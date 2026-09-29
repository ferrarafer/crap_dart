import 'dart:io';

import 'package:crap_dart/src/cli/runner.dart';

/// Entry point of the crap_dart executable.
Future<void> main(List<String> args) async {
  final code = await CrapDartRunner().run(args);
  if (code != 0) exitCode = code;
}
