import 'package:flutter/material.dart';
import 'package:lighthouse_pm/lighthouseProvider/widgets/LighthouseMetadataPage.dart';
import 'package:lighthouse_pm/lighthouseProvider/widgets/UnknownStateAlertWidget.dart';

import '../LighthouseDevice.dart';
import '../LighthousePowerState.dart';
import '../deviceExtensions/StandbyExtension.dart';

typedef LighthousePowerState _ToPowerState(int byte);

/// A widget for showing a [LighthouseDevice] in a list.
class LighthouseWidget extends StatelessWidget {
  LighthouseWidget(this.lighthouseDevice,
      {required this.onLongPress,
      required this.selected,
      this.nickname,
      this.sleepState = LighthousePowerState.SLEEP,
      Key? key})
      : super(key: key) {
    assert(
        sleepState == LighthousePowerState.SLEEP ||
            sleepState == LighthousePowerState.STANDBY,
        'The sleep state may not be ${sleepState.text.toUpperCase()}');

    this.lighthouseDevice.nickname = this.nickname;
  }

  final LighthouseDevice lighthouseDevice;
  final GestureLongPressCallback onLongPress;
  final bool selected;
  final String? nickname;
  final LighthousePowerState sleepState;

  Future _openMetadataPage(BuildContext context) async {
    return await Navigator.push(
        context,
        MaterialPageRoute(
            builder: (c) => LighthouseMetadataPage(lighthouseDevice)));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        color:
            selected ? Theme.of(context).selectedRowColor : Colors.transparent,
        child: InkWell(
            onLongPress: onLongPress,
            onTap: () => _openMetadataPage(context),
            child: IntrinsicHeight(
                child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                  Expanded(
                      child: Padding(
                          padding: const EdgeInsets.all(6.0),
                          child: Column(children: <Widget>[
                            Container(
                                alignment: Alignment.topLeft,
                                child: Row(
                                  children: <Widget>[
                                    Text(
                                        '${this.nickname ?? this.lighthouseDevice.name}',
                                        style: Theme.of(context)
                                            .textTheme
                                            .headline4)
                                  ],
                                )),
                            Container(
                                alignment: Alignment.topLeft,
                                child: Row(
                                  children: <Widget>[
                                    StreamBuilder<int>(
                                        stream:
                                            this.lighthouseDevice.powerState,
                                        initialData: 0xFF,
                                        builder: (c, snapshot) {
                                          final data = snapshot.data ?? 0xFF;
                                          return _LHItemPowerStateWidget(
                                            powerStateByte: data,
                                            toPowerState: lighthouseDevice
                                                .powerStateFromByte,
                                          );
                                        }),
                                    VerticalDivider(),
                                    Text(
                                        '${this.lighthouseDevice.deviceIdentifier}')
                                  ],
                                ))
                          ]))),
                  StreamBuilder<int>(
                      stream: this.lighthouseDevice.powerState,
                      initialData: 0xFF,
                      builder: (c, snapshot) {
                        final data = snapshot.data ?? 0xFF;
                        return _LHItemButtonWidget(
                          powerState: data,
                          toPowerState: lighthouseDevice.powerStateFromByte,
                          onPress: () async {
                            if (!await lighthouseDevice
                                .showExtraInfoWidget(context)) {
                              return;
                            }
                            final state =
                                lighthouseDevice.powerStateFromByte(data);
                            switch (state) {
                              case LighthousePowerState.BOOTING:
                                ScaffoldMessenger.maybeOf(context)
                                    ?.showSnackBar(SnackBar(
                                        content: Text(
                                            'Lighthouse is already booting!'),
                                        action: SnackBarAction(
                                          label: 'I\'m sure',
                                          onPressed: () async {
                                            if (lighthouseDevice
                                                .hasStandbyExtension) {
                                              await this
                                                  .lighthouseDevice
                                                  .changeState(this.sleepState);
                                            } else {
                                              debugPrint(
                                                  'The device doesn\'t support STANDBY so SLEEP will always be used.');
                                              await this
                                                  .lighthouseDevice
                                                  .changeState(
                                                      LighthousePowerState
                                                          .SLEEP);
                                            }
                                          },
                                        )));
                                break;
                              case LighthousePowerState.UNKNOWN:
                                switch (await UnknownStateAlertWidget
                                    .showCustomDialog(
                                        context, lighthouseDevice, data)) {
                                  case LighthousePowerState.STANDBY:
                                    await this.lighthouseDevice.changeState(
                                        LighthousePowerState.STANDBY);
                                    break;
                                  case LighthousePowerState.ON:
                                    continue powerOn;
                                  case LighthousePowerState.SLEEP:
                                    await this.lighthouseDevice.changeState(
                                        LighthousePowerState.SLEEP);
                                }
                                break;
                              case LighthousePowerState.ON:
                                if (lighthouseDevice.hasStandbyExtension) {
                                  await this
                                      .lighthouseDevice
                                      .changeState(this.sleepState);
                                } else {
                                  debugPrint(
                                      'The device doesn\'t support STANDBY so SLEEP will always be used.');
                                  await this
                                      .lighthouseDevice
                                      .changeState(LighthousePowerState.SLEEP);
                                }
                                break;
                              powerOn:
                              case LighthousePowerState.STANDBY:
                              case LighthousePowerState.SLEEP:
                                await this
                                    .lighthouseDevice
                                    .changeState(LighthousePowerState.ON);
                                break;
                            }
                          },
                          onLongPress: () => _openMetadataPage(context),
                        );
                      })
                ]))));
  }
}

/// Display the state of the device together with the state as a number in hex.
class _LHItemPowerStateWidget extends StatelessWidget {
  _LHItemPowerStateWidget(
      {Key? key, required this.powerStateByte, required this.toPowerState})
      : super(key: key);

  final int powerStateByte;
  final _ToPowerState toPowerState;

  @override
  Widget build(BuildContext context) {
    final state = toPowerState(powerStateByte);
    final hexString = powerStateByte.toRadixString(16);
    return Text(
        '${state.text} (0x${hexString.padLeft(hexString.length + (hexString.length % 2), '0')})');
  }
}

/// Add the toggle button for the power state of the device.
class _LHItemButtonWidget extends StatelessWidget {
  _LHItemButtonWidget({
    Key? key,
    required this.powerState,
    required this.onPress,
    required this.onLongPress,
    required this.toPowerState,
  }) : super(key: key);
  final int powerState;
  final VoidCallback onPress;
  final VoidCallback onLongPress;
  final _ToPowerState toPowerState;

  @override
  Widget build(BuildContext context) {
    final state = toPowerState(powerState);
    var color = Colors.grey;
    switch (state) {
      case LighthousePowerState.ON:
        color = Colors.green;
        break;
      case LighthousePowerState.SLEEP:
        color = Colors.blue;
        break;
      case LighthousePowerState.STANDBY:
        color = Colors.orange;
        break;
      case LighthousePowerState.BOOTING:
        color = Colors.yellow;
        break;
    }
    return Padding(
      padding: const EdgeInsets.all(6.0),
      child: RawMaterialButton(
          onPressed: () => onPress.call(),
          onLongPress: () => onLongPress.call(),
          elevation: 2.0,
          fillColor: Theme.of(context).buttonColor,
          padding: const EdgeInsets.all(2.0),
          shape: CircleBorder(),
          child: Icon(
            Icons.power_settings_new,
            color: color,
            size: 24.0,
          )),
    );
  }
}
