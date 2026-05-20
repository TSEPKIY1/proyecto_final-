import os
from datetime import date, datetime, timedelta
from pathlib import Path

from flask import Flask, jsonify, request, send_from_directory, session
from flask_cors import CORS
import mysql.connector
from mysql.connector import IntegrityError

BASE_DIR = Path(__file__).resolve().parent
PUBLIC_DIR = BASE_DIR / "public"

app = Flask(__name__)
app.secret_key = os.getenv("SECRET_KEY", "cambia_esta_clave_en_railway")

app.config["PERMANENT_SESSION_LIFETIME"] = 3600
app.config["SESSION_COOKIE_SAMESITE"] = "Lax"
app.config["SESSION_COOKIE_HTTPONLY"] = True
app.config["SESSION_COOKIE_SECURE"] = os.getenv("SESSION_COOKIE_SECURE", "false").lower() == "true"

# En producción el frontend y el backend se sirven desde el mismo dominio.
# CORS queda abierto solo para desarrollo local o pruebas controladas.
CORS(app, supports_credentials=True)


def get_db_config():
    """Config compatible con Railway MySQL y con entorno local."""
    return {
        "host": os.getenv("MYSQLHOST") or os.getenv("DB_HOST") or "localhost",
        "port": int(os.getenv("MYSQLPORT") or os.getenv("DB_PORT") or 3306),
        "user": os.getenv("MYSQLUSER") or os.getenv("DB_USER") or "root",
        "password": os.getenv("MYSQLPASSWORD") or os.getenv("DB_PASSWORD") or "1234",
        "database": os.getenv("MYSQLDATABASE") or os.getenv("DB_NAME") or "control_militar",
        "autocommit": False,
    }


def get_db():
    return mysql.connector.connect(**get_db_config())


def calcular_rango(puntos):
    puntos = int(puntos or 0)
    if puntos < 80:
        return "Recluta"
    if puntos < 160:
        return "Cadete"
    if puntos < 260:
        return "Soldado"
    if puntos < 380:
        return "Operador"
    return "Elite"


def usuario_actual(cursor):
    cursor.execute(
        """
        SELECT id, email, rango, puntos, racha, ultima_actividad, evaluacion_completada
        FROM operador
        WHERE id = %s
        """,
        (session["usuario_id"],),
    )
    return cursor.fetchone()


def guardar_historial(cursor, operador_id, fecha, puntos):
    cursor.execute(
        """
        INSERT INTO historial_puntos (operador_id, fecha, puntos)
        VALUES (%s, %s, %s)
        ON DUPLICATE KEY UPDATE puntos = VALUES(puntos)
        """,
        (operador_id, fecha, int(puntos)),
    )


def fisico_total_vacio():
    return {
        "pushups": 0,
        "pullups": 0,
        "squats": 0,
        "plank_seconds": 0,
        "running_km": 0,
        "burpees": 0,
        "mountain_climbers": 0,
    }


def obtener_fisico_total(cursor, operador_id):
    cursor.execute(
        """
        SELECT
            total_pushups AS pushups,
            total_pullups AS pullups,
            total_squats AS squats,
            total_plank_seconds AS plank_seconds,
            total_running_km AS running_km,
            total_burpees AS burpees,
            total_mountain_climbers AS mountain_climbers
        FROM progreso_fisico_total
        WHERE operador_id = %s
        """,
        (operador_id,),
    )
    return cursor.fetchone() or fisico_total_vacio()


def obtener_o_crear_rutina_diaria(cursor, operador_id, rango):
    cursor.execute(
        """
        SELECT r.*
        FROM rutina_diaria rd
        JOIN rutinas_semar r ON r.id = rd.rutina_id
        WHERE rd.operador_id = %s
        AND rd.fecha = CURRENT_DATE
        LIMIT 1
        """,
        (operador_id,),
    )
    rutina = cursor.fetchone()
    if rutina:
        return rutina

    cursor.execute(
        """
        SELECT *
        FROM rutinas_semar
        WHERE rango = %s
        AND activa = 1
        ORDER BY RAND()
        LIMIT 1
        """,
        (rango,),
    )
    rutina = cursor.fetchone()

    if not rutina:
        cursor.execute(
            """
            SELECT *
            FROM rutinas_semar
            WHERE activa = 1
            ORDER BY RAND()
            LIMIT 1
            """
        )
        rutina = cursor.fetchone()

    if rutina:
        cursor.execute(
            """
            INSERT INTO rutina_diaria (operador_id, fecha, rutina_id)
            VALUES (%s, CURRENT_DATE, %s)
            ON DUPLICATE KEY UPDATE rutina_id = rutina_id
            """,
            (operador_id, rutina["id"]),
        )

    return rutina


