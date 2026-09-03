import 'package:flutter/material.dart';

class CustomCalendarPicker extends StatefulWidget {
  final DateTime initialDate;
  final DateTime firstDate;
  final DateTime lastDate;
  final List<DateTime> recordedDates;
  final ValueChanged<DateTime> onDateSelected;
  final ValueChanged<DateTime>? onDateUnselected;

  const CustomCalendarPicker({
    super.key,
    required this.initialDate,
    required this.firstDate,
    required this.lastDate,
    required this.recordedDates,
    required this.onDateSelected,
    this.onDateUnselected,
  });

  @override
  State<CustomCalendarPicker> createState() => _CustomCalendarPickerState();
}

class _CustomCalendarPickerState extends State<CustomCalendarPicker> {
  late DateTime _currentMonth;
  late DateTime _selectedDate;

  final List<String> _mesi = [
    'Gennaio', 'Febbraio', 'Marzo', 'Aprile', 'Maggio', 'Giugno',
    'Luglio', 'Agosto', 'Settembre', 'Ottobre', 'Novembre', 'Dicembre'
  ];

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
    _currentMonth = DateTime(widget.initialDate.year, widget.initialDate.month, 1);
  }

  void _cambiaMese(int delta) {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + delta, 1);
    });
  }

  bool _isDataRegistrata(DateTime d) {
    return widget.recordedDates.any((rd) => rd.year == d.year && rd.month == d.month && rd.day == d.day);
  }

  @override
  Widget build(BuildContext context) {
    const Color cislGreen = Color(0xFF0B5335);

    int daysInMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 0).day;
    int firstDayWeekday = DateTime(_currentMonth.year, _currentMonth.month, 1).weekday; // 1 = Lun, 7 = Dom

    List<Widget> dayWidgets = [];

    List<String> weekDays = ['L', 'M', 'M', 'G', 'V', 'S', 'D'];
    for (int i = 0; i < weekDays.length; i++) {
      bool isWeekendCol = (i >= 5);
      dayWidgets.add(
        Center(
          child: Text(
            weekDays[i],
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: isWeekendCol ? Colors.red.shade700 : Colors.grey.shade700,
            ),
          ),
        ),
      );
    }

    for (int i = 1; i < firstDayWeekday; i++) {
      dayWidgets.add(const SizedBox.shrink());
    }

    for (int day = 1; day <= daysInMonth; day++) {
      DateTime dateBox = DateTime(_currentMonth.year, _currentMonth.month, day);
      bool isSelected = (_selectedDate.year == dateBox.year && _selectedDate.month == dateBox.month && _selectedDate.day == dateBox.day);
      bool isRecorded = _isDataRegistrata(dateBox);
      bool isWeekend = (dateBox.weekday == DateTime.saturday || dateBox.weekday == DateTime.sunday);

      dayWidgets.add(
        GestureDetector(
          onTap: () {
            setState(() {
              _selectedDate = dateBox;
            });
            if (isRecorded && widget.onDateUnselected != null) {
              widget.onDateUnselected!(dateBox);
            } else {
              widget.onDateSelected(dateBox);
            }
            Navigator.pop(context);
          },
          child: Container(
            margin: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: isSelected
                  ? cislGreen
                  : isRecorded
                      ? cislGreen.withOpacity(0.15)
                      : Colors.transparent,
              shape: BoxShape.circle,
              border: isRecorded && !isSelected ? Border.all(color: cislGreen, width: 1.5) : null,
            ),
            child: Center(
              child: Text(
                '$day',
                style: TextStyle(
                  fontWeight: isSelected || isRecorded ? FontWeight.bold : FontWeight.normal,
                  color: isSelected
                      ? Colors.white
                      : isWeekend
                          ? Colors.red.shade700
                          : Colors.black87,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 6,
      child: Container(
        padding: const EdgeInsets.all(20),
        constraints: const BoxConstraints(maxWidth: 380),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left, color: cislGreen),
                  onPressed: () => _cambiaMese(-1),
                ),
                Text(
                  '${_mesi[_currentMonth.month - 1]} ${_currentMonth.year}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: cislGreen),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right, color: cislGreen),
                  onPressed: () => _cambiaMese(1),
                ),
              ],
            ),
            const Divider(height: 20),
            GridView.count(
              crossAxisCount: 7,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: dayWidgets,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Chiudi', style: TextStyle(color: Colors.grey)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}