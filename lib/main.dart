import 'dart:io';
import 'package:florascan/database/db.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform, debugPrint;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import './screens/signup_screen.dart';
import './screens/welcome_screen.dart';
import './screens/profile.dart';
import './screens/login_screen.dart';
import './screens/initial_home.dart'; // Importa a tela inicial
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:path/path.dart'
    as path_pkg; // Usando alias para evitar conflitos de nome
import 'dart:convert'; // Necessário para jsonDecode/jsonEncode na identificação de planta

import 'package:florascan/widgets/plant_details_modal.dart'; // Importa o modal componentizado
// import 'package:florascan/screens/my_garden_screen.dart'; // Removido, já que o acesso é por botão

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Carrega as variaveis de ambiente (chaves de API) do arquivo .env.
  await dotenv.load(fileName: ".env");

  // Inicializa o databaseFactory se for desktop
  if (defaultTargetPlatform == TargetPlatform.windows ||
      defaultTargetPlatform == TargetPlatform.linux ||
      defaultTargetPlatform == TargetPlatform.macOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
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
      home: const AuthGate(),
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
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasData) {
          return HomeScreen();
        }

        return const WelcomeScreen();
      },
    );
  }
}

class HomeScreen extends StatefulWidget {
  final String name;
  final String profession;
  final String email;
  final String phone;
  final String password;

  const HomeScreen({
    super.key,
    this.name = '',
    this.profession = '',
    this.email = '',
    this.phone = '',
    this.password = '',
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  String? lastPhotoPath;

  // Copias editaveis dos dados do usuario (o widget e imutavel).
  late String _name = widget.name;
  late String _profession = widget.profession;
  late String _email = widget.email;
  late String _phone = widget.phone;

  void updateUserInfo(
    String newName,
    String newProfession,
    String newEmail,
    String newPhone,
  ) {
    setState(() {
      _name = newName;
      _profession = newProfession;
      _email = newEmail;
      _phone = newPhone;
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
          // REMOVIDO: BottomNavigationBarItem(icon: Icon(Icons.forest), label: "Jardim"),
        ],
      ),
    );
  }

  Widget _getPage(int index) {
    switch (index) {
      case 0:
        return InitialHomeScreen(); // Tela inicial com o botão "Meu Jardim"
      case 1:
        return Grade();
      case 2:
        return ProfileScreen(
          userName: _name,
          userProfession: _profession,
          email: _email,
          phone: _phone,
          onUpdate: updateUserInfo,
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
      debugPrint('❌ Erro ao carregar plantas: $e');
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
    final apiKey = dotenv.env['PLANTNET_API_KEY'] ?? '';
    if (apiKey.isEmpty) {
      debugPrint('❌ PLANTNET_API_KEY não configurada no arquivo .env');
      return;
    }

    final uri = Uri.parse(
      'https://my-api.plantnet.org/v2/identify/all?api-key=$apiKey&lang=pt-br&nb-results=3',
    );

    final request = http.MultipartRequest('POST', uri);

    request.files.add(
      await http.MultipartFile.fromPath(
        'images',
        imagePath,
        contentType: MediaType('image', 'jpeg'),
        filename: path_pkg.basename(imagePath), // Usando o alias aqui
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

          debugPrint('🌿 Nome científico: $nomeCientifico');
          debugPrint('📚 Nome(s) comum(ns): $nomeComum');

          if (nomeCientifico.isNotEmpty) {
            try {
              await DB.instance.insertPlanta({
                'nome': nomeCientifico,
                'descricao': nomeComum,
                'cuidados': '',
                'imagemPath': imagePath,
                'agua': 'N/A',
                'solo': 'N/A',
                'bioma': 'N/A',
                'harmonizacao': 'N/A',
                'categoria_id': null,
              });

              await carregarPlantas();
            } catch (e) {
              debugPrint('❌ Erro ao salvar planta: $e');
            }
          } else {
            debugPrint('❌ Nome da planta é obrigatório.');
          }
        } else {
          debugPrint('❌ Nenhum resultado encontrado.');
        }
      } else {
        debugPrint('❌ Erro na identificação: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Erro ao identificar planta: $e');
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
                padding: const EdgeInsets.only(top: 24.0),
                child: GridView.count(
                  crossAxisCount: 3,
                  children: List.generate(plantas.length, (index) {
                    final planta = plantas[index];
                    final imagemPath = planta['imagemPath'];
                    return GestureDetector(
                      onTap: () {
                        // Usando PageRouteBuilder para um modal flutuante de tela cheia
                        Navigator.push(
                          context,
                          PageRouteBuilder(
                            opaque:
                                false, // Permite que o conteúdo abaixo seja visto
                            pageBuilder:
                                (
                                  BuildContext context,
                                  _,
                                  __,
                                ) => PlantDetailsModal(
                                  // Usando o novo widget
                                  planta: planta,
                                  onPlantaExcluida:
                                      carregarPlantas, // O callback para Grade recarregar
                                ),
                            transitionsBuilder: (
                              context,
                              animation,
                              secondaryAnimation,
                              child,
                            ) {
                              return FadeTransition(
                                opacity: animation,
                                child: child,
                              );
                            },
                          ),
                        );
                      },
                      child: Container(
                        margin: const EdgeInsets.all(8.0),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(12.0),
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
