import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'tambah_spk_page.dart';
import 'detail_spk_page.dart';

class SpkPage extends StatefulWidget {
  const SpkPage({super.key});

  @override
  State<SpkPage> createState() => _SpkPageState();
}

class _SpkPageState extends State<SpkPage> {

  bool isTambahPage = false;
  bool isDetailPage = false;

  Map<String, dynamic>? selectedSpk;

  final TextEditingController searchController = TextEditingController();

  // ================= SCROLL CONTROLLERS =================
  final ScrollController _verticalController = ScrollController();
  final ScrollController _horizontalController = ScrollController();

  @override
  void dispose() {
    _verticalController.dispose();
    _horizontalController.dispose();
    super.dispose();
  }

  // ================= WARNA STATUS =================

  Color statusColor(String status) {
    if (status == "Menunggu") return Colors.orange;
    if (status == "Proses") return Colors.blue;
    return Colors.green;
  }

  Color statusBg(String status) {
    if (status == "Menunggu") return Colors.orange.shade100;
    if (status == "Proses") return Colors.blue.shade100;
    return Colors.green.shade100;
  }

  // ================= STAT CARD =================

  Widget statCard(
    String title,
    String value,
    Color color,
    IconData icon,
  ) {
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
            child: Icon(icon, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    // ================= HALAMAN TAMBAH =================
    if (isTambahPage) {
      return TambahSpkPage(
        onBack: () => setState(() => isTambahPage = false),
      );
    }

    // ================= HALAMAN DETAIL =================
    if (isDetailPage && selectedSpk != null) {
      return DetailSpkPage(
        spkData: selectedSpk!,
        onBack: () => setState(() {
          isDetailPage = false;
          selectedSpk = null;
        }),
      );
    }

    // ================= HALAMAN UTAMA =================
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('spk')
          .orderBy('created_at', descending: true)
          .snapshots(),

      builder: (context, snapshot) {

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final semuaData = snapshot.data!.docs;

        // ================= HITUNG STATUS =================
        final totalSemua = semuaData.length;
        final totalMenunggu = semuaData.where((d) {
          final s = ((d.data() as Map<String, dynamic>)['status'] ?? '').toString().trim().toLowerCase();
          return s == 'menunggu';
        }).length;
        final totalProses = semuaData.where((d) {
          final s = ((d.data() as Map<String, dynamic>)['status'] ?? '').toString().trim().toLowerCase();
          return s == 'proses' || s == 'berlangsung' || s == 'berjalan' || s == 'sedang proses';
        }).length;
        final totalSelesai = semuaData.where((d) {
          final s = ((d.data() as Map<String, dynamic>)['status'] ?? '').toString().trim().toLowerCase();
          return s == 'selesai';
        }).length;

        // ================= FILTER SEARCH =================
        final query = searchController.text.toLowerCase();
        final filteredData = semuaData.where((data) {
          final nama = (data['nama_pelanggan'] ?? '').toString().toLowerCase();
          final plat = (data['plat'] ?? '').toString().toLowerCase();
          final id = data.id.toLowerCase();
          return nama.contains(query) ||
              plat.contains(query) ||
              id.contains(query);
        }).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ================= TITLE =================
            const Text(
              "Data Surat Perintah Kerja (SPK)",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            const Text(
              "Kelola dan pantau seluruh Surat Perintah Kerja bengkel",
            ),

            const SizedBox(height: 20),

            // ================= STAT CARDS =================
            Wrap(
              spacing: 20,
              runSpacing: 20,
              children: [
                statCard(
                  "Semua SPK",
                  "$totalSemua SPK",
                  Colors.purple,
                  Icons.description,
                ),
                statCard(
                  "Menunggu",
                  "$totalMenunggu SPK",
                  Colors.orange,
                  Icons.schedule,
                ),
                statCard(
                  "Berjalan",
                  "$totalProses SPK",
                  Colors.blue,
                  Icons.build,
                ),
                statCard(
                  "Selesai",
                  "$totalSelesai SPK",
                  Colors.green,
                  Icons.check_circle,
                ),
              ],
            ),

            const SizedBox(height: 20),

            // ================= SEARCH + TOMBOL =================
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: searchController,
                    onChanged: (value) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: "Cari No. SPK, nama, atau plat...",
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 18,
                    ),
                  ),
                  onPressed: () => setState(() => isTambahPage = true),
                  icon: const Icon(Icons.add),
                  label: const Text("Tambah SPK Baru"),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // ================= TABEL =================
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade400),
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {

                    // EMPTY STATE
                    if (filteredData.isEmpty) {
                      return const Center(
                        child: Text(
                          "Belum ada data SPK",
                          style: TextStyle(color: Colors.grey),
                        ),
                      );
                    }

                    // ================= SCROLL MOUSE WHEEL =================
                    return Listener(
                      onPointerSignal: (event) {
                      if (event is PointerScrollEvent) {
                        if (event.scrollDelta.dx != 0) {
                          final newOffset = (_horizontalController.offset +
                                  event.scrollDelta.dx)
                              .clamp(
                            0.0,
                            _horizontalController.position.maxScrollExtent,
                          );
                          _horizontalController.jumpTo(newOffset);
                        } else {
                          final newOffset = (_verticalController.offset +
                                  event.scrollDelta.dy)
                              .clamp(
                            0.0,
                            _verticalController.position.maxScrollExtent,
                          );
                          _verticalController.jumpTo(newOffset);
                        }
                      }
                    },
                      child: Scrollbar(
                        controller: _verticalController,
                        thumbVisibility: true,
                        child: Scrollbar(
                          controller: _horizontalController,
                          thumbVisibility: true,
                          notificationPredicate: (notif) => notif.depth == 1,
                          child: SingleChildScrollView(
                            controller: _verticalController,
                            scrollDirection: Axis.vertical,
                            child: SingleChildScrollView(
                              controller: _horizontalController,
                              scrollDirection: Axis.horizontal,
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  minWidth: constraints.maxWidth,
                                ),
                                child: DataTable(
                                  border: TableBorder.all(
                                    color: Colors.grey.shade400,
                                  ),
                                  columnSpacing: 35,
                                  headingRowHeight: 45,
                                  dataRowMinHeight: 55,
                                  dataRowMaxHeight: 65,
                                  headingRowColor: WidgetStateProperty.all(
                                    Colors.grey.shade300,
                                  ),
                                  headingTextStyle: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                  columns: const [
                                    DataColumn(label: Text("TANGGAL")),
                                    DataColumn(label: Text("NO SPK")),
                                    DataColumn(label: Text("NAMA PELANGGAN")),
                                    DataColumn(label: Text("PLAT")),
                                    DataColumn(label: Text("KENDARAAN")),
                                    DataColumn(label: Text("MONTIR")),
                                    DataColumn(label: Text("JENIS SERVIS")),
                                    DataColumn(label: Text("STATUS")),
                                    DataColumn(label: Text("AKSI")),
                                  ],
                                  rows: filteredData.asMap().entries.map((entry) {

                                    final index = entry.key;
                                    final doc = entry.value;
                                    final data = doc.data() as Map<String, dynamic>;

                                    // FORMAT NOMOR SPK
                                    final noSpk =
                                        data['no_spk'] ??
                                        "SPK-${(index + 1).toString().padLeft(4, '0')}";

                                    // FORMAT TANGGAL
                                    String tanggal = "-";
                                    if (data['created_at'] != null) {
                                      final date =
                                          (data['created_at'] as Timestamp).toDate();
                                      tanggal =
                                          "${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}";
                                    }

                                    final status = data['status'] ?? 'Menunggu';

                                    return DataRow(cells: [

                                      DataCell(Text(tanggal)),

                                      DataCell(
                                        Text(
                                          noSpk,
                                          style: const TextStyle(
                                            color: Colors.blue,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),

                                      DataCell(
                                        Text(data['nama_pelanggan'] ?? '-'),
                                      ),

                                      DataCell(Text(data['plat'] ?? '-')),

                                      DataCell(Text(data['kendaraan'] ?? '-')),

                                      DataCell(Text(data['nama_montir'] ?? '-')),

                                      DataCell(
                                        Text(
                                          data['jenis_servis'] is List
                                              ? (data['jenis_servis'] as List).join(', ')
                                              : (data['jenis_servis'] ?? '-').toString(),
                                        ),
                                      ),

                                      // STATUS BADGE
                                      DataCell(
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: statusBg(status),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            status,
                                            style: TextStyle(
                                              color: statusColor(status),
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),

                                      // TOMBOL DETAIL
                                      DataCell(
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.indigo,
                                            foregroundColor: Colors.white,
                                          ),
                                          onPressed: () {
                                            setState(() {
                                              selectedSpk = {
                                                'id': doc.id,
                                                'noSpk': noSpk,
                                                'tanggal': tanggal,
                                                ...data,
                                              };
                                              isDetailPage = true;
                                            });
                                          },
                                          child: const Text("Detail"),
                                        ),
                                      ),
                                    ]);
                                  }).toList(),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}