#!/usr/bin/env bash
# Script to check and update CSS paths in HTML files

# Set colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Checking HTML files for CSS references...${NC}"

# Check Admin HTML files
echo -e "\n${GREEN}Checking Admin HTML files:${NC}"
grep -r "link.*css" ./Admin/*.html

# Check Student HTML files
echo -e "\n${GREEN}Checking Student HTML files:${NC}"
grep -r "link.*css" ./Student/*.html

echo -e "\n${YELLOW}If you need to update CSS paths:${NC}"
echo -e "${GREEN}For /css/tailwind.css path:${NC}"
echo "  Make sure your HTML files reference: <link href=\"/css/tailwind.css\" rel=\"stylesheet\">"

echo -e "\n${GREEN}For local style.css path:${NC}"
echo "  Make sure your HTML files reference: <link href=\"style.css\" rel=\"stylesheet\">"

echo -e "\n${YELLOW}To update all HTML files automatically, run:${NC}"
echo "  find ./Admin -name \"*.html\" -exec sed -i 's|href=\"[^\"]*style.css\"|href=\"/css/tailwind.css\"|g' {} \\;"
echo "  find ./Student -name \"*.html\" -exec sed -i 's|href=\"[^\"]*style.css\"|href=\"/css/tailwind.css\"|g' {} \\;"
