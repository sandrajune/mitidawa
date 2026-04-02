import 'dart:io';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image/image.dart' as img;

import '../models/plant.dart';
import '../services/plant_service.dart';
import '../services/scan_history_service.dart';
import 'prediction_result_screen.dart';

// --- Premium Botanical Palette ---
class ScanPalette {
  static const Color background = Color(0xFFF3F7F4); // Pale sage
  static const Color textPrimary = Color(0xFF162D20); // Deep forest
  static const Color textSecondary = Color(0xFF5A7062);
  static const Color brandGreen = Color(0xFF1B4332);
  static const Color accentGreen = Color(0xFF2D6A4F);
  static const Color surfaceWhite = Color(0xFFFFFFFF);
  static const Color warningRed = Color(0xFFB71C1C);
  static const Color warningBg = Color(0xFFFFEBEE);
}

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> with SingleTickerProviderStateMixin {
  File? _image;
  Interpreter? _interpreter;
  List<String> _labels = [];
  String _prediction = "No prediction yet";
  String? _predictionMessage;
  double _confidence = 0.0;
  String? _errorMessage;
  bool _isModelLoading = false;
  final PlantService _plantService = PlantService();
  final ScanHistoryService _scanHistoryService = ScanHistoryService();
  List<Plant> _catalogPlants = [];
  Plant? _matchedPlant;

  // Animation for the viewfinder pulse
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    
    _loadModel();
    _loadCatalogPlants();
    // Request permissions after first frame is rendered
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _requestPermissions();
    });
  }

  Color _confidenceColor(double confidence) {
    if (confidence >= 0.75) return ScanPalette.brandGreen;
    if (confidence >= 0.35) return const Color(0xFF8B7355); // Earthy clay
    return ScanPalette.warningRed;
  }

  String _confidenceLabel(double confidence) {
    if (confidence >= 0.75) return 'High Match';
    if (confidence >= 0.35) return 'Partial Match';
    return 'Low Match';
  }

  // --- Core Logic (Unchanged) ---

  Future<void> _requestPermissions() async {
    // image_picker handles iOS permissions natively
  }

  Future<void> _loadCatalogPlants() async {
    final plants = await _plantService.fetchPlants();
    if (!mounted) return;
    setState(() => _catalogPlants = plants);
  }

  Plant? _findPlantByLabel(String label) {
    final normalizedLabel = label.trim().toLowerCase();
    for (final plant in _catalogPlants) {
      if (plant.name.trim().toLowerCase() == normalizedLabel) return plant;
      if (plant.scientificName.trim().toLowerCase() == normalizedLabel) return plant;
    }
    return null;
  }

  Future<void> _loadModel() async {
    if (!mounted) return;
    setState(() {
      _isModelLoading = true;
      _errorMessage = null;
    });

    try {
      _interpreter?.close();
      _interpreter = await Interpreter.fromAsset('assets/models/plant_identifier_final.tflite');
      final labelsData = await rootBundle.loadString('assets/labels.txt');
      _labels = labelsData.split('\n').map((line) => line.trim()).where((line) => line.isNotEmpty).toList();
      if (!mounted) return;
      setState(() => _errorMessage = null);
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = 'Model failed to load.\n$e');
    } finally {
      if (mounted) setState(() => _isModelLoading = false);
    }
  }

  Future<bool> _ensureCameraPermission() async {
    return true;
  }

  Future<void> _takePhoto({bool fromGallery = false}) async {
    final hasPermission = await _ensureCameraPermission();
    if (!hasPermission) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Camera permission is required.')));
      return;
    }

    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: fromGallery ? ImageSource.gallery : ImageSource.camera,
    );

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
        _prediction = "Analyzing..."; // Show feedback while processing
      });

      final result = await predict(_image!);
      if (!mounted || result == null) return;

      final predictedPlantName = result['plant'] as String?;
      final confidenceValue = (result['confidence'] as double?) ?? 0.0;
      final matchedPlant = predictedPlantName == null ? null : _findPlantByLabel(predictedPlantName);

      setState(() {
        _prediction = predictedPlantName ?? 'No predicted plant';
        _confidence = confidenceValue;
        _predictionMessage = result['message'] as String?;
        _matchedPlant = matchedPlant;
      });

      await _scanHistoryService.addEntry(
        ScanHistoryEntry(
          plantName: matchedPlant?.name,
          confidence: confidenceValue,
          message: _predictionMessage,
          timestamp: DateTime.now(),
        ),
      );
    }
  }

  Future<Map<String, dynamic>?> predict(File imageFile) async {
    if (_interpreter == null || _labels.isEmpty) {
      if (!mounted) return null;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Model not ready yet.')));
      return null;
    }

    final inputShape = _interpreter!.getInputTensor(0).shape;
    final outputShape = _interpreter!.getOutputTensor(0).shape;
    
    final inputHeight = inputShape[1];
    final inputWidth = inputShape[2];
    final outputClasses = outputShape.last;

    final decoded = img.decodeImage(await imageFile.readAsBytes());
    if (decoded == null) return null;

    final resized = img.copyResize(decoded, width: inputWidth, height: inputHeight);

    final input = List.generate(1, (_) => List.generate(inputHeight, (y) => List.generate(inputWidth, (x) {
      final pixel = resized.getPixel(x, y);
      return [(pixel.r / 127.5) - 1.0, (pixel.g / 127.5) - 1.0, (pixel.b / 127.5) - 1.0];
    })));

    final output = List.generate(1, (_) => List<double>.filled(outputClasses, 0.0));
    _interpreter!.run(input, output);

    final probabilities = output[0];
    if (probabilities.isEmpty) return null;

    int maxIndex = 0;
    double maxProb = probabilities[0];
    for (int i = 1; i < probabilities.length; i++) {
      if (probabilities[i] > maxProb) {
        maxProb = probabilities[i];
        maxIndex = i;
      }
    }

    final safeIndex = _labels.isEmpty ? 0 : math.min(maxIndex, _labels.length - 1);
    final predictedLabel = _labels.isNotEmpty ? _labels[safeIndex] : 'Unknown';

    const double confidenceThreshold = 0.45;
const double nonPlantThreshold = 0.15;
    final inTestedSet = _labels.any((l) => l.trim().toLowerCase() == predictedLabel.trim().toLowerCase());

    if (maxProb >= confidenceThreshold && inTestedSet) {
      return {'plant': predictedLabel, 'confidence': maxProb, 'isConfident': true};
    } else if (maxProb < nonPlantThreshold) {
      return {
        'plant': null,
        'confidence': maxProb,
        'isConfident': false,
        'message': 'This does not look like one of the trained plants. Try a clearer leaf photo.',
      };
    } else {
      return {
        'plant': null,
        'confidence': maxProb,
        'isConfident': false,
        'message': 'Low confidence (${(maxProb * 100).toStringAsFixed(1)}%). Prediction hidden below 75%.',
      };
    }
  }

  // --- Premium UI Build ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ScanPalette.background,
      body: Stack(
        children: [
          // Ambient Leaf Watermark
          Positioned(
            top: -50,
            right: -80,
            child: Transform.rotate(
              angle: math.pi / 4,
              child: Icon(Icons.document_scanner_rounded, size: 300, color: ScanPalette.brandGreen.withOpacity(0.03)),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    child: Column(
                      children: [
                        _buildViewfinder(),
                        const SizedBox(height: 24),
                        if (_errorMessage != null) _buildErrorCard(),
                        if (_image != null && _prediction != "Analyzing...") _buildResultCard(),
                      ],
                    ),
                  ),
                ),
                _buildBottomControls(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Lens',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: ScanPalette.textPrimary,
              letterSpacing: -1.0,
            ),
          ),
          
          // Sleek Status Pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: _errorMessage != null ? ScanPalette.warningBg : ScanPalette.surfaceWhite,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _errorMessage != null ? ScanPalette.warningRed.withOpacity(0.3) : ScanPalette.brandGreen.withOpacity(0.1)),
            ),
            child: Row(
              children: [
                if (_isModelLoading)
                  const SizedBox(
                    width: 12, height: 12,
                    child: CircularProgressIndicator(strokeWidth: 2, color: ScanPalette.brandGreen),
                  )
                else
                  Icon(
                    _errorMessage != null ? Icons.error_outline_rounded : Icons.check_circle_rounded,
                    size: 16,
                    color: _errorMessage != null ? ScanPalette.warningRed : ScanPalette.brandGreen,
                  ),
                const SizedBox(width: 8),
                Text(
                  _isModelLoading ? 'Loading AI...' : (_errorMessage != null ? 'Model Error' : 'AI Ready'),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _errorMessage != null ? ScanPalette.warningRed : ScanPalette.brandGreen,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewfinder() {
    return Container(
      width: double.infinity,
      height: 400,
      decoration: BoxDecoration(
        color: ScanPalette.surfaceWhite,
        borderRadius: BorderRadius.circular(40),
        border: Border.all(color: ScanPalette.brandGreen.withOpacity(0.08), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: ScanPalette.brandGreen.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(40),
        child: _image == null
            ? Stack(
                alignment: Alignment.center,
                children: [
                  Icon(Icons.energy_savings_leaf_rounded, size: 150, color: ScanPalette.brandGreen.withOpacity(0.04)),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedBuilder(
                        animation: _pulseController,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: 1.0 + (_pulseController.value * 0.05),
                            child: Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: ScanPalette.accentGreen.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.camera_alt_rounded, size: 40, color: ScanPalette.brandGreen),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Center leaf in frame',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: ScanPalette.textSecondary),
                      ),
                    ],
                  ),
                ],
              )
            : Stack(
                fit: StackFit.expand,
                children: [
                  Image.file(_image!, fit: BoxFit.cover),
                  if (_prediction == "Analyzing...")
                    Container(
                      color: Colors.black54,
                      child: const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(color: Colors.white),
                            SizedBox(height: 16),
                            Text('Analyzing botanical features...', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
      ),
    );
  }

  Widget _buildResultCard() {
    final confColor = _confidenceColor(_confidence);

    return _ClickableResultCard(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => PredictionResultScreen(
              plant: _matchedPlant,
              confidence: _confidence,
              message: _predictionMessage,
            ),
          ),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: ScanPalette.surfaceWhite,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: confColor.withOpacity(0.3), width: 1.5),
          boxShadow: [
            BoxShadow(color: confColor.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 8)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: confColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _confidenceLabel(_confidence),
                    style: TextStyle(color: confColor, fontWeight: FontWeight.w800, fontSize: 12),
                  ),
                ),
                const Spacer(),
                Text(
                  '${(_confidence * 100).toStringAsFixed(1)}%',
                  style: TextStyle(color: confColor, fontWeight: FontWeight.w800, fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              _matchedPlant?.name ?? 'Unknown Plant',
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: ScanPalette.textPrimary, letterSpacing: -0.5),
            ),
            if (_matchedPlant != null) ...[
              const SizedBox(height: 4),
              Text(
                _matchedPlant!.scientificName,
                style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic, color: ScanPalette.textSecondary),
              ),
            ],
            if (_predictionMessage != null) ...[
              const SizedBox(height: 12),
              Text(
                _predictionMessage!,
                style: const TextStyle(fontSize: 14, color: ScanPalette.textSecondary, height: 1.4),
              ),
            ],
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'View Remedy',
                  style: TextStyle(color: confColor, fontWeight: FontWeight.w700, fontSize: 15),
                ),
                const SizedBox(width: 4),
                Icon(Icons.arrow_forward_ios_rounded, size: 14, color: confColor),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ScanPalette.warningBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: ScanPalette.warningRed.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: ScanPalette.warningRed),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _errorMessage!,
              style: const TextStyle(color: ScanPalette.warningRed, fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: ScanPalette.warningRed),
            onPressed: _isModelLoading ? null : _loadModel,
          )
        ],
      ),
    );
  }

 Widget _buildBottomControls() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 10, 24, 30),
      child: Row(
        children: [
          // Gallery button
          GestureDetector(
            onTap: _isModelLoading ? null : () => _takePhoto(fromGallery: true),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
              decoration: BoxDecoration(
                color: ScanPalette.surfaceWhite,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: ScanPalette.brandGreen.withOpacity(0.3), width: 1.5),
              ),
              child: const Icon(Icons.photo_library_rounded, color: ScanPalette.brandGreen, size: 24),
            ),
          ),
          const SizedBox(width: 12),
          // Camera button
          Expanded(
            child: GestureDetector(
              onTap: _isModelLoading ? null : () => _takePhoto(),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 20),
                decoration: BoxDecoration(
                  color: _isModelLoading ? ScanPalette.textSecondary : ScanPalette.brandGreen,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: ScanPalette.brandGreen.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.document_scanner_rounded, color: Colors.white, size: 24),
                    const SizedBox(width: 12),
                    Text(
                      _image == null ? 'Scan Leaf' : 'Scan Again',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _interpreter?.close();
    super.dispose();
  }
}

// --- Helper for click animation on Result Card ---
class _ClickableResultCard extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const _ClickableResultCard({required this.child, required this.onTap});

  @override
  State<_ClickableResultCard> createState() => _ClickableResultCardState();
}

class _ClickableResultCardState extends State<_ClickableResultCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeInOut,
        child: widget.child,
      ),
    );
  }
}