
BASE_DIR=$1
echo "Base directory: $BASE_DIR"

function join_by { local IFS="$1"; shift; echo "$*"; }

if [ -d /usr/share/java/graph-db-java ]; then
    GRAPH_DB_DEPS=$(join_by : \
        /usr/share/java/graph-db-java/slf4j-api-1.7.16.jar \
        /usr/share/java/graph-db-java/jcl-over-slf4j-1.7.16.jar \
        /usr/share/java/slf4j-simple.jar \
        /usr/share/java/graph-db-java/httpclient-4.4.1.jar \
        /usr/share/java/graph-db-java/graphdb-free-runtime-7.2.0.jar \
        /usr/share/java/graph-db-java/metrics-healthchecks-3.1.0.jar \
        /usr/share/java/graph-db-java/metrics-core-3.1.0.jar \
        /usr/share/java/graph-db-java/trove4j-2.0.2.jar \
        /usr/share/java/graph-db-java/logback-core-1.1.5.jar \
        /usr/share/java/graph-db-java/caffeine-2.3.1.jar \
        /usr/share/java/graph-db-java/commons-codec-1.10.jar \
        /usr/share/java/graph-db-java/tomcat-embed-core-8.0.32.jar \
        /usr/share/java/graph-db-java/commons-cli-1.3.1.jar \
        /usr/share/java/graph-db-java/commons-io-2.4.jar \
        /usr/share/java/graph-db-java/sesame-model-2.9.0.jar \
        /usr/share/java/graph-db-java/sesame-query-2.9.0.jar \
        /usr/share/java/graph-db-java/sesame-queryresultio-api-2.9.0.jar \
        /usr/share/java/graph-db-java/sesame-repository-api-2.9.0.jar \
        /usr/share/java/graph-db-java/sesame-repository-manager-2.9.0.jar \
        /usr/share/java/graph-db-java/sesame-rio-api-2.9.0.jar \
        /usr/share/java/graph-db-java/sesame-repository-sail-2.9.0.jar \
        /usr/share/java/graph-db-java/sesame-http-client-2.9.0.jar \
        /usr/share/java/graph-db-java/sesame-repository-event-2.9.0.jar \
        /usr/share/java/graph-db-java/sesame-queryalgebra-model-2.9.0.jar \
        /usr/share/java/graph-db-java/sesame-sail-api-2.9.0.jar \
        /usr/share/java/graph-db-java/sesame-sail-memory-2.9.0.jar \
        /usr/share/java/graph-db-java/sesame-sail-base-2.9.0.jar \
        /usr/share/java/graph-db-java/sesame-queryalgebra-evaluation-2.9.0.jar \
        /usr/share/java/graph-db-java/sesame-queryparser-api-2.9.0.jar \
        /usr/share/java/graph-db-java/sesame-sail-inferencer-2.9.0.jar \
        /usr/share/java/graph-db-java/sesame-rio-turtle-2.9.0.jar \
        /usr/share/java/graph-db-java/sesame-rio-rdfxml-2.9.0.jar \
        /usr/share/java/graph-db-java/sesame-rio-datatypes-2.9.0.jar \
        /usr/share/java/graph-db-java/sesame-rio-languages-2.9.0.jar \
        /usr/share/java/graph-db-java/sesame-util-2.9.0.jar \
        /usr/share/java/graph-db-java/commons-httpclient-3.1.jar \
        /usr/share/java/graph-db-java/sesame-rio-trig-2.9.0.jar \
        /usr/share/java/graph-db-java/sesame-queryparser-sparql-2.9.0.jar \
        /usr/share/java/graph-db-java/sesame-queryresultio-sparqljson-2.9.0.jar \
        /usr/share/java/graph-db-java/sesame-queryresultio-sparqlxml-2.9.0.jar \
        /usr/share/java/graph-db-java/guava-18.0.jar \
        /usr/share/java/graph-db-java/sesame-config-2.9.0.jar \
        /usr/share/java/graph-db-java/sesame-console-2.9.0.jar \
        /usr/share/java/graph-db-java/sesame-http-protocol-2.9.0.jar \
        /usr/share/java/graph-db-java/sesame-http-server-spring-2.9.0.jar \
        /usr/share/java/graph-db-java/sesame-queryparser-serql-2.9.0.jar \
        /usr/share/java/graph-db-java/sesame-queryrender-2.9.0.jar \
        /usr/share/java/graph-db-java/sesame-queryresultio-binary-2.9.0.jar \
        /usr/share/java/graph-db-java/sesame-queryresultio-text-2.9.0.jar \
        /usr/share/java/graph-db-java/sesame-repository-contextaware-2.9.0.jar \
        /usr/share/java/graph-db-java/sesame-repository-dataset-2.9.0.jar \
        /usr/share/java/graph-db-java/sesame-repository-http-2.9.0.jar \
        /usr/share/java/graph-db-java/sesame-repository-sparql-2.9.0.jar \
        /usr/share/java/graph-db-java/sesame-rio-binary-2.9.0.jar \
        /usr/share/java/graph-db-java/sesame-rio-jsonld-2.9.0.jar \
        /usr/share/java/graph-db-java/sesame-rio-n3-2.9.0.jar \
        /usr/share/java/graph-db-java/sesame-rio-nquads-2.9.0.jar \
        /usr/share/java/graph-db-java/sesame-rio-ntriples-2.9.0.jar \
        /usr/share/java/graph-db-java/sesame-rio-rdfjson-2.9.0.jar \
        /usr/share/java/graph-db-java/sesame-rio-rdfxml-2.9.0.jar \
        /usr/share/java/graph-db-java/sesame-rio-trix-2.9.0.jar \
        /usr/share/java/graph-db-java/sesame-sail-federation-2.9.0.jar \
        /usr/share/java/graph-db-java/sesame-sail-model-2.9.0.jar \
        /usr/share/java/graph-db-java/sesame-sail-nativerdf-2.9.0.jar \
        /usr/share/java/graph-db-java/sesame-sail-spin-2.9.0.jar \
        /usr/share/java/graph-db-java/sesame-spin-2.9.0.jar \
        )
