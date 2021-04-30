#!/bin/bash
# This bash file install apache
# Parameter 1 hostname 
azure_hostname=$1
rtmp_path=$2
storage_account=$3
storage_container=$4
storage_sas_token=$5
#############################################################################
log()
{
	# If you want to enable this logging, uncomment the line below and specify your logging key 
	#curl -X POST -H "content-type:text/plain" --data-binary "$(date) | ${HOSTNAME} | $1" https://logs-01.loggly.com/inputs/${LOGGING_KEY}/tag/redis-extension,${HOSTNAME}
	echo "$1"
	echo "$1" >> /testrtmp/log/install.log
}

#############################################################################
check_os() {
    grep ubuntu /proc/version > /dev/null 2>&1
    isubuntu=${?}
    grep centos /proc/version > /dev/null 2>&1
    iscentos=${?}
    grep redhat /proc/version > /dev/null 2>&1
    isredhat=${?}	
	if [ -f /etc/debian_version ]; then
    isdebian=0
	else
	isdebian=1	
    fi

	if [ $isubuntu -eq 0 ]; then
		OS=Ubuntu
		VER=$(lsb_release -a | grep Release: | sed  's/Release://'| sed -e 's/^[ \t]*//' | cut -d . -f 1)
	elif [ $iscentos -eq 0 ]; then
		OS=Centos
		VER=$(cat /etc/centos-release)
	elif [ $isredhat -eq 0 ]; then
		OS=RedHat
		VER=$(cat /etc/redhat-release)
	elif [ $isdebian -eq 0 ];then
		OS=Debian  # XXX or Ubuntu??
		VER=$(cat /etc/debian_version)
	else
		OS=$(uname -s)
		VER=$(uname -r)
	fi
	
	ARCH=$(uname -m | sed 's/x86_//;s/i[3-6]86/32/')

	log "OS=$OS version $VER Architecture $ARCH"
}


#############################################################################
configure_network(){
# firewall configuration 
iptables -A INPUT -p tcp --dport 80 -j ACCEPT
iptables -A INPUT -p tcp --dport 8080 -j ACCEPT
iptables -A INPUT -p tcp --dport 8554 -j ACCEPT
iptables -A INPUT -p udp --dport 8554 -j ACCEPT
iptables -A INPUT -p udp --dport 7001 -j ACCEPT
iptables -A INPUT -p tcp --dport 443 -j ACCEPT
iptables -A INPUT -p tcp --dport 1935 -j ACCEPT
}
#############################################################################
configure_network_centos(){
# firewall configuration 
iptables -A INPUT -p tcp --dport 80 -j ACCEPT
iptables -A INPUT -p tcp --dport 8080 -j ACCEPT
iptables -A INPUT -p tcp --dport 8554 -j ACCEPT
iptables -A INPUT -p udp --dport 8554 -j ACCEPT
iptables -A INPUT -p udp --dport 7001 -j ACCEPT
iptables -A INPUT -p tcp --dport 443 -j ACCEPT
iptables -A INPUT -p tcp --dport 1935 -j ACCEPT


service firewalld start
firewall-cmd --permanent --add-port=80/tcp
firewall-cmd --permanent --add-port=8080/tcp
firewall-cmd --permanent --add-port=443/tcp
firewall-cmd --permanent --add-port=1935/tcp
firewall-cmd --permanent --add-port=8554/tcp
firewall-cmd --permanent --add-port=8554/udp
firewall-cmd --permanent --add-port=7001/udp
firewall-cmd --reload
}



#############################################################################
install_git_ubuntu(){
apt-get -y install git
}
install_git_centos(){
yum -y install git
}





