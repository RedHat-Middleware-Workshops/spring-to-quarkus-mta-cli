# Dockerfile used to create the MTA CLI used in this exercise
# https://quay.io/repository/rhappsvcs/spring-to-quarkus-mta-cli?tab=tags
#
# docker buildx build -t quay.io/rhappsvcs/spring-to-quarkus-mta-cli:6.1.0.Final -t quay.io/rhappsvcs/spring-to-quarkus-mta-cli:latest --platform linux/amd64,linux/arm64 --push .
FROM registry.access.redhat.com/ubi9-minimal:9.1.0 AS builder

ENV WINDUP_BASE_DIR="/opt/windup"
ENV WINDUP_VERSION="6.1.0.Final"
ENV WINDUP_NAME="tackle-cli"
ENV WINDUP_NAME_VERSION="${WINDUP_NAME}-${WINDUP_VERSION}"

RUN microdnf install -y unzip

RUN mkdir -p ${WINDUP_BASE_DIR} && \
    cd ${WINDUP_BASE_DIR} && \
    curl -L -O https://repo1.maven.org/maven2/org/jboss/windup/${WINDUP_NAME}/${WINDUP_VERSION}/${WINDUP_NAME_VERSION}-offline.zip && \
    unzip ${WINDUP_NAME_VERSION}-offline.zip && \
    rm ${WINDUP_NAME_VERSION}-offline.zip

FROM registry.access.redhat.com/ubi9/openjdk-11-runtime:1.13

ENV WINDUP_BASE_DIR="/opt/windup"
ENV WINDUP_VERSION="6.1.0.Final"
ENV ARTIFACT_NAME="tackle-cli"
ENV WINDUP_NAME="windup-cli"
ENV PROJECT_DIR="/opt/project"
ENV OUTPUT_DIR="windup-report"
ENV WINDUP_HOME="${WINDUP_BASE_DIR}/${ARTIFACT_NAME}-${WINDUP_VERSION}"
ENV PACKAGE_NAME="com.acme"

VOLUME [${PROJECT_DIR}]

USER root

COPY --from=builder ${WINDUP_BASE_DIR} ${WINDUP_BASE_DIR}

RUN chown -R default:0 /opt && \
    chmod -R a+rwx /opt

USER default

RUN mkdir -p $HOME/.mta/ignore && \
    echo "target" >> $HOME/.mta/ignore/project.mta-ignore.txt

WORKDIR ${PROJECT_DIR}

CMD ${WINDUP_HOME}/bin/${WINDUP_NAME} --sourceMode --input . --output ${OUTPUT_DIR} --target quarkus --packages ${PACKAGE_NAME} --overwrite --explodedApp

