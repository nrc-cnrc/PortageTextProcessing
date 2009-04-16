#!/usr/bin/make -f
# vim:noet:ts=3


LIB = PERL5LIB=.:$$PERL5LIB

define test_function
${LIB} perl -e 'use portage_utils; $$portage_utils::DEBUG=1; portage_utils::zout(*VOC, "delme") or die "BAD plain file"; print VOC "test"'
endef

.NOT_PARALLEL:

all: plain
all: gzip
all: bzip2
all: lzma
all: std
all: pipe

F_PREFIX = delme
clean:
	${RM} ${F_PREFIX}{,.gz,.bzip2,.lzma}

plain:
	${LIB} perl -e 'use portage_utils; $$portage_utils::DEBUG=1; portage_utils::zopen(*VOC, ">${F_PREFIX}") or die "BAD plain file"; print VOC "test\n"'
	${LIB} perl -e 'use portage_utils; $$portage_utils::DEBUG=1; portage_utils::zopen(*VOC, ">>${F_PREFIX}") or die "BAD plain file"; print VOC "test\n"'
	${LIB} perl -e 'use portage_utils; $$portage_utils::DEBUG=1; portage_utils::zopen(*VOC, "${F_PREFIX}") or die "BAD plain file"; print <VOC>;'
	${LIB} perl -e 'use portage_utils; $$portage_utils::DEBUG=1; portage_utils::zopen(*VOC, "<${F_PREFIX}") or die "BAD plain file"; print <VOC>;'

gzip:
	${LIB} perl -e 'use portage_utils; $$portage_utils::DEBUG=1; portage_utils::zopen(*VOC, ">${F_PREFIX}.gz") or die "BAD gzip"; print VOC "test\n"'
	${LIB} perl -e 'use portage_utils; $$portage_utils::DEBUG=1; portage_utils::zopen(*VOC, ">>${F_PREFIX}.gz") or die "BAD gzip"; print VOC "test\n"'
	${LIB} perl -e 'use portage_utils; $$portage_utils::DEBUG=1; portage_utils::zopen(*VOC, "${F_PREFIX}.gz") or die "BAD gzip"; print <VOC>'
	${LIB} perl -e 'use portage_utils; $$portage_utils::DEBUG=1; portage_utils::zopen(*VOC, "<${F_PREFIX}.gz") or die "BAD gzip"; print <VOC>'

bzip2:
	${LIB} perl -e 'use portage_utils; $$portage_utils::DEBUG=1; portage_utils::zopen(*VOC, ">${F_PREFIX}.bzip2") or die "BAD bzip2"; print VOC "test\n"'
	${LIB} perl -e 'use portage_utils; $$portage_utils::DEBUG=1; portage_utils::zopen(*VOC, ">>${F_PREFIX}.bzip2") or die "BAD bzip2"; print VOC "test\n"'
	${LIB} perl -e 'use portage_utils; $$portage_utils::DEBUG=1; portage_utils::zopen(*VOC, "${F_PREFIX}.bzip2") or die "BAD bzip2"; print <VOC>'
	${LIB} perl -e 'use portage_utils; $$portage_utils::DEBUG=1; portage_utils::zopen(*VOC, "<${F_PREFIX}.bzip2") or die "BAD bzip2"; print <VOC>'

# NOTE: apppending to a lzma is not allowed.
lzma:
	${LIB} perl -e 'use portage_utils; $$portage_utils::DEBUG=1; portage_utils::zopen(*VOC, ">${F_PREFIX}.lzma") or die "BAD lzma"; print VOC "test\n"'
	-${LIB} perl -e 'use portage_utils; $$portage_utils::DEBUG=1; portage_utils::zopen(*VOC, ">>${F_PREFIX}.lzma") or die "BAD lzma"; print VOC "test\n"'
	${LIB} perl -e 'use portage_utils; $$portage_utils::DEBUG=1; portage_utils::zopen(*VOC, "${F_PREFIX}.lzma") or die "BAD lzma"; print <VOC>'
	${LIB} perl -e 'use portage_utils; $$portage_utils::DEBUG=1; portage_utils::zopen(*VOC, "<${F_PREFIX}.lzma") or die "BAD lzma"; print <VOC>'

std:
	${LIB} perl -e 'use portage_utils; $$portage_utils::DEBUG=1; portage_utils::zout(*VOC, "-") or die "BAD std"; print VOC "test\n";'
	${LIB} perl -e 'use portage_utils; $$portage_utils::DEBUG=1; portage_utils::zopen(*VOC, ">-") or die "BAD std"; print VOC "test\n";'
	echo "test" | ${LIB} perl -e 'use portage_utils; $$portage_utils::DEBUG=1; portage_utils::zin(*VOC, "-") or die "BAD std"; print <VOC>;'
	echo "test" | ${LIB} perl -e 'use portage_utils; $$portage_utils::DEBUG=1; portage_utils::zopen(*VOC, "<-") or die "BAD std"; print <VOC>;'

pipe:
	${LIB} perl -e 'use portage_utils; $$portage_utils::DEBUG=1; portage_utils::zout(*VOC, "| sed -e 's/t/r/g' > ${F_PREFIX}") or die "BAD pipe"; print VOC "test\n";'
	${LIB} perl -e 'use portage_utils; $$portage_utils::DEBUG=1; portage_utils::zin(*VOC, "sed -e 's/r/d/g' ${F_PREFIX} |") or die "BAD pipe"; print <VOC>;'
	${LIB} perl -e 'use portage_utils; $$portage_utils::DEBUG=1; portage_utils::zopen(*VOC, "| sed -e 's/t/r/g' > ${F_PREFIX}") or die "BAD pipe"; print VOC "test\n";'
	${LIB} perl -e 'use portage_utils; $$portage_utils::DEBUG=1; portage_utils::zopen(*VOC, "sed -e 's/r/d/g' ${F_PREFIX} |") or die "BAD pipe"; print <VOC>;'
