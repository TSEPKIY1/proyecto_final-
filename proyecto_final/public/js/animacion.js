document.addEventListener("DOMContentLoaded", () => {
    const API_BASE = window.location.origin;

    fetch(`${API_BASE}/api/verificar-sesion`, {
        method: "GET",
        credentials: "include"
    })
        .then(response => {
            if (!response.ok) throw new Error("Sesión inválida");
            return response.json();
        })
        .then(data => {
            setTimeout(() => {
                if (data.usuario && Number(data.usuario.evaluacion_completada) === 1) {
                    window.location.href = "dashboard.html";
                } else {
                    window.location.href = "niveles.html";
                }
            }, 4500);
        })
        .catch(error => {
            console.error("ERROR DE SESIÓN:", error);
            window.location.href = "index.html";
        });
});
