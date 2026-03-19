# syntax=docker/dockerfile:1
FROM --platform=linux/amd64 almalinux:9 AS builder

RUN dnf install -y epel-release \
    && dnf config-manager --set-enabled crb \
    && dnf install -y \
        cmake \
        gcc-c++ \
        git \
        boost-devel \
        python3 \
        python3-devel \
        python3-pip \
        fmt-devel \
        protobuf-devel \
        abseil-cpp-devel \
    && dnf clean all

RUN python3 -m pip install --upgrade pip && \
    python3 -m pip install "scikit-build-core>=0.9" "pybind11>=2.11" ninja build

WORKDIR /src

# cpp_packages submodules must be checked out on the host before building:
#   git submodule update --init
COPY .gitmodules pyproject.toml CMakeLists.txt ./
COPY cpp_packages/ ./cpp_packages/
COPY pydunedaqfmt/ ./pydunedaqfmt/

RUN python3 -m build --wheel --no-isolation --outdir /dist

# ── Final stage ───────────────────────────────────────────────────────────────
FROM --platform=linux/amd64 almalinux:9 AS final

RUN dnf install -y python3 python3-pip && dnf clean all

COPY --from=builder /dist/*.whl /wheels/
RUN python3 -m pip install --no-index --find-links /wheels pydunedaqfmt \
    && rm -rf /wheels

# Smoke tests
RUN python3 -c "import detdataformats; print('detdataformats OK:', detdataformats.DetID())" && \
    python3 -c "import daqdataformats;  print('daqdataformats  OK:', daqdataformats.SourceID())" && \
    python3 -c "import trgdataformats;  print('trgdataformats  OK')" && \
    python3 -c "import fddetdataformats; print('fddetdataformats OK')"
