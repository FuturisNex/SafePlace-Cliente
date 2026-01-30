import 'dart:io';

class IapProducts {
  // Retorna todos os productIds conhecidos pela aplicação.
  // Se quiser popular isso dinamicamente, substitua pelos IDs reais.
  static List<String> allProductIds() {
    // Por padrão retornamos uma lista vazia para evitar erros de compilação.
    // Substitua pelos seus productIds: e.g. ['com.safeplate.empresa.plan_basic', ...]
    return [];
  }

  // Retorna productId do boost (consumable). Substitua se necessário.
  static String getBoostProductId() {
    // Caso você tenha um ID específico, coloque aqui.
    return '';
  }

  // Chave de plataforma: 'android' ou 'ios'
  static String platformKey() {
    try {
      return Platform.isAndroid ? 'android' : 'ios';
    } catch (_) {
      return 'android';
    }
  }

  // Retornamos uma lista vazia para getPlans (compatibilidade).
  static List<dynamic> getPlans() => [];

  // Compatibilidade: busca um plano por chave (não implementado aqui).
  static dynamic planByKey(String key) {
    return null;
  }
}