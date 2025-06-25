import 'package:flutter/material.dart';
import 'package:flutter_application_1/screens/caretips.dart';
import 'package:google_fonts/google_fonts.dart';
import './my_garden.dart';

class InitialHomeScreen extends StatelessWidget {
  const InitialHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // ✅ Ícone com cor verde
              Icon(
                Icons.local_florist,
                size: 100,
                color: Color.fromARGB(255, 0, 141, 31),
              ),
              SizedBox(height: 20),
              // ✅ Título em verde
              Text(
                "FloraScan",
                style: GoogleFonts.lato(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Color.fromARGB(255, 0, 141, 31),
                ),
              ),
              SizedBox(height: 10),
              // ✅ Subtítulo em verde escuro
              Text(
                "Identifique plantas e aprenda a cuidar delas com facilidade.",
                textAlign: TextAlign.center,
                style: GoogleFonts.lato(fontSize: 16, color: Color(0xFF2E7D32)),
              ),
              SizedBox(height: 40),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => MyGardenScreen()),
                  );
                },
                icon: Icon(Icons.photo),
                label: Text("Meu Jardim"),
              ),
              SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => CaretipsScreen()),
                  );
                },
                icon: Icon(Icons.local_florist),
                label: Text("Dicas de Cuidados"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
