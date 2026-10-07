import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

/// Owns the SQLite connection and schema. Feature data sources query the
/// tables; only this class knows how the database is opened and migrated.
class AppDatabase {
  /// [factory] and [path] are overridable so tests can use an in-memory
  /// database through `sqflite_common_ffi`.
  AppDatabase({DatabaseFactory? factory, String? path})
    : _factory = factory,
      _path = path;

  static const coursesTable = 'courses';
  static const lessonsTable = 'lessons';

  static const _fileName = 'learning_dashboard.db';
  static const _version = 1;

  final DatabaseFactory? _factory;
  final String? _path;
  Future<Database>? _database;

  Future<Database> get database => _database ??= _open();

  Future<Database> _open() async {
    final factory = _factory ?? databaseFactory;
    final path = _path ?? p.join(await factory.getDatabasesPath(), _fileName);
    return factory.openDatabase(
      path,
      options: OpenDatabaseOptions(version: _version, onCreate: _onCreate),
    );
  }

  static Future<void> _onCreate(Database db, int version) async {
    final batch = db.batch()
      ..execute('''
        CREATE TABLE $coursesTable (
          id INTEGER PRIMARY KEY,
          title TEXT NOT NULL,
          instructor TEXT NOT NULL,
          progress INTEGER NOT NULL,
          lesson_count INTEGER NOT NULL,
          sort_order INTEGER NOT NULL
        )''')
      ..execute('''
        CREATE TABLE $lessonsTable (
          id INTEGER PRIMARY KEY,
          course_id INTEGER NOT NULL,
          title TEXT NOT NULL,
          position INTEGER NOT NULL,
          is_completed INTEGER NOT NULL,
          pending_sync INTEGER NOT NULL DEFAULT 0
        )''')
      ..execute('CREATE INDEX idx_lessons_course ON $lessonsTable(course_id)');
    await batch.commit(noResult: true);
  }

  /// Wipes user data, e.g. on logout.
  Future<void> clearAll() async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete(lessonsTable);
      await txn.delete(coursesTable);
    });
  }

  Future<void> close() async {
    final pending = _database;
    _database = null;
    if (pending != null) await (await pending).close();
  }
}
