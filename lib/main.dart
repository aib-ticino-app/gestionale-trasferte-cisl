import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:http/http.dart' as http;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'custom_calendar_picker.dart';

void main() {
  runApp(const GestionaleSindacatoApp());
}

class GestionaleSindacatoApp extends StatelessWidget {
  const GestionaleSindacatoApp({super.key});

  @override
  Widget build(BuildContext context) {
    const Color cislGreen = Color(0xFF0B5335);

    return MaterialApp(
      title: 'Gestionale Trasferte CISL FP',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: cislGreen,
          primary: cislGreen,
        ),
        useMaterial3: true,
      ),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('it', 'IT'),
      ],
      locale: const Locale('it', 'IT'),
      home: const SchermataGiornalieraPage(),
    );
  }
}

class Coord {
  final double lat;
  final double lon;
  Coord(this.lat, this.lon);
}

class TrattaViaggio {
  final TextEditingController partenzaController = TextEditingController();
  final TextEditingController arrivoController = TextEditingController();
  final TextEditingController kmController = TextEditingController();
  bool isAndataRitorno = false;
  double kmSolaAndata = 0.0;
  double rimborsoTratta = 0.0;
}

class GiornataSalvata {
  final DateTime data;
  final String stato;
  final String modelloAuto;
  final String targa;
  final double rimborsoAci;
  final double speseExtra;
  final double totale;
  final String attivita;

  GiornataSalvata({
    required this.data,
    required this.stato,
    required this.modelloAuto,
    required this.targa,
    required this.rimborsoAci,
    required this.speseExtra,
    required this.totale,
    required this.attivita,
  });
}

class SchermataGiornalieraPage extends StatefulWidget {
  const SchermataGiornalieraPage({super.key});

  @override
  State<SchermataGiornalieraPage> createState() => _SchermataGiornalieraPageState();
}

class _SchermataGiornalieraPageState extends State<SchermataGiornalieraPage> {
  String _statoGiornata = 'Lavorativa';
  DateTime _dataSelezionata = DateTime.now();

  final TextEditingController _modelloAutoController = TextEditingController();
  final TextEditingController _targaController = TextEditingController();
  String _alimentazioneSelezionata = 'Gasolio (Diesel)';
  double _costoAciKm = 0.45;

  final List<TrattaViaggio> _tratte = [TrattaViaggio()];

  final TextEditingController _parcheggioController = TextEditingController();
  final TextEditingController _pedaggioController = TextEditingController();
  final TextEditingController _pastoController = TextEditingController();
  final TextEditingController _mezziController = TextEditingController();
  final TextEditingController _agendaController = TextEditingController();

  double _rimborsoAciTotale = 0.0;
  double _speseExtraTotali = 0.0;
  double _totaleGiornaliero = 0.0;

  final List<GiornataSalvata> _archivioGiornate = [];

  @override
  void initState() {
    super.initState();
    _aggiornaAscoltatoriTratta(_tratte[0]);
    _parcheggioController.addListener(_calcolaTotali);
    _pedaggioController.addListener(_calcolaTotali);
    _pastoController.addListener(_calcolaTotali);
    _mezziController.addListener(_calcolaTotali);
  }

  void _aggiornaAscoltatoriTratta(TrattaViaggio tratta) {
    tratta.kmController.addListener(_calcolaTotali);
  }

  Future<void> _selezionaData(BuildContext context) async {
    showDialog(
      context: context,
      builder: (context) => CustomCalendarPicker(
        initialDate: _dataSelezionata,
        firstDate: DateTime(2025, 1, 1),
        lastDate: DateTime(2030, 12, 31),
        onDateSelected: (DateTime newDate) {
          setState(() {
            _dataSelezionata = newDate;
          });
        },
      ),
    );
  }

  Future<void> _calcolaKmOSRM(TrattaViaggio tratta) async {
    String partenza = tratta.partenzaController.text.trim();
    String arrivo = tratta.arrivoController.text.trim();

    if (partenza.isEmpty || arrivo.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Inserisci partenza e arrivo per calcolare i km.')),
      );
      return;
    }

