import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lighthouse_pm/bloc.dart';
import 'package:lighthouse_pm/pages/database/GroupDaoPage.dart';
import 'package:toast/toast.dart';

import 'BasePage.dart';
import 'database/NicknameDaoPage.dart';
import 'database/SettingsDaoPage.dart';
import 'database/ViveBaseStationDaoPage.dart';

class DatabaseTestPage extends BasePage with WithBlocStateless {
  DatabaseTestPage({Key? key}) : super(key: key, replace: true);

  @override
  Widget buildPage(BuildContext context) {
    final theme = Theme.of(context);

    final bloc = blocWithoutListen(context);

    final items = <Widget>[
      ListTile(
        leading: Icon(
          Icons.warning,
          color: Colors.orange,
          size: 30,
        ),
        title: Text(
          'WARNING!',
          style: theme.textTheme.headline4?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.textTheme.bodyText1!.color),
        ),
        subtitle: Text(
            'This is a page meant for development, changing values here may cause the app to become unstable and crash!'),
        isThreeLine: true,
      ),
      Divider(
        thickness: 3,
      ),
      ListTile(
        title: Text('Schema version'),
        subtitle: Text('Version: ${bloc.db.schemaVersion}'),
      ),
      Divider(),
      ListTile(
        title: Text('Known tables'),
        subtitle: Text(_getTables(bloc)),
        onLongPress: () async {
          await Clipboard.setData(ClipboardData(text: _getTables(bloc)));
          Toast.show('Copied to clipboard', context,
              duration: Toast.lengthShort, gravity: Toast.bottom);
        },
        isThreeLine: true,
      ),
      Divider(),
      FutureBuilder<String>(
          future: _getInstalledTables(bloc),
          builder: (context, snapshot) {
            final data = snapshot.data;
            if (snapshot.hasError) {
              final error = snapshot.error;
              return ListTile(
                title: Text('Error!'),
                subtitle: Text(error.toString()),
              );
            } else if (data != null) {
              final knownTables = _getTables(bloc).split('\n');
              final installedTables = data.split('\n');
              // Check if the lists are equal, if they are not show a warning.
              if (listEquals(knownTables, installedTables)) {
                return ListTile(
                  title: Text('Installed tables'),
                  subtitle: Text(data),
                  onLongPress: () async {
                    await Clipboard.setData(ClipboardData(text: data));
                    Toast.show('Copied to clipboard', context,
                        duration: Toast.lengthShort, gravity: Toast.bottom);
                  },
                );
              } else {
                return Column(
                  children: [
                    ListTile(
                      title: Text('Installed tables'),
                      subtitle: Text(data),
                      onLongPress: () async {
                        await Clipboard.setData(ClipboardData(text: data));
                        Toast.show('Copied to clipboard', context,
                            duration: Toast.lengthShort, gravity: Toast.bottom);
                      },
                    ),
                    Divider(),
                    ListTile(
                      title: Text(
                          'WARNING installed tables do not match known tables!'
                          '\nYou should create a migration!',
                          style: theme.textTheme.headline5?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.textTheme.bodyText1!.color)),
                      leading: Icon(
                        Icons.warning,
                        color: Colors.orange,
                        size: 30,
                      ),
                    ),
                  ],
                );
              }
            } else {
              return CircularProgressIndicator();
            }
          }),
      Divider(),
      ListTile(
        title: Text('Daos',
            style: theme.textTheme.headline6!
                .copyWith(fontWeight: FontWeight.bold)),
      ),
      Divider(thickness: 1.5),
    ];

    for (final dao in _DaoContainer._KNOWN_DAOS) {
      items.addAll(<Widget>[
        ListTile(
          title: Text(dao.daoName),
          subtitle:
              dao.daoDescription != null ? Text(dao.daoDescription!) : null,
          trailing: Icon(Icons.arrow_forward_ios),
          onTap: () async {
            Navigator.pushNamed(context, '/databaseTest${dao.pageLink}');
          },
        ),
        Divider(),
      ]);
    }

    return Scaffold(
        appBar: AppBar(
          title: Text('Database test page'),
        ),
        body: ListView(
          children: [
            Column(
              children: items,
            )
          ],
        ));
  }

  String _getTables(LighthousePMBloc bloc) {
    final tableList = bloc.getKnownTables();
    var tables = '';
    for (final table in tableList) {
      tables += '$table\n';
    }

    return tables.trim();
  }

  Future<String> _getInstalledTables(LighthousePMBloc bloc) async {
    return bloc.getInstalledTables().then((tableList) {
      var tables = '';
      for (final table in tableList) {
        tables += '$table\n';
      }

      return tables.trim();
    });
  }

  static Map<String, PageBuilder> _subPages = {
    '/nicknameDao': (context) => NicknameDaoPage(),
    '/settingsDao': (context) => SettingsDaoPage(),
    '/viveBaseStationDao': (context) => ViveBaseStationDaoPage(),
    '/groupDao': (context) => GroupDaoPage(),
  };

  static Map<String, PageBuilder> getSubPages(String parentPath) {
    Map<String, PageBuilder> subPages = {};

    for (final subPage in _subPages.entries) {
      subPages['$parentPath${subPage.key}'] = subPage.value;
    }

    return subPages;
  }
}

class _DaoContainer {
  final String daoName;
  final String? daoDescription;
  final String pageLink;

  const _DaoContainer(this.daoName, this.pageLink, {this.daoDescription});

  static const List<_DaoContainer> _KNOWN_DAOS = [
    _DaoContainer('NicknameDao', '/nicknameDao',
        daoDescription:
            'A dao that handles storage of nicknames and last seen'),
    _DaoContainer('SettingsDao', '/settingsDao',
        daoDescription: 'A dao that handles storage of settings'),
    _DaoContainer('ViveBaseStationDao', '/viveBaseStationDao',
        daoDescription: 'A dao that handles storage of vive base station ids'),
    _DaoContainer('GroupDao', '/groupDao',
        daoDescription:
            'A dao that handles the storage and linking of groups to lighthouses')
  ];
}
