import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_snap_list/flutter_snap_list.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

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

  testWidgets('initialIndex and initialAlignment position and report the initial item', (tester) async {
    final changedIndexes = <int>[];

    await tester.pumpWidget(
      MaterialApp(
        home: SnapList<int>(
          items: const [0, 1, 2, 3],
          itemBuilder: _buildSizedItem,
          initialIndex: 2,
          initialAlignment: 0.25,
          minScale: 1,
          maxScale: 1,
          onCurrentItemChanged: changedIndexes.add,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final viewport = tester.getRect(find.byKey(const Key('snap_scroll')));
    final selectedItem = tester.getRect(find.byKey(const ValueKey('sized-item-2')));
    expect(changedIndexes, contains(2));
    expect(selectedItem.top, closeTo(viewport.top + viewport.height * 0.25, 1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('scale and opacity settings affect focused item rendering', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SnapList<int>(
          items: const [0, 1, 2],
          itemBuilder: _buildSizedItem,
          initialIndex: 1,
          initialAlignment: 0.4166667,
          minScale: 0.5,
          maxScale: 0.5,
          minOpacity: 0.2,
          maxOpacity: 0.2,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 100));

    final firstItem = find.byKey(const ValueKey('sized-item-1'));
    final firstTransform = tester.widget<Transform>(
      find.ancestor(
        of: firstItem,
        matching: find.byWidgetPredicate(
          (widget) => widget is Transform && widget.transform.entry(0, 0) != 1,
        ),
      ),
    );
    final firstOpacity = tester.widget<Opacity>(
      find.ancestor(
        of: firstItem,
        matching: find.byWidgetPredicate((widget) => widget is Opacity && widget.opacity != 1),
      ),
    );
    expect(firstTransform.transform.entry(0, 0), closeTo(0.5, 0.01));
    expect(firstOpacity.opacity, closeTo(0.2, 0.01));

    await tester.pumpWidget(
      MaterialApp(
        home: SnapList<int>(
          items: const [0, 1, 2],
          itemBuilder: _buildSizedItem,
          initialIndex: 1,
          initialAlignment: 0.4166667,
          minScale: 1.25,
          maxScale: 1.25,
          minOpacity: 0.9,
          maxOpacity: 0.9,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final updatedTransform = tester.widget<Transform>(
      find.ancestor(
        of: firstItem,
        matching: find.byWidgetPredicate(
          (widget) => widget is Transform && widget.transform.entry(0, 0) != 1,
        ),
      ),
    );
    final updatedOpacity = tester.widget<Opacity>(
      find.ancestor(
        of: firstItem,
        matching: find.byWidgetPredicate((widget) => widget is Opacity && widget.opacity != 1),
      ),
    );
    expect(updatedTransform.transform.entry(0, 0), closeTo(1.25, 0.01));
    expect(updatedOpacity.opacity, closeTo(0.9, 0.01));
    expect(tester.takeException(), isNull);
  });

  testWidgets('spacing and padding affect list item positions', (tester) async {
    final controller = ItemScrollController();

    await tester.pumpWidget(
      MaterialApp(
        home: SnapList<int>(
          items: const [0, 1],
          itemBuilder: _buildSizedItem,
          itemScrollController: controller,
          initialAlignment: 0,
          minScale: 1,
          maxScale: 1,
          padding: const EdgeInsets.only(top: 20, bottom: 30),
          spacing: 36,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final viewport = tester.getRect(find.byKey(const Key('snap_scroll')));
    final firstItem = find.byKey(const ValueKey('sized-item-0'));
    expect(tester.getTopLeft(firstItem).dy, closeTo(viewport.top + 20, 1));
    controller.jumpTo(index: 0, alignment: 0);
    await tester.pumpAndSettle();
    final firstItemBottom = tester.getBottomRight(firstItem).dy;
    final secondItemTop = tester.getTopLeft(find.byKey(const ValueKey('sized-item-1'))).dy;
    expect(secondItemTop - firstItemBottom, closeTo(36, 1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('physics can disable user-driven scrolling', (tester) async {
    final changedIndexes = <int>[];

    await tester.pumpWidget(
      MaterialApp(
        home: SnapList<int>(
          items: const [0, 1, 2],
          itemBuilder: _buildSizedItem,
          physics: const NeverScrollableScrollPhysics(),
          onCurrentItemChanged: changedIndexes.add,
        ),
      ),
    );
    await tester.pumpAndSettle();
    final initialItemTop = tester.getTopLeft(find.byKey(const ValueKey('sized-item-0'))).dy;

    await tester.drag(find.byKey(const Key('snap_scroll')), const Offset(0, -400));
    await tester.pumpAndSettle();

    expect(changedIndexes, [0]);
    expect(tester.getTopLeft(find.byKey(const ValueKey('sized-item-0'))).dy, initialItemTop);
    expect(tester.takeException(), isNull);
  });

  testWidgets('repaintThrottleDuration limits how often item effects update', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SnapList<int>(
          items: const [0, 1, 2],
          itemBuilder: _buildSizedItem,
          initialAlignment: 0.08,
          repaintThrottleDuration: const Duration(days: 1),
          minScale: 0.5,
          maxScale: 1.25,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final firstItem = find.byKey(const ValueKey('sized-item-0'));
    final initialScale = tester.widget<Transform>(find.ancestor(of: firstItem, matching: find.byType(Transform)).first).transform.getMaxScaleOnAxis();

    await tester.timedDrag(
      find.byKey(const Key('snap_scroll')),
      const Offset(0, -100),
      const Duration(seconds: 1),
    );
    await tester.pumpAndSettle();

    final scaleAfterDrag = tester.widget<Transform>(find.ancestor(of: firstItem, matching: find.byType(Transform)).first).transform.getMaxScaleOnAxis();
    expect(scaleAfterDrag, initialScale);
    expect(tester.takeException(), isNull);
  });

  testWidgets('remains stable during drag gestures', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SnapList<String>(
          items: ['First', 'Second', 'Third', 'Fourth'],
          itemBuilder: _buildItem,
        ),
      ),
    );

    await tester.pumpAndSettle();
    await tester.drag(find.byKey(const Key('snap_scroll')), const Offset(0, -500));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('snap_scroll')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('keeps top and bottom overlays at the viewport edges while scrolling', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Stack(
            key: const Key('overlay-stack'),
            children: [
              Positioned.fill(
                child: SnapList<int>(
                  items: const [0, 1, 2, 3],
                  itemBuilder: _buildOverlayItem,
                  topOverlayHeight: 64,
                  bottomOverlayHeight: 72,
                ),
              ),
              const Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 64,
                child: ColoredBox(key: Key('top-overlay'), color: Colors.red),
              ),
              const Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: 72,
                child: ColoredBox(key: Key('bottom-overlay'), color: Colors.blue),
              ),
            ],
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    await tester.drag(find.byKey(const Key('snap_scroll')), const Offset(0, -400));
    await tester.pumpAndSettle();

    final stackTop = tester.getTopLeft(find.byKey(const Key('overlay-stack'))).dy;
    final stackBottom = stackTop + tester.getSize(find.byKey(const Key('overlay-stack'))).height;
    expect(tester.getTopLeft(find.byKey(const Key('top-overlay'))).dy, stackTop);
    expect(tester.getBottomRight(find.byKey(const Key('bottom-overlay'))).dy, stackBottom);
    expect(tester.takeException(), isNull);
  });

  testWidgets('does not snap past a long item until its bottom is passed', (tester) async {
    final changedIndexes = <int>[];

    await tester.pumpWidget(
      MaterialApp(
        home: SnapList<int>(
          items: const [0, 1, 2],
          itemBuilder: _buildLongItem,
          topOverlayHeight: 64,
          bottomOverlayHeight: 72,
          onCurrentItemChanged: changedIndexes.add,
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(changedIndexes.last, 0);
    final viewportBottom = tester.getBottomRight(find.byKey(const Key('snap_scroll'))).dy;
    expect(tester.getBottomRight(find.byKey(const ValueKey('long-item-0'))).dy, greaterThan(viewportBottom));

    await tester.timedDrag(
      find.byKey(const Key('snap_scroll')),
      const Offset(0, -400),
      const Duration(seconds: 1),
    );
    await tester.pumpAndSettle();
    expect(changedIndexes.last, 0);

    await tester.timedDrag(
      find.byKey(const Key('snap_scroll')),
      const Offset(0, -400),
      const Duration(seconds: 1),
    );
    await tester.pumpAndSettle();
    expect(changedIndexes.last, 1);
    expect(tester.getBottomRight(find.byKey(const ValueKey('long-item-0'))).dy, lessThan(viewportBottom));
    expect(tester.takeException(), isNull);
  });

  testWidgets('supports external item scroll controller without failing', (tester) async {
    final controller = ItemScrollController();

    await tester.pumpWidget(
      MaterialApp(
        home: SnapList<String>(
          items: ['First', 'Second', 'Third'],
          itemBuilder: _buildItem,
          itemScrollController: controller,
        ),
      ),
    );

    await tester.pumpAndSettle();
    controller.scrollTo(index: 2, duration: const Duration(milliseconds: 100), alignment: 0.5);
    await tester.pumpAndSettle();

    expect(find.text('Third'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('snapAnimationDuration controls the snap animation', (tester) async {
    final changedIndexes = <int>[];

    await tester.pumpWidget(
      MaterialApp(
        home: SnapList<int>(
          items: const [0, 1, 2, 3],
          itemBuilder: _buildTallSnapItem,
          initialIndex: 1,
          initialAlignment: 0.5,
          snapAnimationDuration: const Duration(seconds: 1),
          onCurrentItemChanged: changedIndexes.add,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.timedDrag(
      find.byKey(const Key('snap_scroll')),
      const Offset(0, -500),
      const Duration(seconds: 1),
    );
    await tester.pump();
    expect(changedIndexes.last, 2);
    final targetItem = find.byKey(const ValueKey('tall-snap-item-2'));
    final targetItemTopDuringSnap = tester.getTopLeft(targetItem).dy;

    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.getTopLeft(targetItem).dy, isNot(targetItemTopDuringSnap));
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(targetItem).dy, closeTo(150, 10));
    expect(tester.takeException(), isNull);
  });
}

Widget _buildItem(BuildContext context, String item) => Text(item);

Widget _buildOverlayItem(BuildContext context, int item) => SizedBox(height: 180, child: Text('Item $item'));

Widget _buildSizedItem(BuildContext context, int item) => SizedBox(key: ValueKey('sized-item-$item'), height: 100, child: Text('Item $item'));

Widget _buildTallSnapItem(BuildContext context, int item) => SizedBox(key: ValueKey('tall-snap-item-$item'), height: 300, child: Text('Item $item'));

Widget _buildLongItem(BuildContext context, int item) => SizedBox(key: ValueKey('long-item-$item'), height: item == 0 ? 1200 : 180, child: Text('Item $item'));
