FROM alpine:latest
MAINTAINER dwaiba <dwaiba@microsoft.com>
ENV LATEST=v4.x VERSION=v6.2.2 NPM_VERSION=3.9.5
#ENV LATEST=v5.x VERSION=v5.0.0 NPM_VERSION=3.4.1

# For base builds
# ENV CONFIG_FLAGS="--without-npm" RM_DIRS=/usr/include
#ENV CONFIG_FLAGS="--fully-static --without-npm" DEL_PKGS="libgcc libstdc++" RM_DIRS=/usr/include

RUN apk add --update curl make gcc g++ python linux-headers paxctl libgcc libstdc++ git wget && \
  curl -sSL https://nodejs.org/dist/latest/node-${VERSION}.tar.gz | tar -xz && \
  cd /node-${VERSION} && \
  ./configure --prefix=/usr ${CONFIG_FLAGS} && \
  make -j$(grep -c ^processor /proc/cpuinfo 2>/dev/null || 1) && \
  make install && \
  paxctl -cm /usr/bin/node && \
  cd / && \
  if [ -x /usr/bin/npm ]; then \
    npm install -g npm@${NPM_VERSION} && \
    find /usr/lib/node_modules/npm -name test -o -name .bin -type d | xargs rm -rf; \
  fi && \
  #apk del curl make gcc g++ python linux-headers paxctl ${DEL_PKGS} && \
  apk del  linux-headers paxctl ${DEL_PKGS} && \
  rm -rf /etc/ssl /node-${VERSION} ${RM_DIRS} \
    /usr/share/man /tmp/* /var/cache/apk/* /root/.npm /root/.node-gyp \
    /usr/lib/node_modules/npm/man /usr/lib/node_modules/npm/doc /usr/lib/node_modules/npm/html
RUN mkdir /opt && git config --system http.sslverify false
RUN cd /opt && git clone https://github.com/node-red/node-red.git
RUN cd /opt/node-red && npm install
RUN cd /opt/node-red && npm install -g grunt-cli
RUN cd /opt/node-red && npm install auth0-lock --save
RUN cd /opt/node-red && npm install express-jwt --save
RUN cd /opt/node-red && grunt build
EXPOSE 1880
EXPOSE 443
EXPOSE 80
RUN cd /opt && mkdir /opt/node-redstatic
RUN cd /opt/node-red && npm install node-red-contrib-freeboard
RUN cd /opt/node-red/node_modules/node-red-contrib-freeboard/node_modules/freeboard/plugins/ && git clone https://github.com/Freeboard/plugins.git
RUN cd /opt/node-red/node_modules/node-red-contrib-freeboard/node_modules/freeboard/plugins/plugins && mv * ../
RUN cd /opt/node-red/node_modules/node-red-contrib-freeboard/node_modules/freeboard/plugins/ && rm -rf plugins
RUN cd /opt/node-red/node_modules/node-red-contrib-freeboard/node_modules/freeboard/ && sed -i.bak -e '13d' index.html
RUN cd /opt/node-red/node_modules/node-red-contrib-freeboard/node_modules/freeboard/ && sed -i '13ihead.js("js/freeboard.js","js/freeboard.plugins.min.js", "../freeboard_api/datasources","plugins/datasources/plugin_json_ws.js","plugins/datasources/plugin_node.js",' index.html
RUN cd /opt/node-red && npm install node-red-node-mongodb
RUN cd /opt/node-red && npm install node-red-contrib-mongodb2
RUN cd /opt/node-red && npm install node-red-contrib-salesforce
RUN cd /opt/node-red && npm install node-red-contrib-googlechart
RUN cd /opt/node-red && npm install node-red-azure-iot-hub 
RUN cd /opt/node-red && npm install node-red-contrib-azure-documentdb 
RUN cd /opt/node-red && npm install node-red-contrib-azure-table-storage
RUN cd /opt/node-red && npm install node-red-contrib-azure-blob-storage
RUN cd /opt/node-red && npm install node-red-contrib-azure-iot-hub
CMD ["node", "/opt/node-red/red.js"]
