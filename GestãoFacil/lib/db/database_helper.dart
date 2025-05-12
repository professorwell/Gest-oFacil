// lib/db/database_helper.dart
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/transacao_model.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('gestaofacil.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE transacoes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        tipo TEXT NOT NULL,
        descricao TEXT NOT NULL,
        valor REAL NOT NULL,
        data TEXT NOT NULL
      )
    ''');
  }

  /// Insere uma venda (à vista ou fiado) baseada na fala do usuário
  Future<void> inserirVenda(String fala, String tipo) async {
    final db = await instance.database;

    // Captura o primeiro número na fala (com ponto ou vírgula)
    final regex = RegExp(r'(\d+[\,\.]?\d*)');
    final match = regex.firstMatch(fala);

    // Converte para double
    double valor = 0.0;
    if (match != null) {
      final raw = match.group(0)!.replaceAll(',', '.');
      valor = double.tryParse(raw) ?? 0.0;
    }

    // Ajusta descrição removendo o número
    String descricao = fala;
    if (match != null) {
      descricao = fala.replaceFirst(match.group(0)!, '').trim();
    }

    final transacao = Transacao(
      // id fica nulo para auto-increment
      tipo: tipo,
      descricao: descricao,
      valor: valor,
      data: DateTime.now().toIso8601String(),
    );

    await db.insert('transacoes', transacao.toMap());
  }

  /// Lista todas as transações, ou filtra por tipo ('avista' / 'fiado')
  Future<List<Transacao>> listarTransacoes({String? tipo}) async {
    final db = await instance.database;
    final maps = await db.query(
      'transacoes',
      where: tipo != null ? 'tipo = ?' : null,
      whereArgs: tipo != null ? [tipo] : null,
      orderBy: 'data DESC',
    );
    return maps.map((m) => Transacao.fromMap(m)).toList();
  }

  /// Atualiza uma transação já existente (pelo id)
  Future<int> atualizarTransacao(Transacao t) async {
    final db = await instance.database;
    return db.update(
      'transacoes',
      t.toMap(),
      where: 'id = ?',
      whereArgs: [t.id],
    );
  }

  /// Exclui uma transação pelo id
  Future<int> excluirTransacao(int id) async {
    final db = await instance.database;
    return db.delete(
      'transacoes',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
