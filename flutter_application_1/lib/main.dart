import 'dart:io';
import 'package:flutter_application_1/database/db.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import './screens/signup_screen.dart';
import './screens/welcome_screen.dart';
import './screens/profile.dart';
import './screens/login_screen.dart';
import './screens/initial_home.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:path/path.dart';
import 'dart:convert';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializa o databaseFactory se for desktop
  if (defaultTargetPlatform == TargetPlatform.windows ||
      defaultTargetPlatform == TargetPlatform.linux ||
      defaultTargetPlatform == TargetPlatform.macOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
  await dotenv.load();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const FloraScanApp());
}

class FloraScanApp extends StatelessWidget {
  const FloraScanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'FloraScan',
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: Colors.white,
        primaryColor: const Color(0xFF4CAF50),
        colorScheme: const ColorScheme.light(
          primary: Color(0xFF4CAF50),
          secondary: Color(0xFFA5D6A7),
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Color(0xFF2E7D32)),
          bodyMedium: TextStyle(color: Color(0xFF2E7D32)),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Color(0xFF2E7D32),
          elevation: 0,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4CAF50),
            foregroundColor: Colors.white,
            textStyle: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF4CAF50),
            side: const BorderSide(color: Color(0xFF4CAF50)),
          ),
        ),
      ),
      home: AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Ainda carregando
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Usuário logado
        if (snapshot.hasData) {
          return HomeScreen(); // Exibe a tela principal com menu
        }

        // Não logado
        return WelcomeScreen(); // Tela inicial para login/cadastro
      },
    );
  }
}

class HomeScreen extends StatefulWidget {
  String name;
  String profession;
  String email;
  String phone;
  final String password;

  HomeScreen({
    super.key,
    this.name = '', // Definindo valores padrão
    this.profession = '',
    this.email = '',
    this.phone = '',
    this.password = '', // Definindo valores padrão
  });

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  String? lastPhotoPath;

  void updateUserInfo(
    String newName,
    String newProfession,
    String newEmail,
    String newPhone,
  ) {
    setState(() {
      widget.name = newName;
      widget.profession = newProfession;
      widget.email = newEmail;
      widget.phone = newPhone;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _getPage(_currentIndex),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.camera_alt),
            label: "Inicial",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.photo_library),
            label: "Fotos",
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Perfil"),
        ],
      ),
    );
  }

  Widget _getPage(int index) {
    switch (index) {
      case 0:
        return InitialHomeScreen();
      case 1:
        return Grade();
      case 2:
        return ProfileScreen(
          userName: widget.name,
          userProfession: widget.profession,
          email: widget.email,
          phone: widget.phone,
          onUpdate: updateUserInfo,
          correctPassword: widget.password,
        );
      default:
        return InitialHomeScreen();
    }
  }
}

class Grade extends StatefulWidget {
  const Grade({super.key});

  @override
  State<Grade> createState() => _GradeState();
}

class _GradeState extends State<Grade> {
  List<Map<String, dynamic>> plantas = [];

  @override
  void initState() {
    super.initState();
    carregarPlantas();
  }

  Future<void> carregarPlantas() async {
    try {
      final dados = await DB.instance.getPlantasComCategoria();
      setState(() {
        plantas = dados;
      });
    } catch (e) {
      print('❌ Erro ao carregar plantas: $e');
      setState(() {
        plantas = [];
      });
    }
  }

  Future<void> tirarFoto() async {
    final picker = ImagePicker();
    final XFile? novaFoto = await picker.pickImage(source: ImageSource.camera);
    if (novaFoto != null) {
      await identificarPlanta(novaFoto.path);
    }
  }

  Future<void> escolherImagemDaGaleria() async {
    final picker = ImagePicker();
    final XFile? imagemSelecionada = await picker.pickImage(
      source: ImageSource.gallery,
    );
    if (imagemSelecionada != null) {
      await identificarPlanta(imagemSelecionada.path);
    }
  }

