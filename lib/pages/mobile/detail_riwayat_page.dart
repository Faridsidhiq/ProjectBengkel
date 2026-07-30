import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DetailRiwayatPage extends StatelessWidget {
  final Map<String, dynamic> data;

  const DetailRiwayatPage({super.key, required this.data});

  static const Map<String, int> _jenisServisDanHarga = {
    "Tune Up & Scanning System": 200000,
    "Ganti Oli & Filter Oli": 60000,
    "Service Rem / Brake 4 Roda": 200000,
    "Service Kaki-Kaki": 0,
    "Electrical System": 0,
    "Service Kopling / Clutch System": 450000,
    "Ganti Timing Belt": 300000,
    "Overhaul Mesin": 2500000,
    "Overhaul Manual Transmisi": 1500000,
    "Overhaul Gardan": 750000,
    "Overhaul Automatic Transmisi": 2500000,
  };

  static const Map<String, int> _jenisServisDanEstimasi = {
    "Tune Up & Scanning System": 90,       // 1 jam 30 menit
    "Ganti Oli & Filter Oli": 30,          // 30 menit
    "Service Rem / Brake 4 Roda": 60,      // 1 jam
    "Service Kaki-Kaki": 120,              // 2 jam
    "Electrical System": 120,              // 2 jam
    "Service Kopling / Clutch System": 240,// 4 jam
    "Ganti Timing Belt": 180,              // 3 jam
    "Overhaul Mesin": 1440,                // 1 hari
    "Overhaul Manual Transmisi": 480,      // 8 jam
    "Overhaul Gardan": 300,                // 5 jam
    "Overhaul Automatic Transmisi": 1440,  // 1 hari
  };

  String _formatEstimasi(String estimasiMentah) {
    if (estimasiMentah == '-' || estimasiMentah.isEmpty) return "Fleksibel";
    if (estimasiMentah.contains("Menit") || estimasiMentah.contains("Jam") || estimasiMentah.contains("Hari")) {
      return estimasiMentah;
    }
    
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

  String _formatRupiah(dynamic angka) {
    if (angka == null) return "Rp 0";
    final number = int.tryParse(angka.toString()) ?? 0;
    final format = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    return format.format(number);
  }

  @override
  Widget build(BuildContext context) {
    final noSpk = data['no_spk'] ?? data['noSpk'] ?? '-';
    final statusServis = data['status'] ?? 'Selesai';
    final kendaraan = data['kendaraan'] ?? 'Mobil Saya';
    final plat = data['plat'] ?? '-';
    final km = data['km']?.toString() ?? '-';
    final namaMontir = data['nama_montir'] ?? 'Mekanik';
    
    final tanggal = data['tanggal'] ?? '-';
    final waktuMasuk = data['waktu'] ?? data['jam_masuk'] ?? '-';
    final estimasi = data['estimasi'] ?? data['estimasi_waktu'] ?? '-';
    final keluhan = data['keluhan'] ?? '-';
    
    // Parsing jenis_servis list
    List<String> listServis = [];
    if (data['jenis_servis'] != null) {
      if (data['jenis_servis'] is List) {
        listServis = List<String>.from(data['jenis_servis']);
      } else {
        listServis = data['jenis_servis'].toString().split(',').map((e) => e.trim()).toList();
      }
    }
    final jenisServisStr = listServis.join(', ');

    final List<dynamic> spareparts = data['sparepart'] ?? [];
    final int totalHargaSparepart = (double.tryParse(data['total_harga']?.toString() ?? '0') ?? 0).toInt();
    final int biayaJasa = (double.tryParse(data['biaya_jasa']?.toString() ?? '0') ?? 0).toInt();

    // Hitung pembagian harga untuk jasa fleksibel
    int totalFixed = 0;
    final List<String> flexibleServices = [];
    for (var nama in listServis) {
      final int harga = _jenisServisDanHarga[nama] ?? 0;
      if (harga > 0) {
        totalFixed += harga;
      } else {
        flexibleServices.add(nama);
      }
    }
    final int remainingCost = biayaJasa - totalFixed;
    final int hargaPerFlexible = (flexibleServices.isNotEmpty && remainingCost > 0)
        ? remainingCost ~/ flexibleServices.length
        : 0;

    // Persiapkan data checklist pekerjaan
    List<Map<String, dynamic>> listPekerjaan = [];
    if (data['items'] != null) {
      listPekerjaan = List<Map<String, dynamic>>.from(data['items']);
    }

    // Kalkulasi progress
    int totalTugas = listPekerjaan.length;
    int tugasSelesai = listPekerjaan.where((item) => item['status'] == 'Selesai').length;
    double persenProgress = totalTugas > 0 ? (tugasSelesai / totalTugas) : 1.0;

    // Jika statusnya selesai, kita pastikan persenProgress visual di-set ke 100%
    if (statusServis == 'Selesai') {
      persenProgress = 1.0;
      tugasSelesai = totalTugas;
    }

    // Warna status
    Color warnaStatus = Colors.green.shade800;
    Color warnaStatusBg = Colors.green.shade50;
    if (statusServis != 'Selesai') {
      warnaStatus = Colors.blue.shade800;
      warnaStatusBg = Colors.blue.shade50;
    }

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          title: const Text("Detail Riwayat Servis", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          centerTitle: true,
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          elevation: 0.5,
          bottom: TabBar(
            labelColor: Colors.blue.shade800,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.blue.shade800,
            indicatorWeight: 3,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            tabs: const [
              Tab(text: "Progres"),
              Tab(text: "Detail SPK"),
              Tab(text: "Biaya"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // TAB 1: PROGRES LIVE (RIWAYAT)
            SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSpkHeaderCard(noSpk, tanggal, waktuMasuk, statusServis, warnaStatus, warnaStatusBg, estimasi),
                  const SizedBox(height: 14),
                  _buildProgressCard(tugasSelesai, totalTugas, persenProgress, listPekerjaan),
                ],
              ),
            ),

            // TAB 2: DETAIL SPK
            SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildVehicleMekanikCard(kendaraan, plat, km, estimasi, namaMontir),
                  const SizedBox(height: 14),
                  _buildKeluhanLayananCard(keluhan, jenisServisStr),
                ],
              ),
            ),

            // TAB 3: SPAREPART & BIAYA
            SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildJasaServisCostCard(listServis, biayaJasa, hargaPerFlexible),
                  const SizedBox(height: 14),
                  _buildSparepartsCard(spareparts),
                  const SizedBox(height: 14),
                  _buildBillingCard(biayaJasa, totalHargaSparepart),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpkHeaderCard(
    String noSpk, 
    String tanggal, 
    String waktuMasuk, 
    String statusServis, 
    Color warnaStatus, 
    Color warnaStatusBg,
    String estimasi
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "No. SPK: $noSpk",
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, letterSpacing: 0.5),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Check-in: $tanggal, $waktuMasuk",
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: warnaStatusBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  statusServis.toString().toUpperCase(),
                  style: TextStyle(
                    color: warnaStatus, 
                    fontWeight: FontWeight.bold, 
                    fontSize: 10,
                  ),
                ),
              )
            ],
          ),
          const Divider(height: 20, thickness: 0.8),
          Row(
            children: [
              Icon(Icons.hourglass_bottom, color: Colors.blue.shade700, size: 16),
              const SizedBox(width: 8),
              Text(
                "Total Estimasi Waktu: ",
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              Text(
                _formatEstimasi(estimasi),
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressCard(
    int tugasSelesai, 
    int totalTugas, 
    double persenProgress, 
    List<Map<String, dynamic>> listPekerjaan
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.donut_large_rounded, color: Colors.blue, size: 20),
              SizedBox(width: 8),
              Text(
                "Progres Pengerjaan",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ],
          ),
          const Divider(height: 24, thickness: 1),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "$tugasSelesai dari $totalTugas Tugas Selesai",
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              Text(
                "${(persenProgress * 100).toInt()}%",
                style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: persenProgress,
              backgroundColor: Colors.grey.shade100,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 20),

          if (listPekerjaan.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Text("Belum ada rincian pekerjaan.", style: TextStyle(color: Colors.grey, fontSize: 13)),
              ),
            )
          else
            ...listPekerjaan.map((item) {
              // Di halaman riwayat/arsip, semua pengerjaan dianggap Selesai secara default visual jika status utama SPK sudah Selesai
              
              Color iconColor = Colors.green;
              IconData iconData = Icons.check_circle;
              
              final String name = item['nama'] ?? '-';
              final String estimasiPerItem = item['estimasi']?.toString() ?? (_jenisServisDanEstimasi[name] ?? 0).toString();
              
              String statusText = "Selesai dikerjakan";
              if (estimasiPerItem.isNotEmpty && estimasiPerItem != '0') {
                statusText += " • Durasi: ${_formatEstimasi(estimasiPerItem)}";
              }

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.green.shade200,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(iconData, color: iconColor, size: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: Colors.green.shade900,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            statusText,
                            style: TextStyle(
                              color: Colors.green.shade700, 
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildVehicleMekanikCard(
    String kendaraan, 
    String plat, 
    String km, 
    String estimasi, 
    String namaMontir
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.directions_car, color: Colors.blue, size: 20),
              SizedBox(width: 8),
              Text(
                "Informasi Kendaraan & Mekanik",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ],
          ),
          const Divider(height: 24, thickness: 1),
          
          Row(
            children: [
              Expanded(
                child: _buildInfoItem("Kendaraan", kendaraan),
              ),
              Expanded(
                child: _buildInfoItem("No. Plat", plat.toUpperCase()),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          Row(
            children: [
              Expanded(
                child: _buildInfoItem("Kilometer (KM)", "$km km"),
              ),
              Expanded(
                child: _buildInfoItem("Total Durasi", _formatEstimasi(estimasi)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          _buildInfoItem("Mekanik Bertugas", namaMontir, isFullWidth: true),
        ],
      ),
    );
  }

  Widget _buildKeluhanLayananCard(String keluhan, String jenisServis) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.assignment_late_outlined, color: Colors.blue, size: 20),
              SizedBox(width: 8),
              Text(
                "Keluhan & Layanan Terdaftar",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ],
          ),
          const Divider(height: 24, thickness: 1),
          
          _buildInfoItem("Keluhan Pelanggan", keluhan, isFullWidth: true),
          const SizedBox(height: 12),
          _buildInfoItem("Paket / Jenis Servis", jenisServis, isFullWidth: true),
        ],
      ),
    );
  }

  Widget _buildJasaServisCostCard(List<String> listServis, int biayaJasa, int hargaPerFlexible) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.engineering, color: Colors.blue, size: 20),
              SizedBox(width: 8),
              Text(
                "Rincian Jasa Perawatan",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ],
          ),
          const Divider(height: 24, thickness: 1),
          
          if (listServis.isEmpty)
            const Text("-", style: TextStyle(fontSize: 13))
          else
            ...listServis.map((namaServis) {
              final int hargaLookup = _jenisServisDanHarga[namaServis] ?? 0;
              final bool isFlexible = hargaLookup == 0;
              
              int hargaTampil = 0;
              String hargaText = "Fleksibel";
              Color warnaHarga = Colors.orange.shade800;

              if (!isFlexible) {
                hargaTampil = hargaLookup;
                hargaText = _formatRupiah(hargaTampil);
                warnaHarga = Colors.black87;
              } else if (hargaPerFlexible > 0) {
                hargaTampil = hargaPerFlexible;
                hargaText = _formatRupiah(hargaTampil);
                warnaHarga = Colors.black87;
              }
              
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        namaServis,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                    Text(
                      hargaText,
                      style: TextStyle(
                        fontWeight: FontWeight.bold, 
                        fontSize: 13,
                        color: warnaHarga,
                      ),
                    ),
                  ],
                ),
              );
            }),
          const Divider(height: 24, thickness: 1),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Total Biaya Jasa",
                style: TextStyle(color: Colors.black54, fontSize: 13, fontWeight: FontWeight.bold),
              ),
              Text(
                biayaJasa > 0 ? _formatRupiah(biayaJasa) : "Fleksibel",
                style: const TextStyle(
                  color: Colors.blue, 
                  fontSize: 14, 
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSparepartsCard(List<dynamic> spareparts) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.build, color: Colors.blue, size: 20),
              SizedBox(width: 8),
              Text(
                "Suku Cadang / Sparepart Terpasang",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ],
          ),
          const Divider(height: 24, thickness: 1),
          
          if (spareparts.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Column(
                  children: [
                    Icon(Icons.build_outlined, color: Colors.grey, size: 36),
                    SizedBox(height: 8),
                    Text(
                      "Belum ada suku cadang terpasang.",
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ],
                ),
              ),
            )
          else
            ...spareparts.map((item) {
              final int harga = int.tryParse(item['harga_jual_saat_itu'].toString()) ?? 0;
              final int jumlah = item['jumlah'] as int? ?? 1;
              final int subtotal = harga * jumlah;

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['nama'] ?? '-',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "Qty: $jumlah x ${_formatRupiah(harga)}",
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      _formatRupiah(subtotal),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildBillingCard(int biayaJasa, int totalHargaSparepart) {
    final int totalSemua = biayaJasa + totalHargaSparepart;
    
    if (totalSemua <= 0) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: const Center(
          child: Text(
            "Tidak ada rincian biaya pengerjaan.",
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.receipt_long, color: Colors.blue, size: 20),
              SizedBox(width: 8),
              Text(
                "Rincian Estimasi Biaya",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ],
          ),
          const Divider(height: 24, thickness: 1),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Estimasi Biaya Jasa", style: TextStyle(color: Colors.black54, fontSize: 13)),
              Text(_formatRupiah(biayaJasa), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Estimasi Suku Cadang", style: TextStyle(color: Colors.black54, fontSize: 13)),
              Text(_formatRupiah(totalHargaSparepart), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            ],
          ),
          const Divider(height: 24, thickness: 1),
          
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade900,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Total Estimasi Biaya",
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                ),
                Text(
                  _formatRupiah(totalSemua),
                  style: const TextStyle(
                    color: Colors.white, 
                    fontSize: 16, 
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Row(
            children: [
              Icon(Icons.info_outline, color: Colors.orange, size: 14),
              SizedBox(width: 6),
              Expanded(
                child: Text(
                  "Estimasi biaya sementara. Total akhir jasa & suku cadang akan dikalkulasi lengkap saat penyerahan kendaraan.",
                  style: TextStyle(color: Colors.black54, fontSize: 10, height: 1.3),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, {bool isFullWidth = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87),
        ),
      ],
    );
  }
}