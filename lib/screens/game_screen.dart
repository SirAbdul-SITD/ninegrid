import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/puzzle.dart';
import '../painters/board_painter.dart';
import '../services/palette.dart';
import '../services/progress_service.dart';
import '../services/settings_service.dart';
import '../services/audio_manager.dart';

class GameScreen extends StatefulWidget {
  final Puzzle puzzle;
  final AudioManager audio;
  final VoidCallback? onNext;
  const GameScreen({
    super.key,
    required this.puzzle,
    required this.audio,
    this.onNext,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late List<List<int>> state;
  int? selR, selC;
  bool won = false;
  int moves = 0;

  @override
  void initState() {
    super.initState();
    state = List.generate(9, (_) => List.filled(9, 0));
  }

  void _haptic() {
    if (context.read<SettingsService>().haptics) {
      HapticFeedback.selectionClick();
    }
  }

  void _selectCell(int r, int c) {
    if (won) return;
    if (widget.puzzle.givens[r][c] != 0) return; // givens are fixed
    setState(() {
      selR = r;
      selC = c;
    });
    widget.audio.tap();
  }

  void _enterValue(int value) {
    if (won || selR == null || selC == null) return;
    setState(() {
      state[selR!][selC!] = value;
      moves++;
    });
    if (value == 0) {
      widget.audio.clear();
    } else {
      widget.audio.place();
    }
    _haptic();
    _checkWin();
  }

  int _cellValue(int r, int c) {
    final g = widget.puzzle.givens[r][c];
    return g != 0 ? g : state[r][c];
  }

  Set<String> _conflicts() {
    final out = <String>{};
    for (int r = 0; r < 9; r++) {
      final seen = <int, List<int>>{};
      for (int c = 0; c < 9; c++) {
        final v = _cellValue(r, c);
        if (v > 0) seen.putIfAbsent(v, () => []).add(c);
      }
      for (final cs in seen.values) {
        if (cs.length > 1) {
          for (final c in cs) {
            out.add('$r,$c');
          }
        }
      }
    }
    for (int c = 0; c < 9; c++) {
      final seen = <int, List<int>>{};
      for (int r = 0; r < 9; r++) {
        final v = _cellValue(r, c);
        if (v > 0) seen.putIfAbsent(v, () => []).add(r);
      }
      for (final rs in seen.values) {
        if (rs.length > 1) {
          for (final r in rs) {
            out.add('$r,$c');
          }
        }
      }
    }
    for (int br = 0; br < 3; br++) {
      for (int bc = 0; bc < 3; bc++) {
        final seen = <int, List<List<int>>>{};
        for (int i = 0; i < 3; i++) {
          for (int j = 0; j < 3; j++) {
            final r = br * 3 + i, c = bc * 3 + j;
            final v = _cellValue(r, c);
            if (v > 0) seen.putIfAbsent(v, () => []).add([r, c]);
          }
        }
        for (final cells in seen.values) {
          if (cells.length > 1) {
            for (final cell in cells) {
              out.add('${cell[0]},${cell[1]}');
            }
          }
        }
      }
    }
    return out;
  }

  void _checkWin() {
    for (int r = 0; r < 9; r++) {
      for (int c = 0; c < 9; c++) {
        if (_cellValue(r, c) == 0) return;
      }
    }
    if (_conflicts().isNotEmpty) return;
    won = true;
    widget.audio.win();
    final stars = _starRating();
    context.read<ProgressService>().recordWin(widget.puzzle.id, stars);
    Future.delayed(const Duration(milliseconds: 300), _showWinSheet);
  }

  int _starRating() {
    final blanks = 81 - widget.puzzle.givenCount;
    if (moves <= blanks) return 3;
    if (moves <= (blanks * 1.4).round()) return 2;
    return 1;
  }

  void _showWinSheet() {
    final stars = _starRating();
    showModalBottomSheet(
      context: context,
      backgroundColor: Palette.panel,
      isDismissible: false,
      enableDrag: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Grid Complete',
                style: TextStyle(
                    color: Palette.ink,
                    fontSize: 24,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                3,
                (i) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Icon(
                    i < stars ? Icons.star : Icons.star_border,
                    color: i < stars ? Palette.jade : Palette.haze,
                    size: 44,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text('Solved in $moves entries',
                style: const TextStyle(color: Palette.haze, fontSize: 14)),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Palette.ink,
                      side: const BorderSide(color: Palette.line),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).pop();
                    },
                    child: const Text('Levels'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Palette.jade,
                      foregroundColor: Palette.void_,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).pop();
                      widget.onNext?.call();
                    },
                    child: const Text('Next'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _reset() {
    setState(() {
      state = List.generate(9, (_) => List.filled(9, 0));
      selR = null;
      selC = null;
      moves = 0;
      won = false;
    });
    widget.audio.tap();
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.puzzle;
    final conflicts = _conflicts();
    final enabled = selR != null && selC != null;
    return Scaffold(
      backgroundColor: Palette.void_,
      appBar: AppBar(
        backgroundColor: Palette.void_,
        elevation: 0,
        foregroundColor: Palette.ink,
        title: Text('Level ${p.id + 1}',
            style: const TextStyle(fontWeight: FontWeight.w600)),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _reset),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 6),
            Expanded(
              child: Center(
                child: LayoutBuilder(builder: (context, cons) {
                  final side = (cons.maxWidth < cons.maxHeight
                          ? cons.maxWidth
                          : cons.maxHeight) -
                      32;
                  final cell = side / 9;
                  return GestureDetector(
                    onTapUp: (d) {
                      final c = (d.localPosition.dx / cell)
                          .floor()
                          .clamp(0, 8);
                      final r = (d.localPosition.dy / cell)
                          .floor()
                          .clamp(0, 8);
                      _selectCell(r, c);
                    },
                    child: CustomPaint(
                      size: Size(side, side),
                      painter: BoardPainter(
                        puzzle: p,
                        state: state,
                        selR: selR,
                        selC: selC,
                        conflicts: conflicts,
                      ),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 12),
            Opacity(
              opacity: enabled ? 1.0 : 0.4,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    for (int v = 1; v <= 9; v++)
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          child: AspectRatio(
                            aspectRatio: 0.8,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Palette.raised,
                                foregroundColor: Palette.ink,
                                padding: EdgeInsets.zero,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8)),
                              ),
                              onPressed: enabled ? () => _enterValue(v) : null,
                              child: Text('$v',
                                  style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700)),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SizedBox(
                width: double.infinity,
                height: 44,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Palette.coral,
                    side: BorderSide(
                        color: Palette.coral.withValues(alpha: 0.5)),
                  ),
                  onPressed: enabled ? () => _enterValue(0) : null,
                  icon: const Icon(Icons.backspace_outlined, size: 16),
                  label: const Text('Clear cell'),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Entries: $moves',
                      style:
                          const TextStyle(color: Palette.haze, fontSize: 14)),
                  Text(p.tier.toUpperCase(),
                      style: TextStyle(
                          color: Palette.tierColors[p.tier],
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.5,
                          fontSize: 13)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
