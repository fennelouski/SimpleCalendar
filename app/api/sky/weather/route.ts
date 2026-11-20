import { NextRequest } from 'next/server';
import { json, originError, rateLimit, readJSON } from '../../../../lib/api-safety';
import { areaFromHeaders, sharedWeatherCache, validCell, validPayload } from '../../../../lib/sky-weather';

export const runtime = 'nodejs';
export const dynamic = 'force-dynamic';

const now = () => Date.now() / 1000;

/** A recent forecast for this cell that another TV already fetched, if there is one. */
export async function GET(request: NextRequest) {
  const blocked = originError(request) || rateLimit(request, 'sky-weather', 20);
  if (blocked) return blocked;
  const cell = request.nextUrl.searchParams.get('cell');
  if (!validCell(cell)) return json({ error: 'Provide a valid area cell.' }, 400);
  const payload = sharedWeatherCache.get(cell, now());
  return payload ? json(payload) : json({ error: 'No shared weather for this area yet.' }, 404);
}

/** A TV shares the forecast it just fetched. Only accepted for the uploader's own area,
 *  so one client cannot fill other areas with false weather. */
export async function POST(request: NextRequest) {
  const blocked = originError(request) || rateLimit(request, 'sky-weather-share', 6);
  if (blocked) return blocked;
  let input: Record<string, unknown>;
  try { input = await readJSON(request); } catch { return json({ error: 'Send a JSON object no larger than 64 KB.' }, 400); }
  const { cell, payload } = input;
  if (!validCell(cell)) return json({ error: 'Provide a valid area cell.' }, 400);
  const area = areaFromHeaders(request.headers);
  const local = process.env.NODE_ENV !== 'production';
  if (area ? area.cell !== cell : !local) return json({ error: 'Weather can only be shared for your own area.' }, 403);
  const clean = validPayload(payload, now());
  if (!clean) return json({ error: 'The weather payload is not valid.' }, 400);
  return json({ stored: sharedWeatherCache.put(cell, clean, now()) });
}

export async function OPTIONS(request: NextRequest) {
  return originError(request) || new Response(null, { status: 204, headers: { Allow: 'GET, POST, OPTIONS', 'Cache-Control': 'no-store' } });
}
