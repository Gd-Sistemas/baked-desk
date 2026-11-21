# Gera os ícones do Baked Desk a partir de baked/assets/icon-1024.png (rode uma vez e faça commit do resultado).
# Uso: python3 baked/make_assets.py   (precisa do Pillow)
import base64, io, os
from PIL import Image
here = os.path.dirname(os.path.abspath(__file__)); out = os.path.join(here, 'assets')
src = Image.open(os.path.join(out, 'icon-1024.png')).convert('RGBA')
def png(size, name): src.resize((size, size), Image.LANCZOS).save(os.path.join(out, name))
png(1024, 'icon.png'); png(32, '32x32.png'); png(64, '64x64.png'); png(128, '128x128.png'); png(256, '128x128@2x.png'); png(256, 'flutter-icon.png')
src.save(os.path.join(out, 'icon.ico'), sizes=[(16,16),(24,24),(32,32),(48,48),(64,64),(128,128),(256,256)])
src.save(os.path.join(out, 'tray-icon.ico'), sizes=[(16,16),(24,24),(32,32),(48,48),(64,64)])
buf = io.BytesIO(); src.resize((256, 256), Image.LANCZOS).save(buf, 'PNG'); b64 = base64.b64encode(buf.getvalue()).decode()
svg = ('<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" viewBox="0 0 256 256" width="256" height="256">'
       f'<image width="256" height="256" xlink:href="data:image/png;base64,{b64}"/></svg>')
open(os.path.join(out, 'icon.svg'), 'w').write(svg)
print('ok', sorted(os.listdir(out)))

# ---- Android: ícones do launcher (legado, redondo e adaptativo) ----
from PIL import ImageDraw, ImageChops
adir = os.path.join(out, 'android'); os.makedirs(adir, exist_ok=True)
BLUE = (0, 8, 153, 255)
# letras brancas sobre transparente (a partir do ícone azul com letras brancas)
rgb = src.convert('RGB'); alpha = rgb.convert('L').point(lambda v: 255 if v > 170 else (0 if v < 60 else int((v - 60) * 255 / 110)))
letters = Image.new('RGBA', src.size, (255, 255, 255, 255)); letters.putalpha(alpha)
box = letters.getbbox(); letters = letters.crop(box)
def foreground(px):  # 108dp -> px; letras dentro da zona segura (60%)
    cv = Image.new('RGBA', (px, px), (0, 0, 0, 0)); h = int(px * 0.40); w = int(letters.width * h / letters.height)
    l = letters.resize((w, h), Image.LANCZOS); cv.alpha_composite(l, ((px - w) // 2, (px - h) // 2)); return cv
def round_icon(px):
    im = src.resize((px, px), Image.LANCZOS); m = Image.new('L', (px, px), 0); ImageDraw.Draw(m).ellipse((0, 0, px - 1, px - 1), fill=255)
    bg = Image.new('RGBA', (px, px), BLUE); fg = foreground(px)  # fundo azul cheio + letras
    full = bg.copy(); lw = foreground(px); full.alpha_composite(lw); full.putalpha(m); return full
dens = {'mdpi': 48, 'hdpi': 72, 'xhdpi': 96, 'xxhdpi': 144, 'xxxhdpi': 192}
for d, px in dens.items():
    p = os.path.join(adir, f'mipmap-{d}'); os.makedirs(p, exist_ok=True)
    src.resize((px, px), Image.LANCZOS).save(os.path.join(p, 'ic_launcher.png'))
    round_icon(px).save(os.path.join(p, 'ic_launcher_round.png'))
    foreground(int(px * 108 / 48)).save(os.path.join(p, 'ic_launcher_foreground.png'))
    # ícone de notificação: só as letras, branco puro, 24dp
    n = int(px * 24 / 48); nl = foreground(n * 3).crop((0, 0, n * 3, n * 3)).resize((n, n), Image.LANCZOS); nl.save(os.path.join(p, 'ic_stat_logo.png'))
print('android ok')
