#!/bin/bash
while true; do
    sudo nvidia-smi --query-gpu=power.draw --format=csv,noheader,nounits >> nvidia-smi-metrics.csv
    sleep 1
done
