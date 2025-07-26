# -------------------------------------------------------------------
# HTTPS server block
# -------------------------------------------------------------------
server {
    listen       443 ssl;
    server_name  lavra-dicentis.com;

    server_tokens off;
    client_max_body_size 1m;

    access_log   /var/log/nginx/lavra-dicentis.com_access.log;
    error_log    /var/log/nginx/lavra-dicentis.com_error.log;

    root /var/www/lavra-dicentis.com/public;

    # exactly "/" → serve index.html
    location = / {
        limit_except GET HEAD { deny all; }
        try_files /index.html =404;
    }

    # exactly "/favicon.ico"
    location = /favicon.ico {
        limit_except GET HEAD { deny all; }
        try_files /favicon.ico =404;
        access_log off;
        log_not_found off;
    }

    # anything else → 404
    location / {
        return 404;
    }

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
