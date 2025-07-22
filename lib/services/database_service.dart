import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

/// 数据库服务类
/// 
/// 负责管理SQLite数据库的创建、升级和连接
/// 采用单例模式确保全局只有一个数据库连接
class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static Database? _database;
  
  factory DatabaseService() => _instance;
  
  DatabaseService._internal();

  /// 数据库版本
  static const int _databaseVersion = 1;
  
  /// 数据库名称
  static const String _databaseName = 'life_tracking_calendar.db';

  /// 获取数据库实例
  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  /// 初始化数据库
  Future<Database> _initDatabase() async {
    // 获取数据库路径
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, _databaseName);

    // 打开数据库，如果不存在则创建
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// 创建数据库表
  Future<void> _onCreate(Database db, int version) async {
    // 创建标签表
    await db.execute('''
      CREATE TABLE tags (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        config TEXT NOT NULL,
        color TEXT NOT NULL,
        enable_prediction INTEGER NOT NULL DEFAULT 0,
        cycle_days INTEGER,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        is_active INTEGER NOT NULL DEFAULT 1
      )
    ''');

    // 创建标签记录表
    await db.execute('''
      CREATE TABLE tag_records (
        id TEXT PRIMARY KEY,
        tag_id TEXT NOT NULL,
        date TEXT NOT NULL,
        value TEXT NOT NULL,
        is_prediction INTEGER NOT NULL DEFAULT 0,
        confidence REAL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        note TEXT,
        FOREIGN KEY (tag_id) REFERENCES tags (id) ON DELETE CASCADE
      )
    ''');

    // 创建日记条目表
    await db.execute('''
      CREATE TABLE diary_entries (
        id TEXT PRIMARY KEY,
        date TEXT NOT NULL UNIQUE,
        content TEXT NOT NULL,
        attachments TEXT,
        tag_record_ids TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        mood_score INTEGER,
        weather TEXT
      )
    ''');

    // 创建多媒体附件表
    await db.execute('''
      CREATE TABLE media_attachments (
        id TEXT PRIMARY KEY,
        diary_entry_id TEXT NOT NULL,
        type TEXT NOT NULL,
        file_path TEXT NOT NULL,
        file_name TEXT NOT NULL,
        file_size INTEGER NOT NULL,
        created_at TEXT NOT NULL,
        thumbnail_path TEXT,
        FOREIGN KEY (diary_entry_id) REFERENCES diary_entries (id) ON DELETE CASCADE
      )
    ''');

    // 创建索引以提高查询性能
    await db.execute('CREATE INDEX idx_tag_records_tag_id ON tag_records (tag_id)');
    await db.execute('CREATE INDEX idx_tag_records_date ON tag_records (date)');
    await db.execute('CREATE INDEX idx_diary_entries_date ON diary_entries (date)');
    await db.execute('CREATE INDEX idx_media_attachments_diary_id ON media_attachments (diary_entry_id)');
  }

  /// 数据库升级
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // 这里处理数据库版本升级逻辑
    // 目前是第一个版本，暂时不需要升级逻辑
  }

  /// 关闭数据库连接
  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }

  /// 清空所有数据（用于测试或重置）
  Future<void> clearAllData() async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('media_attachments');
      await txn.delete('tag_records');
      await txn.delete('diary_entries');
      await txn.delete('tags');
    });
  }

  /// 获取数据库信息（用于调试）
  Future<Map<String, dynamic>> getDatabaseInfo() async {
    final db = await database;
    
    // 获取各表的记录数量
    final tagCount = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM tags'));
    final recordCount = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM tag_records'));
    final diaryCount = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM diary_entries'));
    final attachmentCount = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM media_attachments'));
    
    return {
      'database_path': db.path,
      'database_version': await db.getVersion(),
      'tag_count': tagCount ?? 0,
      'record_count': recordCount ?? 0,
      'diary_count': diaryCount ?? 0,
      'attachment_count': attachmentCount ?? 0,
    };
  }
}