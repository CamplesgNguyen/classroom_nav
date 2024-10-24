import 'package:latlong2/latlong.dart';

class CoordNode {
  CoordNode(this.coord, this.gVal, this.hVal, this.fVal);
  LatLng coord = const LatLng(0, 0);
  double fVal = 0;
  double gVal = 0;
  double hVal = 0;
  
  
}
