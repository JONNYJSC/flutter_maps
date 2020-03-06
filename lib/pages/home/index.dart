import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_maps/api/nominatim.dart';
import 'package:flutter_maps/models/reverse_result.dart';
import 'package:flutter_maps/models/search_result.dart';
import 'package:flutter_maps/pages/home/map_utils.dart';
import 'package:flutter_maps/pages/home/widgets/my_center_position.dart';
import 'package:flutter_maps/pages/home/widgets/toolbar.dart';
import 'dart:typed_data';
import 'dart:math' as math;
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Nominatim _nominatim = Nominatim();

  PanelController _panelController = PanelController();
  GoogleMapController _mapController;
  // Uint8List _carPin;
  // Marker _myMarker;

  /*final CameraPosition _kGooglePlex = CameraPosition(
    target: LatLng(12.163234, -86.278021),
    zoom: 16.4746,
  );*/
  CameraPosition _initialCameraPosition;

  StreamSubscription<Position> _positionStream;
  Map<MarkerId, Marker> _markers = Map();
  Map<PolylineId, Polyline> _polylines = Map();
  Map<PolygonId, Polygon> _polygons = Map();

  var _isPanelOpen = false;
  LatLng _centerposition, _myPosition;
  ReverseResult _reverseResult;

  // List<LatLng> _myRoute = List();

  // Position _lastPosition;

  @override
  void initState() {
    super.initState();
    _startTracking();
    _nominatim.onReverse = (ReverseResult result) {
      setState(() {
        _reverseResult = result;
      });
      //print(result.toString());
    };
    /*_loadCardPin();*/
  }

  //Mostrar imagen en marcador
  /*_loadCardPin() async {
    _carPin =
        await MapUtils.loadPinFromAsset('assets/icons/car-pin.png', width: 60);
    _startTracking();
  }*/

  //presicion mas alta posible (LocationAccuracy.high), cada 5 metros notificar cambios de ubicacion(distanceFilter: 5)
  _startTracking() {
    final geolocator = Geolocator();
    final locationOptions =
        LocationOptions(accuracy: LocationAccuracy.high, distanceFilter: 5);

    _positionStream =
        geolocator.getPositionStream(locationOptions).listen(_onLocationUpdate);
  }

  _onLocationUpdate(Position position) {
    if (position != null) {
      final myposition = LatLng(position.latitude, position.longitude);

      _myPosition = myposition;

      if (_initialCameraPosition == null) {
        setState(() {
          _initialCameraPosition = CameraPosition(target: myposition, zoom: 14);
        });
      }

      /*_myRoute.add(myposition);

      final myPolyline = Polyline(
          polylineId: PolylineId('me'),
          points: _myRoute,
          color: Colors.cyanAccent,
          width: 8);

      if (_myMarker == null) {
        final markerId = MarkerId('me');
        final bitmap = BitmapDescriptor.fromBytes(_carPin);
        _myMarker = Marker(
            markerId: markerId,
            position: myposition,
            icon: bitmap,
            rotation: 0,
            anchor: Offset(0.5, 0.5));
      } else {
        final rotation = _getMyBearing(_lastPosition, position);
        _myMarker = _myMarker.copyWith(
            positionParam: myposition, rotationParam: rotation);
      }
      setState(() {
        _markers[_myMarker.markerId] = _myMarker;
        _polylines[myPolyline.polylineId] = myPolyline;
      });
      _lastPosition = position;
      _move(position);*/
    }
  }

  /*double _getMyBearing(Position lastPosition, Position currentPosition) {
    final dx = math.cos(math.pi / 180 * lastPosition.latitude) *
        (currentPosition.longitude - lastPosition.longitude);
    final dy = currentPosition.latitude - lastPosition.latitude;
    final angle = math.atan2(dy, dx);
    return 90 - angle * 180 / math.pi;
  }*/

  //libera los recursos del cel
  @override
  void dispose() {
    if (_positionStream != null) {
      _positionStream.cancel();
      _positionStream = null;
    }
    _nominatim.dispose();
    super.dispose();
  }

  //Actualizacion de ubicacion en movimiento
  _moveCamera(LatLng position, {double zoom = 12}) {
    final cameraUpdate = CameraUpdate.newLatLngZoom(position, zoom);
    _mapController.animateCamera(cameraUpdate);
  }

  /*_updateMarkerPosition(MarkerId markerId, LatLng p) {
    print('newPosition');
    _markers[markerId] = _markers[markerId].copyWith(positionParam: p);
  }*/

  _onMarkerTap(String id) {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return CupertinoAlertDialog(
            title: Text('Click'),
            content: Text('marker id $id'),
            actions: <Widget>[
              CupertinoDialogAction(
                child: Text('OK'),
                onPressed: () => Navigator.pop(context),
              )
            ],
          );
        });
  }

  //Mostrando marcador
  /*_onTap(LatLng p) {
    final id = '${_markers.length}';
    final markerId = MarkerId(id);
    final marker = Marker(
        markerId: markerId,
        position: p,
        draggable: true,
        onTap: () => _onMarkerTap(id),
        onDragEnd: (np) => _updateMarkerPosition(markerId, np));
    setState(() {
      _markers[markerId] = marker;
    });
  }*/

  _onCameraMoveStarted() {
    print('Move Started');
    setState(() {
      // _isCameraMoving = true;
      _reverseResult = null;
    });
  }

  _onCameraMove(CameraPosition cameraPosition) {
    print(
        'Moving ${cameraPosition.target.latitude},${cameraPosition.target.longitude}');
    _centerposition = cameraPosition.target;
  }

  _onCameraIdle() {
    print('Move fnished');
    _nominatim.reverse(_centerposition);
    // setState(() {
    //   _isCameraMoving = false;
    // });
  }

  _onSearch(SearchResult result) {
    _moveCamera(result.position, zoom: 16);

    if (result.polygon.length > 0) {
      final polygonId = PolygonId(result.displayName);
      final polygon = Polygon(
          polygonId: polygonId,
          points: result.polygon,
          strokeWidth: 1,
          strokeColor: Colors.white,
          fillColor: Colors.cyan.withOpacity(0.2));
      setState(() {
        _polygons[polygon.polygonId] = polygon;
      });
    } else {
      print("No hay polygon");
    }
  }

  _onGoMyPosition() {
    if (_myPosition != null) {
      _moveCamera(_myPosition, zoom: 15);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final padding = MediaQuery.of(context).padding;
    final slidingUpPanelHeight = size.height - padding.top - padding.bottom;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        child: _initialCameraPosition == null
            ? Center(
                child: CupertinoActivityIndicator(radius: 15),
              )
            : SafeArea(
                child: SlidingUpPanel(
                  controller: _panelController,
                  onPanelOpened: () {
                    setState(() {
                      _isPanelOpen = true;
                    });
                  },
                  onPanelClosed: () {
                    setState(() {
                      _isPanelOpen = false;
                    });
                  },
                  maxHeight: slidingUpPanelHeight,
                  backdropEnabled: true,
                  backdropOpacity: 0.2,
                  body: LayoutBuilder(
                    builder: (context, constrains) {
                      return Stack(
                        children: <Widget>[
                          GoogleMap(
                            initialCameraPosition: _initialCameraPosition,
                            myLocationButtonEnabled: false,
                            myLocationEnabled: true,
                            // onTap: _onTap,
                            markers: Set.of(_markers.values),
                            polylines: Set.of(_polylines.values),
                            polygons: Set.of(_polygons.values),
                            onCameraMoveStarted: _onCameraMoveStarted,
                            onCameraMove: _onCameraMove,
                            onCameraIdle: _onCameraIdle,
                            onMapCreated: (GoogleMapController controller) {
                              _mapController = controller;
                              // _mapController
                              //     .setMapStyle(jsonEncode(mapStyle));
                            },
                          ),
                          MyCenterPosition(
                            reverseResult: _reverseResult,
                            containerHeight: constrains.maxHeight,
                          ),
                        ],
                      );
                    },
                  ),
                  panel: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      _isPanelOpen
                          ? Toolbar(
                              onSearch: _onSearch,
                              onGoMyPosition: _onGoMyPosition,
                              containerHeight: slidingUpPanelHeight,
                              onClear: (){
                                _panelController.close();
                              },
                            )
                          : Container(
                              width: double.infinity,
                              padding: EdgeInsets.all(15),
                              child: CupertinoButton(
                                onPressed: () {
                                  _panelController.open();
                                },
                                color: Color(0xfff0f0f0),
                                padding: EdgeInsets.symmetric(
                                    horizontal: 15, vertical: 15),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: <Widget>[
                                    Text(
                                      'A donde quieres ir?',
                                      textAlign: TextAlign.left,
                                      style: TextStyle(
                                          color: Colors.black54,
                                          fontSize: 19,
                                          letterSpacing: 1),
                                    ),
                                    Icon(
                                      Icons.search,
                                      color: Colors.black54,
                                      size: 30,
                                    )
                                  ],
                                ),
                              ),
                            )
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
