FROM concourse/buildroot:curl

ARG JFROG_CLI_VERSION

ADD assets/ /opt/resource/
ADD test/ /opt/resource-tests/
ADD tools/ /opt/tools/

RUN rm /usr/bin/jq
RUN mv /opt/tools/jq /usr/bin/jq

RUN curl -L -o /usr/bin/jfrog https://jfrog.bintray.com/jfrog-cli-go/$JFROG_CLI_VERSION/jfrog-cli-linux-amd64/jfrog
RUN chmod +x /usr/bin/jfrog

# Run tests
# RUN /opt/resource-tests/test-check.sh
# RUN /opt/resource-tests/test-in.sh
# RUN /opt/resource-tests/test-out.sh
