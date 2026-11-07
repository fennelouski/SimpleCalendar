import { validDate, validText } from './api-safety';

export const emojis = ['📅', '👨‍⚕️', '🎓', '🍽️', '🎉', '💼', '🏃‍♂️', '🎨', '📖', '✈️'];
const frequencies = ['daily', 'weekly', 'monthly', 'yearly'];
const optionalString = { type: ['string', 'null'] };
export const eventSchema = {
  type: 'object', additionalProperties: false, required: ['event'],
  properties: { event: { anyOf: [{ type: 'null' }, {
    type: 'object', additionalProperties: false,
    required: ['title', 'startDate', 'endDate', 'isAllDay', 'location', 'notes', 'color', 'emoji', 'recurrence'],
    properties: {
      title: { type: 'string' }, startDate: { type: 'string' }, endDate: { type: 'string' },
      isAllDay: { type: 'boolean' }, location: optionalString, notes: optionalString,
      color: optionalString, emoji: { type: ['string', 'null'], enum: [...emojis, null] },
      recurrence: { anyOf: [{ type: 'null' }, {
        type: 'object', additionalProperties: false,
        required: ['frequency', 'interval', 'endDate', 'daysOfWeek'],
        properties: {
          frequency: { type: 'string', enum: frequencies }, interval: { type: 'integer' },
          endDate: optionalString, daysOfWeek: { type: ['array', 'null'], items: { type: 'integer' } },
        },
      }] },
    },
  }] } },
};

export function validateEvent(value: unknown): Record<string, unknown> | null {
  if (!value || typeof value !== 'object' || Array.isArray(value)) return null;
  const event = value as Record<string, unknown>;
  if (!validText(event.title, 300, true) || !validDate(event.startDate) || !validDate(event.endDate) ||
      Date.parse(event.endDate) <= Date.parse(event.startDate) || typeof event.isAllDay !== 'boolean') return null;
  if (event.location != null && !validText(event.location, 1000)) return null;
  if (event.notes != null && !validText(event.notes, 4000)) return null;
  if (event.color != null && (typeof event.color !== 'string' || !/^#[0-9a-f]{6}$/i.test(event.color))) return null;
  if (event.emoji != null && (typeof event.emoji !== 'string' || !emojis.includes(event.emoji))) return null;
  let recurrence: Record<string, unknown> | undefined;
  if (event.recurrence != null) {
    if (typeof event.recurrence !== 'object' || Array.isArray(event.recurrence)) return null;
    const r = event.recurrence as Record<string, unknown>;
    if (typeof r.frequency !== 'string' || !frequencies.includes(r.frequency) || !Number.isInteger(r.interval) || Number(r.interval) < 1 || Number(r.interval) > 365) return null;
    if (r.endDate != null && (!validDate(r.endDate) || Date.parse(r.endDate) < Date.parse(event.startDate))) return null;
    if (r.daysOfWeek != null && (!Array.isArray(r.daysOfWeek) || r.daysOfWeek.length > 7 || !r.daysOfWeek.every(d => Number.isInteger(d) && d >= 0 && d <= 6))) return null;
    recurrence = { frequency: r.frequency, interval: r.interval, ...(r.endDate != null ? { endDate: r.endDate } : {}), ...(r.daysOfWeek != null ? { daysOfWeek: r.daysOfWeek } : {}) };
  }
  // Return only fields the native client understands, never provider extras or null optionals.
  return { title: event.title.trim(), startDate: event.startDate, endDate: event.endDate, isAllDay: event.isAllDay,
    ...(event.location != null ? { location: event.location } : {}), ...(event.notes != null ? { notes: event.notes } : {}),
    ...(event.color != null ? { color: event.color } : {}), ...(event.emoji != null ? { emoji: event.emoji } : {}),
    ...(recurrence ? { recurrence } : {}) };
}
