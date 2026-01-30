import 'package:flutter/material.dart';

class BusinessSealsPolicyScreen extends StatelessWidget {
	const BusinessSealsPolicyScreen({super.key});

	static const String _title = 'Política de Selos – Prato Seguro';

	@override
	Widget build(BuildContext context) {
		return Scaffold(
			backgroundColor: const Color(0xFFF7F8FA),
			appBar: AppBar(
				title: const Text('Política de Selos'),
				elevation: 0,
			),
			body: SafeArea(
				child: SingleChildScrollView(
					padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
					child: Column(
						crossAxisAlignment: CrossAxisAlignment.start,
						children: [
							_buildHeader(),
							const SizedBox(height: 16),
							_buildSectionTitle('🏅 Objetivo dos Selos Prato Seguro'),
							const SizedBox(height: 8),
							const Text(
								'Os Selos Prato Seguro têm como objetivo informar, orientar e aumentar a segurança de pessoas com restrições alimentares, classificando estabelecimentos de acordo com níveis distintos de verificação e confiabilidade.\n\n'
								'Os selos não substituem fiscalização sanitária oficial, nem garantem risco zero, mas oferecem camadas progressivas de transparência e confiança.',
								style: TextStyle(fontSize: 13, height: 1.4),
							),
							const SizedBox(height: 16),
							_buildSectionTitle('Estrutura dos Selos'),
							const SizedBox(height: 8),
							const Text(
								'A Prato Seguro adota três níveis de selo, cada um com critérios, responsabilidades e graus de validação distintos:\n'
								'1. Selo Básico\n'
								'2. Selo Intermediário\n'
								'3. Selo Técnico\n\n'
								'Cada selo é independente e representa um nível diferente de comprovação.',
								style: TextStyle(fontSize: 13, height: 1.4),
							),
							const SizedBox(height: 12),
							_buildSealsRow(),
							const SizedBox(height: 20),
							_buildSealSection(
								title: 'SELO BÁSICO – AVALIAÇÃO DA COMUNIDADE',
								imagePath: 'assets/icons/selo1.png',
								color: Colors.green,
								content: const [
									Text(
										'🔍 O que é\n'
										'O Selo Básico é concedido com base exclusivamente na experiência real dos usuários da plataforma.\n\n'
										'Ele reflete a percepção da comunidade sobre o cuidado, atendimento e transparência do estabelecimento em relação às restrições alimentares.',
										style: TextStyle(fontSize: 13, height: 1.4),
									),
									SizedBox(height: 8),
									Text(
										'📌 Critérios de Concessão\n'
										'• Avaliações feitas por usuários cadastrados;\n'
										'• Notas e comentários relacionados à segurança alimentar;\n'
										'• Histórico de avaliações positivas recorrentes;\n'
										'• Ausência de denúncias graves não resolvidas.\n\n'
										'📊 O selo pode ser dinâmico, variando conforme novas avaliações.',
										style: TextStyle(fontSize: 13, height: 1.4),
									),
									SizedBox(height: 8),
									Text(
										'⚠️ Limitações Importantes\n'
										'• O Selo Básico não envolve análise técnica ou documental;\n'
										'• Baseia-se apenas na experiência subjetiva dos usuários;\n'
										'• Não garante ausência de contaminação cruzada.\n\n'
										'📌 Por isso, deve ser interpretado como indicador de confiança comunitária, e não certificação técnica.',
										style: TextStyle(fontSize: 13, height: 1.4),
									),
								],
							),
							const SizedBox(height: 20),
							_buildSealSection(
								title: 'SELO INTERMEDIÁRIO – DOCUMENTAÇÃO DO ESTABELECIMENTO',
								imagePath: 'assets/icons/selo2.png',
								color: Colors.amber,
								content: const [
									Text(
										'🔍 O que é\n'
										'O Selo Intermediário é concedido quando o estabelecimento envia documentação própria, declarando e comprovando práticas relacionadas à segurança alimentar.\n\n'
										'Esse selo representa um compromisso formal do estabelecimento com boas práticas.',
										style: TextStyle(fontSize: 13, height: 1.4),
									),
									SizedBox(height: 8),
									Text(
										'📄 Documentação Avaliada\n'
										'Podem ser solicitados, entre outros:\n'
										'• Alvará de funcionamento;\n'
										'• Licença sanitária vigente;\n'
										'• Declarações internas sobre:\n'
										'  - manipulação de alimentos;\n'
										'  - controle de alergênicos;\n'
										'  - separação de utensílios;\n'
										'• Procedimentos internos documentados;\n'
										'• Certificados ou treinamentos internos da equipe (quando houver).',
										style: TextStyle(fontSize: 13, height: 1.4),
									),
									SizedBox(height: 8),
									Text(
										'🛠️ Processo\n'
										'1. Envio dos documentos pelo aplicativo ou painel do estabelecimento;\n'
										'2. Análise documental pela equipe da Prato Seguro;\n'
										'3. Validação formal do envio e da consistência das informações;\n'
										'4. Concessão do selo, se aprovado.',
										style: TextStyle(fontSize: 13, height: 1.4),
									),
									SizedBox(height: 8),
									Text(
										'⚠️ Limitações Importantes\n'
										'• A análise é documental, não presencial;\n'
										'• A Prato Seguro não audita fisicamente o local neste nível;\n'
										'• As informações são de responsabilidade do próprio estabelecimento.\n\n'
										'📌 O selo indica maior nível de comprometimento, mas ainda não equivale a uma certificação técnica independente.',
										style: TextStyle(fontSize: 13, height: 1.4),
									),
								],
							),
							const SizedBox(height: 20),
							_buildSealSection(
								title: 'SELO TÉCNICO – VALIDAÇÃO ESPECIALIZADA',
								imagePath: 'assets/icons/selo 3.png',
								color: Colors.blue,
								content: const [
									Text(
										'🔍 O que é\n'
										'O Selo Técnico é o nível mais alto de verificação da Prato Seguro.\n\n'
										'Ele é concedido apenas a estabelecimentos que apresentam embasamento técnico comprovado, podendo envolver testes laboratoriais, laudos técnicos e validações especializadas.',
										style: TextStyle(fontSize: 13, height: 1.4),
									),
									SizedBox(height: 8),
									Text(
										'🧪 Critérios Técnicos\n'
										'Podem ser exigidos:\n'
										'• Laudos laboratoriais de ausência ou controle de alergênicos;\n'
										'• Testes específicos (ex.: glúten, lactose, proteínas do leite);\n'
										'• Relatórios técnicos assinados por profissionais habilitados;\n'
										'• Certificações externas reconhecidas;\n'
										'• Protocolos rígidos de prevenção de contaminação cruzada.',
										style: TextStyle(fontSize: 13, height: 1.4),
									),
									SizedBox(height: 8),
									Text(
										'👨‍🔬 Avaliação\n'
										'• Análise técnica aprofundada da documentação;\n'
										'• Possível validação por parceiros técnicos ou especialistas;\n'
										'• Revisão periódica, conforme critérios definidos pela plataforma.',
										style: TextStyle(fontSize: 13, height: 1.4),
									),
									SizedBox(height: 8),
									Text(
										'⚠️ Limitações Importantes\n'
										'• Mesmo com o Selo Técnico, não existe risco zero;\n'
										'• O selo reflete o estado do estabelecimento no momento da avaliação;\n'
										'• Mudanças de processos podem impactar a validade do selo.',
										style: TextStyle(fontSize: 13, height: 1.4),
									),
								],
							),
							const SizedBox(height: 20),
							_buildSectionTitle('3. Atualização, Suspensão e Perda de Selos'),
							const SizedBox(height: 8),
							const Text(
								'A Prato Seguro se reserva o direito de:\n'
								'• revisar selos periodicamente;\n'
								'• suspender ou remover selos em caso de:\n'
								'  - denúncias relevantes;\n'
								'  - inconsistência de informações;\n'
								'  - documentos vencidos;\n'
								'  - descumprimento dos critérios.',
								style: TextStyle(fontSize: 13, height: 1.4),
							),
							const SizedBox(height: 16),
							_buildSectionTitle('4. Transparência com o Usuário'),
							const SizedBox(height: 8),
							const Text(
								'Em todos os casos:\n'
								'• O tipo de selo será claramente identificado no app e no site;\n'
								'• O usuário poderá consultar:\n'
								'  - o significado de cada selo;\n'
								'  - seus critérios e limitações;\n\n'
								'A plataforma incentiva decisões conscientes e informadas.',
								style: TextStyle(fontSize: 13, height: 1.4),
							),
							const SizedBox(height: 16),
							_buildSectionTitle('5. Isenção de Responsabilidade'),
							const SizedBox(height: 8),
							const Text(
								'Os selos da Prato Seguro:\n'
								'• não substituem fiscalização sanitária oficial;\n'
								'• não garantem segurança absoluta;\n'
								'• servem como ferramenta informativa e de apoio à decisão.\n\n'
								'A responsabilidade final pela escolha do consumo permanece com o usuário.',
								style: TextStyle(fontSize: 13, height: 1.4),
							),
						],
					),
				),
			),
		);
	}

