# Use Ubuntu 22.04 as base image
FROM ubuntu:22.04

LABEL maintainer="Todi Adiyatmo <todiadiyatmo@gmail.com>"
LABEL org.label-schema.schema-version="1.0.0"
LABEL org.label-schema.vendor="Tongkolspace"
LABEL org.label-schema.name="nginx-ee"


# Install wget and curl (necessary for the script)
RUN apt-get update && apt-get install -y wget curl  software-properties-common iputils-ping wget nano\
    && add-apt-repository ppa:wordops/nginx-wo -uy \
    && apt install nginx-custom nginx-wo -y \
    # Run the Nginx installation script
    # Note: This script should be carefully reviewed before execution
    # to ensure it meets your security and configuration requirements.
    # RUN bash -c "bash <(wget -qO - vtb.cx/nginx-ee || curl -sL vtb.cx/nginx-ee)"
   && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* 

# Expose ports 80 and 443 for HTTP and HTTPS traffic
EXPOSE 80 443

# Set the default command to start Nginx in the foreground
CMD ["nginx", "-g", "daemon off;"]
