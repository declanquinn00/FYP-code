import 'dart:async';
import 'dart:io';

import 'package:carerassistant/extensions/list/filter.dart';
import 'package:carerassistant/services/entity_service_exceptions.dart';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' show join;
import 'dart:developer' as devtools show log;

class DatabaseService {
  Database? _db;

  List<DatabaseEntry> _entries = [];

  DatabaseUser? _user;

  // create entry service as a singleton, this is how to create singletons in dart
  static final DatabaseService _shared = DatabaseService._sharedInstance();
  DatabaseService._sharedInstance() {
    _entryStreamController = StreamController<List<DatabaseEntry>>.broadcast(
      onListen: () {
        // populate stream controller from database entries
        _entryStreamController.sink.add(_entries);
      },
    );
  }
  factory DatabaseService() => _shared;

  // create a stream pipeline, broadcast allows the controller to be listened to multiple times
  late final StreamController<List<DatabaseEntry>> _entryStreamController;

  Stream<List<DatabaseEntry>> get allEntries =>
      _entryStreamController.stream.filter((entry) {
        final currentUser = _user;
        if (currentUser != null) {
          return entry.userId == currentUser.id;
        } else {
          throw UserShouldBeSetBeforeReadingAllEntries();
        }
      });

  Future<DatabaseUser> getOrCreateUser({
    required String email,
    bool setAsCurrentUser = true,
  }) async {
    try {
      final user = await getUser(email: email);
      if (setAsCurrentUser) {
        _user = user;
      }
      return user;
    } on CouldNotFindUser {
      final createdUser = await createUser(email: email);
      if (setAsCurrentUser) {
        _user = createdUser;
      }
      return createdUser;
    } catch (E) {
      // throw the exception back (debugging)
      rethrow;
    }
  }

  Future<void> _cacheEntries() async {
    final allEntries = await getAllEntries();
    _entries = allEntries.toList();
    _entryStreamController.add(_entries);
  }

  Future<DatabaseEntry> updateEntry({
    required DatabaseEntry entry,
    required String text,
    required String title,
    required Uint8List photoA,
    required Uint8List photoB,
  }) async {
    await _ensureDbIsOpen();
    final db = _getDatabaseOrThrow();

    // make sure entry exists
    await getEntry(id: entry.id);

    // update DB
    final updatesCount = await db.update(
      entryTable,
      {
        textColumn: text,
        titleColumn: title,
        photoAColumn: photoA,
        photoBColumn: photoB,
        isSyncedWithCloudColumn: 0,
      },
      where: 'id = ?',
      whereArgs: [entry.id],
    );

    if (updatesCount == 0) {
      throw CouldNotUpdateEntry();
    } else {
      final updatedEntry = await getEntry(id: entry.id);
      _entries.removeWhere((entry) => entry.id == updatedEntry.id);
      _entries.add(updatedEntry);
      _entryStreamController.add(_entries);
      return updatedEntry;
    }
  }

  Future<Iterable<DatabaseEntry>> getAllEntries() async {
    await _ensureDbIsOpen();
    final db = _getDatabaseOrThrow();
    final entries = await db.query(entryTable);

    return entries.map((entryRow) => DatabaseEntry.fromRow(entryRow));
  }

  Future<DatabaseEntry> getEntry({required int id}) async {
    await _ensureDbIsOpen();
    final db = _getDatabaseOrThrow();
    final entries = await db.query(
      entryTable,
      limit: 1,
      where: 'id = ?',
      whereArgs: [id],
    );

    if (entries.isEmpty) {
      throw CouldNotFindEntry();
    } else {
      final entry = DatabaseEntry.fromRow(entries.first);
      _entries.removeWhere((entry) => entry.id == id);
      _entries.add(entry);
      _entryStreamController.add(_entries);
      return entry;
    }
  }

  Future<int> deleteAllEntries() async {
    await _ensureDbIsOpen();
    final db = _getDatabaseOrThrow();
    final numberOfDeletions = await db.delete(entryTable);
    _entries = [];
    _entryStreamController.add(_entries);
    return numberOfDeletions;
  }

