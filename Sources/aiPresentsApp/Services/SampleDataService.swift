import Foundation
import SwiftData

class SampleDataService {
    static func createSampleData(in context: ModelContext) {
        let cal = Calendar.current
        let today = Date()
        let year = cal.component(.year, from: today)

        // Helper: birthday mit echtem Geburtsjahr (Alter korrekt)
        func bday(daysFromNow: Int, age: Int) -> Date {
            let nextBirthday = cal.date(byAdding: .day, value: daysFromNow, to: today)!
            return cal.date(byAdding: .year, value: -age, to: nextBirthday)!
        }

        // MARK: - Personen (erkennbare Mustermann-Fiktivnamen)

        let max = PersonRef(contactIdentifier: "demo-max", displayName: "Max Mustermann",
                            birthday: bday(daysFromNow: 0, age: 32), relation: "Freund")
        let erika = PersonRef(contactIdentifier: "demo-erika", displayName: "Erika Musterfrau",
                              birthday: bday(daysFromNow: 2, age: 38), relation: "Schwester")
        let hans = PersonRef(contactIdentifier: "demo-hans", displayName: "Hans Beispiel",
                             birthday: bday(daysFromNow: 14, age: 29), relation: "Kollege")
        let anna = PersonRef(contactIdentifier: "demo-anna", displayName: "Anna Muster",
                             birthday: bday(daysFromNow: 21, age: 45), relation: "Mutter")
        let peter = PersonRef(contactIdentifier: "demo-peter", displayName: "Peter Beispielmann",
                              birthday: bday(daysFromNow: 28, age: 26), relation: "Bruder")
        let lisa = PersonRef(contactIdentifier: "demo-lisa", displayName: "Lisa Testmann",
                             birthday: bday(daysFromNow: 35, age: 41), relation: "Kollegin")
        let thomas = PersonRef(contactIdentifier: "demo-thomas", displayName: "Thomas Muster",
                               birthday: bday(daysFromNow: 52, age: 34), relation: "Freund")
        let maria = PersonRef(contactIdentifier: "demo-maria", displayName: "Maria Beispiel",
                              birthday: bday(daysFromNow: 67, age: 58), relation: "Tante")
        let felix = PersonRef(contactIdentifier: "demo-felix", displayName: "Felix Musterknabe",
                              birthday: bday(daysFromNow: 89, age: 23), relation: "Cousin")
        let klara = PersonRef(contactIdentifier: "demo-klara", displayName: "Klara Beispielfrau",
                              birthday: bday(daysFromNow: 112, age: 36), relation: "Freundin")
        let otto = PersonRef(contactIdentifier: "demo-otto", displayName: "Otto Normalverbraucher",
                             birthday: bday(daysFromNow: 145, age: 52), relation: "Vater")
        let emma = PersonRef(contactIdentifier: "demo-emma", displayName: "Emma Musterkind",
                             birthday: bday(daysFromNow: 178, age: 8), relation: "Nichte")
        let paul = PersonRef(contactIdentifier: "demo-paul", displayName: "Paul Muster",
                             birthday: bday(daysFromNow: 210, age: 17), relation: "Neffe")
        let sophie = PersonRef(contactIdentifier: "demo-sophie", displayName: "Sophie Beispiel",
                               birthday: bday(daysFromNow: 255, age: 31), relation: "Partnerin")
        let kurt = PersonRef(contactIdentifier: "demo-kurt", displayName: "Kurt Musterboss",
                             birthday: bday(daysFromNow: 300, age: 44), relation: "Chef")

        let allPeople = [max, erika, hans, anna, peter, lisa, thomas, maria,
                         felix, klara, otto, emma, paul, sophie, kurt]
        allPeople.forEach { context.insert($0) }

        // MARK: - Geschenkideen: Max (Freund, Geburtstag heute!)

        context.insert(GiftIdea(personId: max.id, title: "Whisky Tasting Set",
                                note: "Mag Single Malt, am liebsten Islay",
                                budgetMin: 50, budgetMax: 80, status: .idea, tags: ["Alkohol", "Tasting"]))
        context.insert(GiftIdea(personId: max.id, title: "Kochkurs italienische Küche",
                                note: "Kocht gerne, liebt Pasta und Risotto",
                                budgetMin: 60, budgetMax: 90, status: .planned, tags: ["Erlebnis", "Kochen"]))
        context.insert(GiftIdea(personId: max.id, title: "Grill-Thermometer Bluetooth",
                                note: "Grillt viel im Sommer",
                                budgetMin: 30, budgetMax: 60, status: .idea, tags: ["Grillen", "Küche"]))

        // MARK: - Geschenkideen: Erika (Schwester, in 2 Tagen!)

        context.insert(GiftIdea(personId: erika.id, title: "Spa-Gutschein",
                                note: "Liebt Wellness, am liebsten mit Massage",
                                budgetMin: 80, budgetMax: 120, status: .planned, tags: ["Wellness", "Erholung"]))
        context.insert(GiftIdea(personId: erika.id, title: "Yoga-Matte Premium",
                                note: "Macht täglich Yoga, aktuelle Matte ist alt",
                                budgetMin: 50, budgetMax: 80, status: .idea, tags: ["Sport", "Yoga"]))

        // MARK: - Geschenkideen: Hans (Kollege)

        context.insert(GiftIdea(personId: hans.id, title: "Moleskine Notizbuch Set",
                                note: "Schreibt viel, mag gutes Papier",
                                budgetMin: 25, budgetMax: 40, status: .idea, tags: ["Büro", "Schreiben"]))

        // MARK: - Geschenkideen: Anna (Mutter)

        context.insert(GiftIdea(personId: anna.id, title: "Bosch Akku-Bohrschrauber",
                                note: "Werkzeug immer willkommen, 18V System",
                                budgetMin: 80, budgetMax: 130, status: .planned, tags: ["Werkzeug", "Heimwerken"]))
        context.insert(GiftIdea(personId: anna.id, title: "Weinpaket Bordeaux",
                                note: "Rotwein-Liebhaberin, Jahrgang 2018-2020",
                                budgetMin: 60, budgetMax: 100, status: .idea, tags: ["Wein", "Essen"]))
        context.insert(GiftIdea(personId: anna.id, title: "Kaffeemaschine DeLonghi",
                                note: "Trinkt täglich Espresso",
                                budgetMin: 100, budgetMax: 150, status: .idea, tags: ["Küche", "Kaffee"]))

        // MARK: - Geschenkideen: Sophie (Partnerin)

        context.insert(GiftIdea(personId: sophie.id, title: "Kurzurlaub Prag",
                                note: "War noch nie in Prag, liebt Städtetrips",
                                budgetMin: 300, budgetMax: 500, status: .idea, tags: ["Reise", "Erlebnis"]))
        context.insert(GiftIdea(personId: sophie.id, title: "Kamera Fujifilm Instax",
                                note: "Mag Sofortbild-Fotos, Mini-Format",
                                budgetMin: 70, budgetMax: 100, status: .planned, tags: ["Foto", "Kreativ"]))

        // MARK: - Geschenkideen: Emma (Nichte, 8 Jahre)

        context.insert(GiftIdea(personId: emma.id, title: "LEGO Friends Eiscafé",
                                note: "Liebt LEGO Friends",
                                budgetMin: 35, budgetMax: 55, status: .idea, tags: ["LEGO", "Spielzeug"]))
        context.insert(GiftIdea(personId: emma.id, title: "Einhorn-Rucksack",
                                note: "Schule, mag Einhörner und Lila",
                                budgetMin: 25, budgetMax: 40, status: .planned, tags: ["Schule", "Mode"]))

        // MARK: - Geschenkideen: Paul (Neffe, 17)

        context.insert(GiftIdea(personId: paul.id, title: "Nintendo Switch Spiel",
                                note: "Mag Zelda und Mario",
                                budgetMin: 45, budgetMax: 60, status: .idea, tags: ["Gaming", "Nintendo"]))
        context.insert(GiftIdea(personId: paul.id, title: "Skateboard Deck",
                                note: "Fährt Skateboard, 8.0\" Breite",
                                budgetMin: 40, budgetMax: 70, status: .idea, tags: ["Sport", "Skateboard"]))

        // MARK: - Geschenkhistorie

        context.insert(GiftHistory(personId: max.id, title: "Craftbier-Paket 12er",
                                   category: "Getränke", year: year - 1, budget: 55,
                                   note: "War begeistert, verschiedene Sorten"))
        context.insert(GiftHistory(personId: max.id, title: "Koffer Samsonite 67cm",
                                   category: "Reise", year: year - 2, budget: 180,
                                   note: "Reist viel, sehr praktisch"))
        context.insert(GiftHistory(personId: erika.id, title: "Parfüm Chanel No. 5",
                                   category: "Kosmetik", year: year - 1, budget: 90,
                                   note: "Hat sie sehr gefreut"))
        context.insert(GiftHistory(personId: erika.id, title: "Aquarell-Set Winsor & Newton",
                                   category: "Kreativ", year: year - 2, budget: 65,
                                   note: "Malt als Hobby"))
        context.insert(GiftHistory(personId: anna.id, title: "Jagdmesser Victorinox",
                                   category: "Outdoor", year: year - 1, budget: 75,
                                   note: "Passt zu ihrem Outdoor-Hobby"))
        context.insert(GiftHistory(personId: thomas.id, title: "Garmin Forerunner 55",
                                   category: "Sport/Technik", year: year - 1, budget: 180,
                                   note: "Laufuhr, sehr zufrieden"))
        context.insert(GiftHistory(personId: sophie.id, title: "Wochenende in München",
                                   category: "Erlebnis/Reise", year: year - 1, budget: 420,
                                   note: "Gemeinsamer Trip, war wunderschön"))
        context.insert(GiftHistory(personId: sophie.id, title: "Apple AirPods Pro",
                                   category: "Technik", year: year - 2, budget: 249,
                                   note: "Benutzt sie täglich"))
        context.insert(GiftHistory(personId: emma.id, title: "LEGO Duplo Farm",
                                   category: "Spielzeug", year: year - 1, budget: 40,
                                   note: "Hat tagelang damit gespielt"))
        context.insert(GiftHistory(personId: paul.id, title: "Longboard Globe",
                                   category: "Sport", year: year - 1, budget: 110,
                                   note: "Fährt täglich damit zur Schule"))

        // MARK: - Reminder Rule
        context.insert(ReminderRule(leadDays: [30, 14, 7, 2],
                                    quietHoursStart: 22, quietHoursEnd: 8, enabled: true))
    }

    static func clearSampleData(in context: ModelContext) {
        do {
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
