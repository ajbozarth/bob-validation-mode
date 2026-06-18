#!/usr/bin/env bash
# install.sh — Install bob-validation-mode into the current user's Bob installation.
#
# Usage:
#   ./scripts/install.sh
#
# What this does:
#   1. Builds the MCP server in place
#   2. Symlinks each skill into ~/.bob/skills/
#   3. Merges the mode entry into ~/.bob/settings/custom_modes.yaml
#   4. Merges the MCP server entry into ~/.bob/settings/mcp.json

set -euo pipefail

# ── Colours ───────────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BOLD='\033[1m'
RESET='\033[0m'

info()    { echo -e "  ${GREEN}✔${RESET}  $*"; }
warn()    { echo -e "  ${YELLOW}!${RESET}  $*"; }
error()   { echo -e "  ${RED}✖${RESET}  $*" >&2; }
section() { echo -e "\n${BOLD}$*${RESET}"; }

# ── Resolve repo root (script may be invoked from any directory) ──────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

BOB_SETTINGS_DIR="${HOME}/.bob/settings"
BOB_SKILLS_DIR="${HOME}/.bob/skills"
CUSTOM_MODES_FILE="${BOB_SETTINGS_DIR}/custom_modes.yaml"
MCP_JSON_FILE="${BOB_SETTINGS_DIR}/mcp.json"
MCP_SERVER_ENTRY="bob-validation"
MCP_SERVER_BUILD="${REPO_ROOT}/mcp-server/build/index.js"

# ── Pre-flight checks ─────────────────────────────────────────────────────────
section "Checking prerequisites..."

if ! command -v node &>/dev/null; then
  error "Node.js is not installed. Install Node.js 18+ and re-run."
  exit 1
fi

NODE_MAJOR=$(node -e "process.stdout.write(String(process.versions.node.split('.')[0]))")
if [[ "${NODE_MAJOR}" -lt 18 ]]; then
  error "Node.js 18+ is required (found $(node --version)). Please upgrade."
  exit 1
fi
info "Node.js $(node --version)"

if ! command -v npm &>/dev/null; then
  error "npm is not installed."
  exit 1
fi
info "npm $(npm --version)"

if [[ ! -d "${BOB_SETTINGS_DIR}" ]]; then
  error "Bob settings directory not found at ${BOB_SETTINGS_DIR}."
  error "Make sure Bob is installed before running this script."
  exit 1
fi
info "Bob settings directory found"

# ── Step 1: Build the MCP server ──────────────────────────────────────────────
section "Step 1/4 — Building MCP server..."

pushd "${REPO_ROOT}/mcp-server" > /dev/null
npm ci --silent
npm run build --silent
popd > /dev/null

if [[ ! -f "${MCP_SERVER_BUILD}" ]]; then
  error "Build produced no output at ${MCP_SERVER_BUILD}. Check mcp-server/tsconfig.json."
  exit 1
fi
info "Built → ${MCP_SERVER_BUILD}"

# ── Step 2: Copy skills ───────────────────────────────────────────────────────
section "Step 2/4 — Copying skills..."

mkdir -p "${BOB_SKILLS_DIR}"

for skill_dir in "${REPO_ROOT}/.bob/skills"/*/; do
  skill_name="$(basename "${skill_dir}")"
  target="${BOB_SKILLS_DIR}/${skill_name}"

  # Remove a stale symlink left over from a previous install
  if [[ -L "${target}" ]]; then
    rm "${target}"
  fi

  if [[ -d "${target}" ]]; then
    rm -rf "${target}"
    cp -r "${skill_dir}" "${target}"
    info "Updated: ${skill_name}"
  else
    cp -r "${skill_dir}" "${target}"
    info "Copied: ${skill_name}"
  fi
done

# ── Step 3: Merge mode into custom_modes.yaml ─────────────────────────────────
section "Step 3/4 — Registering mode..."

if [[ ! -f "${CUSTOM_MODES_FILE}" ]]; then
  echo "customModes: []" > "${CUSTOM_MODES_FILE}"
fi

if grep -q "slug: bob-validation" "${CUSTOM_MODES_FILE}" 2>/dev/null; then
  warn "Mode 'bob-validation' already registered — skipping"
else
  # Extract the mode block (everything from the first list entry onward)
  MODE_BLOCK=$(awk '/^  - slug:/{found=1} found{print}' "${REPO_ROOT}/.bob/custom_modes.yaml")

  # Replace empty-list shorthand so we can append a proper block entry
  if grep -q "^customModes: \[\]" "${CUSTOM_MODES_FILE}"; then
    echo "customModes:" > "${CUSTOM_MODES_FILE}"
  fi

  printf "%s\n" "${MODE_BLOCK}" >> "${CUSTOM_MODES_FILE}"
  info "Mode 'bob-validation' added to ${CUSTOM_MODES_FILE}"
fi

# ── Step 4: Merge MCP server entry into mcp.json ──────────────────────────────
section "Step 4/4 — Registering MCP server..."

if [[ ! -f "${MCP_JSON_FILE}" ]]; then
  echo '{"mcpServers":{}}' > "${MCP_JSON_FILE}"
fi

MCP_RESULT=$(node -e "
const fs    = require('fs');
const config = JSON.parse(fs.readFileSync('${MCP_JSON_FILE}', 'utf8'));
if (!config.mcpServers) config.mcpServers = {};
if (config.mcpServers['${MCP_SERVER_ENTRY}']) {
  process.stdout.write('exists');
} else {
  config.mcpServers['${MCP_SERVER_ENTRY}'] = { command: 'node', args: ['${MCP_SERVER_BUILD}'] };
  fs.writeFileSync('${MCP_JSON_FILE}', JSON.stringify(config, null, 2) + '\n');
  process.stdout.write('added');
}
")

if [[ "${MCP_RESULT}" == "exists" ]]; then
  warn "MCP server '${MCP_SERVER_ENTRY}' already registered — skipping"
else
  info "MCP server '${MCP_SERVER_ENTRY}' added to ${MCP_JSON_FILE}"
fi

# ── Done ──────────────────────────────────────────────────────────────────────
echo ""
echo -e "${BOLD}Installation complete.${RESET}"
echo ""
echo "  Restart Bob (start a new session) to activate:"
echo "    • Mode:       🧪 Bob Validation"
echo "    • MCP tools:  validate_mermaid, pylint_check"
echo "    • Skills:     bob-council, dellmify, requirements-cross-check, and 7 more"
echo ""
echo "  To update later:  git pull && ./scripts/install.sh"
echo "  To uninstall:     ./scripts/uninstall.sh"
echo ""
