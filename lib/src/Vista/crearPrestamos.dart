import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // Asegúrate de importar intl

class CrearPrestamosScreen extends StatefulWidget {
  @override
  _CrearPrestamosScreenState createState() => _CrearPrestamosScreenState();
}

class _CrearPrestamosScreenState extends State<CrearPrestamosScreen> {
  final TextEditingController cedulaController = TextEditingController();
  final TextEditingController valorController = TextEditingController();
  final TextEditingController interesController = TextEditingController();
  final TextEditingController customPeriodoController = TextEditingController();

  final FirebaseFirestore firebase = FirebaseFirestore.instance;

  String formaPago = 'Semanal';
  String tipoPago = 'Libre';
  bool clienteExiste = true;
  double cuota = 0.0;
  int? cantidaddeCuotas;
  bool isCustomPeriod = false;

  @override
  void initState() {
    super.initState();
    cedulaController.addListener(() => verificarCliente());
    valorController.addListener(() => calcularCuota());
    interesController.addListener(() => calcularCuota());
  }

  Future<void> verificarCliente() async {
    try {
      final QuerySnapshot cliente = await firebase
          .collection('Clientes')
          .where('Cedula', isEqualTo: cedulaController.text)
          .get();
      setState(() {
        clienteExiste = cliente.docs.isNotEmpty;
      });
    } catch (e) {
      print('Error al verificar cliente: $e');
    }
  }

  void calcularCuota() {
    try {
      final double valorPrestamo = double.parse(valorController.text);
      final double interesBase = tipoPago == 'Interes+Capital'
          ? double.parse(interesController.text)
          : 0.0;

      final double interesIncrementado =
          _calcularInteresIncrementado(interesBase);
      final double valorIntereses = valorPrestamo * (interesIncrementado / 100);
      final double valorTotal = valorPrestamo + valorIntereses;

      final double cantidadPagos = _obtenerCantidadPagos();
      cuota =
          (valorPrestamo / cantidadPagos) + (valorIntereses / cantidadPagos);

      setState(() {});
    } catch (e) {
      print('Error al calcular cuota: $e');
    }
  }

  double _calcularInteresIncrementado(double interesBase) {
    double interesIncrementado = interesBase;
    if (tipoPago == 'Interes+Capital') {
      if (formaPago == 'Quincenal' && cantidaddeCuotas != null) {
        interesIncrementado += (cantidaddeCuotas! - 2) * 10;
      } else if (formaPago == 'Semanal' && cantidaddeCuotas != null) {
        interesIncrementado += (cantidaddeCuotas! - 4) * 5;
      }
    }
    return interesIncrementado;
  }

  double _obtenerCantidadPagos() {
    if (formaPago == 'Quincenal') {
      return cantidaddeCuotas?.toDouble() ?? 2.0;
    } else if (formaPago == 'Semanal') {
      return cantidaddeCuotas?.toDouble() ?? 4.0;
    } else if (formaPago == '20 Dias') {
      return 20.0;
    } else if (formaPago == '24 Dias') {
      return 24.0;
    } else if (formaPago == 'Mensual') {
      return 1.0;
    } else {
      return 0.0;
    }
  }

