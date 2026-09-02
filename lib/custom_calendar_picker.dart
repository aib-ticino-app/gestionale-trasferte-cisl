import 'package:flutter/material.dart';

class CustomCalendarPicker extends StatefulWidget {
  final DateTime initialDate;
  final DateTime firstDate;
  final DateTime lastDate;
  final ValueChanged<DateTime> onDateSelected;

  const CustomCalendarPicker({
    Key? key,
    required this.initialDate,
    required this.firstDate,
    required this.lastDate,
    required this.onDateSelected,
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

  // Lista delle feste nazionali italiane fisse
  bool _isNationalHoliday(DateTime date) {
    int day = date.day;
    int month = date.month;

    if ((month == 1 && day == 1) ||   // Capodanno
        (month == 1 && day == 6) ||   // Epifania
        (month == 4 && day == 25) ||  // Festa della Liberazione
        (month == 5 && day == 1) ||   // Festa dei Lavoratori
        (month == 6 && day == 2) ||   // Festa della Repubblica
        (month == 8 && day == 15) ||  // Ferragosto
        (month == 11 && day == 1) ||  // Ognissanti
        (month == 12 && day == 8) ||  // Immacolata Concezione
        (month == 12 && day == 25) || // Natale
        (month == 12 && day == 26)) { // Santo Stefano
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
            const SizedBox(height: 20),
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
                    backgroundColor: Colors.green[800],
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

      dayWidgets.add(
        GestureDetector(
          onTap: () {
            setState(() {
              _selectedDate = currentDate;
            });
          },
          child: Container(
            decoration: BoxDecoration(
              color: isSelected ? Colors.green[800] : Colors.transparent,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              '$day',
              style: TextStyle(
                color: isSelected
                    ? Colors.white
                    : (isRedDay ? Colors.red : Colors.black87),
                fontWeight: isSelected || isRedDay ? FontWeight.bold : FontWeight.normal,
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