def volumen_por_tipo(rutina, tipo):
    prefijo = "rutina" if tipo == "rutina" else "mision"
    return {
        "pushups": int(rutina.get(f"{prefijo}_pushups") or 0),
        "pullups": int(rutina.get(f"{prefijo}_pullups") or 0),
        "squats": int(rutina.get(f"{prefijo}_squats") or 0),
        "plank_seconds": int(rutina.get(f"{prefijo}_plank_seconds") or 0),
        "running_km": float(rutina.get(f"{prefijo}_running_km") or 0),
        "burpees": int(rutina.get(f"{prefijo}_burpees") or 0),
        "mountain_climbers": int(rutina.get(f"{prefijo}_mountain_climbers") or 0),
    }


def sumar_volumen(cursor, operador_id, volumen):
    cursor.execute(
        """
        INSERT INTO progreso_fisico_total
        (
            operador_id,
            total_pushups,
            total_pullups,
            total_squats,
            total_plank_seconds,
            total_running_km,
            total_burpees,
            total_mountain_climbers
        )
        VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
        ON DUPLICATE KEY UPDATE
            total_pushups = total_pushups + VALUES(total_pushups),
            total_pullups = total_pullups + VALUES(total_pullups),
            total_squats = total_squats + VALUES(total_squats),
            total_plank_seconds = total_plank_seconds + VALUES(total_plank_seconds),
            total_running_km = total_running_km + VALUES(total_running_km),
            total_burpees = total_burpees + VALUES(total_burpees),
            total_mountain_climbers = total_mountain_climbers + VALUES(total_mountain_climbers)
        """,
        (
            operador_id,
            volumen["pushups"],
            volumen["pullups"],
            volumen["squats"],
            volumen["plank_seconds"],
            volumen["running_km"],
            volumen["burpees"],
            volumen["mountain_climbers"],
        ),
    )


def obtener_disciplina(cursor, operador_id):
    cursor.execute(
        """
        SELECT
            COUNT(DISTINCT fecha) AS dias,
            SUM(CASE WHEN tipo = 'rutina' THEN 1 ELSE 0 END) AS rutinas,
            SUM(CASE WHEN tipo = 'mision' THEN 1 ELSE 0 END) AS misiones
        FROM actividad_diaria
        WHERE operador_id = %s
        """,
        (operador_id,),
    )
    row = cursor.fetchone() or {}
    return {
        "dias": int(row.get("dias") or 0),
        "rutinas": int(row.get("rutinas") or 0),
        "misiones": int(row.get("misiones") or 0),
    }


@app.route("/")
def root():
    return send_from_directory(PUBLIC_DIR, "index.html")


@app.route("/<path:filename>")
def frontend_files(filename):
    allowed_pages = {"index.html", "dashboard.html", "niveles.html", "registrarse.html", "animacion.html"}
    if filename in allowed_pages or filename.startswith(("css/", "js/", "img/")):
        return send_from_directory(PUBLIC_DIR, filename)
    return send_from_directory(PUBLIC_DIR, "index.html")


@app.route("/api/health", methods=["GET"])
def health():
    return jsonify({"status": "ok"}), 200


