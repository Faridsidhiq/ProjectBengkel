import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; 
import 'package:intl/intl.dart'; 
import 'keluhan_mobile_page.dart'; 
import 'servis_mobile_page.dart'; 
import 'akun_mobile_page.dart';
import 'detail_perawatan_page.dart';
import 'semua_perawatan_page.dart';
import 'katalog_barang_page.dart'; 
import 'notifikasi_mobile_page.dart';

class DashboardMobilePage extends StatefulWidget {
  const DashboardMobilePage({super.key});

  @override
  State<DashboardMobilePage> createState() => _DashboardMobilePageState();
}

class _DashboardMobilePageState extends State<DashboardMobilePage> {
  final TextEditingController _searchLayananController = TextEditingController();
  String _keywordLayanan = "";

  String _getGambarKategori(String kategori) {
    return "assets/shell_yellow.png"; 
  }

  // ====================================================================
  // DATABASE SEMUA LAYANAN (Disembunyikan jika tidak ditekan "Lainnya")
  // ====================================================================
  final List<Map<String, dynamic>> semuaLayanan = [
    {
      "icon": Icons.build_circle, 
      "title": "Tune Up & Scanning",
      "image": "assets/tuneup.png", 
      "deskripsi": "Tune Up adalah proses standarisasi kembali kondisi mesin kendaraan Anda agar tetap prima. Meliputi penyetelan, pembersihan, dan diagnosa ECU.",
      "estimasi": "Tergantung Kondisi",
      "garansi": "Tersedia",
      "interval": "Sesuai Kebutuhan",
      "harga": "Rp200.000 (Hanya Jasa)",
      "pekerjaan": [
        "Periksa / setel klep (Valve clearance).",
        "Periksa / ganti busi, coil.",
        "Periksa kondisi aki (accu), tambah air aki.",
        "Periksa / bersihkan / ganti filter udara dan filter BBM.",
        "Periksa / setel / ganti fan belt, AC belt, power steering belt.",
        "Periksa / tambah minyak rem, minyak kopling, minyak power steering.",
        "Periksa kondisi dan jumlah oli mesin.",
        "Periksa / tambah air radiator, air wiper.",
        "Periksa fungsi & kondisi lampu-lampu.",
        "Pembersihan throttle body.",
        "Periksa fungsi sensor, actuator, ECU via scanner (scanning system)."
      ]
    },
    {
      "icon": Icons.oil_barrel, 
      "title": "Ganti Oli & Filter",
      "image": "assets/ganti_oli.png",
      "deskripsi": "Layanan penggantian oli mesin secara berkala guna menjaga komponen dalam mesin tetap terlumasi dengan baik.",
      "estimasi": "30 - 45 Menit",
      "garansi": "Saran Penggantian Berikutnya",
      "interval": "Tiap 5.000 Km - 10.000 Km",
      "harga": "Rp60.000 (Jasa)",
      "pekerjaan": [
        "Ganti Oli dan Filter Oli (sesuai tipe kendaraan atau request customer)."
      ]
    },
    {
      "icon": Icons.settings, 
      "title": "Service Rem 4 Roda",
      "image": "assets/servis_rem.png",
      "deskripsi": "Pemeriksaan dan perawatan sistem pengereman demi keselamatan berkendara yang optimal.",
      "estimasi": "1 - 2 Jam",
      "garansi": "Tersedia",
      "interval": "Pengecekan Berkala",
      "harga": "Rp200.000 - Rp400.000 (Jasa)",
      "pekerjaan": [
        "Periksa / bersihkan / ganti kanvas rem.",
        "Periksa / ganti blok rem (brake wheel cylinder).",
        "Periksa / ganti sentral rem (brake master cylinder).",
        "Periksa / ganti minyak rem."
      ]
    },
    {
      "icon": Icons.car_repair, 
      "title": "Service Kaki-kaki",
      "image": "assets/manual.png",
      "deskripsi": "Perawatan sistem suspensi dan kemudi untuk kenyamanan dan kestabilan laju kendaraan.",
      "estimasi": "Sesuai Kerusakan",
      "garansi": "Tersedia",
      "interval": "Saat Terasa Tidak Stabil",
      "harga": "Fleksibel (Sesuai Kerusakan)",
      "pekerjaan": [
        "Periksa / ganti tie rod, rack end, ball joint, shock absorber, bushing-bushing.",
        "Periksa / ganti ban atau roda.",
        "Tire rotation (Rotasi Ban)."
      ]
    },
    {
      "icon": Icons.electrical_services, 
      "title": "Electrical System",
      "image": "assets/manual.png",
      "deskripsi": "Pengecekan dan perbaikan jalur kelistrikan, lampu, serta sistem pengisian daya aki.",
      "estimasi": "Sesuai Kerusakan",
      "garansi": "Tersedia",
      "interval": "-",
      "harga": "Fleksibel (Sesuai Kerusakan)",
      "pekerjaan": [
        "Periksa / ganti lampu-lampu bagian luar atau dalam kendaraan.",
        "Periksa / perbaikan / ganti dinamo starter (starting system).",
        "Periksa / perbaikan / ganti dinamo charge (charging system).",
        "Periksa / perbaikan wiring harness (perkabelan)."
      ]
    },
    {
      "icon": Icons.miscellaneous_services, 
      "title": "Service Kopling",
      "image": "assets/manual.png",
      "deskripsi": "Perbaikan dan pergantian komponen transmisi manual (Kopling) agar perpindahan gigi kembali halus.",
      "estimasi": "Sesuai Pengerjaan",
      "garansi": "Tersedia",
      "interval": "Saat Kopling Selip",
      "harga": "Rp450.000 (Jasa)",
      "pekerjaan": [
        "Periksa / ganti prodo kopling (clutch disc).",
        "Periksa / ganti matahari kopling (clutch cover).",
        "Periksa / ganti klaher kopling (clutch release bearing).",
        "Periksa kabel / seling kopling.",
        "Periksa sentral kopling bawah (power clutch).",
        "Periksa sentral kopling atas (master clutch).",
        "Periksa / tambah minyak kopling."
      ]
    },
    {
      "icon": Icons.build, 
      "title": "Ganti Timing Belt",
      "image": "assets/manual.png",
      "deskripsi": "Pergantian sabuk timing secara berkala untuk mencegah kerusakan fatal pada komponen internal mesin.",
      "estimasi": "Sesuai Pengerjaan",
      "garansi": "Tersedia",
      "interval": "Tiap 80.000 - 100.000 Km",
      "harga": "Rp300.000 - Rp450.000 (Tergantung Tipe)",
      "pekerjaan": [
        "Ganti timing belt.",
        "Periksa / ganti klaher timing belt.",
        "Periksa / ganti automatic adjuster timing belt.",
        "Periksa / ganti fan belt, AC belt, power steering belt."
      ]
    },
    {
      "icon": Icons.handyman, 
      "title": "Overhaul Mesin",
      "image": "assets/manual.png",
      "deskripsi": "Turun mesin total untuk membersihkan, memeriksa, dan mengganti komponen internal dan eksternal mesin yang rusak.",
      "estimasi": "Berapa Hari",
      "garansi": "Tersedia",
      "interval": "-",
      "harga": "Rp2.500.000 - Rp4.500.000 (Jasa)",
      "pekerjaan": [
        "Periksa / bersihkan / ganti semua komponen bagian dalam mesin.",
        "Periksa / bersihkan / ganti semua komponen bagian luar mesin."
      ]
    },
    {
      "icon": Icons.settings_applications, 
      "title": "Overhaul Transmisi (M)",
      "image": "assets/manual.png",
      "deskripsi": "Bongkar total transmisi manual untuk perbaikan gigi, sinkromes, dan komponen lainnya.",
      "estimasi": "Beberapa Hari",
      "garansi": "Tersedia",
      "interval": "-",
      "harga": "Rp1.500.000 (Jasa)",
      "pekerjaan": [
        "Periksa / bersihkan / ganti semua komponen bagian dalam manual transmisi.",
        "Periksa / bersihkan / ganti semua komponen bagian luar manual transmisi."
      ]
    },
    {
      "icon": Icons.settings_system_daydream, 
      "title": "Overhaul Transmisi (A)",
      "image": "assets/manual.png",
      "deskripsi": "Bongkar total transmisi otomatis (Matic) untuk perbaikan kampas matic, valve body, dan seal.",
      "estimasi": "Beberapa Hari",
      "garansi": "Tersedia",
      "interval": "-",
      "harga": "Rp2.500.000 (Jasa)",
      "pekerjaan": [
        "Periksa / bersihkan / ganti semua komponen bagian dalam automatic transmisi.",
        "Periksa / bersihkan / ganti semua komponen bagian luar automatic transmisi."
      ]
    },
    {
      "icon": Icons.settings_suggest, 
      "title": "Overhaul Gardan",
      "image": "assets/manual.png",
      "deskripsi": "Perbaikan komponen penggerak roda belakang (Differential/Gardan).",
      "estimasi": "Sesuai Pengerjaan",
      "garansi": "Tersedia",
      "interval": "-",
      "harga": "Rp750.000 (Jasa)",
      "pekerjaan": [
        "Periksa / bersihkan / ganti semua komponen bagian dalam gardan.",
        "Periksa / bersihkan / ganti semua komponen bagian luar gardan."
      ]
    },
    {
      "icon": Icons.calendar_month, 
      "title": "Booking Servis",
      "image": "assets/booking.png",
      "deskripsi": "Fitur penjadwalan servis instan untuk menghindari antrean panjang di bengkel.",
      "estimasi": "Instan", "garansi": "-", "interval": "-", "harga": "Tanpa Biaya Tambahan",
      "pekerjaan": ["Pilih hari & jam servis", "Konfirmasi kedatangan"]
    },
    {
      "icon": Icons.history, 
      "title": "Riwayat",
      "image": "assets/history.png",
      "deskripsi": "Melihat riwayat servis yang pernah dilakukan.",
      "estimasi": "-", "garansi": "-", "interval": "-", "harga": "-",
      "pekerjaan": ["Melihat nota", "Mengecek pengerjaan"]
    },
  ];

