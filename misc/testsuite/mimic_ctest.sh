#! /usr/bin/env bash
## vim:set ts=4 sw=4 et:
set -e; set -o pipefail
argv0=$0; argv0abs=$(readlink -fn "$argv0"); argv0dir=$(dirname "$argv0abs")

#
# Copyright (C) Markus Franz Xaver Johannes Oberhumer
#
# mimic running "ctest", i.e. the "test" section of CMakeLists.txt; does not redirect stdout
# (allows freely setting $upx_exe_runner, while CMake is restricted to configure-time settings)
#
# requires:
#   $upx_exe                (required, but with convenience fallback "./upx")
# optional settings:
#   $upx_exe_runner         (e.g. "qemu-x86_64 -cpu Nehalem" or "valgrind")
#

#***********************************************************************
# init & checks
#***********************************************************************

# upx_exe
[[ -z $upx_exe && -f ./upx && -x ./upx ]] && upx_exe=./upx # convenience fallback
if [[ -z $upx_exe ]]; then echo "UPX-ERROR: please set \$upx_exe"; exit 1; fi
if [[ ! -f $upx_exe ]]; then echo "UPX-ERROR: file '$upx_exe' does not exist"; exit 1; fi
upx_exe=$(readlink -fn "$upx_exe") # make absolute
[[ -f $upx_exe ]] || exit 1
upx_run=()
if [[ -n $upx_exe_runner ]]; then
    # usage examples:
    #   export upx_exe_runner="qemu-x86_64 -cpu Nehalem"
    #   export upx_exe_runner="valgrind --leak-check=no --error-exitcode=1 --quiet"
    #   export upx_exe_runner="wine"
    IFS=' ' read -r -a upx_run <<< "$upx_exe_runner" # split at spaces into array
elif [[ -n $CMAKE_CROSSCOMPILING_EMULATOR ]]; then
    IFS=';' read -r -a upx_run <<< "$CMAKE_CROSSCOMPILING_EMULATOR" # split at semicolons into array
fi
upx_runner=( "${upx_run[@]}" )
upx_run+=( "$upx_exe" )
echo "upx_run='${upx_run[*]}'"

# upx_run sanity check
if ! "${upx_run[@]}" --version-short >/dev/null; then echo "UPX-ERROR: FATAL: upx --version-short FAILED"; exit 1; fi
if ! "${upx_run[@]}" -L >/dev/null 2>&1; then echo "UPX-ERROR: FATAL: upx -L FAILED"; exit 1; fi
if ! "${upx_run[@]}" --help >/dev/null;  then echo "UPX-ERROR: FATAL: upx --help FAILED"; exit 1; fi

#***********************************************************************
# see CMakeLists.txt
#***********************************************************************

set_on_off() {
    local var_name
    for var_name do
        case "${!var_name}" in
            "" | "0" | "FALSE" | "OFF") eval $var_name=OFF ;;
            *) eval $var_name=ON ;;
        esac
    done
}

set -x
set_on_off UPX_CONFIG_DISABLE_SELF_PACK_TEST
set_on_off UPX_CONFIG_DISABLE_RUN_UNPACKED_TEST
set_on_off UPX_CONFIG_DISABLE_RUN_PACKED_TEST

export UPX="--no-color --no-progress"

"${upx_run[@]}" --version
"${upx_run[@]}" --version-short
"${upx_run[@]}" --help
"${upx_run[@]}" --license
"${upx_run[@]}" --sysinfo -v

if [[ $UPX_CONFIG_DISABLE_SELF_PACK_TEST == ON ]]; then
    echo "Self-pack test disabled. All done."; exit 0
fi

exe=".out"
upx_self_exe=$upx_exe
fo="--force-overwrite"

"${upx_run[@]}" -3 --all-filters "${upx_self_exe}" ${fo} -o upx-packed${exe}
"${upx_run[@]}" -3 --nrv2b       "${upx_self_exe}" ${fo} -o upx-packed-n2b${exe}
"${upx_run[@]}" -3 --nrv2d       "${upx_self_exe}" ${fo} -o upx-packed-n2d${exe}
"${upx_run[@]}" -3 --nrv2e       "${upx_self_exe}" ${fo} -o upx-packed-n2e${exe}
"${upx_run[@]}" -1 --lzma        "${upx_self_exe}" ${fo} -o upx-packed-lzma${exe}

"${upx_run[@]}" -l         upx-packed${exe} upx-packed-n2b${exe} upx-packed-n2d${exe} upx-packed-n2e${exe} upx-packed-lzma${exe}
"${upx_run[@]}" --fileinfo upx-packed${exe} upx-packed-n2b${exe} upx-packed-n2d${exe} upx-packed-n2e${exe} upx-packed-lzma${exe}
"${upx_run[@]}" -t         upx-packed${exe} upx-packed-n2b${exe} upx-packed-n2d${exe} upx-packed-n2e${exe} upx-packed-lzma${exe}

"${upx_run[@]}" -d upx-packed${exe}      ${fo} -o upx-unpacked${exe}
"${upx_run[@]}" -d upx-packed-n2b${exe}  ${fo} -o upx-unpacked-n2b${exe}
"${upx_run[@]}" -d upx-packed-n2d${exe}  ${fo} -o upx-unpacked-n2d${exe}
"${upx_run[@]}" -d upx-packed-n2e${exe}  ${fo} -o upx-unpacked-n2e${exe}
"${upx_run[@]}" -d upx-packed-lzma${exe} ${fo} -o upx-unpacked-lzma${exe}

if [[ $UPX_CONFIG_DISABLE_RUN_UNPACKED_TEST == OFF ]]; then
"${upx_runner[@]}" ./upx-unpacked${exe} --version-short
"${upx_runner[@]}" ./upx-unpacked-n2b${exe} --version-short
"${upx_runner[@]}" ./upx-unpacked-n2d${exe} --version-short
"${upx_runner[@]}" ./upx-unpacked-n2e${exe} --version-short
"${upx_runner[@]}" ./upx-unpacked-lzma${exe} --version-short
fi

if [[ $UPX_CONFIG_DISABLE_RUN_PACKED_TEST == OFF ]]; then
"${upx_runner[@]}" ./upx-packed${exe} --version-short
"${upx_runner[@]}" ./upx-packed-n2b${exe} --version-short
"${upx_runner[@]}" ./upx-packed-n2d${exe} --version-short
"${upx_runner[@]}" ./upx-packed-n2e${exe} --version-short
"${upx_runner[@]}" ./upx-packed-lzma${exe} --version-short
fi

echo "All done."
