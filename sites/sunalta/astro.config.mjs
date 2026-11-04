import { defineConfig } from 'astro/config';
import { loadEnv } from 'vite';

const { SITE_URL } = loadEnv(process.env.NODE_ENV ?? 'production', process.cwd(), '');
const origin = process.env.SITE_URL || SITE_URL || undefined;

if (origin) {
  const url = new URL(origin);
  if (url.protocol !== 'https:' || url.pathname !== '/' || url.search || url.hash || url.username || url.password) {
    throw new Error('SITE_URL must be the public HTTPS origin without a path, credentials, query, or fragment.');
  }
}

export default defineConfig({
  site: origin,
  output: 'static',
  trailingSlash: 'always',
  devToolbar: { enabled: false },
});
