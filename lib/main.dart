import 'dart:convert';
import 'dart:math';
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
      home: const SchermataAutenticazionePage(),
    );
  }
}

class ProfiloUtente {
  final String userId;
  final String password;
  final String email;
  final String nome;
  final String cognome;
  final String ruolo;
  final String sede;
  final String telefono;

  ProfiloUtente({
    required this.userId,
    required this.password,
    required this.email,
    required this.nome,
    required this.cognome,
    required this.ruolo,
    required this.sede,
    required this.telefono,
  });
}

class Autoveicolo {
  final String modello;
  final String targa;
  final String alimentazione;

  Autoveicolo({required this.modello, required this.targa, required this.alimentazione});
}

// Archivio globale temporaneo degli utenti registrati per simulare il database
List<ProfiloUtente> _utentiRegistrati = [];

class SchermataAutenticazionePage extends StatefulWidget {
  const SchermataAutenticazionePage({super.key});

  @override
  State<SchermataAutenticazionePage> createState() => _SchermataAutenticazionePageState();
}

class _SchermataAutenticazionePageState extends State<SchermataAutenticazionePage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Controller Login
  final _loginFormKey = GlobalKey<FormState>();
  final TextEditingController _loginUserCtrl = TextEditingController();
  final TextEditingController _loginPassCtrl = TextEditingController();

  // Controller Registrazione
  final _regFormKey = GlobalKey<FormState>();
  final TextEditingController _regUserCtrl = TextEditingController();
  final TextEditingController _regPassCtrl = TextEditingController();
  final TextEditingController _regEmailCtrl = TextEditingController();
  final TextEditingController _regNomeCtrl = TextEditingController();
  final TextEditingController _regCognomeCtrl = TextEditingController();
  final TextEditingController _regRuoloCtrl = TextEditingController(text: 'Delegato Sindacale');
  final TextEditingController _regSedeCtrl = TextEditingController();
  final TextEditingController _regTelCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  void _eseguiLogin() {
    if (_loginFormKey.currentState!.validate()) {
      String user = _loginUserCtrl.text.trim();
      String pass = _loginPassCtrl.text.trim();

      var trovato = _utentiRegistrati.firstWhere(
        (u) => u.userId == user && u.password == pass,
        orElse: () => ProfiloUtente(userId: '', password: '', email: '', nome: '', cognome: '', ruolo: '', sede: '', telefono: ''),
      );

      if (trovato.userId.isNotEmpty) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => SchermataGiornalieraPage(utente: trovato)),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Credenziali non valide o account non esistente. Registrati prima!'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _eseguiRegistrazione() {
    if (_regFormKey.currentState!.validate()) {
      String user = _regUserCtrl.text.trim();
      
      if (_utentiRegistrati.any((u) => u.userId == user)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User ID già esistente. Scegline un altro o fai il login.'), backgroundColor: Colors.red),
        );
        return;
      }

      ProfiloUtente nuovoUtente = ProfiloUtente(
        userId: user,
        password: _regPassCtrl.text.trim(),
        email: _regEmailCtrl.text.trim(),
        nome: _regNomeCtrl.text.trim(),
        cognome: _regCognomeCtrl.text.trim(),
        ruolo: _regRuoloCtrl.text.trim(),
        sede: _regSedeCtrl.text.trim(),
        telefono: _regTelCtrl.text.trim(),
      );

      _utentiRegistrati.add(nuovoUtente);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Account creato con successo! Ora puoi accedere.'), backgroundColor: Colors.green),
      );

      _tabController.animateTo(0); // Passa alla scheda Login
    }
  }

  void _mostraRecuperoPassword() {
    final TextEditingController emailRecuperoCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Recupero Password', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Inserisci l’indirizzo email associato al tuo account per ricevere le istruzioni di recupero:', style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 12),
            TextField(
              controller: emailRecuperoCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder(), isDense: true),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annulla', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0B5335), foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Se l’email è registrata, riceverai un messaggio di recupero.')),
              );
            },
            child: const Text('Invia Recupero'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color cislGreen = Color(0xFF0B5335);

    return Scaffold(
      appBar: AppBar(
        title: const Text('CISL FP - Gestione Trasferte', style: TextStyle(color: Colors.white)),
        backgroundColor: cislGreen,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'ACCEDI', icon: Icon(Icons.login, size: 20)),
            Tab(text: 'REGISTRATI', icon: Icon(Icons.person_add, size: 20)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Scheda ACCEDI
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 450),
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Form(
                      key: _loginFormKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Icon(Icons.lock_outline, size: 60, color: cislGreen),
                          const SizedBox(height: 12),
                          const Text('Bentornato', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: cislGreen), textAlign: TextAlign.center),
                          const SizedBox(height: 24),
                          TextFormField(
                            controller: _loginUserCtrl,
                            decoration: const InputDecoration(labelText: 'User ID', border: OutlineInputBorder(), prefixIcon: Icon(Icons.person)),
                            validator: (v) => v == null || v.isEmpty ? 'Inserisci il tuo User ID' : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _loginPassCtrl,
                            obscureText: true,
                            decoration: const InputDecoration(labelText: 'Password', border: OutlineInputBorder(), prefixIcon: Icon(Icons.lock)),
                            validator: (v) => v == null || v.isEmpty ? 'Inserisci la password' : null,
                          ),
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: _mostraRecuperoPassword,
                              child: const Text('Password dimenticata?', style: TextStyle(color: cislGreen, fontSize: 13)),
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: cislGreen,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            onPressed: _eseguiLogin,
                            child: const Text('Accedi all’App', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Scheda REGISTRATI
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 450),
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Form(
                      key: _regFormKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Icon(Icons.badge, size: 60, color: cislGreen),
                          const SizedBox(height: 12),
                          const Text('Crea Nuovo Account', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: cislGreen), textAlign: TextAlign.center),
                          const SizedBox(height: 20),
                          TextFormField(
                            controller: _regUserCtrl,
                            decoration: const InputDecoration(labelText: 'User ID desiderato', border: OutlineInputBorder(), prefixIcon: Icon(Icons.person_pin)),
                            validator: (v) => v == null || v.isEmpty ? 'Inserisci un User ID' : null,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _regPassCtrl,
                            obscureText: true,
                            decoration: const InputDecoration(labelText: 'Password', border: OutlineInputBorder(), prefixIcon: Icon(Icons.lock)),
                            validator: (v) => v == null || v.length < 4 ? 'Minimo 4 caratteri' : null,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _regEmailCtrl,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(labelText: 'Email (per recupero password)', border: OutlineInputBorder(), prefixIcon: Icon(Icons.email)),
                            validator: (v) => v == null || !v.contains('@') ? 'Inserisci un’email valida' : null,
                          ),
                          const Divider(height: 24),
                          TextFormField(
                            controller: _regNomeCtrl,
                            decoration: const InputDecoration(labelText: 'Nome', border: OutlineInputBorder(), prefixIcon: Icon(Icons.person)),
                            validator: (v) => v == null || v.isEmpty ? 'Inserisci il nome' : null,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _regCognomeCtrl,
                            decoration: const InputDecoration(labelText: 'Cognome', border: OutlineInputBorder(), prefixIcon: Icon(Icons.person_outline)),
                            validator: (v) => v == null || v.isEmpty ? 'Inserisci il cognome' : null,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _regRuoloCtrl,
                            decoration: const InputDecoration(labelText: 'Ruolo / Qualifica', border: OutlineInputBorder(), prefixIcon: Icon(Icons.work)),
                            validator: (v) => v == null || v.isEmpty ? 'Inserisci il ruolo' : null,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _regSedeCtrl,
                            decoration: const InputDecoration(labelText: 'Sede / Territorio', border: OutlineInputBorder(), prefixIcon: Icon(Icons.location_city)),
                            validator: (v) => v == null || v.isEmpty ? 'Inserisci la sede' : null,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _regTelCtrl,
                            keyboardType: TextInputType.phone,
                            decoration: const InputDecoration(labelText: 'Telefono', border: OutlineInputBorder(), prefixIcon: Icon(Icons.phone)),
                            validator: (v) => v == null || v.isEmpty ? 'Inserisci il telefono' : null,
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: cislGreen,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            onPressed: _eseguiRegistrazione,
                            child: const Text('Registrati', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
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
  final String alimentazione;
  final double costoAciKm;
  final List<TrattDataBackup> tratteDettaglio;
  final double rimborsoAci;
  final double speseExtra;
  final bool haBuonoPasto;
  final double buonoPastoImporto;
  final double totale;
  final String attivita;

  GiornataSalvata({
    required this.data,
    required this.stato,
    required this.modelloAuto,
    required this.targa,
    required this.alimentazione,
    required this.costoAciKm,
    required this.tratteDettaglio,
    required this.rimborsoAci,
    required this.speseExtra,
    required this.haBuonoPasto,
    required this.buonoPastoImporto,
    required this.totale,
    required this.attivita,
  });
}

class TrattDataBackup {
  final String partenza;
  final String arrivo;
  final bool isAndataRitorno;
  final String km;
  final double rimborso;

  TrattDataBackup({required this.partenza, required this.arrivo, required this.isAndataRitorno, required this.km, required this.rimborso});
}

class SchermataGiornalieraPage extends StatefulWidget {
  final ProfiloUtente utente;
  const SchermataGiornalieraPage({super.key, required this.utente});

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

  final List<Autoveicolo> _parcoAuto = [];

  List<TrattaViaggio> _tratte = [TrattaViaggio()];

  final TextEditingController _parcheggioController = TextEditingController();
  final TextEditingController _pedaggioController = TextEditingController();
  final TextEditingController _pastoController = TextEditingController();
  final TextEditingController _mezziController = TextEditingController();
  final TextEditingController _agendaController = TextEditingController();
  
  bool _haBuonoPasto = false;
  static const double _valoreBuonoPasto = 5.70;

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

  void _caricaDatiGiorno(DateTime data) {
    var salvata = _archivioGiornate.firstWhere(
      (g) => g.data.year == data.year && g.data.month == data.month && g.data.day == data.day,
      orElse: () => GiornataSalvata(
        data: data,
        stato: 'Lavorativa',
        modelloAuto: '',
        targa: '',
        alimentazione: 'Gasolio (Diesel)',
        costoAciKm: 0.45,
        tratteDettaglio: [],
        rimborsoAci: 0,
        speseExtra: 0,
        haBuonoPasto: false,
        buonoPastoImporto: 0,
        totale: 0,
        attivita: '',
      ),
    );

    setState(() {
      _dataSelezionata = data;
      _statoGiornata = salvata.stato;
      if (_archivioGiornate.any((g) => g.data.year == data.year && g.data.month == data.month && g.data.day == data.day)) {
        _modelloAutoController.text = salvata.modelloAuto;
        _targaController.text = salvata.targa;
        _alimentazioneSelezionata = salvata.alimentazione;
        _costoAciKm = salvata.costoAciKm;
        _agendaController.text = salvata.attivita;
        _haBuonoPasto = salvata.haBuonoPasto;

        _tratte = salvata.tratteDettaglio.map((t) {
          var tv = TrattaViaggio();
          tv.partenzaController.text = t.partenza;
          tv.arrivoController.text = t.arrivo;
          tv.isAndataRitorno = t.isAndataRitorno;
          tv.kmController.text = t.km;
          tv.rimborsoTratta = t.rimborso;
          _aggiornaAscoltatoriTratta(tv);
          return tv;
        }).toList();

        if (_tratte.isEmpty) {
          _tratte = [TrattaViaggio()];
          _aggiornaAscoltatoriTratta(_tratte[0]);
        }
      } else {
        _azzeraCampiLavorativi();
      }
      _calcolaTotali();
    });
  }

  void _eliminaRegistrazioneGiorno(DateTime data) {
    setState(() {
      _archivioGiornate.removeWhere((g) => g.data.year == data.year && g.data.month == data.month && g.data.day == data.day);
      _caricaDatiGiorno(data);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Registrazione del ${data.day}/${data.month}/${data.year} rimossa.')),
    );
  }

  Future<void> _selezionaData(BuildContext context) async {
    List<DateTime> dateRegistrate = _archivioGiornate.map((g) => g.data).toList();

    showDialog(
      context: context,
      builder: (context) => CustomCalendarPicker(
        initialDate: _dataSelezionata,
        firstDate: DateTime(2025, 1, 1),
        lastDate: DateTime(2030, 12, 31),
        recordedDates: dateRegistrate,
        onDateSelected: (DateTime newDate) {
          _caricaDatiGiorno(newDate);
        },
        onDateUnselected: (DateTime unselectedDate) {
          _eliminaRegistrazioneGiorno(unselectedDate);
        },
      ),
    );
  }

  Future<void> _gestisciParcoAuto() async {
    final TextEditingController modCtrl = TextEditingController();
    final TextEditingController targCtrl = TextEditingController();
    String alimLocal = 'Gasolio (Diesel)';

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text('Gestione Parco Veicoli (Max 4)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              content: SizedBox(
                width: 400,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_parcoAuto.isNotEmpty) ...[
                      const Text('Veicoli in memoria:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                      const SizedBox(height: 6),
                      SizedBox(
                        height: 120,
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: _parcoAuto.length,
                          itemBuilder: (context, index) {
                            final auto = _parcoAuto[index];
                            return ListTile(
                              dense: true,
                              title: Text('${auto.modello} (${auto.targa})', style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text('Alimentazione: ${auto.alimentazione}'),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                                onPressed: () {
                                  setDialogState(() {
                                    _parcoAuto.removeAt(index);
                                  });
                                  setState(() {});
                                },
                              ),
                            );
                          },
                        ),
                      ),
                      const Divider(),
                    ],
                    if (_parcoAuto.length < 4) ...[
                      const Text('Aggiungi nuovo veicolo:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0B5335))),
                      const SizedBox(height: 8),
                      TextField(
                        controller: modCtrl,
                        decoration: const InputDecoration(labelText: 'Modello Auto (es. Fiat Tipo)', border: OutlineInputBorder(), isDense: true),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: targCtrl,
                        decoration: const InputDecoration(labelText: 'Targa', border: OutlineInputBorder(), isDense: true),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: alimLocal,
                        decoration: const InputDecoration(labelText: 'Alimentazione', border: OutlineInputBorder(), isDense: true),
                        items: <String>['Benzina', 'Gasolio (Diesel)', 'GPL / Metano', 'Ibrida / Elettrica']
                            .map<DropdownMenuItem<String>>((String val) => DropdownMenuItem<String>(value: val, child: Text(val)))
                            .toList(),
                        onChanged: (val) => setDialogState(() => alimLocal = val ?? 'Gasolio (Diesel)'),
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0B5335), foregroundColor: Colors.white),
                        onPressed: () {
                          if (modCtrl.text.isNotEmpty && targCtrl.text.isNotEmpty) {
                            setDialogState(() {
                              _parcoAuto.add(Autoveicolo(modello: modCtrl.text.trim(), targa: targCtrl.text.trim().toUpperCase(), alimentazione: alimLocal));
                              modCtrl.clear();
                              targCtrl.clear();
                            });
                            setState(() {});
                          }
                        },
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('Salva in Memoria'),
                      ),
                    ] else
                      const Text('Raggiunto limite massimo di 4 veicoli.', style: TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Chiudi', style: TextStyle(color: Colors.grey)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _selezionaSettimanaDaStampare() async {
    DateTime dataScelta = _dataSelezionata;
    List<DateTime> dateRegistrate = _archivioGiornate.map((g) => g.data).toList();

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            DateTime inizioSettimana = dataScelta.subtract(Duration(days: dataScelta.weekday - 1));
            DateTime fineSettimana = inizioSettimana.add(const Duration(days: 6));

            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text('Seleziona Settimana per Stampa', style: TextStyle(fontSize: 16)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Scegli un giorno della settimana da stampare:', style: TextStyle(fontSize: 13, color: Colors.grey)),
                  const SizedBox(height: 10),
                  ListTile(
                    title: const Text('Giorno di riferimento', style: TextStyle(fontSize: 14)),
                    subtitle: Text('${dataScelta.day}/${dataScelta.month}/${dataScelta.year}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    trailing: const Icon(Icons.calendar_today, color: Color(0xFF0B5335)),
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) => CustomCalendarPicker(
                          initialDate: dataScelta,
                          firstDate: DateTime(2025, 1, 1),
                          lastDate: DateTime(2030, 12, 31),
                          recordedDates: dateRegistrate,
                          onDateSelected: (DateTime picked) {
                            setDialogState(() => dataScelta = picked);
                          },
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    color: Colors.grey.shade100,
                    child: Text(
                      'Intervallo calcolato:\nDal ${inizioSettimana.day}/${inizioSettimana.month}/${inizioSettimana.year} al ${fineSettimana.day}/${fineSettimana.month}/${fineSettimana.year}',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Annulla', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0B5335), foregroundColor: Colors.white),
                  onPressed: () {
                    Navigator.pop(context);
                    _stampaPdfIntervallo(inizioSettimana, fineSettimana, mostraFirme: false);
                  },
                  child: const Text('Stampa Settimana'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<Coord?> _getCoordinateDaIndirizzo(String indirizzo) async {
    final queryCorretta = indirizzo.toLowerCase().contains('italia') ? indirizzo : '$indirizzo, Italia';
    final url = Uri.parse('https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(queryCorretta)}&format=json&limit=1&countrycodes=it');
    
    final response = await http.get(url, headers: {'User-Agent': 'GestionaleSindacatoApp'});
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data.isNotEmpty) {
        return Coord(double.parse(data[0]['lat']), double.parse(data[0]['lon']));
      }
    }
    return null;
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
        final url = Uri.parse(
          'https://routing.openstreetmap.de/routed-car/route/v1/driving/${p1.lon},${p1.lat};${p2.lon},${p2.lat}?overview=false'
        );
        
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
              SnackBar(content: Text('Tratta calcolata: ${tratta.kmController.text} km')),
            );
            return;
          }
        }

        double dLat = (p2.lat - p1.lat) * pi / 180;
        double dLon = (p2.lon - p1.lon) * pi / 180;
        double a = sin(dLat / 2) * sin(dLat / 2) + cos(p1.lat * pi / 180) * cos(p2.lat * pi / 180) * sin(dLon / 2) * sin(dLon / 2);
        double c = 2 * atan2(sqrt(a), sqrt(1 - a));
        double kmRealiStrada = (6371.0 * c) * 1.1;

        setState(() {
          tratta.kmSolaAndata = kmRealiStrada;
          double kmFinali = tratta.isAndataRitorno ? kmRealiStrada * 2 : kmRealiStrada;
          tratta.kmController.text = kmFinali.toStringAsFixed(1);
          _calcolaTotali();
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tratta stimata (fallback geometrico).')),
        );

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
    double buonoPastoValore = _haBuonoPasto ? _valoreBuonoPasto : 0.0;

    setState(() {
      _rimborsoAciTotale = kmTotali * _costoAciKm;
      _speseExtraTotali = parcheggio + pedaggio + pasto + mezzi + buonoPastoValore;
      _totaleGiornaliero = _rimborsoAciTotale + _speseExtraTotali;
    });
  }

  void _azzeraCampiLavorativi() {
    _modelloAutoController.clear();
    _targaController.clear();
    for (var t in _tratte) {
      t.partenzaController.dispose();
      t.arrivoController.dispose();
      t.kmController.dispose();
    }
    _tratte = [TrattaViaggio()];
    _aggiornaAscoltatoriTratta(_tratte[0]);
    _parcheggioController.clear();
    _pedaggioController.clear();
    _pastoController.clear();
    _mezziController.clear();
    _agendaController.clear();
    _haBuonoPasto = false;
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

    List<TrattDataBackup> tratteBackup = _tratte.map((t) => TrattDataBackup(
      partenza: t.partenzaController.text,
      arrivo: t.arrivoController.text,
      isAndataRitorno: t.isAndataRitorno,
      km: t.kmController.text,
      rimborso: t.rimborsoTratta,
    )).toList();

    _archivioGiornate.add(
      GiornataSalvata(
        data: _dataSelezionata,
        stato: _statoGiornata,
        modelloAuto: _modelloAutoController.text,
        targa: _targaController.text,
        alimentazione: _alimentazioneSelezionata,
        costoAciKm: _costoAciKm,
        tratteDettaglio: tratteBackup,
        rimborsoAci: _rimborsoAciTotale,
        speseExtra: _speseExtraTotali,
        haBuonoPasto: _haBuonoPasto,
        buonoPastoImporto: _haBuonoPasto ? _valoreBuonoPasto : 0.0,
        totale: _totaleGiornaliero,
        attivita: _agendaController.text,
      ),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Giornata del ${_dataSelezionata.day}/${_dataSelezionata.month}/${_dataSelezionata.year} salvata con successo!')),
    );
  }

  Future<void> _mostraSelettoreIntervalloStampa() async {
    DateTime dataInizio = _dataSelezionata.subtract(const Duration(days: 7));
    DateTime dataFine = _dataSelezionata;
    List<DateTime> dateRegistrate = _archivioGiornate.map((g) => g.data).toList();

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text('Seleziona Intervallo per Stampa', style: TextStyle(fontSize: 16)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    title: const Text('Data Inizio', style: TextStyle(fontSize: 14)),
                    subtitle: Text('${dataInizio.day}/${dataInizio.month}/${dataInizio.year}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    trailing: const Icon(Icons.calendar_today, color: Color(0xFF0B5335)),
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) => CustomCalendarPicker(
                          initialDate: dataInizio,
                          firstDate: DateTime(2025, 1, 1),
                          lastDate: DateTime(2030, 12, 31),
                          recordedDates: dateRegistrate,
                          onDateSelected: (DateTime picked) {
                            setDialogState(() => dataInizio = picked);
                          },
                        ),
                      );
                    },
                  ),
                  const Divider(),
                  ListTile(
                    title: const Text('Data Fine', style: TextStyle(fontSize: 14)),
                    subtitle: Text('${dataFine.day}/${dataFine.month}/${dataFine.year}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    trailing: const Icon(Icons.calendar_today, color: Color(0xFF0B5335)),
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) => CustomCalendarPicker(
                          initialDate: dataFine,
                          firstDate: DateTime(2025, 1, 1),
                          lastDate: DateTime(2030, 12, 31),
                          recordedDates: dateRegistrate,
                          onDateSelected: (DateTime picked) {
                            setDialogState(() => dataFine = picked);
                          },
                        ),
                      );
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Annulla', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0B5335), foregroundColor: Colors.white),
                  onPressed: () {
                    Navigator.pop(context);
                    _stampaPdfIntervallo(dataInizio, dataFine, mostraFirme: false);
                  },
                  child: const Text('Stampa Report'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _stampaPdfIntervallo(DateTime inizio, DateTime fine, {bool mostraFirme = false}) async {
    DateTime start = DateTime(inizio.year, inizio.month, inizio.day);
    DateTime end = DateTime(fine.year, fine.month, fine.day, 23, 59, 59);

    List<GiornataSalvata> filtrate = _archivioGiornate.where((g) {
      return g.data.isAfter(start.subtract(const Duration(days: 1))) && g.data.isBefore(end.add(const Duration(days: 1)));
    }).toList();

    filtrate.sort((a, b) => a.data.compareTo(b.data));

    double totAci = filtrate.fold(0.0, (sum, item) => sum + item.rimborsoAci);
    double totExtra = filtrate.fold(0.0, (sum, item) => sum + item.speseExtra);
    double totComplessivo = filtrate.fold(0.0, (sum, item) => sum + item.totale);

    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          List<pw.Widget> widgets = [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('CISL FP DEI LAGHI', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 4),
                    pw.Text('Operatore: ${widget.utente.nome} ${widget.utente.cognome} | Sede: ${widget.utente.sede}', style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                  ],
                ),
                pw.Text('Report Trasferte e Attività', style: pw.TextStyle(fontSize: 14)),
              ],
            ),
            pw.Divider(thickness: 2),
            pw.SizedBox(height: 10),
            pw.Text('Periodo: Dal ${start.day}/${start.month}/${start.year} al ${end.day}/${end.month}/${end.year}', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 15),
          ];

          if (filtrate.isEmpty) {
            widgets.add(pw.Paragraph(text: 'Nessuna giornata registrata in questo intervallo.'));
          } else {
            widgets.add(
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Table(
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
                      ...filtrate.map((g) => pw.TableRow(
                            children: [
                              pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('${g.data.day}/${g.data.month}/${g.data.year}', style: const pw.TextStyle(fontSize: 10))),
                              pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(g.stato, style: const pw.TextStyle(fontSize: 10))),
                              pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('EUR ${g.rimborsoAci.toStringAsFixed(2)}', style: const pw.TextStyle(fontSize: 10))),
                              pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('EUR ${g.speseExtra.toStringAsFixed(2)} ${g.haBuonoPasto ? "(incl. Buono Pasto)" : ""}', style: const pw.TextStyle(fontSize: 10))),
                              pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('EUR ${g.totale.toStringAsFixed(2)}', style: const pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold))),
                            ],
                          )),
                    ],
                  ),
                  pw.SizedBox(height: 15),
                  pw.Text('Dettaglio Attività Sindacali e Agenda:', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 5),
                  ...filtrate.where((g) => g.attivita.isNotEmpty).map((g) => pw.Padding(
                        padding: const pw.EdgeInsets.only(bottom: 6),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text('${g.data.day}/${g.data.month}/${g.data.year} (${g.stato}):', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700)),
                            pw.Text(g.attivita, style: const pw.TextStyle(fontSize: 10)),
                          ],
                        ),
                      )),
                ],
              ),
            );
          }

          widgets.add(pw.SizedBox(height: 15));
          widgets.add(pw.Bullet(text: 'Totale Rimborsi ACI: EUR ${totAci.toStringAsFixed(2)}'));
          widgets.add(pw.Bullet(text: 'Totale Spese Extra (inclusi Buoni Pasto): EUR ${totExtra.toStringAsFixed(2)}'));
          widgets.add(pw.SizedBox(height: 20));
          
          widgets.add(
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              color: PdfColors.grey200,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('TOTALE COMPLESSIVO:', style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
                  pw.Text('EUR ${totComplessivo.toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold)),
                ],
              ),
            ),
          );

          if (mostraFirme) {
            widgets.add(pw.SizedBox(height: 40));
            widgets.add(
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Container(width: 180, child: pw.Divider(color: PdfColors.black, thickness: 1)),
                      pw.SizedBox(height: 4),
                      pw.Text('Firma Operatore/Segretario', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Container(width: 220, child: pw.Divider(color: PdfColors.black, thickness: 1)),
                      pw.SizedBox(height: 4),
                      pw.Text('Firma Segretario Amministrativo e/o Segretario Generale', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            );
          }

          return widgets;
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
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
            Expanded(
              child: Text(
                'CISL FP - ${widget.utente.nome} ${widget.utente.cognome} (${widget.utente.sede})',
                style: const TextStyle(color: Colors.white, fontSize: 16),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        backgroundColor: cislGreen,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            tooltip: 'Esci / Logout',
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const SchermataAutenticazionePage()),
              );
            },
          ),
        ],
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
                          label: const Text('Seleziona Data'),
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
                      items: <String>['Lavorativa', 'Ferie', 'Malattia', 'Assenza / Permesso', 'Ex Festività', 'Festività']
                          .map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: value == 'Lavorativa' ? cislGreen : Colors.red.shade700)),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _statoGiornata = newValue ?? 'Lavorativa';
                          if (_statoGiornata != 'Lavorativa' && _statoGiornata != 'Ex Festività' && _statoGiornata != 'Festività') {
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

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Dati Autoveicolo e Tariffa ACI', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: cislGreen)),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(foregroundColor: cislGreen, side: BorderSide(color: cislGreen)),
                  onPressed: _gestisciParcoAuto,
                  icon: const Icon(Icons.directions_car, size: 16),
                  label: const Text('Gestisci Veicoli'),
                ),
              ],
            ),
            const SizedBox(height: 8),

            if (_parcoAuto.isNotEmpty) ...[
              DropdownButtonFormField<Autoveicolo>(
                decoration: const InputDecoration(
                  labelText: 'Seleziona veicolo da memoria',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.garage),
                  isDense: true,
                ),
                items: _parcoAuto.map((auto) {
                  return DropdownMenuItem<Autoveicolo>(
                    value: auto,
                    child: Text('${auto.modello} - ${auto.targa} (${auto.alimentazione})'),
                  );
                }).toList(),
                onChanged: (Autoveicolo? selectedAuto) {
                  if (selectedAuto != null) {
                    setState(() {
                      _modelloAutoController.text = selectedAuto.modello;
                      _targaController.text = selectedAuto.targa;
                      _alimentazioneSelezionata = selectedAuto.alimentazione;
                      _aggiornaCostoAci(selectedAuto.alimentazione);
                    });
                  }
                },
              ),
              const SizedBox(height: 10),
            ],

            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _modelloAutoController,
                    enabled: !isNonLavorativo,
                    decoration: const InputDecoration(labelText: 'Modello Auto', border: OutlineInputBorder(), prefixIcon: Icon(Icons.directions_car)),
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
            const SizedBox(height: 10),
            CheckboxListTile(
              title: const Text('Buono Pasto (€ 5,70)', style: TextStyle(fontWeight: FontWeight.bold)),
              value: _haBuonoPasto,
              activeColor: cislGreen,
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              onChanged: isNonLavorativo ? null : (bool? value) {
                setState(() {
                  _haBuonoPasto = value ?? false;
                  _calcolaTotali();
                });
              },
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
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: cislGreen, foregroundColor: Colors.white),
                  onPressed: () => _stampaPdfIntervallo(_dataSelezionata, _dataSelezionata, mostraFirme: false),
                  icon: const Icon(Icons.print, size: 16),
                  label: const Text('Stampa Giorno'),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: cislGreen, foregroundColor: Colors.white),
                  onPressed: _selezionaSettimanaDaStampare,
                  icon: const Icon(Icons.print, size: 16),
                  label: const Text('Stampa Settimana'),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: cislGreen, foregroundColor: Colors.white),
                  onPressed: () {
                    DateTime inizioMese = DateTime(_dataSelezionata.year, _dataSelezionata.month, 1);
                    DateTime fineMese = DateTime(_dataSelezionata.year, _dataSelezionata.month + 1, 0);
                    _stampaPdfIntervallo(inizioMese, fineMese, mostraFirme: true);
                  },
                  icon: const Icon(Icons.print, size: 16),
                  label: const Text('Stampa Mese'),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade800, foregroundColor: Colors.white),
                  onPressed: _mostraSelettoreIntervalloStampa,
                  icon: const Icon(Icons.date_range, size: 16),
                  label: const Text('Intervallo Personalizzato (Da... a...)'),
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