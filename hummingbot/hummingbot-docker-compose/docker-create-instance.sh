# 1) Create folder for your new instance
mkdir hummingbot_files

# 2) Create folders for logs, config files and database file
mkdir hummingbot_files/conf \
hummingbot_files/conf/connectors \
hummingbot_files/conf/strategies \
hummingbot_files/certs \
hummingbot_files/logs \
hummingbot_files/data \
hummingbot_files/scripts \
hummingbot_files/pmm-scripts 

docker run -it --log-opt max-size=10m --log-opt max-file=5 \
--name bot1 \
--network host \
-v $PWD/hummingbot_files/conf:/conf \
-v $PWD/hummingbot_files/logs:/logs \
-v $PWD/hummingbot_files/data:/data \
-v $PWD/hummingbot_files/pmm-scripts:/pmm-scripts \
-v $PWD/hummingbot_files/scripts:/scripts \
-v $PWD/hummingbot_files/certs:/certs \
hummingbot/hummingbot:development
