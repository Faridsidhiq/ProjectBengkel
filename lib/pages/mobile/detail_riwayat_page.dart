import 'package:flutter/material.dart';

class DetailRiwayatPage extends StatelessWidget {
  final Map<String, dynamic> data;

  const DetailRiwayatPage({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text("Detail Servis Selesai", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87)),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(color: Colors.grey.shade200, blurRadius: 8, offset: const Offset(0, 4)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // BAGIAN ATAS: PLAT & STATUS
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.directions_car, color: Colors.blue.shade700, size: 22),
                        const SizedBox(width: 8),
                        Text(
                          data['plat'] ?? 'Tanpa Plat',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.blue.shade900),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.green.shade100,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        "✓ Selesai",
                        style: TextStyle(color: Colors.green.shade800, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
              
              // BAGIAN TENGAH: DETAIL KENDARAAN & KELUHAN
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailRow(Icons.branding_watermark, "Kendaraan", data['kendaraan'] ?? 'Tidak Diketahui'),
                    const SizedBox(height: 16),
                    _buildDetailRow(Icons.build_circle, "Jenis Servis", data['jenis_servis']?.toString() ?? 'Servis Umum'),
                    const SizedBox(height: 16),
                    _buildDetailRow(Icons.person, "Mekanik", data['nama_montir'] ?? '-'),
                    const SizedBox(height: 20),
                    
                    // Garis Pembatas Putus-putus
                    Row(
                      children: List.generate(
                        40,
                        (index) => Expanded(
                          child: Container(
                            color: index % 2 == 0 ? Colors.grey.shade300 : Colors.transparent,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    const Text("Catatan / Keluhan Awal:", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black54)),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade200)
                      ),
                      child: Text(
                        data['keluhan'] ?? 'Tidak ada catatan tambahan',
                        style: const TextStyle(fontSize: 14, height: 1.5, color: Colors.black87),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget pembantu untuk baris informasi
  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Colors.grey.shade500),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
              const SizedBox(height: 4),
              Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Colors.black87)),
            ],
          ),
        )
      ],
    );
  }
}