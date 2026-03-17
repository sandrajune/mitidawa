import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image/image.dart' as img;

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  File? _image;
  Interpreter? _interpreter;
  List<String> _labels = [];
  String _prediction = "No prediction yet";
  String? _predictionMessage;
  double _confidence = 0.0;
  String? _errorMessage;
  bool _isModelLoading = false;

  Color _confidenceColor(double confidence) {
    if (confidence >= 0.80) return const Color(0xFF2E7D32);
    if (confidence >= 0.35) return const Color(0xFFEF6C00);
    return const Color(0xFF8D6E63);
  }

  String _confidenceLabel(double confidence) {
    if (confidence >= 0.80) return 'High confidence';
    if (confidence >= 0.35) return 'Medium confidence';
    return 'Low confidence';
  }

  @override
  void initState() {
    super.initState();
    _loadModel();
    _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    await [Permission.camera, Permission.photos].request();
  }

  Future<void> _loadModel() async {
    if (!mounted) return;
    setState(() {
      _isModelLoading = true;
      _errorMessage = null;
    });

    try {
      _interpreter?.close();
      _interpreter = await Interpreter.fromAsset(
        'assets/models/plant_identifier_final.tflite',
      );

      final labelsData = await rootBundle.loadString('assets/labels.txt');
      _labels = labelsData
          .split('\n')
          .map((line) => line.trim())
          .where((line) => line.isNotEmpty)
          .toList();

      if (!mounted) return;
      setState(() {
        _errorMessage = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage =
            'Model failed to load on this device/emulator.\nDetails: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isModelLoading = false;
        });
      }
    }
  }

  Future<bool> _ensureCameraPermission() async {
    var status = await Permission.camera.status;
    if (status.isGranted) return true;

    status = await Permission.camera.request();
    if (status.isGranted) return true;

    if (status.isPermanentlyDenied && mounted) {
      await openAppSettings();
    }
    return false;
  }

  Future<void> _takePhoto() async {
    final hasPermission = await _ensureCameraPermission();
    if (!hasPermission) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Camera permission is required.')),
      );
      return;
    }

    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera);

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });

      final result = await predict(_image!);
      if (!mounted || result == null) return;

      setState(() {
        _prediction = (result['plant'] as String?) ?? 'Unknown';
        _confidence = (result['confidence'] as double?) ?? 0.0;
        _predictionMessage = result['message'] as String?;
      });
    }
  }

  Future<Map<String, dynamic>?> predict(File imageFile) async {
    if (_interpreter == null || _labels.isEmpty) {
      if (!mounted) return null;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Model not ready yet. Please wait.')),
      );
      return null;
    }

    final inputShape = _interpreter!.getInputTensor(0).shape;
    if (inputShape.length < 4) {
      if (!mounted) return null;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unexpected model input shape: $inputShape')),
      );
      return null;
    }

    final outputShape = _interpreter!.getOutputTensor(0).shape;
    if (outputShape.length < 2) {
      if (!mounted) return null;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unexpected model output shape: $outputShape')),
      );
      return null;
    }

    final inputHeight = inputShape[1];
    final inputWidth = inputShape[2];
    final outputClasses = outputShape.last;

    final decoded = img.decodeImage(await imageFile.readAsBytes());
    if (decoded == null) return null;

    final resized =
        img.copyResize(decoded, width: inputWidth, height: inputHeight);

    final input = List.generate(
      1,
      (_) => List.generate(
        inputHeight,
        (y) => List.generate(
          inputWidth,
          (x) {
            final pixel = resized.getPixel(x, y);
            return [
              (pixel.r / 127.5) - 1.0,
              (pixel.g / 127.5) - 1.0,
              (pixel.b / 127.5) - 1.0,
            ];
          },
        ),
      ),
    );

    final output = List.generate(
      1,
      (_) => List<double>.filled(outputClasses, 0.0),
    );

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

    final safeIndex = _labels.isEmpty ? 0 : min(maxIndex, _labels.length - 1);
    final predictedLabel = _labels.isNotEmpty ? _labels[safeIndex] : 'Unknown';

    const double confidenceThreshold = 0.80;
    const double nonPlantThreshold = 0.35;

    if (maxProb >= confidenceThreshold) {
      return {
        'plant': predictedLabel,
        'confidence': maxProb,
        'isConfident': true,
      };
    } else if (maxProb < nonPlantThreshold) {
      return {
        'plant': null,
        'confidence': maxProb,
        'isConfident': false,
        'message':
            'This does not look like one of the trained plants/leaves. Try a clearer leaf photo.',
      };
    } else {
      return {
        'plant': predictedLabel,
        'confidence': maxProb,
        'isConfident': false,
        'message':
            'Low confidence (${(maxProb * 100).toStringAsFixed(1)}%). Try a clearer, closer photo.',
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    final confidenceColor = _confidenceColor(_confidence);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F5EF),
      appBar: AppBar(
        title: const Text('Scan Plant'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: _isModelLoading
                      ? const Color(0xFFFFE0B2)
                      : (_errorMessage != null
                          ? const Color(0xFFD7CCC8)
                          : const Color(0xFFC8E6C9)),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _isModelLoading
                      ? 'Model loading...'
                      : (_errorMessage != null
                          ? 'Model not ready'
                          : 'Model ready'),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 16),
              if (_errorMessage != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEBEE),
                    borderRadius: BorderRadius.circular(14),
                    border:
                        Border.all(color: const Color(0xFFD32F2F), width: 1),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(
                      color: Color(0xFFB71C1C),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 16),
              ],
              if (_isModelLoading) ...[
                const CircularProgressIndicator(color: Color(0xFF2E7D32)),
                const SizedBox(height: 12),
                const Text('Preparing leaf model...'),
                const SizedBox(height: 20),
              ],
              Container(
                width: double.infinity,
                height: 280,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(18),
                  border:
                      Border.all(color: const Color(0xFFA5D6A7), width: 1.2),
                ),
                child: _image == null
                    ? const Center(
                        child: Text(
                          'Take a leaf photo to identify',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF33691E),
                          ),
                        ),
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.file(_image!, fit: BoxFit.cover),
                      ),
              ),
              const SizedBox(height: 18),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFD7CCC8), width: 1),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x22000000),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Text(
                      'Prediction Result',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF5D4037),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _prediction == "No prediction yet"
                          ? (_errorMessage == null
                              ? "No prediction yet"
                              : "No prediction yet (model failed to load)")
                          : _prediction,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1B5E20),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: confidenceColor.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(color: confidenceColor, width: 1.2),
                      ),
                      child: Text(
                        '${_confidenceLabel(_confidence)} • ${(_confidence * 100).toStringAsFixed(1)}%',
                        style: TextStyle(
                          color: confidenceColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 350),
                      curve: Curves.easeOutBack,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                            color: const Color(0xFF66BB6A), width: 1),
                      ),
                      child: const Text(
                        '🌿 Confidence bubble',
                        style: TextStyle(
                          color: Color(0xFF2E7D32),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (_predictionMessage != null) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3E0),
                    borderRadius: BorderRadius.circular(14),
                    border:
                        Border.all(color: const Color(0xFFFFB74D), width: 1),
                  ),
                  child: Text(
                    _predictionMessage!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFFE65100),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
              if (_errorMessage != null) ...[
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _isModelLoading ? null : _loadModel,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry model load'),
                ),
              ],
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF2E7D32),
        onPressed: _isModelLoading ? null : _takePhoto,
        child: const Icon(Icons.camera_alt),
      ),
    );
  }

  @override
  void dispose() {
    _interpreter?.close();
    super.dispose();
  }
}
