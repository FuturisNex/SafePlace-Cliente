import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class UserGuideScreen extends StatelessWidget {
  const UserGuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Guia do Usuário'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection(
              title: '🧭 Bem-vindo ao Prato Seguro',
              content:
                  'O Prato Seguro é um aplicativo gratuito criado para tornar a alimentação mais segura, transparente e acessível para pessoas com restrições alimentares.\n\n'
                  'Ele ajuda a evitar contaminação cruzada, conectando usuários a locais confiáveis e promovendo uma comunidade colaborativa de avaliações e indicações.',
            ),
            const SizedBox(height: 24),

            _buildSection(
              title: '1️⃣ Para quem é o Prato Seguro',
              content:
                  'O aplicativo foi desenvolvido especialmente para:\n\n'
                  '• Pessoas com doença celíaca\n'
                  '• Pessoas com APLV (Alergia à Proteína do Leite de Vaca)\n'
                  '• Intolerantes à lactose\n'
                  '• Pessoas com alergias alimentares\n'
                  '• Veganos e vegetarianos\n\n'
                  'Também atende famílias, cuidadores e qualquer pessoa que busca mais segurança e autonomia na alimentação.',
            ),
            const SizedBox(height: 24),

            _buildSection(
              title: '2️⃣ Como o aplicativo funciona',
              content:
                  'O uso do Prato Seguro é simples e intuitivo:\n\n'
                  '• Cadastro do usuário com nome e avatar\n'
                  '• Seleção das restrições alimentares\n'
                  '• Localização de lugares seguros por região\n'
                  '• Consulta de informações e avaliações dos estabelecimentos\n'
                  '• Interação com a comunidade por meio de avaliações e seguidores',
            ),
            const SizedBox(height: 24),

            _buildSection(
              title: '3️⃣ Mapa interativo',
              content:
                  'Encontre locais seguros de forma visual:\n\n'
                  '• Visualize estabelecimentos próximos no mapa\n'
                  '• Marcadores verdes indicam locais confiáveis\n'
                  '• Navegue por bairros, cidades e rotas com facilidade',
            ),
            const SizedBox(height: 24),

            _buildSection(
              title: '4️⃣ Busca inteligente',
              content:
                  'Utilize filtros avançados para encontrar o local ideal:\n\n'
                  '• Busca por nome, cidade ou bairro\n'
                  '• Filtro por tipo de estabelecimento\n'
                  '• Filtro por tipo de restrição alimentar\n'
                  '• Resultados personalizados conforme seu perfil',
            ),
            const SizedBox(height: 24),

            _buildSection(
              title: '5️⃣ Favoritos',
              content:
                  'Salve seus locais preferidos:\n\n'
                  '• Acesso rápido aos estabelecimentos favoritos\n'
                  '• Organização personalizada\n'
                  '• Facilidade para futuras visitas',
            ),
            const SizedBox(height: 24),

            _buildSection(
              title: '6️⃣ Minhas Viagens',
              content:
                  'Planeje viagens com mais segurança:\n\n'
                  '• Crie roteiros com paradas seguras\n'
                  '• Planeje refeições adaptadas\n'
                  '• Consulte viagens passadas e futuras',
            ),
            const SizedBox(height: 24),

            _buildSection(
              title: '7️⃣ Comunidade e interações',
              content:
                  'Faça parte da comunidade Prato Seguro:\n\n'
                  '• Encontre usuários por nome ou e-mail\n'
                  '• Veja seguidores, avaliações e selos\n'
                  '• Interaja contribuindo com avaliações reais\n'
                  '• Acompanhe o ranking de avaliadores',
            ),
            const SizedBox(height: 24),

            _buildSection(
              title: '8️⃣ Eventos e notificações',
              content:
                  'Fique por dentro das novidades:\n\n'
                  '• Notificações de proximidade com locais seguros\n'
                  '• Avisos sobre novos seguidores e interações\n'
                  '• Pop-ups de eventos especiais como a Feira Prato Seguro',
            ),
            const SizedBox(height: 24),

            _buildSection(
              title: '9️⃣ Idiomas disponíveis',
              content:
                  'O Prato Seguro é um aplicativo global:\n\n'
                  '• Português\n'
                  '• Espanhol\n'
                  '• Inglês\n\n'
                  'Você pode alterar o idioma conforme sua preferência.',
            ),
            const SizedBox(height: 24),

            _buildSection(
              title: '🔒 Segurança e confiabilidade',
              content:
                  'Levamos sua segurança a sério:\n\n'
                  '• Critérios claros de segurança alimentar\n'
                  '• Informações transparentes e atualizadas\n'
                  '• Validação comunitária e técnica\n'
                  '• Responsabilidade compartilhada entre usuários, parceiros e equipe',
            ),
            const SizedBox(height: 24),

            _buildSection(
              title: '💳 Planos e acesso',
              content:
                  'Usuários finais têm acesso gratuito às funcionalidades essenciais.\n\n'
                  'Estabelecimentos participam por meio do aplicativo Prato Seguro Empresas, '
                  'com planos básico, intermediário, premium e corporate, ampliando visibilidade e integração com a comunidade.',
            ),
            const SizedBox(height: 24),

            _buildSection(
              title: '📩 Suporte e contato',
              content:
                  'Precisa de ajuda?\n\n'
                  '• Fale com a equipe pelo próprio app\n'
                  '• Instagram: @prato.seguro\n'
                  '• E-mail: prato.seguro@pratoseguro.com\n'
                  '• WhatsApp: link disponível no app',
            ),
            const SizedBox(height: 40),

            Center(
              child: Text(
                'Coma com mais segurança. Viva com mais tranquilidade 💚',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryGreen,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({required String title, required String content}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryGreen,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          content,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade700,
            height: 1.6,
          ),
        ),
      ],
    );
  }
}
