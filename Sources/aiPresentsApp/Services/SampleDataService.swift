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

        let lang = Locale.current.language.languageCode?.identifier
        let isFR = lang == "fr"
        let isEN = lang != "de" && !isFR

        // --- Bald Geburtstag (Timeline sieht direkt gut aus) ---
        let max      = person("demo-max",    isFR ? "Jean Dupont"         : isEN ? "James Wilson"       : "Max Mustermann",        bday(0,   32), isFR ? "Ami"         : isEN ? "Friend"    : "Freund")
        let erika    = person("demo-erika",  isFR ? "Marie Martin"        : isEN ? "Emily Parker"       : "Erika Musterfrau",      bday(2,   38), isFR ? "Sœur"        : isEN ? "Sister"    : "Schwester")
        let hans     = person("demo-hans",   isFR ? "Pierre Bernard"      : isEN ? "David Thompson"     : "Hans Beispiel",         bday(5,   29), isFR ? "Collègue"    : isEN ? "Colleague" : "Kollege")
        let anna     = person("demo-anna",   isFR ? "Isabelle Lefebvre"   : isEN ? "Margaret Johnson"   : "Anna Muster",           bday(7,   45), isFR ? "Mère"        : isEN ? "Mother"    : "Mutter")
        let peter    = person("demo-peter",  isFR ? "Louis Moreau"        : isEN ? "Robert Davis"       : "Peter Beispielmann",    bday(12,  26), isFR ? "Frère"       : isEN ? "Brother"   : "Bruder")

        // --- Diese Woche / diesen Monat ---
        let lisa     = person("demo-lisa",   isFR ? "Camille Petit"       : isEN ? "Lisa Martinez"      : "Lisa Testmann",         bday(15,  41), isFR ? "Collègue"    : isEN ? "Colleague" : "Kollegin")
        let thomas   = person("demo-thomas", isFR ? "Thomas Leroy"        : isEN ? "Thomas Brown"       : "Thomas Muster",         bday(18,  34), isFR ? "Ami"         : isEN ? "Friend"    : "Freund")
        let julia    = person("demo-julia",  isFR ? "Julie Roux"          : isEN ? "Julia Anderson"     : "Julia Musterfrau",      bday(22,  27), isFR ? "Amie"        : isEN ? "Friend"    : "Freundin")
        let sophie   = person("demo-sophie", isFR ? "Sophie Dubois"       : isEN ? "Sophie Miller"      : "Sophie Beispiel",       bday(25,  31), isFR ? "Partenaire"  : isEN ? "Partner"   : "Partnerin")
        let michael  = person("demo-michael",isFR ? "Michel Garnier"      : isEN ? "Michael Taylor"     : "Michael Normalverb.",   bday(28,  50), isFR ? "Oncle"       : isEN ? "Uncle"     : "Onkel")

        // --- Nächste 2 Monate ---
        let maria    = person("demo-maria",  isFR ? "Martine Girard"      : isEN ? "Maria Garcia"       : "Maria Beispiel",        bday(35,  58), isFR ? "Tante"       : isEN ? "Aunt"      : "Tante")
        let felix    = person("demo-felix",  isFR ? "Félix Mercier"       : isEN ? "Felix Harris"       : "Felix Musterknabe",     bday(42,  23), isFR ? "Cousin"      : isEN ? "Cousin"    : "Cousin")
        let klara    = person("demo-klara",  isFR ? "Claire Fontaine"     : isEN ? "Clara Robinson"     : "Klara Beispielfrau",    bday(48,  36), isFR ? "Amie"        : isEN ? "Friend"    : "Freundin")
        let otto     = person("demo-otto",   isFR ? "René Chevalier"      : isEN ? "Richard Moore"      : "Otto Normalverbraucher",bday(55,  52), isFR ? "Père"        : isEN ? "Father"    : "Vater")
        let emma     = person("demo-emma",   isFR ? "Emma Laurent"        : isEN ? "Emma Wilson"        : "Emma Musterkind",       bday(62,   8), isFR ? "Nièce"       : isEN ? "Niece"     : "Nichte")
        let paul     = person("demo-paul",   isFR ? "Paul Simon"          : isEN ? "Paul Walker"        : "Paul Muster",           bday(68,  17), isFR ? "Neveu"       : isEN ? "Nephew"    : "Neffe")
        let kurt     = person("demo-kurt",   isFR ? "Marc Perrin"         : isEN ? "Kurt Reynolds"      : "Kurt Musterboss",       bday(75,  44), isFR ? "Chef"        : isEN ? "Boss"      : "Chef")
        let sarah    = person("demo-sarah",  isFR ? "Sarah Rousseau"      : isEN ? "Sarah Collins"      : "Sarah Beispielfrau",    bday(82,  33), isFR ? "Collègue"    : isEN ? "Colleague" : "Kollegin")
        let markus   = person("demo-markus", isFR ? "Marc Blanc"          : isEN ? "Marcus Reed"        : "Markus Testmann",       bday(88,  28), isFR ? "Ami"         : isEN ? "Friend"    : "Freund")
        let ingrid   = person("demo-ingrid", isFR ? "Françoise Dupuy"     : isEN ? "Dorothy Evans"      : "Ingrid Muster",         bday(95,  67), isFR ? "Grand-mère"  : isEN ? "Grandma"   : "Oma")

        // --- 3–6 Monate ---
        let gerhard  = person("demo-gerhard",isFR ? "Georges Morel"       : isEN ? "George Campbell"    : "Gerhard Beispiel",      bday(102, 70), isFR ? "Grand-père"  : isEN ? "Grandpa"   : "Opa")
        let nina     = person("demo-nina",   isFR ? "Nina Aubert"         : isEN ? "Nina Stewart"       : "Nina Musterfee",        bday(108, 22), isFR ? "Cousine"     : isEN ? "Cousin"    : "Cousine")
        let stefan   = person("demo-stefan", isFR ? "Stéphane Colin"      : isEN ? "Steven Cooper"      : "Stefan Beispielm.",     bday(115, 39), isFR ? "Frère"       : isEN ? "Brother"   : "Bruder")
        let lena     = person("demo-lena",   isFR ? "Léa Bertrand"        : isEN ? "Lena Brooks"        : "Lena Musterkind",       bday(120, 11), isFR ? "Nièce"       : isEN ? "Niece"     : "Nichte")
        let tobias   = person("demo-tobias", isFR ? "Thibault Renard"     : isEN ? "Toby Richardson"    : "Tobias Normalbürger",   bday(128, 25), isFR ? "Collègue"    : isEN ? "Colleague" : "Kollege")
        let petra    = person("demo-petra",  isFR ? "Patricia Vincent"    : isEN ? "Patricia Wood"      : "Petra Beispielfrau",    bday(135, 48), isFR ? "Tante"       : isEN ? "Aunt"      : "Tante")
        let daniel   = person("demo-daniel", isFR ? "Daniel Muller"       : isEN ? "Daniel Foster"      : "Daniel Muster",         bday(142, 30), isFR ? "Ami"         : isEN ? "Friend"    : "Freund")
        let monika   = person("demo-monika", isFR ? "Monique Faure"       : isEN ? "Monica Bell"        : "Monika Beispiel",       bday(149, 55), isFR ? "Mère"        : isEN ? "Mother"    : "Mutter")
        let jan      = person("demo-jan",    isFR ? "Julien Legrand"      : isEN ? "Jack Howard"        : "Jan Testmann",          bday(155, 21), isFR ? "Neveu"       : isEN ? "Nephew"    : "Neffe")
        let laura    = person("demo-laura",  isFR ? "Laura Bonnet"        : isEN ? "Laura Bennett"      : "Laura Musterfrau",      bday(162, 26), isFR ? "Amie"        : isEN ? "Friend"    : "Freundin")

        // --- 6–12 Monate ---
        let bernhard = person("demo-bernhard",isFR ? "Bernard Lacroix"   : isEN ? "Bernard Gray"      : "Bernhard Muster",       bday(168, 43), isFR ? "Oncle"       : isEN ? "Uncle"     : "Onkel")
        let karin    = person("demo-karin",  isFR ? "Karine Masson"       : isEN ? "Karen Price"        : "Karin Beispielfrau",    bday(175, 38), isFR ? "Collègue"    : isEN ? "Colleague" : "Kollegin")
        let florian  = person("demo-florian",isFR ? "Florian Bourgeois"   : isEN ? "Florian Ross"       : "Florian Normalv.",      bday(182, 19), isFR ? "Cousin"      : isEN ? "Cousin"    : "Cousin")
        let ursula   = person("demo-ursula", isFR ? "Ursule Guerin"       : isEN ? "Ruth Morgan"        : "Ursula Musterdame",     bday(188, 72), isFR ? "Grand-mère"  : isEN ? "Grandma"   : "Oma")
        let dominik  = person("demo-dominik",isFR ? "Dominique Olivier"   : isEN ? "Dominic Hayes"      : "Dominik Beispiel",      bday(195, 24), isFR ? "Ami"         : isEN ? "Friend"    : "Freund")
        let helga    = person("demo-helga",  isFR ? "Hélène Clement"      : isEN ? "Helen Peterson"     : "Helga Musterdame",      bday(200, 65), isFR ? "Tante"       : isEN ? "Aunt"      : "Tante")
        let patrick  = person("demo-patrick",isFR ? "Patrick Gauthier"    : isEN ? "Patrick Kelly"      : "Patrick Testperson",    bday(208, 31), isFR ? "Collègue"    : isEN ? "Colleague" : "Kollege")
        let andrea   = person("demo-andrea", isFR ? "Andrée Leroux"       : isEN ? "Andrea Mitchell"    : "Andrea Musterfrau",     bday(215, 46), isFR ? "Cheffe"      : isEN ? "Boss"      : "Chefin")
        let tim      = person("demo-tim",    isFR ? "Tim Barbier"         : isEN ? "Tim Sanders"        : "Tim Beispielkind",      bday(222, 14), isFR ? "Neveu"       : isEN ? "Nephew"    : "Neffe")
        let sandra   = person("demo-sandra", isFR ? "Sandra Arnaud"       : isEN ? "Sandra Cox"         : "Sandra Musterperson",   bday(228, 29), isFR ? "Amie"        : isEN ? "Friend"    : "Freundin")
        let christian = person("demo-christian",isFR ? "Christian Giraud" : isEN ? "Chris Murphy"    : "Christian Muster",       bday(235, 37), isFR ? "Frère"       : isEN ? "Brother"   : "Bruder")
        let brigitte = person("demo-brigitte",isFR ? "Brigitte Perrot"    : isEN ? "Barbara Russell"   : "Brigitte Beispiel",     bday(242, 61), isFR ? "Grand-mère"  : isEN ? "Grandma"   : "Oma")
        let oliver   = person("demo-oliver", isFR ? "Olivier Caron"       : isEN ? "Oliver Grant"       : "Oliver Normalverb.",    bday(248, 27), isFR ? "Ami"         : isEN ? "Friend"    : "Freund")
        let katrin   = person("demo-katrin", isFR ? "Catherine Noel"      : isEN ? "Katherine Lee"      : "Katrin Musterfrau",     bday(255, 34), isFR ? "Collègue"    : isEN ? "Colleague" : "Kollegin")
        let werner   = person("demo-werner", isFR ? "Werner Vidal"        : isEN ? "Walter Scott"       : "Werner Beispielm.",     bday(260, 58), isFR ? "Oncle"       : isEN ? "Uncle"     : "Onkel")
        let melanie  = person("demo-melanie",isFR ? "Mélanie Schmitt"     : isEN ? "Melanie Young"      : "Melanie Musterperson",  bday(268, 23), isFR ? "Cousine"     : isEN ? "Cousin"    : "Cousine")
        let hubert   = person("demo-hubert", isFR ? "Hubert Marchand"     : isEN ? "Herbert King"       : "Hubert Normalverb.",    bday(275, 74), isFR ? "Grand-père"  : isEN ? "Grandpa"   : "Opa")
        let tanja    = person("demo-tanja",  isFR ? "Tania Lemaire"       : isEN ? "Tanya Adams"        : "Tanja Beispielfrau",    bday(280, 41), isFR ? "Amie"        : isEN ? "Friend"    : "Freundin")
        let Sebastian = person("demo-sebastian",isFR ? "Sébastien Brunet" : isEN ? "Sebastian Clark" : "Sebastian Muster",       bday(290, 33), isFR ? "Ami"         : isEN ? "Friend"    : "Freund")
        let irene    = person("demo-irene",  isFR ? "Irène Dumont"        : isEN ? "Irene Wright"       : "Irene Musterdame",      bday(350, 69), isFR ? "Tante"       : isEN ? "Aunt"      : "Tante")

        // Test: Geburtstag gestern + gekauftes Geschenk → Auto-Transition testen
        let gestern  = person("demo-gestern",isFR ? "Hier Anniversaire"  : isEN ? "Yesterday Birthday" : "Gestern Geburtstag",   bday(-1, 30), isFR ? "Ami" : isEN ? "Friend" : "Freund")

        let allPeople: [PersonRef] = [
            max, erika, hans, anna, peter, lisa, thomas, julia, sophie, michael,
            maria, felix, klara, otto, emma, paul, kurt, sarah, markus, ingrid,
            gerhard, nina, stefan, lena, tobias, petra, daniel, monika, jan, laura,
            bernhard, karin, florian, ursula, dominik, helga, patrick, andrea, tim, sandra,
            christian, brigitte, oliver, katrin, werner, melanie, hubert, tanja, Sebastian, irene,
            gestern
        ]
        // Demo-Hobbies fuer einige Personen
        max.hobbies = isFR ? ["Cuisine", "Whisky", "Barbecue"] : isEN ? ["Cooking", "Whisky", "BBQ"] : ["Kochen", "Whisky", "Grillen"]
        erika.hobbies = isFR ? ["Yoga", "Bien-être", "Aquarelle"] : isEN ? ["Yoga", "Wellness", "Watercolor"] : ["Yoga", "Wellness", "Aquarell"]
        sophie.hobbies = isFR ? ["Photographie", "Voyages", "Lecture"] : isEN ? ["Photography", "Travel", "Reading"] : ["Fotografie", "Reisen", "Lesen"]
        anna.hobbies = isFR ? ["Vin", "Jardinage", "Cuisine"] : isEN ? ["Wine", "Gardening", "Cooking"] : ["Wein", "Garten", "Kochen"]
        thomas.hobbies = isFR ? ["Course à pied", "Technologie", "Jeux vidéo"] : isEN ? ["Running", "Tech", "Gaming"] : ["Laufen", "Technik", "Gaming"]
        emma.hobbies = isFR ? ["LEGO", "Bricolage", "Dessin"] : isEN ? ["LEGO", "Crafts", "Drawing"] : ["LEGO", "Basteln", "Malen"]

        allPeople.forEach { context.insert($0) }

        // MARK: - Geschenkideen

        // Max / Jean (Ami, Anniversaire AUJOURD'HUI)
        idea(max, isFR ? "Coffret Dégustation Whisky" : isEN ? "Whisky Tasting Set" : "Whisky Tasting Set", isFR ? "Adore le Single Malt Islay" : isEN ? "Loves Single Malt Islay" : "Mag Single Malt Islay", 50, 80, .idea, isFR ? ["Alcool", "Dégustation"] : isEN ? ["Drinks", "Tasting"] : ["Alkohol", "Tasting"], context)
        idea(max, isFR ? "Cours de cuisine Pasta & Risotto" : isEN ? "Pasta & Risotto Cooking Class" : "Kochkurs Pasta & Risotto", isFR ? "Cuisinier passionné" : isEN ? "Passionate home cook" : "Kocht leidenschaftlich gerne", 60, 90, .planned, isFR ? ["Expérience", "Cuisine"] : isEN ? ["Experience", "Cooking"] : ["Erlebnis", "Kochen"], context)
        idea(max, isFR ? "Thermomètre BBQ Bluetooth" : isEN ? "Bluetooth BBQ Thermometer" : "Grill-Thermometer Bluetooth", isFR ? "Fait beaucoup de barbecue en été" : isEN ? "Grills a lot in summer" : "Grillt viel im Sommer", 30, 60, .idea, isFR ? ["Barbecue", "Cuisine"] : isEN ? ["BBQ", "Kitchen"] : ["Grillen", "Küche"], context)

        // Erika / Marie (Sœur, dans 2 jours)
        idea(erika, isFR ? "Bon Spa" : isEN ? "Spa Voucher" : "Spa-Gutschein", isFR ? "Adore le bien-être et les massages" : isEN ? "Loves wellness and massages" : "Liebt Wellness und Massagen", 80, 120, .planned, ["Wellness"], context)
        idea(erika, isFR ? "Tapis de Yoga Manduka PRO" : isEN ? "Manduka PRO Yoga Mat" : "Yoga-Matte Manduka PRO", isFR ? "Fait du yoga quotidiennement" : isEN ? "Does yoga daily" : "Macht täglich Yoga", 50, 80, .idea, isFR ? ["Sport", "Yoga"] : isEN ? ["Fitness", "Yoga"] : ["Sport", "Yoga"], context)

        // Sophie (Partenaire)
        idea(sophie, isFR ? "Week-end à Paris" : isEN ? "Weekend Trip to Prague" : "Kurzurlaub Prag", isFR ? "Adore les escapades en amoureux" : isEN ? "Never been to Prague" : "War noch nie in Prag", 300, 500, .idea, isFR ? ["Voyage", "Expérience"] : isEN ? ["Travel", "Experience"] : ["Reise", "Erlebnis"], context)
        idea(sophie, isFR ? "Fujifilm Instax Mini 12" : isEN ? "Fujifilm Instax Mini 12" : "Fujifilm Instax Mini 12", isFR ? "Adore les photos instantanées" : isEN ? "Loves instant photos" : "Mag Sofortbild-Fotos", 70, 100, .planned, isFR ? ["Photo", "Créatif"] : isEN ? ["Photo", "Creative"] : ["Foto", "Kreativ"], context)

        // Anna / Isabelle (Mère)
        idea(anna, isFR ? "Coffret Vin Bordeaux" : isEN ? "Bordeaux Wine Collection" : "Weinpaket Bordeaux", isFR ? "Amatrice de vin rouge, millésime 2019" : isEN ? "Red wine lover, 2019 vintage" : "Rotwein-Liebhaberin, Jahrgang 2019", 60, 100, .idea, isFR ? ["Vin"] : isEN ? ["Wine"] : ["Wein"], context)
        idea(anna, isFR ? "Machine à Expresso DeLonghi" : isEN ? "DeLonghi Espresso Machine" : "Kaffeemaschine DeLonghi", isFR ? "Boit un espresso tous les jours" : isEN ? "Drinks espresso daily" : "Trinkt täglich Espresso", 100, 150, .idea, isFR ? ["Cuisine", "Café"] : isEN ? ["Kitchen", "Coffee"] : ["Küche", "Kaffee"], context)

        // Otto / René (Père)
        idea(otto, isFR ? "Perceuse Bosch sans fil" : isEN ? "Bosch Cordless Drill" : "Bosch Akku-Bohrschrauber", isFR ? "Système 18V, adore le bricolage" : isEN ? "18V system, loves DIY" : "18V System, heimwerkert viel", 80, 130, .planned, isFR ? ["Outils"] : isEN ? ["Tools"] : ["Werkzeug"], context)

        // Emma (Nièce, 8 ans)
        idea(emma, isFR ? "LEGO Friends Salon de Glace" : isEN ? "LEGO Friends Ice Cream Parlor" : "LEGO Friends Eiscafé", isFR ? "Adore les sets LEGO Friends" : isEN ? "Loves LEGO Friends sets" : "Liebt LEGO Friends Sets", 35, 55, .idea, isFR ? ["LEGO", "Jouets"] : isEN ? ["LEGO", "Toys"] : ["LEGO", "Spielzeug"], context)
        idea(emma, isFR ? "Sac à Dos Licorne" : isEN ? "Unicorn Backpack" : "Einhorn-Rucksack", isFR ? "Adore les licornes et le violet" : isEN ? "Loves unicorns and purple" : "Mag Einhörner und Lila", 25, 40, .planned, isFR ? ["École"] : isEN ? ["School"] : ["Schule"], context)

        // Paul (Neveu, 17 ans)
        idea(paul, isFR ? "Nintendo Switch Zelda: Echoes of Wisdom" : isEN ? "Nintendo Switch Zelda: Echoes of Wisdom" : "Nintendo Switch Zelda: Echoes of Wisdom", isFR ? "Fan de la série Zelda" : isEN ? "Loves the Zelda series" : "Mag Zelda-Serie", 45, 60, .idea, ["Gaming"], context)
        idea(paul, isFR ? "Planche de Skate Powell" : isEN ? "Powell Skateboard Deck" : "Skateboard Deck Powell", isFR ? "Fait du skate, 8.0\"" : isEN ? "Skateboards, 8.0\"" : "Fährt Skateboard, 8.0\"", 40, 70, .idea, isFR ? ["Sport", "Skateboard"] : isEN ? ["Sports", "Skateboard"] : ["Sport", "Skateboard"], context)

        // Hans / Pierre (Collègue)
        idea(hans, isFR ? "Carnet Moleskine XL" : isEN ? "Moleskine XL Notebook" : "Moleskine Notizbuch XL", isFR ? "Écrit beaucoup, apprécie le bon papier" : isEN ? "Writes a lot, likes quality paper" : "Schreibt viel, mag gutes Papier", 25, 40, .idea, isFR ? ["Bureau"] : isEN ? ["Office"] : ["Büro"], context)

        // Thomas (Ami)
        idea(thomas, isFR ? "Garmin Forerunner 265" : isEN ? "Garmin Forerunner 265" : "Garmin Forerunner 265", isFR ? "Court des semi-marathons" : isEN ? "Runs half marathons" : "Läuft Halbmarathon", 280, 350, .idea, isFR ? ["Sport", "Tech"] : isEN ? ["Sports", "Tech"] : ["Sport", "Technik"], context)

        // Andrea (Cheffe)
        idea(andrea, isFR ? "Tasse en Porcelaine Artisanale" : isEN ? "Handmade Porcelain Mug" : "Porzellan-Tasse handgemacht", isFR ? "Boit toujours du thé au bureau" : isEN ? "Always drinks tea at the office" : "Trinkt immer Tee im Büro", 30, 50, .idea, isFR ? ["Bureau", "Vaisselle"] : isEN ? ["Office", "Ceramics"] : ["Büro", "Geschirr"], context)

        // Maria / Martine (Tante)
        idea(maria, isFR ? "Kit d'Herbes Aromatiques" : isEN ? "Garden Herb Kit" : "Garten-Kräuterset", isFR ? "Grand jardin, cuisine avec des herbes fraîches" : isEN ? "Has a big garden, cooks with fresh herbs" : "Hat großen Garten, kocht mit frischen Kräutern", 30, 50, .idea, isFR ? ["Jardin", "Cuisine"] : isEN ? ["Garden", "Cooking"] : ["Garten", "Kochen"], context)

        // Gestern (Auto-Transition Test: purchased → given)
        idea(gestern, isFR ? "Enceinte Bluetooth JBL" : isEN ? "JBL Bluetooth Speaker" : "Bluetooth-Lautsprecher JBL", isFR ? "Adore la musique" : isEN ? "Loves music" : "Mag Musik", 50, 80, .purchased, isFR ? ["Tech", "Musique"] : isEN ? ["Tech", "Music"] : ["Technik", "Musik"], context)

        // MARK: - Geschenkhistorie

        hist(max, isFR ? "Pack Bières Artisanales 12" : isEN ? "Craft Beer 12-Pack" : "Craftbier-Paket 12er", isFR ? "Boissons" : isEN ? "Drinks" : "Getränke", year-1, 55, isFR ? "Était ravi" : isEN ? "Was thrilled" : "War begeistert", context)
        hist(max, isFR ? "Valise Samsonite 67cm" : isEN ? "Samsonite Suitcase 26\"" : "Koffer Samsonite 67cm", isFR ? "Voyage" : isEN ? "Travel" : "Reise", year-2, 180, isFR ? "Voyage beaucoup, très pratique" : isEN ? "Travels a lot, very practical" : "Reist viel, sehr praktisch", context)
        hist(erika, isFR ? "Parfum Chanel No. 5" : isEN ? "Chanel No. 5 Perfume" : "Parfüm Chanel No. 5", isFR ? "Beauté" : isEN ? "Beauty" : "Kosmetik", year-1, 90, isFR ? "Elle a adoré" : isEN ? "She loved it" : "Hat sie sehr gefreut", context)
        hist(erika, isFR ? "Set Aquarelle Winsor & Newton" : isEN ? "Winsor & Newton Watercolor Set" : "Aquarell-Set Winsor & Newton", isFR ? "Créatif" : isEN ? "Creative" : "Kreativ", year-2, 65, isFR ? "Peint en loisir" : isEN ? "Paints as a hobby" : "Malt als Hobby", context)
        hist(anna, isFR ? "Couteau Victorinox Outdoor" : isEN ? "Victorinox Outdoor Knife" : "Jagdmesser Victorinox", "Outdoor", year-1, 75, isFR ? "Loisir outdoor" : isEN ? "Outdoor hobby" : "Outdoor-Hobby", context)
        hist(thomas, "Garmin Forerunner 55", isFR ? "Sport/Tech" : isEN ? "Sports/Tech" : "Sport/Technik", year-1, 180, isFR ? "Montre de course, très content" : isEN ? "Running watch, very happy" : "Laufuhr, sehr zufrieden", context)
        hist(sophie, isFR ? "Week-end à Lyon" : isEN ? "Weekend in Munich" : "Wochenende in München", isFR ? "Expérience/Voyage" : isEN ? "Experience/Travel" : "Erlebnis/Reise", year-1, 420, isFR ? "C'était magnifique" : isEN ? "Was wonderful" : "War wunderschön", context)
        hist(sophie, "Apple AirPods Pro", isFR ? "Tech" : isEN ? "Tech" : "Technik", year-2, 249, isFR ? "Utilise tous les jours" : isEN ? "Uses them daily" : "Benutzt täglich", context)
        hist(emma, "LEGO Duplo Farm", isFR ? "Jouets" : isEN ? "Toys" : "Spielzeug", year-1, 40, isFR ? "A joué pendant des jours" : isEN ? "Played with it for days" : "Tagelang gespielt", context)
        hist(paul, "Longboard Globe", isFR ? "Sport" : isEN ? "Sports" : "Sport", year-1, 110, isFR ? "Va à l'école avec tous les jours" : isEN ? "Rides it to school daily" : "Fährt täglich zur Schule", context)
        hist(otto, "Weber Grill Q1200", isFR ? "Barbecue" : isEN ? "BBQ" : "Grillen", year-1, 160, isFR ? "Fait des barbecues chaque été" : isEN ? "Grills every summer" : "Grillt jeden Sommer", context)
        hist(peter, "Kindle Paperwhite", isFR ? "Tech/Livres" : isEN ? "Tech/Books" : "Technik/Bücher", year-1, 120, isFR ? "Lit beaucoup, très pratique" : isEN ? "Reads a lot, very practical" : "Liest viel, sehr praktisch", context)
        hist(ingrid, isFR ? "Vol en Montgolfière pour Deux" : isEN ? "Hot Air Balloon Ride for Two" : "Ballonfahrt für zwei", isFR ? "Expérience" : isEN ? "Experience" : "Erlebnis", year-1, 210, isFR ? "Un rêve devenu réalité" : isEN ? "A dream come true" : "War ein Traum", context)
        hist(kurt, "Lamy Pen & Pencil Set", isFR ? "Bureau" : isEN ? "Office" : "Büro", year-1, 85, isFR ? "Utilise tous les jours au bureau" : isEN ? "Uses it daily at the office" : "Benutzt täglich im Büro", context)

        // Erhaltene Geschenke (received)
        hist(max, isFR ? "Casque Bluetooth Sony" : isEN ? "Sony Bluetooth Headphones" : "Bluetooth-Kopfhörer Sony", isFR ? "Tech" : isEN ? "Tech" : "Technik", year-1, 120, isFR ? "Cadeau d'anniversaire" : isEN ? "Birthday gift" : "Zum Geburtstag bekommen", context, direction: .received)
        hist(erika, isFR ? "Bougie Artisanale" : isEN ? "Handmade Candle" : "Handgemachte Kerze", isFR ? "Déco" : isEN ? "Decor" : "Deko", year-1, 25, isFR ? "Cadeau de Noël" : isEN ? "Christmas gift" : "Weihnachtsgeschenk", context, direction: .received)
        hist(sophie, isFR ? "Album Photo Bilan de l'Année" : isEN ? "Year in Review Photo Book" : "Fotobuch Jahresrückblick", isFR ? "Créatif" : isEN ? "Creative" : "Kreativ", year-1, 45, isFR ? "Très personnel, magnifique" : isEN ? "Very personal, beautiful" : "Sehr persönlich, wunderschön", context, direction: .received)

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

