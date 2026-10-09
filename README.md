# flutter_snap_list

[![CI](https://github.com/Bohdandn/flutter-snap-list/actions/workflows/ci.yml/badge.svg?branch=master)](https://github.com/Bohdandn/flutter-snap-list/actions/workflows/ci.yml)

A Flutter widget for displaying a list of dynamically sized items with snapping,
scale, and opacity effects.

<img src="images/example.png" alt="Example" width="500">

## Installation

Add `flutter_snap_list` to your `pubspec.yaml`:

```yaml
dependencies:
  flutter_snap_list: ^0.1.0
```

## Usage

```dart
SnapList<String>(
  items: const ['First', 'Second', 'Third'],
  itemBuilder: (context, item) => Card(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Text(item),
    ),
  ),
  onCurrentItemChanged: (index) {
    debugPrint('Current item: $index');
  },
)
```

`SnapList` accepts dynamically sized items. Use `topOverlayHeight` and
`bottomOverlayHeight` to account for content that overlaps the scroll viewport.

For programmatic scrolling, pass an `ItemScrollController` through
`itemScrollController` from
[`scrollable_positioned_list`](https://pub.dev/packages/scrollable_positioned_list).

## Example

See it in action at [lingoreads.com](https://lingoreads.com/) in the **Weekly Plan** tab.

## License

MIT. See [LICENSE](LICENSE).
