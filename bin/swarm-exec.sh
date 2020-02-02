#!/usr/bin/env bash

SWARMEXEC_cmdname=${0##*/}

usage()
{
    cat << USAGE >&2
Usage: $SWARMEXEC_cmdname [OPTIONS] -- IMAGE [COMMAND] [ARG...]

Run ad-hoc task in Docker Swarm

Options:
      --timeout seconds                    Timeout in seconds, zero for no timeout
      --name string                        Service name

Exit codes:
  2   Service has been rejected
  3   Timeout occurred
USAGE
    exit 1
}

function cleanup() {
  rc=$?

  if [[ -n ${log_pid} ]]; then
    (kill $log_pid && wait $log_pid) >/dev/null 2>&1
  else
    # to catch output for really short lived task that take less then second
    docker service logs ${SWARMEXEC_NAME} --raw
  fi
  echo "> Cleaning up ..." 1>&2
  docker service rm ${SWARMEXEC_NAME} >/dev/null 2>&1
  exit $rc
}

trap cleanup INT TERM EXIT

function swarm_exec() {
  if [[ $SWARMEXEC_TIMEOUT -gt 0 ]]; then
    echo "> Waiting $SWARMEXEC_TIMEOUT seconds for running ${SWARMEXEC_NAME} service" 1>&2
  else
    echo "> Waiting for running ${SWARMEXEC_NAME} service without a timeout" 1>&2
  fi

  if [[ "$SWARMEXEC_NAME_R" == "peatio" ]]; then
    docker service create \
      --name ${SWARMEXEC_NAME} \
      --env-file config/${SWARMEXEC_NAME_R}.env \
      --mount type=volume,source=${SWARMEXEC_NAME_R}_seed,target=/home/app/config/seed \
      --network backend-net \
      --detach=true \
      --restart-condition none \
      --stop-grace-period 0s \
      --with-registry-auth \
      ${SWARMEXEC_IMAGE} ${SWARMEXEC_COMMAND} ${SWARMEXEC_COMMAND_ARG} >/dev/null 2>&1
  fi

  if [[ "$SWARMEXEC_NAME_R" != "peatio" ]]; then
    docker service create \
      --name ${SWARMEXEC_NAME} \
      --env-file config/${SWARMEXEC_NAME_R}.env \
      --mount type=volume,source=${SWARMEXEC_NAME_R}_seed,target=/home/app/config/seed \
      --secret source=app_barong.key,target=/run/secrets/barong.key \
      --network backend-net \
      --detach=true \
      --restart-condition none \
      --stop-grace-period 0s \
      --with-registry-auth \
      ${SWARMEXEC_IMAGE} ${SWARMEXEC_COMMAND} ${SWARMEXEC_COMMAND_ARG} >/dev/null 2>&1
  fi

  SWARMEXEC_start_ts=$(date +%s)

  while :; do
    sleep 1

    IFS='|' read -r desiredState currentState error <<< $(docker service ps ${SWARMEXEC_NAME} --format '{{.DesiredState}}|{{.CurrentState}}|{{.Error}}')
    desiredState="${desiredState,,}"  # running -> shutdown
    currentState="${currentState,,}"  # assigned -> preparing -> rejected
                                      #                       -> running -> complete
                                      #                                  -> failed
    currentState="${currentState%% *}"
    error=${error,,}

    # echo "desiredState: $desiredState, currentState: $currentState, error: $error "

    SWARMEXEC_end_ts=$(date +%s)

    case "$desiredState|$currentState" in
      "running|running")
        if [[ -z ${log_pid+x} ]]; then
          docker service logs -f ${SWARMEXEC_NAME} --raw &
          log_pid=$!
          disown
        fi
        ;;
      "shutdown|complete")
        echo "> ${SWARMEXEC_NAME} service is successfully completed after $((SWARMEXEC_end_ts - SWARMEXEC_start_ts)) seconds" 1>&2
        break
        ;;
      "shutdown|failed")
        echo "> Error: service ${SWARMEXEC_NAME} has been failed with error $error" 1>&2
        exit 1
        ;;

      "shutdown|rejected")
        echo "> Error: service ${SWARMEXEC_NAME} has been rejected" 1>&2
        exit 2
        ;;
    esac
    if [[ $SWARMEXEC_TIMEOUT -gt 0 ]]; then
      if [[ $((SWARMEXEC_end_ts - SWARMEXEC_start_ts)) -gt $SWARMEXEC_TIMEOUT ]]; then
        echo "> Error: timeout occurred after waiting $SWARMEXEC_TIMEOUT seconds" 1>&2
        exit 3
      fi
    fi

  done
}

wait_for_wrapper() {
  echo "Running with "
}

while [[ $# -gt 0 ]]; do
  case "$1" in

    # `swarm-exec` options
    --help)
      usage
      ;;
    --timeout)
      SWARMEXEC_TIMEOUT="$2"
      shift 2
      ;;

    # `docker service create` options
    --name)
      SWARMEXEC_NAME="app_$2_db"
      SWARMEXEC_NAME_R="$2"
      shift 2
      ;;
    --entrypoint)
      SWARMEXEC_ENTRYPOINT="$2"
      shift 2
      ;;
    --env)
      SWARMEXEC_ENV="$SWARMEXEC_ENV --env $2"
      shift 2
      ;;
    --)
      shift
      SWARMEXEC_IMAGE="$1"
      shift
      SWARMEXEC_COMMAND="$1"
      shift
      SWARMEXEC_COMMAND_ARG="$@"
      break
      ;;

    *)
      echo "Error: Unknown argument: $1" 1>&2
      usage
      ;;
  esac
done

if [[ "$SWARMEXEC_IMAGE" == "" ]]; then
    echo "Error: you need to provide a docker image to run" 1>&2
    usage
fi

SWARMEXEC_TIMEOUT=${SWARMEXEC_TIMEOUT:-0}

swarm_exec