import 'package:babyprediction/src/model/singletons_data.dart';
import 'package:babyprediction/src/views/paywall.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:babyprediction/constants/api_constants.dart';
import 'package:launch_review/launch_review.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:babyprediction/models/app_colors.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';

// Models
// Model
class GeneratedBaby {
  final String id;
  final String imageUrl;
  final String motherImageUrl;
  final String fatherImageUrl;
  final DateTime createdAt;
  final bool usedFreeCredit;

  GeneratedBaby({
    required this.id,
    required this.imageUrl,
    required this.motherImageUrl,
    required this.fatherImageUrl,
    required this.createdAt,
    this.usedFreeCredit = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'imageUrl': imageUrl,
        'motherImageUrl': motherImageUrl,
        'fatherImageUrl': fatherImageUrl,
        'createdAt': createdAt.toIso8601String(),
        'usedFreeCredit': usedFreeCredit,
      };

  factory GeneratedBaby.fromJson(Map<String, dynamic> json) => GeneratedBaby(
        id: json['id'],
        imageUrl: json['imageUrl'],
        motherImageUrl: json['motherImageUrl'],
        fatherImageUrl: json['fatherImageUrl'],
        createdAt: DateTime.parse(json['createdAt']),
        usedFreeCredit: json['usedFreeCredit'] ?? false,
      );
}

// Providers
final generatedBabiesProvider =
    StateNotifierProvider<GeneratedBabiesNotifier, List<GeneratedBaby>>((ref) {
  return GeneratedBabiesNotifier();
});

class GeneratedBabiesNotifier extends StateNotifier<List<GeneratedBaby>> {
  // Add this method to reset credits
  Future<void> resetCredits() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('used_credits', 0);
  }

  // Call this in constructor
  GeneratedBabiesNotifier() : super([]) {
    loadSavedBabies();
    resetCredits(); // Add this line to reset credits when app starts
  }

  Future<void> loadSavedBabies() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedBabies = prefs.getStringList('generated_babies') ?? [];

      // Parse saved babies and handle potential errors
      final loadedBabies = savedBabies
          .map((babyJson) {
            try {
              return GeneratedBaby.fromJson(jsonDecode(babyJson));
            } catch (e) {
              print('Error parsing baby: $e');
              return null;
            }
          })
          .whereType<GeneratedBaby>()
          .toList();

      // Sort by creation date
      loadedBabies.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      // Update state
      state = loadedBabies;
    } catch (e) {
      print('Error loading saved babies: $e');
      state = [];
    }
  }

  Future<bool> hasUsedFreeCredit() async {
    final prefs = await SharedPreferences.getInstance();
    final usedCredits = prefs.getInt('used_credits') ?? 0;
    return usedCredits >= 100;
  }

  Future<void> markFreeCreditAsUsed() async {
    final prefs = await SharedPreferences.getInstance();
    final currentCredits = prefs.getInt('used_credits') ?? 0;
    await prefs.setInt('used_credits', currentCredits + 1);
  }

  Future<void> addBaby(
      String imageUrl, String motherImageUrl, String fatherImageUrl) async {
    try {
      // Download and save the image locally
      final response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode != 200)
        throw Exception('Failed to download image'); // 200 değerini ekledik

      // Get local storage directory
      final appDir = await getApplicationDocumentsDirectory();
      final fileName = 'baby_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final localPath = '${appDir.path}/$fileName';

      // Save image to local storage
      await File(localPath).writeAsBytes(response.bodyBytes);

      final newBaby = GeneratedBaby(
        id: const Uuid().v4(),
        imageUrl: localPath, // Store local path instead of URL
        motherImageUrl: motherImageUrl,
        fatherImageUrl: fatherImageUrl,
        createdAt: DateTime.now(),
        usedFreeCredit: !appData.entitlementIsActive,
      );

      if (!appData.entitlementIsActive) {
        await markFreeCreditAsUsed();
      }

      state = [...state, newBaby];
      await _saveBabies();
      await markCreditUsed();
    } catch (e) {
      print('Error saving baby image: $e');
      rethrow;
    }
  }

  Future<void> deleteBaby(String id) async {
    final babyToDelete = state.firstWhere((baby) => baby.id == id);

    // Dosyayı fiziksel olarak sil
    try {
      final file = File(babyToDelete.imageUrl);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      print('Error deleting file: $e');
    }

    // State'den kaldır
    state = state.where((baby) => baby.id != id).toList();
    await _saveBabies();
  }

  Future<void> _saveBabies() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final babiesJson =
          state.map((baby) => jsonEncode(baby.toJson())).toList();
      await prefs.setStringList('generated_babies', babiesJson);
    } catch (e) {
      print('Error saving babies: $e');
    }
  }

  Future<bool> canGenerateBaby() async {
    if (appData.entitlementIsActive) return true;

    final prefs = await SharedPreferences.getInstance();
    final usedCredits = prefs.getInt('baby_prediction_credits') ?? 0;
    return usedCredits < 1;
  }

  Future<void> markCreditUsed() async {
    if (!appData.entitlementIsActive) {
      final prefs = await SharedPreferences.getInstance();
      final currentCredits = prefs.getInt('baby_prediction_credits') ?? 0;
      await prefs.setInt('baby_prediction_credits', currentCredits + 1);
    }
  }
}

