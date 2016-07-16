#
# IMPORTANT... Before making changes to the NGINX configuration:
#
# Always make changes to nginx.conf.tpl, NOT nginx.conf.
# nginx.conf is generated each time the container is started, or when backend
# servers change.  If you modify the template, you'll need to restart the container
# before your changes will have an effect.
#

working_directory %(VAR_DIR);

# Interestingly, Nginx will attempt to write to /tmp/error.log no matter WHAT you do, so
# check there if you are having startup problems, but the following should at least assure
# that things go to syslog whenever Nginx deems fit.
error_log syslog:server=unix:/dev/log;

pid %(NGINX_PID_FILE);

events {
       worker_connections 768;
}

http {
     client_max_body_size  8M;

     client_body_temp_path %(VAR_DIR)/nginx_temp/client;
     proxy_temp_path       %(VAR_DIR)/nginx_temp/proxy;
     fastcgi_temp_path     %(VAR_DIR)/nginx_temp/fastcgi_temp;
     scgi_temp_path        %(VAR_DIR)/nginx_temp/scgi_temp;
     uwsgi_temp_path       %(VAR_DIR)/nginx_temp/uwsgi_temp;

     upstream lb_backend {
         sticky name=AWSLB_route no_fallback %(SSL_BACK:|true|secure|);
%(NGINX_SERVER_LIST)
     }

     access_log %(NGINX_LOG_DIR)/access.log;

     server {
%(SSL_FRONT:|true|
	 listen 8443 ssl;
	 ssl on;
	 ssl_certificate          %(VAR_DIR)/nginx_ssl/server.crt;
	 ssl_certificate_key      %(VAR_DIR)/nginx_ssl/server.key;
	 ssl_trusted_certificate  %(VAR_DIR)/nginx_ssl/ca-certs.pem;
|
	listen 8080;
)
	 location / {
	 	 proxy_pass %(SSL_BACK:|true|https|http)://lb_backend;
         }
     }

%(HTTP_REDIRECT:|true|
     server {
        listen 8080 default_server;
	server_name _;
	return 301 https://$host$request_uri;
    }
|)
}
