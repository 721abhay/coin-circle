import 'package:supabase_flutter/supabase_flutter.dart';

class SupportService {
  static final _supabase = Supabase.instance.client;

  // Create a new support ticket
  static Future<Map<String, dynamic>?> createTicket({
    required String category,
    required String subject,
    required String description,
    required String priority,
    List<String>? attachmentUrls,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not logged in');

      final response = await _supabase.from('support_tickets').insert({
        'user_id': userId,
        'category': category,
        'subject': subject,
        'description': description,
        'priority': priority,
        'status': 'open',
        'attachments': attachmentUrls ?? [],
      }).select().single();

      return response;
    } catch (e) {
      print('Error creating ticket: $e');
      throw e;
    }
  }

  // Fetch FAQs
  static Future<List<Map<String, dynamic>>> getFaqs() async {
    try {
      final response = await _supabase
          .from('faqs')
          .select()
          .eq('is_published', true)
          .order('display_order', ascending: true);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching FAQs: $e');
      return [];
    }
  }

  // Fetch Tutorials
  static Future<List<Map<String, dynamic>>> getTutorials() async {
    try {
      final response = await _supabase
          .from('tutorials')
          .select()
          .eq('is_published', true)
          .order('display_order', ascending: true);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching tutorials: $e');
      return [];
    }
  }

  // Fetch user's tickets
  static Future<List<Map<String, dynamic>>> getUserTickets() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];

      final response = await _supabase
          .from('support_tickets')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching user tickets: $e');
      return [];
    }
  }
}
