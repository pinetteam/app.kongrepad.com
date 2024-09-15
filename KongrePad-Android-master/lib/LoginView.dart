import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:http/http.dart' as http;
import 'package:kongrepad/AlertService.dart';
import 'package:kongrepad/MainPageView.dart';
import 'package:pusher_beams/pusher_beams.dart';

import 'AnnouncementsView.dart';
import 'AppConstants.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:shared_preferences/shared_preferences.dart';
//import 'package:kongrepad/services/pusher_service.dart';

import 'PusherService.dart';
//import 'functions/notification_helper.dart';

void main() async {

  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  PusherBeams beamsClient = PusherBeams.instance;

  await beamsClient.start('dc312300-76d4-4fa3-ad7f-f6fec48cbb56');  // Pusher Beams Instance ID'nizi buraya ekleyin
  await beamsClient.addDeviceInterest('debug-meeting_2');  // Cihazın abone olacağı "interest" ekleyin


  runApp(const MyApp());

}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: AppConstants.backgroundBlue,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home:  Scaffold(body: LoginView()),
    );
  }
}

class LoginView extends StatefulWidget {
  const LoginView({super.key});


  @override
  State<LoginView> createState() => _LoginViewState();
}
void _showPopup(BuildContext context) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        backgroundColor: AppConstants.backgroundBlue,
        title: Text("KİŞİLER VERİLERİN KORUNMASI AYDINLATMA METNİ ve TİCARİ ELEKTRONİK İLETİ MUVAFAKATNAMESİ "),
        content: const SingleChildScrollView(child: Text("A-    KİŞİLER VERİLERİN KORUNMASI AYDINLATMA METNİ 6698 sayılı Kişisel Verilerin Korunması Kanunu (“Kanun”) uyarınca, kişisel verileriniz; veri sorumlusu olarak D Event Turizm Organizasyon Hizmetleri Limited Şirketi (“D Event” veya “Şirket”) tarafından aşağıda açıklanan koşullar kapsamında işlenmektedir.1.Kişisel Verilerin İşlenme Amacı\nKişisel verileriniz, bilgi güvenliğini ve hukuki işlem güvenliğini sağlamamız ve faaliyetlerin mevzuata uygun yürütülmesini sağlamamamız başta olmak üzere, iletişim faaliyetlerinin yürütülmesi, verilerinizin doğruluğunun sağlanması, ürün/hizmetlerin pazarlama süreçlerinin yürütülmesi,ürün ve/veya hizmetlerimizin tanıtımı, sunulması ve satış süreçlerinin işletilmesi, sözleşmelerin müzakeresi, akdedilmesi ve ifası, mevcut ile yeni ürün ve hizmetlerdeki değişikliklerin, kampanyaların, promosyonların duyurulması, pazarlama ve satış faaliyetlerinin yürütülmesi, sosyal medya ve kurumsal iletişim süreçlerinin planlanması ve icra edilmesi, reklam/kampanya/promosyon süreçlerinin yürütülmesi, ihtiyaçlar, talepler ile yasal ve teknik gelişmeler doğrultusunda ürün ve hizmetlerimizin güncellenmesi, özelleştirilmesi, geliştirilmesi ve üyelik işlemlerinin gerçekleştirilmesi amaçlarıyla işlenecektir.2. Kişisel Verileri Toplama Yöntemleri ve Hukuki Sebepleri\nMobil uygulama/internet sitesi üzerinden toplanan kişisel veriler (kimlik ve iletişim bilgileri) ilgili kişinin mobil uygulama/internet sitesi içerisinde yer alan formları doldurması ile toplanmaktadır. Bu kişisel veriler Kanun’da belirtilen kişisel veri işleme şartlarına uygun olarak ve sizinle aramızdaki ilişkinin icrası ve faaliyetlerin mevzuata uygunluğunun temini amaçları başta olmak üzere, sizlere ait kişisel verilerin işlenmesinin gerekli olması, hukuki yükümlülüğümüzü yerine getirebilmek için zorunlu olması hukuki sebepleri doğrultusunda işlenmektedir. 3.İşlenen Kişisel Verilerin Aktarılması\n Şirketimiz, kişisel verilerinizi “bilme gereği” ve “kullanma gereği” ilkelerine uygun olarak, gerekli veri minimizasyonunu sağlayarak ve gerekli teknik ve idari güvenlik tedbirlerini alarak işlemeye özen göstermektedir. Şirketimiz, topladığı kişisel verileri faaliyetlerini yürütebilmek için iş birliği yaptığı kurum ve kuruluşlarla, verilerin bulut ortamında saklanması halinde yurt içindeki/yurt dışındaki kişi ve kurumlarla, ticari elektronik iletilerin gönderilmesi konusunda anlaşmalı olduğu yurt içindeki/yurt dışındaki kuruluşlarla, talep halinde kamu otoriteleriyle ve hizmetin verilmesiyle ilgili olarak iş ortakları ile paylaşabilmektedir. 4.Veri Sorumlusuna Başvuru Yolları ve Haklarınız\nŞirketimize başvurarak, kişisel verilerinizin işlenip işlenmediğini öğrenme, işlenmişse buna ilişkin bilgi talep etme, kişisel verilerinizin işlenme amacını ve bunların amacına uygun kullanılıp kullanılmadığını öğrenme, yurt içinde kişisel verilerinizin aktarıldığı üçüncü kişileri bilme, kişisel verilerinizin eksik veya yanlış işlenmiş olması halinde bunların düzeltilmesini isteme ve bu kapsamda yapılan işlemin kişisel verilerin aktarıldığı üçüncü kişilere bildirilmesini isteme, kanunda öngörülen şartlar çerçevesinde kişisel verilerinizin silinmesini veya yok edilmesini isteme, zarara uğramanız hâlinde zararınızın giderilmesini talep etme haklarına sahipsiniz. Kişisel verilerinizle ilgili sorularınızı ve taleplerinizi, info@devent.com adresine gönderebilir ya da 0 216 573 18 36 numaralı telefondan bilgi alabilirsiniz. Şirket, işbu metni yürürlükteki mevzuatta yapılabilecek değişiklikler çerçevesinde her zaman güncelleme hakkını saklı tutar. B-    TİCARİ ELEKTRONİK İLETİ MUVAFAKATNAMESİ D Event Turizm Organizasyon Hizmetleri Limited Şirketi’ne vermiş olduğum iletişim adreslerime,  her türlü tanıtım, reklam, bilgilerme vb. amaçlarla ticari elektronik ileti (e-posta,sms vs.) gönderilmesine 6563 sayılı Kanun gereği muvafakat ediyorum.")),
        actions: <Widget>[
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text("Tamam"),
          ),
        ],
      );
    },
  );
}
class _LoginViewState extends State<LoginView> {
  Future<void> LoginCheck() async{
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    if (prefs.getString('token') != null){
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const MainPageView(title: 'Main Page')),
      );
    }
  }
  @override
  initState(){
    super.initState();
    LoginCheck();
  }
