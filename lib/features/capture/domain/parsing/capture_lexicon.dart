/// Per-language vocabulary the rule-based parser runs on.
///
/// Everything here is **local, versioned with the app and translatable**
/// (HU-04b/HU-08 of `17-captura-voz.md`): no network call ever backs a lookup.
/// Words are stored already normalized (lowercase, no diacritics) because
/// `SpokenTokens` compares against that form.
///
/// The es-CO colloquialisms ("lucas", "palo", "barras") live only in the
/// Spanish lexicon and therefore cannot fire on an English transcription. Widening this to other
/// Spanish variants ("varos", "pavos") is a deliberate non-goal of the first
/// delivery — the same words mean different things elsewhere and would trade
/// coverage for confident nonsense.
class CaptureLexicon {
  const CaptureLexicon({
    required this.languageCode,
    required this.numberWords,
    required this.scaleWords,
    required this.hundredMultiplier,
    required this.halfWords,
    required this.andWords,
    required this.decimalJoinWords,
    required this.currencyWords,
    required this.currencyConnectorWords,
    required this.expenseVerbs,
    required this.incomeVerbs,
    required this.weekdays,
    required this.categorySynonyms,
    required this.fillerWords,
  });

  final String languageCode;

  /// Word -> value, for values that add up ("veinte" 20, "quinientos" 500).
  final Map<String, int> numberWords;

  /// Word -> multiplier applied to whatever was accumulated ("mil" 1000,
  /// "lucas" 1000, "palo" 1000000). A multiplier with nothing before it means
  /// one of it: "mil quinientos" is 1500, not 500.
  final Map<String, int> scaleWords;

  /// Words that multiply by a hundred instead of adding ("hundred" in
  /// English). Spanish has no such word — "doscientos" is its own entry in
  /// [numberWords] — so this is empty for `es`.
  final Set<String> hundredMultiplier;

  /// "medio" / "half": the magnitude-elision idiom "tres y medio".
  final Set<String> halfWords;

  /// Connectors inside a number ("treinta y cinco").
  final Set<String> andWords;

  /// Words that introduce cents ("doce **con** cincuenta").
  final Set<String> decimalJoinWords;

  /// Words that make the unit explicit and therefore switch the magnitude
  /// heuristic off ("pesos").
  final Set<String> currencyWords;

  /// Connectors that glue a scale word to the currency that follows it ("un
  /// millón **de** pesos"). Only consumed as part of the amount when a
  /// [currencyWords] entry immediately follows — otherwise the word is left
  /// for the note like any other filler, so "un millón de dólares gringos"
  /// still reads "gringos" afterwards instead of swallowing it too.
  final Set<String> currencyConnectorWords;

  /// Verb phrases (as word sequences) that mark the movement as an expense.
  final List<List<String>> expenseVerbs;

  /// Verb phrases that mark it as an income. Matched **before** the expense
  /// ones so "me pagaron" never reads as "pagué".
  final List<List<String>> incomeVerbs;

  /// Weekday name -> ISO weekday (Monday = 1).
  final Map<String, int> weekdays;

  /// Keyword -> the category names it points at, most preferred first. The
  /// dictionary only ever *suggests* a name; the match still has to exist
  /// among the user's own categories.
  final Map<String, List<String>> categorySynonyms;

  /// Command muletillas and articles stripped from the note's edges.
  final Set<String> fillerWords;
}

