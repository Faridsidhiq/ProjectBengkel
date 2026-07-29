import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'detail_riwayat_page.dart';

class NotifikasiMobilePage extends StatelessWidget {
  const NotifikasiMobilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          "Notifikasi", 
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
        ),
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
                  return const Center(child: CircularProgressIndicator(color: Colors.blue));
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return _buildKosong();
                }

                // Ambil hanya yang statusnya "Selesai"
                final notifSelesai = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return data['status'] == 'Selesai';
                }).toList();

                // Urutkan notifikasi secara lokal (terbaru di atas)
                notifSelesai.sort((a, b) {
                  final dataA = a.data() as Map<String, dynamic>;
                  final dataB = b.data() as Map<String, dynamic>;
                  final tA = dataA['waktu_selesai'] as Timestamp?;
                  final tB = dataB['waktu_selesai'] as Timestamp?;
                  if (tA == null && tB == null) return 0;
                  if (tA == null) return 1;
                  if (tB == null) return -1;
                  return tB.compareTo(tA);
                });

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
                    final noSpk = data['no_spk'] ?? data['noSpk'] ?? '-';
                    final plat = data['plat']?.toString().toUpperCase() ?? '-';
                    final kendaraan = data['kendaraan'] ?? 'Mobil';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: sudahDibaca ? Colors.grey.shade50 : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: sudahDibaca ? Colors.grey.shade200 : Colors.blue.shade100,
                        ),
                        boxShadow: [
                          if (!sudahDibaca)
                            BoxShadow(
                              color: Colors.blue.withValues(alpha: 0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                        ],
                      ),
                      child: InkWell(
                        onTap: () async {
                          // Update ke database bahwa notif sudah dibaca
                          if (!sudahDibaca) {
                            await FirebaseFirestore.instance
                                .collection('spk')
                                .doc(doc.id)
                                .update({'notif_dibaca': true});
                          }
                          
                          if (context.mounted) {
                            Navigator.push(
                              context, 
                              MaterialPageRoute(builder: (_) => DetailRiwayatPage(data: data)),
                            );
                          }
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Ikon Indikator
                              CircleAvatar(
                                radius: 20,
                                backgroundColor: sudahDibaca 
                                    ? Colors.grey.shade200 
                                    : Colors.blue.shade50,
                                child: Icon(
                                  sudahDibaca ? Icons.done_all : Icons.notifications_active, 
                                  color: sudahDibaca ? Colors.grey : Colors.blue.shade700,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 14),
                              
                              // Konten Notifikasi
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          "Servis Selesai! 🎉",
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold, 
                                            fontSize: 14,
                                            color: sudahDibaca ? Colors.grey.shade700 : Colors.black87,
                                          ),
                                        ),
                                        if (!sudahDibaca)
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: Colors.red.shade600, 
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: const Text(
                                              "BARU", 
                                              style: TextStyle(
                                                color: Colors.white, 
                                                fontSize: 8, 
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "No. SPK: $noSpk",
                                      style: TextStyle(
                                        fontSize: 10, 
                                        fontWeight: FontWeight.bold, 
                                        color: sudahDibaca ? Colors.grey.shade500 : Colors.blue.shade900,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      "Mobil $kendaraan ($plat) Anda telah selesai diperbaiki dengan sukses. Ketuk untuk melihat laporan lengkap pengerjaan dan rincian biaya.",
                                      style: TextStyle(
                                        height: 1.4, 
                                        color: sudahDibaca ? Colors.grey.shade600 : Colors.black87, 
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              
                              // Chevron right
                              Icon(
                                Icons.arrow_forward_ios, 
                                size: 12, 
                                color: sudahDibaca ? Colors.grey.shade300 : Colors.grey.shade400,
                              ),
                            ],
                          ),
                        ),
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
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.notifications_off_outlined, size: 60, color: Colors.blue.shade300),
          ),
          const SizedBox(height: 20),
          Text(
            "Tidak Ada Notifikasi", 
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey.shade800),
          ),
          const SizedBox(height: 8),
          Text(
            "Pemberitahuan servis Anda akan muncul di sini.", 
            style: TextStyle(color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }
}