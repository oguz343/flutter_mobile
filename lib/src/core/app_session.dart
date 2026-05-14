import '../models/app_user.dart';

class AppSession {
  static AppUser? currentUser;

  static void setUser(AppUser user) {
    currentUser = user;
  }

  static void clear() {
    currentUser = null;
  }

  static bool get isLoggedIn => currentUser != null;
}