# IMDb ETL Projekt

Tento repozitár obsahuje implementáciu ETL procesu v Snowflake pre analýzu dát z IMDb datasetu. Cieľom projektu je spracovanie a modelovanie filmových údajov pre ďalšie analytické účely, vrátane hodnotení filmov, informácií o hercoch, režiséroch, a žánroch. Projekt využíva dátové modelovanie na podporu multidimenzionálnej analýzy a vizualizácie filmových metrik.

## 1. Úvod a popis zdrojových dát

### 1.1 Zdrojové dáta
IMDb dataset obsahuje rôznorodé informácie o filmoch, hercoch, režiséroch a ich hodnoteniach. Dáta boli spracované z nasledovných zdrojových súborov:
- **`director_mapping.csv`**: Mapovanie režisérov na filmy.
- **`genre.csv`**: Informácie o žánroch filmov.
- **`movie.csv`**: Detailné údaje o filmoch, vrátane názvu, roku vydania, trvania a produkčnej spoločnosti.
- **`names.csv`**: Základné údaje o hercoch a režiséroch, ako sú meno a dátum narodenia.
- **`ratings.csv`**: Hodnotenia filmov od používateľov, vrátane priemernej hodnoty, mediánu a počtu hlasov.
- **`role_mapping.csv`**: Údaje o úlohách hercov v jednotlivých filmoch.

Tieto dáta boli transformované a načítané do Snowflake pomocou ETL procesu, aby boli optimalizované pre analytické úlohy.

### 1.2 Dátová architektúra

#### Entitno-relačný model (ERD)
Surové dáta boli usporiadané do relačného modelu, ktorý je znázornený na entitno-relačnom diagrame (ERD):

![ERD IMDb Model](https://github.com/patrikrajnoha/IMDb-ETL/blob/main/erd_schema.png)

---

## 2. Dimenzionálny model

Navrhnutý bol hviezdicový model (**star schema**), ktorý slúži na efektívnu analýzu filmových dát. Centrálna faktová tabuľka **fact_ratings** je prepojená s nasledujúcimi dimenziami:

- **dim_movie**: Obsahuje detailné údaje o filmoch, ako sú názov, dátum vydania, dĺžka filmu, produkčná spoločnosť a žánre.
- **dim_names**: Informácie o osobách, vrátane mena, dátumu narodenia a kategórie (herec/režisér).
- **dim_date**: Zahrňuje údaje o dátumoch hodnotení (deň, mesiac, rok, štvrťrok).
- **dim_time**: Podrobné časové údaje (hodina, AM/PM).
- **sdim_genre**: Špecifické údaje o žánroch filmov.

#### Hviezdicová schéma
Struktúra hviezdicového modelu je znázornená na diagrame nižšie, kde faktová tabuľka spája dimenzionálne tabuľky:

![Hviezdicový model](https://github.com/patrikrajnoha/IMDb-ETL/blob/f0996253cf266406233c2b03f563dff288ac71e5/star_schema.png)

---

Tento model umožňuje detailnú analýzu filmových údajov, napríklad priemerných hodnotení na základe žánrov, krajín alebo času hodnotení.
