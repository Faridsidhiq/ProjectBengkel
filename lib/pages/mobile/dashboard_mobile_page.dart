import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; 
import 'package:intl/intl.dart'; 
import 'package:url_launcher/url_launcher.dart';
import 'keluhan_mobile_page.dart'; 
import 'akun_mobile_page.dart';
import 'detail_perawatan_page.dart';
import 'semua_perawatan_page.dart';
import 'katalog_barang_page.dart'; 
import 'simulasi_biaya_page.dart';
import 'notifikasi_mobile_page.dart';
import 'tracking_pelanggan_page.dart';

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
      "icon": Icons.ac_unit, 
      "title": "Service AC Mobil",
      "image": "assets/manual.png",
      "deskripsi": "Perawatan sistem pendingin kabin mobil agar tetap dingin, bersih, dan bebas bakteri.",
      "estimasi": "1 - 3 Jam",
      "garansi": "Tersedia",
      "interval": "Tiap 20.000 Km / 1 Tahun",
      "harga": "Rp150.000 - Rp350.000 (Jasa)",
      "pekerjaan": [
        "Pembersihan Evaporator dan Kondensor.",
        "Cek tekanan dan isi ulang freon (refrigerant).",
        "Penggantian filter AC kabin.",
        "Deteksi kebocoran selang AC."
      ]
    },
    {
      "icon": Icons.directions_car, 
      "title": "Spooring & Balancing",
      "image": "assets/manual.png",
      "deskripsi": "Penyelarasan sudut roda kemudi agar stabil dan lurus serta menyeimbangkan bobot ban.",
      "estimasi": "1 Jam",
      "garansi": "Tersedia (2 Minggu)",
      "interval": "Tiap 10.000 Km",
      "harga": "Rp150.000 - Rp250.000 (Jasa & Alat)",
      "pekerjaan": [
        "Penyesuaian sudut Camber, Caster, dan Toe.",
        "Pemasangan timah penyeimbang roda.",
        "Pengecekan keausan permukaan tapak ban."
      ]
    },
    {
      "icon": Icons.format_paint, 
      "title": "Body Repair & Detailing",
      "image": "assets/manual.png",
      "deskripsi": "Perbaikan body mobil penyok/gores serta detailing cat luar agar kembali mengkilap.",
      "estimasi": "Tergantung Kerusakan",
      "garansi": "Tersedia",
      "interval": "Sesuai Kebutuhan",
      "harga": "Fleksibel (Sesuai Kerusakan)",
      "pekerjaan": [
        "Perataan body penyok (ketok magic / panel repair).",
        "Pengecatan ulang per panel atau seluruh body.",
        "Polishing body luar, pembersihan jamur kaca, dan interior detailing."
      ]
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
        child: GestureDetector(
          onTap: () {
            FocusScope.of(context).unfocus();
          },
          behavior: HitTestBehavior.translucent,
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
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
            FocusScope.of(context).unfocus();
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
                        FocusScope.of(context).unfocus();
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
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) {
                    FocusScope.of(context).unfocus();
                  },
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



              // ================= LIVE TRACKING / STATUS SERVIS BANNER =================
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('spk')
                    .where('email', isEqualTo: user?.email)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return _buildLacakServisBanner(context);
                  }

                  // Urutkan SPK secara lokal berdasarkan waktu_dibuat descending
                  final docs = snapshot.data!.docs.toList();
                  docs.sort((a, b) {
                    final dataA = a.data() as Map<String, dynamic>;
                    final dataB = b.data() as Map<String, dynamic>;
                    final tA = dataA['waktu_dibuat'] as Timestamp?;
                    final tB = dataB['waktu_dibuat'] as Timestamp?;
                    if (tA == null && tB == null) return 0;
                    if (tA == null) return 1;
                    if (tB == null) return -1;
                    return tB.compareTo(tA);
                  });

                  final doc = docs.first;
                  final docData = doc.data() as Map<String, dynamic>;
                  final statusServis = docData['status'] ?? 'Menunggu';
                  final isHidden = docData['is_hidden'] == true;

                  if (statusServis != 'Selesai') {
                    // Jika status pengerjaan belum selesai, tampilkan card progress aktif
                    return _buildActiveServiceCard(context, docData);
                  } else if (statusServis == 'Selesai' && !isHidden) {
                    // Jika status selesai tapi belum disembunyikan
                    return _buildCompletedServiceCard(context, doc.id, docData);
                  } else {
                    // Jika tidak ada pengerjaan aktif/sudah disembunyikan, tampilkan banner netral biasa
                    return _buildLacakServisBanner(context);
                  }
                },
              ),

              const SizedBox(height: 10),

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
                              FocusScope.of(context).unfocus();
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
                      FocusScope.of(context).unfocus();
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

                    final allDocs = snapshot.data!.docs;
                    // Tampilkan maksimal 5 item saja di dashboard
                    final docs = allDocs.take(5).toList();

                    return ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      itemCount: docs.length + 1,
                      itemBuilder: (context, index) {
                        if (index == docs.length) {
                          return InkWell(
                            onTap: () {
                              FocusScope.of(context).unfocus();
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const KatalogBarangPage()),
                              );
                            },
                            child: Container(
                              width: 130,
                              margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(15),
                                border: Border.all(color: Colors.blue.shade300, width: 1.5), 
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  CircleAvatar(
                                    backgroundColor: Colors.blue.shade100,
                                    child: Icon(Icons.arrow_forward, color: Colors.blue.shade800),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    "Lihat Semua",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 12, 
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue.shade800,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "Katalog Barang",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.blue.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }

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
                              InkWell(
                                onTap: () async {
                                  final Uri url = Uri.parse("https://wa.me/6285269864232");
                                  if (await canLaunchUrl(url)) {
                                    await launchUrl(url, mode: LaunchMode.externalApplication);
                                  } else {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text("Tidak dapat membuka WhatsApp")),
                                      );
                                    }
                                  }
                                },
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(Icons.phone_android, color: Colors.blue.shade700, size: 14),
                                    const SizedBox(width: 4),
                                    const Expanded(
                                      child: Text(
                                        "0852-6986-4232\n(WhatsApp Chat)",
                                        style: TextStyle(
                                          color: Colors.blue,
                                          decoration: TextDecoration.underline,
                                          fontSize: 11,
                                          height: 1.4,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
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
    ),

      // ================= BOTTOM NAVIGATION =================
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0, 
        selectedItemColor: Colors.blue.shade800,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          FocusScope.of(context).unfocus();
          if (index == 1) {
            Navigator.push(
              context, 
              MaterialPageRoute(builder: (_) => SimulasiBiayaPage(daftarLayanan: semuaLayanan)),
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
          BottomNavigationBarItem(icon: Icon(Icons.calculate), label: "Estimasi"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Akun"),
        ],
      ),
    );
  }

  Widget _buildLacakServisBanner(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const TrackingPelangganPage()),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade200,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.airport_shuttle_rounded, color: Colors.blue.shade800, size: 24),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Lacak Proses Servis",
                    style: TextStyle(
                      color: Colors.black87,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    "Periksa status pengerjaan mobil Anda secara real-time",
                    style: TextStyle(
                      color: Colors.black54,
                      fontSize: 11,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: Colors.grey.shade400, size: 14),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveServiceCard(BuildContext context, Map<String, dynamic> docData) {
    final statusServis = docData['status'] ?? 'Menunggu';
    final namaKendaraan = docData['kendaraan'] ?? 'Mobil Saya';
    final namaMontir = docData['nama_montir'] ?? 'Menunggu mekanik';
    
    // Checklist
    List<Map<String, dynamic>> listPekerjaan = [];
    if (docData['items'] != null) {
      listPekerjaan = List<Map<String, dynamic>>.from(docData['items']);
    }
    
    int totalTugas = listPekerjaan.length;
    int tugasSelesai = listPekerjaan.where((item) => item['status'] == 'Selesai').length;
    double persenProgress = totalTugas > 0 ? (tugasSelesai / totalTugas) : 0.0;
    

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const TrackingPelangganPage()),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade900, Colors.blue.shade800],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.shade900.withOpacity(0.3),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.insights, color: Colors.greenAccent, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      "SERVIS SEDANG BERJALAN",
                      style: TextStyle(
                        color: Colors.greenAccent.shade100,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    statusServis.toString().toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white, 
                      fontWeight: FontWeight.bold, 
                      fontSize: 9,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              namaKendaraan,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "Montir: $namaMontir",
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "$tugasSelesai dari $totalTugas Tugas Selesai",
                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                ),
                Text(
                  "${(persenProgress * 100).toInt()}%",
                  style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: persenProgress,
                backgroundColor: Colors.white12,
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.amber),
                minHeight: 6,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sembunyikanDariDashboard(String docId) async {
    try {
      await FirebaseFirestore.instance
          .collection('spk')
          .doc(docId)
          .update({'is_hidden': true});
    } catch (e) {
      debugPrint("Gagal menyembunyikan SPK: $e");
    }
  }

  Widget _buildCompletedServiceCard(BuildContext context, String docId, Map<String, dynamic> docData) {
    final namaKendaraan = docData['kendaraan'] ?? 'Mobil Saya';
    final plat = docData['plat'] ?? '-';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade800, Colors.green.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.green.shade900.withOpacity(0.3),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.check_circle_outline, color: Colors.greenAccent, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    "SERVIS SELESAI 🎉",
                    style: TextStyle(
                      color: Colors.greenAccent.shade100,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () => _sembunyikanDariDashboard(docId),
                child: const Icon(Icons.close, color: Colors.white70, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            "$namaKendaraan (${plat.toString().toUpperCase()})",
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            "Kendaraan Anda telah selesai diperbaiki dan siap diambil. Silakan menuju kasir untuk administrasi.",
            style: TextStyle(
              color: Colors.white70,
              fontSize: 11,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => _sembunyikanDariDashboard(docId),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white70,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
                child: const Text(
                  "Sembunyikan", 
                  style: TextStyle(fontSize: 12),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () {
                  FocusScope.of(context).unfocus();
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const TrackingPelangganPage()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.green.shade800,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
                child: const Text(
                  "Lacak Detail",
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

