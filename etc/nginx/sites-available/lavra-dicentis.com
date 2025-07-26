# -------------------------------------------------------------------
# HTTPS server block
# -------------------------------------------------------------------
server {
    listen       443 ssl;
    server_name  lavra-dicentis.com;

    # Hide nginx version
    server_tokens off;

    root         /var/www/lavra-dicentis.com/public;
    index        index.html;

    # Limit request size
    client_max_body_size 1m;


    access_log   /var/log/nginx/lavra-dicentis.com_access.log;
    error_log    /var/log/nginx/lavra-dicentis.com_error.log;

    # Only allow GET/HEAD and block all other methods
    location / {
        limit_except GET HEAD { deny all; }

        # Hide '.html' in URLs, but serve .html files
        try_files $uri $uri.html $uri/;
        autoindex off;
    }

    # SSL configuration (Certbot managed)
    ssl_certificate           /etc/letsencrypt/live/lavra-dicentis.com/fullchain.pem;
    ssl_certificate_key       /etc/letsencrypt/live/lavra-dicentis.com/privkey.pem;
    include                   /etc/letsencrypt/options-ssl-nginx.conf;
    ssl_dhparam               /etc/letsencrypt/ssl-dhparams.pem;
}

# -------------------------------------------------------------------
# HTTP → HTTPS redirect
# -------------------------------------------------------------------
server {
    listen      80;
    server_name lavra-dicentis.com;

    # Redirect all traffic to HTTPS
    return 301 https://$host$request_uri;
}

# -------------------------------------------------------------------
# Redirect www.lavra-dicentis.com → lavra-dicentis.com
# -------------------------------------------------------------------
server {
    listen       80;
    server_name  www.lavra-dicentis.com;

    return 301 https://lavra-dicentis.com$request_uri;
}

server {
    listen       443 ssl;
    server_name  www.lavra-dicentis.com;

    ssl_certificate           /etc/letsencrypt/live/www.lavra-dicentis.com/fullchain.pem;
    ssl_certificate_key       /etc/letsencrypt/live/www.lavra-dicentis.com/privkey.pem;
    include                   /etc/letsencrypt/options-ssl-nginx.conf;
    ssl_dhparam               /etc/letsencrypt/ssl-dhparams.pem;

    return 301 https://lavra-dicentis.com$request_uri;
}
