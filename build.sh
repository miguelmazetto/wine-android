#!/bin/bash

SDIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]:-$0}"; )" &> /dev/null && pwd 2> /dev/null; )";
RDIR=$SDIR
if [[ ! -z "$MMZ_ROOTFOLDER" ]]; then RDIR=$MMZ_ROOTFOLDER; fi
cd $SDIR

mkcd(){ mkdir -p "$@"; cd "$@"; }

export NDK=$ANDROID_NDK
export TOOLCHAIN=$ANDROID_NDK/toolchains/llvm/prebuilt/linux-x86_64
export ANDROID_USR=$TOOLCHAIN/sysroot/usr
export API=24 # Set this to your minSdkVersion.

NORMALPATH=$PATH

add_inc(){ export CFLAGS="$CFLAGS -I$@"; }
add_link(){ export LDFLAGS="$LDFLAGS -R$@ -L$@"; }
mklink(){ echo "Link from $(realpath $1) to $2"; ln -sf "$(realpath $1)" "$2"; }
do_modpath(){
	local PATH_=$PATH
	export PATH=$1
	${@:2}
	export PATH=$PATH_
}

configure_android(){
	export CFLAGS="-I$ANDROID_USR/include" # -fPIE
	export LDFLAGS="-R$ANDROID_USR/lib/$TARGET/$API -L$ANDROID_USR/lib/$TARGET/$API"
	export AR=$TOOLCHAIN/bin/llvm-ar
	export CC="$TOOLCHAIN/bin/$TARGET$API-clang"
	export AS=$CC
	export CXX=$TOOLCHAIN/bin/$TARGET$API-clang++
	export LD=$TOOLCHAIN/bin/ld
	export RANLIB=$TOOLCHAIN/bin/llvm-ranlib
	export STRIP=$TOOLCHAIN/bin/llvm-strip
	export ARCH=$(echo $TARGET | grep -Po "^\\K\w+(?=-)")
	JNIOUTDIR=$RDIR/jniLibs/$ARCH2
	mkdir -p $JNIOUTDIR

	export PREBUILT=$SDIR/libs/prebuilt/$ARCH
	add_inc $SDIR/android/include
	add_inc $SDIR/libs/llvm-unwind/include
	add_inc $SDIR/libs/llvm-unwind/libunwind/include
	add_inc $SDIR/libs/prebuilt/all/include
	add_inc $PREBUILT/include
	add_inc $PREBUILT/include/freetype2
	#add_inc $PRE
	add_link $PREBUILT/lib
	export PKG_CONFIG_PATH=$PREBUILT/lib/pkgconfig
	export X_LIBS="-landroid-support -landroid-shmem -landroid-glob"
  export SDL2_CFLAGS="-I$PREBUILT/include/SDL2"

	add_inc "$SDIR/android/include"
}

greencol=$(tput setaf 46)
defaultcol=$(tput sgr0)

replmk(){ #(DEF,OLDVAL,NEWVAL)  DCXX="\"g++ -m64\""
	echo "s/D$1=\"\\\"$2\\\"\"/D$1=\"\\\"$3\\\"\"/g"
	sed -i "s/D$1=\"\\\"$2\\\"\"/D$1=\"\\\"$3\\\"\"/g" Makefile
	#sed -i 's/\\"$1\\"/\\"$\\"/g' Makefile
}

build_tools(){
	printf "\n${greencol}Building wine-tools...\n\n${defaultcol}"
	mkcd $SDIR/android/wine-tools

	#needs package libfreetype-dev
	add_inc /usr/include/freetype2

	../../wine/configure -C --enable-win64 --without-alsa --without-capi --without-coreaudio --without-cups --without-dbus \
		--without-fontconfig --without-gettext --without-gphoto --without-gnutls --without-gssapi --without-gstreamer \
		--without-inotify --without-krb5 --without-ldap --without-mingw --without-netapi --without-openal --without-opencl \
		--without-opengl --without-osmesa --without-oss --without-pcap --without-pthread --without-pulse --without-sane \
		--without-sdl --without-udev --without-unwind --without-usb --without-v4l2 --without-vulkan --without-x \
		--without-xcomposite --without-xcursor --without-xfixes --without-xinerama --without-xinput --without-xinput2 \
		--without-xrandr --without-xrender --without-xshape --without-xshm --without-xxf86vm

	sed -i 's/-DCC="\\"gcc -m64\\""/-DCC="\\"clang\\""/g' Makefile
	sed -i 's/-DCPP="\\"cpp\\""/-DCPP="\\"clang\\""/g' Makefile
	sed -i 's/-DCXX="\\"g++ -m64\\""/-DCXX="\\"clang++\\""/g' Makefile
	make -j tools/all tools/sfnt2fon/all tools/widl/all tools/winebuild/all \
		tools/winedump/all tools/winegcc/all tools/wmc/all \
		tools/wrc/all nls/all fonts/all
}

