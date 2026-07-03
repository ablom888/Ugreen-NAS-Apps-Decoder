#!/bin/bash
script_directory=$(dirname "$(realpath "$BASH_SOURCE")")
LOG_LEVEL=INFO LOG_OUTPUT=FILE USE_SYSLOG=on $script_directory/sbin/kvm_tool app install
