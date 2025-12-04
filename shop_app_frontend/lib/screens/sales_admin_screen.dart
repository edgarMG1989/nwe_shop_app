import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shop_app/components/main_layout.dart';
import 'package:shop_app/data/data_provider_venta.dart';
import 'package:shop_app/models/usuario_model.dart';
import 'package:shop_app/models/venta_model.dart';
import 'package:shop_app/models/venta_producto_model.dart';
import 'package:shop_app/screens/order_screen.dart';

class SalesAdminScreen extends StatefulWidget {
  final Usuario? usuario;

  const SalesAdminScreen({super.key, required this.usuario});

  @override
  State<SalesAdminScreen> createState() => _SalesAdminScreenState();
}

class _SalesAdminScreenState extends State<SalesAdminScreen> {
  Usuario? usuario;
  bool loading = true;

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  bool _isSearchExpanded = false;
  String _searchQuery = "";

  // filtros
  final List<Map<String, dynamic>> estatusOptions = [
    {"id": 1, "label": "Registrada"},
    {"id": 2, "label": "En preparación"},
    {"id": 3, "label": "Enviado"},
    {"id": 4, "label": "Entregado"},
    {"id": 5, "label": "Cancelado"},
  ];
  int? _selectedEstatus;
  DateTimeRange? _selectedRange;

  int _page = 1;
  final int _pageSize = 8;

  List<Venta> _allVentas = [];
  List<Venta> _filteredVentas = [];

  @override
  void initState() {
    super.initState();
    usuario = widget.usuario;
    _loadAllVentas();
  }

