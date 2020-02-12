import 'dart:async';
import 'dart:convert';

import 'package:credpal/app/baseApp.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:location/location.dart';

import 'AppEngine.dart';

/// The result returned after completing location selection.
class LocationResult {
  /// The human readable name of the location. This is primarily the
  /// name of the road. But in cases where the place was selected from Nearby
  /// places list, we use the <b>name</b> provided on the list item.
  String name; // or road
  //String country;

  /// The human readable locality of the location.
  String locality;

  /// Latitude/Longitude of the selected location.
  LatLng latLng;

  /// Formatted address suggested by Google
  String formattedAddress;

  String placeId;
}

/// Nearby place data will be deserialized into this model.
class NearbyPlace {
  /// The human-readable name of the location provided. This value is provided
  /// for [LocationResult.name] when the user selects this nearby place.
  String name;

  /// The icon identifying the kind of place provided. Eg. lodging, chapel,
  /// hospital, etc.
  String icon;

  // Latitude/Longitude of the provided location.
  LatLng latLng;
}

/// Autocomplete results item returned from Google will be deserialized
/// into this model.
class AutoCompleteItem {
  /// The id of the place. This helps to fetch the lat,lng of the place.
  String id;

  /// The text (name of place) displayed in the autocomplete suggestions list.
  String text;

  /// Assistive index to begin highlight of matched part of the [text] with
  /// the original query
  int offset;

  /// Length of matched part of the [text]
  int length;
}

/// Place picker widget made with map widget from
/// [google_maps_flutter](https://github.com/flutter/plugins/tree/master/packages/google_maps_flutter)
/// and other API calls to [Google Places API](https://developers.google.com/places/web-service/intro)
///
/// API key provided should have `Maps SDK for Android`, `Maps SDK for iOS`
/// and `Places API`  enabled for it
class PlaceChooser extends StatefulWidget {
  /// API key generated from Google Cloud Console. You can get an API key
  /// [here](https://cloud.google.com/maps-platform/)
  final String apiKey;

  PlaceChooser({this.apiKey = "AIzaSyDl0BvVSLYiwKZ3UPFWpe4dDAMNqmrtLvs"});

  @override
  State<StatefulWidget> createState() {
    return PlaceChooserState();
  }
}

/// Place picker state
class PlaceChooserState extends State<PlaceChooser> {
  /// Initial waiting location for the map before the current user location
  /// is fetched.
  static final LatLng initialTarget = LatLng(5.5911921, -0.3198162);

  final Completer<GoogleMapController> mapController = Completer();

  /// Indicator for the selected location
  final Set<Marker> markers = Set()
    ..add(
      Marker(
        position: initialTarget,
        markerId: MarkerId("selected-location"),
      ),
    );

  /// Result returned after user completes selection
  LocationResult locationResult;

  /// Overlay to display autocomplete suggestions
  OverlayEntry overlayEntry;

  List<NearbyPlace> nearbyPlaces = List();

  /// Session token required for autocomplete API call
  String sessionToken = getRandomId();

  GlobalKey appBarKey = GlobalKey();

  bool hasSearchTerm = false;

  String previousSearchTerm = '';

  // constructor
  PlaceChooserState();

  void onMapCreated(GoogleMapController controller) {
    this.mapController.complete(controller);
    moveToCurrentUserLocation();
  }

  @override
  void setState(fn) {
    if (this.mounted) {
      super.setState(fn);
    }
  }

  @override
  void dispose() {
    this.overlayEntry?.remove();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        key: this.appBarKey,
        title: SearchInput((it) {
          searchPlace(it);
        }),
        centerTitle: true,
        leading: null,
        automaticallyImplyLeading: false,
      ),
      backgroundColor: Colors.white,
      body: Column(
        children: <Widget>[
          Flexible(
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: initialTarget,
                zoom: 15,
              ),
              myLocationButtonEnabled: true,
              myLocationEnabled: true,
              onMapCreated: onMapCreated,
              onTap: (latLng) {
                clearOverlay();
                moveToLocation(latLng);
              },
              markers: markers,
            ),
          ),

