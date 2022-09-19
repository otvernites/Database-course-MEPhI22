import os
import random

from faker import Faker
import csv

cur_dir = os.path.abspath(os.getcwd()) + "\\data"
COUNT = 100000
faker = Faker('ru')

skill_state = ['Теория', 'Практика']
rent_state = ['Арендована', 'Свободна']
interval = ['minutes', 'hours', 'days', 'weeks', 'mons', 'years']
interval_constr = ['hours', 'days', 'weeks', 'mons', 'years']


def generate_course_type(count):
    """
    CREATE TABLE "Course_type" (
        "Type_id"               serial                PRIMARY KEY,
        "Course_name"           varchar(50)  not null UNIQUE,
        "Course_definition"     varchar(625) not null,
        "Total_course_duration" interval     not null CHECK("Total_course_duration">='30 minutes'::interval)
    );
    """
    course_types = []
    for i in range(count):
        if i % 2 == 0:
            type = [i + 1, faker.unique.text(max_nb_chars=50), faker.text(max_nb_chars=70),
                    str(faker.random_int(30, 300)) + " " + random.choice(interval)]
        else:
            type = [i + 1, faker.unique.text(max_nb_chars=50), faker.text(max_nb_chars=70),
                    str(faker.random_int(1, 300)) + " " + random.choice(interval_constr)]
        course_types.append(type)
    return course_types


def generate_studio(count):
    """
    CREATE TABLE "Studio" (
        "Place_id"        serial          PRIMARY KEY,
        "Latitude"        float           not null,
        "Longitude"       float           not null,
        "Capacity"        integer         not null CHECK("Capacity">=3),
        "Rent_price"      numeric(12,2)   not null CHECK("Rent_price">=1),
        "Rental_end_date" date            not null,
        "Status"          rent_state      DEFAULT('Свободна')
    );
    """
    studious = []
    for i in range(count):
        studio = [i + 1, round(random.uniform(-90, 90), 5), round(random.uniform(-180, 180), 5),
                  faker.random_int(3, 5000), round(random.uniform(1, 5000000), 2),
                  faker.date_this_year(), random.choice(rent_state)]
        studious.append(studio)
    return studious


def generate_course(count, count_types, count_places):
    """
    CREATE TABLE "Course" (
        "Course_id"              serial         PRIMARY KEY,
        "Type_id"                integer        not null REFERENCES "Course_type" ON DELETE restrict ON UPDATE cascade,
        "Place_id"               integer        REFERENCES "Studio" ON DELETE restrict ON UPDATE cascade,
        "Course_start_date"      date           not null,
        "Number_of_classes_held" integer        not null CHECK("Number_of_classes_held">=0) DEFAULT 0,
        "Course_cost"            numeric(12,2)  not null CHECK("Course_cost">=1),
        "Number_of_members"      integer        not null CHECK("Number_of_members">=0) DEFAULT 0
    );
    """
    courses = []
    for i in range(count):
        type_id = faker.random_int(1, count_types)
        place_id = faker.random_int(1, count_places)
        course = [i + 1, type_id, place_id, faker.date_this_year(), faker.random_int(0, 1000),
                  round(random.uniform(1, 9999999999), 2), faker.random_int(0, 5000)]
        courses.append(course)
    return courses


def generate_master(count):
    """
    CREATE TABLE "Master" (
        "Personnel_id"    serial PRIMARY KEY,
        "Passport_series" varchar(15) not null,
        "Passport_id"     varchar(15) not null,
        "Surname"         varchar(30) not null,
        "Name"            varchar(30) not null,
        "Middle_name"     varchar(30) not null,
        "Specialist_type" skill_state not null,
        UNIQUE("Passport_series","Passport_id")
    );
    """
    masters = []
    for i in range(count):
        if i % 2 == 0:
            master = [i + 1, faker.plate_number_extra(), faker.unique.postcode(), faker.last_name_female(),
                      faker.first_name_female(), faker.middle_name_female(), random.choice(skill_state)]
        else:
            master = [i + 1, faker.plate_number_extra(), faker.unique.postcode(), faker.last_name_male(),
                      faker.first_name_male(), faker.middle_name_male(), random.choice(skill_state)]
        masters.append(master)
    return masters


