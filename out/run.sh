#!/system/bin/sh
SDIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]:-$0}"; )" &> /dev/null && pwd 2> /dev/null; )";
export LD_LIBRARY_PATH=$SDIR/lib:$SDIR/arm64-v8a/lib/wine/aarch64-unix
export WINEDEBUG="warn+all,err+all"
export WINEPREFIX="$HOME/.wine"
$SDIR/arm64-v8a/bin/wine64 cmd