          if (this.hasSearchTerm)
            SelectPlaceAction(getLocationName(), () {
              //print(this.locationResult.formattedAddress);
              Navigator.of(context).pop(this.locationResult);
            })

//          this.hasSearchTerm
//              ? SizedBox()
//              : Expanded(
//                  child: Column(
//                    crossAxisAlignment: CrossAxisAlignment.end,
//                    children: <Widget>[
//                      Padding(
//                        child: Text(
//                          "Nearby Places",
//                          style: textStyle(true, 16, black),
//                        ),
//                        padding: EdgeInsets.symmetric(
//                          horizontal: 24,
//                          vertical: 8,
//                        ),
//                      ),
//                      addLine(.5, black.withOpacity(.1), 20, 0, 20, 0),
//                      Expanded(
//                        child: ListView(
//                          children: this
//                              .nearbyPlaces
//                              .map((it) => NearbyPlaceItem(it, () {
//                                    print(it.name);
//                                    print(it.latLng.longitude);
//                                    print(it.latLng.latitude);
//                                    moveToLocation(it.latLng);
//                                  }))
//                              .toList(),
//                        ),
//                      ),
//                      SelectPlaceAction(getLocationName(), () {
//                        print(this.locationResult.formattedAddress);
//                        Navigator.of(context).pop(this.locationResult);
//                      }),
//                    ],
//                  ),
//                ),
        ],
      ),
    );
  }

  /// Hides the autocomplete overlay
  void clearOverlay() {
    if (this.overlayEntry != null) {
      this.overlayEntry.remove();
      this.overlayEntry = null;
    }
  }

  /// Begins the search process by displaying a "wait" overlay then
  /// proceeds to fetch the autocomplete list. The bottom "dialog"
  /// is hidden so as to give more room and better experience for the
  /// autocomplete list overlay.
  void searchPlace(String place) {
    // on keyboard dismissal, the search was being triggered again
    // this is to cap that.
    if (place == this.previousSearchTerm) {
      return;
    } else {
      previousSearchTerm = place;
    }

    if (context == null) {
      return;
    }

    clearOverlay();

    setState(() {
      hasSearchTerm = place.length > 0;
    });

    if (place.length < 1) {
      return;
    }

    final RenderBox renderBox = context.findRenderObject();
    Size size = renderBox.size;

    final RenderBox appBarBox =
        this.appBarKey.currentContext.findRenderObject();

    this.overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: appBarBox.size.height,
        width: size.width,
        child: Material(
          elevation: 1,
          child: Container(
            padding: EdgeInsets.symmetric(
              vertical: 16,
              horizontal: 24,
            ),
            color: Colors.white,
            child: Row(
              children: <Widget>[
                SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                  ),
                ),
                SizedBox(
                  width: 24,
                ),
                Expanded(
                  child: Text(
                    "Finding place...",
                    style: textStyle(true, 16, black),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(this.overlayEntry);

    autoCompleteSearch(place);
  }

  /// Fetches the place autocomplete list with the query [place].
  void autoCompleteSearch(String place) {
    place = place.replaceAll(" ", "+");
    var endpoint =
        "https://maps.googleapis.com/maps/api/place/autocomplete/json?" +
            "key=${widget.apiKey}&" +
            "input={$place}&sessiontoken=${this.sessionToken}";

    if (this.locationResult != null) {
      endpoint += "&location=${this.locationResult.latLng.latitude}," +
          "${this.locationResult.latLng.longitude}";
    }
    http.get(endpoint).then((response) {
      if (response.statusCode == 200) {
        Map<String, dynamic> data = jsonDecode(response.body);
        List<dynamic> predictions = data['predictions'];

        List<RichSuggestion> suggestions = [];

        if (predictions.isEmpty) {
          AutoCompleteItem aci = AutoCompleteItem();
          aci.text = "No result found";
          aci.offset = 0;
          aci.length = 0;

          suggestions.add(RichSuggestion(aci, () {}));
        } else {
          for (dynamic t in predictions) {
            AutoCompleteItem aci = AutoCompleteItem();
            //formatted_address
            print(t);
            aci.id = t['place_id'];
            aci.text = t['description'];
            //aci.text = t['description'];
            aci.offset = 0; //t['matched_substrings'][0]['offset'];
            aci.length = 0; //t['matched_substrings'][0]['length'];

            suggestions.add(RichSuggestion(aci, () {
              FocusScope.of(context).requestFocus(FocusNode());

              decodeAndSelectPlace(aci.id, aci.text);
            }));
          }
        }

        displayAutoCompleteSuggestions(suggestions);
      }
    }).catchError((error) {
      print(error);
    });
  }

  /// To navigate to the selected place from the autocomplete list to the map,
  /// the lat,lng is required. This method fetches the lat,lng of the place and
  /// proceeds to moving the map to that location.
  void decodeAndSelectPlace(String placeId, String description) {
    clearOverlay();

    String endpoint =
        "https://maps.googleapis.com/maps/api/place/details/json?key=${widget.apiKey}" +
            "&placeid=$placeId";

    http.get(endpoint).then((response) {
      if (response.statusCode == 200) {
        Map<String, dynamic> responseJson = jsonDecode(response.body);
        Map<String, dynamic> location =
            jsonDecode(response.body)['result']['geometry']['location'];

        LatLng latLng = LatLng(location['lat'], location['lng']);

        final result = responseJson['result'];
        String road = result['address_components'][0]['short_name'];
        String locality = result['address_components'][1]['short_name'];
        print("Result res $result");
        print("Result road $road");
        print("Result resp $responseJson");

        setState(() {
          this.locationResult = LocationResult();
          this.locationResult.name = description;
//          this.locationResult.name = result['formatted_address'];
          this.locationResult.locality = locality;
          this.locationResult.latLng = latLng;
          this.locationResult.formattedAddress = result['formatted_address'];
          this.locationResult.placeId = result['place_id'];
        });
        moveToLocation(latLng);
      }
    }).catchError((error) {
      print(error);
    });
  }

  /// Display autocomplete suggestions with the overlay.
  void displayAutoCompleteSuggestions(List<RichSuggestion> suggestions) {
    final RenderBox renderBox = context.findRenderObject();
    Size size = renderBox.size;

    final RenderBox appBarBox =
        this.appBarKey.currentContext.findRenderObject();

    clearOverlay();

    this.overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        width: size.width,
        top: appBarBox.size.height,
        child: Material(
          elevation: 1,
          color: Colors.white,
          child: Column(
            children: suggestions,
          ),
        ),
      ),
    );

    Overlay.of(context).insert(this.overlayEntry);
  }

  /// Utility function to get clean readable name of a location. First checks
  /// for a human-readable name from the nearby list. This helps in the cases
  /// that the user selects from the nearby list (and expects to see that as a
  /// result, instead of road name). If no name is found from the nearby list,
  /// then the road name returned is used instead.
  String getLocationName() {
    if (this.locationResult == null) {
      return "Unnamed location";
    }

    for (NearbyPlace np in this.nearbyPlaces) {
      if (np.latLng == this.locationResult.latLng &&
          np.name != this.locationResult.locality) {
        this.locationResult.name = np.name;
        return "${np.name}, ${this.locationResult.locality}";
      }
    }

    return "${this.locationResult.name}";
    return "${this.locationResult.name}, ${this.locationResult.locality}";
  }

  /// Moves the marker to the indicated lat,lng
  void setMarker(LatLng latLng) {
    // markers.clear();
    setState(() {
      markers.clear();
      markers.add(
        Marker(
            markerId: MarkerId("selected-location"),
            position: latLng,
            draggable: true,
            onDragEnd: (latLng) {
              reverseGeocodeLatLng(latLng);
            }),
      );
    });
  }

  /// Fetches and updates the nearby places to the provided lat,lng
  void getNearbyPlaces(LatLng latLng) {
    http
        .get("https://maps.googleapis.com/maps/api/place/nearbysearch/json?" +
            "key=${widget.apiKey}&" +
            "location=${latLng.latitude},${latLng.longitude}&radius=150")
        .then((response) {
      if (response.statusCode == 200) {
        this.nearbyPlaces.clear();
        for (Map<String, dynamic> item
            in jsonDecode(response.body)['results']) {
          NearbyPlace nearbyPlace = NearbyPlace();

          nearbyPlace.name = item['name'];
          nearbyPlace.icon = item['icon'];
          double latitude = item['geometry']['location']['lat'];
          double longitude = item['geometry']['location']['lng'];

          LatLng _latLng = LatLng(latitude, longitude);

          nearbyPlace.latLng = _latLng;

          this.nearbyPlaces.add(nearbyPlace);
        }
      }

      // to update the nearby places
      setState(() {
        // this is to require the result to show
        //this.hasSearchTerm = false;
      });
    }).catchError((error) {});
  }

  /// This method gets the human readable name of the location. Mostly appears
  /// to be the road name and the locality.
  void reverseGeocodeLatLng(LatLng latLng) {
    http
        .get("https://maps.googleapis.com/maps/api/geocode/json?" +
            "latlng=${latLng.latitude},${latLng.longitude}&" +
            "key=${widget.apiKey}")
        .then((response) {
      if (response.statusCode == 200) {
        Map<String, dynamic> responseJson = jsonDecode(response.body);

        print("Alternative resp $responseJson");

        final result = responseJson['results'][0];
        String road = result['address_components'][0]['short_name'];
        String locality = result['address_components'][1]['short_name'];

        setState(() {
          this.locationResult = LocationResult();
          this.locationResult.name = result['formatted_address'];
          this.locationResult.locality = locality;
          this.locationResult.latLng = latLng;
          this.locationResult.formattedAddress = result['formatted_address'];
          this.locationResult.placeId = result['place_id'];
        });
      }
    }).catchError((error) {
      print(error);
    });
  }

  /// Moves the camera to the provided location and updates other UI features to
  /// match the location.
  void moveToLocation(LatLng latLng) {
    this.mapController.future.then((controller) {
      controller.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: latLng,
            zoom: 15.0,
          ),
        ),
      );
    });

    setMarker(latLng);

    reverseGeocodeLatLng(latLng);

    getNearbyPlaces(latLng);
  }

  void moveToCurrentUserLocation() {
    var location = Location();
    location.getLocation().then((locationData) {
      LatLng target = LatLng(locationData.latitude, locationData.longitude);
      moveToLocation(target);
    }).catchError((error) {
      // TODO: Handle the exception here
      print(error);
    });
  }
}

