import { json } from '../../../lib/api-safety';
export const dynamic = 'force-dynamic';
export function GET() {
  return json({ status: 'ok', revision: process.env.SOURCE_COMMIT || 'local', service: 'calendar-play' });
}
