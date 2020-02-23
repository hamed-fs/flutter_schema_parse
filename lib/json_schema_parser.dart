import 'package:recase/recase.dart';
import 'package:inflection2/inflection2.dart';

import 'package:flutter_schema_parse/model.dart';

const Map<String, String> _typeMap = <String, String>{
  'integer': 'int',
  'string': 'String',
  'number': 'num',
};

class JsonSchemaParser {
  static List<Model> getModel(Map<String, dynamic> jsonSchema) {
    List<Model> parent = [];

    if (jsonSchema['properties'] != null) {
      for (var property in jsonSchema['properties'].entries) {
        Model child = Model();

        child.title = ReCase(property.key).camelCase;
        child.type = _getType(property.value['type'], property.key);
        child.className = _getClassName(property.value['type'], property.key);
        child.children = [];

        if (property.value['type'] == 'object') {
          child.children.addAll(getModel(property.value));
        } else if (property.value['type'] == 'array') {
          child.children.addAll(getModel(property.value['items']));
        }

        parent.add(child);
      }
    }

    return parent;
  }

  static String _getClassName(String type, String name) => type == 'object'
      ? ReCase(name).pascalCase
      : type == 'array' ? convertToSingular(ReCase(name).pascalCase) : null;

  static String _getType(String type, String name) => type == 'object'
      ? ReCase(name).pascalCase
      : type == 'array'
          ? 'List<${convertToSingular(ReCase(name).pascalCase)}>'
          : _typeMap[type];
}
