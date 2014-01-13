#!/bin/bash
## begin license ##
#
# The Meresco Owlim package is an Owlim Triplestore based on meresco-triplestore
#
# Copyright (C) 2014 Seecr (Seek You Too B.V.) http://seecr.nl
#
# This file is part of "Meresco Owlim"
#
# "Meresco Owlim" is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# "Meresco Owlim" is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with "Meresco Owlim"; if not, write to the Free Software
# Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
#
## end license ##

VERSION=$1

if ! javac -version 2>&1 | grep 1.6 > /dev/null; then
    echo "javac should be java 6"
    exit 1
fi

MERESCO_TRIPLESTORE_JARS=$(test -d /usr/share/java/meresco-triplestore && find /usr/share/java/meresco-triplestore -type f -name "*.jar")
if [ -d deps.d ]; then                                      # DO_NOT_DISTRIBUTE
    FIND_RESULT=$(find -L deps.d/* -type f -name "*.jar")   # DO_NOT_DISTRIBUTE
    if [ ! -z "${FIND_RESULT}" ]; then                      # DO_NOT_DISTRIBUTE
        MERESCO_TRIPLESTORE_JARS=${FIND_RESULT}             # DO_NOT_DISTRIBUTE
    fi                                                      # DO_NOT_DISTRIBUTE
fi                                                          # DO_NOT_DISTRIBUTE
OWLIMJARS=$(find /usr/share/java/owlim-lite-java/ -type f -name "*.jar")
JARS=$(find jars -type f -name "*.jar")

BUILDDIR=./build
TARGET=meresco-owlim.jar
if [ "${VERSION}" != "" ]; then
    TARGET=meresco-owlim-${VERSION}.jar
fi

test -d $BUILDDIR && rm -r $BUILDDIR
mkdir $BUILDDIR

CP="$(echo $JARS | tr ' ' ':'):$(echo $MERESCO_TRIPLESTORE_JARS | tr ' ' ':'):$(echo $OWLIMJARS | tr ' ' ':')"

javaFiles=$(find src/java -name "*.java")
javac -d $BUILDDIR -cp $CP $javaFiles
if [ "$?" != "0" ]; then
    echo "Build failed"
    exit 1
fi

jar -cf $TARGET -C $BUILDDIR org

