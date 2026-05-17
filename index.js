import { spawn } from 'child_process';
import { fileURLToPath } from 'url';
import path from 'path';

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

async function runSetupScripts() {
  await runCommand(path.join(__dirname, 'setup-env.sh'));
  runCommand(path.join(__dirname, 'sslh.sh'), [PORT]);
  runCommand(path.join(__dirname, 'sshd.sh'));

  // [HIDENCLOUD] Server marked as running...
  console.log("change this text 1");
  console.log("All start-up scripts have been run.");
}

function startServer() {
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
}

async function main() {
  try {
    await runSetupScripts();
  } catch (err) {
    console.error(err);
  }

  startServer();
}

main();