/// Custom Search input field, showing the search and clear icons.
class SearchInput extends StatefulWidget {
  final ValueChanged<String> onSearchInput;

  SearchInput(this.onSearchInput);

  @override
  State<StatefulWidget> createState() {
    return SearchInputState();
  }
}

class SearchInputState extends State<SearchInput> {
  TextEditingController editController = TextEditingController();

  Timer debouncer;

  bool hasSearchEntry = false;

  SearchInputState();

  @override
  void initState() {
    super.initState();
    this.editController.addListener(this.onSearchInputChange);
  }

  @override
  void dispose() {
    this.editController.removeListener(this.onSearchInputChange);
    this.editController.dispose();

    super.dispose();
  }

  void onSearchInputChange() {
    if (this.editController.text.isEmpty) {
      this.debouncer?.cancel();
      widget.onSearchInput(this.editController.text);
      return;
    }

    if (this.debouncer?.isActive ?? false) {
      this.debouncer.cancel();
    }

    this.debouncer = Timer(Duration(milliseconds: 500), () {
      widget.onSearchInput(this.editController.text);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        BackButton(),
        Flexible(
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: 8,
            ),
            child: Row(
              children: <Widget>[
                Icon(
                  Icons.search,
                  color: Colors.black,
                ),
                SizedBox(
                  width: 8,
                ),
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: "Search place",
                      border: InputBorder.none,
                      hintStyle: textStyle(false, 18, black.withOpacity(.4)),
                    ),
                    controller: this.editController,
                    style: textStyle(false, 16, black),
                    onChanged: (value) {
                      setState(() {
                        this.hasSearchEntry = value.isNotEmpty;
                      });
                    },
                  ),
                ),
                SizedBox(
                  width: 8,
                ),
                this.hasSearchEntry
                    ? GestureDetector(
                        child: Icon(Icons.clear, color: black),
                        onTap: () {
                          this.editController.clear();
                          setState(() {
                            this.hasSearchEntry = false;
                          });
                        },
                      )
                    : SizedBox(),
              ],
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(25),
              color: white,
            ),
          ),
        ),
      ],
    );
  }
}

