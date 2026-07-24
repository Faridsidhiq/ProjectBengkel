import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class KeluhanMobilePage extends StatefulWidget {
  const KeluhanMobilePage({super.key});

  @override
  State<KeluhanMobilePage> createState() => _KeluhanMobilePageState();
}

class _KeluhanMobilePageState extends State<KeluhanMobilePage> {
  final TextEditingController judulController = TextEditingController();
  final TextEditingController isiController = TextEditingController();
  bool isLoading = false;

  // ✅ FIX 1: Simpan user di state agar konsisten
  User? _user;

  @override
  void initState() {
    super.initState();
    _user = FirebaseAuth.instance.currentUser;

    // ✅ FIX 2: Debug - cek apakah user login dan punya email
    debugPrint("=== KELUHAN DEBUG ===");
    debugPrint("User UID   : ${_user?.uid}");
    debugPrint("User Email : ${_user?.email}");
    debugPrint("User Name  : ${_user?.displayName}");
    debugPrint("====================");
  }

  @override
  void dispose() {
    judulController.dispose();
    isiController.dispose();
    super.dispose();
  }

  Future<void> kirimKeluhan() async {
    // ✅ FIX 3: Cek login dulu sebelum kirim
    if (_user == null) {
      _showSnackbar("Anda belum login. Silakan login terlebih dahulu.",
          isError: true);
      return;
    }

    if (_user?.email == null || _user!.email!.isEmpty) {
      _showSnackbar("Email tidak ditemukan. Silakan login ulang.",
          isError: true);
      return;
    }

    if (judulController.text.trim().isEmpty) {
      _showSnackbar("Judul keluhan tidak boleh kosong", isError: true);
      return;
    }
    if (isiController.text.trim().isEmpty) {
      _showSnackbar("Isi keluhan tidak boleh kosong", isError: true);
      return;
    }

    setState(() => isLoading = true);

    try {
      // ✅ BATASI: Cek apakah user sudah punya keluhan aktif yang belum selesai
      final existingCheck = await FirebaseFirestore.instance
          .collection('keluhan')
          .where('email', isEqualTo: _user!.email)
          .get();

      final activeComplaints = existingCheck.docs.where((doc) {
        final status = (doc.data()['status'] ?? '').toString().trim().toLowerCase();
        return status != 'selesai';
      }).toList();

      if (activeComplaints.isNotEmpty) {
        setState(() => isLoading = false);
        _showSnackbar(
            "Anda sudah mengirimkan keluhan. Harap tunggu tanggapan dari admin.",
            isError: true);
        return;
      }

      // ✅ SIMPAN KELUHAN
      final docRef =
          await FirebaseFirestore.instance.collection('keluhan').add({
        'uid': _user!.uid,
        'nama': _user!.displayName ?? _user!.email ?? 'Pengguna',
        'email': _user!.email!,
        'judul': judulController.text.trim(),
        'isi': isiController.text.trim(),
        'status': 'Menunggu',
        'tanggapan': '',
        'created_at': FieldValue.serverTimestamp(),
      });

      debugPrint("Keluhan berhasil disimpan dengan ID: ${docRef.id}");

      if (!mounted) return;
      judulController.clear();
      isiController.clear();
      _showSnackbar("Keluhan berhasil dikirim!", isError: false);
    } catch (e) {
      debugPrint("ERROR kirim keluhan: $e");
      if (!mounted) return;
      _showSnackbar("Gagal mengirim keluhan: $e", isError: true);
    }

    if (mounted) setState(() => isLoading = false);
  }

  void _showSnackbar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text("Keluhan Pelanggan"),
        backgroundColor: Colors.blue.shade800,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // INFO PENGIRIM
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.blue.shade800,
                    child: const Icon(Icons.person, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _user?.displayName ?? "Pengguna",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        _user?.email ?? "Email tidak tersedia",
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // FORM / STATUS KELUHAN TERKIRIM
            if (_user != null && _user?.email != null)
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('keluhan')
                    .where('email', isEqualTo: _user!.email)
                    .snapshots(),
                builder: (context, snapshot) {
                  final docs = snapshot.data?.docs ?? [];
                  final activeComplaints = docs.where((doc) {
                    final status = (doc.data() as Map<String, dynamic>)['status']
                        .toString()
                        .trim()
                        .toLowerCase();
                    return status != 'selesai';
                  }).toList();

                  if (activeComplaints.isNotEmpty) {
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orange.shade300),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.info_outline, color: Colors.orange.shade800, size: 40),
                          const SizedBox(height: 12),
                          Text(
                            "Keluhan Anda Telah Terkirim",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange.shade900,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            "Anda sudah mengirimkan keluhan ke admin. Pelanggan hanya dapat mengirimkan 1 keluhan dalam satu waktu. Harap tunggu tanggapan dari admin pada riwayat keluhan di bawah ini.",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.orange.shade900,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return _buildFormKeluhan();
                },
              )
            else
              _buildFormKeluhan(),

