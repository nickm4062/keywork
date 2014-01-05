#!/bin/bash

# chkconfig: 345 90 90
# description: Keywork monitoring framework service

### BEGIN INIT INFO
# Provides:       keywork-service
# Required-Start: $remote_fs $network
# Required-Stop:  $remote_fs $network
# Default-Start:  2 3 4 5
# Default-Stop:   0 1 6
# Description:    Keywork monitoring framework service script
### END INIT INFO

prog=keywork-$1

EMBEDDED_RUBY=false
CONFIG_FILE=/etc/keywork/config.json
CONFIG_DIR=/etc/keywork/conf.d
EXTENSION_DIR=/etc/keywork/extensions
PLUGINS_DIR=/etc/keywork/plugins
HANDLERS_DIR=/etc/keywork/handlers
LOG_DIR=/var/log/keywork
LOG_LEVEL=info
PID_DIR=/var/run/keywork
USER=keywork
SERVICE_MAX_WAIT=10

if [ -f /etc/default/keywork ]; then
    . /etc/default/keywork
fi

system=unknown
if [ -f /etc/redhat-release ]; then
    system=redhat
elif [ -f /etc/system-release ]; then
    system=redhat
elif [ -f /etc/debian_version ]; then
    system=debian
elif [ -f /etc/SuSE-release ]; then
    system=suse
elif [ -f /etc/gentoo-release ]; then
    system=gentoo
elif [ -f /etc/arch-release ]; then
    system=arch
elif [ -f /etc/slackware-version ]; then
    system=slackware
elif [ -f /etc/lfs-release ]; then
    system=lfs
fi

##
## Set platform specific bits here.
## The original platform for this script was redhat so the scripts are partial
## to redhat style. Eventually we may want to be more LSB compliant
## such as what Debian platforms already implement instead.
##
## Each platform must implement at least the following functions:
##
##     start_daemon $user $pidfile $executable "arguments"
##     killproc -p $pid $prog
##     log_daemon_msg $@
##     log_action_msg $@
##     log_success_msg $@
##     log_failure_msg $@
##     echo_ok
##     echo_fail
##
if [ "$system" = "redhat" ]; then
    ## source platform specific external scripts
    . /etc/init.d/functions
    [ -r /etc/sysconfig/$prog ] && . /etc/sysconfig/$prog

    ## set or override platform specific variables
    lockfile=${LOCKFILE-/var/lock/subsys/$prog}

    ## set or override platform specific functions
    start_daemon() {
        daemon --user $1 --pidfile $2 "$3 $4"
    }
    log_daemon_msg() {
        echo -n $"$1"
    }
    echo_ok() {
        echo_success; echo
    }
    echo_fail() {
        echo_failure; echo
    }
    log_success_msg() {
        success $"$@"
    }
    log_failure_msg() {
        failure $"$@"
        echo $"$@"
    }
    log_action_msg() {
        echo $@
    }
fi

if [ "$system" = "debian" ]; then
    ## source platform specific external scripts
    . /lib/lsb/init-functions
    [ -r /etc/default/$prog ] && . /etc/default/$prog

    ## set or override platform specific variables
    lockfile=${LOCKFILE-/var/lock/$prog}

    ## set or override platform specific functions
    start_daemon() {
        start-stop-daemon --start --chuid $1 --pidfile $2 --exec $3 -- $4
    }
    echo_ok() {
        log_end_msg 0
    }
    echo_fail() {
        log_end_msg 1
    }
fi

if [ "$system" = "suse" ]; then
    ## source platform specific external scripts
    . /lib/lsb/init-functions
    [ -r /etc/default/$prog ] && . /etc/default/$prog

    ## set or override platform specific variables
    lockfile=${LOCKFILE-/var/lock/subsys/$prog}

    ## set or override platform specific functions
    start_daemon() {
        startproc -s -u $1 -p $2 $3 $4
    }
    echo_ok() {
        log_success_msg
    }
    echo_fail() {
        log_failure_msg
    }
    log_daemon_msg() {
        echo -n $"$1"
    }
    log_action_msg() {
        echo $@
    }
