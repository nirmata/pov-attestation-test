FROM alpine:3.20

ARG IMAGE_TYPE=signed
ENV IMAGE_TYPE=${IMAGE_TYPE}

WORKDIR /app

CMD ["sh", "-c", "echo 'gh-annotation-test image built from $GITHUB_SHA (type: $IMAGE_TYPE)'"]


