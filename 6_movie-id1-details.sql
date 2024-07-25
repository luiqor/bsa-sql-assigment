SELECT
    m.id,
    m.title,
    m.release_date AS "release date",
    m.duration,
    m.description,
    (SELECT
	    json_build_object(
	        'id', f.id,
	        'file_name', f.file_name,
	        'MIME_type', f."MIME_type",
	        'URL', f."URL"
    		) FROM file f WHERE f.id = m.poster_id) AS "poster",
    (SELECT
    	json_build_object(
	        'id', p.id,
	        'first_name', p.first_name,
	        'last_name', p.last_name,
	        'photo', (SELECT 
	        	json_build_object(
	            'id', f.id,
	            'file_name', f.file_name,
	            'MIME_type', f."MIME_type",
	            'URL', f."URL"
        		) FROM file f WHERE f.id = p.profile_picture_id)
    ) FROM person p WHERE p.id = m.director_id) AS "director",
    (SELECT
    	json_agg(
    		json_build_object(
		        'id', p.id,
		        'first_name', p.first_name,
		        'last_name', p.last_name,
		        'photo', (SELECT 
			        json_build_object(
			            'id', f.id,
			            'file_name', f.file_name,
			            'MIME_type', f."MIME_type",
			            'URL', f."URL"
			) FROM file f WHERE f.id = p.profile_picture_id)
    )) FROM movie_cast mc JOIN person p ON mc.actor_id = p.id WHERE mc.movie_id = m.id) AS "actors",
    (SELECT
    	json_agg(
    		json_build_object(
		        'id', g.id,
		        'title', g.title
    )) FROM movie_genre mg JOIN genre g ON mg.genre_id = g.id WHERE mg.movie_id = m.id) AS "genres" 
    FROM
    	movie m 
    WHERE
    	m.id = 1