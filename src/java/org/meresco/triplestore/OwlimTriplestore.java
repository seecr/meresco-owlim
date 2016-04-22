/* begin license *
 *
 * The Meresco Owlim package is an Owlim Triplestore based on meresco-triplestore
 *
 * Copyright (C) 2014, 2016 Seecr (Seek You Too B.V.) http://seecr.nl
 *
 * This file is part of "Meresco Owlim"
 *
 * "Meresco Owlim" is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * "Meresco Owlim" is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with "Meresco Owlim"; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
 *
 * end license */

package org.meresco.triplestore;

import java.io.File;
import java.io.StringReader;

import org.openrdf.model.Resource;
import org.openrdf.model.impl.LiteralImpl;
import org.openrdf.model.impl.TreeModel;
import org.openrdf.model.util.GraphUtil;
import org.openrdf.model.vocabulary.RDF;
import org.openrdf.repository.config.RepositoryConfig;
import org.openrdf.repository.config.RepositoryConfigSchema;
import org.openrdf.repository.manager.LocalRepositoryManager;
import org.openrdf.repository.sail.config.SailRepositorySchema;
import org.openrdf.rio.RDFFormat;
import org.openrdf.rio.RDFParser;
import org.openrdf.rio.Rio;
import org.openrdf.rio.helpers.StatementCollector;

import com.ontotext.trree.config.OWLIMSailSchema;

class OwlimTriplestore extends SesameTriplestore {

    private LocalRepositoryManager repositoryManager;
    private static String REPO_CONFIG = "@prefix rep: <http://www.openrdf.org/config/repository#>."
            + "@prefix sr: <http://www.openrdf.org/config/repository/sail#>."
            + "@prefix sail: <http://www.openrdf.org/config/sail#>."
            + "@prefix owlim: <http://www.ontotext.com/trree/owlim#>."
            + "[] a rep:Repository ; "
            + "rep:repositoryImpl ["
                + "rep:repositoryType \"graphdb:FreeSailRepository\" ;"
                + "sr:sailImpl [ "
                    + "sail:sailType \"graphdb:FreeSail\" ; "
                    + "owlim:enable-context-index \"true\"; "
                    + "owlim:ruleset \"empty\" ;"
                    + "owlim:disable-sameAs \"true\" ;"
                    + "owlim:enablePredicateList \"true\" ;"
                    + "owlim:fts-memory \"0\" ;"
                    + "owlim:in-memory-literal-properties \"true\" ;"
                    + "owlim:enable-literal-index \"true\" ;"
            + "] ].";

    public OwlimTriplestore(File directory, String storageName, String cacheMemory, String entityIndexSize) throws Exception {
        super(directory);

        repositoryManager = new LocalRepositoryManager(directory);
        repositoryManager.initialize();

        TreeModel graph = new TreeModel();

        RDFParser rdfParser = Rio.createParser(RDFFormat.TURTLE);
        rdfParser.setRDFHandler(new StatementCollector(graph));
        rdfParser.parse(new StringReader(REPO_CONFIG), RepositoryConfigSchema.NAMESPACE);

        Resource repositoryNode = GraphUtil.getUniqueSubject(graph, RDF.TYPE, RepositoryConfigSchema.REPOSITORY);
        graph.add(repositoryNode, RepositoryConfigSchema.REPOSITORYID, new LiteralImpl(storageName));

        Resource configNode = GraphUtil.getUniqueObjectResource(graph, null, SailRepositorySchema.SAILIMPL);
        graph.add(configNode, OWLIMSailSchema.storagefolder, new LiteralImpl(storageName));
        if (cacheMemory != null)
            graph.add(configNode, OWLIMSailSchema.cacheMemory, new LiteralImpl(cacheMemory));
        if (entityIndexSize != null)
            graph.add(configNode, OWLIMSailSchema.entityindexsize, new LiteralImpl(entityIndexSize));

        RepositoryConfig repositoryConfig = RepositoryConfig.create(graph, repositoryNode);
        repositoryManager.addRepositoryConfig(repositoryConfig);
        this.repository = repositoryManager.getRepository(storageName);
        this.startup();
    }

    public void shutdown() throws Exception {
        super.shutdown();
        this.repositoryManager.shutDown();
    }
}