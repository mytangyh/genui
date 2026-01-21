import 'package:flutter_test/flutter_test.dart';
import 'package:hexin_demo/src/catalog/markdown_render.dart';

void main() {
  test('MarkdownRender logic: code block fallback on bad json', () {
    final badJsonDsl = '''
# Test
```dsl
{"text": "line1\nline2"}
```
''';

    final segments = parseContentSegments(badJsonDsl);

    // Expected:
    // 1. Text segment: "# Test\n"
    // 2. Code segment (fallback from bad DSL)
    // 3. Text segment (newline/empty)

    expect(segments.length, greaterThanOrEqualTo(2));
    expect(segments[0].isText, isTrue);
    expect(segments[0].text, contains('# Test'));

    // The DSL block should have failed to parse and fallen back to code
    final codeSegment = segments.firstWhere((s) => s.isCode);
    expect(codeSegment, isNotNull);
    expect(codeSegment.language, 'dsl');
    expect(codeSegment.codeContent, contains('"text": "line1\nline2"'));
    expect(codeSegment.isDsl, isFalse);
  });

  test('MarkdownRender logic: code block for unknown language', () {
    final dartCode = '''
```dart
void main() {}
```
''';

    final segments = parseContentSegments(dartCode);
    final codeSegment = segments.firstWhere((s) => s.isCode);

    expect(codeSegment.language, 'dart');
    expect(codeSegment.codeContent, contains('void main() {}'));
    expect(codeSegment.isDsl, isFalse);
  });
}
