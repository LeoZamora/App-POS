import 'package:flutter/material.dart';
import 'package:inversiones_ar/login/loginApp.dart';
import 'package:inversiones_ar/screens/screenRegistroVentas.dart';
import 'package:inversiones_ar/screens/screenVentas.dart';
import 'package:inversiones_ar/widgets/floatingButton.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';

class DrawerItem {
  final String title;
  final IconData icon;

  DrawerItem({required this.title, required this.icon});
}

class InicioScreen extends StatefulWidget {
  const InicioScreen({super.key});

  @override
  State<InicioScreen> createState() => _InicioScreenState();
}

class _InicioScreenState extends State<InicioScreen> {
  int _selectedIndex = 0;
  List<Map<dynamic, dynamic>> menuCards = [{
    "title": 'Ventas',
    "icon": Icons.shopping_cart_outlined,
    "widget": VentasScreen()
  }, {
    "title": 'Registro de Ventas',
    "icon": Icons.drive_file_rename_outline_outlined,
    "widget": RegistroVentas()
  }];
  late List<DrawerItem> drawerItems;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final itemsViewList = [
      DrawerItem(title: "Inicio", icon: Icons.home_outlined),
      DrawerItem(title: "Ventas", icon: Icons.shopping_cart_outlined),
      DrawerItem(title: "Registro de Ventas", icon: Icons.drive_file_rename_outline_outlined),
    ];

    void _onSelected(int index) {
      setState(() {
        _selectedIndex = index;
      });
      //   LOGICA PARA MANEJAR EL MENU
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        title: const Text('Inversiones Zafiro'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.builder(
          itemCount: menuCards.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, // 2 columnas
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 1,
          ),
          itemBuilder: (context, index) {
            final item = menuCards[index];
            return GestureDetector(
              onTap: () {
                if (item.containsKey("widget") && item["widget"] != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => item["widget"]),
                  );
                }
              },
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(2, 4)),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 32,
                      backgroundColor: item['color']?.withOpacity(0.1) ?? Colors.grey[200],
                      child: Icon(
                        item['icon'],
                        size: 30,
                        color: item['color'] ?? Colors.indigo,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      item['title'],
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      drawer: Drawer(
        backgroundColor: Colors.white,
        child: Column(
          children: <Widget>[
            UserAccountsDrawerHeader(
              accountName: Text(
                'Leonardo Zamora',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
              accountEmail: Text(
                'Administrador',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  textBaseline: TextBaseline.alphabetic,
                ),
              ),
              currentAccountPicture: const CircleAvatar(
                backgroundColor: Colors.indigo,
                // child: Text('L', style: TextStyle(color: Colors.white, fontSize: 40.0),),
                child: Icon(
                  Icons.person_outlined,
                  size: 50,
                  color: Colors.white,
                ),
              ),
              decoration: BoxDecoration(color: Colors.white),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  ...itemsViewList.asMap().entries.map((entry) {
                    final index = entry.key;
                    final item = entry.value;
                    return ListTile(
                      leading: Icon(item.icon, color: Colors.indigo),
                      title: Text(
                        item.title,
                        style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      dense: true,
                      selectedTileColor: Colors.indigo[50],
                      onTap: () {
                        _onSelected(index);
                      },
                    );
                  }).toList(),
                ],
              ),
            ),
            const Divider(), // Un separador visual
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.redAccent),
              title: const Text('Cerrar Sesión'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => LoginApp()),
                );
              },
            ),
          ],
        ),
      ),
      floatingActionButton: SpeedDial(
        icon: Icons.more_vert,
        activeIcon: Icons.close,
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        tooltip: 'Opciones',
        buttonSize: const Size(50, 50),
        spaceBetweenChildren: 12,
        visible: true,
        closeManually: false,
        curve: Curves.bounceIn,
        overlayColor: Colors.black,
        overlayOpacity: 0,
        elevation: 8.0,
        children: [
          SpeedDialChild(
            child: Icon(Icons.sync),
            label: 'Sincronizar Ventas',
            foregroundColor: Colors.white,
            backgroundColor: Colors.green,
            onTap: () => print('Imprimir'),
          ),
        ],
      )
    );
  }
}
