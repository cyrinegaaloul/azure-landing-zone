import unittest
from pathlib import Path
from unittest.mock import mock_open, patch

from server import normalized_path, secret_is_mounted


class ServerHelpersTest(unittest.TestCase):
    def test_normalized_path_removes_query_string(self):
        self.assertEqual(normalized_path("/health?probe=true"), "/health")

    def test_unknown_path_has_bounded_metric_label(self):
        self.assertEqual(normalized_path("/arbitrary/value"), "/not-found")

    def test_secret_status_never_returns_secret_contents(self):
        with patch.object(Path, "open", mock_open(read_data=b"sensitive-value")):
            self.assertIs(secret_is_mounted(Path("demo-secret")), True)

    def test_missing_and_empty_secrets_are_not_mounted(self):
        with patch.object(Path, "open", side_effect=FileNotFoundError):
            self.assertIs(secret_is_mounted(Path("missing")), False)
        with patch.object(Path, "open", mock_open(read_data=b"")):
            self.assertIs(secret_is_mounted(Path("empty")), False)


if __name__ == "__main__":
    unittest.main()
