// lib/widgets/location_widget.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:sip_track/services/location_service.dart';
import 'package:sip_track/utils/theme.dart';

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
  final FocusNode _focusNode = FocusNode();
  bool _isLoadingSuggestions = false;

  @override
  void initState() {
    super.initState();

    // Add listener to focus node to save location when focus is lost
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        _saveLocationIfNeeded();
      }
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  // Save location when focus is lost if there's text in the field
  Future<void> _saveLocationIfNeeded() async {
    final text = widget.controller.text.trim();
    if (text.isNotEmpty) {
      await _locationService.saveLocation(text);
    }
  }

  @override
  Widget build(BuildContext context) {
    return RawAutocomplete<String>(
      focusNode: _focusNode,
      textEditingController: widget.controller,
      optionsBuilder: (TextEditingValue textEditingValue) async {
        if (textEditingValue.text.isEmpty) {
          return const Iterable<String>.empty();
        }

        setState(() {
          _isLoadingSuggestions = true;
        });

        final suggestions = await _locationService.getLocationSuggestions(textEditingValue.text);

        setState(() {
          _isLoadingSuggestions = false;
        });

        return suggestions;
      },
      optionsViewBuilder: (context, onSelected, options) {
        if (_isLoadingSuggestions) {
          return Align(
            alignment: Alignment.topLeft,
            child: Material(
              elevation: 4.0,
              color: AppTheme.cardColor,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                height: 100,
                width: 300,
                padding: const EdgeInsets.all(8),
                child: const Center(
                  child: CupertinoActivityIndicator(),
                ),
              ),
            ),
          );
        }

        if (options.isEmpty) {
          return Container();
        }

        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4.0,
            color: AppTheme.cardColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: const BorderSide(color: Color(0xFF444444)),
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: 200,
                maxWidth: MediaQuery.of(context).size.width - 32, // Account for padding
              ),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: options.length,
                itemBuilder: (BuildContext context, int index) {
                  final option = options.elementAt(index);
                  return InkWell(
                    onTap: () {
                      onSelected(option);
                      // No need to explicitly save here as it will be saved
                      // when focus is lost or when submitted
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        children: [
                          const Icon(
                            CupertinoIcons.location_fill,
                            color: Color(0xFF888888),
                            size: 16,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              option,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
      fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
        return CupertinoTextField(
          controller: textEditingController,
          focusNode: focusNode,
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
          onSubmitted: (String value) {
            _saveLocationIfNeeded();
            onFieldSubmitted();
          },
        );
      },
    );
  }
}