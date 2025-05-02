import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Firebase Auth paketini import et

class RegisterScreen extends StatefulWidget {
  // onTap fonksiyonu artık required ve non-nullable
  final void Function() onTap;
  const RegisterScreen({Key? key, required this.onTap})
    : super(key: key); // Constructor'a onTap eklendi

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  // Form alanları için TextEditingController'lar
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  // final _confirmPasswordController = TextEditingController();

  // Formun durumunu yönetmek için GlobalKey
  final _formKey = GlobalKey<FormState>();

  // Kayıt işlemi yükleniyor mu?
  bool _isLoading = false;

  // FirebaseAuth instance
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    // _confirmPasswordController.dispose();
    super.dispose();
  }

  // Firebase kayıt fonksiyonu
  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      String email = _emailController.text.trim();
      String password = _passwordController.text.trim();

      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      print('Kayıt Başarılı: ${userCredential.user?.uid}');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Kayıt başarıyla tamamlandı! Giriş yapabilirsiniz.',
            ), // Mesaj güncellendi
            backgroundColor: Colors.green,
          ),
        );
        // Başarılı kayıttan sonra otomatik olarak giriş sayfasına geçiş yapalım
        widget.onTap(); // onTap fonksiyonunu çağırarak Login'e geçişi tetikle
      }
    } on FirebaseAuthException catch (e) {
      print('Kayıt Hatası Kodu: ${e.code}');
      print('Kayıt Hatası Mesajı: ${e.message}');

      String errorMessage = 'Bir hata oluştu, lütfen tekrar deneyin.';
      if (e.code == 'weak-password') {
        errorMessage = 'Girdiğiniz şifre çok zayıf.';
      } else if (e.code == 'email-already-in-use') {
        errorMessage =
            'Bu e-posta adresi zaten başka bir hesap tarafından kullanılıyor.';
      } else if (e.code == 'invalid-email') {
        errorMessage = 'Girdiğiniz e-posta adresi geçersiz.';
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      print('Beklenmedik Kayıt Hatası: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Beklenmedik bir hata oluştu: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kayıt Ol'),
        automaticallyImplyLeading: false, // Geri butonunu gösterme
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Yeni Hesap Oluştur',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'E-posta',
                    hintText: 'eposta@adresiniz.com',
                    prefixIcon: Icon(Icons.email_outlined), // Outlined ikon
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(
                        Radius.circular(12),
                      ), // Yuvarlak köşe
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF5F5F5),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Lütfen e-posta adresinizi girin';
                    }
                    if (!value.contains('@') || !value.contains('.')) {
                      return 'Geçerli bir e-posta adresi girin';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 15),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Şifre',
                    prefixIcon: Icon(Icons.lock_outline), // Outlined ikon
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(
                        Radius.circular(12),
                      ), // Yuvarlak köşe
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF5F5F5),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Lütfen bir şifre girin';
                    }
                    if (value.length < 6) {
                      return 'Şifre en az 6 karakter olmalıdır';
                    }
                    return null;
                  },
                ),
                // TODO: Şifre Tekrarı alanı eklenebilir
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: _isLoading ? null : _register,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                  ),
                  child:
                      _isLoading
                          ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              color: Colors.white,
                            ),
                          )
                          : const Text(
                            'Kayıt Ol',
                            style: TextStyle(fontSize: 16),
                          ),
                ),
                const SizedBox(height: 20),
                Row(
                  // Ortalamak için
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Zaten hesabın var mı?"),
                    TextButton(
                      // Yüklenirken tıklanmasın ve widget.onTap fonksiyonunu çağırsın
                      onPressed:
                          _isLoading ? null : widget.onTap, // DEĞİŞİKLİK BURADA
                      child: Text(
                        'Giriş Yap',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
