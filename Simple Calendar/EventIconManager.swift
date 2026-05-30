//
//  EventIconManager.swift
//  Simple Calendar
//
//  Created by Nathan Fennel on 11/28/25.
//

import SwiftUI

// MARK: - Event Icon Mapping
struct EventIconManager {
    static let wordToEmoji: [String: String] = [
        // Birthdays & Personal
        "birthday": "🎂",
        "birth": "👶",
        "anniversary": "💍",
        "wedding": "💒",
        "party": "🎉",
        "celebration": "🎊",
        
        // Holidays
        "christmas": "🎄",
        "holiday": "🎁",
        "halloween": "🎃",
        "thanksgiving": "🦃",
        "easter": "🐰",
        "valentine": "💝",
        "new year": "🎆",
        "independence": "🇺🇸",
        "labor": "👷",
        
        // Work & School
        "meeting": "👥",
        "conference": "🎤",
        "presentation": "📊",
        "interview": "💼",
        "deadline": "⏰",
        "school": "🎓",
        "class": "📚",
        "exam": "📝",
        "homework": "✏️",
        "lecture": "👨‍🏫",
        "seminar": "📖",
        
        // Health & Medical
        "doctor": "👨‍⚕️",
        "dentist": "🦷",
        "appointment": "📅",
        "checkup": "🏥",
        "therapy": "🧠",
        "gym": "💪",
        "workout": "🏋️‍♂️",
        "yoga": "🧘‍♀️",
        
        // Travel & Transportation
        "flight": "✈️",
        "train": "🚂",
        "bus": "🚌",
        "car": "🚗",
        "taxi": "🚕",
        "uber": "🚗",
        "vacation": "🏖️",
        "trip": "🗺️",
        "hotel": "🏨",
        
        // Food & Dining
        "dinner": "🍽️",
        "lunch": "🥗",
        "breakfast": "🥞",
        "coffee": "☕",
        "restaurant": "🍽️",
        "bar": "🍸",
        "date": "💑",
        
        // Sports & Activities
        "game": "⚽",
        "match": "🏆",
        "practice": "🏃‍♂️",
        "concert": "🎵",
        "movie": "🎬",
        "theater": "🎭",
        "museum": "🏛️",
        "park": "🌳",
        
        // Family & Social
        "family": "👨‍👩‍👧‍👦",
        "kids": "👶",
        "parent": "👨‍👩‍👧",
        "friend": "👫",
        "call": "📞",
        "video": "📹",
        
        // Time-based
        "morning": "🌅",
        "afternoon": "☀️",
        "evening": "🌆",
        "night": "🌙",
        "weekend": "🏖️",
        
        // Generic
        "event": "📅",
        "reminder": "🔔",
        "important": "⚠️",
        "urgent": "🚨"
    ]
    
    static func emojiForEvent(_ title: String) -> String? {
        let lowercasedTitle = title.lowercased()
        
        // Check for exact matches first
        for (word, emoji) in wordToEmoji {
            if lowercasedTitle.contains(word) {
                return emoji
            }
        }
        
        return nil
    }
    
    static func initialsForEvent(_ title: String) -> String {
        let words = title.components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
        
        if words.count == 1 {
            // Single word - take first 2 letters
            return String(words[0].prefix(2)).uppercased()
        } else if words.count <= 8 {
            // Multiple words - take first letter of first 2-3 words
            let initials = words.prefix(3).compactMap { $0.first }.map { String($0) }
            return initials.joined().uppercased()
        } else {
            // Too many words - just show generic event
            return "📅"
        }
    }
    
    static func compactRepresentation(for title: String, maxLength: Int = 8, cellWidth: CGFloat) -> String {
#if os(iOS)
        if title.count > maxLength && cellWidth < 40 {
            // Use emoji if available, otherwise use initials
            if let emoji = emojiForEvent(title) {
                return emoji
            } else {
                return initialsForEvent(title)
            }
        }
#endif
        
        // Default: return the title (potentially truncated)
        return title.count > maxLength ? String(title.prefix(maxLength)) + "..." : title
    }
}
