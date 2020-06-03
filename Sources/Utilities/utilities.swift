import Foundation

public let databaseNames = [
    "browser_web",
    "musical",
    "farm",
    "voter_1",
    "game_injury",
    "hospital_1",
    "manufacturer",
    "station_weather",
    "perpetrator",
    "storm_record",
    "flight_1",
    "manufactory_1",
    "cre_Theme_park",
    "museum_visit",
    "race_track",
    "soccer_2",
    "bike_1",
    "pilot_record",
    "customers_and_invoices",
    "department_management",
    "news_report",
    "tvshow",
    "music_1",
    "store_product",
    "party_host",
    "ship_1",
    "solvency_ii",
    "products_gen_characteristics",
    "dog_kennels",
    "local_govt_and_lot",
    "culture_company",
    "aircraft",
    "wta_1",
    "cinema",
    "formula_1",
    "wine_1",
    "gas_company",
    "network_2",
    "match_season",
    "phone_1",
    "pets_1",
    "tracking_grants_for_research",
    "party_people",
    "hr_1",
    "scientist_1",
    "college_3",
    "cre_Doc_Template_Mgt",
    "restaurants",
    "program_share",
    "college_2",
    "course_teach",
    "candidate_poll",
    "cre_Doc_Control_Systems",
    "wedding",
    "yelp",
    "document_management",
    "loan_1",
    "railway",
    "geo",
    "sakila_1",
    "movie_1",
    "flight_company",
    "csu_1",
    "company_employee",
    "orchestra",
    "car_1",
    "customers_card_transactions",
    "machine_repair",
    "shop_membership",
    "wrestler",
    "performance_attendance",
    "debate",
    "icfp_1",
    "e_learning",
    "customer_deliveries",
    "academic",
    "cre_Doc_Tracking_DB",
    "entertainment_awards",
    "department_store",
    "customers_and_products_contacts",
    "voter_2",
    "driving_school",
    "school_finance",
    "roller_coaster",
    "journal_committee",
    "flight_4",
    "club_1",
    "epinions_1",
    "decoration_competition",
    "architecture",
    "train_station",
    "allergy_1",
    "soccer_1",
    "election_representative",
    "city_record",
    "customers_campaigns_ecommerce",
    "flight_2",
    "poker_player",
    "customer_complaints",
    "company_1",
    "concert_singer",
    "cre_Docs_and_Epenses",
    "insurance_and_eClaims",
    "insurance_policies",
    "county_public_safety",
    "baseball_1",
    "imdb",
    "music_2",
    "network_1",
    "climbing",
    "swimming",
    "customers_and_addresses",
    "tracking_share_transactions",
    "game_1",
    "cre_Drama_Workshop_Groups",
    "election",
    "book_2",
    "music_4",
    "small_bank_1",
    "local_govt_in_alabama",
    "device",
    "sports_competition",
    "workshop_paper",
    "tracking_orders",
    "school_bus",
    "protein_institute",
    "activity_1",
    "phone_market",
    "entrepreneur",
    "apartment_rentals",
    "medicine_enzyme_interaction",
    "gymnast",
    "student_1",
    "store_1",
    "employee_hire_evaluation",
    "college_1",
    "local_govt_mdm",
    "company_office",
    "battle_death",
    "dorm_1",
    "products_for_hire",
    "coffee_shop",
    "singer",
    "chinook_1",
    "behavior_monitoring",
    "world_1",
    "university_basketball",
    "mountain_photos",
    "scholar",
    "product_catalog",
    "real_estate_properties",
    "student_transcripts_tracking",
    "film_rank",
    "theme_gallery",
    "e_government",
    "insurance_fnol",
    "restaurant_1",
    "inn_1",
    "tracking_software_problems",
    "riding_club",
    "ship_mission",
    "student_assessment",
    "assets_maintenance",
    "twitter_1",
    "body_builder",
    "school_player"
]

/// starts hasura/graphql-engine:v1.2.2
@discardableResult
public func startHasura(name: String, dockerPath: String) -> String {
    return shell(
            """
             \(dockerPath) run -d -p 8080:8080 \
    -e HASURA_GRAPHQL_DATABASE_URL=postgres://host.docker.internal:5432/\(name) \
    -e HASURA_GRAPHQL_ENABLE_CONSOLE=true \
    hasura/graphql-engine:v1.2.2
    """)
}
@discardableResult
public func stopHasura(hash: String, dockerPath: String, shouldRemove: Bool = true) -> String {
    let stopped = shell("\(dockerPath) stop \(hash)")
    if shouldRemove {
       shell("\(dockerPath) rm \(stopped)")
    }
    return stopped
}


@discardableResult
public func shell(_ command: String, launchPath: String = "/usr/bin/env" ) -> String {
    let task = Process()
    task.launchPath = launchPath
    task.arguments = ["bash", "-c", command]

    let pipe = Pipe()
    task.standardOutput = pipe
    task.launch()

    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    let output: String = NSString(data: data, encoding: String.Encoding.utf8.rawValue)! as String

    return output
}

extension FileManager {
    public func urls(for directory: FileManager.SearchPathDirectory, skipsHiddenFiles: Bool = true ) -> [URL]? {
        let documentsURL = urls(for: directory, in: .userDomainMask)[0]
        let fileURLs = try? contentsOfDirectory(at: documentsURL, includingPropertiesForKeys: nil, options: skipsHiddenFiles ? .skipsHiddenFiles : [] )
        return fileURLs
    }
}
