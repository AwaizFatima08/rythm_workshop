import 'dart:math';

import 'package:flutter/material.dart';

import '../theme.dart';

/// Adult check before Settings. Returns true only if solved.
/// 6-9 x 5-9 always gives a 2-digit answer, so it checks itself after two taps.
/// Closes after 3 wrong answers.
class ParentalGate extends StatefulWidget {
  const ParentalGate({super.key, this.random});

  final Random? random;

  static Future<bool> show(BuildContext context, {Random? random}) async {
    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => ParentalGate(random: random),
    );
    return ok ?? false;
  }

  @override
  State<ParentalGate> createState() => _ParentalGateState();
}

class _ParentalGateState extends State<ParentalGate> {
  late final Random _random = widget.random ?? Random();
  late int _a;
  late int _b;
  String _typed = '';
  int _wrongTries = 0;
  bool _showError = false;

  @override
  void initState() {
    super.initState();
    _newProblem();
  }

  void _newProblem() {
    _a = _random.nextInt(4) + 6; // 6 to 9
    _b = _random.nextInt(5) + 5; // 5 to 9 -> answer is always 30 to 81
    _typed = '';
  }

  void _tapDigit(int d) {
    if (_typed.length >= 2) return;
    setState(() {
      _typed += '$d';
      _showError = false;
    });
    if (_typed.length == 2) _check();
  }

  void _clear() => setState(() => _typed = '');

  void _check() {
    if (int.parse(_typed) == _a * _b) {
      Navigator.of(context).pop(true);
      return;
    }
    _wrongTries++;
    if (_wrongTries >= 3) {
      Navigator.of(context).pop(false);
      return;
    }
    setState(() {
      _showError = true;
      _newProblem();
    });
  }

  Widget _key(String label, VoidCallback onTap) => Padding(
        padding: const EdgeInsets.all(4),
        child: SizedBox(
          width: 64,
          height: 64,
          child: ElevatedButton(
            key: ValueKey('gate-key-$label'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Palette.blue,
              foregroundColor: Colors.white,
              padding: EdgeInsets.zero,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: onTap,
            child: Text(label, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
          ),
        ),
      );

  Widget _keypad() => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final row in const [
            [1, 2, 3],
            [4, 5, 6],
            [7, 8, 9],
          ])
            Row(mainAxisSize: MainAxisSize.min, children: [
              for (final d in row) _key('$d', () => _tapDigit(d)),
            ]),
          Row(mainAxisSize: MainAxisSize.min, children: [
            _key('0', () => _tapDigit(0)),
            _key('⌫', _clear),
          ]),
        ],
      );

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(12), // fits a 360 dp-tall phone
      backgroundColor: Palette.cream,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 240,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Grown-ups only',
                      style: TextStyle(fontSize: 22, height: 1.2, fontWeight: FontWeight.bold, color: Palette.walnut)),
                  const SizedBox(height: 6),
                  // The "try again" note replaces the instruction so the dialog
                  // never grows taller than a 360 dp phone.
                  SizedBox(
                    height: 40,
                    child: _showError
                        ? const Text('Not quite — here is a new one.',
                            style: TextStyle(fontSize: 15, height: 1.2, color: Palette.red))
                        : const Text('Solve this to open Settings.',
                            style: TextStyle(fontSize: 16, height: 1.2, color: Palette.walnut)),
                  ),
                  const SizedBox(height: 8),
                  Text('$_a × $_b = ${_typed.padRight(2, '_')}',
                      key: const ValueKey('gate-problem'),
                      style: const TextStyle(fontSize: 32, height: 1.2, fontWeight: FontWeight.w800, color: Palette.walnut)),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 56,
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Close', style: TextStyle(fontSize: 18)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            _keypad(),
          ],
        ),
      ),
    );
  }
}
