import 'dart:convert';
import 'dart:io';

import 'package:warung_pintar_cimahi/core/ai/ai_service.dart';
import 'package:warung_pintar_cimahi/core/ai/inference_retry.dart';
import 'package:warung_pintar_cimahi/core/ai/tool_call_result.dart';
import 'package:warung_pintar_cimahi/core/error/result.dart';
import 'package:warung_pintar_cimahi/core/vision/image_quality_gate.dart';
import 'package:warung_pintar_cimahi/features/catalog/domain/repositories/catalog_repository.dart';

class ParseProductResult {
  final String productName;
  final String estimatedCategory;
  final String? sizeOrWeight;
  const ParseProductResult({
    required this.productName,
    required this.estimatedCategory,
    this.sizeOrWeight,
  });
}

class ParseProductUseCase {
  final AiService _aiService;
  final CatalogRepository _catalogRepository;

  const ParseProductUseCase(this._aiService, this._catalogRepository);

  static const _systemPrompt = '''
Kamu membantu menambah barang baru di WarungPintar dari foto kemasan.
Dari gambar kemasan produk, ekstrak:
- Nama produk (brand + jenis + ukuran/berat jika ada)
- Estimasi kategori (Sembako, Minuman, Snack, dll)
JANGAN menebak harga — harga tidak ada di kemasan.
Output HANYA JSON valid.

TOOLS:
- parse_product_from_image: Ekstrak nama, kategori, dan ukuran dari gambar kemasan.
''';

  Future<Result<ParseProductResult, String>> call(File imageFile) async {
    final qualityResult = await ImageQualityGate.validate(imageFile);
    switch (qualityResult) {
      case ImageQualityFail(:final reason):
        return Failure(_qualityMessage(reason));
      case ImageQualityPass():
        break;
    }

    final bytes = await imageFile.readAsBytes();
    final base64Image = base64Encode(bytes);

    final result = await InferenceRetry.runWithRetry(
      aiService: _aiService,
      systemPrompt: _systemPrompt,
      userInput: '',
      imageBase64: base64Image,
    );

    switch (result) {
      case Success(:final data):
        return _processResult(data, imageFile.path);
      case Failure(:final error):
        return Failure('Gagal memproses gambar: ${error.message}');
    }
  }

  Future<Result<ParseProductResult, String>> _processResult(
    ToolCallResult toolCall,
    String imagePath,
  ) async {
    if (toolCall is! ToolCallSuccess) {
      return const Failure('AI tidak dapat mengenali produk');
    }

    if (toolCall.name == 'parse_product_from_image') {
      final productName = toolCall.arguments['product_name']?.toString() ?? '';
      final category =
          toolCall.arguments['estimated_category']?.toString() ?? '';
      final size = toolCall.arguments['size_or_weight']?.toString();

      if (productName.isEmpty) {
        return const Failure('Nama produk tidak terdeteksi');
      }

      final addResult = await _catalogRepository.addItem(
        itemName: productName,
        defaultPriceSen: 0,
        currentQty: 0,
        categoryId: null,
        rawInputSource: imagePath,
      );

      switch (addResult) {
        case Success():
          return Success(
            ParseProductResult(
              productName: productName,
              estimatedCategory: category,
              sizeOrWeight: size,
            ),
          );
        case Failure(:final error):
          return Failure(error);
      }
    }

    return const Failure('Format produk tidak dikenali');
  }

  String _qualityMessage(ImageQualityFailReason reason) => switch (reason) {
    ImageQualityFailReason.fileTooSmall => 'Gambar terlalu kecil atau buram',
    ImageQualityFailReason.resolutionTooLow =>
      'Resolusi terlalu rendah — pastikan kemasan mengisi layar',
    ImageQualityFailReason.tooDark => 'Gambar terlalu gelap — perbaiki cahaya',
  };
}
