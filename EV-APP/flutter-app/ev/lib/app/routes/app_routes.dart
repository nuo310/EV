// ignore_for_file: constant_identifier_names

part of 'app_pages.dart';

abstract class Routes {
  Routes._();
  static const SPLASH = _Paths.SPLASH;
  static const LANDING = _Paths.LANDING;
  static const LOGIN = _Paths.LOGIN;
  static const SIGNUP = _Paths.SIGNUP;
  static const DASHBOARD = _Paths.DASHBOARD;
}

abstract class _Paths {
  _Paths._();
  static const SPLASH = '/splash';
  static const LANDING = '/landing';
  static const LOGIN = '/login';
  static const SIGNUP = '/signup';
  static const DASHBOARD = '/dashboard';
}
