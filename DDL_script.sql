CREATE TYPE mime_type AS ENUM (
    'image/jpeg', 'image/png', 'image/gif', 'image/webp', 'image/svg+xml'
);

CREATE TYPE character_role AS ENUM (
    'leading', 'supporting', 'background'
);

CREATE TYPE gender AS ENUM (
    'male', 'female', 'non-binary'
);

CREATE TABLE "file" (
    "id" SERIAL PRIMARY KEY,
    "file_name" VARCHAR(50) NOT NULL,
    "MIME_type" mime_type NOT NULL,
    "key" VARCHAR(255) NOT NULL,
    "is_public" BOOLEAN NOT NULL DEFAULT true,
    "URL" VARCHAR(255) NOT NULL UNIQUE,
    "created_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE "country" (
    "id" SERIAL PRIMARY KEY,
    "code" CHAR(2),
    "flag_logo_id" INTEGER UNIQUE,
    "created_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY ("flag_logo_id") REFERENCES "file" ("id")
);

CREATE TABLE "person" (
    "id" SERIAL PRIMARY KEY,
    "first_name" VARCHAR(50) NOT NULL,
    "last_name" VARCHAR(50) NOT NULL,
    "profile_picture_id" INTEGER UNIQUE,
    "date_of_birth" DATE,
    "country" INTEGER NOT NULL,
    "biography" TEXT,
    "gender" gender,
    "created_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY("country") REFERENCES "country"("id"),
    FOREIGN KEY("profile_picture_id") REFERENCES "file"("id")
);

CREATE TABLE "user" (
    "id" SERIAL PRIMARY KEY,
    "username" VARCHAR(30) NOT NULL UNIQUE,
    "first_name" VARCHAR(50) NOT NULL CHECK (LENGTH("first_name") >= 2),
    "last_name" VARCHAR(50) NOT NULL CHECK (LENGTH("last_name") >= 2),
    "email" VARCHAR(255) NOT NULL UNIQUE,
    "password" VARCHAR(20) NOT NULL CHECK (LENGTH("password") BETWEEN 4 AND 20),
    "profile_picture_id" INTEGER UNIQUE,
    "created_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY("profile_picture_id") REFERENCES "file"("id")
);

CREATE TABLE "movie" (
    "id" SERIAL PRIMARY KEY,
    "title" VARCHAR(255) NOT NULL,
    "description" TEXT,
    "budget" MONEY NOT NULL,
    "release_date" DATE NOT NULL,
    "duration" INTERVAL NOT NULL,
    "country_id" INTEGER NOT NULL,
    "director_id" INTEGER NOT NULL,
    "poster_id" INTEGER UNIQUE,
    "created_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY("country_id") REFERENCES "country"("id"),
    FOREIGN KEY("director_id") REFERENCES "person"("id"),
    FOREIGN KEY("poster_id") REFERENCES "file"("id")
);

CREATE TABLE "character" (
    "id" SERIAL PRIMARY KEY,
    "name" VARCHAR(255) NOT NULL,
    "description" TEXT NOT NULL,
    "role" character_role NOT NULL,
    "created_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE "favorite_movie" (
    "id" SERIAL PRIMARY KEY,
    "user_id" INTEGER NOT NULL,
    "movie_id" INTEGER NOT NULL,
    "created_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY("user_id") REFERENCES "user"("id"),
    FOREIGN KEY("movie_id") REFERENCES "movie"("id")
);

CREATE TABLE "genre" (
    "id" SERIAL PRIMARY KEY,
    "title" VARCHAR(255) NOT NULL UNIQUE,
    "created_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE "movie_genre" (
    "id" SERIAL PRIMARY KEY,
    "movie_id" INTEGER NOT NULL,
    "genre_id" INTEGER NOT NULL,
    "created_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY("movie_id") REFERENCES "movie"("id"),
    FOREIGN KEY("genre_id") REFERENCES "genre"("id")
);

CREATE TABLE "movie_cast" (
    "id" SERIAL PRIMARY KEY,
    "movie_id" INTEGER NOT NULL,
    "actor_id" INTEGER,
    "character_id" INTEGER,
    "created_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY("movie_id") REFERENCES "movie"("id"),
    FOREIGN KEY("actor_id") REFERENCES "person"("id"),
    FOREIGN KEY("character_id") REFERENCES "character"("id")
);

CREATE TABLE "person_image" (
    "id" SERIAL PRIMARY KEY,
    "file_id" INTEGER NOT NULL UNIQUE,
    "person_id" INTEGER NOT NULL,
    "created_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY("file_id") REFERENCES "file"("id"),
    FOREIGN KEY("person_id") REFERENCES "person"("id")
);

