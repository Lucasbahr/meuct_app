// Incrementa version no pubspec.yaml (execute na raiz do projeto).
// Uso: dart tool/bump_version.dart [patch|minor|major|build]
// Padrão: patch  (dart run tool/bump_version.dart também funciona, pode ser mais lento)

import 'dart:io';

void main(List<String> args) {
  final pubspec = File('pubspec.yaml');
  if (!pubspec.existsSync()) {
    stderr.writeln('pubspec.yaml não encontrado. Rode na raiz do projeto Flutter.');
    exit(1);
  }

  final lines = pubspec.readAsLinesSync();
  final re = RegExp(r'^version:\s*(\d+)\.(\d+)\.(\d+)\+(\d+)\s*$');
  var index = -1;
  Match? match;
  for (var i = 0; i < lines.length; i++) {
    final m = re.firstMatch(lines[i].trimRight());
    if (m != null) {
      index = i;
      match = m;
      break;
    }
  }
  if (match == null || index < 0) {
    stderr.writeln('Linha version: M.m.p+b não encontrada no pubspec.yaml');
    exit(1);
  }

  var major = int.parse(match.group(1)!);
  var minor = int.parse(match.group(2)!);
  var patch = int.parse(match.group(3)!);
  var build = int.parse(match.group(4)!);

  final mode = args.isEmpty ? 'patch' : args.first;
  switch (mode) {
    case 'build':
      build += 1;
      break;
    case 'patch':
      patch += 1;
      build += 1;
      break;
    case 'minor':
      minor += 1;
      patch = 0;
      build += 1;
      break;
    case 'major':
      major += 1;
      minor = 0;
      patch = 0;
      build += 1;
      break;
    default:
      stderr.writeln(
        'Uso: dart tool/bump_version.dart [patch|minor|major|build]',
      );
      exit(1);
  }

  lines[index] = 'version: $major.$minor.$patch+$build';
  pubspec.writeAsStringSync('${lines.join('\n')}\n');
  stdout.writeln('Atualizado: ${lines[index]}');
}
