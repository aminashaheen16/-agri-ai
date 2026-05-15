import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/app_constants.dart';

class GroqService {
  final String _baseUrl = 'https://api.groq.com/openai/v1/chat/completions';

  Stream<String> getChatResponseStream(String prompt, List<Map<String, String>> history) async* {
    print('GroqService: Starting chat response stream...');
    try {
      final List<Map<String, String>> messages = [
        {
          'role': 'system',
          'content': 'أنت مساعد زراعي ذكي متخصص حصراً في المجال الزراعي. أجب فقط على الأسئلة المتعلقة بالزراعة والنباتات والتربة والري والأمراض الزراعية والمحاصيل. إذا سألك المستخدم عن أي موضوع آخر، اعتذر بلطف وأخبره أنك متخصص في الزراعة فقط. اجعل إجاباتك مختصرة وعملية ومفيدة.'
        },
        ...history,
        {'role': 'user', 'content': prompt}
      ];

      final request = http.Request('POST', Uri.parse(_baseUrl));
      request.headers.addAll({
        'Authorization': 'Bearer ${AppConstants.groqApiKey}',
        'Content-Type': 'application/json',
      });
      
      request.body = jsonEncode({
        'model': AppConstants.groqModel,
        'messages': messages,
        'max_tokens': 1024,
        'temperature': 0.7,
        'stream': true,
      });

      final client = http.Client();
      final response = await client.send(request);

      if (response.statusCode == 200) {
        await for (var line in response.stream.transform(utf8.decoder).transform(const LineSplitter())) {
          if (line.trim().isEmpty) continue;
          if (line.startsWith('data: ')) {
            final data = line.substring(6);
            if (data == '[DONE]') break;
            try {
              final json = jsonDecode(data);
              final content = json['choices'][0]['delta']['content'] as String?;
              if (content != null) {
                yield content;
              }
            } catch (e) {
              print('GroqService: Error decoding stream chunk: $e');
            }
          }
        }
      } else {
        final errorBody = await response.stream.bytesToString();
        print('GroqService: API Error Body: $errorBody');
        yield 'عذراً، حدث خطأ في الاتصال بالمساعد الذكي. (كود: ${response.statusCode})';
      }
    } catch (e) {
      print('GroqService: Exception: $e');
      yield 'عذراً، حدث خطأ غير متوقع. ($e)';
    }
  }

  Future<String> getSingleResponse(String prompt) async {
    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Authorization': 'Bearer ${AppConstants.groqApiKey}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': AppConstants.groqModel,
          'messages': [
            {'role': 'user', 'content': prompt}
          ],
          'max_tokens': 500,
          'temperature': 0.5,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return (data['choices'][0]['message']['content'] as String).trim();
      }
      return 'عذراً، تعذر الحصول على تحليل إضافي حالياً.';
    } catch (e) {
      return 'عذراً، حدث خطأ في الحصول على التحليل.';
    }
  }

  Future<String> generateTitle(String firstMessage) async {
    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Authorization': 'Bearer ${AppConstants.groqApiKey}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': AppConstants.groqModel,
          'messages': [
            {
              'role': 'system',
              'content': 'أنت مساعد. قم بتوليد عنوان قصير جداً (أقل من 5 كلمات) يلخص سؤال المستخدم التالي باللغة العربية. أعطني العنوان فقط بدون أي شرح أو علامات تنصيص.'
            },
            {'role': 'user', 'content': firstMessage}
          ],
          'max_tokens': 20,
          'temperature': 0.5,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return (data['choices'][0]['message']['content'] as String).trim().replaceAll('"', '');
      }
      return 'محادثة جديدة';
    } catch (e) {
      return 'محادثة جديدة';
    }
  }
}
