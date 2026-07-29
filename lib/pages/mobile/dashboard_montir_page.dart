import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_mobile_page.dart';
// PASTIKAN IMPORT FILE LOGIN ANDA SESUAI DENGAN NAMA FILENYA:
// import 'login_page.dart'; // Aktifkan dan sesuaikan jika ada error di fungsi logout

// GLOBAL VARIABLE UNTUK MENAMPUNG DATA SPK YANG SEDANG DIKERJAKAN AKTIF
Map<String, dynamic>? spkAktifData;
String? spkAktifId;

class DashboardMontirPage extends StatefulWidget {
  const DashboardMontirPage({super.key});

  @override
  State<DashboardMontirPage> createState() => _DashboardMontirPageState();
}

class _DashboardMontirPageState extends State<DashboardMontirPage> {
  int _currentBottomIndex = 0;

  void ubahHalaman(int index) {
    setState(() {
      _currentBottomIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> halamanMenu = [
      KontenBerandaMontir(
        onKerjakanPressed: () => ubahHalaman(1),
        onProfilePressed: () => ubahHalaman(2), 
      ), 
      HalamanProsesServis(onSelesaiSemua: () => ubahHalaman(0)), 
      // TAMBAHKAN FUNGSI KEMBALI DI BAWAH INI:
      ProfilePage(onBackPressed: () => ubahHalaman(0)), 
    ];

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: halamanMenu[_currentBottomIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentBottomIndex, 
        selectedItemColor: Colors.blue.shade700,
        unselectedItemColor: Colors.grey.shade500,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        elevation: 15,
        onTap: ubahHalaman,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: "Beranda"),
          BottomNavigationBarItem(icon: Icon(Icons.directions_car), label: "Servis"), 
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Akun"),
        ],
      ),
    );
  }
}

// =========================================================
// 1. HALAMAN BERANDA / DASHBOARD 
// =========================================================
class KontenBerandaMontir extends StatefulWidget {
  final VoidCallback onKerjakanPressed;
  final VoidCallback onProfilePressed; 
  const KontenBerandaMontir({super.key, required this.onKerjakanPressed, required this.onProfilePressed});

  @override
  State<KontenBerandaMontir> createState() => _KontenBerandaMontirState();
}

