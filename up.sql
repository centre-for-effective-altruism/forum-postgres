
CREATE TABLE users (
  id TEXT PRIMARY KEY,
  username TEXT,
  email TEXT,
  karma NUMERIC,
  created_at TIMESTAMPTZ
);

CREATE TABLE posts (
  id TEXT PRIMARY KEY,
  user_id TEXT REFERENCES users(id),
  title TEXT,
  slug TEXT,
  base_score INTEGER,
  community BOOLEAN,
  frontpage_date TIMESTAMPTZ,
  posted_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ
);

CREATE FUNCTION sanitize_date(TEXT)
RETURNS TIMESTAMPTZ AS $$
 SELECT (regexp_replace($1, '{"\$date":"(.*?)"}', '\1'))::TIMESTAMPTZ;
$$ LANGUAGE SQL IMMUTABLE;

INSERT INTO users
SELECT
  data->>'_id' as id,
  data->>'username' as username,
  data->>'email' as email,
  (data->>'karma')::NUMERIC as karma,
 sanitize_date(data->>'createdAt') as created_at
FROM import.forum_users;



INSERT INTO posts
SELECT
  data->>'_id' as id,
  data->>'userId' as user_id,
  data->>'title' as title,
  data->>'slug' as slug,
 (data->>'baseScore')::INTEGER as karma,
 (data->>'meta')::BOOLEAN as community,
 sanitize_date(data->>'frontpageDate') as frontpage_date,
 sanitize_date(data->>'postedAt') as posted_at,
 sanitize_date(data->>'createdAt') as created_at
FROM import.forum_posts
INNER JOIN users ON data->>'userId' = users.id
WHERE (data->>'status')::INTEGER IN (1, 2);

CREATE FUNCTION get_post_url(post_id TEXT)
RETURNS TEXT AS $$
  SELECT 'https://forum.effectivealtruism.org/posts/' || id || '/' || slug
  FROM posts
  WHERE id = $1
$$ LANGUAGE SQL STABLE;

CREATE VIEW post_and_user AS (
  SELECT
    users.username,
    users.email,
    posts.*,
    'https://forum.effectivealtruism.org/posts/' || posts.id || '/' || posts.slug
  FROM posts
  JOIN users ON posts.user_id = users.id
  ORDER BY posted_at::DATE asc, created_at::DATE asc, karma DESC
);

CREATE VIEW top_users AS (
  WITH top_users AS (
  SELECT * from users
),
most_recent_post AS (
  SELECT
    posts.id,
    user_id,
    posted_at,
    rank() over (partition by user_id order by posted_at DESC)
  FROM posts
  INNER JOIN top_users ON top_users.id = posts.user_id
  GROUP BY posts.id, user_id
)
SELECT
  u.*,
  get_post_url(p.id) AS most_recent_post,
  p.posted_at AS most_recent_post_posted_at
FROM top_users u INNER JOIN most_recent_post p ON p.user_id = u.id
WHERE p.rank = 1
ORDER BY karma DESC NULLS LAST
);
