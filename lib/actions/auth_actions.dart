import 'package:ifoot_academy/models/app_user.dart';

typedef ActionResult = void Function(AppAction action);

abstract class AppAction {}

// Login Actions
class LoginStart implements AppAction {
  final String email;
  final String password;
  final ActionResult result;

  LoginStart({required this.email, required this.password, required this.result});
}

class Login implements AppAction {
  final AppUser user;

  Login(this.user);
}

class LoginSuccessful implements AppAction {
  final AppUser user;

  LoginSuccessful(this.user);
}

class LoginError implements AppAction {
  final Object error;

  LoginError(this.error);
}

// Register Actions
class RegisterStart implements AppAction {
  final String email;
  final String name;
  final String dateOfBirth;
  final String mobile;
  final String password;
  final String role;
  final ActionResult result;

  RegisterStart({
    required this.email,
    required this.name,
    required this.dateOfBirth,
    required this.mobile,
    required this.password,
    required this.role,
    required this.result,
  });
}

class RegisterSuccessful implements AppAction {
  final String output;

  RegisterSuccessful(this.output);
}

class RegisterError implements AppAction {
  final Object error;

  RegisterError(this.error);
}

class SignOut implements AppAction {}
