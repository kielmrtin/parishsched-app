// Composites the church icon (same geometry as lib/widgets/church_logo.dart
// and tool/generate_icon.py) with "ParishSched" + parish name text, for use
// as a bitmap layer in android/app/src/main/res/drawable/launch_background.xml.
// This exists because that native pre-Flutter splash turned out to be
// entirely outside Flutter's control on this device (confirmed by a photo
// of the real device showing the icon even with zero splash code left in
// the Dart layer) -- text has to be baked into an image for that native
// layer, since it's a Drawable, not a widget tree.
//
// Run: node tool/generate_splash_with_text.js
const { createCanvas } = require('canvas');
const fs = require('fs');

const W = 900, H = 1000;
const CREAM = '#F5EAD9';
const canvas = createCanvas(W, H);
const ctx = canvas.getContext('2d');
// Transparent background -- this sits as a layer over launch_background.xml's
// existing maroon color item, not a standalone image.

// -- Church icon, scaled/centered in the top ~2/3 --------------------------
const s = 6.0; // scale factor from the 100-unit design space
const ox = W / 2 - 51 * s; // 51 = content bbox center x, matches generate_icon.py
const oy = 40;             // top padding
function X(x) { return ox + x * s; }
function Y(y) { return oy + (y - 1) * s; } // 1 = content bbox top

ctx.fillStyle = CREAM;

function archPath(l, t, r, b) {
  const archHeight = (r - l) * 0.55;
  const midY = t + archHeight;
  const radius = (r - l) / 2;
  ctx.moveTo(X(l), Y(b));
  ctx.lineTo(X(l), Y(midY));
  ctx.arc(X((l + r) / 2), Y(midY), radius * s, Math.PI, 0, false);
  ctx.lineTo(X(r), Y(b));
  ctx.closePath();
}

ctx.beginPath();
// Nave roof + body
ctx.moveTo(X(38), Y(46));
ctx.lineTo(X(64), Y(36));
ctx.lineTo(X(90), Y(46));
ctx.lineTo(X(90), Y(50));
ctx.lineTo(X(38), Y(50));
ctx.closePath();
ctx.rect(X(38), Y(50), X(90) - X(38), Y(76) - Y(50));
// Tower body
ctx.rect(X(14), Y(34), X(34) - X(14), Y(76) - Y(34));
// Spire
ctx.moveTo(X(12), Y(34));
ctx.lineTo(X(24), Y(10));
ctx.lineTo(X(36), Y(34));
ctx.closePath();
// Cross (single outline, no self-overlap)
ctx.moveTo(X(23), Y(1));
ctx.lineTo(X(25), Y(1));
ctx.lineTo(X(25), Y(4));
ctx.lineTo(X(28), Y(4));
ctx.lineTo(X(28), Y(6));
ctx.lineTo(X(25), Y(6));
ctx.lineTo(X(25), Y(10));
ctx.lineTo(X(23), Y(10));
ctx.lineTo(X(23), Y(6));
ctx.lineTo(X(20), Y(6));
ctx.lineTo(X(20), Y(4));
ctx.lineTo(X(23), Y(4));
ctx.closePath();
ctx.fill('evenodd');

// Punch the arch windows/openings out (draw them in destination-out mode)
ctx.save();
ctx.globalCompositeOperation = 'destination-out';
ctx.beginPath();
archPath(47, 58, 60, 76);
archPath(68, 58, 81, 76);
archPath(20.5, 42, 27.5, 56);
ctx.fill();
ctx.restore();

// -- Text --------------------------------------------------------------
ctx.textAlign = 'center';
ctx.fillStyle = CREAM;
ctx.font = 'bold 58px "DejaVu Sans"';
ctx.fillText('ParishSched', W / 2, 620);

ctx.font = 'bold 26px "DejaVu Sans"';
ctx.fillStyle = 'rgba(245,234,217,0.85)';
// Manual letter-spacing (canvas has no native letter-spacing support).
function drawSpacedText(text, cx, y, spacing) {
  const widths = [...text].map((ch) => ctx.measureText(ch).width);
  const total = widths.reduce((a, b) => a + b, 0) + spacing * (text.length - 1);
  let x = cx - total / 2;
  ctx.textAlign = 'left';
  for (let i = 0; i < text.length; i++) {
    ctx.fillText(text[i], x, y);
    x += widths[i] + spacing;
  }
  ctx.textAlign = 'center';
}
drawSpacedText('ST. JOHN THE BAPTIST PARISH', W / 2, 680, 2.5);

const out = fs.createWriteStream('splash_with_text.png');
const stream = canvas.createPNGStream();
stream.pipe(out);
out.on('finish', () => console.log('wrote splash_with_text.png'));
