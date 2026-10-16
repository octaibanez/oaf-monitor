# Monitoreo externo del servidor OAF

Corre en GitHub Actions (repo octaibanez/oaf-monitor), fuera de Hetzner, cada 5 minutos (GitHub a veces lo atrasa unos minutos).
Revisa n8n, n8n de Drives, los 4 Chatwoot, WAHA y el panel. Un servicio cuenta como caído si falla 3 veces seguidas (20 s entre intentos).
Avisa solo cuando algo se cae o vuelve, por 3 canales:
1. ntfy (app en el celular, suscripto al tema guardado en el secreto NTFY_TOPIC; ver memoria monitoreo-externo).
2. WhatsApp a Octa por WAHA (solo si WAHA sigue vivo).
3. Mail de GitHub (el run queda en rojo cuando se cae algo).
La lista de direcciones está en el secreto MONITOR_URLS (formato nombre=url separados por espacio).
