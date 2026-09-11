#!/usr/bin/env bash
set -Eeuo pipefail

APP_NAME="winlux"
INSTALL_DIR="${WINLUX_INSTALL_DIR:-/opt/${APP_NAME}}"
BIN_PATH="/usr/local/bin/${APP_NAME}"
REPO_URL="${WINLUX_REPO_URL:-https://github.com/guirgb/Winlux.git}"

log() { printf '[winlux] %s\n' "$*"; }
fail() { printf '[winlux] erro: %s\n' "$*" >&2; exit 1; }

[[ "${EUID}" -eq 0 ]] || fail "execute com sudo: sudo bash install.sh"

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_DIR="${WINLUX_SOURCE_DIR:-${SCRIPT_DIR}}"
TEMP_DIR=""
cleanup() { [[ -n "${TEMP_DIR}" ]] && rm -rf -- "${TEMP_DIR}" || true; }
trap cleanup EXIT

# Quando o script for baixado e executado fora de um clone, baixa o repositório.
if [[ ! -d "${SOURCE_DIR}/.git" && "${SOURCE_DIR}" == "/tmp"* ]]; then
  TEMP_DIR="$(mktemp -d)"
  log "baixando arquivos de ${REPO_URL}"
  git clone --depth 1 "${REPO_URL}" "${TEMP_DIR}/repo"
  SOURCE_DIR="${TEMP_DIR}/repo"
fi

command -v apt-get >/dev/null 2>&1 || fail "este instalador requer uma distribuição baseada em Debian/Ubuntu"
export DEBIAN_FRONTEND=noninteractive

log "instalando ferramentas básicas"
apt-get update -y
apt-get install -y ca-certificates git curl build-essential

# Dependências opcionais, instaladas somente quando os respectivos arquivos existem.
if [[ -f "${SOURCE_DIR}/requirements.txt" ]]; then
  apt-get install -y python3 python3-pip python3-venv
fi
if [[ -f "${SOURCE_DIR}/package.json" ]]; then
  apt-get install -y nodejs npm
fi

log "copiando arquivos para ${INSTALL_DIR}"
install -d -m 0755 "${INSTALL_DIR}"
# Não copia o próprio destino para evitar recursão quando INSTALL_DIR estiver dentro do projeto.
find "${SOURCE_DIR}" -mindepth 1 -maxdepth 1 ! -name .git ! -name "$(basename -- "${INSTALL_DIR}")" -exec cp -a {} "${INSTALL_DIR}/" \;

if [[ -f "${INSTALL_DIR}/requirements.txt" ]]; then
  log "instalando dependências Python"
  python3 -m venv "${INSTALL_DIR}/.venv"
  "${INSTALL_DIR}/.venv/bin/pip" install --upgrade pip
  "${INSTALL_DIR}/.venv/bin/pip" install -r "${INSTALL_DIR}/requirements.txt"
fi

if [[ -f "${INSTALL_DIR}/package.json" ]]; then
  log "instalando dependências Node.js"
  if [[ -f "${INSTALL_DIR}/package-lock.json" ]]; then
    npm --prefix "${INSTALL_DIR}" ci --omit=dev
  else
    npm --prefix "${INSTALL_DIR}" install --omit=dev
  fi
fi

# Se houver um executável principal, cria um comando global para ele.
if [[ -f "${INSTALL_DIR}/bin/${APP_NAME}" ]]; then
  install -m 0755 "${INSTALL_DIR}/bin/${APP_NAME}" "${BIN_PATH}"
elif [[ -f "${INSTALL_DIR}/${APP_NAME}" ]]; then
  install -m 0755 "${INSTALL_DIR}/${APP_NAME}" "${BIN_PATH}"
elif [[ -f "${INSTALL_DIR}/main.py" ]]; then
  cat > "${BIN_PATH}" <<EOF
#!/usr/bin/env bash
exec "${INSTALL_DIR}/.venv/bin/python" "${INSTALL_DIR}/main.py" "\$@"
EOF
  chmod 0755 "${BIN_PATH}"
else
  # Mantém um comando útil mesmo enquanto o projeto ainda não possui um executável.
  cat > "${BIN_PATH}" <<EOF
#!/usr/bin/env bash
printf '%s\\n' 'Winlux instalado em ${INSTALL_DIR}. Adicione o executável do projeto e execute novamente o instalador.'
EOF
  chmod 0755 "${BIN_PATH}"
fi

log "instalação concluída"
log "arquivos: ${INSTALL_DIR}"
log "comando: ${BIN_PATH}"
