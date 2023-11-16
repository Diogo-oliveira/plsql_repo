CREATE OR REPLACE TRIGGER a_iud_interv_dep_clin_serv
    AFTER INSERT OR UPDATE OR DELETE ON interv_dep_clin_serv
    FOR EACH ROW
DECLARE

    l_type_interv_surgical CONSTANT VARCHAR2(1 CHAR) := 'S';
    l_procedure_type VARCHAR2(3 CHAR);

    FUNCTION get_procedure_type(interv intervention.id_intervention%TYPE) RETURN VARCHAR2 IS
    
        l_flg_type VARCHAR2(3 CHAR) := '';
    
    BEGIN
    
        SELECT a.flg_type
          INTO l_flg_type
          FROM intervention a
         WHERE a.id_intervention = interv;
    
        RETURN l_flg_type;
    
    EXCEPTION
        WHEN no_data_found THEN
            RETURN l_flg_type;
    END get_procedure_type;

BEGIN

    IF inserting
       OR updating
    THEN
        l_procedure_type := get_procedure_type(:new.id_intervention);
    ELSE
        l_procedure_type := get_procedure_type(:old.id_intervention);
    END IF;

    IF instr(l_procedure_type, l_type_interv_surgical) > 0
    THEN
        IF inserting
        THEN
            IF :new.id_dep_clin_serv IS NOT NULL
            THEN
                pk_ia_event_backoffice.sr_interv_dep_clin_serv_new(i_id_sr_interv_dep_clin_serv => :new.id_interv_dep_clin_serv,
                                                                   i_id_institution             => :new.id_institution);
            END IF;
        ELSIF updating
        THEN
            IF :new.id_dep_clin_serv IS NOT NULL
            THEN
                pk_ia_event_backoffice.sr_interv_dep_clin_serv_update(i_id_sr_interv_dep_clin_serv => :new.id_interv_dep_clin_serv,
                                                                      i_id_institution             => :new.id_institution);
            END IF;
        ELSIF deleting
        THEN
            IF :old.id_dep_clin_serv IS NOT NULL
            THEN
                pk_ia_event_backoffice.sr_interv_dep_clin_serv_delete(i_id_sr_interv_dep_clin_serv => :old.id_interv_dep_clin_serv,
                                                                      i_id_institution             => :old.id_institution,
                                                                      i_id_intervention            => :old.id_intervention,
                                                                      i_id_dep_clin_serv           => :old.id_dep_clin_serv);
            END IF;
        END IF;
    END IF;

END a_iud_sr_interv_dep_clin_serv;
/