@app.route("/api/register", methods=["POST"])
def registrar_usuario():
    data = request.get_json(silent=True) or {}
    email = (data.get("email") or "").strip().lower()
    password = data.get("password") or ""

    if not email or not password:
        return jsonify({"error": "Email y contraseña requeridos"}), 400
    if len(password) < 8:
        return jsonify({"error": "La contraseña debe tener mínimo 8 caracteres"}), 400

    try:
        conn = get_db()
        cursor = conn.cursor(dictionary=True)
        cursor.execute(
            """
            INSERT INTO operador (email, password, rango, puntos, racha, ultima_actividad, evaluacion_completada)
            VALUES (%s, %s, 'Recluta', 0, 0, NULL, 0)
            """,
            (email, password),
        )
        conn.commit()
        cursor.close()
        conn.close()
        return jsonify({"mensaje": "Registro exitoso"}), 201
    except IntegrityError:
        return jsonify({"error": "El correo ya está registrado"}), 409
    except Exception as e:
        print("ERROR REGISTER:", e)
        return jsonify({"error": str(e)}), 500


@app.route("/api/login", methods=["POST"])
def login_usuario():
    data = request.get_json(silent=True) or {}
    email = (data.get("email") or "").strip().lower()
    password = data.get("password") or ""

    if not email or not password:
        return jsonify({"error": "Email y contraseña requeridos"}), 400

    try:
        conn = get_db()
        cursor = conn.cursor(dictionary=True)
        cursor.execute(
            """
            SELECT id, email, password, rango, puntos, evaluacion_completada
            FROM operador
            WHERE email = %s
            """,
            (email,),
        )
        usuario = cursor.fetchone()
        cursor.close()
        conn.close()

        if not usuario or usuario["password"] != password:
            return jsonify({"error": "Credenciales inválidas"}), 401

        rango = usuario["rango"] or "Recluta"
        puntos = usuario["puntos"] or 0
        session["usuario_id"] = usuario["id"]
        session["email"] = usuario["email"]
        session["rango"] = rango
        session["puntos"] = puntos
        session.permanent = True

        return jsonify({
            "mensaje": "Login exitoso",
            "usuario": {
                "id": usuario["id"],
                "email": usuario["email"],
                "rango": rango,
                "nivel": rango,
                "puntos": puntos,
                "evaluacion_completada": usuario["evaluacion_completada"],
            },
        }), 200
    except Exception as e:
        print("ERROR LOGIN:", e)
        return jsonify({"error": str(e)}), 500


@app.route("/api/verificar-sesion", methods=["GET"])
def verificar_sesion():
    if "usuario_id" not in session:
        return jsonify({"error": "No hay sesión activa"}), 401

    try:
        conn = get_db()
        cursor = conn.cursor(dictionary=True)
        usuario = usuario_actual(cursor)

        if not usuario:
            session.clear()
            return jsonify({"error": "Usuario no encontrado"}), 404

        usuario["rango"] = usuario["rango"] or "Recluta"
        usuario["nivel"] = usuario["rango"]

        cursor.execute(
            """
            SELECT fecha, puntos
            FROM historial_puntos
            WHERE operador_id = %s
            ORDER BY fecha ASC
            """,
            (session["usuario_id"],),
        )
        historial = []
        for h in cursor.fetchall():
            historial.append({
                "fecha": h["fecha"].strftime("%d/%m") if hasattr(h["fecha"], "strftime") else str(h["fecha"]),
                "puntos": h["puntos"],
            })

        cursor.execute(
            """
            SELECT pushups, pullups, squats, plank, running, flexibilidad, puntos_totales
            FROM evaluacion_fisica_inicial
            WHERE operador_id = %s
            ORDER BY fecha_registro DESC
            LIMIT 1
            """,
            (session["usuario_id"],),
        )
        fisico_inicial = cursor.fetchone() or {
            "pushups": 0,
            "pullups": 0,
            "squats": 0,
            "plank": 0,
            "running": 0,
            "flexibilidad": 0,
            "puntos_totales": 0,
        }

        fisico_total = obtener_fisico_total(cursor, session["usuario_id"])
        rutina = obtener_o_crear_rutina_diaria(cursor, session["usuario_id"], usuario["rango"])
        conn.commit()

        cursor.execute(
            """
            SELECT tipo
            FROM actividad_diaria
            WHERE operador_id = %s
            AND fecha = CURRENT_DATE
            """,
            (session["usuario_id"],),
        )
        completadas_hoy = [row["tipo"] for row in cursor.fetchall()]
        disciplina = obtener_disciplina(cursor, session["usuario_id"])

        cursor.close()
        conn.close()

        return jsonify({
            "usuario": usuario,
            "historial": historial,
            "fisico": fisico_inicial,
            "fisico_total": fisico_total,
            "operacion": rutina,
            "completadas_hoy": completadas_hoy,
            "disciplina": disciplina,
        }), 200
    except Exception as e:
        print("ERROR EN VERIFICAR SESIÓN:", e)
        return jsonify({"error": str(e)}), 500


