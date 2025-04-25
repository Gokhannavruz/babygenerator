import 'package:babyprediction/src/model/singletons_data.dart';
import 'package:babyprediction/src/views/paywall.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:babyprediction/constants/api_constants.dart';
import 'package:babyprediction/models/app_colors.dart';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:launch_review/launch_review.dart';

// Models
class GeneratedName {
  final String id;
  final String name;
  final String meaning;
  final String origin;
  final String imageUrl;
  final DateTime createdAt;
  final bool usedFreeCredit;

  GeneratedName({
    required this.id,
    required this.name,
    required this.meaning,
    required this.origin,
    required this.imageUrl,
    required this.createdAt,
    this.usedFreeCredit = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'meaning': meaning,
        'origin': origin,
        'imageUrl': imageUrl,
        'createdAt': createdAt.toIso8601String(),
        'usedFreeCredit': usedFreeCredit,
      };

  factory GeneratedName.fromJson(Map<String, dynamic> json) => GeneratedName(
        id: json['id'],
        name: json['name'],
        meaning: json['meaning'],
        origin: json['origin'],
        imageUrl: json['imageUrl'],
        createdAt: DateTime.parse(json['createdAt']),
        usedFreeCredit: json['usedFreeCredit'] ?? false,
      );
}

// Providers
final generatedNamesProvider =
    StateNotifierProvider<GeneratedNamesNotifier, List<GeneratedName>>((ref) {
  return GeneratedNamesNotifier();
});

class GeneratedNamesNotifier extends StateNotifier<List<GeneratedName>> {
  GeneratedNamesNotifier() : super([]) {
    loadSavedNames();
  }

  Future<bool> canGenerateName() async {
    if (appData.entitlementIsActive) return true;

    final prefs = await SharedPreferences.getInstance();
    final usedCredits = prefs.getInt('name_generator_credits') ?? 0;
    return usedCredits < 1; // Sadece 1 ücretsiz kredi
  }

  Future<void> markCreditUsed() async {
    final prefs = await SharedPreferences.getInstance();
    final currentCredits = prefs.getInt('name_generator_credits') ?? 0;
    await prefs.setInt('name_generator_credits', currentCredits + 1);
  }

  Future<void> loadSavedNames() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedNames = prefs.getStringList('generated_names') ?? [];

      final loadedNames = savedNames
          .map((nameJson) {
            try {
              return GeneratedName.fromJson(jsonDecode(nameJson));
            } catch (e) {
              print('Error parsing name: $e');
              return null;
            }
          })
          .whereType<GeneratedName>()
          .toList();

      loadedNames.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      state = loadedNames;
    } catch (e) {
      print('Error loading saved names: $e');
      state = [];
    }
  }

  Future<void> addName(
      String name, String meaning, String origin, String imagePath) async {
    try {
      // Get local storage directory
      final appDir = await getApplicationDocumentsDirectory();
      final fileName = 'name_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final localPath = '${appDir.path}/$fileName';

      // Copy image to local storage
      await File(imagePath).copy(localPath);

      final newName = GeneratedName(
        id: const Uuid().v4(),
        name: name,
        meaning: meaning,
        origin: origin,
        imageUrl: localPath, // Store local path instead of URL
        createdAt: DateTime.now(),
        usedFreeCredit: !appData.entitlementIsActive,
      );

      state = [...state, newName];
      await _saveNames();
      await markCreditUsed();
    } catch (e) {
      print('Error saving name image: $e');
      rethrow;
    }
  }

  Future<void> deleteName(String id) async {
    try {
      final nameToDelete = state.firstWhere((name) => name.id == id);

      // Dosyayı fiziksel olarak sil
      final file = File(nameToDelete.imageUrl);
      if (await file.exists()) {
        await file.delete();
      }

      // State'den kaldır
      state = state.where((name) => name.id != id).toList();
      await _saveNames();
    } catch (e) {
      print('Error deleting name: $e');
      rethrow;
    }
  }

  Future<void> _saveNames() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final namesJson = state.map((name) => jsonEncode(name.toJson())).toList();
      await prefs.setStringList('generated_names', namesJson);
    } catch (e) {
      print('Error saving names: $e');
    }
  }
}

