#!/bin/bash

make clean
make all -j ${OMP_NUM_THREADS:-$(nproc)}
exit
