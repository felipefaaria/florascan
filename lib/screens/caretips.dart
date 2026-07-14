import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Tela de Dicas de Cuidados Gerais para Plantas.
/// Oferece um guia visual e profissional sobre como cuidar de plantas,
/// podendo incluir seções para diferentes tipos de dicas ou notícias.
class CaretipsScreen extends StatelessWidget {
  const CaretipsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Care Tips',
          style: GoogleFonts.lato(
            fontWeight: FontWeight.bold,
            color: Colors.green[800],
          ),
        ),
        centerTitle: true,
        backgroundColor:
            Colors.green.shade50, // Cor de fundo suave para a AppBar
        elevation: 0, // Sem sombra na AppBar
        iconTheme: IconThemeData(
          color: Colors.green[800],
        ), // Cor do ícone de voltar
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Guia Essencial para Jardineiros',
              style: GoogleFonts.lato(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: Colors.green[700],
              ),
            ),
            const SizedBox(height: 20),

            // Seção de Dica Rápida / Destaque
            _buildTipCard(
              context,
              icon: Icons.lightbulb_outline,
              iconColor: Colors.amber,
              title: 'Dica Rápida: Rega Consciente',
              content:
                  'A maioria das plantas prefere ser regada profundamente, mas com menos frequência. Verifique a umidade do solo antes de regar novamente para evitar o excesso de água, que pode apodrecer as raízes.',
              backgroundColor: Colors.amber.shade50,
            ),
            const SizedBox(height: 20),

            Text(
              'Categorias de Cuidados',
              style: GoogleFonts.lato(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.green[800],
              ),
            ),
            const SizedBox(height: 15),

            // Grade de Categorias de Cuidados
            GridView.count(
              shrinkWrap: true, // Para o GridView se ajustar ao Column
              physics:
                  const NeverScrollableScrollPhysics(), // Desabilita rolagem própria
              crossAxisCount: 2,
              crossAxisSpacing: 15.0,
              mainAxisSpacing: 15.0,
              children: [
                _buildCategoryCard(
                  context,
                  Icons.water_drop,
                  'Rega',
                  Colors.blue,
                ),
                _buildCategoryCard(
                  context,
                  Icons.sunny,
                  'Luz Solar',
                  Colors.orange,
                ),
                _buildCategoryCard(
                  context,
                  Icons.grass,
                  'Solo e Adubação',
                  Colors.brown,
                ),
                _buildCategoryCard(
                  context,
                  Icons.thermostat_auto,
                  'Temperatura',
                  Colors.red,
                ),
                _buildCategoryCard(
                  context,
                  Icons.pest_control,
                  'Pragas e Doenças',
                  Colors.purple,
                ),
                _buildCategoryCard(
                  context,
                  Icons.grass_outlined,
                  'Poda',
                  Colors.teal,
                ),
              ],
            ),
            const SizedBox(height: 30),

            Text(
              'Notícias e Tendências',
              style: GoogleFonts.lato(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.green[800],
              ),
            ),
            const SizedBox(height: 15),

            // Seção de Notícias (com imagens do Placehold.co)
            _buildNewsItem(
              context,
              'Novas Pesquisas Revelam Benefícios de Plantas Nativas',
              'Estudos recentes mostram como o cultivo de plantas nativas pode impulsionar a biodiversidade local...',
              'assets/images/plant_care.jpg',
            ),
            const SizedBox(height: 15),
            _buildNewsItem(
              context,
              'Tendência: Jardins Verticais em Espaços Urbanos',
              'Descubra como os jardins verticais estão transformando varandas e paredes em oásis verdes...',
              'assets/images/verticalplant.jpg',
            ),

            const SizedBox(height: 15),
          ],
        ),
      ),
    );
  }

  // Widget auxiliar para construir cards de dicas
  Widget _buildTipCard(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String content,
    Color? backgroundColor,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      color: backgroundColor ?? Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: iconColor, size: 30),
                const SizedBox(width: 15),
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.lato(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green[800],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              content,
              style: GoogleFonts.lato(fontSize: 15, color: Colors.black87),
            ),
          ],
        ),
      ),
    );
  }

  // Widget auxiliar para construir cards de categoria
  Widget _buildCategoryCard(
    BuildContext context,
    IconData icon,
    String title,
    Color color,
  ) {
    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Categoria: $title (Em breve mais detalhes!)'),
          ),
        );
      },
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: color),
            const SizedBox(height: 10),
            Text(
              title,
              style: GoogleFonts.lato(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.green[700],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // Widget auxiliar para construir itens de notícia
  // Widget auxiliar para construir itens de notícia
  Widget _buildNewsItem(
    BuildContext context,
    String title,
    String snippet,
    String imagePath, // agora é local
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Image.asset(
            imagePath,
            height: 150,
            width: double.infinity,
            fit: BoxFit.cover,
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.lato(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[800],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  snippet,
                  style: GoogleFonts.lato(fontSize: 14, color: Colors.black87),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.bottomRight,
                  child: TextButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Lendo mais... (Funcionalidade em desenvolvimento)',
                          ),
                        ),
                      );
                    },
                    child: Text(
                      'Ler Mais',
                      style: GoogleFonts.lato(
                        color: Colors.blueAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