  Future<void> _loadAllVentas() async {
    setState(() => loading = true);

    try {
      final data = await VentaService.getVentas();

      final ventasRaw = data[0];
      final productosRaw = data[1];

      final ventas = ventasRaw
          .map<Venta>((v) => Venta.fromJson(v))
          .toList(growable: true);
      final productos = productosRaw
          .map<VentaProducto>((p) => VentaProducto.fromJson(p))
          .toList();

      for (final v in ventas) {
        v.productos = productos.where((p) => p.idVenta == v.idVenta).toList();
      }

      setState(() {
        _allVentas = ventas;
        _applyFilters();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error cargando ventas: $e")));
      }
    } finally {
      setState(() => loading = false);
    }
  }

  // formatea fecha string ISO -> legible
  String formatearFecha(String fecha) {
    try {
      final parsed = DateTime.parse(fecha);
      return DateFormat("dd MMM yyyy - hh:mm a").format(parsed);
    } catch (e) {
      return fecha;
    }
  }

  // aplica búsqueda y filtros sobre _allVentas (cliente)
  void _applyFilters() {
    final q = _searchQuery.trim().toLowerCase();
    final estatusId = _selectedEstatus;
    final range = _selectedRange;

    List<Venta> list = _allVentas
        .where((v) {
          // búsqueda por idVenta, nombre o apellido
          final matchId = v.idVenta.toString().contains(q);
          final matchNombre = v.nombre.toLowerCase().contains(q);
          final matchApellido = v.apellido.toLowerCase().contains(q);

          final matchesQuery = q.isEmpty
              ? true
              : (matchId || matchNombre || matchApellido);

          final matchesEstatus = estatusId == null
              ? true
              : (v.idEstatusVenta == estatusId);

          final matchesRange = range == null
              ? true
              : (() {
                  try {
                    final fecha = DateTime.parse(v.fechaCompra);
                    return !fecha.isBefore(range.start) &&
                        !fecha.isAfter(range.end.add(const Duration(days: 1)));
                  } catch (_) {
                    return true;
                  }
                })();

          return matchesQuery && matchesEstatus && matchesRange;
        })
        .toList(growable: true);

    setState(() {
      _filteredVentas = list;
      _page = 1;
    });
  }

  List<Venta> _pageItems() {
    final start = (_page - 1) * _pageSize;
    final end = (_page * _pageSize).clamp(0, _filteredVentas.length);
    if (start >= _filteredVentas.length) return [];
    return _filteredVentas.sublist(start, end);
  }

  int get _totalPages =>
      (_filteredVentas.length / _pageSize).ceil().clamp(1, 99999);

  Color _getStatusColor(int idEstatus) {
    switch (idEstatus) {
      case 1:
        return Colors.orange; // Registrada
      case 2:
        return Colors.blue; // En preparación
      case 3:
        return Colors.teal; // Enviado
      case 4:
        return Colors.green; // Entregado
      case 5:
        return Colors.red; // Cancelado
      default:
        return Colors.grey;
    }
  }

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _searchQuery = "";
      _selectedEstatus = null;
      _selectedRange = null;
      _applyFilters();
    });
  }

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final initial =
        _selectedRange ??
        DateTimeRange(start: now.subtract(const Duration(days: 30)), end: now);

    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDateRange: initial,
    );

    if (picked != null) {
      setState(() {
        _selectedRange = picked;
        _applyFilters();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return MainLayout(
      currentIndex: 2,
      usuario: usuario,
      header: Padding(
        padding: const EdgeInsets.only(
          top: 60,
          left: 16,
          right: 16,
          bottom: 10,
        ),
        child: Row(
          children: [
            if (!_isSearchExpanded)
              Expanded(
                child: Text(
                  "Ventas",
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: _isSearchExpanded
                    ? TextField(
                        key: const ValueKey("search"),
                        controller: _searchController,
                        focusNode: _searchFocusNode,
                        decoration: InputDecoration(
                          hintText: "Buscar por id, nombre o apellido",
                          prefixIcon: IconButton(
                            icon: const Icon(Icons.arrow_back),
                            onPressed: () {
                              setState(() => _isSearchExpanded = false);
                              _searchController.clear();
                            },
                          ),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() {
                                      _searchQuery = "";
                                      _applyFilters();
                                    });
                                  },
                                )
                              : null,
                          filled: true,
                          fillColor: Colors.grey[200],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        onChanged: (v) {
                          setState(() {
                            _searchQuery = v;
                            _applyFilters();
                          });
                        },
                      )
                    : Align(
                        alignment: Alignment.centerRight,
                        child: IconButton(
                          icon: const Icon(Icons.search),
                          onPressed: () =>
                              setState(() => _isSearchExpanded = true),
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),

      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int>(
                    value: _selectedEstatus,
                    decoration: InputDecoration(
                      labelText: "Estatus",
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    items: estatusOptions
                        .map<DropdownMenuItem<int>>(
                          (e) => DropdownMenuItem<int>(
                            value: e["id"] as int,
                            child: Text(e["label"] as String),
                          ),
                        )
                        .toList(),
                    onChanged: (v) {
                      setState(() {
                        _selectedEstatus = v;
                        _applyFilters();
                      });
                    },
                    isExpanded: true,
                    hint: const Text("Todos"),
                  ),
                ),

                const SizedBox(width: 10),

                ElevatedButton.icon(
                  icon: const Icon(Icons.date_range),
                  label: Text(
                    _selectedRange == null
                        ? "Fecha"
                        : "${DateFormat("dd/MM/yy").format(_selectedRange!.start)} - ${DateFormat("dd/MM/yy").format(_selectedRange!.end)}",
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 14,
                    ),
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black87,
                    elevation: 0,
                    side: BorderSide(color: Colors.grey.shade300),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _pickDateRange,
                ),

                const SizedBox(width: 8),

                IconButton(
                  tooltip: "Limpiar filtros",
                  onPressed: _clearFilters,
                  icon: Icon(Icons.clear, color: Colors.grey.shade700),
                ),
              ],
            ),

            const SizedBox(height: 8),

            Expanded(
              child: _filteredVentas.isEmpty
                  ? const Center(
                      child: Text(
                        "No tienes pedidos aún",
                        style: TextStyle(fontSize: 18),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.only(top: 6, bottom: 12),
                      itemCount: _pageItems().length,
                      itemBuilder: (context, i) {
                        final v = _pageItems()[i];

                        return InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => OrderScreen(venta: v,usuario: widget.usuario),
                              ),
                            );
                          },
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Column(
                                  children: v.productos.take(3).map((producto) {
                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 6),
                                      width: 52,
                                      height: 52,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: Colors.grey.shade200,
                                        ),
                                        image: DecorationImage(
                                          fit: BoxFit.cover,
                                          image: NetworkImage(producto.fullUrl),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),

                                const SizedBox(width: 14),

                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            "Pedido #${v.idVenta}",
                                            style: const TextStyle(
                                              fontSize: 17,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          Text(
                                            formatearFecha(v.fechaCompra),
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _getStatusColor(
                                            v.idEstatusVenta,
                                          ).withOpacity(0.12),
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                        child: Text(
                                          v.estatus,
                                          style: TextStyle(
                                            color: _getStatusColor(
                                              v.idEstatusVenta,
                                            ),
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        "${v.productos.length} productos",
                                        style: TextStyle(
                                          color: Colors.grey.shade700,
                                        ),
                                      ),
                                      Text(
                                        "Total: \$${v.total.toStringAsFixed(2)}",
                                        style: const TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(width: 12),
                                const Icon(
                                  Icons.arrow_forward_ios,
                                  size: 18,
                                  color: Colors.grey,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),

            if (_filteredVentas.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton(
                      onPressed: _page > 1
                          ? () => setState(() => _page--)
                          : null,
                      child: Text(
                        "Anterior",
                        style: TextStyle(
                          color: _page > 1 ? Colors.black : Colors.grey,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      "$_page / $_totalPages",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 12),
                    TextButton(
                      onPressed: _page < _totalPages
                          ? () => setState(() => _page++)
                          : null,
                      child: Text(
                        "Siguiente",
                        style: TextStyle(
                          color: _page < _totalPages
                              ? Colors.black
                              : Colors.grey,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
