server {
    listen       443 ssl http2;
    listen       [::]:443 ssl http2;
    server_name  labguide.${SUBDOM}.${BASE_DOMAIN};

    location / {
        auth_basic "Restricted";
        auth_basic_user_file /etc/nginx/.htpasswd;
        proxy_pass http://localhost:8080/;
        proxy_redirect off;
        proxy_set_header Host             $http_host;
        proxy_set_header X-Forwarded-For  $proxy_add_x_forwarded_for;
        proxy_set_header X-Real-IP        $remote_addr;
    }
}
