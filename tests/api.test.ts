import test from 'node:test';
import assert from 'node:assert/strict';
import { NextRequest } from 'next/server';
import { POST as parse, OPTIONS as parseOptions } from '../app/api/parse-event/route';
import { GET as photos, POST as track } from '../app/api/unsplash/route';
import { rateLimit, validDate } from '../lib/api-safety';

let ip = 0;
function request(path: string, value?: unknown, extra: Record<string, string> = {}) {
  return new NextRequest('https://calendar-play-seven.vercel.app' + path, {
    method: value === undefined ? 'GET' : 'POST',
    ...(value === undefined ? {} : { body: JSON.stringify(value) }),
    headers: { 'Content-Type': 'application/json', 'X-Forwarded-For': '192.0.2.' + (++ip), ...extra },
  });
}
const input = { text: 'Synthetic meeting tomorrow at 10', currentDate: '2026-09-28T12:00:00Z', timeZone: 'Europe/Amsterdam' };
const event = { title: 'Synthetic meeting', startDate: '2026-09-29T10:00:00+02:00', endDate: '2026-09-29T11:00:00+02:00', isAllDay: false,
  location: null, notes: null, emoji: '📅', color: '#4A90E2', recurrence: null };
const realFetch = globalThis.fetch;
const originalKey = process.env.OPENAI_API_KEY;
const originalPhotoKey = process.env.UNSPLASH_ACCESS_KEY;
let calls: { url: string; init?: RequestInit }[] = [];
function provider(value: unknown, status = 200) {
  globalThis.fetch = (async (url: string | URL | Request, init?: RequestInit) => {
    calls.push({ url: String(url), init });
    return Response.json(value, { status });
  }) as typeof fetch;
}
function completion(value: unknown) { provider({ id: 'test', object: 'chat.completion', created: 0, model: 'test', choices: [{ index: 0, finish_reason: 'stop', message: { role: 'assistant', content: JSON.stringify(value) } }] }); }

