DECLARE
    TYPE sup_quantity_nrs IS TABLE OF supply_workflow%ROWTYPE;
    l_data sup_quantity_nrs;

BEGIN

    SELECT sw.* BULK COLLECT
      INTO l_data
      FROM supply_workflow sw
      JOIN supply s ON s.id_supply = sw.id_supply
     WHERE s.flg_type = 'M';

    FOR indx IN 1 .. l_data.count
    LOOP
        UPDATE supply_workflow s
           SET s.total_avail_quantity =
               (SELECT s.total_avail_quantity
                  FROM supply_soft_inst s
                 WHERE s.id_supply = l_data(indx).id_supply
                   AND s.id_software = 80
                   AND s.flg_cons_type = 'L'
                   AND rownum = 1)
         WHERE s.id_supply_workflow = l_data(indx).id_supply_workflow;
    END LOOP;
END;
/
