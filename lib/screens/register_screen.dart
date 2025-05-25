import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // UserCredential için
import 'package:kitap_takas_firebase/services/auth_service.dart'; // AuthService'i import et

class RegisterScreen extends StatefulWidget {
  final void Function() onTap;
  const RegisterScreen({Key? key, required this.onTap}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  final AuthService _authService = AuthService(); // AuthService instance'ı

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

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

      // DÜZELTİLMİŞ ÇAĞRI: Parametreler pozisyonel olarak gönderiliyor
      UserCredential? userCredential = await _authService
          .createUserWithEmailAndPassword(
            email, // Sadece email değişkeni
            password, // Sadece password değişkeni
          );

      if (userCredential != null && userCredential.user != null) {
        print(
          'RegisterScreen: Kayıt Başarılı (Auth ve muhtemelen Firestore). UID: ${userCredential.user?.uid}',
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Kayıt başarıyla tamamlandı! Giriş yapabilirsiniz.',
              ),
              backgroundColor: Colors.green,
            ),
          );
          widget.onTap(); // Giriş ekranına geç
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Kayıt sırasında bir sorun oluştu. Lütfen tekrar deneyin.',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
        print(
          'RegisterScreen: AuthService\'ten null UserCredential döndü veya user null.',
        );
      }
    } on FirebaseAuthException catch (e) {
      print(
        'RegisterScreen: Beklenmeyen FirebaseAuthException (AuthService\'ten sonra): ${e.code}',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Kayıt hatası: ${e.message ?? "Bilinmeyen bir Firebase hatası."}',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('RegisterScreen: _register içinde Beklenmedik Genel Hata: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Kayıt sırasında beklenmedik bir hata oluştu.'),
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
        automaticallyImplyLeading: false,
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
                    prefixIcon: Icon(Icons.email_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                    ),
                    filled: true,
                    fillColor: Color(0xFFF5F5F5),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty)
                      return 'Lütfen e-posta adresinizi girin';
                    if (!value.contains('@') || !value.contains('.'))
                      return 'Geçerli bir e-posta adresi girin';
                    return null;
                  },
                ),
                const SizedBox(height: 15),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Şifre',
                    prefixIcon: Icon(Icons.lock_outline),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                    ),
                    filled: true,
                    fillColor: Color(0xFFF5F5F5),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty)
                      return 'Lütfen bir şifre girin';
                    if (value.length < 6)
                      return 'Şifre en az 6 karakter olmalıdır';
                    return null;
                  },
                ),
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
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Zaten hesabın var mı?"),
                    TextButton(
                      onPressed: _isLoading ? null : widget.onTap,
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
