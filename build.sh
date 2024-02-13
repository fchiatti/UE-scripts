#!/usr/bin/env bash

# CLI utility for quickly compile a ue5 project. Requires ue4cli https://docs.adamrehn.com/ue4cli/.
#
# ./run -h for the help menu
#

# Maintainer: Francesco Chiatti <chiattif@gmail.com>

#check ue4cli
hash ue4 2>/dev/null || { echo >&2 "ue4cli must be installed. Please install it with: pip install ue4cli"; exit 1; }

#colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# build
echo "                            ┌─────────────────────────────┐"
echo "                            │ Project compilation Started │"
echo "                            └─────────────────────────────┘"

set -o pipefail; ue4 build DebugGame -noubtmakefiles -nohotreload | grep -E 'error:|] Compile |] Link |Target is up to date|Total execution time: ';
if [[ "$?" -eq "0" ]]; then
    echo -e "${GREEN}                            ┌─────────────────────────────┐ ${NC}" 
    echo -e "${GREEN}                            │    Compilation succeeded    │ ${NC}" 
    echo -e "${GREEN}                            └─────────────────────────────┘ ${NC}" 
    spd-say "build completed"
    #play ./success-fanfare-trumpets-6185.mp3
    exit 0
fi
    echo -e "${RED}                           ┌──────────────────────────────┐ ${NC}" 
    echo -e "${RED}                           │      Compilation failed      │ ${NC}" 
    echo -e "${RED}                           └──────────────────────────────┘ ${NC}"
    spd-say "build failed"
    exit 1 
    
