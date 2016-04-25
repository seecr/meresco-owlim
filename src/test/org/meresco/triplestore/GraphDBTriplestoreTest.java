/* begin licenseB* end license */

package org.meresco.triplestore;

import java.util.ArrayList;
import java.util.List;
import java.util.zip.GZIPInputStream;
import java.io.File;
import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.io.FileInputStream;
import java.io.PrintStream;
import java.io.ByteArrayOutputStream;
import java.io.OutputStream;
import org.junit.Test;
import org.junit.Ignore;
import org.junit.Before;
import org.junit.After;
import static org.junit.Assert.*;

import static org.meresco.triplestore.Utils.createTempDirectory;
import static org.meresco.triplestore.Utils.deleteDirectory;

import org.openrdf.query.resultio.TupleQueryResultFormat;
import org.openrdf.repository.RepositoryResult;
import org.openrdf.model.Statement;
import org.openrdf.model.Namespace;
import org.openrdf.model.impl.URIImpl;
import org.openrdf.model.impl.LiteralImpl;
import org.openrdf.rio.RDFFormat;

public class GraphDBTriplestoreTest {
    GraphDBTriplestore ts;
    File tempdir;

    @Before
    public void setUp() throws Exception {
        tempdir = createTempDirectory();
        ts = new GraphDBTriplestore(tempdir, "storageName", null, null, "0");
    }

    @After
    public void tearDown() throws Exception {
        ts.shutdown();
        deleteDirectory(tempdir);
    }

    static final String rdf = "<?xml version='1.0'?>" +
        "<rdf:RDF xmlns:rdf='http://www.w3.org/1999/02/22-rdf-syntax-ns#'" +
        "             xmlns:exterms='http://www.example.org/terms/'>" +
        "  <rdf:Description rdf:about='http://www.example.org/index.html'>" +
        "      <exterms:creation-date>August 16, 1999</exterms:creation-date>" +
        "      <rdf:value>A.M. Özman Yürekli</rdf:value>" +
        "  </rdf:Description>" +
        "</rdf:RDF>";

    @Test
    public void testGetNamespaces() throws Exception {
        ts.add("uri:id0", rdf, RDFFormat.RDFXML);
        ts.realCommit();
        List<Namespace> namespacesList = ts.getNamespaces();
        List<String> prefixes = new ArrayList<>();
        for (Namespace n: namespacesList)
            prefixes.add(n.getPrefix());
        assertEquals(7, namespacesList.size());

        assertTrue(prefixes.contains("rdfs"));
        assertTrue(prefixes.contains("exterms"));
    }

    @Test
    public void testAddRemoveTriple() throws Exception {
        long startingPoint = ts.size();
        ts.addTriple("uri:subj|uri:pred|uri:obj");
        ts.realCommit();
        assertEquals(startingPoint + 1, ts.size());
        ts.removeTriple("uri:subj|uri:pred|uri:obj");
        ts.realCommit();
        assertEquals(startingPoint, ts.size());
    }

    @Test
    public void testDelete() throws Exception {
        ts.add("uri:id0", rdf, RDFFormat.RDFXML);
        ts.realCommit();
        long startingPoint = ts.size();
        ts.delete("uri:id0");
        ts.realCommit();
        assertEquals(startingPoint - 2, ts.size());
    }

    @Test
    public void testSparql() throws Exception {
        String answer = null;

        ts.add("uri:id0", rdf, RDFFormat.RDFXML);
        ts.realCommit();
        answer = ts.executeTupleQuery("SELECT ?x ?y ?z WHERE {?x ?y ?z}", TupleQueryResultFormat.JSON);
        assertTrue(answer.indexOf("\"value\" : \"A.M. Özman Yürekli\"") > -1);
        assertTrue(answer.endsWith("\n}"));
    }

    @Test
    public void testSparqlResultInXml() throws Exception {
        String answer = null;

        ts.add("uri:id0", rdf, RDFFormat.RDFXML);
        ts.realCommit();
        answer = ts.executeTupleQuery("SELECT ?x ?y ?z WHERE {?x ?y ?z}", TupleQueryResultFormat.SPARQL);
        assertTrue(answer.startsWith("<?xml"));
        assertTrue(answer.indexOf("<literal>A.M. Özman Yürekli</literal>") > -1);
        assertTrue(answer.endsWith("</sparql>\n"));
    }

    @Test
    public void testShutdown() throws Exception {
        ts.add("uri:id0", rdf, RDFFormat.RDFXML);
        ts.shutdown();
        GraphDBTriplestore ts = new GraphDBTriplestore(tempdir, "storageName", null, null, "0");
        assertEquals(2, ts.size());
        ts.shutdown();
    }

    @Ignore
    public void testShutdownFails() throws Exception {
        File tsPath = new File(tempdir, "anotherOne");
        ts = new GraphDBTriplestore(tempdir, "anotherOne", null, null, "0");
        ts.shutdown();
        ts.startup();
        File contextFile = new File(tsPath, "Contexts.ids");
        Process process = Runtime.getRuntime().exec("chmod 0000 " + contextFile);
        process.waitFor();

        PrintStream originalErrStream = System.err;
        OutputStream os = new ByteArrayOutputStream();
        PrintStream ps = new PrintStream(os);
        System.setErr(ps);
        try {
            ts.shutdown();
            fail("Triplestore shouldn't shutdown correctly");
        } catch (Exception e) {
            assertTrue(e.toString().contains("org.openrdf.repository.RepositoryException"));
        } finally {
            System.setErr(originalErrStream);
        }
    }

    @Test
    public void testExport() throws Exception {
        ts.shutdown();
        ts = new GraphDBTriplestore(tempdir, "storageName", null, null, "0");
        ts.startup();
        ts.addTriple("uri:subj|uri:pred|uri:obj");
        ts.realCommit();
        ts.export("identifier");
        ts.shutdown();
        File backup = new File(new File(tempdir, "backups"), "backup-identifier.trig.gz");
        assertTrue(backup.isFile());
        BufferedReader reader = new BufferedReader(new InputStreamReader(new GZIPInputStream(new FileInputStream(backup))));
        StringBuilder filedata = new StringBuilder();
        String line = reader.readLine();
        while(line != null){
            filedata.append(line);
            line = reader.readLine();
        }
        assertTrue(filedata.toString(), filedata.toString().contains("<uri:subj> <uri:pred> <uri:obj>"));
    }

    String trig = "@prefix xsd: <http://www.w3.org/2001/XMLSchema#> . \n" +
"@prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#> . \n" +
"@prefix rdfs: <http://www.w3.org/2000/01/rdf-schema#> . \n" +
"\n" +
"<uri:aContext> { \n" +
"        <uri:aSubject> <uri:aPredicate> \"a literal  value\" . \n" +
"}";

    @Test
    public void testImport() throws Exception {
        long startingPoint = ts.size();
        ts.importTrig(trig);
        ts.realCommit();
        assertEquals(startingPoint + 1, ts.size());
    }
}
