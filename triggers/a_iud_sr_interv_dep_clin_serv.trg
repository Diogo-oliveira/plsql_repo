CREATE OR REPLACE TRIGGER a_iud_sr_interv_dep_clin_serv
    AFTER INSERT OR UPDATE OR DELETE ON interv_dep_clin_serv
    FOR EACH ROW
DECLARE
    -- local variables here
    l_flg_cat_type       VARCHAR2(2 CHAR) := 'SR';
    l_flg_cat_type_value VARCHAR2(2 CHAR);

BEGIN

    IF inserting
       OR updating
    THEN
        BEGIN
            SELECT a.flg_category_type
              INTO l_flg_cat_type_value
              FROM intervention a
             INNER JOIN interv_dep_clin_serv b
                ON a.id_intervention = b.id_intervention
             WHERE b.id_interv_dep_clin_serv = :new.id_interv_dep_clin_serv;
        EXCEPTION
            WHEN no_data_found THEN
                l_flg_cat_type := NULL;
        END;
    ELSE
        BEGIN
            SELECT a.flg_category_type
              INTO l_flg_cat_type_value
              FROM intervention a
             INNER JOIN interv_dep_clin_serv b
                ON a.id_intervention = b.id_intervention
             WHERE b.id_interv_dep_clin_serv = :old.id_interv_dep_clin_serv;
        EXCEPTION
            WHEN no_data_found THEN
                l_flg_cat_type := NULL;
        END;
    END IF;

    IF l_flg_cat_type_value = l_flg_cat_type
    THEN
    
        IF inserting
        THEN
            pk_ia_event_backoffice.sr_interv_dep_clin_serv_new(i_id_sr_interv_dep_clin_serv => :new.id_interv_dep_clin_serv,
                                                               i_id_institution             => :new.id_institution);
        ELSIF updating
        THEN
            pk_ia_event_backoffice.sr_interv_dep_clin_serv_update(i_id_sr_interv_dep_clin_serv => :new.id_interv_dep_clin_serv,
                                                                  i_id_institution             => :new.id_institution);
        ELSIF deleting
        THEN
            pk_ia_event_backoffice.sr_interv_dep_clin_serv_delete(i_id_sr_interv_dep_clin_serv => :old.id_interv_dep_clin_serv,
                                                                  i_id_institution             => :old.id_institution,
                                                                  i_id_intervention            => :old.id_intervention,
                                                                  i_id_dep_clin_serv           => :old.id_dep_clin_serv);
        END IF;
    
    END IF;
END a_iud_sr_interv_dep_clin_serv;
/
