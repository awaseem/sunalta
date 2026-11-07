import { spawnSync } from 'node:child_process';
import { mkdtempSync, rmSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { fileURLToPath } from 'node:url';
import { join, resolve } from 'node:path';

const site = fileURLToPath(new URL('..', import.meta.url));
const repository = resolve(site, '../..');
const options = process.argv.slice(2);
if (options.some(option => option !== '--social-only') || options.length > 1) {
  throw new Error('Usage: npm run assets -- [--social-only]');
}
const temporary = mkdtempSync(join(tmpdir(), 'sunalta-artwork-'));

function run(command, args) {
  const result = spawnSync(command, args, { stdio: 'inherit' });
  if (result.error) throw result.error;
  if (result.status !== 0) throw new Error(`${command} failed: ${result.signal ?? result.status}`);
}

try {
  const executable = join(temporary, 'render-clock');
  run('xcrun', ['swiftc', '-parse-as-library', '-D', 'DEBUG', '-module-cache-path', join(temporary, 'modules'),
    join(site, 'scripts/RenderClockAssets.swift'),
    join(repository, 'Sunalta/Features/Clock/Assets/ClockMeshReader.swift'),
    join(repository, 'Sunalta/Features/Clock/Debug/ClockArtworkRenderer.swift'),
    '-o', executable]);
  run(executable, [repository, join(site, 'src/assets/clock'), ...options]);
} finally {
  rmSync(temporary, { recursive: true, force: true });
}
