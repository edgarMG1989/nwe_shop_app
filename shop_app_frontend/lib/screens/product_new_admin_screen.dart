import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // ✅ Para permitir solo números
import 'package:shop_app/components/main_layout.dart';
import 'package:shop_app/core/input_styles.dart';
import 'package:shop_app/data/data_provider_catalogo.dart';
import 'package:shop_app/data/data_provider_fileserver.dart';
import 'package:shop_app/data/data_provider_producto.dart';
import 'package:shop_app/data/data_provider_seguridad.dart';
import 'package:shop_app/models/usuario_model.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import 'package:shop_app/screens/product_admin_screen.dart';

class ProductNewAdminScreen extends StatefulWidget {
  final Usuario? usuario;
  const ProductNewAdminScreen({super.key, this.usuario});

  @override
  State<ProductNewAdminScreen> createState() => _ProductNewAdminScreenState();
}

class _ProductNewAdminScreenState extends State<ProductNewAdminScreen> {
  Usuario? usuario;
  XFile? _imagenSeleccionada;
  final ImagePicker _picker = ImagePicker();
  bool _subiendoImagen = false;
  int? _idDocumento;

  final _productoController = TextEditingController();
  final _descController = TextEditingController();
  final _precioController = TextEditingController();
  final _pOfertaController = TextEditingController();
  DateTime? _fechaInicioOferta;
  DateTime? _fechaFinOferta;

  bool _esNovedad = false;

  List<dynamic> tallas = [];
  List<dynamic> tallasSeleccionadas = [];
  List<dynamic> generos = [];
  List<dynamic> generosSeleccionadas = [];
  Map<int, TextEditingController> controllersCantidad = {};

  List<dynamic> tiposPrenda = [];
  dynamic tipoPrendaSeleccionado;

  @override
  void initState() {
    super.initState();
    _loadUsuario();
    _loadTallas();
    _loadGeneros();
    _loadTiposPrenda();

    _productoController.addListener(_refresh);
    _precioController.addListener(_refresh);
    _pOfertaController.addListener(_refresh);
  }

  void _refresh() {
    setState(() {});
  }

  Future<void> _loadUsuario() async {
    final user = await SeguridadService.getUsuario();
    setState(() => usuario = user);
  }

  Future<void> _loadTallas() async {
    final lista = await CatalogoService.getTallas();
    setState(() => tallas = lista);
  }

  Future<void> _loadGeneros() async {
    final lista = await CatalogoService.getGeneros();
    setState(() => generos = lista);
  }

  Future<void> _seleccionarImagen() async {
    final XFile? imagen = await _picker.pickImage(source: ImageSource.gallery);

    if (imagen != null) {
      setState(() {
        _imagenSeleccionada = imagen;
      });
    }
  }

