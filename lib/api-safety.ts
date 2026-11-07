import { createHash, randomBytes } from 'node:crypto';
import { NextRequest, NextResponse } from 'next/server';

export function json(data: unknown, status = 200, headers: Record<string, string> = {}) {
  return NextResponse.json(data, { status, headers: { 'Cache-Control': 'no-store', ...headers } });
}

export function originError(request: NextRequest) {
  const origin = request.headers.get('origin');
  return origin && origin !== new URL(request.url).origin
    ? json({ error: 'Cross-origin browser requests are not supported.' }, 403) : null;
}

const salt = randomBytes(32);
const buckets = new Map<string, { count: number; expires: number }>();
export function rateLimit(request: NextRequest, route: string, limit: number) {
  const now = Date.now();
  for (const [key, value] of buckets) if (value.expires <= now) buckets.delete(key);
  // ponytail: bounded, per-instance throttling; use a shared store if a global quota is required.
  const ip = (request.headers.get('x-vercel-forwarded-for') || request.headers.get('x-forwarded-for') || 'unknown').split(',')[0].trim();
  const key = createHash('sha256').update(salt).update(route + ':' + ip).digest('hex');
  const bucket = buckets.get(key);
  if ((bucket && bucket.count >= limit) || (!bucket && buckets.size >= 2048)) {
    return json({ error: 'Too many requests. Please try again shortly.' }, 429, { 'Retry-After': '60' });
  }
  buckets.set(key, { count: (bucket?.count || 0) + 1, expires: bucket?.expires || now + 60_000 });
  return null;
}

export async function readJSON(request: NextRequest) {
  if (!request.headers.get('content-type')?.toLowerCase().startsWith('application/json')) throw new Error('Send an application/json request.');
  const reader = request.body?.getReader();
  if (!reader) throw new Error('A JSON body is required.');
  const chunks: Uint8Array[] = [];
  let length = 0;
  try {
    while (true) {
      const { done, value } = await reader.read();
      if (done) break;
      length += value.length;
      if (length > 65_536) { await reader.cancel(); throw new Error('The request is too large.'); }
      chunks.push(value);
    }
    const result: unknown = JSON.parse(Buffer.concat(chunks).toString('utf8'));
    if (!result || typeof result !== 'object' || Array.isArray(result)) throw new Error();
    return result as Record<string, unknown>;
  } catch {
    throw new Error('Send a JSON object no larger than 64 KB.');
  } finally { reader.releaseLock(); }
}

const segmenter = new Intl.Segmenter('en', { granularity: 'grapheme' });
export function validText(value: unknown, maximum: number, required = false): value is string {
  return typeof value === 'string' && (!required || !!value.trim()) && [...segmenter.segment(value)].length <= maximum;
}

export function validDate(value: unknown): value is string {
  if (typeof value !== 'string' || !/^\d{4}-\d\d-\d\dT\d\d:\d\d:\d\d(?:\.\d{1,3})?(?:Z|[+-]\d\d:\d\d)$/.test(value)) return false;
  const [year, month, day, hour, minute, second] = value.slice(0, 19).split(/[-T:]/).map(Number);
  const leapYear = year % 4 === 0 && (year % 100 !== 0 || year % 400 === 0);
  const days = [31, leapYear ? 29 : 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31][month - 1];
  return year >= 1 && month >= 1 && month <= 12 && day >= 1 && day <= days && hour <= 23 && minute <= 59 && second <= 59 && Number.isFinite(Date.parse(value));
}
