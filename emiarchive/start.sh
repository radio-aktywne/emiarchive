#!/bin/sh

set -m # for job control

admin_user="${EMIARCHIVE_ADMIN_USER:-admin}"
admin_password="${EMIARCHIVE_ADMIN_PASSWORD:-password}"
port="${EMIARCHIVE_PORT:-30000}"
admin_port="${EMIARCHIVE_ADMIN_PORT:-30001}"
bucket="recordings"
readonly_user="${EMIARCHIVE_READONLY_USER:-readonly}"
readonly_password="${EMIARCHIVE_READONLY_PASSWORD:-password}"
readwrite_user="${EMIARCHIVE_READWRITE_USER:-readwrite}"
readwrite_password="${EMIARCHIVE_READWRITE_PASSWORD:-password}"

export "MINIO_ROOT_USER=$admin_user"
export "MINIO_ROOT_PASSWORD=$admin_password"

minio server ./data \
  --address ":$port" \
  --console-address ":$admin_port" &

echo 'Setting up minio...'

while ! mc config host add minio "http://localhost:${port}" "$admin_user" "$admin_password" >/dev/null 2>&1; do
  echo 'Waiting for minio to startup...'
  sleep 0.1
done

echo 'Connected to minio!'

echo 'Setting up bucket...'
mc mb -p minio/recordings

echo 'Setting up readonly user...'
mc admin user add minio "$readonly_user" "$readonly_password"
mc admin policy add minio custom-readonly ./conf/policies/readonly.json
mc admin policy set minio custom-readonly "user=$readonly_user"

echo 'Setting up readwrite user...'
mc admin user add minio "$readwrite_user" "$readwrite_password"
mc admin policy add minio custom-readwrite ./conf/policies/readwrite.json
mc admin policy set minio custom-readwrite "user=$readwrite_user"

echo 'Minio setup finished!'
echo "Bucket: $bucket"
echo "Readonly user: $readonly_user"
echo "Readwrite user: $readwrite_user"

fg %1 >/dev/null
