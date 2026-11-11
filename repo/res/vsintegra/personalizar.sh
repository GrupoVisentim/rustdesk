#!/usr/bin/env bash
# Personalização "VS Integra Suporte" — roda no GitHub Actions logo depois de baixar o código do RustDesk
# (passo inserido em .github/workflows/flutter-build.yml). Troca servidor, chave e nome; se alguma troca
# não pegar (o RustDesk mudou o arquivo), PARA a compilação em vez de gerar um app apontando pro lugar errado.
set -euo pipefail

NOME_CURTO="VSIntegra"                 # nome interno (pastas, serviço do Windows) — sem espaço de propósito
NOME_EXIBIDO="VS Integra Suporte"      # nome que aparece no Windows (Propriedades) e no Android
SERVIDOR="191.101.70.117"              # servidor próprio na VPS (/docker/rustdesk)
CHAVE="WogQPInisUXot8CQT5gaMf8d4Qw4l+uClZhMvv68oFU="
PACOTE_ANDROID="br.com.vsintegra.suporte"

if [ -f .vsintegra-ok ]; then echo "já personalizado"; exit 0; fi

CFG=libs/hbb_common/src/config.rs
sed -i -E "s|(pub static ref APP_NAME: RwLock<String> = RwLock::new\(\")RustDesk(\"\.to_owned\(\)\);)|\1${NOME_CURTO}\2|" "$CFG"
sed -i -E "s|(pub const RENDEZVOUS_SERVERS: &\[&str\] = &\[)\"[^\"]*\"(\];)|\1\"${SERVIDOR}\"\2|" "$CFG"
sed -i -E "s|(pub const RS_PUB_KEY: &str = \")[^\"]*(\";)|\1${CHAVE}\2|" "$CFG"
grep -q "RwLock::new(\"${NOME_CURTO}\".to_owned())" "$CFG" || { echo "ERRO: não troquei o APP_NAME em $CFG"; exit 1; }
grep -qF "&[\"${SERVIDOR}\"]" "$CFG" || { echo "ERRO: não troquei o servidor em $CFG"; exit 1; }
grep -qF "\"${CHAVE}\"" "$CFG" || { echo "ERRO: não troquei a chave em $CFG"; exit 1; }

RC=flutter/windows/runner/Runner.rc
if [ -f "$RC" ]; then
  sed -i "s/\"RustDesk Remote Desktop\"/\"${NOME_EXIBIDO} Remoto\"/; s/\"ProductName\", \"RustDesk\"/\"ProductName\", \"${NOME_EXIBIDO}\"/" "$RC"
fi

MAN=flutter/android/app/src/main/AndroidManifest.xml
if [ -f "$MAN" ]; then
  sed -i "s/android:label=\"RustDesk\"/android:label=\"${NOME_EXIBIDO}\"/; s/android:label=\"RustDesk Input\"/android:label=\"${NOME_EXIBIDO} Input\"/" "$MAN"
fi

GR=flutter/android/app/build.gradle
if [ -f "$GR" ]; then
  sed -i "s/applicationId \"com.carriez.flutter_hbb\"/applicationId \"${PACOTE_ANDROID}\"/" "$GR"
fi

touch .vsintegra-ok
echo "Personalizado: ${NOME_EXIBIDO} -> ${SERVIDOR}"
