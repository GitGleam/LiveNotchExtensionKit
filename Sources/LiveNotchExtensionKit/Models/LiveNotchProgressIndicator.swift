//
//  LiveNotchProgressIndicator.swift
//  LiveNotchExtensionKit
//
//  Progress indicator configurations for live activities.
//

import Foundation
import CoreGraphics

/// Visual representation of progress within a live activity.
public enum LiveNotchProgressIndicator: Codable, Sendable, Hashable {
    /// Circular ring progress (like timer)
    case ring(diameter: CGFloat = 24, strokeWidth: CGFloat = 3, color: LiveNotchColorDescriptor? = nil)
    
    /// Horizontal progress bar
    case bar(width: CGFloat? = nil, height: CGFloat = 4, cornerRadius: CGFloat = 2, color: LiveNotchColorDescriptor? = nil)
    
    /// Percentage text display
    case percentage(font: LiveNotchFontDescriptor = .system(size: 13, weight: .semibold), color: LiveNotchColorDescriptor? = nil)
    
    /// Countdown timer (mm:ss or HH:mm:ss format)
    case countdown(font: LiveNotchFontDescriptor = .monospacedDigit(size: 13, weight: .semibold), color: LiveNotchColorDescriptor? = nil)
    
    /// Custom Lottie animation (must provide animation data)
    case lottie(animationData: Data, size: CGSize = CGSize(width: 30, height: 30))
    
    /// No progress indicator
    case none
}

/// Font descriptor for text-based elements.
public struct LiveNotchFontDescriptor: Codable, Sendable, Hashable {
    public let size: CGFloat
    public let weight: LiveNotchFontWeight
    public let design: LiveNotchFontDesign
    public let isMonospacedDigit: Bool
    
    public init(size: CGFloat, weight: LiveNotchFontWeight = .regular, design: LiveNotchFontDesign = .default, isMonospacedDigit: Bool = false) {
        self.size = size
        self.weight = weight
        self.design = design
        self.isMonospacedDigit = isMonospacedDigit
    }
    
    public static func system(size: CGFloat, weight: LiveNotchFontWeight = .regular, design: LiveNotchFontDesign = .default) -> LiveNotchFontDescriptor {
        LiveNotchFontDescriptor(size: size, weight: weight, design: design, isMonospacedDigit: false)
    }
    
    public static func monospacedDigit(size: CGFloat, weight: LiveNotchFontWeight = .regular) -> LiveNotchFontDescriptor {
        LiveNotchFontDescriptor(size: size, weight: weight, design: .default, isMonospacedDigit: true)
    }
}

public enum LiveNotchFontWeight: String, Codable, Sendable, Hashable {
    case ultraLight, thin, light, regular, medium, semibold, bold, heavy, black
}

public enum LiveNotchFontDesign: String, Codable, Sendable, Hashable {
    case `default`, serif, rounded, monospaced
}
