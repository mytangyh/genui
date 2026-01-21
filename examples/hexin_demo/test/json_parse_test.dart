import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('repro json control character error', () {
    // This string contains a literal newline inside the JSON string value
    const badJson = '{"text": "line1\nline2"}';

    try {
      json.decode(badJson);
      fail('Should have thrown FormatException');
    } catch (e) {
      print('Caught expected error: $e');
      expect(e, isA<FormatException>());
      expect(e.toString(), contains('Control character in string'));
    }
  });
}
