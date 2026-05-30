# Calendar Play

A beautiful, multi-platform calendar application for iOS, iPadOS, and macOS designed to help teach calendar concepts to kids while providing advanced features for adults.

![Calendar Play](https://img.shields.io/badge/platforms-iOS%20%7C%20iPadOS%20%7C%20macOS-blue)
![Build](https://img.shields.io/badge/build-passing-brightgreen)
![Swift](https://img.shields.io/badge/Swift-5.9-orange)
![License](https://img.shields.io/badge/license-MIT-green)

## 🌟 Features

### Core Calendar Features
- **Multi-platform Support**: Native apps for iOS, iPadOS, and macOS
- **Beautiful Interface**: Clean, child-friendly design with intuitive navigation
- **Grid Lines**: User-controllable grid line contrast (0-100%) for optimal readability
- **Daylight Visualization**: Color-coded daylight cycles on calendar days
- **Multiple View Modes**: Day, 2-day, 3-day, up to 9-day views, 2-week view, full month view, and full year overview
- **Year View**: Click month name to toggle full year calendar showing all 12 months at once
- **System Calendar Integration**: Sync with macOS Calendar app
- **Google Calendar Integration**: Connect and sync with Google Calendar

### Advanced Features
- **🎨 9 Color Themes**: Choose from Ocean, Forest, Sunset, Space, Candy, Autumn, Winter, Rainbow, and System themes (adapts to light/dark mode)
- **🔤 Font Customization**: 5 font size levels for accessibility
- **🖼️ Image Integration**: Beautiful Unsplash images for events with smart caching
- **🌤️ Weather Integration**: Weather forecasts for events with locations
- **🗺️ Map Integration**: Interactive maps for events with location data
- **🔗 Google Calendar**: Sync with your Google Calendar account
- **⚡ Quick Add**: Rapid event creation with Command+N
- **📤 Event Export**: Export events to other calendar applications
- **🔄 Refresh**: Command+R to refresh calendar data
- **🌅 Daylight Visualization**: Command+L to toggle daylight cycle display
- **⚙️ Settings**: Comprehensive settings with sub-menus for themes, typography, and features
- **⌨️ Keyboard Shortcuts**: Full keyboard navigation support

### Experimental Features (Feature Flags)
- **Agenda View**: List-based event view
- **Event Templates**: Predefined event templates for quick creation
- **Recurring Events**: Create events that repeat daily, weekly, or monthly
- **Event Reminders**: Get notified about upcoming events
- **Calendar Sharing**: Share calendars with family and friends (planned)
- **Natural Language Events**: Create events using plain English (planned)
- **AI Suggestions**: Smart event suggestions based on habits (planned)

## 🚀 Getting Started

### Prerequisites
- Xcode 15.0 or later
- iOS 17.0+, iPadOS 17.0+, or macOS 14.0+
- Swift 5.9+

### Installation

1. Clone the repository:
```bash
git clone https://github.com/fennelouski/SimpleCalendar.git
cd SimpleCalendar
```

2. Open the project in Xcode:
```bash
open "Simple Calendar.xcodeproj"
```

3. Build and run the app on your preferred platform (iOS, iPadOS, or macOS) - the app builds successfully on all platforms!

4. Set up API keys (optional for full functionality):
   - Get Unsplash API keys from [Unsplash Developers](https://unsplash.com/developers)
   - Get Google OAuth credentials from [Google Cloud Console](https://console.cloud.google.com/)
   - Get OpenAI API key from [OpenAI Platform](https://platform.openai.com/api-keys)

5. Configure environment variables for the Next.js backend:
   ```bash
   cp .env.example .env.local
   # Edit .env.local with your actual API keys
   ```

   Required environment variables:
   - `UNSPLASH_ACCESS_KEY`: Your Unsplash API access key
   - `OPENAI_API_KEY`: Your OpenAI API key (for event parsing)

## 🎮 Usage

### Basic Navigation
- **Next/Previous Month**: `n` / `p` keys
- **Today**: `t` key
- **Day Views**: `1-9` keys for 1-9 day views, `0` for 2-week view
- **Move Days**: Left/Right arrow keys
- **Move Weeks**: Up/Down arrow keys

### Advanced Features
- **Refresh Data**: `Command+R`
- **Toggle Daylight Visualization**: `Command+L`
- **Settings**: `Command+,`
- **New Event**: `Command+N`
- **Year View**: `Y`
- **Help**: `Command+?`
- **Quick Add Event**: `Command+N`
- **Search Events**: `Command+F`
- **Settings**: `Command+,`
- **Fullscreen**: `Command+Shift+F`
- **Help**: `Command+?`

### Event Management
- **Create Events**: Double-click on calendar days or use Quick Add
- **Edit Events**: Double-click events in detail view
- **Add Images**: Select images from Unsplash during event creation
- **Weather Info**: Automatic weather display for events with locations

## 🎨 Customization

### Color Themes
Choose from 8 beautiful themes:
- **Ocean**: Blues and sandy tones
- **Forest**: Greens and earthy colors
- **Sunset**: Warm pinks and oranges
- **Space**: Deep purples and blues
- **Candy**: Bright pastels
- **Autumn**: Reds, oranges, yellows
- **Winter**: Cool blues and whites
- **Rainbow**: Vibrant primary colors

### Font Sizes
- Extra Small (80% of normal)
- Small (90% of normal)
- Normal (100%)
- Large (110% of normal)
- Extra Large (125% of normal)

## 🏗️ Architecture

### Key Components
- **CalendarViewModel**: Central state management for calendar data
- **UIConfiguration**: Responsive UI system with fonts, padding, and colors
- **ThemeManager**: Color theme management
- **FeatureFlags**: Experimental feature toggles
- **ImageManager**: Unsplash integration with caching
- **WeatherManager**: Weather data integration
- **RequestQueueManager**: API rate limiting and queuing

### Design Patterns
- **MVVM**: Model-View-ViewModel architecture
- **ObservableObject**: Reactive state management
- **Environment Objects**: Dependency injection
- **Feature Flags**: Gradual feature rollout
- **Responsive Design**: Adaptive UI for different screen sizes
- **Cross-platform**: Conditional compilation for platform-specific features
- **Platform Types**: Unified type aliases for cross-platform compatibility

## 🔧 API Integration

### Unsplash (Images)
- **Rate Limited**: 3 requests/minute, 5 seconds between individual requests
- **Smart Caching**: 7-day local image cache
- **Attribution**: Optional photographer credit display

### Google Calendar
- **OAuth 2.0**: Secure authentication
- **Two-way Sync**: Read Google Calendar events
- **Multiple Accounts**: Support for multiple Google accounts

### Weather (Mock Implementation)
- **Location-based**: Weather for events with location data
- **Cached Results**: 30-minute cache duration
- **Extensible**: Easy to integrate real weather APIs

## 🧪 Feature Flags

Access experimental features through Settings > Feature Flags:

- Toggle features on/off without code changes
- Safe experimentation with new functionality
- Gradual rollout of advanced features

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/amazing-feature`
3. Commit changes: `git commit -m 'Add amazing feature'`
4. Push to branch: `git push origin feature/amazing-feature`
5. Open a Pull Request

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- **Unsplash**: Beautiful stock photos
- **Google Calendar API**: Calendar synchronization
- **SwiftUI**: Modern iOS/macOS UI framework
- **EventKit**: Native calendar integration

## 📞 Support

For questions, issues, or feature requests:
- Open an [issue](https://github.com/fennelouski/SimpleCalendar/issues) on GitHub
- Check the in-app help documentation (`Command+?`)

## 🌅 Daylight Visualization

The Daylight Visualization feature adds a beautiful 3-pixel high gradient bar to the top of each calendar day, showing the complete daylight cycle for that day.

### Color Coding
- **🌙 Night**: Black/dark colors for nighttime hours
- **🌅 Astronomical Twilight**: Very dark purple (barely visible before sunrise)
- **🌆 Nautical Twilight**: Dark purple (nautical navigation possible)
- **🌇 Civil Twilight**: Medium purple-blue (civil activities possible)
- **🌅 Sunrise**: Red-orange gradient during sunrise
- **✨ Golden Hour**: Golden yellow during morning golden hour
- **☀️ Daylight**: Blue gradient fading from light to rich blue during the day
- **🌇 Evening Golden Hour**: Golden yellow during evening golden hour
- **🌆 Sunset**: Red-orange gradient during sunset
- **🌙 Twilight Phases**: Reverse order of morning twilight

### How It Works
- Each calendar day square shows a horizontal gradient representing 24 hours
- Each pixel column represents 15 minutes (96 total periods per day)
- Sunrise/sunset times are calculated based on your location and season
- Toggle on/off with **Command+L** or through Settings > Feature Flags

### Educational Value
This feature helps users understand:
- Natural daylight cycles and their variation by season
- Sunrise and sunset timing for different days
- The science of twilight phases
- How daylight affects daily activities

---

**Built with ❤️ for teaching calendar concepts to kids while providing powerful features for adults.**
