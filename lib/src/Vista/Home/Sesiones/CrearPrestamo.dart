import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class CrearPrestamosScreen extends StatefulWidget {
  @override
  _CrearPrestamosScreenState createState() => _CrearPrestamosScreenState();
}

class _CrearPrestamosScreenState extends State<CrearPrestamosScreen> {
  final TextEditingController _cedulaController = TextEditingController();
  final TextEditingController _valorPrestamoController =
      TextEditingController();
  final TextEditingController _interesController = TextEditingController();
  final TextEditingController _cuotasController = TextEditingController();

  bool clienteExiste = false;
  String? _selectedMetodoPago;
  String? _selectedTipoPago;
  double _cuotaAproximada = 0.0;
  String? _selectedRuta;
  List<String> _rutas = [];

  final List<String> _metodosDePago = [
    '20 Días',
    '24 Días',
    'Semanal',
    'Quincenal',
    'Mensual',
  ];

  final List<String> _tiposDePago = [
    'Libre',
    'Interés + Capital',
  ];

  @override
  void initState() {
    super.initState();
    _obtenerRutas();
  }

  Future<void> _obtenerRutas() async {
    try {
      final QuerySnapshot querySnapshot =
          await FirebaseFirestore.instance.collection('Rutas').get();
      final List<String> rutas = querySnapshot.docs
          .where((doc) => doc['Nombre'] != null && doc['Nombre'] is String)
          .map((doc) => doc['Nombre'] as String)
          .toList();
      setState(() {
        _rutas = rutas;
      });
    } catch (e) {
      print('Error al obtener rutas: $e');
    }
  }

  double _calcularInteresIncrementado(double interesBase, int numeroCuotas) {
    double interesIncrementado = interesBase;
    if (_selectedTipoPago == 'Interés + Capital') {
      if (_selectedMetodoPago == 'Semanal' && numeroCuotas > 4) {
        interesIncrementado +=
            (numeroCuotas - 4) * 5; // Incremento de 5% por cada cuota adicional
      } else if (_selectedMetodoPago == 'Quincenal' && numeroCuotas > 2) {
        interesIncrementado += (numeroCuotas - 2) *
            10; // Incremento de 10% por cada cuota adicional
      }
    }
    return interesIncrementado;
  }

  void _calcularCuotaAproximada() {
    final valorPrestamo = double.tryParse(_valorPrestamoController.text) ?? 0;
    final interes = double.tryParse(_interesController.text) ?? 0;
    final numeroCuotas =
        int.tryParse(_cuotasController.text) ?? _getNumeroCuotasPorDefecto();

    if (valorPrestamo > 0 &&
        interes > 0 &&
        _selectedMetodoPago != null &&
        _selectedTipoPago != null &&
        numeroCuotas > 0) {
      double cuota;
      double interesFinal = _calcularInteresIncrementado(interes, numeroCuotas);

      if (_selectedTipoPago == 'Libre') {
        cuota = (valorPrestamo * (interesFinal / 100)) / numeroCuotas;
      } else if (_selectedTipoPago == 'Interés + Capital') {
        double interesTotal = valorPrestamo * (interesFinal / 100);
        cuota = (valorPrestamo + interesTotal) / numeroCuotas;
      } else {
        cuota = 0;
      }

      setState(() {
        _cuotaAproximada = cuota;
      });
    }
  }

  int _getNumeroCuotasPorDefecto() {
    if (_selectedMetodoPago == 'Semanal') {
      return 4;
    } else if (_selectedMetodoPago == 'Quincenal') {
      return 2;
    }
    return 1; // Valor por defecto si el método de pago no es Semanal o Quincenal
  }

  Future<void> verificarCliente() async {
    try {
      final cedula = _cedulaController.text;
      if (cedula.isNotEmpty) {
        final QuerySnapshot cliente = await FirebaseFirestore.instance
            .collection('Clientes')
            .where('Cedula', isEqualTo: cedula)
            .get();

        setState(() {
          clienteExiste = cliente.docs.isNotEmpty;
        });
      } else {
        setState(() {
          clienteExiste = false;
        });
      }
    } catch (e) {
      print('Error al verificar cliente: $e');
    }
  }

