import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_application_1/database/db.dart'; // Importa seu DB
import 'package:flutter_application_1/utils/ai_service.dart'; // Importa a função da IA
import 'package:flutter_application_1/widgets/care_detail_card.dart'; // Importa o novo widget de Card

/// Um modal de tela cheia para exibir detalhes de uma planta.
/// Permite adicionar cuidados via IA e excluir a planta.
class PlantDetailsModal extends StatefulWidget {
  final Map<String, dynamic> planta;
  final VoidCallback onPlantaExcluida;

  const PlantDetailsModal({
    super.key,
    required this.planta,
    required this.onPlantaExcluida,
  });

  @override
  State<PlantDetailsModal> createState() => _PlantDetailsModalState();
}

class _PlantDetailsModalState extends State<PlantDetailsModal> {
  late Map<String, dynamic> _currentPlanta;
  bool _isLoadingCare = false;
  OverlayEntry? _overlayEntry; // Para gerenciar o overlay de mensagem

  @override
  void initState() {
    super.initState();
    _currentPlanta = Map<String, dynamic>.from(widget.planta);
  }

  @override
  void dispose() {
    _overlayEntry
        ?.remove(); // Garante que o overlay seja removido ao descartar o widget
    super.dispose();
  }

  // Helper para capitalizar a primeira letra
  String _capitalizeFirstLetter(String text) {
    if (text.isEmpty) {
      return text;
    }
    return text[0].toUpperCase() + text.substring(1);
  }

