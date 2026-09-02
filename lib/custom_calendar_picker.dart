import 'package:flutter/material.dart';

class CustomCalendarPicker extends StatefulWidget {
  final DateTime initialDate;
  final DateTime firstDate;
  final DateTime lastDate;
  final ValueChanged<DateTime> onDateSelected;
  final List<DateTime> recordedDates; // Date che contengono dati salvati

  const CustomCalendarPicker({
    Key? key,
    required this.initialDate,
    required this.firstDate,
    required this.lastDate,
    required this.onDateSelected,
    required this.recordedDates,
  }) : super(key: key);

  @override
  State<CustomCalendarPicker> createState() => _CustomCalendarPickerState();
}

class _CustomCalendarPickerState extends State<CustomCalendarPicker> {
  late DateTime _displayedMonth;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
    _displayedMonth = DateTime(_selectedDate.year, _selectedDate.month);
  }

  bool _isNationalHoliday(DateTime date) {
    int day = date.day;
    int month = date.month;

    if ((month == 1 && day == 1) ||
        (month == 1 && day == 6) ||
        (month == 4 && day == 25) ||
        (month == 5 && day == 1) ||
        (month == 6 && day == 2) ||
        (month == 8 && day == 15) ||
        (month == 11 && day == 1) ||
        (month == 12 && day == 8) ||
        (month == 12 && day == 25) ||
        (month == 12 && day == 26)) {
      return true;
    }
    return false;
  }

  bool _isWeekendOrHoliday(DateTime date) {
    if (date.weekday == DateTime.saturday || date.weekday == DateTime.sunday) {
      return true;
    }
    return _isNationalHoliday(date);
  }

  bool _hasData(DateTime date) {
    return widget.recordedDates.any((d) =>
        d.year == date.year && d.month == date.month && d.day == date.day);
  }

  @override
  Widget build(BuildContext context) {
    const months = [
      'Gennaio', 'Febbraio', 'Marzo', 'Aprile', 'Maggio', 'Giugno',
      'Luglio', 'Agosto', 'Settembre', 'Ottobre', 'Novembre', 'Dicembre'
    ];

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 360,
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () {
                    setState(() {
                      _displayedMonth = DateTime(_displayedMonth.year, _displayedMonth.month - 1);
                    });
                  },
                ),
                Text(
                  '${months[_displayedMonth.month - 1]} ${_displayedMonth.year}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () {
                    setState(() {
                      _displayedMonth = DateTime(_displayedMonth.year, _displayedMonth.month + 1);
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: ['L', 'M', 'M', 'G', 'V', 'S', 'D'].asMap().entries.map((entry) {
                int idx = entry.key;
                String dayStr = entry.value;
                bool isRed = (idx >= 5);
                return Text(
                  dayStr,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isRed ? Colors.red : Colors.grey[700],
                  ),
                );
              }).toList(),
            ),
            const Divider(height: 20),
            _buildCalendarGrid(),
            const SizedBox(height: 10),
            // Legenda
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(width: 10, height: 10, decoration: const BoxDecoration(color: Colors.blue, shape: BoxShape.circle)),
                const SizedBox(width: 5),
                const Text('Giorni con dati inseriti', style: TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 15),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Annulla', style: TextStyle(color: Colors.grey)),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0B5335),
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    widget.onDateSelected(_selectedDate);
                    Navigator.pop(context);
                  },
                  child: const Text('OK'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarGrid() {
    int year = _displayedMonth.year;
    int month = _displayedMonth.month;

    DateTime firstDayOfMonth = DateTime(year, month, 1);
    int weekdayOffset = firstDayOfMonth.weekday - 1;
    int daysInMonth = DateTime(year, month + 1, 0).day;

    List<Widget> dayWidgets = [];

    for (int i = 0; i < weekdayOffset; i++) {
      dayWidgets.add(const SizedBox());
    }

    for (int day = 1; day <= daysInMonth; day++) {
      DateTime currentDate = DateTime(year, month, day);
      bool isSelected = _selectedDate.year == currentDate.year &&
          _selectedDate.month == currentDate.month &&
          _selectedDate.day == currentDate.day;

      bool isRedDay = _isWeekendOrHoliday(currentDate);
      bool hasRecordedData = _hasData(currentDate);

      dayWidgets.add(
        GestureDetector(
          onTap: () {
            setState(() {
              _selectedDate = currentDate;
            });
          },
          child: Container(
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF0B5335) : Colors.transparent,
              shape: BoxShape.circle,
              border: hasRecordedData && !isSelected
                  ? Border.all(color: Colors.blue, width: 2)
                  : null,
            ),
            alignment: Alignment.center,
            child: Text(
              '$day',
              style: TextStyle(
                color: isSelected
                    ? Colors.white
                    : (isRedDay ? Colors.red : Colors.black87),
                fontWeight: isSelected || hasRecordedData || isRedDay
                    ? FontWeight.bold
                    : FontWeight.normal,
              ),
            ),
          ),
        ),
      );
    }

    return GridView.count(
      crossAxisCount: 7,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: dayWidgets,
    );
  }
}