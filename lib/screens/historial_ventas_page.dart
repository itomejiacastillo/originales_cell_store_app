import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/venta.dart';
import '../services/venta_service.dart';
import '../widgets/venta_card.dart';

enum OrdenTipo { precioAsc, precioDesc, fechaReciente, fechaAntigua }

class HistorialVentasPage extends StatefulWidget {
  const HistorialVentasPage({super.key});

  @override
  State<HistorialVentasPage> createState() => _HistorialVentasPageState();
}

class _HistorialVentasPageState extends State<HistorialVentasPage> {
  final VentaService _ventaService = VentaService();

  OrdenTipo _ordenSeleccionado = OrdenTipo.fechaReciente;

  void _confirmarEliminacion(BuildContext context, Venta venta) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Eliminación'),
        content: Text(
            '¿Estas seguro de que deseas eliminar el producto "${venta.nombre}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await _ventaService.eliminarVenta(venta.id);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Venta eliminada exitosamente'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error al eliminar la venta: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  void _cambiarOrden(OrdenTipo tipo) {
    setState(() {
      _ordenSeleccionado = tipo;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventario'),
        actions: [
          PopupMenuButton<OrdenTipo>(
            icon: const Icon(Icons.filter_list),
            onSelected: _cambiarOrden,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: OrdenTipo.precioAsc,
                child: Text("Precio más bajo"),
              ),
              const PopupMenuItem(
                value: OrdenTipo.precioDesc,
                child: Text("Precio más alto"),
              ),
              const PopupMenuItem(
                value: OrdenTipo.fechaReciente,
                child: Text("Fecha más reciente"),
              ),
              const PopupMenuItem(
                value: OrdenTipo.fechaAntigua,
                child: Text("Fecha más antigua"),
              ),
            ],
          ),
        ],
      ),
      body: StreamBuilder<List<Venta>>(
        stream: _ventaService.getVentas(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          var ventas = snapshot.data;
          if (ventas == null || ventas.isEmpty) {
            return const Center(child: Text('No hay productos registrados'));
          }

          ventas.sort((a, b) {
            switch (_ordenSeleccionado) {
              case OrdenTipo.precioAsc: 
                return a.total.compareTo(b.total);
              case OrdenTipo.precioDesc: 
                return b.total.compareTo(a.total);
              case OrdenTipo.fechaReciente: 
                return b.fecha.compareTo(a.fecha);
              case OrdenTipo.fechaAntigua: 
                return a.fecha.compareTo(b.fecha);
            }
          });

          return ListView.builder(
            itemCount: ventas.length,
            itemBuilder: (context, index) {
              final venta = ventas[index];
              return VentaCard(
                venta: venta,
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Detalles del Producto'),
                      content: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text("Artículo: ${venta.nombre}"),
                            Text("IMEI: ${venta.imei}"),
                            Text(
                              "Total: L. ${NumberFormat("#,##0.00", "es_HN").format(venta.total)}",
                            ),
                            Text(
                              "Fecha: ${DateFormat('dd/MM/yyyy HH:mm').format(venta.fecha)}",
                            ),
                          ],
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cerrar'),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                            _confirmarEliminacion(context, venta);
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.red,
                          ),
                          child: const Text('Eliminar'),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