class _KontenBerandaMontirState extends State<KontenBerandaMontir> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String namaMontir = "Mekanik"; 
  final String currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _getNamaMekanik();
  }

  void _getNamaMekanik() async {
    if (currentUid.isNotEmpty) {
      try {
        // Cari di collection 'montir' berdasarkan uid_akun
        var query = await FirebaseFirestore.instance
            .collection('montir')
            .where('uid_akun', isEqualTo: currentUid)
            .limit(1)
            .get();
            
        if (query.docs.isNotEmpty) {
          setState(() {
            namaMontir = query.docs.first.data()['nama'] ?? 'Mekanik';
          });
        }
      } catch (e) {
        debugPrint("Gagal mengambil nama mekanik: $e");
      }
    }
  }

  void _tampilkanDetailSPK(BuildContext context, Map<String, dynamic> data, String deskripsiServis) {
    // Ambil daftar sparepart dari data SPK
    final List<dynamic> daftarSparepart = data['sparepart'] ?? [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 24, right: 24, top: 12,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 50, height: 5,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const Row(
                children: [
                  Icon(Icons.assignment, color: Colors.blue),
                  SizedBox(width: 8),
                  Text("Detail SPK Kendaraan", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
              const Divider(height: 30),
              
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDetailRow("Pelanggan", data['nama_pelanggan'] ?? '-'),
                      _buildDetailRow("Kendaraan", data['kendaraan'] ?? '-'),
                      _buildDetailRow("Plat Nomor", data['plat'] ?? '-'),
                      _buildDetailRow("Jam Masuk", data['jam_masuk'] ?? '-'),
                      const Divider(height: 30),
                      
                      const Text("Keluhan / Catatan:", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54)),
                      const SizedBox(height: 4),
                      Text(data['keluhan'] ?? 'Tidak ada keluhan spesifik dicatat.', style: const TextStyle(fontSize: 14)),
                      const SizedBox(height: 16),
                      
                      const Text("Jenis Penanganan:", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54)),
                      const SizedBox(height: 4),
                      Text(deskripsiServis, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 16),

                      const Text("Sparepart & Kebutuhan:", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54)),
                      const SizedBox(height: 4),
                      if (daftarSparepart.isEmpty)
                        const Text(
                          "Tidak ada kebutuhan sparepart yang dicatat.", 
                          style: TextStyle(fontSize: 13, fontStyle: FontStyle.italic, color: Colors.grey)
                        )
                      else
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blue.shade100),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: daftarSparepart.map((item) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(Icons.build_circle, size: 14, color: Colors.blue.shade700),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        "${item['nama']} (x${item['jumlah']})",
                                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 45,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade50,
                    foregroundColor: Colors.blue.shade800,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Tutup", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      }
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 110, child: Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 13))),
          const Text(":  "),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Image.asset('assets/logo.png', width: 35, errorBuilder: (c, e, s) => const Icon(Icons.car_repair, color: Colors.blue, size: 35)),
                    const SizedBox(width: 8),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("JIMU MITSUBISHI", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.5)),
                        Text("Bengkel Terbaik", style: TextStyle(color: Colors.grey, fontSize: 10)),
                      ],
                    ),
                  ],
                ),
                InkWell(
                  onTap: widget.onProfilePressed, 
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                    child: Row(
                      children: [
                        Text("Halo, $namaMontir", style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 11)),
                        const SizedBox(width: 6),
                        CircleAvatar(
                          radius: 14,
                          backgroundColor: Colors.orange.shade100,
                          child: const Icon(Icons.face, size: 16, color: Colors.orange),
                        )
                      ],
                    ),
                  ),
                )
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('spk')
                  .where('montir_uid', isEqualTo: currentUid)
                  .snapshots(),
              builder: (context, snapshot) {
                int totalTugasAktif = 0;
                int totalSelesai = 0;

                if (snapshot.hasData) {
                  for (var doc in snapshot.data!.docs) {
                    final data = doc.data() as Map<String, dynamic>;
                    final status = data['status'];
                    if (status == 'Selesai') {
                      totalSelesai++;
                    } else if (status == 'Menunggu' || status == 'Berjalan') {
                      totalTugasAktif++;
                    }
                  }
                }

                return Row(
                  children: [
                    _buildCounterBox("Tugas Aktif", "$totalTugasAktif Unit", Colors.blue.shade700),
                    const SizedBox(width: 12),
                    _buildCounterBox("Selesai", "$totalSelesai Unit", Colors.green.shade600),
                  ],
                );
              },
            ),
          ),

          const SizedBox(height: 10),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            child: Align(alignment: Alignment.centerLeft, child: Text("Daftar Antrean SPK", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14))),
          ),

          TabBar(
            controller: _tabController,
            indicatorColor: Colors.blue.shade600,
            labelColor: Colors.blue.shade600,
            unselectedLabelColor: Colors.grey.shade400,
            indicatorSize: TabBarIndicatorSize.label,
            tabs: const [
              Tab(text: "Menunggu"),
              Tab(text: "Berjalan"),
              Tab(text: "Selesai"),
            ],
          ),

          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildTabContent('Menunggu'),
                _buildTabContent('Berjalan'),
                _buildTabContent('Selesai'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCounterBox(String title, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(color: Colors.grey.shade500, fontSize: 11, fontWeight: FontWeight.w500)),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _buildTabContent(String status) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('spk')
          .where('montir_uid', isEqualTo: currentUid)
          .where('status', isEqualTo: status)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data!.docs;
        if (docs.isEmpty) return Center(child: Text("Tidak ada data SPK $status", style: const TextStyle(color: Colors.grey)));

        return ListView.builder(
          itemCount: docs.length,
          padding: const EdgeInsets.all(12),
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data() as Map<String, dynamic>;
            
            bool isMenunggu = (status == 'Menunggu');
            bool isBerjalan = (status == 'Berjalan');

            String deskripsiServis = 'Servis Umum';
            if (data['jenis_servis'] != null) {
              if (data['jenis_servis'] is List) {
                List listServis = data['jenis_servis'];
                deskripsiServis = listServis.join(', ');
              } else {
                deskripsiServis = data['jenis_servis'].toString();
              }
            } else if (data['keluhan'] != null) {
              deskripsiServis = data['keluhan'].toString();
            }

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2))
                ]
              ),
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => _tampilkanDetailSPK(context, data, deskripsiServis),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(data['plat'] ?? '-', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 2),
                                Text(
                                  "No. SPK: ${data['no_spk'] ?? data['noSpk'] ?? '-'}",
                                  style: TextStyle(color: Colors.blue.shade900, fontWeight: FontWeight.bold, fontSize: 11),
                                ),
                              ],
                            ),
                            _buildStatusBadge(status),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(data['kendaraan'] ?? '-', style: TextStyle(color: Colors.blueGrey.shade400, fontSize: 12)),
                            const Text("Lihat Detail SPK >", style: TextStyle(color: Colors.blue, fontSize: 10, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            const Icon(Icons.build_circle_outlined, size: 16, color: Colors.grey),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                deskripsiServis,
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.black87),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(data['jam_masuk'] ?? "08:30 WIB", style: const TextStyle(fontSize: 11, color: Colors.grey)),
                          ],
                        ),
                        
                        if (status != 'Selesai') ...[
                          const SizedBox(height: 14),
                          SizedBox(
                            width: double.infinity,
                            height: 38,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue.shade600,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              ),
                              onPressed: () async {
                                if (isMenunggu) {
                                  await FirebaseFirestore.instance.collection('spk').doc(doc.id).update({'status': 'Berjalan'});
                                } else if (isBerjalan) {
                                  setState(() {
                                    spkAktifId = doc.id;
                                    spkAktifData = data;
                                  });
                                  widget.onKerjakanPressed(); 
                                }
                              },
                              child: Text(isMenunggu ? "MULAI KERJA SEKARANG" : "BUKA PANEL KERJA", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                            ),
                          ),
                        ]
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bg = Colors.orange.shade50; Color txt = Colors.orange.shade700; String label = "MENUNGGU";
    if (status == 'Berjalan') { bg = Colors.blue.shade50; txt = Colors.blue.shade700; label = "DIKERJAKAN"; }
    else if (status == 'Selesai') { bg = Colors.green.shade50; txt = Colors.green.shade700; label = "SELESAI"; }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: Text(label, style: TextStyle(color: txt, fontWeight: FontWeight.bold, fontSize: 9)),
    );
  }
}

