DECLARE
    g_error           t_error_out;
    g_process         BOOLEAN := FALSE;
    g_data_to_migrate NUMBER;
    g_mess            VARCHAR2(4000);
    g_exception EXCEPTION;
    g_sli_stock_type_central CONSTANT VARCHAR2(1) := 'C';
    g_sli_stock_type_local   CONSTANT VARCHAR2(1) := 'L';

    g_sww_request_local   CONSTANT VARCHAR2(1) := 'A';
    g_sww_request_central CONSTANT VARCHAR2(1) := 'S';
    g_sww_cancelled       CONSTANT VARCHAR2(1) := 'C';
    g_sww_consumed        CONSTANT VARCHAR2(1) := 'O';

    v_id_supply_request       supply_request.id_supply_request%TYPE;
    v_id_supply_request_hist  supply_request_hist.id_supply_request_hist%TYPE;
    v_id_supply               supply.id_supply%TYPE;
    v_id_supply_location      supply_location.id_supply_location%TYPE;
    v_prof                    alert.profissional;
    v_wf_status               supply_workflow.flg_status%TYPE;
    v_period                  VARCHAR2(200);
    v_id_supply_workflow      supply_workflow.id_supply_workflow%TYPE;
    v_id_supply_workflow_hist supply_workflow_hist.id_supply_workflow_hist%TYPE;
    v_lang                    language.id_language%TYPE;
    v_flg_cons_type           supply_soft_inst.flg_cons_type%TYPE;
    v_flg_reusable            supply_soft_inst.flg_reusable%TYPE;
    v_flg_editable            supply_soft_inst.flg_editable%TYPE;
    v_flg_preparing           supply_soft_inst.flg_preparing%TYPE;
    v_flg_countable           supply_soft_inst.flg_countable%TYPE;
    v_id_dept                 episode.id_dept_requested%TYPE;


		PROCEDURE announce_error(i_message VARCHAR2) IS
		BEGIN
				g_mess := current_timestamp || ': E R R O R : ' || i_message || chr(13) || ' :SQLCODE: ' || SQLCODE ||
									' :SQLERRM: ' || SQLERRM || chr(13) || ' :ERROR_STACK: ' || dbms_utility.format_error_stack ||
									' :ERROR_BACKTRACE: ' || dbms_utility.format_error_backtrace || ' :CALL_STACK: ' ||
									dbms_utility.format_call_stack;
				dbms_output.put_line(g_mess);

				pk_alertlog.log_error(text => g_mess, object_name => 'MIGRATION_SR_SUPPLY');
				dbms_output.put_line('Error on data migration. Please look into alertlog.tlog table in ''MIGRATION_SR_SUPPLY'' section. Example:
		select *
			from alertlog.tlog
		 where lsection = ''MIGRATION_SR_SUPPLY''
		 order by 2 desc, 3 desc, 1 desc;');
		END announce_error;		

    PROCEDURE log_reg(i_message VARCHAR2) IS
        l_m VARCHAR2(4000);
    BEGIN
        l_m := current_timestamp || ': L O G : ' || i_message;
        dbms_output.put_line(l_m);
        pk_alertlog.log_debug(text => l_m, object_name => 'MIGRATION_SR_SUPPLY');
    END log_reg;

    FUNCTION ins_request_hist
    (
        i_id_supply_request      IN supply_request.id_supply_request%TYPE,
        i_id_supply_request_hist IN supply_request_hist.id_supply_request_hist%TYPE
    ) RETURN BOOLEAN IS
    BEGIN
        g_mess := 'insert request_hist';
        INSERT INTO supply_request_hist
            (id_supply_request_hist,
             id_supply_request,
             id_professional,
             id_episode,
             id_room_req,
             id_context,
             flg_context,
             dt_request,
             flg_status,
             flg_reason,
             flg_prof_prep,
             id_prof_cancel,
             dt_cancel,
             notes_cancel,
             id_cancel_reason,
             notes)
            SELECT i_id_supply_request_hist,
                   sr.id_supply_request,
                   sr.id_professional,
                   sr.id_episode,
                   sr.id_room_req,
                   sr.id_context,
                   sr.flg_context,
                   sr.dt_request,
                   sr.flg_status,
                   sr.flg_reason,
                   sr.flg_prof_prep,
                   sr.id_prof_cancel,
                   sr.dt_cancel,
                   sr.notes_cancel,
                   sr.id_cancel_reason,
                   sr.notes
              FROM supply_request sr
             WHERE sr.id_supply_request = i_id_supply_request;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            announce_error(g_mess);
            RETURN FALSE;
    END ins_request_hist;

    FUNCTION exec_request
    (
        i_id_supply_request      IN supply_request.id_supply_request%TYPE,
        i_id_prof_exec           IN sr_reserv_req.id_prof_exec%TYPE,
        i_id_supply_request_hist OUT supply_request_hist.id_supply_request_hist%TYPE
    ) RETURN BOOLEAN IS
    BEGIN
        g_mess := 'get id_supply_request_hist';
        SELECT seq_supply_request_hist.nextval
          INTO i_id_supply_request_hist
          FROM dual;
    
        g_mess := 'insert request_hist';
        IF NOT ins_request_hist(i_id_supply_request, i_id_supply_request_hist)
        THEN
            RAISE g_exception;
        END IF;
    
        g_mess := 'update request';
        UPDATE supply_request sr
           SET sr.id_professional = i_id_prof_exec,
               sr.flg_status      = 'F'
         WHERE sr.id_supply_request = i_id_supply_request;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            announce_error(g_mess);
            RETURN FALSE;
    END exec_request;

    FUNCTION cancel_request
    (
        i_id_supply_request      IN supply_request.id_supply_request%TYPE,
        i_id_prof_cancel         IN sr_reserv_req.id_prof_cancel%TYPE,
        i_dt_cancel              IN sr_reserv_req.dt_cancel_tstz%TYPE,
        i_notes_cancel           IN sr_reserv_req.notes_cancel%TYPE,
        i_id_supply_request_hist OUT supply_request_hist.id_supply_request_hist%TYPE
    ) RETURN BOOLEAN IS
    BEGIN
        g_mess := 'get id_supply_request_hist';
        SELECT seq_supply_request_hist.nextval
          INTO i_id_supply_request_hist
          FROM dual;
    
        g_mess := 'insert request_hist';
        IF NOT ins_request_hist(i_id_supply_request, i_id_supply_request_hist)
        THEN
            RAISE g_exception;
        END IF;
    
        g_mess := 'update request';
        UPDATE supply_request sr
           SET sr.id_professional = i_id_prof_cancel, 
               sr.id_prof_cancel  = i_id_prof_cancel,
               sr.dt_cancel       = i_dt_cancel,
               sr.notes_cancel    = i_notes_cancel,
               sr.flg_status      = 'C'
         WHERE sr.id_supply_request = i_id_supply_request;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            announce_error(g_mess);
            RETURN FALSE;
    END cancel_request;

    FUNCTION get_default_location
    (
        i_prof      IN profissional,
        i_id_supply IN supply.id_supply%TYPE
    ) RETURN NUMBER IS
        l_id_location supply_location.id_supply_location%TYPE;
    BEGIN
        g_mess := 'GET DEFAULT LOCATION :i_id_supply:' || i_id_supply || ' :prof.id:' || i_prof.id ||
                  ' :prof.id_institution:' || i_prof.institution || ' :prof.id_sofware:' || i_prof.software;
    
        BEGIN
        
            SELECT sld.id_supply_location
              INTO l_id_location
              FROM supply_soft_inst ssi
              JOIN supply_loc_default sld ON sld.id_supply_soft_inst = ssi.id_supply_soft_inst
              JOIN supply_location sl ON sl.id_supply_location = sld.id_supply_location
             INNER JOIN supply_sup_area ssa ON ssa.id_supply_soft_inst = ssi.id_supply_soft_inst
                                           AND ssa.flg_available = 'Y'
                                           AND ssa.id_supply_area = 3
             WHERE sld.flg_default = 'Y'
               AND nvl(ssi.id_professional, 0) IN (0, i_prof.id)
               AND nvl(ssi.id_institution, 0) IN (0, i_prof.institution)
               AND nvl(ssi.id_software, 0) IN (0, i_prof.software)
               AND ssi.id_supply = i_id_supply
               AND rownum = 1;
        EXCEPTION
            WHEN no_data_found THEN
                BEGIN
                    SELECT loc.id_supply_location
                      INTO l_id_location
                      FROM (SELECT sld.id_supply_location
                              FROM supply_soft_inst ssi
                              JOIN supply_loc_default sld ON sld.id_supply_soft_inst = ssi.id_supply_soft_inst
                              JOIN supply_location sl ON sl.id_supply_location = sld.id_supply_location
                             INNER JOIN supply_sup_area ssa ON ssa.id_supply_soft_inst = ssi.id_supply_soft_inst
                                                           AND ssa.flg_available = 'Y'
                                                           AND ssa.id_supply_area = 3
                             WHERE nvl(ssi.id_professional, 0) IN (0, i_prof.id)
                               AND nvl(ssi.id_institution, 0) IN (0, i_prof.institution)
                               AND nvl(ssi.id_software, 0) IN (0, i_prof.software)
                               AND ssi.id_supply = i_id_supply
                             ORDER BY sl.flg_stock_type DESC) loc -- 1st stock local L
                     WHERE rownum = 1;
                EXCEPTION
                    WHEN no_data_found THEN
                       SELECT loc.id_supply_location
                          INTO l_id_location
                          FROM (SELECT sl.id_supply_location
                                  FROM supply_location sl
                                 WHERE nvl(sl.id_institution, 0) IN (0, i_prof.institution)
                                 ORDER BY sl.flg_stock_type DESC) loc -- 1st stock local L
                         WHERE rownum = 1;
                END;
        END;
    
        RETURN l_id_location;
    END get_default_location;

    FUNCTION get_status
    (
        i_prof               IN profissional,
        i_id_supply_location IN supply_location.id_supply_location%TYPE
    ) RETURN supply_workflow.flg_status%TYPE IS
        l_flg_status supply_workflow.flg_status%TYPE;
    BEGIN
        g_mess := 'GET STATUS WORKFLOW';
        SELECT decode(sl.flg_stock_type,
                      g_sli_stock_type_local,
                      g_sww_request_local,
                      g_sli_stock_type_central,
                      g_sww_request_central)
          INTO l_flg_status
          FROM supply_location sl
         WHERE sl.id_supply_location = i_id_supply_location
           AND nvl(sl.id_institution, 0) IN (0, i_prof.institution);
    
        RETURN l_flg_status;
    END get_status;

    FUNCTION get_prof
    (
        i_id_professional IN professional.id_professional%TYPE,
        i_id_episode      IN episode.id_episode%TYPE
    ) RETURN alert.profissional IS
        l_prof           alert.profissional;
        l_id_software    software.id_software%TYPE;
        l_id_prof        professional.id_professional%TYPE;
        l_id_institution institution.id_institution%TYPE;
    BEGIN
        SELECT decode(e.id_epis_type, 1, 1, 2, 8, 4, 2, 5, 11, 2), i_id_professional, e.id_institution
          INTO l_id_software, l_id_prof, l_id_institution
          FROM episode e
         WHERE e.id_episode = i_id_episode;
    
        l_prof := alert.profissional(id => l_id_prof, institution => l_id_institution, software => l_id_software);
    
        RETURN l_prof;
    END get_prof;

    FUNCTION get_lang(i_prof IN alert.profissional) RETURN language.id_language%TYPE IS
        l_lang sys_config.value%TYPE;
    BEGIN
    
        g_mess := 'get LANGUAGE sys config';
        SELECT alert.pk_sysconfig.get_config('LANGUAGE', i_prof)
          INTO l_lang
          FROM dual;
    
        g_mess := 'get language from prof preferences';
        BEGIN
            SELECT a.id_language
              INTO l_lang
              FROM (SELECT pp.id_language
                      FROM prof_preferences pp, LANGUAGE l, professional prof
                     WHERE pp.id_professional = i_prof.id
                       AND pp.id_language = l_lang
                       AND prof.id_professional = pp.id_professional
                       AND pp.id_professional = prof.id_professional
                       AND pp.id_software IN (i_prof.software, 0)
                       AND pp.id_institution = i_prof.institution
                     ORDER BY pp.id_software DESC) a
             WHERE rownum = 1;
        EXCEPTION
            WHEN no_data_found THEN
                NULL;
        END;
    
        RETURN l_lang;
    END get_lang;

    FUNCTION get_period
    (
        i_id_surg_period IN sr_surg_period.id_surg_period%TYPE,
        i_lang           IN language.id_language%TYPE
    ) RETURN VARCHAR2 IS
        l_desc_period VARCHAR2(200);
    BEGIN
        IF i_id_surg_period IS NOT NULL
        THEN
            SELECT pk_translation.get_translation(i_lang, ssp.code_surg_period)
              INTO l_desc_period
              FROM sr_surg_period ssp
             WHERE ssp.id_surg_period = i_id_surg_period;
        END IF;
    
        RETURN l_desc_period;
    
    END get_period;

    FUNCTION ins_workflow_hist
    (
        i_id_supply_workflow      IN supply_workflow.id_supply_workflow%TYPE,
        i_id_supply_workflow_hist IN supply_workflow_hist.id_supply_workflow_hist%TYPE
    ) RETURN BOOLEAN IS
    BEGIN
        g_mess := 'insert request_hist';
        INSERT INTO supply_workflow_hist
            (id_supply_workflow_hist,
             id_supply_workflow,
             id_professional,
             id_episode,
             id_supply_request,
             id_supply,
             id_supply_location,
             barcode_req,
             barcode_scanned,
             quantity,
             id_unit_measure,
             id_context,
             flg_context,
             flg_status,
             dt_request,
             dt_returned,
             notes,
             id_prof_cancel,
             dt_cancel,
             notes_cancel,
             id_cancel_reason,
             notes_reject,
             dt_reject,
             id_prof_reject,
             dt_supply_workflow,
             id_req_reason,
             id_del_reason,
             id_supply_set,
             id_sup_workflow_parent,
             total_quantity,
             asset_number,
             flg_outdated,
             total_avail_quantity,
             cod_table,
             flg_cons_type,
             flg_reusable,
             flg_editable,
             flg_preparing,
             flg_countable,
             id_protocols,
             id_supply_area)
            SELECT i_id_supply_workflow_hist,
                   sw.id_supply_workflow,
                   sw.id_professional,
                   sw.id_episode,
                   sw.id_supply_request,
                   sw.id_supply,
                   sw.id_supply_location,
                   sw.barcode_req,
                   sw.barcode_scanned,
                   sw.quantity,
                   sw.id_unit_measure,
                   sw.id_context,
                   sw.flg_context,
                   sw.flg_status,
                   sw.dt_request,
                   sw.dt_returned,
                   sw.notes,
                   sw.id_prof_cancel,
                   sw.dt_cancel,
                   sw.notes_cancel,
                   sw.id_cancel_reason,
                   sw.notes_reject,
                   sw.dt_reject,
                   sw.id_prof_reject,
                   sw.dt_supply_workflow,
                   sw.id_req_reason,
                   sw.id_del_reason,
                   sw.id_supply_set,
                   sw.id_sup_workflow_parent,
                   sw.total_quantity,
                   sw.asset_number,
                   sw.flg_outdated,
                   sw.total_avail_quantity,
                   sw.cod_table,
                   sw.flg_cons_type,
                   sw.flg_reusable,
                   sw.flg_editable,
                   sw.flg_preparing,
                   sw.flg_countable,
                   sw.id_protocols,
                   sw.id_supply_area
              FROM supply_workflow sw
             WHERE sw.id_supply_workflow = i_id_supply_workflow;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            announce_error(g_mess);
            RETURN FALSE;
    END ins_workflow_hist;

    FUNCTION cancel_workflow
    (
        i_id_supply_workflow      IN supply_workflow.id_supply_workflow%TYPE,
        i_id_prof_cancel          IN sr_reserv_req.id_prof_cancel%TYPE,
        i_dt_cancel               IN sr_reserv_req.dt_cancel_tstz%TYPE,
        i_notes_cancel            IN sr_reserv_req.notes_cancel%TYPE,
        i_id_supply_workflow_hist OUT supply_workflow_hist.id_supply_workflow_hist%TYPE
    ) RETURN BOOLEAN IS
    BEGIN
        g_mess := 'get id_supply_workflow_hist';
        SELECT seq_supply_workflow_hist.nextval
          INTO i_id_supply_workflow_hist
          FROM dual;
    
        g_mess := 'insert workflow_hist';
        IF NOT ins_workflow_hist(i_id_supply_workflow, i_id_supply_workflow_hist)
        THEN
            RAISE g_exception;
        END IF;
    
        g_mess := 'update workflow';
        UPDATE supply_workflow sw
           SET sw.id_professional    = i_id_prof_cancel,
               sw.id_prof_cancel     = i_id_prof_cancel,
               sw.dt_cancel          = i_dt_cancel,
               sw.dt_supply_workflow = i_dt_cancel,
               sw.notes_cancel       = i_notes_cancel,
               sw.flg_status         = g_sww_cancelled --'C'
         WHERE sw.id_supply_workflow = i_id_supply_workflow;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            announce_error(g_mess);
            RETURN FALSE;
    END cancel_workflow;

    FUNCTION exec_workflow
    (
        i_id_supply_workflow      IN supply_workflow.id_supply_workflow%TYPE,
        i_id_prof_exec            IN sr_reserv_req.id_prof_exec%TYPE,
        i_dt_exec                 IN sr_reserv_req.dt_exec_tstz%TYPE,
        i_id_supply_workflow_hist OUT supply_workflow_hist.id_supply_workflow_hist%TYPE
    ) RETURN BOOLEAN IS
    BEGIN
        g_mess := 'get id_supply_workflow_hist';
        SELECT seq_supply_workflow_hist.nextval
          INTO i_id_supply_workflow_hist
          FROM dual;
    
        g_mess := 'insert workflow_hist';
        IF NOT ins_workflow_hist(i_id_supply_workflow, i_id_supply_workflow_hist)
        THEN
            RAISE g_exception;
        END IF;
    
        g_mess := 'update workflow';
        UPDATE supply_workflow sw
           SET sw.id_professional    = i_id_prof_exec, 
               sw.dt_supply_workflow = i_dt_exec,
               sw.flg_status         = g_sww_consumed --'O'
         WHERE sw.id_supply_workflow = i_id_supply_workflow;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            announce_error(g_mess);
            RETURN FALSE;
    END exec_workflow;

    FUNCTION validate_content RETURN BOOLEAN IS
        l_count_equip_without_content  NUMBER := 0;
        l_count_supply_without_content NUMBER := 0;
        l_count_equip_supply           NUMBER := 0;
    BEGIN
    
        g_mess := 'check if all content have id_content and id_content_new';
        SELECT COUNT(*)
          INTO l_count_equip_without_content
          FROM sr_equip sre
         WHERE (sre.id_content IS NULL OR sre.id_content_new IS NULL)
           AND sre.flg_hemo_yn = 'N';
    
        IF l_count_equip_without_content = 0
        THEN
        
            g_mess := 'check if all equip exists in supply table';
            SELECT COUNT(*)
              INTO l_count_equip_supply
              FROM sr_equip sre
              LEFT JOIN supply s ON s.id_content = sre.id_content_new
             WHERE s.id_supply IS NULL
               AND sre.flg_hemo_yn = 'N';
        
            IF l_count_equip_supply = 0 
            THEN
                RETURN TRUE;
            ELSE
                g_mess := 'missing sr_equip vs supply';
                RETURN FALSE;
            END IF;
        
        ELSE
            g_mess := 'missing sr_equip id_content or id_content_new';
            RETURN FALSE;
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
            announce_error(g_mess);
            RETURN FALSE;
        
    END validate_content;

    FUNCTION check_data_to_migrate(o_data_to_migrate OUT NUMBER) RETURN BOOLEAN IS
    BEGIN
    
        SELECT COUNT(*)
          INTO o_data_to_migrate
          FROM sr_reserv_req srr
         INNER JOIN sr_equip sre ON srr.id_sr_equip = sre.id_sr_equip
         WHERE sre.flg_hemo_yn = 'N';
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            announce_error(g_mess);
            RETURN FALSE;
    END check_data_to_migrate;

    FUNCTION ins_mapping_table
    (
        i_id_sr_reserv_req   IN sr_reserv_req.id_sr_reserv_req%TYPE,
        i_id_supply_workflow IN supply_workflow.id_supply_workflow%TYPE
    ) RETURN BOOLEAN IS
    BEGIN
        g_mess := 'insert into sr_reserv_req_to_supply';
        INSERT INTO sr_reserv_req_to_supply
            (id_sr_reserv_req, id_supply_workflow)
        VALUES
            (i_id_sr_reserv_req, i_id_supply_workflow);
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            announce_error(g_mess);
            RETURN FALSE;
    END ins_mapping_table;

    FUNCTION get_supply_soft_inst
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN alert.profissional,
        i_id_supply     IN supply.id_supply%TYPE,
        i_id_dept       IN episode.id_dept_requested%TYPE,
        o_flg_cons_type OUT supply_soft_inst.flg_cons_type%TYPE,
        o_flg_reusable  OUT supply_soft_inst.flg_reusable%TYPE,
        o_flg_editable  OUT supply_soft_inst.flg_editable%TYPE,
        o_flg_preparing OUT supply_soft_inst.flg_preparing%TYPE,
        o_flg_countable OUT supply_soft_inst.flg_countable%TYPE
    ) RETURN BOOLEAN IS
        l_id_supply_soft_inst supply_soft_inst.id_supply_soft_inst%TYPE;
    
    BEGIN
    
        SELECT t.id_supply_soft_inst, t.flg_cons_type, t.flg_reusable, t.flg_editable, t.flg_preparing, t.flg_countable
          INTO l_id_supply_soft_inst, o_flg_cons_type, o_flg_reusable, o_flg_editable, o_flg_preparing, o_flg_countable
          FROM (SELECT sswi.id_supply_soft_inst,
                       decode(sswi.flg_cons_type, 'L', 'C', sswi.flg_cons_type) flg_cons_type,
                       sswi.flg_reusable,
                       sswi.flg_editable,
                       sswi.flg_preparing,
                       sswi.flg_countable
                  FROM (SELECT 1 ra,
                               ssi.id_supply_soft_inst,
                               ssi.flg_cons_type,
                               ssi.flg_reusable,
                               ssi.flg_editable,
                               ssi.flg_preparing,
                               ssi.flg_countable
                          FROM supply_soft_inst ssi
                         INNER JOIN supply s ON s.id_supply = ssi.id_supply
                         INNER JOIN supply_sup_area ssa ON ssa.id_supply_soft_inst = ssi.id_supply_soft_inst
                                                       AND ssa.flg_available = 'Y'
                                                       AND ssa.id_supply_area = 3
                         WHERE ssi.id_institution = i_prof.institution
                           AND ssi.id_software = i_prof.software
                           AND ssi.id_professional = i_prof.id
                           AND ssi.id_supply = i_id_supply
                        UNION ALL
                        SELECT 2 ra,
                               ssi.id_supply_soft_inst,
                               ssi.flg_cons_type,
                               ssi.flg_reusable,
                               ssi.flg_editable,
                               ssi.flg_preparing,
                               ssi.flg_countable
                          FROM alert.supply_soft_inst ssi
                         INNER JOIN supply s ON s.id_supply = ssi.id_supply
                         INNER JOIN supply_sup_area ssa ON ssa.id_supply_soft_inst = ssi.id_supply_soft_inst
                                                       AND ssa.flg_available = 'Y'
                                                       AND ssa.id_supply_area = 3
                         WHERE ssi.id_institution = i_prof.institution
                           AND ssi.id_software = i_prof.software
                           AND ssi.id_dept = i_id_dept
                           AND ssi.id_supply = i_id_supply
                        UNION ALL
                        SELECT 3 ra,
                               ssi.id_supply_soft_inst,
                               ssi.flg_cons_type,
                               ssi.flg_reusable,
                               ssi.flg_editable,
                               ssi.flg_preparing,
                               ssi.flg_countable
                          FROM supply_soft_inst ssi
                         INNER JOIN supply s ON s.id_supply = ssi.id_supply
                         INNER JOIN supply_sup_area ssa ON ssa.id_supply_soft_inst = ssi.id_supply_soft_inst
                                                       AND ssa.flg_available = 'Y'
                                                       AND ssa.id_supply_area = 3
                         WHERE ssi.id_institution IN (0, i_prof.institution)
                           AND ssi.id_software IN (0, i_prof.software)
                           AND ssi.id_supply = i_id_supply
                        ) sswi
                
                 ORDER BY sswi.ra) t
         WHERE rownum = 1;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            announce_error(g_mess);
            RETURN FALSE;
    END get_supply_soft_inst;

    FUNCTION get_id_dept(i_id_episode IN episode.id_episode%TYPE) RETURN episode.id_dept_requested%TYPE IS
        l_id_dept episode.id_dept_requested%TYPE;
    BEGIN
    
        SELECT e.id_dept_requested
          INTO l_id_dept
          FROM episode e
         WHERE e.id_episode = i_id_episode;
    
        RETURN l_id_dept;
    END get_id_dept;
		
   
