import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/user.dart';
import '../models/establishment.dart';
import 'firebase_service.dart';

class NotificationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static String? _fcmToken;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  static bool _localInitialized = false;
  static String? _currentUserId;

  /// Envia notificação para todos os usuários sobre novo estabelecimento certificado
  static Future<void> notifyNewCertifiedEstablishment(Establishment establishment) async {
    try {
      // Buscar todos os usuários
      final users = await _firestore.collection('users').get();

      // Criar notificação para cada usuário
      for (final userDoc in users.docs) {
        await _firestore.collection('notifications').add({
          'userId': userDoc.id,
          'type': 'new_certified_establishment',
          'title': 'Novo estabelecimento certificado!',
          'message': '${establishment.name} foi certificado e está disponível para você.',
          'establishmentId': establishment.id,
          'establishmentName': establishment.name,
          'createdAt': FieldValue.serverTimestamp(),
          'read': false,
        });
      }

      debugPrint('✅ Notificações enviadas para ${users.docs.length} usuários');
    } catch (e) {
      debugPrint('❌ Erro ao enviar notificações: $e');
    }
  }

  /// Envia notificação sobre progresso do selo
  static Future<void> notifySealProgress(String userId, String message) async {
    try {
      await _firestore.collection('notifications').add({
        'userId': userId,
        'type': 'seal_progress',
        'title': 'Progresso do Selo',
        'message': message,
        'createdAt': FieldValue.serverTimestamp(),
        'read': false,
      });
      debugPrint('✅ Notificação de progresso enviada');
    } catch (e) {
      debugPrint('❌ Erro ao enviar notificação de progresso: $e');
    }
  }

  /// Envia notificação sobre cupom disponível
  static Future<void> notifyCouponAvailable(String userId, String couponTitle, String message) async {
    try {
      await _firestore.collection('notifications').add({
        'userId': userId,
        'type': 'coupon_available',
        'title': 'Cupom Disponível!',
        'message': message,
        'couponTitle': couponTitle,
        'createdAt': FieldValue.serverTimestamp(),
        'read': false,
      });
      debugPrint('✅ Notificação de cupom enviada');
    } catch (e) {
      debugPrint('❌ Erro ao enviar notificação de cupom: $e');
    }
  }

  /// Busca notificações do usuário
  static Future<List<Map<String, dynamic>>> getUserNotifications(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .get();

      final notifications = querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();

      // Ordenar por createdAt (mais recentes primeiro) no cliente
      notifications.sort((a, b) {
        final aTs = a['createdAt'];
        final bTs = b['createdAt'];
        if (aTs is Timestamp && bTs is Timestamp) {
          return bTs.compareTo(aTs); // desc
        }
        return 0;
      });

      if (notifications.length > 50) {
        return notifications.sublist(0, 50);
      }
      return notifications;
    } catch (e) {
      debugPrint('❌ Erro ao buscar notificações: $e');
      return [];
    }
  }

  /// Marca notificação como lida
  static Future<void> markAsRead(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).update({
        'read': true,
      });
    } catch (e) {
      debugPrint('❌ Erro ao marcar notificação como lida: $e');
    }
  }

  /// Inicializa Firebase Cloud Messaging e registra token
  static Future<void> initialize(String userId) async {
    try {
      _currentUserId = userId;
      // Solicitar permissão para notificações (Push)
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      // Solicitar permissão para notificações locais (Android 13+ e iOS)
      await requestLocalPermissions();

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        debugPrint('✅ Permissão de notificação concedida');
      } else {
        debugPrint('⚠️ Permissão de notificação negada');
        return;
      }

      // Obter token FCM
      _fcmToken = await _messaging.getToken();
      if (_fcmToken != null) {
        debugPrint('✅ FCM Token obtido: $_fcmToken');
        
        // Salvar token no Firestore
        await _firestore.collection('users').doc(userId).update({
          'fcmToken': _fcmToken,
          'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
        });
        debugPrint('✅ FCM Token salvo no Firestore');
      }

      // Configurar handlers para notificações em foreground
      FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
        debugPrint('📢 Notificação recebida (foreground): ${message.notification?.title}');
        await _handleRemoteMessage(message, showLocal: true);
      });

      // Handler para quando o app é aberto a partir de uma notificação
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) async {
        debugPrint('📢 App aberto a partir de notificação: ${message.notification?.title}');
        await _handleRemoteMessage(message, showLocal: false);
        // Navegar para a tela apropriada baseado no tipo de notificação (futuro)
      });

      // Verificar se o app foi aberto a partir de uma notificação (quando estava fechado)
      RemoteMessage? initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        debugPrint('📢 App aberto a partir de notificação (inicial): ${initialMessage.notification?.title}');
        await _handleRemoteMessage(initialMessage, showLocal: false);
      }
    } catch (e) {
      debugPrint('❌ Erro ao inicializar FCM: $e');
    }
  }

  /// Atualiza o token FCM do usuário
  static Future<void> updateFcmToken(String userId) async {
    try {
      _fcmToken = await _messaging.getToken();
      if (_fcmToken != null) {
        await _firestore.collection('users').doc(userId).update({
          'fcmToken': _fcmToken,
          'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
        });
        debugPrint('✅ FCM Token atualizado');
      }
    } catch (e) {
      debugPrint('❌ Erro ao atualizar FCM token: $e');
    }
  }

  /// Remove o token FCM do usuário (logout)
  static Future<void> removeFcmToken(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'fcmToken': FieldValue.delete(),
      });
      await _messaging.deleteToken();
      _fcmToken = null;
      debugPrint('✅ FCM Token removido');
    } catch (e) {
      debugPrint('❌ Erro ao remover FCM token: $e');
    }
  }

  static Future<void> initializeLocalNotifications({bool requestPermission = false}) async {
    if (_localInitialized) return;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(initSettings);
    _localInitialized = true;

    if (requestPermission) {
      await requestLocalPermissions();
    }
  }

  static Future<void> requestLocalPermissions() async {
    final androidPlugin =
        _localNotifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.requestNotificationsPermission();

    final iosPlugin =
        _localNotifications.resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();
    await iosPlugin?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  static Future<void> showLocalNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    try {
      if (!_localInitialized) {
        await initializeLocalNotifications();
      }

      const androidDetails = AndroidNotificationDetails(
        'nearby_safe_places',
        'Locais seguros próximos',
        channelDescription:
            'Alertas quando você está perto de um local seguro',
        importance: Importance.high,
        priority: Priority.high,
      );
      const iosDetails = DarwinNotificationDetails();
      const details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _localNotifications.show(
        id,
        title,
        body,
        details,
      );
    } catch (e) {
      debugPrint('Erro ao exibir notificação local: $e');
    }
  }

  static Future<void> showLocalNotificationAndSave({
    required int id,
    required String title,
    required String body,
    String type = 'local_alert',
  }) async {
    await showLocalNotification(id: id, title: title, body: body);

    try {
      final userId = _currentUserId;
      if (userId == null) return;

      await _firestore.collection('notifications').add({
        'userId': userId,
        'type': type,
        'title': title,
        'message': body,
        'createdAt': FieldValue.serverTimestamp(),
        'read': false,
        'source': 'app_local',
      });
    } catch (e) {
      debugPrint('❌ Erro ao salvar notificação local em Firestore: $e');
    }
  }

  static Future<void> _handleRemoteMessage(RemoteMessage message, {required bool showLocal}) async {
    try {
      final userId = _currentUserId;
      if (userId == null) return;

      final notification = message.notification;
      final data = message.data;

      final title = notification?.title ?? (data['title'] as String? ?? '');
      final body = notification?.body ?? (data['body'] as String? ?? '');
      final type = (data['type'] as String?) ?? 'push';

      await _firestore.collection('notifications').add({
        'userId': userId,
        'type': type,
        'title': title,
        'message': body,
        'data': data,
        'createdAt': FieldValue.serverTimestamp(),
        'read': false,
      });

      if (showLocal && title.isNotEmpty && body.isNotEmpty) {
        await showLocalNotification(
          id: message.messageId?.hashCode ?? DateTime.now().millisecondsSinceEpoch ~/ 1000,
          title: title,
          body: body,
        );
      }
    } catch (e) {
      debugPrint('❌ Erro ao processar RemoteMessage: $e');
    }
  }
}
