import 'package:flutter/material.dart';
import '../models/puzzle.dart';
import '../services/palette.dart';

class BoardPainter extends CustomPainter {
  final Puzzle puzzle;
  final List<List<int>> state; // current entered values (0 = empty)
  final int? selR;
  final int? selC;
  final Set<String> conflicts;

  BoardPainter({
    required this.puzzle,
    required this.state,
    required this.selR,
    required this.selC,
    required this.conflicts,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const n = 9;
    final cell = size.width / n;

    for (int r = 0; r < n; r++) {
      for (int c = 0; c < n; c++) {
        final rect = Rect.fromLTWH(c * cell, r * cell, cell, cell);
        final isGiven = puzzle.givens[r][c] != 0;
        final isSel = r == selR && c == selC;
        final isPeer = selR != null &&
            selC != null &&
            !isSel &&
            (r == selR ||
                c == selC ||
                (r ~/ 3 == selR! ~/ 3 && c ~/ 3 == selC! ~/ 3));
        final isConf = conflicts.contains('$r,$c');
        Color fill;
        if (isConf) {
          fill = Palette.coral.withValues(alpha: 0.35);
        } else if (isSel) {
          fill = Palette.cellSel;
        } else if (isPeer) {
          fill = Palette.cellPeer;
        } else if (isGiven) {
          fill = Palette.cellGiven;
        } else {
          fill = Palette.cellFill;
        }
        canvas.drawRect(rect, Paint()..color = fill);

        final v = isGiven ? puzzle.givens[r][c] : state[r][c];
        if (v > 0) {
          final tp = TextPainter(
            text: TextSpan(
                text: '$v',
                style: TextStyle(
                    color: isGiven ? Palette.givenInk : Palette.ink,
                    fontSize: cell * 0.44,
                    fontWeight:
                        isGiven ? FontWeight.w500 : FontWeight.w700)),
            textDirection: TextDirection.ltr,
          )..layout();
          tp.paint(
              canvas,
              Offset(c * cell + cell / 2 - tp.width / 2,
                  r * cell + cell * 0.56 - tp.height / 2));
        }
      }
    }

    final thin = Paint()
      ..color = Palette.line
      ..strokeWidth = 1;
    for (int r = 0; r <= n; r++) {
      canvas.drawLine(Offset(0, r * cell), Offset(size.width, r * cell), thin);
    }
    for (int c = 0; c <= n; c++) {
      canvas.drawLine(Offset(c * cell, 0), Offset(c * cell, size.height), thin);
    }

    final thick = Paint()
      ..color = Palette.boxLine
      ..strokeWidth = 2.6;
    for (int i = 0; i <= 3; i++) {
      canvas.drawLine(
          Offset(i * 3 * cell, 0), Offset(i * 3 * cell, size.height), thick);
      canvas.drawLine(
          Offset(0, i * 3 * cell), Offset(size.width, i * 3 * cell), thick);
    }
  }

  @override
  bool shouldRepaint(covariant BoardPainter old) =>
      old.state != state ||
      old.selR != selR ||
      old.selC != selC ||
      old.conflicts != conflicts ||
      old.puzzle != puzzle;
}
