#
#  Dockerfile for a GPDB SNE Sandbox Base Image
#

FROM centos:6.7
MAINTAINER dbaskette@pivotal.io michael@vindahlbang.dk

RUN yum install -q -y unzip which tar more util-linux-ng passwd openssh-clients openssh-server ed m4; yum clean all

COPY * /tmp/

RUN echo root:pivotal | chpasswd \
        && GPFILE="greenplum-db-4.3.9.1-build-1-rhel5-x86_64" \
        && unzip /tmp/$GPFILE.zip -d /tmp/ \
        && rm /tmp/$GPFILE.zip \
        && sed -i s/"more << EOF"/"cat << EOF"/g /tmp/$GPFILE.bin \
        && echo -e "yes\n\nyes\nyes\n" | /tmp/$GPFILE.bin \
        && rm /tmp/$GPFILE.bin \
        && cat /tmp/sysctl.conf.add >> /etc/sysctl.conf \
        && cat /tmp/limits.conf.add >> /etc/security/limits.conf \
        && rm -f /tmp/*.add \
        && echo "localhost" > /tmp/gpdb-hosts \
        && hostname > ~/orig_hostname \
        && mv /tmp/run.sh /usr/local/bin/run.sh \
        && chmod +x /usr/local/bin/run.sh \
        && /usr/sbin/groupadd gpadmin \
        && /usr/sbin/useradd gpadmin -g gpadmin -G wheel \
        && echo "pivotal"|passwd --stdin gpadmin \
        && echo "gpadmin        ALL=(ALL)       NOPASSWD: ALL" >> /etc/sudoers \
        && mv /tmp/bash_profile /home/gpadmin/.bash_profile \
        && chown -R gpadmin: /home/gpadmin \
        && mkdir -p /gpdata/master /gpdata/segments \
        && chown -R gpadmin: /gpdata \
        && chown -R gpadmin: /usr/local/green* \
        && echo "Waiting 30 seconds for Greenplum to finish initialization..."; sleep 30

EXPOSE 5432 22

VOLUME /gpdata
# Set the default command to run when starting the container


CMD echo "127.0.0.1 $(cat ~/orig_hostname)" >> /etc/hosts \
    && service sshd start \
    && echo "export MASTER_DATA_DIRECTORY=/gpdata/master/gpseg-1; source /usr/local/greenplum-db/greenplum_path.sh" >> /home/gpadmin/.bashrc \
    && su gpadmin -l -c "source /usr/local/greenplum-db/greenplum_path.sh;gpssh-exkeys -f /tmp/gpdb-hosts" \
    && su gpadmin -l -c "python /tmp/make_gpinitsystem_initfile.py $NUMSEGMENTS > /tmp/gpinitsystem_singlenode" \
    && chmod 777 /tmp/gpinitsystem_singlenode \
    && su gpadmin -l -c "source /usr/local/greenplum-db/greenplum_path.sh;gpinitsystem -a -c  /tmp/gpinitsystem_singlenode -h /tmp/gpdb-hosts; exit 0 " \
    && su gpadmin -l -c "export MASTER_DATA_DIRECTORY=/gpdata/master/gpseg-1;source /usr/local/greenplum-db/greenplum_path.sh;psql -d template1 -c \"alter user gpadmin password 'pivotal'\"; createdb gpadmin;  exit 0" \
    && su gpadmin -l -c "/usr/local/bin/run.sh" \
    && /bin/bash
