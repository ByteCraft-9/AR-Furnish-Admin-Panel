// Web-compatible stubs for path provider classes

// PathProviderPlatform stub
class PathProviderPlatform {
  static PathProviderPlatform? _instance;
  static PathProviderPlatform get instance =>
      _instance ?? PathProviderPlatform();
  static set instance(PathProviderPlatform instance) {
    _instance = instance;
  }
}

// PathProviderWindows stub
class PathProviderWindows extends PathProviderPlatform {
  PathProviderWindows();
}

// Stubs for various path provider methods
Future<String?> getTemporaryPath() async => null;
Future<String?> getApplicationSupportPath() async => null;
Future<String?> getLibraryPath() async => null;
Future<String?> getApplicationDocumentsPath() async => null;
Future<String?> getExternalStoragePath() async => null;
Future<List<String>?> getExternalCachePaths() async => null;
Future<List<String>?> getExternalStoragePaths() async => null;
Future<String?> getDownloadsPath() async => null;
