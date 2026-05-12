import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PreferenciasTela extends StatefulWidget {
  const PreferenciasTela({super.key});

  @override
  State<PreferenciasTela> createState() => _PreferenciasTelaState();
}

class _PreferenciasTelaState extends State<PreferenciasTela> {
  final Color azulPrincipal = const Color(0xFF1E5EFE);
  
  // Variável que guarda a escolha atual
  String _metodoSeguranca = 'manter'; // Padrão: manter logado
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    _carregarPreferencias();
  }

  Future<void> _carregarPreferencias() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      // Lê o que o usuário escolheu antes. Se não tiver nada, mantém logado.
      _metodoSeguranca = prefs.getString('seguranca_login') ?? 'manter';
      _carregando = false;
    });
  }

  Future<void> _salvarPreferencia(String valor) async {
    setState(() => _metodoSeguranca = valor);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('seguranca_login', valor);
    
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Preferência de segurança salva!")),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    Color corTextoSecundario = isDark ? Colors.white70 : Colors.black54;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Segurança e Acesso",
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        foregroundColor: isDark ? Colors.white : Colors.black,
        elevation: 0,
      ),
      body: _carregando
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const Icon(Icons.security, size: 64, color: Colors.blue),
                const SizedBox(height: 20),
                Text(
                  "Como você prefere entrar no aplicativo?",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 30),

                // OPÇÃO 1: Manter Conectado
                _construirOpcao(
                  valor: 'manter',
                  titulo: "Entrar Automaticamente",
                  subtitulo: "Não pede senha ao reabrir o aplicativo.",
                  icone: Icons.sentiment_satisfied_alt,
                  isDark: isDark,
                  corTextoSecundario: corTextoSecundario,
                ),
                const SizedBox(height: 15),

                // OPÇÃO 2: Pedir Senha
                _construirOpcao(
                  valor: 'senha',
                  titulo: "Sempre pedir senha",
                  subtitulo: "Maior segurança. Exige login a cada acesso.",
                  icone: Icons.password,
                  isDark: isDark,
                  corTextoSecundario: corTextoSecundario,
                ),
                const SizedBox(height: 15),

                // OPÇÃO 3: Biometria
                _construirOpcao(
                  valor: 'biometria',
                  titulo: "Usar Biometria (Digital/Face)",
                  subtitulo: "Acesso rápido e seguro usando o sistema do celular.",
                  icone: Icons.fingerprint,
                  isDark: isDark,
                  corTextoSecundario: corTextoSecundario,
                ),
              ],
            ),
    );
  }

  // Novo componente customizado, livre de avisos de "deprecated"!
  Widget _construirOpcao({
    required String valor,
    required String titulo,
    required String subtitulo,
    required IconData icone,
    required bool isDark,
    required Color corTextoSecundario,
  }) {
    bool selecionado = _metodoSeguranca == valor;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        border: Border.all(
          color: selecionado ? azulPrincipal : (isDark ? Colors.white24 : Colors.black12),
          width: selecionado ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => _salvarPreferencia(valor),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            child: Row(
              children: [
                // Bolinha do rádio customizada
                Icon(
                  selecionado ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                  color: selecionado ? azulPrincipal : corTextoSecundario,
                ),
                const SizedBox(width: 16),
                
                // Textos
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        titulo,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: selecionado ? FontWeight.bold : FontWeight.normal,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitulo,
                        style: TextStyle(
                          fontSize: 13,
                          color: corTextoSecundario,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                
                // Ícone ilustrativo no final
                Icon(icone, color: selecionado ? azulPrincipal : corTextoSecundario, size: 28),
              ],
            ),
          ),
        ),
      ),
    );
  }
}