def generate_salary(count):
    """
    CREATE TABLE "Salary" (
        "Transaction_id" integer      PRIMARY KEY,
        "Salary_rate"    numeric(8,2) not null CHECK("Salary_rate">=1)
    );
    """
    salaries = []
    for i in range(count):
        salary = [i + 1, round(random.uniform(1, 999999), 2)]
        salaries.append(salary)
    return salaries


def generate_class(count, count_transactions, count_courses, count_personals):
    """
    CREATE TABLE "Class" (
        "Class_id"        serial      PRIMARY KEY ,
        "Transaction_id"  integer     not null REFERENCES "Salary" ON DELETE restrict ON UPDATE cascade,
        "Course_id"       integer     not null REFERENCES "Course" ON DELETE restrict ON UPDATE cascade,
        "Personnel_id"    integer     not null REFERENCES "Master" ON DELETE restrict ON UPDATE cascade,
        "Class_type"      skill_state not null,
        "Class_duration"  interval    not null CHECK("Class_duration">='30 minutes'::interval),
        "Start_date_time" timestamp   not null
    );
    """
    classes = []
    for i in range(count):
        transaction_id = faker.random_int(1, count_transactions)
        course_id = faker.random_int(1, count_courses)
        personnel_id = faker.random_int(1, count_personals)

        if i % 2 == 0:
            class_ = [i + 1, transaction_id, course_id, personnel_id, random.choice(skill_state),
                str(faker.random_int(30, 300)) + " " + random.choice(interval), faker.date_time_this_year()]
        else:
            class_ = [i + 1, transaction_id, course_id, personnel_id, random.choice(skill_state),
                str(faker.random_int(1, 300)) + " " + random.choice(interval_constr), faker.date_time_this_year()]

        classes.append(class_)
    return classes


def generate_client(count):
    """
    CREATE TABLE "Client" (
        "Client_id"      serial      PRIMARY KEY,
        "Surname"        varchar(30) not null,
        "Name"           varchar(30) not null,
        "Middle_name"    varchar(30) not null,
        "Phone_number"   varchar(20) not null,
        "E-mail"         varchar(50) not null,
        "Account_number" integer     not null,
        UNIQUE("Surname", "Name", "Middle_name"),
        CHECK ("Phone_number" SIMILAR TO '\+7[0-9]{10}'),
        CHECK("E-mail" LIKE '%@%')
    );
    """
    clients = []
    for i in range(count):

        if i % 2 == 0:
            client = [i + 1, faker.last_name_female(), faker.first_name_female(), faker.middle_name_female(),
                      '+7' + faker.businesses_inn(), faker.email(), faker.kpp()]
        else:
            client = [i + 1, faker.last_name_male(), faker.first_name_male(), faker.middle_name_male(),
                      '+7' + faker.businesses_inn(), faker.email(), faker.kpp()]

        clients.append(client)
    return clients


def generate_registration(count, count_courses, count_clients):
    """
    CREATE TABLE "Registration" (
        "Registration_id" serial PRIMARY KEY,
        "Course_id"       integer not null REFERENCES "Course" ON DELETE restrict ON UPDATE cascade,
        "Client_id"       integer not null REFERENCES "Client" ON DELETE restrict ON UPDATE cascade
    );
    """
    registrations = []
    for i in range(count):
        course_id = faker.random_int(1, count_courses)
        client_id = faker.random_int(1, count_clients)

        registration = [i + 1, course_id, client_id]
        registrations.append(registration)
    return registrations


