import 'package:flutter/material.dart';
import 'package:flutter_snap_list/flutter_snap_list.dart';

void main() {
  runApp(const SnapListExampleApp());
}

enum DemoMode { cards, empty, tallCard }

const _mobilePreviewSize = Size(390, 844);

const _cards = [
  DemoCard(
    title: 'A little room to focus',
    category: '01  /  EVERYDAY',
    description: 'A calmer daily routine, one small step at a time.',
    icon: Icons.center_focus_strong_rounded,
    color: Color(0xFFDDEBE2),
    highlights: [
      'Make a cup of tea and take a proper break.',
      'Step outside for a few minutes of fresh air.',
      'Write down one thing you want to remember.',
    ],
  ),
  DemoCard(
    title: 'Content can be any size',
    category: '02  /  FLEXIBLE',
    description: 'A little reading plan with room for notes and the occasional longer thought.',
    icon: Icons.fit_screen_rounded,
    color: Color(0xFFF1E5D5),
    highlights: [
      'Start with a short chapter before breakfast.',
      'Save a favorite passage to come back to later.',
      'Finish the day with a few quiet pages.',
    ],
  ),
  DemoCard(
    title: 'A softer way to browse',
    category: '03  /  MOTION',
    description: 'A simple check-in to make space for what matters during a busy day.',
    icon: Icons.animation_rounded,
    color: Color(0xFFE6E1F0),
    highlights: [
      'Pause for a slow breath between meetings.',
      'Put your phone away while you have lunch.',
      'Take the scenic route on your walk home.',
    ],
  ),
  DemoCard(
    title: 'Your content, your style',
    category: '04  /  CUSTOM',
    description: 'Keep a few gentle reminders close by, ready whenever you need them.',
    icon: Icons.widgets_rounded,
    color: Color(0xFFF0E4E3),
    highlights: [
      'Drink some water before your next coffee.',
      'Send a message to someone you have been thinking of.',
      'Call it a day when you have done enough.',
    ],
  ),
];

const _tallCards = [
  DemoCard(
    title: 'A long read, still in focus',
    category: '01  /  TALL ITEM',
    description: 'SnapList also supports items taller than the viewport. Keep swiping through this card; it will stay focused until you reach its end.',
    icon: Icons.menu_book_rounded,
    color: Color(0xFFDDEBE2),
    isTall: true,
  ),
  DemoCard(
    title: 'On to the next one',
    category: '02  /  NEXT ITEM',
    description: 'The next item becomes the focus after the long card passes.',
    icon: Icons.arrow_downward_rounded,
    color: Color(0xFFF1E5D5),
  ),
];

class SnapListExampleApp extends StatelessWidget {
  const SnapListExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    const ink = Color(0xFF20332D);

    return MaterialApp(
      title: 'SnapList — Flutter example',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF456B59),
          surface: const Color(0xFFF8F7F3),
        ),
        scaffoldBackgroundColor: const Color(0xFFECEEE9),
        useMaterial3: true,
        textTheme: const TextTheme(
          headlineMedium: TextStyle(
            color: ink,
            fontSize: 34,
            fontWeight: FontWeight.w700,
            height: 1.1,
            letterSpacing: -1.1,
          ),
          bodyLarge: TextStyle(color: Color(0xFF68756E), height: 1.5),
        ),
      ),
      home: const SnapListExamplePage(),
    );
  }
}

class SnapListExamplePage extends StatefulWidget {
  const SnapListExamplePage({super.key});

  @override
  State<SnapListExamplePage> createState() => _SnapListExamplePageState();
}

class _SnapListExamplePageState extends State<SnapListExamplePage> {
  DemoMode _mode = DemoMode.cards;
  int _currentIndex = 0;

  List<DemoCard> get _items => switch (_mode) {
        DemoMode.cards => _cards,
        DemoMode.empty => const [],
        DemoMode.tallCard => _tallCards,
      };

  String get _modeDescription => switch (_mode) {
        DemoMode.cards => 'Different content heights, with scale and fade effects.',
        DemoMode.empty => 'The built-in empty state shown when there are no items.',
        DemoMode.tallCard => 'Swipe to reveal the rest of a tall item.',
      };

