# initv8.sh - initialize dev directory for embedded V8 development
#
# 12/09/2019 rlb parameterize top directory name
# 11/22/2019 rlb might know better what I'm doing now.
# 11/19/2019 rlb half-assed start
#

# We have some expectations:
#
# embedv8               - directory containing all our dev work
#                         run me from this directory!
# embedv8/depot_tools   - some damn tool crud from Google we need
# embedv8/v8            - where we check out and build v8
# embedv8/src           - where we put OUR actual code
# embedv8/src/initv8.sh - this script

MYNAME="embedv8"     # in case I like a different name later
SAVE_DIR="${PWD}"    # remember directory where we started

# YesNo(): ask user yes/no question, return true if yes
function YesNo() {
    declare -l Answer    # make a lower-casing variable
    while true; do
        read -p "$1 [Y/n]: " Answer
        Answer=${Answer:-y}
        case "$Answer" in
            "y"|"yes"|"")
                Answer="y"
                break
                ;;
            "n"|"no")
                Answer="n"
                break
                ;;
        esac
    done
    if [ "$Answer" == "y" ]; then
        return 0
    else
        return 1
    fi
}


if [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
    echo "You have sourced me, so I will export"\
         "bash variables for development."
    EXIT_CMD="cd ${SAVE_DIR} ; return"
else
    set -e   # die on any error
    EXIT_CMD="cd ${SAVE_DIR} ; exit"
fi
EXIT="eval ${EXIT_CMD}"

#
# Sanity check: must be run from either "$MYNAME" or "$MYNAME/src"
#
MY_DIR="${PWD##*/}"
PARENT_PATH="${SAVE_DIR%/${MY_DIR}}"
PARENT_DIR="${PARENT_PATH##*/}"

# see if we are in a directory named "$MYNAME"
if [[ "$MY_DIR" == "src" ]] && [[ "$PARENT_DIR" == "$MYNAME" ]]; then
    cd ..
elif [[ "$MY_DIR" == "$MYNAME" ]]; then
    :
else
    echo "Please run me from inside either '$MYNAME' or '$MYNAME/src'"
    $EXIT
fi

#
# At this point, we are in the top directory we care about, named '$MYNAME'
#

DEPOT_PATH="$PWD/depot_tools"

# if we're being sourced
if [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
    # then user just wants us to export some bash variables
    
    if ! [[ ":${PATH}:" == *":${DEPOT_PATH}:" ]]; then
        echo export PATH=${PATH}:${DEPOT_PATH}
        export PATH=${PATH}:${DEPOT_PATH}
    else
        echo "${DEPOT_PATH} already in PATH"
    fi
    if alias gm 2>/dev/null >/dev/null ; then
        echo "'gm' alias already exists."
    else
        echo alias gm=${PWD}/v8/tools/dev/gm.py
        alias gm=${PWD}/v8/tools/dev/gm.py
    fi
    if alias clang 2>/dev/null >/dev/null ; then
        echo "'clang' alias already exists."
    else
        echo alias clang=${PWD}/v8/third_party/llvm-build/Release+Asserts/bin/clang++
        alias clang=${PWD}/v8/third_party/llvm-build/Release+Asserts/bin/clang++
    fi
    if alias v8gen 2>/dev/null >/dev/null ; then
        echo "'v8gen' alias already exists."
    else
        echo alias v8gen=${PWD}/v8/tools/dev/v8gen.py
        alias v8gen=${PWD}/v8/tools/dev/v8gen.py
    fi
    echo export ASAN_SYMBOLIZER_PATH="$PWD/v8/third_party/llvm-build/Release+Asserts/bin/llvm-symbolizer"
    export ASAN_SYMBOLIZER_PATH="$PWD/v8/third_party/llvm-build/Release+Asserts/bin/llvm-symbolizer"
    
    export LIBRARY_PATH=${PWD}/v8/out/debug/obj:${PWD}/v8/out/debug
    export INCLUDE=${PWD}/v8/third_party/llvm-build/Release+Asserts/lib/clang/10.0.0/include
    export CPLUS_INCLUDE_PATH=${PWD}/v8/include:${PWD}/v8/buildtools/third_party/libc++/trunk/include
    
    ${EXIT} 0
fi

# OK, we're not being "sourced", so user wants us to set up entire
# v8 dev environment

# instructions taken from: https://v8.dev/docs/source-code

GCLIENT="$DEPOT_PATH/gclient"
if ! [ -d "depot_tools" ]; then
    echo "installing $MYNAME/depot_tools"
    if [ -d .cipd ]; then
        if YesNo "OK to delete pre-existing .cipd directory?"; then
            echo rm -rf ./.cipd
            rm -rf ./.cipd
        fi
    fi
    if [ -f ".gclient" ] || [ -f ".gclient_entries" ]; then
        if YesNo "OK to delete pre-existing .gclient* files?"; then
            rm -f ./.gclient*
        fi
    fi
    
    echo git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git
    git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git
    echo "Finished: installing $MYNAME/depot_tools"

    # have to add it to PATH for some tools we need to work
    if ! [[ ":${PATH}:" == *":${DEPOT_PATH}:" ]]; then
        echo export PATH=${PATH}:${DEPOT_PATH}
        export PATH=${PATH}:${DEPOT_PATH}
    fi

    echo "Now update depot_tools. (why? I dunno)"
    echo $GCLIENT
    $GCLIENT 
else
    echo "updating depot_tools"
    if YesNo "Check for depot_tools updates?"; then
        echo $GCLIENT sync
        $GCLIENT sync
    fi
fi


# OK, now deal with v8
# 
if ! [ -d "v8" ]; then
    echo "v8 dir doesn't exist. Going to try to load latest version."
    $DEPOT_PATH/fetch v8
    if ! [ -d "v8" ]; then
        echo "v8 directory still doesn't exist,"\
             "not sure what went wrong..."
        ${EXIT} 1
    fi
fi

pushd v8

# if YesNo  "v8 dir exists -- do you want me to update the checkout?"; then
#     Branch=
#     while IFS= read -r line; do
#         Pattern="detached at (branch-heads/[0-9]+.[0-9]+)"
#         if [[ $line =~ $Pattern ]]; then
#             echo "Doing checkout of ${BASH_REMATCH[1]}"
#             Branch="${BASH_REMATCH[1]}"
#             break
#         fi
#     done < <(git branch)
#     if [ "$Branch" = "" ]; then
#         echo "Oh oh, couldn't find my detached head branch #! "
#         ${EXIT} 1
#     else
#         git checkout $Branch
#     fi
# fi

# let's generate our favorite build
echo "Generate build info"
declare -a GNARGS=(
    "is_lsan=true"
    "is_asan=true"
    "is_debug=true"
    'target_cpu="x64"'
    "is_component_build=false"
    "v8_monolithic=true"
    "v8_use_external_startup_data=false"
    "is_clang=true"
    )
#gn gen out/debug --args='is_lsan=true is_asan=true is_debug=true target_cpu="x64" is_component_build=false v8_monolithic=true v8_use_external_startup_data=false is_clang=true'
if YesNo "Create all the build files?"; then
    echo gn gen out/debug --args="${GNARGS[@]}"
    gn gen out/debug --args="${GNARGS[@]}"
    if YesNo "Shall I go ahead and compile?"; then
        echo "compile!"
        echo ninja -C out/debug
        ninja -C out/debug
    fi
fi
popd

#
#
echo "OK, I guess I'm done."
cd ${SAVE_DIR}
${EXIT} 0
