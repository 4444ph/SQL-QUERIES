--original

# MASTER DATA (Original Names)

masterlist_tractor
    -
    Id bigint PK
    Head nvarchar PK
    Brand nvarchar
    PlateNo nvarchar
    Bu nvarchar
    Assignment nvarchar
    PairedTrailer nvarchar
    Modified datetime
    Created datetime

masterlist_trailer
    -
    Id bigint PK
    Classification nvarchar
    Axle nvarchar
    SubEngine nvarchar
    Bu nvarchar
    PlateNo nvarchar PK
    Assignment nvarchar
    PairedWith nvarchar
    Modified datetime
    Created datetime

driver_probationary
    -
    Id int PK
    Fullname nvarchar PK
    Hrid nvarchar
    Businessunit nvarchar
    Driverstatus nvarchar
    Deploystatus nvarchar

# REFERENCE DATA

urstat_ref
    -
    Status nvarchar PK
    Category nvarchar

# OPERATIONAL DATA (Original Names)

fromsheet_os_idl
    -
    id bigint PK
    Head nvarchar FK >- masterlist_tractor.Head
    Driver nvarchar FK >- driver_probationary.Fullname
    Trailer nvarchar FK >- masterlist_trailer.PlateNo
    DriverTripStatus nvarchar FK >- urstat_ref.Status
    Team nvarchar
    UrData nvarchar
    Remarks nvarchar
    LastUpdate nvarchar
    LatestLsTripAssigned nvarchar

gps_live_data
    -
    id bigint PK
    Headno nvarchar FK >- masterlist_tractor.Head
    LiveLocation nvarchar
    LastUpdate nvarchar
    GpsStat nvarchar

# MAINTENANCE WORKFLOW (Original Names)

jr_list
    -
    Id bigint PK
    Jrnumber nvarchar PK
    Head nvarchar FK >- masterlist_tractor.Head
    Ur nvarchar
    Jrstatus nvarchar
    Requeststatus nvarchar
    Location nvarchar
    Created datetime

jo_list
    -
    Id bigint PK
    Jonumber nvarchar PK
    Jrn nvarchar FK >- jr_list.Jrnumber
    Jostatus nvarchar
    Activity nvarchar
    Etr nvarchar
    Remarks nvarchar
    Classification nvarchar
    Modified datetime

# VIRTUAL VIEW (Cement Cargo Logic)
# Applying relationships to every relevant column as requested

vw_Truck_Data_Cement_Cargo
    -
    Head nvarchar FK - masterlist_tractor.Head
    Unit nvarchar # Computed: Head | Plate
    Team nvarchar
    Brand nvarchar FK - masterlist_tractor.Brand
    PairedTrailer nvarchar FK - masterlist_tractor.PairedTrailer
    JRNumber nvarchar FK - jr_list.Jrnumber
    JRStatus nvarchar FK - jr_list.Jrstatus
    Jonumber nvarchar FK - jo_list.Jonumber
    Activity nvarchar FK - jo_list.Activity
    Jostatus nvarchar FK - jo_list.Jostatus
    URStatus nvarchar # Computed Logic
    LastLocation nvarchar FK - gps_live_data.LiveLocation
    LastUpdate nvarchar FK - gps_live_data.LastUpdate
    GpsStatus nvarchar FK - gps_live_data.GpsStat
    Trip nvarchar FK - urstat_ref.Category
    Assignment nvarchar FK - masterlist_tractor.Assignment

--original

# MASTER DATA
# Static records for Assets and Personnel

masterlist_tractor
    -
    head_no varchar PK
    brand varchar
    plate_no varchar
    business_unit_id int
    assignment_status varchar
    created_at datetime

masterlist_trailer
    -
    plate_no varchar PK
    classification varchar
    axle_count int
    has_sub_engine bit
    assignment_status varchar
    created_at datetime

driver_probationary
    -
    full_name varchar PK
    hr_id varchar
    license_no varchar
    driver_status varchar
    deploy_status varchar

# REFERENCE DATA
# Used for mapping status strings to categories

