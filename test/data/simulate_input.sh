#!/bin/bash
cd "$(dirname "$0")"
set -Eeuo pipefail

# might need to move mason_genome binary
SEED=42 # was 20181406 before, but was hardcoded to 42 in seqan
BIN_NUMBER=8
HAPLOTYPE_COUNT=2

execs=(dream-stellar generate_local_matches generate_reads split_sequence mason_genome mason_variator)
for exec in "${execs[@]}"; do
    if ! which ${exec} &>/dev/null; then
        echo "${exec} is not available"
        echo ""
        echo "make sure \"${execs[@]}\" are reachable via the \${PATH} variable"
        echo ""

        # trying to do some guessing here:
        paths=(../../build/bin)
        paths+=(../../../raptor_data_simulation/build/bin)
        paths+=(../../../raptor_data_simulation/build/src/mason2/src/mason2-build/bin)
        paths+=(../../../stellar3/build/bin)

        p=""
        for pp in ${paths[@]}; do
            p=${p}$(realpath -m $pp):
        done
        echo "you could try "
        echo "export PATH=${p}\${PATH}"

        exit 127
    fi
done

echo "### dream-stellar metadata input ###"
./split/api_test_input.sh $SEED
./split/cli_test_input.sh $SEED

echo "### dream-stellar build input ###"
./prepare/api_test_input.sh
./build/cli_test_input.sh $SEED $BIN_NUMBER $HAPLOTYPE_COUNT

echo "### dream-stellar search input ###"
./search/cli_test_input.sh $SEED $BIN_NUMBER $HAPLOTYPE_COUNT

echo "### distributed search input ###"
./dream/cli_test_input.sh $SEED

echo "### consolidation lib input ###"
./consolidate/api_test_input.sh $SEED