//344c1051-b28a-4934-8159-b12983258f86
  @override
  Widget build(BuildContext context) {
    Size screenSize = MediaQuery.of(context).size;
    double screenWidth = screenSize.width;
    double screenHeight = screenSize.height;
    return Stack(
        alignment: Alignment.center,
        children: [
          Stack(
            children: [
              Positioned(
                top: -1*screenHeight,
                left: -1*screenWidth*1.5,
                height: screenHeight*2,
                width: screenWidth*4,
                child: Container(
                  width: screenWidth*4,
                  height: screenWidth*2,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Positioned(
                top: -1*screenHeight/2,
                left: -1*screenWidth/2,
                height: screenHeight,
                width: screenWidth*2,
                child: Container(
                  width: screenWidth*2,
                  height: screenWidth,
                  decoration: const BoxDecoration(
                    color: AppConstants.backgroundBlue,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
          SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  height: screenHeight*0.2,
                ),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(screenWidth * 0.4),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.4),
                        spreadRadius: 5,
                        blurRadius: 7,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(screenWidth*0.4),
                    child: Container(
                      color: Colors.white,
                      width: screenWidth*0.4,
                      height: screenWidth*0.4,
                      child: const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Image(
                          image: AssetImage('assets/app_icon.png'),
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  height: screenHeight*0.02,
                ),
                ElevatedButton(
                    style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.all<Color>(AppConstants.loginButtonOrange),
                      foregroundColor: MaterialStateProperty.all<Color>(Colors.white),
                      padding: MaterialStateProperty.all<EdgeInsetsGeometry>(
                        const EdgeInsets.all(12),
                      ),
                      shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            contentPadding: EdgeInsets.zero,
                            content: Container(
                              width: screenWidth * 0.9,
                              height: screenHeight * 0.9,
                              child: const QRViewExample(),
                            ),
                          );
                        },
                      );
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Giriş Yap',
                          style: TextStyle(fontSize: 25),
                        ),
                        SvgPicture.asset(
                          'assets/icon/chevron.right.svg',
                          color:Colors.white,
                          width: screenWidth*0.05,
                        ),

                      ],
                    )
                ),
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text(
                    'Giriş butonuna bastıktan sonra yaka kartınızda bulunan kare kodu kameraya gösteriniz',
                    style: TextStyle(fontSize: 20),
                    textAlign: TextAlign.center,
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(8.0),
                  child: RichText(
                    text: TextSpan(
                      text: 'Uygulamaya giriş yaparak ',
                      style: TextStyle(fontSize: 15, color: Colors.black),
                      children: <TextSpan>[
                        TextSpan(
                          text: '6698 sayılı KVKK\'yı kabul ediyorum',
                          style: const TextStyle(
                            fontSize: 15,
                            color: Colors.black,
                            decoration: TextDecoration.underline,
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () {

                              _showPopup(context);
                            },
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                SizedBox(
                  height: screenHeight*0.02,
                ),
                ElevatedButton(
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all<Color>(AppConstants.loginWithCodeButtonBlue),
                    foregroundColor: MaterialStateProperty.all<Color>(Colors.black),
                    padding: MaterialStateProperty.all<EdgeInsetsGeometry>(
                      const EdgeInsets.all(12),
                    ),
                    shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          backgroundColor: AppConstants.backgroundBlue,
                          contentPadding: EdgeInsets.zero,
                          content: SizedBox(
                            width: screenWidth * 0.9,
                            height: screenHeight * 0.9,
                            child: const LoginWithCodeView(title: 'Login With Code'),
                          ),
                        );
                      },
                    );
                  },
                  child: const Text(
                    'Kod ile giriş',
                    style: TextStyle(fontSize: 15),
                  ),
                ),
                SizedBox(height: screenHeight*0.02),
              ],
            ),
          ),

        ]
    );
  }
}
class QRViewExample extends StatefulWidget {
  const QRViewExample({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _QRViewExampleState();
}

class _QRViewExampleState extends State<QRViewExample> {
  Barcode? result;
  String? responseText;
  QRViewController? controller;
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');

  // In order to get hot reload to work we need to pause the camera if the platform
  // is android, or resume the camera if the platform is iOS.
  @override
  void reassemble() {
    super.reassemble();
    if (Platform.isAndroid) {
      controller!.pauseCamera();
    }
    controller!.resumeCamera();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: <Widget>[
          Expanded(flex: 4, child: _buildQrView(context)),
        ],
      ),
    );
  }

