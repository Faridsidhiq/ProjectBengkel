import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
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
  String platKendaraan = "Memuat plat...";
  String modelKendaraan = "Memuat model...";
  String kmKendaraan = "Memuat KM...";

  int countServis = 0;
  int countKeluhan = 0;

  final List<String> _platPrefixes = [
    "BE", "B", "D", "A", "AB", "AD", "L", "N", "DK", "BG", "BH", "BK", "BM", "BP", "BD", "BA", "KB", "DA", "KH", "KT", "DD", "PA"
  ];

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
            platKendaraan = userDoc['plat'] ?? '-';
            modelKendaraan = userDoc['kendaraan'] ?? '-';
            kmKendaraan = userDoc['km'] ?? '-';
          });
        }

        // Query Statistik Pengerjaan
        final email = currentUser!.email ?? emailPelanggan;
        if (email != '-' && email.isNotEmpty) {
          final spkSnap = await FirebaseFirestore.instance
              .collection('spk')
              .where('email', isEqualTo: email)
              .where('status', isEqualTo: 'Selesai')
              .get();
              
          final keluhanSnap = await FirebaseFirestore.instance
              .collection('keluhan')
              .where('email', isEqualTo: email)
              .get();

          if (mounted) {
            setState(() {
              countServis = spkSnap.docs.length;
              countKeluhan = keluhanSnap.docs.length;
            });
          }
        }
      } catch (e) {
        debugPrint("Gagal mengambil data: $e");
      }
    }
  }

  String _getInitials(String name) {
    if (name.isEmpty || name == "Memuat nama..." || name == "Tanpa Nama") return "U";
    List<String> parts = name.trim().split(" ");
    String initials = "";
    if (parts.isNotEmpty && parts[0].isNotEmpty) {
      initials += parts[0][0];
      if (parts.length > 1 && parts[1].isNotEmpty) {
        initials += parts[1][0];
      }
    }
    return initials.toUpperCase();
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

  // ==================== DIALOG EDIT PLAT ====================
  void _editPlatDialog() {
    String selectedPrefix = "BE";
    String initialNumber = "";
    
    if (platKendaraan != '-' && platKendaraan.trim().isNotEmpty) {
      final trimmed = platKendaraan.trim();
      final spaceIndex = trimmed.indexOf(' ');
      if (spaceIndex != -1) {
        final possiblePrefix = trimmed.substring(0, spaceIndex).toUpperCase();
        if (_platPrefixes.contains(possiblePrefix)) {
          selectedPrefix = possiblePrefix;
          initialNumber = trimmed.substring(spaceIndex + 1);
        } else {
          initialNumber = trimmed;
        }
      } else {
        initialNumber = trimmed;
      }
    }
    
    TextEditingController platNumberController = TextEditingController(text: initialNumber);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            title: const Text("Ubah Plat Nomor", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            content: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedPrefix,
                      items: _platPrefixes.map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setDialogState(() {
                            selectedPrefix = newValue;
                          });
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: platNumberController,
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(
                      labelText: "Nomor & Suffix",
                      hintText: "1234 ABC",
                      prefixIcon: Icon(Icons.badge_outlined),
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text("Batal", style: TextStyle(color: Colors.grey))),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade700),
                onPressed: () async {
                  if (currentUser != null && platNumberController.text.trim().isNotEmpty) {
                    final newPlat = "$selectedPrefix ${platNumberController.text.trim()}".toUpperCase();
                    await FirebaseFirestore.instance.collection('pelanggan').doc(currentUser!.uid).set({
                      'plat': newPlat,
                    }, SetOptions(merge: true));

                    setState(() => platKendaraan = newPlat);
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Plat nomor berhasil diubah!")));
                    }
                  }
                },
                child: const Text("Simpan", style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        }
      ),
    );
  }

  // ==================== DIALOG EDIT MODEL KENDARAAN ====================
  void _editKendaraanDialog() {
    TextEditingController kendaraanController = TextEditingController(text: modelKendaraan == '-' ? '' : modelKendaraan);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text("Ubah Model Kendaraan", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: TextField(
          controller: kendaraanController,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(labelText: "Model Kendaraan Baru", hintText: "Contoh: Pajero Sport", prefixIcon: Icon(Icons.directions_car_outlined)),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Batal", style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade700),
            onPressed: () async {
              if (currentUser != null && kendaraanController.text.trim().isNotEmpty) {
                final newKendaraan = kendaraanController.text.trim();
                await FirebaseFirestore.instance.collection('pelanggan').doc(currentUser!.uid).set({
                  'kendaraan': newKendaraan,
                }, SetOptions(merge: true));

                setState(() => modelKendaraan = newKendaraan);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Model kendaraan berhasil diubah!")));
                }
              }
            },
            child: const Text("Simpan", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ==================== DIALOG EDIT KM ====================
  void _editKmDialog() {
    TextEditingController kmController = TextEditingController(text: kmKendaraan == '-' ? '' : kmKendaraan);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text("Ubah Kilometer Kendaraan", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: TextField(
          controller: kmController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: "Kilometer Kendaraan Baru", hintText: "Contoh: 25000", prefixIcon: Icon(Icons.speed_outlined)),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Batal", style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade700),
            onPressed: () async {
              if (currentUser != null) {
                final newKm = kmController.text.trim().isNotEmpty ? kmController.text.trim() : '-';
                await FirebaseFirestore.instance.collection('pelanggan').doc(currentUser!.uid).set({
                  'km': newKm,
                }, SetOptions(merge: true));

                setState(() => kmKendaraan = newKm);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Kilometer kendaraan berhasil diubah!")));
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
                    AuthCredential credential = EmailAuthProvider.credential(
                      email: currentUser!.email!, 
                      password: passwordLamaController.text.trim()
                    );
                    await currentUser!.reauthenticateWithCredential(credential);

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
              if (!context.mounted) return;
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const LoginMobilePage()), 
                (route) => false,
              );
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
      backgroundColor: Colors.grey.shade50,
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
            // ================= KARTU UTAMA PROFIL GRADASI MODERN =================
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade900, Colors.blue.shade700],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 16),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 46,
                    backgroundColor: Colors.white24,
                    child: CircleAvatar(
                      radius: 42,
                      backgroundColor: Colors.white,
                      child: Text(
                        _getInitials(namaPelanggan),
                        style: TextStyle(
                          fontSize: 28, 
                          fontWeight: FontWeight.bold, 
                          color: Colors.blue.shade900,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: _editNamaDialog,
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            namaPelanggan, 
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.edit, size: 16, color: Colors.white70),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(emailPelanggan, style: const TextStyle(fontSize: 14, color: Colors.white70)),
                ],
              ),
            ),
            
            // ================= SEKSI STATISTIK KENDARAAN (ARSIP) =================
            _buildStatRow(),

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
              decoration: BoxDecoration(
                color: Colors.white, 
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
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

            // ================= SEKSI INFORMASI KENDARAAN =================
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text("Informasi Kendaraan", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey.shade700)),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: Colors.white, 
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  InkWell(
                    onTap: _editPlatDialog,
                    child: _buildInfoTile(Icons.badge_outlined, "Nomor Plat Kendaraan", platKendaraan, showEditIcon: true),
                  ),
                  Divider(height: 1, color: Colors.grey.shade100),
                  InkWell(
                    onTap: _editKendaraanDialog,
                    child: _buildInfoTile(Icons.directions_car_outlined, "Model Kendaraan", modelKendaraan, showEditIcon: true),
                  ),
                  Divider(height: 1, color: Colors.grey.shade100),
                  InkWell(
                    onTap: _editKmDialog,
                    child: _buildInfoTile(Icons.speed_outlined, "Kilometer Kendaraan", kmKendaraan, showEditIcon: true),
                  ),
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
              decoration: BoxDecoration(
                color: Colors.white, 
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  _buildMenuTile(Icons.history, "Riwayat Servis Mobil", () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const RiwayatServisPage()));
                  }),
                  Divider(height: 1, color: Colors.grey.shade100),
                  _buildMenuTile(Icons.lock_outline, "Ubah Kata Sandi", _ubahKataSandiDialog),
                  Divider(height: 1, color: Colors.grey.shade100),
                  _buildMenuTile(
                    Icons.chat_outlined, 
                    "Hubungi Customer Service", 
                    () async {
                      final Uri url = Uri.parse("https://wa.me/6285269864232?text=Halo%20Admin%20Jimu%20Mitsubishi,%20saya%20ingin%20berkonsultasi%20seputar%20servis%20mobil%20saya.");
                      if (await canLaunchUrl(url)) {
                        await launchUrl(url, mode: LaunchMode.externalApplication);
                      } else {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Tidak dapat membuka WhatsApp")),
                          );
                        }
                      }
                    },
                    textColor: Colors.blue.shade800,
                    iconColor: Colors.blue.shade800,
                  ),
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

  Widget _buildStatRow() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatItem("Servis Selesai", "$countServis Kali", Icons.history, Colors.green),
          Container(height: 30, width: 1, color: Colors.grey.shade200),
          _buildStatItem("Keluhan Terkirim", "$countKeluhan Laporan", Icons.support_agent, Colors.orange),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Row(
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: color.withValues(alpha: 0.1),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(color: Colors.grey.shade500, fontSize: 10)),
            const SizedBox(height: 2),
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87)),
          ],
        )
      ],
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