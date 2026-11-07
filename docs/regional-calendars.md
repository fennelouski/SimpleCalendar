# Regional holiday calendars

Holidays are organized into **calendars**. One worldwide calendar is always shown. Each region (country) can also have its own calendar, and the user's **active regions** decide which regional calendars appear. Holiday **categories** (Bank Holidays, Christian Holidays, Awareness Days, …) still filter on top, exactly as before.

```text
visible holiday = category enabled (HolidayCategoryManager)
                  AND holiday is in the worldwide calendar
                      or in the calendar of an active region (HolidayRegionManager)
```

## Where things live

All in `Simple Calendar/HolidayCalendars/`:

| File | What it is |
|---|---|
| `HolidayRegion.swift` | A region, identified by its ISO 3166-1 alpha-2 code (`US`, `CA`, `GB`, …), with a localized name, a flag, and the device's current region. |
| `HolidayCalendar.swift` | `HolidayCalendar` (a scope, worldwide or one region, plus its holidays) and `HolidayCatalog`: the registry of all calendars, the master holiday list (`definitions`) in display-priority order, and `visibleHolidayNames(for:)`. |
| `WorldwideHolidayCalendar.swift` | Holidays observed broadly around the world (religious holidays, seasons, moon phases, UN/WHO world days, New Year's, Valentine's, Halloween, …). |
| `UnitedStatesHolidayCalendar.swift` | US federal holidays, national observances, and the "National ___ Day" celebrations. |
| `RegionalHolidayCalendars.swift` | Canada, Mexico, United Kingdom, Ireland, France, Germany, Sweden, Finland, Czechia, Australia, New Zealand. Small for now. |
| `HolidayRegionManager.swift` | Which regions are active, persisted locally and mirrored to iCloud like holiday categories. Also listens for device region changes. |

The holiday definitions themselves (`CalendarHoliday` static values, and their date rules in `CalendarHoliday.dateInYear`) stay in `Holiday.swift`. `HolidayManager` computes dates for every definition once per year and applies the visibility filter when answering queries.

## How regions are chosen

- **Match Device Region** (on by default): the device's region (`Locale.current.region`) is active automatically and follows changes in system settings. If the locale has no region, the United States is used, since the holiday data has always been US-centric.
- **Additional regions:** the user can turn on any other region in Settings → Holiday Regions (for example, a US user who also wants Canada).
- Turning **Match Device Region** off keeps the device region switched on as a manual choice, so nothing disappears unexpectedly. The user can then turn it off.
- A device region without a calendar yet (for example Japan) still appears in Settings, labeled "No regional holidays yet". Those users see the worldwide calendar.

## Adding a region

1. **Add the region constant** in `HolidayRegion.swift`, e.g. `static let japan = HolidayRegion("JP")`.
2. **Define any new holidays** as `CalendarHoliday` static values (in `Holiday.swift`, or in a new file like `Holiday+Japan.swift`). Give each one a **unique name**: the name is the holiday's identity for date rules, image caching and de-duplication.
3. **Give computed dates a rule.** Fixed dates work from the definition. Holidays like "third Monday of September" need a case in `CalendarHoliday.dateInYear(_:)`.
4. **Write the calendar**: `static let japan = HolidayCalendar(scope: .region(.japan), holidays: [...])`. Put it in `RegionalHolidayCalendars.swift`, or in its own file once it's large (like the US). A calendar may reuse existing holidays (e.g. `.laborDay` appears in both the US and Canada calendars).
5. **Register it** in `HolidayCatalog.calendars`.
6. **Run the tests** in `Simple CalendarTests/HolidayCatalogTests.swift`. New holidays that only appear in a calendar are appended to `HolidayCatalog.definitions` automatically, after the existing ones. Update the expected count in `definitionsKeepThePreviousListAndOrder`.

### Moving a holiday out of the worldwide calendar

Some worldwide holidays are only approximately worldwide. Move them to regional calendars when the right regional data exists:
- **Seasons** use Northern Hemisphere dates. Southern Hemisphere regions (Australia, New Zealand, South Africa, …) need their own season holidays, and the worldwide season entries should move to Northern Hemisphere calendars.
- **Mother's Day** (second Sunday of May) and **Father's Day** (third Sunday of June) use the most common dates. The UK and Ireland (Mothering Sunday in March), Australia and New Zealand (Father's Day in September) and others differ.

A holiday must stay in **at least one** calendar, or it will never be shown. The tests check this.

## Behavior change from before

Before this structure, every user saw every holiday. Now:
- **United States** users see the same holidays as before except four that belong to other regions: Canada Day, Bastille Day, Boxing Day and Walpurgis Night. They can add Canada, France, the UK and so on in Settings.
- **Users elsewhere** see the worldwide calendar plus their region's calendar, instead of the US holidays.

Holiday categories, their saved settings, holiday display order (tvOS shows the first two per day), date calculation and caching are unchanged.
