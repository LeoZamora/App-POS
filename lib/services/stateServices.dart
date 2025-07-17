import 'package:flutter/cupertino.dart';

class StateServices extends ChangeNotifier {
  bool _isLoading = false;

  // GETTERS
  bool get isLoading => _isLoading;

  void login(bool value) {
    _isLoading = value;
    notifyListeners();
  }
 void logout() {
    _isLoading = false;
    notifyListeners();
 }


}