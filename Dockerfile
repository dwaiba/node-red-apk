FROM alpine:3.4
MAINTAINER dwaiba <dwaiba@microsoft.com>
ENV VERSION=v6.2.2 NPM_VERSION=3

# For base builds
# ENV CONFIG_FLAGS="--without-npm" RM_DIRS=/usr/include
# ENV CONFIG_FLAGS="--fully-static --without-npm" DEL_PKGS="libgcc libstdc++" RM_DIRS=/usr/include

RUN apk add --no-cache curl make gcc g++ python linux-headers paxctl libgcc libstdc++ gnupg && \
  gpg --keyserver ha.pool.sks-keyservers.net --recv-keys \
    9554F04D7259F04124DE6B476D5A82AC7E37093B \
    94AE36675C464D64BAFA68DD7434390BDBE9B9C5 \
    0034A06D9D9B0064CE8ADF6BF1747F4AD2306D93 \
    FD3A5288F042B6850C66B31F09FE44734EB7990E \
    71DCFD284A79C3B38668286BC97EC7A07EDE3FC1 \
    DD8F2338BAE7501E3DD5AC78C273792F7D83545D \
    C4F0DFFF4E8C1A8236409D08E73BC641CC11F4C8 \
    B9AE9905FFD7803F25714661B63B535A4C206CA9 && \
  curl -o node-${VERSION}.tar.gz -sSL https://nodejs.org/dist/${VERSION}/node-${VERSION}.tar.gz && \
  curl -o SHASUMS256.txt.asc -sSL https://nodejs.org/dist/${VERSION}/SHASUMS256.txt.asc && \
  gpg --verify SHASUMS256.txt.asc && \
  grep node-${VERSION}.tar.gz SHASUMS256.txt.asc | sha256sum -c - && \
  tar -zxf node-${VERSION}.tar.gz && \
  cd node-${VERSION} && \
  export GYP_DEFINES="linux_use_gold_flags=0" && \
  ./configure --prefix=/usr ${CONFIG_FLAGS} && \
  NPROC=$(grep -c ^processor /proc/cpuinfo 2>/dev/null || 1) && \
  make -j${NPROC} -C out mksnapshot BUILDTYPE=Release && \
  paxctl -cm out/Release/mksnapshot && \
  make -j${NPROC} && \
  make install && \
  paxctl -cm /usr/bin/node && \
  cd / && \
  if [ -x /usr/bin/npm ]; then \
    npm install -g npm@${NPM_VERSION} && \
    find /usr/lib/node_modules/npm -name test -o -name .bin -type d | xargs rm -rf; \
  fi && \
  apk del curl make gcc g++ python linux-headers paxctl gnupg ${DEL_PKGS} && \
  rm -rf /etc/ssl /node-${VERSION}.tar.gz /SHASUMS256.txt.asc /node-${VERSION} ${RM_DIRS} \
    /usr/share/man /tmp/* /var/cache/apk/* /root/.npm /root/.node-gyp /root/.gnupg \
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