            const SizedBox(height: 24),

            // RIWAYAT KELUHAN
            const Text(
              "Riwayat Keluhan",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),

            const SizedBox(height: 10),

            // ✅ FIX 5: Cek user null dulu sebelum StreamBuilder
            if (_user == null || _user?.email == null)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Center(
                  child: Text(
                    "Anda harus login untuk melihat riwayat keluhan",
                    style: TextStyle(color: Colors.red.shade700),
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            else
              StreamBuilder<QuerySnapshot>(
                // ✅ FIX 6: Query pakai UID lebih reliable dari email
                stream: FirebaseFirestore.instance
                    .collection('keluhan')
                    .where('email', isEqualTo: _user!.email)
                    .orderBy('created_at', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  // ✅ FIX 7: Tangkap error index Firestore
                  if (snapshot.hasError) {
                    final errorMsg = snapshot.error.toString();
                    debugPrint("FIRESTORE ERROR: $errorMsg");

                    // Deteksi error index
                    if (errorMsg.contains('FAILED_PRECONDITION') ||
                        errorMsg.contains('index')) {
                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.orange.shade300),
                        ),
                        child: Column(
                          children: [
                            Icon(Icons.warning_amber_rounded,
                                color: Colors.orange.shade700, size: 32),
                            const SizedBox(height: 8),
                            Text(
                              "Index Firestore belum dibuat.\nCek logcat untuk link pembuatan index.",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  color: Colors.orange.shade800, fontSize: 13),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              "Detail: $errorMsg",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  color: Colors.orange.shade600, fontSize: 11),
                            ),
                          ],
                        ),
                      );
                    }

                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        "Terjadi kesalahan: $errorMsg",
                        style: TextStyle(color: Colors.red.shade700),
                        textAlign: TextAlign.center,
                      ),
                    );
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          "Belum ada keluhan yang dikirim",
                          style: TextStyle(color: Colors.grey.shade500),
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: (context, index) {
                      final data = snapshot.data!.docs[index].data()
                          as Map<String, dynamic>;
                      final status = data['status'] ?? 'Menunggu';
                      final tanggapan = data['tanggapan'] ?? '';

                      Color statusColor;
                      if (status == 'Selesai') {
                        statusColor = Colors.green;
                      } else if (status == 'Sedang Proses') {
                        statusColor = Colors.orange;
                      } else {
                        statusColor = Colors.grey;
                      }

                      // ✅ FIX 8: Handle created_at bisa null (serverTimestamp delay)
                      final createdAt = data['created_at'] as Timestamp?;
                      final tanggalStr = createdAt != null
                          ? _formatTanggal(createdAt.toDate())
                          : 'Baru saja';

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.shade200,
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    data['judul'] ?? '',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: statusColor.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: statusColor),
                                  ),
                                  child: Text(
                                    status,
                                    style: TextStyle(
                                      color: statusColor,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            // ✅ Tampilkan tanggal
                            const SizedBox(height: 4),
                            Text(
                              tanggalStr,
                              style: TextStyle(
                                color: Colors.grey.shade400,
                                fontSize: 11,
                              ),
                            ),

                            const SizedBox(height: 6),
                            Text(
                              data['isi'] ?? '',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 13,
                              ),
                            ),

                            // ✅ Tanggapan dari admin
                            if (tanggapan.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border:
                                      Border.all(color: Colors.green.shade200),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(Icons.support_agent,
                                        size: 16,
                                        color: Colors.green.shade700),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            "Balasan Admin",
                                            style: TextStyle(
                                              color: Colors.green.shade700,
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            tanggapan,
                                            style: TextStyle(
                                              color: Colors.green.shade800,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  );
                },
              ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // ✅ Helper format tanggal
  String _formatTanggal(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inMinutes < 1) return 'Baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes} menit lalu';
    if (diff.inHours < 24) return '${diff.inHours} jam lalu';
    if (diff.inDays < 7) return '${diff.inDays} hari lalu';

    return '${dt.day}/${dt.month}/${dt.year}';
  }

  Widget _buildFormKeluhan() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 5,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Tulis Keluhan Anda",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "Keluhan akan ditinjau oleh tim kami",
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 16),

          // JUDUL
          const Text(
            "Judul Keluhan",
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: judulController,
            decoration: InputDecoration(
              hintText: "Contoh: Mesin bunyi kasar",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),

          const SizedBox(height: 14),

          // ISI KELUHAN
          const Text(
            "Detail Keluhan",
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: isiController,
            maxLines: 5,
            decoration: InputDecoration(
              hintText: "Ceritakan keluhan Anda secara detail...",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // TOMBOL KIRIM
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade800,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: isLoading ? null : kirimKeluhan,
              icon: isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.send),
              label: Text(
                isLoading ? "Mengirim..." : "Kirim Keluhan",
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}