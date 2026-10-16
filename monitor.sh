#!/usr/bin/env bash
# Revisa los servicios de OAF desde afuera (GitHub) y avisa solo cuando algo cambia (se cae / vuelve).
# Secretos: MONITOR_URLS ("nombre=url" separados por espacio), NTFY_TOPIC, WAHA_KEY, WA_CHAT.
set -u
ESTADO_FILE=estado/caidos.txt
mkdir -p estado; touch "$ESTADO_FILE"
antes=$(sort -u "$ESTADO_FILE")
caidos=""
for par in $MONITOR_URLS; do
  nombre=${par%%=*}; url=${par#*=}; ok=0
  for intento in 1 2 3; do
    code=$(curl -s -o /dev/null -w '%{http_code}' -m 20 "$url")
    if [[ "$code" =~ ^[23] ]]; then ok=1; break; fi
    sleep 20
  done
  [ $ok = 0 ] && caidos="$caidos $nombre($code)"
  echo "$nombre: $code"
done
ahora=$(echo $caidos | tr ' ' '\n' | sed 's/(.*//' | grep -v '^$' | sort -u)
echo "$ahora" > "$ESTADO_FILE"

nuevos=$(comm -13 <(echo "$antes") <(echo "$ahora") | grep -v '^$' | tr '\n' ' ')
volvieron=$(comm -23 <(echo "$antes") <(echo "$ahora") | grep -v '^$' | tr '\n' ' ')
[ -z "$nuevos" ] && [ -z "$volvieron" ] && exit 0

msg=""
[ -n "$nuevos" ] && msg="CAIDO en el servidor OAF: $nuevos(detalle:$caidos)"
[ -n "$volvieron" ] && msg="$msg${msg:+ / }VOLVIO: $volvieron"
echo "AVISO: $msg"
curl -s -m 20 -H "Title: Servidor OAF" -H "Priority: $([ -n "$nuevos" ] && echo urgent || echo default)" -d "$msg" "https://ntfy.sh/$NTFY_TOPIC" >/dev/null || true
curl -s -m 20 -X POST -H "X-Api-Key: $WAHA_KEY" -H "Content-Type: application/json" \
  -d "$(jq -n --arg t "$msg" --arg c "$WA_CHAT" '{session:"testrodz",chatId:$c,text:$t}')" \
  https://waha.oafiagency.online/api/sendText >/dev/null || true
# Si algo se cayó, el run falla y GitHub manda mail (tercer canal, por si WAHA también está caído)
[ -n "$nuevos" ] && exit 1 || exit 0