  Future<void> registroPrestamo() async {
    if (!clienteExiste) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El cliente no existe'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    try {
      final double valorPrestamo = double.parse(valorController.text);
      final double interesBase = tipoPago == 'Interes+Capital'
          ? double.parse(interesController.text)
          : 0.0;

      final double interesIncrementado =
          _calcularInteresIncrementado(interesBase);
      final double valorIntereses = valorPrestamo * (interesIncrementado / 100);
      final double valorTotal = valorPrestamo + valorIntereses;

      final double cantidadPagos = _obtenerCantidadPagos();
      cuota =
          (valorPrestamo / cantidadPagos) + (valorIntereses / cantidadPagos);

      final String prestamoId = firebase.collection('Prestamos').doc().id;

      final DateTime fechaActual = DateTime.now();
      final DateFormat formatoFecha = DateFormat('dd/MM/yyyy');
      final String fechaFormateada = formatoFecha.format(fechaActual);
      final String diaSemana = DateFormat('EEEE', 'es').format(fechaActual);

      await firebase.collection('Prestamos').doc(prestamoId).set({
        "CedulaCliente": int.parse(cedulaController.text),
        "ValorPrestamo": valorPrestamo,
        "ValorIntereses": valorIntereses,
        "FormaPago": formaPago,
        "TipoPago": tipoPago,
        "Cuota": cuota,
        "Fecha": fechaFormateada, // Fecha en formato DD/MM/AAAA
        "DiaSemana": diaSemana, // Día de la semana
        "ValorTotal": valorTotal,
        "cantidaddeCuotas": cantidaddeCuotas,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Préstamo registrado satisfactoriamente'),
          duration: Duration(seconds: 2),
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      print('Error al registrar préstamo: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error al registrar préstamo'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Registrar Préstamo'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTextField(
                cedulaController, 'Cédula del Cliente', TextInputType.number),
            const SizedBox(height: 20),
            if (!clienteExiste)
              const Text(
                'El cliente no existe',
                style: TextStyle(color: Colors.red),
              ),
            _buildTextField(valorController, 'Valor del Préstamo',
                const TextInputType.numberWithOptions(decimal: false)),
            const SizedBox(height: 20),
            _buildTextField(interesController, 'Interés',
                const TextInputType.numberWithOptions(decimal: false)),
            const SizedBox(height: 20),
            const Text('Forma de Pago:'),
            _buildDropdown(
              value: formaPago,
              items: ['20 Dias', '24 Dias', 'Semanal', 'Quincenal', 'Mensual'],
              onChanged: (value) {
                setState(() {
                  formaPago = value!;
                  cantidaddeCuotas = null;
                  customPeriodoController.clear();
                  isCustomPeriod = false;
                  calcularCuota();
                });
              },
            ),
            const SizedBox(height: 20),
            if (formaPago == 'Quincenal') _buildQuincenalSection(),
            if (formaPago == 'Semanal') _buildSemanalSection(),
            const SizedBox(height: 20),
            const Text('Tipo de Pago:'),
            _buildDropdown(
              value: tipoPago,
              items: ['Libre', 'Interes+Capital'],
              onChanged: (value) {
                setState(() {
                  tipoPago = value!;
                  calcularCuota();
                });
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: registroPrestamo,
              child: const Text('Registrar Préstamo'),
            ),
            const SizedBox(height: 20),
            if (cuota != 0.0)
              Text(
                'Cuota Calculada: \$${cuota.toStringAsFixed(0)}',
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String labelText,
      TextInputType keyboardType) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(labelText: labelText),
      keyboardType: keyboardType,
      onChanged: (value) => calcularCuota(),
    );
  }

  Widget _buildDropdown(
      {required String value,
      required List<String> items,
      required ValueChanged<String?> onChanged}) {
    return DropdownButton<String>(
      value: value,
      onChanged: onChanged,
      items: items.map<DropdownMenuItem<String>>((String item) {
        return DropdownMenuItem<String>(
          value: item,
          child: Text(item),
        );
      }).toList(),
    );
  }

  Widget _buildQuincenalSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Selecciona la cantidad de quincenas:'),
        _buildChoiceChips([3, 4, 5, 6, 'X'], 'Quincenas'),
        if (isCustomPeriod)
          _buildTextField(customPeriodoController, 'Cantidad de Quincenas',
              TextInputType.number),
        if (isCustomPeriod)
          ElevatedButton(
            onPressed: () {
              setState(() {
                cantidaddeCuotas = int.tryParse(customPeriodoController.text);
                calcularCuota();
              });
            },
            child: const Text('Actualizar Cuotas'),
          ),
      ],
    );
  }

  Widget _buildSemanalSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Selecciona la cantidad de semanas:'),
        _buildChoiceChips([4, 8, 12, 16, 'X'], 'Semanas'),
        if (isCustomPeriod)
          _buildTextField(customPeriodoController, 'Cantidad de Semanas',
              TextInputType.number),
        if (isCustomPeriod)
          ElevatedButton(
            onPressed: () {
              setState(() {
                cantidaddeCuotas = int.tryParse(customPeriodoController.text);
                calcularCuota();
              });
            },
            child: const Text('Actualizar Cuotas'),
          ),
      ],
    );
  }

  Widget _buildChoiceChips(List<dynamic> choices, String label) {
    return Wrap(
      spacing: 8.0,
      children: choices.map<Widget>((choice) {
        return ChoiceChip(
          label: Text(choice is int ? choice.toString() : choice),
          selected: cantidaddeCuotas == (choice is int ? choice : null),
          onSelected: (selected) {
            setState(() {
              if (selected) {
                cantidaddeCuotas = choice is int ? choice : null;
                isCustomPeriod = choice == 'X';
                customPeriodoController.clear();
                calcularCuota();
              }
            });
          },
        );
      }).toList(),
    );
  }
}
