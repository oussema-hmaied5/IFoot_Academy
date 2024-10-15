import '../actions/auth_actions.dart';
import '../models/app_state.dart';

AppState appReducer(AppState state, dynamic action) {
  if (action is LoginSuccessful) {
    return state.copyWith(user: action.user);
  } else if (action is RegisterSuccessful) {
    return state.copyWith();  // Modify state accordingly
  } else if (action is LoginError || action is RegisterError) {
    return state;  // Handle errors if needed
  } else if (action is SignOut) {
    return AppState.initial();
  }
  return state;
}
