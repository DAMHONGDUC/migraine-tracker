import SwiftUI
import WidgetKit

/// The whole widget: the fixed log button, this week's count, the latest pressure.
struct BaroEaseWidgetView: View {
  let entry: BaroEaseEntry

  /// The app's own scheme.
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
          // Required wherever WeatherKit data is shown. Quiet and last: it has to be legible, not prominent.
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

/// The one control, drawn as the app's own hero button: a flat lavender fill, no gradient and no motion (hard rule 3 — the user is photophobic).
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

/// A quiet label with its number opposite.
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
          // Shrinks further than the value does before it gives up.
          .minimumScaleFactor(0.7)
        Spacer(minLength: 2)
        if let symbol {
          Image(systemName: symbol)
            .font(.system(size: 11, weight: .semibold))
            .foregroundColor(BaroEasePalette.textSecondary)
        }
        // The value wins the squeeze: a clipped label still names the row, a clipped number says nothing.
        Text(value)
          .font(.system(size: 14, weight: .semibold))
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
  /// iOS 17 requires a widget to declare its background through `containerBackground`, and refuses to draw one that does not.
  @ViewBuilder
  func widgetBackground(_ color: Color) -> some View {
    if #available(iOSApplicationExtension 17.0, *) {
      padding(EdgeInsets(top: 2, leading: 0, bottom: 2, trailing: 0))
        .containerBackground(color, for: .widget)
    } else {
      padding(EdgeInsets(top: 12, leading: 10, bottom: 12, trailing: 10))
        .background(color)
    }
  }
}
