import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

class ProductEditAdminScreen extends StatefulWidget {
  final int idProducto;

  const ProductEditAdminScreen({super.key, required this.idProducto});

  @override
  State<ProductEditAdminScreen> createState() => _ProductEditAdminScreenState();
}

class _ProductEditAdminScreenState extends State<ProductEditAdminScreen> {
  Usuario? usuario;
  XFile? _imagenNueva;
  String? _urlImagenActual;
  final ImagePicker _picker = ImagePicker();

  final _productoController = TextEditingController();
  final _descController = TextEditingController();
  final _precioController = TextEditingController();
  final _pOfertaController = TextEditingController();

  int? _idDocumento;
  bool _esNovedad = false;

  DateTime? _fechaInicioOferta;
  DateTime? _fechaFinOferta;

  List<dynamic> tallas = [];
  List<dynamic> tallasSeleccionadas = [];
  List<dynamic> generos = [];
  List<dynamic> generosSeleccionadas = [];
  Map<int, TextEditingController> controllersCantidad = {};

  bool cargando = true;
  List<dynamic> tiposPrenda = [];
  dynamic tipoPrendaSeleccionado;

  @override
  void initState() {
    super.initState();
    _productoController.addListener(() => setState(() {}));
    _precioController.addListener(() => setState(() {}));
    _pOfertaController.addListener(() => setState(() {}));
    _loadForm();
  }

  Future<void> _loadForm() async {
    await _loadUsuario();
    await _loadCatalogos();
    await _loadProductoBD();
    setState(() => cargando = false);
  }

  Future<void> _loadUsuario() async {
    usuario = await SeguridadService.getUsuario();
  }

  Future<void> _loadCatalogos() async {
    tallas = await CatalogoService.getTallas();
    generos = await CatalogoService.getGeneros();
    tiposPrenda = await CatalogoService.getTipoPrenda();
  }

  Future<void> _loadProductoBD() async {
    final resp = await ProductoService.selProductoId(widget.idProducto);

    if (resp["success"] == 1) {
      final p = resp["producto"];
      final inv = resp["inventario"];
      final gen = resp["generos"];

      _productoController.text = p["nombre"];
      _descController.text = p["descripcion"];
      _precioController.text = p["precio"].toString();
      _pOfertaController.text = p["precioOferta"]?.toString() ?? "";
      _esNovedad = p["novedad"];
      _idDocumento = p["idDocumento"];
      _urlImagenActual = p["fullUrl"];

      if (p["precioOferta"] != null) {
        _fechaInicioOferta = DateTime.parse(p["fechaInicioOferta"]);
        _fechaFinOferta = DateTime.parse(p["fechaFinOferta"]);
      }

      for (var item in inv) {
        final match = tallas.firstWhere((t) => t["id"] == item["idTalla"]);
        tallasSeleccionadas.add(match);
        controllersCantidad[item["idTalla"]] = TextEditingController(
          text: item["cantidad"].toString(),
        )..addListener(() => setState(() {}));
      }

      for (var g in gen) {
        final match = generos.firstWhere((x) => x["id"] == g["idGenero"]);
        generosSeleccionadas.add(match);
      }

      tipoPrendaSeleccionado = tiposPrenda.firstWhere(
        (t) => t["id"] == p["idTipoPrenda"],
        orElse: () => null,
      );
    }
  }

  Future<void> _seleccionarImagen() async {
    final XFile? imagen = await _picker.pickImage(source: ImageSource.gallery);
    if (imagen != null) {
      setState(() => _imagenNueva = imagen);
    }
  }

  Future<void> _subirImagen() async {
    if (_imagenNueva == null) return;

    setState(() => cargando = true);

    final resp = await FileServerService.uploadImage(_imagenNueva!,'PRODUCTO');

    setState(() => cargando = false);

    if (resp == null || resp["data"] == null) {
      _mensaje("❌ Error al subir imagen", false);
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
      setState(() {
        _idDocumento = idDoc;
        _urlImagenActual = data["fullUrl"];
      });
      _mensaje("✅ Imagen actualizada", true);
    } else {
      _mensaje("⚠ Error guardando documento", false);
    }
  }

