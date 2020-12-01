#!/bin/bash
## begin license ##
#
# The Meresco Owlim package is an Owlim Triplestore based on meresco-triplestore
#
# Copyright (C) 2011-2016 Seecr (Seek You Too B.V.) http://seecr.nl
# Copyright (C) 2011 Seek You Too B.V. (CQ2) http://www.cq2.nl
# Copyright (C) 2015 Stichting Kennisnet http://www.kennisnet.nl
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

# source classpath
. ../bin/classpath.sh ..

echo "Arguments: $*"

/usr/lib/jvm/java-1.11.0-openjdk-amd64/bin/java \
     -Xmx3G \
     -cp ${CLASSPATH} \
     -DentityExpansionLimit=1024000 \
     -Dfile.encoding=UTF-8 \
     org.meresco.triplestore.GraphDBServer \
     $*

     #-Dgraphdb.dist=../tmp \ <= equals --stateDir arg
# NOTE: the warning
# [main] WARN com.ontotext.GraphDBConfigParameters - No external plugins found. Some things may not work as expected.
# means that there is no Lucene plugin; something we do not uese

# NOTE: the warning
# [main] WARN com.ontotext.trree.free.GraphDBFreeSchemaRepository - Rule list configuration present, it will override all other rule sets parameters!
# is because the ruleset is empty, see GraphDBTripleStore.java.

# expected args:
#     --stateDir ../tmp \
#     --port 12345
#     --Xmx

