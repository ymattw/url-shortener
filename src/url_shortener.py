"""
Core logic to shorten a long url / expand (get orginal) a slug
"""

from os.path import join as path_join
from base62 import Base62
from db import ShortenerDB


class URLShortener(object):

    SHORTENER_DB_INIT_SQL = 'shorterner_db.sql'

    def __init__(self, config):
        self._base62 = Base62()
        self._db = ShortenerDB(**config['db'])
        self._db.load_sql(
            path_join(config['self_dir'], URLShortener.SHORTENER_DB_INIT_SQL)
        )

    def shorten(self, url):
        next_id = self._next_id()
        slug = self._base62.encode(next_id)
        self._db.execute("INSERT INTO links (slug, target) VALUES (%s, %s)",
                         [slug, url])
        return slug

    def expand(self, slug):
        self._db.execute("SELECT target FROM links WHERE slug=%s", [slug])
        try:
            return self._db.fetchone()[0]
        except TypeError:
            return None

    def _next_id(self):
        self._db.execute("SELECT NEXTVAL('serial')")
        return self._db.fetchone()[0]
