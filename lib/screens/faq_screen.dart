import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Tela de Perguntas Frequentes (FAQ)
class FaqScreen extends StatefulWidget {
  const FaqScreen({super.key});

  @override
  State<FaqScreen> createState() => _FaqScreenState();
}

class _FaqScreenState extends State<FaqScreen> {
  final List<_FaqItem> _faqItems = [
    _FaqItem(
      question: 'O que é o Prato Seguro?',
      answer: 'O Prato Seguro é um aplicativo que ajuda pessoas com restrições alimentares (celíacos, intolerantes à lactose, veganos, etc.) a encontrar estabelecimentos que oferecem opções seguras para suas dietas. Conectamos você a restaurantes, padarias, cafés e outros locais que entendem suas necessidades.',
      icon: Icons.restaurant_menu,
    ),
    _FaqItem(
      question: 'Como encontrar estabelecimentos seguros?',
      answer: 'Use a barra de busca no mapa para pesquisar por nome, categoria ou tipo de restrição alimentar. Você também pode usar os filtros para refinar sua busca por distância, avaliação e opções dietéticas específicas.',
      icon: Icons.search,
    ),
    _FaqItem(
      question: 'O que são os selos de verificação?',
      answer: 'Os selos indicam a confiabilidade do estabelecimento:\n\n🏆 **Selo Popular**: Estabelecimento com 5+ avaliações positivas da comunidade.\n\n✅ **Verificado**: Estabelecimento verificado pela equipe Prato Seguro.\n\n⭐ **Premium**: Estabelecimento parceiro com recursos exclusivos.',
      icon: Icons.verified,
    ),
    _FaqItem(
      question: 'Como avaliar um estabelecimento?',
      answer: 'Após visitar um estabelecimento, acesse a página dele e toque em "Avaliar". Você pode dar uma nota de 1 a 5 estrelas e deixar um comentário sobre sua experiência. Suas avaliações ajudam outros usuários a encontrar locais seguros!',
      icon: Icons.star,
    ),
    _FaqItem(
      question: 'O que é o recurso de Viagens/Itinerários?',
      answer: 'O recurso de Viagens permite que você planeje roteiros gastronômicos seguros. Crie itinerários com múltiplos destinos, adicione paradas em estabelecimentos verificados e organize sua viagem dia a dia.',
      icon: Icons.luggage,
    ),
    _FaqItem(
      question: 'Como sugerir um novo estabelecimento?',
      answer: 'Se você conhece um estabelecimento que deveria estar no Prato Seguro, use o botão "Sugerir Estabelecimento" disponível no app. Preencha as informações e nossa equipe irá verificar e adicionar o local.',
      icon: Icons.add_business,
    ),
    _FaqItem(
      question: 'Como funciona o Delivery?',
      answer: 'O recurso de Delivery permite que você peça comida segura diretamente pelo app. Estabelecimentos parceiros oferecem entrega com garantia de preparo adequado para suas restrições alimentares.',
      icon: Icons.delivery_dining,
    ),
    _FaqItem(
      question: 'Sou dono de estabelecimento. Como cadastrar?',
      answer: 'Crie uma conta do tipo "Empresa" no app. Após o cadastro, você poderá adicionar seus estabelecimentos, gerenciar cardápios, responder avaliações e acessar estatísticas de visualização.',
      icon: Icons.store,
    ),
    _FaqItem(
      question: 'Como entrar em contato com o suporte?',
      answer: 'Você pode entrar em contato conosco através do nosso grupo oficial no WhatsApp ou pelo email suporteapp@pratoseguro.com. Também estamos no Instagram @prato.seguro.',
      icon: Icons.support_agent,
    ),
    _FaqItem(
      question: 'O app é gratuito?',
      answer: 'Sim! O Prato Seguro é gratuito para usuários. Todas as funcionalidades essenciais estão disponíveis gratuitamente.',
      icon: Icons.money_off,
    ),
    _FaqItem(
      question: 'Como funciona a verificação de estabelecimentos?',
      answer: 'Nossa equipe verifica estabelecimentos através de visitas presenciais, análise de cardápios e feedback da comunidade. Estabelecimentos verificados passam por um processo rigoroso para garantir a segurança alimentar.',
      icon: Icons.fact_check,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        title: const Text(
          'Perguntas Frequentes',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.darkGreen, AppTheme.primaryGreen],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.help_outline,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Central de Ajuda',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Tire suas dúvidas sobre o Prato Seguro',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          
          // FAQ items
          ..._faqItems.map((item) => _buildFaqCard(item)),
          
          const SizedBox(height: 20),
          
          // Contact card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Icon(
                  Icons.chat_bubble_outline,
                  size: 40,
                  color: AppTheme.primaryGreen,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Não encontrou sua resposta?',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Entre em contato conosco pelo WhatsApp ou Instagram',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 100), // Padding para navbar
        ],
      ),
    );
  }

  Widget _buildFaqCard(_FaqItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              item.icon,
              color: AppTheme.primaryGreen,
              size: 20,
            ),
          ),
          title: Text(
            item.question,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                item.answer,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FaqItem {
  final String question;
  final String answer;
  final IconData icon;

  _FaqItem({
    required this.question,
    required this.answer,
    required this.icon,
  });
}
