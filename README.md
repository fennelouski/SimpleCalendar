# Simple Calendar

A beautiful, multi-platform calendar application for iOS, iPadOS, and macOS designed to help teach calendar concepts to kids while providing advanced features for adults.

![Simple Calendar](https://img.shields.io/badge/platforms-iOS%20%7C%20iPadOS%20%7C%20macOS-blue)
![Build](https://img.shields.io/badge/build-passing-brightgreen)
![Swift](https://img.shields.io/badge/Swift-5.9-orange)
![License](https://img.shields.io/badge/license-MIT-green)

## 🌟 Features

### Core Calendar Features
- **Multi-platform Support**: Native apps for iOS, iPadOS, and macOS
- **Beautiful Interface**: Clean, child-friendly design with intuitive navigation
- **Multiple View Modes**: Day, 2-day, 3-day, up to 9-day views, 2-week view, and full month view
- **System Calendar Integration**: Sync with macOS Calendar app
- **Google Calendar Integration**: Connect and sync with Google Calendar

### Advanced Features
- **🎨 8 Color Themes**: Choose from Ocean, Forest, Sunset, Space, Candy, Autumn, Winter, and Rainbow themes
- **🔤 Font Customization**: 5 font size levels for accessibility
- **🖼️ Image Integration**: Beautiful Unsplash images for events with smart caching
- **🌤️ Weather Integration**: Weather forecasts for events with locations
- **🗺️ Map Integration**: Interactive maps for events with location data
- **⚡ Quick Add**: Rapid event creation with Command+N
- **📤 Event Export**: Export events to other calendar applications
- **🔄 Refresh**: Command+R to refresh calendar data
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
   - Replace placeholders in `UnsplashAPI.swift` and `GoogleOAuthManager.swift`

## 🎮 Usage

### Basic Navigation
- **Next/Previous Month**: `n` / `p` keys
- **Today**: `t` key
- **Day Views**: `1-9` keys for 1-9 day views, `0` for 2-week view
- **Move Days**: Left/Right arrow keys
- **Move Weeks**: Up/Down arrow keys

### Advanced Features
- **Refresh Data**: `Command+R`
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

---

**Built with ❤️ for teaching calendar concepts to kids while providing powerful features for adults.**
