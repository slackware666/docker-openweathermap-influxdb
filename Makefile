ROOT_DIR="$(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))/"
BUNDLER_VERSION=1.17.3
IMAGE=openweathermap-influxdb
REGISTRY=registry:5000

all: build publish

build:
	gem install bundler -v ${BUNDLER_VERSION}
	bundle _${BUNDLER_VERSION}_ install
	docker build -t ${IMAGE} .

clean:
	rm Gemfile.lock
	docker rmi ${IMAGE}

publish:
	docker tag ${IMAGE} ${REGISTRY}/${IMAGE}
	docker push ${REGISTRY}/${IMAGE}