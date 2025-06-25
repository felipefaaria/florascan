import 'package:flutter/material.dart';
import 'welcome_screen.dart';
import './login_screen.dart';
import './signup_screen.dart';
import '../main.dart';

class LoginChoiceScreen extends StatefulWidget {
  const LoginChoiceScreen({super.key});

  @override
  State<LoginChoiceScreen> createState() => _LoginChoiceScreenState();
}

class _LoginChoiceScreenState extends State<LoginChoiceScreen> {
  final int _selectedIndex = 1;

  void _onItemTapped(int index) {
    if (index == 0) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const WelcomeScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Você pode se conectar com sua conta ou continuar como convidado.",
              style: TextStyle(fontSize: 18),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              icon: const Icon(Icons.login),
              label: const Text("Fazer Login"),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                );
              },
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.person_add),
              label: const Text("Cadastrar"),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SignUpScreen()),
                );
              },
            ),
            const SizedBox(height: 16), // Espaço entre os botões
            ElevatedButton.icon(
              icon: const Icon(Icons.person), // Ícone para convidado
              label: const Text("Entrar como convidado"),
              onPressed: () {
                // Navega para a HomeScreen substituindo a tela atual
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => HomeScreen()),
                );
              },
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Início'),
          BottomNavigationBarItem(icon: Icon(Icons.login), label: 'Login'),
        ],
      ),
    );
  }
}
