#!/usr/bin/make -f
# vim:noet:ts=3
#
# @file Makefile - run this test suite
#
# @author Samuel Larkin
#
# Technologies langagieres interactives / Interactive Language Technologies
# Inst. de technologie de l'information / Institute for Information Technology
# Conseil national de recherches Canada / National Research Council Canada
# Copyright 2009, Sa Majeste la Reine du Chef du Canada /
# Copyright 2009, Her Majesty in Right of Canada


LIB = PERL5LIB=.:$$PERL5LIB

define test_function
${LIB} perl -e 'use portage_utils; $$portage_utils::DEBUG=1; portage_utils::zout(*VOC, "delme") or die "BAD plain file"; print VOC "test"'
endef

.NOTPARALLEL:

all: plain
all: gzip
all: bzip2
all: lzma
all: std
all: pipe
	@echo All tests PASSED

F_PREFIX = delme
clean:
	${RM} ${F_PREFIX}{,.gz,.bzip2,.lzma,.pipe} ${F_PREFIX}.ref-*

plain:
	${LIB} perl -e 'use portage_utils; $$portage_utils::DEBUG=1; portage_utils::zopen(*VOC, ">${F_PREFIX}") or die "BAD plain file"; print VOC "test\n"'
	echo test | diff - ${F_PREFIX}
	${LIB} perl -e 'use portage_utils; $$portage_utils::DEBUG=1; portage_utils::zopen(*VOC, ">>${F_PREFIX}") or die "BAD plain file"; print VOC "test\n"'
	echo test | tee /dev/stdout | diff - ${F_PREFIX}
	${LIB} perl -e 'use portage_utils; $$portage_utils::DEBUG=1; portage_utils::zopen(*VOC, "${F_PREFIX}") or die "BAD plain file"; print <VOC>;' | diff - ${F_PREFIX}
	${LIB} perl -e 'use portage_utils; $$portage_utils::DEBUG=1; portage_utils::zopen(*VOC, "<${F_PREFIX}") or die "BAD plain file"; print <VOC>;' | diff - ${F_PREFIX}

gzip:
	${LIB} perl -e 'use portage_utils; $$portage_utils::DEBUG=1; portage_utils::zopen(*VOC, ">${F_PREFIX}.gz") or die "BAD gzip"; print VOC "test\n"'
	echo test > ${F_PREFIX}.ref-gz && zcat ${F_PREFIX}.gz | diff - ${F_PREFIX}.ref-gz
	${LIB} perl -e 'use portage_utils; $$portage_utils::DEBUG=1; portage_utils::zopen(*VOC, ">>${F_PREFIX}.gz") or die "BAD gzip"; print VOC "test\n"'
	echo test >> ${F_PREFIX}.ref-gz && zcat ${F_PREFIX}.gz | diff - ${F_PREFIX}.ref-gz
	${LIB} perl -e 'use portage_utils; $$portage_utils::DEBUG=1; portage_utils::zopen(*VOC, "${F_PREFIX}.gz") or die "BAD gzip"; print <VOC>' | diff - ${F_PREFIX}.ref-gz
	${LIB} perl -e 'use portage_utils; $$portage_utils::DEBUG=1; portage_utils::zopen(*VOC, "<${F_PREFIX}.gz") or die "BAD gzip"; print <VOC>' | diff - ${F_PREFIX}.ref-gz

bzip2:
	${LIB} perl -e 'use portage_utils; $$portage_utils::DEBUG=1; portage_utils::zopen(*VOC, ">${F_PREFIX}.bzip2") or die "BAD bzip2"; print VOC "test\n"'
	echo test > ${F_PREFIX}.ref-bzip2 && bzcat ${F_PREFIX}.bzip2 | diff - ${F_PREFIX}.ref-bzip2
	${LIB} perl -e 'use portage_utils; $$portage_utils::DEBUG=1; portage_utils::zopen(*VOC, ">>${F_PREFIX}.bzip2") or die "BAD bzip2"; print VOC "test\n"'
	echo test >> ${F_PREFIX}.ref-bzip2 && bzcat ${F_PREFIX}.bzip2 | diff - ${F_PREFIX}.ref-bzip2
	${LIB} perl -e 'use portage_utils; $$portage_utils::DEBUG=1; portage_utils::zopen(*VOC, "${F_PREFIX}.bzip2") or die "BAD bzip2"; print <VOC>' | diff - ${F_PREFIX}.ref-bzip2
	${LIB} perl -e 'use portage_utils; $$portage_utils::DEBUG=1; portage_utils::zopen(*VOC, "<${F_PREFIX}.bzip2") or die "BAD bzip2"; print <VOC>' | diff - ${F_PREFIX}.ref-bzip2

