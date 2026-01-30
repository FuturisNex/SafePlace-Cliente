// Configurações centrais do app.
//
// APP_ACCOUNT_TYPE pode ser 'user' ou 'business'.
// Você pode sobrescrever em tempo de build com:
// flutter build ... --dart-define=APP_ACCOUNT_TYPE=business
//
// Este arquivo expõe:
// - APP_ACCOUNT_TYPE (String)
// - kForcedUserType (UserType)  -> usado pelo app para forçar a variante
//
// Importa o enum UserType definido em lib/models/user.dart.
import 'models/user.dart';

const String APP_ACCOUNT_TYPE = String.fromEnvironment('APP_ACCOUNT_TYPE', defaultValue: 'user');

String get _normalizedAppAccountType => APP_ACCOUNT_TYPE.trim().toLowerCase();

final UserType kForcedUserType = (_normalizedAppAccountType == 'business') ? UserType.business : UserType.user;

const int TRIAL_DAYS = 999;
