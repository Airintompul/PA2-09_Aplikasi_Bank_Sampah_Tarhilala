import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../services/notification_service.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  List _notifs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotif();
  }

  Future<void> _loadNotif() async {
    final data = await NotificationService.getNotifications();
    if (mounted) {
      setState(() {
        _notifs = data;
        _isLoading = false;
      });
    }
  }

  // FUNGSI: Tandai sudah dibaca saat di-klik
  Future<void> _handleMarkAsRead(int index) async {
    final notif = _notifs[index];
    if (notif['is_read'] == 1 || notif['is_read'] == true) return;

    await NotificationService.markAsRead(notif['id']);
    setState(() {
      _notifs[index]['is_read'] = 1; // Update UI langsung tanpa reload
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F9),
      body: Column(
        children: [
          // --- HEADER CUSTOM (KONSISTEN DENGAN HALAMAN LAIN) ---
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5)
                        ],
                      ),
                      child: const Icon(Icons.arrow_back_ios_new, size: 18, color: Colors.black87),
                    ),
                  ),
                  const SizedBox(width: 15),
                  const Text(
                    "Pemberitahuan",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                ],
              ),
            ),
          ),

          // --- DAFTAR NOTIFIKASI ---
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF3B71CA)))
                : _notifs.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _loadNotif,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(20),
                          itemCount: _notifs.length,
                          itemBuilder: (context, i) {
                            final n = _notifs[i];
                            bool isUnread = n['is_read'] == 0 || n['is_read'] == false;

                            return _buildNotifCard(n, isUnread, i);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotifCard(Map n, bool isUnread, int index) {
    String timeStr = n['created_at'] ?? DateTime.now().toString();
    String formattedTime = timeago.format(DateTime.parse(timeStr), locale: 'id');

    return GestureDetector(
      onTap: () => _handleMarkAsRead(index),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: isUnread ? Colors.white : Colors.white.withOpacity(0.7),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))
          ],
          border: isUnread 
            ? Border.all(color: const Color(0xFF3B71CA).withOpacity(0.15), width: 1.5)
            : null,
        ),
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon Notif
              CircleAvatar(
                backgroundColor: isUnread ? const Color(0xFF3B71CA).withOpacity(0.1) : Colors.grey.shade100,
                child: Icon(
                  isUnread ? Icons.notifications_active : Icons.notifications_none,
                  color: isUnread ? const Color(0xFF3B71CA) : Colors.grey,
                  size: 20,
                ),
              ),
              const SizedBox(width: 15),
              // Teks Notif
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      n['judul'],
                      style: TextStyle(
                        fontWeight: isUnread ? FontWeight.bold : FontWeight.bold,
                        fontSize: 14,
                        color: isUnread ? Colors.black87 : Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      n['pesan'],
                      style: TextStyle(
                        fontSize: 12,
                        color: isUnread ? Colors.black54 : Colors.grey.shade500,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      formattedTime,
                      style: TextStyle(fontSize: 10, color: Colors.grey.shade400, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              // Indikator Titik Merah (Jika belum dibaca)
              if (isUnread)
                Container(
                  margin: const EdgeInsets.only(top: 5),
                  width: 8, height: 8,
                  decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_off_outlined, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 15),
          const Text("Belum ada pemberitahuan", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}