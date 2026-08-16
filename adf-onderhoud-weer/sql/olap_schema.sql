-- ===================== DIMENSIES =====================

CREATE TABLE [dbo].[DimDatum]
(
    DatumKey        INT NOT NULL PRIMARY KEY,   -- yyyymmdd
    Datum           DATE NOT NULL,
    Dag             INT,
    Maand           INT,
    MaandNaam       VARCHAR(20),
    Kwartaal        INT,
    Jaar            INT,
    Weeknummer      INT,
    Seizoen         VARCHAR(10),
    DagVanWeek      VARCHAR(10),
    IsWeekend       BIT
)

CREATE TABLE [dbo].[DimLocatie]
(
    LocatieKey      INT IDENTITY PRIMARY KEY,
    Postcode4       VARCHAR(4),
    Woonplaats      VARCHAR(100),
    Wijk            VARCHAR(100) NULL
)

CREATE TABLE [dbo].[DimObject]
(
    ObjectKey       INT IDENTITY PRIMARY KEY,
    BOT_ID          BIGINT NOT NULL,
    Naam            VARCHAR(200),
    ObjectType      VARCHAR(50),
    Daeb_YN         CHAR(1),
    Etage           FLOAT,
    Gang            FLOAT,
    Subcomplex      VARCHAR(100),
    ComplexStatus   VARCHAR(50),
    Straatnaam      VARCHAR(150),
    Huisnummer      INT,
    LocatieKey      INT FOREIGN KEY REFERENCES DimLocatie(LocatieKey)
)

CREATE TABLE [dbo].[DimWerksoort]
(
    WerksoortKey    INT IDENTITY PRIMARY KEY,
    SOORT_ID        BIGINT NOT NULL,
    Code            BIGINT,
    Omschrijving    VARCHAR(200)
)

CREATE TABLE [dbo].[DimProject]
(
    ProjectKey          INT IDENTITY PRIMARY KEY,
    PROJECT_ID          BIGINT NOT NULL,
    Omschrijving         VARCHAR(200),
    Startdatum           DATE,
    Einddatum            DATE,
    BegroteBedragBTW     DECIMAL(18,2)
)

CREATE TABLE [dbo].[DimMelding]
(
    MeldingKey      INT IDENTITY PRIMARY KEY,
    WERKVERZOEK_ID  BIGINT NOT NULL,
    Omschrijving    VARCHAR(300),
    BonJaar         VARCHAR(10),
    BonNmmr         BIGINT
)

CREATE TABLE [dbo].[DimWeer]
(
    WeerKey             INT IDENTITY PRIMARY KEY,
    LocatieKey          INT FOREIGN KEY REFERENCES DimLocatie(LocatieKey),
    DatumKey            INT FOREIGN KEY REFERENCES DimDatum(DatumKey),
    GemTemperatuurC     DECIMAL(5,1),
    MinTemperatuurC     DECIMAL(5,1),
    MaxTemperatuurC     DECIMAL(5,1),
    NeerslagMM          DECIMAL(6,1),
    WindkrachtBft       INT,
    MaxWindstootKmh     DECIMAL(5,1),
    VorstYN             BIT,
    StormYN             BIT,
    Weertype            VARCHAR(50)
)

-- ===================== FACT =====================

CREATE TABLE [dbo].[FactWerk]
(
    WerkFactKey             BIGINT IDENTITY PRIMARY KEY,
    OPDRACHT_ID             BIGINT NOT NULL,
    MeldingKey              INT FOREIGN KEY REFERENCES DimMelding(MeldingKey),
    ObjectKey               INT FOREIGN KEY REFERENCES DimObject(ObjectKey),
    WerksoortKey            INT FOREIGN KEY REFERENCES DimWerksoort(WerksoortKey),
    ProjectKey              INT NULL FOREIGN KEY REFERENCES DimProject(ProjectKey),
    MelddatumKey            INT FOREIGN KEY REFERENCES DimDatum(DatumKey),
    OpdrachtdatumKey        INT FOREIGN KEY REFERENCES DimDatum(DatumKey),
    StartdatumKey           INT NULL FOREIGN KEY REFERENCES DimDatum(DatumKey),
    EinddatumKey            INT NULL FOREIGN KEY REFERENCES DimDatum(DatumKey),
    WeerOpMeldingKey        INT NULL FOREIGN KEY REFERENCES DimWeer(WeerKey),
    AantalMeldingen         INT NOT NULL DEFAULT 1,
    DoorlooptijdDagen       INT,
    IsAfgerond              BIT,
    BegroteKosten           DECIMAL(18,2) NULL
)

-- ===================== ETL ONDERSTEUNING =====================

CREATE TABLE [dbo].[ETL_Watermark]
(
    TableName               VARCHAR(100) NOT NULL PRIMARY KEY,
    LastLoadedOpdrachtdatum  DATETIME2,
    LastRunDatum             DATETIME2
)
GO

CREATE PROCEDURE [dbo].[usp_UpdateWatermark]
    @TableName VARCHAR(100),
    @LoadDatum DATETIME2
AS
BEGIN
    MERGE INTO ETL_Watermark AS target
    USING (SELECT @TableName AS TableName, @LoadDatum AS LoadDatum) AS src
    ON target.TableName = src.TableName
    WHEN MATCHED THEN UPDATE SET LastLoadedOpdrachtdatum = src.LoadDatum, LastRunDatum = src.LoadDatum
    WHEN NOT MATCHED THEN INSERT (TableName, LastLoadedOpdrachtdatum, LastRunDatum) VALUES (src.TableName, src.LoadDatum, src.LoadDatum);
END
GO
