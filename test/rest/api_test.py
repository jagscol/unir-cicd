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

    def test_api_add(self):
        url = f"{BASE_URL}/calc/add/2/2"
        response = urlopen(url, timeout=DEFAULT_TIMEOUT)
        
        # Verifica que el estado de la respuesta sea OK (200)
        self.assertEqual(response.status, http.client.OK, f"Error en la petición API a {url}")
        
        # Verifica que el tipo de contenido sea JSON
        content_type = response.getheader('Content-Type')
        self.assertEqual(content_type, 'application/json', f"Tipo de contenido inesperado: {content_type}")
        
        # Verifica el contenido de la respuesta
        response_body = response.read()
        self.assertIsNotNone(response_body, "El cuerpo de la respuesta es None")
        
        # Si esperas un JSON como respuesta, puedes convertirlo y verificar su contenido
        import json
        try:
            data = json.loads(response_body)
            expected_result = {"result": 4}  # Asumiendo que esta es la estructura de respuesta esperada
            self.assertEqual(data, expected_result, f"Respuesta inesperada: {data}")
        except json.JSONDecodeError:
            self.fail(f"El cuerpo de la respuesta no es un JSON válido: {response_body}")

# Si deseas ejecutar las pruebas desde este script, puedes descomentar la siguiente línea
# if __name__ == "__main__":
#     unittest.main()