  Future<void> deleteEntry({required int id}) async {
    await _ensureDbIsOpen();
    final db = _getDatabaseOrThrow();
    final deletedCount = await db.delete(
      entryTable,
      where: 'id = ?',
      whereArgs: [id],
    );
    if (deletedCount == 0) {
      throw CouldNotDeleteEntry();
    } else {
      _entries.removeWhere((entry) => entry.id == id);
      _entryStreamController.add(_entries);
    }
  }

  Future<DatabaseEntry> createEntry({required DatabaseUser owner}) async {
    await _ensureDbIsOpen();
    final db = _getDatabaseOrThrow();

    // make sure owner exists in the database with the correct id
    final dbUser = await getUser(email: owner.email);
    if (dbUser != owner) {
      throw CouldNotFindUser();
    }

    const text = '';
    const title = '';
    // create the entry
    final entryId = await db.insert(entryTable, {
      userIdColumn: owner.id,
      textColumn: text,
      isSyncedWithCloudColumn: 1,
    });

    final entry = DatabaseEntry(
      id: entryId,
      userId: owner.id,
      title: title,
      photoA: Uint8List(0),
      photoB: Uint8List(0),
      text: text,
      isSyncedWithCloud: true, // not being used
    );

    _entries.add(entry);
    _entryStreamController.add(_entries);

    return entry;
  }

  Future<DatabaseUser> getUser({required String email}) async {
    await _ensureDbIsOpen();
    final db = _getDatabaseOrThrow();

    final results = await db.query(
      userTable,
      limit: 1,
      where: 'email = ?',
      whereArgs: [email.toLowerCase()],
    );
    if (results.isEmpty) {
      devtools.log("Could Not find User");
      throw CouldNotFindUser();
    } else {
      devtools.log("DatabaseUser Found");
      //devtools.log(results.first.toString());
      //devtools.log(DatabaseUser.fromRow(results.first).toString());
      DatabaseUser user = DatabaseUser.fromRow(results.first);
      //return DatabaseUser.fromRow(results.first);
      devtools.log("" + user.id.toString());
      devtools.log("Foo");
      devtools.log(user.email);
      devtools.log(user.toString());
      return user;
    }
  }

  Future<DatabaseUser> createUser({required String email}) async {
    await _ensureDbIsOpen();
    final db = _getDatabaseOrThrow();
    final results = await db.query(
      userTable,
      limit: 1,
      where: 'email = ?',
      whereArgs: [email.toLowerCase()],
    );
    if (results.isNotEmpty) {
      throw UserAlreadyExists();
    }

    final userId = await db.insert(userTable, {
      emailColumn: email.toLowerCase(),
    });

    return DatabaseUser(id: userId, email: email);
  }

  // delete user emails
  Future<void> deleteUser({required String email}) async {
    await _ensureDbIsOpen();
    final db = _getDatabaseOrThrow();
    final deletedCount = await db.delete(
      userTable,
      where: 'email = ?',
      whereArgs: [email.toLowerCase()],
    );
    if (deletedCount != 1) {
      throw CouldNotDeleteUser();
    }
  }

  Database _getDatabaseOrThrow() {
    final db = _db;
    if (db == null) {
      throw DatabaseIsNotOpen();
    } else {
      return db;
    }
  }

  Future<void> close() async {
    final db = _db;
    if (db == null) {
      throw DatabaseIsNotOpen();
    } else {
      await db.close();
      _db = null;
    }
  }

  Future<void> _ensureDbIsOpen() async {
    try {
      await open();
    } on DatabaseAlreadyOpenException {
      // empty
    }
  }