def generate_products(count, count_classes):
    """
    CREATE TABLE "Products" (
        "Product_id"             serial                  PRIMARY KEY,
        "Product_name"           varchar(50)    not null,
        "Product_quantity"       integer        not null CHECK("Product_quantity">=0),
        "Average_purchase_price" numeric(9,2)   not null CHECK("Average_purchase_price">=0),
        "Delivery_time"          interval       not null CHECK("Delivery_time">='0 minutes'::interval),
        "Order_time"             timestamp      not null DEFAULT(current_timestamp),
        "Cost_of_delivery"       numeric(8,2)   not null CHECK("Cost_of_delivery">=0),
        "Class_id"               integer        not null REFERENCES "Class" ON DELETE restrict ON UPDATE cascade
    );
    """
    products = []
    for i in range(count):
        class_id = faker.random_int(1, count_classes)

        product = [i + 1, faker.text(max_nb_chars=50), faker.random_int(0, 100000),
                   round(random.uniform(0, 8000000), 2), str(faker.random_int(0, 300)) + " " + random.choice(interval),
                   faker.date_time_this_year(), round(random.uniform(0, 800000), 2), class_id]
        products.append(product)
    return products


def generate_equipment_type(count):
    """
    CREATE TABLE "Equipment_type" (
        "Equipment_type"        serial                    PRIMARY KEY,
        "Equipment_name"        varchar(50)     not null  UNIQUE
    );
    """
    eq_types = []
    for i in range(count):
        eq_type = [i + 1, faker.unique.text(max_nb_chars=50)]
        eq_types.append(eq_type)
    return eq_types


def generate_equipment(count, count_eq_types, count_classes):
    """
    CREATE TABLE "Equipment" (
        "Equipment_id"        serial                  PRIMARY KEY,
        "Equipment_type"      integer        not null UNIQUE REFERENCES "Equipment_type" ON DELETE restrict ON UPDATE cascade,
        "Amount_of_equipment" integer        not null CHECK("Amount_of_equipment">=0),
        "Class_id"            integer        not null REFERENCES "Class" ON DELETE restrict ON UPDATE cascade,
        "Average_rent_cost"   numeric(10,2)  not null CHECK("Average_rent_cost">=1),
        "Delivery_cost"       numeric(8,2)   not null CHECK("Delivery_cost">=0),
        "Delivery_time"       interval       not null CHECK("Delivery_time">='0 minutes'::interval)
    );
    """
    equipments = []
    for i in range(count):
        # equipment_type = faker.random_int(1, count_eq_types)
        class_id = faker.random_int(1, count_classes)

        equipment = [i + 1, i + 1, faker.random_int(0, 1000000), class_id,
                     round(random.uniform(1, 90000000), 2), round(random.uniform(0, 500000), 2),
                     str(faker.random_int(0, 300)) + " " + random.choice(interval)]
        equipments.append(equipment)
    return equipments


def generate_certificate(count, count_clients, count_courses):
    """
    CREATE TABLE "Certificate" (
        "Certificate_id"  serial           PRIMARY KEY,
        "Client_id"       integer not null REFERENCES "Client" ON DELETE restrict ON UPDATE cascade,
        "Course_id"       integer not null REFERENCES "Course" ON DELETE restrict ON UPDATE cascade,
        "Course_end_date" date    not null
    );
    """
    certificates = []
    for i in range(count):
        client_id = faker.random_int(1, count_clients)
        course_id = faker.random_int(1, count_courses)

        certificate = [i + 1, client_id, course_id, faker.date_this_decade()]
        certificates.append(certificate)
    return certificates


def generate_payment(count, count_registrations):
    """
    CREATE TABLE "Payment" (
        "Payment_document_id" integer          PRIMARY KEY,
        "Registration_id"     integer not null UNIQUE REFERENCES "Registration" ON DELETE restrict ON UPDATE cascade
    );
    """
    payments = []
    for i in range(count):
        registration_id = faker.random_int(1, count_registrations)

        payment = [i + 1, i + 1]
        payments.append(payment)
    return payments


def generate_available_equipment(count, count_eq_types, count_places):
    """
    CREATE TABLE "Available_equipment" (
        "Available_equipment_id"  serial                PRIMARY KEY,
        "Equipment_type"          integer      not null REFERENCES "Equipment_type" ON DELETE restrict ON UPDATE cascade,
        "Amount_of_equipment"     integer      not null CHECK("Amount_of_equipment">=0),
        "Place_id"                integer      not null REFERENCES "Studio" ON DELETE restrict ON UPDATE cascade
    );
    """
    av_equipments = []
    for i in range(count):
        equipment_type = faker.random_int(1, count_eq_types)
        place_id = faker.random_int(1, count_places)

        av_equipment = [i + 1, equipment_type, faker.random_int(0, 1000000), place_id]
        av_equipments.append(av_equipment)
    return av_equipments