fi
# TODO: support other platforms in the future: gentoo, arch, slackware, etc

cd /opt/keywork

exec=/opt/keywork/bin/$prog

pidfile=$PID_DIR/$prog.pid
logfile=$LOG_DIR/$prog.log

options="-b -c $CONFIG_FILE -d $CONFIG_DIR -e $EXTENSION_DIR -p $pidfile -l $logfile -L $LOG_LEVEL $OPTIONS"

ensure_dir() {
    if [ ! -d $1 ]; then
        mkdir -p $1
        chown -R $2 $1
        chmod 755 $1
    fi
}

set_keywork_paths() {
    if [ "x$EMBEDDED_RUBY" = "xtrue" ]; then
        export PATH=/opt/keywork/embedded/bin:$PATH:$PLUGINS_DIR:$HANDLERS_DIR
        export GEM_PATH=/opt/keywork/embedded/lib/ruby/gems/2.0.0:$GEM_PATH
    else
        export PATH=$PATH:$PLUGINS_DIR:$HANDLERS_DIR
    fi
}

start() {
    log_daemon_msg "Starting $prog"

    [ -x $exec ] || exit 5

    status &> /dev/null

    if [ $? -eq 0 ]; then
        log_action_msg "$prog is already running."
        echo_ok
        exit 0
    fi

    set_keywork_paths
    ensure_dir $PID_DIR $USER
    ensure_dir $LOG_DIR $USER

    start_daemon $USER $pidfile $exec "$options"

    retval=$?
    sleep 1

    # make sure it's still running. some errors occur only after startup
    status &> /dev/null
    if [ $? -ne 0 ]; then
        echo_fail
        exit 1
    fi

    if [ $retval -eq 0 ]; then
        touch $lockfile
    fi
    echo_ok

    return $retval
}

stop() {
    log_daemon_msg "Stopping $prog"

    if [ -f $pidfile ]; then
        killproc -p $pidfile $prog
        retval=$?
        if [ $retval -eq 0 ]; then
            rm -f $pidfile
            rm -f $lockfile
            echo_ok
        else
            echo_fail
        fi
        return $retval
    else
        pid=$(pgrep -P1 -fl $exec | grep -v grep | grep -v bash | cut -f1 -d" ")
        if [ ! "$pid" == "" ]; then
            kill $pid
            retval=$?
            if [ $retval -eq 0 ]; then
                rm -f $pidfile
                rm -f $lockfile
                echo_ok
            fi
        else
            echo_fail
        fi
    fi
}

status() {
    local pid

    # First try "ps"
    pid=$(pgrep -P1 -fl $exec | grep -v grep | grep -v bash | cut -f1 -d" ")
    if [ -n "$pid" ]; then
        log_action_msg $"${prog} (pid $pid) is running..."
        return 0
    fi

    # Next try "/var/run/*.pid" files
    if [ -f "$pidfile" ] ; then
        read pid < "$pidfile"
        if [ -n "$pid" ]; then
            log_action_msg $"${prog} dead but pid file exists"
            return 1
        fi
    fi

    # See if $lockfile
    if [ -f "$lockfile" ]; then
        log_action_msg $"${prog} dead but subsys locked"
        return 2
    fi

    log_action_msg $"${prog} is stopped"
    return 3
}

# sometimes keywork components need a moment to shutdown, so
# let's implement a waiting approach to restarts with a timeout
restart() {
    count=0; success=0

    stop

    while [ $count -lt $SERVICE_MAX_WAIT ]; do
        count=$((count + 1))
        status &> /dev/null
        if [ $? -eq 0 ]; then
            # still running
            sleep 1
        else
            success=1
            break
        fi
    done

    if [ $success = 1 ]; then
        start
    else
        log_failure_msg "Timed out waiting for $prog to stop"
        return 1
    fi
}

case "$2" in
    start)
        start
        ;;
    stop)
        stop
        ;;
    status)
        status
        ;;
    restart)
        restart
        ;;
    *)
        echo "Usage: $0 {client|cache|api|dashboard} {start|stop|status|restart}"
        exit 2
esac

exit $?
