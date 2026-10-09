import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snap_list/snap_list.dart';

void main() {
  testWidgets('renders an empty state without trying to snap', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SnapList<String>(items: [], itemBuilder: _buildItem),
      ),
    );

    await tester.pump();

    expect(find.text('No items to display.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('renders list items', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SnapList<String>(items: ['First', 'Second'], itemBuilder: _buildItem),
      ),
    );

    await tester.pump();

    expect(find.text('First'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Widget _buildItem(BuildContext context, String item) => Text(item);
