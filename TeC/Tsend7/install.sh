#!/bin/sh

case `uname` in
  Linux )
     own="-o root"
     grp="-g dialout"
     mod="-m 6755"
     dir="/usr/bin"
     ;;
  FreeBSD )
     own="-o uucp"
     grp="-g dialer"
     mod="-m 6755"
     dir="/usr/local/bin"
     ;;
  Darwin )
     own=""
     grp=""
     mod="-m 755"
     dir="/usr/local/bin"
     ;;
  * )
     echo "`uname` is not nsupported." >&2
     exit 1
     ;;
esac

install -c ${own} ${grp} ${mod} ./tsend7.sh  ${dir}/tsend7
install -c ${own} ${grp} ${mod} ./tsend7.bin ${dir}/tsend7.bin
