import 'dart:async';
import 'dart:io';

import 'package:carerassistant/extensions/list/filter.dart';
import 'package:carerassistant/services/entity_service_exceptions.dart';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' show join;
import 'dart:developer' as devtools show log;

class NotesService {
  Database? _db;

  List<DatabaseEntry> _notes = [];

  DatabaseUser? _user;

  // create notes service as a singleton, this is how to create singletons in dart
  static final NotesService _shared = NotesService._sharedInstance();
  NotesService._sharedInstance() {
    _notesStreamController = StreamController<List<DatabaseEntry>>.broadcast(
      onListen: () {
        // populate stream controller from database notes
        _notesStreamController.sink.add(_notes);
      },
    );
  }
  factory NotesService() => _shared;

  // create a stream pipeline, broadcast allows the controller to be listened to multiple times
  late final StreamController<List<DatabaseEntry>> _notesStreamController;

  Stream<List<DatabaseEntry>> get allNotes =>
      _notesStreamController.stream.filter((note) {
        final currentUser = _user;
        if (currentUser != null) {
          return note.userId == currentUser.id;
        } else {
          throw UserShouldBeSetBeforeReadingAllNotes();
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

  Future<void> _cacheNotes() async {
    final allNotes = await getAllNotes();
    _notes = allNotes.toList();
    _notesStreamController.add(_notes);
  }

  Future<DatabaseEntry> updateNote({
    required DatabaseEntry note,
    required String text,
    required String title,
    required Uint8List photoA,
    required Uint8List photoB,
  }) async {
    await _ensureDbIsOpen();
    final db = _getDatabaseOrThrow();

    // make sure note exists
    await getNote(id: note.id);

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
      whereArgs: [note.id],
    );

    if (updatesCount == 0) {
      throw CouldNotUpdateNote();
    } else {
      final updatedNote = await getNote(id: note.id);
      _notes.removeWhere((note) => note.id == updatedNote.id);
      _notes.add(updatedNote);
      _notesStreamController.add(_notes);
      return updatedNote;
    }
  }

  Future<Iterable<DatabaseEntry>> getAllNotes() async {
    await _ensureDbIsOpen();
    final db = _getDatabaseOrThrow();
    final notes = await db.query(entryTable);

    return notes.map((noteRow) => DatabaseEntry.fromRow(noteRow));
  }

  Future<DatabaseEntry> getNote({required int id}) async {
    await _ensureDbIsOpen();
    final db = _getDatabaseOrThrow();
    final notes = await db.query(
      entryTable,
      limit: 1,
      where: 'id = ?',
      whereArgs: [id],
    );

    if (notes.isEmpty) {
      throw CouldNotFindNote();
    } else {
      final note = DatabaseEntry.fromRow(notes.first);
      _notes.removeWhere((note) => note.id == id);
      _notes.add(note);
      _notesStreamController.add(_notes);
      return note;
    }
  }

  Future<int> deleteAllNotes() async {
    await _ensureDbIsOpen();
    final db = _getDatabaseOrThrow();
    final numberOfDeletions = await db.delete(entryTable);
    _notes = [];
    _notesStreamController.add(_notes);
    return numberOfDeletions;
  }

  Future<void> deleteNote({required int id}) async {
    await _ensureDbIsOpen();
    final db = _getDatabaseOrThrow();
    final deletedCount = await db.delete(
      entryTable,
      where: 'id = ?',
      whereArgs: [id],
    );
    if (deletedCount == 0) {
      throw CouldNotDeleteNote();
    } else {
      _notes.removeWhere((note) => note.id == id);
      _notesStreamController.add(_notes);
    }
  }

  Future<DatabaseEntry> createNote({required DatabaseUser owner}) async {
    await _ensureDbIsOpen();
    final db = _getDatabaseOrThrow();

    // make sure owner exists in the database with the correct id
    final dbUser = await getUser(email: owner.email);
    if (dbUser != owner) {
      throw CouldNotFindUser();
    }

    const text = '';
    const title = '';
    // create the note
    final noteId = await db.insert(entryTable, {
      userIdColumn: owner.id,
      textColumn: text,
      isSyncedWithCloudColumn: 1,
    });
// !!! RETURN
    final note = DatabaseEntry(
      id: noteId,
      userId: owner.id,
      title: title,
      photoA: Uint8List(0),
      photoB: Uint8List(0),
      text: text,
      isSyncedWithCloud: true,
    );

    _notes.add(note);
    _notesStreamController.add(_notes);

    return note;
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
/*  REMOVED INCORRECT TABLE
      const createNoteTable = '''
CREATE TABLE IF NOT EXISTS "entry" (
	"id"	INTEGER NOT NULL,
	"user_id"	INTEGER NOT NULL,
	"text"	TEXT,
	"is_synched_with_cloud"	INTEGER DEFAULT 0,
	FOREIGN KEY("user_id") REFERENCES "user"("ID"),
	PRIMARY KEY("ID" AUTOINCREMENT)
);
''';
*/
      //await db.execute(dropNoteTable);
      await db.execute(createNoteTable);

      // !!! profile table
      await db.execute(createProfileTable);

      await _cacheNotes();
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
      throw CouldNotUpdateNote();
    } else {
      final updatedProfile = await getProfile(userID: profile.user_id);
      // Should just remove Note stuff
      //_notes.removeWhere((profile) => profile.userId == updatedProfile.user_id);
      //_notes.add(updatedNote);
      //_notesStreamController.add(_notes);
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
    return 'Note, ID = $id, userId = $userId, isSynchedWithCloud = $isSyncedWithCloud';
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

// !!! Photos must be mapped correctly
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

const dbName = 'notes.db';
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

const createNoteTable = '''
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

const dropNoteTable = '''
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
