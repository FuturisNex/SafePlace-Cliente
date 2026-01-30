import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'empresa_guide_screen.dart';
import 'terms_screen.dart';
import 'privacy_policy_screen.dart';

class BusinessProfileScreen extends StatefulWidget {
  const BusinessProfileScreen({Key? key}) : super(key: key);

  @override
  State<BusinessProfileScreen> createState() => _BusinessProfileScreenState();
}

class _BusinessProfileScreenState extends State<BusinessProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? _user;
  Map<String, dynamic>? _businessData;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _user = _auth.currentUser;
    _loadBusinessData();
  }

  Future<void> _loadBusinessData() async {
    if (_user == null) return;
    try {
      final doc = await _firestore.collection('users').doc(_user!.uid).get();
      if (doc.exists) {
        setState(() {
          _businessData = doc.data();
        });
      }
    } catch (e) {
      // Silencioso: apenas loga e segue com dados do FirebaseAuth
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar dados da empresa: $e')),
        );
      }
    }
  }

  Future<void> _signOut() async {
    try {
      await _auth.signOut();
      if (!mounted) return;
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao sair: $e')),
      );
    }
  }

  Future<void> _confirmDeleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir conta'),
        content: const Text(
            'Tem certeza que deseja excluir esta conta da empresa? Esta ação removerá seus dados do aplicativo e não pode ser desfeita.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Excluir conta'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _deleteAccount();
    }
  }

  Future<void> _deleteAccount() async {
    if (_user == null) return;
    setState(() => _loading = true);

    try {
      final uid = _user!.uid;

      // 1) Remover documento no Firestore (collection 'users')
      try {
        await _firestore.collection('users').doc(uid).delete();
      } catch (e) {
        // Se falhar, não abortamos imediatamente — apenas avisamos
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Aviso: não foi possível remover dados no Firestore: $e')),
          );
        }
      }

      // 2) Tentar excluir usuário do FirebaseAuth
      try {
        await _user!.delete();
      } on FirebaseAuthException catch (fae) {
        // Caso precise de re-autenticação, informar usuário
        if (fae.code == 'requires-recent-login') {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Para excluir sua conta é necessário fazer login novamente por motivos de segurança. Por favor, faça logout e entre novamente para confirmar a exclusão.',
                ),
              ),
            );
          }
          // Em muitos fluxos, você pode encaminhar para tela de reauth aqui.
          setState(() => _loading = false);
          return;
        } else {
          rethrow;
        }
      }

      // 3) Logout e navegação para a tela inicial (ou login)
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Conta excluída com sucesso.')),
        );
        await _auth.signOut();
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao excluir conta: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _buildHeader() {
    final photoUrl = _businessData?['photoURL'] ?? _user?.photoURL;
    final displayName = _businessData?['name'] ?? _user?.displayName ?? 'Empresa';
    final email = _businessData?['email'] ?? _user?.email ?? '';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24.0),
      child: Column(
        children: [
          CircleAvatar(
            radius: 48,
            backgroundImage: photoUrl != null ? NetworkImage(photoUrl) as ImageProvider : null,
            child: photoUrl == null ? const Icon(Icons.storefront, size: 48) : null,
          ),
          const SizedBox(height: 12),
          Text(
            displayName,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          if (email.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(email, style: const TextStyle(color: Colors.grey)),
          ],
        ],
      ),
    );
  }

  Widget _buildActionList() {
    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.edit),
          title: const Text('Editar perfil'),
          subtitle: const Text('Atualizar informações da empresa'),
          onTap: () {
            // Placeholder: redirecionar para edição de perfil se existir
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Edição de perfil ainda não implementada aqui.')),
            );
          },
        ),
        const Divider(height: 1),
        ListTile(
          leading: const Icon(Icons.business),
          title: const Text('Meus estabelecimentos'),
          subtitle: const Text('Gerenciar estabelecimentos vinculados'),
          onTap: () {
            // Placeholder
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Abertura de lista de estabelecimentos (não implementado).')),
            );
          },
        ),
        const Divider(height: 1),
        ListTile(
          leading: const Icon(Icons.help),
          title: const Text('Suporte'),
          subtitle: const Text('Ajuda e contato'),
          onTap: () {
            // Placeholder
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Abrir suporte (não implementado).')),
            );
          },
        ),
        const Divider(height: 1),
        ListTile(
          leading: const Icon(Icons.book_outlined),
          title: const Text('Guia da Empresa'),
          subtitle: const Text('Como aproveitar ao máximo a plataforma'),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const EmpresaGuideScreen()),
            );
          },
        ),
        const Divider(height: 1),
        ListTile(
          leading: const Icon(Icons.description_outlined),
          title: const Text('Termos de Uso'),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const TermsScreen()),
            );
          },
        ),
        const Divider(height: 1),
        ListTile(
          leading: const Icon(Icons.privacy_tip_outlined),
          title: const Text('Política de Privacidade'),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()),
            );
          },
        ),
        const Divider(height: 1),
        ListTile(
          leading: const Icon(Icons.logout),
          title: const Text('Sair'),
          onTap: _signOut,
        ),
        const Divider(height: 1),
        ListTile(
          leading: const Icon(Icons.delete_forever, color: Colors.red),
          title: const Text('Excluir conta', style: TextStyle(color: Colors.red)),
          subtitle: const Text('Remover permanentemente os dados desta empresa'),
          onTap: _confirmDeleteAccount,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final body = SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        children: [
          _buildHeader(),
          const SizedBox(height: 8),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: _buildActionList(),
            ),
          ),
          const SizedBox(height: 24),
          if (_loading) const CircularProgressIndicator(),
        ],
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil da Empresa'),
        centerTitle: true,
      ),
      body: body,
    );
  }
}