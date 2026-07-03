#!/bin/bash

# Define rootfs and other variables
rootfs=$(dirname $(dirname $(readlink -f "${BASH_SOURCE[0]}")))
dbDir=$rootfs/db
port=5433
logFile="/var/log/video_serv_init.log"

# Function to log messages with timestamps
logMessage() {
    echo "$(date +'%Y-%m-%d %H:%M:%S.%3N') - $1" >> $logFile
}

# Function to stop PostgreSQL processes
stopPostgresProcesses() {
    logMessage "Stopping PostgreSQL processes..."
    ps -ef | grep postgres | grep videomgr | grep -v grep | awk '{print $2}' | xargs kill -9 > /dev/null 2>&1
    logMessage "PostgreSQL processes stopped."
}

# Function to wait for PostgreSQL processes to stop
waitForPostgresEnd() {
    local retries=5
    local count=0
    while [ $count -lt $retries ]; do
        if ! ps -ef | grep postgres | grep videomgr | grep -v grep > /dev/null; then
            return 0
        else
            sleep 1
            count=$((count + 1))
        fi
    done
    return 1
}

# Function to set PostgreSQL listen address
setDbListenAddr() {
    logMessage "Setting database listen address..."
    configFile="${dbDir}/postgresql.conf"
    if ! grep -q "listen_addresses='127.0.0.1'" "$configFile"; then
        if ! grep -q $port "$configFile"; then
            echo "listen_addresses='127.0.0.1'" >> $configFile
            echo "port=$port" >> $configFile
            logMessage "Added listen_addresses and port to $configFile."
        else
            sed -i "/port=$port/ i\listen_addresses='127.0.0.1'" $configFile
            logMessage "Inserted listen_addresses before port in $configFile."
        fi
    fi
}


# Function to remove postmaster.pid if it exists
removePostmasterPid() {
    psqlMasterPid=${dbDir}/postmaster.pid
    if [ -e "$psqlMasterPid" ] || [ -L "$psqlMasterPid" ] || [ -S "$psqlMasterPid" ]; then
        logMessage "Removing postmaster.pid file..."
        rm -rf "$psqlMasterPid"
        logMessage "postmaster.pid file removed."
    fi
}

# Function to initialize PostgreSQL database
initializePostgres() {
    logMessage "Initializing PostgreSQL database..."
    /etc/startpre.d/init_psql.sh ${dbDir} ${port}
    logMessage "PostgreSQL database initialized."
}

# Function to set permissions and ownership
setPermissions() {
    logMessage "Setting permissions and ownership for database directory..."
    chmod 0700 -R $dbDir > /dev/null 2>&1
    chown postgres:postgres -R $dbDir > /dev/null 2>&1
    logMessage "Permissions and ownership set."
}

# Function to start PostgreSQL
startPostgres() {
    logMessage "Starting PostgreSQL..."
    su - postgres -c "/usr/lib/postgresql/15/bin/pg_ctl start -D $dbDir -s -w"

    # Check if PostgreSQL started successfully
    local retries=10
    local count=0
    while [ $count -lt $retries ]; do
        if ps -ef | grep postgres | grep videomgr | grep -v grep > /dev/null; then
            logMessage "PostgreSQL started successfully."
            return 0
        else
            logMessage "PostgreSQL wait to start, sleep 1"
            sleep 1
            count=$((count + 1))
        fi
    done

    logMessage "PostgreSQL failed to start."
    return 1
}

# Function to initialize application database
initializeDatabase() {
    logMessage "Initializing application database..."
    /etc/startpre.d/init_database.sh ${port} video ${dbDir}
    logMessage "Application database initialized."
}

# Create symlink for the video_serv binary (move to end to ensure other services are started first)
createSymlink() {
    logMessage "Creating symlink for video_serv..."
    ln -fsn $rootfs/sbin/video_serv /var/targets/
    logMessage "Symlink for video_serv created."
}

# Main script execution
logMessage "****************start video server bash******************"
stopPostgresProcesses
if ! waitForPostgresEnd; then
    logMessage "Failed to stop all PostgreSQL processes."
    exit 1
fi

removePostmasterPid
setDbListenAddr
initializePostgres
setPermissions
startPostgres
initializeDatabase
createSymlink

logMessage "Video service initialization complete."
logMessage "****************end video server bash******************"


