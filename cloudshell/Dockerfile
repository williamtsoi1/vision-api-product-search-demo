#FROM node:latest AS node_base

#RUN echo "NODE Version:" && node --version
#RUN echo "NPM Version:" && npm --version

FROM gcr.io/cloudshell-images/cloudshell:cloud-shell-v20201208

#COPY --from=node_base . .

ENV TERRAFORM_VERSION="0.14.4"

WORKDIR /tmp

RUN curl https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip > terraform_${TERRAFORM_VERSION}_linux_amd64.zip && \
    unzip -o terraform_${TERRAFORM_VERSION}_linux_amd64.zip -d /usr/local/bin && \
    rm -f terraform_${TERRAFORM_VERSION}_linux_amd64.zip