import 'dart:convert';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

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
    final subtle = web.window.crypto.subtle;

    final key = await subtle
        .importKey(
          'raw',
          Uint8List.fromList(utf8.encode(enteredPassword)).toJS,
          _jsObject({'name': 'PBKDF2'.toJS}),
          false,
          ['deriveBits'.toJS].toJS,
        )
        .toDart;

    final bits = await subtle
        .deriveBits(
          _jsObject({
            'name': 'PBKDF2'.toJS,
            'salt': Uint8List.fromList(salt).toJS,
            'iterations': iterations.toJS,
            'hash': 'SHA-256'.toJS,
          }),
          key,
          expectedHash.length * 8,
        )
        .toDart;

    return _constantTimeEquals(bits.toDart.asUint8List(), expectedHash);
  } catch (_) {
    return false;
  }
}

Future<String> hashPbkdf2Password(String password) async {
  const prefix = 'PBKDF2_V1';
  const iterations = 100000;
  const saltSize = 16;
  const hashSize = 32;

  final salt = Uint8List(saltSize);
  web.window.crypto.getRandomValues(salt.toJS);
  final subtle = web.window.crypto.subtle;

  final key = await subtle
      .importKey(
        'raw',
        Uint8List.fromList(utf8.encode(password)).toJS,
        _jsObject({'name': 'PBKDF2'.toJS}),
        false,
        ['deriveBits'.toJS].toJS,
      )
      .toDart;

  final bits = await subtle
      .deriveBits(
        _jsObject({
          'name': 'PBKDF2'.toJS,
          'salt': salt.toJS,
          'iterations': iterations.toJS,
          'hash': 'SHA-256'.toJS,
        }),
        key,
        hashSize * 8,
      )
      .toDart;

  final hash = bits.toDart.asUint8List();
  return '$prefix\$$iterations\$${base64Encode(salt)}\$${base64Encode(hash)}';
}

JSObject _jsObject(Map<String, JSAny> properties) {
  final object = JSObject();

  for (final entry in properties.entries) {
    object.setProperty(entry.key.toJS, entry.value);
  }

  return object;
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
