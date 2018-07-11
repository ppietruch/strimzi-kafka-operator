#!/bin/bash

# path were the Secret with certificates is mounted
CERTS=/etc/stunnel/certs

echo "pid = /usr/local/var/run/stunnel.pid"
echo "foreground = yes"
echo "debug = info"
 
declare -a PORTS=("2888" "3888")

CURRENT=${BASE_HOSTNAME}-$((ZOOKEEPER_ID-1))

for port in "${PORTS[@]}"
do
	NODE=1
	while [ $NODE -le $ZOOKEEPER_NODE_COUNT ]
	do
		# current node configuration is not needed
		if [ $NODE -ne $ZOOKEEPER_ID ]; then
			PEER=${BASE_HOSTNAME}-$((NODE-1))

			# configuration for outgoing connection to a peer
			cat <<-EOF
			[${PEER}]
			client=yes
			CAfile=${CERTS}/internal-ca.crt
			cert=${CERTS}/${CURRENT}.crt
			key=${CERTS}/${CURRENT}.key
			accept=127.0.0.1:$(expr $port \* 10 + $NODE - 1)
			connect=${PEER}.${BASE_FQDN}:$port

			EOF
		fi
		let NODE=NODE+1
	done

	# Zookeeper port where stunnel forwards received traffic
	CONNECTOR_PORT=$(expr $port \* 10 + $ZOOKEEPER_ID - 1)

	# listener configuration for incoming connection from peers
	cat <<-EOF
	[listener-$port]
	client=no
	cert=${CERTS}/${CURRENT}.crt
	key=${CERTS}/${CURRENT}.key
	accept=$port
	connect=127.0.0.1:$CONNECTOR_PORT

	EOF
done
