import sys

try:
    numsegments = int(sys.argv[1], 10)
except Exception, e:
    raise Exception(str(sys.argv) + " " + str(e))

print """ARRAY_NAME="GPDB SANDBOX"
MACHINE_LIST_FILE=/tmp/gpdb-hosts
SEG_PREFIX=gpseg
PORT_BASE=40000
declare -a DATA_DIRECTORY=({segments})
MASTER_HOSTNAME=localhost
MASTER_DIRECTORY=/gpdata/master
MASTER_PORT=5432
TRUSTED_SHELL=ssh
CHECK_POINT_SEGMENTS=8
ENCODING=UNICODE""".format(segments=' '.join('/gpdata/segments' for _ in xrange(numsegments)))
