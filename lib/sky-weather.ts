// Weather backgrounds: coarse area lookup and a shared cache of device-fetched Apple Weather.
//
// The TV fetches Apple Weather itself (WeatherKit on device). When the account's WeatherKit
// quota is tight, the server runs in "shared" mode: TVs in the same ~25 km cell first ask
// for a recent copy, and only fetch (then upload) when there is none. With plenty of quota
// the server says "direct" and TVs skip the cache entirely.

/** Grid size for sharing weather; ~28 km north-south, enough for a background. */
export const CELL_DEGREES = 0.25;
/** How long an uploaded forecast is handed out before a TV must fetch a fresh one. */
export const CACHE_SECONDS = 45 * 60;
const MAX_ENTRIES = 4096;
const MAX_HOURS = 48;

export type Area = { latitude: number; longitude: number; cell: string };
export type WeatherMode = 'direct' | 'shared';
export type PrecipitationKind = 'none' | 'rain' | 'snow' | 'sleet' | 'hail';
export type WeatherHour = {
  /** Start of the hour, Unix seconds. */
  t: number;
  /** Cloud cover 0...1. */
  cloud: number;
  /** Precipitation rate, mm/h. */
  precip: number;
  kind: PrecipitationKind;
  /** Wind and gust speed, m/s. */
  wind: number;
  gust: number;
  /** Visibility, metres. */
  visibility: number;
  thunder: boolean;
  /** Air temperature, °C. */
  temp: number;
};
export type WeatherPayload = { fetchedAt: number; hours: WeatherHour[] };

export function weatherMode(env: Record<string, string | undefined> = process.env): WeatherMode {
  return env.WEATHER_MODE === 'shared' ? 'shared' : 'direct';
}

export function roundArea(latitude: number, longitude: number): Area {
  const snap = (value: number) => Math.round(value / CELL_DEGREES) * CELL_DEGREES;
  const lat = Math.min(Math.max(snap(latitude), -90), 90);
  let lon = snap(longitude);
  if (lon >= 180) lon -= 360;
  if (lon < -180) lon += 360;
  return { latitude: lat, longitude: lon, cell: `${lat.toFixed(2)},${lon.toFixed(2)}` };
}

/** Coarse area from the hosting edge's IP geolocation headers (Vercel or CloudFront). */
export function areaFromHeaders(headers: Headers): Area | null {
  const read = (vercel: string, cloudfront: string) => {
    const raw = headers.get(vercel) ?? headers.get(cloudfront);
    if (raw === null || raw.trim() === '') return NaN;
    return Number(raw);
  };
  const latitude = read('x-vercel-ip-latitude', 'cloudfront-viewer-latitude');
  const longitude = read('x-vercel-ip-longitude', 'cloudfront-viewer-longitude');
  if (!Number.isFinite(latitude) || !Number.isFinite(longitude)) return null;
  if (Math.abs(latitude) > 90 || Math.abs(longitude) > 180 || (latitude === 0 && longitude === 0)) return null;
  return roundArea(latitude, longitude);
}

export function validCell(value: unknown): value is string {
  if (typeof value !== 'string' || !/^-?\d{1,2}\.\d{2},-?\d{1,3}\.\d{2}$/.test(value)) return false;
  const [lat, lon] = value.split(',').map(Number);
  return roundArea(lat, lon).cell === value;
}

const kinds = new Set<PrecipitationKind>(['none', 'rain', 'snow', 'sleet', 'hail']);
const inRange = (value: unknown, low: number, high: number): value is number =>
  typeof value === 'number' && Number.isFinite(value) && value >= low && value <= high;

/** Accepts only a small, well-formed forecast so a TV can never store anything else. */
export function validPayload(value: unknown, now = Date.now() / 1000): WeatherPayload | null {
  if (!value || typeof value !== 'object' || Array.isArray(value)) return null;
  const { fetchedAt, hours } = value as Record<string, unknown>;
  if (!inRange(fetchedAt, now - CACHE_SECONDS, now + 300)) return null;
  if (!Array.isArray(hours) || hours.length < 1 || hours.length > MAX_HOURS) return null;
  const clean: WeatherHour[] = [];
  let previous = -Infinity;
  for (const hour of hours) {
    if (!hour || typeof hour !== 'object' || Array.isArray(hour)) return null;
    const h = hour as Record<string, unknown>;
    if (Object.keys(h).some(key => !['t', 'cloud', 'precip', 'kind', 'wind', 'gust', 'visibility', 'thunder', 'temp'].includes(key))) return null;
    if (!inRange(h.t, now - 2 * 3600, now + 72 * 3600) || h.t <= previous) return null;
    if (!inRange(h.cloud, 0, 1) || !inRange(h.precip, 0, 300) || !kinds.has(h.kind as PrecipitationKind)) return null;
    if (!inRange(h.wind, 0, 120) || !inRange(h.gust, 0, 150) || !inRange(h.visibility, 0, 200_000)) return null;
    if (typeof h.thunder !== 'boolean' || !inRange(h.temp, -90, 65)) return null;
    previous = h.t;
    clean.push({ t: h.t, cloud: h.cloud, precip: h.precip, kind: h.kind as PrecipitationKind, wind: h.wind,
      gust: h.gust, visibility: h.visibility, thunder: h.thunder, temp: h.temp });
  }
  return { fetchedAt, hours: clean };
}

/** Where shared forecasts live. In memory per server instance for now; a durable store
 *  (e.g. DynamoDB with TTL once the AWS migration is complete) can implement the same shape. */
export interface WeatherCache {
  get(cell: string, now: number): WeatherPayload | null;
  put(cell: string, payload: WeatherPayload, now: number): boolean;
}

export class MemoryWeatherCache implements WeatherCache {
  private entries = new Map<string, { payload: WeatherPayload; expires: number }>();

  get(cell: string, now: number) {
    const entry = this.entries.get(cell);
    if (!entry) return null;
    if (entry.expires <= now) { this.entries.delete(cell); return null; }
    return entry.payload;
  }

  /** First fresh upload wins until it expires, so a burst of TVs cannot thrash the entry. */
  put(cell: string, payload: WeatherPayload, now: number) {
    if (this.get(cell, now)) return false;
    if (this.entries.size >= MAX_ENTRIES) {
      for (const [key, value] of this.entries) if (value.expires <= now) this.entries.delete(key);
      if (this.entries.size >= MAX_ENTRIES) this.entries.delete(this.entries.keys().next().value as string);
    }
    this.entries.set(cell, { payload, expires: Math.min(payload.fetchedAt + CACHE_SECONDS, now + CACHE_SECONDS) });
    return true;
  }
}

export const sharedWeatherCache: WeatherCache = new MemoryWeatherCache();
