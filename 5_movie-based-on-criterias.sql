SELECT
    m.id,
    m.title,
    m.release_date AS "release date",
    m.duration,
    m.description,
   	json_build_object(
        'id', f.id,
        'file_name', f.file_name,
        'MIME_type', f."MIME_type",
        'URL', f."URL"
    ) AS "poster",
    json_build_object(
        'id', p.id,
        'first_name', p.first_name,
        'last_name', p.last_name
    ) AS "director"
FROM
    movie m
JOIN
    person p ON m.director_id = p.id
LEFT JOIN
    file f ON m.poster_id = f.id
JOIN
    movie_genre mg ON m.id = mg.movie_id
JOIN
    genre g ON mg.genre_id = g.id
WHERE
    m.country_id = 1
    AND DATE_PART('year', m.release_date) >= 2022
    AND m.duration > INTERVAL '2 hours 15 minutes'
    AND g.title IN ('Action', 'Drama')
GROUP BY
    m.id, f.id, p.id
ORDER BY
    m.release_date DESC