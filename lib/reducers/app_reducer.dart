import 'package:ifoot_academy/presantation/drawer.dart';

import '../actions/index.dart';
import '../models/app_state.dart';

AppState appReducer(AppState state, dynamic action) {
  if (action is LoginSuccessful) {
    print("Handling LoginSuccessful action in reducer");
    return state.copyWith(user: action.user);
  } else if (action is RegisterSuccessful) {
    print("Handling RegisterSuccessful action in reducer");
    return state.copyWith(); // Assuming no user data on registration
  } else if (action is LoginError || action is RegisterError) {
    print("Handling Error action in reducer: ${action.error}");
    // Handle errors if needed
    return state;
  } else if (action is SignOut) {
    print("Handling SignOut action in reducer");
    return AppState.initial();
  }
  return state;
}
