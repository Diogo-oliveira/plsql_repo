CREATE OR REPLACE TRIGGER b_i_eval_mng
    BEFORE INSERT ON eval_mng
    FOR EACH ROW
-- PL/SQL Block
DECLARE
    l_exist NUMBER := 0;
BEGIN

    SELECT COUNT(1)
      INTO l_exist
      FROM eval_mng e
     WHERE e.flg_available = 'Y'
       AND e.id_institution = :new.id_institution
       AND e.id_software = :new.id_software
       AND e.id_market = :new.id_market
       AND ((EXISTS (SELECT 1
                       FROM eval_mng es
                      WHERE es.flg_available = 'Y'
                        AND es.flg_default = 'Y'
                        AND es.id_institution = :new.id_institution
                        AND es.id_software = :new.id_software
                        AND es.id_market = :new.id_market
                        AND :new.flg_default = 'Y')) OR
           (EXISTS (SELECT 1
                       FROM eval_mng es
                      WHERE es.flg_available = 'Y'
                        AND es.flg_default = 'Y'
                        AND es.id_institution = :new.id_institution
                        AND es.id_software = :new.id_software
                        AND es.id_market = :new.id_market
                        AND :new.flg_default = 'N'
                        AND es.id_cpt_code = :new.id_cpt_code)) OR
           (EXISTS (SELECT 1
                       FROM eval_mng es
                      WHERE es.flg_available = 'Y'
                        AND es.flg_default <> 'Y'
                        AND es.id_institution = :new.id_institution
                        AND es.id_software = :new.id_software
                        AND es.id_market = :new.id_market
                        AND es.id_cpt_code = :new.id_cpt_code)));

    IF l_exist > 0
    THEN
        raise_application_error(-20000, 'Constraint fail for default value.');
    END IF;

    -- 

EXCEPTION
    WHEN OTHERS THEN
        raise_application_error(-20000, 'Constraint fail for default value.');
    
END;
/
