document.addEventListener("DOMContentLoaded", () => {
    const API_BASE = window.location.origin;

    let usuario = null;
    let historial = [];
    let grafica = null;
    let fisicoInicial = {};
    let fisicoTotal = {};
    let operacion = {};
    let completadasHoy = [];
    let disciplina = {};

    const coloresRango = {
        Recluta: "#8b949e",
        Cadete: "#58a6ff",
        Soldado: "#1f6feb",
        Operador: "#ff9e00",
        Elite: "#00ff9c"
    };

    verificarSesion();

    async function verificarSesion() {
        try {
            const response = await fetch(`${API_BASE}/api/verificar-sesion`, {
                method: "GET",
                credentials: "include"
            });

            if (!response.ok) {
                window.location.href = "index.html";
                return;
            }

            const data = await response.json();

            usuario = data.usuario || {};
            usuario.nivel = usuario.nivel || usuario.rango || "Recluta";
            usuario.puntos = Number(usuario.puntos || 0);
            historial = Array.isArray(data.historial) ? data.historial : [];
            fisicoInicial = data.fisico || {};
            fisicoTotal = data.fisico_total || {};
            operacion = data.operacion || {};
            completadasHoy = Array.isArray(data.completadas_hoy) ? data.completadas_hoy : [];
            disciplina = data.disciplina || {};

            iniciarEvaluacion();
            iniciarDashboard();
        } catch (error) {
            console.error("ERROR SESIÓN:", error);
            window.location.href = "index.html";
        }
    }

    function fechaActual() {
        const hoy = new Date();
        return `${String(hoy.getDate()).padStart(2, "0")}/${String(hoy.getMonth() + 1).padStart(2, "0")}`;
    }

    function calcularNivel(puntos) {
        if (puntos < 80) return "Recluta";
        if (puntos < 160) return "Cadete";
        if (puntos < 260) return "Soldado";
        if (puntos < 380) return "Operador";
        return "Elite";
    }

    function numeroOpcional(id) {
        const value = document.getElementById(id)?.value;
        if (value === undefined || value === null || String(value).trim() === "") return null;
        const n = Number(value);
        return Number.isFinite(n) ? n : null;
    }

    function iniciarEvaluacion() {
        const form = document.getElementById("evaluacionForm");
        if (!form) return;

        form.addEventListener("submit", async (e) => {
            e.preventDefault();

            const edad = Number(document.getElementById("edad")?.value || 0);
            const peso = numeroOpcional("peso");
            const altura = numeroOpcional("altura");
            const fc = Number(document.getElementById("fc")?.value || 0);
            const presion = numeroOpcional("presion");
            const oxigeno = numeroOpcional("oxigeno");
            const cardiaca = document.getElementById("cardiaca")?.value === "1";
            const lesiones = document.getElementById("lesiones")?.value === "1";

            const pushups = Number(document.getElementById("pushups")?.value || 0);
            const pullups = Number(document.getElementById("pullups")?.value || 0);
            const squats = Number(document.getElementById("squats")?.value || 0);
            const plank = Number(document.getElementById("plank")?.value || 0);
            const running = Number(document.getElementById("run")?.value || 0);
            const flexibilidad = Number(document.getElementById("flexibilidad")?.value || 0);

            let puntos = 0;
            puntos += pushups * 2;
            puntos += pullups * 5;
            puntos += squats;
            puntos += Math.floor(plank / 10);
            puntos += Math.max(0, Math.floor((8 - running) * 12));
            puntos += flexibilidad;

            usuario.puntos = puntos;
            usuario.nivel = calcularNivel(puntos);
            historial = [{ fecha: fechaActual(), puntos }];

            try {
                const response = await fetch(`${API_BASE}/api/evaluacion-medica`, {
                    method: "POST",
                    headers: { "Content-Type": "application/json" },
                    credentials: "include",
                    body: JSON.stringify({
                        edad, peso, altura, fc, presion, oxigeno,
                        cardiaca, lesiones,
                        puntos,
                        nivel: usuario.nivel,
                        pushups, pullups, squats, plank, running, flexibilidad
                    })
                });

                const data = await response.json();

                if (!response.ok) {
                    alert(data.error || "No se pudo guardar la evaluación.");
                    return;
                }

                const resultadoBox = document.getElementById("resultadoBox");
                const estadoMedico = document.getElementById("estadoMedico");
                const nivelOperador = document.getElementById("nivelOperador");
                const detalleRutina = document.getElementById("detalleRutina");

                if (resultadoBox) resultadoBox.classList.add("activo");
                if (estadoMedico) {
                    estadoMedico.textContent = data.apto ? "APTO PARA ENTRENAMIENTO" : "REVISIÓN MÉDICA RECOMENDADA";
                }
                if (nivelOperador) nivelOperador.textContent = `NIVEL ASIGNADO: ${data.rango || usuario.nivel}`;
                if (detalleRutina) {
                    const obs = Array.isArray(data.observaciones) && data.observaciones.length
                        ? ` | Observaciones: ${data.observaciones.join(", ")}`
                        : "";
                    detalleRutina.textContent = `PUNTOS OBTENIDOS: ${data.puntos}${obs}`;
                }

                setTimeout(() => {
                    window.location.href = "dashboard.html";
                }, 2200);
            } catch (error) {
                console.error("ERROR EVALUACIÓN:", error);
                alert("Servidor no disponible.");
            }
        });
    }

    function iniciarDashboard() {
        const email = document.getElementById("email");
        if (!email) return;

        actualizarUI();
        renderizarGrafica();
        inicializarCronometro();

        const btnLogout = document.getElementById("btnLogout");
        if (btnLogout) {
            btnLogout.addEventListener("click", async () => {
                await fetch(`${API_BASE}/api/logout`, {
                    method: "POST",
                    credentials: "include"
                });
                window.location.href = "index.html";
            });
        }
    }

    function actualizarUI() {
        const color = coloresRango[usuario.nivel] || coloresRango.Recluta;

        setText("email", `Usuario: ${usuario.email || "Sin correo"}`);
        setText("nivel", `Nivel: ${usuario.nivel}`);
        setText("puntos", `Puntos: ${usuario.puntos}`);
        setText("racha", `🔥 ${usuario.racha || disciplina.dias || 0} días`);

        setText("rutinaNombre", operacion.nombre || "ENTRENAMIENTO DEL DÍA");
        setText("rutinaDuracion", operacion.duracion || "---");
        setText("rutinaIntensidad", operacion.intensidad || "---");
        setText("rutinaEnfoque", operacion.enfoque || "---");
        setText("rutinaObjetivo", operacion.objetivo || "Completar la rutina asignada con buena técnica.");
        setText("rutina", operacion.rutina || "Rutina pendiente.");
        setText("rutinaBeneficio", operacion.beneficio || "Este entrenamiento ayuda a mejorar condición física general.");
        setText("mision", operacion.mision || "Misión pendiente.");
        setText("misionBeneficio", operacion.mision_beneficio || "Refuerza constancia y disciplina.");

        const progreso = Math.min((usuario.puntos / 500) * 100, 100);
        const barra = document.getElementById("barra");
        if (barra) {
            barra.style.width = `${progreso}%`;
            barra.style.background = color;
        }
        setText("porcentajeProgreso", `${Math.round(progreso)}%`);

        setText("metricPushups", numeroEntero(fisicoTotal.pushups));
        setText("metricPullups", numeroEntero(fisicoTotal.pullups));
        setText("metricSquats", numeroEntero(fisicoTotal.squats));
        setText("metricRunning", `${numeroDecimal(fisicoTotal.running_km)} km`);
        setText("metricPlank", `${numeroEntero(fisicoTotal.plank_seconds)} seg`);
        setText("metricBurpees", numeroEntero(fisicoTotal.burpees));

        setText("diasActivos", disciplina.dias || 0);
        setText("misionesCompletadas", disciplina.misiones || 0);
        setText("rutinasCompletadas", disciplina.rutinas || 0);

        const diagnostico = document.getElementById("diagnostico");
        if (diagnostico) diagnostico.textContent = diagnosticoFisico();

        actualizarBotonesCooldown();
    }

    function setText(id, value) {
        const el = document.getElementById(id);
        if (el) el.textContent = value;
    }

    function numeroEntero(value) {
        return Number(value || 0).toLocaleString("es-MX");
    }

    function numeroDecimal(value) {
        return Number(value || 0).toFixed(2);
    }

    function diagnosticoFisico() {
        const puntosFisicos = Number(fisicoInicial.puntos_totales || usuario.puntos || 0);
        const totalReps = Number(fisicoTotal.pushups || 0) + Number(fisicoTotal.squats || 0) + Number(fisicoTotal.pullups || 0);
        const km = Number(fisicoTotal.running_km || 0);

        if (!usuario.evaluacion_completada) return "Evaluación física pendiente.";
        if (totalReps >= 1000 || km >= 20) return "Progreso sólido: ya acumulaste buen volumen de fuerza y resistencia.";
        if (puntosFisicos < 80) return "Base inicial: prioriza técnica, constancia y sesiones sin dolor.";
        if (puntosFisicos < 160) return "Condición en desarrollo: ya puedes trabajar fuerza básica y cardio moderado.";
        if (puntosFisicos < 260) return "Buen margen para resistencia y fuerza: mantén progresión semanal.";
        if (puntosFisicos < 380) return "Condición avanzada: toleras circuitos exigentes y mayor volumen.";
        return "Condición alta: enfócate en sostener rendimiento y recuperarte bien.";
    }

    function actualizarBotonesCooldown() {
        const btnRutina = document.querySelector(".btn-principal");
        const btnMision = document.querySelector(".btn-mision");

        if (btnRutina && completadasHoy.includes("rutina")) {
            btnRutina.disabled = true;
            btnRutina.textContent = "ENTRENAMIENTO COMPLETADO HOY";
        }
        if (btnMision && completadasHoy.includes("mision")) {
            btnMision.disabled = true;
            btnMision.textContent = "MISIÓN COMPLETADA HOY";
        }
    }

    function renderizarGrafica() {
        const canvas = document.getElementById("grafica");
        if (!canvas || typeof Chart === "undefined") return;

        if (grafica) grafica.destroy();

        const datos = historial.length ? historial : [{ fecha: fechaActual(), puntos: usuario.puntos || 0 }];

        grafica = new Chart(canvas, {
            type: "line",
            data: {
                labels: datos.map(item => item.fecha),
                datasets: [{
                    label: "Progreso de puntos",
                    data: datos.map(item => item.puntos),
                    tension: 0.35,
                    borderWidth: 2,
                    pointRadius: 4
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                plugins: {
                    legend: {
                        display: false
                    }
                },
                scales: {
                    x: { ticks: { color: "#8b949e" }, grid: { color: "rgba(139,148,158,.1)" } },
                    y: { ticks: { color: "#8b949e" }, grid: { color: "rgba(139,148,158,.1)" } }
                }
            }
        });
    }

    function inicializarCronometro() {
        const timerDisplay = document.getElementById("timerDisplay");
        const btnTimer = document.getElementById("btnTimer");
        const btnResetTimer = document.getElementById("btnResetTimer");

        if (!timerDisplay || !btnTimer || !btnResetTimer) return;

        let timerId = null;
        const tiempoInicial = Number(operacion.tiempo_descanso || 90);
        let tiempoRestante = tiempoInicial;

        function actualizarTimerUI() {
            const minutos = Math.floor(tiempoRestante / 60);
            const segundos = tiempoRestante % 60;
            timerDisplay.textContent = `${String(minutos).padStart(2, "0")}:${String(segundos).padStart(2, "0")}`;
        }

        function pausarCronometro() {
            if (timerId) {
                clearInterval(timerId);
                timerId = null;
            }
        }

        function toggleCronometro() {
            if (timerId) {
                pausarCronometro();
                btnTimer.textContent = "CONTINUAR";
                return;
            }

            btnTimer.textContent = "PAUSAR";

            timerId = setInterval(() => {
                if (tiempoRestante <= 0) {
                    pausarCronometro();
                    btnTimer.textContent = "INICIAR";
                    alert("Descanso finalizado.");
                    return;
                }
                tiempoRestante--;
                actualizarTimerUI();
            }, 1000);
        }

        function reiniciarCronometro() {
            pausarCronometro();
            tiempoRestante = tiempoInicial;
            btnTimer.textContent = "INICIAR";
            actualizarTimerUI();
        }

        btnTimer.addEventListener("click", toggleCronometro);
        btnResetTimer.addEventListener("click", reiniciarCronometro);
        window.toggleCronometro = toggleCronometro;
        window.reiniciarCronometro = reiniciarCronometro;
        actualizarTimerUI();
    }

    async function guardarProgreso(tipo) {
        if (completadasHoy.includes(tipo)) {
            alert("Ya reclamaste esta recompensa hoy. Vuelve mañana.");
            return;
        }

        const nivelAnterior = usuario.nivel;

        try {
            const response = await fetch(`${API_BASE}/api/actualizar-puntos`, {
                method: "POST",
                headers: { "Content-Type": "application/json" },
                credentials: "include",
                body: JSON.stringify({ tipo })
            });

            const data = await response.json();

            if (!response.ok) {
                alert(data.error || "No se pudo guardar el progreso.");
                return;
            }

            usuario.puntos = Number(data.puntos || usuario.puntos);
            usuario.nivel = data.nivel || data.rango || calcularNivel(usuario.puntos);
            usuario.rango = usuario.nivel;
            usuario.racha = data.racha || usuario.racha;

            if (data.fisico_total) fisicoTotal = data.fisico_total;
            if (data.disciplina) disciplina = data.disciplina;
            if (Array.isArray(data.completadas_hoy)) completadasHoy = data.completadas_hoy;

            const hoy = fechaActual();
            const registroHoy = historial.find(item => item.fecha === hoy);
            if (registroHoy) registroHoy.puntos = usuario.puntos;
            else historial.push({ fecha: hoy, puntos: usuario.puntos });

            actualizarUI();
            renderizarGrafica();

            const volumen = data.volumen_sumado || {};
            alert(`Progreso guardado.\nVolumen sumado:\nLagartijas: ${volumen.pushups || 0}\nDominadas: ${volumen.pullups || 0}\nSentadillas: ${volumen.squats || 0}\nCarrera: ${volumen.running_km || 0} km`);

            if (nivelAnterior !== usuario.nivel) mostrarAscenso();
        } catch (error) {
            console.error("ERROR GUARDAR PROGRESO:", error);
            alert("Servidor no disponible.");
        }
    }

    function mostrarAscenso() {
        const alerta = document.getElementById("levelUpMsg");
        if (!alerta) return;
        alerta.style.display = "block";
        alerta.textContent = `ASCENSO: ${usuario.nivel}`;
        setTimeout(() => { alerta.style.display = "none"; }, 3000);
    }

    window.completarRutina = () => guardarProgreso("rutina");
    window.completarMision = () => guardarProgreso("mision");
});
