// Copyright 2026 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:yaml/yaml.dart';

Map<Object?, Object?> _map(Object? value) {
  if (value is Map<Object?, Object?>) return value;
  throw const FormatException('Expected a mapping in the source manifest.');
}

void main() {
  final errors = <String>[];
  final fixedSha = RegExp(r'^[0-9a-f]{40}$');
  final Map<Object?, Object?> refs = _map(
    jsonDecode(
      File('docs/compatibility/fork-references.json').readAsStringSync(),
    ),
  );
  final Map<Object?, Object?> root =
      _map(loadYaml(File('pubspec.yaml').readAsStringSync()));
  final Map<Object?, Object?> packages = _map(
    _map(loadYaml(File('pubspec.lock').readAsStringSync()))['packages'],
  );
  final Map<Object?, Object?> fvm =
      _map(jsonDecode(File('.fvmrc').readAsStringSync()));
  if (fvm['flutter'] != '3.27.4' || !Platform.version.startsWith('3.6.2 ')) {
    errors.add('Use the pinned Flutter 3.27.4 / Dart 3.6.2 toolchain.');
  }
  if (refs['status'] != 'delivery') {
    errors.add('Fork references are still a development snapshot.');
  }
  final workspace = root['workspace'] as List<Object?>;
  for (final Object? member in ['.', ...workspace]) {
    if (File('$member/pubspec_overrides.yaml').existsSync()) {
      errors.add('$member/pubspec_overrides.yaml must be removed.');
    }
  }
  for (final MapEntry<Object?, Object?> entry in packages.entries) {
    final Map<Object?, Object?> package = _map(entry.value);
    if (package['source'] == 'path') {
      errors.add('${entry.key} still resolves to a local path.');
    }
    if (package['source'] == 'hosted') {
      final Map<Object?, Object?> description = _map(package['description']);
      if (description['url'] != 'https://pub.dev') {
        errors.add('${entry.key} uses a host-specific package registry.');
      }
    }
    if (package['source'] == 'git') {
      final Map<Object?, Object?> description = _map(package['description']);
      final Object? ref = description['ref'];
      if (ref is! String || !fixedSha.hasMatch(ref)) {
        errors.add('${entry.key} uses a movable Git ref.');
      } else if (description['resolved-ref'] != ref) {
        errors.add('${entry.key} resolves to a different commit.');
      }
    }
  }
  for (final value in refs['repositories'] as List<Object?>) {
    final Map<Object?, Object?> repo = _map(value);
    final Object? sha = repo['commit'];
    if (sha is! String || !fixedSha.hasMatch(sha)) {
      errors.add('${repo['name']} has no approved delivery commit.');
      continue;
    }
    for (final value in repo['packages'] as List<Object?>) {
      final Map<Object?, Object?> declared = _map(value);
      final Object? name = declared['name'];
      final Object? locked = packages[name];
      if (locked == null || _map(locked)['source'] != 'git') {
        errors.add('$name must resolve from its compatibility fork.');
        continue;
      }
      final Map<Object?, Object?> source = _map(_map(locked)['description']);
      if (source['url'] != 'https://github.com/${repo['repository']}.git' ||
          source['ref'] != sha ||
          source['resolved-ref'] != sha ||
          source['path'] != declared['path']) {
        errors.add('$name does not match the fixed fork source manifest.');
      }
    }
  }
  if (errors.isNotEmpty) {
    for (final error in errors) {
      stderr.writeln(error);
    }
    exitCode = 1;
  } else {
    stdout.writeln('All modified dependency sources use fixed fork commits.');
  }
}
