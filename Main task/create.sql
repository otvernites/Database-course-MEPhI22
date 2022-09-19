CREATE TYPE skill_state as enum ('Теория', 'Практика');
CREATE TYPE rent_state as enum ('Арендована', 'Свободна');

CREATE TABLE "Course_type"
(
    "Type_id"               serial PRIMARY KEY,
    "Course_name"           varchar(50)  not null UNIQUE,
    "Course_definition"     varchar(625) not null,
    "Total_course_duration" interval     not null CHECK ("Total_course_duration" >= '30 minutes'::interval)
);

CREATE TABLE "Studio"
(
    "Place_id"        serial PRIMARY KEY,
    "Latitude"        float          not null,
    "Longitude"       float          not null,
    "Capacity"        integer        not null CHECK ("Capacity" >= 3),
    "Rent_price"      numeric(12, 2) not null CHECK ("Rent_price" >= 1),
    "Rental_end_date" date           not null,
    "Status"          rent_state DEFAULT ('Свободна')
);

CREATE TABLE "Course"
(
    "Course_id"              serial PRIMARY KEY,
    "Type_id"                integer        not null REFERENCES "Course_type" ON DELETE restrict ON UPDATE cascade,
    "Place_id"               integer REFERENCES "Studio" ON DELETE restrict ON UPDATE cascade,
    "Course_start_date"      date           not null,
    "Number_of_classes_held" integer        not null CHECK ("Number_of_classes_held" >= 0) DEFAULT 0,
    "Course_cost"            numeric(12, 2) not null CHECK ("Course_cost" >= 1),
    "Number_of_members"      integer        not null CHECK ("Number_of_members" >= 0)      DEFAULT 0
);

CREATE TABLE "Master"
(
    "Personnel_id"    serial PRIMARY KEY,
    "Passport_series" varchar(15) not null,
    "Passport_id"     varchar(15) not null,
    "Surname"         varchar(30) not null,
    "Name"            varchar(30) not null,
    "Middle_name"     varchar(30) not null,
    "Specialist_type" skill_state not null,
    UNIQUE ("Passport_series", "Passport_id")
);

CREATE INDEX master_name_idx ON "Master" ("Surname", "Name");

CREATE TABLE "Salary"
(
    "Transaction_id" integer PRIMARY KEY,
    "Salary_rate"    numeric(8, 2) not null CHECK ("Salary_rate" >= 1)
);

CREATE TABLE "Class"
(
    "Class_id"        serial PRIMARY KEY,
    "Transaction_id"  integer     not null REFERENCES "Salary" ON DELETE restrict ON UPDATE cascade,
    "Course_id"       integer     not null REFERENCES "Course" ON DELETE restrict ON UPDATE cascade,
    "Personnel_id"    integer     not null REFERENCES "Master" ON DELETE restrict ON UPDATE cascade,
    "Class_type"      skill_state not null,
    "Class_duration"  interval    not null CHECK ("Class_duration" >= '30 minutes'::interval),
    "Start_date_time" timestamp   not null
);

CREATE TABLE "Client"
(
    "Client_id"      serial PRIMARY KEY,
    "Surname"        varchar(50) not null,
    "Name"           varchar(50) not null,
    "Middle_name"    varchar(50) not null,
    "Phone_number"   varchar(20) not null,
    "E-mail"         varchar(50) not null,
    "Account_number" integer     not null,
    CHECK ("Phone_number" SIMILAR TO '\+7[0-9]{10}'),
    CHECK ("E-mail" LIKE '%@%')
);

CREATE INDEX client_name_idx ON "Client" ("Surname", "Name");

CREATE TABLE "Registration"
(
    "Registration_id" serial PRIMARY KEY,
    "Course_id"       integer not null REFERENCES "Course" ON DELETE restrict ON UPDATE cascade,
    "Client_id"       integer not null REFERENCES "Client" ON DELETE restrict ON UPDATE cascade
);

CREATE TABLE "Medicine_chest"
(
    "Course_id"                   integer not null PRIMARY KEY REFERENCES "Course" ON DELETE restrict ON UPDATE cascade,
    "Total_number_of_medications" integer not null CHECK ("Total_number_of_medications" > 0)
);

CREATE TABLE "Products"
(
    "Product_id"             serial PRIMARY KEY,
    "Product_name"           varchar(50)   not null,
    "Product_quantity"       integer       not null CHECK ("Product_quantity" >= 0),
    "Average_purchase_price" numeric(9, 2) not null CHECK ("Average_purchase_price" >= 0),
    "Delivery_time"          interval      not null CHECK ("Delivery_time" >= '0 minutes'::interval),
    "Order_time"             timestamp     not null DEFAULT (current_timestamp),
    "Cost_of_delivery"       numeric(8, 2) not null CHECK ("Cost_of_delivery" >= 0),
    "Class_id"               integer       not null REFERENCES "Class" ON DELETE restrict ON UPDATE cascade
);

