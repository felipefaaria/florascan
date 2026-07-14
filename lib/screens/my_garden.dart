import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:florascan/database/db.dart';
import 'package:florascan/widgets/plant_details_modal.dart'; // Importa o modal de detalhes
import 'dart:io'; // Para File.existsSync e Image.file

/// Tela para exibir e gerenciar os jardins (categorias) do usuário e suas plantas.
class MyGardenScreen extends StatefulWidget {
  const MyGardenScreen({super.key});

  @override
  State<MyGardenScreen> createState() => _MyGardenScreenState();
}

class _MyGardenScreenState extends State<MyGardenScreen> {
  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _plantsInSelectedCategory = [];
  int? _selectedCategoryId;
  String? _selectedCategoryName;
  bool _isLoading = true;
  String? _message; // Para exibir mensagens de sucesso/erro (overlay interno)

  @override
  void initState() {
    super.initState();
    _loadCategories(); // Começa carregando a lista de jardins
  }

  /// Callback unificado para recarregar dados com base na view atual.
  /// Chamado após operações como exclusão de planta ou adição a jardim.
  Future<void> _handleDataReload() async {
    if (_selectedCategoryId == null) {
      await _loadCategories(); // Recarrega a lista de jardins
    } else {
      await _loadPlantsInSelectedCategory(
        _selectedCategoryId!,
      ); // Recarrega as plantas do jardim atual
    }
  }