class SelectPlaceAction extends StatelessWidget {
  final String locationName;
  final VoidCallback onTap;

  SelectPlaceAction(this.locationName, this.onTap);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: plinkdColor,
      child: InkWell(
        onTap: () {
          this.onTap();
        },
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 16,
          ),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      locationName,
                      style: textStyle(true, 16, white),
                    ),
                    Text(
                      "Tap to select this location",
                      style: textStyle(false, 13, white.withOpacity(.5)),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward,
                color: white,
              )
            ],
          ),
        ),
      ),
    );
  }
}

class NearbyPlaceItem extends StatelessWidget {
  final NearbyPlace nearbyPlace;
  final VoidCallback onTap;

  NearbyPlaceItem(this.nearbyPlace, this.onTap);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: onTap,
        child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 16,
            ),
            child: Row(
              children: <Widget>[
                Image.network(
                  nearbyPlace.icon,
                  width: 16,
                ),
                SizedBox(
                  width: 24,
                ),
                Expanded(
                  child: Text(
                    "${nearbyPlace.name}",
                    style: textStyle(true, 16, black),
                  ),
                )
              ],
            )),
      ),
    );
  }
}

class RichSuggestion extends StatelessWidget {
  final VoidCallback onTap;
  final AutoCompleteItem autoCompleteItem;

