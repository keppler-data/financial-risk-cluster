# 🤖 CONTEXTO DE INFRAESTRUCTURA PARA ASISTENTES DE IA

> **INSTRUCCIÓN DE SISTEMA PARA IA:** 
> Estás trabajando en un clúster distribuido en AWS. Al generar código (DAGs de Airflow, Scripts de Python o Jobs de Spark) para el repositorio `data-platform`, **debes acatar estrictamente las siguientes reglas arquitectónicas y limitaciones**. No asumas una infraestructura local estándar.

---

## 1. Topología del Clúster y Limitaciones Físicas
- **Workers de Airflow (Celery):** Son instancias EC2 muy pequeñas (`2 Cores`, `4GB RAM`).
- **Límite de Concurrencia:** Cada worker solo ejecuta un máximo de 4 tareas simultáneas.
- **🚨 REGLA CRÍTICA DE MEMORIA:** NO escribas código con `Pandas` que cargue datasets masivos en la memoria de un `PythonOperator`. Si la transformación es pesada, **debes externalizarla a Spark** o usar sentencias ELT directas en bases de datos (ej. dbt o SQL nativo). Si causas un OOM (Out Of Memory), el clúster se caerá.
- **Colas Disponibles:** Al crear DAGs, puedes enrutar tareas usando `queue='default'`, `queue='etl'`, o `queue='elt'`.

## 2. Entorno y Rutas de Archivos (El "Mapeo")
El código vive en un repositorio externo llamado `data-platform`, pero los contenedores lo ven de la siguiente manera:
- **Directorio de DAGs:** `/opt/airflow/dags/` (Aquí solo deben ir las declaraciones del DAG).
- **Directorio de Lógica (Pipelines):** `/opt/airflow/pipelines/` (Aquí deben ir las tareas de Celery, scripts, SQL, etc.).
- **PYTHONPATH:** `/opt/airflow/pipelines` está inyectado en el `PYTHONPATH`. 
- **🚨 REGLA CRÍTICA DE IMPORTACIÓN:** Puedes importar módulos directamente desde la raíz de `pipelines/` sin rutas relativas complejas. Por ejemplo: `from tasks.my_task import process_data`.
- **Regla del DAG Processor:** NUNCA coloques archivos de código que no sean DAGs (ej. scripts auxiliares, JSON, CSV) dentro de la carpeta `dags/`. Esto sobrecarga el `DagProcessor` de Airflow 3. Ponlos en subcarpetas de `pipelines/`.

## 3. Apache Spark 4.x
- **Versión:** `4.0.2-java21-python3`.
- **Rutas de Spark:** Los contenedores de Spark tienen montada la carpeta de código en `/opt/spark/pipelines/`.
- **Lanzamiento de Jobs (Spark Submit):** Dado que los contenedores de Airflow no tienen los binarios de Spark instalados internamente, **NUNCA uses el `SparkSubmitOperator`**. Todos los jobs de Spark deben lanzarse utilizando el **`SSHOperator`**, conectándose por SSH al nodo Master (`21.0.2.203`) y ejecutando el comando `spark-submit` directamente en la terminal remota de esa máquina.
- **Asignación de Recursos:** Los Spark Workers tienen asigandos `3G` de RAM y `2` Cores. No escribas Jobs que exijan más recursos por ejecutor de lo que el worker puede ofrecer.

## 4. Integración AWS (IAM y Seguridad)
- **Cero Credenciales Hardcodeadas:** Las instancias EC2 operan bajo un Rol de IAM nativo con acceso total a S3, Athena y Glue. 
- **🚨 REGLA CRÍTICA DE AWS:** AL ESCRIBIR CÓDIGO BOTO3 O HOOKS DE AIRFLOW, NUNCA pidas, inyectes o uses `AWS_ACCESS_KEY_ID` ni `AWS_SECRET_ACCESS_KEY`. Usa `boto3.client('s3')` vacío o Hooks con `conn_id` configurados para usar el rol por defecto (ej. `aws_default`).
- **Logs de Airflow:** Se envían automáticamente a `s3://logs-kepper/logs/`. No necesitas configurar loggers personalizados en el código para atrapar los prints, `stdout` ya está ruteado a S3.

## 5. Gestión de Conexiones a Bases de Datos
- Las EC2 utilizan PostgreSQL.
- Se configuró un reciclaje de piscina (`pool_recycle=1200`) a nivel infraestructura.
- Si abres una conexión de base de datos desde un script de Python nativo (`psycopg2` o `SQLAlchemy`), **asegúrate siempre de cerrarla al finalizar** (usa bloques `with` o bloques `try...finally`). Si dejas sesiones dormidas, bloquearás los workers.

---
**FIN DEL CONTEXTO:** Usa esta información como base inamovible para proponer soluciones, escribir código o depurar errores para este usuario.
