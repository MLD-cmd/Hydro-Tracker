import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/drink_type.dart';
import '../models/water_entry.dart';
import '../theme/app_theme.dart';

/// The result of editing an entry: the new amount, drink type and timestamp.
class EntryEdit {
  const EntryEdit({
    required this.amountMl,
    required this.type,
    required this.timestamp,
  });

  final int amountMl;
  final String type;
  final DateTime timestamp;
}

/// A bottom sheet to edit a logged drink: amount (typed or ±50), drink type, and
/// the time of day. Returns an [EntryEdit], or null if dismissed.
Future<EntryEdit?> showEntryEditSheet(
  BuildContext context, {
  required WaterEntry entry,
  required List<DrinkType> drinkTypes,
}) {
  return showModalBottomSheet<EntryEdit>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => _EntryEditSheet(entry: entry, drinkTypes: drinkTypes),
  );
}

class _EntryEditSheet extends StatefulWidget {
  const _EntryEditSheet({required this.entry, required this.drinkTypes});

  final WaterEntry entry;
  final List<DrinkType> drinkTypes;

  @override
  State<_EntryEditSheet> createState() => _EntryEditSheetState();
}

class _EntryEditSheetState extends State<_EntryEditSheet> {
  static const int _min = 10;
  static const int _max = 3000;

  late int _amount = widget.entry.amountMl;
  late String _type = widget.entry.type;
  late TimeOfDay _time = TimeOfDay.fromDateTime(widget.entry.timestamp);
  late final TextEditingController _controller =
      TextEditingController(text: '${widget.entry.amountMl}');

  void _setAmount(int value) {
    final clamped = value.clamp(_min, _max);
    setState(() => _amount = clamped);
    _controller.text = '$clamped';
    _controller.selection =
        TextSelection.collapsed(offset: _controller.text.length);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _time);
    if (picked != null) setState(() => _time = picked);
  }

  @override
  Widget build(BuildContext context) {
    final original = widget.entry.timestamp;
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 10,
        bottom: 20 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 18),
              decoration: BoxDecoration(
                color: AppColors.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Text('Edit drink', style: AppTheme.headlineLg.copyWith(fontSize: 18)),
          const SizedBox(height: 20),
          // Amount
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: () => _setAmount(_amount - 50),
                icon: const Icon(Icons.remove_circle_outline_rounded),
                color: AppColors.primary,
              ),
              SizedBox(
                width: 110,
                child: TextField(
                  controller: _controller,
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(4),
                  ],
                  style: AppTheme.headlineLg.copyWith(fontSize: 30),
                  decoration: const InputDecoration(suffixText: ' ml'),
                  onChanged: (raw) {
                    final v = int.tryParse(raw);
                    if (v != null) setState(() => _amount = v.clamp(_min, _max));
                  },
                ),
              ),
              IconButton(
                onPressed: () => _setAmount(_amount + 50),
                icon: const Icon(Icons.add_circle_outline_rounded),
                color: AppColors.primary,
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Drink type
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              for (final t in widget.drinkTypes)
                ChoiceChip(
                  avatar: Icon(t.icon, size: 16, color: t.color),
                  label: Text(t.name),
                  selected: t.name == _type,
                  showCheckmark: false,
                  onSelected: (_) => setState(() => _type = t.name),
                ),
            ],
          ),
          const SizedBox(height: 16),
          // Time
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.schedule_rounded),
            title: const Text('Time'),
            trailing: Text(
              _time.format(context),
              style: AppTheme.labelBold.copyWith(fontSize: 15),
            ),
            onTap: _pickTime,
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 52,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: () {
                final newTimestamp = DateTime(
                  original.year,
                  original.month,
                  original.day,
                  _time.hour,
                  _time.minute,
                );
                Navigator.of(context).pop(EntryEdit(
                  amountMl: _amount.clamp(_min, _max),
                  type: _type,
                  timestamp: newTimestamp,
                ));
              },
              child: Text('Save changes', style: AppTheme.button),
            ),
          ),
        ],
      ),
    );
  }
}