  Widget _buildQrView(BuildContext context) {
    // For this example we check how width or tall the device is and change the scanArea and overlay accordingly.
    var scanArea = (MediaQuery.of(context).size.width < 400 ||
        MediaQuery.of(context).size.height < 400)
        ? 150.0
        : 300.0;
    // To ensure the Scanner view is properly sizes after rotation
    // we need to listen for Flutter SizeChanged notification and update controller
    return QRView(
      key: qrKey,
      onQRViewCreated: _onQRViewCreated,
      overlay: QrScannerOverlayShape(
          borderColor: Colors.red,
          borderRadius: 10,
          borderLength: 30,
          borderWidth: 10,
          cutOutSize: scanArea),
      onPermissionSet: (ctrl, p) => _onPermissionSet(context, ctrl, p),
    );
  }

  void _onQRViewCreated(QRViewController controller) {
    setState(() {
      this.controller = controller;
    });
    controller.scannedDataStream.listen((scanData) {
      setState(() {
        result = scanData;
        if (result != null){
          Login(result!.code!);
        }
      });
    });
  }

  Future<void> Login(String code) async {
    await controller?.pauseCamera();
    final response = await http.post(
      Uri.parse('http://app.kongrepad.com/api/v1/auth/login/participant'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        'username': code,
      }),
    );
    if (jsonDecode(response.body)['token'] != null) {
      setState(() {
        responseText = jsonDecode(response.body)['token'];
      });
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', responseText!);
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const MainPageView(title: 'Main Page')),
      );
    } else {
      setState(() {
        AlertService().showAlertDialog(
          context,
          title: 'Hata',
          content: 'Yanlış qr code girdiniz!',
        );
      });
      await controller?.resumeCamera();
    }
  }

  void _onPermissionSet(BuildContext context, QRViewController ctrl, bool p) {
    log('${DateTime.now().toIso8601String()}_onPermissionSet $p');
    if (!p) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('no Permission')),
      );
    }
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }
}

