import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../providers/locale_provider.dart';
import '../screens/login_screen.dart';
import '../screens/faq_screen.dart';
import '../screens/terms_screen.dart';
import '../screens/privacy_policy_screen.dart';
import '../screens/seals_policy_screen.dart';

// Telas existentes reutilizadas (devem existir no projeto)
import '../screens/coupons_screen.dart';
import '../screens/register_trail_screen.dart';
import '../screens/refer_establishment_screen.dart';
import '../screens/leaderboard_screen.dart';
import '../screens/offline_mode_screen.dart';

class SettingsContent extends StatefulWidget {
  // Callbacks opcionais para permitir controle externo (ex.: abrir perfil via contexto local)
  final VoidCallback? onOpenPreferences;

  const SettingsContent({Key? key, this.onOpenPreferences}) : super(key: key);

  @override
  State<SettingsContent> createState() => _SettingsContentState();
}

class _SettingsContentState extends State<SettingsContent> {
  bool _working = false;

  Future<void> _abrirLink(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Não foi possível abrir o link')));
    }
  }

  Future<void> _confirmarExcluirConta() async {
    final usuario = fb.FirebaseAuth.instance.currentUser;
    if (usuario == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nenhum usuário logado'), backgroundColor: Colors.red));
      return;
    }

    final confirmado = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir conta'),
        content: const Text('Deseja excluir sua conta permanentemente? Esta ação não pode ser desfeita.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Excluir', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirmado != true) return;

    setState(() => _working = true);
    try {
      final uid = usuario.uid;
      await FirebaseFirestore.instance.collection('users').doc(uid).delete().catchError((_) {});
      await usuario.delete();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Conta excluída com sucesso')));
      await fb.FirebaseAuth.instance.signOut();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const LoginScreen()), (r) => false);
    } on fb.FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message ?? 'Erro ao excluir conta'), backgroundColor: Colors.red));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _sair() async {
    setState(() => _working = true);
    await fb.FirebaseAuth.instance.signOut();
    setState(() => _working = false);
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const LoginScreen()), (r) => false);
  }

  // Navega para telas já existentes (reutiliza comportamento da aba Sobre)
  void _abrirPreferencias() {
    // Se o pai forneceu um callback (ex.: user_profile_screen com contexto local), usa ele.
    if (widget.onOpenPreferences != null) {
      widget.onOpenPreferences!();
      return;
    }

    // Senão tenta usar uma rota nomeada '/profile'. Se a rota não existir, mostra uma mensagem.
    try {
      final nav = Navigator.of(context);
      if (nav.canPop() || ModalRoute.of(context) != null) {
        nav.pushNamed('/profile');
      } else {
        throw Exception('Rota /profile não disponível');
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Abra seu perfil para editar preferências')));
    }
  }

  void _abrirCupons() {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CouponsScreen()));
  }

  void _abrirModoViagem() {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const OfflineModeScreen()));
  }

  void _abrirRegistrarTrilha() {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const RegisterTrailScreen()));
  }

  void _abrirIndicarEstabelecimento() {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ReferEstablishmentScreen()));
  }

  void _abrirRanking() {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LeaderboardScreen()));
  }

  void _abrirFAQ() {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const FaqScreen()));
  }

  void _abrirPoliticaSelos() {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const BusinessSealsPolicyScreen()));
  }

  void _abrirTermos() {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const TermsScreen()));
  }

  void _abrirPrivacidade() {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()));
  }

  Future<void> _abrirSeletorIdioma() async {
    final localeProvider = Provider.of<LocaleProvider>(context, listen: false);
    final atual = localeProvider.locale.languageCode;

    final escolhido = await showModalBottomSheet<String?>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(title: Text('Idioma', style: const TextStyle(fontWeight: FontWeight.w600))),
            RadioListTile<String>(
              value: 'pt',
              groupValue: atual,
              title: const Text('Português'),
              secondary: const Text('🇧🇷'),
              onChanged: (v) => Navigator.of(ctx).pop(v),
            ),
            RadioListTile<String>(
              value: 'en',
              groupValue: atual,
              title: const Text('English'),
              secondary: const Text('🇺🇸'),
              onChanged: (v) => Navigator.of(ctx).pop(v),
            ),
            RadioListTile<String>(
              value: 'es',
              groupValue: atual,
              title: const Text('Español'),
              secondary: const Text('🇪🇸'),
              onChanged: (v) => Navigator.of(ctx).pop(v),
            ),
            const SizedBox(height: 8),
            TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancelar')),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );

    if (escolhido != null && escolhido != atual) {
      localeProvider.selectLanguage(escolhido);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Idioma alterado')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Usando ListView com shrinkWrap:true e física desativada para garantir que
    // o widget calcule sua própria altura quando embutido em outro scrollable.
    return ListView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      children: [
        // Ações principais (FAQ, Preferências, Cupons, Modo Viagem)
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          color: theme.cardColor,
          child: Column(
            children: [
              ListTile(
                dense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16.0),
                leading: const Icon(Icons.help_outline, size: 20),
                title: const Text('Perguntas Frequentes'),
                trailing: const Icon(Icons.chevron_right, size: 20),
                onTap: _abrirFAQ,
              ),
              const Divider(height: 1),
              ListTile(
                dense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16.0),
                leading: const Icon(Icons.shield_outlined, size: 20),
                title: const Text('Política de Selos'),
                subtitle: const Text('Entenda como os selos funcionam'),
                trailing: const Icon(Icons.chevron_right, size: 20),
                onTap: _abrirPoliticaSelos,
              ),
              const Divider(height: 1),
              ListTile(
                dense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16.0),
                leading: const Icon(Icons.restaurant_menu, size: 20),
                title: const Text('Preferências de comida segura'),
                subtitle: const Text('Defina suas restrições alimentares'),
                trailing: const Icon(Icons.chevron_right, size: 20),
                onTap: _abrirPreferencias,
              ),
              /*
              const Divider(height: 1),
              ListTile(
                dense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16.0),
                leading: const Icon(Icons.local_offer_outlined, size: 20),
                title: const Text('Meus cupons'),
                trailing: const Icon(Icons.chevron_right, size: 20),
                onTap: _abrirCupons,
              ),
              */
              const Divider(height: 1),
              ListTile(
                dense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16.0),
                leading: const Icon(Icons.flight_takeoff_outlined, size: 20),
                title: const Text('Modo viagem'),
                subtitle: const Text('Ajustes para uso offline em viagem'),
                trailing: const Icon(Icons.chevron_right, size: 20),
                onTap: _abrirModoViagem,
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Engajamento / Registro
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          color: theme.cardColor,
          child: Column(
            children: [
              ListTile(
                dense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16.0),
                leading: const Icon(Icons.directions_walk, size: 20),
                title: const Text('Registrar sua trilha'),
                subtitle: const Text('Compartilhe locais seguros que você visitou'),
                trailing: const Icon(Icons.chevron_right, size: 20),
                onTap: _abrirRegistrarTrilha,
              ),
              const Divider(height: 1),
              ListTile(
                dense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16.0),
                leading: const Icon(Icons.add_business_outlined, size: 20),
                title: const Text('Indicar estabelecimento'),
                subtitle: const Text('Ajude a comunidade indicando um local'),
                trailing: const Icon(Icons.chevron_right, size: 20),
                onTap: _abrirIndicarEstabelecimento,
              ),
              const Divider(height: 1),
              ListTile(
                dense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16.0),
                leading: const Icon(Icons.emoji_events_outlined, size: 20),
                title: const Text('Ranking'),
                subtitle: const Text('Veja os principais avaliadores'),
                trailing: const Icon(Icons.chevron_right, size: 20),
                onTap: _abrirRanking,
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Contatos
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          color: theme.cardColor,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Contatos', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: () => _abrirLink('mailto:suporte@pratoseguro.com'),
                  child: Row(
                    children: const [
                      Icon(Icons.email_outlined, size: 18),
                      SizedBox(width: 10),
                      Flexible(child: Text('suporte@pratoseguro.com')),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: () => _abrirLink('tel:+5511999999999'),
                  child: Row(
                    children: const [
                      Icon(Icons.phone_outlined, size: 18),
                      SizedBox(width: 10),
                      Flexible(child: Text('+55 11 99999-9999')),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: () => _abrirLink('https://instagram.com/pratoseguro'),
                  child: Row(
                    children: const [
                      Icon(Icons.camera_alt_outlined, size: 18),
                      SizedBox(width: 10),
                      Flexible(child: Text('@pratoseguro')),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Ações sensíveis (Excluir, Sair)
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          color: theme.cardColor,
          child: Column(
            children: [
              ListTile(
                dense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16.0),
                leading: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                title: const Text('Excluir conta', style: TextStyle(color: Colors.redAccent)),
                subtitle: const Text('Remover seus dados permanentemente'),
                onTap: _working ? null : _confirmarExcluirConta,
              ),
              const Divider(height: 1),
              ListTile(
                dense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16.0),
                leading: const Icon(Icons.exit_to_app, size: 20),
                title: const Text('Sair'),
                onTap: _working ? null : _sair,
              ),
            ],
          ),
        ),

        const SizedBox(height: 18),

        // Rodapé com Termos/Privacidade — caso o conteúdo seja embutido o app já pode ter footer,
        // mas deixamos os botões para completude.
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
          child: Row(
            children: [
              TextButton(
                onPressed: _abrirTermos,
                style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(50, 30), tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                child: const Text('Termos de Uso', style: TextStyle(decoration: TextDecoration.underline)),
              ),
              const Spacer(),
              TextButton(
                onPressed: _abrirPrivacidade,
                style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(50, 30), tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                child: const Text('Política de Privacidade', style: TextStyle(decoration: TextDecoration.underline)),
              ),
            ],
          ),
        ),

        if (_working)
          const Padding(
            padding: EdgeInsets.only(top: 8.0),
            child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
          ),

        const SizedBox(height: 8),
      ],
    );
  }
}

/// Use this Sliver wrapper when the parent is a CustomScrollView / Sliver list.
/// Example:
/// CustomScrollView(
///   slivers: [ SliverList(...), SettingsSliver(), ... ]
/// )
class SettingsSliver extends StatelessWidget {
  final VoidCallback? onOpenPreferences;
  const SettingsSliver({Key? key, this.onOpenPreferences}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: SettingsContent(onOpenPreferences: onOpenPreferences),
    );
  }
}