# Tiny base image with a built-in web server (NOT nginx, NOT node)
FROM busybox:stable

# Where we'll serve files from
WORKDIR /www

# Copy your single page; also provide it as index.html for "/"
COPY survey.html /www/survey.html
COPY survey.html /www/index.html

# We'll serve on port 8080 inside the container
EXPOSE 8080

# Run busybox httpd in the foreground (-f), port 8080, serving /www
CMD ["sh", "-c", "httpd -f -p 8080 -h /www"]
