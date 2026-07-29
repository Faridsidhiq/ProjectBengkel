import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'forgot_password_page.dart';
import '../dashboard/dashboard_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  Future<void> loginUser() async {
    if (emailController.text.trim().isEmpty || passwordController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Email dan Kata Sandi tidak boleh kosong!")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );
      
      // Catatan: Pengecekan peran dan navigasi sekarang ditangani 
      // secara otomatis oleh AuthWrapper di main.dart

    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      String pesanError;
      switch (e.code) {
        case 'user-not-found':
        case 'wrong-password':
        case 'invalid-credential':
          pesanError = "Email atau kata sandi salah";
          break;
        case 'invalid-email':
          pesanError = "Format email tidak valid";
          break;
        case 'user-disabled':
          pesanError = "Akun ini telah dinonaktifkan";
          break;
        case 'too-many-requests':
          pesanError = "Terlalu banyak percobaan. Silakan coba lagi nanti";
          break;
        default:
          pesanError = "Email atau kata sandi salah";
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(pesanError), backgroundColor: Colors.red),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Login gagal: $e")),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
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
              // 🔵 LEFT — disembunyikan kalau layar sempit
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

              // ⚪ RIGHT — form login, full width kalau mobile
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

                          const Text(
                            "Selamat Datang",
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            "Silahkan masuk untuk mengelola dashboard admin",
                          ),
                          const SizedBox(height: 30),

                          // EMAIL
                          const Text("Alamat Email"),
                          const SizedBox(height: 8),
                          TextField(
                            controller: emailController,
                            textInputAction: TextInputAction.next,
                            onSubmitted: (_) => loginUser(),
                            decoration: InputDecoration(
                              hintText: "nama@email.com",
                              prefixIcon: const Icon(Icons.email),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),

                          const SizedBox(height: 20),

                          // PASSWORD
                          const Text("Kata Sandi"),
                          const SizedBox(height: 8),
                          TextField(
                            controller: passwordController,
                            obscureText: _obscurePassword,
                            textInputAction: TextInputAction.done,
                            onSubmitted: (_) => loginUser(),
                            decoration: InputDecoration(
                              hintText: "masukan password",
                              prefixIcon: const Icon(Icons.lock),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),

                          const SizedBox(height: 20),

                          // BUTTON LOGIN
                          SizedBox(
                            width: double.infinity,
                            height: 45,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue[800],
                                foregroundColor: Colors.white,
                              ),
                              onPressed: _isLoading ? null : loginUser,
                              child: _isLoading 
                                  ? const SizedBox(
                                      width: 20, 
                                      height: 20, 
                                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                                    )
                                  : const Text("Masuk"),
                            ),
                          ),

                          const SizedBox(height: 20),

                          // LUPA PASSWORD
                          Center(
                            child: TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const ForgotPasswordPage(),
                                  ),
                                );
                              },
                              child: const Text("Lupa Password?"),
                            ),
                          ),
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
}