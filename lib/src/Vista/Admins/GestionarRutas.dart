import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class RutasPage extends StatefulWidget {
  @override
  _RutasPageState createState() => _RutasPageState();
}

class _RutasPageState extends State<RutasPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _baseController = TextEditingController();
  final TextEditingController _cajaController = TextEditingController();
  final TextEditingController _cobradorController = TextEditingController();
  final TextEditingController _codigoController = TextEditingController();
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _superController = TextEditingController();
  final TextEditingController _supervisorController = TextEditingController();
  String? _errorMessage;
  String? _selectedRouteId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Rutas'),
        backgroundColor: Colors.teal,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore.collection('Rutas').snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(
                        child: Text('No hay rutas disponibles.'));
                  }

                  return ListView(
                    children: snapshot.data!.docs.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        elevation: 5,
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          title: Text(
                            data['Nombre'] ?? 'Sin nombre',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text('Código: ${data['Codigo']}'),
                          onTap: () => _editRoute(doc.id, data),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ),
            if (_selectedRouteId != null || _isAddingNew)
              Padding(
                padding: const EdgeInsets.only(top: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildTextField(_baseController, 'Base'),
                    _buildTextField(_cajaController, 'Caja'),
                    _buildTextField(_cobradorController, 'Cobrador'),
                    _buildTextField(
                      _codigoController,
                      'Código Ruta',
                      keyboardType: TextInputType.number,
                    ),
                    _buildTextField(_nombreController, 'Nombre de Ruta'),
                    _buildTextField(_superController, 'Super'),
                    _buildTextField(_supervisorController, 'Supervisor'),
                    if (_errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          _errorMessage!,
                          style:
                              const TextStyle(color: Colors.red, fontSize: 14),
                        ),
                      ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _limpiarCampos,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.teal,
                            ),
                            child: const Text('Limpiar Campos'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _addOrUpdateRoute,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.teal,
                            ),
                            child: Text(_selectedRouteId != null
                                ? 'Actualizar'
                                : 'Agregar'),
                          ),
                        ),
                        if (_selectedRouteId != null)
                          Expanded(
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: ElevatedButton(
                                onPressed: _deleteRutas,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                ),
                                child: const Text('Eliminar'),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _prepareForNewRoute,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
              ),
              child: const Text('Agregar Nueva Ruta'),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label,
      {TextInputType keyboardType = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
        keyboardType: keyboardType,
      ),
    );
  }

  bool get _isAddingNew => _selectedRouteId == null;

  void _editRoute(String routeId, Map<String, dynamic> data) {
    setState(() {
      _selectedRouteId = routeId;
      _baseController.text = data['Base'] ?? '';
      _cajaController.text = data['Caja'] ?? '';
      _cobradorController.text = data['Cobrador'] ?? '';
      _codigoController.text = data['Codigo'].toString();
      _nombreController.text = data['Nombre'] ?? '';
      _superController.text = data['Super'] ?? '';
      _supervisorController.text = data['Supervisor'] ?? '';
      _errorMessage = null;
    });
  }

  Future<void> _addOrUpdateRoute() async {
    final base = _baseController.text;
    final caja = _cajaController.text;
    final cobrador = _cobradorController.text;
    final codigoStr = _codigoController.text;
    final nombre = _nombreController.text;
    final superStr = _superController.text;
    final supervisor = _supervisorController.text;

    if (_isCodigoValido(codigoStr)) {
      final codigo = int.parse(codigoStr);
      try {
        final docRef = _firestore.collection('Rutas').doc(codigo.toString());
        if (_selectedRouteId == null) {
          final docSnapshot = await docRef.get();
          if (!docSnapshot.exists) {
            await docRef.set({
              'Base': base,
              'Caja': caja,
              'Cobrador': cobrador,
              'Codigo': codigo,
              'Nombre': nombre,
              'Super': superStr,
              'Supervisor': supervisor,
            });
          } else {
            setState(() {
              _errorMessage = 'El código ya existe.';
            });
          }
        } else {
          await docRef.update({
            'Base': base,
            'Caja': caja,
            'Cobrador': cobrador,
            'Codigo': codigo,
            'Nombre': nombre,
            'Super': superStr,
            'Supervisor': supervisor,
          });
        }
        _limpiarCampos();
      } catch (e) {
        setState(() {
          _errorMessage = 'Error al agregar/actualizar ruta: $e';
        });
      }
    } else {
      setState(() {
        _errorMessage = 'El código debe tener 4 dígitos.';
      });
    }
  }

  Future<void> _deleteRutas() async {
    if (_selectedRouteId != null) {
      try {
        await _firestore.collection('Rutas').doc(_selectedRouteId).delete();
        _limpiarCampos();
      } catch (e) {
        setState(() {
          _errorMessage = 'Error al eliminar ruta: $e';
        });
      }
    }
  }

  bool _isCodigoValido(String codigo) {
    final codigoInt = int.tryParse(codigo);
    return codigo.length == 2 && codigoInt != null;
  }

  void _limpiarCampos() {
    setState(() {
      _baseController.clear();
      _cajaController.clear();
      _cobradorController.clear();
      _codigoController.clear();
      _nombreController.clear();
      _superController.clear();
      _supervisorController.clear();
      _selectedRouteId = null;
      _errorMessage = null;
    });
  }

  void _prepareForNewRoute() {
    setState(() {
      _selectedRouteId = null;
      _baseController.clear();
      _cajaController.clear();
      _cobradorController.clear();
      _codigoController.clear();
      _nombreController.clear();
      _superController.clear();
      _supervisorController.clear();
      _errorMessage = null;
    });
  }
}
