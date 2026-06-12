# Notion Schema (nur Property-Namen + Typen)

Die Bot-Properties MUESSEN exakt so in Notion existieren.
Integration (Connection) in Notion anlegen, Token in `.env` als `NOTION_TOKEN`.
Jede DB oeffnen -> "Connections" -> Integration hinzufuegen.
Datenbank-ID aus der URL nehmen (32 Zeichen) und in `.env` eintragen.

## Memory  (NOTION_DB_MEMORY)
- Name      : Title
- Summary   : Text
- Tags      : Multi-select

## Tasks   (NOTION_DB_TASKS)
- Name      : Title
- Due       : Date
- Priority  : Select   (Optionen: low, med, high)
- Notes     : Text
- GTaskId   : Text     (befuellt durch Bot beim Sync zu Google Tasks)
- EventId   : Text     (befuellt durch Bot beim Anlegen von Google Calendar Event)

## Costs   (NOTION_DB_COSTS)
- Name      : Title
- Amount    : Number
- Currency  : Select   (Optionen: EUR, USD, ...)
- Category  : Select   (frei)
- Notes     : Text
