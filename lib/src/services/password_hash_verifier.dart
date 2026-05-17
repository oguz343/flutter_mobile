import 'password_hash_verifier_stub.dart'
    if (dart.library.html) 'password_hash_verifier_web.dart'
    as impl;

Future<bool> verifyPbkdf2Password(String enteredPassword, String storedHash) {
  return impl.verifyPbkdf2Password(enteredPassword, storedHash);
}

Future<String> hashPbkdf2Password(String password) {
  return impl.hashPbkdf2Password(password);
}
