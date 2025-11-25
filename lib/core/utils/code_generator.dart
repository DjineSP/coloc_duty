// lib/core/utils/code_generator.dart
import 'dart:math';

class CodeGenerator {
  static String generateInviteCode() {
    const String chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // sans I, O, 0, 1
    Random rnd = Random();
    return String.fromCharCodes(Iterable.generate(
      6,
          (_) => chars.codeUnitAt(rnd.nextInt(chars.length)),
    ));
  }
}