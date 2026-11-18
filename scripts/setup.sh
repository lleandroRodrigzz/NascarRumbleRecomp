#!/usr/bin/env bash
# Gera e compila o NASCAR Rumble Recompiled a partir do disco do proprio usuario.
# Uso: bash scripts/setup.sh "/caminho/para/NASCAR Rumble (USA).cue"
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

CUE="${1:-}"
if [[ -z "$CUE" || ! -f "$CUE" ]]; then
    echo "erro: informe o caminho do arquivo .cue do NASCAR Rumble (USA)." >&2
    echo "uso: bash scripts/setup.sh \"/caminho/NASCAR Rumble (USA).cue\"" >&2
    exit 1
fi
CUE="$(cd "$(dirname "$CUE")" && pwd)/$(basename "$CUE")"

# python3 no Windows costuma ser um atalho da Microsoft Store que nao funciona.
PY=""
for c in python3 python py; do
    if command -v "$c" >/dev/null 2>&1 && "$c" -c "import sys; sys.exit(sys.version_info < (3, 9))" >/dev/null 2>&1; then
        PY="$c"; break
    fi
done
if [[ -z "$PY" ]]; then
    echo "erro: Python 3.9+ nao encontrado. Instale com: winget install Python.Python.3.12" >&2
    exit 1
fi

echo "== [1/5] Baixando submodulos (psxrecomp + recomp-ui) =="
git submodule update --init --recursive

echo "== [2/5] Preparando o compilador (baixa o toolchain Clang na primeira vez, ~209 MB) =="
TC_BIN="$("$PY" -c "
import sys; from pathlib import Path
sys.path.insert(0, 'psxrecomp/tools')
import toolchain_pack as tp
print(tp.ensure_toolchain(Path('.').resolve(), download=True, log=lambda m: print(m, file=sys.stderr)))
" | tail -n 1 | tr -d '\r')"
if [[ -z "$TC_BIN" ]]; then
    echo "erro: nao foi possivel preparar o toolchain." >&2
    exit 1
fi
TC_BIN="$(cygpath -u "$TC_BIN" 2>/dev/null || echo "$TC_BIN")"
export PSXRECOMP_TOOLCHAIN_DIR="$(dirname "$TC_BIN")"
export PATH="$TC_BIN:$PATH"
echo "toolchain: $PSXRECOMP_TOOLCHAIN_DIR"

echo "== [3/5] Compilando o recompilador =="
bash psxrecomp/tools/ci/build_emitters.sh

echo "== [4/5] Gerando o codigo C a partir do seu disco =="
"$PY" psxrecomp/psxrecomp_cli.py generate --config game.toml --project-root . --disc "$CUE"

echo "== [5/5] Compilando o jogo =="
"$PY" psxrecomp/psxrecomp_cli.py rebuild --config game.toml --project-root . \
    --build-dir build-release --no-pgo

echo
echo "Pronto! Execute: build-release/NascarRumble_Recompiled.exe"
