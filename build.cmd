@echo OFF

echo Build Visualizer Docker Image
docker build -t visualizer -f vizDockerfile .

echo Build ShinyProxy and Database Images
docker compose build