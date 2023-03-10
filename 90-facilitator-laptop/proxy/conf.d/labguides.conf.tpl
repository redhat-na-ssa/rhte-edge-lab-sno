server {
    listen       443 ssl http2;
    listen       [::]:443 ssl http2;
    server_name  labguide.internal.${BASE_DOMAIN};

    location / {
        proxy_pass http://localhost:8080/;
        proxy_redirect off;
        proxy_set_header Host             $http_host;
        proxy_set_header X-Forwarded-For  $proxy_add_x_forwarded_for;
        proxy_set_header X-Real-IP        $remote_addr;
    }
}
