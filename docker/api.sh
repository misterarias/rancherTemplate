#/!bin/sh
TOPDIR=$(pwd)

JQ=$(which jq)
if [ -z $(which jq) ] ; then
  mkdir -p ${TOPDIR}/bin
  JQ=${TOPDIR}/bin/jq
  curl https://github.com/stedolan/jq/releases/download/jq-1.5/jq-linux64 > $JQ
  chmod +x $JQ
fi

APIKEYS=$(curl -s -k \
  -X POST \
  -H 'Accept: application/json' \
  -d '{ "description": "new keys", "name": "new_keys" }' \
  'https://mi.org:8080/v1/apikeys')

CATTLE_ACCESS_KEY=$(echo "$APIKEYS" | $JQ -c .publicValue | tr -d '"')
CATTLE_SECRET_KEY=$(echo "$APIKEYS" | $JQ -c .secretValue | tr -d '"')
ACTIVATE_URL=$(echo "$APIKEYS" | $JQ -c .actions.activate | tr -d '"')

curl -k -s  -X POST $ACTIVATE_URL | jq .


# Create a local registry
curl -k  -s -u "${CATTLE_ACCESS_KEY}:${CATTLE_SECRET_KEY}" \
  -X POST \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -d '{"description":"local registry", "serverAddress":"https://mi.org:5000", "name":"juanito"}' \
  'https://mi.org:8080/v1/registries' | jq .
echo

