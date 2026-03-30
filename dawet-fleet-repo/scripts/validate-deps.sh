#!/bin/bash
# =============================================================================
# Validate Fleet Repository Dependencies
# =============================================================================
# Checks that all dependsOn references in fleet.yaml files are resolvable
# Usage: ./scripts/validate-deps.sh
# =============================================================================

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}🔍 Validating Fleet Dependencies...${NC}"

# Collect all bundle labels
declare -A BUNDLES
while IFS= read -r file; do
  LABEL=$(grep -A1 "^labels:" "$file" 2>/dev/null | grep "bundle:" | awk '{print $2}' || true)
  if [ -n "$LABEL" ]; then
    BUNDLES[$LABEL]="$file"
    echo -e "  ${GREEN}📦 Bundle: $LABEL ($file)${NC}"
  fi
done < <(find . -name "fleet.yaml" -not -path "./.git/*")

echo ""

# Validate dependsOn references
ERRORS=0
while IFS= read -r file; do
  DEPS=$(grep -A2 "dependsOn" "$file" 2>/dev/null | grep "bundle:" | awk '{print $2}' || true)
  for dep in $DEPS; do
    if [ -z "${BUNDLES[$dep]+x}" ]; then
      echo -e "  ${RED}✗ Unresolvable dependency '$dep' in $file${NC}"
      ERRORS=$((ERRORS + 1))
    else
      echo -e "  ${GREEN}✓ $file -> $dep${NC}"
    fi
  done
done < <(find . -name "fleet.yaml" -not -path "./.git/*")

if [ $ERRORS -eq 0 ]; then
  echo -e "\n${GREEN}✅ All dependencies valid!${NC}"
else
  echo -e "\n${RED}❌ $ERRORS unresolvable dependencies found${NC}"
  exit 1
fi
