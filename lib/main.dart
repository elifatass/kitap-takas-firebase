import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart'; // Firebase Core paketi
import 'firebase_options.dart'; // FlutterFire CLI tarafından oluşturulan yapılandırma
// import 'screens/register_screen.dart'; // Eski importu kaldırıyoruz
import 'services/auth_gate.dart'; // AuthGate widget'ını import ediyoruz

// main fonksiyonunu async yapıp Firebase'i başlatıyoruz
Future<void> main() async {
  // Flutter widget ağacının hazır olduğundan emin oluyoruz (Firebase öncesi gerekli)
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase'i platforma özel seçeneklerle başlatıyoruz
  // Bu işlem bitene kadar bekliyoruz (await)
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Firebase başlatıldıktan sonra uygulamayı çalıştırıyoruz
  runApp(const MyApp());
}

// --- MyApp Widget'ı ---

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // Uygulama adını değiştirebilirsin
      title: 'Kitap Takas Uygulaması',
      theme: ThemeData(
        // Uygulama teması
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
        ), // Ana rengi mavi yapalım
        useMaterial3: true, // Modern Material Design kullanımı
      ),
      // Uygulama açıldığında ilk gösterilecek widget olarak AuthGate'i belirliyoruz
      home: const AuthGate(), // RegisterScreen yerine AuthGate geldi
      debugShowCheckedModeBanner: false, // Sağ üstteki debug bannerını kaldırır
    );
  }
}

// --- VARSAYILAN MyHomePage ve _MyHomePageState WIDGET'LARI ---
// Bunlar hala burada duruyor, sorun değil.

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text('You have pushed the button this many times:'),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}
