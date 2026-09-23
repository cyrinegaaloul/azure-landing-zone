import unittest

from server import DEMO_ITEMS


class BackendTest(unittest.TestCase):
    def test_demo_data_has_stable_ids(self):
        self.assertEqual([item["id"] for item in DEMO_ITEMS], ["foundation", "networking", "security"])


if __name__ == "__main__":
    unittest.main()
