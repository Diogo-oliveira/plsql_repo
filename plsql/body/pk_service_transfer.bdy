/*-- Last Change Revision: $Rev: 2027707 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:43:04 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_service_transfer AS

    -- ################################################################################
    /******************************************************************************
    NAME: GET_IN_DEPT_TRANSFER_LIST
    CREATION INFO: CARLOS FERREIRA 2007/01/31
    GOAL: RETURNS A LIST OF TRANSFERS FOR DESTINATION SERVICE
    NOTAS:
    
    PARAMETERS:
    -------------------------------------------------------------------------------
    | PARAMETER NAME   |   DATATYPE             | I/O |      DESCRIPTION          |
    -------------------------------------------------------------------------------
    -------------------------------------------------------------------------------
    *********************************************************************************/
    FUNCTION get_in_dept_transfer_list
    (
        i_lang  IN NUMBER,
        i_prof  IN profissional,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_func_name VARCHAR2(32) := 'GET_IN_DEPT_TRANSFER_LIST';
    
        l_id_epis_type  NUMBER;
        l_flg_request   VARCHAR2(0050);
        l_selected      VARCHAR2(0050);
        l_flg_accept    VARCHAR2(0050);
        l_mask_01       VARCHAR2(0050);
        l_flg_executed  VARCHAR2(0050);
        l_flg_transport VARCHAR2(0050);
    
        l_department_dest table_number;
    
    BEGIN
        g_error         := 'SABER QUAL O TIPO DE EPISODIOS QUEREMOS CONSULTAR';
        l_id_epis_type  := 5;
        l_selected      := 'S';
        l_flg_request   := 'R';
        l_flg_accept    := 'F';
        l_flg_executed  := 'X';
        l_flg_transport := 'T';
        l_mask_01       := 'YYYYMMDDHH24MISS';
    
        SELECT DISTINCT dpt.id_department
          BULK COLLECT
          INTO l_department_dest
          FROM prof_dep_clin_serv pdc1, dep_clin_serv dcs1, department dpt
         WHERE pdc1.flg_status = l_selected
           AND pdc1.id_dep_clin_serv = dcs1.id_dep_clin_serv
           AND dpt.id_department = dcs1.id_department
           AND pdc1.id_professional = i_prof.id
           AND dpt.id_institution = i_prof.institution
           AND instr(dpt.flg_type, 'I') > 0;
    
        g_error := 'BUILD CURSOR';
        OPEN o_list FOR
            WITH epr AS
             (SELECT *
                FROM epis_prof_resp
               WHERE flg_status IN (l_flg_request, l_flg_accept)
                 AND flg_transf_type = g_flg_transf_s
                 AND id_department_dest IN (SELECT column_value
                                              FROM TABLE(l_department_dest))
              UNION ALL
              SELECT *
                FROM epis_prof_resp
               WHERE flg_status = l_flg_executed
                 AND dt_end_transfer_tstz IS NULL
                 AND flg_transf_type = g_flg_transf_s
                 AND id_department_dest IN (SELECT column_value
                                              FROM TABLE(l_department_dest))),
            e AS
             (SELECT *
                FROM episode
               WHERE id_epis_type = l_id_epis_type
                 AND flg_ehr = g_flg_ehr_normal
                 AND flg_status != pk_alert_constant.g_epis_status_inactive
              UNION ALL
              SELECT *
                FROM episode
               WHERE id_epis_type = l_id_epis_type
                 AND flg_ehr = g_flg_ehr_schedule
                 AND flg_status != pk_alert_constant.g_epis_status_inactive)
            SELECT e.id_episode,
                   p.id_patient id_patient,
                   p.name name_pat,
                   p.gender gender,
                   pk_patient.get_pat_age(i_lang, p.id_patient, i_prof) pat_age,
                   decode(pk_patphoto.check_blob(p.id_patient), 'N', '', pk_patphoto.get_pat_foto(p.id_patient, i_prof)) photo,
                   pk_inp_grid.get_diagnosis_grid(i_lang, i_prof, e.id_episode) desc_diagnosis,
                   dpg.id_department id_service_orig,
                   pk_date_utils.date_char_hour_tsz(i_lang,
                                                    epr.dt_trf_accepted_tstz,
                                                    i_prof.institution,
                                                    i_prof.software) hour_trf_accepted,
                   pk_date_utils.dt_chr_tsz(i_lang, epr.dt_trf_accepted_tstz, i_prof) date_trf_accepted,
                   pk_date_utils.to_char_insttimezone(i_prof, epr.dt_trf_accepted_tstz, g_date_mask) true_dt_trf_accepted,
                   pk_translation.get_translation(i_lang, dpg.code_department) service_orig,
                   pk_translation.get_translation(i_lang, cso.code_clinical_service) clin_serv_orig,
                   
                   epr.id_prof_req id_prof_orig,
                   pk_date_utils.date_char_hour_tsz(i_lang,
                                                    epr.dt_trf_accepted_tstz,
                                                    i_prof.institution,
                                                    i_prof.software) hour_trf_accepted,
                   pk_date_utils.dt_chr_tsz(i_lang, epr.dt_trf_accepted_tstz, i_prof) date_trf_accepted,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, epr.id_prof_req) prof_orig,
                   dpt.id_department id_service_dest,
                   pk_translation.get_translation(i_lang, dpt.code_department) service_dest,
                   pk_translation.get_translation(i_lang, csd.code_clinical_service) clin_serv_dest,
                   nvl(epr.id_prof_comp, epr.id_prof_to) id_prof_dest,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, nvl(epr.id_prof_comp, epr.id_prof_to)) prof_dest,
                   pk_date_utils.to_char_insttimezone(i_prof, epr.dt_comp_tstz, g_date_mask) true_dt_executed,
                   pk_date_utils.date_char_hour_tsz(i_lang, epr.dt_comp_tstz, i_prof.institution, i_prof.software) hour_dt_executed,
                   pk_date_utils.dt_chr_tsz(i_lang, epr.dt_comp_tstz, i_prof) date_dt_executed,
                   epr.id_epis_prof_resp id_epis_prof_resp,
                   epr.trf_reason trf_reason,
                   epr.trf_answer trf_answer,
                   decode(epr.flg_status, l_flg_executed, l_flg_transport, epr.flg_status) flg_status,
                   pk_translation.get_translation(i_lang, 'ROOM.CODE_ROOM.' || epr.id_room) desc_room,
                   nvl(b.desc_bed, pk_translation.get_translation(i_lang, b.code_bed)) desc_bed,
                   pk_date_utils.to_char_insttimezone(i_prof, current_timestamp, l_mask_01) dt_server,
                   get_serv_transfer_icon_string(i_lang, i_prof, epr.id_epis_prof_resp) trf_status,
                   pk_date_utils.dt_year_day_hour_chr_short_tsz(i_lang,
                                                                epr.dt_trf_accepted_tstz,
                                                                i_prof.institution,
                                                                i_prof.software) date_hour_trf_accepted
              FROM epr,
                   e,
                   visit            v,
                   patient          p,
                   department       dpg, -- REQUESTING SERVICE
                   department       dpt, -- RECEIVING  SERVICE
                   clinical_service cso, -- REQUESTING CLINICAL SERVICE
                   clinical_service csd, -- RECEIVING CLINICAL SERVICE 
                   
                   bed b
             WHERE e.id_visit = v.id_visit
               AND v.id_patient = p.id_patient
               AND v.id_institution = i_prof.institution
               AND e.id_episode = epr.id_episode
               AND epr.id_bed = b.id_bed(+)
               AND epr.id_department_orig = dpg.id_department
               AND epr.id_department_dest = dpt.id_department
               AND epr.id_clinical_service_orig = cso.id_clinical_service
               AND epr.id_clinical_service_dest = csd.id_clinical_service(+)
            
             ORDER BY decode(epr.flg_status, l_flg_request, 0, l_flg_accept, 1), epr.dt_trf_requested_tstz;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            pk_types.open_my_cursor(o_list);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_in_dept_transfer_list;

    -- #################################################################################
    /******************************************************************************
    NAME: GET_IN_DEPT_TRANSFER_LIST
    CREATION INFO: CARLOS FERREIRA 2007/01/31
    GOAL: RETURNS A LIST OF TRANSFERS FOR DESTINATION SERVICE
    NOTAS:
    
    PARAMETERS:
    -------------------------------------------------------------------------------
    | PARAMETER NAME   |   DATATYPE             | I/O |      DESCRIPTION          |
    -------------------------------------------------------------------------------
    -------------------------------------------------------------------------------
    *********************************************************************************/
    FUNCTION get_out_dept_transfer_list
    (
        i_lang  IN NUMBER,
        i_prof  IN profissional,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_func_name VARCHAR2(32) := 'GET_OUT_DEPT_TRANSFER_LIST';
    
        l_id_epis_type  NUMBER;
        l_flg_request   VARCHAR2(0050);
        l_selected      VARCHAR2(0050);
        l_flg_accept    VARCHAR2(0050);
        l_flg_executed  VARCHAR2(0050);
        l_flg_transport VARCHAR2(0050);
        l_mask_01       VARCHAR2(0050);
    
        l_department_orig table_number;
    
    BEGIN
    
        g_error         := 'SABER QUAL O TIPO DE EPISODIOS QUEREMOS CONSULTAR';
        l_id_epis_type  := 5;
        l_selected      := 'S';
        l_flg_request   := 'R';
        l_flg_accept    := 'F';
        l_flg_executed  := 'X';
        l_flg_transport := 'T';
        l_mask_01       := 'YYYYMMDDHH24MISS';
    
        SELECT DISTINCT dpt.id_department
          BULK COLLECT
          INTO l_department_orig
          FROM prof_dep_clin_serv pdc1, dep_clin_serv dcs1, department dpt
         WHERE pdc1.flg_status = l_selected
           AND pdc1.id_dep_clin_serv = dcs1.id_dep_clin_serv
           AND dpt.id_department = dcs1.id_department
           AND pdc1.id_professional = i_prof.id
           AND dpt.id_institution = i_prof.institution
           AND instr(dpt.flg_type, 'I') > 0;
    
        g_error := 'BUILD CURSOR';
        OPEN o_list FOR
            WITH epr AS
             (SELECT *
                FROM epis_prof_resp
               WHERE flg_status IN (l_flg_request, l_flg_accept)
                 AND flg_transf_type = g_flg_transf_s
                 AND id_department_orig IN (SELECT column_value
                                              FROM TABLE(l_department_orig))
              UNION ALL
              SELECT *
                FROM epis_prof_resp
               WHERE flg_status = l_flg_executed
                 AND dt_end_transfer_tstz IS NULL
                 AND flg_transf_type = g_flg_transf_s
                 AND id_department_orig IN (SELECT column_value
                                              FROM TABLE(l_department_orig))),
            e AS
             (SELECT *
                FROM episode
               WHERE id_epis_type = l_id_epis_type
                 AND flg_ehr = g_flg_ehr_normal
                 AND flg_status != pk_alert_constant.g_epis_status_inactive
              UNION ALL
              SELECT *
                FROM episode
               WHERE id_epis_type = l_id_epis_type
                 AND flg_ehr = g_flg_ehr_schedule
                 AND flg_status != pk_alert_constant.g_epis_status_inactive)
            SELECT e.id_episode,
                   p.id_patient id_patient,
                   p.name name_pat,
                   p.gender gender,
                   pk_patient.get_pat_age(i_lang, p.id_patient, i_prof) pat_age,
                   decode(pk_patphoto.check_blob(p.id_patient), 'N', '', pk_patphoto.get_pat_foto(p.id_patient, i_prof)) photo,
                   pk_inp_grid.get_diagnosis_grid(i_lang, i_prof, e.id_episode) desc_diagnosis,
                   dpg.id_department id_service_orig,
                   pk_date_utils.date_char_hour_tsz(i_lang,
                                                    epr.dt_trf_accepted_tstz,
                                                    i_prof.institution,
                                                    i_prof.software) hour_trf_accepted,
                   pk_date_utils.dt_chr_tsz(i_lang, epr.dt_trf_accepted_tstz, i_prof) date_trf_accepted,
                   pk_date_utils.to_char_insttimezone(i_prof, epr.dt_trf_accepted_tstz, g_date_mask) true_dt_trf_accepted,
                   pk_translation.get_translation(i_lang, dpg.code_department) service_orig,
                                           pk_translation.get_translation(i_lang, cso.code_clinical_service) clin_serv_orig,
                   epr.id_prof_req id_prof_orig,
                   pk_date_utils.date_char_hour_tsz(i_lang,
                                                    epr.dt_trf_accepted_tstz,
                                                    i_prof.institution,
                                                    i_prof.software) hour_trf_accepted,
                   pk_date_utils.dt_chr_tsz(i_lang, epr.dt_trf_accepted_tstz, i_prof) date_trf_accepted,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, epr.id_prof_req) prof_orig,
                   dpt.id_department id_service_dest,
                   pk_translation.get_translation(i_lang, dpt.code_department) service_dest,
                                           pk_translation.get_translation(i_lang, csd.code_clinical_service) clin_serv_dest,
                   nvl(epr.id_prof_comp, epr.id_prof_to) id_prof_dest,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, nvl(epr.id_prof_comp, epr.id_prof_to)) prof_dest,
                   pk_date_utils.to_char_insttimezone(i_prof, epr.dt_comp_tstz, g_date_mask) true_dt_executed,
                   pk_date_utils.date_char_hour_tsz(i_lang, epr.dt_comp_tstz, i_prof.institution, i_prof.software) hour_dt_executed,
                   pk_date_utils.dt_chr_tsz(i_lang, epr.dt_comp_tstz, i_prof) date_dt_executed,
                   epr.id_epis_prof_resp id_epis_prof_resp,
                   epr.trf_reason trf_reason,
                   epr.trf_answer trf_answer,
                   decode(epr.flg_status, l_flg_executed, l_flg_transport, epr.flg_status) flg_status,
                   pk_translation.get_translation(i_lang, 'ROOM.CODE_ROOM.' || epr.id_room) desc_room,
                   nvl(b.desc_bed, pk_translation.get_translation(i_lang, b.code_bed)) desc_bed,
                   pk_date_utils.to_char_insttimezone(i_prof, current_timestamp, l_mask_01) dt_server,
                   --jsilva 28-03-2007 icone do estado da transferencia
                   get_serv_transfer_icon_string(i_lang, i_prof, epr.id_epis_prof_resp) trf_status,
                   pk_date_utils.dt_year_day_hour_chr_short_tsz(i_lang,
                                                                epr.dt_trf_accepted_tstz,
                                                                i_prof.institution,
                                                                i_prof.software) date_hour_trf_accepted
              FROM epr,
                   e,
                   visit      v,
                   patient    p,
                   department dpg, -- REQUESTING SERVICE
                   department dpt, -- RECEIVING  SERVICE
                   clinical_service cso, -- REQUESTING CLINICAL SERVICE
                   clinical_service csd, -- RECEIVING CLINICAL SERVICE                    
                   bed        b
             WHERE e.id_visit = v.id_visit
               AND v.id_patient = p.id_patient
               AND v.id_institution = i_prof.institution
               AND e.id_episode = epr.id_episode
               AND epr.id_bed = b.id_bed(+)
               AND epr.id_department_orig = dpg.id_department
               AND epr.id_department_dest = dpt.id_department
               AND epr.id_clinical_service_orig = cso.id_clinical_service
               AND epr.id_clinical_service_dest = csd.id_clinical_service(+)
               
             ORDER BY decode(epr.flg_status, l_flg_request, 0, l_flg_accept, 1), epr.dt_trf_requested_tstz;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            pk_types.open_my_cursor(o_list);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_out_dept_transfer_list;

    /********************************************************************************************
    * RETURNS A LIST OF TRANSFERS FOR the current DESTINATION SERVICE and
    * RETURNS A LIST OF TRANSFERS FOR other DESTINATION SERVICEs.
    *
    * @param   I_LANG       language associated to the professional executing the request
    * @param   I_PROF       professional, institution and software ids
    * @param   o_out_list   A LIST OF TRANSFERS FOR other DESTINATION SERVICE
    * @param   o_in_list    A LIST OF TRANSFERS FOR the current DESTINATION SERVICE
    * @param   o_error      Error message
    *
    * @return  true or false on success or error
    *
    * @author                         Sofia Mendes
    * @version                        2.6.0.4
    * @since                          21-Oct-2010
    **********************************************************************************************/
    FUNCTION get_dept_transfer_list
    (
        i_lang     IN NUMBER,
        i_prof     IN profissional,
        o_out_list OUT pk_types.cursor_type,
        o_in_list  OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL GET_OUT_DEPT_TRANSFER_LIST';
        IF NOT get_out_dept_transfer_list(i_lang => i_lang, i_prof => i_prof, o_list => o_out_list, o_error => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        g_error := 'CALL GET_OUT_DEPT_TRANSFER_LIST';
        IF NOT get_in_dept_transfer_list(i_lang => i_lang, i_prof => i_prof, o_list => o_in_list, o_error => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package_name,
                                              'GET_DEPT_TRANSFER_LIST',
                                              o_error);
            pk_types.open_my_cursor(o_out_list);
            pk_types.open_my_cursor(o_in_list);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_dept_transfer_list;

    /********************************************************************************************
    * CHECK_ACTIVE_TRANSFER            Check if there is any transfer active (service or inter-hospital transfer)
    *
    * @param i_lang                    language associated to the professional executing the request
    * @param i_prof                    professional, software and institution ids
    * @param i_flg_context             Flag that define what are we checking (Service Transfer 'S' or Inter-Hospital Transfer 'H')
    * @param i_id_episode              Episode ID to check transfers
    * @param o_flg_transfer            Flag that informs that there is any active service or inter-hospital transfer (Y/N)
    * @param o_msg_transfer            Message that informs that there is any active service or inter-hospital transfer
    * @param o_title_transfer          Title that informs that check if there is any active service or inter-hospital transfer
    * @param o_id_sys_shortcut         ID shortcut if there is any active service or inter-hospital transfer
    * @param o_flg_info_type           Flag that informs that there is any active service or inter-hospital transfer (I) Or there is more than one episode active in the same visit (E)
    *
    * @return                          true (sucess), false (error)
    *
    * @author                          António Neto
    * @version                         2.5.1.4
    * @since                           22-Mar-2011
    *
    **********************************************************************************************/
    FUNCTION check_active_transfer
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_flg_context     IN VARCHAR2 DEFAULT pk_service_transfer.g_transfer_flg_hospital_h,
        i_id_episode      IN episode.id_episode%TYPE,
        o_flg_transfer    OUT VARCHAR2,
        o_msg_transfer    OUT VARCHAR2,
        o_title_transfer  OUT VARCHAR2,
        o_id_sys_shortcut OUT sys_shortcut.id_sys_shortcut%TYPE,
        o_flg_info_type   OUT VARCHAR2,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_flg_context_error EXCEPTION;
    
        l_num PLS_INTEGER;
    
        CURSOR c_service_transfer IS
            SELECT 0
              FROM epis_prof_resp epr
             INNER JOIN episode epis
                ON epr.id_episode = epis.id_episode
             WHERE epr.flg_transf_type = pk_hand_off.g_flg_transf_s
               AND (epr.flg_status IN (pk_hand_off.g_hand_off_r, pk_hand_off.g_hand_off_f, pk_hand_off.g_hand_off_i))
               AND epis.id_episode = i_id_episode
               AND (epis.flg_ehr = pk_hand_off.g_flg_ehr_normal OR epis.flg_ehr = pk_hand_off.g_flg_ehr_schedule)
               AND epis.flg_status <> pk_transfer_institution.g_epis_cancel;
    
        CURSOR c_hospital_transfer IS
            SELECT 0
              FROM transfer_institution ti
             INNER JOIN episode epis
                ON ti.id_episode = epis.id_episode
             WHERE ti.flg_status IN
                   (pk_transfer_institution.g_transfer_inst_req, pk_transfer_institution.g_transfer_inst_transp)
               AND epis.id_episode = i_id_episode
               AND (epis.flg_ehr = pk_hand_off.g_flg_ehr_normal OR epis.flg_ehr = pk_hand_off.g_flg_ehr_schedule)
               AND epis.flg_status <> pk_transfer_institution.g_epis_cancel;
    
    BEGIN
        o_flg_transfer  := pk_alert_constant.g_no;
        o_flg_info_type := g_flg_info_type_tranfer_i;
    
        IF i_flg_context = g_transfer_flg_hospital_h
        THEN
            IF pk_transfer_institution.check_episodes_for_visit(i_id_episode => i_id_episode) = pk_alert_constant.g_no
            THEN
            
                --check for service transfer
                IF o_flg_transfer = pk_alert_constant.g_no
                THEN
                    OPEN c_service_transfer;
                    FETCH c_service_transfer
                        INTO l_num;
                
                    IF NOT c_service_transfer%NOTFOUND
                    THEN
                        o_flg_transfer := pk_alert_constant.g_yes;
                        o_msg_transfer := pk_message.get_message(i_lang      => i_lang,
                                                                 i_code_mess => g_message_hospital_transfer_m);
                    END IF;
                END IF;
            
                IF o_flg_transfer = pk_alert_constant.g_yes
                THEN
                    o_title_transfer  := pk_message.get_message(i_lang      => i_lang,
                                                                i_code_mess => g_message_hospital_transfer_t);
                    o_id_sys_shortcut := g_transfer_service_shortcut;
                END IF;
            ELSE
                o_flg_info_type  := g_flg_info_type_episodes_e;
                o_flg_transfer   := pk_alert_constant.g_yes;
                o_msg_transfer   := pk_message.get_message(i_lang => i_lang, i_code_mess => g_message_more_episodes_m);
                o_title_transfer := pk_message.get_message(i_lang => i_lang, i_code_mess => g_message_more_episodes_t);
            END IF;
        ELSIF i_flg_context = g_transfer_flg_service_s
        THEN
            --check for inter-hospital transfer
            IF o_flg_transfer = pk_alert_constant.g_no
            THEN
                OPEN c_hospital_transfer;
                FETCH c_hospital_transfer
                    INTO l_num;
            
                IF NOT c_hospital_transfer%NOTFOUND
                THEN
                    o_flg_transfer := pk_alert_constant.g_yes;
                    o_msg_transfer := pk_message.get_message(i_lang      => i_lang,
                                                             i_code_mess => g_message_service_transfer_m);
                END IF;
            END IF;
        
            IF o_flg_transfer = pk_alert_constant.g_yes
            THEN
                o_title_transfer  := pk_message.get_message(i_lang      => i_lang,
                                                            i_code_mess => g_message_service_transfer_t);
                o_id_sys_shortcut := g_transfer_hospital_shortcut;
            END IF;
        
        ELSE
            --If no valid contect specified throw an error        
            RAISE l_flg_context_error;
        
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package_name,
                                              'CHECK_ACTIVE_TRANSFER',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
        
            o_flg_transfer := NULL;
            o_msg_transfer := NULL;
        
            RETURN FALSE;
        
    END check_active_transfer;

    /******************************************************************************
    NAME: GET_TRANSFER_LIST
    CREATION INFO: CARLOS FERREIRA 2007/01/27
    GOAL: GET ALL TRANSFER FROM GIVEN INSTITUTION AND PATIENT.
    NOTAS:
    
    PARAMETERS:
    -------------------------------------------------------------------------------
    | PARAMETER NAME   |   DATATYPE             | I/O |      DESCRIPTION          |
    -------------------------------------------------------------------------------
    -------------------------------------------------------------------------------
    
    *********************************************************************************/
    --jsilva 28-03-2007 novo parametro de saida: o_flag_my_service
    FUNCTION get_pat_transfer_list
    (
        i_lang            IN NUMBER,
        i_id_episode      IN NUMBER,
        i_id_patient      IN NUMBER,
        i_prof            IN profissional,
        o_flag_my_service OUT NUMBER,
        o_list            OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(32) := 'GET_PAT_TRANSFER_LIST';
        --
        l_id_epis_type NUMBER;
        --
        l_mask_01       VARCHAR2(0050);
        l_trf_domain    VARCHAR2(0500);
        l_flg_request   VARCHAR2(0050);
        l_flg_accept    VARCHAR2(0050);
        l_flg_decline   VARCHAR2(0050);
        l_flg_cancel    VARCHAR2(0050);
        l_flg_transport VARCHAR2(0050);
        l_flg_executed  VARCHAR2(0050);
        CURSOR c_dpt IS
            SELECT dpt.id_department, dcs.id_dep_clin_serv
              FROM department dpt, dep_clin_serv dcs, prof_dep_clin_serv pdc
             WHERE pdc.flg_status = 'S'
               AND pdc.id_dep_clin_serv = dcs.id_dep_clin_serv
               AND dpt.id_department = dcs.id_department
               AND pdc.id_professional = i_prof.id
               AND dpt.id_institution = i_prof.institution
               AND instr(dpt.flg_type, 'I') > 0;
        l_pat_my_service NUMBER;
        l_dpt            department%ROWTYPE;
        epo              epis_info%ROWTYPE;
        l_cancel_message sys_message.desc_message%TYPE;
        l_dcs_mandatory  VARCHAR2(1 CHAR) := pk_sysconfig.get_config(i_code_cf => 'SERVICE_TRANSFER_ORIGIN_DCS_MANDATORY',
                                                                     i_prof    => i_prof);
        --
    BEGIN
        l_flg_decline    := 'D';
        l_flg_cancel     := 'C';
        l_flg_executed   := 'X';
        l_flg_request    := 'R';
        l_flg_accept     := 'F';
        l_flg_transport  := 'T';
        l_pat_my_service := 0;
        l_cancel_message := pk_message.get_message(i_lang => i_lang, i_code_mess => 'TRANSFER_M023');
        l_mask_01        := 'YYYYMMDDHH24MISS';
        g_error          := 'SABER QUAL O TYPE DE EPISODIOS QUEREMOS CONSULTAR';
    
        g_error := 'GET EPIS_TYPE';
        SELECT id_epis_type
          INTO l_id_epis_type
          FROM episode
         WHERE id_episode = i_id_episode;
    
        g_error := 'GET SERVICE FROM EPISODE PATIENT';
        SELECT dcs.id_dep_clin_serv, dpt.id_department, ei.flg_unknown
          INTO epo.id_dep_clin_serv, l_dpt.id_department, epo.flg_unknown
          FROM epis_info ei, dep_clin_serv dcs, department dpt
         WHERE id_episode = i_id_episode
           AND ei.id_dep_clin_serv = dcs.id_dep_clin_serv
           AND dcs.id_department = dpt.id_department;
    
        IF l_dcs_mandatory = pk_alert_constant.g_no
        THEN
            l_pat_my_service := 1;
        ELSE
            FOR dpt IN c_dpt
            LOOP
                --            IF epo.id_dep_clin_serv = dpt.id_dep_clin_serv
                IF l_dpt.id_department = dpt.id_department
                THEN
                    l_pat_my_service := 1;
                END IF;
            END LOOP;
        END IF;
        --jsilva 28-03-2007
        o_flag_my_service := l_pat_my_service;
        g_error           := 'BUILD CURSOR';
        OPEN o_list FOR
            SELECT dpg.id_department id_service_orig,
                   cso.id_clinical_service id_clin_serv_orig,
                   pk_date_utils.to_char_insttimezone(i_prof, epr.dt_request_tstz, g_date_mask) dt_request,
                   pk_date_utils.to_char_insttimezone(i_prof, epr.dt_end_transfer_tstz, g_date_mask) dt_end_transfer,
                   l_pat_my_service flag_my_service,
                   pk_date_utils.date_char_hour_tsz(i_lang,
                                                    epr.dt_trf_requested_tstz,
                                                    i_prof.institution,
                                                    i_prof.software) hour_trf_requested,
                   pk_date_utils.dt_chr_tsz(i_lang, epr.dt_trf_requested_tstz, i_prof) date_trf_requested,
                   pk_date_utils.to_char_insttimezone(i_prof, epr.dt_trf_requested_tstz, g_date_mask) true_dt_trf_requested,
                   pk_translation.get_translation(i_lang, dpg.code_department) service_orig,
                   pk_translation.get_translation(i_lang, cso.code_clinical_service) clin_serv_orig,
                   prg.id_professional id_prof_orig,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, prg.id_professional) prof_orig,
                   dpt.id_department id_service_dest,
                   pk_translation.get_translation(i_lang, dpt.code_department) service_dest,
                   csd.id_clinical_service id_clin_serv_dest,
                   pk_translation.get_translation(i_lang, csd.code_clinical_service) clin_serv_dest,
                   prt.id_professional id_prof_dest,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, prt.id_professional) prof_dest,
                   pk_date_utils.to_char_insttimezone(i_prof, epr.dt_trf_accepted_tstz, g_date_mask) true_dt_executed,
                   pk_date_utils.date_char_hour_tsz(i_lang,
                                                    epr.dt_trf_accepted_tstz,
                                                    i_prof.institution,
                                                    i_prof.software) hour_dt_executed,
                   pk_date_utils.dt_chr_tsz(i_lang, epr.dt_trf_accepted_tstz, i_prof) date_dt_executed,
                   epr.id_epis_prof_resp id_epis_prof_resp,
                   epr.trf_reason trf_reason,
                   epr.trf_answer trf_answer,
                   epr.flg_status,
                   epr.id_room id_room,
                   epr.id_bed id_bed,
                   pk_translation.get_translation(i_lang, code_room) desc_room,
                   nvl(bed.desc_bed, pk_translation.get_translation(i_lang, bed.code_bed)) desc_bed,
                   pk_date_utils.to_char_insttimezone(i_prof, current_timestamp, l_mask_01) dt_server,
                   get_serv_transfer_icon_string(i_lang, i_prof, epr.id_epis_prof_resp) trf_status,
                   REPLACE(REPLACE(l_cancel_message,
                                   '@1',
                                   pk_translation.get_translation(i_lang, dpg.code_department) || g_open_parenthesis ||
                                   pk_translation.get_translation(i_lang, cso.code_clinical_service) ||
                                   g_close_parenthesis),
                           '@2',
                           pk_translation.get_translation(i_lang, dpt.code_department) || g_open_parenthesis ||
                           pk_translation.get_translation(i_lang, csd.code_clinical_service) || g_close_parenthesis) transfer_desc
              FROM episode          epi,
                   epis_prof_resp   epr,
                   department       dpg, -- REQUESTING SERVICE
                   department       dpt, -- RECEIVING  SERVICE
                   clinical_service cso, -- REQUESTING CLINICAL SERVICE
                   clinical_service csd, -- RECEIVING CLINICAL SERVICE 
                   professional     prg, -- REQUESTING PROFESSIONAL
                   professional     prt, -- RECEIVING  PROFESSIONAL
                   room             roo,
                   bed
             WHERE epi.id_episode = i_id_episode
               AND epi.id_episode = epr.id_episode
               AND epi.id_epis_type = l_id_epis_type
                  --LMAIA 09-04-2009 Schedule episodes should have same permissions that normal episodes have
               AND (epi.flg_ehr = g_flg_ehr_normal OR epi.flg_ehr = g_flg_ehr_schedule)
                  -- Sílvia Freitas 27/05/2008 Filtrar os episódios para não trazer do tipo EHR 
                  --AND epi.flg_ehr = g_flg_ehr_normal
                  --END
               AND epr.id_room = roo.id_room(+)
               AND epr.id_bed = bed.id_bed(+)
               AND epr.id_department_orig = dpg.id_department
               AND epr.id_department_dest = dpt.id_department(+)
               AND epr.id_clinical_service_orig = cso.id_clinical_service
               AND epr.id_clinical_service_dest = csd.id_clinical_service(+)
               AND epr.id_prof_req = prg.id_professional
               AND nvl(epr.id_prof_comp, epr.id_prof_to) = prt.id_professional(+)
               AND epr.flg_transf_type = g_flg_transf_s
             ORDER BY dt_request DESC;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            pk_types.open_my_cursor(o_list);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_pat_transfer_list;

    /***************************************************************************
    * build string icon for service transfer state
    *                                                                         
    * @param i_lang                   Language ID                             
    * @param i_prof                   Profissional ID  
    * @param i_id_epis_prof_resp      Primary key of epis_prof_resp table                 
    *
    * @return string icon   
    *                                                                         
    * @author                         Filipe Silva                            
    * @version                        2.5.1                                  
    * @since                          2011/03/24                               
    **************************************************************************/

    FUNCTION get_serv_transfer_icon_string
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_epis_prof_resp IN epis_prof_resp.id_epis_prof_resp%TYPE
    ) RETURN VARCHAR2 IS
    
        l_trf_domain  VARCHAR2(40 CHAR) := 'EPIS_PROF_RESP.TRANSFER_STATUS';
        l_icon_string VARCHAR2(1000 CHAR);
        l_id_shortcut PLS_INTEGER := 623;
    
    BEGIN
    
        g_error := 'GET ICON STRING FOR ID_EPIS_PROF_RESP RECORD : ' || i_id_epis_prof_resp;
        pk_alertlog.log_debug(g_error);
        BEGIN
            SELECT pk_utils.get_status_string_immediate(i_lang,
                                                        i_prof,
                                                        st.display_type,
                                                        st.flg_state,
                                                        st.value_text,
                                                        st.value_date,
                                                        st.value_icon,
                                                        st.shortcut,
                                                        st.back_color,
                                                        st.icon_color,
                                                        st.message_style,
                                                        st.message_color,
                                                        st.flg_text_domain,
                                                        NULL,
                                                        st.dt_server)
              INTO l_icon_string
              FROM (SELECT CASE
                                WHEN epr.flg_status IN
                                     (pk_hand_off.g_hand_off_r, pk_hand_off.g_hand_off_f, pk_hand_off.g_hand_off_i) THEN
                                 pk_alert_constant.g_display_type_date_icon
                                ELSE
                                 pk_alert_constant.g_display_type_icon
                            END display_type,
                           epr.flg_status flg_state,
                           NULL value_text,
                           CASE
                                WHEN epr.flg_status = pk_hand_off.g_hand_off_r THEN
                                 to_char(epr.dt_trf_requested_tstz, pk_alert_constant.g_dt_yyyymmddhh24miss)
                                WHEN epr.flg_status = pk_hand_off.g_hand_off_f THEN
                                 to_char(epr.dt_trf_accepted_tstz, pk_alert_constant.g_dt_yyyymmddhh24miss)
                                WHEN epr.flg_status = pk_hand_off.g_hand_off_i THEN
                                 to_char(epr.dt_execute_tstz, pk_alert_constant.g_dt_yyyymmddhh24miss)
                                ELSE
                                 NULL
                            END value_date,
                           l_trf_domain value_icon,
                           l_id_shortcut shortcut,
                           NULL back_color,
                           CASE
                                WHEN epr.flg_status IN (pk_hand_off.g_hand_off_x, pk_hand_off.g_hand_off_d) THEN
                                 pk_alert_constant.g_color_icon_dark_grey
                                WHEN epr.flg_status IN
                                     (pk_hand_off.g_hand_off_r, pk_hand_off.g_hand_off_f, pk_hand_off.g_hand_off_i) THEN
                                 pk_alert_constant.g_color_icon_light_grey
                                WHEN epr.flg_status = pk_hand_off.g_hand_off_c THEN
                                 NULL
                            END icon_color,
                           NULL message_style,
                           NULL message_color,
                           NULL flg_text_domain,
                           current_timestamp dt_server
                      FROM epis_prof_resp epr
                     WHERE epr.id_epis_prof_resp = i_id_epis_prof_resp) st;
        EXCEPTION
            WHEN no_data_found THEN
                l_icon_string := NULL;
        END;
    
        RETURN l_icon_string;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.reset_error_state;
            RETURN NULL;
    END get_serv_transfer_icon_string;

    /********************************************************************************************
    * GET_TRANSFER_STATUS_ICON         Gets the transfer status string from an episode
    *
    * @param i_lang                    language associated to the professional executing the request
    * @param i_prof                    professional, software and institution ids
    * @param i_id_episode              Episode ID to check transfers
    * @param i_flg_context             Flag that define what are we checking (Service Transfer 'S' or Inter-Hospital Transfer 'H')
    * 
    * @return                          Transfer status string with icon
    *
    * @author                          António Neto
    * @version                         2.5.1.4
    * @since                           24-Mar-2011
    *
    **********************************************************************************************/
    FUNCTION get_transfer_status_icon
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_episode  IN episode.id_episode%TYPE,
        i_flg_context IN VARCHAR2
    ) RETURN VARCHAR2 IS
    
        l_transfer_active_st  PLS_INTEGER;
        l_transfer_active_iht PLS_INTEGER;
        l_flg_status_st       VARCHAR2(30 CHAR);
        l_flg_status_iht      VARCHAR2(30 CHAR);
        l_ret                 VARCHAR2(4000 CHAR) := NULL;
        l_error               t_error_out;
    
        l_transf_inst_grid_time PLS_INTEGER := to_number(pk_sysconfig.get_config(g_hours_limit_to_show, i_prof));
        l_id_transfer_st        PLS_INTEGER;
        l_id_transfer_iht       PLS_INTEGER;
        l_date_transfer_st      TIMESTAMP(6) WITH LOCAL TIME ZONE := current_timestamp;
        l_date_transfer_iht     TIMESTAMP(6) WITH LOCAL TIME ZONE := current_timestamp;
    
        CURSOR c_transfer IS
            SELECT st.transfer_active,
                   st.id_transfer,
                   st.date_transfer,
                   st.flg_status_transfer,
                   iht.transfer_active,
                   iht.id_transfer,
                   iht.date_transfer,
                   iht.flg_status_transfer
              FROM (SELECT *
                      FROM (
                            --Service Transfer
                            SELECT epr.id_epis_prof_resp id_transfer,
                                    /*epr.dt_request_tstz*/
                                    /*decode(epr.flg_status,
                                    pk_hand_off.g_hand_off_c,
                                    epr.dt_cancel_tstz,
                                    pk_hand_off.g_hand_off_d,
                                    epr.dt_decline_tstz,
                                    pk_hand_off.g_hand_off_x,
                                    epr.dt_execute_tstz,
                                    pk_hand_off.g_hand_off_r,
                                    epr.dt_request_tstz,
                                    pk_hand_off.g_hand_off_f,
                                    epr.dt_end_transfer_tstz,
                                    pk_hand_off.g_hand_off_t,
                                    epr.dt_end_transfer_tstz)*/
                                    epr.dt_request_tstz date_transfer,
                                    epr.flg_status flg_status_transfer,
                                    CASE
                                         WHEN epr.flg_status IN
                                              (pk_hand_off.g_hand_off_r, pk_hand_off.g_hand_off_f, pk_hand_off.g_hand_off_i) THEN
                                          1
                                         ELSE
                                          0
                                     END transfer_active,
                                    1 id_inner_join
                              FROM epis_prof_resp epr
                             INNER JOIN episode epis
                                ON epr.id_episode = epis.id_episode
                             WHERE (i_flg_context = g_transfer_flg_service_s OR i_flg_context IS NULL)
                               AND epr.id_episode = i_id_episode
                               AND (epis.flg_ehr = pk_hand_off.g_flg_ehr_normal OR
                                   epis.flg_ehr = pk_hand_off.g_flg_ehr_schedule)
                               AND (epr.flg_transf_type = pk_hand_off.g_flg_transf_s AND
                                   (epr.flg_status IN
                                   (pk_hand_off.g_hand_off_r, pk_hand_off.g_hand_off_f, pk_hand_off.g_hand_off_i) OR
                                   (epr.flg_status IN
                                   (pk_hand_off.g_hand_off_c, pk_hand_off.g_hand_off_d, pk_hand_off.g_hand_off_x) AND
                                   --For declined, canceled and executed status check the dates of each one must be less than the value in sys_config (in hours)
                                   pk_date_utils.add_to_ltstz(decode(epr.flg_status,
                                                                        pk_hand_off.g_hand_off_c,
                                                                        epr.dt_cancel_tstz,
                                                                        pk_hand_off.g_hand_off_d,
                                                                        epr.dt_decline_tstz,
                                                                        pk_hand_off.g_hand_off_x,
                                                                        epr.dt_execute_tstz),
                                                                 --
                                                                 l_transf_inst_grid_time,
                                                                 g_hour_format) > current_timestamp)))
                             ORDER BY transfer_active DESC, epr.dt_request_tstz DESC) st_inner
                     WHERE rownum = 1) st
              FULL OUTER JOIN (SELECT *
                                 FROM (
                                       --Inter-Hospital Transfer
                                       SELECT ti.id_episode id_transfer,
                                               /*decode(ti.flg_status,
                                               pk_transfer_institution.g_transfer_inst_cancel,
                                               ti.dt_cancel_tstz,
                                               pk_transfer_institution.g_transfer_inst_req,
                                               ti.dt_creation_tstz,
                                               pk_transfer_institution.g_transfer_inst_transp,
                                               ti.dt_begin_tstz,
                                               pk_transfer_institution.g_transfer_inst_fin,
                                               ti.dt_end_tstz)*/
                                               ti.dt_creation_tstz date_transfer,
                                               ti.flg_status flg_status_transfer,
                                               CASE
                                                    WHEN ti.flg_status IN
                                                         (pk_transfer_institution.g_transfer_inst_req,
                                                          pk_transfer_institution.g_transfer_inst_transp) THEN
                                                     1
                                                    ELSE
                                                     0
                                                END transfer_active,
                                               1 id_inner_join
                                         FROM transfer_institution ti
                                        INNER JOIN episode epis
                                           ON ti.id_episode = epis.id_episode
                                        WHERE (i_flg_context = g_transfer_flg_hospital_h OR i_flg_context IS NULL)
                                          AND epis.id_episode = i_id_episode
                                          AND (epis.flg_ehr = pk_hand_off.g_flg_ehr_normal OR
                                              epis.flg_ehr = pk_hand_off.g_flg_ehr_schedule)
                                          AND (ti.flg_status IN
                                              (pk_transfer_institution.g_transfer_inst_req,
                                                pk_transfer_institution.g_transfer_inst_transp)
                                              --
                                              OR (ti.flg_status IN
                                              (pk_transfer_institution.g_transfer_inst_cancel,
                                                    pk_transfer_institution.g_transfer_inst_fin) AND
                                              --For declined, canceled and executed status check the dates of each one must be less than the value in sys_config (in hours)
                                              pk_date_utils.add_to_ltstz(decode(ti.flg_status,
                                                                                     pk_transfer_institution.g_transfer_inst_cancel,
                                                                                     ti.dt_cancel_tstz,
                                                                                     pk_transfer_institution.g_transfer_inst_fin,
                                                                                     ti.dt_end_tstz),
                                                                              --
                                                                              l_transf_inst_grid_time,
                                                                              g_hour_format) > current_timestamp))
                                       --
                                        ORDER BY transfer_active DESC, ti.dt_creation_tstz DESC) iht_inner
                                WHERE rownum = 1) iht
                ON st.id_inner_join = iht.id_inner_join
            
            ;
    
    BEGIN
        OPEN c_transfer;
        FETCH c_transfer
            INTO l_transfer_active_st,
                 l_id_transfer_st,
                 l_date_transfer_st,
                 l_flg_status_st,
                 l_transfer_active_iht,
                 l_id_transfer_iht,
                 l_date_transfer_iht,
                 l_flg_status_iht;
    
        IF c_transfer%FOUND
        THEN
            IF (nvl(l_transfer_active_st, 0) = 1 AND nvl(l_transfer_active_iht, 0) = 1)
               OR (nvl(l_transfer_active_st, 0) = 0 AND nvl(l_transfer_active_iht, 0) = 0)
            THEN
                IF l_date_transfer_st > l_date_transfer_iht
                   OR (l_date_transfer_st IS NOT NULL AND l_date_transfer_iht IS NULL)
                THEN
                    l_ret := get_serv_transfer_icon_string(i_lang              => i_lang,
                                                           i_prof              => i_prof,
                                                           i_id_epis_prof_resp => l_id_transfer_st);
                ELSE
                    l_ret := pk_transfer_institution.get_inst_transfer_icon_string(i_lang             => i_lang,
                                                                                   i_prof             => i_prof,
                                                                                   i_id_episode       => i_id_episode,
                                                                                   i_dt_creation_tstz => l_date_transfer_iht);
                END IF;
            ELSIF l_transfer_active_st = 1
            THEN
                l_ret := get_serv_transfer_icon_string(i_lang              => i_lang,
                                                       i_prof              => i_prof,
                                                       i_id_epis_prof_resp => l_id_transfer_st);
            ELSIF l_transfer_active_iht = 1
            THEN
                l_ret := pk_transfer_institution.get_inst_transfer_icon_string(i_lang             => i_lang,
                                                                               i_prof             => i_prof,
                                                                               i_id_episode       => i_id_episode,
                                                                               i_dt_creation_tstz => l_date_transfer_iht);
            END IF;
        END IF;
    
        RETURN l_ret;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package_name,
                                              'GET_TRANSFER_STATUS_ICON',
                                              l_error);
            pk_alert_exceptions.reset_error_state;
        
            RETURN NULL;
        
    END get_transfer_status_icon;

    /********************************************************************************************
    * GET_TRANSFER_SHORTCUT            Gets the transfer status string from an episode
    *
    * @param i_lang                    language associated to the professional executing the request
    * @param i_prof                    professional, software and institution ids
    * @param i_flg_context             Flag that define what are we checking (Service Transfer 'S' or Inter-Hospital Transfer 'H')
    * 
    * @return                          Transfer status string with icon
    *
    * @author                          Sofia Mendes
    * @version                         2.5.1.4
    * @since                           24-Mar-2011
    *
    **********************************************************************************************/
    FUNCTION get_transfer_shortcut
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_flg_context IN VARCHAR2
    ) RETURN sys_shortcut.id_sys_shortcut%TYPE IS
        l_shortcut    sys_shortcut.id_sys_shortcut%TYPE;
        l_intern_name sys_shortcut.intern_name%TYPE;
        l_intern_exception EXCEPTION;
        l_error t_error_out;
    BEGIN
        IF (i_flg_context = g_transfer_flg_service_s)
        THEN
            l_intern_name := 'TRANSFER_STATUS';
        ELSE
            l_intern_name := 'TRANSFER_INSTITUTION';
        END IF;
    
        g_error := 'CALL pk_access.get_id_shortcut. i_intern_name: ' || l_intern_name;
        pk_alertlog.log_debug(g_error);
        IF NOT pk_access.get_id_shortcut(i_lang        => i_lang,
                                         i_prof        => i_prof,
                                         i_intern_name => l_intern_name,
                                         o_id_shortcut => l_shortcut,
                                         o_error       => l_error)
        THEN
            RAISE l_intern_exception;
        END IF;
    
        RETURN l_shortcut;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package_name,
                                              'GET_TRANSFER_SHORTCUT',
                                              l_error);
            RETURN NULL;
        
    END get_transfer_shortcut;

    ------------------------------------DETAIL AND HISTORY FUNCTIONS
    /********************************************************************************************
    * get_department_desc            Gets the department description.
    *
    * @param i_lang                    language associated to the professional executing the request
    * @param i_prof                    professional, software and institution ids
    * @param i_id_department           Department ID
    * 
    * @return                          descriptive
    *
    * @author                          Sofia Mendes
    * @version                         2.5.1.4
    * @since                           28-Mar-2011
    *
    **********************************************************************************************/
    FUNCTION get_department_desc
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_department IN department.id_department%TYPE
    ) RETURN pk_translation.t_desc_translation IS
        l_department_desc pk_translation.t_desc_translation;
        l_error           t_error_out;
    BEGIN
        g_error := 'GET department desc. i_id_department: ' || i_id_department;
        pk_alertlog.log_debug(g_error);
        SELECT pk_translation.get_translation(i_lang, d.code_department)
          INTO l_department_desc
          FROM department d
         WHERE d.id_department = i_id_department;
    
        RETURN l_department_desc;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package_name,
                                              'GET_DEPARTMENT_DESC',
                                              l_error);
            RETURN NULL;
    END get_department_desc;

    /********************************************************************************************
    * get_specialty_desc               Gets the clinical service description.
    *
    * @param i_lang                    language associated to the professional executing the request
    * @param i_prof                    professional, software and institution ids
    * @param i_id_clinical_service     Clinical service ID
    * 
    * @return                          descriptive
    *
    * @author                          Sofia Mendes
    * @version                         2.5.1.4
    * @since                           28-Mar-2011
    *
    **********************************************************************************************/
    FUNCTION get_specialty_desc
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_clinical_service IN department.id_department%TYPE
    ) RETURN pk_translation.t_desc_translation IS
        l_specialty_desc pk_translation.t_desc_translation;
        l_error          t_error_out;
    BEGIN
        g_error := 'GET specialty desc. i_id_clinical_service: ' || i_id_clinical_service;
        pk_alertlog.log_debug(g_error);
        SELECT pk_translation.get_translation(i_lang, cs.code_clinical_service)
          INTO l_specialty_desc
          FROM clinical_service cs
         WHERE cs.id_clinical_service = i_id_clinical_service;
    
        RETURN l_specialty_desc;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package_name,
                                              'GET_SPECIALTY_DESC',
                                              l_error);
            RETURN NULL;
    END get_specialty_desc;

    /********************************************************************************************
    * get_room_desc                    Gets the room description.
    *
    * @param i_lang                    language associated to the professional executing the request
    * @param i_prof                    professional, software and institution ids
    * @param i_id_room                 Room ID
    * 
    * @return                          descriptive
    *
    * @author                          Sofia Mendes
    * @version                         2.5.1.4
    * @since                           28-Mar-2011
    *
    **********************************************************************************************/
    FUNCTION get_room_desc
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_id_room IN room.id_room%TYPE
    ) RETURN pk_translation.t_desc_translation IS
        l_room_desc pk_translation.t_desc_translation;
        l_error     t_error_out;
    BEGIN
        g_error := 'GET room desc. i_id_room: ' || i_id_room;
        pk_alertlog.log_debug(g_error);
        SELECT pk_translation.get_translation(i_lang, r.code_room)
          INTO l_room_desc
          FROM room r
         WHERE r.id_room = i_id_room;
    
        RETURN l_room_desc;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package_name,
                                              'GET_ROOM_DESC',
                                              l_error);
            RETURN NULL;
    END get_room_desc;

    /********************************************************************************************
    * get_necessity_desc               Gets the necessity description.
    *
    * @param i_lang                    language associated to the professional executing the request
    * @param i_prof                    professional, software and institution ids
    * @param i_id_movement             Transport ID
    * 
    * @return                          descriptive
    *
    * @author                          Sofia Mendes
    * @version                         2.5.1.4
    * @since                           28-Mar-2011
    *
    **********************************************************************************************/
    FUNCTION get_necessity_desc
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_movement IN movement.id_movement%TYPE
    ) RETURN pk_translation.t_desc_translation IS
        l_nec_desc pk_translation.t_desc_translation;
        l_error    t_error_out;
    BEGIN
        g_error := 'GET room desc. i_id_movement: ' || i_id_movement;
        pk_alertlog.log_debug(g_error);
        SELECT pk_translation.get_translation(i_lang, n.code_necessity)
          INTO l_nec_desc
          FROM movement m
          JOIN necessity n
            ON m.id_necessity = n.id_necessity
         WHERE m.id_movement = i_id_movement;
    
        RETURN l_nec_desc;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package_name,
                                              'GET_NECESSITY_DESC',
                                              l_error);
            RETURN NULL;
    END get_necessity_desc;

    /**
    * Get detail/history signature line
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)
    * @param   i_id_episode                Episode id
    * @param   i_date                      Date of the insertion/last change
    * @param   i_id_prof_last_change       Professional id that performed the insertion/ last change
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  Sofia Mendes
    * @version v2.5.1.4
    * @since   29-Mar-2011
    */
    FUNCTION get_signature
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_episode          IN episode.id_episode%TYPE,
        i_date                IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_id_prof_last_change IN professional.id_professional%TYPE
    ) RETURN VARCHAR2 IS
        l_desc_signature sys_message.desc_message%TYPE;
        l_spec           VARCHAR2(200 CHAR);
    BEGIN
        l_desc_signature := pk_message.get_message(i_lang, i_prof, 'COMMON_M107');
    
        g_error := 'CALL pk_prof_utils.get_spec_signature. i_id_prof_last_change: ' || i_id_prof_last_change ||
                   '; i_date: ' || CAST(i_date AS VARCHAR2) || '; i_id_episode: ' || i_id_episode;
        pk_alertlog.log_debug(g_error);
        l_spec := pk_prof_utils.get_spec_signature(i_lang    => i_lang,
                                                   i_prof    => i_prof,
                                                   i_prof_id => i_id_prof_last_change,
                                                   i_dt_reg  => i_date,
                                                   i_episode => i_id_episode);
    
        g_error := 'GET SIGNATURE';
        pk_alertlog.log_debug(g_error);
        RETURN l_desc_signature || ' ' || pk_date_utils.date_char_tsz(i_lang,
                                                                      i_date,
                                                                      i_prof.institution,
                                                                      i_prof.software) || '; ' --
        || pk_prof_utils.get_name_signature(i_lang => i_lang, i_prof => i_prof, i_prof_id => i_id_prof_last_change) || --
        CASE WHEN l_spec IS NOT NULL THEN ' (' || l_spec || ')' END;
    
    END get_signature;

    /********************************************************************************************
    * Get the service transfer finalization date and professional.
    *
    * @param   I_LANG                      language associated to the professional executing the request
    * @param   i_prof                      professional
    * @param   i_actual_row                Service tranfer data
    * @param   o_prof_finalize             Professional that finalized the service tranfer(performed the 
    *                                      transport or executed the service transfer without transport)    
    * @param   o_dt_finalize               Finalization date    
    * @param   o_error                     Error message
    *                        
    * @return  true or false on success or error
    * 
    * @author                         Sofia Mendes
    * @version                        2.6.0.4
    * @since                          28-Mar-2011
    **********************************************************************************************/
    FUNCTION get_finalize_dt_prof
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_actual_row    IN epis_prof_resp%ROWTYPE,
        o_prof_finalize OUT epis_prof_resp.id_prof_execute%TYPE,
        o_dt_finalize   OUT epis_prof_resp.dt_execute_tstz%TYPE,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        --service transfer with trasport
        IF (i_actual_row.id_movement IS NOT NULL)
        THEN
            g_error := 'GET ID_PROF. i_id_movement: ' || i_actual_row.id_movement;
            pk_alertlog.log_debug(g_error);
            BEGIN
                SELECT m.id_prof_receive
                  INTO o_prof_finalize
                  FROM movement m
                 WHERE m.id_movement = i_actual_row.id_movement;
            EXCEPTION
                WHEN OTHERS THEN
                    o_prof_finalize := NULL;
            END;
        
            o_dt_finalize := i_actual_row.dt_end_transfer_tstz;
        ELSE
            o_prof_finalize := i_actual_row.id_prof_execute;
            o_dt_finalize   := i_actual_row.dt_execute_tstz;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_FINALIZE_DT_PROF',
                                              o_error    => o_error);
            RETURN FALSE;
    END get_finalize_dt_prof;

    /********************************************************************************************
    * Get the the fields data to the detail and history related with the finalization step(conclusion
    * of the transport or execution os the service transfer without transport).
    * To be used on detail and history
    *
    * @param   I_LANG                      language associated to the professional executing the request
    * @param   i_prof                      professional
    * @param   i_actual_row                Service tranfer data
    * @param   i_labels_codes              Sys_message codes of the labels to be used in the finalized status related fields                                                   
    * @param   i_content_type              Detail/History formatting type
    * @param   io_labels                   List of labels
    * @param   io_values                   List of values
    * @param   io_types                    List of formatting types
    * @param   o_prof_finalize             Professional that finalized the service tranfer(performed the 
    *                                      transport or executed the service transfer without transport)    
    * @param   o_dt_finalize               Finalization date
    * @param   o_error                     Error message
    *                        
    * @return  true or false on success or error
    * 
    * @author                         Sofia Mendes
    * @version                        2.6.0.4
    * @since                          28-Mar-2011
    **********************************************************************************************/
    FUNCTION get_finalize_fields
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_actual_row    IN epis_prof_resp%ROWTYPE,
        i_labels_codes  IN table_varchar,
        i_content_type  IN VARCHAR2,
        io_labels       IN OUT NOCOPY table_varchar,
        io_values       IN OUT NOCOPY table_varchar,
        io_types        IN OUT NOCOPY table_varchar,
        o_prof_finalize OUT epis_prof_resp.id_prof_execute%TYPE,
        o_dt_finalize   OUT epis_prof_resp.dt_execute_tstz%TYPE,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'CALL get_finalize_dt_prof';
        pk_alertlog.log_debug(g_error);
        IF NOT get_finalize_dt_prof(i_lang          => i_lang,
                                    i_prof          => i_prof,
                                    i_actual_row    => i_actual_row,
                                    o_prof_finalize => o_prof_finalize,
                                    o_dt_finalize   => o_dt_finalize,
                                    o_error         => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        --execution professional
        pk_inp_detail.add_3_values(io_table_1 => io_labels,
                                   i_value_1  => pk_message.get_message(i_lang, i_labels_codes(1)),
                                   io_table_2 => io_values,
                                   i_value_2  => pk_prof_utils.get_name_signature(i_lang, i_prof, o_prof_finalize),
                                   io_table_3 => io_types,
                                   i_value_3  => i_content_type);
    
        --execution date
        pk_inp_detail.add_3_values(io_table_1 => io_labels,
                                   i_value_1  => pk_message.get_message(i_lang, i_labels_codes(2)),
                                   io_table_2 => io_values,
                                   i_value_2  => pk_date_utils.date_char_tsz(i_lang,
                                                                             o_dt_finalize,
                                                                             i_prof.institution,
                                                                             i_prof.software),
                                   io_table_3 => io_types,
                                   i_value_3  => i_content_type);
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_FINALIZE_FIELDS',
                                              o_error    => o_error);
            RETURN FALSE;
    END get_finalize_fields;

    /********************************************************************************************
    * Get the the fields data to the detail and history related with the request step.
    * To be used on detail and history
    *
    * @param   I_LANG                      language associated to the professional executing the request
    * @param   i_prof                      professional
    * @param   i_actual_row                Service tranfer data
    * @param   i_flg_screen                D-detail; H-History                                                   
    * @param   io_labels                   List of labels
    * @param   io_values                   List of values
    * @param   io_types                    List of formatting types
    * @param   o_error                     Error message
    *                        
    * @return  true or false on success or error
    * 
    * @author                         Sofia Mendes
    * @version                        2.6.0.4
    * @since                          28-Mar-2011
    **********************************************************************************************/
    FUNCTION get_request_fields
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_actual_row  IN epis_prof_resp%ROWTYPE,
        i_flg_screen  IN VARCHAR2,
        io_tbl_labels IN OUT NOCOPY table_varchar,
        io_tbl_values IN OUT NOCOPY table_varchar,
        io_tbl_types  IN OUT NOCOPY table_varchar,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_desc_service_origin   sys_message.desc_message%TYPE;
        l_desc_service_destiny  sys_message.desc_message%TYPE;
        l_desc_spec_origin      sys_message.desc_message%TYPE;
        l_desc_reason           sys_message.desc_message%TYPE;
        l_desc_req_prof         sys_message.desc_message%TYPE;
        l_desc_spec_destiny     sys_message.desc_message%TYPE;
        l_desc_patiente_consent sys_message.desc_message%TYPE;
        l_desc_date_req         sys_message.desc_message%TYPE;
        l_status                epis_prof_resp.flg_status%TYPE;
    BEGIN
        IF (i_flg_screen = g_history_h)
        THEN
            l_status := pk_hand_off.g_hand_off_r;
        ELSE
            l_status := i_actual_row.flg_status;
        END IF;
    
        --request labels
        l_desc_service_origin   := pk_message.get_message(i_lang, 'TRANSFER_T017');
        l_desc_service_destiny  := pk_message.get_message(i_lang, 'TRANSFER_T018');
        l_desc_spec_origin      := pk_message.get_message(i_lang, 'TRANSFER_T047');
        l_desc_spec_destiny     := pk_message.get_message(i_lang, 'TRANSFER_T048');
        l_desc_reason           := pk_message.get_message(i_lang, 'TRANSFER_T019');
        l_desc_req_prof         := pk_message.get_message(i_lang, 'TRANSFER_T021');
        l_desc_date_req         := pk_message.get_message(i_lang, 'TRANSFER_T022');
        l_desc_patiente_consent := pk_message.get_message(i_lang, 'TRANSFER_T067');
    
        --title
        pk_inp_detail.add_3_values(io_table_1 => io_tbl_labels,
                                   i_value_1  => pk_sysdomain.get_domain(i_code_dom => g_sd_transfer_status_det_desc,
                                                                         i_val      => l_status,
                                                                         i_lang     => i_lang),
                                   io_table_2 => io_tbl_values,
                                   i_value_2  => NULL,
                                   io_table_3 => io_tbl_types,
                                   i_value_3  => g_title_t);
    
        --profissional que requisitou
        pk_inp_detail.add_3_values(io_table_1 => io_tbl_labels,
                                   i_value_1  => l_desc_req_prof,
                                   io_table_2 => io_tbl_values,
                                   i_value_2  => pk_prof_utils.get_name_signature(i_lang,
                                                                                  i_prof,
                                                                                  i_actual_row.id_prof_req),
                                   io_table_3 => io_tbl_types,
                                   i_value_3  => g_content_c);
    
        --data de requisição
        pk_inp_detail.add_3_values(io_table_1 => io_tbl_labels,
                                   i_value_1  => l_desc_date_req,
                                   io_table_2 => io_tbl_values,
                                   i_value_2  => pk_date_utils.date_char_tsz(i_lang,
                                                                             i_actual_row.dt_request_tstz,
                                                                             i_prof.institution,
                                                                             i_prof.software),
                                   io_table_3 => io_tbl_types,
                                   i_value_3  => g_content_c);
    
        --origin service
        pk_inp_detail.add_3_values(io_table_1 => io_tbl_labels,
                                   i_value_1  => l_desc_service_origin,
                                   io_table_2 => io_tbl_values,
                                   i_value_2  => get_department_desc(i_lang          => i_lang,
                                                                     i_prof          => i_prof,
                                                                     i_id_department => i_actual_row.id_department_orig),
                                   io_table_3 => io_tbl_types,
                                   i_value_3  => g_content_c);
    
        --destiny service
        pk_inp_detail.add_3_values(io_table_1 => io_tbl_labels,
                                   i_value_1  => l_desc_service_destiny,
                                   io_table_2 => io_tbl_values,
                                   i_value_2  => get_department_desc(i_lang          => i_lang,
                                                                     i_prof          => i_prof,
                                                                     i_id_department => i_actual_row.id_department_dest),
                                   io_table_3 => io_tbl_types,
                                   i_value_3  => g_content_c);
    
        --origin specialty
        pk_inp_detail.add_3_values(io_table_1 => io_tbl_labels,
                                   i_value_1  => l_desc_spec_origin,
                                   io_table_2 => io_tbl_values,
                                   i_value_2  => get_specialty_desc(i_lang                => i_lang,
                                                                    i_prof                => i_prof,
                                                                    i_id_clinical_service => i_actual_row.id_clinical_service_orig),
                                   io_table_3 => io_tbl_types,
                                   i_value_3  => g_content_c);
    
        --destiny specialty
        pk_inp_detail.add_3_values(io_table_1 => io_tbl_labels,
                                   i_value_1  => l_desc_spec_destiny,
                                   io_table_2 => io_tbl_values,
                                   i_value_2  => get_specialty_desc(i_lang                => i_lang,
                                                                    i_prof                => i_prof,
                                                                    i_id_clinical_service => i_actual_row.id_clinical_service_dest),
                                   io_table_3 => io_tbl_types,
                                   i_value_3  => g_content_c);
    
        --reason 
        pk_inp_detail.add_3_values(io_table_1 => io_tbl_labels,
                                   i_value_1  => l_desc_reason,
                                   io_table_2 => io_tbl_values,
                                   i_value_2  => i_actual_row.trf_reason,
                                   io_table_3 => io_tbl_types,
                                   i_value_3  => g_content_c);
    
        --patient consent
        IF i_actual_row.flg_patient_consent IS NOT NULL
        THEN
            pk_inp_detail.add_3_values(io_table_1 => io_tbl_labels,
                                       i_value_1  => l_desc_patiente_consent || ' ' ||
                                                     get_specialty_desc(i_lang                => i_lang,
                                                                        i_prof                => i_prof,
                                                                        i_id_clinical_service => i_actual_row.id_clinical_service_dest) || '?',
                                       io_table_2 => io_tbl_values,
                                       i_value_2  => pk_sysdomain.get_domain(i_code_dom => g_sd_patient_consent,
                                                                             i_val      => i_actual_row.flg_patient_consent,
                                                                             i_lang     => i_lang),
                                       io_table_3 => io_tbl_types,
                                       i_value_3  => g_content_c);
        END IF;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package_name,
                                              'GET_REQUEST_FIELDS',
                                              o_error);
            RETURN NULL;
    END get_request_fields;

    /********************************************************************************************
    * Get the the fields data to the detail and history related with the accept step.
    * To be used on detail and history
    *
    * @param   I_LANG                      language associated to the professional executing the request
    * @param   i_prof                      professional
    * @param   i_actual_row                Service tranfer data
    * @param   i_flg_screen                D-detail; H-History  
    * @param   i_labels_codes              Sys_message codes of the labels to be used in the finalized status related fields
    * @param   i_content_type              Detail/History formatting type                                               
    * @param   io_labels                   List of labels
    * @param   io_values                   List of values
    * @param   io_types                    List of formatting types
    * @param   o_error                     Error message
    *                        
    * @return  true or false on success or error
    * 
    * @author                         Sofia Mendes
    * @version                        2.6.0.4
    * @since                          28-Mar-2011
    **********************************************************************************************/
    FUNCTION get_accepted_fields
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_flg_screen   IN VARCHAR2,
        i_actual_row   IN epis_prof_resp%ROWTYPE,
        i_label_codes  IN table_varchar,
        i_content_type IN VARCHAR2,
        io_tbl_labels  IN OUT NOCOPY table_varchar,
        io_tbl_values  IN OUT NOCOPY table_varchar,
        io_tbl_types   IN OUT NOCOPY table_varchar,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        IF (i_flg_screen = g_detail_d)
        THEN
            IF (i_actual_row.id_prof_comp IS NOT NULL)
            THEN
                --deferring prof 
                pk_inp_detail.add_3_values(io_table_1 => io_tbl_labels,
                                           i_value_1  => pk_message.get_message(i_lang, i_label_codes(1)),
                                           io_table_2 => io_tbl_values,
                                           i_value_2  => pk_prof_utils.get_name_signature(i_lang,
                                                                                          i_prof,
                                                                                          i_actual_row.id_prof_comp),
                                           io_table_3 => io_tbl_types,
                                           i_value_3  => i_content_type);
            END IF;
        
            IF (i_actual_row.dt_trf_accepted_tstz IS NOT NULL AND i_actual_row.id_prof_comp IS NOT NULL)
            THEN
                --deferring date
                pk_inp_detail.add_3_values(io_table_1 => io_tbl_labels,
                                           i_value_1  => pk_message.get_message(i_lang, i_label_codes(2)),
                                           io_table_2 => io_tbl_values,
                                           i_value_2  => pk_date_utils.date_char_tsz(i_lang,
                                                                                     i_actual_row.dt_trf_accepted_tstz,
                                                                                     i_prof.institution,
                                                                                     i_prof.software),
                                           io_table_3 => io_tbl_types,
                                           i_value_3  => i_content_type);
            END IF;
        END IF;
    
        --answer
        IF (i_actual_row.trf_answer IS NOT NULL)
        THEN
            pk_inp_detail.add_3_values(io_table_1 => io_tbl_labels,
                                       i_value_1  => pk_message.get_message(i_lang, i_label_codes(3)),
                                       io_table_2 => io_tbl_values,
                                       i_value_2  => i_actual_row.trf_answer,
                                       io_table_3 => io_tbl_types,
                                       i_value_3  => i_content_type);
        END IF;
    
        --bed
        IF (i_flg_screen = g_history_h OR (i_flg_screen = g_detail_d AND i_actual_row.id_bed_execute IS NULL))
        THEN
            IF (i_actual_row.id_bed IS NOT NULL)
            THEN
                pk_inp_detail.add_3_values(io_table_1 => io_tbl_labels,
                                           i_value_1  => pk_message.get_message(i_lang, i_label_codes(4)),
                                           io_table_2 => io_tbl_values,
                                           i_value_2  => pk_bed.get_bed_desc(i_lang   => i_lang,
                                                                             i_prof   => i_prof,
                                                                             i_id_bed => i_actual_row.id_bed),
                                           io_table_3 => io_tbl_types,
                                           i_value_3  => i_content_type);
            END IF;
        END IF;
    
        --room
        IF (i_flg_screen = g_history_h OR (i_flg_screen = g_detail_d AND i_actual_row.id_room_execute IS NULL))
        THEN
            IF (i_actual_row.id_room IS NOT NULL)
            THEN
                pk_inp_detail.add_3_values(io_table_1 => io_tbl_labels,
                                           i_value_1  => pk_message.get_message(i_lang, i_label_codes(5)),
                                           io_table_2 => io_tbl_values,
                                           i_value_2  => get_room_desc(i_lang    => i_lang,
                                                                       i_prof    => i_prof,
                                                                       i_id_room => i_actual_row.id_room),
                                           io_table_3 => io_tbl_types,
                                           i_value_3  => i_content_type);
            END IF;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_ACCEPTED_FIELDS',
                                              o_error    => o_error);
            RETURN FALSE;
    END get_accepted_fields;

    /********************************************************************************************
    * Get the the fields data to the detail and history related with the decline step.
    * To be used on detail and history
    *
    * @param   I_LANG                      language associated to the professional executing the request
    * @param   i_prof                      professional
    * @param   i_actual_row                Service tranfer data
    * @param   i_flg_screen                D-detail; H-History  
    * @param   i_labels_codes              Sys_message codes of the labels to be used in the finalized status related fields
    * @param   i_content_type              Detail/History formatting type                                               
    * @param   io_labels                   List of labels
    * @param   io_values                   List of values
    * @param   io_types                    List of formatting types
    * @param   o_error                     Error message
    *                        
    * @return  true or false on success or error
    * 
    * @author                         Sofia Mendes
    * @version                        2.6.0.4
    * @since                          28-Mar-2011
    **********************************************************************************************/
    FUNCTION get_declined_fields
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_flg_screen   IN VARCHAR2,
        i_actual_row   IN epis_prof_resp%ROWTYPE,
        i_label_codes  IN table_varchar,
        i_content_type IN VARCHAR2,
        io_tbl_labels  IN OUT NOCOPY table_varchar,
        io_tbl_values  IN OUT NOCOPY table_varchar,
        io_tbl_types   IN OUT NOCOPY table_varchar,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        IF (i_flg_screen = g_detail_d)
        THEN
            --declined prof 
            pk_inp_detail.add_3_values(io_table_1 => io_tbl_labels,
                                       i_value_1  => pk_message.get_message(i_lang, i_label_codes(1)),
                                       io_table_2 => io_tbl_values,
                                       i_value_2  => pk_prof_utils.get_name_signature(i_lang,
                                                                                      i_prof,
                                                                                      i_actual_row.id_prof_decline),
                                       io_table_3 => io_tbl_types,
                                       i_value_3  => i_content_type);
        
            IF (i_actual_row.dt_decline_tstz IS NOT NULL)
            THEN
                --declined date
                pk_inp_detail.add_3_values(io_table_1 => io_tbl_labels,
                                           i_value_1  => pk_message.get_message(i_lang, i_label_codes(2)),
                                           io_table_2 => io_tbl_values,
                                           i_value_2  => pk_date_utils.date_char_tsz(i_lang,
                                                                                     i_actual_row.dt_decline_tstz,
                                                                                     i_prof.institution,
                                                                                     i_prof.software),
                                           io_table_3 => io_tbl_types,
                                           i_value_3  => i_content_type);
            END IF;
        END IF;
    
        --answer
        IF (i_actual_row.trf_answer IS NOT NULL)
        THEN
            pk_inp_detail.add_3_values(io_table_1 => io_tbl_labels,
                                       i_value_1  => pk_message.get_message(i_lang, i_label_codes(3)),
                                       io_table_2 => io_tbl_values,
                                       i_value_2  => i_actual_row.trf_answer,
                                       io_table_3 => io_tbl_types,
                                       i_value_3  => i_content_type);
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_DECLINED_FIELDS',
                                              o_error    => o_error);
            RETURN FALSE;
    END get_declined_fields;

    /********************************************************************************************
    * Get the fields data to the detail and history related with the in transit step.
    * To be used on detail and history
    *
    * @param   I_LANG                      language associated to the professional executing the request
    * @param   i_prof                      professional
    * @param   i_actual_row                Service tranfer data
    * @param   i_flg_screen                D-detail; H-History  
    * @param   i_labels_codes              Sys_message codes of the labels to be used in the finalized status related fields
    * @param   i_content_type              Detail/History formatting type                                               
    * @param   io_labels                   List of labels
    * @param   io_values                   List of values
    * @param   io_types                    List of formatting types
    * @param   o_error                     Error message
    *                        
    * @return  true or false on success or error
    * 
    * @author                         Sofia Mendes
    * @version                        2.6.0.4
    * @since                          28-Mar-2011
    **********************************************************************************************/
    FUNCTION get_in_transit_fields
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_flg_screen         IN VARCHAR2,
        i_flg_show_exec_prof IN VARCHAR2 DEFAULT pk_alert_constant.g_yes,
        i_actual_row         IN epis_prof_resp%ROWTYPE,
        i_label_codes        IN table_varchar,
        i_content_type       IN VARCHAR2,
        io_tbl_labels        IN OUT NOCOPY table_varchar,
        io_tbl_values        IN OUT NOCOPY table_varchar,
        io_tbl_types         IN OUT NOCOPY table_varchar,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        IF (i_flg_show_exec_prof = pk_alert_constant.g_yes)
        THEN
            --execution professional
            pk_inp_detail.add_3_values(io_table_1 => io_tbl_labels,
                                       i_value_1  => pk_message.get_message(i_lang, i_label_codes(7)),
                                       io_table_2 => io_tbl_values,
                                       i_value_2  => pk_prof_utils.get_name_signature(i_lang,
                                                                                      i_prof,
                                                                                      i_actual_row.id_prof_execute),
                                       io_table_3 => io_tbl_types,
                                       i_value_3  => i_content_type);
        
            --execution date
            pk_inp_detail.add_3_values(io_table_1 => io_tbl_labels,
                                       i_value_1  => pk_message.get_message(i_lang, i_label_codes(8)),
                                       io_table_2 => io_tbl_values,
                                       i_value_2  => pk_date_utils.date_char_tsz(i_lang,
                                                                                 i_actual_row.dt_execute_tstz,
                                                                                 i_prof.institution,
                                                                                 i_prof.software),
                                       io_table_3 => io_tbl_types,
                                       i_value_3  => i_content_type);
        END IF;
    
        --transport    
        pk_inp_detail.add_3_values(io_table_1 => io_tbl_labels,
                                   i_value_1  => pk_message.get_message(i_lang, i_label_codes(1)),
                                   io_table_2 => io_tbl_values,
                                   i_value_2  => pk_sysdomain.get_domain('YES_NO',
                                                                         CASE
                                                                             WHEN i_actual_row.id_movement IS NULL THEN
                                                                              'N'
                                                                             ELSE
                                                                              'Y'
                                                                         END,
                                                                         i_lang),
                                   io_table_3 => io_tbl_types,
                                   i_value_3  => i_content_type);
    
        --transport mean 
        IF (i_actual_row.id_movement IS NOT NULL)
        THEN
            pk_inp_detail.add_3_values(io_table_1 => io_tbl_labels,
                                       i_value_1  => pk_message.get_message(i_lang, i_label_codes(2)),
                                       io_table_2 => io_tbl_values,
                                       i_value_2  => get_necessity_desc(i_lang        => i_lang,
                                                                        i_prof        => i_prof,
                                                                        i_id_movement => i_actual_row.id_movement),
                                       io_table_3 => io_tbl_types,
                                       i_value_3  => i_content_type);
        END IF;
    
        IF (i_actual_row.transport_notes IS NOT NULL)
        THEN
            pk_inp_detail.add_3_values(io_table_1 => io_tbl_labels,
                                       i_value_1  => pk_message.get_message(i_lang, i_label_codes(3)),
                                       io_table_2 => io_tbl_values,
                                       i_value_2  => i_actual_row.transport_notes,
                                       io_table_3 => io_tbl_types,
                                       i_value_3  => i_content_type);
        END IF;
    
        --bed      
        IF (i_actual_row.id_bed_execute IS NOT NULL)
        THEN
            pk_inp_detail.add_3_values(io_table_1 => io_tbl_labels,
                                       i_value_1  => pk_message.get_message(i_lang, i_label_codes(4)),
                                       io_table_2 => io_tbl_values,
                                       i_value_2  => pk_bed.get_bed_desc(i_lang   => i_lang,
                                                                         i_prof   => i_prof,
                                                                         i_id_bed => i_actual_row.id_bed_execute),
                                       io_table_3 => io_tbl_types,
                                       i_value_3  => i_content_type);
        
            IF (i_flg_screen = g_history_h AND i_actual_row.id_bed <> i_actual_row.id_bed_execute)
            THEN
                pk_inp_detail.add_3_values(io_table_1 => io_tbl_labels,
                                           i_value_1  => pk_message.get_message(i_lang, 'TRANSFER_T042'),
                                           io_table_2 => io_tbl_values,
                                           i_value_2  => pk_bed.get_bed_desc(i_lang   => i_lang,
                                                                             i_prof   => i_prof,
                                                                             i_id_bed => i_actual_row.id_bed),
                                           io_table_3 => io_tbl_types,
                                           i_value_3  => g_content_c);
            END IF;
        END IF;
    
        --room
        IF (i_actual_row.id_room_execute IS NOT NULL)
        THEN
            pk_inp_detail.add_3_values(io_table_1 => io_tbl_labels,
                                       i_value_1  => pk_message.get_message(i_lang, i_label_codes(5)),
                                       io_table_2 => io_tbl_values,
                                       i_value_2  => get_room_desc(i_lang    => i_lang,
                                                                   i_prof    => i_prof,
                                                                   i_id_room => i_actual_row.id_room_execute),
                                       io_table_3 => io_tbl_types,
                                       i_value_3  => i_content_type);
        
            IF (i_flg_screen = g_history_h AND i_actual_row.id_room <> i_actual_row.id_room_execute)
            THEN
                pk_inp_detail.add_3_values(io_table_1 => io_tbl_labels,
                                           i_value_1  => pk_message.get_message(i_lang, 'TRANSFER_T043'),
                                           io_table_2 => io_tbl_values,
                                           i_value_2  => get_room_desc(i_lang    => i_lang,
                                                                       i_prof    => i_prof,
                                                                       i_id_room => i_actual_row.id_room),
                                           io_table_3 => io_tbl_types,
                                           i_value_3  => g_content_c);
            END IF;
        END IF;
    
        --
        pk_inp_detail.add_3_values(io_table_1 => io_tbl_labels,
                                   i_value_1  => pk_message.get_message(i_lang, i_label_codes(6)),
                                   io_table_2 => io_tbl_values,
                                   i_value_2  => pk_sysdomain.get_domain('YES_NO',
                                                                         nvl(i_actual_row.flg_escort, 'N'),
                                                                         i_lang),
                                   io_table_3 => io_tbl_types,
                                   i_value_3  => i_content_type);
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_IN_TRANSIT_FIELDS',
                                              o_error    => o_error);
            RETURN FALSE;
    END get_in_transit_fields;

    /********************************************************************************************
    * Get the fields data to the detail and history related with the cancellation step.
    * To be used on detail and history
    *
    * @param   I_LANG                      language associated to the professional executing the request
    * @param   i_prof                      professional
    * @param   i_actual_row                Service tranfer data
    * @param   i_flg_screen                D-detail; H-History  
    * @param   i_labels_codes              Sys_message codes of the labels to be used in the finalized status related fields
    * @param   i_content_type              Detail/History formatting type                                               
    * @param   io_labels                   List of labels
    * @param   io_values                   List of values
    * @param   io_types                    List of formatting types
    * @param   o_error                     Error message
    *                        
    * @return  true or false on success or error
    * 
    * @author                         Sofia Mendes
    * @version                        2.6.0.4
    * @since                          28-Mar-2011
    **********************************************************************************************/
    FUNCTION get_cancellation_fields
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_flg_screen   IN VARCHAR2,
        i_actual_row   IN epis_prof_resp%ROWTYPE,
        i_label_codes  IN table_varchar,
        i_content_type IN VARCHAR2,
        io_tbl_labels  IN OUT NOCOPY table_varchar,
        io_tbl_values  IN OUT NOCOPY table_varchar,
        io_tbl_types   IN OUT NOCOPY table_varchar,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        IF (i_flg_screen = g_detail_d)
        THEN
            --cancellation professional
            pk_inp_detail.add_3_values(io_table_1 => io_tbl_labels,
                                       i_value_1  => pk_message.get_message(i_lang, i_label_codes(1)),
                                       io_table_2 => io_tbl_values,
                                       i_value_2  => pk_prof_utils.get_name_signature(i_lang,
                                                                                      i_prof,
                                                                                      i_actual_row.id_prof_cancel),
                                       io_table_3 => io_tbl_types,
                                       i_value_3  => i_content_type);
        
            --cancelation date
            pk_inp_detail.add_3_values(io_table_1 => io_tbl_labels,
                                       i_value_1  => pk_message.get_message(i_lang, i_label_codes(2)),
                                       io_table_2 => io_tbl_values,
                                       i_value_2  => pk_date_utils.date_char_tsz(i_lang,
                                                                                 i_actual_row.dt_cancel_tstz,
                                                                                 i_prof.institution,
                                                                                 i_prof.software),
                                       io_table_3 => io_tbl_types,
                                       i_value_3  => i_content_type);
        END IF;
    
        --Cancel reason
        IF i_actual_row.id_cancel_reason IS NOT NULL
        THEN
            pk_inp_detail.add_3_values(io_table_1 => io_tbl_labels,
                                       i_value_1  => pk_message.get_message(i_lang, i_label_codes(4)),
                                       io_table_2 => io_tbl_values,
                                       i_value_2  => pk_cancel_reason.get_cancel_reason_desc(i_lang             => i_lang,
                                                                                             i_prof             => i_prof,
                                                                                             i_id_cancel_reason => i_actual_row.id_cancel_reason),
                                       io_table_3 => io_tbl_types,
                                       i_value_3  => i_content_type);
        END IF;
    
        --cancellation notes 
        IF (i_actual_row.notes_cancel IS NOT NULL)
        THEN
            pk_inp_detail.add_3_values(io_table_1 => io_tbl_labels,
                                       i_value_1  => pk_message.get_message(i_lang, i_label_codes(3)),
                                       io_table_2 => io_tbl_values,
                                       i_value_2  => i_actual_row.notes_cancel,
                                       io_table_3 => io_tbl_types,
                                       i_value_3  => i_content_type);
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_CANCELLATION_FIELDS',
                                              o_error    => o_error);
            RETURN FALSE;
    END get_cancellation_fields;

    /********************************************************************************************
    * Get the fields data to be shown in detail screen and the first record info of the history screen.
    * To be used on detail and history
    *
    * @param   I_LANG                      language associated to the professional executing the request
    * @param   i_prof                      professional
    * @param   i_actual_row                Service tranfer data
    * @param   i_flg_screen                D-detail; H-History                                                     
    * @param   o_tbl_labels                List of labels
    * @param   o_tbl_values                List of values
    * @param   o_tbl_types                 List of formatting types
    * @param   o_error                     Error message
    *                        
    * @return  true or false on success or error
    * 
    * @author                         Sofia Mendes
    * @version                        2.6.0.4
    * @since                          28-Mar-2011
    **********************************************************************************************/
    FUNCTION get_first_values
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_actual_row IN epis_prof_resp%ROWTYPE,
        i_flg_screen IN VARCHAR2,
        o_tbl_labels OUT table_varchar,
        o_tbl_values OUT table_varchar,
        o_tbl_types  OUT table_varchar,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_prof_finalize epis_prof_resp.id_prof_execute%TYPE;
        l_dt_finalize   epis_prof_resp.dt_execute_tstz%TYPE;
        l_label_codes   table_varchar := table_varchar();
    BEGIN
        o_tbl_labels := table_varchar();
        o_tbl_values := table_varchar();
        o_tbl_types  := table_varchar();
    
        g_error := 'CALL get_request_fields';
        pk_alertlog.log_debug(g_error);
        IF NOT get_request_fields(i_lang        => i_lang,
                                  i_prof        => i_prof,
                                  i_actual_row  => i_actual_row,
                                  i_flg_screen  => i_flg_screen,
                                  io_tbl_labels => o_tbl_labels,
                                  io_tbl_values => o_tbl_values,
                                  io_tbl_types  => o_tbl_types,
                                  o_error       => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        IF (i_flg_screen = g_detail_d)
        THEN
            IF (i_actual_row.flg_status <> pk_hand_off.g_hand_off_r)
            THEN
                --set an empty new line
                pk_inp_detail.add_3_values(io_table_1 => o_tbl_labels,
                                           i_value_1  => NULL,
                                           io_table_2 => o_tbl_values,
                                           i_value_2  => NULL,
                                           io_table_3 => o_tbl_types,
                                           i_value_3  => g_line_l);
            END IF;
        
            -- Deferring status fields: F  
            IF (i_actual_row.id_prof_comp IS NOT NULL)
            THEN
                l_label_codes.extend(5);
                l_label_codes(1) := 'TRANSFER_T024'; --deferring prof
                l_label_codes(2) := 'TRANSFER_T025'; --date
                l_label_codes(3) := 'TRANSFER_T026'; --answer
                l_label_codes(4) := 'TRANSFER_T042'; --bed
                l_label_codes(5) := 'TRANSFER_T043'; --room
            
                g_error := 'CALL get_accepted_fields';
                pk_alertlog.log_debug(g_error);
                IF NOT get_accepted_fields(i_lang         => i_lang,
                                           i_prof         => i_prof,
                                           i_flg_screen   => i_flg_screen,
                                           i_actual_row   => i_actual_row,
                                           i_label_codes  => l_label_codes,
                                           i_content_type => g_content_c,
                                           io_tbl_labels  => o_tbl_labels,
                                           io_tbl_values  => o_tbl_values,
                                           io_tbl_types   => o_tbl_types,
                                           o_error        => o_error)
                THEN
                    RAISE g_exception;
                END IF;
            
                IF (i_actual_row.flg_status <> pk_hand_off.g_hand_off_f)
                THEN
                    --set an empty new line
                    pk_inp_detail.add_3_values(io_table_1 => o_tbl_labels,
                                               i_value_1  => NULL,
                                               io_table_2 => o_tbl_values,
                                               i_value_2  => NULL,
                                               io_table_3 => o_tbl_types,
                                               i_value_3  => g_line_l);
                END IF;
            END IF;
        
            --decline fields
            IF (i_actual_row.id_prof_decline IS NOT NULL)
            THEN
                l_label_codes := table_varchar();
                l_label_codes.extend(3);
                l_label_codes(1) := 'TRANSFER_T032'; --declining prof 
                l_label_codes(2) := 'TRANSFER_T035'; --date
                l_label_codes(3) := 'TRANSFER_T026'; --answer        
            
                g_error := 'CALL get_declined_fields';
                pk_alertlog.log_debug(g_error);
                IF NOT get_declined_fields(i_lang         => i_lang,
                                           i_prof         => i_prof,
                                           i_flg_screen   => i_flg_screen,
                                           i_actual_row   => i_actual_row,
                                           i_label_codes  => l_label_codes,
                                           i_content_type => g_content_c,
                                           io_tbl_labels  => o_tbl_labels,
                                           io_tbl_values  => o_tbl_values,
                                           io_tbl_types   => o_tbl_types,
                                           o_error        => o_error)
                THEN
                    RAISE g_exception;
                END IF;
            
            END IF;
        
            IF (i_actual_row.id_movement IS NOT NULL)
            THEN
                l_label_codes.extend(8);
                l_label_codes(1) := 'TRANSFER_T029';
                l_label_codes(2) := 'TRANSFER_T030';
                l_label_codes(3) := 'TRANSFER_T031';
                l_label_codes(4) := 'TRANSFER_T042';
                l_label_codes(5) := 'TRANSFER_T043';
                l_label_codes(6) := 'TRANSFER_T045';
                l_label_codes(7) := 'TRANSFER_T062';
                l_label_codes(8) := 'TRANSFER_T063';
            
                g_error := 'CALL get_declined_fields';
                pk_alertlog.log_debug(g_error);
                IF NOT get_in_transit_fields(i_lang               => i_lang,
                                        i_prof               => i_prof,
                                        i_flg_screen         => i_flg_screen,
                                        i_flg_show_exec_prof => CASE
                                                                    WHEN i_flg_screen = g_history_h THEN
                                                                     pk_alert_constant.g_no
                                                                    ELSE
                                                                     pk_alert_constant.g_yes
                                                                END,
                                        i_actual_row         => i_actual_row,
                                        i_label_codes        => l_label_codes,
                                        i_content_type       => g_content_c,
                                        io_tbl_labels        => o_tbl_labels,
                                        io_tbl_values        => o_tbl_values,
                                        io_tbl_types         => o_tbl_types,
                                        o_error              => o_error)
                THEN
                    RAISE g_exception;
                END IF;
            
                IF (i_actual_row.flg_status <> pk_hand_off.g_hand_off_i)
                THEN
                    --set an empty new line
                    pk_inp_detail.add_3_values(io_table_1 => o_tbl_labels,
                                               i_value_1  => NULL,
                                               io_table_2 => o_tbl_values,
                                               i_value_2  => NULL,
                                               io_table_3 => o_tbl_types,
                                               i_value_3  => g_line_l);
                END IF;
            END IF;
        
            IF ((i_actual_row.id_prof_execute IS NOT NULL AND i_actual_row.id_movement IS NULL) OR
               (i_actual_row.id_prof_execute IS NOT NULL AND i_actual_row.id_movement IS NOT NULL AND
               i_actual_row.dt_end_transfer_tstz IS NOT NULL))
            THEN
                l_label_codes.extend(8);
                l_label_codes(1) := 'TRANSFER_T027';
                l_label_codes(2) := 'TRANSFER_T028';
                l_label_codes(3) := 'TRANSFER_T029';
                l_label_codes(4) := 'TRANSFER_T030';
                l_label_codes(5) := 'TRANSFER_T031';
                l_label_codes(6) := 'TRANSFER_T042';
                l_label_codes(7) := 'TRANSFER_T043';
                l_label_codes(8) := 'TRANSFER_T045';
            
                --finalize status specific fields
                g_error := 'CALL get_finalize_fields';
                pk_alertlog.log_debug(g_error);
                IF NOT get_finalize_fields(i_lang          => i_lang,
                                           i_prof          => i_prof,
                                           i_actual_row    => i_actual_row,
                                           i_labels_codes  => l_label_codes,
                                           i_content_type  => g_content_c,
                                           io_labels       => o_tbl_labels,
                                           io_values       => o_tbl_values,
                                           io_types        => o_tbl_types,
                                           o_prof_finalize => l_prof_finalize,
                                           o_dt_finalize   => l_dt_finalize,
                                           o_error         => o_error)
                THEN
                    RAISE g_exception;
                END IF;
            
                IF (i_actual_row.id_movement IS NULL)
                THEN
                    l_label_codes.extend(6);
                    l_label_codes(1) := 'TRANSFER_T029';
                    l_label_codes(2) := 'TRANSFER_T030';
                    l_label_codes(3) := 'TRANSFER_T031';
                    l_label_codes(4) := 'TRANSFER_T042';
                    l_label_codes(5) := 'TRANSFER_T043';
                    l_label_codes(6) := 'TRANSFER_T045';
                    l_label_codes(7) := 'TRANSFER_T062';
                    l_label_codes(8) := 'TRANSFER_T063';
                
                    g_error := 'CALL get_declined_fields';
                    pk_alertlog.log_debug(g_error);
                    IF NOT get_in_transit_fields(i_lang               => i_lang,
                                                 i_prof               => i_prof,
                                                 i_flg_screen         => i_flg_screen,
                                                 i_flg_show_exec_prof => pk_alert_constant.g_no, --should not be shown the professional and date
                                                 i_actual_row         => i_actual_row,
                                                 i_label_codes        => l_label_codes,
                                                 i_content_type       => g_content_c,
                                                 io_tbl_labels        => o_tbl_labels,
                                                 io_tbl_values        => o_tbl_values,
                                                 io_tbl_types         => o_tbl_types,
                                                 o_error              => o_error)
                    THEN
                        RAISE g_exception;
                    END IF;
                END IF;
            
                IF (i_actual_row.flg_status <> pk_hand_off.g_hand_off_x)
                THEN
                    --set an empty new line
                    pk_inp_detail.add_3_values(io_table_1 => o_tbl_labels,
                                               i_value_1  => NULL,
                                               io_table_2 => o_tbl_values,
                                               i_value_2  => NULL,
                                               io_table_3 => o_tbl_types,
                                               i_value_3  => g_line_l);
                END IF;
            END IF;
        
            --Cancellation info
            IF (i_actual_row.id_prof_cancel IS NOT NULL)
            THEN
            
                l_label_codes.extend(8);
                l_label_codes(1) := 'TRANSFER_T033'; --cancellation professional
                l_label_codes(2) := 'TRANSFER_T034'; --cancelation date
                l_label_codes(3) := 'COMMON_M073'; --cancellation notes 
                l_label_codes(4) := 'TRANSFER_M022'; --cancel reason
            
                --cancellation status specific fields
                g_error := 'CALL get_cancellation_fields';
                pk_alertlog.log_debug(g_error);
                IF NOT get_cancellation_fields(i_lang         => i_lang,
                                               i_prof         => i_prof,
                                               i_flg_screen   => i_flg_screen,
                                               i_actual_row   => i_actual_row,
                                               i_label_codes  => l_label_codes,
                                               i_content_type => g_new_content_n,
                                               io_tbl_labels  => o_tbl_labels,
                                               io_tbl_values  => o_tbl_values,
                                               io_tbl_types   => o_tbl_types,
                                               o_error        => o_error)
                THEN
                    RAISE g_exception;
                END IF;
            
            END IF;
        
        END IF;
    
        --signature
        pk_inp_detail.add_3_values(io_table_1 => o_tbl_labels,
                                   i_value_1  => NULL,
                                   io_table_2 => o_tbl_values,
                                   i_value_2  => get_signature(i_lang                => i_lang,
                                                               i_prof                => i_prof,
                                                               i_id_episode          => i_actual_row.id_episode,
                                                               i_date                => CASE
                                                                                            WHEN i_flg_screen = g_detail_d THEN
                                                                                             coalesce(l_dt_finalize,
                                                                                                      i_actual_row.dt_execute_tstz,
                                                                                                      i_actual_row.dt_cancel_tstz,
                                                                                                      i_actual_row.dt_decline_tstz,
                                                                                                      i_actual_row.dt_trf_accepted_tstz,
                                                                                                      i_actual_row.dt_request_tstz)
                                                                                            ELSE
                                                                                             i_actual_row.dt_request_tstz
                                                                                        END,
                                                               i_id_prof_last_change => CASE
                                                                                            WHEN i_flg_screen = g_detail_d THEN
                                                                                             coalesce(l_prof_finalize,
                                                                                                      i_actual_row.id_prof_execute,
                                                                                                      i_actual_row.id_prof_cancel,
                                                                                                      i_actual_row.id_prof_decline,
                                                                                                      i_actual_row.id_prof_comp,
                                                                                                      i_actual_row.id_prof_req)
                                                                                            ELSE
                                                                                             i_actual_row.id_prof_req
                                                                                        END),
                                   io_table_3 => o_tbl_types,
                                   i_value_3  => g_signature_s);
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package_name,
                                              'GET_FIRST_VALUES',
                                              o_error);
            RETURN NULL;
    END get_first_values;

    /********************************************************************************************
    * Get the fields data to be shown in the history screen related with the cancellation step.
    * To be used on detail and history
    *
    * @param   I_LANG                      language associated to the professional executing the request
    * @param   i_prof                      professional
    * @param   i_actual_row                Service tranfer data
    * @param   i_labels                    common labels                                                     
    * @param   i_info_labels               info label used in flash to addicional formatting  
    * @param   io_tab_hist                 Structure with all the detail/history data
    * @param   o_error                     Error message
    *                        
    * @return  true or false on success or error
    * 
    * @author                         Sofia Mendes
    * @version                        2.6.0.4
    * @since                          28-Mar-2011
    **********************************************************************************************/
    FUNCTION get_cancellation_hist
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_actual_row  IN epis_prof_resp%ROWTYPE,
        i_labels      IN table_varchar,
        i_info_labels IN table_varchar,
        io_tab_hist   IN OUT t_table_history_data,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_prev_status epis_prof_resp.flg_status%TYPE;
        l_labels      table_varchar := table_varchar();
        l_values      table_varchar := table_varchar();
        l_types       table_varchar := table_varchar();
        l_label_codes table_varchar := table_varchar();
    BEGIN
        IF (i_actual_row.flg_status = pk_hand_off.g_hand_off_c)
        THEN
            --calc prev status
            l_prev_status := CASE
                                 WHEN i_actual_row.id_prof_execute IS NOT NULL THEN
                                  pk_hand_off.g_hand_off_x
                                 WHEN i_actual_row.id_prof_comp IS NOT NULL
                                      AND i_actual_row.id_movement IS NOT NULL THEN
                                  pk_hand_off.g_hand_off_i
                                 WHEN i_actual_row.id_prof_comp IS NOT NULL
                                      AND i_actual_row.id_movement IS NULL THEN
                                  pk_hand_off.g_hand_off_f
                                 WHEN i_actual_row.id_prof_req IS NOT NULL THEN
                                  pk_hand_off.g_hand_off_r
                             END;
        
            --title
            pk_inp_detail.add_3_values(io_table_1 => l_labels,
                                       i_value_1  => pk_sysdomain.get_domain(i_code_dom => g_sd_transfer_status_det_desc,
                                                                             i_val      => pk_hand_off.g_hand_off_c,
                                                                             i_lang     => i_lang),
                                       io_table_2 => l_values,
                                       i_value_2  => NULL,
                                       io_table_3 => l_types,
                                       i_value_3  => g_title_t);
        
            --set status change
            pk_inp_detail.add_3_values(io_table_1 => l_labels,
                                       i_value_1  => i_labels(1),
                                       io_table_2 => l_values,
                                       i_value_2  => pk_sysdomain.get_domain(i_code_dom => g_sd_transfer_status,
                                                                             i_val      => i_actual_row.flg_status,
                                                                             i_lang     => i_lang),
                                       io_table_3 => l_types,
                                       i_value_3  => g_new_content_n);
        
            --status               
            pk_inp_detail.add_3_values(io_table_1 => l_labels,
                                       i_value_1  => i_labels(2),
                                       io_table_2 => l_values,
                                       i_value_2  => pk_sysdomain.get_domain(i_code_dom => g_sd_transfer_status,
                                                                             i_val      => l_prev_status,
                                                                             i_lang     => i_lang),
                                       io_table_3 => l_types,
                                       i_value_3  => g_content_c);
        
            l_label_codes.extend(8);
            l_label_codes(1) := 'TRANSFER_M014'; --cancellation professional
            l_label_codes(2) := 'TRANSFER_M020'; --cancelation date
            l_label_codes(3) := 'TRANSFER_M021'; --cancellation notes 
            l_label_codes(4) := 'TRANSFER_M022'; --cancel reason
        
            --cancellation status specific fields
            g_error := 'CALL get_cancellation_fields';
            pk_alertlog.log_debug(g_error);
            IF NOT get_cancellation_fields(i_lang         => i_lang,
                                           i_prof         => i_prof,
                                           i_flg_screen   => g_history_h,
                                           i_actual_row   => i_actual_row,
                                           i_label_codes  => l_label_codes,
                                           i_content_type => g_new_content_n,
                                           io_tbl_labels  => l_labels,
                                           io_tbl_values  => l_values,
                                           io_tbl_types   => l_types,
                                           o_error        => o_error)
            THEN
                RAISE g_exception;
            END IF;
        
            --signature
            pk_inp_detail.add_3_values(io_table_1 => l_labels,
                                       i_value_1  => NULL,
                                       io_table_2 => l_values,
                                       i_value_2  => get_signature(i_lang                => i_lang,
                                                                   i_prof                => i_prof,
                                                                   i_id_episode          => i_actual_row.id_episode,
                                                                   i_date                => i_actual_row.dt_cancel_tstz,
                                                                   i_id_prof_last_change => i_actual_row.id_prof_cancel),
                                       io_table_3 => l_types,
                                       i_value_3  => g_signature_s);
        
            io_tab_hist.extend;
            io_tab_hist(io_tab_hist.count) := t_rec_history_data(id_rec          => i_actual_row.id_epis_prof_resp,
                                                                 flg_status      => i_actual_row.flg_status,
                                                                 date_rec        => NULL,
                                                                 tbl_labels      => l_labels,
                                                                 tbl_values      => l_values,
                                                                 tbl_types       => l_types,
                                                                 tbl_info_labels => i_info_labels,
                                                                 tbl_info_values => table_varchar(pk_hand_off.g_hand_off_c),
                                                                 table_origin    => NULL);
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_CANCELLATION_HIST',
                                              o_error    => o_error);
            RETURN FALSE;
    END get_cancellation_hist;

    /********************************************************************************************
    * Get the fields data to be shown in the history screen related with the finalization step.
    * To be used on detail and history
    *
    * @param   I_LANG                      language associated to the professional executing the request
    * @param   i_prof                      professional
    * @param   i_actual_row                Service tranfer data                                                         
    * @param   i_info_labels               info label used in flash to addicional formatting  
    * @param   i_info_values               info values used in flash to addicional formatting
    * @param   i_labels                    common labels
    * @param   io_tab_hist                 Structure with all the detail/history data
    * @param   o_error                     Error message
    *                        
    * @return  true or false on success or error
    * 
    * @author                         Sofia Mendes
    * @version                        2.6.0.4
    * @since                          28-Mar-2011
    **********************************************************************************************/
    FUNCTION get_finalize_hist
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_actual_row  IN epis_prof_resp%ROWTYPE,
        i_info_labels IN table_varchar,
        i_info_values IN table_varchar,
        i_labels      IN table_varchar,
        io_tab_hist   IN OUT t_table_history_data,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_prev_status epis_prof_resp.flg_status%TYPE;
        l_labels      table_varchar := table_varchar();
        l_values      table_varchar := table_varchar();
        l_types       table_varchar := table_varchar();
        l_internal_errror EXCEPTION;
        l_prof_finalize movement.id_prof_receive%TYPE;
        l_dt_finalize   epis_prof_resp.dt_execute_tstz%TYPE;
        l_label_codes   table_varchar := table_varchar();
    BEGIN
        IF ((i_actual_row.id_prof_execute IS NOT NULL AND i_actual_row.id_movement IS NULL) OR
           (i_actual_row.id_prof_execute IS NOT NULL AND i_actual_row.id_movement IS NOT NULL AND
           i_actual_row.dt_end_transfer_tstz IS NOT NULL))
        THEN
            --calc prev status
            l_prev_status := CASE
                                 WHEN i_actual_row.id_prof_comp IS NOT NULL
                                      AND i_actual_row.id_movement IS NOT NULL THEN
                                  pk_hand_off.g_hand_off_i
                                 ELSE
                                  pk_hand_off.g_hand_off_f
                             END;
        
            --title
            pk_inp_detail.add_3_values(io_table_1 => l_labels,
                                       i_value_1  => pk_sysdomain.get_domain(i_code_dom => g_sd_transfer_status_det_desc,
                                                                             i_val      => pk_hand_off.g_hand_off_x,
                                                                             i_lang     => i_lang),
                                       io_table_2 => l_values,
                                       i_value_2  => NULL,
                                       io_table_3 => l_types,
                                       i_value_3  => g_title_t);
        
            --set status change
            --it is not possible to change the status from the execution state
            pk_inp_detail.add_3_values(io_table_1 => l_labels,
                                       i_value_1  => i_labels(1),
                                       io_table_2 => l_values,
                                       i_value_2  => pk_sysdomain.get_domain(i_code_dom => g_sd_transfer_status,
                                                                             i_val      => pk_hand_off.g_hand_off_x,
                                                                             i_lang     => i_lang),
                                       io_table_3 => l_types,
                                       i_value_3  => g_new_content_n);
        
            --status               
            pk_inp_detail.add_3_values(io_table_1 => l_labels,
                                       i_value_1  => i_labels(2),
                                       io_table_2 => l_values,
                                       i_value_2  => pk_sysdomain.get_domain(i_code_dom => g_sd_transfer_status,
                                                                             i_val      => l_prev_status,
                                                                             i_lang     => i_lang),
                                       io_table_3 => l_types,
                                       i_value_3  => g_content_c);
        
            g_error := 'CALL get_finalize_dt_prof';
            pk_alertlog.log_debug(g_error);
            IF NOT get_finalize_dt_prof(i_lang          => i_lang,
                                        i_prof          => i_prof,
                                        i_actual_row    => i_actual_row,
                                        o_prof_finalize => l_prof_finalize,
                                        o_dt_finalize   => l_dt_finalize,
                                        o_error         => o_error)
            THEN
                RAISE g_exception;
            END IF;
        
            IF (i_actual_row.id_movement IS NULL)
            THEN
                l_label_codes.extend(6);
                l_label_codes(1) := 'TRANSFER_M008';
                l_label_codes(2) := 'TRANSFER_M009';
                l_label_codes(3) := 'TRANSFER_M010';
                l_label_codes(4) := 'TRANSFER_M012';
                l_label_codes(5) := 'TRANSFER_M013';
                l_label_codes(6) := 'TRANSFER_M011';
            
                --finalize status specific fields
                g_error := 'CALL get_in_transit_fields';
                pk_alertlog.log_debug(g_error);
                IF NOT get_in_transit_fields(i_lang               => i_lang,
                                             i_prof               => i_prof,
                                             i_flg_screen         => g_history_h,
                                             i_flg_show_exec_prof => pk_alert_constant.g_no,
                                             i_actual_row         => i_actual_row,
                                             i_label_codes        => l_label_codes,
                                             i_content_type       => g_new_content_n,
                                             io_tbl_labels        => l_labels,
                                             io_tbl_values        => l_values,
                                             io_tbl_types         => l_types,
                                             o_error              => o_error)
                THEN
                    RAISE g_exception;
                END IF;
            END IF;
        
            --signature
            pk_inp_detail.add_3_values(io_table_1 => l_labels,
                                       i_value_1  => NULL,
                                       io_table_2 => l_values,
                                       i_value_2  => get_signature(i_lang                => i_lang,
                                                                   i_prof                => i_prof,
                                                                   i_id_episode          => i_actual_row.id_episode,
                                                                   i_date                => l_dt_finalize,
                                                                   i_id_prof_last_change => l_prof_finalize),
                                       io_table_3 => l_types,
                                       i_value_3  => g_signature_s);
        
            io_tab_hist.extend;
            io_tab_hist(io_tab_hist.count) := t_rec_history_data(id_rec          => i_actual_row.id_epis_prof_resp,
                                                                 flg_status      => i_actual_row.flg_status,
                                                                 date_rec        => NULL,
                                                                 tbl_labels      => l_labels,
                                                                 tbl_values      => l_values,
                                                                 tbl_types       => l_types,
                                                                 tbl_info_labels => i_info_labels,
                                                                 tbl_info_values => i_info_values,
                                                                 table_origin    => NULL);
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_FINALIZE_HIST',
                                              o_error    => o_error);
            RETURN FALSE;
    END get_finalize_hist;

    /********************************************************************************************
    * Get the fields data to be shown in the history screen related with the in transit step.
    * To be used on detail and history
    *
    * @param   I_LANG                      language associated to the professional executing the request
    * @param   i_prof                      professional
    * @param   i_actual_row                Service tranfer data                                                         
    * @param   i_info_labels               info label used in flash to addicional formatting  
    * @param   i_info_values               info values used in flash to addicional formatting
    * @param   i_labels                    common labels
    * @param   io_tab_hist                 Structure with all the detail/history data
    * @param   o_error                     Error message
    *                        
    * @return  true or false on success or error
    * 
    * @author                         Sofia Mendes
    * @version                        2.6.0.4
    * @since                          28-Mar-2011
    **********************************************************************************************/
    --execution action
    FUNCTION get_in_transit_hist
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_actual_row  IN epis_prof_resp%ROWTYPE,
        i_info_labels IN table_varchar,
        i_info_values IN table_varchar,
        i_labels      IN table_varchar,
        io_tab_hist   IN OUT t_table_history_data,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_labels      table_varchar := table_varchar();
        l_values      table_varchar := table_varchar();
        l_types       table_varchar := table_varchar();
        l_label_codes table_varchar := table_varchar();
    
    BEGIN
        IF (i_actual_row.id_movement IS NOT NULL)
        THEN
            --title
            pk_inp_detail.add_3_values(io_table_1 => l_labels,
                                       i_value_1  => pk_sysdomain.get_domain(i_code_dom => g_sd_transfer_status_det_desc,
                                                                             i_val      => pk_hand_off.g_hand_off_i,
                                                                             i_lang     => i_lang),
                                       io_table_2 => l_values,
                                       i_value_2  => NULL,
                                       io_table_3 => l_types,
                                       i_value_3  => g_title_t);
        
            --set status change
            pk_inp_detail.add_3_values(io_table_1 => l_labels,
                                       i_value_1  => i_labels(1),
                                       io_table_2 => l_values,
                                       i_value_2  => pk_sysdomain.get_domain(i_code_dom => g_sd_transfer_status,
                                                                             i_val      => pk_hand_off.g_hand_off_i,
                                                                             i_lang     => i_lang),
                                       io_table_3 => l_types,
                                       i_value_3  => g_new_content_n);
        
            --status               
            pk_inp_detail.add_3_values(io_table_1 => l_labels,
                                       i_value_1  => i_labels(2),
                                       io_table_2 => l_values,
                                       i_value_2  => pk_sysdomain.get_domain(i_code_dom => g_sd_transfer_status,
                                                                             i_val      => pk_hand_off.g_hand_off_f,
                                                                             i_lang     => i_lang),
                                       io_table_3 => l_types,
                                       i_value_3  => g_content_c);
        
            l_label_codes.extend(6);
            l_label_codes(1) := 'TRANSFER_M008';
            l_label_codes(2) := 'TRANSFER_M009';
            l_label_codes(3) := 'TRANSFER_M010';
            l_label_codes(4) := 'TRANSFER_M012';
            l_label_codes(5) := 'TRANSFER_M013';
            l_label_codes(6) := 'TRANSFER_M011';
        
            --finalize status specific fields
            g_error := 'CALL get_in_transit_fields';
            pk_alertlog.log_debug(g_error);
            IF NOT get_in_transit_fields(i_lang               => i_lang,
                                         i_prof               => i_prof,
                                         i_flg_screen         => g_history_h,
                                         i_flg_show_exec_prof => pk_alert_constant.g_no,
                                         i_actual_row         => i_actual_row,
                                         i_label_codes        => l_label_codes,
                                         i_content_type       => g_new_content_n,
                                         io_tbl_labels        => l_labels,
                                         io_tbl_values        => l_values,
                                         io_tbl_types         => l_types,
                                         o_error              => o_error)
            THEN
                RAISE g_exception;
            END IF;
        
            --signature
            pk_inp_detail.add_3_values(io_table_1 => l_labels,
                                       i_value_1  => NULL,
                                       io_table_2 => l_values,
                                       i_value_2  => get_signature(i_lang                => i_lang,
                                                                   i_prof                => i_prof,
                                                                   i_id_episode          => i_actual_row.id_episode,
                                                                   i_date                => i_actual_row.dt_execute_tstz,
                                                                   i_id_prof_last_change => i_actual_row.id_prof_execute),
                                       io_table_3 => l_types,
                                       i_value_3  => g_signature_s);
        
            io_tab_hist.extend;
            io_tab_hist(io_tab_hist.count) := t_rec_history_data(id_rec          => i_actual_row.id_epis_prof_resp,
                                                                 flg_status      => i_actual_row.flg_status,
                                                                 date_rec        => NULL,
                                                                 tbl_labels      => l_labels,
                                                                 tbl_values      => l_values,
                                                                 tbl_types       => l_types,
                                                                 tbl_info_labels => i_info_labels,
                                                                 tbl_info_values => i_info_values,
                                                                 table_origin    => NULL);
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_IN_TRANSIT_HIST',
                                              o_error    => o_error);
            RETURN FALSE;
    END get_in_transit_hist;

    /********************************************************************************************
    * Get the fields data to be shown in the history screen related with the accept step.
    * To be used on detail and history
    *
    * @param   I_LANG                      language associated to the professional executing the request
    * @param   i_prof                      professional
    * @param   i_actual_row                Service tranfer data                                                         
    * @param   i_info_labels               info label used in flash to addicional formatting  
    * @param   i_info_values               info values used in flash to addicional formatting
    * @param   i_labels                    common labels
    * @param   io_tab_hist                 Structure with all the detail/history data
    * @param   o_error                     Error message
    *                        
    * @return  true or false on success or error
    * 
    * @author                         Sofia Mendes
    * @version                        2.6.0.4
    * @since                          28-Mar-2011
    **********************************************************************************************/
    FUNCTION get_accepted_hist
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_actual_row  IN epis_prof_resp%ROWTYPE,
        i_info_labels IN table_varchar,
        i_info_values IN table_varchar,
        i_labels      IN table_varchar,
        io_tab_hist   IN OUT t_table_history_data,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_labels      table_varchar := table_varchar();
        l_values      table_varchar := table_varchar();
        l_types       table_varchar := table_varchar();
        l_label_codes table_varchar := table_varchar();
    BEGIN
        IF (i_actual_row.id_prof_comp IS NOT NULL)
        THEN
            --title
            pk_inp_detail.add_3_values(io_table_1 => l_labels,
                                       i_value_1  => pk_sysdomain.get_domain(i_code_dom => g_sd_transfer_status_det_desc,
                                                                             i_val      => pk_hand_off.g_hand_off_f,
                                                                             i_lang     => i_lang),
                                       io_table_2 => l_values,
                                       i_value_2  => NULL,
                                       io_table_3 => l_types,
                                       i_value_3  => g_title_t);
        
            --set status change
            pk_inp_detail.add_3_values(io_table_1 => l_labels,
                                       i_value_1  => i_labels(1),
                                       io_table_2 => l_values,
                                       i_value_2  => pk_sysdomain.get_domain(i_code_dom => g_sd_transfer_status,
                                                                             i_val      => pk_hand_off.g_hand_off_f,
                                                                             i_lang     => i_lang),
                                       io_table_3 => l_types,
                                       i_value_3  => g_new_content_n);
        
            --status               
            pk_inp_detail.add_3_values(io_table_1 => l_labels,
                                       i_value_1  => i_labels(2),
                                       io_table_2 => l_values,
                                       i_value_2  => pk_sysdomain.get_domain(i_code_dom => g_sd_transfer_status,
                                                                             i_val      => pk_hand_off.g_hand_off_r,
                                                                             i_lang     => i_lang),
                                       io_table_3 => l_types,
                                       i_value_3  => g_content_c);
        
            l_label_codes.extend(5);
            l_label_codes(1) := 'TRANSFER_M016'; --deferring prof
            l_label_codes(2) := 'TRANSFER_M017'; --date
            l_label_codes(3) := 'TRANSFER_M015'; --answer
            l_label_codes(4) := 'TRANSFER_M012'; --bed
            l_label_codes(5) := 'TRANSFER_M013'; --room
        
            g_error := 'CALL get_accepted_fields';
            pk_alertlog.log_debug(g_error);
            IF NOT get_accepted_fields(i_lang         => i_lang,
                                       i_prof         => i_prof,
                                       i_flg_screen   => g_history_h,
                                       i_actual_row   => i_actual_row,
                                       i_label_codes  => l_label_codes,
                                       i_content_type => g_new_content_n,
                                       io_tbl_labels  => l_labels,
                                       io_tbl_values  => l_values,
                                       io_tbl_types   => l_types,
                                       o_error        => o_error)
            THEN
                RAISE g_exception;
            END IF;
        
            --signature
            pk_inp_detail.add_3_values(io_table_1 => l_labels,
                                       i_value_1  => NULL,
                                       io_table_2 => l_values,
                                       i_value_2  => get_signature(i_lang                => i_lang,
                                                                   i_prof                => i_prof,
                                                                   i_id_episode          => i_actual_row.id_episode,
                                                                   i_date                => i_actual_row.dt_trf_accepted_tstz,
                                                                   i_id_prof_last_change => i_actual_row.id_prof_comp),
                                       io_table_3 => l_types,
                                       i_value_3  => g_signature_s);
        
            io_tab_hist.extend;
            io_tab_hist(io_tab_hist.count) := t_rec_history_data(id_rec          => i_actual_row.id_epis_prof_resp,
                                                                 flg_status      => i_actual_row.flg_status,
                                                                 date_rec        => NULL,
                                                                 tbl_labels      => l_labels,
                                                                 tbl_values      => l_values,
                                                                 tbl_types       => l_types,
                                                                 tbl_info_labels => i_info_labels,
                                                                 tbl_info_values => i_info_values,
                                                                 table_origin    => NULL);
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_ACCEPTED_HIST',
                                              o_error    => o_error);
            RETURN FALSE;
    END get_accepted_hist;

    /********************************************************************************************
    * Get the fields data to be shown in the history screen related with the decline step.
    * To be used on detail and history
    *
    * @param   I_LANG                      language associated to the professional executing the request
    * @param   i_prof                      professional
    * @param   i_actual_row                Service tranfer data                                                         
    * @param   i_info_labels               info label used in flash to addicional formatting  
    * @param   i_info_values               info values used in flash to addicional formatting
    * @param   i_labels                    common labels
    * @param   io_tab_hist                 Structure with all the detail/history data
    * @param   o_error                     Error message
    *                        
    * @return  true or false on success or error
    * 
    * @author                         Sofia Mendes
    * @version                        2.6.0.4
    * @since                          28-Mar-2011
    **********************************************************************************************/
    FUNCTION get_declined_hist
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_actual_row  IN epis_prof_resp%ROWTYPE,
        i_info_labels IN table_varchar,
        i_info_values IN table_varchar,
        i_labels      IN table_varchar,
        io_tab_hist   IN OUT t_table_history_data,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_labels      table_varchar := table_varchar();
        l_values      table_varchar := table_varchar();
        l_types       table_varchar := table_varchar();
        l_label_codes table_varchar := table_varchar();
    BEGIN
        IF (i_actual_row.id_prof_decline IS NOT NULL)
        THEN
            --title
            pk_inp_detail.add_3_values(io_table_1 => l_labels,
                                       i_value_1  => pk_sysdomain.get_domain(i_code_dom => g_sd_transfer_status_det_desc,
                                                                             i_val      => pk_hand_off.g_hand_off_d,
                                                                             i_lang     => i_lang),
                                       io_table_2 => l_values,
                                       i_value_2  => NULL,
                                       io_table_3 => l_types,
                                       i_value_3  => g_title_t);
        
            --set status change
            pk_inp_detail.add_3_values(io_table_1 => l_labels,
                                       i_value_1  => i_labels(1),
                                       io_table_2 => l_values,
                                       i_value_2  => pk_sysdomain.get_domain(i_code_dom => g_sd_transfer_status,
                                                                             i_val      => pk_hand_off.g_hand_off_d,
                                                                             i_lang     => i_lang),
                                       io_table_3 => l_types,
                                       i_value_3  => g_new_content_n);
        
            --status               
            pk_inp_detail.add_3_values(io_table_1 => l_labels,
                                       i_value_1  => i_labels(2),
                                       io_table_2 => l_values,
                                       i_value_2  => pk_sysdomain.get_domain(i_code_dom => g_sd_transfer_status,
                                                                             i_val      => pk_hand_off.g_hand_off_r,
                                                                             i_lang     => i_lang),
                                       io_table_3 => l_types,
                                       i_value_3  => g_content_c);
        
            l_label_codes.extend(3);
            l_label_codes(1) := 'TRANSFER_M019'; --declining prof 
            l_label_codes(2) := 'TRANSFER_M018'; --date
            l_label_codes(3) := 'TRANSFER_M015'; --answer        
        
            g_error := 'CALL get_declined_fields';
            pk_alertlog.log_debug(g_error);
            IF NOT get_declined_fields(i_lang         => i_lang,
                                       i_prof         => i_prof,
                                       i_flg_screen   => g_history_h,
                                       i_actual_row   => i_actual_row,
                                       i_label_codes  => l_label_codes,
                                       i_content_type => g_new_content_n,
                                       io_tbl_labels  => l_labels,
                                       io_tbl_values  => l_values,
                                       io_tbl_types   => l_types,
                                       o_error        => o_error)
            THEN
                RAISE g_exception;
            END IF;
        
            --signature
            pk_inp_detail.add_3_values(io_table_1 => l_labels,
                                       i_value_1  => NULL,
                                       io_table_2 => l_values,
                                       i_value_2  => get_signature(i_lang                => i_lang,
                                                                   i_prof                => i_prof,
                                                                   i_id_episode          => i_actual_row.id_episode,
                                                                   i_date                => i_actual_row.dt_decline_tstz,
                                                                   i_id_prof_last_change => i_actual_row.id_prof_decline),
                                       io_table_3 => l_types,
                                       i_value_3  => g_signature_s);
        
            io_tab_hist.extend;
            io_tab_hist(io_tab_hist.count) := t_rec_history_data(id_rec          => i_actual_row.id_epis_prof_resp,
                                                                 flg_status      => i_actual_row.flg_status,
                                                                 date_rec        => NULL,
                                                                 tbl_labels      => l_labels,
                                                                 tbl_values      => l_values,
                                                                 tbl_types       => l_types,
                                                                 tbl_info_labels => i_info_labels,
                                                                 tbl_info_values => i_info_values,
                                                                 table_origin    => NULL);
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_DECLINED_HIST',
                                              o_error    => o_error);
            RETURN FALSE;
    END get_declined_hist;

    /********************************************************************************************
    * Get the fields data to be shown in the history screen related with the difference between the 
    * different steps performed by the user.
    *
    * @param   I_LANG                      language associated to the professional executing the request
    * @param   i_prof                      professional
    * @param   i_actual_row                Service tranfer data                                                         
    * @param   i_info_labels               info label used in flash to addicional formatting  
    * @param   i_info_values               info values used in flash to addicional formatting
    * @param   i_labels                    common labels
    * @param   io_tab_hist                 Structure with all the detail/history data
    * @param   o_error                     Error message
    *                        
    * @return  true or false on success or error
    * 
    * @author                         Sofia Mendes
    * @version                        2.6.0.4
    * @since                          28-Mar-2011
    **********************************************************************************************/
    FUNCTION get_values
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_actual_row  IN epis_prof_resp%ROWTYPE,
        i_info_labels IN table_varchar,
        i_info_values IN table_varchar,
        i_labels      IN table_varchar,
        io_tab_hist   IN OUT t_table_history_data,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'CALL get_cancel_status_hist';
        pk_alertlog.log_debug(g_error);
        IF NOT get_cancellation_hist(i_lang        => i_lang,
                                     i_prof        => i_prof,
                                     i_actual_row  => i_actual_row,
                                     i_labels      => i_labels,
                                     i_info_labels => i_info_labels,
                                     io_tab_hist   => io_tab_hist,
                                     o_error       => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        g_error := 'CALL get_execution_hist';
        pk_alertlog.log_debug(g_error);
        IF NOT get_finalize_hist(i_lang        => i_lang,
                                 i_prof        => i_prof,
                                 i_actual_row  => i_actual_row,
                                 i_info_labels => i_info_labels,
                                 i_info_values => i_info_values,
                                 i_labels      => i_labels,
                                 io_tab_hist   => io_tab_hist,
                                 o_error       => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        g_error := 'CALL get_in_transit_hist';
        pk_alertlog.log_debug(g_error);
        IF NOT get_in_transit_hist(i_lang        => i_lang,
                                   i_prof        => i_prof,
                                   i_actual_row  => i_actual_row,
                                   i_info_labels => i_info_labels,
                                   i_info_values => i_info_values,
                                   i_labels      => i_labels,
                                   io_tab_hist   => io_tab_hist,
                                   o_error       => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        g_error := 'CALL get_accepted_hist';
        pk_alertlog.log_debug(g_error);
        IF NOT get_accepted_hist(i_lang        => i_lang,
                                 i_prof        => i_prof,
                                 i_actual_row  => i_actual_row,
                                 i_info_labels => i_info_labels,
                                 i_info_values => i_info_values,
                                 i_labels      => i_labels,
                                 io_tab_hist   => io_tab_hist,
                                 o_error       => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        g_error := 'CALL get_declined_hist';
        pk_alertlog.log_debug(g_error);
        IF NOT get_declined_hist(i_lang        => i_lang,
                                 i_prof        => i_prof,
                                 i_actual_row  => i_actual_row,
                                 i_info_labels => i_info_labels,
                                 i_info_values => i_info_values,
                                 i_labels      => i_labels,
                                 io_tab_hist   => io_tab_hist,
                                 o_error       => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_VALUES',
                                              o_error    => o_error);
            RETURN FALSE;
    END get_values;

    /********************************************************************************************
    * Get the transfer service detail and history data.
    *
    * @param   I_LANG                      language associated to the professional executing the request
    * @param   i_prof                      professional
    * @param   o_labels                    common labels list   
    * @param   o_error                     Error message
    *                        
    * @return  true or false on success or error
    * 
    * @author                         Sofia Mendes
    * @version                        2.6.0.4
    * @since                          28-Mar-2011
    **********************************************************************************************/
    FUNCTION get_common_labels
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        o_labels OUT table_varchar,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        o_labels := table_varchar();
    
        o_labels.extend(2);
        o_labels(1) /* l_desc_new_status*/
        := pk_message.get_message(i_lang, 'TRANSFER_M005');
        o_labels(2) /*l_desc_status*/
        := pk_message.get_message(i_lang, 'TRANSFER_M004');
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_COMMON_LABELS',
                                              o_error    => o_error);
            RETURN FALSE;
    END get_common_labels;

    /********************************************************************************************
    * Get the transfer service detail and history data.
    *
    * @param   I_LANG                      language associated to the professional executing the request
    * @param   i_prof                      professional
    * @param   i_id_epis_prof_resp         service transfer identifier
    * @param   i_flg_screen                D-detail; H-history    
    * @param   o_data                      Output data    
    * @param   o_error                     Error message
    *                        
    * @return  true or false on success or error
    * 
    * @author                         Sofia Mendes
    * @version                        2.6.0.4
    * @since                          28-Mar-2011
    **********************************************************************************************/
    FUNCTION get_serv_trans_det_hist
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_epis_prof_resp IN table_number,
        i_flg_screen        IN VARCHAR2,
        o_data              OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(30) := 'GET_SERV_TRANS_DET_HIST';
        --
        TYPE t_epis_prof_resp IS TABLE OF epis_prof_resp%ROWTYPE;
        l_serv_trans_data t_epis_prof_resp;
    
        l_tab_hist t_table_history_data := t_table_history_data();
    
        l_tbl_lables table_varchar := table_varchar();
        l_tbl_values table_varchar := table_varchar();
        l_tbl_types  table_varchar := table_varchar();
    
        l_info_labels table_varchar;
        l_info_values table_varchar;
    
        l_labels table_varchar := table_varchar();
    
        FUNCTION get_info_labels RETURN table_varchar IS
            l_table table_varchar := table_varchar();
        BEGIN
            --RECORD_STATE
            pk_inp_detail.add_value(io_table => l_table, i_value => 'RECORD_STATE_TO_FORMAT');
        
            RETURN l_table;
        END get_info_labels;
    
        FUNCTION get_info_values(i_row_flg_status IN epis_prof_resp.flg_status%TYPE) RETURN table_varchar IS
            l_table table_varchar := table_varchar();
        BEGIN
            --RECORD_STATE
            pk_inp_detail.add_value(io_table => l_table,
                                    i_value  => CASE
                                                    WHEN i_row_flg_status = pk_hand_off.g_hand_off_c THEN
                                                     pk_hand_off.g_hand_off_c
                                                    ELSE
                                                     'A'
                                                END);
        
            RETURN l_table;
        END get_info_values;
    BEGIN
        g_error := 'CALL get_common_labels';
        pk_alertlog.log_debug(g_error);
        IF NOT get_common_labels(i_lang => i_lang, i_prof => i_prof, o_labels => l_labels, o_error => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        g_error := 'CALL data. i_id_epis_prof_resp: ';
        pk_alertlog.log_debug(g_error);
        SELECT *
          BULK COLLECT
          INTO l_serv_trans_data
          FROM epis_prof_resp epr
         WHERE epr.id_epis_prof_resp IN (SELECT *
                                           FROM TABLE(i_id_epis_prof_resp));
    
        l_info_labels := get_info_labels();
    
        FOR i IN 1 .. l_serv_trans_data.count
        LOOP
            IF (i_flg_screen = g_history_h)
            THEN
                --as there is not history, it is not possible to check the status for each operation step
                --we have it always active and we update it in the last history record to inactive if the record is actually cancelled
                l_info_values := table_varchar('A');
            
                g_error := 'CALL get_values';
                pk_alertlog.log_debug(g_error);
                IF NOT get_values(i_lang        => i_lang,
                                  i_prof        => i_prof,
                                  i_actual_row  => l_serv_trans_data(i),
                                  i_info_labels => l_info_labels,
                                  i_info_values => l_info_values,
                                  i_labels      => l_labels,
                                  io_tab_hist   => l_tab_hist,
                                  o_error       => o_error)
                THEN
                    RETURN FALSE;
                END IF;
            ELSE
                l_info_values := get_info_values(l_serv_trans_data(i).flg_status);
            END IF;
        
            g_error := 'CALL get_first_values';
            pk_alertlog.log_debug(g_error);
            IF NOT get_first_values(i_lang       => i_lang,
                                    i_prof       => i_prof,
                                    i_actual_row => l_serv_trans_data(i),
                                    i_flg_screen => i_flg_screen,
                                    o_tbl_labels => l_tbl_lables,
                                    o_tbl_values => l_tbl_values,
                                    o_tbl_types  => l_tbl_types,
                                    o_error      => o_error)
            THEN
                RETURN FALSE;
            END IF;
        
            l_tab_hist.extend;
            l_tab_hist(l_tab_hist.count) := t_rec_history_data(id_rec          => l_serv_trans_data(i).id_epis_prof_resp,
                                                               flg_status      => l_serv_trans_data(i).flg_status,
                                                               date_rec        => NULL,
                                                               tbl_labels      => l_tbl_lables,
                                                               tbl_values      => l_tbl_values,
                                                               tbl_types       => l_tbl_types,
                                                               tbl_info_labels => l_info_labels,
                                                               tbl_info_values => l_info_values,
                                                               table_origin    => NULL);
        
        END LOOP;
    
        g_error := 'OPEN o_data';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
        OPEN o_data FOR
            SELECT t.id_rec          id_epis_prof_resp,
                   t.tbl_labels      tbl_labels,
                   t.tbl_values      tbl_values,
                   t.tbl_types       tbl_types,
                   t.tbl_info_labels info_labels,
                   t.tbl_info_values info_values
              FROM TABLE(l_tab_hist) t;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.reset_error_state;
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_data);
            RETURN FALSE;
    END get_serv_trans_det_hist;

    /******************************************************************************
    NAME: GET_TRANSFER_DETAIL
    CREATION INFO: CARLOS FERREIRA 2007/01/31
    GOAL: RETURNS A LIST OF TRANSFERS FOR DESTINATION SERVICE
    NOTAS:
    
    PARAMETERS:
    -------------------------------------------------------------------------------
    | PARAMETER NAME   |   DATATYPE             | I/O |      DESCRIPTION          |
    -------------------------------------------------------------------------------
    -------------------------------------------------------------------------------
    *********************************************************************************/
    FUNCTION get_transfer_detail
    (
        i_lang              IN NUMBER,
        i_area              IN VARCHAR2, --- A, B,C
        i_prof              IN profissional,
        i_id_epis_prof_resp IN NUMBER,
        o_title             OUT pk_types.cursor_type,
        o_data              OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name    VARCHAR2(32) := 'GET_TRANSFER_DETAIL';
        l_flg_decline  VARCHAR2(0050);
        l_flg_request  VARCHAR2(0050);
        l_flg_accept   VARCHAR2(0050);
        l_flg_cancel   VARCHAR2(0050);
        l_flg_executed VARCHAR2(0050);
    BEGIN
        l_flg_decline  := 'D';
        l_flg_request  := 'R';
        l_flg_accept   := 'F';
        l_flg_cancel   := 'C';
        l_flg_executed := 'X';
        OPEN o_title FOR
            SELECT l_flg_request flg_status,
                   pk_message.get_message(i_lang, 'TRANSFER_T017') label_a, -- serviço de origem
                   pk_message.get_message(i_lang, 'TRANSFER_T018') label_b, -- serviço de destino
                   pk_message.get_message(i_lang, 'TRANSFER_T047') label_c, -- especialidade de origem
                   pk_message.get_message(i_lang, 'TRANSFER_T048') label_d, -- especialidade de destino
                   pk_message.get_message(i_lang, 'TRANSFER_T019') label_e, -- motivo
                   pk_message.get_message(i_lang, 'TRANSFER_T021') label_f, -- Autor da requisição
                   pk_message.get_message(i_lang, 'TRANSFER_T022') label_g, -- DATA da requisição
                   NULL label_h,
                   NULL label_i,
                   --PK_MESSAGE.GET_MESSAGE(I_LANG, 'TRANSFER_T023')     LABEL_E   -- Notas da requisição
                   NULL label_j,
                   NULL label_k
              FROM epis_prof_resp   epr,
                   department       dpo,
                   department       dpd,
                   clinical_service cso,
                   clinical_service csd,
                   professional     prf
             WHERE epr.id_epis_prof_resp = i_id_epis_prof_resp
               AND epr.id_department_orig = dpo.id_department(+)
               AND epr.id_department_dest = dpd.id_department(+)
               AND epr.id_clinical_service_orig = cso.id_clinical_service(+)
               AND epr.id_clinical_service_dest = csd.id_clinical_service(+)
               AND epr.id_prof_req = prf.id_professional
            UNION ALL
            SELECT l_flg_accept flg_status,
                   pk_message.get_message(i_lang, 'TRANSFER_T024') label_a, -- autor da deferencia
                   pk_message.get_message(i_lang, 'TRANSFER_T025') label_b, -- data da deferencia
                   pk_message.get_message(i_lang, 'TRANSFER_T026') label_c, -- resposta
                   pk_message.get_message(i_lang, 'TRANSFER_T042') label_d, -- cama
                   pk_message.get_message(i_lang, 'TRANSFER_T043') label_e, -- sala
                   NULL label_f, --
                   NULL label_g, --
                   NULL label_h, --
                   NULL label_i,
                   NULL label_j,
                   NULL label_k
              FROM epis_prof_resp epr, professional prf
             WHERE epr.id_epis_prof_resp = i_id_epis_prof_resp
               AND epr.id_prof_comp = prf.id_professional
            UNION ALL
            SELECT l_flg_decline flg_status,
                   pk_message.get_message(i_lang, 'TRANSFER_T032') label_a, -- autor
                   pk_message.get_message(i_lang, 'TRANSFER_T026') label_a, -- resposta
                   pk_message.get_message(i_lang, 'TRANSFER_T035') label_c, --
                   NULL label_d, --
                   NULL label_e, --
                   NULL label_f, --
                   NULL label_g,
                   NULL label_h,
                   NULL label_i,
                   NULL label_j,
                   NULL label_k
              FROM epis_prof_resp epr, professional prf
             WHERE epr.id_epis_prof_resp = i_id_epis_prof_resp
               AND epr.id_prof_decline = prf.id_professional
            UNION ALL
            SELECT l_flg_cancel flg_status,
                   pk_message.get_message(i_lang, 'TRANSFER_T033') label_a, -- --autor
                   pk_message.get_message(i_lang, 'TRANSFER_T055') label_a, -- mensagem
                   pk_message.get_message(i_lang, 'TRANSFER_T034') label_a, -- DATA DE CANCELAMENTO
                   NULL label_d, --
                   NULL label_e, --
                   NULL label_f, --
                   NULL label_g,
                   NULL label_h,
                   NULL label_i,
                   NULL label_j,
                   NULL label_k
              FROM epis_prof_resp epr, professional prf
             WHERE epr.id_epis_prof_resp = i_id_epis_prof_resp
               AND epr.id_prof_cancel = prf.id_professional
            UNION ALL
            SELECT l_flg_executed flg_status,
                   pk_message.get_message(i_lang, 'TRANSFER_T027') label_a, -- autor da TRANSFERENICA
                   pk_message.get_message(i_lang, 'TRANSFER_T028') label_b, -- data de transferencia
                   pk_message.get_message(i_lang, 'TRANSFER_T029') label_c, -- transporte
                   pk_message.get_message(i_lang, 'TRANSFER_T030') label_d, -- maio de transporte
                   pk_message.get_message(i_lang, 'TRANSFER_T031') label_e, -- notas de transporte
                   pk_message.get_message(i_lang, 'TRANSFER_T042') label_f, -- cama
                   pk_message.get_message(i_lang, 'TRANSFER_T043') label_g, -- sala
                   pk_message.get_message(i_lang, 'TRANSFER_T045') label_h, -- necessita de acompanhante
                   NULL label_i, --
                   NULL label_j,
                   NULL label_k
              FROM epis_prof_resp epr, movement mov, necessity nec, professional prf
             WHERE epr.id_epis_prof_resp = i_id_epis_prof_resp
               AND epr.id_prof_execute = prf.id_professional
               AND epr.id_movement = mov.id_movement(+)
               AND mov.id_necessity = nec.id_necessity(+);
    
        --
        OPEN o_data FOR
            SELECT l_flg_request flg_status,
                   pk_translation.get_translation(i_lang, dpo.code_department) label_a, -- serviço de origem
                   pk_translation.get_translation(i_lang, dpd.code_department) label_b, -- serviço de destino
                   pk_translation.get_translation(i_lang, cso.code_clinical_service) label_c, -- especialidade de origem
                   pk_translation.get_translation(i_lang, csd.code_clinical_service) label_d, -- especialidade de destino
                   epr.trf_reason label_e, -- motivo
                   pk_prof_utils.get_name_signature(i_lang, i_prof, prf.id_professional) label_f, -- autor da deferencia
                   pk_prof_utils.get_spec_signature(i_lang, i_prof, i_prof.id, epr.dt_request_tstz, epr.id_episode) prof_spec,
                   pk_date_utils.date_char_tsz(i_lang, epr.dt_request_tstz, i_prof.institution, i_prof.software) label_g, -- DATA REQUISICAO
                   NULL label_h,
                   NULL label_i, -- Notas da requisição
                   NULL label_j,
                   NULL label_k,
                   pk_sysdomain.get_domain(g_sd_patient_consent, epr.flg_patient_consent, i_lang) label_l
              FROM epis_prof_resp   epr,
                   department       dpo,
                   department       dpd,
                   clinical_service cso,
                   clinical_service csd,
                   professional     prf,
                   professional     prf1
             WHERE epr.id_epis_prof_resp = i_id_epis_prof_resp
               AND epr.id_department_orig = dpo.id_department(+)
               AND epr.id_department_dest = dpd.id_department(+)
               AND epr.id_clinical_service_orig = cso.id_clinical_service(+)
               AND epr.id_clinical_service_dest = csd.id_clinical_service(+)
               AND epr.id_prof_req = prf.id_professional
               AND epr.id_prof_to = prf1.id_professional(+)
            -- *****************************************************************************
            UNION ALL
            SELECT l_flg_accept flg_status,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, prf.id_professional) label_a, -- autor da deferencia
                   pk_date_utils.date_char_tsz(i_lang, epr.dt_trf_accepted_tstz, i_prof.institution, i_prof.software) label_b, -- data da deferencia
                   epr.trf_answer label_c, -- resposta
                   nvl(bd.desc_bed, pk_translation.get_translation(i_lang, bd.code_bed)) label_d, -- cama
                   nvl(ro.desc_room, pk_translation.get_translation(i_lang, ro.code_room)) label_e, --sala
                   NULL label_f, --
                   pk_prof_utils.get_spec_signature(i_lang, i_prof, i_prof.id, epr.dt_trf_accepted_tstz, epr.id_episode) prof_spec,
                   NULL label_g, --
                   NULL label_h,
                   NULL label_i,
                   NULL label_j,
                   NULL label_k,
                   pk_sysdomain.get_domain(g_sd_patient_consent, epr.flg_patient_consent, i_lang) label_l
              FROM epis_prof_resp epr, professional prf, bed bd, room ro
             WHERE epr.id_epis_prof_resp = i_id_epis_prof_resp
               AND epr.id_prof_comp = prf.id_professional
               AND epr.id_bed = bd.id_bed(+)
               AND epr.id_room = ro.id_room(+)
            -- *****************************************************************************
            UNION ALL
            SELECT l_flg_decline flg_status,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, prf.id_professional) label_a, -- AUTOR DA REJEICAO
                   epr.trf_answer label_b, -- resposta
                   pk_date_utils.date_char_tsz(i_lang, epr.dt_decline_tstz, i_prof.institution, i_prof.software) label_c, -- DATA DE REJEIÇÃO
                   NULL label_d,
                   NULL label_e,
                   NULL label_f,
                   pk_prof_utils.get_spec_signature(i_lang, i_prof, i_prof.id, epr.dt_decline_tstz, epr.id_episode) prof_spec,
                   NULL label_g,
                   NULL label_h,
                   NULL label_i,
                   NULL label_j,
                   NULL label_k,
                   pk_sysdomain.get_domain(g_sd_patient_consent, epr.flg_patient_consent, i_lang) label_l
              FROM epis_prof_resp epr, professional prf
             WHERE epr.id_epis_prof_resp = i_id_epis_prof_resp
               AND epr.id_prof_decline = prf.id_professional
            UNION ALL
            SELECT l_flg_cancel flg_status,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, prf.id_professional) label_a, -- AUTOR
                   epr.notes_cancel label_b, -- MENSAGEM
                   pk_date_utils.date_char_tsz(i_lang, epr.dt_cancel_tstz, i_prof.institution, i_prof.software) label_c, -- DATA DE CANCELAMENTO
                   NULL label_d,
                   NULL label_e,
                   NULL label_f,
                   pk_prof_utils.get_spec_signature(i_lang, i_prof, i_prof.id, epr.dt_cancel_tstz, epr.id_episode) prof_spec,
                   NULL label_g,
                   NULL label_h,
                   NULL label_i,
                   NULL label_j,
                   NULL label_k,
                   pk_sysdomain.get_domain(g_sd_patient_consent, epr.flg_patient_consent, i_lang) label_l
              FROM epis_prof_resp epr, professional prf
             WHERE epr.id_epis_prof_resp = i_id_epis_prof_resp
               AND epr.id_prof_cancel = prf.id_professional
            -- *****************************************************************************
            UNION ALL
            SELECT l_flg_executed flg_status,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, prf.id_professional) label_a, -- autor da TRANSFERENICA
                   pk_date_utils.date_char_tsz(i_lang, epr.dt_execute_tstz, i_prof.institution, i_prof.software) label_b, -- data de transferencia
                   pk_sysdomain.get_domain('YES_NO', decode(epr.id_movement, NULL, 'N', 'Y'), i_lang) label_c, -- transporte
                   pk_translation.get_translation(i_lang, code_necessity) label_d, -- maio de transporte
                   epr.transport_notes label_e, -- notas de transporte
                   nvl(bd.desc_bed, pk_translation.get_translation(i_lang, bd.code_bed)) label_f, -- cama
                   pk_prof_utils.get_spec_signature(i_lang, i_prof, i_prof.id, epr.dt_execute_tstz, epr.id_episode) prof_spec,
                   nvl(ro.desc_room, pk_translation.get_translation(i_lang, ro.code_room)) label_g, --sala
                   pk_sysdomain.get_domain('YES_NO', nvl(epr.flg_escort, 'N'), i_lang) label_h, -- necessita de acompanhante
                   NULL label_i, -- notas de transporte
                   NULL label_j,
                   NULL label_k,
                   pk_sysdomain.get_domain(g_sd_patient_consent, epr.flg_patient_consent, i_lang) label_l
              FROM epis_prof_resp epr, movement mov, necessity nec, professional prf, bed bd, room ro
             WHERE epr.id_epis_prof_resp = i_id_epis_prof_resp
               AND epr.id_prof_execute = prf.id_professional
               AND epr.id_movement = mov.id_movement(+)
               AND mov.id_necessity = nec.id_necessity(+)
               AND epr.id_bed_execute = bd.id_bed(+)
               AND epr.id_room_execute = ro.id_room(+);
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            pk_types.open_my_cursor(o_title);
            pk_types.open_my_cursor(o_data);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_transfer_detail;

    /***************************************************************************
    * Returns a list of service transfer in a string
    *                                                                         
    * @param i_lang                   Language ID                             
    * @param i_prof                   Profissional ID  
    * @param i_patient                Patient identifier
    * @param i_episode                Episode identifier
    *
    * @return string with transfer service
    *                                                                         
    * @author                         Elisabete Bugalho                         
    * @version                        2.7.1.0                                 
    * @since                          2017/04/20                            
    **************************************************************************/
    FUNCTION get_pat_service_transfer
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        i_episode IN episode.id_episode%TYPE
    ) RETURN VARCHAR2 IS
        l_service    VARCHAR2(4000 CHAR);
        l_flg_accept epis_prof_resp.flg_status%TYPE := 'F';
    BEGIN
    
        SELECT pk_utils.concat_table(CAST(COLLECT(service) AS table_varchar), '; ')
          INTO l_service
          FROM (SELECT pk_translation.get_translation(i_lang, code_department) || g_open_parenthesis ||
                       pk_date_utils.date_char_tsz(i_lang, dt_end_transfer_tstz, i_prof.institution, i_prof.software) ||
                       g_close_parenthesis service
                  FROM (SELECT dpt.code_department,
                               epr.dt_end_transfer_tstz,
                               rank() over(PARTITION BY epr.id_episode ORDER BY epr.dt_request_tstz DESC) AS rn
                          FROM episode epi, epis_prof_resp epr, department dpt -- receiving service       
                         WHERE epi.id_episode = i_episode
                           AND epi.id_episode = epr.id_episode
                           AND (epi.flg_ehr = g_flg_ehr_normal OR epi.flg_ehr = g_flg_ehr_schedule)
                           AND epr.id_department_dest = dpt.id_department(+)
                           AND epr.flg_transf_type = g_flg_transf_s
                           AND epr.flg_status IN (g_hand_off_f, g_hand_off_x)
                        UNION (SELECT code_department, dt_begin_tstz, rn
                                FROM (SELECT dpt.code_department, epi.dt_begin_tstz, 999 rn
                                        FROM episode epi, epis_prof_resp epr, department dpt -- receiving service       
                                       WHERE epi.id_episode = i_episode
                                         AND epi.id_episode = epr.id_episode
                                         AND (epi.flg_ehr = g_flg_ehr_normal OR epi.flg_ehr = g_flg_ehr_schedule)
                                         AND epr.id_department_orig = dpt.id_department(+)
                                         AND epr.flg_transf_type = g_flg_transf_s
                                         AND epr.flg_status IN (g_hand_off_f, g_hand_off_x)
                                       ORDER BY epr.dt_request_tstz ASC)
                               WHERE rownum = 1)
                        UNION
                        SELECT dpt.code_department, epi.dt_begin_tstz, 1 rn
                          FROM episode epi, department dpt -- receiving service       
                         WHERE epi.id_episode = i_episode
                           AND (epi.flg_ehr = g_flg_ehr_normal OR epi.flg_ehr = g_flg_ehr_schedule)
                           AND epi.id_department = dpt.id_department
                           AND NOT EXISTS (SELECT 1
                                  FROM epis_prof_resp epr
                                 WHERE epr.id_episode = epi.id_episode
                                   AND epr.flg_transf_type = g_flg_transf_s
                                   AND epr.flg_status IN (g_hand_off_f, g_hand_off_x)))
                 ORDER BY rn);
    
        RETURN l_service;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_pat_service_transfer;

BEGIN
    -- Log initialization.
    pk_alertlog.log_init(pk_alertlog.who_am_i);
END pk_service_transfer;
/
