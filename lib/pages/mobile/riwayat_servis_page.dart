import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'detail_riwayat_page.dart';

class RiwayatServisPage extends StatelessWidget {
  const RiwayatServisPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text("Riwayat Servis", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87)),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0.5,
      ),
      body: user == null
          ? const Center(child: Text("Anda belum login."))
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

                // Filter data yang statusnya 'Selesai'
                final dokumenSelesai = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return data['status'] == 'Selesai';
                }).toList();

                // Urutkan data secara lokal (in-memory) berdasarkan waktu_selesai descending
                dokumenSelesai.sort((a, b) {
                  final dataA = a.data() as Map<String, dynamic>;
                  final dataB = b.data() as Map<String, dynamic>;
                  final tA = dataA['waktu_selesai'] as Timestamp?;
                  final tB = dataB['waktu_selesai'] as Timestamp?;
                  if (tA == null && tB == null) return 0;
                  if (tA == null) return 1;
                  if (tB == null) return -1;
                  return tB.compareTo(tA); // Descending (terbaru di atas)
                });

                if (dokumenSelesai.isEmpty) {
                  return _buildKosong();
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: dokumenSelesai.length,
                  itemBuilder: (context, index) {
                    final data = dokumenSelesai[index].data() as Map<String, dynamic>;
                    
                    // Parse jenis_servis agar tampil rapi tanpa tanda kurung siku []
                    List<String> listServis = [];
                    if (data['jenis_servis'] != null) {
                      if (data['jenis_servis'] is List) {
                        listServis = List<String>.from(data['jenis_servis']);
                      } else {
                        listServis = data['jenis_servis'].toString().split(',').map((e) => e.trim()).toList();
                      }
                    }
                    final jenisServisStr = listServis.isEmpty ? 'Servis Umum' : listServis.join(', ');

                    final noSpk = data['no_spk'] ?? data['noSpk'] ?? '-';
                    final tanggal = data['tanggal'] ?? '-';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03), 
                            blurRadius: 8, 
                            offset: const Offset(0, 3)
                          ),
                        ],
                      ),
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => DetailRiwayatPage(data: data),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // BAGIAN ATAS: PLAT & STATUS & SPK
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(16), 
                                  topRight: Radius.circular(16)
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          data['plat']?.toString().toUpperCase() ?? 'Tanpa Plat',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w900, 
                                            fontSize: 14, 
                                            color: Colors.blue.shade900
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          "No. SPK: $noSpk",
                                          style: const TextStyle(fontSize: 10, color: Colors.black54),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.green.shade100,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      "Selesai",
                                      style: TextStyle(
                                        color: Colors.green.shade800, 
                                        fontWeight: FontWeight.bold, 
                                        fontSize: 10
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            
                            // BAGIAN TENGAH: DETAIL KENDARAAN & KELUHAN
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildDetailRow(Icons.branding_watermark, "Kendaraan", data['kendaraan'] ?? 'Tidak Diketahui'),
                                  const SizedBox(height: 10),
                                  _buildDetailRow(Icons.build_circle, "Jenis Servis", jenisServisStr),
                                  const SizedBox(height: 10),
                                  _buildDetailRow(Icons.calendar_today, "Tanggal Pengerjaan", tanggal),
                                  const SizedBox(height: 14),
                                  
                                  // Garis Pembatas
                                  const Divider(height: 1, thickness: 0.8),
                                  const SizedBox(height: 12),
                                  
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        "Lihat Detail Riwayat",
                                        style: TextStyle(
                                          color: Colors.blue.shade800, 
                                          fontWeight: FontWeight.bold, 
                                          fontSize: 11
                                        ),
                                      ),
                                      Icon(Icons.arrow_forward_ios, size: 10, color: Colors.blue.shade800),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 15, color: Colors.grey.shade500),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
              const SizedBox(height: 1),
              Text(
                value, 
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
            ],
          ),
        )
      ],
    );
  }

  Widget _buildKosong() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: Colors.blue.shade50, shape: BoxShape.circle),
            child: Icon(Icons.history_toggle_off, size: 60, color: Colors.blue.shade300),
          ),
          const SizedBox(height: 20),
          Text("Belum Ada Riwayat", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey.shade800)),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              "Kendaraan Anda yang telah selesai diservis akan muncul di sini sebagai arsip digital.", 
              style: TextStyle(color: Colors.grey.shade500, height: 1.4), 
              textAlign: TextAlign.center
            ),
          ),
        ],
      ),
    );
  }
}