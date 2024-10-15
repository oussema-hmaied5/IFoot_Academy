import 'package:ifoot_academy/models/app_user.dart';

class AppState {
  final AppUser? user;

  AppState({this.user});

  AppState copyWith({AppUser? user}) {
    return AppState(user: user ?? this.user);
  }

  factory AppState.initial() {
    return AppState(user: null);
  }
}
