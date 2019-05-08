
-include ../Docker.mak

ifndef NAMESPACE
NAMESPACE = mkovac
endif
NAME = ${NAMESPACE}/$(shell basename $(shell readlink -e . ) )
VERSION = $(shell date +%Y%m%d)

.PHONY: all
all: latest

.PHONY: build
build:
	rm -f dpkg-new.txt
	docker build --rm -t $(NAME):$(VERSION) \
	 ${DOCKER_BUILD_FLAGS} \
	 --build-arg CACHE_DATE=$(shell date +%Y-%m-%d) \
	 --build-arg "ftp_proxy=${ftp_proxy}" \
	 --build-arg "http_proxy=${http_proxy}" \
	 --build-arg "https_proxy=${https_proxy}" \
	 .
	docker run --rm $(NAME):$(VERSION) dpkg -l > dpkg-new.txt

.PHONY: latest
latest: build
	docker tag $(NAME):$(VERSION) $(NAME):latest
	diff dpkg-new.txt dpkg.txt 2>&1 >/dev/null && { \
	  docker image rm $(NAME):$(VERSION); \
	} || { \
	  ( sed -e s/=NAMESPACE=/${NAMESPACE}/g README.in; \
	    sed -e 's/^/    /' dpkg-new.txt ) > README.md; \
	  git add README.md; \
          git commit -nm "package updates on  ${VERSION}"; \
          git push; \
        }

.PHONY: push
push: latest
	docker push $(NAME):latest

.PHONY: daily
daily:
	count="$(shell docker run --rm -ti ${NAME} bash -c "apt-get update -q -q && apt list -q -q --upgradable 2>/dev/null | wc -l")" && \
	 test $$count -eq 0 || make latest

.PHONY: show-updates
show-updates:
	docker run --rm -ti ${NAME} bash -c "apt-get update -q -q && apt list -q -q --upgradable"
