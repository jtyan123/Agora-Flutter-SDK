import 'dart:io';

import 'package:dart_style/dart_style.dart';
import 'package:paraphrase/paraphrase.dart';
import 'package:testcase_gen/generator.dart';

const ignoreForFile = '// ignore_for_file: '
    'deprecated_member_use,'
    'constant_identifier_names';

const defaultHeader = '''
/// GENERATED BY testcase_gen. DO NOT MODIFY BY HAND.

$ignoreForFile
''';

abstract class DefaultGenerator implements Generator {
  const DefaultGenerator();

  GeneratorConfig? _getConfig(
      List<GeneratorConfig> configs, String methodName) {
    for (final config in configs) {
      if (config.name == methodName) {
        return config;
      }
    }
    return null;
  }

  String _concatParamName(String? prefix, String name) {
    if (prefix == null) return name;
    return '$prefix${name[0].toUpperCase()}${name.substring(1)}';
  }

  String _getParamType(Parameter parameter) {
    if (parameter.type.typeArguments.isEmpty) {
      return parameter.type.type;
    }

    return '${parameter.type.type}<${parameter.type.typeArguments.join(', ')}>';
  }

  String _createConstructorInitializerForMethodParameter(
    ParseResult parseResult,
    Parameter? rootParameter,
    Parameter parameter,
    StringBuffer initializerBuilder,
  ) {
    final bool isEnum = parseResult.hasEnum(parameter.type.type);

    if (isEnum) {
      final enumz = parseResult.getEnum(parameter.type.type)[0];

      initializerBuilder.writeln(
          'const ${_getParamType(parameter)} ${_concatParamName(rootParameter?.name, parameter.name)} = ${enumz.enumConstants[0].name};');

      return _concatParamName(rootParameter?.name, parameter.name);
    }

    stdout.writeln('parameter.type.type: ${parameter.type.type}');
    final parameterClass = parseResult.getClazz(parameter.type.type)[0];
    final initBlockParameterListBuilder = StringBuffer();
    final initBlockBuilder = StringBuffer();
    if (parameterClass.constructors.isEmpty) {
      return '';
    }

    final constructor = parameterClass.constructors[0];

    initBlockBuilder.write(parameterClass.name);
    initBlockBuilder.write('(');

    bool shouldBeConst = constructor.isConst;

    for (final cp in parameterClass.constructors[0].parameters) {
      final adjustedParamName = _concatParamName(parameter.name, cp.name);
      if (cp.isNamed) {
        if (cp.type.type == 'Function') {
          shouldBeConst = false;
          stdout.writeln(
              'cp.type.parameters: ${cp.type.parameters.map((e) => e.name.toString()).toString()}');
          final functionParamsList = cp.type.parameters
              .map((t) => '${t.type.type} ${t.name}')
              .join(', ');

          initBlockBuilder.write('${cp.name}:($functionParamsList) { },');
        } else if (cp.isPrimitiveType) {
          if (_getParamType(cp) == 'Uint8List') {
            shouldBeConst = false;
            initBlockParameterListBuilder.writeln(
                '${_getParamType(cp)} $adjustedParamName = ${cp.primitiveDefualtValue()};');
          } else {
            initBlockParameterListBuilder.writeln(
                'const ${_getParamType(cp)} $adjustedParamName = ${cp.primitiveDefualtValue()};');
          }

          initBlockBuilder.write('${cp.name}: $adjustedParamName,');
        } else {
          _createConstructorInitializerForMethodParameter(
              parseResult, parameter, cp, initializerBuilder);
          initBlockBuilder.write('${cp.name}: $adjustedParamName,');
        }
      } else {
        if (cp.type.type == 'Function') {
          final functionParamsList = cp.type.parameters
              .map((t) => '${t.type.type} ${t.name}')
              .join(', ');

          initBlockBuilder.write('${cp.name}:($functionParamsList) { },');
        } else if (cp.isPrimitiveType) {
          if (_getParamType(cp) == 'Uint8List') {
            initBlockParameterListBuilder.writeln(
                '${_getParamType(cp)} $adjustedParamName = ${cp.primitiveDefualtValue()};');
          } else {
            initBlockParameterListBuilder.writeln(
                'const ${_getParamType(cp)} $adjustedParamName = ${cp.primitiveDefualtValue()};');
          }

          initBlockBuilder.write('$adjustedParamName,');
        } else {
          _createConstructorInitializerForMethodParameter(
              parseResult, parameter, cp, initializerBuilder);
          initBlockBuilder.write('$adjustedParamName,');
        }
      }
    }

    initBlockBuilder.write(')');

    initializerBuilder.write(initBlockParameterListBuilder.toString());
    final keywordPrefix = shouldBeConst ? 'const' : 'final';

    initializerBuilder.writeln(
        '$keywordPrefix ${_getParamType(parameter)} ${_concatParamName(rootParameter?.name, parameter.name)} = ${initBlockBuilder.toString()};');
    return _concatParamName(rootParameter?.name, parameter.name);
  }

