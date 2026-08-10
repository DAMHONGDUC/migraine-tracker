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
  ///
  /// **The `homeWidget` query item is load-bearing.** The plugin's
  /// `isWidgetUrl` matches on that parameter's presence and silently ignores
  /// any URL without it, so `baroease://log` reached the app and went
  /// nowhere — the app just opened on the dashboard. Its value is never read.
  private let logURL = URL(string: "baroease://log?homeWidget=true")!

  var body: some View {
    Link(destination: logURL) {
      VStack(alignment: .leading, spacing: 10) {
        LogButton(label: entry.logLabel)
        StatRow(label: entry.weekLabel, value: entry.weekValue, detail: "", symbol: nil)
        StatRow(
          label: entry.pressureLabel,
          value: entry.pressureValue,
          detail: entry.pressureDetail,
          symbol: entry.pressureDetail.isEmpty ? nil : entry.trend.symbol
        )
        Spacer(minLength: 0)
        if !entry.attribution.isEmpty {
          // Required wherever WeatherKit data is shown. Quiet and last: it
          // has to be legible, not prominent.
          Text(entry.attribution)
            .font(.system(size: 9))
            .foregroundColor(BaroEasePalette.textSecondary)
            .lineLimit(1)
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
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
    .padding(.vertical, 11)
    .background(BaroEasePalette.primary)
    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
  }
}

/// A quiet label with its number opposite. [detail] and [symbol] are the
/// pressure row's extra; the week row passes neither.
///
/// Label and value share a line rather than stacking, which is what keeps a
/// small widget from spending most of its height on two-line rows — and it
/// puts both values on one right edge, so they read as a pair.
private struct StatRow: View {
  let label: String
  let value: String
  let detail: String
  let symbol: String?

  var body: some View {
    VStack(alignment: .trailing, spacing: 1) {
      HStack(alignment: .firstTextBaseline, spacing: 6) {
        Text(label)
          .font(.system(size: 12, weight: .medium))
          .foregroundColor(BaroEasePalette.textSecondary)
          .lineLimit(1)
          .minimumScaleFactor(0.8)
        Spacer(minLength: 2)
        if let symbol {
          Image(systemName: symbol)
            .font(.system(size: 11, weight: .semibold))
            .foregroundColor(BaroEasePalette.textSecondary)
        }
        // The value wins the squeeze: a clipped label still names the row,
        // a clipped number says nothing.
        Text(value)
          .font(.system(size: 16, weight: .semibold))
          .foregroundColor(BaroEasePalette.textPrimary)
          .lineLimit(1)
          .minimumScaleFactor(0.75)
          .layoutPriority(1)
      }
      if !detail.isEmpty {
        Text(detail)
          .font(.system(size: 11))
          .foregroundColor(BaroEasePalette.textSecondary)
          .lineLimit(1)
          .minimumScaleFactor(0.8)
      }
    }
  }
}

private extension View {
  /// iOS 17 requires a widget to declare its background through
  /// `containerBackground`, and refuses to draw one that does not. Below 17
  /// that modifier does not exist, so the plain background is the fallback —
  /// the extension ships to the same iOS 15 floor as the app.
  ///
  /// Tighter at the sides than top and bottom: a small widget is ~155pt wide,
  /// so every point spent on side air is a point the log button and the
  /// readings do not get.
  ///
  /// These are the ONLY horizontal margins, and only because the widget
  /// disables the system's own — iOS 17 adds ~16pt of content margin of its
  /// own, which stacked on top of this and took roughly a third of the width.
  /// See `contentMarginsDisabled` in BaroEaseWidget.swift: remove that and
  /// these numbers are wrong again.
  @ViewBuilder
  func widgetBackground(_ color: Color) -> some View {
    let insets = EdgeInsets(top: 12, leading: 10, bottom: 12, trailing: 10)

    if #available(iOSApplicationExtension 17.0, *) {
      padding(insets).containerBackground(color, for: .widget)
    } else {
      padding(insets).background(color)
    }
  }
}
