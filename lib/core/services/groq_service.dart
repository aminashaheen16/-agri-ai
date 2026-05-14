import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/app_constants.dart';

class GroqService {
  final _supabase = Supabase.instance.client;

  Future<String> getChatResponse(String prompt, List<Map<String, String>> history) async {
    try {
      // جلب قائمة المنتجات ليرشحها الشات بوت (كما في النسخة القديمة)
      final productResponse = await _supabase
          .from('products_with_price')
          .select('name, description, price_egp')
          .limit(15);
      
      final List<dynamic> products = productResponse as List<dynamic>;
      
      String productsList = products.map((p) => 
        "- ${p['name']} (السعر: ${p['price_egp']} ج.م)"
      ).join("\n");

      final List<Map<String, String>> messages = [
        {
          'role': 'system',
          'content': '''أنت "دكتور زراعي" خبير وبشري متخصص جداً في تطبيق Soil For Soul (Agri AI). 
شخصيتك: ودود، ذكي، خبير زراعي حقيقي، وتفتخر جداً بمشروعنا. 
مهمتك: مساعدة المزارعين في حل مشاكل نباتاتهم وتقديم نصائح احترافية بلهجة مصرية عامية ودودة.

قواعد هامة:
1. الذاكرة: تذكر دائماً ما قاله المستخدم وكن مترابطاً.
2. المتجر: إليك قائمة بالمنتجات المتوفرة في متجرنا حالياً:
$productsList

3. التوصيات: عندما تقترح علاجاً، ابحث في قائمة المنتجات أعلاه. إذا وجد منتج مناسب، رشحه بالاسم والسعر، وقل له: "المنتج ده موجود عندنا في الستور وممكن يوصلك لحد البيت".
4. الأسلوب: تكلم بلهجة مصرية عامية (كأنك دكتور بشري متخصص).
5. ممنوع الهلوسة: إذا كنت لا تعرف معلومة، قل لا أعرف ولا تخترع منتجات غير موجودة.
6. سؤاله في النهاية: دائماً اسأل المستخدم إذا كان يحتاج مساعدة في شيء آخر.'''
        },
        ...history,
        {'role': 'user', 'content': prompt}
      ];

      final response = await http.post(
        Uri.parse('https://api.groq.com/openai/v1/chat/completions'),
        headers: {
          'Authorization': 'Bearer ${AppConstants.groqApiKey}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': 'llama-3.1-70b-versatile', // استخدام موديل قوي وذكي جداً
          'messages': messages,
          'max_tokens': 1024,
          'temperature': 0.7,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'] as String;
      } else {
        final err = jsonDecode(response.body);
        print('Groq Error: $err');
        return "أنا أسف جداً، في مشكلة بسيطة في الاتصال. ممكن تحاول تبعت رسالتك تاني؟";
      }
    } catch (e) {
      print('Chat Service Exception: $e');
      return "أهلاً بك! أنا الدكتور الزراعي، للأسف واجهت مشكلة في الاتصال حالياً. هل يمكنك المحاولة مرة أخرى؟";
    }
  }
}
