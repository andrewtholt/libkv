#!/usr/bin/env bash
#
# install.sh - Install script for libkv shared library and headers
#

set -euo pipefail

# Determine repository root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "${SCRIPT_DIR}"

# Defaults
PREFIX="${PREFIX:-/usr/local}"
LIBDIR=""
INCLUDEDIR=""
DESTDIR="${DESTDIR:-}"
UNINSTALL=0
BUILD=1
DRY_RUN=0

usage() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Install or uninstall libkv shared library and headers.

Options:
  -p, --prefix <dir>       Base installation directory (default: /usr/local)
      --libdir <dir>       Directory to install library into (default: <prefix>/lib)
      --includedir <dir>   Directory to install header into (default: <prefix>/include)
      --destdir <dir>      Staging directory prepended to install paths (default: empty)
  -d, --dry-run            Show what actions would be performed without executing them
  -u, --uninstall          Uninstall libkv instead of installing
      --no-build           Do not run 'make libkv.so' before installing
  -h, --help               Display this help message and exit

Environment Variables:
  PREFIX       Alternative way to specify --prefix (default: /usr/local)
  LIBDIR       Alternative way to specify --libdir
  INCLUDEDIR   Alternative way to specify --includedir
  DESTDIR      Alternative way to specify --destdir

Examples:
  sudo ./install.sh
  ./install.sh -d
  ./install.sh --prefix "\$HOME/.local" -d
  ./install.sh --prefix "\$HOME/.local"
  sudo ./install.sh --uninstall
EOF
}

# Parse command line options
while [ $# -gt 0 ]; do
    case "$1" in
        -p|--prefix)
            if [ -z "${2:-}" ]; then
                echo "Error: $1 requires a directory argument." >&2
                exit 1
            fi
            PREFIX="$2"
            shift 2
            ;;
        --prefix=*)
            PREFIX="${1#*=}"
            shift 1
            ;;
        --libdir)
            if [ -z "${2:-}" ]; then
                echo "Error: $1 requires a directory argument." >&2
                exit 1
            fi
            LIBDIR="$2"
            shift 2
            ;;
        --libdir=*)
            LIBDIR="${1#*=}"
            shift 1
            ;;
        --includedir)
            if [ -z "${2:-}" ]; then
                echo "Error: $1 requires a directory argument." >&2
                exit 1
            fi
            INCLUDEDIR="$2"
            shift 2
            ;;
        --includedir=*)
            INCLUDEDIR="${1#*=}"
            shift 1
            ;;
        --destdir)
            if [ -z "${2:-}" ]; then
                echo "Error: $1 requires a directory argument." >&2
                exit 1
            fi
            DESTDIR="$2"
            shift 2
            ;;
        --destdir=*)
            DESTDIR="${1#*=}"
            shift 1
            ;;
        -d|--dry-run)
            DRY_RUN=1
            shift 1
            ;;
        -u|--uninstall)
            UNINSTALL=1
            shift 1
            ;;
        -du|-ud)
            DRY_RUN=1
            UNINSTALL=1
            shift 1
            ;;
        --no-build)
            BUILD=0
            shift 1
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo "Error: Unknown option '$1'" >&2
            echo "Use --help for usage details." >&2
            exit 1
            ;;
    esac
done

# Resolve default directories if not explicitly provided
if [ -z "${LIBDIR}" ]; then
    LIBDIR="${PREFIX}/lib"
fi
if [ -z "${INCLUDEDIR}" ]; then
    INCLUDEDIR="${PREFIX}/include"
fi

# Apply DESTDIR prefix for staged installs / packaging
TARGET_LIBDIR="${DESTDIR}${LIBDIR}"
TARGET_INCLUDEDIR="${DESTDIR}${INCLUDEDIR}"

# Helper to check write permissions
can_write_to() {
    local target="$1"
    local dir="$target"
    while [ ! -d "$dir" ] && [ "$dir" != "/" ] && [ "$dir" != "." ]; do
        dir="$(dirname "$dir")"
    done
    [ -w "$dir" ]
}

