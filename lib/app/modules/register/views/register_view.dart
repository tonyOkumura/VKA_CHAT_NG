import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:vka_chat_ng/app/widgets/animated_background.dart';
import 'package:vka_chat_ng/app/widgets/particle/particle_widget.dart';

import '../controllers/register_controller.dart';

class RegisterView extends GetView<RegisterController> {
  const RegisterView({super.key});

  void _handleKeyPress(RawKeyEvent event) {
    if (event is RawKeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.enter) {
      controller.register();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(title: const Text('Register'), centerTitle: true),
      body: RawKeyboardListener(
        focusNode: FocusNode(),
        onKey: _handleKeyPress,
        child: Stack(
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
                        controller: controller.usernameController,
                        decoration: InputDecoration(
                          labelText: 'Username',
                          border: OutlineInputBorder(),
                        ),
                        textInputAction: TextInputAction.next,
                      ),
                      SizedBox(height: 16),
                      TextField(
                        controller: controller.emailController,
                        decoration: InputDecoration(
                          labelText: 'email'.tr,
                          border: OutlineInputBorder(),
                        ),
                        textInputAction: TextInputAction.next,
                      ),
                      SizedBox(height: 16),
                      TextField(
                        controller: controller.passwordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: 'password'.tr,
                          border: OutlineInputBorder(),
                        ),
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => controller.register(),
                      ),
                      SizedBox(height: 32),
                      Obx(
                        () =>
                            controller.isLoading.value
                                ? CircularProgressIndicator()
                                : ElevatedButton(
                                  onPressed: () {
                                    controller.register();
                                  },
                                  child: Text('register'.tr),
                                  style: ElevatedButton.styleFrom(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 100,
                                      vertical: 15,
                                    ),
                                    backgroundColor:
                                        Get.theme.colorScheme.primaryContainer,
                                    textStyle: TextStyle(fontSize: 18),
                                  ),
                                ),
                      ),
                      SizedBox(height: 16),
                      TextButton(
                        onPressed: () {
                          Get.back();
                        },
                        child: Text(
                          'already_have_account'.tr + "  " + 'login'.tr,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