  Future<void> open() async {
    if (_db != null) {
      throw DatabaseAlreadyOpenException();
    }
    try {
      final docsPath = await getApplicationDocumentsDirectory();
      final dbPath = join(docsPath.path, dbName);
      final db = await openDatabase(dbPath);
      _db = db;
      // create sql user table
      const createUserTable = '''
CREATE TABLE IF NOT EXISTS "user" (
	"id"	INTEGER NOT NULL,
	"email"	TEXT NOT NULL UNIQUE,
	PRIMARY KEY("id" AUTOINCREMENT)
);
''';
      await db.execute(createUserTable);
      //await db.execute(dropEntryTable);
      await db.execute(createEntryTable);

      // !!! profile table
      await db.execute(createProfileTable);

      await _cacheEntries();
    } on MissingPlatformDirectoryException {
      throw UnableToGetDocumentsDirectory();
    }
  }

  Future<DatabaseProfile> createProfile({
    required int userID,
    required String Title,
    required Uint8List PhotoA,
    required Uint8List PhotoB,
    required String Description,
  }) async {
    await _ensureDbIsOpen();
    final db = _getDatabaseOrThrow();
    final results = await db.query(
      profileTable,
      limit: 1,
      where: 'user_id = ?',
      whereArgs: [userID],
    );
    if (results.isNotEmpty) {
      throw UserAlreadyExists();
    }

    await db.insert(profileTable, {
      "user_id": userID,
      "Title": Title,
      "PhotoA": PhotoA,
      "PhotoB": PhotoB,
      "Description": Description,
    });

    return DatabaseProfile(
        user_id: userID,
        Title: Title,
        PhotoA: PhotoA,
        PhotoB: PhotoB,
        Description: Description);
  }

  // delete user profile (if needed)
  Future<void> deleteProfile({required int userID}) async {
    await _ensureDbIsOpen();
    final db = _getDatabaseOrThrow();
    final deletedCount = await db.delete(
      profileTable,
      where: 'user_id = ?',
      whereArgs: [userID],
    );
    if (deletedCount != 1) {
      throw CouldNotDeleteUser();
    }
  }

  Future<DatabaseProfile> getProfile({required int userID}) async {
    await _ensureDbIsOpen();
    final db = _getDatabaseOrThrow();
    final results = await db.query(
      profileTable,
      limit: 1,
      where: 'user_id = ?',
      whereArgs: [userID],
    );
    if (results.isEmpty) {
      devtools.log('No existing profile found');
      throw ProfileDoesNotExist();
    } else {
      DatabaseProfile profile = DatabaseProfile.fromRow(results.first);
      devtools.log('Existing Profile found');
      return profile;
    }
  }

  Future<DatabaseProfile> updateProfile({
    required DatabaseProfile profile,
    required String title,
    required String description,
    required Uint8List PhotoA,
    required Uint8List PhotoB,
  }) async {
    await _ensureDbIsOpen();
    final db = _getDatabaseOrThrow();

    // make sure profile exists
    await getProfile(userID: profile.user_id);

    // update DB
    final updatesCount = await db.update(
      profileTable,
      {
        //"user_id":	INTEGER UNIQUE,
        "Title": title,
        "PhotoA": PhotoA,
        "PhotoB": PhotoB,
        "Description": description,
      },
      where: 'user_id = ?',
      whereArgs: [profile.user_id],
    );

    if (updatesCount == 0) {
      throw CouldNotUpdateEntry();
    } else {
      final updatedProfile = await getProfile(userID: profile.user_id);
      return updatedProfile;
    }
  }

  // Save/Load Data Functions
}

// all subtypes of class must be final
@immutable
class DatabaseUser {
  final int id;
  final String email;
  const DatabaseUser({
    required this.id,
    required this.email,
  });

  // Factory constructor to recreate DatabaseUser from database query result
  factory DatabaseUser.fromRow(Map<String, Object?> map) {
    devtools.log("Mapping...");
    DatabaseUser user = DatabaseUser(
      id: map[idColumn] as int,
      email: map[emailColumn] as String,
    );
    devtools.log("Finished");
    return user;
  }
  @override
  String toString() {
    return 'Person, ID = $id, email = $email';
  }

