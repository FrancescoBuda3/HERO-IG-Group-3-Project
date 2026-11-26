#!/bin/bash
# Avvia tutto il necessario per Mike in un solo terminale:
#   1. controlla la chiave OpenRouter e la connessione
#   2. avvia il server Piper TTS (porta 5001)
#   3. apre il progetto in Godot
# Premi Ctrl+C in questo terminale per chiudere anche Piper.

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
VOICE="${MIKE_VOICE:-en_GB-semaine-medium}"      # voce Piper (file .onnx nella cartella del progetto)
PORT="${MIKE_PIPER_PORT:-5001}"            # deve coincidere con piper_port in tts_piper.gd
GODOT_APP="${GODOT_APP:-$HOME/Downloads/Godot.app}"
KEY_FILE="$HOME/Library/Application Support/Godot/app_userdata/MikeTPAGodot/openrouter_key.txt"
PIPER_PID=""

cd "$PROJECT_DIR" || exit 1

# Python: usa il venv del progetto se esiste, altrimenti python3 di sistema
if [ -x "$PROJECT_DIR/.venv/bin/python3" ]; then
  PY="$PROJECT_DIR/.venv/bin/python3"
else
  PY="python3"
fi

cleanup() {
  echo
  if [ -n "$PIPER_PID" ] && kill -0 "$PIPER_PID" 2>/dev/null; then
    echo "Chiudo Piper (pid $PIPER_PID)..."
    kill "$PIPER_PID" 2>/dev/null
  fi
  exit 0
}
trap cleanup INT TERM EXIT

echo "== 1/3 Controlli =="

if ! "$PY" -c "import piper" 2>/dev/null; then
  echo "ERRORE: piper-tts non è installato per $PY"
  echo "Installalo con:  $PY -m pip install piper-tts flask"
  exit 1
fi

if [ ! -f "$PROJECT_DIR/$VOICE.onnx" ]; then
  echo "Voce $VOICE non trovata, la scarico..."
  "$PY" -m piper.download_voices "$VOICE" || { echo "ERRORE: download voce fallito"; exit 1; }
fi

if [ -s "$KEY_FILE" ]; then
  echo "Chiave OpenRouter: trovata"
else
  echo "ATTENZIONE: chiave OpenRouter mancante in:"
  echo "  $KEY_FILE"
  echo "Mike non potrà rispondere finché non la salvi (vedi la guida)."
fi

# Controllo veloce che OpenRouter sia raggiungibile (senza inviare la chiave)
if curl -s -m 8 -o /dev/null https://openrouter.ai/api/v1/models; then
  echo "Connessione a OpenRouter: ok"
else
  echo "ATTENZIONE: OpenRouter non raggiungibile, controlla la connessione"
fi

echo
echo "== 2/3 Piper TTS (voce $VOICE, porta $PORT) =="

piper_ready() {
  curl -s -m 3 -o /dev/null -X POST "http://localhost:$PORT/synthesize" \
    -H 'Content-Type: application/json' -d '{"text":"ok"}'
}

start_piper() {
  "$PY" -m piper.http_server -m "$VOICE" --port "$PORT" > /tmp/mike_piper.log 2>&1 &
  PIPER_PID=$!
  for i in $(seq 1 30); do
    if piper_ready; then
      echo "Piper pronto (pid $PIPER_PID)"
      return 0
    fi
    if ! kill -0 "$PIPER_PID" 2>/dev/null; then
      echo "ERRORE: Piper si è fermato. Log:"
      cat /tmp/mike_piper.log
      return 1
    fi
    sleep 1
  done
  return 1
}

if piper_ready; then
  echo "Piper già attivo sulla porta $PORT, lo uso."
elif lsof -iTCP:"$PORT" -sTCP:LISTEN -n -P >/dev/null 2>&1; then
  echo "ERRORE: la porta $PORT è occupata da un altro programma che non è Piper:"
  lsof -iTCP:"$PORT" -sTCP:LISTEN -n -P
  exit 1
else
  start_piper || exit 1
fi

echo
echo "== 3/3 Godot =="
if [ -d "$GODOT_APP" ]; then
  open -a "$GODOT_APP" --args --path "$PROJECT_DIR"
  echo "Godot aperto. Premi Play, poi Spazio per parlare."
else
  echo "Godot non trovato in $GODOT_APP"
  echo "Aprilo a mano, oppure lancia:  GODOT_APP=/percorso/Godot.app ./start_mike.sh"
fi

echo
echo "Mike è pronto. Lascia aperto questo terminale; Ctrl+C per chiudere Piper."
# Controlla Piper ogni 5 secondi e lo riavvia se si ferma
while true; do
  sleep 5
  if ! piper_ready; then
    echo "$(date +%H:%M:%S) Piper non risponde, lo riavvio..."
    [ -n "$PIPER_PID" ] && kill "$PIPER_PID" 2>/dev/null
    start_piper || echo "Riavvio fallito, riprovo tra poco."
  fi
done
