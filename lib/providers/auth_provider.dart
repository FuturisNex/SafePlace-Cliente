import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import '../models/user.dart' as model;
import '../models/user_seal.dart';
import '../services/firebase_service.dart';
import '../services/notification_service.dart';
import '../config.dart';

class AuthProvider with ChangeNotifier {
  model.User? _user;
  UserCredential? _firebaseUser;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isInitialized = false;
  Completer<void>? _initCompleter;

  model.User? get user => _user;
  bool get isAuthenticated => _user != null;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  UserCredential? get firebaseUser => _firebaseUser;
  bool get isInitialized => _isInitialized;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  GoogleSignIn? _googleSignIn;
  bool _isGoogleSignInInitialized = false;

  AuthProvider() {
    debugPrint('🟢 [DEBUG] AuthProvider inicializado. kForcedUserType=$kForcedUserType');
    _checkAuthState();
  }

  Future<bool> _enforceAppAccountType({String? origin}) async {
    if (_user == null) return false;
    if (_user!.type == kForcedUserType) return false;

    debugPrint(
        '⚠️ Conta incompatível detectada${origin == null ? '' : ' ($origin)'}: '
        'userType=${_user!.type.toString().split('.').last}, '
        'appType=${kForcedUserType.toString().split('.').last}');

    _errorMessage =
        'Esta conta é do tipo "${_user!.type == model.UserType.business ? 'business' : 'user'}" '
        'e não é compatível com esta variante do app.';

    await logout();
    return true;
  }

  /// Aguarda a inicialização do AuthProvider (carregamento do estado de autenticação)
  Future<void> waitForInitialization() async {
    if (_isInitialized) return;
    _initCompleter ??= Completer<void>();
    return _initCompleter!.future;
  }

  GoogleSignIn get googleSignIn {
    _googleSignIn ??= GoogleSignIn.instance;
    return _googleSignIn!;
  }

  Future<void> updateProfilePhoto(String photoUrl) async {
    if (_user == null) return;

    try {
      _user = model.User(
        id: _user!.id,
        email: _user!.email,
        name: _user!.name,
        type: _user!.type,
        photoUrl: photoUrl,
        coverPhotoUrl: _user!.coverPhotoUrl,
        preferredLanguage: _user!.preferredLanguage,
        phone: _user!.phone,
        points: _user!.points,
        seal: _user!.seal,
        totalCheckIns: _user!.totalCheckIns,
        totalReviews: _user!.totalReviews,
        totalReferrals: _user!.totalReferrals,
        followersCount: _user!.followersCount,
        followingCount: _user!.followingCount,
        dietaryPreferences: _user!.dietaryPreferences,
        createdAt: _user!.createdAt,
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user', json.encode(_user!.toJson()));

      await FirebaseService.saveUserData(_user!);

      notifyListeners();
    } catch (e) {
      debugPrint('❌ Erro ao atualizar foto de perfil: $e');
    }
  }

  Future<void> updateCoverPhoto(String coverPhotoUrl) async {
    if (_user == null) return;

    try {
      _user = model.User(
        id: _user!.id,
        email: _user!.email,
        name: _user!.name,
        type: _user!.type,
        photoUrl: _user!.photoUrl,
        coverPhotoUrl: coverPhotoUrl,
        preferredLanguage: _user!.preferredLanguage,
        phone: _user!.phone,
        points: _user!.points,
        seal: _user!.seal,
        totalCheckIns: _user!.totalCheckIns,
        totalReviews: _user!.totalReviews,
        totalReferrals: _user!.totalReferrals,
        followersCount: _user!.followersCount,
        followingCount: _user!.followingCount,
        dietaryPreferences: _user!.dietaryPreferences,
        createdAt: _user!.createdAt,
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user', json.encode(_user!.toJson()));

      await FirebaseService.saveUserData(_user!);

      notifyListeners();
    } catch (e) {
      debugPrint('❌ Erro ao atualizar capa do perfil: $e');
    }
  }

  Future<void> updatePhone(String phone) async {
    if (_user == null) return;

    try {
      _user = model.User(
        id: _user!.id,
        email: _user!.email,
        name: _user!.name,
        type: _user!.type,
        photoUrl: _user!.photoUrl,
        coverPhotoUrl: _user!.coverPhotoUrl,
        preferredLanguage: _user!.preferredLanguage,
        phone: phone,
        points: _user!.points,
        seal: _user!.seal,
        totalCheckIns: _user!.totalCheckIns,
        totalReviews: _user!.totalReviews,
        totalReferrals: _user!.totalReferrals,
        followersCount: _user!.followersCount,
        followingCount: _user!.followingCount,
        dietaryPreferences: _user!.dietaryPreferences,
        createdAt: _user!.createdAt,
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user', json.encode(_user!.toJson()));

      await FirebaseService.saveUserData(_user!);

      notifyListeners();
    } catch (e) {
      debugPrint('❌ Erro ao atualizar telefone do usuário: $e');
    }
  }

  Future<void> _checkAuthState() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser != null) {
        debugPrint('🔐 Firebase Auth: usuário autenticado (${currentUser.uid})');
        // Carregar dados locais primeiro para não travar
        await _loadUser();
        final mismatchLocal = await _enforceAppAccountType(origin: 'cache');
        if (mismatchLocal) return;
        // Depois tentar atualizar do Firestore (sem bloquear)
        _loadUserFromFirebase(currentUser).then((_) async {
          final mismatchRemote = await _enforceAppAccountType(origin: 'firestore');
          if (mismatchRemote) return;
          // Inicializar notificações push após carregar usuário
          if (_user != null) {
            NotificationService.initialize(_user!.id).catchError((e) {
              debugPrint('⚠️ Erro ao inicializar notificações: $e');
            });
          }
        }).catchError((e) {
          debugPrint('⚠️ Erro ao carregar do Firestore no _checkAuthState: $e');
        });
        // Aplicar idioma preferido após carregar usuário
        _applyPreferredLanguage();
      } else {
        debugPrint('🔐 Firebase Auth: nenhum usuário autenticado, tentando carregar do cache local');
        await _loadUser();
        await _enforceAppAccountType(origin: 'cache-no-firebase');
        _applyPreferredLanguage();
      }
    } catch (e) {
      debugPrint('Erro ao verificar estado de autenticação: $e');
    } finally {
      // Marcar como inicializado
      _isInitialized = true;
      if (_initCompleter != null && !_initCompleter!.isCompleted) {
        _initCompleter!.complete();
      }
      debugPrint('🔐 AuthProvider inicializado. isAuthenticated: $isAuthenticated');
      notifyListeners();
    }
  }

