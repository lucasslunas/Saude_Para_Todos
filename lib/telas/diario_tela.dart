import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DiarioTela extends StatefulWidget {
  const DiarioTela({super.key});

  @override
  State<DiarioTela> createState() => _DiarioTelaState();
}

class _DiarioTelaState extends State<DiarioTela> {
  final Color azulPrincipal = const Color(0xFF1E5EFE);

  static bool _tutorialExibido = false;
  final TextEditingController _anotacaoController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (!_tutorialExibido) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _mostrarPopupTutorial();
      });
    }
  }

  void _mostrarPopupTutorial() {
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor, // Fundo adaptável
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Icon(Icons.auto_awesome, color: azulPrincipal),
              const SizedBox(width: 10),
              Text(
                "Bem-vindo(a)!",
                style: TextStyle(color: isDark ? Colors.white : Colors.black),
              ),
            ],
          ),
          content: Text(
            "Este é o seu Diário de Saúde.\n\n"
            "Aqui você pode registrar sintomas, humores e acompanhar sua evolução diária.\n\n"
            "Agora você também pode editar ou excluir suas anotações!",
            style: TextStyle(
                fontSize: 16,
                height: 1.5,
                color: isDark ? Colors.white70 : Colors.black87 // Texto adaptável
                ),
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: azulPrincipal,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                setState(() => _tutorialExibido = true);
                Navigator.of(context).pop();
              },
              child: const Text("Entendi!",
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  // --- FORMULÁRIO UNIFICADO (Serve para Criar e Editar) ---
  void _abrirFormulario({String? docId, String? textoExistente}) {
    if (textoExistente != null) {
      _anotacaoController.text = textoExistente;
    } else {
      _anotacaoController.clear();
    }

    bool isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) {
        // CORREÇÃO: SafeArea em volta de tudo para garantir a margem inferior do Android
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 20,
              right: 20,
              top: 20,
            ),
            // CORREÇÃO: Adicionado SingleChildScrollView para rolar se faltar espaço
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    docId == null
                        ? "Como você está se sentindo?"
                        : "Editar registro",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 15),
                  TextField(
                    controller: _anotacaoController,
                    maxLines: 4,
                    style: TextStyle(color: isDark ? Colors.white : Colors.black),
                    decoration: InputDecoration(
                      hintText: "Descreva aqui...",
                      hintStyle: TextStyle(
                          color: isDark ? Colors.white54 : Colors.black54),
                      filled: true,
                      fillColor: isDark
                          ? const Color(0xFF1E293B)
                          : const Color(0xFFF8F9FA),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: azulPrincipal,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15)),
                      ),
                      onPressed: () => _salvarNoFirebase(docId: docId),
                      child: Text(
                        docId == null ? "Salvar Registro" : "Atualizar Registro",
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
                      ),
                    ),
                  ),
                  // CORREÇÃO: Adicionado mais um respiro em branco no fundo do pop-up
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // --- SALVAR OU ATUALIZAR ---
  Future<void> _salvarNoFirebase({String? docId}) async {
    if (_anotacaoController.text.trim().isEmpty) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final colecao = FirebaseFirestore.instance
          .collection('usuarios')
          .doc(user.uid)
          .collection('diario');

      try {
        if (docId == null) {
          // CRIAR NOVO
          await colecao.add({
            'anotacao': _anotacaoController.text.trim(),
            'data_registro': FieldValue.serverTimestamp(),
          });
        } else {
          // ATUALIZAR EXISTENTE
          await colecao.doc(docId).update({
            'anotacao': _anotacaoController.text.trim(),
            'data_edicao': FieldValue.serverTimestamp(),
          });
        }

        _anotacaoController.clear();
        if (!mounted) return;
        Navigator.pop(context);
      } catch (_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("Erro na operação.")));
      }
    }
  }

  // --- EXCLUIR REGISTRO ---
  Future<void> _excluirRegistro(String docId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(user.uid)
          .collection('diario')
          .doc(docId)
          .delete();

      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Registro excluído.")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: azulPrincipal,
        elevation: 0,
        centerTitle: true,
        title: const Text("Meu Diário",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: user == null
          ? const Center(child: Text("Usuário não autenticado."))
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('usuarios')
                  .doc(user.uid)
                  .collection('diario')
                  .orderBy('data_registro', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                      child: Text("Nenhum registro encontrado.",
                          style: TextStyle(
                              color: isDark
                                  ? Colors.white70
                                  : const Color(0xFF0F172A))));
                }

                final registros = snapshot.data!.docs;
                return ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: registros.length,
                  itemBuilder: (context, index) {
                    final doc = registros[index];
                    final data = doc.data() as Map<String, dynamic>;

                    return Card(
                      elevation: 0,
                      margin: const EdgeInsets.only(bottom: 12),
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15)),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(15),
                        leading: CircleAvatar(
                          backgroundColor: azulPrincipal.withValues(alpha: 0.1),
                          child: Icon(Icons.article, color: azulPrincipal),
                        ),
                        title: Text(
                          data['anotacao'] ?? '',
                          style: TextStyle(
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF0F172A)),
                        ),
                        trailing: PopupMenuButton<String>(
                          icon: Icon(Icons.more_vert,
                              color: isDark ? Colors.white70 : Colors.black87),
                          color:
                              isDark ? const Color(0xFF1E293B) : Colors.white,
                          onSelected: (value) {
                            if (value == 'editar') {
                              _abrirFormulario(
                                  docId: doc.id,
                                  textoExistente: data['anotacao']);
                            } else if (value == 'excluir') {
                              _excluirRegistro(doc.id);
                            }
                          },
                          itemBuilder: (context) => [
                            PopupMenuItem(
                                value: 'editar',
                                child: Text("Editar",
                                    style: TextStyle(
                                        color: isDark
                                            ? Colors.white
                                            : Colors.black))),
                            const PopupMenuItem(
                                value: 'excluir',
                                child: Text("Excluir",
                                    style: TextStyle(
                                        color: Colors.red,
                                        fontWeight: FontWeight.bold))),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _abrirFormulario(),
        backgroundColor: azulPrincipal,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("Novo Registro",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }
}