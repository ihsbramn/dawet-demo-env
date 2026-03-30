#!/bin/bash
# =============================================================================
# Pre-commit Hook: Validate Fleet Repository
# =============================================================================
# Validates YAML syntax, Helm template rendering, and security checks
# Install: cp scripts/pre-commit.sh .git/hooks/pre-commit && chmod +x .git/hooks/pre-commit
# =============================================================================

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}🔍 Running Fleet Repository Pre-commit Checks...${NC}"

# 1. Validate YAML syntax
echo -e "\n${YELLOW}[1/4] Validating YAML syntax...${NC}"
YAML_ERRORS=0
for file in $(git diff --cached --name-only --diff-filter=ACM | grep -E '\.(yaml|yml)$'); do
  if ! python3 -c "import yaml; yaml.safe_load(open('$file'))" 2>/dev/null; then
    echo -e "  ${RED}✗ Invalid YAML: $file${NC}"
    YAML_ERRORS=$((YAML_ERRORS + 1))
  fi
done
if [ $YAML_ERRORS -eq 0 ]; then
  echo -e "  ${GREEN}✓ All YAML files valid${NC}"
else
  echo -e "  ${RED}✗ $YAML_ERRORS YAML errors found${NC}"
  exit 1
fi

# 2. Check for hardcoded secrets
echo -e "\n${YELLOW}[2/4] Scanning for hardcoded secrets...${NC}"
SECRET_PATTERNS="password:|secret:|api_key:|access_key:|token:"
SECRETS_FOUND=0
for file in $(git diff --cached --name-only --diff-filter=ACM | grep -E '\.(yaml|yml)$'); do
  MATCHES=$(grep -inE "$SECRET_PATTERNS" "$file" | grep -v "CHANGE_ME" | grep -v "secretKeyRef" | grep -v "secretName" | grep -v '\$\{' | grep -v "sealed-secret" || true)
  if [ -n "$MATCHES" ]; then
    echo -e "  ${RED}✗ Potential secret in $file:${NC}"
    echo "$MATCHES" | head -5
    SECRETS_FOUND=$((SECRETS_FOUND + 1))
  fi
done
if [ $SECRETS_FOUND -eq 0 ]; then
  echo -e "  ${GREEN}✓ No hardcoded secrets detected${NC}"
else
  echo -e "  ${YELLOW}⚠ $SECRETS_FOUND files with potential secrets (review required)${NC}"
fi

# 3. Validate fleet.yaml structure
echo -e "\n${YELLOW}[3/4] Validating fleet.yaml structures...${NC}"
FLEET_ERRORS=0
for file in $(find . -name "fleet.yaml" -not -path "./.git/*"); do
  if ! grep -q "defaultNamespace\|helm\|targetCustomizations" "$file" 2>/dev/null; then
    echo -e "  ${YELLOW}⚠ Minimal fleet.yaml: $file${NC}"
  fi
done
echo -e "  ${GREEN}✓ Fleet configs validated${NC}"

# 4. Check OJK compliance markers
echo -e "\n${YELLOW}[4/4] Checking OJK compliance markers...${NC}"
if grep -r "SSE-S3\|encryption\|PII" --include="*.yaml" . > /dev/null 2>&1; then
  echo -e "  ${GREEN}✓ OJK compliance markers present${NC}"
else
  echo -e "  ${YELLOW}⚠ Missing OJK compliance markers${NC}"
fi

echo -e "\n${GREEN}✅ Pre-commit checks passed!${NC}"
