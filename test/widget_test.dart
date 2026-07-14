// Teste de widget do FloraScan.
//
// Verifica o CareDetailCard, um widget puro (sem dependencia de Firebase/DB),
// garantindo que titulo e valor sejam renderizados corretamente.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:florascan/widgets/care_detail_card.dart';

void main() {
  testWidgets('CareDetailCard exibe titulo e valor', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: CareDetailCard(
            icon: Icons.water_drop,
            iconColor: Colors.blue,
            title: 'Água:',
            value: 'Regar 2x por semana',
          ),
        ),
      ),
    );

    expect(find.text('Água:'), findsOneWidget);
    expect(find.text('Regar 2x por semana'), findsOneWidget);
    expect(find.byIcon(Icons.water_drop), findsOneWidget);
  });
}
