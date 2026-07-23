import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RegisterMobilePage extends StatefulWidget {
  const RegisterMobilePage({super.key});

  @override
  State<RegisterMobilePage> createState() => _RegisterMobilePageState();
}

class _RegisterMobilePageState extends State<RegisterMobilePage> {
  // ================= CONTROLLER INPUT FORM =================
  final TextEditingController _namaController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _telpController = TextEditingController();
  final TextEditingController _platNumberController = TextEditingController();
  final TextEditingController _kendaraanController = TextEditingController();
  final TextEditingController _kmController = TextEditingController(); // Controller Baru untuk KM
  final TextEditingController _passwordController = TextEditingController();

  String _selectedPlatPrefix = "BE";
  final List<String> _platPrefixes = [
    "BE", "B", "D", "A", "AB", "AD", "L", "N", "DK", "BG", "BH", "BK", "BM", "BP", "BD", "BA", "KB", "DA", "KH", "KT", "DD", "PA"
  ];

  bool _isLoading = false;
  bool _obscurePassword = true;

  // ====================================================================
  // FUNGSI UTAMA: DAFTAR AKUN AUTH + SIMPAN KE DATABASE ADMIN
  // ====================================================================
  Future<void> _prosesRegistrasiPelanggan() async {
    // 1. Validasi: KM tidak dimasukkan ke dalam pengecekan ini karena sifatnya Opsional
    if (_namaController.text.trim().isEmpty ||
        _emailController.text.trim().isEmpty ||
        _telpController.text.trim().isEmpty ||
        _platNumberController.text.trim().isEmpty ||
        _kendaraanController.text.trim().isEmpty ||
        _passwordController.text.trim().isEmpty) {
      _showSnackbar("Selain KM, seluruh form wajib diisi untuk keperluan data Bengkel!", isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 2. Mendaftarkan akun di sistem Firebase Authentication
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final String userUid = userCredential.user!.uid;
      final String platLengkap = "$_selectedPlatPrefix ${_platNumberController.text.trim()}".toUpperCase();

      // 3. Menyimpan Biodata Pelanggan ke tabel 'pelanggan' milik Admin
      await FirebaseFirestore.instance
          .collection('pelanggan')
          .doc(userUid)
          .set({
        'id': userUid, 
        'uid_akun': userUid, 
        'nama': _namaController.text.trim(),
        'email': _emailController.text.trim().toLowerCase(),
        'telepon': _telpController.text.trim(),
        'plat': platLengkap, 
        'kendaraan': _kendaraanController.text.trim(),
        // Logika KM opsional: Jika diisi maka simpan angkanya, jika kosong simpan '-'
        'km': _kmController.text.trim().isNotEmpty ? _kmController.text.trim() : '-', 
        'role': 'Pelanggan',
        'created_at': Timestamp.now(),
      });

      if (!mounted) return;

      _showSnackbar("Pendaftaran Berhasil! Data Anda sudah terhubung ke sistem Bengkel.", isError: false);
      
      // 4. Tutup halaman register dan kembali ke halaman Login
      Navigator.pop(context);

    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      String pesanError = "Terjadi kesalahan.";
      if (e.code == 'weak-password') {
        pesanError = "Password terlalu lemah (minimal 6 karakter).";
      } else if (e.code == 'email-already-in-use') {
        pesanError = "Email ini sudah terdaftar sebelumnya.";
      } else if (e.code == 'invalid-email') {
        pesanError = "Format email tidak valid.";
      }
      _showSnackbar(pesanError, isError: true);
    } catch (e) {
      if (!mounted) return;
      _showSnackbar("Gagal mendaftar: $e", isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackbar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  void dispose() {
    _namaController.dispose();
    _emailController.dispose();
    _telpController.dispose();
    _platNumberController.dispose();
    _kendaraanController.dispose();
    _kmController.dispose(); // Hapus controller memori KM
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text("Daftar Akun", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 8, offset: const Offset(0, 4))],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Lengkapi Data Kendaraan",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                const SizedBox(height: 4),
                const Text(
                  "Data yang Anda masukkan akan digunakan Admin bengkel untuk memproses SPK kendaraan Anda.",
                  style: TextStyle(fontSize: 12, color: Colors.grey, height: 1.4),
                ),
                const SizedBox(height: 24),

                _buildInputField("Nama Lengkap", "Masukkan nama sesuai KTP", _namaController, Icons.person),
                _buildInputField("Email Aktif", "contoh@email.com", _emailController, Icons.email, keyboardType: TextInputType.emailAddress),
                _buildInputField("Nomor Telepon / WA", "0812XXXXXXXX", _telpController, Icons.phone, keyboardType: TextInputType.phone),
                
                // Input Plat Nomor (Dropdown Prefix + Textfield Sisa)
                const Text("Nomor Plat Kendaraan", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black54)),
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedPlatPrefix,
                            icon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
                            items: _platPrefixes.map((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              if (newValue != null) {
                                setState(() {
                                  _selectedPlatPrefix = newValue;
                                });
                              }
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _platNumberController,
                          textCapitalization: TextCapitalization.characters,
                          decoration: InputDecoration(
                            hintText: "1234 ABC",
                            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                            prefixIcon: const Icon(Icons.badge, size: 20, color: Colors.grey),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade100,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                _buildInputField("Model Kendaraan", "Xpander Cross / Pajero Sport", _kendaraanController, Icons.directions_car),
                
                // Input KM Baru (Opsional)
                _buildInputField("Kilometer Kendaraan (Opsional)", "Contoh: 25000", _kmController, Icons.speed, keyboardType: TextInputType.number),
                
                // Input Password
                const Text("Password", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black54)),
                const SizedBox(height: 6),
                TextField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    hintText: "Minimal 6 karakter",
                    prefixIcon: const Icon(Icons.lock_outline, size: 20),
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, size: 20, color: Colors.grey),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  ),
                ),

                const SizedBox(height: 30),

                // Tombol Submit
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade800,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 2,
                    ),
                    onPressed: _isLoading ? null : _prosesRegistrasiPelanggan,
                    child: _isLoading
                        ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                        : const Text("DAFTAR SEKARANG", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 1)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Widget bantuan untuk membuat form input
  Widget _buildInputField(
    String label,
    String hint,
    TextEditingController controller,
    IconData icon, {
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black54)),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            keyboardType: keyboardType,
            textCapitalization: label.contains("Plat") ? TextCapitalization.characters : TextCapitalization.words,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
              prefixIcon: Icon(icon, size: 20, color: Colors.grey.shade600),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.grey.shade100,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            ),
          ),
        ],
      ),
    );
  }
}