// =========================================================================
// 2. HALAMAN CEKLIST PROSES SERVIS (DIKEMBALIKAN UTUH 100%)
// =========================================================================
class HalamanProsesServis extends StatefulWidget {
  final VoidCallback onSelesaiSemua;
  const HalamanProsesServis({super.key, required this.onSelesaiSemua});

  @override
  State<HalamanProsesServis> createState() => _HalamanProsesServisState();
}

class _HalamanProsesServisState extends State<HalamanProsesServis> {
  // Fungsi pengonversi menit menjadi Hari, Jam, dan Menit
  String _formatEstimasi(String estimasiMentah) {
    int totalMenit = int.tryParse(estimasiMentah) ?? 0;
    if (totalMenit <= 0) return "Fleksibel";
    
    final hari = totalMenit ~/ 1440; // 1 Hari = 1440 menit
    final sisaSetelahHari = totalMenit % 1440;
    final jam = sisaSetelahHari ~/ 60; // 1 Jam = 60 menit
    final menit = sisaSetelahHari % 60;

    final parts = <String>[];
    if (hari > 0) parts.add("$hari Hari");
    if (jam > 0) parts.add("$jam Jam");
    if (menit > 0) parts.add("$menit Menit");
    
    return parts.join(" ");
  }

  void _bukaDetailSPK(BuildContext context, Map<String, dynamic> data) {
    final List<dynamic> daftarSparepart = data['sparepart'] ?? [];
    
    String deskripsiServis = 'Servis Umum';
    if (data['jenis_servis'] != null) {
      if (data['jenis_servis'] is List) {
        List listServis = data['jenis_servis'];
        deskripsiServis = listServis.join(', ');
      } else {
        deskripsiServis = data['jenis_servis'].toString();
      }
    } else if (data['keluhan'] != null) {
      deskripsiServis = data['keluhan'].toString();
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 24, right: 24, top: 12,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 50, height: 5,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const Row(
                children: [
                  Icon(Icons.assignment, color: Colors.blue),
                  SizedBox(width: 8),
                  Text("Detail SPK Kendaraan", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
              const Divider(height: 30),
              
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDetailItem("Pelanggan", data['nama_pelanggan'] ?? '-'),
                      _buildDetailItem("Kendaraan", data['kendaraan'] ?? '-'),
                      _buildDetailItem("Plat Nomor", data['plat'] ?? '-'),
                      _buildDetailItem("Jam Masuk", data['waktu'] ?? data['jam_masuk'] ?? '-'),
                      const Divider(height: 30),
                      
                      const Text("Keluhan / Catatan:", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54)),
                      const SizedBox(height: 4),
                      Text(data['keluhan'] ?? 'Tidak ada keluhan spesifik dicatat.', style: const TextStyle(fontSize: 14)),
                      const SizedBox(height: 16),
                      
                      const Text("Jenis Penanganan:", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54)),
                      const SizedBox(height: 4),
                      Text(deskripsiServis, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 16),

                      const Text("Sparepart & Kebutuhan:", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54)),
                      const SizedBox(height: 4),
                      if (daftarSparepart.isEmpty)
                        const Text(
                          "Tidak ada kebutuhan sparepart yang dicatat.", 
                          style: TextStyle(fontSize: 13, fontStyle: FontStyle.italic, color: Colors.grey)
                        )
                      else
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blue.shade100),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: daftarSparepart.map((sp) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: Text(
                                  "- ${sp['nama']} (Qty: ${sp['jumlah']})",
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildEmptyStateList(BuildContext context) {
    final String currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text("Panel Kerja Mekanik", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0.5,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 40),
            Center(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(color: Colors.blue.shade50, shape: BoxShape.circle),
                    child: Icon(Icons.car_repair_outlined, size: 60, color: Colors.blue.shade800),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Belum Ada SPK Aktif",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  const SizedBox(height: 6),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 40),
                    child: Text(
                      "Pilih salah satu SPK berjalan Anda di bawah ini untuk membuka panel kerja pengerjaan.",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey, fontSize: 12, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Daftar SPK Berjalan Anda",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black54),
                ),
              ),
            ),
            const SizedBox(height: 10),

            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('spk')
                  .where('montir_uid', isEqualTo: currentUid)
                  .where('status', isEqualTo: 'Berjalan')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()));
                }
                
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(20),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: const Center(
                      child: Text(
                        "Tidak ada SPK berstatus 'Berjalan'. Silakan mulai kerja SPK baru di tab Beranda.",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ),
                  );
                }

                final docs = snapshot.data!.docs;

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: docs.length,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final plat = data['plat'] ?? '-';
                    final kendaraan = data['kendaraan'] ?? '-';
                    final noSpk = data['no_spk'] ?? data['noSpk'] ?? '-';
                    final tanggal = data['tanggal'] ?? '-';

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.blue.shade100, width: 1),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: CircleAvatar(
                          backgroundColor: Colors.blue.shade50,
                          child: Icon(Icons.engineering, color: Colors.blue.shade800),
                        ),
                        title: Text(
                          "$kendaraan ($plat)",
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        subtitle: Text(
                          "No. SPK: $noSpk\nMasuk: $tanggal",
                          style: const TextStyle(fontSize: 11, color: Colors.black54),
                        ),
                        trailing: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              spkAktifId = doc.id;
                              spkAktifData = data;
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue.shade800,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          ),
                          child: const Text("Buka", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (spkAktifId == null) {
      return _buildEmptyStateList(context);
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('spk').doc(spkAktifId).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Scaffold(body: Center(child: CircularProgressIndicator()));
        
        final docData = snapshot.data!.data() as Map<String, dynamic>?;
        if (docData == null) return const Scaffold(body: Center(child: Text("Data tidak ditemukan")));

        List<Map<String, dynamic>> listPekerjaanDinamis = [];
        String estimasiGlobal = docData['estimasi_waktu'] ?? '30';

        if (docData['items'] != null) {
          listPekerjaanDinamis = List<Map<String, dynamic>>.from(docData['items']);
        } else if (docData['jenis_servis'] != null) {
          if (docData['jenis_servis'] is List) {
            List listTeks = docData['jenis_servis'];
            for (var namaItem in listTeks) {
              if (namaItem.toString().trim().isNotEmpty) {
                listPekerjaanDinamis.add({
                  'nama': namaItem.toString().trim(),
                  'estimasi': estimasiGlobal,
                  'status': 'Belum Mulai'
                });
              }
            }
          } else {
            String teksDariAdmin = docData['jenis_servis'].toString();
            List<String> potonganServis = teksDariAdmin.split(',');
            for (var namaItem in potonganServis) {
              if (namaItem.trim().isNotEmpty) {
                listPekerjaanDinamis.add({
                  'nama': namaItem.trim(),
                  'estimasi': estimasiGlobal,
                  'status': 'Belum Mulai'
                });
              }
            }
          }
        }

        int totalTugas = listPekerjaanDinamis.length;
        int tugasSelesai = listPekerjaanDinamis.where((item) => item['status'] == 'Selesai').length;
        double persenProgress = totalTugas > 0 ? (tugasSelesai / totalTugas) : 0.0;
        
        bool isSemuaSelesai = totalTugas > 0 && tugasSelesai == totalTugas;

        int totalEstimasiMenit = 0;
        for (var item in listPekerjaanDinamis) {
          String est = item['estimasi'] ?? '0';
          est = est.replaceAll(RegExp(r'[^0-9]'), '');
          int menit = int.tryParse(est) ?? 0;
          totalEstimasiMenit += menit;
        }
        String totalEstimasiFormat = _formatEstimasi(totalEstimasiMenit.toString());

        return Scaffold(
          backgroundColor: Colors.grey.shade50,
          appBar: AppBar(
            title: const Text("Mekanik Live Tracking", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            elevation: 0.5,
            centerTitle: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                widget.onSelesaiSemua();
              },
            ),
          ),
          body: Column(
            children: [
              Container(
                margin: const EdgeInsets.all(14),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade900,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [BoxShadow(color: Colors.blue.shade900.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 4))],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const CircleAvatar(
                          radius: 20,
                          backgroundColor: Colors.white24,
                          child: Icon(Icons.engineering, color: Colors.white),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(docData['kendaraan'] ?? '-', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                              Text(
                                "No. SPK: ${docData['no_spk'] ?? docData['noSpk'] ?? '-'}", 
                                style: TextStyle(color: Colors.blue.shade100, fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  const Icon(Icons.timer_outlined, color: Colors.white70, size: 12),
                                  const SizedBox(width: 4),
                                  Text(
                                    "Total Est: $totalEstimasiFormat", 
                                    style: const TextStyle(color: Colors.white70, fontSize: 11),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.info_outline, color: Colors.white70),
                          onPressed: () => _bukaDetailSPK(context, docData),
                          tooltip: "Lihat Detail SPK",
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: Colors.amber, borderRadius: BorderRadius.circular(20)),
                          child: const Text("LIVE", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 10)),
                        )
                      ],
                    ),
                    const Divider(color: Colors.white24, height: 20),
                    
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Progress Kerja: $tugasSelesai dari $totalTugas Selesai",
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                        Text(
                          "${(persenProgress * 100).toInt()}%",
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: persenProgress,
                        backgroundColor: Colors.white12,
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.greenAccent),
                        minHeight: 8,
                      ),
                    ),
                  ],
                ),
              ),

              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Align(
                  alignment: Alignment.centerLeft, 
                  child: Text("Item Servis (Sentuh untuk Menyelesaikan):", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black54)),
                ),
              ),

              Expanded(
                child: listPekerjaanDinamis.isEmpty
                    ? const Center(child: Text("Tidak ada item ceklist.", style: TextStyle(color: Colors.grey)))
                    : ListView.builder(
                        itemCount: listPekerjaanDinamis.length,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        itemBuilder: (context, index) {
                          final item = listPekerjaanDinamis[index];
                          String namaTugas = item['nama'] ?? 'Item Servis';
                          
                          String estimasiMentah = item['estimasi'] ?? '0';
                          String estimasiFormat = _formatEstimasi(estimasiMentah);
                          
                          bool isSelesai = item['status'] == 'Selesai';

                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: isSelesai ? Colors.green.shade200 : Colors.grey.shade300),
                            ),
                            child: CheckboxListTile(
                              activeColor: Colors.green,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                              title: Text(
                                namaTugas,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: isSelesai ? Colors.grey : Colors.black87,
                                  decoration: isSelesai ? TextDecoration.lineThrough : TextDecoration.none,
                                ),
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  isSelesai ? "Selesai ditangani" : "Estimasi pengerjaan: $estimasiFormat",
                                  style: TextStyle(fontSize: 11, color: isSelesai ? Colors.green : Colors.black54),
                                ),
                              ),
                              value: isSelesai,
                              onChanged: (bool? checked) async {
                                if (checked != null) {
                                  listPekerjaanDinamis[index]['status'] = checked ? 'Selesai' : 'Belum Mulai';
                                  await FirebaseFirestore.instance.collection('spk').doc(spkAktifId).update({
                                    'items': listPekerjaanDinamis
                                  });
                                }
                              },
                            ),
                          );
                        },
                      ),
              ),

              Padding(
                padding: const EdgeInsets.all(14),
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isSemuaSelesai ? Colors.blue.shade700 : Colors.grey.shade400,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: isSemuaSelesai 
                        ? () async {
                            await FirebaseFirestore.instance.collection('spk').doc(spkAktifId).update({
                              'status': 'Selesai',
                              'waktu_selesai': Timestamp.now()
                            });

                            setState(() {
                              spkAktifId = null;
                              spkAktifData = null;
                            });
                            
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Laporan SPK berhasil dikirim, mobil siap diambil!")),
                            );
                            widget.onSelesaiSemua();
                          }
                        : () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Selesaikan seluruh ceklist tugas terlebih dahulu!"),
                                backgroundColor: Colors.red,
                              ),
                            );
                          },
                    child: Text(
                      isSemuaSelesai ? "SELESAI & SERAHKAN KUNCI" : "SELESAIKAN TUGAS DULU", 
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)
                    ),
                  ),
                ),
              )
            ],
          ),
        );
      },
    );
  }
}

