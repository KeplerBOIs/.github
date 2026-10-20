#!/usr/bin/env bash
# Set up a KeplerBOIs workspace: clone the project's repos side by side and
# install them, editable, into one shared virtual environment with one Jupyter
# kernel.  Safe to re-run: existing clones are left as they are (not pulled)
# and the environment is updated in place.
#
# Usage:  bash setup_workspace.sh [WORKSPACE]      (default: the current directory)
#         PYTHON=python3.12 bash setup_workspace.sh   to choose the interpreter

set -euo pipefail

WORKSPACE=${1:-.}
PYTHON=${PYTHON:-python3}
ORG=https://github.com/KeplerBOIs
KERNEL_NAME=keplerbois
KERNEL_DISPLAY="KeplerBOIs (.venv)"

# repo directory -> clone URL
REPOS=(
    ".github=$ORG/.github.git"
    "kbonus-data=$ORG/kbonus-data.git"
    "stellar-characterization=$ORG/stellar-characterization.git"
    "preconditioning=$ORG/preconditioning.git"
    "transit-search=$ORG/transit-search.git"
    "transit-vetting=$ORG/transit-vetting.git"
    "transit-modelling=$ORG/transit-modelling.git"
    "injections=$ORG/injections.git"
    "exoplanet-catalogues=$ORG/exoplanet-catalogues.git"
    "demographics=$ORG/demographics.git"
    "Kepler-BOI1b=$ORG/Kepler-BOI1b.git"
    "bls_cuda=https://github.com/jasonfrowe/bls_cuda.git"
)
# repos installed editable into the environment, in dependency order
# (directory[extras]); others are cloned only
INSTALL=(
    "bls_cuda" "kbonus-data[test]" "stellar-characterization[test]" "preconditioning"
    "transit-search[test]" "transit-vetting[test]" "transit-modelling[test]"
    "injections[test]" "exoplanet-catalogues[test]" "demographics[test]"
)
# needed by notebooks rather than by any one package; exotic-ld imports
# pkg_resources, which setuptools 81 and later no longer provide
EXTRAS=(ipykernel matplotlib exotic-ld h5py pytest "setuptools<81")

if ! "$PYTHON" -c 'import sys; sys.exit(sys.version_info < (3, 10))' 2>/dev/null; then
    echo "error: $PYTHON is missing or older than Python 3.10; set PYTHON=..." >&2
    exit 1
fi

mkdir -p "$WORKSPACE"
cd "$WORKSPACE"
echo "workspace: $(pwd)"

missing=()
for entry in "${REPOS[@]}"; do
    dir=${entry%%=*}
    url=${entry#*=}
    if [ -d "$dir/.git" ]; then
        echo "have   $dir"
    elif git clone --quiet "$url" "$dir"; then
        echo "cloned $dir"
    else
        # private repos need GitHub access, e.g. `gh auth login` then `gh auth setup-git`
        echo "warning: could not clone $url; skipping $dir" >&2
        missing+=("$dir")
    fi
done

if [ ! -x .venv/bin/python ]; then
    echo "creating .venv with $("$PYTHON" --version)"
    "$PYTHON" -m venv .venv
fi
.venv/bin/python -m pip install --quiet --upgrade pip

args=()
for spec in "${INSTALL[@]}"; do
    dir=${spec%%[*}
    if [ -f "$dir/pyproject.toml" ] || [ -f "$dir/setup.py" ]; then
        args+=(-e "./$spec")
    elif [ -d "$dir" ]; then
        echo "warning: $dir has no pyproject.toml; not installed" >&2
    fi
done
echo "installing: ${args[*]} ${EXTRAS[*]}"
.venv/bin/python -m pip install --quiet "${args[@]}" "${EXTRAS[@]}"

.venv/bin/python -m ipykernel install --user --name "$KERNEL_NAME" --display-name "$KERNEL_DISPLAY" >/dev/null
echo "registered Jupyter kernel \"$KERNEL_DISPLAY\""

cat <<EOF

Done. Next:
  source $(pwd)/.venv/bin/activate
  export KBONUS_DATA_DIR=/path/to/kbonus   # the data directory, e.g. /opt/data2/rowe/kbonus
EOF
if [ ${#missing[@]} -gt 0 ]; then
    echo "Not cloned (check access, then re-run): ${missing[*]}"
fi
