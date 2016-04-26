## begin license ##
#
# The Meresco Owlim package is an Owlim Triplestore based on meresco-triplestore
#
# Copyright (C) 2013-2014, 2016 Seecr (Seek You Too B.V.) http://seecr.nl
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

from os import system
from os.path import join, dirname, abspath

from seecr.test.integrationtestcase import IntegrationState
from seecr.test.portnumbergenerator import PortNumberGenerator


myDir = dirname(abspath(__file__))
serverBinDir = join(dirname(dirname(myDir)), 'bin')

class OwlimIntegrationState(IntegrationState):
    def __init__(self, stateName, tests=None, fastMode=False):
        IntegrationState.__init__(self, stateName=stateName, tests=tests, fastMode=fastMode)

        self.graphdbDataDir = join(self.integrationTempdir, 'graphdb-data')
        self.graphdbPort = PortNumberGenerator.next()
        self.testdataDir = join(dirname(myDir), 'data')
        if not fastMode:
            system('rm -rf ' + self.integrationTempdir)
            system('mkdir --parents ' + self.graphdbDataDir)

    def setUp(self):
        self.startGraphDBServer()

    def binDir(self):
        return serverBinDir

    def startGraphDBServer(self):
        self._startServer('graphdb', self.binPath('start-graphdb'), 'http://localhost:%s/query' % self.graphdbPort, port=self.graphdbPort, stateDir=self.graphdbDataDir)

    def restartGraphDBServer(self):
        self.stopGraphDBServer()
        self.startGraphDBServer()

    def stopGraphDBServer(self):
        self._stopServer('graphdb')

