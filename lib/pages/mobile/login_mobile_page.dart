import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'register_mobile_page.dart';
import 'dashboard_mobile_page.dart';
import 'dashboard_montir_page.dart';
import '../auth/forgot_password_page.dart';

class LoginMobilePage extends StatefulWidget {
  const LoginMobilePage({super.key});

  @override
  State<LoginMobilePage> createState() => _LoginMobilePageState();
}

class _LoginMobilePageState extends State<LoginMobilePage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool isLoading = false;
  bool obscurePassword = true;

  Future<void> loginUser() async {
    if (emailController.text.trim().isEmpty || passwordController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Email dan Kata Sandi tidak boleh kosong!")),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      // 1. Proses Login Utama ke Firebase Authentication
      UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      String uid = userCredential.user!.uid;

      // ================= 1. CEK KOLEKSI 'pelanggan' =================
      // PERBAIKAN: Mengubah pencarian dari 'users' menjadi 'pelanggan'
      DocumentSnapshot pelangganDoc = await FirebaseFirestore.instance
          .collection('pelanggan')
          .doc(uid)
          .get();

      if (!mounted) return;

      if (pelangganDoc.exists) {
        String role = pelangganDoc.get('role') ?? '';
        
        // PERBAIKAN: Menggunakan .toLowerCase() agar kebal terhadap salah ketik huruf besar/kecil
        if (role.toLowerCase() == 'pelanggan') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Login Sukses Sebagai Pelanggan!"),
              backgroundColor: Colors.green,
            ),
          );

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => const DashboardMobilePage(),
            ),
          );
          return;
        }
      }

      // ================= 2. CEK KOLEKSI 'manajemen_akun' (MONTIR / ADMIN LAIN) =================
      DocumentSnapshot montirDoc = await FirebaseFirestore.instance
          .collection('manajemen_akun')
          .doc(uid)
          .get();

      if (!mounted) return;
      
      if (montirDoc.exists) {
        String role = montirDoc.get('role') ?? '';

        if (role.toLowerCase() == 'montir') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Login Sukses Sebagai Montir!"),
              backgroundColor: Colors.blue,
            ),
          );

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => const DashboardMontirPage(),
            ),
          );
          return;
        } else if (role.toLowerCase() == 'admin') {
          // 🛑 Antisipasi jika admin login di aplikasi mobile, beri peringatan atau arahkan ke halaman khusus
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Akun Admin silakan gunakan sistem Web!"),
              backgroundColor: Colors.orange,
            ),
          );
          await FirebaseAuth.instance.signOut(); // Logout otomatis karena salah tempat login
          return;
        }
      }

      // ================= 3. DATA DIDAPAT TAPI ROLE TIDAK COCOK / KOSONG =================
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Akses Ditolak: Peran akun tidak dikenali!"),
          backgroundColor: Colors.red,
        ),
      );
      await FirebaseAuth.instance.signOut();

    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Login gagal: $e"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Column(
                    children: [
                      Image.asset('assets/logo.png', width: 300), 
                      const SizedBox(height: 15),
                      const Text(
                        "JIMU MITSUBISHI",
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "Sistem Manajemen Bengkel untuk Pelayanan Terbaik",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.black87, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 100), 
                const Text(
                  "Selamat Datang",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold), 
                ),
                const SizedBox(height: 4),
                const Text(
                  "Silahkan masuk untuk mengelola aplikasi mobile",
                  style: TextStyle(color: Colors.black54, fontSize: 13), 
                ),
                const SizedBox(height: 20), 
                const Text(
                  "Alamat Email", 
                  style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13), 
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  onSubmitted: (_) => loginUser(),
                  style: const TextStyle(fontSize: 14), 
                  decoration: InputDecoration(
                    hintText: "nama@email.com",
                    prefixIcon: const Icon(Icons.email, size: 20), 
                    contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12), 
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 14), 
                const Text(
                  "Kata Sandi", 
                  style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13), 
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: passwordController,
                  obscureText: obscurePassword,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => loginUser(),
                  style: const TextStyle(fontSize: 14),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.lock, size: 20),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscurePassword ? Icons.visibility_off : Icons.visibility,
                        size: 20,
                        color: Colors.grey,
                      ),
                      onPressed: () {
                        setState(() {
                          obscurePassword = !obscurePassword;
                        });
                      },
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12), 
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 20), 
                SizedBox(
                  width: double.infinity,
                  height: 42, 
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[800],
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: isLoading ? null : loginUser,
                    child: isLoading 
                        ? const SizedBox(
                            width: 18, 
                            height: 18, 
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                          )
                        : const Text("Masuk", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)), 
                  ),
                ),
                const SizedBox(height: 10), 
                Center(
                  child: TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const ForgotPasswordPage()),
                      );
                    },
                    style: TextButton.styleFrom(padding: EdgeInsets.zero), 
                    child: Text(
                      "Lupa Password?",
                      style: TextStyle(color: Colors.grey[700], fontSize: 13),
                    ),
                  ),
                ),
                const SizedBox(height: 10), 
                Center(
                  child: TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const RegisterMobilePage()),
                      );
                    },
                    style: TextButton.styleFrom(padding: EdgeInsets.zero), 
                    child: Text(
                      "Belum punya akun? Daftar disini",
                      style: TextStyle(color: Colors.blue[800], fontSize: 13),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}