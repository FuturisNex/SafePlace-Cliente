import 'package:flutter/material.dart';
import '../models/review.dart';
import '../models/establishment.dart'; // Para DifficultyLevel
import '../services/firebase_service.dart';
import '../services/gamification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:io'; // For File

class ReviewProvider with ChangeNotifier {
  List<Review> _reviews = [];
  bool _isLoading = false;

  List<Review> get reviews => _reviews;
  bool get isLoading => _isLoading;

  ReviewProvider() {
    _loadReviews();
  }

  Future<void> _loadReviews() async {
    try {
      // Tentar carregar do Firestore primeiro
      try {
        final establishments = await FirebaseService.getAllEstablishments();
        final allReviewsList = <Review>[];
        for (final establishment in establishments) {
          final reviews = await FirebaseService.getReviewsForEstablishment(establishment.id);
          allReviewsList.addAll(reviews);
        }
        
        _reviews = allReviewsList;
        _reviews.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        notifyListeners();
        
        // Salvar localmente como backup
        await _saveReviews();
        return;
      } catch (e) {
        debugPrint('⚠️ Erro ao carregar do Firestore, tentando local: $e');
      }

      // Fallback: carregar localmente
      final prefs = await SharedPreferences.getInstance();
      final reviewsJson = prefs.getStringList('reviews') ?? [];
      
      _reviews = reviewsJson
          .map((json) => Review.fromJson(jsonDecode(json)))
          .toList();
      
      _reviews.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Erro ao carregar avaliações: $e');
    }
  }
  

  Future<void> _saveReviews() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final reviewsJson = _reviews
          .map((review) => jsonEncode(review.toJson()))
          .toList();
      
