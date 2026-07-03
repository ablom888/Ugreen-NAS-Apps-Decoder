#!/bin/bash

script_directory=$(dirname "$(realpath "$BASH_SOURCE")")
sqlite3 $script_directory/db/vm.db "UPDATE virtual_machine SET autoStart=0;"
