import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:simple_animations/simple_animations.dart';
import 'package:supercharged/supercharged.dart';

enum _ColorTween {
  color1,
  color2,
}

class AnimatedBackground extends StatelessWidget {
  const AnimatedBackground({super.key});

  @override
  Widget build(BuildContext context) {
    final tween = MovieTween()
      ..tween(
          _ColorTween.color1,
          ColorTween(
              begin: Get.theme.colorScheme.primaryContainer,
              end: Get.theme.colorScheme.secondaryContainer),
          duration: 30.seconds,
          curve: Curves.easeIn)
      ..tween(
        _ColorTween.color2,
        ColorTween(
          begin: Get.theme.colorScheme.secondaryContainer,
          end: Get.theme.colorScheme.tertiaryContainer,
        ),
        duration: 30.seconds,
      );

    return MirrorAnimationBuilder<Movie>(
      tween: tween,
      duration: tween.duration,
      builder: (context, value, child) {
        return Container(
          decoration: BoxDecoration(
              gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                value.get<Color>(_ColorTween.color1),
                value.get<Color>(_ColorTween.color2),
              ])),
        );
      },
    );
  }
}