#############################################################################
install_nginx_rtmp(){
# install pre-requisites
apt-get -y install build-essential curl g++
# Download source code
cd /git
apt-get -y update
apt-get -y install gcc
apt-get -y install make
apt-get -y install libpcre3 libpcre3-dev
apt-get -y install libssl-dev
apt-get -y install zlib1g-dev
#git clone https://github.com/nginx/nginx.git
wget http://nginx.org/download/nginx-1.16.1.tar.gz
tar xvfz nginx-1.16.1.tar.gz
git clone https://github.com/arut/nginx-rtmp-module.git 
cd nginx-1.16.1
./configure --add-module=/git/nginx-rtmp-module
make
make install

log "nginx_rtmp installed"

}
#############################################################################
install_rtsp(){
cd /git
wget https://github.com/aler9/rtsp-simple-server/releases/download/v0.12.2/rtsp-simple-server_v0.12.2_linux_amd64.tar.gz
tar xvfz rtsp-simple-server_v0.12.2_linux_amd64.tar.gz
cp ./rtsp-simple-server /usr/bin/
cp ./rtsp-simple-server.yml /usr/bin/
log "rtsp-simple-server installed"
}

install_nginx_rtmp_centos(){
# install pre-requisites
yum -y groupinstall 'Development Tools'
yum -y install epel-release
yum install -y  wget git unzip perl perl-devel perl-ExtUtils-Embed libxslt libxslt-devel libxml2 libxml2-devel gd gd-devel pcre-devel GeoIP GeoIP-devel
# Download source code
cd /usr/local/src
wget https://nginx.org/download/nginx-1.14.0.tar.gz
tar -xzvf nginx-1.14.0.tar.gz
wget https://ftp.pcre.org/pub/pcre/pcre-8.42.zip
unzip pcre-8.42.zip
wget https://www.zlib.net/zlib-1.2.11.tar.gz
tar -xzvf zlib-1.2.11.tar.gz
wget https://www.openssl.org/source/openssl-1.1.0h.tar.gz
tar -xzvf openssl-1.1.0h.tar.gz
git clone https://github.com/sergey-dryabzhinsky/nginx-rtmp-module.git
rm -f *.tar.gz *.zip
ls -lah
cd nginx-1.14.0/
./configure --prefix=/etc/nginx \
            --sbin-path=/usr/sbin/nginx \
            --modules-path=/usr/lib64/nginx/modules \
            --conf-path=/etc/nginx/nginx.conf \
            --error-log-path=/var/log/nginx/error.log \
            --pid-path=/var/run/nginx.pid \
            --lock-path=/var/run/nginx.lock \
            --user=nginx \
            --group=nginx \
            --build=CentOS \
            --builddir=nginx-1.14.0 \
            --with-select_module \
            --with-poll_module \
            --with-threads \
            --with-file-aio \
            --with-http_ssl_module \
            --with-http_v2_module \
            --with-http_realip_module \
            --with-http_addition_module \
            --with-http_xslt_module=dynamic \
            --with-http_image_filter_module=dynamic \
            --with-http_geoip_module=dynamic \
            --with-http_sub_module \
            --with-http_dav_module \
            --with-http_flv_module \
            --with-http_mp4_module \
            --with-http_gunzip_module \
            --with-http_gzip_static_module \
            --with-http_auth_request_module \
            --with-http_random_index_module \
            --with-http_secure_link_module \
            --with-http_degradation_module \
            --with-http_slice_module \
            --with-http_stub_status_module \
            --http-log-path=/var/log/nginx/access.log \
            --http-client-body-temp-path=/var/cache/nginx/client_temp \
            --http-proxy-temp-path=/var/cache/nginx/proxy_temp \
            --http-fastcgi-temp-path=/var/cache/nginx/fastcgi_temp \
            --http-uwsgi-temp-path=/var/cache/nginx/uwsgi_temp \
            --http-scgi-temp-path=/var/cache/nginx/scgi_temp \
            --with-mail=dynamic \
            --with-mail_ssl_module \
            --with-stream=dynamic \
            --with-stream_ssl_module \
            --with-stream_realip_module \
            --with-stream_geoip_module=dynamic \
            --with-stream_ssl_preread_module \
            --with-compat \
            --with-pcre=../pcre-8.42 \
            --with-pcre-jit \
            --with-zlib=../zlib-1.2.11 \
            --with-openssl=../openssl-1.1.0h \
            --with-openssl-opt=no-nextprotoneg \
            --add-module=../nginx-rtmp-module \
            --with-debug

make 
make install

ln -s /usr/lib64/nginx/modules /etc/nginx/modules

useradd -r -d /var/cache/nginx/ -s /sbin/nologin -U nginx

mkdir -p /var/cache/nginx/
chown -R nginx:nginx /var/cache/nginx/

nginx -t
nginx -V

cat <<EOF > /lib/systemd/system/nginx.service
[Unit]
Description=nginx - high performance web server
Documentation=https://nginx.org/en/docs/
After=network-online.target remote-fs.target nss-lookup.target
Wants=network-online.target

[Service]
Type=forking
PIDFile=/var/run/nginx.pid
ExecStartPre=/usr/sbin/nginx -t -c /etc/nginx/nginx.conf
ExecStart=/usr/sbin/nginx -c /etc/nginx/nginx.conf
ExecReload=/bin/kill -s HUP $MAINPID
ExecStop=/bin/kill -s TERM $MAINPID

[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload
systemctl start nginx
systemctl enable nginx


log "nginx_rtmp installed"

}

#############################################################################
install_ffmpeg(){
# install pre-requisites
apt-get -y update
apt-get -y install ffmpeg
log "ffmpeg installed"
}

install_ffmpeg_centos(){
# install pre-requisites
yum -y install epel-release
rpm -v --import http://li.nux.ro/download/nux/RPM-GPG-KEY-nux.ro
rpm -Uvh http://li.nux.ro/download/nux/dextop/el7/x86_64/nux-dextop-release-0-5.el7.nux.noarch.rpm
yum -y install ffmpeg ffmpeg-devel
log "ffmpeg installed"
}
install_ffmpeg_redhat(){
# install pre-requisites
yum -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
yum-config-manager --add-repo https://negativo17.org/repos/epel-multimedia.repo
yum -y install ffmpeg 
log "ffmpeg installed"
}

#############################################################################
install_azcli(){
cd /git
 
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

log "azcli installed"
}

install_azcli_centos(){
cd /git
rpm --import https://packages.microsoft.com/keys/microsoft.asc

sh -c 'echo -e "[azure-cli]
name=Azure CLI
baseurl=https://packages.microsoft.com/yumrepos/azure-cli
enabled=1
gpgcheck=1
gpgkey=https://packages.microsoft.com/keys/microsoft.asc" > /etc/yum.repos.d/azure-cli.repo'
yum -y install azure-cli

log "azcli installed"
}


#############################################################################
install_azcopy(){
cd /git
wget https://aka.ms/downloadazcopy-v10-linux
 
#Expand Archive
tar -xvf downloadazcopy-v10-linux
 
#(Optional) Remove existing AzCopy version
sudo rm /usr/bin/azcopy
 
#Move AzCopy to the destination you want to store it
sudo cp ./azcopy_linux_amd64_*/azcopy /usr/bin/
log "azcopy installed"
}

#############################################################################
install_ffmpeg_service(){
cat <<EOF > /testrtmp/ffmpegloop.sh
while [ : ]
do
folder=\$(date  +"%F-%X.%S")
mkdir /chunks/\$folder
echo mkdir /chunks/\$folder >> /testrtmp/log/ffmpeg.log
/usr/bin/ffmpeg -f flv -i rtmp://127.0.0.1:1935/$1 -c copy -flags +global_header -f segment -segment_time 60 -segment_format_options movflags=+faststart -reset_timestamps 1 -strftime 1 "/chunks/\$folder/%Y-%m-%d_%H-%M-%S_chunk.mp4" 
sleep 5
done
EOF

chmod +x   /testrtmp/ffmpegloop.sh
adduser testrtmpuser --disabled-login
usermod -aG sudo testrtmpuser


cat <<EOF > /etc/systemd/system/ffmpegloop.service
[Unit]
Description=ffmpeg Loop Service
After=network.target

[Service]
Type=simple
User=testrtmpuser
ExecStart=/bin/sh /testrtmp/ffmpegloop.sh
Restart=on-abort

[Install]
WantedBy=multi-user.target
EOF
}

#############################################################################
install_nginxrtmp_service(){
cat <<EOF > /testrtmp/nginxrtmploop.sh
while [ : ]
do
folder=\$(date  +"%F-%X.%S")
echo Starting nginx rtmp loop \$folder >> /testrtmp/log/nginxrtmp.log
/usr/local/nginx/sbin/nginx -g "daemon off;"
sleep 5
done
EOF

chmod +x   /testrtmp/nginxrtmploop.sh
adduser testrtmpuser --disabled-login
usermod -aG sudo testrtmpuser

cat <<EOF > /etc/systemd/system/nginxrtmploop.service
[Unit]
Description=nginx rtmp Loop Service
After=network.target

[Service]
Type=simple
ExecStart=/bin/sh /testrtmp/nginxrtmploop.sh
Restart=on-abort

[Install]
WantedBy=multi-user.target
EOF
}

#############################################################################
install_rtsp_service(){
cat <<EOF > /testrtmp/rtsploop.sh
export RTSP_PROTOCOLS=tcp 
export RTSP_RTSPPORT=8554
while [ : ]
do
folder=\$(date  +"%F-%X.%S")
echo Starting rtsp loop \$folder >> /testrtmp/log/rtsp.log
/usr/bin/rtsp-simple-server
sleep 5
done
EOF

chmod +x   /testrtmp/rtsploop.sh
adduser testrtmpuser --disabled-login
usermod -aG sudo testrtmpuser

cat <<EOF > /etc/systemd/system/rtsploop.service
[Unit]
Description=rtsp Loop Service
After=network.target

[Service]
Type=simple
User=testrtmpuser
ExecStart=/bin/sh /testrtmp/rtsploop.sh
Restart=on-abort

[Install]
WantedBy=multi-user.target
EOF
}
#############################################################################
install_ffmpegrtsp_service(){
cat <<EOF > /testrtmp/ffmpegrtsploop.sh
while [ : ]
do
folder=\$(date  +"%F-%X.%S")
echo Starting rtsp loop \$folder >> /testrtmp/log/ffmpegrtsp.log
#ffmpeg  -i rtmp://127.0.0.1:1935/live/stream  -framerate 25 -video_size 640x480  -pix_fmt yuv420p -bsf:v h264_mp4toannexb -profile:v baseline -level:v 3.2 -c:v libx264 -x264-params keyint=120:scenecut=0 -c:a aac -b:a 128k -ar 44100 -f rtsp -muxdelay 0.1 rtsp://127.0.0.1:8554/test
#ffmpeg  -i rtmp://127.0.0.1:1935/live/stream  -f rtsp  rtsp://127.0.0.1:8554/rtsp/stream 
ffmpeg  -i rtmp://127.0.0.1:1935/live/stream   -codec copy -bsf:v h264_mp4toannexb -f rtsp  rtsp://127.0.0.1:8554/rtsp/stream
sleep 5
done
EOF

chmod +x   /testrtmp/ffmpegrtsploop.sh
adduser testrtmpuser --disabled-login
usermod -aG sudo testrtmpuser

cat <<EOF > /etc/systemd/system/ffmpegrtsploop.service
[Unit]
Description=rtsp Loop Service
After=network.target

[Service]
Type=simple
User=testrtmpuser
ExecStart=/bin/sh /testrtmp/ffmpegrtsploop.sh
Restart=on-abort

[Install]
WantedBy=multi-user.target
EOF
}

install_ffmpeg_service_centos(){
cat <<EOF > /testrtmp/ffmpegloop.sh
while [ : ]
do
folder=\$(date  +"%Y-%m-%d-%T")
mkdir /chunks/\$folder
echo mkdir /chunks/\$folder >> /testrtmp/log/ffmpeg.log
/usr/bin/ffmpeg -f flv -i rtmp://127.0.0.1:1935/$1 -c copy -flags +global_header -f segment -segment_time 60 -segment_format_options movflags=+faststart -reset_timestamps 1 -strftime 1 "/chunks/\$folder/%Y-%m-%d_%H-%M-%S_chunk.mp4" 
sleep 5
done
EOF
chmod +x   /testrtmp/ffmpegloop.sh
adduser  testrtmpuser -s /sbin/nologin
usermod -aG sudo testrtmpuser

cat <<EOF > /etc/systemd/system/ffmpegloop.service
[Unit]
Description=ffmpeg Loop Service
After=network.target

[Service]
Type=simple
User=testrtmpuser
ExecStart=/bin/bash /testrtmp/ffmpegloop.sh
Restart=on-abort

[Install]
WantedBy=multi-user.targetEOF
EOF
}
#############################################################################
install_azcopy_service(){
cat <<EOF > /testrtmp/azcopyloop.sh
prefixuri='$1'
sastoken="$2"
while [ : ]
do
for mp in /chunks/**/*.mp4
do
if [ \$mp != '/chunks/**/*.mp4' ];
then
echo Processing file: "\$mp"
#echo Token: "\$sastoken"
#echo Url: "\$prefixuri"
echo azcopy cp "\$mp" "\$prefixuri\$mp\$sastoken"
lsof | grep \$mp
if [ ! \${?} -eq 0 ];
then
        echo copying "\$mp"
        azcopy cp "\$mp" "\$prefixuri\$mp\$sastoken"
        rm -f "\$mp"
else
        echo in process "\$mp"
fi
fi
done
sleep 60
done
EOF

}




#############################################################################
install_azcli_service(){
cat <<EOF > /testrtmp/azcliloop.sh
account='$1'
container='$2'
sastoken="$3"
echo account: $account >> /testrtmp/log/azcli.log
echo container: $container  >> /testrtmp/log/azcli.log
echo sastoken: $sastoken   >> /testrtmp/log/azcli.log
while [ : ]
do
for mp in /chunks/**/*.mp4
do
if [ \$mp != '/chunks/**/*.mp4' ];
then
echo az storage blob upload -f "\$mp" -c "\$container" -n "\${mp:1}" --account-name "\$account" --sas-token "\$sastoken" >> /testrtmp/log/azcli.log
lsof | grep \$mp
if [ ! \${?} -eq 0 ];
then
        echo Processing file: "\$mp"  >> /testrtmp/log/azcli.log
        az storage blob upload -f "\$mp" -c "\$container" -n "\${mp:1}" --account-name "\$account" --sas-token "\$sastoken"
        rm -f "\$mp"
        echo file "\$mp" removed >> /testrtmp/log/azcli.log
else
        echo in process "\$mp"
fi
fi
done
sleep 60
done
EOF

chmod +x   /testrtmp/azcliloop.sh
adduser testrtmpuser --disabled-login
usermod -aG sudo testrtmpuser

cat <<EOF > /etc/systemd/system/azcliloop.service
[Unit]
Description=Azcli Loop Service
After=network.target

[Service]
Type=simple
User=testrtmpuser
ExecStart=/bin/bash /testrtmp/azcliloop.sh
Restart=on-abort


[Install]
WantedBy=multi-user.target
EOF
}

install_azcli_service_centos(){
cat <<EOF > /testrtmp/azcliloop.sh
account='$1'
container='$2'
sastoken="$3"
echo account: $account >> /testrtmp/log/azcli.log
echo container: $container  >> /testrtmp/log/azcli.log
echo sastoken: $sastoken   >> /testrtmp/log/azcli.log
while [ : ]
do
for mp in /chunks/**/*.mp4
do
if [ \$mp != '/chunks/**/*.mp4' ];
then
echo az storage blob upload -f "\$mp" -c "\$container" -n "\${mp:1}" --account-name "\$account" --sas-token "\$sastoken" >> /testrtmp/log/azcli.log
lsof | grep \$mp
if [ ! \${?} -eq 0 ];
then
        echo Processing file: "\$mp"  >> /testrtmp/log/azcli.log
        az storage blob upload -f "\$mp" -c "\$container" -n "\${mp:1}" --account-name "\$account" --sas-token "\$sastoken"
        rm -f "\$mp"
        echo file "\$mp" removed >> /testrtmp/log/azcli.log
else
        echo in process "\$mp"
fi
fi
done
sleep 60
done
EOF

chmod +x   /testrtmp/azcliloop.sh
adduser  testrtmpuser -s /sbin/nologin
usermod -aG sudo testrtmpuser

cat <<EOF > /etc/systemd/system/azcliloop.service
[Unit]
Description=Azcli Loop Service
After=network.target

[Service]
Type=simple
User=testrtmpuser
ExecStart=/bin/bash /testrtmp/azcliloop.sh
Restart=on-abort


[Install]
WantedBy=multi-user.target
EOF
}

#############################################################################
install_nginx_rtmp_service(){
/usr/local/nginx/sbin/nginx -s stop
cat <<EOF > /usr/local/nginx/html/player.html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Live Streaming</title>
    <link href="//vjs.zencdn.net/7.8.2/video-js.min.css" rel="stylesheet">
    <script src="//vjs.zencdn.net/7.8.2/video.min.js"></script>
    <script src="https://cdn.jsdelivr.net/npm/videojs-contrib-eme@3.7.0/dist/videojs-contrib-eme.min.js"></script>
</head>
<body>
<video id="player" class="video-js vjs-default-skin" height="360" width="640" controls preload="none">
    <source src="http://$1:8080/live/stream.m3u8" type="application/x-mpegURL" />
</video>
<script>
    var player = videojs('#player');
</script>
</body>
 <p>HOSTNAME: '$1'</p>
 <p>PORT_HTTP: 80 - URL: 'http://$1:80/player.html'</p>
 <p>PORT_SSL: 443 - URL: 'https://$1:443/player.html'</p>
 <p>PORT_RTMP: 1935 - URL: 'rtmp://$1:1935/live/stream'</p> 
 <p>PORT_HLS: 8080 - URL: 'http://$1:8080/live/stream.m3u8'</p>
 <p>PORT_RTSP: 8554 - URL: 'rtsp://$1:8554/rtsp/stream'</p> 
</html>
EOF


cat <<EOF > /usr/local/nginx/conf/nginx.conf
#user  nobody;
worker_processes  1;
error_log  /testrtmp/log/nginxerror.log debug;
events {
    worker_connections  1024;
}
http {
    include       mime.types;
    default_type  application/octet-stream;
    keepalive_timeout  65;
    tcp_nopush on;
#    aio on;
    directio 512;

    server {
        sendfile        on;
        listen       80;
        server_name  localhost;

        # rtmp stat
        location /stat {
            rtmp_stat all;
            rtmp_stat_stylesheet stat.xsl;
        }
        location /stat.xsl {
            # you can move stat.xsl to a different location
            root /usr/build/nginx-rtmp-module;
        }

        # rtmp control
        location /control {
            rtmp_control all;
        }

        error_page   500 502 503 504  /50x.html;
        location = /50x.html {
            root   html;
        }
    }
    server {
        sendfile        off;
        listen 8080;

        location /live {
            # Disable cache
            add_header 'Cache-Control' 'no-cache';

            # CORS setup
            add_header 'Access-Control-Allow-Origin' '*' always;
            add_header 'Access-Control-Expose-Headers' 'Content-Length';

            # allow CORS preflight requests
            if (\$request_method = 'OPTIONS') {
                add_header 'Access-Control-Allow-Origin' '*';
                add_header 'Access-Control-Max-Age' 1728000;
                add_header 'Content-Type' 'text/plain charset=UTF-8';
                add_header 'Content-Length' 0;
                return 204;
            }

            types {
                application/dash+xml mpd;
                application/vnd.apple.mpegurl m3u8;
                video/mp2t ts;
            }

            root /mnt/;
        }
    }
}

rtmp {
    server {
        listen 1935;
        ping 30s;
        notify_method get;
        buflen 5s;
        chunk_size 4000;

#        application live {
#            live on;
#            interleave on;
#        }
        application live {
            live on;
            interleave on;
            hls on;
            hls_path /mnt/live/;
            hls_fragment 3;
            hls_playlist_length 60;
            # disable consuming the stream from nginx as rtmp
            # deny play all;
        }
    }
}
EOF

install_nginxrtmp_service

}

install_nginx_rtmp_service_centos(){
systemctl stop nginx
mv /etc/nginx/nginx.conf /etc/nginx/nginx.conf.asli


cat <<EOF > /etc/nginx/html/player.html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Live Streaming</title>
    <link href="//vjs.zencdn.net/5.8/video-js.min.css" rel="stylesheet">
    <script src="//vjs.zencdn.net/5.8/video.min.js"></script>
</head>
<body>
<video id="player" class="video-js vjs-default-skin" height="360" width="640" controls preload="none">
    <source src="http://$1:8080/live/stream.m3u8" type="application/x-mpegURL" />
</video>
<script>
    var player = videojs('#player');
</script>
</body>
 <p>HOSTNAME: '$1'</p>
 <p>PORT_HTTP: 80 - URL: 'http://$1:80/player.html'</p>
 <p>PORT_SSL: 443 - URL: 'https://$1:443/player.html'</p>
 <p>PORT_RTMP: 1935 - URL: 'rtmp://$1:1935/live/stream'</p> 
 <p>PORT_HLS: 8080 - URL: 'http://$1:8080/live/stream.m3u8'</p>
 <p>PORT_RTSP: 8554 - URL: 'rtsp://$1:8554/rtsp/stream'</p> 
</html>
EOF

cat <<EOF > /etc/nginx/nginx.conf
#user  nobody;
worker_processes  1;
error_log  /testrtmp/log/nginxerror.log debug;
events {
    worker_connections  1024;
}
http {
    include       mime.types;
    default_type  application/octet-stream;
    keepalive_timeout  65;
    tcp_nopush on;
#    aio on;
    directio 512;

    server {
        sendfile        on;
        listen       80;
        server_name  localhost;

        # rtmp stat
        location /stat {
            rtmp_stat all;
            rtmp_stat_stylesheet stat.xsl;
        }
        location /stat.xsl {
            # you can move stat.xsl to a different location
            root /usr/build/nginx-rtmp-module;
        }

        # rtmp control
        location /control {
            rtmp_control all;
        }

        error_page   500 502 503 504  /50x.html;
        location = /50x.html {
            root   html;
        }
    }
    server {
        sendfile        off;
        listen 8080;

        location /live {
            # Disable cache
            add_header 'Cache-Control' 'no-cache';

            # CORS setup
            add_header 'Access-Control-Allow-Origin' '*' always;
            add_header 'Access-Control-Expose-Headers' 'Content-Length';

            # allow CORS preflight requests
            if (\$request_method = 'OPTIONS') {
                add_header 'Access-Control-Allow-Origin' '*';
                add_header 'Access-Control-Max-Age' 1728000;
                add_header 'Content-Type' 'text/plain charset=UTF-8';
                add_header 'Content-Length' 0;
                return 204;
            }

            types {
                application/dash+xml mpd;
                application/vnd.apple.mpegurl m3u8;
                video/mp2t ts;
            }

            root /mnt/;
        }
    }
}

rtmp {
    server {
        listen 1935;
        ping 30s;
        notify_method get;
        buflen 5s;
        chunk_size 4000;

#        application live {
#            live on;
#            interleave on;
#        }
        application live {
            live on;
            interleave on;
            hls on;
            hls_path /mnt/live/;
            hls_fragment 3;
            hls_playlist_length 60;
            # disable consuming the stream from nginx as rtmp
            # deny play all;
        }
    }
}
EOF

install_nginxrtmp_service

}






#############################################################################

environ=`env`
# Create folders
mkdir /git
mkdir /temp
mkdir /chunks
chmod +777 /chunks
mkdir /testrtmp
mkdir /testrtmp/log
chmod +777 /testrtmp/log
mkdir /testrtmp/config

# Write access in log subfolder
chmod -R a+rw /testrtmp/log
log "Environment before installation: $environ"

log "Installation script start : $(date)"
log "Net Core Installation: $(date)"
log "#####  azure_hostname: $azure_hostname"
log "#####  rtmp_path: $rtmp_path"
log "#####  storage_account: $storage_account"
log "#####  storage_container: $storage_container"
log "#####  storage_key: $storage_sas_token"
log "Installation script start : $(date)"
check_os
if [ $iscentos -ne 0 ] && [ $isredhat -ne 0 ] && [ $isubuntu -ne 0 ] && [ $isdebian -ne 0 ];
then
    log "unsupported operating system"
    exit 1 
else
	if [ $iscentos -eq 0 ] ; then
	    log "configure network centos"
		configure_network_centos
	    log "install git centos"
		install_git_centos
	elif [ $isredhat -eq 0 ] ; then
	    log "configure network redhat"
		configure_network_centos
	    log "install git redhat"
		install_git_centos
	elif [ $isubuntu -eq 0 ] ; then
	    log "configure network ubuntu"
		configure_network
	    log "install git ubuntu"
		install_git_ubuntu
	elif [ $isdebian -eq 0 ] ; then
	    log "configure network debian"
		configure_network
	    log "install git debian"
		install_git_ubuntu
	fi
	log "build ffmpeg nginx_rtmp azcli"
	if [ $iscentos -eq 0 ] ; then
	    log "build ffmpeg nginx_rtmp centos"
		install_ffmpeg_centos
		install_nginx_rtmp_centos
		install_rtsp
		install_azcli_centos
	elif [ $isredhat -eq 0 ] ; then
	    log "build ffmpeg nginx_rtmp redhat"
		install_ffmpeg_redhat
		install_nginx_rtmp_centos
		install_rtsp
		install_azcli_centos
	else
	    log "build ffmpeg nginx_rtmp debian ubuntu"
		install_ffmpeg
		install_nginx_rtmp
		install_rtsp
		install_azcli
	fi

	if [ $iscentos -eq 0 ] ; then
	    log "install ffmpeg nginx_rtmp azcli centos"
		install_ffmpeg_service_centos $rtmp_path
		install_nginx_rtmp_service_centos $azure_hostname
		install_rtsp_service
		install_ffmpegrtsp_service
        install_azcli_service_centos $storage_account  $storage_container   $storage_sas_token
	    log "Start nginx_rtmp service"
        systemctl stop nginx
        systemctl start nginx
	elif [ $isredhat -eq 0 ] ; then
	    log "install ffmpeg nginx_rtmp azcli redhat"
		install_ffmpeg_service_centos $rtmp_path
		install_nginx_rtmp_service_centos $azure_hostname
		install_rtsp_service
		install_ffmpegrtsp_service
        install_azcli_service_centos $storage_account  $storage_container   $storage_sas_token
	    log "Start nginx_rtmp service"
        systemctl stop nginx
        systemctl start nginx
	elif [ $isubuntu -eq 0 ] ; then
	    log "install ffmpeg nginx_rtmp azcli ubuntu"
		install_ffmpeg_service $rtmp_path
		install_nginx_rtmp_service $azure_hostname
		install_rtsp_service
        install_ffmpegrtsp_service
		install_azcli_service $storage_account  $storage_container   $storage_sas_token
	    log "Start nginx_rtmp service"
	    /usr/local/nginx/sbin/nginx -s stop
	    /usr/local/nginx/sbin/nginx
	elif [ $isdebian -eq 0 ] ; then
	    log "install ffmpeg nginx_rtmp azcli debian"
		install_ffmpeg_service $rtmp_path
		install_nginx_rtmp_service $azure_hostname
		install_rtsp_service
        install_ffmpegrtsp_service
		install_azcli_service $storage_account  $storage_container   $storage_sas_token
	    log "Start nginx_rtmp service"
	    /usr/local/nginx/sbin/nginx -s stop
	    /usr/local/nginx/sbin/nginx
	fi
	
    log "Start ffmpeg service"
	systemctl enable ffmpegloop.service
	systemctl start ffmpegloop.service 
    log "Start nginx rtmp service"
    systemctl enable nginxrtmploop.service
    systemctl start nginxrtmploop.service
    log "Start rtsp service"
    systemctl enable rtsploop.service
    systemctl start rtsploop.service
    log "Start ffmpegrtsp service"
    systemctl enable ffmpegrtsploop.service
    systemctl start ffmpegrtsploop.service
	log "Start azcli service"
	systemctl enable azcliloop.service
	systemctl start azcliloop.service 
	log "Installation successful, services nginx_rtmp, ffmpeg and azcli running"
fi
exit 0 

