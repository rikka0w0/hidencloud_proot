import { spawn } from 'child_process';
import { fileURLToPath } from 'url';
import path from 'path';
import { parseArgs } from "node:util";
import { mkdir, writeFile } from "node:fs/promises";

const PORT = process.env.SERVER_PORT;
console.log(`SERVER_PORT=${PORT}`);

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

function runCommand(command, args = [], options = {}) {
  return new Promise((resolve, reject) => {
    console.log(`\n==> Running: ${command} ${args.join(' ')}`);

    const child = spawn(command, args, {
      cwd: options.cwd ?? __dirname,
      env: options.env ?? process.env,
      stdio: 'inherit',
    });

    child.on('error', (err) => {
      reject(err);
    });

    child.on('close', (code, signal) => {
      if (code === 0) {
        console.log(`==> Finished: ${command}`);
        resolve();
      } else {
        reject(
          new Error(
            `Command failed: ${command} ${args.join(' ')}; code=${code}; signal=${signal}`
          )
        );
      }
    });
  });
}

// Collect ssh public keys from command-line arguments and URLs, then write them to authorized_keys
const { values } = parseArgs({
  options: {
    k: {
      type: "string",
      multiple: true,
      short: "k",
    },
    u: {
      type: "string",
      multiple: true,
      short: "u",
    },
  },
  allowPositionals: false,
});

const pubkeys = [];

for (const key of values.k ?? []) {
  pubkeys.push(key);
}

for (const url of values.u ?? []) {
  try {
    const res = await fetch(url);

    if (!res.ok) {
      console.error(`Skipping URL ${url}: HTTP ${res.status} ${res.statusText}`);
      continue;
    }

    const text = await res.text();
    pubkeys.push(text);
  } catch (err) {
    console.error(`Skipping URL ${url}: fetch failed: ${err.message}`);
  }
}

await mkdir("/home/container/.ssh", { recursive: true });
const output = 
  "# This file is auto-generated, do not edit manually.\n" +
  "# Changes are overwritten when the container restarts.\n" +
  "# Pass -k and -u options to NodeJS Additional Arguments to add keys.\n\n" +
  pubkeys.map((s) => s.trimEnd()).filter((s) => s.length > 0).join("\n");
await writeFile("/home/container/.ssh/authorized_keys", output + "\n", "utf8");
console.log(`Wrote ${pubkeys.length} key(s) to /home/container/.ssh/authorized_keys`);


// Run start-up scripts
try {
  await runCommand(path.join(__dirname, 'setup-env.sh'));
  
  // Start sslh and sshd as background processes, but log any errors they produce
  runCommand(path.join(__dirname, 'sslh.sh'), [PORT]).catch((err) => {
    console.error("sslh.sh failed:", err);
  });
  runCommand(path.join(__dirname, 'sshd.sh')).catch((err) => {
    console.error("sshd.sh failed:", err);
  });

  // [HIDENCLOUD] Server marked as running...
  console.log("change this text 1");
  console.log("All start-up scripts have been run.");
} catch (err) {
  console.error(err);
}

// Spawn an interactive shell to keep the container running and allow user interaction
const sh = spawn('/bin/bash', ['-i'], {
  cwd: __dirname,
  env: process.env,
  stdio: 'inherit',
});

sh.on('error', (err) => {
  console.error('Failed to start shell:', err);
  process.exitCode = 1;
});

sh.on('close', (code, signal) => {
  console.log(`Shell exited with code=${code}; signal=${signal}`);
  process.exit(code ?? 0);
});
