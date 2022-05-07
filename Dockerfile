FROM debian:bullseye

RUN apt update && \
  apt install -y build-essential wget git \
  libgmp3-dev

# To build from sources, MLton requires an existing mlton
# compiler in the path to bootstrap itself.
# Download a pre-compiled one from Github - it only has to be sufficiently new.
WORKDIR /tmp
RUN wget https://github.com/MLton/mlton/releases/download/on-20210117-release/mlton-20210117-1.amd64-linux-glibc2.31.tgz \
         -O mlton.tgz && \
  mkdir mlton && \
  tar -xzf mlton.tgz --strip-components=1 --directory mlton
ENV PATH /tmp/mlton/bin:$PATH

WORKDIR /mlton

RUN git clone https://github.com/MLton/mlton.git . && \
  git checkout 625209f402e0a3d5f8c7012572df9a72ed1db651 && \
  make all -j && \
  make PREFIX=/opt/mlton install

FROM debian:bullseye
# MLton requires:
#   - a C compiler
#   - GMP (GNU Multiple Precision arithmetic library)
RUN apt update && apt install -y wget build-essential libgmp3-dev \
  lsb-release software-properties-common # LLVM dependencies.
# Install LLVM 15 - that is to test with MLton's LLVM backend.
RUN wget https://apt.llvm.org/llvm.sh && chmod +x llvm.sh && ./llvm.sh 15
COPY --from=0 /opt/mlton /opt/mlton
ENV PATH /opt/mlton/bin:$PATH
