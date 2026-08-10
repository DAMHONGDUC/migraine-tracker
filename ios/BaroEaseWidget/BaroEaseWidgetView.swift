import SwiftUI
import WidgetKit

/// The whole widget: the fixed log button, this week's count, the latest
/// pressure. The button is always there and always the same size — someone
/// reaching for it is mid-attack, so it must be found without reading.
///
/// The whole widget is one `Link` to the same place. A widget has no
/// hit-testing worth the name at this size, and there is only one thing to
/// do here, so a mistap still logs an attack rather than doing nothing.
struct BaroEaseWidgetView: View {
  let entry: BaroEaseEntry

  /// The app's own scheme. `HomeWidgetTapListener` reads the host.
  private let logURL = URL(string: "baroease://log")!

  var body: some View {
    Link(destination: logURL) {
      VStack(alignment: .leading, spacing: 12) {
        LogButton(label: entry.logLabel)
        StatRow(label: entry.weekLabel, value: entry.weekValue, detail: "", symbol: nil)
        StatRow(
          label: entry.pressureLabel,
          value: entry.pressureValue,
          detail: entry.pressureDetail,
          symbol: entry.pressureDetail.isEmpty ? nil : entry.trend.symbol
        )
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
    .widgetBackground(BaroEasePalette.background)
  }
}

/// The one control, drawn as the app's own hero button: a flat lavender fill,
/// no gradient and no motion (hard rule 3 — the user is photophobic).
private struct LogButton: View {
  let label: String

  var body: some View {
    HStack(spacing: 6) {
      Image(systemName: "plus")
        .font(.system(size: 14, weight: .bold))
      Text(label)
        .font(.system(size: 14, weight: .semibold))
        .lineLimit(1)
        .minimumScaleFactor(0.8)
    }
    .foregroundColor(BaroEasePalette.onPrimary)
    .frame(maxWidth: .infinity)
    .padding(.vertical, 10)
    .background(BaroEasePalette.primary)
    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
  }
}

/// A quiet label with its number under it. [detail] and [symbol] are the
/// pressure row's extra; the week row passes neither.
private struct StatRow: View {
  let label: String
  let value: String
  let detail: String
  let symbol: String?

  var body: some View {
    VStack(alignment: .leading, spacing: 2) {
      Text(label)
        .font(.system(size: 11, weight: .medium))
        .foregroundColor(BaroEasePalette.textSecondary)
      HStack(spacing: 4) {
        if let symbol {
          Image(systemName: symbol)
            .font(.system(size: 11, weight: .semibold))
            .foregroundColor(BaroEasePalette.textSecondary)
        }
        Text(value)
          .font(.system(size: 15, weight: .semibold))
          .foregroundColor(BaroEasePalette.textPrimary)
          .lineLimit(1)
          .minimumScaleFactor(0.8)
      }
      if !detail.isEmpty {
        Text(detail)
          .font(.system(size: 11))
          .foregroundColor(BaroEasePalette.textSecondary)
          .lineLimit(1)
      }
    }
  }
}

private extension View {
  /// iOS 17 requires a widget to declare its background through
  /// `containerBackground`, and refuses to draw one that does not. Below 17
  /// that modifier does not exist, so the plain background is the fallback —
  /// the extension ships to the same iOS 15 floor as the app.
  @ViewBuilder
  func widgetBackground(_ color: Color) -> some View {
    if #available(iOSApplicationExtension 17.0, *) {
      padding(16).containerBackground(color, for: .widget)
    } else {
      padding(16).background(color)
    }
  }
}