@app.route("/api/logout", methods=["POST"])
def logout_usuario():
    session.clear()
    return jsonify({"mensaje": "Sesión cerrada exitosamente"}), 200


@app.route("/api/evaluacion-medica", methods=["POST"])
def guardar_evaluacion_medica():
    if "usuario_id" not in session:
        return jsonify({"error": "No hay sesión activa"}), 401

    data = request.get_json(silent=True) or {}
    usuario_id = session["usuario_id"]

    try:
        conn = get_db()
        cursor = conn.cursor(dictionary=True)

        puntos = int(data.get("puntos") or 0)
        rango = data.get("nivel") or calcular_rango(puntos)
        edad = int(data.get("edad") or 0)
        peso = data.get("peso")
        altura = data.get("altura")
        fc = int(data.get("fc") or 0)
        presion = data.get("presion")
        oxigeno = data.get("oxigeno")
        cardiaca = int(bool(data.get("cardiaca")))
        lesiones = int(bool(data.get("lesiones")))

        observaciones = []
        if cardiaca:
            observaciones.append("Antecedente cardíaco")
        if lesiones:
            observaciones.append("Lesiones articulares")
        if fc > 120:
            observaciones.append("Frecuencia cardíaca alta")
        if presion is not None and int(presion) >= 160:
            observaciones.append("Presión sistólica elevada")
        if oxigeno is not None and int(oxigeno) < 90:
            observaciones.append("Saturación baja")

        apto = 0 if observaciones else 1
        observaciones_texto = ", ".join(observaciones) if observaciones else None

        cursor.execute(
            """
            UPDATE operador
            SET puntos = %s,
                rango = %s,
                evaluacion_completada = 1,
                ultima_actividad = CURRENT_DATE
            WHERE id = %s
            """,
            (puntos, rango, usuario_id),
        )

        cursor.execute(
            """
            INSERT INTO evaluacion_medica_semar
            (
                operador_id, edad_usuario, peso_kg, estatura_cm,
                frecuencia_cardiaca_reposo, presion_sistolica, oxigeno_saturacion,
                enfermedad_cardiaca, problemas_huesos_articulaciones,
                apto_para_entrenamiento, observaciones
            )
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
            """,
            (usuario_id, edad, peso, altura, fc, presion, oxigeno, cardiaca, lesiones, apto, observaciones_texto),
        )

        pushups = int(data.get("pushups") or 0)
        pullups = int(data.get("pullups") or 0)
        squats = int(data.get("squats") or 0)
        plank = int(data.get("plank") or 0)
        running = float(data.get("running") or 0)
        flexibilidad = int(data.get("flexibilidad") or 0)

        cursor.execute(
            """
            INSERT INTO evaluacion_fisica_inicial
            (operador_id, pushups, pullups, squats, plank, running, flexibilidad, puntos_totales)
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
            """,
            (usuario_id, pushups, pullups, squats, plank, running, flexibilidad, puntos),
        )

        sumar_volumen(cursor, usuario_id, {
            "pushups": pushups,
            "pullups": pullups,
            "squats": squats,
            "plank_seconds": plank,
            "running_km": 1.0 if running > 0 else 0,
            "burpees": 0,
            "mountain_climbers": 0,
        })

        guardar_historial(cursor, usuario_id, date.today(), puntos)
        conn.commit()
        cursor.close()
        conn.close()

        session["puntos"] = puntos
        session["rango"] = rango

        return jsonify({
            "mensaje": "Evaluación guardada exitosamente",
            "puntos": puntos,
            "nivel": rango,
            "rango": rango,
            "apto": bool(apto),
            "observaciones": observaciones,
        }), 200
    except Exception as e:
        print("ERROR EVALUACIÓN:", e)
        return jsonify({"error": str(e)}), 500


