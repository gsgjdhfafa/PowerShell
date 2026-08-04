# 07-raspberry-pi

SSH-Einrichtung für einen Raspberry Pi im lokalen Netzwerk.

```bash
curl -fsSL -o ~/Desktop/PI_SSH_SETUP.command "https://raw.githubusercontent.com/gsgjdhfafa/PowerShell/claude/setup-system-architecture-XKISu/setup-system-architecture/07-raspberry-pi/PI_SSH_SETUP.command" && chmod +x ~/Desktop/PI_SSH_SETUP.command && bash ~/Desktop/PI_SSH_SETUP.command
```

Macht (einmalig, idempotent):
1. Sucht den Pi per mDNS (`raspberrypi.local` u.ä., Fallback: Bonjour-SSH-Scan)
2. Fragt Benutzername ab
3. Legt einen SSH-Key an, falls noch keiner existiert (überschreibt nie)
4. Trägt einen Host-Alias `raspi` in `~/.ssh/config` ein (keine Duplikate)
5. Bietet `ssh-copy-id` an (einmalig Passwort nötig)
6. Testet die Verbindung

Danach reicht überall: `ssh raspi`
