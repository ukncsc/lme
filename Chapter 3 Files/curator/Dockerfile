FROM alpine:3.7

RUN apk --no-cache add python py-setuptools py-pip gcc libffi py-cffi python-dev libffi-dev py-openssl musl-dev linux-headers openssl-dev libssl1.0 && \
    pip install elasticsearch-curator && \
    pip install boto3 && \
    pip install requests-aws4auth && \
    pip install cryptography



ADD curator.yml /root/.curator/curator.yml
ADD actions.yml /etc/curator/actions.yml
CMD ["/usr/bin/curator", "/etc/curator/actions.yml"]