// Service
class NameGeneratorService {
  final String openAIKey;
  static const String baseUrl = 'https://api.openai.com/v1';

  NameGeneratorService(this.openAIKey);

  Future<Map<String, String>?> generateName(
      String imageUrl, String country) async {
    try {
      // Önce resmi base64'e çevir
      final File imageFile = File(imageUrl);
      final List<int> imageBytes = await imageFile.readAsBytes();
      final String base64Image = base64Encode(imageBytes);

      final response = await http.post(
        Uri.parse('$baseUrl/chat/completions'),
        headers: {
          'Authorization': 'Bearer $openAIKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': 'gpt-4o-mini', // Doğru model adı
          'messages': [
            {
              'role': 'user',
              'content': [
                {
                  'type': 'text',
                  'text':
                      '''Based on this child's appearance and considering they are from $country, suggest a suitable name. 
                  Please respond in this exact JSON format:
                  {
                    "name": "Suggested name",
                    "meaning": "What the name means",
                    "origin": "Cultural origin of the name"
                  }'''
                },
                {
                  'type': 'image_url',
                  'image_url': {'url': 'data:image/jpeg;base64,$base64Image'}
                }
              ]
            }
          ],
          'max_tokens': 1000
        }),
      );

      if (response.statusCode != 200) {
        print('API Error: ${response.body}');
        throw Exception('Failed to generate name: ${response.statusCode}');
      }

      final result = jsonDecode(response.body);
      print(
          'API Response: ${result['choices'][0]['message']['content']}'); // Debug için

      final content = result['choices'][0]['message']['content'];
      // JSON string'i temizle ve parse et
      final cleanJson = content.trim().replaceAll(RegExp(r'```json|```'), '');
      final nameData = jsonDecode(cleanJson);

      return {
        'name': nameData['name'],
        'meaning': nameData['meaning'],
        'origin': nameData['origin'],
      };
    } catch (e) {
      print('Service Error: $e');
      return null;
    }
  }
}

// Screen
class BabyNameGeneratorScreen extends ConsumerStatefulWidget {
  @override
  _BabyNameGeneratorScreenState createState() =>
      _BabyNameGeneratorScreenState();
}

