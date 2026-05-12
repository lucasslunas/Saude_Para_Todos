import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Imports já configurados para o nome do projeto no VS Code:
import 'package:saude_para_todos/componentes/decoracao_campo_autenticacao.dart';
import 'package:saude_para_todos/telas/tela_principal.dart';

class AutenticacaoTela extends StatefulWidget {
  const AutenticacaoTela({super.key});

  @override
  State<AutenticacaoTela> createState() => _AutenticacaoTelaState();
}

class _AutenticacaoTelaState extends State<AutenticacaoTela> {
  bool queroEntrar = true;
  final _formKey = GlobalKey<FormState>();

  bool _senhaVisivel = false;
  bool _confirmarSenhaVisivel = false;
  bool _carregando = false;

  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _senhaController = TextEditingController();
  final TextEditingController _confirmarSenhaController =
      TextEditingController();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? selectedSexo;
  String? selectedTipoUsuario;
  String? selectedTipoDoencaCronica;

  final List<String> _sexo = ["Masculino", "Feminino"];
  final List<String> _usuario = ["Pessoa Portadora de doença crônica"];
  final List<String> _opcaoDoenca = [
    "Diabetes",
    "Hipertensão",
    "Colesterol Alto"
  ];

  void _exibirSnackBar(String mensagem, Color cor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensagem), backgroundColor: cor),
    );
  }

  void navegarParaPrincipal() {
    if (!context.mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const TelaPrincipal()),
    );
  }

  Future<void> _recuperarSenha() async {
    final emailRecuperacaoController =
        TextEditingController(text: _emailController.text);
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        title: Text(
          "Recuperar Senha",
          style: TextStyle(color: isDark ? Colors.white : Colors.black),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Digite seu e-mail de cadastro. Enviaremos um link seguro para você redefinir sua senha.",
              style: TextStyle(color: isDark ? Colors.white70 : Colors.black87),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: emailRecuperacaoController,
              keyboardType: TextInputType.emailAddress,
              style: TextStyle(color: isDark ? Colors.white : Colors.black),
              decoration: InputDecoration(
                labelText: "E-mail",
                labelStyle:
                    TextStyle(color: isDark ? Colors.white54 : Colors.black87),
                filled: true,
                fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.email, color: Colors.blue),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (emailRecuperacaoController.text.isEmpty) {
                _exibirSnackBar(
                    "Por favor, digite um e-mail válido.", Colors.red);
                return;
              }
              try {
                await FirebaseAuth.instance.sendPasswordResetEmail(
                  email: emailRecuperacaoController.text.trim(),
                );

                if (context.mounted) {
                  Navigator.pop(context);
                  _exibirSnackBar(
                      "E-mail de recuperação enviado! Verifique sua caixa de entrada.",
                      Colors.green);
                }
              } on FirebaseAuthException {
                if (context.mounted) {
                  Navigator.pop(context);
                  _exibirSnackBar(
                      "Erro: Verifique se este e-mail está correto e cadastrado.",
                      Colors.red);
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            child: const Text("Enviar Link",
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> botaoPrincipalClicado() async {
    // CORREÇÃO: Tira o foco ao tentar autenticar
    FocusScope.of(context).unfocus();

    if (_formKey.currentState!.validate()) {
      setState(() => _carregando = true);

      try {
        if (queroEntrar) {
          // --- LOGIN ---
          await _auth.signInWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _senhaController.text,
          );
          navegarParaPrincipal();
        } else {
          // --- CADASTRO ---
          UserCredential userCredential =
              await _auth.createUserWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _senhaController.text,
          );

          // Salva dados extras no Firestore
          await _firestore
              .collection('usuarios')
              .doc(userCredential.user!.uid)
              .set({
            'nome': _nomeController.text.trim(),
            'email': _emailController.text.trim(),
            'sexo': selectedSexo,
            'tipoUsuario': selectedTipoUsuario,
            'doencaCronica': selectedTipoDoencaCronica,
            'createdAt': Timestamp.now(),
          });

          _exibirSnackBar("Cadastro realizado com sucesso!", Colors.green);
          navegarParaPrincipal();
        }
      } on FirebaseAuthException catch (e) {
        String mensagemErro = "Ocorreu um erro.";
        if (e.code == 'weak-password') {
          mensagemErro = 'A senha é muito fraca.';
        } else if (e.code == 'email-already-in-use') {
          mensagemErro = 'E-mail já cadastrado.';
        } else if (e.code == 'invalid-credential' ||
            e.code == 'wrong-password' ||
            e.code == 'user-not-found') {
          mensagemErro = 'E-mail ou senha inválidos.';
        }
        _exibirSnackBar(mensagemErro, Colors.red);
      } catch (e) {
        _exibirSnackBar("Erro: $e", Colors.red);
      } finally {
        if (context.mounted) {
          setState(() => _carregando = false);
        }
      }
    } else {
      _exibirSnackBar("Preencha todos os campos corretamente.", Colors.red);
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    Color corFundoInput = isDark ? const Color(0xFF1E293B) : Colors.transparent;
    Color corTextoDica = isDark ? Colors.white70 : Colors.black87;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      // CORREÇÃO AQUI: GestureDetector fecha o teclado ao tocar no fundo da tela
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Center(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Image.asset("assets/logo.png", height: 128),
                    Text(
                      "Saúde Para todos",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // --- CAMPO NOME (Apenas Cadastro) ---
                    Visibility(
                      visible: !queroEntrar,
                      child: Column(
                        children: [
                          TextFormField(
                            style: TextStyle(
                                color: isDark ? Colors.white : Colors.black),
                            decoration:
                                getAuthenticationInputDecoration("Nome").copyWith(
                              filled: isDark,
                              fillColor: corFundoInput,
                              hintStyle: TextStyle(color: corTextoDica),
                              labelStyle: TextStyle(color: corTextoDica),
                            ),
                            controller: _nomeController,
                            validator: (value) {
                              if (!queroEntrar &&
                                  (value == null || value.length < 3)) {
                                return "Nome inválido";
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),

                    // --- CAMPO E-MAIL ---
                    TextFormField(
                      style:
                          TextStyle(color: isDark ? Colors.white : Colors.black),
                      decoration:
                          getAuthenticationInputDecoration("E-Mail").copyWith(
                        filled: isDark,
                        fillColor: corFundoInput,
                        hintStyle: TextStyle(color: corTextoDica),
                        labelStyle: TextStyle(color: corTextoDica),
                      ),
                      controller: _emailController,
                      validator: (value) {
                        if (value == null || !value.contains("@")) {
                          return "E-mail inválido";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 8),

                    // --- CAMPO SENHA ---
                    TextFormField(
                      style:
                          TextStyle(color: isDark ? Colors.white : Colors.black),
                      decoration:
                          getAuthenticationInputDecoration("Senha").copyWith(
                        filled: isDark,
                        fillColor: corFundoInput,
                        hintStyle: TextStyle(color: corTextoDica),
                        labelStyle: TextStyle(color: corTextoDica),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _senhaVisivel
                                ? Icons.visibility
                                : Icons.visibility_off,
                            color: Colors.blue,
                          ),
                          onPressed: () =>
                              setState(() => _senhaVisivel = !_senhaVisivel),
                        ),
                      ),
                      controller: _senhaController,
                      obscureText: !_senhaVisivel,
                      validator: (String? value) {
                        if (value == null || value.isEmpty) {
                          return "Por favor, digite uma senha";
                        }
                        if (value.length < 8) {
                          return "A senha deve ter pelo menos 8 caracteres";
                        }

                        bool contemMaiscula = value.contains(RegExp(r'[A-Z]'));
                        bool contemMinuscula = value.contains(RegExp(r'[a-z]'));
                        bool contemNumeros = value.contains(RegExp(r'[0-9]'));
                        bool contemCaracteresEspeciais =
                            value.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>]'));

                        if (!contemMaiscula) {
                          return "A senha deve conter pelo menos uma letra maiúscula.";
                        }
                        if (!contemMinuscula) {
                          return "A senha deve conter pelo menos uma letra minúscula.";
                        }
                        if (!contemNumeros) {
                          return "A senha deve conter pelo menos um número.";
                        }
                        if (!contemCaracteresEspeciais) {
                          return "A senha deve conter pelo menos um caractere especial (!@#\$%^&*...).";
                        }

                        return null;
                      },
                    ),
                    const SizedBox(height: 8),

                    // --- CAMPOS EXTRAS (Apenas Cadastro) ---
                    Visibility(
                      visible: !queroEntrar,
                      child: Column(
                        children: [
                          // Confirmação de Senha
                          TextFormField(
                            style: TextStyle(
                                color: isDark ? Colors.white : Colors.black),
                            controller: _confirmarSenhaController,
                            decoration: getAuthenticationInputDecoration(
                                    "Confirme a Senha")
                                .copyWith(
                              filled: isDark,
                              fillColor: corFundoInput,
                              hintStyle: TextStyle(color: corTextoDica),
                              labelStyle: TextStyle(color: corTextoDica),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _confirmarSenhaVisivel
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                  color: Colors.blue,
                                ),
                                onPressed: () => setState(() =>
                                    _confirmarSenhaVisivel =
                                        !_confirmarSenhaVisivel),
                              ),
                            ),
                            obscureText: !_confirmarSenhaVisivel,
                            validator: (value) {
                              if (!queroEntrar &&
                                  value != _senhaController.text) {
                                return "Senhas não conferem";
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Dropdowns
                          _buildDropdownButton(
                            hintText: 'Selecione seu Sexo',
                            value: selectedSexo,
                            options: _sexo,
                            isDark: isDark,
                            onChanged: (val) =>
                                setState(() => selectedSexo = val),
                          ),
                          const SizedBox(height: 16),
                          _buildDropdownButton(
                            hintText: "Tipo de usuário",
                            value: selectedTipoUsuario,
                            options: _usuario,
                            isDark: isDark,
                            onChanged: (val) =>
                                setState(() => selectedTipoUsuario = val),
                          ),
                          const SizedBox(height: 16),
                          _buildDropdownButton(
                            hintText: "Doença crônica",
                            value: selectedTipoDoencaCronica,
                            options: _opcaoDoenca,
                            isDark: isDark,
                            onChanged: (val) =>
                                setState(() => selectedTipoDoencaCronica = val),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // --- BOTÃO PRINCIPAL ---
                    ElevatedButton(
                      onPressed:
                          (_carregando) ? null : () => botaoPrincipalClicado(),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                      child: (_carregando)
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child:
                                  CircularProgressIndicator(color: Colors.white))
                          : Text((queroEntrar) ? "Entrar" : "Cadastrar",
                              style: const TextStyle(fontSize: 18)),
                    ),

                    // --- BOTÃO RECUPERAR SENHA ---
                    Visibility(
                      visible: queroEntrar,
                      child: TextButton(
                        onPressed: _recuperarSenha,
                        child: const Text(
                          "Esqueci minha senha",
                          style: TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ),

                    const Divider(),

                    // --- BOTÃO ALTERNAR MODO ---
                    TextButton(
                      onPressed: () {
                        // CORREÇÃO AQUI: Força o teclado a fechar antes de alternar o modo
                        FocusScope.of(context).unfocus();

                        setState(() {
                          queroEntrar = !queroEntrar;
                          _formKey.currentState?.reset();
                          _senhaVisivel = false;
                          _confirmarSenhaVisivel = false;

                          _nomeController.clear();
                          _emailController.clear();
                          _senhaController.clear();
                          _confirmarSenhaController.clear();
                          selectedSexo = null;
                          selectedTipoUsuario = null;
                          selectedTipoDoencaCronica = null;
                        });
                      },
                      child: Text(
                        (queroEntrar) ? "Criar conta" : "Já tenho conta",
                        style: TextStyle(
                            color: isDark ? Colors.white70 : Colors.deepPurple,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Dropdown atualizado
  Widget _buildDropdownButton({
    required String hintText,
    required String? value,
    required List<String> options,
    required ValueChanged<String?> onChanged,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.transparent,
        border: Border.all(color: Colors.blue, width: 1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          value: value,
          hint: Text(
            hintText,
            style: TextStyle(
                color: isDark ? Colors.white70 : Colors.black87), // Preto forte
          ),
          onChanged: onChanged,
          items: options.map((String option) {
            return DropdownMenuItem<String>(
              value: option,
              child: Text(
                option,
                style: TextStyle(color: isDark ? Colors.white : Colors.black),
              ),
            );
          }).toList(),
          isExpanded: true,
          icon: const Icon(Icons.arrow_drop_down, color: Colors.blue),
        ),
      ),
    );
  }
}