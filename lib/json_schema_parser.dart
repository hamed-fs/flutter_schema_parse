import 'package:meta/meta.dart';
import 'package:recase/recase.dart';
import 'package:dart_style/dart_style.dart';
import 'package:inflection2/inflection2.dart';

import 'package:flutter_schema_parse/schema_model.dart';

const String _objectType = 'object';
const String _arrayType = 'array';

class JsonSchemaParser {
  static List<StringBuffer> _result;

  static Map<String, String> _typeMap = <String, String>{
    'integer': 'int',
    'string': 'String',
    'number': 'num',
  };

  static String _getClassName({
    @required String type,
    @required String name,
  }) =>
      type == _objectType
          ? ReCase(name).pascalCase
          : type == _arrayType
              ? convertToSingular(ReCase(name).pascalCase)
              : null;

  static String _getObjectType({
    @required String type,
    @required String name,
  }) =>
      type == _objectType
          ? _getClassName(type: type, name: name)
          : type == _arrayType
              ? 'List<${_getClassName(type: type, name: name)}>'
              : _typeMap[type];

  static String _getClass({
    @required String className,
    @required List<SchemaModel> models,
  }) {
    final StringBuffer result = StringBuffer();

    result.write('class $className {');
    result.write(_buildClassContractor(className: className, models: models));
    result.write(_buildClassFromJson(className: className, models: models));
    result.write(_buildClassToJson(models: models));
    result.write('}');

    return DartFormatter().format(result.toString());
  }

  static StringBuffer _buildClassContractor({
    @required String className,
    @required List<SchemaModel> models,
  }) {
    final StringBuffer result = StringBuffer();

    for (SchemaModel model in models) {
      result.write('${model.type} ${model.title};');
    }

    result.write('$className({');

    for (SchemaModel model in models) {
      result.write('${model.title},');
    }

    result.write('});');

    return result;
  }

  static StringBuffer _buildClassFromJson({
    @required String className,
    @required List<SchemaModel> models,
  }) {
    final StringBuffer result = StringBuffer();

    result.write('$className.fromJson(Map<String, dynamic> json) {');

    for (SchemaModel model in models) {
      if (model.schemaType == _objectType) {
        result.write('''
          ${model.title} = json['${model.schemaTitle}'] != null
            ? ${model.className}.fromJson(json['${model.schemaTitle}'])
            : null;
        ''');
      } else if (model.schemaType == _arrayType) {
        result.write('''
          if (json['${model.schemaTitle}'] != null) {
            ${model.title} = List<${model.className}>();
            
            json['${model.schemaTitle}'].forEach((item) {
              ${model.className}.add(${model.className}.fromJson(item));
            });
          }
        ''');
      } else {
        result.write('''${model.title} = json['${model.schemaTitle}'];''');
      }
    }

    result.write('}');

    return result;
  }

  static StringBuffer _buildClassToJson({@required List<SchemaModel> models}) {
    final StringBuffer result = StringBuffer();

    result.write('Map<String, dynamic> toJson() {');
    result.write('final Map<String, dynamic> data = Map<String, dynamic>();');

    for (SchemaModel model in models) {
      if (model.schemaType == _objectType) {
        result.write('''
          if (${model.title} != null) {
            data['${model.schemaTitle}'] = ${model.title}.toJson();
          }
        ''');
      } else if (model.schemaType == _arrayType) {
        result.write('''
          if (${model.title} != null) {
            data['${model.schemaTitle}'] =
                ${model.title}.map((item) => item.toJson()).toList();
          }
        ''');
      } else {
        result.write('''data['${model.schemaTitle}'] = ${model.title};''');
      }
    }

    result.write('return data;');
    result.write('}');

    return result;
  }

  static List<SchemaModel> getModel({@required Map<String, dynamic> schema}) {
    final List<SchemaModel> parent = <SchemaModel>[];

    if (schema['properties'] != null) {
      for (dynamic entry in schema['properties'].entries) {
        final SchemaModel child = SchemaModel();

        child.className =
            _getClassName(type: entry.value['type'], name: entry.key);
        child.title = ReCase(entry.key).camelCase;
        child.type = _getObjectType(type: entry.value['type'], name: entry.key);
        child.schemaTitle = entry.key;
        child.schemaType = entry.value['type'];
        child.children = <SchemaModel>[];

        if (entry.value['type'] == _objectType) {
          child.children.addAll(getModel(schema: entry.value));
        } else if (entry.value['type'] == _arrayType) {
          child.children.addAll(getModel(schema: entry.value['items']));
        }

        parent.add(child);
      }
    }

    return parent;
  }

  static List<StringBuffer> getClasses({
    @required String className,
    @required List<SchemaModel> models,
    bool clearResult = true,
  }) {
    if (clearResult) {
      _result = <StringBuffer>[];
    }

    if (models.isNotEmpty) {
      _result.add(StringBuffer(JsonSchemaParser._getClass(
        className: className,
        models: models,
      )));
    }

    for (SchemaModel model in models) {
      getClasses(
        className: model.className,
        models: model.children,
        clearResult: false,
      );
    }

    return _result;
  }
}
