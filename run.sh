SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
COMPOSE_FILE="$SCRIPT_DIR/docker-compose.yml"

docker-compose -f $COMPOSE_FILE up -d --build

cd metadata-service
git pull
mkdir ../log
> ../log/metadata-service.log
./gradlew bootRun >> ../log/metadata-service.log &
PID1=$!

cd ../ingest-service
git pull
> ../log/ingest-service.log
./gradlew bootRun >> ../log/ingest-service.log &
PID2=$!

cd ../austrian-geosphere-data-collector
git pull
> ../log/austrian-geosphere-data-collector.log
sleep 10
./gradlew bootRun >> ../log/austrian-geosphere-data-collector.log &
PID3=$!

cd ../orchestrator
git pull
> ../log/orchestrator.log
sleep 10
./gradlew bootRun >> ../log/orchestrator.log &
PID4=$!

cd ..

# Function to stop both applications on exit
function cleanup {
  echo "Stopping applications..."
  kill $PID1
  kill $PID2
  kill $PID3
  kill $PID4
  docker-compose -f $COMPOSE_FILE down
}

# Trap the EXIT signal to ensure cleanup is done
trap cleanup EXIT

# Wait for both applications to finish
wait $PID1
wait $PID2
wait $PID3
wait $PID4