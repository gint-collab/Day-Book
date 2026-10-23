// Renders the Dayloom app icon, splash logo and wordmark to PNGs in
// assets/branding/. The design follows design/reference/app-icon.jpg (a green
// spiral notebook with a "d"), redrawn here so it stays sharp at any size.
// Run from the project root with:
//
//   flutter test tool/branding/generate_branding_test.dart
//
// then regenerate the platform files with:
//
//   dart run flutter_launcher_icons
//   dart run flutter_native_splash:create

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const _outDir = 'assets/branding';

const _cover = Color(0xFF4CAF50);
const _spine = Color(0xFF3E9643);
const _ringHole = Color(0xFF2E6F33);
const _ring = Color(0xFFFFFFFF);
const _ringShade = Color(0xFFCFCFCF);
const _glyph = Color(0xFFFFFFFF);
const _wordmark = Color(0xFF2F6B34);

/// Notebook cover: green page, darker spine, spiral rings and bookmark.
///
/// Geometry is laid out relative to [c] (the area guaranteed visible), but the
/// spine, rings and bookmark bleed out to the canvas edges so the icon still
/// reads as a notebook when a launcher crops it to a circle or squircle.
void _paintCover(Canvas canvas, Size size, Rect c) {
  double x(double f) => c.left + c.width * f;
  double y(double f) => c.top + c.height * f;

  canvas.drawRect(Offset.zero & size, Paint()..color = _cover);
  canvas.drawRect(
      Rect.fromLTRB(0, 0, x(0.16), size.height), Paint()..color = _spine);

  // Spiral rings: a dark punch hole with a white wire looping over the edge.
  final wireH = c.height * 0.044;
  for (final f in [0.2, 0.4, 0.6, 0.8]) {
    final cy = y(f);
    canvas.drawCircle(
        Offset(x(0.105), cy), c.width * 0.034, Paint()..color = _ringHole);
    final wire = RRect.fromLTRBR(0, cy - wireH / 2, x(0.108), cy + wireH / 2,
        Radius.circular(wireH / 2));
    canvas.drawRRect(
      wire,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(0, cy - wireH / 2),
          Offset(0, cy + wireH / 2),
          [_ring, _ring, _ringShade],
          [0, 0.45, 1],
        ),
    );
  }

  // Ribbon bookmark hanging from the top edge.
  final bl = x(0.225), br = x(0.293), bb = y(0.108);
  canvas.drawPath(
    Path()
      ..moveTo(bl, 0)
      ..lineTo(br, 0)
      ..lineTo(br, bb)
      ..lineTo((bl + br) / 2, bb - c.height * 0.026)
      ..lineTo(bl, bb)
      ..close(),
    Paint()..color = _ring,
  );
}

/// The "d" lettermark with its soft long shadow.
void _paintGlyph(Canvas canvas, Rect c) {
  final u = c.width / 512;
  Offset p(double px, double py) => Offset(c.left + px * u, c.top + py * u);

  final center = p(272, 292);
  const ringRadius = 81.0, stroke = 33.0;
  final bowl = Path()
    ..addOval(Rect.fromCircle(
        center: center, radius: (ringRadius + stroke / 2) * u))
    ..addOval(Rect.fromCircle(
        center: center, radius: (ringRadius - stroke / 2) * u))
    ..fillType = PathFillType.evenOdd;
  final stemLeft = p(272 + ringRadius - stroke / 2, 118);
  final stem = Path()
    ..addRRect(RRect.fromRectAndCorners(
      Rect.fromLTWH(stemLeft.dx, stemLeft.dy, stroke * u, 174 * u),
      topLeft: Radius.circular(stroke * u),
      topRight: Radius.circular(stroke * u),
    ));

  // Long shadow cast down-right from the bowl.
  canvas.saveLayer(null, Paint()..color = const Color(0x52FFFFFF));
  final shadowPaint = Paint()..color = _glyph;
  for (var t = 0.0; t <= 26; t += 0.5) {
    canvas.drawPath(bowl.shift(Offset(t * u, t * u)), shadowPaint);
  }
  canvas.restore();

  final glyphPaint = Paint()..color = _glyph;
  canvas.drawPath(bowl, glyphPaint);
  canvas.drawPath(stem, glyphPaint);
}

/// The full icon as a rounded tile with a soft drop shadow.
void _paintSplashTile(Canvas canvas, Rect tile) {
  final rrect =
      RRect.fromRectAndRadius(tile, Radius.circular(tile.width * 0.225));
  canvas.drawRRect(
    rrect.shift(const Offset(0, 14)),
    Paint()
      ..color = const Color(0x40402A10)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 22),
  );
  canvas.save();
  canvas.clipRRect(rrect);
  canvas.translate(tile.left, tile.top);
  final local = Offset.zero & tile.size;
  _paintCover(canvas, tile.size, local);
  _paintGlyph(canvas, local);
  canvas.restore();
}

Rect _centered(double canvas, double side) => Rect.fromCenter(
    center: Offset(canvas / 2, canvas / 2), width: side, height: side);

Future<void> _write(
    String name, int width, int height, void Function(Canvas) paint) async {
  final recorder = ui.PictureRecorder();
  paint(Canvas(recorder));
  final image = await recorder.endRecording().toImage(width, height);
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  File('$_outDir/$name').writeAsBytesSync(bytes!.buffer.asUint8List());
}

Future<void> _writeWordmark(String name, Color color) async {
  final painter = TextPainter(
    text: TextSpan(
      text: 'Dayloom',
      style: TextStyle(
        fontFamily: 'Inter',
        fontWeight: FontWeight.w700,
        fontSize: 120,
        letterSpacing: -2,
        color: color,
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  const w = 800, h = 200;
  await _write(name, w, h, (c) {
    painter.paint(
        c, Offset((w - painter.width) / 2, (h - painter.height) / 2));
  });
}

void main() {
  testWidgets('generate branding PNGs', (tester) async {
    await tester.runAsync(() async {
      final font = FontLoader('Inter')
        ..addFont(Future.value(ByteData.sublistView(
            File('assets/fonts/Inter-700.ttf').readAsBytesSync())));
      await font.load();
      Directory(_outDir).createSync(recursive: true);

      // Full-bleed icon (iOS, macOS, web, Windows, legacy Android).
      await _write('icon.png', 1024, 1024, (c) {
        final full = _centered(1024, 1024);
        _paintCover(c, const Size(1024, 1024), full);
        _paintGlyph(c, full);
      });

      // Android adaptive icon: layers are 108dp with the middle 72dp visible;
      // keep the layout a little inside that so circle masks don't clip it.
      final adaptive = _centered(1024, 1024 * 72 / 108 * 0.92);
      await _write('icon_background.png', 1024, 1024,
          (c) => _paintCover(c, const Size(1024, 1024), adaptive));
      await _write('icon_foreground.png', 1024, 1024,
          (c) => _paintGlyph(c, adaptive));

      // Pre-Android-12 / iOS / web splash: rounded tile with a soft shadow,
      // sitting on the paper background.
      await _write('splash_logo.png', 768, 768,
          (c) => _paintSplashTile(c, _centered(768, 600)));

      // Android 12+ splash: 1152 canvas, circle-masked to the middle 768.
      // The 600px tile's rounded corners stay inside that circle, so the
      // system mask never clips it and it matches the other platforms.
      await _write('splash_android12.png', 1152, 1152,
          (c) => _paintSplashTile(c, _centered(1152, 600)));

      await _writeWordmark('wordmark.png', _wordmark);
    });
  });
}
