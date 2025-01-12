USE DATABASE IMDb_SQUIRREL;

CREATE STAGE imdb_squirrel;

DROP TABLE IF EXISTS movie;

CREATE TABLE movie (
    id VARCHAR(10) NOT NULL,
    title VARCHAR(200) DEFAULT NULL,
    year INT DEFAULT NULL,
    date_published DATE DEFAULT null,
    duration INT,
    country VARCHAR(250),
    worlwide_gross_income VARCHAR(30),
    languages VARCHAR(200),
    production_company VARCHAR(200),
    PRIMARY KEY (id)
);

DROP TABLE IF EXISTS genre;

CREATE TABLE genre (
    movie_id VARCHAR(10),
    genre VARCHAR(20),
    PRIMARY KEY (movie_id, genre)
);

CREATE TABLE names (
    id varchar(10) NOT NULL,
    name varchar(100) DEFAULT NULL,
    height int DEFAULT NULL,
    date_of_birth date DEFAULT null,
    known_for_movies varchar(100),
    PRIMARY KEY (id)
);

DROP TABLE IF EXISTS role_mapping;

CREATE TABLE role_mapping (
    movie_id VARCHAR(10) NOT NULL,
    name_id VARCHAR(10) NOT NULL,
    category VARCHAR(10),
    PRIMARY KEY (movie_id, name_id)
);

DROP TABLE IF EXISTS director_mapping;

CREATE TABLE director_mapping (
    movie_id VARCHAR(10),
    name_id VARCHAR(10),
    PRIMARY KEY (movie_id, name_id)
);

DROP TABLE IF EXISTS ratings;

CREATE TABLE ratings (
    movie_id VARCHAR(10) NOT NULL,
    avg_rating DECIMAL(3, 1),
    total_votes INT,
    median_rating INT,
    PRIMARY KEY (movie_id)
);

COPY INTO movie
FROM @IMDB_SQUIRREL / movie.csv FILE_FORMAT = (
        TYPE = 'CSV' FIELD_OPTIONALLY_ENCLOSED_BY = '"' SKIP_HEADER = 1
    );

COPY INTO genre
FROM @IMDB_SQUIRREL / genre.csv FILE_FORMAT = (
        TYPE = 'CSV' FIELD_OPTIONALLY_ENCLOSED_BY = '"' SKIP_HEADER = 1
    );

COPY INTO names
FROM
    @IMDB_SQUIRREL / names.csv FILE_FORMAT = (
        TYPE = 'CSV' FIELD_OPTIONALLY_ENCLOSED_BY = '"' SKIP_HEADER = 1
    ) ON_ERROR = 'CONTINUE';

COPY INTO role_mapping
FROM @IMDB_SQUIRREL / role_mapping.csv FILE_FORMAT = (
        TYPE = 'CSV' FIELD_OPTIONALLY_ENCLOSED_BY = '"' SKIP_HEADER = 1
    );

COPY INTO director_mapping
FROM @IMDB_SQUIRREL / director_mapping.csv FILE_FORMAT = (
        TYPE = 'CSV' FIELD_OPTIONALLY_ENCLOSED_BY = '"' SKIP_HEADER = 1
    );

COPY INTO ratings
FROM @IMDB_SQUIRREL / ratings.csv FILE_FORMAT = (
        TYPE = 'CSV' FIELD_OPTIONALLY_ENCLOSED_BY = '"' SKIP_HEADER = 1
    );

DROP TABLE IF EXISTS dim_names;

CREATE TABLE dim_names AS
SELECT n.id AS names_id, n.name, n.date_of_birth
FROM names n;

CREATE TABLE dim_movie AS
SELECT
    m.id AS movie_id,
    m.title,
    m.date_published,
    m.duration,
    m.country,
    m.languages,
    m.production_company,
    g.genre AS genre_name
FROM movie m
    JOIN genre g ON m.id = g.movie_id;

CREATE TABLE dim_names AS
SELECT n.id AS names_id, n.name, n.date_of_birth, r.category
FROM names n
    JOIN role_mapping r ON n.id = r.name_id;

DROP TABLE IF EXISTS sdim_genre;