  @override
  Widget build(BuildContext context) {
    final items = _items;
    final isDesktopPreview = MediaQuery.sizeOf(context).width > 520;

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Center(
                child: SizedBox(
                  key: const Key('mobile-preview'),
                  width: _mobilePreviewSize.width,
                  height: _mobilePreviewSize.height,
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F7F3),
                      borderRadius: BorderRadius.circular(isDesktopPreview ? 32 : 0),
                      border: isDesktopPreview ? Border.all(color: const Color(0xFFD8DDD6)) : null,
                      boxShadow: isDesktopPreview
                          ? const [
                              BoxShadow(
                                color: Color(0x180F241B),
                                blurRadius: 36,
                                offset: Offset(0, 16),
                              ),
                            ]
                          : null,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _BrandHeader(),
                          const SizedBox(height: 24),
                          Text(
                            'A list with a little rhythm.',
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'A mobile-first list with long, flexible cards and a satisfying snap.',
                            style: TextStyle(color: Color(0xFF68756E), height: 1.5),
                          ),
                          const SizedBox(height: 20),
                          _ModePicker(
                            mode: _mode,
                            onChanged: (mode) {
                              setState(() {
                                _mode = mode;
                                _currentIndex = 0;
                              });
                            },
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _modeDescription,
                                  style: const TextStyle(color: Color(0xFF68756E), fontSize: 13),
                                ),
                              ),
                              if (items.isNotEmpty)
                                Text(
                                  '${(_currentIndex + 1).toString().padLeft(2, '0')} / ${items.length.toString().padLeft(2, '0')}',
                                  key: const Key('current-item-indicator'),
                                  style: const TextStyle(
                                    color: Color(0xFF456B59),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(24),
                              child: ColoredBox(
                                color: const Color(0xFFECEEE9),
                                child: SnapList<DemoCard>(
                                  key: ValueKey(_mode),
                                  items: items,
                                  spacing: 20,
                                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
                                  minScale: 0.9,
                                  maxScale: 1,
                                  minOpacity: 0.45,
                                  maxOpacity: 1,
                                  itemBuilder: (context, card) => _DemoCardView(card: card),
                                  onCurrentItemChanged: (index) {
                                    if (mounted && _currentIndex != index) {
                                      setState(() => _currentIndex = index);
                                    }
                                  },
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Row(
                            children: [
                              Icon(Icons.touch_app_rounded, size: 16, color: Color(0xFF748078)),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Swipe up or down on the cards to navigate.',
                                  style: TextStyle(
                                    color: Color(0xFF748078),
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              Text(
                                'MOBILE FIRST',
                                style: TextStyle(
                                  color: Color(0xFF748078),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BrandHeader extends StatelessWidget {
  const _BrandHeader();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Icon(Icons.view_carousel_rounded, color: Color(0xFF456B59), size: 25),
        SizedBox(width: 9),
        Text(
          'SNAPLIST',
          style: TextStyle(
            color: Color(0xFF20332D),
            fontSize: 13,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.5,
          ),
        ),
        SizedBox(width: 10),
        Text('·', style: TextStyle(color: Color(0xFF9AA39D))),
        SizedBox(width: 10),
        Text(
          'MOBILE FIRST',
          style: TextStyle(
            color: Color(0xFF748078),
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }
}

class _ModePicker extends StatelessWidget {
  const _ModePicker({required this.mode, required this.onChanged});

  final DemoMode mode;
  final ValueChanged<DemoMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<DemoMode>(
      showSelectedIcon: false,
      segments: const [
        ButtonSegment(value: DemoMode.cards, label: Text('Cards')),
        ButtonSegment(value: DemoMode.empty, label: Text('Empty')),
        ButtonSegment(value: DemoMode.tallCard, label: Text('Tall card')),
      ],
      selected: {mode},
      onSelectionChanged: (selection) => onChanged(selection.first),
    );
  }
}

class _DemoCardView extends StatelessWidget {
  const _DemoCardView({required this.card});

  final DemoCard card;

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: const EdgeInsets.all(30),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(card.icon, size: 30, color: const Color(0xFF456B59)),
          const SizedBox(height: 24),
          Text(
            card.category,
            style: const TextStyle(
              color: Color(0xFF62776A),
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            card.title,
            style: const TextStyle(
              color: Color(0xFF20332D),
              fontSize: 27,
              fontWeight: FontWeight.w700,
              height: 1.2,
              letterSpacing: -0.6,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            card.description,
            style: const TextStyle(color: Color(0xFF52635A), fontSize: 15, height: 1.6),
          ),
          if (card.highlights.isNotEmpty) ...[
            const SizedBox(height: 24),
            for (var index = 0; index < card.highlights.length; index++) ...[
              _HighlightRow(
                number: '${(index + 1).toString().padLeft(2, '0')}',
                text: card.highlights[index],
              ),
              if (index < card.highlights.length - 1) const Divider(height: 24, color: Color(0x8062776A)),
            ],
          ],
          if (card.isTall) ...[
            const SizedBox(height: 40),
            const Divider(color: Color(0x8062776A)),
            const SizedBox(height: 24),
            for (var i = 0; i < 3; i++) ...[
              const Text(
                'A long item does not have to be cut off at the edge of the screen. '
                'Keep swiping to explore its content, then snap to the next item '
                'when you are ready.',
                style: TextStyle(color: Color(0xFF52635A), fontSize: 15, height: 1.7),
              ),
              if (i < 2) const SizedBox(height: 22),
            ],
          ],
        ],
      ),
    );

    return Container(
      constraints: BoxConstraints(minHeight: card.isTall ? 760 : 390),
      decoration: BoxDecoration(color: card.color, borderRadius: BorderRadius.circular(20)),
      child: content,
    );
  }
}

class DemoCard {
  const DemoCard({
    required this.title,
    required this.category,
    required this.description,
    required this.icon,
    required this.color,
    this.highlights = const [],
    this.isTall = false,
  });

  final String title;
  final String category;
  final String description;
  final IconData icon;
  final Color color;
  final List<String> highlights;
  final bool isTall;
}

class _HighlightRow extends StatelessWidget {
  const _HighlightRow({required this.number, required this.text});

  final String number;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          number,
          style: const TextStyle(
            color: Color(0xFF718477),
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: Color(0xFF52635A),
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }
}
