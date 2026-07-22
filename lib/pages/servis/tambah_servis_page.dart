import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class TambahServisPage extends StatefulWidget {
  final VoidCallback onBack;
  final Map<String, dynamic> spkData;

  const TambahServisPage({
    super.key,
    required this.onBack,
    required this.spkData,
  });

  @override
  State<TambahServisPage> createState() => _TambahServisPageState();
}

class _TambahServisPageState extends State<TambahServisPage> {
  String metodePembayaran = "Cash";
  bool isSaving = false;

  // ================= KALKULASI BIAYA =================
  double get biayaJasa => (widget.spkData['biaya_jasa'] ?? 0).toDouble();
  double get subtotalSparepart => (widget.spkData['total_harga'] ?? 0).toDouble();
  double get pajak => 0.11 * (biayaJasa + subtotalSparepart);
  double get totalAkhir => biayaJasa + subtotalSparepart + pajak;

  String _formatRupiah(num value) {
    final formatter = NumberFormat('#,##0', 'id_ID');
    return 'Rp ${formatter.format(value)}';
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.grey.shade100,
      child: Padding(
        padding: const EdgeInsets.all(20),
        // 🔥 RESPONSIF: kolom kiri & kanan jadi Row kalau lebar, ditumpuk Column kalau sempit
        child: LayoutBuilder(
          builder: (context, constraints) {
            final bool isNarrow = constraints.maxWidth < 900;

            if (isNarrow) {
              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildKolomKiriContent(),
                    const SizedBox(height: 15),
                    summaryCard(),
                    const SizedBox(height: 20),
                  ],
                ),
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ================= LEFT =================
                Expanded(
                  flex: 3,
                  child: SingleChildScrollView(
                    child: _buildKolomKiriContent(),
                  ),
                ),

                const SizedBox(width: 20),

                // ================= RIGHT =================
                Expanded(
                  flex: 1,
                  child: summaryCard(),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // 🔥 Isi kolom kiri (dipisah biar bisa dipakai ulang untuk mode lebar & sempit)
  Widget _buildKolomKiriContent() {
    return Column(
      children: [
        cardSPK(),
        const SizedBox(height: 15),
        cardSparepart(),
        const SizedBox(height: 15),
        cardRincian(),
        const SizedBox(height: 15),
        cardPembayaran(),
        const SizedBox(height: 80),
      ],
    );
  }

  // ================= CARD SPK =================
  Widget cardSPK() {
    return card(
      "Data SPK",
      Column(
        children: [
          // 🔥 RESPONSIF: DataTable bisa discroll horizontal kalau kolomnya kesempitan
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              border: TableBorder.all(color: Colors.grey.shade300),
              columns: const [
                DataColumn(label: Text("Nomor SPK")),
                DataColumn(label: Text("Nama Pelanggan")),
                DataColumn(label: Text("Kendaraan")),
                DataColumn(label: Text("Total Harga")),
              ],
              rows: [
                DataRow(
                  cells: [
                    DataCell(
                      Text(
                        widget.spkData['no_spk'] ?? '-',
                        style: const TextStyle(color: Colors.blue),
                      ),
                    ),
                    DataCell(Text(widget.spkData['nama_pelanggan'] ?? '-')),
                    DataCell(Text(widget.spkData['kendaraan'] ?? '-')),
                    DataCell(Text(_formatRupiah(widget.spkData['total_harga'] ?? 0))),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ================= CARD SPAREPART =================
  Widget cardSparepart() {
    return card(
      "Daftar Sparepart",
      Column(
        children: [
          const SizedBox(height: 10),
          // 🔥 RESPONSIF: DataTable bisa discroll horizontal kalau kolomnya kesempitan
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              border: TableBorder.all(color: Colors.grey.shade300),
              columns: const [
                DataColumn(label: Text("Nama")),
                DataColumn(label: Text("Kode")),
                DataColumn(label: Text("Jumlah")),
                DataColumn(label: Text("Harga")),
                DataColumn(label: Text("Total")),
              ],
              rows: (widget.spkData['sparepart'] as List? ?? [])
                  .map<DataRow>((item) {
                return DataRow(
                  cells: [
                    DataCell(Text(item['nama'] ?? '-')),
                    DataCell(Text(item['kode'] ?? '-')),
                    DataCell(Text("${item['jumlah'] ?? 0}")),
                    DataCell(Text(_formatRupiah(item['harga_jual_saat_itu'] ?? 0))),
                    DataCell(Text(_formatRupiah(item['subtotal'] ?? 0))),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // ================= CARD RINCIAN =================
  Widget cardRincian() {
    return card(
      "Rincian Biaya Akhir",
      Column(
        children: [
          rowText("Biaya Jasa Servis", _formatRupiah(biayaJasa)),
          rowText("Total Biaya Sparepart", _formatRupiah(subtotalSparepart)),
          rowText("Pajak (PPN 11%)", _formatRupiah(pajak)),
        ],
      ),
    );
  }

  // ================= CARD PEMBAYARAN =================
  Widget cardPembayaran() {
    return card(
      "Metode Pembayaran",
      Column(
        children: [
          RadioListTile<String>(
            title: const Text("Tunai (Cash)"),
            value: "Cash",
            groupValue: metodePembayaran,
            onChanged: (String? value) {
              setState(() {
                metodePembayaran = value!;
              });
            },
          ),
          RadioListTile<String>(
            title: const Text("Transfer Bank"),
            value: "Transfer",
            groupValue: metodePembayaran,
            onChanged: (String? value) {
              setState(() {
                metodePembayaran = value!;
              });
            },
          ),
          if (metodePembayaran == "Transfer")
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Nomor Rekening", style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(height: 5),
                  Text("BCA : 2940825272"),
                  Text("A/N Sarjimu"),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ================= SUMMARY =================
  Widget summaryCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 6),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade800,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              "RINGKASAN BIAYA",
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),

          rowText("Subtotal Jasa", _formatRupiah(biayaJasa)),
          rowText("Subtotal Sparepart", _formatRupiah(subtotalSparepart)),
          rowText("Pajak (PPN 11%)", _formatRupiah(pajak)),

          const Divider(),

          const Text("TOTAL BIAYA AKHIR"),
          const SizedBox(height: 5),

          Text(
            _formatRupiah(totalAkhir),
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 15),

          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 45),
            ),
            onPressed: isSaving ? null : _simpanInvoice,
            icon: isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.save),
            label: Text(isSaving ? "Menyimpan..." : "Simpan & Selesaikan"),
          ),

          const SizedBox(height: 10),

          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 45),
            ),
            onPressed: widget.onBack,
            child: const Text("Batal Transaksi"),
          ),

          // 🔥 TOMBOL CETAK INVOICE DIHAPUS DARI SINI
          // sudah ada di DetailServisPage
        ],
      ),
    );
  }

  // ================= SIMPAN INVOICE =================
  Future<void> _simpanInvoice() async {
    setState(() => isSaving = true);

    try {
      final cekInvoice = await FirebaseFirestore.instance
          .collection('invoice')
          .where('spk_id', isEqualTo: widget.spkData['id'])
          .limit(1)
          .get();

      if (cekInvoice.docs.isNotEmpty) {
        setState(() => isSaving = false);
        return;
      }

      await FirebaseFirestore.instance.collection('invoice').add({
        'spk_id': widget.spkData['id'],
        'no_spk': widget.spkData['no_spk'],
        'nama_pelanggan': widget.spkData['nama_pelanggan'],
        'nama_montir': widget.spkData['nama_montir'],
        'kendaraan': widget.spkData['kendaraan'],
        'plat': widget.spkData['plat'],
        'sparepart': widget.spkData['sparepart'] ?? [],
        'biaya_jasa': biayaJasa,
        'total_harga': subtotalSparepart,
        'pajak': pajak,
        'total_akhir': totalAkhir,
        'metode_pembayaran': metodePembayaran,
        // 🔥 FIX: invoice baru dibuat setelah pembayaran dipilih & disimpan,
        // jadi statusnya harus langsung "Lunas", bukan "Belum Bayar".
        'status': 'Lunas',
        'created_at': Timestamp.now(),
      });

      await FirebaseFirestore.instance
          .collection('spk')
          .doc(widget.spkData['id'])
          .update({
        'status_invoice': true,
      });

      widget.onBack();
    } finally {
      if (mounted) {
        setState(() => isSaving = false);
      }
    }
  }

  // ================= COMPONENT =================

  Widget card(String title, Widget child) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          child
        ],
      ),
    );
  }

  Widget input(String hint) {
    return TextField(
      decoration: InputDecoration(
        hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Widget rowText(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget paymentCard(String title, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, size: 30),
          const SizedBox(height: 10),
          Text(title),
        ],
      ),
    );
  }
}