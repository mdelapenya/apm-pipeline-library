#!/usr/bin/env bash
# license agreements. See the NOTICE file distributed with
# this work for additional information regarding copyright
# ownership. Elasticsearch B.V. licenses this file to you under
# the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http:#www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.
set -eo pipefail

# Once the npm run bundlesize goal has been run this particular
# script will create a JSON file with all the details regarding
# the size of the bundles and also the details regardinig the
# target to be compared with.
#

if [ -n "${PIPELINE_LOG_LEVEL}" ] && [ "${PIPELINE_LOG_LEVEL}" == "DEBUG" ] ; then
  set -x
fi

NAME=${1:?'Missing the name of the report'}
REPORT_FOLDER=${2:?'Missing the output folder'}
INPUT=${3:?'Missing the input files to query for'}
COMPARE_TO=${4:-''}

# Function to add the previous size for the given bundlesize id
# if there is something to compare with.
function addPreviousSizeIfPossible() {
    set -x
    label=$1
    size=$2
    new_size=$3
    report=$4
    compare_to=$5

    if [ ! -e "${compare_to}" ] ; then
        return
    fi
    tmp="$(mktemp -d)/compare.json"
    # shellcheck disable=SC2016
    previous_size=$($JQ --arg id "${label}" --arg v "$size" '(.[] | select(.label==$id) | .[$v])' "${compare_to}")
    if [ -n "${previous_size}" ] ; then
        # shellcheck disable=SC2016
        $JQ --arg id "${label}" --arg v "${new_size}" --argjson new "${previous_size}" '(.[] | select(.label==$id) | .[$v]) |= $new' "${report}" > "$tmp"
        mv "$tmp" "${report}"
    fi
    set +x
}

# Install jq if required
JQ=$(command -v jq || true)
if [ -z "${JQ}" ]; then
    echo "1..5 install jq"
    JQ="/tmp/jq"
    OS=$(uname -s)
    if [ "${OS}" == "Linux" ] ; then
        ARCH=$(uname -m)
        suffix=linux64
        if [ "${ARCH}" != "x86_64" ] ; then
            suffix=linux32
        fi
    else
        suffix=osx-amd64
    fi
    wget -q -O "${JQ}" https://github.com/stedolan/jq/releases/download/jq-1.6/jq-${suffix}
    chmod 755 "${JQ}"
else
    echo "1..5 install jq is not required"
fi

# Prepare temporary folder
echo "2..5 prepare a temporary folder"
mkdir -p "${REPORT_FOLDER}"

echo "3..5 query each bundlesize html reported file"
for f in ${INPUT} ; do
	DATA=$(grep "window.chartData =" "${f}" | sed 's#window.chartData =##g' | sed 's#;$##g')
    FILENAME=$(basename "${f}")
    echo "${DATA}" | $JQ 'map(del(.groups))' > "${REPORT_FOLDER}/${FILENAME}.json"
done

echo "4..5 aggregate files"
REPORT=${REPORT_FOLDER}/${NAME}.json
$JQ -s '[.[][]]' "${REPORT_FOLDER}"/*.json > "${REPORT}"

if [ -n "${COMPARE_TO}" ] ; then
    if [ -e "${COMPARE_TO}" ] ; then
        echo "5..5 compare is enabled"
        # For each entry then add the previous sizes
        for label in $($JQ -r 'map(.label) | .[]' "${COMPARE_TO}"); do
            addPreviousSizeIfPossible "${label}" "parsedSize" "previousParsedSize" "${REPORT}" "${COMPARE_TO}"
            addPreviousSizeIfPossible "${label}" "gzipSize" "previousGzipSize" "${REPORT}" "${COMPARE_TO}"
            addPreviousSizeIfPossible "${label}" "statSize" "previousStatSize" "${REPORT}" "${COMPARE_TO}"
        done
    else
        echo "5..5 compare is disabled since the provided file does not exist."
    fi
else
    echo "5..5 compare is disabled since no file to compare with has been provided"
fi

echo "Report has been generated. See ${REPORT}"
