import 'package:flutter/material.dart';

class MessagePage extends StatelessWidget {
  const MessagePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Messages'),
        elevation: 1,
        actions: [
          IconButton(icon: const Icon(Icons.search), onPressed: () {}),
          IconButton(icon: const Icon(Icons.more_vert), onPressed: () {}),
        ],
      ),
      body: Column(
        children: [
          SizedBox(height: 10),
          Text('Recent', style: TextStyle(fontSize: 16)),
          Divider(),
          Container(
            height: 110,
            padding: EdgeInsets.all(5),
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildRecentContact(),
                _buildRecentContact(),
                _buildRecentContact(),
                _buildRecentContact(),
                _buildRecentContact(),
                _buildRecentContact(),
                _buildRecentContact(),
                _buildRecentContact(),
                _buildRecentContact(),
                _buildRecentContact(),
                _buildRecentContact(),
                _buildRecentContact(),
                _buildRecentContact(),
                _buildRecentContact(),
                _buildRecentContact(),
                _buildRecentContact(),
                _buildRecentContact(),
                _buildRecentContact(),
                _buildRecentContact(),
                _buildRecentContact(),
                _buildRecentContact(),
                _buildRecentContact(),
                _buildRecentContact(),
                _buildRecentContact(),
                _buildRecentContact(),
                _buildRecentContact(),
                _buildRecentContact(),
                _buildRecentContact(),
              ],
            ),
          ),
          Divider(),
          Expanded(
            child: Container(
              child: ListView(
                children: [
                  _buildMessageTile(
                    'https://via.placeholder.com/150',
                    'User Name',
                    'Message',
                    '10:00 PM',
                  ),
                  _buildMessageTile(
                    'https://via.placeholder.com/150',
                    'User Name',
                    'Message',
                    '10:00 PM',
                  ),
                  _buildMessageTile(
                    'https://via.placeholder.com/150',
                    'User Name',
                    'Message',
                    '10:00 PM',
                  ),
                  _buildMessageTile(
                    'https://via.placeholder.com/150',
                    'User Name',
                    'Hello',
                    '10:00 am',
                  ),
                  _buildMessageTile(
                    'https://via.placeholder.com/150',
                    'User Name',
                    'Hello',
                    '10:00 am',
                  ),
                  _buildMessageTile(
                    'https://via.placeholder.com/150',
                    'User Name',
                    'Hello',
                    '10:00 am',
                  ),
                  _buildMessageTile(
                    'https://via.placeholder.com/150',
                    'User Name',
                    'Hello',
                    '10:00 am',
                  ),
                  _buildMessageTile(
                    'https://via.placeholder.com/150',
                    'User Name',
                    'Hello',
                    '10:00 am',
                  ),
                  _buildMessageTile(
                    'https://via.placeholder.com/150',
                    'User Name',
                    'Hello',
                    '10:00 am',
                  ),
                  _buildMessageTile(
                    'https://via.placeholder.com/150',
                    'User Name',
                    'Hello',
                    '10:00 am',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Widget _buildRecentContact() {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 10.0),
    child: Column(
      children: [
        CircleAvatar(
          radius: 30,
          backgroundImage: NetworkImage('https://via.placeholder.com/150'),
        ),
        Text('User Name'),
      ],
    ),
  );
}

Widget _buildMessageTile(
  String imageUrl,
  String userName,
  String message,
  String time,
) {
  return ListTile(
    leading: CircleAvatar(radius: 30, backgroundImage: NetworkImage(imageUrl)),
    title: Text(userName),
    subtitle: Text(message, overflow: TextOverflow.ellipsis),
    trailing: Column(
      children: [
        Text(time),
        CircleAvatar(
          radius: 10,
          backgroundColor: Colors.blue,
          child: Text('2', style: TextStyle(color: Colors.white)),
        ),
      ],
    ),
  );
}
