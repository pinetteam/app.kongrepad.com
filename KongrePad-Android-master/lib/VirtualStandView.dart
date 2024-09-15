import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:kongrepad/AppConstants.dart';
import 'package:kongrepad/Models/VirtualStand.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class VirtualStandView extends StatefulWidget {
  const VirtualStandView({super.key, required this.stand});

  final VirtualStand stand;

  @override
  State<VirtualStandView> createState() => _VirtualStandViewState(stand);
}


class _VirtualStandViewState extends State<VirtualStandView> {

  final VirtualStand stand;

  @override
  Widget build(BuildContext context) {
    Size screenSize = MediaQuery.of(context).size;
    double screenWidth = screenSize.width;
    double screenHeight = screenSize.height;
    return SafeArea(
      child: Scaffold(
        body: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              height: screenHeight*0.1,
              decoration: const BoxDecoration(
                color: AppConstants.virtualStandBlue
              ),
              child: Container(
                width: screenWidth,
                child: Stack(
                  alignment: Alignment.centerLeft,
                  children: [
                      GestureDetector(
                        onTap:() {
                          Navigator.pop(context);
                        },
                        child: Container(
                          height: screenHeight*0.05,
                          width: screenHeight*0.05,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppConstants.logoutButtonBlue, // Circular background color
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: SvgPicture.asset(
                              'assets/icon/chevron.left.svg',
                              color:Colors.white,
                              height: screenHeight*0.03,
                            ),
                          ),
                        ),
                      ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.network(
                        'https://app.kongrepad.com/storage/virtual-stands/${stand.fileName}.${stand.fileExtension}',
                        width: 150, // Adjust image width as needed
                        height: 150, // Adjust image height as needed
                        fit: BoxFit.contain,
                      ),
                      ]
                    ),
                  ],
                ),
              ),
            ),
            Container(
              height: screenHeight*0.85,
              child: SfPdfViewer.network(
                'https://app.kongrepad.com/storage/virtual-stand-pdfs/${stand.pdfName}.pdf'),
            ),
          ]
        )
      ),
    );
  }

  _VirtualStandViewState(this.stand);
}