// =========================================================
// 3. HALAMAN PROFIL (DENGAN STATISTIK & RIWAYAT)
// =========================================================
class ProfilePage extends StatefulWidget {
  final VoidCallback onBackPressed; // Menampung fungsi kembali
  
  const ProfilePage({super.key, required this.onBackPressed});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final User? currentUser = FirebaseAuth.instance.currentUser;
  
  String _namaMontir = "Mekanik...";
  String _spesialisasi = "Mekanik Umum";
  int _selesaiHariIni = 0;
  int _selesaiBulanIni = 0;

  @override
  void initState() {
    super.initState();
    _loadDataProfilDanStatistik();
  }

  Future<void> _loadDataProfilDanStatistik() async {
    if (currentUser != null) {
      try {
        final query = await FirebaseFirestore.instance
            .collection('montir')
            .where('uid_akun', isEqualTo: currentUser!.uid)
            .limit(1)
            .get();

        if (query.docs.isNotEmpty) {
          final doc = query.docs.first;
          final data = doc.data();
          setState(() {
            _namaMontir = data['nama'] ?? 'Mekanik';
            _spesialisasi = data['spesialis'] ?? 'Mekanik Umum';
          });
        }

        final spkSelesai = await FirebaseFirestore.instance
            .collection('spk')
            .where('montir_uid', isEqualTo: currentUser!.uid)
            .where('status', isEqualTo: 'Selesai')
            .get();

        final now = DateTime.now();
        int hitungHariIni = 0;
        int hitungBulanIni = 0;

        for (var spk in spkSelesai.docs) {
          final data = spk.data();
          if (data['waktu_selesai'] != null) {
            DateTime waktuSelesai = (data['waktu_selesai'] as Timestamp).toDate();
            if (waktuSelesai.year == now.year && waktuSelesai.month == now.month) {
              hitungBulanIni++;
              if (waktuSelesai.day == now.day) {
                hitungHariIni++;
              }
            }
          }
        }

        setState(() {
          _selesaiHariIni = hitungHariIni;
          _selesaiBulanIni = hitungBulanIni;
        });

      } catch (e) {
        debugPrint("Error load profil & stat: $e");
      }
    }
  }

