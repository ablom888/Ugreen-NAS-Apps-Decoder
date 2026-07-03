#!/bin/bash
script_directory=$(dirname "$(realpath "$BASH_SOURCE")")
$script_directory/sbin/dlna_tool app install
