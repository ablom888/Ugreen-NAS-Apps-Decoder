#!/bin/bash

rootfs=$(dirname $(dirname $(readlink -f "$0")))
dbDir=$rootfs/db

ug-postgres --stop-mode --db-dir=${dbDir}