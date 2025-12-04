import 'package:flutter/material.dart';
import 'package:shop_app/models/usuario_model.dart';
import 'package:shop_app/screens/catalogs_admin_screen.dart';
import 'package:shop_app/screens/home_screen.dart';
import 'package:shop_app/screens/product_admin_screen.dart';
import 'package:shop_app/screens/sales_admin_screen.dart';
import 'package:shop_app/screens/search_screen.dart';
import 'package:shop_app/screens/cart_screen.dart';
import 'package:shop_app/screens/perfil_screen.dart';
import 'package:shop_app/screens/login_screen.dart';

class MainLayout extends StatelessWidget {
  final Widget child;
  final int currentIndex;
  final Usuario? usuario;
  final Widget? header;

  const MainLayout({
    super.key,
    required this.child,
    required this.currentIndex,
    this.usuario,
    this.header,
  });

  void _navigate(BuildContext context, int index) {
    // ✅ Valor inicial seguro según si es Admin o Cliente
    Widget destination = const HomeScreen();

    if (usuario?.idRol == 1) {
      switch (index) {
        case 0:
          destination = ProductAdminScreen(usuario: usuario);
          break;
        case 1:
          destination = CatalogsAdminScreen(usuario: usuario);
          break;
        case 2:
          destination = SalesAdminScreen(usuario: usuario);
        case 3:
          destination = PerfilScreen(usuario: usuario);
          break;
      }
    } else {
      // 👤 Cliente / Invitado
      switch (index) {
        case 0:
          destination = const HomeScreen();
          break;
        case 1:
          destination = const SearchScreen();
          break;
        case 2:
          destination = const CartScreen();
          break;
        case 3:
          destination = (usuario == null || usuario!.idUsuario == 0)
              ? const LoginScreen()
              : const PerfilScreen();
          break;
      }
    }

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => destination,
        transitionDuration: Duration.zero,
      ),
    );
  }

  // ✅ Ahora la función está dentro de la clase y puede usar `usuario`
  List<BottomNavigationBarItem> _buildNavItems() {
    if (usuario?.idRol == 1) {
      return const [
        BottomNavigationBarItem(
          icon: Icon(Icons.inventory_2_outlined),
          label: 'Productos',
        ),
         BottomNavigationBarItem(
          icon: Icon(Icons.grid_view),
          label: 'Catálgos',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.attach_money_outlined),
          label: 'Ventas',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          label: 'Perfil',
        ),
      ];
    }

    return [
      BottomNavigationBarItem(
        icon: ClipRRect(
          borderRadius: BorderRadius.circular(50),
          child: Image.asset(
            'assets/images/logo.jpg',
            height: 28,
            width: 28,
            fit: BoxFit.cover,
          ),
        ),
        label: 'Inicio',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.search_outlined),
        label: 'Buscar',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.shopping_cart_outlined),
        label: 'Carrito',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.person_outline),
        label: 'Perfil',
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          if (header != null) header!,
          Expanded(child: child),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (index) => _navigate(context, index),
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: _buildNavItems(),
      ),
    );
  }
}
