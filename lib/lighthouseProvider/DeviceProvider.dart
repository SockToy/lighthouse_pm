import './LighthouseDevice.dart';
import 'backEnd/LowLevelDevice.dart';

///
/// An abstract super class of what all device provider should be able to do.
///
abstract class DeviceProvider<D extends LowLevelDevice> {
  ///
  /// A simple check to see if the name matches with what the device provider
  /// expects. If the name doesn't matter for the device provider just always
  /// return true.
  bool nameCheck(String name);

  ///
  /// Connect to a device and return a super class of [LighthouseDevice].
  ///
  /// [device] the specific device to connect to and test.
  /// [updateInterval] The update time for the underlying devices.
  ///
  /// Can return `null` if the device is not support by this [DeviceProvider].
  Future<LighthouseDevice?> getDevice(D device, {Duration? updateInterval});

  ///
  /// Close any open connections that may have been made for discovering devices.
  /// If no open connection have been made this can just return.
  ///
  Future disconnectRunningDiscoveries();

  @override
  bool operator ==(Object other) {
    return this.runtimeType == other.runtimeType;
  }

  @override
  int get hashCode => super.hashCode;
}