  void _applyPreferredLanguage() {
    if (_user?.preferredLanguage != null) {
      // Salvar no SharedPreferences para o LocaleProvider carregar
      SharedPreferences.getInstance().then((prefs) {
        prefs.setString('language', _user!.preferredLanguage!);
      });
    }
  }

  Future<void> _loadUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString('user');
      if (userJson != null) {
        _user = model.User.fromJson(json.decode(userJson));
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Erro ao carregar usuário: $e');
    }
  }

  Future<void> _loadUserFromFirebase(User firebaseUser, {String? preferredLanguage}) async {
    try {
      final userTypeString = await SharedPreferences.getInstance().then((prefs) {
        final storedType = prefs.getString('userType');
        if (storedType != null && storedType.isNotEmpty) {
          return storedType;
        }
        return kForcedUserType == model.UserType.business ? 'business' : 'user';
      });
      
      // Tentar carregar dados do Firestore primeiro (com timeout)
      final cachedPhone = _user?.phone;
      model.User? firestoreUser;
      try {
        firestoreUser = await FirebaseService.getUserData(firebaseUser.uid)
            .timeout(const Duration(seconds: 5), onTimeout: () {
          debugPrint('⚠️ Timeout ao carregar dados do Firestore');
          return null;
        });
      } catch (e) {
        debugPrint('⚠️ Erro ao carregar dados do Firestore: $e');
      }
      
      // Usar dados do Firestore se disponíveis, senão criar novo
      if (firestoreUser != null) {
        // Sempre forçar o tipo do usuário para o valor de kForcedUserType
        _user = model.User(
          id: firestoreUser.id,
          email: firestoreUser.email,
          name: firestoreUser.name,
          type: kForcedUserType,
          photoUrl: firestoreUser.photoUrl,
          coverPhotoUrl: firestoreUser.coverPhotoUrl,
          preferredLanguage: firestoreUser.preferredLanguage,
          phone: firestoreUser.phone,
          points: firestoreUser.points,
          seal: firestoreUser.seal,
          totalCheckIns: firestoreUser.totalCheckIns,
          totalReviews: firestoreUser.totalReviews,
          totalReferrals: firestoreUser.totalReferrals,
          followersCount: firestoreUser.followersCount,
          followingCount: firestoreUser.followingCount,
          dietaryPreferences: firestoreUser.dietaryPreferences,
          createdAt: firestoreUser.createdAt,
        );
        if ((_user!.phone == null || _user!.phone!.trim().isEmpty) &&
            cachedPhone != null &&
            cachedPhone.trim().isNotEmpty) {
          _user = model.User(
            id: _user!.id,
            email: _user!.email,
            name: _user!.name,
            type: _user!.type,
            photoUrl: _user!.photoUrl,
            coverPhotoUrl: _user!.coverPhotoUrl,
            preferredLanguage: _user!.preferredLanguage,
            phone: cachedPhone,
            points: _user!.points,
            seal: _user!.seal,
            totalCheckIns: _user!.totalCheckIns,
            totalReviews: _user!.totalReviews,
            totalReferrals: _user!.totalReferrals,
            followersCount: _user!.followersCount,
            followingCount: _user!.followingCount,
            dietaryPreferences: _user!.dietaryPreferences,
            createdAt: _user!.createdAt,
          );
        }
        if (preferredLanguage != null && preferredLanguage != _user!.preferredLanguage) {
          _user = model.User(
            id: _user!.id,
            email: _user!.email,
            name: _user!.name,
            type: _user!.type,
            photoUrl: _user!.photoUrl,
            coverPhotoUrl: _user!.coverPhotoUrl,
            preferredLanguage: preferredLanguage,
            phone: _user!.phone ?? cachedPhone,
            points: _user!.points,
            seal: _user!.seal,
            totalCheckIns: _user!.totalCheckIns,
            totalReviews: _user!.totalReviews,
            totalReferrals: _user!.totalReferrals,
            followersCount: _user!.followersCount,
            followingCount: _user!.followingCount,
            dietaryPreferences: _user!.dietaryPreferences,
            createdAt: _user!.createdAt,
          );
          FirebaseService.updateUserPreferredLanguage(_user!.id, preferredLanguage)
              .catchError((e) {
            debugPrint('⚠️ Erro ao atualizar idioma no Firestore: $e');
          });
        }
      } else {
        // Criar novo usuário apenas se não existir no Firestore
        final trialExpiresAt = DateTime.now().add(Duration(days: TRIAL_DAYS));
        final forcedType = kForcedUserType == model.UserType.user ? model.UserType.user : (userTypeString == 'business' ? model.UserType.business : model.UserType.user);
        debugPrint('🟡 [DEBUG] Criando novo usuário. id=${firebaseUser.uid}, type=$forcedType, userTypeString=$userTypeString, kForcedUserType=$kForcedUserType');
        _user = model.User(
          id: firebaseUser.uid,
          email: firebaseUser.email ?? '',
          name: firebaseUser.displayName,
          type: forcedType,
          photoUrl: firebaseUser.photoURL,
          coverPhotoUrl: null,
          preferredLanguage: preferredLanguage,
          // Dados de gamificação iniciados com valores padrão
          points: 0,
          seal: UserSeal.bronze,
          totalCheckIns: 0,
          totalReviews: 0,
          totalReferrals: 0,
        );
        // Salvar novo usuário no Firestore (sem bloquear login)
        debugPrint('💾 Salvando novo usuário no Firestore...');
        FirebaseService.saveUserData(_user!).timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            debugPrint('⚠️ Timeout ao salvar novo usuário no Firestore (continuando login)');
            return;
          },
        ).then((_) {
          debugPrint('✅ Novo usuário salvo no Firestore com sucesso');
        }).catchError((e) {
          debugPrint('⚠️ Erro ao salvar novo usuário no Firestore: $e');
        });
      }

      // Salvar localmente primeiro (não esperar Firestore)
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user', json.encode(_user!.toJson()));

      notifyListeners();
    } catch (e) {
      debugPrint('Erro ao carregar usuário do Firebase: $e');
      try {
        final userTypeString = await SharedPreferences.getInstance().then((prefs) {
          final storedType = prefs.getString('userType');
          if (storedType != null && storedType.isNotEmpty) {
            return storedType;
          }
          return kForcedUserType == model.UserType.business ? 'business' : 'user';
        });
        final trialExpiresAt = DateTime.now().add(Duration(days: TRIAL_DAYS));
        _user = model.User(
          id: firebaseUser.uid,
          email: firebaseUser.email ?? '',
          name: firebaseUser.displayName,
          type: userTypeString == 'business' ? model.UserType.business : model.UserType.user,
          photoUrl: firebaseUser.photoURL,
          coverPhotoUrl: null,
          preferredLanguage: preferredLanguage,
          // Dados de gamificação iniciados com valores padrão
          points: 0,
          seal: UserSeal.bronze,
          totalCheckIns: 0,
          totalReviews: 0,
          totalReferrals: 0,
        );
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user', json.encode(_user!.toJson()));
        notifyListeners();
      } catch (e2) {
        debugPrint('Erro crítico ao criar usuário: $e2');
      }
    }
  }

  Future<bool> login(String email, String password, model.UserType userType, {String? preferredLanguage}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      debugPrint('🔐 Tentando fazer login com email: ${email.trim()}');
      
      // Validar email antes de tentar login
      if (email.trim().isEmpty) {
        _isLoading = false;
        _errorMessage = 'Por favor, informe o email';
        notifyListeners();
        return false;
      }

      if (password.isEmpty) {
        _isLoading = false;
        _errorMessage = 'Por favor, informe a senha';
        notifyListeners();
        return false;
      }

      if (!email.trim().contains('@')) {
        _isLoading = false;
        _errorMessage = 'Por favor, informe um email válido';
        notifyListeners();
        return false;
      }

      // Fazer login com email e senha
      UserCredential credential;
      try {
        credential = await _auth.signInWithEmailAndPassword(
          email: email.trim(),
          password: password,
        ).timeout(
          const Duration(seconds: 30),
          onTimeout: () {
            throw TimeoutException('Tempo de conexão excedido. Verifique sua internet.');
          },
        );
      } catch (e) {
        // Se o erro for relacionado a PigeonUserDetails, é um bug do Google Sign In
        // que não deveria afetar login manual, mas vamos tratar
        if (e.toString().contains('PigeonUserDetails')) {
          debugPrint('⚠️ Erro PigeonUserDetails detectado (pode ser falso positivo): $e');
          // Tentar novamente sem timeout
          credential = await _auth.signInWithEmailAndPassword(
            email: email.trim(),
            password: password,
          );
        } else {
          rethrow;
        }
      }

      debugPrint('✅ Login Firebase bem-sucedido: ${credential.user?.uid}');

      if (credential.user != null) {
        _firebaseUser = credential;
        
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('userType', userType.toString().split('.').last);

        debugPrint('📥 Carregando dados do usuário do Firestore...');
        try {
          await _loadUserFromFirebase(credential.user!, preferredLanguage: preferredLanguage);
          debugPrint('✅ Dados do usuário carregados com sucesso');
        } catch (e) {
          debugPrint('⚠️ Erro ao carregar dados do Firestore, mas continuando login: $e');
          // Continuar mesmo com erro no Firestore
        }

        // Inicializar notificações push após login
        if (_user != null) {
          NotificationService.initialize(_user!.id).catchError((e) {
            debugPrint('⚠️ Erro ao inicializar notificações: $e');
          });
        }

        _isLoading = false;
        notifyListeners();
        debugPrint('✅ Login completo com sucesso');
        return true;
      }

      _isLoading = false;
      _errorMessage = 'Erro ao fazer login. Usuário não encontrado.';
      notifyListeners();
      return false;
    } on FirebaseAuthException catch (e) {
      _isLoading = false;
      debugPrint('❌ Erro Firebase Auth: ${e.code} - ${e.message}');
      _errorMessage = _getAuthErrorMessage(e.code);
      notifyListeners();
      return false;
    } on TimeoutException catch (e) {
      _isLoading = false;
      debugPrint('❌ Timeout no login: $e');
      _errorMessage = e.message ?? 'Tempo de conexão excedido. Verifique sua internet.';
      notifyListeners();
      return false;
    } catch (e, stackTrace) {
      _isLoading = false;
      debugPrint('❌ Erro inesperado no login: $e');
      debugPrint('Stack trace: $stackTrace');
      
      // Filtrar erros relacionados a PigeonUserDetails (bug do Google Sign In)
      String errorMessage = e.toString();
      if (errorMessage.contains('PigeonUserDetails')) {
        debugPrint('⚠️ Erro PigeonUserDetails detectado - pode ser bug do Google Sign In');
        // Se o usuário foi autenticado mesmo com o erro, continuar
        if (_auth.currentUser != null) {
          debugPrint('✅ Usuário autenticado apesar do erro PigeonUserDetails, continuando...');
          try {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('userType', userType.toString().split('.').last);
            await _loadUserFromFirebase(_auth.currentUser!, preferredLanguage: preferredLanguage);
            
            if (_user != null) {
              NotificationService.initialize(_user!.id).catchError((e) {
                debugPrint('⚠️ Erro ao inicializar notificações: $e');
              });
            }
            
            _isLoading = false;
            notifyListeners();
            return true;
          } catch (e2) {
            debugPrint('❌ Erro ao carregar usuário após PigeonUserDetails: $e2');
          }
        }
        errorMessage = 'Erro ao fazer login. Tente novamente ou use outro método de login.';
      } else {
        errorMessage = 'Erro ao fazer login: ${e.toString()}';
      }
      
      _errorMessage = errorMessage;
      notifyListeners();
      return false;
    }
  }

  Future<bool> signUp(String email, String password, model.UserType userType, String? name, {String? preferredLanguage}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      debugPrint('📝 Tentando criar conta com email: ${email.trim()}');
      
      // Validar email antes de tentar cadastro
      if (email.trim().isEmpty) {
        _isLoading = false;
        _errorMessage = 'Por favor, informe o email';
        notifyListeners();
        return false;
      }

      if (password.isEmpty) {
        _isLoading = false;
        _errorMessage = 'Por favor, informe a senha';
        notifyListeners();
        return false;
      }

      if (password.length < 6) {
        _isLoading = false;
        _errorMessage = 'A senha deve ter pelo menos 6 caracteres';
        notifyListeners();
        return false;
      }

      if (!email.trim().contains('@')) {
        _isLoading = false;
        _errorMessage = 'Por favor, informe um email válido';
        notifyListeners();
        return false;
      }

      // Criar conta com email e senha
      UserCredential credential;
      try {
        credential = await _auth.createUserWithEmailAndPassword(
          email: email.trim(),
          password: password,
        ).timeout(
          const Duration(seconds: 30),
          onTimeout: () {
            throw TimeoutException('Tempo de conexão excedido. Verifique sua internet.');
          },
        );
      } catch (e) {
        // Se o erro for relacionado a PigeonUserDetails, é um bug do Google Sign In
        // que não deveria afetar cadastro manual, mas vamos tratar
        if (e.toString().contains('PigeonUserDetails')) {
          debugPrint('⚠️ Erro PigeonUserDetails detectado (pode ser falso positivo): $e');
          // Tentar novamente sem timeout
          credential = await _auth.createUserWithEmailAndPassword(
            email: email.trim(),
            password: password,
          );
        } else {
          rethrow;
        }
      }

      debugPrint('✅ Cadastro Firebase bem-sucedido: ${credential.user?.uid}');

      if (credential.user != null) {
        // Atualizar perfil com nome se fornecido
        if (name != null && name.isNotEmpty) {
          try {
            await credential.user!.updateDisplayName(name);
            await credential.user!.reload();
            debugPrint('✅ Nome do usuário atualizado: $name');
          } catch (e) {
            debugPrint('⚠️ Erro ao atualizar nome do usuário: $e');
            // Continuar mesmo com erro ao atualizar nome
          }
        }

        _firebaseUser = credential;
        
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('userType', userType.toString().split('.').last);

        debugPrint('📥 Carregando dados do usuário do Firestore...');
        try {
          await _loadUserFromFirebase(credential.user!, preferredLanguage: preferredLanguage);
          debugPrint('✅ Dados do usuário carregados com sucesso');
        } catch (e) {
          debugPrint('⚠️ Erro ao carregar dados do Firestore, mas continuando cadastro: $e');
          // Continuar mesmo com erro no Firestore
        }

        // Inicializar notificações push após signup
        if (_user != null) {
          NotificationService.initialize(_user!.id).catchError((e) {
            debugPrint('⚠️ Erro ao inicializar notificações: $e');
          });
        }

        _isLoading = false;
        notifyListeners();
        debugPrint('✅ Cadastro completo com sucesso');
        return true;
      }

      _isLoading = false;
      _errorMessage = 'Erro ao criar conta. Usuário não foi criado.';
      notifyListeners();
      return false;
    } on FirebaseAuthException catch (e) {
      _isLoading = false;
      debugPrint('❌ Erro Firebase Auth: ${e.code} - ${e.message}');
      _errorMessage = _getAuthErrorMessage(e.code);
      notifyListeners();
      return false;
    } on TimeoutException catch (e) {
      _isLoading = false;
      debugPrint('❌ Timeout no cadastro: $e');
      _errorMessage = e.message ?? 'Tempo de conexão excedido. Verifique sua internet.';
      notifyListeners();
      return false;
    } catch (e, stackTrace) {
      _isLoading = false;
      debugPrint('❌ Erro inesperado no cadastro: $e');
      debugPrint('Stack trace: $stackTrace');
      
      // Filtrar erros relacionados a PigeonUserDetails (bug do Google Sign In)
      String errorMessage = e.toString();
      if (errorMessage.contains('PigeonUserDetails')) {
        debugPrint('⚠️ Erro PigeonUserDetails detectado - pode ser bug do Google Sign In');
        // Se o usuário foi criado mesmo com o erro, continuar
        if (_auth.currentUser != null) {
          debugPrint('✅ Usuário criado apesar do erro PigeonUserDetails, continuando...');
          try {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('userType', userType.toString().split('.').last);
            await _loadUserFromFirebase(_auth.currentUser!, preferredLanguage: preferredLanguage);
            
            if (_user != null) {
              NotificationService.initialize(_user!.id).catchError((e) {
                debugPrint('⚠️ Erro ao inicializar notificações: $e');
              });
            }
            
            _isLoading = false;
            notifyListeners();
            return true;
          } catch (e2) {
            debugPrint('❌ Erro ao carregar usuário após PigeonUserDetails: $e2');
          }
        }
        errorMessage = 'Erro ao criar conta. Tente novamente ou use outro método de cadastro.';
      } else {
        errorMessage = 'Erro ao criar conta: ${e.toString()}';
      }
      
      _errorMessage = errorMessage;
      notifyListeners();
      return false;
    }
  }

  Future<bool> loginWithGoogle(model.UserType userType, {String? preferredLanguage}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    // Garantir que o GoogleSignIn esteja inicializado com o serverClientId (Web Client ID)
    if (!_isGoogleSignInInitialized) {
      try {
        await googleSignIn.initialize(
          clientId: '476899420653-i68uga9ceqb8m9ovo1bpm9j7204ued3g.apps.googleusercontent.com',
          serverClientId: '476899420653-32m5g35ltk24e92426rnpde37s0tpthu.apps.googleusercontent.com',
        );
        _isGoogleSignInInitialized = true;
      } catch (e) {
        debugPrint('⚠️ Erro ao inicializar GoogleSignIn: $e');
      }
    }

    // Criar listener ANTES de iniciar qualquer processo
    User? authenticatedUser;
    StreamSubscription<User?>? authSubscription;
    
    authSubscription = _auth.authStateChanges().listen((User? user) {
      if (user != null) {
        authenticatedUser = user;
      }
    });

    try {
      // Iniciar fluxo de login do Google
      GoogleSignInAccount? googleUser;
      try {
        googleUser = await googleSignIn.authenticate();
      } on GoogleSignInException catch (e) {
        debugPrint('⚠️ Erro ao autenticar com Google: ${e.code}: $e');
        await authSubscription.cancel();
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Se o usuário cancelou o fluxo de login
      if (googleUser == null) {
        await authSubscription.cancel();
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Tentar obter autenticação (pode dar erro PigeonUserDetails)
      GoogleSignInAuthentication? googleAuth;
      try {
        googleAuth = await googleUser.authentication;
      } catch (e) {
        debugPrint('⚠️ Erro ao obter authentication do Google (PigeonUserDetails?): $e');
        // Erro ao obter authentication - tentar método alternativo
        // Verificar se Firebase já autenticou via authStateChanges
        if (authenticatedUser != null) {
          await authSubscription.cancel();
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('userType', userType.toString().split('.').last);
          await _loadUserFromFirebase(authenticatedUser!, preferredLanguage: preferredLanguage);
          
          if (_user != null) {
            NotificationService.initialize(_user!.id).catchError((e) {
              debugPrint('⚠️ Erro ao inicializar notificações: $e');
            });
          }
          
          _isLoading = false;
          notifyListeners();
          return true;
        }
        // Continuar para verificar Firebase diretamente
      }

      // Se conseguimos a autenticação, usar normalmente
      if (googleAuth != null && googleAuth.idToken != null) {
        final credential = GoogleAuthProvider.credential(
          idToken: googleAuth.idToken,
        );
        final userCredential = await _auth.signInWithCredential(credential);
        
        if (userCredential.user != null) {
          await authSubscription.cancel();
          _firebaseUser = userCredential;
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('userType', userType.toString().split('.').last);
          await _loadUserFromFirebase(userCredential.user!, preferredLanguage: preferredLanguage);
          
          if (_user != null) {
            NotificationService.initialize(_user!.id).catchError((e) {
              debugPrint('⚠️ Erro ao inicializar notificações: $e');
            });
          }
          
          _isLoading = false;
          notifyListeners();
          return true;
        }
      }

      // Se chegou aqui, deu erro ao obter authentication, mas Firebase pode ter autenticado
      // Aguardar um pouco para Firebase processar e verificar múltiplas vezes
      for (int i = 0; i < 10; i++) {
        await Future.delayed(const Duration(milliseconds: 400));
        
        // Verificar se listener capturou
        if (authenticatedUser != null) {
          await authSubscription.cancel();
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('userType', userType.toString().split('.').last);
          await _loadUserFromFirebase(authenticatedUser!, preferredLanguage: preferredLanguage);
          
          // Inicializar notificações push após login com Google
          if (_user != null) {
            NotificationService.initialize(_user!.id).catchError((e) {
              debugPrint('⚠️ Erro ao inicializar notificações: $e');
            });
          }
          
          _isLoading = false;
          notifyListeners();
          return true;
        }
        
        // Verificar diretamente também
        final currentUser = _auth.currentUser;
        if (currentUser != null) {
          await authSubscription.cancel();
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('userType', userType.toString().split('.').last);
          await _loadUserFromFirebase(currentUser, preferredLanguage: preferredLanguage);
          
          // Inicializar notificações push após login com Google
          if (_user != null) {
            NotificationService.initialize(_user!.id).catchError((e) {
              debugPrint('⚠️ Erro ao inicializar notificações: $e');
            });
          }
          
          _isLoading = false;
          notifyListeners();
          return true;
        }
      }

      await authSubscription.cancel();
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      await authSubscription?.cancel();
      
      // Última tentativa: verificar se usuário foi autenticado
      for (int i = 0; i < 10; i++) {
        await Future.delayed(const Duration(milliseconds: 400));
        final currentUser = _auth.currentUser;
        
        if (currentUser != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('userType', userType.toString().split('.').last);
          await _loadUserFromFirebase(currentUser, preferredLanguage: preferredLanguage);
          _isLoading = false;
          notifyListeners();
          return true;
        }
      }
      _isLoading = false;
      if (e is GoogleSignInException) {
        _errorMessage = 'Erro ao fazer login com Google: ${e.code}: $e';
      } else {
        _errorMessage = 'Erro ao fazer login com Google: ${e.toString()}';
      }
      notifyListeners();
      return false;
    }
  }

  Future<bool> loginWithFacebook(model.UserType userType, {String? preferredLanguage}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final LoginResult result = await FacebookAuth.instance.login(permissions: ['email']);

      if (result.status != LoginStatus.success || result.accessToken == null) {
        _isLoading = false;
        if (result.status == LoginStatus.cancelled) {
          // Usuário cancelou, não mostrar erro agressivo
          _errorMessage = null;
        } else {
          _errorMessage = 'Erro ao fazer login com Facebook. Tente novamente.';
        }
        notifyListeners();
        return false;
      }

      final OAuthCredential credential = FacebookAuthProvider.credential(result.accessToken!.token);
      final UserCredential userCredential = await _auth.signInWithCredential(credential);

      if (userCredential.user == null) {
        _isLoading = false;
        _errorMessage = 'Erro ao fazer login com Facebook. Usuário não encontrado.';
        notifyListeners();
        return false;
      }

      _firebaseUser = userCredential;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('userType', userType.toString().split('.').last);

      await _loadUserFromFirebase(userCredential.user!, preferredLanguage: preferredLanguage);

      if (_user != null && _user!.type != userType) {
        _errorMessage =
            'Esta conta é do tipo "${_user!.type == model.UserType.business ? 'business' : 'user'}" '
            'e não é compatível com esta variante do app.';
        await logout();
        _isLoading = false;
        notifyListeners();
        return false;
      }

      if (_user != null) {
        NotificationService.initialize(_user!.id).catchError((e) {
          debugPrint('⚠️ Erro ao inicializar notificações (Facebook): $e');
        });
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _isLoading = false;
      debugPrint('❌ Erro Firebase Auth (Facebook): ${e.code} - ${e.message}');
      _errorMessage = _getAuthErrorMessage(e.code);
      notifyListeners();
      return false;
    } catch (e, stackTrace) {
      _isLoading = false;
      debugPrint('❌ Erro inesperado no login com Facebook: $e');
      debugPrint('Stack trace: $stackTrace');
      _errorMessage = 'Erro ao fazer login com Facebook. Tente novamente.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> loginWithApple(model.UserType userType, {String? preferredLanguage}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final bool isAvailable = await SignInWithApple.isAvailable();
      if (!isAvailable) {
        _isLoading = false;
        _errorMessage = 'Login com Apple não está disponível neste dispositivo.';
        notifyListeners();
        return false;
      }

      final rawNonce = _generateNonce();
      final hashedNonce = _sha256ofString(rawNonce);

      final AuthorizationCredentialAppleID appleCredential =
          await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: hashedNonce,
      );

      if (appleCredential.identityToken == null) {
        _isLoading = false;
        _errorMessage = 'Erro ao obter credenciais da Apple. Tente novamente.';
        notifyListeners();
        return false;
      }

      final oauthCredential = OAuthProvider('apple.com').credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
        rawNonce: rawNonce,
      );

      final UserCredential userCredential =
          await _auth.signInWithCredential(oauthCredential);

      if (userCredential.user == null) {
        _isLoading = false;
        _errorMessage = 'Erro ao fazer login com Apple. Usuário não encontrado.';
        notifyListeners();
        return false;
      }

      _firebaseUser = userCredential;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('userType', userType.toString().split('.').last);

      await _loadUserFromFirebase(userCredential.user!, preferredLanguage: preferredLanguage);

      if (_user != null) {
        NotificationService.initialize(_user!.id).catchError((e) {
          debugPrint('⚠️ Erro ao inicializar notificações (Apple): $e');
        });
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } on SignInWithAppleAuthorizationException catch (e) {
      _isLoading = false;
      if (e.code == AuthorizationErrorCode.canceled) {
        // Usuário cancelou, não tratar como erro grave
        _errorMessage = null;
      } else if (e.code == AuthorizationErrorCode.unknown) {
        debugPrint('❌ Erro na autorização Apple (unknown): $e');
        _errorMessage =
            'Não foi possível autorizar com a Apple. Verifique sua conta Apple e tente novamente.';
      } else {
        debugPrint('❌ Erro na autorização Apple: ${e.code} - $e');
        _errorMessage = 'Erro ao fazer login com Apple. Tente novamente.';
      }
      notifyListeners();
      return false;
    } on FirebaseAuthException catch (e) {
      _isLoading = false;
      debugPrint('❌ Erro Firebase Auth (Apple): ${e.code} - ${e.message}');
      _errorMessage = _getAuthErrorMessage(e.code);
      notifyListeners();
      return false;
    } catch (e, stackTrace) {
      _isLoading = false;
      debugPrint('❌ Erro inesperado no login com Apple: $e');
      debugPrint('Stack trace: $stackTrace');
      _errorMessage = 'Erro ao fazer login com Apple. Tente novamente.';
      notifyListeners();
      return false;
    }
  }

  String _generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)])
        .join();
  }

  String _sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<void> logout() async {
    try {
      // Remover token FCM antes de fazer logout
      if (_user != null) {
        await NotificationService.removeFcmToken(_user!.id).catchError((e) {
          debugPrint('⚠️ Erro ao remover FCM token: $e');
        });
      }
      
      // Fazer logout do Google Sign In (se estiver inicializado)
      try {
        if (_googleSignIn != null) {
          await googleSignIn.signOut();
        }
      } catch (e) {
        debugPrint('⚠️ Erro ao fazer logout do Google: $e');
        // Continuar mesmo com erro
      }
      await _auth.signOut();
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user');
      await prefs.remove('userType');
      
      _user = null;
      _firebaseUser = null;
      notifyListeners();
    } catch (e) {
      debugPrint('Erro ao fazer logout: $e');
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } catch (e) {
      debugPrint('Erro ao enviar email de recuperação: $e');
      rethrow;
    }
  }

  /// Atualiza o idioma preferido do usuário
  Future<void> updatePreferredLanguage(String languageCode) async {
    if (_user == null) return;
    
    try {
      // Atualizar objeto local primeiro
      _user = model.User(
        id: _user!.id,
        email: _user!.email,
        name: _user!.name,
        type: _user!.type,
        photoUrl: _user!.photoUrl,
        coverPhotoUrl: _user!.coverPhotoUrl,
        preferredLanguage: languageCode,
        phone: _user!.phone,
        points: _user!.points,
        seal: _user!.seal,
        totalCheckIns: _user!.totalCheckIns,
        totalReviews: _user!.totalReviews,
        totalReferrals: _user!.totalReferrals,
        followersCount: _user!.followersCount,
        followingCount: _user!.followingCount,
        dietaryPreferences: _user!.dietaryPreferences,
        createdAt: _user!.createdAt,
      );
      
      // Salvar localmente primeiro (não esperar Firestore)
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user', json.encode(_user!.toJson()));
      
      notifyListeners();
      
      // Tentar atualizar no Firestore em background (não bloquear)
      FirebaseService.updateUserPreferredLanguage(_user!.id, languageCode)
          .catchError((e) {
        debugPrint('⚠️ Erro ao atualizar idioma no Firestore: $e');
      });
    } catch (e) {
      debugPrint('Erro ao atualizar idioma preferido: $e');
    }
  }

  Future<void> updateDietaryPreferences(List<String> dietaryPreferences) async {
    if (_user == null) return;

    try {
      _user = model.User(
        id: _user!.id,
        email: _user!.email,
        name: _user!.name,
        type: _user!.type,
        photoUrl: _user!.photoUrl,
        coverPhotoUrl: _user!.coverPhotoUrl,
        preferredLanguage: _user!.preferredLanguage,
          phone: _user!.phone,
        points: _user!.points,
        seal: _user!.seal,
        totalCheckIns: _user!.totalCheckIns,
        totalReviews: _user!.totalReviews,
        totalReferrals: _user!.totalReferrals,
        followersCount: _user!.followersCount,
        followingCount: _user!.followingCount,
        dietaryPreferences: dietaryPreferences,
        createdAt: _user!.createdAt,
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user', json.encode(_user!.toJson()));

      FirebaseService.saveUserData(_user!).catchError((e) {
        debugPrint('⚠️ Erro ao salvar preferências dietéticas no Firestore: $e');
      });

      notifyListeners();
    } catch (e) {
      debugPrint('❌ Erro ao atualizar preferências dietéticas: $e');
    }
  }

  /// Recarrega os dados do usuário do Firestore
  Future<void> reloadUser() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      // Se não há usuário autenticado, tentar carregar do local
      await _loadUser();
      return;
    }
    
    try {
      final firestoreUser = await FirebaseService.getUserData(currentUser.uid)
          .timeout(const Duration(seconds: 5), onTimeout: () {
        debugPrint('⚠️ Timeout ao recarregar dados do usuário');
        return null;
      });
      
      if (firestoreUser != null) {
        // Atualizar usuário local com dados do Firestore
        _user = firestoreUser;
        // Salvar localmente também
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user', json.encode(_user!.toJson()));
        notifyListeners();
        debugPrint('✅ Dados do usuário recarregados do Firestore');
      } else {
        // Se não conseguiu do Firestore, manter dados locais
        debugPrint('⚠️ Não foi possível recarregar do Firestore, mantendo dados locais');
      }
    } catch (e) {
      debugPrint('⚠️ Erro ao recarregar dados do usuário: $e');
      // Em caso de erro, manter dados locais
      await _loadUser();
    }
  }

  String _getAuthErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'Nenhum usuário encontrado com este email.';
      case 'wrong-password':
        return 'Senha incorreta.';
      case 'email-already-in-use':
        return 'Este email já está sendo usado.';
      case 'invalid-email':
        return 'Email inválido.';
      case 'weak-password':
        return 'Senha muito fraca. Use pelo menos 6 caracteres.';
      case 'network-request-failed':
        return 'Erro de conexão. Verifique sua internet.';
      case 'too-many-requests':
        return 'Muitas tentativas. Aguarde alguns minutos e tente novamente.';
      case 'user-disabled':
        return 'Esta conta foi desabilitada. Entre em contato com o suporte.';
      case 'operation-not-allowed':
        return 'Operação não permitida. Verifique as configurações do Firebase.';
      case 'invalid-credential':
        return 'Credenciais inválidas. Verifique email e senha.';
      case 'requires-recent-login':
        return 'Por favor, faça logout e login novamente.';
      case 'account-exists-with-different-credential':
        return 'Já existe uma conta com este email. Faça login com email/senha para vincular.';
      default:
        debugPrint('⚠️ Código de erro não mapeado: $code');
        return 'Erro ao fazer login. Tente novamente. (Código: $code)';
    }
  }

  /// Verifica se o usuário atual precisa trocar a senha (usuário empresa criado pelo admin)
  Future<bool> checkMustChangePassword() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return false;

    try {
      final doc = await FirebaseService.getUserData(currentUser.uid);
      if (doc == null) return false;
      
      // Verificar campo mustChangePassword no Firestore
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();
      
      if (!userDoc.exists) return false;
      
      final data = userDoc.data();
      return data?['mustChangePassword'] == true;
    } catch (e) {
      debugPrint('⚠️ Erro ao verificar mustChangePassword: $e');
      return false;
    }
  }

  /// Marca que o usuário já trocou a senha
  Future<void> clearMustChangePassword() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .update({
        'mustChangePassword': false,
        'passwordChangedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('⚠️ Erro ao limpar mustChangePassword: $e');
    }
  }

  /// Tenta login com Google e retorna informações para tratamento de conta existente
  /// Retorna um Map com:
  /// - 'success': bool - se o login foi bem sucedido
  /// - 'needsLinking': bool - se precisa vincular a conta existente
  /// - 'email': String? - email da conta existente (se needsLinking)
  /// - 'credential': AuthCredential? - credencial do Google para vincular
  Future<Map<String, dynamic>> loginWithGoogleAdvanced(model.UserType userType, {String? preferredLanguage}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Inicializar GoogleSignIn se necessário
      if (!_isGoogleSignInInitialized) {
        try {
          await googleSignIn.initialize(
            clientId: '476899420653-i68uga9ceqb8m9ovo1bpm9j7204ued3g.apps.googleusercontent.com',
            serverClientId: '476899420653-32m5g35ltk24e92426rnpde37s0tpthu.apps.googleusercontent.com',
          );
          _isGoogleSignInInitialized = true;
        } catch (e) {
          debugPrint('⚠️ Erro ao inicializar GoogleSignIn: $e');
        }
      }

      // Iniciar fluxo de login do Google
      GoogleSignInAccount? googleUser;
      try {
        googleUser = await googleSignIn.authenticate();
      } on GoogleSignInException catch (e) {
        debugPrint('⚠️ Erro ao autenticar com Google: ${e.code}: $e');
        _isLoading = false;
        notifyListeners();
        return {'success': false, 'needsLinking': false};
      }

      if (googleUser == null) {
        _isLoading = false;
        notifyListeners();
        return {'success': false, 'needsLinking': false};
      }

      // Obter autenticação
      final googleAuth = await googleUser.authentication;
      
      if (googleAuth.idToken == null) {
        _isLoading = false;
        notifyListeners();
        return {'success': false, 'needsLinking': false};
      }

      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      try {
        final userCredential = await _auth.signInWithCredential(credential);
        
        if (userCredential.user != null) {
          _firebaseUser = userCredential;
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('userType', userType.toString().split('.').last);
          await _loadUserFromFirebase(userCredential.user!, preferredLanguage: preferredLanguage);
          
          if (_user != null) {
            NotificationService.initialize(_user!.id).catchError((e) {
              debugPrint('⚠️ Erro ao inicializar notificações: $e');
            });
          }
          
          _isLoading = false;
          notifyListeners();
          return {'success': true, 'needsLinking': false};
        }
      } on FirebaseAuthException catch (e) {
        if (e.code == 'account-exists-with-different-credential') {
          // Conta existe com outro provider - precisa vincular
          _isLoading = false;
          notifyListeners();
          return {
            'success': false,
            'needsLinking': true,
            'email': googleUser.email,
            'credential': credential,
          };
        }
        rethrow;
      }

      _isLoading = false;
      notifyListeners();
      return {'success': false, 'needsLinking': false};
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Erro ao fazer login com Google: $e';
      notifyListeners();
      return {'success': false, 'needsLinking': false, 'error': e.toString()};
    }
  }

  /// Vincula credencial do Google a uma conta existente após login com email/senha
  Future<bool> linkGoogleCredential(AuthCredential credential) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return false;

      await currentUser.linkWithCredential(credential);
      debugPrint('✅ Credencial Google vinculada com sucesso');
      return true;
    } catch (e) {
      debugPrint('❌ Erro ao vincular credencial Google: $e');
      return false;
    }
  }

  Future<bool> deleteAccount(String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final user = _auth.currentUser;
      if (user == null || _user == null) {
        throw Exception('Usuário não autenticado');
      }

      // Tentar reautenticar se for email/senha
      if (user.providerData.any((UserInfo info) => info.providerId == 'password')) {
         AuthCredential credential = EmailAuthProvider.credential(email: user.email!, password: password);
         await user.reauthenticateWithCredential(credential);
      }

      // Deletar dados do Firestore
      await FirebaseService.deleteUserData(_user!.id);

      // Deletar usuário do Auth
      await user.delete();

      // Limpar dados locais
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      _user = null;
      _firebaseUser = null;
      _isLoading = false;
      notifyListeners();
      return true;

    } catch (e) {
      debugPrint('❌ Erro ao excluir conta: $e');
      _errorMessage = 'Erro ao excluir conta: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
