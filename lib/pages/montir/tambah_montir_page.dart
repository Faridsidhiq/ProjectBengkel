import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TambahMontirPage extends StatefulWidget {
  const TambahMontirPage({super.key});

  @override
  State<TambahMontirPage> createState() => _TambahMontirPageState();
}

class _TambahMontirPageState extends State<TambahMontirPage> {
  final _formKey = GlobalKey<FormState>();

  final namaController = TextEditingController();
  final telpController = TextEditingController();
  final spesialisController = TextEditingController();

  String selectedStatus = "Aktif";

  Future<void> simpanData() async {
    // Validasi form dulu (termasuk validasi nomor telepon)
    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {
      await FirebaseFirestore.instance.collection('montir').add({
        'nama': namaController.text.trim(),
        'telp': telpController.text.trim(),
        'spesialis': spesialisController.text.trim(),
        'status': selectedStatus,
        'uid_akun': '',
        'created_at': Timestamp.now(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Data montir berhasil disimpan")),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  @override
  void dispose() {
    namaController.dispose();
    telpController.dispose();
    spesialisController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // HEADER
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Tambah Data Montir Baru",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  )
                ],
              ),

              const SizedBox(height: 20),

              buildInput(
                "Nama Lengkap Montir *",
                "Masukkan nama",
                namaController,
              ),

              buildInput(
                "Nomor Telepon *",
                "081234567890",
                telpController,
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(13),
                ],
                validator: (value) {
                  final v = value?.trim() ?? '';
                  if (v.isEmpty) {
                    return "Nomor telepon wajib diisi";
                  }
                  if (v.length < 10) {
                    return "Nomor telepon minimal 10 digit";
                  }
                  if (v.length > 13) {
                    return "Nomor telepon maksimal 13 digit";
                  }
                  return null;
                },
              ),

              buildInput(
                "Spesialisasi *",
                "Engine Specialist",
                spesialisController,
              ),

              // STATUS
              buildStatus(),

              const SizedBox(height: 25),

              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Batal"),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: simpanData,
                      icon: const Icon(Icons.save),
                      label: const Text("Simpan Data"),
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget buildInput(
    String label,
    String hint,
    TextEditingController controller, {
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label),
          const SizedBox(height: 5),
          TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            inputFormatters: inputFormatters,
            validator: validator ??
                (value) {
                  if (value == null || value.trim().isEmpty) {
                    return "$label tidak boleh kosong";
                  }
                  return null;
                },
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

  Widget buildStatus() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Status Montir *"),
          const SizedBox(height: 5),
          DropdownButtonFormField<String>(
            initialValue: selectedStatus,
            items: ["Aktif", "Libur", "Tidak Aktif"]
                .map((status) => DropdownMenuItem(
                      value: status,
                      child: Text(status),
                    ))
                .toList(),
            onChanged: (value) {
              setState(() {
                selectedStatus = value!;
              });
            },
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}