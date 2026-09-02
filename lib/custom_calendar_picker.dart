 import 'package:flutter/material.dart';

class CustomCalendarPicker extends StatefulWidget {
  final DateTime initialDate;
  final DateTime firstDate;
  final DateTime lastDate;
  final ValueChanged<DateTime> onDateSelected;
  final List<DateTime> recordedDates;

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

  // Stato delle festività (configurabili dal pulsante Festività)
  bool _festivitaattive = true;
  final Map<String, bool> _festeAbilitate = {
    'Capodanno': true,
    'Epifania': true,
    'Pasqua': true,
    'Pasquetta': true,
    'Liberazione': true,
    'Festa Lavoro': true,
    'Festa Repubblica': true,
    'Assunzione': true,
    'Tutti i Santi': true,
    'Immacolata': true,
    'Natale': true,
    'Santo Stefano': true,
  };
  bool _sabatoFestivo = false;
  bool _domenicaFestiva = true;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
    _displayedMonth = DateTime(_selectedDate.year, _selectedDate.month);
  }

  // Calcolo della data di Pasqua per un dato anno
  DateTime _calcolaPasqua(int year) {
    int a = year % 19;
    int b = year ~/ 100;
    int c = year % 100;
    int d = b ~/ 4;
    int e = b % 4;
    int f = (b + 8) ~/ 25;
    int g = (b - f + 1) ~/ 3;
    int h = (19 * a + b - d - g + 15) % 30;
    int i = c ~/ 4;
    int k = c % 4;
    int l = (32 + 2 * e + 2 * i - h - k) % 7;
    int m = (a + 11 * h + 22 * l) ~/ 451;
    int month = (h + l - 7 * m + 114) ~/ 31;
    int day = ((h + l - 7 * m + 114) % 31) + 1;
    return DateTime(year, month, day);
  }

  bool _isHoliday(DateTime date) {
    if (!_festivitaattive) return false;
    int day = date.day;
    int month = date.month;
    int year = date.year;

    if (_festeAbilitate['Capodanno']! && month == 1 && day == 1) return true;
    if (_festeAbilitate['Epifania']! && month == 1 && day == 6) return true;
    if (_festeAbilitate['Liberazione']! && month == 4 && day == 25) return true;
    if (_festeAbilitate['Festa Lavoro']! && month == 5 && day == 1) return true;
    if (_festeAbilitate['Festa Repubblica']! && month == 6 && day == 2) return true;
    if (_festeAbilitate['Assunzione']! && month == 8 && day == 15) return true;
    if (_festeAbilitate['Tutti i Santi']! && month == 11 && day == 1) return true;
    if (_festeAbilitate['Immacolata']! && month == 12 && day == 8) return true;
    if (_festeAbilitate['Natale']! && month == 12 && day == 25) return true;
    if (_festeAbilitate['Santo Stefano']! && month == 12 && day == 26) return true;

    DateTime pasqua = _calcolaPasqua(year);
    if (_festeAbilitate['Pasqua']! && date.year == pasqua.year && date.month == pasqua.month && date.day == pasqua.day) return true;

    DateTime pasquetta = pasqua.add(const Duration(days: 1));
    if (_festeAbilitate['Pasquetta']! && date.year == pasquetta.year && date.month == pasquetta.month && date.day == pasquetta.day) return true;

    return false;
  }

  bool _isRedDay(DateTime date) {
    if (_domenicaFestiva && date.weekday == DateTime.sunday) return true;
    if (_sabatoFestivo && date.weekday == DateTime.saturday) return true;
    return _isHoliday(date);
  }

  bool _hasData(DateTime date) {
    return widget.recordedDates.any((d) =>
        d.year == date.year && d.month == date.month && d.day == date.day);
  }

  // Calcolo del numero della settimana (ISO 8601)
  int _numeroSettimana(DateTime date) {
    DateTime firstDayOfYear = DateTime(date.year, 1, 1);
    int days = date.difference(firstDayOfYear).inDays;
    return ((days + firstDayOfYear.weekday - 1) ~/ 7) + 1;
  }

  void _apriGestioneFestivita() {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              title: const Text('Gestione Festività', style: TextStyle(fontWeight: FontWeight.bold)),
              content: SizedBox(
                width: 320,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ..._festeAbilitate.keys.map((festa) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  color: Colors.yellow.shade100,
                                  child: Text(festa, style: const TextStyle(fontWeight: FontWeight.w500)),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                flex: 2,
                                child: Container(
                                  alignment: Alignment.center,
                                  padding: const EdgeInsets.all(8),
                                  color: Colors.grey.shade200,
                                  child: Text(
                                    festa == 'Pasqua'
                                        ? '${_calcolaPasqua(_displayedMonth.year).day.toString().padLeft(2, '0')}/${_calcolaPasqua(_displayedMonth.year).month.toString().padLeft(2, '0')}'
                                        : festa == 'Pasquetta'
                                            ? '${_calcolaPasqua(_displayedMonth.year).add(const Duration(days: 1)).day.toString().padLeft(2, '0')}/${_calcolaPasqua(_displayedMonth.year).add(const Duration(days: 1)).month.toString().padLeft(2, '0')}'
                                            : _getFestaDataString(festa),
                                    style: const TextStyle(color: Colors.grey),
                                  ),
                                ),
                              ),
                              Checkbox(
                                value: _festeAbilitate[festa],
                                activeColor: Colors.green,
                                onChanged: (val) {
                                  setModalState(() {
                                    _festeAbilitate[festa] = val ?? true;
                                  });
                                  setState(() {});
                                },
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      const Divider(height: 20),
                      CheckboxListTile(
                        title: const Text('Sabato Festivo', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                        value: _sabatoFestivo,
                        activeColor: Colors.red,
                        onChanged: (val) {
                          setModalState(() => _sabatoFestivo = val ?? false);
                          setState(() {});
                        },
                      ),
                      CheckboxListTile(
                        title: const Text('Domeniche Festive', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        tileColor: Colors.red,
                        value: _domenicaFestiva,
                        activeColor: Colors.black,
                        onChanged: (val) {
                          setModalState(() => _domenicaFestiva = val ?? true);
                          setState(() {});
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Conferma Festività'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  String _getFestaDataString(String festa) {
    switch (festa) {
      case 'Capodanno': return '01/01';
      case 'Epifania': return '06/01';
      case 'Liberazione': return '25/04';
      case 'Festa Lavoro': return '01/05';
      case 'Festa Repubblica': return '02/06';
      case 'Assunzione': return '15/08';
      case 'Tutti i Santi': return '01/11';
      case 'Immacolata': return '08/12';
      case 'Natale': return '25/12';
      case 'Santo Stefano': return '26/12';
      default: return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    const mesiNomi = [
      'Gennaio', 'Febbraio', 'Marzo', 'Aprile', 'Maggio', 'Giugno',
      'Luglio', 'Agosto', 'Settembre', 'Ottobre', 'Novembre', 'Dicembre'
    ];

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      child: Container(
        width: 380,
        padding: const EdgeInsets.all(12),
        color: Colors.grey.shade200,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Riga superiore: Pulsante Festività + Frecce Mese + Frecce Anno
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                  ),
                  onPressed: _apriGestioneFestivita,
                  child: const Text('Festività', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_left, size: 28),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () {
                        setState(() {
                          _displayedMonth = DateTime(_displayedMonth.year, _displayedMonth.month - 1);
                        });
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.arrow_right, size: 28),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () {
                        setState(() {
                          _displayedMonth = DateTime(_displayedMonth.year, _displayedMonth.month + 1);
                        });
                      },
                    ),
                  ],
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_left, size: 28),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () {
                        setState(() {
                          _displayedMonth = DateTime(_displayedMonth.year - 1, _displayedMonth.month);
                        });
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.arrow_right, size: 28),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () {
                        setState(() {
                          _displayedMonth = DateTime(_displayedMonth.year + 1, _displayedMonth.month);
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Tendine Selezione Mese e Anno + Testo Mese Anno
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${mesiNomi[_displayedMonth.month - 1]} ${_displayedMonth.year}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  color: Colors.white,
                  child: DropdownButton<int>(
                    value: _displayedMonth.month,
                    underline: const SizedBox(),
                    items: List.generate(12, (index) {
                      return DropdownMenuItem(
                        value: index + 1,
                        child: Text(mesiNomi[index]),
                      );
                    }),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _displayedMonth = DateTime(_displayedMonth.year, val);
                        });
                      }
                    },
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  color: Colors.white,
                  child: DropdownButton<int>(
                    value: _displayedMonth.year,
                    underline: const SizedBox(),
                    items: List.generate(10, (index) {
                      int y = 2025 + index;
                      return DropdownMenuItem(
                        value: y,
                        child: Text('$y'),
                      );
                    }),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _displayedMonth = DateTime(val, _displayedMonth.month);
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
            const Divider(thickness: 2),

            // Tabella Calendario con colonna N.S. a sinistra
            _buildCalendarGridStyle(),
            const SizedBox(height: 10),

            // Pulsante Oggi in basso
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                ),
                onPressed: () {
                  setState(() {
                    DateTime now = DateTime.now();
                    _selectedDate = now;
                    _displayedMonth = DateTime(now.year, now.month);
                  });
                  widget.onDateSelected(_selectedDate);
                  Navigator.pop(context);
                },
                child: Text('Oggi: ${DateTime.now().day.toString().padLeft(2, '0')}/${DateTime.now().month.toString().padLeft(2, '0')}/${DateTime.now().year}', style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarGridStyle() {
    int year = _displayedMonth.year;
    int month = _displayedMonth.month;

    DateTime firstDayOfMonth = DateTime(year, month, 1);
    int weekdayOffset = firstDayOfMonth.weekday - 1; // 0 per Lunedì

    // Calcoliamo i giorni da mostrare in una griglia di 6 righe x 7 giorni
    List<Widget> rows = [];

    // Intestazione giorni settimana
    rows.add(
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Container(
            width: 32,
            alignment: Alignment.center,
            child: const Text('N.S.', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blue)),
          ),
          ...['LUN', 'MAR', 'MER', 'GIO', 'VEN', 'SAB', 'DOM'].asMap().entries.map((e) {
            bool isDom = e.key == 6;
            bool isSab = e.key == 5;
            return Container(
              width: 38,
              alignment: Alignment.center,
              child: Text(
                e.value,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isDom ? Colors.red : (isSab ? Colors.black87 : Colors.black87),
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
    rows.add(const SizedBox(height: 4));

    DateTime currentIterator = firstDayOfMonth.subtract(Duration(days: weekdayOffset));

    for (int week = 0; week < 6; week++) {
      int weekNum = _numeroSettimana(currentIterator);
      List<Widget> weekDays = [];

      // Colonna Settimana (N.S.)
      weekDays.appendIfCustom(
        Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          color: Colors.yellow,
          child: Text('$weekNum', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blue)),
        ),
      );

      for (int d = 0; d < 7; d++) {
        DateTime cellDate = currentIterator;
        bool isCurrentMonth = cellDate.month == month;
        bool isSelected = _selectedDate.year == cellDate.year &&
            _selectedDate.month == cellDate.month &&
            _selectedDate.day == cellDate.day;
        bool isRed = _isRedDay(cellDate);
        bool hasData = _hasData(cellDate);

        weekDays.add(
          GestureDetector(
            onTap: () {
              setState(() {
                _selectedDate = cellDate;
              });
              widget.onDateSelected(_selectedDate);
              Navigator.pop(context);
            },
            child: Container(
              width: 38,
              height: 32,
              alignment: Alignment.center,
              margin: const EdgeInsets.all(1),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF0B5335)
                    : (isRed ? Colors.red : Colors.grey.shade300),
                border: hasData && !isSelected ? Border.all(color: Colors.blue, width: 2) : null,
              ),
              child: Text(
                '${cellDate.day}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: isSelected
                      ? Colors.white
                      : (!isCurrentMonth
                          ? Colors.grey.shade500
                          : (isRed ? Colors.white : Colors.black87)),
                ),
              ),
            ),
          ),
        );
        currentIterator = currentIterator.add(const Duration(days: 1));
      }

      rows.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: weekDays,
          ),
        ),
      );
    }

    return Column(children: rows);
  }
}

extension on List<Widget> {
  void appendIfCustom(Widget widget) {
    add(widget);
  }
}