// Service
class BabyPredictionService {
  final String openAIKey;
  static const String baseUrl = 'https://api.openai.com/v1';

  BabyPredictionService(this.openAIKey);

  Future<String?> analyzeImages(
      String motherImagePath, String fatherImagePath) async {
    try {
      // Önce analiz isteği
      final analysisResponse = await http.post(
        Uri.parse('$baseUrl/chat/completions'),
        headers: {
          'Authorization': 'Bearer $openAIKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': 'gpt-4o-mini', // Model adını düzelttik
          'messages': [
            {
              'role': 'user',
              'content': [
                {
                  'type': 'text',
                  'text':
                      'Analyze these two people and describe how their child might look at age 4-5 years old.'
                },
                {
                  'type': 'image_url',
                  'image_url': {
                    'url':
                        'data:image/jpeg;base64,${base64Encode(File(motherImagePath).readAsBytesSync())}'
                  }
                },
                {
                  'type': 'image_url',
                  'image_url': {
                    'url':
                        'data:image/jpeg;base64,${base64Encode(File(fatherImagePath).readAsBytesSync())}'
                  }
                }
              ]
            }
          ],
          'max_tokens': 500
        }),
      );

      if (analysisResponse.statusCode != 200) {
        print('Analysis API Error: ${analysisResponse.body}');
        throw Exception('Failed to analyze images');
      }

      final analysisJson = jsonDecode(analysisResponse.body);
      if (analysisJson['choices'] == null || analysisJson['choices'].isEmpty) {
        throw Exception('Invalid analysis response');
      }

      final description = analysisJson['choices'][0]['message']['content'];

      // DALL-E isteği
      final dalleResponse = await http.post(
        Uri.parse('$baseUrl/images/generations'),
        headers: {
          'Authorization': 'Bearer $openAIKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': 'dall-e-3',
          'prompt':
              '''Create a natural, casual photo of a 4-5 year old child with these features: $description

STRICT REQUIREMENTS:
1. Output Format:
   - ONE single image only
   - NO variations or multiple versions
   - NO collages or split images
   - NO side-by-side comparisons

2. Photo Style:
   - Simple head and shoulders portrait
   - Front-facing view only
   - Clear, unobstructed face
   - Natural daylight
   - Plain or simple background
   - No props or accessories

3. Child Appearance:
   - One consistent look
   - Natural expression (slight smile)
   - Regular children's clothing (solid colors preferred)
   - Age must be exactly 4-5 years old

Important: Focus on creating a realistic child photo based on the description. DO NOT create multiple versions or variations of the child in the same image. Generate only one clear portrait photo''',
          'n': 1,
          'size': '1024x1024',
          'quality': 'standard',
          'style': 'natural'
        }),
      );