  Future<void> identificarPlanta(String imagePath) async {
    final uri = Uri.parse(
      'https://my-api.plantnet.org/v2/identify/all?api-key=2b101pP92wbLhY6TqTbkv1lBtO&lang=pt-br&nb-results=3',
    );

    final request = http.MultipartRequest('POST', uri);

    request.files.add(
      await http.MultipartFile.fromPath(
        'images',
        imagePath,
        contentType: MediaType('image', 'jpeg'),
        filename: basename(imagePath),
      ),
    );

    request.fields['organs'] = 'auto';

    try {
      final response = await request.send();

      if (response.statusCode == 200) {
        final body = await response.stream.bytesToString();
        final json = jsonDecode(body);

        if (json['results'] != null && (json['results'] as List).isNotEmpty) {
          final species = json['results'][0]['species'];
          final nomeCientifico =
              species['scientificNameWithoutAuthor']?.toString().trim() ?? '';
          final commonNamesList = species['commonNames'];
          String nomeComum = '';

          if (commonNamesList is List && commonNamesList.isNotEmpty) {
            nomeComum =
                commonNamesList.map((e) => e.toString()).join(', ').trim();
          }

          print('🌿 Nome científico: $nomeCientifico');
          print('📚 Nome(s) comum(ns): $nomeComum');

          if (nomeCientifico.isNotEmpty) {
            try {
              await DB.instance.insertPlanta({
                'nome': nomeCientifico,
                'descricao': nomeComum,
                'cuidados': '',
                'imagemPath': imagePath,
                'categoria_id': null,
              });

              await carregarPlantas();

              // Sem mensagem para o usuário aqui, pois tiramos o context
            } catch (e) {
              print('❌ Erro ao salvar planta: $e');
              // Sem snackbar de erro
            }
          } else {
            print('❌ Nome da planta é obrigatório.');
            // Sem snackbar de aviso
          }
        } else {
          print('❌ Nenhum resultado encontrado.');
          // Sem snackbar
        }
      } else {
        print('❌ Erro na identificação: ${response.statusCode}');
        // Sem snackbar
      }
    } catch (e) {
      print('❌ Erro ao identificar planta: $e');
      // Sem snackbar
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            onPressed: escolherImagemDaGaleria,
            backgroundColor: Colors.white,
            heroTag: 'galeria',
            child: const Icon(
              Icons.photo_library,
              color: Colors.black,
              size: 28,
            ),
          ),
          const SizedBox(height: 12),
          FloatingActionButton(
            onPressed: tirarFoto,
            backgroundColor: Colors.white,
            heroTag: 'camera',
            child: const Icon(Icons.camera_alt, color: Colors.black, size: 32),
          ),
        ],
      ),
      body:
          plantas.isEmpty
              ? const Center(child: Text('Nenhuma foto tirada ainda :('))
              : Padding(
                padding: const EdgeInsets.only(
                  top: 24.0,
                ), // margem maior no topo
                child: GridView.count(
                  crossAxisCount: 3,
                  children: List.generate(plantas.length, (index) {
                    final planta = plantas[index];
                    final imagemPath = planta['imagemPath'];
                    return GestureDetector(
                      onTap: () {
                        showDialog(
                          context: context,
                          builder:
                              (context) => FotoDetalhe(
                                planta: planta,
                                onPlantaExcluida: carregarPlantas,
                              ),
                        );
                      },
                      child: Container(
                        margin: const EdgeInsets.all(8.0),
                        decoration: BoxDecoration(
                          color: Colors.grey[200], // cinza claro
                          borderRadius: BorderRadius.circular(
                            12.0,
                          ), // borda arredondada
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Expanded(
                              flex: 7,
                              child: ClipRRect(
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(12),
                                ),
                                child:
                                    (imagemPath != null &&
                                            File(imagemPath).existsSync())
                                        ? Image.file(
                                          File(imagemPath),
                                          width: double.infinity,
                                          fit: BoxFit.cover,
                                        )
                                        : const Center(
                                          child: Icon(
                                            Icons.image_not_supported,
                                            color: Colors.black26,
                                            size: 40,
                                          ),
                                        ),
                              ),
                            ),
                            Expanded(
                              flex: 3,
                              child: Container(
                                alignment: Alignment.center,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                ),
                                child: Text(
                                  planta['nome'] ?? 'Sem nome',
                                  style: const TextStyle(
                                    color: Colors.black87,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ),
              ),
    );
  }
}

// Widget para exibir os detalhes da foto em um modal

class FotoDetalhe extends StatelessWidget {
  final Map<String, dynamic> planta;
  final VoidCallback onPlantaExcluida;

  const FotoDetalhe({
    super.key,
    required this.planta,
    required this.onPlantaExcluida,
  });

  @override
  Widget build(BuildContext context) {
    final imagemPath = planta['imagemPath'];
    final String? cuidados = planta['cuidados'];

    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Text(
                  planta['nome'] ?? 'Sem nome',
                  style: GoogleFonts.lato(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              if (imagemPath != null && File(imagemPath).existsSync())
                Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8.0),
                    child: Image.file(
                      File(imagemPath),
                      height: 200,
                      width: 200,
                      fit: BoxFit.cover,
                    ),
                  ),
                )
              else
                const Center(child: Icon(Icons.image_not_supported, size: 100)),
              const SizedBox(height: 10),
              Text(
                "🌿 Descrição:",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(planta['descricao'] ?? 'Sem descrição'),
              const SizedBox(height: 10),
              Text(
                "💧 Cuidados:",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              cuidados == null || cuidados.isEmpty
                  ? ElevatedButton(
                    onPressed: () async {
                      print('Botão "Adicionar Cuidados" clicado');
                      final nomeCientifico = planta['nome'];
                      if (nomeCientifico != null && nomeCientifico.isNotEmpty) {
                        final novosCuidados = await detalhesPlantaAI(
                          nomeCientifico,
                        );
                        print(novosCuidados);
                        // if (novosCuidados != null) {
                        //   final plantaAtualizada = Map<String, dynamic>.from(
                        //     planta,
                        //   );
                        //   plantaAtualizada['cuidados'] = novosCuidados;

                        //   final resultado = await DB.instance.updatePlanta(
                        //     plantaAtualizada,
                        //   );
                        //   if (context.mounted) {
                        //     ScaffoldMessenger.of(context).showSnackBar(
                        //       SnackBar(
                        //         content: Text(
                        //           resultado > 0
                        //               ? 'Cuidados atualizados com sucesso!'
                        //               : 'Falha ao atualizar planta.',
                        //         ),
                        //       ),
                        //     );
                        //     Navigator.of(
                        //       context,
                        //     ).pop(); // Fecha e força recarregar
                        //   }
                        // }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                    child: const Text(
                      'Adicionar Cuidados',
                      style: TextStyle(color: Colors.white),
                    ),
                  )
                  : Text(cuidados),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text('Fechar'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () async {
                      if (planta['id'] != null) {
                        try {
                          await DB.instance.deletePlanta(planta['id']);
                          if (context.mounted) {
                            Navigator.of(context).pop();
                            onPlantaExcluida();
                          }
                        } catch (e) {
                          print('Erro ao excluir planta: $e');
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Erro ao excluir planta.'),
                              ),
                            );
                          }
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                    child: const Text(
                      'Excluir',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<String?> detalhesPlantaAI(String nomeCientifico) async {
  print('Botão "Adicionar Cuidados" função');

  const endpoint =
      'https://plantscan.openai.azure.com/openai/deployments/plantscan-chat/chat/completions?api-version=2025-01-01-preview';

  final apiKey = dotenv.env['AZURE_OPENAI_KEY'];

  if (apiKey == null || apiKey.isEmpty) {
    print('❌ API Key não encontrada no .env!');
    return null;
  }

  final headers = {'Content-Type': 'application/json', 'api-key': apiKey};

  final prompt = '''
Me dê informações sobre a planta "$nomeCientifico". Use obrigatoriamente o seguinte formato JSON:

{
  "quantidade_ideal_de_agua": "Regar 2x por semana",
  "tipo_de_solo": "arenoso",
  "bioma_adequado": "temperado",
  "outras_plantas_compatíveis": "ardósia"
}
''';

  final body = jsonEncode({
    'model': 'gpt-4.1-mini',
    'messages': [
      {
        'role': 'system',
        'content':
            'Você é um assistente de jardinagem. Sempre responda em JSON.',
      },
      {'role': 'user', 'content': prompt},
    ],
    'max_tokens': 500,
    'temperature': 0.7,
  });

  try {
    final response = await http.post(
      Uri.parse(endpoint),
      headers: headers,
      body: body,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final respostaJson = data['choices'][0]['message']['content'];

      try {
        final parsed = jsonDecode(respostaJson);
        final textoFormatado = '''
💧 Água: ${parsed['quantidade_ideal_de_agua']}
🌱 Solo: ${parsed['tipo_de_solo']}
🌍 Bioma: ${parsed['bioma_adequado']}
🌿 Harmoniza com: ${parsed['outras_plantas_compatíveis']}
''';
        return textoFormatado;
      } catch (e) {
        print('⚠️ Erro ao interpretar JSON da resposta: $e');
        return null;
      }
    } else {
      print('❌ Erro na resposta: ${response.statusCode}');
      print(response.body);
      return null;
    }
  } catch (e) {
    print('❌ Erro ao conectar com Azure OpenAI: $e');
    return null;
  }
}