  // *! check if two different users are equal covariants for comparing objects
  @override
  bool operator ==(covariant DatabaseUser other) => id == other.id;

  @override
  int get hashCode => id.hashCode;
}

class DatabaseEntry {
  final int id;
  final int userId;
  final String title;
  final String text;
  final Uint8List? photoA;
  final Uint8List? photoB;
  final bool isSyncedWithCloud;

  DatabaseEntry(
      {required this.id,
      required this.userId,
      required this.title,
      required this.text,
      required this.photoA,
      required this.photoB,
      required this.isSyncedWithCloud});

  DatabaseEntry.fromRow(Map<String, Object?> map)
      : id = map[idColumn] as int,
        userId = map[userIdColumn] as int,
        title = map[titleColumn] as String? ?? '',
        text = map[textColumn] as String,
        photoA = map[photoAColumn] as Uint8List?,
        photoB = map[photoBColumn] as Uint8List?,
        isSyncedWithCloud =
            (map[isSyncedWithCloudColumn] as int) == 1 ? true : false;

  @override
  String toString() {
    return 'Entry, ID = $id, userId = $userId, isSynchedWithCloud = $isSyncedWithCloud';
  }

  @override
  bool operator ==(covariant DatabaseEntry other) => id == other.id;

  @override
  int get hashCode => id.hashCode;
}

class DatabaseProfile {
  final int user_id;
  final String Title;
  final Uint8List? PhotoA;
  final Uint8List? PhotoB;
  final String Description;

  DatabaseProfile(
      {required this.user_id,
      required this.Title,
      required this.PhotoA,
      required this.PhotoB,
      required this.Description});

  DatabaseProfile.fromRow(Map<String, Object?> map)
      : user_id = map['user_id'] as int,
        Title = map['Title'] as String,
        PhotoA = map['PhotoA'] as Uint8List,
        PhotoB = map['PhotoB'] as Uint8List,
        Description = (map['Description'] as String);

  @override
  String toString() {
    return 'user_Id = $user_id, Title = $Title, Description = $Description';
  }

  @override
  bool operator ==(covariant DatabaseProfile other) => user_id == other.user_id;

  @override
  int get hashCode => user_id.hashCode;
}

const dbName = 'entries.db';
const entryTable = 'entry';
const userTable = 'user';
const profileTable = 'profile';
const idColumn = 'id';
const emailColumn = 'email';
const userIdColumn = 'user_id';
const textColumn = 'text';
const titleColumn = 'title';
const photoAColumn = 'PhotoA';
const photoBColumn = 'PhotoB';
const isSyncedWithCloudColumn = 'is_synced_with_cloud';

const createUserTable = '''
CREATE TABLE IF NOT EXISTS "user" (
	"id"	INTEGER NOT NULL,
	"email"	TEXT NOT NULL UNIQUE,
	PRIMARY KEY("id" AUTOINCREMENT)
);
''';

const createEntryTable = '''
CREATE TABLE IF NOT EXISTS "entry" (
	"id"	INTEGER NOT NULL,
	"user_id"	INTEGER NOT NULL,
  "title"	TEXT,
	"text"	TEXT,
  "PhotoA"	BLOB,
	"PhotoB"	BLOB,
	"is_synced_with_cloud"	INTEGER DEFAULT 0,
	FOREIGN KEY("user_id") REFERENCES "user"("ID"),
	PRIMARY KEY("ID" AUTOINCREMENT)
);
''';

const dropEntryTable = '''
DROP TABLE IF EXISTS "entry";
''';

const createProfileTable = '''
CREATE TABLE IF NOT EXISTS "profile" (
	"user_id"	INTEGER UNIQUE,
	"Title"	TEXT,
	"PhotoA"	BLOB,
	"PhotoB"	BLOB,
	"Description"	TEXT,
	FOREIGN KEY("user_id") REFERENCES "user"("ID"),
	PRIMARY KEY("user_id")
);
''';
