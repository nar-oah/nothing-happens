import { spawnSync } from 'node:child_process';
import { access, cp, mkdir, readdir, rm, writeFile } from 'node:fs/promises';
import { dirname, extname, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const frontendDir = resolve(dirname(fileURLToPath(import.meta.url)), '..');
const buildDir = join(frontendDir, 'build');
const godotWebDir = resolve(frontendDir, '../godot/web');
const pnpm = process.platform === 'win32' ? 'pnpm.cmd' : 'pnpm';

const keepExtensions = new Set([
	'.woff',
	'.woff2',
	'.ttf',
	'.otf',
	'.png',
	'.jpg',
	'.jpeg',
	'.webp',
	'.svg',
	'.gif',
	'.ico'
]);

async function addGodotKeepImports(directory) {
	const entries = await readdir(directory, { withFileTypes: true });

	for (const entry of entries) {
		const path = join(directory, entry.name);

		if (entry.isDirectory()) {
			await addGodotKeepImports(path);
			continue;
		}

		if (!keepExtensions.has(extname(entry.name).toLowerCase())) continue;

		await writeFile(`${path}.import`, '[remap]\n\nimporter="keep"\n');
	}
}

const result = spawnSync(pnpm, ['build'], {
	cwd: frontendDir,
	stdio: 'inherit'
});

if (result.error) throw result.error;
if (result.status !== 0) process.exit(result.status ?? 1);

await access(join(buildDir, 'index.html'));

await rm(godotWebDir, {
	recursive: true,
	force: true
});

await mkdir(godotWebDir, {
	recursive: true
});

await cp(buildDir, godotWebDir, {
	recursive: true
});

await addGodotKeepImports(godotWebDir);

console.log(`Copied ${buildDir} to ${godotWebDir} with Godot keep imports`);
