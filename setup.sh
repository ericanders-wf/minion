#!/bin/bash

#
# make.sh <clone|setup|run-frontend|run-backend|run-scan-worker|run-state-worker|run-plugin-worker|run-scanscheduler>
#
# This script is really just for development only. It makes it easier to
# checkout the depend projects and to set them up in a virtualenv.
#
PROJECTS="backend frontend"

if [ "$(id -u)" == "0" ]; then
    echo "abort: cannot run as root."
    exit 1
fi

if [ ! `which virtualenv` ]; then
    echo "abort: no virtualenv found"
    exit 1
fi

if [ ! `which python2.7` ]; then
    echo "abort: no python2.7 found"
    exit 1
fi

if [ ! -z "$VIRTUAL_ENV" ]; then
    echo "abort: cannot run from an existing virtual environment"
    exit 1
fi

# Default optional argument values
ADDRESS="0.0.0.0"
ROOT="."

# shift all option arugments to the front so getopts can parse the options
COMMAND=$1
shift

while getopts ":a:p:x:" opt; do
    case "$opt" in
        a) ADDRESS=${OPTARG};;
        p) PORT=${OPTARG};;
        x) ROOT=${OPTARG%/};;
        \?)
            echo "Invalid option: -$OPTARG" >&2
            exit 1
            ;;
        :)
            echo "Option -$OPTARG requires an argument." >&2
            exit 1
            ;;
    esac
done

case $COMMAND in
    clone)
        for project in $PROJECTS; do
            if [ ! -d "minion-$project" ]; then
                git clone --recursive "https://github.com/ericanders-wf/minion-$project" "$ROOT/minion-$project" || exit 1
            fi
        done
        ;;
    develop)
        # Create our virtualenv
        if [ ! -d "env" ]; then
                virtualenv -p python2.7 --no-site-packages "$ROOT/env" || exit 1
        fi
        # Activate our virtualenv
        source "$ROOT/env/bin/activate"
        for project in $PROJECTS; do
            if [ -x "$ROOT/minion-$project/setup.sh" ]; then
				(cd "$ROOT/minion-$project"; "./setup.sh" develop) || exit 1
            fi
        done
        ;;
    install)
        for project in $PROJECTS; do
            (cd "$ROOT/minion-$project"; "sudo" "python" "setup.py" "install") || exit 1
        done
        ;;
    run-backend)
        source "$ROOT/env/bin/activate"
        if [ -z "$PORT" ]; then
            PORT="8383"
        fi
        minion-backend/scripts/minion-backend-api "-a" $ADDRESS "-p" $PORT -r -d
        ;;
    run-frontend)
        source "$ROOT/env/bin/activate"
        if [ -z "$PORT" ]; then
            PORT="8080"
        fi
        minion-frontend/scripts/minion-frontend "-a" $ADDRESS "-p" $PORT -r -d
        ;;
    run-scan-worker)
        source "$ROOT/env/bin/activate"
        $ROOT/minion-backend/scripts/minion-scan-worker
        ;;
    run-state-worker)
        source "$ROOT/env/bin/activate"
        $ROOT/minion-backend/scripts/minion-state-worker
        ;;
    run-plugin-worker)
        source "$ROOT/env/bin/activate"
        $ROOT/minion-backend/scripts/minion-plugin-worker
        ;;
    run-scheduler)
        source "$ROOT/env/bin/activate"
        $ROOT/minion-backend/scripts/minion-scanscheduler
        ;;
    run-scheduler-worker)
        source "$ROOT/env/bin/activate"
        $ROOT/minion-backend/scripts/minion-scanschedule-worker
        ;;
    *)
        echo "Usage : $0 <clone|install|develop|run-backend|run-frontend|run-plugin-worker|run-scan-worker|run-state-worker|run-scheduler|run-scheduler-worker>"
        ;;
esac
