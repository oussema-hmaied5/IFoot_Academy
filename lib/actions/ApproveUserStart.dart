// ignore_for_file: file_names

import 'package:ifoot_academy/actions/index.dart';
import 'package:ifoot_academy/models/app_user.dart';

class ApproveUserStart implements AppAction {
  final String userId;
  final String role;
  final ActionResult result;

  ApproveUserStart({required this.userId, required this.role, required this.result});
}

class ApproveUserSuccessful implements AppAction {
  final AppUser user;
  final String role;

  ApproveUserSuccessful(this.user, this.role);
}

class ApproveUserError implements AppAction {
  final Object error;

  ApproveUserError(this.error);
}
