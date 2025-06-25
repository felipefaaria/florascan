import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/foundation.dart'; // Importado para debugPrint

class DB {
  DB._();
  static final DB instance = DB._();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, 'plantas.db');
    debugPrint(
      'Database Path: $path',
    ); // Imprimindo o caminho do banco de dados
    return await openDatabase(
      path,
      version: 2, // <-- VERSÃO DO BANCO DE DADOS ATUALIZADA PARA 2
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: _onCreate,
      onUpgrade: _onUpgrade, // Mudado de _onUpgradeSafe para _onUpgrade
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Cria tabela Categoria primeiro
    await db.execute('''
      CREATE TABLE categoria (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nome TEXT NOT NULL UNIQUE
      );
    ''');

    // Cria tabela Plantas com relação 1:N e os novos campos de cuidados
    await db.execute('''
      CREATE TABLE plantas (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nome TEXT NOT NULL,
        descricao TEXT,
        cuidados TEXT,        -- Mantido para compatibilidade ou uso futuro
        imagemPath TEXT,
        agua TEXT,            -- NOVO CAMPO
        solo TEXT,            -- NOVO CAMPO
        bioma TEXT,           -- NOVO CAMPO
        harmonizacao TEXT,    -- NOVO CAMPO
        categoria_id INTEGER,
        FOREIGN KEY (categoria_id) REFERENCES categoria(id) ON DELETE SET NULL
      );
    ''');
  }

  // Função de upgrade para lidar com mudanças de esquema
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Se a versão antiga for menor que 2, recriamos as tabelas para incluir os novos campos
    if (oldVersion < 2) {
      debugPrint(
        'Executando upgrade do banco de dados de v$oldVersion para v$newVersion...',
      );
      await db.execute('DROP TABLE IF EXISTS plantas;');
      await db.execute('DROP TABLE IF EXISTS categoria;');
      await _onCreate(db, newVersion);
      debugPrint('Upgrade completo: tabelas recriadas com novos campos.');
    }
    // Adicione mais blocos `if (oldVersion < X)` para futuras migrações
  }

  // Inserir categoria
  Future<int> insertCategoria(String nome) async {
    final db = await database;
    try {
      return await db.insert('categoria', {'nome': nome});
    } catch (e) {
      debugPrint('Erro ao inserir categoria: $e');
      rethrow; // Relança o erro para ser tratado no UI
    }
  }

  // Buscar categoria por nome
  Future<Map<String, dynamic>?> getCategoriaByName(String nome) async {
    final db = await database;
    final result = await db.query(
      'categoria',
      where: 'nome = ?',
      whereArgs: [nome],
    );
    if (result.isNotEmpty) {
      return result.first;
    }
    return null;
  }

  // Inserir planta e retornar todos os elementos da tabela plantas no console
  Future<int> insertPlanta(Map<String, dynamic> planta) async {
    final db = await database;
    final id = await db.insert('plantas', planta);

    // Busca todos os elementos da tabela plantas
    final todasPlantas = await db.query('plantas');

    // Imprime os elementos no console
    debugPrint(
      '\n\n\n\n\n=== Conteúdo da tabela plantas (após inserção com id: $id) ===',
    );
    for (var row in todasPlantas) {
      debugPrint(row.toString());
    }
    debugPrint('============================================================');

    return id;
  }

  // Atualizar planta
  Future<int> updatePlanta(Map<String, dynamic> planta) async {
    final db = await database;
    final id = planta['id'];
    if (id == null) {
      debugPrint('❌ Erro: ID da planta não fornecido para atualização.');
      return 0;
    }
    final rowsAffected = await db.update(
      'plantas',
      planta,
      where: 'id = ?',
      whereArgs: [id],
    );
    debugPrint('Planta com ID $id atualizada. Linhas afetadas: $rowsAffected');
    return rowsAffected;
  }

  // Deletar planta
  Future<int> deletePlanta(int id) async {
    final db = await database;
    return await db.delete('plantas', where: 'id = ?', whereArgs: [id]);
  }

  // Buscar todas as plantas
  Future<List<Map<String, dynamic>>> getPlantas() async {
    final db = await database;
    return await db.query('plantas');
  }

  // Buscar plantas com o nome da categoria (JOIN)
  Future<List<Map<String, dynamic>>> getPlantasComCategoria() async {
    final db = await database;
    return await db.rawQuery('''
      SELECT plantas.*, categoria.nome AS categoria_nome
      FROM plantas
      LEFT JOIN categoria ON plantas.categoria_id = categoria.id
    ''');
  }

  // NOVO: Buscar plantas por categoria_id
  Future<List<Map<String, dynamic>>> getPlantasByCategoria(
    int categoriaId,
  ) async {
    final db = await database;
    return await db.query(
      'plantas',
      where: 'categoria_id = ?',
      whereArgs: [categoriaId],
      orderBy: 'nome ASC', // Ordena pelo nome para uma lista organizada
    );
  }

  // Buscar todas as categorias
  Future<List<Map<String, dynamic>>> getCategorias() async {
    final db = await database;
    return await db.query('categoria', orderBy: 'nome ASC'); // Ordena por nome
  }
}
