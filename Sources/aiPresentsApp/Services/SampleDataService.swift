import Foundation
import SwiftData

class SampleDataService {
    static func createSampleData(in context: ModelContext) {
        let cal = Calendar.current
        let today = Date()
        let year = cal.component(.year, from: today)

        // Helper: Geburtsdatum mit korrektem Alter (lokal, damit der Compiler keine Labels erwartet)
        func bday(_ daysFromNow: Int, _ age: Int) -> Date {
            let next = cal.date(byAdding: .day, value: daysFromNow, to: today)!
            return cal.date(byAdding: .year, value: -age, to: next)!
        }

        // MARK: - 50 Demo-Personen

        let isEN = Locale.current.language.languageCode?.identifier != "de"

        // --- Bald Geburtstag (Timeline sieht direkt gut aus) ---
        let max      = person("demo-max",    isEN ? "James Wilson"       : "Max Mustermann",        bday(0,   32), isEN ? "Friend"    : "Freund")
        let erika    = person("demo-erika",  isEN ? "Emily Parker"       : "Erika Musterfrau",      bday(2,   38), isEN ? "Sister"    : "Schwester")
        let hans     = person("demo-hans",   isEN ? "David Thompson"     : "Hans Beispiel",         bday(5,   29), isEN ? "Colleague" : "Kollege")
        let anna     = person("demo-anna",   isEN ? "Margaret Johnson"   : "Anna Muster",           bday(7,   45), isEN ? "Mother"    : "Mutter")
        let peter    = person("demo-peter",  isEN ? "Robert Davis"       : "Peter Beispielmann",    bday(12,  26), isEN ? "Brother"   : "Bruder")

        // --- Diese Woche / diesen Monat ---
        let lisa     = person("demo-lisa",   isEN ? "Lisa Martinez"      : "Lisa Testmann",         bday(15,  41), isEN ? "Colleague" : "Kollegin")
        let thomas   = person("demo-thomas", isEN ? "Thomas Brown"       : "Thomas Muster",         bday(18,  34), isEN ? "Friend"    : "Freund")
        let julia    = person("demo-julia",  isEN ? "Julia Anderson"     : "Julia Musterfrau",      bday(22,  27), isEN ? "Friend"    : "Freundin")
        let sophie   = person("demo-sophie", isEN ? "Sophie Miller"      : "Sophie Beispiel",       bday(25,  31), isEN ? "Partner"   : "Partnerin")
        let michael  = person("demo-michael",isEN ? "Michael Taylor"     : "Michael Normalverb.",   bday(28,  50), isEN ? "Uncle"     : "Onkel")

        // --- Nächste 2 Monate ---
        let maria    = person("demo-maria",  isEN ? "Maria Garcia"       : "Maria Beispiel",        bday(35,  58), isEN ? "Aunt"      : "Tante")
        let felix    = person("demo-felix",  isEN ? "Felix Harris"       : "Felix Musterknabe",     bday(42,  23), isEN ? "Cousin"    : "Cousin")
        let klara    = person("demo-klara",  isEN ? "Clara Robinson"     : "Klara Beispielfrau",    bday(48,  36), isEN ? "Friend"    : "Freundin")
        let otto     = person("demo-otto",   isEN ? "Richard Moore"      : "Otto Normalverbraucher",bday(55,  52), isEN ? "Father"    : "Vater")
        let emma     = person("demo-emma",   isEN ? "Emma Wilson"        : "Emma Musterkind",       bday(62,   8), isEN ? "Niece"     : "Nichte")
        let paul     = person("demo-paul",   isEN ? "Paul Walker"        : "Paul Muster",           bday(68,  17), isEN ? "Nephew"    : "Neffe")
        let kurt     = person("demo-kurt",   isEN ? "Kurt Reynolds"      : "Kurt Musterboss",       bday(75,  44), isEN ? "Boss"      : "Chef")
        let sarah    = person("demo-sarah",  isEN ? "Sarah Collins"      : "Sarah Beispielfrau",    bday(82,  33), isEN ? "Colleague" : "Kollegin")
        let markus   = person("demo-markus", isEN ? "Marcus Reed"        : "Markus Testmann",       bday(88,  28), isEN ? "Friend"    : "Freund")
        let ingrid   = person("demo-ingrid", isEN ? "Dorothy Evans"      : "Ingrid Muster",         bday(95,  67), isEN ? "Grandma"   : "Oma")

        // --- 3–6 Monate ---
        let gerhard  = person("demo-gerhard",isEN ? "George Campbell"    : "Gerhard Beispiel",      bday(102, 70), isEN ? "Grandpa"   : "Opa")
        let nina     = person("demo-nina",   isEN ? "Nina Stewart"       : "Nina Musterfee",        bday(108, 22), isEN ? "Cousin"    : "Cousine")
        let stefan   = person("demo-stefan", isEN ? "Steven Cooper"      : "Stefan Beispielm.",     bday(115, 39), isEN ? "Brother"   : "Bruder")
        let lena     = person("demo-lena",   isEN ? "Lena Brooks"        : "Lena Musterkind",       bday(120, 11), isEN ? "Niece"     : "Nichte")
        let tobias   = person("demo-tobias", isEN ? "Toby Richardson"    : "Tobias Normalbürger",  bday(128, 25), isEN ? "Colleague" : "Kollege")
        let petra    = person("demo-petra",  isEN ? "Patricia Wood"      : "Petra Beispielfrau",    bday(135, 48), isEN ? "Aunt"      : "Tante")
        let daniel   = person("demo-daniel", isEN ? "Daniel Foster"      : "Daniel Muster",         bday(142, 30), isEN ? "Friend"    : "Freund")
        let monika   = person("demo-monika", isEN ? "Monica Bell"        : "Monika Beispiel",       bday(149, 55), isEN ? "Mother"    : "Mutter")
        let jan      = person("demo-jan",    isEN ? "Jack Howard"        : "Jan Testmann",          bday(155, 21), isEN ? "Nephew"    : "Neffe")
        let laura    = person("demo-laura",  isEN ? "Laura Bennett"      : "Laura Musterfrau",      bday(162, 26), isEN ? "Friend"    : "Freundin")

        // --- 6–12 Monate ---
        let bernhard = person("demo-bernhard",isEN ? "Bernard Gray"      : "Bernhard Muster",      bday(168, 43), isEN ? "Uncle"     : "Onkel")
        let karin    = person("demo-karin",  isEN ? "Karen Price"        : "Karin Beispielfrau",    bday(175, 38), isEN ? "Colleague" : "Kollegin")
        let florian  = person("demo-florian",isEN ? "Florian Ross"       : "Florian Normalv.",      bday(182, 19), isEN ? "Cousin"    : "Cousin")
        let ursula   = person("demo-ursula", isEN ? "Ruth Morgan"        : "Ursula Musterdame",     bday(188, 72), isEN ? "Grandma"   : "Oma")
        let dominik  = person("demo-dominik",isEN ? "Dominic Hayes"      : "Dominik Beispiel",      bday(195, 24), isEN ? "Friend"    : "Freund")
        let helga    = person("demo-helga",  isEN ? "Helen Peterson"     : "Helga Musterdame",      bday(200, 65), isEN ? "Aunt"      : "Tante")
        let patrick  = person("demo-patrick",isEN ? "Patrick Kelly"      : "Patrick Testperson",    bday(208, 31), isEN ? "Colleague" : "Kollege")
        let andrea   = person("demo-andrea", isEN ? "Andrea Mitchell"    : "Andrea Musterfrau",     bday(215, 46), isEN ? "Boss"      : "Chefin")
        let tim      = person("demo-tim",    isEN ? "Tim Sanders"        : "Tim Beispielkind",      bday(222, 14), isEN ? "Nephew"    : "Neffe")
        let sandra   = person("demo-sandra", isEN ? "Sandra Cox"         : "Sandra Musterperson",   bday(228, 29), isEN ? "Friend"    : "Freundin")
        let christian = person("demo-christian",isEN ? "Chris Murphy"    : "Christian Muster",      bday(235, 37), isEN ? "Brother"   : "Bruder")
        let brigitte = person("demo-brigitte",isEN ? "Barbara Russell"   : "Brigitte Beispiel",     bday(242, 61), isEN ? "Grandma"   : "Oma")
        let oliver   = person("demo-oliver", isEN ? "Oliver Grant"       : "Oliver Normalverb.",    bday(248, 27), isEN ? "Friend"    : "Freund")
        let katrin   = person("demo-katrin", isEN ? "Katherine Lee"      : "Katrin Musterfrau",     bday(255, 34), isEN ? "Colleague" : "Kollegin")
        let werner   = person("demo-werner", isEN ? "Walter Scott"       : "Werner Beispielm.",     bday(260, 58), isEN ? "Uncle"     : "Onkel")
        let melanie  = person("demo-melanie",isEN ? "Melanie Young"      : "Melanie Musterperson",  bday(268, 23), isEN ? "Cousin"    : "Cousine")
        let hubert   = person("demo-hubert", isEN ? "Herbert King"       : "Hubert Normalverb.",    bday(275, 74), isEN ? "Grandpa"   : "Opa")
        let tanja    = person("demo-tanja",  isEN ? "Tanya Adams"        : "Tanja Beispielfrau",    bday(280, 41), isEN ? "Friend"    : "Freundin")
        let Sebastian = person("demo-sebastian",isEN ? "Sebastian Clark" : "Sebastian Muster",      bday(290, 33), isEN ? "Friend"    : "Freund")
        let irene    = person("demo-irene",  isEN ? "Irene Wright"       : "Irene Musterdame",      bday(350, 69), isEN ? "Aunt"      : "Tante")

        // Test: Geburtstag gestern + gekauftes Geschenk → Auto-Transition testen
        let gestern  = person("demo-gestern",isEN ? "Yesterday Birthday" : "Gestern Geburtstag",   bday(-1, 30), isEN ? "Friend" : "Freund")

        let allPeople: [PersonRef] = [
            max, erika, hans, anna, peter, lisa, thomas, julia, sophie, michael,
            maria, felix, klara, otto, emma, paul, kurt, sarah, markus, ingrid,
            gerhard, nina, stefan, lena, tobias, petra, daniel, monika, jan, laura,
            bernhard, karin, florian, ursula, dominik, helga, patrick, andrea, tim, sandra,
            christian, brigitte, oliver, katrin, werner, melanie, hubert, tanja, Sebastian, irene,
            gestern
        ]
        // Demo-Hobbies fuer einige Personen
        max.hobbies = isEN ? ["Cooking", "Whisky", "BBQ"] : ["Kochen", "Whisky", "Grillen"]
        erika.hobbies = isEN ? ["Yoga", "Wellness", "Watercolor"] : ["Yoga", "Wellness", "Aquarell"]
        sophie.hobbies = isEN ? ["Photography", "Travel", "Reading"] : ["Fotografie", "Reisen", "Lesen"]
        anna.hobbies = isEN ? ["Wine", "Gardening", "Cooking"] : ["Wein", "Garten", "Kochen"]
        thomas.hobbies = isEN ? ["Running", "Tech", "Gaming"] : ["Laufen", "Technik", "Gaming"]
        emma.hobbies = isEN ? ["LEGO", "Crafts", "Drawing"] : ["LEGO", "Basteln", "Malen"]

        allPeople.forEach { context.insert($0) }

        // MARK: - Geschenkideen

        // Max / James (Freund, Geburtstag HEUTE)
        idea(max, isEN ? "Whisky Tasting Set" : "Whisky Tasting Set", isEN ? "Loves Single Malt Islay" : "Mag Single Malt Islay", 50, 80, .idea, isEN ? ["Drinks", "Tasting"] : ["Alkohol", "Tasting"], context)
        idea(max, isEN ? "Pasta & Risotto Cooking Class" : "Kochkurs Pasta & Risotto", isEN ? "Passionate home cook" : "Kocht leidenschaftlich gerne", 60, 90, .planned, isEN ? ["Experience", "Cooking"] : ["Erlebnis", "Kochen"], context)
        idea(max, isEN ? "Bluetooth BBQ Thermometer" : "Grill-Thermometer Bluetooth", isEN ? "Grills a lot in summer" : "Grillt viel im Sommer", 30, 60, .idea, isEN ? ["BBQ", "Kitchen"] : ["Grillen", "Küche"], context)

        // Erika / Emily (Schwester, in 2 Tagen)
        idea(erika, isEN ? "Spa Voucher" : "Spa-Gutschein", isEN ? "Loves wellness and massages" : "Liebt Wellness und Massagen", 80, 120, .planned, ["Wellness"], context)
        idea(erika, isEN ? "Manduka PRO Yoga Mat" : "Yoga-Matte Manduka PRO", isEN ? "Does yoga daily" : "Macht täglich Yoga", 50, 80, .idea, isEN ? ["Fitness", "Yoga"] : ["Sport", "Yoga"], context)

        // Sophie (Partnerin)
        idea(sophie, isEN ? "Weekend Trip to Prague" : "Kurzurlaub Prag", isEN ? "Never been to Prague" : "War noch nie in Prag", 300, 500, .idea, isEN ? ["Travel", "Experience"] : ["Reise", "Erlebnis"], context)
        idea(sophie, isEN ? "Fujifilm Instax Mini 12" : "Fujifilm Instax Mini 12", isEN ? "Loves instant photos" : "Mag Sofortbild-Fotos", 70, 100, .planned, isEN ? ["Photo", "Creative"] : ["Foto", "Kreativ"], context)

        // Anna / Margaret (Mutter)
        idea(anna, isEN ? "Bordeaux Wine Collection" : "Weinpaket Bordeaux", isEN ? "Red wine lover, 2019 vintage" : "Rotwein-Liebhaberin, Jahrgang 2019", 60, 100, .idea, isEN ? ["Wine"] : ["Wein"], context)
        idea(anna, isEN ? "DeLonghi Espresso Machine" : "Kaffeemaschine DeLonghi", isEN ? "Drinks espresso daily" : "Trinkt täglich Espresso", 100, 150, .idea, isEN ? ["Kitchen", "Coffee"] : ["Küche", "Kaffee"], context)

        // Otto / Richard (Vater)
        idea(otto, isEN ? "Bosch Cordless Drill" : "Bosch Akku-Bohrschrauber", isEN ? "18V system, loves DIY" : "18V System, heimwerkert viel", 80, 130, .planned, isEN ? ["Tools"] : ["Werkzeug"], context)

        // Emma (Nichte, 8 Jahre)
        idea(emma, isEN ? "LEGO Friends Ice Cream Parlor" : "LEGO Friends Eiscafé", isEN ? "Loves LEGO Friends sets" : "Liebt LEGO Friends Sets", 35, 55, .idea, isEN ? ["LEGO", "Toys"] : ["LEGO", "Spielzeug"], context)
        idea(emma, isEN ? "Unicorn Backpack" : "Einhorn-Rucksack", isEN ? "Loves unicorns and purple" : "Mag Einhörner und Lila", 25, 40, .planned, isEN ? ["School"] : ["Schule"], context)

        // Paul (Neffe, 17)
        idea(paul, isEN ? "Nintendo Switch Zelda: Echoes of Wisdom" : "Nintendo Switch Zelda: Echoes of Wisdom", isEN ? "Loves the Zelda series" : "Mag Zelda-Serie", 45, 60, .idea, ["Gaming"], context)
        idea(paul, isEN ? "Powell Skateboard Deck" : "Skateboard Deck Powell", isEN ? "Skateboards, 8.0\"" : "Fährt Skateboard, 8.0\"", 40, 70, .idea, isEN ? ["Sports", "Skateboard"] : ["Sport", "Skateboard"], context)

        // Hans / David (Kollege)
        idea(hans, isEN ? "Moleskine XL Notebook" : "Moleskine Notizbuch XL", isEN ? "Writes a lot, likes quality paper" : "Schreibt viel, mag gutes Papier", 25, 40, .idea, isEN ? ["Office"] : ["Büro"], context)

        // Thomas (Freund)
        idea(thomas, isEN ? "Garmin Forerunner 265" : "Garmin Forerunner 265", isEN ? "Runs half marathons" : "Läuft Halbmarathon", 280, 350, .idea, isEN ? ["Sports", "Tech"] : ["Sport", "Technik"], context)

        // Andrea (Chefin)
        idea(andrea, isEN ? "Handmade Porcelain Mug" : "Porzellan-Tasse handgemacht", isEN ? "Always drinks tea at the office" : "Trinkt immer Tee im Büro", 30, 50, .idea, isEN ? ["Office", "Ceramics"] : ["Büro", "Geschirr"], context)

        // Maria (Tante)
        idea(maria, isEN ? "Garden Herb Kit" : "Garten-Kräuterset", isEN ? "Has a big garden, cooks with fresh herbs" : "Hat großen Garten, kocht mit frischen Kräutern", 30, 50, .idea, isEN ? ["Garden", "Cooking"] : ["Garten", "Kochen"], context)

        // Gestern (Auto-Transition Test: purchased → given)
        idea(gestern, isEN ? "JBL Bluetooth Speaker" : "Bluetooth-Lautsprecher JBL", isEN ? "Loves music" : "Mag Musik", 50, 80, .purchased, isEN ? ["Tech", "Music"] : ["Technik", "Musik"], context)

        // MARK: - Geschenkhistorie

        hist(max, isEN ? "Craft Beer 12-Pack" : "Craftbier-Paket 12er", isEN ? "Drinks" : "Getränke", year-1, 55, isEN ? "Was thrilled" : "War begeistert", context)
        hist(max, isEN ? "Samsonite Suitcase 26\"" : "Koffer Samsonite 67cm", isEN ? "Travel" : "Reise", year-2, 180, isEN ? "Travels a lot, very practical" : "Reist viel, sehr praktisch", context)
        hist(erika, isEN ? "Chanel No. 5 Perfume" : "Parfüm Chanel No. 5", isEN ? "Beauty" : "Kosmetik", year-1, 90, isEN ? "She loved it" : "Hat sie sehr gefreut", context)
        hist(erika, isEN ? "Winsor & Newton Watercolor Set" : "Aquarell-Set Winsor & Newton", isEN ? "Creative" : "Kreativ", year-2, 65, isEN ? "Paints as a hobby" : "Malt als Hobby", context)
        hist(anna, isEN ? "Victorinox Outdoor Knife" : "Jagdmesser Victorinox", "Outdoor", year-1, 75, isEN ? "Outdoor hobby" : "Outdoor-Hobby", context)
        hist(thomas, "Garmin Forerunner 55", isEN ? "Sports/Tech" : "Sport/Technik", year-1, 180, isEN ? "Running watch, very happy" : "Laufuhr, sehr zufrieden", context)
        hist(sophie, isEN ? "Weekend in Munich" : "Wochenende in München", isEN ? "Experience/Travel" : "Erlebnis/Reise", year-1, 420, isEN ? "Was wonderful" : "War wunderschön", context)
        hist(sophie, "Apple AirPods Pro", isEN ? "Tech" : "Technik", year-2, 249, isEN ? "Uses them daily" : "Benutzt täglich", context)
        hist(emma, "LEGO Duplo Farm", isEN ? "Toys" : "Spielzeug", year-1, 40, isEN ? "Played with it for days" : "Tagelang gespielt", context)
        hist(paul, "Longboard Globe", isEN ? "Sports" : "Sport", year-1, 110, isEN ? "Rides it to school daily" : "Fährt täglich zur Schule", context)
        hist(otto, "Weber Grill Q1200", isEN ? "BBQ" : "Grillen", year-1, 160, isEN ? "Grills every summer" : "Grillt jeden Sommer", context)
        hist(peter, "Kindle Paperwhite", isEN ? "Tech/Books" : "Technik/Bücher", year-1, 120, isEN ? "Reads a lot, very practical" : "Liest viel, sehr praktisch", context)
        hist(ingrid, isEN ? "Hot Air Balloon Ride for Two" : "Ballonfahrt für zwei", isEN ? "Experience" : "Erlebnis", year-1, 210, isEN ? "A dream come true" : "War ein Traum", context)
        hist(kurt, "Lamy Pen & Pencil Set", isEN ? "Office" : "Büro", year-1, 85, isEN ? "Uses it daily at the office" : "Benutzt täglich im Büro", context)

        // Erhaltene Geschenke (received)
        hist(max, isEN ? "Sony Bluetooth Headphones" : "Bluetooth-Kopfhörer Sony", isEN ? "Tech" : "Technik", year-1, 120, isEN ? "Birthday gift" : "Zum Geburtstag bekommen", context, direction: .received)
        hist(erika, isEN ? "Handmade Candle" : "Handgemachte Kerze", isEN ? "Decor" : "Deko", year-1, 25, isEN ? "Christmas gift" : "Weihnachtsgeschenk", context, direction: .received)
        hist(sophie, isEN ? "Year in Review Photo Book" : "Fotobuch Jahresrückblick", isEN ? "Creative" : "Kreativ", year-1, 45, isEN ? "Very personal, beautiful" : "Sehr persönlich, wunderschön", context, direction: .received)

        // MARK: - Erinnerungsregel
        context.insert(ReminderRule(leadDays: [30, 14, 7, 2],
                                    quietHoursStart: 22, quietHoursEnd: 8, enabled: true))
    }

