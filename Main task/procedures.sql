/* Процедура 1 - закупка оборудования из заказа */
--- Получаем тип оборудования, который надо докупить к определенному занятию
--- Получаем из списка заказов все количество необходимого оборудования
--- Проверяем, что у нас не избыток оборудования
--- Добавляем в список имеющегося оборудования "закупленное" количество
--- Из заказов удаляем старые записи

CREATE OR REPLACE PROCEDURE equipment_purchase(IN p_equipment_type integer, IN p_class_id integer) AS
$$
DECLARE
    equipment_amount_n INTEGER; --- necessary
    equipment_amount_a INTEGER; --- available
    equipment_amount_o INTEGER; --- final value

    place_id           INTEGER;
    quantity_in_order  INTEGER; --- in order table
BEGIN
    SELECT "Amount_of_equipment"
    INTO equipment_amount_n --- максимальное число оборудования необходимого типа
    FROM "Equipment"
    WHERE "Class_id" = p_class_id
      AND "Equipment_type" = p_equipment_type;
    RAISE notice 'necessary: %', equipment_amount_n;

    SELECT "Place_id"
    INTO place_id
    FROM "Course"
    WHERE "Course"."Course_id" = (SELECT "Course_id" FROM "Class" WHERE "Class_id" = p_class_id);

    SELECT "Amount_of_equipment"
    INTO equipment_amount_a -- существующее кол-во обородования необходимого типа
    FROM "Available_equipment"
    WHERE "Equipment_type" = p_equipment_type
      AND "Place_id" = place_id;
    RAISE notice 'available: %', equipment_amount_a;

    SELECT SUM("Amount_of_equipment")
    INTO quantity_in_order --- заказ оборудования данного типа
    FROM (SELECT "Amount_of_equipment"
          FROM "Purchased_equipment" tab2
          WHERE tab2."Equipment_type" = p_equipment_type
            AND tab2."Class_id" = p_class_id
            AND tab2."Place_id" = place_id) as t2;
    RAISE notice 'for purchase (not the final value): %', quantity_in_order;

    equipment_amount_o := equipment_amount_n - equipment_amount_a; --- ровно столько нужно докупить

    IF quantity_in_order > equipment_amount_o THEN
        RAISE notice 'Ordered more than needed!';
        quantity_in_order = equipment_amount_o;
    END IF;
    RAISE notice 'for purchase (final value): %', quantity_in_order;

    UPDATE "Available_equipment"
    SET "Amount_of_equipment" = "Amount_of_equipment" + quantity_in_order
    WHERE "Equipment_type" = p_equipment_type
      AND "Available_equipment"."Place_id" = place_id;

    DELETE
    FROM "Purchased_equipment"
    WHERE "Equipment_type" = p_equipment_type
      AND "Class_id" = p_class_id
      AND "Place_id" = place_id;
    RAISE notice 'deleted';
END
$$ LANGUAGE plpgsql;


/* Процедура 2 (курсор) - поиск наиболее подходящей студии для курса */
--- Есть возможность выбрать студии сразу для всех курсов
--- Или только для избранных
CREATE OR REPLACE PROCEDURE main_find_studio(IN p_all_courses bool, IN p_course_id integer[]) AS
$$
DECLARE
    r record;
    i record;
BEGIN
    IF p_all_courses IS TRUE THEN
        FOR r IN
            SELECT * FROM "Course" WHERE "Place_id" IS NULL
            LOOP
                RAISE notice '<< Номер %', r."Course_id";
                CALL find_studio(r."Course_id");
            END LOOP;
    ELSE
        IF p_course_id = '{}' THEN
            RAISE exception 'No course selected!';
        END IF;
        FOREACH i IN ARRAY p_course_id
            LOOP
                CALL find_studio(i);
            END LOOP;
    END IF;
END
$$ LANGUAGE plpgsql;


CREATE OR REPLACE PROCEDURE find_studio(IN p_course_id integer) AS
$$
DECLARE
    is_empty         INTEGER;
    studios_exist    BOOL;
    equipment_cost   NUMERIC(12, 2) = 0;
    profit           NUMERIC(12, 2) = 0;
    suitable_studios INTEGER[];
    all_difference   NUMERIC(12, 2)[];
    max_difference   FLOAT          = '-Infinity';
    result_place     INTEGER;
    rec              RECORD;
    i                RECORD;
    curs             REFCURSOR;
