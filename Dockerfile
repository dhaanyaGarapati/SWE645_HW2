FROM busybox:stable

WORKDIR /www

COPY survey.html /www/survey.html
COPY survey.html /www/index.html

EXPOSE 8080

CMD ["sh", "-c", "httpd -f -p 8080 -h /www"]