# Helper to run ldconfig if appropriate
update_ldconfig() {
    local ldconfig_cmd=""
    if command -v ldconfig >/dev/null 2>&1; then
        ldconfig_cmd="ldconfig"
    elif [ -x /sbin/ldconfig ]; then
        ldconfig_cmd="/sbin/ldconfig"
    elif [ -x /usr/sbin/ldconfig ]; then
        ldconfig_cmd="/usr/sbin/ldconfig"
    fi

    if [ -n "$ldconfig_cmd" ]; then
        if [ "$(id -u)" -eq 0 ]; then
            echo "Updating dynamic linker cache ($ldconfig_cmd)..."
            "$ldconfig_cmd" || true
        elif sudo -n true >/dev/null 2>&1; then
            echo "Updating dynamic linker cache (sudo $ldconfig_cmd)..."
            sudo "$ldconfig_cmd" || true
        fi
    fi
}

# Uninstall workflow
if [ "${UNINSTALL}" -eq 1 ]; then
    if [ "${DRY_RUN}" -eq 1 ]; then
        echo "[DRY-RUN] Simulating uninstallation of libkv..."
        installed_files=0
        if [ -e "${TARGET_LIBDIR}/libkv.so" ]; then
            echo "  [DRY-RUN] Would remove: ${TARGET_LIBDIR}/libkv.so"
            installed_files=$((installed_files + 1))
        fi
        if [ -e "${TARGET_INCLUDEDIR}/kv.h" ]; then
            echo "  [DRY-RUN] Would remove: ${TARGET_INCLUDEDIR}/kv.h"
            installed_files=$((installed_files + 1))
        fi
        if [ "${installed_files}" -eq 0 ]; then
            echo "  [DRY-RUN] No installed libkv files found in ${TARGET_LIBDIR} or ${TARGET_INCLUDEDIR}."
        else
            echo "  [DRY-RUN] Would update dynamic linker cache (ldconfig)"
        fi
        echo "[DRY-RUN] Uninstallation simulation complete. No files were removed."
        exit 0
    fi

    echo "Uninstalling libkv..."

    installed_files=0

    if [ -f "${TARGET_LIBDIR}/libkv.so" ]; then
        if [ ! -w "${TARGET_LIBDIR}/libkv.so" ] && ! can_write_to "${TARGET_LIBDIR}"; then
            echo "Error: Insufficient permissions to remove ${TARGET_LIBDIR}/libkv.so" >&2
            echo "Please run with sudo: sudo $0 --uninstall" >&2
            exit 1
        fi
        rm -f "${TARGET_LIBDIR}/libkv.so"
        echo "  [REMOVED] ${TARGET_LIBDIR}/libkv.so"
        installed_files=$((installed_files + 1))
    fi

    if [ -f "${TARGET_INCLUDEDIR}/kv.h" ]; then
        if [ ! -w "${TARGET_INCLUDEDIR}/kv.h" ] && ! can_write_to "${TARGET_INCLUDEDIR}"; then
            echo "Error: Insufficient permissions to remove ${TARGET_INCLUDEDIR}/kv.h" >&2
            echo "Please run with sudo: sudo $0 --uninstall" >&2
            exit 1
        fi
        rm -f "${TARGET_INCLUDEDIR}/kv.h"
        echo "  [REMOVED] ${TARGET_INCLUDEDIR}/kv.h"
        installed_files=$((installed_files + 1))
    fi

    if [ "${installed_files}" -eq 0 ]; then
        echo "No installed libkv files found in ${TARGET_LIBDIR} or ${TARGET_INCLUDEDIR}."
    else
        update_ldconfig
        echo "Uninstallation complete."
    fi
    exit 0
fi

# Install workflow
if [ "${BUILD}" -eq 1 ]; then
    if [ "${DRY_RUN}" -eq 1 ]; then
        echo "[DRY-RUN] Would check/build libkv.so ('make libkv.so')."
    else
        echo "Ensuring libkv.so is built..."
        if ! make libkv.so; then
            echo "Error: Build failed." >&2
            exit 1
        fi
    fi
