// Nome: Vinicius Santuci Virgolino - RA: 25000294
// Data: 13/10/2026
// Descrição: Paleta de cores do ClimAlerta, compartilhada entre as telas.

import 'package:flutter/material.dart';

// "abstract final": a classe não pode ser instanciada nem herdada; serve só
// para agrupar as cores. As telas usam assim: AppColors.verde.
// Trocar uma cor aqui muda o app inteiro de uma vez.
// Formato das cores: 0xAARRGGBB (FF = totalmente opaca, depois vermelho,
// verde e azul em hexadecimal).
abstract final class AppColors {
  // Cores principais da interface.
  static const Color verde = Color(0xFF1E7B58); // botões e títulos
  static const Color verdeFolha = Color(0xFF6FBF73); // detalhes (modo offline)
  static const Color amareloSol = Color(0xFFF2C94C); // avisos (dados salvos)
  static const Color borda = Color(0xFFD5DBD8); // contorno dos campos
  static const Color fundo = Color(0xFFF4F7F5); // fundo das telas
  static const Color textoEscuro = Color(0xFF2B3A33); // texto principal
  static const Color textoSecundario = Color(0xFF66736D); // texto de apoio
  static const Color erro = Color(0xFFE05252); // mensagens de erro

  // Verde bem claro dos morros, usado no fundo da tela de recomendações.
  static const Color morroClaro = Color(0xFFCFE8D5);
}