class LoginWithCodeView extends StatefulWidget {
  const LoginWithCodeView({super.key, required this.title});

  final String title;

  @override
  State<LoginWithCodeView> createState() => _LoginWithCodeViewState();
}

class _LoginWithCodeViewState extends State<LoginWithCodeView> {
  final TextEditingController _controller = TextEditingController();
  String responseText = "";

  void _submit() async {
    final response = await http.post(
      Uri.parse('http://app.kongrepad.com/api/v1/auth/login/participant'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        'username': _controller.text,
      }),
    );
    if (jsonDecode(response.body)['token'] != null) {
      setState(() {
        responseText = jsonDecode(response.body)['token'];
      });
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', responseText);
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const MainPageView(title: 'Main Page')),
      );
    } else {
      AlertService().showAlertDialog(
        context,
        title: 'Hata',
        content: 'Yanlış kod girdiniz!',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    Size screenSize = MediaQuery.of(context).size;
    double screenWidth = screenSize.width;
    double screenHeight = screenSize.height;

    return Expanded(
      child: Scaffold(
        body: Center(
          child: Container(
            padding: const EdgeInsets.all(15),
            constraints: BoxConstraints(
              maxHeight: screenHeight * 0.8, // Ekranın %80'ine kadar genişleyebilir
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min, // İçeriği minimum boyutta tutar
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextField(
                  controller: _controller,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    hintText: 'Lütfen Kodunuzu buraya giriniz',
                    hintStyle: const TextStyle(color: Colors.orange),
                    focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Colors.orange),
                      borderRadius: BorderRadius.circular(40),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Colors.orange),
                      borderRadius: BorderRadius.circular(40),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        vertical: 10.0, horizontal: 15.0),
                  ),
                ),
                SizedBox(height: screenHeight * 0.02),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: RichText(
                    text: TextSpan(
                      text: 'Uygulamaya giriş yaparak ',
                      style: const TextStyle(fontSize: 15, color: Colors.white),
                      children: <TextSpan>[
                        TextSpan(
                          text: '6698 sayılı KVKK\'yı kabul ediyorum',
                          style: const TextStyle(
                            fontSize: 15,
                            color: Colors.white,
                            decoration: TextDecoration.underline,
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () {
                              _showPopup(context);
                            },
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                SizedBox(height: screenHeight * 0.02),
                ElevatedButton(
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all<Color>(AppConstants.loginButtonOrange),
                    foregroundColor: MaterialStateProperty.all<Color>(Colors.white),
                    padding: MaterialStateProperty.all<EdgeInsetsGeometry>(
                      const EdgeInsets.all(12),
                    ),
                    shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                  onPressed: _submit,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Giriş Yap',
                        style: TextStyle(fontSize: 25),
                      ),
                      SvgPicture.asset(
                        'assets/icon/chevron.right.svg',
                        color: Colors.white,
                        width: screenWidth * 0.05,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
