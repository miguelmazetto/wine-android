#!/bin/bash
cd "$(realpath "$(dirname "$0")")"

mkcd(){ mkdir -p "$@"; cd "$@"; }
mkcd libs/prebuilt
PDIR=$PWD

solve_pkgurl(){
	local PREF="https://packages.termux.dev/apt/$2/pool/main"
	if [[ $1 == lib* ]]; then
		PREF=$PREF/lib${1:3:1}
	else
		PREF=$PREF/${1:0:1}
	fi
	echo "$PREF/$1/"
}

mvmerge(){
	DEST="${@:${#@}}"
	ABS_DEST="$(mkcd "$(dirname "$DEST")"; pwd)/$(basename "$DEST")"
	
	for SRC in "${@:1:$((${#@} -1))}"; do   (
	    cd "$SRC";
	    find . -type d -exec mkdir -p "${ABS_DEST}"/\{} \;
	    find . -type f,l -exec mv -f \{} "${ABS_DEST}"/\{} \;
	    find . -type d -empty -delete
	) done
}

download_pkg(){
	local BASEURL=$(solve_pkgurl $1 $2)

	mkcd $PDIR/tmp_$1

	curl --silent $BASEURL 2>&1 | \
	grep -oP "<a href=\"\\K$1_.+(?=\">)" | \
	while read -r f ; do
		local VERSION=$(echo $f | grep -oP "_\\K[\d\.-]+(?=_)")
		local ARCH="$(echo $f | grep -oP "${VERSION}_\\K\w+(?=.deb)")"
		printf "\nDownloading $f...\n"
		#curl -o $f "$BASEURL$f"
		wget -nv "$BASEURL$f"
		printf "\nExtracting $f...\n"
		ar x $f
		tar xf data.tar.xz
		local USR=data/data/com.termux/files/usr
		mkdir ../$ARCH 2&>1 >/dev/null
		[ -d $USR/lib ] && mvmerge $USR/lib ../$ARCH/lib
		[ -d $USR/include ] && mvmerge $USR/include ../$ARCH/include
		break
	done

	rm -rf $PDIR/tmp_$1
}

color=(1 2 3 4 5 6 7 8 9 10 11 12 13 14 15)
default=$(tput sgr0)

download_pkg_col(){
	download_pkg $1 termux-main 2>&1 | sed "s/.*/$(tput setaf ${color[$RANDOM%15]})&$default/"
}

download_pkg_col_x11(){
	download_pkg $1 termux-x11 2>&1 | sed "s/.*/$(tput setaf ${color[$RANDOM%15]})&$default/"
}

repl_path(){
	sed -i 's/\/data\/data\/com.termux\/files\/usr/..\/../g' $PDIR/$1/lib/pkgconfig/*.pc
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
download_msys2_pkg(){
	mkcd $PDIR/wtmp_$2
	printf "\nDownloading $2...\n"
	wget "https://repo.msys2.org/mingw/$1/mingw-w64-clang-$2.pkg.tar.zst"
	printf "\nExtracting $2...\n"
	tar --use-compress-program=unzstd -xf "mingw-w64-clang-$2.pkg.tar.zst"
	[ -d $1/bin ] && mvmerge $1/bin ../w$1/bin
	[ -d $1/lib ] && mvmerge $1/lib ../w$1/lib
	[ -d $1/include ] && mvmerge $1/include ../w$1/include
	#rm -rf $PWD
	cd ..
}
download_win_headers(){
	mkcd $PDIR/tmp_winheaders
	local f="mingw-w64-clang-aarch64-headers-git-10.0.0.r72.g1dd2a4993-1-any.pkg.tar.zst"
	wget "https://mirror.msys2.org/mingw/clangarm64/$f"
	tar --use-compress-program=unzstd -xf $f
	mvmerge clangarm64/include $PDIR/aarch64/include/winheaders
	rm -rf $PWD
	cd ..
}

#fix_lib_version $PDIR/aarch64/lib

download_pkg_col libandroid-support &
download_pkg_col libandroid-glob &
download_pkg_col libandroid-shmem &
download_pkg_col libandroid-support-static &
download_pkg_col libandroid-glob-static &
download_pkg_col libandroid-shmem-static &
#wait
#download_pkg_col libxau &
#download_pkg_col libxdmcp &
#download_pkg_col libxcb &
#download_pkg_col libx11 &
#download_pkg_col libxrender &
#download_pkg_col_x11 libxfixes &
#download_pkg_col_x11 libxcursor &
#download_pkg_col_x11 libxxf86dga &
#wait
#download_pkg_col_x11 libxxf86vm &
#download_pkg_col_x11 libxi &
#download_pkg_col_x11 libxinerama &
#download_pkg_col_x11 libxfont2 &
#download_pkg_col_x11 libxcursor &
#download_pkg_col_x11 libxcomposite &
#download_pkg_col libxext &
#download_pkg_col libxt &
#wait
#download_pkg_col xorgproto &
#
#download_pkg_col libbz2 &
#download_pkg_col libpng &
download_pkg_col freetype &

#download_pkg_col libiconv &
download_pkg_col libgnutls &
download_pkg_col gnutls &
#wait
download_pkg_col cups &

download_pkg_col_x11 libdrm &

#download_msys2_pkg clangarm64 aarch64-freetype-2.12.1-1-any &
#download_msys2_pkg clangarm64 aarch64-libpng-1.6.38-1-any &

#download_pkg_col libflac &
#download_pkg_col libogg &
#download_pkg_col libopus &
#download_pkg_col libvorbis &
#wait
#download_pkg_col libsndfile &
#download_pkg_col libandroid-execinfo &
#download_pkg_col libltdl &
#download_pkg_col libsoxr &
#download_pkg_col libwebrtc-audio-processing &
#download_pkg_col speexdsp &
#download_pkg_col pulseaudio &
#download_pkg_col_x11 libxrandr &
#download_pkg_col_x11 sdl2 &

#download_win_headers &

download_pkg_col libgmp &
download_pkg_col openldap &

wait

sed -i 's/\/data\/data\/com.termux\/files\/usr/..\/../g' $PDIR/aarch64/lib/pkgconfig/*.pc
sed -i 's/\/data\/data\/com.termux\/files\/usr/..\/../g' $PDIR/arm/lib/pkgconfig/*.pc
sed -i 's/\/data\/data\/com.termux\/files\/usr/..\/../g' $PDIR/x86_64/lib/pkgconfig/*.pc
sed -i 's/\/data\/data\/com.termux\/files\/usr/..\/../g' $PDIR/i686/lib/pkgconfig/*.pc
sed -i 's/\/data\/data\/com.termux\/files\/usr/..\/../g' $PDIR/all/lib/pkgconfig/*.pc