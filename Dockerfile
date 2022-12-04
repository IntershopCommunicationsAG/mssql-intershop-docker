#
# Copyright 2021 Intershop Communications AG.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
ARG UBUNTUVERSION=20.04
FROM ubuntu:$UBUNTUVERSION

ARG MSSQLVERSION=2022
ARG UBUNTUVERSION=20.04

LABEL maintainer="a-team@intershop.de"
LABEL mssqlversion="$MSSQLVERSION"

RUN export DEBIAN_FRONTEND=noninteractive && \
    apt-get update && \
    apt-get install -yq curl apt-transport-https unzip gnupg2 && \
    # Get official Microsoft repository configuration
    curl https://packages.microsoft.com/keys/microsoft.asc | apt-key add - && \
    curl https://packages.microsoft.com/config/ubuntu/$UBUNTUVERSION/mssql-server-$MSSQLVERSION.list | tee /etc/apt/sources.list.d/mssql-server.list && \
    curl https://packages.microsoft.com/config/ubuntu/$UBUNTUVERSION/prod.list > /etc/apt/sources.list.d/mssql-release.list && \
    apt-get update && \
    # Install SQL Server from apt
    apt-get install -y mssql-server && \
    # Install optional packages
    apt-get install -y mssql-server-fts && \
    ACCEPT_EULA=Y apt-get install -y mssql-tools locales && \
    curl -ksSL -o /tmp/wait-for-port.zip https://github.com/bitnami/wait-for-port/releases/download/v1.0/wait-for-port.zip && \
    unzip /tmp/wait-for-port.zip -d /usr/local/bin/ && rm -f /tmp/wait-for-port.zip &&  chmod a+x /usr/local/bin/wait-for-port && \
    echo 'export PATH="$PATH:/opt/mssql-tools/bin"' >> ~/.bashrc && /bin/bash -c "source ~/.bashrc" && \
    locale-gen en_US.UTF-8 && update-locale LANG=en_US.UTF-8 && \
    # remove curl and others
    apt-get purge -y curl apt-transport-https unzip && \
    # Cleanup the Dockerfile
    apt-get clean && rm -rf /var/lib/apt/lists && \
    # Create app directory
    mkdir -p /usr/src/icmdb && mkdir -p /var/opt/mssql/backup

EXPOSE 1433/tcp
EXPOSE 1434/tcp

VOLUME [ "/var/opt/mssql/data", \
         "/var/opt/mssql/backup" ]

COPY scripts/ /usr/src/icmdb

ENV ICM_DB_NAME=icmdb ICM_DB_USER=intershop ICM_DB_PASSWORD=intershop

# Grant permissions for the import-data script to be executable
RUN chmod +x /usr/src/icmdb/*.sh

WORKDIR /usr/src/icmdb

CMD ./entrypoint.sh
