# KeplerBOIs workspace guide

The KeplerBOIs repos are developed together: preconditioning, injections and
the BOI analyses all read light curves through kbonus-data and fit transits
with pytfit5. So we work in one **workspace**: the repos cloned side by side
in one folder and installed, editable, into **one shared virtual environment**
with one Jupyter kernel. A change in any repo is seen at once by all the
others, and there is one environment to keep up to date instead of one per
repo.

This repo (`KeplerBOIs/.github`) holds the setup script and this guide;
`profile/README.md` is the organization's front page.

## Layout

```
BOIs/                          the workspace (any name, not itself a git repo)
├── .venv/                     the shared environment
├── .github/                   this repo: setup_workspace.sh and this guide
├── kbonus-data/               reading and indexing KBonus-BKG light curves
├── stellar-characterization/  stellar parameters for every star
├── preconditioning/           detrending (systematics basis vectors)
├── transit-search/            matched-filter, BLS and single-event searches
├── transit-vetting/           flux- and pixel-level vetting
├── transit-modelling/         transit fits and posteriors
├── injections/                completeness and reliability tests
├── exoplanet-catalogues/      the BOI and long-period catalogues
├── demographics/              occurrence rates
├── Kepler-BOI1b/              the BOI-1b analysis (standalone result)
└── bls_cuda/                  pytfit5: TransitFit5 and BLS (jasonfrowe/bls_cuda)
```

| repo | installed as | import |
|---|---|---|
| [kbonus-data](https://github.com/KeplerBOIs/kbonus-data) | `kbonus-data` | `kbonus_data` |
| [stellar-characterization](https://github.com/KeplerBOIs/stellar-characterization) | `boi-stellar` | `boi_stellar` |
| [preconditioning](https://github.com/KeplerBOIs/preconditioning) | `preconditioning` (dependencies only so far) | |
| [transit-search](https://github.com/KeplerBOIs/transit-search) | `boi-search` | `boi_search` |
| [transit-vetting](https://github.com/KeplerBOIs/transit-vetting) | `boi-vetting` | `boi_vetting` |
| [transit-modelling](https://github.com/KeplerBOIs/transit-modelling) | `boi-modelling` | `boi_modelling` |
| [injections](https://github.com/KeplerBOIs/injections) | `boi-injections` | `boi_injections` |
| [exoplanet-catalogues](https://github.com/KeplerBOIs/exoplanet-catalogues) | `boi-catalogues` | `boi_catalogues` |
| [demographics](https://github.com/KeplerBOIs/demographics) | `boi-demographics` | `boi_demographics` |
| [bls_cuda](https://github.com/jasonfrowe/bls_cuda) | `pytfit5` | `pytfit5` |
| [Kepler-BOI1b](https://github.com/KeplerBOIs/Kepler-BOI1b) | not installed; a notebook | |

The light curves themselves (4.8 TB) are not in the workspace; they live in a
data directory found through `KBONUS_DATA_DIR` (see below).

## Setting up

You need Python 3.10 or newer, git, and access to the KeplerBOIs repos
(all but kbonus-data, Kepler-BOI1b and this one are private). The simplest way to give git
your GitHub access is the [GitHub CLI](https://cli.github.com/):

```sh
gh auth login
gh auth setup-git
```

Then make a workspace and run the script:

```sh
mkdir BOIs && cd BOIs
curl -O https://raw.githubusercontent.com/KeplerBOIs/.github/main/setup_workspace.sh
bash setup_workspace.sh
```

The script:

1. clones each repo that is not there yet (existing clones are left alone);
2. creates `.venv` (with `python3`; set `PYTHON=python3.12` to choose another);
3. installs every repo with a `pyproject.toml` editable (`pip install -e`),
   plus `ipykernel`, `matplotlib`, `exotic-ld`, `h5py`
   and `pytest`;
4. registers the Jupyter kernel **KeplerBOIs (.venv)**.

It is safe to re-run, and you should re-run it after a repo adds
dependencies or a new repo joins the workspace.

## Daily use

```sh
cd BOIs
source .venv/bin/activate
```

In VS Code or Jupyter, pick the **KeplerBOIs (.venv)** kernel for any
notebook in any of the repos. The kernel is registered per user, so if you set
up a second workspace, the most recent setup owns the kernel.

Tell kbonus-data where the light curves are, at the top of a script or
notebook:

```python
import os
os.environ["KBONUS_DATA_DIR"] = "/opt/data2/rowe/kbonus"   # our copy; use yours

import kbonus_data as kb
cq = kb.read_channel(5, 41)          # every star on channel 41 in quarter 5
```

or once in your shell profile: `export KBONUS_DATA_DIR=/opt/data2/rowe/kbonus`.
The kbonus-data README describes the data directory, its layout
(`catalogs/`, `index/`, `lcs/`, `logs/`) and how to download it.

Each repo is its own git repository: `git pull` in a repo to update it, and
commit, branch and open pull requests per repo as usual. To contribute from a
fork, clone your fork into the workspace folder under the repo's name before
running the script, or change the clone's `origin` afterwards.

## Adding a repo to the workspace

1. Give it a `pyproject.toml`. List other KeplerBOIs packages **by name
   only**:

   ```toml
   dependencies = ["kbonus-data", "numpy"]
   ```

   not `"kbonus-data @ git+https://github.com/..."`. A direct URL makes pip
   replace the workspace's editable copy with a frozen copy from GitHub, so
   changes you make in `../kbonus-data` would stop being seen.
   kbonus-data and pytfit5 are not on PyPI, so a repo's README should say to
   install them from GitHub first when it is used outside the workspace.
2. Check the package name is free on PyPI (`pip index versions <name>`) even
   if we never publish, so `pip` can never pull in someone else's package.
   That is why the packages are named `boi-<name>`: `injections` was taken.
3. Name its test files uniquely (`tests/test_boi_<name>.py`, not
   `tests/test_import.py`), so pytest can run every repo's tests together.
4. Add it to `REPOS` and, if it should be installed, `INSTALL` in
   `setup_workspace.sh`, and to the tables above.

A repo that needs versions of something that conflict with the rest (for
example a different CUDA stack) should get its own environment instead. So
should exact reproductions of a finished result: Kepler-BOI1b pins the
pytfit5 it was run with as a git submodule, and its README shows how to
rerun with exactly that version.
