server {
    listen       443 ssl http2;
    listen       [::]:443 ssl http2;
    server_name  registry.${SUBDOM}.${BASE_DOMAIN};

    add_header Strict-Transport-Security "max-age=31536000;";
    client_max_body_size 0;
    chunked_transfer_encoding on;

    location / {
        proxy_pass                          http://localhost:5000;
        proxy_set_header Host               $http_host;
        proxy_set_header X-Forwarded-For    $proxy_add_x_forwarded_for;
        proxy_set_header X-Real-IP          $remote_addr;
        proxy_set_header X-Forwarded-Proto  $scheme;
        proxy_read_timeout                  900;
        proxy_send_timeout                  300;
        proxy_buffering                     off;
        keepalive_timeout                   5 5;
        tcp_nodelay                         on;
    }
}
