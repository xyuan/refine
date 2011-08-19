#!/usr/bin/env bash

CC=gcc
CFLAGS="-g -O0 -pedantic-errors -Wall -Wextra -Werror -Wunused"

if [ -z "$1" ]
then
  tests=`ls -1 *_test.c`
else
  tests=$*
fi

for test in $tests;
do
  root=${test%_test.c}
  echo $root ---------------------

  dependencies=''
  for dep_header in `grep '#include "ref_' ${root}.h`
  do
    source_with_leading_quote=${dep_header%.h\"}.c
    source=${source_with_leading_quote#\"}
    if [ -a ${source} ]; then
      if ! echo ${dependencies} | grep -q "${source}" ; then
        dependencies=${dependencies}' '${source}
      fi
    fi
  done
  for dep_header in `grep '#include "ref_' ${root}_test.c`
  do
    source_with_leading_quote=${dep_header%.h\"}.c
    source=${source_with_leading_quote#\"}
    if [ -a ${source} ]; then
      if ! echo ${dependencies} | grep -q "${source}" ; then
        dependencies=${dependencies}' '${source}
      fi
    fi
  done

  compile="${CC} ${CFLAGS} -o ${root}_test ${dependencies} ${root}_test.c"
  (eval ${compile} && eval valgrind --leak-check=full ./${root}_test) || \
      ( echo FAIL: ./${root}_test ; exit 1 ) ||  exit 1
done

