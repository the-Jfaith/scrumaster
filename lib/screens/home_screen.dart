import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'guide_widget.dart';
import 'quiz_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final Color barraColor = const Color(0xFF6BD0D7);
  final Color grisNivel = const Color(0xFFA5B899);
  final Color verdeNivel = const Color(0xFF4FA83D);
  final Color amarilloNivel = const Color(0xFFEBCB56);

  bool _mostrarGuia = false;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('usuarios')
          .doc('usuario_demo')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Colors.white,
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Scaffold(
            backgroundColor: Colors.white,
            body: Center(child: Text('Falta el documento "usuario_demo"')),
          );
        }

        var userData = snapshot.data!.data() as Map<String, dynamic>;

        // Extraemos las variables numéricas para el progreso
        int nivelActualUsuario =
            int.tryParse(userData['nivel']?.toString() ?? "1") ?? 1;
        int expActual =
            int.tryParse(userData['experiencia']?.toString() ?? "0") ?? 0;

        // Calculamos el porcentaje de la barra (de 0.0 a 1.0)
        double progresoExp = expActual / 100.0;

        String monedas = userData['monedas']?.toString() ?? "0";
        String erroresTexto = userData['errores']?.toString() ?? "0";
        String racha = userData['aciertos']?.toString() ?? "0";
        List<dynamic> amigos = userData['amigos'] ?? [];
        List<dynamic> historialEstrellas =
            userData['historial_estrellas'] ?? [];

        int energiaActual = int.tryParse(erroresTexto) ?? 0;
        int nivelActual = historialEstrellas.length;
        int seccionActual = (nivelActual / 3).floor();
        if (seccionActual > 1) seccionActual = 1;

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: barraColor,
            elevation: 0,
            toolbarHeight: 70,
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildNivelBadge(nivelActualUsuario, progresoExp),
                _buildBadge(
                  texto: monedas,
                  colorFondo: Colors.orange.shade300,
                  cuadrado: false,
                ),
                _buildIconoConTexto(
                  Icons.flash_on_rounded,
                  Colors.yellowAccent,
                  erroresTexto,
                ),
                _buildIconoConTexto(
                  Icons.local_fire_department,
                  Colors.redAccent,
                  racha,
                ),
              ],
            ),
          ),
          body: Stack(
            children: [
              ListView(
                padding: const EdgeInsets.symmetric(vertical: 30),
                children: _generarRutasPorSeccion(
                  historialEstrellas,
                  context,
                  energiaActual,
                ),
              ),

              Positioned(
                top: 20,
                right: 20,
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _mostrarGuia = true;
                    });
                  },
                  child: Transform.rotate(
                    angle: 0.3,
                    child: Icon(
                      Icons.menu_book_rounded,
                      color: Colors.green.shade400,
                      size: 45,
                    ),
                  ),
                ),
              ),

              Positioned(
                bottom: 30,
                right: 20,
                child: Icon(
                  Icons.arrow_upward_rounded,
                  color: Colors.grey.shade400,
                  size: 40,
                ),
              ),

              if (_mostrarGuia)
                Positioned.fill(
                  child: IgnorePointer(
                    ignoring: !_mostrarGuia,
                    child: AnimatedOpacity(
                      opacity: _mostrarGuia ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeInOut,
                      child: GuideOverlayWidget(
                        seccionIndex: seccionActual,
                        onClose: () {
                          setState(() {
                            _mostrarGuia = false;
                          });
                        },
                      ),
                    ),
                  ),
                ),
            ],
          ),
          bottomNavigationBar: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            backgroundColor: barraColor,
            showSelectedLabels: false,
            showUnselectedLabels: false,
            iconSize: 32,
            elevation: 0,
            items: [
              const BottomNavigationBarItem(
                icon: Icon(Icons.person, color: Colors.white),
                label: 'Usuario',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.emoji_events, color: Colors.amber),
                label: 'Torneo',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.fitness_center, color: Colors.grey),
                label: 'Repasar',
              ),
              BottomNavigationBarItem(
                icon: Badge(
                  isLabelVisible: amigos.isNotEmpty,
                  label: Text(amigos.length.toString()),
                  child: const Icon(Icons.group, color: Colors.white),
                ),
                label: 'Amigos',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.inventory_2, color: Colors.brown),
                label: 'Tienda',
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNivelBadge(int nivel, double progreso) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.indigo.shade300,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "Lvl $nivel",
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 5),
          SizedBox(
            width: 45, // Ancho de la pequeña barrita
            child: ClipRRect(
              borderRadius: BorderRadius.circular(5),
              child: LinearProgressIndicator(
                value: progreso,
                minHeight: 6,
                backgroundColor: Colors.indigo.shade100,
                color: Colors.yellowAccent,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge({
    required String texto,
    required Color colorFondo,
    required bool cuadrado,
  }) {
    return Container(
      padding: EdgeInsets.all(cuadrado ? 4 : 8),
      decoration: BoxDecoration(
        color: colorFondo,
        borderRadius: BorderRadius.circular(cuadrado ? 8 : 20),
      ),
      child: Text(
        texto,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildIconoConTexto(IconData icono, Color colorIcono, String texto) {
    return Row(
      children: [
        Icon(icono, color: colorIcono, size: 35),
        Text(
          texto,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ],
    );
  }

  List<Widget> _generarRutasPorSeccion(
    List<dynamic> historial,
    BuildContext context,
    int energiaActual,
  ) {
    List<Widget> ruta = [];
    List<String> titulosSecciones = [
      'Sección 1: Fundamentos',
      'Sección 2: Ceremonias',
    ];
    int nivelesPorSeccion = 3;
    int nivelGlobal = 0;
    List<double> alineaciones = [0.0, -0.25, 0.25];

    for (int s = 0; s < titulosSecciones.length; s++) {
      ruta.add(_buildSeccionHeader(titulosSecciones[s]));
      ruta.add(const SizedBox(height: 30));

      for (int l = 0; l < nivelesPorSeccion; l++) {
        Color colorNivel;
        int estrellas = 0;

        if (nivelGlobal < historial.length) {
          estrellas = int.tryParse(historial[nivelGlobal].toString()) ?? 0;
          colorNivel = (estrellas == 3) ? amarilloNivel : verdeNivel;
        } else if (nivelGlobal == historial.length) {
          colorNivel = verdeNivel;
          estrellas = 0;
        } else {
          colorNivel = grisNivel;
          estrellas = 0;
        }

        bool nivelDesbloqueado = nivelGlobal <= historial.length;

        ruta.add(
          _buildNivelLibro(
            context: context,
            color: colorNivel,
            estrellasActivas: estrellas,
            alineacion: alineaciones[l],
            desbloqueado: nivelDesbloqueado,
            nivelIndex: nivelGlobal,
            energiaActual: energiaActual,
          ),
        );

        if (l < nivelesPorSeccion - 1) {
          ruta.add(_buildCaminoPuntos(alineaciones[l], alineaciones[l + 1]));
        } else if (s < titulosSecciones.length - 1) {
          ruta.add(const SizedBox(height: 10));
          ruta.add(_buildCaminoPuntos(alineaciones[l], 0.0));
          ruta.add(const SizedBox(height: 20));
        }

        nivelGlobal++;
      }
    }
    return ruta;
  }

  Widget _buildSeccionHeader(String titulo) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
        decoration: BoxDecoration(
          color: barraColor,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              offset: const Offset(0, 5),
              blurRadius: 0,
            ),
          ],
        ),
        child: Text(
          titulo,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildNivelLibro({
    required BuildContext context,
    required Color color,
    required int estrellasActivas,
    required double alineacion,
    required bool desbloqueado,
    required int nivelIndex,
    required int energiaActual,
  }) {
    return Align(
      alignment: Alignment(alineacion, 0),
      child: GestureDetector(
        onTap: () {
          if (desbloqueado) {
            if (energiaActual > 0) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => QuizScreen(nivelIndex: nivelIndex),
                ),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    '¡Te quedaste sin energía! Espera a que se recargue.',
                  ),
                  backgroundColor: Colors.redAccent,
                  duration: Duration(seconds: 2),
                ),
              );
            }
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Nivel bloqueado. ¡Completa los anteriores primero!',
                ),
                backgroundColor: Colors.orange,
                duration: Duration(seconds: 2),
              ),
            );
          }
        },
        child: Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                offset: const Offset(0, 6),
                blurRadius: 0,
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                height: 10,
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
              const Spacer(),
              desbloqueado
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(3, (index) {
                        return Icon(
                          Icons.star_rounded,
                          color: index < estrellasActivas
                              ? Colors.white
                              : Colors.white.withOpacity(0.3),
                          size: 22,
                        );
                      }),
                    )
                  : const Icon(
                      Icons.lock_rounded,
                      color: Colors.white70,
                      size: 28,
                    ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCaminoPuntos(
    double alineacionActual,
    double alineacionSiguiente,
  ) {
    int pasos = 3;
    List<Widget> puntos = [];
    double distanciaPorPaso =
        (alineacionSiguiente - alineacionActual) / (pasos + 1);

    for (int i = 1; i <= pasos; i++) {
      double pos = alineacionActual + (distanciaPorPaso * i);
      puntos.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Align(
            alignment: Alignment(pos, 0),
            child: Icon(Icons.circle, size: 10, color: barraColor),
          ),
        ),
      );
    }
    return Column(children: puntos);
  }
}
