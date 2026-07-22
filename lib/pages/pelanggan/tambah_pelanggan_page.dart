import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/intl.dart';

// Formatter otomatis untuk pemisah ribuan (titik) pada angka KM
class ThousandsSeparatorInputFormatter extends TextInputFormatter {
  final NumberFormat _formatter = NumberFormat('#,##0', 'id_ID');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '');
    }

    final String digitsOnly = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digitsOnly.isEmpty) {
      return newValue.copyWith(text: '');
    }

    final int number = int.parse(digitsOnly);
    final String newText = _formatter.format(number);

    return TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
}

// Daftar Kode Plat Nomor Wilayah Indonesia
const List<String> listKodePlat = [
  "A", "AA", "AB", "AD", "AE", "AG", "B", "BA", "BB", "BD", "BE", "BG", "BH",
  "BK", "BL", "BM", "BN", "BP", "D", "DA", "DB", "DC", "DD", "DE", "DG", "DH",
  "DK", "DL", "DM", "DN", "DP", "DR", "DS", "DT", "DW", "E", "ED", "F", "G",
  "H", "K", "KB", "KH", "KT", "KU", "L", "M", "N", "P", "PA", "PB", "R", "S",
  "T", "W", "Z"
];

class TambahPelangganPage extends StatefulWidget {
  const TambahPelangganPage({super.key});

  @override
  State<TambahPelangganPage> createState() => _TambahPelangganPageState();
}

class _TambahPelangganPageState extends State<TambahPelangganPage> {
  final namaController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final telpController = TextEditingController();
  final platRestController = TextEditingController();
  final kendaraanController = TextEditingController();
  final kmController = TextEditingController();

  String selectedKodePlat = "BE";
  bool isLoading = false;
  bool obscurePassword = true;

  // Notifikasi menarik & modern
  void showNotification(BuildContext context, String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        elevation: 6,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        backgroundColor: isError ? Colors.red.shade700 : Colors.green.shade700,
        content: Row(
          children: [
            Icon(
              isError ? Icons.warning_amber_rounded : Icons.check_circle_rounded,
              color: Colors.white,
              size: 28,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> simpanData() async {
    // 1. Cek kelengkapan semua kolom input
    if (namaController.text.trim().isEmpty ||
        emailController.text.trim().isEmpty ||
        passwordController.text.trim().isEmpty ||
        telpController.text.trim().isEmpty ||
        platRestController.text.trim().isEmpty ||
        kendaraanController.text.trim().isEmpty ||
        kmController.text.trim().isEmpty) {
      showNotification(
        context,
        "Mohon lengkapi semua kolom input terlebih dahulu!",
      );
      return;
    }

    // 2. Validasi nomor telepon (11 - 14 digit)
    final String phoneDigits = telpController.text.replaceAll(RegExp(r'\D'), '');
    if (phoneDigits.length < 11 || phoneDigits.length > 14) {
      showNotification(
        context,
        "Nomor telepon harus terdiri dari 11 - 14 digit angka!",
      );
      return;
    }

    // 3. Validasi panjang password
    if (passwordController.text.trim().length < 6) {
      showNotification(
        context,
        "Password minimal harus 6 karakter!",
      );
      return;
    }

    setState(() => isLoading = true);

    FirebaseApp? secondaryApp;

    try {
      secondaryApp = await Firebase.initializeApp(
        name: 'SecondaryApp',
        options: Firebase.app().options,
      );

      final secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);

      final userCredential = await secondaryAuth.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      final uid = userCredential.user!.uid;

      // Gabungkan kode plat dropdown + nomor & huruf belakang
      final String fullPlat = '$selectedKodePlat ${platRestController.text.trim().toUpperCase()}';

      // Format KM dengan akhiran " KM"
      final String rawKm = kmController.text.trim();
      final String formattedKm = rawKm.endsWith('KM') ? rawKm : '$rawKm KM';

      // Simpan data pelanggan pakai UID sebagai document ID
      await FirebaseFirestore.instance.collection('pelanggan').doc(uid).set({
        'nama': namaController.text.trim(),
        'email': emailController.text.trim(),
        'telepon': telpController.text.trim(),
        'plat': fullPlat,
        'kendaraan': kendaraanController.text.trim(),
        'km': formattedKm,
        'role': 'Pelanggan',
        'created_at': Timestamp.now(),
      });

      // Logout dari secondary auth & hapus instance-nya
      await secondaryAuth.signOut();
      await secondaryApp.delete();

      if (!mounted) return;

      showNotification(
        context,
        "Data & akun pelanggan berhasil disimpan!",
        isError: false,
      );

      Navigator.pop(context);

    } on FirebaseAuthException catch (e) {
      String pesan;
      switch (e.code) {
        case 'email-already-in-use':
          pesan = "Email sudah terdaftar, silakan gunakan email lain";
          break;
        case 'invalid-email':
          pesan = "Format email tidak valid";
          break;
        case 'weak-password':
          pesan = "Password terlalu lemah";
          break;
        default:
          pesan = "Gagal membuat akun: ${e.message}";
      }

      if (secondaryApp != null) await secondaryApp.delete();

      if (!mounted) return;
      showNotification(context, pesan);

    } catch (e) {
      if (secondaryApp != null) await secondaryApp.delete();

      if (!mounted) return;
      showNotification(context, "Terjadi kesalahan: $e");
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

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
                    "Tambah Pelanggan Baru",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: isLoading ? null : () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  )
                ],
              ),

              const SizedBox(height: 20),

              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      buildInput(
                        "Nama Lengkap *",
                        "Masukkan nama lengkap pelanggan",
                        namaController,
                      ),
                      buildInput(
                        "Email *",
                        "contoh@email.com",
                        emailController,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      buildPasswordInput(),
                      buildInput(
                        "Nomor Telepon *",
                        "081234567890 (11-14 digit)",
                        telpController,
                        keyboardType: TextInputType.phone,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[\d+]')),
                        ],
                      ),
                      buildPlatInput(),
                      buildInput(
                        "Nama Kendaraan *",
                        "Avanza / Xpander",
                        kendaraanController,
                      ),
                      buildInput(
                        "KM Terakhir *",
                        "Contoh: 24.000",
                        kmController,
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

              // BUTTON
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: isLoading ? null : () => Navigator.pop(context),
                    child: const Text("Batal"),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: isLoading ? null : simpanData,
                    icon: isLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.save),
                    label: Text(isLoading ? "Menyimpan..." : "Simpan"),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget buildPlatInput() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Nomor Plat *", style: TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(height: 5),
          Row(
            children: [
              // Dropdown Kode Wilayah Plat
              SizedBox(
                width: 95,
                child: DropdownButtonFormField<String>(
                  value: selectedKodePlat,
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
                      setState(() => selectedKodePlat = val);
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              // Input Manual Angka & Huruf Belakang
              Expanded(
                child: TextField(
                  controller: platRestController,
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
    String hint,
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
              hintText: hint,
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

  Widget buildPasswordInput() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Password *", style: TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(height: 5),
          TextField(
            controller: passwordController,
            obscureText: obscurePassword,
            decoration: InputDecoration(
              hintText: "Minimal 6 karakter",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  obscurePassword ? Icons.visibility_off : Icons.visibility,
                ),
                onPressed: () {
                  setState(() => obscurePassword = !obscurePassword);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}