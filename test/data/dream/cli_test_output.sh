#!/bin/bash
cd dream
set -Eeuo pipefail

if [ -z "${VALIK_TMP}" ]; then
    echo "no VALIK_TMP folder given"
    exit 127
fi

mkdir -p $VALIK_TMP

#----------- Index and search the reference genome -----------

pattern=50            # min local match length

ibf_size="32k"
ref_input="ref.fasta"
query="query.fasta"

max_errors=2
max_err_rate=$(echo $max_errors/$pattern | bc -l)
max_er=$(echo $max_errors/$pattern | bc -l)

echo "Creating IBF for max_er=$max_er and pattern=$pattern"
index=$max_errors"error_"$pattern"pattern_index.ibf"
dream-stellar build "$ref_input" --seg-count 8 --pattern "$pattern" --error-rate "$max_err_rate" --size "$ibf_size" --output "$index" --without-parameter-tuning

for e in 1 2
do
    er=$(echo $e/$pattern | bc -l)  # error rate

    echo "Searching IBF with error rate $er"
    dist_out=$e"error.gff"
    #dream-stellar search --distribute --index "$index" --query "$query" --output "$dist_out" --error-rate "$er" \
    #            --repeatPeriod 1 --repeatLength 10 --numMatches 2
    local_out="${e}error.gff"
    dream-stellar search --index "$index" --query "$query" --output "$local_out" --error-rate "$er" \
                 --repeatPeriod 1 --repeatLength 10 --numMatches 2

    if [ -d "${VALIK_TMP}" ]; then
        rm $VALIK_TMP/*
    fi
    mkdir -p $VALIK_TMP

    stellar_out=$e"error_stellar.gff"
    stellar $ref_input $query -e $er -l $pattern -o $stellar_out --repeatPeriod 1 --repeatLength 10 --numMatches 2 &> /dev/null
    rm stellar.disabled.fasta
done

rm $index
rm -r $VALIK_TMP
rm fn_err_conf*.bin

