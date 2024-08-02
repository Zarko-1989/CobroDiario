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

  bool clienteExiste = false;
  String? _selectedMetodoPago;
  String? _selectedTipoPago;
  int _numeroCuotas = 0;
  double _cuotaAproximada = 0.0;

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

  final List<int> _cuotasSemanal = [5, 6, 7, 8, 9, 10, 11, 12];
  final List<int> _cuotasQuincenal = [3, 4, 5, 6, 7, 8, 9, 10];

  double _calcularInteresIncrementado(double interesBase) {
    double interesIncrementado = interesBase;
    if (_selectedTipoPago == 'Interés + Capital') {
      if (_selectedMetodoPago == 'Semanal' && _numeroCuotas > 4) {
        interesIncrementado += (_numeroCuotas - 4) *
            5; // Incremento de 5% por cada cuota adicional
      } else if (_selectedMetodoPago == 'Quincenal' && _numeroCuotas > 2) {
        interesIncrementado += (_numeroCuotas - 2) *
            10; // Incremento de 10% por cada cuota adicional
      }
    }
    return interesIncrementado;
  }

  void _calcularCuotaAproximada() {
    final valorPrestamo = double.tryParse(_valorPrestamoController.text) ?? 0;
    final interes = double.tryParse(_interesController.text) ?? 0;

    if (valorPrestamo > 0 &&
        interes > 0 &&
        _selectedMetodoPago != null &&
        _selectedTipoPago != null) {
      int numCuotas = _getNumeroCuotas(_selectedMetodoPago!);
      double cuota;
      double interesFinal = _calcularInteresIncrementado(interes);

      if (_selectedTipoPago == 'Libre') {
        cuota = (valorPrestamo * (interesFinal / 100)) / numCuotas;
      } else if (_selectedTipoPago == 'Interés + Capital') {
        double interesTotal = valorPrestamo * (interesFinal / 100);
        cuota = (valorPrestamo + interesTotal) / numCuotas;
      } else {
        cuota = 0;
      }

      setState(() {
        _cuotaAproximada = cuota;
      });
    }
  }

  int _getNumeroCuotas(String metodoPago) {
    switch (metodoPago) {
      case '20 Días':
        return 20;
      case '24 Días':
        return 24;
      case 'Semanal':
        return _numeroCuotas > 0 ? _numeroCuotas : 4;
      case 'Quincenal':
        return _numeroCuotas > 0 ? _numeroCuotas : 2;
      case 'Mensual':
        return 1;
      default:
        return 1;
    }
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
    final interesIncrementado = _calcularInteresIncrementado(interesBase);
    final interesTotal = valorPrestamo * (interesIncrementado / 100);
    final valorTotal = valorPrestamo + interesTotal;
    final DateTime fechaActual = DateTime.now();
    final DateFormat formatoFecha = DateFormat('dd/MM/yyyy');
    final String fechaFormateada = formatoFecha.format(fechaActual);
    final String diaSemana = DateFormat('EEEE', 'es').format(fechaActual);
    final numeroCuotas = _getNumeroCuotas(_selectedMetodoPago!);

    if (valorPrestamo > 0 &&
        interesBase > 0 &&
        _selectedMetodoPago != null &&
        _selectedTipoPago != null) {
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
                    _numeroCuotas = 0; // Reset number of installments
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
                    _numeroCuotas = 0; // Reset number of installments
                    _calcularCuotaAproximada();
                  });
                },
              ),
              SizedBox(height: 16),
              if (_selectedTipoPago == 'Interés + Capital' &&
                  (_selectedMetodoPago == 'Semanal' ||
                      _selectedMetodoPago == 'Quincenal' ||
                      _selectedMetodoPago == '20 Días' ||
                      _selectedMetodoPago == '24 Días'))
                DropdownButtonFormField<int>(
                  value: _numeroCuotas > 0 ? _numeroCuotas : null,
                  decoration: InputDecoration(
                    labelText: 'Número de Cuotas',
                    border: OutlineInputBorder(),
                  ),
                  items: (_selectedMetodoPago == 'Semanal'
                          ? _cuotasSemanal
                          : _selectedMetodoPago == 'Quincenal'
                              ? _cuotasQuincenal
                              : _selectedMetodoPago == '20 Días'
                                  ? [20]
                                  : _selectedMetodoPago == '24 Días'
                                      ? [24]
                                      : [1])
                      .map((cuotas) {
                    return DropdownMenuItem(
                      value: cuotas,
                      child: Text('$cuotas Cuotas'),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _numeroCuotas = value ?? 0;
                      _calcularCuotaAproximada();
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
