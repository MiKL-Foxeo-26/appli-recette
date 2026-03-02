// ignore_for_file: prefer_const_constructors

import 'package:appli_recette/core/platform/url_params_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UrlParamsService', () {
    late UrlParamsService service;

    setUp(() {
      service = const UrlParamsService();
    });

    group('extractInvitationCode (mobile stub)', () {
      // Sur mobile (stub), la méthode retourne toujours null.
      test('retourne null sur mobile (stub)', () {
        // Le stub mobile est utilisé en environnement de test (pas dart:html)
        expect(service.extractInvitationCode(), isNull);
      });
    });
  });
}
