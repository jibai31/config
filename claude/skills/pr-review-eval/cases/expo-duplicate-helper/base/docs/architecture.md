# Architecture

1. The local SQLite database is the source of truth on the device. Screens read data only through the hooks in
   `src/features/*/`, which query SQLite with Drizzle live queries. This is what makes the app work offline.
2. Only the sync service in `src/sync/` talks to the network. It pulls server data into SQLite; screens then see it
   through their live queries.
