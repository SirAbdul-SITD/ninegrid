class Puzzle {
  final int id;
  final String tier;
  final List<List<int>> givens; // 0 = empty
  final List<List<int>> solution;

  Puzzle({
    required this.id,
    required this.tier,
    required this.givens,
    required this.solution,
  });

  factory Puzzle.fromJson(Map<String, dynamic> j) {
    final gf = (j['givens'] as List).map((e) => e as int).toList();
    final sf = (j['solution'] as List).map((e) => e as int).toList();
    return Puzzle(
      id: j['id'] as int,
      tier: j['tier'] as String,
      givens: List.generate(9, (r) => List.generate(9, (c) => gf[r * 9 + c])),
      solution:
          List.generate(9, (r) => List.generate(9, (c) => sf[r * 9 + c])),
    );
  }

  int get givenCount {
    int n = 0;
    for (final row in givens) {
      for (final v in row) {
        if (v != 0) n++;
      }
    }
    return n;
  }
}
