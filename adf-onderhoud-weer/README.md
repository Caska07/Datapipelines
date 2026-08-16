# ADF Pipeline — Onderhoudsmeldingen & Weer (Zuid-Limburg)

Azure Data Factory git-repo structuur voor het laden van de OLAP-database (star schema)
vanuit de OLTP-bron én het aanvullen met historische weerdata van Open-Meteo voor de
regio Zuid-Limburg.

## Uitgangspunten
- OLTP en OLAP staan op **dezelfde SQL server, andere database** → twee losse
  Linked Services (`LS_SQL_OLTP`, `LS_SQL_OLAP`) op dezelfde server.
- Wachtwoorden staan niet in de JSON's maar in Key Vault (`LS_KeyVault`) — vervang de
  placeholders (`<server-naam>`, `<database-naam>`, secret-namen) voor eigen gebruik.
- Weerdata komt van de gratis Open-Meteo Archive API, geen API-key nodig.
  Centroid Zuid-Limburg (Heerlen, 50.888 / 5.980) wordt gebruikt — weer varieert niet
  per postcode, dus één weerpunt per dag volstaat voor de hele regio.

## Structuur
```
linkedService/   Verbindingen: OLTP-db, OLAP-db, Key Vault, weer-API
dataset/         Tabel-/resource-referenties per linked service
pipeline/
  PL_Master_ETL        Orkestreert de 3 sub-pipelines in de juiste volgorde
  PL_Load_Dimensions   OLTP -> DimWerksoort, DimProject, DimMelding, DimObject, DimLocatie
  PL_Load_Weerdata     Haalt Open-Meteo data op, upsert naar DimWeer
  PL_Load_FactWerk     Bouwt FactWerk (grain = 1 rij per WERKOPDRACHT), incrementeel via watermark
trigger/         Dagelijkse schedule trigger (06:00)
sql/             DDL voor het OLAP-schema + watermark-tabel/stored proc
```

## Volgorde is belangrijk
`Load Dimensions` → `Load Weerdata` → `Load FactWerk`, want FactWerk doet een lookup
op zowel de dimensies als DimWeer (via LocatieKey + MelddatumKey).

## Nog te bouwen in ADF Studio (Mapping Data Flows)
De JSON's hier verwijzen naar twee Data Flows die je zelf visueel moet samenstellen
(dit zit niet in losse Copy-activities omdat er joins/dedupe/flatten nodig zijn):
- **DF_Load_DimObject** — join OBJECTEN + ADRES + COMPLEX, dedupliceer naar DimLocatie,
  schrijf DimObject + DimLocatie weg.
- **DF_Load_DimWeer** — flatten de daily-arrays uit de Open-Meteo response naar losse
  rijen, bereken `VorstYN` (min temp < 0), `StormYN` (windstoot > 75 km/u), `DatumKey`,
  upsert naar DimWeer.
- **DF_Load_FactWerk** — join WERKOPDRACHT + WERKVERZOEK, lookups naar alle dimensies,
  bereken `DoorlooptijdDagen`, upsert naar FactWerk op `OPDRACHT_ID`, gefilterd op de
  watermark.

## Importeren
In Azure Data Factory Studio: Manage → Git configuration → koppel deze repo. ADF leest
de mappenstructuur automatisch in als linked services, datasets, pipelines en triggers.
