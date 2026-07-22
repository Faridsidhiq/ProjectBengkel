import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// 🔥 FORMATTER TITIK RIBUAN OTOMATIS SAAT KETIK
class _RupiahInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    String digits = newValue.text.replaceAll('.', '');
    if (digits.isEmpty) return newValue.copyWith(text: '');
    final number = int.tryParse(digits) ?? 0;
    final formatted = _formatAngka(number);
    return newValue.copyWith(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  String _formatAngka(int value) {
    final str = value.toString();
    final buffer = StringBuffer();
    int counter = 0;
    for (int i = str.length - 1; i >= 0; i--) {
      if (counter > 0 && counter % 3 == 0) buffer.write('.');
      buffer.write(str[i]);
      counter++;
    }
    return buffer.toString().split('').reversed.join();
  }
}

class TambahSparepartPage extends StatefulWidget {
  final String? docId;
  final Map<String, dynamic>? data;

  const TambahSparepartPage({
    super.key,
    this.docId,
    this.data,
  });

  @override
  State<TambahSparepartPage> createState() => _TambahSparepartPageState();
}

class _TambahSparepartPageState extends State<TambahSparepartPage> {

  final namaController = TextEditingController();
  final beliController = TextEditingController();
  final jualController = TextEditingController();
  final stokController = TextEditingController();
  final minStokController = TextEditingController();
  final fotoController = TextEditingController();

  // 🔥 KATEGORI DIUPDATE SESUAI EXCEL
  String selectedKategori = "Oli";
  final List<String> kategoriList = [
    "Oli",
    "Grease",
    "Filter Oli",
    "Filter Udara",
    "Filter AC",
    "Filter Bahan Bakar",
    "Kampas Rem",
    "Pompa",
    "Additive",
    "Spare Part",
  ];

  String selectedTypeKendaraan = "ALL TYPE";
  final List<String> typeKendaraanList = [
    "ALL NEW PAJERO",
    "ALL TYPE",
    "ALL TYPE AT",
    "ALL TYPE CVT",
    "ALL TYPE DIESEL",
    "ALL TYPE GASOLIN",
    "AVANZA",
    "AVANZA NEW",
    "CANTER",
    "CANTER NEW",
    "COLT DIESEL",
    "DUTRO",
    "DUTRO, CANTER",
    "ELF MACAN",
    "ELF NLR",
    "ERTIGA",
    "FUSO",
    "INNOVA REBORN",
    "KIJANG EFI",
    "L300",
    "LIVINA",
    "MIRAGE",
    "NAVARA",
    "NEW L300",
    "NEW PAJERO",
    "PAJERO",
    "PAJERO DAKAR",
    "PAJERO EXCEED",
    "PAJERO OLD",
    "PANTHER 1,8",
    "PANTHER 2,5",
    "RINO",
    "T120SS",
    "TRITON",
    "X PANDER",
    "XPANDER",
    "XPANDER, MIRAGE",
    "XENIA 1000 CC",  // 🔥 tambahan dari Excel
  ];

  bool isLoading = false;

  int _parseRupiah(String value) {
    return int.tryParse(value.replaceAll('.', '')) ?? 0;
  }

  String _formatAngka(int value) {
    final str = value.toString();
    final buffer = StringBuffer();
    int counter = 0;
    for (int i = str.length - 1; i >= 0; i--) {
      if (counter > 0 && counter % 3 == 0) buffer.write('.');
      buffer.write(str[i]);
      counter++;
    }
    return buffer.toString().split('').reversed.join();
  }

  @override
  void initState() {
    super.initState();
    if (widget.data != null) {
      namaController.text = widget.data!['nama'] ?? '';
      beliController.text = _formatAngka(widget.data!['harga_beli'] ?? 0);
      jualController.text = _formatAngka(widget.data!['harga_jual'] ?? 0);
      stokController.text = (widget.data!['stok'] ?? 0).toString();
      minStokController.text = (widget.data!['min_stok'] ?? 0).toString();
      fotoController.text = widget.data!['foto_url'] ?? '';

      // 🔥 pastikan kategori yang disimpan ada di list, kalau tidak fallback ke "Spare Part"
      final savedKategori = widget.data!['kategori'] ?? "Oli";
      selectedKategori = kategoriList.contains(savedKategori) ? savedKategori : "Spare Part";
      selectedTypeKendaraan = widget.data!['type_kendaraan'] ?? "ALL TYPE";
    }
  }

