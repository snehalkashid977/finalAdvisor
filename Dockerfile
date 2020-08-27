# Generated by IBM TransformationAdvisor
# Thu Aug 27 11:04:41 UTC 2020


FROM adoptopenjdk/openjdk8-openj9 AS build-stage

RUN apt-get update && \
    apt-get install -y maven unzip

COPY . /project
WORKDIR /project

#RUN mvn -X initialize process-resources verify => to get dependencies from maven
#RUN mvn clean package	
#RUN mvn --version
RUN mvn --version

RUN mkdir -p /config/apps && \
    mkdir -p /sharedlibs && \
    cp ./src/main/liberty/config/server.xml /config && \
    cp ./target/*.*ar /config/apps/ && \
    if [ ! -z "$(ls ./src/main/liberty/lib)" ]; then \
        cp ./src/main/liberty/lib/* /sharedlibs; \
    fi

FROM ibmcom/websphere-liberty:kernel-java8-ibmjava-ubi

ARG SSL=true
#Monitoring is disabled because it is not compatible with the servlet version the application is using.
#To enable monitoring, you must be using servlet-3.1 and set the monitoring value to true in this file, and also in the values.yaml for the chart.
ARG MP_MONITORING=false
ARG HTTP_ENDPOINT=false

RUN mkdir -p /opt/ibm/wlp/usr/shared/config/lib/global
COPY --chown=1001:0 --from=build-stage /config/ /config/
COPY --chown=1001:0 --from=build-stage /sharedlibs/ /opt/ibm/wlp/usr/shared/config/lib/global

USER root
RUN configure.sh
USER 1001

# Upgrade to production license if URL to JAR provided
ARG LICENSE_JAR_URL
RUN \
   if [ $LICENSE_JAR_URL ]; then \
     wget $LICENSE_JAR_URL -O /tmp/license.jar \
     && java -jar /tmp/license.jar -acceptLicense /opt/ibm \
     && rm /tmp/license.jar; \
   fi