  @override
  void dispose() {
    _searchLayananController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    // =========================================================
    // LOGIKA FILTER 8 ITEM (2 BARIS) + KELUHAN & LAINNYA
    // =========================================================
    List<Map<String, dynamic>> layananTerfilter = [];

    if (_keywordLayanan.isEmpty) {
      // 1. Ambil 6 Servis Teratas Saja
      layananTerfilter = semuaLayanan.take(6).toList();
      
      // 2. Tambahkan "Keluhan" di posisi ke-7
      layananTerfilter.add({
        "icon": Icons.feedback, 
        "title": "Keluhan",
        "estimasi": "-", "garansi": "-", "interval": "-", "harga": "-", "pekerjaan": []
      });

      // 3. Tambahkan "Lainnya" di posisi ke-8 (Paling Ujung)
      layananTerfilter.add({
        "icon": Icons.more_horiz, 
        "title": "Lainnya",
        "image": "assets/lainnya.png",
        "deskripsi": "Lihat semua layanan perawatan kendaraan yang tersedia di bengkel kami.",
        "estimasi": "-", "garansi": "-", "interval": "-", "harga": "-", "pekerjaan": []
      });
    } else {
      // Jika user sedang mengetik pencarian, tampilkan hasil yang cocok dari semua layanan
      layananTerfilter = semuaLayanan.where((item) {
        final String judulLayanan = item["title"].toString().toLowerCase();
        return judulLayanan.contains(_keywordLayanan);
      }).toList();
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // ================= HEADER =================
              Container(
                margin: const EdgeInsets.all(12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(color: Colors.grey.shade300, blurRadius: 5),
                  ],
                ),
                child: Row(
                  children: [
                    Image.asset(
                      'assets/logo.png',
                      width: 60,
                      height: 60,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(Icons.car_repair, color: Colors.blue, size: 40);
                      },
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "JIMU MITSUBISHI",
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          Text("Bengkel Terbaik", style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    ),
  StreamBuilder<QuerySnapshot>(
  stream: FirebaseFirestore.instance
      .collection('spk')
      .where('email', isEqualTo: FirebaseAuth.instance.currentUser?.email)
      .where('status', isEqualTo: 'Selesai')
      .snapshots(),
  builder: (context, snapshot) {
    bool adaNotifBaru = false;

    if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
      // Cek apakah ada minimal 1 notifikasi yang BELUM dibaca
      adaNotifBaru = snapshot.data!.docs.any((doc) {
        final data = doc.data() as Map<String, dynamic>;
        // Jika field 'notif_dibaca' belum ada atau bernilai false, berarti belum dibaca
        return data['notif_dibaca'] != true; 
      });
    }
    
    return Stack(
      children: [
        IconButton(
          onPressed: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const NotifikasiMobilePage()));
          },
          icon: const Icon(Icons.notifications_active, color: Colors.orange),
        ),
        if (adaNotifBaru)
          Positioned(
            right: 11,
            top: 11,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
            ),
          ),
      ],
    );
  },
),
                    // FITUR BARU: Ikon User bisa diklik dan lompat ke AkunMobilePage
                    InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const AkunMobilePage()),
                        );
                      },
                      borderRadius: BorderRadius.circular(50),
                      child: CircleAvatar(
                        backgroundColor: Colors.orange.shade100,
                        child: const Icon(Icons.person, color: Colors.orange),
                      ),
                    ),
                  ],
                ),
              ),

              // ================= SEARCH BAR =================
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: TextField(
                  controller: _searchLayananController,
                  onChanged: (value) {
                    setState(() {
                      _keywordLayanan = value.toLowerCase();
                    });
                  },
                  decoration: InputDecoration(
                    hintText: "Cari Nama Layanan Perawatan...",
                    prefixIcon: const Icon(Icons.search, color: Colors.blue),
                    suffixIcon: _searchLayananController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: Colors.grey),
                            onPressed: () {
                              setState(() {
                                _searchLayananController.clear();
                                _keywordLayanan = "";
                              });
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // ================= JUDUL LAYANAN =================
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Jenis Perawatan dan Estimasi Biaya",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // ================= GRID MENU LAYANAN (Dibatasi 2 Baris) =================
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: layananTerfilter.isEmpty
                    ? const Card(
                        color: Colors.white,
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Center(
                            child: Text(
                              "Layanan menu tidak ditemukan",
                              style: TextStyle(color: Colors.grey, fontSize: 13),
                            ),
                          ),
                        ),
                      )
                    : GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: layananTerfilter.length,
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                          childAspectRatio: 0.85, 
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                        ),
                        itemBuilder: (context, index) {
                          return InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () {
                              final title = layananTerfilter[index]["title"];
                              
                              if (title == "Keluhan") {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const KeluhanMobilePage()),
                                );
                              } 
                              else if (title == "Lainnya") {
                                // Membawa master data semuaLayanan ke halaman SemuaPerawatanPage
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => SemuaPerawatanPage(daftarLayanan: semuaLayanan),
                                  ),
                                );
                              }
                              else {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => DetailPerawatanPage(dataLayanan: layananTerfilter[index]),
                                  ),
                                );
                              }
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    layananTerfilter[index]["icon"],
                                    color: Colors.blue,
                                    size: 28,
                                  ),
                                  const SizedBox(height: 5),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 2),
                                    child: Text(
                                      layananTerfilter[index]["title"],
                                      textAlign: TextAlign.center,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 10, height: 1.1),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),

              const SizedBox(height: 20),

              // ================= KATALOG BARANG =================
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const KatalogBarangPage()),
                      );
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          "Katalog Barang",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(width: 5),
                        Icon(Icons.arrow_forward, color: Colors.blue.shade800, size: 20),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // ================= HORIZONTAL LIST DATA FIREBASE =================
              SizedBox(
                height: 190, 
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('sparepart').snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Center(
                        child: Text(
                          "Belum ada produk dari admin",
                          style: TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                      );
                    }

                    final docs = snapshot.data!.docs;

                    return ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        final data = docs[index].data() as Map<String, dynamic>;
                        
                        String kategoriBarang = data['kategori'] ?? "Oli & Cairan";
                        String namaBarang = data['nama'] ?? "-";
                        
                        int hargaJual = 0;
                        if (data['harga_jual'] != null) {
                          hargaJual = (data['harga_jual'] is String)
                              ? int.tryParse(data['harga_jual']) ?? 0
                              : (data['harga_jual'] as num).toInt();
                        }
                        
                        String? urlGambar = data['foto_url'];

                        final formatRupiah = NumberFormat.currency(
                          locale: 'id_ID', 
                          symbol: 'Rp ', 
                          decimalDigits: 0,
                        );

                        return Container(
                          width: 130,
                          margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(color: Colors.blue, width: 1.5), 
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Expanded(
                                child: urlGambar != null && urlGambar.isNotEmpty && urlGambar.startsWith('http')
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(10),
                                        child: Image.network(
                                          urlGambar,
                                          fit: BoxFit.cover, 
                                          loadingBuilder: (context, child, loadingProgress) {
                                            if (loadingProgress == null) return child;
                                            return const Center(
                                              child: SizedBox(
                                                width: 20,
                                                height: 20,
                                                child: CircularProgressIndicator(strokeWidth: 2),
                                              ),
                                            );
                                          },
                                          errorBuilder: (context, error, stackTrace) {
                                            return Icon(Icons.broken_image, size: 40, color: Colors.red.shade300);
                                          },
                                        ),
                                      )
                                    : Image.asset(
                                        _getGambarKategori(kategoriBarang), 
                                        fit: BoxFit.contain,
                                        errorBuilder: (context, error, stackTrace) {
                                          return const Icon(Icons.oil_barrel, size: 40, color: Colors.orange);
                                        },
                                      ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                namaBarang,
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                formatRupiah.format(hargaJual),
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.black),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),

              const SizedBox(height: 25),

              // ================= KONTEN INFORMASI BENGKEL =================
              Container(
                width: double.infinity,
                margin: const EdgeInsets.all(12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white, 
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(color: Colors.grey.shade300, blurRadius: 5),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 5,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "ALAMAT BENGKEL",
                                style: TextStyle(
                                  color: Colors.blue.shade800, 
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                "Jl. P. Damar gg Wijaya Kusuma No.10, Way Dadi, Kec. Sukarame, Kota Bandar Lampung, Lampung 35131",
                                style: TextStyle(color: Colors.black87, fontSize: 11, height: 1.4),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 4,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "HUBUNGI KAMI",
                                style: TextStyle(
                                  color: Colors.blue.shade800, 
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(Icons.phone_android, color: Colors.blue.shade700, size: 14),
                                  const SizedBox(width: 4),
                                  const Expanded(
                                    child: Text(
                                      "0852-6986-4232\n(WhatsApp Chat)",
                                      style: TextStyle(color: Colors.black87, fontSize: 11, height: 1.4),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 20),
                    Divider(color: Colors.grey.shade200, height: 1),
                    const SizedBox(height: 12),

                    Center(
                      child: Column(
                        children: [
                          const Text(
                            "© 2026 PT Karya Baik Bersama, Indonesia",
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey, fontSize: 10),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "Login sebagai: ${user?.email ?? 'Pengguna'}",
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey.shade400, fontSize: 9),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 15),
            ],
          ),
        ),
      ),

      // ================= BOTTOM NAVIGATION =================
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0, 
        selectedItemColor: Colors.blue.shade800,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          if (index == 1) {
            Navigator.push(
              context, 
              MaterialPageRoute(builder: (_) => const ServisMobilePage()),
            );
          } else if (index == 2) {
            Navigator.push(
              context, 
              MaterialPageRoute(builder: (_) => const AkunMobilePage()),
            );
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Beranda"),
          BottomNavigationBarItem(icon: Icon(Icons.build), label: "Servis"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Akun"),
        ],
      ),
    );
  }
}

