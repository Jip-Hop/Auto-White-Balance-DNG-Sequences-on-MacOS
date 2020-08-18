#!/bin/bash

# GNU public license

# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the
# Free Software Foundation, Inc.,
# 51 Franklin Street, Fifth Floor,
# Boston, MA 02110-1301, USA.

# Config variables
nrOfFrameSamples=8

# Variables for terminal output formatting
bold=$(tput bold)
normal=$(tput sgr0)

# Uses dot as decimal separator
export LC_NUMERIC="C"

# Read the folders to process from a text file
IFS=$'\n' read -d '' -r -a folders < $1

# Cleanup if ran from tmp directory
if [[ "$0" == "/tmp"* ]]; then
    # Remove this script file
    rm -f -- "$0"
    # Remove input file
    rm -f $1
fi

# Install dependencies
dcrawInstalled=$(type -P dcraw)
exiv2Installed=$(type -P exiv2)

echo "${normal}"

if [[ $dcrawInstalled && $exiv2Installed ]]; then
    echo "Dependencies are installed."
else
    echo "You need dcraw ($([[ $dcrawInstalled ]] || echo "not ")installed) and exiv2 ($([[ $exiv2Installed ]] || echo "not ")installed)."
    echo "I can install it for you, OK?"
    read -e -p "Y or N? " yn
    if [[ "y" = "$yn" || "Y" = "$yn" ]]; then
        brewInstalled=$(type -P brew)
        if ! [[ brewInstalled ]]; then
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"
        fi
        brew install dcraw exiv2
    else
        echo "We need dcraw and exiv2. Stopping."
        exit
    fi
fi

nrOfFolders=${#folders[@]} # Number of elements in array
remainingFolders=$nrOfFolders
echo "${bold}Start processing $nrOfFolders folders.${normal}"
for d in "${folders[@]}"; do
    # Get all DNG files in current directory
    IFS=$'\n'
    files=($(find $d -name "*.dng" -type f ))

    nrOfFrames=${#files[@]}
    echo "Start processing $nrOfFrames frames."

    if ! (($nrOfFrames > 0)); then
        # Skip this folder if there are no DNG frames
        echo "Skip folder: $d."
        continue
    fi

    if ((nrOfFrameSamples > nrOfFrames)); then
        echo "Limit amount of samples to the number of frames."
        nrOfFrameSamples=$nrOfFrames
    fi

    echo "Taking $nrOfFrameSamples frame samples for Auto White Balance."

    stepSize=$(($nrOfFrames / $nrOfFrameSamples))

    currentStep=$stepSize                # Start here
    lastStep=$stepSize*$nrOfFrameSamples # End here
    typeset -i currentStep lastStep      # Declare these variables as integers

    averageMultipliers=(0 0 0 0)

    while ((currentStep <= lastStep)); do

        filePath=${files[currentStep - 1]} # -1 because array index starts at 0
        echo "AWB frame: $(basename -- $filePath)."
        dcrawOutput=$(dcraw -T -a -v -c $filePath 2>&1 | awk '/multipliers/ { print $2,$3,$4,$5; exit }')
        echo "Result of AWB: $dcrawOutput."

        # Split into new multipliers array
        IFS=' ' read -r -a multipliers <<<$dcrawOutput

        averageMultipliers[0]=$(echo ${averageMultipliers[0]}+${multipliers[0]} | bc -l)
        averageMultipliers[1]=$(echo ${averageMultipliers[1]}+${multipliers[1]} | bc -l)
        averageMultipliers[2]=$(echo ${averageMultipliers[2]}+${multipliers[2]} | bc -l)
        averageMultipliers[3]=$(echo ${averageMultipliers[3]}+${multipliers[3]} | bc -l)

        # Increment with step size
        currentStep=$(($currentStep + $stepSize))
    done

    # Average the summed up multipliers
    averageMultipliers[0]=$(echo ${averageMultipliers[0]}/$nrOfFrameSamples | bc -l)
    averageMultipliers[1]=$(echo ${averageMultipliers[1]}/$nrOfFrameSamples | bc -l)
    averageMultipliers[2]=$(echo ${averageMultipliers[2]}/$nrOfFrameSamples | bc -l)
    averageMultipliers[3]=$(echo ${averageMultipliers[3]}/$nrOfFrameSamples | bc -l)

    echo "Average multipliers: ${averageMultipliers[0]} ${averageMultipliers[1]} ${averageMultipliers[2]} ${averageMultipliers[3]}."

    vit_01=$(echo ${averageMultipliers[1]}/${averageMultipliers[0]} | bc -l)
    vit_02=$(echo ${averageMultipliers[3]}/${averageMultipliers[2]} | bc -l)

    # Multiply by 1000000
    vit_01=$(echo $vit_01*1000000 | bc)
    vit_02=$(echo $vit_02*1000000 | bc)

    # Round to an integer
    vit_01=$(printf "%.0f\n" "$vit_01")
    vit_02=$(printf "%.0f\n" "$vit_02")

    echo "Start applying WB to this DNG sequence..."
    # Apply the white balance value to all DNG files in parallel (amount of threads based on amount of CPU threads)
    printf '%s\0' "${files[@]}" | xargs -0 -P $(sysctl -n hw.ncpu) -n 1 exiv2 -M"set Exif.Image.AsShotNeutral Rational $vit_01/1000000 1/1 $vit_02/1000000"

    wait # Wait for the xargs process to finish
    echo "Done applying WB to this DNG sequence!"
    ((remainingFolders -= 1))
    echo "${bold}Folders remaining: $remainingFolders.${normal}"

done

echo "${bold}Done!${normal}"