-- Addictionaly
-- constraints for movie_cast table to prohibit duplicating actors and characters for same movie
ALTER TABLE movie_cast 
ADD CONSTRAINT unique_movie_character UNIQUE (movie_id, character_id),
ADD CONSTRAINT unique_movie_actor UNIQUE (movie_id, actor_id);

-- trigger to update updated_at column
CREATE OR REPLACE FUNCTION update_modified_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION create_update_trigger_for_all_tables() RETURNS void AS $$
DECLARE
    tbl_name text;
    trigger_name text;
    trigger_sql text;
BEGIN
    FOR tbl_name IN 
        SELECT table_name
        FROM information_schema.tables 
        WHERE table_schema = 'public' 
          AND table_type = 'BASE TABLE'
    LOOP
        IF EXISTS (
            SELECT 1
            FROM information_schema.columns
            WHERE table_schema = 'public'
              AND table_name = tbl_name
              AND column_name = 'updated_at'
        ) THEN
            trigger_name := 'update_' || tbl_name || '_modtime';
            trigger_sql := 'CREATE TRIGGER ' || quote_ident(trigger_name) || 
                           ' BEFORE UPDATE ON ' || quote_ident(tbl_name) || 
                           ' FOR EACH ROW EXECUTE FUNCTION update_modified_column()';
            
            EXECUTE trigger_sql;
        END IF;
    END LOOP;
END;
$$ LANGUAGE plpgsql;

SELECT create_update_trigger_for_all_tables();

-- Mocked data
INSERT INTO "file" (file_name, "MIME_type", key, is_public, "URL") VALUES
('usa_flag.svg', 'image/svg+xml', 'flags/usa', true, 'https://example.com/flags/usa.svg'),
('uk_flag.svg', 'image/svg+xml', 'flags/uk', true, 'https://example.com/flags/uk.svg'),
('nolan.jpg', 'image/jpeg', 'person/nolan', true, 'https://example.com/person/nolan.jpg'),
('nolan_childhood.jpg', 'image/jpeg', 'person/nolan_childhood', true, 'https://example.com/person/nolan_childhood.jpg'),
('dicaprio.jpg', 'image/jpeg', 'person/dicaprio', true, 'https://example.com/person/dicaprio.jpg'),
('dicaprio_family.jpg', 'image/jpeg', 'person/dicaprio_family', true, 'https://example.com/person/dicaprio_family.jpg'),
('spielberg.jpg', 'image/jpeg', 'person/spielberg', true, 'https://example.com/person/spielberg.jpg'),
('inception_poster.jpg', 'image/jpeg', 'posters/inception', true, 'https://example.com/posters/inception.jpg'),
('tenet_poster.jpg', 'image/jpeg', 'posters/tenet', true, 'https://example.com/posters/tenet.jpg');

INSERT INTO "country" (code, flag_logo_id) VALUES
('US', (SELECT id FROM "file" WHERE file_name = 'usa_flag.svg')),
('GB', (SELECT id FROM "file" WHERE file_name = 'uk_flag.svg')),
('FR', NULL);

INSERT INTO "person" (first_name, last_name, profile_picture_id, date_of_birth, country, biography, gender) VALUES
('Christopher', 'Nolan', (SELECT id FROM "file" WHERE file_name = 'nolan.jpg'), '1970-07-30', (SELECT id FROM "country" WHERE code = 'GB'), 'British-American film director', 'male'),
('Leonardo', 'DiCaprio', (SELECT id FROM "file" WHERE file_name = 'dicaprio.jpg'), '1974-11-11', (SELECT id FROM "country" WHERE code = 'US'), 'American actor', 'male'),
('Ellen', 'Page', NULL, '1987-02-21', (SELECT id FROM "country" WHERE code = 'US'), 'Canadian actress', 'non-binary'),
('Tom', 'Hardy', NULL, '1977-09-15', (SELECT id FROM "country" WHERE code = 'GB'), 'English actor', 'male'),
('Steven', 'Spielberg', (SELECT id FROM "file" WHERE file_name = 'spielberg.jpg'), '1946-12-18', (SELECT id FROM "country" WHERE code = 'US'), 'American filmmaker', 'male'),
('Tom', 'Hanks', NULL, '1956-07-09', (SELECT id FROM "country" WHERE code = 'US'), 'American actor', 'male'),
('Cillian', 'Murphy',NULL, '1976-05-25', (SELECT id FROM "country" WHERE code = 'GB'), 'Irish actor known for his roles in Peaky Blinders and Inception', 'male'),
('Emily', 'Blunt',NULL, '1983-02-23', (SELECT id FROM "country" WHERE code = 'GB'), 'British-American actress known for her roles in A Quiet Place and Mary Poppins Returns', 'female'),
('Robert', 'Downey Jr.',NULL, '1965-04-04', (SELECT id FROM "country" WHERE code = 'US'), 'American actor known for his roles as Iron Man in the Marvel Cinematic Universe', 'male');

