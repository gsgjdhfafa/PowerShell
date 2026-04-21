# Telegram Setup (2 Minuten)

1. In Telegram `@BotFather` oeffnen.
2. `/newbot` -> Name + Handle vergeben. Token kopieren -> `.env` `TELEGRAM_BOT_TOKEN`.
3. In Telegram `@userinfobot` oeffnen, eigene numerische ID kopieren.
4. In `.env`:  `TELEGRAM_ALLOWED_USER_IDS=123456789` (Komma-separiert fuer mehrere).
5. Optional `/setcommands` beim BotFather:
   ```
   task - Aufgabe anlegen
   note - Notiz speichern
   cost - Ausgabe erfassen
   ```
