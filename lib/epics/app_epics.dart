import 'package:ifoot_academy/actions/ApproveUserStart.dart';
import 'package:ifoot_academy/models/app_user.dart';
import 'package:redux_epics/redux_epics.dart';
import 'package:rxdart/rxdart.dart';

import '../actions/index.dart';
import '../data/auth_api.dart';
import '../models/app_state.dart';

class AppEpics {
  const AppEpics({required AuthApi authApi}) : _authApi = authApi;

  final AuthApi _authApi;

  Epic<AppState> get epics {
    return combineEpics<AppState>(<Epic<AppState>>[
      TypedEpic<AppState, LoginStart>(_login),
      TypedEpic<AppState, RegisterStart>(_register),
      TypedEpic<AppState, ApproveUserStart>(_approveUser),
    ]);
  }

  Stream<AppAction> _login(Stream<LoginStart> actions, EpicStore<AppState> store) {
    return actions.flatMap((LoginStart action) => Stream<void>.value(null)
        .asyncMap((_) => _authApi.login(action.email, action.password))
        .map<AppAction>((AppUser? user) {
          if (user == null) {
            return LoginError(Exception('User not found'));
          } else if (user.role == 'pending') {
            return LoginError(Exception('Your account is pending approval by an admin.'));
          } else {
            return LoginSuccessful(user);
          }
        })
        .onErrorReturnWith((Object error, StackTrace stackTrace) => LoginError(error))
        .doOnData(action.result));
  }

  Stream<AppAction> _register(Stream<RegisterStart> actions, EpicStore<AppState> store) {
    return actions.flatMap((RegisterStart action) => Stream<void>.value(null)
        .asyncMap((_) => _authApi.register(action.mobile, action.email, action.name, action.password, action.role))
        .map<AppAction>((String output) => RegisterSuccessful(output))
        .onErrorReturnWith((Object error, StackTrace stackTrace) => RegisterError(error))
        .doOnData(action.result));
  }

  Stream<AppAction> _approveUser(Stream<ApproveUserStart> actions, EpicStore<AppState> store) {
    return actions.flatMap((ApproveUserStart action) => Stream<void>.value(null)
        .asyncMap((_) => _authApi.approveUser(action.userId, action.role))
        .asyncMap<AppAction>((String role) async {
          final AppUser user = await _authApi.getUserById(action.userId);
          return ApproveUserSuccessful(user, role);
        })
        .onErrorReturnWith((Object error, StackTrace stackTrace) => ApproveUserError(error))
        .doOnData(action.result));
  }
}
