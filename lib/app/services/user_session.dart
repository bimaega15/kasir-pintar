import 'package:get/get.dart';

/// Menyimpan sesi user yang sedang login secara global.
/// Diakses di seluruh app untuk menentukan hak akses.
class UserSession extends GetxService {
  final currentRole = 'admin'.obs; // 'admin' | 'kasir'
  final currentUsername = ''.obs;

  bool get isAdmin => currentRole.value == 'admin';
  bool get isKasir => currentRole.value == 'kasir';

  void setSession({required String username, required String role}) {
    currentUsername.value = username;
    currentRole.value = role;
  }

  void clearSession() {
    currentUsername.value = '';
    currentRole.value = 'admin';
  }
}
