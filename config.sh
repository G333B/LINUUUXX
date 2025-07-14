#!/bin/bash

#variables
ENV_FILE="ENV/env_cc_linux.img"
MOUNT_POINT="/mnt/cc_env"
MAPPER_NAME="cc_env_map"
DEFAULT_SIZE="5G"
PASSWORD_FILE="MDP/psswd.txt"

USER_EMAIL="test@exmeple.com"
USER_NAME="Test User"

COFFRE_DIR="$MOUNT_POINT/ssh_coffre"
ALIAS_FILE="$COFFRE_DIR/.bash_aliases"
HOME="/home/bjoork"
host_key="id_rsa"
