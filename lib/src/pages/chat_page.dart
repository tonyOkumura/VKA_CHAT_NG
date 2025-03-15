import 'package:flutter/material.dart';

class ChatPage extends StatelessWidget {
  const ChatPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 1,
        title: Row(
          children: [
            const CircleAvatar(
              radius: 20,
              backgroundImage: NetworkImage('https://via.placeholder.com/150'),
            ),
            const SizedBox(width: 10),
            const Text('User Name'),
          ],
        ),
        actions: [
          PopupMenuButton(
            itemBuilder: (context) {
              return [
                const PopupMenuItem(child: Text('View Contact')),
                const PopupMenuItem(child: Text('Media, links, and docs')),
                const PopupMenuItem(child: Text('Search')),
                const PopupMenuItem(child: Text('Mute notifications')),
                const PopupMenuItem(child: Text('Wallpaper')),
                const PopupMenuItem(child: Text('More')),
              ];
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(10),
              children: [
                _buildReceivedMessage('Hello, how are you doing today?'),
                _buildSentMessage('I am doing fine, thank you.'),
                _buildReceivedMessage('Hello, how are you doing today?'),
                _buildSentMessage(
                  'I am doijhsfrslfjlsjfrshrjsd;rgsrng fine, thank you.',
                ),
                _buildReceivedMessage(
                  'Hello, how are you doing todabdghndthncfthmcfntbhnftmyjfybyndytbtsty?',
                ),
                _buildSentMessage('I am doing fine, thank you.'),
                _buildReceivedMessage('Hello, how are you doing today?'),
                _buildSentMessage('I am doing fine, thank you.'),
                _buildReceivedMessage('Hello, how are you doing today?'),
                _buildSentMessage('I am doing fine, thank you.'),
                _buildReceivedMessage(
                  'Hello, how are ycjjfiwevghoiprqtdeorkmtgekvgnjocmkfsvdklfdjoigrjgmkfvsfobrjdigcifmjarvnojaou doing today?',
                ),
                _buildSentMessage('I am doing fine, thank you.'),
                _buildReceivedMessage('Hello, how are you doing today?'),
                _buildSentMessage('I am doing fine, thank you.'),
                _buildReceivedMessage('Hello, how are you doing today?'),
                _buildSentMessage('I am doing fine, thank you.'),
                _buildReceivedMessage('Hello, how are you doing today?'),
                _buildSentMessage('I am doing fine, thank you.'),
                _buildReceivedMessage(
                  'Hello, how are you doiwfmivsehrjekrjtdjiriotvtr4ort9u5940w5u9ir03tu940t4390tu93i02irtu94i302rhgr3ie02rh9r03ei04r9h90ri32rhg94r0i3r9gh90ri320hgww90ri323hgw9jr32i04ghjri32049gh9j0ri4ghg9jri049h9ir-i-gh90ir4ughtjiro2i4jghjir23jhtir32i09ghj0ir0gthgjir3-ghtri0r329ghi032rghti03ri0gtrh9i0r4utgsijorfirgstu4i3sgru94ipi0rtgu94torhd0oi94ruq3w4i0o4trq3w4to09r23w345hijotirg09u4w5hitrogu904r23hq4tgur9q04yhoitwtugr9wa4qthoi;whstoi0grua4thowhjsotri0grua4t;hqiwshjtriruy4thoqisthiougra4thi;o5ystoi[0gru4thiq;ng today?',
                ),
                _buildSentMessage('I am doing fine, thank you.'),
                _buildReceivedMessage('Hello, how are you doing today?'),
                _buildSentMessage('I am doing fine, thank you.'),
                _buildReceivedMessage('Hello, how are you doing today?'),
                _buildSentMessage('I am doing fine, thank you.'),
                _buildReceivedMessage('Hello, how are you doing today?'),
                _buildSentMessage('I am doing fine, thank you.'),
                _buildReceivedMessage('Hello, how are you doing today?'),
                _buildSentMessage('I am doing fine, thank you.'),
                _buildReceivedMessage('Hello, how are you doing today?'),
                _buildSentMessage('I am doing fine, thank you.'),
              ],
            ),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }
}

Widget _buildReceivedMessage(String message) {
  return Align(
    alignment: Alignment.centerLeft,
    child: Container(
      padding: const EdgeInsets.all(10),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        // color: Colors.grey[300],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Text(message),
    ),
  );
}

Widget _buildSentMessage(String message) {
  return Align(
    alignment: Alignment.centerRight,
    child: Container(
      padding: const EdgeInsets.all(10),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.blue.shade300),
      ),
      child: Text(message),
    ),
  );
}

Widget _buildMessageInput() {
  return Container(
    padding: const EdgeInsets.all(10),
    child: Row(
      children: [
        IconButton.filled(onPressed: () {}, icon: Icon(Icons.attach_file)),
        const SizedBox(width: 10),
        Expanded(
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Type a message',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        IconButton.filled(onPressed: () {}, icon: Icon(Icons.send)),
      ],
    ),
  );
}
