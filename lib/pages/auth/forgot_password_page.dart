import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final TextEditingController emailController = TextEditingController();

  bool isLoading = false;
  bool emailTerkirim = false;

  Future<void> kirimLinkReset() async {
    final String inputEmail = emailController.text.trim();

    if (inputEmail.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Email tidak boleh kosong")),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      // 1. Cek apakah email terdaftar di Firestore (koleksi 'pelanggan' & 'manajemen_akun')
      final QuerySnapshot pelangganQuery = await FirebaseFirestore.instance
          .collection('pelanggan')
          .where('email', isEqualTo: inputEmail)
          .limit(1)
          .get();

      bool isRegistered = pelangganQuery.docs.isNotEmpty;

      if (!isRegistered) {
        final QuerySnapshot pelangganQueryLower = await FirebaseFirestore.instance
            .collection('pelanggan')
            .where('email', isEqualTo: inputEmail.toLowerCase())
            .limit(1)
            .get();
        if (pelangganQueryLower.docs.isNotEmpty) {
          isRegistered = true;
        }
      }

      if (!isRegistered) {
        final QuerySnapshot manajemenQuery = await FirebaseFirestore.instance
            .collection('manajemen_akun')
            .where('email', isEqualTo: inputEmail)
            .limit(1)
            .get();

        if (manajemenQuery.docs.isNotEmpty) {
          isRegistered = true;
        } else {
          final QuerySnapshot manajemenQueryLower = await FirebaseFirestore.instance
              .collection('manajemen_akun')
              .where('email', isEqualTo: inputEmail.toLowerCase())
              .limit(1)
              .get();
          if (manajemenQueryLower.docs.isNotEmpty) {
            isRegistered = true;
          }
        }
      }

      // 2. Jika email tidak terdaftar di Firestore, tampilkan pesan error
      if (!isRegistered) {
        setState(() => isLoading = false);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Email tidak terdaftar! Silakan periksa kembali email Anda."),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // 4. Email terdaftar, kirim link reset password
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: inputEmail,
      );

      setState(() {
        isLoading = false;
        emailTerkirim = true; // ← tampilkan pesan sukses
      });
    } on FirebaseAuthException catch (e) {
      setState(() => isLoading = false);
      if (!mounted) return;

      String pesanError;
      switch (e.code) {
        case 'user-not-found':
          pesanError = "Email tidak terdaftar dalam sistem.";
          break;
        case 'invalid-email':
          pesanError = "Format email tidak valid.";
          break;
        case 'too-many-requests':
          pesanError = "Terlalu banyak permintaan. Silakan coba lagi nanti.";
          break;
        default:
          pesanError = e.message ?? "Gagal mengirimkan link reset password.";
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(pesanError), backgroundColor: Colors.red),
      );
    } catch (e) {
      setState(() => isLoading = false);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Terjadi kesalahan: $e"), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 🔥 RESPONSIF: deteksi lebar layar pakai LayoutBuilder
      body: LayoutBuilder(
        builder: (context, constraints) {
          final bool isMobile = constraints.maxWidth < 800;

          return Row(
            children: [
              // 🔵 KIRI - Logo, disembunyikan kalau layar sempit
              if (!isMobile)
                Expanded(
                  child: Container(
                    color: Colors.grey[200],
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset('assets/logo.png', width: 200),
                        const SizedBox(height: 20),
                        const Text(
                          "JIMU MITSUBISHI",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          "Sistem Manajemen Bengkel untuk Pelayanan Terbaik",
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),

              // ⚪ KANAN - Form, full width kalau mobile
              Expanded(
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 30 : 60,
                  ),
                  child: Center(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 🔥 Logo kecil muncul di atas form kalau mobile
                          if (isMobile) ...[
                            Center(
                              child: Image.asset(
                                'assets/logo.png',
                                width: 120,
                              ),
                            ),
                            const SizedBox(height: 20),
                          ],

                          emailTerkirim ? _buildSukses() : _buildForm(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // TAMPILAN FORM INPUT EMAIL
  Widget _buildForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Lupa Password",
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
        ),

        const SizedBox(height: 8),

        const Text(
          "Masukkan email akun kamu, kami akan kirim link reset password ke email tersebut.",
        ),

        const SizedBox(height: 30),

        const Text("Email"),

        const SizedBox(height: 8),

        TextField(
          controller: emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            hintText: "Contoh: admin@gmail.com",
            prefixIcon: const Icon(Icons.email_outlined),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),

        const SizedBox(height: 30),

        SizedBox(
          width: double.infinity,
          height: 45,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[800],
              foregroundColor: Colors.white,
            ),
            onPressed: isLoading ? null : kirimLinkReset,
            child: isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text("Kirim Link Reset Password"),
          ),
        ),

        const SizedBox(height: 20),

        Center(
          child: TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Kembali ke Login"),
          ),
        ),
      ],
    );
  }

  // TAMPILAN SETELAH EMAIL TERKIRIM
  Widget _buildSukses() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(
          Icons.mark_email_read_outlined,
          size: 80,
          color: Colors.green,
        ),

        const SizedBox(height: 20),

        const Text(
          "Email Terkirim!",
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),

        const SizedBox(height: 12),

        Text(
          "Link reset password sudah dikirim ke:\n${emailController.text.trim()}",
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 8),

        const Text(
          "Cek inbox atau folder spam email kamu.",
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey),
        ),

        const SizedBox(height: 30),

        SizedBox(
          width: double.infinity,
          height: 45,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[800],
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context),
            child: const Text("Kembali ke Login"),
          ),
        ),
      ],
    );
  }
}