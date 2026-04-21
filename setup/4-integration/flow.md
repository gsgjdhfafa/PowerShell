# End-to-End Flow (einmalig)

```
[PC]  Brave  ->  Notion Dashboard

[Telegram]  /task ...   -->  [VPS bot]  -->  [KI]  -->  JSON  -->  [Notion]
                                                                         |
                                    <-- Bestaetigung als formatierte Antwort
```

## Reihenfolge nach frischer VPS

```bash
# als root auf dem Server:
export APP_USER=ops
bash setup/2-server/01-base.sh
bash setup/2-server/02-security.sh
bash setup/2-server/03-docker.sh
bash setup/2-server/04-node.sh

# .env vorbereiten:
cp setup/3-bot/.env.example setup/3-bot/.env
# Werte eintragen, dann:

export REPO_URL=git@github.com:<du>/<repo>.git
export BRANCH=main
bash setup/2-server/05-deploy.sh
```

## Verify

```bash
docker ps --filter name=zf-bot
docker logs -f zf-bot
```

Telegram: `/start` -> Antwort erwartet.
