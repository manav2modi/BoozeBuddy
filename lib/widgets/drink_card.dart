// lib/widgets/drink_card.dart
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import '../models/drink.dart';

class DrinkCard extends StatelessWidget {
  final Drink drink;

  const DrinkCard({required this.drink});

  @override
  Widget build(BuildContext context) {
    final time = DateFormat.Hm().format(drink.dateTime);
    final typeName = drink.type
        .toString()
        .split('.')
        .last
        .replaceFirstMapped(RegExp(r'^.'), (m) => m[0]!.toUpperCase());

    return Container(
      padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: CupertinoColors.separator,
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          Text(drink.type.emoji, style: TextStyle(fontSize: 32)),
          SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('$typeName at $time',
                  style:
                  TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
              if (drink.cost != null) ...[
                SizedBox(height: 4),
                Text('Cost: \$${drink.cost!.toStringAsFixed(2)}',
                    style: TextStyle(
                        color: CupertinoColors.systemGrey, fontSize: 14)),
              ],
            ],
          ),
        ],
      ),
    );

  }
}