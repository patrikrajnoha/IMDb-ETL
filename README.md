# IMDb ETL Projekt

Tento repozitár obsahuje implementáciu ETL procesu v Snowflake pre analýzu dát z IMDb datasetu. Cieľom projektu je spracovanie a modelovanie filmových údajov pre ďalšie analytické účely, vrátane hodnotení filmov, informácií o hercoch, režiséroch, a žánroch. Projekt využíva dátové modelovanie na podporu multidimenzionálnej analýzy a vizualizácie filmových metrík.

---

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

*Obrázok 1: Entitno-relačný diagram znázorňuje štruktúra zdrojových dát a ich prepojenia. Zahŕňa tabuľky ako `movie`, `names`, `ratings`, `genre` a ich asociácie s čalšími entitami, ako je mapovanie úloh a režisérov.*

---

## 2. Dimenzionálny model

Navrhnutý bol hviezdicový model (**star schema**), ktorý slúži na efektívnu analýzu filmových dát. Centrálna faktová tabuľka **fact_ratings** je prepojená s nasledujúcimi dimenziami:

- **dim_movie**: Obsahuje detailné údaje o filmoch, ako sú názov, dátum vydania, dĺžka filmu, produkčná spoločnosť a žánre.
- **dim_names**: Informácie o osobách, vrátane mena, dátumu narodenia a kategórie (herec/režisér).
- **dim_date**: Zahrňuje údaje o dátumoch hodnotení (deň, mesiac, rok, štvrťrok).
- **dim_time**: Podrobné časové údaje (hodina, AM/PM).
- **sdim_genre**: Špecifické údaje o žánroch filmov.

#### Hviezdicová schéma
Štruktúra hviezdicového modelu je znázornená na diagrame nižšie, kde faktová tabuľka spája dimenzionálne tabuľky:

