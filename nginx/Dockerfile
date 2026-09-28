FROM nginx:alpine

COPY /pictures /usr/share/nginx/html/pictures
COPY /music /usr/share/nginx/html/music
COPY /index.html /usr/share/nginx/html/index.html

COPY /red /usr/share/nginx/html/red
COPY /blue /usr/share/nginx/html/blue

COPY stress-test.sh /usr/local/bin/stress-test.sh
RUN chmod +x /usr/local/bin/stress-test.sh
