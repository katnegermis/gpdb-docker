#
#  Dockerfile for a GPDB SNE Sandbox Base Image
#

FROM centos:6.7
MAINTAINER dbaskette@pivotal.io michael@vindahlbang.dk

RUN yum install -q -y unzip which tar more util-linux-ng passwd openssh-clients openssh-server ed m4; yum clean all

COPY docker-entrypoint-initdb.d/ /docker-entrypoint-initdb.d/
COPY docker-entrypoint.sh /
COPY gpadmin-entrypoint.sh /
COPY configs/* /tmp/
COPY greenplum-db-4.3.10.0-build-1-rhel5-x86_64.zip /tmp/

RUN echo root:pivotal | chpasswd \
        && GPFILE="greenplum-db-4.3.10.0-build-1-rhel5-x86_64" \
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
        && echo "Waiting 5 seconds for Greenplum to finish initialization..."; sleep 5


VOLUME /gpdata

ENTRYPOINT ["/docker-entrypoint.sh"]

EXPOSE 5432 22
CMD ["greenplum"]
