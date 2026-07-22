import 'package:flutter/material.dart';
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        // STAT CARDS
        Wrap(
          spacing: 20,
          runSpacing: 20,
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
                  "Keluhan",
                  total.toString(),
                  Colors.red,
                  Icons.warning,
                );
              },
            ),
          ],
        ),

        const SizedBox(height: 30),

        // TABEL PEKERJAAN AKTIF
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Daftar Pekerjaan Berlangsung",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),

                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('spk')
                        .snapshots(),
                    builder: (context, snapshot) {

                      // LOADING
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      // ERROR
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

                      // KOSONG
                      if (docs.isEmpty) {
                        return const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.check_circle_outline,
                                  size: 60, color: Colors.green),
                              SizedBox(height: 12),
                              Text(
                                "Semua pekerjaan sudah selesai!",
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      // TABEL
                      return LayoutBuilder(
                        builder: (context, constraints) {
                          return SingleChildScrollView(
                            scrollDirection: Axis.vertical,
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                    minWidth: constraints.maxWidth),
                                child: DataTable(
                                  border: TableBorder.all(
                                    color: Colors.grey.shade400,
                                  ),
                                  columnSpacing: 25,
                                  headingRowHeight: 45,
                                  dataRowMinHeight: 45,
                                  dataRowMaxHeight: 55,
                                  headingRowColor: WidgetStateProperty.all(
                                      Colors.grey.shade300),
                                  headingTextStyle: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                  columns: const [
                                    DataColumn(label: Text("NO")),
                                    DataColumn(label: Text("NO SPK")),
                                    DataColumn(label: Text("NO PLAT")),
                                    DataColumn(label: Text("NAMA PELANGGAN")),
                                    DataColumn(label: Text("KENDARAAN")),
                                    DataColumn(label: Text("MONTIR")),
                                    DataColumn(label: Text("STATUS")),
                                  ],
                                  rows: List.generate(docs.length, (index) {
                                    final data = docs[index].data()
                                        as Map<String, dynamic>;

                                    final status =
                                        (data['status'] ?? '-').toString();

                                    // Warna badge status
                                    Color badgeColor;
                                    if (status == 'Menunggu') {
                                      badgeColor = Colors.orange;
                                    } else if (status == 'Proses') {
                                      badgeColor = Colors.blue;
                                    } else {
                                      badgeColor = const Color.fromARGB(255, 17, 207, 67);
                                    }

                                    return DataRow(cells: [
                                      DataCell(Text("${index + 1}")),
                                      DataCell(Text(data['no_spk'] ?? '-')),
                                      DataCell(Text(data['plat'] ?? '-')),
                                      DataCell(Text(data['nama_pelanggan'] ?? '-')),
                                      DataCell(Text(data['kendaraan'] ?? '-')),
                                      DataCell(Text(data['nama_montir'] ?? '-')),
                                      DataCell(
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: badgeColor,
                                            borderRadius:
                                                BorderRadius.circular(20),
                                          ),
                                          child: Text(
                                            status,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ]);
                                  }),
                                ),
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
          ),
        ),
      ],
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

  Widget statCard(String title, String value, Color color, IconData icon) {
    return Container(
      width: 220,
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
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.white, size: 26),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}