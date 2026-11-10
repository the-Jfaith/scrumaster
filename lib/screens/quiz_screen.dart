import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class QuizScreen extends StatefulWidget {
  final int nivelIndex;

  const QuizScreen({super.key, required this.nivelIndex});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  bool _respondido = false;
  int? _opcionSeleccionada;

  final int _minutosRecarga = 5;
  final int _maxErrores = 5;

  int _erroresRestantes = 5;
  int _aciertosConsecutivos = 0;

  List<QueryDocumentSnapshot> _colaPreguntas = [];
  Set<String> _preguntasIntentadas = {};
  int _totalPreguntasUnicas = 0;
  int _aciertosALaPrimera = 0;

  bool _cargando = true;
  bool _juegoTerminado = false;
  bool _esVictoria = false;

  @override
  void initState() {
    super.initState();
    _prepararLeccion();
  }

  Future<void> _prepararLeccion() async {
    try {
      var docRef = FirebaseFirestore.instance
          .collection('usuarios')
          .doc('usuario_demo');
      var userSnap = await docRef.get();

      if (userSnap.exists) {
        var userData = userSnap.data()!;
        _erroresRestantes =
            int.tryParse(userData['errores']?.toString() ?? "$_maxErrores") ??
            _maxErrores;
        _aciertosConsecutivos =
            int.tryParse(userData['aciertos']?.toString() ?? "0") ?? 0;

        Timestamp? ultimaRecarga = userData['ultima_recarga'];
        if (ultimaRecarga != null) {
          final diff = DateTime.now()
              .difference(ultimaRecarga.toDate())
              .inMinutes;
          if (diff >= _minutosRecarga && _erroresRestantes < _maxErrores) {
            _erroresRestantes = _maxErrores;
            await docRef.update({
              'errores': _erroresRestantes,
              'ultima_recarga': FieldValue.serverTimestamp(),
            });
          }
        } else {
          await docRef.update({'ultima_recarga': FieldValue.serverTimestamp()});
        }
      }

      var preguntasSnap = await FirebaseFirestore.instance
          .collection('preguntas')
          .get();
      var todasLasPreguntas = preguntasSnap.docs;

      todasLasPreguntas.shuffle();
      _colaPreguntas = todasLasPreguntas.take(5).toList();
      _totalPreguntasUnicas = _colaPreguntas.length;
    } catch (e) {
      debugPrint("Error: $e");
    } finally {
      setState(() {
        _cargando = false;
      });
    }
  }

  // 🔥 AQUÍ ESTÁ LA NUEVA LÓGICA DE EXPERIENCIA Y NIVELES
  Future<void> _guardarProgresoVictoria() async {
    var docRef = FirebaseFirestore.instance
        .collection('usuarios')
        .doc('usuario_demo');
    var docSnap = await docRef.get();

    if (docSnap.exists) {
      var userData = docSnap.data()!;
      List<dynamic> historial = userData['historial_estrellas'] ?? [];

      int monedasActuales =
          int.tryParse(userData['monedas']?.toString() ?? "0") ?? 0;
      int nivelActualUsuario =
          int.tryParse(userData['nivel']?.toString() ?? "1") ?? 1;
      int expActual =
          int.tryParse(userData['experiencia']?.toString() ?? "0") ?? 0;

      int estrellas = 1;
      if (_aciertosALaPrimera == _totalPreguntasUnicas)
        estrellas = 3;
      else if (_aciertosALaPrimera >= 3)
        estrellas = 2;

      if (widget.nivelIndex < historial.length) {
        if (estrellas > (historial[widget.nivelIndex] as int)) {
          historial[widget.nivelIndex] = estrellas;
        }
      } else {
        historial.add(estrellas);
      }

      int nuevasMonedas = monedasActuales + _aciertosALaPrimera;

      // Calculamos la nueva experiencia (10 XP por acierto a la primera)
      int xpGanada = _aciertosALaPrimera * 10;
      expActual += xpGanada;

      // Lógica de Subida de Nivel (Cada 100 XP = 1 Nivel)
      while (expActual >= 100) {
        nivelActualUsuario++;
        expActual -= 100; // Guardamos el sobrante para la próxima barra
      }

      await docRef.update({
        'historial_estrellas': historial,
        'monedas': nuevasMonedas,
        'nivel': nivelActualUsuario,
        'experiencia': expActual, // Guardamos la XP actualizada
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF4FA83D)),
        ),
      );
    }

    if (_juegoTerminado) {
      if (_esVictoria) {
        return _buildPantallaFinal(
          titulo: "¡Lección Completada!",
          mensaje: "Impresionante dedicación.",
          colorBase: Colors.orange.shade400,
          icono: Icons.emoji_events_rounded,
          esVictoria: true,
        );
      } else {
        return _buildPantallaFinal(
          titulo: "¡Te quedaste sin energía!",
          mensaje:
              "Tus rayitos llegarán a $_maxErrores nuevamente en $_minutosRecarga minutos.",
          colorBase: Colors.red,
          icono: Icons.flash_off_rounded,
          esVictoria: false,
        );
      }
    }

    var preguntaActual = _colaPreguntas.first;
    List<dynamic> opciones = preguntaActual['opciones'];
    int respuestaCorrecta = preguntaActual['respuesta_correcta'];
    String explicacion = preguntaActual['explicacion'];

    double progreso =
        (_totalPreguntasUnicas - _colaPreguntas.length) / _totalPreguntasUnicas;
    if (progreso < 0) progreso = 0;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.grey, size: 32),
          onPressed: () => Navigator.pop(context),
        ),
        title: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: progreso,
            minHeight: 12,
            backgroundColor: Colors.grey.shade200,
            color: const Color(0xFF4FA83D),
          ),
        ),
        actions: [
          const Icon(
            Icons.local_fire_department,
            color: Colors.orange,
            size: 26,
          ),
          const SizedBox(width: 4),
          Text(
            _aciertosConsecutivos.toString(),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.orange,
            ),
          ),
          const SizedBox(width: 12),
          const Icon(Icons.flash_on_rounded, color: Colors.amber, size: 26),
          const SizedBox(width: 4),
          Text(
            _erroresRestantes.toString(),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.redAccent,
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),

      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      preguntaActual['pregunta'],
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),

                    ...List.generate(opciones.length, (index) {
                      Color colorFondo = Colors.white;
                      Color colorBorde = Colors.grey.shade300;

                      if (_respondido) {
                        if (index == respuestaCorrecta) {
                          colorFondo = Colors.green.shade50;
                          colorBorde = Colors.green;
                        } else if (index == _opcionSeleccionada &&
                            index != respuestaCorrecta) {
                          colorFondo = Colors.red.shade50;
                          colorBorde = Colors.red;
                        }
                      }

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10.0),
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            backgroundColor: colorFondo,
                            side: BorderSide(color: colorBorde, width: 2),
                            padding: const EdgeInsets.symmetric(
                              vertical: 16,
                              horizontal: 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                          onPressed: _respondido
                              ? null
                              : () async {
                                  setState(() {
                                    _opcionSeleccionada = index;
                                    _respondido = true;
                                  });

                                  bool correcta = (index == respuestaCorrecta);
                                  String pId = preguntaActual.id;
                                  bool primeraVez = !_preguntasIntentadas
                                      .contains(pId);
                                  _preguntasIntentadas.add(pId);

                                  if (correcta) {
                                    _aciertosConsecutivos++;
                                    if (primeraVez) _aciertosALaPrimera++;
                                  } else {
                                    _aciertosConsecutivos = 0;
                                    _erroresRestantes--;
                                    if (_erroresRestantes < 0)
                                      _erroresRestantes = 0;
                                    _colaPreguntas.add(preguntaActual);
                                  }

                                  await FirebaseFirestore.instance
                                      .collection('usuarios')
                                      .doc('usuario_demo')
                                      .update({
                                        'aciertos': _aciertosConsecutivos,
                                        'errores': _erroresRestantes,
                                      });
                                },
                          child: Text(
                            opciones[index],
                            style: TextStyle(
                              fontSize: 16,
                              color:
                                  (_respondido && index == _opcionSeleccionada)
                                  ? Colors.black
                                  : Colors.black87,
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),

            if (_respondido) ...[
              const SizedBox(height: 12),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.25,
                ),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _opcionSeleccionada == respuestaCorrecta
                        ? Colors.green.shade50
                        : Colors.red.shade50,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: _opcionSeleccionada == respuestaCorrecta
                          ? Colors.green
                          : Colors.red,
                      width: 2,
                    ),
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        Text(
                          _opcionSeleccionada == respuestaCorrecta
                              ? '¡Excelente!'
                              : 'Respuesta incorrecta',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: _opcionSeleccionada == respuestaCorrecta
                                ? Colors.green.shade700
                                : Colors.red.shade700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          explicacion,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _opcionSeleccionada == respuestaCorrecta
                        ? const Color(0xFF4FA83D)
                        : Colors.red,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    elevation: 3,
                  ),
                  onPressed: () async {
                    if (_erroresRestantes <= 0) {
                      setState(() {
                        _juegoTerminado = true;
                        _esVictoria = false;
                      });
                    } else {
                      _colaPreguntas.removeAt(0);

                      if (_colaPreguntas.isEmpty) {
                        setState(() {
                          _cargando = true;
                        });
                        await _guardarProgresoVictoria();
                        setState(() {
                          _cargando = false;
                          _juegoTerminado = true;
                          _esVictoria = true;
                        });
                      } else {
                        setState(() {
                          _respondido = false;
                          _opcionSeleccionada = null;
                        });
                      }
                    }
                  },
                  child: const Text(
                    'CONTINUAR',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPantallaFinal({
    required String titulo,
    required String mensaje,
    required Color colorBase,
    required IconData icono,
    required bool esVictoria,
  }) {
    int xpGanada = _aciertosALaPrimera * 10;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(icono, size: 80, color: colorBase),
            const SizedBox(height: 24),
            Text(
              titulo,
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: colorBase,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              mensaje,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black54,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),

            if (esVictoria) ...[
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey.shade200, width: 2),
                ),
                child: Column(
                  children: [
                    _buildStatFila(
                      Icons.check_circle_outline,
                      Colors.green,
                      "Aciertos Perfectos",
                      "$_aciertosALaPrimera/$_totalPreguntasUnicas",
                    ),
                    const Divider(height: 24, thickness: 1.5),
                    _buildStatFila(
                      Icons.stars,
                      Colors.blue,
                      "Experiencia",
                      "+$xpGanada XP",
                    ),
                    const Divider(height: 24, thickness: 1.5),
                    _buildStatFila(
                      Icons.monetization_on,
                      Colors.amber,
                      "Monedas Ganadas",
                      "+$_aciertosALaPrimera",
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
            ],

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: colorBase,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'CONTINUAR',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatFila(
    IconData icono,
    Color color,
    String titulo,
    String valor,
  ) {
    return Row(
      children: [
        Icon(icono, color: color, size: 28),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            titulo,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
        Text(
          valor,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
