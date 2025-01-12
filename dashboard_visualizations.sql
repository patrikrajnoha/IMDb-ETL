-- Graf 1: Top 5 spoločností, u ktorých je rating filmov viac ako priemer
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

-- Graf 2: Počet filmov s priemerným hodnotením medzi 7 a 8
SELECT COUNT(*) AS movie_count
FROM ratings
WHERE
    avg_rating BETWEEN 7 AND 8;

-- Graf 3: Top tri krajiny s najvyšším počtom filmov
SELECT country, COUNT(*) AS movie_count
FROM movie
GROUP BY
    country
ORDER BY movie_count DESC
LIMIT 3;

-- Graf 4: Tri najčastejšie produkované žánre vo filmoch s hodnotením > 8
SELECT g.genre, COUNT(*) AS genre_count
FROM genre g
    JOIN ratings r ON g.movie_id = r.movie_id
WHERE
    r.avg_rating > 8
GROUP BY
    g.genre
ORDER BY genre_count DESC
LIMIT 3;

-- Graf 5: Priemerná dĺžka filmov podľa krajiny produkcie
SELECT m.country, AVG(m.duration) AS avg_duration
FROM movie m
WHERE
    m.duration IS NOT NULL
GROUP BY
    m.country
ORDER BY avg_duration DESC;

-- Graf 6: Filmy s najviac hlasmi v každom roku
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