urstat_ref
    -
    status varchar PK
    category varchar FK # IDLE, ON TRIP, AVAILABLE, etc. FK >- vw_Truck_Data_Cement_Cargo.trip_category

# OPERATIONAL DATA
# Live telemetry and daily assignments

fromsheet_os_idl
    -
    id bigint PK
    head_no varchar FK >- masterlist_tractor.head_no
    driver_name varchar FK >- driver_probationary.full_name
    helper_name varchar
    trailer_no varchar FK >- masterlist_trailer.plate_no
    team_name varchar
    trip_status varchar FK >- urstat_ref.status
    remarks varchar(max)
    last_update datetime
    latest_trip_id varchar
    truck_status varchar
    trailer_status varchar

gps_live_data
    -
    id bigint PK
    head_no varchar FK >- masterlist_tractor.head_no
    gps_status varchar
    last_update datetime
    live_location varchar(max)
    latitude decimal(9,6)
    longitude decimal(9,6)
    speed_kph int
    platform varchar

# MAINTENANCE WORKFLOW
# Job Requests (JR) and Job Orders (JO)

jr_list
    -
    id bigint PK
    jr_number varchar UNIQUE
    head_no varchar FK >- masterlist_tractor.head_no
    jr_status varchar
    odometer_reading int
    request_status varchar
    priority_level varchar
    location varchar
    approval_timestamp datetime
    done_timestamp datetime

jo_list
    -
    id bigint PK
    jo_number varchar UNIQUE
    related_jr_number varchar FK >- jr_list.jr_number
    jo_status varchar
    mechanic_name varchar
    actual_repair varchar(max)
    duration_hrs float
    etr_datetime datetime

# VIRTUAL VIEW (Logic Layer)
# Representation of [vw_Truck_Data_Cement_Cargo]

vw_Truck_Data_Cement_Cargo
    -
    head_no varchar FK - masterlist_tractor.head_no
    unit_label varchar # Head | Plate
    team_name varchar
    jr_number varchar FK - jr_list.jr_number
    jr_status varchar
    jo_number varchar FK - jo_list.jo_number
    ur_status varchar # Calculated: FOR RESC, WFP, ON GOING, etc.
    last_location varchar
    assigned_yard varchar # Result of YardMapping
    sbuo_status varchar
    trip_category varchar FK - urstat_ref.category
    fjo_act varchar # START / PAUSE / RESUME logic

--cleaned ERD vw_Truck_Data_Cement_Cargo
// MASTER DATA (Original Names)

Table masterlist_tractor {
  Id bigint [pk]
  Head nvarchar [pk, unique]
  Brand nvarchar
  PlateNo nvarchar
  Bu nvarchar
  Assignment nvarchar
  PairedTrailer nvarchar
  Modified datetime
  Created datetime
}

Table masterlist_trailer {
  Id bigint [pk]
  PlateNo nvarchar [pk, unique]
  Classification nvarchar
  Axle nvarchar
  SubEngine nvarchar
  Bu nvarchar
  Assignment nvarchar
  PairedWith nvarchar
  Modified datetime
  Created datetime
}

Table driver_probationary {
  Id int [pk]
  Fullname nvarchar [pk, unique]
  Hrid nvarchar
  Businessunit nvarchar
  Driverstatus nvarchar
  Deploystatus nvarchar
}

// REFERENCE DATA

Table urstat_ref {
  Status nvarchar [pk]
  Category nvarchar
}

// OPERATIONAL DATA (Original Names)

Table fromsheet_os_idl {
  id bigint [pk]
  Head nvarchar
  Driver nvarchar
  Trailer nvarchar
  DriverTripStatus nvarchar
  Team nvarchar
  UrData nvarchar
  Remarks nvarchar
  LastUpdate nvarchar
  LatestLsTripAssigned nvarchar
}

// MAINTENANCE WORKFLOW

