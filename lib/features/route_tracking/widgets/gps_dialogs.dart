import 'package:flutter/material.dart';

class GpsDisabledDialog extends StatelessWidget {
  final VoidCallback onEnableSettings;
  final VoidCallback onCancel;

  const GpsDisabledDialog({
    super.key,
    required this.onEnableSettings,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.gps_off, color: Colors.orange, size: 24),
          const SizedBox(width: 12),
          const Text('GPS Desactivado'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Para usar Movi Rutas necesitas activar el GPS de tu dispositivo.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 12),
          Text(
            'El GPS es necesario para:',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ...[
                '• Registrar tu ubicación en tiempo real',
                '• Calcular distancias correctamente',
                '• Guardar puntos de la ruta',
              ]
              .map(
                (feature) => Padding(
                  padding: const EdgeInsets.only(left: 16, top: 4),
                  child: Text(
                    feature,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              )
              .toList(),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Colors.orange.shade700,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Una vez activado, regresar a la aplicación para continuar.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.orange.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: onCancel, child: const Text('Cancelar')),
        ElevatedButton.icon(
          onPressed: onEnableSettings,
          icon: const Icon(Icons.settings),
          label: const Text('Activar GPS'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
      ],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}

class LocationPermissionDialog extends StatelessWidget {
  final VoidCallback onOpenSettings;
  final VoidCallback onCancel;

  const LocationPermissionDialog({
    super.key,
    required this.onOpenSettings,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.location_off, color: Colors.red, size: 24),
          const SizedBox(width: 12),
          const Text('Permisos de Ubicación'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Movi Rutas necesita permisos de ubicación para funcionar correctamente.',
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 12),
          Text(
            'Permisos necesarios:',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ...[
                '• Acceder a tu ubicación GPS',
                '• Seguimiento en segundo plano',
                '• Guardar rutas en el dispositivo',
              ]
              .map(
                (permission) => Padding(
                  padding: const EdgeInsets.only(left: 16, top: 4),
                  child: Text(permission, style: const TextStyle(fontSize: 13)),
                ),
              )
              .toList(),
        ],
      ),
      actions: [
        TextButton(onPressed: onCancel, child: const Text('Ahora no')),
        ElevatedButton.icon(
          onPressed: onOpenSettings,
          icon: const Icon(Icons.lock_open),
          label: const Text('Conceder Permisos'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
      ],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}

Future<bool> showGpsDisabledDialog(BuildContext context) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) => GpsDisabledDialog(
      onEnableSettings: () {
        Navigator.of(context).pop(true);
      },
      onCancel: () {
        Navigator.of(context).pop(false);
      },
    ),
  );

  return result ?? false;
}

Future<bool> showLocationPermissionDialog(BuildContext context) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) => LocationPermissionDialog(
      onOpenSettings: () {
        Navigator.of(context).pop(true);
      },
      onCancel: () {
        Navigator.of(context).pop(false);
      },
    ),
  );

  return result ?? false;
}
