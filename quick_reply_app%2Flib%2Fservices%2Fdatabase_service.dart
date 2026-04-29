import 'dart:convert';
import 'dart:io';
import 'package:archive/archive_io.dart';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:excel/excel.dart';
import '../models/message.dart';
import '../models/tag.dart';
import '../models/customer.dart';
import '../models/call_record.dart';

class DatabaseService {
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'quick_reply.db');
    final db = await openDatabase(
      path,
      version: 6,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
    await _normalizeLevelValues(db);
    return db;
  }

  /// 灏嗘暟鎹簱涓腑鏂囩殑 level 鍊肩粺涓€杞负鑻辨枃
  Future<void> _normalizeLevelValues(Database db) async {
    try {
      await db.execute("UPDATE messages SET level = 'company' WHERE level IN ('鍏徃绾?, '鍏徃', 'Company')");
      await db.execute("UPDATE messages SET level = 'group' WHERE level IN ('灏忕粍绾?, '灏忕粍', 'Group')");
      await db.execute("UPDATE messages SET level = 'private' WHERE level IN ('绉佷汉', '鎴戠殑', '涓汉', 'Private')");
      await db.execute("UPDATE categories SET level = 'company' WHERE level IN ('鍏徃绾?, '鍏徃', 'Company')");
      await db.execute("UPDATE categories SET level = 'group' WHERE level IN ('灏忕粍绾?, '灏忕粍', 'Group')");
      await db.execute("UPDATE categories SET level = 'private' WHERE level IN ('绉佷汉', '鎴戠殑', '涓汉', 'Private')");
    } catch (e) {
      // 闈欓粯澶勭悊,涓嶅奖鍝嶅簲鐢ㄥ惎鍔?    }
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // 娣诲姞level瀛楁鍒癱ategories琛?      await db.execute('ALTER TABLE categories ADD COLUMN level TEXT DEFAULT "company"');
    }
    if (oldVersion < 3) {
      // 娣诲姞customers琛?鏃х増)
      await db.execute('''
        CREATE TABLE IF NOT EXISTS customers(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          phone TEXT,
          wechat TEXT,
          email TEXT,
          company TEXT,
          position TEXT,
          address TEXT,
          tags TEXT,
          notes TEXT,
          createdAt TEXT NOT NULL,
          updatedAt TEXT NOT NULL
        )
      ''');
    }
    if (oldVersion < 4) {
      // 鍗囩骇customers琛ㄧ粨鏋?      // 澶囦唤鏃ф暟鎹?      final oldCustomers = await db.query('customers');
      // 鍒犻櫎鏃ц〃
      await db.execute('DROP TABLE IF EXISTS customers');
      // 鍒涘缓鏂拌〃
      await db.execute('''
        CREATE TABLE customers(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          followDate TEXT NOT NULL,
          company TEXT NOT NULL,
          name TEXT NOT NULL,
          phone TEXT,
          researchGroup TEXT,
          product TEXT,
          followResult TEXT,
          category TEXT DEFAULT '鏈垎绫?,
          isPinned INTEGER DEFAULT 0,
          createdAt TEXT NOT NULL,
          updatedAt TEXT NOT NULL
        )
      ''');
      // 鎭㈠鏁版嵁(灏藉彲鑳芥槧灏?
      for (var old in oldCustomers) {
        await db.insert('customers', {
          'followDate': old['createdAt'] ?? DateTime.now().toIso8601String(),
          'company': old['company'] ?? '',
          'name': old['name'] ?? '',
          'phone': old['phone'],
          'researchGroup': null,
          'product': null,
          'followResult': null,
          'category': '鏈垎绫?,
          'isPinned': 0,
          'createdAt': old['createdAt'],
          'updatedAt': old['updatedAt'],
        });
      }
    }
    if (oldVersion < 5) {
      // 鍒涘缓瀹㈡埛鍒嗙被琛?      await db.execute('''
        CREATE TABLE customer_categories(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          color TEXT NOT NULL,
          sort INTEGER DEFAULT 0
        )
      ''');
      // 鎻掑叆榛樿瀹㈡埛鍒嗙被
      await db.insert('customer_categories', {'name': '鎰忓悜瀹㈡埛', 'color': '#10B981', 'sort': 0});
      await db.insert('customer_categories', {'name': '宸叉垚浜?, 'color': '#2563EB', 'sort': 1});
      await db.insert('customer_categories', {'name': '宸叉祦澶?, 'color': '#EF4444', 'sort': 2});
      await db.insert('customer_categories', {'name': '鏈垎绫?, 'color': '#9CA3AF', 'sort': 99});
    }
    if (oldVersion < 6) {
      // 鍒涘缓閫氳瘽璁板綍琛?      await db.execute('''
        CREATE TABLE call_logs(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          phone_number TEXT NOT NULL,
          contact_name TEXT DEFAULT '',
          duration_seconds INTEGER DEFAULT 0,
          start_time TEXT NOT NULL,
          end_time TEXT NOT NULL,
          call_type TEXT DEFAULT 'outgoing',
          notes TEXT
        )
      ''');
    }
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
        category TEXT DEFAULT '鏈垎绫?,
        subcategory TEXT,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE categories(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        color TEXT NOT NULL,
        parentId INTEGER,
        sort INTEGER DEFAULT 0,
        level TEXT DEFAULT 'company'
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

    await db.execute('''
      CREATE TABLE customers(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        followDate TEXT NOT NULL,
        company TEXT NOT NULL,
        name TEXT NOT NULL,
        phone TEXT,
        researchGroup TEXT,
        product TEXT,
        followResult TEXT,
        category TEXT DEFAULT '鏈垎绫?,
        isPinned INTEGER DEFAULT 0,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE customer_categories(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        color TEXT NOT NULL,
        sort INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE call_logs(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        phone_number TEXT NOT NULL,
        contact_name TEXT DEFAULT '',
        duration_seconds INTEGER DEFAULT 0,
        start_time TEXT NOT NULL,
        end_time TEXT NOT NULL,
        call_type TEXT DEFAULT 'outgoing',
        notes TEXT
      )
    ''');

    await _insertSampleData(db);
  }

  Future<void> _insertSampleData(Database db) async {
    // 鎻掑叆绀轰緥鍒嗙被(涓€绾?- company 绾у埆
    await db.insert('categories', {'name': '娆㈣繋璇?, 'color': '#10B981', 'parentId': null, 'sort': 0, 'level': 'company'});
    await db.insert('categories', {'name': '鍜ㄨ', 'color': '#F59E0B', 'parentId': null, 'sort': 1, 'level': 'company'});
    await db.insert('categories', {'name': '鍞悗', 'color': '#EF4444', 'parentId': null, 'sort': 2, 'level': 'company'});
    await db.insert('categories', {'name': '娲诲姩', 'color': '#8B5CF6', 'parentId': null, 'sort': 3, 'level': 'group'});
    await db.insert('categories', {'name': '甯哥敤', 'color': '#2563EB', 'parentId': null, 'sort': 4, 'level': 'private'});

    // 鎻掑叆绀轰緥瀛愬垎绫?浜岀骇)
    await db.insert('categories', {'name': '鏂板鎴?, 'color': '#10B981', 'parentId': 1, 'sort': 0, 'level': 'company'});
    await db.insert('categories', {'name': '鑰佸鎴?, 'color': '#10B981', 'parentId': 1, 'sort': 1, 'level': 'company'});
    await db.insert('categories', {'name': '浜у搧鍜ㄨ', 'color': '#F59E0B', 'parentId': 2, 'sort': 0, 'level': 'company'});
    await db.insert('categories', {'name': '浠锋牸鍜ㄨ', 'color': '#F59E0B', 'parentId': 2, 'sort': 1, 'level': 'company'});
    await db.insert('categories', {'name': '鐗╂祦闂', 'color': '#EF4444', 'parentId': 3, 'sort': 0, 'level': 'company'});
    await db.insert('categories', {'name': '閫€鎹㈣揣', 'color': '#EF4444', 'parentId': 3, 'sort': 1, 'level': 'company'});

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
      'content': '鎮ㄥソ,娆㈣繋鍏変复!鎰熻阿鎮ㄧ殑淇′换,鎴戞槸鎮ㄧ殑涓撳睘瀹㈡湇,鏈変换浣曢棶棰橀殢鏃惰仈绯绘垜~',
      'images': '',
      'files': '',
      'tags': '娆㈣繋璇?甯哥敤',
      'level': 'company',
      'groupId': null,
      'userId': 1,
      'category': '娆㈣繋璇?,
      'subcategory': '鏂板鎴?,
      'createdAt': now,
      'updatedAt': now,
    });

    await db.insert('messages', {
      'title': '鍙戣揣鎻愰啋',
      'content': '浜?鎮ㄧ殑璁㈠崟宸插彂璐у暒!棰勮3-5澶╅€佽揪,璇蜂繚鎸佹墜鏈虹晠閫氬摝~ 鏀跺埌璐у悗鏈変换浣曢棶棰樻杩庨殢鏃惰仈绯绘垜浠?',
      'images': '',
      'files': '',
      'tags': '鍞悗,甯哥敤',
      'level': 'company',
      'groupId': null,
      'userId': 1,
      'category': '鍞悗',
      'subcategory': '鐗╂祦闂',
      'createdAt': now,
      'updatedAt': now,
    });

    await db.insert('messages', {
      'title': '娲诲姩浠嬬粛',
      'content': '馃帀 闄愭椂浼樻儬娲诲姩杩涜涓?鍏ㄥ満8鎶?婊?99鍑?0,鐐瑰嚮閾炬帴棰嗗彇浼樻儬鍒?xxx',
      'images': '',
      'files': '',
      'tags': '娲诲姩',
      'level': 'group',
      'groupId': 'group_1',
      'userId': 1,
      'category': '娲诲姩',
      'subcategory': null,
      'createdAt': now,
      'updatedAt': now,
    });

    await db.insert('messages', {
      'title': '鎴戠殑涓撳睘璇濇湳',
      'content': '杩欐槸鎴戝父鐢ㄧ殑鍥炲妯℃澘,鏂逛究蹇嵎~',
      'images': '',
      'files': '',
      'tags': '甯哥敤',
      'level': 'private',
      'groupId': null,
      'userId': 1,
      'category': '甯哥敤',
      'subcategory': null,
      'createdAt': now,
      'updatedAt': now,
    });
  }

  // Message CRUD
  Future<List<Message>> getMessages({String? level, String? userId}) async {
    final db = await database;

    String? whereClause;
    List<dynamic> whereArgs = [];

    // 濡傛灉鎸囧畾浜唋evel,鎸塴evel杩囨护
    if (level != null) {
      whereClause = 'level = ?';
      whereArgs.add(level);
    }

    // 濡傛灉鎸囧畾浜唘serId(绉佷汉绾у埆)
    if (userId != null) {
      if (whereClause != null) {
        whereClause = '$whereClause AND userId = ?';
        whereArgs.add(userId);
      } else {
        whereClause = 'userId = ?';
        whereArgs.add(userId);
      }
    }

    List<Map<String, dynamic>> maps = await db.query(
      'messages',
      where: whereClause,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: 'updatedAt DESC',
    );

    // 鐩存帴杩斿洖,涓嶅仛璺緞楠岃瘉(閬垮厤 File.existsSync 鎶涘紓甯稿鑷存暣鎵规暟鎹涪澶?
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

  // Category CRUD
  Future<List<Map<String, dynamic>>> getCategories({int? parentId, String? level}) async {
    final db = await database;
    String? whereClause;
    List<dynamic>? whereArgs;

    if (parentId == null && level != null) {
      whereClause = 'parentId IS NULL AND level = ?';
      whereArgs = [level];
    } else if (parentId != null && level != null) {
      whereClause = 'parentId = ? AND level = ?';
      whereArgs = [parentId, level];
    } else if (parentId == null) {
      whereClause = 'parentId IS NULL';
    } else {
      whereClause = 'parentId = ?';
      whereArgs = [parentId];
    }

    List<Map<String, dynamic>> maps = await db.query(
      'categories',
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'sort ASC',
    );
    return maps;
  }

  Future<List<Map<String, dynamic>>> getAllCategories({String? level}) async {
    final db = await database;
    if (level != null) {
      return await db.query('categories', where: 'level = ?', whereArgs: [level], orderBy: 'sort ASC');
    }
    return await db.query('categories', orderBy: 'sort ASC');
  }

  Future<int> insertCategory(Map<String, dynamic> category) async {
    final db = await database;
    // 纭繚level瀛楁鏈夐粯璁ゅ€?    if (!category.containsKey('level')) {
      category['level'] = 'company';
    }
    return await db.insert('categories', category);
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

  // ========== Customer CRUD ==========
  Future<List<Customer>> getCustomers() async {
    final db = await database;
    List<Map<String, dynamic>> maps = await db.query(
      'customers',
      orderBy: 'isPinned DESC, followDate DESC',
    );
    return maps.map((map) => Customer.fromMap(map)).toList();
  }

  Future<Customer?> getCustomer(int id) async {
    final db = await database;
    List<Map<String, dynamic>> maps = await db.query(
      'customers',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return maps.isNotEmpty ? Customer.fromMap(maps.first) : null;
  }

  Future<int> insertCustomer(Customer customer) async {
    final db = await database;
    return await db.insert('customers', customer.toMap()..remove('id'));
  }

  Future<int> updateCustomer(Customer customer) async {
    final db = await database;
    return await db.update(
      'customers',
      customer.toMap(),
      where: 'id = ?',
      whereArgs: [customer.id],
    );
  }

  Future<int> deleteCustomer(int id) async {
    final db = await database;
    return await db.delete(
      'customers',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Customer>> searchCustomers(String keyword) async {
    final db = await database;
    List<Map<String, dynamic>> maps = await db.query(
      'customers',
      where: 'name LIKE ? OR company LIKE ? OR phone LIKE ? OR researchGroup LIKE ? OR product LIKE ? OR followResult LIKE ?',
      whereArgs: List.filled(6, '%$keyword%'),
      orderBy: 'isPinned DESC, updatedAt DESC',
    );
    return maps.map((map) => Customer.fromMap(map)).toList();
  }

  /// 瀵煎嚭瀹㈡埛鏁版嵁鍒癊xcel(鎸夊垎绫诲垎Sheet)
  Future<String> exportCustomersToExcel() async {
    final customers = await getCustomers();

    final excel = Excel.createExcel();
    // 鍒犻櫎榛樿sheet
    excel.delete('Sheet1');

    // 鎸夊垎绫诲垎缁?    final Map<String, List<Customer>> categorized = {};
    for (var c in customers) {
      final cat = c.category.isEmpty ? '鏈垎绫? : c.category;
      categorized.putIfAbsent(cat, () => []).add(c);
    }

    // 涓烘瘡涓垎绫诲垱寤篠heet
    for (var entry in categorized.entries) {
      final categoryName = entry.key;
      final sheetName = categoryName.length > 31 ? categoryName.substring(0, 31) : categoryName;
      final sheet = excel[sheetName];

      // 琛ㄥご
      final headers = ['搴忓彿', '璺熻繘鏃ユ湡', '鍏徃(瀛︽牎)', '濮撳悕', '鐢佃瘽', '璇鹃缁?, '鍜ㄨ浜у搧', '璺熻繘缁撴灉', '缃《'];
      for (var i = 0; i < headers.length; i++) {
        sheet.cell(CellIndex.indexByString('${String.fromCharCode(65 + i)}1')).value = TextCellValue(headers[i]);
      }

      // 鏁版嵁琛?      final categoryCustomers = entry.value;
      for (var i = 0; i < categoryCustomers.length; i++) {
        final c = categoryCustomers[i];
        final row = i + 2;
        sheet.cell(CellIndex.indexByString('A$row')).value = IntCellValue(i + 1);
        sheet.cell(CellIndex.indexByString('B$row')).value = TextCellValue(c.followDate.toIso8601String().split('T').first);
        sheet.cell(CellIndex.indexByString('C$row')).value = TextCellValue(c.company);
        sheet.cell(CellIndex.indexByString('D$row')).value = TextCellValue(c.name);
        sheet.cell(CellIndex.indexByString('E$row')).value = TextCellValue(c.phone ?? '');
        sheet.cell(CellIndex.indexByString('F$row')).value = TextCellValue(c.researchGroup ?? '');
        sheet.cell(CellIndex.indexByString('G$row')).value = TextCellValue(c.product ?? '');
        sheet.cell(CellIndex.indexByString('H$row')).value = TextCellValue(c.followResult ?? '');
        sheet.cell(CellIndex.indexByString('I$row')).value = TextCellValue(c.isPinned ? '鏄? : '鍚?);
      }
    }

    // 淇濆瓨鏂囦欢
    final dir = await getExternalStorageDirectory() ?? await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').split('.').first;
    final fileName = '瀹㈡埛鐢诲儚_$timestamp.xlsx';
    final filePath = '${dir.path}/$fileName';

    final bytes = excel.encode();
    if (bytes == null) throw Exception('Excel鐢熸垚澶辫触');

    final file = File(filePath);
    await file.writeAsBytes(bytes);

    return filePath;
  }

  // ========== 澶囦唤涓庤繕鍘?==========
  /// 瀵煎嚭鍏ㄩ儴鏁版嵁涓?ZIP(鍚?data.json + 鎵€鏈夐檮浠舵枃浠?
  Future<String> exportZipBackup() async {
    final db = await database;
    final messages = await db.query('messages');
    final categories = await db.query('categories');
    final tags = await db.query('tags');
    final customers = await db.query('customers');

    final archive = Archive();
    final List<Map<String, dynamic>> messagesExport = [];

    for (var msg in messages) {
      final Map<String, dynamic> msgExport = Map<String, dynamic>.from(msg);
      final List<String> imageNames = [];
      final List<String> fileNames = [];

      // 鎵撳寘鍥剧墖
      final imagesStr = msg['images'] as String? ?? '';
      for (var imgPath in imagesStr.split(',').where((p) => p.isNotEmpty)) {
        try {
          final f = File(imgPath);
          if (await f.exists()) {
            final bytes = await f.readAsBytes();
            final name = 'attachments/${imgPath.split('/').last}';
            archive.addFile(ArchiveFile(name, bytes.length, bytes));
            imageNames.add(name);
          }
        } catch (_) {}
      }
      msgExport['images'] = imageNames.join(',');

      // 鎵撳寘鏂囦欢
      final filesStr = msg['files'] as String? ?? '';
      for (var filePath in filesStr.split(',').where((p) => p.isNotEmpty)) {
        try {
          final f = File(filePath);
          if (await f.exists()) {
            final bytes = await f.readAsBytes();
            final name = 'attachments/${filePath.split('/').last}';
            archive.addFile(ArchiveFile(name, bytes.length, bytes));
            fileNames.add(name);
          }
        } catch (_) {}
      }
      msgExport['files'] = fileNames.join(',');

      messagesExport.add(msgExport);
    }

    // 鍐欏叆 data.json
    final jsonStr = jsonEncode({
      'version': 3,
      'exportedAt': DateTime.now().toIso8601String(),
      'messages': messagesExport,
      'categories': categories,
      'tags': tags,
      'customers': customers,
    });
    final jsonBytes = jsonStr.codeUnits;
    archive.addFile(ArchiveFile('data.json', jsonBytes.length, jsonBytes));

    // 鍘嬬缉骞跺啓鍏ヤ复鏃舵枃浠?    final dir = await getTemporaryDirectory();
    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').split('.').first;
    final zipPath = '${dir.path}/quickreply_backup_$timestamp.zip';
    final zipFile = File(zipPath);
    final encoder = ZipEncoder();
    await zipFile.writeAsBytes(encoder.encode(archive)!);
    return zipPath;
  }

  /// 浠?ZIP 鏂囦欢瀵煎叆澶囦唤
  Future<void> importZipBackup(String zipPath) async {
    debugPrint('[瀵煎叆] 寮€濮嬪鍏? $zipPath');
    final db = await database;
    final appDir = await getApplicationDocumentsDirectory();
    debugPrint('[瀵煎叆] 搴旂敤鐩綍: ${appDir.path}');

    final attachmentsDir = Directory('${appDir.path}/attachments');
    if (!await attachmentsDir.exists()) {
      await attachmentsDir.create(recursive: true);
    }

    // 璇诲彇骞惰В鍘媄IP
    final bytes = await File(zipPath).readAsBytes();
    debugPrint('[瀵煎叆] ZIP鏂囦欢澶у皬: ${bytes.length} bytes');

    Archive archive;
    try {
      archive = ZipDecoder().decodeBytes(bytes);
    } catch (e) {
      throw Exception('ZIP瑙ｅ帇澶辫触: $e');
    }
    debugPrint('[瀵煎叆] ZIP鍖呭惈 ${archive.length} 涓枃浠?);

    // 鎻愬彇 data.json
    final jsonEntry = archive.findFile('data.json');
    if (jsonEntry == null) {
      // 鍒楀嚭ZIP涓殑鎵€鏈夋枃浠跺府鍔╄皟璇?      final files = archive.map((f) => f.name).join(', ');
      throw Exception('澶囦唤鏂囦欢缂哄皯data.json銆傛枃浠跺垪琛? $files');
    }

    Map<String, dynamic> data;
    try {
      final jsonStr = String.fromCharCodes(jsonEntry.content as List<int>);
      debugPrint('[瀵煎叆] JSON闀垮害: ${jsonStr.length} 瀛楃');
      data = jsonDecode(jsonStr) as Map<String, dynamic>;
    } catch (e) {
      throw Exception('JSON瑙ｆ瀽澶辫触: $e');
    }
    debugPrint('[瀵煎叆] 澶囦唤鐗堟湰: ${data['version']}');

    // 瑙ｅ帇闄勪欢
    int attCount = 0;
    for (final file in archive) {
      if (file.name.startsWith('attachments/') && !file.isSymbolicLink) {
        final outFile = File('${appDir.path}/${file.name}');
        await outFile.parent.create(recursive: true);
        await outFile.writeAsBytes(file.content as List<int>);
        attCount++;
      }
    }
    debugPrint('[瀵煎叆] 瑙ｅ帇闄勪欢: $attCount 涓?);

    // 娓呯┖鐜版湁鏁版嵁
    await db.delete('messages');
    await db.delete('categories');
    await db.delete('tags');
    await db.delete('customers');
    debugPrint('[瀵煎叆] 宸叉竻绌烘棫鏁版嵁');

    // 鎭㈠鍒嗙被
    int catCount = 0;
    if (data['categories'] != null) {
      for (var cat in data['categories'] as List) {
        await db.insert('categories', Map<String, dynamic>.from(cat as Map));
        catCount++;
      }
    }
    debugPrint('[瀵煎叆] 鎭㈠鍒嗙被: $catCount 涓?);

    // 鎭㈠鏍囩
    int tagCount = 0;
    if (data['tags'] != null) {
      for (var tag in data['tags'] as List) {
        await db.insert('tags', Map<String, dynamic>.from(tag as Map));
        tagCount++;
      }
    }
    debugPrint('[瀵煎叆] 鎭㈠鏍囩: $tagCount 涓?);

    // 鎭㈠璇濇湳
    int msgCount = 0;
    if (data['messages'] != null) {
      for (var msg in data['messages'] as List) {
        final Map<String, dynamic> msgData = Map<String, dynamic>.from(msg as Map);
        // 鍥剧墖鍜屾枃浠惰矾寰勪繚鎸佺浉瀵硅矾寰勬牸寮?        final imgNames = (msgData['images'] as String? ?? '').split(',').where((p) => p.isNotEmpty);
        msgData['images'] = imgNames.join(',');
        final fileNames = (msgData['files'] as String? ?? '').split(',').where((p) => p.isNotEmpty);
        msgData['files'] = fileNames.join(',');
        await db.insert('messages', msgData);
        msgCount++;
      }
    }
    debugPrint('[瀵煎叆] 鎭㈠璇濇湳: $msgCount 涓?);

    // 鎭㈠瀹㈡埛
    int custCount = 0;
    if (data['customers'] != null) {
      for (var cust in data['customers'] as List) {
        await db.insert('customers', Map<String, dynamic>.from(cust as Map));
        custCount++;
      }
    }
    debugPrint('[瀵煎叆] 鎭㈠瀹㈡埛: $custCount 涓?);

    debugPrint('[瀵煎叆] 瀵煎叆瀹屾垚!');
  }

  /// 鏃х増:瀵煎嚭鍏ㄩ儴鏁版嵁(鍚浘鐗?鏂囦欢)涓?JSON(淇濈暀鍏煎)
  Future<Map<String, dynamic>> exportFullBackup() async {
    final db = await database;
    final messages = await db.query('messages');
    final categories = await db.query('categories');
    final tags = await db.query('tags');

    // 澶勭悊姣忎釜璇濇湳,璇诲彇鍥剧墖/鏂囦欢鍐呭
    final List<Map<String, dynamic>> messagesWithAttachments = [];
    for (var msg in messages) {
      final Map<String, dynamic> msgWithAtt = Map<String, dynamic>.from(msg);

      // 澶勭悊鍥剧墖
      final imagesStr = msg['images'] as String? ?? '';
      final List<String> imagesList = imagesStr.isNotEmpty ? imagesStr.split(',') : [];
      final List<String> imagesBase64 = [];

      for (var imgPath in imagesList) {
        if (imgPath.isNotEmpty) {
          try {
            final file = File(imgPath);
            if (await file.exists()) {
              final bytes = await file.readAsBytes();
              imagesBase64.add(base64Encode(bytes));
            }
          } catch (e) {
            // 鍥剧墖璇诲彇澶辫触,璺宠繃
          }
        }
      }
      msgWithAtt['images_base64'] = imagesBase64;

      // 澶勭悊鏂囦欢
      final filesStr = msg['files'] as String? ?? '';
      final List<String> filesList = filesStr.isNotEmpty ? filesStr.split(',') : [];
      final List<Map<String, String>> filesData = [];

      for (var filePath in filesList) {
        if (filePath.isNotEmpty) {
          try {
            final file = File(filePath);
            if (await file.exists()) {
              final bytes = await file.readAsBytes();
              final name = filePath.split('/').last;
              filesData.add({
                'name': name,
                'data': base64Encode(bytes),
              });
            }
          } catch (e) {
            // 鏂囦欢璇诲彇澶辫触,璺宠繃
          }
        }
      }
      msgWithAtt['files_data'] = filesData;

      messagesWithAttachments.add(msgWithAtt);
    }

    return {
      'version': 2,
      'exportedAt': DateTime.now().toIso8601String(),
      'messages': messagesWithAttachments,
      'categories': categories,
      'tags': tags,
    };
  }

  /// 鏃х増瀵煎嚭(鍙璺緞)
  Future<Map<String, dynamic>> exportData() async {
    final db = await database;
    final messages = await db.query('messages');
    final categories = await db.query('categories');
    final tags = await db.query('tags');
    return {
      'version': 1,
      'exportedAt': DateTime.now().toIso8601String(),
      'messages': messages,
      'categories': categories,
      'tags': tags,
    };
  }

  /// 瀵煎叆瀹屾暣澶囦唤
  Future<void> importFullBackup(Map<String, dynamic> data) async {
    final db = await database;
    final appDir = await getApplicationDocumentsDirectory();
    final attachmentsDir = Directory('${appDir.path}/attachments');
    if (!await attachmentsDir.exists()) {
      await attachmentsDir.create(recursive: true);
    }

    // 娓呯┖鐜版湁鏁版嵁
    await db.delete('messages');
    await db.delete('categories');
    await db.delete('tags');

    // 鎭㈠鍒嗙被鍜屾爣绛?    if (data['categories'] != null) {
      for (var cat in data['categories'] as List) {
        await db.insert('categories', Map<String, dynamic>.from(cat));
      }
    }
    if (data['tags'] != null) {
      for (var tag in data['tags'] as List) {
        await db.insert('tags', Map<String, dynamic>.from(tag));
      }
    }

    // 鎭㈠璇濇湳鍜岄檮浠?    if (data['messages'] != null) {
      for (var msg in data['messages'] as List) {
        final Map<String, dynamic> msgData = Map<String, dynamic>.from(msg);
        final List<String> restoredImages = [];
        final List<String> restoredFiles = [];

        // 鎭㈠鍥剧墖
        if (msgData['images_base64'] != null) {
          for (var i = 0; i < (msgData['images_base64'] as List).length; i++) {
            final base64Data = msgData['images_base64'][i] as String;
            final bytes = base64Decode(base64Data);
            final imgName = 'img_${DateTime.now().millisecondsSinceEpoch}_$i.jpg';
            final imgFile = File('${attachmentsDir.path}/$imgName');
            await imgFile.writeAsBytes(bytes);
            restoredImages.add(imgFile.path);
          }
        }
        msgData['images'] = restoredImages.join(',');
        msgData.remove('images_base64');

        // 鎭㈠鏂囦欢
        if (msgData['files_data'] != null) {
          for (var fileInfo in msgData['files_data'] as List) {
            final Map<String, dynamic> fi = Map<String, dynamic>.from(fileInfo);
            final bytes = base64Decode(fi['data'] as String);
            final fileName = fi['name'] as String;
            final file = File('${attachmentsDir.path}/$fileName');
            await file.writeAsBytes(bytes);
            restoredFiles.add(file.path);
          }
        }
        msgData['files'] = restoredFiles.join(',');
        msgData.remove('files_data');

        await db.insert('messages', msgData);
      }
    }
  }

  /// 鏃х増瀵煎叆
  Future<void> importData(Map<String, dynamic> data) async {
    final db = await database;
    await db.delete('messages');
    await db.delete('categories');
    await db.delete('tags');

    if (data['messages'] != null) {
      for (var msg in data['messages'] as List) {
        await db.insert('messages', Map<String, dynamic>.from(msg));
      }
    }
    if (data['categories'] != null) {
      for (var cat in data['categories'] as List) {
        await db.insert('categories', Map<String, dynamic>.from(cat));
      }
    }
    if (data['tags'] != null) {
      for (var tag in data['tags'] as List) {
        await db.insert('tags', Map<String, dynamic>.from(tag));
      }
    }
  }

  // ========== 瀹㈡埛鍒嗙被绠＄悊 ==========

  /// 鑾峰彇鎵€鏈夊鎴峰垎绫?  Future<List<Map<String, dynamic>>> getCustomerCategories() async {
    final db = await database;
    return await db.query('customer_categories', orderBy: 'sort ASC');
  }

  /// 娣诲姞瀹㈡埛鍒嗙被
  Future<int> insertCustomerCategory(Map<String, dynamic> category) async {
    final db = await database;
    return await db.insert('customer_categories', category);
  }

  /// 鏇存柊瀹㈡埛鍒嗙被
  Future<int> updateCustomerCategory(int id, Map<String, dynamic> category) async {
    final db = await database;
    return await db.update(
      'customer_categories',
      category,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// 鍒犻櫎瀹㈡埛鍒嗙被
  Future<int> deleteCustomerCategory(int id) async {
    final db = await database;
    // 灏嗚鍒嗙被鐨勫鎴锋敼涓?鏈垎绫?
    await db.update(
      'customers',
      {'category': '鏈垎绫?},
      where: 'category = (SELECT name FROM customer_categories WHERE id = ?)',
      whereArgs: [id],
    );
    return await db.delete(
      'customer_categories',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ========== 閫氳瘽璁板綍绠＄悊 ==========

  /// 鑾峰彇鎵€鏈夐€氳瘽璁板綍
  Future<List<CallRecord>> getCallLogs() async {
    final db = await database;
    final maps = await db.query('call_logs', orderBy: 'start_time DESC');
    return maps.map((map) => CallRecord.fromMap(map)).toList();
  }

  /// 娣诲姞閫氳瘽璁板綍
  Future<int> insertCallLog(CallRecord record) async {
    final db = await database;
    return await db.insert('call_logs', record.toMap());
  }

  /// 鏇存柊閫氳瘽璁板綍
  Future<int> updateCallLog(CallRecord record) async {
    final db = await database;
    return await db.update(
      'call_logs',
      record.toMap(),
      where: 'id = ?',
      whereArgs: [record.id],
    );
  }

  /// 鍒犻櫎閫氳瘽璁板綍
  Future<int> deleteCallLog(int id) async {
    final db = await database;
    return await db.delete(
      'call_logs',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