test('Calendar API boundaries and provider behavior with synthetic input', async t => {
  process.env.OPENAI_API_KEY = 'synthetic-not-a-real-key';
  process.env.UNSPLASH_ACCESS_KEY = 'synthetic-photo-key';
  try {
    await t.test('valid one-event output matches native DTO and uses structured nonstored requests', async () => {
      completion({ event }); calls = [];
      const response = await parse(request('/api/parse-event', input));
      assert.equal(response.status, 200);
      assert.deepEqual(await response.json(), { title: event.title, startDate: event.startDate, endDate: event.endDate, isAllDay: false, emoji: '📅', color: '#4A90E2' });
      const outgoing = JSON.parse(String(calls[0].init?.body));
      assert.equal(outgoing.model, 'gpt-5.4-mini'); assert.equal(outgoing.store, false); assert.equal(outgoing.response_format.json_schema.strict, true);
      assert.match(outgoing.messages[1].content, /Europe\/Amsterdam/);
      assert.equal(response.headers.get('cache-control'), 'no-store');
    });
    await t.test('invalid bodies, dates, zones and browser origins never contact provider', async () => {
      calls = [];
      for (const changed of [{ text: '' }, { text: 'a'.repeat(2001) }, { currentDate: '2026-02-30T12:00:00Z' }, { timeZone: 'Mars/Olympus' }, { currentDate: 'yesterday' }, { text: 5 }]) {
        assert.equal((await parse(request('/api/parse-event', { ...input, ...changed }))).status, 400);
      }
      assert.equal((await parse(request('/api/parse-event', input, { Origin: 'https://foreign.invalid' }))).status, 403);
      const malformed = new NextRequest('https://fixture.invalid/api/parse-event', { method: 'POST', body: '{', headers: { 'Content-Type': 'application/json' } });
      assert.equal((await parse(malformed)).status, 400);
      assert.equal((await parse(request('/api/parse-event', { ...input, padding: 'x'.repeat(66000) }))).status, 400);
      assert.equal(calls.length, 0);
    });
    await t.test('grapheme limits accept complex emoji and calendar dates reject normalized invalid days', async () => {
      completion({ event });
      assert.equal((await parse(request('/api/parse-event', { ...input, text: '👨‍⚕️'.repeat(2000) }))).status, 200);
      assert.equal(validDate('2024-02-29T00:00:00Z'), true);
      assert.equal(validDate('1800-01-01T00:00:00Z'), true);
      assert.equal(validDate('0004-02-29T00:00:00Z'), true);
      for (const date of ['2025-02-29T00:00:00Z', '2026-13-01T00:00:00Z', '2026-01-01T24:00:00Z']) assert.equal(validDate(date), false);
    });
    await t.test('invalid provider fields never become a saved event and raw data is not reflected', async () => {
      for (const changed of [{ title: '' }, { title: 'x'.repeat(301) }, { startDate: 'bad' }, { endDate: event.startDate }, { color: 'red' }, { emoji: '💣' }, { isAllDay: 'yes' }, { location: 'x'.repeat(1001) }, { recurrence: { frequency: 'hourly', interval: 1 } }, { recurrence: { frequency: 'weekly', interval: 0 } }, { recurrence: { frequency: 'weekly', interval: 1, daysOfWeek: [7] } }]) {
        completion({ event: { ...event, ...changed } });
        const response = await parse(request('/api/parse-event', input));
        assert.equal(response.status, 502);
        assert.equal('rawResponse' in await response.json(), false);
      }
      completion({ event: null }); assert.equal((await parse(request('/api/parse-event', input))).status, 422);
      provider({ choices: [{ finish_reason: 'length', message: { content: 'private-partial-output' } }] });
      const response = await parse(request('/api/parse-event', input)); assert.equal(response.status, 502); assert.equal((await response.text()).includes('private'), false);
    });
    await t.test('recurrence preserves supported fields and discards unrequested fields', async () => {
      completion({ event: { ...event, recurrence: { frequency: 'weekly', interval: 2, endDate: null, daysOfWeek: [1, 3] }, internal: 'unused' } });
      const response = await parse(request('/api/parse-event', input)); const body = await response.json();
      assert.equal(response.status, 200); assert.deepEqual(body.recurrence, { frequency: 'weekly', interval: 2, daysOfWeek: [1, 3] }); assert.equal(body.internal, undefined);
    });
    await t.test('provider failures and missing configuration return safe errors', async () => {
      provider({ error: { message: 'secret provider detail', type: 'server_error' } }, 500);
      const response = await parse(request('/api/parse-event', input)); assert.equal(response.status, 502); assert.equal((await response.text()).includes('secret'), false);
      delete process.env.OPENAI_API_KEY; calls = [];
      assert.equal((await parse(request('/api/parse-event', input))).status, 503); assert.equal(calls.length, 0);
      process.env.OPENAI_API_KEY = 'synthetic-not-a-real-key';
    });
    await t.test('request throttle rejects limit+1 and expires without permanent identifiers', () => {
      const realNow = Date.now; let now = realNow(); Date.now = () => now;
      const r = request('/api/parse-event');
      try { for (let i = 0; i < 10; i++) assert.equal(rateLimit(r, 'isolated-test', 10), null);
        const limited = rateLimit(r, 'isolated-test', 10); assert.equal(limited?.status, 429); assert.equal(limited?.headers.get('retry-after'), '60');
        now += 60001; assert.equal(rateLimit(r, 'isolated-test', 10), null);
      } finally { Date.now = realNow; }
    });
    await t.test('Unsplash shape and attribution survive without keys in URLs', async () => {
      const photo = { id: 'Ab_C-12', urls: { regular: 'https://images.unsplash.com/example' }, user: { name: 'Synthetic Photographer', links: { html: 'https://unsplash.com/@fixture' } }, links: { download_location: 'https://api.unsplash.com/photos/Ab_C-12/download' } };
      provider({ results: [photo] }); calls = [];
      const response = await photos(request('/api/unsplash?action=search&query=forest&per_page=5'));
      assert.equal(response.status, 200); assert.deepEqual(await response.json(), [photo]);
      assert.equal(calls[0].url.includes('synthetic-photo-key'), false); assert.equal(calls[0].url.includes('client_id'), false);
      assert.equal(new Headers(calls[0].init?.headers).get('Authorization'), 'Client-ID synthetic-photo-key');
      provider(photo); assert.deepEqual(await (await photos(request('/api/unsplash?action=random'))).json(), [photo]);
    });
    await t.test('Unsplash rejects malformed inputs and tracking awaits actual success', async () => {
      calls = [];
      for (const query of ['action=search', 'action=other', 'action=random&per_page=31', 'action=search&query=' + 'x'.repeat(201), 'action=random&page=0']) assert.equal((await photos(request('/api/unsplash?' + query))).status, 400);
      assert.equal((await track(request('/api/unsplash', { action: 'track_download', photoId: '../secret' }))).status, 400); assert.equal(calls.length, 0);
      provider({}, 500); assert.equal((await track(request('/api/unsplash', { action: 'track_download', photoId: 'Ab_C-12' }))).status, 502);
      let resolve!: (r: Response) => void;
      globalThis.fetch = (() => new Promise<Response>(r => { resolve = r; })) as typeof fetch;
      let finished = false;
      const pending = track(request('/api/unsplash', { action: 'track_download', photoId: 'Ab_C-12' })).then(r => { finished = true; return r; });
      await new Promise(r => setTimeout(r, 5)); assert.equal(finished, false);
      resolve(Response.json({ url: 'https://images.unsplash.com/example' })); assert.equal((await pending).status, 200);
    });
    await t.test('same-origin preflight succeeds and cross-origin cannot bypass policy', async () => {
      assert.equal((await parseOptions(request('/api/parse-event'))).status, 204);
      assert.equal((await parseOptions(request('/api/parse-event', undefined, { Origin: 'https://foreign.invalid' }))).status, 403);
    });
  } finally {
    globalThis.fetch = realFetch;
    if (originalKey === undefined) delete process.env.OPENAI_API_KEY; else process.env.OPENAI_API_KEY = originalKey;
    if (originalPhotoKey === undefined) delete process.env.UNSPLASH_ACCESS_KEY; else process.env.UNSPLASH_ACCESS_KEY = originalPhotoKey;
  }
});
