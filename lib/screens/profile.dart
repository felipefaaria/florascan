import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_application_1/screens/welcome_screen.dart';
import 'package:flutter_application_1/screens/login_screen.dart';
import 'package:flutter_application_1/screens/signup_screen.dart';
import 'package:flutter_application_1/database/db.dart'; // Importa o DB para gerenciar dados do usuário

class ProfileScreen extends StatefulWidget {
  // As propriedades userName, userProfession, email, phone não precisam mais ser 'required'
  // ou passadas diretamente do HomeScreen. Elas serão lidas do Firebase Auth
  // e do banco de dados local.
  final String
  userName; // Mantido para compatibilidade inicial, mas será substituído
  final String userProfession; // Mantido para compatibilidade inicial
  final String email; // Será lido do Firebase Auth
  final String phone; // Mantido para compatibilidade inicial
  final Function(String, String, String, String)
  onUpdate; // Mantido para o callback externo

  const ProfileScreen({
    super.key,
    this.userName = '', // Default vazio
    this.userProfession = '', // Default vazio
    this.email = '', // Default vazio
    this.phone = '', // Default vazio
    required this.onUpdate,
  });

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool isEditing = false;
  late TextEditingController _nameController;
  late TextEditingController _professionController;
  late TextEditingController _emailController; // Será apenas para exibição
  late TextEditingController _phoneController;
  // final TextEditingController _passwordConfirmationController = TextEditingController(); // REMOVIDO: Não mais necessário para esta lógica
  String? errorMessage;
  bool _isLoadingProfile = true; // Estado para carregar dados do perfil
  Map<String, dynamic>?
  _userProfileData; // Dados do perfil carregados do SQFlite

  @override
  void initState() {
    super.initState();
    _loadUserProfile(); // Carrega dados do perfil do banco de dados local e Firebase
  }

