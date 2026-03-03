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

        // --- Bald Geburtstag (Timeline sieht direkt gut aus) ---
        let max      = person("demo-max",    "Max Mustermann",        bday(0,   32), "Freund")
        let erika    = person("demo-erika",  "Erika Musterfrau",      bday(2,   38), "Schwester")
        let hans     = person("demo-hans",   "Hans Beispiel",         bday(5,   29), "Kollege")
        let anna     = person("demo-anna",   "Anna Muster",           bday(7,   45), "Mutter")
        let peter    = person("demo-peter",  "Peter Beispielmann",    bday(12,  26), "Bruder")

        // --- Diese Woche / diesen Monat ---
        let lisa     = person("demo-lisa",   "Lisa Testmann",         bday(15,  41), "Kollegin")
        let thomas   = person("demo-thomas", "Thomas Muster",         bday(18,  34), "Freund")
        let julia    = person("demo-julia",  "Julia Musterfrau",      bday(22,  27), "Freundin")
        let sophie   = person("demo-sophie", "Sophie Beispiel",       bday(25,  31), "Partnerin")
        let michael  = person("demo-michael","Michael Normalverb.",   bday(28,  50), "Onkel")

        // --- Nächste 2 Monate ---
        let maria    = person("demo-maria",  "Maria Beispiel",        bday(35,  58), "Tante")
        let felix    = person("demo-felix",  "Felix Musterknabe",     bday(42,  23), "Cousin")
        let klara    = person("demo-klara",  "Klara Beispielfrau",    bday(48,  36), "Freundin")
        let otto     = person("demo-otto",   "Otto Normalverbraucher",bday(55,  52), "Vater")
        let emma     = person("demo-emma",   "Emma Musterkind",       bday(62,   8), "Nichte")
        let paul     = person("demo-paul",   "Paul Muster",           bday(68,  17), "Neffe")
        let kurt     = person("demo-kurt",   "Kurt Musterboss",       bday(75,  44), "Chef")
        let sarah    = person("demo-sarah",  "Sarah Beispielfrau",    bday(82,  33), "Kollegin")
        let markus   = person("demo-markus", "Markus Testmann",       bday(88,  28), "Freund")
        let ingrid   = person("demo-ingrid", "Ingrid Muster",         bday(95,  67), "Oma")

        // --- 3–6 Monate ---
        let gerhard  = person("demo-gerhard","Gerhard Beispiel",      bday(102, 70), "Opa")
        let nina     = person("demo-nina",   "Nina Musterfee",        bday(108, 22), "Cousine")
        let stefan   = person("demo-stefan", "Stefan Beispielm.",     bday(115, 39), "Bruder")
        let lena     = person("demo-lena",   "Lena Musterkind",       bday(120, 11), "Nichte")
        let tobias   = person("demo-tobias", "Tobias Normalbürger",  bday(128, 25), "Kollege")
        let petra    = person("demo-petra",  "Petra Beispielfrau",    bday(135, 48), "Tante")
        let daniel   = person("demo-daniel", "Daniel Muster",         bday(142, 30), "Freund")
        let monika   = person("demo-monika", "Monika Beispiel",       bday(149, 55), "Mutter")
        let jan      = person("demo-jan",    "Jan Testmann",          bday(155, 21), "Neffe")
        let laura    = person("demo-laura",  "Laura Musterfrau",      bday(162, 26), "Freundin")

        // --- 6–12 Monate ---
        let bernhard = person("demo-bernhard","Bernhard Muster",      bday(168, 43), "Onkel")
        let karin    = person("demo-karin",  "Karin Beispielfrau",    bday(175, 38), "Kollegin")
        let florian  = person("demo-florian","Florian Normalv.",      bday(182, 19), "Cousin")
        let ursula   = person("demo-ursula", "Ursula Musterdame",     bday(188, 72), "Oma")
        let dominik  = person("demo-dominik","Dominik Beispiel",      bday(195, 24), "Freund")
        let helga    = person("demo-helga",  "Helga Musterdame",      bday(200, 65), "Tante")
        let patrick  = person("demo-patrick","Patrick Testperson",    bday(208, 31), "Kollege")
        let andrea   = person("demo-andrea", "Andrea Musterfrau",     bday(215, 46), "Chefin")
        let tim      = person("demo-tim",    "Tim Beispielkind",      bday(222, 14), "Neffe")
        let sandra   = person("demo-sandra", "Sandra Musterperson",   bday(228, 29), "Freundin")
        let christian = person("demo-christian","Christian Muster",   bday(235, 37), "Bruder")
        let brigitte = person("demo-brigitte","Brigitte Beispiel",    bday(242, 61), "Oma")
        let oliver   = person("demo-oliver", "Oliver Normalverb.",    bday(248, 27), "Freund")
        let katrin   = person("demo-katrin", "Katrin Musterfrau",     bday(255, 34), "Kollegin")
        let werner   = person("demo-werner", "Werner Beispielm.",     bday(260, 58), "Onkel")
        let melanie  = person("demo-melanie","Melanie Musterperson",  bday(268, 23), "Cousine")
        let hubert   = person("demo-hubert", "Hubert Normalverb.",    bday(275, 74), "Opa")
        let tanja    = person("demo-tanja",  "Tanja Beispielfrau",    bday(280, 41), "Freundin")
        let Sebastian = person("demo-sebastian","Sebastian Muster",   bday(290, 33), "Freund")
        let irene    = person("demo-irene",  "Irene Musterdame",      bday(350, 69), "Tante")

        // Test: Geburtstag gestern + gekauftes Geschenk → Auto-Transition testen
        let gestern  = person("demo-gestern","Gestern Geburtstag",   bday(-1, 30), "Freund")

        let allPeople: [PersonRef] = [
            max, erika, hans, anna, peter, lisa, thomas, julia, sophie, michael,
            maria, felix, klara, otto, emma, paul, kurt, sarah, markus, ingrid,
            gerhard, nina, stefan, lena, tobias, petra, daniel, monika, jan, laura,
            bernhard, karin, florian, ursula, dominik, helga, patrick, andrea, tim, sandra,
            christian, brigitte, oliver, katrin, werner, melanie, hubert, tanja, Sebastian, irene,
            gestern
        ]
        allPeople.forEach { context.insert($0) }

        // MARK: - Geschenkideen

        // Max (Freund, Geburtstag HEUTE)
        idea(max, "Whisky Tasting Set", "Mag Single Malt Islay", 50, 80, .idea, ["Alkohol", "Tasting"], context)
        idea(max, "Kochkurs Pasta & Risotto", "Kocht leidenschaftlich gerne", 60, 90, .planned, ["Erlebnis", "Kochen"], context)
        idea(max, "Grill-Thermometer Bluetooth", "Grillt viel im Sommer", 30, 60, .idea, ["Grillen", "Küche"], context)

        // Erika (Schwester, in 2 Tagen)
        idea(erika, "Spa-Gutschein", "Liebt Wellness und Massagen", 80, 120, .planned, ["Wellness"], context)
        idea(erika, "Yoga-Matte Manduka PRO", "Macht täglich Yoga", 50, 80, .idea, ["Sport", "Yoga"], context)

        // Sophie (Partnerin)
        idea(sophie, "Kurzurlaub Prag", "War noch nie in Prag", 300, 500, .idea, ["Reise", "Erlebnis"], context)
        idea(sophie, "Fujifilm Instax Mini 12", "Mag Sofortbild-Fotos", 70, 100, .planned, ["Foto", "Kreativ"], context)

        // Anna (Mutter)
        idea(anna, "Weinpaket Bordeaux", "Rotwein-Liebhaberin, Jahrgang 2019", 60, 100, .idea, ["Wein"], context)
        idea(anna, "Kaffeemaschine DeLonghi", "Trinkt täglich Espresso", 100, 150, .idea, ["Küche", "Kaffee"], context)

        // Otto (Vater)
        idea(otto, "Bosch Akku-Bohrschrauber", "18V System, heimwerkert viel", 80, 130, .planned, ["Werkzeug"], context)

        // Emma (Nichte, 8 Jahre)
        idea(emma, "LEGO Friends Eiscafé", "Liebt LEGO Friends Sets", 35, 55, .idea, ["LEGO", "Spielzeug"], context)
        idea(emma, "Einhorn-Rucksack", "Mag Einhörner und Lila", 25, 40, .planned, ["Schule"], context)

        // Paul (Neffe, 17)
        idea(paul, "Nintendo Switch Zelda: Echoes of Wisdom", "Mag Zelda-Serie", 45, 60, .idea, ["Gaming"], context)
        idea(paul, "Skateboard Deck Powell", "Fährt Skateboard, 8.0\"", 40, 70, .idea, ["Sport", "Skateboard"], context)

        // Hans (Kollege)
        idea(hans, "Moleskine Notizbuch XL", "Schreibt viel, mag gutes Papier", 25, 40, .idea, ["Büro"], context)

        // thomas (Freund)
        idea(thomas, "Garmin Forerunner 265", "Läuft Halbmarathon", 280, 350, .idea, ["Sport", "Technik"], context)

        // andrea (Chefin)
        idea(andrea, "Porzellan-Tasse handgemacht", "Trinkt immer Tee im Büro", 30, 50, .idea, ["Büro", "Geschirr"], context)

        // maria (Tante)
        idea(maria, "Garten-Kräuterset", "Hat großen Garten, kocht mit frischen Kräutern", 30, 50, .idea, ["Garten", "Kochen"], context)

        // Gestern (Auto-Transition Test: purchased → given)
        idea(gestern, "Bluetooth-Lautsprecher JBL", "Mag Musik", 50, 80, .purchased, ["Technik", "Musik"], context)

        // MARK: - Geschenkhistorie

        hist(max, "Craftbier-Paket 12er", "Getränke", year-1, 55, "War begeistert", context)
        hist(max, "Koffer Samsonite 67cm", "Reise", year-2, 180, "Reist viel, sehr praktisch", context)
        hist(erika, "Parfüm Chanel No. 5", "Kosmetik", year-1, 90, "Hat sie sehr gefreut", context)
        hist(erika, "Aquarell-Set Winsor & Newton", "Kreativ", year-2, 65, "Malt als Hobby", context)
        hist(anna, "Jagdmesser Victorinox", "Outdoor", year-1, 75, "Outdoor-Hobby", context)
        hist(thomas, "Garmin Forerunner 55", "Sport/Technik", year-1, 180, "Laufuhr, sehr zufrieden", context)
        hist(sophie, "Wochenende in München", "Erlebnis/Reise", year-1, 420, "War wunderschön", context)
        hist(sophie, "Apple AirPods Pro", "Technik", year-2, 249, "Benutzt täglich", context)
        hist(emma, "LEGO Duplo Farm", "Spielzeug", year-1, 40, "Tagelang gespielt", context)
        hist(paul, "Longboard Globe", "Sport", year-1, 110, "Fährt täglich zur Schule", context)
        hist(otto, "Weber Grill Q1200", "Grillen", year-1, 160, "Grillt jeden Sommer", context)
        hist(peter, "Kindle Paperwhite", "Technik/Bücher", year-1, 120, "Liest viel, sehr praktisch", context)
        hist(ingrid, "Ballonfahrt für zwei", "Erlebnis", year-1, 210, "War ein Traum", context)
        hist(kurt, "Pen & Pencil Set Lamy", "Büro", year-1, 85, "Benutzt täglich im Büro", context)

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
        _ year: Int, _ budget: Double, _ note: String, _ context: ModelContext
    ) {
        context.insert(GiftHistory(personId: person.id, title: title,
                                   category: category, year: year,
                                   budget: budget, note: note))
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

