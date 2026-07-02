import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ServisMobilePage extends StatefulWidget {
  const ServisMobilePage({super.key});

  @override
  State<ServisMobilePage> createState() => _ServisMobilePageState();
}

class _ServisMobilePageState extends State<ServisMobilePage> {
  final String? userEmail = FirebaseAuth.instance.currentUser?.email;

  Future<void> _sembunyikanDariAktif(String docId) async {
    try {
      await FirebaseFirestore.instance
          .collection('spk')
          .doc(docId)
          .update({'is_hidden': true});
          
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Telah dipindahkan ke Riwayat Servis di menu Akun"),
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint("Gagal update status: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "Layanan Servis",
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: userEmail == null
          ? const Center(child: Text("Silakan login terlebih dahulu"))
          : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('spk')
                  .where('email', isEqualTo: userEmail)
                  .orderBy('created_at', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Colors.blue));
                }
                if (snapshot.hasError) {
                  return Center(child: Text("Terjadi kesalahan:\n${snapshot.error}"));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return _buildEmptyState();
                }

                final listSpkBerjalan = snapshot.data!.docs.where((doc) {
                  final data = doc.data();
                  final status = (data['status'] ?? '').toString().toLowerCase();
                  final isHidden = data['is_hidden'] == true;
                  return status != 'selesai' && !isHidden; 
                }).toList();

                final listSpkSelesai = snapshot.data!.docs.where((doc) {
                  final data = doc.data();
                  final status = (data['status'] ?? '').toString().toLowerCase();
                  final isHidden = data['is_hidden'] == true;
                  return status == 'selesai' && !isHidden; 
                }).take(2).toList(); 

                if (listSpkBerjalan.isEmpty && listSpkSelesai.isEmpty) {
                  return _buildEmptyState();
                }

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      
                      if (listSpkBerjalan.isNotEmpty) ...[
                        const Padding(
                          padding: EdgeInsets.only(bottom: 12, left: 4),
                          child: Text(
                            "Sedang Diproses",
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black54),
                          ),
                        ),
                        ...listSpkBerjalan.map((doc) => _TimelineCard(data: doc.data())),
                      ],