def generate_purchased_equipment(count, count_eq_types, count_places, count_classes):
    """
    CREATE TABLE "Purchased_equipment" (
        "Purchased_equipment_id" serial                  PRIMARY KEY,
        "Equipment_type"         integer        not null REFERENCES "Equipment_type" ON DELETE restrict ON UPDATE cascade,
        "Amount_of_equipment"    integer        not null CHECK("Amount_of_equipment">=0),
        "Order_time"             interval       not null,
        "Place_id"               integer        not null REFERENCES "Studio" ON DELETE restrict ON UPDATE cascade,
        "Class_id"               integer        not null REFERENCES "Class" ON DELETE restrict ON UPDATE cascade
    );
    """
    pur_equipments = []
    for i in range(count):
        equipment_type = faker.random_int(1, count_eq_types)
        place_id = faker.random_int(1, count_places)
        class_id = faker.random_int(1, count_classes)

        pur_equipment = [i + 1, equipment_type, faker.random_int(0, 1000000),
                         str(faker.random_int(0, 300)) + " " + random.choice(interval), place_id, class_id]
        pur_equipments.append(pur_equipment)
    return pur_equipments


def generate_master_skills(count, count_personals, count_types):
    """
    CREATE TABLE "Master_skills" (
        "Personnel_id" integer REFERENCES "Master" ON DELETE SET NULL ON UPDATE cascade,
        "Type_id"      integer REFERENCES "Course_type" ON DELETE SET NULL ON UPDATE cascade,
        PRIMARY KEY("Personnel_id", "Type_id")
    );
    """
    master_skills = []
    for i in range(count):
        personnel_id = faker.random_int(1, count_personals)
        type_id = faker.random_int(1, count_types)

        master_skill = [personnel_id, type_id]
        master_skills.append(master_skill)
    return master_skills


def generate_timetable(count, count_personals, count_types):
    """
    CREATE TABLE "Timetable" (
        "Timetable_id" SERIAL  PRIMARY KEY,
        "Personnel_id" integer REFERENCES "Master" ON DELETE SET NULL ON UPDATE cascade,
        "Type_id"      integer REFERENCES "Course_type" ON DELETE SET NULL ON UPDATE cascade
    );
    """
    timetables = []
    for i in range(count):
        personnel_id = faker.random_int(1, count_personals)
        type_id = faker.random_int(1, count_types)

        timetable = [i + 1, personnel_id, type_id]
        timetables.append(timetable)
    return timetables


