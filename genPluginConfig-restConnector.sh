#!/bin/bash

# This script demonstrates how to call the Plugin Configuration Generator MBEAN
# on a lberty instance with the restConnector configured.
# Author: ecovener@us.ibm.com

# Liberty setup hints: https://developer.ibm.com/wasdev/docs/accessing-libertys-jmx-rest-apis/


# Edit this section as desired
###########################################################################
# WebServer details
DEFAULT_PLUGIN_ROOT=/opt/IBM/HTTPServer_Plugins
DEFAULT_WEBSERVER_NAME=webserver1

# When configuring the restConnector, you have to specify at least a 
# quick-start security user and password. These will be visible in the
# process table.
JMX_USER=theUser
JMX_PASS=thePassword


WGET="wget --no-check-certificate"
###########################################################################

PLUGIN_ROOT=${2:-$DEFAULT_PLUGIN_ROOT}
WEBSERVER_NAME=${3:-$DEFAULT_WEBSERVER_NAME}

# Edit below at your own risk.

if [ $# -lt 1 ]; then
  echo "$0 https-URL [ plugin-root [ webserver-name ] ]"
  echo ""
  echo -e "Examples:"
  echo -e "\t $0 https://localhost:9443"
  echo -e "\t $0 https://localhost:9443 /opt/Plugins webserver1"
  exit 1
fi


# Remove the https:// prefix to allow host:port input to work too 
URL=$1
URL=$(echo $URL | sed -e 's/^https:\/\///')
URL="https://${URL}"
# Remove trailing slash
URL=$(echo $URL | sed -e 's/\/$//')

$WGET -q --http-user=$JMX_USER --http-password=$JMX_PASS $URL/IBMJMXConnectorREST/mbeans/ -O/dev/null
if [ $? -ne 0 ]; then
  echo "URL or user/password parameter looks wrong, $URL/IBMJMXConnectorREST/mbeans/ returned an error"
  exit 2
fi

TEMPFILE=`mktemp`
cat <<==end > $TEMPFILE
{ 
   "params": [ 
             { "value": "$PLUGIN_ROOT"       , "type": "java.lang.String"},  
             { "value": "$WEBSERVER_NAME"    , "type": "java.lang.String"} 
           ], 
   "signature": ["java.lang.String", "java.lang.String"]
}
==end


$WGET -q --body-file $TEMPFILE --header="Content-Type: application/json" --method=POST  \
     --no-check-certificate --http-user=$JMX_USER --http-password=$JMX_PASS         \
     "$URL/IBMJMXConnectorREST/mbeans/WebSphere%3Aname%3Dcom.ibm.ws.jmx.mbeans.generatePluginConfig/operations/generatePluginConfig" -O/dev/null

if [ $? -eq 0 ]; then
  echo "Success, plugin-cfg.xml should have been generated on the Liberty server"
fi


unlink $TEMPFILE



