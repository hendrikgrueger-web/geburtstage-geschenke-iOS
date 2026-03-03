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

        // MARK: - Personen

        let anna = PersonRef(contactIdentifier: "", displayName: "Anna Müller",
                             birthday: bday(daysFromNow: 3, age: 32), relation: "Schwester")
        let thomas = PersonRef(contactIdentifier: "", displayName: "Thomas Schmidt",
                               birthday: bday(daysFromNow: 8, age: 38), relation: "Freund")
        let lisa = PersonRef(contactIdentifier: "", displayName: "Lisa Weber",
                             birthday: bday(daysFromNow: 14, age: 29), relation: "Kollegin")
        let markus = PersonRef(contactIdentifier: "", displayName: "Markus Bauer",
                               birthday: bday(daysFromNow: 21, age: 45), relation: "Vater")
        let julia = PersonRef(contactIdentifier: "", displayName: "Julia Hoffmann",
                              birthday: bday(daysFromNow: 28, age: 26), relation: "Freundin")
        let stefan = PersonRef(contactIdentifier: "", displayName: "Stefan Keller",
                               birthday: bday(daysFromNow: 35, age: 41), relation: "Bruder")
        let sarah = PersonRef(contactIdentifier: "", displayName: "Sarah Fischer",
                              birthday: bday(daysFromNow: 52, age: 34), relation: "Freundin")
        let peter = PersonRef(contactIdentifier: "", displayName: "Peter Wagner",
                              birthday: bday(daysFromNow: 67, age: 58), relation: "Onkel")
        let lena = PersonRef(contactIdentifier: "", displayName: "Lena Braun",
                             birthday: bday(daysFromNow: 89, age: 23), relation: "Cousine")
        let michael = PersonRef(contactIdentifier: "", displayName: "Michael Schulz",
                                birthday: bday(daysFromNow: 112, age: 36), relation: "Kollege")
        let claudia = PersonRef(contactIdentifier: "", displayName: "Claudia Richter",
                                birthday: bday(daysFromNow: 145, age: 52), relation: "Mutter")
        let felix = PersonRef(contactIdentifier: "", displayName: "Felix Zimmermann",
                              birthday: bday(daysFromNow: 178, age: 17), relation: "Neffe")
        let nina = PersonRef(contactIdentifier: "", displayName: "Nina Schwarz",
                             birthday: bday(daysFromNow: 210, age: 31), relation: "Partnerin")
        let david = PersonRef(contactIdentifier: "", displayName: "David König",
                              birthday: bday(daysFromNow: 255, age: 44), relation: "Chef")
        let marie = PersonRef(contactIdentifier: "", displayName: "Marie Lange",
                              birthday: bday(daysFromNow: 300, age: 8), relation: "Nichte")

        let allPeople = [anna, thomas, lisa, markus, julia, stefan, sarah,
                         peter, lena, michael, claudia, felix, nina, david, marie]
        allPeople.forEach { context.insert($0) }

        // MARK: - Geschenkideen: Anna (Schwester, in 3 Tagen!)

        context.insert(GiftIdea(personId: anna.id, title: "Spa-Gutschein", note: "Liebt Wellness, am liebsten mit Massage",
                                budgetMin: 80, budgetMax: 120, status: .planned, tags: ["Wellness", "Erholung"]))
        context.insert(GiftIdea(personId: anna.id, title: "Seidenschal Hermès", note: "Mag klassische Muster, Farbe: Navy/Rot",
                                budgetMin: 150, budgetMax: 200, link: "https://www.hermes.com",
                                status: .purchased, tags: ["Mode", "Accessoires", "Luxus"]))
        context.insert(GiftIdea(personId: anna.id, title: "Kochkurs italienische Küche",
                                note: "Kocht gerne, liebt Pasta und Risotto",
                                budgetMin: 60, budgetMax: 90, status: .idea, tags: ["Erlebnis", "Kochen"]))

        // MARK: - Geschenkideen: Thomas (Freund, in 8 Tagen)

        context.insert(GiftIdea(personId: thomas.id, title: "Whisky Tasting Set",
                                note: "Mag Single Malt, am liebsten Islay",
                                budgetMin: 50, budgetMax: 80, status: .idea, tags: ["Alkohol", "Tasting"]))
        context.insert(GiftIdea(personId: thomas.id, title: "PlayStation 5 Controller",
                                note: "Hat PS5, braucht zweiten Controller",
                                budgetMin: 65, budgetMax: 75, link: "https://www.sony.com",
                                status: .planned, tags: ["Gaming", "Technik"]))
        context.insert(GiftIdea(personId: thomas.id, title: "Grill-Thermometer",
                                note: "Grillt viel im Sommer, Bluetooth-Modell wäre toll",
                                budgetMin: 30, budgetMax: 60, status: .idea, tags: ["Grillen", "Küche"]))

        // MARK: - Geschenkideen: Lisa (Kollegin, in 14 Tagen)

        context.insert(GiftIdea(personId: lisa.id, title: "Moleskine Notizbuch Set",
                                note: "Schreibt viel, mag gutes Papier",
                                budgetMin: 25, budgetMax: 40, status: .idea, tags: ["Büro", "Schreiben"]))
        context.insert(GiftIdea(personId: lisa.id, title: "Pflanzensamen & Töpfe",
                                note: "Hat viele Zimmerpflanzen, Sukkulenten würden passen",
                                budgetMin: 20, budgetMax: 35, status: .given, tags: ["Pflanzen", "Dekoration"]))

        // MARK: - Geschenkideen: Markus (Vater)

        context.insert(GiftIdea(personId: markus.id, title: "Bosch Akku-Bohrschrauber",
                                note: "Werkzeug immer willkommen, braucht 18V System",
                                budgetMin: 80, budgetMax: 130, link: "https://www.bosch.com",
                                status: .planned, tags: ["Werkzeug", "Heimwerken"]))
        context.insert(GiftIdea(personId: markus.id, title: "Weinpaket Bordeaux",
                                note: "Rotwein-Liebhaber, Jahrgang 2018-2020 bevorzugt",
                                budgetMin: 60, budgetMax: 100, status: .idea, tags: ["Wein", "Essen"]))
        context.insert(GiftIdea(personId: markus.id, title: "Angelrute Shimano",
                                note: "Angelt am Wochenende, Karpfenrute gesucht",
                                budgetMin: 100, budgetMax: 180, status: .idea, tags: ["Angeln", "Sport"]))

        // MARK: - Geschenkideen: Julia (Freundin)

        context.insert(GiftIdea(personId: julia.id, title: "Yoga-Matte Premium",
                                note: "Macht täglich Yoga, aktuelle Matte ist alt",
                                budgetMin: 50, budgetMax: 80, status: .idea, tags: ["Sport", "Yoga", "Gesundheit"]))
        context.insert(GiftIdea(personId: julia.id, title: "Olaplex Haarpflege Set",
                                note: "Färbt ihre Haare, braucht intensive Pflege",
                                budgetMin: 40, budgetMax: 60, status: .planned, tags: ["Pflege", "Haare", "Kosmetik"]))

        // MARK: - Geschenkideen: Stefan (Bruder)

        context.insert(GiftIdea(personId: stefan.id, title: "Laufschuhe Nike Pegasus",
                                note: "Läuft 3x/Woche, Größe 43, mag Neutral-Schuhe",
                                budgetMin: 100, budgetMax: 140, status: .idea, tags: ["Sport", "Laufen", "Schuhe"]))
        context.insert(GiftIdea(personId: stefan.id, title: "Spotify Premium 1 Jahr",
                                note: "Hört viel Musik, aktuell kein Abo",
                                budgetMin: 99, budgetMax: 99, status: .purchased, tags: ["Musik", "Streaming"]))

        // MARK: - Geschenkideen: Nina (Partnerin)

        context.insert(GiftIdea(personId: nina.id, title: "Kurzurlaub Prag",
                                note: "War noch nie in Prag, liebt Städtetrips",
                                budgetMin: 300, budgetMax: 500, status: .idea, tags: ["Reise", "Erlebnis", "Städtetrip"]))
        context.insert(GiftIdea(personId: nina.id, title: "Pandora Armband",
                                note: "Silber-Basis mit 2-3 Charms nach Wunsch",
                                budgetMin: 120, budgetMax: 200, link: "https://www.pandora.net",
                                status: .planned, tags: ["Schmuck", "Accessoires"]))
        context.insert(GiftIdea(personId: nina.id, title: "Kamera Fujifilm Instax",
                                note: "Mag Sofortbild-Fotos, Mini-Format",
                                budgetMin: 70, budgetMax: 100, status: .idea, tags: ["Foto", "Kreativ"]))

        // MARK: - Geschenkideen: Felix (Neffe, 17)

        context.insert(GiftIdea(personId: felix.id, title: "Nintendo Switch Spiel",
                                note: "Mag Zelda und Mario, kein Online-Abo nötig",
                                budgetMin: 45, budgetMax: 60, status: .idea, tags: ["Gaming", "Nintendo"]))
        context.insert(GiftIdea(personId: felix.id, title: "Skateboard Deck",
                                note: "Fährt Skateboard, 8.0\" Breite, eigene Achsen schon vorhanden",
                                budgetMin: 40, budgetMax: 70, status: .idea, tags: ["Sport", "Skateboard"]))

        // MARK: - Geschenkideen: Marie (Nichte, 8 Jahre)

        context.insert(GiftIdea(personId: marie.id, title: "LEGO Friends Eiscafé",
                                note: "Liebt LEGO Friends, Eiscafé-Set wäre perfekt",
                                budgetMin: 35, budgetMax: 55, status: .idea, tags: ["LEGO", "Spielzeug"]))
        context.insert(GiftIdea(personId: marie.id, title: "Einhorn-Rucksack",
                                note: "Schule, mag Einhörner und Lila",
                                budgetMin: 25, budgetMax: 40, status: .planned, tags: ["Schule", "Mode"]))

        // MARK: - Geschenkhistorie

        context.insert(GiftHistory(personId: anna.id, title: "Parfüm Chanel No. 5",
                                   category: "Kosmetik", year: year - 1, budget: 90,
                                   note: "Hat sie sehr gefreut, blumige Düfte liebt sie"))
        context.insert(GiftHistory(personId: anna.id, title: "Aquarell-Set Winsor & Newton",
                                   category: "Kreativ", year: year - 2, budget: 65,
                                   note: "Malt als Hobby"))
        context.insert(GiftHistory(personId: thomas.id, title: "Craftbier-Paket 12er",
                                   category: "Getränke", year: year - 1, budget: 55,
                                   note: "War begeistert, verschiedene Sorten"))
        context.insert(GiftHistory(personId: thomas.id, title: "Koffer Samsonite 67cm",
                                   category: "Reise", year: year - 2, budget: 180,
                                   note: "Reist viel, sehr praktisch"))
        context.insert(GiftHistory(personId: markus.id, title: "Kaffeemaschine DeLonghi",
                                   category: "Küche", year: year - 1, budget: 120,
                                   note: "Trinkt täglich Espresso"))
        context.insert(GiftHistory(personId: markus.id, title: "Jagdmesser Victorinox",
                                   category: "Outdoor", year: year - 3, budget: 75,
                                   note: "Passt zu seinem Outdoor-Hobby"))
        context.insert(GiftHistory(personId: julia.id, title: "Thermosflasche Stanley",
                                   category: "Sport", year: year - 1, budget: 45,
                                   note: "Nimmt sie überallhin mit"))
        context.insert(GiftHistory(personId: stefan.id, title: "Garmin Forerunner 55",
                                   category: "Sport/Technik", year: year - 1, budget: 180,
                                   note: "Laufuhr, sehr zufrieden"))
        context.insert(GiftHistory(personId: nina.id, title: "Wochenende in München",
                                   category: "Erlebnis/Reise", year: year - 1, budget: 420,
                                   note: "Gemeinsamer Trip, war wunderschön"))
        context.insert(GiftHistory(personId: nina.id, title: "Apple AirPods Pro",
                                   category: "Technik", year: year - 2, budget: 249,
                                   note: "Benutzt sie täglich"))
        context.insert(GiftHistory(personId: felix.id, title: "Longboard Globe",
                                   category: "Sport", year: year - 1, budget: 110,
                                   note: "Fährt täglich damit zur Schule"))
        context.insert(GiftHistory(personId: marie.id, title: "LEGO Duplo Farm",
                                   category: "Spielzeug", year: year - 1, budget: 40,
                                   note: "Hat tagelang damit gespielt"))

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
