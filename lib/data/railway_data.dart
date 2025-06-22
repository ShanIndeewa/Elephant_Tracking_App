import 'package:latlong2/latlong.dart';

class RailwayData {
  // Data sourced and simplified from public map data.
  // This is a representative sample, not exhaustive.
  static final Map<String, List<LatLng>> allTracks = {
    'main_line': [
      const LatLng(6.9319, 79.8478), // Colombo Fort
      const LatLng(6.9350, 79.8525), // Maradana
      const LatLng(6.9147, 79.8778), // Ragama
      const LatLng(7.0919, 79.9986), // Gampaha
      const LatLng(7.2906, 80.6337), // Kandy
      const LatLng(7.2150, 80.7718), // Peradeniya
      const LatLng(6.9531, 80.7788), // Hatton
      const LatLng(6.8983, 80.8030), // Nanu Oya
      const LatLng(6.8699, 81.0568), // Ella
      const LatLng(6.8016, 81.2390), // Badulla
    ],
    'coastal_line': [
      const LatLng(6.9319, 79.8478), // Colombo Fort
      const LatLng(6.8530, 79.8610), // Dehiwala
      const LatLng(6.7970, 79.8885), // Moratuwa
      const LatLng(6.0535, 80.2210), // Galle
      const LatLng(5.9496, 80.5489), // Matara
    ],
    'northern_line': [
      const LatLng(6.9350, 79.8525), // Maradana
      const LatLng(6.9147, 79.8778), // Ragama
      const LatLng(7.4674, 80.0000), // Polgahawela
      const LatLng(8.3496, 80.4180), // Anuradhapura
      const LatLng(9.2500, 80.4167), // Vavuniya
      const LatLng(9.6615, 80.0255), // Jaffna
    ],
    'puttalam_line': [
      const LatLng(6.9147, 79.8778), // Ragama
      const LatLng(7.0333, 79.8499), // Ja-Ela
      const LatLng(7.2000, 79.8333), // Negombo
      const LatLng(7.6800, 79.8500), // Chilaw
      const LatLng(8.0333, 79.7900), // Puttalam
    ]
  };
}