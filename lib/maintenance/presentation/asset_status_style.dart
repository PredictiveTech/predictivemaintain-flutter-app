import 'package:flutter/material.dart';

import '../domain/asset_status.dart';

Color assetStatusColor(AssetStatus status) => switch (status) {
      AssetStatus.operational => Colors.green.shade700,
      AssetStatus.inAlert => Colors.red.shade700,
      AssetStatus.noCommunication => Colors.grey.shade700,
    };

Color assetStatusBgColor(AssetStatus status) => switch (status) {
      AssetStatus.operational => Colors.green.shade50,
      AssetStatus.inAlert => Colors.red.shade50,
      AssetStatus.noCommunication => Colors.grey.shade200,
    };

String assetStatusLabel(AssetStatus status) => switch (status) {
      AssetStatus.operational => 'Operativo',
      AssetStatus.inAlert => 'Alerta',
      AssetStatus.noCommunication => 'Sin comunicación',
    };