INSERT INTO "user" (username, first_name, last_name, email, password, profile_picture_id) VALUES
('moviefan1', 'John', 'Doe', 'john@example.com', 'password123', NULL),
('cinephile', 'Jane', 'Smith', 'jane@example.com', 'securepass', NULL),
('filmcritic', 'Bob', 'Johnson', 'bob@example.com', 'critiquepw', NULL),
('hater', 'Hi', 'Hi', 'hihihater@example.com', 'iamhater', NULL);

INSERT INTO "movie" (title, description, budget, release_date, duration, country_id, director_id, poster_id) VALUES
('Inception', 'A thief who enters the dreams of others', 160000000, '2010-07-16', '02:28:00', 
 (SELECT id FROM "country" WHERE code = 'US'),
 (SELECT id FROM "person" WHERE first_name = 'Christopher' AND last_name = 'Nolan'),
 (SELECT id FROM "file" WHERE file_name = 'inception_poster.jpg')),
('Interstellar', 'A team of explorers travel through a wormhole in space', 165000000, '2014-11-07', '02:49:00',
 (SELECT id FROM "country" WHERE code = 'US'),
 (SELECT id FROM "person" WHERE first_name = 'Christopher' AND last_name = 'Nolan'),
 NULL),
('Saving Private Ryan', 'A group of U.S. soldiers go behind enemy lines to retrieve a paratrooper', 70000000, '1998-07-24', '02:49:00',
 (SELECT id FROM "country" WHERE code = 'US'),
 (SELECT id FROM "person" WHERE first_name = 'Steven' AND last_name = 'Spielberg'),
 NULL),
('Tenet', 'Armed with only one word, Tenet, a CIA operative journeys through a twilight world of international espionage', 200000000, '2020-08-26', '02:30:00',
 (SELECT id FROM "country" WHERE code = 'GB'),
 (SELECT id FROM "person" WHERE first_name = 'Christopher' AND last_name = 'Nolan'),
 (SELECT id FROM "file" WHERE file_name = 'tenet_poster.jpg')),
 ('Oppenheimer',
    'The story of American scientist J. Robert Oppenheimer and his role in the development of the atomic bomb.',
    100000000,
    '2023-07-21',
    '03:00:00',
    (SELECT id FROM "country" WHERE code = 'US'),
    (SELECT id FROM "person" WHERE first_name = 'Christopher' AND last_name = 'Nolan'), NULL
),
(
    'The Fabelmans',
    'A semi-autobiography based on Spielberg''s own childhood, exploring the discovery of the power of films and dreams.',
    40000000,
    '2022-11-23',
    '02:31:00',
    (SELECT id FROM "country" WHERE code = 'US'),
    (SELECT id FROM "person" WHERE first_name = 'Steven' AND last_name = 'Spielberg'),
    NULL
),
('Short Drama', NULL, 100000000, '2023-05-28', '01:00:00',
 (SELECT id FROM "country" WHERE code = 'US'),
 (SELECT id FROM "person" WHERE first_name = 'Steven' AND last_name = 'Spielberg'),
 NULL);

INSERT INTO "character" (name, description, role) VALUES
('Cobb', 'The protagonist, a skilled extractor', 'leading'),
('Ariadne', 'The architect, designs the dreams', 'supporting'),
('Cooper', 'Former NASA pilot', 'leading'),
('Captain Miller', 'U.S. Army Ranger captain', 'leading'),
('The Protagonist', 'CIA operative', 'leading'),
('J. Robert Oppenheimer', 'American physicist and director of the Manhattan Project', 'leading'),
('Katherine "Kitty" Oppenheimer', 'Biologist and botanist, wife of J. Robert Oppenheimer', 'supporting'),
('Lewis Strauss', 'United States Atomic Energy Commission (AEC) chairman', 'supporting');

INSERT INTO "favorite_movie" (user_id, movie_id) VALUES
((SELECT id FROM "user" WHERE username = 'moviefan1'), (SELECT id FROM "movie" WHERE title = 'Inception')),
((SELECT id FROM "user" WHERE username = 'moviefan1'), (SELECT id FROM "movie" WHERE title = 'Interstellar')),
((SELECT id FROM "user" WHERE username = 'cinephile'), (SELECT id FROM "movie" WHERE title = 'Saving Private Ryan')),
((SELECT id FROM "user" WHERE username = 'cinephile'), (SELECT id FROM "movie" WHERE title = 'Inception')),
((SELECT id FROM "user" WHERE username = 'filmcritic'), (SELECT id FROM "movie" WHERE title = 'Tenet'));

