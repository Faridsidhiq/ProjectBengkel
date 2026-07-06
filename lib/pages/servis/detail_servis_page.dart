import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class DetailServisPage extends StatelessWidget {
  final String spkId;
  final VoidCallback onBack;

  const DetailServisPage({
    super.key,
    required this.spkId,
    required this.onBack,
  });

  // ================= HELPER FORMAT RUPIAH =================
  String _rp(num value) {
    final formatter = NumberFormat('#,##0', 'id_ID');
    return 'Rp ${formatter.format(value)}';
  }

  // ================= GENERATE NO INVOICE RAPI =================
  String _formatNoInvoice(Map<String, dynamic> data, String docId) {
    final existing = data['no_invoice'] as String?;
    if (existing != null && existing.startsWith('INV-')) {
      return existing;
    }

    final noSpk = data['no_spk'] as String?;
    if (noSpk != null && noSpk.startsWith('SPK-')) {
      return noSpk.replaceFirst('SPK-', 'INV-');
    }

    final now = DateTime.now();
    final bulan = DateFormat('yyyyMM').format(now);
    final suffix = docId.length >= 4
        ? docId.substring(0, 4).toUpperCase()
        : docId.toUpperCase();
    return 'INV-$bulan-$suffix';
  }

  // ================= HELPER INFO ROW (Flutter UI) =================
  TableRow _infoRow(String label, String value) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Text(label, style: const TextStyle(fontSize: 13)),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 2, horizontal: 6),
          child: Text(" : ", style: TextStyle(fontSize: 13)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Text(value, style: const TextStyle(fontSize: 13)),
        ),
      ],
    );
  }

  // ================= HELPER INFO ROW (PDF) =================
  pw.TableRow _pdfInfoRow(String label, String value, pw.TextStyle style) {
    return pw.TableRow(
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 2),
          child: pw.Text(label, style: style),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 2, horizontal: 4),
          child: pw.Text(" : ", style: style),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 2),
          child: pw.Text(value, style: style),
        ),
      ],
    );
  }

  // ================= HELPER ROW TOTAL (PDF) =================
  pw.Widget _pdfTotalRow(String label, String value,
      {bool bold = false, PdfColor? color}) {
    final style = pw.TextStyle(
      fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
      color: color,
      fontSize: bold ? 11 : 9,
    );
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 3),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: style),
          pw.Text(value, style: style),
        ],
      ),
    );
  }

  // ================= GENERATE PDF =================
  Future<Uint8List> _buildInvoicePdf({
    required String noInvoice,
    required Map<String, dynamic> data,
    required List sparepart,
    required double biayaJasa,
    required double subtotalSparepart,
    required double pajak,
    required double totalAkhir,
  }) async {
    final pdfDoc = pw.Document();

    pw.MemoryImage? logoImage;
    try {
      final logoBytes = await rootBundle.load('assets/logo.png');
      logoImage = pw.MemoryImage(logoBytes.buffer.asUint8List());
    } catch (_) {
      logoImage = null;
    }

    const infoStyle = pw.TextStyle(fontSize: 9);
    final isTransfer =
        (data['metode_pembayaran'] ?? '').toString().toLowerCase() == 'transfer';

    pdfDoc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) {
          return pw.Padding(
            padding: const pw.EdgeInsets.all(28),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // ===== HEADER =====
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Expanded(
                      flex: 3,
                      child: pw.Row(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          if (logoImage != null)
                            pw.Image(logoImage, width: 50, height: 50),
                          pw.SizedBox(width: 10),
                          pw.Expanded(
                            child: pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                pw.Text("JIMU MITSUBISHI",
                                    style: pw.TextStyle(
                                        fontWeight: pw.FontWeight.bold,
                                        fontSize: 13)),
                                pw.Text("Bengkel Terbaik", style: infoStyle),
                                pw.SizedBox(height: 6),
                                pw.Text(
                                    "JL. P DAMAR GG WIJAYA KESUMA NO.10",
                                    style: infoStyle),
                                pw.Text("BANDAR LAMPUNG", style: infoStyle),
                                pw.Text("Telp: 08213123412", style: infoStyle),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    pw.SizedBox(width: 16),
                    pw.Expanded(
                      flex: 2,
                      child: pw.Table(
                        defaultColumnWidth: const pw.IntrinsicColumnWidth(),
                        children: [
                          _pdfInfoRow("No Invoice", noInvoice, infoStyle),
                          _pdfInfoRow("No SPK", data['no_spk'] ?? '-', infoStyle),
                          _pdfInfoRow("Nama Pelanggan",
                              data['nama_pelanggan'] ?? '-', infoStyle),
                          _pdfInfoRow(
                              "Nama Montir", data['nama_montir'] ?? '-', infoStyle),
                          _pdfInfoRow("No Plat", data['plat'] ?? '-', infoStyle),
                          _pdfInfoRow(
                              "Kendaraan", data['kendaraan'] ?? '-', infoStyle),
                        ],
                      ),
                    ),
                  ],
                ),

                pw.SizedBox(height: 24),

                // ===== TABEL SPAREPART =====
                pw.Table.fromTextArray(
                  headers: [
                    "No.",
                    "Deskripsi Sparepart",
                    "Jumlah",
                    "Harga Satuan",
                    "Subtotal"
                  ],
                  data: List.generate(sparepart.length, (i) {
                    final item = sparepart[i];
                    return [
                      (i + 1).toString().padLeft(2, '0'),
                      "${item['nama'] ?? '-'}",
                      "${item['jumlah'] ?? 0}",
                      _rp(item['harga_jual_saat_itu'] ?? 0),
                      _rp(item['subtotal'] ?? 0),
                    ];
                  }),
                  headerStyle: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.white,
                      fontSize: 9),
                  headerDecoration:
                      const pw.BoxDecoration(color: PdfColors.blue700),
                  cellStyle: const pw.TextStyle(fontSize: 9),
                  cellAlignments: {
                    0: pw.Alignment.center,
                    1: pw.Alignment.centerLeft,
                    2: pw.Alignment.center,
                    3: pw.Alignment.centerRight,
                    4: pw.Alignment.centerRight,
                  },
                  columnWidths: {
                    0: const pw.FixedColumnWidth(28),
                    1: const pw.FlexColumnWidth(3),
                    2: const pw.FixedColumnWidth(45),
                    3: const pw.FlexColumnWidth(1.4),
                    4: const pw.FlexColumnWidth(1.4),
                  },
                  border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
                  cellPadding:
                      const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 6),
                ),

                pw.SizedBox(height: 16),

                // ===== RINCIAN & TOTAL (PDF) =====
                pw.Align(
                  alignment: pw.Alignment.centerRight,
                  child: pw.SizedBox(
                    width: 230,
                    child: pw.Column(
                      children: [
                        _pdfTotalRow("Subtotal Sparepart", _rp(subtotalSparepart)),
                        _pdfTotalRow("Harga Jasa Servis", _rp(biayaJasa)),
                        _pdfTotalRow("Pajak (PPN 11%)", _rp(pajak)),
                        pw.Divider(),
                        _pdfTotalRow("Total Akhir Dibayarkan", _rp(totalAkhir), bold: true),
                        pw.SizedBox(height: 6),
                        _pdfTotalRow(
                          "Pembayaran",
                          "${data['metode_pembayaran'] ?? '-'}".toUpperCase(),
                          bold: true,
                          color: PdfColors.green700,
                        ),
                        if (isTransfer) ...[
                          pw.SizedBox(height: 3),
                          pw.Align(
                            alignment: pw.Alignment.centerRight,
                            child: pw.Text(
                              "BCA : 1234567890 A/N Jimu Mitsubishi",
                              style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
                            ),
                          ),
                          // pw.Align(
                          //   alignment: pw.Alignment.centerRight,
                          //   child: pw.Text(
                          //     "Nominal: ${_rp(totalAkhir)}",
                          //     style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
                          //   ),
                          // ),
                        ],
                      ],
                    ),
                  ),
                ),

                pw.SizedBox(height: 24),

                pw.Text(
                  "*Simpan invoice ini sebagai garansi saat ada yang kurang dalam pelayanan.\nHarap hubungi kami jika ada pertanyaan, keluhan, atau permintaan lainnya.",
                  style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
                ),

                pw.SizedBox(height: 20),

                pw.Center(
                  child: pw.Text(
                    "TERIMA KASIH ATAS KEPERCAYAAN ANDA\nMENGGUNAKAN JASA KAMI",
                    textAlign: pw.TextAlign.center,
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Center(
                  child: pw.Text("JIMU MITSUBISHI | BENGKEL TERBAIK",
                      style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold, fontSize: 10)),
                ),
              ],
            ),
          );
        },
      ),
    );

    return pdfDoc.save();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xfff5f7fb),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(onPressed: onBack, icon: const Icon(Icons.arrow_back)),
                const SizedBox(width: 10),
                const Text("Pencatatan Data Servis",
                    style:
                        TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: FutureBuilder<QuerySnapshot>(
                future: FirebaseFirestore.instance
                    .collection('invoice')
                    .where('spk_id', isEqualTo: spkId)
                    .limit(1)
                    .get(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(
                        child: Text("Data invoice tidak ditemukan."));
                  }

                  final doc = snapshot.data!.docs.first;
                  final data = doc.data() as Map<String, dynamic>;

                  final String noInvoice = _formatNoInvoice(data, doc.id);

                  final List sparepart = data['sparepart'] ?? [];
                  final double biayaJasa =
                      (data['biaya_jasa'] ?? 0).toDouble();
                  final double subtotalSparepart =
                      (data['total_harga'] ?? 0).toDouble();
                  final double pajak = (data['pajak'] ?? 0).toDouble();
                  final double totalAkhir =
                      (data['total_akhir'] ?? 0).toDouble();

                  // Cek apakah metode pembayaran transfer
                  final bool isTransfer =
                      (data['metode_pembayaran'] ?? '').toString().toLowerCase() ==
                          'transfer';

                  return Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            noInvoice,
                            style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.blueGrey),
                          ),
                          Row(
                            children: [
                              ElevatedButton.icon(
                                onPressed: () async {
                                  final bytes = await _buildInvoicePdf(
                                    noInvoice: noInvoice,
                                    data: data,
                                    sparepart: sparepart,
                                    biayaJasa: biayaJasa,
                                    subtotalSparepart: subtotalSparepart,
                                    pajak: pajak,
                                    totalAkhir: totalAkhir,
                                  );
                                  await Printing.layoutPdf(
                                    onLayout: (format) async => bytes,
                                  );
                                },
                                icon: const Icon(Icons.print),
                                label: const Text("Cetak Invoice"),
                              ),
                              const SizedBox(width: 10),
                              ElevatedButton.icon(
                                onPressed: () async {
                                  final bytes = await _buildInvoicePdf(
                                    noInvoice: noInvoice,
                                    data: data,
                                    sparepart: sparepart,
                                    biayaJasa: biayaJasa,
                                    subtotalSparepart: subtotalSparepart,
                                    pajak: pajak,
                                    totalAkhir: totalAkhir,
                                  );
                                  await Printing.sharePdf(
                                    bytes: bytes,
                                    filename: '$noInvoice.pdf',
                                  );
                                },
                                icon: const Icon(Icons.picture_as_pdf),
                                label: const Text("Unduh PDF"),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      Expanded(
                        child: Center(
                          child: Container(
                            width: MediaQuery.of(context).size.width * 0.8,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 30, vertical: 25),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                    color:
                                        Colors.black.withValues(alpha: 0.05),
                                    blurRadius: 12),
                              ],
                            ),
                            child: SingleChildScrollView(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // ===== HEADER INVOICE =====
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // KIRI: Logo + Info Bengkel
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Image.asset('assets/logo.png',
                                              width: 100,
                                              height: 100,
                                              fit: BoxFit.contain),
                                          const SizedBox(width: 15),
                                          const Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text("JIMU MITSUBISHI",
                                                  style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 18)),
                                              SizedBox(height: 5),
                                              Text("Bengkel Terbaik"),
                                              SizedBox(height: 10),
                                              Text(
                                                  "JL. P DAMAR GG WIJAYA KESUMA NO.10"),
                                              Text("BANDAR LAMPUNG"),
                                              Text("Telp: 08213123412"),
                                            ],
                                          ),
                                        ],
                                      ),

                                      // KANAN: Info Invoice
                                      Table(
                                        defaultColumnWidth:
                                            const IntrinsicColumnWidth(),
                                        children: [
                                          _infoRow("No Invoice", noInvoice),
                                          _infoRow("No SPK",
                                              data['no_spk'] ?? '-'),
                                          _infoRow("Nama Pelanggan",
                                              data['nama_pelanggan'] ?? '-'),
                                          _infoRow("Nama Montir",
                                              data['nama_montir'] ?? '-'),
                                          _infoRow(
                                              "No Plat", data['plat'] ?? '-'),
                                          _infoRow("Kendaraan",
                                              data['kendaraan'] ?? '-'),
                                        ],
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 25),

                                  // ===== HEADER TABEL =====
                                  Row(
                                    children: const [
                                      Expanded(
                                          child: Text("No.",
                                              style: TextStyle(
                                                  color: Colors.blue))),
                                      Expanded(
                                          flex: 3,
                                          child: Text("Deskripsi Sparepart",
                                              style: TextStyle(
                                                  color: Colors.blue))),
                                      Expanded(
                                          child: Text("Jumlah",
                                              style: TextStyle(
                                                  color: Colors.blue))),
                                      Expanded(
                                          child: Text("Harga Satuan",
                                              style: TextStyle(
                                                  color: Colors.blue))),
                                      Expanded(
                                          child: Text("Subtotal",
                                              style: TextStyle(
                                                  color: Colors.blue))),
                                    ],
                                  ),
                                  const Divider(),

                                  // ===== ISI TABEL =====
                                  ...List.generate(sparepart.length, (i) {
                                    final item = sparepart[i];
                                    return invoiceRow(
                                      (i + 1).toString().padLeft(2, '0'),
                                      item['nama'] ?? '-',
                                      "${item['jumlah'] ?? 0}",
                                      _rp(item['harga_jual_saat_itu'] ?? 0),
                                      _rp(item['subtotal'] ?? 0),
                                    );
                                  }),
                                  const Divider(),
                                  const SizedBox(height: 15),

                                  // ===== RINCIAN BIAYA (Flutter UI) =====
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text("Subtotal Sparepart: ${_rp(subtotalSparepart)}"),
                                        const SizedBox(height: 5),
                                        Text("Harga Jasa Servis: ${_rp(biayaJasa)}"),
                                        const SizedBox(height: 5),
                                        Text("Pajak (PPN 11%): ${_rp(pajak)}"),
                                      ],
                                    ),
                                  ),

                                  const SizedBox(height: 10),
                                  const Divider(),

                                  // ===== TOTAL =====
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text("Total Akhir Dibayarkan :",
                                          style: TextStyle(fontWeight: FontWeight.bold)),
                                      Text(_rp(totalAkhir),
                                          style: const TextStyle(fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text("Pembayaran :"),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            "${data['metode_pembayaran'] ?? '-'}".toUpperCase(),
                                            style: const TextStyle(
                                                color: Colors.green,
                                                fontWeight: FontWeight.bold),
                                          ),
                                          if (isTransfer) ...[
                                            const SizedBox(height: 4),
                                            Text(
                                              "BCA  •  2940825272  •  a.n Sarjimu",
                                              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                            ),
                                            Text(
                                              "Nominal: ${_rp(totalAkhir)}",
                                              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 20),

                                  const Text(
                                    "*Simpan invoice ini sebagai garansi saat ada yang kurang dalam pelayanan.\nHarap hubungi kami jika ada pertanyaan, keluhan, atau permintaan lainnya.",
                                    style: TextStyle(
                                        fontSize: 12, color: Colors.grey),
                                  ),
                                  const SizedBox(height: 25),
                                  const Center(
                                    child: Text(
                                      "TERIMA KASIH ATAS KEPERCAYAAN ANDA\nMENGGUNAKAN JASA KAMI",
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  const Center(
                                    child: Text(
                                        "JIMU MITSUBISHI | BENGKEL TERBAIK",
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget invoiceRow(
      String no, String desc, String qty, String price, String total) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(child: Text(no)),
          Expanded(flex: 3, child: Text(desc)),
          Expanded(child: Text(qty)),
          Expanded(child: Text(price)),
          Expanded(child: Text(total)),
        ],
      ),
    );
  }
}