class _BabyNameGeneratorScreenState
    extends ConsumerState<BabyNameGeneratorScreen> {
  final ImagePicker _picker = ImagePicker();
  File? selectedImage;
  String? selectedCountry;
  bool isGenerating = false;
  final List<String> countries = [
    'Afghanistan',
    'Albania',
    'Algeria',
    'Andorra',
    'Angola',
    'Argentina',
    'Armenia',
    'Australia',
    'Austria',
    'Azerbaijan',
    'Bahamas',
    'Bahrain',
    'Bangladesh',
    'Barbados',
    'Belarus',
    'Belgium',
    'Belize',
    'Benin',
    'Bhutan',
    'Bolivia',
    'Brazil',
    'Bulgaria',
    'Cambodia',
    'Cameroon',
    'Canada',
    'Chad',
    'Chile',
    'China',
    'Colombia',
    'Congo',
    'Costa Rica',
    'Croatia',
    'Cuba',
    'Cyprus',
    'Czech Republic',
    'Denmark',
    'Ecuador',
    'Egypt',
    'Estonia',
    'Ethiopia',
    'Fiji',
    'Finland',
    'France',
    'Georgia',
    'Germany',
    'Ghana',
    'Greece',
    'Guatemala',
    'Haiti',
    'Honduras',
    'Hungary',
    'Iceland',
    'India',
    'Indonesia',
    'Iran',
    'Iraq',
    'Ireland',
    'Israel',
    'Italy',
    'Jamaica',
    'Japan',
    'Jordan',
    'Kazakhstan',
    'Kenya',
    'Kuwait',
    'Kyrgyzstan',
    'Laos',
    'Latvia',
    'Lebanon',
    'Libya',
    'Lithuania',
    'Luxembourg',
    'Madagascar',
    'Malaysia',
    'Maldives',
    'Mali',
    'Malta',
    'Mexico',
    'Moldova',
    'Monaco',
    'Mongolia',
    'Montenegro',
    'Morocco',
    'Myanmar',
    'Nepal',
    'Netherlands',
    'New Zealand',
    'Nicaragua',
    'Nigeria',
    'North Korea',
    'Norway',
    'Oman',
    'Pakistan',
    'Panama',
    'Paraguay',
    'Peru',
    'Philippines',
    'Poland',
    'Portugal',
    'Qatar',
    'Romania',
    'Russia',
    'Rwanda',
    'Saudi Arabia',
    'Senegal',
    'Serbia',
    'Singapore',
    'Slovakia',
    'Slovenia',
    'Somalia',
    'South Africa',
    'South Korea',
    'Spain',
    'Sri Lanka',
    'Sudan',
    'Sweden',
    'Switzerland',
    'Syria',
    'Taiwan',
    'Tanzania',
    'Thailand',
    'Tunisia',
    'Turkey',
    'Uganda',
    'Ukraine',
    'United Arab Emirates',
    'United Kingdom',
    'United States',
    'Uruguay',
    'Uzbekistan',
    'Venezuela',
    'Vietnam',
    'Yemen',
    'Zimbabwe'
  ]..sort();

  final NameGeneratorService nameService = NameGeneratorService(
    ApiConstants.OPENAI_API_KEY,
  );

  Future<void> pickImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (image != null) {
      setState(() {
        selectedImage = File(image.path);
      });
    }
  }

  Future<void> generateNameFromImage() async {
    if (selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a photo first')),
      );
      return;
    }

    // Premium veya kredi kontrolü
    if (!appData.entitlementIsActive) {
      final canGenerate =
          await ref.read(generatedNamesProvider.notifier).canGenerateName();
      if (!canGenerate) {
        if (mounted) {
          final offerings = await Purchases.getOfferings();
          if (offerings.current != null) {
            await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => Paywall(offering: offerings.current!),
              ),
            );
          }
          return; // Paywall'dan döndükten sonra işlemi sonlandır
        }
      }
    }

    setState(() => isGenerating = true);

    try {
      final nameData = await nameService.generateName(
        selectedImage!.path,
        selectedCountry!,
      );

      if (nameData != null) {
        await ref.read(generatedNamesProvider.notifier).addName(
              nameData['name']!,
              nameData['meaning']!,
              nameData['origin']!,
              selectedImage!.path,
            );
        setState(() {
          selectedImage = null;
        });

        // İsim oluşturma başarılı olduktan sonra 2 saniye bekleyip kullanıcıdan yorum iste
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            _showRatingDialog();
          }
        });
      } else {
        throw Exception('Failed to generate name');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to generate name. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isGenerating = false);
      }
    }
  }

  Future<void> _showRatingDialog() async {
    if (!mounted) return;

    final prefs = await SharedPreferences.getInstance();
    final hasRated = prefs.getBool('has_rated_for_name') ?? false;
    final lastRatingDate = DateTime.parse(
        prefs.getString('last_rating_name_date') ?? DateTime.now().toString());
    final daysSinceLastRating =
        DateTime.now().difference(lastRatingDate).inDays;

    // Kullanıcı daha önce değerlendirme yapmamışsa veya son değerlendirmeden 7 gün geçtiyse
    if (!hasRated || daysSinceLastRating >= 7) {
      int selectedRating = 0;
      final size = MediaQuery.of(context).size;

      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => StatefulBuilder(
          builder: (context, setState) => Dialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: SingleChildScrollView(
              child: Container(
                width: size.width * 0.9 > 400 ? 400 : size.width * 0.9,
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Love the Baby Names?',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'How do you like our name suggestions? Your review helps other parents find us!',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 8),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: SizedBox(
                        width: 240,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: List.generate(
                            5,
                            (index) => GestureDetector(
                              onTap: () {
                                setState(() {
                                  selectedRating = index + 1;
                                });

                                // 4 veya 5 yıldız seçildiğinde App Store'a yönlendir
                                if (selectedRating >= 4) {
                                  LaunchReview.launch(
                                    androidAppId: "your.android.app.id",
                                    iOSAppId: "6740035205",
                                  );
                                  // Değerlendirme yapıldı ve tarih bilgilerini kaydet
                                  prefs.setBool('has_rated_for_name', true);
                                  prefs.setString('last_rating_name_date',
                                      DateTime.now().toString());
                                  Navigator.pop(context);
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                child: Icon(
                                  Icons.star_rounded,
                                  size: 36,
                                  color: index < selectedRating
                                      ? Colors.amber[600]
                                      : Colors.grey[400],
                                  shadows: [
                                    Shadow(
                                      color: Colors.black.withOpacity(0.2),
                                      blurRadius: 2,
                                      offset: const Offset(0, 1),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text(
                            'Maybe Later',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 14,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        FilledButton(
                          onPressed: selectedRating > 0 && selectedRating < 4
                              ? () {
                                  // Değerlendirme yapıldı ve tarih bilgilerini kaydet
                                  prefs.setBool('has_rated_for_name', true);
                                  prefs.setString('last_rating_name_date',
                                      DateTime.now().toString());
                                  Navigator.pop(context);
                                  _showFeedbackForm(selectedRating);
                                }
                              : null,
                          child: const Text(
                            'Submit',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }
  }

  Future<void> _showFeedbackForm(int rating) async {
    final feedbackController = TextEditingController();
    final size = MediaQuery.of(context).size;

    try {
      await showDialog(
        context: context,
        barrierDismissible: true,
        builder: (context) => Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            width: size.width * 0.9 > 400 ? 400 : size.width * 0.9,
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Tell us how we can improve',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Your feedback is important to us. What can we do better?',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Container(
                  constraints: BoxConstraints(
                    maxHeight: size.height * 0.2,
                  ),
                  child: TextField(
                    controller: feedbackController,
                    maxLines: null,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      hintText: 'Write your feedback here...',
                      hintStyle: const TextStyle(fontFamily: 'Poppins'),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Theme.of(context).primaryColor,
                          width: 2,
                        ),
                      ),
                      contentPadding: const EdgeInsets.all(16),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(fontFamily: 'Poppins'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    FilledButton(
                      onPressed: () async {
                        final feedback = feedbackController.text.trim();
                        if (feedback.isNotEmpty) {
                          try {
                            // Burada feedback'i backend'e gönderebilirsiniz
                            // Örnek: await sendFeedbackToBackend(rating, feedback);

                            // Başarılı mesajı göster
                            if (mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Thank you for your feedback!',
                                    style: TextStyle(fontFamily: 'Poppins'),
                                  ),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          } catch (e) {
                            // Hata durumunda sessizce devam et
                            Navigator.pop(context);
                          }
                        } else {
                          Navigator.pop(context);
                        }
                      },
                      child: const Text(
                        'Send Feedback',
                        style: TextStyle(fontFamily: 'Poppins'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    } finally {
      feedbackController.dispose();
    }
  }

  Widget _buildCountrySelector() {
    return SearchAnchor(
      builder: (BuildContext context, SearchController controller) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          child: ListTile(
            onTap: () {
              controller.openView();
            },
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: Colors.grey.withOpacity(0.3),
              ),
            ),
            title: Text(
              selectedCountry ?? 'Select a country',
              style: TextStyle(
                fontFamily: 'Poppins',
                color: selectedCountry != null
                    ? AppColors.textPrimary
                    : Colors.grey[600],
              ),
            ),
            trailing: const Icon(Icons.search),
          ),
        );
      },
      suggestionsBuilder: (BuildContext context, SearchController controller) {
        final keyword = controller.text.toLowerCase();
        return countries
            .where((country) => country.toLowerCase().contains(keyword))
            .map((country) => ListTile(
                  title: Text(
                    country,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                    ),
                  ),
                  onTap: () {
                    setState(() {
                      selectedCountry = country;
                    });
                    controller.closeView(country);
                  },
                ));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final generatedNames = ref.watch(generatedNamesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Name Generator',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  color: appData.entitlementIsActive
                      ? Colors.green[50]
                      : Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: appData.entitlementIsActive
                        ? Colors.green[200]!
                        : Colors.blue[200]!,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      appData.entitlementIsActive
                          ? Icons.stars
                          : Icons.info_outline,
                      color: appData.entitlementIsActive
                          ? Colors.green
                          : Colors.blue,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        appData.entitlementIsActive
                            ? 'Premium member - Unlimited name generations'
                            : 'Free credits remaining: 1',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: appData.entitlementIsActive
                              ? Colors.green[700]
                              : Colors.blue[700],
                        ),
                      ),
                    ),
                    if (!appData.entitlementIsActive)
                      TextButton(
                        onPressed: () async {
                          final offerings = await Purchases.getOfferings();
                          if (offerings.current != null && mounted) {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) =>
                                    Paywall(offering: offerings.current!),
                              ),
                            );
                          }
                        },
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.blue[50],
                          padding:
                              EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: Text(
                          'Get Premium',
                          style: TextStyle(
                            color: Colors.blue[700],
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              SizedBox(height: 16),
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Select Country',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'How it works:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        '1. Select the country for cultural background\n2. Upload a photo of the baby\n3. AI will suggest a name based on appearance and cultural heritage',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                          height: 1.5,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildCountrySelector(),

                      // Ülke seçildiğinde görsel seçme alanını göster
                      if (selectedCountry != null) ...[
                        const SizedBox(height: 24),
                        GestureDetector(
                          onTap: pickImage,
                          child: Container(
                            width: double.infinity,
                            height: 200,
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.grey.withOpacity(0.3),
                              ),
                            ),
                            child: selectedImage != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.file(
                                      selectedImage!,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: const [
                                      Icon(
                                        Icons.add_photo_alternate_outlined,
                                        size: 40,
                                        color: Colors.grey,
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        'Select a photo',
                                        style: TextStyle(
                                          color: Colors.grey,
                                          fontSize: 14,
                                          fontFamily: 'Poppins',
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Generate butonu
                        if (selectedImage != null)
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed:
                                  isGenerating ? null : generateNameFromImage,
                              style: ElevatedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: isGenerating
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text(
                                      'Generate Name',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontFamily: 'Poppins',
                                      ),
                                    ),
                            ),
                          ),
                      ],
                    ],
                  ),
                ),
              ),

              // Generated Names başlığı
              if (generatedNames.isNotEmpty) ...[
                const SizedBox(height: 24),
                const Text(
                  'Generated Names',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 16),
                // Generated names listesi
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: generatedNames.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final name = generatedNames[index];
                    return _buildNameCard(name);
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNameCard(GeneratedName name) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundImage: _getImageProvider(name.imageUrl),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        name.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 20),
                        onPressed: () => ref
                            .read(generatedNamesProvider.notifier)
                            .deleteName(name.id),
                      ),
                    ],
                  ),
                  Text(
                    'Origin: ${name.origin}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Meaning: ${name.meaning}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  ImageProvider _getImageProvider(String imageUrl) {
    try {
      if (imageUrl.startsWith('http')) {
        return NetworkImage(imageUrl);
      } else {
        return FileImage(File(imageUrl));
      }
    } catch (e) {
      print('Error loading image: $e');
      // Fallback to a placeholder image or asset
      return const AssetImage(
          'assets/placeholder.png'); // Make sure you have this asset
    }
  }
}