BEGIN
    SELECT "Place_id"
    INTO is_empty
    FROM "Course"
    WHERE "Course_id" = p_course_id;

    IF is_empty IS NOT NULL THEN
        RAISE exception 'A studio has already been rented for this course!';
    END IF;

    OPEN curs FOR
        SELECT *
        FROM "Studio"
        WHERE ("Status" != 'Арендована' OR
               "Rental_end_date" < (SELECT "Course_start_date" FROM "Course" WHERE "Course_id" = p_course_id))
          AND "Capacity" >= (SELECT "Number_of_members" FROM "Course" WHERE "Course_id" = p_course_id);
    LOOP
        FETCH curs INTO rec;
        EXIT WHEN NOT FOUND;

        SELECT EXISTS(SELECT * FROM "Available_equipment" WHERE "Place_id" = rec."Place_id") INTO studios_exist;

        IF studios_exist IS TRUE THEN
            FOR i in (SELECT * FROM "Available_equipment" WHERE "Place_id" = rec."Place_id")
                LOOP
                    SELECT "Average_rent_cost"
                    INTO equipment_cost
                    FROM (SELECT * FROM "Equipment" WHERE i."Equipment_type" = "Equipment_type") as "E*";
                    -- получаю суммарную стоимость оборудования, которое у меня уже есть (больше - лучше)
                    -- а цена аренды: меньше - лучше
                    profit = profit + equipment_cost;
                END LOOP;
            profit = profit - rec."Rent_price"; -- чем больше разница, тем лучше
            suitable_studios = array_append(suitable_studios, rec."Place_id");
            all_difference = array_append(all_difference, profit);
        ELSE
            RAISE notice '<< There are no suitable studios for the course %', p_course_id;
        END IF;
    END LOOP;
    CLOSE curs;

    RAISE notice 'Список студий: %', suitable_studios;
    RAISE notice 'Профиты: %', all_difference;

    IF array_length(suitable_studios, 1) > 0 THEN
        FOR i IN 1 .. array_upper(suitable_studios, 1)
            LOOP
                IF all_difference[i] > max_difference THEN
                    max_difference = all_difference[i];
                    result_place = suitable_studios[i];
                END IF;
            END LOOP;

        RAISE notice 'Выбрали студию: %', result_place;
        RAISE notice 'Выигрыш составил: %', max_difference;

        UPDATE "Course"
        SET "Place_id" = result_place
        WHERE "Course_id" = p_course_id;

        UPDATE "Studio"
        SET "Status" = 'Арендована'
        WHERE "Place_id" = result_place;
    ELSE
        RAISE notice '<< There are no suitable studios for the course %', p_course_id;
    END IF;
END
$$ LANGUAGE plpgsql;


--- 3 процедура - равномерное распределение мастеров по курсам
CREATE TABLE "Timetable"
(
    "Timetable_id" SERIAL PRIMARY KEY,
    "Personnel_id" integer REFERENCES "Master" ON DELETE SET NULL ON UPDATE cascade,
    "Type_id"      integer REFERENCES "Course_type" ON DELETE SET NULL ON UPDATE cascade
);

CREATE OR REPLACE PROCEDURE masters_distribution() AS
$$
DECLARE
    row             RECORD; -- строки таблицы скиллов Мастер-Количество_курсов,
    max_masters     INTEGER = 1; -- для одного курса
    current_masters INTEGER = 1; -- текущее кол-во мастеров на курсе
BEGIN
    -- Прохожу по строкам в табличке Master_skills (от наиболее невостребованного курса к более популярным)
    FOR row IN
        (SELECT *
         FROM ((SELECT "Personnel_id", COUNT("Personnel_id") c
                FROM "Master_skills"
                GROUP BY "Personnel_id"
                ORDER BY COUNT("Personnel_id")) as Pi
                  JOIN (SELECT * FROM "Master_skills") as Ms USING ("Personnel_id"))
         ORDER BY c)
        LOOP
            RAISE NOTICE '%', row;

            -- Каждый раз при занесении в распределение обновляю максимальное кол-во мастеров на курсе
            IF (EXISTS(SELECT 1 FROM "Timetable")) THEN
                SELECT MAX(y.num)
                INTO max_masters
                FROM (SELECT "Type_id", COUNT("Type_id") num
                      FROM "Timetable"
                      GROUP BY "Type_id") y;
            END IF;

            SELECT COUNT(*) INTO current_masters FROM (SELECT * FROM "Timetable" WHERE "Type_id" = row."Type_id") T;
            RAISE NOTICE 'type id %, current masters %, max masters %', row."Type_id", current_masters, max_masters;

            -- Обычная ситуация
            IF current_masters < max_masters AND NOT EXISTS(SELECT 1
                                                            FROM "Timetable"
                                                            WHERE row."Personnel_id" = "Personnel_id"
                                                              AND row."Type_id" = "Type_id") THEN
                INSERT INTO "Timetable" VALUES (default, row."Personnel_id", row."Type_id");
                DELETE FROM "Master_skills" WHERE "Type_id" = row."Type_id" AND "Personnel_id" = row."Personnel_id";
                RAISE NOTICE 'inserted';
                RAISE NOTICE 'no subcall %', row.c;
                -- Когда требуется пересчет
            ELSIF current_masters = max_masters AND
                  NOT EXISTS(SELECT 1 FROM "Timetable" WHERE row."Personnel_id" = "Personnel_id") THEN
                INSERT INTO "Timetable" VALUES (default, row."Personnel_id", row."Type_id");
                DELETE FROM "Master_skills" WHERE "Type_id" = row."Type_id" AND "Personnel_id" = row."Personnel_id";
                RAISE NOTICE 'inserted';
                RAISE NOTICE 'subcall start';
                CALL masters_distribution();
                RAISE NOTICE 'subcall end';
            END IF;
        END LOOP;
END
$$ LANGUAGE plpgsql;