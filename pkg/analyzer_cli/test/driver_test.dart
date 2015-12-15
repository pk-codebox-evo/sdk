// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer_cli.test.driver;

import 'dart:io';

import 'package:analyzer/plugin/options.dart';
import 'package:analyzer/source/analysis_options_provider.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/error.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/plugin/plugin_configuration.dart';
import 'package:analyzer/src/services/lint.dart';
import 'package:analyzer_cli/src/bootloader.dart';
import 'package:analyzer_cli/src/driver.dart';
import 'package:analyzer_cli/src/options.dart';
import 'package:path/path.dart' as path;
import 'package:plugin/plugin.dart';
import 'package:unittest/unittest.dart';
import 'package:yaml/src/yaml_node.dart';

import 'utils.dart';

main() {
  StringSink savedOutSink, savedErrorSink;
  int savedExitCode;
  ExitHandler savedExitHandler;

  /// Base setup.
  _setUp() {
    savedOutSink = outSink;
    savedErrorSink = errorSink;
    savedExitHandler = exitHandler;
    savedExitCode = exitCode;
    exitHandler = (code) => exitCode = code;
    outSink = new StringBuffer();
    errorSink = new StringBuffer();
  }

  /// Base teardown.
  _tearDown() {
    outSink = savedOutSink;
    errorSink = savedErrorSink;
    exitCode = savedExitCode;
    exitHandler = savedExitHandler;
  }

  setUp(() => _setUp());

  tearDown(() => _tearDown());

  initializeTestEnvironment();

  group('Driver', () {
    group('options', () {
      test('custom processor', () {
        Driver driver = new Driver();
        TestProcessor processor = new TestProcessor();
        driver.userDefinedPlugins = [new TestPlugin(processor)];
        driver.start([
          '--options',
          path.join(testDirectory, 'data/test_options.yaml'),
          path.join(testDirectory, 'data/test_file.dart')
        ]);
        expect(processor.options['test_plugin'], isNotNull);
        expect(processor.exception, isNull);
      });
    });

    //TODO(pq): refactor to NOT set actual error codes to play nice with bots
    group('exit codes', () {
      test('fatal hints', () {
        drive('data/file_with_hint.dart', args: ['--fatal-hints']);
        expect(exitCode, 3);
      });

      test('not fatal hints', () {
        drive('data/file_with_hint.dart');
        expect(exitCode, 0);
      });

      test('fatal errors', () {
        drive('data/file_with_error.dart');
        expect(exitCode, 3);
      });

      test('not fatal warnings', () {
        drive('data/file_with_warning.dart');
        expect(exitCode, 0);
      });

      test('fatal warnings', () {
        drive('data/file_with_warning.dart', args: ['--fatal-warnings']);
        expect(exitCode, 3);
      });

      test('missing options file', () {
        drive('data/test_file.dart', options: 'data/NO_OPTIONS_HERE');
        expect(exitCode, 3);
      });

      test('missing dart file', () {
        drive('data/NO_DART_FILE_HERE.dart');
        expect(exitCode, 3);
      });

      test('part file', () {
        drive('data/library_and_parts/part2.dart');
        expect(exitCode, 3);
      });

      test('non-dangling part file', () {
        Driver driver = new Driver();
        driver.start([
          path.join(testDirectory, 'data/library_and_parts/lib.dart'),
          path.join(testDirectory, 'data/library_and_parts/part1.dart')
        ]);
        expect(exitCode, 0);
      });

      test('extra part file', () {
        Driver driver = new Driver();
        driver.start([
          path.join(testDirectory, 'data/library_and_parts/lib.dart'),
          path.join(testDirectory, 'data/library_and_parts/part1.dart'),
          path.join(testDirectory, 'data/library_and_parts/part2.dart')
        ]);
        expect(exitCode, 3);
      });
    });

    group('linter', () {
      group('lints in options', () {
        // Shared lint command.
        var runLinter = () => drive('data/linter_project/test_file.dart',
            options: 'data/linter_project/.analysis_options',
            args: ['--lints']);

        test('gets analysis options', () {
          runLinter();

          /// Lints should be enabled.
          expect(driver.context.analysisOptions.lint, isTrue);

          /// The .analysis_options file only specifies 'camel_case_types'.
          var lintNames = getLints(driver.context).map((r) => r.name);
          expect(lintNames, orderedEquals(['camel_case_types']));
        });

        test('generates lints', () {
          runLinter();
          expect(outSink.toString(),
              contains('[lint] Name types using UpperCamelCase.'));
        });
      });

      group('default lints', () {
        // Shared lint command.
        var runLinter = () => drive('data/linter_project/test_file.dart',
            options: 'data/linter_project/.analysis_options',
            args: ['--lints']);

        test('gets default lints', () {
          runLinter();

          /// Lints should be enabled.
          expect(driver.context.analysisOptions.lint, isTrue);

          /// Default list should include camel_case_types.
          var lintNames = getLints(driver.context).map((r) => r.name);
          expect(lintNames, contains('camel_case_types'));
        });

        test('generates lints', () {
          runLinter();
          expect(outSink.toString(),
              contains('[lint] Name types using UpperCamelCase.'));
        });
      });

      group('no `--lints` flag (none in options)', () {
        // Shared lint command.
        var runLinter = () => drive('data/no_lints_project/test_file.dart',
            options: 'data/no_lints_project/.analysis_options');

        test('lints disabled', () {
          runLinter();
          expect(driver.context.analysisOptions.lint, isFalse);
        });

        test('no registered lints', () {
          runLinter();
          expect(getLints(driver.context), isEmpty);
        });

        test('no generated warnings', () {
          runLinter();
          expect(outSink.toString(), contains('No issues found'));
        });
      });
    });

    test('containsLintRuleEntry', () {
      Map<String, YamlNode> options;
      options = parseOptions('''
linter:
  rules:
    - foo
        ''');
      expect(containsLintRuleEntry(options), true);
      options = parseOptions('''
        ''');
      expect(containsLintRuleEntry(options), false);
      options = parseOptions('''
linter:
  rules:
    # - foo
        ''');
      expect(containsLintRuleEntry(options), true);
      options = parseOptions('''
linter:
 # rules:
    # - foo
        ''');
      expect(containsLintRuleEntry(options), false);
    });

    group('options processing', () {
      // Shared driver command.
      var doDrive = () => drive('data/options_tests_project/test_file.dart',
          options: 'data/options_tests_project/.analysis_options');

      group('error filters', () {
        test('filters', () {
          doDrive();
          var processors =
              driver.context.getConfigurationData(CONFIGURED_ERROR_PROCESSORS);
          expect(processors, hasLength(1));

          var unused_local_variable = new AnalysisError(
              new TestSource(), 0, 1, HintCode.UNUSED_LOCAL_VARIABLE, [
            ['x']
          ]);

          var unusedLocalVariable =
              processors.firstWhere((p) => p.appliesTo(unused_local_variable));
          expect(unusedLocalVariable.severity, isNull);
        });

        test('language config', () {
          doDrive();
          expect(driver.context.analysisOptions.enableSuperMixins, isTrue);
        });
      });
    });

//TODO(pq): fix to be bot-friendly (sdk#25258).
//    group('in temp directory', () {
//      Directory savedCurrentDirectory;
//      Directory tempDir;
//      setUp(() {
//        // Call base setUp.
//        _setUp();
//        savedCurrentDirectory = Directory.current;
//        tempDir = Directory.systemTemp.createTempSync('analyzer_');
//      });
//      tearDown(() {
//        Directory.current = savedCurrentDirectory;
//        tempDir.deleteSync(recursive: true);
//        // Call base tearDown.
//        _tearDown();
//      });
//
//      test('packages folder', () {
//        Directory.current = tempDir;
//        new File(path.join(tempDir.path, 'test.dart')).writeAsStringSync('''
//import 'package:foo/bar.dart';
//main() {
//  baz();
//}
//        ''');
//        Directory packagesDir =
//            new Directory(path.join(tempDir.path, 'packages'));
//        packagesDir.createSync();
//        Directory fooDir = new Directory(path.join(packagesDir.path, 'foo'));
//        fooDir.createSync();
//        new File(path.join(fooDir.path, 'bar.dart')).writeAsStringSync('''
//void baz() {}
//        ''');
//        new Driver().start(['test.dart']);
//        expect(exitCode, 0);
//      });
//
//      test('no package resolution', () {
//        Directory.current = tempDir;
//        new File(path.join(tempDir.path, 'test.dart')).writeAsStringSync('''
//import 'package:path/path.dart';
//main() {}
//        ''');
//        new Driver().start(['test.dart']);
//        expect(exitCode, 3);
//        String stdout = outSink.toString();
//        expect(stdout, contains('[error] Target of URI does not exist'));
//        expect(stdout, contains('1 error found.'));
//        expect(errorSink.toString(), '');
//      });
//
//      test('bad package root', () {
//        new Driver().start(['--package-root', 'does/not/exist', 'test.dart']);
//        String stdout = outSink.toString();
//        expect(exitCode, 3);
//        expect(
//            stdout,
//            contains(
//                'Package root directory (does/not/exist) does not exist.'));
//      });
//    });
  });

  group('Bootloader', () {
    group('plugin processing', () {
      test('bad format', () {
        BootLoader loader = new BootLoader();
        loader.createImage([
          '--options',
          path.join(testDirectory, 'data/bad_plugin_options.yaml'),
          path.join(testDirectory, 'data/test_file.dart')
        ]);
        expect(
            errorSink.toString(),
            equals('Plugin configuration skipped: Unrecognized plugin config '
                'format, expected `YamlMap`, got `YamlList` '
                '(line 2, column 4)\n'));
      });
      test('plugin config', () {
        BootLoader loader = new BootLoader();
        Image image = loader.createImage([
          '--options',
          path.join(testDirectory, 'data/plugin_options.yaml'),
          path.join(testDirectory, 'data/test_file.dart')
        ]);
        var plugins = image.config.plugins;
        expect(plugins, hasLength(1));
        expect(plugins.first.name, equals('my_plugin1'));
      });
      group('plugin validation', () {
        test('requires class name', () {
          expect(
              validate(new PluginInfo(
                  name: 'test_plugin', libraryUri: 'my_package/foo.dart')),
              isNotNull);
        });
        test('requires library URI', () {
          expect(
              validate(
                  new PluginInfo(name: 'test_plugin', className: 'MyPlugin')),
              isNotNull);
        });
        test('check', () {
          expect(
              validate(new PluginInfo(
                  name: 'test_plugin',
                  className: 'MyPlugin',
                  libraryUri: 'my_package/foo.dart')),
              isNull);
        });
      });
    });
  });
}

