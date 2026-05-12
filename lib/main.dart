import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; 
import 'package:shared_preferences/shared_preferences.dart'; 
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:local_auth/local_auth.dart';
import 'firebase_options.dart';

// Certifique-se de que os caminhos abaixo estão corretos no seu projeto
import 'package:saude_para_todos/telas/autenticacao_tela.dart';
import 'package:saude_para_todos/telas/tela_principal.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final prefs = await SharedPreferences.getInstance();
  final temaSalvo = prefs.getString('tema_usuario') ?? 'claro';

  runApp(MyApp(temaInicial: temaSalvo));
}

class MyApp extends StatefulWidget {
  final String temaInicial;
  const MyApp({super.key, required this.temaInicial});

  @override
  State<MyApp> createState() => _MyAppState();

  static State<MyApp>? of(BuildContext context) =>
      context.findAncestorStateOfType<_MyAppState>();
}

class _MyAppState extends State<MyApp> {
  late ThemeMode _modoAtual;

  @override
  void initState() {
    super.initState();
    _configurarTemaInicial(widget.temaInicial);
  }

  void _configurarTemaInicial(String tema) {
    if (tema == 'escuro') {
      _modoAtual = ThemeMode.dark;
    } else if (tema == 'sistema') {
      _modoAtual = ThemeMode.system;
    } else {
      _modoAtual = ThemeMode.light;
    }
    // Força a cor do sistema logo ao abrir o app
    _atualizarCoresDoSistema(_modoAtual);
  }

  // --- O "Comandante" das cores do Android ---
  void _atualizarCoresDoSistema(ThemeMode modo) {
    bool isDark = modo == ThemeMode.dark || 
                 (modo == ThemeMode.system && 
                  WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.dark);

    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        systemNavigationBarColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8F9FA),
        systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      ),
    );
  }

  Future<void> alternarTema(ThemeMode modo) async {
    setState(() {
      _modoAtual = modo;
    });

    // Força a cor do sistema IMEDIATAMENTE ao trocar o tema
    _atualizarCoresDoSistema(modo);

    final prefs = await SharedPreferences.getInstance();
    String valorParaSalvar = 'claro';
    if (modo == ThemeMode.dark) valorParaSalvar = 'escuro';
    if (modo == ThemeMode.system) valorParaSalvar = 'sistema';

    await prefs.setString('tema_usuario', valorParaSalvar);
  }

  @override
  Widget build(BuildContext context) {
    const Color azulPrincipal = Color(0xFF1E5EFE);

    return MaterialApp(
      title: 'Saúde Para Todos',
      debugShowCheckedModeBanner: false,
      
      theme: ThemeData(
        brightness: Brightness.light,
        primaryColor: azulPrincipal,
        colorScheme: ColorScheme.fromSeed(
            seedColor: azulPrincipal, brightness: Brightness.light),
        scaffoldBackgroundColor: const Color(0xFFF8F9FA),
        useMaterial3: true,
      ),
      
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: azulPrincipal,
        colorScheme: ColorScheme.fromSeed(
            seedColor: azulPrincipal, brightness: Brightness.dark),
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        useMaterial3: true,
      ),
      
      themeMode: _modoAtual,
      home: const RoteadorTelas(),
    );
  }
}

// --- MUDANÇA DEFINITIVA AQUI: Transformado em StatefulWidget para ler as configs com calma ---
class RoteadorTelas extends StatefulWidget {
  const RoteadorTelas({super.key});

  @override
  State<RoteadorTelas> createState() => _RoteadorTelasState();
}

class _RoteadorTelasState extends State<RoteadorTelas> {
  String _seguranca = 'manter';
  bool _carregandoPrefs = true;

  @override
  void initState() {
    super.initState();
    _carregarPreferencia();
  }

  Future<void> _carregarPreferencia() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _seguranca = prefs.getString('seguranca_login') ?? 'manter';
      _carregandoPrefs = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Aguarda a leitura da memória do celular primeiro
    if (_carregandoPrefs) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Color(0xFF1E5EFE))),
      );
    }

    // Depois de saber a regra, verifica o Firebase
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator(color: Color(0xFF1E5EFE))),
          );
        }

        if (snapshot.hasData) {
          // Se pediu pra exigir senha sempre, desloga por baixo dos panos e joga pro login
          if (_seguranca == 'login' || _seguranca == 'senha') {
            WidgetsBinding.instance.addPostFrameCallback((_) async {
              await FirebaseAuth.instance.signOut();
            });
            return const AutenticacaoTela();
          }

          // Se escolheu biometria, vai pra tela do dedão
          if (_seguranca == 'biometria') {
            return const TelaBloqueioBiometrico();
          }

          // Se escolheu 'manter' (Entrar Automaticamente), as portas se abrem!
          return const TelaPrincipal();
        }

        // Se não tem conta logada, vai pro login normal
        return const AutenticacaoTela();
      },
    );
  }
}

class TelaBloqueioBiometrico extends StatefulWidget {
  const TelaBloqueioBiometrico({super.key});

  @override
  State<TelaBloqueioBiometrico> createState() => _TelaBloqueioBiometricoState();
}

class _TelaBloqueioBiometricoState extends State<TelaBloqueioBiometrico> {
  final LocalAuthentication _auth = LocalAuthentication();

  @override
  void initState() {
    super.initState();
    _autenticar();
  }

  Future<void> _autenticar() async {
    try {
      final bool autenticado = await _auth.authenticate(
        localizedReason: 'Confirme sua identidade para entrar',
      );

      if (!mounted) return;

      if (autenticado) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const TelaPrincipal()),
        );
      }
    } catch (e) {
      // Se der erro ou cancelar clicando fora, apenas continua na tela bloqueada.
      debugPrint("Cancelado pelo usuário ou erro no sensor.");
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.fingerprint, size: 80, color: Color(0xFF1E5EFE)),
            const SizedBox(height: 20),
            Text(
              "Aplicativo Bloqueado",
              style: TextStyle(
                fontSize: 22, 
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "Confirme sua identidade para continuar",
              style: TextStyle(color: isDark ? Colors.white54 : Colors.black54),
            ),
            const SizedBox(height: 50),
            
            ElevatedButton.icon(
              onPressed: _autenticar,
              icon: const Icon(Icons.lock_open, color: Colors.white),
              label: const Text("Usar Digital", style: TextStyle(color: Colors.white, fontSize: 16)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E5EFE),
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),

            const SizedBox(height: 20),

            TextButton(
              onPressed: () async {
                // Aqui sim, se clicar no botão, deslogamos de verdade
                await FirebaseAuth.instance.signOut();
                
                if (!context.mounted) return;
                
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const AutenticacaoTela()),
                );
              },
              child: const Text("Entrar com outra conta", style: TextStyle(color: Color(0xFF1E5EFE))),
            )
          ],
        ),
      ),
    );
  }
}