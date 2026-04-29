import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/message.dart';
import '../models/tag.dart';

class DatabaseService {
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'quick_reply.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE messages(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        content TEXT NOT NULL,
        images TEXT,
        files TEXT,
        tags TEXT,
        level TEXT NOT NULL,
        groupId TEXT,
        userId INTEGER NOT NULL,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE tags(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        color TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE users(
        id INTEGER PRIMARY KEY,
        name TEXT NOT NULL,
        role TEXT NOT NULL,
        groupId TEXT,
        companyId TEXT
      )
    ''');

    await _insertSampleData(db);
  }

  Future<void> _insertSampleData(Database db) async {
    // 鎻掑叆绀轰緥鏍囩
    await db.insert('tags', {'name': '娆㈣繋璇?, 'color': '#10B981'});
    await db.insert('tags', {'name': '鍜ㄨ', 'color': '#F59E0B'});
    await db.insert('tags', {'name': '鍞悗', 'color': '#EF4444'});
    await db.insert('tags', {'name': '娲诲姩', 'color': '#8B5CF6'});
    await db.insert('tags', {'name': '甯哥敤', 'color': '#2563EB'});

    // 鎻掑叆绀轰緥璇濇湳
    final now = DateTime.now().toIso8601String();
    
    await db.insert('messages', {
      'title': '鏂板鎴锋杩庤',
      'content': '鎮ㄥソ锛屾杩庡厜涓达紒鎰熻阿鎮ㄧ殑淇′换锛屾垜鏄偍鐨勪笓灞炲鏈嶏紝鏈変换浣曢棶棰橀殢鏃惰仈绯绘垜~',
      'images': '',
      'files': '',
      'tags': '娆㈣繋璇?甯哥敤',
      'level': 'company',
      'groupId': null,
      'userId': 1,
      'createdAt': now,
      'updatedAt': now,
    });

    await db.insert('messages', {
      'title': '鍙戣揣鎻愰啋',
      'content': '浜诧紝鎮ㄧ殑璁㈠崟宸插彂璐у暒锛侀璁?-5澶╅€佽揪锛岃淇濇寔鎵嬫満鐣呴€氬摝~ 鏀跺埌璐у悗鏈変换浣曢棶棰樻杩庨殢鏃惰仈绯绘垜浠紒',
      'images': '',
      'files': '',
      'tags': '鍞悗,甯哥敤',
      'level': 'company',
      'groupId': null,
      'userId': 1,
      'createdAt': now,
      'updatedAt': now,
    });

    await db.insert('messages', {
      'title': '娲诲姩浠嬬粛',
      'content': '馃帀 闄愭椂浼樻儬娲诲姩杩涜涓紒鍏ㄥ満8鎶橈紝婊?99鍑?0锛岀偣鍑婚摼鎺ラ鍙栦紭鎯犲埜锛歺xx',
      'images': '',
      'files': '',
      'tags': '娲诲姩',
      'level': 'group',
      'groupId': 'group_1',
      'userId': 1,
      'createdAt': now,
      'updatedAt': now,
    });

    await db.insert('messages', {
      'title': '鎴戠殑涓撳睘璇濇湳',
      'content': '杩欐槸鎴戝父鐢ㄧ殑鍥炲妯℃澘锛屾柟渚垮揩鎹穨',
      'images': '',
      'files': '',
      'tags': '甯哥敤',
      'level': 'private',
      'groupId': null,
      'userId': 1,
      'createdAt': now,
      'updatedAt': now,
    });
  }

  // Message CRUD
  Future<List<Message>> getMessages({String? level, String? userId}) async {
    final db = await database;
    List<Map<String, dynamic>> maps = await db.query(
      'messages',
      where: level != null ? 'level = ?' : null,
      whereArgs: level != null ? [level] : null,
      orderBy: 'updatedAt DESC',
    );
    return maps.map((map) => Message.fromMap(map)).toList();
  }

  Future<int> insertMessage(Message message) async {
    final db = await database;
    return await db.insert('messages', message.toMap()..remove('id'));
  }

  Future<int> updateMessage(Message message) async {
    final db = await database;
    return await db.update(
      'messages',
      message.toMap(),
      where: 'id = ?',
      whereArgs: [message.id],
    );
  }

  Future<int> deleteMessage(int id) async {
    final db = await database;
    return await db.delete(
      'messages',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Message>> searchMessages(String keyword) async {
    final db = await database;
    List<Map<String, dynamic>> maps = await db.query(
      'messages',
      where: 'title LIKE ? OR content LIKE ? OR tags LIKE ?',
      whereArgs: ['%$keyword%', '%$keyword%', '%$keyword%'],
      orderBy: 'updatedAt DESC',
    );
    return maps.map((map) => Message.fromMap(map)).toList();
  }

  // Tag CRUD
  Future<List<Tag>> getTags() async {
    final db = await database;
    List<Map<String, dynamic>> maps = await db.query('tags');
    return maps.map((map) => Tag.fromMap(map)).toList();
  }

  Future<int> insertTag(Tag tag) async {
    final db = await database;
    return await db.insert('tags', tag.toMap()..remove('id'));
  }

  // User
  Future<void> insertUser(Map<String, dynamic> user) async {
    final db = await database;
    await db.insert('users', user);
  }

  Future<Map<String, dynamic>?> getUser() async {
    final db = await database;
    List<Map<String, dynamic>> users = await db.query('users', limit: 1);
    return users.isNotEmpty ? users.first : null;
  }
}
