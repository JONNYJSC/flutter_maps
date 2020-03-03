import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_maps/api/nominatim.dart';
import 'package:flutter_maps/models/search_result.dart';

class Toolbar extends StatefulWidget {
  //Para busqueda de lugares
  final Function(SearchResult) onSearch;

  const Toolbar({Key key, @required this.onSearch}) : super(key: key);

  @override
  _ToolbarState createState() => _ToolbarState();
}

class _ToolbarState extends State<Toolbar> {
  var _query = '';
  final _nominatim = Nominatim();
  List<SearchResult> _items = List();
  final TextEditingController _textEditingController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _nominatim.onSearch = (List<SearchResult> data) {
      print('onSearch $data');
      setState(() {
        _items = data;
      });
    };
  }

  _onChanged(String text) async {
    _query = text;
    setState(() {});

    if (_query.trim().length > 0) {
      setState(() {
        _items.clear();
      });
      await _nominatim.search(_query);
    }
  }

  @override
  void dispose() {
    _nominatim.dispose();
    _textEditingController.dispose();
    super.dispose();
  }

  _clear() {
    setState(() {
      _query = '';
      _items.clear();
    });
    _textEditingController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final isNotEmpty = _query.trim().length > 0;
    return Positioned(
      left: 10,
      right: 10,
      top: 10,
      bottom: 10,
      child: SafeArea(
          child: Column(
        children: <Widget>[
          Container(
            // height: 50,
            decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(10)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Expanded(
                    child: CupertinoTextField(
                  controller: _textEditingController,
                  placeholder: "Search ...",
                  onChanged: _onChanged,
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  style: TextStyle(color: Colors.black),
                  decoration: BoxDecoration(color: Colors.transparent),
                  suffix: isNotEmpty
                      ? CupertinoButton(
                          onPressed: _clear, child: Icon(Icons.clear))
                      : null,
                )),
                CupertinoButton(
                    padding: EdgeInsets.all(10),
                    child: Icon(Icons.gps_fixed, color: Colors.blue),
                    onPressed: () {})
              ],
            ),
          ),
          SizedBox(
            height: 10,
          ),
          isNotEmpty
              ? Expanded(
                  child: Container(
                    child: ListView.builder(
                      itemCount: _items.length,
                      itemBuilder: (context, index) {
                        final item = _items[index];
                        return CupertinoButton(
                          onPressed: () {
                            widget.onSearch(item);
                            _clear();
                          },
                          child: Text(
                            item.displayName,
                            style: TextStyle(color: Colors.black, fontSize: 15),
                          ),
                        );
                      },
                    ),
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10)),
                  ),
                )
              : Container()
        ],
      )),
    );
  }
}
