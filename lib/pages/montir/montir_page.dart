import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'tambah_montir_page.dart';

class MontirPage extends StatefulWidget {
  final Function(String) onHistoryClick; // ✅ DIUBAH: dari VoidCallback ke Function(String)

  const MontirPage({super.key, required this.onHistoryClick});

  @override
  State<MontirPage> createState() => _MontirPageState();
}

class _MontirPageState extends State<MontirPage> {
  String searchQuery = "";

  int currentPage = 1;
  int rowsPerPage = 5;

  // WARNA STATUS
  Color statusColor(String status) {
    if (status == "Aktif") return Colors.green;
    if (status == "Libur") return Colors.orange;
    return Colors.red;
  }

  Color statusBg(String status) {
    if (status == "Aktif") return Colors.green.shade100;
    if (status == "Libur") return Colors.orange.shade100;
    return Colors.red.shade100;
  }

  // HAPUS DATA
  Future<void> hapusData(String id, String nama) async {
    final konfirmasi = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Hapus Data Montir"),
        content: Text(
          'Yakin ingin menghapus "$nama"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Hapus"),
          ),
        ],
      ),
    );

    if (konfirmasi == true) {
      await FirebaseFirestore.instance.collection('montir').doc(id).delete();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Data montir "$nama" berhasil dihapus'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  // INPUT (UNTUK EDIT)
  Widget buildInput(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label),
          const SizedBox(height: 5),
          TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: label,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // EDIT DATA
  void editData(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    final nama = TextEditingController(text: data['nama']);
    final telp = TextEditingController(text: data['telp']);
    final spesialis = TextEditingController(text: data['spesialis']);

    String selectedStatus = data['status'] ?? "Aktif";

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Container(
                width: 500,
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [

                    // HEADER
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Edit Data Montir",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(dialogContext),
                          icon: const Icon(Icons.close),
                        )
                      ],
                    ),

                    const SizedBox(height: 20),

                    buildInput("Nama Lengkap Montir *", nama),
                    buildInput("Nomor Telepon *", telp),
                    buildInput("Spesialisasi *", spesialis),

                    // STATUS
                    Padding(
                      padding: const EdgeInsets.only(bottom: 15),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Status Montir *"),
                          const SizedBox(height: 5),
                          DropdownButtonFormField<String>(
                            initialValue: selectedStatus,
                            items: ["Aktif", "Libur", "Tidak Aktif"]
                                .map((status) => DropdownMenuItem(
                                      value: status,
                                      child: Text(status),
                                    ))
                                .toList(),
                            onChanged: (value) {
                              setStateDialog(() {
                                selectedStatus = value!;
                              });
                            },
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () => Navigator.pop(dialogContext),
                          child: const Text("Batal"),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () async {
                            final navigator = Navigator.of(dialogContext);

                            await FirebaseFirestore.instance
                                .collection('montir')
                                .doc(doc.id)
                                .update({
                              'nama': nama.text,
                              'telp': telp.text,
                              'spesialis': spesialis.text,
                              'status': selectedStatus,
                            });

                            if (!mounted) return;

                            navigator.pop();
                          },
                          icon: const Icon(Icons.save),
                          label: const Text("Update"),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('montir')
          .orderBy('created_at', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final semuaData = snapshot.data!.docs;

        // ================= FILTER SEARCH =================
        final filteredData = semuaData.where((doc) {
          final d = doc.data() as Map<String, dynamic>;
          final nama = (d['nama'] ?? '').toString().toLowerCase();
          final spesialis = (d['spesialis'] ?? '').toString().toLowerCase();
          final telp = (d['telp'] ?? '').toString().toLowerCase();
          return nama.contains(searchQuery) ||
              spesialis.contains(searchQuery) ||
              telp.contains(searchQuery);
        }).toList();

        // ================= PAGINATION =================
        final totalData = filteredData.length;
        int start = (currentPage - 1) * rowsPerPage;
        if (start >= totalData && totalData > 0) {
          start = 0;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            setState(() => currentPage = 1);
          });
        }
        final end = (start + rowsPerPage).clamp(0, totalData);
        final paginatedData =
            totalData == 0 ? <DocumentSnapshot>[] : filteredData.sublist(start, end);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            const Text(
              "Data Montir",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 20),

            // ================= SEARCH + TOMBOL =================
            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: "Cari montir...",
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        searchQuery = value.toLowerCase();
                        currentPage = 1;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 20),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (_) => const TambahMontirPage(),
                    );
                  },
                  icon: const Icon(Icons.person_add),
                  label: const Text("Tambah Montir"),
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
                child: Column(
                  children: [

                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          if (filteredData.isEmpty) {
                            return const Center(
                              child: Text(
                                "Belum ada data montir",
                                style: TextStyle(color: Colors.grey),
                              ),
                            );
                          }

                          return SingleChildScrollView(
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  minWidth: constraints.maxWidth,
                                ),
                                child: DataTable(
                                  border: TableBorder.all(
                                    color: Colors.grey.shade400,
                                  ),
                                  columnSpacing: 25,
                                  headingRowColor: WidgetStateProperty.all(
                                    Colors.grey.shade300,
                                  ),
                                  columns: const [
                                    DataColumn(label: Text("NO")),
                                    DataColumn(label: Text("NAMA MONTIR")),
                                    DataColumn(label: Text("SPESIALISASI")),
                                    DataColumn(label: Text("NOMOR TELEPON")),
                                    DataColumn(label: Text("STATUS")),
                                    DataColumn(label: Text("AKSI")),
                                  ],
                                  rows: paginatedData.asMap().entries.map((entry) {
                                    final index = entry.key;
                                    final doc = entry.value;
                                    final d = doc.data() as Map<String, dynamic>;

                                    return DataRow(cells: [
                                      DataCell(Text("${start + index + 1}")),
                                      DataCell(Text(d['nama'] ?? '')),
                                      DataCell(Text(d['spesialis'] ?? '')),
                                      DataCell(Text(d['telp'] ?? '')),

                                      // STATUS BADGE
                                      DataCell(
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: statusBg(d['status'] ?? ''),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            d['status'] ?? '',
                                            style: TextStyle(
                                              color: statusColor(d['status'] ?? ''),
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),

                                      // AKSI
                                      DataCell(
                                        Row(
                                          children: [

                                            GestureDetector(
                                              onTap: () => editData(doc),
                                              child: Container(
                                                padding: const EdgeInsets.all(6),
                                                decoration: BoxDecoration(
                                                  color: Colors.blue.shade100,
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: const Icon(
                                                  Icons.edit,
                                                  size: 16,
                                                  color: Colors.blue,
                                                ),
                                              ),
                                            ),

                                            const SizedBox(width: 6),

                                            GestureDetector(
                                              onTap: () => hapusData(doc.id, d['nama'] ?? ''),
                                              child: Container(
                                                padding: const EdgeInsets.all(6),
                                                decoration: BoxDecoration(
                                                  color: Colors.red.shade100,
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: const Icon(
                                                  Icons.delete,
                                                  size: 16,
                                                  color: Colors.red,
                                                ),
                                              ),
                                            ),

                                            const SizedBox(width: 6),

                                            InkWell(
                                              onTap: () => widget.onHistoryClick(d['nama'] ?? ''), // ✅ DIUBAH: kirim nama montir
                                              borderRadius: BorderRadius.circular(6),
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 10,
                                                  vertical: 6,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFF2E7D32),
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: const Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Icon(
                                                      Icons.history,
                                                      size: 16,
                                                      color: Colors.white,
                                                    ),
                                                    SizedBox(width: 5),
                                                    Text(
                                                      "History",
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                        fontWeight: FontWeight.w600,
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ]);
                                  }).toList(),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 10),

                    // ================= PAGINATION =================
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back),
                          onPressed: currentPage > 1
                              ? () => setState(() => currentPage--)
                              : null,
                        ),
                        Text("Halaman $currentPage"),
                        IconButton(
                          icon: const Icon(Icons.arrow_forward),
                          onPressed: (currentPage * rowsPerPage) < totalData
                              ? () => setState(() => currentPage++)
                              : null,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}