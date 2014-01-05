#!/bin/bash

# chkconfig: 345 90 90
# description: Keywork Caching service

### BEGIN INIT INFO
# Provides:       keywork-server
# Required-Start: $remote_fs $network
# Required-Stop:  $remote_fs $network
# Default-Start:  2 3 4 5
# Default-Stop:   0 1 6
# Description:    Keywork Caching service
### END INIT INFO

/etc/init.d/keywork-service cache $1

exit $?
