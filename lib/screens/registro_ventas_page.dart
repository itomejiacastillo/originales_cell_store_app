import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:intl/intl.dart';
import '../models/venta.dart';
import '../services/venta_service.dart';
import '../widgets/venta_card.dart';

class RegistroVentasPage extends StatefulWidget {
  const RegistroVentasPage({super.key});

  @override
  State<RegistroVentasPage> createState() => _RegistroVentasPageState();
}

class _RegistroVentasPageState extends State<RegistroVentasPage> {
  final VentaService _ventaService = VentaService();
  final TextEditingController nombreController = TextEditingController();
  final TextEditingController totalController = TextEditingController();
  final TextEditingController imeiController = TextEditingController();
  final NumberFormat _currencyFormat = NumberFormat("#,##0.00", "es_HN");
  List<Venta> ventas = [];
  String? idEdicion;
  bool _guardando = false;

  @override
  void dispose() {
    nombreController.dispose();
    totalController.dispose();
    imeiController.dispose();
    super.dispose();
  }

  void _escanearCodigo() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.7,
          child: Column(
            children: [
              AppBar(
                title: const Text('Escanear Código'),
                leading: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              Expanded(
                child: MobileScanner(
                  controller: MobileScannerController(
                    facing: CameraFacing.back,
                    torchEnabled: false,
                  ),
                  onDetect: (capture) {
                    final List<Barcode> barcodes = capture.barcodes;
                    if (barcodes.isNotEmpty) {
                      setState(() {
                        imeiController.text = barcodes.first.rawValue ?? '';
                      });
                      Navigator.pop(context);
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _agregarALista() {
    if (nombreController.text.isEmpty || totalController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor completa los campos requeridos'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      final String totalLimpio =
          totalController.text.replaceAll('L. ', '').replaceAll(',', '').trim();

      final int totalEntero = int.tryParse(totalLimpio) ?? 0;

      final venta = Venta(
        id: idEdicion ?? DateTime.now().millisecondsSinceEpoch.toString(),
        nombre: nombreController.text,
        imei: imeiController.text,
        total: totalEntero,
        fecha: DateTime.now(),
      );

      print('📝 Agregando a lista: ${venta.toString()}');

      ventas.add(venta);
      _limpiarCampos();
    });
  }

  void _limpiarCampos() {
    nombreController.clear();
    totalController.clear();
    imeiController.clear();
    idEdicion = null;
  }

  void _editarVenta(int index) {
    final venta = ventas[index];
    setState(() {
      nombreController.text = venta.nombre;
      totalController.text =
          'L. ${_currencyFormat.format(venta.total.toDouble())}';
      imeiController.text = venta.imei;
      idEdicion = venta.id;
      ventas.removeAt(index);
    });
  }

  String formatNumber(String value) {
    if (value.isEmpty) return '';
    final number = int.tryParse(value.replaceAll(',', '')) ?? 0;
    final parts = number.toString().split('');
    String result = '';
    for (int i = parts.length - 1, count = 0; i >= 0; i--, count++) {
      if (count > 0 && count % 3 == 0) {
        result = ',' + result;
      }
      result = parts[i] + result;
    }
    return result;
  }

  Future<void> _guardarVentas() async {
    if (_guardando) return;

    try {
      setState(() {
        _guardando = true;
      });

      final ventasParaGuardar = List<Venta>.from(ventas);
      final cantidadVentas = ventasParaGuardar.length;

      print('🔄 Iniciando guardado de $cantidadVentas ventas...');

      setState(() {
        ventas = [];
        _limpiarCampos();
      });

      await _ventaService.guardarVentas(ventasParaGuardar);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 10),
                Text(cantidadVentas == 1
                    ? '¡1 venta guardada exitosamente!'
                    : '¡$cantidadVentas ventas guardadas exitosamente!'),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ),
        );
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) => AlertDialog(
            title: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 24),
                const SizedBox(width: 10),
                const Text('¡Guardado Exitoso!'),
              ],
            ),
            content: Text(cantidadVentas == 1
                ? 'Se ha guardado 1 venta correctamente.'
                : 'Se han guardado $cantidadVentas ventas correctamente y la lista ha sido limpiada.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.green,
                ),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      print('❌ Error al guardar ventas: $e');

      if (mounted) {
        // Restaurar las ventas al estado local si hay error
        setState(() {
          ventas = List<Venta>.from(ventas);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 10),
                Text(
                    'Error al guardar las ventas: ${e.toString().substring(0, 100)}...'),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _guardando = false;
        });
      }
    }
  }

  Widget _buildActionButtons() {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Si el ancho es menor a 400 pixels, usar columna
        if (constraints.maxWidth < 400) {
          return Column(
            children: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _escanearCodigo,
                  icon: const Icon(Icons.qr_code_scanner),
                  label: const Text('Escanear Código'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _agregarALista,
                  icon: const Icon(Icons.add),
                  label: Text(
                      idEdicion != null ? 'Actualizar' : 'Agregar a Lista'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          );
        } else {
          // Si hay suficiente espacio, usar fila
          return Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _escanearCodigo,
                  icon: const Icon(Icons.qr_code_scanner),
                  label: const Text('Escanear Código'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _agregarALista,
                  icon: const Icon(Icons.add),
                  label: Text(
                      idEdicion != null ? 'Actualizar' : 'Agregar a Lista'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ingreso de Productos')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Fecha y Hora: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: nombreController,
              decoration: const InputDecoration(
                labelText: 'Nombre del Artículo',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: totalController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                TextInputFormatter.withFunction((oldValue, newValue) {
                  final cleanText = newValue.text.replaceAll(',', '');
                  if (cleanText.isEmpty) return newValue;

                  final formatted = formatNumber(cleanText);
                  return TextEditingValue(
                    text: formatted,
                    selection:
                        TextSelection.collapsed(offset: formatted.length),
                  );
                }),
              ],
              decoration: const InputDecoration(
                labelText: 'Total',
                hintText: 'Ingrese el precio',
                prefixText: 'L. ',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: imeiController,
              maxLength: 15,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ],
              decoration: const InputDecoration(
                labelText: 'IMEI (Escaneado o Ingresado)',
                counterText: '15 dígitos máximo',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            _buildActionButtons(),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Lista de Ingreso',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  '${ventas.length} ${ventas.length == 1 ? 'artículo' : 'artículos'}',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),
            Container(
              height: MediaQuery.of(context).size.height *
                  0.3, // Altura fija responsive
              child: ventas.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.list_alt,
                              size: 48, color: Colors.grey[400]),
                          const SizedBox(height: 10),
                          Text(
                            'No hay productos en la lista',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: ventas.length,
                      itemBuilder: (context, index) {
                        return VentaCard(
                          venta: ventas[index],
                          onEdit: () => _editarVenta(index),
                          onDelete: () =>
                              setState(() => ventas.removeAt(index)),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed:
                    ventas.isNotEmpty && !_guardando ? _guardarVentas : null,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  backgroundColor: Colors.blue,
                ),
                child: _guardando
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.0,
                            ),
                          ),
                          SizedBox(width: 10),
                          Text('Guardando...', style: TextStyle(fontSize: 16)),
                        ],
                      )
                    : const Text(
                        'Guardar Producto',
                        style: TextStyle(fontSize: 16),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