CREATE TABLE sdim_genre AS
SELECT CONCAT(g.movie_id, '_', g.genre) AS sdim_genre_id, g.genre
FROM genre g;

CREATE TABLE dim_movie AS
SELECT
    m.id AS movie_id,
    m.title,
    m.date_published,
    m.duration,
    m.country,
    m.languages,
    m.production_company,
    g.genre AS category,
    CONCAT(g.movie_id, '_', g.genre) AS genre_id
FROM movie m
    JOIN genre g ON m.id = g.movie_id;

DROP TABLE IF EXISTS fact_ratings;
-- Vytvorenie tabuľky fact_ratings na základe údajov z iných tabuliek
CREATE TABLE fact_ratings AS
SELECT
    r.movie_id AS movie_id,
    -- movie_id z tabuľky ratings
    d.names_id AS names_id,
    -- names_id z tabuľky dim_names
    EXTRACT(
        YEAR
        FROM r.date
    ) AS date_id,
    -- date_id na základe roku z tabuľky ratings
    EXTRACT(
        HOUR
        FROM r.time
    ) AS time_id,
    -- time_id na základe hodiny z tabuľky ratings
    r.average_rating AS avg_rating,
    -- priemerné hodnotenie z tabuľky ratings
    r.total_votes AS total_votes,
    -- celkový počet hlasov z tabuľky ratings
    r.median_rating AS median_rating -- medián hodnotenia z tabuľky ratings
FROM
    ratings r
    JOIN dim_movie m ON r.movie_id = m.movie_id -- spojenie s tabuľkou dim_movie
    JOIN dim_names d ON r.names_id = d.names_id;

DROP TABLE IF EXISTS fact_ratings;

CREATE TABLE fact_ratings (
    rating_id INT UNSIGNED NOT NULL AUTO_INCREMENT,
    movie_id VARCHAR(10) NOT NULL,
    names_id VARCHAR(10) NOT NULL,
    date_id INT NOT NULL,
    time_id INT NOT NULL,
    avg_rating DECIMAL(3, 1) NOT NULL,
    total_votes INT(11) NOT NULL,
    median_rating INT(11) NOT NULL,
    PRIMARY KEY (rating_id),
    INDEX fk_fact_ratings_dim_movie_idx (movie_id ASC) VISIBLE,
    INDEX fk_fact_ratings_dim_names1_idx (names_id ASC) VISIBLE,
    INDEX fk_fact_ratings_dim_time1_idx (time_id ASC) VISIBLE,
    CONSTRAINT fk_fact_ratings_dim_movie FOREIGN KEY (movie_id) REFERENCES mydb.dim_movie (movie_id) ON DELETE NO ACTION ON UPDATE NO ACTION,
    CONSTRAINT fk_fact_ratings_dim_names1 FOREIGN KEY (names_id) REFERENCES mydb.dim_names (names_id) ON DELETE NO ACTION ON UPDATE NO ACTION,
    CONSTRAINT fk_fact_ratings_dim_time1 FOREIGN KEY (time_id) REFERENCES mydb.dim_time (time_id) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE = InnoDB;

INSERT INTO
    fact_ratings (
        movie_id,
        names_id,
        date_id,
        time_id,
        avg_rating,
        total_votes,
        median_rating
    )
SELECT
    r.movie_id,
    r.names_id,
    EXTRACT(
        YEAR
        FROM r.date
    ) AS date_id,
    EXTRACT(
        HOUR
        FROM r.time
    ) AS time_id,
    r.average_rating AS avg_rating,
    r.total_votes AS total_votes,
    r.median_rating AS median_rating
FROM ratings r
    JOIN mydb.dim_movie m ON r.movie_id = m.movie_id
    JOIN mydb.dim_names d ON r.names_id = d.names_id;

CREATE TABLE fact_ratings AS
SELECT
    ROW_NUMBER() OVER (
        ORDER BY r.movie_id
    ) AS fact_rating_id,
    r.movie_id AS movie_id,
    n.names_id AS names_id
FROM
    ratings AS r
    JOIN dim_movie AS m ON r.movie_id = m.movie_id
    LEFT JOIN dim_names AS n ON r.movie_id = n.names_id
WHERE
    NOT r.movie_id IS NULL
    AND NOT n.names_id IS NULL;