/// Spanish (es-CO flavoured) lexicon.
const CaptureLexicon spanishCaptureLexicon = CaptureLexicon(
  languageCode: 'es',
  numberWords: <String, int>{
    'cero': 0,
    'un': 1,
    'uno': 1,
    'una': 1,
    'dos': 2,
    'tres': 3,
    'cuatro': 4,
    'cinco': 5,
    'seis': 6,
    'siete': 7,
    'ocho': 8,
    'nueve': 9,
    'diez': 10,
    'once': 11,
    'doce': 12,
    'trece': 13,
    'catorce': 14,
    'quince': 15,
    'dieciseis': 16,
    'diecisiete': 17,
    'dieciocho': 18,
    'diecinueve': 19,
    'veinte': 20,
    'veintiuno': 21,
    'veintiun': 21,
    'veintidos': 22,
    'veintitres': 23,
    'veinticuatro': 24,
    'veinticinco': 25,
    'veintiseis': 26,
    'veintisiete': 27,
    'veintiocho': 28,
    'veintinueve': 29,
    'treinta': 30,
    'cuarenta': 40,
    'cincuenta': 50,
    'sesenta': 60,
    'setenta': 70,
    'ochenta': 80,
    'noventa': 90,
    'cien': 100,
    'ciento': 100,
    'doscientos': 200,
    'doscientas': 200,
    'trescientos': 300,
    'trescientas': 300,
    'cuatrocientos': 400,
    'cuatrocientas': 400,
    'quinientos': 500,
    'quinientas': 500,
    'seiscientos': 600,
    'seiscientas': 600,
    'setecientos': 700,
    'setecientas': 700,
    'ochocientos': 800,
    'ochocientas': 800,
    'novecientos': 900,
    'novecientas': 900,
  },
  scaleWords: <String, int>{
    'mil': 1000,
    'millon': 1000000,
    'millones': 1000000,
    // es-CO colloquialisms.
    'luca': 1000,
    'lucas': 1000,
    'barra': 1000,
    'barras': 1000,
    'palo': 1000000,
    'palos': 1000000,
  },
  hundredMultiplier: <String>{},
  halfWords: <String>{'medio', 'media'},
  andWords: <String>{'y'},
  decimalJoinWords: <String>{'con'},
  currencyWords: <String>{'peso', 'pesos', 'cop'},
  currencyConnectorWords: <String>{'de'},
  expenseVerbs: <List<String>>[
    <String>['gaste'],
    <String>['gastamos'],
    <String>['pague'],
    <String>['pagamos'],
    <String>['compre'],
    <String>['compramos'],
    <String>['me', 'costo'],
    <String>['nos', 'costo'],
    <String>['costo'],
  ],
  // Anything that is not listed here falls through to an expense, so the list
  // has to cover third person singular ("me pagó") as much as plural, and the
  // colloquial es-CO forms ("me cayó"). What it must *not* do is win over a
  // legitimate expense: since these are matched first, a verb that doubles as
  // a noun ("pago", "depósito", "ingreso") is only ever accepted with "me" /
  // "nos" in front — bare, it would read "pagué el ingreso del gimnasio" as
  // money coming in.
  incomeVerbs: <List<String>>[
    <String>['me', 'pagaron'],
    <String>['nos', 'pagaron'],
    // Deliberately not "me pago" / "nos pago": normalized without accents,
    // that token is identical to the first-person present of "pagar" — "me
    // pago el gimnasio", a real and common expense, not someone paying the
    // user. Unlike the entries below, this one is not resolvable from text
    // alone, so it stays out rather than risk reading an expense as income.
    <String>['me', 'consignaron'],
    <String>['me', 'consigno'],
    <String>['me', 'depositaron'],
    <String>['me', 'deposito'],
    <String>['me', 'transfirieron'],
    <String>['me', 'transfirio'],
    <String>['me', 'ingresaron'],
    // Not "me ingreso": same accent-loss collision as "pago" above, this time
    // with "me ingreso al gimnasio" / "me ingreso a la universidad" — a
    // common reflexive "enroll myself", not money coming in.
    <String>['me', 'entro'],
    <String>['me', 'entraron'],
    <String>['me', 'llego'],
    <String>['me', 'llegaron'],
    <String>['me', 'cayo'],
    <String>['me', 'cayeron'],
    <String>['me', 'devolvieron'],
    <String>['me', 'devolvio'],
    <String>['me', 'reembolsaron'],
    <String>['me', 'reembolso'],
    <String>['me', 'reintegraron'],
    <String>['me', 'dieron'],
    <String>['me', 'dio'],
    <String>['me', 'prestaron'],
    // Not "me presto": same collision, with "me presto el carro" / "me
    // presto plata" — borrowing something, the opposite direction of money.
    <String>['recibi'],
    <String>['recibimos'],
    <String>['cobre'],
    <String>['cobramos'],
    <String>['gane'],
    <String>['ganamos'],
    <String>['vendi'],
    <String>['vendimos'],
  ],
  weekdays: <String, int>{
    'lunes': 1,
    'martes': 2,
    'miercoles': 3,
    'jueves': 4,
    'viernes': 5,
    'sabado': 6,
    'domingo': 7,
  },
  categorySynonyms: <String, List<String>>{
    'almuerzo': <String>['alimentacion', 'comida', 'alimentos'],
    'almorce': <String>['alimentacion', 'comida', 'alimentos'],
    'comida': <String>['alimentacion', 'comida', 'alimentos'],
    'desayuno': <String>['alimentacion', 'comida', 'alimentos'],
    'cena': <String>['alimentacion', 'comida', 'alimentos'],
    'mercado': <String>['mercado', 'alimentacion', 'comida'],
    'domicilio': <String>['alimentacion', 'comida', 'restaurantes'],
    'restaurante': <String>['restaurantes', 'alimentacion', 'comida'],
    'tinto': <String>['alimentacion', 'comida', 'cafe'],
    'cafe': <String>['alimentacion', 'comida', 'cafe'],
    'onces': <String>['alimentacion', 'comida'],
    'mecato': <String>['alimentacion', 'comida'],
    'uber': <String>['transporte'],
    'taxi': <String>['transporte'],
    'bus': <String>['transporte'],
    'transmilenio': <String>['transporte'],
    'metro': <String>['transporte'],
    'peaje': <String>['transporte'],
    'parqueadero': <String>['transporte'],
    'gasolina': <String>['gasolina', 'transporte'],
    'arriendo': <String>['arriendo', 'hogar', 'vivienda'],
    'servicios': <String>['servicios', 'hogar', 'vivienda'],
    'luz': <String>['servicios', 'hogar', 'vivienda'],
    'agua': <String>['servicios', 'hogar', 'vivienda'],
    'internet': <String>['servicios', 'hogar', 'vivienda'],
    'salud': <String>['salud'],
    'farmacia': <String>['salud'],
    'medico': <String>['salud'],
    'cine': <String>['entretenimiento', 'ocio'],
    'ropa': <String>['ropa', 'compras'],
    'sueldo': <String>['salario', 'sueldo', 'nomina'],
    'salario': <String>['salario', 'sueldo', 'nomina'],
    'nomina': <String>['salario', 'sueldo', 'nomina'],
    // A noun, not a verb: it suggests a category, and the polarity still comes
    // from the verb ("me llegó la quincena").
    'quincena': <String>['salario', 'sueldo', 'nomina'],
  },
  fillerWords: <String>{
    'a',
    'al',
    'anota',
    'apunta',
    'con',
    'de',
    'del',
    'e',
    'el',
    'en',
    'la',
    'las',
    'lo',
    'los',
    'me',
    'mi',
    'nos',
    'para',
    'por',
    'que',
    'registra',
    'se',
    'tome',
    'tomamos',
    'comi',
    'comimos',
    'un',
    'una',
    'unas',
    'unos',
    'y',
  },
);

