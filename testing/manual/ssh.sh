CONTAINER_ID=$(docker run --rm --detach jonrad/profilerate-bash:v1)
IP=$(docker inspect -f "{{ .NetworkSettings.IPAddress }}" $CONTAINER_ID)
echo "CONTAINER: $CONTAINER_ID"
echo "IP: $IP"