INSERT INTO "genre" (title) VALUES
('Science Fiction'),
('Action'),
('Thriller'),
('Drama'),
('War');

INSERT INTO "movie_genre" (movie_id, genre_id) VALUES
((SELECT id FROM "movie" WHERE title = 'Inception'), (SELECT id FROM "genre" WHERE title = 'Science Fiction')),
((SELECT id FROM "movie" WHERE title = 'Inception'), (SELECT id FROM "genre" WHERE title = 'Action')),
((SELECT id FROM "movie" WHERE title = 'Inception'), (SELECT id FROM "genre" WHERE title = 'Thriller')),
((SELECT id FROM "movie" WHERE title = 'Interstellar'), (SELECT id FROM "genre" WHERE title = 'Science Fiction')),
((SELECT id FROM "movie" WHERE title = 'Interstellar'), (SELECT id FROM "genre" WHERE title = 'Drama')),
((SELECT id FROM "movie" WHERE title = 'Saving Private Ryan'), (SELECT id FROM "genre" WHERE title = 'War')),
((SELECT id FROM "movie" WHERE title = 'Saving Private Ryan'), (SELECT id FROM "genre" WHERE title = 'Drama')),
((SELECT id FROM "movie" WHERE title = 'Tenet'), (SELECT id FROM "genre" WHERE title = 'Action')),
((SELECT id FROM "movie" WHERE title = 'Tenet'), (SELECT id FROM "genre" WHERE title = 'Thriller')),
((SELECT id FROM "movie" WHERE title = 'Tenet'), (SELECT id FROM "genre" WHERE title = 'Science Fiction')),
((SELECT id FROM "movie" WHERE title = 'Oppenheimer'), (SELECT id FROM "genre" WHERE title = 'Action')),
((SELECT id FROM "movie" WHERE title = 'Short Drama'), (SELECT id FROM "genre" WHERE title = 'Drama'));

INSERT INTO "movie_cast" (movie_id, actor_id, character_id) VALUES
((SELECT id FROM "movie" WHERE title = 'Inception'),
 (SELECT id FROM "person" WHERE first_name = 'Leonardo' AND last_name = 'DiCaprio'),
 (SELECT id FROM "character" WHERE name = 'Cobb')),
((SELECT id FROM "movie" WHERE title = 'Inception'),
 (SELECT id FROM "person" WHERE first_name = 'Ellen' AND last_name = 'Page'),
 (SELECT id FROM "character" WHERE name = 'Ariadne')),
((SELECT id FROM "movie" WHERE title = 'Inception'),
 (SELECT id FROM "person" WHERE first_name = 'Tom' AND last_name = 'Hardy'),
 NULL),
((SELECT id FROM "movie" WHERE title = 'Interstellar'),
 (SELECT id FROM "person" WHERE first_name = 'Leonardo' AND last_name = 'DiCaprio'),
 (SELECT id FROM "character" WHERE name = 'Cooper')),
((SELECT id FROM "movie" WHERE title = 'Saving Private Ryan'),
 (SELECT id FROM "person" WHERE first_name = 'Tom' AND last_name = 'Hanks'),
 (SELECT id FROM "character" WHERE name = 'Captain Miller')),
((SELECT id FROM "movie" WHERE title = 'Tenet'),
 (SELECT id FROM "person" WHERE first_name = 'Tom' AND last_name = 'Hardy'),
 (SELECT id FROM "character" WHERE name = 'The Protagonist')),
((SELECT id FROM "movie" WHERE title = 'Oppenheimer'),
 (SELECT id FROM "person" WHERE first_name = 'Cillian' AND last_name = 'Murphy'),
 (SELECT id FROM "character" WHERE name = 'J. Robert Oppenheimer')),
((SELECT id FROM "movie" WHERE title = 'Oppenheimer'),
 (SELECT id FROM "person" WHERE first_name = 'Emily' AND last_name = 'Blunt'),
 (SELECT id FROM "character" WHERE name = 'Katherine "Kitty" Oppenheimer')),
((SELECT id FROM "movie" WHERE title = 'Oppenheimer'),
 (SELECT id FROM "person" WHERE first_name = 'Robert' AND last_name = 'Downey Jr.'),
 (SELECT id FROM "character" WHERE name = 'Lewis Strauss'));

INSERT INTO "person_image" (file_id, person_id) VALUES
((SELECT id FROM "file" WHERE file_name = 'nolan_childhood.jpg'),
 (SELECT id FROM "person" WHERE first_name = 'Christopher' AND last_name = 'Nolan')),
((SELECT id FROM "file" WHERE file_name = 'dicaprio_family.jpg'),
 (SELECT id FROM "person" WHERE first_name = 'Leonardo' AND last_name = 'DiCaprio'));