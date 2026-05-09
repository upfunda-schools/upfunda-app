import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class CertificateHelper {
  static Future<void> generateAndDownload({
    required String studentName,
    required String categoryName,
    required String level,
  }) async {
    final pdf = await _buildPdf(studentName, categoryName, level, isPreview: false);
    
    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: 'Upfunda_Certificate_${categoryName.replaceAll(' ', '_')}_${studentName.replaceAll(' ', '_')}.pdf',
    );
  }

  static Future<void> showPreview(
    BuildContext context, {
    required String studentName,
    required String categoryName,
    required String level,
  }) async {
    final pdf = await _buildPdf(studentName, categoryName, level, isPreview: true);
    final bytes = await pdf.save();

    if (!context.mounted) return;

    await showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        clipBehavior: Clip.antiAlias,
        child: SizedBox(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.75,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                color: const Color(0xFF1A1D4D),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Certificate Preview',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(Icons.close, color: Colors.white),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: PdfPreview(
                  build: (format) => bytes,
                  allowPrinting: false,
                  allowSharing: false,
                  canChangePageFormat: false,
                  canChangeOrientation: false,
                  canDebug: false,
                  padding: const EdgeInsets.all(12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Future<pw.Document> _buildPdf(String studentName, String categoryName, String level, {required bool isPreview}) async {
    final pdf = pw.Document();
    
    final String displayName = isPreview ? 'YOUR NAME HERE' : studentName;
    
    // Load the template image
    final ByteData bytes = await rootBundle.load('assets/images/certificate/certificate_template.png');
    final Uint8List byteList = bytes.buffer.asUint8List();
    final pw.MemoryImage image = pw.MemoryImage(byteList);

    // Load fonts
    final fontBold = await PdfGoogleFonts.playfairDisplayBold();
    final fontRegular = await PdfGoogleFonts.openSansRegular();
    final fontDetailBold = await PdfGoogleFonts.openSansBold();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.zero,
        build: (pw.Context context) {
          return pw.Stack(
            children: [
              // Background Image
              pw.FullPage(
                ignoreMargins: true,
                child: pw.Image(image, fit: pw.BoxFit.cover),
              ),
              
              // Student Name
              pw.Positioned(
                top: 440, // Moved down to avoid overlap with background text
                left: 0,
                right: 0,
                child: pw.Center(
                  child: pw.Text(
                    displayName,
                    style: pw.TextStyle(
                      font: fontBold,
                      fontSize: 42,
                      color: PdfColor.fromInt(0xFFF58220), // More vibrant orange
                    ),
                  ),
                ),
              ),

              // Details
              pw.Positioned(
                top: 510,
                left: 0,
                right: 0,
                child: pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 80),
                  child: pw.Column(
                    children: [
                      pw.Text(
                        'For completing $categoryName',
                        textAlign: pw.TextAlign.center,
                        style: pw.TextStyle(
                          font: fontRegular,
                          fontSize: 14,
                          color: PdfColor.fromInt(0xFF4A4A4A), // Darker grey
                        ),
                      ),
                      pw.RichText(
                        textAlign: pw.TextAlign.center,
                        text: pw.TextSpan(
                          style: pw.TextStyle(
                            font: fontRegular,
                            fontSize: 14,
                            color: PdfColor.fromInt(0xFF4A4A4A), // Darker grey
                          ),
                          children: [
                            const pw.TextSpan(text: 'of '),
                            pw.TextSpan(
                              text: 'GRADE $level',
                              style: pw.TextStyle(font: fontDetailBold),
                            ),
                            const pw.TextSpan(text: ' at Upfunda'),
                          ],
                        ),
                      ),
                      pw.SizedBox(height: 8),
                      pw.Text(
                        DateTime.now().toString().split(' ')[0],
                        style: pw.TextStyle(
                          font: fontRegular,
                          fontSize: 10,
                          color: PdfColor.fromInt(0xFF4A4A4A),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            ],
          );
        },
      ),
    );
    return pdf;
  }
}
