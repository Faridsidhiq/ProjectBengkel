import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:intl/intl.dart';
import '../pelanggan/pelanggan_page.dart';
import '../montir/montir_page.dart';
import '../sparepart/sparepart_page.dart';
import '../spk/spk_page.dart';
import '../servis/servis_page.dart';
import '../keluhan/keluhan_page.dart';
import '../laporan/laporan_page.dart';
import '../auth/logout_page.dart';
import '../montir/history_montir_page.dart';
import '../manajemen_akun/manajemen_akun_page.dart';
import '../profile/profile_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class _WebScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
      };
}

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  String selectedMenu = "dashboard";
  String selectedMontirNama = "";

  @override
  Widget build(BuildContext context) {
    bool isMobile = MediaQuery.of(context).size.width < 800;

    return Scaffold(
      appBar: isMobile
          ? AppBar(
              title: Text(getTitle()),
              backgroundColor: Colors.white,
              iconTheme: const IconThemeData(color: Colors.black),
              actions: [
                GestureDetector(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => const ProfilePage(),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: Colors.blue.shade100,
                          child: const Icon(Icons.person, color: Colors.blue, size: 16),
                        ),
                      ],
                    ),
                  ),
                )
              ],
            )
          : null,
      drawer: isMobile ? Drawer(child: _buildSidebar()) : null,
      body: Row(
        children: [
          // SIDEBAR
          if (!isMobile) _buildSidebar(),

          // CONTENT
          Expanded(
            child: Column(
              children: [
                // HEADER (Desktop only)
                if (!isMobile)
                  Container(
                    height: 70,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    color: Colors.white,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          getTitle(),
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        // PROFILE
                        GestureDetector(
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (context) => const ProfilePage(),
                            );
                          },
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 22,
                                backgroundColor: Colors.blue.shade100,
                                child: const Icon(
                                  Icons.person,
                                  color: Colors.blue,
                                ),
                              ),
                              const SizedBox(width: 10),
                              const Text(
                                "admin",
                                style: TextStyle(fontSize: 18),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                // PAGE CONTENT
                Expanded(
                  child: Container(
                    padding: EdgeInsets.all(isMobile ? 10 : 20),
                    color: Colors.grey[100],
                    child: buildContent(),
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 250,
      color: Colors.grey[200],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),

          // LOGO
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                Image.asset(
                  'assets/logo.png',
                  width: 100,
                ),
                const SizedBox(height: 10),
                const Text(
                  "JIMU MITSUBISHI",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 30),

          menuItem(Icons.dashboard, "Dashboard", "dashboard"),
          menuItem(Icons.people, "Data Pelanggan", "pelanggan"),
          menuItem(Icons.build, "Data Montir", "montir"),
          menuItem(Icons.settings, "Data Sparepart", "sparepart"),
          menuItem(Icons.description, "SPK", "spk"),
          menuItem(Icons.note, "Servis", "servis"),
          menuItem(Icons.warning, "Keluhan", "keluhan"),
          menuItem(Icons.bar_chart, "Laporan", "laporan"),
          menuItem(Icons.account_box, "Manajemen Akun", "manajemen_akun"),

          const Spacer(),

          Padding(
            padding: const EdgeInsets.all(20),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (context) => const LogoutPage(),
                  );
                },
                icon: const Icon(Icons.logout),
                label: const Text("Logout"),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget menuItem(IconData icon, String title, String keyMenu) {
    bool active = selectedMenu == keyMenu;

    return Container(
      color: active ? Colors.blue[800] : Colors.transparent,
      child: ListTile(
        leading: Icon(icon, color: active ? Colors.white : Colors.black),
        title: Text(
          title,
          style: TextStyle(color: active ? Colors.white : Colors.black),
        ),
        onTap: () {
          setState(() {
            selectedMenu = keyMenu;
          });
          if (MediaQuery.of(context).size.width < 800) {
            Navigator.pop(context);
          }
        },
      ),
    );
  }

  Widget buildContent() {
    if (selectedMenu == "pelanggan") {
      return const PelangganPage();
    } else if (selectedMenu == "montir") {
      return MontirPage(
        onHistoryClick: (namaMontir) {
          setState(() {
            selectedMontirNama = namaMontir;
            selectedMenu = "history";
          });
        },
      );
    } else if (selectedMenu == "history") {
      return HistoryMontirPage(
        namaMontir: selectedMontirNama,
        onBack: () {
          setState(() {
            selectedMenu = "montir";
          });
        },
      );
    } else if (selectedMenu == "sparepart") {
      return const SparepartPage();
    } else if (selectedMenu == "spk") {
      return const SpkPage();
    } else if (selectedMenu == "servis") {
      return const ServisPage();
    } else if (selectedMenu == "keluhan") {
      return const KeluhanPage();
    } else if (selectedMenu == "laporan") {
      return const LaporanPage();
    } else if (selectedMenu == "manajemen_akun") {
      return const ManajemenAkunPage();
    }

    return dashboardContent();
  }

  // ============================================================
  // DASHBOARD CONTENT
  // ============================================================
  Widget dashboardContent() {
    bool isWide = MediaQuery.of(context).size.width >= 1100;

    return ScrollConfiguration(
      behavior: _WebScrollBehavior(),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ================= 1. STAT CARDS UTAMA =================
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                // PELANGGAN
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('pelanggan')
                      .snapshots(),
                  builder: (context, snapshot) {
                    int total = snapshot.data?.docs.length ?? 0;
                    return statCard(
                      "Data Pelanggan",
                      total.toString(),
                      Colors.blue,
                      Icons.people,
                      onTap: () => setState(() => selectedMenu = "pelanggan"),
                    );
                  },
                ),

                // MONTIR
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('montir')
                      .snapshots(),
                  builder: (context, snapshot) {
                    int total = snapshot.data?.docs.length ?? 0;
                    return statCard(
                      "Data Montir",
                      total.toString(),
                      Colors.orange,
                      Icons.build,
                      onTap: () => setState(() => selectedMenu = "montir"),
                    );
                  },
                ),

                // SPAREPART
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('sparepart')
                      .snapshots(),
                  builder: (context, snapshot) {
                    int total = snapshot.data?.docs.length ?? 0;
                    return statCard(
                      "Data Sparepart",
                      total.toString(),
                      Colors.indigo,
                      Icons.inventory,
                      onTap: () => setState(() => selectedMenu = "sparepart"),
                    );
                  },
                ),

                // TOTAL SPK
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('spk')
                      .snapshots(),
                  builder: (context, snapshot) {
                    int total = snapshot.data?.docs.length ?? 0;
                    return statCard(
                      "Total SPK",
                      total.toString(),
                      Colors.teal,
                      Icons.description,
                      onTap: () => setState(() => selectedMenu = "spk"),
                    );
                  },
                ),

                // KELUHAN
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('keluhan')
                      .snapshots(),
                  builder: (context, snapshot) {
                    int total = snapshot.data?.docs.length ?? 0;
                    return statCard(
                      "Keluhan Pelanggan",
                      total.toString(),
                      Colors.red,
                      Icons.warning,
                      onTap: () => setState(() => selectedMenu = "keluhan"),
                    );
                  },
                ),
              ],
            ),

            const SizedBox(height: 24),

            // ================= 2. STATUS PEKERJAAN SPK OVERVIEW =================
            _buildStatusPekerjaanOverview(),

            const SizedBox(height: 24),

            // ================= 3. GRAFIK SERVIS & SPAREPART MENIPIS/HABIS =================
            if (isWide)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 3, child: _buildGrafikServisCard()),
                  const SizedBox(width: 20),
                  Expanded(flex: 2, child: _buildSparepartMenipisCard()),
                ],
              )
            else
              Column(
                children: [
                  _buildGrafikServisCard(),
                  const SizedBox(height: 20),
                  _buildSparepartMenipisCard(),
                ],
              ),

            const SizedBox(height: 24),

            // ================= 4. TABEL PEKERJAAN BERLANGSUNG =================
            _buildTabelPekerjaanBerlangsung(),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // WIDGET STATUS PEKERJAAN OVERVIEW (Menunggu, Berlangsung, Selesai)
  // ============================================================
  Widget _buildStatusPekerjaanOverview() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('spk').snapshots(),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];

        int menungguCount = 0;
        int berlangsungCount = 0;
        int selesaiCount = 0;

        for (var doc in docs) {
          final data = doc.data() as Map<String, dynamic>;
          final status = (data['status'] ?? '').toString().trim().toLowerCase();
          if (status == 'menunggu') {
            menungguCount++;
          } else if (status == 'proses' || status == 'berlangsung' || status == 'berjalan' || status == 'sedang proses') {
            berlangsungCount++;
          } else if (status == 'selesai') {
            selesaiCount++;
          }
        }

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 6,
                offset: Offset(0, 3),
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.engineering, color: Colors.blue, size: 22),
                  SizedBox(width: 8),
                  Text(
                    "Status Pekerjaan Bengkel",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              LayoutBuilder(
                builder: (context, constraints) {
                  bool isSmall = constraints.maxWidth < 600;
                  return isSmall
                      ? Column(
                          children: [
                            _statusPekerjaanCard("Menunggu", menungguCount, Colors.orange, Icons.hourglass_top, onTap: () => setState(() => selectedMenu = "spk")),
                            const SizedBox(height: 10),
                            _statusPekerjaanCard("Berlangsung / Proses", berlangsungCount, Colors.blue, Icons.autorenew, onTap: () => setState(() => selectedMenu = "spk")),
                            const SizedBox(height: 10),
                            _statusPekerjaanCard("Selesai", selesaiCount, Colors.green, Icons.check_circle_outline, onTap: () => setState(() => selectedMenu = "spk")),
                          ],
                        )
                      : Row(
                          children: [
                            Expanded(child: _statusPekerjaanCard("Menunggu", menungguCount, Colors.orange, Icons.hourglass_top, onTap: () => setState(() => selectedMenu = "spk"))),
                            const SizedBox(width: 12),
                            Expanded(child: _statusPekerjaanCard("Berlangsung / Proses", berlangsungCount, Colors.blue, Icons.autorenew, onTap: () => setState(() => selectedMenu = "spk"))),
                            const SizedBox(width: 12),
                            Expanded(child: _statusPekerjaanCard("Selesai", selesaiCount, Colors.green, Icons.check_circle_outline, onTap: () => setState(() => selectedMenu = "spk"))),
                          ],
                        );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _statusPekerjaanCard(String title, int count, Color color, IconData icon, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "$count Pekerjaan",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // WIDGET GRAFIK SERVIS PER BULAN
  // ============================================================
  Widget _buildGrafikServisCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
            offset: Offset(0, 3),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.bar_chart, color: Colors.indigo, size: 22),
                  SizedBox(width: 8),
                  Text(
                    "Grafik Jumlah Servis Per Bulan",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.indigo.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  "${DateTime.now().year}",
                  style: TextStyle(
                    color: Colors.indigo.shade700,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // STREAM BUILDER SERVIS
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('servis').snapshots(),
            builder: (context, snapshotServis) {
              return StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('spk').snapshots(),
                builder: (context, snapshotSpk) {
                  // Hitung jumlah servis per bulan (1..12)
                  List<int> monthlyCount = List.filled(12, 0);

                  final servisDocs = snapshotServis.data?.docs ?? [];
                  final spkDocs = snapshotSpk.data?.docs ?? [];

                  void processDoc(Map<String, dynamic> data) {
                    DateTime? dt;
                    if (data['created_at'] != null) {
                      if (data['created_at'] is Timestamp) {
                        dt = (data['created_at'] as Timestamp).toDate();
                      } else if (data['created_at'] is String) {
                        dt = DateTime.tryParse(data['created_at']);
                      }
                    } else if (data['tanggal'] != null && data['tanggal'] is String) {
                      try {
                        dt = DateFormat('dd/MM/yyyy').parse(data['tanggal']);
                      } catch (_) {
                        dt = DateTime.tryParse(data['tanggal']);
                      }
                    }

                    if (dt != null && dt.year == DateTime.now().year) {
                      monthlyCount[dt.month - 1]++;
                    }
                  }

                  for (var doc in servisDocs) {
                    processDoc(doc.data() as Map<String, dynamic>);
                  }

                  // Jika data servis masih sedikit, tambahkan dari SPK yang selesai
                  if (servisDocs.isEmpty) {
                    for (var doc in spkDocs) {
                      final data = doc.data() as Map<String, dynamic>;
                      if (data['status'] == 'Selesai') {
                        processDoc(data);
                      }
                    }
                  }

                  int maxVal = monthlyCount.reduce((a, b) => a > b ? a : b);
                  if (maxVal < 5) maxVal = 5;

                  const months = [
                    "Jan", "Feb", "Mar", "Apr", "Mei", "Jun",
                    "Jul", "Agu", "Sep", "Okt", "Nov", "Des"
                  ];

                  return SizedBox(
                    height: 200,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: List.generate(12, (index) {
                        int val = monthlyCount[index];
                        double heightFactor = val / maxVal;

                        return Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(
                                val > 0 ? "$val" : "",
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.indigo,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Tooltip(
                                message: "${months[index]}: $val Servis",
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 500),
                                  width: 18,
                                  height: 130 * heightFactor,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.indigo.shade400,
                                        Colors.blue.shade600,
                                      ],
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                    ),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                months[index],
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade700,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  // ============================================================
  // WIDGET INFORMASI SPAREPART MENIPIS ATAU HABIS
  // ============================================================
  Widget _buildSparepartMenipisCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
            offset: Offset(0, 3),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(Icons.warning_amber_rounded, color: Colors.red.shade700, size: 20),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  "Sparepart Menipis / Habis",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('sparepart').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final allDocs = snapshot.data?.docs ?? [];
              final lowStockDocs = allDocs.where((doc) {
                final d = doc.data() as Map<String, dynamic>;
                int stok = d['stok'] ?? 0;
                int minStok = d['min_stok'] ?? 0;
                return stok <= minStok;
              }).toList();

              // Urutkan yang stok == 0 paling atas
              lowStockDocs.sort((a, b) {
                int aStok = (a.data() as Map<String, dynamic>)['stok'] ?? 0;
                int bStok = (b.data() as Map<String, dynamic>)['stok'] ?? 0;
                return aStok.compareTo(bStok);
              });

              if (lowStockDocs.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          "Semua stok sparepart aman!",
                          style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }

              return SizedBox(
                height: 195,
                child: ScrollConfiguration(
                  behavior: _WebScrollBehavior(),
                  child: Scrollbar(
                    thumbVisibility: true,
                    child: ListView.separated(
                      itemCount: lowStockDocs.length,
                      separatorBuilder: (context, index) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final d = lowStockDocs[index].data() as Map<String, dynamic>;
                        int stok = d['stok'] ?? 0;
                        int minStok = d['min_stok'] ?? 0;
                        bool isHabis = stok == 0;

                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          leading: CircleAvatar(
                            backgroundColor: isHabis ? Colors.red.shade100 : Colors.orange.shade100,
                            child: Icon(
                              isHabis ? Icons.remove_shopping_cart : Icons.inventory_2,
                              color: isHabis ? Colors.red : Colors.orange,
                              size: 18,
                            ),
                          ),
                          title: Text(
                            d['nama'] ?? '-',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            "Kode: ${d['kode'] ?? '-'} | Min: $minStok",
                            style: const TextStyle(fontSize: 11),
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: isHabis ? Colors.red.shade100 : Colors.orange.shade100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              isHabis ? "Habis (0)" : "Sisa ($stok)",
                              style: TextStyle(
                                color: isHabis ? Colors.red.shade700 : Colors.orange.shade800,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ============================================================
  // WIDGET TABEL PEKERJAAN BERLANGSUNG (LENGKAP KOLOM STATUS)
  // ============================================================
  Widget _buildTabelPekerjaanBerlangsung() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
            offset: Offset(0, 3),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.build_circle, color: Colors.blue, size: 22),
                  SizedBox(width: 8),
                  Text(
                    "Daftar Pekerjaan Berlangsung & Menunggu",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    selectedMenu = "spk";
                  });
                },
                icon: const Icon(Icons.arrow_forward, size: 16),
                label: const Text("Lihat Semua SPK"),
              ),
            ],
          ),
          const SizedBox(height: 12),

          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('spk')
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    "Terjadi kesalahan: ${snapshot.error}",
                    style: const TextStyle(color: Colors.red),
                  ),
                );
              }

              // Filter client side: tampilkan yang BUKAN "Selesai"
              final allDocs = snapshot.data?.docs ?? [];
              final docs = allDocs.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return data['status'] != 'Selesai';
              }).toList();

              if (docs.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(30),
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle_outline,
                            size: 50, color: Colors.green),
                        SizedBox(height: 12),
                        Text(
                          "Semua pekerjaan SPK sudah selesai!",
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return LayoutBuilder(
                builder: (context, constraints) {
                  return ScrollConfiguration(
                    behavior: _WebScrollBehavior(),
                    child: Scrollbar(
                      thumbVisibility: true,
                      trackVisibility: true,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                              minWidth: constraints.maxWidth),
                          child: DataTable(
                            border: TableBorder.all(
                              color: Colors.grey.shade300,
                            ),
                            columnSpacing: 20,
                            headingRowHeight: 45,
                            dataRowMinHeight: 50,
                            dataRowMaxHeight: 55,
                            headingRowColor: WidgetStateProperty.all(
                                Colors.grey.shade200),
                            headingTextStyle: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: Colors.black87,
                            ),
                            columns: const [
                              DataColumn(label: Text("NO")),
                              DataColumn(label: Text("NO SPK")),
                              DataColumn(label: Text("TANGGAL")),
                              DataColumn(label: Text("NO PLAT")),
                              DataColumn(label: Text("NAMA PELANGGAN")),
                              DataColumn(label: Text("KENDARAAN")),
                              DataColumn(label: Text("MONTIR")),
                              DataColumn(label: Text("STATUS PEKERJAAN")),
                            ],
                            rows: List.generate(docs.length, (index) {
                              final data = docs[index].data()
                                  as Map<String, dynamic>;

                              final status =
                                  (data['status'] ?? 'Menunggu').toString();

                              // Formatting tanggal
                              String tglFormatted = "-";
                              if (data['created_at'] != null) {
                                if (data['created_at'] is Timestamp) {
                                  tglFormatted = DateFormat('dd/MM/yyyy HH:mm')
                                      .format((data['created_at'] as Timestamp).toDate());
                                } else {
                                  tglFormatted = data['created_at'].toString();
                                }
                              } else if (data['tanggal'] != null) {
                                tglFormatted = data['tanggal'].toString();
                              }

                              // Warna badge status pekerjaan
                              Color badgeBg;
                              Color badgeTextColor;
                              IconData statusIcon;

                              if (status == 'Menunggu') {
                                badgeBg = Colors.orange.shade100;
                                badgeTextColor = Colors.orange.shade900;
                                statusIcon = Icons.hourglass_empty;
                              } else if (status == 'Proses' || status == 'Berlangsung') {
                                badgeBg = Colors.blue.shade100;
                                badgeTextColor = Colors.blue.shade900;
                                statusIcon = Icons.autorenew;
                              } else {
                                badgeBg = Colors.green.shade100;
                                badgeTextColor = Colors.green.shade900;
                                statusIcon = Icons.check_circle;
                              }

                              return DataRow(cells: [
                                DataCell(Text("${index + 1}")),
                                DataCell(
                                  Text(
                                    data['no_spk'] ?? '-',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue,
                                    ),
                                  ),
                                ),
                                DataCell(Text(tglFormatted, style: const TextStyle(fontSize: 12))),
                                DataCell(Text(data['plat'] ?? '-')),
                                DataCell(Text(data['nama_pelanggan'] ?? '-')),
                                DataCell(Text(data['kendaraan'] ?? '-')),
                                DataCell(Text(data['nama_montir'] ?? '-')),
                                DataCell(
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: badgeBg,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(statusIcon, size: 13, color: badgeTextColor),
                                        const SizedBox(width: 4),
                                        Text(
                                          status,
                                          style: TextStyle(
                                            color: badgeTextColor,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ]);
                            }),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  String getTitle() {
    if (selectedMenu == "pelanggan") return "Data Pelanggan";
    if (selectedMenu == "montir") return "Data Montir";
    if (selectedMenu == "history") return "History Montir";
    if (selectedMenu == "sparepart") return "Data Sparepart";
    if (selectedMenu == "spk") return "Data SPK";
    if (selectedMenu == "servis") return "Pencatatan Data Servis";
    if (selectedMenu == "keluhan") return "Keluhan Pelanggan";
    if (selectedMenu == "laporan") return "Laporan Bengkel";
    if (selectedMenu == "manajemen_akun") return "Manajemen Akun";
    return "Dashboard Admin";
  }

  Widget statCard(String title, String value, Color color, IconData icon, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 200,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 6,
              offset: Offset(0, 3),
            )
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}