#!/bin/bash
# Author: Daniele Rondina, geaaru@sabayonlinux.org

set -x

GCC_VERSION=11.3.0
EROOT=${EROOT:-/}

create_gcc_ldconfig() {
  mkdir -p ${EROOT}etc/ld.so.conf.d || true

  echo "
/usr/lib/gcc/x86_64-pc-linux-gnu/${GCC_VERSION}/32
/usr/lib/gcc/x86_64-pc-linux-gnu/${GCC_VERSION}
" > ${EROOT}etc/ld.so.conf.d/05gcc-x86_64-pc-linux-gnu.conf 
}

main() {
  create_gcc_ldconfig

  return 0
}

main $@
exit $?
