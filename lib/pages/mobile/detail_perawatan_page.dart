import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class DetailPerawatanPage extends StatelessWidget {
  final Map<String, dynamic> dataLayanan;

  const DetailPerawatanPage({super.key, required this.dataLayanan});

  Future<void> _hubungiWhatsApp(BuildContext context, String namaLayanan) async {
    final String message = "Halo Admin Jimu Mitsubishi, saya tertarik untuk memesan/bertanya mengenai layanan *$namaLayanan* untuk kendaraan saya. Mohon info jadwal servis yang tersedia. Terima kasih!";
    final Uri url = Uri.parse("https://wa.me/6285269864232?text=${Uri.encodeComponent(message)}");
    
    try {
      bool launched = await launchUrl(url, mode: LaunchMode.externalApplication);
      if (!launched && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Tidak dapat membuka WhatsApp")),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Tidak dapat membuka WhatsApp")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<String> pekerjaan = List<String>.from(dataLayanan["pekerjaan"] ?? []);
    final String title = dataLayanan["title"] ?? "Detail Perawatan";

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. ILLUSTRASI UTAMA / ICON HEADER
            Container(
              width: double.infinity,
              height: 180,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade800, Colors.blue.shade500],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Center(
                child: dataLayanan["image"] != null && 
                       dataLayanan["image"] != "assets/manual.png" && 
                       !dataLayanan["image"].toString().contains("placeholder")
                    ? Image.asset(
                        dataLayanan["image"],
                        height: 120,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(dataLayanan["icon"] ?? Icons.build_circle, size: 80, color: Colors.white);
                        },
                      )
                    : Icon(dataLayanan["icon"] ?? Icons.build_circle, size: 85, color: Colors.white),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 2. DESKRIPSI LAYANAN
                  const Text(
                    "Deskripsi Layanan",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    dataLayanan["deskripsi"] ?? "Penjelasan mengenai layanan perawatan.",
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade700,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.justify,
                  ),
                  const SizedBox(height: 20),

                  // 3. INFORMASI ESTIMASI & BIAYA (2x2 GRID)
                  const Text(
                    "Informasi Perawatan",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87),
                  ),
                  const SizedBox(height: 10),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    childAspectRatio: 2.2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    children: [
                      _buildGridInfo(Icons.access_time_filled, "Estimasi Waktu", dataLayanan["estimasi"], Colors.orange),
                      _buildGridInfo(Icons.verified, "Garansi", dataLayanan["garansi"], Colors.green),
                      _buildGridInfo(Icons.loop, "Interval Servis", dataLayanan["interval"], Colors.purple),
                      _buildGridInfo(Icons.account_balance_wallet, "Estimasi Biaya", dataLayanan["harga"], Colors.blue),
                    ],
                  ),
                  const SizedBox(height: 25),

                  // 4. BAGIAN PEKERJAAN YANG DILAKUKAN
                  if (pekerjaan.isNotEmpty) ...[
                    const Text(
                      "Pekerjaan yang Dilakukan",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: pekerjaan.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                margin: const EdgeInsets.only(top: 2),
                                child: const Icon(
                                  Icons.check_circle,
                                  color: Colors.green,
                                  size: 16,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  pekerjaan[index],
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Colors.black87,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 30),
                  ],

                  // 5. TOMBOL HUBUNGI VIA WA (CTA)
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade600,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 1,
                      ),
                      onPressed: () => _hubungiWhatsApp(context, title),
                      icon: const Icon(Icons.phone, size: 18),
                      label: const Text(
                        "Tanyakan / Pesan via WhatsApp",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGridInfo(IconData icon, String label, String value, MaterialColor color) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 1, offset: Offset(0, 1)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color.shade700, size: 16),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade500, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}