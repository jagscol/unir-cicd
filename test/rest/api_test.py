import http.client
import os
import unittest
from urllib.request import urlopen

import pytest

BASE_URL = os.environ.get("BASE_URL")
DEFAULT_TIMEOUT = 2  # in seconds


@pytest.mark.api
class TestApi(unittest.TestCase):
    def setUp(self):
        # Verifica que BASE_URL no sea None y que tenga una longitud razonable
        self.assertIsNotNone(BASE_URL, "URL no configurada")
        self.assertTrue(len(BASE_URL) > 8, "URL no configurada")