# NOTE: apppending to a lzma is not allowed.
lzma:
	${LIB} perl -e 'use portage_utils; $$portage_utils::DEBUG=1; portage_utils::zopen(*VOC, ">${F_PREFIX}.lzma") or die "BAD lzma"; print VOC "test\n"'
	echo test > ${F_PREFIX}.ref-lzma && lzcat ${F_PREFIX}.lzma | diff - ${F_PREFIX}.ref-lzma
	-${LIB} perl -e 'use portage_utils; $$portage_utils::DEBUG=1; portage_utils::zopen(*VOC, ">>${F_PREFIX}.lzma") or die "BAD lzma"; print VOC "test\n"'
	#echo test >> ${F_PREFIX}.ref-lzma && lzcat ${F_PREFIX}.lzma | diff - ${F_PREFIX}.ref-lzma
	${LIB} perl -e 'use portage_utils; $$portage_utils::DEBUG=1; portage_utils::zopen(*VOC, "${F_PREFIX}.lzma") or die "BAD lzma"; print <VOC>' | diff - ${F_PREFIX}.ref-lzma
	${LIB} perl -e 'use portage_utils; $$portage_utils::DEBUG=1; portage_utils::zopen(*VOC, "<${F_PREFIX}.lzma") or die "BAD lzma"; print <VOC>' | diff - ${F_PREFIX}.ref-lzma

std:
	echo test > ${F_PREFIX}.ref-std
	${LIB} perl -e 'use portage_utils; $$portage_utils::DEBUG=1; portage_utils::zout(*VOC, "-") or die "BAD std"; print VOC "test\n";' | diff - ${F_PREFIX}.ref-std
	${LIB} perl -e 'use portage_utils; $$portage_utils::DEBUG=1; portage_utils::zopen(*VOC, ">-") or die "BAD std"; print VOC "test\n";' | diff - ${F_PREFIX}.ref-std
	echo "test" | ${LIB} perl -e 'use portage_utils; $$portage_utils::DEBUG=1; portage_utils::zin(*VOC, "-") or die "BAD std"; print <VOC>;' | diff - ${F_PREFIX}.ref-std
	echo "test" | ${LIB} perl -e 'use portage_utils; $$portage_utils::DEBUG=1; portage_utils::zopen(*VOC, "<-") or die "BAD std"; print <VOC>;' | diff - ${F_PREFIX}.ref-std

pipe:
	${LIB} perl -e 'use portage_utils; $$portage_utils::DEBUG=1; portage_utils::zout(*VOC, "| sed -e 's/t/r/g' > ${F_PREFIX}.pipe") or die "BAD pipe"; print VOC "test\n";'
	echo resr | diff - ${F_PREFIX}.pipe
	echo desd > ${F_PREFIX}.ref-pipe
	${LIB} perl -e 'use portage_utils; $$portage_utils::DEBUG=1; portage_utils::zin(*VOC, "sed -e 's/r/d/g' ${F_PREFIX}.pipe |") or die "BAD pipe"; print <VOC>;' | diff - ${F_PREFIX}.ref-pipe
	${LIB} perl -e 'use portage_utils; $$portage_utils::DEBUG=1; portage_utils::zopen(*VOC, "| sed -e 's/t/r/g' > ${F_PREFIX}.pipe") or die "BAD pipe"; print VOC "test\n";'
	echo resr | diff - ${F_PREFIX}.pipe
	${LIB} perl -e 'use portage_utils; $$portage_utils::DEBUG=1; portage_utils::zopen(*VOC, "sed -e 's/r/d/g' ${F_PREFIX}.pipe |") or die "BAD pipe"; print <VOC>;' | diff - ${F_PREFIX}.ref-pipe
