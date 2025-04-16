import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class ChatDateHeader extends StatelessWidget {
  final DateTime date;

  const ChatDateHeader({super.key, required this.date});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 30.0, horizontal: 16.0),
      child: Text(
        _formatDate(date),
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          fontFamily: 'Nunito',
          color: Get.theme.colorScheme.secondary,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final messageDate = DateTime(date.year, date.month, date.day);

    if (messageDate == today) {
      return "Сегодня";
    } else if (messageDate == yesterday) {
      return "Вчера";
    } else {
      // Use a more specific format if needed, or keep the simple one
      return DateFormat('dd.MM.yyyy').format(date);
      // return "${date.day}.${date.month}.${date.year}";
    }
  }
}
