import { NextRequest } from 'next/server';
import { json, originError, rateLimit } from '../../../lib/api-safety';
import { areaFromHeaders, weatherMode } from '../../../lib/sky-weather';

export const runtime = 'nodejs';
export const dynamic = 'force-dynamic';

// The TV's coarse area (from the edge's IP geolocation, never logged or stored) and whether
// weather should be fetched directly or shared through the cache.
export async function GET(request: NextRequest) {
  const blocked = originError(request) || rateLimit(request, 'sky', 20);
  if (blocked) return blocked;
  return json({ area: areaFromHeaders(request.headers), weatherMode: weatherMode() });
}

export async function OPTIONS(request: NextRequest) {
  return originError(request) || new Response(null, { status: 204, headers: { Allow: 'GET, OPTIONS', 'Cache-Control': 'no-store' } });
}
