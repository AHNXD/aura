import 'dart:convert';
import 'package:http/http.dart' as http;

class ChatService {
  // Placeholder n8n webhook URL - replace with your actual URL
  static const String n8nWebhookUrl =
      'http://10.162.238.64:5678/webhook-test/chat';

  Future<String> sendMessageToN8n(String message, {String? sessionId}) async {
    try {
      final response = await http
          .post(
            Uri.parse(n8nWebhookUrl),
            headers: {'Content-Type': 'application/json'},
            // In chat_service.dart -> sendMessageToN8n
            body: jsonEncode({
              'message': message,
              'timestamp': DateTime.now().toIso8601String(),
              'sessionId': sessionId ?? 'anonymous_user',
            }),
          )
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw Exception('Request timeout - n8n server not responding');
            },
          );

      if (response.statusCode == 200) {
        // Parse the response
        final jsonResponse = jsonDecode(response.body);

        // Extract the message from response
        // Adjust this based on your n8n workflow response structure
        String assistantMessage =
            jsonResponse['message'] ??
            jsonResponse['response'] ??
            jsonResponse['data'] ??
            'No response received';

        return assistantMessage;
      } else {
        throw Exception(
          'Failed to get response from n8n: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error communicating with n8n: $e');
    }
  }
}
