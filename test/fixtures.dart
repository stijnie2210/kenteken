import 'dart:convert';
import 'dart:io';

/// Reads a fixture from `test/fixtures`: real records from RDW open data.
List<Map<String, Object?>> fixture(String name) =>
    (jsonDecode(File('test/fixtures/$name.json').readAsStringSync())
            as List<Object?>)
        .cast();
