import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_snap_list_example/main.dart';

void main() {
  testWidgets('shows cards and the current item indicator by default', (tester) async {
    await tester.pumpWidget(const SnapListExampleApp());
    await tester.pumpAndSettle();

    expect(find.text('A little room to focus'), findsOneWidget);
    expect(find.text('Make a cup of tea and take a proper break.'), findsOneWidget);
    expect(find.text('Swipe up or down on the cards to navigate.'), findsOneWidget);
    expect(find.byKey(const Key('snap_scroll')), findsOneWidget);
    expect(find.byKey(const Key('current-item-indicator')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('supports mouse dragging without showing scrollbars', (tester) async {
    await tester.pumpWidget(const SnapListExampleApp());
    await tester.pumpAndSettle();

    final mouseRegion = tester.widget<MouseRegion>(
      find
          .ancestor(
            of: find.byKey(const Key('snap_scroll')),
            matching: find.byType(MouseRegion),
          )
          .first,
    );
    final scrollBehavior = ScrollConfiguration.of(
      tester.element(find.byKey(const Key('snap_scroll'))),
    );
    expect(mouseRegion.cursor, SystemMouseCursors.click);
    expect(scrollBehavior.dragDevices, contains(PointerDeviceKind.mouse));
    expect(find.byType(Scrollbar), findsNothing);
  });

  testWidgets('uses a fixed phone-sized preview on wider screens', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(900, 900);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const SnapListExampleApp());
    await tester.pumpAndSettle();

    final previewSize = tester.getSize(find.byKey(const Key('mobile-preview')));
    expect(previewSize, const Size(390, 844));
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows the built-in empty state', (tester) async {
    await tester.pumpWidget(const SnapListExampleApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Empty'));
    await tester.pumpAndSettle();

    expect(find.text('No items to display.'), findsOneWidget);
    expect(find.byKey(const Key('current-item-indicator')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows a tall item example', (tester) async {
    await tester.pumpWidget(const SnapListExampleApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Tall card'));
    await tester.pumpAndSettle();

    expect(find.text('A long read, still in focus'), findsOneWidget);
    expect(
      find.textContaining('Keep swiping through this card'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