#wine

EXTRAWINECFG=''
configure_wine(){
	printf "\n${greencol}Configuring wine for $TARGET...\n\n${defaultcol}"

	mkcd $SDIR/build/$ARCH2/wine
	mkdir -p "$SDIR/out"

	PATH2=$PATH
	export PATH="$TOOLCHAIN/bin:$PATH"
  #export CFLAGS="$CFLAGS -DWINE_TRACE=1"

	../../../wine/configure -C $EXTRAWINECFG --with-wine-tools="$SDIR/android/wine-tools" \
		--host $TARGET --prefix="$SDIR/out" --disable-tests

	#fixes opengl32.dll.so
	#sed -i 's/-Wl,-delayload,glu32.dll/-Wl,-delayload,glu32.dll -nostdlib -lc/g' Makefile

	export PATH=$PATH2
}

WINEIGNORE=()
add_wine_ignore(){
	WINEIGNORE=(${WINEIGNORE[@]} $@)
}
nothing(){
	local Nothing=':D'
}

build_wine64(){
	printf "\n${greencol}Building wine for $TARGET...\n\n${defaultcol}"
	mkcd $SDIR/build/$ARCH2/wine
	#touch dlls/wineandroid.drv/wine-debug.apk dlls/wineandroid.drv/build.gradle dlls/wineandroid.drv/wineandroid.so \
	#add_wine_ignore dlls/wineandroid.drv/wine-debug.apk dlls/wineandroid.drv/build.gradle dlls/wineandroid.drv/wineandroid.so

	#for I in "${WINEIGNORE[@]}"; do
	#	mkdir -p "$(dirname $I)"
	#	touch $I
	#    IGN=$IGN" -o $I"
	#    RML=$RML" $I"
	#done

	PATH2="$PATH"
	export PATH="$TOOLCHAIN/bin:$SDIR/android/bin:$PATH"
	mkdir -p $SDIR/android/bin
	ln -sf $(which llvm-dlltool-14) $SDIR/android/bin/llvm-dlltool
  	#export LDFLAGS="-v $LDFLAGS"
  	#export CROSSLDFLAGS="-v"

  	#make -j install-lib
  	#make dlls/ntdll/all

	#make -j7 $IGN
  #\
  #dlls/d3d9/install-dev dlls/d3d11/install-dev dlls/dxgi/install-dev \
  #dlls/d3dcompiler_47/install-dev 
  #nothing -j $IGN dlls/kernel32/install-dev dlls/user32/install-dev dlls/gdi32/install-dev \
  #dlls/winspool.drv/install-dev dlls/shell32/install-dev dlls/ole32/install-dev \
  #dlls/oleaut32/install-dev libs/uuid/install-de dlls/comdlg32/install-dev \
  #dlls/advapi32/install-dev


	#rm -rf $RML
	#make -j7 install-lib
	echo "warn+all,err+all" > $SDIR/out/winedebug
	make -j7 dlls/wineandroid.drv/install-lib dlls/wineandroid.drv/all
	export PATH="$PATH2"
	cp -f dlls/wineandroid.drv/wine-debug.apk /mnt/c/Users/migue/Downloads
}

#gl4es

