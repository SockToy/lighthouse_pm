import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lighthouse_pm/lighthouseProvider/LighthouseDevice.dart';
import 'package:lighthouse_pm/lighthouseProvider/LighthousePowerState.dart';
import 'package:lighthouse_pm/lighthouseProvider/deviceExtensions/StandbyExtension.dart';
import 'package:lighthouse_pm/lighthouseProvider/helpers/CustomLongPressGestureRecognizer.dart';
import 'package:package_info/package_info.dart';
import 'package:toast/toast.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vibration/vibration.dart';

const _GITHUB_ISSUE_URL =
    "https://github.com/jeroen1602/lighthouse_pm/issues/40";

/// An alert dialog to ask the user what to do since the state is unknown.
class UnknownStateAlertWidget extends StatelessWidget {
  UnknownStateAlertWidget(this.device, this.currentState, {Key? key})
      : super(key: key);

  final LighthouseDevice device;
  final int currentState;

  @override
  Widget build(BuildContext context) {
    final actions = <Widget>[
      SimpleDialogOption(
        child: Text("Cancel"),
        onPressed: () {
          Navigator.pop(context, null);
        },
      ),
      SimpleDialogOption(
        child: Text("Sleep"),
        onPressed: () {
          Navigator.pop(context, LighthousePowerState.SLEEP);
        },
      ),
      SimpleDialogOption(
        child: Text("On"),
        onPressed: () {
          Navigator.pop(context, LighthousePowerState.ON);
        },
      ),
    ];

    // Add standby, but only if it's supported
    if (device.hasStandbyExtension) {
      actions.insert(
          2,
          SimpleDialogOption(
            child: Text("Standby"),
            onPressed: () {
              Navigator.pop(context, LighthousePowerState.STANDBY);
            },
          ));
    }

    return AlertDialog(
        title: Text('Unknown state'),
        content: RichText(
          text: TextSpan(children: <InlineSpan>[
            TextSpan(
              style: Theme.of(context).textTheme.bodyText1,
              text:
                  'The state of this device is unknown. What do you want to do?\n',
            ),
            TextSpan(
              text: "Help out.",
              style: Theme.of(context).textTheme.bodyText1?.copyWith(
                  color: Colors.blue, decoration: TextDecoration.underline),
              recognizer: TapGestureRecognizer()
                ..onTap = () async {
                  await UnknownStateHelpOutAlertWidget.showCustomDialog(
                      context, device, currentState);
                },
            )
          ]),
        ),
        actions: actions);
  }

  static Future<LighthousePowerState?> showCustomDialog(
      BuildContext context, LighthouseDevice device, int currentState) {
    return showDialog(
        context: context,
        builder: (BuildContext context) {
          return UnknownStateAlertWidget(device, currentState);
        });
  }
}

/// A dialog to ask the user to help out with unknown states
class UnknownStateHelpOutAlertWidget extends StatelessWidget {
  UnknownStateHelpOutAlertWidget(this.device, this.currentState, {Key? key})
      : super(key: key);

  final LighthouseDevice device;
  final int currentState;

  String _getClipboardString(String version) {
    return 'App version: $version\n'
        'Device type: ${device.runtimeType}\n'
        'Firmware version: ${device.firmwareVersion}\n'
        'Current reported state: 0x${currentState.toRadixString(16).padLeft(2, '0')}\n';
  }

  GestureRecognizer createRecognizer(BuildContext context, String version) {
    return CustomLongPressGestureRecognizer()
      ..onLongPress = () async {
        Clipboard.setData(ClipboardData(text: _getClipboardString(version)));
        if (await Vibration.hasVibrator() == true) {
          Vibration.vibrate(duration: 200);
        }
        Toast.show('Copied to clipboard', context,
            duration: Toast.lengthShort, gravity: Toast.bottom);
      };
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Help out!'),
      content: FutureBuilder<PackageInfo>(
        future: PackageInfo.fromPlatform(),
        builder: (context, snapshot) {
          final version = snapshot.data;
          final recognizer = version != null
              ? createRecognizer(context, version.version)
              : null;
          return RichText(
              text: TextSpan(children: <InlineSpan>[
            TextSpan(
                style: Theme.of(context).textTheme.bodyText1,
                text:
                    'Help out by leaving a comment with the following information on the github issue.\n\n'),
            TextSpan(
              children: <InlineSpan>[
                TextSpan(
                  style: Theme.of(context).textTheme.bodyText2,
                  text: 'App version: ',
                  recognizer: recognizer,
                ),
                TextSpan(
                  style: Theme.of(context)
                      .textTheme
                      .bodyText2!
                      .copyWith(fontWeight: FontWeight.bold),
                  text: '${version?.version ?? "Loading"}\n',
                  recognizer: recognizer,
                ),
                TextSpan(
                  style: Theme.of(context).textTheme.bodyText2,
                  text: 'Device type: ',
                  recognizer: recognizer,
                ),
                TextSpan(
                  style: Theme.of(context)
                      .textTheme
                      .bodyText2!
                      .copyWith(fontWeight: FontWeight.bold),
                  text: '${device.runtimeType}\n',
                  recognizer: recognizer,
                ),
                TextSpan(
                  style: Theme.of(context).textTheme.bodyText2,
                  text: 'Firmware version: ',
                  recognizer: recognizer,
                ),
                TextSpan(
                  style: Theme.of(context)
                      .textTheme
                      .bodyText2!
                      .copyWith(fontWeight: FontWeight.bold),
                  text: '${device.firmwareVersion}\n',
                  recognizer: recognizer,
                ),
                TextSpan(
                  style: Theme.of(context).textTheme.bodyText2,
                  text: 'Current reported state: ',
                  recognizer: recognizer,
                ),
                TextSpan(
                  style: Theme.of(context)
                      .textTheme
                      .bodyText2!
                      .copyWith(fontWeight: FontWeight.bold),
                  text: '0x${currentState.toRadixString(16).padLeft(2, '0')}\n',
                  recognizer: recognizer,
                ),
              ],
            ),
          ]));
        },
      ),
      actions: <Widget>[
        SimpleDialogOption(
          child: Text("Open issue"),
          onPressed: () async {
            await launch(_GITHUB_ISSUE_URL);
          },
        ),
        SimpleDialogOption(
          child: Text("Cancel"),
          onPressed: () {
            Navigator.pop(context, null);
          },
        )
      ],
    );
  }

  static Future<void> showCustomDialog(
      BuildContext context, LighthouseDevice device, int currentState) {
    return showDialog(
        context: context,
        builder: (BuildContext context) {
          return UnknownStateHelpOutAlertWidget(device, currentState);
        });
  }
}
