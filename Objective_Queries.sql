use ig_clone;

-- OQ1 for finding duplicates (its just for users table, checked for all tables )

SELECT username, id, COUNT(*)
FROM users
GROUP BY username, id
HAVING COUNT(*) > 1;

-- OQ2. What is the distribution of user activity levels (e.g., number of posts, likes, comments) across the user base?
 
SELECT 
    u.id as user_id,
    u.username,
    COALESCE(p.num_posts, 0) AS num_posts,
    COALESCE(l.num_likes, 0) AS num_likes,
    COALESCE(c.num_comments, 0) AS num_comments
FROM users u
LEFT JOIN 
    (SELECT user_id, COUNT(*) AS num_posts
     FROM photos
     GROUP BY user_id) p ON u.id = p.user_id
LEFT JOIN 
    (SELECT user_id, COUNT(*) AS num_likes
     FROM likes
     GROUP BY user_id) l ON u.id = l.user_id
LEFT JOIN 
    (SELECT user_id, COUNT(*) AS num_comments
     FROM comments
     GROUP BY user_id) c ON u.id = c.user_id;
      
-- OQ3. Calculate the average number of tags per post (photo_tags and photos tables).

SELECT AVG(tag_count) AS avg_tags_per_post
FROM 
    (SELECT p.id,COUNT(pt.tag_id) AS tag_count
     FROM photos p
     LEFT JOIN photo_tags pt ON p.id = pt.photo_id
     GROUP BY p.id) AS tag_counts;
         
-- OQ4. Identify the top users with the highest engagement rates (likes, comments) on their posts and rank them.

SELECT u.id, u.username,
    COALESCE(p.total_posts, 0) AS total_posts,
    COALESCE(l.total_likes, 0) AS total_likes,
    COALESCE(c.total_comments, 0) AS total_comments,
    (COALESCE(l.total_likes, 0) + COALESCE(c.total_comments, 0)) AS total_engagement,
    ((COALESCE(l.total_likes, 0) + COALESCE(c.total_comments, 0))/ COALESCE(p.total_posts, 0)) as engagement_rate,
    RANK() OVER (ORDER BY ((COALESCE(l.total_likes, 0) + COALESCE(c.total_comments, 0))/ COALESCE(p.total_posts, 0)) DESC) AS engagement_rank
FROM users u
LEFT JOIN (
    SELECT user_id,COUNT(*) AS total_likes
    FROM likes
    GROUP BY user_id
) l ON u.id = l.user_id
LEFT JOIN (
    SELECT user_id,COUNT(*) AS total_comments
    FROM comments
    GROUP BY user_id
) c ON u.id = c.user_id
LEFT JOIN (
    SELECT user_id, COUNT(*) AS total_posts
    FROM photos
    GROUP BY user_id) p ON u.id = p.user_id
GROUP BY id
HAVING total_posts>0
ORDER BY engagement_rank
LIMIT 10;
 
-- OQ5. Which users have the highest number of followers and followings?

SELECT u.id,u.username,
    COALESCE(followers_count, 0) AS followers_count,
    COALESCE(followings_count, 0) AS followings_count
FROM users u
LEFT JOIN (
    SELECT followee_id, COUNT(follower_id) AS followers_count
    FROM follows
    GROUP BY followee_id) AS f_count ON u.id = f_count.followee_id
LEFT JOIN (
    SELECT follower_id, COUNT(followee_id) AS followings_count
    FROM follows
    GROUP BY follower_id) AS fl_count ON u.id = fl_count.follower_id
ORDER BY followers_count DESC, followings_count DESC;
    
-- OQ6. Calculate the average engagement rate (likes, comments) per post for each user.

SELECT u.id as user_id,u.username,
    COALESCE(p.num_posts, 0) AS num_posts,
    COALESCE(l.num_likes, 0) AS num_likes,
    COALESCE(c.num_comments, 0) AS num_comments,
    CASE 
        WHEN COALESCE(p.num_posts, 0) = 0 THEN 0
        ELSE (COALESCE(l.num_likes, 0) + COALESCE(c.num_comments, 0)) / COALESCE(p.num_posts, 0) END AS avg_engagement_rate
FROM users u
LEFT JOIN 
    (SELECT user_id, COUNT(*) AS num_posts
     FROM photos
     GROUP BY user_id) p ON u.id = p.user_id