if __name__ == "__main__":
    count = {
        "course_type": 0,
        "studio": 0,
        "course": 0,
        "master": 0,
        "salary": 0,
        "class": 0,
        "client": 0,
        "registration": 0,
        "products": 0,
        "equipment_type": 0,
        "equipment": 0,
        "certificate": 0,
        "payment": 0,
        "available_equipment": 0,
        "purchased_equipment": 0,
        "master_skills": 0,
        "timetable": 0
    }

    try:
        os.mkdir(cur_dir)
    except:
        print("Directory /data exists")

    #
    with open(str(cur_dir + "/course_types.csv"), "w") as course_types_file:
        writer = csv.writer(course_types_file, delimiter=',', lineterminator='\r', 
                                                            quotechar='"', quoting=csv.QUOTE_MINIMAL)
        course_types = generate_course_type(COUNT)

        writer.writerow(["Type_id", "Course_name", "Course_definition", "Total_course_duration"])
        count['course_type'] = len(course_types)

        for i in range(len(course_types)):
            writer.writerow(course_types[i])
  

    #
    with open(str(cur_dir + "/studious.csv"), "w") as studious_file:
        writer = csv.writer(studious_file, delimiter=',', lineterminator='\r', quotechar='"', quoting=csv.QUOTE_MINIMAL)
        studious = generate_studio(COUNT)

        writer.writerow(["Place_id", "Latitude", "Longitude", "Capacity", "Rent_price", "Rental_end_date", "Status"])
        count['studio'] = len(studious)

        for i in range(len(studious)):
            writer.writerow(studious[i])


    #
    with open(str(cur_dir + "/courses.csv"), "w") as courses_file:
        writer = csv.writer(courses_file, delimiter=',', lineterminator='\r', quotechar='"', quoting=csv.QUOTE_MINIMAL)
        courses = generate_course(COUNT, count['course_type'], count['studio'])

        writer.writerow(["Course_id", "Type_id", "Place_id", "Course_start_date",
                         "Number_of_classes_held", "Course_cost", "Number_of_members"])
        count['course'] = len(courses)

        for i in range(len(courses)):
            writer.writerow(courses[i])

    #
    with open(str(cur_dir + "/masters.csv"), "w") as masters_file:
        writer = csv.writer(masters_file, delimiter=',', lineterminator='\r', quotechar='"', quoting=csv.QUOTE_MINIMAL)
        masters = generate_master(COUNT)

        writer.writerow(["Personnel_id", "Passport_series", "Passport_id",
                         "Surname", "Name", "Middle_name", "Specialist_type"])
        count['master'] = len(masters)

        for i in range(len(masters)):
            writer.writerow(masters[i])

    #
    with open(str(cur_dir + "/salaries.csv"), "w") as salaries_file:
        writer = csv.writer(salaries_file, delimiter=',', lineterminator='\r', quotechar='"', quoting=csv.QUOTE_MINIMAL)
        salaries = generate_salary(COUNT)

        writer.writerow(["Transaction_id", "Salary_rate"])
        count['salary'] = len(salaries)

        for i in range(len(salaries)):
            writer.writerow(salaries[i])

    #
    with open(str(cur_dir + "/classes.csv"), "w") as classes_file:
        writer = csv.writer(classes_file, delimiter=',', lineterminator='\r', quotechar='"', quoting=csv.QUOTE_MINIMAL)
        classes = generate_class(COUNT, count['salary'], count['course'], count['master'])

        writer.writerow(["Class_id", "Transaction_id", "Course_id", "Personnel_id",
                         "Class_type", "Class_duration", "Start_date_time"])
        count['class'] = len(classes)

        for i in range(len(classes)):
            writer.writerow(classes[i])

    #
    with open(str(cur_dir + "/clients.csv"), "w") as clients_file:
        writer = csv.writer(clients_file, delimiter=',', lineterminator='\r', quotechar='"', quoting=csv.QUOTE_MINIMAL)
        clients = generate_client(COUNT)

        writer.writerow(["Client_id", "Surname", "Name", "Middle_name", "Phone_number", "E-mail", "Account_number"])
        count['client'] = len(clients)

        for i in range(len(clients)):
            writer.writerow(clients[i])

    #
    with open(str(cur_dir + "/registrations.csv"), "w") as registrations_file:
        writer = csv.writer(registrations_file, delimiter=',', lineterminator='\r', 
                                                                quotechar='"', quoting=csv.QUOTE_MINIMAL)
        registrations = generate_registration(COUNT, count['course'], count['client'])

        writer.writerow(["Registration_id", "Course_id", "Client_id"])
        count['registration'] = len(registrations)

        for i in range(len(registrations)):
            writer.writerow(registrations[i])

    #
    with open(str(cur_dir + "/products.csv"), "w") as products_file:
        writer = csv.writer(products_file, delimiter=',', lineterminator='\r', quotechar='"', quoting=csv.QUOTE_MINIMAL)
        products = generate_products(COUNT, count['class'])

        writer.writerow(["Product_id", "Product_name", "Product_quantity", "Average_purchase_price",
                         "Delivery_time", "Order_time", "Cost_of_delivery", "Class_id"])
        count['products'] = len(products)

        for i in range(len(products)):
            writer.writerow(products[i])

    #
    with open(str(cur_dir + "/equipment_types.csv"), "w") as equipment_types_file:
        writer = csv.writer(equipment_types_file, delimiter=',', lineterminator='\r', 
                                                                quotechar='"', quoting=csv.QUOTE_MINIMAL)
        equipment_types = generate_equipment_type(COUNT)

        writer.writerow(["Equipment_type", "Equipment_name"])
        count['equipment_type'] = len(equipment_types)

        for i in range(len(equipment_types)):
            writer.writerow(equipment_types[i])

    #
    with open(str(cur_dir + "/equipments.csv"), "w") as equipments_file:
        writer = csv.writer(equipments_file, delimiter=',', lineterminator='\r', 
                                                                quotechar='"', quoting=csv.QUOTE_MINIMAL)
        equipments = generate_equipment(COUNT, count['equipment_type'], count['class'])

        writer.writerow(["Equipment_id", "Equipment_type", "Amount_of_equipment", "Class_id",
                         "Average_rent_cost", "Delivery_cost", "Delivery_time"])
        count['equipment'] = len(equipments)

        for i in range(len(equipments)):
            writer.writerow(equipments[i])

    #
    with open(str(cur_dir + "/certificates.csv"), "w") as certificates_file:
        writer = csv.writer(certificates_file, delimiter=',', lineterminator='\r', 
                                                                quotechar='"', quoting=csv.QUOTE_MINIMAL)
        certificates = generate_certificate(COUNT, count['client'], count['course'])

        writer.writerow(["Certificate_id", "Client_id", "Course_id", "Course_end_date"])
        count['certificate'] = len(certificates)

        for i in range(len(certificates)):
            writer.writerow(certificates[i])

    #
    with open(str(cur_dir + "/payments.csv"), "w") as payments_file:
        writer = csv.writer(payments_file, delimiter=',', lineterminator='\r', quotechar='"', quoting=csv.QUOTE_MINIMAL)
        payments = generate_payment(COUNT, count['registration'])

        writer.writerow(["Payment_document_id", "Registration_id"])
        count['payment'] = len(payments)

        for i in range(len(payments)):
            writer.writerow(payments[i])

    #
    with open(str(cur_dir + "/av_equipments.csv"), "w") as av_equipments_file:
        writer = csv.writer(av_equipments_file, delimiter=',', lineterminator='\r', 
                                                                quotechar='"', quoting=csv.QUOTE_MINIMAL)
        av_equipments = generate_available_equipment(COUNT, count['equipment_type'], count['studio'])

        writer.writerow(["Available_equipment_id", "Equipment_type", "Amount_of_equipment", "Place_id"])
        count['available_equipment'] = len(av_equipments)

        for i in range(len(av_equipments)):
            writer.writerow(av_equipments[i])

    #
    with open(str(cur_dir + "/pur_equipments.csv"), "w") as pur_equipments_file:
        writer = csv.writer(pur_equipments_file, delimiter=',', lineterminator='\r',
                                                                    quotechar='"', quoting=csv.QUOTE_MINIMAL)
        pur_equipments = generate_purchased_equipment(COUNT, count['equipment_type'], count['studio'], count['class'])

        writer.writerow(["Purchased_equipment_id", "Equipment_type", "Amount_of_equipment",
                         "Order_time", "Place_id", "Class_id"])
        count['purchased_equipment'] = len(pur_equipments)

        for i in range(len(pur_equipments)):
            writer.writerow(pur_equipments[i])

    #
    with open(str(cur_dir + "/master_skills.csv"), "w") as master_skills_file:
        writer = csv.writer(master_skills_file, delimiter=',', lineterminator='\r', 
                                                                    quotechar='"', quoting=csv.QUOTE_MINIMAL)
        master_skills = generate_master_skills(COUNT, count['master'], count['course_type'])

        writer.writerow(["Personnel_id", "Type_id"])
        count['master_skills'] = len(master_skills)

        for i in range(len(master_skills)):
            writer.writerow(master_skills[i])

    #
    with open(str(cur_dir + "/timetables.csv"), "w") as timetables_file:
        writer = csv.writer(timetables_file, delimiter=',', lineterminator='\r', 
                                                                quotechar='"', quoting=csv.QUOTE_MINIMAL)
        timetables = generate_timetable(COUNT, count['master'], count['course_type'])

        writer.writerow(["Timetable_id", "Personnel_id", "Type_id"])
        count['timetable'] = len(timetables)

        for i in range(len(timetables)):
            writer.writerow(timetables[i])
