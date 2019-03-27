#!/usr/bin/env bash
# This script sets up the CockroachDB databases and users for the Politeia
# cache.  This includes creating the client certificates for the politeiad and
# politeiawww users, creating the corresponding database users, setting up the
# cache databases, and assigning user privileges.
# This script requires that you have already created CockroachDB certificates
# using the cockroachcerts.sh script and that you have a CockroachDB instance
# listening on the default port localhost:26257.

set -ex

# COCKROACHDB_DIR must be the same directory that was passed into the
# cockroachcerts.sh script.
readonly COCKROACHDB_DIR=$1

if [ "${COCKROACHDB_DIR}" == "" ]; then
    >&2 echo "error: missing argument CockroachDB directory"
    exit
fi

# ROOT_CERTS_DIR must contain client.root.crt, client.root.key, and ca.crt.
readonly ROOT_CERTS_DIR="${COCKROACHDB_DIR}/certs/clients/root"

if [ ! -f "${ROOT_CERTS_DIR}/client.root.crt" ]; then
    >&2 echo "error: file not found ${ROOT_CERTS_DIR}/client.root.crt"
    exit
elif [ ! -f "${ROOT_CERTS_DIR}/client.root.key" ]; then
    >&2 echo "error: file not found ${ROOT_CERTS_DIR}/client.root.key"
    exit
elif [ ! -f "${ROOT_CERTS_DIR}/ca.crt" ]; then
    >&2 echo "error: file not found ${ROOT_CERTS_DIR}/ca.crt"
    exit
fi

# Database names.
readonly DB_MAINNET="records_mainnet"
readonly DB_TESTNET="records_testnet3"

# Database usernames.
readonly USER_POLITEIAD="records_politeiad"
readonly USER_POLITEIAWWW="records_politeiawww"

# Make directories for the politeiad and politeiawww client certs.
mkdir -p "${COCKROACHDB_DIR}/certs/clients/${USER_POLITEIAD}"
mkdir -p "${COCKROACHDB_DIR}/certs/clients/${USER_POLITEIAWWW}"

# Create the client certificate and key for the politeiad user.
cp "${COCKROACHDB_DIR}/certs/ca.crt" \
  "${COCKROACHDB_DIR}/certs/clients/${USER_POLITEIAD}"

cockroach cert create-client ${USER_POLITEIAD} \
  --certs-dir="${COCKROACHDB_DIR}/certs/clients/${USER_POLITEIAD}" \
  --ca-key="${COCKROACHDB_DIR}/ca.key"

# Create the client certificate and key for politeiawww user.
cp "${COCKROACHDB_DIR}/certs/ca.crt" \
  "${COCKROACHDB_DIR}/certs/clients/${USER_POLITEIAWWW}"

cockroach cert create-client ${USER_POLITEIAWWW} \
  --certs-dir="${COCKROACHDB_DIR}/certs/clients/${USER_POLITEIAWWW}" \
  --ca-key="${COCKROACHDB_DIR}/ca.key"

# Create the mainnet and testnet databases for the politeiad records cache.
cockroach sql \
  --certs-dir="${ROOT_CERTS_DIR}" \
  --execute "CREATE DATABASE IF NOT EXISTS ${DB_MAINNET}"

cockroach sql \
  --certs-dir="${ROOT_CERTS_DIR}" \
  --execute "CREATE DATABASE IF NOT EXISTS ${DB_TESTNET}"

# Create the politeiad user and assign privileges.
cockroach sql \
  --certs-dir="${ROOT_CERTS_DIR}" \
  --execute "CREATE USER IF NOT EXISTS ${USER_POLITEIAD}"

cockroach sql \
  --certs-dir="${ROOT_CERTS_DIR}" \
  --execute "GRANT CREATE, SELECT, DROP, INSERT, DELETE, UPDATE \
  ON DATABASE ${DB_MAINNET} TO  ${USER_POLITEIAD}"

cockroach sql \
  --certs-dir="${ROOT_CERTS_DIR}" \
  --execute "GRANT CREATE, SELECT, DROP, INSERT, DELETE, UPDATE \
  ON DATABASE ${DB_TESTNET} TO  ${USER_POLITEIAD}"

# Create politeiawww user and assign privileges.
cockroach sql \
  --certs-dir="${ROOT_CERTS_DIR}" \
  --execute "CREATE USER IF NOT EXISTS ${USER_POLITEIAWWW}"

cockroach sql \
  --certs-dir="${ROOT_CERTS_DIR}" \
  --execute "GRANT SELECT ON DATABASE ${DB_MAINNET} TO  ${USER_POLITEIAWWW}"

cockroach sql \
  --certs-dir="${ROOT_CERTS_DIR}" \
  --execute "GRANT SELECT ON DATABASE ${DB_TESTNET} TO  ${USER_POLITEIAWWW}"
