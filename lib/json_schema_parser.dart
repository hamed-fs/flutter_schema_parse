import 'package:recase/recase.dart';
import 'package:dart_style/dart_style.dart';
import 'package:inflection2/inflection2.dart';

import 'package:flutter_schema_parse/model.dart';

const Map<String, String> _typeMap = <String, String>{
  'integer': 'int',
  'string': 'String',
  'number': 'num',
};

class JsonSchemaParser {
  static String _getObjectName(String type, String name) => type == 'object'
      ? ReCase(name).pascalCase
      : type == 'array' ? convertToSingular(ReCase(name).pascalCase) : null;

  static String _getObjectType(String type, String name) => type == 'object'
      ? ReCase(name).pascalCase
      : type == 'array'
          ? 'List<${convertToSingular(ReCase(name).pascalCase)}>'
          : _typeMap[type];

  static List<Model> _getModel(Map<String, dynamic> jsonSchema) {
    List<Model> parent = [];

    if (jsonSchema['properties'] != null) {
      for (var property in jsonSchema['properties'].entries) {
        Model child = Model();

        child.title = ReCase(property.key).camelCase;
        child.type = _getObjectType(property.value['type'], property.key);
        child.className = _getObjectName(property.value['type'], property.key);
        child.children = [];

        if (property.value['type'] == 'object') {
          child.children.addAll(_getModel(property.value));
        } else if (property.value['type'] == 'array') {
          child.children.addAll(_getModel(property.value['items']));
        }

        parent.add(child);
      }
    }

    return parent;
  }

  static String getClass(String className, Map<String, dynamic> schema) {
    List<Model> models = _getModel(schema);
    StringBuffer result = StringBuffer();

    result.write('class $className {');
    for (Model model in models) {
      result.write('final ${model.className ?? model.type} ${model.title};');
    }

    result.write('$className({');
    for (Model model in models) {
      result.write('this.${model.title},');
    }
    result.write('});');

    result.write('}');

    return DartFormatter().format(result.toString());
  }
}
