# Fix: AstronomicalInfoSection eventCount Always Returns 0

## Problem Description

In the tvOS version of the Simple Calendar app, the `AstronomicalInfoSection` view has a conditional display logic based on the number of events on a given date:
- **0 events**: Show full astronomical information (sunrise, sunset, daylight/night duration, and Daily Progression with twilight times)
- **1 event**: Show only sunrise and sunset
- **2+ events**: Show nothing

However, the `eventCount` parameter being passed to `AstronomicalInfoSection` is always 0, regardless of how many events actually exist on that date. This causes the full astronomical information to always be displayed, even when there are 1 or 2+ events.

## Current Implementation

### Location of Code
- File: `Simple Calendar/ContentView.swift`
- The `AstronomicalInfoSection` is called around line 1309
- The struct definition starts around line 1468

### Current Code Structure

1. **Where it's called** (in `DayDetailView`):
```swift
let dayEvents = calendarViewModel.events.filter { event in
    Calendar.current.isDate(event.startDate, inSameDayAs: date)
}

// ... later in the same VStack ...

#if os(tvOS)
AstronomicalInfoSection(date: date, eventCount: dayEvents.count)
#endif
```

2. **The struct definition**:
```swift
struct AstronomicalInfoSection: View {
    let date: Date
    let eventCount: Int  // This is always 0
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var uiConfig: UIConfiguration
    
    var body: some View {
        Group {
            if eventCount >= 2 {
                EmptyView()
            } else if let data = astronomicalData {
                if eventCount == 1 {
                    // Show only sunrise/sunset
                } else if eventCount == 0 {
                    // Show full information including Daily Progression
                }
            }
        }
    }
}
```

## What We've Tried

1. **Passing `dayEvents.count` directly**: The `dayEvents` array is calculated correctly in the parent view and has the right count, but when passed to `AstronomicalInfoSection`, it becomes 0.

2. **Calculating eventCount inside AstronomicalInfoSection**: We tried making `eventCount` a computed property that filters `calendarViewModel.events` directly:
```swift
private var eventCount: Int {
    calendarViewModel.events.filter { event in
        Calendar.current.isDate(event.startDate, inSameDayAs: date)
    }.count
}
```
This also always returned 0.

3. **Using `startOfDay` comparison**: We tried using the same date comparison method used elsewhere in the codebase:
```swift
private var eventCount: Int {
    let calendar = Calendar.current
    let dayStart = calendar.startOfDay(for: date)
    return calendarViewModel.events.filter { event in
        let eventStart = calendar.startOfDay(for: event.startDate)
        return eventStart == dayStart
    }.count
}
```
This also always returned 0.

4. **Adding @EnvironmentObject for calendarViewModel**: We tried accessing `calendarViewModel` as an environment object inside `AstronomicalInfoSection`, but the event count was still 0.

## Key Observations

- The `dayEvents` array in `DayDetailView` is calculated correctly and shows the right count when debugging
- The same filter logic works correctly elsewhere in the codebase (e.g., line 845-848)
- The `date` parameter being passed to `AstronomicalInfoSection` is correct
- The issue seems to be that `eventCount` becomes 0 somewhere between being calculated and being used in the conditional logic

## Acceptance Criteria

The fix is complete when:

1. ✅ When there are **0 events** on a date: Show full astronomical information including:
   - Sunrise and sunset (side by side)
   - Daylight and night duration (side by side)
   - Daily Progression section with all twilight times

2. ✅ When there is **1 event** on a date: Show only:
   - Sunrise and sunset (side by side)
   - NO Daily Progression section

3. ✅ When there are **2 or more events** on a date: Show nothing (EmptyView)

4. ✅ The `eventCount` correctly reflects the actual number of events for the given date

5. ✅ The solution works consistently across different dates with different event counts

## Additional Context

- This is a tvOS-specific feature (`#if os(tvOS)`)
- The `AstronomicalInfoSection` is displayed in the `DayDetailView` which is shown in a slide-out panel
- The `calendarViewModel.events` array contains all events and is populated from both system calendars and Google Calendar
- The date filtering logic using `Calendar.current.isDate(event.startDate, inSameDayAs: date)` works correctly in other parts of the codebase

## Files to Examine

- `Simple Calendar/ContentView.swift` - Contains both `DayDetailView` and `AstronomicalInfoSection`
- `Simple Calendar/CalendarViewModel.swift` - Contains the events array and event loading logic

## Suggested Debugging Approach

1. Add print statements to verify:
   - What `dayEvents.count` is when calculated in `DayDetailView`
   - What `eventCount` is when received in `AstronomicalInfoSection`
   - What `calendarViewModel.events.count` is at various points
   - What the `date` parameter value is

2. Check if there's a timing issue where events haven't loaded yet when the view is rendered

3. Verify that the `date` parameter in `AstronomicalInfoSection` matches the `date` used to calculate `dayEvents`

4. Consider if there's a SwiftUI view update/refresh issue causing stale values

