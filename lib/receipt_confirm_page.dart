import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ReceiptConfirmPage extends StatefulWidget {
  final Map<String, dynamic> receiptData;

  const ReceiptConfirmPage({Key? key, required this.receiptData})
    : super(key: key);

  @override
  State<ReceiptConfirmPage> createState() => _ReceiptConfirmPageState();
}

class _ReceiptConfirmPageState extends State<ReceiptConfirmPage> {
  bool _isPosting = false;

  @override
  Widget build(BuildContext context) {
    double subtotal =
        (widget.receiptData['total_amount'] ?? 0.0) -
        (widget.receiptData['tax_amount'] ?? 0.0);

    return Scaffold(
      appBar: AppBar(
        title: Text('Confirm Receipt'),
        backgroundColor: Colors.blue.shade800,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Card(
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Receipt Details',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 20),
                        _buildInfoRow(
                          'Company',
                          widget.receiptData['company_name'],
                        ),
                        _buildInfoRow(
                          'Address',
                          widget.receiptData['company_address'],
                        ),
                        SizedBox(height: 20),
                        Divider(),
                        Text(
                          'Items',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 10),
                        if (widget.receiptData['items'] != null)
                          ...((widget.receiptData['items'] as List)
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
                        _buildInfoRow(
                          'Subtotal',
                          '₱${subtotal.toStringAsFixed(2)}',
                        ),
                        _buildInfoRow(
                          'Tax',
                          '₱${widget.receiptData['tax_amount']?.toStringAsFixed(2) ?? '0.00'}',
                        ),
                        _buildInfoRow(
                          'Total',
                          '₱${widget.receiptData['total_amount']?.toStringAsFixed(2) ?? '0.00'}',
                          isTotal: true,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed:
                        _isPosting ? null : () => Navigator.pop(context, false),
                    child: Text('Cancel'),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isPosting ? null : _onSavePressed,
                    child:
                        _isPosting
                            ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                            : Text('Save'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _onSavePressed() async {
    setState(() => _isPosting = true);
    try {
      final response = await http.post(
        Uri.parse(
          'http://192.168.50.86:5678/webhook-test/7bae2dc9-ae08-4fae-bdc3-463b3a150b6a',
        ),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(widget.receiptData),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        if (mounted) {
          Future.microtask(() => Navigator.pop(context, true));
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to post receipt: \\n${response.statusCode}'),
          ), // double backslash for escaping
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to post receipt: $e')));
    } finally {
      setState(() => _isPosting = false);
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
