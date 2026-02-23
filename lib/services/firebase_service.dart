import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'cloudinary_service.dart';
import '../models/establishment.dart';
import '../models/review.dart';
import '../models/user.dart';
import '../models/trail_record.dart';
import '../models/menu_item.dart';
import '../models/trip.dart';

// Helper para converter dados do Firestore para formato JSON
Map<String, dynamic> _convertFirestoreData(Map<String, dynamic> data) {
  final converted = Map<String, dynamic>.from(data);
  
  // Converter Timestamps do Firestore para strings ISO8601
  converted.forEach((key, value) {
    if (value is Timestamp) {
      converted[key] = value.toDate().toIso8601String();
    } else if (value is DateTime) {
      converted[key] = value.toIso8601String();
    }
  });
  
  return converted;
}

class FirebaseService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseStorage _storage = FirebaseStorage.instance;

  // ============ APP CONFIG ============

  /// Stream do tema sazonal configurado no painel admin.
  /// Lê o campo 'seasonalTheme' do documento 'appConfig/global'.
  static Stream<String?> seasonalThemeStream() {
    return _firestore
        .collection('appConfig')
        .doc('global')
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists) return null;
      final data = snapshot.data();
      final value = data?['seasonalTheme'];
      if (value is String) {
        return value;
      }
      return null;
    });
  }

  /// Define o tema sazonal atual. Pode ser usado pelo painel admin.
  /// Exemplos de valores: 'none', 'christmas', 'carnival'.
  static Future<void> setSeasonalTheme(String? themeKey) async {
    await _firestore.collection('appConfig').doc('global').set(
      {
        'seasonalTheme': themeKey,
      },
      SetOptions(merge: true),
    );
  }

  static Future<Map<String, dynamic>?> getGlobalAppConfig() async {
    try {
      final snapshot = await _firestore.collection('appConfig').doc('global').get();
      if (!snapshot.exists || snapshot.data() == null) {
        return null;
      }
      final data = snapshot.data() as Map<String, dynamic>;
      return Map<String, dynamic>.from(data);
    } catch (e) {
      debugPrint('❌ Erro ao carregar appConfig/global: $e');
      return null;
    }
  }

  // ============ ESTABELECIMENTOS ============
  
  /// Salva um estabelecimento no Firestore
  static Future<String> saveEstablishment(Establishment establishment) async {
    try {
      // Remover o campo 'id' dos dados, pois o Firestore gera o ID do documento automaticamente
      final data = establishment.toJson();
      data.remove('id'); // O ID do documento do Firestore será o ID real
      
      final docRef = await _firestore
          .collection('establishments')
          .add(data)
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw TimeoutException('Timeout ao salvar estabelecimento no Firestore');
            },
          );
      debugPrint('✅ Estabelecimento salvo com ID: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      debugPrint('❌ Erro ao salvar estabelecimento: $e');
      rethrow;
    }
  }

  /// Atualiza um estabelecimento no Firestore
  static Future<void> updateEstablishment(String establishmentId, Map<String, dynamic> data) async {
    try {
      await _firestore
          .collection('establishments')
          .doc(establishmentId)
          .update(data)
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw TimeoutException('Timeout ao atualizar estabelecimento no Firestore');
            },
          );
      debugPrint('✅ Estabelecimento atualizado: $establishmentId');
    } catch (e) {
      debugPrint('❌ Erro ao atualizar estabelecimento: $e');
      rethrow;
    }
  }

  /// Busca um estabelecimento pelo ID
  static Future<Establishment?> getEstablishmentById(String establishmentId) async {
    try {
      final doc = await _firestore.collection('establishments').doc(establishmentId).get();
      if (!doc.exists) return null;
      
      final rawData = doc.data();
      if (rawData == null) return null;
      
      final data = _convertFirestoreData(rawData);
      data['id'] = doc.id;
      return Establishment.fromJson(data);
    } catch (e) {
      debugPrint('❌ Erro ao buscar estabelecimento por ID: $e');
      return null;
    }
  }

  /// Busca estabelecimentos de um dono específico
  static Future<List<Establishment>> getEstablishmentsByOwner(String ownerId) async {
    try {
      final querySnapshot = await _firestore
          .collection('establishments')
          .where('ownerId', isEqualTo: ownerId)
          .get();

      return querySnapshot.docs.map((doc) {
        final rawData = doc.data();
        final data = _convertFirestoreData(rawData);
        data['id'] = doc.id;
        return Establishment.fromJson(data);
      }).toList();
    } catch (e) {
      debugPrint('❌ Erro ao buscar estabelecimentos: $e');
      return [];
    }
  }

  /// Busca todos os estabelecimentos
  static Future<List<Establishment>> getAllEstablishments() async {
    try {
      final querySnapshot = await _firestore
          .collection('establishments')
          .get();

      return querySnapshot.docs.map((doc) {
        final rawData = doc.data();
        final data = _convertFirestoreData(rawData);
        data['id'] = doc.id;
        return Establishment.fromJson(data);
      }).toList();
    } catch (e) {
      debugPrint('❌ Erro ao buscar estabelecimentos: $e');
      return [];
    }
  }

  /// Stream de estabelecimentos (atualização em tempo real)
  static Stream<List<Establishment>> establishmentsStream() {
    return _firestore
        .collection('establishments')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final rawData = doc.data() as Map<String, dynamic>;
        final data = _convertFirestoreData(rawData);
        data['id'] = doc.id;
        return Establishment.fromJson(data);
      }).toList();
    });
  }

  /// Stream de estabelecimentos de um dono específico (atualização em tempo real)
  static Stream<List<Establishment>> establishmentsByOwnerStream(String ownerId) {
    return _firestore
        .collection('establishments')
        .where('ownerId', isEqualTo: ownerId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final rawData = doc.data() as Map<String, dynamic>;
        final data = _convertFirestoreData(rawData);
        data['id'] = doc.id;
        return Establishment.fromJson(data);
      }).toList();
    });
  }

  /// Stream de um estabelecimento específico por ID (atualização em tempo real)
  static Stream<Establishment?> establishmentStream(String establishmentId) {
    return _firestore
        .collection('establishments')
        .doc(establishmentId)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists) return null;
      final rawData = snapshot.data() as Map<String, dynamic>;
      final data = _convertFirestoreData(rawData);
      data['id'] = snapshot.id;
      return Establishment.fromJson(data);
    });
  }

  /// Cria uma solicitação de certificação técnica para um estabelecimento
  static Future<void> createCertificationRequest({
    required String establishmentId,
    required String establishmentName,
    required String ownerId,
    required String ownerName,
  }) async {
    try {
      await _firestore.collection('certificationRequests').add({
        'establishmentId': establishmentId,
        'establishmentName': establishmentName,
        'ownerId': ownerId,
        'ownerName': ownerName,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'source': 'app',
      });
      debugPrint('✅ Solicitação de certificação criada para $establishmentName ($establishmentId)');
    } catch (e) {
      debugPrint('❌ Erro ao criar solicitação de certificação: $e');
      rethrow;
    }
  }

  // ============ AVALIAÇÕES ============

  /// Salva uma avaliação no Firestore
  static Future<String> saveReview(Review review) async {
    try {
      final docRef = await _firestore
          .collection('reviews')
          .add(review.toJson());
      debugPrint('✅ Avaliação salva com ID: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      debugPrint('❌ Erro ao salvar avaliação: $e');
      rethrow;
    }
  }

  /// Atualiza as URLs das fotos de uma avaliação
  static Future<void> updateReviewPhotos(String reviewId, List<String> photoUrls) async {
    try {
      await _firestore.collection('reviews').doc(reviewId).update({
        'photos': photoUrls,
      });
      debugPrint('✅ Fotos da avaliação atualizadas: $reviewId');
    } catch (e) {
      debugPrint('❌ Erro ao atualizar fotos da avaliação: $e');
      rethrow;
    }
  }

  /// Busca avaliações de um estabelecimento específico
  static Future<List<Review>> getReviewsForEstablishment(String establishmentId) async {
    try {
      QuerySnapshot querySnapshot;
      try {
        querySnapshot = await _firestore
            .collection('reviews')
            .where('establishmentId', isEqualTo: establishmentId)
            .orderBy('createdAt', descending: true)
            .get();
      } catch (e) {
        // Se orderBy falhar (índice não criado), tentar sem orderBy
        debugPrint('⚠️ Erro com orderBy, tentando sem: $e');
        querySnapshot = await _firestore
            .collection('reviews')
            .where('establishmentId', isEqualTo: establishmentId)
            .get();
      }

      return querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return Review.fromJson(data);
      }).toList();
    } catch (e) {
      debugPrint('❌ Erro ao buscar avaliações: $e');
      return [];
    }
  }

  /// Stream de avaliações de um estabelecimento (atualização em tempo real)
  static Stream<List<Review>> reviewsStream(String establishmentId) {
    return _firestore
        .collection('reviews')
        .where('establishmentId', isEqualTo: establishmentId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return Review.fromJson(data);
      }).toList();
    });
  }

  /// Verifica se um usuário já avaliou um estabelecimento
  static Future<Review?> getUserReviewForEstablishment(String establishmentId, String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('reviews')
          .where('establishmentId', isEqualTo: establishmentId)
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return null;
      }

      final doc = querySnapshot.docs.first;
      final data = doc.data();
      data['id'] = doc.id;
      return Review.fromJson(data);
    } catch (e) {
      debugPrint('❌ Erro ao verificar avaliação do usuário: $e');
      return null;
    }
  }

  /// Deleta uma avaliação
  static Future<void> deleteReview(String reviewId) async {
    try {
      await _firestore.collection('reviews').doc(reviewId).delete();
      debugPrint('✅ Avaliação deletada: $reviewId');
    } catch (e) {
      debugPrint('❌ Erro ao deletar avaliação: $e');
      rethrow;
    }
  }

  /// Verifica se o usuário já curtiu uma avaliação
  static Future<bool> isReviewLikedByUser({
    required String reviewId,
    required String userId,
  }) async {
    try {
      final likeDocId = '${reviewId}_$userId';
      final doc = await _firestore.collection('reviewLikes').doc(likeDocId).get();
      return doc.exists;
    } catch (e) {
      debugPrint('❌ Erro ao verificar like da avaliação: $e');
      return false;
    }
  }

  /// Marca uma avaliação como curtida pelo usuário
  static Future<void> likeReview({
    required String reviewId,
    required String userId,
  }) async {
    try {
      final likeDocId = '${reviewId}_$userId';
      final likeRef = _firestore.collection('reviewLikes').doc(likeDocId);
      final snapshot = await likeRef.get();
      if (snapshot.exists) {
        return;
      }

      await _firestore.runTransaction((tx) async {
        tx.set(likeRef, {
          'reviewId': reviewId,
          'userId': userId,
          'createdAt': DateTime.now().toIso8601String(),
        });

        final reviewRef = _firestore.collection('reviews').doc(reviewId);
        tx.update(reviewRef, {
          'likesCount': FieldValue.increment(1),
        });
      });

      debugPrint('✅ Like registrado em review $reviewId por $userId');
    } catch (e) {
      debugPrint('❌ Erro ao registrar like na avaliação: $e');
      rethrow;
    }
  }

  /// Remove curtida de uma avaliação pelo usuário
  static Future<void> unlikeReview({
    required String reviewId,
    required String userId,
  }) async {
    try {
      final likeDocId = '${reviewId}_$userId';
      final likeRef = _firestore.collection('reviewLikes').doc(likeDocId);
      final snapshot = await likeRef.get();
      if (!snapshot.exists) {
        return;
      }

      await _firestore.runTransaction((tx) async {
        tx.delete(likeRef);

        final reviewRef = _firestore.collection('reviews').doc(reviewId);
        tx.update(reviewRef, {
          'likesCount': FieldValue.increment(-1),
        });
      });

      debugPrint('✅ Like removido em review $reviewId por $userId');
    } catch (e) {
      debugPrint('❌ Erro ao remover like da avaliação: $e');
      rethrow;
    }
  }

  // ============ CARDÁPIO / MENU ITEMS ============

  static CollectionReference<Map<String, dynamic>> _menuItemsCollection(String establishmentId) {
    return _firestore
        .collection('establishments')
        .doc(establishmentId)
        .collection('menuItems');
  }

  static Future<List<MenuItem>> getMenuItems(String establishmentId) async {
    try {
      final querySnapshot = await _menuItemsCollection(establishmentId)
          .orderBy('name')
          .get();

      return querySnapshot.docs.map((doc) {
        final rawData = doc.data();
        final data = _convertFirestoreData(rawData);
        data['id'] = doc.id;
        data['establishmentId'] = establishmentId;
        return MenuItem.fromJson(data);
      }).toList();
    } catch (e) {
      debugPrint('❌ Erro ao buscar itens de cardápio para estabelecimento $establishmentId: $e');
      return [];
    }
  }

  static Stream<List<MenuItem>> menuItemsStream(String establishmentId) {
    try {
      return _menuItemsCollection(establishmentId)
          .orderBy('name')
          .snapshots()
          .map((snapshot) {
        return snapshot.docs.map((doc) {
          final rawData = doc.data();
          final data = _convertFirestoreData(rawData);
          data['id'] = doc.id;
          data['establishmentId'] = establishmentId;
          return MenuItem.fromJson(data);
        }).toList();
      });
    } catch (e) {
      debugPrint('❌ Erro ao criar stream de cardápio para estabelecimento $establishmentId: $e');
      return const Stream.empty();
    }
  }

  static Future<String> createMenuItem(String establishmentId, MenuItem item) async {
    try {
      final data = item.toJson();
      data.remove('id');
      data['establishmentId'] = establishmentId;
      data['createdAt'] = FieldValue.serverTimestamp();
      data['updatedAt'] = FieldValue.serverTimestamp();

      final docRef = await _menuItemsCollection(establishmentId)
          .add(data)
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw TimeoutException('Timeout ao salvar item de cardápio no Firestore');
            },
          );
      debugPrint('✅ Item de cardápio criado: ${docRef.id} (${item.name})');
      return docRef.id;
    } catch (e) {
      debugPrint('❌ Erro ao criar item de cardápio: $e');
      rethrow;
    }
  }

  static Future<void> updateMenuItem(
    String establishmentId,
    String menuItemId,
    Map<String, dynamic> data,
  ) async {
    try {
      final updates = Map<String, dynamic>.from(data);
      updates.remove('id');
      updates['updatedAt'] = FieldValue.serverTimestamp();

      await _menuItemsCollection(establishmentId)
          .doc(menuItemId)
          .update(updates)
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw TimeoutException('Timeout ao atualizar item de cardápio no Firestore');
            },
          );
      debugPrint('✅ Item de cardápio atualizado: $menuItemId');
    } catch (e) {
      debugPrint('❌ Erro ao atualizar item de cardápio: $e');
      rethrow;
    }
  }

  static Future<void> deleteMenuItem(String establishmentId, String menuItemId) async {
    try {
      await _menuItemsCollection(establishmentId)
          .doc(menuItemId)
          .delete()
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw TimeoutException('Timeout ao deletar item de cardápio no Firestore');
            },
          );
      debugPrint('✅ Item de cardápio deletado: $menuItemId');
    } catch (e) {
      debugPrint('❌ Erro ao deletar item de cardápio: $e');
      rethrow;
    }
  }

  // ============ UPLOAD DE IMAGENS ============

  /// Upload de imagem de perfil do estabelecimento
  static Future<String> uploadEstablishmentImage(File imageFile, String establishmentId) async {
    try {
      final folder = 'safeplate/establishments/$establishmentId/profile';
      final publicId = 'profile_${DateTime.now().millisecondsSinceEpoch}';
      final downloadUrl = await CloudinaryService.uploadImage(
        imageFile,
        folder: folder,
        publicId: publicId,
      );
      
      debugPrint('✅ Imagem do estabelecimento enviada: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      debugPrint('❌ Erro ao fazer upload da imagem: $e');
      rethrow;
    }
  }

  /// Upload de múltiplas fotos de um estabelecimento (galeria)
  static Future<List<String>> uploadEstablishmentPhotos(
    List<File> imageFiles,
    String establishmentId,
  ) async {
    try {
      final folder = 'safeplate/establishments/$establishmentId/gallery';
      final photoUrls = await CloudinaryService.uploadImages(
        imageFiles,
        folder: folder,
        namePrefix: 'gallery',
      );

      debugPrint('✅ ${photoUrls.length} foto(s) de estabelecimento enviada(s)');
      return photoUrls;
    } catch (e) {
      debugPrint('❌ Erro ao fazer upload das fotos do estabelecimento: $e');
      rethrow;
    }
  }

  /// Atualiza as URLs das fotos de um estabelecimento (inclui avatarUrl = primeira foto, se existir)
  static Future<void> updateEstablishmentPhotos(
    String establishmentId,
    List<String> photoUrls,
  ) async {
    try {
      final updates = <String, dynamic>{
        'photoUrls': photoUrls,
      };
      if (photoUrls.isNotEmpty) {
        updates['avatarUrl'] = photoUrls.first;
      }

      await _firestore.collection('establishments').doc(establishmentId).update(updates);
      debugPrint('✅ Fotos do estabelecimento atualizadas: $establishmentId (${photoUrls.length} fotos)');
    } catch (e) {
      debugPrint('❌ Erro ao atualizar fotos do estabelecimento: $e');
      rethrow;
    }
  }

  /// Upload de imagem de perfil do usuário
  static Future<String> uploadUserImage(File imageFile, String userId) async {
    try {
      final folder = 'safeplate/users/$userId';
      final publicId = 'profile_${DateTime.now().millisecondsSinceEpoch}';
      final downloadUrl = await CloudinaryService.uploadImage(
        imageFile,
        folder: folder,
        publicId: publicId,
      );
      
      debugPrint('✅ Imagem do usuário enviada: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      debugPrint('❌ Erro ao fazer upload da imagem de perfil: $e');
      rethrow;
    }
  }

  /// Upload de imagem de capa do usuário
  static Future<String> uploadUserCoverImage(File imageFile, String userId) async {
    try {
      final folder = 'safeplate/users/$userId';
      final publicId = 'cover_${DateTime.now().millisecondsSinceEpoch}';
      final downloadUrl = await CloudinaryService.uploadImage(
        imageFile,
        folder: folder,
        publicId: publicId,
      );

      debugPrint('✅ Capa do usuário enviada: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      debugPrint('❌ Erro ao fazer upload da capa do usuário: $e');
      rethrow;
    }
  }

  /// Upload de imagem de prato do cardápio
  static Future<String> uploadDishImage(File imageFile, String establishmentId, String dishId) async {
    try {
      final folder = 'safeplate/establishments/$establishmentId/dishes';
      final publicId = '${dishId}_${DateTime.now().millisecondsSinceEpoch}';
      final downloadUrl = await CloudinaryService.uploadImage(
        imageFile,
        folder: folder,
        publicId: publicId,
      );
      
      debugPrint('✅ Imagem do prato enviada: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      debugPrint('❌ Erro ao fazer upload da imagem: $e');
      rethrow;
    }
  }

  /// Upload de fotos de avaliação
  static Future<String> uploadReviewPhoto(File imageFile, String reviewId, int photoIndex) async {
    try {
      final folder = 'safeplate/reviews/$reviewId';
      final publicId = 'photo_${photoIndex}_${DateTime.now().millisecondsSinceEpoch}';
      final downloadUrl = await CloudinaryService.uploadImage(
        imageFile,
        folder: folder,
        publicId: publicId,
      );
      
      debugPrint('✅ Foto da avaliação enviada: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      debugPrint('❌ Erro ao fazer upload da foto da avaliação: $e');
      rethrow;
    }
  }

  /// Upload de múltiplas fotos de avaliação
  static Future<List<String>> uploadReviewPhotos(List<File> imageFiles, String reviewId) async {
    try {
      final List<String> photoUrls = [];
      
      for (int i = 0; i < imageFiles.length; i++) {
        final photoUrl = await uploadReviewPhoto(imageFiles[i], reviewId, i);
        photoUrls.add(photoUrl);
      }
      
      debugPrint('✅ ${photoUrls.length} foto(s) da avaliação enviada(s)');
      return photoUrls;
    } catch (e) {
      debugPrint('❌ Erro ao fazer upload das fotos da avaliação: $e');
      rethrow;
    }
  }

  /// Deleta imagem do Storage
  static Future<void> deleteImage(String imageUrl) async {
    try {
      final ref = _storage.refFromURL(imageUrl);
      await ref.delete();
      debugPrint('✅ Imagem deletada: $imageUrl');
    } catch (e) {
      debugPrint('❌ Erro ao deletar imagem: $e');
      // Não relança erro - pode ser que a imagem já não exista
    }
  }

  // ============ ESTATÍSTICAS ============

  /// Calcula média de avaliações de um estabelecimento
  static Future<double> getAverageRating(String establishmentId) async {
    try {
      final reviews = await getReviewsForEstablishment(establishmentId);
      
      if (reviews.isEmpty) {
        return 0.0;
      }

      final sum = reviews.fold(0.0, (sum, review) => sum + review.rating);
      return sum / reviews.length;
    } catch (e) {
      debugPrint('❌ Erro ao calcular média: $e');
      return 0.0;
    }
  }

  /// Conta quantos check-ins existem para um determinado estabelecimento
  static Future<int> getCheckInCountForEstablishment(String establishmentId) async {
    try {
      final snapshot = await _firestore
          .collection('checkins')
          .where('establishmentId', isEqualTo: establishmentId)
          .get();
      return snapshot.size;
    } catch (e) {
      debugPrint('❌ Erro ao buscar contagem de check-ins para estabelecimento $establishmentId: $e');
      return 0;
    }
  }

  /// Registra um clique em um estabelecimento, diferenciando origem orgânica vs patrocinada.
  /// Mantém o campo agregado `clickCount` para compatibilidade.
  static Future<void> registerEstablishmentClick(
    String establishmentId, {
    bool isSponsored = false,
  }) async {
    try {
      final ref = _firestore.collection('establishmentStats').doc(establishmentId);

      final updates = <String, dynamic>{
        'establishmentId': establishmentId,
        'clickCount': FieldValue.increment(1),
      };

      if (isSponsored) {
        updates['sponsoredClickCount'] = FieldValue.increment(1);
      } else {
        updates['organicClickCount'] = FieldValue.increment(1);
      }

      await ref.set(updates, SetOptions(merge: true));
      debugPrint('✅ Clique registrado para estabelecimento $establishmentId (patrocinado=$isSponsored)');
    } catch (e) {
      debugPrint('❌ Erro ao registrar clique para estabelecimento $establishmentId: $e');
    }
  }

  static Future<Map<String, int>> _getClickStatsForEstablishment(
      String establishmentId) async {
    try {
      final doc =
          await _firestore.collection('establishmentStats').doc(establishmentId).get();
      if (!doc.exists || doc.data() == null) {
        return {
          'clicks': 0,
          'organicClicks': 0,
          'sponsoredClicks': 0,
        };
      }

      final data = doc.data() as Map<String, dynamic>;

      int totalClicks = 0;
      final totalValue = data['clickCount'];
      if (totalValue is int) totalClicks = totalValue;
      if (totalValue is num) totalClicks = totalValue.toInt();

      int organicClicks = 0;
      final organicValue = data['organicClickCount'];
      if (organicValue is int) organicClicks = organicValue;
      if (organicValue is num) organicClicks = organicValue.toInt();

      int sponsoredClicks = 0;
      final sponsoredValue = data['sponsoredClickCount'];
      if (sponsoredValue is int) sponsoredClicks = sponsoredValue;
      if (sponsoredValue is num) sponsoredClicks = sponsoredValue.toInt();

      if (totalClicks == 0 && (organicClicks + sponsoredClicks) > 0) {
        totalClicks = organicClicks + sponsoredClicks;
      }

      return {
        'clicks': totalClicks,
        'organicClicks': organicClicks,
        'sponsoredClicks': sponsoredClicks,
      };
    } catch (e) {
      debugPrint(
          '❌ Erro ao buscar estatísticas de cliques para estabelecimento $establishmentId: $e');
      return {
        'clicks': 0,
        'organicClicks': 0,
        'sponsoredClicks': 0,
      };
    }
  }

  static Future<int> getClickCountForEstablishment(String establishmentId) async {
    try {
      final stats = await _getClickStatsForEstablishment(establishmentId);
      return stats['clicks'] ?? 0;
    } catch (e) {
      debugPrint('❌ Erro ao buscar contagem de cliques para estabelecimento $establishmentId: $e');
      return 0;
    }
  }

  static Future<Map<String, int>> getEstablishmentActivityStats(
      String establishmentId) async {
    try {
      final checkIns = await getCheckInCountForEstablishment(establishmentId);
      final clickStats = await _getClickStatsForEstablishment(establishmentId);

      return {
        'checkIns': checkIns,
        'clicks': clickStats['clicks'] ?? 0,
        'organicClicks': clickStats['organicClicks'] ?? 0,
        'sponsoredClicks': clickStats['sponsoredClicks'] ?? 0,
      };
    } catch (e) {
      debugPrint(
          '❌ Erro ao buscar estatísticas de atividade para estabelecimento $establishmentId: $e');
      return {
        'checkIns': 0,
        'clicks': 0,
        'organicClicks': 0,
        'sponsoredClicks': 0,
      };
    }
  }

  // ============ USUÁRIOS ============

  /// Salva ou atualiza dados do usuário no Firestore
  static Future<void> saveUserData(User user) async {
    try {
      final userData = user.toJson();
      debugPrint('💾 Salvando dados do usuário no Firestore: ${user.id}');
      debugPrint('📋 Dados: ${userData.keys.join(", ")}');
      
      await _firestore
          .collection('users')
          .doc(user.id)
          .set(userData, SetOptions(merge: true))
          .timeout(const Duration(seconds: 10));
      debugPrint('✅ Dados do usuário salvos com sucesso: ${user.id}');
    } catch (e) {
      debugPrint('❌ Erro ao salvar dados do usuário: $e');
      debugPrint('Stack trace: ${StackTrace.current}');
      // Não relançar erro para não bloquear o login
      // O erro será tratado pelo chamador
    }
  }

  /// Atualiza estatísticas do usuário
  static Future<void> updateUserStats(
    String userId, {
    int? reviewsIncrement,
    int? checkInsIncrement,
    int? referralsIncrement,
  }) async {
    try {
      final updates = <String, dynamic>{};
      
      if (reviewsIncrement != null) {
        updates['totalReviews'] = FieldValue.increment(reviewsIncrement);
      }
      if (checkInsIncrement != null) {
        updates['totalCheckIns'] = FieldValue.increment(checkInsIncrement);
      }
      if (referralsIncrement != null) {
        updates['totalReferrals'] = FieldValue.increment(referralsIncrement);
      }
      
      if (updates.isNotEmpty) {
        await _firestore.collection('users').doc(userId).update(updates);
        debugPrint('✅ Estatísticas do usuário atualizadas: $userId');
      }
    } catch (e) {
      debugPrint('❌ Erro ao atualizar estatísticas do usuário: $e');
      // Não relançar erro para não bloquear operações
    }
  }

  /// Busca dados do usuário do Firestore
  static Future<User?> getUserData(String userId) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .get()
          .timeout(const Duration(seconds: 5));
      
      if (doc.exists && doc.data() != null) {
        final data = doc.data() as Map<String, dynamic>;
        // Garantir que o ID do documento seja usado (pode não estar no data)
        data['id'] = doc.id;
        // Converter Timestamps do Firestore para formato compatível
        final convertedData = _convertFirestoreData(data);
        return User.fromJson(convertedData);
      }
      return null;
    } catch (e) {
      debugPrint('❌ Erro ao buscar dados do usuário: $e');
      // Retornar null em caso de erro (não bloquear login)
      return null;
    }
  }

  /// Busca os principais avaliadores (Top Avaliadores) ordenados por totalReviews
  static Future<List<User>> getTopUsers({int limit = 20}) async {
    try {
      Query query = _firestore.collection('users').where('type', isEqualTo: 'user');

      QuerySnapshot snapshot;
      try {
        snapshot = await query
            .orderBy('totalReviews', descending: true)
            .limit(limit)
            .get();
      } catch (e) {
        debugPrint('⚠️ Erro ao ordenar por totalReviews em users (tentando sem filtro type): $e');
        snapshot = await _firestore
            .collection('users')
            .orderBy('totalReviews', descending: true)
            .limit(limit)
            .get();
      }

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        final convertedData = _convertFirestoreData(data);
        return User.fromJson(convertedData);
      }).toList();
    } catch (e) {
      debugPrint('❌ Erro ao buscar Top usuários: $e');
      return [];
    }
  }

  // ============ SEGUIDORES (FOLLOWERS) ============

  /// Verifica se currentUserId já segue targetUserId
  static Future<bool> isFollowing(String currentUserId, String targetUserId) async {
    try {
      if (currentUserId == targetUserId) return false;

      final followDocId = '${currentUserId}_$targetUserId';
      final doc = await _firestore
          .collection('userFollows')
          .doc(followDocId)
          .get()
          .timeout(const Duration(seconds: 5));

      return doc.exists;
    } catch (e) {
      debugPrint('❌ Erro ao verificar follow: $e');
      return false;
    }
  }

  /// Faz com que currentUserId passe a seguir targetUserId (idempotente)
  static Future<void> followUser({
    required String currentUserId,
    required String targetUserId,
  }) async {
    try {
      if (currentUserId == targetUserId) {
        debugPrint('⚠️ Usuário tentou seguir a si mesmo. Ignorando.');
        return;
      }

      final followDocId = '${currentUserId}_$targetUserId';
      final followRef = _firestore.collection('userFollows').doc(followDocId);
      final followerUserRef = _firestore.collection('users').doc(currentUserId);
      final targetUserRef = _firestore.collection('users').doc(targetUserId);

      await _firestore.runTransaction((tx) async {
        final followSnap = await tx.get(followRef);
        if (followSnap.exists) {
          // Já segue - garantir idempotência
          return;
        }

        tx.set(followRef, {
          'followerId': currentUserId,
          'targetUserId': targetUserId,
          'createdAt': FieldValue.serverTimestamp(),
        });

        tx.update(targetUserRef, {
          'followersCount': FieldValue.increment(1),
        });
        tx.update(followerUserRef, {
          'followingCount': FieldValue.increment(1),
        });
      });

      debugPrint('✅ $currentUserId agora segue $targetUserId');

      // Registrar notificação simples de novo seguidor (in-app)
      try {
        final followerSnap = await followerUserRef.get();
        final targetSnap = await targetUserRef.get();

        String followerName = 'Alguém';
        if (followerSnap.exists && followerSnap.data() != null) {
          final data = followerSnap.data() as Map<String, dynamic>;
          final rawName = (data['name'] as String?)?.trim();
          if (rawName != null && rawName.isNotEmpty) {
            followerName = rawName;
          } else {
            final email = (data['email'] as String?)?.trim();
            if (email != null && email.isNotEmpty) {
              followerName = email;
            }
          }
        }

        String languageCode = 'pt';
        if (targetSnap.exists && targetSnap.data() != null) {
          final targetData = targetSnap.data() as Map<String, dynamic>;
          final rawLang = (targetData['preferredLanguage'] as String?)?.trim();
          if (rawLang != null && rawLang.isNotEmpty) {
            languageCode = rawLang;
          }
        }

        String title;
        String message;
        if (languageCode == 'es') {
          title = 'Nuevo seguidor';
          message = '$followerName comenzó a seguirte en Prato Seguro.';
        } else if (languageCode == 'en') {
          title = 'New follower';
          message = '$followerName started following you on Prato Seguro.';
        } else {
          title = 'Novo seguidor';
          message = '$followerName começou a te seguir no Prato Seguro.';
        }

        await _firestore.collection('notifications').add({
          'userId': targetUserId,
          'type': 'new_follower',
          'title': title,
          'message': message,
          'followerId': currentUserId,
          'followerName': followerName,
          'createdAt': FieldValue.serverTimestamp(),
          'read': false,
          'source': 'app',
        });
        debugPrint('✅ Notificação de novo seguidor registrada para $targetUserId');
      } catch (e) {
        debugPrint('⚠️ Erro ao registrar notificação de novo seguidor: $e');
      }
    } catch (e) {
      debugPrint('❌ Erro ao seguir usuário: $e');
      rethrow;
    }
  }

  /// Faz com que currentUserId deixe de seguir targetUserId (idempotente)
  static Future<void> unfollowUser({
    required String currentUserId,
    required String targetUserId,
  }) async {
    try {
      if (currentUserId == targetUserId) {
        debugPrint('⚠️ Usuário tentou deixar de seguir a si mesmo. Ignorando.');
        return;
      }

      final followDocId = '${currentUserId}_$targetUserId';
      final followRef = _firestore.collection('userFollows').doc(followDocId);
      final followerUserRef = _firestore.collection('users').doc(currentUserId);
      final targetUserRef = _firestore.collection('users').doc(targetUserId);

      await _firestore.runTransaction((tx) async {
        final followSnap = await tx.get(followRef);
        if (!followSnap.exists) {
          // Já não segue - garantir idempotência
          return;
        }

        tx.delete(followRef);

        tx.update(targetUserRef, {
          'followersCount': FieldValue.increment(-1),
        });
        tx.update(followerUserRef, {
          'followingCount': FieldValue.increment(-1),
        });
      });

      debugPrint('✅ $currentUserId deixou de seguir $targetUserId');
    } catch (e) {
      debugPrint('❌ Erro ao deixar de seguir usuário: $e');
      rethrow;
    }
  }

  /// Deleta todos os dados do usuário do Firestore
  static Future<void> deleteUserData(String userId) async {
    try {
      // Deletar documento do usuário
      await _firestore.collection('users').doc(userId).delete();
      debugPrint('✅ Dados do usuário $userId deletados do Firestore');
    } catch (e) {
      debugPrint('❌ Erro ao deletar dados do usuário: $e');
      rethrow;
    }
  }

  /// Lista seguidores de um usuário (quem segue userId)
  static Future<List<User>> getFollowers(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('userFollows')
          .where('targetUserId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get()
          .timeout(const Duration(seconds: 10));

      if (querySnapshot.docs.isEmpty) {
        return [];
      }

      final followerIds = querySnapshot.docs
          .map((doc) => doc.data()['followerId'] as String?)
          .where((id) => id != null)
          .cast<String>()
          .toSet()
          .toList();

      if (followerIds.isEmpty) {
        return [];
      }

      final futures = followerIds.map((id) => _firestore.collection('users').doc(id).get());
      final docs = await Future.wait(futures);

      final users = <User>[];
      for (final doc in docs) {
        if (!doc.exists || doc.data() == null) continue;
        final rawData = doc.data() as Map<String, dynamic>;
        rawData['id'] = doc.id;
        final convertedData = _convertFirestoreData(rawData);
        users.add(User.fromJson(convertedData));
      }

      debugPrint('✅ getFollowers: ${users.length} seguidores carregados para $userId');
      return users;
    } catch (e) {
      debugPrint('❌ Erro ao buscar seguidores: $e');
      return [];
    }
  }

  /// Lista perfis que o usuário segue (quem é seguido por userId)
  static Future<List<User>> getFollowing(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('userFollows')
          .where('followerId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get()
          .timeout(const Duration(seconds: 10));

      if (querySnapshot.docs.isEmpty) {
        return [];
      }

      final targetIds = querySnapshot.docs
          .map((doc) => doc.data()['targetUserId'] as String?)
          .where((id) => id != null)
          .cast<String>()
          .toSet()
          .toList();

      if (targetIds.isEmpty) {
        return [];
      }

      final futures = targetIds.map((id) => _firestore.collection('users').doc(id).get());
      final docs = await Future.wait(futures);

      final users = <User>[];
      for (final doc in docs) {
        if (!doc.exists || doc.data() == null) continue;
        final rawData = doc.data() as Map<String, dynamic>;
        rawData['id'] = doc.id;
        final convertedData = _convertFirestoreData(rawData);
        users.add(User.fromJson(convertedData));
      }

      debugPrint('✅ getFollowing: ${users.length} perfis seguidos carregados para $userId');
      return users;
    } catch (e) {
      debugPrint('❌ Erro ao buscar perfis seguidos: $e');
      return [];
    }
  }

  /// Atualiza apenas o idioma preferido do usuário
  static Future<void> updateUserPreferredLanguage(String userId, String languageCode) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .update({'preferredLanguage': languageCode})
          .timeout(const Duration(seconds: 5));
      debugPrint('✅ Idioma preferido atualizado: $languageCode');
    } catch (e) {
      debugPrint('❌ Erro ao atualizar idioma preferido: $e');
      // Não relançar erro para não bloquear a atualização
    }
  }

  // ============ TRILHAS (Registre sua Trilha) ============

  static Future<void> saveTrailRecord(TrailRecord trail) async {
    try {
      await _firestore
          .collection('trails')
          .doc(trail.id)
          .set(trail.toJson());
      debugPrint('✅ Trilha salva: ${trail.id}');
    } catch (e) {
      debugPrint('❌ Erro ao salvar trilha: $e');
      rethrow;
    }
  }

  static Future<List<TrailRecord>> getUserTrailRecords(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('trails')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return TrailRecord.fromJson(data);
      }).toList();
    } catch (e) {
      debugPrint('❌ Erro ao buscar trilhas: $e');
      return [];
    }
  }

  static Future<List<String>> uploadTrailPhotos(
    List<File> imageFiles,
    String userId,
    String trailId,
  ) async {
    try {
      final folder = 'safeplate/trails/$userId/$trailId';
      final photoUrls = await CloudinaryService.uploadImages(
        imageFiles,
        folder: folder,
        namePrefix: 'photo',
      );

      debugPrint('✅ ${photoUrls.length} foto(s) da trilha enviada(s)');
      return photoUrls;
    } catch (e) {
      debugPrint('❌ Erro ao enviar fotos da trilha: $e');
      rethrow;
    }
  }

  /// Salva um novo local da trilha como indicação (referral) com origem 'trilha'
  /// Retorna o ID do referral criado
  static Future<String> saveTrailAsReferral({
    required String userId,
    required String name,
    required String category,
    required double latitude,
    required double longitude,
    String? address,
    String? phone,
    required List<DietaryFilter> dietaryOptions,
    String? comment,
    List<String>? photoUrls,
  }) async {
    try {
      final referral = {
        'userId': userId,
        'establishmentName': name,
        'establishmentCategory': category,
        'latitude': latitude,
        'longitude': longitude,
        'address': address,
        'phone': phone,
        'dietaryOptions': dietaryOptions.map((f) => f.toString().split('.').last).toList(),
        'notes': comment,
        'photoUrls': photoUrls ?? [],
        'status': 'pending', // pending, approved, rejected
        'origem': 'trilha', // Diferencia de indicação normal
        'createdAt': FieldValue.serverTimestamp(),
      };

      final docRef = await _firestore.collection('referrals').add(referral);
      debugPrint('✅ Trilha salva como indicação (origem: trilha): $name - ID: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      debugPrint('❌ Erro ao salvar trilha como indicação: $e');
      rethrow;
    }
  }

  /// Salva uma sugestão de estabelecimento feita pelo usuário
  static Future<String> saveSuggestion(Map<String, dynamic> suggestion) async {
    try {
      suggestion['createdAt'] = FieldValue.serverTimestamp();
      final docRef = await _firestore.collection('suggestions').add(suggestion);
      debugPrint('✅ Sugestão salva: ${suggestion['name']} - ID: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      debugPrint('❌ Erro ao salvar sugestão: $e');
      rethrow;
    }
  }

  // ==================== TRIPS (ITINERÁRIOS) ====================

  /// Busca todas as viagens de um usuário
  static Future<List<Trip>> getUserTrips(String userId) async {
    try {
      debugPrint('🔍 Buscando viagens para userId: $userId');
      
      // Query simples sem orderBy para evitar necessidade de índice composto
      final snapshot = await _firestore
          .collection('trips')
          .where('userId', isEqualTo: userId)
          .get();
      
      debugPrint('📋 Encontradas ${snapshot.docs.length} viagens');
      
      final trips = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return Trip.fromJson(data);
      }).toList();
      
      // Ordenar localmente por startDate
      trips.sort((a, b) => a.startDate.compareTo(b.startDate));
      
      return trips;
    } catch (e) {
      debugPrint('❌ Erro ao buscar viagens: $e');
      return [];
    }
  }

  /// Salva ou atualiza uma viagem
  static Future<void> saveTrip(Trip trip) async {
    try {
      final data = trip.toJson();
      data['updatedAt'] = FieldValue.serverTimestamp();
      
      await _firestore.collection('trips').doc(trip.id).set(data);
      debugPrint('✅ Viagem salva: ${trip.name}');
    } catch (e) {
      debugPrint('❌ Erro ao salvar viagem: $e');
      rethrow;
    }
  }

  /// Busca uma viagem por ID
  static Future<Trip?> getTripById(String tripId) async {
    try {
      final doc = await _firestore.collection('trips').doc(tripId).get();
      if (!doc.exists) return null;
      
      final data = doc.data();
      if (data == null) return null;
      
      data['id'] = doc.id;
      return Trip.fromJson(data);
    } catch (e) {
      debugPrint('❌ Erro ao buscar viagem: $e');
      return null;
    }
  }

  /// Exclui uma viagem
  static Future<void> deleteTrip(String tripId) async {
    try {
      await _firestore.collection('trips').doc(tripId).delete();
      debugPrint('✅ Viagem excluída: $tripId');
    } catch (e) {
      debugPrint('❌ Erro ao excluir viagem: $e');
      rethrow;
    }
  }

  /// Atualiza o status de uma viagem
  static Future<void> updateTripStatus(String tripId, TripStatus status) async {
    try {
      await _firestore.collection('trips').doc(tripId).update({
        'status': status.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      debugPrint('✅ Status da viagem atualizado: $tripId -> ${status.name}');
    } catch (e) {
      debugPrint('❌ Erro ao atualizar status da viagem: $e');
      rethrow;
    }
  }
}

