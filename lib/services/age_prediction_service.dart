import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class AgePredictionService {
  final String openAIKey;
  static const String baseUrl = 'https://api.openai.com/v1';

  AgePredictionService(this.openAIKey);

  Future<String> generateAgedImage(String imagePath, int targetAge) async {
    try {
      final analysisResponse = await http.post(
        Uri.parse('$baseUrl/chat/completions'),
        headers: {
          'Authorization': 'Bearer $openAIKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': 'gpt-4o-mini',
          'messages': [
            {
              'role': 'user',
              'content': [
                {
                  'type': 'text',
                  'text': '''Analyze this person's facial features in detail:
1. Face shape and structure
2. Eye shape and color
3. Nose characteristics
4. Mouth and lip shape
5. Skin tone and texture
6. Hair color, style, and texture
7. Any distinctive features

Then describe how they might naturally look at age $targetAge, focusing on realistic aging changes while maintaining their core features.'''
                },
                {
                  'type': 'image_url',
                  'image_url': {
                    'url':
                        'data:image/jpeg;base64,${base64Encode(File(imagePath).readAsBytesSync())}'
                  }
                }
              ]
            }
          ],
          'max_tokens': 1000
        }),
      );

      if (analysisResponse.statusCode != 200) {
        throw Exception('Failed to analyze image: ${analysisResponse.body}');
      }

      final analysisJson = jsonDecode(analysisResponse.body);
      final description = analysisJson['choices'][0]['message']['content'];

      final dalleResponse = await http.post(
        Uri.parse('$baseUrl/images/generations'),
        headers: {
          'Authorization': 'Bearer $openAIKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': 'dall-e-3',
          'prompt':
              '''Create a photorealistic portrait of the same person aged $targetAge years old.

Key features to maintain from the original:
$description

Critical requirements:
1. Maintain exact same face shape and bone structure
2. Keep identical eye shape and color
3. Preserve nose shape and characteristics
4. Match original skin tone
5. Use same head position and angle
6. Keep similar facial expression
7. Ensure photo looks natural and not AI-generated
8. Add age-appropriate details like fine lines and wrinkles
9. Natural hair changes for age $targetAge

Style: Photorealistic portrait, front-facing, clear lighting, neutral background''',
          'n': 1,
          'size': '1024x1024',
          'quality': 'hd',
          'style': 'natural'
        }),
      );

      if (dalleResponse.statusCode != 200) {
        throw Exception('Failed to generate image: ${dalleResponse.body}');
      }

      final dalleJson = jsonDecode(dalleResponse.body);
      return dalleJson['data'][0]['url'];
    } catch (e) {
      print('Error in generateAgedImage: $e');
      throw Exception('Failed to process image: $e');
    }
  }
}
