import 'package:flutter/material.dart';

class Constants {
  static String baseUrl = "dummyjson.com";
  static String categoriesApi = "/products/categories";
  Color themeColor = Color(0xFF4D79FF);
  Color greyColor = Color(0xff666F80);

  static final String mapStyle = '''
[
  {
    "elementType": "geometry",
    "stylers": [
      {"color": "#f2f3f5"}
    ]
  },
  {
    "elementType": "labels.icon",
    "stylers": [
      {"visibility": "off"}
    ]
  },
  {
    "elementType": "labels.text.fill",
    "stylers": [
      {"color": "#7a7a7a"}
    ]
  },
  {
    "elementType": "labels.text.stroke",
    "stylers": [
      {"color": "#f2f3f5"}
    ]
  },
  {
    "featureType": "administrative",
    "elementType": "geometry",
    "stylers": [
      {"visibility": "off"}
    ]
  },
  {
    "featureType": "poi",
    "elementType": "geometry",
    "stylers": [
      {"color": "#e7ebf0"}
    ]
  },
  {
    "featureType": "poi.park",
    "elementType": "geometry",
    "stylers": [
      {"color": "#cbe6c7"}
    ]
  },
  {
    "featureType": "road",
    "elementType": "geometry",
    "stylers": [
      {"color": "#d4d7db"}
    ]
  },
  {
    "featureType": "road.highway",
    "elementType": "geometry",
    "stylers": [
      {"color": "#efc6c6"}
    ]
  },
  {
    "featureType": "road.highway",
    "elementType": "labels",
    "stylers": [
      {"visibility": "off"}
    ]
  },
  {
    "featureType": "transit",
    "elementType": "geometry",
    "stylers": [
      {"color": "#e3e6ea"}
    ]
  },
  {
    "featureType": "transit.station",
    "stylers": [
      {"visibility": "off"}
    ]
  },
  {
    "featureType": "water",
    "elementType": "geometry",
    "stylers": [
      {"color": "#a8c4f0"}
    ]
  }
]
''';
}
