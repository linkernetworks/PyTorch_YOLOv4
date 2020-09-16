# from https://github.com/linkernetworks/template-python-project/blob/master/Makefile
PYTHON := $$(which python3)
PIP := $(PYTHON) -m pip
PY_DIRS = inference models utils
PY_SCRIPTS := $$(grep -ERIl '^\#!.+python' $(PY_DIRS) | grep -Ev '**/*.py')
PY_FILES := $$(find $(PY_DIRS) -name '*.py' | grep -v '\./\.') $(PY_SCRIPTS) setup.py
CUR_DIR = $(shell echo "${PWD}")
IMAGE_NAME = linkermetrics
TEST_IMAGE_NAME = linkermetrics-test
HUB_NAMESPACE = xiebaoyun.synology.me:6088
VERSION = 0.0
DOCKER_FILE_DIR = "docker"
DOCKERFILE = "${DOCKER_FILE_DIR}/Dockerfile"
TESTDOCKERFILE = "${DOCKER_FILE_DIR}/Dockerfiletest"

.PHONY: dev install install-dep install-dev format test unit-test format-test

install-dep:
	@$(PIP) install numpy
	@$(PIP) install -r requirements.txt

install-dev:
	@$(PIP) install -r requirements-dev.txt

install: install-dep
	@$(PYTHON) setup.py install
	@echo "Dependes installation finished\n"

dev: install-dep
	@$(PIP) install -e .

format: setup.cfg
	@isort -q -rc -sp $< $(PY_DIRS)
	@yapf -i -r --style $< $(PY_DIRS)

test: format-test unit-test

unit-test:
	@echo "Pytest Testing..."
	@pytest -vv -s
	@echo "Pytest Testing passed\n"

format-test: setup.cfg
	@echo "Format Testing..."
	@flake8 --config=$< $(PY_FILES)
	@isort -rc --check-only -sp $< $(PY_DIRS)
	@yapf -d -r --style $< $(PY_DIRS)
	@echo "Format Testing passed\n"

#################################
# Docker targets
#################################
.PHONY: clean-image
clean-image:
	@echo "+ $@"
	@docker rmi ${HUB_NAMESPACE}/${IMAGE_NAME}:latest  || true
	@docker rmi ${HUB_NAMESPACE}/${IMAGE_NAME}:${VERSION}  || true
	@docker rmi ${HUB_NAMESPACE}/${TEST_IMAGE_NAME}  || true

.PHONY: image
image:
	@echo "+ $@"
	@docker build -t ${HUB_NAMESPACE}/${IMAGE_NAME}:${VERSION} -f ./${DOCKERFILE} .
	@docker tag ${HUB_NAMESPACE}/${IMAGE_NAME}:${VERSION} ${HUB_NAMESPACE}/${IMAGE_NAME}:latest
	@echo 'Done.'
	@docker images --format '{{.Repository}}:{{.Tag}}\t\t Built: {{.CreatedSince}}\t\tSize: {{.Size}}' | \
		grep ${IMAGE_NAME}:${VERSION}

.PHONY: test-image
test-image:
	@echo "+ $@"
	@docker build -t ${HUB_NAMESPACE}/${TEST_IMAGE_NAME} -f ./${TESTDOCKERFILE} .
	@echo 'Done.'
	@docker images --format '{{.Repository}}:{{.Tag}}\t\t Built: {{.CreatedSince}}\t\tSize: {{.Size}}' | \
		grep ${TEST_IMAGE_NAME}

#################################
# test targets in docker
#################################



.PHONY: docker-format
docker-format: test-image
	@echo "+ $@"
	@docker run --rm  --name linkermetrics-format -v ${CUR_DIR}:/workspace ${HUB_NAMESPACE}/${TEST_IMAGE_NAME} make format

.PHONY: docker-test
docker-test: test-image
	@echo "+ $@"
	@docker run --rm  --name linkermetrics-test  ${HUB_NAMESPACE}/${TEST_IMAGE_NAME} make test

format-and-test: install format  test

.PHONY: docker-pushhook
docker-pushhook: test-image
	@echo "+ $@"
	@docker run --rm  --name linkermetrics-format -v ${CUR_DIR}:/workspace ${HUB_NAMESPACE}/${TEST_IMAGE_NAME} make format-and-test