else
    echo "Dependency graph-db-java not found. Please install it."
    exit
fi
echo "Graph DB Jars: $GRAPH_DB_DEPS"
echo


if [ -x ${BASE_DIR}/deps.d/meresco-triplestore ]; then
    MT_DEPS=$(join_by : \
        ${BASE_DIR}/deps.d/meresco-triplestore/server/build \
        ${BASE_DIR}/deps.d/meresco-triplestore/server/jars/commons-codec-1.7.jar \
        ${BASE_DIR}/deps.d/meresco-triplestore/server/jars/commons-io-2.1.jar \
        ${BASE_DIR}/deps.d/meresco-triplestore/server/jars/commons-lang3-3.0.1.jar \
        ${BASE_DIR}/deps.d/meresco-triplestore/server/jars/jackson-core-2.3.0.jar \
        ${BASE_DIR}/deps.d/meresco-triplestore/server/jars/javax.servlet-api-3.1.0.jar \
        ${BASE_DIR}/deps.d/meresco-triplestore/server/jars/jetty-all-9.2.14.v20151106.jar \
        )
elif [ -d "/usr/share/java/meresco-triplestore" ]; then
    MT_DEPS=$(join_by : \
        /usr/share/java/meresco-triplestore/commons-codec-1.7.jar \
        /usr/share/java/meresco-triplestore/commons-io-2.1.jar \
        /usr/share/java/meresco-triplestore/commons-lang3-3.0.1.jar \
        /usr/share/java/meresco-triplestore/jackson-core-2.3.0.jar \
        /usr/share/java/meresco-triplestore/javax.servlet-api-3.1.0.jar \
        /usr/share/java/meresco-triplestore/jetty-all-9.2.14.v20151106.jar \
        /usr/share/java/meresco-triplestore/meresco-triplestore-5.2.1.3.jar \
        /usr/share/java/meresco-triplestore/meresco-triplestore.jar \
        )
        # more jars from meresco-triplestore
        # /usr/share/java/meresco-triplestore/slf4j-api-1.6.6.jar \
        # /usr/share/java/meresco-triplestore/slf4j-jdk14-1.6.6.jar \
        #${BASE_DIR}/deps.d/meresco-triplestore/server/jars/openrdf-sesame-2.8.11-onejar.jar \
else
    echo "Dependency meresco-triplestore not found. Please install it or clone it in depd.d."
    exit
fi
echo "Meresco Triplestore Jars: $MT_DEPS"
echo


if [ -d "${BASE_DIR}/.git" ]; then
    echo "Development mode."
    MY_DEPS=$(join_by : \
        ${BASE_DIR}/build \
        )
        # More Jars from same dir, not needed or conflicting
        # ${BASE_DIR}/jars/javax.servlet-api-3.1.0.jar \
        # ${BASE_DIR}/jars/jetty-all-9.2.14.v20151106.jar \
        # ${BASE_DIR}/jars/commons-cli-1.2.jar \
else
    MY_DEPS=$(join_by : \
        /usr/share/java/meresco-triplestore/meresco-triplestore.jar \
        )
        # More jars from same dir
        # /usr/share/java/meresco-triplestore/javax.servlet-api-3.1.0.jar \
        # /usr/share/java/meresco-triplestore/jetty-all-9.2.14.v20151106.jar \
fi
echo "My Deps: ${MY_DEPS}"
echo


CLASSPATH=${MY_DEPS}:${MT_DEPS}:${GRAPH_DB_DEPS}


JAVA_VERSION=8
JAVAC=/usr/lib/jvm/java-1.${JAVA_VERSION}.0-openjdk.x86_64/bin/javac
if [ -f /etc/debian_version ]; then
    #DEBIAN_VERSION=`cat /etc/debian_version`
    #if [ $((${DEBIAN_VERSION:0:2})) -ge 10 ]; then
    #    JAVA_VERSION=11
    #fi
    echo "Using JAVA $JAVA_VERSION"
    JAVAC=/usr/lib/jvm/java-${JAVA_VERSION}-openjdk-amd64/bin/javac
fi
