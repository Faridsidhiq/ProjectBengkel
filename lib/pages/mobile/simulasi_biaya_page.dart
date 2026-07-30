import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class SimulasiBiayaPage extends StatefulWidget {
  final List<Map<String, dynamic>> daftarLayanan;

  const SimulasiBiayaPage({super.key, required this.daftarLayanan});

  @override
  State<SimulasiBiayaPage> createState() => _SimulasiBiayaPageState();
}

class _SimulasiBiayaPageState extends State<SimulasiBiayaPage> {
  // State untuk jasa yang dipilih
  final Set<String> _jasaTerpilih = {};

  // State untuk sparepart yang dipilih (ID -> Jumlah)
  final Map<String, int> _sparepartTerpilih = {};
  
  // Cache data sparepart (ID -> Data Map)
  final Map<String, Map<String, dynamic>> _dataSparepart = {};

  String _keywordSparepart = "";
  String _kategoriTerpilih = "Semua";
  final TextEditingController _searchController = TextEditingController();

  int _ambilHargaJasa(String hargaStr) {
    String firstPrice = hargaStr.split('-')[0].trim();
    final cleanStr = firstPrice.replaceAll(RegExp(r'[^0-9]'), '');
    return int.tryParse(cleanStr) ?? 0;
  }

  // Menghitung total biaya jasa
  int get _totalJasa {
    int total = 0;
    for (var title in _jasaTerpilih) {
      final layanan = widget.daftarLayanan.firstWhere((element) => element["title"] == title);
      total += _ambilHargaJasa(layanan["harga"]);
    }
    return total;
  }

  // Menghitung total biaya sparepart
  int get _totalSparepart {
    int total = 0;
    _sparepartTerpilih.forEach((id, qty) {
      final data = _dataSparepart[id];
      if (data != null && qty > 0) {
        int harga = 0;
        if (data['harga_jual'] != null) {
          harga = (data['harga_jual'] is String)
              ? int.tryParse(data['harga_jual']) ?? 0
              : (data['harga_jual'] as num).toInt();
        }
        total += harga * qty;
      }
    });
    return total;
  }

  int get _totalBiaya => _totalJasa + _totalSparepart;

  final formatRupiah = NumberFormat.currency(
    locale: 'id_ID', 
    symbol: 'Rp ', 
    decimalDigits: 0,
  );

