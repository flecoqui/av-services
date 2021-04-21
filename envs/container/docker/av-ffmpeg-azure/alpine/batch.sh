#!/bin/sh
##########################################################################################################################################################################################
#- Purpose: Script is used to handle the commands in the input json file 
#- Parameters are:
#- [-i] input-file - The input file, it can be local file or http url.
#- [-s] input-string - The input string, if set, option -i not required.
###########################################################################################################################################################################################
set -u
bashRoot="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cd "$bashRoot"
#######################################################
#- function used to print out script usage
#######################################################
function usage() {
    echo
    echo "Arguments:"
    echo -e " -i Sets the input fle path: local file or http url"
    echo -e " -s Sets the input string (json format)"
    echo
    echo "Example:"
    echo -e "bash batch.sh -i commands.json "
    echo -e "bash batch.sh -s '[{\"input\": \"/tempvol/input/camera-300s.mkv\",\"command\": \"ffmpeg -y -nostats -loglevel 0  -i \${inputFile} -codec copy \${outputFolder}/camera-300s.mp4\",\"output\": \"/tempvol/output\",\"log\": \"/tempvol/logs/log.txt\"}]' "
}
inputfilepath=""
inputstring=""
while getopts "i:s:hq" opt; do
    case $opt in
    i) inputfilepath="$OPTARG" ;;
    s) inputstring="$OPTARG" ;;
    :)
        echo "Error: -${OPTARG} requires a value"
        exit 1
        ;;
    *)
        usage
        exit 1
        ;;
    esac
done

# Validation
if [[ $# -eq 0 || -z $inputfilepath && -z $inputstring ]]; then
    echo "Required parameters are missing"
    usage
    exit 1
fi
# colors for formatting the ouput
YELLOW='\033[1;33m'
GREEN='\033[1;32m'
RED='\033[0;31m'
BLUE='\033[1;34m'
NC='\033[0m' # No Color

checkError() {
    if [ $? -ne 0 ]; then
        echo -e "${RED}\nAn error occured exiting from the current bash${NC}"
        exit 1
    fi
}
writeLog() {
    logUrl="$1"
    msg="$2"    
    
    localMsg="$(date -u +%Y/%m/%d-%H:%M:%S.%N) $msg"
    if [[ -z $logUrl ]]; then
        echo "$localMsg"
    else
        if [ "${logUrl:0:8}" = https:// ]; then
            echo "$localMsg" >> "$logUrl"
        else
            echo "$localMsg" >> "$logUrl"
        fi
    fi
}
getFileName() {
    resultUrlWithoutSAS="$(echo "$1" | cut -d'?' -f 1)"
    resultGetFileName="$(echo "${resultUrlWithoutSAS##*/}")"
    resultSasToken="$(echo "$1" | cut -d'?' -f 2)"
}
processCommand() {
    localInput="$1"
    localCommand="$2"
    localOutput="$3"
    localLog="$4"

    writeLog "$localLog" "Check input file: $localInput"
    if [ "${localInput:0:8}" = https:// ]; then
        getFileName $localInput
        inputFile="$resultGetFileName"
        writeLog "$localLog" "Downloading file: $inputFile"
        cmd="wget --quiet \"$localInput\" -O \"$inputFile\""
        eval "$cmd"
        checkError
        writeLog "$localLog" "Download of file $inputFile successful"
    else
        inputFile=$localInput
    fi
    if [ "${localOutput:0:8}" = https:// ]; then
        getFileName $localOutput
        outputFolder="$resultGetFileName"
        outputUrlWithoutSasToken="$resultUrlWithoutSAS"
        outputSasToken="$resultSasToken"
    else
        outputFolder=$localOutput
    fi
    if [[ -f "$inputFile" ]]; then
        writeLog "$localLog" "Check output folder: $outputFolder"
        if [[ ! -d "$outputFolder" ]]; then
            writeLog "$localLog" "Creating output folder: $outputFolder"
            mkdir "$outputFolder"
            checkError
            writeLog "$localLog" "Creation of folder $outputFolder successful"
        fi
        if [[ -d "$outputFolder" ]]; then
            writeLog "$localLog" "Preparing command: $localCommand"
            # the line below will replace "$inputFile" and "$outputFolder" 
            command=$(echo "$localCommand" | sed 's/${inputFile}/"$inputFile"/' | sed 's/${outputFolder}/"$outputFolder"/' )
            writeLog "$localLog" "Launching the command: $command"
            eval "$command"
            checkError
            writeLog "$localLog" "Command: $command successful"
            for file in "$outputFolder"/*; do
                if [[ -f $file ]]; then
                    writeLog "$localLog" "File $file created" 
                    if [ "${localOutput:0:8}" = https:// ]; then
                        fileWithoutFolder="$(echo "${file##*/}")"
                        destinationFile="$outputUrlWithoutSasToken/$fileWithoutFolder?$outputSasToken"
                        writeLog "$localLog" "Uploading file $file to $destinationFile" 
                        cmd="azcopy cp \"$file\" \"$destinationFile\""
                        eval "$cmd" > /dev/null
                        checkError
                        writeLog "$localLog" "File $file sucessfully uploaded" 
                        # if output file in the cloud remove local file
                        rm "$file"
                    fi
                fi
            done
        fi
    fi
    if [ "${localInput:0:8}" = https:// ]; then
        # if input file in the cloud remove local file
        rm $inputFile 
    fi    
}
if [[ -z "$inputstring" ]]; then
    if [ "${inputfilepath:0:8}" = https:// ]; then
        getFileName $inputfilepath
        inputfile="$resultGetFileName"
        cmd="wget --quiet \"$inputfilepath\" -O \"$inputFile\""
        eval "$cmd"
        checkError
    else
        inputfile=$inputfilepath
    fi
    inputstring=$(cat "$inputfile")
    echo "Batch processing file: $inputfile"
fi
echo "Batch processing content: $inputstring"

for row in $(echo "${inputstring}" | jq -r '.[] | @base64'); do
    _jq() {
     echo ${row} | base64 --decode | jq -r ${1}
    }

   input=$(_jq '.input')
   output=$(_jq '.output')
   command=$(_jq '.command')
   log=$(_jq '.log')
   writeLog "$log" "Processing command: \"$command\" with input: \"$input\" and output: \"$output\""
   processCommand "$input" "$command" "$output" "$log" 
done

exit 0

