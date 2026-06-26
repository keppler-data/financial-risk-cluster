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

# 6. COPIAR Y EJECUTAR REQUIREMENTS
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# 7. DIRECTORIO DE TRABAJO
WORKDIR /opt/airflow