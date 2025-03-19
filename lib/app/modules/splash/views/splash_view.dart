import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import 'package:simple_progress_indicators/simple_progress_indicators.dart';

import '../controllers/splash_controller.dart';

class SplashView extends GetView<SplashController> {
  const SplashView({super.key});
  @override
  Widget build(BuildContext context) {
    final RxBool _isVisible = true.obs;

    // Используем Future.delayed для задержки исчезновения
    Future.delayed(const Duration(seconds: 2), () {
      _isVisible.value = false; // Скрываем элементы через 2 секунды
    });

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Obx(
              () => AnimatedOpacity(
                opacity: _isVisible.value ? 1.0 : 0.0,
                duration: const Duration(seconds: 1),
                child:
                    Get.isDarkMode
                        ? Lottie.asset(
                          'assets/lottie/logo_dark_animated.json',
                          fit: BoxFit.contain,
                          width: Get.height * 0.7,
                        )
                        : Lottie.asset(
                          'assets/lottie/logo_light_animated.json',
                          fit: BoxFit.contain,
                          width: Get.height * 0.7,
                        ),
              ),
            ),

            // Индикатор прогресса с анимацией исчезновения
            Obx(() {
              return AnimatedOpacity(
                opacity: _isVisible.value ? 1.0 : 0.0,
                duration: const Duration(
                  seconds: 1,
                ), // Продолжительность исчезновения
                child: ProgressBarAnimation(
                  width: Get.width * 0.8,
                  duration: const Duration(seconds: 2),
                  gradient: LinearGradient(
                    colors: [
                      Get.theme.colorScheme.primary,
                      Get.theme.colorScheme.tertiary,
                    ],
                  ),
                  backgroundColor: Get.theme.colorScheme.primaryContainer
                      .withAlpha(40),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
