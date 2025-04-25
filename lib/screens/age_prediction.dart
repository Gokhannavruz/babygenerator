import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:babyprediction/models/age_prediction.dart';
import 'package:babyprediction/models/age_prediction_provider.dart';
import 'package:babyprediction/widgets/generated_age_card.dart';

import '../services/age_prediction_service.dart';
import '../constants/api_constants.dart';
import 'package:babyprediction/screens/baby_prediction.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:gallery_saver/gallery_saver.dart';
import 'package:babyprediction/models/app_colors.dart';

class AgePredictionScreen extends ConsumerStatefulWidget {
  @override
  _AgePredictionScreenState createState() => _AgePredictionScreenState();
}

class _AgePredictionScreenState extends ConsumerState<AgePredictionScreen> {
  final ImagePicker _picker = ImagePicker();
  File? selectedImage;
  bool isGenerating = false;
  int targetAge = 60; // Varsayılan hedef yaş

  final AgePredictionService predictionService = AgePredictionService(
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

  Future<void> generateAgedImage() async {
    if (selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a photo')),
      );
      return;
    }

    setState(() => isGenerating = true);

    try {
      final imageUrl = await predictionService.generateAgedImage(
        selectedImage!.path,
        targetAge,
      );

      await ref.read(generatedAgesProvider.notifier).addAgedImage(
            imageUrl,
            selectedImage!.path,
            targetAge,
          );
    } catch (e) {
      print('Error in generateAgedImage: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
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

  Future<void> _saveAgedImage(BuildContext context, GeneratedAge age) async {
    try {
      final response = await http.get(Uri.parse(age.imageUrl));
      final bytes = response.bodyBytes;
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/aged_image.jpg');
      await file.writeAsBytes(bytes);

      final result = await GallerySaver.saveImage(file.path);

      if (result == true && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Image saved to gallery'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to save image'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final generatedAges = ref.watch(generatedAgesProvider)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Age Predictor',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
            color: Color(0xFF2D3142),
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Photo Selection Area
                  GestureDetector(
                    onTap: pickImage,
                    child: Container(
                      height: 280,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Color(0xFFE1E3E8),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.textPrimary.withOpacity(0.05),
                            blurRadius: 10,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: selectedImage != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(18),
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  Image.file(
                                    selectedImage!,
                                    fit: BoxFit.cover,
                                  ),
                                  Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.bottomCenter,
                                        end: Alignment.topCenter,
                                        colors: [
                                          Colors.black54,
                                          Colors.transparent,
                                        ],
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    bottom: 16,
                                    left: 16,
                                    child: Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.edit,
                                            size: 16,
                                            color: Color(0xFF6C63FF),
                                          ),
                                          SizedBox(width: 4),
                                          Text(
                                            'Change Photo',
                                            style: TextStyle(
                                              color: Color(0xFF6C63FF),
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.add_photo_alternate_rounded,
                                  size: 48,
                                  color: Color(0xFF6C63FF),
                                ),
                                SizedBox(height: 12),
                                Text(
                                  'Select a Photo',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF2D3142),
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Tap to choose from your gallery',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),

                  SizedBox(height: 24),

                  // Age Selection
                  Container(
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Target Age',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF2D3142),
                              ),
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Color(0xFF6C63FF),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '$targetAge years',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 16),
                        SliderTheme(
                          data: SliderThemeData(
                            activeTrackColor: AppColors.primary,
                            inactiveTrackColor:
                                AppColors.primary.withOpacity(0.2),
                            thumbColor: AppColors.primary,
                            overlayColor: AppColors.primary.withOpacity(0.1),
                            trackHeight: 4,
                          ),
                          child: Slider(
                            value: targetAge.toDouble(),
                            min: 1,
                            max: 100,
                            divisions: 99,
                            onChanged: (value) {
                              setState(() {
                                targetAge = value.round();
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 24),

                  // Generate Button
                  FilledButton.icon(
                    onPressed: isGenerating ? null : generateAgedImage,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      minimumSize: Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    icon: isGenerating
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Icon(Icons.auto_fix_high_rounded),
                    label: Text(
                      isGenerating ? 'Generating...' : 'Generate Future You',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Generated Images Section
          if (generatedAges.isNotEmpty) ...[
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 32, 20, 12),
              sliver: SliverToBoxAdapter(
                child: Text(
                  'Previous Results',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2D3142),
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 1,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.85,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final age = generatedAges[index];
                    return GeneratedAgeCard(
                      age: age,
                      onDelete: () => ref
                          .read(generatedAgesProvider.notifier)
                          .deleteAgedImage(age.id),
                      onSave: () => _saveAgedImage(context, age),
                    );
                  },
                  childCount: generatedAges.length,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
