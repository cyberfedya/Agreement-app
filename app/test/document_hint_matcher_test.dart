import 'package:flutter_test/flutter_test.dart';

import 'package:app/features/questionnaire/presentation/document_hint_matcher.dart';

void main() {
  group('DocumentHintMatcher.categoryFor', () {
    test('matches vehicle document-dependent fields', () {
      expect(DocumentHintMatcher.categoryFor('Какой VIN автомобиля?'), DocumentHintCategory.vehicle);
      expect(DocumentHintMatcher.categoryFor('Укажите номер двигателя'), DocumentHintCategory.vehicle);
      expect(DocumentHintMatcher.categoryFor('Номер кузова автомобиля?'), DocumentHintCategory.vehicle);
      expect(DocumentHintMatcher.categoryFor('Номер шасси?'), DocumentHintCategory.vehicle);
      expect(DocumentHintMatcher.categoryFor('Есть ли особые отметки?'), DocumentHintCategory.vehicle);
    });

    test('does not match fields the owner knows from memory (plate, brand, price, date)', () {
      expect(DocumentHintMatcher.categoryFor('Укажите государственный номер автомобиля'), isNull);
      expect(DocumentHintMatcher.categoryFor('Какая марка и модель?'), isNull);
      expect(DocumentHintMatcher.categoryFor('Какая цена?'), isNull);
      expect(DocumentHintMatcher.categoryFor('Когда автомобиль будет передан?'), isNull);
      expect(DocumentHintMatcher.categoryFor('Как будет произведена оплата?'), isNull);
    });

    test('matches real estate document-dependent fields', () {
      expect(DocumentHintMatcher.categoryFor('Кадастровый номер?'), DocumentHintCategory.realEstate);
      expect(DocumentHintMatcher.categoryFor('Свидетельство о праве собственности?'), DocumentHintCategory.realEstate);
    });

    test('matches company/business registration fields', () {
      expect(DocumentHintMatcher.categoryFor('Какой ИНН компании?'), DocumentHintCategory.business);
      expect(DocumentHintMatcher.categoryFor('Свидетельство о регистрации?'), DocumentHintCategory.business);
    });

    test('matches inheritance document fields', () {
      expect(DocumentHintMatcher.categoryFor('Номер свидетельства о смерти?'), DocumentHintCategory.inheritance);
      expect(
        DocumentHintMatcher.categoryFor('Свидетельство о праве на наследство?'),
        DocumentHintCategory.inheritance,
      );
    });

    test('matches court document fields', () {
      expect(DocumentHintMatcher.categoryFor('Какое решение суда?'), DocumentHintCategory.court);
      expect(DocumentHintMatcher.categoryFor('Номер дела?'), DocumentHintCategory.court);
    });

    test('matches loan document fields', () {
      expect(DocumentHintMatcher.categoryFor('Номер договора займа?'), DocumentHintCategory.loan);
    });

    test('matches service agreement document fields', () {
      expect(DocumentHintMatcher.categoryFor('Есть ли техническое задание?'), DocumentHintCategory.service);
      expect(DocumentHintMatcher.categoryFor('Укажите смету'), DocumentHintCategory.service);
    });
  });
}
