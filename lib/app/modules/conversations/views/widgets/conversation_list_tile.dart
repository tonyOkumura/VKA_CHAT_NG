import 'package:flutter/material.dart';

class ConversationListTile extends StatelessWidget {
  final String formattedTimestamp;
  final int unreadCount;

  const ConversationListTile({
    Key? key,
    required this.formattedTimestamp,
    required this.unreadCount,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          formattedTimestamp,
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
        const SizedBox(height: 4),
        // Animate the badge appearance/disappearance and count changes
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (Widget child, Animation<double> animation) {
            // Fade and scale transition
            return FadeTransition(
              opacity: animation,
              child: ScaleTransition(scale: animation, child: child),
            );
          },
          child:
              unreadCount > 0
                  ? Container(
                    key: ValueKey<int>(
                      unreadCount,
                    ), // Important for animating changes
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor, // Use theme color
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      unreadCount > 99
                          ? '99+'
                          : unreadCount.toString(), // Limit display
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                  : const SizedBox(
                    key: ValueKey<String>('no_badge'),
                    width: 18,
                    height: 18,
                  ), // Keep space consistent
        ),
      ],
    );
  }
}
