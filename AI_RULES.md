# AI Rules for Prato Seguro Mobile

## Visão geral da stack
- Flutter 3.x com Dart como base do aplicativo mobile multiplataforma.
- Firebase (Auth, Firestore, Storage, Messaging) para autenticação, dados, mídia e notificações.
- Mapbox Maps para renderizar mapas, pins e camadas geoespaciais.
- Provider como gerenciador de estado reativo de todo o app.
- Geolocator e permission_handler para geolocalização e permissões de localização.
- Dio e http para consumo de APIs e integrações externas.
- shared_preferences e sqflite para cache e armazenamento local.
- flutter_local_notifications integrado ao Firebase Messaging para alertas locais.

## Diretrizes de bibliotecas
- Priorize widgets nativos do Flutter; use Material como padrão e Cupertino apenas quando necessário para comportamento iOS.
- Utilize Provider para expor estados/global stores entre telas; evite misturar outros gerenciadores sem alinhamento prévio.
- Persistência em tempo real deve ficar no Cloud Firestore através dos serviços já existentes; evite criar camadas paralelas.
- Use firebase_auth para login/cadastro, google_sign_in, flutter_facebook_auth e sign_in_with_apple para logins sociais.
- Integrações com mapas devem passar sempre por mapbox_maps_flutter; não adicione outros SDKs de mapas.
- Para localização e permissões use geolocator + geocoding + permission_handler conforme utilidades já criadas.
- Consumo HTTP deve seguir dio para chamadas complexas (interceptores, cancelamento) e http para usos simples.
- Preferir shared_preferences para dados simples e sqflite para armazenamentos relacionais/offline maiores.
- Notificações push via firebase_messaging; use flutter_local_notifications para exibir alertas locais.
- Indicadores de carregamento devem aproveitar flutter_spinkit e feedbacks visuais existentes; mantenha consistência com o design atual.