  void _konfirmasiLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Konfirmasi Logout"),
        content: const Text("Apakah Anda yakin ingin keluar dari akun mekanik ini?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(context); // Tutup dialog konfirmasi dulu
              
              // Proses logout dari Firebase
              await FirebaseAuth.instance.signOut();
              
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginMobilePage()), 
                  (Route<dynamic> route) => false,
                );
              }
            },
            child: const Text("Ya, Logout", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView( 
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            
            // --- HEADER DENGAN TOMBOL KEMBALI ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.black87),
                  onPressed: widget.onBackPressed, // Memanggil fungsi kembali ke Beranda
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(), // Mengurangi jarak kosong di sekitar ikon
                ),
                const Text("Profil Mekanik", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(width: 24), // Spacer bayangan agar teks tetap persis di tengah
              ],
            ),
            
            const SizedBox(height: 30),
            
            CircleAvatar(
              radius: 45,
              backgroundColor: Colors.blue.shade50,
              child: Icon(Icons.engineering, size: 50, color: Colors.blue.shade800),
            ),
            const SizedBox(height: 16),
            
            Text(_namaMontir, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: Colors.amber.shade100, borderRadius: BorderRadius.circular(20)),
              child: Text(
                "Spesialis: $_spesialisasi",
                style: TextStyle(color: Colors.amber.shade900, fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
            const SizedBox(height: 8),
            Text(currentUser?.email ?? 'Email tidak ditemukan', style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
            
            const SizedBox(height: 30),

            Row(
              children: [
                _buildStatBox("Selesai Hari Ini", "$_selesaiHariIni Unit", Colors.green),
                const SizedBox(width: 16),
                _buildStatBox("Selesai Bulan Ini", "$_selesaiBulanIni Unit", Colors.blue),
              ],
            ),
            
            const SizedBox(height: 30),

            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))]
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
                      child: Icon(Icons.history, color: Colors.blue.shade700),
                    ),
                    title: const Text("Riwayat Pekerjaan Saya", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    subtitle: const Text("Lihat mobil yang pernah ditangani", style: TextStyle(fontSize: 11)),
                    trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const RiwayatKerjaMontirPage()));
                    },
                  ),

                ],
              ),
            ),

            const SizedBox(height: 30),
            
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade50,
                  foregroundColor: Colors.red.shade700,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.red.shade200),
                  ),
                ),
                onPressed: () => _konfirmasiLogout(context),
                icon: const Icon(Icons.logout),
                label: const Text("Keluar Akun (Logout)", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatBox(String title, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Text(title, style: TextStyle(color: Colors.grey.shade600, fontSize: 11, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(value, style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.w900)),
          ],
        ),
      ),
    );
  }
}

