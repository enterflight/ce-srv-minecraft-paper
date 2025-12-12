FROM ghcr.io/enterflight/ce-srv-minecraft-core:main AS build

RUN microdnf install git -y

RUN git config --global user.name "Enterflight Game Services"
RUN git config --global user.email "engineering@enterflight.xyz"

WORKDIR /tmp

RUN git clone https://github.com/PaperMC/Paper.git
WORKDIR /tmp/Paper

RUN /bin/bash /tmp/Paper/gradlew applyPatches
RUN /bin/bash /tmp/Paper/gradlew createMojmapBundlerJar

FROM ghcr.io/enterflight/ce-srv-minecraft-core:main AS final

RUN mkdir /opt/minecraft
COPY --from=build /tmp/Paper/paper-server/build/libs/paper-server-1.21.11-R0.1-SNAPSHOT.jar /opt/minecraft/server.jar
WORKDIR /opt/minecraft