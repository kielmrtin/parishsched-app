// Bakes "ParishSched" + "ST. JOHN THE BAPTIST PARISH" into the actual app
// icon itself (not just a splash-only image): this device's OEM splash was
// confirmed (via a plain-color test icon) to render directly from
// android:icon, bypassing every theme/drawable mechanism, so getting text
// onto that screen means it has to live in the icon source used by
// flutter_launcher_icons. Produces:
//   - app_icon_with_text.png: opaque maroon bg, for image_path (flat icon)
//   - app_icon_with_text_foreground.png: transparent bg, smaller/safer fill
//     for adaptive_icon_foreground (Android's adaptive-icon safe zone)
//
// Run: node tool/generate_icon_with_text.js
const { createCanvas } = require('canvas');
const fs = require('fs');

const CREAM = '#F5EAD9';
const MAROON = '#6E1B29';

function drawSpacedText(ctx, text, cx, y, spacing) {
  const widths = [...text].map((ch) => ctx.measureText(ch).width);
  const total = widths.reduce((a, b) => a + b, 0) + spacing * (text.length - 1);
  let x = cx - total / 2;
  const prevAlign = ctx.textAlign;
  ctx.textAlign = 'left';
  for (let i = 0; i < text.length; i++) {
    ctx.fillText(text[i], x, y);
    x += widths[i] + spacing;
  }
  ctx.textAlign = prevAlign;
}

function render({ size, transparentBg, iconScale, iconTopY, name1FontPx, name1Y, name2FontPx, name2Y, name2Spacing }) {
  const canvas = createCanvas(size, size);
  const ctx = canvas.getContext('2d');

  if (!transparentBg) {
    ctx.fillStyle = MAROON;
    ctx.fillRect(0, 0, size, size);
  }

  // Church icon, same 100-unit design space as church_logo.dart.
  const s = iconScale;
  const contentCx = 51; // matches generate_icon.py's content bbox center
  const ox = size / 2 - contentCx * s;
  const oy = iconTopY;
  const X = (x) => ox + x * s;
  const Y = (y) => oy + (y - 1) * s;

  ctx.fillStyle = CREAM;
  ctx.beginPath();
  ctx.moveTo(X(38), Y(46));
  ctx.lineTo(X(64), Y(36));
  ctx.lineTo(X(90), Y(46));
  ctx.lineTo(X(90), Y(50));
  ctx.lineTo(X(38), Y(50));
  ctx.closePath();
  ctx.rect(X(38), Y(50), X(90) - X(38), Y(76) - Y(50));
  ctx.rect(X(14), Y(34), X(34) - X(14), Y(76) - Y(34));
  ctx.moveTo(X(12), Y(34));
  ctx.lineTo(X(24), Y(10));
  ctx.lineTo(X(36), Y(34));
  ctx.closePath();
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

  ctx.save();
  ctx.globalCompositeOperation = 'destination-out';
  ctx.beginPath();
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
  archPath(47, 58, 60, 76);
  archPath(68, 58, 81, 76);
  archPath(20.5, 42, 27.5, 56);
  ctx.fill();
  ctx.restore();

  // Text.
  ctx.textAlign = 'center';
  ctx.fillStyle = CREAM;
  ctx.font = `bold ${name1FontPx}px "DejaVu Sans"`;
  ctx.fillText('ParishSched', size / 2, name1Y);

  ctx.font = `bold ${name2FontPx}px "DejaVu Sans"`;
  ctx.fillStyle = transparentBg
    ? 'rgba(245,234,217,0.9)'
    : 'rgba(245,234,217,0.85)';
  drawSpacedText(ctx, 'ST. JOHN THE BAPTIST PARISH', size / 2, name2Y, name2Spacing);

  return canvas;
}

const SIZE = 1024;

// Flat/legacy icon: generous fill, this is the one most likely to be what
// the OEM's splash actually reads (a plain PNG mipmap, not the adaptive
// layers).
const flat = render({
  size: SIZE,
  transparentBg: false,
  iconScale: 5.2,
  iconTopY: 242,
  name1FontPx: 46,
  name1Y: 697,
  name2FontPx: 21,
  name2Y: 742,
  name2Spacing: 2,
});
fs.writeFileSync('app_icon_with_text.png', flat.toBuffer('image/png'));
console.log('wrote app_icon_with_text.png');

// Adaptive foreground: transparent bg, smaller/more central fill so it
// clears the circular/squircle mask safe zone (see the earlier
// tool/generate_icon.py fix for the same concern on the icon-only version).
const fg = render({
  size: SIZE,
  transparentBg: true,
  iconScale: 3.6,
  iconTopY: 320,
  name1FontPx: 32,
  name1Y: 660,
  name2FontPx: 15,
  name2Y: 690,
  name2Spacing: 1.4,
});
fs.writeFileSync('app_icon_with_text_foreground.png', fg.toBuffer('image/png'));
console.log('wrote app_icon_with_text_foreground.png');
