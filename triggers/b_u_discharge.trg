CREATE OR REPLACE TRIGGER B_U_DISCHARGE
BEFORE UPDATE ON ALERT.DISCHARGE FOR EACH ROW
DECLARE
    xerr       interface.errors%ROWTYPE;
    l_error    VARCHAR2(4000);
    l_instit   episode.id_institution%TYPE;
    l_software epis_type_soft_inst.id_software%TYPE;
    l_module   VARCHAR2(10);

BEGIN
    IF :NEW.dt_admin_tstz IS NOT NULL
    THEN
        l_error := 'GET INFO';
        SELECT e.id_institution, etsi.id_software, decode(e.id_epis_type, 8, 'CON', 9, 'SAP') module
          INTO l_instit, l_software, l_module
          FROM episode e
         INNER JOIN epis_type_soft_inst etsi ON etsi.id_epis_type = e.id_epis_type
                                            AND etsi.id_institution = e.id_institution
         WHERE e.id_episode = :NEW.id_episode;
    
        IF l_module IN ('SAP')
        THEN
        
            l_error := 'INSERT INTO INTERFACE.OUT_DISCHARGE';
            INSERT INTO interface.out_discharge
                (id_discharge,
                 id_episode,
                 id_institution,
                 id_software,
                 cod_module,
                 dt_discharge,
                 id_professional,
                 id_discharge_dest)
            VALUES
                (:NEW.id_discharge,
                 :NEW.id_episode,
                 l_instit,
                 l_software,
                 l_module,
                 CAST(:NEW.dt_admin_tstz AS DATE),
                 :NEW.id_prof_med,
                 :NEW.id_disch_reas_dest);
        END IF;
    END IF;

EXCEPTION
    WHEN OTHERS THEN
        xerr.sqlerror    := SQLERRM;
        xerr.dt_error    := SYSDATE;
        xerr.title       := l_error;
        xerr.origin      := 'ALERT.B_U_DISCHARGE';
        xerr.description := ':NEW.ID_EPISODE:' || :NEW.id_episode;
        xerr.description := xerr.description || '| :NEW.ID_DISCH_REAS_DEST:' || :NEW.id_disch_reas_dest;
        xerr.description := xerr.description || '| :NEW.ID_PROF_MED:' || :NEW.id_prof_med;
        xerr.description := xerr.description || '| :NEW.DT_MED:' || :NEW.dt_med_tstz;
        xerr.description := xerr.description || '| :NEW.ID_PROF_ADMIN:' || :NEW.id_prof_admin;
        xerr.description := xerr.description || '| :NEW.DT_ADMIN:' || :NEW.dt_admin_tstz;
        xerr.description := xerr.description || '| :NEW.FLG_STATUS:' || :NEW.flg_status;
    
        xerr.num_marcacao := :NEW.id_discharge;
        SELECT userenv('SESSIONID')
          INTO xerr.session_id
          FROM dual;
    
        INSERT INTO interface.errors
            (dt_error, title, origin, description, sqlerror, num_marcacao, session_id)
        VALUES
            (xerr.dt_error,
             xerr.title,
             xerr.origin,
             xerr.description,
             xerr.sqlerror,
             xerr.num_marcacao,
             xerr.session_id);
END;
