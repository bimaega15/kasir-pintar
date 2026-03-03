import 'package:get/get.dart';

class MainNavigationController extends GetxController {
  static const String TAG = 'MainNavigationController';

  var currentIndex = 0.obs;

  final List<String> routes = [
    '/home',
    '/master',
    '/report',
    '/settings',
    '/kasir',
  ];

  void changeIndex(int index) {
    currentIndex.value = index;
  }

  void navigateTo(String routeName) {
    final routeIndex = routes.indexOf(routeName);
    if (routeIndex != -1) {
      currentIndex.value = routeIndex;
    }
  }
}
