import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void setupDatabase() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
}
