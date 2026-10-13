// Vinicius Santuci Virgolino - 25000294
// Data: 13/10/26
// Descrição: Ilustração decorativa de morros com árvores e uma casa,
// usada na tela de cadastro da propriedade.

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class PaisagemRural extends StatelessWidget {
  const PaisagemRural({super.key, this.altura = 140});

  final double altura;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: SizedBox(
        height: altura,
        width: double.infinity,
        child: const CustomPaint(painter: _PaisagemPainter()),
      ),
    );
  }
}

class _PaisagemPainter extends CustomPainter {
  const _PaisagemPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final morroDeTras = Path()
      ..moveTo(0, h * 0.50)
      ..quadraticBezierTo(w * 0.25, h * 0.15, w * 0.55, h * 0.45)
      ..quadraticBezierTo(w * 0.80, h * 0.65, w, h * 0.35)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();

    final morroDaFrente = Path()
      ..moveTo(0, h * 0.80)
      ..quadraticBezierTo(w * 0.30, h * 0.62, w * 0.60, h * 0.78)
      ..quadraticBezierTo(w * 0.85, h * 0.90, w, h * 0.70)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();

    canvas.drawPath(morroDeTras, Paint()..color = AppColors.morroClaro);
    _desenharArvore(canvas, Offset(w * 0.07, h * 0.78), h * 0.48);
    _desenharArvore(canvas, Offset(w * 0.15, h * 0.80), h * 0.38);
    canvas.drawPath(morroDaFrente, Paint()..color = AppColors.morroEscuro);
    _desenharCasa(canvas, Offset(w * 0.68, h * 0.84), h);
    _desenharArvore(canvas, Offset(w * 0.58, h * 0.84), h * 0.34);
    _desenharArvore(canvas, Offset(w * 0.82, h * 0.82), h * 0.44);
  }

  void _desenharArvore(Canvas canvas, Offset base, double altura) {
    final larguraTronco = altura * 0.08;
    final alturaCopa = altura * 0.75;

    canvas.drawRect(
      Rect.fromLTWH(
        base.dx - larguraTronco / 2,
        base.dy - altura * 0.35,
        larguraTronco,
        altura * 0.35,
      ),
      Paint()..color = AppColors.troncoArvore,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(base.dx, base.dy - altura + alturaCopa / 2),
        width: altura * 0.42,
        height: alturaCopa,
      ),
      Paint()..color = AppColors.copaArvore,
    );
  }

  void _desenharCasa(Canvas canvas, Offset base, double alturaTela) {
    final largura = alturaTela * 0.36;
    final alturaParede = alturaTela * 0.20;
    final alturaTelhado = alturaTela * 0.12;

    final parede = Rect.fromLTWH(
      base.dx - largura / 2,
      base.dy - alturaParede,
      largura,
      alturaParede,
    );

    final telhado = Path()
      ..moveTo(parede.left - largura * 0.08, parede.top)
      ..lineTo(base.dx, parede.top - alturaTelhado)
      ..lineTo(parede.right + largura * 0.08, parede.top)
      ..close();

    final porta = Rect.fromLTWH(
      base.dx - largura * 0.10,
      base.dy - alturaParede * 0.60,
      largura * 0.20,
      alturaParede * 0.60,
    );

    canvas.drawRect(parede, Paint()..color = AppColors.paredeCasa);
    canvas.drawPath(telhado, Paint()..color = AppColors.telhadoCasa);
    canvas.drawRect(porta, Paint()..color = AppColors.portaCasa);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}