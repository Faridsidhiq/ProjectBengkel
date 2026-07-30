import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'detail_keluhan_page.dart';

class _WebScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
      };
}

class KeluhanPage extends StatefulWidget {
  const KeluhanPage({super.key});

  @override
  State<KeluhanPage> createState() => _KeluhanPageState();
}

class _KeluhanPageState extends State<KeluhanPage> {
  bool isDetailKeluhan = false;
  DocumentSnapshot? selectedKeluhan;

  String keyword = '';
  String filterStatus = 'Semua';

  int _statusOrder(String status) {
    if (status == 'Menunggu') return 0;
    if (status == 'Sedang Proses') return 1;
    if (status == 'Selesai') return 2;
    return 3;
  }

  Color statusColor(String status) {
    if (status == 'Menunggu') return Colors.orange;
    if (status == 'Sedang Proses') return Colors.blue;
    return Colors.green;
  }

  Color statusBg(String status) {
    if (status == 'Menunggu') return Colors.orange.shade100;
    if (status == 'Sedang Proses') return Colors.blue.shade100;
    return Colors.green.shade100;
  }

  @override
  Widget build(BuildContext context) {
    if (isDetailKeluhan && selectedKeluhan != null) {
      return DetailKeluhanPage(
        keluhanDoc: selectedKeluhan!,
        onBack: () => setState(() {
          isDetailKeluhan = false;
          selectedKeluhan = null;
        }),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('keluhan')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final allDocs = snapshot.data!.docs;

        // ===== HITUNG STAT (dari semua data, bukan yang difilter) =====
        final belumDitangani = allDocs
            .where((d) =>
                (d.data() as Map<String, dynamic>)['status'] == 'Menunggu')
            .length;
        final sedangProses = allDocs
            .where((d) =>
                (d.data() as Map<String, dynamic>)['status'] == 'Sedang Proses')
            .length;
        final selesai = allDocs
            .where((d) =>
                (d.data() as Map<String, dynamic>)['status'] == 'Selesai')
            .length;

        // ===== FILTER =====
        final filtered = allDocs.where((doc) {
          final d = doc.data() as Map<String, dynamic>;
          final nama = (d['nama'] ?? '').toString().toLowerCase();
          final email = (d['email'] ?? '').toString().toLowerCase();
          final judul = (d['judul'] ?? '').toString().toLowerCase();
          final status = (d['status'] ?? '').toString();

          final cocokKeyword = nama.contains(keyword) ||
              email.contains(keyword) ||
              judul.contains(keyword);
          final cocokStatus =
              filterStatus == 'Semua' || status == filterStatus;

          return cocokKeyword && cocokStatus;
        }).toList();

        // ===== SORT: Menunggu → Sedang Proses → Selesai, terbaru di atas =====
        filtered.sort((a, b) {
          final aData = a.data() as Map<String, dynamic>;
          final bData = b.data() as Map<String, dynamic>;
          final aOrder = _statusOrder(aData['status'] ?? '');
          final bOrder = _statusOrder(bData['status'] ?? '');
          if (aOrder != bOrder) return aOrder.compareTo(bOrder);
          final aTime = aData['created_at'];
          final bTime = bData['created_at'];
          if (aTime != null && bTime != null) {
            return bTime.compareTo(aTime);
          }
          return 0;
        });

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ================= JUDUL =================
            const Text(
              'Keluhan Pelanggan',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('Kelola dan pantau seluruh keluhan pelanggan'),
            const SizedBox(height: 16),

            // ================= STAT CARDS — SELALU DI ATAS =================
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                _statCard('Belum Ditangani', belumDitangani.toString(),
                    Colors.orange, Icons.schedule),
                _statCard('Sedang Proses', sedangProses.toString(),
                    Colors.blue, Icons.settings),
                _statCard('Selesai', selesai.toString(),
                    Colors.green, Icons.check_circle),
              ],
            ),

            const SizedBox(height: 16),

            // ================= SEARCH =================
            Row(
              children: [
                Expanded(
                  child: TextField(
                    onChanged: (value) =>
                        setState(() => keyword = value.toLowerCase()),
                    decoration: InputDecoration(
                      hintText: 'Cari nama, email, atau judul keluhan...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // ================= FILTER STATUS =================
            Row(
              children: [
                const Icon(Icons.filter_list, size: 16, color: Colors.grey),
                const SizedBox(width: 6),
                const Text('Filter Status:',
                    style: TextStyle(fontSize: 13, color: Colors.grey)),
                const SizedBox(width: 10),
                _buildFilterDropdown(
                  value: filterStatus,
                  items: const [
                    'Semua',
                    'Menunggu',
                    'Sedang Proses',
                    'Selesai',
                  ],
                  onChanged: (val) => setState(() => filterStatus = val!),
                ),
                const SizedBox(width: 10),
                if (filterStatus != 'Semua' || keyword.isNotEmpty)
                  TextButton.icon(
                    onPressed: () => setState(() {
                      filterStatus = 'Semua';
                      keyword = '';
                    }),
                    icon: const Icon(Icons.close, size: 14, color: Colors.red),
                    label: const Text('Reset',
                        style: TextStyle(color: Colors.red, fontSize: 13)),
                    style: TextButton.styleFrom(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 8)),
                  ),
              ],
            ),

            const SizedBox(height: 12),

            // ================= TABLE =================
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade400),
                ),
                child: filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.search_off,
                                size: 48, color: Colors.grey.shade400),
                            const SizedBox(height: 10),
                            Text(
                              allDocs.isEmpty
                                  ? 'Belum ada keluhan masuk'
                                  : 'Tidak ada data yang cocok',
                              style:
                                  TextStyle(color: Colors.grey.shade500),
                            ),
                            const SizedBox(height: 6),
                            if (filterStatus != 'Semua' ||
                                keyword.isNotEmpty)
                              TextButton(
                                onPressed: () => setState(() {
                                  filterStatus = 'Semua';
                                  keyword = '';
                                }),
                                child: const Text('Reset Filter'),
                              ),
                          ],
                        ),
                      )
                    : LayoutBuilder(
                        builder: (context, constraints) {
                          return ScrollConfiguration(
                            behavior: _WebScrollBehavior(),
                            child: Scrollbar(
                              thumbVisibility: true,
                              trackVisibility: true,
                              child: SingleChildScrollView(
                                scrollDirection: Axis.vertical,
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: ConstrainedBox(
                                    constraints: BoxConstraints(
                                      minWidth: constraints.maxWidth,
                                    ),
                                    child: DataTable(
                                      border: TableBorder.all(
                                          color: Colors.grey.shade400),
                                      columnSpacing: 24,
                                      headingRowHeight: 45,
                                      dataRowMinHeight: 60,
                                      dataRowMaxHeight: 60,
                                      headingRowColor:
                                          WidgetStateProperty.all(
                                              Colors.grey.shade300),
                                      headingTextStyle: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                      columns: const [
                                        DataColumn(label: Text('NO')),
                                        DataColumn(label: Text('NAMA')),
                                        DataColumn(label: Text('EMAIL')),
                                        DataColumn(
                                            label: Text('JUDUL KELUHAN')),
                                        DataColumn(
                                            label: Text('ISI KELUHAN')),
                                        DataColumn(label: Text('STATUS')),
                                        DataColumn(label: Text('AKSI')),
                                      ],
                                      rows: filtered
                                          .asMap()
                                          .entries
                                          .map((entry) {
                                        final index = entry.key;
                                        final doc = entry.value;
                                        final d = doc.data()
                                            as Map<String, dynamic>;
                                        final status =
                                            d['status'] ?? 'Menunggu';

                                        return DataRow(cells: [
                                          DataCell(Text('${index + 1}')),

                                          DataCell(Text(
                                            d['nama'] ?? '',
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 1,
                                          )),

                                          DataCell(Text(
                                            d['email'] ?? '',
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 1,
                                          )),

                                          DataCell(Text(
                                            d['judul'] ?? '',
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 1,
                                          )),

                                          DataCell(Text(
                                            d['keluhan'] ??
                                                d['isi'] ??
                                                d['pesan'] ??
                                                '-',
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 1,
                                            style: const TextStyle(
                                                color: Colors.black54),
                                          )),

                                          DataCell(Container(
                                            padding:
                                                const EdgeInsets.symmetric(
                                                    horizontal: 10,
                                                    vertical: 4),
                                            decoration: BoxDecoration(
                                              color: statusBg(status),
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            child: Text(
                                              status,
                                              style: TextStyle(
                                                color: statusColor(status),
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                              ),
                                            ),
                                          )),

                                          DataCell(GestureDetector(
                                            onTap: () => setState(() {
                                              selectedKeluhan = doc;
                                              isDetailKeluhan = true;
                                            }),
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                      vertical: 6),
                                              decoration: BoxDecoration(
                                                color: Colors.indigo,
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                              ),
                                              child: const Row(
                                                mainAxisSize:
                                                    MainAxisSize.min,
                                                children: [
                                                  Icon(Icons.visibility,
                                                      size: 14,
                                                      color: Colors.white),
                                                  SizedBox(width: 5),
                                                  Text(
                                                    'Detail',
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          )),
                                        ]);
                                      }).toList(),
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

  // ================= STAT CARD =================
  Widget _statCard(String title, String value, Color color, IconData icon) {
    return Container(
      width: 200,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [
          BoxShadow(
              color: Colors.black12, blurRadius: 6, offset: Offset(0, 3)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title,
                  style:
                      const TextStyle(fontSize: 12, color: Colors.black54)),
              Text(value,
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  // ================= FILTER DROPDOWN =================
  Widget _buildFilterDropdown({
    required String value,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    final isActive = value != 'Semua';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        color: isActive ? Colors.blue.shade50 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isActive ? Colors.blue : Colors.grey.shade300,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isDense: true,
          style: TextStyle(
            fontSize: 13,
            color: isActive ? Colors.blue.shade700 : Colors.black87,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
          icon: Icon(
            Icons.keyboard_arrow_down,
            size: 16,
            color: isActive ? Colors.blue : Colors.grey,
          ),
          items: items
              .map((item) =>
                  DropdownMenuItem(value: item, child: Text(item)))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}