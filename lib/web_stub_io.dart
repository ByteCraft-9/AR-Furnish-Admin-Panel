// Web-compatible stubs for dart:io classes

// Platform stub for web
class Platform {
  static bool get isWindows => false;
  static bool get isAndroid => false;
  static bool get isIOS => false;
  static bool get isMacOS => false;
  static bool get isLinux => false;
  static bool get isFuchsia => false;

  static String get operatingSystem => 'web';
  static String get operatingSystemVersion => 'web';
}

// Directory stub for web
class Directory {
  final String path;

  Directory(this.path);

  static Directory get current => Directory('');

  Future<bool> exists() async => false;
  Future<Directory> create({bool recursive = false}) async => this;
}

// File stub for web
class File {
  final String path;

  File(this.path);

  Future<bool> exists() async => false;
  Future<File> writeAsBytes(List<int> bytes) async => this;
  Future<File> writeAsString(String contents) async => this;
  Future<List<int>> readAsBytes() async => [];
}
