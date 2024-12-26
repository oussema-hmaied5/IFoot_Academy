import 'package:ifoot_academy/models/app_user.dart';

class AppState {
  final AppUser? user;
  final String? errorMessage;

  AppState({this.user, this.errorMessage});

  AppState copyWith({AppUser? user, String? errorMessage}) {
    return AppState(
      user: user ?? this.user,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  factory AppState.initial() {
    return AppState(
      user: null,
      errorMessage: null,
    );
  }
}
