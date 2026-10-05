import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_tracker/core/constants/legal_url_constant.dart';

void main() {
  // The paywall's Terms link is required by App Store 3.1.2, so an unset or
  // empty TERMS_OF_SERVICE_URL must still leave a link that opens.
  test('the terms link is never empty, whatever the build sets', () {
    final Uri uri = Uri.parse(LegalUrlConstant.termsOfUse);

    expect(uri.scheme, 'https');
    expect(uri.host, isNotEmpty);
  });
}
