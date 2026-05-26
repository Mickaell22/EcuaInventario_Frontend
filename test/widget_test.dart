import 'package:facilito/app/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('smoke test — app arranca sin errores', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: FacilitoApp()));
    await tester.pump();
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
