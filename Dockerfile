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
COPY --from=build /tmp/Paper/paper-server/build/libs/paper-bundler-*-mojmap.jar /opt/minecraft/server.jar

COPY scripts/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

WORKDIR /data

# Define the entrypoint
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

# Default command (can be empty since entrypoint handles it, 
# but good practice to leave CMD empty or as arguments to entrypoint)
CMD []
