SELECT
    movie.id,
    movie.title,
    COUNT(DISTINCT movie_cast.actor_id) AS "Actors count"
FROM
    movie
LEFT JOIN
    movie_cast ON movie.id = movie_cast.movie_id
WHERE
    movie.release_date >= CURRENT_DATE - INTERVAL '5 years'
GROUP BY
    movie.id, movie.title
ORDER BY
    movie.release_date DESC, "Actors count" DESC
