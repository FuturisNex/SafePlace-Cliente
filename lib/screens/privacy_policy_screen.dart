import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({Key? key}) : super(key: key);

  // Conteúdo placeholder — substitua pelo texto oficial quando disponível.
  String get _policyText => '''
Política de Privacidade — Prato Seguro
1. Compromisso com a Privacidade
A Prato Seguro Tecnologia LTDA respeita a privacidade dos usuários e realiza o tratamento de dados pessoais em conformidade com a Lei Geral de Proteção de Dados (LGPD – Lei nº 13.709/2018).

2. Dados Coletados
Podem ser coletados, conforme o uso da plataforma:
  - nome, e-mail e telefone;
  - dados de login e autenticação;
  - informações de uso do aplicativo e do site;
  - localização aproximada (quando autorizada);
  - dados fornecidos por estabelecimentos parceiros.

3. Finalidade do Tratamento
Os dados coletados são utilizados para:
  - funcionamento adequado da plataforma;
  - autenticação, segurança e prevenção de fraudes;
  - personalização da experiência do usuário;
  - comunicação com usuários e estabelecimentos;
  - melhoria contínua dos serviços;
  - cumprimento de obrigações legais.

4. Compartilhamento de Dados
Os dados não são vendidos.

Eles podem ser compartilhados apenas:
  - com prestadores de serviços essenciais (ex.: hospedagem, mapas, notificações);
  - quando exigido por lei ou ordem judicial;
  - mediante consentimento do titular, quando aplicável.

5. Armazenamento e Segurança
Os dados são armazenados em ambientes seguros, com medidas técnicas e administrativas adequadas, incluindo controle de acesso e, quando aplicável, criptografia.
Apesar das boas práticas adotadas, nenhum sistema é totalmente imune a riscos.

6. Direitos do Titular
O usuário pode, a qualquer momento:
  - solicitar acesso aos seus dados pessoais;
  - corrigir informações incorretas ou desatualizadas;
  - solicitar a exclusão de dados, quando permitido por lei;
  - revogar consentimentos previamente concedidos.

As solicitações devem ser feitas pelo e-mail: pratoseguroapp@gmail.com

7. Cookies
O site pode utilizar cookies para:
  - funcionamento adequado da plataforma;
  - análise de uso e desempenho;
  - melhoria da experiência do usuário.

O usuário pode gerenciar cookies diretamente nas configurações de seu navegador.

8. Retenção dos Dados
Os dados pessoais serão mantidos apenas pelo período necessário para cumprir suas finalidades ou exigências legais e regulatórias.

9. Alterações desta Política
Esta Política de Privacidade pode ser atualizada a qualquer momento.
Recomendamos a revisão periódica deste documento.

10. Contato
Em caso de dúvidas sobre privacidade ou proteção de dados:

E-mail: pratoseguroapp@gmail.com
WhatsApp: (41) 99624-3262
''';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Política de Privacidade'),
        elevation: 0,
        backgroundColor: theme.scaffoldBackgroundColor,
        foregroundColor: theme.textTheme.bodyLarge?.color,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          child: SingleChildScrollView(
            child: Text(
              _policyText,
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ),
      ),
    );
  }
}