  Future<void> _guardarPrestamo() async {
    await verificarCliente();

    if (!clienteExiste) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cédula no encontrada')),
      );
      return;
    }

    final valorPrestamo = double.tryParse(_valorPrestamoController.text) ?? 0;
    final interesBase = double.tryParse(_interesController.text) ?? 0;
    final numeroCuotas =
        int.tryParse(_cuotasController.text) ?? _getNumeroCuotasPorDefecto();
    final interesIncrementado =
        _calcularInteresIncrementado(interesBase, numeroCuotas);
    final interesTotal = valorPrestamo * (interesIncrementado / 100);
    final valorTotal = valorPrestamo + interesTotal;
    final DateTime fechaActual = DateTime.now();
    final DateFormat formatoFecha = DateFormat('dd/MM/yyyy');
    final String fechaFormateada = formatoFecha.format(fechaActual);
    final String diaSemana = DateFormat('EEEE', 'es').format(fechaActual);

    if (valorPrestamo > 0 &&
        interesBase > 0 &&
        _selectedMetodoPago != null &&
        _selectedTipoPago != null &&
        _selectedRuta != null &&
        numeroCuotas > 0) {
      Map<String, dynamic> prestamoData = {
        'Cedula': _cedulaController.text,
        'Valor_Prestamo': valorPrestamo,
        'Interes': interesBase,
        'Interes_Incrementado': interesIncrementado,
        'ValorIntereses': interesTotal,
        'Metodo_Pago': _selectedMetodoPago,
        'Fecha': fechaFormateada,
        'DiaSemana': diaSemana,
        'ValorTotal': valorTotal,
        'Tipo_Pago': _selectedTipoPago,
        'Cuota_Aproximada': _cuotaAproximada,
        'Numero_Cuotas': numeroCuotas,
        'Ruta': _selectedRuta,
      };

      await FirebaseFirestore.instance
          .collection('Prestamos')
          .add(prestamoData);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Préstamo guardado exitosamente')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Por favor complete todos los campos')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    final double padding = isLandscape ? 24.0 : 16.0;

    return Scaffold(
      appBar: AppBar(
        title: Text('Crear Préstamo'),
        backgroundColor: Colors.blueAccent,
      ),
      body: Padding(
        padding: EdgeInsets.all(padding),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Ingrese los datos del préstamo',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.blueAccent,
                    ),
              ),
              SizedBox(height: 20),
              TextField(
                controller: _cedulaController,
                decoration: InputDecoration(
                  labelText: 'Cédula',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  verificarCliente();
                },
              ),
              SizedBox(height: 16),
              TextField(
                controller: _valorPrestamoController,
                decoration: InputDecoration(
                  labelText: 'Valor del Préstamo',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.monetization_on),
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) => _calcularCuotaAproximada(),
              ),
              SizedBox(height: 16),
              TextField(
                controller: _interesController,
                decoration: InputDecoration(
                  labelText: 'Porcentaje de Interés',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.percent),
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) => _calcularCuotaAproximada(),
              ),
              SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedMetodoPago,
                decoration: InputDecoration(
                  labelText: 'Método de Pago',
                  border: OutlineInputBorder(),
                ),
                items: _metodosDePago.map((metodo) {
                  return DropdownMenuItem(
                    value: metodo,
                    child: Text(metodo),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedMetodoPago = value;
                    _calcularCuotaAproximada();
                  });
                },
              ),
              SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedTipoPago,
                decoration: InputDecoration(
                  labelText: 'Tipo de Pago',
                  border: OutlineInputBorder(),
                ),
                items: _tiposDePago.map((tipo) {
                  return DropdownMenuItem(
                    value: tipo,
                    child: Text(tipo),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedTipoPago = value;
                    _calcularCuotaAproximada();
                  });
                },
              ),
              SizedBox(height: 16),
              if (_selectedTipoPago == 'Interés + Capital' &&
                  (_selectedMetodoPago == 'Semanal' ||
                      _selectedMetodoPago == 'Quincenal'))
                TextField(
                  controller: _cuotasController,
                  decoration: InputDecoration(
                    labelText: 'Número de Cuotas',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.calendar_view_day),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    _calcularCuotaAproximada();
                  },
                ),
              SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedRuta,
                decoration: InputDecoration(
                  labelText: 'Ruta',
                  border: OutlineInputBorder(),
                ),
                items: _rutas.isNotEmpty
                    ? _rutas.map((ruta) {
                        return DropdownMenuItem(
                          value: ruta,
                          child: Text(ruta),
                        );
                      }).toList()
                    : [
                        DropdownMenuItem(
                          value: null,
                          child: Text('No hay rutas disponibles'),
                        )
                      ],
                onChanged: (value) {
                  setState(() {
                    _selectedRuta = value;
                  });
                },
              ),
              SizedBox(height: 20),
              Text(
                'Cuota: ${_cuotaAproximada.toStringAsFixed(0)}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _guardarPrestamo,
                child: Text('Guardar Préstamo'),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16.0),
                  textStyle: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                  backgroundColor: Colors.blueAccent,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