  Future<void> _subirImagen() async {
    if (_imagenSeleccionada == null) return;

    setState(() => _subiendoImagen = true);

    final resp = await FileServerService.uploadImage(_imagenSeleccionada!, 'PRODUCTO');

    setState(() => _subiendoImagen = false);

    if (resp == null || resp["data"] == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("❌ Error al subir imagen")));
      return;
    }

    final data = resp["data"];

    final bodyDoc = {
      "filename": data["filename"],
      "originalName": data["originalName"],
      "path": data["path"],
      "url": data["url"],
      "fullUrl": data["fullUrl"],
      "localPath": data["localPath"],
      "size": data["size"],
    };

    final idDoc = await FileServerService.postInsDocumento(bodyDoc);

    if (idDoc != null) {
      _idDocumento = idDoc;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("✅ Imagen subida")));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("⚠ Error guardando documento")),
      );
    }
  }

  bool get _formValido {
    if (_productoController.text.isEmpty) return false;
    if (_precioController.text.isEmpty) return false;
    if (_idDocumento == null) return false;
    if (tallasSeleccionadas.isEmpty) return false;
    if (generosSeleccionadas.isEmpty) return false;
    if (tipoPrendaSeleccionado == null) return false;

    if (_pOfertaController.text.isNotEmpty &&
        double.tryParse(_pOfertaController.text)! > 0) {
      if (_fechaInicioOferta == null || _fechaFinOferta == null) return false;
    }

    for (var t in tallasSeleccionadas) {
      final id = t["id"];
      if (controllersCantidad[id]?.text.isEmpty ?? true) return false;
    }
    return true;
  }

  Future<void> _loadTiposPrenda() async {
    final lista = await CatalogoService.getTipoPrenda();
    setState(() => tiposPrenda = lista);
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      currentIndex: 0,
      usuario: usuario,
      header: AppBar(
        automaticallyImplyLeading: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "ALTA PRODUCTO",
          style: const TextStyle(color: Colors.black),
        ),
        centerTitle: true,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Column(
                children: [
                  GestureDetector(
                    onTap: _seleccionarImagen,
                    child: CircleAvatar(
                      radius: 65,
                      backgroundColor: Colors.grey.shade300,
                      backgroundImage: _imagenSeleccionada != null
                          ? FileImage(File(_imagenSeleccionada!.path))
                          : null,
                      child: _imagenSeleccionada == null
                          ? const Icon(
                              Icons.camera_alt,
                              size: 35,
                              color: Colors.black54,
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (_imagenSeleccionada != null)
                    ElevatedButton.icon(
                      icon: _subiendoImagen
                          ? const CircularProgressIndicator()
                          : const Icon(Icons.cloud_upload),
                      label: const Text("Subir imagen"),
                      onPressed: _subiendoImagen ? null : _subirImagen,
                    ),
                ],
              ),
            ),
            const SizedBox(height: 25),

            // 🛍 Nombre Producto
            TextFormField(
              controller: _productoController,
              decoration: InputStyles.textField("Producto", Icons.inventory),
            ),
            const SizedBox(height: 16),

            // 📘 Descripción
            TextFormField(
              controller: _descController,
              decoration: InputStyles.textField(
                "Descripción",
                Icons.description,
              ),
            ),
            const SizedBox(height: 16),

            DropdownButtonFormField(
              decoration: InputStyles.textField(
                "Selecciona tipo de prenda",
                Icons.checkroom,
              ),
              value: tipoPrendaSeleccionado,
              items: tiposPrenda.map((t) {
                return DropdownMenuItem(value: t, child: Text(t["prenda"]));
              }).toList(),
              onChanged: (value) {
                setState(() => tipoPrendaSeleccionado = value);
              },
            ),
            const SizedBox(height: 20),

            // 💲 Precio (solo números + $)
            TextFormField(
              controller: _precioController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
              decoration: InputStyles.textField(
                "Precio \$",
                Icons.attach_money,
              ),
            ),
            const SizedBox(height: 16),

            // 💸 Precio Oferta (solo números + $)
            TextFormField(
              controller: _pOfertaController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
              decoration: InputStyles.textField(
                "Precio oferta \$",
                Icons.money_off,
              ),
            ),
            const SizedBox(height: 20),
            if (_pOfertaController.text.isNotEmpty &&
                double.tryParse(_pOfertaController.text) != null &&
                double.tryParse(_pOfertaController.text)! > 0)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Fecha Inicio Oferta"),
                  const SizedBox(height: 5),
                  ElevatedButton(
                    child: Text(
                      _fechaInicioOferta == null
                          ? "Seleccionar fecha"
                          : _fechaInicioOferta!.toString().split(" ")[0],
                    ),
                    onPressed: () async {
                      final fecha = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100),
                      );
                      if (fecha != null) {
                        setState(() => _fechaInicioOferta = fecha);
                      }
                    },
                  ),
                  const SizedBox(height: 10),

                  const Text("Fecha Fin Oferta"),
                  const SizedBox(height: 5),
                  ElevatedButton(
                    child: Text(
                      _fechaFinOferta == null
                          ? "Seleccionar fecha"
                          : _fechaFinOferta!.toString().split(" ")[0],
                    ),
                    onPressed: () async {
                      final fecha = await showDatePicker(
                        context: context,
                        initialDate:
                            _fechaInicioOferta ??
                            DateTime.now(), // ✅ más lógico
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100),
                      );
                      if (fecha != null) {
                        setState(() => _fechaFinOferta = fecha);
                      }
                    },
                  ),
                  const SizedBox(height: 20),
                ],
              ),

            // ✅ Checkbox Novedad
            Row(
              children: [
                Checkbox(
                  value: _esNovedad,
                  onChanged: (v) => setState(() => _esNovedad = v!),
                ),
                const Text("¿Es novedad?", style: TextStyle(fontSize: 16)),
              ],
            ),
            const SizedBox(height: 20),

            const Text(
              "Tallas disponibles:",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            // 👕 Chips de tallas
            Wrap(
              spacing: 10,
              children: tallas.map((t) {
                final id = t["id"];
                final codigo = t["codigo"];
                final selected = tallasSeleccionadas.contains(t);

                return ChoiceChip(
                  label: Text(codigo),
                  selected: selected,
                  selectedColor: Colors.blue.shade300,
                  onSelected: (value) {
                    setState(() {
                      if (value) {
                        tallasSeleccionadas.add(t);
                        controllersCantidad[id] = TextEditingController();
                        controllersCantidad[id]!.addListener(_refresh);
                      } else {
                        tallasSeleccionadas.remove(t);
                        controllersCantidad.remove(id);
                      }
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            // 📦 Cantidades por talla seleccionada
            if (tallasSeleccionadas.isNotEmpty)
              Column(
                children: tallasSeleccionadas.map((t) {
                  final id = t["id"];
                  final codigo = t["codigo"];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: TextFormField(
                      controller: controllersCantidad[id],
                      keyboardType: TextInputType.number,
                      decoration: InputStyles.textField(
                        "Cantidad talla $codigo",
                        Icons.numbers,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d+$')),
                      ],
                    ),
                  );
                }).toList(),
              ),

            const SizedBox(height: 20),

            const Text(
              "Generos disponibles:",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            // 👕 Chips de generos
            Wrap(
              spacing: 10,
              children: generos.map((t) {
                final codigo = t["codigo"];
                final selected = generosSeleccionadas.contains(t);

                return ChoiceChip(
                  label: Text(codigo),
                  selected: selected,
                  selectedColor: Colors.blue.shade300,
                  onSelected: (value) {
                    setState(() {
                      if (value) {
                        generosSeleccionadas.add(t);
                      } else {
                        generosSeleccionadas.remove(t);
                      }
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF248FAA),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.save),
                label: const Text(
                  "Guardar Producto",
                  style: TextStyle(fontSize: 18),
                ),
                onPressed: _formValido ? _guardarProducto : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _guardarProducto() async {
    final precioOferta = double.tryParse(_pOfertaController.text) ?? 0.0;

    final body = {
      "nombre": _productoController.text,
      "descripcion": _descController.text,
      "precio": double.tryParse(_precioController.text) ?? 0,
      "precioOferta": precioOferta,
      "novedad": _esNovedad,
      "idDocumento": _idDocumento,
      "idTipoPrenda": tipoPrendaSeleccionado["id"],
      "fechaInicioOferta": precioOferta > 0
          ? _fechaInicioOferta?.toIso8601String()
          : null,
      "fechaFinOferta": precioOferta > 0
          ? _fechaFinOferta?.toIso8601String()
          : null,
      "inventarioJson": tallasSeleccionadas.map((t) {
        final id = t["id"];
        return {
          "idTalla": id,
          "cantidad": int.tryParse(controllersCantidad[id]!.text) ?? 0,
        };
      }).toList(),
      "generosJson": generosSeleccionadas.map((g) => g["id"]).toList(),
    };

    final result = await ProductoService.addProducto(body);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result['message']),
        backgroundColor: result['success'] == 1 ? Colors.green : Colors.red,
        duration: Duration(seconds: 2),
      ),
    );

    if (result['success'] == 1) {
      Future.delayed(Duration(seconds: 1), () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => ProductAdminScreen()),
        );
      });
    }
  }
}
