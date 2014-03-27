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

BUILDDIR=../../build/
test -d ${BUILDDIR} && rm -rf ${BUILDDIR}
mkdir ${BUILDDIR}

JUNIT=/usr/share/java/junit4.jar
if [ ! -f ${JUNIT} ]; then
    echo "JUnit is not installed. Please install the junit4 package."
    exit 1
fi

MERESCO_TRIPLESTORE_JARS=$(test -d /usr/share/java/meresco-triplestore && find /usr/share/java/meresco-triplestore -type f -name "*.jar")

if [ -d ../../deps.d ]; then                                      # DO_NOT_DISTRIBUTE
    FIND_RESULT=$(find -L ../../deps.d/* -type f -name "*.jar")   # DO_NOT_DISTRIBUTE
    if [ ! -z "${FIND_RESULT}" ]; then                            # DO_NOT_DISTRIBUTE
        MERESCO_TRIPLESTORE_JARS=${FIND_RESULT}                   # DO_NOT_DISTRIBUTE
    fi                                                            # DO_NOT_DISTRIBUTE
fi
OWLIMJARS=$(find /usr/share/java/owlim-lite-java/ -type f -name "*.jar")
JARS=$(find ../../jars -type f -name "*.jar")

CP="$JUNIT:$(echo $OWLIMJARS | tr ' ' ':'):$(echo $MERESCO_TRIPLESTORE_JARS | tr ' ' ':'):$(echo $JARS | tr ' ' ':'):../../build"

javaFiles=$(find ../java -name "*.java")
javac -d ${BUILDDIR} -cp $CP $javaFiles
if [ "$?" != "0" ]; then
    echo "Build failed"
    exit 1
fi

javaFiles=$(find . -name "*.java")
javac -d ${BUILDDIR} -cp $CP $javaFiles
if [ "$?" != "0" ]; then
    echo "Test Build failed"
    exit 1
fi

testClasses=$(cd ${BUILDDIR}; find . -name "*Test.class" | sed 's,.class,,g' | tr '/' '.' | sed 's,..,,')
echo "Running $testClasses"
java -Xmx1024m -classpath ".:$CP" org.junit.runner.JUnitCore $testClasses

