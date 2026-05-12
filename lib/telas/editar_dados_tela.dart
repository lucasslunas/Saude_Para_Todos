import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:saude_para_todos/telas/autenticacao_tela.dart';

class EditarDadosTela extends StatefulWidget {
  const EditarDadosTela({super.key});

  @override
  State<EditarDadosTela> createState() => _EditarDadosTelaState();
}

class _EditarDadosTelaState extends State<EditarDadosTela> {
  final _nomeController = TextEditingController();
  final _doencaController = TextEditingController();
  
  // 1. Mudamos o padrão inicial para 'neutro'
  String _avatarSelecionado = 'neutro';
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('usuarios')
            .doc(user.uid)
            .get();
        if (doc.exists) {
          if (mounted) {
            setState(() {
              _nomeController.text = doc['nome'] ?? '';
              _doencaController.text = doc['doencaCronica'] ?? '';
              // 2. Se não vier nada do banco, o fallback agora é 'neutro'
              _avatarSelecionado = doc['avatar_tipo'] ?? 'neutro';
              _carregando = false;
            });
          }
        }
      } catch (e) {
        if (mounted) setState(() => _carregando = false);
      }
    } else {
      if (mounted) setState(() => _carregando = false);
    }
  }

  Future<void> _salvar() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(user.uid)
          .update({
        'nome': _nomeController.text,
        'doencaCronica': _doencaController.text,
        'avatar_tipo': _avatarSelecionado, // O avatar escolhido é salvo aqui
      });
      
      if (!mounted) return; 
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Perfil atualizado! 🎉")),
      );
      Navigator.pop(context);
    }
  }

  Future<void> _dialogoAlterarSenha() async {
    final senhaController = TextEditingController();
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        title: Text("Nova Senha",
            style: TextStyle(color: isDark ? Colors.white : Colors.black)),
        content: TextField(
          controller: senhaController,
          obscureText: true,
          style: TextStyle(color: isDark ? Colors.white : Colors.black),
          decoration: InputDecoration(
            hintText: "Digite a nova senha",
            hintStyle:
                TextStyle(color: isDark ? Colors.white54 : Colors.black54),
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child:
                  const Text("Cancelar", style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () async {
              try {
                await FirebaseAuth.instance.currentUser
                    ?.updatePassword(senhaController.text);
                    
                if (!mounted) return; 
                Navigator.pop(context); 
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text("Senha alterada com sucesso! 🔒")));
              } on FirebaseAuthException {
                if (!mounted) return;
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text(
                        "Erro: Saia do app, faça login novamente e tente alterar.")));
              }
            },
            child: const Text("Atualizar"),
          ),
        ],
      ),
    );
  }

  Future<void> _dialogoExcluirConta() async {
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        title: const Text("Excluir Conta? ⚠️",
            style: TextStyle(color: Colors.red)),
        content: Text(
            "Tem certeza? Isso apagará todos os seus dados e não poderá ser desfeito.",
            style: TextStyle(color: isDark ? Colors.white70 : Colors.black87)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child:
                  const Text("Cancelar", style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              final user = FirebaseAuth.instance.currentUser;
              if (user != null) {
                try {
                  await FirebaseFirestore.instance
                      .collection('usuarios')
                      .doc(user.uid)
                      .delete();
                  await user.delete();

                  if (!mounted) return; 
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const AutenticacaoTela()),
                    (Route<dynamic> route) => false,
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Conta excluída.")));
                } on FirebaseAuthException {
                  if (!mounted) return;
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text(
                          "Por segurança, faça login novamente antes de excluir a conta.")));
                }
              }
            },
            child: const Text("Sim, excluir",
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    Color corTextoAltoContraste =
        isDark ? Colors.white : const Color(0xFF0F172A);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Editar Perfil",
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        foregroundColor: isDark ? Colors.white : Colors.black,
        elevation: 0,
      ),
      body: _carregando
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Text("Escolha seu Avatar:",
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: corTextoAltoContraste)),
                  ),
                  const SizedBox(height: 20),
                  
                  // 3. Grade com os 3 avatares lado a lado, distribuídos por igual
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _botaoAvatar('neutro', Icons.person, isDark),
                      _botaoAvatar('masculino', Icons.face, isDark),
                      _botaoAvatar('feminino', Icons.face_3, isDark),
                    ],
                  ),
                  const SizedBox(height: 30),

                  // Campos de Texto Adaptados
                  TextField(
                    controller: _nomeController,
                    style: TextStyle(color: corTextoAltoContraste),
                    decoration: InputDecoration(
                      labelText: "Nome",
                      labelStyle: TextStyle(
                          color: isDark ? Colors.white70 : Colors.black87),
                      filled: true,
                      fillColor:
                          isDark ? const Color(0xFF1E293B) : Colors.white,
                      border: const OutlineInputBorder(),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                            color: isDark ? Colors.white38 : Colors.black38),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _doencaController,
                    style: TextStyle(color: corTextoAltoContraste),
                    decoration: InputDecoration(
                      labelText: "Doença Crônica",
                      labelStyle: TextStyle(
                          color: isDark ? Colors.white70 : Colors.black87),
                      filled: true,
                      fillColor:
                          isDark ? const Color(0xFF1E293B) : Colors.white,
                      border: const OutlineInputBorder(),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                            color: isDark ? Colors.white38 : Colors.black38),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),

                  ElevatedButton(
                    onPressed: _salvar,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text("SALVAR ALTERAÇÕES",
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold)),
                  ),

                  // --- ZONA DE CONFIGURAÇÕES ---
                  const SizedBox(height: 40),
                  Divider(color: isDark ? Colors.white24 : Colors.black26),
                  const SizedBox(height: 10),
                  Center(
                    child: Text("Segurança da Conta",
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: corTextoAltoContraste)),
                  ),
                  const SizedBox(height: 20),

                  OutlinedButton.icon(
                    onPressed: _dialogoAlterarSenha,
                    icon: const Icon(Icons.lock_reset, color: Colors.blue),
                    label: const Text("Alterar Minha Senha",
                        style: TextStyle(
                            color: Colors.blue, fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      side: const BorderSide(color: Colors.blue),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 15),

                  OutlinedButton.icon(
                    onPressed: _dialogoExcluirConta,
                    icon: const Icon(Icons.delete_forever, color: Colors.red),
                    label: const Text("Excluir Conta Permanentemente",
                        style: TextStyle(
                            color: Colors.red, fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  )
                ],
              ),
            ),
    );
  }

  // 4. Função atualizada para renderizar os 3 tipos corretamente
  Widget _botaoAvatar(String tipo, IconData icone, bool isDark) {
    bool selecionado = _avatarSelecionado == tipo;
    Color corDesabilitada = isDark ? Colors.white38 : Colors.grey;

    String rotulo = "Neutro";
    if (tipo == 'masculino') rotulo = "Masculino";
    if (tipo == 'feminino') rotulo = "Feminino";

    return GestureDetector(
      onTap: () => setState(() => _avatarSelecionado = tipo),
      child: Column(
        children: [
          CircleAvatar(
            radius: 35, // Tamanho sutilmente reduzido para caber os três
            backgroundColor: selecionado
                ? Colors.blue
                : (isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0)),
            child: Icon(icone,
                size: 40, color: selecionado ? Colors.white : corDesabilitada),
          ),
          const SizedBox(height: 8),
          Text(
            rotulo,
            style: TextStyle(
                fontWeight: selecionado ? FontWeight.bold : FontWeight.normal,
                color: selecionado ? Colors.blue : corDesabilitada),
          ),
        ],
      ),
    );
  }
}