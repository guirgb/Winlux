#!/usr/bin/env bash
set -Eeuo pipefail

APP_NAME="winlux"
REPO_URL="${WINLUX_REPO_URL:-https://github.com/guirgb/Winlux.git}"
IS_TERMUX=0
if [[ -n "${PREFIX:-}" && -d "${PREFIX}/bin" ]] || [[ "${OSTYPE:-}" == "android"* ]] || [[ -n "${TERMUX_VERSION:-}" ]]; then
  IS_TERMUX=1
fi

if [[ "${IS_TERMUX}" -eq 1 ]]; then
  INSTALL_DIR="${WINLUX_INSTALL_DIR:-${PREFIX}/opt/${APP_NAME}}"
  BIN_PATH="${PREFIX}/bin/${APP_NAME}"
else
  INSTALL_DIR="${WINLUX_INSTALL_DIR:-/opt/${APP_NAME}}"
  BIN_PATH="/usr/local/bin/${APP_NAME}"
fi

log() { printf '[winlux] %s\n' "$*"; }
fail() { printf '[winlux] erro: %s\n' "$*" >&2; exit 1; }

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_DIR="${WINLUX_SOURCE_DIR:-${SCRIPT_DIR}}"
TEMP_DIR=""
cleanup() { [[ -n "${TEMP_DIR}" ]] && rm -rf -- "${TEMP_DIR}" || true; }
trap cleanup EXIT

if [[ ! -d "${SOURCE_DIR}/.git" && "${SOURCE_DIR}" == "/tmp"* ]]; then
  TEMP_DIR="$(mktemp -d)"
  log "baixando arquivos de ${REPO_URL}"
  git clone --depth 1 "${REPO_URL}" "${TEMP_DIR}/repo"
  SOURCE_DIR="${TEMP_DIR}/repo"
fi

if [[ "${IS_TERMUX}" -eq 1 ]]; then
  command -v pkg >/dev/null 2>&1 || fail "Termux não foi detectado corretamente; instale o Termux pelo F-Droid ou GitHub oficial"
  log "Termux detectado; instalando ferramentas sem sudo"
  pkg update -y
  pkg install -y git curl ca-certificates build-essential
  if [[ -f "${SOURCE_DIR}/requirements.txt" ]]; then
    pkg install -y python
  fi
  if [[ -f "${SOURCE_DIR}/package.json" ]]; then
    pkg install -y nodejs
  fi
else
  command -v apt-get >/dev/null 2>&1 || fail "este instalador requer Ubuntu/Debian ou Termux"
  [[ "${EUID}" -eq 0 ]] || fail "no Ubuntu/Debian execute com sudo: sudo bash install.sh"
  export DEBIAN_FRONTEND=noninteractive
  log "Ubuntu/Debian detectado; instalando ferramentas básicas"
  apt-get update -y
  apt-get install -y ca-certificates git curl build-essential
  if [[ -f "${SOURCE_DIR}/requirements.txt" ]]; then
    apt-get install -y python3 python3-pip python3-venv
  fi
  if [[ -f "${SOURCE_DIR}/package.json" ]]; then
    apt-get install -y nodejs npm
  fi
fi

log "copiando arquivos para ${INSTALL_DIR}"
mkdir -p "${INSTALL_DIR}"
find "${SOURCE_DIR}" -mindepth 1 -maxdepth 1 ! -name .git ! -name "$(basename -- "${INSTALL_DIR}")" -exec cp -a {} "${INSTALL_DIR}/" \;

if [[ -f "${INSTALL_DIR}/requirements.txt" ]]; then
  log "instalando dependências Python"
  if [[ "${IS_TERMUX}" -eq 1 ]]; then
    python -m pip install --upgrade pip
    python -m pip install -r "${INSTALL_DIR}/requirements.txt"
  else
    python3 -m venv "${INSTALL_DIR}/.venv"
    "${INSTALL_DIR}/.venv/bin/pip" install --upgrade pip
    "${INSTALL_DIR}/.venv/bin/pip" install -r "${INSTALL_DIR}/requirements.txt"
  fi
fi

if [[ -f "${INSTALL_DIR}/package.json" ]]; then
  log "instalando dependências Node.js"
  if [[ -f "${INSTALL_DIR}/package-lock.json" ]]; then
    npm --prefix "${INSTALL_DIR}" ci --omit=dev
  else
    npm --prefix "${INSTALL_DIR}" install --omit=dev
  fi
fi

if [[ -f "${INSTALL_DIR}/bin/${APP_NAME}" ]]; then
  cp -f "${INSTALL_DIR}/bin/${APP_NAME}" "${BIN_PATH}"
elif [[ -f "${INSTALL_DIR}/${APP_NAME}" ]]; then
  cp -f "${INSTALL_DIR}/${APP_NAME}" "${BIN_PATH}"
elif [[ -f "${INSTALL_DIR}/main.py" ]]; then
  if [[ "${IS_TERMUX}" -eq 1 ]]; then
    PYTHON_CMD="python"
  else
    PYTHON_CMD="${INSTALL_DIR}/.venv/bin/python"
  fi
  cat > "${BIN_PATH}" <<EOF
#!/usr/bin/env bash
exec ${PYTHON_CMD@Q} ${INSTALL_DIR@Q}/main.py "\$@"
EOF
else
  cat > "${BIN_PATH}" <<EOF
#!/usr/bin/env bash
printf '%s\\n' 'Winlux instalado em ${INSTALL_DIR}. Adicione o executável do projeto e execute novamente o instalador.'
EOF
fi
chmod 0755 "${BIN_PATH}"

log "instalação concluída"
log "arquivos: ${INSTALL_DIR}"
log "comando: ${BIN_PATH}"
