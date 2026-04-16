#!/bin/bash
#set -eux
set -eu
set -o pipefail

echo "================================"
echo "================================"
echo "PT DEBUG: In run_compile.sh ..."
echo "================================"
echo "================================"

echo "PID=$$"
SECONDS=0

trap '[ "$?" -eq 0 ] || write_fail_test' EXIT
trap 'echo "run_compile.sh interrupted PID=$$"; cleanup' INT
trap 'echo "run_compile.sh terminated PID=$$";  cleanup' TERM

cleanup() {
  [[ ${ROCOTO} = 'false' ]] && interrupt_job
  trap 0
  exit
}

write_fail_test() {
  echo "${JBNME} failed in run_compile" >> "${PATHRT}/fail_${JBNME}"
  if [[ ${ROCOTO:-false} == true ]] || [[ ${ECFLOW:-false} == true ]]; then
    # if this script has been submitted by a workflow return non-zero exit status
    # so that workflow can resubmit it
    exit 1
  else
    # if this script has been executed interactively, return zero exit status
    # so that rt.sh can continue running, and hope that rt.sh's generate_log
    # will catch failed tests
    exit 0
  fi
}


remove_fail_test() {
    echo "Removing test failure flag file for ${JBNME}"
    rm -f "${PATHRT}/fail_${JBNME}"
}

if [[ $# != 4 ]]; then
  echo "Usage: $0 PATHRT RUNDIR_ROOT MAKE_OPT COMPILE_ID"
  exit 1
fi

export PATHRT=$1
export RUNDIR_ROOT=$2
export MAKE_OPT=$3
export COMPILE_ID=$4

export JBNME="compile_${COMPILE_ID}"

cd "${PATHRT}"
remove_fail_test

echo "PT DEBUG: why does it source it twice here?"
echo "PT DEBUG: what is in ${RUNDIR_ROOT}/${JBNME}.env"
if [[ -e ${RUNDIR_ROOT}/${JBNME}.env ]]; then
  source "${RUNDIR_ROOT}/${JBNME}.env"
  cat "${RUNDIR_ROOT}/${JBNME}.env"
fi

echo "PT DEBUG: sourcing default_vars.sh" 
source default_vars.sh

echo "PT DEBUG: what is in ${RUNDIR_ROOT}/${JBNME}.env"
if [[ -e ${RUNDIR_ROOT}/${JBNME}.env ]]; then
  source "${RUNDIR_ROOT}/${JBNME}.env"
  cat "${RUNDIR_ROOT}/${JBNME}.env"
fi


export RUNDIR=${RUNDIR_ROOT}/${JBNME}
date_s=$( date +%s )
echo -n "${JBNME}, ${date_s}," > "${LOG_DIR}/${JBNME}_timestamp.txt"

export RT_LOG=${LOG_DIR}/${JBNME}.log

source rt_utils.sh

source atparse.bash

rm -rf "${RUNDIR}"
mkdir -p "${RUNDIR}"
cd "${RUNDIR}"

if [[ ${SCHEDULER} = 'pbs' ]]; then
  if [[ -e ${PATHRT}/fv3_conf/compile_qsub.IN_${MACHINE_ID} ]]; then 
    atparse < "${PATHRT}/fv3_conf/compile_qsub.IN_${MACHINE_ID}" > job_card
  else
    echo "Looking for fv3_conf/compile_qsub.IN_${MACHINE_ID} but it is not found. Exiting"
    exit 1
  fi
elif [[ ${SCHEDULER} = 'slurm' ]]; then
  if [[ -e ${PATHRT}/fv3_conf/compile_slurm.IN_${MACHINE_ID} ]]; then
    atparse < "${PATHRT}/fv3_conf/compile_slurm.IN_${MACHINE_ID}" > job_card
  else
    echo "Looking for fv3_conf/compile_slurm.IN_${MACHINE_ID} but it is not found. Exiting"
    exit 1
  fi
elif [[ ${SCHEDULER} = 'cloudflow' ]]; then
  echo "PT DEBUG: SCHEDULER = cloudflow"
  if [[ -e ${PATHRT}/fv3_conf/compile_${SCHEDULER}.IN_${MACHINE_ID} ]]; then
    echo "PT DEBUG: calling atparse < ${PATHRT}/fv3_conf/compile_${SCHEDULER}.IN_${MACHINE_ID}> job_card"
    atparse < "${PATHRT}/fv3_conf/compile_${SCHEDULER}.IN_${MACHINE_ID}" > job_card
  else
    echo "Looking for fv3_conf/compile_${SCHEDULER}.IN_${MACHINE_ID} but it is not found. Exiting"
    exit 1
  fi
fi

################################################################################
# Submit compile job
################################################################################

if [[ ${ROCOTO} = 'false' ]]; then
  echo "PT DEBUG: calling submit_and_wait job_card"
  cat job_card
  submit_and_wait job_card
else
  chmod u+x job_card
  redirect_out_err ./job_card
fi
#ls -l "${PATHTR}/tests/fv3_${COMPILE_ID}.exe"

cp "${RUNDIR}/${JBNME}_time.log" "${LOG_DIR}"
cat "${RUNDIR}/job_timestamp.txt" >> "${LOG_DIR}/${JBNME}_timestamp.txt"

echo "PT DEBUG: calling remove_fail_test()"
remove_fail_test

################################################################################
# End compile job
################################################################################
date_s=$( date +%s )
echo " ${date_s}, 1" >> "${LOG_DIR}/${JBNME}_timestamp.txt"

elapsed=${SECONDS}
echo "run_compile.sh: Compile ${COMPILE_ID} Completed."
echo "run_compile.sh: Compile ${COMPILE_ID} Elapsed time ${elapsed} seconds."
