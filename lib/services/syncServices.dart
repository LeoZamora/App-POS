import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:flutter/services.dart';
import 'dart:async';

class SyncServices {
  Timer? _timer;
  final connectionChecker = InternetConnectionChecker.instance;
  bool isConnected = false;

}