SELECT
    "user".id,
    "user".username,
    ARRAY_AGG(favorite_movie.movie_id) AS "Favorite movie id's"
FROM
    "user"
LEFT JOIN
    favorite_movie ON "user".id = favorite_movie.user_id
GROUP BY
    "user".id, "user".username
