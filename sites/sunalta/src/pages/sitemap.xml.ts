import type { APIRoute } from 'astro';

export const GET: APIRoute = ({ site }) => {
  const location = site ? new URL('/', site).href.replaceAll('&', '&amp;').replaceAll('<', '&lt;') : undefined;
  return new Response(
    `<?xml version="1.0" encoding="UTF-8"?>\n<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">${location ? `\n  <url><loc>${location}</loc></url>\n` : ''}</urlset>\n`,
    { headers: { 'Content-Type': 'application/xml; charset=utf-8' } },
  );
};
