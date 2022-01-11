FROM chase81/buildbase:ubuntu20.04_gcc11_openssl_cmake3.18_aws-s3_cpprest_mysqlcppconn8_boost1.78

RUN cd /usr/src \
&& git clone -b main --single-branch https://github.com/lazychase/mlnserver.git \
&& cd mlnserver \
&& cmake -DCMAKE_BUILD_TYPE=Debug CMakeLists.txt && make -j$(nproc) \
&& mkdir -p /usr/local/mlnserver \
&& cp ./mlnserver/mlnserver /usr/local/mlnserver \
&& cp ./mlnserver/netconfig.json /usr/local/mlnserver

WORKDIR /usr/local/mlnserver

CMD ["./mlnserver"]
