import 'dart:convert';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'MainPageView.dart';
import '../services/alert_service.dart';
import '../utils/app_constants.dart';
import 'login_with_code_view..dart';
import 'qr_view_example.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  Future<void> _checkLoginStatus() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    if (prefs.getString('token') != null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const MainPageView(title: 'Main Page')),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  void _showPopup(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppConstants.backgroundBlue,
          title: const Text(
            "KİŞİLER VERİLERİN KORUNMASI AYDINLATMA METNİ ve TİCARİ ELEKTRONİK İLETİ MUVAFAKATNAMESİ ",
            style: TextStyle(color: Colors.white),
          ),
          content: const SingleChildScrollView(
            child: Text(
              "A-    KİŞİLER VERİLERİN KORUNMASI AYDINLATMA METNİ 6698 sayılı Kişisel Verilerin Korunması Kanunu (“Kanun”) uyarınca, kişisel verileriniz; veri sorumlusu olarak D Event Turizm Organizasyon Hizmetleri Limited Şirketi (“D Event” veya “Şirket”) tarafından aşağıda açıklanan koşullar kapsamında işlenmektedir.1.Kişisel Verilerin İşlenme Amacı\nKişisel verileriniz, bilgi güvenliğini ve hukuki işlem güvenliğini sağlamamız ve faaliyetlerin mevzuata uygun yürütülmesini sağlamamamız başta olmak üzere, iletişim faaliyetlerinin yürütülmesi, verilerinizin doğruluğunun sağlanması, ürün/hizmetlerin pazarlama süreçlerinin yürütülmesi,ürün ve/veya hizmetlerimizin tanıtımı, sunulması ve satış süreçlerinin işletilmesi, sözleşmelerin müzakeresi, akdedilmesi ve ifası, mevcut ile yeni ürün ve hizmetlerdeki değişikliklerin, kampanyaların, promosyonların duyurulması, pazarlama ve satış faaliyetlerinin yürütülmesi, sosyal medya ve kurumsal iletişim süreçlerinin planlanması ve icra edilmesi, reklam/kampanya/promosyon süreçlerinin yürütülmesi, ihtiyaçlar, talepler ile yasal ve teknik gelişmeler doğrultusunda ürün ve hizmetlerimizin güncellenmesi, özelleştirilmesi, geliştirilmesi ve üyelik işlemlerinin gerçekleştirilmesi amaçlarıyla işlenecektir.2. Kişisel Verileri Toplama Yöntemleri ve Hukuki Sebepleri\nMobil uygulama/internet sitesi üzerinden toplanan kişisel veriler (kimlik ve iletişim bilgileri) ilgili kişinin mobil uygulama/internet sitesi içerisinde yer alan formları doldurması ile toplanmaktadır. Bu kişisel veriler Kanun’da belirtilen kişisel veri işleme şartlarına uygun olarak ve sizinle aramızdaki ilişkinin icrası ve faaliyetlerin mevzuata uygunluğunun temini amaçları başta olmak üzere, sizlere ait kişisel verilerin işlenmesinin gerekli olması, hukuki yükümlülüğümüzü yerine getirebilmek için zorunlu olması hukuki sebepleri doğrultusunda işlenmektedir. 3.İşlenen Kişisel Verilerin Aktarılması\n Şirketimiz, kişisel verilerinizi “bilme gereği” ve “kullanma gereği” ilkelerine uygun olarak, gerekli veri minimizasyonunu sağlayarak ve gerekli teknik ve idari güvenlik tedbirlerini alarak işlemeye özen göstermektedir. Şirketimiz, topladığı kişisel verileri faaliyetlerini yürütebilmek için iş birliği yaptığı kurum ve kuruluşlarla, verilerin bulut ortamında saklanması halinde yurt içindeki/yurt dışındaki kişi ve kurumlarla, ticari elektronik iletilerin gönderilmesi konusunda anlaşmalı olduğu yurt içindeki/yurt dışındaki kuruluşlarla, talep halinde kamu otoriteleriyle ve hizmetin verilmesiyle ilgili olarak iş ortakları ile paylaşabilmektedir. 4.Veri Sorumlusuna Başvuru Yolları ve Haklarınız\nŞirketimize başvurarak, kişisel verilerinizin işlenip işlenmediğini öğrenme, işlenmişse buna ilişkin bilgi talep etme, kişisel verilerinizin işlenme amacını ve bunların amacına uygun kullanılıp kullanılmadığını öğrenme, yurt içinde kişisel verilerinizin aktarıldığı üçüncü kişileri bilme, kişisel verilerinizin eksik veya yanlış işlenmiş olması halinde bunların düzeltilmesini isteme ve bu kapsamda yapılan işlemin kişisel verilerin aktarıldığı üçüncü kişilere bildirilmesini isteme, kanunda öngörülen şartlar çerçevesinde kişisel verilerinizin silinmesini veya yok edilmesini isteme, zarara uğramanız hâlinde zararınızın giderilmesini talep etme haklarına sahipsiniz. Kişisel verilerinizle ilgili sorularınızı ve taleplerinizi, info@devent.com adresine gönderebilir ya da 0 216 573 18 36 numaralı telefondan bilgi alabilirsiniz. Şirket, işbu metni yürürlükteki mevzuatta yapılabilecek değişiklikler çerçevesinde her zaman güncelleme hakkını saklı tutar. B-    TİCARİ ELEKTRONİK İLETİ MUVAFAKATNAMESİ D Event Turizm Organizasyon Hizmetleri Limited Şirketi’ne vermiş olduğum iletişim adreslerime, her türlü tanıtım, reklam, bilgilerme vb. amaçlarla ticari elektronik ileti (e-posta,sms vs.) gönderilmesine 6563 sayılı Kanun gereği muvafakat ediyorum.",
              style: TextStyle(color: Colors.white),
            ),
          ),
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

  @override
  Widget build(BuildContext context) {
    Size screenSize = MediaQuery.of(context).size;
    double screenWidth = screenSize.width;
    double screenHeight = screenSize.height;

    return Scaffold(
      body: Stack(
        alignment: Alignment.center,
        children: [
          // Background shapes
          Stack(
            children: [
              Positioned(
                top: -1 * screenHeight,
                left: -1 * screenWidth * 1.6,
                height: screenHeight * 2,
                width: screenWidth * 4.3,
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Positioned(
                top: -1 * screenHeight / 2,
                left: -1 * screenWidth / 2,
                height: screenHeight,
                width: screenWidth * 2,
                child: Container(
                  decoration: const BoxDecoration(
                    color: AppConstants.backgroundBlue,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
          // Main content

          Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(height: 130,),

                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(screenWidth * 0.4),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.4),
                          spreadRadius: 5,
                          blurRadius: 7,
                          offset: const Offset(0, 3),
                        ),

                      ],
                    ),

                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(screenWidth * 0.4),
                      child: Container(
                        color: Colors.white,
                        width: screenWidth * 0.4,
                        height: screenWidth * 0.4,
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
                 // SizedBox(height: screenHeight * 0.02),
                  SizedBox(height: 30,),

                  ElevatedButton(
                    style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.all<Color>(AppConstants.loginButtonOrange),
                      foregroundColor: MaterialStateProperty.all<Color>(Colors.white),
                      padding: MaterialStateProperty.all<EdgeInsetsGeometry>(const EdgeInsets.all(12)),
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
                            content: SizedBox(
                              width: screenWidth * 0.9,
                              height: screenHeight * 0.9,
                              child: const QRViewExample(),
                            ),
                          );
                        },
                      );
                    },
                    child: Padding(
                      padding: EdgeInsets.all(8),
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
                    padding: const EdgeInsets.all(7.0),
                    child: RichText(
                      text: TextSpan(
                        text: 'Uygulamaya giriş yaparak ',
                        style: const TextStyle(color: Colors.black),
                        children: [
                          TextSpan(
                            text: '6698 sayılı KVKK\'yı kabul ediyorum',
                            style: const TextStyle(
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
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.02),
                  ElevatedButton(
                    style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.all<Color>(AppConstants.loginWithCodeButtonBlue),
                      foregroundColor: MaterialStateProperty.all<Color>(Colors.black),
                      padding: MaterialStateProperty.all<EdgeInsetsGeometry>(const EdgeInsets.all(12)),
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
                          return const AlertDialog(
                            content: LoginWithCodeView(),
                          );
                        },
                      );
                    },
                    child: const Text(
                      'Kod ile giriş',
                      style: TextStyle(fontSize: 15),
                    ),
                  ),
                  //SizedBox(height: screenHeight * 0.0),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
