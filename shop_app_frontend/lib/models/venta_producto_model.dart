class VentaProducto {
  final int idVenta;
  final int idProducto;
  final String talla;
  final int cantidad;
  final double precio;
  final double precioOferta;
  final String producto;
  final String descripcion;
  final String fullUrl;

  VentaProducto({
    required this.idVenta,
    required this.idProducto,
    required this.talla,
    required this.cantidad,
    required this.precio,
    required this.precioOferta,
    required this.producto,
    required this.descripcion,
    required this.fullUrl,
  });

  factory VentaProducto.fromJson(Map<String, dynamic> json) {
    return VentaProducto(
      idVenta: json['idVenta'],
      idProducto: json['idProducto'],
      talla: json['talla'],
      cantidad: json['cantidad'],
      precio: (json['precio'] as num).toDouble(),
      precioOferta: (json['precioOferta'] as num).toDouble(),
      producto: json['producto'],
      descripcion: json['descripcion'],
      fullUrl: json['fullUrl'],
    );
  }
}
