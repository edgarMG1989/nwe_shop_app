import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shop_app/data/data_provider_venta.dart';
import 'package:shop_app/models/usuario_model.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:shop_app/screens/orders_screen.dart';

class CheckoutScreen extends StatefulWidget {
  final List<dynamic> cartItems;
  final double total;
  final Usuario? usuario;

  const CheckoutScreen({
    super.key,
    required this.cartItems,
    required this.total,
    this.usuario,
  });

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController nombreController;
  late TextEditingController apellidoController;
  late TextEditingController correoController;
  late TextEditingController telefonoController;
  late TextEditingController direccionController;

  bool loading = false;
  bool isFormValid = false;

  @override
  void initState() {
    super.initState();

    nombreController = TextEditingController(
      text: widget.usuario?.nombre ?? "",
    );
    apellidoController = TextEditingController(
      text: widget.usuario?.apellidoPaterno ?? "",
    );
    correoController = TextEditingController(
      text: widget.usuario?.correo ?? "",
    );
    telefonoController = TextEditingController(
      text: widget.usuario?.telefono ?? "",
    );
    direccionController = TextEditingController();

    _addListeners();
    _validateForm();
  }

  void _addListeners() {
    nombreController.addListener(_validateForm);
    apellidoController.addListener(_validateForm);
    correoController.addListener(_validateForm);
    telefonoController.addListener(_validateForm);
    direccionController.addListener(_validateForm);
  }

  void _validateForm() {
    final valid =
        nombreController.text.trim().isNotEmpty &&
        apellidoController.text.trim().isNotEmpty &&
        correoController.text.trim().isNotEmpty &&
        telefonoController.text.trim().isNotEmpty &&
        direccionController.text.trim().isNotEmpty;

    setState(() => isFormValid = valid);
  }

  Future<void> _initPayment() async {
    try {
      setState(() => loading = true);

      final total = widget.total;
      final body = {"amount": (total * 100).toInt().toString()};

      final data = await VentaService.intencionPago(body);

      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          merchantDisplayName: "LA ROPA NOSTRAA",
          paymentIntentClientSecret: data['paymentIntent'],
          customerEphemeralKeySecret: data['ephemeralKey'],
          customerId: data['customer'],
          style: ThemeMode.light,
        ),
      );

      await Stripe.instance.presentPaymentSheet();

      await _registrarVenta();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      setState(() => loading = false);
    }
  }

  Future<void> _registrarVenta() async {
    final productos = widget.cartItems.map((item) {
      return {
        "idProducto": item["idProducto"],
        "idTalla": item["idTalla"],
        "cantidad": item["cantidad"],
        "precio": item["precio"],
        "precioOferta": item["precioOferta"] ?? item["precio"],
      };
    }).toList();

    final bodyVenta = {
      "idUsuarioCompra": widget.usuario?.idUsuario ?? 0,
      "nombre": nombreController.text.trim(),
      "apellido": apellidoController.text.trim(),
      "direccion": direccionController.text.trim(),
      "telefono": telefonoController.text.trim(),
      "correo": correoController.text.trim(),
      "total": widget.total,
      "productos": jsonEncode(productos),
    };

    final result = await VentaService.addVenta(bodyVenta);

    if (!mounted) return;

    if (result["success"] == 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Compra registrada correctamente")),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => OrdersScreen(usuario: widget.usuario),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al registrar: ${result['message']}")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool logged = widget.usuario != null;

    return Scaffold(
      appBar: AppBar(title: const Text("Datos de envío")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Información del cliente",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),

              TextFormField(
                controller: nombreController,
                readOnly: logged,
                decoration: const InputDecoration(labelText: "Nombre"),
                validator: (v) => v!.isEmpty ? "Obligatorio" : null,
              ),

              TextFormField(
                controller: apellidoController,
                readOnly: logged,
                decoration: const InputDecoration(labelText: "Apellido"),
                validator: (v) => v!.isEmpty ? "Obligatorio" : null,
              ),

              TextFormField(
                controller: correoController,
                readOnly: logged,
                decoration: const InputDecoration(labelText: "Correo"),
                validator: (v) => v!.isEmpty ? "Obligatorio" : null,
              ),

              TextFormField(
                controller: telefonoController,
                readOnly: logged,
                decoration: const InputDecoration(labelText: "Teléfono"),
                validator: (v) => v!.isEmpty ? "Obligatorio" : null,
              ),

              const SizedBox(height: 20),
              const Text(
                "Dirección de entrega",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),

              TextFormField(
                controller: direccionController,
                decoration: const InputDecoration(
                  labelText: "Dirección completa",
                ),
                validator: (v) => v!.isEmpty ? "Obligatorio" : null,
              ),

              const SizedBox(height: 30),

              const Text(
                "Resumen del pedido",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),

              ...widget.cartItems.map((item) {
                return ListTile(
                  title: Text(item["nombre"]),
                  subtitle: Text("Cantidad: ${item['cantidad']}"),
                  trailing: Text("\$${item['precio']}"),
                );
              }),

              const Divider(),
              Text(
                "Total a pagar: \$${widget.total}",
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 30),

              ElevatedButton(
                onPressed: (!isFormValid || loading)
                    ? null
                    : () {
                        if (_formKey.currentState!.validate()) {
                          _initPayment();
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF248FAA),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  disabledBackgroundColor: Colors.grey,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        "PAGAR AHORA",
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
