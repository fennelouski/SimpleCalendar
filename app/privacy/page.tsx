export const metadata = {
  title: 'Calendar Play privacy policy',
  description: 'How Calendar Play handles saved events and optional online features.',
};

export default function PrivacyPage() {
  return (
    <main style={{ maxWidth: '780px', margin: '3rem auto', padding: '0 1.5rem', lineHeight: 1.7 }}>
      <h1>Calendar Play privacy policy</h1>
      <p>Updated September 28, 2026. Developer: Nathan Fennel.</p>
      <p>The new per-device privacy choices described below are part of version 1.4. Older installed versions may make online requests through their existing feature settings without these new consent controls.</p>
      <h2>Saved events and preferences</h2>
      <p>Calendar Play stores app-created events, preferences, selected images and cached content on your device. Deleting an app-created event removes it from the local event store after the save succeeds. Image caches are separate. The Apple TV release does not connect to system calendars or Google Calendar and does not promise iCloud synchronization.</p>
      <p>On platforms where calendar connections are available, Apple EventKit uses the calendar access you grant, and an optional Google connection requests read access to Google calendars. Those calendars remain with their providers. Disconnecting a calendar does not erase the provider&apos;s events. The current Apple TV release keeps app preferences locally.</p>
      <h2>Optional event suggestions</h2>
      <p>AI event suggestions are off by default on each device. After you enable them and request a suggestion, the description you enter, selected date and time zone go to the Calendar Play backend and OpenAI. Descriptions may contain names, contact details, locations or other information you include. The backend returns one proposed event for you to review before saving. Recurrence information is descriptive and does not automatically create repeated events.</p>
      <p>The backend does not save event descriptions or generated event content in an application database or write them to application logs. It sends OpenAI requests with response storage disabled. This does not eliminate the providers&apos; operational or abuse-monitoring records. OpenAI explains its API data handling in its <a href="https://developers.openai.com/api/docs/guides/your-data">data controls documentation</a>.</p>
      <h2>Optional online photos</h2>
      <p>Online photos are off by default. When enabled, photo searches send search terms through the Calendar Play backend to Unsplash. A separate choice permits event titles and locations to be used for automatic photo matching. Selected photo identifiers are reported to Unsplash through the backend for download tracking. Loading an image contacts Unsplash image servers, which receive connection information such as your IP address. Photographer credit and Unsplash links accompany online photos.</p>
      <p>Turning online photos off stops new app requests and invalidates pending results. Images already selected or cached on your device can remain there. Followed photographer or Unsplash links are handled by your browser under those sites&apos; policies.</p>
      <h2>Location, maps and weather</h2>
      <p>Version 1.4 build 3 estimates location locally from the device&apos;s time zone and region for sunrise, sunset and daylight calculations. These regional estimates can differ from your city. This build makes no IP-location request, and older stored network-location choices do not enable one. Earlier installed versions can still contact ipapi.co to estimate location from an IP address; their memory cache can last up to 24 hours. Online maps/weather remain a separate choice that starts off.</p>
      <p>The active online weather view sends coordinates and dates to Open-Meteo. Apple map search and geocoding can process location text. These providers receive the request and connection information under their own policies. The current Apple TV weather implementation does not provide online forecasts. Platform capabilities and device permissions also determine which features are available.</p>
      <h2>Historical information</h2>
      <p>When the optional historical-information feature is enabled, opening day details automatically requests the selected month and day from Wikimedia. This feature is off in fresh settings. Wikimedia receives the date in the URL and connection information such as your IP address. Text results are cached in local preferences with seven-day entry validity; expired entries are cleaned up while the feature runs. This view does not download Wikimedia thumbnails. Calendar descriptions are not needed for these requests.</p>
      <h2>Service records and retention</h2>
      <p>The backend keeps salted hashes of client connection addresses and request counters in server memory for a one-minute rate-limit window. Expired counters are removed when another request runs. They are bounded per server instance, are not stored in a database, and reset when that instance ends. The service does not use them for advertising or cross-app tracking.</p>
      <p>Vercel and AWS host the service and can retain operational connection and diagnostic records under their account settings. AWS application diagnostic logs are configured for seven-day retention. This does not set a retention period for Vercel, OpenAI, Unsplash, Wikimedia, weather providers or other provider records. The app has no advertising SDK and does not sell personal information.</p>
      <h2>Your choices</h2>
      <p>You can disable optional online features in the app. Revoking a choice cancels pending app work where possible, but cannot recall a request already received by a provider or erase its logs. Local deletion does not erase exports, backups, separate image caches or copies retained by external calendar and online services. Manage device permissions and provider account access in their settings.</p>
      <p>For support or a privacy request, <a href="https://nathanfennel.com/contact">contact Nathan Fennel</a>. Information you choose to send for support is used to respond. Do not include private event content unless it is needed for your request.</p>
    </main>
  );
}