  String generateWithTemplate({
    required ParseResult parseResult,
    required Clazz clazz,
    required String testCaseTemplate,
    required String testCasesContentTemplate,
    required String methodInvokeObjectName,
    required List<GeneratorConfig> configs,
    List<GeneratorConfigPlatform>? supportedPlatformsOverride,
    List<String> skipMemberFunctions = const [],
  }) {
    final testCases = <String>[];
    for (final method in clazz.methods) {
      final methodName = method.name;

      if (skipMemberFunctions.contains(methodName)) {
        continue;
      }

      final config = _getConfig(configs, methodName);
      if (config?.donotGenerate == true) continue;
      if (methodName.startsWith('_')) continue;
      if (methodName.startsWith('create')) continue;

      StringBuffer pb = StringBuffer();

      for (final parameter in method.parameters) {
        if (parameter.type.type == 'Function') {
          continue;
        }
        if (parameter.isPrimitiveType) {
          final parameterType = _getParamType(parameter);
          if (parameterType == 'Uint8List') {
            pb.writeln(
                '${_getParamType(parameter)} ${parameter.name} = ${parameter.primitiveDefualtValue()};');
          } else {
            pb.writeln(
                'const ${_getParamType(parameter)} ${parameter.name} = ${parameter.primitiveDefualtValue()};');
          }
        } else {
          _createConstructorInitializerForMethodParameter(
              parseResult, null, parameter, pb);
        }
      }

      StringBuffer methodCallBuilder = StringBuffer();
      bool isFuture = method.returnType.type == 'Future';
      // methodCallBuilder.write('await screenShareHelper.$methodName(');
      methodCallBuilder.write(
          '${isFuture ? 'await ' : ''}$methodInvokeObjectName.$methodName(');
      for (final parameter in method.parameters) {
        if (parameter.isNamed) {
          methodCallBuilder.write('${parameter.name}:${parameter.name},');
        } else {
          methodCallBuilder.write('${parameter.name}, ');
        }
      }
      methodCallBuilder.write(');');

      pb.writeln(methodCallBuilder.toString());

      String skipExpression = 'false';

      if (supportedPlatformsOverride != null) {
        // skipExpression =
        //     '!(${desktopPlatforms.map((e) => e.toPlatformExpression()).join(' || ')})';
        skipExpression =
            '!(${supportedPlatformsOverride.map((e) => e.toPlatformExpression()).join(' || ')})';
      } else {
        if (config != null &&
            config.supportedPlatforms.length <
                GeneratorConfigPlatform.values.length) {
          skipExpression =
              '!(${config.supportedPlatforms.map((e) => e.toPlatformExpression()).join(' || ')})';
        }
      }

      String testCase =
          testCaseTemplate.replaceAll('{{TEST_CASE_NAME}}', methodName);
      testCase = testCase.replaceAll('{{TEST_CASE_BODY}}', pb.toString());
      testCase = testCase.replaceAll('{{TEST_CASE_SKIP}}', skipExpression);
      testCases.add(testCase);
    }

    final output = testCasesContentTemplate.replaceAll(
      '{{TEST_CASES_CONTENT}}',
      testCases.join('\n'),
    );

    return DartFormatter().format(output);
  }
}