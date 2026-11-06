import type { APIRoute } from 'astro';

export const GET: APIRoute = ({ site }) => {
  const locations = site
    ? ['/', '/privacy/', '/support/'].map(path => new URL(path, site).href.replaceAll('&', '&amp;').replaceAll('<', '&lt;'))
    : [];
  return new Response(
    `<?xml version="1.0" encoding="UTF-8"?>\n<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">\n${locations.map(location => `  <url><loc>${location}</loc></url>\n`).join('')}</urlset>\n`,
    { headers: { 'Content-Type': 'application/xml; charset=utf-8' } },
  );
};
