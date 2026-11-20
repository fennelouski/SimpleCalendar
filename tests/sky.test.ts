import test from 'node:test';
import assert from 'node:assert/strict';
import { NextRequest } from 'next/server';
import { GET as sky } from '../app/api/sky/route';
import { GET as shared, POST as share } from '../app/api/sky/weather/route';
import { MemoryWeatherCache, areaFromHeaders, roundArea, validCell, validPayload, weatherMode } from '../lib/sky-weather';

let ip = 0;
function request(path: string, value?: unknown, extra: Record<string, string> = {}) {
  return new NextRequest('https://calendar-play-seven.vercel.app' + path, {
    method: value === undefined ? 'GET' : 'POST',
    ...(value === undefined ? {} : { body: JSON.stringify(value) }),
    headers: { 'Content-Type': 'application/json', 'X-Forwarded-For': '198.51.100.' + (++ip), ...extra },
  });
}
const nowSeconds = () => Math.floor(Date.now() / 1000);
function payload(hours = 3) {
  const start = nowSeconds() - (nowSeconds() % 3600);
  return {
    fetchedAt: nowSeconds(),
    hours: Array.from({ length: hours }, (_, i) => ({ t: start + i * 3600, cloud: 0.8, precip: 1.2, kind: 'rain', wind: 6, gust: 11, visibility: 9000, thunder: false, temp: 7 })),
  };
}
const amsterdam = { 'x-vercel-ip-latitude': '52.374', 'x-vercel-ip-longitude': '4.8897' };

test('areas snap to a quarter-degree grid and reject junk', () => {
  assert.deepEqual(roundArea(52.374, 4.8897), { latitude: 52.25, longitude: 5, cell: '52.25,5.00' });
  assert.equal(roundArea(10, 179.9).cell, '10.00,-180.00');
  assert.equal(areaFromHeaders(new Headers(amsterdam))?.cell, '52.25,5.00');
  assert.equal(areaFromHeaders(new Headers({ 'cloudfront-viewer-latitude': '40.7128', 'cloudfront-viewer-longitude': '-74.006' }))?.cell, '40.75,-74.00');
  assert.equal(areaFromHeaders(new Headers()), null);
  assert.equal(areaFromHeaders(new Headers({ 'x-vercel-ip-latitude': '0', 'x-vercel-ip-longitude': '0' })), null);
  assert.ok(validCell('52.25,5.00'));
  assert.ok(!validCell('52.30,5.00'));
  assert.ok(!validCell('52.25;5.00'));
});

test('mode defaults to direct and only switches when configured', () => {
  assert.equal(weatherMode({}), 'direct');
  assert.equal(weatherMode({ WEATHER_MODE: 'shared' }), 'shared');
  assert.equal(weatherMode({ WEATHER_MODE: 'anything' }), 'direct');
});

test('payload validation keeps only well-formed recent forecasts', () => {
  assert.ok(validPayload(payload()));
  assert.equal(validPayload({ ...payload(), fetchedAt: nowSeconds() - 7200 }), null);
  const extra = payload(); (extra.hours[0] as Record<string, unknown>).note = 'x';
  assert.equal(validPayload(extra), null);
  const bad = payload(); bad.hours[1].cloud = 2;
  assert.equal(validPayload(bad), null);
  const unordered = payload(); unordered.hours.reverse();
  assert.equal(validPayload(unordered), null);
  assert.equal(validPayload(payload(49)), null);
});

test('cache: first fresh upload wins and entries expire', () => {
  const cache = new MemoryWeatherCache();
  const now = nowSeconds();
  const first = validPayload(payload(), now)!;
  assert.ok(cache.put('52.25,5.00', first, now));
  assert.equal(cache.put('52.25,5.00', first, now + 10), false);
  assert.deepEqual(cache.get('52.25,5.00', now + 60), first);
  assert.equal(cache.get('52.25,5.00', now + 46 * 60), null);
});

test('routes: area lookup, sharing only for your own area, and fetching shared weather', async () => {
  const lookup = await sky(request('/api/sky', undefined, amsterdam));
  assert.equal(lookup.status, 200);
  assert.deepEqual(await lookup.json(), { area: { latitude: 52.25, longitude: 5, cell: '52.25,5.00' }, weatherMode: 'direct' });

  const miss = await shared(request('/api/sky/weather?cell=52.25,5.00'));
  assert.equal(miss.status, 404);

  const elsewhere = await share(request('/api/sky/weather', { cell: '40.75,-74.00', payload: payload() }, amsterdam));
  assert.equal(elsewhere.status, 403);

  const stored = await share(request('/api/sky/weather', { cell: '52.25,5.00', payload: payload() }, amsterdam));
  assert.equal(stored.status, 200);
  assert.deepEqual(await stored.json(), { stored: true });

  const hit = await shared(request('/api/sky/weather?cell=52.25,5.00'));
  assert.equal(hit.status, 200);
  assert.equal((await hit.json()).hours.length, 3);

  const invalid = await shared(request('/api/sky/weather?cell=nowhere'));
  assert.equal(invalid.status, 400);
});
