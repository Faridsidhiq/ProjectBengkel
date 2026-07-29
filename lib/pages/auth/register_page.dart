import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {

  final TextEditingController namaController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController telpController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  Future<void> registerUser() async {
  try {
    await FirebaseAuth.instance.createUserWithEmailAndPassword(
      email: emailController.text.trim(),
      password: passwordController.text.trim(),
    );

    if (!mounted) return; // 🔥 FIX

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Register berhasil")),
    );

    Navigator.pop(context);

  } catch (e) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Register gagal: $e")),
    );
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [

          // 🔵 LEFT
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
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
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

          // ⚪ RIGHT
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 60),
              child: Center(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      const Text(
                        "Daftar Akun Baru",
                        style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "Silahkan lengkapi data untuk melakukan pembuatan akun baru.",
                      ),
                      const SizedBox(height: 30),

                      // NAMA
                      const Text("Nama Lengkap"),
                      const SizedBox(height: 8),
                      TextField(
                        controller: namaController,
                        decoration: InputDecoration(
                          hintText: "Contoh: Budi Santoso",
                          prefixIcon: const Icon(Icons.person),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // EMAIL
                      const Text("Alamat Email"),
                      const SizedBox(height: 8),
                      TextField(
                        controller: emailController,
                        decoration: InputDecoration(
                          hintText: "nama@email.com",
                          prefixIcon: const Icon(Icons.email),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // TELEPON
                      const Text("Nomor Telepon"),
                      const SizedBox(height: 8),
                      TextField(
                        controller: telpController,
                        decoration: InputDecoration(
                          hintText: "08123xxxx",
                          prefixIcon: const Icon(Icons.phone),
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
                        obscureText: true,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.lock),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),

                      const SizedBox(height: 30),

                      // 🔥 BUTTON REGISTER (SUDAH CONNECT FIREBASE)
                      SizedBox(
                        width: double.infinity,
                        height: 45,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue[800],
                            foregroundColor: Colors.white,
                          ),
                          onPressed: registerUser,
                          child: const Text("Daftar Sekarang"),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // LOGIN
                      Center(
                        child: TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: const Text("Sudah punya akun? Masuk"),
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}