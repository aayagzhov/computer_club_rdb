echo "============================================"
echo " Start docker containers"
echo "============================================"

docker compose up -d

echo ""
echo "=== Waiting for all nodes to be ready (30 seconds) ==="
sleep 30

./init.sh