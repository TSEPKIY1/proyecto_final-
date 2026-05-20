# Proyecto de Acondicionamiento - Listo para Railway

Este paquete ya está preparado para desplegarse en Railway.

## Archivos principales

- `data_base.py`: backend Flask y servidor del frontend.
- `public/`: HTML, CSS, JS e imágenes.
- `requirements.txt`: dependencias Python.
- `Procfile` y `railway.json`: arranque con Gunicorn.
- `database_schema_railway.sql`: script para crear tablas y rutinas en MySQL de Railway.
- `database_schema.sql`: script local que reinicia `control_militar`.

## Deploy en Railway

1. Sube esta carpeta a GitHub.
2. En Railway crea un proyecto nuevo desde ese repositorio.
3. Agrega un servicio MySQL al proyecto.
4. Railway generará variables como `MYSQLHOST`, `MYSQLPORT`, `MYSQLUSER`, `MYSQLPASSWORD` y `MYSQLDATABASE`. El backend ya las lee automáticamente.
5. Abre la consola/query del MySQL de Railway y ejecuta `database_schema_railway.sql`.
6. Genera dominio público para el servicio web.
7. Abre la URL pública.

## Uso local

```bash
pip install -r requirements.txt
mysql -u root -p < database_schema.sql
python data_base.py
```

Después abre:

```text
http://127.0.0.1:5000
```

## Nota

El proyecto sirve frontend y backend desde el mismo Flask. Por eso ya no necesita Live Server en Railway.
