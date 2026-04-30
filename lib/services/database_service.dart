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

  /// 将数据库中中文的 level 值统一转为英文
  Future<void> _normalizeLevelValues(Database db) async {
    try {
      await db.execute("UPDATE messages SET level = 'company' WHERE level IN ('公司级', '公司', 'Company')");
      await db.execute("UPDATE messages SET level = 'group' WHERE level IN ('小组级', '小组', 'Group')");
      await db.execute("UPDATE messages SET level = 'private' WHERE level IN ('私人', '我的', '个人', 'Private')");
      await db.execute("UPDATE categories SET level = 'company' WHERE level IN ('公司级', '公司', 'Company')");
      await db.execute("UPDATE categories SET level = 'group' WHERE level IN ('小组级', '小组', 'Group')");
      await db.execute("UPDATE categories SET level = 'private' WHERE level IN ('私人', '我的', '个人', 'Private')");
    } catch (e) {
      // 静默处理,不影响应用启动
    }
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // 添加level字段到categories表
      await db.execute('ALTER TABLE categories ADD COLUMN level TEXT DEFAULT "company"');
    }
    if (oldVersion < 3) {
      // 添加customers表(旧版)
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
      // 升级customers表结构
      // 备份旧数据
      final oldCustomers = await db.query('customers');
      // 删除旧表
      await db.execute('DROP TABLE IF EXISTS customers');
      // 创建新表
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
          category TEXT DEFAULT '未分类',
          isPinned INTEGER DEFAULT 0,
          createdAt TEXT NOT NULL,
          updatedAt TEXT NOT NULL
        )
      ''');
      // 恢复数据(尽可能映射)
      for (var old in oldCustomers) {
        await db.insert('customers', {
          'followDate': old['createdAt'] ?? DateTime.now().toIso8601String(),
          'company': old['company'] ?? '',
          'name': old['name'] ?? '',
          'phone': old['phone'],
          'researchGroup': null,
          'product': null,
          'followResult': null,
          'category': '未分类',
          'isPinned': 0,
          'createdAt': old['createdAt'],
          'updatedAt': old['updatedAt'],
        });
      }
    }
    if (oldVersion < 5) {
      // 创建客户分类表
      await db.execute('''
        CREATE TABLE customer_categories(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          color TEXT NOT NULL,
          sort INTEGER DEFAULT 0
        )
      ''');
      // 插入默认客户分类
      await db.insert('customer_categories', {'name': '意向客户', 'color': '#10B981', 'sort': 0});
      await db.insert('customer_categories', {'name': '已成交', 'color': '#2563EB', 'sort': 1});
      await db.insert('customer_categories', {'name': '已流失', 'color': '#EF4444', 'sort': 2});
      await db.insert('customer_categories', {'name': '未分类', 'color': '#9CA3AF', 'sort': 99});
    }
    if (oldVersion < 6) {
      // 创建通话记录表
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
        category TEXT DEFAULT '未分类',
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
        category TEXT DEFAULT '未分类',
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
    // 插入示例分类(一级)- company 级别
    await db.insert('categories', {'name': '欢迎语', 'color': '#10B981', 'parentId': null, 'sort': 0, 'level': 'company'});
    await db.insert('categories', {'name': '咨询', 'color': '#F59E0B', 'parentId': null, 'sort': 1, 'level': 'company'});
    await db.insert('categories', {'name': '售后', 'color': '#EF4444', 'parentId': null, 'sort': 2, 'level': 'company'});
    await db.insert('categories', {'name': '活动', 'color': '#8B5CF6', 'parentId': null, 'sort': 3, 'level': 'group'});
    await db.insert('categories', {'name': '常用', 'color': '#2563EB', 'parentId': null, 'sort': 4, 'level': 'private'});

    // 插入示例子分类(二级)
    await db.insert('categories', {'name': '新客户', 'color': '#10B981', 'parentId': 1, 'sort': 0, 'level': 'company'});
    await db.insert('categories', {'name': '老客户', 'color': '#10B981', 'parentId': 1, 'sort': 1, 'level': 'company'});
    await db.insert('categories', {'name': '产品咨询', 'color': '#F59E0B', 'parentId': 2, 'sort': 0, 'level': 'company'});
    await db.insert('categories', {'name': '价格咨询', 'color': '#F59E0B', 'parentId': 2, 'sort': 1, 'level': 'company'});
    await db.insert('categories', {'name': '物流问题', 'color': '#EF4444', 'parentId': 3, 'sort': 0, 'level': 'company'});
    await db.insert('categories', {'name': '退换货', 'color': '#EF4444', 'parentId': 3, 'sort': 1, 'level': 'company'});

    // 插入示例标签
    await db.insert('tags', {'name': '欢迎语', 'color': '#10B981'});
    await db.insert('tags', {'name': '咨询', 'color': '#F59E0B'});
    await db.insert('tags', {'name': '售后', 'color': '#EF4444'});
    await db.insert('tags', {'name': '活动', 'color': '#8B5CF6'});
    await db.insert('tags', {'name': '常用', 'color': '#2563EB'});

    // 插入示例话术
    final now = DateTime.now().toIso8601String();

    await db.insert('messages', {
      'title': '新客户欢迎语',
      'content': '您好,欢迎光临!感谢您的信任,我是您的专属客服,有任何问题随时联系我~',
      'images': '',
      'files': '',
      'tags': '欢迎语,常用',
      'level': 'company',
      'groupId': null,
      'userId': 1,
      'category': '欢迎语',
      'subcategory': '新客户',
      'createdAt': now,
      'updatedAt': now,
    });

    await db.insert('messages', {
      'title': '发货提醒',
      'content': '亲,您的订单已发货啦!预计3-5天送达,请保持手机畅通哦~ 收到货后有任何问题欢迎随时联系我们!',
      'images': '',
      'files': '',
      'tags': '售后,常用',
      'level': 'company',
      'groupId': null,
      'userId': 1,
      'category': '售后',
      'subcategory': '物流问题',
      'createdAt': now,
      'updatedAt': now,
    });

    await db.insert('messages', {
      'title': '活动介绍',
      'content': '🎉 限时优惠活动进行中!全场8折,满199减30,点击链接领取优惠券:xxx',
      'images': '',
      'files': '',
      'tags': '活动',
      'level': 'group',
      'groupId': 'group_1',
      'userId': 1,
      'category': '活动',
      'subcategory': null,
      'createdAt': now,
      'updatedAt': now,
    });

    await db.insert('messages', {
      'title': '我的专属话术',
      'content': '这是我常用的回复模板,方便快捷~',
      'images': '',
      'files': '',
      'tags': '常用',
      'level': 'private',
      'groupId': null,
      'userId': 1,
      'category': '常用',
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

    // 如果指定了level,按level过滤
    if (level != null) {
      whereClause = 'level = ?';
      whereArgs.add(level);
    }

    // 如果指定了userId(私人级别)
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

    // 直接返回,不做路径验证(避免 File.existsSync 抛异常导致整批数据丢失)
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
    // 确保level字段有默认值
    if (!category.containsKey('level')) {
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

  /// 导出客户数据到Excel(按分类分Sheet)
  Future<String> exportCustomersToExcel() async {
    final customers = await getCustomers();

    final excel = Excel.createExcel();
    // 删除默认sheet
    excel.delete('Sheet1');

    // 按分类分组
    final Map<String, List<Customer>> categorized = {};
    for (var c in customers) {
      final cat = c.category.isEmpty ? '未分类' : c.category;
      categorized.putIfAbsent(cat, () => []).add(c);
    }

    // 为每个分类创建Sheet
    for (var entry in categorized.entries) {
      final categoryName = entry.key;
      final sheetName = categoryName.length > 31 ? categoryName.substring(0, 31) : categoryName;
      final sheet = excel[sheetName];

      // 表头
      final headers = ['序号', '跟进日期', '公司(学校)', '姓名', '电话', '课题组', '咨询产品', '跟进结果', '置顶'];
      for (var i = 0; i < headers.length; i++) {
        sheet.cell(CellIndex.indexByString('${String.fromCharCode(65 + i)}1')).value = TextCellValue(headers[i]);
      }

      // 数据行
      final categoryCustomers = entry.value;
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
        sheet.cell(CellIndex.indexByString('I$row')).value = TextCellValue(c.isPinned ? '是' : '否');
      }
    }

    // 保存文件
    final dir = await getExternalStorageDirectory() ?? await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').split('.').first;
    final fileName = '客户画像_$timestamp.xlsx';
    final filePath = '${dir.path}/$fileName';

    final bytes = excel.encode();
    if (bytes == null) throw Exception('Excel生成失败');

    final file = File(filePath);
    await file.writeAsBytes(bytes);

    return filePath;
  }

  // ========== 备份与还原 ==========
  /// 导出全部数据为 ZIP(含 data.json + 所有附件文件)
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

      // 打包图片
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

      // 打包文件
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

    // 写入 data.json
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

    // 压缩并写入临时文件
    final dir = await getTemporaryDirectory();
    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').split('.').first;
    final zipPath = '${dir.path}/quickreply_backup_$timestamp.zip';
    final zipFile = File(zipPath);
    final encoder = ZipEncoder();
    await zipFile.writeAsBytes(encoder.encode(archive)!);
    return zipPath;
  }

  /// 从 ZIP 文件导入备份
  Future<void> importZipBackup(String zipPath) async {
    debugPrint('[导入] 开始导入: $zipPath');
    final db = await database;
    final appDir = await getApplicationDocumentsDirectory();
    debugPrint('[导入] 应用目录: ${appDir.path}');

    final attachmentsDir = Directory('${appDir.path}/attachments');
    if (!await attachmentsDir.exists()) {
      await attachmentsDir.create(recursive: true);
    }

    // 读取并解压ZIP
    final bytes = await File(zipPath).readAsBytes();
    debugPrint('[导入] ZIP文件大小: ${bytes.length} bytes');

    Archive archive;
    try {
      archive = ZipDecoder().decodeBytes(bytes);
    } catch (e) {
      throw Exception('ZIP解压失败: $e');
    }
    debugPrint('[导入] ZIP包含 ${archive.length} 个文件');

    // 提取 data.json
    final jsonEntry = archive.findFile('data.json');
    if (jsonEntry == null) {
      // 列出ZIP中的所有文件帮助调试
      final files = archive.map((f) => f.name).join(', ');
      throw Exception('备份文件缺少data.json。文件列表: $files');
    }

    Map<String, dynamic> data;
    try {
      final jsonStr = String.fromCharCodes(jsonEntry.content as List<int>);
      debugPrint('[导入] JSON长度: ${jsonStr.length} 字符');
      data = jsonDecode(jsonStr) as Map<String, dynamic>;
    } catch (e) {
      throw Exception('JSON解析失败: $e');
    }
    debugPrint('[导入] 备份版本: ${data['version']}');

    // 解压附件
    int attCount = 0;
    for (final file in archive) {
      if (file.name.startsWith('attachments/') && !file.isSymbolicLink) {
        final outFile = File('${appDir.path}/${file.name}');
        await outFile.parent.create(recursive: true);
        await outFile.writeAsBytes(file.content as List<int>);
        attCount++;
      }
    }
    debugPrint('[导入] 解压附件: $attCount 个');

    // 清空现有数据
    await db.delete('messages');
    await db.delete('categories');
    await db.delete('tags');
    await db.delete('customers');
    debugPrint('[导入] 已清空旧数据');

    // 恢复分类
    int catCount = 0;
    if (data['categories'] != null) {
      for (var cat in data['categories'] as List) {
        await db.insert('categories', Map<String, dynamic>.from(cat as Map));
        catCount++;
      }
    }
    debugPrint('[导入] 恢复分类: $catCount 个');

    // 恢复标签
    int tagCount = 0;
    if (data['tags'] != null) {
      for (var tag in data['tags'] as List) {
        await db.insert('tags', Map<String, dynamic>.from(tag as Map));
        tagCount++;
      }
    }
    debugPrint('[导入] 恢复标签: $tagCount 个');

    // 恢复话术
    int msgCount = 0;
    if (data['messages'] != null) {
      for (var msg in data['messages'] as List) {
        final Map<String, dynamic> msgData = Map<String, dynamic>.from(msg as Map);
        // 图片和文件路径保持相对路径格式
        final imgNames = (msgData['images'] as String? ?? '').split(',').where((p) => p.isNotEmpty);
        msgData['images'] = imgNames.join(',');
        final fileNames = (msgData['files'] as String? ?? '').split(',').where((p) => p.isNotEmpty);
        msgData['files'] = fileNames.join(',');
        await db.insert('messages', msgData);
        msgCount++;
      }
    }
    debugPrint('[导入] 恢复话术: $msgCount 个');

    // 恢复客户
    int custCount = 0;
    if (data['customers'] != null) {
      for (var cust in data['customers'] as List) {
        await db.insert('customers', Map<String, dynamic>.from(cust as Map));
        custCount++;
      }
    }
    debugPrint('[导入] 恢复客户: $custCount 个');

    debugPrint('[导入] 导入完成!');
  }

  /// 旧版:导出全部数据(含图片/文件)为 JSON(保留兼容)
  Future<Map<String, dynamic>> exportFullBackup() async {
    final db = await database;
    final messages = await db.query('messages');
    final categories = await db.query('categories');
    final tags = await db.query('tags');

    // 处理每个话术,读取图片/文件内容
    final List<Map<String, dynamic>> messagesWithAttachments = [];
    for (var msg in messages) {
      final Map<String, dynamic> msgWithAtt = Map<String, dynamic>.from(msg);

      // 处理图片
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
            // 图片读取失败,跳过
          }
        }
      }
      msgWithAtt['images_base64'] = imagesBase64;

      // 处理文件
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
            // 文件读取失败,跳过
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

  /// 旧版导出(只导路径)
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

  /// 导入完整备份
  Future<void> importFullBackup(Map<String, dynamic> data) async {
    final db = await database;
    final appDir = await getApplicationDocumentsDirectory();
    final attachmentsDir = Directory('${appDir.path}/attachments');
    if (!await attachmentsDir.exists()) {
      await attachmentsDir.create(recursive: true);
    }

    // 清空现有数据
    await db.delete('messages');
    await db.delete('categories');
    await db.delete('tags');

    // 恢复分类和标签
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

    // 恢复话术和附件
    if (data['messages'] != null) {
      for (var msg in data['messages'] as List) {
        final Map<String, dynamic> msgData = Map<String, dynamic>.from(msg);
        final List<String> restoredImages = [];
        final List<String> restoredFiles = [];

        // 恢复图片
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

        // 恢复文件
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

  /// 旧版导入
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

  // ========== 客户分类管理 ==========

  /// 获取所有客户分类
  Future<List<Map<String, dynamic>>> getCustomerCategories() async {
    final db = await database;
    return await db.query('customer_categories', orderBy: 'sort ASC');
  }

  /// 添加客户分类
  Future<int> insertCustomerCategory(Map<String, dynamic> category) async {
    final db = await database;
    return await db.insert('customer_categories', category);
  }

  /// 更新客户分类
  Future<int> updateCustomerCategory(int id, Map<String, dynamic> category) async {
    final db = await database;
    return await db.update(
      'customer_categories',
      category,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// 删除客户分类
  Future<int> deleteCustomerCategory(int id) async {
    final db = await database;
    // 将该分类的客户改为"未分类"
    await db.update(
      'customers',
      {'category': '未分类'},
      where: 'category = (SELECT name FROM customer_categories WHERE id = ?)',
      whereArgs: [id],
    );
    return await db.delete(
      'customer_categories',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ========== 通话记录管理 ==========

  /// 获取所有通话记录
  Future<List<CallRecord>> getCallLogs() async {
    final db = await database;
    final maps = await db.query('call_logs', orderBy: 'start_time DESC');
    return maps.map((map) => CallRecord.fromMap(map)).toList();
  }

  /// 添加通话记录
  Future<int> insertCallLog(CallRecord record) async {
    final db = await database;
    return await db.insert('call_logs', record.toMap());
  }

  /// 更新通话记录
  Future<int> updateCallLog(CallRecord record) async {
    final db = await database;
    return await db.update(
      'call_logs',
      record.toMap(),
      where: 'id = ?',
      whereArgs: [record.id],
    );
  }

  /// 删除通话记录
  Future<int> deleteCallLog(int id) async {
    final db = await database;
    return await db.delete(
      'call_logs',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
