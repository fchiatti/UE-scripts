#!/usr/bin/env bash

# CLI utility for quickly compile in DebugGame Editor and run tests from the command line.
#
# ./test -h for the help menu
#

# Maintainer: Francesco Chiatti <chiattif@gmail.com>
# Maintainer: Paolo Galeone <paolo@zuru.tech>

check=$(find -type f -name "*.uproject" | wc -l)
if [[ $check -eq 0 ]]; then
    echo ".uproject not found in $PWD"
    exit 1
elif [[ $check -ne 1 ]]; then
    echo "Ambiguous .uproject file in $PWD"
    exit 1
fi

hash ue4 2>/dev/null || { echo >&2 "ue4cli must be installed. Please install it with: pip install ue4cli"; exit 1; }


grep -qEi "(MINGW|Microsoft|WSL)" /proc/version &> /dev/null
windows=$(echo "$?")

script_path=$(readlink -f "$0")
script_folder=${script_path%/*}
ue4root=$(ue4 root 2>/dev/null)
dcpath="$PWD"
uprojectname=$(find -type f -name "*.uproject")
uprojectpath="${dcpath}/${uprojectname}"
logsfolder="${dcpath}/Saved/Logs/"
if [ "$windows" -eq "0" ]; then
    ue4path=$(cygpath "$ue4root")
    engineexepath="${ue4path}/Engine/Binaries/Win64/UnrealEditor-Win64-DebugGame-Cmd.exe"
else
    ue4path=$ue4root
    engineexepath="${ue4path}/Engine/Binaries/Linux/UnrealEditor-Linux-DebugGame-Cmd"
fi

tests=("BIM.Unit" "BIM.Integration" "BIM.UI") #by default run all the BIM tests

cmd=("$engineexepath" "$uprojectpath" -buildmachine -unattended -nopause -nosplash -nosound)

# -forcelogflush slows down on windows, but it looks like on windows the buffer at the end of the
# execution is flushed anyway (only once).
# On linux without this flag, the final buffer (before closing it) is not flushed and thus the output
# is truncated :<
if [ "$windows" -ne "0" ]; then
    cmd+=(-forcelogflush)
fi


#colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

userhi=0
while getopts "h b r o g t:" option
do
    case $option in
        h) # help
            echo "-h | for help"
            echo "-b | to build DebugGame Editor before running the tests"
            echo "-r | to run tests with rhi"
            echo "-o | to print output during tests execution"
            echo "-g | to run DC with -game flag (no PIE)"
            echo "-t | input string to specify the tests to execute. All the tests whose name constains the provided string will be executed. Empty string to execute no tests."
            exit ;;
        b) # build
            $script_folder/build.sh
            if [[ $? -ne 0 ]]; then
                echo -e "${RED}Aborting tests execution because compilation failed.${NC}" 
                exit 1 
            fi ;;
        r) # rhi
            userhi=1 ;;
        o) # output (filtered -stdout)
            cmd+=(-stdout) ;;
        g) # game
            echo -e "GAME IS ON!"
            cmd+=(-game) ;;
        t) # provide test names
            tests=("${OPTARG}")
            echo "Running only tests containing the string $OPTARG" ;;
        \?) # Invalid option
            echo "Error: Invalid arguments. Run -h to get help." ;;
    esac
done

if ((userhi == 0))
then
    cmd+=(-nullrhi)
fi

echo "                   ┌─────────────────────────────────────────────────┐"
echo "                   │      Running tests. This may take a while.      │"
echo "                   └─────────────────────────────────────────────────┘"
echo -e "${PURPLE}Engine path: $ue4path${NC}"
echo -e "${PURPLE}Dreamcatcher path: $dcpath${NC}"
echo -e "${PURPLE}Log output folder: $logsfolder${NC}"

rm -rf $logsfolder

#timestamp
start=$(date +%s)

for ((i = 0; i < ${#tests[@]}; i++)); do
    t="${tests[$i]}"
    logname="${t// /_}"
    testcmd=("${cmd[@]}" -ExecCmds="automation RunTests Now ${t}; ForceQuit" -log="logtests-${logname}.log")
    echo -e "${PURPLE}running command ${testcmd[@]}${NC}"
    "${testcmd[@]}" | grep -E "automation tests based on|Test Completed. Result" &
done
wait

#print execution time
end=$(date +%s)
totaltime=$((end-start))
echo "" #just a space
echo -e "${PURPLE}Total execution time: $totaltime seconds${NC}"

failures=0
for ((i = 0; i < ${#tests[@]}; i++)); do
    t="${tests[$i]}"
    #logs
    logfile="${logsfolder}logtests-${logname}.log"

    $script_folder/analyze_tests_results.sh -l "$logfile"
    if [[ $? -ne 0 ]]; then #failure
        exit 1 
    fi
done


#success
exit 0
