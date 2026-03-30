#!/bin/bash
# =============================================================================
# Lint all Helm values and fleet.yaml files
# =============================================================================
# Usage: ./scripts/lint.sh
# =============================================================================

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}🔍 Linting Fleet Repository...${NC}"

ERRORS=0

# Validate all YAML files
echo -e "\n${YELLOW}Validating YAML syntax...${NC}"
find . -name "*.yaml" -o -name "*.yml" | while read -r file; do
  if ! python3 -c "import yaml; yaml.safe_load(open('$file'))" 2>/dev/null; then
    echo -e "  ${RED}✗ $file${NC}"
    ERRORS=$((ERRORS + 1))
  else
    echo -e "  ${GREEN}✓ $file${NC}"
  fi
done

# Check for common issues
echo -e "\n${YELLOW}Checking for common issues...${NC}"

# Ensure all fleet.yaml have defaultNamespace
for fleet in $(find . -name "fleet.yaml" -not -path "./.git/*"); do
  if ! grep -q "defaultNamespace" "$fleet"; then
    echo -e "  ${RED}✗ Missing defaultNamespace: $fleet${NC}"
    ERRORS=$((ERRORS + 1))
  fi
done

# Ensure no plaintext passwords (only CHANGE_ME placeholders or sealed secrets)
PLAIN_PASS=$(grep -rnE "password:\s+[a-zA-Z0-9]+" --include="*.yaml" . | grep -v "CHANGE_ME" | grep -v "secretKeyRef" | grep -v '\$\{' || true)
if [ -n "$PLAIN_PASS" ]; then
  echo -e "  ${RED}✗ Plaintext passwords found:${NC}"
  echo "$PLAIN_PASS"
  ERRORS=$((ERRORS + 1))
fi

if [ $ERRORS -eq 0 ]; then
  echo -e "\n${GREEN}✅ All checks passed!${NC}"
else
  echo -e "\n${RED}❌ $ERRORS errors found${NC}"
  exit 1
fi