  // 🔥 GENERATE KODE DIUPDATE SESUAI KATEGORI BARU
  Future<String> generateKode(String kategori) async {
    final Map<String, String> prefixMap = {
      "Oli":                "OLI",
      "Filter Oli":         "FOLI",
      "Filter Udara":       "FUDR",
      "Filter AC":          "FAC",
      "Filter Bahan Bakar": "FBB",
      "Kampas Rem":         "KPS",
      "Pompa":              "PMP",
      "Additive":           "ADD",
      "Spare Part":         "SPR",
    };

    final prefix = prefixMap[kategori] ?? "SPR";

    final snapshot = await FirebaseFirestore.instance
        .collection('sparepart')
        .where('kategori', isEqualTo: kategori)
        .get();

    int nomorTerakhir = 0;
    for (var doc in snapshot.docs) {
      final kode = doc['kode'] ?? '';
      if (kode.toString().startsWith(prefix)) {
        try {
          final nomor = int.parse(kode.toString().split('-').last);
          if (nomor > nomorTerakhir) nomorTerakhir = nomor;
        } catch (_) {}
      }
    }
    return "$prefix-${(nomorTerakhir + 1).toString().padLeft(4, '0')}";
  }

  Future<void> simpanData() async {
    final nama = namaController.text.trim();
    final hargaJual = _parseRupiah(jualController.text);
    final stok = int.tryParse(stokController.text) ?? 0;

    if (nama.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("⚠️ Nama sparepart wajib diisi"), backgroundColor: Colors.red),
      );
      return;
    }
    if (hargaJual == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("⚠️ Harga jual wajib diisi"), backgroundColor: Colors.red),
      );
      return;
    }
    if (stok == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("⚠️ Stok wajib diisi"), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final hargaBeli = _parseRupiah(beliController.text);
      final minStok = int.tryParse(minStokController.text) ?? 0;

      if (widget.docId != null) {
        await FirebaseFirestore.instance
            .collection('sparepart')
            .doc(widget.docId)
            .update({
          'nama': nama,
          'kategori': selectedKategori,
          'type_kendaraan': selectedTypeKendaraan,
          'harga_beli': hargaBeli,
          'harga_jual': hargaJual,
          'stok': stok,
          'min_stok': minStok,
          'foto_url': fotoController.text.trim(),
        });
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Data berhasil diupdate"), backgroundColor: Colors.green),
        );
      } else {
        final kode = await generateKode(selectedKategori);
        await FirebaseFirestore.instance.collection('sparepart').add({
          'nama': nama,
          'kategori': selectedKategori,
          'type_kendaraan': selectedTypeKendaraan,
          'kode': kode,
          'harga_beli': hargaBeli,
          'harga_jual': hargaJual,
          'stok': stok,
          'min_stok': minStok,
          'foto_url': fotoController.text.trim(),
          'created_at': Timestamp.now(),
        });
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Data berhasil ditambahkan"), backgroundColor: Colors.green),
        );
      }
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }

    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    // 🔥 Lebar dialog menyesuaikan layar: maksimal 950, tapi nggak lebih dari 95% lebar layar
    final screenWidth = MediaQuery.of(context).size.width;
    final dialogWidth = screenWidth < 1000 ? screenWidth * 0.95 : 950.0;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: dialogWidth,
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [

              // ================= HEADER =================
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.docId == null ? "Tambah Data Sparepart" : "Edit Data Sparepart",
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),

              Align(
                alignment: Alignment.centerLeft,
                child: RichText(
                  text: const TextSpan(children: [
                    TextSpan(text: "* ", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                    TextSpan(text: "Wajib diisi  ", style: TextStyle(color: Colors.grey, fontSize: 12)),
                    TextSpan(text: "Opsional", style: TextStyle(color: Colors.blue, fontSize: 12)),
                    TextSpan(text: " = boleh dikosongkan", style: TextStyle(color: Colors.grey, fontSize: 12)),
                  ]),
                ),
              ),

              const SizedBox(height: 16),

              // 🔥 RESPONSIF: 3 kolom jadi Row kalau lebar, ditumpuk Column kalau sempit
              LayoutBuilder(
                builder: (context, constraints) {
                  final bool isNarrow = constraints.maxWidth < 700;

                  final kolomKiri = _buildKolomKiri();
                  final kolomTengah = _buildKolomTengah();
                  final kolomKanan = _buildKolomKanan();

                  if (isNarrow) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        kolomKiri,
                        const SizedBox(height: 10),
                        kolomTengah,
                        const SizedBox(height: 10),
                        kolomKanan,
                      ],
                    );
                  }

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: kolomKiri),
                      const SizedBox(width: 20),
                      Expanded(child: kolomTengah),
                      const SizedBox(width: 20),
                      Expanded(child: kolomKanan),
                    ],
                  );
                },
              ),

              const SizedBox(height: 25),

              // ================= TOMBOL =================
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Batal"),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: isLoading ? null : simpanData,
                      icon: isLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.save),
                      label: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(isLoading ? "Menyimpan..." : "Simpan Data"),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ================= KOLOM KIRI =================
  Widget _buildKolomKiri() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel("Nama Sparepart", wajib: true),
        _buildTextField(
          controller: namaController,
          hint: "Contoh: Oli Shell Helix",
          helper: "Isi nama sparepart sesuai produk",
          tipeInput: TextInputType.text,
        ),

        _buildLabel("Kategori", wajib: true),
        DropdownButtonFormField<String>(
          initialValue: selectedKategori,
          items: kategoriList
              .map((k) => DropdownMenuItem(value: k, child: Text(k)))
              .toList(),
          onChanged: (value) => setState(() => selectedKategori = value!),
          decoration: InputDecoration(
            helperText: "Pilih jenis sparepart",
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),

        const SizedBox(height: 15),

        _buildLabel("Stok", wajib: true),
        _buildTextField(
          controller: stokController,
          hint: "Contoh: 10",
          helper: "Jumlah barang tersedia",
        ),

        const SizedBox(height: 15),

        _buildLabel("Type Kendaraan", wajib: false),
        DropdownButtonFormField<String>(
          initialValue: selectedTypeKendaraan,
          decoration: InputDecoration(
            helperText: "Pilih type kendaraan (opsional)",
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
          items: typeKendaraanList
              .map((item) => DropdownMenuItem(
                    value: item,
                    child: Text(item, overflow: TextOverflow.ellipsis),
                  ))
              .toList(),
          onChanged: (value) => setState(() => selectedTypeKendaraan = value!),
        ),
      ],
    );
  }

  // ================= KOLOM TENGAH =================
  Widget _buildKolomTengah() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel("Harga Beli", wajib: false),
        _buildTextField(
          controller: beliController,
          hint: "Contoh: 50.000",
          helper: "Opsional — harga modal sparepart",
          isRupiah: true,
        ),

        _buildLabel("Harga Jual", wajib: true),
        _buildTextField(
          controller: jualController,
          hint: "Contoh: 75.000",
          helper: "Harga jual ke pelanggan",
          isRupiah: true,
        ),

        _buildLabel("Minimal Stok", wajib: false),
        _buildTextField(
          controller: minStokController,
          hint: "Contoh: 3",
          helper: "Opsional — batas peringatan stok menipis",
        ),
      ],
    );
  }

  // ================= KOLOM KANAN - FOTO =================
  Widget _buildKolomKanan() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel("Link Foto", wajib: false),
        TextField(
          controller: fotoController,
          keyboardType: TextInputType.url,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: "https://...",
            helperText: "Opsional — tempel link URL gambar",
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),

        const SizedBox(height: 15),

        Container(
          width: double.infinity,
          height: 200,
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: fotoController.text.trim().isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.image_outlined, size: 40, color: Colors.grey),
                      SizedBox(height: 8),
                      Text("Preview gambar", style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                )
              : ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    fotoController.text.trim(),
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.broken_image_outlined, size: 40, color: Colors.red),
                          SizedBox(height: 8),
                          Text("Link gambar tidak valid", style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildLabel(String label, {required bool wajib}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: label,
              style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w500, fontSize: 13),
            ),
            if (wajib)
              const TextSpan(text: "  *", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))
            else
              const TextSpan(text: "  Opsional", style: TextStyle(color: Colors.blue, fontSize: 11)),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    String hint = "",
    String helper = "",
    TextInputType tipeInput = TextInputType.number,
    bool isRupiah = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextField(
        controller: controller,
        keyboardType: tipeInput,
        inputFormatters: isRupiah ? [_RupiahInputFormatter()] : [],
        decoration: InputDecoration(
          hintText: hint,
          helperText: helper,
          prefixText: isRupiah ? "Rp " : null,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }
}