LEFT JOIN 
    (SELECT user_id, COUNT(*) AS num_likes
     FROM likes
     GROUP BY user_id) l ON u.id = l.user_id
LEFT JOIN 
    (SELECT user_id, COUNT(*) AS num_comments
     FROM comments
     GROUP BY user_id) c ON u.id = c.user_id
	ORDER BY avg_engagement_rate DESC;

-- OQ7. Get the list of users who have never liked any post (users and likes tables)

SELECT u.id, u.username
FROM users u
LEFT JOIN likes l ON u.id = l.user_id
WHERE l.user_id IS NULL;
    
-- OQ10. Calculate the total number of likes, comments, and photo tags for each user

SELECT u.id as id, u.username,
    COALESCE(l.total_likes, 0) AS total_likes,
    COALESCE(c.total_comments, 0) AS total_comments,
    COALESCE(pt.total_photo_tags, 0) AS total_photo_tags
FROM users u
LEFT JOIN 
    (SELECT user_id, COUNT(*) AS total_likes FROM likes GROUP BY user_id) l ON u.id = l.user_id
LEFT JOIN 
    (SELECT user_id, COUNT(*) AS total_comments FROM comments GROUP BY user_id) c ON u.id = c.user_id
LEFT JOIN 
    (SELECT tag_id, COUNT(*) AS total_photo_tags FROM photo_tags GROUP BY tag_id) pt ON u.id = pt.tag_id;
    
--   OQ11. Rank users based on their total engagement (likes, comments, shares) over a month.  
     
WITH MonthlyEngagement AS (
    SELECT u.id AS user_id, 
		   u.username, 
           COALESCE(p.total_posts, 0) AS total_posts,
           COALESCE(l.total_likes, 0) AS total_likes, 
           COALESCE(c.total_comments, 0) AS total_comments,
		   (COALESCE(l.total_likes, 0) + COALESCE(c.total_comments, 0)) AS total_engagement
    FROM users u
    LEFT JOIN (
        SELECT user_id, COUNT(photo_id) AS total_likes
        FROM likes
        WHERE DATE(created_at) >= '2024-07-01' OR DATE(created_at) <= '2024-07-31'
        GROUP BY user_id
    ) l ON u.id = l.user_id
    LEFT JOIN (
        SELECT user_id, COUNT(id) AS total_comments
        FROM comments
        WHERE DATE(created_at) >= '2024-07-01' OR DATE(created_at) <= '2024-07-31'
        GROUP BY user_id
    ) c ON u.id = c.user_id
    LEFT JOIN (
    SELECT user_id, COUNT(*) AS total_posts
    FROM photos
    GROUP BY user_id) p ON u.id = p.user_id
) 
SELECT user_id, username, total_likes, total_comments, total_engagement, 
RANK() OVER (ORDER BY total_engagement DESC) AS engagement_rank
FROM MonthlyEngagement
where total_posts>0
ORDER BY engagement_rank;

-- OQ12. Retrieve the hashtags that have been used in posts with the highest average number of likes. 
-- Use a CTE to calculate the average likes for each hashtag first.
 
WITH HashtagLikes AS (
    SELECT ht.tag_name, COUNT(l.photo_id) AS total_likes, COUNT(DISTINCT p.id) AS total_posts
    FROM tags ht
    JOIN photo_tags pt ON ht.id = pt.tag_id
    JOIN photos p ON pt.photo_id = p.id
    LEFT JOIN likes l ON p.id = l.photo_id
    GROUP BY ht.tag_name
),
AverageLikesPerHashtag AS (
    SELECT tag_name, (CAST(total_likes AS FLOAT) / total_posts) AS avg_likes
    FROM HashtagLikes
)
SELECT tag_name, round(avg_likes,2) as avg_likes
FROM AverageLikesPerHashtag
order by avg_likes desc;

-- OQ13. Retrieve the users who have started following someone after being followed by that person

SELECT
    f1.follower_id AS followed_back_user,
    f1.followee_id AS original_follower,
    f1.created_at AS followed_back_at,
    f2.created_at AS originally_followed_at
FROM follows f1
JOIN follows f2 ON f1.follower_id = f2.followee_id 
AND f1.followee_id = f2.follower_id
WHERE f1.created_at > f2.created_at;
    
    
# Q1, Q8, Q9 answers given as theory approaches in document file.
    
