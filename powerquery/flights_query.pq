// Flights table: Power Query (M)
// Change the file path on the Source line to where flights.csv is on your computer.
let
    Source = Csv.Document(
        File.Contents("C:\Data\Airline_Operations\flights.csv"),
        [Delimiter = ",", Encoding = 65001, QuoteStyle = QuoteStyle.None]
    ),
    Promoted = Table.PromoteHeaders(Source, [PromoteAllScalars = true]),

    // Keep only the columns the dashboard needs
    Kept = Table.SelectColumns(Promoted, {
        "YEAR","MONTH","DAY","DAY_OF_WEEK","AIRLINE","FLIGHT_NUMBER",
        "ORIGIN_AIRPORT","DESTINATION_AIRPORT","SCHEDULED_DEPARTURE",
        "DEPARTURE_DELAY","SCHEDULED_TIME","AIR_TIME","DISTANCE",
        "ARRIVAL_DELAY","DIVERTED","CANCELLED","CANCELLATION_REASON",
        "AIR_SYSTEM_DELAY","SECURITY_DELAY","AIRLINE_DELAY",
        "LATE_AIRCRAFT_DELAY","WEATHER_DELAY"
    }),

    Typed = Table.TransformColumnTypes(Kept, {
        {"YEAR", Int64.Type}, {"MONTH", Int64.Type}, {"DAY", Int64.Type},
        {"DAY_OF_WEEK", Int64.Type}, {"AIRLINE", type text},
        {"FLIGHT_NUMBER", Int64.Type},
        {"ORIGIN_AIRPORT", type text}, {"DESTINATION_AIRPORT", type text},
        {"SCHEDULED_DEPARTURE", Int64.Type},
        {"DEPARTURE_DELAY", type number}, {"SCHEDULED_TIME", type number},
        {"AIR_TIME", type number}, {"DISTANCE", Int64.Type},
        {"ARRIVAL_DELAY", type number},
        {"DIVERTED", Int64.Type}, {"CANCELLED", Int64.Type},
        {"CANCELLATION_REASON", type text},
        {"AIR_SYSTEM_DELAY", type number}, {"SECURITY_DELAY", type number},
        {"AIRLINE_DELAY", type number}, {"LATE_AIRCRAFT_DELAY", type number},
        {"WEATHER_DELAY", type number}
    }, "en-US"),

    // Remove rows with numeric airport codes (they don't exist in the airports table)
    CleanAirports = Table.SelectRows(Typed, each
        Text.Length([ORIGIN_AIRPORT]) = 3 and Text.Length([DESTINATION_AIRPORT]) = 3),

    // Real date column for the relationship to the Date table
    AddDate = Table.AddColumn(CleanAirports, "FlightDate",
        each #date([YEAR], [MONTH], [DAY]), type date),

    // On-time flag: not cancelled and arrived less than 15 minutes late
    AddOnTime = Table.AddColumn(AddDate, "IsOnTime",
        each if [CANCELLED] = 0 and [ARRIVAL_DELAY] <> null and [ARRIVAL_DELAY] < 15 then 1 else 0,
        Int64.Type),

    // Delay bucket for charts
    AddBucket = Table.AddColumn(AddOnTime, "Delay Category", each
        if [CANCELLED] = 1 then "Cancelled"
        else if [ARRIVAL_DELAY] = null then "Diverted / No data"
        else if [ARRIVAL_DELAY] < 15 then "On Time"
        else if [ARRIVAL_DELAY] < 60 then "Minor (15-59 min)"
        else if [ARRIVAL_DELAY] < 180 then "Major (1-3 hrs)"
        else "Severe (3+ hrs)", type text),

    Final = Table.RemoveColumns(AddBucket, {"YEAR","MONTH","DAY"})
in
    Final
