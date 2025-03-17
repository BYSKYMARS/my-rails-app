# Usar una imagen base de Ubuntu
FROM ubuntu:24.04

# Instalar dependencias necesarias
RUN apt-get update && apt-get install -y \
    curl \
    git \
    build-essential \
    libssl-dev \
    libreadline-dev \
    zlib1g-dev \
    libyaml-dev \
    libxml2-dev \
    libxslt1-dev \
    libffi-dev \
    libgdbm-dev \
    libncurses5-dev \
    libtool \
    libpq-dev \ 
    nodejs \     
    npm \        
    && rm -rf /var/lib/apt/lists/*

# Instalar rbenv y ruby-build
RUN git clone https://github.com/rbenv/rbenv.git ~/.rbenv
RUN git clone https://github.com/rbenv/ruby-build.git ~/.rbenv/plugins/ruby-build
RUN echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.bashrc
RUN echo 'eval "$(rbenv init -)"' >> ~/.bashrc
ENV PATH="/root/.rbenv/shims:/root/.rbenv/bin:$PATH"

# Instalar una versión específica de Ruby
RUN rbenv install 3.2.2 && rbenv global 3.2.2

# Instalar Bundler y Rails
RUN gem install bundler rails

# Crear un directorio para la aplicación
WORKDIR /myapp

# Exponer el puerto 3000 para Rails
EXPOSE 3000

# Comando por defecto al iniciar el contenedor
CMD ["bash"]