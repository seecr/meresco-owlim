# -*- coding: utf-8 -*-
## begin license ##
#
# The Meresco Owlim package is an Owlim Triplestore based on meresco-triplestore
#
# Copyright (C) 2011-2014, 2016 Seecr (Seek You Too B.V.) http://seecr.nl
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

from shutil import rmtree, copyfile
from os.path import join, abspath, isdir
from os import kill, waitpid, WNOHANG, system, symlink, makedirs
from simplejson import loads
from urllib import urlencode
from urllib2 import urlopen, Request
from signal import SIGKILL, SIGTERM
from time import time, sleep
from threading import Thread
from socket import error as socketError

from weightless.core import compose

from seecr.test.utils import getRequest, postRequest
from seecr.test.integrationtestcase import IntegrationTestCase

from meresco.triplestore import HttpClient, MalformedQueryException, InvalidRdfXmlException
from seecr.test.io import stderr_replaced


class OwlimTest(IntegrationTestCase):
    def testOne(self):
        result = urlopen("http://localhost:%s/query?%s" % (self.owlimPort, urlencode(dict(query='SELECT ?x WHERE {}')))).read()
        self.assertEquals(["x"], loads(result)["head"]["vars"])

    def testAddTripleThatsNotATriple(self):
        owlimClient = HttpClient(host='localhost', port=self.owlimPort, synchronous=True)
        try:
            list(compose(owlimClient.addTriple('uri:subject', 'uri:predicate', '')))
            self.fail("should not get here")
        except ValueError, e:
            self.assertEquals('java.lang.IllegalArgumentException: Not a triple: "uri:subject|uri:predicate|"', str(e))

    def testAddInvalidRdf(self):
        owlimClient = HttpClient(host='localhost', port=self.owlimPort, synchronous=True)
        try:
            list(compose(owlimClient.add('uri:identifier', '<invalidRdf/>')))
            self.fail("should not get here")
        except InvalidRdfXmlException, e:
            self.assertTrue('org.openrdf.rio.RDFParseException: Not a valid (absolute) URI: #invalidRdf [line 1, column 14]' in str(e), str(e))

    def testAddInvalidIdentifier(self):
        owlimClient = HttpClient(host='localhost', port=self.owlimPort, synchronous=True)
        try:
            list(compose(owlimClient.add('identifier', '<ignore/>')))
            self.fail("should not get here")
        except ValueError, e:
            self.assertEquals('java.lang.IllegalArgumentException: Not a valid (absolute) URI: identifier', str(e))

    def testInvalidSparql(self):
        owlimClient = HttpClient(host='localhost', port=self.owlimPort, synchronous=True)
        try:
            list(compose(owlimClient.executeQuery("""select ?x""")))
            self.fail("should not get here")
        except MalformedQueryException, e:
            self.assertTrue(str(e).startswith('org.openrdf.query.MalformedQueryException: Encountered "<EOF>"'), str(e))

    def testKillTripleStoreSavesState(self):
        postRequest(self.owlimPort, "/add?identifier=uri:record", """<rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#">
        <rdf:Description>
            <rdf:type>uri:testKillTripleStoreSavesState</rdf:type>
        </rdf:Description>
    </rdf:RDF>""", parse=False)
        self.commit()
        json = self.query('SELECT ?x WHERE {?x ?y "uri:testKillTripleStoreSavesState"}')
        self.assertEquals(1, len(json['results']['bindings']))

        rmtree(join(self.owlimDataDir, "transactionLog"))
        self.restartOwlimServer()

        json = self.query('SELECT ?x WHERE {?x ?y "uri:testKillTripleStoreSavesState"}')
        self.assertEquals(1, len(json['results']['bindings']))

    def testKillTripleStoreRecoversFromTransactionLog(self):
        postRequest(self.owlimPort, "/add?identifier=uri:record", """<rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#">
        <rdf:Description>
            <rdf:type rdf:resource="uri:testKillTripleStoreRecoversFromTransactionLog"/>
        </rdf:Description>
    </rdf:RDF>""", parse=False)
        postRequest(self.owlimPort, "/addTriple", "uri:subject|http://www.w3.org/1999/02/22-rdf-syntax-ns#type|uri:testKillTripleStoreRecoversFromTransactionLog")
        self.commit()
        json = self.query('SELECT ?x WHERE {?x ?y <uri:testKillTripleStoreRecoversFromTransactionLog>}')
        self.assertEquals(2, len(json['results']['bindings']))

        kill(self.pids['owlim'], SIGTERM)
        waitpid(self.pids['owlim'], WNOHANG)
        sleep(1)
        self.startOwlimServer()

        json = self.query('SELECT ?x WHERE {?x ?y <uri:testKillTripleStoreRecoversFromTransactionLog>}')
        self.assertEquals(2, len(json['results']['bindings']))

    @stderr_replaced
    def testKillTripleStoreWhileDoingQuery(self):
        def doQueries():
            for i in range(1000):
                self.query('SELECT ?x WHERE { ?x ?y ?z }')
        t = Thread(target=doQueries)
        t.start()
        for i in range(100):
            header, body = postRequest(self.owlimPort, "/addTriple", "uri:subject%s|uri:predicate%s|uri:object%s" % (i, i, i), parse=False)
        self.stopOwlimServer()
        t.join()
        self.assertTrue('Shutdown completed.' in open(join(self.integrationTempdir, 'stdouterr-owlim.log')).read())
        self.startOwlimServer()

    def xxxtestKillAndRestoreLargeTransactionLogTiming(self):
        postRequest(self.owlimPort, "/add?identifier=uri:record", """<rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#">
        <rdf:Description>
            <rdf:type>uri:testKillTripleStoreRecoversFromTransactionLog</rdf:type>
        </rdf:Description>
    </rdf:RDF>""", parse=False)
        json = self.query('SELECT ?x WHERE {?x ?y "uri:testKillTripleStoreRecoversFromTransactionLog"}')
        self.assertEquals(1, len(json['results']['bindings']))

        kill(self.pids['owlim'], SIGKILL)
        waitpid(self.pids['owlim'], WNOHANG)

        bigTestTransactionLogPath = '/home/zp/owlim_translog_1348054481457000' # or whatever path to big transaction log

        rmtree(join(self.integrationTempdir, 'owlim-data/transactionLog'))
        isdir("integration/transactionLog") or makedirs("integration/transactionLog")
        symlink(abspath("integration/transactionLog"), join(self.integrationTempdir, 'owlim-data/transactionLog'))
        target = join(self.integrationTempdir, 'owlim-data/transactionLog/current')
        copyfile(bigTestTransactionLogPath, target)
        print time()
        self.startOwlimServer()
        print time()

    def testDeleteRecord(self):
        postRequest(self.owlimPort, "/add?identifier=uri:record", """<rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#">
        <rdf:Description>
            <rdf:type>uri:testDelete</rdf:type>
        </rdf:Description>
    </rdf:RDF>""", parse=False)
        self.commit()
        json = self.query('SELECT ?x WHERE {?x ?y "uri:testDelete"}')
        self.assertEquals(1, len(json['results']['bindings']))

        postRequest(self.owlimPort, "/update?identifier=uri:record", """<rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#">
        <rdf:Description>
            <rdf:type>uri:testDeleteUpdated</rdf:type>
        </rdf:Description>
    </rdf:RDF>""", parse=False)
        self.commit()
        json = self.query('SELECT ?x WHERE {?x ?y "uri:testDelete"}')
        self.assertEquals(0, len(json['results']['bindings']))
        json = self.query('SELECT ?x WHERE {?x ?y "uri:testDeleteUpdated"}')
        self.assertEquals(1, len(json['results']['bindings']))

        postRequest(self.owlimPort, "/delete?identifier=uri:record", "", parse=False)
        self.commit()
        json = self.query('SELECT ?x WHERE {?x ?y "uri:testDelete"}')
        self.assertEquals(0, len(json['results']['bindings']))
        json = self.query('SELECT ?x WHERE {?x ?y "uri:testDeleteUpdated"}')
        self.assertEquals(0, len(json['results']['bindings']))

        postRequest(self.owlimPort, "/add?identifier=uri:record", """<rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#">
        <rdf:Description>
            <rdf:type>uri:testDelete</rdf:type>
        </rdf:Description>
    </rdf:RDF>""", parse=False)
        self.commit()
        json = self.query('SELECT ?x WHERE {?x ?y "uri:testDelete"}')
        self.assertEquals(1, len(json['results']['bindings']))

    def testAddAndRemoveTriple(self):
        json = self.query('SELECT ?obj WHERE { <uri:subject> <uri:predicate> ?obj }')
        self.assertEquals(0, len(json['results']['bindings']))

        header, body = postRequest(self.owlimPort, "/addTriple", "uri:subject|uri:predicate|uri:object", parse=False)
        self.assertTrue("200" in header, header)
        self.commit()

        json = self.query('SELECT ?obj WHERE { <uri:subject> <uri:predicate> ?obj }')
        self.assertEquals(1, len(json['results']['bindings']))

        header, body = postRequest(self.owlimPort, "/removeTriple", "uri:subject|uri:predicate|uri:object", parse=False)
        self.assertTrue("200" in header, header)
        self.commit()
        json = self.query('SELECT ?obj WHERE { <uri:subject> <uri:predicate> ?obj }')
        self.assertEquals(0, len(json['results']['bindings']))

    def testAddPerformance(self):
        totalTime = 0
        try:
            for i in range(10):
                postRequest(self.owlimPort, "/add?identifier=uri:record", """<rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#">
            <rdf:Description>
                <rdf:type>uri:testFirst%s</rdf:type>
            </rdf:Description>
        </rdf:RDF>""" % i, parse=False)
            number = 1000
            for i in range(number):
                start = time()
                postRequest(self.owlimPort, "/add?identifier=uri:record", """<rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#">
            <rdf:Description>
                <rdf:type>uri:testSecond%s</rdf:type>
            </rdf:Description>
        </rdf:RDF>""" % i, parse=False)
                totalTime += time() - start
            self.assertTiming(0.00015, totalTime / number, 0.0085)
        finally:
            postRequest(self.owlimPort, "/delete?identifier=uri:record", "")

    def testAddPerformanceInCaseOfThreads(self):
        number = 25
        threads = []
        responses = []
        try:
            for i in range(number):
                def doAdd(i=i):
                    header, body = postRequest(self.owlimPort, "/add?identifier=uri:record", """<rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#">
            <rdf:Description>
                <rdf:type>uri:testSecond%s</rdf:type>
            </rdf:Description>
        </rdf:RDF>""" % i, parse=False)
                    responses.append((header, body))
                threads.append(Thread(target=doAdd))

            for thread in threads:
                thread.start()
            for thread in threads:
                thread.join()

            for header, body in responses:
                self.assertTrue('200 OK' in header, header + '\r\n\r\n' + body)
        finally:
            postRequest(self.owlimPort, "/delete?identifier=uri:record", "")

    def testAcceptHeaders(self):
        postRequest(self.owlimPort, "/add?identifier=uri:record", """<rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#">
        <rdf:Description>
            <rdf:type>uri:test:acceptHeaders</rdf:type>
        </rdf:Description>
    </rdf:RDF>""", parse=False)
        self.commit()

        request = Request('http://localhost:%s/query?%s' % (self.owlimPort, urlencode({'query': 'SELECT ?x WHERE {?x ?y "uri:test:acceptHeaders"}'})), headers={"Accept" : "application/xml"})
        contents = urlopen(request).read()
        self.assertTrue("""<variable name='x'/>""" in contents, contents)

        headers, body = getRequest(self.owlimPort, "/query", arguments={'query': 'SELECT ?x WHERE {?x ?y "uri:test:acceptHeaders"}'}, additionalHeaders={"Accept" : "image/jpg"}, parse=False)
        headers = headers.split('\r\n')
        self.assertTrue("HTTP/1.1 200 OK" in headers, headers)
        self.assertTrue("Content-Type: application/sparql-results+json; charset=UTF-8" in headers, headers)

    def testMimeTypeArgument(self):
        postRequest(self.owlimPort, "/add?identifier=uri:record", """<rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#">
        <rdf:Description rdf:about="uri:test:mimeType">
            <rdf:value>Value</rdf:value>
        </rdf:Description>
    </rdf:RDF>""", parse=False)
        self.commit()

        request = Request('http://localhost:%s/query?%s' % (self.owlimPort, urlencode({'query': 'SELECT ?x WHERE {?x ?y "Value"}', 'mimeType': 'application/sparql-results+xml'})))
        contents = urlopen(request).read()
        self.assertEqualsWS("""<?xml version='1.0' encoding='UTF-8'?>
<sparql xmlns='http://www.w3.org/2005/sparql-results#'>
    <head>
        <variable name='x'/>
    </head>
    <results>
        <result>
            <binding name='x'>
                <uri>uri:test:mimeType</uri>
            </binding>
        </result>
    </results>
</sparql>""", contents)

    def testDescribeQuery(self):
        postRequest(self.owlimPort, "/add?identifier=uri:record", """<rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#">
        <rdf:Description rdf:about="uri:test:describe">
            <rdf:value>DESCRIBE</rdf:value>
        </rdf:Description>
    </rdf:RDF>""", parse=False)
        self.commit()

        headers, body = getRequest(self.owlimPort, "/query", arguments={'query': 'DESCRIBE <uri:test:describe>'}, additionalHeaders={"Accept" : "application/rdf+xml"}, parse=False)
        self.assertTrue("Content-Type: application/rdf+xml" in headers, headers)
        self.assertXmlEquals("""<rdf:RDF
    xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
    xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#"
    xmlns:sesame="http://www.openrdf.org/schema/sesame#"
    xmlns:owl="http://www.w3.org/2002/07/owl#"
    xmlns:xsd="http://www.w3.org/2001/XMLSchema#"
    xmlns:fn="http://www.w3.org/2005/xpath-functions#">
<rdf:Description rdf:about="uri:test:describe">
    <rdf:value rdf:datatype="http://www.w3.org/2001/XMLSchema#string">DESCRIBE</rdf:value>
</rdf:Description></rdf:RDF>""", body)

    def testAddUnicodeChars(self):
        postRequest(self.owlimPort, "/add?identifier=uri:unicode:chars", """<rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#">
        <rdf:Description rdf:about="uri:unicode:chars">
            <rdfs:label>Ittzés, Gergely</rdfs:label>
        </rdf:Description>
    </rdf:RDF>""", parse=False)
        self.commit()
        json = self.query('SELECT ?label WHERE {<uri:unicode:chars> ?x ?label}')
        self.assertEquals(1, len(json['results']['bindings']))
        self.assertEqual('Ittzés, Gergely', json['results']['bindings'][0]['label']['value'])

    def query(self, query):
        u = urlopen('http://localhost:%s/query?%s' % (self.owlimPort, urlencode(dict(query=query))))
        return loads(u.read())

    def commit(self):
        header, body = postRequest(self.owlimPort, "/commit")
        self.assertTrue("200 OK" in header.upper(), header + body)
