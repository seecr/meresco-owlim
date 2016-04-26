/* begin license *
 *
 * The Meresco Owlim package is an Owlim Triplestore based on meresco-triplestore
 *
 * Copyright (C) 2011-2014, 2016 Seecr (Seek You Too B.V.) http://seecr.nl
 * Copyright (C) 2011 Seek You Too B.V. (CQ2) http://www.cq2.nl
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
import java.nio.charset.Charset;
import java.util.Properties;
import java.util.concurrent.ArrayBlockingQueue;
import java.util.concurrent.TimeUnit;

import org.apache.commons.cli.Option;
import org.apache.commons.cli.Options;
import org.apache.commons.cli.PosixParser;
import org.eclipse.jetty.server.HttpConnectionFactory;
import org.eclipse.jetty.server.Server;
import org.eclipse.jetty.server.ServerConnector;
import org.eclipse.jetty.server.handler.ContextHandler;
import org.eclipse.jetty.util.thread.ExecutorThreadPool;
import org.apache.commons.cli.CommandLine;
import org.apache.commons.cli.HelpFormatter;
import org.apache.commons.cli.MissingOptionException;

import sun.misc.Signal;
import sun.misc.SignalHandler;

public class GraphDBServer {
    public static void main(String[] args) throws Exception {
        Option option;

        Options options = new Options();

        // Port Number
        option = new Option("p", "port", true, "Port number");
        option.setType(Integer.class);
        option.setRequired(true);
        options.addOption(option);

        // Triplestore name
        option = new Option("n", "name", true, "Name of the triplestore. Defaults to triplestore");
        option.setType(String.class);
        option.setRequired(false);
        options.addOption(option);

        // Triplestore location
        option = new Option("d", "stateDir", true, "Directory in which triplestore is located");
        option.setType(String.class);
        option.setRequired(true);
        options.addOption(option);

        option = new Option(null, "cacheMemory", true, "Cache size; Usually half -Xmx");
        option.setType(String.class);
        option.setRequired(false);
        options.addOption(option);

        option = new Option(null, "entityIndexSize", true, "Entity index size. Usually half the number of entities (Uri's, blank nodes, literals). Cannot be changed after indexing.");
        option.setType(Integer.class);
        option.setRequired(false);
        options.addOption(option);

        option = new Option(null, "queryTimeout", true, "Query timeout in seconds. Defaults to 0 (no limit)");
        option.setType(Integer.class);
        option.setRequired(false);
        options.addOption(option);

        option = new Option(null, "maxCommitCount", true, "Max number of commits for updates.");
        option.setType(Integer.class);
        option.setRequired(false);
        options.addOption(option);

        option = new Option(null, "maxCommitTimeout", true, "Maximum seconds after update for a commit.");
        option.setType(Integer.class);
        option.setRequired(false);
        options.addOption(option);

        PosixParser parser = new PosixParser();
        CommandLine commandLine = null;
        try {
            commandLine = parser.parse(options, args);
        } catch (MissingOptionException e) {
            HelpFormatter helpFormatter = new HelpFormatter();
            helpFormatter.printHelp("start-graphdb" , options);
            System.exit(1);
        }

        Integer port = new Integer(commandLine.getOptionValue("p"));
        String storeLocation = commandLine.getOptionValue("d");
        String storeName = commandLine.getOptionValue("n");
        if (storeName == null)
            storeName = "triplestore";
        String cacheMemory = commandLine.getOptionValue("cacheMemory");
        String entityIndexSize = commandLine.getOptionValue("entityIndexSize");
        String queryTimeout = commandLine.getOptionValue("queryTimeout");
        if (queryTimeout == null)
            queryTimeout = "0";
        String maxCommitCount = commandLine.getOptionValue("maxCommitCount");
        String maxCommitTimeout = commandLine.getOptionValue("maxCommitTimeout");

        if (Charset.defaultCharset() != Charset.forName("UTF-8")) {
        	System.err.println("file.encoding must be UTF-8.");
            System.exit(1);
        }

        long startTime = System.currentTimeMillis();
        GraphDBTriplestore tripleStore = new GraphDBTriplestore(new File(storeLocation), storeName, cacheMemory, entityIndexSize, queryTimeout);
        if (maxCommitCount != null)
            tripleStore.setMaxCommitCount(Integer.parseInt(maxCommitCount));
        if (maxCommitTimeout != null)
            tripleStore.setMaxCommitTimeout(Integer.parseInt(maxCommitTimeout));

        ExecutorThreadPool pool = new ExecutorThreadPool(50, 200, 60, TimeUnit.SECONDS, new ArrayBlockingQueue<Runnable>(1000));
        Server server = new Server(pool);

        ContextHandler context = new ContextHandler("/");
        context.setHandler(new HttpHandler(tripleStore));

        ServerConnector http = new ServerConnector(server, new HttpConnectionFactory());
        http.setPort(port);
        server.addConnector(http);

        registerShutdownHandler(tripleStore, server);

        server.setHandler(context);
        server.start();
        server.join();
    }

    static void registerShutdownHandler(final Triplestore tripleStore, final Server server) {
        Signal.handle(new Signal("TERM"), new SignalHandler() {
            public void handle(Signal sig) {
                shutdown(server, tripleStore);
            }
        });
        Signal.handle(new Signal("INT"), new SignalHandler() {
            public void handle(Signal sig) {
                shutdown(server, tripleStore);
            }
        });
    }

    static void shutdown(final Server server, final Triplestore tripleStore) {
        System.out.println("Shutting down triplestore. Please wait...");
        try {
            tripleStore.shutdown();
            System.out.println("Shutdown completed.");
            System.out.flush();
        } catch (Exception e) {
            e.printStackTrace();
            System.err.flush();
            System.out.println("Shutdown failed.");
            System.out.flush();
        }
        try {
            server.stop();
        } catch (Exception e) {
            e.printStackTrace();
        }
        System.out.println("Http-server stopped");
        System.exit(0);
    }
}
