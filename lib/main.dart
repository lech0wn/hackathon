import 'dart:convert';

import 'package:flutter/material.dart';
import 'supabase_service.dart';
import 'qr_scan_page.dart';
import 'receipt_confirm_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseService.initialize(); // <-- Make sure this runs before runApp
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Receipt Scanner',
      theme: ThemeData(primarySwatch: Colors.blue),
      initialRoute: '/',
      routes: {
        '/': (context) => WelcomePage(),
        '/dashboard': (context) => DashboardPage(),
        '/receipt': (context) => ReceiptPage(),
      },
    );
  }
}

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade400, Colors.blue.shade800],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.receipt_long, size: 100, color: Colors.white),
              SizedBox(height: 20),
              Text(
                'Re-Save-O',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 10),
              Text(
                'Digitalize your receipts instantly',
                style: TextStyle(fontSize: 16, color: Colors.white70),
              ),
              SizedBox(height: 40),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.blue.shade800,
                  padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                ),
                child: Text('Get Started', style: TextStyle(fontSize: 18)),
                onPressed: () => Navigator.pushNamed(context, '/dashboard'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  _DashboardPageState createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  bool isLoading = false;
  bool isLoadingReceipts = true;
  List<Map<String, dynamic>> receipts = [];

  final String sampleReceiptJson = '''
  {
    "company_name": "SuperMart Grocery Store",
    "company_address": "123 Main Street, Cebu City, Philippines",
    "items": [
      "Organic Milk 1L - Qty: 2 - ₱9.00",
      "Whole Wheat Bread - Qty: 1 - ₱3.25", 
      "Fresh Bananas (kg) - Qty: 1.5 - ₱4.20",
      "Chicken Breast (kg) - Qty: 0.8 - ₱12.50",
      "Rice 5kg - Qty: 1 - ₱25.00"
    ],
    "tax_amount": 5.40,
    "total_amount": 59.35
  }
  ''';

  @override
  void initState() {
    super.initState();
    _loadReceipts();
  }

  Future<void> _loadReceipts() async {
    setState(() => isLoadingReceipts = true);

    try {
      final fetchedReceipts = await SupabaseService.getReceipts();
      setState(() {
        receipts = fetchedReceipts;
        isLoadingReceipts = false;
      });
    } catch (e) {
      setState(() => isLoadingReceipts = false);
      _showError('Failed to load receipts: $e');
    }
  }

  Future<void> fetchReceiptData() async {
    setState(() => isLoading = true);

    try {
      final scannedJson = await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => QRScanPage()),
      );

      if (scannedJson != null) {
        final receiptData = jsonDecode(scannedJson);

        // Show full-screen confirmation page
        final shouldSave = await Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder: (context) => ReceiptConfirmPage(receiptData: receiptData),
          ),
        );

        if (shouldSave == true) {
          await SupabaseService.saveReceipt(receiptData);
          _loadReceipts();
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Receipt saved!')));
        }
      }
    } catch (e) {
      _showError('Failed to process receipt data: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Dashboard'),
        backgroundColor: Colors.blue.shade800,
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: Icon(Icons.refresh), onPressed: _loadReceipts),
        ],
      ),
      body: Container(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Process Receipt Card
            Card(
              elevation: 4,
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  children: [
                    Icon(
                      Icons.camera_alt,
                      size: 60,
                      color: Colors.blue.shade800,
                    ),
                    SizedBox(height: 15),
                    Text(
                      'Scan Receipt',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Process your receipt and get digital access',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                    SizedBox(height: 20),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade800,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          horizontal: 30,
                          vertical: 15,
                        ),
                      ),
                      onPressed: isLoading ? null : fetchReceiptData,
                      child:
                          isLoading
                              ? Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 10),
                                  Text('Processing...'),
                                ],
                              )
                              : Text(
                                'Process Receipt',
                                style: TextStyle(fontSize: 16),
                              ),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 20),

            // Receipts List Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Your Receipts',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                Text(
                  '${receipts.length} receipts',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                ),
              ],
            ),
            SizedBox(height: 10),

            // Receipts List
            Expanded(
              child:
                  isLoadingReceipts
                      ? Center(child: CircularProgressIndicator())
                      : receipts.isEmpty
                      ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.receipt_long_outlined,
                              size: 64,
                              color: Colors.grey.shade400,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'No receipts found',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Process your first receipt to get started!',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      )
                      : RefreshIndicator(
                        onRefresh: _loadReceipts,
                        child: ListView.builder(
                          itemCount: receipts.length,
                          itemBuilder: (context, index) {
                            final receipt = receipts[index];
                            return Card(
                              margin: EdgeInsets.only(bottom: 10),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Colors.blue.shade100,
                                  child: Icon(
                                    Icons.receipt,
                                    color: Colors.blue.shade800,
                                  ),
                                ),
                                title: Text(
                                  receipt['company_name'] ?? 'Unknown Store',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (receipt['company_address'] != null)
                                      Text(
                                        receipt['company_address'],
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(fontSize: 12),
                                      ),
                                    SizedBox(height: 4),
                                    Text(
                                      'Total: ₱${receipt['total_amount']?.toStringAsFixed(2) ?? '0.00'}',
                                      style: TextStyle(
                                        color: Colors.green.shade700,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                                trailing: Icon(
                                  Icons.arrow_forward_ios,
                                  size: 16,
                                ),
                                onTap: () {
                                  Navigator.pushNamed(
                                    context,
                                    '/receipt',
                                    arguments: receipt,
                                  );
                                },
                              ),
                            );
                          },
                        ),
                      ),
            ),
          ],
        ),
      ),
    );
  }
}

