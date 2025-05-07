// lib/screens/add_drink_screen.dart
import 'package:flutter/cupertino.dart';
import 'package:uuid/uuid.dart';
import '../models/drink.dart';
import '../services/storage_service.dart';
import '../widgets/emoji_button.dart';

class AddDrinkScreen extends StatefulWidget {
  @override
  _AddDrinkScreenState createState() => _AddDrinkScreenState();
}

class _AddDrinkScreenState extends State {
  final storage = StorageService();
  DrinkType selected = DrinkType.beer;
  final costCtrl = TextEditingController();

  void _save() {
    final id = Uuid().v4();
    final dateTime = DateTime.now();
    final cost =
    costCtrl.text.isNotEmpty ? double.tryParse(costCtrl.text) : null;
    storage.addDrink(
        Drink(id: id, type: selected, dateTime: dateTime, cost: cost));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(middle: Text('Log a Drink')),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              Text('Select Drink Type', style: TextStyle(fontSize: 18)),
              SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: DrinkType.values.map((type) {
                  return EmojiButton(
                    type: type,
                    isSelected: selected == type,
                    onPressed: () => setState(() => selected = type),
                  );
                }).toList(),
              ),
              SizedBox(height: 20),
              CupertinoTextField(
                controller: costCtrl,
                keyboardType:
                TextInputType.numberWithOptions(decimal: true),
                placeholder: 'Cost (optional)',
                prefix: Text('\$'),
              ),
              Spacer(),
              CupertinoButton.filled(
                child: Text('Save Drink'),
                onPressed: _save,
                padding: EdgeInsets.symmetric(horizontal: 80, vertical: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}