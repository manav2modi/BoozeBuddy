// 2. Create an autocomplete TextField widget
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:sip_track/services/location_service.dart';

class LocationAutocompleteField extends StatefulWidget {
  final TextEditingController controller;
  final Color accentColor;

  const LocationAutocompleteField({
    Key? key,
    required this.controller,
    required this.accentColor,
  }) : super(key: key);

  @override
  State<LocationAutocompleteField> createState() => _LocationAutocompleteFieldState();
}

class _LocationAutocompleteFieldState extends State<LocationAutocompleteField> {
  final LocationService _locationService = LocationService();
  List<String> _suggestions = [];
  bool _showSuggestions = false;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        setState(() {
          _showSuggestions = false;
        });
      }
    });

    widget.controller.addListener(_onTextChanged);
  }

  void _onTextChanged() async {
    if (widget.controller.text.isNotEmpty) {
      final suggestions = await _locationService.getLocationSuggestions(widget.controller.text);
      setState(() {
        _suggestions = suggestions;
        _showSuggestions = suggestions.isNotEmpty;
      });
    } else {
      setState(() {
        _suggestions = [];
        _showSuggestions = false;
      });
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CupertinoTextField(
          controller: widget.controller,
          focusNode: _focusNode,
          placeholder: 'e.g. New York, Bar name, etc.',
          placeholderStyle: const TextStyle(
            color: Color(0xFF666666),
            decoration: TextDecoration.none,
          ),
          style: const TextStyle(
            color: Colors.white,
            decoration: TextDecoration.none,
          ),
          prefix: Padding(
            padding: const EdgeInsets.only(left: 12),
            child: Icon(
              CupertinoIcons.location,
              color: widget.accentColor,
              size: 20,
            ),
          ),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF2A2A2A),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: const Color(0xFF444444),
              width: 1,
            ),
          ),
          cursorColor: widget.accentColor,
          autocorrect: false,
          enableSuggestions: true,
        ),
        if (_showSuggestions)
          Container(
            margin: const EdgeInsets.only(top: 1),
            decoration: BoxDecoration(
              color: const Color(0xFF2A2A2A),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: const Color(0xFF444444),
                width: 1,
              ),
            ),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _suggestions.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () {
                    widget.controller.text = _suggestions[index];
                    setState(() {
                      _showSuggestions = false;
                    });
                    _focusNode.unfocus();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    child: Row(
                      children: [
                        const Icon(
                          CupertinoIcons.location_fill,
                          color: Color(0xFF888888),
                          size: 16,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          _suggestions[index],
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}