  // Carrega os dados do perfil do usuário do SQFlite e do Firebase Auth
  Future<void> _loadUserProfile() async {
    setState(() {
      _isLoadingProfile = true;
    });
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && user.email != null) {
      final data = await DB.instance.getUserByEmail(user.email!);
      setState(() {
        _userProfileData = data;
        // Inicializa controllers com dados do DB, ou do Firebase, ou vazio
        _nameController = TextEditingController(
          text: _userProfileData?['name'] ?? '',
        );
        _professionController = TextEditingController(
          text: _userProfileData?['profession'] ?? '',
        );
        _emailController = TextEditingController(
          text: user.email,
        ); // Email sempre vem do Firebase e não é editável aqui
        _phoneController = TextEditingController(
          text: _userProfileData?['phone'] ?? '',
        );
        _isLoadingProfile = false;
      });
    } else {
      // Se não há usuário logado ou e-mail, inicializa com controllers vazios
      setState(() {
        _nameController = TextEditingController(text: '');
        _professionController = TextEditingController(text: '');
        _emailController = TextEditingController(
          text: '',
        ); // Vazio se não houver email
        _phoneController = TextEditingController(text: '');
        _isLoadingProfile = false;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _professionController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    // _passwordConfirmationController.dispose(); // REMOVIDO
    super.dispose();
  }

  void _saveChanges() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.email == null) {
      setState(() {
        errorMessage = "Usuário não logado ou e-mail indisponível.";
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro: Usuário não logado.')),
      );
      return;
    }

    // A validação de senha foi removida, pois não é armazenada no SQFlite
    // e a validação de autenticação Firebase deveria ser tratada separadamente.

    final userMapToSave = {
      'email': user.email, // Email é a chave primária, sempre do Firebase
      'name': _nameController.text.trim(),
      'profession': _professionController.text.trim(),
      'phone': _phoneController.text.trim(),
    };

    try {
      await DB.instance.insertOrUpdateUser(userMapToSave);

      setState(() {
        isEditing = false;
        errorMessage = null;
        _userProfileData =
            userMapToSave; // Atualiza os dados locais após salvar
        // _passwordConfirmationController.clear(); // REMOVIDO
      });
      // Notifica o HomeScreen (ou qualquer pai que use onUpdate) com os novos dados
      widget.onUpdate(
        _nameController.text,
        _professionController.text,
        _emailController.text, // Email do Firebase
        _phoneController.text,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Perfil atualizado com sucesso!')),
      );
    } catch (e) {
      setState(() {
        errorMessage = "Erro ao salvar perfil: $e";
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao atualizar perfil: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    // Tela para usuários não logados ou anônimos
    if (user == null || user.isAnonymous) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.person_off_outlined,
                  size: 100,
                  color: Colors.grey[600],
                ),
                const SizedBox(height: 25),
                Text(
                  "Você está usando como convidado.",
                  style: GoogleFonts.lato(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Text(
                  "Faça login ou cadastre-se para personalizar seu perfil.",
                  style: GoogleFonts.lato(
                    fontSize: 16,
                    color: Colors.grey[700],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 40,
                      vertical: 15,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 5,
                  ),
                  child: Text(
                    "Fazer Login",
                    style: GoogleFonts.lato(color: Colors.white, fontSize: 18),
                  ),
                ),
                const SizedBox(height: 15),
                OutlinedButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const SignUpScreen()),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Theme.of(context).primaryColor,
                    side: BorderSide(color: Theme.of(context).primaryColor),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 30,
                      vertical: 15,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    "Cadastrar-se",
                    style: GoogleFonts.lato(fontSize: 18),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Tela para usuários logados
    // A tela de perfil agora será apenas o corpo, sem AppBar próprio,
    // pois a AppBar superior é fornecida pelo Scaffold pai (HomeScreen).
    return Scaffold(
      body:
          _isLoadingProfile
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                // Para evitar overflow em teclados
                padding: const EdgeInsets.all(25.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Título e botão de edição agora fazem parte do corpo,
                    // permitindo que o BottomNavigationBar controle a AppBar.
                    Align(
                      alignment:
                          Alignment.centerLeft, // Alinha o título à esquerda
                    ),
                    // Botão de edição/cancelar movido para um local lógico, talvez abaixo do avatar ou como um FAB
                    // Para manter a funcionalidade de edição: Adicionar um botão no final da lista de informações
                    const SizedBox(height: 20),

                    const SizedBox(height: 20),
                    Text(
                      _userProfileData?['name']?.isNotEmpty == true
                          ? _userProfileData!['name']
                          : "Usuário",
                      style: GoogleFonts.lato(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.green[800],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (_userProfileData?['profession']?.isNotEmpty ==
                        true) ...[
                      const SizedBox(height: 5),
                      Text(
                        _userProfileData!['profession'],
                        style: GoogleFonts.lato(
                          fontSize: 18,
                          color: Colors.grey[700],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                    const SizedBox(height: 30),

                    if (isEditing) ...[
                      // Campos de edição
                      _buildTextField(
                        controller: _nameController,
                        label: "Nome",
                        icon: Icons.person_outline,
                      ),
                      const SizedBox(height: 15),
                      _buildTextField(
                        controller: _professionController,
                        label: "Profissão",
                        icon: Icons.work_outline,
                      ),
                      const SizedBox(height: 15),
                      // Email é apenas para exibição no modo de edição, não editável aqui.
                      _buildTextField(
                        controller: _emailController,
                        label: "Email (Não Editável)",
                        icon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        readOnly: true, // Torna o campo de email não editável
                        enabled: false, // Desabilita visualmente o campo
                      ),
                      const SizedBox(height: 15),
                      _buildTextField(
                        controller: _phoneController,
                        label: "Celular",
                        icon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                      ),
                      // Removido o campo de confirmação de senha
                      // const SizedBox(height: 15),
                      // _buildTextField(controller: _passwordConfirmationController, label: "Confirme sua senha (opcional)", icon: Icons.lock_outline, obscureText: true),
                      if (errorMessage != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Text(
                            errorMessage!,
                            style: GoogleFonts.lato(
                              color: Colors.red,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      const SizedBox(height: 30),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                setState(() {
                                  isEditing = false;
                                  errorMessage = null;
                                  // Reseta para os dados carregados do DB
                                  _nameController.text =
                                      _userProfileData?['name'] ?? '';
                                  _professionController.text =
                                      _userProfileData?['profession'] ?? '';
                                  _emailController.text = user.email!;
                                  _phoneController.text =
                                      _userProfileData?['phone'] ?? '';
                                  // _passwordConfirmationController.clear(); // REMOVIDO
                                });
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red,
                                side: const BorderSide(color: Colors.red),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 15,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: Text(
                                "Cancelar",
                                style: GoogleFonts.lato(fontSize: 16),
                              ),
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _saveChanges,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context).primaryColor,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 15,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                elevation: 3,
                              ),
                              child: Text(
                                "Salvar Mudanças",
                                style: GoogleFonts.lato(
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      // Campos de exibição
                      _buildInfoCard(
                        label: "Email",
                        value: _userProfileData?['email'] ?? user.email,
                        icon: Icons.email_outlined,
                      ),
                      _buildInfoCard(
                        label: "Nome",
                        value: _userProfileData?['name'],
                        icon: Icons.person_outline,
                      ),
                      _buildInfoCard(
                        label: "Celular",
                        value: _userProfileData?['phone'],
                        icon: Icons.phone_outlined,
                      ),
                      _buildInfoCard(
                        label: "Profissão",
                        value: _userProfileData?['profession'],
                        icon: Icons.work_outline,
                      ),

                      const SizedBox(height: 30),
                      ElevatedButton.icon(
                        onPressed: () => setState(() => isEditing = true),
                        icon: const Icon(Icons.edit, color: Colors.white),
                        label: Text(
                          "Editar Informações",
                          style: GoogleFonts.lato(
                            color: Colors.white,
                            fontSize: 18,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 30,
                            vertical: 15,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 5,
                        ),
                      ),
                      const SizedBox(height: 15),
                      TextButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AboutScreen(),
                            ),
                          );
                        },
                        icon: const Icon(
                          Icons.info_outline,
                          color: Colors.grey,
                        ),
                        label: Text(
                          "Sobre o app",
                          style: GoogleFonts.lato(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 40,
                            vertical: 15,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 5,
                        ),
                        onPressed: () async {
                          await FirebaseAuth.instance.signOut();
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const WelcomeScreen(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.logout, color: Colors.white),
                        label: Text(
                          "Sair",
                          style: GoogleFonts.lato(
                            color: Colors.white,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
    );
  }

  // Helper para construir os campos de texto no modo de edição
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    bool readOnly = false,
    bool enabled = true,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      readOnly: readOnly,
      enabled: enabled,
      decoration: InputDecoration(
        labelText: label,
        hintText: 'Digite seu $label',
        prefixIcon: Icon(icon, color: Colors.green[700]),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: Colors.green.shade50,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 14.0,
          horizontal: 16.0,
        ),
      ),
      style: GoogleFonts.lato(fontSize: 16),
    );
  }

  // Helper para construir os cards de informação no modo de exibição
  Widget _buildInfoCard({
    required String label,
    String? value, // Agora pode ser nulo
    required IconData icon,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(icon, color: Colors.green[700], size: 24),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.lato(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value?.isNotEmpty == true
                        ? value!
                        : 'Não informado', // Exibe "Não informado" se o valor for nulo ou vazio
                    style: GoogleFonts.lato(
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Sobre o app",
          style: GoogleFonts.lato(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Flora Scan",
              style: GoogleFonts.lato(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.green[800],
              ),
            ),
            const SizedBox(height: 15),
            Text(
              """O Flora Scan é um aplicativo dedicado a ajudar entusiastas e profissionais a identificar, registrar e conhecer melhor as plantas ao seu redor. Desenvolvido com carinho, o app tem o objetivo de promover a conscientização ambiental, facilitar o estudo da flora local e ajudar em hobbies relacionados à plantação.

O app permite que os usuários tirem fotos de plantas e recebam informações gerais sobre elas. Além disso, o aplicativo oferece dicas de cuidados e informações sobre o habitat das plantas, tornando-se uma verdadeira ajuda para amantes da natureza.

""",
              style: GoogleFonts.lato(fontSize: 16, height: 1.5),
            ),
            const SizedBox(height: 20),
            Text(
              "Desenvolvido por:",
              style: GoogleFonts.lato(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.green[700],
              ),
            ),
            const SizedBox(height: 10),
            Text("""- FELIPE SILVA FARIA
- HUGO ALVES DUARTE
- MATHEUS HENRIQUE GONÇALVES
- PEDRO HENRIQUE GAIOSO
""", style: GoogleFonts.lato(fontSize: 16)),
            const SizedBox(height: 20),
            Text(
              "Versão do Aplicativo: 1.0.0", // Exemplo de versão
              style: GoogleFonts.lato(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }
}
