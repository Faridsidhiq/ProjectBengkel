import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../mobile/login_mobile_page.dart';
import 'riwayat_servis_page.dart';

class AkunMobilePage extends StatefulWidget {
  const AkunMobilePage({super.key});

  @override
  State<AkunMobilePage> createState() => _AkunMobilePageState();
}

class _AkunMobilePageState extends State<AkunMobilePage> {
  final User? currentUser = FirebaseAuth.instance.currentUser;
  
  String namaPelanggan = "Memuat nama...";
  String emailPelanggan = "Memuat email...";
  String nomorTelepon = "Memuat nomor...";

  @override
  void initState() {
    super.initState();
    _ambilDataPelanggan();
  }

  Future<void> _ambilDataPelanggan() async {
    if (currentUser != null) {
      try {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('pelanggan') 
            .doc(currentUser!.uid)
            .get();

        if (userDoc.exists && mounted) {
          setState(() {
            namaPelanggan = userDoc['nama'] ?? 'Tanpa Nama';
            emailPelanggan = userDoc['email'] ?? currentUser!.email ?? '-';
            nomorTelepon = userDoc['telepon'] ?? '-'; 
          });
        }
      } catch (e) {
        debugPrint("Gagal mengambil data: $e");
      }
    }
  }

  // ==================== DIALOG EDIT NAMA ====================
  void _editNamaDialog() {
    TextEditingController namaController = TextEditingController(text: namaPelanggan);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text("Ubah Nama", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: TextField(
          controller: namaController,
          decoration: const InputDecoration(labelText: "Nama Lengkap", prefixIcon: Icon(Icons.person_outline)),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Batal", style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade700),
            onPressed: () async {
              if (currentUser != null && namaController.text.trim().isNotEmpty) {
                await FirebaseFirestore.instance.collection('pelanggan').doc(currentUser!.uid).set({
                  'nama': namaController.text.trim(),
                }, SetOptions(merge: true));

                setState(() => namaPelanggan = namaController.text.trim());
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Nama berhasil diubah!")));
                }
              }
            },
            child: const Text("Simpan", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ==================== DIALOG EDIT NOMOR HP ====================
  void _editTeleponDialog() {
    TextEditingController teleponController = TextEditingController(text: nomorTelepon);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text("Ubah Nomor Telepon", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: TextField(
          controller: teleponController,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(labelText: "Nomor Telepon Baru", prefixIcon: Icon(Icons.phone_android)),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Batal", style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade700),
            onPressed: () async {
              if (currentUser != null && teleponController.text.trim().isNotEmpty) {
                await FirebaseFirestore.instance.collection('pelanggan').doc(currentUser!.uid).set({
                  'telepon': teleponController.text.trim(),
                }, SetOptions(merge: true));

                setState(() => nomorTelepon = teleponController.text.trim());
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Nomor telepon berhasil diubah!")));
                }
              }
            },
            child: const Text("Simpan", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ==================== DIALOG UBAH KATA SANDI AMAN ====================
  void _ubahKataSandiDialog() {
    TextEditingController passwordLamaController = TextEditingController();
    TextEditingController passwordBaruController = TextEditingController();
    bool isObscureLama = true;
    bool isObscureBaru = true;
    bool isLoading = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            title: const Text("Ubah Kata Sandi", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("Sebagai keamanan, masukkan kata sandi lama Anda terlebih dahulu.", style: TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 15),
                // Input Sandi Lama
                TextField(
                  controller: passwordLamaController,
                  obscureText: isObscureLama,
                  decoration: InputDecoration(
                    labelText: "Kata Sandi Lama",
                    prefixIcon: const Icon(Icons.lock_clock),
                    suffixIcon: IconButton(
                      icon: Icon(isObscureLama ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
                      onPressed: () => setDialogState(() => isObscureLama = !isObscureLama),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                // Input Sandi Baru
                TextField(
                  controller: passwordBaruController,
                  obscureText: isObscureBaru,
                  decoration: InputDecoration(
                    labelText: "Kata Sandi Baru",
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(isObscureBaru ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
                      onPressed: () => setDialogState(() => isObscureBaru = !isObscureBaru),
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: isLoading ? null : () => Navigator.pop(context), 
                child: const Text("Batal", style: TextStyle(color: Colors.grey))
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade700),
                onPressed: isLoading ? null : () async {
                  if (passwordLamaController.text.isEmpty || passwordBaruController.text.length < 6) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Isi sandi lama dan sandi baru minimal 6 karakter!"), backgroundColor: Colors.red));
                    return;
                  }

                  setDialogState(() => isLoading = true);

                  try {
                    // 1. Verifikasi sandi lama
                    AuthCredential credential = EmailAuthProvider.credential(
                      email: currentUser!.email!, 
                      password: passwordLamaController.text.trim()
                    );
                    await currentUser!.reauthenticateWithCredential(credential);

                    // 2. Jika benar, ganti ke sandi baru
                    await currentUser!.updatePassword(passwordBaruController.text.trim());
                    
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Kata sandi berhasil diubah!"), backgroundColor: Colors.green));
                    }
                  } on FirebaseAuthException catch (e) {
                    if (context.mounted) {
                      String errorMsg = "Terjadi kesalahan.";
                      if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
                        errorMsg = "Kata sandi lama yang Anda masukkan salah!";
                      }
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMsg), backgroundColor: Colors.red));
                    }
                  } finally {
                    setDialogState(() => isLoading = false);
                  }
                },
                child: isLoading 
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text("Simpan", style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        }
      ),
    );
  }

  // ==================== FUNGSI LOGOUT ====================
  Future<void> _prosesLogout() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Konfirmasi Keluar", style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text("Apakah Anda yakin ingin keluar dari akun Jimu Mitsubishi?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Batal", style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700),
            onPressed: () async {
              Navigator.pop(context);
              await FirebaseAuth.instance.signOut();
              if (mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginMobilePage()), 
                  (route) => false,
                );
              }
            },
            child: const Text("Keluar", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text("Profil Akun", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ================= KARTU UTAMA PROFIL =================
            Container(
              width: double.infinity,
              color: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              child: Column(
                children: [
                  // FOTO STATIS (TIDAK BISA DIKLIK)
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.red.shade50,
                    child: Icon(Icons.person, size: 60, color: Colors.red.shade700),
                  ),
                  const SizedBox(height: 16),
                  
                  // HANYA MENGUBAH NAMA
                  InkWell(
                    onTap: _editNamaDialog,
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(namaPelanggan, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)),
                          const SizedBox(width: 8),
                          Icon(Icons.edit, size: 16, color: Colors.grey.shade400),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(emailPelanggan, style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
                ],
              ),
            ),
            
            const SizedBox(height: 12),

            // ================= SEKSI DETAIL INFORMASI =================
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text("Informasi Pribadi", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey.shade700)),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
              child: Column(
                children: [
                  // HANYA MENGUBAH NOMOR TELEPON
                  InkWell(
                    onTap: _editTeleponDialog,
                    child: _buildInfoTile(Icons.phone_android, "Nomor Telepon", nomorTelepon, showEditIcon: true),
                  ),
                  Divider(height: 1, color: Colors.grey.shade100),
                  _buildInfoTile(Icons.verified_user_outlined, "Status Akun", "Pelanggan", showEditIcon: false),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ================= SEKSI PENGATURAN & AKSI =================
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text("Pengaturan Aplikasi", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey.shade700)),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
              child: Column(
                children: [
                  _buildMenuTile(Icons.history, "Riwayat Servis Mobil", () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const RiwayatServisPage()));
                  }),
                  Divider(height: 1, color: Colors.grey.shade100),
                  _buildMenuTile(Icons.lock_outline, "Ubah Kata Sandi", _ubahKataSandiDialog),
                  Divider(height: 1, color: Colors.grey.shade100),
                  _buildMenuTile(Icons.logout, "Keluar dari Akun", _prosesLogout, textColor: Colors.red, iconColor: Colors.red),
                ],
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile(IconData icon, String label, String value, {bool showEditIcon = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icon, color: Colors.blueGrey, size: 22),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Colors.black87)),
              ],
            ),
          ),
          if (showEditIcon) Icon(Icons.edit, size: 16, color: Colors.grey.shade400),
        ],
      ),
    );
  }

  Widget _buildMenuTile(IconData icon, String title, VoidCallback onTap, {Color textColor = Colors.black87, Color iconColor = Colors.blueGrey}) {
    return ListTile(
      leading: Icon(icon, color: iconColor, size: 22),
      title: Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: textColor)),
      trailing: Icon(Icons.chevron_right, color: Colors.grey.shade400, size: 20),
      onTap: onTap,
    );
  }
}