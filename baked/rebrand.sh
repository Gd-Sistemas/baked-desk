#!/usr/bin/env bash
# Aplica a marca Baked Desk sobre o código do RustDesk antes de compilar.
# Roda na raiz do repositório (depois do checkout com submódulos). Falha se algum trecho não for encontrado,
# para não gerar um instalador com a marca errada quando o RustDesk mudar o código.
set -euo pipefail

NAME="Baked Desk"
SERVER="bakeddesk.gdsistemas.com.br"
KEY="g4z4JJDusghdvE424DLp3zt16vd7eENjxgydOLJU2EI="   # chave PÚBLICA do servidor (não é segredo)
COMPANY="GD Sistemas / Baked Potato"
ATTRIB="Baked Desk, baseado no RustDesk (AGPL-3.0)"
HERE="$(cd "$(dirname "$0")" && pwd)"

CFG=libs/hbb_common/src/config.rs
RC=flutter/windows/runner/Runner.rc

must() { grep -qF -- "$2" "$1" || { echo "rebrand: trecho não encontrado em $1: $2" >&2; exit 1; }; }

# 1) Nome, servidor e chave embutidos (valores de reserva)
must "$CFG" 'RwLock::new("RustDesk".to_owned())'
must "$CFG" 'pub const RENDEZVOUS_SERVERS: &[&str] = &["rs-ny.rustdesk.com"];'
must "$CFG" 'pub const RS_PUB_KEY: &str = "OeVuKk5nlHiXp+APNn0Y3pC1Iwpwn44JGqrQCsWqmBw=";'
sed -i "s|RwLock::new(\"RustDesk\".to_owned())|RwLock::new(\"${NAME}\".to_owned())|" "$CFG"
sed -i "s|pub const RENDEZVOUS_SERVERS: &\[&str\] = &\[\"rs-ny.rustdesk.com\"\];|pub const RENDEZVOUS_SERVERS: \&[\&str] = \&[\"${SERVER}\"];|" "$CFG"
sed -i "s|pub const RS_PUB_KEY: &str = \"OeVuKk5nlHiXp+APNn0Y3pC1Iwpwn44JGqrQCsWqmBw=\";|pub const RS_PUB_KEY: \&str = \"${KEY}\";|" "$CFG"
must "$CFG" "\"${SERVER}\""; must "$CFG" "\"${KEY}\""; must "$CFG" "\"${NAME}\""

# 2) Servidor e chave como configuração PADRÃO (some o aviso "configure seu próprio servidor")
DEFAULTS='pub static ref DEFAULT_SETTINGS: RwLock<HashMap<String, String>> = Default::default();'
must "$CFG" "$DEFAULTS"
SERVER="$SERVER" KEY="$KEY" python3 - "$CFG" "$DEFAULTS" <<'PY'
import os, sys
p, old = sys.argv[1], sys.argv[2]
new = ('pub static ref DEFAULT_SETTINGS: RwLock<HashMap<String, String>> = RwLock::new(HashMap::from(['
       '("custom-rendezvous-server".to_owned(), "%s".to_owned()), ("key".to_owned(), "%s".to_owned())]));' % (os.environ['SERVER'], os.environ['KEY']))
s = open(p).read(); assert old in s; open(p, 'w').write(s.replace(old, new, 1))
PY
must "$CFG" '("custom-rendezvous-server".to_owned(), "'"$SERVER"'".to_owned())'

# 3) Rodapé "Desenvolvido por RustDesk" -> atribuição (mantém a menção exigida pela AGPL)
n=0
for f in src/lang/*.rs; do
  if grep -q '("powered_by_me", "' "$f"; then
    sed -i -E "s|\(\"powered_by_me\", \"[^\"]*\"\)|(\"powered_by_me\", \"${ATTRIB}\")|" "$f"; n=$((n+1))
  fi
done
[ "$n" -gt 0 ] || { echo "rebrand: powered_by_me não encontrado" >&2; exit 1; }
grep -qF "$ATTRIB" src/lang/en.rs || { echo "rebrand: atribuição não aplicada" >&2; exit 1; }

# 4) Informações do arquivo no Windows (propriedades do .exe)
must "$RC" 'VALUE "ProductName", "RustDesk"'
sed -i "s|VALUE \"ProductName\", \"RustDesk\"|VALUE \"ProductName\", \"${NAME}\"|; s|VALUE \"FileDescription\", \"RustDesk Remote Desktop\"|VALUE \"FileDescription\", \"${NAME} - acesso remoto\"|; s|VALUE \"CompanyName\", \"[^\"]*\"|VALUE \"CompanyName\", \"${COMPANY}\"|; s|VALUE \"LegalCopyright\", \"[^\"]*\"|VALUE \"LegalCopyright\", \"Baseado no RustDesk (AGPL-3.0)\"|" "$RC"
must "$RC" "\"${NAME}\""
for T in Cargo.toml libs/portable/Cargo.toml; do
  must "$T" 'ProductName = "RustDesk"'
  sed -i "s|^ProductName = \"RustDesk\"|ProductName = \"${NAME}\"|; s|^FileDescription = \"RustDesk Remote Desktop\"|FileDescription = \"${NAME} - acesso remoto\"|; s|^LegalCopyright = \".*\"|LegalCopyright = \"Baseado no RustDesk (AGPL-3.0)\"|; s|^description = \"RustDesk Remote Desktop\"|description = \"${NAME} - acesso remoto\"|" "$T"
  must "$T" "ProductName = \"${NAME}\""
done

# 5) Pacote Linux: nome baked-desk (substitui o rustdesk), atalho e descrição
must build.py 'content = """Package: rustdesk'
python3 - <<'PY'
p = 'build.py'; s = open(p).read()
for old, new in [('content = """Package: rustdesk\n', 'content = """Package: baked-desk\nConflicts: rustdesk\nReplaces: rustdesk\n'),
                 ('Maintainer: rustdesk <info@rustdesk.com>', 'Maintainer: GD Sistemas'),
                 ('Homepage: https://rustdesk.com', 'Homepage: https://baked.gdsistemas.com.br'),
                 ('Description: A remote control software.', 'Description: Baked Desk - acesso remoto')]:
    assert old in s, old; s = s.replace(old, new, 1)
open(p, 'w').write(s)
PY
for D in res/rustdesk.desktop res/rustdesk-link.desktop; do
  must "$D" 'Name=RustDesk'
  sed -i "s|^Name=RustDesk|Name=${NAME}|; s|^GenericName=.*|GenericName=Acesso remoto|; s|^Comment=.*|Comment=Acesso remoto da Baked|" "$D"
done

# 6) Ícones (monograma BD)
A="$HERE/assets"
cp "$A/icon.png" res/icon.png; cp "$A/32x32.png" res/32x32.png; cp "$A/64x64.png" res/64x64.png
cp "$A/128x128.png" res/128x128.png; cp "$A/128x128@2x.png" res/128x128@2x.png
cp "$A/icon.ico" res/icon.ico; cp "$A/tray-icon.ico" res/tray-icon.ico
cp "$A/icon.svg" res/scalable.svg; cp "$A/icon.svg" flutter/assets/icon.svg
cp "$A/flutter-icon.png" flutter/assets/icon.png
cp "$A/icon.ico" flutter/windows/runner/resources/app_icon.ico

echo "rebrand: ${NAME} -> ${SERVER} (padrões, atribuição, pacote baked-desk, ícones)"
