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
      version: 3, // <-- VERSÃO DO BANCO DE DADOS ATUALIZADA PARA 3
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
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

    // NOVO: Cria tabela de Usuários
    await db.execute('''
      CREATE TABLE users (
        email TEXT PRIMARY KEY,
        name TEXT,
        profession TEXT,
        phone TEXT
      );
    ''');
  }

  // Função de upgrade para lidar com mudanças de esquema
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      debugPrint(
        'Executando upgrade do banco de dados de v$oldVersion para v$newVersion...',
      );
      await db.execute('DROP TABLE IF EXISTS plantas;');
      await db.execute('DROP TABLE IF EXISTS categoria;');
      await _onCreate(
        db,
        2,
      ); // Recria as tabelas antigas se a versão for menor que 2
    }
    if (oldVersion < 3) {
      // Adiciona a tabela 'users' se estiver atualizando da versão 2 para 3
      debugPrint(
        'Adicionando tabela "users" no upgrade de v$oldVersion para v$newVersion...',
      );
      await db.execute('''
        CREATE TABLE users (
          email TEXT PRIMARY KEY,
          name TEXT,
          profession TEXT,
          phone TEXT
        );
      ''');
    }
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

  // Buscar plantas por categoria_id
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

  // NOVO: Inserir ou atualizar dados do usuário
  Future<int> insertOrUpdateUser(Map<String, dynamic> user) async {
    final db = await database;
    final email = user['email'];
    if (email == null) {
      debugPrint(
        '❌ Erro: Email do usuário não fornecido para inserção/atualização.',
      );
      return 0;
    }
    // Tenta atualizar. Se nenhuma linha for afetada, insere.
    final rowsAffected = await db.update(
      'users',
      user,
      where: 'email = ?',
      whereArgs: [email],
      conflictAlgorithm:
          ConflictAlgorithm
              .replace, // Garante que se o email existir, ele substitui
    );
    if (rowsAffected == 0) {
      // Se não atualizou, tenta inserir
      return await db.insert(
        'users',
        user,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    debugPrint(
      'Usuário com email $email atualizado/inserido. Linhas afetadas: $rowsAffected',
    );
    return rowsAffected;
  }

  // NOVO: Buscar dados do usuário por email
  Future<Map<String, dynamic>?> getUserByEmail(String email) async {
    final db = await database;
    final result = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
    );
    if (result.isNotEmpty) {
      return result.first;
    }
    return null;
  }
}
