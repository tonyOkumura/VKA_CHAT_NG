import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vka_chat_ng/app/routes/app_pages.dart';
import '../controllers/login_controller.dart';

class LoginView extends GetView<LoginController> {
  const LoginView({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login'), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: controller.emailController,
              decoration: InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: controller.passwordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Password',
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
                        child: Text('Login'),
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                            horizontal: 50,
                            vertical: 15,
                          ),
                          textStyle: TextStyle(fontSize: 18),
                        ),
                      ),
            ),
            SizedBox(height: 16),
            TextButton(
              onPressed: () {
                Get.toNamed(Routes.REGISTER);
              },
              child: Text('Don\'t have an account? Register'),
            ),
          ],
        ),
      ),
    );
  }
}
