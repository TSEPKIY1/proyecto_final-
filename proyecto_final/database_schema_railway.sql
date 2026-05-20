CREATE TABLE operador (
    id INT PRIMARY KEY AUTO_INCREMENT,
    email VARCHAR(100) NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL,
    rango VARCHAR(30) NOT NULL DEFAULT 'Recluta',
    puntos INT NOT NULL DEFAULT 0,
    racha INT NOT NULL DEFAULT 0,
    ultima_actividad DATE DEFAULT NULL,
    evaluacion_completada BOOLEAN NOT NULL DEFAULT 0,
    fecha_registro DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE evaluacion_medica_semar (
    id INT AUTO_INCREMENT PRIMARY KEY,
    operador_id INT NOT NULL,
    fecha_evaluacion DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    edad_usuario INT NOT NULL,
    peso_kg DECIMAL(6,2) DEFAULT NULL,
    estatura_cm INT DEFAULT NULL,
    frecuencia_cardiaca_reposo INT NOT NULL,
    presion_sistolica INT DEFAULT NULL,
    oxigeno_saturacion INT DEFAULT NULL,
    enfermedad_cardiaca BOOLEAN NOT NULL DEFAULT 0,
    problemas_huesos_articulaciones BOOLEAN NOT NULL DEFAULT 0,
    apto_para_entrenamiento BOOLEAN NOT NULL DEFAULT 1,
    observaciones VARCHAR(255) DEFAULT NULL,
    FOREIGN KEY (operador_id) REFERENCES operador(id) ON DELETE CASCADE
);

CREATE TABLE evaluacion_fisica_inicial (
    id INT AUTO_INCREMENT PRIMARY KEY,
    operador_id INT NOT NULL,
    pushups INT NOT NULL DEFAULT 0,
    pullups INT NOT NULL DEFAULT 0,
    squats INT NOT NULL DEFAULT 0,
    plank INT NOT NULL DEFAULT 0,
    running DECIMAL(5,2) NOT NULL DEFAULT 0,
    flexibilidad INT NOT NULL DEFAULT 0,
    puntos_totales INT NOT NULL DEFAULT 0,
    fecha_registro DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (operador_id) REFERENCES operador(id) ON DELETE CASCADE
);

CREATE TABLE progreso_fisico_total (
    operador_id INT PRIMARY KEY,
    total_pushups INT NOT NULL DEFAULT 0,
    total_pullups INT NOT NULL DEFAULT 0,
    total_squats INT NOT NULL DEFAULT 0,
    total_plank_seconds INT NOT NULL DEFAULT 0,
    total_running_km DECIMAL(8,2) NOT NULL DEFAULT 0,
    total_burpees INT NOT NULL DEFAULT 0,
    total_mountain_climbers INT NOT NULL DEFAULT 0,
    fecha_actualizacion DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (operador_id) REFERENCES operador(id) ON DELETE CASCADE
);

CREATE TABLE historial_puntos (
    id INT AUTO_INCREMENT PRIMARY KEY,
    operador_id INT NOT NULL,
    fecha DATE NOT NULL,
    puntos INT NOT NULL,
    UNIQUE KEY uq_historial_dia (operador_id, fecha),
    FOREIGN KEY (operador_id) REFERENCES operador(id) ON DELETE CASCADE
);

CREATE TABLE rutinas_semar (
    id INT AUTO_INCREMENT PRIMARY KEY,
    rango VARCHAR(30) NOT NULL,
    nombre VARCHAR(100) NOT NULL,
    objetivo VARCHAR(255) NOT NULL,
    duracion VARCHAR(50) NOT NULL,
    intensidad VARCHAR(50) NOT NULL,
    enfoque VARCHAR(80) NOT NULL,
    rutina TEXT NOT NULL,
    beneficio TEXT NOT NULL,
    mision TEXT NOT NULL,
    mision_beneficio TEXT NOT NULL,
    tiempo_descanso INT NOT NULL DEFAULT 90,
    puntos_rutina INT NOT NULL DEFAULT 20,
    puntos_mision INT NOT NULL DEFAULT 30,
    rutina_pushups INT NOT NULL DEFAULT 0,
    rutina_pullups INT NOT NULL DEFAULT 0,
    rutina_squats INT NOT NULL DEFAULT 0,
    rutina_plank_seconds INT NOT NULL DEFAULT 0,
    rutina_running_km DECIMAL(8,2) NOT NULL DEFAULT 0,
    rutina_burpees INT NOT NULL DEFAULT 0,
    rutina_mountain_climbers INT NOT NULL DEFAULT 0,
    mision_pushups INT NOT NULL DEFAULT 0,
    mision_pullups INT NOT NULL DEFAULT 0,
    mision_squats INT NOT NULL DEFAULT 0,
    mision_plank_seconds INT NOT NULL DEFAULT 0,
    mision_running_km DECIMAL(8,2) NOT NULL DEFAULT 0,
    mision_burpees INT NOT NULL DEFAULT 0,
    mision_mountain_climbers INT NOT NULL DEFAULT 0,
    fuente_pdf VARCHAR(120) NOT NULL DEFAULT 'Guía de Actividad Física SEMAR',
    activa BOOLEAN NOT NULL DEFAULT 1
);

CREATE TABLE rutina_diaria (
    id INT AUTO_INCREMENT PRIMARY KEY,
    operador_id INT NOT NULL,
    fecha DATE NOT NULL,
    rutina_id INT NOT NULL,
    UNIQUE KEY uq_rutina_usuario_dia (operador_id, fecha),
    FOREIGN KEY (operador_id) REFERENCES operador(id) ON DELETE CASCADE,
    FOREIGN KEY (rutina_id) REFERENCES rutinas_semar(id) ON DELETE CASCADE
);

CREATE TABLE actividad_diaria (
    id INT AUTO_INCREMENT PRIMARY KEY,
    operador_id INT NOT NULL,
    tipo ENUM('rutina','mision') NOT NULL,
    fecha DATE NOT NULL,
    puntos_otorgados INT NOT NULL,
    fecha_registro DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY uq_actividad_diaria (operador_id, tipo, fecha),
    FOREIGN KEY (operador_id) REFERENCES operador(id) ON DELETE CASCADE
);

INSERT INTO rutinas_semar (rango,nombre,duracion,intensidad,enfoque,objetivo,rutina,beneficio,mision,mision_beneficio,tiempo_descanso,rutina_pushups,rutina_pullups,rutina_squats,rutina_plank_seconds,rutina_running_km,rutina_burpees,rutina_mountain_climbers,mision_pushups,mision_pullups,mision_squats,mision_plank_seconds,mision_running_km,mision_burpees,mision_mountain_climbers) VALUES
('Recluta','Inicio general','35-40 min','Baja','Adaptación cardiovascular','Crear base de resistencia y técnica sin saturar articulaciones.','1. Caminata rápida — 20 minutos.
2. Lagartijas con rodillas apoyadas o normales — 3 series de 8 repeticiones.
3. Sentadilla libre — 3 series de 12 repeticiones.
4. Plancha frontal — 3 series de 20 segundos.
5. Elevación de rodillas en el lugar — 3 series de 30 segundos.
Descanso: 60 segundos entre series.','Ayuda a crear hábito, mejorar respiración y preparar piernas, abdomen, pecho y hombros para entrenamientos más largos.','Completar 2 rondas:
• 8 lagartijas
• 12 sentadillas
• 20 segundos de plancha
• 1 minuto de caminata rápida
Descanso máximo: 60 segundos entre rondas.','Refuerza técnica básica y continuidad sin exigir intensidad alta.',90,24,0,36,60,2.0,0,0,16,0,24,40,0.3,0,0),
('Recluta','Movilidad y postura','30-35 min','Baja','Movilidad y control corporal','Mejorar movilidad, postura y control antes de subir intensidad.','1. Movilidad de cuello, hombros y cadera — 8 minutos.
2. Puente de glúteo — 3 series de 15 repeticiones.
3. Sentadilla libre lenta — 3 series de 10 repeticiones.
4. Bird-dog — 3 series de 10 repeticiones por lado.
5. Plancha frontal — 3 series de 20 segundos.
6. Caminata ligera — 12 minutos.','Mejora estabilidad de cadera, zona lumbar y abdomen; reduce riesgo de mala técnica al correr o hacer fuerza.','Completar 3 rondas suaves:
• 10 puentes de glúteo
• 10 sentadillas lentas
• 20 segundos de plancha
• 30 segundos de caminata en el lugar','Aumenta control corporal y resistencia postural.',75,0,0,30,60,1.0,0,0,0,0,30,60,0.0,0,0),
('Recluta','Cardio base','35 min','Baja','Resistencia aeróbica','Aumentar tolerancia al esfuerzo continuo.','1. Caminata rápida — 25 minutos.
2. Lagartijas inclinadas en mesa o pared — 3 series de 10 repeticiones.
3. Sentadilla libre — 3 series de 15 repeticiones.
4. Crunch abdominal — 3 series de 15 repeticiones.
5. Estiramiento suave — 5 minutos.','Mejora condición cardiovascular y ayuda a sostener actividad por más tiempo sin detenerse.','Reto continuo:
• 10 minutos caminando sin pausa
• 10 lagartijas inclinadas
• 15 sentadillas
• 15 crunches','Entrena constancia y tolerancia al movimiento continuo.',90,30,0,45,0,2.2,0,0,10,0,15,0,0.8,0,0),
('Recluta','Cuerpo completo inicial','40 min','Baja-media','Fuerza básica','Trabajar todo el cuerpo con ejercicios sencillos y seguros.','1. Caminata de calentamiento — 8 minutos.
2. Lagartijas normales o con rodillas — 4 series de 8 repeticiones.
3. Sentadilla libre — 4 series de 12 repeticiones.
4. Remo con mochila — 3 series de 12 repeticiones.
5. Plancha frontal — 3 series de 25 segundos.
6. Caminata final — 10 minutos.','Fortalece pecho, espalda, piernas y abdomen con volumen moderado.','Completar 2 rondas:
• 8 lagartijas
• 12 sentadillas
• 12 remos con mochila
• 25 segundos de plancha','Une fuerza básica con resistencia muscular.',90,32,0,48,75,1.0,0,0,16,0,24,50,0.0,0,0),
('Recluta','Pierna y abdomen básico','35 min','Baja-media','Piernas y abdomen','Mejorar resistencia de piernas y estabilidad del abdomen.','1. Calentamiento caminando — 8 minutos.
2. Sentadilla libre — 4 series de 15 repeticiones.
3. Desplantes atrás — 3 series de 8 por pierna.
4. Elevación de pantorrillas — 3 series de 20 repeticiones.
5. Plancha frontal — 4 series de 20 segundos.
6. Caminata ligera — 8 minutos.','Fortalece piernas para caminar, correr y soportar mejor el peso corporal.','Completar 3 rondas:
• 15 sentadillas
• 10 desplantes por pierna
• 20 elevaciones de pantorrilla
• 20 segundos de plancha','Construye base de pierna sin necesidad de equipo.',90,0,0,60,80,0.8,0,0,0,0,45,60,0.0,0,0),
('Cadete','Resistencia y fuerza básica','45 min','Media','Cuerpo completo','Combinar cardio con fuerza usando volumen manejable.','1. Trote suave — 15 minutos.
2. Lagartijas — 4 series de 12 repeticiones.
3. Sentadilla libre — 4 series de 18 repeticiones.
4. Remo con mochila o banda — 4 series de 12 repeticiones.
5. Plancha frontal — 4 series de 30 segundos.
Descanso: 45-60 segundos.','Mejora resistencia general, fuerza de empuje, espalda y estabilidad central.','Completar 3 rondas:
• 12 lagartijas
• 18 sentadillas
• 12 remos con mochila
• 30 segundos de plancha
Descanso máximo: 60 segundos.','Acostumbra al cuerpo a trabajar fuerza bajo respiración elevada.',120,48,0,72,120,2.0,0,0,36,0,54,90,0.0,0,0),
('Cadete','Intervalos sencillos','40-45 min','Media','Cardio e intervalos','Aprender a alternar esfuerzo y recuperación.','1. Calentamiento caminando — 8 minutos.
2. Trote 2 minutos + caminata 1 minuto — repetir 8 veces.
3. Lagartijas — 3 series de 15.
4. Crunch abdominal — 3 series de 20.
5. Estiramiento — 5 minutos.','Mejora recuperación entre esfuerzos y capacidad cardiovascular.','Completar 10 minutos de intervalos:
• 30 segundos trote rápido
• 30 segundos caminata
Después: 20 sentadillas y 20 crunches.','Ayuda a controlar respiración y ritmo.',120,45,0,0,0,3.0,0,0,0,0,20,0,1.0,0,0),
('Cadete','Pierna y estabilidad','45 min','Media','Piernas','Desarrollar resistencia de piernas con técnica clara.','1. Calentamiento dinámico — 8 minutos.
2. Sentadilla libre — 4 series de 20.
3. Desplantes caminando — 3 series de 12 por pierna.
4. Step-ups en banco o escalón — 3 series de 12 por pierna.
5. Plancha lateral — 3 series de 20 segundos por lado.
6. Caminata rápida — 10 minutos.','Fortalece piernas, glúteos y abdomen para correr, subir escaleras y tolerar más volumen.','Completar 3 rondas:
• 20 sentadillas
• 12 desplantes por pierna
• 12 step-ups por pierna
• 20 segundos de plancha lateral por lado','Mejora estabilidad y resistencia muscular de piernas.',120,0,0,80,120,1.0,0,0,0,0,60,120,0.0,0,0),
('Cadete','Empuje y abdomen','40 min','Media','Pecho, hombro y abdomen','Mejorar fuerza de empuje y estabilidad abdominal.','1. Movilidad de hombros — 5 minutos.
2. Lagartijas — 5 series de 10 repeticiones.
3. Fondos en silla — 4 series de 10 repeticiones.
4. Plancha frontal — 4 series de 35 segundos.
5. Mountain climbers — 4 series de 20 repeticiones.
6. Caminata ligera — 8 minutos.','Fortalece pecho, hombros, tríceps y abdomen, útiles para pruebas físicas básicas.','Completar 4 rondas:
• 10 lagartijas
• 10 fondos en silla
• 20 mountain climbers
• 30 segundos de plancha','Aumenta resistencia del tren superior y core.',120,50,0,0,140,0.8,0,80,40,0,0,120,0.0,0,80),
('Cadete','Marcha activa','50 min','Media','Resistencia continua','Sostener actividad por más tiempo sin pausas largas.','1. Caminata rápida o trote suave — 35 minutos.
2. Lagartijas — 3 series de 12.
3. Sentadillas — 3 series de 20.
4. Plancha — 3 series de 30 segundos.
5. Estiramiento final — 7 minutos.','Mejora resistencia aeróbica y tolerancia a sesiones largas.','Reto:
• Completar 3 km caminando rápido o trotando suave.
• Al terminar: 20 sentadillas y 10 lagartijas.','Refuerza constancia y control del ritmo.',120,36,0,60,90,3.0,0,0,10,0,20,0,3.0,0,0),
('Soldado','Circuito funcional claro','50 min','Media-alta','Fuerza-resistencia','Trabajar fuerza y respiración en rondas continuas.','Completar 4 rondas:
1. Lagartijas — 15 repeticiones.
2. Dominadas estrictas o remo invertido — 6 repeticiones.
3. Sentadilla libre — 25 repeticiones.
4. Mountain climbers — 30 repeticiones.
5. Plancha frontal — 40 segundos.
Descanso: 60 segundos por ronda.','Desarrolla resistencia muscular en pecho, espalda, piernas y abdomen.','Completar 2 rondas extra:
• 12 lagartijas
• 20 sentadillas
• 20 mountain climbers
• 30 segundos de plancha','Mejora tolerancia a fatiga acumulada.',150,60,24,100,160,0.0,0,120,24,0,40,60,0.0,0,40),
('Soldado','Carrera y cuerpo completo','55 min','Media-alta','Cardio y fuerza','Combinar carrera con fuerza sin perder técnica.','1. Carrera continua — 25 minutos.
2. Lagartijas — 4 series de 18.
3. Dominadas o remo con mochila — 4 series de 8.
4. Desplantes caminando — 3 series de 14 por pierna.
5. Plancha frontal — 4 series de 40 segundos.','Aumenta capacidad cardiovascular y fuerza útil para sesiones largas.','Completar 1 km adicional a ritmo moderado.
Después:
• 15 lagartijas
• 20 sentadillas
• 30 segundos de plancha','Refuerza resistencia después del bloque principal.',150,72,32,84,160,3.5,0,0,15,0,20,30,1.0,0,0),
('Soldado','Pierna fuerte','50 min','Media-alta','Piernas y estabilidad','Mejorar fuerza-resistencia de piernas.','1. Calentamiento — 10 minutos.
2. Sentadilla libre — 5 series de 20.
3. Desplantes caminando — 4 series de 12 por pierna.
4. Step-ups — 4 series de 12 por pierna.
5. Elevaciones de pantorrilla — 4 series de 25.
6. Plancha lateral — 4 series de 25 segundos por lado.','Construye piernas más resistentes para correr, marchar y sostener esfuerzo prolongado.','Completar 3 rondas:
• 25 sentadillas
• 12 desplantes por pierna
• 20 elevaciones de pantorrilla
• 30 segundos de plancha','Mejora estabilidad y tolerancia de piernas.',150,0,0,100,200,0.0,0,0,0,0,75,90,0.0,0,0),
('Soldado','Empuje, espalda y abdomen','50 min','Media-alta','Tren superior','Fortalecer empuje, jalón y zona media.','1. Lagartijas — 5 series de 16.
2. Dominadas o remo invertido — 5 series de 6.
3. Fondos en silla — 4 series de 12.
4. Crunch abdominal — 4 series de 25.
5. Plancha frontal — 4 series de 45 segundos.
6. Caminata rápida — 10 minutos.','Equilibra pecho, espalda y abdomen para mejorar postura y rendimiento.','Completar 4 rondas:
• 12 lagartijas
• 6 dominadas o 12 remos
• 20 crunches
• 30 segundos de plancha','Aumenta resistencia de torso y abdomen.',150,80,30,0,180,1.0,0,0,48,24,0,120,0.0,0,0),
('Soldado','Intervalos y potencia','45 min','Alta controlada','Velocidad y recuperación','Mejorar cambios de ritmo y recuperación.','1. Calentamiento — 10 minutos.
2. Sprint corto — 8 repeticiones de 20 segundos.
3. Caminata de recuperación — 40 segundos después de cada sprint.
4. Burpees — 4 series de 8.
5. Sentadillas — 4 series de 20.
6. Plancha — 3 series de 45 segundos.','Mejora velocidad, respiración y capacidad de recuperarte entre esfuerzos intensos.','Completar 3 rondas:
• 8 burpees
• 20 sentadillas
• 20 mountain climbers
• 30 segundos de trote rápido','Entrena potencia sin perder control.',150,0,0,80,135,1.2,32,0,0,0,60,0,0.4,24,60),
('Operador','Resistencia bajo fatiga','60 min','Alta','Cardio y fuerza','Mantener rendimiento físico cuando ya hay cansancio.','1. Carrera continua — 30 minutos.
2. Lagartijas — 5 series de 20.
3. Dominadas estrictas o remo invertido — 5 series de 8.
4. Sentadillas — 5 series de 25.
5. Plancha frontal — 5 series de 45 segundos.
Descanso: 45 segundos entre series.','Mejora resistencia cardiovascular y fuerza-resistencia de cuerpo completo.','Completar 4 rondas:
• 15 lagartijas
• 20 sentadillas
• 8 dominadas o 12 remos
• 30 segundos de plancha
Descanso máximo: 45 segundos.','Mide capacidad de sostener técnica bajo cansancio.',180,100,40,125,225,4.5,0,0,60,32,80,120,0.0,0,0),
('Operador','Fuerza funcional avanzada','55-65 min','Alta','Fuerza funcional','Subir volumen con ejercicios claros y ejecutables.','1. Calentamiento dinámico — 10 minutos.
2. Lagartijas con pausa abajo — 5 series de 15.
3. Dominadas o remo con mochila pesada — 5 series de 8.
4. Sentadilla con mochila — 5 series de 18.
5. Desplantes caminando — 4 series de 14 por pierna.
6. Plancha lateral — 4 series de 30 segundos por lado.','Aumenta fuerza útil en piernas, espalda, pecho y abdomen sin depender de gimnasio.','Completar 3 rondas:
• 15 lagartijas con pausa
• 18 sentadillas con mochila
• 10 remos con mochila
• 30 segundos de plancha lateral por lado','Desarrolla fuerza estable y control del cuerpo.',180,75,40,90,240,0.0,0,0,45,0,54,180,0.0,0,0),
('Operador','Cardio prolongado','60 min','Media-alta','Resistencia aeróbica','Sostener esfuerzo largo con ritmo controlado.','1. Carrera o trote continuo — 40 minutos.
2. Lagartijas — 4 series de 15.
3. Sentadillas — 4 series de 20.
4. Crunch abdominal — 4 series de 25.
5. Estiramiento final — 8 minutos.','Mejora capacidad pulmonar, ritmo y recuperación después del esfuerzo.','Reto:
• Completar 5 km caminando rápido o trotando.
• Al terminar: 20 lagartijas y 30 sentadillas.','Construye resistencia mental y cardiovascular.',180,60,0,80,0,5.0,0,0,20,0,30,0,5.0,0,0),
('Operador','Potencia y abdomen','55 min','Alta','Potencia y estabilidad','Mejorar explosividad con abdomen fuerte.','1. Calentamiento — 10 minutos.
2. Burpees — 5 series de 10.
3. Sentadilla con salto — 5 series de 12.
4. Lagartijas — 5 series de 18.
5. Mountain climbers — 5 series de 30.
6. Plancha frontal — 5 series de 45 segundos.','Mejora potencia, coordinación, abdomen y resistencia a esfuerzos intensos.','Completar 4 rondas:
• 8 burpees
• 12 sentadillas con salto
• 15 lagartijas
• 30 mountain climbers','Eleva intensidad con ejercicios entendibles y medibles.',180,90,0,60,225,0.0,50,150,60,0,48,0,0.0,32,120),
('Operador','Full body avanzado','65 min','Alta','Cuerpo completo','Integrar cardio, piernas, torso y abdomen en una sesión completa.','1. Trote — 15 minutos.
2. Lagartijas — 5 series de 20.
3. Dominadas o remo invertido — 5 series de 8.
4. Sentadilla con mochila — 5 series de 20.
5. Desplantes — 4 series de 12 por pierna.
6. Plancha — 5 series de 50 segundos.
7. Caminata final — 10 minutos.','Entrena todo el cuerpo con volumen alto y descanso controlado.','Completar 3 rondas:
• 20 lagartijas
• 20 sentadillas
• 10 remos o dominadas asistidas
• 45 segundos de plancha','Aumenta capacidad de trabajo total.',180,100,40,100,250,3.0,0,0,60,30,60,135,0.0,0,0),
('Elite','Desafío total medible','70 min','Muy alta','Cuerpo completo','Poner a prueba resistencia, fuerza y recuperación.','Completar 6 rondas:
1. Lagartijas — 20 repeticiones.
2. Dominadas estrictas o remo pesado — 10 repeticiones.
3. Sentadillas — 30 repeticiones.
4. Burpees — 10 repeticiones.
5. Plancha frontal — 60 segundos.
Descanso: 60 segundos entre rondas.','Mide capacidad física total con volumen alto y ejercicios claros.','Completar 1 ronda extra de calidad:
• 20 lagartijas
• 30 sentadillas
• 10 burpees
• 60 segundos de plancha','Reto final para tolerancia a fatiga.',240,120,60,180,360,0.0,60,0,20,0,30,60,0.0,10,0),
('Elite','Resistencia máxima','75 min','Muy alta','Cardio prolongado','Sostener esfuerzo largo y cerrar con fuerza.','1. Carrera continua — 50 minutos.
2. Lagartijas — 5 series de 25.
3. Dominadas — 5 series de 10.
4. Sentadillas — 5 series de 30.
5. Plancha — 5 series de 60 segundos.','Fortalece resistencia cardiovascular y musculatura bajo alto volumen.','Reto:
• Completar 6 km de carrera o marcha rápida.
• Luego 25 lagartijas y 40 sentadillas.','Exige control de ritmo y recuperación.',240,125,50,150,300,7.0,0,0,25,0,40,0,6.0,0,0),
('Elite','Fuerza-resistencia superior','65 min','Muy alta','Torso y abdomen','Aumentar volumen en empuje, jalón y core.','1. Lagartijas — 6 series de 22.
2. Dominadas estrictas — 6 series de 8.
3. Fondos en silla o paralelas — 5 series de 15.
4. Mountain climbers — 6 series de 40.
5. Plancha frontal — 6 series de 60 segundos.
6. Trote suave — 12 minutos.','Mejora resistencia de pecho, espalda, hombros, tríceps y abdomen.','Completar 4 rondas:
• 20 lagartijas
• 8 dominadas
• 20 fondos
• 40 mountain climbers','Consolida tren superior con volumen alto.',240,132,48,0,360,2.0,0,240,80,32,0,0,0.0,0,160),
('Elite','Pierna y potencia avanzada','65 min','Muy alta','Piernas y potencia','Desarrollar piernas resistentes y explosivas.','1. Calentamiento — 12 minutos.
2. Sentadilla con mochila — 6 series de 25.
3. Desplantes caminando — 5 series de 16 por pierna.
4. Sentadilla con salto — 5 series de 15.
5. Sprint corto — 10 repeticiones de 20 segundos.
6. Plancha lateral — 5 series de 35 segundos por lado.','Mejora fuerza de piernas, potencia y capacidad de cambio de ritmo.','Completar 4 rondas:
• 30 sentadillas
• 12 desplantes por pierna
• 10 sentadillas con salto
• 30 segundos de sprint en sitio','Eleva resistencia de piernas y potencia.',240,0,0,150,350,1.5,0,0,0,0,120,0,0.5,0,0),
('Elite','Operación completa civil','75 min','Muy alta','Full body y resistencia','Cerrar la semana con volumen alto, claro y medible.','1. Carrera o marcha rápida — 35 minutos.
2. Lagartijas — 6 series de 20.
3. Dominadas o remo pesado — 6 series de 8.
4. Sentadillas — 6 series de 25.
5. Burpees — 5 series de 10.
6. Plancha — 5 series de 60 segundos.','Integra resistencia, fuerza muscular y control mental en una sesión completa.','Completar 5 rondas:
• 15 lagartijas
• 20 sentadillas
• 8 dominadas o remos
• 8 burpees
• 45 segundos de plancha','Sirve como prueba semanal de capacidad general.',240,120,48,150,300,5.0,50,0,75,40,100,225,0.0,40,0);
