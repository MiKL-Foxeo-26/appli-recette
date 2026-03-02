// ignore_for_file: prefer_const_constructors

import 'package:appli_recette/core/household/invitation_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('InvitationService', () {
    late InvitationService service;

    setUp(() {
      service = const InvitationService();
    });

    group('generateInvitationLink', () {
      test('contient le code dans le query param', () {
        final link = service.generateInvitationLink('123456');
        expect(link, contains('code=123456'));
      });

      test('contient /join dans le chemin', () {
        final link = service.generateInvitationLink('654321');
        expect(link, contains('/join'));
      });

      test('commence par https://', () {
        final link = service.generateInvitationLink('123456');
        expect(link, startsWith('https://'));
      });

      test('est une URL valide parseable', () {
        final link = service.generateInvitationLink('999999');
        final uri = Uri.parse(link);
        expect(uri.queryParameters['code'], equals('999999'));
      });

      test('code différent → liens différents', () {
        final link1 = service.generateInvitationLink('111111');
        final link2 = service.generateInvitationLink('222222');
        expect(link1, isNot(equals(link2)));
      });
    });
  });
}
