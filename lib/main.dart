import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:async';
import 'dart:convert';
import 'dart:core';
import 'package:http/http.dart' as http;

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    //material app widget
    return MaterialApp(
      title: 'Crypto Price List',
      theme: new ThemeData(primaryColor: Colors.white),
      home: CryptoList(),
    ); //use our widget instead of the text previously
  }
}

//creates a stateful widget (data inside will change once created)
class CryptoList extends StatefulWidget {
  @override
  CryptoListState createState() => CryptoListState();
}

class CryptoListState extends State<CryptoList> {
  List _cryptoList; //store cryptolist
  final _saved = Set<Map>(); //store favourited cryptos
  final _boldStyle =
      new TextStyle(fontWeight: FontWeight.bold); //bold text style to be reused
  bool _loading = false; //will be used later to control state
  final List<MaterialColor> _colors = [
    //to show different colors for different cryptos
    Colors.blue,
    Colors.indigo,
    Colors.lime,
    Colors.teal,
    Colors.cyan
  ];
  //this means that the function will be executed sometime in the future (in this case does not return data)
  Future<void> getCryptoPrices() async {
    //async to use await, which suspends the current function, while it does other stuff and resumes when data ready
    print('getting crypto prices'); //print
    String _apiURL =
        "https://api.coinmarketcap.com/v1/ticker/"; //url to get data
    setState(() {
      this._loading = true; //before calling the api, set the loading to true
    });
    http.Response response = await http.get(_apiURL); //waits for response
    setState(() {
      this._cryptoList =
          jsonDecode(response.body); //sets the state of our widget
      this._loading = false; //set the loading to false after we get a response
      print(_cryptoList); //prints the list
    });
    return;
  }

  //takes in an object and returns the price with 2 decimal places
  String cryptoPrice(Map crypto) {
    int decimals = 2;
    int fac = pow(10, decimals);
    double d = double.parse(crypto['price_usd']);
    return "\$" + (d = (d * fac).round() / fac).toString();
  }

  // takes in an object and color and returns a circle avatar with first letter and required color
  CircleAvatar _getLeadingWidget(String name, MaterialColor color) {
    return new CircleAvatar(
      backgroundColor: color,
      child: new Text(name[0]),
    );
  }

  _getMainBody() {
    if (_loading) {
      return new Center(
        child: new CircularProgressIndicator(),
      );
    } else {
      return new RefreshIndicator(
        child: _buildCryptoList(),
        onRefresh: getCryptoPrices,
      );
    }
  }

  @override
  void initState() {
    //override creation of state so that we can call our function
    super.initState();
    getCryptoPrices(); //this function is called which then sets the state of our app
  }

//build method
  @override
  Widget build(BuildContext context) {
    //Implements the basic Material Design visual layout structure.
    //This class provides APIs for showing drawers, snack bars, and bottom sheets.
    return Scaffold(
        appBar: AppBar(
          title: Text('CryptoList'),
          actions: <Widget>[
            // will be used to view favourites
            new IconButton(icon: const Icon(Icons.list), onPressed: _pushSaved),
          ],
        ),
        body: _getMainBody());
  }

  //called when the button is pressed to go to the next view
  void _pushSaved() {
    Navigator.of(context).push( //get the current navigator
      new MaterialPageRoute<void>( //A modal route that replaces the entire screen with a platform-adaptive transition.
        builder: (BuildContext context) {
          final Iterable<ListTile> tiles = _saved.map( //iterate through our saved cryptocurrencies sequentially
            (crypto) {
              return new ListTile( //same list tile as what we have shown in the previous page
                leading: _getLeadingWidget(crypto['name'], Colors.blue),
                title: Text(crypto['name']),
                subtitle: Text(
                  cryptoPrice(crypto),
                  style: _boldStyle,
                ),
              );
            },
          );
          final List<Widget> divided = ListTile.divideTiles( //divided tiles allows to insert the dividers for visually pleasing outcome
            context: context,
            tiles: tiles,
          ).toList();
          return new Scaffold( //return a new scaffold with a new appbar and listview as a body
            appBar: new AppBar(
              title: const Text('Saved Cryptos'),
            ),
            body: new ListView(children: divided),
          );
        },
      ),
    );
  }

  //widget that builds the list
  Widget _buildCryptoList() {
    return ListView.builder(
        itemCount: _cryptoList
            .length, //set the item count so that index won't be out of range
        padding:
            const EdgeInsets.all(16.0), //add some padding to make it look good
        itemBuilder: (context, i) {
          //item builder returns a row for each index i=0,1,2,3,4
          // if (i.isOdd) return Divider(); //if index = 1,3,5 ... return a divider to make it visually appealing

          // final index = i ~/ 2; //get the actual index excluding dividers.
          final index = i;
          print(index);
          final MaterialColor color = _colors[index %
              _colors.length]; //iterate through indexes and get the next colour
          return _buildRow(_cryptoList[index], color); //build the row widget
        });
  }

  Widget _buildRow(Map crypto, MaterialColor color) {
    // if _saved contains our crypto, return true
    final bool favourited = _saved.contains(crypto);

    // function to handle when heart icon is tapped
    void _fav() {
      setState(() {
        if (favourited) {
          //if it is favourited previously, remove it from the list
          _saved.remove(crypto);
        } else {
          _saved.add(crypto); //else add it to the array
        }
      });
    }

    // returns a row with the desired properties
    return ListTile(
      leading: _getLeadingWidget(crypto['name'],
          color), // get the first letter of each crypto with the color
      title: Text(crypto['name']), //title to be name of the crypto
      subtitle: Text(
        //subtitle is below title, get the price in 2 decimal places and set style to bold
        cryptoPrice(crypto),
        style: _boldStyle,
      ),
      trailing: new IconButton(
        //at the end of the row, add an icon button
        // Add the lines from here...
        icon: Icon(favourited
            ? Icons.favorite
            : Icons
                .favorite_border), // if button is favourited, show favourite icon
        color:
            favourited ? Colors.red : null, // if button is favourited, show red
        onPressed: _fav, //when pressed, let _fav function handle
      ),
    );
  }
}