class ReceiptPage extends StatelessWidget {
  const ReceiptPage({super.key});

  @override
  Widget build(BuildContext context) {
    final dynamic receiptData = ModalRoute.of(context)?.settings.arguments;

    return Scaffold(
      appBar: AppBar(
        title: Text('Receipt Details'),
        backgroundColor: Colors.blue.shade800,
        foregroundColor: Colors.white,
      ),
      body: Container(
        padding: EdgeInsets.all(20),
        child:
            receiptData != null
                ? _buildReceiptDetails(receiptData)
                : Center(child: Text('No receipt data found.')),
      ),
    );
  }

  Widget _buildReceiptDetails(dynamic data) {
    if (data is Map<String, dynamic>) {
      // Calculate subtotal (total - tax)
      double subtotal =
          (data['total_amount'] ?? 0.0) - (data['tax_amount'] ?? 0.0);

      return SingleChildScrollView(
        child: Card(
          elevation: 4,
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Receipt Details',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 20),

                // Company info (using your database fields)
                _buildInfoRow('Company', data['company_name']),
                _buildInfoRow('Address', data['company_address']),

                SizedBox(height: 20),
                Divider(),

                // Items section (using your database field)
                Text(
                  'Items',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 10),

                if (data['items'] != null)
                  ...((data['items'] as List)
                      .map(
                        (item) => Padding(
                          padding: EdgeInsets.symmetric(vertical: 3),
                          child: Text(
                            '• $item',
                            style: TextStyle(fontSize: 14),
                          ),
                        ),
                      )
                      .toList()),

                SizedBox(height: 15),
                Divider(),

                // Totals (using your database fields)
                _buildInfoRow('Subtotal', '₱${subtotal.toStringAsFixed(2)}'),
                _buildInfoRow(
                  'Tax',
                  '₱${data['tax_amount']?.toStringAsFixed(2) ?? '0.00'}',
                ),
                _buildInfoRow(
                  'Total',
                  '₱${data['total_amount']?.toStringAsFixed(2) ?? '0.00'}',
                  isTotal: true,
                ),
              ],
            ),
          ),
        ),
      );
    } else {
      return Card(
        elevation: 4,
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Receipt Data',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 20),
              Text('$data'),
            ],
          ),
        ),
      );
    }
  }

  Widget _buildInfoRow(String label, dynamic value, {bool isTotal = false}) {
    if (value == null) return SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '$label:',
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              fontSize: isTotal ? 16 : 14,
            ),
          ),
          Flexible(
            child: Text(
              '$value',
              style: TextStyle(
                fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
                fontSize: isTotal ? 16 : 14,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}