    try {
      Coord? p1 = await _getCoordinateDaIndirizzo(partenza);
      Coord? p2 = await _getCoordinateDaIndirizzo(arrivo);

      if (p1 != null && p2 != null) {
        final url = Uri.parse('https://router.project-osrm.org/route/v1/driving/${p1.lon},${p1.lat};${p2.lon},${p2.lat}?overview=false');
        final response = await http.get(url);

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data['routes'] != null && data['routes'].isNotEmpty) {
            double metri = data['routes'][0]['distance'].toDouble();
            double kmReali = metri / 1000.0;

            setState(() {
              tratta.kmSolaAndata = kmReali;
              double kmFinali = tratta.isAndataRitorno ? kmReali * 2 : kmReali;
              tratta.kmController.text = kmFinali.toStringAsFixed(1);
              _calcolaTotali();
            });

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Tratta calcolata: ${tratta.kmController.text} km (${tratta.isAndataRitorno ? "A/R" : "Solo Andata"})')),
            );
          }
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Indirizzo non trovato.')),
        );
      }
    } catch (e) {
      print('Errore: $e');
    }
  }

  void _toggleAndataRitorno(TrattaViaggio tratta, bool? value) {
    setState(() {
      tratta.isAndataRitorno = value ?? false;
      if (tratta.kmSolaAndata > 0) {
        double kmFinali = tratta.isAndataRitorno ? tratta.kmSolaAndata * 2 : tratta.kmSolaAndata;
        tratta.kmController.text = kmFinali.toStringAsFixed(1);
      }
      _calcolaTotali();
    });
  }

  Future<Coord?> _getCoordinateDaIndirizzo(String indirizzo) async {
    final url = Uri.parse('https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(indirizzo)}&format=json&limit=1');
    final response = await http.get(url, headers: {'User-Agent': 'GestionaleSindacatoApp'});
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data.isNotEmpty) {
        return Coord(double.parse(data[0]['lat']), double.parse(data[0]['lon']));
      }
    }
    return null;
  }

  void _aggiungiTratta() {
    setState(() {
      final nuovaTratta = TrattaViaggio();
      _aggiornaAscoltatoriTratta(nuovaTratta);
      _tratte.add(nuovaTratta);
    });
  }

  void _rimuoviTratta(int index) {
    setState(() {
      _tratte[index].partenzaController.dispose();
      _tratte[index].arrivoController.dispose();
      _tratte[index].kmController.dispose();
      _tratte.removeAt(index);
      _calcolaTotali();
    });
  }

  void _calcolaTotali() {
    if (_statoGiornata != 'Lavorativa') return;

    double kmTotali = 0.0;
    for (var tratta in _tratte) {
      double km = double.tryParse(tratta.kmController.text.replaceAll(',', '.')) ?? 0.0;
      tratta.rimborsoTratta = km * _costoAciKm;
      kmTotali += km;
    }

    double parcheggio = double.tryParse(_parcheggioController.text.replaceAll(',', '.')) ?? 0.0;
    double pedaggio = double.tryParse(_pedaggioController.text.replaceAll(',', '.')) ?? 0.0;
    double pasto = double.tryParse(_pastoController.text.replaceAll(',', '.')) ?? 0.0;
    double mezzi = double.tryParse(_mezziController.text.replaceAll(',', '.')) ?? 0.0;

    setState(() {
      _rimborsoAciTotale = kmTotali * _costoAciKm;
      _speseExtraTotali = parcheggio + pedaggio + pasto + mezzi;
      _totaleGiornaliero = _rimborsoAciTotale + _speseExtraTotali;
    });
  }

  void _azzeraCampiLavorativi() {
    _modelloAutoController.clear();
    _targaController.clear();
    for (var t in _tratte) {
      t.partenzaController.clear();
      t.arrivoController.clear();
      t.kmController.clear();
      t.isAndataRitorno = false;
    }
    _parcheggioController.clear();
    _pedaggioController.clear();
    _pastoController.clear();
    _mezziController.clear();
    _agendaController.clear();
    _totaleGiornaliero = 0.0;
    _rimborsoAciTotale = 0.0;
    _speseExtraTotali = 0.0;
  }

  void _aggiornaCostoAci(String? alimentazione) {
    setState(() {
      _alimentazioneSelezionata = alimentazione ?? 'Gasolio (Diesel)';
      if (_alimentazioneSelezionata == 'Benzina') {
        _costoAciKm = 0.48;
      } else if (_alimentazioneSelezionata == 'Gasolio (Diesel)') {
        _costoAciKm = 0.45;
      } else if (_alimentazioneSelezionata == 'Ibrida / Elettrica') {
        _costoAciKm = 0.40;
      } else {
        _costoAciKm = 0.42;
      }
      _calcolaTotali();
    });
  }

  void _salvaGiornataCorrente() {
    _archivioGiornate.removeWhere((g) => g.data.year == _dataSelezionata.year && g.data.month == _dataSelezionata.month && g.data.day == _dataSelezionata.day);

    _archivioGiornate.add(
      GiornataSalvata(
        data: _dataSelezionata,
        stato: _statoGiornata,
        modelloAuto: _modelloAutoController.text,
        targa: _targaController.text,
        rimborsoAci: _rimborsoAciTotale,
        speseExtra: _speseExtraTotali,
        totale: _totaleGiornaliero,
        attivita: _agendaController.text,
      ),
    );

    String dataStr = '${_dataSelezionata.day}/${_dataSelezionata.month}/${_dataSelezionata.year}';
    String msg = _statoGiornata != 'Lavorativa'
        ? 'Giornata del $dataStr salvata come: $_statoGiornata'
        : 'Giornata del $dataStr salvata con successo! Totale: € ${_totaleGiornaliero.toStringAsFixed(2)}';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  Future<void> _stampaPdfRiepilogo(String tipoPeriodo) async {
    final pdf = pw.Document();

    List<GiornataSalvata> giornateFiltrate = [];
    String periodoTesto = '';

    if (tipoPeriodo == 'Giornaliero') {
      periodoTesto = 'Data: ${_dataSelezionata.day}/${_dataSelezionata.month}/${_dataSelezionata.year}';
      giornateFiltrate = _archivioGiornate.where((g) => g.data.year == _dataSelezionata.year && g.data.month == _dataSelezionata.month && g.data.day == _dataSelezionata.day).toList();
      
      if (giornateFiltrate.isEmpty) {
        giornateFiltrate.add(GiornataSalvata(
          data: _dataSelezionata,
          stato: _statoGiornata,
          modelloAuto: _modelloAutoController.text,
          targa: _targaController.text,
          rimborsoAci: _rimborsoAciTotale,
          speseExtra: _speseExtraTotali,
          totale: _totaleGiornaliero,
          attivita: _agendaController.text,
        ));
      }
    } else if (tipoPeriodo == 'Settimanale') {
      DateTime inizioSettimana = _dataSelezionata.subtract(Duration(days: _dataSelezionata.weekday - 1));
      DateTime fineSettimana = inizioSettimana.add(const Duration(days: 6));
      periodoTesto = 'Periodo: Dal ${inizioSettimana.day}/${inizioSettimana.month}/${inizioSettimana.year} al ${fineSettimana.day}/${fineSettimana.month}/${fineSettimana.year}';

      giornateFiltrate = _archivioGiornate.where((g) {
        return g.data.isAfter(inizioSettimana.subtract(const Duration(days: 1))) && g.data.isBefore(fineSettimana.add(const Duration(days: 1)));
      }).toList();
    } else if (tipoPeriodo == 'Mensile') {
      periodoTesto = 'Mese di Riferimento: ${_dataSelezionata.month}/${_dataSelezionata.year}';

      giornateFiltrate = _archivioGiornate.where((g) {
        return g.data.year == _dataSelezionata.year && g.data.month == _dataSelezionata.month;
      }).toList();
    }

    double totaleAciPeriodo = giornateFiltrate.fold(0.0, (sum, item) => sum + item.rimborsoAci);
    double totaleExtraPeriodo = giornateFiltrate.fold(0.0, (sum, item) => sum + item.speseExtra);
    double totaleComplessivoPeriodo = giornateFiltrate.fold(0.0, (sum, item) => sum + item.totale);

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('CISL FP DEI LAGHI', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
                  pw.Text('Riepilogo $tipoPeriodo', style: pw.TextStyle(fontSize: 16)),
                ],
              ),
              pw.Divider(thickness: 2),
              pw.SizedBox(height: 10),
              pw.Text(periodoTesto, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              
              if (tipoPeriodo == 'Giornaliero') ...[
                if (giornateFiltrate.isNotEmpty) ...[
                  pw.Text('Stato Giornata: ${giornateFiltrate.first.stato}', style: const pw.TextStyle(fontSize: 12)),
                  pw.Text('Dati Veicolo: ${giornateFiltrate.first.modelloAuto} (Targa: ${giornateFiltrate.first.targa})', style: const pw.TextStyle(fontSize: 12)),
                  pw.Text('Alimentazione: $_alimentazioneSelezionata (${_costoAciKm.toStringAsFixed(2)} EUR/km)', style: const pw.TextStyle(fontSize: 12)),
                  pw.SizedBox(height: 15),
                  pw.Text('Dettaglio Economico:', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                  pw.Bullet(text: 'Rimborso Chilometrico ACI: EUR ${giornateFiltrate.first.rimborsoAci.toStringAsFixed(2)}'),
                  pw.Bullet(text: 'Spese Extra (Parcheggi, Pedaggi, Pasti, Mezzi): EUR ${giornateFiltrate.first.speseExtra.toStringAsFixed(2)}'),
                  pw.SizedBox(height: 15),
                  pw.Text('Attività Svolte:', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                  pw.Paragraph(text: giornateFiltrate.first.attivita.isEmpty ? 'Nessuna attività registrata.' : giornateFiltrate.first.attivita),
                ],
              ] else ...[
                pw.SizedBox(height: 10),
                pw.Text('Elenco Giornate Registrate nel Periodo:', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 8),
                giornateFiltrate.isEmpty
                    ? pw.Paragraph(text: 'Nessuna giornata registrata in questo periodo. Ricordati di cliccare "Salva Giornata" dopo aver compilato i dati.')
                    : pw.Table(
                        border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
                        children: [
                          pw.TableRow(
                            decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                            children: [
                              pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Data', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10))),
                              pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Stato', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10))),
                              pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Rimborso ACI', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10))),
                              pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Spese Extra', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10))),
                              pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Totale', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10))),
                            ],
                          ),
                          ...giornateFiltrate.map((g) => pw.TableRow(
                                children: [
                                  pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('${g.data.day}/${g.data.month}/${g.data.year}', style: const pw.TextStyle(fontSize: 10))),
                                  pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(g.stato, style: const pw.TextStyle(fontSize: 10))),
                                  pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('EUR ${g.rimborsoAci.toStringAsFixed(2)}', style: const pw.TextStyle(fontSize: 10))),
                                  pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('EUR ${g.speseExtra.toStringAsFixed(2)}', style: const pw.TextStyle(fontSize: 10))),
                                  pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('EUR ${g.totale.toStringAsFixed(2)}', style: const pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold))),
                                ],
                              )),
                        ],
                      ),
                pw.SizedBox(height: 15),
                pw.Bullet(text: 'Totale Rimborsi Chilometrici ACI nel Periodo: EUR ${totaleAciPeriodo.toStringAsFixed(2)}'),
                pw.Bullet(text: 'Totale Spese Extra nel Periodo: EUR ${totaleExtraPeriodo.toStringAsFixed(2)}'),
              ],

              pw.SizedBox(height: 25),
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                color: PdfColors.grey200,
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('TOTALE COMPLESSIVO PERIODALE:', style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
                    pw.Text('EUR ${totaleComplessivoPeriodo.toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold)),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
    );
  }

  @override
  void dispose() {
    _modelloAutoController.dispose();
    _targaController.dispose();
    for (var t in _tratte) {
      t.partenzaController.dispose();
      t.arrivoController.dispose();
      t.kmController.dispose();
    }
    _parcheggioController.dispose();
    _pedaggioController.dispose();
    _pastoController.dispose();
    _mezziController.dispose();
    _agendaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool isNonLavorativo = _statoGiornata != 'Lavorativa';
    const Color cislGreen = Color(0xFF0B5335);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset(
              'assets/logo_cisl.png',
              width: 32,
              height: 32,
              errorBuilder: (context, error, stackTrace) => const Icon(Icons.shield, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 10),
            const Text('CISL FP - Gestione Trasferte', style: TextStyle(color: Colors.white, fontSize: 18)),
          ],
        ),
        backgroundColor: cislGreen,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Data: ${_dataSelezionata.day}/${_dataSelezionata.month}/${_dataSelezionata.year}',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: cislGreen.withOpacity(0.1),
                            foregroundColor: cislGreen,
                            elevation: 0,
                          ),
                          onPressed: () => _selezionaData(context),
                          icon: const Icon(Icons.calendar_today, size: 18),
                          label: const Text('Cambia Data'),
                        ),
                      ],
                    ),
                    const Divider(height: 20),
                    DropdownButtonFormField<String>(
                      value: _statoGiornata,
                      decoration: const InputDecoration(
                        labelText: 'Tipologia Giornata',
                        border: OutlineInputBorder(),
                        isDense: true,
                        prefixIcon: Icon(Icons.event_note),
                      ),
                      items: <String>['Lavorativa', 'Ferie', 'Malattia', 'Assenza / Permesso']
                          .map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: value == 'Lavorativa' ? cislGreen : Colors.red.shade700)),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _statoGiornata = newValue ?? 'Lavorativa';
                          if (_statoGiornata != 'Lavorativa') {
                            _azzeraCampiLavorativi();
                          }
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            if (isNonLavorativo)
              Container(
                padding: const EdgeInsets.all(12),
                color: Colors.orange.shade50,
                child: Row(
                  children: [
                    const Icon(Icons.info, color: Colors.orange),
                    const SizedBox(width: 8),
                    Text(
                      'Giornata registrata come: $_statoGiornata. Nessuna spesa o rimborso calcolabile.',
                      style: TextStyle(color: Colors.orange.shade900, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 16),

            Text('Dati Autoveicolo e Tariffa ACI', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: cislGreen)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _modelloAutoController,
                    enabled: !isNonLavorativo,
                    decoration: const InputDecoration(labelText: 'Modello Auto (es. Fiat Tipo)', border: OutlineInputBorder(), prefixIcon: Icon(Icons.directions_car)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 1,
                  child: TextField(
                    controller: _targaController,
                    enabled: !isNonLavorativo,
                    decoration: const InputDecoration(labelText: 'Targa', border: OutlineInputBorder(), prefixIcon: Icon(Icons.badge)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: _alimentazioneSelezionata,
              decoration: const InputDecoration(
                labelText: 'Alimentazione Veicolo (Tabella ACI)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.local_gas_station),
              ),
              items: <String>['Benzina', 'Gasolio (Diesel)', 'GPL / Metano', 'Ibrida / Elettrica']
                  .map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: isNonLavorativo ? null : _aggiornaCostoAci,
            ),
            Padding(
              padding: const EdgeInsets.only(top: 4, left: 4),
              child: Text(
                'Costo chilometrico applicato: ${_costoAciKm.toStringAsFixed(2)} €/km',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade700, fontStyle: FontStyle.italic),
              ),
            ),
            const SizedBox(height: 20),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Tratte e Percorrenza', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: cislGreen)),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: cislGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  onPressed: isNonLavorativo ? null : _aggiungiTratta,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Aggiungi Tratta'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _tratte.length,
              itemBuilder: (context, index) {
                final tratta = _tratte[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  elevation: 1,
                  child: Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Text('Tratta #${index + 1}', style: TextStyle(fontWeight: FontWeight.bold, color: cislGreen)),
                            const Spacer(),
                            if (_tratte.length > 1)
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                                onPressed: isNonLavorativo ? null : () => _rimuoviTratta(index),
                              ),
                          ],
                        ),
                        TextField(
                          controller: tratta.partenzaController,
                          enabled: !isNonLavorativo,
                          decoration: const InputDecoration(labelText: 'Partenza', border: OutlineInputBorder(), isDense: true, prefixIcon: Icon(Icons.trip_origin, size: 20)),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: tratta.arrivoController,
                          enabled: !isNonLavorativo,
                          onEditingComplete: () => _calcolaKmOSRM(tratta),
                          onSubmitted: (_) => _calcolaKmOSRM(tratta),
                          decoration: InputDecoration(
                            labelText: 'Arrivo (Premi Invio o icona mappa per calcolare km)',
                            border: const OutlineInputBorder(),
                            isDense: true,
                            prefixIcon: const Icon(Icons.location_on, size: 20),
                            suffixIcon: IconButton(
                              icon: Icon(Icons.map, color: cislGreen),
                              onPressed: () => _calcolaKmOSRM(tratta),
                              tooltip: 'Calcola km effettivi',
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Checkbox(
                              value: tratta.isAndataRitorno,
                              activeColor: cislGreen,
                              onChanged: isNonLavorativo ? null : (val) => _toggleAndataRitorno(tratta, val),
                            ),
                            const Text('Andata e Ritorno (A/R)', style: TextStyle(fontWeight: FontWeight.w500)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: tratta.kmController,
                                enabled: !isNonLavorativo,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(labelText: 'Km totali tratta', border: OutlineInputBorder(), isDense: true, prefixIcon: Icon(Icons.straighten, size: 20)),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Rimborso: € ${tratta.rimborsoTratta.toStringAsFixed(2)}',
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),

            Text('Spese Extra e Documentate', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: cislGreen)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _parcheggioController,
                    enabled: !isNonLavorativo,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Parcheggio (€)', border: OutlineInputBorder(), prefixIcon: Icon(Icons.local_parking)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _pedaggioController,
                    enabled: !isNonLavorativo,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Pedaggio Autostrada (€)', border: OutlineInputBorder(), prefixIcon: Icon(Icons.toll)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _pastoController,
                    enabled: !isNonLavorativo,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Pasto (€)', border: OutlineInputBorder(), prefixIcon: Icon(Icons.restaurant)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _mezziController,
                    enabled: !isNonLavorativo,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Treno / Tram (€)', border: OutlineInputBorder(), prefixIcon: Icon(Icons.train)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            Text('Agenda Attività Sindacali', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: cislGreen)),
            const SizedBox(height: 8),
            TextField(
              controller: _agendaController,
              enabled: !isNonLavorativo,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Descrizione delle attività svolte, riunioni, incontri...',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 20),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cislGreen.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: cislGreen.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'TOTALE GIORNALIERO:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: cislGreen),
                  ),
                  Text(
                    '€ ${_totaleGiornaliero.toStringAsFixed(2)}',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: cislGreen),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            Text('Esportazione e Stampa PDF', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: cislGreen)),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: cislGreen, foregroundColor: Colors.white),
                    onPressed: () => _stampaPdfRiepilogo('Giornaliero'),
                    icon: const Icon(Icons.print, size: 16),
                    label: const Text('Stampa Giorno'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: cislGreen, foregroundColor: Colors.white),
                    onPressed: () => _stampaPdfRiepilogo('Settimanale'),
                    icon: const Icon(Icons.print, size: 16),
                    label: const Text('Stampa Settimana'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: cislGreen, foregroundColor: Colors.white),
                    onPressed: () => _stampaPdfRiepilogo('Mensile'),
                    icon: const Icon(Icons.print, size: 16),
                    label: const Text('Stampa Mese'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isNonLavorativo ? Colors.orange.shade800 : cislGreen,
                  foregroundColor: Colors.white,
                ),
                onPressed: _salvaGiornataCorrente,
                icon: Icon(isNonLavorativo ? Icons.event_busy : Icons.save),
                label: Text(
                  isNonLavorativo ? 'Salva Giornata ($_statoGiornata)' : 'Salva Giornata Lavorativa',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}