import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class EmpresaGuideScreen extends StatelessWidget {
  const EmpresaGuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Guia do Prato Seguro Empresa'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection(
              title: '🧭 Bem-vindo ao Prato Seguro Empresa',
              content:
                  'O Prato Seguro Empresa é o aplicativo exclusivo para estabelecimentos comerciais que desejam se conectar à comunidade do app Prato Seguro.\n\n'
                  'Ele foi criado para ajudar empresas a tornar seus serviços mais acessíveis e seguros para pessoas com restrições alimentares, '
                  'além de ampliar a visibilidade e fortalecer a confiança junto aos consumidores.\n\n'
                  'O app está disponível em português, espanhol e inglês.',
            ),
            const SizedBox(height: 24),

            _buildSection(
              title: '1️⃣ Para quem é o Prato Seguro Empresa',
              content:
                  'Este aplicativo é indicado para:\n\n'
                  '• Restaurantes, padarias, cafés, hotéis e mercados\n'
                  '• Empresas que atendem pessoas com restrições alimentares\n'
                  '• Profissionais que desejam se destacar pela segurança e transparência\n'
                  '• Estabelecimentos interessados em participar de ações especiais, como a Feira Prato Seguro',
            ),
            const SizedBox(height: 24),

            _buildSection(
              title: '2️⃣ Como o aplicativo funciona',
              content:
                  'O funcionamento do app é simples e intuitivo:\n\n'
                  '• Cadastro da empresa com perfil público\n'
                  '• Indicação de locais seguros para a comunidade\n'
                  '• Impulsionamento de visibilidade nos resultados de busca\n'
                  '• Acompanhamento de avaliações, seguidores e desempenho\n'
                  '• Gestão de múltiplos estabelecimentos\n'
                  '• Escolha do idioma: português, inglês ou espanhol',
            ),
            const SizedBox(height: 24),

            _buildSection(
              title: '3️⃣ Onboarding e primeiros passos',
              content:
                  'Ao acessar o app pela primeira vez, você passa por um onboarding inicial com:\n\n'
                  '• Mensagem de boas-vindas\n'
                  '• Orientações sobre a comunidade Prato Seguro\n'
                  '• Incentivo à participação ativa\n'
                  '• Navegação guiada com botões de avançar e começar',
            ),
            const SizedBox(height: 24),

            _buildSection(
              title: '4️⃣ Indicação de locais seguros',
              content:
                  'Sua empresa pode indicar outros estabelecimentos seguros da região:\n\n'
                  '• Restaurantes, cafés e mercados confiáveis\n'
                  '• Fortalecimento da comunidade local\n'
                  '• Acesso rápido pelo botão “Indicar um local”',
            ),
            const SizedBox(height: 24),

            _buildSection(
              title: '5️⃣ Impulsionamento de visibilidade',
              content:
                  'A ferramenta de impulsionamento permite destacar seu estabelecimento:\n\n'
                  '• Aparição nos primeiros resultados de busca\n'
                  '• Controle de saldo e duração da campanha\n'
                  '• Métricas como impressões, cliques, CPC e CTR\n'
                  '• Acompanhamento do desempenho em tempo real',
            ),
            const SizedBox(height: 24),

            _buildSection(
              title: '6️⃣ Painel de desempenho',
              content:
                  'Acompanhe os principais indicadores do seu negócio:\n\n'
                  '• Número de seguidores\n'
                  '• Avaliações recebidas\n'
                  '• Cliques e check-ins\n'
                  '• Campanhas ativas e saldo investido',
            ),
            const SizedBox(height: 24),

            _buildSection(
              title: '7️⃣ Planos disponíveis',
              content:
                  'O Prato Seguro Empresa oferece diferentes planos:\n\n'
                  '• Gratuito: presença básica no app\n'
                  '• Intermediário: destaque em buscas e impulsionamento\n'
                  '• Premium: fotos em destaque, posição de topo e suporte dedicado\n'
                  '• Corporate: gestão avançada para redes de estabelecimentos',
            ),
            const SizedBox(height: 24),

            _buildSection(
              title: '8️⃣ Eventos especiais e parcerias',
              content:
                  'Empresas podem participar de ações exclusivas:\n\n'
                  '• Eventos como a Feira Prato Seguro\n'
                  '• Pop-ups informativos dentro do app\n'
                  '• Área dedicada para investidores e parceiros',
            ),
            const SizedBox(height: 24),

            _buildSection(
              title: '9️⃣ Segurança e confiabilidade',
              content:
                  'O Prato Seguro preza pela confiança da comunidade:\n\n'
                  '• Compromisso com práticas seguras de alimentação\n'
                  '• Transparência nas informações\n'
                  '• Validação técnica e comunitária dos locais\n'
                  '• Responsabilidade compartilhada entre empresas, usuários e equipe',
            ),
            const SizedBox(height: 24),

            _buildSection(
              title: '🔔 Suporte e contato',
              content:
                  'Precisa de ajuda?\n\n'
                  '• Suporte diretamente pelo aplicativo\n'
                  '• Instagram: @prato.seguro\n'
                  '• Envie dúvidas, sugestões e acompanhe novidades da plataforma',
            ),
            const SizedBox(height: 40),

            Center(
              child: Text(
                'Obrigado por fazer parte do Prato Seguro 💚',
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
