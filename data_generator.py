import psycopg2

import psycopg2
conn = psycopg2.connect(host="127.0.0.1",
                        dbname="CCourses",
                        user="postgres",
                        password="otvernites")


cur = conn.cursor()

cur.execute('DELETE FROM "Available_equipment"')
cur.execute('DELETE FROM "Master_skills"')
cur.execute('DELETE FROM "Equipment"')
cur.execute('DELETE FROM "Purchased_equipment"')
cur.execute('DELETE FROM "Products"')
cur.execute('DELETE FROM "Class"')
cur.execute('DELETE FROM "Payment"')
cur.execute('DELETE FROM "Registration"')
cur.execute('DELETE FROM "Course"')
cur.execute('DELETE FROM "Course_type"')
cur.execute('DELETE FROM "Studio"')
cur.execute('DELETE FROM "Equipment_type"')
cur.execute('DELETE FROM "Master"')
cur.execute('DELETE FROM "Salary"')
cur.execute('DELETE FROM "Client"')
cur.execute('DELETE FROM "Certificate"')
cur.execute('DELETE FROM "Timetable"')

conn.commit()

with open('data/equipment_types.csv', 'r') as f:
    next(f) # Skip the header row.
    cur.copy_from(f, 'Equipment_type', sep=',')
print(1)
with open('data/salaries.csv', 'r') as f:
    next(f) # Skip the header row.
    cur.copy_from(f, 'Salary', sep=',')
print(2)
with open('data/course_types.csv', 'r') as f:
    next(f) # Skip the header row.
    cur.copy_from(f, 'Course_type', sep=',')
print(3)
with open('data/studious.csv', 'r') as f:
    next(f) # Skip the header row.
    cur.copy_from(f, 'Studio', sep=',')
print(4)
with open('data/courses.csv', 'r') as f:
    next(f) # Skip the header row.
    cur.copy_from(f, 'Course', sep=',')
print(5)
with open('data/masters.csv', 'r') as f:
    next(f) # Skip the header row.
    cur.copy_from(f, 'Master', sep=',')
print(6)
with open('data/classes.csv', 'r') as f:
    next(f) # Skip the header row.
    cur.copy_from(f, 'Class', sep=',')
print(7)
with open('data/equipments.csv', 'r') as f:
    next(f) # Skip the header row.
    cur.copy_from(f, 'Equipment', sep=',')
print(8)
with open('data/timetables.csv', 'r') as f:
    next(f) # Skip the header row.
    cur.copy_from(f, 'Timetable', sep=',')
print(9)
with open('data/av_equipments.csv', 'r') as f:
    next(f) # Skip the header row.
    cur.copy_from(f, 'Available_equipment', sep=',')
print(10)
with open('data/clients.csv', 'r') as f:
    next(f) # Skip the header row.
    cur.copy_from(f, 'Client', sep=',')
print(11)
with open('data/certificates.csv', 'r') as f:
    next(f) # Skip the header row.
    cur.copy_from(f, 'Certificate', sep=',')
print(12)
with open('data/master_skills.csv', 'r') as f:
    next(f) # Skip the header row.
    cur.copy_from(f, 'Master_skills', sep=',')
print(13)
with open('data/registrations.csv', 'r') as f:
    next(f) # Skip the header row.
    cur.copy_from(f, 'Registration', sep=',')
print(14)
with open('data/products.csv', 'r') as f:
    next(f) # Skip the header row.
    cur.copy_from(f, 'Products', sep=',')
print(15)
with open('data/pur_equipments.csv', 'r') as f:
    next(f) # Skip the header row.
    cur.copy_from(f, 'Purchased_equipment', sep=',')
print(16)
with open('data/payments.csv', 'r') as f:
    next(f) # Skip the header row.
    cur.copy_from(f, 'Payment', sep=',')
print(17)
""""""

conn.commit()
conn.close()
""""""