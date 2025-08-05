# syntax=docker/dockerfile:1
# Usar digest fijo en vez de latest (cámbialo por uno que funcione en tu máquina)
FROM quay.io/unstructured-io/base-images:wolfi-base@sha256:c92bb68337824ff09685d698306bc5e12b825e061f90f6b97cd0bffa58d0dbc7 as base

# Variables y configuración inicial
ARG NB_USER=notebook-user
ARG NB_UID=1000
ARG PIP_VERSION
ARG PIPELINE_PACKAGE
ARG PYTHON_VERSION="3.12"

ENV PYTHON python${PYTHON_VERSION}
ENV PIP ${PYTHON} -m pip
ENV PYTHONPATH="${PYTHONPATH}:${HOME}"
ENV PATH="/home/${NB_USER}/.local/bin:${PATH}"

WORKDIR ${HOME}
USER ${NB_USER}

# Etapa para instalar dependencias de Python
FROM base as python-deps
COPY --chown=${NB_USER}:${NB_USER} requirements/base.txt requirements-base.txt
RUN ${PIP} install --upgrade pip \
 && ${PIP} install --no-cache -r requirements-base.txt

# Etapa de código y configuración
FROM python-deps as code
COPY --chown=${NB_USER}:${NB_USER} CHANGELOG.md CHANGELOG.md
COPY --chown=${NB_USER}:${NB_USER} logger_config.yaml logger_config.yaml
COPY --chown=${NB_USER}:${NB_USER} exploration-notebooks exploration-notebooks
COPY --chown=${NB_USER}:${NB_USER} scripts/app-start.sh scripts/app-start.sh

# Usar script de arranque que descargará modelos al inicio (runtime, no en build)
# Esto reduce el peso de la imagen y evita timeouts
ENTRYPOINT ["scripts/app-start.sh"]

# Railway asigna un puerto con la variable $PORT
EXPOSE 8000
