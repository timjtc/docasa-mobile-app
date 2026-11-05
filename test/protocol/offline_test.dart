import 'dart:typed_data';

import 'package:docasa_app/protocol/codec.dart';
import 'package:flutter_test/flutter_test.dart';

/// Contract v1.1 fixtures/tolerances (§4.4 "st", §10.1 record decoding).
void main() {
  group('Filter Counters "st" (F8/F5/X7/X8)', () {
    test('F8 — full payload with st decodes exactly', () {
      final c = DocasaCodec.decodeFilterCounters(jsonStExample);
      expect(c.fanSeconds, 10800000);
      expect(c.dirtyAirSeconds, 30120 + 9120 + 15);
      expect(c.powerOnHours, 3210);
      expect(c.stageSeconds.every((e) => e >= 0), isTrue);
      expect(c.stageSeconds.length, 5);
      expect(DocasaCodec.encodeFilterCounters(c), jsonStExample);
    });

    test('F5 — pre-v1.1 payload decodes with empty st (X7 fallback)', () {
      final c = DocasaCodec.decodeFilterCounters(
          '{"v":1,"fs":1,"pwfs":2,"on":3}');
      expect(c.fanSeconds, 1);
      expect(c.dirtyAirSeconds, 0);
      // re-encode omits st when empty (older devices ignore unknown keys).
      expect(DocasaCodec.encodeFilterCounters(c), '{"v":1,"fs":1,"pwfs":2,"on":3}');
    });

    test('X8 — non-integer/overlong st is tolerated as empty', () {
      final bad = DocasaCodec.decodeFilterCounters(
          '{"v":1,"fs":1,"pwfs":2,"on":3,"st":[600,"x",0,0,0,0]}');
      expect(bad.stageSeconds, isEmpty);
      final short = DocasaCodec.decodeFilterCounters(
          '{"v":1,"fs":1,"pwfs":2,"on":3,"st":[600,0]}');
      expect(short.stageSeconds.length, 2); // length tolerated as-is; UI padding
      expect(short.dirtyAirSeconds, 0); // <5 entries → no dirty basis yet
    });
  });

  group('offline record decoding (§10.1)', () {
    Uint8List record({
      int pmMin = 11,
      int pmMean = 22,
      int pmMax = 33,
      List<int> st = const [600, 0, 0, 0, 0],
    }) {
      final b = BytesBuilder();
      void u16(int v) {
        b.add([v & 0xFF, (v >> 8) & 0xFF]);
      }

      u16(pmMin);
      u16(pmMean);
      u16(pmMax);
      for (final s in st) {
        u16(s);
      }
      return b.toBytes();
    }

    test('valid record decodes little-endian', () {
      final bytes = record();
      final w = DocasaCodec.decodeOfflineRecord(bytes, 0);
      expect(w.pmMin, 11);
      expect(w.pmMean, 22);
      expect(w.pmMax, 33);
      expect(w.stageSeconds, [600, 0, 0, 0, 0]);
      // Multiple records in one chunk (drain-style serving, §10.3):
      final two = BytesBuilder()..add(bytes)..add(bytes);
      final second = DocasaCodec.decodeOfflineRecord(two.toBytes(), 16);
      expect(second.pmMax, 33);
    });

    test('torn/power-cut write (0xFF fields) is rejected (§10.1 marker)', () {
      expect(
        () => DocasaCodec.decodeOfflineRecord(record(pmMean: 0xFFFF), 0),
        throwsA(isA<MalformedPayloadException>()),
      );
      expect(
        () => DocasaCodec.decodeOfflineRecord(record(pmMin: 1000), 0),
        throwsA(isA<MalformedPayloadException>()),
      );
      expect(
        () => DocasaCodec.decodeOfflineRecord(
            record(st: const [600, 601, 0, 0, 0]), 0),
        throwsA(isA<MalformedPayloadException>()),
      );
    });
  });
}

/// F8 golden fixture (Contract §4.4).
const String jsonStExample =
    '{"v":1,"fs":10800000,"pwfs":74250000,"on":3210,"st":[20100,60100,30120,9120,15]}';
