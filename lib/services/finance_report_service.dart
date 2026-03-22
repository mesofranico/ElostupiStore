import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/financial_record.dart';

class FinanceReportService {
  static Future<void> generateAndPrintReport({
    required String title,
    required DateTime startDate,
    required DateTime endDate,
    required double totalIncome,
    required double totalExpense,
    required Map<String, dynamic> incomeBreakdown,
    required List<FinancialRecord> records,
  }) async {
    final font = await PdfGoogleFonts.interRegular();
    final boldFont = await PdfGoogleFonts.interBold();
    final pdf = pw.Document();
    final dateFormat = DateFormat('dd/MM/yy');
    final currencyFormat = NumberFormat.currency(symbol: '€', locale: 'pt_PT');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        theme: pw.ThemeData.withFont(
          base: font,
          bold: boldFont,
        ),
        build: (pw.Context context) {
          return [
            // Header
            pw.Header(
              level: 0,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Relatório Financeiro',
                        style: pw.TextStyle(
                          fontSize: 24,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        'Associação Elos de Tupinambá',
                        style: const pw.TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'Período: ${dateFormat.format(startDate)} - ${dateFormat.format(endDate)}',
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                      pw.Text(
                        'Gerado em: ${dateFormat.format(DateTime.now())}',
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 20),

            // Summary Cards
            pw.Row(
              children: [
                _buildSummaryBox('Total Entradas', totalIncome, PdfColors.green, boldFont),
                pw.SizedBox(width: 20),
                _buildSummaryBox('Total Gastos', totalExpense, PdfColors.red, boldFont),
                pw.SizedBox(width: 20),
                _buildSummaryBox(
                  'Balanço Final',
                  totalIncome - totalExpense,
                  (totalIncome - totalExpense) >= 0
                      ? PdfColors.blue
                      : PdfColors.orange,
                  boldFont,
                ),
              ],
            ),
            pw.SizedBox(height: 30),

            // Breakdown Section
            pw.Text(
              'Detalhamento de Receitas',
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
            ),
            pw.Divider(),
            pw.SizedBox(height: 10),
            _buildBreakdownRow(
              'Mensalidades',
              incomeBreakdown['membership']?.toDouble() ?? 0.0,
              currencyFormat,
            ),
            _buildBreakdownRow(
              'Venda de Produtos',
              incomeBreakdown['sales']?.toDouble() ?? 0.0,
              currencyFormat,
            ),
            _buildBreakdownRow(
              'Sessões (Presenças)',
              incomeBreakdown['sessions']?.toDouble() ?? 0.0,
              currencyFormat,
            ),
            if ((incomeBreakdown['other']?.toDouble() ?? 0.0) > 0)
              _buildBreakdownRow(
                'Outras Entradas',
                incomeBreakdown['other']?.toDouble() ?? 0.0,
                currencyFormat,
              ),
            pw.SizedBox(height: 30),

            // Transactions Table
            pw.Text(
              'Lista de Transações',
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
            ),
            pw.Divider(),
            pw.SizedBox(height: 10),
            pw.TableHelper.fromTextArray(
              headers: ['Data', 'Categoria', 'Descrição', 'Tipo', 'Valor'],
              data: records.map((r) {
                return [
                  dateFormat.format(r.recordDate),
                  r.category,
                  r.description ?? '-',
                  r.type == 'income' ? 'Entrada' : 'Saída',
                  currencyFormat.format(r.amount),
                ];
              }).toList(),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
              cellAlignment: pw.Alignment.centerLeft,
              cellStyle: const pw.TextStyle(fontSize: 10),
              columnWidths: {
                0: const pw.FixedColumnWidth(60),
                1: const pw.FixedColumnWidth(100),
                2: const pw.FlexColumnWidth(),
                3: const pw.FixedColumnWidth(50),
                4: const pw.FixedColumnWidth(70),
              },
            ),
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Relatorio_Financeiro_${dateFormat.format(startDate)}.pdf',
    );
  }

  static pw.Widget _buildSummaryBox(String label, double value, PdfColor color, pw.Font boldFont) {
    final currencyFormat = NumberFormat.currency(symbol: '€', locale: 'pt_PT');
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: color, width: 2),
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(label, style: const pw.TextStyle(fontSize: 10)),
            pw.SizedBox(height: 5),
            pw.Text(
              currencyFormat.format(value),
              style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
                font: boldFont,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static pw.Widget _buildBreakdownRow(
    String label,
    double value,
    NumberFormat format,
  ) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label),
          pw.Text(
            format.format(value),
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
