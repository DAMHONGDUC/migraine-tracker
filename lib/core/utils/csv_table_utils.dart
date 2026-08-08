/// Reads CSV text back into rows and cells.
///
/// Hand-written rather than a package because the app writes this CSV itself
/// (`DataExportService.toCsv`) and only has to read back what it wrote: RFC
/// 4180 quoting, `""` for a literal quote, CRLF or LF between records.
final class CsvTableUtils {
  /// Rows of cells, header first. An empty input is no rows at all.
  ///
  /// A quoted field may hold commas and line breaks, so this walks characters
  /// rather than splitting on `,` and `\n` — splitting is what turns one
  /// note containing a comma into two columns.
  static List<List<String>> parse(String csv) {
    final List<List<String>> rows = <List<String>>[];
    final StringBuffer cell = StringBuffer();
    List<String> row = <String>[];
    bool quoted = false;
    int i = 0;

    void endCell() {
      row.add(cell.toString());
      cell.clear();
    }

    void endRow() {
      endCell();
      rows.add(row);
      row = <String>[];
    }

    while (i < csv.length) {
      final String char = csv[i];

      if (quoted) {
        if (char == '"') {
          // A doubled quote is one literal quote, not the end of the field.
          if (i + 1 < csv.length && csv[i + 1] == '"') {
            cell.write('"');
            i += 2;
            continue;
          }
          quoted = false;
          i++;
          continue;
        }
        cell.write(char);
        i++;
        continue;
      }

      if (char == '"') {
        quoted = true;
        i++;
      } else if (char == ',') {
        endCell();
        i++;
      } else if (char == '\r' || char == '\n') {
        endRow();
        // CRLF is one break, not two.
        i += char == '\r' && i + 1 < csv.length && csv[i + 1] == '\n' ? 2 : 1;
      } else {
        cell.write(char);
        i++;
      }
    }

    // Whatever is left is a final row without a trailing break.
    if (cell.isNotEmpty || row.isNotEmpty) endRow();

    return rows;
  }
}