fi

if [ "${DRY_RUN}" -eq 0 ] && [ ! -f "libkv.so" ]; then
    echo "Error: 'libkv.so' not found. Run 'make libkv.so' or run without --no-build." >&2
    exit 1
fi

if [ ! -f "kv.h" ]; then
    echo "Error: 'kv.h' not found in $(pwd)." >&2
    exit 1
fi

# Check permissions before attempting installation
if ! can_write_to "${TARGET_LIBDIR}" || ! can_write_to "${TARGET_INCLUDEDIR}"; then
    if [ "${DRY_RUN}" -eq 1 ]; then
        echo "[DRY-RUN] Note: Target directory is not currently writable by $(whoami)."
        echo "[DRY-RUN] (Actual installation will require elevated privileges, e.g. sudo $0)"
    else
        echo "Error: Insufficient permissions to install into destination directories." >&2
        if ! can_write_to "${TARGET_LIBDIR}"; then
            echo "  - Cannot write to ${TARGET_LIBDIR}" >&2
        fi
        if ! can_write_to "${TARGET_INCLUDEDIR}"; then
            echo "  - Cannot write to ${TARGET_INCLUDEDIR}" >&2
        fi
        echo "" >&2
        echo "Please re-run with sudo:" >&2
        echo "  sudo $0" >&2
        echo "" >&2
        echo "Or specify a writable user directory with --prefix:" >&2
        echo "  $0 --prefix \"\$HOME/.local\"" >&2
        exit 1
    fi
fi

if [ "${DRY_RUN}" -eq 1 ]; then
    echo "[DRY-RUN] Simulating installation of libkv..."
    echo "  Prefix:     ${PREFIX}"
    echo "  Library:    ${TARGET_LIBDIR}/libkv.so"
    echo "  Header:     ${TARGET_INCLUDEDIR}/kv.h"
    [ -n "${DESTDIR}" ] && echo "  DestDir:    ${DESTDIR}"
    echo ""
    echo "  [DRY-RUN] Would create directory: ${TARGET_LIBDIR}"
    echo "  [DRY-RUN] Would create directory: ${TARGET_INCLUDEDIR}"
    echo "  [DRY-RUN] Would install: libkv.so -> ${TARGET_LIBDIR}/libkv.so (mode 0755)"
    echo "  [DRY-RUN] Would install: kv.h -> ${TARGET_INCLUDEDIR}/kv.h (mode 0644)"
    echo "  [DRY-RUN] Would update dynamic linker cache (ldconfig)"
    echo ""
    echo "[DRY-RUN] Installation simulation complete. No files were modified."
else
    echo "Installing libkv..."
    echo "  Prefix:     ${PREFIX}"
    echo "  Library:    ${TARGET_LIBDIR}/libkv.so"
    echo "  Header:     ${TARGET_INCLUDEDIR}/kv.h"
    [ -n "${DESTDIR}" ] && echo "  DestDir:    ${DESTDIR}"

    mkdir -p "${TARGET_LIBDIR}"
    mkdir -p "${TARGET_INCLUDEDIR}"

    install -m 0755 libkv.so "${TARGET_LIBDIR}/libkv.so"
    install -m 0644 kv.h "${TARGET_INCLUDEDIR}/kv.h"

    echo "  [INSTALLED] ${TARGET_LIBDIR}/libkv.so"
    echo "  [INSTALLED] ${TARGET_INCLUDEDIR}/kv.h"

    update_ldconfig

    echo "Installation complete!"
fi

if [ "${PREFIX}" != "/usr" ] && [ "${PREFIX}" != "/usr/local" ]; then
    cat <<EOF

Note: Since libkv was configured for a non-standard location (${PREFIX}), you may need to:
1. Add the library path to LD_LIBRARY_PATH at runtime:
   export LD_LIBRARY_PATH="${LIBDIR}:\${LD_LIBRARY_PATH:-}"

2. Specify include and library paths when compiling code:
   gcc -I"${INCLUDEDIR}" main.c -L"${LIBDIR}" -lkv -o my_program
EOF
fi
