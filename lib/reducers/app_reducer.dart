import 'package:ifoot_academy/presantation/Drawer/drawer.dart';

import '../actions/index.dart';
import '../models/app_state.dart';

AppState appReducer(AppState state, dynamic action) {
  if (action is LoginSuccessful) {
    return state.copyWith(user: action.user);
  } else if (action is RegisterSuccessful) {
    return state.copyWith(); // Assuming no user data on registration
  } else if (action is LoginError || action is RegisterError) {
    // Handle errors if needed
    return state;
  } else if (action is SignOut) {
    return AppState.initial();
  }
  return state;
}
