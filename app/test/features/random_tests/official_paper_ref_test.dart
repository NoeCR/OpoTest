import 'package:flutter_test/flutter_test.dart';
import 'package:opotest/features/random_tests/domain/official_paper_ref.dart';

void main() {
  group('OfficialPaperRef', () {
    test('extrae año y administración de nombres reales', () {
      final cases = <(String, String, int?)>[
        ('TAI INAP 2025 · Ingreso libre modelo A (primera parte)', 'INAP / AGE', 2025),
        ('TAI Ayuntamiento de Madrid 2025', 'Ayuntamiento de Madrid', 2025),
        ('Técnico Especialista Informática SAS 2025', 'SAS (Andalucía)', 2025),
        ('TAI Ayuntamiento de Burriana 2024', 'Ayuntamiento de Burriana', 2024),
        ('C1-02 Especialistas STI GVA 2021 turno libre (conv. 125/18)', 'Generalitat Valenciana', 2021),
        ('Escala Administrativa Informática Univ. Sevilla 2025', 'Universidad de Sevilla', 2025),
        ('Ayudante Técnico Informática UPO 2023', 'Universidad Pablo de Olavide', 2023),
        ('Técnico auxiliar informática UGR 2024', 'Universidad de Granada', 2024),
        ('Auxiliar de Informática Senado 2018', 'Senado', 2018),
        ('Ayudante investigación ciencia de datos CSIC 2026', 'CSIC', 2026),
        ('Técnico de Soporte Informático JCyL 2026', 'Junta de Castilla y León', 2026),
        ('TAI Diputación de Guadalajara 2024', 'Diputación de Guadalajara', 2024),
        ('Prueba real TAI · 1 (75 preguntas)', 'Banco TAI (transcripciones)', null),
      ];

      for (final c in cases) {
        final ref = OfficialPaperRef.fromMeta(id: 'x', name: c.$1);
        expect(ref.administration, c.$2, reason: c.$1);
        expect(ref.year, c.$3, reason: c.$1);
      }
    });

    test('agrupa por administración y ordena por año descendente', () {
      final papers = [
        OfficialPaperRef.fromMeta(id: 'a', name: 'TAI Ayuntamiento de Madrid 2023'),
        OfficialPaperRef.fromMeta(id: 'b', name: 'TAI Ayuntamiento de Madrid 2026'),
        OfficialPaperRef.fromMeta(id: 'c', name: 'TAI INAP 2025 · Ingreso libre'),
      ];
      final groups = OfficialPaperRef.grouped(papers);
      expect(groups.map((e) => e.key).toList(), ['Ayuntamiento de Madrid', 'INAP / AGE']);
      expect(groups.first.value.map((p) => p.year).toList(), [2026, 2023]);
    });
  });
}
