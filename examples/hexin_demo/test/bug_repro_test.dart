import 'package:flutter_test/flutter_test.dart';
import 'package:hexin_dsl/hexin_dsl.dart';

void main() {
  test('repro _unescapeContent bug', () {
    String _unescapeContent(String input) {
      return input.replaceAll('\\n', '\n').replaceAll('\\t', '\t');
    }

    // A DSL block with a JSON string containing an escaped quote.
    // The JSON we want is: {"props": {"text": "Say \"Hello\""}}
    // In Dart string literal for that JSON: '{"props": {"text": "Say \\"Hello\\""}}'
    // If this entire thing is inside a content string, and assuming no extra escaping from transport:
    // content = ...

    // Case 1: The input string has literal backslash and quote sequence (e.g. from a double-escaped source)
    // If the input is indeed double escaped, then `_unescapeContent` is correct.
    // But if the input is NOT double escaped, but just contains JSON structure which naturally uses `\"` for quotes in strings.

    // Let's assume the user provides this content:
    const dslJson = '{"props": {"text": "Say \\"Hello\\""}}';
    const content = '```dsl\n$dslJson\n```';

    print('Original content: $content');

    final unescaped = _unescapeContent(content);
    print('Unescaped content: $unescaped');

    // The unescaped content should still have valid JSON.
    // The JSON parser needs `\"` to parse the quote inside the string.
    // If `_unescapeContent` turns `\"` into `"`, it becomes `Say "Hello"`, which opens and closes string at "Say ", leaves Hello" hanging.

    expect(
      unescaped,
      contains('Say \\"Hello\\"'),
      reason: 'Should preserve escaped quotes in JSON',
    );
  });

  test('extractMixedBlocks preserves order', () {
    const markdown = '''
Step 1:
```dsl
{"id": 1}
```

Step 2:
```web
{"id": 2}
```

Step 3:
```dsl
{"id": 3}
```
''';

    final blocks = DslParser.extractMixedBlocks(
      markdown,
      languages: ['dsl', 'web'],
      transformer: (data, language) {
        return {'lang': language, ...data};
      },
    );

    expect(blocks.length, 3);
    expect(blocks[0]['id'], 1);
    expect(blocks[0]['lang'], 'dsl');

    expect(blocks[1]['id'], 2);
    expect(blocks[1]['lang'], 'web');

    expect(blocks[2]['id'], 3);
    expect(blocks[2]['lang'], 'dsl');
  });
}