BEGIN

    log_reg('Start migration from sr_reserv_req to supply_request and supply_workflow....');

    g_mess := 'Check if there is data to migrate';
    IF NOT check_data_to_migrate(g_data_to_migrate)
    THEN
        RAISE g_exception;
    END IF;

    IF g_data_to_migrate > 0
    THEN
        IF validate_content
        THEN
            g_process := TRUE;
        ELSE
            g_process := FALSE;
            g_mess    := 'Validate content: ' || g_mess;
            RAISE g_exception;
        END IF;
    
        IF g_process
        THEN

            FOR rec IN (SELECT *
                          FROM sr_reserv_req
                        
                         WHERE id_sr_equip IN (SELECT s.id_sr_equip
                                                 FROM sr_equip s
                                                WHERE s.flg_hemo_yn = 'N')
                         ORDER BY 1)
            LOOP
            
                log_reg('ID_SR_RESERV_REQ:' || rec.id_sr_reserv_req || ' ID_SR_EQUIP:' || rec.id_sr_equip);
            
                g_mess := 'get id_supply_request';
                SELECT seq_supply_request.nextval
                  INTO v_id_supply_request
                  FROM dual;
            
                g_mess := 'get professional:'||rec.id_prof_req || ' id_episode:'||rec.id_episode;
                v_prof := get_prof(rec.id_prof_req, rec.id_episode);
            
                g_mess := 'get language';
                v_lang := get_lang(v_prof);
            
                g_mess   := 'get period:'||rec.id_surg_period ||' lang:'|| v_lang;
                v_period := get_period(rec.id_surg_period, v_lang);
            
                g_mess    := 'get id_dept episode:' || rec.id_episode;
                v_id_dept := get_id_dept(rec.id_episode);
            
                g_mess := 'insert request';
                INSERT INTO supply_request
                    (id_supply_request,
                     id_professional,
                     id_episode,
                     id_room_req,
                     id_context,
                     flg_context,
                     dt_request,
                     flg_status,
                     flg_reason,
                     flg_prof_prep,
                     id_prof_cancel,
                     dt_cancel,
                     notes_cancel,
                     id_cancel_reason,
                     notes)
                VALUES
                    (v_id_supply_request,
                     rec.id_prof_req,
                     rec.id_episode_context,
                     NULL,
                     NULL,
                     NULL,
                     rec.dt_req_tstz,
                     'R',
                     'O',
                     NULL,
                     NULL,
                     NULL,
                     NULL,
                     NULL,
                     v_period);
            
                IF rec.flg_status = 'F' --finished
                THEN
                    IF rec.dt_exec_tstz > rec.dt_cancel_tstz
                       AND rec.id_prof_cancel IS NOT NULL
                    THEN
                        g_mess := '1st_cancel 2nd_execute';
                        IF NOT cancel_request(i_id_supply_request      => v_id_supply_request,
                                              i_id_prof_cancel         => rec.id_prof_cancel,
                                              i_dt_cancel              => rec.dt_cancel_tstz,
                                              i_notes_cancel           => rec.notes_cancel,
                                              i_id_supply_request_hist => v_id_supply_request_hist)
                        THEN
                            g_mess := 'cancel_request';
                            RAISE g_exception;
                        END IF;
                        IF NOT exec_request(i_id_supply_request      => v_id_supply_request,
                                            i_id_prof_exec           => rec.id_prof_exec,
                                            i_id_supply_request_hist => v_id_supply_request_hist)
                        THEN
                            g_mess := 'exec_request';
                            RAISE g_exception;
                        END IF;
                    
                    ELSE
                        g_mess := 'execute request';
                        IF NOT exec_request(i_id_supply_request      => v_id_supply_request,
                                            i_id_prof_exec           => rec.id_prof_exec,
                                            i_id_supply_request_hist => v_id_supply_request_hist)
                        THEN
                            g_mess := 'exec_request';
                            RAISE g_exception;
                        END IF;
                    END IF;
                END IF;
            
                IF rec.flg_status = 'C' --canceled
                THEN
                    IF rec.dt_cancel_tstz > rec.dt_exec_tstz
                       AND rec.id_prof_exec IS NOT NULL
                    THEN
                        g_mess := '1st_execute 2nd_cancel';
                    
                        IF NOT exec_request(i_id_supply_request      => v_id_supply_request,
                                            i_id_prof_exec           => rec.id_prof_exec,
                                            i_id_supply_request_hist => v_id_supply_request_hist)
                        THEN
                            g_mess := 'exec_request';
                            RAISE g_exception;
                        END IF;
                    
                        IF NOT cancel_request(i_id_supply_request      => v_id_supply_request,
                                              i_id_prof_cancel         => rec.id_prof_cancel,
                                              i_dt_cancel              => rec.dt_cancel_tstz,
                                              i_notes_cancel           => rec.notes_cancel,
                                              i_id_supply_request_hist => v_id_supply_request_hist)
                        THEN
                            g_mess := 'cancel_request';
                            RAISE g_exception;
                        END IF;
                    ELSE
                        g_mess := 'cancel request';
                        IF NOT cancel_request(i_id_supply_request      => v_id_supply_request,
                                              i_id_prof_cancel         => rec.id_prof_cancel,
                                              i_dt_cancel              => rec.dt_cancel_tstz,
                                              i_notes_cancel           => rec.notes_cancel,
                                              i_id_supply_request_hist => v_id_supply_request_hist)
                        THEN
                            g_mess := 'cancel_request';
                            RAISE g_exception;
                        END IF;
                    
                    END IF;
                
                END IF;
            
                g_mess := 'get id_supply';
                SELECT s.id_supply
                  INTO v_id_supply
                  FROM supply s
                 INNER JOIN sr_equip sre ON s.id_content = sre.id_content_new
                 WHERE sre.id_sr_equip = rec.id_sr_equip;
            
                g_mess := 'get supply soft inst info:' || v_id_supply || 'lang:' || v_lang || 'v_prof:' || v_prof.id || ',' ||
                          v_prof.institution || ',' || v_prof.software || 'i_dept' || v_id_dept;
                IF NOT get_supply_soft_inst(i_lang          => v_lang,
                                            i_prof          => v_prof,
                                            i_id_supply     => v_id_supply,
                                            i_id_dept       => v_id_dept,
                                            o_flg_cons_type => v_flg_cons_type,
                                            o_flg_reusable  => v_flg_reusable,
                                            o_flg_editable  => v_flg_editable,
                                            o_flg_preparing => v_flg_preparing,
                                            o_flg_countable => v_flg_countable)
                THEN
                    RAISE g_exception;
                END IF;
            
                FOR q IN 1 .. rec.qty_req
                LOOP
                
                    log_reg('QT: ' || q || ' of ' || rec.qty_req);
                
                    g_mess               := 'get default location:'||v_id_supply;
                    v_id_supply_location := get_default_location(v_prof, v_id_supply);
                
                    g_mess      := 'get status:'||v_id_supply_location;
                    v_wf_status := get_status(v_prof, v_id_supply_location);
                
                    g_mess := 'get id_supply_workflow';
                    SELECT seq_supply_workflow.nextval
                      INTO v_id_supply_workflow
                      FROM dual;
                
                    INSERT INTO supply_workflow
                        (id_supply_workflow,
                         id_professional,
                         id_episode,
                         id_supply_request,
                         id_supply,
                         id_supply_location,
                         barcode_req,
                         barcode_scanned,
                         quantity,
                         id_unit_measure,
                         id_context,
                         flg_context,
                         flg_status,
                         dt_request,
                         dt_returned,
                         notes,
                         id_prof_cancel,
                         dt_cancel,
                         notes_cancel,
                         id_cancel_reason,
                         notes_reject,
                         dt_reject,
                         id_prof_reject,
                         dt_supply_workflow,
                         id_req_reason,
                         id_del_reason,
                         id_supply_set,
                         id_sup_workflow_parent,
                         total_quantity,
                         asset_number,
                         flg_outdated,
                         total_avail_quantity,
                         cod_table,
                         flg_cons_type,
                         flg_reusable,
                         flg_editable,
                         flg_preparing,
                         flg_countable,
                         id_protocols,
                         id_supply_area)
                    VALUES
                        (v_id_supply_workflow,
                         rec.id_prof_req,
                         rec.id_episode_context,
                         v_id_supply_request,
                         v_id_supply,
                         v_id_supply_location,
                         NULL,
                         NULL,
                         1,
                         NULL,
                         NULL,
                         NULL,
                         v_wf_status,
                         rec.dt_req_tstz,
                         NULL,
                         v_period,
                         NULL,
                         NULL,
                         NULL,
                         NULL,
                         NULL,
                         NULL,
                         NULL,
                         rec.dt_req_tstz,
                         NULL,
                         NULL,
                         NULL,
                         NULL,
                         NULL,
                         NULL,
                         NULL,
                         NULL,
                         NULL,
                         v_flg_cons_type,
                         v_flg_reusable,
                         v_flg_editable,
                         v_flg_preparing,
                         v_flg_countable,
                         rec.id_protocols,
                         3);
                
                    IF rec.flg_status = 'F'
                    
                    THEN
                        IF rec.dt_exec_tstz > rec.dt_cancel_tstz
                           AND rec.id_prof_cancel IS NOT NULL
                        THEN
                            g_mess := '1st_cancel 2nd_execute';
                            IF NOT cancel_workflow(i_id_supply_workflow      => v_id_supply_workflow,
                                                   i_id_prof_cancel          => rec.id_prof_cancel,
                                                   i_dt_cancel               => rec.dt_cancel_tstz,
                                                   i_notes_cancel            => rec.notes_cancel,
                                                   i_id_supply_workflow_hist => v_id_supply_workflow_hist)
                            THEN
                                g_mess := 'cancel_workflow';
                                RAISE g_exception;
                            END IF;
                            IF NOT exec_workflow(i_id_supply_workflow      => v_id_supply_workflow,
                                                 i_id_prof_exec            => rec.id_prof_exec,
                                                 i_dt_exec                 => rec.dt_exec_tstz,
                                                 i_id_supply_workflow_hist => v_id_supply_workflow_hist)
                            THEN
                                g_mess := 'exec_workflow';
                                RAISE g_exception;
                            END IF;
                        
                        ELSE
                            g_mess := 'execute';
                            IF NOT exec_workflow(i_id_supply_workflow      => v_id_supply_workflow,
                                                 i_id_prof_exec            => rec.id_prof_exec,
                                                 i_dt_exec                 => rec.dt_exec_tstz,
                                                 i_id_supply_workflow_hist => v_id_supply_workflow_hist)
                            THEN
                                g_mess := 'exec_workflow';
                                RAISE g_exception;
                            END IF;
                        END IF;
                    END IF;
                
                    IF rec.flg_status = 'C'
                    THEN
                        IF rec.dt_cancel_tstz > rec.dt_exec_tstz
                           AND rec.id_prof_exec IS NOT NULL
                        THEN
                            g_mess := '1st_execute 2nd_cancel';
                            IF NOT exec_workflow(i_id_supply_workflow      => v_id_supply_workflow,
                                                 i_id_prof_exec            => rec.id_prof_exec,
                                                 i_dt_exec                 => rec.dt_exec_tstz,
                                                 i_id_supply_workflow_hist => v_id_supply_workflow_hist)
                            THEN
                                g_mess := 'exec_workflow';
                                RAISE g_exception;
                            END IF;
                            IF NOT cancel_workflow(i_id_supply_workflow      => v_id_supply_workflow,
                                                   i_id_prof_cancel          => rec.id_prof_cancel,
                                                   i_dt_cancel               => rec.dt_cancel_tstz,
                                                   i_notes_cancel            => rec.notes_cancel,
                                                   i_id_supply_workflow_hist => v_id_supply_workflow_hist)
                            THEN
                                g_mess := 'cancel_workflow';
                                RAISE g_exception;
                            END IF;
                        
                        ELSE
                            g_mess := 'cancel';
                            IF NOT cancel_workflow(i_id_supply_workflow      => v_id_supply_workflow,
                                                   i_id_prof_cancel          => rec.id_prof_cancel,
                                                   i_dt_cancel               => rec.dt_cancel_tstz,
                                                   i_notes_cancel            => rec.notes_cancel,
                                                   i_id_supply_workflow_hist => v_id_supply_workflow_hist)
                            THEN
                                g_mess := 'cancel_workflow';
                                RAISE g_exception;
                            END IF;
                        END IF;
                    END IF;
                
                    IF NOT ins_mapping_table(rec.id_sr_reserv_req, v_id_supply_workflow)
                    THEN
                        RAISE g_exception;
                    END IF;
                
                END LOOP;
            
            END LOOP;
        
            log_reg('START grid task update...');
            g_mess := 'UPDATE GRID TASK';
            FOR rec IN (SELECT *
                          FROM (SELECT srr.id_episode_context,
                                       srr.id_prof_req,
                                       rank() over(PARTITION BY srr.id_episode_context ORDER BY srr.dt_req_tstz DESC, srr.id_sr_equip) ranking
                                  FROM sr_reserv_req srr
                                 INNER JOIN sr_equip s ON srr.id_sr_equip = s.id_sr_equip
                                                      AND s.flg_hemo_yn = 'N') s
                         WHERE s.ranking = 1
                        
                         ORDER BY 1)
            LOOP
                log_reg('ID_EPISODE:' || rec.id_episode_context);
            
                g_mess := 'get professional';
                v_prof := get_prof(rec.id_prof_req, rec.id_episode_context);
            
                g_mess := 'get language';
                v_lang := get_lang(v_prof);
            
                g_mess := 'set supplies grid task';
                IF NOT pk_sr_supplies.set_supplies_grid_task(i_lang       => v_lang,
                                                             i_prof       => v_prof,
                                                             i_id_episode => rec.id_episode_context,
                                                             o_error      => g_error)
                
                THEN
                    announce_error(g_mess || ':' ||
                                   g_error.ora_sqlcode || ', ' || g_error.ora_sqlerrm || ', ' || g_error.err_desc || ', ' ||
                                   g_error.err_action || ', ' || g_error.log_id);
                    RAISE g_exception;
                END IF;
            END LOOP;
        
        ELSE
            announce_error(g_mess);
        END IF;
    
    ELSE
        log_reg('There is no data to migrate :)...');
    END IF;

    log_reg('...End migration from sr_reserv_req to supply_request and supply_workflow.');

    -- C O M M I T
    COMMIT;

EXCEPTION
    WHEN OTHERS THEN
        announce_error(g_mess);
        ROLLBACK;
END;
