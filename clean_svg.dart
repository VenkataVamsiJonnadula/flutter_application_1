import 'dart:io';

void main() {
  final file = File('assets/full_brand_logo.svg');
  if (!file.existsSync()) {
    stdout.writeln('File not found');
    return;
  }
  
  String content = file.readAsStringSync();
  
  // Remove the <style> block completely
  final RegExp styleRegExp = RegExp(r'<style[^>]*>.*?<!\[CDATA\[(.*?)\]\]>.*?</style>', dotAll: true);
  content = content.replaceAll(styleRegExp, '');
  
  // Remove DOCTYPE just in case
  final RegExp doctypeRegExp = RegExp(r'<!DOCTYPE[^>]*>');
  content = content.replaceAll(doctypeRegExp, '');
  
  file.writeAsStringSync(content);
  stdout.writeln('Cleaned SVG successfully!');
}
