/*-- Last Change Revision: $Rev: 2053041 $*/
/*-- Last Change by: $Author: pedro.henriques $*/
/*-- Date of last change: $Date: 2022-12-13 16:11:04 +0000 (ter, 13 dez 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_admission_request IS
    -- Private constants
    g_pck_owner CONSTANT VARCHAR2(5) := 'ALERT';
    g_pck_name  CONSTANT VARCHAR2(30) := 'PK_ADMISSION_REQUEST';

    g_flg_new            CONSTANT VARCHAR2(1) := 'N';
    g_flg_edit           CONSTANT VARCHAR2(1) := 'E';
    g_flg_remove         CONSTANT VARCHAR2(1) := 'R';
    g_grid_date_format   CONSTANT VARCHAR2(20) := 'DATE_FORMAT_M006';
    g_adm_physician      CONSTANT VARCHAR2(1) := 'A';
    g_admission_type_req CONSTANT VARCHAR2(20) := 'A';

    g_prof_flg_type_a CONSTANT VARCHAR2(1) := 'A';
    g_prof_flg_type_d CONSTANT VARCHAR2(1) := 'D';
    g_prof_flg_type_n CONSTANT VARCHAR2(1) := 'N';

    -- Private variables
    g_error VARCHAR2(400);

    -- Private exceptions
    e_call_error EXCEPTION;

    -- Private functions
    /**********************************************************************************************
    * Funtion to list possible physicians to take care of that episode
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids             
    * @param i_dep_clin_serv          dep_clin_serv id
    * @param i_check_prof             boolean to indicate whether we should check the current professional only
    * @param o_list                   array with physicians
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Fábio Oliveira
    * @version                        1.0 
    * @since                          2009/04/25
    **********************************************************************************************/
    FUNCTION get_physicians
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_dep_clin_serv IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_check_prof    IN BOOLEAN,
        o_list          OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        l_check_prof INTEGER;
    BEGIN
        g_error := 'CHECK PROF';
        IF i_check_prof
        THEN
            l_check_prof := 1;
        ELSE
            l_check_prof := 0;
        END IF;
    
        g_error := 'OPEN CURSOR';
        OPEN o_list FOR
        -- lista os profissionais associados a um dep_clin_serv ou à instituição actual se i_dep_clin_serv for null
        -- se l_check_prof for 1 ele só valida a elegibilidade do profissional actual
            SELECT p.id_professional, pk_prof_utils.get_name_signature(i_lang, i_prof, p.id_professional) name_prof
              FROM professional p
             WHERE EXISTS (SELECT 0
                      FROM prof_dep_clin_serv pdcs
                      JOIN prof_institution pi
                        ON (pi.id_professional = pdcs.id_professional)
                      JOIN dep_clin_serv dcs
                        ON (pdcs.id_dep_clin_serv = dcs.id_dep_clin_serv)
                      JOIN department d
                        ON (d.id_department = dcs.id_department AND d.id_institution = pi.id_institution)
                     WHERE (dcs.id_dep_clin_serv = i_dep_clin_serv OR
                           (i_dep_clin_serv IS NULL AND d.id_institution = i_prof.institution))
                       AND pdcs.id_professional = p.id_professional
                       AND pdcs.flg_status = 'S'
                       AND pi.flg_state = pk_alert_constant.g_active
                       AND pk_prof_utils.get_category(i_lang,
                                                      profissional(p.id_professional,
                                                                   pi.id_institution,
                                                                   pk_alert_constant.g_soft_inpatient)) =
                           pk_alert_constant.g_cat_type_doc
                       AND instr(d.flg_type, 'I') > 0)
               AND decode(l_check_prof, 1, p.id_professional, 0) = decode(l_check_prof, 1, i_prof.id, 0)
               AND pk_prof_utils.is_internal_prof(i_lang, i_prof, p.id_professional, i_prof.institution) =
                   pk_alert_constant.g_yes
             ORDER BY name_prof;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_pck_owner,
                                              g_pck_name,
                                              'GET_PHYSICIANS',
                                              o_error);
        
            RETURN FALSE;
    END;

    FUNCTION get_physicians_ds
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_dep_clin_serv IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_check_prof    IN BOOLEAN,
        i_professional  IN professional.id_professional%TYPE,
        i_id_inst_dest  IN department.id_institution%TYPE,
        o_list          OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        l_check_prof INTEGER;
    BEGIN
        g_error := 'CHECK PROF';
        IF i_check_prof
        THEN
            l_check_prof := 1;
        ELSE
            l_check_prof := 0;
        END IF;
    
        g_error := 'OPEN CURSOR';
        OPEN o_list FOR
        -- lista os profissionais associados a um dep_clin_serv ou à instituição actual se i_dep_clin_serv for null
        -- se l_check_prof for 1 ele só valida a elegibilidade do profissional actual
            SELECT z.id_professional,
                   z.name_prof,
                   z.flg_default,
                   xmlelement("ADDITIONAL_INFO", xmlattributes(z.flg_default)).getclobval() addit_info
              FROM (SELECT p.id_professional,
                           pk_prof_utils.get_name_signature(i_lang, i_prof, p.id_professional) name_prof,
                           decode(p.id_professional, i_professional, pk_alert_constant.g_yes, pk_alert_constant.g_no) flg_default
                      FROM professional p
                     WHERE EXISTS (SELECT 0
                              FROM prof_dep_clin_serv pdcs
                              JOIN prof_institution pi
                                ON (pi.id_professional = pdcs.id_professional)
                              JOIN dep_clin_serv dcs
                                ON (pdcs.id_dep_clin_serv = dcs.id_dep_clin_serv)
                              JOIN department d
                                ON (d.id_department = dcs.id_department AND d.id_institution = pi.id_institution)
                             WHERE (dcs.id_dep_clin_serv = i_dep_clin_serv OR
                                   (i_dep_clin_serv IS NULL AND
                                   d.id_institution = nvl(i_id_inst_dest, i_prof.institution)))
                               AND pdcs.id_professional = p.id_professional
                               AND pdcs.flg_status = 'S'
                               AND pi.flg_state = pk_alert_constant.g_active
                               AND (pk_prof_utils.get_prof_sub_category(i_lang,
                                                                        profissional(pdcs.id_professional,
                                                                                     d.id_institution,
                                                                                     i_prof.software)) IS NULL OR
                                   pk_prof_utils.get_prof_sub_category(i_lang,
                                                                        profissional(pdcs.id_professional,
                                                                                     d.id_institution,
                                                                                     i_prof.software)) !=
                                   pk_alert_constant.g_na)
                               AND pk_prof_utils.get_category(i_lang,
                                                              profissional(p.id_professional,
                                                                           pi.id_institution,
                                                                           pk_alert_constant.g_soft_inpatient)) =
                                   pk_alert_constant.g_cat_type_doc
                               AND instr(d.flg_type, 'I') > 0)
                       AND decode(l_check_prof, 1, p.id_professional, 0) = decode(l_check_prof, 1, i_prof.id, 0)
                       AND pk_prof_utils.is_internal_prof(i_lang,
                                                          i_prof,
                                                          p.id_professional,
                                                          nvl(i_id_inst_dest, i_prof.institution)) =
                           pk_alert_constant.g_yes) z
             ORDER BY z.name_prof;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_pck_owner,
                                              g_pck_name,
                                              'GET_PHYSICIANS',
                                              o_error);
        
            RETURN FALSE;
    END;

    /**********************************************************************************************
    * Funtion to check if there is any default location (institution, department and dep_clin_serv) for the parameters entered
    * It also checks professional for his availability to take responsability on the admission
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids             
    * @param i_adm_indication         admission indication id
    * @param i_location               institution to check
    * @param i_ward                   department to check
    * @param o_location               default institution (when i_location is null)
    * @param o_location_desc          default institution description
    * @param o_ward                   default department (when i_ward is null)
    * @param o_ward_desc              default department description
    * @param o_dep_clin_serv          default dep_clin_serv
    * @param o_clin_serv_desc         default dep_clin_serv description
    * @param o_professional           profissional can take responsaibility if not null
    * @param o_prof_desc              profissional name
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Fábio Oliveira
    * @version                        1.0 
    * @since                          2009/04/25
    **********************************************************************************************/
    FUNCTION get_default_locations
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_adm_indication IN adm_indication.id_adm_indication%TYPE,
        i_location       IN institution.id_institution%TYPE DEFAULT NULL,
        i_ward           IN department.id_department%TYPE DEFAULT NULL,
        o_location       OUT institution.id_institution%TYPE,
        o_location_desc  OUT pk_translation.t_desc_translation,
        o_ward           OUT department.id_department%TYPE,
        o_ward_desc      OUT pk_translation.t_desc_translation,
        o_dep_clin_serv  OUT dep_clin_serv.id_dep_clin_serv%TYPE,
        o_clin_serv_desc OUT pk_translation.t_desc_translation,
        o_professional   OUT professional.id_professional%TYPE,
        o_prof_desc      OUT pk_translation.t_desc_translation,
        o_adm_type       OUT admission_type.id_admission_type%TYPE,
        o_adm_type_desc  OUT pk_translation.t_desc_translation,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_num_dcs  INTEGER;
        l_num_dep  INTEGER;
        l_num_inst INTEGER;
        l_num_pref INTEGER;
    
        c_locations pk_types.cursor_type;
    
        c_physician pk_types.cursor_type;
    BEGIN
        g_error := 'OPEN CURSOR';
        OPEN c_locations FOR
            SELECT SUM(decode(aidcs.flg_pref, pk_alert_constant.g_yes, 1, 0)) over(PARTITION BY dcs.id_department) num_pref,
                   dcs.id_dep_clin_serv,
                   pk_translation.get_translation(i_lang,
                                                  'CLINICAL_SERVICE.CODE_CLINICAL_SERVICE.' || dcs.id_clinical_service) clinical_service_desc,
                   COUNT(DISTINCT dcs.id_dep_clin_serv) over() num_dep_clin_serv,
                   d.id_department,
                   pk_translation.get_translation(i_lang, d.code_department) department_desc,
                   COUNT(DISTINCT d.id_department) over() num_department,
                   d.id_institution,
                   (SELECT pk_utils.get_institution_name(i_lang, d.id_institution)
                      FROM dual) institution_desc,
                   COUNT(DISTINCT d.id_institution) over() num_institution,
                   d.id_admission_type,
                   nvl(at.desc_admission_type, pk_translation.get_translation(i_lang, at.code_admission_type)) admission_type_desc
              FROM adm_ind_dep_clin_serv aidcs
              JOIN dep_clin_serv dcs
                ON (dcs.id_dep_clin_serv = aidcs.id_dep_clin_serv)
              JOIN department d
                ON (d.id_department = dcs.id_department)
              LEFT JOIN admission_type at
                ON (d.id_admission_type = at.id_admission_type)
             WHERE aidcs.id_adm_indication = i_adm_indication
               AND aidcs.flg_available = pk_alert_constant.g_yes
               AND d.flg_available = pk_alert_constant.g_yes
               AND d.id_institution = decode(i_location, NULL, d.id_institution, i_location)
               AND d.id_department = decode(i_ward, NULL, d.id_department, i_ward)
             ORDER BY aidcs.flg_pref DESC;
    
        g_error := 'FETCH CURSOR';
        FETCH c_locations
            INTO l_num_pref,
                 o_dep_clin_serv,
                 o_clin_serv_desc,
                 l_num_dcs,
                 o_ward,
                 o_ward_desc,
                 l_num_dep,
                 o_location,
                 o_location_desc,
                 l_num_inst,
                 o_adm_type,
                 o_adm_type_desc;
    
        g_error := 'CHECK DCS COUNT';
        IF (l_num_dcs > 1 AND l_num_pref != 1)
           OR l_num_inst > 1
        THEN
            o_dep_clin_serv  := NULL;
            o_clin_serv_desc := NULL;
        END IF;
    
        g_error := 'CHECK DEP COUNT';
        IF (l_num_dep > 1 AND l_num_pref != 1)
           OR l_num_inst > 1
        THEN
            o_ward          := NULL;
            o_ward_desc     := NULL;
            o_adm_type      := NULL;
            o_adm_type_desc := NULL;
        END IF;
    
        g_error := 'CHECK INST COUNT';
        IF l_num_inst > 1
        THEN
            o_location      := NULL;
            o_location_desc := NULL;
        END IF;
    
        CLOSE c_locations;
    
        g_error := 'CHECK PROF';
        IF o_dep_clin_serv IS NOT NULL
        THEN
            IF NOT get_physicians(i_lang, i_prof, o_dep_clin_serv, TRUE, c_physician, o_error)
            THEN
                RAISE e_call_error;
            END IF;
            FETCH c_physician
                INTO o_professional, o_prof_desc;
            CLOSE c_physician;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_pck_owner,
                                              g_pck_name,
                                              'GET_DEFAULT_LOCATIONS',
                                              o_error);
        
            RETURN FALSE;
    END;

    /********************************************************************************************
    * Sets or updates a nurse appointment request
    *
    * @param i_lang                       language id
    * @param i_prof                       professional, software and institution ids
    * @param i_patient                    patient to set the request to
    * @param i_episode                    requested admission episode
    * @param i_flg_edit                   record type: A - add, R - remove, E - edit
    * @param i_consult_req                consult_req ID
    * @param i_dep_clin_serv              appointment type
    * @param i_dt_scheduled_str           appointment date
    * @param io_consult_req               new consult_req ID
    * @param o_error                      Error message
    *                    
    * @return                             true or false on success or error
    *
    * @author                             José Silva
    * @version                            1.0   
    * @since                              25-04-2009
    **********************************************************************************************/
    FUNCTION set_nurse_schedule
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_patient          IN patient.id_patient%TYPE,
        i_episode          IN episode.id_episode%TYPE,
        i_flg_edit         IN VARCHAR2,
        i_dep_clin_serv    IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_dt_scheduled_str IN VARCHAR2,
        io_consult_req     IN OUT consult_req.id_consult_req%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_exception        EXCEPTION;
        l_status_exception EXCEPTION;
        l_msg_err_status sys_message.desc_message%TYPE;
        l_error          t_error_out;
    
        l_cons_req_status consult_req.flg_status%TYPE;
        l_nurse_epis_type sys_config.value%TYPE := pk_sysconfig.get_config('NURSE_EPIS_TYPE', i_prof);
    
        FUNCTION set_consult_req
        (
            o_consult_req OUT consult_req.id_consult_req%TYPE,
            o_error       OUT t_error_out
        ) RETURN BOOLEAN IS
        BEGIN
            RETURN pk_consult_req.set_consult_req(i_lang             => i_lang,
                                                  i_episode          => i_episode,
                                                  i_prof_req         => i_prof,
                                                  i_pat              => i_patient,
                                                  i_instit_requests  => NULL,
                                                  i_instit_requested => NULL,
                                                  i_consult_type     => NULL,
                                                  i_clinical_service => NULL,
                                                  i_dt_scheduled_str => i_dt_scheduled_str,
                                                  i_flg_type_date    => pk_alert_constant.g_flg_type_date_f,
                                                  i_notes            => NULL,
                                                  i_dep_clin_serv    => i_dep_clin_serv,
                                                  i_prof_requested   => -1,
                                                  i_prof_cat_type    => pk_alert_constant.g_cat_type_nurse,
                                                  i_id_complaint     => NULL,
                                                  i_commit_data      => pk_alert_constant.g_no,
                                                  i_epis_type        => l_nurse_epis_type,
                                                  i_flg_type         => pk_consult_req.g_flg_type_waitlist,
                                                  o_consult_req      => o_consult_req,
                                                  o_error            => o_error);
        END;
    
    BEGIN
        g_error          := 'GET ERROR MESSAGE';
        l_msg_err_status := pk_message.get_message(i_lang, 'ADM_REQUEST_E001');
        IF i_flg_edit = g_flg_new
        THEN
            g_error := 'SET NEW CONSULT_REQ';
            IF NOT set_consult_req(o_consult_req => io_consult_req, o_error => l_error)
            THEN
                RAISE l_exception;
            END IF;
        ELSIF i_flg_edit IN (g_flg_edit, g_flg_remove)
        THEN
            g_error := 'EDIT OR REMOVE CONSULT REQ';
            BEGIN
                -- g_error := 'GET CONSULT_REQ STATUS';
                SELECT cr.flg_status
                  INTO l_cons_req_status
                  FROM consult_req cr
                 WHERE cr.id_consult_req = io_consult_req;
            EXCEPTION
                WHEN OTHERS THEN
                    RAISE l_status_exception;
            END;
        
            g_error := 'CHECK CONSULT_REQ STATUS';
            IF l_cons_req_status = pk_consult_req.g_consult_req_stat_proc
            THEN
                RAISE l_status_exception;
            END IF;
        
            IF l_cons_req_status = pk_consult_req.g_consult_req_stat_cancel
            THEN
                RETURN TRUE;
            END IF;
        
            g_error := 'CANCEL CONSULT_REQ';
            IF NOT pk_consult_req.cancel_consult_req_noprofcheck(i_lang         => i_lang,
                                                                 i_consult_req  => io_consult_req,
                                                                 i_prof_cancel  => i_prof,
                                                                 i_notes_cancel => NULL,
                                                                 i_commit_data  => pk_alert_constant.g_no,
                                                                 o_error        => l_error)
            THEN
                RAISE l_exception;
            END IF;
        
            IF i_flg_edit = g_flg_edit
            THEN
                --SM:
                io_consult_req := NULL;
                --
                g_error := 'EDIT CONSULT_REQ';
                IF NOT set_consult_req(o_consult_req => io_consult_req, o_error => l_error)
                THEN
                    RAISE l_exception;
                END IF;
            END IF;
        
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_status_exception THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
            
                l_error_in.set_all(i_lang,
                                   'ADM_REQUEST_E001',
                                   l_msg_err_status,
                                   '',
                                   g_pck_owner,
                                   g_pck_name,
                                   'SET_NURSE_SCHEDULE',
                                   NULL,
                                   'D');
            
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
                pk_utils.undo_changes;
                RETURN FALSE;
            END;
        WHEN l_exception THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error || ' / ' || l_error.err_desc,
                                              g_pck_owner,
                                              g_pck_name,
                                              'SET_NURSE_SCHEDULE',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_pck_owner,
                                              g_pck_name,
                                              'SET_NURSE_SCHEDULE',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_nurse_schedule;

    /**********************************************************************************************
    * Checks two records and compare them
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids             
    * @param i_adm_req         adm_request record
    * @param i_adm_req_old               adm_request record to check against
    *
    * @return                         TRUE if equal, FALSE otherwise
    *                        
    * @author                         Fábio Oliveira
    * @version                        1.0 
    * @since                          2009/04/25
    **********************************************************************************************/
    FUNCTION check_changes
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_adm_req     IN adm_request%ROWTYPE,
        i_adm_req_old IN adm_request%ROWTYPE
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'COMPARISON';
        IF nvl(to_char(i_adm_req.id_adm_indication), 'null') = nvl(to_char(i_adm_req_old.id_adm_indication), 'null')
           AND nvl(to_char(i_adm_req.id_dest_episode), 'null') = nvl(to_char(i_adm_req_old.id_dest_episode), 'null')
           AND nvl(to_char(i_adm_req.id_dest_prof), 'null') = nvl(to_char(i_adm_req_old.id_dest_prof), 'null')
           AND nvl(to_char(i_adm_req.id_dest_inst), 'null') = nvl(to_char(i_adm_req_old.id_dest_inst), 'null')
           AND nvl(to_char(i_adm_req.id_department), 'null') = nvl(to_char(i_adm_req_old.id_department), 'null')
           AND nvl(to_char(i_adm_req.id_dep_clin_serv), 'null') = nvl(to_char(i_adm_req_old.id_dep_clin_serv), 'null')
           AND nvl(to_char(i_adm_req.id_room_type), 'null') = nvl(to_char(i_adm_req_old.id_room_type), 'null')
           AND nvl(to_char(i_adm_req.id_pref_room), 'null') = nvl(to_char(i_adm_req_old.id_pref_room), 'null')
           AND
           nvl(to_char(i_adm_req.id_admission_type), 'null') = nvl(to_char(i_adm_req_old.id_admission_type), 'null')
           AND
           nvl(to_char(i_adm_req.expected_duration), 'null') = nvl(to_char(i_adm_req_old.expected_duration), 'null')
           AND
           nvl(to_char(i_adm_req.id_adm_preparation), 'null') = nvl(to_char(i_adm_req_old.id_adm_preparation), 'null')
           AND
           nvl(to_char(i_adm_req.flg_mixed_nursing), 'null') = nvl(to_char(i_adm_req_old.flg_mixed_nursing), 'null')
           AND nvl(to_char(i_adm_req.id_bed_type), 'null') = nvl(to_char(i_adm_req_old.id_bed_type), 'null')
           AND nvl(to_char(i_adm_req.flg_nit), 'null') = nvl(to_char(i_adm_req_old.flg_nit), 'null')
           AND nvl(to_char(i_adm_req.dt_nit_suggested), 'null') = nvl(to_char(i_adm_req_old.dt_nit_suggested), 'null')
           AND nvl(to_char(i_adm_req.id_nit_dcs), 'null') = nvl(to_char(i_adm_req_old.id_nit_dcs), 'null')
           AND nvl(to_char(i_adm_req.id_nit_req), 'null') = nvl(to_char(i_adm_req_old.id_nit_req), 'null')
           AND nvl(to_char(i_adm_req.notes), 'null') = nvl(to_char(i_adm_req_old.notes), 'null')
           AND nvl(to_char(i_adm_req.flg_status), 'null') = nvl(to_char(i_adm_req_old.flg_status), 'null')
           AND nvl(to_char(i_adm_req.dt_admission), 'null') = nvl(to_char(i_adm_req_old.dt_admission), 'null')
           AND nvl(to_char(i_adm_req.flg_regim), 'null') = nvl(to_char(i_adm_req_old.flg_regim), 'null')
           AND nvl(to_char(i_adm_req.flg_benefi), 'null') = nvl(to_char(i_adm_req_old.flg_benefi), 'null')
           AND nvl(to_char(i_adm_req.flg_contact), 'null') = nvl(to_char(i_adm_req_old.flg_contact), 'null')
           AND nvl(to_char(i_adm_req.flg_precauc), 'null') = nvl(to_char(i_adm_req_old.flg_precauc), 'null')
           AND nvl(to_char(i_adm_req.flg_compulsory), 'null') = nvl(to_char(i_adm_req_old.flg_compulsory), 'null')
           AND nvl(to_char(i_adm_req.id_compulsory_reason), 'null') =
           nvl(to_char(i_adm_req_old.id_compulsory_reason), 'null')
           AND
           nvl(to_char(i_adm_req.compulsory_reason), 'null') = nvl(to_char(i_adm_req_old.compulsory_reason), 'null')
        THEN
            RETURN TRUE;
        ELSE
            RETURN FALSE;
        END IF;
    END;

    /**********************************************************************************************
    * Checks two records and compare them
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids             
    * @param i_flg_status_i           adm_request record
    * @param i_flg_status_f           adm_request record to check against
    *
    * @param o_flg                    Possible values: c-cancel; r-restore; n-new; e-edit. 
    *
    * @return                         TRUE if successful, FALSE otherwise
    *                        
    * @author                         RicardoNunoAlmeida
    * @version                        1.0 
    * @since                          2009/06/09
    ***********************************************************************************************/
    FUNCTION check_hist_status
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_flg_status_i IN adm_request.flg_status%TYPE,
        i_flg_status_f IN adm_request.flg_status%TYPE,
        o_flg          OUT adm_request.flg_status%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        IF i_flg_status_i = pk_alert_constant.g_flg_status_a
           AND i_flg_status_f = pk_alert_constant.g_flg_status_c
        THEN
            o_flg := pk_alert_constant.g_flg_status_c; --cancelamento
        ELSIF i_flg_status_i = pk_alert_constant.g_flg_status_c
              AND i_flg_status_f = pk_alert_constant.g_flg_status_a
        THEN
            o_flg := pk_alert_constant.g_flg_status_r; --restauro
        ELSIF i_flg_status_i IS NULL
              AND i_flg_status_f = pk_alert_constant.g_flg_status_a
        THEN
            o_flg := 'N'; --novo
        ELSE
            o_flg := pk_alert_constant.g_flg_status_e; --edição
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_pck_owner,
                                              g_pck_name,
                                              'CHECK_HIST_STATUS',
                                              o_error);
            RETURN FALSE;
    END check_hist_status;

    -- Same as previous, but this version can be called within SQL queries.
    FUNCTION check_hist_status
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_flg_status_i IN adm_request.flg_status%TYPE,
        i_flg_status_f IN adm_request.flg_status%TYPE
    ) RETURN VARCHAR2 IS
        l_rez   VARCHAR2(1);
        l_error t_error_out;
    BEGIN
        IF NOT check_hist_status(i_lang         => i_lang,
                                 i_prof         => i_prof,
                                 i_flg_status_i => i_flg_status_i,
                                 i_flg_status_f => i_flg_status_f,
                                 o_flg          => l_rez,
                                 o_error        => l_error)
        THEN
            RETURN NULL;
        END IF;
    
        RETURN l_rez;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END check_hist_status;

    FUNCTION get_status
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_adm_request_rec IN adm_request%ROWTYPE,
        i_id_wtl          IN waiting_list.id_waiting_list%TYPE,
        o_flg_status      OUT adm_request.flg_status%TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_wtl_ready VARCHAR2(1);
    BEGIN
    
        IF NOT pk_wtl_prv_core.check_surg_req_mandatory(i_lang      => i_lang,
                                                        i_prof      => i_prof,
                                                        i_id_wtlist => i_id_wtl,
                                                        o_flg_valid => l_wtl_ready,
                                                        o_error     => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        IF i_adm_request_rec.flg_status = pk_alert_constant.g_adm_req_status_canc
        THEN
            g_error      := 'CANCEL';
            o_flg_status := pk_alert_constant.g_adm_req_status_canc;
        ELSIF (i_adm_request_rec.id_dest_inst IS NULL OR i_adm_request_rec.id_department IS NULL OR
              i_adm_request_rec.id_dep_clin_serv IS NULL OR i_adm_request_rec.expected_duration IS NULL OR
              l_wtl_ready = pk_alert_constant.g_no)
        
        THEN
            g_error      := 'PENDING EDIT';
            o_flg_status := pk_alert_constant.g_adm_req_status_pend;
        ELSE
            IF i_adm_request_rec.dt_admission IS NOT NULL
            THEN
                g_error      := 'NO DT_ADMISSION';
                o_flg_status := pk_alert_constant.g_adm_req_status_sche;
            ELSE
                g_error      := 'DT_ADMISSION FILLED';
                o_flg_status := pk_alert_constant.g_adm_req_status_inwa;
            END IF;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_pck_owner,
                                              g_pck_name,
                                              'GET_STATUS',
                                              o_error);
            RETURN FALSE;
    END get_status;

    FUNCTION set_professional
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_waiting_list IN waiting_list.id_waiting_list%TYPE,
        i_episode      IN adm_request.id_dest_episode%TYPE,
        i_adm_prof     IN adm_request.id_dest_prof%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_rows  table_varchar;
        l_count INTEGER;
    BEGIN
        g_error := 'CHECK ACTIVE PROFESSIONAL';
        IF i_adm_prof IS NOT NULL
        THEN
            SELECT COUNT(*)
              INTO l_count
              FROM wtl_prof wp
             WHERE wp.id_episode = i_episode
               AND wp.flg_type = pk_alert_constant.g_wtl_prof_flg_type_a
               AND wp.flg_status = pk_alert_constant.g_active
               AND wp.id_waiting_list = i_waiting_list
               AND wp.id_prof = i_adm_prof;
        
            g_error := 'PROF UPD';
            ts_wtl_prof.upd(flg_status_in => 'O',
                            where_in      => 'id_episode = ' || i_episode || ' AND flg_type = ''' ||
                                             pk_alert_constant.g_wtl_prof_flg_type_a || ''' AND flg_status = ''' ||
                                             pk_alert_constant.g_active || ''' AND id_waiting_list = ' || i_waiting_list ||
                                             ' AND id_prof != ' || i_adm_prof,
                            rows_out      => l_rows);
            g_error := 'WTL_PROF PROCESS UPDATE';
            t_data_gov_mnt.process_update(i_lang, i_prof, 'WTL_PROF', l_rows, o_error, table_varchar('FLG_STATUS'));
        
            l_rows := table_varchar();
        
            IF l_count != 1
            THEN
                g_error := 'INSERT WTL_PROF';
                ts_wtl_prof.ins(id_prof_in         => i_adm_prof,
                                id_waiting_list_in => i_waiting_list,
                                id_episode_in      => i_episode,
                                flg_type_in        => pk_alert_constant.g_wtl_prof_flg_type_a,
                                flg_status_in      => pk_alert_constant.g_active,
                                rows_out           => l_rows);
                g_error := 'WTL_PROF PROCESS INSERT';
                t_data_gov_mnt.process_insert(i_lang, i_prof, 'WTL_PROF', l_rows, o_error);
            END IF;
        ELSE
            ts_wtl_prof.upd(flg_status_in => 'O',
                            where_in      => 'id_episode = ' || i_episode || ' AND flg_type = ''' ||
                                             pk_alert_constant.g_wtl_prof_flg_type_a || ''' AND flg_status = ''' ||
                                             pk_alert_constant.g_active || ''' AND id_waiting_list = ' || i_waiting_list,
                            rows_out      => l_rows);
            t_data_gov_mnt.process_update(i_lang, i_prof, 'WTL_PROF', l_rows, o_error, table_varchar('FLG_STATUS'));
        END IF;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_pck_owner,
                                              g_pck_name,
                                              'SET_PROFESSIONAL',
                                              o_error);
        
            pk_utils.undo_changes;
        
            RETURN FALSE;
    END;

    FUNCTION set_diagnosis
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_diagnosis_adm_req IN pk_edis_types.rec_in_epis_diagnosis,
        i_adm_request       IN adm_request.id_adm_request%TYPE,
        i_episode_inp       IN episode.id_episode%TYPE,
        i_episode_sr        IN episode.id_episode%TYPE,
        i_timestamp         IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_id_cdr_call       IN cdr_call.id_cdr_call%TYPE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        l_id_adm_req_diagnosis table_number;
        l_rows                 table_varchar;
        l_rows_ins             table_varchar;
        l_rows_aux             table_varchar;
        l_prev_id_diagnosis    table_number;
        l_tbl_flg_diag_status  table_varchar;
    
        l_tbl_id_adm_req_diag   table_number;
        l_tbl_adm_req_diagnosis table_varchar;
        l_found                 BOOLEAN;
    
        l_epis_diag_flg_status epis_diagnosis.flg_type%TYPE;
    
        l_id_diagnosis   table_number;
        l_flg_other      diagnosis.flg_other%TYPE;
        l_desc_epis_diag table_varchar;
        l_internal_error EXCEPTION;
    
        l_created_diag      pk_edis_types.table_out_epis_diags;
        l_created_diag_sr   pk_edis_types.table_out_epis_diags;
        l_created_diags     table_number;
        l_tbl_diag          t_table_diagnoses;
        l_diagnosis_adm_req pk_edis_types.rec_in_epis_diagnoses;
    BEGIN
        -- build an object with diagnosis info to be used in queries
        l_tbl_diag := pk_diagnosis.tf_diagnosis(i_rec_epis_diag => i_diagnosis_adm_req);
    
        g_error := 'GET ALL DIAGNOSIS ASSOCIATED TO THE ADM_REQ';
        pk_alertlog.log_debug(g_error);
        SELECT ard.flg_diag_status, ard.id_adm_req_diagnosis, ard.notes, ed.id_diagnosis, ed.desc_epis_diagnosis
          BULK COLLECT
          INTO l_tbl_flg_diag_status,
               l_tbl_id_adm_req_diag,
               l_tbl_adm_req_diagnosis,
               l_prev_id_diagnosis,
               l_desc_epis_diag
          FROM adm_req_diagnosis ard
          JOIN epis_diagnosis ed
            ON ed.id_epis_diagnosis = ard.id_epis_diagnosis
          JOIN (SELECT id_diagnosis, id_alert_diagnosis
                  FROM TABLE(l_tbl_diag)) t
            ON t.id_diagnosis = ed.id_diagnosis
           AND nvl(t.id_alert_diagnosis, -1) = nvl(-1, ed.id_alert_diagnosis)
         WHERE ard.id_adm_request = i_adm_request
           AND ard.flg_status = pk_alert_constant.g_active;
    
        FOR j IN i_diagnosis_adm_req.tbl_diagnosis.first .. i_diagnosis_adm_req.tbl_diagnosis.last
        LOOP
            --Update the diagnosis associations in which some info was changed
            g_error := 'TEST EACH DIAGNOSIS';
            pk_alertlog.log_debug(g_error);
        
            l_found := FALSE;
        
            g_error := 'j: ' || j || ' l_diagnosis_ids(j): ' || i_diagnosis_adm_req.tbl_diagnosis(j).id_diagnosis;
            pk_alertlog.log_debug(g_error);
            IF l_prev_id_diagnosis.exists(1)
            THEN
                FOR i IN l_prev_id_diagnosis.first .. l_prev_id_diagnosis.last
                LOOP
                    g_error := 'i: ' || i || ' l_prev_id_diagnosis: ' || l_prev_id_diagnosis(i) || ' l_diagnosis_ids: ' || i_diagnosis_adm_req.tbl_diagnosis(j).id_diagnosis;
                    pk_alertlog.log_debug(g_error);
                    IF i_diagnosis_adm_req.tbl_diagnosis(j).id_diagnosis = l_prev_id_diagnosis(i)
                    THEN
                        g_error := 'CALL pk_diagnosis.get_diag_flg_other. id_diagnosis: ' || i_diagnosis_adm_req.tbl_diagnosis(j).id_diagnosis;
                        pk_alertlog.log_debug(g_error);
                        IF NOT pk_diagnosis.get_diag_flg_other(i_lang         => i_lang,
                                                               i_prof         => i_prof,
                                                               i_id_diagnosis => i_diagnosis_adm_req.tbl_diagnosis(j).id_diagnosis,
                                                               o_flg_other    => l_flg_other,
                                                               o_error        => o_error)
                        THEN
                            RAISE l_internal_error;
                        END IF;
                        pk_alertlog.log_debug('l_flg_other: ' || l_flg_other || ' i_diag_desc_ar(j): ' || i_diagnosis_adm_req.tbl_diagnosis(j).desc_diagnosis ||
                                              ' l_desc_epis_diag(i): ' || l_desc_epis_diag(i));
                    
                        IF i_diagnosis_adm_req.tbl_diagnosis(j)
                         .flg_status != l_tbl_flg_diag_status(i)
                            OR (i_diagnosis_adm_req.tbl_diagnosis(j).notes != l_tbl_adm_req_diagnosis(i))
                            OR (l_flg_other = pk_alert_constant.g_yes AND i_diagnosis_adm_req.tbl_diagnosis(j)
                                .desc_diagnosis = l_desc_epis_diag(i))
                        THEN
                            g_error := 'CALL ts_adm_req_diagnosis.upd. id_adm_req_diagnosis_in: ' ||
                                       l_tbl_id_adm_req_diag(i);
                            pk_alertlog.log_debug(g_error);
                            /* THERE'S NEW INFO SO WE MAY 'DISABLE' OLD RECORDS */
                            ts_adm_req_diagnosis.upd(id_adm_req_diagnosis_in   => l_tbl_id_adm_req_diag(i),
                                                     flg_status_in             => 'O',
                                                     id_professional_update_in => i_prof.id,
                                                     dt_update_in              => i_timestamp,
                                                     rows_out                  => l_rows);
                        ELSE
                            g_error := 'set lfoud = TRUE';
                            pk_alertlog.log_debug(g_error);
                            l_found := TRUE;
                        END IF;
                    END IF;
                END LOOP;
            END IF;
        
            /* WE WANT TO INSERT NEW RECORDS IF 1) THAT DIAGNOSIS IS NOT ALREADY REGISTERED 2) THAT DIAGNOSIS HAVE DIFFERENT INFO (STATUS OR NOTES) */
            IF NOT l_found
            THEN
                l_created_diag                     := NULL;
                l_diagnosis_adm_req.epis_diagnosis := i_diagnosis_adm_req;
            
                IF i_episode_inp IS NOT NULL
                THEN
                    l_diagnosis_adm_req.epis_diagnosis.id_episode := i_episode_inp;
                END IF;
            
                g_error := 'SEND TO INP EPISODE. i_id_diag: ' || l_diagnosis_adm_req.epis_diagnosis.tbl_diagnosis(j).id_diagnosis ||
                           ' i_diag_status: ' || l_diagnosis_adm_req.epis_diagnosis.tbl_diagnosis(j).desc_diagnosis ||
                           ' i_spec_notes: ' || l_diagnosis_adm_req.epis_diagnosis.tbl_diagnosis(j).notes;
                pk_alertlog.log_debug(g_error);
            
                IF NOT pk_diagnosis.set_epis_diagnosis(i_lang           => i_lang,
                                                       i_prof           => i_prof,
                                                       i_epis_diagnoses => l_diagnosis_adm_req,
                                                       o_params         => l_created_diag,
                                                       o_error          => o_error)
                THEN
                    RETURN FALSE;
                END IF;
            
                IF i_episode_sr IS NOT NULL
                THEN
                
                    l_diagnosis_adm_req.epis_diagnosis.id_episode := i_episode_sr;
                
                    g_error := 'SEND TO SR EPISODE i_episode_sr: ' || i_episode_sr;
                    pk_alertlog.log_debug(g_error);
                
                    IF NOT pk_diagnosis.set_epis_diagnosis(i_lang           => i_lang,
                                                           i_prof           => i_prof,
                                                           i_epis_diagnoses => l_diagnosis_adm_req,
                                                           o_params         => l_created_diag_sr,
                                                           o_error          => o_error)
                    THEN
                        RETURN FALSE;
                    END IF;
                
                END IF;
            
                IF (l_created_diag IS NOT NULL AND l_created_diag.exists(1))
                THEN
                    g_error := 'GET FLG_STATUS id_epis_diagnosis: ' || l_created_diag(j).id_epis_diagnosis;
                    pk_alertlog.log_debug(g_error);
                
                    SELECT ed.flg_status
                      INTO l_epis_diag_flg_status
                      FROM epis_diagnosis ed
                     WHERE ed.id_epis_diagnosis = l_created_diag(j).id_epis_diagnosis;
                
                    ts_adm_req_diagnosis.ins(id_adm_request_in       => i_adm_request,
                                             id_professional_diag_in => i_prof.id,
                                             flg_status_in           => pk_alert_constant.g_active,
                                             flg_diag_status_in      => l_epis_diag_flg_status,
                                             dt_epis_diagnosis_in    => i_timestamp,
                                             notes_in                => i_diagnosis_adm_req.tbl_diagnosis(j).notes,
                                             id_epis_diagnosis_in    => l_created_diag(j).id_epis_diagnosis,
                                             rows_out                => l_rows_aux);
                    l_rows_ins := l_rows_ins MULTISET UNION ALL l_rows_aux;
                END IF;
            END IF;
        END LOOP;
    
        --De-associate the diagnosis that were de-selected
        g_error := 'LOAD ALL PREVIOUS DIAGNOSES i_adm_request: ' || i_adm_request;
        pk_alertlog.log_debug(g_error);
    
        SELECT ard.id_adm_req_diagnosis, ed.id_diagnosis, ed.id_epis_diagnosis
          BULK COLLECT
          INTO l_id_adm_req_diagnosis, l_id_diagnosis, l_created_diags
          FROM adm_req_diagnosis ard
         INNER JOIN epis_diagnosis ed
            ON ed.id_epis_diagnosis = ard.id_epis_diagnosis
         INNER JOIN diagnosis d
            ON d.id_diagnosis = ed.id_diagnosis
         WHERE ard.id_adm_request = i_adm_request
           AND ((ed.id_diagnosis NOT IN (SELECT id_diagnosis
                                           FROM TABLE(l_tbl_diag)) AND (nvl(d.flg_other, 'X') = 'N')) OR
               ((ed.desc_epis_diagnosis NOT IN (SELECT desc_epis_diagnosis
                                                   FROM TABLE(l_tbl_diag)) AND
               nvl(d.flg_other, 'X') = pk_alert_constant.g_yes)))
           AND ard.flg_status = pk_alert_constant.g_active;
    
        g_error := 'CANCEL ALL PREVIOUS DIAGNOSES';
        pk_alertlog.log_debug(g_error);
    
        IF l_id_adm_req_diagnosis IS NOT NULL
           AND l_id_adm_req_diagnosis.count > 0
        THEN
            FOR i IN l_id_adm_req_diagnosis.first .. l_id_adm_req_diagnosis.last
            LOOP
                g_error := 'CALL ts_adm_req_diagnosis. id_adm_req_diagnosis_in: ' || l_id_adm_req_diagnosis(i);
                pk_alertlog.log_debug(g_error);
                ts_adm_req_diagnosis.upd(id_adm_req_diagnosis_in   => l_id_adm_req_diagnosis(i),
                                         flg_status_in             => 'O',
                                         id_professional_update_in => i_prof.id,
                                         dt_update_in              => i_timestamp,
                                         rows_out                  => l_rows);
            
                g_error := 'SEND TO INP EPISODE (pk_diagnosis.set_epis_diagnosis_nocommit) i_diagnosis: ' ||
                           l_id_diagnosis(i) || ' id_epis_diagnosis: ' || l_created_diags(i) || ' i_diag_notes: ' || i_diagnosis_adm_req.tbl_diagnosis(i).notes;
                pk_alertlog.log_debug(g_error);
            
                l_diagnosis_adm_req.epis_diagnosis := pk_diagnosis.get_diag_rec(i_lang              => i_lang,
                                                                                i_prof              => i_prof,
                                                                                i_patient           => NULL,
                                                                                i_episode           => i_episode_inp,
                                                                                i_diagnosis         => l_id_diagnosis(i),
                                                                                i_cdr_call          => i_id_cdr_call,
                                                                                i_id_epis_diagnosis => l_created_diag(i).id_epis_diagnosis,
                                                                                i_flg_status        => pk_alert_constant.g_flg_status_c,
                                                                                i_spec_notes        => i_diagnosis_adm_req.tbl_diagnosis(i).notes);
            
                IF NOT pk_diagnosis.set_epis_diagnosis(i_lang           => i_lang,
                                                       i_prof           => i_prof,
                                                       i_epis_diagnoses => l_diagnosis_adm_req,
                                                       o_params         => l_created_diag,
                                                       o_error          => o_error)
                THEN
                    RETURN FALSE;
                END IF;
            
                IF i_episode_sr IS NOT NULL
                THEN
                    g_error := 'SEND TO SR EPISODE. (pk_diagnosis.set_epis_diagnosis_nocommit) i_diagnosis: ' ||
                               l_id_diagnosis(i) || ' id_epis_diagnosis: ' || l_created_diags(i) || ' i_diag_notes: ' || i_diagnosis_adm_req.tbl_diagnosis(i).notes ||
                               ' i_episode_sr: ' || i_episode_sr;
                    pk_alertlog.log_debug(g_error);
                
                    l_diagnosis_adm_req.epis_diagnosis := pk_diagnosis.get_diag_rec(i_lang              => i_lang,
                                                                                    i_prof              => i_prof,
                                                                                    i_patient           => NULL,
                                                                                    i_episode           => i_episode_sr,
                                                                                    i_diagnosis         => l_id_diagnosis(i),
                                                                                    i_cdr_call          => i_id_cdr_call,
                                                                                    i_id_epis_diagnosis => l_created_diag(i).id_epis_diagnosis,
                                                                                    i_flg_status        => pk_alert_constant.g_flg_status_c,
                                                                                    i_spec_notes        => i_diagnosis_adm_req.tbl_diagnosis(i).notes);
                
                    IF NOT pk_diagnosis.set_epis_diagnosis(i_lang           => i_lang,
                                                           i_prof           => i_prof,
                                                           i_epis_diagnoses => l_diagnosis_adm_req,
                                                           o_params         => l_created_diag,
                                                           o_error          => o_error)
                    THEN
                        RETURN FALSE;
                    END IF;
                END IF;
            END LOOP;
        
            g_error := 'PROCESS UPDATE ADM_REQ_DIAGNOSIS';
            pk_alertlog.log_debug(g_error);
            t_data_gov_mnt.process_update(i_lang,
                                          i_prof,
                                          'ADM_REQ_DIAGNOSIS',
                                          l_rows,
                                          o_error,
                                          table_varchar('FLG_STATUS', 'ID_PROFESSIONAL_UPDATE', 'DT_UPDATE'));
            t_data_gov_mnt.process_insert(i_lang, i_prof, 'ADM_REQ_DIAGNOSIS', l_rows_ins, o_error);
        
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_pck_owner,
                                              g_pck_name,
                                              'SET_DIAGNOSIS',
                                              o_error);
            pk_utils.undo_changes;
        
            RETURN FALSE;
    END set_diagnosis;

    -- Public functions
    FUNCTION get_adm_indication_spec_list
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_specs OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'OPEN CURSOR';
        OPEN o_specs FOR
            SELECT cs.id_clinical_service,
                   pk_translation.get_translation(i_lang, cs.code_clinical_service) clin_serv_name
              FROM clinical_service cs
             WHERE cs.flg_available = pk_alert_constant.g_yes
               AND EXISTS (SELECT 0
                      FROM dep_clin_serv dcs
                      JOIN adm_ind_dep_clin_serv aidcs
                        ON (dcs.id_dep_clin_serv = aidcs.id_dep_clin_serv)
                      JOIN department d
                        ON (dcs.id_department = d.id_department)
                      JOIN institution inst
                        ON (inst.id_institution = d.id_institution)
                      LEFT JOIN institution mine
                        ON (mine.id_parent = inst.id_parent)
                     WHERE (mine.id_institution = i_prof.institution OR
                           (mine.id_institution IS NULL AND inst.id_institution = i_prof.institution))
                       AND dcs.id_clinical_service = cs.id_clinical_service
                       AND d.flg_available = pk_alert_constant.g_yes
                       AND dcs.flg_available = pk_alert_constant.g_yes
                       AND aidcs.flg_available = pk_alert_constant.g_yes
                       AND d.id_institution IN
                           (SELECT decode(ai.id_group, NULL, ai.id_institution, ig.id_institution)
                              FROM adm_indication ai
                              LEFT JOIN institution_group ig
                                ON (ig.id_group = ai.id_group AND
                                   ig.flg_relation = pk_alert_constant.g_grp_flg_rel_instcnt)
                             WHERE ai.id_adm_indication = aidcs.id_adm_indication))
             ORDER BY clin_serv_name;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_pck_owner,
                                              g_pck_name,
                                              'GET_ADM_INDICATION_SPEC_LIST',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_specs);
        
            RETURN FALSE;
    END;

    FUNCTION get_adm_indication_list
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_clin_serv   IN clinical_service.id_clinical_service%TYPE,
        o_indications OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'OPEN CURSOR';
        OPEN o_indications FOR
            SELECT ai.id_adm_indication,
                   nvl(ai.desc_adm_indication, pk_translation.get_translation(i_lang, ai.code_adm_indication)) indication_desc
              FROM adm_indication ai
             WHERE EXISTS (SELECT 0
                      FROM dep_clin_serv dcs
                      JOIN adm_ind_dep_clin_serv aidcs
                        ON (aidcs.id_dep_clin_serv = dcs.id_dep_clin_serv)
                      JOIN department dep
                        ON (dep.id_department = dcs.id_department)
                      JOIN institution inst
                        ON (inst.id_institution = dep.id_institution)
                      LEFT JOIN institution mine
                        ON (mine.id_parent = inst.id_parent)
                     WHERE (mine.id_institution = i_prof.institution OR
                           (mine.id_institution IS NULL AND inst.id_institution = i_prof.institution))
                       AND dcs.id_clinical_service = i_clin_serv
                       AND aidcs.flg_available = pk_alert_constant.g_yes
                       AND dcs.flg_available = pk_alert_constant.g_yes
                       AND ai.id_adm_indication = aidcs.id_adm_indication)
               AND ai.flg_available = pk_alert_constant.g_yes
             ORDER BY indication_desc;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_pck_owner,
                                              g_pck_name,
                                              'GET_ADM_INDICATION_LIST',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_indications);
        
            RETURN FALSE;
    END;

    FUNCTION get_location_list
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_adm_indication IN adm_indication.id_adm_indication%TYPE,
        o_list           OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        IF i_adm_indication IS NULL
        THEN
            g_error := 'OPEN CURSOR';
            OPEN o_list FOR
                SELECT inst.id_institution,
                       'N',
                       pk_translation.get_translation(i_lang, inst.code_institution) institution_desc
                  FROM institution inst
                  JOIN institution mine
                    ON (mine.id_parent = inst.id_parent)
                 WHERE mine.id_institution = i_prof.institution
                   AND EXISTS
                 (SELECT 0
                          FROM adm_indication ai
                          LEFT JOIN institution_group ig
                            ON (ai.id_group = ig.id_group)
                         WHERE inst.id_institution = decode(ai.id_group, NULL, ai.id_institution, ig.id_institution));
        
        ELSIF i_adm_indication = g_reason_admission_ft
        THEN
            OPEN o_list FOR
                SELECT i.id_institution,
                       'Y',
                       pk_translation.get_translation(i_lang, i.code_institution) institution_desc
                  FROM institution i
                 WHERE i.id_institution = i_prof.institution;
        
        ELSE
            g_error := 'OPEN CURSOR';
            OPEN o_list FOR
                SELECT id_institution,
                       decode(id_institution, i_prof.institution, pk_alert_constant.g_yes, pk_alert_constant.g_no),
                       institution_desc
                  FROM (SELECT DISTINCT inst.id_institution AS id_institution,
                                        pk_translation.get_translation(i_lang, inst.code_institution) institution_desc
                          FROM institution inst
                          LEFT JOIN institution mine
                            ON (mine.id_parent = inst.id_parent)
                          JOIN adm_indication ai
                            ON (1 = 1)
                          LEFT JOIN institution_group ig
                            ON (ig.id_group = ai.id_group AND ig.flg_relation = pk_alert_constant.g_grp_flg_rel_instcnt)
                         WHERE (mine.id_institution = i_prof.institution OR
                               (mine.id_institution IS NULL AND inst.id_institution = i_prof.institution) OR
                               inst.id_institution = ig.id_institution)
                           AND EXISTS (SELECT 0
                                  FROM adm_ind_dep_clin_serv aidcs
                                  JOIN dep_clin_serv dcs
                                    ON (dcs.id_dep_clin_serv = aidcs.id_dep_clin_serv)
                                  JOIN department d
                                    ON (dcs.id_department = d.id_department)
                                  JOIN adm_indication ai2
                                    ON (ai2.id_adm_indication = aidcs.id_adm_indication)
                                 WHERE ai.id_adm_indication = ai2.id_adm_indication
                                   AND (ai2.id_adm_indication = i_adm_indication OR i_adm_indication IS NULL)
                                   AND dcs.flg_available = pk_alert_constant.g_yes
                                   AND d.flg_available = pk_alert_constant.g_yes
                                   AND d.id_institution = inst.id_institution
                                   AND aidcs.flg_available = 'Y')
                        --AND inst.id_institution IN decode(ai.id_group, NULL, ai.id_institution, ig.id_institution)
                        )
                 ORDER BY institution_desc;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_pck_owner,
                                              g_pck_name,
                                              'GET_LOCATION_LIST',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_list);
        
            RETURN FALSE;
    END;

    FUNCTION get_ward_list
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_adm_indication IN adm_indication.id_adm_indication%TYPE,
        i_location       IN institution.id_institution%TYPE,
        o_list           OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'OPEN CURSOR';
        OPEN o_list FOR
            SELECT d.id_department, pk_translation.get_translation(i_lang, d.code_department) ward_desc
              FROM department d
             WHERE d.id_institution = i_location
               AND d.flg_available = pk_alert_constant.g_yes
               AND EXISTS (SELECT 0
                      FROM adm_ind_dep_clin_serv aidcs
                      JOIN dep_clin_serv dcs
                        ON (dcs.id_dep_clin_serv = aidcs.id_dep_clin_serv)
                     WHERE dcs.id_department = d.id_department
                       AND aidcs.id_adm_indication = i_adm_indication
                       AND aidcs.flg_available = pk_alert_constant.g_yes
                       AND dcs.flg_available = pk_alert_constant.g_yes)
             ORDER BY ward_desc;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_pck_owner,
                                              g_pck_name,
                                              'GET_WARD_LIST',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_list);
        
            RETURN FALSE;
    END;

    FUNCTION get_ward_list_ds
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_adm_indication IN adm_indication.id_adm_indication%TYPE,
        i_location       IN institution.id_institution%TYPE,
        i_ward           IN department.id_department%TYPE,
        o_list           OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_dept_dummy sys_config.value%TYPE := pk_sysconfig.get_config(i_prof    => i_prof,
                                                                      i_code_cf => 'INPATIENT_ADMISSION_DEPARTMENT_DUMMY');
    
        l_id_market market.id_market%TYPE := pk_prof_utils.get_prof_market(i_prof => i_prof);
    BEGIN
        g_error := 'OPEN CURSOR';
    
        IF i_adm_indication = g_reason_admission_ft
        THEN
            OPEN o_list FOR
                SELECT z.id_department,
                       z.ward_desc,
                       z.flg_default,
                       xmlelement("ADDITIONAL_INFO", xmlattributes(z.flg_default)).getclobval() addit_info
                  FROM (SELECT DISTINCT d.id_department,
                                        pk_translation.get_translation(i_lang, d.code_department) ward_desc,
                                        decode(d.id_department,
                                               l_dept_dummy,
                                               pk_alert_constant.g_yes,
                                               decode(b.flg_default,
                                                      pk_alert_constant.g_yes,
                                                      pk_alert_constant.g_yes,
                                                      pk_alert_constant.g_no)) AS flg_default
                          FROM department d
                          LEFT JOIN dep_clin_serv a
                            ON d.id_department = a.id_department
                          LEFT JOIN prof_dep_clin_serv b
                            ON a.id_dep_clin_serv = b.id_dep_clin_serv
                           AND b.id_professional = i_prof.id
                         WHERE (d.id_institution = i_location OR i_location IS NULL)
                           AND d.flg_available = pk_alert_constant.g_yes
                           AND d.flg_type = 'I'
                           AND ((l_id_market = pk_alert_constant.g_id_market_sa AND d.id_department = l_dept_dummy) OR
                               (l_id_market != pk_alert_constant.g_id_market_sa))) z
                 ORDER BY ward_desc;
        ELSE
            OPEN o_list FOR
                SELECT z.id_department,
                       z.ward_desc,
                       z.flg_default,
                       xmlelement("ADDITIONAL_INFO", xmlattributes(z.flg_default)).getclobval() addit_info
                  FROM (SELECT d.id_department,
                               pk_translation.get_translation(i_lang, d.code_department) ward_desc,
                               decode(d.id_department,
                                      l_dept_dummy,
                                      pk_alert_constant.g_yes,
                                      i_ward,
                                      pk_alert_constant.g_yes,
                                      pk_alert_constant.g_no) AS flg_default
                          FROM department d
                         WHERE (d.id_institution = i_location OR i_location IS NULL)
                           AND d.flg_available = pk_alert_constant.g_yes
                           AND d.flg_type = 'I'
                           AND ((l_id_market = pk_alert_constant.g_id_market_sa AND d.id_department = l_dept_dummy) OR
                               (l_id_market != pk_alert_constant.g_id_market_sa AND EXISTS
                                (SELECT 0
                                    FROM adm_ind_dep_clin_serv aidcs
                                    JOIN dep_clin_serv dcs
                                      ON (dcs.id_dep_clin_serv = aidcs.id_dep_clin_serv)
                                   WHERE dcs.id_department = d.id_department
                                     AND aidcs.id_adm_indication = i_adm_indication
                                     AND aidcs.flg_available = pk_alert_constant.g_yes
                                     AND dcs.flg_available = pk_alert_constant.g_yes)))) z
                 ORDER BY ward_desc;
        
        END IF;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_pck_owner,
                                              g_pck_name,
                                              'GET_WARD_LIST',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_list);
        
            RETURN FALSE;
    END;

    FUNCTION get_dep_clin_serv_list
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_adm_indication IN adm_indication.id_adm_indication%TYPE,
        i_ward           IN department.id_department%TYPE,
        o_list           OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'OPEN CURSOR';
        OPEN o_list FOR
            SELECT dcs.id_dep_clin_serv,
                   pk_translation.get_translation(i_lang,
                                                  'CLINICAL_SERVICE.CODE_CLINICAL_SERVICE.' || dcs.id_clinical_service) clin_serv_desc
              FROM dep_clin_serv dcs
              JOIN department d
                ON (dcs.id_department = d.id_department)
            
             WHERE d.id_department = i_ward
               AND dcs.flg_available = pk_alert_constant.g_yes
            /*AND EXISTS (SELECT 0
             FROM adm_ind_dep_clin_serv aidcs
            WHERE aidcs.id_adm_indication = i_adm_indication
              AND aidcs.id_dep_clin_serv = dcs.id_dep_clin_serv)*/
            
             ORDER BY clin_serv_desc;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_pck_owner,
                                              g_pck_name,
                                              'GET_DEP_CLIN_SERV_LIST',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_list);
        
            RETURN FALSE;
    END;

    FUNCTION get_dep_clin_serv_list_ds
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_adm_indication IN adm_indication.id_adm_indication%TYPE,
        i_ward           IN department.id_department%TYPE,
        i_dep_clin_serv  IN dep_clin_serv.id_dep_clin_serv%TYPE,
        o_list           OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_dept_dummy sys_config.value%TYPE := pk_sysconfig.get_config(i_prof    => i_prof,
                                                                      i_code_cf => 'INPATIENT_ADMISSION_DEPARTMENT_DUMMY');
    
        l_prof_speciality clinical_service.id_clinical_service%TYPE;
        l_prof_dept_pref  dep_clin_serv.id_dep_clin_serv%TYPE;
    BEGIN
    
        BEGIN
            SELECT dcs.id_clinical_service
              INTO l_prof_speciality
              FROM dep_clin_serv dcs
              JOIN department dpt
                ON dpt.id_department = dcs.id_department
              JOIN prof_dep_clin_serv pdcs
                ON pdcs.id_dep_clin_serv = dcs.id_dep_clin_serv
              JOIN software_dept sdt
                ON sdt.id_dept = dpt.id_dept
             WHERE pdcs.flg_default = pk_prof_utils.g_dcs_default
               AND sdt.id_software = i_prof.software
                  --AND dpt.flg_type = g_flg_type_department_s
               AND pdcs.flg_status = pk_prof_utils.g_dcs_selected
               AND pdcs.id_professional = i_prof.id
               AND dpt.id_institution = i_prof.institution
               AND rownum = 1;
        EXCEPTION
            WHEN OTHERS THEN
                l_prof_speciality := NULL;
        END;
    
        g_error := 'OPEN CURSOR';
        IF i_adm_indication = g_reason_admission_ft
        THEN
            OPEN o_list FOR
                SELECT z.id_dep_clin_serv,
                       z.clin_serv_desc,
                       z.flg_default,
                       xmlelement("ADDITIONAL_INFO", xmlattributes(z.flg_default)).getclobval() addit_info
                  FROM (SELECT DISTINCT dcs.id_dep_clin_serv,
                                        pk_translation.get_translation(i_lang,
                                                                       'CLINICAL_SERVICE.CODE_CLINICAL_SERVICE.' ||
                                                                       dcs.id_clinical_service) clin_serv_desc,
                                        decode(pdcs.id_prof_dep_clin_serv,
                                               NULL,
                                               decode(dcs.id_dep_clin_serv,
                                                      i_dep_clin_serv,
                                                      pk_alert_constant.g_yes,
                                                      decode(l_prof_speciality,
                                                             dcs.id_clinical_service,
                                                             pk_alert_constant.g_yes,
                                                             pk_alert_constant.g_no)),
                                               pdcs.flg_default) flg_default
                          FROM dep_clin_serv dcs
                          JOIN department d
                            ON (dcs.id_department = d.id_department)
                          LEFT JOIN prof_dep_clin_serv pdcs
                            ON pdcs.id_dep_clin_serv = dcs.id_dep_clin_serv
                         WHERE (d.id_department = i_ward OR i_ward IS NULL)
                           AND d.flg_type = 'I'
                           AND ((pdcs.id_professional = i_prof.id AND i_ward != nvl(l_dept_dummy, 0)) OR
                               i_ward = l_dept_dummy)
                           AND dcs.flg_available = pk_alert_constant.g_yes) z
                 ORDER BY clin_serv_desc;
        ELSE
            OPEN o_list FOR
                SELECT z.id_dep_clin_serv,
                       z.clin_serv_desc,
                       z.flg_default,
                       xmlelement("ADDITIONAL_INFO", xmlattributes(z.flg_default)).getclobval() addit_info
                  FROM (SELECT DISTINCT dcs.id_dep_clin_serv,
                                        pk_translation.get_translation(i_lang,
                                                                       'CLINICAL_SERVICE.CODE_CLINICAL_SERVICE.' ||
                                                                       dcs.id_clinical_service) clin_serv_desc,
                                        decode(dcs.id_dep_clin_serv,
                                               i_dep_clin_serv,
                                               pk_alert_constant.g_yes,
                                               decode(l_prof_speciality,
                                                      dcs.id_clinical_service,
                                                      pk_alert_constant.g_yes,
                                                      pk_alert_constant.g_no)) flg_default
                          FROM dep_clin_serv dcs
                          JOIN department d
                            ON (dcs.id_department = d.id_department)
                        /*                          LEFT JOIN prof_dep_clin_serv pdcs
                        ON pdcs.id_dep_clin_serv = dcs.id_dep_clin_serv*/
                         WHERE (d.id_department = i_ward OR i_ward IS NULL)
                           AND dcs.flg_available = pk_alert_constant.g_yes
                           AND ((EXISTS (SELECT 0
                                           FROM adm_ind_dep_clin_serv aidcs
                                          WHERE aidcs.id_adm_indication = i_adm_indication
                                            AND aidcs.id_dep_clin_serv = dcs.id_dep_clin_serv) AND
                                i_ward != nvl(l_dept_dummy, 0)) OR i_ward = l_dept_dummy)) z
                 ORDER BY clin_serv_desc;
        END IF;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_pck_owner,
                                              g_pck_name,
                                              'GET_DEP_CLIN_SERV_LIST',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_list);
        
            RETURN FALSE;
    END;

    FUNCTION get_admission_type_list
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_location IN institution.id_institution%TYPE,
        o_list     OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
        l_location institution.id_institution%TYPE;
    BEGIN
        g_error := 'GET LOCATION';
        SELECT MAX(at.id_institution)
          INTO l_location
          FROM admission_type at
         WHERE at.id_institution IN (0, i_location);
    
        g_error := 'OPEN CURSOR';
        OPEN o_list FOR
            SELECT at.id_admission_type,
                   nvl(at.desc_admission_type, pk_translation.get_translation(i_lang, at.code_admission_type)) adm_type_desc,
                   at.max_admission_time
              FROM admission_type at
             WHERE at.id_institution = l_location
               AND at.flg_available = pk_alert_constant.g_yes
             ORDER BY adm_type_desc;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_pck_owner,
                                              g_pck_name,
                                              'GET_ADMISSION_TYPE_LIST',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_list);
        
            RETURN FALSE;
    END;

    FUNCTION get_admission_type_list_ds
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_location IN institution.id_institution%TYPE,
        i_adm_type IN admission_type.id_admission_type%TYPE,
        o_list     OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
        l_location institution.id_institution%TYPE;
        l_count    NUMBER;
    BEGIN
        g_error := 'GET LOCATION';
        SELECT MAX(at.id_institution)
          INTO l_location
          FROM admission_type at
         WHERE at.id_institution IN (0, i_location);
    
        SELECT COUNT(*)
          INTO l_count
          FROM admission_type at
         WHERE (at.id_institution = l_location OR l_location IS NULL)
           AND at.flg_available = pk_alert_constant.g_yes;
    
        g_error := 'OPEN CURSOR';
        OPEN o_list FOR
            SELECT z.id_admission_type,
                   z.adm_type_desc,
                   z.max_admission_time,
                   xmlelement("ADDITIONAL_INFO", xmlattributes(z.flg_default)).getclobval() addit_info
              FROM (SELECT at.id_admission_type,
                           nvl(at.desc_admission_type, pk_translation.get_translation(i_lang, at.code_admission_type)) adm_type_desc,
                           at.max_admission_time,
                           decode(at.id_admission_type,
                                  i_adm_type,
                                  pk_alert_constant.g_yes,
                                  decode(l_count, 1, pk_alert_constant.g_yes, pk_alert_constant.g_no)) flg_default
                      FROM admission_type at
                     WHERE (at.id_institution = l_location OR l_location IS NULL)
                       AND at.flg_available = pk_alert_constant.g_yes) z
             ORDER BY z.adm_type_desc;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_pck_owner,
                                              g_pck_name,
                                              'GET_ADMISSION_TYPE_LIST',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_list);
        
            RETURN FALSE;
    END;

    FUNCTION get_bed_type_list
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_location IN institution.id_institution%TYPE,
        o_list     OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'OPEN CURSOR';
        OPEN o_list FOR
            SELECT bt.id_bed_type,
                   nvl(bt.desc_bed_type, pk_translation.get_translation(i_lang, bt.code_bed_type)) bed_type_desc
              FROM bed_type bt
             WHERE EXISTS (SELECT 0
                      FROM department d
                      JOIN room r
                        ON (r.id_department = d.id_department)
                      JOIN bed b
                        ON (b.id_room = r.id_room)
                     WHERE d.id_institution = i_location
                       AND b.id_bed_type = bt.id_bed_type
                       AND d.flg_available = pk_alert_constant.g_yes
                       AND r.flg_available = pk_alert_constant.g_yes
                       AND r.flg_transp = pk_alert_constant.g_yes
                       AND b.flg_available = pk_alert_constant.g_yes)
               AND bt.id_institution IN (0, i_location)
               AND bt.flg_available = pk_alert_constant.g_yes
             ORDER BY bed_type_desc;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_pck_owner,
                                              g_pck_name,
                                              'GET_BED_TYPE_LIST',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_list);
        
            RETURN FALSE;
    END;

    FUNCTION get_room_type_list
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_location IN institution.id_institution%TYPE,
        o_list     OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'OPEN CURSOR';
        OPEN o_list FOR
            SELECT rt.id_room_type,
                   nvl(rt.desc_room_type, pk_translation.get_translation(i_lang, rt.code_room_type)) room_type_desc
              FROM room_type rt
             WHERE EXISTS (SELECT 0
                      FROM department d
                      JOIN room r
                        ON (r.id_department = d.id_department)
                     WHERE r.id_room_type = rt.id_room_type
                       AND d.id_institution = i_location
                          
                       AND d.flg_available = pk_alert_constant.g_yes
                       AND r.flg_available = pk_alert_constant.g_yes
                       AND r.flg_transp = pk_alert_constant.g_yes)
               AND rt.id_institution IN (0, i_location)
               AND rt.flg_available = pk_alert_constant.get_yes
             ORDER BY room_type_desc;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_pck_owner,
                                              g_pck_name,
                                              'GET_ROOM_TYPE_LIST',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_list);
        
            RETURN FALSE;
    END;

    FUNCTION get_mixed_nursing_list
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'GET DOMAINS';
        IF NOT pk_sysdomain.get_values_domain('ADM_REQUEST.FLG_MIXED_NURSING',
                                              i_lang,
                                              o_list,
                                              table_varchar(pk_alert_constant.g_no, 'I'))
        THEN
            RAISE e_call_error;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_pck_owner,
                                              g_pck_name,
                                              'GET_MIXED_NURSING_LIST',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_list);
        
            RETURN FALSE;
    END;

    FUNCTION get_nurse_intake_yesno_list
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'GET DOMAINS';
        IF NOT pk_sysdomain.get_values_domain('YES_NO', i_lang, o_list, table_varchar('Y', 'N'))
        THEN
            RAISE e_call_error;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_pck_owner,
                                              g_pck_name,
                                              'GET_NURSE_INTAKE_YESNO_LIST',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_list);
        
            RETURN FALSE;
    END;

    FUNCTION get_adm_preparation_list
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_location IN institution.id_institution%TYPE,
        o_list     OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
        l_location institution.id_institution%TYPE;
    BEGIN
        g_error := 'GET LOCATION';
        SELECT MAX(ap.id_institution)
          INTO l_location
          FROM adm_preparation ap
         WHERE ap.id_institution IN (0, i_location);
    
        g_error := 'GET DOMAINS';
        OPEN o_list FOR
            SELECT ap.id_adm_preparation,
                   nvl(ap.desc_adm_preparation, pk_translation.get_translation(i_lang, ap.code_adm_preparation)) adm_preparation_desc
              FROM adm_preparation ap
             WHERE ap.id_institution = l_location
               AND ap.flg_available = pk_alert_constant.g_yes
             ORDER BY adm_preparation_desc;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_pck_owner,
                                              g_pck_name,
                                              'GET_ADM_PREPARATION_LIST',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_list);
        
            RETURN FALSE;
    END;

    FUNCTION get_physicians_list
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_dep_clin_serv IN dep_clin_serv.id_dep_clin_serv%TYPE,
        o_list          OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'OPEN CURSOR';
        IF NOT get_physicians(i_lang, i_prof, i_dep_clin_serv, FALSE, o_list, o_error)
        THEN
            RAISE e_call_error;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_pck_owner,
                                              g_pck_name,
                                              'GET_PHYSICIANS_LIST',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_list);
        
            RETURN FALSE;
    END;

    FUNCTION get_physicians_list_ds
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_dep_clin_serv IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_professional  IN professional.id_professional%TYPE,
        i_id_inst_dest  IN department.id_institution%TYPE,
        o_list          OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'OPEN CURSOR';
    
        IF NOT
            get_physicians_ds(i_lang, i_prof, i_dep_clin_serv, FALSE, i_professional, i_id_inst_dest, o_list, o_error)
        THEN
            RAISE e_call_error;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_pck_owner,
                                              g_pck_name,
                                              'GET_PHYSICIANS_LIST',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_list);
        
            RETURN FALSE;
    END;

    FUNCTION get_mrp_list_ds
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_dep_clin_serv IN dep_clin_serv.id_dep_clin_serv%TYPE,
        o_list          OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        OPEN o_list FOR
            SELECT z.id, z.name,xmlelement("ADDITIONAL_INFO", xmlattributes(z.flg_default)).getclobval() addit_info
              FROM (SELECT DISTINCT prf.id_professional id,
                                    pk_prof_utils.get_name_signature(i_lang, i_prof, prf.id_professional) name,
                                    decode(prf.id_professional,
                                           i_prof.id,
                                           pk_alert_constant.g_yes,
                                           pk_alert_constant.g_no) flg_default
                      FROM prof_institution pi
                     INNER JOIN prof_cat prc
                        ON (prc.id_professional = pi.id_professional)
                     INNER JOIN category cat
                        ON (cat.id_category = prc.id_category)
                     INNER JOIN professional prf
                        ON (prf.id_professional = pi.id_professional)
                     INNER JOIN prof_profile_template ppt
                        ON prc.id_institution = ppt.id_institution
                       AND prc.id_professional = ppt.id_professional
                      JOIN profile_template pt
                        ON ppt.id_profile_template = pt.id_profile_template
                      JOIN prof_dep_clin_serv pdcs
                        ON pdcs.id_professional = prf.id_professional
                     WHERE cat.flg_type = 'D'
                       AND prf.flg_state = 'A'
                       AND (pdcs.id_dep_clin_serv = i_dep_clin_serv OR i_dep_clin_serv IS NULL)
                       AND pi.id_institution = i_prof.institution
                       AND pi.flg_state = pk_alert_constant.g_active
                       AND pi.dt_end_tstz IS NULL
                       AND prc.id_institution = i_prof.institution
                       AND pi.flg_external = pk_alert_constant.g_no
                       AND ppt.id_software = pk_alert_constant.g_soft_inpatient
                       AND nvl(prf.flg_prof_test, pk_alert_constant.g_no) = pk_alert_constant.g_no
                       AND pt.flg_profile IN ('S')
                       AND pk_prof_utils.get_flg_mrp(i_lang, i_prof, ppt.id_profile_template) = pk_alert_constant.g_yes) z;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_pck_owner,
                                              g_pck_name,
                                              'GET_PHYSICIANS_LIST',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_list);
        
            RETURN FALSE;
    END get_mrp_list_ds;

    FUNCTION get_nit_location_list
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
        g_nitdcs_config CONSTANT sys_config.id_sys_config%TYPE := 'NURSE_INTAKE_DCS';
    BEGIN
        g_error := 'OPEN CURSOR';
        OPEN o_list FOR
            SELECT inst.id_institution id_location,
                   pk_translation.get_translation(i_lang, inst.code_institution) location_desc,
                   dcs.id_dep_clin_serv
              FROM institution inst
              JOIN department d
                ON (d.id_institution = inst.id_institution)
              JOIN dep_clin_serv dcs
                ON (dcs.id_department = d.id_department)
              JOIN sys_config sc
                ON (dcs.id_dep_clin_serv = sc.value AND inst.id_institution = sc.id_institution)
             WHERE d.flg_available = pk_alert_constant.g_yes
               AND dcs.flg_available = pk_alert_constant.g_yes
               AND sc.id_sys_config = g_nitdcs_config
               AND inst.id_institution IN (SELECT samehc.id_institution
                                             FROM institution samehc
                                             JOIN institution mine
                                               ON (mine.id_parent = samehc.id_parent)
                                            WHERE mine.id_institution = i_prof.institution
                                           UNION ALL
                                           SELECT i_prof.institution
                                             FROM dual);
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_pck_owner,
                                              g_pck_name,
                                              'GET_NIT_LOCATION_LIST',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_list);
        
            RETURN FALSE;
    END;

    FUNCTION get_adm_indication_search
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_indication IN VARCHAR2,
        o_list       OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'OPEN CURSOR';
        OPEN o_list FOR
            SELECT id_adm_indication, indication_desc
              FROM (SELECT ai.id_adm_indication,
                           nvl(ai.desc_adm_indication, pk_translation.get_translation(i_lang, ai.code_adm_indication)) indication_desc
                      FROM adm_indication ai
                     WHERE EXISTS (SELECT 0
                              FROM adm_ind_dep_clin_serv aidcs
                              JOIN dep_clin_serv dcs
                                ON (aidcs.id_dep_clin_serv = dcs.id_dep_clin_serv)
                              JOIN department d
                                ON (d.id_department = dcs.id_department)
                              JOIN institution inst
                                ON (inst.id_institution = d.id_institution)
                              LEFT JOIN institution mine
                                ON (mine.id_parent = inst.id_parent)
                             WHERE aidcs.id_adm_indication = ai.id_adm_indication
                               AND aidcs.flg_available = pk_alert_constant.g_yes
                               AND dcs.flg_available = pk_alert_constant.g_yes
                               AND d.flg_available = pk_alert_constant.g_yes
                               AND (mine.id_institution = i_prof.institution OR
                                   (mine.id_institution IS NULL AND inst.id_institution = i_prof.institution)))
                       AND ai.flg_available = pk_alert_constant.g_yes)
             WHERE translate(upper(indication_desc), 'ÁÉÍÓÚÀÈÌÒÙÂÊÎÔÛÃÕÇÄËÏÖÜÑ', 'AEIOUAEIOUAEIOUAOCAEIOUN') LIKE
                   '%' || translate(upper(i_indication), 'ÁÉÍÓÚÀÈÌÒÙÂÊÎÔÛÃÕÇÄËÏÖÜÑ', 'AEIOUAEIOUAEIOUAOCAEIOUN') || '%'
            UNION ALL
            SELECT g_reason_admission_ft id_adm_indication,
                   i_indication || CASE
                       WHEN i_indication LIKE
                            '%' || pk_message.get_message(i_lang => i_lang, i_code_mess => 'COMMON_M136') || '%' THEN
                        NULL
                       ELSE
                        ' ' || pk_message.get_message(i_lang => i_lang, i_code_mess => 'COMMON_M136') || ''
                   END indication_desc
              FROM dual
             ORDER BY indication_desc;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_pck_owner,
                                              g_pck_name,
                                              'GET_ADM_INDICATION_SEARCH',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_list);
        
            RETURN FALSE;
    END;

    FUNCTION get_adm_indication_det
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_adm_indication    IN adm_indication.id_adm_indication%TYPE,
        o_avg_duration      OUT adm_indication.avg_duration%TYPE,
        o_u_lvl_id          OUT wtl_urg_level.id_wtl_urg_level%TYPE,
        o_u_lvl_duration    OUT wtl_urg_level.duration%TYPE,
        o_u_lvl_description OUT pk_translation.t_desc_translation,
        o_dt_begin          OUT VARCHAR2,
        o_dt_end            OUT VARCHAR2,
        o_location          OUT institution.id_institution%TYPE,
        o_location_desc     OUT pk_translation.t_desc_translation,
        o_ward              OUT department.id_department%TYPE,
        o_ward_desc         OUT pk_translation.t_desc_translation,
        o_dep_clin_serv     OUT dep_clin_serv.id_dep_clin_serv%TYPE,
        o_clin_serv_desc    OUT pk_translation.t_desc_translation,
        o_professional      OUT professional.id_professional%TYPE,
        o_prof_desc         OUT pk_translation.t_desc_translation,
        o_adm_type          OUT admission_type.id_admission_type%TYPE,
        o_adm_type_desc     OUT pk_translation.t_desc_translation,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        l_today_insttimezone TIMESTAMP WITH TIME ZONE;
        l_no_data_found      BOOLEAN;
    BEGIN
        g_error := 'GET FROM ADM_INDICATION';
        BEGIN
            SELECT ai.avg_duration,
                   ai.id_wtl_urg_level,
                   wul.duration ulvl_duration,
                   nvl(wul.desc_wtl_urg_level, pk_translation.get_translation(i_lang, wul.code)) u_lvl_description
              INTO o_avg_duration, o_u_lvl_id, o_u_lvl_duration, o_u_lvl_description
              FROM adm_indication ai
              LEFT JOIN wtl_urg_level wul
                ON wul.id_wtl_urg_level = ai.id_wtl_urg_level
             WHERE ai.id_adm_indication = i_adm_indication;
        EXCEPTION
            WHEN no_data_found THEN
                l_no_data_found := TRUE;
        END;
    
        g_error := 'GET LOCATIONS';
        IF NOT get_default_locations(i_lang           => i_lang,
                                     i_prof           => i_prof,
                                     i_adm_indication => i_adm_indication,
                                     o_location       => o_location,
                                     o_location_desc  => o_location_desc,
                                     o_ward           => o_ward,
                                     o_ward_desc      => o_ward_desc,
                                     o_dep_clin_serv  => o_dep_clin_serv,
                                     o_clin_serv_desc => o_clin_serv_desc,
                                     o_professional   => o_professional,
                                     o_prof_desc      => o_prof_desc,
                                     o_adm_type       => o_adm_type,
                                     o_adm_type_desc  => o_adm_type_desc,
                                     o_error          => o_error)
        THEN
            RAISE e_call_error;
        END IF;
    
        g_error              := 'GET TODAY DATE';
        l_today_insttimezone := pk_date_utils.trunc_insttimezone(i_prof, current_timestamp, 'DD');
    
        g_error    := 'GET TODAY DATE SEND';
        o_dt_begin := pk_date_utils.date_send(i_lang => i_lang, i_date => l_today_insttimezone, i_prof => i_prof);
        g_error    := 'GET END DATE SEND';
    
        IF o_u_lvl_duration IS NOT NULL
        THEN
            o_dt_end := pk_date_utils.date_send(i_lang => i_lang,
                                                i_date => ((l_today_insttimezone + to_number(o_u_lvl_duration)) - 1),
                                                i_prof => i_prof);
        ELSE
            o_dt_end := NULL;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_pck_owner,
                                              g_pck_name,
                                              'GET_ADM_INDICATION_DET',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
        
            RETURN FALSE;
    END;

    FUNCTION get_defaults_with_location
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_adm_indication IN adm_indication.id_adm_indication%TYPE,
        i_location       IN institution.id_institution%TYPE,
        o_ward           OUT department.id_department%TYPE,
        o_ward_desc      OUT pk_translation.t_desc_translation,
        o_dep_clin_serv  OUT dep_clin_serv.id_dep_clin_serv%TYPE,
        o_clin_serv_desc OUT pk_translation.t_desc_translation,
        o_professional   OUT professional.id_professional%TYPE,
        o_prof_desc      OUT pk_translation.t_desc_translation,
        o_adm_type       OUT admission_type.id_admission_type%TYPE,
        o_adm_type_desc  OUT pk_translation.t_desc_translation,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_location      institution.id_institution%TYPE;
        l_location_desc pk_translation.t_desc_translation;
    BEGIN
        g_error := 'GET LOCATIONS';
        IF NOT get_default_locations(i_lang           => i_lang,
                                     i_prof           => i_prof,
                                     i_adm_indication => i_adm_indication,
                                     i_location       => i_location,
                                     o_location       => l_location,
                                     o_location_desc  => l_location_desc,
                                     o_ward           => o_ward,
                                     o_ward_desc      => o_ward_desc,
                                     o_dep_clin_serv  => o_dep_clin_serv,
                                     o_clin_serv_desc => o_clin_serv_desc,
                                     o_professional   => o_professional,
                                     o_prof_desc      => o_prof_desc,
                                     o_adm_type       => o_adm_type,
                                     o_adm_type_desc  => o_adm_type_desc,
                                     o_error          => o_error)
        THEN
            RAISE e_call_error;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_pck_owner,
                                              g_pck_name,
                                              'SET_LOCATION',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
        
            RETURN FALSE;
    END;

    FUNCTION get_defaults_with_ward
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_adm_indication IN adm_indication.id_adm_indication%TYPE,
        i_ward           IN department.id_department%TYPE,
        o_dep_clin_serv  OUT dep_clin_serv.id_dep_clin_serv%TYPE,
        o_clin_serv_desc OUT pk_translation.t_desc_translation,
        o_professional   OUT professional.id_professional%TYPE,
        o_prof_desc      OUT pk_translation.t_desc_translation,
        o_adm_type       OUT admission_type.id_admission_type%TYPE,
        o_adm_type_desc  OUT pk_translation.t_desc_translation,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_location      institution.id_institution%TYPE;
        l_location_desc pk_translation.t_desc_translation;
    
        l_ward      department.id_department%TYPE;
        l_ward_desc pk_translation.t_desc_translation;
    BEGIN
        g_error := 'GET LOCATIONS';
        IF NOT get_default_locations(i_lang           => i_lang,
                                     i_prof           => i_prof,
                                     i_adm_indication => i_adm_indication,
                                     i_ward           => i_ward,
                                     o_location       => l_location,
                                     o_location_desc  => l_location_desc,
                                     o_ward           => l_ward,
                                     o_ward_desc      => l_ward_desc,
                                     o_dep_clin_serv  => o_dep_clin_serv,
                                     o_clin_serv_desc => o_clin_serv_desc,
                                     o_professional   => o_professional,
                                     o_prof_desc      => o_prof_desc,
                                     o_adm_type       => o_adm_type,
                                     o_adm_type_desc  => o_adm_type_desc,
                                     o_error          => o_error)
        THEN
            RAISE e_call_error;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_pck_owner,
                                              g_pck_name,
                                              'SET_WARD',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
        
            RETURN FALSE;
    END;

    FUNCTION get_defaults_with_dcs
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_dep_clin_serv IN dep_clin_serv.id_dep_clin_serv%TYPE,
        o_professional  OUT professional.id_professional%TYPE,
        o_prof_desc     OUT pk_translation.t_desc_translation,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        c_physician pk_types.cursor_type;
    BEGIN
        g_error := 'GET LOCATIONS';
        IF NOT get_physicians(i_lang, i_prof, i_dep_clin_serv, TRUE, c_physician, o_error)
        THEN
            RAISE e_call_error;
        END IF;
        FETCH c_physician
            INTO o_professional, o_prof_desc;
        CLOSE c_physician;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_pck_owner,
                                              g_pck_name,
                                              'SET_DEP_CLIN_SERV',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
        
            RETURN FALSE;
    END;

    /********************************************************************************************
    * Sets a new admission request
    *
    * @param i_lang                           language id
    * @param i_prof                           professional tuple
    * @param i_req_episode                    current episode
    * @param i_patient                        current patient
    * @param i_adm_indication                 indication for admission id
    * @param i_diagnosis                      list with diagnoses
    * @param i_diag_statuses                  list with the diagnoses statuses
    * @param i_spec_notes                     list with diagnoses notes
    * @param i_diag_notes                     notes for the diagnoses set
    * @param i_dest_inst                      location requested
    * @param i_adm_type                       admission type
    * @param i_department                     department requested
    * @param i_room_type                      room type
    * @param i_dep_clin_serv                  specialty requested
    * @param i_pref_room                      preferred room
    * @param i_mixed_nursing                  mixed nursing preference
    * @param i_bed_type                       bed type
    * @param i_dest_prof                      professional requested to take the admission
    * @param i_adm_preparation                admission preparation
    * @param i_expect_duration                admission's expected duration
    * @param i_dt_admission                   date of admission (final)
    * @param i_notes                          entered notes
    * @param i_flg_nit                        flag indicating need for a nurse intake
    * @param i_dt_nit_suggested               date suggested for the nurse intake
    * @param i_id_nit_dcs                        dep_clin_serv for nurse intake
    * @param i_timestamp                      current_timestamp
    * @param i_waiting_list                   waiting list id
    * @param i_dt_sched_period_start          date expected for episode beginning
    * @param i_flg_process_event              Y-should be despoleted the process insert or update in the admission_request table
    * @param io_dest_episode                  episode id
    * @param o_visit                          visit id for the new admission episode
    * @param o_flg_ins_upd                    'I' - insert new record; 'U'- update record
    * @param o_error                          error
    *                    
    * @return                             true or false on success or error
    *
    * @author                             Fábio Oliveira
    * @version                            1.0   
    * @since                              25-04-2009
    **********************************************************************************************/

    FUNCTION set_adm_request
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_req_episode           IN adm_request.id_upd_episode%TYPE,
        i_patient               IN patient.id_patient%TYPE,
        i_adm_indication        IN adm_request.id_adm_indication%TYPE,
        i_adm_ind_desc          IN adm_request.adm_indication_ft%TYPE,
        i_dest_inst             IN adm_request.id_dest_inst%TYPE,
        i_adm_type              IN adm_request.id_admission_type%TYPE,
        i_department            IN adm_request.id_department%TYPE,
        i_room_type             IN adm_request.id_room_type%TYPE,
        i_dep_clin_serv         IN adm_request.id_dep_clin_serv%TYPE,
        i_pref_room             IN adm_request.id_pref_room%TYPE,
        i_mixed_nursing         IN adm_request.flg_mixed_nursing%TYPE,
        i_bed_type              IN adm_request.id_bed_type%TYPE,
        i_dest_prof             IN adm_request.id_dest_prof%TYPE,
        i_adm_preparation       IN adm_request.id_adm_preparation%TYPE,
        i_expect_duration       IN adm_request.expected_duration%TYPE,
        i_notes                 IN adm_request.notes%TYPE,
        i_flg_nit               IN adm_request.flg_nit%TYPE,
        i_dt_nit_suggested      IN adm_request.dt_nit_suggested%TYPE,
        i_nit_dcs               IN adm_request.id_nit_dcs%TYPE,
        i_timestamp             IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_waiting_list          IN waiting_list.id_waiting_list%TYPE,
        i_dt_sched_period_start IN VARCHAR2,
        io_dest_episode         IN OUT episode.id_episode%TYPE,
        i_transaction_id        IN VARCHAR2,
        i_flg_process_event     IN VARCHAR2 DEFAULT pk_alert_constant.g_yes,
        i_regimen               IN VARCHAR2 DEFAULT NULL,
        i_beneficiario          IN VARCHAR2 DEFAULT NULL,
        i_precauciones          IN VARCHAR2 DEFAULT NULL,
        i_contactado            IN VARCHAR2 DEFAULT NULL,
        i_order_set             IN VARCHAR2,
        i_id_mrp                IN NUMBER DEFAULT NULL,
        i_id_written_by         IN NUMBER DEFAULT NULL,
        i_ri_prof_spec          IN NUMBER DEFAULT NULL,
        i_flg_compulsory        IN VARCHAR2 DEFAULT NULL,
        i_id_compulsory_reason  IN adm_request.id_compulsory_reason%TYPE DEFAULT NULL,
        i_compulsory_reason     IN adm_request.compulsory_reason%TYPE DEFAULT NULL,
        o_adm_request           OUT adm_request.id_adm_request%TYPE,
        o_visit                 IN OUT visit.id_visit%TYPE,
        o_flg_ins_upd           OUT VARCHAR2,
        o_rows                  OUT table_varchar,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(15 CHAR) := 'SET_ADM_REQUEST';
        l_adm_request_rec_old adm_request%ROWTYPE;
        l_adm_request_rec     adm_request%ROWTYPE;
        l_found               BOOLEAN;
        l_timestamp           TIMESTAMP WITH LOCAL TIME ZONE := nvl(i_timestamp, current_timestamp);
        l_timestamp_str       VARCHAR2(200) := pk_date_utils.date_send_tsz(i_lang => i_lang,
                                                                           i_date => current_timestamp,
                                                                           i_prof => i_prof);
        l_id_nit_req          adm_request.id_nit_req%TYPE;
    
        l_rows             table_varchar;
        l_flg_edit         VARCHAR2(1);
        l_not_changed      BOOLEAN;
        l_default_mixed    sys_config.value%TYPE;
        l_epis_dt_begin    VARCHAR2(20);
        l_dt_begin         TIMESTAMP WITH LOCAL TIME ZONE;
        l_clinical_service clinical_service.id_clinical_service%TYPE;
        l_epis_prof_resp   epis_prof_resp.id_epis_prof_resp%TYPE;
    
        --Scheduler 3.0 variables DO NOT REMOVE
        l_transaction_id VARCHAR2(4000);
    
        l_scheduler_exists sys_config.value%TYPE := pk_sysconfig.get_config(i_code_cf => 'ADMISSION_SCHEDULER_EXISTS',
                                                                            i_prof    => i_prof);
        l_rowids           table_varchar;
    
    BEGIN
    
        -- gets a new transaction ID and begins the transaction (for the Scheduler 3.0 transactions)
        g_error          := 'CALL PK_SCHEDULE_API_UPSTREAM.BEGIN_NEW_TRANSACTION';
        l_transaction_id := pk_schedule_api_upstream.begin_new_transaction(i_transaction_id, i_prof);
    
        g_error := 'CHECK ADM REQUEST';
        pk_alertlog.log_info(text => g_error, object_name => g_pck_name, sub_object_name => l_func_name);
        BEGIN
            SELECT ar.*
              INTO l_adm_request_rec_old
              FROM adm_request ar
             INNER JOIN wtl_epis we
                ON (we.id_episode = ar.id_dest_episode)
             WHERE ar.id_dest_episode = io_dest_episode --ar.id_req_episode = i_req_episode -- José Brito 06/05/2009
               AND we.id_waiting_list = i_waiting_list;
        
            l_found := TRUE;
        EXCEPTION
            WHEN no_data_found THEN
                l_found := FALSE;
        END;
    
        g_error := 'SET ADM REQUEST ID';
        pk_alertlog.log_info(text => g_error, object_name => g_pck_name, sub_object_name => l_func_name);
        IF l_found
        THEN
            l_adm_request_rec := l_adm_request_rec_old;
        ELSE
            l_adm_request_rec.id_adm_request := ts_adm_request.next_key;
        END IF;
    
        o_adm_request := l_adm_request_rec.id_adm_request;
    
        g_error := 'EPISODE SETUP';
        pk_alertlog.log_info(text => g_error, object_name => g_pck_name, sub_object_name => l_func_name);
        /*IF i_order_set = pk_alert_constant.g_no
        THEN*/
        IF io_dest_episode IS NULL
        THEN
            -- GET string in DATE_HOUR_SEND_FORMAT for current_timestamp to use as new episode begin date
            IF i_dt_sched_period_start IS NULL
            THEN
                l_epis_dt_begin := l_timestamp_str;
            ELSE
                l_epis_dt_begin := i_dt_sched_period_start;
            END IF;
        
            g_error := 'CALL pk_inp_episode.create_episode_no_commit';
            pk_alertlog.log_info(text => g_error, object_name => g_pck_name, sub_object_name => l_func_name);
            IF NOT pk_inp_episode.create_episode_no_commit(i_lang                   => i_lang,
                                                           i_prof                   => i_prof,
                                                           i_id_patient             => i_patient,
                                                           i_id_dep_clin_serv       => i_dep_clin_serv,
                                                           i_id_room                => NULL,
                                                           i_id_bed                 => NULL,
                                                           i_dt_begin               => l_epis_dt_begin,
                                                           i_flg_dt_begin_with_tstz => pk_alert_constant.g_no,
                                                           i_dt_discharge           => NULL,
                                                           i_anamnesis              => NULL,
                                                           i_flg_surgery            => NULL,
                                                           i_type                   => NULL,
                                                           i_dt_surgery             => NULL,
                                                           i_id_prev_episode        => i_req_episode,
                                                           i_id_external_sys        => NULL,
                                                           i_transaction_id         => l_transaction_id,
                                                           i_id_visit               => o_visit,
                                                           i_inst_dest              => i_dest_inst,
                                                           i_order_set              => i_order_set,
                                                           i_flg_compulsory         => i_flg_compulsory,
                                                           i_id_compulsory_reason   => i_id_compulsory_reason,
                                                           i_compulsory_reason      => i_compulsory_reason,
                                                           o_id_inp_episode         => io_dest_episode,
                                                           o_error                  => o_error)
            THEN
                pk_alert_exceptions.reset_error_state;
                --RAISE e_call_error;
                RETURN FALSE;
            END IF;
        ELSE
            IF l_scheduler_exists = pk_alert_constant.g_no
            THEN
                l_dt_begin := pk_date_utils.get_string_tstz(i_lang,
                                                            i_prof,
                                                            nvl(i_dt_sched_period_start, l_timestamp_str),
                                                            NULL);
                g_error    := 'UPDATE EPISODE';
                pk_alertlog.log_debug(g_error);
                ts_episode.upd(id_episode_in            => io_dest_episode,
                               dt_begin_tstz_nin        => FALSE,
                               dt_begin_tstz_in         => l_dt_begin,
                               flg_compulsory_in        => i_flg_compulsory,
                               flg_compulsory_nin       => FALSE,
                               id_compulsory_reason_in  => i_id_compulsory_reason,
                               id_compulsory_reason_nin => FALSE,
                               compulsory_reason_in     => i_compulsory_reason,
                               compulsory_reason_nin    => FALSE,
                               rows_out                 => l_rowids);
            
                g_error := 'PROCESS UPDATE';
                pk_alertlog.log_debug(g_error);
                t_data_gov_mnt.process_update(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_table_name => 'EPISODE',
                                              i_rowids     => l_rowids,
                                              o_error      => o_error);
            ELSE
                g_error := 'UPDATE EPISODE';
                pk_alertlog.log_debug(g_error);
                ts_episode.upd(id_episode_in            => io_dest_episode,
                               flg_compulsory_in        => i_flg_compulsory,
                               flg_compulsory_nin       => FALSE,
                               id_compulsory_reason_in  => i_id_compulsory_reason,
                               id_compulsory_reason_nin => FALSE,
                               compulsory_reason_in     => i_compulsory_reason,
                               compulsory_reason_nin    => FALSE,
                               rows_out                 => l_rowids);
            
                g_error := 'PROCESS UPDATE';
                pk_alertlog.log_debug(g_error);
                t_data_gov_mnt.process_update(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_table_name => 'EPISODE',
                                              i_rowids     => l_rowids,
                                              o_error      => o_error);
            END IF;
        END IF;
    
        IF o_visit IS NULL
        THEN
            g_error := 'GET VISIT. io_dest_episode: ' || io_dest_episode;
            pk_alertlog.log_info(text => g_error, object_name => g_pck_name, sub_object_name => l_func_name);
            SELECT epis.id_visit
              INTO o_visit
              FROM episode epis
             WHERE epis.id_episode = io_dest_episode;
        END IF;
        /*END IF;*/
        l_id_nit_req                       := l_adm_request_rec_old.id_nit_req;
        l_adm_request_rec.flg_nit          := nvl(i_flg_nit, pk_alert_constant.g_no);
        l_adm_request_rec.dt_nit_suggested := i_dt_nit_suggested;
        l_adm_request_rec.id_nit_dcs       := i_nit_dcs;
    
        g_error := 'NURSE INTAKE SETUP';
        pk_alertlog.log_info(text => g_error, object_name => g_pck_name, sub_object_name => l_func_name);
        IF (l_adm_request_rec.flg_nit = pk_alert_constant.g_yes)
        THEN
            -- Nurse intake needed
            IF (nvl(l_adm_request_rec_old.flg_nit, pk_alert_constant.g_no) = pk_alert_constant.g_no)
               OR (l_adm_request_rec_old.dt_nit_suggested IS NULL)
               OR (l_adm_request_rec_old.id_nit_dcs IS NULL)
            THEN
                -- Nurse intake was set to needed
                l_flg_edit := g_flg_new;
            ELSIF (pk_date_utils.compare_dates_tsz(i_prof,
                                                   l_adm_request_rec.dt_nit_suggested,
                                                   l_adm_request_rec_old.dt_nit_suggested) != 'E')
                  OR (l_adm_request_rec.id_nit_dcs != l_adm_request_rec_old.id_nit_dcs)
            THEN
                -- Nurse intake was already needed but dates were changed
                l_flg_edit := g_flg_edit;
            ELSIF ((l_adm_request_rec.dt_nit_suggested IS NULL) OR (l_adm_request_rec.id_nit_dcs IS NULL))
            THEN
                l_flg_edit := g_flg_remove;
            END IF;
        ELSIF (l_adm_request_rec_old.flg_nit = pk_alert_constant.g_yes)
        THEN
            -- Nurse intake was set to not needed
            l_flg_edit := g_flg_remove;
        END IF;
    
        IF ((l_flg_edit IN (g_flg_new, g_flg_edit)) AND (l_adm_request_rec.dt_nit_suggested IS NOT NULL) AND
           (l_adm_request_rec.id_nit_dcs IS NOT NULL))
           OR ((l_flg_edit = g_flg_remove) AND (l_adm_request_rec_old.id_nit_req IS NOT NULL))
        THEN
            g_error := 'CALL set_nurse_schedule';
            pk_alertlog.log_info(text => g_error, object_name => g_pck_name, sub_object_name => l_func_name);
            -- Action needed to nurse intake request
            IF NOT set_nurse_schedule(i_lang             => i_lang,
                                      i_prof             => i_prof,
                                      i_patient          => i_patient,
                                      i_episode          => io_dest_episode, --i_req_episode, SM(17/09/2009): ALERT-41812
                                      i_flg_edit         => l_flg_edit,
                                      i_dep_clin_serv    => l_adm_request_rec.id_nit_dcs,
                                      i_dt_scheduled_str => pk_date_utils.date_send_tsz(i_lang,
                                                                                        l_adm_request_rec.dt_nit_suggested,
                                                                                        i_prof),
                                      io_consult_req     => l_id_nit_req,
                                      o_error            => o_error)
            THEN
                RAISE e_call_error;
            END IF;
            NULL;
        END IF;
    
        l_adm_request_rec.id_adm_indication := i_adm_indication;
        IF i_adm_indication = g_reason_admission_ft
        THEN
            l_adm_request_rec.adm_indication_ft := i_adm_ind_desc;
        END IF;
        l_adm_request_rec.id_dest_inst           := i_dest_inst;
        l_adm_request_rec.id_department          := i_department;
        l_adm_request_rec.id_dep_clin_serv       := i_dep_clin_serv;
        l_adm_request_rec.id_room_type           := i_room_type;
        l_adm_request_rec.id_pref_room           := i_pref_room;
        l_adm_request_rec.id_dest_prof           := i_dest_prof;
        l_adm_request_rec.id_mrp                 := i_id_mrp;
        l_adm_request_rec.id_written_by          := i_id_written_by;
        l_adm_request_rec.id_prof_speciality_adm := i_ri_prof_spec;
    
        IF l_adm_request_rec.id_dest_inst = l_adm_request_rec_old.id_dest_inst
        THEN
            -- If we're just changing departments or services use a service transfer
            IF nvl(l_adm_request_rec.id_dep_clin_serv, -1) != nvl(l_adm_request_rec_old.id_dep_clin_serv, -1)
               OR nvl(l_adm_request_rec.id_department, -1) != nvl(l_adm_request_rec_old.id_department, -1)
               OR nvl(l_adm_request_rec.id_dest_prof, -1) != nvl(l_adm_request_rec_old.id_dest_prof, -1)
            THEN
                g_error := 'SERVICE TRANSFER - GET CS';
                pk_alertlog.log_info(text => g_error, object_name => g_pck_name, sub_object_name => l_func_name);
                BEGIN
                    SELECT dcs.id_clinical_service
                      INTO l_clinical_service
                      FROM dep_clin_serv dcs
                     WHERE dcs.id_dep_clin_serv = l_adm_request_rec.id_dep_clin_serv;
                EXCEPTION
                    WHEN no_data_found THEN
                        l_clinical_service := NULL;
                END;
            
                g_error := 'SERVICE TRANSFER - INSERT TRANSFER';
                pk_alertlog.log_info(text => g_error, object_name => g_pck_name, sub_object_name => l_func_name);
                IF NOT pk_hand_off.insert_transfer_no_commit(i_lang               => i_lang,
                                                             i_id_episode         => io_dest_episode,
                                                             i_id_patient         => i_patient,
                                                             i_prof               => i_prof,
                                                             i_id_department_orig => l_adm_request_rec_old.id_department,
                                                             i_id_department_dest => l_adm_request_rec.id_department,
                                                             i_id_prof_dest       => l_adm_request_rec.id_dest_prof,
                                                             i_dt_trf_requested   => l_timestamp_str,
                                                             i_trf_reason         => '',
                                                             i_notes              => '',
                                                             i_clinical_service   => l_clinical_service,
                                                             o_id_epis_prof_resp  => l_epis_prof_resp,
                                                             o_error              => o_error)
                THEN
                    RAISE e_call_error;
                END IF;
            
                g_error := 'SERVICE TRANSFER - UPDATE TRANSFER';
                pk_alertlog.log_info(text => g_error, object_name => g_pck_name, sub_object_name => l_func_name);
                IF NOT pk_hand_off.update_transfer_no_commit(i_lang               => i_lang,
                                                             i_id_episode         => io_dest_episode,
                                                             i_id_patient         => i_patient,
                                                             i_id_epis_prof_resp  => l_epis_prof_resp,
                                                             i_prof               => i_prof,
                                                             i_id_department_dest => NULL,
                                                             i_id_prof_dest       => NULL,
                                                             i_dt_trf_accepted    => l_timestamp_str,
                                                             i_trf_answer         => '',
                                                             i_notes              => '',
                                                             i_cancel_notes       => '',
                                                             i_flg_status         => 'X',
                                                             i_id_room            => NULL,
                                                             i_id_bed             => NULL,
                                                             i_flg_movement       => 'N',
                                                             i_type_mov           => NULL,
                                                             i_escort             => NULL,
                                                             i_id_dep_clin_serv   => NULL,
                                                             i_id_cancel_reason   => NULL,
                                                             o_error              => o_error)
                THEN
                    RAISE e_call_error;
                END IF;
            END IF;
        
        END IF;
        g_error := 'SET PROFESSIONAL';
        pk_alertlog.log_info(text => g_error, object_name => g_pck_name, sub_object_name => l_func_name);
        IF i_order_set != pk_alert_constant.g_yes
        THEN
            IF NOT set_professional(i_lang,
                                    i_prof,
                                    i_waiting_list,
                                    io_dest_episode,
                                    l_adm_request_rec.id_dest_prof,
                                    o_error)
            THEN
                RAISE e_call_error;
            END IF;
        END IF;
    
        l_default_mixed := pk_sysconfig.get_config('FLG_MIXED_NURSING', i_prof);
    
        l_adm_request_rec.flg_compulsory       := i_flg_compulsory;
        l_adm_request_rec.id_compulsory_reason := i_id_compulsory_reason;
        l_adm_request_rec.compulsory_reason    := i_compulsory_reason;
        l_adm_request_rec.id_admission_type    := i_adm_type;
        l_adm_request_rec.expected_duration    := i_expect_duration;
        l_adm_request_rec.id_adm_preparation   := i_adm_preparation;
        l_adm_request_rec.flg_mixed_nursing    := nvl(i_mixed_nursing, l_default_mixed);
        l_adm_request_rec.id_bed_type          := i_bed_type;
        l_adm_request_rec.id_upd_inst          := i_prof.institution;
        l_adm_request_rec.id_nit_req           := l_id_nit_req;
        l_adm_request_rec.id_dest_episode      := io_dest_episode;
        l_adm_request_rec.notes                := i_notes;
        l_adm_request_rec.flg_regim            := i_regimen;
        l_adm_request_rec.flg_benefi           := i_beneficiario;
        l_adm_request_rec.flg_precauc          := i_precauciones;
        l_adm_request_rec.flg_contact          := i_contactado;
    
        g_error := 'SET STATUS';
        pk_alertlog.log_info(text => g_error, object_name => g_pck_name, sub_object_name => l_func_name);
        IF i_order_set != pk_alert_constant.g_yes
        THEN
            IF NOT get_status(i_lang, i_prof, l_adm_request_rec, i_waiting_list, l_adm_request_rec.flg_status, o_error)
            THEN
                RAISE e_call_error;
            END IF;
        ELSE
            l_adm_request_rec.flg_status := pk_admission_request.g_flg_status_pd;
        END IF;
    
        g_error := 'CHECK CHANGES';
        pk_alertlog.log_info(text => g_error, object_name => g_pck_name, sub_object_name => l_func_name);
        l_not_changed := check_changes(i_lang, i_prof, l_adm_request_rec, l_adm_request_rec_old);
    
        IF NOT l_not_changed
        THEN
            g_error := 'CHANGED';
            pk_alertlog.log_info(text => g_error, object_name => g_pck_name, sub_object_name => l_func_name);
            l_adm_request_rec.id_upd_episode := i_req_episode;
        
            l_adm_request_rec.id_upd_prof := i_prof.id;
        
            l_adm_request_rec.dt_upd := l_timestamp;
        
            l_adm_request_rec.id_upd_inst := i_prof.institution;
        
            IF l_found
            THEN
                g_error := 'UPDATE ts_adm_request';
                pk_alertlog.log_info(text => g_error, object_name => g_pck_name, sub_object_name => l_func_name);
                ts_adm_request.upd(id_adm_request_in          => l_adm_request_rec.id_adm_request,
                                   id_adm_indication_in       => l_adm_request_rec.id_adm_indication,
                                   id_adm_indication_nin      => FALSE,
                                   id_dest_episode_in         => l_adm_request_rec.id_dest_episode,
                                   id_dest_episode_nin        => FALSE,
                                   id_dest_prof_in            => l_adm_request_rec.id_dest_prof,
                                   id_dest_prof_nin           => FALSE,
                                   id_dest_inst_in            => l_adm_request_rec.id_dest_inst,
                                   id_dest_inst_nin           => FALSE,
                                   id_department_in           => l_adm_request_rec.id_department,
                                   id_department_nin          => FALSE,
                                   id_dep_clin_serv_in        => l_adm_request_rec.id_dep_clin_serv,
                                   id_dep_clin_serv_nin       => FALSE,
                                   id_room_type_in            => l_adm_request_rec.id_room_type,
                                   id_room_type_nin           => FALSE,
                                   id_pref_room_in            => l_adm_request_rec.id_pref_room,
                                   id_pref_room_nin           => FALSE,
                                   id_admission_type_in       => l_adm_request_rec.id_admission_type,
                                   id_admission_type_nin      => FALSE,
                                   expected_duration_in       => l_adm_request_rec.expected_duration,
                                   expected_duration_nin      => FALSE,
                                   id_adm_preparation_in      => l_adm_request_rec.id_adm_preparation,
                                   id_adm_preparation_nin     => FALSE,
                                   flg_mixed_nursing_in       => l_adm_request_rec.flg_mixed_nursing,
                                   flg_mixed_nursing_nin      => FALSE,
                                   id_bed_type_in             => l_adm_request_rec.id_bed_type,
                                   id_bed_type_nin            => FALSE,
                                   dt_admission_in            => l_adm_request_rec.dt_admission,
                                   dt_admission_nin           => FALSE,
                                   flg_nit_in                 => l_adm_request_rec.flg_nit,
                                   flg_nit_nin                => FALSE,
                                   dt_nit_suggested_in        => l_adm_request_rec.dt_nit_suggested,
                                   dt_nit_suggested_nin       => FALSE,
                                   id_nit_dcs_in              => l_adm_request_rec.id_nit_dcs,
                                   id_nit_dcs_nin             => FALSE,
                                   id_nit_req_in              => l_adm_request_rec.id_nit_req,
                                   id_nit_req_nin             => FALSE,
                                   notes_in                   => l_adm_request_rec.notes,
                                   notes_nin                  => FALSE,
                                   flg_status_in              => l_adm_request_rec.flg_status,
                                   flg_status_nin             => FALSE,
                                   id_upd_episode_in          => l_adm_request_rec.id_upd_episode,
                                   id_upd_episode_nin         => FALSE,
                                   id_upd_prof_in             => l_adm_request_rec.id_upd_prof,
                                   id_upd_prof_nin            => FALSE,
                                   id_upd_inst_in             => l_adm_request_rec.id_upd_inst,
                                   id_upd_inst_nin            => FALSE,
                                   dt_upd_in                  => l_adm_request_rec.dt_upd,
                                   dt_upd_nin                 => FALSE,
                                   flg_regim_in               => l_adm_request_rec.flg_regim,
                                   flg_regim_nin              => FALSE,
                                   flg_benefi_in              => l_adm_request_rec.flg_benefi,
                                   flg_benefi_nin             => FALSE,
                                   flg_contact_in             => l_adm_request_rec.flg_contact,
                                   flg_contact_nin            => FALSE,
                                   flg_precauc_in             => l_adm_request_rec.flg_precauc,
                                   flg_precauc_nin            => FALSE,
                                   adm_indication_ft_in       => l_adm_request_rec.adm_indication_ft,
                                   adm_indication_ft_nin      => FALSE,
                                   id_mrp_in                  => l_adm_request_rec.id_mrp,
                                   id_mrp_nin                 => FALSE,
                                   id_written_by_in           => l_adm_request_rec.id_written_by,
                                   id_written_by_nin          => FALSE,
                                   flg_compulsory_in          => l_adm_request_rec.flg_compulsory,
                                   flg_compulsory_nin         => FALSE,
                                   id_prof_speciality_adm_in  => i_ri_prof_spec,
                                   id_prof_speciality_adm_nin => FALSE,
                                   id_compulsory_reason_in    => l_adm_request_rec.id_compulsory_reason,
                                   id_compulsory_reason_nin   => FALSE,
                                   compulsory_reason_in       => l_adm_request_rec.compulsory_reason,
                                   compulsory_reason_nin      => FALSE,
                                   rows_out                   => o_rows);
            
                --because it is necessary that the admission request event is raised only after the records being inserted in the wtl_epis table
                --because of the insertion in the task_timeline_ea table
                g_error := 'i_flg_process_event: ' || i_flg_process_event;
                pk_alertlog.log_info(text => g_error, object_name => g_pck_name, sub_object_name => l_func_name);
                IF (i_flg_process_event = pk_alert_constant.g_yes)
                THEN
                    g_error := 'PROCESS ADM_REQUEST UPD';
                    pk_alertlog.log_info(text => g_error, object_name => g_pck_name, sub_object_name => l_func_name);
                    t_data_gov_mnt.process_update(i_lang, i_prof, 'ADM_REQUEST', o_rows, o_error);
                    l_rows := table_varchar();
                
                END IF;
                o_flg_ins_upd := g_update;
            
                g_error := 'SET ADM REQ HIST';
                pk_alertlog.log_info(text => g_error, object_name => g_pck_name, sub_object_name => l_func_name);
                ts_adm_request_hist.ins(id_adm_request_in       => l_adm_request_rec_old.id_adm_request,
                                        id_adm_indication_in    => l_adm_request_rec_old.id_adm_indication,
                                        id_dest_episode_in      => l_adm_request_rec_old.id_dest_episode,
                                        id_dest_prof_in         => l_adm_request_rec_old.id_dest_prof,
                                        id_dest_inst_in         => l_adm_request_rec_old.id_dest_inst,
                                        id_department_in        => l_adm_request_rec_old.id_department,
                                        id_dep_clin_serv_in     => l_adm_request_rec_old.id_dep_clin_serv,
                                        id_room_type_in         => l_adm_request_rec_old.id_room_type,
                                        id_pref_room_in         => l_adm_request_rec_old.id_pref_room,
                                        id_admission_type_in    => l_adm_request_rec_old.id_admission_type,
                                        expected_duration_in    => l_adm_request_rec_old.expected_duration,
                                        id_adm_preparation_in   => l_adm_request_rec_old.id_adm_preparation,
                                        flg_mixed_nursing_in    => l_adm_request_rec_old.flg_mixed_nursing,
                                        id_bed_type_in          => l_adm_request_rec_old.id_bed_type,
                                        dt_admission_in         => l_adm_request_rec_old.dt_admission,
                                        flg_nit_in              => l_adm_request_rec_old.flg_nit,
                                        dt_nit_suggested_in     => l_adm_request_rec_old.dt_nit_suggested,
                                        id_nit_dcs_in           => l_adm_request_rec_old.id_nit_dcs,
                                        id_nit_req_in           => l_adm_request_rec_old.id_nit_req,
                                        notes_in                => l_adm_request_rec_old.notes,
                                        flg_status_in           => l_adm_request_rec_old.flg_status,
                                        id_upd_episode_in       => l_adm_request_rec_old.id_upd_episode,
                                        id_upd_prof_in          => l_adm_request_rec_old.id_upd_prof,
                                        dt_upd_in               => l_adm_request_rec_old.dt_upd,
                                        id_upd_inst_in          => l_adm_request_rec_old.id_upd_inst,
                                        flg_regim_in            => l_adm_request_rec_old.flg_regim,
                                        flg_benefi_in           => l_adm_request_rec_old.flg_benefi,
                                        flg_contact_in          => l_adm_request_rec_old.flg_contact,
                                        flg_precauc_in          => l_adm_request_rec_old.flg_precauc,
                                        flg_compulsory_in       => l_adm_request_rec_old.flg_compulsory,
                                        id_compulsory_reason_in => l_adm_request_rec_old.id_compulsory_reason,
                                        compulsory_reason_in    => l_adm_request_rec_old.compulsory_reason,
                                        rows_out                => l_rows);
                t_data_gov_mnt.process_insert(i_lang, i_prof, 'ADM_REQUEST_HIST', l_rows, o_error);
                l_rows := table_varchar();
            
                --Call ALERT_INTER event update
                alert_inter.pk_ia_event_schedule.inp_admission_req_update(i_id_institution => i_prof.institution,
                                                                          i_id_adm_request => l_adm_request_rec.id_adm_request);
            ELSE
                g_error := 'INSERT ts_adm_request';
                pk_alertlog.log_info(text => g_error, object_name => g_pck_name, sub_object_name => l_func_name);
                ts_adm_request.ins(id_adm_request_in         => l_adm_request_rec.id_adm_request,
                                   id_adm_indication_in      => l_adm_request_rec.id_adm_indication,
                                   id_dest_episode_in        => l_adm_request_rec.id_dest_episode,
                                   id_dest_prof_in           => l_adm_request_rec.id_dest_prof,
                                   id_dest_inst_in           => l_adm_request_rec.id_dest_inst,
                                   id_department_in          => l_adm_request_rec.id_department,
                                   id_dep_clin_serv_in       => l_adm_request_rec.id_dep_clin_serv,
                                   id_room_type_in           => l_adm_request_rec.id_room_type,
                                   id_pref_room_in           => l_adm_request_rec.id_pref_room,
                                   id_admission_type_in      => l_adm_request_rec.id_admission_type,
                                   expected_duration_in      => l_adm_request_rec.expected_duration,
                                   id_adm_preparation_in     => l_adm_request_rec.id_adm_preparation,
                                   flg_mixed_nursing_in      => l_adm_request_rec.flg_mixed_nursing,
                                   id_bed_type_in            => l_adm_request_rec.id_bed_type,
                                   dt_admission_in           => l_adm_request_rec.dt_admission,
                                   flg_nit_in                => l_adm_request_rec.flg_nit,
                                   dt_nit_suggested_in       => l_adm_request_rec.dt_nit_suggested,
                                   id_nit_dcs_in             => l_adm_request_rec.id_nit_dcs,
                                   id_nit_req_in             => l_adm_request_rec.id_nit_req,
                                   notes_in                  => l_adm_request_rec.notes,
                                   flg_status_in             => l_adm_request_rec.flg_status,
                                   id_upd_episode_in         => l_adm_request_rec.id_upd_episode,
                                   id_upd_prof_in            => l_adm_request_rec.id_upd_prof,
                                   id_upd_inst_in            => l_adm_request_rec.id_upd_inst,
                                   dt_upd_in                 => l_adm_request_rec.dt_upd,
                                   flg_regim_in              => l_adm_request_rec.flg_regim,
                                   flg_benefi_in             => l_adm_request_rec.flg_benefi,
                                   flg_contact_in            => l_adm_request_rec.flg_contact,
                                   flg_precauc_in            => l_adm_request_rec.flg_precauc,
                                   adm_indication_ft_in      => l_adm_request_rec.adm_indication_ft,
                                   id_mrp_in                 => l_adm_request_rec.id_mrp,
                                   id_written_by_in          => l_adm_request_rec.id_written_by,
                                   flg_compulsory_in         => l_adm_request_rec.flg_compulsory,
                                   id_prof_speciality_adm_in => i_ri_prof_spec,
                                   id_compulsory_reason_in   => l_adm_request_rec.id_compulsory_reason,
                                   compulsory_reason_in      => l_adm_request_rec.compulsory_reason,
                                   rows_out                  => o_rows);
                IF (i_flg_process_event = pk_alert_constant.g_yes)
                THEN
                    g_error := 'PROCESS ADM_REQUEST INS';
                    pk_alertlog.log_info(text => g_error, object_name => g_pck_name, sub_object_name => l_func_name);
                    t_data_gov_mnt.process_insert(i_lang, i_prof, 'ADM_REQUEST', o_rows, o_error);
                END IF;
                o_flg_ins_upd := g_insert;
            
                --Call ALERT_INTER event new
                alert_inter.pk_ia_event_schedule.inp_admission_req_new(i_id_institution => i_dest_inst,
                                                                       i_id_adm_request => l_adm_request_rec.id_adm_request);
            END IF;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_pck_owner,
                                              g_pck_name,
                                              'SET_ADM_REQUEST',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_schedule_api_upstream.do_rollback(l_transaction_id);
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_adm_request;

    /********************************************************************************************
    * Checks if an admission indication is valid
    *
    * @param i_lang                       language id
    * @param i_prof                       professional, software and institution ids
    * @param i_department                 department ID
    * @param i_adm_indication             admission indication ID
    * @param o_flg_valid                  the admission indication is valid: Y - yes, N - no
    * @param o_error                      Error message
    *                    
    * @return                             true or false on success or error
    *
    * @author                             José Silva
    * @version                            1.0   
    * @since                              25-04-2009
    **********************************************************************************************/
    FUNCTION check_adm_indication
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_department     IN department.id_department%TYPE,
        i_adm_indication IN adm_indication.id_adm_indication%TYPE,
        o_flg_valid      OUT VARCHAR2,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_flg_escape adm_indication.flg_escape%TYPE;
        l_count      NUMBER;
        l_count2     NUMBER := 0;
    
    BEGIN
    
        g_error := 'GET FLG_ESCAPE';
        SELECT a.flg_escape
          INTO l_flg_escape
          FROM adm_indication a
         WHERE a.id_adm_indication = i_adm_indication;
    
        IF l_flg_escape = pk_alert_constant.g_flg_escape_a
        THEN
            o_flg_valid := pk_alert_constant.g_yes;
        ELSIF l_flg_escape IN (pk_alert_constant.g_flg_escape_n, pk_alert_constant.g_flg_escape_e)
        THEN
        
            g_error := 'CHECK ADM INDICATION DEP_CLIN_SERV';
            SELECT COUNT(0)
              INTO l_count
              FROM adm_ind_dep_clin_serv adcs
              JOIN dep_clin_serv dcs
                ON adcs.id_dep_clin_serv = dcs.id_dep_clin_serv
             WHERE adcs.flg_available = pk_alert_constant.g_yes
               AND adcs.id_adm_indication = i_adm_indication
               AND dcs.id_department = i_department;
        
            IF l_flg_escape = pk_alert_constant.g_flg_escape_e
            THEN
                g_error := 'CHECK ADM INDICATION ESCAPE DEPARTMENT';
                SELECT COUNT(0)
                  INTO l_count2
                  FROM escape_department ed
                 WHERE ed.id_department = i_department
                   AND ed.id_adm_indication = i_adm_indication;
            END IF;
        
            IF l_count + l_count2 > 0
            THEN
                o_flg_valid := pk_alert_constant.g_yes;
            ELSE
                o_flg_valid := pk_alert_constant.g_no;
            END IF;
        ELSE
            o_flg_valid := pk_alert_constant.g_no;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_pck_owner,
                                              g_pck_name,
                                              'CHECK_ADM_INDICATION',
                                              o_error);
            RETURN FALSE;
    END check_adm_indication;

    /********************************************************************************************
    * Checks if a nurse intake is configured for the selected location
    *
    * @param i_lang                       language id
    * @param i_prof                       professional, software and institution ids
    * @param i_location                   location ID
    * @param o_flg_valid                  the admission indication is valid: Y - yes, N - no
    * @param o_nit_dcs                    id_dep_clin_serv for the nurse intake location
    * @param o_error                      Error message
    *                    
    * @return                             true or false on success or error
    *
    * @author                             Fábio Oliveira
    * @version                            1.0   
    * @since                              26-06-2009
    **********************************************************************************************/
    FUNCTION check_nit_location
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_location  IN institution.id_institution%TYPE,
        o_flg_valid OUT VARCHAR2,
        o_nit_dcs   OUT sys_config.value%TYPE,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
        l_nit_dcs sys_config.value%TYPE;
    BEGIN
        l_nit_dcs := pk_sysconfig.get_config('NURSE_INTAKE_DCS', profissional(i_prof.id, i_location, i_prof.software));
    
        -- José Brito 01/09/2009 ALERT-40365 
        o_nit_dcs := l_nit_dcs;
    
        IF l_nit_dcs IS NULL
        THEN
            o_flg_valid := pk_alert_constant.g_no;
        ELSE
            o_flg_valid := pk_alert_constant.g_yes;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_pck_owner,
                                              g_pck_name,
                                              'CHECK_NIT_LOCATION',
                                              o_error);
            RETURN FALSE;
    END check_nit_location;

    /********************************************************************************************
    * Checks if an admission indication is valid
    *
    * @param i_lang                       language id
    * @param i_prof                       professional, software and institution ids
    * @param i_room                       room ID
    * @param i_adm_indication             admission indication ID
    * @param o_adm_type                   admission type configured for the associated department
    * @param o_error                      Error message
    *                    
    * @return                             true or false on success or error
    *
    * @author                             José Silva
    * @version                            1.0   
    * @since                              25-04-2009
    **********************************************************************************************/
    FUNCTION check_room_adm_indication
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_room           IN room.id_room%TYPE,
        i_adm_indication IN adm_indication.id_adm_indication%TYPE,
        o_flg_valid      OUT VARCHAR2,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_id_department department.id_department%TYPE;
        l_exception EXCEPTION;
        l_error t_error_out;
    
    BEGIN
    
        g_error := 'GET DEPARTMENT ID';
        SELECT r.id_department
          INTO l_id_department
          FROM room r
         WHERE r.id_room = i_room;
    
        g_error := 'CALL TO CHECK_ADM_INDICATION';
        IF NOT check_adm_indication(i_lang           => i_lang,
                                    i_prof           => i_prof,
                                    i_department     => l_id_department,
                                    i_adm_indication => i_adm_indication,
                                    o_flg_valid      => o_flg_valid,
                                    o_error          => l_error)
        THEN
            RAISE l_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_exception THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error || ' / ' || l_error.err_desc,
                                              g_pck_owner,
                                              g_pck_name,
                                              'CHECK_ROOM_ADM_INDICATION',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_pck_owner,
                                              g_pck_name,
                                              'CHECK_ROOM_ADM_INDICATION',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END check_room_adm_indication;

    /********************************************************************************************
    * Gets the list of rooms for a specific department
    *
    * @param i_lang                       language id
    * @param i_prof                       professional, software and institution ids
    * @param i_department                 department ID
    * @param o_room                       room list
    * @param o_error                      Error message
    *                    
    * @return                             true or false on success or error
    *
    * @author                             José Silva
    * @version                            1.0   
    * @since                              25-04-2009
    **********************************************************************************************/
    FUNCTION get_room_list
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_department IN room.id_department%TYPE,
        o_room       OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'GET CURSOR';
        OPEN o_room FOR
            SELECT r.id_room,
                   nvl(r.desc_room, pk_translation.get_translation(i_lang, r.code_room)) desc_room,
                   r.id_room_type,
                   nvl(rt.desc_room_type, pk_translation.get_translation(i_lang, rt.code_room_type)) desc_room_type
              FROM room r
              LEFT JOIN room_type rt
                ON r.id_room_type = rt.id_room_type
              JOIN department d
                ON r.id_department = d.id_department
             WHERE r.id_department = i_department
               AND r.flg_transp = pk_alert_constant.g_available
               AND r.flg_available = pk_alert_constant.g_available
             ORDER BY r.rank, desc_room;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_pck_owner,
                                              g_pck_name,
                                              'GET_ROOM_LIST',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_room);
            RETURN FALSE;
    END get_room_list;

    /********************************************************************************************
    * Gets the list of departments for a specific institution
    *
    * @param i_lang                       language id
    * @param i_prof                       professional, software and institution ids
    * @param i_institution                institution ID
    * @param o_department                 department list
    * @param o_error                      Error message
    *                    
    * @return                             true or false on success or error
    *
    * @author                             José Silva
    * @version                            1.0   
    * @since                              25-04-2009
    **********************************************************************************************/
    FUNCTION get_department_list
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_institution IN institution.id_institution%TYPE,
        o_department  OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'GET CURSOR';
        OPEN o_department FOR
            SELECT id_department,
                   abbreviation,
                   pk_translation.get_translation(i_lang, code_department) department,
                   d.id_admission_type,
                   nvl(at.desc_admission_type, pk_translation.get_translation(i_lang, at.code_admission_type)) admission_type
              FROM department d
              LEFT OUTER JOIN admission_type at
                ON (d.id_admission_type = at.id_admission_type)
             WHERE d.id_institution = i_institution
               AND EXISTS (SELECT r.id_department
                      FROM room r
                     WHERE r.id_department = d.id_department
                       AND r.flg_transp = pk_alert_constant.g_available
                       AND r.flg_available = pk_alert_constant.g_available)
               AND instr(d.flg_type, 'I') > 0
               AND d.flg_available = pk_alert_constant.g_available
             ORDER BY rank, department;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_pck_owner,
                                              g_pck_name,
                                              'GET_DEPARTMENT_LIST',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_department);
            RETURN FALSE;
    END get_department_list;

    /*******************************************************************************************************************************************
    * GET_DURATION                    Returns admission request expected duration in format days(d) hours(h).
    * 
    * @param I_LANG                   Language ID for translations
    * @param I_DURATION               Surgery duration in hours
    * 
    * @return                         Returns one string with duration in hours
    * 
    * @author                         Luís Maia
    * @version                        1.0
    * @since                          2009/04/28
    *******************************************************************************************************************************************/
    FUNCTION get_duration
    (
        i_lang      IN language.id_language%TYPE,
        i_durantion IN schedule_sr.duration%TYPE
    ) RETURN VARCHAR2 IS
        --
        l_num_days  NUMBER(24) := 0;
        l_num_hours NUMBER(24) := 0;
        --
        l_desc_hours     VARCHAR2(20);
        l_duration_str   VARCHAR2(30);
        l_total_num_hour NUMBER(24) := 24;
        l_hour_sign      VARCHAR2(30) := '';
    
    BEGIN
    
        -- Get number of days
        g_error    := 'GET DAYS';
        l_num_days := floor(i_durantion / l_total_num_hour);
    
        -- Get number of hours
        g_error     := 'GET HOURS';
        l_num_hours := MOD(i_durantion, l_total_num_hour);
    
        -- Get string with number of hours (if necessary puts an zero in the left)
        IF ((l_num_hours IS NULL) OR (l_num_hours = 0 AND l_num_days = 0))
        THEN
            RETURN '';
        
        ELSIF l_num_hours BETWEEN 1 AND 10
              AND l_num_days > 0
        THEN
            l_desc_hours := '0' || l_num_hours;
        ELSIF l_num_hours = 0
              AND l_num_days > 0
        THEN
            l_desc_hours := '';
        ELSE
        
            l_desc_hours := l_num_hours;
        END IF;
    
        IF l_num_hours > 0
           OR l_num_days = 0
        THEN
            l_hour_sign := pk_message.get_message(i_lang, 'HOURS_SIGN');
        END IF;
    
        -- Get string with number of days and hours
        IF l_num_days > 1
        THEN
            l_duration_str := l_num_days || pk_message.get_message(i_lang, 'COMMON_M093') || ' ' || l_desc_hours ||
                              l_hour_sign;
        ELSIF l_num_days = 1
        THEN
            l_duration_str := l_num_days || pk_message.get_message(i_lang, 'COMMON_M092') || ' ' || l_desc_hours ||
                              l_hour_sign;
        ELSE
            l_duration_str := l_desc_hours || l_hour_sign;
        END IF;
    
        --
        RETURN l_duration_str;
    END get_duration;

    FUNCTION get_duration_unit_measure_ds
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_hours        IN adm_request.expected_duration%TYPE,
        i_date         IN adm_request.dt_admission%TYPE, --Value is sent in minutes
        o_value        OUT NUMBER,
        o_unit_measure OUT unit_measure.id_unit_measure%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_value_mod  NUMBER;
        l_hours_year NUMBER;
        l_hours_week NUMBER := 168;
        l_hours_day  NUMBER := 24;
        l_hours      NUMBER := 1;
    
        --Convert the input minutes in hours
        l_input_hours NUMBER := i_hours / 60;
    
    BEGIN
    
        SELECT (add_months(trunc(i_date, 'YEAR'), 12) - trunc(i_date, 'YEAR')) * 24
          INTO l_hours_year
          FROM dual;
    
        -- verify is a year
        IF l_input_hours >= l_hours_year
        THEN
        
            SELECT MOD(l_input_hours, l_hours_year)
              INTO l_value_mod
              FROM dual;
            IF l_value_mod = 0
            THEN
                o_value        := l_input_hours / l_hours_year;
                o_unit_measure := 10373;
                RETURN TRUE;
            END IF;
        
        END IF;
    
        -- verify week
        IF l_input_hours >= l_hours_week
        THEN
        
            SELECT MOD(l_input_hours, l_hours_week)
              INTO l_value_mod
              FROM dual;
            IF l_value_mod = 0
            THEN
                o_value        := l_input_hours / l_hours_week;
                o_unit_measure := 10375;
                RETURN TRUE;
            
            END IF;
        
        END IF;
    
        -- verify day
        IF l_input_hours >= l_hours_day
        THEN
        
            SELECT MOD(l_input_hours, l_hours_day)
              INTO l_value_mod
              FROM dual;
            IF l_value_mod = 0
            THEN
                o_value        := l_input_hours / l_hours_day;
                o_unit_measure := 1039;
                RETURN TRUE;
            END IF;
        END IF;
    
        IF l_input_hours >= l_hours
        THEN
            SELECT MOD(l_input_hours, l_hours)
              INTO l_value_mod
              FROM dual;
            IF l_value_mod = 0
            THEN
                o_value        := l_input_hours / l_hours;
                o_unit_measure := 1041;
                RETURN TRUE;
            END IF;
        END IF;
    
        -- return hour
        o_value        := i_hours;
        o_unit_measure := 10374;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN FALSE;
    END get_duration_unit_measure_ds;

    /*******************************************************************************************************************************************
    * CONCATENATE_LIST                Returns string with concatenation of an list of strings in an CURSOR
    * 
    * @param P_CURSOR                 Cursor with all data to join in the same string
    * 
    * @return                         Returns STRING with all elements of P_CURSOR concatenation if success, otherwise returns NULL
    * 
    * @author                         Luís Maia
    * @version                        1.0
    * @since                          2009/07/04
    *******************************************************************************************************************************************/
    FUNCTION concatenate_list(p_cursor IN SYS_REFCURSOR) RETURN VARCHAR2 IS
        l_return VARCHAR2(32767);
        l_temp   VARCHAR2(32767);
    BEGIN
        LOOP
            FETCH p_cursor
                INTO l_temp;
            EXIT WHEN p_cursor%NOTFOUND;
            l_return := l_return || l_temp || '; ';
        END LOOP;
        RETURN ltrim(l_return, ',');
    END;

    /*******************************************************************************************************************************************
    * GET_ALL_DIAGNOSIS_STR           Returns all diagnosis of a patient
    * 
    * @param I_LANG                   Language ID for translations
    * @param I_ID_EPISODE             Episode id that is soposed to retunr information
    * 
    * @return                         Returns STRING with all diagnosis if success, otherwise returns NULL
    * 
    * @author                         Luís Maia
    * @version                        1.0
    * @since                          2009/07/04
    *******************************************************************************************************************************************/
    FUNCTION get_all_diagnosis_str
    (
        i_lang       language.id_language%TYPE,
        i_id_episode episode.id_episode%TYPE
    ) RETURN VARCHAR2 IS
    
    BEGIN
    
        RETURN pk_diagnosis.get_epis_diagnosis(i_lang => i_lang, i_epis => i_id_episode);
    END get_all_diagnosis_str;

    FUNCTION get_sr_episode_by_inp(i_waiting_list waiting_list.id_waiting_list%TYPE) RETURN episode.id_episode%TYPE AS
        l_ret episode.id_episode%TYPE;
    BEGIN
    
        SELECT id_episode
          INTO l_ret
          FROM wtl_epis
         WHERE id_waiting_list = i_waiting_list
           AND id_epis_type = pk_alert_constant.g_epis_type_operating;
    
        RETURN l_ret;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_sr_episode_by_inp;

    /*******************************************************************************************************************************************
    * Returns admission Request episodes for a specific id patient. 
    * 
    * @param I_LANG                   Language ID for translations
    * @param I_PROF                   Professional vector of information (professional ID, institution ID, software ID)
    * @param I_ID_PATIENT             Patient id that is supposed to return information
    * @param I_FLG_CONTEXT            Grid information aggregated or not ('A' - Aggregated, 'C' - Categorized)
    * @param O_GRID_PLANNED           Cursor that returns available information for current patient which admissions are planned
    * @param O_GRID_EMERGENT          Cursor that returns available information for current patient which admissions are emergent
    * @param O_PROF_EDITABLE          Current professional can edit current request ('Y' - Yes, 'N' - No)
    * @param O_PROF_ACCESS_OK         Current professional have OK button active in main GRID ('Y' - Yes, 'N' - No)
    * @param O_ERROR                  If an error occurs, this parameter will have information about the error
    * 
    * @return                         Returns TRUE if success, otherwise returns FALSE
    * 
    * @raises                         PL/SQL generic error "OTHERS" and "user_exception"
    * 
    * @author                         António Neto
    * @version                        2.6.1
    * @since                          19-May-2011
    *******************************************************************************************************************************************/
    FUNCTION get_admission_grid_type
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_patient     IN patient.id_patient%TYPE,
        i_flg_context    IN VARCHAR2,
        o_grid_planned   OUT pk_types.cursor_type,
        o_grid_emergent  OUT pk_types.cursor_type,
        o_prof_editable  OUT VARCHAR2,
        o_prof_access_ok OUT VARCHAR2,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_func_name            VARCHAR2(30) := 'get_admission_grid_type';
        l_is_anesthesiologist  VARCHAR2(1);
        l_ar_episodes          t_tbl_ar_episodes;
        l_ar_planned_episodes  t_tbl_ar_episodes;
        l_ar_emergent_episodes t_tbl_ar_episodes;
        l_num_records          PLS_INTEGER;
        l_num_planned_records  PLS_INTEGER := 0;
        l_num_emergent_records PLS_INTEGER := 0;
        l_task_type            task_type.id_task_type%TYPE := 35;
    BEGIN
        -- Call GET_AR_EPISODES
        g_error       := 'CALL FUNCTION GET_AR_EPISODES';
        l_ar_episodes := get_ar_episodes(i_lang, i_prof, i_id_patient, NULL, NULL);
    
        --If Aggregated
        IF i_flg_context = g_flg_context_aggregated_a
        THEN
        
            g_error := 'GET CURSOR o_grid';
            OPEN o_grid_planned FOR
                SELECT rank,
                       desc_admission,
                       waiting_list_type,
                       id_waiting_list,
                       adm_needed,
                       sur_needed,
                       admiss_epis_done,
                       dt_admission,
                       duration,
                       id_episode,
                       id_dest_inst,
                       flg_status,
                       nurse_intake_status,
                       oris_status,
                       admiss_status,
                       adm_type,
                       adm_status,
                       inst_adm_name,
                       id_inst_adm,
                       adm_type_icon,
                       id_discharge,
                       flg_epis_status,
                       id_schedule,
                       flg_status,
                       flg_cancel,
                       pk_date_utils.dt_chr_tsz(i_lang, dt_discharge, i_prof) dt_discharge_str,
                       discharge_type,
                       id_department,
                       desc_dpt,
                       flg_request_edit,
                       (SELECT COUNT(*) - 1
                          FROM wtl_unav un
                         WHERE un.id_waiting_list = t_grid.id_waiting_list) unav_number,
                       l_task_type task_type,
                       pk_sr_pos.check_pos_status(i_lang, i_prof, get_sr_episode_by_inp(t_grid.id_waiting_list)) check_pos_status
                  FROM TABLE(l_ar_episodes) t_grid
                 ORDER BY rank, admiss_status DESC, dt_admission;
        
            pk_types.open_my_cursor(o_grid_emergent);
        
            --If Categorized
        ELSE
            l_num_records          := l_ar_episodes.count;
            l_ar_planned_episodes  := t_tbl_ar_episodes();
            l_ar_emergent_episodes := t_tbl_ar_episodes();
        
            FOR i IN 1 .. l_num_records
            LOOP
                IF l_ar_episodes(i).adm_type != pk_alert_constant.g_no
                THEN
                    l_num_planned_records := l_num_planned_records + 1;
                    l_ar_planned_episodes.extend;
                    l_ar_planned_episodes(l_num_planned_records) := l_ar_episodes(i);
                ELSE
                    l_num_emergent_records := l_num_emergent_records + 1;
                    l_ar_emergent_episodes.extend;
                    l_ar_emergent_episodes(l_num_emergent_records) := l_ar_episodes(i);
                END IF;
            END LOOP;
        
            OPEN o_grid_planned FOR
                SELECT rank,
                       desc_admission,
                       waiting_list_type,
                       id_waiting_list,
                       adm_needed,
                       sur_needed,
                       admiss_epis_done,
                       dt_admission,
                       duration,
                       id_episode,
                       id_dest_inst,
                       flg_status,
                       nurse_intake_status,
                       oris_status,
                       admiss_status,
                       adm_type,
                       adm_status,
                       inst_adm_name,
                       id_inst_adm,
                       adm_type_icon,
                       id_discharge,
                       flg_epis_status,
                       id_schedule,
                       flg_status,
                       flg_cancel,
                       pk_date_utils.dt_chr_tsz(i_lang, dt_discharge, i_prof) dt_discharge_str,
                       discharge_type,
                       id_department,
                       desc_dpt,
                       flg_request_edit,
                       (SELECT COUNT(*) - 1
                          FROM wtl_unav un
                         WHERE un.id_waiting_list = t_grid.id_waiting_list) unav_number,
                       l_task_type task_type,
                       pk_sr_pos.check_pos_status(i_lang, i_prof, get_sr_episode_by_inp(t_grid.id_waiting_list)) check_pos_status
                  FROM TABLE(l_ar_planned_episodes) t_grid
                 ORDER BY rank, admiss_status DESC, dt_admission;
        
            OPEN o_grid_emergent FOR
                SELECT rank,
                       desc_admission,
                       waiting_list_type,
                       id_waiting_list,
                       adm_needed,
                       sur_needed,
                       admiss_epis_done,
                       dt_admission,
                       duration,
                       id_episode,
                       id_dest_inst,
                       flg_status,
                       nurse_intake_status,
                       oris_status,
                       admiss_status,
                       adm_type,
                       adm_status,
                       inst_adm_name,
                       id_inst_adm,
                       adm_type_icon,
                       id_discharge,
                       flg_epis_status,
                       id_schedule,
                       flg_status,
                       flg_cancel,
                       pk_date_utils.dt_chr_tsz(i_lang, dt_discharge, i_prof) dt_discharge_str,
                       discharge_type,
                       id_department,
                       desc_dpt,
                       (SELECT COUNT(*) - 1
                          FROM wtl_unav un
                         WHERE un.id_waiting_list = t_grid.id_waiting_list) unav_number
                  FROM TABLE(l_ar_emergent_episodes) t_grid
                 ORDER BY rank, admiss_status DESC, dt_admission;
        END IF;
    
        -- Check if current professional is an anesthesiologist and if he/she has permissions to edit current surgery/admission request
        g_error := 'CALL TO PK_SURGERY_REQUEST.CHECK_EDIT_PERMISSIONS';
        IF NOT pk_surgery_request.check_edit_permissions(i_lang                => i_lang,
                                                         i_prof                => i_prof,
                                                         i_type_request        => g_admission_type_req,
                                                         o_is_anesthesiologist => l_is_anesthesiologist,
                                                         o_prof_editable       => o_prof_editable,
                                                         o_prof_access_ok      => o_prof_access_ok,
                                                         o_error               => o_error)
        THEN
            l_is_anesthesiologist := pk_alert_constant.g_no;
            o_prof_editable       := pk_alert_constant.g_no;
            o_prof_access_ok      := pk_alert_constant.g_no;
        END IF;
    
        --
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.reset_error_state;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_pck_owner,
                                              g_pck_name,
                                              l_func_name,
                                              o_error);
            pk_types.open_my_cursor(o_grid_planned);
            pk_types.open_my_cursor(o_grid_emergent);
            RETURN FALSE;
    END get_admission_grid_type;

    /*******************************************************************************************************************************************
    * GET_INTAKE_STATUS_STR           Returns nurse intake to the first state collumn in Surgery grid. 
    * 
    * @param I_LANG                   Language ID for translations
    * @param I_PROF                   Professional vector of information (professional ID, institution ID, software ID)
    * @param I_SR_POS_STATUS          SR_POS_STATUS id
    * @param I_ID_WAITING_LIST        Waiting List id
    * @param O_ERROR                  If an error accurs, this parameter will have information about the error
    * 
    * @return                         Returns the status string information
    * 
    * @raises                         PL/SQL generic erro "OTHERS" and "user_exception"
    * 
    * @author                         Luís Maia
    * @version                        1.0
    * @since                          2009/04/28
    *******************************************************************************************************************************************/
    FUNCTION get_intake_status_str
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_adm_request  IN adm_request.id_adm_request%TYPE,
        i_id_waiting_list IN waiting_list.id_waiting_list%TYPE
    ) RETURN VARCHAR2 IS
        --
        l_display_type VARCHAR2(30) := '';
        l_back_color   VARCHAR2(30) := '';
        l_status_flg   VARCHAR2(30) := '';
        l_icon_color   VARCHAR2(30) := '';
        l_aux          VARCHAR2(200);
        l_date_begin   VARCHAR2(200);
        --
        l_has_nurse_intake   adm_request.flg_nit%TYPE;
        l_consult_req_status consult_req.flg_status%TYPE;
        l_dt_begin_null      VARCHAR2(1);
        l_disch_null         VARCHAR2(1);
        l_id_waiting_list    waiting_list.id_waiting_list%TYPE;
        l_id_epis_type       epis_type.id_epis_type%TYPE;
        l_dt_nit_suggested   adm_request.dt_nit_suggested%TYPE;
        l_id_nit_dcs         adm_request.id_nit_dcs%TYPE;
        l_ar_flg_status      adm_request.flg_status%TYPE;
        l_id_consult_req     consult_req.id_consult_req%TYPE;
        l_id_episode_outp    episode.id_episode%TYPE;
        --
        l_duration_str VARCHAR2(4000);
        l_error_out    t_error_out;
        --
        CURSOR c_info
        (
            l_has_nurse_intake   IN VARCHAR2,
            l_consult_req_status IN VARCHAR2,
            l_dt_begin_null      IN VARCHAR2,
            l_disch_null         IN VARCHAR2,
            l_needsfilling       IN VARCHAR2,
            l_ar_flg_status      IN VARCHAR2
        ) IS
            SELECT
            -- dt_begin
             NULL date_begin, -- It is not necessary get dates info
             -- l_aux
             decode(l_ar_flg_status,
                    pk_alert_constant.g_adm_req_status_canc,
                    'ADM_REQUEST.FLG_STATUS',
                    decode(l_has_nurse_intake,
                           pk_alert_constant.g_no,
                           'SCHEDULE_SR.ADM_NEEDED',
                           decode(l_needsfilling,
                                  pk_alert_constant.g_yes,
                                  'SCHEDULE_SR.FLG_STATUS',
                                  'ADM_REQUEST.FLG_STATUS'))) desc_stat,
             -- l_display_type
             'I' flg_text, -- There is always icons
             -- l_back_color
             decode(l_ar_flg_status,
                    pk_alert_constant.g_adm_req_status_canc,
                    NULL,
                    decode(l_has_nurse_intake,
                           pk_alert_constant.g_no,
                           NULL,
                           decode(l_needsfilling, pk_alert_constant.g_yes, pk_alert_constant.g_color_red, NULL))) color_status, -- There is no background color
             -- status_flg                      
             /*decode(l_ar_flg_status,
             pk_alert_constant.g_adm_req_status_canc,
             pk_alert_constant.g_adm_req_status_canc,*/
             decode(l_has_nurse_intake,
                    pk_alert_constant.g_no,
                    pk_alert_constant.g_no, -- NOT NEEDED
                    decode(l_needsfilling,
                           pk_alert_constant.g_yes,
                           'I',
                           decode(l_consult_req_status,
                                  pk_alert_constant.g_adm_req_status_pend,
                                  pk_alert_constant.g_adm_req_status_pend, -- Not Schedule
                                  pk_alert_constant.g_adm_req_status_canc,
                                  pk_alert_constant.g_adm_req_status_canc, -- Cancelled
                                  decode(l_disch_null,
                                         pk_alert_constant.g_no,
                                         pk_alert_constant.g_adm_req_status_done, -- DONE
                                         decode(l_dt_begin_null,
                                                pk_alert_constant.g_no,
                                                pk_alert_constant.g_adm_req_status_unde, -- Undergoing
                                                pk_alert_constant.g_adm_req_status_sche) -- Schedule
                                         )))) /*)*/ status_flg
              FROM dual;
    
    BEGIN
    
        -- Get information about nurse_intake information
        g_error := 'GET NURSE INTAKE STATUS INFORMATION';
        BEGIN
            SELECT ar.flg_nit,
                   cr.flg_status,
                   we.id_epis_type,
                   we.id_waiting_list,
                   ar.dt_nit_suggested,
                   ar.id_nit_dcs,
                   ar.flg_status,
                   cr.id_consult_req
              INTO l_has_nurse_intake,
                   l_consult_req_status,
                   l_id_epis_type,
                   l_id_waiting_list,
                   l_dt_nit_suggested,
                   l_id_nit_dcs,
                   l_ar_flg_status,
                   l_id_consult_req
              FROM adm_request ar
              LEFT JOIN consult_req cr
                ON (cr.id_consult_req = ar.id_nit_req)
             INNER JOIN wtl_epis we
                ON (we.id_episode = ar.id_dest_episode)
             WHERE ar.id_adm_request = i_id_adm_request
               AND we.id_waiting_list = i_id_waiting_list;
        EXCEPTION
            WHEN no_data_found THEN
                -- IF no data found there are not defined NURSE INTAKE
                l_has_nurse_intake := pk_alert_constant.g_no;
        END;
    
        -- Get if current episode already begun and if it as already medical and administrative discharge            
        BEGIN
            g_error := 'GET OUP EPISODE';
            SELECT ei.id_episode
              INTO l_id_episode_outp
              FROM consult_req c
              JOIN schedule s
                ON c.id_schedule = s.id_schedule
              JOIN epis_info ei
                ON ei.id_schedule = s.id_schedule
             WHERE c.id_consult_req = l_id_consult_req;
        
            BEGIN
                g_error := 'CHECK IF EPISODE HAD ALREADY BEEN REGISTERED';
                SELECT decode(epi.flg_ehr,
                              pk_alert_constant.g_epis_ehr_schedule,
                              pk_alert_constant.g_yes,
                              pk_alert_constant.g_no)
                  INTO l_dt_begin_null
                  FROM episode epi
                 WHERE epi.id_episode = l_id_episode_outp;
            EXCEPTION
                WHEN OTHERS THEN
                    l_dt_begin_null := pk_alert_constant.g_yes;
            END;
        
            BEGIN
                --check if the outp episode has discharge date
                g_error := 'CHECK IF THE OUTP EPISODE HAS A DISCHARGE DATE';
                SELECT decode(COUNT(0), 0, pk_alert_constant.g_yes, pk_alert_constant.g_no)
                  INTO l_disch_null
                  FROM nurse_discharge nd
                 WHERE nd.id_episode = l_id_episode_outp;
            EXCEPTION
                WHEN OTHERS THEN
                    l_disch_null := pk_alert_constant.g_yes;
            END;
        
            IF l_disch_null = pk_alert_constant.g_yes
            THEN
                BEGIN
                    SELECT decode(COUNT(0), 0, pk_alert_constant.g_yes, pk_alert_constant.g_no)
                      INTO l_disch_null
                      FROM episode
                     WHERE id_episode = l_id_episode_outp
                       AND flg_status = pk_alert_constant.g_inactive;
                EXCEPTION
                    WHEN OTHERS THEN
                        -- if there is no admission episode (l_disch_null = 'Y')
                        l_disch_null := pk_alert_constant.g_yes;
                END;
            END IF;
        
        EXCEPTION
            WHEN OTHERS THEN
                l_dt_begin_null := pk_alert_constant.g_yes;
                l_disch_null    := pk_alert_constant.g_yes;
        END;
    
        g_error := 'GET NURSE INTAKE STATUS STRING';
        OPEN c_info(l_has_nurse_intake,
                    l_consult_req_status,
                    l_dt_begin_null,
                    l_disch_null,
                    CASE WHEN l_dt_nit_suggested IS NULL OR l_id_nit_dcs IS NULL THEN pk_alert_constant.g_yes ELSE
                    pk_alert_constant.g_no END,
                    l_ar_flg_status);
        FETCH c_info
            INTO l_date_begin, l_aux, l_display_type, l_back_color, l_status_flg;
        CLOSE c_info;
    
        --
        l_duration_str := pk_utils.get_status_string_immediate(i_lang            => i_lang,
                                                               i_prof            => i_prof,
                                                               i_display_type    => l_display_type,
                                                               i_flg_state       => l_status_flg,
                                                               i_value_text      => l_aux,
                                                               i_value_date      => l_date_begin,
                                                               i_value_icon      => l_aux,
                                                               i_shortcut        => NULL,
                                                               i_back_color      => l_back_color,
                                                               i_icon_color      => l_icon_color,
                                                               i_message_style   => NULL,
                                                               i_message_color   => NULL,
                                                               i_flg_text_domain => NULL,
                                                               i_dt_server       => current_timestamp);
        --
        RETURN l_duration_str;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_pck_owner,
                                              g_pck_name,
                                              'GET_INTAKE_STATUS_STR',
                                              l_error_out);
            pk_alert_exceptions.raise_error(error_code_in => SQLCODE);
        
    END get_intake_status_str;

    /***************************************************************************************************************
    *
    * Cancels the entry in ADM_REQUEST after saving its previous state in ADM_REQUEST_HIST 
    * Note: related episodes must be cancelled in other functions. 
    * 
    * @param      i_lang              language ID
    * @param      i_prof              ALERT profissional 
    * @param      i_id_adm_req        ID of the record to cancel.
    * @param      o_error
    *
    *
    * @RETURN  TRUE or FALSE
    * @author  Ricardo Nuno Almeida
    * @version 1.0
    * @since   29-04-2009
    *
    ****************************************************************************************************/
    FUNCTION cancel_admission_request
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_adm_req IN adm_request.id_adm_request%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_adm_req adm_request%ROWTYPE;
        e_exp_o EXCEPTION;
        l_rows table_varchar;
    BEGIN
        g_error := 'GET ADM_REQUEST RECORD';
        SELECT ar.*
          INTO l_adm_req
          FROM adm_request ar
         WHERE ar.id_adm_request = i_id_adm_req;
    
        IF l_adm_req.flg_status IN ('C')
        THEN
            -- estados inválidos.... completar
            RAISE e_exp_o;
        END IF;
    
        IF l_adm_req.flg_nit = pk_alert_constant.g_yes
           AND l_adm_req.id_nit_req IS NOT NULL
        THEN
        
            g_error := 'CALL SET_NURSE_SCHEDULE';
            IF NOT set_nurse_schedule(i_lang             => i_lang,
                                      i_prof             => i_prof,
                                      i_patient          => NULL,
                                      i_episode          => NULL,
                                      i_flg_edit         => g_flg_remove,
                                      i_dep_clin_serv    => NULL,
                                      i_dt_scheduled_str => NULL,
                                      io_consult_req     => l_adm_req.id_nit_req,
                                      o_error            => o_error)
            THEN
            
                RETURN FALSE;
            END IF;
        
        END IF;
    
        --The previous validation allows us not to check for changes in the record.
        g_error := 'INSERT ADM_REQ HIST';
        ts_adm_request_hist.ins(id_adm_request_hist_in => ts_adm_request_hist.next_key,
                                id_adm_request_in      => l_adm_req.id_adm_request,
                                id_adm_indication_in   => l_adm_req.id_adm_indication,
                                id_dest_episode_in     => l_adm_req.id_dest_episode,
                                id_dest_prof_in        => l_adm_req.id_dest_prof,
                                id_dest_inst_in        => l_adm_req.id_dest_inst,
                                id_department_in       => l_adm_req.id_department,
                                id_dep_clin_serv_in    => l_adm_req.id_dep_clin_serv,
                                id_room_type_in        => l_adm_req.id_room_type,
                                id_pref_room_in        => l_adm_req.id_pref_room,
                                id_admission_type_in   => l_adm_req.id_admission_type,
                                expected_duration_in   => l_adm_req.expected_duration,
                                id_adm_preparation_in  => l_adm_req.id_adm_preparation,
                                flg_mixed_nursing_in   => l_adm_req.flg_mixed_nursing,
                                id_bed_type_in         => l_adm_req.id_bed_type,
                                dt_admission_in        => l_adm_req.dt_admission,
                                flg_nit_in             => l_adm_req.flg_nit,
                                dt_nit_suggested_in    => l_adm_req.dt_nit_suggested,
                                id_nit_dcs_in          => l_adm_req.id_nit_dcs,
                                id_nit_req_in          => l_adm_req.id_nit_req,
                                notes_in               => l_adm_req.notes,
                                flg_status_in          => l_adm_req.flg_status,
                                id_upd_episode_in      => l_adm_req.id_upd_episode,
                                id_upd_prof_in         => l_adm_req.id_upd_prof,
                                id_upd_inst_in         => l_adm_req.id_upd_inst,
                                dt_upd_in              => l_adm_req.dt_upd,
                                rows_out               => l_rows);
    
        g_error := 'PROCESS INSERT';
        t_data_gov_mnt.process_insert(i_lang, i_prof, 'ADM_REQUEST_HIST', l_rows, o_error);
        l_rows := table_varchar();
    
        g_error := 'UPDATE ADM_REQ';
        ts_adm_request.upd(id_adm_request_in => l_adm_req.id_adm_request,
                           flg_status_in     => g_wlt_status_c,
                           id_upd_prof_in    => i_prof.id,
                           id_upd_inst_in    => i_prof.institution,
                           dt_upd_in         => current_timestamp,
                           rows_out          => l_rows);
    
        g_error := 'PROCESS UPDATE';
        t_data_gov_mnt.process_update(i_lang, i_prof, 'ADM_REQUEST', l_rows, o_error);
    
        --Call ALERT_INTER event cancel
        alert_inter.pk_ia_event_schedule.inp_admission_req_cancel(i_id_institution => i_prof.institution,
                                                                  i_id_adm_request => l_adm_req.id_adm_request);
    
        RETURN TRUE;
    EXCEPTION
        WHEN e_exp_o THEN
            DECLARE
                l_error_in      t_error_in := t_error_in();
                l_error_message sys_message.desc_message%TYPE := pk_message.get_message(i_lang, 'ADM_REQUEST_E007');
                l_ret           BOOLEAN;
            BEGIN
                l_error_in.set_all(i_lang,
                                   'ADM_REQUEST_T060',
                                   l_error_message,
                                   g_error,
                                   g_pck_owner,
                                   g_pck_name,
                                   'CANCEL_ADMISSION_REQUEST');
            
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                pk_utils.undo_changes;
                pk_alert_exceptions.reset_error_state;
            
                RETURN FALSE;
            END;
        
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_pck_owner,
                                              g_pck_name,
                                              'CANCEL_ADMISSION_REQUEST',
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
        
            RETURN FALSE;
    END cancel_admission_request;

    FUNCTION get_adm_req_diag_ds
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_adm_request IN adm_request.id_adm_request%TYPE,
        i_flg_status  IN adm_req_diagnosis.flg_status%TYPE,
        o_diag        OUT VARCHAR2,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_id_diag            NUMBER(24);
        l_id_epis_diag       NUMBER(24);
        l_id_episode         epis_diagnosis.id_episode%TYPE;
        l_id_patient         epis_diagnosis.id_patient%TYPE;
        l_flg_type           epis_diagnosis.flg_type%TYPE;
        l_diag_desc          VARCHAR2(500 CHAR);
        l_diag_status_flg    VARCHAR2(10 CHAR);
        l_diag_status_desc   VARCHAR2(50 CHAR);
        l_diag_notes         VARCHAR2(2000 CHAR);
        l_diag_notes_general VARCHAR2(2000 CHAR);
        l_diag_flg_problem   VARCHAR2(10 CHAR);
        l_diag_flg_other     VARCHAR2(10 CHAR);
    BEGIN
        g_error := 'OPEN CURSOR';
    
        BEGIN
            SELECT ed.id_diagnosis,
                   ed.id_epis_diagnosis,
                   ed.id_episode,
                   ed.id_patient,
                   ed.flg_type,
                   pk_diagnosis.std_diag_desc(i_lang                => i_lang,
                                              i_prof                => i_prof,
                                              i_id_alert_diagnosis  => ad.id_alert_diagnosis,
                                              i_desc_epis_diagnosis => ed.desc_epis_diagnosis,
                                              i_code                => d.code_icd,
                                              i_flg_other           => d.flg_other,
                                              i_flg_std_diag        => ad.flg_icd9) diag_desc,
                   ard.flg_diag_status,
                   pk_sysdomain.get_domain('ADM_REQ_DIAGNOSIS.FLG_DIAG_STATUS', ard.flg_diag_status, i_lang) status_desc,
                   ed.notes specific_notes,
                   pk_diagnosis_core.get_epis_diag_note(i_lang           => i_lang,
                                                        i_prof           => i_prof,
                                                        i_episode        => ed.id_episode,
                                                        i_epis_diag      => ed.id_epis_diagnosis,
                                                        i_epis_diag_hist => NULL) general_notes,
                   ed.flg_add_problem,
                   d.flg_other
              INTO l_id_diag,
                   l_id_epis_diag,
                   l_id_episode,
                   l_id_patient,
                   l_flg_type,
                   l_diag_desc,
                   l_diag_status_flg,
                   l_diag_status_desc,
                   l_diag_notes,
                   l_diag_notes_general,
                   l_diag_flg_problem,
                   l_diag_flg_other
              FROM adm_req_diagnosis ard
              JOIN epis_diagnosis ed
                ON ed.id_epis_diagnosis = ard.id_epis_diagnosis
              JOIN diagnosis d
                ON (d.id_diagnosis = ed.id_diagnosis)
              LEFT OUTER JOIN alert_diagnosis ad
                ON (ad.id_alert_diagnosis = ed.id_alert_diagnosis)
              JOIN adm_request ar
                ON (ar.id_adm_request = ard.id_adm_request)
              JOIN epis_diagnosis ed
                ON (ard.id_epis_diagnosis = ed.id_epis_diagnosis AND ed.id_episode = ar.id_dest_episode)
             WHERE ard.id_adm_request = i_adm_request
               AND ard.flg_status = i_flg_status
             ORDER BY diag_desc;
        
            o_diag := '<EPIS_DIAGNOSIS INTERNAL_NAME="RI_DIAGNOSIS">' || '<PARAMETERS FLG_EDIT_MODE="E" ID_EPISODE="' ||
                      l_id_episode || '" ID_PATIENT="' || l_id_patient || '"><EPIS_DIAGNOSIS ID_EPIS_DIAGNOSIS="' ||
                      l_id_epis_diag ||
                      '" /><DS_COMPONENT FLG_COMPONENT_TYPE="N" INTERNAL_NAME="GENERAL_DIAGNOSES_CARACTERIZATION" /><DIAGNOSIS DESC_DIAGNOSIS="' ||
                      l_diag_desc || '" FLG_TYPE="' || l_flg_type || '" ID_DIAGNOSIS="' || l_id_diag ||
                      '" /></PARAMETERS>' || '<PARAMETERS FLG_EDIT_MODE="E" ID_EPISODE="' || l_id_episode ||
                      '" ID_PATIENT="' || l_id_patient || '"><EPIS_DIAGNOSIS ID_EPIS_DIAGNOSIS="' || l_id_epis_diag ||
                      '" /><DS_COMPONENT FLG_COMPONENT_TYPE="N" INTERNAL_NAME="GENERAL_DIAGNOSES_ADDITIONAL_INFO" /><DIAGNOSIS DESC_DIAGNOSIS="' ||
                      l_diag_desc || '" FLG_TYPE="' || l_flg_type || '" ID_DIAGNOSIS="' || l_id_diag ||
                      '" /></PARAMETERS>' || '</EPIS_DIAGNOSIS>';
        EXCEPTION
            WHEN no_data_found THEN
                o_diag := NULL;
            
        END;
    
        RETURN TRUE;
    
    EXCEPTION
    
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_pck_owner,
                                              g_pck_name,
                                              'GET_ADM_REQ_DIAG',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_adm_req_diag_ds;

    FUNCTION get_adm_req_diag
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_adm_request IN adm_request.id_adm_request%TYPE,
        i_flg_status  IN adm_req_diagnosis.flg_status%TYPE,
        o_diag        OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'OPEN CURSOR';
        OPEN o_diag FOR
            SELECT ed.id_diagnosis,
                   pk_diagnosis.std_diag_desc(i_lang                => i_lang,
                                              i_prof                => i_prof,
                                              i_id_alert_diagnosis  => ad.id_alert_diagnosis,
                                              i_desc_epis_diagnosis => ed.desc_epis_diagnosis,
                                              i_code                => d.code_icd,
                                              i_flg_other           => d.flg_other,
                                              i_flg_std_diag        => ad.flg_icd9) diag_desc,
                   ard.flg_diag_status,
                   pk_sysdomain.get_domain('ADM_REQ_DIAGNOSIS.FLG_DIAG_STATUS', ard.flg_diag_status, i_lang) status_desc,
                   ed.notes specific_notes,
                   pk_diagnosis_core.get_epis_diag_note(i_lang           => i_lang,
                                                        i_prof           => i_prof,
                                                        i_episode        => ed.id_episode,
                                                        i_epis_diag      => ed.id_epis_diagnosis,
                                                        i_epis_diag_hist => NULL) general_notes,
                   ed.flg_add_problem,
                   d.flg_other
              FROM adm_req_diagnosis ard
              JOIN epis_diagnosis ed
                ON ed.id_epis_diagnosis = ard.id_epis_diagnosis
              JOIN diagnosis d
                ON (d.id_diagnosis = ed.id_diagnosis)
              LEFT OUTER JOIN alert_diagnosis ad
                ON (ad.id_alert_diagnosis = ed.id_alert_diagnosis)
              JOIN adm_request ar
                ON (ar.id_adm_request = ard.id_adm_request)
              JOIN epis_diagnosis ed
                ON (ard.id_epis_diagnosis = ed.id_epis_diagnosis AND ed.id_episode = ar.id_dest_episode)
             WHERE ard.id_adm_request = i_adm_request
               AND ard.flg_status = i_flg_status
             ORDER BY diag_desc;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_pck_owner,
                                              g_pck_name,
                                              'GET_ADM_REQ_DIAG',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_diag);
            RETURN FALSE;
    END;

    FUNCTION get_adm_req_diag
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_adm_request IN adm_request.id_adm_request%TYPE,
        o_diag        OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_error := 'CALL GET_ADM_REQ_DIAG';
        IF NOT get_adm_req_diag(i_lang        => i_lang,
                                i_prof        => i_prof,
                                i_adm_request => i_adm_request,
                                i_flg_status  => pk_alert_constant.g_active,
                                o_diag        => o_diag,
                                o_error       => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_pck_owner,
                                              g_pck_name,
                                              'GET_ADM_REQ_DIAG',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_diag);
            RETURN FALSE;
    END;

    FUNCTION get_adm_req_diag_string
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_adm_request IN adm_request.id_adm_request%TYPE
    ) RETURN VARCHAR2 IS
        l_func_name          VARCHAR2(30) := 'GET_ADM_REQ_DIAG_STRING';
        l_str_aux            VARCHAR2(2000) := NULL;
        l_diag               pk_types.cursor_type;
        l_tbl_id_diags       table_number;
        l_tbl_desc_diags     table_varchar;
        l_tbl_flg_stat       table_varchar;
        l_tbl_desc_stat      table_varchar;
        l_tbl_specific_notes table_varchar;
        l_tbl_general_notes  table_varchar;
        l_flg_add_problem    table_varchar;
        l_tbl_flg_other      table_varchar;
        l_error              t_error_out;
        l_runtime_error EXCEPTION;
    BEGIN
        g_error := 'GET DIAGNOSIS';
        IF NOT pk_admission_request.get_adm_req_diag(i_lang        => i_lang,
                                                     i_prof        => i_prof,
                                                     i_adm_request => i_adm_request,
                                                     o_diag        => l_diag,
                                                     o_error       => l_error)
        THEN
            RAISE l_runtime_error;
        END IF;
    
        g_error := 'GET FETCH INTO table_varchar';
        FETCH l_diag BULK COLLECT
            INTO l_tbl_id_diags,
                 l_tbl_desc_diags,
                 l_tbl_flg_stat,
                 l_tbl_desc_stat,
                 l_tbl_specific_notes,
                 l_tbl_general_notes,
                 l_flg_add_problem,
                 l_tbl_flg_other;
        CLOSE l_diag;
    
        FOR i IN 1 .. l_tbl_id_diags.count
        LOOP
            l_str_aux := l_str_aux || l_tbl_desc_diags(i) || ' - ' || l_tbl_desc_stat(i) || '; ';
        END LOOP;
    
        RETURN l_str_aux;
    EXCEPTION
        WHEN no_data_found THEN
            RETURN NULL;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_pck_owner,
                                              g_pck_name,
                                              l_func_name,
                                              l_error);
            --            RAISE l_runtime_error;
            RETURN NULL;
    END get_adm_req_diag_string;

    FUNCTION get_adm_req_diag_string
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_adm_request IN adm_request.id_adm_request%TYPE,
        i_timestamp   IN VARCHAR2
    ) RETURN VARCHAR2 IS
        l_func_name      VARCHAR2(30) := 'GET_ADM_REQ_DIAG_STRING';
        l_str_aux        VARCHAR2(2000) := NULL;
        l_tbl_id_diags   table_number;
        l_tbl_desc_diags table_varchar;
        l_tbl_flg_stat   table_varchar;
        l_tbl_desc_stat  table_varchar;
    
        l_error t_error_out;
        l_runtime_error EXCEPTION;
    BEGIN
        g_error := 'GET FETCH INTO table_varchar';
    
        SELECT ed.id_diagnosis,
               pk_diagnosis.std_diag_desc(i_lang               => i_lang,
                                          i_prof               => i_prof,
                                          i_id_alert_diagnosis => ed.id_alert_diagnosis,
                                          i_code               => d.code_icd,
                                          i_flg_other          => d.flg_other,
                                          i_flg_std_diag       => pk_alert_constant.g_yes) diag_desc,
               ard.flg_diag_status,
               pk_sysdomain.get_domain('ADM_REQ_DIAGNOSIS.FLG_DIAG_STATUS', ard.flg_diag_status, i_lang) status_desc
          BULK COLLECT
          INTO l_tbl_id_diags, l_tbl_desc_diags, l_tbl_flg_stat, l_tbl_desc_stat
          FROM adm_req_diagnosis ard
          JOIN epis_diagnosis ed
            ON ed.id_epis_diagnosis = ard.id_epis_diagnosis
          JOIN diagnosis d
            ON (d.id_diagnosis = ed.id_diagnosis)
         WHERE ard.id_adm_request = i_adm_request
           AND ard.update_time = i_timestamp
         ORDER BY diag_desc;
    
        FOR i IN 1 .. l_tbl_id_diags.count
        LOOP
            l_str_aux := l_str_aux || l_tbl_desc_diags(i) || ' - ' || l_tbl_desc_stat(i) || '; ';
        END LOOP;
    
        RETURN l_str_aux;
    EXCEPTION
        WHEN no_data_found THEN
            RETURN NULL;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_pck_owner,
                                              g_pck_name,
                                              l_func_name,
                                              l_error);
            RAISE l_runtime_error;
    END get_adm_req_diag_string;

    FUNCTION get_admission_request_ds
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_id_episode           IN episode.id_episode%TYPE,
        i_id_waiting_list      IN waiting_list.id_waiting_list%TYPE,
        i_all                  IN VARCHAR2 DEFAULT 'Y',
        o_dt_admission         OUT adm_request.dt_admission%TYPE,
        o_id_dep_clin_serv     OUT NUMBER,
        o_desc_dep_clin_serv   OUT VARCHAR2,
        o_id_prof_spec_adm     OUT NUMBER,
        o_desc_prof_spec_adm   OUT VARCHAR2,
        o_id_adm_phys          OUT NUMBER,
        o_name_adm_phys        OUT VARCHAR2,
        o_id_mrp               OUT NUMBER,
        o_name_mrp             OUT VARCHAR2,
        o_id_written_by        OUT NUMBER,
        o_name_written_by      OUT VARCHAR2,
        o_id_compulsory        OUT VARCHAR2,
        o_desc_compulsory      OUT VARCHAR2,
        o_id_compulsory_opt    OUT VARCHAR2,
        o_desc_compulsory_opt  OUT VARCHAR2,
        o_id_adm_indication    OUT NUMBER,
        o_desc_adm_indication  OUT VARCHAR2,
        o_id_admission_type    OUT NUMBER,
        o_desc_adm_type        OUT VARCHAR2,
        o_expected_duration    OUT NUMBER,
        o_id_adm_preparation   OUT NUMBER,
        o_desc_adm_preparation OUT VARCHAR2,
        o_id_dest_inst         OUT NUMBER,
        o_desc_dest_inst       OUT VARCHAR2,
        o_id_department        OUT NUMBER,
        o_desc_depart          OUT VARCHAR2,
        o_id_room_type         OUT NUMBER,
        o_desc_room_type       OUT VARCHAR2,
        o_flg_mixed_nursing    OUT VARCHAR2,
        o_id_bed_type          OUT NUMBER,
        o_desc_bed_type        OUT VARCHAR2,
        o_id_pref_room         OUT NUMBER,
        o_dep_pref_room        OUT NUMBER,
        o_desc_pref_room       OUT VARCHAR2,
        o_flg_nit              OUT VARCHAR2,
        o_flg_nit_desc         OUT VARCHAR2,
        o_dt_nit_suggested     OUT VARCHAR2,
        o_id_nit_dcs           OUT NUMBER,
        o_nit_dt_sugg_send     OUT VARCHAR2,
        o_nit_dt_sugg_char     OUT VARCHAR2,
        o_nit_location         OUT VARCHAR2,
        o_notes                OUT VARCHAR2,
        o_diag                 OUT pk_types.cursor_type,
        o_id_regimen           OUT VARCHAR2,
        o_desc_regimen         OUT VARCHAR2,
        o_id_beneficiario      OUT VARCHAR2,
        o_desc_beneficiario    OUT VARCHAR2,
        o_id_precauciones      OUT VARCHAR2,
        o_desc_precauciones    OUT VARCHAR2,
        o_id_contactado        OUT VARCHAR2,
        o_desc_contactado      OUT VARCHAR2,
        
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(30) := 'GET_ADMISSION_REQUEST';
        l_runtime_error EXCEPTION;
    
        l_waiting_list_type waiting_list.flg_type%TYPE;
        l_id_adm_request    adm_request.id_adm_request%TYPE;
    BEGIN
        g_error := 'get waiting_list flg_type';
        SELECT w.flg_type
          INTO l_waiting_list_type
          FROM waiting_list w
         WHERE w.id_waiting_list = i_id_waiting_list;
    
        --For surgery request without admission request
        IF l_waiting_list_type = pk_alert_constant.g_wl_type_s
        THEN
            RETURN TRUE;
        END IF;
    
        g_error := 'get id_adm_request';
        BEGIN
            SELECT ar.id_adm_request
              INTO l_id_adm_request
              FROM adm_request ar
             WHERE ar.id_dest_episode = i_id_episode;
        EXCEPTION
            WHEN too_many_rows THEN
                RAISE l_runtime_error;
        END;
    
        g_error := 'fill output cursor';
        SELECT ar.dt_admission,
               ar.id_dep_clin_serv,
               pk_translation.get_translation(i_lang, cs.code_clinical_service) desc_dep_clin_serv,
               wp.id_prof id_adm_phys,
               pk_prof_utils.get_name_signature(i_lang, i_prof, wp.id_prof) name_adm_phys,
               ar.id_mrp,
               pk_prof_utils.get_name_signature(i_lang, i_prof, ar.id_mrp),
               ar.id_written_by,
               pk_prof_utils.get_name_signature(i_lang, i_prof, ar.id_written_by),
               ar.flg_compulsory,
               pk_sysdomain.get_domain('ADM_REQUEST.FLG_MIXED_NURSING', ar.flg_compulsory, i_lang),
               ar.id_compulsory_reason,
               decode(ar.id_compulsory_reason,
                      NULL,
                      NULL,
                      -1,
                      ar.compulsory_reason,
                      pk_multichoice.get_multichoice_option_desc(i_lang      => i_lang,
                                                                 i_prof      => i_prof,
                                                                 i_id_option => ar.id_compulsory_reason)) compulsory_reason,
               ar.id_adm_indication,
               decode(ar.id_adm_indication,
                      g_reason_admission_ft,
                      ar.adm_indication_ft,
                      nvl(ai.desc_adm_indication, pk_translation.get_translation(i_lang, ai.code_adm_indication))) desc_adm_indication,
               ar.id_admission_type,
               nvl(atp.desc_admission_type, pk_translation.get_translation(i_lang, atp.code_admission_type)) desc_adm_type,
               nvl(ar.expected_duration, ai.avg_duration) expected_duration,
               ar.id_adm_preparation,
               nvl(ap.desc_adm_preparation, pk_translation.get_translation(i_lang, ap.code_adm_preparation)) desc_adm_preparation,
               ar.id_dest_inst,
               pk_translation.get_translation(i_lang, i.code_institution) desc_dest_inst, -- location
               ar.id_department,
               pk_translation.get_translation(i_lang, d.code_department) desc_depart, -- pref_ward
               ar.id_room_type,
               nvl(rt.desc_room_type, pk_translation.get_translation(i_lang, rt.code_room_type)) desc_room_type,
               ar.flg_mixed_nursing,
               ar.id_bed_type,
               nvl(bt.desc_bed_type, pk_translation.get_translation(i_lang, bt.code_bed_type)) desc_bed_type,
               ar.id_pref_room,
               r.id_department dep_pref_room,
               nvl(r.desc_room, pk_translation.get_translation(i_lang, r.code_room)) desc_pref_room,
               ar.flg_nit,
               pk_sysdomain.get_domain('ADM_REQUEST.FLG_MIXED_NURSING', ar.flg_nit, i_lang),
               ar.dt_nit_suggested,
               ar.id_nit_dcs,
               pk_date_utils.date_send_tsz(i_lang, ar.dt_nit_suggested, i_prof) nit_dt_sugg_send,
               pk_date_utils.date_char_tsz(i_lang, ar.dt_nit_suggested, i_prof.institution, i_prof.software) nit_dt_sugg_char,
               (SELECT pk_translation.get_translation(i_lang, i2.code_institution)
                  FROM department d2
                  JOIN dep_clin_serv dcs2
                    ON (d2.id_department = dcs2.id_department)
                  JOIN institution i2
                    ON (i2.id_institution = d2.id_institution)
                 WHERE dcs2.id_dep_clin_serv = ar.id_nit_dcs
                   AND d2.flg_available = pk_alert_constant.g_yes) nit_location,
               ar.notes,
               ar.flg_regim,
               pk_sysdomain.get_domain('ADM_REQUEST.REGIMEN', ar.flg_regim, i_lang),
               ar.flg_benefi,
               pk_sysdomain.get_domain('ADM_REQUEST.BENEFICIARIO', ar.flg_benefi, i_lang),
               ar.flg_precauc,
               pk_sysdomain.get_domain('ADM_REQUEST.PRECAUCIONES', ar.flg_precauc, i_lang),
               ar.flg_contact,
               pk_sysdomain.get_domain('ADM_REQUEST.CONTACTADO', ar.flg_contact, i_lang)
        
          INTO o_dt_admission,
               o_id_dep_clin_serv,
               o_desc_dep_clin_serv,
               
               o_id_adm_phys,
               o_name_adm_phys,
               o_id_mrp,
               o_name_mrp,
               o_id_written_by,
               o_name_written_by,
               o_id_compulsory,
               o_desc_compulsory,
               o_id_compulsory_opt,
               o_desc_compulsory_opt,
               o_id_adm_indication,
               o_desc_adm_indication,
               o_id_admission_type,
               o_desc_adm_type,
               o_expected_duration,
               o_id_adm_preparation,
               o_desc_adm_preparation,
               o_id_dest_inst,
               o_desc_dest_inst,
               o_id_department,
               o_desc_depart,
               o_id_room_type,
               o_desc_room_type,
               o_flg_mixed_nursing,
               o_id_bed_type,
               o_desc_bed_type,
               o_id_pref_room,
               o_dep_pref_room,
               o_desc_pref_room,
               o_flg_nit,
               o_flg_nit_desc,
               o_dt_nit_suggested,
               o_id_nit_dcs,
               o_nit_dt_sugg_send,
               o_nit_dt_sugg_char,
               o_nit_location,
               o_notes,
               o_id_regimen,
               o_desc_regimen,
               o_id_beneficiario,
               o_desc_beneficiario,
               o_id_precauciones,
               o_desc_precauciones,
               o_id_contactado,
               o_desc_contactado
          FROM adm_request ar
         INNER JOIN adm_indication ai
            ON ar.id_adm_indication = ai.id_adm_indication
         INNER JOIN wtl_epis we
            ON ar.id_dest_episode = we.id_episode
        --LEFT JOIN clinical_service cs ON ar.id_dep_clin_serv = cs.id_clinical_service
          LEFT JOIN dep_clin_serv dcs
            ON ar.id_dep_clin_serv = dcs.id_dep_clin_serv
          LEFT JOIN clinical_service cs
            ON dcs.id_clinical_service = cs.id_clinical_service
        --
        
        --INNER JOIN wtl_prof wp ON we.id_waiting_list = wp.id_waiting_list
          LEFT JOIN wtl_prof wp
            ON we.id_waiting_list = wp.id_waiting_list
           AND wp.flg_type = g_adm_physician
           AND (wp.flg_status = pk_alert_constant.g_active OR i_all = pk_alert_constant.g_yes)
        
          LEFT JOIN admission_type atp
            ON ar.id_admission_type = atp.id_admission_type
          LEFT JOIN adm_preparation ap
            ON ar.id_adm_preparation = ap.id_adm_preparation
          LEFT JOIN institution i
            ON ar.id_dest_inst = i.id_institution
          LEFT JOIN department d
            ON ar.id_department = d.id_department
          LEFT JOIN room_type rt
            ON ar.id_room_type = rt.id_room_type
          LEFT JOIN bed_type bt
            ON ar.id_bed_type = bt.id_bed_type
          LEFT JOIN room r
            ON ar.id_pref_room = r.id_room
        
         WHERE --ar.id_adm_request = l_id_adm_request
         ar.id_dest_episode = i_id_episode
         AND we.id_waiting_list = i_id_waiting_list
         AND we.id_epis_type = pk_alert_constant.g_epis_type_inpatient; --pk_alert_constant.g_epis_type_emergency
        --AND wp.flg_type = g_adm_physician
        --AND (i_all = pk_alert_constant.g_yes OR wp.flg_status = pk_alert_constant.g_active);
    
        SELECT s.id_speciality, pk_translation.get_translation(i_lang, s.code_speciality) speciality_desc
          INTO o_id_prof_spec_adm, o_desc_prof_spec_adm
        
          FROM adm_request ar
         INNER JOIN adm_indication ai
            ON ar.id_adm_indication = ai.id_adm_indication
         INNER JOIN wtl_epis we
            ON ar.id_dest_episode = we.id_episode
        --LEFT JOIN clinical_service cs ON ar.id_dep_clin_serv = cs.id_clinical_service
          LEFT JOIN dep_clin_serv dcs
            ON ar.id_dep_clin_serv = dcs.id_dep_clin_serv
          LEFT JOIN clinical_service cs
            ON dcs.id_clinical_service = cs.id_clinical_service
        --
        
        --INNER JOIN wtl_prof wp ON we.id_waiting_list = wp.id_waiting_list
          LEFT JOIN wtl_prof wp
            ON we.id_waiting_list = wp.id_waiting_list
           AND wp.flg_type = g_adm_physician
           AND (wp.flg_status = pk_alert_constant.g_active OR i_all = pk_alert_constant.g_yes)
        
          LEFT JOIN adm_preparation ap
            ON ar.id_adm_preparation = ap.id_adm_preparation
          LEFT JOIN institution i
            ON ar.id_dest_inst = i.id_institution
          LEFT JOIN department d
            ON ar.id_department = d.id_department
          LEFT JOIN speciality s
            ON s.id_speciality = ar.id_prof_speciality_adm
         WHERE --ar.id_adm_request = l_id_adm_request
         ar.id_dest_episode = i_id_episode
         AND we.id_waiting_list = i_id_waiting_list
         AND we.id_epis_type = pk_alert_constant.g_epis_type_inpatient;
    
        g_error := 'GET get_adm_req_diag';
        IF NOT pk_admission_request.get_adm_req_diag(i_lang        => i_lang,
                                                     i_prof        => i_prof,
                                                     i_adm_request => l_id_adm_request,
                                                     i_flg_status  => pk_alert_constant.g_active,
                                                     o_diag        => o_diag,
                                                     o_error       => o_error)
        THEN
            RAISE l_runtime_error;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_pck_owner,
                                              g_pck_name,
                                              l_func_name,
                                              o_error);
        
            RETURN FALSE;
    END get_admission_request_ds;

    /******************************************************************************
    *  Given an id_episode and id_waiting_list returns admission request data.
    *
    *  @param  i_lang              Language ID
    *  @param  i_prof              Professional ID/Institution ID/Software ID
    *  @param  i_id_episode        ID of the episode
    *  @param  i_id_waiting_list   ID of the waiting list request
    *  @param  i_all               Y=all rows  N=only active rows
    *  @param  o_adm_request       Admission request       
    *  @param  o_diag              Diagnosis
    *  @param  o_error               
    *
    *  @return                     boolean
    *
    *  @author                     Alexandre Santos
    *  @version                    2.5.0.2
    *  @since                      2009-04-29
    *
    ******************************************************************************/
    FUNCTION get_admission_request
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_episode      IN episode.id_episode%TYPE,
        i_id_waiting_list IN waiting_list.id_waiting_list%TYPE,
        i_all             IN VARCHAR2 DEFAULT 'Y',
        o_adm_request     OUT pk_types.cursor_type,
        o_diag            OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(30) := 'GET_ADMISSION_REQUEST';
        l_runtime_error EXCEPTION;
    
        l_waiting_list_type waiting_list.flg_type%TYPE;
        l_id_adm_request    adm_request.id_adm_request%TYPE;
    
    BEGIN
        g_error := 'get waiting_list flg_type';
        SELECT w.flg_type
          INTO l_waiting_list_type
          FROM waiting_list w
         WHERE w.id_waiting_list = i_id_waiting_list;
    
        --For surgery request without admission request
        IF l_waiting_list_type = pk_alert_constant.g_wl_type_s
        THEN
            RETURN TRUE;
        END IF;
    
        g_error := 'get id_adm_request';
        BEGIN
            SELECT ar.id_adm_request
              INTO l_id_adm_request
              FROM adm_request ar
             WHERE ar.id_dest_episode = i_id_episode;
        EXCEPTION
            WHEN too_many_rows THEN
                RAISE l_runtime_error;
        END;
    
        g_error := 'fill output cursor';
        OPEN o_adm_request FOR
            SELECT ar.id_dep_clin_serv,
                   pk_translation.get_translation(i_lang, cs.code_clinical_service) clin_serv_desc,
                   wp.id_prof id_adm_phys,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, wp.id_prof) name_adm_phys,
                   ar.id_mrp,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, ar.id_mrp) name_mrp,
                   ar.id_written_by,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, ar.id_written_by) name_written_by,
                   ar.flg_compulsory,
                   pk_sysdomain.get_domain(i_code_dom => 'ADM_REQUEST.FLG_MIXED_NURSING',
                                           i_val      => ar.flg_compulsory,
                                           i_lang     => i_lang) name_flg_compulsory,
                   ar.id_adm_indication,
                   decode(ar.id_adm_indication,
                          g_reason_admission_ft,
                          ar.adm_indication_ft,
                          nvl(ai.desc_adm_indication, pk_translation.get_translation(i_lang, ai.code_adm_indication))) desc_adm_indication,
                   ar.id_admission_type,
                   nvl(atp.desc_admission_type, pk_translation.get_translation(i_lang, atp.code_admission_type)) desc_adm_type,
                   ar.expected_duration,
                   ar.id_adm_preparation,
                   nvl(ap.desc_adm_preparation, pk_translation.get_translation(i_lang, ap.code_adm_preparation)) desc_adm_preparation,
                   ar.id_dest_inst,
                   pk_translation.get_translation(i_lang, i.code_institution) desc_dest_inst, -- location
                   ar.id_department,
                   pk_translation.get_translation(i_lang, d.code_department) department_desc, -- pref_ward
                   ar.id_room_type,
                   nvl(rt.desc_room_type, pk_translation.get_translation(i_lang, rt.code_room_type)) desc_room_type,
                   ar.flg_mixed_nursing,
                   ar.id_bed_type,
                   nvl(bt.desc_bed_type, pk_translation.get_translation(i_lang, bt.code_bed_type)) desc_bed_type,
                   ar.id_pref_room,
                   r.id_department dep_pref_room,
                   nvl(r.desc_room, pk_translation.get_translation(i_lang, r.code_room)) desc_pref_room,
                   ar.flg_nit,
                   ar.dt_nit_suggested,
                   ar.id_nit_dcs,
                   pk_date_utils.date_send_tsz(i_lang, ar.dt_nit_suggested, i_prof) nit_dt_sugg_send,
                   pk_date_utils.date_chr_short_read_tsz(i_lang,
                                                         ar.dt_nit_suggested,
                                                         i_prof.institution,
                                                         i_prof.software) nit_dt_sugg_char,
                   (SELECT pk_translation.get_translation(i_lang, i2.code_institution)
                      FROM department d2
                      JOIN dep_clin_serv dcs2
                        ON (d2.id_department = dcs2.id_department)
                      JOIN institution i2
                        ON (i2.id_institution = d2.id_institution)
                     WHERE dcs2.id_dep_clin_serv = ar.id_nit_dcs
                       AND d2.flg_available = pk_alert_constant.g_yes) nit_location,
                   ar.notes,
                   ar.flg_regim,
                   pk_sysdomain.get_domain(i_code_dom => 'ADM_REQUEST.REGIMEN', i_val => ar.flg_regim, i_lang => i_lang) regim_desc,
                   ar.flg_benefi,
                   pk_sysdomain.get_domain(i_code_dom => 'ADM_REQUEST.BENEFICIARIO',
                                           i_val      => ar.flg_benefi,
                                           i_lang     => i_lang) benefic_desc,
                   ar.flg_precauc,
                   pk_sysdomain.get_domain(i_code_dom => 'ADM_REQUEST.PRECAUCIONES',
                                           i_val      => ar.flg_precauc,
                                           i_lang     => i_lang) precauc_desc,
                   ar.flg_contact,
                   pk_sysdomain.get_domain(i_code_dom => 'ADM_REQUEST.CONTACTADO',
                                           i_val      => ar.flg_contact,
                                           i_lang     => i_lang) contact_desc,
                   pk_translation.get_translation(i_lang, s.code_speciality) speciality_desc,
                   (SELECT get_duration_desc(i_lang, i_prof, ar.expected_duration)
                      FROM dual) desc_expected_duration,
                   pk_sysdomain.get_domain(i_code_dom => 'ADM_REQUEST.FLG_MIXED_NURSING',
                                           i_val      => ar.flg_mixed_nursing,
                                           i_lang     => i_lang) desc_mixed_nursing,
                   ar.id_compulsory_reason,
                   decode(ar.id_compulsory_reason,
                          NULL,
                          NULL,
                          -1,
                          pk_multichoice.get_multichoice_option_desc(i_lang      => i_lang,
                                                                     i_prof      => i_prof,
                                                                     i_id_option => ar.id_compulsory_reason) || ' - ' ||
                          ar.compulsory_reason,
                          pk_multichoice.get_multichoice_option_desc(i_lang      => i_lang,
                                                                     i_prof      => i_prof,
                                                                     i_id_option => ar.id_compulsory_reason)) compulsory_reason_desc
              FROM adm_request ar
             INNER JOIN adm_indication ai
                ON ar.id_adm_indication = ai.id_adm_indication
             INNER JOIN wtl_epis we
                ON ar.id_dest_episode = we.id_episode
            --LEFT JOIN clinical_service cs ON ar.id_dep_clin_serv = cs.id_clinical_service
              LEFT JOIN dep_clin_serv dcs
                ON ar.id_dep_clin_serv = dcs.id_dep_clin_serv
              LEFT JOIN clinical_service cs
                ON dcs.id_clinical_service = cs.id_clinical_service
            --
            
            --INNER JOIN wtl_prof wp ON we.id_waiting_list = wp.id_waiting_list
              LEFT JOIN wtl_prof wp
                ON we.id_waiting_list = wp.id_waiting_list
               AND wp.flg_type = g_adm_physician
               AND (wp.flg_status = pk_alert_constant.g_active OR i_all = pk_alert_constant.g_yes)
            
              LEFT JOIN admission_type atp
                ON ar.id_admission_type = atp.id_admission_type
              LEFT JOIN adm_preparation ap
                ON ar.id_adm_preparation = ap.id_adm_preparation
              LEFT JOIN institution i
                ON ar.id_dest_inst = i.id_institution
              LEFT JOIN department d
                ON ar.id_department = d.id_department
              LEFT JOIN room_type rt
                ON ar.id_room_type = rt.id_room_type
              LEFT JOIN bed_type bt
                ON ar.id_bed_type = bt.id_bed_type
              LEFT JOIN room r
                ON ar.id_pref_room = r.id_room
              LEFT JOIN wtl_dep_clin_serv wdcs
                ON wdcs.id_waiting_list = i_id_waiting_list
               AND wdcs.flg_status = pk_alert_constant.g_active
               AND wdcs.flg_type = 'S'
              LEFT JOIN speciality s
                ON s.id_speciality = wdcs.id_prof_speciality
             WHERE --ar.id_adm_request = l_id_adm_request
             ar.id_dest_episode = i_id_episode
             AND we.id_waiting_list = i_id_waiting_list
             AND we.id_epis_type = pk_alert_constant.g_epis_type_inpatient
             AND rownum = 1; --wtl_dep_clin_serv may have several records
        --AND wp.flg_type = g_adm_physician
        --AND (i_all = pk_alert_constant.g_yes OR wp.flg_status = pk_alert_constant.g_active);
    
        g_error := 'GET get_adm_req_diag';
        IF NOT pk_admission_request.get_adm_req_diag(i_lang        => i_lang,
                                                     i_prof        => i_prof,
                                                     i_adm_request => l_id_adm_request,
                                                     o_diag        => o_diag,
                                                     o_error       => o_error)
        THEN
            RAISE l_runtime_error;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_pck_owner,
                                              g_pck_name,
                                              l_func_name,
                                              o_error);
        
            pk_types.open_my_cursor(o_adm_request);
            pk_types.open_my_cursor(o_diag);
        
            RETURN FALSE;
    END get_admission_request;

    --
    FUNCTION get_adm_request_hist
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_episode     IN episode.id_episode%TYPE,
        i_wtl         IN waiting_list.id_waiting_list%TYPE,
        o_title       OUT pk_types.cursor_type,
        o_description OUT pk_types.cursor_type,
        o_info        OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(30) := 'GET_ADMISSION_REQUEST_HIST';
        --
        adm_01 VARCHAR2(200);
        adm_02 VARCHAR2(200);
        adm_03 VARCHAR2(200);
        adm_04 VARCHAR2(200);
        adm_05 VARCHAR2(200);
        adm_06 VARCHAR2(200);
        adm_07 VARCHAR2(200);
        adm_08 VARCHAR2(200);
        adm_09 VARCHAR2(200);
        adm_10 VARCHAR2(200);
        adm_11 VARCHAR2(200);
        adm_12 VARCHAR2(200);
        adm_13 VARCHAR2(200);
        adm_14 VARCHAR2(200);
        adm_15 VARCHAR2(200);
        adm_16 VARCHAR2(200);
        adm_17 VARCHAR2(200);
        --
        surg_01 VARCHAR2(200);
        surg_02 VARCHAR2(200);
        surg_03 VARCHAR2(200);
        surg_04 VARCHAR2(200);
        surg_05 VARCHAR2(200);
        surg_06 VARCHAR2(200);
        surg_07 VARCHAR2(200);
        surg_08 VARCHAR2(200);
        surg_09 VARCHAR2(200);
        surg_10 VARCHAR2(200);
        surg_11 VARCHAR2(200);
        surg_12 VARCHAR2(200);
        --
        adm_surg_01 VARCHAR2(200);
        adm_surg_02 VARCHAR2(200);
        adm_surg_03 VARCHAR2(200);
        adm_surg_04 VARCHAR2(200);
        adm_surg_05 VARCHAR2(200);
        adm_surg_06 VARCHAR2(200);
        adm_surg_07 VARCHAR2(200);
        adm_surg_08 VARCHAR2(200);
        adm_surg_09 VARCHAR2(200);
        adm_surg_10 VARCHAR2(200);
        adm_surg_11 VARCHAR2(200);
    BEGIN
    
        g_error := 'SET UP VARIABLES';
        -- ADMISSION
        adm_01 := pk_message.get_message(i_lang, 'ADM_REQUEST_T001');
        adm_02 := pk_message.get_message(i_lang, 'ADM_REQUEST_T028');
        adm_03 := pk_message.get_message(i_lang, 'ADM_REQUEST_T008');
        adm_04 := pk_message.get_message(i_lang, 'ADM_REQUEST_T009');
        adm_05 := pk_message.get_message(i_lang, 'ADM_REQUEST_T029');
        adm_06 := pk_message.get_message(i_lang, 'ADM_REQUEST_T030');
        adm_07 := pk_message.get_message(i_lang, 'ADM_REQUEST_T031');
        adm_08 := pk_message.get_message(i_lang, 'ADM_REQUEST_T032');
        adm_09 := pk_message.get_message(i_lang, 'ADM_REQUEST_T033');
        adm_10 := pk_message.get_message(i_lang, 'ADM_REQUEST_T034');
        adm_11 := pk_message.get_message(i_lang, 'ADM_REQUEST_T035');
        adm_12 := pk_message.get_message(i_lang, 'ADM_REQUEST_T036');
        adm_13 := pk_message.get_message(i_lang, 'ADM_REQUEST_T037');
        adm_14 := pk_message.get_message(i_lang, 'ADM_REQUEST_T038');
        adm_15 := pk_message.get_message(i_lang, 'ADM_REQUEST_T052');
        adm_16 := pk_message.get_message(i_lang, 'ADM_REQUEST_T039');
        adm_17 := pk_message.get_message(i_lang, 'ADM_REQUEST_T040');
        --
        -- SURGERY
        surg_01 := pk_message.get_message(i_lang, 'SURGERY_REQUEST_T034');
        surg_02 := pk_message.get_message(i_lang, 'SURGERY_REQUEST_T010');
        surg_03 := pk_message.get_message(i_lang, 'SURGERY_REQUEST_T011');
        surg_04 := pk_message.get_message(i_lang, 'SURGERY_REQUEST_T001');
        surg_05 := pk_message.get_message(i_lang, 'SURGERY_REQUEST_T012');
        surg_06 := pk_message.get_message(i_lang, 'SURGERY_REQUEST_T013');
        surg_07 := pk_message.get_message(i_lang, 'SURGERY_REQUEST_T014');
        surg_08 := pk_message.get_message(i_lang, 'SURGERY_REQUEST_T015');
        surg_09 := pk_message.get_message(i_lang, 'SURGERY_REQUEST_T016');
        surg_10 := pk_message.get_message(i_lang, 'SURGERY_REQUEST_T017');
        surg_11 := pk_message.get_message(i_lang, 'SURGERY_REQUEST_T018');
        surg_12 := pk_message.get_message(i_lang, 'SURGERY_REQUEST_T019');
        --
        -- ADMISSION AND SURGERY
        adm_surg_01 := pk_message.get_message(i_lang, 'SURG_ADM_REQUEST_T003');
        adm_surg_02 := pk_message.get_message(i_lang, 'SURG_ADM_REQUEST_T002');
        adm_surg_03 := pk_message.get_message(i_lang, 'SURG_ADM_REQUEST_T004');
        adm_surg_04 := pk_message.get_message(i_lang, 'SURG_ADM_REQUEST_T005');
        adm_surg_05 := pk_message.get_message(i_lang, 'SURG_ADM_REQUEST_T006');
        adm_surg_06 := pk_message.get_message(i_lang, 'SURG_ADM_REQUEST_T014');
        adm_surg_07 := pk_message.get_message(i_lang, 'SURG_ADM_REQUEST_T010');
        adm_surg_08 := pk_message.get_message(i_lang, 'SURG_ADM_REQUEST_T013');
        adm_surg_09 := pk_message.get_message(i_lang, 'SURG_ADM_REQUEST_T011');
        adm_surg_10 := pk_message.get_message(i_lang, 'SURG_ADM_REQUEST_T008');
        adm_surg_11 := pk_message.get_message(i_lang, 'SURG_ADM_REQUEST_T007');
        --
        -- TODO
        --(não deve existir)                            : Admission status
        --(não deve existir)                            : Surgery status
    
        --
        g_error := 'OPEN O_TITLE';
        OPEN o_title FOR
            SELECT adm_01,
                   adm_02,
                   adm_03,
                   adm_04,
                   adm_05,
                   adm_06,
                   adm_07,
                   adm_08,
                   adm_09,
                   adm_10,
                   adm_11,
                   adm_12,
                   adm_13,
                   adm_14,
                   adm_15,
                   adm_16,
                   adm_17,
                   --
                   surg_01,
                   surg_02,
                   surg_03,
                   surg_04,
                   surg_05,
                   surg_06,
                   surg_07,
                   surg_08,
                   surg_09,
                   surg_10,
                   surg_11,
                   surg_12,
                   --
                   adm_surg_01,
                   adm_surg_02,
                   adm_surg_03,
                   adm_surg_04,
                   adm_surg_05,
                   adm_surg_06,
                   --adm_surg_07, adm_surg_08, adm_surg_09,
                   unav_period.*,
                   --
                   adm_surg_10,
                   adm_surg_11
              FROM (SELECT adm_surg_07, adm_surg_08, adm_surg_09
                      FROM wtl_unav wu
                     WHERE wu.id_waiting_list = i_wtl) unav_period;
    
        --
        g_error := 'OPEN O_DESCRIPTION';
        OPEN o_description FOR
            SELECT 'Osteomyelitis.', 'Osteomyelitis.'
              FROM dual;
    
        --
        g_error := 'OPEN O_INFO';
        OPEN o_info FOR
            SELECT 'C' flg_status, 'Created at: ' label, '11:00h/Nov-03-2009' dt_reg, 'Dan Bakker' prof
              FROM dual;
    
        --
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_pck_owner,
                                              g_pck_name,
                                              l_func_name,
                                              o_error);
        
            pk_types.open_my_cursor(o_title);
            pk_types.open_my_cursor(o_description);
            pk_types.open_my_cursor(o_info);
            --
            RETURN FALSE;
        
    END get_adm_request_hist;

    /******************************************************************************
    *  Given an id_waiting_list returns indication for admission description.
    *
    *  @param  i_lang              Language ID
    *  @param  i_prof              Professional ID/Institution ID/Software ID
    *  @param  i_id_waiting_list   ID of the waiting list request
    *
    *  @return                     varchar2
    *
    *  @author                     Fábio Oliveira
    *  @version                    2.5.0.3
    *  @since                      2009-05-29
    *
    ******************************************************************************/
    FUNCTION get_adm_indication_desc
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_waiting_list IN waiting_list.id_waiting_list%TYPE
    ) RETURN pk_translation.t_desc_translation IS
        l_desc_adm_indication pk_translation.t_desc_translation;
    BEGIN
        g_error := 'GET DESCRIPTION';
        SELECT nvl(ai.desc_adm_indication, pk_translation.get_translation(i_lang, ai.code_adm_indication)) desc_adm_indication
          INTO l_desc_adm_indication
          FROM adm_request ar
          JOIN wtl_epis we
            ON ar.id_dest_episode = we.id_episode
          JOIN adm_indication ai
            ON ar.id_adm_indication = ai.id_adm_indication
         WHERE we.id_waiting_list = i_id_waiting_list
           AND we.id_epis_type = pk_alert_constant.g_epis_type_inpatient;
    
        RETURN l_desc_adm_indication;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.raise_error(error_code_in => SQLCODE, text_in => SQLERRM);
            RETURN NULL;
    END get_adm_indication_desc;

    /********************************************************************************************
    * Given an indication for admission ID returns the admission description
    *
    * @param    i_prof                object (id of professional, id of institution, id of software)
    * @param    i_lang                preferred language ID
    * @param    i_id_adm_indication   indication for admission ID
    *
    * @return   varchar2              admission description
    *
    * @author                         Tiago Silva
    * @since                          2010/08/06
    ********************************************************************************************/
    FUNCTION get_adm_indication_desc
    (
        i_prof              IN profissional,
        i_lang              IN language.id_language%TYPE,
        i_id_adm_indication IN adm_indication.id_adm_indication%TYPE
    ) RETURN pk_translation.t_desc_translation IS
        l_desc_adm_indication pk_translation.t_desc_translation;
    BEGIN
    
        g_error := 'GET ADMISSION DESCRIPTION';
        pk_alertlog.log_debug(g_error, g_pck_name);
    
        SELECT nvl(ai.desc_adm_indication, pk_translation.get_translation(i_lang, ai.code_adm_indication)) desc_adm_indication
          INTO l_desc_adm_indication
          FROM adm_indication ai
         WHERE ai.id_adm_indication = i_id_adm_indication;
    
        RETURN l_desc_adm_indication;
    
    END get_adm_indication_desc;

    /**********************************************************************************************
    * Funtion to list possible professionals to receive an alert for completing a patient request.
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids             
    * @param i_prof_templ             profile_template id
    * @param o_list                   array with physicians
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         RicardoNunoAlmeida
    * @version                        1.0 
    * @since                          2009/06/09
    **********************************************************************************************/
    FUNCTION get_professionals_nl
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_prof_templ IN profile_template.id_profile_template%TYPE,
        o_list       OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(30) := 'GET_PROFESSIONALS_NL';
        l_inst      table_number;
    BEGIN
        g_error := 'CALL GET RELATED INSTITUTIONS';
        IF NOT pk_utils.get_institutions_sib(i_lang, i_prof, i_prof.institution, l_inst, o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        g_error := 'FAIL-SAFE';
        IF l_inst.count = 0
        THEN
            l_inst.extend;
            l_inst(l_inst.last) := i_prof.institution;
        END IF;
    
        g_error := 'OPEN O_LIST';
        OPEN o_list FOR
            SELECT id_profile_template,
                   desc_prof_templ,
                   id_professional,
                   nick_name || decode(i_prof_templ, 0, ' (' || desc_prof_templ || ')', '') nick_name,
                   name
              FROM (SELECT sap.id_profile_template,
                           (SELECT pk_message.get_message(i_lang, pt.code_profile_template)
                              FROM dual) desc_prof_templ,
                           sap.id_professional,
                           p.nick_name,
                           p.name
                      FROM sys_alert_prof sap
                      JOIN profile_template pt
                        ON pt.id_profile_template = sap.id_profile_template
                      JOIN institution i
                        ON i.id_institution = sap.id_institution
                      JOIN professional p
                        ON p.id_professional = sap.id_professional
                     WHERE sap.id_institution IN (SELECT /*+ opt_estimate(table inst rows=1) */
                                                   *
                                                    FROM TABLE(l_inst) inst)
                       AND sap.id_sys_alert = g_adm_req_alert
                       AND ((sap.id_profile_template = i_prof_templ) OR (i_prof_templ = 0)))
             WHERE (SELECT pk_prof_utils.is_internal_prof(i_lang, i_prof, id_professional, i_prof.institution)
                      FROM dual) = 'Y'
             ORDER BY name ASC;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_pck_owner,
                                              g_pck_name,
                                              l_func_name,
                                              o_error);
            pk_types.open_my_cursor(o_list);
            RETURN FALSE;
        
    END get_professionals_nl;

    /**********************************************************************************************
    * Funtion to list possible professionals to receive an alert for completing a patient request.
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids             
    * @param i_text                   Text to search for.
    * @param o_list                   array with physicians
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         RicardoNunoAlmeida
    * @version                        1.0 
    * @since                          2009/06/09
    **********************************************************************************************/
    FUNCTION get_search_professionals_nl
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_text       IN VARCHAR2,
        o_list       OUT pk_types.cursor_type,
        o_prof_templ OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(30) := 'GET_SEARCH_PROFESSIONALS_NL';
        l_inst      table_number;
        l_straw     VARCHAR2(4000);
    BEGIN
    
        g_error := 'CALL GET RELATED INSTITUTIONS';
        IF NOT pk_utils.get_institutions_sib(i_lang, i_prof, i_prof.institution, l_inst, o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        g_error := 'FAIL-SAFE';
        IF l_inst.count = 0
        THEN
            l_inst.extend;
            l_inst(l_inst.last) := i_prof.institution;
        END IF;
    
        l_straw := '%' || upper(i_text) || '%';
    
        g_error := 'OPEN O_LIST';
        OPEN o_list FOR
            SELECT pt.id_profile_template,
                   pk_message.get_message(i_lang, pt.code_profile_template) desc_prof_templ,
                   p.id_professional,
                   p.nick_name,
                   p.name
              FROM professional p
             INNER JOIN prof_profile_template ppt
                ON ppt.id_professional = p.id_professional
             INNER JOIN profile_template pt
                ON pt.id_profile_template = ppt.id_profile_template
               AND pt.flg_type IN (g_prof_flg_type_a, g_prof_flg_type_d, g_prof_flg_type_n)
               AND pt.id_software = ppt.id_software
             INNER JOIN institution i
                ON i.id_institution = ppt.id_institution
             INNER JOIN profile_template_market ptm
                ON ptm.id_profile_template = pt.id_profile_template
               AND ptm.id_market IN (0, i.id_market)
             INNER JOIN software s
                ON s.id_software = pt.id_software
               AND s.flg_viewer = pk_alert_constant.g_no
             WHERE ((upper(p.name) LIKE l_straw) OR (upper(p.nick_name) LIKE l_straw))
               AND pt.flg_available = pk_alert_constant.g_yes
               AND ppt.id_software IN (pk_alert_constant.g_soft_outpatient,
                                       pk_alert_constant.g_soft_edis,
                                       pk_alert_constant.g_soft_oris,
                                       pk_alert_constant.g_soft_inpatient)
               AND ppt.id_institution IN (SELECT *
                                            FROM TABLE(l_inst))
               AND pk_prof_utils.is_internal_prof(i_lang, i_prof, p.id_professional, i_prof.institution) =
                   pk_alert_constant.g_yes
             ORDER BY pt.id_profile_template ASC, p.name ASC;
    
        g_error := 'OPEN O_PROF_TEMPL';
        OPEN o_prof_templ FOR
            SELECT pt.id_profile_template,
                   pk_message.get_message(i_lang, pt.code_profile_template) desc_prof_templ,
                   COUNT(ppt.id_prof_profile_template) total
              FROM profile_template pt
             INNER JOIN prof_profile_template ppt
                ON pt.id_profile_template = ppt.id_profile_template
               AND pt.id_software = ppt.id_software
            
             INNER JOIN professional p
                ON p.id_professional = ppt.id_professional
             INNER JOIN institution i
                ON i.id_institution = ppt.id_institution
             INNER JOIN profile_template_market ptm
                ON ptm.id_profile_template = pt.id_profile_template
               AND ptm.id_market IN (0, i.id_market)
             INNER JOIN software s
                ON s.id_software = pt.id_software
               AND s.flg_viewer = pk_alert_constant.g_no
             WHERE ((upper(p.name) LIKE l_straw) OR (upper(p.nick_name) LIKE l_straw))
               AND pt.flg_available = pk_alert_constant.g_yes
               AND pt.flg_type IN (g_prof_flg_type_a, g_prof_flg_type_d, g_prof_flg_type_n)
               AND ppt.id_software IN
                   (pk_alert_constant.g_soft_outpatient, pk_alert_constant.g_soft_edis, pk_alert_constant.g_soft_oris)
               AND ppt.id_institution IN (SELECT *
                                            FROM TABLE(l_inst))
             GROUP BY pt.id_profile_template, pk_message.get_message(i_lang, pt.code_profile_template)
             ORDER BY pk_message.get_message(i_lang, pt.code_profile_template) ASC;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_pck_owner,
                                              g_pck_name,
                                              l_func_name,
                                              o_error);
            pk_types.open_my_cursor(o_list);
            pk_types.open_my_cursor(o_prof_templ);
        
            RETURN FALSE;
        
    END get_search_professionals_nl;

    /**********************************************************************************************
    * Function to list possible professionals to receive an alert for completing a patient request.
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids             
    * @param i_text                   Text to search for.
    * @param o_list                   array with physicians
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         RicardoNunoAlmeida
    * @version                        1.0 
    * @since                          2009/06/09
    **********************************************************************************************/
    FUNCTION get_prof_templ_nl
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(30) := 'GET_PROF_TEMPL_NL';
        l_inst      table_number;
    BEGIN
        g_error := 'CALL GET RELATED INSTITUTIONS';
        IF NOT pk_utils.get_institutions_sib(i_lang, i_prof, i_prof.institution, l_inst, o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        g_error := 'FAIL-SAFE';
        IF l_inst.count = 0
        THEN
            l_inst.extend;
            l_inst(l_inst.last) := i_prof.institution;
        END IF;
    
        g_error := 'OPEN O_LIST';
        OPEN o_list FOR
        
            SELECT pt.id_profile_template,
                   (SELECT pk_message.get_message(i_lang, pt.code_profile_template)
                      FROM dual) desc_prof_templ,
                   0 rank,
                   1 total
              FROM profile_template pt
             WHERE pt.id_profile_template = 0
            UNION ALL
            SELECT t.id_profile_template, t.desc_prof_templ, t.rank, COUNT(t.id_prof_profile_template) total
              FROM (SELECT pt.id_profile_template,
                           s.name || ' - ' || (SELECT pk_message.get_message(i_lang, pt.code_profile_template)
                                                 FROM dual) desc_prof_templ,
                           1 rank,
                           ppt.id_prof_profile_template
                      FROM profile_template pt
                     INNER JOIN software s
                        ON s.id_software = pt.id_software
                     INNER JOIN prof_profile_template ppt
                        ON ppt.id_profile_template = pt.id_profile_template
                       AND pt.id_software = ppt.id_software
                       AND ppt.id_software = s.id_software
                     INNER JOIN institution i
                        ON i.id_institution = ppt.id_institution
                     INNER JOIN profile_template_market ptm
                        ON ptm.id_profile_template = pt.id_profile_template
                       AND ptm.id_profile_template = ppt.id_profile_template
                       AND ptm.id_market IN (0, i.id_market)
                     INNER JOIN sys_alert_config sac
                        ON sac.id_profile_template = pt.id_profile_template
                       AND sac.id_profile_template = ppt.id_profile_template
                       AND sac.id_profile_template = ptm.id_profile_template
                     WHERE s.flg_viewer = pk_alert_constant.g_no
                       AND pt.flg_type IN (g_prof_flg_type_a, g_prof_flg_type_d, g_prof_flg_type_n)
                       AND pt.flg_available = pk_alert_constant.g_yes
                       AND ppt.id_software IN (pk_alert_constant.g_soft_outpatient,
                                               pk_alert_constant.g_soft_edis,
                                               pk_alert_constant.g_soft_oris,
                                               pk_alert_constant.g_soft_inpatient)
                       AND ppt.id_institution IN (SELECT /*+ opt_estimate(table t rows=1) */
                                                   *
                                                    FROM TABLE(l_inst) t)
                       AND sac.id_sys_alert = g_adm_req_alert
                       AND EXISTS (SELECT /*+ no_unnest */
                             1
                              FROM sys_alert_prof sap
                             WHERE sap.id_profile_template = pt.id_profile_template
                               AND sap.id_sys_alert = sac.id_sys_alert
                               AND sap.id_institution = ppt.id_institution)) t
             GROUP BY t.id_profile_template, t.desc_prof_templ, t.rank
            HAVING COUNT(t.id_prof_profile_template) > 0
             ORDER BY rank ASC, desc_prof_templ ASC;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_pck_owner,
                                              g_pck_name,
                                              l_func_name,
                                              o_error);
            pk_types.open_my_cursor(o_list);
            RETURN FALSE;
    END get_prof_templ_nl;

    /**********************************************************************************************
    * Creates a new alert message for each one of the professionals in the array.
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids             
    * @param i_epis                   ID of the episode
    * @param i_wtl                    ID of the Waiting List entry
    * @param i_profs                  array with professionals
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         RicardoNunoAlmeida
    * @version                        1.0 
    * @since                          2009/06/09
    **********************************************************************************************/
    FUNCTION set_adm_req_alert
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_epis  IN episode.id_episode%TYPE,
        i_wtl   IN waiting_list.id_waiting_list%TYPE,
        i_profs IN table_number,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(30) := 'SET_ADM_REQ_ALERT';
        l_sysdate   TIMESTAMP WITH LOCAL TIME ZONE;
    BEGIN
        l_sysdate := current_timestamp;
        g_error   := 'LOOP SELECTED PROFESSIONALS';
        FOR i IN i_profs.first .. i_profs.last
        LOOP
        
            IF NOT pk_alerts.insert_sys_alert_event(i_lang                => i_lang,
                                                    i_prof                => i_prof,
                                                    i_sys_alert           => 64,
                                                    i_id_episode          => i_epis,
                                                    i_id_record           => i_wtl,
                                                    i_dt_record           => l_sysdate,
                                                    i_id_professional     => i_profs(i),
                                                    i_id_room             => NULL,
                                                    i_id_clinical_service => NULL,
                                                    i_flg_type_dest       => 'C',
                                                    i_replace1            => NULL,
                                                    i_replace2            => NULL,
                                                    o_error               => o_error)
            THEN
                RETURN FALSE;
            END IF;
        
        END LOOP;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_pck_owner,
                                              g_pck_name,
                                              l_func_name,
                                              o_error);
        
            RETURN FALSE;
    END set_adm_req_alert;

    /***************************************************************************************************************
    *
    * Restores the entry in ADM_REQUEST after saving its previous state in ADM_REQUEST_HIST 
    * Note: related episodes must be restored in other functions. 
    * 
    * @param      i_lang              language ID
    * @param      i_prof              ALERT profissional 
    * @param      i_id_adm_req        ID of the record to cancel.
    * @param      o_error
    *
    *
    * @RETURN  TRUE or FALSE
    * @author  Ricardo Nuno Almeida
    * @version 1.0
    * @since   02-07-2009
    *
    ****************************************************************************************************/
    FUNCTION undelete_admission_req
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_adm_req IN adm_request.id_adm_request%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_adm_req_h adm_request_hist%ROWTYPE;
        l_adm_req   adm_request%ROWTYPE;
        e_exp_o EXCEPTION;
        l_rows          table_varchar;
        l_pat           patient.id_patient%TYPE;
        l_wtl           waiting_list.id_waiting_list%TYPE;
        l_visit         visit.id_visit%TYPE;
        l_epis_dt_begin TIMESTAMP WITH TIME ZONE;
    BEGIN
        g_error := 'GET ADM_REQUEST_HIST RECORD';
        SELECT data.*
          INTO l_adm_req_h
          FROM (SELECT arh.*
                  FROM adm_request_hist arh
                 WHERE arh.id_adm_request = i_id_adm_req
                   AND arh.flg_status != pk_alert_constant.g_flg_status_c
                 ORDER BY nvl(arh.dt_upd, current_timestamp) DESC) data
         INNER JOIN episode epis
            ON epis.id_episode = data.id_dest_episode
         WHERE rownum = 1;
    
        g_error := 'GET ADM_REQUEST RECORD';
        SELECT ar.*
          INTO l_adm_req
          FROM adm_request ar
         WHERE ar.id_adm_request = i_id_adm_req;
    
        g_error := 'GET PAT';
        SELECT epis.id_patient, we.id_waiting_list, epis.id_visit, epis.dt_begin_tstz
          INTO l_pat, l_wtl, l_visit, l_epis_dt_begin
          FROM episode epis
         INNER JOIN wtl_epis we
            ON we.id_episode = epis.id_episode
         WHERE epis.id_episode = l_adm_req_h.id_dest_episode;
    
        IF l_adm_req_h.flg_nit = pk_alert_constant.g_yes
           AND l_adm_req_h.id_nit_req IS NOT NULL
        THEN
        
            g_error := 'CALL SET_NURSE_SCHEDULE';
            IF NOT set_nurse_schedule(i_lang             => i_lang,
                                      i_prof             => i_prof,
                                      i_patient          => l_pat,
                                      i_episode          => l_adm_req.id_dest_episode,
                                      i_flg_edit         => g_flg_new,
                                      i_dep_clin_serv    => l_adm_req.id_nit_dcs,
                                      i_dt_scheduled_str => l_adm_req.dt_nit_suggested,
                                      io_consult_req     => l_adm_req.id_nit_req,
                                      o_error            => o_error)
            THEN
                DECLARE
                    l_error_in      t_error_in := t_error_in();
                    l_error_message sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                                            'SURG_ADM_REQUEST_E029');
                    l_ret           BOOLEAN;
                BEGIN
                    l_error_in.set_all(i_lang,
                                       'ADM_REQUEST_T060',
                                       l_error_message,
                                       g_error,
                                       g_pck_owner,
                                       g_pck_name,
                                       'UNDELETE_ADMISSION_REQUEST');
                
                    l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
                
                    pk_utils.undo_changes;
                    pk_alert_exceptions.reset_error_state;
                
                END;
            END IF;
        
        END IF;
    
        --The previous validation allows us not to check for changes in the record.
        g_error := 'INSERT ADM_REQ HIST';
        ts_adm_request_hist.ins(id_adm_request_hist_in => ts_adm_request_hist.next_key,
                                id_adm_request_in      => l_adm_req.id_adm_request,
                                id_adm_indication_in   => l_adm_req.id_adm_indication,
                                id_dest_episode_in     => l_adm_req.id_dest_episode,
                                id_dest_prof_in        => l_adm_req.id_dest_prof,
                                id_dest_inst_in        => l_adm_req.id_dest_inst,
                                id_department_in       => l_adm_req.id_department,
                                id_dep_clin_serv_in    => l_adm_req.id_dep_clin_serv,
                                id_room_type_in        => l_adm_req.id_room_type,
                                id_pref_room_in        => l_adm_req.id_pref_room,
                                id_admission_type_in   => l_adm_req.id_admission_type,
                                expected_duration_in   => l_adm_req.expected_duration,
                                id_adm_preparation_in  => l_adm_req.id_adm_preparation,
                                flg_mixed_nursing_in   => l_adm_req.flg_mixed_nursing,
                                id_bed_type_in         => l_adm_req.id_bed_type,
                                dt_admission_in        => l_adm_req.dt_admission,
                                flg_nit_in             => l_adm_req.flg_nit,
                                dt_nit_suggested_in    => l_adm_req.dt_nit_suggested,
                                id_nit_dcs_in          => l_adm_req.id_nit_dcs,
                                id_nit_req_in          => l_adm_req.id_nit_req,
                                notes_in               => l_adm_req.notes,
                                flg_status_in          => l_adm_req.flg_status,
                                id_upd_episode_in      => l_adm_req.id_upd_episode,
                                id_upd_prof_in         => l_adm_req.id_upd_prof,
                                id_upd_inst_in         => l_adm_req.id_upd_inst,
                                dt_upd_in              => l_adm_req.dt_upd,
                                rows_out               => l_rows);
    
        g_error := 'PROCESS INSERT';
        t_data_gov_mnt.process_insert(i_lang, i_prof, 'ADM_REQUEST_HIST', l_rows, o_error);
        l_rows := table_varchar();
    
        g_error := 'UPDATE ADM_REQ';
        ts_adm_request.upd(id_adm_request_in => l_adm_req.id_adm_request,
                           flg_status_in     => l_adm_req_h.flg_status,
                           id_upd_prof_in    => i_prof.id,
                           id_upd_inst_in    => i_prof.institution,
                           id_nit_req_in     => l_adm_req.id_nit_req, --Sofia Mendes(17-09-2009): ALERT-41812
                           dt_upd_in         => current_timestamp,
                           rows_out          => l_rows);
    
        g_error := 'PROCESS UPDATE';
        t_data_gov_mnt.process_update(i_lang, i_prof, 'ADM_REQUEST', l_rows, o_error);
    
        RETURN TRUE;
    EXCEPTION
    
        WHEN OTHERS THEN
        
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_pck_owner,
                                              g_pck_name,
                                              'CANCEL_ADMISSION_REQUEST',
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
        
            RETURN FALSE;
    END undelete_admission_req;

    /***************************************************************************************************************
    *
    * Returns the description of the provided bed
    *  
    * 
    * @param      i_lang              language ID
    * @param      i_prof              ALERT profissional 
    * @param      i_bed               ID of the bed.
    * @param      o_error
    *
    *
    * @RETURN  TRUE or FALSE
    * @author  Ricardo Nuno Almeida
    * @version 1.0
    * @since   21-07-2009
    *
    ****************************************************************************************************/
    FUNCTION get_bed_type
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_bed     IN bed.id_bed%TYPE,
        o_desc_bt OUT pk_translation.t_desc_translation,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_error := 'SELECT BED TYPE';
        SELECT nvl(bt.desc_bed_type, pk_translation.get_translation(i_lang, bt.code_bed_type))
          INTO o_desc_bt
          FROM bed b
          LEFT JOIN bed_type bt
            ON b.id_bed_type = bt.id_bed_type
         WHERE b.id_bed = i_bed;
    
        RETURN TRUE;
    EXCEPTION
    
        WHEN OTHERS THEN
        
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_pck_owner,
                                              g_pck_name,
                                              'GET_BED_TYPE',
                                              o_error);
        
            pk_alert_exceptions.reset_error_state;
        
            RETURN FALSE;
    END get_bed_type;

    FUNCTION get_bed_type
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional,
        i_bed  IN bed.id_bed%TYPE
    ) RETURN VARCHAR2 IS
        l_err  t_error_out;
        l_desc pk_translation.t_desc_translation;
    BEGIN
        g_error := 'CALL MAIN FUNCTION';
        IF NOT get_bed_type(i_lang => i_lang, i_prof => i_prof, i_bed => i_bed, o_desc_bt => l_desc, o_error => l_err)
        THEN
            RETURN '';
        ELSE
            RETURN l_desc;
        END IF;
    
    EXCEPTION
    
        WHEN OTHERS THEN
        
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_pck_owner,
                                              g_pck_name,
                                              'GET_BED_TYPE',
                                              l_err);
        
            pk_alert_exceptions.reset_error_state;
        
            RETURN '';
    END get_bed_type;

    /***************************************************************************************************************
    *
    * Returns the description of the provided room
    *  
    * 
    * @param      i_lang              language ID
    * @param      i_prof              ALERT profissional 
    * @param      i_room               ID of the room.
    * @param      o_error
    *
    *
    * @RETURN  TRUE or FALSE
    * @author  Ricardo Nuno Almeida
    * @version 1.0
    * @since   21-07-2009
    *
    ****************************************************************************************************/
    FUNCTION get_room_type
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_room    IN room.id_room%TYPE,
        o_desc_rt OUT pk_translation.t_desc_translation,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_error := 'SELECT ROOM TYPE';
        SELECT nvl(rt.desc_room_type, pk_translation.get_translation(i_lang, rt.code_room_type))
          INTO o_desc_rt
          FROM room r
          LEFT JOIN room_type rt
            ON rt.id_room_type = r.id_room_type
         WHERE r.id_room = i_room;
    
        RETURN TRUE;
    EXCEPTION
    
        WHEN OTHERS THEN
        
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_pck_owner,
                                              g_pck_name,
                                              'GET_ROOM_TYPE',
                                              o_error);
        
            pk_alert_exceptions.reset_error_state;
        
            RETURN FALSE;
    END get_room_type;

    FUNCTION get_room_type
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional,
        i_room IN room.id_room%TYPE
    ) RETURN VARCHAR2 IS
        l_err  t_error_out;
        l_desc pk_translation.t_desc_translation;
    BEGIN
        g_error := 'CALL MAIN FUNCTION';
        IF NOT
            get_room_type(i_lang => i_lang, i_prof => i_prof, i_room => i_room, o_desc_rt => l_desc, o_error => l_err)
        THEN
            RETURN '';
        ELSE
            RETURN l_desc;
        END IF;
    
    EXCEPTION
    
        WHEN OTHERS THEN
        
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_pck_owner,
                                              g_pck_name,
                                              'GET_ROOM_TYPE',
                                              l_err);
        
            pk_alert_exceptions.reset_error_state;
        
            RETURN '';
    END get_room_type;

    /*******************************************************************************************************************************************
    * GET_ADMISSION_REQUESTS          Returns admission Request episodes for a specific id patient. 
    * 
    * @param I_LANG                   Language ID for translations
    * @param I_PROF                   Professional vector of information (professional ID, institution ID, software ID)
    * @param I_REQ_STATUS             Admission Request Status: S-scheduled, N-not scheduled, C-cancelled
    * @param I_FLG_EHR                Episode flg_ehr (N-registered episodes; S-scheduled episodes [not registered])
    * @param I_PATIENT                Patient id that is soposed to retunr information
    * @param i_id_epis_documentation  Barthel Index Evaluation ID
    * @param O_GRID                   Cursor that returns available information for current patient id
    * 
    * @return                         Returns TRUE if success, otherwise returns FALSE
    * 
    * @raises                         PL/SQL generic erro "OTHERS"
    * 
    * @author                         Sofia Mendes
    * @version                        2.6.0
    * @since                          2010/02/22
    *******************************************************************************************************************************************/
    FUNCTION get_admission_requests
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_patient               IN patient.id_patient%TYPE,
        i_req_status            IN wtl_epis.flg_status%TYPE,
        i_flg_ehr               IN episode.flg_ehr%TYPE,
        i_id_epis_documentation IN epis_documentation.id_epis_documentation%TYPE DEFAULT NULL,
        i_id_wtlist             IN waiting_list.id_waiting_list%TYPE DEFAULT NULL,
        o_adm_requests          OUT pk_types.cursor_type,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'GET CURSOR o_adm_requests';
        OPEN o_adm_requests FOR
            SELECT wl.id_waiting_list,
                   nvl(ai.desc_adm_indication, pk_translation.get_translation(i_lang, ai.code_adm_indication)) desc_admission,
                   pk_sr_clinical_info.get_proposed_surgery(i_lang, ssr.id_episode, i_prof, pk_alert_constant.g_no) surg_proc
              FROM waiting_list wl
             INNER JOIN wtl_epis we
                ON (wl.id_waiting_list = we.id_waiting_list)
             INNER JOIN episode epis
                ON (we.id_episode = epis.id_episode)
             INNER JOIN wtl_documentation wd
                ON (wl.id_waiting_list = wd.id_waiting_list)
              LEFT JOIN adm_request ar
                ON (ar.id_dest_episode = we.id_episode)
              LEFT JOIN adm_indication ai
                ON (ai.id_adm_indication = ar.id_adm_indication)
              LEFT JOIN schedule_sr ssr
                ON (ssr.id_waiting_list = wl.id_waiting_list)
             WHERE wl.id_patient = i_patient
               AND (i_req_status IS NULL OR we.flg_status = i_req_status)
               AND (i_flg_ehr IS NULL OR epis.flg_ehr = i_flg_ehr)
               AND wd.flg_type = pk_wtl_prv_core.g_wtl_doc_type_b
               AND wd.flg_status IN (pk_wtl_prv_core.g_wtl_doc_status_a, pk_wtl_prv_core.g_wtl_doc_status_p)
               AND (i_id_epis_documentation IS NULL OR wd.id_epis_documentation = i_id_epis_documentation)
               AND (i_id_wtlist IS NULL OR wl.id_waiting_list = i_id_wtlist);
        --
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_pck_owner,
                                              g_pck_name,
                                              'GET_ADMISSION_REQUESTS',
                                              o_error);
            pk_types.open_my_cursor(o_adm_requests);
            RETURN FALSE;
    END get_admission_requests;

    /*******************************************************************************************************************************************
    * GET_NURSE_INTAKE_ICONS          Returns all the icons that can appear in the nurse intake column of the admission grid. 
    * 
    * @param I_LANG                   Language ID for translations    
    * @param O_DATA                   Icons
    * @param O_ERROR                  Error stuf    
    * 
    * @return                         Returns TRUE if success, otherwise returns FALSE
    * 
    * @raises                         PL/SQL generic erro "OTHERS"
    * 
    * @author                         Sofia Mendes
    * @version                        2.6.0
    * @since                          2010/03/23
    *******************************************************************************************************************************************/
    FUNCTION get_nurse_intake_icons
    (
        i_lang  IN sys_domain.id_language%TYPE,
        o_data  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'GET nurse intake icons';
        OPEN o_data FOR --
            SELECT *
              FROM (SELECT desc_val label, val data, img_name icon, rank
                      FROM sys_domain s
                     WHERE s.code_domain = 'ADM_REQUEST.FLG_STATUS'
                       AND s.id_language = i_lang
                       AND s.domain_owner = pk_sysdomain.k_default_schema
                       AND s.flg_available = pk_alert_constant.g_yes
                       AND s.val IN (pk_alert_constant.g_adm_req_status_canc,
                                     pk_alert_constant.g_no,
                                     pk_alert_constant.g_adm_req_status_pend,
                                     pk_alert_constant.g_adm_req_status_done,
                                     pk_alert_constant.g_adm_req_status_unde,
                                     pk_alert_constant.g_adm_req_status_sche)
                    UNION ALL
                    SELECT desc_val label, val data, img_name icon, rank
                      FROM sys_domain s
                     WHERE s.code_domain = 'SCHEDULE_SR.FLG_STATUS'
                       AND s.domain_owner = pk_sysdomain.k_default_schema
                       AND s.id_language = i_lang
                       AND s.flg_available = pk_alert_constant.g_yes
                       AND s.val IN ('I'))
             ORDER BY label;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_data);
            RETURN pk_alert_exceptions.process_error(i_lang     => i_lang,
                                                     i_sqlcode  => SQLCODE,
                                                     i_sqlerrm  => SQLERRM,
                                                     i_message  => g_error,
                                                     i_owner    => g_pck_owner,
                                                     i_package  => g_pck_name,
                                                     i_function => 'GET_NURSE_INTAKE_ICONS',
                                                     o_error    => o_error);
    END get_nurse_intake_icons;

    /*******************************************************************************************************************************************
    * GET_REQ_STATUS_ICONS            Returns all the icons that can appear in the admission/surgery
    *                                 status column of the admission/surgery grid. 
    * 
    * @param I_LANG                   Language ID for translations    
    * @param O_DATA                   Icons
    * @param O_ERROR                  Error stuf    
    * 
    * @return                         Returns TRUE if success, otherwise returns FALSE
    * 
    * @raises                         PL/SQL generic erro "OTHERS"
    * 
    * @author                         Sofia Mendes
    * @version                        2.6.0
    * @since                          2010/03/23
    *******************************************************************************************************************************************/
    FUNCTION get_req_status_icons
    (
        i_lang  IN sys_domain.id_language%TYPE,
        o_data  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'GET admission/surgery request icons';
        OPEN o_data FOR --
            SELECT *
              FROM (SELECT desc_val label, val data, img_name icon, rank
                      FROM sys_domain s
                     WHERE s.code_domain = 'SCHEDULE_SR.ADM_NEEDED'
                       AND s.domain_owner = pk_sysdomain.k_default_schema
                       AND s.id_language = i_lang
                       AND s.flg_available = pk_alert_constant.g_yes
                       AND s.val IN ('N')
                    UNION ALL
                    SELECT desc_val label, val data, img_name icon, rank
                      FROM sys_domain s
                     WHERE s.code_domain = 'SCHEDULE_SR.FLG_STATUS'
                       AND s.domain_owner = pk_sysdomain.k_default_schema
                       AND s.id_language = i_lang
                       AND s.flg_available = pk_alert_constant.g_yes
                       AND s.val IN ('I', 'C')
                    UNION ALL
                    SELECT desc_val label, decode(val, 'I', 'O', val) data, img_name icon, rank
                      FROM sys_domain s
                     WHERE s.code_domain = 'ADM_REQUEST.FLG_STATUS'
                       AND s.domain_owner = pk_sysdomain.k_default_schema
                       AND s.id_language = i_lang
                       AND s.flg_available = pk_alert_constant.g_yes
                       AND s.val IN ('W', 'I', 'D', 'S', 'U'))
             ORDER BY label;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_data);
            RETURN pk_alert_exceptions.process_error(i_lang     => i_lang,
                                                     i_sqlcode  => SQLCODE,
                                                     i_sqlerrm  => SQLERRM,
                                                     i_message  => g_error,
                                                     i_owner    => g_pck_owner,
                                                     i_package  => g_pck_name,
                                                     i_function => 'GET_REQ_STATUS_ICONS',
                                                     o_error    => o_error);
    END get_req_status_icons;

    /********************************************************************************************
    * Gets the list of departments for the given list of institutions
    *
    * @param i_lang                       language id
    * @param i_prof                       professional, software and institution ids
    * @param i_ids_inst                   institution IDs
    * @param o_department                 department list
    * @param o_error                      Error message
    *                    
    * @return                             true or false on success or error
    *
    * @author                             Telmo Castro
    * @version                            2.6.0.3
    * @since                              07-06-2010
    **********************************************************************************************/
    FUNCTION get_department_list
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_ids_inst   IN table_number,
        o_department OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_exists NUMBER(1) := 1;
    BEGIN
        IF i_ids_inst IS NULL
           OR i_ids_inst.count = 0
        THEN
            l_exists := 0;
        END IF;
    
        g_error := 'GET CURSOR';
        OPEN o_department FOR
            SELECT id_department, pk_translation.get_translation(i_lang, code_department) department
              FROM department d
             WHERE (l_exists = 0 OR
                   (d.id_institution IN (SELECT *
                                            FROM TABLE(i_ids_inst))))
               AND EXISTS (SELECT r.id_department
                      FROM room r
                     WHERE r.id_department = d.id_department
                       AND r.flg_transp = pk_alert_constant.g_available
                       AND r.flg_available = pk_alert_constant.g_available)
               AND instr(d.flg_type, 'I') > 0
               AND d.flg_available = pk_alert_constant.g_available
             ORDER BY rank, department;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_pck_owner,
                                              g_pck_name,
                                              'GET_DEPARTMENT_LIST',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_department);
            RETURN FALSE;
    END get_department_list;

    /*******************************************************************************************************************************************
    * GET_AR_EPISODES                 Returns Surgery Request episodes for a specific id patient. 
    * 
    * @param I_LANG                   Language ID for translations
    * @param I_PROF                   Professional vector of information (professional ID, institution ID, software ID)
    * @param I_PATIENT                Patient id that is soposed to retunr information
    * @param I_START_DT               Start date to be consider to filter data
    * @param I_END_DT                 End date to be consider to filter data
    * 
    * @return                         Returns a table function of Ongoing or Future Events of Surgery Request
    * 
    * @author                         António Neto
    * @version                        2.6.0.5
    * @since                          02-Feb-2011
    *******************************************************************************************************************************************/
    FUNCTION get_ar_episodes
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_patient  IN patient.id_patient%TYPE,
        i_start_dt IN TIMESTAMP WITH TIME ZONE DEFAULT NULL,
        i_end_dt   IN TIMESTAMP WITH TIME ZONE DEFAULT NULL
    ) RETURN t_tbl_ar_episodes IS
        l_tbl_ar_epis t_tbl_ar_episodes;
    
        l_error            t_error_out;
        l_grid_date_format sys_message.desc_message%TYPE;
    BEGIN
    
        -- GET institution date format string
        l_grid_date_format := pk_message.get_message(i_lang, g_grid_date_format);
    
        SELECT t_rec_ar_episodes(rank,
                                  desc_admission,
                                  waiting_list_type,
                                  id_waiting_list,
                                  adm_needed,
                                  sur_needed,
                                  admiss_epis_done,
                                  pk_date_utils.to_char_insttimezone(i_lang, i_prof, dt_admission_int, l_grid_date_format),
                                  duration,
                                  id_episode,
                                  id_dest_inst,
                                  flg_status,
                                  nurse_intake_status,
                                  oris_status,
                                  admiss_status,
                                  adm_type,
                                  adm_status,
                                  inst_adm_name,
                                  id_inst_adm,
                                  adm_type_icon,
                                  id_discharge,
                                  flg_epis_status,
                                  id_schedule,
                                  
                                  id_adm_request,
                                  dt_admission_int,
                                  id_prof_req,
                                  id_dest_prof,
                                  adm_status,
                                  id_dep_clin_serv,
                                  CASE
                                      WHEN flg_ehr = pk_alert_constant.g_flg_ehr_n
                                           OR adm_type = pk_alert_constant.g_no
                                           OR flg_status IN ('C', 'D') THEN
                                       pk_alert_constant.g_no
                                      ELSE
                                       pk_alert_constant.g_yes
                                  END,
                                  --
                                  dt_discharge,
                                  id_department,
                                  desc_dpt,
                                  discharge_type,
                                  CASE
                                      WHEN flg_status IN (pk_alert_constant.g_adm_req_status_sche, pk_alert_constant.g_adm_req_status_pend) THEN
                                       pk_alert_constant.g_no
                                      WHEN flg_status_pos NOT IN (pk_consult_req.g_sched_pend, pk_consult_req.g_sched_canc) THEN
                                       pk_alert_constant.g_no
                                      ELSE
                                       pk_alert_constant.g_yes
                                  END,
                                  id_prev_episode)
          BULK COLLECT
          INTO l_tbl_ar_epis
          FROM (SELECT t_internal.rank,
                       t_internal.desc_admission,
                       t_internal.waiting_list_type,
                       t_internal.id_waiting_list,
                       t_internal.adm_needed,
                       t_internal.sur_needed,
                       t_internal.admiss_epis_done,
                       pk_surgery_request.get_wl_status_date_dtz(i_lang,
                                                                 i_prof,
                                                                 t_internal.id_episode,
                                                                 t_internal.id_waiting_list,
                                                                 t_internal.flg_epis_status) dt_admission_int,
                       t_internal.duration,
                       t_internal.id_episode,
                       t_internal.id_dest_inst,
                       
                       decode(admiss_epis_done,
                              pk_alert_constant.g_yes,
                              pk_alert_constant.g_adm_req_status_done,
                              decode(surgery_epis_done,
                                     pk_alert_constant.g_yes,
                                     pk_alert_constant.g_adm_req_status_done,
                                     t_internal.flg_status)) flg_status,
                       
                       t_internal.nurse_intake_status,
                       t_internal.oris_status,
                       t_internal.admiss_status,
                       t_internal.adm_type,
                       pk_surgery_request.get_wl_status_msg(i_lang, i_prof, t_internal.flg_epis_status) adm_status,
                       
                       t_internal.inst_adm_name,
                       t_internal.id_inst_adm,
                       t_internal.adm_type_icon,
                       t_internal.id_discharge,
                       t_internal.flg_epis_status,
                       pk_schedule_inp.get_schedule_id(i_lang, i_prof, t_internal.id_episode) AS id_schedule,
                       
                       id_adm_request,
                       id_prof_req,
                       id_dest_prof,
                       id_dep_clin_serv,
                       flg_ehr,
                       --
                       t_internal.dt_discharge,
                       t_internal.id_department,
                       t_internal.desc_dpt,
                       t_internal.discharge_type,
                       t_internal.flg_status_pos,
                       t_internal.id_prev_episode
                  FROM (SELECT 2 rank,
                               decode(ai.id_adm_indication,
                                      g_reason_admission_ft,
                                      ar.adm_indication_ft,
                                      (nvl(ai.desc_adm_indication,
                                           pk_translation.get_translation(i_lang, ai.code_adm_indication)))) desc_admission,
                               wl.flg_type waiting_list_type,
                               we.id_waiting_list,
                               nvl(ssr.adm_needed, pk_alert_constant.g_yes) adm_needed,
                               decode(wl.flg_type,
                                      pk_alert_constant.g_wl_status_s,
                                      pk_alert_constant.g_yes,
                                      pk_alert_constant.g_wl_status_a,
                                      pk_alert_constant.g_yes,
                                      pk_alert_constant.g_no) sur_needed,
                               pk_surgery_request.get_epis_done_state(i_lang,
                                                                      wl.id_waiting_list,
                                                                      pk_alert_constant.g_epis_type_inpatient) admiss_epis_done,
                               pk_surgery_request.get_epis_done_state(i_lang,
                                                                      wl.id_waiting_list,
                                                                      pk_alert_constant.g_epis_type_operating) surgery_epis_done,
                               
                               pk_admission_request.get_duration_desc(i_lang, i_prof, ar.expected_duration) duration,
                               ar.id_dest_episode id_episode,
                               ar.id_dest_inst,
                               wl.flg_status,
                               pk_admission_request.get_intake_status_str(i_lang,
                                                                          i_prof,
                                                                          ar.id_adm_request,
                                                                          we.id_waiting_list) nurse_intake_status,
                               pk_surgery_request.get_completwl_status_str(i_lang,
                                                                           i_prof,
                                                                           wl.id_waiting_list,
                                                                           decode(wl.flg_type,
                                                                                  pk_alert_constant.g_wl_status_a,
                                                                                  pk_alert_constant.g_yes,
                                                                                  pk_alert_constant.g_no), --ssr.adm_needed,
                                                                           pos.id_sr_pos_status,
                                                                           pk_alert_constant.g_epis_type_operating,
                                                                           wl.flg_type) oris_status,
                               pk_surgery_request.get_wl_status_str(i_lang,
                                                                    i_prof,
                                                                    wl.id_waiting_list,
                                                                    decode(wl.flg_type,
                                                                           pk_alert_constant.g_wl_status_a,
                                                                           pk_alert_constant.g_yes,
                                                                           pk_alert_constant.g_no), --ssr.adm_needed,
                                                                    pos.id_sr_pos_status,
                                                                    pk_alert_constant.g_epis_type_inpatient,
                                                                    wl.flg_type) admiss_status,
                               pk_alert_constant.g_active adm_type,
                               pk_translation.get_translation(i_lang,
                                                              (SELECT i.code_institution
                                                                 FROM institution i
                                                                WHERE i.id_institution = ar.id_dest_inst)) inst_adm_name,
                               ar.id_dest_inst id_inst_adm,
                               pk_sysdomain.get_img(i_lang, 'SCHEDULE_SR.FLG_SCHED', pk_alert_constant.g_active) adm_type_icon,
                               NULL id_discharge,
                               pk_surgery_request.get_wl_status_flg(i_lang,
                                                                    i_prof,
                                                                    wl.id_waiting_list,
                                                                    decode(wl.flg_type,
                                                                           pk_alert_constant.g_wl_status_a,
                                                                           pk_alert_constant.g_yes,
                                                                           pk_alert_constant.g_no), --ssr.adm_needed,
                                                                    pos.id_sr_pos_status,
                                                                    pk_alert_constant.g_epis_type_inpatient,
                                                                    wl.flg_type) flg_epis_status,
                               rank() over(PARTITION BY ssr.id_schedule_sr ORDER BY pos.dt_req DESC, pos.dt_reg DESC) origin_rank,
                               
                               ar.id_adm_request,
                               wl.id_prof_req,
                               ar.id_dest_prof,
                               ar.id_dep_clin_serv,
                               epi.flg_ehr,
                               --
                               pk_discharge.get_discharge_date(i_lang, i_prof, ar.id_dest_episode) dt_discharge,
                               dpt.id_department,
                               pk_translation.get_translation(i_lang, dpt.code_department) desc_dpt,
                               pk_inp_grid.get_discharge_msg(i_lang, i_prof, epi.id_episode, NULL) discharge_type,
                               cr.flg_status flg_status_pos,
                               epi.id_prev_episode
                          FROM adm_request ar
                         INNER JOIN adm_indication ai
                            ON (ai.id_adm_indication = ar.id_adm_indication)
                         INNER JOIN wtl_epis we
                            ON (we.id_episode = ar.id_dest_episode)
                         INNER JOIN episode epi
                            ON (epi.id_episode = we.id_episode)
                         INNER JOIN waiting_list wl
                            ON (wl.id_waiting_list = we.id_waiting_list)
                          LEFT JOIN schedule_sr ssr
                            ON (ssr.id_waiting_list = wl.id_waiting_list)
                          LEFT JOIN sr_pos_schedule pos
                            ON (pos.id_schedule_sr = ssr.id_schedule_sr)
                          LEFT JOIN consult_req cr
                            ON cr.id_consult_req = pos.id_pos_consult_req
                          LEFT JOIN (SELECT id_sr_pos_status, flg_status
                                      FROM (SELECT sps1.id_sr_pos_status,
                                                   sps1.flg_status,
                                                   rank() over(ORDER BY sps1.id_institution DESC) origin_rank
                                              FROM sr_pos_status sps1
                                             WHERE sps1.id_institution IN (0, i_prof.institution))
                                     WHERE origin_rank = 1) sps
                            ON sps.id_sr_pos_status = pos.id_sr_pos_status
                          LEFT JOIN department dpt
                            ON ar.id_department = dpt.id_department
                         WHERE wl.id_patient = i_patient
                           AND (ar.dt_admission >= i_start_dt OR i_start_dt IS NULL)
                           AND (ar.dt_admission <= i_end_dt OR i_end_dt IS NULL)
                        --
                        ) t_internal
                 WHERE t_internal.origin_rank = 1
                --
                UNION
                --
                SELECT
                
                 t_epis.rank,
                 t_epis.desc_admission,
                 t_epis.waiting_list_type,
                 t_epis.id_waiting_list,
                 t_epis.adm_needed,
                 t_epis.sur_needed,
                 t_epis.admiss_epis_done,
                 t_epis.dt_admission_int,
                 t_epis.duration,
                 t_epis.id_episode,
                 t_epis.id_dest_inst,
                 t_epis.flg_status,
                 t_epis.nurse_intake_status,
                 t_epis.oris_status,
                 t_epis.admiss_status,
                 t_epis.adm_type,
                 t_epis.adm_status,
                 t_epis.inst_adm_name,
                 t_epis.id_inst_adm,
                 t_epis.adm_type_icon,
                 t_epis.id_discharge,
                 t_epis.flg_epis_status,
                 t_epis.id_schedule,
                 
                 t_epis.id_adm_request,
                 t_epis.id_prof_req,
                 t_epis.id_dest_prof,
                 id_dep_clin_serv,
                 flg_ehr,
                 --
                 t_epis.dt_discharge,
                 t_epis.id_department,
                 t_epis.desc_dpt,
                 t_epis.discharge_type,
                 NULL flg_status_pos,
                 t_epis.id_prev_episode
                  FROM (SELECT DISTINCT --
                                        1 rank,
                                        pk_admission_request.get_all_diagnosis_str(i_lang, e.id_episode) desc_admission,
                                        NULL waiting_list_type,
                                        NULL id_waiting_list,
                                        NULL adm_needed,
                                        NULL sur_needed,
                                        decode((SELECT decode(COUNT(0), 0, pk_alert_constant.g_yes, pk_alert_constant.g_no)
                                                 FROM discharge dis
                                                WHERE dis.id_episode = e.id_episode
                                                  AND dis.flg_status = pk_alert_constant.g_active
                                                  AND pk_discharge_core.check_admin_discharge(i_lang,
                                                                                              i_prof,
                                                                                              NULL,
                                                                                              dis.flg_status_adm) =
                                                      pk_alert_constant.g_yes),
                                               pk_alert_constant.g_yes,
                                               pk_alert_constant.g_no,
                                               pk_alert_constant.g_yes) admiss_epis_done,
                                        --
                                        decode(e.flg_ehr,
                                               'S',
                                               e.dt_begin_tstz,
                                               decode((SELECT decode(COUNT(0),
                                                                    0,
                                                                    pk_alert_constant.g_yes,
                                                                    pk_alert_constant.g_no)
                                                        FROM discharge dis
                                                       WHERE dis.id_episode = e.id_episode
                                                         AND dis.flg_status = pk_alert_constant.g_active
                                                         AND pk_discharge_core.check_admin_discharge(i_lang,
                                                                                                     i_prof,
                                                                                                     NULL,
                                                                                                     dis.flg_status_adm) =
                                                             pk_alert_constant.g_yes),
                                                      pk_alert_constant.g_yes,
                                                      e.dt_begin_tstz,
                                                      dc.dt_admin_tstz)) dt_admission_int,
                                        nvl((SELECT pk_admission_request.get_duration(i_lang,
                                                                                     pk_date_utils.diff_timestamp(dis.dt_admin_tstz,
                                                                                                                  e.dt_begin_tstz) * 24)
                                              FROM discharge dis
                                             WHERE dis.id_episode = e.id_episode
                                               AND dis.flg_status = pk_alert_constant.g_active
                                                  --AND dis.dt_med_tstz IS NOT NULL
                                               AND pk_discharge_core.check_admin_discharge(i_lang,
                                                                                           i_prof,
                                                                                           NULL,
                                                                                           dis.flg_status_adm) =
                                                   pk_alert_constant.g_yes),
                                            (SELECT pk_admission_request.get_duration(i_lang,
                                                                                      pk_date_utils.diff_timestamp(ds.dt_discharge_schedule,
                                                                                                                   e.dt_begin_tstz) * 24)
                                               FROM discharge_schedule ds
                                              WHERE ds.id_episode = e.id_episode
                                                AND ds.flg_status = pk_alert_constant.g_yes)) duration,
                                        e.id_episode,
                                        e.id_institution id_dest_inst,
                                        decode((SELECT decode(COUNT(0), 0, pk_alert_constant.g_yes, pk_alert_constant.g_no)
                                                 FROM discharge dis
                                                WHERE dis.id_episode = e.id_episode
                                                  AND dis.flg_status = pk_alert_constant.g_active
                                                  AND dis.dt_med_tstz IS NOT NULL
                                                  AND pk_discharge_core.check_admin_discharge(i_lang,
                                                                                              i_prof,
                                                                                              NULL,
                                                                                              dis.flg_status_adm) =
                                                      pk_alert_constant.g_yes),
                                               pk_alert_constant.g_yes,
                                               pk_alert_constant.g_adm_req_status_unde,
                                               pk_alert_constant.g_adm_req_status_done) flg_status,
                                        -- José Brito 03/09/2009
                                        -- Nurse intake: always show "Not needed" for these episodes
                                        pk_utils.get_status_string_immediate(i_lang,
                                                                             i_prof,
                                                                             'I',
                                                                             'N',
                                                                             'SCHEDULE_SR.ADM_NEEDED',
                                                                             'SCHEDULE_SR.ADM_NEEDED',
                                                                             'SCHEDULE_SR.ADM_NEEDED',
                                                                             NULL,
                                                                             NULL,
                                                                             NULL,
                                                                             NULL,
                                                                             NULL,
                                                                             NULL,
                                                                             current_timestamp) nurse_intake_status,
                                        pk_utils.get_status_string_immediate(i_lang,
                                                                             i_prof,
                                                                             'I',
                                                                             decode((SELECT pk_sr_approval.get_status_surg_proc(i_lang,
                                                                                                                               i_prof,
                                                                                                                               eps.id_episode)
                                                                                      FROM episode eps
                                                                                     WHERE eps.id_epis_type =
                                                                                           pk_alert_constant.g_epis_type_operating
                                                                                       AND eps.id_prev_episode =
                                                                                           e.id_episode
                                                                                       AND e.dt_creation = eps.dt_creation),
                                                                                    NULL,
                                                                                    pk_alert_constant.g_no),
                                                                             'ADM_REQUEST.FLG_STATUS',
                                                                             'ADM_REQUEST.FLG_STATUS',
                                                                             'ADM_REQUEST.FLG_STATUS',
                                                                             NULL,
                                                                             NULL,
                                                                             NULL,
                                                                             NULL,
                                                                             NULL,
                                                                             NULL,
                                                                             current_timestamp) oris_status,
                                        pk_utils.get_status_string_immediate(i_lang,
                                                                             i_prof,
                                                                             'I',
                                                                             decode(e.flg_ehr,
                                                                                    'S',
                                                                                    pk_alert_constant.g_adm_req_status_sche,
                                                                                    pk_alert_constant.g_flg_ehr_n,
                                                                                    decode(e.flg_status,
                                                                                           pk_alert_constant.g_active /*g_yes*/,
                                                                                           pk_alert_constant.g_adm_req_status_unde,
                                                                                           pk_alert_constant.g_adm_req_status_done)),
                                                                             'ADM_REQUEST.FLG_STATUS',
                                                                             'ADM_REQUEST.FLG_STATUS',
                                                                             'ADM_REQUEST.FLG_STATUS',
                                                                             NULL,
                                                                             NULL,
                                                                             NULL,
                                                                             NULL,
                                                                             NULL,
                                                                             NULL,
                                                                             current_timestamp) admiss_status,
                                        pk_alert_constant.g_no adm_type,
                                        decode((decode((SELECT decode(COUNT(0),
                                                                     0,
                                                                     pk_alert_constant.g_yes,
                                                                     pk_alert_constant.g_no)
                                                         FROM discharge dis
                                                        WHERE dis.id_episode = e.id_episode
                                                          AND dis.flg_status = pk_alert_constant.g_active
                                                             --AND dis.dt_med_tstz IS NOT NULL
                                                          AND pk_discharge_core.check_admin_discharge(i_lang,
                                                                                                      i_prof,
                                                                                                      NULL,
                                                                                                      dis.flg_status_adm) =
                                                              pk_alert_constant.g_yes),
                                                       pk_alert_constant.g_yes,
                                                       pk_alert_constant.g_adm_req_status_unde,
                                                       pk_alert_constant.g_adm_req_status_done)),
                                               pk_alert_constant.g_adm_req_status_unde,
                                               pk_message.get_message(i_lang, 'INP_GRID_SR_T002'),
                                               pk_alert_constant.g_adm_req_status_done,
                                               pk_message.get_message(i_lang, 'INP_GRID_SR_T001')) adm_status,
                                        pk_translation.get_translation(i_lang, i.code_institution) inst_adm_name,
                                        e.id_institution id_inst_adm,
                                        pk_sysdomain.get_img(i_lang, 'SCHEDULE_SR.FLG_SCHED', pk_alert_constant.g_no) adm_type_icon,
                                        dc.id_discharge,
                                        decode(e.flg_status,
                                               pk_alert_constant.g_epis_status_active,
                                               pk_alert_constant.g_adm_req_status_unde,
                                               pk_alert_constant.g_adm_req_status_done) AS flg_epis_status,
                                        
                                        NULL                id_adm_request,
                                        NULL                id_prof_req,
                                        NULL                id_dest_prof,
                                        NULL                AS id_schedule,
                                        ei.id_dep_clin_serv,
                                        e.flg_ehr,
                                        --
                                        pk_discharge.get_discharge_date(i_lang, i_prof, e.id_episode) dt_discharge,
                                        dpt.id_department,
                                        pk_translation.get_translation(i_lang, dpt.code_department) desc_dpt,
                                        pk_inp_grid.get_discharge_msg(i_lang, i_prof, e.id_episode, NULL) discharge_type,
                                        e.id_prev_episode
                          FROM (SELECT *
                                  FROM episode e
                                 START WITH e.id_episode IN
                                            (SELECT column_value
                                               FROM TABLE(CAST(MULTISET (SELECT ar.id_dest_episode id_episode
                                                                  FROM adm_request ar
                                                                 INNER JOIN wtl_epis we
                                                                    ON (we.id_episode = ar.id_dest_episode)
                                                                 INNER JOIN waiting_list wl
                                                                    ON (wl.id_waiting_list = we.id_waiting_list)
                                                                 WHERE wl.id_patient = i_patient) AS table_number))
                                             -- Jose Brito 03/09/2009 ALERT-40328 List patient admissions, before inserting records in Admission Request 
                                             /*                                             UNION ALL
                                             SELECT column_value
                                               FROM TABLE(CAST(MULTISET (SELECT e1.id_episode
                                                                  FROM episode e1
                                                                 WHERE e1.id_patient = i_patient) AS table_number))*/
                                             )
                                CONNECT BY PRIOR e.id_prev_episode = e.id_episode) e
                         INNER JOIN epis_info ei
                            ON ei.id_episode = e.id_episode
                         INNER JOIN institution i
                            ON i.id_institution = e.id_institution
                          LEFT JOIN discharge dc
                            ON dc.id_episode = e.id_episode
                           AND dc.flg_status = pk_discharge.g_disch_flg_status_active
                          LEFT JOIN department dpt
                            ON e.id_department = dpt.id_department
                         WHERE e.id_epis_type = pk_alert_constant.g_epis_type_inpatient
                              -- Sofia Mendes (25-11-2009): The cancelled episodes does not appear on the grid. 
                           AND e.flg_type != pk_episode.g_flg_temp
                           AND e.flg_status <> pk_alert_constant.g_epis_status_cancel
                           AND (e.dt_begin_tstz >= i_start_dt OR i_start_dt IS NULL)
                           AND (e.dt_begin_tstz <= i_end_dt OR i_end_dt IS NULL)) t_epis
                -- 
                 WHERE id_episode NOT IN
                       (SELECT column_value
                          FROM TABLE(CAST(MULTISET (SELECT ar.id_dest_episode id_episode
                                             FROM adm_request ar
                                            INNER JOIN adm_indication ai
                                               ON (ai.id_adm_indication = ar.id_adm_indication)
                                            INNER JOIN wtl_epis we
                                               ON (we.id_episode = ar.id_dest_episode)
                                            INNER JOIN waiting_list wl
                                               ON (wl.id_waiting_list = we.id_waiting_list)
                                             LEFT JOIN schedule_sr ssr
                                               ON (ssr.id_waiting_list = wl.id_waiting_list)
                                             LEFT JOIN (SELECT id_schedule_sr
                                                         FROM (SELECT sps.id_schedule_sr,
                                                                      rank() over(PARTITION BY sps.id_schedule_sr ORDER BY sps.dt_req DESC, sps.dt_reg DESC) origin_rank
                                                                 FROM sr_pos_schedule sps
                                                                WHERE sps.flg_status = pk_alert_constant.g_active) t
                                                        WHERE t.origin_rank = 1) pos
                                               ON (pos.id_schedule_sr = ssr.id_schedule_sr)) AS table_number)))
                -- 
                 ORDER BY rank, admiss_status DESC, dt_admission_int) tbl_info;
    
        RETURN l_tbl_ar_epis;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_ADMISSION_REQUEST',
                                              'GET_AR_EPISODES',
                                              l_error);
            RETURN NULL;
    END get_ar_episodes;

    FUNCTION get_value_from_time_pref(i_val IN VARCHAR2) RETURN NUMBER AS
        l_ret NUMBER(24);
    BEGIN
    
        CASE i_val
            WHEN 'M' THEN
                l_ret := 1;
            WHEN 'A' THEN
                l_ret := 2;
            WHEN 'N' THEN
                l_ret := 3;
            WHEN 'O' THEN
                l_ret := 4;
            ELSE
                l_ret := -1;
        END CASE;
    
        RETURN l_ret;
    END get_value_from_time_pref;

    /**
    * Get Inpatient & Surgery task description.
    * Used for the task timeline easy access (HandP import mechanism).
    *
    * @param i_lang              language identifier
    * @param i_prof              logged professional structure
    * @param i_id_adm_request    adm request identifier
    * @param i_desc_type         de4sc_type S-short/L-long
    *
    * @return               diet task description
    *
    * @author              Jorge Silva
    * @version              2.6.2
    * @since                2012/09/03
    */
    FUNCTION get_description
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_adm_request IN adm_request.id_adm_request%TYPE,
        i_desc_type   IN VARCHAR2
    ) RETURN CLOB IS
        l_ret CLOB;
    
        CURSOR c_desc IS
            SELECT decode(i_desc_type,
                          pk_prog_notes_constants.g_desc_type_s,
                          pk_message.get_message(i_lang, 'ADM_REQUEST_T001'),
                          pk_message.get_message(i_lang, 'ADM_REQUEST_T027')) || ': ' || event_type_clinical_service ||
                   decode(desc_dep_clin_serv, '', '', ', ' || desc_dep_clin_serv) ||
                   decode(interv_desc,
                          '',
                          '',
                          chr(10) || decode(i_desc_type,
                                            pk_prog_notes_constants.g_desc_type_s,
                                            pk_message.get_message(i_lang, 'SURGERY_REQUEST_T042'),
                                            pk_message.get_message(i_lang, 'SURGERY_REQUEST_T009')) || ': ' ||
                          interv_desc) || decode(spec_desc, '', '', ', ' || spec_desc) ||
                   decode(i_desc_type,
                          pk_prog_notes_constants.g_desc_type_s,
                          nvl2(dt_admission, ',' || dt_admission, ''),
                          '') || ', ' || request_status_desc descr
              FROM (SELECT decode(ai.desc_adm_indication, '', '', ai.desc_adm_indication) event_type_clinical_service,
                           pk_surgery_request.get_wl_status_msg(i_lang,
                                                                i_prof,
                                                                pk_surgery_request.get_wl_status_flg(i_lang,
                                                                                                     i_prof,
                                                                                                     wl.id_waiting_list,
                                                                                                     decode(wl.flg_type,
                                                                                                            pk_alert_constant.g_wl_status_a,
                                                                                                            pk_alert_constant.g_yes,
                                                                                                            pk_alert_constant.g_no), --ssr.adm_needed,
                                                                                                     pos.id_sr_pos_status,
                                                                                                     pk_alert_constant.g_epis_type_inpatient,
                                                                                                     wl.flg_type)) request_status_desc,
                           --   pk_date_utils.date_char_tsz(i_lang, ar.dt_nit_suggested, i_prof.institution, i_prof.software) dt_admission,
                           pk_date_utils.dt_chr_tsz(i_lang,
                                                    pk_surgery_request.get_wl_status_date_dtz(i_lang,
                                                                                              i_prof,
                                                                                              id_dest_episode,
                                                                                              wl.id_waiting_list,
                                                                                              epis.flg_status),
                                                    i_prof.institution,
                                                    i_prof.software) dt_admission,
                           pk_translation.get_translation(i_lang, cs2.code_clinical_service) desc_dep_clin_serv,
                           pk_sr_clinical_info.get_proposed_surgery(i_lang,
                                                                    ssr.id_episode,
                                                                    i_prof,
                                                                    pk_alert_constant.g_no) interv_desc,
                           pk_translation.get_translation(i_lang, cs.code_clinical_service) spec_desc
                      FROM adm_request ar
                     INNER JOIN adm_indication ai
                        ON ai.id_adm_indication = ar.id_adm_indication
                      LEFT JOIN dep_clin_serv dcs1
                        ON dcs1.id_dep_clin_serv = ar.id_dep_clin_serv
                      LEFT JOIN clinical_service cs2
                        ON cs2.id_clinical_service = dcs1.id_clinical_service
                     INNER JOIN wtl_epis we
                        ON (we.id_episode = ar.id_dest_episode)
                     INNER JOIN episode epis
                        ON (epis.id_episode = ar.id_upd_episode)
                     INNER JOIN waiting_list wl
                        ON (wl.id_waiting_list = we.id_waiting_list)
                      LEFT JOIN schedule_sr ssr
                        ON (ssr.id_waiting_list = wl.id_waiting_list)
                      LEFT JOIN sr_pos_schedule pos
                        ON (pos.id_schedule_sr = ssr.id_schedule_sr)
                      LEFT JOIN wtl_dep_clin_serv wdcs
                        ON wdcs.id_waiting_list = wl.id_waiting_list
                       AND wdcs.flg_status = pk_alert_constant.g_sr_pos_status_a
                      LEFT JOIN dep_clin_serv dcs2
                        ON dcs2.id_dep_clin_serv = wdcs.id_dep_clin_serv
                      LEFT JOIN clinical_service cs
                        ON cs.id_clinical_service = dcs2.id_clinical_service
                     WHERE ar.id_adm_request = i_adm_request);
    
    BEGIN
        OPEN c_desc;
        FETCH c_desc
            INTO l_ret;
        CLOSE c_desc;
    
        RETURN l_ret;
    END get_description;

    /**
    * Get future events icon
    *
    * @param i_lang              language identifier
    * @param i_prof              logged professional structure
    * @param i_id_episode        episode  identifier
    *
    * @return               future events icon
    *
    * @author              Paulo Teixeira
    * @version              2.6
    * @since                2014/10/02
    */
    FUNCTION get_fe_icon
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE
    ) RETURN VARCHAR2 IS
        l_ret   sys_message.desc_message%TYPE;
        l_count NUMBER(12);
    BEGIN
    
        l_count := pk_episode.count_oris_inp_visit_epis(i_lang       => i_lang,
                                                        i_prof       => i_prof,
                                                        i_id_episode => i_id_episode);
    
        IF l_count = 1
        THEN
            l_ret := 'DetailInternmentIcon';
        ELSE
            l_ret := 'DetailInternmentIcon'; --'INPSurgeryIcon';
        END IF;
    
        RETURN l_ret;
    END get_fe_icon;
    /**
    * Get future events desc
    *
    * @param i_lang              language identifier
    * @param i_prof              logged professional structure
    * @param i_id_episode        episode  identifier
    *
    * @return               future events description
    *
    * @author              Paulo Teixeira
    * @version              2.6
    * @since                2014/10/02
    */
    FUNCTION get_fe_desc
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE
    ) RETURN VARCHAR2 IS
        l_ret   sys_message.desc_message%TYPE;
        l_count NUMBER(12);
    BEGIN
    
        l_count := pk_episode.count_oris_inp_visit_epis(i_lang       => i_lang,
                                                        i_prof       => i_prof,
                                                        i_id_episode => i_id_episode);
    
        IF l_count = 1
        THEN
            l_ret := pk_message.get_message(i_lang, i_prof, 'INP_FE_T001');
        ELSE
            l_ret := pk_message.get_message(i_lang, i_prof, 'INP_FE_T002');
        END IF;
    
        RETURN l_ret;
    END get_fe_desc;
    /**
    * get_can_admit
    *
    * @param i_lang              language identifier
    * @param i_prof              logged professional structure
    * @param i_id_episode        episode  identifier
    *
    * @return               get_can_admit
    *
    * @author              Paulo Teixeira
    * @version              2.6
    * @since                2014/10/02
    */
    FUNCTION get_can_admit
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE
    ) RETURN VARCHAR2 IS
        l_ret        sys_message.desc_message%TYPE;
        l_wtl_status wtl_epis.flg_status%TYPE;
    BEGIN
    
        IF pk_sysconfig.get_config(i_code_cf => 'INP_SURG_ADM_REQ_ACTION', i_prof => i_prof) = pk_alert_constant.g_no
        THEN
            l_ret := pk_alert_constant.g_no;
        ELSE
            BEGIN
                SELECT we.flg_status
                  INTO l_wtl_status
                  FROM episode e
                  JOIN wtl_epis we
                    ON we.id_episode = e.id_episode
                 WHERE e.id_epis_type = pk_alert_constant.g_epis_type_operating
                   AND nvl(e.id_prev_epis_type, -1) != pk_alert_constant.g_epis_type_inpatient
                   AND e.id_episode = i_id_episode;
            EXCEPTION
                WHEN OTHERS THEN
                    l_wtl_status := NULL;
            END;
            IF l_wtl_status = pk_alert_constant.g_schedule_sr_status_s
            THEN
                l_ret := pk_alert_constant.g_yes;
            ELSE
                l_ret := pk_alert_constant.g_no;
            END IF;
        END IF;
    
        RETURN l_ret;
    END get_can_admit;

    PROCEDURE add_new_def_event
    (
        i_pk              IN ds_def_event.id_def_event%TYPE,
        i_ds_cmpt_mkt_rel IN ds_cmpt_mkt_rel.id_ds_cmpt_mkt_rel%TYPE,
        i_flg_event_type  IN ds_def_event.flg_event_type%TYPE,
        io_tbl_def_events IN OUT NOCOPY t_table_ds_def_events
    ) IS
        l_proc_name CONSTANT VARCHAR2(30) := 'ADD_NEW_DEF_EVENT';
        --
        r_ds_def_event    t_rec_ds_def_events;
        l_def_event_found BOOLEAN := FALSE;
    BEGIN
        IF io_tbl_def_events.exists(1)
        THEN
            FOR i IN io_tbl_def_events.first .. io_tbl_def_events.last
            LOOP
                IF io_tbl_def_events(i).id_ds_cmpt_mkt_rel = i_ds_cmpt_mkt_rel
                THEN
                    io_tbl_def_events(i).flg_event_type := i_flg_event_type;
                    io_tbl_def_events(i).id_def_event := i_pk; --This way I know that the value was changed in code
                    l_def_event_found := TRUE;
                    EXIT;
                END IF;
            END LOOP;
        END IF;
    
        IF NOT l_def_event_found
        THEN
            g_error := 'NEW T_REC_DS_DEF_EVENTS INSTANCE';
            pk_alertlog.log_debug(text            => g_error,
                                  object_name     => 'PK_ADMISSION_REQUEST',
                                  sub_object_name => l_proc_name);
            r_ds_def_event := t_rec_ds_def_events(id_ds_cmpt_mkt_rel => i_ds_cmpt_mkt_rel,
                                                  id_def_event       => i_pk,
                                                  flg_event_type     => i_flg_event_type);
        
            g_error := 'ADD DEF_EVENT TO IO_TBL_DEF_EVENTS';
            pk_alertlog.log_debug(text            => g_error,
                                  object_name     => 'PK_ADMISSION_REQUEST',
                                  sub_object_name => l_proc_name);
            io_tbl_def_events.extend;
            io_tbl_def_events(io_tbl_def_events.count) := r_ds_def_event;
        END IF;
    END add_new_def_event;

    FUNCTION add_def_events
    (
        i_lang            IN language.id_language%TYPE,
        i_ds_cmpt_mkt_rel IN ds_cmpt_mkt_rel.id_ds_cmpt_mkt_rel%TYPE,
        i_internal_name   IN ds_component.internal_name%TYPE,
        i_edt_mode        IN VARCHAR2,
        i_has_surgery     IN VARCHAR2,
        i_has_lvl_urg     IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        i_inst_location   IN VARCHAR2,
        i_adm_indication  IN NUMBER,
        i_spec_surgery    IN VARCHAR2,
        i_flg_nit         IN VARCHAR2,
        i_has_unav        IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        io_tbl_def_events IN OUT NOCOPY t_table_ds_def_events,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30) := 'ADD_DEF_EVENTS';
        --
        l_default_uk          CONSTANT VARCHAR2(10) := '00200';
        l_def_event_mandatory CONSTANT VARCHAR2(1) := 'M';
    BEGIN
        IF i_internal_name IN (g_rs_spec_surgery,
                               g_rs_loc_surgery,
                               g_rs_prev_duration,
                               g_rs_uci,
                               g_rs_pref_surg,
                               g_rs_proc_surg,
                               g_rs_ext_spec,
                               g_rs_cont_danger,
                               g_rs_pref_time,
                               g_rs_mot_pref_time,
                               g_rs_notes,
                               g_rv_request)
        THEN
        
            IF i_has_surgery = pk_alert_constant.g_yes
               OR (i_edt_mode = pk_alert_constant.g_yes AND i_has_surgery = pk_alert_constant.g_yes)
            THEN
            
                IF i_internal_name IN (g_rs_loc_surgery)
                THEN
                    IF i_inst_location IS NULL
                    THEN
                        add_new_def_event(i_pk              => i_ds_cmpt_mkt_rel || l_default_uk || 1,
                                          i_ds_cmpt_mkt_rel => i_ds_cmpt_mkt_rel,
                                          i_flg_event_type  => pk_alert_constant.g_inactive,
                                          io_tbl_def_events => io_tbl_def_events);
                    ELSE
                        add_new_def_event(i_pk              => i_ds_cmpt_mkt_rel || l_default_uk || 1,
                                          i_ds_cmpt_mkt_rel => i_ds_cmpt_mkt_rel,
                                          i_flg_event_type  => l_def_event_mandatory,
                                          io_tbl_def_events => io_tbl_def_events);
                    
                    END IF;
                ELSIF i_internal_name IN (g_rs_pref_surg)
                THEN
                    IF i_spec_surgery IS NULL
                    THEN
                        add_new_def_event(i_pk              => i_ds_cmpt_mkt_rel || l_default_uk || 1,
                                          i_ds_cmpt_mkt_rel => i_ds_cmpt_mkt_rel,
                                          i_flg_event_type  => pk_alert_constant.g_inactive,
                                          io_tbl_def_events => io_tbl_def_events);
                    ELSE
                        add_new_def_event(i_pk              => i_ds_cmpt_mkt_rel || l_default_uk || 1,
                                          i_ds_cmpt_mkt_rel => i_ds_cmpt_mkt_rel,
                                          i_flg_event_type  => pk_dynamic_screen.g_event_active,
                                          io_tbl_def_events => io_tbl_def_events);
                    
                    END IF;
                ELSIF i_internal_name IN (g_rs_proc_surg)
                THEN
                    IF i_spec_surgery IS NULL
                    THEN
                        add_new_def_event(i_pk              => i_ds_cmpt_mkt_rel || l_default_uk || 1,
                                          i_ds_cmpt_mkt_rel => i_ds_cmpt_mkt_rel,
                                          i_flg_event_type  => pk_alert_constant.g_inactive,
                                          io_tbl_def_events => io_tbl_def_events);
                    ELSE
                        add_new_def_event(i_pk              => i_ds_cmpt_mkt_rel || l_default_uk || 1,
                                          i_ds_cmpt_mkt_rel => i_ds_cmpt_mkt_rel,
                                          i_flg_event_type  => l_def_event_mandatory,
                                          io_tbl_def_events => io_tbl_def_events);
                    
                    END IF;
                ELSIF i_internal_name IN (g_rs_prev_duration)
                THEN
                    IF i_spec_surgery IS NULL
                    THEN
                        add_new_def_event(i_pk              => i_ds_cmpt_mkt_rel || l_default_uk || 1,
                                          i_ds_cmpt_mkt_rel => i_ds_cmpt_mkt_rel,
                                          i_flg_event_type  => pk_alert_constant.g_active,
                                          io_tbl_def_events => io_tbl_def_events);
                    ELSE
                        add_new_def_event(i_pk              => i_ds_cmpt_mkt_rel || l_default_uk || 1,
                                          i_ds_cmpt_mkt_rel => i_ds_cmpt_mkt_rel,
                                          i_flg_event_type  => l_def_event_mandatory,
                                          io_tbl_def_events => io_tbl_def_events);
                    END IF;
                ELSIF i_internal_name IN (g_rs_spec_surgery)
                THEN
                    IF i_inst_location IS NULL
                    THEN
                        add_new_def_event(i_pk              => i_ds_cmpt_mkt_rel || l_default_uk || 1,
                                          i_ds_cmpt_mkt_rel => i_ds_cmpt_mkt_rel,
                                          i_flg_event_type  => pk_alert_constant.g_inactive,
                                          io_tbl_def_events => io_tbl_def_events);
                    ELSE
                        add_new_def_event(i_pk              => i_ds_cmpt_mkt_rel || l_default_uk || 1,
                                          i_ds_cmpt_mkt_rel => i_ds_cmpt_mkt_rel,
                                          i_flg_event_type  => l_def_event_mandatory,
                                          io_tbl_def_events => io_tbl_def_events);
                    
                    END IF;
                ELSE
                    add_new_def_event(i_pk              => i_ds_cmpt_mkt_rel || l_default_uk || 1,
                                      i_ds_cmpt_mkt_rel => i_ds_cmpt_mkt_rel,
                                      i_flg_event_type  => pk_alert_constant.g_active,
                                      io_tbl_def_events => io_tbl_def_events);
                END IF;
            END IF;
        END IF;
    
        IF i_internal_name IN
           (g_rsp_lvl_urg, g_rsp_begin_sched, g_rsp_end_sched, g_rsp_time_min, g_rsp_sugg_dt_surg, g_rsp_sugg_dt_int)
           AND i_has_lvl_urg = pk_alert_constant.g_yes
        THEN
            add_new_def_event(i_pk              => i_ds_cmpt_mkt_rel || l_default_uk || 1,
                              i_ds_cmpt_mkt_rel => i_ds_cmpt_mkt_rel,
                              i_flg_event_type  => pk_alert_constant.g_active,
                              io_tbl_def_events => io_tbl_def_events);
        END IF;
    
        IF i_edt_mode = pk_alert_constant.g_yes
        THEN
            IF i_adm_indication IS NOT NULL
            THEN
                IF i_internal_name IN (g_ri_loc_int, g_rs_type_int, g_ri_durantion)
                THEN
                    add_new_def_event(i_pk              => i_ds_cmpt_mkt_rel || l_default_uk || 1,
                                      i_ds_cmpt_mkt_rel => i_ds_cmpt_mkt_rel,
                                      i_flg_event_type  => l_def_event_mandatory,
                                      io_tbl_def_events => io_tbl_def_events);
                ELSIF i_internal_name IN (g_ri_prepar, g_ri_type_room, g_ri_mix_room, g_rs_type_bed, g_ri_pref_room)
                THEN
                    add_new_def_event(i_pk              => i_ds_cmpt_mkt_rel || l_default_uk || 1,
                                      i_ds_cmpt_mkt_rel => i_ds_cmpt_mkt_rel,
                                      i_flg_event_type  => pk_alert_constant.g_active,
                                      io_tbl_def_events => io_tbl_def_events);
                
                END IF;
            END IF;
        
            IF i_inst_location IS NOT NULL
            
            THEN
            
                IF i_internal_name IN (g_ri_serv_adm, g_ri_esp_int)
                THEN
                    add_new_def_event(i_pk              => i_ds_cmpt_mkt_rel || l_default_uk || 1,
                                      i_ds_cmpt_mkt_rel => i_ds_cmpt_mkt_rel,
                                      i_flg_event_type  => l_def_event_mandatory,
                                      io_tbl_def_events => io_tbl_def_events);
                ELSIF i_internal_name IN (g_ri_phys_adm)
                THEN
                    add_new_def_event(i_pk              => i_ds_cmpt_mkt_rel || l_default_uk || 1,
                                      i_ds_cmpt_mkt_rel => i_ds_cmpt_mkt_rel,
                                      i_flg_event_type  => pk_alert_constant.g_active,
                                      io_tbl_def_events => io_tbl_def_events);
                END IF;
            END IF;
        
            IF i_flg_nit = pk_alert_constant.g_yes
               AND i_internal_name IN (g_ri_loc_nurse_cons, g_ri_date_nurse_cons)
            THEN
                add_new_def_event(i_pk              => i_ds_cmpt_mkt_rel || l_default_uk || 1,
                                  i_ds_cmpt_mkt_rel => i_ds_cmpt_mkt_rel,
                                  i_flg_event_type  => pk_alert_constant.g_active,
                                  io_tbl_def_events => io_tbl_def_events);
            
            END IF;
        
        END IF;
    
        IF (i_internal_name LIKE 'RIP_DURATION%' OR i_internal_name LIKE 'RIP_END_PER%')
           AND i_has_unav = pk_alert_constant.g_yes
        THEN
            add_new_def_event(i_pk              => i_ds_cmpt_mkt_rel || l_default_uk || 1,
                              i_ds_cmpt_mkt_rel => i_ds_cmpt_mkt_rel,
                              i_flg_event_type  => pk_alert_constant.g_active,
                              io_tbl_def_events => io_tbl_def_events);
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => 'ALERT',
                                              i_package  => 'PK_ADMISSION_REQUEST',
                                              i_function => l_func_name,
                                              o_error    => o_error);
            RETURN FALSE;
    END add_def_events;

    PROCEDURE remove_section_events
    (
        io_tbl_all_events    IN OUT t_table_ds_events,
        i_tbl_evts_to_remove IN t_table_ds_events
    ) IS
        l_idx              PLS_INTEGER;
        l_tbl_final_events t_table_ds_events;
    BEGIN
        IF i_tbl_evts_to_remove.exists(1)
           AND io_tbl_all_events.exists(1)
        THEN
            --REMOVE EVENTS WHOSE TARGET IS THE TUMOR SECTION
            FOR i IN i_tbl_evts_to_remove.first .. i_tbl_evts_to_remove.last
            LOOP
                l_idx := io_tbl_all_events.first;
                WHILE l_idx IS NOT NULL
                LOOP
                    IF i_tbl_evts_to_remove(i).id_ds_event = io_tbl_all_events(l_idx).id_ds_event
                        AND i_tbl_evts_to_remove(i).target = io_tbl_all_events(l_idx).target
                    THEN
                        io_tbl_all_events.delete(l_idx);
                    END IF;
                
                    l_idx := io_tbl_all_events.next(l_idx);
                END LOOP;
            END LOOP;
        
            --REORGANIZE TABLE ITEMS
            IF io_tbl_all_events.count > 0
            THEN
                l_tbl_final_events := t_table_ds_events();
            
                l_idx := io_tbl_all_events.first;
                WHILE l_idx IS NOT NULL
                LOOP
                    IF io_tbl_all_events(l_idx).id_ds_event IS NOT NULL
                    THEN
                        l_tbl_final_events.extend;
                        l_tbl_final_events(l_tbl_final_events.count) := io_tbl_all_events(l_idx);
                    END IF;
                
                    l_idx := io_tbl_all_events.next(l_idx);
                END LOOP;
            
                io_tbl_all_events := l_tbl_final_events;
            END IF;
        END IF;
    END remove_section_events;

    FUNCTION handle_unav
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_episode           IN episode.id_episode%TYPE,
        i_current_section   IN ds_component.internal_name%TYPE,
        i_unav_num          IN NUMBER DEFAULT 1,
        io_tab_sections     IN OUT t_table_ds_sections,
        io_tab_def_events   IN OUT t_table_ds_def_events,
        io_tab_events       IN OUT t_table_ds_events,
        io_tab_items_values IN OUT t_table_ds_items_values,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    
        TYPE table_map_pk IS TABLE OF PLS_INTEGER INDEX BY PLS_INTEGER;
        l_tbl_map_components_pk   table_map_pk;
        l_tbl_map_cmpt_mkt_rel_pk table_map_pk;
        --
        l_tab_sections   t_table_ds_sections := t_table_ds_sections();
        l_rec_section    t_rec_ds_sections;
        l_rec_def_event  t_rec_ds_def_events;
        l_rec_event      t_rec_ds_events;
        l_rec_item_value t_rec_ds_items_values;
    
        l_keep_parent            ds_cmpt_mkt_rel.id_ds_component_parent%TYPE;
        l_parent_rank            NUMBER;
        l_new_ds_comp_pk         PLS_INTEGER := NULL;
        l_new_ds_cmpt_mkt_rel_pk PLS_INTEGER := NULL;
    
        l_exception EXCEPTION;
    
        l_rec_unav t_rec_ds_unav_sections;
    
        g_default_unav_section_uk CONSTANT VARCHAR2(10) := '90';
    
        FUNCTION get_uk
        (
            i_current_pk IN PLS_INTEGER,
            i_num_unav   IN PLS_INTEGER
        ) RETURN PLS_INTEGER IS
        BEGIN
            RETURN to_number(i_current_pk || g_default_unav_section_uk) + i_num_unav;
        END get_uk;
    
        FUNCTION has_component_id_changed(i_ds_component_pk IN ds_component.id_ds_component%TYPE) RETURN BOOLEAN IS
        BEGIN
            IF i_ds_component_pk IS NULL
            THEN
                RETURN FALSE;
            ELSE
                RETURN(l_tbl_map_components_pk(i_ds_component_pk) IS NOT NULL);
            END IF;
        EXCEPTION
            WHEN no_data_found THEN
                RETURN FALSE;
        END has_component_id_changed;
    
        FUNCTION get_new_ds_cmpt_mkt_rel_pk(i_old_ds_cmpt_mkt_rel_pk IN PLS_INTEGER) RETURN PLS_INTEGER IS
        BEGIN
            RETURN l_tbl_map_cmpt_mkt_rel_pk(i_old_ds_cmpt_mkt_rel_pk);
        EXCEPTION
            WHEN no_data_found THEN
                RETURN i_old_ds_cmpt_mkt_rel_pk;
        END get_new_ds_cmpt_mkt_rel_pk;
    
        FUNCTION get_new_ds_component_pk(i_old_ds_component_pk IN PLS_INTEGER) RETURN PLS_INTEGER IS
        BEGIN
            RETURN l_tbl_map_components_pk(i_old_ds_component_pk);
        EXCEPTION
            WHEN no_data_found THEN
                RETURN i_old_ds_component_pk;
        END get_new_ds_component_pk;
    
        FUNCTION get_other_section_events RETURN t_table_ds_events IS
            l_tbl_unav_section t_table_ds_sections;
            l_ret              t_table_ds_events;
        BEGIN
            l_tbl_unav_section := pk_dynamic_screen.tf_ds_sections(i_lang           => i_lang,
                                                                   i_prof           => i_prof,
                                                                   i_component_name => 'REQUEST_IND_PER');
        
            SELECT t_rec_ds_events(id_ds_event    => de.id_ds_event,
                                   origin         => de.id_ds_cmpt_mkt_rel,
                                   VALUE          => de.value,
                                   target         => det.id_ds_cmpt_mkt_rel,
                                   flg_event_type => det.flg_event_type)
              BULK COLLECT
              INTO l_ret
              FROM ds_event_target det
              JOIN ds_event de
                ON de.id_ds_event = det.id_ds_event
             WHERE det.id_ds_cmpt_mkt_rel IN (SELECT /*+opt_estimate (table t rows=10)*/
                                               t.id_ds_cmpt_mkt_rel
                                                FROM TABLE(l_tbl_unav_section) t)
               AND de.id_ds_cmpt_mkt_rel NOT IN (SELECT /*+opt_estimate (table t rows=10)*/
                                                  t.id_ds_cmpt_mkt_rel
                                                   FROM TABLE(l_tbl_unav_section) t);
        
            RETURN l_ret;
        END get_other_section_events;
    
        --Returns the ds_events whose origin are fields inside the tumor section and target are fields from other sections
        FUNCTION get_evts_to_other_sects RETURN t_table_ds_events IS
            l_tbl_unav_section t_table_ds_sections;
            l_ret              t_table_ds_events;
        BEGIN
            l_tbl_unav_section := pk_dynamic_screen.tf_ds_sections(i_lang           => i_lang,
                                                                   i_prof           => i_prof,
                                                                   i_component_name => 'REQUEST_IND_PER');
        
            SELECT t_rec_ds_events(id_ds_event    => de.id_ds_event,
                                   origin         => de.id_ds_cmpt_mkt_rel,
                                   VALUE          => de.value,
                                   target         => det.id_ds_cmpt_mkt_rel,
                                   flg_event_type => det.flg_event_type)
              BULK COLLECT
              INTO l_ret
              FROM ds_event_target det
              JOIN ds_event de
                ON de.id_ds_event = det.id_ds_event
             WHERE de.id_ds_cmpt_mkt_rel IN (SELECT /*+opt_estimate (table t rows=10)*/
                                              t.id_ds_cmpt_mkt_rel
                                               FROM TABLE(l_tbl_unav_section) t)
               AND det.id_ds_cmpt_mkt_rel NOT IN (SELECT /*+opt_estimate (table t rows=10)*/
                                                   t.id_ds_cmpt_mkt_rel
                                                    FROM TABLE(l_tbl_unav_section) t);
        
            RETURN l_ret;
        END get_evts_to_other_sects;
    
        PROCEDURE add_other_section_events IS
            l_tbl_other_evts t_table_ds_events;
        BEGIN
            l_tbl_other_evts := get_other_section_events;
        
            IF l_tbl_other_evts IS NOT NULL
               AND l_tbl_other_evts.count > 0
            THEN
                IF io_tab_events IS NULL
                THEN
                    io_tab_events := t_table_ds_events();
                END IF;
            
                FOR i IN l_tbl_other_evts.first .. l_tbl_other_evts.last
                LOOP
                    io_tab_events.extend;
                    io_tab_events(io_tab_events.count) := l_tbl_other_evts(i);
                END LOOP;
            END IF;
        END add_other_section_events;
    
        PROCEDURE remove_other_section_events IS
            l_tbl_other_evts t_table_ds_events;
        BEGIN
            l_tbl_other_evts := get_other_section_events;
            remove_section_events(io_tbl_all_events => io_tab_events, i_tbl_evts_to_remove => l_tbl_other_evts);
        END remove_other_section_events;
    
        PROCEDURE remove_evts_to_other_sects IS
            l_tbl_other_evts t_table_ds_events;
        BEGIN
            l_tbl_other_evts := get_evts_to_other_sects;
            remove_section_events(io_tbl_all_events => io_tab_events, i_tbl_evts_to_remove => l_tbl_other_evts);
        END remove_evts_to_other_sects;
    
    BEGIN
    
        IF io_tab_sections.exists(1)
        THEN
        
            FOR i IN io_tab_sections.first .. io_tab_sections.last
            LOOP
            
                l_rec_section := io_tab_sections(i);
            
                l_new_ds_comp_pk := get_uk(i_current_pk => l_rec_section.id_ds_component, i_num_unav => i_unav_num);
            
                l_tbl_map_components_pk(l_rec_section.id_ds_component) := l_new_ds_comp_pk;
                l_rec_section.id_ds_component := l_new_ds_comp_pk;
            
                l_new_ds_cmpt_mkt_rel_pk := get_uk(i_current_pk => l_rec_section.id_ds_cmpt_mkt_rel,
                                                   i_num_unav   => i_unav_num);
                l_tbl_map_cmpt_mkt_rel_pk(l_rec_section.id_ds_cmpt_mkt_rel) := l_new_ds_cmpt_mkt_rel_pk;
                l_rec_section.id_ds_cmpt_mkt_rel := l_new_ds_cmpt_mkt_rel_pk;
            
                l_rec_section.internal_name := l_rec_section.internal_name || '_' || to_char(i_unav_num);
            
                IF l_rec_section.id_ds_component_parent IS NULL
                THEN
                    l_keep_parent                := l_rec_section.id_ds_component;
                    l_rec_section.rank           := l_rec_section.rank + i_unav_num + i;
                    l_parent_rank                := l_rec_section.rank;
                    l_rec_section.component_desc := l_rec_section.component_desc || '(' || i_unav_num || ')';
                ELSE
                    l_rec_section.id_ds_component_parent := l_keep_parent;
                    l_rec_section.rank                   := l_rec_section.rank + (i_unav_num * 10) + i;
                END IF;
            
                l_tab_sections.extend;
                l_tab_sections(l_tab_sections.count) := l_rec_section;
            
            END LOOP;
        END IF;
    
        io_tab_sections := l_tab_sections;
    
        IF io_tab_def_events IS NOT NULL
           AND io_tab_def_events.count > 0
        THEN
            FOR i IN io_tab_def_events.first .. io_tab_def_events.last
            LOOP
                l_rec_def_event := io_tab_def_events(i);
            
                l_rec_def_event.id_ds_cmpt_mkt_rel := get_new_ds_cmpt_mkt_rel_pk(i_old_ds_cmpt_mkt_rel_pk => l_rec_def_event.id_ds_cmpt_mkt_rel);
            
                io_tab_def_events(i) := l_rec_def_event;
            END LOOP;
        END IF;
    
        IF i_current_section = 'REQUEST_IND_PER'
        THEN
            --Add section events whose target is the tumor section
            add_other_section_events;
        ELSE
            --Remove section events whose target is the tumor section
            remove_other_section_events;
        END IF;
    
        IF i_unav_num != 1
        THEN
            --Remove section events whose origin are fields inside the tumor section 
            --and target are fields from other sections
            remove_evts_to_other_sects;
        END IF;
    
        IF io_tab_events IS NOT NULL
           AND io_tab_events.count > 0
        THEN
            FOR i IN io_tab_events.first .. io_tab_events.last
            LOOP
                l_rec_event := io_tab_events(i);
            
                l_rec_event.origin := get_new_ds_cmpt_mkt_rel_pk(i_old_ds_cmpt_mkt_rel_pk => l_rec_event.origin);
                l_rec_event.target := get_new_ds_cmpt_mkt_rel_pk(i_old_ds_cmpt_mkt_rel_pk => l_rec_event.target);
            
                io_tab_events(i) := l_rec_event;
            END LOOP;
        END IF;
    
        IF io_tab_items_values IS NOT NULL
           AND io_tab_items_values.count > 0
        THEN
            FOR i IN io_tab_items_values.first .. io_tab_items_values.last
            LOOP
                l_rec_item_value := io_tab_items_values(i);
            
                l_rec_item_value.id_ds_cmpt_mkt_rel := get_new_ds_cmpt_mkt_rel_pk(i_old_ds_cmpt_mkt_rel_pk => l_rec_item_value.id_ds_cmpt_mkt_rel);
                l_rec_item_value.id_ds_component    := get_new_ds_component_pk(i_old_ds_component_pk => l_rec_item_value.id_ds_component);
            
                io_tab_items_values(i) := l_rec_item_value;
            END LOOP;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN l_exception THEN
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => 'ALERT',
                                              i_package  => 'PK_ADMISSION_REQUEST',
                                              i_function => 'HANDLE_UNAV',
                                              o_error    => o_error);
            RETURN FALSE;
    END handle_unav;

    FUNCTION get_section_events_list
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_episode    IN episode.id_episode%TYPE,
        o_section    OUT pk_types.cursor_type,
        o_def_events OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        c_function_name CONSTANT VARCHAR2(30 CHAR) := 'GET_SECTION_EVENTS_LIST';
        l_dbg_msg      VARCHAR2(100 CHAR);
        l_need_co_sign VARCHAR2(10 CHAR);
    
        l_section    t_table_ds_sections;
        l_def_events t_table_ds_def_events;
    
    BEGIN
    
        IF NOT pk_co_sign.check_prof_needs_cosign(i_lang                 => i_lang,
                                                  i_prof                 => i_prof,
                                                  i_episode              => NULL,
                                                  i_task_type            => 35,
                                                  o_flg_prof_need_cosign => l_need_co_sign,
                                                  o_error                => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        l_dbg_msg := 'get dynamic screen section list';
        pk_alertlog.log_info(text            => l_dbg_msg,
                             object_name     => 'PK_ADMISSION_REQUEST',
                             sub_object_name => c_function_name);
    
        IF NOT pk_dynamic_screen.get_ds_section_events_list(i_lang           => i_lang,
                                                            i_prof           => i_prof,
                                                            i_component_name => 'REQUEST_INP_ADM',
                                                            i_component_type => pk_dynamic_screen.c_root_component,
                                                            o_section        => l_section,
                                                            o_def_events     => l_def_events,
                                                            o_error          => o_error)
        THEN
            pk_types.open_my_cursor(i_cursor => o_section);
            pk_types.open_my_cursor(i_cursor => o_def_events);
            RETURN FALSE;
        END IF;
    
        OPEN o_section FOR
            SELECT *
              FROM TABLE(l_section) t
             WHERE (t.internal_name != 'REQUEST_COSIGN' OR
                   (t.internal_name = 'REQUEST_COSIGN' AND l_need_co_sign = pk_alert_constant.g_yes AND
                   i_episode IS NOT NULL));
    
        OPEN o_def_events FOR
            SELECT *
              FROM TABLE(l_def_events);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => l_dbg_msg,
                                              i_owner    => 'ALERT',
                                              i_package  => 'PK_ADMISSION_REQUEST',
                                              i_function => c_function_name,
                                              o_error    => o_error);
        
            pk_types.open_my_cursor(i_cursor => o_section);
            pk_types.open_my_cursor(i_cursor => o_def_events);
            RETURN FALSE;
        
    END get_section_events_list;

    FUNCTION get_section_data
    (
        i_lang                      IN language.id_language%TYPE,
        i_prof                      IN profissional,
        i_patient                   IN patient.id_patient%TYPE,
        i_episode                   IN episode.id_episode%TYPE,
        i_need_surgery              IN VARCHAR2 DEFAULT 'N',
        i_waiting_list              IN waiting_list.id_waiting_list%TYPE,
        i_component_name            IN ds_cmpt_mkt_rel.internal_name_parent%TYPE,
        i_component_type            IN ds_cmpt_mkt_rel.flg_component_type_parent%TYPE DEFAULT pk_dynamic_screen.c_node_component,
        i_adm_indication            IN adm_indication.id_adm_indication%TYPE,
        i_inst_location             IN institution.id_institution%TYPE,
        i_id_department             IN department.id_department%TYPE,
        i_dep_clin_serv             IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_dep_clin_serv_surg        IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_sch_lvl_urg               IN wtl_urg_level.id_wtl_urg_level%TYPE,
        i_id_surg_proc_princ        IN intervention.id_intervention%TYPE,
        i_unav_val                  IN NUMBER,
        i_unav_begin                IN VARCHAR2,
        i_unav_duration             IN NUMBER,
        i_unav_duration_mea         IN unit_measure.id_unit_measure%TYPE,
        i_unav_end                  IN VARCHAR2,
        i_ask_hosp                  IN VARCHAR2,
        i_order_set                 IN VARCHAR2,
        i_anesth_field              IN VARCHAR2,
        i_anesth_value              IN VARCHAR2,
        i_adm_phy                   IN professional.id_professional%TYPE,
        o_section                   OUT pk_types.cursor_type,
        o_def_events                OUT pk_types.cursor_type,
        o_events                    OUT pk_types.cursor_type,
        o_items_values              OUT pk_types.cursor_type,
        o_data_val                  OUT CLOB,
        o_data_diag                 OUT pk_types.cursor_type,
        o_data_proc                 OUT pk_types.cursor_type,
        o_interv_clinical_questions OUT pk_types.cursor_type,
        o_interv_supplies           OUT pk_types.cursor_type,
        o_error                     OUT t_error_out
    ) RETURN BOOLEAN IS
        c_function_name CONSTANT VARCHAR2(50 CHAR) := 'GET_DR_SECTION_DATA';
        l_dbg_msg VARCHAR(200 CHAR);
    
        l_tbl_sections         t_table_ds_sections;
        l_tbl_sections_aux     t_table_ds_sections;
        l_final_tbl_sections   t_table_ds_sections := t_table_ds_sections();
        r_section              t_rec_ds_sections;
        l_tbl_items_values     t_table_ds_items_values;
        l_tbl_items_values_aux t_table_ds_items_values;
        l_tbl_events           t_table_ds_events;
        l_tbl_events_aux       t_table_ds_events;
        l_tbl_def_events       t_table_ds_def_events;
        l_tbl_def_events_aux   t_table_ds_def_events;
        l_i_need_surgery VARCHAR2(1 CHAR) := CASE
                                                 WHEN i_ask_hosp = pk_alert_constant.g_yes
                                                      AND i_component_name = g_request_surgery THEN
                                                  pk_alert_constant.g_yes
                                                 ELSE
                                                  i_need_surgery
                                             END;
    
        l_section t_table_ds_sections;
    
        g_sysdate_tstz TIMESTAMP WITH LOCAL TIME ZONE := current_timestamp;
    
        l_prof_data  pk_types.cursor_type;
        l_ret        BOOLEAN;
        l_death_date TIMESTAMP WITH LOCAL TIME ZONE;
    
        l_avg_duration      adm_indication.avg_duration%TYPE;
        l_u_lvl_id          wtl_urg_level.id_wtl_urg_level%TYPE;
        l_u_lvl_duration    wtl_urg_level.duration%TYPE;
        l_u_lvl_description pk_translation.t_desc_translation;
        l_dt_begin          VARCHAR2(20 CHAR);
        l_dt_end            VARCHAR2(20 CHAR);
        l_location          institution.id_institution%TYPE;
        l_location_desc     pk_translation.t_desc_translation;
    
        l_ward           department.id_department%TYPE;
        l_ward_desc      pk_translation.t_desc_translation;
        l_dep_clin_serv  dep_clin_serv.id_dep_clin_serv%TYPE;
        l_clin_serv_desc pk_translation.t_desc_translation;
        l_professional   professional.id_professional%TYPE;
        l_prof_desc      pk_translation.t_desc_translation;
        l_adm_type       admission_type.id_admission_type%TYPE;
        l_adm_type_desc  pk_translation.t_desc_translation;
    
        -- ADMISSION_REQUEST_GET_DATA
        l_dt_admission         adm_request.dt_admission%TYPE;
        l_id_dep_clin_serv     NUMBER(24);
        l_desc_dep_clin_serv   VARCHAR2(300 CHAR);
        l_id_prof_spec_adm     NUMBER(24);
        l_desc_prof_spec_adm   VARCHAR(300 CHAR);
        l_id_adm_phys          NUMBER(24);
        l_name_adm_phys        VARCHAR2(300 CHAR);
        l_id_mrp               NUMBER(24);
        l_name_mrp             VARCHAR2(300 CHAR);
        l_id_written_by        NUMBER(24);
        l_name_written_by      VARCHAR2(300 CHAR);
        l_id_adm_indication    NUMBER(24);
        l_desc_adm_indication  VARCHAR2(300 CHAR);
        l_id_admission_type    NUMBER(24);
        l_desc_adm_type        VARCHAR2(300 CHAR);
        l_expected_duration    NUMBER(24);
        l_id_adm_preparation   NUMBER(24);
        l_desc_adm_preparation VARCHAR2(300 CHAR);
        l_id_dest_inst         NUMBER(24);
        l_desc_dest_inst       VARCHAR2(300 CHAR);
        l_id_department        NUMBER(24);
        l_desc_depart          VARCHAR2(300 CHAR);
        l_id_room_type         NUMBER(24);
        l_desc_room_type       VARCHAR2(300 CHAR);
        l_flg_mixed_nursing    VARCHAR2(300 CHAR);
        l_id_bed_type          NUMBER(24);
        l_desc_bed_type        VARCHAR2(300 CHAR);
        l_id_pref_room         NUMBER(24);
        l_dep_pref_room        NUMBER(24);
        l_desc_pref_room       VARCHAR2(300 CHAR);
        l_flg_nit              VARCHAR2(300 CHAR);
        l_flg_nit_desc         VARCHAR2(300 CHAR);
        l_compulsory_desc      VARCHAR2(20 CHAR);
        l_compulsory_id        VARCHAR2(10 CHAR);
        l_compulsory_id_opt    NUMBER(24);
        l_compulsory_desc_opt  VARCHAR2(4000 CHAR);
        l_dt_nit_suggested     VARCHAR2(300 CHAR);
        l_id_nit_dcs           NUMBER(24);
        l_nit_dt_sugg_send     VARCHAR2(300 CHAR);
        l_nit_dt_sugg_char     VARCHAR2(300 CHAR);
        l_nit_location         VARCHAR2(300 CHAR);
        l_nit_inst             NUMBER;
    
        l_notes VARCHAR2(300 CHAR);
    
        l_id_regimen   VARCHAR2(10 CHAR);
        l_desc_regimen VARCHAR2(200 CHAR);
    
        l_id_beneficiario   VARCHAR2(10 CHAR);
        l_desc_beneficiario VARCHAR2(200 CHAR);
    
        l_id_precauciones   VARCHAR2(10 CHAR);
        l_desc_precauciones VARCHAR2(200 CHAR);
    
        l_id_contactado   VARCHAR2(10 CHAR);
        l_desc_contactado VARCHAR2(200 CHAR);
    
        l_diag   VARCHAR2(4000 CHAR);
        l_diag_c pk_types.cursor_type;
    
        -- SURGERY REQUEST GET DATA
        l_surg_date               schedule_sr.dt_target_tstz%TYPE;
        l_surg_spec_id            NUMBER(24);
        l_id                      NUMBER(24);
        l_surg_spec_desc          VARCHAR2(300 CHAR);
        l_surg_speciality         NUMBER(24);
        l_surg_speciality_desc    VARCHAR2(300 CHAR);
        l_surg_department         NUMBER(24);
        l_surg_department_desc    VARCHAR2(300 CHAR);
        l_desc                    VARCHAR2(300 CHAR);
        l_surg_pref_id            table_number := table_number();
        l_surg_pref_desc          table_varchar;
        l_surg_proc               VARCHAR2(300 CHAR);
        l_surg_spec_ext_id        table_number := table_number();
        l_surg_spec_ext_desc      table_varchar;
        l_surg_danger_cont        VARCHAR2(300 CHAR);
        l_surg_pref_time_id       table_number := table_number();
        l_surg_pref_time_desc     table_varchar;
        l_surg_pref_time_flg      table_varchar;
        l_surg_pref_reason_id     NUMBER(24);
        l_surg_pref_reason_desc   VARCHAR2(300 CHAR);
        l_surg_duration           NUMBER(24);
        l_surg_icu                VARCHAR2(10 CHAR);
        l_surg_desc_icu           VARCHAR2(300 CHAR);
        l_surg_icu_pos            VARCHAR2(10 CHAR);
        l_surg_desc_icu_pos       VARCHAR2(300 CHAR);
        l_surg_notes              VARCHAR2(300 CHAR);
        l_surg_need               VARCHAR2(10 CHAR);
        l_surg_need_desc          VARCHAR2(300 CHAR);
        l_surg_institution        NUMBER(24);
        l_surg_institution_desc   VARCHAR2(300 CHAR);
        l_surg_global_anesth_desc VARCHAR2(10 CHAR);
        l_surg_global_anesth_id   VARCHAR2(2 CHAR);
        l_surg_local_anesth_desc  VARCHAR2(10 CHAR);
        l_surg_local_anesth_id    VARCHAR2(2 CHAR);
    
        -- UNAVAILABILITY
    
        l_unav_start     VARCHAR2(100 CHAR);
        l_unav_start_chr VARCHAR2(100 CHAR);
        l_unav_duration  NUMBER(24);
        l_unav_end       VARCHAR2(100 CHAR);
        l_unav_end_chr   VARCHAR2(100 CHAR);
        l_has_unav       VARCHAR2(1 CHAR);
    
        -- SCHEDULING PERIOD
    
        l_sch_dt_start        VARCHAR2(100 CHAR);
        l_sch_dt_start_chr    VARCHAR2(100 CHAR);
        l_sch_lvl_urg         NUMBER(24);
        l_sch_lvl_urg_desc    VARCHAR2(200 CHAR);
        l_sch_duration        NUMBER(24);
        l_sch_dt_end          VARCHAR2(100 CHAR);
        l_sch_dt_end_chr      VARCHAR2(100 CHAR);
        l_sch_min_inform      NUMBER(24);
        l_sch_min_inform_um   NUMBER(24) := g_unit_measure_days;
        l_sch_dt_sug_surg     VARCHAR2(100 CHAR);
        l_sch_dt_sug_surg_chr VARCHAR2(100 CHAR);
        l_sch_dt_sug_int      VARCHAR2(100 CHAR);
        l_sch_dt_sug_int_chr  VARCHAR2(100 CHAR);
    
        -- POS VERIFICATION
        l_id_sr_pos_schedule sr_pos_schedule.id_sr_pos_schedule%TYPE;
        l_pos_dt_sugg        VARCHAR2(100 CHAR);
        l_pos_dt_sugg_chr    VARCHAR2(100 CHAR);
        l_pos_notes          VARCHAR2(4000 CHAR);
        l_pos_sr_stauts      NUMBER(24);
        l_pos_desc_decision  VARCHAR2(100 CHAR);
        l_pos_valid_days     NUMBER(24);
        l_pos_desc_notes     VARCHAR2(4000 CHAR);
        l_pos_need_op        VARCHAR2(10 CHAR);
        l_pos_need_op_desc   VARCHAR2(100 CHAR);
    
        --CO-SIGN
        l_rc_type_desc VARCHAR2(200 CHAR);
        l_rc_type_id   NUMBER(24);
        l_rc_by_desc   VARCHAR2(200 CHAR);
        l_rc_by_id     NUMBER(24);
        l_rc_at_desc   VARCHAR2(200 CHAR);
        l_rc_at_id     NUMBER(24);
    
        l_xml_data xmltype;
    
        l_exception EXCEPTION;
    
        l_epis_type_sr  epis_type.id_epis_type%TYPE := pk_alert_constant.g_epis_type_operating;
        l_epis_type_inp epis_type.id_epis_type%TYPE := pk_alert_constant.g_epis_type_inpatient;
    
        l_id_episode_sr  episode.id_episode%TYPE;
        l_id_episode_inp episode.id_episode%TYPE;
    
        l_count_diag      NUMBER;
        lvl_duration      NUMBER;
        l_unit_measure    unit_measure.id_unit_measure%TYPE;
        l_unit_measure_rs unit_measure.id_unit_measure%TYPE;
    
        lvl_start_date_default VARCHAR2(100 CHAR);
        lvl_end_date_default   VARCHAR2(100 CHAR);
        l_has_lvl_urg          VARCHAR2(1 CHAR);
    
        l_lvl_urg_dur NUMBER(24);
    
        l_unav_duration_umea unit_measure.id_unit_measure%TYPE;
        l_days_diff          NUMBER;
        l_unav_end_tstz      TIMESTAMP WITH LOCAL TIME ZONE;
    
        l_need_surgery VARCHAR2(2 CHAR);
    
        l_id_market market.id_market%TYPE := pk_prof_utils.get_prof_market(i_prof => i_prof);
    
        l_sys_config_hide_doc sys_config.value%TYPE := pk_sysconfig.get_config(i_prof    => i_prof,
                                                                               i_code_cf => 'SURGICAL_EVENT_HIDE_DOC');
    
        l_sys_config_hide_uci sys_config.value%TYPE := pk_sysconfig.get_config(i_prof    => i_prof,
                                                                               i_code_cf => 'SURGICAL_EVENT_HIDE_UCI');
    
        l_phys_adm professional.id_professional%TYPE;
    
        l_flg_compulsory sys_config.value%TYPE := pk_sysconfig.get_config(i_code_cf => 'ADMISSION_ORDER_COMPULSORY_ENABLED',
                                                                          i_prof    => i_prof);
    
        l_sys_config_surg_dt_sugg sys_config.value%TYPE := pk_sysconfig.get_config(i_prof    => i_prof,
                                                                                   i_code_cf => 'REQUEST_SURGERY_DT_SUGGESTED');
    
        PROCEDURE add_data_val
        (
            i_idx_section IN NUMBER,
            i_desc_value  IN VARCHAR2,
            i_value       IN NUMBER DEFAULT NULL,
            i_alt_value   IN VARCHAR2 DEFAULT NULL,
            i_vs_int_name IN VARCHAR2 DEFAULT NULL,
            i_xml_value   IN CLOB DEFAULT NULL
        ) IS
            l_rec_data_val t_rec_ds_items_values;
        BEGIN
            l_rec_data_val := NEW t_rec_ds_items_values(id_ds_cmpt_mkt_rel => l_final_tbl_sections(i_idx_section).id_ds_cmpt_mkt_rel,
                                                        id_ds_component    => NULL,
                                                        internal_name      => i_vs_int_name,
                                                        flg_component_type => NULL,
                                                        item_desc          => i_desc_value,
                                                        item_value         => i_value,
                                                        item_alt_value     => i_alt_value,
                                                        item_xml_value     => i_xml_value,
                                                        item_rank          => NULL);
        
            l_final_tbl_sections(i_idx_section).component_values.extend;
            l_final_tbl_sections(i_idx_section).component_values(l_final_tbl_sections(i_idx_section).component_values.count) := l_rec_data_val;
        END add_data_val;
    
        PROCEDURE add_values
        (
            i_idx_section   IN NUMBER,
            i_internal_name IN ds_component.internal_name%TYPE
        ) IS
        
        BEGIN
        
            CASE
                WHEN i_internal_name = g_ri_reason_admission THEN
                    add_data_val(i_idx_section => i_idx_section,
                                 i_desc_value  => l_desc_adm_indication,
                                 i_value       => l_id_adm_indication);
                WHEN i_internal_name = g_ri_diagnoses THEN
                    add_data_val(i_idx_section => i_idx_section, i_desc_value => l_diag, i_value => NULL);
                WHEN i_internal_name = g_ri_loc_int THEN
                    add_data_val(i_idx_section => i_idx_section,
                                 i_desc_value  => l_desc_dest_inst,
                                 i_value       => l_id_dest_inst);
                WHEN i_internal_name = g_ri_serv_adm THEN
                    add_data_val(i_idx_section => i_idx_section,
                                 i_desc_value  => l_desc_depart,
                                 i_value       => l_id_department);
                WHEN i_internal_name = g_ri_esp_int THEN
                    add_data_val(i_idx_section => i_idx_section,
                                 i_desc_value  => l_desc_dep_clin_serv,
                                 i_value       => l_id_dep_clin_serv);
                WHEN i_internal_name = 'RI_PROF_SPECIALITY' THEN
                    add_data_val(i_idx_section => i_idx_section,
                                 i_desc_value  => l_desc_prof_spec_adm,
                                 i_value       => l_id_prof_spec_adm);
                WHEN i_internal_name = g_ri_phys_adm THEN
                    add_data_val(i_idx_section => i_idx_section,
                                 i_desc_value  => CASE
                                                      WHEN l_id_market = pk_alert_constant.g_id_market_sa THEN
                                                       l_name_mrp
                                                      ELSE
                                                       l_name_adm_phys
                                                  END,
                                 i_value       => CASE
                                                      WHEN l_id_market = pk_alert_constant.g_id_market_sa THEN
                                                       l_id_mrp
                                                      ELSE
                                                       l_id_adm_phys
                                                  END);
                WHEN i_internal_name = g_ri_mrp THEN
                    add_data_val(i_idx_section => i_idx_section,
                                 i_desc_value  => CASE
                                                      WHEN l_id_market = pk_alert_constant.g_id_market_sa THEN
                                                       l_name_adm_phys
                                                      ELSE
                                                       l_name_mrp
                                                  END,
                                 i_value       => CASE
                                                      WHEN l_id_market = pk_alert_constant.g_id_market_sa THEN
                                                       l_id_adm_phys
                                                      ELSE
                                                       l_id_mrp
                                                  END);
                WHEN i_internal_name = g_ri_written_by THEN
                    add_data_val(i_idx_section => i_idx_section,
                                 i_desc_value  => l_name_written_by,
                                 i_value       => l_id_written_by);
                
                WHEN i_internal_name = g_rs_type_int THEN
                    add_data_val(i_idx_section => i_idx_section,
                                 i_desc_value  => l_desc_adm_type,
                                 i_value       => l_id_admission_type);
                WHEN i_internal_name = g_ri_durantion THEN
                
                    IF i_order_set != pk_alert_constant.g_yes
                    THEN
                    
                        add_data_val(i_idx_section => i_idx_section,
                                     i_desc_value  => CASE
                                                          WHEN l_expected_duration IS NULL THEN
                                                           NULL
                                                          ELSE
                                                           l_expected_duration || ' ' ||
                                                           pk_translation.get_translation(i_lang,
                                                                                          'UNIT_MEASURE.CODE_UNIT_MEASURE.' || l_unit_measure)
                                                      END,
                                     i_value       => l_expected_duration,
                                     i_alt_value   => CASE
                                                          WHEN l_expected_duration IS NULL THEN
                                                           NULL
                                                          ELSE
                                                           l_unit_measure
                                                      END);
                    
                    END IF;
                
                WHEN i_internal_name = g_ri_prepar THEN
                    add_data_val(i_idx_section => i_idx_section,
                                 i_desc_value  => l_desc_adm_preparation,
                                 i_value       => l_id_adm_preparation);
                WHEN i_internal_name = g_ri_type_room THEN
                    add_data_val(i_idx_section => i_idx_section,
                                 i_desc_value  => l_desc_room_type,
                                 i_value       => l_id_room_type);
                
                WHEN i_internal_name = g_ri_regimen THEN
                    add_data_val(i_idx_section => i_idx_section,
                                 i_desc_value  => l_desc_regimen,
                                 i_alt_value   => l_id_regimen);
                WHEN i_internal_name = g_ri_beneficiario THEN
                    add_data_val(i_idx_section => i_idx_section,
                                 i_desc_value  => l_desc_beneficiario,
                                 i_alt_value   => l_id_beneficiario);
                WHEN i_internal_name = g_ri_precauciones THEN
                    add_data_val(i_idx_section => i_idx_section,
                                 i_desc_value  => l_desc_precauciones,
                                 i_alt_value   => l_id_precauciones);
                WHEN i_internal_name = g_ri_contactado THEN
                    add_data_val(i_idx_section => i_idx_section,
                                 i_desc_value  => l_desc_contactado,
                                 i_alt_value   => l_id_contactado);
                
                WHEN i_internal_name = g_ri_mix_room THEN
                    add_data_val(i_idx_section => i_idx_section,
                                 i_desc_value  => pk_sysdomain.get_domain(i_lang     => i_lang,
                                                                          i_code_dom => 'ADM_REQUEST.FLG_MIXED_NURSING',
                                                                          i_val      => l_flg_mixed_nursing),
                                 i_alt_value   => l_flg_mixed_nursing);
                WHEN i_internal_name = g_rs_type_bed THEN
                    add_data_val(i_idx_section => i_idx_section,
                                 i_desc_value  => l_desc_bed_type,
                                 i_value       => l_id_bed_type);
                WHEN i_internal_name = g_ri_pref_room THEN
                    add_data_val(i_idx_section => i_idx_section,
                                 i_desc_value  => l_desc_pref_room,
                                 i_value       => l_id_pref_room);
                WHEN i_internal_name = g_ri_need_nurse_cons THEN
                    add_data_val(i_idx_section => i_idx_section,
                                 i_desc_value  => l_flg_nit_desc,
                                 i_alt_value   => l_flg_nit);
                WHEN i_internal_name = 'RI_COMPULSORY' THEN
                    add_data_val(i_idx_section => i_idx_section,
                                 i_desc_value  => l_compulsory_desc,
                                 i_alt_value   => l_compulsory_id);
                WHEN i_internal_name = 'RI_COMPULSORY_REASON' THEN
                    add_data_val(i_idx_section => i_idx_section,
                                 i_desc_value  => l_compulsory_desc_opt,
                                 i_value       => l_compulsory_id_opt);
                WHEN i_internal_name = g_ri_loc_nurse_cons THEN
                    BEGIN
                        IF l_id_nit_dcs IS NOT NULL
                        THEN
                        
                            SELECT d.id_institution
                              INTO l_nit_inst
                              FROM department d
                              JOIN dep_clin_serv dcs
                                ON dcs.id_department = d.id_department
                             WHERE dcs.id_dep_clin_serv = l_id_nit_dcs;
                        END IF;
                    EXCEPTION
                        WHEN OTHERS THEN
                            NULL;
                    END;
                    add_data_val(i_idx_section => i_idx_section, i_desc_value => l_nit_location, i_value => l_nit_inst);
                WHEN i_internal_name = g_ri_date_nurse_cons THEN
                    add_data_val(i_idx_section => i_idx_section,
                                 i_desc_value  => l_nit_dt_sugg_char,
                                 i_value       => l_nit_dt_sugg_send);
                WHEN i_internal_name = g_ri_notes THEN
                    add_data_val(i_idx_section => i_idx_section, i_desc_value => l_notes, i_alt_value => NULL);
                
                WHEN i_internal_name = g_rs_sur_need THEN
                    /*add_data_val(i_idx_section => i_idx_section,
                    i_desc_value  => CASE
                                         WHEN i_need_surgery = 'Y' THEN
                                          pk_sysdomain.get_domain('SCHEDULE_SR.ADM_NEEDED', i_need_surgery, i_lang)
                                         ELSE
                                          pk_sysdomain.get_domain('SCHEDULE_SR.ADM_NEEDED', i_need_surgery, i_lang)
                                     END,
                    i_alt_value   => nvl(i_need_surgery, l_surg_need));*/
                    add_data_val(i_idx_section => i_idx_section,
                                 i_desc_value  => l_surg_need_desc,
                                 i_alt_value   => l_surg_need);
                WHEN i_internal_name = g_rs_loc_surgery THEN
                
                    IF i_order_set != pk_alert_constant.g_yes
                    THEN
                        add_data_val(i_idx_section => i_idx_section,
                                     i_desc_value  => l_surg_institution_desc,
                                     i_value       => l_surg_institution);
                    END IF;
                
                WHEN i_internal_name = g_rs_spec_surgery THEN
                    add_data_val(i_idx_section => i_idx_section,
                                 i_desc_value  => l_surg_speciality_desc,
                                 i_value       => l_surg_speciality);
                
                WHEN i_internal_name = 'RS_CLIN_SERVICE' THEN
                    add_data_val(i_idx_section => i_idx_section,
                                 i_desc_value  => l_surg_spec_desc,
                                 i_value       => l_surg_spec_id);
                WHEN i_internal_name = 'RS_DEPARTMENT' THEN
                    add_data_val(i_idx_section => i_idx_section,
                                 i_desc_value  => l_surg_department_desc,
                                 i_value       => l_surg_department);
                    /*WHEN i_internal_name = 'RS_DEPARTMENT' THEN
                        BEGIN
                            SELECT b.id_department, pk_translation.get_translation(i_lang, b.code_department)
                              INTO l_id, l_desc
                              FROM dep_clin_serv a
                             INNER JOIN department b
                                ON a.id_department = b.id_department
                             WHERE a.id_dep_clin_serv = l_surg_spec_id;
                        
                            add_data_val(i_idx_section => i_idx_section, i_desc_value => l_desc, i_value => l_id);
                        EXCEPTION
                            WHEN OTHERS THEN
                                NULL;
                        END;
                    WHEN i_internal_name = 'RS_CLIN_SERV' THEN
                        BEGIN
                            SELECT b.id_clinical_service, pk_translation.get_translation(i_lang, b.code_clinical_service)
                              INTO l_id, l_desc
                              FROM dep_clin_serv a
                             INNER JOIN clinical_service b
                                ON a.id_clinical_service = b.id_clinical_service
                             WHERE a.id_dep_clin_serv = l_surg_spec_id;
                        
                            add_data_val(i_idx_section => i_idx_section, i_desc_value => l_desc, i_value => l_id);
                        EXCEPTION
                            WHEN OTHERS THEN
                                NULL;
                        END;*/
                WHEN i_internal_name = g_rs_global_anesth THEN
                    add_data_val(i_idx_section => i_idx_section,
                                 i_desc_value  => l_surg_global_anesth_desc,
                                 i_alt_value   => l_surg_global_anesth_id);
                
                WHEN i_internal_name = g_rs_local_anesth THEN
                    add_data_val(i_idx_section => i_idx_section,
                                 i_desc_value  => l_surg_local_anesth_desc,
                                 i_alt_value   => l_surg_local_anesth_id);
                
                WHEN i_internal_name = g_rs_pref_surg THEN
                    FOR i IN 1 .. l_surg_pref_id.count
                    LOOP
                        add_data_val(i_idx_section => i_idx_section,
                                     i_desc_value  => l_surg_pref_desc(i),
                                     i_value       => l_surg_pref_id(i));
                    END LOOP;
                WHEN i_internal_name = g_rs_proc_surg THEN
                    add_data_val(i_idx_section => i_idx_section, i_desc_value => l_surg_proc, i_value => NULL);
                WHEN i_internal_name = g_rs_prev_duration THEN
                
                    add_data_val(i_idx_section => i_idx_section,
                                 i_desc_value  => CASE
                                                      WHEN l_surg_duration IS NULL THEN
                                                       NULL
                                                      ELSE
                                                       l_surg_duration || ' ' ||
                                                       pk_translation.get_translation(i_lang,
                                                                                      'UNIT_MEASURE.CODE_UNIT_MEASURE.' ||
                                                                                      l_unit_measure_rs)
                                                  END,
                                 i_value       => l_surg_duration,
                                 i_alt_value   => CASE
                                                      WHEN l_surg_duration IS NULL THEN
                                                       NULL
                                                      ELSE
                                                       l_unit_measure_rs
                                                  END);
                
                WHEN i_internal_name = g_rs_uci THEN
                    add_data_val(i_idx_section => i_idx_section,
                                 i_desc_value  => l_surg_desc_icu,
                                 i_alt_value   => l_surg_icu);
                WHEN i_internal_name = 'RS_UCI_POS' THEN
                    add_data_val(i_idx_section => i_idx_section,
                                 i_desc_value  => l_surg_desc_icu_pos,
                                 i_alt_value   => l_surg_icu_pos);
                WHEN i_internal_name = g_rs_ext_spec THEN
                    FOR i IN 1 .. l_surg_spec_ext_id.count
                    LOOP
                        add_data_val(i_idx_section => i_idx_section,
                                     i_desc_value  => l_surg_spec_ext_desc(i),
                                     i_value       => l_surg_spec_ext_id(i));
                    END LOOP;
                WHEN i_internal_name = g_rs_cont_danger THEN
                    add_data_val(i_idx_section => i_idx_section, i_desc_value => l_surg_danger_cont, i_value => NULL);
                WHEN i_internal_name = g_rs_pref_time THEN
                
                    FOR i IN 1 .. l_surg_pref_time_id.count
                    LOOP
                        add_data_val(i_idx_section => i_idx_section,
                                     i_desc_value  => l_surg_pref_time_desc(i),
                                     i_value       => get_value_from_time_pref(l_surg_pref_time_flg(i)));
                    END LOOP;
                WHEN i_internal_name = g_rs_mot_pref_time THEN
                    add_data_val(i_idx_section => i_idx_section,
                                 i_desc_value  => l_surg_pref_reason_desc,
                                 i_value       => l_surg_pref_reason_id);
                WHEN i_internal_name = g_rs_notes THEN
                    add_data_val(i_idx_section => i_idx_section, i_desc_value => l_surg_notes, i_value => NULL);
                WHEN i_internal_name LIKE 'RIP_BEGIN_PER%' THEN
                    add_data_val(i_idx_section => i_idx_section,
                                 i_desc_value  => l_unav_start_chr,
                                 i_value       => l_unav_start);
                WHEN i_internal_name LIKE 'RIP_DURATION%' THEN
                    add_data_val(i_idx_section => i_idx_section,
                                 i_desc_value  => CASE
                                                      WHEN l_unav_duration IS NULL THEN
                                                       NULL
                                                      ELSE
                                                       l_unav_duration || ' ' ||
                                                       pk_translation.get_translation(i_lang,
                                                                                      'UNIT_MEASURE.CODE_UNIT_MEASURE.' ||
                                                                                      l_unav_duration_umea)
                                                  END,
                                 i_value       => l_unav_duration,
                                 i_alt_value   => CASE
                                                      WHEN l_unav_duration IS NULL THEN
                                                       NULL
                                                      ELSE
                                                       l_unav_duration_umea
                                                  END);
                WHEN i_internal_name LIKE 'RIP_END_PER%' THEN
                    add_data_val(i_idx_section => i_idx_section, i_desc_value => l_unav_end_chr, i_value => l_unav_end);
                WHEN i_internal_name = g_rsp_lvl_urg THEN
                    add_data_val(i_idx_section => i_idx_section,
                                 i_desc_value  => l_sch_lvl_urg_desc,
                                 i_value       => l_sch_lvl_urg);
                WHEN i_internal_name = g_rsp_begin_sched THEN
                    add_data_val(i_idx_section => i_idx_section,
                                 i_desc_value  => l_sch_dt_start_chr,
                                 i_value       => l_sch_dt_start);
                WHEN i_internal_name = g_rsp_end_sched THEN
                    add_data_val(i_idx_section => i_idx_section,
                                 i_desc_value  => l_sch_dt_end_chr,
                                 i_value       => l_sch_dt_end);
                WHEN i_internal_name = g_rsp_time_min THEN
                    add_data_val(i_idx_section => i_idx_section,
                                 i_desc_value  => CASE
                                                      WHEN l_sch_min_inform IS NULL THEN
                                                       NULL
                                                      ELSE
                                                       l_sch_min_inform || ' ' ||
                                                       pk_translation.get_translation(i_lang,
                                                                                      'UNIT_MEASURE.CODE_UNIT_MEASURE.' ||
                                                                                      l_sch_min_inform_um)
                                                  END,
                                 i_value       => l_sch_min_inform,
                                 i_alt_value   => CASE
                                                      WHEN l_sch_min_inform IS NULL THEN
                                                       NULL
                                                      ELSE
                                                       l_sch_min_inform_um
                                                  END);
                WHEN i_internal_name = g_rsp_sugg_dt_surg THEN
                    add_data_val(i_idx_section => i_idx_section,
                                 i_desc_value  => l_sch_dt_sug_surg_chr,
                                 i_value       => l_sch_dt_sug_surg);
                WHEN i_internal_name = g_rsp_sugg_dt_int THEN
                    add_data_val(i_idx_section => i_idx_section,
                                 i_desc_value  => l_sch_dt_sug_int_chr,
                                 i_value       => l_sch_dt_sug_int);
                
                WHEN i_internal_name = g_rv_request THEN
                    add_data_val(i_idx_section => i_idx_section,
                                 i_desc_value  => l_pos_need_op_desc,
                                 i_alt_value   => l_pos_need_op);
                WHEN i_internal_name = g_rv_dt_verif THEN
                    add_data_val(i_idx_section => i_idx_section,
                                 i_desc_value  => l_pos_dt_sugg_chr,
                                 i_value       => l_pos_dt_sugg);
                WHEN i_internal_name = g_rv_notes_req THEN
                    add_data_val(i_idx_section => i_idx_section, i_desc_value => l_pos_notes, i_value => NULL);
                WHEN i_internal_name = g_rv_decision THEN
                    add_data_val(i_idx_section => i_idx_section,
                                 i_desc_value  => l_pos_desc_decision,
                                 i_value       => l_pos_sr_stauts);
                WHEN i_internal_name = g_rv_valid THEN
                    add_data_val(i_idx_section => i_idx_section,
                                 i_desc_value  => l_pos_valid_days,
                                 i_value       => l_pos_valid_days);
                WHEN i_internal_name = g_rv_notes_decis THEN
                    add_data_val(i_idx_section => i_idx_section, i_desc_value => l_pos_desc_notes, i_value => NULL);
                WHEN i_internal_name = 'RC_TYPE' THEN
                    add_data_val(i_idx_section => i_idx_section,
                                 i_desc_value  => l_rc_type_desc,
                                 i_value       => l_rc_type_id);
                WHEN i_internal_name = 'RC_BY' THEN
                    add_data_val(i_idx_section => i_idx_section, i_desc_value => l_rc_by_desc, i_value => l_rc_by_id);
                WHEN i_internal_name = 'RC_AT' THEN
                    add_data_val(i_idx_section => i_idx_section, i_desc_value => l_rc_at_desc, i_value => l_rc_at_id);
                
                ELSE
                    NULL;
            END CASE;
        
        END add_values;
    
        PROCEDURE add_default_values
        (
            i_idx_section   IN NUMBER,
            i_internal_name IN ds_component.internal_name%TYPE
        ) IS
        
            clob_duration CLOB;
        BEGIN
        
            CASE
                WHEN i_internal_name = g_ri_durantion THEN
                
                    add_data_val(i_idx_section => i_idx_section,
                                 i_desc_value  => CASE
                                                      WHEN l_avg_duration IS NULL THEN
                                                       NULL
                                                      ELSE
                                                       l_avg_duration / 24 || ' ' ||
                                                       pk_translation.get_translation(i_lang,
                                                                                      'UNIT_MEASURE.CODE_UNIT_MEASURE.' ||
                                                                                      g_unit_measure_days)
                                                  END,
                                 i_value       => l_avg_duration / 24,
                                 i_vs_int_name => i_internal_name,
                                 i_alt_value   => g_unit_measure_days);
                WHEN i_internal_name = g_rs_prev_duration THEN
                
                    IF l_surg_duration IS NULL
                       AND i_id_surg_proc_princ IS NOT NULL
                    THEN
                        BEGIN
                            SELECT i.duration / 60
                              INTO l_surg_duration
                              FROM intervention i
                             WHERE i.id_intervention = i_id_surg_proc_princ;
                        
                            l_unit_measure_rs := pk_admission_request.g_unit_measure_hours;
                        EXCEPTION
                            WHEN OTHERS THEN
                                l_surg_duration := NULL;
                            
                        END;
                    
                    END IF;
                
                    add_data_val(i_idx_section => i_idx_section,
                                 i_desc_value  => CASE
                                                      WHEN l_surg_duration IS NULL THEN
                                                       NULL
                                                      ELSE
                                                       l_surg_duration || ' ' ||
                                                       pk_translation.get_translation(i_lang,
                                                                                      'UNIT_MEASURE.CODE_UNIT_MEASURE.' ||
                                                                                      g_unit_measure_hours)
                                                  END,
                                 i_value       => l_surg_duration,
                                 i_vs_int_name => i_internal_name,
                                 i_alt_value   => g_unit_measure_hours);
                
                WHEN i_internal_name = g_rsp_begin_sched THEN
                    IF i_sch_lvl_urg IS NOT NULL
                    THEN
                        SELECT pk_date_utils.date_send(i_lang,
                                                       pk_date_utils.trunc_insttimezone(i_prof, current_timestamp, 'DD'),
                                                       i_prof)
                          INTO lvl_start_date_default
                          FROM dual;
                    
                        add_data_val(i_idx_section => i_idx_section,
                                     i_desc_value  => pk_date_utils.date_chr_short_read_str(i_lang,
                                                                                            lvl_start_date_default,
                                                                                            i_prof.institution,
                                                                                            i_prof.software),
                                     i_value       => to_number(lvl_start_date_default));
                    ELSE
                        add_data_val(i_idx_section => i_idx_section,
                                     i_desc_value  => pk_date_utils.date_chr_short_read_str(i_lang,
                                                                                            lvl_start_date_default,
                                                                                            i_prof.institution,
                                                                                            i_prof.software),
                                     i_value       => to_number(lvl_start_date_default));
                    END IF;
                
                WHEN i_internal_name = g_rsp_end_sched THEN
                    IF i_sch_lvl_urg IS NOT NULL
                    THEN
                    
                        SELECT pk_date_utils.date_send(i_lang,
                                                       (pk_date_utils.trunc_insttimezone(i_prof, current_timestamp, 'DD')) +
                                                       to_number(wul.duration),
                                                       i_prof)
                          INTO lvl_end_date_default
                          FROM wtl_urg_level wul
                         WHERE wul.id_wtl_urg_level = i_sch_lvl_urg;
                    
                        add_data_val(i_idx_section => i_idx_section,
                                     i_desc_value  => pk_date_utils.date_chr_short_read_str(i_lang,
                                                                                            lvl_end_date_default,
                                                                                            i_prof.institution,
                                                                                            i_prof.software),
                                     i_value       => to_number(lvl_end_date_default));
                    
                    ELSE
                        add_data_val(i_idx_section => i_idx_section,
                                     i_desc_value  => pk_date_utils.date_chr_short_read_str(i_lang,
                                                                                            lvl_end_date_default,
                                                                                            i_prof.institution,
                                                                                            i_prof.software),
                                     i_value       => to_number(lvl_end_date_default));
                    END IF;
                
                WHEN i_internal_name = g_rsp_time_min THEN
                
                    add_data_val(i_idx_section => i_idx_section,
                                 i_desc_value  => ' ',
                                 i_value       => NULL,
                                 i_alt_value   => g_unit_measure_days);
                
                    lvl_start_date_default := NULL;
                    lvl_end_date_default   := NULL;
                
                WHEN i_internal_name LIKE 'RIP_DURATION%' THEN
                    IF i_unav_duration IS NULL
                       AND i_unav_end IS NOT NULL
                    THEN
                    
                        SELECT ((round(pk_date_utils.get_timestamp_diff(pk_date_utils.get_string_tstz(i_lang,
                                                                                                      i_prof,
                                                                                                      i_unav_end,
                                                                                                      NULL),
                                                                        pk_date_utils.get_string_tstz(i_lang,
                                                                                                      i_prof,
                                                                                                      i_unav_begin,
                                                                                                      NULL))) * 24 * 60) +
                               24 * 60)
                          INTO l_days_diff
                          FROM dual;
                    
                        IF NOT get_duration_unit_measure_ds(i_lang         => i_lang,
                                                            i_prof         => i_prof,
                                                            i_hours        => l_days_diff,
                                                            i_date         => NULL,
                                                            o_value        => l_days_diff,
                                                            o_unit_measure => l_unav_duration_umea,
                                                            o_error        => o_error)
                        THEN
                            RAISE l_exception;
                        END IF;
                    
                        add_data_val(i_idx_section => i_idx_section,
                                     
                                     i_desc_value => l_days_diff || ' ' ||
                                                     pk_translation.get_translation(i_lang,
                                                                                    'UNIT_MEASURE.CODE_UNIT_MEASURE.' ||
                                                                                    l_unav_duration_umea),
                                     
                                     i_value       => l_days_diff,
                                     i_alt_value   => l_unav_duration_umea,
                                     i_vs_int_name => i_internal_name);
                    
                    END IF;
                
                    IF i_unav_duration IS NULL
                       AND i_unav_end IS NULL
                    THEN
                        add_data_val(i_idx_section => i_idx_section,
                                     
                                     i_desc_value => NULL,
                                     
                                     i_value       => NULL,
                                     i_alt_value   => g_unit_measure_days,
                                     i_vs_int_name => i_internal_name);
                    
                    END IF;
                
                WHEN i_internal_name LIKE 'RIP_END_PER%' THEN
                    IF i_unav_duration IS NOT NULL
                       AND i_unav_duration > 0
                       AND i_unav_end IS NULL
                    THEN
                    
                        CASE i_unav_duration_mea
                            WHEN 10373 THEN
                                l_days_diff := i_unav_duration * 365;
                            WHEN 1127 THEN
                                l_days_diff := i_unav_duration * 30;
                            WHEN 10375 THEN
                                l_days_diff := i_unav_duration * 7;
                            ELSE
                                l_days_diff := i_unav_duration;
                        END CASE;
                    
                        l_unav_end_tstz := pk_date_utils.add_days_to_tstz(i_timestamp => pk_date_utils.get_string_tstz(i_lang,
                                                                                                                       i_prof,
                                                                                                                       i_unav_begin,
                                                                                                                       NULL),
                                                                          i_days      => (l_days_diff - 1));
                    
                        lvl_start_date_default := pk_date_utils.date_send(i_lang, l_unav_end_tstz, i_prof);
                    
                        add_data_val(i_idx_section => i_idx_section,
                                     i_desc_value  => pk_date_utils.date_chr_short_read_str(i_lang,
                                                                                            lvl_start_date_default,
                                                                                            i_prof.institution,
                                                                                            i_prof.software),
                                     i_value       => to_number(lvl_start_date_default));
                    END IF;
                
                    IF (i_unav_duration = 0 OR i_unav_duration IS NULL)
                       AND i_unav_end IS NULL
                    THEN
                        add_data_val(i_idx_section => i_idx_section,
                                     i_desc_value  => ' ',
                                     i_value       => NULL,
                                     i_vs_int_name => i_internal_name);
                    
                    END IF;
                ELSE
                    NULL;
            END CASE;
            NULL;
        
        END add_default_values;
    
        PROCEDURE add_new_item
        (
            i_ds_cmpt_mkt_rel    IN ds_cmpt_mkt_rel.id_ds_cmpt_mkt_rel%TYPE,
            i_ds_component       IN ds_component.id_ds_component%TYPE,
            i_internal_name      IN ds_component.internal_name%TYPE,
            i_flg_component_type IN ds_component.flg_component_type%TYPE,
            i_item_desc          IN pk_translation.t_desc_translation,
            i_item_value         IN sys_list.id_sys_list%TYPE,
            i_item_alt_value     IN sys_list_group_rel.flg_context%TYPE,
            i_item_xml_value     IN CLOB DEFAULT NULL,
            i_item_rank          IN sys_list_group_rel.rank%TYPE,
            io_tbl_items_values  IN OUT NOCOPY t_table_ds_items_values
        ) IS
            l_inner_proc_name CONSTANT VARCHAR2(30) := 'ADD_NEW_ITEM';
            --
            r_item_value t_rec_ds_items_values;
        BEGIN
            g_error      := 'NEW T_REC_DS_ITEMS_VALUES INSTANCE';
            r_item_value := t_rec_ds_items_values(id_ds_cmpt_mkt_rel => i_ds_cmpt_mkt_rel,
                                                  id_ds_component    => i_ds_component,
                                                  internal_name      => i_internal_name,
                                                  flg_component_type => i_flg_component_type,
                                                  item_desc          => i_item_desc,
                                                  item_value         => i_item_value,
                                                  item_alt_value     => i_item_alt_value,
                                                  item_xml_value     => i_item_xml_value,
                                                  item_rank          => i_item_rank);
        
            g_error := 'ADD TO TABLE L_TBL_ITEMS_VALUES';
            io_tbl_items_values.extend;
            io_tbl_items_values(io_tbl_items_values.count) := r_item_value;
        END add_new_item;
    
        PROCEDURE add_sample_text
        (
            i_intern_name_sample_text_type IN sample_text_type.intern_name_sample_text_type%TYPE,
            io_section                     IN OUT t_rec_ds_sections
        ) IS
            l_inner_proc_name CONSTANT VARCHAR2(30) := 'ADD_SAMPLE_TEXT';
        BEGIN
            g_error := 'ADD SAMPLE TEXT ADDITIONAL_INFO TO SECTION: ' || io_section.internal_name;
        
            SELECT xmlelement("ADDITIONAL_INFO", xmlattributes(t.intern_name_sample_text_type)).getclobval()
              INTO io_section.addit_info_xml_value
              FROM (SELECT i_intern_name_sample_text_type intern_name_sample_text_type
                      FROM dual) t;
        END add_sample_text;
    
        PROCEDURE add_inst_location
        (
            i_ds_cmpt_mkt_rel    IN ds_cmpt_mkt_rel.id_ds_cmpt_mkt_rel%TYPE,
            i_ds_component       IN ds_component.id_ds_component%TYPE,
            i_internal_name      IN ds_component.internal_name%TYPE,
            i_flg_component_type IN ds_component.flg_component_type%TYPE
        ) IS
            l_inner_proc_name CONSTANT VARCHAR2(30) := 'ADD_INST_LOCATION';
            --
            c_list pk_types.cursor_type;
        
            c_origin pk_list.cursor_origin;
            r_origin pk_list.rec_origin;
        
            l_inst_desc   VARCHAR2(300 CHAR);
            l_id_inst     NUMBER;
            l_flg_default VARCHAR2(2 CHAR);
        
            l_addict_info CLOB;
        BEGIN
            g_error := 'CALL PK_LIST.GET_ORIGIN_LIST';
            IF NOT pk_admission_request.get_location_list(i_lang           => i_lang,
                                                          i_prof           => i_prof,
                                                          i_adm_indication => nvl(i_adm_indication, l_id_adm_indication),
                                                          o_list           => c_list,
                                                          o_error          => o_error)
            THEN
                RAISE l_exception;
            END IF;
        
            g_error := 'ADD ALL INST LOCATIONS';
            LOOP
                FETCH c_list
                    INTO l_id_inst, l_flg_default, l_inst_desc;
                EXIT WHEN c_list%NOTFOUND;
            
                SELECT xmlelement("ADDITIONAL_INFO", xmlattributes(decode(i_adm_indication, g_reason_admission_ft,(decode(l_id_inst, i_prof.institution, pk_alert_constant.g_yes, pk_alert_constant.g_no)), decode(l_id_inst, i_prof.institution /*i_inst_location*/, pk_alert_constant.g_yes, pk_alert_constant.g_no)) AS flg_default)).getclobval() addit_info
                  INTO l_addict_info
                  FROM dual;
            
                IF l_flg_default = pk_alert_constant.g_yes
                THEN
                    l_id_dest_inst := l_id_inst;
                END IF;
            
                add_new_item(i_ds_cmpt_mkt_rel    => i_ds_cmpt_mkt_rel,
                             i_ds_component       => i_ds_component,
                             i_internal_name      => i_internal_name,
                             i_flg_component_type => i_flg_component_type,
                             i_item_desc          => l_inst_desc,
                             i_item_value         => l_id_inst,
                             i_item_alt_value     => NULL,
                             i_item_xml_value     => l_addict_info,
                             i_item_rank          => NULL,
                             io_tbl_items_values  => l_tbl_items_values);
            END LOOP;
        
            CLOSE c_list;
        END add_inst_location;
    
        PROCEDURE add_inst_location_surg
        (
            i_ds_cmpt_mkt_rel    IN ds_cmpt_mkt_rel.id_ds_cmpt_mkt_rel%TYPE,
            i_ds_component       IN ds_component.id_ds_component%TYPE,
            i_internal_name      IN ds_component.internal_name%TYPE,
            i_flg_component_type IN ds_component.flg_component_type%TYPE
        ) IS
            l_inner_proc_name CONSTANT VARCHAR2(30) := 'ADD_INST_LOCATION';
            --
            c_list pk_types.cursor_type;
        
            c_origin pk_list.cursor_origin;
            r_origin pk_list.rec_origin;
        
            l_inst_desc   VARCHAR2(300 CHAR);
            l_id_inst     NUMBER;
            l_flg_default VARCHAR2(100 CHAR);
        
            l_addict_info CLOB;
        BEGIN
        
            IF l_i_need_surgery = pk_alert_constant.g_yes
               OR l_need_surgery = pk_alert_constant.g_yes
            THEN
                g_error := 'CALL PK_LIST.GET_ORIGIN_LIST';
                IF NOT
                    pk_admission_request.get_location_list(i_lang           => i_lang,
                                                           i_prof           => i_prof,
                                                           i_adm_indication => nvl(i_adm_indication, l_id_adm_indication),
                                                           o_list           => c_list,
                                                           o_error          => o_error)
                THEN
                    RAISE l_exception;
                END IF;
            
                g_error := 'ADD ALL INST LOCATIONS';
                LOOP
                    FETCH c_list
                        INTO l_id_inst, l_flg_default, l_inst_desc;
                    EXIT WHEN c_list%NOTFOUND;
                
                    SELECT xmlelement("ADDITIONAL_INFO", xmlattributes(decode(i_adm_indication, g_reason_admission_ft,(decode(l_id_inst, i_prof.institution, pk_alert_constant.g_yes, pk_alert_constant.g_no)), decode(l_id_inst, i_inst_location, pk_alert_constant.g_yes, l_flg_default)) AS flg_default)).getclobval() addit_info
                      INTO l_addict_info
                      FROM dual;
                
                    IF l_id_inst = nvl(i_inst_location, l_id_dest_inst)
                       OR i_adm_indication = g_reason_admission_ft
                       OR l_flg_default = pk_alert_constant.g_yes
                    THEN
                    
                        add_new_item(i_ds_cmpt_mkt_rel    => i_ds_cmpt_mkt_rel,
                                     i_ds_component       => i_ds_component,
                                     i_internal_name      => i_internal_name,
                                     i_flg_component_type => i_flg_component_type,
                                     i_item_desc          => l_inst_desc,
                                     i_item_value         => l_id_inst,
                                     i_item_alt_value     => NULL,
                                     i_item_xml_value     => l_addict_info,
                                     i_item_rank          => NULL,
                                     io_tbl_items_values  => l_tbl_items_values);
                    END IF;
                END LOOP;
            
                CLOSE c_list;
            
            END IF;
        END add_inst_location_surg;
    
        PROCEDURE add_inst_dep
        (
            i_ds_cmpt_mkt_rel    IN ds_cmpt_mkt_rel.id_ds_cmpt_mkt_rel%TYPE,
            i_ds_component       IN ds_component.id_ds_component%TYPE,
            i_internal_name      IN ds_component.internal_name%TYPE,
            i_flg_component_type IN ds_component.flg_component_type%TYPE
        ) IS
            l_inner_proc_name CONSTANT VARCHAR2(30) := 'ADD_INST_DEP';
            --
            c_list pk_types.cursor_type;
        
            c_origin pk_list.cursor_origin;
            r_origin pk_list.rec_origin;
        
            l_inst_desc   VARCHAR2(300 CHAR);
            l_id_inst     NUMBER;
            l_flg_default VARCHAR2(2 CHAR);
        
            l_addit_info CLOB;
        BEGIN
        
            IF NOT pk_admission_request.get_ward_list_ds(i_lang           => i_lang,
                                                         i_prof           => i_prof,
                                                         i_adm_indication => nvl(i_adm_indication, l_id_adm_indication),
                                                         i_location       => nvl(i_inst_location, l_id_dest_inst),
                                                         i_ward           => l_ward,
                                                         o_list           => c_list,
                                                         o_error          => o_error)
            THEN
                RAISE l_exception;
            END IF;
        
            g_error := 'ADD ALL INST LOCATIONS';
            LOOP
                FETCH c_list
                    INTO l_id_inst, l_inst_desc, l_flg_default, l_addit_info;
                EXIT WHEN c_list%NOTFOUND;
            
                IF l_flg_default = pk_alert_constant.g_yes
                THEN
                    l_ward := l_id_inst;
                END IF;
            
                add_new_item(i_ds_cmpt_mkt_rel    => i_ds_cmpt_mkt_rel,
                             i_ds_component       => i_ds_component,
                             i_internal_name      => i_internal_name,
                             i_flg_component_type => i_flg_component_type,
                             i_item_desc          => l_inst_desc,
                             i_item_value         => l_id_inst,
                             i_item_alt_value     => NULL,
                             i_item_rank          => NULL,
                             i_item_xml_value     => l_addit_info,
                             io_tbl_items_values  => l_tbl_items_values);
            END LOOP;
        
            CLOSE c_list;
        END add_inst_dep;
    
        PROCEDURE add_dep_clin_serv
        (
            i_ds_cmpt_mkt_rel    IN ds_cmpt_mkt_rel.id_ds_cmpt_mkt_rel%TYPE,
            i_ds_component       IN ds_component.id_ds_component%TYPE,
            i_internal_name      IN ds_component.internal_name%TYPE,
            i_flg_component_type IN ds_component.flg_component_type%TYPE
        ) IS
            l_inner_proc_name CONSTANT VARCHAR2(30) := 'ADD_DEP_CLIN_SERV';
            --
            c_list pk_types.cursor_type;
        
            c_origin pk_list.cursor_origin;
            r_origin pk_list.rec_origin;
        
            l_inst_desc   VARCHAR2(300 CHAR);
            l_id_inst     NUMBER;
            l_flg_default VARCHAR2(2 CHAR);
            l_addict_info CLOB;
        
            l_count PLS_INTEGER := 0;
        BEGIN
        
            IF NOT pk_admission_request.get_dep_clin_serv_list_ds(i_lang           => i_lang,
                                                                  i_prof           => i_prof,
                                                                  i_adm_indication => nvl(i_adm_indication,
                                                                                          l_id_adm_indication),
                                                                  i_ward           => nvl(nvl(i_id_department, l_ward),
                                                                                          l_id_department),
                                                                  i_dep_clin_serv  => l_dep_clin_serv,
                                                                  o_list           => c_list,
                                                                  o_error          => o_error)
            THEN
                RAISE l_exception;
            END IF;
        
            g_error := 'ADD ALL INST LOCATIONS';
            LOOP
                FETCH c_list
                    INTO l_id_inst, l_inst_desc, l_flg_default, l_addict_info;
                EXIT WHEN c_list%NOTFOUND;
            
                IF l_flg_default = pk_alert_constant.g_yes
                THEN
                    l_id_dep_clin_serv := l_id_inst;
                END IF;
            
                add_new_item(i_ds_cmpt_mkt_rel    => i_ds_cmpt_mkt_rel,
                             i_ds_component       => i_ds_component,
                             i_internal_name      => i_internal_name,
                             i_flg_component_type => i_flg_component_type,
                             i_item_desc          => l_inst_desc,
                             i_item_value         => l_id_inst,
                             i_item_alt_value     => NULL,
                             i_item_rank          => NULL,
                             i_item_xml_value     => l_addict_info,
                             io_tbl_items_values  => l_tbl_items_values);
            
                l_count := l_count + 1;
            END LOOP;
        
            --This element is mandatory, therefore it is necessary to assure that, even when there is no configured content,it is activated
            IF l_count = 0
            THEN
                add_new_item(i_ds_cmpt_mkt_rel    => i_ds_cmpt_mkt_rel,
                             i_ds_component       => i_ds_component,
                             i_internal_name      => i_internal_name,
                             i_flg_component_type => i_flg_component_type,
                             i_item_desc          => NULL,
                             i_item_value         => NULL,
                             i_item_alt_value     => NULL,
                             i_item_rank          => NULL,
                             i_item_xml_value     => NULL,
                             io_tbl_items_values  => l_tbl_items_values);
            END IF;
            CLOSE c_list;
        END add_dep_clin_serv;
    
        PROCEDURE add_phys_adm
        (
            i_ds_cmpt_mkt_rel    IN ds_cmpt_mkt_rel.id_ds_cmpt_mkt_rel%TYPE,
            i_ds_component       IN ds_component.id_ds_component%TYPE,
            i_internal_name      IN ds_component.internal_name%TYPE,
            i_flg_component_type IN ds_component.flg_component_type%TYPE
        ) IS
            l_inner_proc_name CONSTANT VARCHAR2(30) := 'ADD_PHYS_ADM';
            --
            c_list pk_types.cursor_type;
        
            c_origin pk_list.cursor_origin;
            r_origin pk_list.rec_origin;
        
            l_inst_desc   VARCHAR2(300 CHAR);
            l_id_inst     NUMBER;
            l_flg_default VARCHAR2(2 CHAR);
            l_addict_info CLOB;
            l_id_market   market.id_market%TYPE;
        BEGIN
        
            l_id_market := pk_prof_utils.get_prof_market(i_prof => i_prof);
        
            IF i_internal_name = g_ri_written_by
            THEN
            
                SELECT i_prof.id,
                       pk_prof_utils.get_name(i_lang => 2, i_prof_id => i_prof.id),
                       xmlelement("ADDITIONAL_INFO", xmlattributes(pk_alert_constant.g_yes AS flg_default)).getclobval()
                  INTO l_id_inst, l_inst_desc, l_addict_info
                  FROM dual;
            
                add_new_item(i_ds_cmpt_mkt_rel    => i_ds_cmpt_mkt_rel,
                             i_ds_component       => i_ds_component,
                             i_internal_name      => i_internal_name,
                             i_flg_component_type => i_flg_component_type,
                             i_item_desc          => l_inst_desc,
                             i_item_value         => l_id_inst,
                             i_item_alt_value     => NULL,
                             i_item_rank          => NULL,
                             i_item_xml_value     => l_addict_info,
                             io_tbl_items_values  => l_tbl_items_values);
            
            ELSE
                IF i_adm_indication IS NOT NULL
                   AND nvl(i_inst_location, l_id_dest_inst) IS NOT NULL
                   AND i_id_department IS NOT NULL
                   OR i_waiting_list IS NOT NULL
                THEN
                    /*IF l_id_market != pk_alert_constant.g_id_market_cl
                    THEN
                    
                        OPEN c_list FOR
                            SELECT z.id,
                                   z.name,
                                   z.flg_default,
                                   xmlelement("ADDITIONAL_INFO", xmlattributes(z.flg_default)).getclobval() addit_info
                              FROM (SELECT DISTINCT prf.id_professional id,
                                                    pk_prof_utils.get_name_signature(i_lang, i_prof, prf.id_professional) name,
                                                    decode(pi.id_professional,
                                                           i_prof.id,
                                                           pk_alert_constant.g_yes,
                                                           pk_alert_constant.g_no) flg_default
                                      FROM prof_institution pi
                                     INNER JOIN prof_cat prc
                                        ON (prc.id_professional = pi.id_professional)
                                     INNER JOIN category cat
                                        ON (cat.id_category = prc.id_category)
                                     INNER JOIN professional prf
                                        ON (prf.id_professional = pi.id_professional)
                                     INNER JOIN prof_profile_template ppt
                                        ON prc.id_institution = ppt.id_institution
                                       AND prc.id_professional = ppt.id_professional
                                      JOIN profile_template pt
                                        ON ppt.id_profile_template = pt.id_profile_template
                                     WHERE cat.flg_type = 'D'
                                       AND prf.flg_state = 'A'
                                       AND pi.id_institution = i_prof.institution
                                       AND pi.flg_state = pk_alert_constant.g_active
                                       AND pi.dt_end_tstz IS NULL
                                       AND prc.id_institution = i_prof.institution
                                       AND pi.flg_external = pk_alert_constant.g_no
                                       AND ppt.id_software = i_prof.software
                                       AND (pk_prof_utils.get_prof_sub_category(i_lang,
                                                                                profissional(prf.id_professional,
                                                                                             i_prof.institution,
                                                                                             i_prof.software)) IS NULL OR
                                           pk_prof_utils.get_prof_sub_category(i_lang,
                                                                                profissional(prf.id_professional,
                                                                                             i_prof.institution,
                                                                                             i_prof.software)) !=
                                           pk_alert_constant.g_na)
                                       AND nvl(prf.flg_prof_test, pk_alert_constant.g_no) = pk_alert_constant.g_no
                                       AND pt.flg_profile = 'S'
                                     ORDER BY name) z;
                    
                    ELSE*/
                    IF NOT
                        pk_admission_request.get_physicians_list_ds(i_lang          => i_lang,
                                                                    i_prof          => i_prof,
                                                                    i_dep_clin_serv => nvl(i_dep_clin_serv,
                                                                                           l_id_dep_clin_serv),
                                                                    i_professional  => l_professional,
                                                                    i_id_inst_dest  => nvl(i_inst_location, l_id_dest_inst),
                                                                    o_list          => c_list,
                                                                    o_error         => o_error)
                    THEN
                        RAISE l_exception;
                    END IF;
                    /*END IF;*/
                
                    g_error := 'ADD ALL INST LOCATIONS';
                    LOOP
                        FETCH c_list
                            INTO l_id_inst, l_inst_desc, l_flg_default, l_addict_info;
                        EXIT WHEN c_list%NOTFOUND;
                    
                        IF l_flg_default = pk_alert_constant.g_yes
                        THEN
                            l_phys_adm := l_id_inst;
                        END IF;
                    
                        add_new_item(i_ds_cmpt_mkt_rel    => i_ds_cmpt_mkt_rel,
                                     i_ds_component       => i_ds_component,
                                     i_internal_name      => i_internal_name,
                                     i_flg_component_type => i_flg_component_type,
                                     i_item_desc          => l_inst_desc,
                                     i_item_value         => l_id_inst,
                                     i_item_alt_value     => NULL,
                                     i_item_rank          => NULL,
                                     i_item_xml_value     => l_addict_info,
                                     io_tbl_items_values  => l_tbl_items_values);
                    END LOOP;
                
                    CLOSE c_list;
                
                END IF;
            END IF;
        END add_phys_adm;
    
        PROCEDURE add_mrp
        (
            i_ds_cmpt_mkt_rel    IN ds_cmpt_mkt_rel.id_ds_cmpt_mkt_rel%TYPE,
            i_ds_component       IN ds_component.id_ds_component%TYPE,
            i_internal_name      IN ds_component.internal_name%TYPE,
            i_flg_component_type IN ds_component.flg_component_type%TYPE
        ) IS
            l_inner_proc_name CONSTANT VARCHAR2(30) := 'ADD_MRP';
            --
            c_list pk_types.cursor_type;
        
            c_origin pk_list.cursor_origin;
            r_origin pk_list.rec_origin;
        
            l_inst_desc   VARCHAR2(300 CHAR);
            l_id_inst     NUMBER;
            l_addict_info CLOB;
        BEGIN
            IF i_adm_indication IS NOT NULL
               AND nvl(i_inst_location, l_id_dest_inst) IS NOT NULL
               AND i_id_department IS NOT NULL
               OR i_waiting_list IS NOT NULL
            THEN
                IF NOT pk_admission_request.get_mrp_list_ds(i_lang          => i_lang,
                                                            i_prof          => i_prof,
                                                            i_dep_clin_serv => nvl(i_dep_clin_serv, l_id_dep_clin_serv),
                                                            o_list          => c_list,
                                                            o_error         => o_error)
                THEN
                    RAISE l_exception;
                END IF;
            
                g_error := 'ADD ALL INST LOCATIONS';
                LOOP
                    FETCH c_list
                        INTO l_id_inst, l_inst_desc, l_addict_info;
                    EXIT WHEN c_list%NOTFOUND;
                
                    IF nvl(l_phys_adm, i_adm_phy) IS NOT NULL
                    THEN
                        IF nvl(i_adm_phy, l_phys_adm) = l_id_inst
                        THEN
                            SELECT xmlelement("ADDITIONAL_INFO", xmlattributes(pk_alert_constant.g_yes AS flg_default)).getclobval() addit_info
                              INTO l_addict_info
                              FROM dual;
                        END IF;
                    END IF;
                
                    add_new_item(i_ds_cmpt_mkt_rel    => i_ds_cmpt_mkt_rel,
                                 i_ds_component       => i_ds_component,
                                 i_internal_name      => i_internal_name,
                                 i_flg_component_type => i_flg_component_type,
                                 i_item_desc          => l_inst_desc,
                                 i_item_value         => l_id_inst,
                                 i_item_alt_value     => NULL,
                                 i_item_rank          => NULL,
                                 i_item_xml_value     => l_addict_info,
                                 io_tbl_items_values  => l_tbl_items_values);
                END LOOP;
            
                CLOSE c_list;
            END IF;
        END add_mrp;
    
        PROCEDURE add_type_int
        (
            i_ds_cmpt_mkt_rel    IN ds_cmpt_mkt_rel.id_ds_cmpt_mkt_rel%TYPE,
            i_ds_component       IN ds_component.id_ds_component%TYPE,
            i_internal_name      IN ds_component.internal_name%TYPE,
            i_flg_component_type IN ds_component.flg_component_type%TYPE
        ) IS
            l_inner_proc_name CONSTANT VARCHAR2(30) := 'ADD_TYPE_INT';
            --
            c_list pk_types.cursor_type;
        
            c_origin pk_list.cursor_origin;
            r_origin pk_list.rec_origin;
        
            l_inst_desc   VARCHAR2(300 CHAR);
            l_id_inst     NUMBER;
            l_third       NUMBER;
            l_addict_info CLOB;
        BEGIN
        
            IF NOT pk_admission_request.get_admission_type_list_ds(i_lang     => i_lang,
                                                                   i_prof     => i_prof,
                                                                   i_location => nvl(i_inst_location, l_id_dest_inst),
                                                                   i_adm_type => l_adm_type,
                                                                   o_list     => c_list,
                                                                   o_error    => o_error)
            THEN
                RAISE l_exception;
            END IF;
        
            g_error := 'ADD ALL INST LOCATIONS';
            LOOP
                FETCH c_list
                    INTO l_id_inst, l_inst_desc, l_third, l_addict_info;
                EXIT WHEN c_list%NOTFOUND;
            
                add_new_item(i_ds_cmpt_mkt_rel    => i_ds_cmpt_mkt_rel,
                             i_ds_component       => i_ds_component,
                             i_internal_name      => i_internal_name,
                             i_flg_component_type => i_flg_component_type,
                             i_item_desc          => l_inst_desc,
                             i_item_value         => l_id_inst,
                             i_item_alt_value     => NULL,
                             i_item_rank          => NULL,
                             i_item_xml_value     => l_addict_info,
                             io_tbl_items_values  => l_tbl_items_values);
            END LOOP;
        
            CLOSE c_list;
        END add_type_int;
    
        PROCEDURE add_preparation
        (
            i_ds_cmpt_mkt_rel    IN ds_cmpt_mkt_rel.id_ds_cmpt_mkt_rel%TYPE,
            i_ds_component       IN ds_component.id_ds_component%TYPE,
            i_internal_name      IN ds_component.internal_name%TYPE,
            i_flg_component_type IN ds_component.flg_component_type%TYPE
        ) IS
            l_inner_proc_name CONSTANT VARCHAR2(30) := 'ADD_PREPARATION';
            --
            c_list pk_types.cursor_type;
        
            c_origin pk_list.cursor_origin;
            r_origin pk_list.rec_origin;
        
            l_inst_desc   VARCHAR2(300 CHAR);
            l_id_inst     NUMBER;
            l_addict_info CLOB;
        BEGIN
        
            IF NOT pk_admission_request.get_adm_preparation_list(i_lang     => i_lang,
                                                                 i_prof     => i_prof,
                                                                 i_location => nvl(i_inst_location, l_id_dest_inst),
                                                                 o_list     => c_list,
                                                                 o_error    => o_error)
            THEN
                RAISE l_exception;
            END IF;
        
            g_error := 'ADD ALL INST LOCATIONS';
            LOOP
                FETCH c_list
                    INTO l_id_inst, l_inst_desc;
                EXIT WHEN c_list%NOTFOUND;
            
                add_new_item(i_ds_cmpt_mkt_rel    => i_ds_cmpt_mkt_rel,
                             i_ds_component       => i_ds_component,
                             i_internal_name      => i_internal_name,
                             i_flg_component_type => i_flg_component_type,
                             i_item_desc          => l_inst_desc,
                             i_item_value         => l_id_inst,
                             i_item_alt_value     => NULL,
                             i_item_rank          => NULL,
                             i_item_xml_value     => l_addict_info,
                             io_tbl_items_values  => l_tbl_items_values);
            END LOOP;
        
            CLOSE c_list;
        END add_preparation;
    
        PROCEDURE add_type_room
        (
            i_ds_cmpt_mkt_rel    IN ds_cmpt_mkt_rel.id_ds_cmpt_mkt_rel%TYPE,
            i_ds_component       IN ds_component.id_ds_component%TYPE,
            i_internal_name      IN ds_component.internal_name%TYPE,
            i_flg_component_type IN ds_component.flg_component_type%TYPE
        ) IS
            l_inner_proc_name CONSTANT VARCHAR2(30) := 'ADD_TYPE_ROOM';
            --
            c_list pk_types.cursor_type;
        
            c_origin pk_list.cursor_origin;
            r_origin pk_list.rec_origin;
        
            l_inst_desc VARCHAR2(300 CHAR);
            l_id_inst   NUMBER;
        BEGIN
        
            IF NOT pk_admission_request.get_room_type_list(i_lang     => i_lang,
                                                           i_prof     => i_prof,
                                                           i_location => nvl(i_inst_location, l_id_dest_inst),
                                                           o_list     => c_list,
                                                           o_error    => o_error)
            THEN
                RAISE l_exception;
            END IF;
        
            g_error := 'ADD ALL INST LOCATIONS';
            LOOP
                FETCH c_list
                    INTO l_id_inst, l_inst_desc;
                EXIT WHEN c_list%NOTFOUND;
            
                add_new_item(i_ds_cmpt_mkt_rel    => i_ds_cmpt_mkt_rel,
                             i_ds_component       => i_ds_component,
                             i_internal_name      => i_internal_name,
                             i_flg_component_type => i_flg_component_type,
                             i_item_desc          => l_inst_desc,
                             i_item_value         => l_id_inst,
                             i_item_alt_value     => NULL,
                             i_item_rank          => NULL,
                             io_tbl_items_values  => l_tbl_items_values);
            END LOOP;
        
            CLOSE c_list;
        END add_type_room;
    
        PROCEDURE add_type_bed
        (
            i_ds_cmpt_mkt_rel    IN ds_cmpt_mkt_rel.id_ds_cmpt_mkt_rel%TYPE,
            i_ds_component       IN ds_component.id_ds_component%TYPE,
            i_internal_name      IN ds_component.internal_name%TYPE,
            i_flg_component_type IN ds_component.flg_component_type%TYPE
        ) IS
            l_inner_proc_name CONSTANT VARCHAR2(30) := 'ADD_TYPE_BED';
            --
            c_list pk_types.cursor_type;
        
            c_origin pk_list.cursor_origin;
            r_origin pk_list.rec_origin;
        
            l_inst_desc VARCHAR2(300 CHAR);
            l_id_inst   NUMBER;
        BEGIN
        
            IF NOT pk_admission_request.get_bed_type_list(i_lang     => i_lang,
                                                          i_prof     => i_prof,
                                                          i_location => nvl(i_inst_location, l_id_dest_inst),
                                                          o_list     => c_list,
                                                          o_error    => o_error)
            THEN
                RAISE l_exception;
            END IF;
        
            g_error := 'ADD ALL INST LOCATIONS';
            LOOP
                FETCH c_list
                    INTO l_id_inst, l_inst_desc;
                EXIT WHEN c_list%NOTFOUND;
            
                add_new_item(i_ds_cmpt_mkt_rel    => i_ds_cmpt_mkt_rel,
                             i_ds_component       => i_ds_component,
                             i_internal_name      => i_internal_name,
                             i_flg_component_type => i_flg_component_type,
                             i_item_desc          => l_inst_desc,
                             i_item_value         => l_id_inst,
                             i_item_alt_value     => NULL,
                             i_item_rank          => NULL,
                             io_tbl_items_values  => l_tbl_items_values);
            END LOOP;
        
            CLOSE c_list;
        END add_type_bed;
    
        PROCEDURE add_loc_nurse
        (
            i_ds_cmpt_mkt_rel    IN ds_cmpt_mkt_rel.id_ds_cmpt_mkt_rel%TYPE,
            i_ds_component       IN ds_component.id_ds_component%TYPE,
            i_internal_name      IN ds_component.internal_name%TYPE,
            i_flg_component_type IN ds_component.flg_component_type%TYPE
        ) IS
            l_inner_proc_name CONSTANT VARCHAR2(30) := 'add_loc_nurse';
            --
            c_list pk_types.cursor_type;
        
            c_origin pk_list.cursor_origin;
            r_origin pk_list.rec_origin;
        
            l_inst_desc        VARCHAR2(300 CHAR);
            l_id_inst          NUMBER;
            l_id_dep_clin_serv NUMBER;
        BEGIN
        
            IF NOT pk_admission_request.get_nit_location_list(i_lang  => i_lang,
                                                              i_prof  => i_prof,
                                                              o_list  => c_list,
                                                              o_error => o_error)
            THEN
                RAISE l_exception;
            END IF;
        
            g_error := 'ADD ALL INST LOCATIONS';
            LOOP
                FETCH c_list
                    INTO l_id_inst, l_inst_desc, l_id_dep_clin_serv;
                EXIT WHEN c_list%NOTFOUND;
            
                add_new_item(i_ds_cmpt_mkt_rel    => i_ds_cmpt_mkt_rel,
                             i_ds_component       => i_ds_component,
                             i_internal_name      => i_internal_name,
                             i_flg_component_type => i_flg_component_type,
                             i_item_desc          => l_inst_desc,
                             i_item_value         => l_id_dep_clin_serv,
                             i_item_alt_value     => NULL,
                             i_item_rank          => NULL,
                             io_tbl_items_values  => l_tbl_items_values);
            END LOOP;
        
            CLOSE c_list;
        END add_loc_nurse;
    
        PROCEDURE add_mix_room
        (
            i_ds_cmpt_mkt_rel    IN ds_cmpt_mkt_rel.id_ds_cmpt_mkt_rel%TYPE,
            i_ds_component       IN ds_component.id_ds_component%TYPE,
            i_internal_name      IN ds_component.internal_name%TYPE,
            i_flg_component_type IN ds_component.flg_component_type%TYPE
        ) IS
            l_inner_proc_name CONSTANT VARCHAR2(30) := 'ADD_MIX_ROOM';
            --
            c_list pk_types.cursor_type;
        
            c_origin pk_list.cursor_origin;
            r_origin pk_list.rec_origin;
        
            l_inst_desc VARCHAR2(300 CHAR);
            l_id_inst   VARCHAR2(2 CHAR);
            l_img_name  VARCHAR2(200 CHAR);
            l_rank      NUMBER;
        BEGIN
        
            IF NOT pk_admission_request.get_mixed_nursing_list(i_lang  => i_lang,
                                                               i_prof  => i_prof,
                                                               o_list  => c_list,
                                                               o_error => o_error)
            THEN
                RAISE l_exception;
            END IF;
        
            g_error := 'ADD ALL INST LOCATIONS';
            LOOP
                FETCH c_list
                    INTO l_inst_desc, l_id_inst, l_img_name, l_rank;
                EXIT WHEN c_list%NOTFOUND;
            
                add_new_item(i_ds_cmpt_mkt_rel    => i_ds_cmpt_mkt_rel,
                             i_ds_component       => i_ds_component,
                             i_internal_name      => i_internal_name,
                             i_flg_component_type => i_flg_component_type,
                             i_item_desc          => l_inst_desc,
                             i_item_value         => NULL,
                             i_item_alt_value     => l_id_inst,
                             i_item_rank          => NULL,
                             io_tbl_items_values  => l_tbl_items_values);
            END LOOP;
        
            CLOSE c_list;
        END add_mix_room;
    
        PROCEDURE add_nurse_intake
        (
            i_ds_cmpt_mkt_rel    IN ds_cmpt_mkt_rel.id_ds_cmpt_mkt_rel%TYPE,
            i_ds_component       IN ds_component.id_ds_component%TYPE,
            i_internal_name      IN ds_component.internal_name%TYPE,
            i_flg_component_type IN ds_component.flg_component_type%TYPE
        ) IS
            l_inner_proc_name CONSTANT VARCHAR2(30) := 'ADD_NURSE_INTAKE';
            --
            c_list pk_types.cursor_type;
        
            c_origin pk_list.cursor_origin;
            r_origin pk_list.rec_origin;
        
            l_inst_desc   VARCHAR2(300 CHAR);
            l_id_inst     VARCHAR2(5 CHAR);
            l_img_name    VARCHAR2(200 CHAR);
            l_rank        NUMBER;
            l_addict_info CLOB;
        BEGIN
        
            IF NOT pk_admission_request.get_nurse_intake_yesno_list(i_lang  => i_lang,
                                                                    i_prof  => i_prof,
                                                                    o_list  => c_list,
                                                                    o_error => o_error)
            THEN
                RAISE l_exception;
            END IF;
        
            g_error := 'ADD ALL INST LOCATIONS';
            LOOP
                FETCH c_list
                    INTO l_inst_desc, l_id_inst, l_img_name, l_rank;
            
                EXIT WHEN c_list%NOTFOUND;
            
                IF i_internal_name NOT IN
                   ('RS_SUR_NEED', g_rs_uci, 'RS_UCI_POS', g_rs_global_anesth, g_rs_local_anesth, 'RI_COMPULSORY')
                THEN
                    SELECT xmlelement("ADDITIONAL_INFO", xmlattributes(decode(l_id_inst, pk_alert_constant.g_yes, pk_alert_constant.g_no, pk_alert_constant.g_yes) AS flg_default)).getclobval() addit_info
                      INTO l_addict_info
                      FROM dual;
                END IF;
            
                IF i_internal_name = 'RS_SUR_NEED'
                THEN
                    SELECT xmlelement("ADDITIONAL_INFO", xmlattributes(decode(l_i_need_surgery, pk_alert_constant.g_yes, decode(l_id_inst, pk_alert_constant.g_yes, pk_alert_constant.g_yes, pk_alert_constant.g_no), decode(l_id_inst, pk_alert_constant.g_no, pk_alert_constant.g_yes, pk_alert_constant.g_no)) AS flg_default)).getclobval() addit_info
                      INTO l_addict_info
                      FROM dual;
                END IF;
            
                add_new_item(i_ds_cmpt_mkt_rel    => i_ds_cmpt_mkt_rel,
                             i_ds_component       => i_ds_component,
                             i_internal_name      => i_internal_name,
                             i_flg_component_type => i_flg_component_type,
                             i_item_desc          => l_inst_desc,
                             i_item_value         => NULL,
                             i_item_alt_value     => l_id_inst,
                             i_item_rank          => NULL,
                             i_item_xml_value     => l_addict_info,
                             io_tbl_items_values  => l_tbl_items_values);
            END LOOP;
        
            CLOSE c_list;
        END add_nurse_intake;
    
        PROCEDURE add_spec_surgery
        (
            i_ds_cmpt_mkt_rel    IN ds_cmpt_mkt_rel.id_ds_cmpt_mkt_rel%TYPE,
            i_ds_component       IN ds_component.id_ds_component%TYPE,
            i_internal_name      IN ds_component.internal_name%TYPE,
            i_flg_component_type IN ds_component.flg_component_type%TYPE
        ) IS
            l_inner_proc_name CONSTANT VARCHAR2(30) := 'ADD_SPEC_SURGERY';
            --
            c_list pk_types.cursor_type;
        
            c_origin pk_list.cursor_origin;
            r_origin pk_list.rec_origin;
        
            l_inst_desc  VARCHAR2(300 CHAR);
            l_id_inst    NUMBER;
            l_addit_info CLOB;
        BEGIN
        
            CASE
                WHEN i_internal_name IN ('RS_SPEC_SURGERY', 'RI_PROF_SPECIALITY')
                     AND l_id_market != pk_alert_constant.g_id_market_cl THEN
                
                    IF NOT pk_list.get_specialty_list(i_lang => i_lang, o_specialty_list => c_list, o_error => o_error)
                    THEN
                        RAISE l_exception;
                    END IF;
                
                    LOOP
                        FETCH c_list
                            INTO l_id_inst, l_inst_desc;
                        EXIT WHEN c_list%NOTFOUND;
                    
                        IF l_id_inst = pk_prof_utils.get_prof_speciality_id(i_lang => i_lang, i_prof => i_prof)
                        THEN
                            SELECT xmlelement("ADDITIONAL_INFO", xmlattributes((pk_alert_constant.g_yes) AS flg_default)).getclobval()
                              INTO l_addit_info
                              FROM dual;
                        END IF;
                    
                        add_new_item(i_ds_cmpt_mkt_rel    => i_ds_cmpt_mkt_rel,
                                     i_ds_component       => i_ds_component,
                                     i_internal_name      => i_internal_name,
                                     i_flg_component_type => i_flg_component_type,
                                     i_item_desc          => l_inst_desc,
                                     i_item_value         => l_id_inst,
                                     i_item_alt_value     => NULL,
                                     i_item_rank          => NULL,
                                     i_item_xml_value     => l_addit_info,
                                     io_tbl_items_values  => l_tbl_items_values);
                    END LOOP;
                    CLOSE c_list;
                
                WHEN i_internal_name = 'RS_DEPARTMENT' THEN
                
                    IF NOT pk_surgery_request.get_department(i_lang  => i_lang,
                                                             i_prof  => i_prof,
                                                             i_inst  => coalesce(i_inst_location,
                                                                                 l_surg_institution,
                                                                                 l_id_dest_inst,
                                                                                 i_prof.institution),
                                                             o_cs    => c_list,
                                                             o_error => o_error)
                    THEN
                        RAISE l_exception;
                    END IF;
                
                    g_error := 'ADD ALL INST LOCATIONS';
                    LOOP
                        FETCH c_list
                            INTO l_id_inst, l_inst_desc, l_addit_info;
                        EXIT WHEN c_list%NOTFOUND;
                    
                        add_new_item(i_ds_cmpt_mkt_rel    => i_ds_cmpt_mkt_rel,
                                     i_ds_component       => i_ds_component,
                                     i_internal_name      => i_internal_name,
                                     i_flg_component_type => i_flg_component_type,
                                     i_item_desc          => l_inst_desc,
                                     i_item_value         => l_id_inst,
                                     i_item_alt_value     => NULL,
                                     i_item_rank          => NULL,
                                     i_item_xml_value     => l_addit_info,
                                     io_tbl_items_values  => l_tbl_items_values);
                    END LOOP;
                    CLOSE c_list;
                
                ELSE
                
                    IF NOT pk_surgery_request.get_dep_clin_serv_ds(i_lang  => i_lang,
                                                                   i_prof  => i_prof,
                                                                   i_inst  => coalesce(i_inst_location,
                                                                                       l_surg_institution,
                                                                                       l_id_dest_inst,
                                                                                       i_prof.institution),
                                                                   i_dept  => i_id_department,
                                                                   o_cs    => c_list,
                                                                   o_error => o_error)
                    THEN
                        RAISE l_exception;
                    END IF;
                
                    g_error := 'ADD ALL INST LOCATIONS';
                    LOOP
                        FETCH c_list
                            INTO l_id_inst, l_inst_desc;
                        EXIT WHEN c_list%NOTFOUND;
                    
                        add_new_item(i_ds_cmpt_mkt_rel    => i_ds_cmpt_mkt_rel,
                                     i_ds_component       => i_ds_component,
                                     i_internal_name      => i_internal_name,
                                     i_flg_component_type => i_flg_component_type,
                                     i_item_desc          => l_inst_desc,
                                     i_item_value         => l_id_inst,
                                     i_item_alt_value     => NULL,
                                     i_item_rank          => NULL,
                                     io_tbl_items_values  => l_tbl_items_values);
                    END LOOP;
                    CLOSE c_list;
            END CASE;
        
        END add_spec_surgery;
    
        PROCEDURE add_surgeons
        (
            i_ds_cmpt_mkt_rel    IN ds_cmpt_mkt_rel.id_ds_cmpt_mkt_rel%TYPE,
            i_ds_component       IN ds_component.id_ds_component%TYPE,
            i_internal_name      IN ds_component.internal_name%TYPE,
            i_flg_component_type IN ds_component.flg_component_type%TYPE
        ) IS
            l_inner_proc_name CONSTANT VARCHAR2(30) := 'ADD_SURGEONS';
            --
            c_list pk_types.cursor_type;
        
            c_origin pk_list.cursor_origin;
            r_origin pk_list.rec_origin;
        
            l_inst_desc   VARCHAR2(300 CHAR);
            l_id_inst     NUMBER;
            l_no          VARCHAR2(2 CHAR);
            l_num         NUMBER;
            l_addict_info CLOB;
        BEGIN
        
            IF NOT pk_surgery_request.get_surgeons_by_dep_clin_serv(i_lang     => i_lang,
                                                                    i_prof     => i_prof,
                                                                    i_inst     => nvl(i_inst_location, l_id_dest_inst),
                                                                    i_id_dcs   => nvl(i_dep_clin_serv_surg, l_surg_spec_id),
                                                                    o_surgeons => c_list,
                                                                    o_error    => o_error)
            THEN
                RAISE l_exception;
            END IF;
        
            g_error := 'ADD ALL INST LOCATIONS';
            LOOP
                FETCH c_list
                    INTO l_id_inst, l_inst_desc, l_no, l_num, l_addict_info;
                EXIT WHEN c_list%NOTFOUND;
            
                add_new_item(i_ds_cmpt_mkt_rel    => i_ds_cmpt_mkt_rel,
                             i_ds_component       => i_ds_component,
                             i_internal_name      => i_internal_name,
                             i_flg_component_type => i_flg_component_type,
                             i_item_desc          => l_inst_desc,
                             i_item_value         => l_id_inst,
                             i_item_alt_value     => NULL,
                             i_item_rank          => NULL,
                             i_item_xml_value     => l_addict_info,
                             io_tbl_items_values  => l_tbl_items_values);
            END LOOP;
        
            CLOSE c_list;
        END add_surgeons;
    
        PROCEDURE add_pref_time
        (
            i_ds_cmpt_mkt_rel    IN ds_cmpt_mkt_rel.id_ds_cmpt_mkt_rel%TYPE,
            i_ds_component       IN ds_component.id_ds_component%TYPE,
            i_internal_name      IN ds_component.internal_name%TYPE,
            i_flg_component_type IN ds_component.flg_component_type%TYPE
        ) IS
            l_inner_proc_name CONSTANT VARCHAR2(30) := 'ADD_SURGEONS';
            --
            c_list pk_types.cursor_type;
        
            c_origin pk_list.cursor_origin;
            r_origin pk_list.rec_origin;
        
            l_inst_desc   VARCHAR2(300 CHAR);
            l_id_inst     VARCHAR2(5 CHAR);
            l_img_name    VARCHAR2(200 CHAR);
            l_rank        NUMBER;
            l_addict_info CLOB;
        BEGIN
        
            IF NOT pk_sysdomain.get_values_domain('WTL_PREF_TIME.FLG_VALUE', i_lang, c_list)
            THEN
                RAISE e_call_error;
            END IF;
        
            g_error := 'ADD ALL INST LOCATIONS';
            LOOP
                FETCH c_list
                    INTO l_inst_desc, l_id_inst, l_img_name, l_rank;
                EXIT WHEN c_list%NOTFOUND;
            
                add_new_item(i_ds_cmpt_mkt_rel    => i_ds_cmpt_mkt_rel,
                             i_ds_component       => i_ds_component,
                             i_internal_name      => i_internal_name,
                             i_flg_component_type => i_flg_component_type,
                             i_item_desc          => l_inst_desc,
                             i_item_value         => NULL,
                             i_item_alt_value     => l_id_inst,
                             i_item_rank          => NULL,
                             io_tbl_items_values  => l_tbl_items_values);
            END LOOP;
        
            CLOSE c_list;
        END add_pref_time;
    
        PROCEDURE add_sys_domains
        (
            i_ds_cmpt_mkt_rel    IN ds_cmpt_mkt_rel.id_ds_cmpt_mkt_rel%TYPE,
            i_ds_component       IN ds_component.id_ds_component%TYPE,
            i_internal_name      IN ds_component.internal_name%TYPE,
            i_flg_component_type IN ds_component.flg_component_type%TYPE
        ) IS
            l_inner_proc_name CONSTANT VARCHAR2(30) := 'ADD_SURGEONS';
            --
            c_list pk_types.cursor_type;
        
            c_origin pk_list.cursor_origin;
            r_origin pk_list.rec_origin;
        
            l_inst_desc   VARCHAR2(300 CHAR);
            l_id_inst     VARCHAR2(5 CHAR);
            l_img_name    VARCHAR2(200 CHAR);
            l_rank        NUMBER;
            l_addict_info CLOB;
        
            l_domain_value VARCHAR2(50 CHAR);
        
        BEGIN
        
            CASE i_internal_name
                WHEN g_ri_regimen THEN
                    l_domain_value := 'ADM_REQUEST.REGIMEN';
                WHEN g_ri_beneficiario THEN
                    l_domain_value := 'ADM_REQUEST.BENEFICIARIO';
                WHEN g_ri_precauciones THEN
                    l_domain_value := 'ADM_REQUEST.PRECAUCIONES';
                WHEN g_ri_contactado THEN
                    l_domain_value := 'ADM_REQUEST.CONTACTADO';
                ELSE
                    l_domain_value := NULL;
            END CASE;
        
            IF NOT pk_sysdomain.get_values_domain(l_domain_value, i_lang, c_list)
            THEN
                RAISE e_call_error;
            END IF;
        
            g_error := 'ADD ALL INST LOCATIONS';
            LOOP
                FETCH c_list
                    INTO l_inst_desc, l_id_inst, l_img_name, l_rank;
                EXIT WHEN c_list%NOTFOUND;
            
                add_new_item(i_ds_cmpt_mkt_rel    => i_ds_cmpt_mkt_rel,
                             i_ds_component       => i_ds_component,
                             i_internal_name      => i_internal_name,
                             i_flg_component_type => i_flg_component_type,
                             i_item_desc          => l_inst_desc,
                             i_item_value         => NULL,
                             i_item_alt_value     => l_id_inst,
                             i_item_rank          => NULL,
                             io_tbl_items_values  => l_tbl_items_values);
            END LOOP;
        
            CLOSE c_list;
        END add_sys_domains;
    
        PROCEDURE add_mot_pref_time
        (
            i_ds_cmpt_mkt_rel    IN ds_cmpt_mkt_rel.id_ds_cmpt_mkt_rel%TYPE,
            i_ds_component       IN ds_component.id_ds_component%TYPE,
            i_internal_name      IN ds_component.internal_name%TYPE,
            i_flg_component_type IN ds_component.flg_component_type%TYPE
        ) IS
            l_inner_proc_name CONSTANT VARCHAR2(30) := 'ADD_INST_DEP';
            --
            c_list pk_types.cursor_type;
        
            c_origin pk_list.cursor_origin;
            r_origin pk_list.rec_origin;
        
            l_inst_desc VARCHAR2(300 CHAR);
            l_id_inst   NUMBER;
        
            l_addit_info CLOB;
        BEGIN
        
            IF NOT pk_surgery_request.get_wtl_ptreason_list(i_lang           => i_lang,
                                                            i_prof           => i_prof,
                                                            i_id_institution => nvl(i_inst_location, l_id_dest_inst),
                                                            o_list           => c_list,
                                                            o_error          => o_error)
            THEN
                RAISE l_exception;
            END IF;
        
            g_error := 'ADD ALL INST LOCATIONS';
            LOOP
                FETCH c_list
                    INTO l_id_inst, l_inst_desc;
                EXIT WHEN c_list%NOTFOUND;
            
                add_new_item(i_ds_cmpt_mkt_rel    => i_ds_cmpt_mkt_rel,
                             i_ds_component       => i_ds_component,
                             i_internal_name      => i_internal_name,
                             i_flg_component_type => i_flg_component_type,
                             i_item_desc          => l_inst_desc,
                             i_item_value         => l_id_inst,
                             i_item_alt_value     => NULL,
                             i_item_rank          => NULL,
                             io_tbl_items_values  => l_tbl_items_values);
            END LOOP;
        
            CLOSE c_list;
        END add_mot_pref_time;
    
        PROCEDURE add_lvl_urg
        (
            i_ds_cmpt_mkt_rel    IN ds_cmpt_mkt_rel.id_ds_cmpt_mkt_rel%TYPE,
            i_ds_component       IN ds_component.id_ds_component%TYPE,
            i_internal_name      IN ds_component.internal_name%TYPE,
            i_flg_component_type IN ds_component.flg_component_type%TYPE
        ) IS
            l_inner_proc_name CONSTANT VARCHAR2(30) := 'ADD_RV_REQUEST';
            --
            c_list pk_types.cursor_type;
        
            c_origin pk_list.cursor_origin;
            r_origin pk_list.rec_origin;
        
            l_inst_desc  VARCHAR2(300 CHAR);
            l_id_inst    NUMBER;
            l_start      VARCHAR2(100 CHAR);
            l_end        VARCHAR2(100 CHAR);
            l_duration   NUMBER;
            l_addit_info CLOB;
            lvl_default  VARCHAR2(1 CHAR);
        
            l_count PLS_INTEGER := 0;
        BEGIN
        
            IF NOT pk_surgery_request.get_wtl_urg_level_list_ds(i_lang    => i_lang,
                                                                i_prof    => i_prof,
                                                                i_lvl_urg => l_u_lvl_id,
                                                                o_list    => c_list,
                                                                o_error   => o_error)
            THEN
                RAISE l_exception;
            END IF;
        
            g_error := 'ADD ALL INST LOCATIONS';
            LOOP
                FETCH c_list
                    INTO l_id_inst, l_inst_desc, lvl_duration, l_start, l_end, l_addit_info, lvl_default;
                EXIT WHEN c_list%NOTFOUND;
            
                IF lvl_default = pk_alert_constant.g_yes
                THEN
                    lvl_start_date_default := l_start;
                    lvl_end_date_default   := l_end;
                    l_has_lvl_urg          := pk_alert_constant.g_yes;
                    l_lvl_urg_dur          := lvl_duration;
                END IF;
                add_new_item(i_ds_cmpt_mkt_rel    => i_ds_cmpt_mkt_rel,
                             i_ds_component       => i_ds_component,
                             i_internal_name      => i_internal_name,
                             i_flg_component_type => i_flg_component_type,
                             i_item_desc          => l_inst_desc,
                             i_item_value         => l_id_inst,
                             i_item_alt_value     => NULL,
                             i_item_rank          => NULL,
                             i_item_xml_value     => l_addit_info,
                             io_tbl_items_values  => l_tbl_items_values);
            
                l_count := l_count + 1;
            END LOOP;
        
            --This element is mandatory, therefore it is necessary to assure that, even when there is no configured content,it is activated
            IF l_count = 0
            THEN
                add_new_item(i_ds_cmpt_mkt_rel    => i_ds_cmpt_mkt_rel,
                             i_ds_component       => i_ds_component,
                             i_internal_name      => i_internal_name,
                             i_flg_component_type => i_flg_component_type,
                             i_item_desc          => NULL,
                             i_item_value         => NULL,
                             i_item_alt_value     => NULL,
                             i_item_rank          => NULL,
                             i_item_xml_value     => NULL,
                             io_tbl_items_values  => l_tbl_items_values);
            END IF;
        
            CLOSE c_list;
        END add_lvl_urg;
    
        PROCEDURE add_unit_measure_ri
        (
            i_ds_cmpt_mkt_rel    IN ds_cmpt_mkt_rel.id_ds_cmpt_mkt_rel%TYPE,
            i_ds_component       IN ds_component.id_ds_component%TYPE,
            i_internal_name      IN ds_component.internal_name%TYPE,
            i_flg_component_type IN ds_component.flg_component_type%TYPE
        ) IS
            l_inner_proc_name CONSTANT VARCHAR2(30) := 'ADD_UNIT_MEASURE';
            --
            c_list pk_types.cursor_type;
        
            l_id_unit_measure         NUMBER(24);
            l_id_unit_measure_subtype NUMBER(24);
            l_code_unit_measure       VARCHAR2(100 CHAR);
            l_transl_unit_measure     VARCHAR2(100 CHAR);
            l_rank                    NUMBER(24);
            l_addit_info              CLOB;
        
        BEGIN
        
            IF l_expected_duration IS NULL
               AND i_internal_name = g_ri_durantion
            THEN
                l_unit_measure := g_unit_measure_hours;
            ELSIF l_expected_duration IS NULL
                  AND (i_internal_name = g_rsp_time_min OR i_internal_name LIKE 'RIP_DURATION%')
            THEN
                l_unit_measure := g_unit_measure_days;
            ELSE
                IF NOT get_duration_unit_measure_ds(i_lang         => i_lang,
                                                    i_prof         => i_prof,
                                                    i_hours        => l_expected_duration * 60,
                                                    i_date         => l_dt_admission,
                                                    o_value        => l_expected_duration,
                                                    o_unit_measure => l_unit_measure,
                                                    o_error        => o_error)
                THEN
                    RAISE l_exception;
                END IF;
            
            END IF;
        
            IF NOT pk_unit_measure.get_umea_type_ds(i_lang                 => i_lang,
                                                    i_prof                 => i_prof,
                                                    i_unit_measure_subtype => g_dyn_unit_meas_type,
                                                    i_unit_measure         => l_unit_measure,
                                                    o_list                 => c_list,
                                                    o_error                => o_error)
            THEN
                RAISE l_exception;
            END IF;
        
            g_error := 'ADD ALL INST LOCATIONS';
            LOOP
                FETCH c_list
                    INTO l_id_unit_measure,
                         l_id_unit_measure_subtype,
                         l_code_unit_measure,
                         l_transl_unit_measure,
                         l_rank,
                         l_addit_info;
                EXIT WHEN c_list%NOTFOUND;
            
                IF (i_internal_name = g_rsp_time_min OR i_internal_name LIKE 'RIP_DURATION%')
                   AND l_id_unit_measure != 1041
                   OR i_internal_name IN (g_ri_durantion)
                THEN
                
                    add_new_item(i_ds_cmpt_mkt_rel    => i_ds_cmpt_mkt_rel,
                                 i_ds_component       => i_ds_component,
                                 i_internal_name      => i_internal_name,
                                 i_flg_component_type => i_flg_component_type,
                                 i_item_desc          => l_transl_unit_measure,
                                 i_item_value         => l_id_unit_measure,
                                 i_item_alt_value     => NULL,
                                 i_item_rank          => NULL,
                                 i_item_xml_value     => l_addit_info,
                                 io_tbl_items_values  => l_tbl_items_values);
                END IF;
            END LOOP;
        
            CLOSE c_list;
        END add_unit_measure_ri;
    
        PROCEDURE add_unit_measure_rs
        (
            i_ds_cmpt_mkt_rel    IN ds_cmpt_mkt_rel.id_ds_cmpt_mkt_rel%TYPE,
            i_ds_component       IN ds_component.id_ds_component%TYPE,
            i_internal_name      IN ds_component.internal_name%TYPE,
            i_flg_component_type IN ds_component.flg_component_type%TYPE
        ) IS
            l_inner_proc_name CONSTANT VARCHAR2(30) := 'ADD_UNIT_MEASURE';
            --
            c_list pk_types.cursor_type;
        
            l_id_unit_measure         NUMBER(24);
            l_id_unit_measure_subtype NUMBER(24);
            l_code_unit_measure       VARCHAR2(100 CHAR);
            l_transl_unit_measure     VARCHAR2(100 CHAR);
            l_rank                    NUMBER(24);
            l_addit_info              CLOB;
        
            l_unit_default NUMBER := g_dyn_unit_meas_type;
        
        BEGIN
        
            IF l_surg_duration IS NULL
               AND i_internal_name IN ('RS_PREV_DURATION')
            THEN
                l_unit_measure_rs := pk_admission_request.g_unit_measure_hours;
            ELSIF l_surg_duration IS NULL
                  AND (i_internal_name = 'RSP_TIME_MIN' OR i_internal_name LIKE 'RIP_DURATION%')
            THEN
                l_unit_measure_rs := pk_admission_request.g_unit_measure_days;
            ELSE
                IF NOT get_duration_unit_measure_ds(i_lang         => i_lang,
                                                    i_prof         => i_prof,
                                                    i_hours        => l_surg_duration,
                                                    i_date         => l_surg_date,
                                                    o_value        => l_surg_duration,
                                                    o_unit_measure => l_unit_measure_rs,
                                                    o_error        => o_error)
                THEN
                    RAISE l_exception;
                END IF;
            
            END IF;
        
            IF i_internal_name = g_rs_prev_duration
            THEN
                l_unit_default := 581;
            END IF;
        
            IF NOT pk_unit_measure.get_umea_type_ds(i_lang                 => i_lang,
                                                    i_prof                 => i_prof,
                                                    i_unit_measure_subtype => l_unit_default,
                                                    i_unit_measure         => l_unit_measure_rs,
                                                    o_list                 => c_list,
                                                    o_error                => o_error)
            THEN
                RAISE l_exception;
            END IF;
        
            g_error := 'ADD ALL INST LOCATIONS';
            LOOP
                FETCH c_list
                    INTO l_id_unit_measure,
                         l_id_unit_measure_subtype,
                         l_code_unit_measure,
                         l_transl_unit_measure,
                         l_rank,
                         l_addit_info;
                EXIT WHEN c_list%NOTFOUND;
            
                IF (i_internal_name = 'RSP_TIME_MIN' OR i_internal_name LIKE 'RIP_DURATION%')
                   AND l_id_unit_measure != 1041
                   OR i_internal_name IN ('RS_PREV_DURATION')
                THEN
                
                    add_new_item(i_ds_cmpt_mkt_rel    => i_ds_cmpt_mkt_rel,
                                 i_ds_component       => i_ds_component,
                                 i_internal_name      => i_internal_name,
                                 i_flg_component_type => i_flg_component_type,
                                 i_item_desc          => l_transl_unit_measure,
                                 i_item_value         => l_id_unit_measure,
                                 i_item_alt_value     => NULL,
                                 i_item_rank          => NULL,
                                 i_item_xml_value     => l_addit_info,
                                 io_tbl_items_values  => l_tbl_items_values);
                
                END IF;
            END LOOP;
        
            CLOSE c_list;
        END add_unit_measure_rs;
    
        PROCEDURE add_cosign_order_type
        (
            i_ds_cmpt_mkt_rel    IN ds_cmpt_mkt_rel.id_ds_cmpt_mkt_rel%TYPE,
            i_ds_component       IN ds_component.id_ds_component%TYPE,
            i_internal_name      IN ds_component.internal_name%TYPE,
            i_flg_component_type IN ds_component.flg_component_type%TYPE
        ) IS
            l_inner_proc_name CONSTANT VARCHAR2(30) := 'ADD_RV_REQUEST';
            --
            c_list pk_types.cursor_type;
        
            c_origin pk_list.cursor_origin;
            r_origin pk_list.rec_origin;
        
            l_inst_desc  VARCHAR2(300 CHAR);
            l_id_inst    NUMBER;
            l_start      VARCHAR2(100 CHAR);
            l_end        VARCHAR2(100 CHAR);
            l_duration   NUMBER;
            l_addit_info CLOB;
            lvl_default  VARCHAR2(1 CHAR);
        
        BEGIN
        
            IF NOT pk_co_sign_api.get_order_type(i_lang       => i_lang,
                                                 i_prof       => i_prof,
                                                 o_order_type => c_list,
                                                 o_error      => o_error)
            THEN
                RAISE l_exception;
            END IF;
        
            g_error := 'ADD ALL INST LOCATIONS';
            LOOP
                FETCH c_list
                    INTO l_id_inst, l_inst_desc, l_start, l_duration, l_end;
                EXIT WHEN c_list%NOTFOUND;
            
                add_new_item(i_ds_cmpt_mkt_rel    => i_ds_cmpt_mkt_rel,
                             i_ds_component       => i_ds_component,
                             i_internal_name      => i_internal_name,
                             i_flg_component_type => i_flg_component_type,
                             i_item_desc          => l_inst_desc,
                             i_item_value         => l_id_inst,
                             i_item_alt_value     => NULL,
                             i_item_rank          => NULL,
                             i_item_xml_value     => NULL,
                             io_tbl_items_values  => l_tbl_items_values);
            END LOOP;
        
            CLOSE c_list;
        END add_cosign_order_type;
    
        PROCEDURE add_cosign_prof_list
        (
            i_ds_cmpt_mkt_rel    IN ds_cmpt_mkt_rel.id_ds_cmpt_mkt_rel%TYPE,
            i_ds_component       IN ds_component.id_ds_component%TYPE,
            i_internal_name      IN ds_component.internal_name%TYPE,
            i_flg_component_type IN ds_component.flg_component_type%TYPE
        ) IS
            l_inner_proc_name CONSTANT VARCHAR2(30) := 'ADD_RV_REQUEST';
            --
            c_list pk_types.cursor_type;
        
            c_origin pk_list.cursor_origin;
            r_origin pk_list.rec_origin;
        
            l_inst_desc  VARCHAR2(300 CHAR);
            l_id_inst    NUMBER;
            l_start      VARCHAR2(100 CHAR);
            l_end        VARCHAR2(100 CHAR);
            l_duration   NUMBER;
            l_addit_info CLOB;
            lvl_default  VARCHAR2(1 CHAR);
        
        BEGIN
        
            IF NOT pk_co_sign_api.get_prof_list(i_lang       => i_lang,
                                                i_prof       => i_prof,
                                                i_id_episode => i_episode,
                                                o_prof_list  => c_list,
                                                o_error      => o_error)
            THEN
                RAISE l_exception;
            END IF;
        
            g_error := 'ADD ALL INST LOCATIONS';
            LOOP
                FETCH c_list
                    INTO l_id_inst, l_inst_desc, lvl_default;
                EXIT WHEN c_list%NOTFOUND;
            
                add_new_item(i_ds_cmpt_mkt_rel    => i_ds_cmpt_mkt_rel,
                             i_ds_component       => i_ds_component,
                             i_internal_name      => i_internal_name,
                             i_flg_component_type => i_flg_component_type,
                             i_item_desc          => l_inst_desc,
                             i_item_value         => l_id_inst,
                             i_item_alt_value     => NULL,
                             i_item_rank          => NULL,
                             i_item_xml_value     => NULL,
                             io_tbl_items_values  => l_tbl_items_values);
            END LOOP;
        
            CLOSE c_list;
        END add_cosign_prof_list;
    
    BEGIN
        g_sysdate_tstz := current_timestamp;
    
        l_dbg_msg := 'get dynamic screen section complete structure';
        pk_alertlog.log_info(text            => l_dbg_msg,
                             object_name     => 'Pk_ADMISSION_REQUEST',
                             sub_object_name => 'GET_SECTION_DATA');
    
        IF i_waiting_list IS NOT NULL
        THEN
        
            BEGIN
                SELECT wtle.id_episode
                  INTO l_id_episode_sr
                  FROM wtl_epis wtle
                 WHERE wtle.id_waiting_list = i_waiting_list
                   AND wtle.id_epis_type = l_epis_type_sr;
            EXCEPTION
                WHEN no_data_found THEN
                    l_id_episode_sr := NULL;
            END;
        
            BEGIN
                SELECT wtle.id_episode
                  INTO l_id_episode_inp
                  FROM wtl_epis wtle
                 WHERE wtle.id_waiting_list = i_waiting_list
                   AND wtle.id_epis_type = l_epis_type_inp;
            EXCEPTION
                WHEN no_data_found THEN
                    l_id_episode_inp := NULL;
            END;
        
            IF i_component_name IN (g_request_inpatient, g_request_surgery)
            THEN
            
                IF NOT get_admission_request_ds(i_lang                 => i_lang,
                                                i_prof                 => i_prof,
                                                i_id_episode           => l_id_episode_inp,
                                                i_id_waiting_list      => i_waiting_list,
                                                o_dt_admission         => l_dt_admission,
                                                o_id_dep_clin_serv     => l_id_dep_clin_serv,
                                                o_desc_dep_clin_serv   => l_desc_dep_clin_serv,
                                                o_id_prof_spec_adm     => l_id_prof_spec_adm,
                                                o_desc_prof_spec_adm   => l_desc_prof_spec_adm,
                                                o_id_adm_phys          => l_id_adm_phys,
                                                o_name_adm_phys        => l_name_adm_phys,
                                                o_id_mrp               => l_id_mrp,
                                                o_name_mrp             => l_name_mrp,
                                                o_id_written_by        => l_id_written_by,
                                                o_name_written_by      => l_name_written_by,
                                                o_id_compulsory        => l_compulsory_id,
                                                o_desc_compulsory      => l_compulsory_desc,
                                                o_id_compulsory_opt    => l_compulsory_id_opt,
                                                o_desc_compulsory_opt  => l_compulsory_desc_opt,
                                                o_id_adm_indication    => l_id_adm_indication,
                                                o_desc_adm_indication  => l_desc_adm_indication,
                                                o_id_admission_type    => l_id_admission_type,
                                                o_desc_adm_type        => l_desc_adm_type,
                                                o_expected_duration    => l_expected_duration,
                                                o_id_adm_preparation   => l_id_adm_preparation,
                                                o_desc_adm_preparation => l_desc_adm_preparation,
                                                o_id_dest_inst         => l_id_dest_inst,
                                                o_desc_dest_inst       => l_desc_dest_inst,
                                                o_id_department        => l_id_department,
                                                o_desc_depart          => l_desc_depart,
                                                o_id_room_type         => l_id_room_type,
                                                o_desc_room_type       => l_desc_room_type,
                                                o_flg_mixed_nursing    => l_flg_mixed_nursing,
                                                o_id_bed_type          => l_id_bed_type,
                                                o_desc_bed_type        => l_desc_bed_type,
                                                o_id_pref_room         => l_id_pref_room,
                                                o_dep_pref_room        => l_dep_pref_room,
                                                o_desc_pref_room       => l_desc_pref_room,
                                                o_flg_nit              => l_flg_nit,
                                                o_flg_nit_desc         => l_flg_nit_desc,
                                                o_dt_nit_suggested     => l_dt_nit_suggested,
                                                o_id_nit_dcs           => l_id_nit_dcs,
                                                o_nit_dt_sugg_send     => l_nit_dt_sugg_send,
                                                o_nit_dt_sugg_char     => l_nit_dt_sugg_char,
                                                o_nit_location         => l_nit_location,
                                                o_notes                => l_notes,
                                                o_diag                 => o_data_diag,
                                                o_id_regimen           => l_id_regimen,
                                                o_desc_regimen         => l_desc_regimen,
                                                o_id_beneficiario      => l_id_beneficiario,
                                                o_desc_beneficiario    => l_desc_beneficiario,
                                                o_id_precauciones      => l_id_precauciones,
                                                o_desc_precauciones    => l_desc_precauciones,
                                                o_id_contactado        => l_id_contactado,
                                                o_desc_contactado      => l_desc_contactado,
                                                o_error                => o_error)
                THEN
                    RAISE l_exception;
                END IF;
            END IF;
        
            IF i_component_name = 'REQUEST_COSIGN'
            THEN
                BEGIN
                    SELECT c.id_prof_ordered_by id_prof_order,
                           c.desc_prof_ordered_by prof_order,
                           pk_date_utils.date_send_tsz(i_lang, c.dt_ordered_by, i_prof) dt_order_str,
                           pk_date_utils.date_char_tsz(i_lang, c.dt_ordered_by, i_prof.institution, i_prof.software) dt_order,
                           c.id_order_type,
                           c.desc_order_type order_type
                      INTO l_rc_by_id, l_rc_by_desc, l_rc_at_id, l_rc_at_desc, l_rc_type_id, l_rc_type_desc
                      FROM adm_request a
                     INNER JOIN wtl_epis b
                        ON a.id_dest_episode = b.id_episode
                     INNER JOIN TABLE(pk_co_sign_api.tf_co_sign_task_info(i_lang, i_prof, i_episode, NULL)) c
                        ON c.id_co_sign = a.id_co_sign_order
                     WHERE b.id_waiting_list = i_waiting_list
                       AND a.id_adm_request = c.id_task;
                EXCEPTION
                    WHEN OTHERS THEN
                        l_rc_by_id     := NULL;
                        l_rc_by_desc   := NULL;
                        l_rc_at_id     := NULL;
                        l_rc_at_desc   := NULL;
                        l_rc_type_id   := NULL;
                        l_rc_type_desc := NULL;
                END;
            END IF;
        
            IF i_component_name = g_request_surgery
            THEN
            
                IF l_id_episode_sr IS NOT NULL
                THEN
                    IF NOT pk_surgery_request.get_surgery_request_ds(i_lang                      => i_lang,
                                                                     i_prof                      => i_prof,
                                                                     i_id_episode                => l_id_episode_sr,
                                                                     i_id_waiting_list           => i_waiting_list,
                                                                     o_surg_date                 => l_surg_date,
                                                                     o_surg_spec_id              => l_surg_spec_id,
                                                                     o_surg_spec_desc            => l_surg_spec_desc,
                                                                     o_surg_speciality           => l_surg_speciality,
                                                                     o_surg_speciality_desc      => l_surg_speciality_desc,
                                                                     o_surg_department           => l_surg_department,
                                                                     o_surg_department_desc      => l_surg_department_desc,
                                                                     o_surg_pref_id              => l_surg_pref_id,
                                                                     o_surg_pref_desc            => l_surg_pref_desc,
                                                                     o_surg_proc                 => l_surg_proc,
                                                                     o_surg_spec_ext_id          => l_surg_spec_ext_id,
                                                                     o_surg_spec_ext_desc        => l_surg_spec_ext_desc,
                                                                     o_surg_danger_cont          => l_surg_danger_cont,
                                                                     o_surg_pref_time_id         => l_surg_pref_time_id,
                                                                     o_surg_pref_time_desc       => l_surg_pref_time_desc,
                                                                     o_surg_pref_time_flg        => l_surg_pref_time_flg,
                                                                     o_surg_pref_reason_id       => l_surg_pref_reason_id,
                                                                     o_surg_pref_reason_desc     => l_surg_pref_reason_desc,
                                                                     o_surg_duration             => l_surg_duration,
                                                                     o_surg_icu                  => l_surg_icu,
                                                                     o_surg_desc_icu             => l_surg_desc_icu,
                                                                     o_surg_icu_pos              => l_surg_icu_pos,
                                                                     o_surg_desc_icu_pos         => l_surg_desc_icu_pos,
                                                                     o_surg_notes                => l_surg_notes,
                                                                     o_surg_need                 => l_surg_need,
                                                                     o_surg_need_desc            => l_surg_need_desc,
                                                                     o_surg_institution          => l_surg_institution,
                                                                     o_surg_institution_desc     => l_surg_institution_desc,
                                                                     o_procedures                => o_data_proc,
                                                                     o_interv_clinical_questions => o_interv_clinical_questions,
                                                                     o_danger_cont               => o_data_diag,
                                                                     o_interv_supplies           => o_interv_supplies,
                                                                     o_global_anesth_desc        => l_surg_global_anesth_desc,
                                                                     o_global_anesth_id          => l_surg_global_anesth_id,
                                                                     o_local_anesth_desc         => l_surg_local_anesth_desc,
                                                                     o_local_anesth_id           => l_surg_local_anesth_id,
                                                                     o_error                     => o_error)
                    THEN
                        RAISE l_exception;
                    END IF;
                
                    l_need_surgery := pk_alert_constant.g_yes;
                
                    IF i_ask_hosp = pk_alert_constant.g_yes
                    THEN
                        l_surg_need      := pk_alert_constant.g_yes;
                        l_surg_need_desc := pk_sysdomain.get_domain(i_code_dom => 'YES_NO',
                                                                    i_val      => pk_alert_constant.g_yes,
                                                                    i_lang     => i_lang);
                    END IF;
                
                END IF;
            
            END IF;
        
            IF i_component_name LIKE 'REQUEST_IND_PER%'
            THEN
            
                BEGIN
                    SELECT z.dt_unav_start_send,
                           z.dt_unav_start_char,
                           z.duration,
                           z.dt_unav_end_send,
                           z.dt_unav_end_char
                      INTO l_unav_start, l_unav_start_chr, l_unav_duration, l_unav_end, l_unav_end_chr
                      FROM (SELECT pk_date_utils.date_send_tsz(i_lang, u.dt_unav_start, i_prof) dt_unav_start_send,
                                   pk_date_utils.date_char_tsz(i_lang,
                                                               u.dt_unav_start,
                                                               i_prof.institution,
                                                               i_prof.software) dt_unav_start_char,
                                   (round(pk_date_utils.get_timestamp_diff(u.dt_unav_end, u.dt_unav_start)) * 24 * 60) +
                                   24 * 60 duration,
                                   pk_date_utils.date_send_tsz(i_lang, u.dt_unav_end, i_prof) dt_unav_end_send,
                                   pk_date_utils.date_char_tsz(i_lang,
                                                               u.dt_unav_end,
                                                               i_prof.institution,
                                                               i_prof.software) dt_unav_end_char,
                                   row_number() over(PARTITION BY u.id_waiting_list ORDER BY u.id_wtl_unav) rn
                              FROM wtl_unav u
                             WHERE u.id_waiting_list = i_waiting_list
                               AND u.flg_status = pk_alert_constant.g_active
                             ORDER BY u.id_wtl_unav) z
                     WHERE rn = (i_unav_val + 1);
                EXCEPTION
                    WHEN no_data_found THEN
                        l_unav_start    := NULL;
                        l_unav_duration := NULL;
                        l_unav_end      := NULL;
                END;
            
                IF NOT get_duration_unit_measure_ds(i_lang         => i_lang,
                                                    i_prof         => i_prof,
                                                    i_hours        => l_unav_duration,
                                                    i_date         => NULL,
                                                    o_value        => l_unav_duration,
                                                    o_unit_measure => l_unav_duration_umea,
                                                    o_error        => o_error)
                THEN
                    RAISE l_exception;
                END IF;
            
                IF l_unav_start IS NOT NULL
                THEN
                    l_has_unav := pk_alert_constant.g_yes;
                END IF;
            
            END IF;
        
            IF i_component_name = g_request_sched_per
            THEN
            
                BEGIN
                    SELECT -- 16 - Scheduling period start
                     pk_date_utils.date_send_tsz(i_lang, wl.dt_dpb, i_prof) dt_sched_start_send,
                     /* pk_date_utils.date_char_tsz(i_lang, wl.dt_dpb, i_prof.institution, i_prof.software) dt_sched_start_char,*/
                     --'20150205' dt_sched_start_send,
                     pk_date_utils.dt_chr(i_lang, wl.dt_dpb, i_prof) dt_sched_start_char,
                     -- 17 - Urg level
                     wl.id_wtl_urg_level,
                     nvl(wul.desc_wtl_urg_level, pk_translation.get_translation(i_lang, wul.code)) desc_urg_level,
                     wul.duration duration_urg_level,
                     -- 18 - Scheduling period end
                     pk_date_utils.date_send_tsz(i_lang, wl.dt_dpa, i_prof) dt_sched_end_send,
                     pk_date_utils.date_char_tsz(i_lang, wl.dt_dpa, i_prof.institution, i_prof.software) dt_sched_end_char,
                     -- 19 - Minimum time to inform
                     wl.min_inform_time,
                     -- 20 - Suggested surgery date / Suggested admission date
                     pk_date_utils.date_send_tsz(i_lang, wl.dt_surgery, i_prof) dt_sug_surg_send,
                     pk_date_utils.date_char_tsz(i_lang, wl.dt_surgery, i_prof.institution, i_prof.software) dt_sug_surg_char,
                     pk_date_utils.date_send_tsz(i_lang, wl.dt_admission, i_prof) dt_sug_admission_send,
                     pk_date_utils.date_char_tsz(i_lang, wl.dt_admission, i_prof.institution, i_prof.software) dt_sug_admission_char
                      INTO l_sch_dt_start,
                           l_sch_dt_start_chr,
                           l_sch_lvl_urg,
                           l_sch_lvl_urg_desc,
                           l_sch_duration,
                           l_sch_dt_end,
                           l_sch_dt_end_chr,
                           l_sch_min_inform,
                           l_sch_dt_sug_surg,
                           l_sch_dt_sug_surg_chr,
                           l_sch_dt_sug_int,
                           l_sch_dt_sug_int_chr
                      FROM waiting_list wl
                      LEFT JOIN wtl_urg_level wul
                        ON wl.id_wtl_urg_level = wul.id_wtl_urg_level
                      LEFT JOIN adm_request adm
                        ON adm.id_dest_episode = l_id_episode_inp
                    --INNER JOIN schedule_sr s ON wl.id_waiting_list = s.id_waiting_list
                    -- José Brito 07/05/09 Show scheduling period when there's no surgery request
                      LEFT JOIN schedule_sr s
                        ON wl.id_waiting_list = s.id_waiting_list
                     WHERE wl.id_waiting_list = i_waiting_list
                       AND (s.id_episode = l_id_episode_sr OR l_id_episode_sr IS NULL);
                EXCEPTION
                    WHEN no_data_found THEN
                        l_sch_dt_start     := NULL;
                        l_sch_lvl_urg      := NULL;
                        l_sch_lvl_urg_desc := NULL;
                        l_sch_dt_end       := NULL;
                        l_sch_min_inform   := NULL;
                        l_sch_dt_sug_surg  := NULL;
                        l_sch_dt_sug_int   := NULL;
                END;
            
                IF i_waiting_list IS NOT NULL
                   AND l_sch_dt_start IS NULL
                   AND i_order_set != pk_alert_constant.g_yes
                THEN
                    l_sch_dt_start     := pk_date_utils.date_send_tsz(i_lang, current_timestamp, i_prof);
                    l_sch_dt_start_chr := pk_date_utils.dt_chr(i_lang, current_timestamp, i_prof);
                
                    l_sch_dt_end     := pk_date_utils.date_send_tsz(i_lang,
                                                                    current_timestamp + to_number(l_sch_duration),
                                                                    i_prof);
                    l_sch_dt_end_chr := pk_date_utils.dt_chr(i_lang,
                                                             current_timestamp + to_number(l_sch_duration),
                                                             i_prof);
                
                END IF;
            
                IF l_sch_lvl_urg IS NOT NULL
                THEN
                    l_has_lvl_urg := pk_alert_constant.g_yes;
                END IF;
            
            END IF;
        
            IF i_component_name = g_request_ver_op
            THEN
            
                BEGIN
                    SELECT id_sr_pos_schedule
                      INTO l_id_sr_pos_schedule
                      FROM (SELECT sps.id_sr_pos_schedule, rank() over(ORDER BY sps.dt_req DESC) origin_rank
                              FROM schedule_sr ssr
                             INNER JOIN sr_pos_schedule sps
                                ON sps.id_schedule_sr = ssr.id_schedule_sr
                             WHERE ssr.id_waiting_list = i_waiting_list
                            
                            )
                     WHERE origin_rank = 1;
                EXCEPTION
                    WHEN no_data_found THEN
                        g_error := 'ID_SR_POS_SCHEDULE not found';
                        pk_alertlog.log_debug(text            => g_error,
                                              object_name     => 'PK_ADMISSION_REQUEST',
                                              sub_object_name => 'GET_SECTION_DATA');
                        l_id_sr_pos_schedule := NULL;
                END;
            
                IF l_id_sr_pos_schedule IS NOT NULL
                THEN
                
                    IF NOT pk_sr_pos.get_pos_decision_ds(i_lang               => i_lang,
                                                         i_prof               => i_prof,
                                                         i_id_sr_pos_schedule => l_id_sr_pos_schedule,
                                                         i_flg_return_opts    => pk_alert_constant.g_no,
                                                         o_pos_dt_sugg        => l_pos_dt_sugg,
                                                         o_pos_dt_sugg_chr    => l_pos_dt_sugg_chr,
                                                         o_pos_notes          => l_pos_notes,
                                                         o_pos_sr_stauts      => l_pos_sr_stauts,
                                                         o_pos_desc_decision  => l_pos_desc_decision,
                                                         o_pos_valid_days     => l_pos_valid_days,
                                                         o_pos_desc_notes     => l_pos_desc_notes,
                                                         o_pos_need_op        => l_pos_need_op,
                                                         o_pos_need_op_desc   => l_pos_need_op_desc,
                                                         o_error              => o_error)
                    THEN
                        RAISE l_exception;
                    END IF;
                END IF;
            END IF;
        
        ELSE
        
            IF NOT pk_diagnosis.get_count_final_diagnosis(i_lang          => i_lang,
                                                          i_prof          => i_prof,
                                                          i_epis          => i_episode,
                                                          i_prof_cat_type => pk_diagnosis.g_diag_type_d,
                                                          o_count         => l_count_diag,
                                                          o_error         => o_error)
            THEN
                RAISE l_exception;
            END IF;
        
            /*IF l_count_diag = 1
            THEN*/
        
            IF i_component_name = g_request_inpatient
            THEN
                IF NOT pk_diagnosis.get_epis_diag(i_lang    => i_lang,
                                                  i_prof    => i_prof,
                                                  i_episode => i_episode,
                                                  o_diag    => o_data_diag,
                                                  o_error   => o_error)
                THEN
                    RAISE l_exception;
                END IF;
            END IF;
        
            IF i_component_name = g_request_surgery
            THEN
                IF NOT pk_diagnosis.get_epis_diag(i_lang    => i_lang,
                                                  i_prof    => i_prof,
                                                  i_episode => i_episode,
                                                  o_diag    => o_data_diag,
                                                  o_error   => o_error)
                THEN
                    RAISE l_exception;
                END IF;
            END IF;
            /*END IF;*/
        
        END IF;
    
        IF NOT pk_dynamic_screen.get_ds_section_complete_struct(i_lang           => i_lang,
                                                                i_prof           => i_prof,
                                                                i_component_name => i_component_name,
                                                                i_component_type => nvl(i_component_type,
                                                                                        pk_dynamic_screen.c_node_component),
                                                                i_patient        => i_patient,
                                                                o_section        => l_tbl_sections,
                                                                o_def_events     => l_tbl_def_events,
                                                                o_events         => l_tbl_events,
                                                                o_items_values   => l_tbl_items_values,
                                                                o_error          => o_error)
        THEN
            pk_types.open_my_cursor(i_cursor => o_section);
            pk_types.open_my_cursor(i_cursor => o_def_events);
            pk_types.open_my_cursor(i_cursor => o_events);
            pk_types.open_my_cursor(i_cursor => o_items_values);
            o_data_val := NULL;
            RETURN FALSE;
        END IF;
    
        IF i_unav_val > 0
           AND i_component_name LIKE 'REQUEST_IND_PER%'
        THEN
        
            IF NOT handle_unav(i_lang    => i_lang,
                               i_prof    => i_prof,
                               i_episode => i_episode,
                               --i_current_section   => 'REQUEST_IND_PER',
                               i_current_section   => i_component_name,
                               i_unav_num          => i_unav_val,
                               io_tab_sections     => l_tbl_sections,
                               io_tab_def_events   => l_tbl_def_events,
                               io_tab_events       => l_tbl_events,
                               io_tab_items_values => l_tbl_items_values,
                               o_error             => o_error)
            THEN
                pk_types.open_my_cursor(i_cursor => o_section);
                pk_types.open_my_cursor(i_cursor => o_def_events);
                pk_types.open_my_cursor(i_cursor => o_events);
                pk_types.open_my_cursor(i_cursor => o_items_values);
                o_data_val := NULL;
                RETURN FALSE;
            END IF;
        
        END IF;
    
        IF i_adm_indication IS NOT NULL
           OR l_id_dest_inst IS NOT NULL
        THEN
        
            IF NOT pk_admission_request.get_adm_indication_det(i_lang              => i_lang,
                                                               i_prof              => i_prof,
                                                               i_adm_indication    => nvl(i_adm_indication,
                                                                                          l_id_adm_indication),
                                                               o_avg_duration      => l_avg_duration,
                                                               o_u_lvl_id          => l_u_lvl_id,
                                                               o_u_lvl_duration    => l_u_lvl_duration,
                                                               o_u_lvl_description => l_u_lvl_description,
                                                               o_dt_begin          => l_dt_begin,
                                                               o_dt_end            => l_dt_end,
                                                               o_location          => l_location,
                                                               o_location_desc     => l_location_desc,
                                                               o_ward              => l_ward,
                                                               o_ward_desc         => l_ward_desc,
                                                               o_dep_clin_serv     => l_dep_clin_serv,
                                                               o_clin_serv_desc    => l_clin_serv_desc,
                                                               o_professional      => l_professional,
                                                               o_prof_desc         => l_prof_desc,
                                                               o_adm_type          => l_adm_type,
                                                               o_adm_type_desc     => l_adm_type_desc,
                                                               o_error             => o_error)
            THEN
                RAISE l_exception;
            END IF;
        
            IF l_id_dest_inst IS NULL
            THEN
                IF i_adm_indication = pk_admission_request.g_reason_admission_ft
                THEN
                    l_id_dest_inst := i_prof.institution;
                ELSE
                    l_id_dest_inst := l_location;
                END IF;
            END IF;
        
        END IF;
    
        IF (i_inst_location IS NOT NULL AND i_id_department IS NULL)
           OR l_id_dest_inst IS NOT NULL
        THEN
            -- GET_DEFAULTS_WITH_LOCATION
            IF NOT pk_admission_request.get_defaults_with_location(i_lang           => i_lang,
                                                                   i_prof           => i_prof,
                                                                   i_adm_indication => nvl(i_adm_indication,
                                                                                           l_id_adm_indication),
                                                                   i_location       => nvl(i_inst_location, l_id_dest_inst),
                                                                   o_ward           => l_ward,
                                                                   o_ward_desc      => l_ward_desc,
                                                                   o_dep_clin_serv  => l_dep_clin_serv,
                                                                   o_clin_serv_desc => l_clin_serv_desc,
                                                                   o_professional   => l_professional,
                                                                   o_prof_desc      => l_prof_desc,
                                                                   o_adm_type       => l_adm_type,
                                                                   o_adm_type_desc  => l_adm_type_desc,
                                                                   o_error          => o_error)
            THEN
                RAISE l_exception;
            END IF;
        END IF;
    
        IF (i_id_department IS NOT NULL AND i_dep_clin_serv IS NULL)
           OR l_id_department IS NOT NULL
        THEN
            -- GET_DEFAULTS_WITH_WARD
            IF NOT
                pk_admission_request.get_defaults_with_ward(i_lang           => i_lang,
                                                            i_prof           => i_prof,
                                                            i_adm_indication => nvl(i_adm_indication, l_id_adm_indication),
                                                            i_ward           => nvl(i_id_department, l_id_department),
                                                            o_dep_clin_serv  => l_dep_clin_serv,
                                                            o_clin_serv_desc => l_clin_serv_desc,
                                                            o_professional   => l_professional,
                                                            o_prof_desc      => l_prof_desc,
                                                            o_adm_type       => l_adm_type,
                                                            o_adm_type_desc  => l_adm_type_desc,
                                                            o_error          => o_error)
            THEN
                RAISE l_exception;
            END IF;
        END IF;
    
        IF i_dep_clin_serv IS NOT NULL
           OR l_id_dep_clin_serv IS NOT NULL
        THEN
            -- GET_DEFAULTS_WITH_DCS
            IF NOT pk_admission_request.get_defaults_with_dcs(i_lang          => i_lang,
                                                              i_prof          => i_prof,
                                                              i_dep_clin_serv => nvl(i_dep_clin_serv, l_id_dep_clin_serv),
                                                              o_professional  => l_professional,
                                                              o_prof_desc     => l_prof_desc,
                                                              o_error         => o_error)
            THEN
                RAISE l_exception;
            END IF;
        END IF;
    
        IF l_sch_min_inform IS NOT NULL
        THEN
            IF NOT get_duration_unit_measure_ds(i_lang         => i_lang,
                                                i_prof         => i_prof,
                                                i_hours        => (l_sch_min_inform * 24 * 60),
                                                i_date         => l_dt_admission,
                                                o_value        => l_sch_min_inform,
                                                o_unit_measure => l_sch_min_inform_um,
                                                o_error        => o_error)
            THEN
                RAISE l_exception;
            END IF;
        END IF;
    
        FOR i IN l_tbl_sections.first .. l_tbl_sections.last
        LOOP
            r_section := l_tbl_sections(i);
        
            CASE
                WHEN r_section.internal_name IN (g_ri_loc_int) THEN
                    add_inst_location(i_ds_cmpt_mkt_rel    => r_section.id_ds_cmpt_mkt_rel,
                                      i_ds_component       => r_section.id_ds_component,
                                      i_internal_name      => r_section.internal_name,
                                      i_flg_component_type => r_section.flg_component_type);
                WHEN r_section.internal_name IN (g_rs_loc_surgery) THEN
                    add_inst_location_surg(i_ds_cmpt_mkt_rel    => r_section.id_ds_cmpt_mkt_rel,
                                           i_ds_component       => r_section.id_ds_component,
                                           i_internal_name      => r_section.internal_name,
                                           i_flg_component_type => r_section.flg_component_type);
                WHEN r_section.internal_name = g_ri_serv_adm THEN
                    add_inst_dep(i_ds_cmpt_mkt_rel    => r_section.id_ds_cmpt_mkt_rel,
                                 i_ds_component       => r_section.id_ds_component,
                                 i_internal_name      => r_section.internal_name,
                                 i_flg_component_type => r_section.flg_component_type);
                WHEN r_section.internal_name = g_ri_esp_int THEN
                    add_dep_clin_serv(i_ds_cmpt_mkt_rel    => r_section.id_ds_cmpt_mkt_rel,
                                      i_ds_component       => r_section.id_ds_component,
                                      i_internal_name      => r_section.internal_name,
                                      i_flg_component_type => r_section.flg_component_type);
                WHEN r_section.internal_name IN (g_ri_phys_adm, g_ri_written_by) THEN
                    add_phys_adm(i_ds_cmpt_mkt_rel    => r_section.id_ds_cmpt_mkt_rel,
                                 i_ds_component       => r_section.id_ds_component,
                                 i_internal_name      => r_section.internal_name,
                                 i_flg_component_type => r_section.flg_component_type);
                WHEN r_section.internal_name = g_ri_mrp THEN
                    add_mrp(i_ds_cmpt_mkt_rel    => r_section.id_ds_cmpt_mkt_rel,
                            i_ds_component       => r_section.id_ds_component,
                            i_internal_name      => r_section.internal_name,
                            i_flg_component_type => r_section.flg_component_type);
                WHEN r_section.internal_name = g_rs_type_int THEN
                    add_type_int(i_ds_cmpt_mkt_rel    => r_section.id_ds_cmpt_mkt_rel,
                                 i_ds_component       => r_section.id_ds_component,
                                 i_internal_name      => r_section.internal_name,
                                 i_flg_component_type => r_section.flg_component_type);
                WHEN r_section.internal_name = g_ri_prepar THEN
                    add_preparation(i_ds_cmpt_mkt_rel    => r_section.id_ds_cmpt_mkt_rel,
                                    i_ds_component       => r_section.id_ds_component,
                                    i_internal_name      => r_section.internal_name,
                                    i_flg_component_type => r_section.flg_component_type);
                WHEN r_section.internal_name = g_ri_type_room THEN
                    add_type_room(i_ds_cmpt_mkt_rel    => r_section.id_ds_cmpt_mkt_rel,
                                  i_ds_component       => r_section.id_ds_component,
                                  i_internal_name      => r_section.internal_name,
                                  i_flg_component_type => r_section.flg_component_type);
                
                WHEN r_section.internal_name IN (g_ri_regimen, g_ri_beneficiario, g_ri_precauciones, g_ri_contactado) THEN
                    add_sys_domains(i_ds_cmpt_mkt_rel    => r_section.id_ds_cmpt_mkt_rel,
                                    i_ds_component       => r_section.id_ds_component,
                                    i_internal_name      => r_section.internal_name,
                                    i_flg_component_type => r_section.flg_component_type);
                
                WHEN r_section.internal_name = g_rs_type_bed THEN
                    add_type_bed(i_ds_cmpt_mkt_rel    => r_section.id_ds_cmpt_mkt_rel,
                                 i_ds_component       => r_section.id_ds_component,
                                 i_internal_name      => r_section.internal_name,
                                 i_flg_component_type => r_section.flg_component_type);
                WHEN r_section.internal_name = g_ri_loc_nurse_cons THEN
                    add_loc_nurse(i_ds_cmpt_mkt_rel    => r_section.id_ds_cmpt_mkt_rel,
                                  i_ds_component       => r_section.id_ds_component,
                                  i_internal_name      => r_section.internal_name,
                                  i_flg_component_type => r_section.flg_component_type);
                WHEN r_section.internal_name = g_ri_mix_room THEN
                    add_mix_room(i_ds_cmpt_mkt_rel    => r_section.id_ds_cmpt_mkt_rel,
                                 i_ds_component       => r_section.id_ds_component,
                                 i_internal_name      => r_section.internal_name,
                                 i_flg_component_type => r_section.flg_component_type);
                WHEN r_section.internal_name IN (g_ri_need_nurse_cons,
                                                 g_rs_sur_need,
                                                 g_rs_uci,
                                                 'RS_UCI_POS',
                                                 'RI_COMPULSORY',
                                                 g_rv_request,
                                                 g_rs_global_anesth,
                                                 g_rs_local_anesth) THEN
                    add_nurse_intake(i_ds_cmpt_mkt_rel    => r_section.id_ds_cmpt_mkt_rel,
                                     i_ds_component       => r_section.id_ds_component,
                                     i_internal_name      => r_section.internal_name,
                                     i_flg_component_type => r_section.flg_component_type);
                WHEN r_section.internal_name IN
                     (g_rs_spec_surgery, g_rs_ext_spec, 'RS_CLIN_SERVICE', 'RS_DEPARTMENT', 'RI_PROF_SPECIALITY') THEN
                    add_spec_surgery(i_ds_cmpt_mkt_rel    => r_section.id_ds_cmpt_mkt_rel,
                                     i_ds_component       => r_section.id_ds_component,
                                     i_internal_name      => r_section.internal_name,
                                     i_flg_component_type => r_section.flg_component_type);
                WHEN r_section.internal_name = g_rs_pref_surg THEN
                    add_surgeons(i_ds_cmpt_mkt_rel    => r_section.id_ds_cmpt_mkt_rel,
                                 i_ds_component       => r_section.id_ds_component,
                                 i_internal_name      => r_section.internal_name,
                                 i_flg_component_type => r_section.flg_component_type);
                WHEN r_section.internal_name = g_rs_pref_time THEN
                    add_pref_time(i_ds_cmpt_mkt_rel    => r_section.id_ds_cmpt_mkt_rel,
                                  i_ds_component       => r_section.id_ds_component,
                                  i_internal_name      => r_section.internal_name,
                                  i_flg_component_type => r_section.flg_component_type);
                WHEN r_section.internal_name = g_rs_mot_pref_time THEN
                    add_mot_pref_time(i_ds_cmpt_mkt_rel    => r_section.id_ds_cmpt_mkt_rel,
                                      i_ds_component       => r_section.id_ds_component,
                                      i_internal_name      => r_section.internal_name,
                                      i_flg_component_type => r_section.flg_component_type);
                WHEN r_section.internal_name = g_rsp_lvl_urg THEN
                    add_lvl_urg(i_ds_cmpt_mkt_rel    => r_section.id_ds_cmpt_mkt_rel,
                                i_ds_component       => r_section.id_ds_component,
                                i_internal_name      => r_section.internal_name,
                                i_flg_component_type => r_section.flg_component_type);
                WHEN r_section.internal_name IN (g_ri_durantion, g_rsp_time_min) THEN
                    add_unit_measure_ri(i_ds_cmpt_mkt_rel    => r_section.id_ds_cmpt_mkt_rel,
                                        i_ds_component       => r_section.id_ds_component,
                                        i_internal_name      => r_section.internal_name,
                                        i_flg_component_type => r_section.flg_component_type);
                WHEN r_section.internal_name LIKE 'RIP_DURATION%' THEN
                    add_unit_measure_rs(i_ds_cmpt_mkt_rel    => r_section.id_ds_cmpt_mkt_rel,
                                        i_ds_component       => r_section.id_ds_component,
                                        i_internal_name      => r_section.internal_name,
                                        i_flg_component_type => r_section.flg_component_type);
                WHEN r_section.internal_name = g_rs_prev_duration THEN
                    add_unit_measure_rs(i_ds_cmpt_mkt_rel    => r_section.id_ds_cmpt_mkt_rel,
                                        i_ds_component       => r_section.id_ds_component,
                                        i_internal_name      => r_section.internal_name,
                                        i_flg_component_type => r_section.flg_component_type);
                WHEN r_section.internal_name = 'RC_TYPE' THEN
                    add_cosign_order_type(i_ds_cmpt_mkt_rel    => r_section.id_ds_cmpt_mkt_rel,
                                          i_ds_component       => r_section.id_ds_component,
                                          i_internal_name      => r_section.internal_name,
                                          i_flg_component_type => r_section.flg_component_type);
                WHEN r_section.internal_name = 'RC_BY' THEN
                    add_cosign_prof_list(i_ds_cmpt_mkt_rel    => r_section.id_ds_cmpt_mkt_rel,
                                         i_ds_component       => r_section.id_ds_component,
                                         i_internal_name      => r_section.internal_name,
                                         i_flg_component_type => r_section.flg_component_type);
                WHEN r_section.internal_name = g_rs_notes_p THEN
                    -- EMR-2497
                    add_sample_text(i_intern_name_sample_text_type => g_disc_adm_fe_notes_st, io_section => r_section);
                WHEN r_section.internal_name = g_ri_notes THEN
                    -- EMR-2497
                    add_sample_text(i_intern_name_sample_text_type => g_disc_adm_fe_notes_st, io_section => r_section);
                WHEN r_section.internal_name = g_rs_notes THEN
                    -- EMR-2497
                    add_sample_text(i_intern_name_sample_text_type => g_disc_fe_notes_st, io_section => r_section);
                ELSE
                    --add_sample_text(i_intern_name_sample_text_type => pk_edis_triage.g_sample_text_entourage,
                    --                io_section                     => r_section);
                    NULL; -- EMR-2497
            END CASE;
        
            l_final_tbl_sections.extend();
            l_final_tbl_sections(l_final_tbl_sections.count) := r_section;
        
            g_error := 'CALL ADD_DEF_EVENTS';
        
            IF NOT add_def_events(i_lang            => i_lang,
                             i_ds_cmpt_mkt_rel => r_section.id_ds_cmpt_mkt_rel,
                             i_internal_name   => r_section.internal_name,
                             i_edt_mode        => (CASE
                                                      WHEN i_waiting_list IS NULL THEN
                                                       pk_alert_constant.g_no
                                                      ELSE
                                                       pk_alert_constant.g_yes
                                                  END),
                             i_has_surgery     => nvl(l_need_surgery, l_i_need_surgery),
                             i_has_lvl_urg     => l_has_lvl_urg,
                             i_inst_location   => nvl(i_inst_location, l_id_dest_inst),
                             i_adm_indication  => l_id_adm_indication,
                             i_spec_surgery    => nvl(i_dep_clin_serv_surg, l_surg_spec_id),
                             i_flg_nit         => l_flg_nit,
                             i_has_unav        => l_has_unav,
                             io_tbl_def_events => l_tbl_def_events,
                             o_error           => o_error)
            THEN
                RAISE l_exception;
            END IF;
        
            IF i_waiting_list IS NOT NULL
            THEN
                add_values(i_idx_section => l_final_tbl_sections.count, i_internal_name => r_section.internal_name);
            ELSE
                add_default_values(i_idx_section   => l_final_tbl_sections.count,
                                   i_internal_name => r_section.internal_name);
            END IF;
        
        END LOOP;
    
        SELECT t_rec_ds_sections(id_ds_cmpt_mkt_rel     => a.id_ds_cmpt_mkt_rel,
                                 id_ds_component_parent => a.id_ds_component_parent,
                                 id_ds_component        => a.id_ds_component,
                                 component_desc         => a.component_desc,
                                 internal_name          => a.internal_name,
                                 flg_component_type     => a.flg_component_type,
                                 flg_data_type          => a.flg_data_type,
                                 slg_internal_name      => a.slg_internal_name,
                                 addit_info_xml_value   => a.addit_info_xml_value,
                                 rank                   => a.rank,
                                 max_len                => a.max_len,
                                 min_value              => a.min_value,
                                 max_value              => a.max_value,
                                 gender                 => a.gender,
                                 age_min_value          => a.age_min_value,
                                 age_min_unit_measure   => a.age_min_unit_measure,
                                 age_max_value          => a.age_max_value,
                                 age_max_unit_measure   => a.age_max_unit_measure,
                                 component_values       => a.component_values)
          BULK COLLECT
          INTO l_section
          FROM (SELECT b.id_ds_cmpt_mkt_rel,
                       b.id_ds_component_parent,
                       b.id_ds_component,
                       b.component_desc,
                       b.internal_name,
                       b.flg_component_type,
                       b.flg_data_type,
                       b.slg_internal_name,
                       b.addit_info_xml_value,
                       pk_dynamic_screen.get_section_rank(i_tbl_section     => l_final_tbl_sections,
                                                          i_ds_cmpt_mkt_rel => b.id_ds_cmpt_mkt_rel) rank,
                       b.max_len,
                       b.min_value,
                       b.max_value,
                       b.gender,
                       b.age_min_value,
                       b.age_min_unit_measure,
                       b.age_max_value,
                       b.age_max_unit_measure,
                       b.component_values
                  FROM TABLE(l_final_tbl_sections) b) a
         ORDER BY a.rank;
    
        OPEN o_section FOR
            SELECT t.id_ds_cmpt_mkt_rel,
                   t.id_ds_component_parent,
                   t.id_ds_component,
                   t.component_desc,
                   t.internal_name,
                   t.flg_component_type,
                   t.flg_data_type,
                   t.slg_internal_name,
                   t.addit_info_xml_value,
                   t.rank,
                   t.max_len,
                   t.min_value,
                   t.max_value
              FROM TABLE(l_section) t
             WHERE (l_sys_config_hide_doc = pk_alert_constant.g_no OR
                   (l_sys_config_hide_doc = pk_alert_constant.g_yes AND t.internal_name NOT IN ('RS_CONT_DANGER')))
               AND (l_sys_config_hide_uci = pk_alert_constant.g_no OR (l_sys_config_hide_uci = pk_alert_constant.g_yes AND
                   t.internal_name NOT IN ('RS_UCI', 'RS_UCI_POS')))
               AND ((l_flg_compulsory = pk_alert_constant.g_yes AND
                   t.internal_name IN ('RI_COMPULSORY', 'RI_COMPULSORY_REASON')) OR
                   (t.internal_name NOT IN ('RI_COMPULSORY', 'RI_COMPULSORY_REASON')));
    
        IF i_ask_hosp = pk_alert_constant.g_yes
        THEN
            IF i_component_name = g_request_surgery
            THEN
                OPEN o_events FOR
                    SELECT t.*
                      FROM TABLE(l_tbl_events) t
                     WHERE NOT (i_ask_hosp = pk_alert_constant.g_yes AND i_component_name = g_request_surgery);
            
            ELSE
                OPEN o_events FOR
                    SELECT t.*
                      FROM TABLE(l_tbl_events) t
                     INNER JOIN ds_cmpt_mkt_rel a
                        ON a.id_ds_cmpt_mkt_rel = t.target
                     WHERE a.internal_name_parent != g_request_surgery;
            END IF;
        ELSE
        
            IF i_waiting_list IS NOT NULL
               AND i_dep_clin_serv_surg IS NULL
            THEN
                OPEN o_events FOR
                    SELECT DISTINCT t.id_ds_event,
                                    t.origin,
                                    t.value,
                                    t.target,
                                    decode(a.internal_name_child,
                                            'RSP_SUGG_DT_SURG',
                                            decode(t.value,
                                                   NULL,
                                                   flg_event_type,
                                                   CASE
                                                       WHEN l_sys_config_surg_dt_sugg = pk_alert_constant.g_yes THEN
                                                        'M'
                                                       ELSE
                                                        flg_event_type
                                                   END),
                                            flg_event_type) flg_event_type
                      FROM TABLE(l_tbl_events) t
                      JOIN ds_event s
                        ON t.id_ds_event = s.id_ds_event
                      JOIN ds_cmpt_mkt_rel a
                        ON a.id_ds_cmpt_mkt_rel = t.target
                     WHERE i_order_set = pk_alert_constant.g_no
                       AND (l_sys_config_hide_doc = pk_alert_constant.g_no OR
                           (l_sys_config_hide_doc = pk_alert_constant.g_yes AND
                           t.target NOT IN (SELECT id_ds_cmpt_mkt_rel
                                                FROM ds_cmpt_mkt_rel cc
                                               WHERE cc.internal_name_child IN ('RS_CONT_DANGER'))))
                       AND (l_sys_config_hide_uci = pk_alert_constant.g_no OR
                           (l_sys_config_hide_uci = pk_alert_constant.g_yes AND
                           t.target NOT IN
                           (SELECT id_ds_cmpt_mkt_rel
                                FROM ds_cmpt_mkt_rel cc
                               WHERE cc.internal_name_child IN ('RS_UCI', 'RS_UCI_POS'))))
                       AND (l_flg_compulsory = pk_alert_constant.g_yes OR
                           (l_flg_compulsory = pk_alert_constant.g_no AND
                           t.target NOT IN (SELECT id_ds_cmpt_mkt_rel
                                                FROM ds_cmpt_mkt_rel cc
                                               WHERE cc.internal_name_child = 'RI_COMPULSORY')));
                --AND a.internal_name_child != g_rs_proc_surg;
            ELSE
                OPEN o_events FOR
                    SELECT DISTINCT t.id_ds_event,
                                    t.origin,
                                    t.value,
                                    t.target,
                                    decode(a.internal_name_child,
                                            'RSP_SUGG_DT_SURG',
                                            decode(t.value,
                                                   NULL,
                                                   flg_event_type,
                                                   CASE
                                                       WHEN l_sys_config_surg_dt_sugg = pk_alert_constant.g_yes THEN
                                                        'M'
                                                       ELSE
                                                        flg_event_type
                                                   END),
                                            flg_event_type) flg_event_type
                      FROM TABLE(l_tbl_events) t
                      JOIN ds_cmpt_mkt_rel a
                        ON a.id_ds_cmpt_mkt_rel = t.target
                     WHERE i_order_set = pk_alert_constant.g_no
                       AND (l_sys_config_hide_doc = pk_alert_constant.g_no OR
                           (l_sys_config_hide_doc = pk_alert_constant.g_yes AND
                           t.target NOT IN (SELECT id_ds_cmpt_mkt_rel
                                                FROM ds_cmpt_mkt_rel cc
                                               WHERE cc.internal_name_child IN ('RS_CONT_DANGER'))))
                       AND (l_sys_config_hide_uci = pk_alert_constant.g_no OR
                           (l_sys_config_hide_uci = pk_alert_constant.g_yes AND
                           t.target NOT IN
                           (SELECT id_ds_cmpt_mkt_rel
                                FROM ds_cmpt_mkt_rel cc
                               WHERE cc.internal_name_child IN ('RS_UCI', 'RS_UCI_POS'))))
                       AND (l_flg_compulsory = pk_alert_constant.g_yes OR
                           (l_flg_compulsory = pk_alert_constant.g_no AND
                           t.target NOT IN (SELECT id_ds_cmpt_mkt_rel
                                                FROM ds_cmpt_mkt_rel cc
                                               WHERE cc.internal_name_child = 'RI_COMPULSORY')));
            END IF;
        END IF;
    
        IF i_order_set = pk_alert_constant.g_yes
        THEN
        
            OPEN o_def_events FOR
                SELECT t.id_ds_cmpt_mkt_rel,
                       t.id_def_event,
                       decode(d.internal_name_child,
                              g_ri_reason_admission,
                              pk_dynamic_screen.g_event_mandatory,
                              g_rsp_lvl_urg,
                              pk_dynamic_screen.g_event_mandatory,
                              decode(i_need_surgery,
                                     pk_alert_constant.g_yes,
                                     (decode(d.internal_name_child,
                                             g_rs_proc_surg,
                                             pk_dynamic_screen.g_event_mandatory,
                                             pk_dynamic_screen.g_event_inactive)),
                                     pk_dynamic_screen.g_event_inactive)) flg_event_type
                  FROM TABLE(l_tbl_def_events) t
                 INNER JOIN ds_cmpt_mkt_rel d
                    ON t.id_ds_cmpt_mkt_rel = d.id_ds_cmpt_mkt_rel;
        
        ELSE
        
            OPEN o_def_events FOR
                SELECT t.id_ds_cmpt_mkt_rel,
                       t.id_def_event,
                       decode(t.id_ds_cmpt_mkt_rel,
                              818,
                              decode(i_ask_hosp,
                                     pk_alert_constant.g_yes,
                                     pk_dynamic_screen.g_event_active,
                                     t.flg_event_type),
                              t.flg_event_type) flg_event_type
                  FROM TABLE(l_tbl_def_events) t
                 WHERE NOT (i_ask_hosp = pk_alert_constant.g_yes AND i_component_name = g_request_surgery);
        END IF;
    
        --o_items_values - This cursor has all multichoice options for all triage form multichoice fields
        --               - And has all vital sign detail info
        OPEN o_items_values FOR
            SELECT *
              FROM TABLE(l_tbl_items_values)
             WHERE NOT (i_ask_hosp = pk_alert_constant.g_yes AND i_component_name = g_request_surgery);
    
        FOR r_section IN (SELECT t.id_ds_cmpt_mkt_rel, t.internal_name, t.flg_data_type, t.component_values
                            FROM TABLE(l_final_tbl_sections) t)
        LOOP
            IF r_section.component_values.count = 1
            THEN
                FOR r_value IN (SELECT t.id_ds_cmpt_mkt_rel, t.item_desc, t.item_value, t.item_alt_value
                                  FROM TABLE(r_section.component_values) t)
                LOOP
                    SELECT xmlconcat(l_xml_data,
                                     xmlagg(xmlelement("COMPONENT_LEAF",
                                                       xmlattributes(a.id_ds_cmpt_mkt_rel,
                                                                     a.internal_name,
                                                                     a.desc_value,
                                                                     a.value,
                                                                     a.alt_value)))) data_val
                      INTO l_xml_data
                      FROM (SELECT r_value.id_ds_cmpt_mkt_rel AS id_ds_cmpt_mkt_rel,
                                   r_section.internal_name    AS internal_name,
                                   r_value.item_desc          AS desc_value,
                                   r_value.item_value         AS VALUE,
                                   r_value.item_alt_value     AS alt_value
                              FROM dual
                             WHERE r_value.item_desc IS NOT NULL
                                OR r_value.item_value IS NOT NULL
                                OR r_value.item_alt_value IS NOT NULL) a;
                END LOOP;
            ELSIF r_section.component_values.count > 1
            THEN
                SELECT xmlconcat(l_xml_data,
                                 xmlagg(xmlelement("COMPONENT_LEAF",
                                                   xmlattributes(c.id_ds_cmpt_mkt_rel AS "ID_DS_CMPT_MKT_REL",
                                                                 c.internal_name AS "INTERNAL_NAME"), --
                                                   (SELECT xmlagg(xmlelement("SELECTED_ITEM",
                                                                             xmlattributes(d.item_desc AS "DESC_VALUE",
                                                                                           d.item_value AS "VALUE",
                                                                                           d.item_alt_value AS "ALT_VALUE")))
                                                      FROM TABLE(r_section.component_values) d
                                                     WHERE d.item_desc IS NOT NULL
                                                        OR d.item_value IS NOT NULL
                                                        OR d.item_alt_value IS NOT NULL))))
                  INTO l_xml_data
                  FROM (SELECT r_section.id_ds_cmpt_mkt_rel AS id_ds_cmpt_mkt_rel,
                               r_section.internal_name      AS internal_name
                          FROM dual) c;
            END IF;
        END LOOP;
    
        IF l_xml_data IS NOT NULL
        THEN
            --o_data_val - Has all the default triage form fields values
            SELECT xmlelement("COMPONENTS", l_xml_data).getclobval()
              INTO o_data_val
              FROM dual;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => l_dbg_msg,
                                              i_owner    => 'ALERT',
                                              i_package  => 'PK_ADMISSION_REQUEST',
                                              i_function => 'GET_SECTION_DATA',
                                              o_error    => o_error);
        
            pk_types.open_my_cursor(i_cursor => o_section);
            pk_types.open_my_cursor(i_cursor => o_def_events);
            pk_types.open_my_cursor(i_cursor => o_events);
            pk_types.open_my_cursor(i_cursor => o_items_values);
            o_data_val := NULL;
            RETURN FALSE;
        
    END get_section_data;

    FUNCTION get_task_instructions
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_task_request IN adm_request.id_adm_request%TYPE,
        o_task_instr   OUT VARCHAR2,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_lvl_urg         VARCHAR2(500 CHAR);
        tbl_sr_proc_value table_varchar;
    BEGIN
    
        -- GET LEVEL URG
        BEGIN
            SELECT b.desc_wtl_urg_level
              INTO l_lvl_urg
              FROM waiting_list a
              JOIN wtl_urg_level b
                ON a.id_wtl_urg_level = b.id_wtl_urg_level
             WHERE a.id_waiting_list = i_task_request;
        EXCEPTION
            WHEN no_data_found THEN
                RETURN FALSE;
        END;
    
        SELECT pk_translation.get_translation(i_lang => i_lang, i_code_mess => i.code_intervention)
          BULK COLLECT
          INTO tbl_sr_proc_value
          FROM waiting_list a
          JOIN wtl_epis we
            ON a.id_waiting_list = we.id_waiting_list
          JOIN sr_epis_interv sei
            ON sei.id_episode_context = we.id_episode
          JOIN intervention i
            ON i.id_intervention = sei.id_sr_intervention
         WHERE a.id_waiting_list = i_task_request
           AND we.id_epis_type = pk_alert_constant.g_epis_type_operating;
    
        o_task_instr := get_adm_indication_desc(i_lang => i_lang, i_prof => i_prof, i_id_waiting_list => i_task_request) ||
                        ' ; ' || l_lvl_urg || ' ; ' || pk_utils.to_string(tbl_sr_proc_value);
    
        /*BEGIN
            SELECT ai.desc_adm_indication
             INTO o_task_instr
             FROM waiting_list a 
             JOIN wtl_epis we on a.id_waiting_list = we.id_waiting_list
             JOIN adm_request ar on ar.id_dest_episode = we.id_episode
             JOIN adm_indication ai
               ON ai.id_adm_indication = ar.id_adm_indication
            WHERE a.id_waiting_list =  i_task_request;
        EXCEPTION WHEN NO_DATA_FOUND THEN
            o_task_instr := 'Nelson';
          END;*/
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => 'GET_TASK_INSTRUCTIONS',
                                              i_owner    => 'ALERT',
                                              i_package  => 'PK_ADMISSION_REQUEST',
                                              i_function => 'GET_TASK_INSTRUCTIONS',
                                              o_error    => o_error);
        
            RETURN FALSE;
    END get_task_instructions;

    FUNCTION copy_adm_request_wf
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_adm_request IN adm_request.id_adm_request%TYPE,
        i_id_episode     IN adm_request.id_dest_episode%TYPE DEFAULT NULL,
        i_dt_request     IN adm_request.dt_admission%TYPE DEFAULT NULL,
        i_sur_need       IN VARCHAR2,
        o_id_adm_request OUT adm_request.id_adm_request%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_lvl_urg             NUMBER(24);
        tbl_sr_proc_value     table_number;
        l_ri_reason_admission NUMBER(24);
        l_adm_request         adm_request.id_adm_request%TYPE;
        l_msg_error           VARCHAR2(1000 CHAR);
        l_title_error         VARCHAR2(1000 CHAR);
        l_id_episode_sr       episode.id_episode%TYPE;
        l_id_episode_inp      episode.id_episode%TYPE;
        l_id_waiting_list     waiting_list.id_waiting_list%TYPE;
    
    BEGIN
    
        -- GET INPATIET REASON AND l_lvl_urg
        BEGIN
            SELECT ar.id_adm_indication, a.id_wtl_urg_level
              INTO l_ri_reason_admission, l_lvl_urg
              FROM waiting_list a
              JOIN wtl_epis we
                ON a.id_waiting_list = we.id_waiting_list
              JOIN adm_request ar
                ON ar.id_dest_episode = we.id_episode
              JOIN adm_indication ai
                ON ai.id_adm_indication = ar.id_adm_indication
             WHERE a.id_waiting_list = i_id_adm_request;
        EXCEPTION
            WHEN no_data_found THEN
                RETURN FALSE;
        END;
    
        SELECT sei.id_sr_intervention
          BULK COLLECT
          INTO tbl_sr_proc_value
          FROM waiting_list a
          JOIN wtl_epis we
            ON a.id_waiting_list = we.id_waiting_list
          JOIN sr_epis_interv sei
            ON sei.id_episode_context = we.id_episode
         WHERE a.id_waiting_list = i_id_adm_request;
    
        IF NOT pk_wtl_pbl_core.set_adm_surg_request(i_lang                    => i_lang,
                                               i_prof                    => i_prof,
                                               i_id_patient              => NULL,
                                               i_id_episode              => i_id_episode,
                                               io_id_episode_sr          => l_id_episode_sr,
                                               io_id_episode_inp         => l_id_episode_inp,
                                               io_id_waiting_list        => l_id_waiting_list,
                                               i_flg_type                => CASE
                                                                                WHEN i_sur_need = pk_alert_constant.g_yes THEN
                                                                                 'A'
                                                                                ELSE
                                                                                 'B'
                                                                            END,
                                               i_id_wtl_urg_level        => l_lvl_urg,
                                               i_dt_sched_period_start   => NULL,
                                               i_dt_sched_period_end     => NULL,
                                               i_min_inform_time         => NULL,
                                               i_dt_surgery              => NULL,
                                               i_unav_period_start       => table_varchar(NULL), --
                                               i_unav_period_end         => table_varchar(NULL), --
                                               i_pref_surgeons           => table_number(NULL), --
                                               i_external_dcs            => table_number(NULL), --
                                               i_dep_clin_serv_sr        => table_number(NULL),
                                               i_speciality_sr           => table_number(NULL),
                                               i_department_sr           => table_number(NULL),
                                               i_flg_pref_time           => table_varchar(NULL), --
                                               i_reason_pref_time        => table_number(NULL),
                                               i_id_sr_intervention      => tbl_sr_proc_value,
                                               i_flg_principal           => table_varchar(NULL), --
                                               i_codification            => table_number(NULL), --
                                               i_flg_laterality          => table_varchar(NULL), --
                                               i_surgical_site           => table_varchar(NULL),
                                               i_sp_notes                => table_varchar(NULL), --
                                               i_duration                => NULL,
                                               i_icu                     => NULL,
                                               i_icu_pos                 => NULL,
                                               i_notes_surg              => NULL,
                                               i_adm_needed              => 'Y',
                                               i_id_sr_pos_status        => NULL,
                                               i_surg_needed             => NULL,
                                               i_adm_indication          => l_ri_reason_admission,
                                               i_dest_inst               => NULL,
                                               i_adm_type                => NULL,
                                               i_department              => NULL,
                                               i_room_type               => NULL,
                                               i_dep_clin_serv_adm       => NULL,
                                               i_pref_room               => NULL,
                                               i_mixed_nursing           => NULL,
                                               i_bed_type                => NULL,
                                               i_dest_prof               => NULL,
                                               i_adm_preparation         => NULL,
                                               i_dt_admission            => NULL,
                                               i_expect_duration         => NULL,
                                               i_notes_adm               => NULL,
                                               i_nit_flg                 => NULL,
                                               i_nit_dt_suggested        => NULL,
                                               i_nit_dcs                 => NULL,
                                               i_external_request        => NULL,
                                               i_func_eval_score         => NULL,
                                               i_notes_edit              => NULL,
                                               i_prof_cat_type           => 'D',
                                               i_doc_area                => NULL,
                                               i_doc_template            => NULL,
                                               i_epis_documentation      => NULL,
                                               i_doc_flg_type            => NULL,
                                               i_id_documentation        => NULL,
                                               i_id_doc_element          => NULL,
                                               i_id_doc_element_crit     => NULL,
                                               i_value                   => NULL,
                                               i_notes                   => NULL,
                                               i_id_doc_element_qualif   => NULL,
                                               i_epis_context            => NULL,
                                               i_summary_and_notes       => NULL,
                                               i_wtl_change              => 'N',
                                               i_profs_alert             => NULL,
                                               i_sr_pos_schedule         => NULL,
                                               i_dt_pos_suggested        => NULL,
                                               i_pos_req_notes           => NULL,
                                               i_decision_notes          => NULL,
                                               i_supply                  => NULL,
                                               i_supply_set              => NULL,
                                               i_supply_qty              => NULL,
                                               i_supply_loc              => NULL,
                                               i_dt_return               => NULL,
                                               i_supply_soft_inst        => NULL,
                                               i_flg_cons_type           => NULL,
                                               i_description_sp          => table_varchar(NULL),
                                               i_id_sr_epis_interv       => table_number(NULL),
                                               i_id_req_reason           => table_table_number(NULL),
                                               i_supply_notes            => table_table_varchar(NULL),
                                               i_surgery_record          => table_number(NULL),
                                               i_prof_team               => table_number(NULL),
                                               i_tbl_prof                => table_table_number(table_number(NULL)),
                                               i_tbl_catg                => table_table_number(table_number(NULL)),
                                               i_tbl_status              => table_table_varchar(table_varchar(NULL)),
                                               i_test                    => NULL,
                                               i_diagnosis_adm_req       => NULL,
                                               i_diagnosis_surg_proc     => NULL,
                                               i_diagnosis_contam        => NULL,
                                               i_id_cdr_call             => NULL,
                                               i_id_ct_io                => table_table_varchar(NULL),
                                               i_regimen                 => NULL,
                                               i_beneficiario            => NULL,
                                               i_precauciones            => NULL,
                                               i_contactado              => NULL,
                                               i_clinical_question       => NULL,
                                               i_response                => NULL,
                                               i_clinical_question_notes => NULL,
                                               i_id_inst_dest            => NULL,
                                               i_order_set               => 'Y',
                                               o_adm_request             => l_adm_request,
                                               o_msg_error               => l_msg_error,
                                               o_title_error             => l_title_error,
                                               o_error                   => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        o_id_adm_request := l_id_waiting_list;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => 'COPY_ADM_REQUEST_WF',
                                              i_owner    => 'ALERT',
                                              i_package  => 'PK_ADMISSION_REQUEST',
                                              i_function => 'COPY_ADM_REQUEST_WF',
                                              o_error    => o_error);
        
            RETURN FALSE;
    END copy_adm_request_wf;

    FUNCTION cancel_predefined_task
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_task_request IN table_number,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_exception EXCEPTION;
    BEGIN
    
        FOR i IN 1 .. i_task_request.count
        LOOP
            IF NOT pk_wtl_api_ui.cancel_wtlist(i_lang             => i_lang,
                                               i_prof             => i_prof,
                                               i_wtl_id           => i_task_request(i),
                                               i_id_cancel_reason => NULL,
                                               i_notes_cancel     => NULL,
                                               o_error            => o_error)
            THEN
                RAISE l_exception;
            END IF;
        END LOOP;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => 'CANCEL_PREDEFINED_TASK',
                                              i_owner    => 'ALERT',
                                              i_package  => 'PK_ADMISSION_REQUEST',
                                              i_function => 'CANCEL_PREDEFINED_TASK',
                                              o_error    => o_error);
        
            RETURN FALSE;
    END cancel_predefined_task;

    FUNCTION get_reason_admission_ft RETURN NUMBER IS
    BEGIN
        RETURN g_reason_admission_ft;
    END get_reason_admission_ft;

    FUNCTION get_adm_req_description
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_adm_request  IN adm_request.id_adm_request%TYPE,
        i_co_sign_hist IN co_sign_hist.id_co_sign_hist%TYPE
    ) RETURN CLOB IS
        l_ret CLOB;
    BEGIN
    
        l_ret := get_description(i_lang        => i_lang,
                                 i_prof        => i_prof,
                                 i_adm_request => i_adm_request,
                                 i_desc_type   => NULL);
    
        RETURN l_ret;
    EXCEPTION
        WHEN OTHERS THEN
            NULL;
    END get_adm_req_description;

    FUNCTION get_adm_req_instructions
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_adm_request  IN adm_request.id_adm_request%TYPE,
        i_co_sign_hist IN co_sign_hist.id_co_sign_hist%TYPE
    ) RETURN CLOB IS
        l_ret          CLOB;
        l_waiting_list waiting_list.id_waiting_list%TYPE;
        l_task_instr   VARCHAR2(1000 CHAR);
        l_error        t_error_out;
        l_exception EXCEPTION;
    BEGIN
    
        SELECT b.id_waiting_list
          INTO l_waiting_list
          FROM adm_request a
          JOIN wtl_epis b
            ON a.id_dest_episode = b.id_episode
         WHERE a.id_adm_request = i_adm_request;
    
        IF NOT get_task_instructions(i_lang         => i_lang,
                                     i_prof         => i_prof,
                                     i_task_request => l_waiting_list,
                                     o_task_instr   => l_task_instr,
                                     o_error        => l_error)
        THEN
            RAISE l_exception;
        END IF;
    
        IF l_task_instr IS NOT NULL
        THEN
            l_ret := to_clob(l_task_instr);
        ELSE
            l_ret := NULL;
        END IF;
    
        RETURN l_ret;
    EXCEPTION
        WHEN OTHERS THEN
            NULL;
    END get_adm_req_instructions;

    FUNCTION get_adm_req_action_desc
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_adm_request  IN adm_request.id_adm_request%TYPE,
        i_action       IN co_sign.id_action%TYPE,
        i_co_sign_hist IN co_sign_hist.id_co_sign_hist%TYPE
    ) RETURN VARCHAR2 IS
    
        l_msg_cosign_action_order  sys_message.desc_message%TYPE := pk_message.get_message(i_lang, 'COMMON_M146');
        l_msg_cosign_action_cancel sys_message.desc_message%TYPE := pk_message.get_message(i_lang, 'COMMON_M147');
        l_msg_action               sys_message.desc_message%TYPE;
    
    BEGIN
        SELECT CASE
                   WHEN ar.id_co_sign_cancel = i_co_sign_hist THEN
                    l_msg_cosign_action_cancel
                   ELSE
                    l_msg_cosign_action_order
               END
          INTO l_msg_action
          FROM adm_request ar
         WHERE ar.id_adm_request = i_adm_request;
    
        RETURN l_msg_action;
    EXCEPTION
        WHEN OTHERS THEN
            NULL;
    END get_adm_req_action_desc;

    FUNCTION get_adm_req_date_to_order
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_adm_request  IN adm_request.id_adm_request%TYPE,
        i_co_sign_hist IN co_sign_hist.id_co_sign_hist%TYPE
    ) RETURN TIMESTAMP
        WITH LOCAL TIME ZONE IS
        l_ret TIMESTAMP WITH LOCAL TIME ZONE;
    BEGIN
    
        SELECT ar.dt_admission
          INTO l_ret
          FROM adm_request ar
         WHERE ar.id_adm_request = i_adm_request;
    
        RETURN l_ret;
    EXCEPTION
        WHEN OTHERS THEN
            NULL;
    END get_adm_req_date_to_order;

    FUNCTION get_duration_desc
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_value IN adm_request.expected_duration%TYPE --Hours
    ) RETURN VARCHAR2 IS
    
        l_hours NUMBER := 0;
        l_days  NUMBER := 0;
        l_weeks NUMBER := 0;
        l_aux   NUMBER := 0;
        l_ret   VARCHAR2(100);
    
        FUNCTION get_hour_label(i_hour IN NUMBER) RETURN VARCHAR IS
        BEGIN
            IF i_hour <= 1
            THEN
                RETURN pk_message.get_message(i_lang => i_lang, i_code_mess => 'COMMON_M122');
            ELSE
                RETURN pk_message.get_message(i_lang => i_lang, i_code_mess => 'COMMON_M123');
            END IF;
        END get_hour_label;
    
        FUNCTION get_day_label(i_day IN NUMBER) RETURN VARCHAR IS
        BEGIN
            IF i_day <= 1
            THEN
                RETURN pk_message.get_message(i_lang => i_lang, i_code_mess => 'COMMON_M092');
            ELSE
                RETURN pk_message.get_message(i_lang => i_lang, i_code_mess => 'COMMON_M093');
            END IF;
        END get_day_label;
    
        FUNCTION get_week_label(i_week IN NUMBER) RETURN VARCHAR IS
        BEGIN
            IF i_week <= 1
            THEN
                RETURN pk_message.get_message(i_lang => i_lang, i_code_mess => 'COMMON_M120');
            ELSE
                RETURN pk_message.get_message(i_lang => i_lang, i_code_mess => 'COMMON_M121');
            END IF;
        END get_week_label;
    
    BEGIN
    
        IF i_value IS NULL
        THEN
            RETURN NULL;
        END IF;
    
        IF i_value <= 1
        THEN
            l_ret := i_value || ' ' || pk_message.get_message(i_lang => i_lang, i_code_mess => 'COMMON_M122');
        ELSIF i_value <= 23
        THEN
            l_ret := i_value || ' ' || pk_message.get_message(i_lang => i_lang, i_code_mess => 'COMMON_M123');
        
        ELSIF i_value <= 167
        THEN
            SELECT MOD(i_value, 24)
              INTO l_hours
              FROM dual;
        
            SELECT floor((i_value / 24))
              INTO l_days
              FROM dual;
        
            IF l_hours > 0
            THEN
                l_ret := l_days || ' ' || get_day_label(l_days) || ' ' || l_hours || ' ' || get_hour_label(l_hours);
            ELSE
                l_ret := l_days || ' ' || get_day_label(l_days);
            END IF;
        ELSE
            SELECT floor((i_value / 168))
              INTO l_weeks
              FROM dual;
        
            SELECT MOD(i_value, 168)
              INTO l_aux
              FROM dual;
        
            SELECT MOD(l_aux, 24)
              INTO l_hours
              FROM dual;
        
            SELECT floor((l_aux / 24))
              INTO l_days
              FROM dual;
        
            IF l_weeks > 0
            THEN
                l_ret := l_weeks || ' ' || get_week_label(l_weeks);
            END IF;
        
            IF l_days > 0
            THEN
                l_ret := l_ret || ' ' || l_days || ' ' || get_day_label(l_days);
            END IF;
        
            IF l_hours > 0
            THEN
                l_ret := l_ret || ' ' || l_hours || ' ' || get_hour_label(l_hours);
            END IF;
        END IF;
    
        RETURN l_ret;
    END;

    FUNCTION inactivate_inpatient_admission
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_inst        IN institution.id_institution%TYPE,
        i_ids_exclude IN OUT table_number,
        o_has_error   OUT BOOLEAN,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_cancel_cfg sys_config.value%TYPE := pk_sysconfig.get_config(i_code_cf => 'INACTIVATE_CANCEL_REASON',
                                                                      i_prof    => i_prof);
    
        l_cancel_id cancel_reason.id_cancel_reason%TYPE := pk_cancel_reason.get_id_by_content(i_lang,
                                                                                              i_prof,
                                                                                              l_cancel_cfg);
    
        l_tbl_config t_tbl_config_table := pk_core_config.get_values_by_mkt_inst_sw(i_lang => NULL,
                                                                                    i_prof => profissional(0, i_inst, 0),
                                                                                    i_area => 'INPATIENT_INACTIVATE');
    
        l_max_rows sys_config.value%TYPE := pk_sysconfig.get_config(i_prof    => i_prof,
                                                                    i_code_cf => 'INACTIVATE_TASKS_MAX_NUMBER_ROWS');
    
        l_send_cancel_event sys_config.value%TYPE := nvl(pk_sysconfig.get_config(i_prof    => i_prof,
                                                                                 i_code_cf => 'SEND_CANCEL_EVENT'),
                                                         pk_alert_constant.g_yes);
    
        l_tbl_episode      table_number;
        l_tbl_waiting_list table_number;
        l_final_status     table_varchar;
        l_opinion_hist     opinion_hist.id_opinion_hist%TYPE;
    
        l_error t_error_out;
        g_other_exception EXCEPTION;
    
        l_tbl_error_ids table_number := table_number();
    
        --The cursor will not fetch the records for the ids (id_waiting_list) sent in i_ids_exclude    
        CURSOR c_inp_adm(ids_exclude IN table_number) IS
            SELECT e.id_episode, we.id_waiting_list, cfg.field_04 final_status
              FROM episode e
             INNER JOIN epis_info ei
                ON ei.id_episode = e.id_episode
             INNER JOIN institution i
                ON i.id_institution = e.id_institution
              LEFT JOIN discharge dc
                ON dc.id_episode = e.id_episode
               AND dc.flg_status = pk_discharge.g_disch_flg_status_active
             INNER JOIN wtl_epis we --To fetch only non-urgent requests
                ON we.id_episode = e.id_episode
             INNER JOIN waiting_list wl
                ON wl.id_waiting_list = we.id_waiting_list
             INNER JOIN (SELECT /*+opt_estimate(table t rows=1)*/
                          *
                           FROM TABLE(l_tbl_config) t) cfg
                ON cfg.field_01 = e.flg_status
              LEFT JOIN (SELECT /*+opt_estimate(table t rows=1)*/
                          t.column_value
                           FROM TABLE(i_ids_exclude) t) t_ids
                ON t_ids.column_value = we.id_waiting_list
             WHERE e.id_epis_type = pk_alert_constant.g_epis_type_inpatient
               AND e.flg_type != pk_episode.g_flg_temp
               AND e.flg_status NOT IN
                   (pk_alert_constant.g_epis_status_cancel, pk_alert_constant.g_epis_status_inactive)
               AND e.id_institution = i_inst
               AND pk_date_utils.trunc_insttimezone(i_prof      => i_prof,
                                                    i_timestamp => (pk_date_utils.add_to_ltstz(i_timestamp => coalesce(wl.dt_dpb,
                                                                                                                       e.dt_begin_tstz),
                                                                                               i_amount    => cfg.field_02,
                                                                                               i_unit      => cfg.field_03))) <=
                   pk_date_utils.trunc_insttimezone(i_prof => i_prof, i_timestamp => current_timestamp)
                  --Don't cancel the scheduled episodes      
               AND (ei.id_schedule IS NULL OR ei.id_schedule = -1)
               AND (we.id_schedule IS NULL OR we.id_schedule = -1)
               AND (wl.flg_status NOT IN (pk_wtl_prv_core.g_wtlist_status_partial,
                                          pk_wtl_prv_core.g_wtlist_status_schedule,
                                          pk_wtl_prv_core.g_wtlist_status_cancelled) OR wl.flg_status IS NULL)
               AND t_ids.column_value IS NULL
               AND rownum <= l_max_rows;
    
    BEGIN
    
        OPEN c_inp_adm(i_ids_exclude);
        FETCH c_inp_adm BULK COLLECT
            INTO l_tbl_episode, l_tbl_waiting_list, l_final_status;
        CLOSE c_inp_adm;
    
        o_has_error := FALSE;
    
        IF l_tbl_episode.count > 0
        THEN
            FOR i IN l_tbl_episode.first .. l_tbl_episode.last
            LOOP
                IF l_final_status(i) = 'C'
                THEN
                    IF l_tbl_waiting_list(i) IS NOT NULL
                    THEN
                        SAVEPOINT init_cancel;
                        IF NOT pk_wtl_api_ui.cancel_wtlist(i_lang             => i_lang,
                                                           i_prof             => i_prof,
                                                           i_wtl_id           => l_tbl_waiting_list(i),
                                                           i_id_cancel_reason => l_cancel_id,
                                                           i_notes_cancel     => NULL,
                                                           o_error            => l_error)
                        THEN
                            CONTINUE;
                        END IF;
                    
                        ROLLBACK TO init_cancel;
                    
                        --If, for the given id_nurse_tea_req, an error is generated, o_has_error is set as TRUE,
                        --this way, the loop cicle may continue, but the system will know that at least one error has happened
                        o_has_error := TRUE;
                    
                        --A log for the id_nurse_tea_req that raised the error must be generated 
                        pk_alert_exceptions.reset_error_state;
                        g_error := 'ERROR CALLING PK_WTL_API_UI.CANCEL_WTLIST FOR RECORD ' || l_tbl_waiting_list(i);
                        pk_alert_exceptions.process_error(i_lang,
                                                          SQLCODE,
                                                          SQLERRM,
                                                          g_error,
                                                          'ALERT',
                                                          'PK_ADMISSION_REQUEST',
                                                          'INACTIVATE_INPATIENT_ADMISSION',
                                                          o_error);
                    
                        --The array for the ids (id_exam_req_det) that raised the error is incremented
                        l_tbl_error_ids.extend();
                        l_tbl_error_ids(l_tbl_error_ids.count) := l_tbl_waiting_list(i);
                    
                        CONTINUE;
                    END IF;
                END IF;
            END LOOP;
        
            --When the number of error ids match the max number of rows that can be processed for each call,
            --it means that no id_waiting_list has been inactivated.
            --The next time the Job would be executed, the cursor would fetch the same set fetched on the previous call,
            --and therefore, from this point on, no more records would be inactivated.
            IF l_tbl_error_ids.count = l_max_rows
            THEN
                FOR i IN l_tbl_error_ids.first .. l_tbl_error_ids.last
                LOOP
                    --i_ids_exclude is an IN OUT parameter, and is incremented with the ids (id_waiting_list) that could not
                    --be inactivated with the current call of the function
                    i_ids_exclude.extend();
                    i_ids_exclude(i_ids_exclude.count) := l_tbl_error_ids(i);
                END LOOP;
            
                --Since no inactivations were performed with the current call, a new call to this function is performed,
                --however, this time, the array i_ids_exclude will include a list of ids that cannot be fetched by the cursor
                --on the next call. The recursion will be perfomed until at least one record is inactivated, or the cursor
                --has no more records to fetch.
                --Note: i_ids_exclude is incremented and is an IN OUT parameter, therefore, 
                --it will hold all the ids that were not inactivated from ALL calls.            
                IF NOT pk_admission_request.inactivate_inpatient_admission(i_lang        => i_lang,
                                                                           i_prof        => i_prof,
                                                                           i_inst        => i_inst,
                                                                           i_ids_exclude => i_ids_exclude,
                                                                           o_has_error   => o_has_error,
                                                                           o_error       => o_error)
                THEN
                    RAISE g_other_exception;
                END IF;
            END IF;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              l_error.err_desc,
                                              'ALERT',
                                              'PK_ADMISSION_REQUEST',
                                              'INACTIVATE_INPATIENT_ADMISSION',
                                              l_error);
            RETURN FALSE;
    END inactivate_inpatient_admission;

END pk_admission_request;
/
