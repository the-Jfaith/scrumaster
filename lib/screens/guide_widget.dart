import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class GuideOverlayWidget extends StatefulWidget {
  final int seccionIndex;
  final VoidCallback onClose;

  const GuideOverlayWidget({
    super.key,
    required this.seccionIndex,
    required this.onClose,
  });

  @override
  State<GuideOverlayWidget> createState() => _GuideOverlayWidgetState();
}

class _GuideOverlayWidgetState extends State<GuideOverlayWidget> {
  late Future<DocumentSnapshot> _guiaFuture;
  final List<ExpansionTileController> _controladores = [];
  int? _indiceExpandido;

  @override
  void initState() {
    super.initState();
    _guiaFuture = FirebaseFirestore.instance
        .collection('guias_seccion')
        .doc('seccion_${widget.seccionIndex}')
        .get();
  }

  @override
  Widget build(BuildContext context) {
    final double alturaMaxima = MediaQuery.of(context).size.height * 0.8;

    return Container(
      color: Colors.black.withOpacity(0.4),
      alignment: Alignment.center,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: FutureBuilder<DocumentSnapshot>(
          future: _guiaFuture,
          builder: (context, snapshot) {
            return Container(
              constraints: BoxConstraints(maxHeight: alturaMaxima),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
                border: Border.all(color: const Color(0xFF6BD0D7), width: 3),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.4),
                    blurRadius: 15,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(16),
              child: _buildContenido(snapshot),
            );
          },
        ),
      ),
    );
  }

  Widget _buildContenido(AsyncSnapshot<DocumentSnapshot> snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Color(0xFF6BD0D7)),
          SizedBox(height: 12),
          Text(
            'Abriendo guía...',
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
        ],
      );
    }

    if (!snapshot.hasData || !snapshot.data!.exists) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, color: Colors.orange, size: 40),
          const SizedBox(height: 12),
          const Text(
            'Guía no encontrada',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildBotonCerrar(),
        ],
      );
    }

    var guiaData = snapshot.data!.data() as Map<String, dynamic>;
    String titulo = guiaData['titulo'] ?? 'Guía de la Sección';
    List<dynamic> temas = guiaData['temas'] ?? [];

    if (_controladores.length < temas.length) {
      for (int i = _controladores.length; i < temas.length; i++) {
        _controladores.add(ExpansionTileController());
      }
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.menu_book_rounded,
              color: Color(0xFF6BD0D7),
              size: 26,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                titulo,
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF6BD0D7),
                ),
              ),
            ),
          ],
        ),
        const Divider(height: 20, thickness: 2, color: Color(0xFFE0E0E0)),

        Flexible(
          child: temas.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'Aún no hay temas agregados.',
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: temas.length,
                  itemBuilder: (context, index) {
                    var temaActual = temas[index] as Map<String, dynamic>;
                    String frase = temaActual['frase'] ?? 'Sin título';
                    String texto = temaActual['texto'] ?? 'Sin contenido';

                    return Card(
                      elevation: 0,
                      color: Colors.grey.shade50,
                      shape: RoundedRectangleBorder(
                        side: BorderSide(
                          color: Colors.grey.shade300,
                          width: 1.5,
                        ),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ExpansionTile(
                        controller: _controladores[index],
                        onExpansionChanged: (estaExpandido) {
                          if (estaExpandido) {
                            if (_indiceExpandido != null &&
                                _indiceExpandido != index) {
                              _controladores[_indiceExpandido!].collapse();
                            }
                            setState(() {
                              _indiceExpandido = index;
                            });
                          } else {
                            if (_indiceExpandido == index) {
                              setState(() {
                                _indiceExpandido = null;
                              });
                            }
                          }
                        },

                        iconColor: const Color(0xFF6BD0D7),
                        collapsedIconColor: Colors.grey.shade400,
                        title: Text(
                          frase,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: Colors.black87,
                          ),
                        ),
                        childrenPadding: const EdgeInsets.only(
                          left: 16,
                          right: 16,
                          bottom: 12,
                        ),
                        children: [
                          Container(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              texto,
                              style: const TextStyle(
                                fontSize: 14,
                                height: 1.4,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),

        const SizedBox(height: 12),
        _buildBotonCerrar(),
      ],
    );
  }

  Widget _buildBotonCerrar() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF4FA83D),
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          elevation: 3,
        ),
        onPressed: widget
            .onClose,
        child: const Text(
          'ENTENDIDO',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
