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
  static String _getClassName(String type, String name) => type == 'object'
      ? ReCase(name).pascalCase
      : type == 'array' ? convertToSingular(ReCase(name).pascalCase) : null;

  static String _getObjectType(String type, String name) => type == 'object'
      ? _getClassName(type, name)
      : type == 'array' ? 'List<${_getClassName(type, name)}>' : _typeMap[type];

  static List<Model> getModel(Map<String, dynamic> schema) {
    List<Model> parent = [];

    if (schema['properties'] != null) {
      for (var property in schema['properties'].entries) {
        Model child = Model();

        child.title = ReCase(property.key).camelCase;
        child.type = _getObjectType(property.value['type'], property.key);
        child.attributeTitle = property.key;
        child.attributeType = property.value['type'];
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

  static String getClasses(String className, List<Model> models) {
    StringBuffer result = StringBuffer();

    result.write('class $className {');
    result.write(_buildContractor(className, models));
    result.write(_buildFromJson(className, models));
    result.write(_buildToJson(result, models));
    result.write('}');

    return DartFormatter().format(result.toString());
  }

  static StringBuffer _buildContractor(String className, List<Model> models) {
    StringBuffer result = StringBuffer();

    for (Model model in models) {
      result.write('${model.type} ${model.title};');
    }

    result.write('$className({');

    for (Model model in models) {
      result.write('${model.title},');
    }

    result.write('});');

    return result;
  }

  static StringBuffer _buildFromJson(String className, List<Model> models) {
    StringBuffer result = StringBuffer();

    result.write('$className.fromJson(Map<String, dynamic> json) {');
    for (Model model in models) {
      if (model.attributeType == 'object') {
        result.write('''
          ${model.title} = json['${model.attributeTitle}'] != null
            ? ${model.className}.fromJson(json['${model.attributeTitle}'])
            : null;
        ''');
      } else if (model.attributeType == 'array') {
        result.write('''
          if (json['${model.attributeTitle}'] != null) {
            ${model.title} = List<${model.className}>();
            
            json['${model.attributeTitle}'].forEach((item) {
              ${model.className}.add(${model.className}.fromJson(item));
            });
          }
        ''');
      } else {
        result.write('''${model.title} = json['${model.attributeTitle}'];''');
      }
    }

    result.write('}');

    return result;
  }

  static StringBuffer _buildToJson(StringBuffer result, List<Model> models) {
    StringBuffer result = StringBuffer();

    result.write('Map<String, dynamic> toJson() {');
    result.write('final Map<String, dynamic> data = Map<String, dynamic>();');
    for (Model model in models) {
      if (model.attributeType == 'object') {
        result.write('''
          if (${model.title} != null) {
            data['${model.attributeTitle}'] = ${model.title}.toJson();
          }
        ''');
      } else if (model.attributeType == 'array') {
        result.write('''
          if (${model.title} != null) {
            data['${model.attributeTitle}'] =
                ${model.title}.map((item) => item.toJson()).toList();
          }
        ''');
      } else {
        result.write('''data['${model.attributeTitle}'] = ${model.title};''');
      }
    }

    result.write('return data;');

    result.write('}');

    return result;
  }

  static void getAllClasses(String className, List<Model> models) {
    if (models.length > 0) {
      print(JsonSchemaParser.getClasses(className, models));
    }

    for (Model model in models) {
      getAllClasses(model.className, model.children);
    }
  }
}