  // Método para exibir a mensagem como um overlay temporário
  void _showMessageOverlay(
    String message, {
    Color? backgroundColor,
    Color? textColor,
    Duration? duration,
  }) {
    // Remove qualquer overlay existente antes de adicionar um novo
    _overlayEntry?.remove();
    _overlayEntry = null;

    final overlay = Overlay.of(context);
    _overlayEntry = OverlayEntry(
      builder:
          (context) => Positioned(
            bottom: 50.0, // Posição na parte inferior da tela
            left: 20.0,
            right: 20.0,
            child: Material(
              color: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 12.0,
                ),
                decoration: BoxDecoration(
                  color: backgroundColor ?? Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(10.0),
                ),
                child: Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: textColor ?? Colors.white,
                    fontSize: 16.0,
                  ),
                ),
              ),
            ),
          ),
    );

    overlay.insert(_overlayEntry!);

    Future.delayed(duration ?? const Duration(seconds: 3), () {
      if (_overlayEntry != null && _overlayEntry!.mounted) {
        _overlayEntry!.remove();
        _overlayEntry = null;
      }
    });
  }

  /// Recarrega os detalhes da planta do banco de dados para atualizar o modal.
  Future<void> _reloadPlantaDetails() async {
    final updatedPlantas = await DB.instance.getPlantas();
    final foundPlant = updatedPlantas.firstWhere(
      (p) => p['id'] == _currentPlanta['id'],
      orElse: () => _currentPlanta,
    );

    if (mounted) {
      setState(() {
        _currentPlanta = Map<String, dynamic>.from(foundPlant);
      });
    }
  }

  /// Adiciona detalhes de cuidado à planta usando a IA e atualiza o banco de dados.
  Future<void> _adicionarCuidados() async {
    setState(() {
      _isLoadingCare = true;
    });

    final nomeCientifico = _currentPlanta['nome'];
    if (nomeCientifico != null && nomeCientifico.isNotEmpty) {
      _showMessageOverlay(
        'Buscando cuidados com IA...',
        backgroundColor: Colors.blueAccent,
        duration: const Duration(seconds: 2),
      );
      final novosCuidadosMap = await detalhesPlantaAI(nomeCientifico);

      if (novosCuidadosMap != null) {
        // Atualiza a cópia local do mapa com os novos dados
        _currentPlanta['agua'] = novosCuidadosMap['agua'];
        _currentPlanta['solo'] = novosCuidadosMap['solo'];
        _currentPlanta['bioma'] = novosCuidadosMap['bioma'];
        _currentPlanta['harmonizacao'] = novosCuidadosMap['harmonizacao'];

        final plantaParaAtualizar = Map<String, dynamic>.from(_currentPlanta);
        // Remove 'categoria_nome' pois não é uma coluna da tabela 'plantas'.
        plantaParaAtualizar.remove('categoria_nome');

        final resultado = await DB.instance.updatePlanta(plantaParaAtualizar);

        if (mounted) {
          if (resultado > 0) {
            _showMessageOverlay(
              'Cuidados atualizados com sucesso!',
              backgroundColor: Colors.green,
            );
            await _reloadPlantaDetails(); // Recarrega os detalhes no próprio modal
            widget
                .onPlantaExcluida(); // Notifica a Grade para recarregar a lista
          } else {
            _showMessageOverlay(
              'Falha ao atualizar planta.',
              backgroundColor: Colors.red,
            );
          }
        }
      } else {
        if (mounted) {
          _showMessageOverlay(
            'Não foi possível obter os cuidados da planta.',
            backgroundColor: Colors.orange,
          );
        }
      }
    } else {
      if (mounted) {
        _showMessageOverlay(
          'Nome da planta não disponível para buscar cuidados.',
          backgroundColor: Colors.blueGrey,
        );
      }
    }
    setState(() {
      _isLoadingCare = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final imagemPath = _currentPlanta['imagemPath'];
    final String nomeComum =
        _currentPlanta['descricao'] != null &&
                _currentPlanta['descricao'].isNotEmpty
            ? _currentPlanta['descricao']
            : 'Nome não identificado'; // Exibe "Nome não identificado"

    final String agua = _capitalizeFirstLetter(_currentPlanta['agua'] ?? 'N/A');
    final String solo = _capitalizeFirstLetter(_currentPlanta['solo'] ?? 'N/A');
    final String bioma = _capitalizeFirstLetter(
      _currentPlanta['bioma'] ?? 'N/A',
    );
    final String harmonizacao = _capitalizeFirstLetter(
      _currentPlanta['harmonizacao'] ?? 'N/A',
    );

    // A flag cuidadosPreenchidos agora controla a visibilidade dos detalhes de cuidado
    bool cuidadosPreenchidos =
        agua != 'N/A' ||
        solo != 'N/A' ||
        bioma != 'N/A' ||
        harmonizacao != 'N/A';

    return Scaffold(
      // Modal flutuante de tela cheia
      backgroundColor: Colors.white.withOpacity(
        0.95,
      ), // Fundo levemente transparente
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.green),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Título da Planta
              Center(
                child: Text(
                  _currentPlanta['nome'] ?? 'Nome Científico',
                  style: GoogleFonts.lato(
                    fontSize: 26, // Aumentado um pouco o tamanho
                    fontWeight: FontWeight.bold,
                    color: Colors.green[800],
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 15),

              // Imagem da Planta
              if (imagemPath != null && File(imagemPath).existsSync())
                Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(
                      15.0,
                    ), // Bordas mais arredondadas
                    child: Image.file(
                      File(imagemPath),
                      height: 220, // Aumentado o tamanho da imagem
                      width: 220,
                      fit: BoxFit.cover,
                    ),
                  ),
                )
              else
                Center(
                  child: Container(
                    height: 220,
                    width: 220,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(15.0),
                      border: Border.all(
                        color: Colors.grey.shade400,
                      ), // Adiciona uma borda
                    ),
                    child: const Icon(
                      Icons.image_not_supported,
                      size: 100, // Aumentado o tamanho do ícone
                      color: Colors.black26,
                    ),
                  ),
                ),
              const SizedBox(height: 25),

              // Card para Nome Comum
              Card(
                elevation: 4, // Sombra maior
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ), // Bordas mais arredondadas
                margin: const EdgeInsets.symmetric(vertical: 10.0),
                child: Padding(
                  padding: const EdgeInsets.all(16.0), // Mais padding
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.tag_faces,
                            color: Colors.green[700],
                            size: 24,
                          ), // Ícone mais sugestivo
                          const SizedBox(width: 10),
                          Text(
                            "Nome Comum:", // Alterado para Nome Comum
                            style: GoogleFonts.lato(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: Colors.green[800],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(nomeComum, style: const TextStyle(fontSize: 16)),
                    ],
                  ),
                ),
              ),

              // Condicional para o botão "Adicionar Cuidados" ou os detalhes dos cuidados
              if (_isLoadingCare)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20.0),
                    child: CircularProgressIndicator(color: Colors.green),
                  ),
                )
              else if (!cuidadosPreenchidos) // Mostra o botão se os cuidados não foram preenchidos
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20.0),
                    child: ElevatedButton.icon(
                      onPressed: _adicionarCuidados,
                      icon: const Icon(Icons.auto_awesome, color: Colors.white),
                      label: const Text(
                        'Adicionar Cuidados (IA)',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 25,
                          vertical: 15,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 5, // Sombra para o botão
                      ),
                    ),
                  ),
                )
              else // Mostra os detalhes dos cuidados se já foram preenchidos
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 15),
                    Text(
                      "Detalhes de Cuidados:",
                      style: GoogleFonts.lato(
                        fontSize: 20, // Tamanho maior
                        fontWeight: FontWeight.bold,
                        color: Colors.green[800],
                      ),
                    ),
                    const SizedBox(height: 15),
                    CareDetailCard(
                      icon: Icons.water_drop,
                      iconColor: Colors.blue,
                      title: "Água:",
                      value: agua,
                    ),
                    CareDetailCard(
                      icon: Icons.grass,
                      iconColor: Colors.brown,
                      title: "Solo:",
                      value: solo,
                    ),
                    CareDetailCard(
                      icon: Icons.public,
                      iconColor: Colors.lightGreen,
                      title: "Bioma:",
                      value: bioma,
                    ),
                    CareDetailCard(
                      icon: Icons.local_florist,
                      iconColor: Colors.purple,
                      title: "Harmoniza com:",
                      value: harmonizacao,
                    ),
                  ],
                ),

              const SizedBox(height: 30), // Mais espaço na parte inferior
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red[600],
                    ),
                    child: const Text(
                      'Fechar',
                      style: TextStyle(fontSize: 16, color: Colors.red),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () async {
                      if (_currentPlanta['id'] != null) {
                        try {
                          await DB.instance.deletePlanta(_currentPlanta['id']);
                          if (mounted) {
                            _showMessageOverlay(
                              'Planta excluída com sucesso!',
                              backgroundColor: Colors.grey,
                            );
                            Navigator.of(
                              context,
                            ).pop(); // Fecha o PlantDetailsModal
                            widget
                                .onPlantaExcluida(); // Notifica a Grade para recarregar
                          }
                        } catch (e) {
                          print('Erro ao excluir planta: $e');
                          if (mounted) {
                            _showMessageOverlay(
                              'Erro ao excluir planta.',
                              backgroundColor: Colors.red,
                            );
                          }
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 3,
                    ),
                    child: const Text(
                      'Excluir',
                      style: TextStyle(color: Colors.white, fontSize: 16),
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
