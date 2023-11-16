-- CHANGED BY:  Nuno Neves
-- CHANGE DATE: 11/11/2011 09:45
-- CHANGE REASON: [ALERT-196713] 
DECLARE
    l_recurr table_number;
    l_iei    table_number;
BEGIN

    SELECT iei.id_icnp_epis_interv, iei.id_order_recurr_plan BULK COLLECT
      INTO l_iei, l_recurr
      FROM icnp_epis_intervention iei
     WHERE iei.id_order_recurr_plan IS NOT NULL;

    IF l_iei IS NOT NULL
       AND l_recurr IS NOT NULL
    THEN
        FOR i IN 1 .. l_iei.count
        LOOP        
            UPDATE icnp_interv_plan iip
               SET iip.id_order_recurr_plan = l_recurr(i)
             WHERE iip.id_icnp_epis_interv = l_iei(i);
        END LOOP;
    END IF;
END;
/
-- CHANGE END:  Nuno Neves