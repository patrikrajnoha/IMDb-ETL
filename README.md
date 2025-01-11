# IMDb-ETL

# Dimenzionálny model

Navrhnutý bol **hviezdicový model (star schema)**, ktorý slúži na efektívnu analýzu dát. Centrálnym bodom je faktová tabuľka `fact_ratings`, ktorá je prepojená s viacerými dimenziami. Tento model poskytuje prehľadnú štruktúru pre implementáciu a pochopenie údajov o filmoch a hodnoteniach.

## Štruktúra hviezdicového modelu

Hviezdicový model obsahuje tieto dimenzie:

- **dim_names**: Obsahuje podrobné informácie o osobách (napr. mená a dátumy narodenia).
- **dim_movie**: Obsahuje podrobné informácie o filmoch (napr. názov, dátum vydania, krajinu, jazyk, produkčnú spoločnosť a kategóriu).
- **dim_time**: Obsahuje podrobné časové údaje (napr. hodiny, AM/PM).
- **dim_date**: Obsahuje informácie o dátumoch hodnotení (napr. deň, mesiac, rok, štvrťrok).
- **sdim_genre**: Obsahuje kategórie žánrov filmov.

Centrálna faktová tabuľka `fact_ratings` obsahuje údaje o hodnoteniach filmov vrátane prepojení na vyššie uvedené dimenzie.

## Diagram

Nižšie je znázornená štruktúra hviezdicového modelu, ktorá ukazuje prepojenie medzi faktovou tabuľkou a jednotlivými dimenziami:

![Star Schema](https://github.com/patrikrajnoha/IMDb-ETL/blob/main/star_schema.png)

Tento model umožňuje efektívnu analýzu dát a poskytuje flexibilitu pri práci s veľkými objemami údajov.
