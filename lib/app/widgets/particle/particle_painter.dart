import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:simple_animations/simple_animations.dart';

import 'particle_model.dart';

class ParticlePainter extends CustomPainter {
  List<ParticleModel> particles;

  ParticlePainter(this.particles);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Get.theme.colorScheme.surface.withAlpha(50);

    for (var particle in particles) {
      final progress = particle.progress();
      final Movie animation = particle.tween.transform(progress);
      final position = Offset(
        animation.get<double>(ParticleOffsetProps.x) * size.width,
        animation.get<double>(ParticleOffsetProps.y) * size.height,
      );
      canvas.drawCircle(position, size.width * 0.2 * particle.size, paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
