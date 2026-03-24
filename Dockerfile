# syntax=docker/dockerfile:1

FROM golang:1.26 AS build

WORKDIR /src

COPY go.mod go.sum ./
RUN go mod download

COPY . ./
RUN CGO_ENABLED=0 GOOS=linux go build -o bin/

FROM gcr.io/distroless/static-debian12

COPY --from=build /src/bin/* /

ENTRYPOINT ["/go-nsupdate"]
