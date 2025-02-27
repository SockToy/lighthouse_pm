import 'package:flutter/widgets.dart';
import 'package:lighthouse_pm/permissionsHelper/BLEPermissionsHelper.dart';
import 'package:lighthouse_pm/widgets/CloseCurrentRouteMixin.dart';
import 'package:lighthouse_pm/widgets/ScanningMixin.dart';
import 'package:lighthouse_pm/widgets/WaterfallWidget.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionsStream extends WaterfallStreamWidget<PermissionStatus>
    with ScanningMixin, CloseCurrentRouteMixin {
  PermissionsStream(
      {Key? key,
      required List<Object?> upStream,
      List<DownStreamBuilder> downStreamBuilders = const []})
      : super(
            key: key,
            upStream: upStream,
            downStreamBuilders: downStreamBuilders);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PermissionStatus>(
        future: BLEPermissionsHelper.hasBLEPermissions(),
        builder: (context, AsyncSnapshot<PermissionStatus> permissionSnapshot) {
          final permissions = permissionSnapshot.data;
          if (permissions == null) {
            return Text('Loading...');
          }
          if (permissionSnapshot.data != PermissionStatus.granted) {
            WidgetsBinding.instance?.addPostFrameCallback((_) async {
              await closeCurrentRouteWithWait(context);
            });
            return Text('Permission has not been given!');
          }
          return buildScanPopScope(
              child: getNextStreamDown(context, permissions));
        });
  }

  static DownStreamBuilder createBuilder() {
    return (context, upStream, downStream) {
      return PermissionsStream(
        upStream: upStream,
        downStreamBuilders: downStream.cast<DownStreamBuilder>(),
      );
    };
  }
}
