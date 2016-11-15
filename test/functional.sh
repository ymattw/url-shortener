#!/bin/bash

readonly SELF_DIR=$(cd $(dirname $0) && pwd)
readonly SERVER_PORT=${SERVER_PORT:-9988}
readonly SERVER_URL="http://localhost:${SERVER_PORT}"

# Test functions, name must starts with 'test_'
#
function test_shorten_invalid_version
{
    check_shorten "/v2/shorten" "http://example.com" 501 "null"
}

function test_shorten_invalid_url
{
    check_shorten "/v1/shorten" "xxx://example.com" 400 "null"
}

function test_shorten_normal
{
    check_shorten "/v1/shorten" "http://example.com" 200 \
        '{"short":"http://localhost/*[0-9A-Za-z]*"}'
}

function test_original_invalid_version
{
    check_original "/v2/original" "http://localhost/0" 501 "null"
}

function test_original_invalid_short_url
{
    check_original "/v1/original" "http://fake-host/0" 400 "null"
    check_original "/v1/original" "http://localhost:invalid-port/0" 400 "null"
}

function test_original_non_existing_slug
{
    check_original "/v1/original" "http://localhost/abcd1234" 404 "null"
}

function test_original_normal
{
    check_original "/v1/original" "http://localhost/0" 200 \
        '{"url":"http://example.com"}'
}

# Helper functions
#
function check_shorten
{
    local uri=${1:?}
    local long_url="${2:?}"
    local expected_status=${3:?}
    local expected_body=${4:?}

    _check_call "$uri" POST "{\"url\":\"${long_url}\"}" \
        $expected_status "$expected_body"
}

function check_original
{
    local uri=${1:?}
    local short_url="${2:?}"
    local expected_status=${3:?}
    local expected_body=${4:?}

    _check_call "$uri" GET "{\"short\":\"${short_url}\"}" \
        $expected_status "$expected_body"
}

function _check_call
{
    local uri=${1:?}
    local verb=${2:?}
    local data="${3:?}"
    local expected_status=${4:?}
    local expected_body=${5:?}
    local rc=0
    local out=""
    local status
    local body

    out=$(set -x; curl -is -X $verb -H 'Content-Type: application/json' \
        -d "$data" "${SERVER_URL}${uri}")
    rc=$?

    # Output before returning non-zero (error)
    trap 'echo "$out"' RETURN

    (( rc == 0 )) || return 1
    [[ $out =~ ^HTTP/1\.[0-1]\ $expected_status ]] || return 1
    [[ $out == *Content-Type:\ application/json* ]] || return 1
    [[ $out == *${expected_body}* ]] || return 1

    # Clean up on-return handler (and return 0)
    trap '' RETURN
}

function all_tests
{
    declare -f | grep -Eo '^test_[a-z_]+'
}

function run_test
{
    local t=${1:?}
    local out

    printf "%-48s " "* Running $t"
    out=$(eval $t 2>&1)
    if (( $? != 0 )); then
        echo -e "\x1b[31mFAIL\x1b[0m"
        [[ -z $out ]] || echo "$out" | sed 's/^/  | /'
        return 1
    else
        echo -e "\x1b[32mPASS\x1b[0m"
        return 0
    fi
}

function main
{
    local -i total=0
    local -i failed=0
    local -a tests=()
    local t

    if (( $# == 0 )); then
        tests=( $(all_tests) )
    else
        tests=( "$@" )
    fi

    for t in ${tests[@]}; do
        (( total += 1 ))
        run_test $t || {
            (( failed += 1 ))
        }
    done

    echo "Executed $total tests, $failed failed"
    (( failed == 0 ))  # Test result is return code
}

main "$@"
