import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vka_chat_ng/app/routes/app_pages.dart';
import 'package:vka_chat_ng/app/widgets/animated_background.dart';
import 'package:vka_chat_ng/app/widgets/particle/particle_widget.dart';
import '../controllers/login_controller.dart';

class LoginView extends GetView<LoginController> {
  const LoginView({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(title: const Text('Login'), centerTitle: true),
      body: Stack(
        children: [
          const Positioned.fill(child: AnimatedBackground()),
          const Positioned.fill(child: ParticlesWidget(30)),
          Center(
            child: Card(
              margin: const EdgeInsets.symmetric(horizontal: 60),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextField(
                      controller: controller.emailController,
                      decoration: InputDecoration(
                        labelText: 'email'.tr,
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 16),
                    TextField(
                      controller: controller.passwordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: 'password'.tr,
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 32),

                    Obx(
                      () =>
                          controller.isLoading.value
                              ? CircularProgressIndicator()
                              : ElevatedButton(
                                onPressed: () {
                                  controller.login();
                                },
                                child: Text('login'.tr),
                                style: ElevatedButton.styleFrom(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 100,
                                    vertical: 15,
                                  ),
                                  backgroundColor:
                                      Get.theme.colorScheme.primaryContainer,
                                  textStyle: TextStyle(
                                    fontSize: 18,
                                    color:
                                        Get
                                            .theme
                                            .colorScheme
                                            .onPrimaryContainer,
                                  ),
                                ),
                              ),
                    ),
                    SizedBox(height: 16),
                    TextButton(
                      onPressed: () {
                        Get.toNamed(Routes.REGISTER);
                      },
                      child: Text(
                        'dont_have_account'.tr + "   " + 'register'.tr,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