      await prefs.setStringList('reviews', reviewsJson);
    } catch (e) {
      debugPrint('Erro ao salvar avaliações: $e');
    }
  }

  Future<bool> addReview({
    required String establishmentId,
    required String userId,
    required String userName,
    String? userPhotoUrl,
    required double rating,
    required String comment,
    List<String>? dietaryRestrictions,
    bool verifiedVisit = false,
    List<String>? photos, // URLs já prontas (para compatibilidade)
    List<File>? photoFiles, // Arquivos para upload (novo)
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final review = Review(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        establishmentId: establishmentId,
        userId: userId,
        userName: userName,
        userPhotoUrl: userPhotoUrl,
        rating: rating,
        comment: comment,
        createdAt: DateTime.now(),
        dietaryRestrictions: dietaryRestrictions,
        verifiedVisit: verifiedVisit,
        photos: photos, // Se já tiver URLs, usar
      );

      // Salvar no Firestore primeiro para obter o ID real
      final reviewId = await FirebaseService.saveReview(review);
      
      // Se houver arquivos de fotos, fazer upload DEPOIS de salvar (com ID real)
      List<String>? finalPhotoUrls = photos; // Usar URLs já prontas se houver
      if (photoFiles != null && photoFiles.isNotEmpty) {
        try {
          // Fazer upload das fotos com o ID real do Firestore
          finalPhotoUrls = await FirebaseService.uploadReviewPhotos(photoFiles, reviewId);
          debugPrint('✅ ${finalPhotoUrls.length} foto(s) enviada(s) com ID real: $reviewId');
          
          // Atualizar a avaliação no Firestore com as URLs das fotos
          await FirebaseService.updateReviewPhotos(reviewId, finalPhotoUrls);
        } catch (e) {
          debugPrint('❌ Erro ao fazer upload das fotos: $e');
          // Continuar sem fotos se o upload falhar
        }
      }
      
      // Criar nova instância com o ID do Firestore e fotos atualizadas
      final savedReview = Review(
        id: reviewId,
        establishmentId: review.establishmentId,
        userId: review.userId,
        userName: review.userName,
        userPhotoUrl: review.userPhotoUrl,
        rating: review.rating,
        comment: review.comment,
        createdAt: review.createdAt,
        dietaryRestrictions: review.dietaryRestrictions,
        verifiedVisit: review.verifiedVisit,
        photos: finalPhotoUrls, // URLs das fotos (se houver)
      );
      
      _reviews.add(savedReview);
      _reviews.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      // Adicionar pontos e atualizar estatísticas
      try {
        if (finalPhotoUrls != null && finalPhotoUrls.isNotEmpty) {
          // Avaliação com foto: +25 pts
          await GamificationService.addPoints(userId, GamificationService.getPointsForAction('review_with_photo'), 'Avaliação com foto');
        } else {
          // Avaliação sem foto: +15 pts
          await GamificationService.addPoints(userId, GamificationService.getPointsForAction('review'), 'Avaliação');
        }
        
        // Atualizar total de avaliações do usuário
        await FirebaseService.updateUserStats(userId, reviewsIncrement: 1);
        
        // Atualizar selo do usuário
        await GamificationService.updateUserSeal(userId);
        
        // Verificar se o estabelecimento deve receber o selo Popular automaticamente
        // Selo Popular: média das avaliações >= 4.0
        await _checkAndUpdateEstablishmentPopularSeal(establishmentId);
      } catch (e) {
        debugPrint('⚠️ Erro ao adicionar pontos: $e');
      }
      
      // Salvar localmente como backup
      await _saveReviews();
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('❌ Erro ao adicionar avaliação: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  List<Review> getReviewsForEstablishment(String establishmentId) {
    return _reviews
        .where((review) => review.establishmentId == establishmentId)
        .toList();
  }

  double getAverageRating(String establishmentId) {
    final establishmentReviews = getReviewsForEstablishment(establishmentId);
    
    if (establishmentReviews.isEmpty) {
      return 0.0;
    }
    
    final sum = establishmentReviews.fold(0.0, (sum, review) => sum + review.rating);
    return sum / establishmentReviews.length;
  }

  int getReviewCount(String establishmentId) {
    return getReviewsForEstablishment(establishmentId).length;
  }

  Future<bool> deleteReview(String reviewId) async {
    try {
      // Deletar do Firestore
      await FirebaseService.deleteReview(reviewId);
      
      // Remover da lista local
      _reviews.removeWhere((review) => review.id == reviewId);
      await _saveReviews();
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('❌ Erro ao deletar avaliação: $e');
      return false;
    }
  }

  // Verificar se usuário já avaliou este estabelecimento
  Review? getUserReviewForEstablishment(String establishmentId, String userId) {
    try {
      return _reviews.firstWhere(
        (review) => review.establishmentId == establishmentId && review.userId == userId,
      );
    } catch (e) {
      return null;
    }
  }

  // Método para carregar avaliações de um estabelecimento do Firestore
  Future<void> loadReviewsForEstablishment(String establishmentId) async {
    try {
      final reviews = await FirebaseService.getReviewsForEstablishment(establishmentId);
      
      // Adicionar/atualizar na lista local
      for (final review in reviews) {
        final index = _reviews.indexWhere((r) => r.id == review.id);
        if (index >= 0) {
          _reviews[index] = review;
        } else {
          _reviews.add(review);
        }
      }
      
      _reviews.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      notifyListeners();
    } catch (e) {
      debugPrint('⚠️ Erro ao carregar avaliações do Firestore: $e');
    }
  }

  /// Verifica e sincroniza o selo Popular automaticamente:
  /// media >= 4.0 => Popular, abaixo disso => sem selo ("")
  Future<void> _checkAndUpdateEstablishmentPopularSeal(String establishmentId) async {
    try {
      // Buscar todas as avaliacoes do estabelecimento
      final reviews = await FirebaseService.getReviewsForEstablishment(establishmentId);

      final reviewCount = reviews.length;
      final averageRating = reviewCount == 0
          ? 0.0
          : reviews.fold<double>(0.0, (sum, r) => sum + r.rating) / reviewCount;
      final shouldBePopular = reviewCount > 0 && averageRating >= 4.0;

      debugPrint('Estabelecimento $establishmentId: media=${averageRating.toStringAsFixed(2)}, avaliacoes=$reviewCount');

      final establishment = await FirebaseService.getEstablishmentById(establishmentId);
      if (establishment == null) return;

      final currentLevel = establishment.difficultyLevel;
      final desiredLevel = shouldBePopular ? DifficultyLevel.popular : DifficultyLevel.none;

      if (currentLevel != desiredLevel) {
        await FirebaseService.updateEstablishment(establishmentId, {
          'difficultyLevel': desiredLevel == DifficultyLevel.popular ? 'Popular' : '',
          'rating': averageRating,
          'ratingCount': reviewCount,
        });
      }
    } catch (e) {
      debugPrint('Erro ao verificar selo Popular: $e');
    }
  }
}