  void _mensaje(String msg, bool ok) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: ok ? Colors.green : Colors.red,
      ),
    );
  }

  bool get _formValido {
    return _productoController.text.isNotEmpty &&
        _precioController.text.isNotEmpty &&
        _idDocumento != null &&
        tallasSeleccionadas.isNotEmpty &&
        generosSeleccionadas.isNotEmpty;
  }

  Future<void> _guardarCambios() async {
    final precioOferta = double.tryParse(_pOfertaController.text) ?? 0;
    final precio = double.tryParse(_precioController.text) ?? 0;

    if (precioOferta > 0 && precioOferta >= precio) {
      _mensaje("⚠ El precio de oferta debe ser menor al normal", false);
      return;
    }

    final body = {
      "idProducto": widget.idProducto,
      "nombre": _productoController.text,
      "descripcion": _descController.text,
      "precio": precio,
      "precioOferta": precioOferta,
      "novedad": _esNovedad,
      "idDocumento": _idDocumento,
      "idTipoPrenda": tipoPrendaSeleccionado["id"],
      "fechaInicioOferta": _fechaInicioOferta?.toIso8601String(),
      "fechaFinOferta": _fechaFinOferta?.toIso8601String(),
      "inventarioJson": tallasSeleccionadas.map((t) {
        final id = t["id"];
        return {
          "idTalla": id,
          "cantidad": int.tryParse(controllersCantidad[id]!.text) ?? 0,
        };
      }).toList(),
      "generosJson": generosSeleccionadas.map((g) => g["id"]).toList(),
    };

    final result = await ProductoService.updateProducto(body);
    _mensaje(result["message"], result["success"] == 1);

    if (result['success'] == 1) {
      Future.delayed(const Duration(milliseconds: 800), () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const ProductAdminScreen()),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (cargando) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return MainLayout(
      currentIndex: 0,
      usuario: usuario,
      header: AppBar(title: const Text("Editar Producto")),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            GestureDetector(
              onTap: _seleccionarImagen,
              child: CircleAvatar(
                radius: 65,
                backgroundImage: _imagenNueva != null
                    ? FileImage(File(_imagenNueva!.path))
                    : (_urlImagenActual != null
                              ? NetworkImage(_urlImagenActual!)
                              : null)
                          as ImageProvider?,
                child: _imagenNueva == null && _urlImagenActual == null
                    ? const Icon(Icons.camera_alt)
                    : null,
              ),
            ),

            if (_imagenNueva != null) ...[
              const SizedBox(height: 10),
              ElevatedButton.icon(
                icon: const Icon(Icons.cloud_upload),
                label: const Text("Subir imagen"),
                onPressed: _subirImagen,
              ),
            ],

            const SizedBox(height: 20),

            TextFormField(
              controller: _productoController,
              decoration: InputStyles.textField("Producto", Icons.inventory),
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _descController,
              decoration: InputStyles.textField(
                "Descripción",
                Icons.text_fields,
              ),
            ),
            const SizedBox(height: 12),
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
            const SizedBox(height: 16),

            if (double.tryParse(_pOfertaController.text) != null &&
                double.tryParse(_pOfertaController.text)! > 0)
              _buildFechaOfertas(),

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

            _buildTallas(),
            const SizedBox(height: 20),
            _buildGeneros(),

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
                  "Guardar Cambios",
                  style: TextStyle(fontSize: 18),
                ),
                onPressed: _formValido ? _guardarCambios : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFechaOfertas() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Fecha Inicio Oferta"),
        TextButton(
          onPressed: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: _fechaInicioOferta ?? DateTime.now(),
              firstDate: DateTime(2020),
              lastDate: DateTime(2100),
            );
            if (date != null) setState(() => _fechaInicioOferta = date);
          },
          child: Text(
            _fechaInicioOferta?.toString().split(" ").first ??
                "Seleccionar fecha",
          ),
        ),
        const SizedBox(height: 10),
        const Text("Fecha Fin Oferta"),
        TextButton(
          onPressed: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: _fechaFinOferta ?? DateTime.now(),
              firstDate: DateTime(2020),
              lastDate: DateTime(2100),
            );
            if (date != null) setState(() => _fechaFinOferta = date);
          },
          child: Text(
            _fechaFinOferta?.toString().split(" ").first ?? "Seleccionar fecha",
          ),
        ),
      ],
    );
  }

  Widget _buildTallas() {
    return Column(
      children: [
        const Text(
          "Tallas disponibles:",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          children: tallas.map((t) {
            final id = t["id"];
            final selected = tallasSeleccionadas.contains(t);

            return ChoiceChip(
              label: Text(t["codigo"]),
              selected: selected,
              selectedColor: Colors.blue.shade300,
              onSelected: (value) {
                setState(() {
                  if (value) {
                    tallasSeleccionadas.add(t);
                    controllersCantidad[id] ??= TextEditingController()
                      ..addListener(() => setState(() {}));
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
        if (tallasSeleccionadas.isNotEmpty)
          Column(
            children: tallasSeleccionadas.map((t) {
              final id = t["id"];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: TextFormField(
                  controller: controllersCantidad[id],
                  keyboardType: TextInputType.number,
                  decoration: InputStyles.textField(
                    "Cantidad talla ${t["codigo"]}",
                    Icons.numbers,
                  ),
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildGeneros() {
    return Column(
      children: [
        const Text(
          "Géneros disponibles:",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          children: generos.map((g) {
            final selected = generosSeleccionadas.contains(g);

            return ChoiceChip(
              label: Text(g["codigo"]),
              selected: selected,
              selectedColor: Colors.blue.shade300,
              onSelected: (value) {
                setState(() {
                  value
                      ? generosSeleccionadas.add(g)
                      : generosSeleccionadas.remove(g);
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }
}