    // MARK: - Hilfsfunktionen

    private static func person(
        _ id: String, _ name: String, _ birthday: Date, _ relation: String
    ) -> PersonRef {
        PersonRef(contactIdentifier: id, displayName: name, birthday: birthday, relation: relation)
    }

    private static func idea(
        _ person: PersonRef, _ title: String, _ note: String,
        _ budgetMin: Double, _ budgetMax: Double, _ status: GiftStatus,
        _ tags: [String], _ context: ModelContext
    ) {
        context.insert(GiftIdea(personId: person.id, title: title, note: note,
                                budgetMin: budgetMin, budgetMax: budgetMax,
                                status: status, tags: tags))
    }

    private static func hist(
        _ person: PersonRef, _ title: String, _ category: String,
        _ year: Int, _ budget: Double, _ note: String, _ context: ModelContext,
        direction: GiftDirection = .given
    ) {
        context.insert(GiftHistory(personId: person.id, title: title,
                                   category: category, year: year,
                                   budget: budget, note: note,
                                   direction: direction))
    }

    // MARK: - Reset

    static func clearSampleData(in context: ModelContext) {
        do {
            try context.delete(model: SuggestionFeedback.self)
            try context.delete(model: ReminderRule.self)
            try context.delete(model: GiftHistory.self)
            try context.delete(model: GiftIdea.self)
            try context.delete(model: PersonRef.self)
            AppLogger.data.info("Sample data cleared successfully")
        } catch {
            AppLogger.data.error("Failed to clear sample data", error: error)
        }
    }
}

