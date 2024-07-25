CREATE TYPE MIME_type AS ENUM (
    'image/jpeg', 'image/png', 'image/gif', 'image/webp', 'image/svg+xml'
);

CREATE TYPE character_role AS ENUM (
    'leading', 'supporting', 'background'
);

CREATE TYPE gender AS ENUM (
    'male', 'female', 'non-binary'
);

CREATE TABLE "file" (
    "id" SERIAL NOT NULL UNIQUE,
    "file_name" VARCHAR(50) NOT NULL,
    "MIME_type" MIME_type NOT NULL,
    "key" VARCHAR(255) NOT NULL ,
    "is_public" BOOLEAN NOT NULL DEFAULT true,
    "URL" VARCHAR(255) NOT NULL UNIQUE,
    "created_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY("id")
);

CREATE TABLE "country" (
    "id" SERIAL NOT NULL UNIQUE,
    "title" VARCHAR(255) NOT NULL UNIQUE,
    "flag_logo_id" INTEGER,
    "flag_hexadecimal" VARCHAR(5) UNIQUE,
    "created_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY("id"), 
    FOREIGN KEY("flag_logo_id") REFERENCES "file"("id")
);

CREATE TABLE "person" (
    "id" SERIAL NOT NULL UNIQUE,
    "first_name" VARCHAR(50) NOT NULL,
    "last_name" VARCHAR(50) NOT NULL,
    "profile_picture_id" INTEGER UNIQUE,
    "date_of_birth" DATE,
    "country" INTEGER NOT NULL,
    "biography" TEXT,
    "gender" gender,
    "created_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY("id"),
    FOREIGN KEY("country") REFERENCES "country"("id"),
    FOREIGN KEY("profile_picture_id") REFERENCES "file"("id")
);

CREATE TABLE "user" (
    "id" SERIAL NOT NULL UNIQUE,
    "username" VARCHAR(30) NOT NULL UNIQUE,
    "first_name" VARCHAR(50) NOT NULL CHECK (LENGTH("first_name") >= 2),
    "last_name" VARCHAR(50) NOT NULL CHECK (LENGTH("last_name") >= 2),
    "email" VARCHAR(255) NOT NULL,
    "password" VARCHAR(20) NOT NULL CHECK (LENGTH("password") BETWEEN 4 AND 20),
    "profile_picture_id" INTEGER UNIQUE,
    "created_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY("id"),
    FOREIGN KEY("profile_picture_id") REFERENCES "file"("id")
);

CREATE TABLE "movie" (
    "id" SERIAL NOT NULL UNIQUE,
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
    PRIMARY KEY("id"),
    FOREIGN KEY("country_id") REFERENCES "country"("id"),
    FOREIGN KEY("director_id") REFERENCES "person"("id"),
    FOREIGN KEY("poster_id") REFERENCES "file"("id")
);

CREATE TABLE "character" (
    "id" SERIAL NOT NULL UNIQUE,
    "name" VARCHAR(255) NOT NULL,
    "description" TEXT NOT NULL,
    "role" character_role NOT NULL,
    "created_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY("id")
);

CREATE TABLE "favorite_movie" (
    "id" SERIAL NOT NULL UNIQUE,
    "user_id" INTEGER NOT NULL,
    "movie_id" INTEGER NOT NULL,
    "created_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY("id"),
    FOREIGN KEY("user_id") REFERENCES "user"("id"),
    FOREIGN KEY("movie_id") REFERENCES "movie"("id")
);

CREATE TABLE "genre" (
    "id" SERIAL NOT NULL UNIQUE,
    "title" VARCHAR(255) NOT NULL UNIQUE,
    "created_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY("id")
);

CREATE TABLE "movie_genre" (
    "id" SERIAL NOT NULL UNIQUE,
    "movie_id" INTEGER NOT NULL,
    "genre_id" INTEGER NOT NULL,
    "created_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY("id"),
    FOREIGN KEY("movie_id") REFERENCES "movie"("id"),
    FOREIGN KEY("genre_id") REFERENCES "genre"("id")
);

CREATE TABLE "movie_cast" (
    "id" SERIAL NOT NULL UNIQUE,
    "movie_id" INTEGER NOT NULL,
    "actor_id" INTEGER,
    "character_id" INTEGER,
    "created_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY("id"),
    FOREIGN KEY("movie_id") REFERENCES "movie"("id"),
    FOREIGN KEY("actor_id") REFERENCES "person"("id"),
    FOREIGN KEY("character_id") REFERENCES "character"("id")
);

CREATE TABLE "person_image" (
    "id" SERIAL NOT NULL UNIQUE,
    "file_id" INTEGER NOT NULL,
    "person_id" INTEGER NOT NULL,
    "created_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY("id"),
    FOREIGN KEY("file_id") REFERENCES "file"("id"),
    FOREIGN KEY("person_id") REFERENCES "person"("id")
);

-- (addictionaly) constraints for movie_cast table to prohibit duplicating actors and characters for same movie
ALTER TABLE movie_cast 
ADD CONSTRAINT unique_movie_character UNIQUE (movie_id, character_id),
ADD CONSTRAINT unique_movie_actor UNIQUE (movie_id, actor_id);