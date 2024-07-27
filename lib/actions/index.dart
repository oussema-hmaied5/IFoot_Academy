import 'package:ifoot_academy/models/app_user.dart';

typedef ActionResult = void Function(AppAction action);

abstract class AppAction {}

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
class ErrorAction implements AppAction {
  final Object error;

  ErrorAction(this.error);
}

class LoginError implements AppAction {
  final Object error;

  LoginError(this.error);
}
class RegisterSuccessful implements AppAction {
  final String output;

  RegisterSuccessful(this.output);
}
class RegisterStart implements AppAction {
  final String mobile;
  final String email;
  final String name;
  final String password;
  final String role; // Add this field
  final ActionResult result;

  RegisterStart({required this.mobile, required this.email, required this.name, required this.password, required this.role, required this.result});
}
class LoginSuccessful implements AppAction {
  final AppUser user;

  LoginSuccessful(this.user);
}

class Register implements AppAction {
  final String output;

  Register(this.output, String email, String name, String number, void Function(AppAction action) onResult);
}


class RegisterError implements AppAction {
  final Object error;

  RegisterError(this.error);
}