  RichSuggestion(this.autoCompleteItem, this.onTap);

  @override
  Widget build(BuildContext context) {
    return Material(
      child: InkWell(
        child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 16,
            ),
            color: white,
            child: Row(
              children: <Widget>[
                Expanded(
                  child: RichText(
                    text: TextSpan(children: getStyledTexts(context)),
                  ),
                )
              ],
            )),
        onTap: this.onTap,
      ),
    );
  }

  List<TextSpan> getStyledTexts(BuildContext context) {
    final List<TextSpan> result = [];

    String startText =
        this.autoCompleteItem.text.substring(0, this.autoCompleteItem.offset);
    if (startText.isNotEmpty) {
      result.add(
        TextSpan(
          text: startText,
          style: textStyle(false, 15, black.withOpacity(.7)),
        ),
      );
    }

    String boldText = this.autoCompleteItem.text.substring(
        this.autoCompleteItem.offset,
        this.autoCompleteItem.offset + this.autoCompleteItem.length);

    result.add(TextSpan(
      text: boldText,
      style: textStyle(true, 15, black),
    ));

    String remainingText = this
        .autoCompleteItem
        .text
        .substring(this.autoCompleteItem.offset + this.autoCompleteItem.length);
    result.add(
      TextSpan(
        text: remainingText,
        style: textStyle(true, 15, black),
      ),
    );

    return result;
  }
}
