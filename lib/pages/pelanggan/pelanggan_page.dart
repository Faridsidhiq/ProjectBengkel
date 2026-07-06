import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'tambah_pelanggan_page.dart';

class PelangganPage extends StatefulWidget {
  const PelangganPage({super.key});

  @override
  State<PelangganPage> createState() => _PelangganPageState();
}

class _PelangganPageState extends State<PelangganPage> {
  String searchQuery = "";

  int currentPage = 1;
  int rowsPerPage = 5;

  Future<void> hapusData(String id) async {
    await FirebaseFirestore.instance
        .collection('pelanggan')
        .doc(id)
        .delete();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Data berhasil dihapus")),
    );
  }

void editData(DocumentSnapshot doc) {
  final data = doc.data() as Map<String, dynamic>;

  final nama = TextEditingController(text: data['nama']);
  final email = TextEditingController(text: data['email']);
  final telp = TextEditingController(text: data['telepon']);
  final kendaraan = TextEditingController(text: data['kendaraan']);
  final plat = TextEditingController(text: data['plat']);
  final km = TextEditingController(text: data['km']);

  showDialog(
    context: context,
    builder: (dialogContext) {
      final screenHeight = MediaQuery.of(dialogContext).size.height;

      return Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 500,
            maxHeight: screenHeight * 0.9, // 👈 batasi tinggi dialog max 90% layar
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // HEADER
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Edit Pelanggan",
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

                // 👇 SEMUA INPUT DIBUNGKUS SCROLLVIEW BIAR NGGAK OVERFLOW
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        buildInput("Nama Lengkap *", nama),
                        buildInput("Email *", email),
                        buildInput("Nomor Telepon *", telp),
                        buildInput("Nomor Plat *", plat),
                        buildInput("Nama Kendaraan *", kendaraan),
                        buildInput("KM Terakhir *", km),
                      ],
                    ),
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
                            .collection('pelanggan')
                            .doc(doc.id)
                            .update({
                          'nama': nama.text,
                          'email': email.text,
                          'telepon': telp.text,
                          'kendaraan': kendaraan.text,
                          'plat': plat.text,
                          'km': km.text,
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
        ),
      );
    },
  );
}

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
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Data Pelanggan",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),

        const SizedBox(height: 10),
        const Text("Kelola data pelanggan bengkel"),

        const SizedBox(height: 20),

        Row(
          children: [
            Expanded(
              child: TextField(
                onChanged: (value) {
                  setState(() {
                    searchQuery = value.toLowerCase();
                    currentPage = 1;
                  });
                },
                decoration: const InputDecoration(
                  hintText: "Cari pelanggan...",
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 20),
            ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              elevation: 3,
            ),
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => const TambahPelangganPage(),
              );
            },
            icon: const Icon(Icons.person_add),
            label: const Text("Tambah Pelanggan"),
          ),
          ],
        ),

        const SizedBox(height: 20),

        Expanded(
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade400),
            ),
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('pelanggan')
                  .orderBy('created_at', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {

                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final allData = snapshot.data!.docs;

                final filteredData = allData.where((doc) {
                  final d = doc.data() as Map<String, dynamic>;

                  final nama = (d['nama'] ?? '').toLowerCase();
                  final email = (d['email'] ?? '').toLowerCase();
                  final telp = (d['telepon'] ?? '').toLowerCase();
                  final plat = (d['plat'] ?? '').toLowerCase();

                  return nama.contains(searchQuery) ||
                         email.contains(searchQuery) ||
                         telp.contains(searchQuery) ||
                         plat.contains(searchQuery);
                }).toList();

                int totalData = filteredData.length;

                int start = (currentPage - 1) * rowsPerPage;

                if (start >= totalData) {
                  start = 0;
                  currentPage = 1;
                }

                int end = start + rowsPerPage;

                if (end > totalData) {
                  end = totalData;
                }

                final paginatedData = totalData == 0
                    ? <DocumentSnapshot>[]
                    : filteredData.sublist(start, end);

                return Column(
                  children: [

                    // 🔥 TABLE
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
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
                                  headingRowColor:
                                      WidgetStateProperty.all(Colors.grey.shade300),

                                  columns: const [
                                    DataColumn(label: Text("NO")),
                                    DataColumn(label: Text("NAMA")),
                                    DataColumn(label: Text("EMAIL")),
                                    DataColumn(label: Text("TELEPON")),
                                    DataColumn(label: Text("KENDARAAN")),
                                    DataColumn(label: Text("PLAT")),
                                    DataColumn(label: Text("KM")),
                                    DataColumn(label: Text("AKSI")),
                                  ],

                                  rows: paginatedData.isEmpty
                                      ? []
                                      : paginatedData.asMap().entries.map((entry) {
                                          int index = entry.key;
                                          var doc = entry.value;
                                          final d = doc.data() as Map<String, dynamic>;

                                          return DataRow(cells: [
                                            DataCell(Text("${start + index + 1}")),
                                            DataCell(Text(d['nama'] ?? '')),
                                            DataCell(Text(d['email'] ?? '')),
                                            DataCell(Text(d['telepon'] ?? '')),
                                            DataCell(Text(d['kendaraan'] ?? '')),
                                            DataCell(Text(d['plat'] ?? '')),
                                            DataCell(Text(d['km'] ?? '')),

                                            DataCell(
                                                Row(
                                                  children: [

                                                    // ✏️ EDIT
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

                                                    // 🗑️ DELETE
                                                    GestureDetector(
                                                      onTap: () => hapusData(doc.id),
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

                    // 🔥 PAGINATION
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
                          onPressed: (currentPage * rowsPerPage) < filteredData.length
                              ? () => setState(() => currentPage++)
                              : null,
                        ),
                      ],
                    )
                  ],
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}