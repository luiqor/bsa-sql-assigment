SELECT
    person.id,
    person.first_name AS "First name",
    person.last_name AS "Last name",
    COALESCE(SUM(movie.budget), MONEY(0)) AS "Total movies budget"
FROM
    person
LEFT JOIN
    movie_cast ON person.id = movie_cast.actor_id
LEFT JOIN
    movie ON movie_cast.movie_id = movie.id
GROUP BY
    person.id, person.first_name, person.last_name
ORDER BY
    "Total movies budget" DESC