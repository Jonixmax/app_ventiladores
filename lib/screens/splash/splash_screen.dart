import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/gradients.dart';
import '../login/login_screen.dart';

class PantallaSplash extends StatefulWidget {
  const PantallaSplash({super.key});
  @override
  State createState() { return _PantallaSplashState(); }
}

class _PantallaSplashState extends State<PantallaSplash> with TickerProviderStateMixin {
  late AnimationController _controladorFade;
  late Animation _animacionFade;
  late AnimationController _controladorEscala;
  late Animation<double> _animacionEscala;

  @override
  void initState() {
    super.initState();
    _controladorFade = AnimationController(vsync: this, duration: const Duration(seconds: 2));
    _animacionFade = Tween(begin: 0.0, end: 1.0).animate(_controladorFade);
    _controladorEscala = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _animacionEscala = CurvedAnimation(parent: _controladorEscala, curve: Curves.elasticOut);
    _controladorFade.forward();
    _controladorEscala.forward();
    _iniciarApp();
  }

  _iniciarApp() async {
    await Future.delayed(const Duration(seconds: 3));
    if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) { return const PantallaLogin(); }));
  }

  @override
  void dispose() { _controladorFade.dispose(); _controladorEscala.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: gradientePrincipal),
        child: Center(
          child: FadeTransition(
            opacity: _animacionFade as Animation<double>,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ScaleTransition(
                  scale: _animacionEscala,
                  child: Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: colorCeleste.withOpacity(0.45), blurRadius: 40, spreadRadius: 4),
                        BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 15, offset: const Offset(0, 10)),
                      ],
                    ),
                    child: ClipOval(
                      child: Transform.scale(
                        scale: 1.6, // El zoom que ya teníamos
                        child: Transform.translate(
                          // Offset(Derecha/Izquierda, Abajo/Arriba)
                          // Positivo mueve a la derecha y abajo. Negativo a la izquierda y arriba.
                          offset: const Offset(5, 10),
                          child: Image.asset('assets/kiro_feliz.png', fit: BoxFit.cover),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                const Text('KITHER', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: 6)),
                const SizedBox(height: 4),
                Text('VENTILACIÓN INTELIGENTE', style: TextStyle(color: Colors.white.withOpacity(0.65), fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 3)),
                const SizedBox(height: 36),
                SizedBox(
                  width: 32, height: 32,
                  child: CircularProgressIndicator(color: colorCeleste, strokeWidth: 3),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