![Hviezdicový model](https://github.com/patrikrajnoha/IMDb-ETL/blob/main/star_schema.png)

*Obrázok 2: Hviezdicový model znázorňuje faktovú tabuľku `fact_ratings` a jej prepojenie s dimenziami. Tento model podporuje rýchle dotazovanie a analytické výpočty, napríklad analýzu hodnotení podľa žánrov, času alebo krajín.*

---

## 3. ETL proces v Snowflake

### 3.1 Extrakcia dát
Dáta sa importujú zo súborov CSV do staging tabuliek pomocou príkazu `COPY INTO`.

Príklad:
```sql
COPY INTO movie
FROM @IMDB_SQUIRREL/movie.csv
FILE_FORMAT = (TYPE = 'CSV' SKIP_HEADER = 1);
```

Použitie `ON_ERROR = 'CONTINUE'` zabezpečí, že chyby nebudú proces zastavovať.

### 3.2 Transformácia dát
Vyčistenie a transformácia dát pre dimenzie a faktové tabuľky. 

Príklad pre dimenziu `dim_movie`:
```sql
CREATE TABLE dim_movie AS
SELECT 
    m.id AS movie_id,
    m.title,
    m.date_published,
    m.duration,
    m.country,
    m.languages,
    m.production_company,
    g.genre AS category
FROM 
    movie m
JOIN 
    genre g
ON 
    m.id = g.movie_id;
```

### 3.3 Načítanie dát
Prepojenie dimenzií a naplnenie faktovej tabuľky:
```sql
CREATE TABLE fact_ratings AS
SELECT 
    r.movie_id,
    n.names_id,
    r.avg_rating,
    r.total_votes,
    r.median_rating
FROM 
    ratings r
JOIN 
    dim_movie m ON r.movie_id = m.movie_id
LEFT JOIN 
    dim_names n ON r.movie_id = n.names_id;
```

---

## 4. Vizualizácia dát

### Dashboard

Celkový dashboard znázorňuje vizualizácie hlavných metrík a odpovede na analytické otázky.

![Dashboard](https://github.com/patrikrajnoha/IMDb-ETL/blob/main/imdb_dashboard.png)

### Grafy a vizualizácie:

1. **Top 5 spoločností s hodnoteniami nad priemerom**
   Tento graf zobrazuje päť spoločností s najvyšším priemerným hodnotením filmov, ktoré presahujú celkový priemer hodnotení. Pomáha identifikovať spoločnosti, ktoré produkujú kvalitné filmy.
   ```sql
   WITH
       avg_rating AS (
           SELECT AVG(avg_rating) AS overall_avg_rating
           FROM ratings
       )
   SELECT m.production_company, AVG(r.avg_rating) AS avg_rating
   FROM movie m
       JOIN ratings r ON m.id = r.movie_id
   WHERE
       r.avg_rating > (
           SELECT overall_avg_rating
           FROM avg_rating
       )
   GROUP BY
       m.production_company
   ORDER BY avg_rating DESC
   LIMIT 5;
   ```
   ![Graf 1](https://github.com/patrikrajnoha/IMDb-ETL/blob/main/grafy/graf_4.png)

2. **Počet filmov s priemerným hodnotením medzi 7 a 8**
   Tento graf ukazuje celkový počet filmov, ktoré majú hodnotenie v rozmedzí 7 až 8. Pomáha pochopiť, koľko filmov spadá do tejto hodnotiacej kategórie.
   ```sql
   SELECT COUNT(*) AS movie_count
   FROM ratings
   WHERE
       avg_rating BETWEEN 7 AND 8;
   ```
   ![Graf 2](https://github.com/patrikrajnoha/IMDb-ETL/blob/main/grafy/graf_1.png)

3. **Top tri krajiny s najvyšším počtom filmov**
   Graf zobrazuje tri krajiny, ktoré produkovali najväčší počet filmov. Táto informácia môže byť užitočná na identifikáciu dominantných hráčov vo filmovom priemysle podľa krajiny.
   ```sql
   SELECT country, COUNT(*) AS movie_count
   FROM movie
   GROUP BY
       country
   ORDER BY movie_count DESC
   LIMIT 3;
   ```
   ![Graf 3](https://github.com/patrikrajnoha/IMDb-ETL/blob/main/grafy/graf_3.png)

4. **Najčastejšie žánre vo filmoch s hodnotením > 8**
   Tento graf ukazuje najčastejšie žánre vo filmoch, ktoré získali hodnotenie vyššie ako 8. Pomáha identifikovať populárne žánre medzi vysoko hodnotenými filmami.
   ```sql
   SELECT g.genre, COUNT(*) AS genre_count
   FROM genre g
       JOIN ratings r ON g.movie_id = r.movie_id
   WHERE
       r.avg_rating > 8
   GROUP BY
       g.genre
   ORDER BY genre_count DESC
   LIMIT 3;
   ```
   ![Graf 4](https://github.com/patrikrajnoha/IMDb-ETL/blob/main/grafy/graf_5.png)

5. **Priemerná dĺžka filmov podľa krajiny produkcie**
   Graf zobrazuje priemernú dĺžku filmov pre každú krajinu produkcie. Pomáha pochopiť rozdiely v dĺžke filmov medzi jednotlivými krajinami.
   ```sql
   SELECT m.country, AVG(m.duration) AS avg_duration
   FROM movie m
   WHERE
       m.duration IS NOT NULL
   GROUP BY
       m.country
   ORDER BY avg_duration DESC;
   ```
   ![Graf 5](https://github.com/patrikrajnoha/IMDb-ETL/blob/main/grafy/graf_6.png)

6. **Filmy s najviac hlasmi v každom roku**
   Tento graf zobrazuje filmy, ktoré získali najviac hlasov v každom roku. Pomáha identifikovať najpopulárnejšie filmy v daných rokoch.
   ```sql
   WITH
       yearly_max_votes AS (
           SELECT YEAR(m.date_published) AS release_year, MAX(r.total_votes) AS max_votes
           FROM movie m
               JOIN ratings r ON m.id = r.movie_id
           GROUP BY
               YEAR(m.date_published)
       )
   SELECT m.title, YEAR(m.date_published) AS release_year, r.total_votes
   FROM
       movie m
       JOIN ratings r ON m.id = r.movie_id
       JOIN yearly_max_votes y ON YEAR(m.date_published) = y.release_year
       AND r.total_votes = y.max_votes
   ORDER BY release_year;
   ```
   ![Graf 6](https://github.com/patrikrajnoha/IMDb-ETL/blob/main/grafy/graf_2.png)

---

**Autor:** Patrik Rajnoha

