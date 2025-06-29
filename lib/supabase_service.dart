import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static const String supabaseUrl = 'https://khqykhxiqnqzvlzkmukz.supabase.co';
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImtocXlraHhpcW5xenZsemttdWt6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDk5NjQwMzQsImV4cCI6MjA2NTU0MDAzNH0.7PbcsRcC12aAJ66pwhkb8QAn5SCw7Rj3WPDTlWaKtzo';

  static SupabaseClient get client => Supabase.instance.client;

  static Future<void> initialize() async {
    await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
  }

  // Fetch all receipts from your existing table
  static Future<List<Map<String, dynamic>>> getReceipts() async {
    final response = await client
        .from('receipt') // Using your existing table name
        .select()
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  static Future<void> saveReceipt(Map<String, dynamic> receipt) async {
    await client.from('receipt').insert(receipt);
  }
}
