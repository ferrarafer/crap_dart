import 'dart:io';

import 'package:crap_dart/src/gates/method_size_gate.dart';
import 'package:test/test.dart';

import 'gate_test_utils.dart';

void main() {
  const gate = MethodSizeGate();

  late Directory project;

  setUp(() => project = createTempProject());
  tearDown(() => project.deleteSync(recursive: true));

  test('unnamed constructors are reported under their type name', () async {
    writeFile(project, 'lib/a.dart', '''
class C {
  C(int a, int b, int c);
}
enum E {
  one(1, 2, 3);
  const E(this.a, this.b, this.c);
  final int a, b, c;
}
extension type T(int v) {
  T.of(int a, int b, int c) : v = a + b + c;
}
''');
    final result = await gate.run(
      makeContext(project, [
        'lib/a.dart',
      ], configYaml: 'gates:\n  method_size:\n    max_params: 2\n'),
    );
    expect(result.violations.map((v) => v.message), [
      'C has 3 params > max 2',
      'E has 3 params > max 2',
      'of has 3 params > max 2',
    ]);
  });
}
