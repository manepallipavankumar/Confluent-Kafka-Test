#!/bin/bash
# Generates the configuration based on the ConfigMap properties

[ $# -lt 2 ] \
    && echo "ERROR: Missing parameter. ConfigMap mount path and configuration file path are required." \
    && exit 1

# create the testing cert file
unsecureCert=$(mktemp)
cat $KAFKA_CONFIG_DIR/os-certs/* > $unsecureCert

KAFKA_CONFIG_PROPS_PATH=$1
KAFKA_CONFIG_FILE=$2

[ ! -d $KAFKA_CONFIG_PROPS_PATH ] \
    && echo "ERROR: ConfigMap mount path '$KAFKA_CONFIG_PROPS_PATH' does not exist." \
    && exit 10

echo "Generating Kafka configuration in '$KAFKA_CONFIG_FILE'."

add_property() {
    echo "Adding: $1"
    echo "$1" >> $KAFKA_CONFIG_FILE
    return 0
}

# remove configuration file if it exists already
rm -f $KAFKA_CONFIG_FILE

# write ConfigMap properties to the configuration file
for propFile in $(ls -1U $KAFKA_CONFIG_PROPS_PATH/*)
do
    propName=$(basename $propFile)
    propValue=$(cat $propFile)
    
    ( [ "$propName" == "advertised.host.name" ] \
            || [ "$propName" == "advertised.listeners" ] \
            || [ "$propName" == "advertised.port" ] \
            || [ "$propName" == "broker.id" ] \
            || [ "$propName" == "listeners" ] \
            || [ "$propName" == "log.dir" ] \
            || [ "$propName" == "log.dirs" ] \
            || [ "$propName" == "ssl.keystore.location" ] \
            || [ "$propName" == "ssl.keystore.password" ] \
            || [ "$propName" == "ssl.keystore.type" ] \
            || [ "$propName" == "ssl.truststore.location" ] \
            || [ "$propName" == "ssl.truststore.password" ] \
            || [ "$propName" == "ssl.truststore.type" ] \
            || [ "$propName" == "zookeeper.connect" ] ) \
        && echo "Skipping $propName. Not allowed to specify this in the ConfigMap." \
        && continue
    
    add_property "$propName=$propValue"
done

    add_property "advertised.listeners=INTERNAL://$(hostname -f):9092,EXTERNAL://$(cat ${KAFKA_CONFIG_DIR}/route-hostname):443"

# write standard configuration parameters to the configuration file
add_property "log.dirs=/var/lib/kafka/data"
