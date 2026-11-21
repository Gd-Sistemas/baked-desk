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
