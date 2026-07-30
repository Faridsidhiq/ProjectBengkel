import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'tambah_manajemen_akun_page.dart';

class ManajemenAkunPage extends StatefulWidget {
  const ManajemenAkunPage({super.key});

  @override
  State<ManajemenAkunPage> createState() =>
      _ManajemenAkunPageState();
}

class _ManajemenAkunPageState
    extends State<ManajemenAkunPage> {

  final TextEditingController searchController =
      TextEditingController();

  // ================= RESET PASSWORD =================

  Future<void> resetPassword(String email) async {
    try {
      await FirebaseAuth.instance
          .sendPasswordResetEmail(email: email);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Link reset password telah dikirim ke $email",
          ),
          backgroundColor: Colors.green,
        ),
      );

    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Gagal kirim reset password: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ================= HAPUS AKUN =================

  Future<void> hapusAkun(String docId) async {

    // KONFIRMASI SEBELUM HAPUS
    final konfirmasi = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Hapus Akun"),
        content: const Text(
          "Apakah kamu yakin ingin menghapus akun ini?",
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

    if (konfirmasi != true) return;

    try {
      // Hapus dari Firestore
      await FirebaseFirestore.instance
          .collection('manajemen_akun')
          .doc(docId)
          .delete();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Akun berhasil dihapus"),
          backgroundColor: Colors.green,
        ),
      );

    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Gagal hapus akun: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,

      children: [

          // ================= TITLE =================

          const Text(
            "Manajemen Akun",
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 5),

          const Text(
            "Kelola informasi akun pengguna bengkel",
            style: TextStyle(color: Colors.grey),
          ),

          const SizedBox(height: 25),

          // ================= SEARCH + BUTTON =================

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [

              SizedBox(
                width: 300,
                child: TextField(
                  controller: searchController,
                  onChanged: (value) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: "Cari akun admin...",
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: Colors.grey.shade300,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: Colors.grey.shade300,
                      ),
                    ),
                  ),
                ),
              ),

              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 18,
                  ),
                ),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) =>
                        const TambahManajemenAkunPage(),
                  );
                },
                icon: const Icon(Icons.add),
                label: const Text("Tambah Akun"),
              ),
            ],
          ),

          const SizedBox(height: 30),

          // ================= TABLE =================

          Expanded(
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade400),
              ),

              child: StreamBuilder(
                stream: FirebaseFirestore.instance
                    .collection('manajemen_akun')
                    .orderBy('created_at', descending: false)
                    .snapshots(),

                builder: (context, snapshot) {

                        if (!snapshot.hasData) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        // ================= FILTER SEARCH =================
                        final query =
                            searchController.text.toLowerCase();

                        final filteredList =
                            snapshot.data!.docs.where((data) {
                          final nama =
                              data['nama'].toString().toLowerCase();
                          final email =
                              data['email'].toString().toLowerCase();
                          return nama.contains(query) ||
                              email.contains(query);
                        }).toList();

                        // ================= EMPTY STATE =================
                        if (filteredList.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.all(40),
                            child: Center(
                              child: Text(
                                "Tidak ada akun ditemukan",
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
                          );
                        }

                        return LayoutBuilder(
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
                          headingRowHeight: 45,
                          dataRowMinHeight: 45,
                          dataRowMaxHeight: 55,

                          headingRowColor: WidgetStateProperty.all(
                            Colors.grey.shade300,
                          ),

                          headingTextStyle: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),

                          columns: const [
                            DataColumn(label: Text("NO")),
                            DataColumn(label: Text("NAMA")),
                            DataColumn(label: Text("EMAIL")),
                            DataColumn(label: Text("ROLE")),
                            DataColumn(label: Text("TANGGAL DIBUAT")),
                            DataColumn(label: Text("AKSI")),
                          ],

                          rows: List.generate(
                            filteredList.length,
                            (index) {

                              final data = filteredList[index];

                                String role = 'admin';

                                if (data.data().containsKey('role')) {
                                  role = data['role'];
                                }

                              // FORMAT TANGGAL
                              String tanggal = "-";
                              if (data['created_at'] != null) {
                                final date =
                                    data['created_at'].toDate();
                                tanggal =
                                    "${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}";
                              }

                              return DataRow(
                                cells: [

                                  DataCell(Text("${index + 1}")),

                                  DataCell(
                                    Text(data['nama'] ?? "-"),
                                  ),

                                  DataCell(
                                    Text(data['email'] ?? "-"),
                                  ),

                                  DataCell(
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: role == 'admin'
                                            ? Colors.blue.shade100
                                            : Colors.orange.shade100,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        role == 'admin'
                                            ? 'Admin'
                                            : 'Montir',
                                        style: TextStyle(
                                          color: role == 'admin'
                                              ? Colors.blue
                                              : Colors.orange,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                  DataCell(Text(tanggal)),

                                  // ================= AKSI =================
                                  DataCell(
                                    Row(
                                      children: [

                                        // 🔑 RESET PASSWORD
                                        Tooltip(
                                          message: "Reset Password",
                                          child: GestureDetector(
                                            onTap: () => resetPassword(
                                              data['email'],
                                            ),
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.all(6),
                                              decoration: BoxDecoration(
                                                color:
                                                    Colors.blue.shade100,
                                                borderRadius:
                                                    BorderRadius.circular(
                                                  4,
                                                ),
                                              ),
                                              child: const Icon(
                                                Icons.key,
                                                size: 16,
                                                color: Colors.blue,
                                              ),
                                            ),
                                          ),
                                        ),

                                        const SizedBox(width: 8),

                                        // 🗑 HAPUS
                                        Tooltip(
                                          message: "Hapus Akun",
                                          child: GestureDetector(
                                            onTap: () =>
                                                hapusAkun(data.id),
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.all(6),
                                              decoration: BoxDecoration(
                                                color: Colors.red.shade100,
                                                borderRadius:
                                                    BorderRadius.circular(
                                                  4,
                                                ),
                                              ),
                                              child: const Icon(
                                                Icons.delete,
                                                size: 16,
                                                color: Colors.red,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
            ),
          ),
        ],
    );
  }
}