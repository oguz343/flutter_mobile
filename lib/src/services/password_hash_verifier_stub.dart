import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

Future<bool> verifyPbkdf2Password(
  String enteredPassword,
  String storedHash,
) async {
  const prefix = 'PBKDF2_V1';
  final parts = storedHash.split(r'$');

  if (parts.length != 4 || parts.first != prefix) {
    return false;
  }

  final iterations = int.tryParse(parts[1]);

  if (iterations == null || iterations <= 0) {
    return false;
  }

  try {
    final salt = base64Decode(parts[2]);
    final expectedHash = base64Decode(parts[3]);
    final actualHash = _pbkdf2Sha256(
      password: utf8.encode(enteredPassword),
      salt: salt,
      iterations: iterations,
      length: expectedHash.length,
    );

    return _constantTimeEquals(actualHash, expectedHash);
  } catch (_) {
    return false;
  }
}

Future<String> hashPbkdf2Password(String password) async {
  const prefix = 'PBKDF2_V1';
  const iterations = 100000;
  const saltSize = 16;
  const hashSize = 32;

  final random = Random.secure();
  final salt = Uint8List.fromList(
    List<int>.generate(saltSize, (_) => random.nextInt(256)),
  );

  final hash = _pbkdf2Sha256(
    password: utf8.encode(password),
    salt: salt,
    iterations: iterations,
    length: hashSize,
  );

  return '$prefix\$$iterations\$${base64Encode(salt)}\$${base64Encode(hash)}';
}

Uint8List _pbkdf2Sha256({
  required List<int> password,
  required List<int> salt,
  required int iterations,
  required int length,
}) {
  final hmac = Hmac(sha256, password);
  final blockCount = (length / hmac.convert(<int>[]).bytes.length).ceil();
  final output = BytesBuilder(copy: false);

  for (var blockIndex = 1; blockIndex <= blockCount; blockIndex++) {
    final blockSalt = <int>[
      ...salt,
      (blockIndex >> 24) & 0xff,
      (blockIndex >> 16) & 0xff,
      (blockIndex >> 8) & 0xff,
      blockIndex & 0xff,
    ];

    var u = hmac.convert(blockSalt).bytes;
    final block = List<int>.from(u);

    for (var i = 1; i < iterations; i++) {
      u = hmac.convert(u).bytes;

      for (var j = 0; j < block.length; j++) {
        block[j] ^= u[j];
      }
    }

    output.add(block);
  }

  return Uint8List.fromList(output.toBytes().take(length).toList());
}

bool _constantTimeEquals(List<int> a, List<int> b) {
  if (a.length != b.length) {
    return false;
  }

  var diff = 0;

  for (var i = 0; i < a.length; i++) {
    diff |= a[i] ^ b[i];
  }

  return diff == 0;
}
