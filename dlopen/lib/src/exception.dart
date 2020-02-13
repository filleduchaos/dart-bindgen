class DlOpenException implements Exception {
  const DlOpenException(this.libraryName, {
    String version,
    this.originalErrors = const [],
  }) : version = version ?? '';

  final String libraryName;
  final String version;
  final List<String> originalErrors;

  @override
  String toString() {
    var report = StringBuffer()..write('An exception occurred while opening library $libraryName');
    if (version.isNotEmpty) report.write(' at version $version');
    if (originalErrors.isNotEmpty) report..write(': \n')..writeAll(originalErrors, '\n');
    return report.toString();
  }
}
