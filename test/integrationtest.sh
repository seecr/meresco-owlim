#!/bin/bash
## begin license ##
#
# The Meresco Owlim package is an Owlim Triplestore based on meresco-triplestore
#
# Copyright (C) 2014, 2016 Seecr (Seek You Too B.V.) http://seecr.nl
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

export LANG=en_US.UTF-8
export PYTHONPATH=.:$PYTHONPATH
#export JAVA_BIN=/usr/lib/jvm/java-1.8.0-openjdk-amd64/bin

# source CLASSPATH
#. ../bin/classpath.sh ..

pycmd="python3.7"

option=$1
if [ "${option:0:10}" == "--python" ]; then
    shift
    pycmd="${option:3}"
fi
echo Using Python version: $pycmd
echo "================ $pycmd _integrationtest.py $@ ================"
$pycmd _integrationtest.py "$@"
