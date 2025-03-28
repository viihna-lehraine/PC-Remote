# File: nginx/Dockerfile

FROM nginx:stable-alpine

# remove default configuration
RUN rm /etc/nginx/conf.d/default.conf

# copy custom configuration
COPY conf.d/ /etc/nginx/conf.d/
