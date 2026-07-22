import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class TambahManajemenAkunPage extends StatefulWidget {
  const TambahManajemenAkunPage({super.key});

  @override
  State<TambahManajemenAkunPage> createState() =>
      _TambahManajemenAkunPageState();
}

class _TambahManajemenAkunPageState
    extends State<TambahManajemenAkunPage> {

  // ================= CONTROLLER =================

  final TextEditingController namaController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController konfirmasiPasswordController = TextEditingController();

  String selectedRole = "admin";

  bool isLoading = false;
  bool obscurePassword = true;
  bool obscureKonfirmasiPassword = true;

  // ================= SIMPAN DATA =================

  Future<void> simpanData() async {

    // VALIDASI FIELD KOSONG
    if (namaController.text.trim().isEmpty ||
        emailController.text.trim().isEmpty ||
        passwordController.text.trim().isEmpty ||
        konfirmasiPasswordController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Semua field harus diisi")),
      );
      return;
    }

    // VALIDASI KONFIRMASI PASSWORD
    if (passwordController.text != konfirmasiPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Konfirmasi password tidak sama")),
      );
      return;
    }

    setState(() => isLoading = true);

    try {

      // ================= FIREBASE AUTH =================
      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      // ================= FIRESTORE =================
      // CATATAN: password TIDAK disimpan di Firestore
        await FirebaseFirestore.instance
        .collection('manajemen_akun')
        .doc(credential.user!.uid)
        .set({
        'uid': credential.user!.uid,
        'nama': namaController.text.trim(),
        'email': emailController.text.trim(),
        'role': selectedRole,
        'created_at': Timestamp.now(),
      });
      if (selectedRole == 'montir') {
        final montirDoc = await FirebaseFirestore.instance
            .collection('montir')
            .where(
              'nama',
              isEqualTo: namaController.text.trim(),
            )
            .limit(1)
            .get();

        if (montirDoc.docs.isNotEmpty) {
          await FirebaseFirestore.instance
              .collection('montir')
              .doc(montirDoc.docs.first.id)
              .update({
            'uid_akun': credential.user!.uid,
          });
        }
}
      if (!mounted) return;

      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Akun berhasil ditambahkan")),
      );

    } on FirebaseAuthException catch (e) {

      String message = "Terjadi kesalahan";

      if (e.code == 'email-already-in-use') {
        message = "Email sudah digunakan";
      } else if (e.code == 'weak-password') {
        message = "Password terlalu lemah (minimal 6 karakter)";
      } else if (e.code == 'invalid-email') {
        message = "Format email tidak valid";
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );

    } catch (e) {

      debugPrint("ERROR TAMBAH AKUN: $e");

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }

    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {

    return AlertDialog(

      title: const Text("Tambah Akun"),

      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [

            // ================= NAMA =================
            TextField(
              controller: namaController,
              decoration: InputDecoration(
                labelText: "Nama",
                hintText: "Contoh: Intan",
                prefixIcon: const Icon(Icons.person_outline),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),

            const SizedBox(height: 15),

            // ================= EMAIL =================
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: "Email",
                hintText: "Contoh: intan@gmail.com",
                prefixIcon: const Icon(Icons.email_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),

            const SizedBox(height: 15),

            // ================= PASSWORD =================
            

            DropdownButtonFormField<String>(
            initialValue: selectedRole,
            decoration: InputDecoration(
              labelText: "Role",
              prefixIcon: const Icon(Icons.badge_outlined),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            items: const [
              DropdownMenuItem(
                value: "admin",
                child: Text("Admin"),
              ),
              DropdownMenuItem(
                value: "montir",
                child: Text("Montir"),
              ),
            ],
            onChanged: (value) {
              setState(() {
                selectedRole = value!;
              });
            },
          ),


            const SizedBox(height: 15),

              TextField(
                controller: passwordController,
                obscureText: obscurePassword,
                decoration: InputDecoration(
                  labelText: "Password",
                  hintText: "Minimal 6 karakter",
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      obscurePassword ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() {
                        obscurePassword = !obscurePassword;
                      });
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),

              const SizedBox(height: 15),

            // ================= KONFIRMASI PASSWORD =================
            TextField(
              controller: konfirmasiPasswordController,
              obscureText: obscureKonfirmasiPassword,
              decoration: InputDecoration(
                labelText: "Konfirmasi Password",
                hintText: "Ulangi password",
                prefixIcon: const Icon(Icons.lock_reset),
                suffixIcon: IconButton(
                  icon: Icon(
                    obscureKonfirmasiPassword ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: () {
                    setState(() {
                      obscureKonfirmasiPassword = !obscureKonfirmasiPassword;
                    });
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),

      actions: [
        Padding(
          padding: const EdgeInsets.only(left: 15, right: 15, bottom: 15),
          child: Row(
            children: [

              // ================= BATAL =================
              Expanded(
                child: SizedBox(
                  height: 45,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      foregroundColor: Colors.white,
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      "Batal",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 15),

              // ================= SIMPAN =================
              Expanded(
                child: SizedBox(
                  height: 45,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    onPressed: isLoading ? null : simpanData,
                    icon: isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.save, size: 18),
                    label: Text(
                      isLoading ? "Loading..." : "Simpan",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}