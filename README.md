# Prato Seguro – Aplicativo Mobile

**Versão atual:** 1.2.0  
**Última atualização:** Dezembro de 2025

---

## Visão geral

O Prato Seguro é um aplicativo Flutter que ajuda pessoas com restrições alimentares a encontrar restaurantes, padarias, cafés e outros estabelecimentos seguros. O foco deste repositório é **exclusivamente** o aplicativo mobile (Android e iOS) e os recursos que ele utiliza.

---

## Público alvo

- **Consumidores**: usuários com alergias, intolerâncias ou escolhas alimentares específicas que precisam de referências confiáveis.
- **Empresas**: estabelecimentos que desejam divulgar opções seguras, acompanhar feedbacks e fidelizar clientes.

---

## Funcionalidades principais

- **Mapa interativo (Mapbox)** com filtros por restrição alimentar e categoria.
- **Check-ins, avaliações e upload de fotos** para construir confiança entre usuários.
- **Sistema de pontos, selos e ranking** para incentivar engajamento.
- **Favoritos e modo offline** para consulta sem internet.
- **Notificações push** com alertas sobre novos locais, cupons e eventos.
- **Área empresarial dentro do app** com planos de divulgação e gestão de cardápio.

---

## Tecnologias utilizadas

- **Flutter 3.x / Dart** para uma base única Android + iOS.
- **Firebase**: Auth, Firestore, Storage e Messaging.
- **Mapbox Maps** para mapas, pins e rotas.
- **Provider** para gerenciamento de estado reativo.
- **Dio / http** para integrações REST.
- **shared_preferences / sqflite** para armazenamento local.
- **flutter_local_notifications + firebase_messaging** para push/local notifications.

---

## Estrutura do projeto

```
prato-seguro/
├── android/                 # Projeto nativo Android gerado pelo Flutter
├── ios/                     # Projeto nativo iOS gerado pelo Flutter
├── lib/                     # Código Dart principal do aplicativo
│   ├── models/              # Modelos de dados
│   ├── providers/           # Providers (Provider package)
│   ├── screens/             # Telas do app
│   ├── services/            # Integrações (Firebase, pagamentos, mapas, etc.)
│   ├── widgets/             # Componentes reutilizáveis
│   └── utils/               # Helpers e utilidades
├── assets/                  # Imagens e ícones usados no app
├── test/                    # Testes Flutter
├── pubspec.yaml             # Dependências e configurações Flutter
├── codemagic.yaml           # Pipelines de CI/CD (Flutter)
└── README.md                # Este arquivo
```

---

## Configuração do ambiente

### Pré-requisitos

- Flutter SDK 3.0 ou superior.
- Conta Firebase com projeto configurado.
- Token do Mapbox Maps.
- Xcode (para builds iOS) e Android SDK (para builds Android).

### Passos

1. Instale dependências:
   ```
   flutter pub get
   ```
2. Adicione arquivos do Firebase:
   - `google-services.json` em `android/app/`.
   - `GoogleService-Info.plist` em `ios/Runner/`.
3. Configure tokens do Mapbox:
   - Android: `android/app/src/main/AndroidManifest.xml` (meta-data `com.mapbox.accessToken`).
   - iOS: `ios/Runner/Info.plist` (chave `MBXAccessToken` se necessário).
4. Execute:
   ```
   flutter run
   ```

---

## Variáveis e arquivos sensíveis

- **Firebase**: os arquivos `google-services.json` e `GoogleService-Info.plist` devem ser obtidos no console Firebase.
- **Mapbox**: token disponível em https://account.mapbox.com, adicione nas plataformas conforme instruções acima.
- **Mercado Pago**: o app consome serviços via `lib/services/mercado_pago_payment_service.dart`; credenciais ficam no backend seguro.

---

## Testes e qualidade

- Testes unitários/widget: `flutter test`
- Análise estática: `flutter analyze`
- Formatador: `flutter format <arquivos>`

---

## Automação (CI/CD)

- **Codemagic** (`codemagic.yaml`): orquestra builds para simulador iOS, screenshots e distribuição TestFlight.
- **GitHub Actions** (pasta `.github/workflows/`): builds e screenshots automatizados em macOS.

---

## Contato

Para dúvidas técnicas ou novas demandas, fale com a equipe de desenvolvimento do Prato Seguro.

---