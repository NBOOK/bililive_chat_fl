import 'package:badges/badges.dart';
import 'package:bililive_api_fl/bililive_api_fl.dart';
import 'package:flutter/material.dart' hide Badge;
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class MessageWidget extends StatelessWidget {
  final Message message;

  const MessageWidget({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Row(
      // Align avatars to the top
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Avatar
        const CircleAvatar(
          radius: 16,
          // NetworkImage('https://static.hdslb.com/images/member/noface.gif'),
          backgroundImage: AssetImage('assets/noface.gif'),
          // Prevent a strange "border" from appearing around the image
          backgroundColor: Colors.transparent,
        ),
        // Horizontal space
        const SizedBox(width: 10),
        // Nickname and content
        Expanded(
          child: Column(
            // Align texts to the left
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SenderInfoWidget(message: message),
              const SizedBox(height: 3),
              Text(message.text),
            ],
          ),
        ),
      ],
    );
  }
}

/// Sender info widget (including nickname, icons (badges) and medal).
class SenderInfoWidget extends StatelessWidget {
  final Message message;

  const SenderInfoWidget({super.key, required this.message});

  Color _kanchouColor(int lv) {
    if (lv == 0) return Colors.grey;
    if (lv >= 3) return Colors.blue.shade800;
    if (lv == 2) return Colors.purple.shade700;
    return Colors.orange;
  }

  @override
  Widget build(BuildContext context) {
    var items = <Widget>[
      // Nickname
      Text(
        message.nickname,
        style: TextStyle(
          color: _kanchouColor(message.kanchouLv),
          fontWeight:
              message.kanchouLv > 0 ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    ];

    // Kanchou icon (CNY sign)
    if (message.kanchouLv > 0) {
      items.add(FaIcon(
        FontAwesomeIcons.yenSign,
        size: 12,
        color: _kanchouColor(message.kanchouLv),
      ));
    }

    // Medal bubble
    var medal = message.medal;
    if (medal != null) {
      items.add(MedalWidget(medal: medal));
    }

    return Wrap(
      spacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: items,
    );
  }
}

/// Medal bubble (implemented using Material "badge" widget).
class MedalWidget extends StatelessWidget {
  final Medal medal;

  const MedalWidget({super.key, required this.medal});

  @override
  Widget build(BuildContext context) {
    return Badge(
      badgeContent: Text(
        "${medal.title} ${medal.level}",
        style: const TextStyle(fontSize: 12, color: Colors.white),
      ),
      badgeStyle: BadgeStyle(
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        shape: BadgeShape.square,
        borderRadius: BorderRadius.circular(12),
        badgeColor: Color.fromARGB(255, medal.color >> 16,
            (medal.color >> 8) & 255, medal.color & 255),
      ),
      // toAnimate: false,
      badgeAnimation: const BadgeAnimation.fade(),
    );
  }
}