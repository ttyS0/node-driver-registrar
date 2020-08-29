FROM --platform=$BUILDPLATFORM golang:1.15.0 AS builder
ARG TARGETPLATFORM
ARG BUILDPLATFORM

WORKDIR /code
ADD . /code/

RUN cd /code/ && GOARCH=$(echo $TARGETPLATFORM | cut -f2 -d '/') go build -a -ldflags '-X main.version=v2.0.0-0-g74cddc9a -extldflags "-static"' -o ./bin/csi-node-driver-registrar ./cmd/csi-node-driver-registrar

FROM gcr.io/distroless/static:latest
LABEL maintainers="Kubernetes Authors"
LABEL description="CSI Node driver registrar"

COPY --from=builder /code/bin/csi-node-driver-registrar csi-node-driver-registrar
ENTRYPOINT ["/csi-node-driver-registrar"]
