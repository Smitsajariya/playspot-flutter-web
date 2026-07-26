import 'package:flutter/material.dart';
import '../services/notification_service.dart';
import '../socket_service.dart';
import '../theme/playspot_theme.dart';
import 'group_chat_screen.dart';

enum _NotifTab { all, joinRequests, gameActivity }

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final NotificationService _service = NotificationService();
  _NotifTab _tab = _NotifTab.all;

  @override
  void initState() {
    super.initState();
    _service.init();
    _service.attachSocketListeners(SocketService());
  }

  List<NotificationItem> _filtered(List<NotificationItem> all) {
    switch (_tab) {
      case _NotifTab.all:
        return all;
      case _NotifTab.joinRequests:
        return all.where((n) => n.type == PSNotificationType.joinRequest).toList();
      case _NotifTab.gameActivity:
        return all.where((n) => n.type == PSNotificationType.gameActivity).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PSColors.bg,
      appBar: AppBar(
        backgroundColor: PSColors.bg,
        elevation: 0,
        title: const Text('Notifications', style: PSText.screenTitle),
        actions: [
          ValueListenableBuilder<List<NotificationItem>>(
            valueListenable: _service.items,
            builder: (context, items, _) {
              final hasUnread = items.any((n) => !n.read);
              if (!hasUnread) return const SizedBox.shrink();
              return TextButton(
                onPressed: () => _service.markAllRead(),
                child: const Text(
                  'Mark all read',
                  style: TextStyle(color: PSColors.gold, fontSize: 13, fontWeight: FontWeight.w700),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildTabs(),
          const SizedBox(height: 4),
          Expanded(
            child: ValueListenableBuilder<List<NotificationItem>>(
              valueListenable: _service.items,
              builder: (context, all, _) {
                final list = _filtered(all);
                if (list.isEmpty) return _buildEmpty();
                return ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: list.length,
                  separatorBuilder: (_, __) => Divider(
                    height: 1,
                    color: PSColors.border,
                    indent: 72,
                  ),
                  itemBuilder: (context, i) => _buildTile(list[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    Widget chip(String label, _NotifTab value) {
      final selected = _tab == value;
      return GestureDetector(
        onTap: () => setState(() => _tab = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.only(right: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? PSColors.gold : PSColors.surface,
            borderRadius: BorderRadius.circular(PSRadius.full),
            border: Border.all(color: selected ? PSColors.gold : PSColors.border),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? const Color(0xFF140A00) : PSColors.ink,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            chip('All', _NotifTab.all),
            chip('Join Requests', _NotifTab.joinRequests),
            chip('Game Activity', _NotifTab.gameActivity),
          ],
        ),
      ),
    );
  }

  Widget _buildTile(NotificationItem n) {
    return InkWell(
      onTap: () async {
        await _service.markRead(n.id);
        if (n.groupId != null && mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => GroupChatScreen(
                groupId: n.groupId!,
                groupName: n.groupName ?? 'Game',
              ),
            ),
          );
        }
      },
      child: Container(
        color: n.read ? Colors.transparent : PSColors.gold.withOpacity(0.05),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: PSColors.surface2,
                  backgroundImage: n.avatarUrl != null && n.avatarUrl!.isNotEmpty
                      ? NetworkImage(n.avatarUrl!)
                      : null,
                  child: (n.avatarUrl == null || n.avatarUrl!.isEmpty)
                      ? Text(n.emoji, style: const TextStyle(fontSize: 18))
                      : null,
                ),
                if (!n.read)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: PSColors.fire,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    n.title,
                    style: TextStyle(
                      color: PSColors.ink,
                      fontSize: 14,
                      fontWeight: n.read ? FontWeight.w600 : FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    n.body,
                    style: const TextStyle(color: PSColors.inkDim, fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _relativeTime(n.timestamp),
                    style: const TextStyle(color: PSColors.inkMuted, fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    final emptyCopy = switch (_tab) {
      _NotifTab.all => ('🔔', 'No notifications yet', 'Game activity and join requests will show up here.'),
      _NotifTab.joinRequests => ('🙌', 'No join requests', 'When players RSVP to your games, you\'ll see it here.'),
      _NotifTab.gameActivity => ('🔥', 'No activity yet', 'Heating-up games and new games near you will show here.'),
    };
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emptyCopy.$1, style: const TextStyle(fontSize: 40)),
            const SizedBox(height: 12),
            Text(emptyCopy.$2,
                style: const TextStyle(color: PSColors.ink, fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text(emptyCopy.$3,
                textAlign: TextAlign.center,
                style: const TextStyle(color: PSColors.inkDim, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  String _relativeTime(DateTime t) {
    final diff = DateTime.now().difference(t);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} minutes ago';
    if (diff.inHours < 24) return 'about ${diff.inHours} hour${diff.inHours == 1 ? '' : 's'} ago';
    return '${diff.inDays} day${diff.inDays == 1 ? '' : 's'} ago';
  }
}
