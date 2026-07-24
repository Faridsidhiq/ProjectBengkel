import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
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

  Future<void> hapusData(String id, String nama) async {
    final konfirmasi = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Hapus Data Pelanggan"),
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
      await FirebaseFirestore.instance
          .collection('pelanggan')
          .doc(id)
          .delete();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Data pelanggan "$nama" berhasil dihapus'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

void editData(DocumentSnapshot doc) {
  final data = doc.data() as Map<String, dynamic>;

  final nama = TextEditingController(text: data['nama']);
  final email = TextEditingController(text: data['email']);
  final telp = TextEditingController(text: data['telepon']);
  final kendaraan = TextEditingController(text: data['kendaraan']);
  final km = TextEditingController(text: data['km']);

  final String existingPlat = data['plat'] ?? '';
  String selectedKodePlat = "BE";
  String initialPlatRest = "";

  if (existingPlat.isNotEmpty) {
    final parts = existingPlat.trim().split(RegExp(r'\s+'));
    if (parts.isNotEmpty && listKodePlat.contains(parts[0].toUpperCase())) {
      selectedKodePlat = parts[0].toUpperCase();
      initialPlatRest = parts.sublist(1).join(" ");
    } else {
      initialPlatRest = existingPlat;
    }
  }

  final platRestController = TextEditingController(text: initialPlatRest);

  showDialog(
    context: context,
    builder: (dialogContext) {
      final screenHeight = MediaQuery.of(dialogContext).size.height;

      return StatefulBuilder(
        builder: (context, setDialogState) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: 500,
                maxHeight: screenHeight * 0.9,
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

                    Flexible(
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            buildInput("Nama Lengkap *", nama),
                            buildInput("Email *", email, keyboardType: TextInputType.emailAddress),
                            buildInput(
                              "Nomor Telepon *",
                              telp,
                              keyboardType: TextInputType.phone,
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(RegExp(r'[\d+]')),
                              ],
                            ),
                            buildPlatInput(selectedKodePlat, platRestController, (val) {
                              setDialogState(() {
                                selectedKodePlat = val;
                              });
                            }),
                            buildInput("Nama Kendaraan *", kendaraan),
                            buildInput(
                              "KM Terakhir *",
                              km,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                ThousandsSeparatorInputFormatter(),
                              ],
                              suffixText: "KM",
                            ),
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
                            if (nama.text.trim().isEmpty ||
                                email.text.trim().isEmpty ||
                                telp.text.trim().isEmpty ||
                                platRestController.text.trim().isEmpty ||
                                kendaraan.text.trim().isEmpty ||
                                km.text.trim().isEmpty) {
                              ScaffoldMessenger.of(context).hideCurrentSnackBar();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  elevation: 6,
                                  behavior: SnackBarBehavior.floating,
                                  margin: const EdgeInsets.all(16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  backgroundColor: Colors.red.shade700,
                                  content: const Row(
                                    children: [
                                      Icon(Icons.warning_amber_rounded, color: Colors.white, size: 28),
                                      SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          "Mohon lengkapi semua kolom input terlebih dahulu!",
                                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                              return;
                            }

                            final String phoneDigits = telp.text.replaceAll(RegExp(r'\D'), '');
                            if (phoneDigits.length < 11 || phoneDigits.length > 14) {
                              ScaffoldMessenger.of(context).hideCurrentSnackBar();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  elevation: 6,
                                  behavior: SnackBarBehavior.floating,
                                  margin: const EdgeInsets.all(16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  backgroundColor: Colors.red.shade700,
                                  content: const Row(
                                    children: [
                                      Icon(Icons.warning_amber_rounded, color: Colors.white, size: 28),
                                      SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          "Nomor telepon harus terdiri dari 11 - 14 digit angka!",
                                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                              return;
                            }

                            final String fullPlat = '$selectedKodePlat ${platRestController.text.trim().toUpperCase()}';
                            final String rawKm = km.text.trim();
                            final String formattedKm = rawKm.endsWith('KM') ? rawKm : '$rawKm KM';

                            final navigator = Navigator.of(dialogContext);

                            await FirebaseFirestore.instance
                                .collection('pelanggan')
                                .doc(doc.id)
                                .update({
                              'nama': nama.text.trim(),
                              'email': email.text.trim(),
                              'telepon': telp.text.trim(),
                              'plat': fullPlat,
                              'kendaraan': kendaraan.text.trim(),
                              'km': formattedKm,
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
    },
  );
}

  Widget buildPlatInput(
    String selectedKode,
    TextEditingController controller,
    ValueChanged<String> onChangedKode,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Nomor Plat *", style: TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(height: 5),
          Row(
            children: [
              SizedBox(
                width: 95,
                child: DropdownButtonFormField<String>(
                  value: selectedKode,
                  isExpanded: true,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  items: listKodePlat.map((kode) {
                    return DropdownMenuItem<String>(
                      value: kode,
                      child: Text(
                        kode,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      onChangedKode(val);
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: controller,
                  textCapitalization: TextCapitalization.characters,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9\s]')),
                  ],
                  decoration: InputDecoration(
                    hintText: "1234 ABC",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget buildInput(
    String label,
    TextEditingController controller, {
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    String? suffixText,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(height: 5),
          TextField(
            controller: controller,
            keyboardType: keyboardType,
            inputFormatters: inputFormatters,
            decoration: InputDecoration(
              hintText: label,
              suffixText: suffixText,
              suffixStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
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
                                    DataColumn(label: Text("NAMA LENGKAP")),
                                    DataColumn(label: Text("EMAIL")),
                                    DataColumn(label: Text("NOMOR TELEPON")),
                                    DataColumn(label: Text("NOMOR PLAT")),
                                    DataColumn(label: Text("NAMA KENDARAAN")),
                                    DataColumn(label: Text("KM TERAKHIR")),
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
                                            DataCell(Text(d['plat'] ?? '')),
                                            DataCell(Text(d['kendaraan'] ?? '')),
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