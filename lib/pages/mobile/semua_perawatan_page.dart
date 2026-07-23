import 'package:flutter/material.dart';
import 'detail_perawatan_page.dart';

class SemuaPerawatanPage extends StatelessWidget {
  final List<Map<String, dynamic>> daftarLayanan;

  const SemuaPerawatanPage({super.key, required this.daftarLayanan});

  String _kategoriLayanan(String title) {
    switch (title) {
      case "Tune Up & Scanning":
      case "Ganti Oli & Filter":
      case "Service AC Mobil":
        return "Rutin";
      case "Service Rem 4 Roda":
      case "Service Kaki-kaki":
      case "Spooring & Balancing":
        return "Rem & Sasis";
      case "Service Kopling":
      case "Ganti Timing Belt":
      case "Overhaul Mesin":
      case "Overhaul Transmisi (M)":
      case "Overhaul Transmisi (A)":
      case "Overhaul Gardan":
        return "Mesin";
      case "Electrical System":
      case "Body Repair & Detailing":
      default:
        return "Kelistrikan & Body";
    }
  }

  Widget _buildListLayanan(BuildContext context, List<Map<String, dynamic>> items) {
    if (items.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.category_outlined, size: 48, color: Colors.grey),
            SizedBox(height: 10),
            Text(
              "Tidak ada layanan di kategori ini",
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return Card(
          elevation: 2,
          shadowColor: Colors.black12,
          margin: const EdgeInsets.symmetric(vertical: 6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          color: Colors.white,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DetailPerawatanPage(dataLayanan: item),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  // Icon box with circular gradient
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.blue.shade50, Colors.blue.shade100],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(item["icon"], color: Colors.blue.shade800, size: 28),
                  ),
                  const SizedBox(width: 14),
                  // Title and Info Chips
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item["title"],
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 6),
                        // Chips row
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.amber.shade50,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: Colors.amber.shade200),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.access_time_filled, size: 10, color: Colors.amber.shade800),
                                  const SizedBox(width: 3),
                                  Text(
                                    item["estimasi"],
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.amber.shade900,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: Colors.green.shade200),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.account_balance_wallet, size: 10, color: Colors.green.shade800),
                                  const SizedBox(width: 3),
                                  Text(
                                    item["harga"].toString().split(' (')[0], // Trim info dalam kurung biar rapi
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.green.shade900,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Filter out Keluhan and Lainnya
    final listPerawatan = daftarLayanan.where((layanan) => 
      layanan["title"] != "Keluhan" && layanan["title"] != "Lainnya"
    ).toList();

    return DefaultTabController(
      length: 5,
      child: Scaffold(
        backgroundColor: Colors.grey.shade50,
        appBar: AppBar(
          title: const Text(
            "Jenis Perawatan",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          elevation: 0.5,
          bottom: const TabBar(
            isScrollable: true,
            labelColor: Colors.blue,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.blue,
            indicatorWeight: 3,
            labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            tabs: [
              Tab(text: "Semua"),
              Tab(text: "Rutin & AC"),
              Tab(text: "Rem & Sasis"),
              Tab(text: "Mesin"),
              Tab(text: "Lainnya"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildListLayanan(context, listPerawatan),
            _buildListLayanan(
              context,
              listPerawatan.where((layanan) => _kategoriLayanan(layanan["title"]) == "Rutin").toList(),
            ),
            _buildListLayanan(
              context,
              listPerawatan.where((layanan) => _kategoriLayanan(layanan["title"]) == "Rem & Sasis").toList(),
            ),
            _buildListLayanan(
              context,
              listPerawatan.where((layanan) => _kategoriLayanan(layanan["title"]) == "Mesin").toList(),
            ),
            _buildListLayanan(
              context,
              listPerawatan.where((layanan) => _kategoriLayanan(layanan["title"]) == "Kelistrikan & Body").toList(),
            ),
          ],
        ),
      ),
    );
  }
}