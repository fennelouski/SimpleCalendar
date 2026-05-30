//
//  String+Localized.swift
//  Simple Calendar
//
//  Created by Nathan Fennel on 12/01/25.
//

import Foundation

extension String {
    var localized: String {
        return NSLocalizedString(self, comment: "")
    }
    
    func localized(with arguments: CVarArg...) -> String {
        return String(format: self.localized, arguments: arguments)
    }
}