      if (dalleResponse.statusCode != 200) {
        print('DALL-E API Error: ${dalleResponse.body}');
        throw Exception('Failed to generate image');
      }

      final dalleJson = jsonDecode(dalleResponse.body);
      if (dalleJson['data'] == null || dalleJson['data'].isEmpty) {
        throw Exception('Invalid DALL-E response');
      }

      return dalleJson['data'][0]['url'];
    } catch (e) {
      print('Service Error: $e');
      return null;
    }
  }
}

// Screens
class BabyPredictionScreen extends ConsumerStatefulWidget {
  @override
  _BabyPredictionScreenState createState() => _BabyPredictionScreenState();
}

class _BabyPredictionScreenState extends ConsumerState<BabyPredictionScreen> {
  final ImagePicker _picker = ImagePicker();
  File? motherImage;
  File? fatherImage;
  bool isGenerating = false;

  final BabyPredictionService predictionService = BabyPredictionService(
    ApiConstants.OPENAI_API_KEY,
  );

  @override
  void initState() {
    super.initState();
    // Sayfa yüklendiğinde 1 saniyelik gecikme ile kontrol et
    Future.delayed(const Duration(seconds: 1), () {
      _checkAndShowFeedbackDialog();
    });
  }

  Future<void> _checkAndShowFeedbackDialog() async {
    final prefs = await SharedPreferences.getInstance();
    final hasShownFeedback = prefs.getBool('has_shown_feedback') ?? false;
    final lastFeedbackDate = DateTime.parse(
        prefs.getString('last_feedback_date') ?? DateTime.now().toString());
    final daysSinceLastFeedback =
        DateTime.now().difference(lastFeedbackDate).inDays;

    // Kullanıcı daha önce feedback vermemişse veya son feedbackten 7 gün geçtiyse
    if (!hasShownFeedback || daysSinceLastFeedback >= 7) {
      if (mounted) {
        // En az 1 görsel oluşturmuş mu kontrol et
        final generatedBabies = ref.read(generatedBabiesProvider);
        if (generatedBabies.isNotEmpty) {
          await _showFeedbackDialog();
          // Feedback gösterildi olarak işaretle
          await prefs.setBool('has_shown_feedback', true);
          // Son feedback tarihini kaydet
          await prefs.setString(
              'last_feedback_date', DateTime.now().toString());
        }
      }
    }
  }

  Future<void> _showFeedbackDialog() async {
    if (!mounted) return;

    int selectedRating = 0;
    final size = MediaQuery.of(context).size;
    final buttonWidth = (size.width * 0.9 > 400 ? 400 : size.width * 0.9) *
        0.35; // Her buton genişliğin %35'i kadar

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
                    'How\'s Your Experience?',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Love seeing your future baby? Your rating helps others discover our app!',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
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

                              // 4 veya 5 yıldız seçildiğinde hemen yönlendir
                              if (selectedRating >= 4) {
                                LaunchReview.launch(
                                  androidAppId: "your.android.app.id",
                                  iOSAppId: "6740035205",
                                );
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
                      SizedBox(
                        width: buttonWidth,
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text(
                            'Maybe Later',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      SizedBox(
                        width: buttonWidth,
                        child: FilledButton(
                          onPressed: selectedRating > 0 && selectedRating < 4
                              ? () {
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

  Future<bool> validateImage(File imageFile, String parentType) async {
    try {
      final response = await http.post(
        Uri.parse('${BabyPredictionService.baseUrl}/chat/completions'),
        headers: {
          'Authorization': 'Bearer ${predictionService.openAIKey}',
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
                  'text':
                      '''Analyze this image and determine if it shows ONLY a clear, front-facing photo of a human adult face.
                  
Requirements:
- Must be a human (not an animal, object, or artwork)
- Must be an adult (not a child)
- Must show a clear face (not blurry, not a body shot)
- Must be a single person (not multiple people)
- Must be front-facing (not profile or back view)

Respond with ONLY "yes" if ALL requirements are met, otherwise respond with "no".'''
                },
                {
                  'type': 'image_url',
                  'image_url': {
                    'url':
                        'data:image/jpeg;base64,${base64Encode(imageFile.readAsBytesSync())}'
                  }
                }
              ]
            }
          ],
          'max_tokens': 10
        }),
      );

      final result = jsonDecode(response.body);
      final answer =
          result['choices'][0]['message']['content'].toLowerCase().trim();

      if (answer != 'yes') {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Please select a clear, front-facing photo of an adult ${parentType.toLowerCase()}',
                style: const TextStyle(fontFamily: 'Poppins'),
              ),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
        return false;
      }
      return true;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Error validating image. Please try again.',
              style: TextStyle(fontFamily: 'Poppins'),
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
      return false;
    }
  }

  Future<void> pickImage(bool isMother) async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (image != null) {
      setState(() {
        if (isMother) {
          motherImage = File(image.path);
        } else {
          fatherImage = File(image.path);
        }
      });
    }
  }

