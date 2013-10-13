# Copyright (c) 2013 Michele Bini

# This program is free software: you can redistribute it and/or modify
# it under the terms of the version 3 of the GNU General Public License
# as published by the Free Software Foundation.

# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

ALL = test

all: $(ALL)

clean: tempclean
	rm -f $(ALL) *.compiled *.compiled.*

## Rules for compiling Mythryl

BAEMHI=build-an-executable-mythryl-heap-image

%.lib: %.pkg
	@ [ -e "$@"~ ] && mv "$@" "$@"~; (echo LIBRARY_EXPORTS && echo && sed -n "s/^generic package \\([a-z0-9_']*\\).*/	generic \\1/p" <"$<" && sed -n "s/^package \\([a-z0-9_']*\\).*/	pkg \\1/p" <"$<" && echo && echo LIBRARY_COMPONENTS && echo && (sed -n "s/.*#  *Requires:  *\\([^ ]*\\)/\\1/p"|sed "s,standard,""$$""ROOT/src/lib/std/standard.lib,"|sed "s/^/	/") <"$<" && echo && echo "	""$<" && echo) >"$@".new
	@ mv "$@".new "$@"
	@ echo Built "$@"


%: %.lib %.pkg
	${MAKE} tempclean
	${BAEMHI} $< main::main

tempclean:
	rm -rf .tmp-* tmp-* *.compile.log

## Generation of various constants ##

%.bc-value: %.bc-expr
	bc -l <$< >.tmp.$@ && mv .tmp.$@ $@

# Discard the first 8192 bits of the fractional part, use the next 8192 for the lookup table
hibiscus-prng-table.pkg.in: phi-tau-e.bc-value Makefile
	echo "package hibiscus_prng_table : api { table: Vector(Unt32) } { table = {" >.tmp.$@
	tr -d -c ".0-9A-Fa-f" <$<|sed "s/^[^.]*[.]//"|sed -E "s/([0-9a-f]{8})/0x\\1\n/gi"|head -n512|tail -n256|tr "\\n" " "|sed 's/ 0x/, 0x/g'|fmt -w 72 >>.tmp.$@
	echo "}; };" >>.tmp.$@
	mv .tmp.$@ $@

hibiscus-prng-seeds.pkg.in: phi-tau-e.bc-value Makefile
	echo "# Generated extra constants:" >.tmp.$@
	tr -d -c ".0-9A-Fa-f" <$<|sed "s/^[^.]*[.]//"|sed -E "s/([0-9a-f]{8})/0x\\1\n/gi"|head -n592|tail -n80|tr "\\n" " "|sed 's/ 0x/, 0x/g'|fmt -w 72 >>.tmp.$@
	mv .tmp.$@ $@
