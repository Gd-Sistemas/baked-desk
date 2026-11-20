#!/usr/bin/env bash
# Aplica a marca Baked Desk sobre o código do RustDesk antes de compilar.
# Roda na raiz do repositório (depois do checkout com submódulos). Falha se algum trecho não for encontrado,
# para não gerar um instalador com a marca errada quando o RustDesk mudar o código.
set -euo pipefail

NAME="Baked Desk"
SERVER="bakeddesk.gdsistemas.com.br"
KEY="g4z4JJDusghdvE424DLp3zt16vd7eENjxgydOLJU2EI="   # chave PÚBLICA do servidor (não é segredo)
COMPANY="GD Sistemas / Baked Potato"

CFG=libs/hbb_common/src/config.rs
RC=flutter/windows/runner/Runner.rc

must() { grep -qF -- "$2" "$1" || { echo "rebrand: trecho não encontrado em $1: $2" >&2; exit 1; }; }

must "$CFG" 'RwLock::new("RustDesk".to_owned())'
must "$CFG" 'pub const RENDEZVOUS_SERVERS: &[&str] = &["rs-ny.rustdesk.com"];'
must "$CFG" 'pub const RS_PUB_KEY: &str = "OeVuKk5nlHiXp+APNn0Y3pC1Iwpwn44JGqrQCsWqmBw=";'
sed -i "s|RwLock::new(\"RustDesk\".to_owned())|RwLock::new(\"${NAME}\".to_owned())|" "$CFG"
sed -i "s|pub const RENDEZVOUS_SERVERS: &\[&str\] = &\[\"rs-ny.rustdesk.com\"\];|pub const RENDEZVOUS_SERVERS: \&[\&str] = \&[\"${SERVER}\"];|" "$CFG"
sed -i "s|pub const RS_PUB_KEY: &str = \"OeVuKk5nlHiXp+APNn0Y3pC1Iwpwn44JGqrQCsWqmBw=\";|pub const RS_PUB_KEY: \&str = \"${KEY}\";|" "$CFG"
must "$CFG" "\"${SERVER}\""; must "$CFG" "\"${KEY}\""; must "$CFG" "\"${NAME}\""

# Informações do arquivo no Windows (propriedades do .exe)
must "$RC" 'VALUE "ProductName", "RustDesk"'
sed -i "s|VALUE \"ProductName\", \"RustDesk\"|VALUE \"ProductName\", \"${NAME}\"|; s|VALUE \"FileDescription\", \"RustDesk Remote Desktop\"|VALUE \"FileDescription\", \"${NAME} - acesso remoto\"|; s|VALUE \"CompanyName\", \"[^\"]*\"|VALUE \"CompanyName\", \"${COMPANY}\"|; s|VALUE \"LegalCopyright\", \"[^\"]*\"|VALUE \"LegalCopyright\", \"Baseado no RustDesk (AGPL-3.0)\"|" "$RC"
must "$RC" "\"${NAME}\""

echo "rebrand: ${NAME} -> ${SERVER}"