CREATE INDEX product_name_idx ON "Products" ("Product_name");

CREATE TABLE "Equipment_type"
(
    "Equipment_type" serial PRIMARY KEY,
    "Equipment_name" varchar(50) not null UNIQUE
);

CREATE INDEX equipment_name_idx ON "Equipment_type" ("Equipment_name");

CREATE TABLE "Equipment"
(
    "Equipment_id"        serial PRIMARY KEY,
    "Equipment_type"      integer        not null UNIQUE REFERENCES "Equipment_type" ON DELETE restrict ON UPDATE cascade,
    "Amount_of_equipment" integer        not null CHECK ("Amount_of_equipment" >= 0),
    "Class_id"            integer        not null REFERENCES "Class" ON DELETE restrict ON UPDATE cascade,
    "Average_rent_cost"   numeric(10, 2) not null CHECK ("Average_rent_cost" >= 1),
    "Delivery_cost"       numeric(8, 2)  not null CHECK ("Delivery_cost" >= 0),
    "Delivery_time"       interval       not null CHECK ("Delivery_time" >= '0 minutes'::interval)
);

CREATE INDEX equipment_type_idx1 ON "Equipment" ("Equipment_type");

CREATE TABLE "Medicine"
(
    "Medicine_id"   serial PRIMARY KEY,
    "Medicine_name" varchar(50)    not null UNIQUE,
    "Medicine_cost" numeric(10, 2) not null CHECK ("Medicine_cost" >= 1)
);

CREATE INDEX medicine_name_idx ON "Medicine" ("Medicine_name");

CREATE TABLE "Certificate"
(
    "Certificate_id"  serial PRIMARY KEY,
    "Client_id"       integer not null REFERENCES "Client" ON DELETE restrict ON UPDATE cascade,
    "Course_id"       integer not null REFERENCES "Course" ON DELETE restrict ON UPDATE cascade,
    "Course_end_date" date    not null
);

CREATE INDEX certificate_name_idx1 ON "Certificate" ("Client_id", "Course_id");

CREATE TABLE "Payment"
(
    "Payment_document_id" integer PRIMARY KEY,
    "Registration_id"     integer not null UNIQUE REFERENCES "Registration" ON DELETE restrict ON UPDATE cascade
);

CREATE TABLE "Client-intolerable_medicine"
(
    "Client_id"   integer REFERENCES "Client" ON DELETE SET NULL ON UPDATE cascade,
    "Medicine_id" integer REFERENCES "Medicine" ON DELETE SET NULL ON UPDATE cascade,
    PRIMARY KEY ("Medicine_id", "Client_id")
);

CREATE TABLE "Available_equipment"
(
    "Available_equipment_id" serial PRIMARY KEY,
    "Equipment_type"         integer not null REFERENCES "Equipment_type" ON DELETE restrict ON UPDATE cascade,
    "Amount_of_equipment"    integer not null CHECK ("Amount_of_equipment" >= 0),
    "Place_id"               integer not null REFERENCES "Studio" ON DELETE restrict ON UPDATE cascade
);

CREATE INDEX equipment_type_idx2 ON "Available_equipment" ("Equipment_type");

CREATE TABLE "Master-intolerable_medicine"
(
    "Personnel_id" integer REFERENCES "Master" ON DELETE SET NULL ON UPDATE cascade,
    "Medicine_id"  integer REFERENCES "Medicine" ON DELETE SET NULL ON UPDATE cascade,
    PRIMARY KEY ("Personnel_id", "Medicine_id")
);

CREATE TABLE "Master_skills"
(
    "Personnel_id" integer REFERENCES "Master" ON DELETE SET NULL ON UPDATE cascade,
    "Type_id"      integer REFERENCES "Course_type" ON DELETE SET NULL ON UPDATE cascade,
    PRIMARY KEY ("Personnel_id", "Type_id")
);

CREATE TABLE "Course_medicine"
(
    "Course_id"   integer REFERENCES "Medicine_chest" ON DELETE SET NULL ON UPDATE cascade,
    "Medicine_id" integer REFERENCES "Medicine" ON DELETE SET NULL ON UPDATE cascade,
    PRIMARY KEY ("Course_id", "Medicine_id")
);

CREATE TABLE "Purchased_equipment"
(
    "Purchased_equipment_id" serial PRIMARY KEY,
    "Equipment_type"         integer  not null REFERENCES "Equipment_type" ON DELETE restrict ON UPDATE cascade,
    "Amount_of_equipment"    integer  not null CHECK ("Amount_of_equipment" >= 0),
    "Order_time"             interval not null,
    "Place_id"               integer  not null REFERENCES "Studio" ON DELETE restrict ON UPDATE cascade,
    "Class_id"               integer  not null REFERENCES "Class" ON DELETE restrict ON UPDATE cascade
);

CREATE INDEX equipment_type_idx3 ON "Purchased_equipment" ("Equipment_type");