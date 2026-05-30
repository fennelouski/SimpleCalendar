//
//  SmallWeatherIndicator.swift
//  Simple Calendar
//
//  Created by Nathan Fennel on 11/28/25.
//

import SwiftUI

// MARK: - Small Weather Indicator
struct SmallWeatherIndicator: View {
    let weatherInfo: WeatherInfo?
    let weatherForecast: WeatherForecast?
    let date: Date
    let displayState: WeatherDisplayState
    
    @EnvironmentObject var themeManager: ThemeManager
    
    private var calendar: Calendar {
        Calendar.current
    }
    
    var body: some View {
        Group {
            switch displayState {
            case .icon:
                if let icon = weatherIcon {
                    Image(systemName: icon)
                        .font(.system(size: 10))
                        .foregroundColor(weatherIconColor)
                        .frame(width: 12, height: 12)
                }
            case .highTemp:
                if let highTemp = highTemperature {
                    Text(highTemp)
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundColor(themeManager.currentPalette.textPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
            case .feelsLike:
                if let feelsLike = feelsLikeTemperature {
                    Text(feelsLike)
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundColor(themeManager.currentPalette.textSecondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
            }
        }
        .frame(width: 16, height: 12)
    }
    
    private var weatherIcon: String? {
        // Try to get from forecast first
        if let forecast = weatherForecast {
            let dailyForecast = forecast.daily.first { daily in
                calendar.isDate(daily.date, inSameDayAs: date)
            }
            return dailyForecast?.icon ?? forecast.current.icon
        }
        
        // Fallback to weather info
        return weatherInfo?.icon
    }
    
    private var weatherIconColor: Color {
        let condition = weatherCondition
        switch condition.lowercased() {
        case let cond where cond.contains("clear") || cond.contains("sunny"):
            return .yellow
        case let cond where cond.contains("cloudy"):
            return .gray
        case let cond where cond.contains("rain") || cond.contains("drizzle"):
            return .blue
        case let cond where cond.contains("snow"):
            return .white
        case let cond where cond.contains("thunderstorm"):
            return .purple
        case let cond where cond.contains("fog") || cond.contains("foggy"):
            return .gray.opacity(0.7)
        default:
            return .blue
        }
    }
    
    private var weatherCondition: String {
        if let forecast = weatherForecast {
            let dailyForecast = forecast.daily.first { daily in
                calendar.isDate(daily.date, inSameDayAs: date)
            }
            return dailyForecast?.condition ?? forecast.current.condition
        }
        
        return weatherInfo?.condition ?? ""
    }
    
    private var highTemperature: String? {
        if let forecast = weatherForecast {
            let dailyForecast = forecast.daily.first { daily in
                calendar.isDate(daily.date, inSameDayAs: date)
            }
            return dailyForecast?.maxTemperatureString
        }
        
        // Fallback to current temperature if no forecast
        return weatherInfo?.temperatureString
    }
    
    private var feelsLikeTemperature: String? {
        // Open-Meteo doesn't provide feels-like temperature in the free API
        // This would need to be calculated or obtained from a different source
        // For now, return nil so it doesn't show
        return nil
    }
}
