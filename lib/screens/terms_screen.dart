import 'package:flutter/material.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({Key? key}) : super(key: key);

  // Conteúdo placeholder — substitua pelo texto oficial quando disponível.
  String get _termsText => '''
Termos de Uso — Prato Seguro

Última atualização: Janeiro/2026

1. Identificação da Empresa
O aplicativo e o site Prato Seguro são operados por:

Prato Seguro Tecnologia LTDA
CNPJ: 63.630.478/0001-15
Sede: Curitiba – PR – Brasil
E-mail: suporteapp@pratoseguro.com
Telefone: (41) 99624-3262

2. Aceitação dos Termos
Ao acessar ou utilizar o aplicativo e/ou o site Prato Seguro, o usuário declara que leu, compreendeu e concorda integralmente com estes Termos de Uso.
Caso não concorde com qualquer condição aqui descrita, deverá interromper imediatamente o uso da plataforma.

3. Sobre a Plataforma
O Prato Seguro é uma plataforma digital que conecta:
  - Pessoas com restrições alimentares (celíacos, intolerantes à lactose, APLV, alérgicos alimentares, veganos, vegetarianos, entre outros);
  - Estabelecimentos comerciais que informam opções, práticas e dados relacionados à segurança alimentar.

A plataforma possui caráter informativo e colaborativo, não substituindo orientação médica, nutricional, sanitária ou qualquer outro tipo de aconselhamento profissional especializado.

4. Cadastro e Conta
Para utilizar determinadas funcionalidades, o usuário deverá:
  - Fornecer informações verdadeiras, completas e atualizadas;
  - Manter a confidencialidade de seus dados de acesso;
  - Responsabilizar-se por todas as atividades realizadas em sua conta.

O Prato Seguro poderá suspender ou excluir contas, a qualquer tempo, em caso de violação destes Termos ou da legislação vigente.

5. Responsabilidades do Usuário
O usuário compromete-se a:
  - Utilizar a plataforma de forma ética, responsável e legal;
  - Não publicar informações falsas, ofensivas ou enganosas;
  - Não violar direitos de terceiros;
  - Não tentar acessar áreas restritas ou sistemas internos da plataforma.

6. Responsabilidades dos Estabelecimentos
Os estabelecimentos cadastrados são inteiramente responsáveis pelas informações fornecidas, incluindo:
  - Descrição de produtos e serviços;
  - Práticas relacionadas a restrições alimentares;
  - Cumprimento das normas sanitárias e legais aplicáveis.

O Prato Seguro não garante ausência de contaminação cruzada nem segurança absoluta em relação a alergênicos.

7. Limitação de Responsabilidade
O Prato Seguro:
  - Não se responsabiliza por decisões tomadas com base nas informações exibidas;
  - Não garante funcionamento ininterrupto ou livre de erros;
  - Não se responsabiliza por danos diretos ou indiretos decorrentes do uso da plataforma.

8. Propriedade Intelectual
Todo o conteúdo da plataforma (marca, layout, textos, imagens, código-fonte, logotipos e demais elementos) pertence à Prato Seguro Tecnologia LTDA, sendo protegido pela legislação de direitos autorais.
É proibida qualquer reprodução, total ou parcial, sem autorização expressa.

9. Alterações dos Termos
Estes Termos de Uso podem ser alterados a qualquer momento.
O uso contínuo da plataforma após eventuais alterações implica aceitação automática das novas condições.

10. Legislação e Foro
Estes Termos são regidos pelas leis da República Federativa do Brasil, ficando eleito o foro da comarca de Curitiba/PR, com renúncia a qualquer outro, por mais privilegiado que seja.

11. Planos, Assinaturas, Acesso Premium e Cancelamento
11.1 Acesso Premium por Tempo Indeterminado
Atualmente, o Prato Seguro disponibiliza aos usuários acesso aos recursos e funcionalidades Premium por tempo indeterminado, sem a cobrança de valores, como parte de uma fase promocional, experimental ou de disponibilização inicial da plataforma.

Este acesso gratuito aos recursos Premium não caracteriza concessão vitalícia, podendo ser alterado, limitado ou encerrado a critério da Prato Seguro, respeitados os princípios da transparência e da boa-fé.

Caso o modelo de acesso aos recursos Premium venha a ser modificado no futuro, incluindo a implementação de planos pagos, assinaturas ou restrições de funcionalidades, o usuário será devidamente informado com antecedência mínima de 30 (trinta) dias, por meio do aplicativo, site, e/ou outros canais oficiais de comunicação.

11.2 Planos de Assinatura
O aplicativo Prato Seguro poderá, a seu exclusivo critério, oferecer planos de assinatura nas modalidades Trimestral e Anual, ou em outras modalidades que venham a ser disponibilizadas, conforme as opções apresentadas de forma clara e transparente no aplicativo no momento da contratação.

A contratação de qualquer plano de assinatura será sempre opcional e condicionada à manifestação expressa de consentimento do usuário, observadas as regras e políticas da Apple App Store ou Google Play Store, conforme a plataforma utilizada.

11.3 Cancelamento, Renovação e Reembolso
O usuário poderá cancelar a assinatura a qualquer momento por meio das ferramentas de gerenciamento disponibilizadas pela Apple App Store ou Google Play Store, de acordo com a plataforma utilizada na contratação.

O cancelamento interrompe apenas a renovação automática da assinatura, permanecendo o acesso aos recursos e benefícios do plano ativo até o final do período já pago (trimestral, anual ou outro).

Os valores pagos não são reembolsáveis, de forma total ou proporcional, inclusive em caso de cancelamento antecipado, salvo quando houver obrigação legal em sentido contrário, uma vez que os serviços e funcionalidades são disponibilizados imediatamente após a confirmação da assinatura.

As regras de cobrança, renovação, cancelamento e eventuais reembolsos também seguem as políticas da loja de aplicativos utilizada no momento da contratação.

Ao realizar a assinatura de qualquer plano, o usuário declara estar ciente e de acordo com estas condições, tendo acesso prévio, claro e transparente às informações antes da confirmação da contratação.''';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Termos de Uso'),
        elevation: 0,
        backgroundColor: theme.scaffoldBackgroundColor,
        foregroundColor: theme.textTheme.bodyLarge?.color,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          child: SingleChildScrollView(
            child: Text(
              _termsText,
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ),
      ),
    );
  }
}
