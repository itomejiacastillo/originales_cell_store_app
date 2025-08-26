import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/venta.dart';

class VentaCard extends StatelessWidget {
  final Venta venta;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onTap;

  final NumberFormat _currencyFormat = NumberFormat("#,##0.00", "en_US");

  VentaCard({
    super.key,
    required this.venta,
    this.onEdit,
    this.onDelete,
    this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    final totalFormateado = _currencyFormat.format(venta.total.toDouble());

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        onTap: onTap,
        title: Text(
          venta.nombre,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          "IMEI: ${venta.imei}\nTotal: L. $totalFormateado\nFecha: ${DateFormat('dd/MM/yyyy HH:mm').format(venta.fecha)}",
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (onEdit != null)
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: onEdit,
              ),
            if (onDelete != null)
              IconButton(
                icon: const Icon(Icons.delete),
                onPressed: onDelete,
              ),
          ],
        ),
      ),
    );
  }
}
