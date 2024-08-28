import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

void main() {
  runApp(MaterialApp(home: AboutPage()));
}

class AboutPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          // Logo en la parte superior
          Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Image.asset(
                'images/icon.png', // Reemplaza con la ruta de tu ícono personalizado
                height: 210.0,
                fit: BoxFit.contain,
              ),
            ),
          ),
          // Botones "Asistencia Vial" y "Servicio al Cliente"
          //      _buildCategoryButton("Asistencia Vial", [
          //      _buildWhatsAppOptionButton("Solicitud de grúa", Icons.local_car_wash, WHATSAPP1),
          //    _buildWhatsAppOptionButton("Suministro de carga de batería", Icons.battery_charging_full, WHATSAPP2),
          //  _buildWhatsAppOptionButton("Suministro de combustible", Icons.local_gas_station, WHATSAPP3),
          //   _buildEmergencyCallButton("Llamada de emergencia", Icons.sos_rounded),
          //    ]),
          _buildCategoryButton("Servicio al Cliente", [
            //     _buildEmergencyCallButton("Llamada de emergencia", Icons.sos_rounded),
            _buildWhatsAppOptionButton("Soporte - Ventas", Icons.contact_support_rounded, WHATSAPP1),
            //   _buildWhatsAppOptionButton("Soporte", Icons.support_agent, WHATSAPP2),
            //     _buildWhatsAppOptionButton("Redes sociales", Icons.info, WHATSAPP3),
            //        _buildWhatsAppOptionButton("Cotizar seguro de auto", Icons.security, WHATSAPP4),
            _buildWhatsAppOptionButton("Sitio web oficial", Icons.web, WHATSAPP5),
            _buildWhatsAppOptionButton("Correo electrónico", Icons.email_outlined, CORREO),
          ]),

          // Enlace a Términos y Políticas de Privacidad
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: () {
                // Abre la URL de Términos y Políticas de Privacidad
                _openPrivacyPolicyURL();
              },
              child: Text("Términos y Políticas de Privacidad"),
            ),
          ),
          // Botones de redes sociales
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: <Widget>[
  //            IconButton(
    //            icon: Icon(FontAwesomeIcons.facebook),
      //          onPressed: () {
                  //  Abre Facebook
        //          _openSocialMediaURL(FB_APP);
        //        },
          //    ),
       //       IconButton(
         //       icon: Icon(FontAwesomeIcons.instagram),
           //     onPressed: () {
                  // Abre Instagram
             //     _openSocialMediaURL(INSTA_APP);
               // },
           //   ),
    //          IconButton(
      //          icon: Icon(FontAwesomeIcons.youtube),
        //        onPressed: () {
                  // Abre TikTok
      //            _openSocialMediaURL(TIKTOK_APP);
        //        },
          //    ),
       //                    IconButton(
         //                    icon: Icon(FontAwesomeIcons.linkedin),
           //                 onPressed: () {
              // Abre LinkedIn
            //                 _openSocialMediaURL(LINKEDIN_APP);
        //                },
              //                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWhatsAppOptionButton(String option, IconData icon, String url) {
    return itemCardList(AboutModel(option, icon, url));
  }

  Widget itemCardList(AboutModel aboutItem) {
    return Card(
      elevation: 1.0,
      child: InkWell(
        onTap: () async {
          await launch(aboutItem.url);
        },
        child: Row(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Icon(aboutItem.icon),
            ),
            new Container(
              padding: EdgeInsets.only(left: 10.0, top: 5, bottom: 5),
              child: Text(
                aboutItem.title,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 15.0,
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  void _openPrivacyPolicyURL() async {
    // Reemplaza con la URL de tus Términos y Políticas de Privacidad
    const privacyPolicyUrl = "https://trazegps.cl/privacy-policy/";
    if (await canLaunch(privacyPolicyUrl)) {
      await launch(privacyPolicyUrl);
    } else {
      // Manejar el error según sea necesario
    }
  }

  void _openSocialMediaURL(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      // Manejar el caso cuando no se pueda abrir la URL
    }
  }

  Widget _buildCategoryButton(String category, List<Widget> options) {
    return Column(
      children: [
        // Título de la categoría
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            category,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        // Lista de opciones con botones
        Column(
          children: options,
        ),
      ],
    );
  }

  Widget _buildEmergencyCallButton(String option, IconData icon) {
    return itemCardList(AboutModel(option, icon, "tel:911"));
  }
}

// Definición de URLs de WhatsApp para cada botón
const String WHATSAPP1 = "https://wa.me/56983083178";
const String WHATSAPP2 = "https://wa.me/5215546505882";
const String WHATSAPP3 = "https://linktr.ee/soltech_avl";
const String WHATSAPP4 = "https://wa.me/573237780615";
const String WHATSAPP5 = "https://trazegps.cl";
const String CORREO = "mailto:soporte@trazegps.cl";
// ... (otros métodos y clases)

class AboutModel {
  final String title;
  final IconData icon;
  final String url;

  AboutModel(this.title, this.icon, this.url);
}

// URLs de redes sociales
const String INSTA_APP = "https://www.instagram.com/smarttrack_ar/";
const String FB_APP = "https://www.facebook.com/smarttrack.ar/";
const String TIKTOK_APP = "https://www.youtube.com/@smarttrack1019";
const String LINKEDIN_APP = "https://www.linkedin.com/company/smarttrack-com-ar";
