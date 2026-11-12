// Nome: Rafael Mendes Valente - RA: 25002875
// Data: 11/11/2026
// Descrição: Representa o clima diário e a previsão retornados pela API.

class ClimaHoje {
  const ClimaHoje({
    required this.temperatura,
    required this.maxima,
    required this.minima,
    required this.descricao,
  });

  final double temperatura;
  final double maxima;
  final double minima;
  final String descricao;

  // Mantém o mesmo formato no cache local e na resposta de clima diário.
  factory ClimaHoje.fromJson(Map<String, dynamic> json) {
    return ClimaHoje(
      temperatura: (json['temperatura'] as num).toDouble(),
      maxima: (json['maxima'] as num).toDouble(),
      minima: (json['minima'] as num).toDouble(),
      descricao: json['descricao'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'temperatura': temperatura,
      'maxima': maxima,
      'minima': minima,
      'descricao': descricao,
    };
  }
}

class ClimaDia {
  const ClimaDia({
    required this.data,
    required this.maxima,
    required this.minima,
    required this.precipitacao,
  });

  final DateTime data;
  final double maxima;
  final double minima;
  final double precipitacao;

  factory ClimaDia.fromJson(Map<String, dynamic> json) {
    return ClimaDia(
      data: DateTime.parse(json['date'] as String),
      maxima: (json['maxima'] as num).toDouble(),
      minima: (json['minima'] as num).toDouble(),
      precipitacao: (json['precipitation'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': data.toIso8601String().substring(0, 10),
      'maxima': maxima,
      'minima': minima,
      'precipitation': precipitacao,
    };
  }
}

class PrevisaoClimatica {
  const PrevisaoClimatica({required this.atual, required this.dias});

  final ClimaHoje atual;
  final List<ClimaDia> dias;

  factory PrevisaoClimatica.fromJson(Map<String, dynamic> json) {
    final current = json['current'] as Map<String, dynamic>;
    final daily = json['daily'] as List<dynamic>;
    final today = daily.first as Map<String, dynamic>;
    return PrevisaoClimatica(
      atual: ClimaHoje(
        temperatura: (current['temperatura'] as num).toDouble(),
        maxima: (today['maxima'] as num).toDouble(),
        minima: (today['minima'] as num).toDouble(),
        descricao: current['descricao'] as String,
      ),
      dias: [
        for (final item in daily)
          ClimaDia.fromJson(item as Map<String, dynamic>),
      ],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'current': {
        'temperatura': atual.temperatura,
        'descricao': atual.descricao,
      },
      'daily': [for (final dia in dias) dia.toJson()],
    };
  }
}