@app.route("/api/actualizar-puntos", methods=["POST"])
def actualizar_puntos():
    if "usuario_id" not in session:
        return jsonify({"error": "No hay sesión activa"}), 401

    data = request.get_json(silent=True) or {}
    tipo = data.get("tipo")
    if tipo not in ("rutina", "mision"):
        return jsonify({"error": "Tipo de actividad inválido"}), 400

    usuario_id = session["usuario_id"]

    try:
        conn = get_db()
        cursor = conn.cursor(dictionary=True)
        usuario = usuario_actual(cursor)
        if not usuario:
            session.clear()
            return jsonify({"error": "Usuario no encontrado"}), 404

        rango_actual = usuario["rango"] or "Recluta"
        rutina = obtener_o_crear_rutina_diaria(cursor, usuario_id, rango_actual)
        if not rutina:
            return jsonify({"error": "No hay rutina asignada"}), 500

        puntos_extra = int(rutina["puntos_rutina"] if tipo == "rutina" else rutina["puntos_mision"])

        try:
            cursor.execute(
                """
                INSERT INTO actividad_diaria (operador_id, tipo, fecha, puntos_otorgados)
                VALUES (%s, %s, CURRENT_DATE, %s)
                """,
                (usuario_id, tipo, puntos_extra),
            )
        except IntegrityError:
            conn.rollback()
            return jsonify({"error": "Ya completaste esta actividad hoy. Vuelve mañana."}), 409

        puntos_nuevos = int(usuario["puntos"] or 0) + puntos_extra
        rango_nuevo = calcular_rango(puntos_nuevos)

        hoy = date.today()
        ultima = usuario.get("ultima_actividad")
        if ultima == hoy:
            racha_nueva = int(usuario.get("racha") or 0)
        elif ultima == hoy - timedelta(days=1):
            racha_nueva = int(usuario.get("racha") or 0) + 1
        else:
            racha_nueva = 1

        cursor.execute(
            """
            UPDATE operador
            SET puntos = %s,
                rango = %s,
                racha = %s,
                ultima_actividad = CURRENT_DATE
            WHERE id = %s
            """,
            (puntos_nuevos, rango_nuevo, racha_nueva, usuario_id),
        )

        volumen = volumen_por_tipo(rutina, tipo)
        sumar_volumen(cursor, usuario_id, volumen)
        guardar_historial(cursor, usuario_id, hoy, puntos_nuevos)

        conn.commit()

        fisico_total = obtener_fisico_total(cursor, usuario_id)
        disciplina = obtener_disciplina(cursor, usuario_id)

        cursor.execute(
            """
            SELECT tipo
            FROM actividad_diaria
            WHERE operador_id = %s
            AND fecha = CURRENT_DATE
            """,
            (usuario_id,),
        )
        completadas_hoy = [row["tipo"] for row in cursor.fetchall()]

        cursor.close()
        conn.close()

        session["puntos"] = puntos_nuevos
        session["rango"] = rango_nuevo

        return jsonify({
            "mensaje": "Progreso actualizado",
            "puntos": puntos_nuevos,
            "nivel": rango_nuevo,
            "rango": rango_nuevo,
            "racha": racha_nueva,
            "actividad": tipo,
            "puntos_otorgados": puntos_extra,
            "volumen_sumado": volumen,
            "fisico_total": fisico_total,
            "disciplina": disciplina,
            "completadas_hoy": completadas_hoy,
        }), 200
    except Exception as e:
        print("ERROR ACTUALIZAR PUNTOS:", e)
        return jsonify({"error": str(e)}), 500


if __name__ == "__main__":
    port = int(os.getenv("PORT", 5000))
    app.run(host="0.0.0.0", debug=os.getenv("FLASK_DEBUG", "false").lower() == "true", port=port, use_reloader=False)
