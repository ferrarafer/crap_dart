import 'dart:io';

import 'package:crap_dart/src/gates/public_docs_gate.dart';
import 'package:test/test.dart';

import 'gate_test_utils.dart';

void main() {
  const gate = PublicDocsGate();

  late Directory project;

  setUp(() => project = createTempProject());
  tearDown(() => project.deleteSync(recursive: true));

  test('members of private containers are not public API', () async {
    writeFile(project, 'lib/a.dart', '''
enum _E { a; void m() {} }
mixin _M { void m() {} }
extension type _T(int v) { void m() {} }
extension _X on int { void m() {} }
extension on String { void m() {} }
''');
    final result = await gate.run(makeContext(project, ['lib/a.dart']));
    expect(result.violations, isEmpty);
  });

  test('members of public containers need docs', () async {
    writeFile(project, 'lib/a.dart', '''
/// E.
enum E { a; void e() {} }
/// M.
mixin M { void m() {} }
/// T.
extension type T(int v) { void t() {} }
/// X.
extension X on int { void x() {} }
''');
    final result = await gate.run(makeContext(project, ['lib/a.dart']));
    final messages = result.violations.map((v) => v.message).join('\n');
    for (final name in ['e', 'm', 't', 'x']) {
      expect(messages, contains('method "$name"'));
    }
  });
}
