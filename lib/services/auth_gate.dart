import 'package:firebase_auth/firebase_auth.dart'; // FirebaseAuth User tipi için
import 'package:flutter/material.dart';
import 'package:kitap_takas_firebase/services/auth_service.dart'; // Oluşturduğumuz servis
import '../screens/login_or_register_page.dart'; // Giriş/Kayıt widget'ı
import '../screens/home_screen.dart'; // Ana Sayfa widget'ını import ediyoruz

class AuthGate extends StatelessWidget {
  const AuthGate({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // AuthService instance'ını al (Bu kısmı değiştirmedik)
    final AuthService _authService = AuthService();

    return Scaffold(
      body: StreamBuilder<User?>(
        stream: _authService.authStateChanges,
        builder: (context, snapshot) {
          // Bağlantı bekleniyor durumu (Aynı kaldı)
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // Kullanıcı giriş yapmış durumu
          if (snapshot.hasData) {
            // Eski geçici kodu kaldırıyoruz:
            // return Center(
            //   child: Column(
            //     mainAxisAlignment: MainAxisAlignment.center,
            //     children: [
            //       const Text("Giriş yapıldı! Ana Sayfa Buraya Gelecek."),
            //       const SizedBox(height: 20),
            //       ElevatedButton(
            //         onPressed: () async {
            //           await _authService.signOut();
            //           print("Çıkış yapıldı!");
            //         },
            //         child: const Text("Çıkış Yap"),
            //       )
            //     ],
            //   ),
            // );

            // YENİ HALİ: Doğrudan HomeScreen'i gösteriyoruz
            // HomeScreen'in constructor'ı const olmadığı için başına const koymuyoruz
            return HomeScreen();
          }

          // Kullanıcı giriş yapmamış durumu (Aynı kaldı)
          return const LoginOrRegisterPage();
        },
      ),
    );
  }
}