// =========================================================
// 4. HALAMAN BARU: RIWAYAT PEKERJAAN MONTIR
// =========================================================
class RiwayatKerjaMontirPage extends StatefulWidget {
  const RiwayatKerjaMontirPage({super.key});

  @override
  State<RiwayatKerjaMontirPage> createState() => _RiwayatKerjaMontirPageState();
}

class _RiwayatKerjaMontirPageState extends State<RiwayatKerjaMontirPage> {
  String _keyword = "";
  final TextEditingController _searchController = TextEditingController();

  void _bukaDetailSPK(BuildContext context, Map<String, dynamic> data) {
    final List<dynamic> daftarSparepart = data['sparepart'] ?? [];
    
    String deskripsiServis = 'Servis Umum';
    if (data['jenis_servis'] != null) {
      if (data['jenis_servis'] is List) {
        List listServis = data['jenis_servis'];
        deskripsiServis = listServis.join(', ');
      } else {
        deskripsiServis = data['jenis_servis'].toString();
      }
    } else if (data['keluhan'] != null) {
      deskripsiServis = data['keluhan'].toString();
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 24, right: 24, top: 12,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 50, height: 5,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const Row(
                children: [
                  Icon(Icons.assignment, color: Colors.blue),
                  SizedBox(width: 8),
                  Text("Detail SPK Kendaraan", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
              const Divider(height: 30),
              
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDetailItem("Pelanggan", data['nama_pelanggan'] ?? '-'),
                      _buildDetailItem("Kendaraan", data['kendaraan'] ?? '-'),
                      _buildDetailItem("Plat Nomor", data['plat'] ?? '-'),
                      _buildDetailItem("Jam Masuk", data['waktu'] ?? data['jam_masuk'] ?? '-'),
                      const Divider(height: 30),
                      
                      const Text("Keluhan / Catatan:", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54)),
                      const SizedBox(height: 4),
                      Text(data['keluhan'] ?? 'Tidak ada keluhan spesifik dicatat.', style: const TextStyle(fontSize: 14)),
                      const SizedBox(height: 16),
                      
                      const Text("Jenis Penanganan:", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54)),
                      const SizedBox(height: 4),
                      Text(deskripsiServis, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 16),

                      const Text("Sparepart & Kebutuhan:", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54)),
                      const SizedBox(height: 4),
                      if (daftarSparepart.isEmpty)
                        const Text(
                          "Tidak ada kebutuhan sparepart yang dicatat.", 
                          style: TextStyle(fontSize: 13, fontStyle: FontStyle.italic, color: Colors.grey)
                        )
                      else
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blue.shade100),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: daftarSparepart.map((sp) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: Text(
                                  "- ${sp['nama']} (Qty: ${sp['jumlah']})",
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text("Riwayat Pekerjaan Saya", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: Colors.white,
            child: TextField(
              controller: _searchController,
              onChanged: (val) {
                setState(() {
                  _keyword = val.trim().toLowerCase();
                });
              },
              decoration: InputDecoration(
                hintText: "Cari plat nomor atau jenis kendaraan...",
                hintStyle: const TextStyle(fontSize: 13, color: Colors.grey),
                prefixIcon: const Icon(Icons.search, size: 20),
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide(color: Colors.blue.shade300),
                ),
                fillColor: Colors.grey.shade50,
                filled: true,
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('spk')
                  .where('montir_uid', isEqualTo: currentUid)
                  .where('status', isEqualTo: 'Selesai')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text("Terjadi kesalahan: ${snapshot.error}"));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text("Belum ada riwayat pekerjaan yang selesai.", style: TextStyle(color: Colors.grey)),
                  );
                }

                var docs = snapshot.data!.docs.toList();
                
                if (_keyword.isNotEmpty) {
                  docs = docs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final plat = (data['plat'] ?? '').toString().toLowerCase();
                    final kendaraan = (data['kendaraan'] ?? '').toString().toLowerCase();
                    final noSpk = (data['no_spk'] ?? data['noSpk'] ?? '').toString().toLowerCase();
                    return plat.contains(_keyword) || kendaraan.contains(_keyword) || noSpk.contains(_keyword);
                  }).toList();
                }

