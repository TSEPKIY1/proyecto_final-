document.addEventListener("DOMContentLoaded", () => {

    const API_BASE = window.location.origin;

    const btnVerPassword = document.getElementById("btnVerPassword");
    const passwordInput = document.getElementById("password");

    const loginStatus = document.getElementById("loginStatus");

    if (btnVerPassword && passwordInput) {

        btnVerPassword.addEventListener("click", () => {

            if (passwordInput.type === "password") {

                passwordInput.type = "text";
                btnVerPassword.textContent = "OCULTAR CONTRASEÑA";

            } else {

                passwordInput.type = "password";
                btnVerPassword.textContent = "MOSTRAR CONTRASEÑA";

            }

        });

    }


    const loginForm = document.getElementById("loginForm");

    if (loginForm) {

        loginForm.addEventListener("submit", async (e) => {

            e.preventDefault();

            const email = document.getElementById("email").value.trim();
            const password = passwordInput.value;

            // =========================
            // VALIDACIÓN BÁSICA
            // =========================
            if (!email || !password) {

                mostrarEstado("Completa todos los campos.", "#ff4d4d");
                return;

            }

            try {

                mostrarEstado("Conectando con el servidor táctico...", "#58a6ff");

                const response = await fetch(`${API_BASE}/api/login`, {

                    method: "POST",

                    headers: {
                        "Content-Type": "application/json"
                    },

                    credentials: "include",

                    body: JSON.stringify({
                        email,
                        password
                    })

                });

                const data = await response.json();

                // =========================
                // LOGIN EXITOSO
                // =========================
                if (response.ok) {

                    mostrarEstado("ACCESO AUTORIZADO", "#00ff9c");

                    console.log("LOGIN EXITOSO:", data);

                    setTimeout(() => {

                        window.location.href = "animacion.html";

                    }, 1200);

                } else {

                    mostrarEstado(
                        data.error || "Credenciales inválidas.",
                        "#ff4d4d"
                    );

                }

            } catch (error) {

                console.error("ERROR LOGIN:", error);

                mostrarEstado(
                    "Servidor fuera de línea.",
                    "#ff4d4d"
                );

            }

        });

    }

    // =====================================================
    // REGISTRO
    // =====================================================
    const registroForm = document.getElementById("registroForm");

    if (registroForm) {

        const checkLongitud = document.getElementById("longitud");
        const checkMayus = document.getElementById("mayus");
        const checkNumero = document.getElementById("numero");

        const confirmarInput = document.getElementById("confirmar");

        // =========================================
        // VALIDACIÓN EN TIEMPO REAL
        // =========================================
        passwordInput.addEventListener("input", () => {

            const pass = passwordInput.value;

            // Longitud
            if (checkLongitud) {

                const ok = pass.length >= 8;

                checkLongitud.innerHTML =
                    ok ? "✅ Mínimo 8 caracteres"
                        : "❌ Mínimo 8 caracteres";

                checkLongitud.style.color =
                    ok ? "#00ff9c" : "#8b949e";

            }

            // Mayúscula
            if (checkMayus) {

                const ok = /[A-Z]/.test(pass);

                checkMayus.innerHTML =
                    ok ? "✅ Una mayúscula"
                        : "❌ Una mayúscula";

                checkMayus.style.color =
                    ok ? "#00ff9c" : "#8b949e";

            }

            // Número
            if (checkNumero) {

                const ok = /[0-9]/.test(pass);

                checkNumero.innerHTML =
                    ok ? "✅ Un número"
                        : "❌ Un número";

                checkNumero.style.color =
                    ok ? "#00ff9c" : "#8b949e";

            }

        });

        // =========================================
        // ENVÍO DEL REGISTRO
        // =========================================
        registroForm.addEventListener("submit", async (e) => {

            e.preventDefault();

            const email = document.getElementById("email").value.trim();

            const pass = passwordInput.value;

            const confirmar = confirmarInput.value;

            // =========================
            // VALIDACIÓN PASSWORD
            // =========================
            const passwordSegura =
                pass.length >= 8 &&
                /[A-Z]/.test(pass) &&
                /[0-9]/.test(pass);

            if (!passwordSegura) {

                alert("La contraseña no cumple los requisitos.");

                return;

            }

            if (pass !== confirmar) {

                alert("Las contraseñas no coinciden.");

                return;

            }

            try {

                const response = await fetch(`${API_BASE}/api/register`, {

                    method: "POST",

                    headers: {
                        "Content-Type": "application/json"
                    },

                    credentials: "include",

                    body: JSON.stringify({
                        email,
                        password: pass
                    })

                });

                const data = await response.json();

                if (response.ok) {

                    alert("Registro exitoso.");

                    console.log(data);

                    window.location.href = "index.html";

                } else {

                    alert(data.error || "Error en el registro.");

                }

            } catch (error) {

                console.error("ERROR REGISTRO:", error);

                alert("Servidor no disponible.");

            }

        });

    }

    // =====================================================
    // UTILIDAD UI
    // =====================================================
    function mostrarEstado(texto, color) {

        if (!loginStatus) return;

        loginStatus.textContent = texto;
        loginStatus.style.color = color;

    }

});