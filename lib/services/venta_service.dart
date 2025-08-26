import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/venta.dart';

class VentaService {
  final CollectionReference _ventasRef =
      FirebaseFirestore.instance.collection('ventas');

  Stream<List<Venta>> getVentas() {
    return _ventasRef
        .orderBy('fecha', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;

        return Venta(
          id: doc.id,
          nombre: data['nombre'] ?? '',
          imei: data['imei'] ?? '',
          total: data['total'] is num ? (data['total'] as num).toInt() : 0,
          fecha: (data['fecha'] as Timestamp).toDate(),
        );
      }).toList();
    });
  }

  Future<void> guardarVentas(List<Venta> ventas) async {
    final batch = FirebaseFirestore.instance.batch();

    for (var venta in ventas) {
      final docRef = _ventasRef.doc();
      final ventaData = venta.toMap();
      ventaData['fecha'] = Timestamp.fromDate(venta.fecha);

      batch.set(docRef, ventaData);
    }

    await batch.commit();
  }

  Future<void> eliminarVenta(String id) async {
    await _ventasRef.doc(id).delete();
  }

  Future<List<Venta>> buscarVentas({
    DateTime? fechaInicio,
    DateTime? fechaFin,
    String? imei,
  }) async {
    Query query = _ventasRef;

    if (fechaInicio != null) {
      query = query.where('fecha',
          isGreaterThanOrEqualTo: Timestamp.fromDate(fechaInicio));
    }

    if (fechaFin != null) {
      query = query.where('fecha',
          isLessThanOrEqualTo: Timestamp.fromDate(fechaFin));
    }

    if (imei != null && imei.isNotEmpty) {
      query = query.where('imei', isEqualTo: imei);
    }

    final snapshot = await query.get();
    return snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;

      return Venta(
        id: doc.id,
        nombre: data['nombre'] ?? '',
        imei: data['imei'] ?? '',
        total: data['total'] is num ? (data['total'] as num).toInt() : 0,
        fecha: (data['fecha'] as Timestamp).toDate(),
      );
    }).toList();
  }
}