                docs.sort((a, b) {
                  final dataA = a.data() as Map<String, dynamic>;
                  final dataB = b.data() as Map<String, dynamic>;
                  Timestamp? waktuA = dataA['waktu_selesai'] as Timestamp?;
                  Timestamp? waktuB = dataB['waktu_selesai'] as Timestamp?;
                  
                  if (waktuA == null || waktuB == null) return 0;
                  return waktuB.compareTo(waktuA);
                });

                if (docs.isEmpty) {
                  return const Center(
                    child: Text("Pekerjaan yang Anda cari tidak ditemukan.", style: TextStyle(color: Colors.grey)),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    
                    String tanggalSelesai = "-";
                    if (data['waktu_selesai'] != null) {
                      DateTime dt = (data['waktu_selesai'] as Timestamp).toDate();
                      tanggalSelesai = "${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}";
                    }

                    return Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.grey.shade300)
                      ),
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        onTap: () => _bukaDetailSPK(context, data),
                        leading: CircleAvatar(
                          backgroundColor: Colors.green.shade50,
                          child: Icon(Icons.verified, color: Colors.green.shade600),
                        ),
                        title: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(data['plat'] ?? 'Tanpa Plat', style: const TextStyle(fontWeight: FontWeight.bold)),
                            const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text("Kendaraan: ${data['kendaraan'] ?? '-'}"),
                            const SizedBox(height: 2),
                            Text("No. SPK: ${data['no_spk'] ?? data['noSpk'] ?? '-'}"),
                            const SizedBox(height: 4),
                            Text("Tgl Selesai: $tanggalSelesai", style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}