  Future<void> generateBabyImage() async {
    if (motherImage == null || fatherImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select both parent photos')),
      );
      return;
    }

    // Premium veya kredi kontrolü
    if (!appData.entitlementIsActive) {
      final canGenerate =
          await ref.read(generatedBabiesProvider.notifier).canGenerateBaby();
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
      final imageUrl = await predictionService.analyzeImages(
        motherImage!.path,
        fatherImage!.path,
      );

      if (imageUrl != null) {
        await ref.read(generatedBabiesProvider.notifier).addBaby(
              imageUrl,
              motherImage!.path,
              fatherImage!.path,
            );
        setState(() {
          motherImage = null;
          fatherImage = null;
        });

        // Bebek oluşturma başarılı olduktan sonra 2 saniye bekleyip yorum diyaloğunu göster
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            _showFeedbackDialog();
          }
        });
      } else {
        throw Exception('Failed to generate baby image');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to generate baby image. Please try again.'),
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

  @override
  Widget build(BuildContext context) {
    final generatedBabies = ref.watch(generatedBabiesProvider);
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Baby Predictor',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              margin: EdgeInsets.symmetric(
                horizontal: isTablet ? screenSize.width * 0.1 : 16,
                vertical: 8,
              ),
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
                          ? 'Premium member - Unlimited predictions'
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
          ),
          SliverToBoxAdapter(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.textPrimary.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              margin: EdgeInsets.symmetric(
                horizontal: isTablet ? screenSize.width * 0.1 : 16,
                vertical: 16,
              ),
              padding: EdgeInsets.all(isTablet ? 32 : 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Upload Parent Photos',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Select clear, front-facing photos of both parents',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: ImagePickerWidget(
                          title: "Mother",
                          image: motherImage,
                          onTap: () => pickImage(true),
                          height: isTablet ? 300 : 180,
                        ),
                      ),
                      SizedBox(width: isTablet ? 32 : 16),
                      Expanded(
                        child: ImagePickerWidget(
                          title: "Father",
                          image: fatherImage,
                          onTap: () => pickImage(false),
                          height: isTablet ? 300 : 180,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: isGenerating ? null : generateBabyImage,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    icon: isGenerating
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Icon(Icons.child_care, size: 28),
                    label: Text(
                      isGenerating ? 'Generating Baby...' : 'Generate Baby',
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (generatedBabies.isNotEmpty) ...[
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                isTablet ? screenSize.width * 0.1 : 16,
                0,
                isTablet ? screenSize.width * 0.1 : 16,
                16,
              ),
              sliver: SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: isTablet ? 2 : 1,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: isTablet ? 1 : 0.85,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final baby = generatedBabies[index];
                    return GeneratedBabyCard(
                      baby: baby,
                      onDelete: () => ref
                          .read(generatedBabiesProvider.notifier)
                          .deleteBaby(baby.id),
                      onSave: () => _saveBabyImage(context, baby),
                    );
                  },
                  childCount: generatedBabies.length,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _saveBabyImage(BuildContext context, GeneratedBaby baby) async {
    try {
      // Dosya zaten local storage'da olduğu için direkt olarak galeriye kaydedebiliriz
      final result = await ImageGallerySaver.saveFile(
        baby.imageUrl,
        name: 'baby_${baby.id}.jpg',
      );

      if (result['isSuccess'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Image saved to gallery'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        throw Exception('Gallery save failed');
      }
    } catch (e) {
      print('Error saving image: $e'); // Hata detayını görmek için
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error saving image'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

class ImagePickerWidget extends StatelessWidget {
  final String title;
  final File? image;
  final VoidCallback onTap;
  final double height;

  const ImagePickerWidget({
    required this.title,
    required this.image,
    required this.onTap,
    this.height = 180,
  });

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF64B5F6);

    return Column(
      children: [
        Text(
          title,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: height > 180 ? 20 : 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            height: height,
            decoration: BoxDecoration(
              color: image != null
                  ? Colors.transparent
                  : primaryColor.withOpacity(0.05),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: image != null
                    ? Colors.transparent
                    : primaryColor.withOpacity(0.2),
                width: 2,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: image != null
                  ? Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.file(
                          image!,
                          fit: BoxFit.cover,
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.9),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 4,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.edit_outlined,
                              color: primaryColor,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: primaryColor.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.add_photo_alternate_rounded,
                            size: 32,
                            color: primaryColor,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Tap to select',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            color: primaryColor,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ],
    );
  }
}

class GeneratedBabyCard extends StatelessWidget {
  final GeneratedBaby baby;
  final VoidCallback onDelete;
  final VoidCallback onSave;

  const GeneratedBabyCard({
    required this.baby,
    required this.onDelete,
    required this.onSave,
  });

  Widget _buildImage(String imagePath) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(40),
      child: Builder(
        builder: (context) {
          try {
            if (imagePath.startsWith('http')) {
              return Image.network(
                imagePath,
                width: 80,
                height: 80,
                fit: BoxFit.cover,
              );
            } else {
              final file = File(imagePath);
              if (file.existsSync()) {
                return Image.file(
                  file,
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                );
              }
            }
          } catch (e) {
            print('Error loading image $imagePath: $e');
          }

          // Fallback for errors or missing files
          return Container(
            width: 80,
            height: 80,
            color: Colors.grey[200],
            child: Icon(Icons.person, color: Colors.grey[400]),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                  child: Builder(
                    builder: (context) {
                      return Image.file(
                        File(baby.imageUrl),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          print('Error loading image: $error');
                          return Center(
                            child: Icon(
                              Icons.broken_image,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
                Positioned(
                  top: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 14,
                          color: Colors.grey[800],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatDate(baby.createdAt),
                          style: TextStyle(
                            color: Colors.grey[800],
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(24),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildActionButton(
                  icon: Icons.save_alt,
                  label: 'Save',
                  onTap: onSave,
                  color: Colors.green,
                ),
                _buildActionButton(
                  icon: Icons.delete,
                  label: 'Delete',
                  onTap: () => _showDeleteDialog(context),
                  color: Colors.red,
                ),
                _buildActionButton(
                  icon: Icons.share,
                  label: 'Share',
                  onTap: () => _shareImage(context),
                  color: Colors.blue,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color color,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: color,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showDeleteDialog(BuildContext context) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Delete Image',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
          ),
        ),
        content: const Text(
          'Are you sure you want to delete this image?',
          style: TextStyle(
            fontFamily: 'Poppins',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              onDelete();
              Navigator.pop(context);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _shareImage(BuildContext context) async {
    try {
      // Share özelliği şu an desteklenmiyor
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sharing will be available in a future update'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('An error occurred'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
