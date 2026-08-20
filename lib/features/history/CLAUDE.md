# History

- **`HistoryViewToggle`'s thumb is a solid `colorScheme.primary`, and the
  selected glyph inverts to `onPrimary`.** Owner's call. It was a 22%-alpha wash
  with a merely tinted glyph, which over a frosted track on a dark background
  left the two states nearly indistinguishable — and which view you are in is
  the only thing that control says. `onPrimary` is `#1C1C1E`, so the filled thumb
  stays a dark-mode surface rather than a bright one (hard rule 3).
  - The track carries a hairline edge too: frosted glass alone left its bounds
    guessable against the app bar.
  - **`SdSegmentedTabsV2` keeps the quieter 0.22 thumb.** Its segments are
    labelled text in content, where the label already says which is which; this
    one is icon-only chrome.
