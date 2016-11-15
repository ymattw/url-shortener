**Table of Contents**

  - [Scope](#scope)
  - [Slug Generation](#slug-generation)
  - [Database Schema](#database-schema)
  - [Notes](#notes)

# Scope

The task is to build an URL shortener service with an HTTP API.

For example:

```
curl -sX POST -H 'Content-Type: application/json' 'localhost/shorten' -d '{"url":"http://a.very.long.url"}'

> HTTP 200
> '{"short":"http://localhost/abcdef"}'
```

```
curl -sX GET -H 'Content-Type: application/json' 'localhost/original' -d '{"short":"http://localhost/abcdef"}'

> HTTP 200
> {"original":"http://a.very.long.url"}
```

Scope were further declared below:

1. We do not need a web interface, just implement the API
2. We do not need authentication or authorization
3. We do not need the ability to DELETE or EDIT a shortened url
4. Keep in mind we might need to support customizing short url later

# Slug Generation

## Allowed chars

Shortened link (the slug) should be URL-ready, according to [RFC
1738](https://www.rfc-editor.org/rfc/rfc1738.txt), only alphanumerics and the
special characters `"$-_.+!*'(),`" may be used unencoded within a URL.  But for
readability we might not want to use those special characters.  So the
remainders are 26 lowercased letters, 26 uppercased letters and 10 digits, 62
in total.

## The algorithm

A common solution is to associate every long URL with a unique key, the key can
be converted from a integer with [base
36](https://en.wikipedia.org/wiki/Base_36) or [base
62](https://en.wikipedia.org/wiki/Base_62).  The _integer_ can be generated
from an auto incremental database serial id.

Suppose we can handle up to 1,000 requests per second (a reasonable QPS limit),
so max links processed within a year will be

    1000 * 3600 * 24 * 365 = 31,536,000,000

That is ~3.1 trillion records for 100 years.

If we allow all the 62 characters, 7 characters will be enough to represent all
the links.

    62⁶ =      56,800,235,584 (56 billion)
    62⁷ =   3,521,614,606,208 (3.5 trillion)
    62⁸ = 218,340,105,584,896 (218 trillion)

So we can just use the [base 62](https://en.wikipedia.org/wiki/Base_62)
algorithm to represent long links.  The idea is just assign a unique, auto
incremental id for each input long URL, and convert the id to base-62 form and
use it as the slug of the long URL. For example, if we are processing the
`8469th` URL, 8469 can be represented in base-10 as `2 * 62² + 12 * 62¹ + 37`,
now we look up following table and can get its base-62 form which is `2Cb`.

    0 -> 0
    1 -> 1
    2 -> 2
    ...
    10 -> A
    11 -> B
    12 -> C
    ...
    36 -> a
    37 -> b
    38 -> c
    ...
    61 -> z

We will be using the `SEQUENCE` data type from Postgres to produce the _unique_
id.

# Database Schema

We need a backend storage to save the mapping between long links and slugs.
RDBS or NoSQL can both be considered.  Let's just use a RDBS as the first step
because persistence problem in NoSQL is another challenge, we can use Postgres
which has a handy SEQUENCE data type we can leverage.  The
simplest schema can be:

    CREATE SEQUENCE IF NOT EXISTS serial;

    CREATE TABLE IF NOT EXISTS links (
        slug   VARCHAR(7) PRIMARY KEY,
        target TEXT NOT NULL
    );

Here we use `slug` as the `PRIMARY KEY` because it has to be unique.  The core
logic will be taking `NEXTVAL('serial')` first and then generate the slug.

# Notes

## Performance consideration

To speed up read performance we can add a caching layer, for example, use
Redis.

## Scalability consideration

We do not have any JOIN operations so current schema should be able to handle
billion of rows in the `links` table.  When the total records grows into a huge
number, we can distribute the future input to separate table or even separate
server based on the global sequence number, for example we start to use table
`links-1` when sequence number exceeds a billion.

## How to support customized slug

One slug can has many customized slugs (aliases), we can store the mapping in
a separate table, for example:

    CREATE TABLE IF NOT EXISTS aliases (
        id     SERIAL PRIMARY KEY,
        slug   VARCHAR(7) NOT NULL,
        alias  VARCHAR(32) NOT NULL
    );

When a client specify the customized slug in the POST body json, we auto
generate one slug for it and also map it with the input slug in above table.

## What if we want to avoid duplicate long URLs

We can generate a hash (e.g. SHA1) for each long URL, store this in the `links`
table with a new field (e.g. `fingerprint`), also create a `UNIQUE INDEX` on
the field to avoid duplication.  Core logic can be enhanced to check the
existence first, capture _IntegrityError_ and retry to to handle race condition
between the _check_ and _insertion_.
