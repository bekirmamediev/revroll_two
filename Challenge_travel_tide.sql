/*
Question #1: 
Calculate the proportion of sessions abandoned in summer months (June, July, August)
and compare it to the proportion of sessions abandoned in non-summer months. 
Round the output to 3 decimal places.
*/
WITH summer AS(
	SELECT 
	ROUND(
    		CAST(SUM(CASE WHEN (flight_booked = FALSE AND hotel_booked = FALSE)  THEN 1 ELSE 0 END) AS numeric)
    		/CAST(COUNT(session_id) AS numeric)
    , 3) as summer_abandon_rate
FROM sessions
WHERE EXTRACT(month from session_end) IN (6,7,8)
),
other AS(
	SELECT 
	ROUND(
    		CAST(SUM(CASE WHEN (flight_booked = FALSE AND hotel_booked = FALSE) THEN 1 ELSE 0 END) AS numeric)
    		/CAST(COUNT(session_id) AS numeric)
    , 3) as other_abandon_rate
FROM sessions
WHERE EXTRACT(month from session_end) NOT IN (6,7,8)
)
SELECT 
	*
FROM summer
CROSS JOIN other

/*
Question #2: 
Bin customers according to their place in the session abandonment distribution as follows: 

1. number of abandonments greater than one standard deviation more than the mean. Call these customers “gt”.
2. number of abandonments fewer than one standard deviation less than the mean. Call these customers “lt”.
3. everyone else (the middle of the distribution). Call these customers “middle”.

calculate the number of customers in each group, the mean number of abandonments in each group,
and the range of abandonments in each group.
*/
WITH abandonments AS(
SELECT 
	user_id
  , COUNT(session_id) as abandoned 
FROM sessions
WHERE flight_booked = FALSE
	AND hotel_booked = FALSE
GROUP BY 1
)

SELECT 
	CASE WHEN abandoned > (SELECT STDDEV(abandoned)+AVG(abandoned) FROM abandonments) THEN 'gt'
       WHEN abandoned < (SELECT AVG(abandoned)-STDDEV(abandoned) FROM abandonments) THEN 'lt'
       ELSE 'middle'
       END AS distribution_loc
  , count(user_id) as abandon_n
  , ROUND(AVG(abandoned), 3) as abandon_avg
  , max(abandoned) - min(abandoned) AS abandon_rande
FROM abandonments 
GROUP BY 1


/*
Question #3: 
Calculate the total number of abandoned sessions and the total number of sessions 
that resulted in a booking per day, but only for customers who reside in one of the top 5 cities
(top 5 in terms of total number of users from city). 
Also calculate the ratio of booked to abandoned for each day. 
Return only the 5 most recent days in the dataset.
*/
WITH top5 AS(
  SELECT 
	user_id
FROM users
WHERE home_city IN (SELECT 
                    home_city
                    FROM users 
                    GROUP BY 1 
                    ORDER BY COUNT(DISTINCT user_id) DESC
                    LIMIT 5
                   )
),
abandon_book AS(
SELECT 
				to_date(CAST(session_start as text), 'yyyy-mm-dd') as session_date
  			, CAST(SUM(CASE WHEN s.flight_booked = FALSE AND s.hotel_booked = FAlSE THEN 1 ELSE 0  END) as numeric) AS abandoned
  			, CAST(SUM(CASE WHEN s.flight_booked = TRUE OR s.hotel_booked = TRUE THEN 1 ELSE 0 END) as numeric) AS booked
			FROM sessions s
			INNER JOIN top5 t ON t.user_id = s.user_id
			GROUP BY 1
			ORDER BY 1 DESC
)
SELECT 
	*,
  ROUND(booked/abandoned, 3)
FROM abandon_book 
WHERE abandoned !=0 
	AND booked !=0
LIMIT 5




















