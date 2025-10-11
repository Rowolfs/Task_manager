import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager/widgets/login.dart';

void main() {
  testWidgets('LoginSheet отображает кнопку Войти', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: LoginSheet())));
    expect(find.text('Войти'), findsOneWidget);
  });

  testWidgets('Валидация логина', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: LoginSheet())));
    await tester.tap(find.text('Войти'));
    await tester.pump(); // обновляем UI
    expect(find.text('Введите логин'), findsOneWidget);
  });
}