/// English lexicon. Deliberately free of Spanish colloquialisms.
const CaptureLexicon englishCaptureLexicon = CaptureLexicon(
  languageCode: 'en',
  numberWords: <String, int>{
    'zero': 0,
    'one': 1,
    'two': 2,
    'three': 3,
    'four': 4,
    'five': 5,
    'six': 6,
    'seven': 7,
    'eight': 8,
    'nine': 9,
    'ten': 10,
    'eleven': 11,
    'twelve': 12,
    'thirteen': 13,
    'fourteen': 14,
    'fifteen': 15,
    'sixteen': 16,
    'seventeen': 17,
    'eighteen': 18,
    'nineteen': 19,
    'twenty': 20,
    'thirty': 30,
    'forty': 40,
    'fifty': 50,
    'sixty': 60,
    'seventy': 70,
    'eighty': 80,
    'ninety': 90,
  },
  scaleWords: <String, int>{
    'thousand': 1000,
    'million': 1000000,
    'millions': 1000000,
    'k': 1000,
  },
  hundredMultiplier: <String>{'hundred'},
  halfWords: <String>{'half'},
  andWords: <String>{'and'},
  decimalJoinWords: <String>{'point'},
  currencyWords: <String>{'peso', 'pesos', 'dollar', 'dollars', 'bucks'},
  // English does not glue a scale word to its currency with a connector
  // ("a million dollars", never "a million of dollars").
  currencyConnectorWords: <String>{},
  expenseVerbs: <List<String>>[
    <String>['spent'],
    <String>['paid'],
    <String>['bought'],
    <String>['it', 'cost'],
    <String>['cost'],
  ],
  incomeVerbs: <List<String>>[
    <String>['got', 'paid'],
    <String>['was', 'paid'],
    <String>['received'],
    <String>['earned'],
  ],
  weekdays: <String, int>{
    'monday': 1,
    'tuesday': 2,
    'wednesday': 3,
    'thursday': 4,
    'friday': 5,
    'saturday': 6,
    'sunday': 7,
  },
  categorySynonyms: <String, List<String>>{
    'lunch': <String>['food', 'groceries', 'alimentacion'],
    'dinner': <String>['food', 'alimentacion'],
    'breakfast': <String>['food', 'alimentacion'],
    'groceries': <String>['groceries', 'food', 'mercado'],
    'coffee': <String>['food', 'coffee', 'alimentacion'],
    'restaurant': <String>['restaurants', 'food', 'alimentacion'],
    'uber': <String>['transport', 'transporte'],
    'taxi': <String>['transport', 'transporte'],
    'bus': <String>['transport', 'transporte'],
    'gas': <String>['gas', 'transport', 'transporte'],
    'fuel': <String>['gas', 'transport', 'transporte'],
    'rent': <String>['rent', 'home', 'hogar'],
    'utilities': <String>['utilities', 'home', 'hogar'],
    'internet': <String>['utilities', 'home', 'hogar'],
    'health': <String>['health', 'salud'],
    'pharmacy': <String>['health', 'salud'],
    'clothes': <String>['clothing', 'shopping'],
    'salary': <String>['salary', 'salario'],
  },
  fillerWords: <String>{
    'a',
    'an',
    'and',
    'at',
    'add',
    'for',
    'from',
    'i',
    'in',
    'it',
    'log',
    'my',
    'of',
    'on',
    'record',
    'the',
    'to',
    'with',
  },
);

/// The lexicon for [languageCode], falling back to Spanish (the app's primary
/// market) for anything that is not English.
CaptureLexicon lexiconFor(String languageCode) =>
    languageCode.toLowerCase().startsWith('en')
        ? englishCaptureLexicon
        : spanishCaptureLexicon;
