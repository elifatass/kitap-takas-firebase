import 'package:flutter/material.dart';
import 'login_screen.dart'; // Giriş ekranını import et
import 'register_screen.dart'; // Kayıt ekranını import et

class LoginOrRegisterPage extends StatefulWidget {
  const LoginOrRegisterPage({super.key});

  @override
  State<LoginOrRegisterPage> createState() => _LoginOrRegisterPageState();
}

class _LoginOrRegisterPageState extends State<LoginOrRegisterPage> {
  // Başlangıçta giriş sayfasını gösterip göstermeyeceğimizi tutan değişken
  bool showLoginPage = true;

  // Gösterilen sayfayı değiştiren (toggle) fonksiyon
  void togglePages() {
    setState(() {
      showLoginPage =
          !showLoginPage; // Değeri tersine çevir (true ise false, false ise true yap)
    });
  }

  @override
  Widget build(BuildContext context) {
    // Eğer showLoginPage true ise LoginScreen'i göster, değilse RegisterScreen'i göster.
    // Her iki ekrana da togglePages fonksiyonunu parametre olarak gönderiyoruz ki
    // o ekranlardaki butonlar bu fonksiyonu çağırıp sayfa değişimini tetikleyebilsin.
    if (showLoginPage) {
      return LoginScreen(onTap: togglePages); // onTap callback'ini ekleyeceğiz
    } else {
      return RegisterScreen(
        onTap: togglePages,
      ); // onTap callback'ini ekleyeceğiz
    }
  }
}
