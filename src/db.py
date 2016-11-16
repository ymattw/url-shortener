"""
Wrapper for psycopg2
"""

from time import sleep
import psycopg2


class ShortenerDB(object):

    def __init__(self, **kwargs):
        retries = 0
        while retries < 10:
            try:
                self._conn = psycopg2.connect(**kwargs)
                self._cursor = self._conn.cursor()
                return
            except psycopg2.OperationalError as e:
                retries += 1
                sleep(2**retries)
        raise RuntimeError('Unable to connect DB, all retries failed')

    def execute(self, sql, parameter=None):
        self._cursor.execute(sql, parameter)

    def fetchone(self):
        return self._cursor.fetchone()

    def fetchall(self):
        return self._cursor.fetchall()

    def load_sql(self, pathname):
        with open(pathname) as f:
            self._cursor.execute(f.read())
