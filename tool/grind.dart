import 'dart:io';

import 'package:grinder/grinder.dart';
import 'package:pubspec/pubspec.dart';

final pub = sdkBin('pub');
final analyser = sdkBin('dartanalyzer');

void main(List<String> args) => grind(args);

@Task('Run tests')
@Depends(analysis)
void test() => TestRunner().testAsync();

@Task('Dart analysis')
void analysis() {
  Pub.getAsync();
  Analyzer.analyze(['lib/', 'test/'], fatalWarnings: true);
}

@Task('Test pub')
@Depends(analysis, test)
void testPub() {
  runProcess(pub, ['publish', '-n']);
}

@Task('Tag on git')
@Depends(analysis, test)
void git() {
  var yamlString = File('pubspec.yaml').readAsStringSync();
  final pubspec = PubSpec.fromYamlString(yamlString);
  final ver = pubspec.version;
  runProcess('git', ['add', '.']);
  runProcess('git', ['commit', '-m', 'Update v$ver']);
  runProcess('git', ['tag', '-a', 'v$ver', '-m', 'Version $ver']);
  //runProcess('git', ['push', 'origin', '--tags']);
  print('Here should push v$ver');
}

@Task('Publish on pub')
@Depends(
  git,
  testPub,
  analysis,
  test,
)
void publishPub() {
  runProcess(pub, ['publish', '-f']);
  print('Here should publish');
}

void runProcess(String executable, List<String> args) {
  var proc = Process.runSync(executable, args);
  if (proc.exitCode != 0) {
    throw Exception(
        'Failed with exitCode: ${proc.exitCode}:\n${proc.stdout}\n-----\n'
        '${proc.stderr}');
  }
}