                      if (listSpkSelesai.isNotEmpty) ...[
                        if (listSpkBerjalan.isNotEmpty) const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(child: Divider(color: Colors.grey.shade300, thickness: 1.5)),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: Text(
                                "Baru Saja Selesai",
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.green.shade700),
                              ),
                            ),
                            Expanded(child: Divider(color: Colors.grey.shade300, thickness: 1.5)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        
                        ...listSpkSelesai.map((doc) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(24),
                                onTap: () => _sembunyikanDariAktif(doc.id),
                                child: _TimelineCard(data: doc.data(), isTappable: true),
                              ),
                            ),
                          );
                        }),
                        
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 8, bottom: 24),
                            child: Text(
                              "Ketuk kartu di atas untuk menyembunyikannya",
                              style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontStyle: FontStyle.italic),
                            ),
                          ),
                        )
                      ],
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: Colors.blue.shade50, shape: BoxShape.circle),
            child: Icon(Icons.car_repair_outlined, size: 64, color: Colors.blue.shade300),
          ),
          const SizedBox(height: 24),
          const Text(
            "Tidak Ada Servis Aktif",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          const SizedBox(height: 8),
          Text(
            "Kendaraan yang sedang diservis akan muncul di sini.",
            style: TextStyle(color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }
}

class _TimelineCard extends StatefulWidget {
  final Map<String, dynamic> data;
  final bool isTappable;
  
  const _TimelineCard({required this.data, this.isTappable = false});

  @override
  State<_TimelineCard> createState() => _TimelineCardState();
}

class _TimelineCardState extends State<_TimelineCard> {
  bool _isChecklistExpanded = false;

  // FUNGSI KONVERSI WAKTU BARU
  String _formatEstimasi(String estimasiMentah) {
    int totalMenit = int.tryParse(estimasiMentah) ?? 0;
    if (totalMenit <= 0) return "Fleksibel";
    
    final hari = totalMenit ~/ 1440;
    final sisaSetelahHari = totalMenit % 1440;
    final jam = sisaSetelahHari ~/ 60;
    final menit = sisaSetelahHari % 60;

    final parts = <String>[];
    if (hari > 0) parts.add("$hari Hari");
    if (jam > 0) parts.add("$jam Jam");
    if (menit > 0) parts.add("$menit Menit");
    
    return parts.join(" ");
  }

  @override
  Widget build(BuildContext context) {
    final rawStatus = (widget.data['status'] ?? 'Menunggu').toString().toLowerCase();
    bool isProses = rawStatus == 'sedang dikerjakan' || rawStatus == 'proses' || rawStatus == 'berjalan';
    bool isSelesai = rawStatus == 'selesai';
    if (isSelesai) isProses = true; 

    final kendaraan = widget.data['kendaraan'] ?? 'Kendaraan';
    final plat = widget.data['plat'] ?? '-';
    final tanggal = widget.data['tanggal'] ?? '';
    final jamMasuk = widget.data['jam_masuk'] ?? '';
    final namaMontir = widget.data['nama_montir'] ?? 'Menunggu Mekanik';
    final estimasi = widget.data['estimasi_waktu'] ?? '-';
    final itemsPekerjaan = widget.data['items'] as List<dynamic>? ?? [];

    int totalItems = itemsPekerjaan.length;
    int selesaiItems = itemsPekerjaan.where((item) {
      return item['status']?.toString().toLowerCase() == 'selesai' || isSelesai;
    }).length;

    return Container(
      margin: EdgeInsets.only(bottom: widget.isTappable ? 0 : 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: widget.isTappable ? Colors.green.shade200 : Colors.grey.shade200, 
          width: widget.isTappable ? 1.5 : 1.0
        ),
        boxShadow: [
          BoxShadow(color: Colors.blue.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isSelesai ? Colors.green.shade50 : Colors.blue.shade50,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        kendaraan.toUpperCase(),
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                      ),
                    ),
                    _buildStatusBadge(rawStatus),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  plat.toUpperCase(),
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: isSelesai ? Colors.green.shade700 : Colors.blue.shade700),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.calendar_today_outlined, size: 14, color: Colors.grey.shade600),
                    const SizedBox(width: 6),
                    Text(
                      "Check-in: $tanggal, $jamMasuk",
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade700, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                _buildStep(
                  title: "Penerimaan",
                  subtitle: Text("Selesai • $jamMasuk", style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                  isActive: true,
                  isLast: false,
                ),
                _buildStep(
                  title: "Sedang Dikerjakan",
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Mekanik: $namaMontir", style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                      if (isProses && itemsPekerjaan.isNotEmpty && !_isChecklistExpanded) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: totalItems > 0 ? selesaiItems / totalItems : 0,
                                  backgroundColor: Colors.grey.shade200,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.green.shade500),
                                  minHeight: 6,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              "$selesaiItems/$totalItems Selesai",
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.green.shade700),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text("Ketuk untuk lihat detail pekerjaan", style: TextStyle(fontSize: 10, color: Colors.blue.shade400, fontStyle: FontStyle.italic)),
                      ]
                    ],
                  ),
                  isActive: isProses,
                  isLast: false,
                  isExpandable: isProses && itemsPekerjaan.isNotEmpty,
                  isExpanded: _isChecklistExpanded,
                  onTap: () {
                    if (isProses && itemsPekerjaan.isNotEmpty && !widget.isTappable) {
                      setState(() { _isChecklistExpanded = !_isChecklistExpanded; });
                    }
                  },
                  child: AnimatedSize(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    child: _isChecklistExpanded 
                        ? Padding(padding: const EdgeInsets.only(top: 8), child: _buildChecklistContainer(itemsPekerjaan, isSelesai))
                        : const SizedBox(width: double.infinity),
                  ),
                ),
                _buildStep(
                  title: "Selesai",
                  subtitle: Text(isSelesai ? "Siap diambil" : "Estimasi selesai belum tersedia", style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                  isActive: isSelesai,
                  isLast: true,
                ),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 18),
            decoration: BoxDecoration(
              color: isSelesai ? Colors.green.shade600 : Colors.blue.shade700,
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(isSelesai ? Icons.verified : Icons.timer_outlined, color: Colors.white, size: 22),
                const SizedBox(width: 10),
                Text(
                  isSelesai ? "SIAP DIAMBIL / SELESAI" : "Estimasi Selesai : ${_formatEstimasi(estimasi)}", // Menggunakan formatter
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 0.5),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildStep({
    required String title,
    required Widget subtitle,
    required bool isActive,
    required bool isLast,
    bool isExpandable = false,
    bool isExpanded = false,
    VoidCallback? onTap,
    Widget? child,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 24, height: 24,
                decoration: BoxDecoration(
                  color: isActive ? Colors.green : Colors.grey.shade300,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                ),
                child: isActive ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 3, margin: const EdgeInsets.symmetric(vertical: 4),
                    decoration: BoxDecoration(color: isActive ? Colors.green : Colors.grey.shade200, borderRadius: BorderRadius.circular(2)),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  InkWell(
                    onTap: onTap,
                    borderRadius: BorderRadius.circular(8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: isActive ? Colors.black87 : Colors.grey.shade500)),
                              const SizedBox(height: 2),
                              subtitle,
                            ],
                          ),
                        ),
                        if (isExpandable)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Icon(isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, color: Colors.blue.shade700),
                          ),
                      ],
                    ),
                  ),
                  if (child != null) child,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChecklistContainer(List<dynamic> itemsPekerjaan, bool spkSelesai) {
    if (itemsPekerjaan.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider()),
        Text("DAFTAR PEKERJAAN", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey.shade500, letterSpacing: 1.0)),
        const SizedBox(height: 16),
        ...itemsPekerjaan.map((item) {
          bool itemSelesai = item['status']?.toString().toLowerCase() == 'selesai';
          if (spkSelesai) itemSelesai = true;

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Icon(itemSelesai ? Icons.check_circle : Icons.circle_outlined, color: itemSelesai ? Colors.green : Colors.grey.shade400, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    item['nama'] ?? '-',
                    style: TextStyle(
                      fontSize: 13,
                      color: itemSelesai ? Colors.black54 : Colors.black87,
                      decoration: itemSelesai ? TextDecoration.lineThrough : null,
                    ),
                  ),
                ),
                Text(
                  itemSelesai ? "Selesai" : (item['estimasi'] != null ? "Est. ${_formatEstimasi(item['estimasi'].toString())}" : ""),
                  style: TextStyle(fontSize: 11, color: itemSelesai ? Colors.green : Colors.grey.shade400, fontWeight: itemSelesai ? FontWeight.bold : FontWeight.normal),
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildStatusBadge(String rawStatus) {
    Color bgColor = Colors.grey.shade200;
    Color textColor = Colors.grey.shade800;
    String label = rawStatus.toUpperCase();

    if (rawStatus == 'menunggu') {
      bgColor = Colors.orange.shade100;
      textColor = Colors.orange.shade800;
    } else if (rawStatus == 'sedang dikerjakan' || rawStatus == 'proses' || rawStatus == 'berjalan') {
      bgColor = Colors.blue.shade100;
      textColor = Colors.blue.shade800;
      label = "BERJALAN";
    } else if (rawStatus == 'selesai') {
      bgColor = Colors.green.shade100;
      textColor = Colors.green.shade800;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: TextStyle(color: textColor, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }
}