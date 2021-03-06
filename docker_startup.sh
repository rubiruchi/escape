#!/usr/bin/env bash
# Copyright 2018 Janos Czentye
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at:
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

RESTART_VALUE=42
UPDATE_VALUE=142
STOP_VALUE=242

trap term_handler INT TERM STOP

SLICER_PORT=8888
ESCAPE_API_PORT=9999
#USE_SLICER="False"
SLICE_CFG_FOLDER="../slices/"

ESCAPE_PID=""
SLICER_PID=""

function term_handler() {
    echo "Terminating ESCAPE process: $ESCAPE_PID"
    kill -SIGTERM ${ESCAPE_PID}
    if [ -n ${SLICER_PID} ]; then
        echo "Terminating SLICER process: $SLICER_PID"
        kill -SIGINT ${SLICER_PID}
    fi
}

function update() {
    echo "Updating ESCAPE source base..."
    git fetch --recurse-submodules --tags
    git checkout "${1-master}"
    git submodule update
}

echo -e "152.66.246.230\t5gexgit.tmit.bme.hu" >> /etc/hosts

while true
do
    echo "Received params: $@"
    echo "Starting ESCAPE..."
    python escape.py ${@} &
    ESCAPE_PID=${!}
    echo "ESCAPE PID: $ESCAPE_PID"
    if [ ${USE_SLICER:-False} != "False" ]; then
        echo "Starting Slicer..."
        python ./slicer_bin/slicer.pyc --port ${SLICER_PORT} --host 0.0.0.0 \
            --mdo "http://127.0.0.1:$ESCAPE_API_PORT/escape/orchestration/" \
            -ds v0 &
        SLICER_PID=${!}
        echo "SLICER PID: $SLICER_PID"
    fi
    wait ${ESCAPE_PID}
    ret_value=${?}
    echo "Received exit code from ESCAPE: $ret_value"
    if [ ${ret_value} -eq ${RESTART_VALUE} ]; then
        echo "Restarting..."
    elif [ ${ret_value} -eq ${UPDATE_VALUE} ]; then
    if [ -f ./.checkout ]; then
            update $(cat ./.checkout)
            rm ./.checkout
        else
            update
        fi
    elif [ ${ret_value} -eq ${STOP_VALUE} ]; then
        python start_waiter.py ${@}
        if [ ${?} -ne 0 ]; then
            exit -1
        fi
    else
        echo "Exit."
        exit 0
    fi
    echo "Restarting ESCAPE..."
    sleep 2
done
