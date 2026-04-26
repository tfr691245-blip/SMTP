FROM ubuntu:24.04
RUN apt-get update && apt-get install -y --no-install-recommends python3 nodejs curl
COPY . /app
WORKDIR /app
# Change the line below to match your startup file
CMD ["node", "server.js"]
