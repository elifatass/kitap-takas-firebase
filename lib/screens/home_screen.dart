import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:kitap_takas_firebase/services/auth_service.dart';

class HomeScreen extends StatelessWidget {
  // 'const' anahtar kelimesini constructor'dan kaldıralım, çünkü içinde final olmayan
  // _authService değişkeni var. Veya _authService'i dışarı alabiliriz.
  // Şimdilik const'u kaldıralım:
  HomeScreen({Key? key}) : super(key: key); // 'const' kaldırıldı

  // AuthService instance'ı (final yapalım)
  final AuthService _authService = AuthService();

  // Mevcut kullanıcıyı al (final yapalım)
  final User? _currentUser = FirebaseAuth.instance.currentUser;

  // ... build metodu ve geri kalanı aynı ...

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ana Sayfa'),
        actions: [
          // AppBar'ın sağına buton eklemek için actions kullanılır
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Çıkış Yap',
            onPressed: () async {
              // Çıkış yap butonuna basılınca
              print("AppBar Çıkış Yap butonuna basıldı.");
              await _authService.signOut();
              // AuthGate değişikliği algılayıp Login/Register'a yönlendirecek
            },
          ),
        ],
        // AuthGate'den geldiğimiz için geri butonu olmamalı
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Başarıyla Giriş Yaptınız!',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            // Giriş yapan kullanıcının emailini gösterelim (eğer varsa)
            Text(
              'Hoş Geldin, ${_currentUser?.email ?? 'Kullanıcı'}', // Null ise 'Kullanıcı' yaz
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 30),
            // Buraya kitap listesi, butonlar vb. eklenecek
            const Text(
              'Kitap Takas İçerikleri Buraya Gelecek...',
              style: TextStyle(fontSize: 18, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
