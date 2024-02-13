#!/usr/bin/env bash

# CLI utility for quickly compile and run Dreamcatcher (in Debug Game Editor). Requires ue4cli https://docs.adamrehn.com/ue4cli/.
#
# ./run -h for the help menu
#

# Maintainer: Francesco Chiatti <chiattif@gmail.com>

check=$(find -type f -name "*.uproject" | wc -l)
if [[ $check -eq 0 ]]; then
    echo ".uproject not found in $PWD"
    exit 1
elif [[ $check -ne 1 ]]; then
    echo "Ambiguous .uproject file in $PWD"
    exit 1
fi

#check ue4cli
hash ue4 2>/dev/null || { echo >&2 "ue4cli must be installed. Please install it with: pip install ue4cli"; exit 1; }

#colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

grep -qEi "(MINGW|Microsoft|WSL)" /proc/version &> /dev/null
windows=$(echo "$?")

ue4root=$(ue4 root 2>/dev/null)
dcpath="$PWD"
uprojectname=$(find -type f -name "*.uproject")
uprojectpath="${dcpath}/${uprojectname}"
if [ "$windows" -eq "0" ]; then
    ue4path=$(cygpath "$ue4root")
    engineexepath="${ue4path}/Engine/Binaries/Win64/UnrealEditor-Win64-DebugGame.exe"
else
    ue4path=$ue4root
    engineexepath="${ue4path}/Engine/Binaries/Linux/UnrealEditor-Linux-DebugGame"
fi

# command to run DC
cmd=("$engineexepath" "$uprojectpath" -buildmachine -forcelogflush) #other useful flags: -unattended -nopause -nosplash -nowrite -silent

#compile
while getopts "h b g f:" option
do
    case $option in
        h) # help
            echo "-h | for help"
            echo "-b | to build in DebugGame Editor configuration before running DC"
            echo "-g | to run DC with -game flag (no Editor)"
            echo "-f | to grep a string in the UE logs during execution"
            exit ;;
        b) # build
            script_path=$(readlink -f "$0")
            script_folder=${script_path%/*}
            $script_folder/build.sh
            res="$?"
            if [[ $res -ne 0 ]]; then
                echo -e "${RED}Exiting...${NC}" 
                exit 1 
            fi ;;
        g) # game
            echo -e "GAME IS ON!"
            cmd+=(-game) ;;
        f) # filter
            filter_string=("${OPTARG}");;
        \?) # Invalid option
            echo "Error: Invalid arguments. Run -h to get help." ;;
    esac
done

# run Dreamcatcher
echo -e "${PURPLE}running command${NC} ${cmd[@]}${NC}"
"${cmd[@]}" | grep "$filter_string"

exit 1
