import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:agri_ai/main.dart';

void main() {
  testWidgets('AgriAI app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: AgriAIApp()),
    );
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
