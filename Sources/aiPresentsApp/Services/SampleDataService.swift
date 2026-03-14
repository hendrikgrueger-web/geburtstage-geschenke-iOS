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
        let isES = lang == "es"
        let isEN = lang != "de" && !isFR && !isES

        // --- Bald Geburtstag (Timeline sieht direkt gut aus) ---
        let max      = person("demo-max",    isFR ? "Jean Dupont"         : isES ? "Carlos García"      : isEN ? "James Wilson"       : "Lukas Brenner",         bday(0,   32), isFR ? "Ami"         : isES ? "Amigo"     : isEN ? "Friend"    : "Freund")
        let erika    = person("demo-erika",  isFR ? "Marie Martin"        : isES ? "María López"        : isEN ? "Emily Parker"       : "Sarah Yılmaz",          bday(2,   38), isFR ? "Sœur"        : isES ? "Hermana"   : isEN ? "Sister"    : "Schwester")
        let hans     = person("demo-hans",   isFR ? "Pierre Bernard"      : isES ? "Pedro Martínez"     : isEN ? "David Thompson"     : "Niklas Weber",          bday(5,   29), isFR ? "Collègue"    : isES ? "Colega"    : isEN ? "Colleague" : "Kollege")
        let anna     = person("demo-anna",   isFR ? "Isabelle Lefebvre"   : isES ? "Ana Rodríguez"      : isEN ? "Margaret Johnson"   : "Claudia Richter",       bday(7,   45), isFR ? "Mère"        : isES ? "Madre"     : isEN ? "Mother"    : "Mutter")
        let peter    = person("demo-peter",  isFR ? "Louis Moreau"        : isES ? "Luis Hernández"     : isEN ? "Robert Davis"       : "Emre Kaya",             bday(12,  26), isFR ? "Frère"       : isES ? "Hermano"   : isEN ? "Brother"   : "Bruder")

        // --- Diese Woche / diesen Monat ---
        let lisa     = person("demo-lisa",   isFR ? "Camille Petit"       : isES ? "Sofia Torres"       : isEN ? "Lisa Martinez"      : "Jana Hofmann",          bday(15,  41), isFR ? "Collègue"    : isES ? "Colega"    : isEN ? "Colleague" : "Kollegin")
        let thomas   = person("demo-thomas", isFR ? "Thomas Leroy"        : isES ? "Miguel Fernández"   : isEN ? "Thomas Brown"       : "Finn Becker",           bday(18,  34), isFR ? "Ami"         : isES ? "Amigo"     : isEN ? "Friend"    : "Freund")
        let julia    = person("demo-julia",  isFR ? "Julie Roux"          : isES ? "Julia Sánchez"      : isEN ? "Julia Anderson"     : "Leyla Demir",           bday(22,  27), isFR ? "Amie"        : isES ? "Amiga"     : isEN ? "Friend"    : "Freundin")
        let sophie   = person("demo-sophie", isFR ? "Sophie Dubois"       : isES ? "Carmen Díaz"        : isEN ? "Sophie Miller"      : "Lina Schäfer",          bday(25,  31), isFR ? "Partenaire"  : isES ? "Pareja"    : isEN ? "Partner"   : "Partnerin")
        let michael  = person("demo-michael",isFR ? "Michel Garnier"      : isES ? "Antonio García"     : isEN ? "Michael Taylor"     : "Andreas Krüger",        bday(28,  50), isFR ? "Oncle"       : isES ? "Tío"       : isEN ? "Uncle"     : "Onkel")

        // --- Nächste 2 Monate ---
        let maria    = person("demo-maria",  isFR ? "Martine Girard"      : isES ? "Elena Moreno"       : isEN ? "Maria Garcia"       : "Renate Fischer",        bday(35,  58), isFR ? "Tante"       : isES ? "Tía"       : isEN ? "Aunt"      : "Tante")
        let felix    = person("demo-felix",  isFR ? "Félix Mercier"       : isES ? "Diego López"        : isEN ? "Felix Harris"       : "Moritz Lange",          bday(42,  23), isFR ? "Cousin"      : isES ? "Primo"     : isEN ? "Cousin"    : "Cousin")
        let klara    = person("demo-klara",  isFR ? "Claire Fontaine"     : isES ? "Clara Jiménez"      : isEN ? "Clara Robinson"     : "Aylin Özdemir",         bday(48,  36), isFR ? "Amie"        : isES ? "Amiga"     : isEN ? "Friend"    : "Freundin")
        let otto     = person("demo-otto",   isFR ? "René Chevalier"      : isES ? "Roberto Torres"     : isEN ? "Richard Moore"      : "Wolfgang Hartmann",     bday(55,  52), isFR ? "Père"        : isES ? "Padre"     : isEN ? "Father"    : "Vater")
        let emma     = person("demo-emma",   isFR ? "Emma Laurent"        : isES ? "Lucía García"       : isEN ? "Emma Wilson"        : "Mia Schröder",          bday(62,   8), isFR ? "Nièce"       : isES ? "Sobrina"   : isEN ? "Niece"     : "Nichte")
        let paul     = person("demo-paul",   isFR ? "Paul Simon"          : isES ? "Pablo Martínez"     : isEN ? "Paul Walker"        : "Noah Wagner",           bday(68,  17), isFR ? "Neveu"       : isES ? "Sobrino"   : isEN ? "Nephew"    : "Neffe")
        let kurt     = person("demo-kurt",   isFR ? "Marc Perrin"         : isES ? "Javier Ruiz"        : isEN ? "Kurt Reynolds"      : "Stefan Braun",          bday(75,  44), isFR ? "Chef"        : isES ? "Jefe"      : isEN ? "Boss"      : "Chef")
        let sarah    = person("demo-sarah",  isFR ? "Sarah Rousseau"      : isES ? "Sara Gómez"         : isEN ? "Sarah Collins"      : "Celine Berger",         bday(82,  33), isFR ? "Collègue"    : isES ? "Colega"    : isEN ? "Colleague" : "Kollegin")
        let markus   = person("demo-markus", isFR ? "Marc Blanc"          : isES ? "Marcos Pérez"       : isEN ? "Marcus Reed"        : "Tim Schulz",            bday(88,  28), isFR ? "Ami"         : isES ? "Amigo"     : isEN ? "Friend"    : "Freund")
        let ingrid   = person("demo-ingrid", isFR ? "Françoise Dupuy"     : isES ? "Isabel Fernández"   : isEN ? "Dorothy Evans"      : "Hannelore Müller",      bday(95,  67), isFR ? "Grand-mère"  : isES ? "Abuela"    : isEN ? "Grandma"   : "Oma")

        // --- 3–6 Monate ---
        let gerhard  = person("demo-gerhard",isFR ? "Georges Morel"       : isES ? "Gerardo López"      : isEN ? "George Campbell"    : "Heinrich Vogel",        bday(102, 70), isFR ? "Grand-père"  : isES ? "Abuelo"    : isEN ? "Grandpa"   : "Opa")
        let nina     = person("demo-nina",   isFR ? "Nina Aubert"         : isES ? "Nina Vargas"        : isEN ? "Nina Stewart"       : "Nina Petersen",         bday(108, 22), isFR ? "Cousine"     : isES ? "Prima"     : isEN ? "Cousin"    : "Cousine")
        let stefan   = person("demo-stefan", isFR ? "Stéphane Colin"      : isES ? "Esteban Castro"     : isEN ? "Steven Cooper"      : "Kai Lehmann",           bday(115, 39), isFR ? "Frère"       : isES ? "Hermano"   : isEN ? "Brother"   : "Bruder")
        let lena     = person("demo-lena",   isFR ? "Léa Bertrand"        : isES ? "Valentina Ramos"    : isEN ? "Lena Brooks"        : "Elif Çelik",            bday(120, 11), isFR ? "Nièce"       : isES ? "Sobrina"   : isEN ? "Niece"     : "Nichte")
        let tobias   = person("demo-tobias", isFR ? "Thibault Renard"     : isES ? "Tomás Herrera"      : isEN ? "Toby Richardson"    : "Tobias Kern",           bday(128, 25), isFR ? "Collègue"    : isES ? "Colega"    : isEN ? "Colleague" : "Kollege")
        let petra    = person("demo-petra",  isFR ? "Patricia Vincent"    : isES ? "Patricia Vega"      : isEN ? "Patricia Wood"      : "Petra Zimmermann",      bday(135, 48), isFR ? "Tante"       : isES ? "Tía"       : isEN ? "Aunt"      : "Tante")
        let daniel   = person("demo-daniel", isFR ? "Daniel Muller"       : isES ? "Daniel Ortega"      : isEN ? "Daniel Foster"      : "Daniel Koch",           bday(142, 30), isFR ? "Ami"         : isES ? "Amigo"     : isEN ? "Friend"    : "Freund")
        let monika   = person("demo-monika", isFR ? "Monique Faure"       : isES ? "Mónica Reyes"       : isEN ? "Monica Bell"        : "Monika Weiß",           bday(149, 55), isFR ? "Mère"        : isES ? "Madre"     : isEN ? "Mother"    : "Mutter")
        let jan      = person("demo-jan",    isFR ? "Julien Legrand"      : isES ? "Juan Delgado"       : isEN ? "Jack Howard"        : "Jan Neumann",           bday(155, 21), isFR ? "Neveu"       : isES ? "Sobrino"   : isEN ? "Nephew"    : "Neffe")
        let laura    = person("demo-laura",  isFR ? "Laura Bonnet"        : isES ? "Laura Romero"       : isEN ? "Laura Bennett"      : "Laura Engel",           bday(162, 26), isFR ? "Amie"        : isES ? "Amiga"     : isEN ? "Friend"    : "Freundin")

        // --- 6–12 Monate ---
        let bernhard = person("demo-bernhard",isFR ? "Bernard Lacroix"   : isES ? "Bernardo Cruz"     : isEN ? "Bernard Gray"      : "Bernd Schneider",       bday(168, 43), isFR ? "Oncle"       : isES ? "Tío"       : isEN ? "Uncle"     : "Onkel")
        let karin    = person("demo-karin",  isFR ? "Karine Masson"       : isES ? "Carolina Flores"    : isEN ? "Karen Price"        : "Karin Lorenz",          bday(175, 38), isFR ? "Collègue"    : isES ? "Colega"    : isEN ? "Colleague" : "Kollegin")
        let florian  = person("demo-florian",isFR ? "Florian Bourgeois"   : isES ? "Florián Mendoza"    : isEN ? "Florian Ross"       : "Florian Haas",          bday(182, 19), isFR ? "Cousin"      : isES ? "Primo"     : isEN ? "Cousin"    : "Cousin")
        let ursula   = person("demo-ursula", isFR ? "Ursule Guerin"       : isES ? "Úrsula Morales"     : isEN ? "Ruth Morgan"        : "Gisela Franke",         bday(188, 72), isFR ? "Grand-mère"  : isES ? "Abuela"    : isEN ? "Grandma"   : "Oma")
        let dominik  = person("demo-dominik",isFR ? "Dominique Olivier"   : isES ? "Dominik Guzmán"     : isEN ? "Dominic Hayes"      : "Dennis Arslan",         bday(195, 24), isFR ? "Ami"         : isES ? "Amigo"     : isEN ? "Friend"    : "Freund")
        let helga    = person("demo-helga",  isFR ? "Hélène Clement"      : isES ? "Helena Castillo"    : isEN ? "Helen Peterson"     : "Dennis Baumann",        bday(200, 32), isFR ? "Collègue"    : isES ? "Colega"    : isEN ? "Colleague" : "Kollege")
        let patrick  = person("demo-patrick",isFR ? "Patrick Gauthier"    : isES ? "Patricio Ibáñez"    : isEN ? "Patrick Kelly"      : "Patrick Roth",          bday(208, 31), isFR ? "Collègue"    : isES ? "Colega"    : isEN ? "Colleague" : "Kollege")
        let andrea   = person("demo-andrea", isFR ? "Andrée Leroux"       : isES ? "Andrea Silva"       : isEN ? "Andrea Mitchell"    : "Andrea Wolff",          bday(215, 46), isFR ? "Cheffe"      : isES ? "Jefa"      : isEN ? "Boss"      : "Chefin")
        let tim      = person("demo-tim",    isFR ? "Tim Barbier"         : isES ? "Timoteo Varela"     : isEN ? "Tim Sanders"        : "Tim Scholz",            bday(222, 14), isFR ? "Neveu"       : isES ? "Sobrino"   : isEN ? "Nephew"    : "Neffe")
        let sandra   = person("demo-sandra", isFR ? "Sandra Arnaud"       : isES ? "Sandra Ríos"        : isEN ? "Sandra Cox"         : "Sandra Meier",          bday(228, 29), isFR ? "Amie"        : isES ? "Amiga"     : isEN ? "Friend"    : "Freundin")
        let christian = person("demo-christian",isFR ? "Christian Giraud" : isES ? "Cristian Navarro" : isEN ? "Chris Murphy"    : "Christian Seidel",       bday(235, 37), isFR ? "Frère"       : isES ? "Hermano"   : isEN ? "Brother"   : "Bruder")
        let brigitte = person("demo-brigitte",isFR ? "Brigitte Perrot"    : isES ? "Brigida Santos"    : isEN ? "Barbara Russell"   : "Brigitte Huber",        bday(242, 61), isFR ? "Grand-mère"  : isES ? "Abuela"    : isEN ? "Grandma"   : "Oma")
        let oliver   = person("demo-oliver", isFR ? "Olivier Caron"       : isES ? "Oliver Serrano"     : isEN ? "Oliver Grant"       : "Oliver Jansen",         bday(248, 27), isFR ? "Ami"         : isES ? "Amigo"     : isEN ? "Friend"    : "Freund")
        let katrin   = person("demo-katrin", isFR ? "Catherine Noel"      : isES ? "Catalina León"      : isEN ? "Katherine Lee"      : "Katrin Vogt",           bday(255, 34), isFR ? "Collègue"    : isES ? "Colega"    : isEN ? "Colleague" : "Kollegin")
        let werner   = person("demo-werner", isFR ? "Werner Vidal"        : isES ? "Wenceslao Vera"     : isEN ? "Walter Scott"       : "Werner Dietrich",       bday(260, 58), isFR ? "Oncle"       : isES ? "Tío"       : isEN ? "Uncle"     : "Onkel")
        let melanie  = person("demo-melanie",isFR ? "Mélanie Schmitt"     : isES ? "Melania Blanco"     : isEN ? "Melanie Young"      : "Melanie Krause",        bday(268, 23), isFR ? "Cousine"     : isES ? "Prima"     : isEN ? "Cousin"    : "Cousine")
        let hubert   = person("demo-hubert", isFR ? "Hubert Marchand"     : isES ? "Huberto Aguilar"    : isEN ? "Herbert King"       : "Herbert Schuster",      bday(275, 74), isFR ? "Grand-père"  : isES ? "Abuelo"    : isEN ? "Grandpa"   : "Opa")
        let tanja    = person("demo-tanja",  isFR ? "Tania Lemaire"       : isES ? "Tania Molina"       : isEN ? "Tanya Adams"        : "Tanja Böhm",            bday(280, 41), isFR ? "Amie"        : isES ? "Amiga"     : isEN ? "Friend"    : "Freundin")
        let Sebastian = person("demo-sebastian",isFR ? "Sébastien Brunet" : isES ? "Sebastián Parra"  : isEN ? "Sebastian Clark" : "Sebastian Pfeiffer",     bday(290, 33), isFR ? "Ami"         : isES ? "Amigo"     : isEN ? "Friend"    : "Freund")
        let irene    = person("demo-irene",  isFR ? "Irène Dumont"        : isES ? "Irene Cabrera"      : isEN ? "Irene Wright"       : "Irene Schwarz",         bday(350, 69), isFR ? "Tante"       : isES ? "Tía"       : isEN ? "Aunt"      : "Tante")

        // Test: Geburtstag gestern + gekauftes Geschenk → Auto-Transition testen
        let gestern  = person("demo-gestern",isFR ? "Hier Anniversaire"  : isES ? "Ayer Cumpleaños"    : isEN ? "Yesterday Birthday" : "Marco Rossi",          bday(-1, 30), isFR ? "Ami" : isES ? "Amigo" : isEN ? "Friend" : "Freund")

        let allPeople: [PersonRef] = [
            max, erika, hans, anna, peter, lisa, thomas, julia, sophie, michael,
            maria, felix, klara, otto, emma, paul, kurt, sarah, markus, ingrid,
            gerhard, nina, stefan, lena, tobias, petra, daniel, monika, jan, laura,
            bernhard, karin, florian, ursula, dominik, helga, patrick, andrea, tim, sandra,
            christian, brigitte, oliver, katrin, werner, melanie, hubert, tanja, Sebastian, irene,
            gestern
        ]
        // Demo-Hobbies fuer einige Personen
        max.hobbies = isFR ? ["Cuisine", "Whisky", "Barbecue"] : isES ? ["Cocina", "Whisky", "Barbacoa"] : isEN ? ["Cooking", "Whisky", "BBQ"] : ["Kochen", "Whisky", "Grillen"]
        erika.hobbies = isFR ? ["Yoga", "Bien-être", "Aquarelle"] : isES ? ["Yoga", "Bienestar", "Acuarela"] : isEN ? ["Yoga", "Wellness", "Watercolor"] : ["Yoga", "Wellness", "Aquarell"]
        sophie.hobbies = isFR ? ["Photographie", "Voyages", "Lecture"] : isES ? ["Fotografía", "Viajes", "Lectura"] : isEN ? ["Photography", "Travel", "Reading"] : ["Fotografie", "Reisen", "Lesen"]
        anna.hobbies = isFR ? ["Vin", "Jardinage", "Cuisine"] : isES ? ["Vino", "Jardinería", "Cocina"] : isEN ? ["Wine", "Gardening", "Cooking"] : ["Wein", "Garten", "Kochen"]
        thomas.hobbies = isFR ? ["Course à pied", "Technologie", "Jeux vidéo"] : isES ? ["Correr", "Tecnología", "Videojuegos"] : isEN ? ["Running", "Tech", "Gaming"] : ["Laufen", "Technik", "Gaming"]
        emma.hobbies = isFR ? ["LEGO", "Bricolage", "Dessin"] : isES ? ["LEGO", "Manualidades", "Dibujo"] : isEN ? ["LEGO", "Crafts", "Drawing"] : ["LEGO", "Basteln", "Malen"]

        allPeople.forEach { context.insert($0) }

        // MARK: - Geschenkideen

        // Max / Jean (Ami, Anniversaire AUJOURD'HUI)
        idea(max, isFR ? "Coffret Dégustation Whisky" : isES ? "Set de Cata de Whisky" : isEN ? "Whisky Tasting Set" : "Whisky Tasting Set", isFR ? "Adore le Single Malt Islay" : isES ? "Le encanta el Single Malt Islay" : isEN ? "Loves Single Malt Islay" : "Mag Single Malt Islay", 50, 80, .idea, isFR ? ["Alcool", "Dégustation"] : isES ? ["Bebidas", "Cata"] : isEN ? ["Drinks", "Tasting"] : ["Alkohol", "Tasting"], context)
        idea(max, isFR ? "Cours de cuisine Pasta & Risotto" : isES ? "Clase de Cocina Pasta & Risotto" : isEN ? "Pasta & Risotto Cooking Class" : "Kochkurs Pasta & Risotto", isFR ? "Cuisinier passionné" : isES ? "Le encanta cocinar" : isEN ? "Passionate home cook" : "Kocht leidenschaftlich gerne", 60, 90, .planned, isFR ? ["Expérience", "Cuisine"] : isES ? ["Experiencia", "Cocina"] : isEN ? ["Experience", "Cooking"] : ["Erlebnis", "Kochen"], context)
        idea(max, isFR ? "Thermomètre BBQ Bluetooth" : isES ? "Termómetro Bluetooth para Barbacoa" : isEN ? "Bluetooth BBQ Thermometer" : "Grill-Thermometer Bluetooth", isFR ? "Fait beaucoup de barbecue en été" : isES ? "Hace muchas barbacoas en verano" : isEN ? "Grills a lot in summer" : "Grillt viel im Sommer", 30, 60, .idea, isFR ? ["Barbecue", "Cuisine"] : isES ? ["Barbacoa", "Cocina"] : isEN ? ["BBQ", "Kitchen"] : ["Grillen", "Küche"], context)

        // Erika / Marie (Sœur, dans 2 jours)
        idea(erika, isFR ? "Bon Spa" : isES ? "Vale de Spa" : isEN ? "Spa Voucher" : "Spa-Gutschein", isFR ? "Adore le bien-être et les massages" : isES ? "Le encanta el bienestar y los masajes" : isEN ? "Loves wellness and massages" : "Liebt Wellness und Massagen", 80, 120, .planned, ["Wellness"], context)
        idea(erika, isFR ? "Tapis de Yoga Manduka PRO" : isES ? "Esterilla de Yoga Manduka PRO" : isEN ? "Manduka PRO Yoga Mat" : "Yoga-Matte Manduka PRO", isFR ? "Fait du yoga quotidiennement" : isES ? "Hace yoga a diario" : isEN ? "Does yoga daily" : "Macht täglich Yoga", 50, 80, .idea, isFR ? ["Sport", "Yoga"] : isES ? ["Deporte", "Yoga"] : isEN ? ["Fitness", "Yoga"] : ["Sport", "Yoga"], context)

        // Sophie (Partenaire)
        idea(sophie, isFR ? "Week-end à Paris" : isES ? "Escapada a Barcelona" : isEN ? "Weekend Trip to Prague" : "Kurzurlaub Prag", isFR ? "Adore les escapades en amoureux" : isES ? "Nunca ha estado en Barcelona" : isEN ? "Never been to Prague" : "War noch nie in Prag", 300, 500, .idea, isFR ? ["Voyage", "Expérience"] : isES ? ["Viaje", "Experiencia"] : isEN ? ["Travel", "Experience"] : ["Reise", "Erlebnis"], context)
        idea(sophie, isFR ? "Fujifilm Instax Mini 12" : isEN ? "Fujifilm Instax Mini 12" : "Fujifilm Instax Mini 12", isFR ? "Adore les photos instantanées" : isES ? "Le encantan las fotos instantáneas" : isEN ? "Loves instant photos" : "Mag Sofortbild-Fotos", 70, 100, .planned, isFR ? ["Photo", "Créatif"] : isES ? ["Foto", "Creativo"] : isEN ? ["Photo", "Creative"] : ["Foto", "Kreativ"], context)

        // Anna / Isabelle (Mère)
        idea(anna, isFR ? "Coffret Vin Bordeaux" : isES ? "Selección de Vino de Rioja" : isEN ? "Bordeaux Wine Collection" : "Weinpaket Bordeaux", isFR ? "Amatrice de vin rouge, millésime 2019" : isES ? "Amante del vino tinto, cosecha 2019" : isEN ? "Red wine lover, 2019 vintage" : "Rotwein-Liebhaberin, Jahrgang 2019", 60, 100, .idea, isFR ? ["Vin"] : isES ? ["Vino"] : isEN ? ["Wine"] : ["Wein"], context)
        idea(anna, isFR ? "Machine à Expresso DeLonghi" : isES ? "Cafetera Espresso DeLonghi" : isEN ? "DeLonghi Espresso Machine" : "Kaffeemaschine DeLonghi", isFR ? "Boit un espresso tous les jours" : isES ? "Bebe un espresso a diario" : isEN ? "Drinks espresso daily" : "Trinkt täglich Espresso", 100, 150, .idea, isFR ? ["Cuisine", "Café"] : isES ? ["Cocina", "Café"] : isEN ? ["Kitchen", "Coffee"] : ["Küche", "Kaffee"], context)

        // Otto / René (Père)
        idea(otto, isFR ? "Perceuse Bosch sans fil" : isES ? "Taladro Inalámbrico Bosch" : isEN ? "Bosch Cordless Drill" : "Bosch Akku-Bohrschrauber", isFR ? "Système 18V, adore le bricolage" : isES ? "Sistema 18V, le encanta el bricolaje" : isEN ? "18V system, loves DIY" : "18V System, heimwerkert viel", 80, 130, .planned, isFR ? ["Outils"] : isES ? ["Herramientas"] : isEN ? ["Tools"] : ["Werkzeug"], context)

        // Emma (Nièce, 8 ans)
        idea(emma, isFR ? "LEGO Friends Salon de Glace" : isES ? "LEGO Friends Heladería" : isEN ? "LEGO Friends Ice Cream Parlor" : "LEGO Friends Eiscafé", isFR ? "Adore les sets LEGO Friends" : isES ? "Le encantan los sets LEGO Friends" : isEN ? "Loves LEGO Friends sets" : "Liebt LEGO Friends Sets", 35, 55, .idea, isFR ? ["LEGO", "Jouets"] : isES ? ["LEGO", "Juguetes"] : isEN ? ["LEGO", "Toys"] : ["LEGO", "Spielzeug"], context)
        idea(emma, isFR ? "Sac à Dos Licorne" : isES ? "Mochila Unicornio" : isEN ? "Unicorn Backpack" : "Einhorn-Rucksack", isFR ? "Adore les licornes et le violet" : isES ? "Le encantan los unicornios y el morado" : isEN ? "Loves unicorns and purple" : "Mag Einhörner und Lila", 25, 40, .planned, isFR ? ["École"] : isES ? ["Escuela"] : isEN ? ["School"] : ["Schule"], context)

        // Paul (Neveu, 17 ans)
        idea(paul, isFR ? "Nintendo Switch Zelda: Echoes of Wisdom" : isEN ? "Nintendo Switch Zelda: Echoes of Wisdom" : "Nintendo Switch Zelda: Echoes of Wisdom", isFR ? "Fan de la série Zelda" : isES ? "Fan de la serie Zelda" : isEN ? "Loves the Zelda series" : "Mag Zelda-Serie", 45, 60, .idea, ["Gaming"], context)
        idea(paul, isFR ? "Planche de Skate Powell" : isEN ? "Powell Skateboard Deck" : "Skateboard Deck Powell", isFR ? "Fait du skate, 8.0\"" : isES ? "Hace skate, 8.0\"" : isEN ? "Skateboards, 8.0\"" : "Fährt Skateboard, 8.0\"", 40, 70, .idea, isFR ? ["Sport", "Skateboard"] : isES ? ["Deporte", "Monopatín"] : isEN ? ["Sports", "Skateboard"] : ["Sport", "Skateboard"], context)

        // Hans / Pierre (Collègue)
        idea(hans, isFR ? "Carnet Moleskine XL" : isES ? "Cuaderno Moleskine XL" : isEN ? "Moleskine XL Notebook" : "Moleskine Notizbuch XL", isFR ? "Écrit beaucoup, apprécie le bon papier" : isES ? "Escribe mucho, aprecia el buen papel" : isEN ? "Writes a lot, likes quality paper" : "Schreibt viel, mag gutes Papier", 25, 40, .idea, isFR ? ["Bureau"] : isES ? ["Oficina"] : isEN ? ["Office"] : ["Büro"], context)

        // Thomas (Ami)
        idea(thomas, isFR ? "Garmin Forerunner 265" : isEN ? "Garmin Forerunner 265" : "Garmin Forerunner 265", isFR ? "Court des semi-marathons" : isES ? "Corre medias maratones" : isEN ? "Runs half marathons" : "Läuft Halbmarathon", 280, 350, .idea, isFR ? ["Sport", "Tech"] : isES ? ["Deporte", "Tecnología"] : isEN ? ["Sports", "Tech"] : ["Sport", "Technik"], context)

        // Andrea (Cheffe)
        idea(andrea, isFR ? "Tasse en Porcelaine Artisanale" : isES ? "Taza de Porcelana Artesanal" : isEN ? "Handmade Porcelain Mug" : "Porzellan-Tasse handgemacht", isFR ? "Boit toujours du thé au bureau" : isES ? "Siempre bebe té en la oficina" : isEN ? "Always drinks tea at the office" : "Trinkt immer Tee im Büro", 30, 50, .idea, isFR ? ["Bureau", "Vaisselle"] : isES ? ["Oficina", "Cerámica"] : isEN ? ["Office", "Ceramics"] : ["Büro", "Geschirr"], context)

        // Maria / Martine (Tante)
        idea(maria, isFR ? "Kit d'Herbes Aromatiques" : isES ? "Kit de Hierbas Aromáticas" : isEN ? "Garden Herb Kit" : "Garten-Kräuterset", isFR ? "Grand jardin, cuisine avec des herbes fraîches" : isES ? "Tiene un gran jardín, cocina con hierbas frescas" : isEN ? "Has a big garden, cooks with fresh herbs" : "Hat großen Garten, kocht mit frischen Kräutern", 30, 50, .idea, isFR ? ["Jardin", "Cuisine"] : isES ? ["Jardín", "Cocina"] : isEN ? ["Garden", "Cooking"] : ["Garten", "Kochen"], context)

        // Gestern (Auto-Transition Test: purchased → given)
        idea(gestern, isFR ? "Enceinte Bluetooth JBL" : isES ? "Altavoz Bluetooth JBL" : isEN ? "JBL Bluetooth Speaker" : "Bluetooth-Lautsprecher JBL", isFR ? "Adore la musique" : isES ? "Le encanta la música" : isEN ? "Loves music" : "Mag Musik", 50, 80, .purchased, isFR ? ["Tech", "Musique"] : isES ? ["Tecnología", "Música"] : isEN ? ["Tech", "Music"] : ["Technik", "Musik"], context)

        // MARK: - Geschenkhistorie

        hist(max, isFR ? "Pack Bières Artisanales 12" : isES ? "Pack de Cervezas Artesanales 12" : isEN ? "Craft Beer 12-Pack" : "Craftbier-Paket 12er", isFR ? "Boissons" : isES ? "Bebidas" : isEN ? "Drinks" : "Getränke", year-1, 55, isFR ? "Était ravi" : isES ? "Estaba encantado" : isEN ? "Was thrilled" : "War begeistert", context)
        hist(max, isFR ? "Valise Samsonite 67cm" : isES ? "Maleta Samsonite 67cm" : isEN ? "Samsonite Suitcase 26\"" : "Koffer Samsonite 67cm", isFR ? "Voyage" : isES ? "Viaje" : isEN ? "Travel" : "Reise", year-2, 180, isFR ? "Voyage beaucoup, très pratique" : isES ? "Viaja mucho, muy práctico" : isEN ? "Travels a lot, very practical" : "Reist viel, sehr praktisch", context)
        hist(erika, isFR ? "Parfum Chanel No. 5" : isES ? "Perfume Chanel N.° 5" : isEN ? "Chanel No. 5 Perfume" : "Parfüm Chanel No. 5", isFR ? "Beauté" : isES ? "Belleza" : isEN ? "Beauty" : "Kosmetik", year-1, 90, isFR ? "Elle a adoré" : isES ? "Le encantó" : isEN ? "She loved it" : "Hat sie sehr gefreut", context)
        hist(erika, isFR ? "Set Aquarelle Winsor & Newton" : isES ? "Set de Acuarela Winsor & Newton" : isEN ? "Winsor & Newton Watercolor Set" : "Aquarell-Set Winsor & Newton", isFR ? "Créatif" : isES ? "Creativo" : isEN ? "Creative" : "Kreativ", year-2, 65, isFR ? "Peint en loisir" : isES ? "Pinta como afición" : isEN ? "Paints as a hobby" : "Malt als Hobby", context)
        hist(anna, isFR ? "Couteau Victorinox Outdoor" : isES ? "Navaja Victorinox Outdoor" : isEN ? "Victorinox Outdoor Knife" : "Jagdmesser Victorinox", "Outdoor", year-1, 75, isFR ? "Loisir outdoor" : isES ? "Afición al aire libre" : isEN ? "Outdoor hobby" : "Outdoor-Hobby", context)
        hist(thomas, "Garmin Forerunner 55", isFR ? "Sport/Tech" : isES ? "Deporte/Tecnología" : isEN ? "Sports/Tech" : "Sport/Technik", year-1, 180, isFR ? "Montre de course, très content" : isES ? "Reloj deportivo, muy contento" : isEN ? "Running watch, very happy" : "Laufuhr, sehr zufrieden", context)
        hist(sophie, isFR ? "Week-end à Lyon" : isES ? "Fin de semana en Madrid" : isEN ? "Weekend in Munich" : "Wochenende in München", isFR ? "Expérience/Voyage" : isES ? "Experiencia/Viaje" : isEN ? "Experience/Travel" : "Erlebnis/Reise", year-1, 420, isFR ? "C'était magnifique" : isES ? "Fue maravilloso" : isEN ? "Was wonderful" : "War wunderschön", context)
        hist(sophie, "Apple AirPods Pro", isFR ? "Tech" : isES ? "Tecnología" : isEN ? "Tech" : "Technik", year-2, 249, isFR ? "Utilise tous les jours" : isES ? "Los usa a diario" : isEN ? "Uses them daily" : "Benutzt täglich", context)
        hist(emma, "LEGO Duplo Farm", isFR ? "Jouets" : isES ? "Juguetes" : isEN ? "Toys" : "Spielzeug", year-1, 40, isFR ? "A joué pendant des jours" : isES ? "Jugó con ello durante días" : isEN ? "Played with it for days" : "Tagelang gespielt", context)
        hist(paul, "Longboard Globe", isFR ? "Sport" : isES ? "Deporte" : isEN ? "Sports" : "Sport", year-1, 110, isFR ? "Va à l'école avec tous les jours" : isES ? "Lo usa para ir al colegio a diario" : isEN ? "Rides it to school daily" : "Fährt täglich zur Schule", context)
        hist(otto, "Weber Grill Q1200", isFR ? "Barbecue" : isES ? "Barbacoa" : isEN ? "BBQ" : "Grillen", year-1, 160, isFR ? "Fait des barbecues chaque été" : isES ? "Hace barbacoas cada verano" : isEN ? "Grills every summer" : "Grillt jeden Sommer", context)
        hist(peter, "Kindle Paperwhite", isFR ? "Tech/Livres" : isES ? "Tecnología/Libros" : isEN ? "Tech/Books" : "Technik/Bücher", year-1, 120, isFR ? "Lit beaucoup, très pratique" : isES ? "Lee mucho, muy práctico" : isEN ? "Reads a lot, very practical" : "Liest viel, sehr praktisch", context)
        hist(ingrid, isFR ? "Vol en Montgolfière pour Deux" : isES ? "Vuelo en Globo para Dos" : isEN ? "Hot Air Balloon Ride for Two" : "Ballonfahrt für zwei", isFR ? "Expérience" : isES ? "Experiencia" : isEN ? "Experience" : "Erlebnis", year-1, 210, isFR ? "Un rêve devenu réalité" : isES ? "Un sueño hecho realidad" : isEN ? "A dream come true" : "War ein Traum", context)
        hist(kurt, "Lamy Pen & Pencil Set", isFR ? "Bureau" : isES ? "Oficina" : isEN ? "Office" : "Büro", year-1, 85, isFR ? "Utilise tous les jours au bureau" : isES ? "Lo usa a diario en la oficina" : isEN ? "Uses it daily at the office" : "Benutzt täglich im Büro", context)

        // Erhaltene Geschenke (received)
        hist(max, isFR ? "Casque Bluetooth Sony" : isES ? "Auriculares Bluetooth Sony" : isEN ? "Sony Bluetooth Headphones" : "Bluetooth-Kopfhörer Sony", isFR ? "Tech" : isES ? "Tecnología" : isEN ? "Tech" : "Technik", year-1, 120, isFR ? "Cadeau d'anniversaire" : isES ? "Regalo de cumpleaños" : isEN ? "Birthday gift" : "Zum Geburtstag bekommen", context, direction: .received)
        hist(erika, isFR ? "Bougie Artisanale" : isES ? "Vela Artesanal" : isEN ? "Handmade Candle" : "Handgemachte Kerze", isFR ? "Déco" : isES ? "Decoración" : isEN ? "Decor" : "Deko", year-1, 25, isFR ? "Cadeau de Noël" : isES ? "Regalo de Navidad" : isEN ? "Christmas gift" : "Weihnachtsgeschenk", context, direction: .received)
        hist(sophie, isFR ? "Album Photo Bilan de l'Année" : isES ? "Álbum de Fotos del Año" : isEN ? "Year in Review Photo Book" : "Fotobuch Jahresrückblick", isFR ? "Créatif" : isES ? "Creativo" : isEN ? "Creative" : "Kreativ", year-1, 45, isFR ? "Très personnel, magnifique" : isES ? "Muy personal, precioso" : isEN ? "Very personal, beautiful" : "Sehr persönlich, wunderschön", context, direction: .received)

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

