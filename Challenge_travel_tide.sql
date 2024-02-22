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



/*
Question #1: 
Vibestream is designed for users to share brief updates about how they are feeling, 
as such the platform enforces a character limit of 25. How many posts are exactly 25 characters long?
*/

SELECT 
	COUNT(post_id) as char_limit_posts
FROM posts
WHERE LENGTH(content) = 25


/*
Question #2: 
Users JamesTiger8285 and RobertMermaid7605 are Vibestream’s most active posters.

Find the difference in the number of posts these two users made
on each day that at least one of them made a post.
Return dates where the absolute value of the difference between posts made is greater than 2 
(i.e dates where JamesTiger8285 made at least 3 more posts than RobertMermaid7605 or vice versa).
*/

WITH cte AS(
  SELECT 
  p.post_date
	, SUM(CASE WHEN u.user_name = 'JamesTiger8285' THEN 1 ELSE 0 END) as james_post 
	, SUM(CASE WHEN u.user_name = 'RobertMermaid7605' THEN 1 ELSE 0  END) as robert_post
FROM posts p
INNER JOIN users u ON p.user_id=u.user_id
GROUP BY 1 
)

SELECT 
	post_date 
FROM cte 
WHERE ABS(james_post - robert_post) > 2


/*
Question #3: 
Most users have relatively low engagement and few connections. User WilliamEagle6815, for example, has only 2 followers. 

Network Analysts would say this user has two 1-step path relationships. Having 2 followers doesn’t mean WilliamEagle6815 is isolated, however. Through his followers, he is indirectly connected to the larger Vibestream network.  


Consider all users up to 3 steps away from this user:


1-step path (X → WilliamEagle6815)
2-step path (Y → X → WilliamEagle6815)
3-step path (Z → Y → X → WilliamEagle6815)

Write a query to find follower_id of all users within 4 steps of WilliamEagle6815. Order by follower_id and return the top 10 records.
*/

SELECT 
	follower_id 
FROM follows
WHERE followee_id IN (SELECT 
												follower_id 
											FROM follows
											WHERE followee_id IN (SELECT 
																							follower_id 
																						FROM follows
																						WHERE followee_id IN (SELECT 
																																		follower_id 
																																	FROM follows
                                                                  WHERE followee_id IN (SELECT 
                                                                                          user_id
                                                                                        FROM users
                                                                                        WHERE user_name = 'WilliamEagle6815'
                                                                                        )
                                                                  )
                                            )
                      )
GROUP BY follower_id 
ORDER BY follower_id
LIMIT 10 































