SELECT
    person.id AS "Director id",
    CONCAT(person.first_name, ' ', person.last_name) AS "Director name",
    CAST(AVG(CAST(movie.budget AS numeric)) AS money) AS "Average budget"
FROM
    person
JOIN
    movie ON person.id = movie.director_id
GROUP BY
    person.id, person.first_name, person.last_name
ORDER BY
    "Average budget" DESC