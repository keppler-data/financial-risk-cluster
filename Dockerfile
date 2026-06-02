# 1. IMAGEN BASE
FROM apache/airflow:3.2.0-python3.12

# 2. CAMBIO DE USUARIO A ROOT
USER root

# 3. INSTALAR DEPENDENCIAS DE SISTEMA (C/C++)
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    libpq-dev \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# 4. VOLVER AL USUARIO AIRFLOW
USER airflow

# 5. BLINDAJE DEL PATH: Obligamos al contenedor a usar los binarios del usuario airflow
ENV PATH="/home/airflow/.local/bin:${PATH}"

# 6. ARGUMENTOS DE CONSTRUCCIÓN (Obligatorio declararlo antes de usarlo)
ARG EXTRA_REQUIREMENTS=""

# 7. INSTALAR LIBRERÍAS CORE + REQUISITOS EXTRA
# Nota: Pasamos directamente las variables core y concatenamos el ARG de forma segura.
# Usar la sintaxis ${EXTRA_REQUIREMENTS} asegura que Docker reemplace el valor correctamente aquí.
RUN pip install --no-cache-dir \
    gunicorn \
    psycopg2-binary \
    ${EXTRA_REQUIREMENTS}

# 7. DIRECTORIO DE TRABAJO
WORKDIR /opt/airflow