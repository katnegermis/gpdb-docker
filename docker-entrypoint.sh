#!/bin/bash

echo "127.0.0.1 $(cat ~/orig_hostname)" >> /etc/hosts \
&& service sshd start \
&& echo "export MASTER_DATA_DIRECTORY=/gpdata/master/gpseg-1; source /usr/local/greenplum-db/greenplum_path.sh" >> /home/gpadmin/.bashrc \
&& su gpadmin -l -c "source /usr/local/greenplum-db/greenplum_path.sh;gpssh-exkeys -f /tmp/gpdb-hosts" \
&& su gpadmin -l -c "python /tmp/make_gpinitsystem_initfile.py $NUMSEGMENTS > /tmp/gpinitsystem_singlenode" \
&& chmod 777 /tmp/gpinitsystem_singlenode \
&& su gpadmin -l -c "source /usr/local/greenplum-db/greenplum_path.sh;gpinitsystem -a -c  /tmp/gpinitsystem_singlenode -h /tmp/gpdb-hosts; exit 0 " \
&& su gpadmin -l -c "export MASTER_DATA_DIRECTORY=/gpdata/master/gpseg-1;source /usr/local/greenplum-db/greenplum_path.sh;psql -d template1 -c \"alter user gpadmin password 'pivotal'\"; createdb gpadmin;  exit 0" \
&& su gpadmin -l -c "/usr/local/bin/run.sh"


for f in /docker-entrypoint-initdb.d/*; do
			case "$f" in
				*_root_*.sh)     echo "$0: running $f"; . "$f" ;;
				*)        echo "$0: ignoring $f" ;;
			esac
			echo
done

su gpadmin -l -c "/gpadmin-entrypoint.sh"
