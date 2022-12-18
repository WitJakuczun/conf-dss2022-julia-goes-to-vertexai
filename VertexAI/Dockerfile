FROM julia:1.8.2-bullseye as julia

FROM --platform=linux/amd64 python:3.9-slim-buster as python
ENV JULIA_GPG=3673DF529D9049477F76B37566E3C7DC03D6E495 \
    JULIA_PATH=/usr/local/julia \
    JULIA_VERSION=1.8.2
ENV PATH="${JULIA_PATH}/bin:${PATH}"


COPY --from=julia /usr/local/julia /usr/local/julia

#Build Julia proj dependencies
RUN mkdir -p /opt/UnitCommitment
COPY UnitCommitment/*.toml /opt/UnitCommitment/
RUN julia --project=/opt/UnitCommitment --eval "import Pkg; Pkg.instantiate()"

#Build python dependencies
COPY requirements.txt /opt/
RUN pip install --no-cache-dir -r /opt/requirements.txt

#Build PyCall with proper python
RUN julia --project=/opt/UnitCommitment --eval "ENV[\"PYTHON\"] = Sys.which(\"python\"); using Pkg; Pkg.build(\"PyCall\")"

# Copy py and jl scripts
COPY UnitCommitment/*.jl /opt/UnitCommitment/
COPY UnitCommitment/*.sh /opt/UnitCommitment/
COPY UnitCommitment/src /opt/UnitCommitment/src/
COPY UnitCommitment/*.jmd /opt/UnitCommitment/

WORKDIR /opt