	Widget _buildHeader() {
		return Container(
			width: double.infinity,
			padding: const EdgeInsets.all(16),
			decoration: BoxDecoration(
				color: Colors.white,
				borderRadius: BorderRadius.circular(16),
				boxShadow: [
					BoxShadow(
						color: Colors.black.withOpacity(0.06),
						blurRadius: 12,
						offset: const Offset(0, 4),
					),
				],
			),
			child: Row(
				crossAxisAlignment: CrossAxisAlignment.start,
				children: [
					Container(
						width: 56,
						height: 56,
						decoration: BoxDecoration(
							color: Colors.green.shade50,
							borderRadius: BorderRadius.circular(14),
						),
						child: const Icon(
							Icons.verified_rounded,
							color: Colors.green,
							size: 30,
						),
					),
					const SizedBox(width: 12),
					const Expanded(
						child: Column(
							crossAxisAlignment: CrossAxisAlignment.start,
							children: [
								Text(
									_title,
									style: TextStyle(
										fontSize: 16,
										fontWeight: FontWeight.bold,
									),
								),
								SizedBox(height: 6),
								Text(
									'Entenda os níveis, critérios e limitações dos selos para orientar decisões mais seguras.',
									style: TextStyle(
										fontSize: 12,
										color: Colors.grey,
										height: 1.4,
									),
								),
							],
						),
					),
				],
			),
		);
	}

