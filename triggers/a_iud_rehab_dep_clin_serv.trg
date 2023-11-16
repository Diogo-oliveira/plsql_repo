create or replace
TRIGGER a_iud_rehab_dep_clin_serv
    AFTER INSERT OR UPDATE OR DELETE ON rehab_dep_clin_serv
    FOR EACH ROW
BEGIN
    IF inserting
    THEN
         pk_ia_event_rehabilitation.rehab_dep_clin_serv_new(i_id_rehab_session_type => :NEW.id_rehab_session_type,
                                                            i_id_dep_clin_serv      => :NEW.id_dep_clin_serv);
    ELSIF updating
    THEN
       pk_ia_event_rehabilitation.rehab_dep_clin_serv_update(i_id_rehab_session_type => :NEW.id_rehab_session_type,
                                                             i_id_dep_clin_serv      => :NEW.id_dep_clin_serv);
    ELSIF deleting
    THEN
        pk_ia_event_rehabilitation.rehab_dep_clin_serv_delete(i_id_rehab_session_type => :OLD.id_rehab_session_type,
																														  i_id_dep_clin_serv      => :OLD.id_dep_clin_serv);
    END IF;
END a_iud_rehab_dep_clin_serv;
/