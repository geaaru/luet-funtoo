#!/bin/bash

SCRIPT_DIR="$( dirname "${BASH_SOURCE[0]}" )"

kits=(
  "release"
  "net"
  "dev"
  "python"
  "db"
  "portage"
  "server"
  "java"
  "php"
  "service"
  "xorg"
)

for i in ${kits[@]} ; do
  TARGET_PKG=packages/toolchain/extra-${i} SOURCE_PKGS_DIR=packages/atoms-extra/${i}  ${SCRIPT_DIR}/toolchain-requires.sh
done
