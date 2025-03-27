import 'package:get/get.dart';

import '../modules/chats/bindings/chats_binding.dart';
import '../modules/chats/views/chats_view.dart';
import '../modules/contacts/bindings/contacts_binding.dart';
import '../modules/contacts/views/contacts_view.dart';
import '../modules/home/bindings/home_binding.dart';
import '../modules/home/views/home_view.dart';
import '../modules/login/bindings/login_binding.dart';
import '../modules/login/views/login_view.dart';
import '../modules/register/bindings/register_binding.dart';
import '../modules/register/views/register_view.dart';
import '../modules/settings/bindings/settings_binding.dart';
import '../modules/settings/views/settings_view.dart';
import '../modules/splash/bindings/splash_binding.dart';
import '../modules/splash/views/splash_view.dart';
import '../routes/app_layout.dart';
import '../middlewares/sidebar_middleware.dart';

part 'app_routes.dart';

class AppPages {
  AppPages._();

  static const INITIAL = Routes.SPLASH;

  static final routes = [
    GetPage(
      name: Routes.SPLASH,
      page: () => const SplashView(),
      binding: SplashBinding(),
    ),
    GetPage(
      name: Routes.LOGIN,
      page: () => const LoginView(),
      binding: LoginBinding(),
    ),
    GetPage(
      name: Routes.REGISTER,
      page: () => const RegisterView(),
      binding: RegisterBinding(),
    ),
    GetPage(
      name: Routes.CHATS,
      page: () => const AppLayout(child: ChatsView()),
      binding: ChatsBinding(),
      middlewares: [SidebarMiddleware()],
    ),
    GetPage(
      name: Routes.HOME,
      page: () => const AppLayout(child: HomeView()),
      binding: HomeBinding(),
      middlewares: [SidebarMiddleware()],
    ),
    GetPage(
      name: Routes.SETTINGS,
      page: () => const AppLayout(child: SettingsView()),
      binding: SettingsBinding(),
      middlewares: [SidebarMiddleware()],
    ),
    GetPage(
      name: Routes.CONTACTS,
      page: () => const AppLayout(child: ContactsView()),
      binding: ContactsBinding(),
      middlewares: [SidebarMiddleware()],
    ),
  ];
}
