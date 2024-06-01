FROM postgres:latest

# Installiere locale und locales-Paket
RUN apt-get update && apt-get install -y locales

# Füge die gewünschten Locales zu /etc/locale.gen hinzu
RUN echo "de_DE.UTF-8 UTF-8" >> /etc/locale.gen && \
    echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen

# Generiere die Locales
RUN locale-gen


