// Nome: Rafael Mendes Valente - RA: 25002875
// Data: 11/11/2026
// Descrição: Verifica isolamento dos caches climáticos entre propriedades.

import 'package:app/models/clima.dart';
import 'package:app/services/armazenamento_local_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('armazena clima separadamente por propriedade', () async {
    const storage = ArmazenamentoLocalService();
    const first = ClimaHoje(
      temperatura: 20,
      maxima: 25,
      minima: 14,
      descricao: 'Céu limpo',
    );
    const second = ClimaHoje(
      temperatura: 30,
      maxima: 35,
      minima: 24,
      descricao: 'Nublado',
    );

    await storage.salvarClima(first, propriedadeId: 'property-1');
    await storage.salvarClima(second, propriedadeId: 'property-2');
    final forecast = PrevisaoClimatica(
      atual: first,
      dias: [
        ClimaDia(
          data: DateTime(2026, 11, 11),
          maxima: 25,
          minima: 14,
          precipitacao: 1,
        ),
      ],
    );
    await storage.salvarPrevisao(forecast, propriedadeId: 'property-1');

    expect(
      (await storage.lerClima(propriedadeId: 'property-1'))?.temperatura,
      first.temperatura,
    );
    expect(
      (await storage.lerClima(propriedadeId: 'property-2'))?.temperatura,
      second.temperatura,
    );
    expect(await storage.lerClima(propriedadeId: 'unknown'), isNull);
    expect(
      (await storage.lerPrevisao(
        propriedadeId: 'property-1',
      ))?.dias.single.precipitacao,
      1,
    );
    expect(await storage.lerPrevisao(propriedadeId: 'property-2'), isNull);
  });
}
