/* Запросы */

/* №1 - выводит тип оборудования и количество, которое нужно докупить
-- если имеющегося оборудования больше, чем требуемого - выводим 0
*/
WITH T2 AS (SELECT "Equipment_type", "Amount_of_equipment" equipment_amount_n, T1.equipment_amount_a
            FROM "Equipment"
                     JOIN (SELECT "Equipment_type", SUM("Amount_of_equipment") equipment_amount_a
                           FROM "Available_equipment"
                           GROUP BY "Equipment_type"
                           ORDER BY "Equipment_type") T1
                          USING ("Equipment_type")
)

SELECT "Equipment_type",
       SUM(CASE
               WHEN (T2.equipment_amount_n - T2.equipment_amount_a) < 0 THEN 0
               ELSE T2.equipment_amount_n - T2.equipment_amount_a
           END) AS Purchased_equipment
FROM T2
GROUP BY T2."Equipment_type"
ORDER BY T2."Equipment_type";


/* №2 - Выводим суммарную прибыль (или убытки) за каждый курс
--
*/
WITH t2 AS (SELECT "Course_id",
                   tt1."Transaction_id",
                   coalesce(tt2."Salary_rate" * EXTRACT(epoch FROM "Class_duration") / 3600, 0) as Total_salary,
                   coalesce(Product_cost, 0)                                                    as New_product_cost,
                   coalesce(Equipment_cost, 0)                                                  as New_Equipment_cost
            FROM "Class" as tt1
                     JOIN (SELECT * FROM "Salary") as tt2 ON tt1."Transaction_id" = tt2."Transaction_id"
                     FULL JOIN (SELECT "Class_id",
                                       ("Product_quantity" * "Average_purchase_price" + "Cost_of_delivery") as Product_cost
                                FROM "Products") as tt3 ON tt1."Class_id" = tt3."Class_id"
                     FULL JOIN (SELECT "Class_id", count * price + delivery as Equipment_cost
                                FROM (SELECT "Purchased_equipment"."Class_id",
                                             SUM("Purchased_equipment"."Amount_of_equipment") count,
                                             SUM("Average_rent_cost")                         price,
                                             SUM("Delivery_cost")                             delivery
                                      FROM "Purchased_equipment"
                                               JOIN "Equipment"
                                                    ON "Equipment"."Class_id" = "Purchased_equipment"."Class_id"
                                      GROUP BY "Purchased_equipment"."Class_id") as tt4) as tt5
                               ON tt5."Class_id" = tt1."Class_id"
),

-- Сформировали таблицу-полурезультат, где из всех вложений надо будет вычесть оставшиеся строки
     t1 AS (SELECT res."Course_id",
                   "Course_cost" * "Number_of_members" as All_investments,
                   "Rent_price",
                   SUM(Total_salary)                      salary,
                   SUM(New_product_cost)                  products,
                   SUM(New_equipment_cost)                equipment
            FROM "Course" as res
                     JOIN
                     (SELECT "Place_id", "Rent_price" FROM "Studio") as SRp ON res."Place_id" = SRp."Place_id"
                     FULL JOIN
                 t2 ON t2."Course_id" = res."Course_id"
            GROUP BY res."Course_id", "Rent_price", All_investments
            ORDER BY res."Course_id")

SELECT "Course_id", coalesce(All_investments - "Rent_price" - salary - products - equipment, 0) as Profit
FROM t1;


/* №3 - Получение расписания мастера
-- Выводим ФИО мастера
-- Выводим информацию о курсах, которые он ведет
-- Выводим список занятий на этом курсе

-- Для этого выводим Explain plan
*/
SELECT "Master"."Surname",
       "Master"."Name",
       "Master"."Middle_name",
       "Course_name",
       "Class_type",
       "Start_date_time"
FROM "Course_type"
         JOIN "Timetable" ON "Course_type"."Type_id" = "Timetable"."Type_id"
         JOIN "Master" ON "Timetable"."Personnel_id" = "Master"."Personnel_id"
         JOIN "Class" ON "Master"."Personnel_id" = "Class"."Personnel_id"
         JOIN "Client" ON "Client"."Surname" = "Master"."Surname" AND "Client"."Name" = "Master"."Name" AND
                          "Client"."Middle_name" = "Master"."Middle_name"
ORDER BY "Course_name";


/* №4 - Получить идентификатор занятия, и кол-во разных типов обрудования (тип-кол-во) в сделанных заказах
--
*/
SELECT "Class"."Class_id",
       count(DISTINCT "Purchased_equipment"."Equipment_type")                                          as "Number of different types",
       coalesce(SUM("Purchased_equipment"."Amount_of_equipment" * "Equipment"."Average_rent_cost"), 0) as "Total cost"
FROM "Class"
         LEFT OUTER JOIN "Purchased_equipment" ON "Class"."Class_id" = "Purchased_equipment"."Class_id"
         JOIN "Equipment" ON "Class"."Class_id" = "Equipment"."Class_id"
GROUP BY "Class"."Class_id";


/* №5 - Выбрать клиентов, которые имеют сертификаты за максимальное число курсов
--
*/
WITH T1 AS (
    SELECT DISTINCT "Client"."Client_id",
                    "Surname",
                    "Name",
                    "Middle_name",
                    count("Certificate_id") finished_course_amount
    FROM "Client"
             JOIN "Certificate" ON "Client"."Client_id" = "Certificate"."Client_id"
    GROUP BY "Surname", "Name", "Middle_name", "Client"."Client_id"
)
SELECT *
FROM T1
WHERE finished_course_amount = (SELECT max(finished_course_amount) FROM T1);


