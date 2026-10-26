"""Adapter-only tests; these do not verify an actual UE4 EndMatch/OB15 event."""
import importlib.util
import pathlib
import sys
import types
import unittest


class WireAdapterTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.last = {}
        codec = types.ModuleType('tdr_codec')
        def packet(command, schema, value):
            cls.last['wire'] = value
            return b'wire'
        def packets(encoded):
            return [(60, b'data')]
        def decode_all(schema, frame):
            return {'Count': cls.last['wire']['Count'],
                    'BattleInfo': dict(cls.last['wire']['BattleInfo'])}
        codec.packet = packet
        codec.packets = packets
        codec.decode_all = decode_all
        cls.prior = sys.modules.get('tdr_codec')
        sys.modules['tdr_codec'] = codec
        path = pathlib.Path(__file__).resolve().parents[1] / 'postmatch_wire35.py'
        spec = importlib.util.spec_from_file_location('postmatch_wire35_tested', path)
        cls.adapter = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(cls.adapter)

    @classmethod
    def tearDownClass(cls):
        if cls.prior is None:
            sys.modules.pop('tdr_codec', None)
        else:
            sys.modules['tdr_codec'] = cls.prior

    def test_valid_wire(self):
        data = self.adapter.result_notice({'WinTeamId': 0, 'TimeConsume': 45}, [{'Name': 'Pilot'}], room_sequence=25)
        self.assertEqual(data, b'wire')
        self.assertEqual(self.last['wire']['RoomSeq'], 25)
        self.assertEqual(self.last['wire']['ItemCount'], 0)

    def test_invalid_duration_rejected(self):
        for duration in (None, False, True, '45', 45.0, 0, -1, 86401, []):
            with self.subTest(duration=duration), self.assertRaises(ValueError):
                self.adapter.result_notice({'WinTeamId': 0, 'TimeConsume': duration}, [{'Name': 'Pilot'}])

    def test_invalid_outcome_rejected(self):
        for outcome in (None, False, True, '0', 0.0, 2, 256, []):
            with self.subTest(outcome=outcome), self.assertRaises(ValueError):
                self.adapter.result_notice({'WinTeamId': outcome, 'TimeConsume': 45}, [{'Name': 'Pilot'}])

    def test_invalid_name_rejected(self):
        for name in ('', '  ', None, 1, b'Pilot', []):
            with self.subTest(name=name), self.assertRaises(ValueError):
                self.adapter.result_notice({'WinTeamId': 0, 'TimeConsume': 45}, [{'Name': name}])

    def test_invalid_rows_rejected(self):
        for rows in ([], [None], ['Pilot'], [{'Name': 'a'}]*17, None):
            with self.subTest(rows=rows), self.assertRaises(ValueError):
                self.adapter.result_notice({'WinTeamId': 0, 'TimeConsume': 45}, rows)

    def test_sequence_rejected(self):
        for number in (True, -1, 2**63, 1.0, '1'):
            with self.subTest(number=number), self.assertRaises(ValueError):
                self.adapter.result_notice({'WinTeamId': 0, 'TimeConsume': 45}, [{'Name': 'Pilot'}], number)

    def test_detect_modified_decoded_result(self):
        original = self.adapter.decode_all
        try:
            self.adapter.decode_all = lambda schema, payload: {'Count': 1, 'BattleInfo': {'WinTeamId': 1, 'TimeConsume': 45}}
            with self.assertRaisesRegex(ValueError, 'mismatch'):
                self.adapter.result_notice({'WinTeamId': 0, 'TimeConsume': 45}, [{'Name': 'Pilot'}])
        finally:
            self.adapter.decode_all = original


if __name__ == '__main__':
    unittest.main()
