import { spawnSync } from 'node:child_process';
import { access, cp, mkdir, rm } from 'node:fs/promises';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const frontendDir = resolve(dirname(fileURLToPath(import.meta.url)), '..');
const buildDir = join(frontendDir, 'build');
const godotWebDir = resolve(frontendDir, '../godot/web');
const pnpm = process.platform === 'win32' ? 'pnpm.cmd' : 'pnpm';
const result = spawnSync(pnpm, ['build'], { cwd: frontendDir, stdio: 'inherit' });

if (result.error) throw result.error;
if (result.status !== 0) process.exit(result.status ?? 1);

await access(join(buildDir, 'index.html'));
await rm(godotWebDir, { recursive: true, force: true });
await mkdir(godotWebDir, { recursive: true });
await cp(buildDir, godotWebDir, { recursive: true });

console.log(`Copied ${buildDir} to ${godotWebDir}`);
