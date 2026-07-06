import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

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
  final platController = TextEditingController();
  final kendaraanController = TextEditingController();
  final kmController = TextEditingController();

  bool isLoading = false;
  bool obscurePassword = true;

  Future<void> simpanData() async {

    if (namaController.text.trim().isEmpty ||
        emailController.text.trim().isEmpty ||
        passwordController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Nama, Email, dan Password wajib diisi")),
      );
      return;
    }

    if (passwordController.text.trim().length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Password minimal 6 karakter")),
      );
      return;
    }

    setState(() => isLoading = true);

    // 👇 PAKAI SECONDARY APP biar sesi login admin nggak ke-replace
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

      // Simpan data pelanggan pakai UID sebagai document ID
      await FirebaseFirestore.instance.collection('pelanggan').doc(uid).set({
        'nama': namaController.text.trim(),
        'email': emailController.text.trim(),
        'telepon': telpController.text.trim(),
        'plat': platController.text.trim(),
        'kendaraan': kendaraanController.text.trim(),
        'km': kmController.text.trim(),
        'role': 'Pelanggan',
        'created_at': Timestamp.now(),
      });

      // Logout dari secondary auth & hapus instance-nya
      await secondaryAuth.signOut();
      await secondaryApp.delete();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Data & akun login berhasil dibuat")),
      );

      Navigator.pop(context);

    } on FirebaseAuthException catch (e) {
      String pesan;
      switch (e.code) {
        case 'email-already-in-use':
          pesan = "Email sudah terdaftar, pakai email lain";
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(pesan)),
      );

    } catch (e) {
      if (secondaryApp != null) await secondaryApp.delete();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
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
                      buildInput("Nama Lengkap *", "Masukkan nama lengkap pelanggan", namaController),
                      buildInput("Email *", "contoh@email.com", emailController),
                      buildPasswordInput(),
                      buildInput("Nomor Telepon *", "+62 812345678", telpController),
                      buildInput("Nomor Plat *", "B 1234 ABC", platController),
                      buildInput("Nama Kendaraan *", "Avanza / Xpander", kendaraanController),
                      buildInput("KM Terakhir *", "24.000 KM", kmController),
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

  Widget buildInput(String label, String hint, TextEditingController controller) {
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
              hintText: hint,
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
          const Text("Password *"),
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