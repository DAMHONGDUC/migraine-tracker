import SwiftUI

/// The app's palette, mirrored.
enum BaroEasePalette {
  /// AppColors.background
  static let background = Color(hex: 0x0E0E10)
  /// AppColors.surface
  static let surface = Color(hex: 0x1C1C1E)
  /// AppColors.primary
  static let primary = Color(hex: 0xA594F9)
  /// AppColors.onPrimary
  static let onPrimary = Color(hex: 0x1C1C1E)
  /// AppColors.textPrimary
  static let textPrimary = Color(hex: 0xE4E2E8)
  /// AppColors.textSecondary
  static let textSecondary = Color(hex: 0x9E9CA6)
}

extension Color {
  init(hex: UInt32) {
    self.init(
      .sRGB,
      red: Double((hex >> 16) & 0xFF) / 255,
      green: Double((hex >> 8) & 0xFF) / 255,
      blue: Double(hex & 0xFF) / 255,
      opacity: 1
    )
  }
}
