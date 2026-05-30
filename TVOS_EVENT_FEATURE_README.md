# tvOS Event Management Feature

This document explains the new experimental tvOS feature that allows users to manage calendar events using voice input and AI-powered natural language processing.

## Overview

When users press the play/pause button while viewing the day detail slide-out on tvOS, they now get access to a comprehensive event management interface that includes:

1. **Event List View**: Shows all existing events for the selected date with options to view details, edit, or delete events
2. **Voice-Powered Event Creation**: Users can speak naturally to describe events, which are then parsed by AI
3. **Manual Event Editing**: Full editing capabilities with Siri remote keyboard input
4. **AI-Powered Parsing**: Natural language descriptions are converted to structured event data using OpenAI's GPT-4o-mini

## Features

### Natural Language Input
- Type or dictate your event description using the Siri remote keyboard
- Describe events naturally: "Doctor appointment at 2 PM tomorrow" or "My kids have school from 8:30 to 3:45 Monday through Friday"
- Tap "Parse Event" to send to AI for processing
- The AI automatically parses:
  - Event titles
  - Dates and times
  - Locations
  - Recurring patterns
  - Duration inference

### Event Management
- View all events for a selected date
- Create new events with voice or manual input
- Edit existing events
- Delete events
- Support for recurring events (stored as text notes for now)

### Siri Remote Navigation
- Full Siri remote support for navigation and text input
- Siri remote keyboard for typing event descriptions
- Directional buttons for navigating form fields
- Select button to activate fields and buttons

## Technical Implementation

### Files Added/Modified

#### Swift Files
- `Simple Calendar/TVEventManagementView.swift` - Main event management interface
- `Simple Calendar/TVEventCreationView.swift` - Event creation/editing form with voice input
- `Simple Calendar/ContentView.swift` - Modified to handle play/pause button for event management
- `Simple Calendar/CalendarViewModel.swift` - Added `showTVEventManagement` state
- `Simple Calendar/Info.tvOS.plist` - Added speech recognition permissions

#### API Files
- `app/api/parse-event/route.ts` - Vercel API endpoint for AI-powered event parsing
- `package.json` - Added OpenAI dependency

### API Endpoint

The Vercel API endpoint (`/api/parse-event`) accepts POST requests with:
```json
{
  "description": "Doctor appointment at 2 PM tomorrow",
  "selectedDate": "2024-12-01T00:00:00Z"
}
```

And returns structured event data:
```json
{
  "title": "Doctor appointment",
  "startDate": "2024-12-02T14:00:00Z",
  "endDate": "2024-12-02T15:00:00Z",
  "isAllDay": false,
  "location": null,
  "notes": null,
  "recurrence": null
}
```

## Deployment Instructions

### 1. Deploy to Vercel

1. Push the Next.js app to a Git repository
2. Connect the repository to Vercel
3. Deploy the app

### 2. Configure Environment Variables

In your Vercel dashboard, add the environment variable:
- `OPENAI_API_KEY`: Your OpenAI API key (already mentioned as configured)

### 3. Update API URL

In `Simple Calendar/TVEventCreationView.swift`, replace the placeholder URL:
```swift
let url = URL(string: "https://your-calendar-play-api.vercel.app/api/parse-event")!
```
Replace `your-calendar-play-api` with your actual Vercel app name.

### 4. Test the Feature

1. Build and run the tvOS app
2. Navigate to a date in month view
3. Press the play/pause button to open day detail
4. Press play/pause again to access event management
5. Try creating events with voice input

## Example Voice Commands

The AI can understand various natural language patterns:

- **Simple events**: "Doctor appointment at 2 PM"
- **Dated events**: "Meeting tomorrow at 3 PM"
- **Recurring events**: "School Monday through Friday from 8:30 to 3:45"
- **Events with locations**: "Dinner at Olive Garden at 7 PM"
- **Complex events**: "Weekly team meeting every Tuesday at 10 AM for the next 3 months"

## Limitations

- Recurring events are stored as text notes (full recurrence implementation would require additional calendar integration)
- Date/time parsing relies on AI accuracy
- Text input is done via Siri remote keyboard (voice dictation may be available depending on tvOS version)
- Location resolution is basic (AI suggests addresses but doesn't validate them)
- Speech recognition framework is not available on tvOS (text input only)

## Future Enhancements

- Full calendar integration for recurring events
- Location validation and maps integration
- Voice feedback and confirmation
- Event templates and quick actions
- Integration with external calendar services

## Troubleshooting

### API Issues
- Check Vercel deployment logs for OpenAI API errors
- Verify OPENAI_API_KEY is set in Vercel environment
- Test API endpoint directly with curl/Postman

### Voice Input Issues
- Ensure speech recognition permission is granted in tvOS settings
- Test in quiet environment for better recognition
- Check device microphone access

### Navigation Issues
- Ensure Siri remote is properly paired
- Test focus movement with directional buttons
- Verify play/pause button handling

## Support

If you encounter issues, check:
1. Xcode build logs for compilation errors
2. Vercel deployment logs for API issues
3. tvOS device logs for runtime errors
4. OpenAI API usage dashboard for rate limits