const emptyOptionsFile = 'data/empty_options.yaml';

/// Shared driver.
Driver driver;

/// Start a driver for the given [source], optionally providing additional
/// [args] and an [options] file path.  The value of [options] defaults to
/// an empty options file to avoid unwanted configuration from an otherwise
/// discovered options file.
void drive(String source,
    {String options: emptyOptionsFile, List<String> args: const <String>[]}) {
  driver = new Driver();
  var cmd = [
    '--options',
    path.join(testDirectory, options),
    path.join(testDirectory, source)
  ]..addAll(args);
  driver.start(cmd);
}

Map<String, YamlNode> parseOptions(String src) =>
    new AnalysisOptionsProvider().getOptionsFromString(src);

class TestPlugin extends Plugin {
  TestProcessor processor;
  TestPlugin(this.processor);

  @override
  String get uniqueIdentifier => 'test_plugin.core';

  @override
  void registerExtensionPoints(RegisterExtensionPoint register) {
    // None
  }

  @override
  void registerExtensions(RegisterExtension register) {
    register(OPTIONS_PROCESSOR_EXTENSION_POINT_ID, processor);
  }
}

class TestProcessor extends OptionsProcessor {
  Map<String, YamlNode> options;
  Exception exception;

  @override
  void onError(Exception exception) {
    this.exception = exception;
  }

  @override
  void optionsProcessed(
      AnalysisContext context, Map<String, YamlNode> options) {
    this.options = options;
  }
}

class TestSource implements Source {
  TestSource();

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}