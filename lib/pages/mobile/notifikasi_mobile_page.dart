import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'riwayat_servis_page.dart'; 
import 'detail_riwayat_page.dart'; // Tambahkan ini di atas

class NotifikasiMobilePage extends StatelessWidget {
  const NotifikasiMobilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text("Notifikasi", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: user == null
          ? const Center(child: Text("Silakan login terlebih dahulu."))
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('spk')
                  .where('email', isEqualTo: user.email)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return _buildKosong();
                }

                // Ambil hanya yang statusnya "Selesai"
                final notifSelesai = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return data['status'] == 'Selesai';
                }).toList();

                if (notifSelesai.isEmpty) {
                  return _buildKosong();
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: notifSelesai.length,
                  itemBuilder: (context, index) {
                    final doc = notifSelesai[index];
                    final data = doc.data() as Map<String, dynamic>;
                    
                    // Cek apakah pesan ini sudah dibaca atau belum
                    bool sudahDibaca = data['notif_dibaca'] == true;
                    
                    return Card(
                      elevation: sudahDibaca ? 0 : 2, // Jika belum dibaca, card sedikit menonjol
                      color: sudahDibaca ? Colors.grey.shade100 : Colors.white, // Warna beda jika belum dibaca
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: sudahDibaca ? Colors.transparent : Colors.blue.shade200),
                      ),
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        leading: CircleAvatar(
                          backgroundColor: sudahDibaca ? Colors.grey.shade200 : Colors.green.shade50,
                          child: Icon(
                            sudahDibaca ? Icons.done_all : Icons.mark_email_unread, 
                            color: sudahDibaca ? Colors.grey : Colors.green.shade600
                          ),
                        ),
                        title: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "Servis Selesai!",
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                            if (!sudahDibaca)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(4)),
                                child: const Text("BARU", style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
                              )
                          ],
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            "Kendaraan ${data['kendaraan'] ?? ''} (${data['plat'] ?? ''}) Anda telah selesai dikerjakan. Silakan cek riwayat untuk detailnya.",
                            style: TextStyle(height: 1.4, color: Colors.grey.shade700, fontSize: 13),
                          ),
                        ),
                        trailing: Icon(Icons.chevron_right, color: Colors.grey.shade400),
                        
                        // ==========================================
                        // KETIKA DIKLIK, TANDAI SEBAGAI SUDAH DIBACA
                        // ==========================================
                        onTap: () async {
                        // Update ke database bahwa notif sudah dibaca
                        if (!sudahDibaca) {
                          await FirebaseFirestore.instance.collection('spk').doc(doc.id).update({
                            'notif_dibaca': true
                          });
                        }
                        
                        // PINDAH KE HALAMAN DETAIL KHUSUS (Bukan list riwayat umum lagi)
                        if (context.mounted) {
                          Navigator.push(
                            context, 
                            MaterialPageRoute(builder: (_) => DetailRiwayatPage(data: data))
                          );
                        }
                      },
                      ),
                    );
                  },
                );
              },
            ),
    );
  }

  Widget _buildKosong() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_off_outlined, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text("Tidak Ada Notifikasi", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey.shade700)),
          const SizedBox(height: 8),
          Text("Pemberitahuan servis Anda akan muncul di sini.", style: TextStyle(color: Colors.grey.shade500)),
        ],
      ),
    );
  }
}