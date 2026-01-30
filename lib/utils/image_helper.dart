import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';

class ImageHelper {
  /// Cria uma imagem customizada com foto do restaurante dentro de um círculo verde
  /// Retorna os bytes da imagem PNG para ser usado no Mapbox
  static Future<Uint8List?> createMarkerImageWithGreenCircle(
    String imageUrl,
    {
    int size = 100, // Tamanho total da imagem (100x100) - maior para fotos grandes
    int borderWidth = 5, // Largura da borda verde
  }) async {
    try {
      // 1. Carregar a imagem da URL
      final response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode != 200) {
        debugPrint('Erro ao carregar imagem: ${response.statusCode}');
        return null;
      }

      final imageBytes = response.bodyBytes;
      final codec = await ui.instantiateImageCodec(imageBytes);
      final frame = await codec.getNextFrame();
      final originalImage = frame.image;

      // 2. Criar um PictureRecorder para desenhar a imagem composta
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);

      // 3. Calcular dimensões
      final center = Offset(size / 2, size / 2);
      final imageRadius = (size - borderWidth * 2) / 2;
      final circleRadius = size / 2;

      // 4. Desenhar círculo verde de fundo (borda externa)
      final greenPaint = Paint()
        ..color = const Color(0xFF4CAF50) // Verde
        ..style = PaintingStyle.fill;
      canvas.drawCircle(center, circleRadius, greenPaint);

      // 5. Criar clip path para desenhar a foto em círculo
      final imageRect = Rect.fromCircle(center: center, radius: imageRadius);
      canvas.save();
      canvas.clipPath(
        Path()..addOval(imageRect),
      );

      // 6. Desenhar a foto cortada em círculo
      final photoPaint = Paint();
      
      // Calcular dimensões para preencher o círculo mantendo proporção
      final imageWidth = originalImage.width.toDouble();
      final imageHeight = originalImage.height.toDouble();
      final imageAspectRatio = imageWidth / imageHeight;
      final circleAspectRatio = 1.0; // Círculo é sempre 1:1
      
      double srcWidth, srcHeight, srcX, srcY;
      if (imageAspectRatio > circleAspectRatio) {
        // Imagem mais larga - usar altura completa e cortar laterais
        srcHeight = imageHeight;
        srcWidth = imageHeight; // Quadrado
        srcX = (imageWidth - srcWidth) / 2;
        srcY = 0;
      } else {
        // Imagem mais alta - usar largura completa e cortar topo/baixo
        srcWidth = imageWidth;
        srcHeight = imageWidth; // Quadrado
        srcX = 0;
        srcY = (imageHeight - srcHeight) / 2;
      }
      
      final srcRect = Rect.fromLTWH(srcX, srcY, srcWidth, srcHeight);
      final dstRect = Rect.fromCircle(center: center, radius: imageRadius);
      
      canvas.drawImageRect(
        originalImage,
        srcRect,
        dstRect,
        photoPaint,
      );
      
      canvas.restore(); // Restaurar canvas após clip

      originalImage.dispose();

      // 7. Converter para bytes PNG
      final picture = recorder.endRecording();
      final image = await picture.toImage(size, size);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      picture.dispose();
      image.dispose();

      return byteData?.buffer.asUint8List();
    } catch (e) {
      debugPrint('Erro ao criar imagem customizada: $e');
      return null;
    }
  }

  /// Cria uma imagem placeholder quando não há foto disponível
  static Future<Uint8List> createPlaceholderMarkerImage({
    int size = 60,
    int borderWidth = 4,
  }) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    final center = Offset(size / 2, size / 2);
    final circleRadius = size / 2;

    // Círculo verde de fundo
    final greenPaint = Paint()
      ..color = const Color(0xFF4CAF50)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, circleRadius, greenPaint);

    // Ícone de restaurante no centro
    final iconPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    
    // Desenhar ícone simples de restaurante (garfo e faca)
    final iconSize = size * 0.4;
    final iconPath = Path()
      ..moveTo(center.dx - iconSize / 3, center.dy - iconSize / 2)
      ..lineTo(center.dx - iconSize / 3, center.dy + iconSize / 2)
      ..moveTo(center.dx + iconSize / 3, center.dy - iconSize / 2)
      ..lineTo(center.dx + iconSize / 3, center.dy + iconSize / 2)
      ..addOval(Rect.fromCircle(
        center: Offset(center.dx, center.dy + iconSize / 4),
        radius: iconSize / 6,
      ));
    
    canvas.drawPath(iconPath, iconPaint);

    final picture = recorder.endRecording();
    final image = await picture.toImage(size, size);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    picture.dispose();
    image.dispose();

    return byteData!.buffer.asUint8List();
  }
}

