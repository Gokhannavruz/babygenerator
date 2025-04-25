import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:babyprediction/models/app_colors.dart';
import 'package:babyprediction/models/onboarding_model.dart';
import 'package:babyprediction/screens/baby_prediction.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:launch_review/launch_review.dart';
import 'package:in_app_review/in_app_review.dart';
import 'dart:io';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final int _totalPages = 3;
  int _selectedRating = 0;

  final InAppReview inAppReview = InAppReview.instance;

  // Modern yumuşak renkler
  final List<Color> _modernColors = [
    Color(0xFF8AAAE5), // Soft blue
    Color(0xFFFFB7C3), // Soft coral
    Color(0xFF9C89B8), // Soft purple
  ];

  // Onboarding sayfalarının veri modelleri
  final List<OnboardingModel> _pages = [
    OnboardingModel(
      title: 'Magic Baby Prediction',
      description:
          'Upload mom and dad\'s photos and watch our AI create adorable predictions of what your future baby might look like!',
      animationPath: 'assets/animations/ai_face_scan.json',
      backgroundColor: Color(0xFF8AAAE5), // Soft blue
      features: [
        OnboardingFeature(
          icon: Icons.child_friendly,
          title: 'Adorable Baby Faces',
          description: 'See cute little faces based on mom & dad\'s features',
        ),
        OnboardingFeature(
          icon: Icons.auto_awesome,
          title: 'Magical AI Technology',
          description: 'Creates sweet baby photos with realistic details',
        ),
      ],
    ),
    OnboardingModel(
      title: 'Perfect Baby Names',
      description:
          'Upload your baby\'s photo and our magic AI will suggest cute names that match your little one\'s beautiful appearance!',
      animationPath: 'assets/animations/ai_face_scan.json',
      backgroundColor: Color(0xFFFFB7C3), // Soft coral
      features: [
        OnboardingFeature(
          icon: Icons.favorite,
          title: 'Precious Name Ideas',
          description: 'Names that perfectly match your baby\'s cute look',
        ),
        OnboardingFeature(
          icon: Icons.emoji_emotions,
          title: 'Personality Matching',
          description: 'Names that reflect your baby\'s special character',
        ),
      ],
    ),
    OnboardingModel(
      title: 'Start Your Journey',
      description:
          'Ready to see your adorable little one? Explore our magical baby prediction features and create wonderful moments!',
      animationPath: 'assets/animations/ai_face_scan.json',
      backgroundColor: Color(0xFF9C89B8), // Soft purple
      features: null,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _completeOnboarding() async {
    // Onboarding'i tamamlandı olarak işaretle
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isFirstLaunch', false);

    // Ana ekrana geç
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => BabyPredictionScreen()),
    );
  }

  void _showRatingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(builder: (context, setState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.emoji_emotions, color: Color(0xFF3F88F5)),
                SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'Enjoying\nBaby Prediction?',
                    style: TextStyle(
                      color: Color(0xFF5E5873),
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'We\'d love to hear what you think! Your reviews motivate us and help others discover this app.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF5E5873),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedRating = index + 1;
                          // Eğer 5 yıldız seçildiyse otomatik olarak Submit et
                          if (_selectedRating == 5) {
                            Navigator.of(context).pop();
                            _handleRating(5);
                          }
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                        child: Icon(
                          _selectedRating > index
                              ? Icons.star
                              : Icons.star_border,
                          color: Colors.amber,
                          size: 40,
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 16),
                Text(
                  _selectedRating > 0 ? _getRatingText(_selectedRating) : '',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontStyle: FontStyle.italic,
                    fontSize: 14,
                    color: Color(0xFF7B7D8C),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.white,
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _setRatingPreferences(askLater: true);
                  _completeOnboarding();
                },
                style: TextButton.styleFrom(
                  foregroundColor: Color(0xFF7B7D8C),
                ),
                child: const Text('Ask Me Later'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  if (_selectedRating > 0) {
                    _handleRating(_selectedRating);
                  } else {
                    // User didn't select any rating
                    _setRatingPreferences(askLater: true);
                    _completeOnboarding();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF3F88F5), // Canlı mavi
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  elevation: 3, // Biraz daha belirgin gölge
                ),
                child: const Text(
                  'Submit',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          );
        });
      },
    );
  }

  // Handle the user's rating based on its value
  void _handleRating(int rating) async {
    if (rating >= 4) {
      // For high ratings, use the SKStoreReviewController API to show the native review dialog
      _setRatingPreferences(rated: true);

      try {
        if (await inAppReview.isAvailable()) {
          // Show the in-app review dialog using Apple's SKStoreReviewController
          await inAppReview.requestReview();
        } else {
          // Fallback to manual app store launch if in-app review is not available
          await LaunchReview.launch(
            androidAppId: "com.yourcompany.babyprediction",
            iOSAppId: "6740035205", // What My Baby Look Like - AI ID
            writeReview: true, // Ask for a written review, not just a rating
          );
        }
      } catch (e) {
        // Fallback to manual app store launch in case of errors
        await LaunchReview.launch(
          androidAppId: "com.yourcompany.babyprediction",
          iOSAppId: "6740035205", // What My Baby Look Like - AI ID
          writeReview: true,
        );
      }

      _completeOnboarding();
    } else {
      // For lower ratings, show feedback collection dialog
      _showFeedbackDialog(rating);
    }
  }

  void _showFeedbackDialog(int rating) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final feedbackController = TextEditingController();

        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          backgroundColor: Colors.white,
          title: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.feedback,
                color: Color(0xFF3F88F5),
              ),
              SizedBox(width: 8),
              Flexible(
                child: Text(
                  'Your Feedback Matters',
                  style: TextStyle(
                    color: Color(0xFF5E5873),
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'How can we make the app better for you?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF5E5873),
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: feedbackController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Your suggestions...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _setRatingPreferences(providedFeedback: true);
                _completeOnboarding();
              },
              style: TextButton.styleFrom(
                foregroundColor: Color(0xFF7B7D8C),
              ),
              child: const Text('Skip'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Here you would normally send the feedback to your server
                // or analytics platform
                _setRatingPreferences(providedFeedback: true);
                _completeOnboarding();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF3F88F5),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                elevation: 3,
              ),
              child: Text(
                'Send Feedback',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _setRatingPreferences({
    bool askLater = false,
    bool rated = false,
    bool providedFeedback = false,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    if (askLater) {
      // Set a timestamp when to ask again (e.g., after 3 days)
      final nextPromptTime =
          DateTime.now().add(Duration(days: 3)).millisecondsSinceEpoch;
      await prefs.setInt('nextRatingPromptTime', nextPromptTime);
      await prefs.setBool('shouldShowRatingPrompt', true);
    }

    if (rated) {
      // User has rated the app, don't ask again
      await prefs.setBool('hasRatedApp', true);
    }

    if (providedFeedback) {
      // User has given feedback, we can still ask for rating later
      final nextPromptTime =
          DateTime.now().add(Duration(days: 7)).millisecondsSinceEpoch;
      await prefs.setInt('nextRatingPromptTime', nextPromptTime);
      await prefs.setBool('hasProvidedFeedback', true);
    }
  }

  void _maybeRateLater() async {
    _setRatingPreferences(askLater: true);
    _completeOnboarding();
  }

  Future<void> _requestReview() async {
    try {
      if (await inAppReview.isAvailable()) {
        await inAppReview.requestReview();
      } else {
        // In-app review kullanılamıyorsa App Store'a yönlendir
        await LaunchReview.launch(
          androidAppId: "com.yourcompany.babyprediction",
          iOSAppId: "6740035205", // What My Baby Look Like - AI ID
          writeReview: true,
        );
      }
    } catch (e) {
      // Hata durumunda App Store'a yönlendir
      await LaunchReview.launch(
        androidAppId: "com.yourcompany.babyprediction",
        iOSAppId: "6740035205", // What My Baby Look Like - AI ID
        writeReview: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Gradient arkaplan (resim yok)
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  _pages[_currentPage].backgroundColor,
                  _pages[_currentPage].backgroundColor.withOpacity(0.7),
                ],
              ),
            ),
          ),

          // Onboarding sayfaları
          PageView.builder(
            controller: _pageController,
            itemCount: _pages.length,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemBuilder: (context, index) {
              final page = _pages[index];
              return _buildPage(page, index);
            },
          ),

          // Sayfa göstergesi
          Positioned(
            bottom: 100,
            left: 0,
            right: 0,
            child: Center(
              child: SmoothPageIndicator(
                controller: _pageController,
                count: _totalPages,
                effect: ExpandingDotsEffect(
                  activeDotColor: Colors.white,
                  dotColor: Colors.white.withOpacity(0.4),
                  dotHeight: 8,
                  dotWidth: 8,
                  expansionFactor: 4,
                ),
              ),
            ),
          ),

          // Butonlar
          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Geri butonu (ilk sayfada gösterme)
                _currentPage > 0
                    ? TextButton.icon(
                        onPressed: () {
                          _pageController.previousPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        },
                        icon: Icon(
                          Icons.arrow_back_rounded,
                          color: Colors.white,
                        ),
                        label: const Text(
                          'Back',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                      )
                    : const SizedBox(width: 100),

                // Son sayfada belki daha sonra butonu ekle
                if (_currentPage == _totalPages - 1)
                  TextButton(
                    onPressed: _maybeRateLater,
                    child: const Text(
                      'Skip',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ),

                // İleri / Başla butonu
                ElevatedButton.icon(
                  onPressed: () async {
                    if (_currentPage < _totalPages - 1) {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    } else {
                      // Son sayfada önce Apple'ın inceleme diyaloğunu göster
                      _setRatingPreferences(rated: true);

                      try {
                        if (await inAppReview.isAvailable()) {
                          // Önce Apple'ın native review diyaloğunu göster
                          await inAppReview.requestReview();

                          // Kullanıcının diyalog ile etkileşimde bulunması için 3 saniye bekle
                          await Future.delayed(Duration(seconds: 3));
                        } else {
                          // API kullanılamıyorsa App Store'a yönlendir
                          await LaunchReview.launch(
                            androidAppId: "com.yourcompany.babyprediction",
                            iOSAppId: "6740035205",
                            writeReview: true,
                          );
                          // App Store yönlendirmesinden sonra bekle
                          await Future.delayed(Duration(seconds: 3));
                        }
                      } catch (e) {
                        print("Review dialog error: $e");
                        // Hata durumunda kısa bir süre bekle
                        await Future.delayed(Duration(seconds: 1));
                      } finally {
                        // Bekleme süresi tamamlandıktan sonra ana sayfaya yönlendir
                        _completeOnboarding();
                      }
                    }
                  },
                  icon: _currentPage < _totalPages - 1
                      ? Icon(Icons.arrow_forward_rounded)
                      : Icon(Icons.favorite),
                  label: Text(
                    _currentPage < _totalPages - 1 ? 'Next' : 'Start',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Color(0xFF5E5873),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPage(OnboardingModel page, int index) {
    // Her sayfa için farklı bir görsel belirle
    String imagePath;
    if (index == 0) {
      imagePath = 'assets/images/ai4.png';
    } else if (index == 1) {
      imagePath = 'assets/images/ai3.png';
    } else {
      imagePath = 'assets/images/ai2.png';
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Animasyon
            Expanded(
              flex: 5,
              child: Center(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 20,
                        spreadRadius: 0,
                        offset: Offset(0, 5),
                      ),
                    ],
                  ),
                  margin: EdgeInsets.all(10),
                  padding: EdgeInsets.all(20),
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Image.asset(
                      imagePath,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
            ),

            // Başlık
            Container(
              width: double.infinity,
              padding: EdgeInsets.only(top: 16, bottom: 8),
              child: Text(
                page.title,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            // Açıklama
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              child: Text(
                page.description,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white.withOpacity(0.9),
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 20),

            // Özellikler
            Expanded(
              flex: 4,
              child: _buildFeaturesList(page.features, index),
            ),

            // Alt boşluk (butonlar için)
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturesList(List<OnboardingFeature>? features, int pageIndex) {
    if (features == null) {
      // 3. sayfa için özel içerik
      return Center(
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 20,
                spreadRadius: 0,
                offset: Offset(0, 5),
              ),
            ],
          ),
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.baby_changing_station,
                size: 60,
                color: _pages[pageIndex].backgroundColor,
              ),
              SizedBox(height: 16),
              Text(
                "Let's create some baby magic!",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF5E5873),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      itemCount: features.length,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      itemBuilder: (context, index) {
        final feature = features[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 20.0),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  spreadRadius: 0,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            padding: EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _pages[pageIndex].backgroundColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    feature.icon,
                    color: _pages[pageIndex].backgroundColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        feature.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF5E5873),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        feature.description,
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF7B7D8C),
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _getRatingText(int rating) {
    switch (rating) {
      case 1:
        return 'We\'re sorry to hear that. We value your feedback to improve!';
      case 2:
        return 'Thanks for your honest feedback. We\'ll work to make it better!';
      case 3:
        return 'Thank you! We\'re constantly working to improve our app.';
      case 4:
        return 'Great! We\'re glad you\'re enjoying our app!';
      case 5:
        return 'Wonderful! Your review helps other parents discover our app ❤️';
      default:
        return '';
    }
  }

  void _showAppleReviewDialog() async {
    try {
      if (await inAppReview.isAvailable()) {
        // Apple'ın native review diyaloğunu göster
        await inAppReview.requestReview();
      } else {
        // Test ortamında veya in-app review kullanılamıyorsa
        print("In-app review is not available");
      }
    } catch (e) {
      print("Review dialog error: $e");
    }
  }

  void _showThankYouDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          backgroundColor: Colors.white,
          title: Icon(
            Icons.check_circle,
            color: Color(0xFF3F88F5),
            size: 50,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Thank You!',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF5E5873),
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 10),
              Text(
                'Your feedback helps us improve the app for everyone.',
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF7B7D8C),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            Center(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _completeOnboarding();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF3F88F5),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                  elevation: 2,
                ),
                child: Text(
                  'Continue to App',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
