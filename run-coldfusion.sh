#!/bin/bash
set -e

CLASSPATH=$CF_DIR/runtime/bin/tomcat-juli.jar:$CF_DIR/bin/cf-bootstrap.jar:$CF_DIR/bin/cf-startup.jar:$CF_DIR/runtime/lib/'*'
JVMCONFIG=$CF_DIR/bin/jvm.config

sed -i \
    -e "/^java.args=/s:-Xms[[:digit:]]\\+[kmg]:-Xms$COLDFUSION_MIN_MEM:" \
    -e "/^java.args=/s:-Xmx[[:digit:]]\\+[kmg]:-Xmx$COLDFUSION_MAX_MEM:" \
    -e "/^java.args=/s~$~ $COLDFUSION_ADDITIONAL_JVM_ARGS~" $JVMCONFIG

. $CF_DIR/bin/parseargs $JVMCONFIG
CLASSPATH=$CLASSPATH:$JAVA_CLASSPATH
JAVA_LIBRARY_PATH=$JAVA_LIBRARYPATH
LD_LIBRARY_PATH="$CF_DIR/lib:$CF_DIR/lib/_linux64:$JAVA_LIBRARY_PATH"

if [ "$JAVA_HOME" = "" ]; then
    JAVA_EXECUTABLE="java"
else
    JAVA_EXECUTABLE="$JAVA_HOME/bin/java"
fi

for word in $JVM_ARGS
do
    if [ "$word" != "-Xdebug" ]; then
        if [ ${word:0:9} != "-Xrunjdwp" ]; then
            JVM_ARGS_NODEBUG="$JVM_ARGS_NODEBUG $word"
        fi
    fi
done

export LD_LIBRARY_PATH

cd $CF_DIR/bin
exec $JAVA_EXECUTABLE -classpath $CLASSPATH $JVM_ARGS_NODEBUG \
    com.adobe.coldfusion.bootstrap.Bootstrap -start
