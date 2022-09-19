/* Сложный триггер - считает текущих клиентов на курсе */

CREATE OR REPLACE FUNCTION participants_count()
    RETURNS TRIGGER AS
$$
DECLARE
    course_id       INTEGER;
    place_id        INTEGER;
    capacity        INTEGER;
    current_members INTEGER;
BEGIN
    IF (TG_OP = 'INSERT') THEN
        SELECT "Course_id"
        INTO course_id
        FROM "Registration"
        WHERE "Registration_id" = new."Registration_id";
    ELSE
        SELECT "Course_id"
        INTO course_id
        FROM "Registration"
        WHERE "Registration_id" = old."Registration_id";
    END IF;

    SELECT "Place_id"
    INTO place_id
    FROM "Course"
    WHERE "Course_id" = course_id;

    SELECT COUNT(*)
    INTO current_members
    FROM (select
          from "Payment" t1
                   inner join "Registration" t2 on t1."Registration_id" = t2."Registration_id"
                   inner join "Course" t3 on t2."Course_id" = t3."Course_id"
          WHERE t3."Course_id" = course_id) as t;

    RAISE notice '%', current_members;

    IF place_id IS NULL THEN
        UPDATE "Course" SET "Number_of_members" = current_members WHERE "Course_id" = course_id;
        RAISE notice 'place is null';
    ELSE
        SELECT "Capacity"
        INTO capacity
        FROM "Studio"
        WHERE "Place_id" = place_id;

        IF current_members <= capacity THEN
            UPDATE "Course" SET "Number_of_members" = current_members WHERE "Course_id" = course_id;
            RAISE notice 'place is not null, +1';
        ELSE
            RAISE notice 'The maximum number of participants has been exceeded!';
        END IF;
    END IF;
    RETURN NEW;
END
$$ LANGUAGE plpgsql;

CREATE TRIGGER participants_count
    after INSERT OR DELETE
    ON "Payment"
    FOR EACH ROW
EXECUTE FUNCTION participants_count();


/* Простой триггер - при добавлении оборудования в класс прибавляет кол-во (если оно уже есть) */

CREATE OR REPLACE FUNCTION available_equipment()
    RETURNS TRIGGER AS
$$
DECLARE
    count INT;
BEGIN
    SELECT COUNT(*)
    INTO count
    FROM "Available_equipment"
    WHERE "Equipment_type" = new."Equipment_type"
      AND "Place_id" = new."Place_id";
    RAISE notice '%', count;
    IF count > 1 THEN
        UPDATE "Available_equipment"
        SET "Amount_of_equipment" = "Amount_of_equipment" + new."Amount_of_equipment"
        WHERE "Equipment_type" = new."Equipment_type"
          AND "Available_equipment_id" != new."Available_equipment_id"
          AND "Place_id" = new."Place_id";

        DELETE FROM "Available_equipment" where "Available_equipment_id" = new."Available_equipment_id";
        RAISE notice 'deleted';
    END IF;
    RETURN NEW;
END
$$ LANGUAGE plpgsql;

CREATE TRIGGER available_equipment
    after INSERT
    ON "Available_equipment"
    FOR EACH ROW
EXECUTE FUNCTION available_equipment();