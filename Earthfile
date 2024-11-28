VERSION 0.8
FROM ghcr.io/vfarcic/silly-demo-earthly:0.0.5
ARG --global registry=ghcr.io/vfarcic
ARG --global user=vfarcic
ARG --global image=idp-full-demo
WORKDIR /go-workdir

binary:
    COPY go.mod go.sum vendor .
    COPY *.go .
    RUN go mod vendor
    RUN GOOS=linux GOARCH=amd64 go build --mod vendor -o silly-demo
    SAVE ARTIFACT silly-demo

image:
    BUILD +binary
    ARG tag='latest'
    ARG taglatest='latest'
    ARG base='scratch'
    FROM $base
    ENV DB_PORT=5432 DB_USERNAME=postgres DB_NAME=silly-demo
    EXPOSE 8080
    CMD ["silly-demo"]
    ENV VERSION=$tag
    COPY +binary/silly-demo /usr/local/bin/silly-demo
    SAVE IMAGE --push \
        $registry/$image:$tag \
        $registry/$image:$taglatest

gitops:
    ARG --required tag
    COPY apps apps
    RUN yq --inplace ".spec.parameters.image = \"$registry/$image:$tag\"" apps/silly-demo.yaml
    SAVE ARTIFACT apps/silly-demo.yaml AS LOCAL apps/silly-demo.yaml

all:
    ARG tag
    WAIT
        BUILD +image --tag $tag --taglatest latest
    END
    BUILD +gitops --tag $tag