	Widget _buildSectionTitle(String title) {
		return Text(
			title,
			style: TextStyle(
				fontSize: 14,
				fontWeight: FontWeight.w600,
				color: Colors.grey.shade800,
			),
		);
	}

	Widget _buildSealsRow() {
		return Row(
			children: [
				Expanded(
					child: _buildSealPreview(
						label: 'Básico',
						imagePath: 'assets/icons/selo1.png',
						color: Colors.green,
					),
				),
				const SizedBox(width: 12),
				Expanded(
					child: _buildSealPreview(
						label: 'Intermediário',
						imagePath: 'assets/icons/selo2.png',
						color: Colors.amber,
					),
				),
				const SizedBox(width: 12),
				Expanded(
					child: _buildSealPreview(
						label: 'Técnico',
						imagePath: 'assets/icons/selo 3.png',
						color: Colors.blue,
					),
				),
			],
		);
	}

	Widget _buildSealPreview({
		required String label,
		required String imagePath,
		required Color color,
	}) {
		return Container(
			padding: const EdgeInsets.all(12),
			decoration: BoxDecoration(
				color: Colors.white,
				borderRadius: BorderRadius.circular(14),
				border: Border.all(color: color.withOpacity(0.2)),
			),
			child: Column(
				children: [
					Container(
						width: 72,
						height: 72,
						padding: const EdgeInsets.all(8),
						decoration: BoxDecoration(
							color: color.withOpacity(0.08),
							borderRadius: BorderRadius.circular(14),
						),
						child: Image.asset(
							imagePath,
							fit: BoxFit.contain,
						),
					),
					const SizedBox(height: 8),
					Text(
						label,
						textAlign: TextAlign.center,
						style: TextStyle(
							fontSize: 11,
							fontWeight: FontWeight.w600,
							color: color,
						),
					),
				],
			),
		);
	}

	Widget _buildSealSection({
		required String title,
		required String imagePath,
		required Color color,
		required List<Widget> content,
	}) {
		return Container(
			padding: const EdgeInsets.all(16),
			decoration: BoxDecoration(
				color: Colors.white,
				borderRadius: BorderRadius.circular(16),
				boxShadow: [
					BoxShadow(
						color: Colors.black.withOpacity(0.05),
						blurRadius: 10,
						offset: const Offset(0, 2),
					),
				],
			),
			child: Column(
				crossAxisAlignment: CrossAxisAlignment.start,
				children: [
					Row(
						crossAxisAlignment: CrossAxisAlignment.start,
						children: [
							Container(
								width: 78,
								height: 78,
								padding: const EdgeInsets.all(10),
								decoration: BoxDecoration(
									color: color.withOpacity(0.1),
									borderRadius: BorderRadius.circular(16),
								),
								child: Image.asset(
									imagePath,
									fit: BoxFit.contain,
								),
							),
							const SizedBox(width: 12),
							Expanded(
								child: Text(
									title,
									style: TextStyle(
										fontSize: 14,
										fontWeight: FontWeight.w700,
										color: color,
									),
								),
							),
						],
					),
					const SizedBox(height: 12),
					...content,
				],
			),
		);
	}
}
