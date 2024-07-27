import 'package:ifoot_academy/models/app_user.dart';

class AppState {
  final AppUser? user;

  AppState({this.user});

  // Initial state factory
  factory AppState.initial() {
    return AppState(user: null);
  }

  // Copy with method
  AppState copyWith({AppUser? user}) {
    return AppState(
      user: user ?? this.user,
    );
  }
}
