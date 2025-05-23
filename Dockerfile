FROM golang:1.23.3-alpine AS build
RUN mkdir /src
WORKDIR /src
COPY ./go.mod .
COPY ./go.sum .
COPY ./vendor .
COPY ./*.go ./
COPY ./internal ./internal
RUN GOOS=linux GOARCH=amd64 go build -o silly-demo
RUN chmod +x silly-demo

FROM scratch
ARG VERSION
ENV VERSION=$VERSION
ENV DB_PORT=5432 DB_USERNAME=postgres DB_NAME=silly-demo
COPY --from=build /src/silly-demo /usr/local/bin/silly-demo
EXPOSE 8080
CMD ["silly-demo"]
