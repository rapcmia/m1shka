# 1) Create folder for your new instance
 mkdir autobot

# 2) Create folders for logs, config files and database file 
mkdir autobot/certs autobot/logs autobot/data autobot/conf autobot/pmm-scripts autobot/script

# 3) Copy config files from pre-existing config folder 
cp -a \
hummingbot_files/conf/* \
hummingbot_files/conf/.password_verification \
autobot/conf

# 4) Set environment variables specifying the strategy config file to use, and the decryption password
export CONFIG_FILE_NAME=log_price_example.py
export CONFIG_PASSWORD=test
export TAG=development

docker run -it --log-opt max-size=10m --log-opt max-file=5 \
--name autobot \
--network host \
-v $PWD/autobot/conf:/conf \
-v $PWD/autobot/logs:/logs \
-v $PWD/autobot/data:/data \
-v $PWD/autobot/pmm-scripts:/pmm-scripts \
-v $PWD/autobot/scripts:/scripts \
-v $PWD/autobot/certs:/certs \
-e STRATEGY -e CONFIG_FILE_NAME -e CONFIG_PASSWORD \
hummingbot/hummingbot:development && docker attach autobot
