-- CHANGED BY:  Nuno Neves
-- CHANGE DATE: 14/12/2012 11:56
-- CHANGE REASON: [ALERT-247359] 
DECLARE
    CURSOR c_get_records IS
        SELECT *
          FROM interv_plan_dep_clin_serv;

    TYPE c_cursor_type IS TABLE OF c_get_records%ROWTYPE;
    l_get_records c_cursor_type;
    l_seq         NUMBER(24);
BEGIN

    OPEN c_get_records;

    FETCH c_get_records BULK COLLECT
        INTO l_get_records;

    FOR i IN 1 .. l_get_records.count
    LOOP
        l_seq := seq_interv_plan_dep_clin_serv.nextval;
    
        UPDATE interv_plan_dep_clin_serv d
           SET d.id_interv_plan_dep_clin_serv = l_seq
         WHERE d.id_interv_plan = l_get_records(i).id_interv_plan
           AND nvl(d.id_dep_clin_serv, -111111) = nvl(l_get_records(i).id_dep_clin_serv, -111111)
           AND nvl(d.id_professional, -111111) = nvl(l_get_records(i).id_professional, -111111)
           AND nvl(d.id_software, -111111) = nvl(l_get_records(i).id_software, -111111)
           AND nvl(d.id_institution, -111111) = nvl(l_get_records(i).id_institution, -111111)
           AND d.flg_type = l_get_records(i).flg_type;
    END LOOP;
END;
/
-- CHANGE END:  Nuno Neves