Table jr_list {
  Id bigint [pk]
  Jrnumber nvarchar [pk, unique]
  Head nvarchar
  Ur nvarchar
  Jrstatus nvarchar
  Requeststatus nvarchar
  Location nvarchar
  Created datetime
}

Table jo_list {
  Id bigint [pk]
  Jonumber nvarchar [pk]
  Jrn nvarchar
  Jostatus nvarchar
  Activity nvarchar
  Etr nvarchar
  Remarks nvarchar
  Classification nvarchar
  Modified datetime
}

Table gps_live_data {
  id bigint [pk]
  Headno nvarchar
  LiveLocation nvarchar
  LastUpdate nvarchar
  GpsStat nvarchar
}

// VIRTUAL VIEW (Cement Cargo Logic)
// In DBML, we represent the View as a table and define its logical connections

Table vw_Truck_Data_Cement_Cargo {
  Head nvarchar [pk]
  Unit nvarchar
  Team nvarchar
  Brand nvarchar
  PairedTrailer nvarchar
  JRNumber nvarchar
  JRStatus nvarchar
  Jonumber nvarchar
  Activity nvarchar
  Jostatus nvarchar
  URStatus nvarchar
  LastLocation nvarchar
  LastUpdate nvarchar
  GpsStatus nvarchar
  Trip nvarchar
  Assignment nvarchar
} 

// RELATIONSHIPS (DBML Syntax)

Ref: fromsheet_os_idl.Head - masterlist_tractor.Head
Ref: fromsheet_os_idl.Driver > driver_probationary.Fullname
Ref: fromsheet_os_idl.Trailer - masterlist_trailer.PlateNo
Ref: fromsheet_os_idl.DriverTripStatus > urstat_ref.Status

Ref: gps_live_data.Headno > masterlist_tractor.Head

Ref: jr_list.Head > masterlist_tractor.Head
Ref: jo_list.Jrn > jr_list.Jrnumber

// Relationships for the View logic
Ref: vw_Truck_Data_Cement_Cargo.Head - masterlist_tractor.Head
Ref: vw_Truck_Data_Cement_Cargo.JRNumber - jr_list.Jrnumber
Ref: vw_Truck_Data_Cement_Cargo.Jonumber - jo_list.Jonumber
Ref: vw_Truck_Data_Cement_Cargo.LastLocation - gps_live_data.LiveLocation

//Ref: "masterlist_tractor"."Id" < "masterlist_tractor"."Bu"

Ref: "jo_list"."Jostatus" - "vw_Truck_Data_Cement_Cargo"."Jostatus"
               
Ref: "jr_list"."Jrstatus" - "vw_Truck_Data_Cement_Cargo"."JRStatus"

Ref: "jo_list"."Activity" - "vw_Truck_Data_Cement_Cargo"."Activity"

Ref: "masterlist_tractor"."Assignment" - "vw_Truck_Data_Cement_Cargo"."Assignment"

Ref: "gps_live_data"."LastUpdate" - "vw_Truck_Data_Cement_Cargo"."LastUpdate"

Ref: "gps_live_data"."GpsStat" - "vw_Truck_Data_Cement_Cargo"."GpsStatus"

Ref: "urstat_ref"."Category" - "vw_Truck_Data_Cement_Cargo"."Trip"

Ref: "masterlist_tractor"."Brand" - "vw_Truck_Data_Cement_Cargo"."Brand"

Ref: "masterlist_tractor"."PairedTrailer" - "vw_Truck_Data_Cement_Cargo"."PairedTrailer"

Ref: "masterlist_tractor"."PlateNo" - "vw_Truck_Data_Cement_Cargo"."Unit"

Ref: "masterlist_tractor"."Head" - "vw_Truck_Data_Cement_Cargo"."Unit"

Ref: "masterlist_tractor"."Bu" - "vw_Truck_Data_Cement_Cargo"."Team"

ordr
        U_TranType--FILTER 

      ,[U_SORefNo]--DCT
      U_CustPONo --SFT
      U_SOARef --SFT
      U_PORef
      U_CementType
      U_DeliveryType
      U_Destination
      DocDate
      U_Source