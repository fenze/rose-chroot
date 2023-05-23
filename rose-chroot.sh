#!/bin/sh -e

case $1 in
	--help|-h)
		echo "usage: rose-chroot [PATH]"
		exit 0;;
esac

ROOT=`realpath $1`

mounted() {
	[ -e "$1" ] || return 1
	[ -e /proc/mounts ] || return 1

	while read -r _ target _; do
		[ "$target" = "$1" ] && return 0
	done < /proc/mounts

	return 1
}

clean() {
	umount -l "$ROOT/dev/shm"
	umount -l "$ROOT/dev"
	umount -l "$ROOT/proc"
	umount -l "$ROOT/run"
	umount -l "$ROOT/sys/firmware/efi/efivars" 2>/dev/null
	umount -l "$ROOT/sys"
	umount -l "$ROOT/tmp"
	rm -f "$ROOT/etc/resolv.conf"
}

mmount() {
	dest=$1
	shift
	mounted "$dest" || run mount "$@" "$dest"
}

[ "$ROOT" ] || exit 1
[ -d "$ROOT" ] || exit 1
[ "$(id -u)" = 0 ] || exit 1

set -- "${ROOT%"${ROOT##*[!/]}"}"
trap 'clean "${1%"${1##*[!/]}"}"' EXIT INT

mmount "$ROOT/dev"     -o bind /dev
mmount "$ROOT/dev/pts" -o bind /dev/pts
mmount "$ROOT/dev/shm" -t tmpfs shmfs
mmount "$ROOT/proc"    -t proc  proc
mmount "$ROOT/run"     -t tmpfs tmpfs
mmount "$ROOT/sys"     -t sysfs sys
mmount "$ROOT/sys/firmware/efi/efivars" -t efivarfs efivarfs 2>/dev/null
mmount "$ROOT/tmp"     -o mode=1777,nosuid,nodev -t tmpfs tmpfs
cp -f /etc/resolv.conf "$ROOT/etc"

_ret=1
chroot "$ROOT" /usr/bin/env -i \
	HOME=/root \
	TERM=$TERM \
	COLORTERM=$COLORTERM \
	SHELL=/bin/sh \
	USER=root \
	LOGNAME=root \
	/bin/sh -l