  /// Carrega as categorias (jardins) do banco de dados.
  Future<void> _loadCategories() async {
    setState(() {
      _isLoading = true;
      _message = null; // Limpa mensagens anteriores ao recarregar
    });
    try {
      final categories = await DB.instance.getCategorias();
      setState(() {
        _categories = categories;
      });
    } catch (e) {
      debugPrint('❌ Erro ao carregar categorias: $e');
      setState(() {
        _message = 'Erro ao carregar seus jardins.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Carrega as plantas para a categoria selecionada.
  Future<void> _loadPlantsInSelectedCategory(int categoryId) async {
    setState(() {
      _isLoading = true;
      _message = null; // Limpa mensagens anteriores ao recarregar
    });
    try {
      final plants = await DB.instance.getPlantasByCategoria(categoryId);
      setState(() {
        _plantsInSelectedCategory = plants;
      });
    } catch (e) {
      debugPrint('❌ Erro ao carregar plantas do jardim: $e');
      setState(() {
        _message = 'Erro ao carregar plantas deste jardim.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Exibe um diálogo para criar um novo jardim.
  Future<void> _createNewGardenDialog() async {
    String? newCategoryName;
    await showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Criar Novo Jardim'),
          content: TextField(
            onChanged: (value) {
              newCategoryName = value;
            },
            decoration: const InputDecoration(
              hintText: 'Nome do Jardim',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            ),
            autofocus: true,
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            ElevatedButton(
              child: const Text('Criar'),
              onPressed: () async {
                if (newCategoryName != null &&
                    newCategoryName!.trim().isNotEmpty) {
                  try {
                    // Verifica se o nome já existe
                    final existingCategory = await DB.instance
                        .getCategoriaByName(newCategoryName!);
                    if (existingCategory != null) {
                      if (mounted) {
                        _showMessage(
                          'Um jardim com este nome já existe.',
                          isError: true,
                        );
                        Navigator.of(dialogContext).pop();
                      }
                    } else {
                      await DB.instance.insertCategoria(newCategoryName!);
                      if (mounted) {
                        Navigator.of(dialogContext).pop();
                        _loadCategories(); // Recarrega a lista de jardins
                        _showMessage(
                          'Jardim "${newCategoryName!}" criado com sucesso!',
                        );
                      }
                    }
                  } catch (e) {
                    debugPrint('Erro ao criar jardim: $e');
                    if (mounted) {
                      _showMessage(
                        'Falha ao criar jardim: Erro inesperado.',
                        isError: true,
                      );
                      Navigator.of(dialogContext).pop();
                    }
                  }
                } else {
                  _showMessage(
                    'Nome do jardim não pode ser vazio.',
                    isError: true,
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  /// Exibe uma mensagem flutuante (overlay).
  void _showMessage(String message, {bool isError = false}) {
    final overlay = Overlay.of(context);
    OverlayEntry? overlayEntry;

    overlayEntry = OverlayEntry(
      builder:
          (context) => Positioned(
            bottom: 50.0,
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
                  color:
                      isError
                          ? Colors.red.withOpacity(0.8)
                          : Colors.green.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(10.0),
                ),
                child: Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 16.0),
                ),
              ),
            ),
          ),
    );

    overlay.insert(overlayEntry);

    Future.delayed(const Duration(seconds: 3), () {
      if (overlayEntry != null && overlayEntry.mounted) {
        overlayEntry.remove();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _selectedCategoryId == null ? "Meu Jardim" : _selectedCategoryName!,
        ),
        leading:
            _selectedCategoryId != null
                ? IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () {
                    setState(() {
                      _selectedCategoryId = null;
                      _selectedCategoryName = null;
                      _plantsInSelectedCategory = []; // Limpa plantas ao voltar
                      _handleDataReload(); // Recarrega a lista de categorias para atualizar contagens
                    });
                  },
                )
                : null,
        actions: [
          if (_selectedCategoryId ==
              null) // Apenas mostra o botão '+' na visão de categorias
            IconButton(
              icon: const Icon(
                Icons.add_box_outlined,
              ), // Ícone para criar novo jardim
              tooltip: 'Criar Novo Jardim',
              onPressed: _createNewGardenDialog,
            ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                children: [
                  if (_message != null) // Exibe mensagens de overlay
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        _message!,
                        style: TextStyle(
                          color:
                              _message!.contains('Erro')
                                  ? Colors.red
                                  : Colors.green,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  Expanded(
                    child:
                        _selectedCategoryId == null
                            ? _buildCategoryList() // Constrói a lista de categorias
                            : _buildPlantList(), // Constrói a lista de plantas
                  ),
                ],
              ),
    );
  }

  /// Constrói a lista de categorias (jardins).
  Widget _buildCategoryList() {
    if (_categories.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Nenhum jardim criado ainda.',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Criar seu primeiro jardim'),
              onPressed: _createNewGardenDialog,
            ),
          ],
        ),
      );
    } else {
      return ListView.builder(
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            child: ListTile(
              leading: const Icon(Icons.folder_shared, color: Colors.green),
              title: Text(
                category['nome'],
                style: GoogleFonts.lato(
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                ),
              ),
              subtitle: FutureBuilder<List<Map<String, dynamic>>>(
                future: DB.instance.getPlantasByCategoria(category['id']),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Text('Carregando plantas...');
                  }
                  if (snapshot.hasError) {
                    return const Text('Erro ao carregar contagem de plantas.');
                  }
                  final plantCount = snapshot.data?.length ?? 0;
                  return Text('$plantCount planta(s)');
                },
              ),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                setState(() {
                  _selectedCategoryId = category['id'];
                  _selectedCategoryName = category['nome'];
                });
                _handleDataReload(); // Carrega as plantas do jardim selecionado
              },
            ),
          );
        },
      );
    }
  }

  /// Constrói a lista de plantas dentro de um jardim selecionado.
  Widget _buildPlantList() {
    if (_plantsInSelectedCategory.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.local_florist, size: 60, color: Colors.grey),
            const SizedBox(height: 10),
            Text(
              'Nenhuma planta neste jardim ainda.',
              style: GoogleFonts.lato(fontSize: 18, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Text(
              'Adicione plantas através do botão "Adicionar ao Jardim" no detalhe da planta.',
              style: GoogleFonts.lato(fontSize: 16, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    } else {
      return ListView.builder(
        itemCount: _plantsInSelectedCategory.length,
        itemBuilder: (context, index) {
          final plant = _plantsInSelectedCategory[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            child: ListTile(
              leading:
                  plant['imagemPath'] != null &&
                          File(plant['imagemPath']).existsSync()
                      ? ClipRRect(
                        borderRadius: BorderRadius.circular(8.0),
                        child: Image.file(
                          File(plant['imagemPath']),
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                        ),
                      )
                      : const Icon(
                        Icons.image_outlined,
                        size: 50,
                        color: Colors.green,
                      ),
              title: Text(
                plant['nome'] ?? 'Nome Científico Desconhecido',
                style: GoogleFonts.lato(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              subtitle: Text(
                plant['descricao'] != null && plant['descricao'].isNotEmpty
                    ? plant['descricao']
                    : 'Nome comum não identificado',
                style: GoogleFonts.lato(fontSize: 14, color: Colors.grey[700]),
              ),
              trailing: IconButton(
                icon: const Icon(
                  Icons.remove_circle_outline,
                  color: Colors.red,
                ),
                onPressed: () async {
                  // Opção para remover a planta do jardim (setar categoria_id para null)
                  await DB.instance.updatePlanta({
                    'id': plant['id'],
                    'categoria_id': null,
                  });
                  _showMessage(
                    'Planta removida do jardim.',
                    isError: false,
                  ); // isError: false para sucesso
                  _handleDataReload(); // Recarrega a lista de plantas no jardim atual
                },
              ),
              onTap: () {
                // Abre o PlantDetailsModal para a planta clicada
                Navigator.push(
                  context,
                  PageRouteBuilder(
                    opaque: false,
                    pageBuilder:
                        (BuildContext context, _, __) => PlantDetailsModal(
                          planta: plant,
                          onPlantaExcluida:
                              _handleDataReload, // Passa o callback para recarregar
                        ),
                    transitionsBuilder: (
                      context,
                      animation,
                      secondaryAnimation,
                      child,
                    ) {
                      return FadeTransition(opacity: animation, child: child);
                    },
                  ),
                );
              },
            ),
          );
        },
      );
    }
  }
}
