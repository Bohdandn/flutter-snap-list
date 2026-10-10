# flutter_snap_list

[![CI/CD](https://github.com/Bohdandn/flutter-snap-list/actions/workflows/ci-cd.yml/badge.svg?branch=main)](https://github.com/Bohdandn/flutter-snap-list/actions/workflows/ci-cd.yml)

A mobile-focused Flutter widget for displaying a list of dynamically sized
items with snapping, scale, and opacity effects. It is designed for touch-first
interfaces where users browse one item at a time.

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

Once the Pages workflow has deployed, try the interactive
[web example](https://bohdandn.github.io/flutter-snap-list/), which demonstrates
long mobile-style cards, the empty state, and items taller than the viewport.
Navigate the cards by swiping up or down. On larger screens, the page frames
the example as a phone-sized preview.

To run the example locally:

```sh
cd example
flutter pub get
flutter run -d chrome
```

The web example is deployed to GitHub Pages when changes are pushed to `main`.
If Pages has not been enabled for the repository yet, select **GitHub Actions**
as the build and deployment source in the repository's Pages settings.

For a production example, see [lingoreads.com](https://lingoreads.com/) in the
**Weekly Plan** tab.

## License

MIT. See [LICENSE](LICENSE).