  @override
  Widget build(BuildContext context) {
    // Filter agar Keluhan dan Lainnya tidak ikut di simulasi jasa
    final listJasa = widget.daftarLayanan.where((layanan) => 
      layanan["title"] != "Keluhan" && layanan["title"] != "Lainnya"
    ).toList();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.grey.shade50,
        appBar: AppBar(
          title: const Text(
            "Simulasi Estimasi Biaya",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          elevation: 0.5,
          bottom: const TabBar(
            labelColor: Colors.blue,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.blue,
            indicatorWeight: 3,
            labelStyle: TextStyle(fontWeight: FontWeight.bold),
            tabs: [
              Tab(text: "Jasa Perawatan"),
              Tab(text: "Suku Cadang"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // TAB 1: PILIH JASA PERAWATAN
            ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: listJasa.length,
              itemBuilder: (context, index) {
                final item = listJasa[index];
                final String title = item["title"];
                final int harga = _ambilHargaJasa(item["harga"]);
                final isSelected = _jasaTerpilih.contains(title);

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: isSelected ? Colors.blue.shade300 : Colors.grey.shade200,
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  color: isSelected ? Colors.blue.shade50.withOpacity(0.3) : Colors.white,
                  child: CheckboxListTile(
                    value: isSelected,
                    activeColor: Colors.blue.shade800,
                    title: Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    subtitle: Text(
                      harga == 0 ? "Biaya Jasa: Fleksibel / Hubungi Admin" : "Biaya Jasa: ${formatRupiah.format(harga)}",
                      style: TextStyle(fontSize: 12, color: Colors.blue.shade800, fontWeight: FontWeight.w600),
                    ),
                    onChanged: (bool? value) {
                      setState(() {
                        if (value == true) {
                          _jasaTerpilih.add(title);
                        } else {
                          _jasaTerpilih.remove(title);
                        }
                      });
                    },
                    secondary: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(item["icon"], color: Colors.blue.shade700, size: 20),
                    ),
                  ),
                );
              },
            ),

            // TAB 2: PILIH SUKU CADANG (DARI FIREBASE)
            Column(
              children: [
                // Search Bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) {
                      setState(() {
                        _keywordSparepart = value.toLowerCase();
                      });
                    },
                    decoration: InputDecoration(
                      hintText: "Cari suku cadang / barang...",
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                setState(() {
                                  _searchController.clear();
                                  _keywordSparepart = "";
                                });
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance.collection('sparepart').snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return const Center(
                          child: Text("Tidak ada data barang dari admin"),
                        );
                      }

                      final allDocs = snapshot.data!.docs;

                      // 1. Ekstrak Kategori Unik secara dinamis
                      final List<String> kategoriList = ["Semua"];
                      for (var doc in allDocs) {
                        final data = doc.data() as Map<String, dynamic>;
                        final kat = data['kategori']?.toString() ?? 'Lain-lain';
                        if (kat.isNotEmpty && !kategoriList.contains(kat)) {
                          kategoriList.add(kat);
                        }
                      }

                      // 2. Filter barang berdasarkan keyword pencarian dan kategori terpilih
                      final docs = allDocs.where((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final nama = (data['nama'] ?? "").toString().toLowerCase();
                        final matchesKeyword = nama.contains(_keywordSparepart);
                        
                        final kat = data['kategori']?.toString() ?? 'Lain-lain';
                        final matchesCategory = _kategoriTerpilih == "Semua" || kat == _kategoriTerpilih;

                        return matchesKeyword && matchesCategory;
                      }).toList();

                      return Column(
                        children: [
                          // Horizontal Category Chips
                          SizedBox(
                            height: 42,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              itemCount: kategoriList.length,
                              itemBuilder: (context, idx) {
                                final katName = kategoriList[idx];
                                final isSelected = _kategoriTerpilih == katName;
                                return Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 4),
                                  child: FilterChip(
                                    label: Text(
                                      katName,
                                      style: TextStyle(
                                        fontSize: 12, 
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                        color: isSelected ? Colors.white : Colors.black87,
                                      ),
                                    ),
                                    selected: isSelected,
                                    selectedColor: Colors.blue.shade800,
                                    checkmarkColor: Colors.white,
                                    backgroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                      side: BorderSide(
                                        color: isSelected ? Colors.blue.shade800 : Colors.grey.shade300,
                                      ),
                                    ),
                                    onSelected: (bool selected) {
                                      setState(() {
                                        _kategoriTerpilih = katName;
                                      });
                                    },
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 6),
                          
                          // ListView items
                          Expanded(
                            child: docs.isEmpty
                                ? const Center(
                                    child: Text("Suku cadang tidak ditemukan"),
                                  )
                                : ListView.builder(
                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                    itemCount: docs.length,
                                    itemBuilder: (context, index) {
                                      final doc = docs[index];
                                      final id = doc.id;
                                      final data = doc.data() as Map<String, dynamic>;
                                      
                                      _dataSparepart[id] = data;

                                      final nama = data['nama'] ?? "-";
                                      final brand = data['kategori'] ?? "Sparepart";
                                      final String? urlGambar = data['foto_url'];
                                      
                                      int harga = 0;
                                      if (data['harga_jual'] != null) {
                                        harga = (data['harga_jual'] is String)
                                            ? int.tryParse(data['harga_jual']) ?? 0
                                            : (data['harga_jual'] as num).toInt();
                                      }

                                      final qty = _sparepartTerpilih[id] ?? 0;

                                      return Card(
                                        margin: const EdgeInsets.symmetric(vertical: 6),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          side: BorderSide(color: Colors.grey.shade200),
                                        ),
                                        color: Colors.white,
                                        child: Padding(
                                          padding: const EdgeInsets.all(10),
                                          child: Row(
                                            children: [
                                              // Image / Icon
                                              Container(
                                                width: 50,
                                                height: 50,
                                                decoration: BoxDecoration(
                                                  color: Colors.grey.shade100,
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: urlGambar != null && 
                                                       urlGambar.isNotEmpty && 
                                                       urlGambar.startsWith('http')
                                                    ? ClipRRect(
                                                        borderRadius: BorderRadius.circular(8),
                                                        child: Image.network(
                                                          urlGambar,
                                                          fit: BoxFit.cover,
                                                          errorBuilder: (context, error, stackTrace) =>
                                                              Icon(Icons.broken_image, color: Colors.grey.shade400, size: 20),
                                                        ),
                                                      )
                                                    : Icon(Icons.build_outlined, color: Colors.orange.shade800, size: 22),
                                              ),
                                              const SizedBox(width: 12),
                                              // Details
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      nama,
                                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                                      maxLines: 2,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      brand,
                                                      style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      formatRupiah.format(harga),
                                                      style: const TextStyle(
                                                        fontWeight: FontWeight.bold,
                                                        fontSize: 12,
                                                        color: Colors.black87,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              // Counter
                                              Row(
                                                children: [
                                                  IconButton(
                                                    icon: const Icon(Icons.remove_circle_outline, color: Colors.blue),
                                                    onPressed: qty > 0
                                                        ? () {
                                                            setState(() {
                                                              _sparepartTerpilih[id] = qty - 1;
                                                            });
                                                          }
                                                        : null,
                                                  ),
                                                  Text(
                                                    "$qty",
                                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                                  ),
                                                  IconButton(
                                                    icon: const Icon(Icons.add_circle_outline, color: Colors.blue),
                                                    onPressed: () {
                                                      setState(() {
                                                        _sparepartTerpilih[id] = qty + 1;
                                                      });
                                                    },
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
        // PERSISTENT BOTTOM SUMMARY BAR
        bottomNavigationBar: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: SafeArea(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "Total Estimasi Biaya",
                      style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      formatRupiah.format(_totalBiaya),
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue.shade900),
                    ),
                  ],
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade800,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                  onPressed: _totalBiaya > 0 ? _tampilkanRincianDialog : null,
                  child: const Text(
                    "Lihat Rincian",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _tampilkanRincianDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          maxChildSize: 0.85,
          minChildSize: 0.4,
          expand: false,
          builder: (context, scrollController) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: ListView(
                controller: scrollController,
                children: [
                  Center(
                    child: Container(
                      width: 50,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  const Center(
                    child: Text(
                      "Rincian Estimasi Biaya",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // LIST JASA
                  if (_jasaTerpilih.isNotEmpty) ...[
                    const Text(
                      "JASA PERAWATAN",
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey),
                    ),
                    const SizedBox(height: 6),
                    ..._jasaTerpilih.map((title) {
                      final layanan = widget.daftarLayanan.firstWhere((element) => element["title"] == title);
                      final harga = _ambilHargaJasa(layanan["harga"]);
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(title, style: const TextStyle(fontSize: 13, color: Colors.black87)),
                            Text(
                              harga == 0 ? "Fleksibel" : formatRupiah.format(harga),
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      );
                    }),
                    const Divider(height: 20),
                  ],

                  // LIST SPAREPART
                  if (_totalSparepart > 0) ...[
                    const Text(
                      "SUKU CADANG / BARANG",
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey),
                    ),
                    const SizedBox(height: 6),
                    ..._sparepartTerpilih.entries.map((entry) {
                      final id = entry.key;
                      final qty = entry.value;
                      final data = _dataSparepart[id];
                      if (data == null || qty == 0) return const SizedBox.shrink();

                      final nama = data['nama'] ?? "-";
                      int harga = 0;
                      if (data['harga_jual'] != null) {
                        harga = (data['harga_jual'] is String)
                            ? int.tryParse(data['harga_jual']) ?? 0
                            : (data['harga_jual'] as num).toInt();
                      }
                      
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                "$nama (x$qty)",
                                style: const TextStyle(fontSize: 13, color: Colors.black87),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(formatRupiah.format(harga * qty), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                          ],
                        ),
                      );
                    }),
                    const Divider(height: 20),
                  ],

                  // RINGKASAN TOTAL
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Subtotal Jasa", style: TextStyle(fontSize: 13, color: Colors.grey)),
                      Text(
                        _jasaTerpilih.any((title) => _ambilHargaJasa(widget.daftarLayanan.firstWhere((e) => e["title"] == title)["harga"]) == 0)
                            ? (_totalJasa > 0 ? "${formatRupiah.format(_totalJasa)} + Fleksibel" : "Fleksibel")
                            : formatRupiah.format(_totalJasa),
                        style: const TextStyle(fontSize: 13, color: Colors.black87),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Subtotal Suku Cadang", style: TextStyle(fontSize: 13, color: Colors.grey)),
                      Text(formatRupiah.format(_totalSparepart), style: const TextStyle(fontSize: 13, color: Colors.black87)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(thickness: 1.5),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Total Perkiraan Biaya", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                      Text(
                        _jasaTerpilih.any((title) => _ambilHargaJasa(widget.daftarLayanan.firstWhere((e) => e["title"] == title)["harga"]) == 0)
                            ? (_totalBiaya > 0 ? "${formatRupiah.format(_totalBiaya)} + Fleksibel" : "Fleksibel")
                            : formatRupiah.format(_totalBiaya),
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue.shade900),
                      ),
                    ],
                  ),
                  if (_jasaTerpilih.any((title) {
                    final layanan = widget.daftarLayanan.firstWhere((element) => element["title"] == title);
                    return _ambilHargaJasa(layanan["harga"]) == 0;
                  })) ...[
                    const SizedBox(height: 12),
                    Text(
                      "*Beberapa jasa yang Anda pilih bersifat 'Fleksibel' karena membutuhkan pemeriksaan fisik oleh montir untuk menentukan biaya pasti.",
                      style: TextStyle(fontSize: 10, color: Colors.red.shade700, fontStyle: FontStyle.italic),
                    ),
                  ],
                  const SizedBox(height: 25),
                  
                  // TOMBOL TUTUP
                  SizedBox(
                    width: double.infinity,
                    height: 45,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade800,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Tutup Rincian", style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
