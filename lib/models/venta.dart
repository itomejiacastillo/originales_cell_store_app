import 'package:cloud_firestore/cloud_firestore.dart';

class Venta {
  final String id;
  final String nombre;
  final String imei;
  final int total;
  final DateTime fecha;

  Venta({
    required this.id,
    required this.nombre,
    required this.imei,
    required this.total,
    required this.fecha,
  });

  Map<String, dynamic> toMap() {
    return {
      'nombre': nombre,
      'imei': imei,
      'total': total,
      'fecha': Timestamp.fromDate(fecha),
    };
  }

  factory Venta.fromMap(String id, Map<String, dynamic> map) {
    return Venta(
      id: id,
      nombre: map['nombre'] ?? '',
      imei: map['imei'] ?? '',
      total: map['total'] ?? 0, 
      fecha: (map['fecha'] as Timestamp).toDate(),
    );
  }
}
