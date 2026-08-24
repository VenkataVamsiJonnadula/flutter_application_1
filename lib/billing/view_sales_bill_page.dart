import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'bill_model.dart';
import '../customers/customer_model.dart';
import '../customers/customer_profile_page.dart';
import '../data/mock_data.dart';

// Converted to a clean StatelessWidget to eliminate createState and widget context compilation conflicts
class ViewSalesBillPage extends StatelessWidget {
  final Bill bill;
  final Customer customer;

  // Unique notifier for this page instance to cache the generated PDF bytes and prevent CPU-bound re-generation freezes.
  final ValueNotifier<Uint8List?> _cachedPdfBytesNotifier = ValueNotifier<Uint8List?>(null);

  ViewSalesBillPage({
    super.key,
    required this.bill,
    required this.customer,
  }) {
    _loadAssets();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _prewarmPdf();
    });
  }

  // Static cache to persist loaded assets across page opens
  static Uint8List? _cachedFontBytes;
  static Uint8List? _cachedItalicFontBytes;
  static pw.Font? _parsedTtf;
  static pw.Font? _parsedTtfItalic;
  static String? _cachedSvgString;
  static bool _fontsLoadedSuccessfully = false;
  static bool _hasLoadedAssets = false;

  static final ValueNotifier<bool> _isLoadingAssetsNotifier = ValueNotifier<bool>(!_hasLoadedAssets);

  void _loadAssets() async {
    if (_hasLoadedAssets) return;

    try {
      final svgString = await rootBundle.loadString('assets/brand_logo_colored.svg');
      _cachedSvgString = svgString;
    } catch (e) {
      debugPrint("SVG Asset missing, falling back to clean vector typography: $e");
      _cachedSvgString = '';
    }

    try {
      final fontData = await rootBundle.load('assets/Rubik-VariableFont_wght.ttf');
      _cachedFontBytes = fontData.buffer.asUint8List();
      _parsedTtf = pw.Font.ttf(ByteData.sublistView(_cachedFontBytes!));

      final italicData = await rootBundle.load('assets/Rubik-Italic-VariableFont_wght.ttf');
      _cachedItalicFontBytes = italicData.buffer.asUint8List();
      _parsedTtfItalic = pw.Font.ttf(ByteData.sublistView(_cachedItalicFontBytes!));

      _fontsLoadedSuccessfully = true;
    } catch (e) {
      debugPrint("Custom font asset load failed, falling back to clean system font defaults: $e");
      _cachedFontBytes = null;
      _cachedItalicFontBytes = null;
      _parsedTtf = pw.Font.helvetica();
      _parsedTtfItalic = pw.Font.helveticaOblique();
      _fontsLoadedSuccessfully = false;
    }

    _hasLoadedAssets = true;
    _isLoadingAssetsNotifier.value = false;
  }

  void _prewarmPdf() async {
    if (_cachedPdfBytesNotifier.value != null) return;

    // Yield control to let Flutter build and present the UI view first without lag
    await Future.delayed(const Duration(milliseconds: 80));

    while (_isLoadingAssetsNotifier.value) {
      await Future.delayed(const Duration(milliseconds: 15));
    }

    if (_cachedPdfBytesNotifier.value == null) {
      try {
        final doc = await _buildPdfDocumentStatic(
          bill: bill,
          customer: customer,
          ttf: _parsedTtf ?? pw.Font.helvetica(),
          ttfItalic: _parsedTtfItalic ?? pw.Font.helveticaOblique(),
          rawSvgString: _cachedSvgString ?? '',
          fontsLoadedSuccessfully: _fontsLoadedSuccessfully,
        );
        _cachedPdfBytesNotifier.value = await doc.save();
      } catch (e) {
        debugPrint("Background PDF prewarm error: $e");
      }
    }
  }

  static Future<pw.Document> _buildPdfDocumentStatic({
    required Bill bill,
    required Customer customer,
    required pw.Font ttf,
    required pw.Font ttfItalic,
    required String rawSvgString,
    required bool fontsLoadedSuccessfully,
  }) async {

    final String wingdingDecor = fontsLoadedSuccessfully ? '✿' : '*';
    final String bulletDecor = fontsLoadedSuccessfully ? '✦' : '-';

    final pw.Widget logoWidget = rawSvgString.isNotEmpty
        ? pw.SizedBox(width: 212, height: 106, child: pw.SvgImage(svg: rawSvgString, fit: pw.BoxFit.contain))
        : pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            mainAxisSize: pw.MainAxisSize.min,
            children: [
              pw.Row(
                mainAxisSize: pw.MainAxisSize.min,
                children: [
                  pw.Text(wingdingDecor, style: pw.TextStyle(fontSize: 10, color: const PdfColor.fromInt(0xFFB8860B))),
                  pw.SizedBox(width: 4),
                  pw.Text(wingdingDecor, style: pw.TextStyle(fontSize: 10, color: const PdfColor.fromInt(0xFFB8860B))),
                  pw.SizedBox(width: 4),
                  pw.Text(wingdingDecor, style: pw.TextStyle(fontSize: 10, color: const PdfColor.fromInt(0xFFB8860B))),
                ],
              ),
              pw.SizedBox(height: 2),
              pw.Text('SRI VIJAYALAKSHMI', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: const PdfColor.fromInt(0xFF8B1A1A), letterSpacing: 1.5)),
              pw.Text('$bulletDecor J E W E L L E R S $bulletDecor', style: const pw.TextStyle(fontSize: 9, color: PdfColor.fromInt(0xFF8B1A1A), letterSpacing: 2)),
              pw.SizedBox(height: 1),
              pw.Text('SINCE 1954', style: const pw.TextStyle(fontSize: 8, color: PdfColor.fromInt(0xFFB8860B))),
            ],
          );

    final simulatedItems = bill.items;
    final totalTaxable = simulatedItems.fold(0.0, (sum, item) => sum + item.taxableValue);
    final totalDiscount = simulatedItems.fold(0.0, (sum, item) => sum + item.discAmt);
    final totalCgst = double.parse((totalTaxable * 0.015).toStringAsFixed(2));
    final totalSgst = double.parse((totalTaxable * 0.015).toStringAsFixed(2));
    final unroundedPayable = double.parse((totalTaxable + totalCgst + totalSgst).toStringAsFixed(2));
    final totalPayable = unroundedPayable.roundToDouble();
    final roundOff = double.parse((totalPayable - unroundedPayable).toStringAsFixed(2));
    final amountInWordsText = _amountInWords(totalPayable);

    final invoiceNumber = bill.invoiceNumber;
    final invoiceDate = DateFormat('dd-MM-yyyy').format(bill.date);

    final pdf = pw.Document();

    pw.Widget pdfInvoiceDetailRow(String label, String value) {
      return pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 1),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.end,
          mainAxisSize: pw.MainAxisSize.min,
          children: [
            pw.Text(label, style: const pw.TextStyle(fontSize: 10, color: PdfColor.fromInt(0xFF555555))),
            pw.SizedBox(width: 6),
            pw.Text(value, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: const PdfColor.fromInt(0xFF1A1A1A))),
          ],
        ),
      );
    }

    pw.Widget pdfTermLine(String text) {
      return pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 2),
        child: pw.Text(text, style: const pw.TextStyle(fontSize: 8.5, color: PdfColor.fromInt(0xFF555555))),
      );
    }

    pw.Widget pdfTotalRow(String label, String value, {bool isDiscount = false}) {
      final valueColor = isDiscount ? const PdfColor.fromInt(0xFFCC0000) : const PdfColor.fromInt(0xFF1A1A1A);
      return pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 2, horizontal: 4),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              label,
              style: pw.TextStyle(
                fontSize: 9.5,
                color: isDiscount ? const PdfColor.fromInt(0xFFCC0000) : const PdfColor.fromInt(0xFF444444),
                fontWeight: isDiscount ? pw.FontWeight.bold : pw.FontWeight.normal,
              ),
            ),
            pw.Text(
              value,
              style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold, color: valueColor),
            ),
          ],
        ),
      );
    }

    String formatCurrencyStr(double value) =>
        NumberFormat.currency(locale: 'en_IN', symbol: '', decimalDigits: 2).format(value);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.copyWith(
          marginTop: 16,
          marginBottom: 16,
          marginLeft: 28,
          marginRight: 28,
        ),
        theme: pw.ThemeData.withFont(
          base: ttf,
          italic: ttfItalic,
          bold: ttf,
        ),
        footer: (pw.Context context) {
          return pw.Column(
            mainAxisSize: pw.MainAxisSize.min,
            children: [
              pw.Divider(color: const PdfColor.fromInt(0xFFCCCCCC), thickness: 0.5),
              pw.SizedBox(height: 5),
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Expanded(
                    flex: 5,
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Terms & Conditions:', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: const PdfColor.fromInt(0xFF1A1A1A))),
                        pw.SizedBox(height: 3),
                        pdfTermLine('1. Certified that the particulars given above are true and correct.'),
                        pdfTermLine('2. All gold jewellery is certified as per the standards of BIS.'),
                        pdfTermLine('3. Goods once sold will not be taken back only store credit will be provided.'),
                        pdfTermLine('4. Exchange will be allowed within 7 days of purchase.'),
                      ],
                    ),
                  ),
                  pw.Expanded(
                    flex: 4,
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text('For Sri Vijayalakshmi Jewellers', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: const PdfColor.fromInt(0xFF1A1A1A))),
                        pw.SizedBox(height: 35),
                        pw.Container(width: 125, height: 0.5, color: PdfColors.grey500),
                        pw.SizedBox(height: 2),
                        pw.Text('Authorised Signatory', style: const pw.TextStyle(fontSize: 8.5, color: PdfColor.fromInt(0xFF555555))),
                      ],
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 10),
              pw.Container(
                decoration: const pw.BoxDecoration(
                  border: pw.Border(top: pw.BorderSide(color: PdfColor.fromInt(0xFFE0E0E0), width: 0.5)),
                  color: PdfColor.fromInt(0xFFF9F9F9),
                ),
                padding: const pw.EdgeInsets.symmetric(vertical: 5),
                child: pw.SizedBox(
                  width: double.infinity,
                  child: pw.Text(
                    'Thank you for your trust. | Visit us again! ',
                    textAlign: pw.TextAlign.center,
                    style: const pw.TextStyle(fontSize: 8.5, color: PdfColor.fromInt(0xFF666666)),
                  ),
                ),
              ),
            ],
          );
        },
        build: (pw.Context context) {
          // DYNAMIC ON-THE-FLY COLUMN WIDTH CALCULATION
          // Dynamically measures required width per column for the current bill's data (handles lakhs/crores and long descriptions)
          double measureColWidth(String header, List<String> dataValues) {
            int maxLen = header.length;
            for (final v in dataValues) {
              if (v.length > maxLen) maxLen = v.length;
            }
            return maxLen * 4.5;
          }

          final double w0 = measureColWidth('S.No', List.generate(simulatedItems.length, (i) => (i + 1).toString()));
          final double w1 = measureColWidth('Description', simulatedItems.map((e) => e.description).toList());
          final double w2 = measureColWidth('HSN', simulatedItems.map((e) => e.hsnSac).toList());
          final double w3 = measureColWidth('Gr.Wt', simulatedItems.map((e) => e.grossWt.toStringAsFixed(3)).toList());
          final double w4 = measureColWidth('St.Wt', simulatedItems.map((e) => e.stoneWt.toStringAsFixed(3)).toList());
          final double w5 = measureColWidth('Net Wt', simulatedItems.map((e) => e.netWt.toStringAsFixed(3)).toList());
          final double w6 = measureColWidth('Rate', simulatedItems.map((e) => formatCurrencyStr(e.metalRate)).toList());
          final double w7 = measureColWidth('Metal Value', simulatedItems.map((e) => formatCurrencyStr(e.metalValue)).toList());
          final double w8 = measureColWidth('Stone Value', simulatedItems.map((e) => formatCurrencyStr(e.stoneValue)).toList());
          final double w9 = measureColWidth('Making', simulatedItems.map((e) => formatCurrencyStr(e.va)).toList());
          final double w10 = measureColWidth('Total', simulatedItems.map((e) => formatCurrencyStr(e.totalValue)).toList());

          final double minTotalRequired = w0 + w1 + w2 + w3 + w4 + w5 + w6 + w7 + w8 + w9 + w10;
          const double totalPrintableWidth = 539.28;
          final double remainingSpace = totalPrintableWidth > minTotalRequired ? (totalPrintableWidth - minTotalRequired) : 0.0;
          final double equalPaddingPerCol = remainingSpace / 11.0;

          final double col0 = w0 + equalPaddingPerCol;
          final double col1 = w1 + equalPaddingPerCol;
          final double col2 = w2 + equalPaddingPerCol;
          final double col3 = w3 + equalPaddingPerCol;
          final double col4 = w4 + equalPaddingPerCol;
          final double col5 = w5 + equalPaddingPerCol;
          final double col6 = w6 + equalPaddingPerCol;
          final double col7 = w7 + equalPaddingPerCol;
          final double col8 = w8 + equalPaddingPerCol;
          final double col9 = w9 + equalPaddingPerCol;
          final double col10 = totalPrintableWidth - (col0 + col1 + col2 + col3 + col4 + col5 + col6 + col7 + col8 + col9);

          return [
            // FIXED VISUAL PARITY: Explicitly namespaced alignment calls safely bound to the PDF layout context tree
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Container(
                  child: logoWidget,
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  mainAxisAlignment: pw.MainAxisAlignment.end,
                  children: [
                    pw.Text(
                      'TAX INVOICE',
                      style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: const PdfColor.fromInt(0xFF1A1A1A), letterSpacing: 1),
                    ),
                    pw.SizedBox(height: 4),
                    pdfInvoiceDetailRow('Invoice No:', invoiceNumber),
                    pdfInvoiceDetailRow('Date:', invoiceDate),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 12),

            // ADDRESS BAR
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(vertical: 5, horizontal: 4),
              decoration: const pw.BoxDecoration(
                border: pw.Border.symmetric(horizontal: pw.BorderSide(color: PdfColor.fromInt(0xFFCCCCCC), width: 0.5)),
              ),
              child: pw.SizedBox(
                width: double.infinity,
                child: pw.Text(
                  'DNo. 8-355, Sharof bazar Road, Mangalagiri - 522503 | Phone: +91 78420 68860 | GSTIN: 33AABCS1234F1Z5',
                  textAlign: pw.TextAlign.center,
                  style: const pw.TextStyle(fontSize: 8.5, color: PdfColor.fromInt(0xFF444444)),
                ),
              ),
            ),
            pw.SizedBox(height: 12),

            // BILL TO
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Bill To:', style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold, color: const PdfColor.fromInt(0xFF1A1A1A))),
                pw.SizedBox(height: 2),
                pw.Text(bill.customerName.isNotEmpty ? bill.customerName : customer.name, style: pw.TextStyle(fontSize: 11.5, fontWeight: pw.FontWeight.bold, color: const PdfColor.fromInt(0xFF1A1A1A))),
                pw.Text(bill.customerAddress.isNotEmpty ? bill.customerAddress : customer.address, style: const pw.TextStyle(fontSize: 9.5, color: PdfColor.fromInt(0xFF333333))),
                pw.Text('Phone: ${bill.customerPhone.isNotEmpty ? bill.customerPhone : customer.phone}', style: const pw.TextStyle(fontSize: 9.5, color: PdfColor.fromInt(0xFF333333))),
              ],
            ),
            pw.SizedBox(height: 12),

            // LINE ITEMS DATA TABLE
            pw.Table(
              defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
              border: pw.TableBorder.all(color: const PdfColor.fromInt(0xFFCCCCCC), width: 0.5),
              columnWidths: {
                0: pw.FixedColumnWidth(col0),
                1: pw.FixedColumnWidth(col1),
                2: pw.FixedColumnWidth(col2),
                3: pw.FixedColumnWidth(col3),
                4: pw.FixedColumnWidth(col4),
                5: pw.FixedColumnWidth(col5),
                6: pw.FixedColumnWidth(col6),
                7: pw.FixedColumnWidth(col7),
                8: pw.FixedColumnWidth(col8),
                9: pw.FixedColumnWidth(col9),
                10: pw.FixedColumnWidth(col10),
              },
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFF2C3E50)),
                  children: [
                    'S.No', 'Description', 'HSN', 'Gr.Wt', 'St.Wt', 'Net Wt', 'Rate', 'Metal Value', 'Stone Value', 'Making', 'Total'
                  ].map((text) {
                    return pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(vertical: 5, horizontal: 3),
                      child: pw.Align(
                        alignment: pw.Alignment.center,
                        child: pw.Text(
                          text,
                          style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                          maxLines: 1,
                          softWrap: false,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                ...simulatedItems.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final item = entry.value;
                  return pw.TableRow(
                    children: [
                      pw.Padding(padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 3), child: pw.Text((idx + 1).toString(), textAlign: pw.TextAlign.center, style: const pw.TextStyle(fontSize: 7.5), maxLines: 1, softWrap: false)),
                      pw.Padding(padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 3), child: pw.Text(item.description, textAlign: pw.TextAlign.center, style: const pw.TextStyle(fontSize: 7.5), maxLines: 1, softWrap: false)),
                      pw.Padding(padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 3), child: pw.Text(item.hsnSac, textAlign: pw.TextAlign.center, style: const pw.TextStyle(fontSize: 7.5), maxLines: 1, softWrap: false)),
                      pw.Padding(padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 3), child: pw.Text(item.grossWt.toStringAsFixed(3), textAlign: pw.TextAlign.center, style: const pw.TextStyle(fontSize: 7.5), maxLines: 1, softWrap: false)),
                      pw.Padding(padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 3), child: pw.Text(item.stoneWt.toStringAsFixed(3), textAlign: pw.TextAlign.center, style: const pw.TextStyle(fontSize: 7.5), maxLines: 1, softWrap: false)),
                      pw.Padding(padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 3), child: pw.Text(item.netWt.toStringAsFixed(3), textAlign: pw.TextAlign.center, style: const pw.TextStyle(fontSize: 7.5), maxLines: 1, softWrap: false)),
                      pw.Padding(padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 3), child: pw.Text(formatCurrencyStr(item.metalRate), textAlign: pw.TextAlign.center, style: const pw.TextStyle(fontSize: 7.5), maxLines: 1, softWrap: false)),
                      pw.Padding(padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 3), child: pw.Text(formatCurrencyStr(item.metalValue), textAlign: pw.TextAlign.center, style: const pw.TextStyle(fontSize: 7.5), maxLines: 1, softWrap: false)),
                      pw.Padding(padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 3), child: pw.Text(formatCurrencyStr(item.stoneValue), textAlign: pw.TextAlign.center, style: const pw.TextStyle(fontSize: 7.5), maxLines: 1, softWrap: false)),
                      pw.Padding(padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 3), child: pw.Text(formatCurrencyStr(item.va), textAlign: pw.TextAlign.center, style: const pw.TextStyle(fontSize: 7.5), maxLines: 1, softWrap: false)),
                      pw.Padding(padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 3), child: pw.Text(formatCurrencyStr(item.totalValue), textAlign: pw.TextAlign.center, style: const pw.TextStyle(fontSize: 7.5), maxLines: 1, softWrap: false)),
                    ],
                  );
                }),
              ],
            ),
            pw.SizedBox(height: 12),

            // TOTALS CALCULATION ROW
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  child: pw.RichText(
                    text: pw.TextSpan(
                      style: const pw.TextStyle(fontSize: 9, color: PdfColor.fromInt(0xFF333333)),
                      children: [
                        pw.TextSpan(text: 'Amount in Words: ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        pw.TextSpan(text: amountInWordsText),
                      ],
                    ),
                  ),
                ),
                pw.SizedBox(width: 20),
                pw.SizedBox(
                  width: 195,
                  child: pw.Column(
                    children: [
                      if (totalDiscount > 0.0) pdfTotalRow('Discount:', '- ${formatCurrencyStr(totalDiscount)}', isDiscount: true),
                      pdfTotalRow('Sub Total:', formatCurrencyStr(totalTaxable)),
                      pdfTotalRow('CGST @ 1.5%:', formatCurrencyStr(totalCgst)),
                      pdfTotalRow('SGST @ 1.5%:', formatCurrencyStr(totalSgst)),
                      if (roundOff != 0.0) pdfTotalRow('Round Off:', '${roundOff >= 0 ? '+' : ''}${formatCurrencyStr(roundOff)}'),
                      pw.SizedBox(height: 3),
                      pw.Container(
                        color: const PdfColor.fromInt(0xFF2C3E50),
                        padding: const pw.EdgeInsets.symmetric(vertical: 5, horizontal: 6),
                        child: pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text('GRAND TOTAL:', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
                            pw.Text('Rs. ${formatCurrencyStr(totalPayable)}', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ];
        },
      ),
    );

    return pdf;
  }

  static String _amountInWords(double amount) {
    final rupees = amount.floor();
    final paise = ((amount - rupees) * 100).round();
    final rupeesText = _convertNumberToWords(rupees);
    if (paise == 0) {
      return '$rupeesText only';
    }
    final paiseText = _convertNumberToWords(paise);
    return '$rupeesText and $paiseText paise only';
  }

  static String _convertNumberToWords(int number) {
    if (number == 0) return 'zero';

    const units = [
      '', 'one', 'two', 'three', 'four', 'five', 'six', 'seven', 'eight', 'nine', 'ten',
      'eleven', 'twelve', 'thirteen', 'fourteen', 'fifteen', 'sixteen', 'seventeen', 'eighteen', 'nineteen',
    ];
    const tens = [
      '', '', 'twenty', 'thirty', 'forty', 'fifty', 'sixty', 'seventy', 'eighty', 'ninety',
    ];

    String convert(int n) {
      if (n < 20) return units[n];
      if (n < 100) {
        final t = tens[n ~/ 10];
        final u = units[n % 10];
        return u.isEmpty ? t : '$t $u';
      }
      if (n < 1000) {
        final h = units[n ~/ 100];
        final rest = n % 100;
        return rest == 0 ? '$h hundred' : '$h hundred ${convert(rest)}';
      }
      if (n < 100000) {
        final t = convert(n ~/ 1000);
        final rest = n % 1000;
        return rest == 0 ? '$t thousand' : '$t thousand ${convert(rest)}';
      }
      if (n < 10000000) {
        final t = convert(n ~/ 100000);
        final rest = n % 100000;
        return rest == 0 ? '$t lakh' : '$t lakh ${convert(rest)}';
      }
      final t = convert(n ~/ 10000000);
      final rest = n % 10000000;
      return rest == 0 ? '$t crore' : '$t crore ${convert(rest)}';
    }

    return convert(number);
  }

  @override
  Widget build(BuildContext context) {
    _loadAssets();

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        elevation: 1.0,
        backgroundColor: const Color(0xFF03045E),
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          'Invoice Dashboard ${bill.invoiceNumber}',
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.print, color: Colors.white),
            tooltip: 'Print Invoice',
            onPressed: () async {
              final bytes = await _getOrGeneratePdfBytes(context);
              if (context.mounted) {
                _printInvoice(context, bytes);
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.share, color: Colors.white),
            tooltip: 'Share PDF',
            onPressed: () async {
              final bytes = await _getOrGeneratePdfBytes(context);
              if (context.mounted) {
                _shareInvoice(context, bytes);
              }
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
          body: LayoutBuilder(
            builder: (context, constraints) {
              final isDesktop = constraints.maxWidth >= 900;
              if (isDesktop) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // CRM Sidebar Left (30%)
                    Container(
                      width: constraints.maxWidth * 0.3,
                      constraints: const BoxConstraints(minWidth: 280, maxWidth: 360),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        border: Border(right: BorderSide(color: Colors.grey.shade200)),
                      ),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            _buildCustomerCRMCard(context),
                            const SizedBox(height: 20),
                            _buildRecentPurchasesList(context),
                          ],
                        ),
                      ),
                    ),
                    // Bill Details & Glassmorphism Area Right (70%)
                    Expanded(
                      child: Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFFEBF3FB), Color(0xFFF3F7FA)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(32),
                          child: _buildRightDashboardPanel(context, isDesktop: true),
                        ),
                      ),
                    ),
                  ],
                );
              } else {
                // Mobile View: Stacks vertically, hides CRM recent list, completely scrollable!
                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildCustomerCRMCard(context),
                      const SizedBox(height: 20),
                      _buildRightDashboardPanel(context, isDesktop: false),
                    ],
                  ),
                );
              }
            },
          ),
        );
  }


  Widget _buildCustomerCRMCard(BuildContext context) {
    final activeCustomer = Customer(
      id: bill.customerId.isNotEmpty ? bill.customerId : customer.id,
      name: bill.customerName.isNotEmpty ? bill.customerName : customer.name,
      phone: bill.customerPhone.isNotEmpty ? bill.customerPhone : customer.phone,
      address: bill.customerAddress.isNotEmpty ? bill.customerAddress : customer.address,
      email: customer.email,
      customerSince: customer.customerSince,
    );

    return Card(
      elevation: 2,
      shadowColor: Colors.black12,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'CUSTOMER ACCOUNT',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.black45,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CustomerProfilePage(
                      customer: activeCustomer,
                      onBack: () => Navigator.pop(context),
                    ),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: const Color(0xFF0077B6),
                      radius: 28,
                      child: Text(
                        activeCustomer.name.isNotEmpty ? activeCustomer.name.substring(0, 1).toUpperCase() : '?',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            activeCustomer.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF03045E),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'ID: ${activeCustomer.id}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.black45,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Divider(height: 1, thickness: 0.5),
            const SizedBox(height: 16),
            _buildInfoRow(Icons.phone_outlined, activeCustomer.phone, 'Phone'),
            const SizedBox(height: 12),
            _buildInfoRow(Icons.location_on_outlined, activeCustomer.address, 'Address'),
            if (activeCustomer.email.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildInfoRow(Icons.email_outlined, activeCustomer.email, 'Email'),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String value, String label) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: const Color(0xFF0077B6)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label.toUpperCase(),
                style: const TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                  color: Colors.black38,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRecentPurchasesList(BuildContext context) {
    final isRegistered = !bill.isOneTime &&
        bill.customerId.isNotEmpty &&
        bill.customerId != 'ONE-TIME' &&
        bill.customerId != 'GUEST';

    final customerInvoices = sharedMockItems.where((item) {
      // Exclude the current bill being viewed so only alternate bills are displayed
      if (item.slNo == bill.slNo || item.invoiceNumber == bill.invoiceNumber) {
        return false;
      }
      
      if (isRegistered) {
        // Registered customer: match by registered Customer ID or exact Name
        final sameId = item.customerId.isNotEmpty &&
            item.customerId != 'ONE-TIME' &&
            item.customerId != 'GUEST' &&
            item.customerId == bill.customerId;
        final sameName = item.customerName.trim().toLowerCase() == bill.customerName.trim().toLowerCase();
        return sameId || sameName;
      } else {
        // Unregistered / One-time / Guest customer: ONLY group if they share the exact SAME name (case-insensitive)
        final billName = bill.customerName.trim().toLowerCase();
        final itemName = item.customerName.trim().toLowerCase();
        return billName != 'na' && billName.isNotEmpty && itemName == billName;
      }
    }).toList();

    customerInvoices.sort((a, b) => b.date.compareTo(a.date));
    final last5 = customerInvoices.take(5).toList();
    final currencyFormatter = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    return Card(
      elevation: 2,
      shadowColor: Colors.black12,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'ALTERNATE PURCHASES',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.black45,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 12),
            if (last5.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text(
                    'No alternate purchase records found.',
                    style: TextStyle(fontSize: 12, color: Colors.black38),
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: last5.length,
                separatorBuilder: (context, index) => const Divider(height: 1, thickness: 0.5),
                itemBuilder: (context, index) {
                  final invoice = last5[index];
                  final isCurrent = invoice.slNo == bill.slNo;

                  return InkWell(
                    onTap: isCurrent
                        ? null
                        : () {
                            final targetCustomer = Customer(
                              id: invoice.customerId,
                              name: invoice.customerName,
                              phone: invoice.customerPhone,
                              address: invoice.customerAddress,
                              email: '',
                              customerSince: invoice.date,
                            );
                            Navigator.pushReplacement(
                              context,
                              PageRouteBuilder(
                                pageBuilder: (context, animation1, animation2) => ViewSalesBillPage(
                                  bill: invoice,
                                  customer: targetCustomer,
                                ),
                                transitionDuration: Duration.zero,
                                reverseTransitionDuration: Duration.zero,
                              ),
                            );
                          },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                      decoration: BoxDecoration(
                        color: isCurrent ? const Color(0xFF03045E).withAlpha(13) : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: isCurrent
                                  ? const Color(0xFF03045E)
                                  : const Color(0xFF0077B6).withAlpha(25),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.receipt_outlined,
                              size: 14,
                              color: isCurrent ? Colors.white : const Color(0xFF0077B6),
                            ),
                          ),
                          const SizedBox(width: 12),
                          SizedBox(
                            width: 100,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'INV-${invoice.slNo.toString().padLeft(4, '0')}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: isCurrent ? const Color(0xFF03045E) : Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  DateFormat('dd MMM yyyy').format(invoice.date),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 10, color: Colors.black45),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  currencyFormatter.format(invoice.grandTotal),
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: isCurrent ? const Color(0xFF03045E) : Colors.teal,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  invoice.description,
                                  style: const TextStyle(
                                    fontSize: 9,
                                    color: Colors.black45,
                                    fontStyle: FontStyle.italic,
                                  ),
                                  textAlign: TextAlign.end,
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRightDashboardPanel(BuildContext context, {required bool isDesktop}) {
    final invoiceNumber = bill.invoiceNumber;
    final invoiceDate = DateFormat('dd-MM-yyyy').format(bill.date);

    final simulatedItems = bill.items;
    final totalTaxable = simulatedItems.fold(0.0, (sum, item) => sum + item.taxableValue);
    final totalCgst = double.parse((totalTaxable * 0.015).toStringAsFixed(2));
    final totalSgst = double.parse((totalTaxable * 0.015).toStringAsFixed(2));
    final unroundedPayable = double.parse((totalTaxable + totalCgst + totalSgst).toStringAsFixed(2));
    final totalPayable = unroundedPayable.roundToDouble();
    final roundOff = double.parse((totalPayable - unroundedPayable).toStringAsFixed(2));
    final amountInWordsText = _amountInWords(totalPayable);

    String formatCurrencyStr(double value) =>
        NumberFormat.currency(locale: 'en_IN', symbol: '₹ ', decimalDigits: 2).format(value);

    final tableWidget = Table(
      border: TableBorder.all(color: Colors.grey.shade100, width: 0.5),
      columnWidths: const {
        0: FixedColumnWidth(35),
        1: FlexColumnWidth(2.2),
        2: FixedColumnWidth(70),
        3: FixedColumnWidth(70),
        4: FixedColumnWidth(75),
        5: FixedColumnWidth(90),
        6: FixedColumnWidth(90),
        7: FixedColumnWidth(80),
        8: FixedColumnWidth(75),
        9: FixedColumnWidth(95),
      },
      children: [
        TableRow(
          decoration: const BoxDecoration(
            color: Color(0xFF03045E),
          ),
          children: [
            _buildHeaderCell('Sl'),
            _buildHeaderCell('Description / HSN'),
            _buildHeaderCell('Gross Wt'),
            _buildHeaderCell('Stone Wt'),
            _buildHeaderCell('Net Wt'),
            _buildHeaderCell('Metal Rate'),
            _buildHeaderCell('Making VA'),
            _buildHeaderCell('Stone Val'),
            _buildHeaderCell('Discount'),
            _buildHeaderCell('Taxable Val'),
          ],
        ),
        ...simulatedItems.map((item) {
          final idx = simulatedItems.indexOf(item) + 1;
          return TableRow(
            decoration: BoxDecoration(
              color: idx.isEven ? Colors.grey.shade50 : Colors.white,
            ),
            children: [
              _buildDataCell('$idx'),
              _buildDataCell('${item.description}\n(HSN: ${item.hsnSac})', alignLeft: true),
              _buildDataCell('${item.grossWt.toStringAsFixed(3)} g'),
              _buildDataCell('${item.stoneWt.toStringAsFixed(3)} g'),
              _buildDataCell('${item.netWt.toStringAsFixed(3)} g', isBold: true),
              _buildDataCell(formatCurrencyStr(item.metalRate)),
              _buildDataCell(formatCurrencyStr(item.va)),
              _buildDataCell(formatCurrencyStr(item.stoneValue)),
              _buildDataCell(formatCurrencyStr(item.discAmt), isDiscount: true),
              _buildDataCell(formatCurrencyStr(item.taxableValue), isBold: true),
            ],
          );
        }),
      ],
    );

    final tableContainer = Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(5),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: tableWidget,
      ),
    );

    final responsiveTable = LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 860) {
          return tableContainer;
        } else {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: 860,
              child: tableContainer,
            ),
          );
        }
      },
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'DESCRIPTION OF GOODS',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Color(0xFF03045E),
                letterSpacing: 1,
              ),
            ),
            Text(
              'INV: $invoiceNumber   •   DATE: $invoiceDate',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.black54,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        responsiveTable,
        const SizedBox(height: 32),
        _buildGlassmorphicSummary(
          totalTaxable: totalTaxable,
          totalCgst: totalCgst,
          totalSgst: totalSgst,
          roundOff: roundOff,
          totalPayable: totalPayable,
          amountInWordsText: amountInWordsText,
          formatCurrencyStr: formatCurrencyStr,
        ),
      ],
    );
  }

  Widget _buildGlassmorphicSummary({
    required double totalTaxable,
    required double totalCgst,
    required double totalSgst,
    required double roundOff,
    required double totalPayable,
    required String amountInWordsText,
    required String Function(double) formatCurrencyStr,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(204),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withAlpha(128),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF03045E).withAlpha(18),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 600;

              final summaryContent = Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildSummaryRowItem('Total Taxable Value', formatCurrencyStr(totalTaxable)),
                  const SizedBox(height: 10),
                  _buildSummaryRowItem('CGST (1.5%)', formatCurrencyStr(totalCgst)),
                  const SizedBox(height: 10),
                  _buildSummaryRowItem('SGST (1.5%)', formatCurrencyStr(totalSgst)),
                  if (roundOff != 0.0) ...[
                    const SizedBox(height: 10),
                    _buildSummaryRowItem('Round Off', '${roundOff >= 0 ? '+' : ''}${formatCurrencyStr(roundOff)}'),
                  ],
                  const SizedBox(height: 12),
                  const Divider(height: 1, thickness: 0.5),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'FINAL BILL AMOUNT',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF03045E),
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        formatCurrencyStr(totalPayable),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF03045E),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0077B6).withAlpha(15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.info_outline, size: 14, color: Color(0xFF0077B6)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'RUPEES ${amountInWordsText.replaceAll(RegExp(r'\s+only$', caseSensitive: false), '').toUpperCase()} ONLY',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0077B6),
                              height: 1.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );

              if (isWide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(right: 32, top: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'DECLARATIONS & TERMS',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.black45,
                                letterSpacing: 1.0,
                              ),
                            ),
                            SizedBox(height: 12),
                            Text(
                              '1. Certified that the particulars given above are true and correct.\n'
                              '2. All gold jewellery is certified as per the standards of BIS.\n'
                              '3. Goods once sold will not be taken back only store credit will be provided.\n'
                              '4. Exchange will be allowed within 7 days of purchase.',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.black54,
                                height: 1.6,
                              ),
                            ),
                            SizedBox(height: 24),
                            Text(
                              'Thank you for shopping with us!',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                fontStyle: FontStyle.italic,
                                color: Color(0xFF0077B6),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 360,
                      child: summaryContent,
                    ),
                  ],
                );
              } else {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    summaryContent,
                    const SizedBox(height: 24),
                    const Divider(height: 1, thickness: 0.5),
                    const SizedBox(height: 16),
                    const Text(
                      'DECLARATIONS & TERMS',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.black45,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '1. Certified that the particulars given above are true and correct.\n'
                      '2. Subject to Bengaluru Jurisdiction.\n'
                      '3. Making VA includes value addition and melting loss charges.',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.black54,
                        height: 1.5,
                      ),
                    ),
                  ],
                );
              }
            },
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryRowItem(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade700,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderCell(String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildDataCell(String value, {bool alignLeft = false, bool isBold = false, bool isDiscount = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: Text(
        value,
        textAlign: alignLeft ? TextAlign.left : TextAlign.center,
        style: TextStyle(
          fontSize: 11,
          fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          color: isDiscount
              ? const Color(0xFFC1121F)
              : isBold
                  ? const Color(0xFF03045E)
                  : Colors.black87,
        ),
      ),
    );
  }

  Future<Uint8List> _getOrGeneratePdfBytes(BuildContext context) async {
    if (_cachedPdfBytesNotifier.value != null) {
      return _cachedPdfBytesNotifier.value!;
    }

    final ValueNotifier<double> progressNotifier = ValueNotifier<double>(0.15);
    final ValueNotifier<String> statusNotifier = ValueNotifier<String>('Loading Font Assets & Branding Logo...');

    bool dialogShown = false;

    if (context.mounted) {
      dialogShown = true;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => _PdfPercentageProgressDialog(
          progressNotifier: progressNotifier,
          statusNotifier: statusNotifier,
        ),
      );
    }

    while (_isLoadingAssetsNotifier.value) {
      await Future.delayed(const Duration(milliseconds: 15));
    }

    progressNotifier.value = 0.50;
    statusNotifier.value = 'Calculating Totals & Formatting Layout...';
    await Future.delayed(const Duration(milliseconds: 20));

    progressNotifier.value = 0.85;
    statusNotifier.value = 'Compiling High-Resolution Vector PDF Pages...';

    final doc = await _buildPdfDocumentStatic(
      bill: bill,
      customer: customer,
      ttf: _parsedTtf ?? pw.Font.helvetica(),
      ttfItalic: _parsedTtfItalic ?? pw.Font.helveticaOblique(),
      rawSvgString: _cachedSvgString ?? '',
      fontsLoadedSuccessfully: _fontsLoadedSuccessfully,
    );

    final bytes = await doc.save();
    _cachedPdfBytesNotifier.value = bytes;

    progressNotifier.value = 1.0;
    statusNotifier.value = 'Complete 100%! Opening Print Dialog...';
    await Future.delayed(const Duration(milliseconds: 30));

    if (dialogShown && context.mounted) {
      Navigator.of(context, rootNavigator: true).pop();
    }

    return bytes;
  }

  Future<void> _printInvoice(BuildContext context, Uint8List pdfBytes) async {
    try {
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) => pdfBytes,
        name: 'Invoice_${bill.slNo}.pdf',
        format: PdfPageFormat.a4,
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to print: $e', style: const TextStyle(fontWeight: FontWeight.bold)),
            backgroundColor: const Color(0xFFCC0000),
          ),
        );
      }
    }
  }

  Future<void> _shareInvoice(BuildContext context, Uint8List pdfBytes) async {
    try {
      await Printing.sharePdf(
        bytes: pdfBytes,
        filename: 'Invoice_${bill.slNo}.pdf',
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to share: $e', style: const TextStyle(fontWeight: FontWeight.bold)),
            backgroundColor: const Color(0xFFCC0000),
          ),
        );
      }
    }
  }
}

class _PdfPercentageProgressDialog extends StatelessWidget {
  final ValueNotifier<double> progressNotifier;
  final ValueNotifier<String> statusNotifier;

  const _PdfPercentageProgressDialog({
    required this.progressNotifier,
    required this.statusNotifier,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<double>(
      valueListenable: progressNotifier,
      builder: (context, progress, _) {
        final percent = (progress * 100).clamp(0, 100).toInt();
        return ValueListenableBuilder<String>(
          valueListenable: statusNotifier,
          builder: (context, statusText, _) {
            return Center(
              child: Card(
                elevation: 12,
                shadowColor: const Color(0xFF03045E).withAlpha(40),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                child: Container(
                  width: 320,
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 72,
                            height: 72,
                            child: CircularProgressIndicator(
                              value: progress > 0 ? progress : null,
                              strokeWidth: 6,
                              backgroundColor: const Color(0xFF03045E).withAlpha(25),
                              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF0077B6)),
                            ),
                          ),
                          Text(
                            '$percent%',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF03045E),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Generating Invoice PDF',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Color(0xFF03045E),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        statusText,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: progress > 0 ? progress : null,
                          minHeight: 6,
                          backgroundColor: Colors.grey.shade200,
                          valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF0077B6)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}