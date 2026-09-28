import { NextRequest } from 'next/server';
import { json, originError, rateLimit, readJSON, validText } from '../../../lib/api-safety';

export const runtime = 'nodejs';
export const dynamic = 'force-dynamic';
export const maxDuration = 30;

async function unsplash(path: string, request: NextRequest) {
  return fetch(`https://api.unsplash.com${path}`, {
    headers: { 'Accept-Version': 'v1', Authorization: `Client-ID ${process.env.UNSPLASH_ACCESS_KEY}` },
    cache: 'no-store', signal: AbortSignal.any([request.signal, AbortSignal.timeout(15_000)]),
  });
}

export async function GET(request: NextRequest) {
  const blocked = originError(request) || rateLimit(request, 'unsplash', 30);
  if (blocked) return blocked;
  const params = request.nextUrl.searchParams;
  const action = params.get('action');
  const query = (params.get('query') || '').trim();
  const page = params.get('page') || '1';
  const perPage = params.get('per_page') || '10';
  if (!['random', 'search'].includes(action || '') || !validText(query, 200) ||
      (action === 'search' && !query) || !/^[1-9]\d{0,2}$/.test(page) || !/^[1-9]\d?$/.test(perPage) || Number(perPage) > 30) {
    return json({ error: 'Choose random or search, a query up to 200 characters, page 1–999, and 1–30 photos.' }, 400);
  }
  if (!process.env.UNSPLASH_ACCESS_KEY) return json({ error: 'Online photos are temporarily unavailable.' }, 503);
  const outgoing = new URLSearchParams();
  if (query) outgoing.set('query', query);
  if (action === 'search') { outgoing.set('page', page); outgoing.set('per_page', perPage); }
  try {
    const response = await unsplash(`${action === 'search' ? '/search/photos' : '/photos/random'}?${outgoing}`, request);
    if (!response.ok) return json({ error: 'Online photos are temporarily unavailable.' }, response.status === 429 ? 429 : 502);
    const data = await response.json();
    const photos = action === 'search' ? data?.results : [data];
    if (!Array.isArray(photos) || photos.length > 30 || !photos.every(p => typeof p?.id === 'string' && typeof p?.urls?.regular === 'string' && typeof p?.user?.name === 'string')) {
      return json({ error: 'The photo service returned an invalid response.' }, 502);
    }
    return json(photos);
  } catch { return json({ error: 'Online photos are temporarily unavailable.' }, 502); }
}

export async function POST(request: NextRequest) {
  const blocked = originError(request) || rateLimit(request, 'unsplash-track', 30);
  if (blocked) return blocked;
  let input: Record<string, unknown>;
  try { input = await readJSON(request); } catch { return json({ error: 'Send a JSON object no larger than 64 KB.' }, 400); }
  if (input.action !== 'track_download' || typeof input.photoId !== 'string' || !/^[A-Za-z0-9_-]{1,100}$/.test(input.photoId)) {
    return json({ error: 'Provide track_download and a valid photo ID.' }, 400);
  }
  if (!process.env.UNSPLASH_ACCESS_KEY) return json({ error: 'Online photos are temporarily unavailable.' }, 503);
  try {
    const response = await unsplash(`/photos/${encodeURIComponent(input.photoId)}/download`, request);
    return response.ok ? json({ success: true }) : json({ error: 'The photo download could not be registered. Please try again.' }, 502);
  } catch { return json({ error: 'The photo download could not be registered. Please try again.' }, 502); }
}

export async function OPTIONS(request: NextRequest) {
  return originError(request) || new Response(null, { status: 204, headers: { Allow: 'GET, POST, OPTIONS', 'Cache-Control': 'no-store' } });
}
