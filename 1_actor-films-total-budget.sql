SELECT
    person.id,
    person.first_name AS "First name",
    person.last_name AS "Last name",
    SUM(movie.budget) AS "Total movies budget"
FROM
    person
JOIN
    movie_cast ON person.id = movie_cast.actor_id
LEFT JOIN
    movie ON movie_cast.movie_id = movie.id
GROUP BY
    person.id, person.first_name, person.last_name
ORDER BY
    "Total movies budget" DESC