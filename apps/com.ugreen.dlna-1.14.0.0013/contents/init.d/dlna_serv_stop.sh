#!/bin/bash

/bin/kill -s QUIT $MAINPID
systemctl stop ugminidlna
