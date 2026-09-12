import 'package:syncfusion_flutter_pdf/pdf.dart';

class EditablePdfPage {
  EditablePdfPage({
    required this.originalIndex,
    this.rotationSteps = 0,
  });

  final int originalIndex;
  int rotationSteps;

  void rotateClockwise() {
    rotationSteps = (rotationSteps + 1) % 4;
  }

  PdfPageRotateAngle get rotationAngle {
    switch (rotationSteps % 4) {
      case 0:
        return PdfPageRotateAngle.rotateAngle0;
      case 1:
        return PdfPageRotateAngle.rotateAngle90;
      case 2:
        return PdfPageRotateAngle.rotateAngle180;
      case 3:
        return PdfPageRotateAngle.rotateAngle270;
      default:
        return PdfPageRotateAngle.rotateAngle0;
    }
  }

  int get displayPageNumber => originalIndex + 1;
}
