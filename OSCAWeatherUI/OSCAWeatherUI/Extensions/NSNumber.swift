//
//  NSNumber.swift
//  
//
//  Created by Ömer Kurutay on 17.02.22.
//

import Foundation

extension NSNumber {
  func toString(digits: Int) -> String {
    let formatter = NumberFormatter()
    formatter.locale = Locale.current
    formatter.maximumFractionDigits = digits
    formatter.usesGroupingSeparator = true
    formatter.numberStyle = .decimal
    
    return formatter.string(from: self) ?? "n/a"
  }
}
