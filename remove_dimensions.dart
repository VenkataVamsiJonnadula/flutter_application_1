import 'dart:io';

void main() {
  final file = File('assets/full_brand_logo.svg');
  if (!file.existsSync()) {
    stdout.writeln('File not found');
    return;
  }
  
  String content = file.readAsStringSync();
  
  // Remove width="..." and height="..." from the <svg> tag
  final RegExp widthRegExp = RegExp(r'width="[^"]+"');
  final RegExp heightRegExp = RegExp(r'height="[^"]+"');
  
  content = content.replaceFirst(widthRegExp, '');
  content = content.replaceFirst(heightRegExp, '');
  
  file.writeAsStringSync(content);
  stdout.writeln('Removed width and height successfully!');
}
