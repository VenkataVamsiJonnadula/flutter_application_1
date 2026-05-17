import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'billing_item_model.dart';
import '../customers/customer_model.dart';
import '../customers/customer_profile_page.dart';
import '../data/mock_data.dart';

// Converted to a clean StatelessWidget to eliminate createState and widget context compilation conflicts
class ViewSalesBillPage extends StatelessWidget {
  final BillItem billItem;
  final Customer customer;

  // Unique notifier for this page instance to cache the generated PDF bytes and prevent CPU-bound re-generation freezes.
  final ValueNotifier<Uint8List?> _cachedPdfBytesNotifier = ValueNotifier<Uint8List?>(null);

  ViewSalesBillPage({
    super.key,
    required this.billItem,
    required this.customer,
  });

  // Static cache to persist loaded assets across page opens
  static Uint8List? _cachedFontBytes;
  static Uint8List? _cachedItalicFontBytes;
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

      final italicData = await rootBundle.load('assets/Rubik-Italic-VariableFont_wght.ttf');
      _cachedItalicFontBytes = italicData.buffer.asUint8List();

      _fontsLoadedSuccessfully = true;
    } catch (e) {
      debugPrint("Custom font asset load failed, falling back to clean system font defaults: $e");
      _cachedFontBytes = null;
      _cachedItalicFontBytes = null;
      _fontsLoadedSuccessfully = false;
    }

    _hasLoadedAssets = true;
    _isLoadingAssetsNotifier.value = false;
  }

  static Future<pw.Document> _buildPdfDocumentStatic({
    required BillItem billItem,
    required Customer customer,
    required pw.Font ttf,
    required pw.Font ttfItalic,
    required String rawSvgString,
    required bool fontsLoadedSuccessfully,
  }) async {

    final String wingdingDecor = fontsLoadedSuccessfully ? '✿' : '*';
    final String bulletDecor = fontsLoadedSuccessfully ? '✦' : '-';

    final pw.Widget logoWidget = rawSvgString.isNotEmpty
        ? pw.SizedBox(width: 210, height: 105, child: pw.SvgImage(svg: rawSvgString, fit: pw.BoxFit.contain))
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

    final simulatedItems = [billItem];
    final totalTaxable = simulatedItems.fold(0.0, (sum, item) => sum + item.taxableValue);
    final totalDiscount = simulatedItems.fold(0.0, (sum, item) => sum + item.discAmt);
    final totalPayable = simulatedItems.fold(0.0, (sum, item) => sum + item.totalValue) - totalDiscount;
    final amountInWordsText = _amountInWords(totalPayable);

    final firstItem = simulatedItems.first;
    final invoiceNumber = 'SVJ/${firstItem.date.year}/${firstItem.slNo.toString().padLeft(4, '0')}';
    final invoiceDate = DateFormat('dd-MM-yyyy').format(firstItem.date);

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
                pw.Text(customer.name, style: pw.TextStyle(fontSize: 11.5, fontWeight: pw.FontWeight.bold, color: const PdfColor.fromInt(0xFF1A1A1A))),
                pw.Text(customer.address, style: const pw.TextStyle(fontSize: 9.5, color: PdfColor.fromInt(0xFF333333))),
                pw.Text('Phone: ${customer.phone}', style: const pw.TextStyle(fontSize: 9.5, color: PdfColor.fromInt(0xFF333333))),
              ],
            ),
            pw.SizedBox(height: 12),

            // LINE ITEMS DATA TABLE
            pw.Table(
              border: pw.TableBorder.all(color: const PdfColor.fromInt(0xFFCCCCCC), width: 0.5),
              columnWidths: const {
                0: pw.FixedColumnWidth(20),  
                1: pw.FlexColumnWidth(2.2),  
                2: pw.FixedColumnWidth(40),  
                3: pw.FixedColumnWidth(20),  
                4: pw.FixedColumnWidth(34),  
                5: pw.FixedColumnWidth(34),  
                6: pw.FixedColumnWidth(34),  
                7: pw.FixedColumnWidth(45),  
                8: pw.FixedColumnWidth(52),  
                9: pw.FixedColumnWidth(52),  
                10: pw.FixedColumnWidth(58), 
              },
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFF2C3E50)),
                  children: [
                    'S.No', 'Description', 'HSN', 'PCS', 'Gr.Wt', 'St.Wt', 'Net Wt', 'Rate', 'Metal Value', 'Stone Value', 'Total'
                  ].map((text) {
                    return pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(vertical: 5, horizontal: 2),
                      child: pw.Text(
                        text,
                        textAlign: text == 'Description' ? pw.TextAlign.left : (['Rate', 'Metal Value', 'Stone Value', 'Total'].contains(text) ? pw.TextAlign.right : pw.TextAlign.center),
                        style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                      ),
                    );
                  }).toList(),
                ),
                ...simulatedItems.map((item) {
                  return pw.TableRow(
                    children: [
                      pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(item.slNo.toString(), textAlign: pw.TextAlign.center, style: const pw.TextStyle(fontSize: 8))),
                      pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(item.description, style: const pw.TextStyle(fontSize: 8))),
                      pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(item.hsnSac, textAlign: pw.TextAlign.center, style: const pw.TextStyle(fontSize: 8))),
                      pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(item.pcs.toString(), textAlign: pw.TextAlign.center, style: const pw.TextStyle(fontSize: 8))),
                      pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(item.grossWt.toStringAsFixed(2), textAlign: pw.TextAlign.center, style: const pw.TextStyle(fontSize: 8))),
                      pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(item.stoneWt.toStringAsFixed(2), textAlign: pw.TextAlign.center, style: const pw.TextStyle(fontSize: 8))),
                      pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(item.netWt.toStringAsFixed(2), textAlign: pw.TextAlign.center, style: const pw.TextStyle(fontSize: 8))),
                      pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(formatCurrencyStr(item.metalRate), textAlign: pw.TextAlign.right, style: const pw.TextStyle(fontSize: 8))),
                      pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(formatCurrencyStr(item.metalValue), textAlign: pw.TextAlign.right, style: const pw.TextStyle(fontSize: 8))),
                      pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(formatCurrencyStr(item.stoneValue), textAlign: pw.TextAlign.right, style: const pw.TextStyle(fontSize: 8))),
                      pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(formatCurrencyStr(item.totalValue), textAlign: pw.TextAlign.right, style: const pw.TextStyle(fontSize: 8))),
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
                      pdfTotalRow('Sub Total:', formatCurrencyStr(totalTaxable)),
                      pdfTotalRow('Discount:', '- ${formatCurrencyStr(totalDiscount)}', isDiscount: true),
                      pdfTotalRow('CGST @ 1.5%:', formatCurrencyStr(totalTaxable * 0.015)),
                      pdfTotalRow('SGST @ 1.5%:', formatCurrencyStr(totalTaxable * 0.015)),
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
          'Invoice Dashboard SVJ/#${billItem.slNo}',
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
                      customer: customer,
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
                        customer.name.isNotEmpty ? customer.name.substring(0, 1).toUpperCase() : '?',
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
                            customer.name,
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
                            'ID: ${customer.id}',
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
            _buildInfoRow(Icons.phone_outlined, customer.phone, 'Phone'),
            const SizedBox(height: 12),
            _buildInfoRow(Icons.location_on_outlined, customer.address, 'Address'),
            if (customer.email.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildInfoRow(Icons.email_outlined, customer.email, 'Email'),
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
    final customerInvoices = sharedMockItems
        .where((item) => item.customerId == customer.id)
        .toList();
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
              'RECENT PURCHASES',
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
                    'No previous purchase records.',
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
                  final isCurrent = invoice.slNo == billItem.slNo;

                  return InkWell(
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ViewSalesBillPage(
                            billItem: invoice,
                            customer: customer,
                          ),
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
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'INV-${invoice.slNo.toString().padLeft(4, '0')}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: isCurrent ? const Color(0xFF03045E) : Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  DateFormat('dd MMM yyyy').format(invoice.date),
                                  style: const TextStyle(fontSize: 10, color: Colors.black45),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                currencyFormatter.format(invoice.totalValue),
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
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
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
    final invoiceNumber = 'SVJ/${billItem.date.year}/${billItem.slNo.toString().padLeft(4, '0')}';
    final invoiceDate = DateFormat('dd-MM-yyyy').format(billItem.date);

    final simulatedItems = [billItem];
    final totalTaxable = simulatedItems.fold(0.0, (sum, item) => sum + item.taxableValue);
    final totalDiscount = simulatedItems.fold(0.0, (sum, item) => sum + item.discAmt);
    final totalPayable = simulatedItems.fold(0.0, (sum, item) => sum + item.totalValue) - totalDiscount;
    final totalCgst = totalTaxable * 0.015;
    final totalSgst = totalTaxable * 0.015;
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
                            'RUPEES ${amountInWordsText.toUpperCase()} ONLY',
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

    // Wait if assets are still loading in the background
    while (_isLoadingAssetsNotifier.value) {
      await Future.delayed(const Duration(milliseconds: 50));
    }

    // Show progress dialog to notify user that PDF is compiling
    if (context.mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: Card(
            elevation: 8,
            shadowColor: Colors.black26,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16))),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: Color(0xFF03045E)),
                  SizedBox(height: 20),
                  Text(
                    'Generating Invoice PDF...',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Color(0xFF03045E),
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Compiling vector document assets',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.black45,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // Give framework time to render the loading dialog
    await Future.delayed(const Duration(milliseconds: 150));

    final bytes = await compute(_generatePdfBytesInBackground, PdfGenerationInput(
      billItem: billItem,
      customer: customer,
      fontBytes: _cachedFontBytes,
      italicFontBytes: _cachedItalicFontBytes,
      svgString: _cachedSvgString ?? '',
      fontsLoadedSuccessfully: _fontsLoadedSuccessfully,
    ));

    _cachedPdfBytesNotifier.value = bytes;

    if (context.mounted) {
      Navigator.pop(context); // Dismiss the progress dialog
    }

    return bytes;
  }

  Future<void> _printInvoice(BuildContext context, Uint8List pdfBytes) async {
    try {
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) => pdfBytes,
        name: 'Invoice_SVJ_${billItem.slNo}.pdf',
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
        filename: 'Invoice_SVJ_${billItem.slNo}.pdf',
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

  static Future<Uint8List> _generatePdfBytesInBackground(PdfGenerationInput input) async {
    final pw.Font ttf = input.fontBytes != null
        ? pw.Font.ttf(ByteData.sublistView(input.fontBytes!))
        : pw.Font.helvetica();
    final pw.Font ttfItalic = input.italicFontBytes != null
        ? pw.Font.ttf(ByteData.sublistView(input.italicFontBytes!))
        : pw.Font.helveticaOblique();

    final doc = await _buildPdfDocumentStatic(
      billItem: input.billItem,
      customer: input.customer,
      ttf: ttf,
      ttfItalic: ttfItalic,
      rawSvgString: input.svgString,
      fontsLoadedSuccessfully: input.fontsLoadedSuccessfully,
    );

    return doc.save();
  }
}

class PdfGenerationInput {
  final BillItem billItem;
  final Customer customer;
  final Uint8List? fontBytes;
  final Uint8List? italicFontBytes;
  final String svgString;
  final bool fontsLoadedSuccessfully;

  PdfGenerationInput({
    required this.billItem,
    required this.customer,
    required this.fontBytes,
    required this.italicFontBytes,
    required this.svgString,
    required this.fontsLoadedSuccessfully,
  });
}