# Forum Postgres

If you want to run nice SQL queries on JSON exported from MongoDB, here's how I'd do it...

The script is super bare-bones and currently just handles `Users`/`Posts`, but the general principle should be pretty robust.

## Export the data from Mongo

```
# users
mongoexport --host $MONGO_URL --username $MONGO_ADMIN --password "$MONGO_PASSWORD" -d $MONGO_DBNAME --collection users --out ~/Desktop/forum_users.json
# posts
mongoexport --host $MONGO_URL --username $MONGO_ADMIN --password "$MONGO_PASSWORD" -d $MONGO_DBNAME --collection posts --out ~/Desktop/forum_posts.json
```

## Import into postgres

_Requires [pgfutter](https://github.com/lukasmartinelli/pgfutter)_

```
createdb eaforum
pgfutter --db eaforum --user $PGUSER json ~/Desktop/forum_posts.json
pgfutter --db eaforum --user $PGUSER json ~/Desktop/forum_posts.json
```

## Scaffold the DB

Run `./up.sql`:

```
psql=# \i /path/to/forum-postgres/up.sql
```

## Profit