configure_gl4es(){
	printf "\n${greencol}Configuring gl4es for $TARGET...\n\n${defaultcol}"
	mkcd "$SDIR/build/$ARCH2/gl4es"
	cmake "$SDIR/libs/gl4es" -DCMAKE_BUILD_TYPE=RelWithDebInfo -DDEFAULT_ES=2 \
		-DANDROID=1 -DANDROID_PLATFORM=$API -DANDROID_ABI=$ARCH2 -DNOX11=1
}
build_gl4es(){
	printf "\n${greencol}Building gl4es for $TARGET...\n\n${defaultcol}"
	mkcd "$SDIR/build/$ARCH2/gl4es"
	make -j
	cp -f "$SDIR/libs/gl4es/lib/libGL.so.1" "$PREBUILT/lib"
	ln -sf "$PREBUILT/lib/libGL.so.1" "$PREBUILT/lib/libGL.so"
}

#libgbm

build_libgbm(){
	printf "\n${greencol}Building libgbm for $TARGET...\n\n${defaultcol}"
	mkcd "$SDIR/build/$ARCH2/libgbm"
	cmake "$SDIR/libs/libgbm" -DCMAKE_BUILD_TYPE=RelWithDebInfo \
		--toolchain "$NDK/build/cmake/android.toolchain.cmake" -DANDROID_PLATFORM=$API \
		-DANDROID_ABI=$ARCH2
	make -j
	cp -f ./libgbm.a "$SDIR/libs/prebuilt/$ARCH/lib"
	cd "$SDIR/libs/libgbm"
	cp -f ./src/gbm.h "$SDIR/libs/prebuilt/all/include"
	cp -f ./gbm.pc "$SDIR/libs/prebuilt/$ARCH/lib/pkgconfig/"
}

winecc(){
    #CC="winegcc" CXX="wineg++" CFLAGS="-v $CFLAGS" \
      do_modpath "$SDIR/android/wine-tools/tools/winegcc:$SDIR/android/bin:$TOOLCHAIN/bin:$PATH" $@
}

#utils

cpmerge(){
	DEST="${@:${#@}}"
	ABS_DEST="$(mkcd "$(dirname "$DEST")"; pwd)/$(basename "$DEST")"
	
	for SRC in "${@:1:$((${#@} -1))}"; do   (
	    cd "$SRC";
	    find . -type d -exec mkdir -p "${ABS_DEST}"/\{} \;
	    find . -type f -exec cp -f \{} "${ABS_DEST}"/\{} \;
	) done
}
fix_lib_version(){
	OLDPATH=$PWD
	cd "$1"
	for f in $1/*.so.*; do
		local newname=$(dirname "$f")/$(echo $f | grep -Po "\\K\w+(?=.so)").so
		[ ! -e newname ] && ln -sr $f $newname 2&>1 >/dev/null
	done
	cd "$OLDPATH"
}

#libunwind

configure_libunwind(){
	printf "\n${greencol}Configuring libunwind for $TARGET...\n\n${defaultcol}"
	mkcd "$SDIR/build/$ARCH2/libunwind"
	cmake "$SDIR/libs/llvm-unwind/libunwind" \
		-DLIBUNWIND_USE_COMPILER_RT=1 -DLIBUNWIND_ENABLE_CROSS_UNWINDING=1
}
build_libunwind(){
	printf "\n${greencol}Building libunwind for $TARGET...\n\n${defaultcol}"
	mkcd "$SDIR/build/$ARCH2/libunwind"
	make -j
	cp -f lib/* "$PREBUILT/lib"
	#cd "$SDIR/libs"
	#find "llvm-unwind/libunwind/include/" -name "*.h" -exec cp '{}' "prebuilt/all/include" \;
}

doall(){
	configure_android

#	configure_gl4es
#	build_gl4es
#
#	fix_lib_version $SDIR/libs/prebuilt/$ARCH/lib
#
#	configure_libunwind
#	build_libunwind
#
	configure_wine
	build_wine64
}

#build_tools

EXTRAWINECFG="--enable-win64"
export TARGET=aarch64-linux-android
ARCH2=arm64-v8a
doall
#build_dxvk

#EXTRAWINECFG='--enable-win64'
#export TARGET=x86_64-linux-android
#ARCH2=x86_64
#doall
#
#EXTRAWINECFG='--with-wine64=$SDIR/build/x86_64/wine'
#export TARGET=i686-linux-android
#ARCH2=x86
#doall

#EXTRAWINECFG=''
#export TARGET=armv7a-linux-androideabi
#ARCH2=armeabi-v7a
#doall