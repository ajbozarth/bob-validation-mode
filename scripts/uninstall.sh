#!/usr/bin/env bash
# uninstall.sh — Remove bob-validation-mode from the current user's Bob installation.
#
# Usage:
#   ./scripts/uninstall.sh

set -euo pipefail

# ── Colours ───────────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BOLD='\033[1m'
RESET='\033[0m'

info()    { echo -e "  ${GREEN}✔${RESET}  $*"; }
warn()    { echo -e "  ${YELLOW}!${RESET}  $*"; }
section() { echo -e "\n${BOLD}$*${RESET}"; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

BOB_SKILLS_DIR="${HOME}/.bob/skills"
CUSTOM_MODES_FILE="${HOME}/.bob/settings/custom_modes.yaml"
MCP_JSON_FILE="${HOME}/.bob/settings/mcp.json"
MCP_SERVER_ENTRY="bob-validation"

# ── Step 1: Remove installed skills ──────────────────────────────────────────
section "Step 1/3 — Removing installed skills..."

for skill_dir in "${REPO_ROOT}/.bob/skills"/*/; do
  skill_name="$(basename "${skill_dir}")"
  target="${BOB_SKILLS_DIR}/${skill_name}"

  if [[ -L "${target}" ]]; then
    # Legacy symlink from an older install
    rm "${target}"
    info "Removed symlink: ${skill_name}"
  elif [[ -d "${target}" ]]; then
    rm -rf "${target}"
    info "Removed: ${skill_name}"
  else
    warn "Skipped ${skill_name}: not found at ${target}"
  fi
done

# ── Step 2: Remove mode from custom_modes.yaml ───────────────────────────────
section "Step 2/3 — Removing mode..."

if [[ ! -f "${CUSTOM_MODES_FILE}" ]]; then
  warn "custom_modes.yaml not found — nothing to do"
elif ! grep -q "slug: bob-validation" "${CUSTOM_MODES_FILE}" 2>/dev/null; then
  warn "Mode 'bob-validation' not found in ${CUSTOM_MODES_FILE} — nothing to do"
else
  # Remove the mode block. The block starts at "  - slug: bob-validation" and
  # ends just before the next "  - slug:" entry (or end of file).
  # awk: suppress lines between (and including) the start marker and the next entry.
  awk '
    /^  - slug: bob-validation/ { skip=1; next }
    /^  - slug:/ { skip=0 }
    skip { next }
    { print }
  ' "${CUSTOM_MODES_FILE}" > "${CUSTOM_MODES_FILE}.tmp"

  # If the result has only the header line, restore the compact empty-list form
  if ! grep -q "^  - slug:" "${CUSTOM_MODES_FILE}.tmp"; then
    echo "customModes: []" > "${CUSTOM_MODES_FILE}"
    rm "${CUSTOM_MODES_FILE}.tmp"
  else
    mv "${CUSTOM_MODES_FILE}.tmp" "${CUSTOM_MODES_FILE}"
  fi

  info "Mode 'bob-validation' removed from ${CUSTOM_MODES_FILE}"
fi

# ── Step 3: Remove MCP server entry from mcp.json ────────────────────────────
section "Step 3/3 — Removing MCP server registration..."

if [[ ! -f "${MCP_JSON_FILE}" ]]; then
  warn "mcp.json not found — nothing to do"
else
  MCP_RESULT=$(node -e "
const fs     = require('fs');
const config = JSON.parse(fs.readFileSync('${MCP_JSON_FILE}', 'utf8'));
if (!config.mcpServers || !config.mcpServers['${MCP_SERVER_ENTRY}']) {
  process.stdout.write('absent');
} else {
  delete config.mcpServers['${MCP_SERVER_ENTRY}'];
  fs.writeFileSync('${MCP_JSON_FILE}', JSON.stringify(config, null, 2) + '\n');
  process.stdout.write('removed');
}
")

  if [[ "${MCP_RESULT}" == "absent" ]]; then
    warn "MCP server '${MCP_SERVER_ENTRY}' not found in ${MCP_JSON_FILE} — nothing to do"
  else
    info "MCP server '${MCP_SERVER_ENTRY}' removed from ${MCP_JSON_FILE}"
  fi
fi

# ── Done ──────────────────────────────────────────────────────────────────────
echo ""
echo -e "${BOLD}Uninstall complete.${RESET}"
echo ""
echo "  Restart Bob to deactivate the mode and MCP server."
echo "  The cloned repository at ${REPO_ROOT} was not deleted."
echo ""
