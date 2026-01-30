# Prato Seguro – Documentação do Aplicativo Mobile

**Versão:** 1.2.0  
**Atualização:** Dezembro de 2025

---

## Sobre o projeto

O Prato Seguro é um aplicativo Flutter que conecta pessoas com restrições alimentares a estabelecimentos que oferecem opções seguras. Esta documentação cobre apenas o **aplicativo mobile** (Android e iOS) e seus componentes de suporte.

---

## Público-alvo

- **Usuários finais** com alergias, intolerâncias ou dietas específicas.
- **Empresas** que desejam divulgar cardápios seguros e aumentar visibilidade junto ao público correto.

---

## Principais funcionalidades

1. **Mapa seguro (Mapbox)**
   - Exibe estabelecimentos próximos com filtros por restrição alimentar e categoria.
   - Indica locais certificados e destaques Premium.

2. **Check-ins e avaliações**
   - Registro de visitas com fotos, comentários e nota.
   - Construção de reputação da comunidade.

3. **Gamificação**
   - Pontos por check-ins, avaliações, indicações e participação.
   - Selos (Bronze, Prata, Ouro) e ranking de usuários engajados.

4. **Favoritos e modo offline**
   - Salve locais para consultar sem internet.
   - Acesso rápido aos lugares preferidos.

5. **Cupons e benefícios**
   - Resgate de cupons usando pontos.
   - Campanhas e destaques patrocinados.

6. **Experiência para empresas**
   - Gestão de estabelecimentos, cardápio e planos dentro do app.
   - Solicitação de certificação técnica e acompanhamento de avaliações.

---

## Stack do aplicativo

- **Flutter 3.x / Dart**
- **Firebase**: Auth, Firestore, Storage, Messaging
- **Mapbox Maps**
- **Provider** (estado)
- **Dio / http** (API)
- **shared_preferences / sqflite** (armazenamento local)
- **flutter_local_notifications + firebase_messaging** (notificações)

Todos os detalhes para uso adequado das bibliotecas estão descritos em `AI_RULES.md`.

---

## Estrutura de pastas

```
lib/
├── main.dart
├── models/
├── providers/
├── screens/
├── services/
├── widgets/
└── utils/
assets/
  ├── icons/
  └── images/
android/    # Projeto nativo Android
ios/        # Projeto nativo iOS
test/       # Testes Flutter
```

---

## Configuração rápida

1. **Dependências**
   ```
   flutter pub get
   ```
2. **Firebase**
   - `google-services.json` → `android/app/`
   - `GoogleService-Info.plist` → `ios/Runner/`
3. **Mapbox**
   - Token em `android/app/src/main/AndroidManifest.xml` e, se necessário, em `ios/Runner/Info.plist`.
4. **Execução**
   ```
   flutter run
   ```

---

## Recursos de dados

- Cloud Firestore: usuários, estabelecimentos, check-ins, avaliações, planos, cupons, notificações.
- Firebase Storage: imagens de usuários, estabelecimentos e avaliações.
- Firebase Messaging: push notifications.
- Integração Mercado Pago: gerenciada por serviço dedicado em `lib/services/mercado_pago_payment_service.dart`.

---

## Gamificação (valores padrão)

| Ação                                   | Pontos |
|----------------------------------------|--------|
| Check-in                               | 10     |
| Avaliação                              | 15     |
| Avaliação com foto                     | 25     |
| Indicar novo estabelecimento           | 50     |
| Responder pesquisa                     | 15     |
| Indicar novo usuário                   | 100    |

Selos evoluem conforme pontos e participação:
- **Bronze**
- **Prata**
- **Ouro**

---

## Automatizações

- **Codemagic** (`codemagic.yaml`): builds Flutter para simulador, screenshots e TestFlight.
- **GitHub Actions** (`.github/workflows/`): builds e screenshots automáticos.

---

## Suporte

Em caso de dúvidas ou solicitações, entre em contato com a equipe de desenvolvimento do Prato Seguro.

---