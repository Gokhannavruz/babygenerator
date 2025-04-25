import 'package:flutter_dotenv/flutter_dotenv.dart';

String BASE_URL = "https://api.openai.com/v1";
String get API_KEY => dotenv.env['OPENAI_API_KEY'] ?? '';

class ApiConstants {
  // OpenAI API anahtarınızı .env dosyasından okur
  static String get OPENAI_API_KEY => dotenv.env['OPENAI_API_KEY'] ?? '';
}
