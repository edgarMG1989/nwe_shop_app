import 'package:shop_app/models/venta_producto_model.dart';

class Venta {
  final int idVenta;
  final int idUsuario;
  final String nombre;
  final String apellido;
  final String fechaCompra;
  final String estatus;
  final String direccion;
  final String telefono;
  final String correo;
  final double total;
  final int idEstatusVenta;
  List<VentaProducto> productos = [];

  Venta({
    required this.idVenta,
    required this.idUsuario,
    required this.nombre,
    required this.apellido,
    required this.fechaCompra,
    required this.estatus,
    required this.direccion,
    required this.telefono,
    required this.correo,
    required this.total,
    required this.idEstatusVenta,
    this.productos = const [],
  });

  factory Venta.fromJson(Map<String, dynamic> json) {
    return Venta(
      idVenta: json['idVenta'],
      idUsuario: json['idUsuarioCompra'],
      nombre: json['nombre'],
      apellido: json['apellido'],
      fechaCompra: json['fechaCompra'],
      estatus: json['estatus'],
      direccion: json['direccion'],
      telefono: json['telefono'],
      correo: json['correo'],
      idEstatusVenta: json['idEstatusVenta'],
      total: (json['total'] as num).toDouble(),
    );
  }
}
