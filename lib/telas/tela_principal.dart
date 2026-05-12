import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:saude_para_todos/main.dart';
import 'package:saude_para_todos/telas/autenticacao_tela.dart';
import 'package:saude_para_todos/telas/editar_dados_tela.dart';
import 'package:saude_para_todos/telas/diario_tela.dart';
import 'package:saude_para_todos/telas/preferencias_tela.dart';

class TelaPrincipal extends StatefulWidget {
  const TelaPrincipal({super.key});

  @override
  State<TelaPrincipal> createState() => _TelaPrincipalState();
}

class _TelaPrincipalState extends State<TelaPrincipal> {
  String _primeiroNome = "Carregando...";
  String _email = "...";
  String _avatarTipo = "neutro";

  final Color azulPrincipal = const Color(0xFF1E5EFE);

  @override
  void initState() {
    super.initState();
    _buscarDadosUsuario();
  }

  Future<void> _buscarDadosUsuario() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      if (mounted) setState(() => _email = user.email ?? "");
      try {
        final doc = await FirebaseFirestore.instance
            .collection('usuarios')
            .doc(user.uid)
            .get();
            
        if (!mounted) return;

        if (doc.exists) {
          setState(() {
            String nomeCompleto = (doc.data()?['nome'] ?? 'Paciente').toString();
            _primeiroNome = nomeCompleto.split(' ').first;
            _avatarTipo = (doc.data()?['avatar_tipo'] ?? 'neutro').toString();
          });
        }
      } catch (_) {
        if (mounted) setState(() => _primeiroNome = "Usuário");
      }
    }
  }

  Future<void> _sair() async {
    Navigator.pop(context); // Fecha o menu antes de sair
    await FirebaseAuth.instance.signOut();
    if (!mounted) return; 

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const AutenticacaoTela()),
    );
  }

  IconData _getIconeAvatar() {
    if (_avatarTipo == 'masculino') return Icons.face;
    if (_avatarTipo == 'feminino') return Icons.face_3;
    return Icons.person;
  }

  void _mostrarAvisoEmDesenvolvimento() {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.construction, color: Colors.white),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                "Funcionalidade em desenvolvimento! 🚀",
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        backgroundColor: azulPrincipal,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        margin: const EdgeInsets.only(bottom: 20, left: 20, right: 20),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    Color corFundo = Theme.of(context).scaffoldBackgroundColor;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        systemNavigationBarColor: corFundo,
        systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        statusBarColor: azulPrincipal,
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: corFundo,

        appBar: AppBar(
          backgroundColor: azulPrincipal,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
          title: const Text(
            "Saúde Para Todos",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),

        drawer: Drawer(
          backgroundColor: corFundo,
          surfaceTintColor: Colors.transparent, 
          // SOLUÇÃO DEFINITIVA: SafeArea impede que o menu "vaze" para as bordas do sistema
          child: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      UserAccountsDrawerHeader(
                        decoration: BoxDecoration(color: azulPrincipal),
                        currentAccountPicture: CircleAvatar(
                          backgroundColor: Colors.white,
                          child: Icon(_getIconeAvatar(), size: 40, color: azulPrincipal),
                        ),
                        accountName: Text(
                          _primeiroNome,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                        accountEmail: Text(_email),
                      ),

                      ListTile(
                        leading: const Icon(Icons.edit_note),
                        title: const Text("Editar Perfil"),
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const EditarDadosTela()),
                          ).then((_) {
                            _buscarDadosUsuario(); 
                          });
                        },
                      ),

                      ListTile(
                        leading: const Icon(Icons.security),
                        title: const Text("Segurança e Acesso"),
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const PreferenciasTela()),
                          );
                        },
                      ),

                      const Divider(),
                      const Padding(
                        padding: EdgeInsets.only(left: 16, top: 10, bottom: 5),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text("APARÊNCIA",
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                        ),
                      ),

                      SwitchListTile(
                        secondary: Icon(isDark ? Icons.dark_mode : Icons.light_mode),
                        title: const Text("Modo Escuro"),
                        value: isDark,
                        onChanged: (bool valor) {
                          (MyApp.of(context) as dynamic)
                              ?.alternarTema(valor ? ThemeMode.dark : ThemeMode.light);
                        },
                      ),

                      ListTile(
                        leading: const Icon(Icons.settings_brightness),
                        title: const Text("Usar padrão do sistema"),
                        onTap: () {
                          (MyApp.of(context) as dynamic)?.alternarTema(ThemeMode.system);
                          Navigator.pop(context);
                        },
                      ),
                    ],
                  ),
                ),

                // O BOTÃO DE SAIR: Agora com Padding para ficar bem posicionado e longe do limite inferior
                const Divider(),
                Padding(
                  padding: const EdgeInsets.only(bottom: 24.0, top: 8.0),
                  child: ListTile(
                    leading: const Icon(Icons.exit_to_app, color: Colors.red),
                    title: const Text("Sair da Conta", style: TextStyle(color: Colors.red)),
                    onTap: _sair,
                  ),
                ),
              ],
            ),
          ),
        ),

        body: SingleChildScrollView(
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
                decoration: BoxDecoration(
                  color: azulPrincipal,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                  ),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.favorite, color: Colors.white, size: 48),
                    const SizedBox(height: 10),
                    Text(
                      "Olá, $_primeiroNome!",
                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      "Acompanhe sua saúde de perto todos os dias.",
                      style: TextStyle(fontSize: 14, color: Colors.white70),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 15,
                  mainAxisSpacing: 15,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _construirBotao(context, "Meu Diário", Icons.book, () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const DiarioTela()));
                    }),
                    _construirBotao(context, "Alarmes", Icons.notifications_active, _mostrarAvisoEmDesenvolvimento),
                    _construirBotao(context, "Medicações", Icons.local_pharmacy, _mostrarAvisoEmDesenvolvimento),
                    _construirBotao(context, "Calendário", Icons.calendar_month, _mostrarAvisoEmDesenvolvimento),
                    _construirBotao(context, "Exames", Icons.biotech, _mostrarAvisoEmDesenvolvimento),
                    _construirBotao(context, "Chatbot", Icons.smart_toy, _mostrarAvisoEmDesenvolvimento),
                    _construirBotao(context, "SOS", Icons.emergency_share, _mostrarAvisoEmDesenvolvimento),
                    _construirBotao(context, "Dicas", Icons.lightbulb, _mostrarAvisoEmDesenvolvimento),
                  ],
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _construirBotao(
      BuildContext context, String titulo, IconData icone, VoidCallback onTap) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: azulPrincipal.withValues(alpha: 0.08),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: isDark
                      ? azulPrincipal.withValues(alpha: 0.1)
                      : const Color(0xFFEEF4FF),
                  shape: BoxShape.circle,
                ),
                child: Icon(icone, size: 36, color: azulPrincipal),
              ),
              const SizedBox(height: 15),
              Text(
                titulo,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}