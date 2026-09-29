import 'package:analyzer/dart/ast/ast.dart';

/// The declared name of the class, enum, mixin, extension type or
/// extension that encloses [node] (or is [node]): `null` for top-level
/// code, `''` for an unnamed extension.
String? enclosingContainerName(AstNode node) {
  for (AstNode? current = node; current != null; current = current.parent) {
    switch (current) {
      case ClassDeclaration(:final namePart):
      case EnumDeclaration(:final namePart):
      case ExtensionTypeDeclaration(:final namePart):
        return namePart.typeName.lexeme;
      case MixinDeclaration(:final name):
        return name.lexeme;
      case ExtensionDeclaration(:final name):
        return name?.lexeme ?? '';
    }
  }
  return null;
}
