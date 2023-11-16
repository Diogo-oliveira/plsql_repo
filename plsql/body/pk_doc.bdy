/*-- Last Change Revision: $Rev: 2053992 $*/
/*-- Last Change by: $Author: ana.matos $*/
/*-- Date of last change: $Date: 2023-01-03 10:39:58 +0000 (ter, 03 jan 2023) $*/

CREATE OR REPLACE PACKAGE BODY pk_doc IS
    g_exception EXCEPTION;
    g_detail    t_coll_screen_detail := t_coll_screen_detail();

    FUNCTION get_id_group(i_doc_external IN doc_external.id_doc_external%TYPE) RETURN NUMBER IS
        l_id_grupo doc_external.id_grupo%TYPE;
    BEGIN
        SELECT nvl(id_grupo, de.id_doc_external)
          INTO l_id_grupo
          FROM doc_external de
         WHERE de.id_doc_external = i_doc_external;
    
        RETURN l_id_grupo;
    END get_id_group;

    FUNCTION is_first_version(i_doc_external IN doc_external.id_doc_external%TYPE) RETURN VARCHAR2 IS
        l_id_group doc_external.id_grupo%TYPE;
        l_result   VARCHAR2(1);
    BEGIN
        l_id_group := get_id_group(i_doc_external);
        IF i_doc_external = l_id_group
        THEN
            l_result := g_yes;
        ELSE
            l_result := g_no;
        END IF;
    
        RETURN l_result;
    END is_first_version;

    FUNCTION get_doc_oid
    (
        i_prof   IN profissional,
        i_id_doc IN doc_external.id_doc_external%TYPE
    ) RETURN VARCHAR2 IS
        l_doc_oid  doc_external.doc_oid%TYPE;
        l_id_group doc_external.id_grupo%TYPE;
    BEGIN
        l_id_group := get_id_group(i_id_doc);
    
        SELECT nvl(de.doc_oid, pk_utils.create_oid(i_prof, 'ALERT_OID_HIE_DOC_EXTERNAL', l_id_group))
          INTO l_doc_oid
          FROM doc_external de
         WHERE de.id_doc_external = l_id_group;
    
        RETURN l_doc_oid;
    END get_doc_oid;

    FUNCTION get_epis_report_by_doc_ext(i_doc_external IN doc_external.id_doc_external%TYPE) RETURN NUMBER IS
        CURSOR c_epis_rep IS
            SELECT id_epis_report
              FROM epis_report er
             WHERE er.id_doc_external = i_doc_external;
    
        l_epis_rep epis_report.id_epis_report%TYPE;
    BEGIN
    
        OPEN c_epis_rep;
        FETCH c_epis_rep
            INTO l_epis_rep;
        CLOSE c_epis_rep;
    
        RETURN l_epis_rep;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_epis_report_by_doc_ext;

    FUNCTION get_default_original
    (
        i_lang  IN NUMBER,
        i_prof  IN profissional,
        o_dest  OUT doc_original.id_doc_original%TYPE,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
        CURSOR c_doc_orig IS
            SELECT id_doc_original
              FROM doc_original do
             WHERE do.flg_other = g_yes;
    BEGIN
    
        OPEN c_doc_orig;
        FETCH c_doc_orig
            INTO o_dest;
        CLOSE c_doc_orig;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                --Inicialization of object for input 
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                o_dest := NULL;
                -- setting language, setting error content into input object, setting package information 
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   g_package_owner,
                                   g_package_name,
                                   'GET_DEFAULT_ORIGINAL');
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
                RETURN FALSE;
            END;
    END get_default_original;

    /**
    * Gets professional profile_template
    * Assumes that there's only ibe profile_template for user/software/institution.
    * 
    * @param   i_lang language associated to the professional executing the request
    * @param   i_prof professional, institution and software ids
    * @param   o_pt an error message, set when return=false
    * @param   o_error an error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  João Sá
    * @version 2.0
    * @since   28-09-2007
    */
    FUNCTION get_profile_template
    (
        i_lang  IN NUMBER,
        i_prof  IN profissional,
        o_pt    OUT profile_template.id_profile_template%TYPE,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
        CURSOR c_pt IS
            SELECT ppt.id_profile_template
              FROM prof_profile_template ppt, profile_template pt
             WHERE ppt.id_professional = i_prof.id
               AND ppt.id_software = i_prof.software
               AND ppt.id_institution = i_prof.institution
               AND pt.id_profile_template = ppt.id_profile_template
               AND pt.id_software = ppt.id_software;
    BEGIN
    
        g_error := 'OPEN o_pt';
        OPEN c_pt;
        FETCH c_pt
            INTO o_pt;
        CLOSE c_pt;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                --Inicialization of object for input 
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                -- setting language, setting error content into input object, setting package information 
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   g_package_owner,
                                   g_package_name,
                                   'GET_PROFILE_TEMPLATE');
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
                RETURN FALSE;
            END;
    END get_profile_template;

    /**
    * INTERNAL USE ONLY
    *
    * @return true (sucess), false (error)    
    * @created 01.10.2009
    * @author BM
    * @version 1.0
    */
    FUNCTION set_doc
    (
        i_lang            IN NUMBER,
        i_id_institution  IN NUMBER,
        i_id_doc          IN NUMBER,
        i_id_professional IN NUMBER,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_market PLS_INTEGER;
    BEGIN
    
        SELECT id_market
          INTO l_market
          FROM institution
         WHERE id_institution = i_id_institution;
    
        IF pk_adt.is_core_market(i_lang => i_lang, i_market => l_market, o_error => o_error)
        THEN
            INSERT INTO doc_external_us
                (id_doc_external_us)
            VALUES
                (i_id_doc);
        
            INSERT INTO doc_external_us_hist
                (id_doc_external_us_hist, id_doc_external_us, operation_type, operation_time, operation_user)
            VALUES
                (seq_doc_external_us_hist.nextval * 10000000, i_id_doc, 'C', current_timestamp, i_id_professional);
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'set_doc',
                                              o_error);
            --pk_utils.undo_changes;
            RETURN FALSE;
    END set_doc;

    /**
    * Gets value from doc_config
    * 
    * @param   i_code_cf doc_config code
    * @param   i_prof professional, institution and software ids
    * @param   i_pt profile_template id
    * @param   i_btn sys_button id
    *
    * @RETURN  
    * @author  João Sá
    * @version 2.0
    * @since   28-09-2007
    */
    FUNCTION get_config
    (
        i_code_cf IN VARCHAR2,
        i_prof    IN profissional,
        i_pt      IN profile_template.id_profile_template%TYPE,
        i_btn     IN sys_button_prop.id_sys_button_prop%TYPE
    ) RETURN VARCHAR2 IS
        CURSOR c IS
            SELECT VALUE
              FROM doc_config dc
             WHERE dc.code_doc_config = i_code_cf
               AND dc.id_software IN (i_prof.software, 0)
               AND dc.id_institution IN (i_prof.institution, 0)
               AND dc.id_profile_template IN (i_pt, 0)
               AND dc.id_sys_button_prop IN (i_btn, 0)
             ORDER BY id_software DESC, id_institution DESC, id_profile_template DESC, id_sys_button_prop DESC;
    
        l_msg doc_config.value%TYPE;
    BEGIN
        OPEN c;
        FETCH c
            INTO l_msg;
        CLOSE c;
    
        RETURN l_msg;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_config;

    /**
    * Gets value from doc_types_config
    * 
    * @param   i_doc_type id doc_type (can be null) 
    * @param   i_doc_ori_type id doc_ori_type (can be null)
    * @param   i_doc_original id doc_original (can be null)
    * @param   i_prof professional, institution and software ids
    * @param   i_pt proile template id
    * @param   i_btn sys_button area id
    *
    * @RETURN  TRUE if sucess, FALSE otherwise 
    * @author  João Sá
    * @version 2.0
    * @since   28-09-2007
    */
    FUNCTION get_types_config
    (
        i_doc_type        IN doc_type.id_doc_type%TYPE,
        i_doc_ori_type    IN doc_ori_type.id_doc_ori_type%TYPE,
        i_doc_original    IN doc_original.id_doc_original%TYPE,
        i_doc_destination IN doc_destination.id_doc_destination%TYPE,
        i_prof            IN profissional,
        i_pt              IN profile_template.id_profile_template%TYPE,
        i_btn             IN sys_button_prop.id_sys_button_prop%TYPE,
        o_row             OUT doc_types_config%ROWTYPE
    ) RETURN BOOLEAN IS
    
        l_val_doc_config doc_config.value%TYPE;
    
        CURSOR c IS
            SELECT *
              FROM doc_types_config dtc
             WHERE nvl(dtc.id_doc_type, 0) = nvl(i_doc_type, 0)
               AND nvl(dtc.id_doc_ori_type, 0) = nvl(i_doc_ori_type, 0)
               AND nvl(dtc.id_doc_original, 0) = nvl(i_doc_original, 0)
               AND nvl(dtc.id_doc_destination, 0) = nvl(i_doc_destination, 0)
               AND dtc.id_software IN (i_prof.software, 0)
               AND dtc.id_institution IN (i_prof.institution, 0)
               AND dtc.id_profile_template IN (i_pt, 0)
               AND ((dtc.id_sys_button_prop IN (i_btn, 0) AND l_val_doc_config = g_no) OR
                    (dtc.id_sys_button_prop = i_btn AND l_val_doc_config = g_yes))
             ORDER BY id_software DESC, id_institution DESC, id_profile_template DESC, id_sys_button_prop DESC;
    
    BEGIN
    
        l_val_doc_config := nvl(pk_doc.get_config('SEE_ONLY_BTN_DOCS', i_prof, i_pt, i_btn), g_no);
    
        OPEN c;
        FETCH c
            INTO o_row;
        CLOSE c;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN FALSE;
    END get_types_config;

    /**
    * Gets doc_types_config.flg_view for the parameters provided
    * 
    * @param   i_doc_type id doc_type (can be null) 
    * @param   i_doc_ori_type id doc_ori_type (can be null)
    * @param   i_doc_original id doc_original (can be null)
    * @param   i_prof professional, institution and software ids
    * @param   i_pt proile template id
    * @param   i_btn sys_button id
    *
    * @RETURN  TRUE if sucess, FALSE otherwise 
    * @author  João Sá
    * @version 2.0
    * @since   28-09-2007
    */
    FUNCTION get_types_config_visible
    (
        i_doc_type        IN doc_type.id_doc_type%TYPE,
        i_doc_ori_type    IN doc_ori_type.id_doc_ori_type%TYPE,
        i_doc_original    IN doc_original.id_doc_original%TYPE,
        i_doc_destination IN doc_destination.id_doc_destination%TYPE,
        i_prof            IN profissional,
        i_pt              IN profile_template.id_profile_template%TYPE,
        i_btn             IN sys_button_prop.id_sys_button_prop%TYPE
    ) RETURN VARCHAR2 IS
        l_ret BOOLEAN;
        l_row doc_types_config%ROWTYPE;
    
    BEGIN
    
        l_ret := get_types_config(i_doc_type,
                                  i_doc_ori_type,
                                  i_doc_original,
                                  i_doc_destination,
                                  i_prof,
                                  i_pt,
                                  i_btn,
                                  l_row);
    
        IF l_ret
        THEN
            RETURN(nvl(l_row.flg_view, g_doc_config_n));
        END IF;
    
        RETURN g_doc_config_n;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN g_doc_config_n;
        
    END get_types_config_visible;

    /**
    * Gets doc_types_config.flg_other for the parameters provided
    * 
    * @param   i_doc_type id doc_type (can be null) 
    * @param   i_doc_ori_type id doc_ori_type (can be null)
    * @param   i_doc_original id doc_original (can be null)
    * @param   i_prof professional, institution and software ids
    * @param   i_pt proile template id
    * @param   i_btn sys_button id
    *
    * @RETURN  TRUE if sucess, FALSE otherwise 
    * @author  João Sá
    * @version 2.0
    * @since   28-09-2007
    */
    FUNCTION get_types_config_other
    (
        i_doc_type        IN doc_type.id_doc_type%TYPE,
        i_doc_ori_type    IN doc_ori_type.id_doc_ori_type%TYPE,
        i_doc_original    IN doc_original.id_doc_original%TYPE,
        i_doc_destination IN doc_destination.id_doc_destination%TYPE,
        i_prof            IN profissional,
        i_pt              IN profile_template.id_profile_template%TYPE,
        i_btn             IN sys_button_prop.id_sys_button_prop%TYPE
    ) RETURN VARCHAR2 IS
        l_ret BOOLEAN;
        l_row doc_types_config%ROWTYPE;
    
    BEGIN
    
        l_ret := get_types_config(i_doc_type,
                                  i_doc_ori_type,
                                  i_doc_original,
                                  i_doc_destination,
                                  i_prof,
                                  i_pt,
                                  i_btn,
                                  l_row);
    
        IF l_ret
        THEN
            RETURN(nvl(l_row.flg_other, g_doc_config_n));
        END IF;
    
        RETURN g_doc_config_n;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN g_doc_config_n;
        
    END get_types_config_other;

    /* Gets doc_types_config.flg_insert for the parameters provided
    * 
    * @param   i_doc_type id doc_type (can be null) 
    * @param   i_doc_ori_type id doc_ori_type (can be null)
    * @param   i_doc_original id doc_original (can be null)
    * @param   i_doc_destination id doc_destination (can be null)    
    * @param   i_prof professional, institution and software ids
    * @param   i_pt profile template id
    * @param   i_btn sys_button_prop id
    *
    * @RETURN  TRUE if sucess, FALSE otherwise 
    * @author  João Sá
    * @version 2.0
    * @since   28-09-2007
    */
    FUNCTION get_types_config_insert
    (
        i_doc_type        IN doc_type.id_doc_type%TYPE,
        i_doc_ori_type    IN doc_ori_type.id_doc_ori_type%TYPE,
        i_doc_original    IN doc_original.id_doc_original%TYPE,
        i_doc_destination IN doc_destination.id_doc_destination%TYPE,
        i_prof            IN profissional,
        i_pt              IN profile_template.id_profile_template%TYPE,
        i_btn             IN sys_button_prop.id_sys_button_prop%TYPE
    ) RETURN VARCHAR2 IS
        l_ret BOOLEAN;
        l_row doc_types_config%ROWTYPE;
    
    BEGIN
    
        l_ret := get_types_config(i_doc_type,
                                  i_doc_ori_type,
                                  i_doc_original,
                                  i_doc_destination,
                                  i_prof,
                                  i_pt,
                                  i_btn,
                                  l_row);
    
        IF l_ret
        THEN
            RETURN(nvl(l_row.flg_insert, g_doc_config_n));
        END IF;
    
        RETURN g_doc_config_n;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN g_doc_config_n;
        
    END get_types_config_insert;

    /**
    * Gets the primary key (id_doc_types_config) of doc_types_config for the parameters provided
    * 
    * @param   i_doc_type id doc_type (can be null) 
    * @param   i_doc_ori_type id doc_ori_type (can be null)
    * @param   i_doc_original id doc_original (can be null)
    * @param   i_doc_destination id doc_destination (can be null)
    * @param   i_prof professional, institution and software ids
    * @param   i_pt profile template id
    * @param   i_btn sys_button id
    *
    * @RETURN  id_doc_types_config
    * @author  Telmo Castro
    * @version 1.0
    * @since   12-12-2007
    */
    FUNCTION get_types_config_id
    (
        i_doc_type        IN doc_type.id_doc_type%TYPE,
        i_doc_ori_type    IN doc_ori_type.id_doc_ori_type%TYPE,
        i_doc_original    IN doc_original.id_doc_original%TYPE,
        i_doc_destination IN doc_destination.id_doc_destination%TYPE,
        i_prof            IN profissional,
        i_pt              IN profile_template.id_profile_template%TYPE,
        i_btn             IN sys_button_prop.id_sys_button_prop%TYPE
    ) RETURN NUMBER IS
        l_ret BOOLEAN;
        l_row doc_types_config%ROWTYPE;
    
    BEGIN
    
        l_ret := get_types_config(i_doc_type,
                                  i_doc_ori_type,
                                  i_doc_original,
                                  i_doc_destination,
                                  i_prof,
                                  i_pt,
                                  i_btn,
                                  l_row);
    
        IF l_ret
        THEN
            RETURN l_row.id_doc_types_config;
        END IF;
    
        RETURN NULL;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_types_config_id;

    /**
    * Returns the doc_ori_type configured for the doc_type
    * 
    * @param   i_doc_type id doc_type (can be null) 
    * @param   i_doc_ori_type id doc_ori_type (can be null)
    * @param   i_doc_original id doc_original (can be null)
    * @param   i_doc_destination id doc_destination (can be null)
    * @param   i_prof professional, institution and software ids
    * @param   i_pt profile template id
    * @param   i_btn sys_button id
    *
    * @RETURN  id_doc_types_config
    * @author  Telmo Castro
    * @version 1.0
    * @since   12-12-2007
    */
    FUNCTION get_types_config_ori_type
    (
        i_doc_type        IN doc_type.id_doc_type%TYPE,
        i_doc_ori_type    IN doc_ori_type.id_doc_ori_type%TYPE,
        i_doc_original    IN doc_original.id_doc_original%TYPE,
        i_doc_destination IN doc_destination.id_doc_destination%TYPE,
        i_prof            IN profissional,
        i_pt              IN profile_template.id_profile_template%TYPE,
        i_btn             IN sys_button_prop.id_sys_button_prop%TYPE
    ) RETURN NUMBER IS
        l_ret BOOLEAN;
        l_row doc_types_config%ROWTYPE;
    
    BEGIN
    
        l_ret := get_types_config(i_doc_type,
                                  i_doc_ori_type,
                                  i_doc_original,
                                  i_doc_destination,
                                  i_prof,
                                  i_pt,
                                  i_btn,
                                  l_row);
    
        IF l_ret
        THEN
            RETURN l_row.id_doc_ori_type_parent;
        END IF;
    
        RETURN NULL;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_types_config_ori_type;

    /**
    * Gets document list
    *
    * @param   I_LANG language associated to the professional executing the request
    * @param   I_PROF  professional, institution and software ids
    * @param   I_PATIENT patient id
    * @param   I_EPISODE episode id
    * @param   I_EXT_REQ external request id
    * @param   I_BTN sys_button used to allow diferent behaviours depending
    *          on the button being used.
    * @param   O_ERROR an error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  João Sá
    * @version 2.0
    * @since   24-11-2006
    */
    FUNCTION get_doc_list
    (
        i_lang    IN NUMBER,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        i_episode IN episode.id_episode%TYPE,
        i_ext_req IN p1_external_request.id_external_request%TYPE,
        i_btn     IN sys_button_prop.id_sys_button_prop%TYPE,
        o_style   OUT VARCHAR2,
        o_docs    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        l_ret        BOOLEAN;
        my_exception EXCEPTION;
    
        text_na VARCHAR2(0050);
        --        l_context VARCHAR2(0020);
    
        l_patient patient.id_patient%TYPE;
        l_episode episode.id_episode%TYPE;
        l_ext_req p1_external_request.id_external_request%TYPE;
    
        l_my_pt profile_template.id_profile_template%TYPE;
        l_error t_error_out;
    BEGIN
    
        g_error := 'GET_CONFIG';
        text_na := pk_message.get_message(i_lang, 'P1_TEXT_NA');
    
        g_error := 'GET PROFILE';
        l_ret   := pk_doc.get_profile_template(i_lang, i_prof, l_my_pt, l_error);
    
        IF NOT l_ret
        THEN
            RAISE my_exception;
        END IF;
    
        -- Validate context (Patient, Episode and External Request)
        SELECT decode(pk_doc.get_config('DOC_PATIENT', i_prof, l_my_pt, i_btn), g_doc_config_y, i_patient, NULL),
               decode(pk_doc.get_config('DOC_EPISODE', i_prof, l_my_pt, i_btn), g_doc_config_y, i_episode, NULL),
               decode(pk_doc.get_config('DOC_REFERRAL', i_prof, l_my_pt, i_btn), g_doc_config_y, i_ext_req, NULL)
          INTO l_patient, l_episode, l_ext_req
          FROM dual;
    
        g_error := 'OPEN O_DOCS';
        OPEN o_docs FOR
            SELECT de.id_doc_external id_doc,
                   decode(de.desc_doc_type,
                          NULL,
                          pk_translation.get_translation(i_lang, dt.code_doc_type),
                          de.desc_doc_type) doc,
                   de.num_doc,
                   nvl(pk_date_utils.dt_chr(i_lang, de.dt_emited, i_prof), text_na) dt_doc,
                   nvl(pk_date_utils.dt_chr(i_lang, de.dt_digit, i_prof), text_na) dt_digit,
                   pk_doc.get_count_image(i_lang, i_prof, de.id_doc_external) img_num,
                   decode(de.desc_doc_ori_type,
                          NULL,
                          pk_translation.get_translation(i_lang, dot.code_doc_ori_type),
                          de.desc_doc_ori_type) ori_type,
                   nvl(pk_doc.get_config('DOC_CAN_RECEIVE', i_prof, l_my_pt, i_btn), g_doc_config_n) can_receive,
                   de.flg_sent_by,
                   pk_sysdomain.get_img(i_lang, 'DOC_EXTERNAL.FLG_RECEIVED', de.flg_received) flg_received_img,
                   de.flg_received
              FROM doc_type dt, doc_external de, doc_ori_type dot
             WHERE (de.id_patient = l_patient AND dt.id_doc_type = de.id_doc_type AND de.flg_status = g_doc_active AND
                   de.id_doc_ori_type = dot.id_doc_ori_type AND
                   get_types_config_visible(dt.id_doc_type, NULL, NULL, NULL, i_prof, l_my_pt, i_btn) = g_doc_config_y AND
                   get_types_config_visible(NULL, dot.id_doc_ori_type, NULL, NULL, i_prof, l_my_pt, i_btn) =
                   g_doc_config_y)
                OR (de.id_episode = l_episode AND dt.id_doc_type = de.id_doc_type AND de.flg_status = g_doc_active AND
                   de.id_doc_ori_type = dot.id_doc_ori_type AND
                   get_types_config_visible(dt.id_doc_type, NULL, NULL, NULL, i_prof, l_my_pt, i_btn) = g_doc_config_y AND
                   get_types_config_visible(NULL, dot.id_doc_ori_type, NULL, NULL, i_prof, l_my_pt, i_btn) =
                   g_doc_config_y)
                OR (de.id_external_request = l_ext_req AND dt.id_doc_type = de.id_doc_type AND
                   de.flg_status = g_doc_active AND de.id_doc_ori_type = dot.id_doc_ori_type AND
                   get_types_config_visible(dt.id_doc_type, NULL, NULL, NULL, i_prof, l_my_pt, i_btn) = g_doc_config_y AND
                   get_types_config_visible(NULL, dot.id_doc_ori_type, NULL, NULL, i_prof, l_my_pt, i_btn) =
                   g_doc_config_y);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN my_exception THEN
            o_error := l_error;
            pk_types.open_my_cursor(o_docs);
            RETURN FALSE;
        WHEN OTHERS THEN
            DECLARE
                --Inicialization of object for input 
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                pk_types.open_my_cursor(o_docs);
            
                -- setting language, setting error content into input object, setting package information 
                l_error_in.set_all(i_lang, SQLCODE, SQLERRM, g_error, g_package_owner, g_package_name, 'GET_DOC_LIST');
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
                RETURN FALSE;
            END;
    END get_doc_list;

    /******************************************************************************
       OBJECTIVO:   Retornar detalhes de documento
       PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional
               I_PROF - Profissional, instituição, software
                   I_DOC  - ID do documento
          Saida: O_DOC_DETAIL  - Cursor com detalhe do dodumento
             O_ERROR       - erro
    
      CRIAÇÃO: JS 2006/03/15
      CORRECÇÕES:
      
      UPDATED - acrescentei colunas ao output, tais como id_prof_perf_by, desc_prof_perf, etc.
     * @author Telmo Castro
     * @date   24-12-2007
     
     UPDATED - Esta função passa a chamar uma outra função com a capacidade de devolver os detalhes de vários documentos
     * @author Jorge Costa
     * @date   10-03-2014
    *********************************************************************************/
    FUNCTION get_doc_detail
    (
        i_lang       IN NUMBER,
        i_prof       IN profissional,
        i_doc        IN NUMBER,
        o_doc_detail OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_error := 'CALL GET_DOC_DETAIL';
        RETURN get_doc_detail(i_lang       => i_lang,
                              i_prof       => i_prof,
                              i_doc_list   => table_number(i_doc),
                              o_doc_detail => o_doc_detail,
                              o_error      => o_error);
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                --Inicialization of object for input 
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                pk_types.open_my_cursor(o_doc_detail);
                -- setting language, setting error content into input object, setting package information 
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   g_package_owner,
                                   g_package_name,
                                   'GET_DOC_DETAIL');
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
                RETURN FALSE;
            END;
            RETURN FALSE;
    END get_doc_detail;

    /******************************************************************************
       OBJECTIVO:   Retornar detalhes de uma lista de documentos
       PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional
               I_PROF - Profissional, instituição, software
                   I_DOC_LIST  - Lista de id's de documentos (recentes ou não)
          Saida: O_DOC_DETAIL  - Cursor com detalhe do dodumento
             O_ERROR       - erro
     * @author Jorge Costa
     * @date   10-03-2014
    *********************************************************************************/
    FUNCTION get_doc_detail
    (
        i_lang       IN NUMBER,
        i_prof       IN profissional,
        i_doc_list   IN table_number,
        o_doc_detail OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_exception EXCEPTION;
    BEGIN
    
        -- Obter detalhes
        g_error := 'OPEN O_DOC_DETAIL';
        OPEN o_doc_detail FOR
            WITH doc_info AS
             (SELECT ode.id_doc_external old_id, nde.id_doc_external new_id, nvl(dc.num_docs, 0) num_notes
                FROM doc_external ode,
                     doc_external nde,
                     (SELECT COUNT(doc.id_doc_external) num_docs, doc.id_doc_external
                        FROM doc_comments doc
                       GROUP BY doc.id_doc_external) dc
               WHERE ode.id_doc_external IN (SELECT column_value
                                               FROM TABLE(i_doc_list))
                 AND dc.id_doc_external(+) = nde.id_doc_external
                 AND ((ode.id_grupo IS NOT NULL AND ode.id_grupo = nde.id_grupo AND
                     nde.flg_status IN (g_doc_active, g_doc_inactive, g_doc_pendente)) OR
                     (ode.id_doc_external = nde.id_doc_external AND
                     ode.flg_status IN (g_doc_active, g_doc_inactive, g_doc_pendente))))
            
            SELECT de.id_doc_type,
                   decode(de.desc_doc_type,
                          NULL,
                          pk_translation.get_translation(i_lang, dt.code_doc_type),
                          de.desc_doc_type) doc,
                   de.num_doc,
                   de.title,
                   de.id_prof_perf_by,
                   de.desc_perf_by,
                   pk_date_utils.dt_chr(i_lang, de.dt_emited, i_prof) dt_doc,
                   pk_date_utils.date_send(i_lang, de.dt_emited, i_prof) dt_doc_ymd,
                   --
                   pk_date_utils.dt_chr_date_hour(i_lang, de.dt_emited, i_prof) dt_doc_ymd_hhmm,
                   --
                   pk_date_utils.dt_chr(i_lang, de.dt_expire, i_prof) dt_exp,
                   pk_date_utils.date_send(i_lang, de.dt_expire, i_prof) dt_exp_ymd,
                   --
                   pk_date_utils.dt_chr_date_hour(i_lang, de.dt_expire, i_prof) dt_exp_ymd_hhmm,
                   --
                   de.id_doc_destination,
                   decode(de.desc_doc_destination,
                          NULL,
                          pk_translation.get_translation(i_lang, dd.code_doc_destination),
                          de.desc_doc_destination) orig_dest,
                   de.id_doc_ori_type,
                   decode(de.desc_doc_ori_type,
                          NULL,
                          pk_translation.get_translation(i_lang, dot.code_doc_ori_type),
                          de.desc_doc_ori_type) orig_type,
                   --de.notes,
                   pk_doc.get_count_image(i_lang, i_prof, doc_info.new_id) num_img,
                   doc_info.num_notes num_notas,
                   de.flg_sent_by,
                   pk_sysdomain.get_domain('DOC_EXTERNAL.FLG_SENT_BY', de.flg_sent_by, i_lang) desc_sent_by,
                   de.flg_received,
                   pk_sysdomain.get_img(i_lang, 'DOC_EXTERNAL.FLG_RECEIVED', 'N') img_receive_ko,
                   pk_sysdomain.get_img(i_lang, 'DOC_EXTERNAL.FLG_RECEIVED', 'Y') img_receive_ok,
                   de.id_doc_original,
                   decode(de.desc_doc_original,
                          NULL,
                          pk_translation.get_translation(i_lang, do.code_doc_original),
                          de.desc_doc_original) desc_doc_original,
                   --
                   nvl(de.id_grupo, de.id_doc_external) id_folder,
                   de.author,
                   de.id_specialty,
                   pk_translation.get_translation(i_lang, s.code_speciality) desc_specialty,
                   de.id_language,
                   pk_translation.get_translation(i_lang, l.code_language) desc_language,
                   xds.flg_submission_type submission_status,
                   --
                   
                   doc_info.old_id old_document_id,
                   doc_info.new_id new_document_id,
                   get_main_thumb_url(i_lang, i_prof, doc_info.new_id) url_thumb, -- url_thumb,
                   get_main_thumb_mime_type(i_lang, i_prof, doc_info.new_id) mime_type, -- mime_type,
                   get_main_thumb_extension(i_lang, i_prof, doc_info.new_id) format_type, -- format_type,
                   dcm.desc_comment notes
            --
              FROM doc_type        dt,
                   doc_destination dd,
                   doc_ori_type    dot,
                   doc_external    de,
                   doc_original    do,
                   --
                   speciality              s,
                   LANGUAGE                l,
                   xds_document_submission xds,
                   doc_info,
                   doc_comments            dcm
            --
             WHERE de.id_doc_external IN (doc_info.new_id)
               AND dd.id_doc_destination(+) = de.id_doc_destination
               AND dot.id_doc_ori_type = de.id_doc_ori_type
               AND dt.id_doc_type = de.id_doc_type
               AND do.id_doc_original(+) = de.id_doc_original
               AND de.id_doc_external = dcm.id_doc_external(+)
                  --
               AND s.id_speciality(+) = de.id_specialty
               AND de.id_language = l.id_language(+)
               AND nvl(de.id_grupo, de.id_doc_external) = xds.id_doc_external(+)
               AND nvl(xds.flg_status, g_doc_active) = 'A'
            --
            ;
    
        -- log document activity
        g_error := 'Error registering document activity';
        IF NOT pk_doc_activity.log_document_activity(i_lang            => i_lang,
                                                     i_prof            => i_prof,
                                                     i_doc_id          => i_doc_list(1),
                                                     i_operation       => 'VIEW',
                                                     i_source          => 'EHR',
                                                     i_target          => 'EHR',
                                                     i_operation_param => NULL,
                                                     o_error           => o_error)
        THEN
            RAISE l_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                --Inicialization of object for input 
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                pk_types.open_my_cursor(o_doc_detail);
                -- setting language, setting error content into input object, setting package information 
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   g_package_owner,
                                   g_package_name,
                                   'GET_DOC_DETAIL');
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
                RETURN FALSE;
            END;
            RETURN FALSE;
    END get_doc_detail;

    /**
    * dá o detalhe do documento, mas agora na forma de 1 lista com todas as versoes deste documento
    * ordenadas cronologicamente. O primeiro da lista deve estar activo e por isso ser a versao actual.
    * @param i_lang     linguagem pedida
    * @param i_prof     ids do profissional
    * @param i_id_doc   id do documento pretendido
    * @param o_list     lista do resultado
    * @param o_error    error message, if any
    *
    * @return TRUE if sucess, FALSE otherwise 
    * @author  Telmo Castro
    * @version 1.0
    * @date    08-01-2007
    */
    FUNCTION get_doc_details
    (
        i_lang   IN NUMBER,
        i_prof   IN profissional,
        i_id_doc IN NUMBER,
        o_list   OUT pk_types.cursor_type,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_num_img   NUMBER;
        l_num_notas NUMBER;
        l_id_grupo  doc_external.id_grupo%TYPE;
    BEGIN
    
        g_error := 'COUNT IMAGES';
        -- Obter numero de imagens
        l_num_img := get_count_image(i_lang, i_prof, i_id_doc);
    
        -- Obter numero de notas/interpretacoes
        SELECT COUNT(*)
          INTO l_num_notas
          FROM doc_comments dc
         WHERE dc.id_doc_external = i_id_doc
           AND flg_cancel = g_flg_cancel_n;
    
        -- obter id_grupo
        g_error := 'GET ID_GRUPO';
        SELECT nvl(id_grupo, -1)
          INTO l_id_grupo
          FROM doc_external
         WHERE id_doc_external = i_id_doc
           AND flg_status IN (g_doc_active, g_doc_inactive);
    
        -- Obter detalhes
        g_error := 'OPEN O_DOC_DETAIL';
        OPEN o_list FOR
            SELECT de.id_doc_type,
                   decode(de.desc_doc_type,
                          NULL,
                          pk_translation.get_translation(i_lang, dt.code_doc_type),
                          de.desc_doc_type) doc,
                   de.num_doc,
                   de.title,
                   de.id_prof_perf_by,
                   de.desc_perf_by,
                   pk_date_utils.dt_chr(i_lang, de.dt_emited, i_prof) dt_doc,
                   pk_date_utils.date_send(i_lang, de.dt_emited, i_prof) dt_doc_ymd,
                   --
                   pk_date_utils.dt_chr_date_hour(i_lang, de.dt_emited, i_prof) dt_doc_ymd_hhmm,
                   --
                   pk_date_utils.dt_chr(i_lang, de.dt_expire, i_prof) dt_exp,
                   pk_date_utils.date_send(i_lang, de.dt_expire, i_prof) dt_exp_ymd,
                   --
                   pk_date_utils.dt_chr_date_hour(i_lang, de.dt_expire, i_prof) dt_exp_ymd_hhmm,
                   --
                   de.id_doc_destination,
                   decode(de.desc_doc_destination,
                          NULL,
                          pk_translation.get_translation(i_lang, dd.code_doc_destination),
                          de.desc_doc_destination) orig_dest,
                   de.id_doc_ori_type,
                   decode(de.desc_doc_ori_type,
                          NULL,
                          pk_translation.get_translation(i_lang, dot.code_doc_ori_type),
                          de.desc_doc_ori_type) orig_type,
                   l_num_img num_img,
                   l_num_notas num_notas,
                   de.flg_sent_by,
                   pk_sysdomain.get_domain('DOC_EXTERNAL.FLG_SENT_BY', de.flg_sent_by, i_lang) desc_sent_by,
                   de.flg_received,
                   pk_sysdomain.get_domain('DOC_EXTERNAL.FLG_RECEIVED', de.flg_received, i_lang) desc_received,
                   de.id_doc_original,
                   decode(de.desc_doc_original,
                          NULL,
                          pk_translation.get_translation(i_lang, do.code_doc_original),
                          de.desc_doc_original) desc_doc_original,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, p.id_professional) insertby,
                   pk_prof_utils.get_spec_signature(i_lang, i_prof, p.id_professional, de.dt_inserted, de.id_episode) insertspecialty,
                   pk_date_utils.date_char_tsz(i_lang, de.dt_inserted, i_prof.institution, i_prof.software) insertdate,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, p2.id_professional) updatedby,
                   pk_prof_utils.get_spec_signature(i_lang, i_prof, p2.id_professional, de.dt_updated, de.id_episode) updatespecialty,
                   pk_date_utils.date_char_tsz(i_lang, de.dt_updated, i_prof.institution, i_prof.software) updatedate,
                   --
                   de.author,
                   de.id_specialty,
                   pk_translation.get_translation(i_lang, s3.code_speciality) desc_specialty,
                   de.id_language,
                   pk_translation.get_translation(i_lang, l.code_language) desc_language
            --
              FROM doc_type        dt,
                   doc_destination dd,
                   doc_ori_type    dot,
                   doc_external    de,
                   doc_original    do,
                   professional    p,
                   speciality      s,
                   professional    p2,
                   speciality      s2,
                   --
                   speciality s3,
                   LANGUAGE   l
            --
            
             WHERE (de.id_doc_external = i_id_doc OR de.id_grupo = l_id_grupo)
               AND dd.id_doc_destination(+) = de.id_doc_destination
               AND dot.id_doc_ori_type = de.id_doc_ori_type
               AND dt.id_doc_type = de.id_doc_type
               AND do.id_doc_original(+) = de.id_doc_original
               AND de.id_professional = p.id_professional(+)
               AND p.id_speciality = s.id_speciality(+)
               AND de.id_professional_upd = p2.id_professional(+)
               AND p2.id_speciality = s2.id_speciality(+)
                  --
               AND de.id_specialty = s3.id_speciality(+)
               AND de.id_language = l.id_language(+)
            --
             ORDER BY de.flg_status, de.dt_inserted DESC;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                --Inicialization of object for input 
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                pk_types.open_my_cursor(o_list);
                -- setting language, setting error content into input object, setting package information 
                l_error_in.set_all(i_lang, SQLCODE, SQLERRM, g_error, g_package_owner, g_package_name, 'SET_DISCHARGE');
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
                RETURN FALSE;
            END;
        
    END get_doc_details;

    /**
    * UTILIZADA NOS EXAMES dá o detalhe de uma lista de documentos, mas agora na forma de 1 lista com todas as versoes deste documento
    * ordenadas cronologicamente. O primeiro da lista deve estar activo e por isso ser a versao actual.
    * @param i_lang     linguagem pedida
    * @param i_prof     ids do profissional
    * @param i_id_doc   array_de ids
    * @param o_list     lista do resultado
    * @param o_error    error message, if any
    *
    * @return TRUE if sucess, FALSE otherwise 
    * @author  Rita Lopes
    * @version 1.0
    * @date    16-07-2009
    */
    FUNCTION get_doc_details_exam
    (
        i_lang   IN NUMBER,
        i_prof   IN profissional,
        i_id_doc IN table_number,
        o_list   OUT pk_types.cursor_type,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_num_img   NUMBER;
        l_num_notas NUMBER;
        l_id_grupo  table_number;
    BEGIN
    
        g_error := 'COUNT IMAGES';
        -- Obter numero de imagens
        l_num_img := get_count_image_list(i_lang, i_prof, i_id_doc);
    
        -- Obter numero de notas/interpretacoes
        SELECT COUNT(*)
          INTO l_num_notas
          FROM doc_comments dc
         WHERE dc.id_doc_external IN (SELECT column_value
                                        FROM TABLE(i_id_doc))
           AND flg_cancel = g_flg_cancel_n;
    
        -- obter id_grupo
        g_error := 'GET ID_GRUPO';
        SELECT nvl(id_grupo, -1)
          BULK COLLECT
          INTO l_id_grupo
          FROM doc_external
         WHERE id_doc_external IN (SELECT column_value
                                     FROM TABLE(i_id_doc))
           AND flg_status IN (g_doc_active, g_doc_inactive);
    
        -- Obter detalhes
        g_error := 'OPEN O_DOC_DETAIL';
        OPEN o_list FOR
            SELECT de.id_doc_type,
                   decode(de.desc_doc_type,
                          NULL,
                          pk_translation.get_translation(i_lang, dt.code_doc_type),
                          de.desc_doc_type) doc,
                   de.num_doc,
                   de.title,
                   de.id_prof_perf_by,
                   de.desc_perf_by,
                   pk_date_utils.dt_chr(i_lang, de.dt_emited, i_prof) dt_doc,
                   pk_date_utils.date_send(i_lang, de.dt_emited, i_prof) dt_doc_ymd,
                   pk_date_utils.dt_chr(i_lang, de.dt_expire, i_prof) dt_exp,
                   pk_date_utils.date_send(i_lang, de.dt_expire, i_prof) dt_exp_ymd,
                   de.id_doc_destination,
                   decode(de.desc_doc_destination,
                          NULL,
                          pk_translation.get_translation(i_lang, dd.code_doc_destination),
                          de.desc_doc_destination) orig_dest,
                   de.id_doc_ori_type,
                   decode(de.desc_doc_ori_type,
                          NULL,
                          pk_translation.get_translation(i_lang, dot.code_doc_ori_type),
                          de.desc_doc_ori_type) orig_type,
                   l_num_img num_img,
                   l_num_notas num_notas,
                   de.flg_sent_by,
                   pk_sysdomain.get_domain('DOC_EXTERNAL.FLG_SENT_BY', de.flg_sent_by, i_lang) desc_sent_by,
                   de.flg_received,
                   pk_sysdomain.get_domain('DOC_EXTERNAL.FLG_RECEIVED', de.flg_received, i_lang) desc_received,
                   de.id_doc_original,
                   decode(de.desc_doc_original,
                          NULL,
                          pk_translation.get_translation(i_lang, do.code_doc_original),
                          de.desc_doc_original) desc_doc_original,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, p.id_professional) insertby,
                   pk_prof_utils.get_spec_signature(i_lang, i_prof, p.id_professional, de.dt_inserted, de.id_episode) insertspecialty,
                   pk_date_utils.date_char_tsz(i_lang, de.dt_inserted, i_prof.institution, i_prof.software) insertdate,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, p2.id_professional) updatedby,
                   pk_prof_utils.get_spec_signature(i_lang, i_prof, p2.id_professional, de.dt_updated, de.id_episode) updatespecialty,
                   pk_date_utils.date_char_tsz(i_lang, de.dt_updated, i_prof.institution, i_prof.software) updatedate
              FROM doc_type        dt,
                   doc_destination dd,
                   doc_ori_type    dot,
                   doc_external    de,
                   doc_original    do,
                   professional    p,
                   speciality      s,
                   professional    p2,
                   speciality      s2
             WHERE (de.id_doc_external IN (SELECT column_value
                                             FROM TABLE(i_id_doc)) OR
                   de.id_grupo IN (SELECT column_value
                                      FROM TABLE(l_id_grupo)))
               AND dd.id_doc_destination(+) = de.id_doc_destination
               AND dot.id_doc_ori_type = de.id_doc_ori_type
               AND dt.id_doc_type = de.id_doc_type
               AND do.id_doc_original(+) = de.id_doc_original
               AND de.id_professional = p.id_professional(+)
               AND p.id_speciality = s.id_speciality(+)
               AND de.id_professional_upd = p2.id_professional(+)
               AND p2.id_speciality = s2.id_speciality(+)
             ORDER BY de.flg_status, de.dt_inserted DESC;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                --Inicialization of object for input 
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                pk_types.open_my_cursor(o_list);
                -- setting language, setting error content into input object, setting package information 
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   g_package_owner,
                                   g_package_name,
                                   'GET_DOC_DETAILS_EXAM');
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
                RETURN FALSE;
            END;
        
    END get_doc_details_exam;
    /**
    * Gets doc_types list
    * 
    * @param   i_lang language 
    * @param   i_prof professional, institution and software ids
    * @param   i_btn sys_button id
    * @param   o_doc_types list of doc types
    * @param   o_error error message
    *
    * @RETURN  TRUE if sucess, FALSE otherwise 
    * @author  João Sá
    * @version 2.0
    * @since   28-09-2007
    */
    FUNCTION get_doc_types
    (
        i_lang      IN NUMBER,
        i_prof      IN profissional,
        i_patient   IN patient.id_patient%TYPE,
        i_episode   IN episode.id_episode%TYPE,
        i_ext_req   IN p1_external_request.id_external_request%TYPE,
        i_btn       IN sys_button_prop.id_sys_button_prop%TYPE,
        o_doc_types OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
        l_ret        BOOLEAN;
        my_exception EXCEPTION;
        l_my_pt      profile_template.id_profile_template%TYPE;
        l_error      t_error_out;
    BEGIN
    
        g_error := 'Call get_profile_template';
        l_ret   := get_profile_template(i_lang, i_prof, l_my_pt, l_error);
    
        IF NOT l_ret
        THEN
            RAISE my_exception;
        END IF;
    
        g_error := 'OPEN o_doc_types';
        OPEN o_doc_types FOR
        
            SELECT data, label, flg_other, doc_type
              FROM (SELECT dt.id_doc_type data,
                           pk_translation.get_translation(i_lang, dt.code_doc_type) label,
                           get_types_config_other(dt.id_doc_type, NULL, NULL, NULL, i_prof, l_my_pt, i_btn) flg_other,
                           get_types_config_ori_type(dt.id_doc_type, NULL, NULL, NULL, i_prof, l_my_pt, i_btn) doc_type
                      FROM doc_type dt
                     WHERE dt.flg_available = g_doc_type_available_y
                       AND get_types_config_insert(dt.id_doc_type, NULL, NULL, NULL, i_prof, l_my_pt, i_btn) =
                           g_doc_config_y
                       AND is_doc_type_registered(i_lang, i_prof, i_patient, i_episode, i_ext_req, dt.id_doc_type, i_btn) = g_no
                     ORDER BY dt.rank, label)
             WHERE label IS NOT NULL;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN my_exception THEN
            o_error := l_error;
            pk_types.open_my_cursor(o_doc_types);
            RETURN FALSE;
        WHEN OTHERS THEN
            DECLARE
                --Inicialization of object for input 
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                pk_types.open_my_cursor(o_doc_types);
            
                -- setting language, setting error content into input object, setting package information 
                l_error_in.set_all(i_lang, SQLCODE, SQLERRM, g_error, g_package_owner, g_package_name, 'O_DOC_TYPES');
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
                RETURN FALSE;
            END;
    END get_doc_types;

    /**
    * Gets doc_ori_types list - Alterado para se existe parametrizacao especifica para esse software, usar essa
    *  
    * @param   i_lang language 
    * @param   i_prof professional, institution and software ids
    * @param   i_btn sys_button id
    * @param   o_doc_ori_types list of doc_ori_types
    * @param   o_error error message
    *
    * @RETURN  TRUE if sucess, FALSE otherwise 
    * @author  João Sá
    * @version 2.0
    * @since   28-09-2007
    */
    FUNCTION get_doc_original_types
    (
        i_lang          IN NUMBER,
        i_prof          IN profissional,
        i_btn           IN sys_button_prop.id_sys_button_prop%TYPE,
        o_doc_ori_types OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        l_ret        BOOLEAN;
        my_exception EXCEPTION;
        l_my_pt      profile_template.id_profile_template%TYPE;
        l_error      t_error_out;
    
    BEGIN
    
        g_error := 'Call get_profile_template';
        l_ret   := get_profile_template(i_lang, i_prof, l_my_pt, l_error);
    
        IF NOT l_ret
        THEN
            RAISE my_exception;
        END IF;
    
        g_error := 'OPEN o_doc_ori_types';
        OPEN o_doc_ori_types FOR
            SELECT dot.id_doc_ori_type data,
                   pk_translation.get_translation(i_lang, dot.code_doc_ori_type) label,
                   get_types_config_other(NULL, dot.id_doc_ori_type, NULL, NULL, i_prof, l_my_pt, i_btn) flg_other
              FROM doc_ori_type dot
             WHERE dot.flg_available = g_doc_ori_type_available_y
               AND get_types_config_insert(NULL, dot.id_doc_ori_type, NULL, NULL, i_prof, l_my_pt, i_btn) =
                   g_doc_config_y
             ORDER BY dot.rank, label;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN my_exception THEN
            o_error := l_error;
            pk_types.open_my_cursor(o_doc_ori_types);
            RETURN FALSE;
        WHEN OTHERS THEN
            DECLARE
                --Inicialization of object for input 
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                pk_types.open_my_cursor(o_doc_ori_types);
                -- setting language, setting error content into input object, setting package information  
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   g_package_owner,
                                   g_package_name,
                                   'GET_DOC_ORIGINAL_TYPES');
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
                RETURN FALSE;
            END;
    END get_doc_original_types;

    FUNCTION get_doc_type_groups
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_patient          IN patient.id_patient%TYPE,
        i_episode          IN episode.id_episode%TYPE,
        o_doc_types_groups OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
        my_exception EXCEPTION;
        l_error      t_error_out;
    
    BEGIN
    
        g_error := 'OPEN O_DOC_TYPES_GROUPS';
        OPEN o_doc_types_groups FOR
            SELECT DISTINCT dot.id_doc_ori_type,
                            pk_translation.get_translation(i_lang, dot.code_doc_ori_type) doc_type_desc
              FROM doc_ori_type dot
              JOIN doc_external de
                ON (de.id_doc_ori_type = dot.id_doc_ori_type)
             WHERE ((de.id_patient = i_patient) OR (de.id_episode = i_episode))
               AND de.flg_status = g_doc_active
             ORDER BY doc_type_desc;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN my_exception THEN
            o_error := l_error;
            pk_types.open_my_cursor(o_doc_types_groups);
            RETURN FALSE;
        WHEN OTHERS THEN
            DECLARE
                --Inicialization of object for input 
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                pk_types.open_my_cursor(o_doc_types_groups);
                -- setting language, setting error content into input object, setting package information  
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   g_package_owner,
                                   g_package_name,
                                   'GET_DOC_TYPE_GROUPS');
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
                RETURN FALSE;
            END;
    END get_doc_type_groups;

    /**
    * Gets doc_original list
    * 
    * @param   i_lang language 
    * @param   i_prof professional, institution and software ids
    * @param   i_btn sys_button id
    * @param   o_doc_originals list of doc_originals
    * @param   o_error error message
    *
    * @RETURN  TRUE if sucess, FALSE otherwise 
    * @author  João Sá
    * @version 2.0
    * @since   28-09-2007
    */
    FUNCTION get_doc_originals
    (
        i_lang          IN NUMBER,
        i_prof          IN profissional,
        i_btn           IN sys_button_prop.id_sys_button_prop%TYPE,
        o_doc_originals OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        l_ret        BOOLEAN;
        my_exception EXCEPTION;
        l_my_pt      profile_template.id_profile_template%TYPE;
        l_error      t_error_out;
    BEGIN
    
        g_error := 'Call get_profile_template';
        l_ret   := get_profile_template(i_lang, i_prof, l_my_pt, l_error);
    
        IF NOT l_ret
        THEN
            RAISE my_exception;
        END IF;
    
        g_error := 'OPEN o_doc_originals';
        OPEN o_doc_originals FOR
            SELECT do.id_doc_original data,
                   pk_translation.get_translation(i_lang, do.code_doc_original) label,
                   get_types_config_other(NULL, NULL, do.id_doc_original, NULL, i_prof, l_my_pt, i_btn) flg_other
              FROM doc_original do
             WHERE do.flg_available = g_doc_original_available_y
               AND get_types_config_insert(NULL, NULL, do.id_doc_original, NULL, i_prof, l_my_pt, i_btn) =
                   g_doc_config_y
             ORDER BY do.rank, label;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN my_exception THEN
            o_error := l_error;
            pk_types.open_my_cursor(o_doc_originals);
            RETURN FALSE;
        WHEN OTHERS THEN
            DECLARE
                --Inicialization of object for input 
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                pk_types.open_my_cursor(o_doc_originals);
                -- setting language, setting error content into input object, setting package information 
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   g_package_owner,
                                   g_package_name,
                                   'GET_DOC_ORIGINALS');
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
                RETURN FALSE;
            END;
    END get_doc_originals;

    FUNCTION get_doc_originals
    (
        i_lang IN NUMBER,
        i_prof IN profissional,
        i_btn  IN sys_button_prop.id_sys_button_prop%TYPE
    ) RETURN t_tbl_core_domain IS
        l_ret        BOOLEAN;
        l_return     t_tbl_core_domain;
        my_exception EXCEPTION;
        l_my_pt      profile_template.id_profile_template%TYPE;
        l_error      t_error_out;
    
    BEGIN
    
        g_error := 'Call get_profile_template';
        l_ret   := get_profile_template(i_lang, i_prof, l_my_pt, l_error);
    
        IF NOT l_ret
        THEN
            RAISE my_exception;
        END IF;
    
        g_error := 'OPEN L_RETURN';
        SELECT *
          BULK COLLECT
          INTO l_return
          FROM (SELECT t_row_core_domain(internal_name => NULL,
                                         desc_domain   => label,
                                         domain_value  => data,
                                         order_rank    => NULL,
                                         img_name      => NULL)
                  FROM (SELECT do.id_doc_original data,
                               pk_translation.get_translation(i_lang, do.code_doc_original) label
                          FROM doc_original do
                         WHERE do.flg_available = g_doc_original_available_y
                           AND get_types_config_insert(NULL, NULL, do.id_doc_original, NULL, i_prof, l_my_pt, i_btn) =
                               g_doc_config_y
                         ORDER BY do.rank, label));
    
        RETURN l_return;
    
    EXCEPTION
        WHEN my_exception THEN
            RETURN t_tbl_core_domain();
        WHEN OTHERS THEN
            RETURN t_tbl_core_domain();
    END get_doc_originals;

    /**
    * Gets original destinations
    * 
    * @param   i_lang language 
    * @param   i_prof professional, institution and software ids
    * @param   i_btn sys_button id
    * @param   o_doc_dest list of destinations
    * @param   o_error error message
    *
    * @RETURN  TRUE if sucess, FALSE otherwise 
    * @author  João Sá
    * @version 2.0
    * @since   28-09-2007
    */
    FUNCTION get_doc_destinations
    (
        i_lang     IN NUMBER,
        i_prof     IN profissional,
        i_btn      IN sys_button_prop.id_sys_button_prop%TYPE,
        o_doc_dest OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
        l_ret        BOOLEAN;
        my_exception EXCEPTION;
        l_my_pt      profile_template.id_profile_template%TYPE;
        l_error      t_error_out;
    BEGIN
    
        g_error := 'Call get_profile_template';
        l_ret   := get_profile_template(i_lang, i_prof, l_my_pt, l_error);
    
        IF NOT l_ret
        THEN
            RAISE my_exception;
        END IF;
    
        g_error := 'OPEN o_doc_dest';
        OPEN o_doc_dest FOR
            SELECT dd.id_doc_destination data,
                   pk_translation.get_translation(i_lang, dd.code_doc_destination) label,
                   get_types_config_other(NULL, NULL, NULL, dd.id_doc_destination, i_prof, l_my_pt, i_btn) flg_other
              FROM doc_destination dd
             WHERE dd.flg_available = g_doc_destination_available_y
               AND get_types_config_insert(NULL, NULL, NULL, dd.id_doc_destination, i_prof, l_my_pt, i_btn) =
                   g_doc_config_y
             ORDER BY dd.rank, label;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN my_exception THEN
            pk_types.open_my_cursor(o_doc_dest);
            o_error := l_error;
            RETURN FALSE;
        WHEN OTHERS THEN
            DECLARE
                --Inicialization of object for input 
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                pk_types.open_my_cursor(o_doc_dest);
                -- setting language, setting error content into input object, setting package information 
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   g_package_owner,
                                   g_package_name,
                                   'GET_DOC_DESTINATIONS');
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
                RETURN FALSE;
            END;
            RETURN FALSE;
    END get_doc_destinations;

    FUNCTION get_doc_destinations
    (
        i_lang IN NUMBER,
        i_prof IN profissional,
        i_btn  IN sys_button_prop.id_sys_button_prop%TYPE
    ) RETURN t_tbl_core_domain IS
        l_ret        BOOLEAN;
        l_return     t_tbl_core_domain;
        my_exception EXCEPTION;
        l_my_pt      profile_template.id_profile_template%TYPE;
        l_error      t_error_out;
    
    BEGIN
    
        g_error := 'Call get_profile_template';
        l_ret   := get_profile_template(i_lang, i_prof, l_my_pt, l_error);
    
        IF NOT l_ret
        THEN
            RAISE my_exception;
        END IF;
    
        g_error := 'OPEN L_RETURN';
        SELECT *
          BULK COLLECT
          INTO l_return
          FROM (SELECT t_row_core_domain(internal_name => NULL,
                                         desc_domain   => label,
                                         domain_value  => data,
                                         order_rank    => NULL,
                                         img_name      => NULL)
                  FROM (SELECT dd.id_doc_destination data,
                               pk_translation.get_translation(i_lang, dd.code_doc_destination) label
                          FROM doc_destination dd
                         WHERE dd.flg_available = g_doc_destination_available_y
                           AND get_types_config_insert(NULL, NULL, NULL, dd.id_doc_destination, i_prof, l_my_pt, i_btn) =
                               g_doc_config_y
                         ORDER BY dd.rank, label));
    
        RETURN l_return;
    
    EXCEPTION
        WHEN my_exception THEN
            RETURN t_tbl_core_domain();
        WHEN OTHERS THEN
            RETURN t_tbl_core_domain();
    END get_doc_destinations;

    /**
    * Gets doc_ori_types list
    * 
    * @param   i_lang language 
    * @param   i_prof professional, institution and software ids
    * @param   i_btn sys_button id
    * @param   o_doc_types list of doc types
    * @param   o_doc_ori_types list of doc_ori_types    
    * @param   o_doc_originals list of doc_originals    
    * @param   o_doc_dest list of destinations    
    * @param   o_error error message
    *
    * @RETURN  TRUE if sucess, FALSE otherwise 
    * @author  João Sá
    * @version 2.0
    * @since   28-09-2007
    */
    FUNCTION get_doc_options
    (
        i_lang          IN NUMBER,
        i_prof          IN profissional,
        i_patient       IN patient.id_patient%TYPE,
        i_episode       IN episode.id_episode%TYPE,
        i_ext_req       IN p1_external_request.id_external_request%TYPE,
        i_btn           IN sys_button_prop.id_sys_button_prop%TYPE,
        o_doc_types     OUT pk_types.cursor_type,
        o_doc_specs     OUT pk_types.cursor_type,
        o_doc_originals OUT pk_types.cursor_type,
        o_doc_dest      OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        ret         BOOLEAN;
        l_error     t_error_out;
        l_exception EXCEPTION;
    BEGIN
    
        ret := get_doc_original_types(i_lang, i_prof, i_btn, o_doc_types, l_error);
        IF (ret = FALSE)
        THEN
            RAISE l_exception;
        END IF;
    
        ret := get_doc_types(i_lang, i_prof, i_patient, i_episode, i_ext_req, i_btn, o_doc_specs, l_error);
        IF (ret = FALSE)
        THEN
            RAISE l_exception;
        END IF;
    
        ret := get_doc_originals(i_lang, i_prof, i_btn, o_doc_originals, l_error);
        IF (ret = FALSE)
        THEN
            RAISE l_exception;
        END IF;
    
        ret := get_doc_destinations(i_lang, i_prof, i_btn, o_doc_dest, l_error);
        IF (ret = FALSE)
        THEN
            RAISE l_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_exception THEN
            o_error := l_error;
            pk_types.open_my_cursor(o_doc_types);
            pk_types.open_my_cursor(o_doc_specs);
            pk_types.open_my_cursor(o_doc_originals);
            pk_types.open_my_cursor(o_doc_specs);
            RETURN FALSE;
        
        WHEN OTHERS THEN
            DECLARE
                --Inicialization of object for input 
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                pk_types.open_my_cursor(o_doc_types);
                pk_types.open_my_cursor(o_doc_specs);
                pk_types.open_my_cursor(o_doc_originals);
                pk_types.open_my_cursor(o_doc_specs);
            
                -- setting language, setting error content into input object, setting package information 
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   g_package_owner,
                                   g_package_name,
                                   'GET_DOC_OPTIONS');
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
                RETURN FALSE;
            END;
    END get_doc_options;

    /**
    * Gets document id based in the doc_type for the context provided (patient, episode, external_request)
    * If the doc_type can be duplicated the result is allways null.
    *
    * @param i_lang         language id
    * @param i_prof         professional, software and institution ids
    * @param i_id_patient   the patient id
    * @param i_episode      episode id
    * @param i_ext_req      external request id
    * @param i_doc_type     doc type id
    * @param i_btn          is sys_button_prop
    * @param o_doc_external resulting document id
    * @param o_error        error message           
    *
    * @return true (sucess), false (error)
    * @created 24-Oct-2007
    * @author Joao Sa
    *
    * UPDATED - funçao copiada para o pk_doc_internal. Neste package deixou de estar no spec e foi mantida aqui
    * para uso interno
    * @created  Telmo Castro
    * @date     21-12-2007
    */

    FUNCTION get_doc_identific
    (
        i_lang         IN NUMBER,
        i_prof         IN profissional,
        i_patient      IN patient.id_patient%TYPE,
        i_episode      IN episode.id_episode%TYPE,
        i_ext_req      IN p1_external_request.id_external_request%TYPE,
        i_doc_type     IN NUMBER,
        i_btn          IN sys_button_prop.id_sys_button_prop%TYPE,
        o_doc_external OUT doc_external%ROWTYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_ret   BOOLEAN;
        l_my_pt profile_template.id_profile_template%TYPE;
    
        l_patient patient.id_patient%TYPE;
        l_episode episode.id_episode%TYPE;
        l_ext_req p1_external_request.id_external_request%TYPE;
        l_error   t_error_out;
    
        CURSOR c_doc
        (
            x_patient patient.id_patient%TYPE,
            x_episode episode.id_episode%TYPE,
            x_ext_req p1_external_request.id_external_request%TYPE
        ) IS
            SELECT *
              FROM (SELECT de.*
                      FROM doc_external de, doc_type dt
                     WHERE de.id_patient = x_patient
                       AND de.id_doc_type = i_doc_type
                       AND dt.id_doc_type = de.id_doc_type
                       AND dt.flg_duplicate = g_doc_config_n
                       AND de.flg_status = g_doc_active
                    UNION
                    SELECT de.*
                      FROM doc_external de, doc_type dt
                     WHERE de.id_episode = x_episode
                       AND de.id_doc_type = i_doc_type
                       AND dt.id_doc_type = de.id_doc_type
                       AND dt.flg_duplicate = g_doc_config_n
                       AND de.flg_status = g_doc_active
                    UNION
                    SELECT de.*
                      FROM doc_external de, doc_type dt
                     WHERE de.id_external_request = x_ext_req
                       AND de.id_doc_type = i_doc_type
                       AND dt.id_doc_type = de.id_doc_type
                       AND dt.flg_duplicate = g_doc_config_n
                       AND de.flg_status = g_doc_active)
             ORDER BY id_patient, id_episode, id_external_request;
        l_exception_patient EXCEPTION;
    
    BEGIN
        BEGIN
            g_error := 'GET PROFILE';
            l_ret   := get_profile_template(i_lang, i_prof, l_my_pt, l_error);
        
            -- Validate context (Pacient, Episode and External Request)   
            SELECT decode(pk_doc.get_config('DOC_PATIENT', i_prof, l_my_pt, i_btn), g_doc_config_y, i_patient, NULL),
                   decode(pk_doc.get_config('DOC_EPISODE', i_prof, l_my_pt, i_btn), g_doc_config_y, i_episode, NULL),
                   decode(pk_doc.get_config('DOC_REFERRAL', i_prof, l_my_pt, i_btn), g_doc_config_y, i_ext_req, NULL)
              INTO l_patient, l_episode, l_ext_req
              FROM dual;
        
            IF l_patient IS NULL
               AND l_episode IS NULL
               AND l_ext_req IS NULL
            THEN
                RAISE l_exception_patient;
            ELSE
                pk_alertlog.log_debug('l_patient: ' || l_patient || ', l_episode: ' || l_episode || ', l_ext_req: ' ||
                                      l_ext_req || ' i_doc_type: ' || i_doc_type);
            
            END IF;
        
            g_error := 'Open c_doc';
            OPEN c_doc(l_patient, l_episode, l_ext_req);
            FETCH c_doc
                INTO o_doc_external;
            CLOSE c_doc;
        
        EXCEPTION
            WHEN no_data_found THEN
                NULL;
        END;
    
        RETURN TRUE;
    EXCEPTION
        WHEN l_exception_patient THEN
            DECLARE
                --Inicialization of object for input 
                l_error_in   t_error_in := t_error_in();
                l_ret        BOOLEAN;
                l_desc_error VARCHAR2(2000);
            BEGIN
                l_desc_error := 'No parameters DOC_PATIENT, DOC_EPISODE or DOC_REFERRAL defined in DOC_CONFIG for SOFTWARE: ' ||
                                i_prof.software || ', INSTITUTION: ' || i_prof.institution || ', PROFILE_TEMPLATE: ' ||
                                l_my_pt || ' and SYS_BUTTON_PROP: ' || i_btn;
                -- setting language, setting error content into input object, setting package information 
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   l_desc_error,
                                   g_error,
                                   g_package_owner,
                                   g_package_name,
                                   'GET_DOC_IDENTIFIC');
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
                RETURN FALSE;
            END;
        WHEN OTHERS THEN
            DECLARE
                --Inicialization of object for input 
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                -- setting language, setting error content into input object, setting package information 
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   g_package_owner,
                                   g_package_name,
                                   'GET_DOC_IDENTIFIC');
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
                RETURN FALSE;
            END;
    END get_doc_identific;

    /**
    * lista de opçoes para o multi-choice do novo documento
    *
    * @param   i_lang      id da lingua
    * @param   o_val       lista das opcoes
    * @param   o_error     mensagem de erro
    *
    * @RETURN  TRUE sucesso ou FALSE erro
    * @author  Telmo Castro
    * @version 1.0
    * @since   14-12-2007
    */
    FUNCTION get_doc_add
    (
        i_lang  IN language.id_language%TYPE,
        o_val   OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'OPEN CURSOR O_VAL';
        OPEN o_val FOR
            SELECT desc_val, val
              FROM sys_domain
             WHERE code_domain = 'DOCUMENTS.FLG_ADD'
               AND id_language = i_lang
               AND domain_owner = pk_sysdomain.k_default_schema
               AND flg_available = g_yes
             ORDER BY desc_val; --rank;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                --Inicialization of object for input 
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                pk_types.open_my_cursor(o_val);
                -- setting language, setting error content into input object, setting package information 
                l_error_in.set_all(i_lang, SQLCODE, SQLERRM, g_error, g_package_owner, g_package_name, 'GET_DOC_ADD');
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
                RETURN FALSE;
            END;
    END;

    FUNCTION get_doc_in_type_groups
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_patient      IN patient.id_patient%TYPE,
        i_episode      IN episode.id_episode%TYPE,
        i_doc_ori_type IN doc_ori_type.id_doc_ori_type%TYPE,
        o_doc          OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
        my_exception EXCEPTION;
        l_error      t_error_out;
    
    BEGIN
    
        g_error := 'OPEN O_DOC';
        OPEN o_doc FOR
            SELECT id_doc_external,
                   de.title doc_desc,
                   NULL image_name,
                   pk_date_utils.dt_chr(i_lang, de.dt_emited, i_prof) dt_doc,
                   pk_doc.get_main_thumb_url(i_lang, i_prof, de.id_doc_external) image,
                   NULL image_size,
                   pk_doc.get_count_image(i_lang, i_prof, de.id_doc_external) image_num
              FROM doc_external de
             WHERE de.id_doc_ori_type = i_doc_ori_type
               AND ((de.id_patient = i_patient) OR (de.id_episode = i_episode))
               AND de.flg_status = g_doc_active;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN my_exception THEN
            o_error := l_error;
            pk_types.open_my_cursor(o_doc);
            RETURN FALSE;
        WHEN OTHERS THEN
            DECLARE
                --Inicialization of object for input 
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                pk_types.open_my_cursor(o_doc);
                -- setting language, setting error content into input object, setting package information  
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   g_package_owner,
                                   g_package_name,
                                   'GET_DOC_IN_TYPE_GROUPS');
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
                RETURN FALSE;
            END;
    END get_doc_in_type_groups;

    -- lg 2007-fev-03
    /******************************************************************************
       OBJECTIVO:   Inserir documento
       PARAMETROS:  Entrada: I_LANG      - Língua registada como preferência do profissional
                             I_PROF  - Profissional, instituição, software
                             I_CODE  - Id do P1
                             I_DOC_TYPE  - Id da caracterização do documento
                             I_NUM_DOC   - Numero do documento
                             I_DT_DOC  - Data do documento
                             I_ORIG_DEST - Destino do documento original
                             I_ORIG_TYPE - Id do Tipo do documento
                             I_ORIGINAL - Id do tipo de original,
                             I_DESC_ORIGINAL - Descrição manual do tipo de original.
    
                Saida:   O_ERROR   - erro
    
      CRIAÇÃO: JS 2006/03/15
      CORRECÇÕES: LG 2007/fev/03 - adição de novo campo doc_original
      NOTAS:
    *********************************************************************************/
    FUNCTION create_doc
    (
        i_lang              IN NUMBER,
        i_prof              IN profissional,
        i_patient           IN patient.id_patient%TYPE,
        i_episode           IN episode.id_episode%TYPE,
        i_ext_req           IN p1_external_request.id_external_request%TYPE,
        i_doc_type          IN NUMBER,
        i_desc_doc_type     IN VARCHAR2,
        i_num_doc           IN VARCHAR2,
        i_dt_doc            IN DATE,
        i_dt_expire         IN DATE,
        i_orig_dest         IN NUMBER,
        i_desc_ori_dest     IN VARCHAR2,
        i_orig_type         IN NUMBER,
        i_desc_ori_doc_type IN VARCHAR2,
        i_notes             IN VARCHAR2,
        i_sent_by           IN doc_external.flg_sent_by%TYPE,
        i_original          IN NUMBER,
        i_desc_original     IN VARCHAR2,
        i_btn               IN sys_button_prop.id_sys_button_prop%TYPE,
        o_id_doc            OUT NUMBER,
        o_create_doc_msg    OUT VARCHAR2,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        RETURN create_doc(i_lang,
                          i_prof,
                          i_patient,
                          i_episode,
                          i_ext_req,
                          i_doc_type,
                          i_desc_doc_type,
                          i_num_doc,
                          i_dt_doc,
                          i_dt_expire,
                          i_orig_dest,
                          i_desc_ori_dest,
                          i_orig_type,
                          i_desc_ori_doc_type,
                          i_notes,
                          i_sent_by,
                          i_original,
                          i_desc_original,
                          i_btn,
                          --
                          NULL,
                          NULL,
                          NULL,
                          NULL,
                          NULL,
                          NULL,
                          NULL,
                          NULL,
                          NULL,
                          NULL,
                          --
                          o_id_doc,
                          o_create_doc_msg,
                          o_error);
    
    END create_doc;

    FUNCTION create_doc
    (
        i_lang              IN NUMBER,
        i_prof              IN profissional,
        i_patient           IN patient.id_patient%TYPE,
        i_episode           IN episode.id_episode%TYPE,
        i_ext_req           IN p1_external_request.id_external_request%TYPE,
        i_doc_type          IN NUMBER,
        i_desc_doc_type     IN VARCHAR2,
        i_num_doc           IN VARCHAR2,
        i_dt_doc            IN DATE,
        i_dt_expire         IN DATE,
        i_orig_dest         IN NUMBER,
        i_desc_ori_dest     IN VARCHAR2,
        i_orig_type         IN NUMBER,
        i_desc_ori_doc_type IN VARCHAR2,
        i_notes             IN VARCHAR2,
        i_sent_by           IN doc_external.flg_sent_by%TYPE,
        i_original          IN NUMBER,
        i_desc_original     IN VARCHAR2,
        i_btn               IN sys_button_prop.id_sys_button_prop%TYPE,
        --
        i_author             IN doc_external.author%TYPE,
        i_specialty          IN doc_external.id_specialty%TYPE,
        i_doc_language       IN doc_external.id_language%TYPE,
        i_desc_language      IN doc_external.desc_language%TYPE,
        i_flg_publish        IN VARCHAR2,
        i_conf_code          IN table_varchar,
        i_desc_conf_code     IN table_varchar,
        i_code_coding_schema IN table_varchar,
        i_conf_code_set      IN table_varchar,
        i_desc_conf_code_set IN table_varchar,
        --
        o_id_doc         OUT NUMBER,
        o_create_doc_msg OUT VARCHAR2,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_error     t_error_out;
        l_exception EXCEPTION;
    BEGIN
        IF NOT pk_doc.create_doc_internal(i_lang,
                                          i_prof,
                                          i_patient,
                                          i_episode,
                                          i_ext_req,
                                          i_doc_type,
                                          i_desc_doc_type,
                                          i_num_doc,
                                          i_dt_doc,
                                          i_dt_expire,
                                          i_orig_dest,
                                          i_desc_ori_dest,
                                          i_orig_type,
                                          i_desc_ori_doc_type,
                                          i_notes,
                                          i_sent_by,
                                          i_original,
                                          i_desc_original,
                                          i_btn,
                                          --
                                          i_author,
                                          i_specialty,
                                          i_doc_language,
                                          i_desc_language,
                                          i_flg_publish,
                                          i_conf_code,
                                          i_desc_conf_code,
                                          i_code_coding_schema,
                                          i_conf_code_set,
                                          i_desc_conf_code_set,
                                          --
                                          o_id_doc,
                                          o_create_doc_msg,
                                          l_error)
        THEN
            RAISE l_exception;
        END IF;
    
        COMMIT;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'CREATE_DOC',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
    END create_doc;

    /******************************************************************************
       OBJECTIVO:   Inserir documento, sem commit
       PARAMETROS:  Entrada: I_LANG      - Língua registada como preferência do profissional
                             I_PROF  - Profissional, instituição, software
                             I_CODE  - Id do P1
                             I_DOC_TYPE  - Id da caracterização do documento
                             I_NUM_DOC   - Numero do documento
                             I_DT_DOC  - Data do documento
                             I_ORIG_DEST - Destino do documento original
                             I_ORIG_TYPE - Id do Tipo do documento
                             I_ORIGINAL - Id do tipo de original,
                             I_DESC_ORIGINAL - Descrição manual do tipo de original.
    
                Saida:   O_ERROR   - erro
    
      CRIAÇÃO: JS 2006/03/15
      CORRECÇÕES: LG 2007/fev/03 - adição de novo campo doc_original
      NOTAS:
      
      UPDATED - esta e' uma funcao legacy portanto os novos campos title, id_prof_perf_by e desc_perf_by 
      sao inicializados com null. Apenas no media archive, que usa a create_initdoc + create_savedoc 
      eles sao inicializados.
      * @author Telmo Castro
      * @date   24-12-2007
      
      UPDATED - invocacao do pk_visit.set_first_obs
      * @author  Telmo Castro
      * @date   18-01-2008
      
      UPDATED - setup do title quando o doc_ori_type e' do tipo identification. Este tipo e' identificado 
                pela flg_identification
      * @author Telmo Castro
      * @date   23-01-2008
      
      UPDATED - invocacao do pk_visit.set_first_obs so quando ha id do episodio
      * @author Telmo Castro
      * @date   11-03-2008
    *********************************************************************************/
    FUNCTION create_doc_internal
    (
        i_lang              IN NUMBER,
        i_prof              IN profissional,
        i_patient           IN patient.id_patient%TYPE,
        i_episode           IN episode.id_episode%TYPE,
        i_ext_req           IN p1_external_request.id_external_request%TYPE,
        i_doc_type          IN NUMBER,
        i_desc_doc_type     IN VARCHAR2,
        i_num_doc           IN VARCHAR2,
        i_dt_doc            IN DATE,
        i_dt_expire         IN DATE,
        i_orig_dest         IN NUMBER,
        i_desc_ori_dest     IN VARCHAR2,
        i_orig_type         IN NUMBER,
        i_desc_ori_doc_type IN VARCHAR2,
        i_notes             IN VARCHAR2,
        i_sent_by           IN doc_external.flg_sent_by%TYPE,
        i_original          IN NUMBER,
        i_desc_original     IN VARCHAR2,
        i_btn               IN sys_button_prop.id_sys_button_prop%TYPE,
        --
        i_author             IN doc_external.author%TYPE,
        i_specialty          IN doc_external.id_specialty%TYPE,
        i_doc_language       IN doc_external.id_language%TYPE,
        i_desc_language      IN doc_external.desc_language%TYPE,
        i_flg_publish        IN VARCHAR2,
        i_conf_code          IN table_varchar,
        i_desc_conf_code     IN table_varchar,
        i_code_coding_schema IN table_varchar,
        i_conf_code_set      IN table_varchar,
        i_desc_conf_code_set IN table_varchar,
        --
        o_id_doc         OUT NUMBER,
        o_create_doc_msg OUT VARCHAR2,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_ret                  BOOLEAN;
        l_desc_doc_ori_type    doc_external.desc_doc_ori_type%TYPE;
        l_desc_doc_type        doc_external.desc_doc_type%TYPE;
        l_desc_doc_destination doc_external.desc_doc_destination%TYPE;
        l_desc_doc_original    doc_external.desc_doc_original%TYPE;
        l_flg_identification   doc_ori_type.flg_identification%TYPE;
        l_title                doc_external.title%TYPE;
    
        l_my_pt profile_template.id_profile_template%TYPE;
    
        --l_context VARCHAR2(0020);
        l_patient patient.id_patient%TYPE;
        l_episode episode.id_episode%TYPE;
        l_ext_req p1_external_request.id_external_request%TYPE;
    
        l_id_doc    doc_external%ROWTYPE;
        l_exception EXCEPTION;
        l_error     t_error_out;
    
        l_id_doc_external doc_external.id_doc_external%TYPE;
        l_doc_original    doc_original.id_doc_original%TYPE;
    
        l_doc_external_row doc_external%ROWTYPE;
        l_rowids           table_varchar;
    BEGIN
    
        g_error := 'GET PROFILE';
        l_ret   := get_profile_template(i_lang, i_prof, l_my_pt, l_error);
    
        g_error := 'CALL ID_DOC_REGISTERED';
        IF NOT get_doc_identific(i_lang, i_prof, i_patient, i_episode, i_ext_req, i_doc_type, i_btn, l_id_doc, l_error)
        THEN
            RAISE l_exception;
        END IF;
    
        g_error := 'Get default original';
        IF i_original IS NULL
        THEN
            IF NOT get_default_original(i_lang, i_prof, l_doc_original, o_error)
            THEN
                RAISE g_exception;
            END IF;
        ELSE
            l_doc_original := i_original;
        END IF;
    
        IF l_id_doc.id_doc_external IS NOT NULL
        THEN
            -- Se o documento existe e nao pode ser duplicado entao actualiza os dados.
            g_error := 'CALL UPDATE_DOC_INTERNAL';
            RETURN pk_doc.update_doc_internal(i_lang,
                                              i_prof,
                                              l_id_doc.id_doc_external,
                                              i_doc_type,
                                              i_desc_doc_type,
                                              i_num_doc,
                                              i_dt_doc,
                                              i_dt_expire,
                                              i_orig_dest,
                                              i_desc_ori_dest,
                                              i_orig_type,
                                              i_desc_ori_doc_type,
                                              i_notes,
                                              i_sent_by,
                                              l_id_doc.flg_received,
                                              l_doc_original,
                                              i_desc_original,
                                              i_btn,
                                              l_id_doc.title, --os campos novos title, i_prof_perf_by e i_desc_perf_by devem manter o valor actual
                                              l_id_doc.id_prof_perf_by,
                                              l_id_doc.desc_perf_by,
                                              --
                                              i_author,
                                              i_specialty,
                                              i_doc_language,
                                              i_desc_language,
                                              i_flg_publish,
                                              i_conf_code,
                                              i_desc_conf_code,
                                              i_code_coding_schema,
                                              i_conf_code_set,
                                              i_desc_conf_code_set,
                                              NULL,
                                              --
                                              l_id_doc_external,
                                              o_error);
        END IF;
    
        g_error := 'calculate doc_type desc';
        SELECT decode(get_types_config_other(i_doc_type, NULL, NULL, NULL, i_prof, l_my_pt, i_btn),
                      g_doc_config_y,
                      decode(upper(pk_translation.get_translation(i_lang, code_doc_type)),
                             upper(i_desc_doc_type),
                             NULL,
                             i_desc_doc_type),
                      NULL)
          INTO l_desc_doc_type
          FROM doc_type
         WHERE id_doc_type = i_doc_type;
    
        g_error := 'calculate doc_ori_type desc';
        SELECT decode(get_types_config_other(NULL, i_orig_type, NULL, NULL, i_prof, l_my_pt, i_btn),
                      g_doc_config_y,
                      decode(upper(pk_translation.get_translation(i_lang, code_doc_ori_type)),
                             upper(i_desc_ori_doc_type),
                             NULL,
                             i_desc_ori_doc_type),
                      NULL),
               flg_identification
          INTO l_desc_doc_ori_type, l_flg_identification
          FROM doc_ori_type
         WHERE id_doc_ori_type = i_orig_type;
    
        g_error := 'calculate doc_original desc';
        SELECT decode(get_types_config_other(NULL, NULL, l_doc_original, NULL, i_prof, l_my_pt, i_btn),
                      g_doc_config_y,
                      decode(upper(pk_translation.get_translation(i_lang, code_doc_original)),
                             upper(i_desc_original),
                             NULL,
                             i_desc_original),
                      NULL)
          INTO l_desc_doc_original
          FROM doc_original
         WHERE id_doc_original = l_doc_original;
    
        g_error := 'calculate doc_destination desc';
        IF i_orig_dest IS NOT NULL
        THEN
            SELECT decode(get_types_config_other(NULL, NULL, NULL, i_orig_dest, i_prof, l_my_pt, i_btn),
                          g_doc_config_y,
                          decode(upper(pk_translation.get_translation(i_lang, code_doc_destination)),
                                 upper(i_desc_ori_dest),
                                 NULL,
                                 i_desc_ori_dest),
                          NULL)
              INTO l_desc_doc_destination
              FROM doc_destination
             WHERE id_doc_destination = i_orig_dest;
        END IF;
    
        -- Validate context (Patient, Episode and External Request)
        SELECT decode(pk_doc.get_config('DOC_PATIENT', i_prof, l_my_pt, i_btn), g_doc_config_y, i_patient, NULL),
               decode(pk_doc.get_config('DOC_EPISODE', i_prof, l_my_pt, i_btn), g_doc_config_y, i_episode, NULL),
               decode(pk_doc.get_config('DOC_REFERRAL', i_prof, l_my_pt, i_btn), g_doc_config_y, i_ext_req, NULL)
          INTO l_patient, l_episode, l_ext_req
          FROM dual;
    
        -- Telmo Castro 23-01-2008
        -- setup do titulo quando o doc_ori_type é do tipo identification. Fica com a designacao do doc_type recebido 
        -- ou da desc_doc_type se o doc_type for other
        g_error := 'set title';
        IF l_flg_identification = g_doc_ori_type_identific_y
        THEN
            l_title := l_desc_doc_type;
        
            IF l_title IS NULL
            THEN
                SELECT pk_translation.get_translation(i_lang, t.code_doc_type)
                  INTO l_title
                  FROM doc_type t
                 WHERE id_doc_type = i_doc_type;
            END IF;
        END IF;
    
        l_doc_external_row.id_doc_external      := ts_doc_external.next_key();
        l_doc_external_row.id_doc_type          := i_doc_type;
        l_doc_external_row.desc_doc_type        := l_desc_doc_type;
        l_doc_external_row.num_doc              := i_num_doc;
        l_doc_external_row.dt_emited            := i_dt_doc;
        l_doc_external_row.dt_expire            := i_dt_expire;
        l_doc_external_row.notes                := i_notes;
        l_doc_external_row.id_doc_destination   := i_orig_dest;
        l_doc_external_row.desc_doc_destination := l_desc_doc_destination;
        l_doc_external_row.id_doc_ori_type      := i_orig_type;
        l_doc_external_row.desc_doc_ori_type    := l_desc_doc_ori_type;
        l_doc_external_row.id_patient           := l_patient;
        l_doc_external_row.id_episode           := l_episode;
        l_doc_external_row.id_external_request  := l_ext_req;
        l_doc_external_row.flg_status           := g_doc_active;
        l_doc_external_row.flg_sent_by          := i_sent_by;
        l_doc_external_row.id_doc_original      := l_doc_original;
        l_doc_external_row.desc_doc_original    := l_desc_doc_original;
        l_doc_external_row.id_professional      := i_prof.id;
        l_doc_external_row.dt_inserted          := current_timestamp;
        l_doc_external_row.dt_updated           := current_timestamp;
        l_doc_external_row.id_institution       := i_prof.institution;
        l_doc_external_row.id_grupo             := l_doc_external_row.id_doc_external;
        l_doc_external_row.title                := l_title;
        l_doc_external_row.id_specialty         := i_specialty;
        l_doc_external_row.author               := i_author;
    
        o_id_doc := l_doc_external_row.id_doc_external;
        l_rowids := table_varchar();
    
        g_error := 'INSERT DOC_EXTERNAL';
        ts_doc_external.ins(rec_in => l_doc_external_row, handle_error_in => TRUE, rows_out => l_rowids);
    
        g_error := 'Process_insert DOC_EXTERNAL';
        t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'DOC_EXTERNAL',
                                      i_rowids     => l_rowids,
                                      o_error      => o_error);
    
        --is the document to be published (and can be published)
        IF i_flg_publish = g_yes
           AND pk_sysconfig.get_config('HIE_ENABLED', i_prof) = 'Y'
        THEN
            --Call publish_document
            IF NOT pk_hie_xds.set_submit_doc_internal(i_lang,
                                                      i_prof,
                                                      o_id_doc,
                                                      i_conf_code,
                                                      i_desc_conf_code,
                                                      i_code_coding_schema,
                                                      i_conf_code_set,
                                                      i_desc_conf_code_set,
                                                      pk_hie_xds.g_flg_submission_status_n,
                                                      NULL,
                                                      o_error)
            THEN
                RAISE l_exception;
            END IF;
        END IF;
    
        -- pk_visit.set_first_obs; so interessa executar se houver id do episodio
        g_sysdate := current_timestamp;
        IF l_episode IS NOT NULL
           AND NOT pk_visit.set_first_obs(i_lang                => i_lang,
                                          i_id_episode          => l_episode,
                                          i_pat                 => l_patient,
                                          i_prof                => i_prof,
                                          i_prof_cat_type       => NULL,
                                          i_dt_last_interaction => g_sysdate,
                                          i_dt_first_obs        => g_sysdate,
                                          o_error               => l_error)
        THEN
            RAISE l_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_exception THEN
            o_error := l_error;
            pk_utils.undo_changes;
            RETURN FALSE;
        WHEN OTHERS THEN
            DECLARE
                --Inicialization of object for input 
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                -- setting language, setting error content into input object, setting package information 
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   g_package_owner,
                                   g_package_name,
                                   'CREATE_DOC_INTERNAL');
                -- undo changes quando aplicável
                pk_utils.undo_changes;
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
                RETURN FALSE;
            END;
    END create_doc_internal;

    FUNCTION create_document
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_id_episode           IN nurse_tea_req.id_episode%TYPE,
        i_id_patient           IN patient.id_patient%TYPE,
        i_id_doc               IN doc_external.id_doc_external%TYPE,
        i_ext_req              IN doc_external.id_external_request%TYPE,
        i_tbl_ds_internal_name IN table_varchar DEFAULT NULL,
        i_tbl_val              IN table_table_varchar DEFAULT NULL,
        i_tbl_real_val         IN table_table_varchar DEFAULT NULL,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_num_doc           doc_external.num_doc%TYPE;
        l_dt_doc            doc_external.dt_emited%TYPE;
        l_dt_expire         doc_external.dt_expire%TYPE;
        l_dest              doc_external.id_doc_destination%TYPE;
        l_desc_dest         doc_external.desc_doc_destination%TYPE;
        l_ori_doc_type      doc_external.id_doc_ori_type%TYPE;
        l_desc_ori_doc_type doc_external.desc_doc_ori_type%TYPE;
        l_original          doc_external.id_doc_original%TYPE;
        l_desc_original     doc_external.desc_doc_original%TYPE;
        l_title             doc_external.title%TYPE;
        l_desc_perf_by      doc_external.desc_perf_by%TYPE;
        l_author            doc_external.author%TYPE;
        l_specialty         doc_external.id_specialty%TYPE;
        l_doc_language      doc_external.id_language%TYPE;
        l_notes             VARCHAR2(4000 CHAR);
        l_desc_language     VARCHAR2(100 CHAR);
    
    BEGIN
    
        FOR i IN i_tbl_ds_internal_name.first .. i_tbl_ds_internal_name.last
        LOOP
            IF i_tbl_ds_internal_name(i) = 'DS_DOCUMENT_NUMBER'
            THEN
                l_num_doc := i_tbl_real_val(i) (1);
            ELSIF i_tbl_ds_internal_name(i) = 'DS_DT_DOCUMENT'
            THEN
                BEGIN
                    l_dt_doc := to_date(i_tbl_real_val(i) (1), 'yyyymmdd HH24:MI:SS');
                EXCEPTION
                    WHEN OTHERS THEN
                        l_dt_doc := NULL;
                END;
            ELSIF i_tbl_ds_internal_name(i) = 'DS_DT_DOCUMENT_EXPIRE'
            THEN
                BEGIN
                    l_dt_expire := to_date(i_tbl_real_val(i) (1), 'yyyymmdd HH24:MI:SS');
                EXCEPTION
                    WHEN OTHERS THEN
                        l_dt_expire := NULL;
                END;
            ELSIF i_tbl_ds_internal_name(i) = 'DS_ORIGINAL_STAYS_WITH'
            THEN
                l_dest := i_tbl_real_val(i) (1);
            
                IF pk_doc.get_types_config_other(NULL,
                                                 NULL,
                                                 NULL,
                                                 l_dest,
                                                 i_prof,
                                                 pk_prof_utils.get_prof_profile_template(i_prof),
                                                 NULL) = pk_alert_constant.g_no
                THEN
                    l_desc_dest := i_tbl_val(i) (1);
                END IF;
            ELSIF i_tbl_ds_internal_name(i) = 'DS_ORIGINAL_STAYS_WITH_OTHER'
            THEN
                IF i_tbl_val(i) (1) IS NOT NULL
                THEN
                    l_desc_dest := i_tbl_val(i) (1);
                END IF;
            ELSIF i_tbl_ds_internal_name(i) = 'DS_CATEGORY'
            THEN
                l_ori_doc_type      := to_number(i_tbl_real_val(i) (1));
                l_desc_ori_doc_type := i_tbl_val(i) (1);
            ELSIF i_tbl_ds_internal_name(i) = 'DS_ORIGINAL_TYPE'
            THEN
                l_original := i_tbl_real_val(i) (1);
            
                IF pk_doc.get_types_config_other(NULL,
                                                 NULL,
                                                 l_original,
                                                 NULL,
                                                 i_prof,
                                                 pk_prof_utils.get_prof_profile_template(i_prof),
                                                 NULL) = pk_alert_constant.g_no
                THEN
                    l_desc_original := i_tbl_val(i) (1);
                END IF;
            ELSIF i_tbl_ds_internal_name(i) = 'DS_ORIGINAL_OTHER'
            THEN
                IF i_tbl_val(i) (1) IS NOT NULL
                THEN
                    l_desc_original := i_tbl_val(i) (1);
                END IF;
            ELSIF i_tbl_ds_internal_name(i) = 'DS_DOCUMENT_NAME'
            THEN
                l_title := i_tbl_real_val(i) (1);
            ELSIF i_tbl_ds_internal_name(i) = 'DS_PERFORMED_BY'
            THEN
                l_desc_perf_by := i_tbl_real_val(i) (1);
            ELSIF i_tbl_ds_internal_name(i) = 'DS_PROFESSIONAL'
            THEN
                l_author := i_tbl_val(i) (1);
            ELSIF i_tbl_ds_internal_name(i) = 'DS_SPECIALTY'
            THEN
                l_specialty := i_tbl_real_val(i) (1);
            ELSIF i_tbl_ds_internal_name(i) = 'DS_LANGUAGE'
            THEN
                l_doc_language := i_tbl_real_val(i) (1);
            ELSIF i_tbl_ds_internal_name(i) = 'DS_NOTES'
            THEN
                l_notes := i_tbl_real_val(i) (1);
            ELSIF i_tbl_ds_internal_name(i) = 'DS_LANGUAGE_OTHER'
            THEN
                l_desc_language := i_tbl_real_val(i) (1);
            END IF;
        END LOOP;
    
        g_error := 'pk_doc.create_savedoc';
        IF NOT pk_doc.create_savedoc(i_id_doc             => i_id_doc,
                                     i_lang               => i_lang,
                                     i_prof               => i_prof,
                                     i_patient            => i_id_patient,
                                     i_episode            => i_id_episode,
                                     i_ext_req            => i_ext_req,
                                     i_doc_type           => 999, --other
                                     i_desc_doc_type      => NULL,
                                     i_num_doc            => l_num_doc,
                                     i_dt_doc             => l_dt_doc,
                                     i_dt_expire          => l_dt_expire,
                                     i_dest               => l_dest,
                                     i_desc_dest          => l_desc_dest,
                                     i_ori_doc_type       => l_ori_doc_type,
                                     i_desc_ori_doc_type  => l_desc_ori_doc_type,
                                     i_original           => l_original,
                                     i_desc_original      => l_desc_original,
                                     i_btn                => NULL,
                                     i_title              => l_title,
                                     i_flg_sent_by        => NULL,
                                     i_flg_received       => NULL,
                                     i_prof_perf_by       => NULL,
                                     i_desc_perf_by       => l_desc_perf_by,
                                     i_author             => l_author,
                                     i_specialty          => l_specialty,
                                     i_doc_language       => l_doc_language,
                                     i_desc_language      => l_desc_language,
                                     i_flg_publish        => 'N',
                                     i_conf_code          => NULL,
                                     i_desc_conf_code     => NULL,
                                     i_code_coding_schema => NULL,
                                     i_conf_code_set      => NULL,
                                     i_desc_conf_code_set => NULL,
                                     i_local_emitted      => NULL,
                                     i_doc_oid            => get_doc_oid(i_prof, i_id_doc),
                                     i_internal_commit    => TRUE,
                                     i_notes              => l_notes,
                                     o_error              => o_error)
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
                                              g_package_owner,
                                              g_package_name,
                                              'CREATE_DOCUMENT',
                                              o_error);
            RETURN FALSE;
    END create_document;

    FUNCTION update_doc
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_doc             IN NUMBER,
        i_doc_type           IN NUMBER,
        i_desc_doc_type      IN VARCHAR2,
        i_num_doc            IN VARCHAR2,
        i_dt_doc             IN DATE,
        i_dt_expire          IN DATE,
        i_orig_dest          IN NUMBER,
        i_desc_ori_dest      IN VARCHAR2,
        i_orig_type          IN NUMBER,
        i_desc_ori_doc_type  IN VARCHAR2,
        i_notes              IN VARCHAR2,
        i_sent_by            IN doc_external.flg_sent_by%TYPE,
        i_received           IN doc_external.flg_received%TYPE,
        i_original           IN NUMBER,
        i_desc_original      IN VARCHAR2,
        i_btn                IN sys_button_prop.id_sys_button_prop%TYPE,
        i_title              IN doc_external.title%TYPE,
        i_prof_perf_by       IN doc_external.id_prof_perf_by%TYPE,
        i_desc_perf_by       IN doc_external.desc_perf_by%TYPE,
        i_author             IN doc_external.author%TYPE,
        i_specialty          IN doc_external.id_specialty%TYPE,
        i_doc_language       IN doc_external.id_language%TYPE,
        i_desc_language      IN doc_external.desc_language%TYPE,
        i_flg_publish        IN VARCHAR2,
        i_conf_code          IN table_varchar,
        i_desc_conf_code     IN table_varchar,
        i_code_coding_schema IN table_varchar,
        i_conf_code_set      IN table_varchar,
        i_desc_conf_code_set IN table_varchar,
        i_notes_upd          IN VARCHAR2,
        o_id_doc_external    OUT doc_external.id_doc_external%TYPE,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_id_doc_external doc_external.id_doc_external%TYPE;
        l_id_docs         doc_comments.id_doc_comment%TYPE;
        l_exception       EXCEPTION;
    
    BEGIN
    
        BEGIN
            SELECT t.id_doc_comment
              INTO l_id_docs
              FROM (SELECT a.id_doc_comment
                      FROM doc_comments a
                     WHERE a.id_doc_external = i_id_doc
                       AND a.flg_cancel = pk_alert_constant.g_no
                     ORDER BY a.dt_comment DESC) t
             WHERE rownum = 1;
        EXCEPTION
            WHEN OTHERS THEN
                NULL;
        END;
    
        g_error := ' - CALL update_doc_internal';
        IF NOT pk_doc.update_doc_internal(i_lang,
                                          i_prof,
                                          i_id_doc,
                                          i_doc_type,
                                          i_desc_doc_type,
                                          i_num_doc,
                                          i_dt_doc,
                                          i_dt_expire,
                                          i_orig_dest,
                                          i_desc_ori_dest,
                                          i_orig_type,
                                          i_desc_ori_doc_type,
                                          i_notes,
                                          i_sent_by,
                                          i_received,
                                          i_original,
                                          i_desc_original,
                                          i_btn,
                                          i_title,
                                          i_prof_perf_by,
                                          i_desc_perf_by,
                                          i_author,
                                          i_specialty,
                                          i_doc_language,
                                          i_desc_language,
                                          i_flg_publish,
                                          i_conf_code,
                                          i_desc_conf_code,
                                          i_code_coding_schema,
                                          i_conf_code_set,
                                          i_desc_conf_code_set,
                                          i_notes_upd,
                                          l_id_doc_external,
                                          o_error)
        THEN
            pk_utils.undo_changes;
            RETURN FALSE;
        END IF;
    
        IF l_id_docs IS NOT NULL
        THEN
        
            IF NOT pk_doc.cancel_comments(i_lang            => i_lang,
                                          i_prof            => i_prof,
                                          i_id_doc_comments => l_id_docs,
                                          i_type_reg        => NULL,
                                          o_error           => o_error)
            THEN
                RAISE l_exception;
            END IF;
        END IF;
    
        g_error := ' - CALL ts_exam_media_archive.upd';
        ts_exam_media_archive.upd(id_doc_external_in => l_id_doc_external,
                                  where_in           => ' id_doc_external = ' || i_id_doc || ' AND flg_type = ''' ||
                                                        pk_exam_constant.g_media_archive_exam_result || '''');
    
        pk_ia_event_common.document_update(i_prof.institution, l_id_doc_external);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'UPDATE_DOC',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
    END update_doc;

    FUNCTION update_document
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_id_doc               IN doc_external.id_doc_external%TYPE,
        i_tbl_ds_internal_name IN table_varchar DEFAULT NULL,
        i_tbl_val              IN table_table_varchar DEFAULT NULL,
        i_tbl_real_val         IN table_table_varchar DEFAULT NULL,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_id_doc_external   doc_external.id_doc_external%TYPE;
        l_num_doc           doc_external.num_doc%TYPE;
        l_dt_doc            doc_external.dt_emited%TYPE;
        l_dt_expire         doc_external.dt_expire%TYPE;
        l_dest              doc_external.id_doc_destination%TYPE;
        l_desc_dest         doc_external.desc_doc_destination%TYPE;
        l_ori_doc_type      doc_external.id_doc_ori_type%TYPE;
        l_desc_ori_doc_type doc_external.desc_doc_ori_type%TYPE;
        l_original          doc_external.id_doc_original%TYPE;
        l_desc_original     doc_external.desc_doc_original%TYPE;
        l_title             doc_external.title%TYPE;
        l_desc_perf_by      doc_external.desc_perf_by%TYPE;
        l_author            doc_external.author%TYPE;
        l_specialty         doc_external.id_specialty%TYPE;
        l_doc_language      doc_external.id_language%TYPE;
        l_notes             VARCHAR2(4000 CHAR);
        l_desc_language     VARCHAR2(100 CHAR);
    
    BEGIN
    
        FOR i IN i_tbl_ds_internal_name.first .. i_tbl_ds_internal_name.last
        LOOP
            IF i_tbl_ds_internal_name(i) = 'DS_DOCUMENT_NUMBER'
            THEN
                l_num_doc := i_tbl_real_val(i) (1);
            ELSIF i_tbl_ds_internal_name(i) = 'DS_DT_DOCUMENT'
            THEN
                BEGIN
                    l_dt_doc := to_date(i_tbl_real_val(i) (1), 'yyyymmdd HH24:MI:SS');
                EXCEPTION
                    WHEN OTHERS THEN
                        l_dt_doc := NULL;
                END;
            ELSIF i_tbl_ds_internal_name(i) = 'DS_DT_DOCUMENT_EXPIRE'
            THEN
                BEGIN
                    l_dt_expire := to_date(i_tbl_real_val(i) (1), 'yyyymmdd HH24:MI:SS');
                EXCEPTION
                    WHEN OTHERS THEN
                        l_dt_expire := NULL;
                END;
            ELSIF i_tbl_ds_internal_name(i) = 'DS_ORIGINAL_STAYS_WITH'
            THEN
                l_dest := i_tbl_real_val(i) (1);
            
                IF pk_doc.get_types_config_other(NULL,
                                                 NULL,
                                                 NULL,
                                                 l_dest,
                                                 i_prof,
                                                 pk_prof_utils.get_prof_profile_template(i_prof),
                                                 NULL) = pk_alert_constant.g_no
                THEN
                    l_desc_dest := i_tbl_val(i) (1);
                END IF;
            ELSIF i_tbl_ds_internal_name(i) = 'DS_ORIGINAL_STAYS_WITH_OTHER'
            THEN
                IF i_tbl_val(i) (1) IS NOT NULL
                THEN
                    l_desc_dest := i_tbl_val(i) (1);
                END IF;
            ELSIF i_tbl_ds_internal_name(i) = 'DS_CATEGORY'
            THEN
                l_ori_doc_type      := to_number(i_tbl_real_val(i) (1));
                l_desc_ori_doc_type := i_tbl_val(i) (1);
            ELSIF i_tbl_ds_internal_name(i) = 'DS_ORIGINAL_TYPE'
            THEN
                l_original := i_tbl_real_val(i) (1);
            
                IF pk_doc.get_types_config_other(NULL,
                                                 NULL,
                                                 l_original,
                                                 NULL,
                                                 i_prof,
                                                 pk_prof_utils.get_prof_profile_template(i_prof),
                                                 NULL) = pk_alert_constant.g_no
                THEN
                    l_desc_original := i_tbl_val(i) (1);
                END IF;
            ELSIF i_tbl_ds_internal_name(i) = 'DS_ORIGINAL_OTHER'
            THEN
                IF i_tbl_val(i) (1) IS NOT NULL
                THEN
                    l_desc_original := i_tbl_val(i) (1);
                END IF;
            ELSIF i_tbl_ds_internal_name(i) = 'DS_DOCUMENT_NAME'
            THEN
                l_title := i_tbl_real_val(i) (1);
            ELSIF i_tbl_ds_internal_name(i) = 'DS_PERFORMED_BY'
            THEN
                l_desc_perf_by := i_tbl_real_val(i) (1);
            ELSIF i_tbl_ds_internal_name(i) = 'DS_PROFESSIONAL'
            THEN
                l_desc_perf_by := i_tbl_val(i) (1);
            ELSIF i_tbl_ds_internal_name(i) = 'DS_SPECIALTY'
            THEN
                l_specialty := i_tbl_real_val(i) (1);
            ELSIF i_tbl_ds_internal_name(i) = 'DS_LANGUAGE'
            THEN
                l_doc_language := i_tbl_real_val(i) (1);
            ELSIF i_tbl_ds_internal_name(i) = 'DS_NOTES'
            THEN
                l_notes := i_tbl_real_val(i) (1);
            ELSIF i_tbl_ds_internal_name(i) = 'DS_LANGUAGE_OTHER'
            THEN
                l_desc_language := i_tbl_real_val(i) (1);
            END IF;
        END LOOP;
    
        g_error := 'pk_doc.update_doc';
        IF NOT pk_doc.update_doc(i_lang               => i_lang,
                                 i_prof               => i_prof,
                                 i_id_doc             => i_id_doc,
                                 i_doc_type           => 999, --other,
                                 i_desc_doc_type      => NULL,
                                 i_num_doc            => l_num_doc,
                                 i_dt_doc             => l_dt_doc,
                                 i_dt_expire          => l_dt_expire,
                                 i_orig_dest          => l_dest,
                                 i_desc_ori_dest      => l_desc_dest,
                                 i_orig_type          => l_ori_doc_type,
                                 i_desc_ori_doc_type  => l_desc_ori_doc_type,
                                 i_notes              => NULL,
                                 i_sent_by            => NULL,
                                 i_received           => NULL,
                                 i_original           => l_original,
                                 i_desc_original      => l_desc_original,
                                 i_btn                => NULL,
                                 i_title              => l_title,
                                 i_prof_perf_by       => NULL,
                                 i_desc_perf_by       => l_desc_perf_by,
                                 i_author             => l_author,
                                 i_specialty          => l_specialty,
                                 i_doc_language       => l_doc_language,
                                 i_desc_language      => l_desc_language,
                                 i_flg_publish        => NULL,
                                 i_conf_code          => NULL,
                                 i_desc_conf_code     => NULL,
                                 i_code_coding_schema => NULL,
                                 i_conf_code_set      => NULL,
                                 i_desc_conf_code_set => NULL,
                                 i_notes_upd          => l_notes,
                                 o_id_doc_external    => l_id_doc_external,
                                 o_error              => o_error)
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
                                              g_package_owner,
                                              g_package_name,
                                              'UPDATE_DOCUMENT',
                                              o_error);
            RETURN FALSE;
    END update_document;

    /******************************************************************************
       OBJECTIVO:   Actualizar documento, sem commit
       PARAMETROS:  Entrada: I_LANG     - Língua registada como preferência do profissional
                             I_ID_DOC   - Id do documento
                             I_DOC_TYPE - Id do tipo de documento
                             I_NUM_DOC  - Numero do documento
                             I_DT_DOC   - Data do documento
                             I_ORIG_DEST - Destino do documento original
                             I_ORIG_TYPE - Tipo do documento original
                             I_ORIGINAL - Id do tipo de original,
                             I_DESC_ORIGINAL - Descrição manual do tipo de original.
    
                Saida:   O_ERROR       - erro
    
      CRIAÇÃO:
      CRIAÇÃO: JS 2006/03/15
      CORRECÇÕES: LG 2007/fev/03, adição de novo campo: doc_original
      
      UPDATED - novo parametro i_title,, i_prof_perf_by, i_desc_perf_by
      * @author Telmo Castro
      * @date   19-12-2007
      
      UPDATED - alterada a politica de gravacao de alteraçoes. Passa a colocar estado 
                em outdated e insere novo registo
      * @author Telmo Castro
      * @date   07-01-2008
      
      UPDATED - o registo actual passa a ficar no estado O (oldversion)
      
      UPDATED - invocacao do pk_visit.set_first_obs
      * @author  Telmo Castro
      * @date    18-01-2008
    *********************************************************************************/
    FUNCTION update_doc_internal
    (
        i_lang               IN NUMBER,
        i_prof               IN profissional,
        i_id_doc             IN NUMBER,
        i_doc_type           IN NUMBER,
        i_desc_doc_type      IN VARCHAR2,
        i_num_doc            IN VARCHAR2,
        i_dt_doc             IN DATE,
        i_dt_expire          IN DATE,
        i_orig_dest          IN NUMBER,
        i_desc_ori_dest      IN VARCHAR2,
        i_orig_type          IN NUMBER,
        i_desc_ori_doc_type  IN VARCHAR2,
        i_notes              IN VARCHAR2,
        i_sent_by            IN doc_external.flg_sent_by%TYPE,
        i_received           IN doc_external.flg_received%TYPE,
        i_original           IN NUMBER,
        i_desc_original      IN VARCHAR2,
        i_btn                IN sys_button_prop.id_sys_button_prop%TYPE,
        i_title              IN doc_external.title%TYPE,
        i_prof_perf_by       IN doc_external.id_prof_perf_by%TYPE,
        i_desc_perf_by       IN doc_external.desc_perf_by%TYPE,
        i_author             IN doc_external.author%TYPE,
        i_specialty          IN doc_external.id_specialty%TYPE,
        i_doc_language       IN doc_external.id_language%TYPE,
        i_desc_language      IN doc_external.desc_language%TYPE,
        i_flg_publish        IN VARCHAR2,
        i_conf_code          IN table_varchar,
        i_desc_conf_code     IN table_varchar,
        i_code_coding_schema IN table_varchar,
        i_conf_code_set      IN table_varchar,
        i_desc_conf_code_set IN table_varchar,
        i_notes_upd          IN VARCHAR2,
        o_id_doc_external    OUT doc_external.id_doc_external%TYPE,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_desc_doc_ori_type    doc_external.desc_doc_ori_type%TYPE;
        l_desc_doc_type        doc_external.desc_doc_type%TYPE;
        l_desc_doc_destination doc_external.desc_doc_destination%TYPE;
        l_desc_doc_original    doc_external.desc_doc_original%TYPE;
        l_flg_status           doc_external.flg_status%TYPE;
        l_my_pt                profile_template.id_profile_template%TYPE;
        l_error                t_error_out;
        l_new_id               doc_external.id_doc_external%TYPE;
        l_id_patient           doc_external.id_patient%TYPE;
        l_id_episode           doc_external.id_episode%TYPE;
        l_id_ext_req           doc_external.id_external_request%TYPE;
        l_id_grupo             doc_external.id_grupo%TYPE;
        l_flg_received         doc_external.flg_received%TYPE;
        l_local_emitted        doc_external.local_emited%TYPE;
        l_doc_oid              doc_external.doc_oid%TYPE;
    
        r_doc doc_external%ROWTYPE;
    
        l_exception    EXCEPTION;
        l_ret          BOOLEAN;
        l_doc_original doc_original.id_doc_original%TYPE;
        l_rowids       table_varchar;
        l_operation    VARCHAR2(1);
    
    BEGIN
    
        g_error := 'Get default original';
        IF i_original IS NULL
        THEN
            IF NOT get_default_original(i_lang, i_prof, l_doc_original, o_error)
            THEN
                RAISE g_exception;
            END IF;
        ELSE
            l_doc_original := i_original;
        END IF;
    
        g_error := 'calculate doc_type desc';
        SELECT decode(get_types_config_other(i_doc_type, NULL, NULL, NULL, i_prof, l_my_pt, i_btn),
                      g_doc_config_y,
                      decode(upper(pk_translation.get_translation(i_lang, code_doc_type)),
                             upper(i_desc_doc_type),
                             NULL,
                             i_desc_doc_type),
                      NULL)
          INTO l_desc_doc_type
          FROM doc_type
         WHERE id_doc_type = i_doc_type;
    
        g_error := 'calculate doc_ori_type desc';
        SELECT decode(get_types_config_other(NULL, i_orig_type, NULL, NULL, i_prof, l_my_pt, i_btn),
                      g_doc_config_y,
                      decode(upper(pk_translation.get_translation(i_lang, code_doc_ori_type)),
                             upper(i_desc_ori_doc_type),
                             NULL,
                             i_desc_ori_doc_type),
                      NULL)
          INTO l_desc_doc_ori_type
          FROM doc_ori_type
         WHERE id_doc_ori_type = i_orig_type;
    
        g_error := 'calculate doc_original desc';
        SELECT decode(get_types_config_other(NULL, NULL, l_doc_original, NULL, i_prof, l_my_pt, i_btn),
                      g_doc_config_y,
                      decode(upper(pk_translation.get_translation(i_lang, code_doc_original)),
                             upper(i_desc_original),
                             NULL,
                             i_desc_original),
                      NULL)
          INTO l_desc_doc_original
          FROM doc_original
         WHERE id_doc_original = l_doc_original;
    
        g_error := 'calculate doc_destination desc';
        IF i_orig_dest IS NOT NULL
        THEN
            SELECT decode(get_types_config_other(NULL, NULL, NULL, i_orig_dest, i_prof, l_my_pt, i_btn),
                          g_doc_config_y,
                          decode(upper(pk_translation.get_translation(i_lang, code_doc_destination)),
                                 upper(i_desc_ori_dest),
                                 NULL,
                                 i_desc_ori_dest),
                          NULL)
              INTO l_desc_doc_destination
              FROM doc_destination
             WHERE id_doc_destination = i_orig_dest;
        END IF;
    
        -- obter estado do documento, ids e id_grupo para passar a' proxima geracao
        g_error := 'SELECT ID_DOC_EXTERNAL';
        SELECT de.flg_status,
               de.id_external_request,
               de.id_episode,
               de.id_patient,
               de.id_grupo,
               de.flg_received,
               de.local_emited,
               de.doc_oid
          INTO l_flg_status,
               l_id_ext_req,
               l_id_episode,
               l_id_patient,
               l_id_grupo,
               l_flg_received,
               l_local_emitted,
               l_doc_oid
          FROM doc_external de
         WHERE de.id_doc_external = i_id_doc;
    
        -- update do id_grupo do pai se ainda nao tinha. Fica com id_grupo = id_doc_external
        IF l_id_grupo IS NULL
        THEN
            l_id_grupo := i_id_doc;
        
            l_rowids := table_varchar();
        
            g_error := 'Call ts_doc_external.upd / ID_DOC_EXTERNAL_IN=' || i_id_doc;
            ts_doc_external.upd(id_doc_external_in => i_id_doc,
                                id_grupo_in        => l_id_grupo,
                                handle_error_in    => TRUE,
                                rows_out           => l_rowids);
        
            g_error := 'Call t_data_gov_mnt.process_update';
            t_data_gov_mnt.process_update(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'DOC_EXTERNAL',
                                          i_rowids     => l_rowids,
                                          o_error      => o_error);
        
            --ADT
            UPDATE doc_external_hist
               SET id_grupo = l_id_grupo
             WHERE id_doc_external = i_id_doc;
        END IF;
    
        IF l_flg_status = pk_doc.g_doc_pendente
        THEN
            l_rowids := table_varchar();
            g_error  := 'Call ts_doc_external.upd / ID_DOC_EXTERNAL_IN=' || i_id_doc;
            ts_doc_external.upd(id_doc_external_in      => i_id_doc,
                                id_doc_type_in          => i_doc_type,
                                desc_doc_type_in        => l_desc_doc_type,
                                num_doc_in              => i_num_doc,
                                dt_emited_in            => i_dt_doc,
                                dt_expire_in            => i_dt_expire,
                                notes_in                => i_notes,
                                id_doc_destination_in   => i_orig_dest,
                                desc_doc_destination_in => l_desc_doc_destination,
                                id_doc_ori_type_in      => i_orig_type,
                                desc_doc_ori_type_in    => l_desc_doc_ori_type,
                                flg_sent_by_in          => i_sent_by,
                                flg_received_in         => nvl(i_received, 'N'),
                                id_doc_original_in      => l_doc_original,
                                desc_doc_original_in    => l_desc_doc_original,
                                title_in                => i_title,
                                dt_updated_in           => current_timestamp,
                                id_professional_upd_in  => i_prof.id,
                                id_prof_perf_by_in      => i_prof_perf_by,
                                desc_perf_by_in         => i_desc_perf_by,
                                id_specialty_in         => i_specialty,
                                id_language_in          => i_doc_language,
                                desc_language_in        => i_desc_language,
                                author_in               => i_author,
                                handle_error_in         => TRUE,
                                rows_out                => l_rowids);
        
            g_error := 'Call t_data_gov_mnt.process_update';
            t_data_gov_mnt.process_update(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'DOC_EXTERNAL',
                                          i_rowids     => l_rowids,
                                          o_error      => o_error);
        
            o_id_doc_external := i_id_doc;
        
            --ADT
            UPDATE doc_external_hist
               SET id_doc_type          = i_doc_type,
                   desc_doc_type        = l_desc_doc_type,
                   num_doc              = i_num_doc,
                   dt_emited            = i_dt_doc,
                   dt_expire            = i_dt_expire,
                   notes                = i_notes,
                   id_doc_destination   = i_orig_dest,
                   desc_doc_destination = l_desc_doc_destination,
                   id_doc_ori_type      = i_orig_type,
                   desc_doc_ori_type    = l_desc_doc_ori_type,
                   flg_sent_by          = i_sent_by,
                   flg_received         = nvl(i_received, 'N'),
                   id_doc_original      = l_doc_original,
                   desc_doc_original    = l_desc_doc_original,
                   title                = i_title,
                   dt_updated           = current_timestamp,
                   id_professional_upd  = i_prof.id,
                   id_prof_perf_by      = i_prof_perf_by,
                   desc_perf_by         = i_desc_perf_by,
                   id_language          = i_doc_language,
                   desc_language        = i_desc_language
             WHERE id_doc_external = i_id_doc;
        
            --is the document to be published
            IF i_flg_publish = g_yes
               AND pk_sysconfig.get_config('HIE_ENABLED', i_prof) = 'Y'
            THEN
                --Call publish_document
                IF NOT pk_hie_xds.set_submit_or_upd_doc_internal(i_lang,
                                                                 i_prof,
                                                                 i_id_doc, --i_doc_external  ,
                                                                 i_conf_code,
                                                                 i_desc_conf_code,
                                                                 i_code_coding_schema,
                                                                 i_conf_code_set,
                                                                 i_desc_conf_code_set,
                                                                 o_error)
                THEN
                    RAISE l_exception;
                END IF;
            
            END IF;
        
        ELSIF l_flg_status = g_doc_active
        THEN
            -- old version este doc 
            -- UPDATE doc_external
            --  SET flg_status = g_doc_oldversion, dt_updated = current_timestamp, id_professional_upd = i_prof.id
            -- WHERE id_doc_external = i_id_doc;
        
            l_rowids := table_varchar();
            g_error  := 'OLD VERSION Call ts_doc_external.upd / ID_DOC_EXTERNAL_IN=' || i_id_doc;
            ts_doc_external.upd(id_doc_external_in     => i_id_doc,
                                flg_status_in          => g_doc_oldversion,
                                dt_updated_in          => current_timestamp,
                                id_professional_upd_in => i_prof.id,
                                handle_error_in        => TRUE,
                                rows_out               => l_rowids);
        
            g_error := 'Call t_data_gov_mnt.process_update';
            t_data_gov_mnt.process_update(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'DOC_EXTERNAL',
                                          i_rowids     => l_rowids,
                                          o_error      => o_error);
        
            -- log activity 
            g_error := 'Error registering document activity';
            IF NOT pk_doc_activity.log_document_activity(i_lang            => i_lang,
                                                         i_prof            => i_prof,
                                                         i_doc_id          => i_id_doc,
                                                         i_operation       => 'UPDATE',
                                                         i_source          => 'EHR',
                                                         i_target          => 'EHR',
                                                         i_operation_param => NULL,
                                                         o_error           => o_error)
            THEN
                RAISE l_exception;
            END IF;
        
            -- inserir novo parte 1
            g_error := 'INIT NEW DOC';
            IF NOT pk_doc.create_initdoc(i_lang            => i_lang,
                                         i_prof            => i_prof,
                                         i_patient         => l_id_patient,
                                         i_episode         => l_id_episode,
                                         i_ext_req         => l_id_ext_req,
                                         i_btn             => i_btn,
                                         i_id_grupo        => l_id_grupo,
                                         i_internal_commit => TRUE,
                                         o_id_doc          => l_new_id,
                                         o_error           => o_error)
            THEN
                RAISE l_exception;
            END IF;
        
            -- Update document edition
            UPDATE doc_external_hist deh
               SET deh.operation_type = 'U'
             WHERE id_doc_external = l_new_id;
        
            -- inserir novo parte 2
            g_error := 'SAVE NEW DOC';
            IF NOT pk_doc.create_savedoc(i_id_doc             => l_new_id,
                                         i_lang               => i_lang,
                                         i_prof               => i_prof,
                                         i_patient            => l_id_patient,
                                         i_episode            => l_id_episode,
                                         i_ext_req            => l_id_ext_req,
                                         i_doc_type           => i_doc_type,
                                         i_desc_doc_type      => i_desc_doc_type,
                                         i_num_doc            => i_num_doc,
                                         i_dt_doc             => i_dt_doc,
                                         i_dt_expire          => i_dt_expire,
                                         i_dest               => i_orig_dest,
                                         i_desc_dest          => i_desc_ori_dest,
                                         i_ori_doc_type       => i_orig_type,
                                         i_desc_ori_doc_type  => i_desc_ori_doc_type,
                                         i_original           => l_doc_original,
                                         i_desc_original      => i_desc_original,
                                         i_btn                => i_btn,
                                         i_title              => i_title,
                                         i_flg_sent_by        => i_sent_by,
                                         i_flg_received       => i_received,
                                         i_prof_perf_by       => i_prof_perf_by,
                                         i_desc_perf_by       => i_desc_perf_by,
                                         i_author             => i_author,
                                         i_specialty          => i_specialty,
                                         i_doc_language       => i_doc_language,
                                         i_desc_language      => i_desc_language,
                                         i_flg_publish        => i_flg_publish,
                                         i_conf_code          => i_conf_code,
                                         i_desc_conf_code     => i_desc_conf_code,
                                         i_code_coding_schema => i_code_coding_schema,
                                         i_conf_code_set      => i_conf_code_set,
                                         i_desc_conf_code_set => i_desc_conf_code_set,
                                         i_local_emitted      => l_local_emitted,
                                         i_doc_oid            => l_doc_oid,
                                         i_internal_commit    => TRUE,
                                         i_notes              => i_notes_upd,
                                         o_error              => o_error)
            THEN
                RAISE l_exception;
            END IF;
        
            -- ALERT-261468
            IF l_id_ext_req IS NOT NULL
            THEN
                IF (i_received IS NOT NULL AND l_flg_received IS NOT NULL AND i_received != l_flg_received)
                   OR (i_received IS NULL AND l_flg_received IS NOT NULL)
                   OR (i_received IS NOT NULL AND l_flg_received IS NULL)
                THEN
                    pk_ia_event_referral.referral_document_receive(i_id_doc_external => l_id_grupo,
                                                                   i_id_institution  => i_prof.institution);
                END IF;
            END IF;
        
            -- transferir imagens para o novo
            UPDATE doc_image
               SET id_doc_external = l_new_id
             WHERE id_doc_external = i_id_doc;
        
            --  transfer reports to new document
            UPDATE epis_report
               SET id_doc_external = l_new_id
             WHERE id_doc_external = i_id_doc;
        
            -- transferir comentarios para o novo
            UPDATE doc_comments
               SET id_doc_external = l_new_id
             WHERE id_doc_external = i_id_doc;
        
            -- pk_visit.set_first_obs
            g_sysdate := current_timestamp;
            IF NOT pk_visit.set_first_obs(i_lang                => i_lang,
                                          i_id_episode          => l_id_episode,
                                          i_pat                 => l_id_patient,
                                          i_prof                => i_prof,
                                          i_prof_cat_type       => NULL,
                                          i_dt_last_interaction => g_sysdate,
                                          i_dt_first_obs        => g_sysdate,
                                          o_error               => o_error)
            THEN
                RAISE l_exception;
            END IF;
        
            o_id_doc_external := l_new_id;
        END IF;
    
        IF is_lab_test_result(i_lang => i_lang, i_prof => i_prof, i_doc_external => i_id_doc)
        THEN
            DECLARE
                l_id_analysis_req_det        analysis_req_det.id_analysis_req_det%TYPE;
                l_id_analysis_result         analysis_result_par.id_analysis_result%TYPE;
                l_id_analysis_result_par     analysis_result_par.id_analysis_result_par%TYPE;
                l_tbl_analysis_media_archive table_number := table_number();
            
                l_rows_out table_varchar := table_varchar();
            BEGIN
            
                g_sysdate_tstz := current_timestamp;
            
                l_rows_out := NULL;
            
                --Inactivate old records of analysis_media_archive for the given i_doc_external
                BEGIN
                    SELECT ama.id_analysis_media_archive
                      BULK COLLECT
                      INTO l_tbl_analysis_media_archive
                      FROM analysis_media_archive ama
                     WHERE ama.id_doc_external = i_id_doc
                       AND ama.flg_status = pk_alert_constant.g_active;
                EXCEPTION
                    WHEN no_data_found THEN
                        l_tbl_analysis_media_archive := table_number();
                END;
            
                IF l_tbl_analysis_media_archive.exists(1)
                THEN
                    FOR i IN 1 .. l_tbl_analysis_media_archive.count
                    LOOP
                        ts_analysis_media_archive.upd(id_analysis_media_archive_in => l_tbl_analysis_media_archive(i),
                                                      flg_status_in                => pk_alert_constant.g_inactive,
                                                      id_prof_last_update_in       => i_prof.id,
                                                      dt_last_update_tstz_in       => g_sysdate_tstz,
                                                      rows_out                     => l_rows_out);
                    
                        --Create new recods on analysis_media_archive for the new doc_external ids
                    
                        SELECT ama.id_analysis_req_det, ama.id_analysis_result, ama.id_analysis_result_par
                          INTO l_id_analysis_req_det, l_id_analysis_result, l_id_analysis_result_par
                          FROM analysis_media_archive ama
                         WHERE ama.id_analysis_media_archive = l_tbl_analysis_media_archive(i);
                    
                        ts_analysis_media_archive.ins(id_analysis_req_det_in    => l_id_analysis_req_det,
                                                      id_analysis_result_in     => l_id_analysis_result,
                                                      id_analysis_result_par_in => l_id_analysis_result_par,
                                                      id_doc_external_in        => o_id_doc_external,
                                                      flg_type_in               => pk_lab_tests_constant.g_media_archive_analysis_res,
                                                      flg_status_in             => pk_lab_tests_constant.g_active,
                                                      id_prof_last_update_in    => i_prof.id,
                                                      dt_last_update_tstz_in    => g_sysdate_tstz,
                                                      rows_out                  => l_rows_out);
                    END LOOP;
                END IF;
                g_error := 'CALL PROCESS_INSERT';
                t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_table_name => 'ANALYSIS_MEDIA_ARCHIVE',
                                              i_rowids     => l_rows_out,
                                              o_error      => o_error);
            END;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_exception THEN
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'UPDATE_DOC_INTERNAL',
                                              o_error);
            RETURN FALSE;
    END update_doc_internal;

    /**
    * Cancels a document
    *
    * @param   I_LANG language associated to the professional executing the request
    * @param   I_PROF  professional, institution and software ids
    * @param   I_ID_DOC  document id
    * @param   O_ERROR an error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  João Sá
    * @version 1.0
    * @since   22-11-2006
    *
    * UPDATED  invocar pk_visit.set_first_obs
    * @author  Telmo Castro
    * @date    18-01-2008
    */
    FUNCTION cancel_doc
    (
        i_lang   IN NUMBER,
        i_prof   IN profissional,
        i_id_doc IN NUMBER,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN IS
        l_exception EXCEPTION;
        l_error     t_error_out;
    BEGIN
    
        g_error := 'CANCEL DOC';
        IF NOT pk_doc.cancel_doc_internal(i_lang => i_lang, i_prof => i_prof, i_id_doc => i_id_doc, o_error => o_error)
        THEN
            RAISE l_exception;
        END IF;
    
        COMMIT;
    
        pk_ia_event_common.document_cancel(i_prof.institution, i_id_doc);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'CANCEL_DOC',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
    END cancel_doc;

    /**
    * Cancels a document
    *
    * @param   I_LANG language associated to the professional executing the request
    * @param   I_PROF  professional, institution and software ids
    * @param   I_ID_DOC  document id
    * @param   O_ERROR an error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  João Sá
    * @version 1.0
    * @since   22-11-2006
    *
    * UPDATED  invocar pk_visit.set_first_obs
    * @author  Telmo Castro
    * @date    18-01-2008
    */
    FUNCTION cancel_doc_internal
    (
        i_lang   IN NUMBER,
        i_prof   IN profissional,
        i_id_doc IN NUMBER,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN IS
        l_exception   EXCEPTION;
        l_episode     doc_external.id_episode%TYPE;
        l_patient     doc_external.id_patient%TYPE;
        l_error       t_error_out;
        r_doc         doc_external%ROWTYPE;
        l_ret         BOOLEAN;
        l_delete_hie  sys_config.value%TYPE;
        l_hie_enabled sys_config.value%TYPE;
    
        l_doc_external_row doc_external%ROWTYPE;
        l_rowids           table_varchar;
    BEGIN
    
        g_error := 'UPDATE DOC_EXTERNAL';
        SELECT *
          INTO l_doc_external_row
          FROM doc_external
         WHERE id_doc_external = i_id_doc;
    
        l_doc_external_row.flg_status          := g_doc_inactive;
        l_doc_external_row.dt_updated          := current_timestamp;
        l_doc_external_row.id_professional_upd := i_prof.id;
    
        l_episode := l_doc_external_row.id_episode;
        l_patient := l_doc_external_row.id_patient;
    
        -- UPDATE doc_external
        --   SET flg_status = g_doc_inactive, dt_updated = current_timestamp, id_professional_upd = i_prof.id
        -- WHERE id_doc_external = i_id_doc
        -- RETURNING id_episode, id_patient INTO l_episode, l_patient;*/
    
        l_rowids := table_varchar();
        g_error  := 'Call ts_doc_external.upd  / RECORD  L_DOC_EXTERNAL_ROW.ID_DOC_EXTERNAL=' ||
                    l_doc_external_row.id_doc_external;
        ts_doc_external.upd(rec_in => l_doc_external_row, handle_error_in => TRUE, rows_out => l_rowids);
    
        g_error := 'Call t_data_gov_mnt.process_update';
        t_data_gov_mnt.process_update(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'DOC_EXTERNAL',
                                      i_rowids     => l_rowids,
                                      o_error      => o_error);
    
        -- Log operation on doc_external_hist
        g_error := 'Error registering document activity';
        IF NOT pk_doc_activity.log_document_activity(i_lang            => i_lang,
                                                     i_prof            => i_prof,
                                                     i_doc_id          => i_id_doc,
                                                     i_operation       => 'DELETE',
                                                     i_source          => 'EHR',
                                                     i_target          => 'EHR',
                                                     i_operation_param => NULL,
                                                     o_error           => o_error)
        THEN
            RAISE l_exception;
        END IF;
    
        --ADT requirement
        UPDATE doc_external_hist
           SET flg_status = g_doc_inactive, dt_updated = current_timestamp, id_professional_upd = i_prof.id
         WHERE id_doc_external = i_id_doc;
    
        --delete document from HIE
        l_hie_enabled := pk_sysconfig.get_config('HIE_ENABLED', i_prof => i_prof);
        l_delete_hie  := pk_sysconfig.get_config('HIE_DELETE_ON_DOC_CANCEL_IN_DOC_ARCHIVE', i_prof => i_prof);
    
        -- only deletes document if this Institution is connected to an HIE
        -- and It's configured to do so. By default, it will delete if Institution is connected to HIE
        IF l_hie_enabled = 'Y'
           AND (l_delete_hie = 'Y' OR l_delete_hie IS NULL)
        THEN
        
            IF NOT pk_hie_xds.delist_doc(i_lang         => i_lang,
                                         i_prof         => i_prof,
                                         i_doc_external => i_id_doc,
                                         i_do_commit    => FALSE,
                                         o_error        => o_error)
            THEN
                RAISE l_exception;
            END IF;
        END IF;
        --
    
        -- pk_visit.set_first_obs
        g_sysdate := current_timestamp;
        IF SQL%ROWCOUNT > 0
           AND NOT pk_visit.set_first_obs(i_lang                => i_lang,
                                          i_id_episode          => l_episode,
                                          i_pat                 => l_patient,
                                          i_prof                => i_prof,
                                          i_prof_cat_type       => NULL,
                                          i_dt_last_interaction => g_sysdate,
                                          i_dt_first_obs        => g_sysdate,
                                          o_error               => l_error)
        THEN
            RAISE l_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_exception THEN
            o_error := l_error;
            RETURN FALSE;
        WHEN OTHERS THEN
            DECLARE
                --Inicialization of object for input 
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                -- setting language, setting error content into input object, setting package information 
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   g_package_owner,
                                   g_package_name,
                                   'CANCEL_DOC_INTERNAL');
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
                RETURN FALSE;
            END;
            RETURN FALSE;
    END cancel_doc_internal;

    /**
    * Obtain file extension
    *
    * @param i_lang              language id
    * @param i_prof              professional, software and institution ids
    * @param i_id_img            image id
    * @param o_error             an error message
    *
    * @return true (sucess), false (error)
    * @created 14-Jun-2007
    * @author João Sá
    */
    FUNCTION get_doc_image_extension
    (
        i_lang   IN NUMBER,
        i_prof   IN profissional,
        i_id_img IN NUMBER
    ) RETURN VARCHAR2 IS
    
        CURSOR c_file_ext IS
            SELECT lower(substr(i.file_name, instr(i.file_name, '.', -1) + 1))
              FROM doc_image i, doc_file_type f
             WHERE i.id_doc_image = i_id_img
               AND lower(f.extension) = lower(substr(i.file_name, instr(i.file_name, '.', -1) + 1));
    
        CURSOR c_report IS
            SELECT decode(r.mime_type, 'text/xml', 'xml', 'pdf')
              FROM epis_report er, reports r
             WHERE id_epis_report = i_id_img
               AND er.id_reports = r.id_reports;
    
        l_file_ext doc_file_type.extension%TYPE;
    
    BEGIN
    
        --Get extension from doc_image
        OPEN c_file_ext;
        FETCH c_file_ext
            INTO l_file_ext;
        g_found := c_file_ext%FOUND;
        CLOSE c_file_ext;
    
        IF NOT g_found
        THEN
            --If we do not have records in doc_image get extension from epis_report
            OPEN c_report;
            FETCH c_report
                INTO l_file_ext;
            g_found := c_report%FOUND;
            CLOSE c_report;
            --If we do not have records in epis_report get default extension
            IF NOT g_found
            THEN
                SELECT pk_sysconfig.get_config('DOC_DEFAULT_FILE_TYPE_EXTENSION', i_prof)
                  INTO l_file_ext
                  FROM dual;
            END IF;
        END IF;
    
        RETURN l_file_ext;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_doc_image_extension;

    /**
    * Retornar lista de imagens do documento
    *
    * @param i_lang              language id
    * @param i_prof              professional, software and institution ids
    * @param i_id_doc_list       list of document ids
    * @param i_start_point       subset starting point
    * @param i_quantity          number of results to return
    * @param o_doc_img_detail    image details
    * @param o_error             an error message
    *
    * @return true (sucess), false (error)
    * @created 14-Jun-2007
    * @author João Sá
    *
    * UPDATED - title incluido no output
    * @author Telmo Castro
    * @date   20-12-2007 
    *
    * UPDATED - created an internal to return a subset of results from a list of documents (from a requirment from JG to the coverflow).
    * @author Daniel Silva
    * @date  2013.09.05 
    */
    FUNCTION get_doc_images_internal
    (
        i_lang        IN NUMBER,
        i_prof        IN profissional,
        i_id_doc_list IN table_number,
        i_start_point IN NUMBER,
        i_quantity    IN NUMBER,
        o_doc_images  OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_url_doc            VARCHAR2(2000);
        l_url_rep            VARCHAR2(2000);
        l_url_doc_cda        VARCHAR2(2000);
        l_url_doc_cda_report VARCHAR2(2000);
    
    BEGIN
    
        l_url_doc            := pk_sysconfig.get_config('URL_DOC_IMAGE_DEF_THUMBNAIL', i_prof);
        l_url_rep            := pk_sysconfig.get_config('URL_REPORT_THUMBNAIL', i_prof);
        l_url_doc_cda        := pk_sysconfig.get_config('URL_DOC_CDA', i_prof);
        l_url_doc_cda_report := pk_sysconfig.get_config('URL_DOC_CDA_REPORT', i_prof);
    
        OPEN o_doc_images FOR
        
            SELECT flg_type,
                   id_img,
                   page,
                   file_name,
                   dt_img,
                   url,
                   url_thumb,
                   has_thumb,
                   flg_import,
                   dt_import,
                   mime_type,
                   img_name,
                   desc_file_type,
                   viewing_style,
                   title,
                   rank,
                   flg_deletable,
                   dt_import_tstz
              FROM (SELECT rownum r, dimg.*
                      FROM (SELECT 'I' flg_type,
                                   di.id_doc_image id_img,
                                   di.id_doc_image page,
                                   di.file_name file_name,
                                   pk_date_utils.date_send_tsz(i_lang, di.dt_img_tstz, i_prof) dt_img,
                                   --http://localhost:8080/CDA-Gateway/services/getcda?idLanguage=2.0&idProfessional=142.0&idSoftware=8.0&idInstitution=19.0&bdoc=1643179&bdocpage=389353&thumb=0
                                   decode(nvl(di.mime_type, dt.mime_type),
                                          'text/xml',
                                          REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(l_url_doc_cda,
                                                                                                  '@1',
                                                                                                  i_lang),
                                                                                          '@2',
                                                                                          i_prof.id),
                                                                                  '@3',
                                                                                  i_prof.software),
                                                                          '@4',
                                                                          i_prof.institution),
                                                                  '@5',
                                                                  di.id_doc_external),
                                                          '@6',
                                                          di.id_doc_image),
                                                  '@7',
                                                  '0'),
                                          REPLACE(REPLACE(REPLACE(l_url_doc, '@1', di.id_doc_external),
                                                          '@2',
                                                          di.id_doc_image),
                                                  '@3',
                                                  '0')) url,
                                   REPLACE(REPLACE(REPLACE(l_url_doc, '@1', di.id_doc_external), '@2', di.id_doc_image),
                                           '@3',
                                           '1') url_thumb,
                                   nvl(di.flg_img_thumbnail, g_flg_img_thumbnail_n) has_thumb,
                                   di.flg_import flg_import,
                                   pk_date_utils.date_send_tsz(i_lang, di.dt_import_tstz, i_prof) dt_import,
                                   dt.mime_type mime_type,
                                   dt.img_name img_name,
                                   pk_translation.get_translation(i_lang, dt.code_doc_file_type) desc_file_type,
                                   dt.viewing_style viewing_style,
                                   nvl(di.title, di.file_name) title,
                                   di.rank rank,
                                   g_yes flg_deletable,
                                   dt_img_tstz dt_import_tstz
                              FROM doc_image di
                             INNER JOIN doc_external de
                                ON di.id_doc_external = de.id_doc_external
                             INNER JOIN doc_file_type dt
                                ON lower(dt.extension) = pk_doc.get_doc_image_extension(i_lang, i_prof, di.id_doc_image)
                             WHERE di.id_doc_external IN (SELECT column_value
                                                            FROM TABLE(i_id_doc_list))
                               AND di.flg_status = g_img_active
                            UNION ALL
                            SELECT 'R' flg_type,
                                   er.id_epis_report id_img,
                                   er.id_epis_report page,
                                   pk_translation.get_translation(i_lang, r.code_reports) file_name,
                                   pk_date_utils.date_send_tsz(i_lang, er.dt_creation_tstz, i_prof) dt_img,
                                   --For reports the UX layer will call a JAVA method to get those URL links
                                   --unless it is a CDA - in that case its a separeted window.
                                   --http://localhost:8080/CDA-Gateway/services/getcda?idLanguage=2.0&idProfessional=142.0&idSoftware=8.0&idInstitution=19.0&idEpisReport=1770172.0
                                   decode(r.mime_type,
                                          'text/xml',
                                          REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(l_url_doc_cda_report, '@1', i_lang),
                                                                          '@2',
                                                                          i_prof.id),
                                                                  '@3',
                                                                  i_prof.software),
                                                          '@4',
                                                          i_prof.institution),
                                                  '@5',
                                                  er.id_epis_report),
                                          NULL) url,
                                   l_url_rep || er.id_epis_report url_thumb,
                                   decode(nvl(dbms_lob.getlength(er.epis_report_thumbnail), 0), 0, g_no, g_yes) has_thumb,
                                   NULL flg_import,
                                   NULL dt_import,
                                   nvl(r.mime_type, dt.mime_type) mime_type,
                                   pk_translation.get_translation(i_lang, r.code_reports) img_name,
                                   pk_translation.get_translation(i_lang, dt.code_doc_file_type) desc_file_type,
                                   dt.viewing_style viewing_style,
                                   pk_translation.get_translation(i_lang, r.code_reports) title,
                                   999 rank,
                                   g_no flg_deletable,
                                   NULL dt_import_tstz
                              FROM epis_report er, reports r, doc_file_type dt
                             WHERE er.id_doc_external IN (SELECT column_value
                                                            FROM TABLE(i_id_doc_list))
                               AND (er.flg_status != g_epis_report_flg_status_n OR
                                   (er.flg_status = g_epis_report_flg_status_n AND er.flg_report_origin = 'D'))
                               AND er.id_reports = r.id_reports
                               AND lower(dt.extension) = g_report_default_extension
                             ORDER BY dt_import_tstz ASC) dimg)
             WHERE r BETWEEN i_start_point AND ((i_start_point + i_quantity) - 1);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                --Inicialization of object for input 
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                pk_types.open_my_cursor(o_doc_images);
                -- setting language, setting error content into input object, setting package information 
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   g_package_owner,
                                   g_package_name,
                                   'GET_DOC_IMAGES_INTERNAL');
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
                RETURN FALSE;
            END;
    END get_doc_images_internal;

    /**
    * Retornar lista de imagens do documento
    *
    * @param i_lang              language id
    * @param i_prof              professional, software and institution ids
    * @param i_id_doc            document id
    * @param o_doc_img_detail    image details
    * @param o_error             an error message
    *
    * @return true (sucess), false (error)
    * @created 14-Jun-2007
    * @author João Sá
    *
    * UPDATED - title incluido no output
    * @author Telmo Castro
    * @date   20-12-2007 
    *
    * UPDATED - created an internal to return a subset of results from a list of documents (from a requirment from JG to the coverflow).
    * @author Daniel Silva
    * @date  2013.09.05 
    */
    FUNCTION get_doc_images
    (
        i_lang       IN NUMBER,
        i_prof       IN profissional,
        i_id_doc     IN NUMBER,
        o_doc_images OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        RETURN pk_doc.get_doc_images_internal(i_lang, i_prof, table_number(i_id_doc), 0, 99999, o_doc_images, o_error);
    
    END get_doc_images;

    FUNCTION get_doc_images_list
    (
        i_lang       IN NUMBER,
        i_prof       IN profissional,
        i_id_doc     IN table_number,
        o_doc_images OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_url_doc VARCHAR2(2000);
        l_url_rep VARCHAR2(2000);
    
        l_url_doc_cda_report VARCHAR2(2000);
    
    BEGIN
    
        l_url_doc_cda_report := pk_sysconfig.get_config('URL_DOC_CDA_REPORT', i_prof);
        l_url_doc            := pk_sysconfig.get_config('URL_DOC_IMAGE_DEF_THUMBNAIL', i_prof);
        l_url_rep            := pk_sysconfig.get_config('URL_REPORT_THUMBNAIL', i_prof);
    
        OPEN o_doc_images FOR
            SELECT 'I' flg_type,
                   di.id_doc_image id_img,
                   di.id_doc_image page,
                   di.file_name,
                   de.id_doc_external,
                   de.title,
                   pk_date_utils.date_send_tsz(i_lang, di.dt_img_tstz, i_prof) dt_img,
                   REPLACE(REPLACE(REPLACE(l_url_doc, '@1', t.column_value), '@2', di.id_doc_image), '@3', '0') url,
                   REPLACE(REPLACE(REPLACE(l_url_doc, '@1', t.column_value), '@2', di.id_doc_image), '@3', '1') url_thumb,
                   nvl(di.flg_img_thumbnail, g_flg_img_thumbnail_n) has_thumb,
                   di.flg_import,
                   pk_date_utils.date_send_tsz(i_lang, di.dt_import_tstz, i_prof) dt_import,
                   nvl(di.mime_type, dt.mime_type) mime_type,
                   dt.img_name,
                   pk_translation.get_translation(i_lang, dt.code_doc_file_type) desc_file_type,
                   dt.viewing_style,
                   di.title doc_title,
                   di.rank,
                   g_yes flg_deletable,
                   dt_img_tstz dt_import_tstz
              FROM doc_image di,
                   doc_file_type dt,
                   (SELECT column_value
                      FROM TABLE(i_id_doc)) t,
                   doc_external de
             WHERE di.id_doc_external = t.column_value
               AND di.flg_status = g_img_active
               AND di.doc_img IS NOT NULL
               AND dbms_lob.compare(di.doc_img, empty_blob()) != 0
               AND de.id_doc_external = di.id_doc_external
               AND lower(dt.extension) = pk_doc.get_doc_image_extension(i_lang, i_prof, di.id_doc_image)
            UNION ALL
            SELECT 'R' flg_type,
                   er.id_epis_report id_img,
                   er.id_epis_report page,
                   NULL file_name,
                   de.id_doc_external,
                   de.title,
                   pk_date_utils.date_send_tsz(1, er.dt_creation_tstz, i_prof) dt_img,
                   --For reports the UX layer will call a JAVA method to get those URL links
                   decode(r.mime_type,
                          'text/xml',
                          REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(l_url_doc_cda_report, '@1', i_lang), '@2', i_prof.id),
                                                  '@3',
                                                  i_prof.software),
                                          '@4',
                                          i_prof.institution),
                                  '@5',
                                  er.id_epis_report),
                          NULL) url,
                   l_url_rep || er.id_epis_report url_thumb,
                   decode(nvl(dbms_lob.getlength(er.epis_report_thumbnail), 0), 0, g_no, g_yes) has_thumb,
                   NULL flg_import,
                   NULL dt_import,
                   dt.mime_type,
                   NULL img_name,
                   pk_translation.get_translation(1, dt.code_doc_file_type) desc_file_type,
                   dt.viewing_style,
                   pk_translation.get_translation(1, 'REPORT.CODE_REPORT.' || er.id_reports),
                   999 rank,
                   g_no flg_deletable,
                   NULL dt_import_tstz
              FROM epis_report er,
                   reports r,
                   doc_file_type dt,
                   (SELECT column_value
                      FROM TABLE(i_id_doc)) t,
                   doc_external de
             WHERE er.id_doc_external = t.column_value
               AND er.id_reports = r.id_reports
               AND de.id_doc_external = er.id_doc_external
               AND (er.flg_status != g_epis_report_flg_status_n OR
                   (er.flg_status = g_no AND er.flg_report_origin = 'D'))
               AND dt.mime_type = r.mime_type
             ORDER BY rank, dt_import_tstz;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                --Inicialization of object for input 
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                pk_types.open_my_cursor(o_doc_images);
                -- setting language, setting error content into input object, setting package information 
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   g_package_owner,
                                   g_package_name,
                                   'GET_DOC_IMAGES_LIST');
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
                RETURN FALSE;
            END;
    END get_doc_images_list;

    /**
    * Devolve lista de notas/interpretacoes dum documento
    *
    * @param i_lang              language id
    * @param i_prof              professional, software and institution ids
    * @param i_id_doc            document id do qual se pretende obter as notas
    * @param o_list             lista das notas
    * @param o_error             an error message
    *
    * @version 1.0
    * @author Telmo Castro
    * @date   26-12-2007 
    */
    FUNCTION get_doc_comments
    (
        i_lang   IN NUMBER,
        i_prof   IN profissional,
        i_id_doc IN NUMBER,
        o_list   OUT pk_types.cursor_type,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        g_error := 'OPEN doc_comments';
        OPEN o_list FOR
            SELECT c.id_doc_comment idcomm,
                   c.id_doc_external iddoc,
                   c.id_doc_image idimg,
                   c.desc_comment,
                   c.flg_type,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, p.id_professional) insertby,
                   p.id_speciality,
                   pk_prof_utils.get_spec_signature(i_lang, i_prof, p.id_professional, c.dt_comment, de.id_episode) especialidade,
                   pk_date_utils.date_char_tsz(i_lang, c.dt_comment, i_prof.institution, i_prof.software) insertdate,
                   pk_doc.get_comments_line(i_lang, dot.flg_comment_type) comment_desig,
                   c.flg_cancel,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, p2.id_professional) cancelby,
                   p2.id_speciality id_speciality_cancel,
                   pk_prof_utils.get_spec_signature(i_lang, i_prof, p2.id_professional, c.dt_cancel, de.id_episode) especialidade_cancel,
                   pk_date_utils.date_char_tsz(i_lang, c.dt_cancel, i_prof.institution, i_prof.software) canceldate
              FROM doc_comments c
             INNER JOIN doc_external de
                ON c.id_doc_external = de.id_doc_external
             INNER JOIN doc_ori_type dot
                ON de.id_doc_ori_type = dot.id_doc_ori_type
              LEFT JOIN professional p
                ON c.id_professional = p.id_professional
              LEFT JOIN speciality s
                ON p.id_speciality = s.id_speciality
              LEFT JOIN professional p2
                ON c.id_prof_cancel = p2.id_professional
              LEFT JOIN speciality s2
                ON p2.id_speciality = s2.id_speciality
             WHERE c.id_doc_external = i_id_doc
               AND c.flg_cancel = pk_alert_constant.g_no
             ORDER BY flg_cancel, insertdate DESC;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                --Inicialization of object for input 
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                pk_types.open_my_cursor(o_list);
                -- setting language, setting error content into input object, setting package information 
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   g_package_owner,
                                   g_package_name,
                                   'GET_DOC_COMMENTS');
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
                RETURN FALSE;
            END;
    END get_doc_comments;

    FUNCTION get_doc_comments_as_text
    (
        i_id_doc_external IN doc_external.id_doc_external%TYPE,
        i_delimiter       IN VARCHAR2
    ) RETURN VARCHAR2 IS
        l_comments VARCHAR2(4000);
    BEGIN
        SELECT listagg(dc.desc_comment, chr(13) || chr(10)) within GROUP(ORDER BY dc.dt_comment ASC)
          INTO l_comments
          FROM doc_comments dc
         WHERE dc.id_doc_external = i_id_doc_external;
    
        RETURN l_comments;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END;

    FUNCTION get_doc_last_comment
    (
        i_lang         IN NUMBER,
        i_prof         IN profissional,
        i_doc_external IN doc_external.id_doc_external%TYPE
    ) RETURN VARCHAR2 IS
    
        l_comment doc_comments.desc_comment%TYPE;
    
    BEGIN
    
        g_error := 'OPEN doc_comments';
        SELECT desc_comment
          INTO l_comment
          FROM (SELECT row_number() over(PARTITION BY dc.id_doc_external ORDER BY dc.dt_comment DESC) rn,
                       dc.desc_comment
                  FROM doc_comments dc
                 WHERE dc.id_doc_external = i_doc_external
                   AND dc.flg_cancel = g_no
                 ORDER BY dc.dt_comment DESC)
         WHERE rn = 1;
    
        RETURN l_comment;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_doc_last_comment;

    /**
    * Cancels a image
    *
    * @param   I_LANG language associated to the professional executing the request
    * @param   I_PROF  professional, institution and software ids
    * @param   I_ID_IMG  image id
    * @param   O_ERROR an error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  João Sá
    * @version 1.0
    * @since   22-11-2006
    *
    * UPDATED - novos campos dt_cancel e id_prof_cancel. Delete no caso do documento estar pendente
    * @author  Telmo Castro
    * @date    19-12-2007
    *
    * UPDATED - invocar pk_visit.set_first_obs
    * @author Telmo Castro
    * @date   18-01-2008
    */
    FUNCTION cancel_image
    (
        i_lang   IN NUMBER,
        i_prof   IN profissional,
        i_id_img IN NUMBER,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_flg_status      doc_external.flg_status%TYPE;
        l_id_doc_external doc_external.id_doc_external%TYPE;
        l_exception       EXCEPTION;
        l_episode         doc_external.id_episode%TYPE;
        l_patient         doc_external.id_patient%TYPE;
        l_error           t_error_out;
        l_rowids          table_varchar;
    BEGIN
        --Only images can be canceled, reports cannot be canceled
    
        g_error := 'GET FLG_STATUS / I_ID_IMG=' || i_id_img;
        SELECT de.flg_status, de.id_doc_external, de.id_episode, de.id_patient
          INTO l_flg_status, l_id_doc_external, l_episode, l_patient
          FROM doc_external de
         INNER JOIN doc_image di
            ON de.id_doc_external = di.id_doc_external
         WHERE di.id_doc_image = i_id_img;
    
        -- Se o documento ainda está pendente nao interessa manter a imagem
    
        IF l_flg_status = g_doc_pendente
        THEN
            g_error := 'DELETE DOC_IMAGE / I_ID_IMG=' || i_id_img || ', I_PROF.ID=' || i_prof.id ||
                       'I_PROF.INSTITUTION=' || i_prof.institution;
            DELETE doc_image
             WHERE id_doc_image = i_id_img;
        ELSE
            g_error := 'UPDATE  DOC_IMAGE / I_ID_IMG=' || i_id_img || ', I_PROF.ID=' || i_prof.id ||
                       'I_PROF.INSTITUTION=' || i_prof.institution;
            UPDATE doc_image
               SET flg_status = g_img_inactive, dt_cancel = current_timestamp, id_prof_cancel = i_prof.id
             WHERE id_doc_image = i_id_img;
        
            g_error := 'UPDATE  DOC_EXTERNAL / ID_DOC_EXTERNAL=' || l_id_doc_external || ', I_PROF.ID=' || i_prof.id ||
                       'I_PROF.INSTITUTION=' || i_prof.institution;
        
            --  UPDATE doc_external
            --  SET dt_updated = current_timestamp, id_professional_upd = i_prof.id
            --  WHERE id_doc_external = l_id_doc_external
            --  AND flg_status <> pk_doc.g_doc_pendente;
        
            l_rowids := table_varchar();
            g_error  := 'Call ts_doc_external.upd / ID_DOC_EXTERNAL=' || l_id_doc_external || 'FLG_STATUS=' ||
                        pk_doc.g_doc_pendente;
            ts_doc_external.upd(dt_updated_in          => current_timestamp,
                                id_professional_upd_in => i_prof.id,
                                where_in               => 'id_doc_external = ' || l_id_doc_external || '
               AND flg_status <> ''' || pk_doc.g_doc_pendente || '''',
                                handle_error_in        => TRUE,
                                rows_out               => l_rowids);
        
            g_error := 'Call t_data_gov_mnt.process_update';
            t_data_gov_mnt.process_update(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'DOC_EXTERNAL',
                                          i_rowids     => l_rowids,
                                          o_error      => o_error);
        
            --ADT
            g_error := 'UPDATE  DOC_EXTERNAL_HIST / ID_DOC_EXTERNAL=' || l_id_doc_external || ', I_PROF.ID=' ||
                       i_prof.id || 'I_PROF.INSTITUTION=' || i_prof.institution;
            UPDATE doc_external_hist
               SET dt_updated = current_timestamp, id_professional_upd = i_prof.id
             WHERE id_doc_external = l_id_doc_external
               AND flg_status <> pk_doc.g_doc_pendente;
        
            -- pk_visit.set_first_obs
            g_sysdate := current_timestamp;
            g_error   := 'CALL  PK_VISIT.SET_FIRST_OBS / I_ID_EPISODE=' || l_episode || ', I_PAT=' || l_patient ||
                         ', I_DT_LAST_INTERACTION=' || g_sysdate || ', I_DT_FIRST_OBS=' || g_sysdate || ', I_PROF.ID=' ||
                         i_prof.id || 'I_PROF.INSTITUTION=' || i_prof.institution;
            IF NOT pk_visit.set_first_obs(i_lang                => i_lang,
                                          i_id_episode          => l_episode,
                                          i_pat                 => l_patient,
                                          i_prof                => i_prof,
                                          i_prof_cat_type       => NULL,
                                          i_dt_last_interaction => g_sysdate,
                                          i_dt_first_obs        => g_sysdate,
                                          o_error               => l_error)
            THEN
                RAISE l_exception;
            END IF;
        END IF;
    
        COMMIT;
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_exception THEN
            o_error := l_error;
            pk_utils.undo_changes;
            RETURN FALSE;
        WHEN OTHERS THEN
            DECLARE
                --Inicialization of object for input 
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                -- setting language, setting error content into input object, setting package information 
                l_error_in.set_all(i_lang, SQLCODE, SQLERRM, g_error, g_package_owner, g_package_name, 'CANCEL_IMAGE');
                -- undo changes quando aplicável
                pk_utils.undo_changes;
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
                RETURN FALSE;
            END;
    END cancel_image;

    /**
    * Cancelar lista de imagens
    *
    * @param   I_LANG language associated to the professional executing the request
    * @param   I_PROF  professional, institution and software ids
    * @param   I_ids_images lista com ids das imagens
    * @param   O_ERROR an error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Telmo Castro
    * @version 1.0
    * @since   24-12-2007
    */
    FUNCTION cancel_images
    (
        i_lang       IN NUMBER,
        i_prof       IN profissional,
        i_ids_images IN table_number,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_idi     NUMBER;
        l_my_ex   EXCEPTION;
        l_exerror t_error_out;
    
    BEGIN
        g_error := 'LOOP cancel_images';
    
        l_idi := i_ids_images.first;
        WHILE l_idi IS NOT NULL
        LOOP
            -- se falhar em algum dos cancel individuais interrompe processo
            g_error := 'Call pk_doc.cancel_image / I_ID_IMG=' || i_ids_images(l_idi) || ', I_PROF.ID=' || i_prof.id ||
                       'I_PROF.INSTITUTION=' || i_prof.institution;
            IF NOT cancel_image(i_lang, i_prof, i_ids_images(l_idi), l_exerror)
            THEN
                RAISE l_my_ex;
            END IF;
        
            l_idi := i_ids_images.next(l_idi);
        END LOOP;
        RETURN TRUE;
    EXCEPTION
        WHEN l_my_ex THEN
            o_error := l_exerror;
            pk_utils.undo_changes;
            RETURN FALSE;
        WHEN OTHERS THEN
            DECLARE
                --Inicialization of object for input 
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                -- setting language, setting error content into input object, setting package information 
                l_error_in.set_all(i_lang, SQLCODE, SQLERRM, g_error, g_package_owner, g_package_name, 'CANCEL_IMAGES');
                -- undo changes quando aplicável
                pk_utils.undo_changes;
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
                RETURN FALSE;
            END;
        
    END cancel_images;

    /**
    * Return the parameters needed for the documents upload
    *
    * @param   I_LANG language associated to the professional executing the request
    * @param   I_PROF  professional, institution and software ids
    * @param   O_DOC_PATH init path, path to copy files and max file size allowed
    * @param   O_DOC_FILES allowed files types (name and file extensions)
    * @param   O_SEND_BY list of sending modes
    * @param   O_RECEIVE list of receiving status    
    * @param   O_SEND_PERM sending permissions for this profile
    * @param   O_ERROR an error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  João Sá
    * @version 1.0
    * @since   16-03-2006
    */
    FUNCTION get_doc_path
    (
        i_lang      IN NUMBER,
        i_prof      IN profissional,
        i_btn       IN sys_button_prop.id_sys_button_prop%TYPE,
        o_doc_path  OUT pk_types.cursor_type,
        o_doc_files OUT pk_types.cursor_type,
        o_send_by   OUT pk_types.cursor_type,
        o_received  OUT pk_types.cursor_type,
        o_send_perm OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
        l_ret        BOOLEAN;
        l_my_pt      profile_template.id_profile_template%TYPE;
        my_exception EXCEPTION;
        l_error      t_error_out;
    BEGIN
    
        g_error := 'GET PROFILE';
        l_ret   := get_profile_template(i_lang, i_prof, l_my_pt, o_error);
    
        IF NOT l_ret
        THEN
            RAISE my_exception;
        END IF;
    
        g_error := 'OPEN O_DOC_PATH';
        OPEN o_doc_path FOR
            SELECT pk_sysconfig.get_config('PATH_DOC_INIT', i_prof) path_doc_init,
                   pk_sysconfig.get_config('PATH_DOC_IMPORT', i_prof) path_doc_dest, -- Pasta para fazer a cópia dos ficheiros - flash
                   pk_sysconfig.get_config('DOC_FILE_MAX_SIZE', i_prof) max_size
              FROM dual;
    
        g_error := 'OPEN O_DOC_FILES';
        OPEN o_doc_files FOR
            SELECT sd.desc_val, sd.val
              FROM sys_domain sd
             WHERE sd.code_domain = 'DOC_FILE_TYPE'
               AND sd.flg_available = 'Y'
               AND sd.domain_owner = pk_sysdomain.k_default_schema
               AND sd.id_language = i_lang
             ORDER BY sd.rank;
    
        g_error := 'OPEN O_SEND_BY';
        OPEN o_send_by FOR
            SELECT pk_message.get_message(i_lang, 'COMMON_M002') label, NULL data
              FROM dual
            UNION ALL
            SELECT sd.desc_val label, sd.val data
              FROM sys_domain sd
             WHERE sd.code_domain = 'DOC_EXTERNAL.FLG_SENT_BY'
               AND sd.domain_owner = pk_sysdomain.k_default_schema
               AND sd.flg_available = 'Y'
               AND sd.id_language = i_lang;
    
        g_error := 'OPEN O_RECEIVE';
        OPEN o_received FOR
            SELECT sd.desc_val label, sd.val data, sd.img_name icon
              FROM sys_domain sd
             WHERE sd.code_domain = 'DOC_EXTERNAL.FLG_RECEIVED'
               AND sd.domain_owner = pk_sysdomain.k_default_schema
               AND sd.flg_available = 'Y'
               AND sd.id_language = i_lang;
    
        g_error := 'OPEN O_SEND_PERM';
        OPEN o_send_perm FOR
            SELECT pk_doc.get_config('DOC_CAN_SEND', i_prof, l_my_pt, i_btn) can_send,
                   pk_doc.get_config('DOC_CAN_RECEIVE', i_prof, l_my_pt, i_btn) can_receive
              FROM dual;
    
        RETURN TRUE;
    
    EXCEPTION
    
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_doc_path);
            pk_types.open_my_cursor(o_doc_files);
            pk_types.open_my_cursor(o_send_by);
            pk_types.open_my_cursor(o_send_perm);
        
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     g_package_owner,
                                                     g_package_name,
                                                     'GET_DOC_PATH',
                                                     o_error);
        
    END;

    /******************************************************************************
       OBJECTIVO:   Retornar imagem do documento
       PARAMETROS:  
       Entrada: 
            I_LANG - Idioma
            I_ID_DOC - Id do documento
            I_ID_PAGE - Numero de pagina
       Saida: 
            O_DOC_IMG - imagem
            O_ERROR - erro
       
       CRIAÇÃO: JS 2006/03/16
       NOTAS:
    *********************************************************************************/
    FUNCTION get_blob
    (
        i_id_doc  IN NUMBER,
        i_id_page IN NUMBER,
        i_thumb   IN NUMBER,
        i_prof    IN profissional,
        o_doc_img OUT BLOB,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_lang sys_config.value%TYPE;
    
    BEGIN
    
        l_lang := pk_sysconfig.get_config('LANGUAGE', i_prof);
    
        IF i_thumb = 0
        THEN
            g_error := 'GET IMAGE';
            SELECT doc_img
              INTO o_doc_img
              FROM doc_image
             WHERE id_doc_external = i_id_doc
               AND id_doc_image = i_id_page
            UNION ALL
            SELECT er.rep_binary_file
              FROM epis_report er
             WHERE er.id_doc_external = i_id_doc
               AND er.id_epis_report = i_id_page;
        ELSE
            g_error := 'GET IMAGE THUMBNAIL';
            SELECT doc_img_thumbnail
              INTO o_doc_img
              FROM doc_image
             WHERE id_doc_external = i_id_doc
               AND id_doc_image = i_id_page
            UNION ALL
            SELECT er.epis_report_thumbnail
              FROM epis_report er
             WHERE er.id_doc_external = i_id_doc
               AND er.id_epis_report = i_id_page;
        END IF;
    
        o_doc_img := pk_tech_utils.set_empty_blob(o_doc_img);
    
        RETURN pk_doc_activity.log_document_activity(i_lang            => 2,
                                                     i_prof            => i_prof,
                                                     i_doc_id          => i_id_doc,
                                                     i_operation       => 'VIEW',
                                                     i_source          => 'EHR',
                                                     i_target          => 'EHR',
                                                     i_operation_param => NULL,
                                                     o_error           => o_error);
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_alert_exceptions.process_error(l_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     g_package_owner,
                                                     g_package_name,
                                                     'GET_BLOB',
                                                     o_error);
        
    END get_blob;

    FUNCTION get_num_episode_images
    (
        i_id_episode IN episode.id_episode%TYPE,
        i_id_patient IN patient.id_patient%TYPE
    ) RETURN NUMBER IS
    
        l_ret NUMBER;
    
    BEGIN
    
        SELECT COUNT(1)
          INTO l_ret
          FROM (SELECT de.id_doc_external
                  FROM doc_external de
                  JOIN doc_image di
                    ON de.id_doc_external = di.id_doc_external
                 WHERE de.id_episode = i_id_episode
                   AND de.flg_status = g_doc_active
                   AND di.flg_status = g_doc_active
                UNION
                SELECT de.id_doc_external
                  FROM doc_external de
                  JOIN doc_image di
                    ON de.id_doc_external = di.id_doc_external
                 WHERE (de.id_patient = i_id_patient AND de.id_episode IS NULL)
                   AND de.flg_status = g_doc_active
                   AND di.flg_status = g_doc_active);
    
        IF (l_ret = 0)
        THEN
            l_ret := NULL;
        END IF;
    
        RETURN l_ret;
    END get_num_episode_images;

    /**
    * Get doc_image properties (file_name, mime_type)
    *
    * @param i_lang              language id
    * @param i_prof              professional, software and institution ids
    * @param i_id_img            image id
    * @param o_doc_img_detail    image details
    * @param o_error             an error message
    *
    * @return true (sucess), false (error)
    * @created 14-Jun-2007
    * @author João Sá
    */
    FUNCTION get_doc_image_props
    (
        i_lang          IN NUMBER,
        i_prof          IN profissional,
        i_id_img        IN NUMBER,
        o_doc_img_props OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        l_file_ext doc_file_type.extension%TYPE;
    
    BEGIN
        -- Obter a extensão do ficheiro
        g_error    := 'call get_doc_image_extension';
        l_file_ext := get_doc_image_extension(i_lang, i_prof, i_id_img);
    
        g_error := 'open o_doc_img_detail';
        OPEN o_doc_img_props FOR
            SELECT i.file_name, f.mime_type
              FROM doc_file_type f, doc_image i
             WHERE f.extension = l_file_ext
               AND i.id_doc_image = i_id_img;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_doc_img_props);
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     g_package_owner,
                                                     g_package_name,
                                                     'GET_DOC_IMAGE_PROPS',
                                                     o_error);
    END get_doc_image_props;

    /**
    * Return 'Y' if there's one document with the same doc_type already registered 
    * for the context provided (patient, episode, external_request)and that doc_type can't 
    * be duplicated (FLG_DUPLICATE = 'Y').
    * If the doc_type can be duplicated (FLG_DUPLICATE = 'N') the result is allways 'N'.
    *
    * @param i_lang         language id
    * @param i_prof         professional, software and institution ids
    * @param i_id_patient   the patient id
    * @param i_episode      episode id
    * @param i_ext_req      external request id
    * @param i_doc_type     doc type id
    * @param i_btn          is sys_button_prop
    * @param o_doc_external resulting document id
    * @param o_error        error message           
    *
    * @return true (sucess), false (error)
    * @created 24-Oct-2007
    * @author Joao Sa
    */
    FUNCTION is_doc_type_registered
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_patient  IN patient.id_patient%TYPE,
        i_episode  IN episode.id_episode%TYPE,
        i_ext_req  IN p1_external_request.id_external_request%TYPE,
        i_doc_type IN NUMBER,
        i_btn      IN sys_button_prop.id_sys_button_prop%TYPE
    ) RETURN VARCHAR2 IS
    
        l_doc       doc_external%ROWTYPE;
        l_exception EXCEPTION;
    
        l_error t_error_out;
    
    BEGIN
    
        g_error := 'CALL ID_DOC_REGISTERED';
        IF NOT get_doc_identific(i_lang, i_prof, i_patient, i_episode, i_ext_req, i_doc_type, i_btn, l_doc, l_error)
        THEN
            RAISE l_exception;
        END IF;
    
        IF l_doc.id_doc_external IS NOT NULL
        THEN
            RETURN g_yes;
        ELSE
            RETURN g_no;
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
            g_error := pk_message.get_message(i_lang, 'COMMON_M001') || chr(10) || 'pk_doc.is_doc_registered / ' ||
                       g_error || ' / ' || SQLERRM;
            RETURN NULL;
    END is_doc_type_registered;

    /**
    * inserir/actualizar preferencia do profissional sobre o ori_type presente em doc_types_config 
    * dado pelo parametro i_id_doc_types_config.
    
    * @param i_lang       lingua
    * @param i_idtcs      vector com os ids das configs a dar preferencia (ou nao) - pode ser 1 doc_type ou 1 doc_ori_type ou 1 original ou 1 destination
    * @param i_pref       valor da preferencia. pode ser Y ou N
    * @param i_prof       professional que esta a configurar suas preferencias
    * @param o_error      error output
    
    * @return true (sucess), false (error)
    
    * @author Telmo Castro
    * @created 13-12-2007
    * @version 1.0
    */
    FUNCTION update_pref_prof
    (
        i_lang  IN NUMBER,
        i_idtcs IN table_number,
        i_pref  IN VARCHAR DEFAULT 'Y',
        i_prof  IN profissional,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
        l_idtc NUMBER;
    BEGIN
        g_error := 'MERGE DOC_TYPES_CONFIG_PROF';
    
        l_idtc := i_idtcs.first;
        WHILE l_idtc IS NOT NULL
        LOOP
            -- tenta actualizar...
            UPDATE doc_types_config_prof
               SET flg_view = i_pref
             WHERE id_doc_types_config = i_idtcs(l_idtc)
               AND id_professional = i_prof.id;
            -- se nao conseguiu e' porque ainda nao existia. vai inserir
            IF SQL%ROWCOUNT = 0
            THEN
                INSERT INTO doc_types_config_prof
                    (id_doc_types_config, id_professional, flg_view)
                VALUES
                    (i_idtcs(l_idtc), i_prof.id, i_pref);
            END IF;
        
            l_idtc := i_idtcs.next(l_idtc);
        END LOOP;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'UPDATE_PREF_PROF',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END update_pref_prof;

    /**
    * Obter preferencia (quer ver ou nao) do profissional sobre o elemento representado pelo i_id_doc_types_config
    * Function interna - nao visivel para o exterior
    *
    * @param   i_id_doc_types_config      id da configuracao de que se quer obter a preferencia do prof.
    * @param   i_prof                     professional, institution e software ids
    *
    * @RETURN  Y, N
    * @author  Telmo Castro
    * @version 1.0
    * @since   14-12-2007
    */
    FUNCTION get_pref_prof
    (
        i_id_doc_types_config IN doc_types_config_prof.id_doc_types_config%TYPE,
        i_prof                IN profissional
    ) RETURN VARCHAR2 IS
        l_ret doc_types_config_prof.flg_view%TYPE;
    BEGIN
    
        SELECT flg_view
          INTO l_ret
          FROM doc_types_config_prof
         WHERE id_doc_types_config = i_id_doc_types_config
           AND id_professional = i_prof.id;
    
        IF l_ret IS NULL
        THEN
            RETURN g_doc_config_y;
        END IF;
    
        RETURN l_ret;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN g_doc_config_y;
    END get_pref_prof;

    /******************************************************************************
       OBJECTIVO:   Inserir comentarios a um documento ou imagem
       Neste momento as imagens nao tem comentarios mas o codigo fica preparado para se nalgum momento
       passarem a existir comentarios a imagens especificas
       PARAMETROS:  Entrada: I_LANG              - Língua registada como preferência do profissional
                             I_PROF              - Profissional que altera comentarios 
                             I_ID_DOC_EXTERNAL   - Id do documento
                             I_DOC_IMAGE         - Id da imagem
    
    
                Saida:   O_ERROR       - erro
    
      CRIAÇÃO:
      CRIAÇÃO: Rita Lopes 2007/12/17
    
      * UPDATED: invocacao da pk_visit.set_first_obs
      * @author  Telmo Castro
      * @date    18-01-2008 
    *********************************************************************************/
    FUNCTION set_comments
    (
        i_lang            IN NUMBER,
        i_prof            IN profissional,
        i_id_doc_external IN doc_external.id_doc_external%TYPE,
        i_id_image        IN doc_image.id_doc_image%TYPE,
        i_desc_comment    IN doc_comments.desc_comment%TYPE,
        i_date_comment    IN VARCHAR2,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_flg_type doc_comments.flg_type%TYPE := g_flg_type_d;
        l_episode  doc_external.id_episode%TYPE;
        l_patient  doc_external.id_patient%TYPE;
    
        l_doc_external_row doc_external%ROWTYPE;
    
        l_rowids table_varchar;
    
        l_exception EXCEPTION;
    
    BEGIN
    
        SELECT *
          INTO l_doc_external_row
          FROM doc_external
         WHERE id_doc_external = i_id_doc_external;
    
        l_patient := l_doc_external_row.id_patient;
        l_episode := l_doc_external_row.id_episode;
    
        IF i_date_comment IS NULL
        THEN
            g_sysdate := current_timestamp;
        ELSE
            g_sysdate := pk_date_utils.get_string_tstz(i_lang, i_prof, i_date_comment, NULL);
        END IF;
    
        IF i_id_image IS NOT NULL
        THEN
            l_flg_type := g_flg_type_i;
        END IF;
    
        INSERT INTO doc_comments
            (id_doc_comment, id_doc_external, id_doc_image, desc_comment, flg_type, dt_comment, id_professional)
        VALUES
            (seq_doc_comments.nextval, i_id_doc_external, i_id_image, i_desc_comment, l_flg_type, g_sysdate, i_prof.id);
    
        l_rowids := table_varchar();
    
        l_doc_external_row.dt_updated          := current_timestamp;
        l_doc_external_row.id_professional_upd := i_prof.id;
    
        g_error := 'Call ts_doc_external.upd  / RECORD  L_DOC_EXTERNAL_ROW.ID_DOC_EXTERNAL=' ||
                   l_doc_external_row.id_doc_external;
        ts_doc_external.upd(rec_in => l_doc_external_row, handle_error_in => TRUE, rows_out => l_rowids);
    
        g_error := 'Call t_data_gov_mnt.process_update';
        t_data_gov_mnt.process_update(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'DOC_EXTERNAL',
                                      i_rowids     => l_rowids,
                                      o_error      => o_error);
    
        UPDATE doc_external_hist
           SET dt_updated = current_timestamp, id_professional_upd = i_prof.id
         WHERE id_doc_external = i_id_doc_external
           AND flg_status <> g_doc_pendente;
    
        -- pk_visit.set_first_obs
        g_sysdate := current_timestamp;
    
        IF i_prof.software != g_referral -- para o referral na deve chamar o pk_visit.set_first_obs
        THEN
            IF NOT pk_visit.set_first_obs(i_lang                => i_lang,
                                          i_id_episode          => l_episode,
                                          i_pat                 => l_patient,
                                          i_prof                => i_prof,
                                          i_prof_cat_type       => NULL,
                                          i_dt_last_interaction => g_sysdate,
                                          i_dt_first_obs        => g_sysdate,
                                          o_error               => o_error)
            THEN
                RAISE l_exception;
            END IF;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_COMMENTS',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_comments;

    /**
    * Get ori type list for the viewer 'all' filter
    *
    * @param   I_LANG    language associated to the professional executing the request
    * @param   I_PROF    professional, institution and software ids
    * @param   I_PATIENT patient id
    * @param   I_EPISODE episode id
    * @param   I_EXT_REQ referral id        
    * @param   I_BTN     sys_button used to allow diferent behaviours depending on the button being used.
    * @param   O_LIST    output list
    * @param   O_ERROR   an error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Telmo Castro
    * @version 1.0
    * @since   17-12-2007
    *
    * UPDATED passa a contar com os docs inactivos (nao confundir com os oldversion)
    * @author Telmo Castro
    * @since  11-01-2008
    */
    FUNCTION get_doc_viewer_all
    (
        i_lang    IN NUMBER,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        i_episode IN episode.id_episode%TYPE,
        i_ext_req IN p1_external_request.id_external_request%TYPE,
        i_btn     IN sys_button_prop.id_sys_button_prop%TYPE,
        o_list    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_ret        BOOLEAN;
        my_exception EXCEPTION;
        l_patient    patient.id_patient%TYPE;
        l_episode    episode.id_episode%TYPE;
        l_ext_req    p1_external_request.id_external_request%TYPE;
        l_my_pt      profile_template.id_profile_template%TYPE;
    BEGIN
    
        g_error := 'GET PROFILE';
        l_ret   := get_profile_template(i_lang, i_prof, l_my_pt, o_error);
    
        IF NOT l_ret
        THEN
            RAISE my_exception;
        END IF;
    
        -- Validate context (Patient, Episode and External Request)
        SELECT decode(pk_doc.get_config('DOC_PATIENT', i_prof, l_my_pt, i_btn), g_doc_config_y, i_patient, NULL),
               decode(pk_doc.get_config('DOC_EPISODE', i_prof, l_my_pt, i_btn), g_doc_config_y, i_episode, NULL),
               decode(pk_doc.get_config('DOC_REFERRAL', i_prof, l_my_pt, i_btn), g_doc_config_y, i_ext_req, NULL)
          INTO l_patient, l_episode, l_ext_req
          FROM dual;
    
        g_error := 'OPEN O_LIST';
        OPEN o_list FOR
            SELECT um.*, pk_doc.get_pref_prof(um.idtc, i_prof) checked
              FROM (SELECT pk_doc.get_types_config_id(NULL, dot.id_doc_ori_type, NULL, NULL, i_prof, l_my_pt, i_btn) idtc,
                           dot.id_doc_ori_type,
                           pk_translation.get_translation(i_lang, dot.code_doc_ori_type) oritypedesc,
                           COUNT(*) numdocs
                      FROM doc_type dt
                      JOIN doc_external de
                        ON (dt.id_doc_type = de.id_doc_type)
                      JOIN doc_ori_type dot
                        ON (de.id_doc_ori_type = dot.id_doc_ori_type)
                     WHERE ((de.id_patient = l_patient) OR (de.id_episode = l_episode) OR
                           (de.id_external_request = l_ext_req))
                       AND de.flg_status IN (g_doc_active, g_doc_inactive)
                       AND pk_doc.get_types_config_visible(dt.id_doc_type, NULL, NULL, NULL, i_prof, l_my_pt, i_btn) =
                           g_doc_config_y
                       AND pk_doc.get_types_config_visible(NULL, dot.id_doc_ori_type, NULL, NULL, i_prof, l_my_pt, i_btn) =
                           g_doc_config_y
                     GROUP BY pk_doc.get_types_config_id(NULL, dot.id_doc_ori_type, NULL, NULL, i_prof, l_my_pt, i_btn),
                              dot.id_doc_ori_type,
                              pk_translation.get_translation(i_lang, dot.code_doc_ori_type)
                     ORDER BY oritypedesc) um;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_list);
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     g_package_owner,
                                                     g_package_name,
                                                     'GET_DOC_VIEWER_ALL',
                                                     o_error);
    END get_doc_viewer_all;

    /**
    * Get ori type list for the viewer 'last 10' filter
    *
    * @param   I_LANG    language associated to the professional executing the request
    * @param   I_PROF    professional, institution and software ids
    * @param   I_PATIENT patient id
    * @param   I_EPISODE episode id
    * @param   I_EXT_REQ referral id        
    * @param   I_BTN     sys_button used to allow diferent behaviours depending on the button being used.
    * @param   I_QUANT   quantos devolver
    * @param   O_LIST    output list
    * @param   O_ERROR   an error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Telmo Castro
    * @version 1.0
    * @since   17-12-2007
    *
    * UPDATED passa a contar com os docs inactivos (nao confundir com os oldversion)
    * @author Telmo Castro
    * @since  11-01-2008
    */
    FUNCTION get_doc_viewer_last10
    (
        i_lang    IN NUMBER,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        i_episode IN episode.id_episode%TYPE,
        i_ext_req IN p1_external_request.id_external_request%TYPE,
        i_btn     IN sys_button_prop.id_sys_button_prop%TYPE,
        i_quant   IN NUMBER DEFAULT 10,
        o_list    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_ret        BOOLEAN;
        my_exception EXCEPTION;
        l_patient    patient.id_patient%TYPE;
        l_episode    episode.id_episode%TYPE;
        l_ext_req    p1_external_request.id_external_request%TYPE;
        l_my_pt      profile_template.id_profile_template%TYPE;
    BEGIN
    
        g_error := 'GET PROFILE';
        l_ret   := get_profile_template(i_lang, i_prof, l_my_pt, o_error);
    
        IF NOT l_ret
        THEN
            RAISE my_exception;
        END IF;
    
        -- Validate context (Patient, Episode and External Request)
        SELECT decode(pk_doc.get_config('DOC_PATIENT', i_prof, l_my_pt, i_btn), g_doc_config_y, i_patient, NULL),
               decode(pk_doc.get_config('DOC_EPISODE', i_prof, l_my_pt, i_btn), g_doc_config_y, i_episode, NULL),
               decode(pk_doc.get_config('DOC_REFERRAL', i_prof, l_my_pt, i_btn), g_doc_config_y, i_ext_req, NULL)
          INTO l_patient, l_episode, l_ext_req
          FROM dual;
    
        g_error := 'OPEN O_LIST';
        OPEN o_list FOR
            SELECT three.*, pk_doc.get_pref_prof(three.idtc, i_prof) checked
              FROM (SELECT pk_doc.get_types_config_id(NULL, two.id_doc_ori_type, NULL, NULL, i_prof, l_my_pt, i_btn) idtc,
                           two.id_doc_ori_type,
                           pk_translation.get_translation(i_lang, two.code_doc_ori_type) oritypedesc,
                           COUNT(*) numdocs
                      FROM (SELECT dot.id_doc_ori_type, dot.code_doc_ori_type
                              FROM doc_type dt
                              JOIN doc_external de
                                ON (dt.id_doc_type = de.id_doc_type)
                              JOIN doc_ori_type dot
                                ON (de.id_doc_ori_type = dot.id_doc_ori_type)
                             WHERE ((de.id_patient = l_patient) OR (de.id_episode = l_episode) OR
                                   (de.id_external_request = l_ext_req))
                               AND de.flg_status IN (g_doc_active, g_doc_inactive)
                               AND pk_doc.get_types_config_visible(dt.id_doc_type,
                                                                   NULL,
                                                                   NULL,
                                                                   NULL,
                                                                   i_prof,
                                                                   l_my_pt,
                                                                   i_btn) = g_doc_config_y
                               AND pk_doc.get_types_config_visible(NULL,
                                                                   dot.id_doc_ori_type,
                                                                   NULL,
                                                                   NULL,
                                                                   i_prof,
                                                                   l_my_pt,
                                                                   i_btn) = g_doc_config_y
                               AND rownum <= i_quant
                             ORDER BY de.dt_inserted DESC) two
                     GROUP BY pk_doc.get_types_config_id(NULL, two.id_doc_ori_type, NULL, NULL, i_prof, l_my_pt, i_btn),
                              two.id_doc_ori_type,
                              pk_translation.get_translation(i_lang, two.code_doc_ori_type)
                     ORDER BY oritypedesc) three;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_list);
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     g_package_owner,
                                                     g_package_name,
                                                     'GET_DOC_VIEWER_LAST10',
                                                     o_error);
    END get_doc_viewer_last10;

    /**
     * Get ori type list for the viewer 'episode' filter
     *
     * @param   I_LANG    language associated to the professional executing the request
     * @param   I_PROF    professional, institution and software ids
     * @param   I_PATIENT patient id
     * @param   I_EPISODE episode id
     * @param   I_EXT_REQ referral id        
     * @param   I_BTN     sys_button used to allow diferent behaviours depending on the button being used.
     * @param   O_LIST    output list
     * @param   O_ERROR   an error message, set when return=false
     *
     * @RETURN  TRUE if sucess, FALSE otherwise
     * @author  Telmo Castro
     * @version 1.0
     * @since   17-12-2007
     *
     * UPDATED passa a contar com os docs inactivos (nao confundir com os oldversion)
     * @author Telmo Castro
     * @since  11-01-2008
    */
    FUNCTION get_doc_viewer_epis
    (
        i_lang    IN NUMBER,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        i_episode IN episode.id_episode%TYPE,
        i_ext_req IN p1_external_request.id_external_request%TYPE,
        i_btn     IN sys_button_prop.id_sys_button_prop%TYPE,
        o_list    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        l_ret        BOOLEAN;
        my_exception EXCEPTION;
        l_patient    patient.id_patient%TYPE;
        l_episode    episode.id_episode%TYPE;
        l_ext_req    p1_external_request.id_external_request%TYPE;
        l_my_pt      profile_template.id_profile_template%TYPE;
    BEGIN
    
        g_error := 'GET PROFILE';
        l_ret   := get_profile_template(i_lang, i_prof, l_my_pt, o_error);
    
        IF NOT l_ret
        THEN
            RAISE my_exception;
        END IF;
    
        -- Validate context (Patient, Episode and External Request)
        SELECT decode(pk_doc.get_config('DOC_PATIENT', i_prof, l_my_pt, i_btn), g_doc_config_y, i_patient, NULL),
               decode(pk_doc.get_config('DOC_EPISODE', i_prof, l_my_pt, i_btn), g_doc_config_y, i_episode, NULL),
               decode(pk_doc.get_config('DOC_REFERRAL', i_prof, l_my_pt, i_btn), g_doc_config_y, i_ext_req, NULL)
          INTO l_patient, l_episode, l_ext_req
          FROM dual;
    
        g_error := 'OPEN O_LIST';
        OPEN o_list FOR
            SELECT um.*, pk_doc.get_pref_prof(um.idtc, i_prof) checked
              FROM (SELECT pk_doc.get_types_config_id(NULL, dot.id_doc_ori_type, NULL, NULL, i_prof, l_my_pt, i_btn) idtc,
                           dot.id_doc_ori_type,
                           pk_translation.get_translation(i_lang, dot.code_doc_ori_type) oritypedesc,
                           COUNT(*) numdocs
                      FROM doc_type dt
                      JOIN doc_external de
                        ON (dt.id_doc_type = de.id_doc_type)
                      JOIN doc_ori_type dot
                        ON (de.id_doc_ori_type = dot.id_doc_ori_type)
                     WHERE ((de.id_patient = l_patient)
                           -- JS, 2008-06-30: Neste caso valida sempre por episodio.
                           -- Nao e configuravel porque o botao de filtro no "viewer" nao e configurado na BD.
                           OR (de.id_episode = i_episode) OR (de.id_external_request = l_ext_req))
                       AND de.flg_status IN (g_doc_active, g_doc_inactive)
                       AND pk_doc.get_types_config_visible(dt.id_doc_type, NULL, NULL, NULL, i_prof, l_my_pt, i_btn) =
                           g_doc_config_y
                       AND pk_doc.get_types_config_visible(NULL, dot.id_doc_ori_type, NULL, NULL, i_prof, l_my_pt, i_btn) =
                           g_doc_config_y
                     GROUP BY pk_doc.get_types_config_id(NULL, dot.id_doc_ori_type, NULL, NULL, i_prof, l_my_pt, i_btn),
                              dot.id_doc_ori_type,
                              pk_translation.get_translation(i_lang, dot.code_doc_ori_type)
                     ORDER BY oritypedesc) um;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_list);
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     g_package_owner,
                                                     g_package_name,
                                                     'GET_DOC_VIEWER_EPIS',
                                                     o_error);
            RETURN FALSE;
    END get_doc_viewer_epis;

    /**
    * Get ori type list for the viewer 'with me' filter
    *
    * @param   I_LANG    language associated to the professional executing the request
    * @param   I_PROF    professional, institution and software ids
    * @param   I_PATIENT patient id
    * @param   I_EPISODE episode id
    * @param   I_EXT_REQ referral id        
    * @param   I_BTN     sys_button used to allow diferent behaviours depending on the button being used.
    * @param   O_LIST    output list
    * @param   O_ERROR   an error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Telmo Castro
    * @version 1.0
    * @since   17-12-2007
    *
    * UPDATED passa a contar com os docs inactivos (nao confundir com os oldversion)
    * @author Telmo Castro
    * @since  11-01-2008
    */
    FUNCTION get_doc_viewer_me
    (
        i_lang    IN NUMBER,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        i_episode IN episode.id_episode%TYPE,
        i_ext_req IN p1_external_request.id_external_request%TYPE,
        i_btn     IN sys_button_prop.id_sys_button_prop%TYPE,
        o_list    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        l_ret        BOOLEAN;
        my_exception EXCEPTION;
        l_patient    patient.id_patient%TYPE;
        l_episode    episode.id_episode%TYPE;
        l_ext_req    p1_external_request.id_external_request%TYPE;
        l_my_pt      profile_template.id_profile_template%TYPE;
    BEGIN
    
        g_error := 'GET PROFILE';
        l_ret   := get_profile_template(i_lang, i_prof, l_my_pt, o_error);
    
        IF NOT l_ret
        THEN
            RAISE my_exception;
        END IF;
    
        -- Validate context (Patient, Episode and External Request)
        SELECT decode(pk_doc.get_config('DOC_PATIENT', i_prof, l_my_pt, i_btn), g_doc_config_y, i_patient, NULL),
               decode(pk_doc.get_config('DOC_EPISODE', i_prof, l_my_pt, i_btn), g_doc_config_y, i_episode, NULL),
               decode(pk_doc.get_config('DOC_REFERRAL', i_prof, l_my_pt, i_btn), g_doc_config_y, i_ext_req, NULL)
          INTO l_patient, l_episode, l_ext_req
          FROM dual;
    
        g_error := 'OPEN O_LIST';
        OPEN o_list FOR
            SELECT um.*, pk_doc.get_pref_prof(um.idtc, i_prof) checked
              FROM (SELECT pk_doc.get_types_config_id(NULL, dot.id_doc_ori_type, NULL, NULL, i_prof, l_my_pt, i_btn) idtc,
                           dot.id_doc_ori_type,
                           pk_translation.get_translation(i_lang, dot.code_doc_ori_type) oritypedesc,
                           COUNT(*) numdocs
                      FROM doc_type dt
                      JOIN doc_external de
                        ON (dt.id_doc_type = de.id_doc_type)
                      JOIN doc_ori_type dot
                        ON (de.id_doc_ori_type = dot.id_doc_ori_type)
                     WHERE ((de.id_patient = l_patient) OR (de.id_episode = l_episode) OR
                           (de.id_external_request = l_ext_req))
                       AND de.flg_status IN (g_doc_active, g_doc_inactive)
                       AND pk_doc.get_types_config_visible(dt.id_doc_type, NULL, NULL, NULL, i_prof, l_my_pt, i_btn) =
                           g_doc_config_y
                       AND pk_doc.get_types_config_visible(NULL, dot.id_doc_ori_type, NULL, NULL, i_prof, l_my_pt, i_btn) =
                           g_doc_config_y
                       AND i_prof.id IN (de.id_professional, de.id_professional_upd)
                     GROUP BY pk_doc.get_types_config_id(NULL, dot.id_doc_ori_type, NULL, NULL, i_prof, l_my_pt, i_btn),
                              dot.id_doc_ori_type,
                              pk_translation.get_translation(i_lang, dot.code_doc_ori_type)
                     ORDER BY oritypedesc) um;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_list);
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     g_package_owner,
                                                     g_package_name,
                                                     'GET_DOC_VIEWER_ME',
                                                     o_error);
    END get_doc_viewer_me;

    /******************************************************************************
       OBJECTIVO:   cancelar um comentario
       PARAMETROS:  Entrada: I_LANG              - Língua registada como preferência do profissional
                             I_PROF              - Profissional que altera comentarios 
                             I_ID_DOC_COMMENTS   - Id do comentario a cancelar
                             I_Type_Reg          - Tipo de cancelamento: E - Editar, C - Cancelar
    
                Saida:   O_ERROR       - erro
    
      CRIAÇÃO:
      CRIAÇÃO: Rita Lopes 2007/12/17
      
      * UPDATED - invocacao do pk_visit.set_first_obs
      * @author   Telmo Castro
      * @date     18-01-2008
    *********************************************************************************/
    FUNCTION cancel_comments
    (
        i_lang            IN NUMBER,
        i_prof            IN profissional,
        i_id_doc_comments IN doc_comments.id_doc_comment%TYPE,
        i_type_reg        IN VARCHAR2,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_exception EXCEPTION;
        l_episode   doc_external.id_episode%TYPE;
        l_patient   doc_external.id_patient%TYPE;
    BEGIN
    
        g_sysdate := current_timestamp;
    
        UPDATE doc_comments dc
           SET dc.flg_cancel = g_flg_cancel_y, dc.dt_cancel = g_sysdate, dc.id_prof_cancel = i_prof.id
         WHERE dc.id_doc_comment = i_id_doc_comments;
    
        IF i_type_reg = 'E'
        THEN
            COMMIT;
        END IF;
    
        -- pk_visit.set_first_obs
        -- obter primeiro os 2 ids
        SELECT id_patient, id_episode
          INTO l_patient, l_episode
          FROM doc_external de
         INNER JOIN doc_comments dc
            ON de.id_doc_external = dc.id_doc_external
         WHERE dc.id_doc_comment = i_id_doc_comments;
    
        g_sysdate := current_timestamp;
        IF NOT pk_visit.set_first_obs(i_lang                => i_lang,
                                      i_id_episode          => l_episode,
                                      i_pat                 => l_patient,
                                      i_prof                => i_prof,
                                      i_prof_cat_type       => NULL,
                                      i_dt_last_interaction => g_sysdate,
                                      i_dt_first_obs        => g_sysdate,
                                      o_error               => o_error)
        THEN
            RAISE l_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'CANCEL_COMMENTS',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
    END cancel_comments;

    /******************************************************************************
       OBJECTIVO:   editar um comentario
       PARAMETROS:  Entrada: I_LANG              - Língua registada como preferência do profissional
                             I_PROF              - Profissional que altera comentarios 
                             I_ID_DOC_EXTERNAL   - ID do documento
                             I_ID_IMAGE          - ID da imagem
                             I_DESC_COMMENT      - Descritivo do comentario
                             I_ID_DOC_COMMENTS   - Id do comentario a cancelar
                             I_Type_Reg          - Tipo de cancelamento: E - Editar, C - Cancelar
    
                Saida:   O_ERROR       - erro
    
      CRIAÇÃO: Rita Lopes 2007/12/17
      NOTAS:
      
      * UPDATED - update da data e prof de update na doc_external
      * @author Telmo Castro 
      * @date   2007/12/20
      
      * UPDATED - invocacao do pk_visit.set_first_obs
      * @author   Telmo Castro
      * @date     18-01-2008
    *********************************************************************************/
    FUNCTION update_comments
    (
        i_lang            IN NUMBER,
        i_prof            IN profissional,
        i_id_doc_external IN doc_comments.id_doc_external%TYPE,
        i_id_image        IN doc_comments.id_doc_image%TYPE,
        i_desc_comment    IN doc_comments.desc_comment%TYPE,
        i_id_doc_comments IN doc_comments.id_doc_comment%TYPE,
        i_type_reg        IN VARCHAR2,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_exception EXCEPTION;
        l_error     NUMBER;
    
        l_patient doc_external.id_patient%TYPE;
        l_episode doc_external.id_episode%TYPE;
    
        l_doc_external_row doc_external%ROWTYPE;
        l_rowids           table_varchar;
    
        l_id_doc_comments doc_comments.id_doc_comment%TYPE;
    
    BEGIN
    
        g_sysdate := current_timestamp;
        SELECT *
          INTO l_doc_external_row
          FROM doc_external
         WHERE id_doc_external = i_id_doc_external
           AND flg_status <> g_doc_pendente;
    
        l_doc_external_row.dt_updated          := current_timestamp;
        l_doc_external_row.id_professional_upd := i_prof.id;
    
        l_episode := l_doc_external_row.id_episode;
        l_patient := l_doc_external_row.id_patient;
    
        IF i_id_doc_comments IS NULL
        THEN
            BEGIN
                SELECT a.id_doc_comment
                  INTO l_id_doc_comments
                  FROM doc_comments a
                 WHERE a.id_doc_external = i_id_doc_external;
            EXCEPTION
                WHEN no_data_found THEN
                    RETURN TRUE;
            END;
        
        END IF;
    
        IF NOT pk_doc.cancel_comments(i_lang            => i_lang,
                                      i_prof            => i_prof,
                                      i_id_doc_comments => nvl(i_id_doc_comments, l_id_doc_comments),
                                      i_type_reg        => 'E',
                                      o_error           => o_error)
        THEN
            RAISE l_exception;
        END IF;
    
        IF NOT pk_doc.set_comments(i_lang            => i_lang,
                                   i_prof            => i_prof,
                                   i_id_doc_external => i_id_doc_external,
                                   i_id_image        => i_id_image,
                                   i_desc_comment    => i_desc_comment,
                                   i_date_comment    => g_sysdate,
                                   o_error           => o_error)
        
        THEN
            RAISE l_exception;
        END IF;
    
        -- update da data e id_prof no documento
        -- UPDATE doc_external
        --   SET dt_updated = current_timestamp, id_professional_upd = i_prof.id
        -- WHERE id_doc_external = i_id_doc_external
        --   AND flg_status <> g_doc_pendente
        -- RETURNING id_episode, id_patient INTO l_episode, l_patient;*/
    
        l_rowids := table_varchar();
        g_error  := 'Call ts_doc_external.upd  / RECORD  L_DOC_EXTERNAL_ROW.ID_DOC_EXTERNAL=' ||
                    l_doc_external_row.id_doc_external;
        ts_doc_external.upd(rec_in => l_doc_external_row, handle_error_in => TRUE, rows_out => l_rowids);
    
        g_error := 'Call t_data_gov_mnt.process_update';
        t_data_gov_mnt.process_update(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'DOC_EXTERNAL',
                                      i_rowids     => l_rowids,
                                      o_error      => o_error);
    
        UPDATE doc_external_hist
           SET dt_updated = current_timestamp, id_professional_upd = i_prof.id
         WHERE id_doc_external = i_id_doc_external
           AND flg_status <> g_doc_pendente;
    
        -- pk_visit.set_first_obs
        g_sysdate := current_timestamp;
        IF NOT pk_visit.set_first_obs(i_lang                => i_lang,
                                      i_id_episode          => l_episode,
                                      i_pat                 => l_patient,
                                      i_prof                => i_prof,
                                      i_prof_cat_type       => NULL,
                                      i_dt_last_interaction => g_sysdate,
                                      i_dt_first_obs        => g_sysdate,
                                      o_error               => o_error)
        THEN
            RAISE l_exception;
        END IF;
    
        COMMIT;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'UPDATE_COMMENTS',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
    END update_comments;

    /******************************************************************************
       OBJECTIVO:   Detalhe de comentarios de um documento
       PARAMETROS:  Entrada: I_LANG              - Língua registada como preferência do profissional
                             I_PROF              - Profissional que altera comentarios 
                             I_ID_DOC_EXTERNAL   - ID do documento
    
                Saida:  o_comments_det  - cursor com o detalhe
                        O_ERROR         - erro
    
      CRIAÇÃO:
      CRIAÇÃO: Rita Lopes 2007/12/18
      NOTAS:
    *********************************************************************************/
    FUNCTION get_comments_det
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_doc_external IN doc_comments.id_doc_external%TYPE,
        o_comments_det    OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'OPEN O_COMMENTS_DET';
        OPEN o_comments_det FOR
            SELECT dc.desc_comment,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, p.id_professional) nick_name,
                   pk_date_utils.date_char_tsz(i_lang, dc.dt_comment, i_prof.institution, i_prof.software) prof_date
              FROM doc_comments dc, professional p
             WHERE dc.id_doc_external = i_id_doc_external
               AND dc.flg_cancel IS NULL
               AND dc.id_professional = p.id_professional
             ORDER BY prof_date;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_comments_det);
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     g_package_owner,
                                                     g_package_name,
                                                     'GET_COMMENTS_DET',
                                                     o_error);
    END;

    /**
    * Inicializar novo documento. Serve apenas para gerar um id_doc_external (chave da doc_external).
    * O registo com esse id e' usado pela top tier para ir armazenando as imagens. Os dados sao gravados
    * apenas quando se carrega no ok, o que vai chamar o update_closedoc. Ver mais info no create_savedoc.
    *
    * @param   I_LANG    language associated to the professional executing the request
    * @param   I_PROF    professional, institution and software ids
    * @param   I_PATIENT patient id
    * @param   I_BTN     sys_button used to allow diferent behaviours depending on the button being used.
    * @param   I_ID_GRUPO  id que identifica as versoes deste documento
    * @param   I_INTERNAL_COMMIT commit/rollback is performed in this function
    * @param   O_LIST    output list
    * @param   O_ERROR   an error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Telmo Castro
    * @version 1.0
    * @since   17-12-2007
    */
    FUNCTION create_initdoc
    (
        i_lang            IN NUMBER,
        i_prof            IN profissional,
        i_patient         IN doc_external.id_patient%TYPE,
        i_episode         IN doc_external.id_episode%TYPE,
        i_ext_req         IN doc_external.id_external_request%TYPE,
        i_btn             IN sys_button_prop.id_sys_button_prop%TYPE,
        i_id_grupo        IN doc_external.id_grupo%TYPE,
        i_internal_commit IN BOOLEAN,
        o_id_doc          OUT NUMBER,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_ret                BOOLEAN;
        my_exception         EXCEPTION;
        l_patient            patient.id_patient%TYPE;
        l_episode            episode.id_episode%TYPE;
        l_ext_req            p1_external_request.id_external_request%TYPE;
        l_id_doc_type        doc_type.id_doc_type%TYPE;
        l_id_doc_ori_type    doc_ori_type.id_doc_ori_type%TYPE;
        l_id_doc_destination doc_destination.id_doc_destination%TYPE;
        l_my_pt              profile_template.id_profile_template%TYPE;
    
        l_doc_external_row doc_external%ROWTYPE;
        l_rowids           table_varchar;
    
        l_exception EXCEPTION;
    
    BEGIN
        g_sysdate := current_timestamp;
        -- get profile
        g_error := 'GET PROFILE';
        l_ret   := get_profile_template(i_lang, i_prof, l_my_pt, o_error);
        IF NOT l_ret
        THEN
            RAISE my_exception;
        END IF;
    
        -- Validate context (Patient, Episode and External Request)
        SELECT decode(pk_doc.get_config('DOC_PATIENT', i_prof, l_my_pt, i_btn), g_doc_config_y, i_patient, NULL),
               decode(pk_doc.get_config('DOC_EPISODE', i_prof, l_my_pt, i_btn), g_doc_config_y, i_episode, NULL),
               decode(pk_doc.get_config('DOC_REFERRAL', i_prof, l_my_pt, i_btn), g_doc_config_y, i_ext_req, NULL)
          INTO l_patient, l_episode, l_ext_req
          FROM dual;
    
        -- obter valores basicos para id_doc_type, id_doc_ori_type e id_doc_destination para satisfazer as suas
        -- check constraints do tipo not null
        -- doc ori type
        g_error := 'get id_doc_type and id_doc_ori_type';
        SELECT dtc.id_doc_type, dtc.id_doc_ori_type_parent
          INTO l_id_doc_type, l_id_doc_ori_type
          FROM doc_types_config dtc
         WHERE id_doc_type IS NOT NULL
           AND dtc.id_software IN (i_prof.software, 0)
           AND dtc.id_institution IN (i_prof.institution, 0)
           AND dtc.id_profile_template IN (l_my_pt, 0)
           AND dtc.id_sys_button_prop IN (i_btn, 0)
           AND rownum <= 1
         ORDER BY id_software DESC, id_institution DESC, id_profile_template DESC, id_sys_button_prop DESC;
    
        -- doc destination
        g_error := 'get id_destination';
        SELECT dtc.id_doc_destination
          INTO l_id_doc_destination
          FROM doc_types_config dtc
         WHERE id_doc_destination IS NOT NULL
           AND dtc.id_software IN (i_prof.software, 0)
           AND dtc.id_institution IN (i_prof.institution, 0)
           AND dtc.id_profile_template IN (l_my_pt, 0)
           AND dtc.id_sys_button_prop IN (i_btn, 0)
           AND rownum <= 1
         ORDER BY id_software DESC, id_institution DESC, id_profile_template DESC, id_sys_button_prop DESC;
    
        -- insert
        g_error := 'INSERT INTO DOC_EXTERNAL';
    
        o_id_doc                               := ts_doc_external.next_key();
        l_doc_external_row.id_doc_external     := o_id_doc;
        l_doc_external_row.id_doc_type         := l_id_doc_type;
        l_doc_external_row.id_doc_ori_type     := l_id_doc_ori_type;
        l_doc_external_row.id_doc_destination  := l_id_doc_destination;
        l_doc_external_row.id_professional     := i_prof.id;
        l_doc_external_row.id_institution      := i_prof.institution;
        l_doc_external_row.flg_status          := g_doc_pendente;
        l_doc_external_row.dt_inserted         := g_sysdate;
        l_doc_external_row.dt_updated          := g_sysdate;
        l_doc_external_row.id_grupo            := nvl(i_id_grupo, o_id_doc);
        l_doc_external_row.id_external_request := l_ext_req;
        l_doc_external_row.id_episode          := l_episode;
    
        g_error := 'INSERT DOC_EXTERNAL';
        ts_doc_external.ins(rec_in => l_doc_external_row, handle_error_in => TRUE, rows_out => l_rowids);
    
        g_error := 'Process_insert DOC_EXTERNAL';
        t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'DOC_EXTERNAL',
                                      i_rowids     => l_rowids,
                                      o_error      => o_error);
    
        --INSERT INTO doc_external
        --    (id_doc_external,
        --     id_doc_type,
        --     id_doc_ori_type,
        --     id_doc_destination,
        --     id_professional,
        --     id_institution,
        --     flg_status,
        --     dt_inserted,
        --     dt_updated,
        --     id_grupo,
        --     id_external_request,
        --     id_episode)
        -- VALUES
        --    (o_id_doc,
        --     l_id_doc_type,
        --     l_id_doc_ori_type,
        --     l_id_doc_destination,
        --     i_prof.id,
        --     i_prof.institution,
        --     g_doc_pendente,
        --     current_timestamp,
        --     current_timestamp,
        --     nvl(i_id_grupo, o_id_doc),
        --     l_ext_req,
        --     l_episode);
    
        --ADT requirements
        INSERT INTO doc_external_hist
            (id_doc_external_hist,
             id_doc_external,
             id_doc_type,
             id_doc_ori_type,
             id_doc_destination,
             id_professional,
             id_institution,
             flg_status,
             dt_inserted,
             id_grupo,
             operation_type,
             operation_time,
             operation_user)
        VALUES
            (seq_doc_external_hist.nextval * 10000000,
             o_id_doc,
             l_id_doc_type,
             l_id_doc_ori_type,
             l_id_doc_destination,
             i_prof.id,
             i_prof.institution,
             g_doc_pendente,
             current_timestamp,
             nvl(i_id_grupo, o_id_doc),
             'C',
             current_timestamp,
             i_prof.id);
    
        IF NOT set_doc(i_lang            => i_lang,
                       i_id_institution  => i_prof.institution,
                       i_id_doc          => o_id_doc,
                       i_id_professional => i_prof.id,
                       o_error           => o_error)
        THEN
            RAISE my_exception;
        END IF;
    
        IF o_id_doc = l_doc_external_row.id_grupo
        THEN
            -- log activity 
            g_error := 'Error registering document activity';
            IF NOT pk_doc_activity.log_document_activity(i_lang            => i_lang,
                                                         i_prof            => i_prof,
                                                         i_doc_id          => o_id_doc,
                                                         i_operation       => 'CREATE',
                                                         i_source          => 'EHR',
                                                         i_target          => 'EHR',
                                                         i_operation_param => NULL,
                                                         o_error           => o_error)
            THEN
                RAISE l_exception;
            END IF;
        END IF;
    
        -- aqui optei por nao invocar a pk_visit.set_first_obs porque nesta fase o documento esta pendente
    
        IF i_internal_commit
        THEN
            COMMIT;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
        
            IF i_internal_commit
            THEN
                pk_utils.undo_changes;
            END IF;
        
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'CREATE_INITDOC',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
        
            RETURN FALSE;
    END create_initdoc;

    /**
    * Gravaçao do documento. 
    * Todos os dados excepto as imagens(que foram sendo gravadas entre o init e o close) sao gravados aqui.
    * Este é um circuito alternativo ao create_doc, necessario para esta versao.
    * 
    * @param   i_id_doc              id do documento a fechar
    * @param   I_LANG                language associated to the professional executing the request
    * @param   I_PROF                professional, institution and software ids
    * @param   I_PATIENT             patient id
    * @param   I_EPISODE             episode id
    * @param   I_EXT_REQ             external request id
    * @param   I_DOC_TYPE            tipo documento
    * @param   I_DESC_DOC_TYPE       descriçao manual do tipo documento
    * @param   i_num_doc             numero do documento original
    * @param   i_dt_doc              data emissao do doc. original
    * @param   i_dt_expire           validade do doc. original
    * @param   i_dest                destination id
    * @param   i_desc_dest           descriçao manual da destination
    * @param   i_ori_type            doc_ori_type id
    * @param   i_desc_ori_doc_type   descriçao manual do ori_type
    * @param   i_original            doc_original id
    * @param   i_desc_original       descriçao manual do original
    * @param   i_btn                 contexto
    * @param   i_title               descritivo manual do doc.
    * @param   i_flg_sent_by         info sobre o carrier do doc
    * @param   i_flg_received        indica se recebeu o documento    
    * @param   i_prof_perf_by        id do profissional escolhido no performed by
    * @param   i_desc_perf_by        descricao manual do performed by
    * @param   o_error               an error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Telmo Castro
    * @version 1.0
    * @since   18-12-2007
    *
    * UPDATED - invocacao da pk_visit.set_first_obs
    * @author   Telmo Castro
    * @date     18-01-2008
    */
    FUNCTION create_savedoc_internal
    (
        i_id_doc            IN doc_external.id_doc_external%TYPE,
        i_lang              IN NUMBER,
        i_prof              IN profissional,
        i_patient           IN doc_external.id_patient%TYPE,
        i_episode           IN doc_external.id_episode%TYPE,
        i_ext_req           IN doc_external.id_external_request%TYPE,
        i_doc_type          IN doc_external.id_doc_type%TYPE,
        i_desc_doc_type     IN doc_external.desc_doc_type%TYPE,
        i_num_doc           IN doc_external.num_doc%TYPE,
        i_dt_doc            IN doc_external.dt_emited%TYPE,
        i_dt_expire         IN doc_external.dt_expire%TYPE,
        i_dest              IN doc_external.id_doc_destination%TYPE,
        i_desc_dest         IN doc_external.desc_doc_destination%TYPE,
        i_ori_doc_type      IN doc_external.id_doc_ori_type%TYPE,
        i_desc_ori_doc_type IN doc_external.desc_doc_ori_type%TYPE,
        i_original          IN doc_external.id_doc_original%TYPE,
        i_desc_original     IN doc_external.desc_doc_original%TYPE,
        i_btn               IN sys_button_prop.id_sys_button_prop%TYPE,
        i_title             IN doc_external.title%TYPE,
        i_flg_sent_by       IN doc_external.flg_sent_by%TYPE,
        i_flg_received      IN doc_external.flg_received%TYPE,
        i_prof_perf_by      IN doc_external.id_prof_perf_by%TYPE,
        i_desc_perf_by      IN doc_external.desc_perf_by%TYPE,
        --
        i_author             IN doc_external.author%TYPE := NULL,
        i_specialty          IN doc_external.id_specialty%TYPE := NULL,
        i_doc_language       IN doc_external.id_language%TYPE := NULL,
        i_desc_language      IN doc_external.desc_language%TYPE := NULL,
        i_flg_publish        IN VARCHAR2 := NULL,
        i_conf_code          IN table_varchar := table_varchar(),
        i_desc_conf_code     IN table_varchar := table_varchar(),
        i_code_coding_schema IN table_varchar := table_varchar(),
        i_conf_code_set      IN table_varchar := table_varchar(),
        i_desc_conf_code_set IN table_varchar := table_varchar(),
        i_local_emitted      IN doc_external.local_emited%TYPE := NULL,
        i_doc_oid            IN doc_external.doc_oid%TYPE := NULL,
        --
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
        l_ret                  BOOLEAN;
        l_exception            EXCEPTION;
        l_desc_doc_ori_type    doc_external.desc_doc_ori_type%TYPE;
        l_desc_doc_type        doc_external.desc_doc_type%TYPE;
        l_desc_doc_destination doc_external.desc_doc_destination%TYPE;
        l_desc_doc_original    doc_external.desc_doc_original%TYPE;
    
        l_my_pt profile_template.id_profile_template%TYPE;
    
        l_patient doc_external.id_patient%TYPE;
        l_episode doc_external.id_episode%TYPE;
        l_ext_req doc_external.id_external_request%TYPE;
    
        l_flg_status doc_external.flg_status%TYPE;
    
        r_doc              doc_external%ROWTYPE;
        l_doc_original     doc_original.id_doc_original%TYPE;
        l_doc_external_row doc_external%ROWTYPE;
        l_rowids           table_varchar;
    BEGIN
    
        g_error := 'Get default original';
        IF i_original IS NULL
        THEN
            IF NOT get_default_original(i_lang, i_prof, l_doc_original, o_error)
            THEN
                RAISE g_exception;
            END IF;
        ELSE
            l_doc_original := i_original;
        END IF;
    
        g_error := 'GET PROFILE';
        l_ret   := get_profile_template(i_lang, i_prof, l_my_pt, o_error);
    
        IF NOT l_ret
        THEN
            RAISE l_exception;
        END IF;
    
        g_error := 'GET l_doc_external_row';
        SELECT *
          INTO l_doc_external_row
          FROM doc_external
         WHERE id_doc_external = i_id_doc;
    
        -- obter flg_status actual. Se tiver valor pendente passa a activo
        g_error      := 'GET FLG_STATUS';
        l_flg_status := nvl(l_doc_external_row.flg_status, g_doc_pendente);
    
        -- validar ids externos
        SELECT decode(pk_doc.get_config('DOC_PATIENT', i_prof, l_my_pt, i_btn), g_doc_config_y, i_patient, NULL),
               decode(pk_doc.get_config('DOC_EPISODE', i_prof, l_my_pt, i_btn), g_doc_config_y, i_episode, NULL),
               decode(pk_doc.get_config('DOC_REFERRAL', i_prof, l_my_pt, i_btn), g_doc_config_y, i_ext_req, NULL)
          INTO l_patient, l_episode, l_ext_req
          FROM dual;
    
        -- validar as 4 descriçoes manuais
        g_error := 'calculate doc_type desc';
        SELECT decode(get_types_config_other(i_doc_type, NULL, NULL, NULL, i_prof, l_my_pt, i_btn),
                      g_doc_config_y,
                      decode(upper(pk_translation.get_translation(i_lang, code_doc_type)),
                             upper(i_desc_doc_type),
                             NULL,
                             i_desc_doc_type),
                      NULL)
          INTO l_desc_doc_type
          FROM doc_type
         WHERE id_doc_type = i_doc_type;
    
        g_error := 'calculate doc_ori_type desc';
        SELECT decode(get_types_config_other(NULL, i_ori_doc_type, NULL, NULL, i_prof, l_my_pt, i_btn),
                      g_doc_config_y,
                      decode(upper(pk_translation.get_translation(i_lang, code_doc_ori_type)),
                             upper(i_desc_ori_doc_type),
                             NULL,
                             i_desc_ori_doc_type),
                      NULL)
          INTO l_desc_doc_ori_type
          FROM doc_ori_type
         WHERE id_doc_ori_type = i_ori_doc_type;
    
        g_error := 'calculate doc_original desc';
        SELECT decode(get_types_config_other(NULL, NULL, l_doc_original, NULL, i_prof, l_my_pt, i_btn),
                      g_doc_config_y,
                      decode(upper(pk_translation.get_translation(i_lang, code_doc_original)),
                             upper(i_desc_original),
                             NULL,
                             i_desc_original),
                      NULL)
          INTO l_desc_doc_original
          FROM doc_original
         WHERE id_doc_original = l_doc_original;
    
        g_error := 'calculate doc_destination desc';
        IF i_dest IS NOT NULL
        THEN
            SELECT decode(get_types_config_other(NULL, NULL, NULL, i_dest, i_prof, l_my_pt, i_btn),
                          g_doc_config_y,
                          decode(upper(pk_translation.get_translation(i_lang, code_doc_destination)),
                                 upper(i_desc_dest),
                                 NULL,
                                 i_desc_dest),
                          NULL)
              INTO l_desc_doc_destination
              FROM doc_destination
             WHERE id_doc_destination = i_dest;
        END IF;
    
        --update 
        g_error := 'UPDATE DOC_EXTERNAL';
        --     UPDATE doc_external
        --  SET id_doc_type          = i_doc_type,
        --      desc_doc_type        = l_desc_doc_type,
        --      num_doc              = i_num_doc,
        --      dt_emited            = i_dt_doc,
        --      dt_expire            = i_dt_expire,
        --      id_doc_destination   = i_dest,
        --      desc_doc_destination = l_desc_doc_destination,
        --      id_doc_ori_type      = i_ori_doc_type,
        --      desc_doc_ori_type    = l_desc_doc_ori_type,
        --      id_doc_original      = l_doc_original,
        --      desc_doc_original    = l_desc_doc_original,
        --      title                = i_title,
        --      id_patient           = l_patient,
        --      id_episode           = l_episode,
        --      id_external_request  = l_ext_req,
        --      id_institution       = i_prof.institution,
        --      id_professional      = i_prof.id,
        --      -- se estava pendente passa a activo, senao deixa ficar
        --      flg_status  = decode(l_flg_status, g_doc_pendente, g_doc_active, flg_status),
        --      flg_sent_by = i_flg_sent_by,
        --      -- js, 2008-07-02: trata flg_received
        --      flg_received    = decode(i_flg_sent_by, NULL, NULL, decode(i_flg_received, NULL, g_no, i_flg_received)),
        --      id_prof_perf_by = i_prof_perf_by,
        --      desc_perf_by    = i_desc_perf_by,
        --      id_specialty    = i_specialty,
        --      id_language     = i_doc_language,
        --      author          = i_author,
        --      dt_updated      = current_timestamp
        -- WHERE id_doc_external = i_id_doc;
    
        l_doc_external_row.id_doc_type          := i_doc_type;
        l_doc_external_row.desc_doc_type        := l_desc_doc_type;
        l_doc_external_row.num_doc              := i_num_doc;
        l_doc_external_row.dt_emited            := i_dt_doc;
        l_doc_external_row.dt_expire            := i_dt_expire;
        l_doc_external_row.id_doc_destination   := i_dest;
        l_doc_external_row.desc_doc_destination := l_desc_doc_destination;
        l_doc_external_row.id_doc_ori_type      := i_ori_doc_type;
        l_doc_external_row.desc_doc_ori_type    := l_desc_doc_ori_type;
        l_doc_external_row.id_doc_original      := l_doc_original;
        l_doc_external_row.desc_doc_original    := l_desc_doc_original;
        l_doc_external_row.title                := i_title;
        l_doc_external_row.id_patient           := l_patient;
        l_doc_external_row.id_episode           := l_episode;
        l_doc_external_row.id_external_request  := l_ext_req;
        l_doc_external_row.id_institution       := i_prof.institution;
        l_doc_external_row.id_professional      := i_prof.id;
    
        --decode(l_flg_status, g_doc_pendente, g_doc_active, flg_status)
        IF l_flg_status = g_doc_pendente
        THEN
            l_doc_external_row.flg_status := g_doc_active;
        END IF;
    
        l_doc_external_row.flg_sent_by := i_flg_sent_by;
    
        --decode(i_flg_sent_by,NULL,NULL,decode(i_flg_received, NULL, g_no, i_flg_received));
    
        IF i_flg_received IS NULL
        THEN
            IF i_flg_sent_by IS NULL
            THEN
                l_doc_external_row.flg_received := NULL;
            ELSE
                l_doc_external_row.flg_received := g_no;
            END IF;
        ELSE
            l_doc_external_row.flg_received := i_flg_received;
        END IF;
    
        l_doc_external_row.id_prof_perf_by := i_prof_perf_by;
        l_doc_external_row.desc_perf_by    := i_desc_perf_by;
        l_doc_external_row.id_specialty    := i_specialty;
        l_doc_external_row.id_language     := i_doc_language;
        l_doc_external_row.desc_language   := i_desc_language;
        l_doc_external_row.author          := i_author;
        l_doc_external_row.dt_updated      := current_timestamp;
    
        IF i_doc_oid IS NULL
        THEN
            l_doc_external_row.doc_oid := get_doc_oid(i_prof, i_id_doc);
        ELSE
            l_doc_external_row.doc_oid := i_doc_oid;
        END IF;
    
        l_doc_external_row.local_emited := i_local_emitted;
    
        l_rowids := table_varchar();
        g_error  := 'Call ts_doc_external.upd  / RECORD  L_DOC_EXTERNAL_ROW.ID_DOC_EXTERNAL=' ||
                    l_doc_external_row.id_doc_external;
        ts_doc_external.upd(rec_in => l_doc_external_row, handle_error_in => TRUE, rows_out => l_rowids);
    
        g_error := 'Call t_data_gov_mnt.process_update';
        t_data_gov_mnt.process_update(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'DOC_EXTERNAL',
                                      i_rowids     => l_rowids,
                                      o_error      => o_error);
    
        -- ADT
        UPDATE doc_external_hist
           SET id_doc_type          = i_doc_type,
               desc_doc_type        = l_desc_doc_type,
               num_doc              = i_num_doc,
               dt_emited            = i_dt_doc,
               dt_expire            = i_dt_expire,
               id_doc_destination   = i_dest,
               desc_doc_destination = l_desc_doc_destination,
               id_doc_ori_type      = i_ori_doc_type,
               desc_doc_ori_type    = l_desc_doc_ori_type,
               id_doc_original      = l_doc_original,
               desc_doc_original    = l_desc_doc_original,
               title                = i_title,
               id_patient           = l_patient,
               id_episode           = l_episode,
               id_external_request  = l_ext_req,
               id_institution       = i_prof.institution,
               id_professional      = i_prof.id,
               flg_status           = decode(l_flg_status, g_doc_pendente, g_doc_active, flg_status),
               flg_sent_by          = i_flg_sent_by,
               flg_received         = decode(i_flg_sent_by,
                                             NULL,
                                             NULL,
                                             decode(i_flg_received, NULL, g_no, i_flg_received)),
               id_prof_perf_by      = i_prof_perf_by,
               desc_perf_by         = i_desc_perf_by,
               id_language          = i_doc_language,
               desc_language        = i_desc_language
         WHERE id_doc_external = i_id_doc;
    
        -- Código temporario para compatibilidade com ADT a retirar depois 2.5.0.2    
        g_error := 'SET RECORD DOC_EXTERNAL';
    
        r_doc.id_doc_type     := i_doc_type;
        r_doc.id_patient      := l_patient;
        r_doc.num_doc         := i_num_doc;
        r_doc.dt_emited       := i_dt_doc;
        r_doc.id_grupo        := NULL;
        r_doc.dt_expire       := i_dt_expire;
        r_doc.id_doc_external := i_id_doc;
    
        IF l_flg_status = g_doc_pendente
        THEN
            r_doc.flg_status := g_doc_active;
        ELSE
            g_error := 'SET STATUS OF DOC';
        
            SELECT flg_status
              INTO r_doc.flg_status
              FROM doc_external
             WHERE id_doc_external = i_id_doc;
        END IF;
    
        --is the document to be published
        IF i_flg_publish = g_yes
           AND pk_sysconfig.get_config('HIE_ENABLED', i_prof) = 'Y'
        THEN
        
            --Call publish_document
            IF NOT pk_hie_xds.set_submit_or_upd_doc_internal(i_lang,
                                                             i_prof,
                                                             i_id_doc, --i_doc_external  ,
                                                             i_conf_code,
                                                             i_desc_conf_code,
                                                             i_code_coding_schema,
                                                             i_conf_code_set,
                                                             i_desc_conf_code_set,
                                                             o_error)
            THEN
                RAISE l_exception;
            
            END IF;
        
        END IF;
    
        g_error := 'CALLING DOC_EXTERNAL->PAT DOC';
        -- pk_visit.set_first_obs
        g_sysdate := current_timestamp;
        g_error   := 'SET_FIRST_OBS';
        IF l_episode IS NOT NULL
        THEN
            IF i_prof.software != g_referral -- para o referral não deve chamar o pk_visit.set_first_obs
            THEN
                IF NOT pk_visit.set_first_obs(i_lang                => i_lang,
                                              i_id_episode          => l_episode,
                                              i_pat                 => l_patient,
                                              i_prof                => i_prof,
                                              i_prof_cat_type       => NULL,
                                              i_dt_last_interaction => g_sysdate,
                                              i_dt_first_obs        => g_sysdate,
                                              o_error               => o_error)
                THEN
                    RAISE l_exception;
                END IF;
            END IF;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_exception THEN
            RETURN FALSE;
        WHEN OTHERS THEN
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     g_package_owner,
                                                     g_package_name,
                                                     'CREATE_SAVEDOC_INTERNAL',
                                                     o_error);
            RETURN FALSE;
    END create_savedoc_internal;

    FUNCTION create_savedoc
    (
        i_id_doc             IN doc_external.id_doc_external%TYPE,
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_patient            IN doc_external.id_patient%TYPE,
        i_episode            IN doc_external.id_episode%TYPE,
        i_ext_req            IN doc_external.id_external_request%TYPE,
        i_doc_type           IN doc_external.id_doc_type%TYPE,
        i_desc_doc_type      IN doc_external.desc_doc_type%TYPE,
        i_num_doc            IN doc_external.num_doc%TYPE,
        i_dt_doc             IN doc_external.dt_emited%TYPE,
        i_dt_expire          IN doc_external.dt_expire%TYPE,
        i_dest               IN doc_external.id_doc_destination%TYPE,
        i_desc_dest          IN doc_external.desc_doc_destination%TYPE,
        i_ori_doc_type       IN doc_external.id_doc_ori_type%TYPE,
        i_desc_ori_doc_type  IN doc_external.desc_doc_ori_type%TYPE,
        i_original           IN doc_external.id_doc_original%TYPE,
        i_desc_original      IN doc_external.desc_doc_original%TYPE,
        i_btn                IN sys_button_prop.id_sys_button_prop%TYPE,
        i_title              IN doc_external.title%TYPE,
        i_flg_sent_by        IN doc_external.flg_sent_by%TYPE,
        i_flg_received       IN doc_external.flg_received%TYPE,
        i_prof_perf_by       IN doc_external.id_prof_perf_by%TYPE,
        i_desc_perf_by       IN doc_external.desc_perf_by%TYPE,
        i_author             IN doc_external.author%TYPE,
        i_specialty          IN doc_external.id_specialty%TYPE,
        i_doc_language       IN doc_external.id_language%TYPE,
        i_desc_language      IN doc_external.desc_language%TYPE,
        i_flg_publish        IN VARCHAR2,
        i_conf_code          IN table_varchar,
        i_desc_conf_code     IN table_varchar,
        i_code_coding_schema IN table_varchar,
        i_conf_code_set      IN table_varchar,
        i_desc_conf_code_set IN table_varchar,
        i_local_emitted      IN doc_external.local_emited%TYPE,
        i_doc_oid            IN doc_external.doc_oid%TYPE,
        i_internal_commit    IN BOOLEAN,
        i_notes              IN VARCHAR2,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_exception       EXCEPTION;
        l_id_doc_comments table_number;
        l_id_group        NUMBER;
    
    BEGIN
    
        BEGIN
            SELECT a.id_doc_comment
              BULK COLLECT
              INTO l_id_doc_comments
              FROM doc_comments a
             WHERE a.id_doc_external = i_id_doc
               AND a.flg_cancel = pk_alert_constant.g_no;
        EXCEPTION
            WHEN OTHERS THEN
                NULL;
        END;
    
        g_error := 'CREATE DOC';
        IF NOT create_savedoc_internal(i_id_doc             => i_id_doc,
                                       i_lang               => i_lang,
                                       i_prof               => i_prof,
                                       i_patient            => i_patient,
                                       i_episode            => i_episode,
                                       i_ext_req            => i_ext_req,
                                       i_doc_type           => i_doc_type,
                                       i_desc_doc_type      => i_desc_doc_type,
                                       i_num_doc            => i_num_doc,
                                       i_dt_doc             => i_dt_doc,
                                       i_dt_expire          => i_dt_expire,
                                       i_dest               => i_dest,
                                       i_desc_dest          => i_desc_dest,
                                       i_ori_doc_type       => i_ori_doc_type,
                                       i_desc_ori_doc_type  => i_desc_ori_doc_type,
                                       i_original           => i_original,
                                       i_desc_original      => i_desc_original,
                                       i_btn                => i_btn,
                                       i_title              => i_title,
                                       i_flg_sent_by        => i_flg_sent_by,
                                       i_flg_received       => i_flg_received,
                                       i_prof_perf_by       => i_prof_perf_by,
                                       i_desc_perf_by       => i_desc_perf_by,
                                       i_author             => i_author,
                                       i_specialty          => i_specialty,
                                       i_doc_language       => i_doc_language,
                                       i_desc_language      => i_desc_language,
                                       i_flg_publish        => i_flg_publish,
                                       i_conf_code          => i_conf_code,
                                       i_desc_conf_code     => i_desc_conf_code,
                                       i_code_coding_schema => i_code_coding_schema,
                                       i_conf_code_set      => i_conf_code_set,
                                       i_desc_conf_code_set => i_desc_conf_code_set,
                                       i_local_emitted      => i_local_emitted,
                                       i_doc_oid            => i_doc_oid,
                                       o_error              => o_error)
        THEN
            RAISE l_exception;
        END IF;
    
        IF i_internal_commit
        THEN
            COMMIT;
        END IF;
    
        BEGIN
            SELECT id_grupo
              INTO l_id_group
              FROM doc_external
             WHERE id_doc_external = i_id_doc
               AND id_grupo = i_id_doc;
        
            pk_ia_event_common.document_new(i_prof.institution, i_id_doc);
        
        EXCEPTION
            WHEN no_data_found THEN
                NULL;
        END;
    
        IF i_notes IS NOT NULL
        THEN
        
            FOR i IN 1 .. l_id_doc_comments.count
            LOOP
                IF NOT pk_doc.cancel_comments(i_lang            => i_lang,
                                              i_prof            => i_prof,
                                              i_id_doc_comments => l_id_doc_comments(i),
                                              i_type_reg        => NULL,
                                              o_error           => o_error)
                THEN
                    RAISE l_exception;
                END IF;
            END LOOP;
        
            IF NOT pk_doc.set_comments(i_lang            => i_lang,
                                       i_prof            => i_prof,
                                       i_id_doc_external => i_id_doc,
                                       i_id_image        => NULL,
                                       i_desc_comment    => i_notes,
                                       i_date_comment    => NULL,
                                       o_error           => o_error)
            THEN
                RAISE l_exception;
            END IF;
        ELSE
        
            IF l_id_doc_comments IS NOT NULL
               AND l_id_doc_comments.count > 0
            THEN
                FOR i IN 1 .. l_id_doc_comments.count
                LOOP
                    IF NOT pk_doc.cancel_comments(i_lang            => i_lang,
                                                  i_prof            => i_prof,
                                                  i_id_doc_comments => l_id_doc_comments(i),
                                                  i_type_reg        => NULL,
                                                  o_error           => o_error)
                    THEN
                        RAISE l_exception;
                    END IF;
                END LOOP;
            END IF;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_exception THEN
            IF i_internal_commit
            THEN
                pk_utils.undo_changes;
            END IF;
            RETURN FALSE;
        
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'CREATE_SAVEDOC',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
    END create_savedoc;

    /**
    * Gravaçao do documento. 
    * Todos os dados excepto as imagens(que foram sendo gravadas entre o init e o close) sao gravados aqui.
    * Este é um circuito alternativo ao create_doc, necessario para esta versao.
    * 
    * @param   i_id_doc              id do documento a fechar
    * @param   I_LANG                language associated to the professional executing the request
    * @param   I_PROF                professional, institution and software ids
    * @param   I_PATIENT             patient id
    * @param   I_EPISODE             episode id
    * @param   I_EXT_REQ             external request id
    * @param   I_DOC_TYPE            tipo documento
    * @param   I_DESC_DOC_TYPE       descriçao manual do tipo documento
    * @param   i_num_doc             numero do documento original
    * @param   i_dt_doc              data emissao do doc. original
    * @param   i_dt_expire           validade do doc. original
    * @param   i_dest                destination id
    * @param   i_desc_dest           descriçao manual da destination
    * @param   i_ori_type            doc_ori_type id
    * @param   i_desc_ori_doc_type   descriçao manual do ori_type
    * @param   i_original            doc_original id
    * @param   i_desc_original       descriçao manual do original
    * @param   i_btn                 contexto
    * @param   i_title               descritivo manual do doc.
    * @param   i_flg_sent_by         info sobre o carrier do doc
    * @param   i_flg_received        indica se recebeu o documento    
    * @param   i_prof_perf_by        id do profissional escolhido no performed by
    * @param   i_desc_perf_by        descricao manual do performed by
    * @param   o_error               an error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Telmo Castro
    * @version 1.0
    * @since   18-12-2007
    *
    * UPDATED - invocacao da pk_visit.set_first_obs
    * @author   Telmo Castro
    * @date     18-01-2008
    */
    /*FUNCTION create_savedoc
    (
        i_id_doc            IN doc_external.id_doc_external%TYPE,
        i_lang              IN NUMBER,
        i_prof              IN profissional,
        i_patient           IN doc_external.id_patient%TYPE,
        i_episode           IN doc_external.id_episode%TYPE,
        i_ext_req           IN doc_external.id_external_request%TYPE,
        i_doc_type          IN doc_external.id_doc_type%TYPE,
        i_desc_doc_type     IN doc_external.desc_doc_type%TYPE,
        i_num_doc           IN doc_external.num_doc%TYPE,
        i_dt_doc            IN doc_external.dt_emited%TYPE,
        i_dt_expire         IN doc_external.dt_expire%TYPE,
        i_dest              IN doc_external.id_doc_destination%TYPE,
        i_desc_dest         IN doc_external.desc_doc_destination%TYPE,
        i_ori_doc_type      IN doc_external.id_doc_ori_type%TYPE,
        i_desc_ori_doc_type IN doc_external.desc_doc_ori_type%TYPE,
        i_original          IN doc_external.id_doc_original%TYPE,
        i_desc_original     IN doc_external.desc_doc_original%TYPE,
        i_btn               IN sys_button_prop.id_sys_button_prop%TYPE,
        i_title             IN doc_external.title%TYPE,
        i_flg_sent_by       IN doc_external.flg_sent_by%TYPE,
        i_flg_received      IN doc_external.flg_received%TYPE,
        i_prof_perf_by      IN doc_external.id_prof_perf_by%TYPE,
        i_desc_perf_by      IN doc_external.desc_perf_by%TYPE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        RETURN create_savedoc(i_id_doc,
                              i_lang,
                              i_prof,
                              i_patient,
                              i_episode,
                              i_ext_req,
                              i_doc_type,
                              i_desc_doc_type,
                              i_num_doc,
                              i_dt_doc,
                              i_dt_expire,
                              i_dest,
                              i_desc_dest,
                              i_ori_doc_type,
                              i_desc_ori_doc_type,
                              i_original,
                              i_desc_original,
                              i_btn,
                              i_title,
                              i_flg_sent_by,
                              i_flg_received,
                              i_prof_perf_by,
                              i_desc_perf_by,
                              --
                              NULL,
                              NULL,
                              NULL,
                              NULL,
                              NULL,
                              NULL,
                              NULL,
                              NULL,
                              NULL,
                              NULL,
                              NULL,
                              --
                              o_error);
    END create_savedoc;*/

    /**
    * Retorna URL para o thumbnail principal de 1 doc.
    * O thumbnail principal esta na imagem com o rank mais baixo.
    * Funçao local para ser usada nos get_doc_list_xxxx
    *
    * @param i_lang              language id
    * @param i_prof              professional, software and institution ids
    * @param i_id_doc            document id
    *
    * @return varchar2 (sucesso), null (erro ou nao existente)
    * @created 27-12-2007
    * @author Telmo Castro
    */
    FUNCTION get_main_thumb_url
    (
        i_lang   IN NUMBER,
        i_prof   IN profissional,
        i_id_doc IN NUMBER
    ) RETURN VARCHAR2 IS
    
        l_urlbase    VARCHAR2(2000);
        l_repurlbase VARCHAR2(2000);
        l_output     VARCHAR2(2000);
    
    BEGIN
    
        l_urlbase    := pk_sysconfig.get_config('URL_DOC_IMAGE_DEF_THUMBNAIL', i_prof);
        l_repurlbase := pk_sysconfig.get_config('URL_REPORT_THUMBNAIL', i_prof);
    
        SELECT um.url
          INTO l_output
          FROM (SELECT REPLACE(REPLACE(REPLACE(l_urlbase, '@1', i_id_doc), '@2', di.id_doc_image), '@3', '1') url,
                       di.rank rank,
                       di.id_doc_image id_record
                  FROM doc_image di, doc_file_type dt
                 WHERE di.id_doc_external = i_id_doc
                   AND di.flg_status = g_img_active
                   AND di.doc_img IS NOT NULL
                   AND dbms_lob.compare(di.doc_img, empty_blob()) != 0
                   AND lower(dt.extension) = get_doc_image_extension(i_lang, i_prof, di.id_doc_image)
                UNION ALL
                --reports URL is made by concatenating the sys_config with id_epis_report
                SELECT l_repurlbase || id_epis_report url, 0 rank, er.id_epis_report id_record
                  FROM epis_report er
                 WHERE er.id_doc_external = i_id_doc
                   AND (er.flg_status IN ('I', 'D', 'S') OR (er.flg_status = g_no AND er.flg_report_origin = 'D'))
                 ORDER BY rank, id_record) um
         WHERE rownum < 2;
    
        RETURN l_output;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_main_thumb_url;

    FUNCTION get_main_thumb_mime_type
    (
        i_lang   IN NUMBER,
        i_prof   IN profissional,
        i_id_doc IN NUMBER
    ) RETURN VARCHAR2 IS
        l_urlbase VARCHAR2(2000);
        l_output  VARCHAR2(2000);
    BEGIN
    
        SELECT um.mime_type --, um.extension
          INTO l_output
          FROM (SELECT dt.mime_type, di.rank, di.id_doc_image id_record
                  FROM doc_image di, doc_file_type dt
                 WHERE di.id_doc_external = i_id_doc
                   AND di.flg_status = g_img_active
                   AND di.doc_img IS NOT NULL
                   AND dbms_lob.compare(di.doc_img, empty_blob()) != 0
                   AND lower(dt.extension) = get_doc_image_extension(i_lang, i_prof, di.id_doc_image)
                UNION
                SELECT r.mime_type, NULL rank, er.id_epis_report id_record
                  FROM epis_report er
                 INNER JOIN reports r
                    ON r.id_reports = er.id_reports
                 INNER JOIN doc_file_type dt
                    ON dt.mime_type = r.mime_type
                 WHERE er.id_doc_external = i_id_doc
                 ORDER BY rank, id_record) um
         WHERE rownum < 2;
        RETURN l_output;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_main_thumb_mime_type;

    FUNCTION get_main_thumb_extension
    (
        i_lang   IN NUMBER,
        i_prof   IN profissional,
        i_id_doc IN NUMBER
    ) RETURN VARCHAR2 IS
    
        l_urlbase VARCHAR2(2000);
        l_output  VARCHAR2(2000);
    
    BEGIN
    
        SELECT um.extension
          INTO l_output
          FROM (SELECT get_doc_image_extension(i_lang, i_prof, di.id_doc_image) extension,
                       di.rank,
                       di.id_doc_image id_record
                  FROM doc_image di
                 WHERE di.id_doc_external = i_id_doc
                   AND di.flg_status = g_img_active
                UNION
                SELECT dt.extension, NULL rank, er.id_epis_report id_record
                  FROM epis_report er
                 INNER JOIN reports r
                    ON r.id_reports = er.id_reports
                 INNER JOIN doc_file_type dt
                    ON dt.mime_type = r.mime_type
                 WHERE er.id_doc_external = i_id_doc
                 ORDER BY rank, id_record) um
         WHERE rownum < 2;
    
        RETURN l_output;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_main_thumb_extension;

    /**
    * Retorna frase '<designacao>: <valor>' para os get_doc_list_...
    * <designacao> pode ser 'notas' ou 'interpretacoes', dependendo do flg_comm_type.
    * <valor> é o numero de comentarios activos para o documento dado por i_id_doc_external.
    * Funçao local para ser usada nos get_doc_list_xxxx
    *
    * @param i_lang              language id
    * @param i_prof              professional, software and institution ids
    * @param i_id_doc            document id
    * @param i_flg_comm_type      tipo do comentario 
    *
    * @return varchar2 (sucesso ou erro)
    * @created 28-12-2007
    * @author Telmo Castro
    * @version 1.0
    */
    FUNCTION get_comments_line_with_count
    (
        i_lang          IN NUMBER,
        i_prof          IN profissional,
        i_id_doc        IN doc_comments.id_doc_external%TYPE,
        i_flg_comm_type IN doc_ori_type.flg_comment_type%TYPE
    ) RETURN VARCHAR2 IS
    
        l_line VARCHAR2(200);
    
    BEGIN
    
        SELECT get_comments_line(i_lang, i_flg_comm_type) || ': ' ||
               -- count devolve sempre valor. secçao EXCEPTION desnecessaria
                (SELECT to_char(COUNT(1))
                   FROM doc_comments
                  WHERE id_doc_external = i_id_doc
                    AND flg_cancel = g_flg_cancel_n)
          INTO l_line
          FROM dual;
    
        RETURN nvl(l_line, ' ');
    
    END get_comments_line_with_count;

    /**
    * Retorna a designacao formal para os comentarios nos get_doc_list_...
    * A designacao pode ser 'notas' ou 'interpretacoes', dependendo do flg_comm_type.
    *
    * @param i_lang              language id
    * @param i_flg_comm_type     tipo do comentario 
    *
    * @return varchar2 (sucesso ou erro)
    *
    * @created 28-12-2007
    * @author Telmo Castro
    * @version 1.0
    */
    FUNCTION get_comments_line
    (
        i_lang          IN NUMBER,
        i_flg_comm_type IN doc_ori_type.flg_comment_type%TYPE
    ) RETURN VARCHAR2 IS
    
        l_line VARCHAR2(200);
    
    BEGIN
    
        SELECT CASE i_flg_comm_type
                   WHEN g_flg_comm_type_i THEN
                    pk_message.get_message(i_lang, 'DOC_T040')
                   WHEN g_flg_comm_type_n THEN
                    pk_message.get_message(i_lang, 'DOC_T039')
                   ELSE
                   -- se nao encontrou assume que e' uma Nota
                    pk_message.get_message(i_lang, 'DOC_T039')
               END
          INTO l_line
          FROM dual;
    
        RETURN nvl(l_line, ' ');
    
    END get_comments_line;

    /**
    * Get detail list (central pane) for the viewer 'all' filter
    *
    * @param   I_LANG    language associated to the professional executing the request
    * @param   I_PROF    professional, institution and software ids
    * @param   I_PATIENT patient id
    * @param   I_EPISODE episode id
    * @param   I_EXT_REQ referral id        
    * @param   I_BTN     sys_button used to allow diferent behaviours depending on the button being used.
    * @param   O_LIST    output list
    * @param   O_ERROR   an error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Telmo Castro
    * @version 1.0
    * @since   20-12-2007
    */
    FUNCTION get_doc_list_all
    (
        i_lang    IN NUMBER,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        i_episode IN episode.id_episode%TYPE,
        i_ext_req IN p1_external_request.id_external_request%TYPE,
        i_btn     IN sys_button_prop.id_sys_button_prop%TYPE,
        o_list    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_ret        BOOLEAN;
        my_exception EXCEPTION;
        l_patient    patient.id_patient%TYPE;
        l_episode    episode.id_episode%TYPE;
        l_ext_req    p1_external_request.id_external_request%TYPE;
        l_my_pt      profile_template.id_profile_template%TYPE;
    BEGIN
    
        g_error := 'GET PROFILE';
        l_ret   := get_profile_template(i_lang, i_prof, l_my_pt, o_error);
    
        IF NOT l_ret
        THEN
            RAISE my_exception;
        END IF;
    
        -- Validate context (Patient, Episode and External Request)
        SELECT decode(pk_doc.get_config('DOC_PATIENT', i_prof, l_my_pt, i_btn), g_doc_config_y, i_patient, NULL),
               decode(pk_doc.get_config('DOC_EPISODE', i_prof, l_my_pt, i_btn), g_doc_config_y, i_episode, NULL),
               decode(pk_doc.get_config('DOC_REFERRAL', i_prof, l_my_pt, i_btn), g_doc_config_y, i_ext_req, NULL)
          INTO l_patient, l_episode, l_ext_req
          FROM dual;
    
        g_error := 'OPEN O_LIST';
        OPEN o_list FOR
            SELECT dot.id_doc_ori_type,
                   pk_translation.get_translation(i_lang, dot.code_doc_ori_type) oritypedesc,
                   de.title,
                   de.id_doc_external iddoc,
                   pk_doc.get_comments_line_with_count(i_lang, i_prof, de.id_doc_external, dot.flg_comment_type) numcomments,
                   (SELECT COUNT(1)
                      FROM doc_image
                     WHERE id_doc_external = de.id_doc_external
                       AND flg_status = g_img_active) numimages,
                   --                   pk_date_utils.date_time_chr(i_lang, de.dt_emited, i_prof) dt_emited,
                   pk_date_utils.dt_chr(i_lang, de.dt_emited, i_prof) dt_emited,
                   pk_date_utils.date_char_tsz(i_lang,
                                               nvl(de.dt_updated, de.dt_inserted),
                                               i_prof.institution,
                                               i_prof.software) lastupdateddate,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, nvl(de.id_professional_upd, de.id_professional)) lastupdatedby,
                   pk_prof_utils.get_spec_signature(i_lang,
                                                    i_prof,
                                                    nvl(de.id_professional_upd, de.id_professional),
                                                    nvl(de.dt_updated, de.dt_inserted),
                                                    de.id_episode) todo_especialidade,
                   get_main_thumb_url(i_lang, i_prof, de.id_doc_external) url_thumb,
                   de.flg_status,
                   dot.flg_comment_type
              FROM doc_type dt
              JOIN doc_external de
                ON (dt.id_doc_type = de.id_doc_type)
              JOIN doc_ori_type dot
                ON (de.id_doc_ori_type = dot.id_doc_ori_type)
             WHERE ((de.id_patient = l_patient) OR (de.id_episode = l_episode) OR (de.id_external_request = l_ext_req))
               AND de.flg_status IN (g_doc_active, g_doc_inactive)
               AND pk_doc.get_types_config_visible(dt.id_doc_type, NULL, NULL, NULL, i_prof, l_my_pt, i_btn) =
                   g_doc_config_y
               AND pk_doc.get_types_config_visible(NULL, dot.id_doc_ori_type, NULL, NULL, i_prof, l_my_pt, i_btn) =
                   g_doc_config_y
             ORDER BY oritypedesc, de.flg_status ASC, de.dt_emited DESC;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_list);
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     g_package_owner,
                                                     g_package_name,
                                                     'GET_DOC_LIST_ALL',
                                                     o_error);
    END get_doc_list_all;

    /**
    * Get detail list (central pane) for the viewer 'last 10' filter
    *
    * @param   I_LANG    language associated to the professional executing the request
    * @param   I_PROF    professional, institution and software ids
    * @param   I_PATIENT patient id
    * @param   I_EPISODE episode id
    * @param   I_EXT_REQ referral id        
    * @param   I_BTN     sys_button used to allow diferent behaviours depending on the button being used.
    * @param   I_QUANT   considera apenas os ultimos I_QUANT episodios
    * @param   O_LIST    output list
    * @param   O_ERROR   an error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Telmo Castro
    * @version 1.0
    * @since   21-12-2007
    */
    FUNCTION get_doc_list_last10
    (
        i_lang    IN NUMBER,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        i_episode IN episode.id_episode%TYPE,
        i_ext_req IN p1_external_request.id_external_request%TYPE,
        i_btn     IN sys_button_prop.id_sys_button_prop%TYPE,
        i_quant   IN NUMBER DEFAULT 10,
        o_list    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_ret        BOOLEAN;
        my_exception EXCEPTION;
        l_patient    patient.id_patient%TYPE;
        l_episode    episode.id_episode%TYPE;
        l_ext_req    p1_external_request.id_external_request%TYPE;
        l_my_pt      profile_template.id_profile_template%TYPE;
    BEGIN
        g_error := 'GET PROFILE';
        l_ret   := get_profile_template(i_lang, i_prof, l_my_pt, o_error);
    
        IF NOT l_ret
        THEN
            RAISE my_exception;
        END IF;
    
        -- Validate context (Patient, Episode and External Request)
        SELECT decode(pk_doc.get_config('DOC_PATIENT', i_prof, l_my_pt, i_btn), g_doc_config_y, i_patient, NULL),
               decode(pk_doc.get_config('DOC_EPISODE', i_prof, l_my_pt, i_btn), g_doc_config_y, i_episode, NULL),
               decode(pk_doc.get_config('DOC_REFERRAL', i_prof, l_my_pt, i_btn), g_doc_config_y, i_ext_req, NULL)
          INTO l_patient, l_episode, l_ext_req
          FROM dual;
    
        g_error := 'OPEN O_LIST';
        OPEN o_list FOR
            SELECT t.id_doc_ori_type,
                   pk_translation.get_translation(i_lang, t.code_doc_ori_type) oritypedesc,
                   t.title,
                   t.id_doc_external iddoc,
                   pk_doc.get_comments_line_with_count(i_lang, i_prof, t.id_doc_external, t.flg_comment_type) numcomments,
                   (SELECT COUNT(1)
                      FROM doc_image
                     WHERE id_doc_external = t.id_doc_external
                       AND flg_status = g_img_active) numimages,
                   --                   pk_date_utils.date_time_chr(i_lang, t.dt_emited, i_prof) dt_emited,                   
                   pk_date_utils.dt_chr(i_lang, t.dt_emited, i_prof) dt_emited,
                   pk_date_utils.date_char_tsz(i_lang,
                                               nvl(t.dt_updated, t.dt_inserted),
                                               i_prof.institution,
                                               i_prof.software) lastupdateddate,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, nvl(t.id_professional_upd, t.id_professional)) lastupdatedby,
                   pk_prof_utils.get_spec_signature(i_lang,
                                                    i_prof,
                                                    nvl(t.id_professional_upd, t.id_professional),
                                                    nvl(t.dt_updated, t.dt_inserted),
                                                    t.id_episode) todo_especialidade,
                   pk_doc.get_main_thumb_url(i_lang, i_prof, t.id_doc_external) url_thumb,
                   t.flg_status,
                   t.flg_comment_type
              FROM (SELECT dot.id_doc_ori_type,
                           dot.code_doc_ori_type,
                           de.title,
                           de.id_doc_external,
                           dot.flg_comment_type,
                           de.dt_emited,
                           de.dt_updated,
                           de.dt_inserted,
                           de.id_professional_upd,
                           de.id_professional,
                           de.flg_status,
                           de.id_episode
                      FROM doc_type dt
                      JOIN doc_external de
                        ON (dt.id_doc_type = de.id_doc_type)
                      JOIN doc_ori_type dot
                        ON (de.id_doc_ori_type = dot.id_doc_ori_type)
                     WHERE ((de.id_patient = l_patient) OR (de.id_episode = l_episode) OR
                           (de.id_external_request = l_ext_req))
                       AND de.flg_status IN (g_doc_active, g_doc_inactive)
                       AND pk_doc.get_types_config_visible(dt.id_doc_type, NULL, NULL, NULL, i_prof, l_my_pt, i_btn) =
                           g_doc_config_y
                       AND pk_doc.get_types_config_visible(NULL, dot.id_doc_ori_type, NULL, NULL, i_prof, l_my_pt, i_btn) =
                           g_doc_config_y
                       AND rownum <= i_quant
                     ORDER BY de.dt_inserted DESC) t
             ORDER BY oritypedesc, t.flg_status ASC, dt_emited DESC;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_list);
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     g_package_owner,
                                                     g_package_name,
                                                     'GET_DOC_LIST_LAST10',
                                                     o_error);
        
    END get_doc_list_last10;

    /**
    * Get detail list for the viewer 'episode' filter
    *
    * @param   I_LANG    language associated to the professional executing the request
    * @param   I_PROF    professional, institution and software ids
    * @param   I_PATIENT patient id
    * @param   I_EPISODE episode id
    * @param   I_EXT_REQ referral id        
    * @param   I_BTN     sys_button used to allow diferent behaviours depending on the button being used.
    * @param   O_LIST    output list
    * @param   O_ERROR   an error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Telmo Castro
    * @version 1.0
    * @since   21-12-2007
    */
    FUNCTION get_doc_list_epis
    (
        i_lang    IN NUMBER,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        i_episode IN episode.id_episode%TYPE,
        i_ext_req IN p1_external_request.id_external_request%TYPE,
        i_btn     IN sys_button_prop.id_sys_button_prop%TYPE,
        o_list    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        l_ret        BOOLEAN;
        my_exception EXCEPTION;
        l_patient    patient.id_patient%TYPE;
        l_ext_req    p1_external_request.id_external_request%TYPE;
        l_my_pt      profile_template.id_profile_template%TYPE;
    BEGIN
    
        g_error := 'GET PROFILE';
        l_ret   := get_profile_template(i_lang, i_prof, l_my_pt, o_error);
    
        IF NOT l_ret
        THEN
            RAISE my_exception;
        END IF;
    
        -- Validate context (Patient, Episode and External Request)
        SELECT decode(pk_doc.get_config('DOC_PATIENT', i_prof, l_my_pt, i_btn), g_doc_config_y, i_patient, NULL),
               decode(pk_doc.get_config('DOC_EPISODE', i_prof, l_my_pt, i_btn), g_doc_config_y, i_episode, NULL)
          INTO l_patient, l_ext_req
          FROM dual;
    
        g_error := 'OPEN O_LIST';
        OPEN o_list FOR
            SELECT dot.id_doc_ori_type,
                   pk_translation.get_translation(i_lang, dot.code_doc_ori_type) oritypedesc,
                   de.title,
                   de.id_doc_external iddoc,
                   pk_doc.get_comments_line_with_count(i_lang, i_prof, de.id_doc_external, dot.flg_comment_type) numcomments,
                   (SELECT COUNT(1)
                      FROM doc_image
                     WHERE id_doc_external = de.id_doc_external
                       AND flg_status = g_img_active) numimages,
                   --                   pk_date_utils.date_time_chr(i_lang, de.dt_emited, i_prof) dt_emited,
                   pk_date_utils.dt_chr(i_lang, de.dt_emited, i_prof) dt_emited,
                   pk_date_utils.date_char_tsz(i_lang,
                                               nvl(de.dt_updated, de.dt_inserted),
                                               i_prof.institution,
                                               i_prof.software) lastupdateddate,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, nvl(de.id_professional_upd, de.id_professional)) lastupdatedby,
                   pk_prof_utils.get_spec_signature(i_lang,
                                                    i_prof,
                                                    nvl(de.id_professional_upd, de.id_professional),
                                                    nvl(de.dt_updated, de.dt_inserted),
                                                    de.id_episode) todo_especialidade,
                   get_main_thumb_url(i_lang, i_prof, de.id_doc_external) url_thumb,
                   de.flg_status,
                   dot.flg_comment_type
              FROM doc_type dt
              JOIN doc_external de
                ON (dt.id_doc_type = de.id_doc_type)
              JOIN doc_ori_type dot
                ON (de.id_doc_ori_type = dot.id_doc_ori_type)
             WHERE ((de.id_patient = l_patient)
                   -- JS, 2008-06-30: Neste caso valida sempre por episodio.
                   -- Nao e configuravel porque o botao de filtro no "viewer" nao e configurado na BD.
                   OR (de.id_episode = i_episode) OR (de.id_external_request = l_ext_req))
               AND de.flg_status IN (g_doc_active, g_doc_inactive)
               AND pk_doc.get_types_config_visible(dt.id_doc_type, NULL, NULL, NULL, i_prof, l_my_pt, i_btn) =
                   g_doc_config_y
               AND pk_doc.get_types_config_visible(NULL, dot.id_doc_ori_type, NULL, NULL, i_prof, l_my_pt, i_btn) =
                   g_doc_config_y
             ORDER BY oritypedesc, de.flg_status ASC, de.dt_emited DESC;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_list);
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     g_package_owner,
                                                     g_package_name,
                                                     'GET_DOC_LIST_EPIS',
                                                     o_error);
    END get_doc_list_epis;

    /**
    * Get detail list for the viewer 'with me' filter
    *
    * @param   I_LANG    language associated to the professional executing the request
    * @param   I_PROF    professional, institution and software ids
    * @param   I_PATIENT patient id
    * @param   I_EPISODE episode id
    * @param   I_EXT_REQ referral id        
    * @param   I_BTN     sys_button used to allow diferent behaviours depending on the button being used.
    * @param   O_LIST    output list
    * @param   O_ERROR   an error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Telmo Castro
    * @version 1.0
    * @since   21-12-2007
    */
    FUNCTION get_doc_list_me
    (
        i_lang    IN NUMBER,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        i_episode IN episode.id_episode%TYPE,
        i_ext_req IN p1_external_request.id_external_request%TYPE,
        i_btn     IN sys_button_prop.id_sys_button_prop%TYPE,
        o_list    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        l_ret        BOOLEAN;
        my_exception EXCEPTION;
        l_patient    patient.id_patient%TYPE;
        l_episode    episode.id_episode%TYPE;
        l_ext_req    p1_external_request.id_external_request%TYPE;
        l_my_pt      profile_template.id_profile_template%TYPE;
    BEGIN
        g_error := 'GET PROFILE';
        l_ret   := get_profile_template(i_lang, i_prof, l_my_pt, o_error);
    
        IF NOT l_ret
        THEN
            RAISE my_exception;
        END IF;
    
        -- Validate context (Patient, Episode and External Request)
        SELECT decode(pk_doc.get_config('DOC_PATIENT', i_prof, l_my_pt, i_btn), g_doc_config_y, i_patient, NULL),
               decode(pk_doc.get_config('DOC_EPISODE', i_prof, l_my_pt, i_btn), g_doc_config_y, i_episode, NULL),
               decode(pk_doc.get_config('DOC_REFERRAL', i_prof, l_my_pt, i_btn), g_doc_config_y, i_ext_req, NULL)
          INTO l_patient, l_episode, l_ext_req
          FROM dual;
    
        g_error := 'OPEN O_LIST';
        OPEN o_list FOR
            SELECT dot.id_doc_ori_type,
                   pk_translation.get_translation(i_lang, dot.code_doc_ori_type) oritypedesc,
                   de.title,
                   de.id_doc_external iddoc,
                   pk_doc.get_comments_line_with_count(i_lang, i_prof, de.id_doc_external, dot.flg_comment_type) numcomments,
                   (SELECT COUNT(1)
                      FROM doc_image
                     WHERE id_doc_external = de.id_doc_external
                       AND flg_status = g_img_active) numimages,
                   --                   pk_date_utils.date_time_chr(i_lang, de.dt_emited, i_prof) dt_emited,
                   pk_date_utils.dt_chr(i_lang, de.dt_emited, i_prof) dt_emited,
                   pk_date_utils.date_char_tsz(i_lang,
                                               nvl(de.dt_updated, de.dt_inserted),
                                               i_prof.institution,
                                               i_prof.software) lastupdateddate,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, nvl(de.id_professional_upd, de.id_professional)) lastupdatedby,
                   pk_prof_utils.get_spec_signature(i_lang,
                                                    i_prof,
                                                    nvl(de.id_professional_upd, de.id_professional),
                                                    nvl(de.dt_updated, de.dt_inserted),
                                                    de.id_episode) todo_especialidade,
                   get_main_thumb_url(i_lang, i_prof, de.id_doc_external) url_thumb,
                   de.flg_status,
                   dot.flg_comment_type
              FROM doc_type dt
              JOIN doc_external de
                ON (dt.id_doc_type = de.id_doc_type)
              JOIN doc_ori_type dot
                ON (de.id_doc_ori_type = dot.id_doc_ori_type)
             WHERE ((de.id_patient = l_patient) OR (de.id_episode = l_episode) OR (de.id_external_request = l_ext_req))
               AND de.flg_status IN (g_doc_active, g_doc_inactive)
               AND pk_doc.get_types_config_visible(dt.id_doc_type, NULL, NULL, NULL, i_prof, l_my_pt, i_btn) =
                   g_doc_config_y
               AND pk_doc.get_types_config_visible(NULL, dot.id_doc_ori_type, NULL, NULL, i_prof, l_my_pt, i_btn) =
                   g_doc_config_y
               AND i_prof.id IN (de.id_professional, de.id_professional_upd)
             ORDER BY oritypedesc, de.dt_emited DESC;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_list);
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     g_package_owner,
                                                     g_package_name,
                                                     'GET_DOC_LIST_EPIS',
                                                     o_error);
        
            RETURN FALSE;
        
    END get_doc_list_me;

    /**
    * Gets the last active document of a specified type
    *
    * @param   I_LANG     language associated to the professional executing the request
    * @param   I_PROF     professional, institution and software ids
    * @param   I_PATIENT  patient id
    * @param   I_EPISODE  episode id
    * @param   I_DOC_TYPE document type ID    
    * @param   O_LIST     output list
    * @param   O_ERROR    an error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  José Silva
    * @version 1.0
    * @since   15-02-2009
    */
    FUNCTION get_doc_list_type
    (
        i_lang     IN NUMBER,
        i_prof     IN profissional,
        i_patient  IN patient.id_patient%TYPE,
        i_episode  IN episode.id_episode%TYPE,
        i_doc_type IN doc_type.id_doc_type%TYPE,
        i_btn      IN sys_button_prop.id_sys_button_prop%TYPE,
        o_list     OUT p_doc_list_rec_cur,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_ret        BOOLEAN;
        my_exception EXCEPTION;
        l_patient    patient.id_patient%TYPE;
        l_episode    episode.id_episode%TYPE;
        l_my_pt      profile_template.id_profile_template%TYPE;
    BEGIN
    
        g_error := 'GET PROFILE';
        l_ret   := get_profile_template(i_lang, i_prof, l_my_pt, o_error);
    
        IF NOT l_ret
        THEN
            RAISE my_exception;
        END IF;
    
        -- Validate context (Patient, Episode and External Request)
        SELECT decode(pk_doc.get_config('DOC_PATIENT', i_prof, l_my_pt, i_btn), g_doc_config_y, i_patient, NULL),
               decode(pk_doc.get_config('DOC_EPISODE', i_prof, l_my_pt, i_btn), g_doc_config_y, i_episode, NULL)
          INTO l_patient, l_episode
          FROM dual;
    
        g_error := 'OPEN O_LIST';
        OPEN o_list FOR
            SELECT dot.id_doc_ori_type,
                   pk_translation.get_translation(i_lang, dot.code_doc_ori_type) oritypedesc,
                   pk_translation.get_translation(i_lang, dt.code_doc_type) typedesc,
                   de.title,
                   de.id_doc_external iddoc,
                   pk_doc.get_comments_line_with_count(i_lang, i_prof, de.id_doc_external, dot.flg_comment_type) numcomments,
                   (SELECT COUNT(1)
                      FROM doc_image
                     WHERE id_doc_external = de.id_doc_external
                       AND flg_status = g_img_active) numimages,
                   --                   pk_date_utils.date_time_chr(i_lang, de.dt_emited, i_prof) dt_emited,
                   pk_date_utils.dt_chr(i_lang, de.dt_emited, i_prof) dt_emited,
                   pk_date_utils.date_char_tsz(i_lang,
                                               nvl(de.dt_updated, de.dt_inserted),
                                               i_prof.institution,
                                               i_prof.software) lastupdateddate,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, nvl(de.id_professional_upd, de.id_professional)) lastupdatedby,
                   get_main_thumb_url(i_lang, i_prof, de.id_doc_external) url_thumb,
                   de.flg_status,
                   dot.flg_comment_type
              FROM doc_type dt
              JOIN doc_external de
                ON (dt.id_doc_type = de.id_doc_type)
              JOIN doc_ori_type dot
                ON (de.id_doc_ori_type = dot.id_doc_ori_type)
             WHERE ((de.id_patient = l_patient) OR (de.id_episode = l_episode))
               AND de.flg_status = g_doc_active
               AND dt.id_doc_type = i_doc_type
               AND pk_doc.get_types_config_visible(dt.id_doc_type, NULL, NULL, NULL, i_prof, l_my_pt, i_btn) =
                   g_doc_config_y
               AND pk_doc.get_types_config_visible(NULL, dot.id_doc_ori_type, NULL, NULL, i_prof, l_my_pt, i_btn) =
                   g_doc_config_y
             ORDER BY de.dt_emited DESC;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
        
            pk_types.open_my_cursor(o_list);
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     g_package_owner,
                                                     g_package_name,
                                                     'GET_DOC_LIST_TYPE',
                                                     o_error);
    END get_doc_list_type;

    /**
    * update do titulo em varias imagens. Para ser usado pelo botao Apply title to all images.
    * 
    * @param i_lang            IN id da lingua
    * @param i_prof            IN profissional data
    * @param i_ids_images      IN ids das imagens
    * @param i_titles          IN novos titulos
    * @param o_ids_images      OUT id do novo registo
    * @param o_error           OUT mensagem de erro (se result = 0)
    *
    * @return true (sucess), false (error)
    * @created 28-12-2007
    * @author Telmo Castro
    * @version 1.0
    *
    * @updated 31-12-2007
    * @author Telmo Castro 
    * i_title passa a ser uma table_varchar. O indice das nested tables une i_ids_images com i_titles
    */
    FUNCTION update_titles
    (
        i_lang       IN NUMBER,
        i_prof       IN profissional,
        i_ids_images IN table_number,
        i_titles     IN table_varchar,
        o_ids_images OUT table_number,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_id      NUMBER;
        l_my_ex   EXCEPTION;
        l_outid   NUMBER;
        l_exerror t_error_out;
    BEGIN
    
        g_error := 'LOOP update_titles';
    
        l_id := i_ids_images.first;
        WHILE l_id IS NOT NULL
        LOOP
            --            dbms_output.put_line('vai chamar o updateimage');
            -- se falhar em algum dos updates individuais interrompe processo
            IF NOT pk_doc_attach.update_image(i_lang,
                                              i_prof,
                                              i_ids_images(l_id),
                                              NULL,
                                              NULL,
                                              NULL,
                                              NULL,
                                              NULL,
                                              i_titles(l_id),
                                              l_outid,
                                              l_exerror)
            THEN
                RAISE l_my_ex;
            END IF;
            -- juntar a' lista dos ids novos
            IF o_ids_images IS NULL
            THEN
                o_ids_images := table_number(l_outid);
            ELSE
                o_ids_images.extend();
                o_ids_images(o_ids_images.last) := l_outid;
            END IF;
        
            l_id := i_ids_images.next(l_id);
        END LOOP;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'UPDATE_TITLES',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
        
    END update_titles;

    /**
    * delete dos documentos pendentes criados ha mais de i_lifetime. 
    * Isto e' usado por um job para limpar regularmente a tabela doc_external
    * 
    * @param i_lifetime          IN numero de horas minimo que o documento deve ter para poder ser apagado
    *
    * @return true (sucess), false (error)
    * @created 09.01.2008
    * @author Telmo Castro
    * @version 1.0
    */
    FUNCTION delete_docs(i_lifetime IN NUMBER DEFAULT 72) RETURN BOOLEAN IS
    BEGIN
        -- apagar primeiro comments, por causa da FK
        DELETE doc_comments
         WHERE id_doc_external IN
               (SELECT id_doc_external
                  FROM doc_external
                 WHERE dt_inserted IS NOT NULL
                   AND flg_status = g_doc_pendente
                   AND pk_date_utils.get_elapsed_minutes_abs_tsz(dt_inserted) / 60 >= i_lifetime);
        -- apagar primeiro images, por causa da FK
        DELETE doc_image
         WHERE id_doc_external IN
               (SELECT id_doc_external
                  FROM doc_external
                 WHERE dt_inserted IS NOT NULL
                   AND flg_status = g_doc_pendente
                   AND pk_date_utils.get_elapsed_minutes_abs_tsz(dt_inserted) / 60 >= i_lifetime);
        -- apagar docs
        DELETE doc_external
         WHERE dt_inserted IS NOT NULL
           AND flg_status = g_doc_pendente
           AND pk_date_utils.get_elapsed_minutes_abs_tsz(dt_inserted) / 60 >= i_lifetime;
    
        RETURN TRUE;
    
    END delete_docs;

    /**
    * Return number of migrant doc 
    * Isto e' usado por um job para limpar regularmente a tabela doc_external
    * 
    * @param i_lang            IN id da lingua
    * @param i_prof            IN profissional data
    * @param i_id_patient      IN id_patient
    * @param o_num_doc      OUT document number    
    * @param o_doc_exist      OUT Y - if document exists, N
    * @param o_error           OUT mensagem de erro (se result = 0)
    *
    *
    * @return true (sucess), false (error)
    * @created 09.01.2008
    * @version 1.0
    */
    FUNCTION get_migrant_doc
    (
        i_lang                IN NUMBER,
        i_prof                IN profissional,
        i_id_patient          IN patient.id_patient%TYPE,
        o_num_doc             OUT doc_external.num_doc%TYPE,
        o_exist_doc           OUT VARCHAR2,
        o_dt_expire           OUT doc_external.dt_expire%TYPE,
        o_doc_type            OUT doc_external.id_doc_type%TYPE,
        o_id_content_doc_type OUT doc_type.id_content%TYPE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
    
        CURSOR c_exists(v_doc_type table_varchar) IS
            SELECT de.num_doc, de.dt_expire, de.id_doc_type, dt.id_content
              FROM doc_external de
              JOIN doc_type dt
                ON dt.id_doc_type = de.id_doc_type
             WHERE de.id_patient = i_id_patient
               AND dt.id_content IN (SELECT column_value
                                       FROM TABLE(v_doc_type))
               AND de.flg_status = g_doc_active;
    
        r_exists c_exists%ROWTYPE;
    
        l_doc_type_table table_varchar := pk_utils.str_split_l(pk_sysconfig.get_config('ID_DOC_TYPE_MIGRANT', i_prof),
                                                               '|');
    BEGIN
    
        OPEN c_exists(l_doc_type_table);
        FETCH c_exists
            INTO r_exists;
    
        IF c_exists%FOUND
        THEN
            o_num_doc             := r_exists.num_doc;
            o_dt_expire           := r_exists.dt_expire;
            o_exist_doc           := 'Y';
            o_doc_type            := r_exists.id_doc_type;
            o_id_content_doc_type := r_exists.id_content;
        ELSE
            o_num_doc             := r_exists.num_doc;
            o_dt_expire           := NULL;
            o_exist_doc           := 'N';
            o_doc_type            := r_exists.id_doc_type;
            o_id_content_doc_type := r_exists.id_content;
        END IF;
        CLOSE c_exists;
    
        RETURN TRUE;
    
    END get_migrant_doc;

    /********************************************************************************************
    * Get the total size already used for documents upload
    *
    * @ param i_lang                  Preferred language ID for this professional 
    * @ param i_prof                  Object (professional ID, institution ID, software ID)
    * @ param o_used_quota            Quota size already used, in a given institution
    * @ param o_error                 Error
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         0.1
    * @since                           2010/02/18
    **********************************************************************************************/
    FUNCTION get_used_quota
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        o_used_quota OUT NUMBER,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        pk_alertlog.log_debug('GET_USED_QUOTA', 'PK_DOC');
    
        SELECT SUM(di.img_size)
          INTO o_used_quota
          FROM doc_image di
         WHERE di.id_institution = i_prof.institution;
    
        pk_alertlog.log_debug('GET_USED_QUOTA = ' || o_used_quota || ' Kbytes', 'PK_DOC');
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
        
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_USED_QUOTA',
                                              o_error);
            RETURN FALSE;
    END get_used_quota;

    /********************************************************************************************
    * Validate the if maximum quota size for documents upload is exceeded
    *
    * @ param i_lang                  Preferred language ID for this professional 
    * @ param i_prof                  Object (professional ID, institution ID, software ID)
    * @ param i_new_docs_size         Total size of documents to upload
    * @ param o_flg_show              Indication of Warning message              
    * @ param o_msg                   Warning message text
    * @ param o_msg_title             Warning message title
    * @ param o_button                Warning message buttons
    * @ param o_error                 Error
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         0.1
    * @since                           2010/02/18
    **********************************************************************************************/
    FUNCTION validate_used_quota
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_new_docs_size IN NUMBER,
        o_flg_show      OUT VARCHAR2,
        o_msg           OUT VARCHAR2,
        o_msg_title     OUT VARCHAR2,
        o_button        OUT VARCHAR2,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        l_inst_quota NUMBER(24);
        l_max_quota  NUMBER(24);
        my_exception EXCEPTION;
    BEGIN
        pk_alertlog.log_debug('VALIDATE_USED_QUOTA', 'PK_DOC');
    
        l_max_quota := pk_sysconfig.get_config('MAX_DOC_QUOTA_PER_INST', i_prof);
        o_flg_show  := 'F';
    
        IF NOT get_used_quota(i_lang => i_lang, i_prof => i_prof, o_used_quota => l_inst_quota, o_error => o_error)
        THEN
            RAISE my_exception;
        END IF;
    
        --the quota size is in bytes
        IF (l_inst_quota + i_new_docs_size) > l_max_quota
        THEN
            o_flg_show  := pk_alert_constant.g_yes;
            o_msg       := pk_message.get_message(i_lang, 'DOC_T108');
            o_msg_title := pk_message.get_message(i_lang, 'DOC_T107');
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'VALIDATE_USED_QUOTA',
                                              o_error);
            RETURN FALSE;
    END validate_used_quota;

    /********************************************************************************************
    * Validate the upload of selected documents. In this case, two diferent validations are being done:
    *          1 - maximun document size, per document
    *          2 - maximum quota size for documents upload, per institution
    *
    * @ param i_lang                  Preferred language ID for this professional 
    * @ param i_prof                  Object (professional ID, institution ID, software ID)
    * @ param i_docs_info             List of documents to upload (id, name, size)
    * @ param o_doc_upload            Documents uploaded (id, Y/N) - indicates if the documents 
    *                                 were successfully uploaded
    * @ param o_flg_show              Indication of Warning message              
    * @ param o_msg                   Warning message text
    * @ param o_msg_title             Warning message title
    * @ param o_button                Warning message buttons
    * @ param o_error                 Error
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         0.1
    * @since                           2010/02/18
    **********************************************************************************************/
    FUNCTION validate_doc_upload
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_docs_info  IN table_table_varchar,
        o_doc_upload OUT table_table_varchar,
        o_flg_show   OUT VARCHAR2,
        o_msg        OUT VARCHAR2,
        o_msg_title  OUT VARCHAR2,
        o_button     OUT VARCHAR2,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_inst_quota          NUMBER(24);
        l_max_quota           NUMBER(24);
        l_doc_max_size        NUMBER(24);
        l_new_docs_total_size NUMBER(24) := 0;
    
        l_doc_size_exceeded     BOOLEAN := FALSE;
        l_quota_size_exceeded   BOOLEAN := FALSE;
        l_doc_size_exceeded_str VARCHAR2(4000);
        my_exception            EXCEPTION;
        --
        --in this case the ID is received as a string!
        l_doc_id   doc_image.file_name%TYPE;
        l_doc_name doc_image.file_name%TYPE;
        l_doc_size doc_image.img_size%TYPE;
    
        --can the doc be uploaded?
        l_doc_upload          table_table_varchar := table_table_varchar();
        l_doc_upload_internal table_varchar := table_varchar();
    
        l_total_docs        PLS_INTEGER;
        l_total_docs_upload PLS_INTEGER := 0;
    BEGIN
        pk_alertlog.log_debug('VALIDATE_DOC_UPLOAD', 'PK_DOC');
        --Quota size
        l_max_quota := pk_sysconfig.get_config('MAX_DOC_QUOTA_PER_INST', i_prof);
        --Max file size
        l_doc_max_size := pk_sysconfig.get_config('DOC_FILE_MAX_SIZE', i_prof);
        o_flg_show     := 'N';
    
        IF l_max_quota = -1 --no limmit
        THEN
            l_inst_quota := -1; -- no limmit
        ELSE
            IF NOT get_used_quota(i_lang => i_lang, i_prof => i_prof, o_used_quota => l_inst_quota, o_error => o_error)
            THEN
                RAISE my_exception;
            END IF;
        END IF;
    
        --Validations:
        l_total_docs := i_docs_info.count;
    
        FOR i IN 1 .. i_docs_info.count
        LOOP
            --validate all docs that are being uploaded
            l_doc_id   := i_docs_info(i) (1);
            l_doc_name := i_docs_info(i) (2);
            l_doc_size := i_docs_info(i) (3);
            IF l_doc_size > l_doc_max_size
            THEN
                --1 file exceed the max doc size
                l_doc_size_exceeded     := TRUE;
                l_doc_size_exceeded_str := l_doc_size_exceeded_str || '<br>' || l_doc_name;
                l_doc_upload.extend;
                l_doc_upload(i) := table_varchar(l_doc_id, g_no);
            ELSE
                l_doc_upload.extend;
                l_doc_upload(i) := table_varchar(l_doc_id, g_yes);
                --only for files that can be uploaded
                l_new_docs_total_size := l_new_docs_total_size + to_number(l_doc_size);
                --number of docs ok for download
                l_total_docs_upload := l_total_docs_upload + 1;
            END IF;
        
        END LOOP;
        o_doc_upload := l_doc_upload;
    
        IF l_max_quota = -1 -- no limmit
        THEN
            l_quota_size_exceeded := FALSE;
        ELSE
            l_quota_size_exceeded := (l_inst_quota + l_new_docs_total_size) > l_max_quota;
        END IF;
        --
        pk_alertlog.log_debug((l_inst_quota + l_new_docs_total_size) || ', cota max = ' || l_max_quota || ', ' ||
                              sys.diutil.bool_to_int(l_quota_size_exceeded));
        --The quota warning is more important than the file size one.
        --
        IF l_doc_size_exceeded
           AND l_quota_size_exceeded
        THEN
            g_error := 'l_doc_size_exceeded=TRUE,  l_quota_size_exceeded=TRUE';
            FOR i IN 1 .. l_doc_upload.count
            LOOP
                --no documents can be uploaded 
                l_doc_upload(i)(2) := g_no;
            END LOOP;
            --
            o_doc_upload := l_doc_upload;
            o_flg_show   := pk_alert_constant.g_yes;
            o_msg        := pk_message.get_message(i_lang, 'DOC_T108');
            o_msg_title  := pk_message.get_message(i_lang, 'DOC_T107');
            o_button     := 'R';
            RETURN TRUE;
        ELSIF l_quota_size_exceeded
        THEN
            g_error := 'l_quota_size_exceeded=TRUE';
            FOR i IN 1 .. l_doc_upload.count
            LOOP
                --no documents can be uploaded    
                l_doc_upload(i)(2) := g_no;
            END LOOP;
            o_doc_upload := l_doc_upload;
        
            o_flg_show  := pk_alert_constant.g_yes;
            o_msg       := pk_message.get_message(i_lang, 'DOC_T108');
            o_msg_title := pk_message.get_message(i_lang, 'DOC_T107');
            o_button    := 'R';
            RETURN TRUE;
        ELSIF l_doc_size_exceeded
        THEN
            g_error     := 'l_doc_size_exceeded=TRUE';
            o_flg_show  := pk_alert_constant.g_yes;
            o_msg_title := pk_message.get_message(i_lang, 'DOC_T107');
            IF l_total_docs_upload = 0
            THEN
                o_msg    := pk_message.get_message(i_lang, 'DOC_T106');
                o_button := 'R';
            ELSE
                o_msg    := pk_message.get_message(i_lang, 'DOC_T104') || chr(10) || l_doc_size_exceeded_str;
                o_button := 'NC';
            END IF;
            RETURN TRUE;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'VALIDATE_DOC_UPLOAD',
                                              o_error);
            RETURN FALSE;
    END validate_doc_upload;

    FUNCTION get_documents_list_count
    (
        i_lang       IN NUMBER,
        i_prof       IN profissional,
        i_pat        IN patient.id_patient%TYPE,
        i_episode    IN episode.id_episode%TYPE,
        i_ext_req    IN p1_external_request.id_external_request%TYPE,
        i_btn        IN sys_button_prop.id_sys_button_prop%TYPE,
        i_flg_status IN table_varchar,
        o_list       OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_inst       table_number;
        my_exception EXCEPTION;
    
        l_patient patient.id_patient%TYPE;
        l_episode episode.id_episode%TYPE;
        l_ext_req p1_external_request.id_external_request%TYPE;
    
        l_my_pt profile_template.id_profile_template%TYPE;
        l_ret   BOOLEAN := FALSE;
        l_error t_error_out;
    
        l_id_doc_ori_types table_number;
        l_id_doc_types     table_number;
    
        l_doc_external_oid sys_config.value%TYPE := pk_sysconfig.get_config('ALERT_OID_HIE_DOC_EXTERNAL', i_prof);
    
        document_tbl t_tbl_rec_document;
    
        l_include_bdy_diagram VARCHAR2(1 CHAR);
        l_body_diagrams       pk_types.cursor_type;
        l_id_doc_ori_type     NUMBER;
    
        l_id_epis_diagram table_number := table_number();
        l_diagram_order   table_number := table_number();
        l_diagram_desc    table_varchar := table_varchar();
        l_id_episode      table_number := table_number();
        l_last_upd_prof   table_number := table_number();
        l_specialty       table_number := table_number();
        l_last_upd_date   table_varchar := table_varchar();
        l_num_images      table_number := table_number();
    
    BEGIN
    
        g_error            := 'GET ALLOWED ID_DOC_ORI_TYPES';
        l_id_doc_ori_types := get_categories_tbl(i_lang, i_prof, l_error);
    
        g_error := 'Get all related institutions';
        IF NOT pk_utils.get_institutions_sib(i_lang  => i_lang,
                                             i_prof  => i_prof,
                                             i_inst  => i_prof.institution,
                                             o_list  => l_inst,
                                             o_error => o_error)
        THEN
            RAISE my_exception;
        ELSE
            IF l_inst.count = 0
            THEN
                l_inst.extend;
                l_inst(1) := i_prof.institution;
            END IF;
        END IF;
    
        IF pk_doc.is_arch_including_body_diag(i_lang, i_prof)
        THEN
            l_include_bdy_diagram := 'Y';
        
            SELECT d.id_doc_ori_type
              INTO l_id_doc_ori_type
              FROM doc_type d
             WHERE d.id_doc_type = 2622; -- body diagrams doc_type        
        END IF;
    
        g_error := 'Get body diagrams';
        IF NOT pk_diagram_new.get_all_pat_diag_doc(i_lang    => i_lang,
                                                   i_prof    => i_prof,
                                                   i_patient => i_pat,
                                                   o_info    => l_body_diagrams,
                                                   o_error   => o_error)
        THEN
            pk_types.open_my_cursor(l_body_diagrams);
        END IF;
    
        g_error := 'Fetch body diagrams';
        FETCH l_body_diagrams BULK COLLECT
            INTO l_id_epis_diagram,
                 l_diagram_order,
                 l_diagram_desc,
                 l_id_episode,
                 l_last_upd_prof,
                 l_specialty,
                 l_last_upd_date,
                 l_num_images;
    
        g_error := 'OPEN cursor';
        OPEN o_list FOR
            WITH patient_documents AS
             (SELECT de.doc_oid,
                     de.id_doc_external,
                     nvl(de.dt_updated, de.dt_inserted) lastupdateddatetstz,
                     nvl(de.title, '') title,
                     de.flg_status,
                     de.id_doc_ori_type
                FROM (SELECT *
                        FROM doc_external
                       WHERE id_patient = i_pat
                      UNION
                      SELECT *
                        FROM doc_external
                       WHERE id_episode = i_episode
                      UNION
                      SELECT *
                        FROM doc_external
                       WHERE id_external_request = i_ext_req) de
                LEFT JOIN xds_document_submission xds
                  ON xds.id_doc_external = nvl(de.id_grupo, de.id_doc_external)
               WHERE de.flg_status IN (SELECT *
                                         FROM TABLE(i_flg_status))
                 AND de.id_institution IN (SELECT column_value
                                             FROM TABLE(l_inst))
                 AND nvl(xds.flg_status, g_doc_active) = g_doc_active
                 AND de.id_doc_ori_type IN (SELECT column_value
                                              FROM TABLE(l_id_doc_ori_types))
              UNION ALL
              SELECT NULL doc_oid,
                     ied.val id_doc_external,
                     CAST(pk_date_utils.get_timestamp_insttimezone(i_lang,
                                                                   i_prof,
                                                                   lud.val,
                                                                   pk_alert_constant.g_dt_yyyymmddhh24miss) AS TIMESTAMP WITH
                          LOCAL TIME ZONE) lastupdateddatetstz,
                     nvl(dd.val, '') title,
                     'A' flg_status,
                     l_id_doc_ori_type id_doc_ori_type
                FROM (SELECT /*+ opt_estimate(table t1 rows=1) */
                       rownum rn, column_value val
                        FROM TABLE(l_id_epis_diagram) t1) ied
                JOIN (SELECT /*+ opt_estimate(table t2 rows=2) */
                      rownum rn, column_value val
                       FROM TABLE(l_last_upd_date) t2) lud
                  ON lud.rn = ied.rn
                JOIN (SELECT /*+ opt_estimate(table t3 rows=3) */
                      rownum rn, column_value val
                       FROM TABLE(l_diagram_desc) t3) dd
                  ON dd.rn = ied.rn
               WHERE l_include_bdy_diagram = 'Y')
            SELECT t.rank, t.id_doc_ori_type, t.desc_ori_type, t.num_docs, t.doc_oids, t.id_docs, t.id_dates, t.titles
              FROM (SELECT 0 rank,
                           NULL id_doc_ori_type,
                           pk_message.get_message(i_lang, 'DOC_T109') desc_ori_type,
                           COUNT(1) num_docs,
                           CAST(COLLECT(de.doc_oid) AS table_varchar) doc_oids,
                           CAST(COLLECT(de.id_doc_external) AS table_number_id) id_docs,
                           CAST(COLLECT(de.lastupdateddatetstz) AS table_timestamp_tstz) id_dates,
                           CAST(COLLECT(nvl(de.title, ' ')) AS table_varchar) titles,
                           0 rank1
                      FROM patient_documents de
                     WHERE de.flg_status IN (SELECT *
                                               FROM TABLE(i_flg_status))
                     GROUP BY 1
                    UNION ALL
                    SELECT 0 rank,
                           NULL id_doc_ori_type,
                           pk_message.get_message(i_lang, 'DOC_T109') desc_ori_type,
                           0 num_docs,
                           table_varchar() doc_oids,
                           table_number_id() id_docs,
                           table_timestamp_tstz() id_dates,
                           table_varchar() titles,
                           0 rank1
                      FROM dual
                     WHERE 0 = (SELECT COUNT(1)
                                  FROM patient_documents)
                     GROUP BY 1
                    UNION ALL
                    SELECT /*+ opt_estimate(table de rows=1) */
                     dot.rank,
                     de.id_doc_ori_type,
                     (SELECT pk_translation.get_translation(i_lang, dot.code_button)
                        FROM dual) desc_ori_type,
                     COUNT(1) num_docs,
                     CAST(COLLECT(de.doc_oid) AS table_varchar) doc_oids,
                     CAST(COLLECT(de.id_doc_external) AS table_number_id) id_docs,
                     CAST(COLLECT(de.lastupdateddatetstz) AS table_timestamp_tstz) id_dates,
                     CAST(COLLECT(nvl(de.title, ' ')) AS table_varchar) titles,
                     (SELECT pk_doc.get_doc_rank(i_lang, i_prof, de.id_doc_ori_type)
                        FROM dual) rank1
                      FROM patient_documents de
                     INNER JOIN doc_ori_type dot
                        ON dot.id_doc_ori_type = de.id_doc_ori_type
                     WHERE de.flg_status IN (SELECT *
                                               FROM TABLE(i_flg_status))
                     GROUP BY dot.rank, de.id_doc_ori_type, dot.code_button
                    UNION ALL
                    SELECT dot.rank,
                           dot.id_doc_ori_type,
                           (SELECT pk_translation.get_translation(i_lang, dot.code_button)
                              FROM dual) desc_ori_type,
                           0 num_docs,
                           table_varchar() doc_oids,
                           table_number_id() id_docs,
                           table_timestamp_tstz() id_dates,
                           table_varchar() titles,
                           (SELECT pk_doc.get_doc_rank(i_lang, i_prof, dot.id_doc_ori_type)
                              FROM dual) rank1
                      FROM doc_ori_type dot
                     WHERE NOT EXISTS (SELECT 1
                              FROM patient_documents de
                             WHERE de.id_doc_ori_type = dot.id_doc_ori_type)
                       AND dot.id_doc_ori_type IN (SELECT column_value
                                                     FROM TABLE(l_id_doc_ori_types))
                     GROUP BY dot.rank, dot.id_doc_ori_type, dot.code_button
                     ORDER BY rank1, rank, desc_ori_type) t;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_list);
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_DOCUMENTS_LIST_COUNT',
                                              o_error);
            RETURN FALSE;
    END get_documents_list_count;

    FUNCTION get_documents_list_details
    (
        i_lang         IN NUMBER,
        i_prof         IN profissional,
        i_pat          IN patient.id_patient%TYPE,
        i_episode      IN episode.id_episode%TYPE,
        i_ext_req      IN p1_external_request.id_external_request%TYPE,
        i_btn          IN sys_button_prop.id_sys_button_prop%TYPE,
        i_doc_ori_type IN doc_ori_type.id_doc_ori_type%TYPE,
        o_list         OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_inst             table_number;
        my_exception       EXCEPTION;
        l_doc_external_oid sys_config.value%TYPE := pk_sysconfig.get_config('ALERT_OID_HIE_DOC_EXTERNAL', i_prof);
    
        l_patient patient.id_patient%TYPE;
        l_episode episode.id_episode%TYPE;
        l_ext_req p1_external_request.id_external_request%TYPE;
    
        l_my_pt profile_template.id_profile_template%TYPE;
    
        l_ret   BOOLEAN;
        l_error t_error_out;
    
    BEGIN
        --For UX layer this function will have 2 behaviours
        --If i_doc_ori_type is not null the information will be filtered
        --If i_doc_ori_type is null the information will not be filtered
    
        g_error := 'Get all related institutions';
        IF NOT pk_utils.get_institutions_sib(i_lang  => i_lang,
                                             i_prof  => i_prof,
                                             i_inst  => i_prof.institution,
                                             o_list  => l_inst,
                                             o_error => o_error)
        THEN
            RAISE my_exception;
        ELSE
            IF l_inst.count = 0
            THEN
                l_inst.extend;
                l_inst(1) := i_prof.institution;
            END IF;
        END IF;
    
        g_error := 'GET PROFILE';
        l_ret   := pk_doc.get_profile_template(i_lang, i_prof, l_my_pt, l_error);
    
        IF NOT l_ret
        THEN
            RAISE g_exception;
        END IF;
    
        -- Validate context (Patient, Episode and External Request)
        SELECT decode(pk_doc.get_config('DOC_PATIENT', i_prof, l_my_pt, i_btn), g_doc_config_y, i_pat, NULL),
               decode(pk_doc.get_config('DOC_EPISODE', i_prof, l_my_pt, i_btn), g_doc_config_y, i_episode, NULL),
               decode(pk_doc.get_config('DOC_REFERRAL', i_prof, l_my_pt, i_btn), g_doc_config_y, i_ext_req, NULL)
          INTO l_patient, l_episode, l_ext_req
          FROM dual;
    
        IF i_doc_ori_type IS NOT NULL
        THEN
            g_error := 'Return cursor - filtered';
            OPEN o_list FOR
                SELECT de.id_doc_ori_type,
                       de.id_doc_external,
                       de.id_grupo,
                       l_doc_external_oid || '.' || nvl(de.id_grupo, de.id_doc_external) doc_oid
                  FROM doc_external de, doc_type dt, doc_ori_type dot
                 WHERE de.id_patient = i_pat
                   AND de.id_doc_ori_type = i_doc_ori_type
                   AND dt.id_doc_type = de.id_doc_type
                   AND dot.id_doc_ori_type = de.id_doc_ori_type
                   AND dt.flg_available = 'Y'
                   AND dot.flg_available = 'Y'
                   AND de.flg_status = g_doc_active
                   AND de.id_institution IN (SELECT column_value
                                               FROM TABLE(l_inst))
                   AND de.flg_status IN (g_doc_active, g_doc_inactive)
                 ORDER BY de.dt_inserted DESC;
        
        ELSE
            g_error := 'Return cursor - not filtered';
            OPEN o_list FOR
                SELECT de.id_doc_ori_type,
                       de.id_doc_external,
                       de.id_grupo,
                       l_doc_external_oid || '.' || nvl(de.id_grupo, de.id_doc_external) doc_oid
                  FROM doc_external de, doc_type dt, doc_ori_type dot
                 WHERE de.id_patient = i_pat
                   AND dt.id_doc_type = de.id_doc_type
                   AND dot.id_doc_ori_type = de.id_doc_ori_type
                   AND dt.flg_available = 'Y'
                   AND dot.flg_available = 'Y'
                   AND de.id_institution IN (SELECT column_value
                                               FROM TABLE(l_inst))
                   AND de.flg_status IN (g_doc_active, g_doc_inactive)
                 ORDER BY de.dt_inserted DESC;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_list);
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_DOCUMENTS_LIST_DETAILS',
                                              o_error);
            RETURN FALSE;
    END get_documents_list_details;

    FUNCTION create_report_document
    (
        i_lang            IN NUMBER,
        i_prof            IN profissional,
        i_epis_report     IN epis_report.id_epis_report%TYPE,
        i_flg_share_grid  IN VARCHAR2,
        o_error           OUT t_error_out,
        o_id_doc_external OUT epis_report.id_doc_external%TYPE
    ) RETURN BOOLEAN IS
    
        CURSOR c_epis_report IS
            SELECT
            /*+opt_estimate(table er rows=10)*/
             id_epis_report, --1
             risdt.id_doc_type id_doc_type,
             NULL num_doc,
             er.dt_creation_tstz dt_emited,
             NULL notes, --5
             NULL dt_digit,
             risdt.id_doc_ori_type id_doc_ori_type,
             NULL id_doc_destination,
             NULL dt_expire,
             er.id_external_request, --10
             NULL desc_doc_type,
             NULL desc_doc_ori_type,
             NULL desc_doc_destination,
             er.id_episode,
             epis.id_patient, --15
             'A' flg_status,
             NULL local_emited,
             pk_episode.get_epis_institution_id(il.id_language, i_prof, er.id_episode) id_institution,
             NULL flg_sent_by,
             NULL flg_received, --20
             NULL id_doc_original,
             NULL desc_doc_original,
             er.id_professional,
             coalesce(pk_message.get_message(il.id_language, er.code_dynamic_title),
                      pk_translation.get_translation(il.id_language, rep.code_reports_title),
                      pk_translation.get_translation(il.id_language, rep.code_reports)) title,
             er.dt_creation_tstz dt_inserted, --25
             NULL dt_updated,
             NULL id_professional_upd,
             NULL id_prof_perf_by,
             NULL desc_perf_by,
             NULL id_grupo, --30
             NULL dt_last_identification_tstz,
             NULL organ_shipper,
             il.id_language id_language,
             NULL id_specialty, -- falta ir buscar a especialidade em que este report foi gerado.
             NULL author,
             er.id_reports
              FROM epis_report er
             INNER JOIN episode epis
                ON epis.id_episode = er.id_episode
             INNER JOIN reports rep
                ON rep.id_reports = er.id_reports
             INNER JOIN rep_ins_soft_doc_type risdt
                ON risdt.id_reports = er.id_reports
             INNER JOIN institution_language il
                ON il.id_institution = pk_episode.get_epis_institution_id(i_lang, i_prof, er.id_episode)
             WHERE er.id_epis_report = i_epis_report
               AND (( --catch the printed reports and the discharge reports
                    ( --catch the printed...
                     risdt.flg_print_type = 'P' --is the report printed by print tool
                     AND (er.flg_status = 'I' OR er.flg_status = 'S') --is the report printed or saved in print tool
                     AND (er.flg_report_origin IS NULL OR er.flg_report_origin = 'P')) OR
                    ( -- and... catch the discharge
                     risdt.flg_print_type = 'D' -- the report was generated on discharge
                     AND er.flg_report_origin = 'D' --is the report printed in print tool/discharge
                    )) OR i_flg_share_grid = 'Y') --AND rep.flg_avlble_in_doc_archive = g_yes --is report available in documents archive?
               AND risdt.id_institution IN (pk_episode.get_epis_institution_id(i_lang, i_prof, er.id_episode), 0)
               AND risdt.id_software IN (pk_episode.get_soft_by_epis_type(epis.id_epis_type, epis.id_institution), 0)
               AND il.flg_available = g_yes
               AND er.id_doc_external IS NULL; -- to ensure we don't add the same document twice
    
        l_doc_original     doc_original.id_doc_original%TYPE;
        l_doc_external_row doc_external%ROWTYPE;
        l_rowids           table_varchar;
        l_doc_oid          VARCHAR2(4000 CHAR);
    BEGIN
    
        g_error := 'Get default original';
        IF NOT get_default_original(i_lang, i_prof, l_doc_original, o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        FOR r_epis_report IN c_epis_report
        LOOP
        
            l_rowids                                  := table_varchar();
            l_doc_external_row.id_doc_external        := ts_doc_external.next_key();
            l_doc_external_row.id_doc_type            := r_epis_report.id_doc_type;
            l_doc_external_row.num_doc                := r_epis_report.num_doc;
            l_doc_external_row.dt_emited              := r_epis_report.dt_emited;
            l_doc_external_row.notes                  := r_epis_report.notes;
            l_doc_external_row.dt_digit               := r_epis_report.dt_digit;
            l_doc_external_row.id_doc_ori_type        := r_epis_report.id_doc_ori_type; --l_doc_original  
            l_doc_external_row.id_doc_destination     := r_epis_report.id_doc_destination;
            l_doc_external_row.dt_expire              := r_epis_report.dt_expire;
            l_doc_external_row.id_external_request    := r_epis_report.id_external_request;
            l_doc_external_row.desc_doc_type          := r_epis_report.desc_doc_type;
            l_doc_external_row.desc_doc_ori_type      := r_epis_report.desc_doc_ori_type;
            l_doc_external_row.desc_doc_destination   := r_epis_report.desc_doc_destination;
            l_doc_external_row.id_episode             := r_epis_report.id_episode;
            l_doc_external_row.id_patient             := r_epis_report.id_patient;
            l_doc_external_row.flg_status             := r_epis_report.flg_status;
            l_doc_external_row.local_emited           := r_epis_report.local_emited;
            l_doc_external_row.id_institution         := r_epis_report.id_institution;
            l_doc_external_row.flg_sent_by            := r_epis_report.flg_sent_by;
            l_doc_external_row.flg_received           := r_epis_report.flg_received;
            l_doc_external_row.id_doc_original        := r_epis_report.id_doc_original;
            l_doc_external_row.desc_doc_original      := r_epis_report.desc_doc_original;
            l_doc_external_row.id_professional        := r_epis_report.id_professional;
            l_doc_external_row.title                  := r_epis_report.title;
            l_doc_external_row.dt_inserted            := r_epis_report.dt_inserted;
            l_doc_external_row.dt_updated             := r_epis_report.dt_updated;
            l_doc_external_row.id_professional_upd    := r_epis_report.id_professional_upd;
            l_doc_external_row.id_prof_perf_by        := r_epis_report.id_prof_perf_by;
            l_doc_external_row.desc_perf_by           := r_epis_report.desc_perf_by;
            l_doc_external_row.id_grupo               := l_doc_external_row.id_doc_external;
            l_doc_external_row.dt_last_identification := r_epis_report.dt_last_identification_tstz;
            l_doc_external_row.organ_shipper          := r_epis_report.organ_shipper;
            l_doc_external_row.id_language            := r_epis_report.id_language;
            l_doc_external_row.id_specialty           := r_epis_report.id_specialty;
            l_doc_external_row.author                 := r_epis_report.author;
        
            g_error := 'INSERT DOC_EXTERNAL';
            ts_doc_external.ins(rec_in => l_doc_external_row, handle_error_in => TRUE, rows_out => l_rowids);
        
            g_error := 'Process_insert DOC_EXTERNAL';
            t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'DOC_EXTERNAL',
                                          i_rowids     => l_rowids,
                                          o_error      => o_error);
        
            UPDATE epis_report er
               SET er.id_doc_external = l_doc_external_row.id_doc_external
             WHERE er.id_epis_report = r_epis_report.id_epis_report;
        
            o_id_doc_external := l_doc_external_row.id_doc_external;
        
            -- Using EPIS_REPORT OID for generated reports
            l_doc_oid := pk_sysconfig.get_config('ALERT_OID_HIE_EPIS_REPORT', i_prof) || '.' ||
                         r_epis_report.id_epis_report;
        
            UPDATE doc_external de
               SET de.doc_oid = l_doc_oid
             WHERE de.id_doc_external = l_doc_external_row.id_doc_external;
        
            -- log document activity
            IF NOT pk_doc_activity.log_document_activity(i_lang            => i_lang,
                                                         i_prof            => i_prof,
                                                         i_doc_id          => l_doc_external_row.id_doc_external,
                                                         i_operation       => 'CREATE',
                                                         i_source          => 'EHR',
                                                         i_target          => 'EHR',
                                                         i_operation_param => NULL,
                                                         o_error           => o_error)
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
                                              g_package_owner,
                                              g_package_name,
                                              'CREATE_REPORT_DOCUMENT',
                                              o_error);
            RETURN FALSE;
    END create_report_document;

    FUNCTION get_doc_image_mime_type(i_doc_imag IN doc_image.id_doc_image%TYPE) RETURN VARCHAR2 IS
        l_ext       doc_file_type.extension%TYPE;
        l_mime_type doc_file_type.mime_type%TYPE;
        l_lang      language.id_language%TYPE := 2; --This function will be used in a view so we do not have the language argument
        --As this is only for a select in a table we forced to EN-US
        l_prof profissional := profissional(NULL, NULL, NULL); --The same as before, we do not have these arguments
    
    BEGIN
        g_error := 'Get mime_type';
        SELECT mime_type
          INTO l_mime_type
          FROM doc_image di
         WHERE di.id_doc_image = i_doc_imag;
    
        IF l_mime_type IS NULL
        THEN
            g_error := 'Get file extension';
            l_ext   := pk_doc.get_doc_image_extension(i_lang => l_lang, i_prof => l_prof, i_id_img => i_doc_imag);
            IF l_ext IS NULL
            THEN
                --Default extension
                l_ext := '*';
            END IF;
        
            g_error := 'Get mime type using extension';
            SELECT dft.mime_type
              INTO l_mime_type
              FROM doc_file_type dft
             WHERE dft.extension = l_ext;
        END IF;
    
        RETURN l_mime_type;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_doc_image_mime_type;

    FUNCTION get_original_oid
    (
        i_lang         IN NUMBER,
        i_prof         IN profissional,
        i_doc_external IN doc_external.id_doc_external%TYPE,
        o_oid          OUT VARCHAR2,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        o_oid := get_doc_oid(i_prof, i_doc_external);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_ORIGINAL_OID',
                                              o_error);
            RETURN FALSE;
    END get_original_oid;
    --
    FUNCTION get_count_image
    (
        i_lang         IN NUMBER,
        i_prof         IN profissional,
        i_doc_external IN doc_external.id_doc_external%TYPE
    ) RETURN NUMBER IS
    
        l_count_img NUMBER(6) := 0;
    BEGIN
        --Return number of images from a document
        SELECT COUNT(1)
          INTO l_count_img
          FROM (SELECT di.id_doc_image imag
                  FROM doc_image di
                 WHERE di.id_doc_external = i_doc_external
                   AND di.flg_status = g_img_active
                   AND di.doc_img IS NOT NULL
                   AND dbms_lob.compare(di.doc_img, empty_blob()) != 0
                UNION ALL
                SELECT er.id_epis_report imag
                  FROM epis_report er
                 WHERE er.id_doc_external = i_doc_external
                   AND (er.flg_status != g_no OR (er.flg_status = g_no AND er.flg_report_origin = 'D')));
    
        RETURN l_count_img;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN 0;
    END get_count_image;
    --
    FUNCTION has_blob
    (
        i_lang         IN NUMBER,
        i_prof         IN profissional,
        i_doc_external IN doc_external.id_doc_external%TYPE
    ) RETURN VARCHAR2 IS
    
        l_count_img NUMBER(6) := 0;
    BEGIN
        --Return number of images from a document
        SELECT COUNT(1)
          INTO l_count_img
          FROM (SELECT di.id_doc_image imag
                  FROM doc_image di
                 WHERE di.id_doc_external = i_doc_external
                   AND di.flg_status = g_img_active
                   AND di.doc_img IS NOT NULL
                   AND dbms_lob.compare(di.doc_img, empty_blob()) != 0
                UNION ALL
                SELECT er.id_epis_report imag
                  FROM epis_report er
                 WHERE er.id_doc_external = i_doc_external
                   AND (er.flg_status != g_no OR (er.flg_status = g_no AND er.flg_report_origin = 'D')));
    
        IF l_count_img > 0
        THEN
            RETURN g_yes;
        ELSE
            RETURN g_no;
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN 0;
    END has_blob;
    --
    FUNCTION get_count_image_list
    (
        i_lang         IN NUMBER,
        i_prof         IN profissional,
        i_doc_external IN table_number
    ) RETURN NUMBER IS
    
        l_count_img NUMBER(6) := 0;
    BEGIN
        --Return number of images from a list of documents
        SELECT COUNT(1)
          INTO l_count_img
          FROM (SELECT di.id_doc_image imag
                  FROM doc_image di
                 WHERE di.id_doc_external IN (SELECT column_value
                                                FROM TABLE(i_doc_external))
                   AND di.flg_status = g_img_active
                UNION ALL
                SELECT er.id_epis_report imag
                  FROM epis_report er
                 WHERE er.id_doc_external IN (SELECT column_value
                                                FROM TABLE(i_doc_external))
                   AND er.flg_status != g_no);
    
        RETURN l_count_img;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN 0;
    END get_count_image_list;

    /**
    * Get detail list (central pane) for the viewer 'all' filter
    *
    * @param   i_lang           language associated to the professional executing the request
    * @param   i_prof           professional, institution and software ids
    * @param   i_patient        patient id
    * @param   i_episode        episode id
    * @param   i_ext_req        referral id        
    * @param   i_btn            sys_button used to allow diferent behaviours depending on the button being used.
    * @param   i_doc_ori_type   document type - Can be ALL if NULL or a specific one
    * @param   o_list           output list
    * @param   o_error          an error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Rui Spratley
    * @version 2.6.0.4
    * @since   06-10-2010
    */
    FUNCTION get_doc_list_by_type
    (
        i_lang         IN NUMBER,
        i_prof         IN profissional,
        i_patient      IN patient.id_patient%TYPE,
        i_episode      IN episode.id_episode%TYPE,
        i_ext_req      IN p1_external_request.id_external_request%TYPE,
        i_btn          IN sys_button_prop.id_sys_button_prop%TYPE,
        i_doc_ori_type IN doc_ori_type.id_doc_ori_type%TYPE,
        o_list         OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
        document_tbl t_tbl_rec_document;
    
    BEGIN
    
        document_tbl := pk_doc.get_doc_list_by_type(i_lang         => i_lang,
                                                    i_prof         => i_prof,
                                                    i_patient      => i_patient,
                                                    i_episode      => i_episode,
                                                    i_ext_req      => i_ext_req,
                                                    i_btn          => i_btn,
                                                    i_doc_ori_type => i_doc_ori_type);
    
        OPEN o_list FOR
            SELECT *
              FROM (SELECT *
                      FROM TABLE(CAST(document_tbl AS t_tbl_rec_document)))
             ORDER BY created_date DESC;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_list);
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     g_package_owner,
                                                     g_package_name,
                                                     'GET_DOC_LIST_BY_TYPE',
                                                     o_error);
    END get_doc_list_by_type;

    FUNCTION get_doc_list_by_category
    (
        i_lang         IN NUMBER,
        i_prof         IN profissional,
        i_patient      IN patient.id_patient%TYPE,
        i_episode      IN episode.id_episode%TYPE,
        i_ext_req      IN p1_external_request.id_external_request%TYPE,
        i_btn          IN sys_button_prop.id_sys_button_prop%TYPE,
        i_doc_ori_type IN doc_ori_type.id_doc_ori_type%TYPE,
        i_id_doc_type  IN doc_type.id_doc_type%TYPE,
        o_list         OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
        document_tbl t_tbl_rec_document;
    
    BEGIN
    
        document_tbl := pk_doc.get_doc_list_by_category_tbl(i_lang         => i_lang,
                                                            i_prof         => i_prof,
                                                            i_patient      => i_patient,
                                                            i_episode      => i_episode,
                                                            i_ext_req      => i_ext_req,
                                                            i_btn          => i_btn,
                                                            i_doc_ori_type => i_doc_ori_type,
                                                            i_id_doc_type  => i_id_doc_type);
    
        OPEN o_list FOR
            SELECT *
              FROM (SELECT *
                      FROM TABLE(CAST(document_tbl AS t_tbl_rec_document)))
             ORDER BY created_date DESC;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_list);
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     g_package_owner,
                                                     g_package_name,
                                                     'GET_DOC_LIST_BY_TYPE',
                                                     o_error);
    END get_doc_list_by_category;

    /**
    * Get detail list (central pane) for the viewer 'all' filter
    *
    * @param   i_lang           language associated to the professional executing the request
    * @param   i_prof           professional, institution and software ids
    * @param   i_patient        patient id
    * @param   i_episode        episode id
    * @param   i_ext_req        referral id        
    * @param   i_btn            sys_button used to allow diferent behaviours depending on the button being used.
    * @param   i_doc_ori_type   document type - Can be ALL if NULL or a specific one
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Daniel Silva
    * @version 2.6.3
    * @since  2013.09.19
    */
    FUNCTION get_doc_list_by_type
    (
        i_lang         IN NUMBER,
        i_prof         IN profissional,
        i_patient      IN patient.id_patient%TYPE,
        i_episode      IN episode.id_episode%TYPE,
        i_ext_req      IN p1_external_request.id_external_request%TYPE,
        i_btn          IN sys_button_prop.id_sys_button_prop%TYPE,
        i_doc_ori_type IN doc_ori_type.id_doc_ori_type%TYPE
    ) RETURN t_tbl_rec_document IS
    
        l_ret        BOOLEAN;
        o_error      t_error_out;
        my_exception EXCEPTION;
        l_inst       table_number;
        l_patient    patient.id_patient%TYPE;
        l_episode    episode.id_episode%TYPE;
        l_ext_req    p1_external_request.id_external_request%TYPE;
        l_my_pt      profile_template.id_profile_template%TYPE;
    
        document_tbl            t_tbl_rec_document := t_tbl_rec_document();
        o_document_tbl          t_tbl_rec_document := t_tbl_rec_document();
        body_diagram_tbl        t_tbl_rec_document := t_tbl_rec_document();
        l_include_body_diagrams sys_config.value%TYPE;
    
        l_document_tbl_count NUMBER := 0;
    
    BEGIN
    
        g_error := 'Get all related institutions';
        IF NOT pk_utils.get_institutions_sib(i_lang  => i_lang,
                                             i_prof  => i_prof,
                                             i_inst  => i_prof.institution,
                                             o_list  => l_inst,
                                             o_error => o_error)
        THEN
            RAISE my_exception;
        ELSE
            IF l_inst.count = 0
            THEN
                l_inst.extend;
                l_inst(1) := i_prof.institution;
            END IF;
        END IF;
    
        g_error := 'GET PROFILE';
        l_ret   := get_profile_template(i_lang, i_prof, l_my_pt, o_error);
    
        --Validate profile template from professional
        IF NOT l_ret
        THEN
            RAISE my_exception;
        END IF;
    
        -- Validate context (Patient, Episode and External Request)
        SELECT decode(pk_doc.get_config('DOC_PATIENT', i_prof, l_my_pt, i_btn), g_doc_config_y, i_patient, NULL),
               decode(pk_doc.get_config('DOC_EPISODE', i_prof, l_my_pt, i_btn), g_doc_config_y, i_episode, NULL),
               decode(pk_doc.get_config('DOC_REFERRAL', i_prof, l_my_pt, i_btn), g_doc_config_y, i_ext_req, NULL)
          INTO l_patient, l_episode, l_ext_req
          FROM dual;
    
        g_error := 'OPEN O_LIST';
        SELECT t_rec_document(dot.id_doc_ori_type, -- id_doc_ori_type,
                              pk_translation.get_translation(i_lang, dot.code_doc_ori_type), -- oritypedesc,
                              pk_translation.get_translation(i_lang, dt.code_doc_type), -- typedesc,
                              de.title,
                              de.id_doc_external, -- iddoc,
                              pk_doc.get_comments_line_with_count(i_lang,
                                                                  i_prof,
                                                                  de.id_doc_external,
                                                                  dot.flg_comment_type), -- numcomments,
                              CASE has_blob(i_lang, i_prof, de.id_doc_external)
                                  WHEN g_yes THEN
                                   get_count_image(i_lang, i_prof, de.id_doc_external)
                                  ELSE
                                   NULL
                              END, -- numimages,
                              pk_date_utils.get_timestamp_str(i_lang, i_prof, de.dt_emited, NULL),
                              pk_date_utils.get_timestamp_str(i_lang, i_prof, de.dt_expire, NULL),
                              --pk_date_utils.dt_chr(i_lang, de.dt_emited, i_prof), -- dt_emited,
                              --pk_date_utils.dt_chr(i_lang, de.dt_expire, i_prof), -- dt_expire,                          
                              pk_date_utils.date_send_tsz(i_lang,
                                                          decode(is_first_version(de.id_doc_external),
                                                                 g_yes,
                                                                 decode(de.flg_received,
                                                                        g_yes,
                                                                        de.dt_emited,
                                                                        de.dt_inserted),
                                                                 de.dt_updated),
                                                          i_prof.institution,
                                                          i_prof.software), -- lastupdateddate
                              nvl(decode(is_first_version(de.id_doc_external), g_yes, de.author, NULL), -- get de.author on the first document version                     
                                  pk_prof_utils.get_name_signature(i_lang,
                                                                   i_prof,
                                                                   nvl(de.id_professional_upd, de.id_professional))), -- lastupdatedby
                              nvl(decode(is_first_version(de.id_doc_external), g_yes, de.local_emited, NULL), -- get de.local_emited on the first document version                     
                                  pk_utils.get_institution_name(i_lang, nvl(de.update_institution, de.id_institution))), -- lastupdatedby_inst
                              pk_prof_utils.get_spec_signature(i_lang,
                                                               i_prof,
                                                               nvl(de.id_professional_upd, de.id_professional),
                                                               nvl(de.dt_updated, de.dt_inserted),
                                                               de.id_episode), -- todo_especialidade,
                              CASE has_blob(i_lang, i_prof, de.id_doc_external)
                                  WHEN g_yes THEN
                                   get_main_thumb_url(i_lang, i_prof, de.id_doc_external)
                                  ELSE
                                   NULL
                              END, -- url_thumb,
                              CASE has_blob(i_lang, i_prof, de.id_doc_external)
                                  WHEN g_yes THEN
                                   get_main_thumb_mime_type(i_lang, i_prof, de.id_doc_external)
                                  ELSE
                                   NULL
                              END, -- mime_type,
                              get_main_thumb_extension(i_lang, i_prof, de.id_doc_external), -- format_type,
                              de.flg_status,
                              dot.flg_comment_type,
                              de.id_doc_external,
                              nvl(de.id_grupo, de.id_doc_external), -- id_folder,
                              xds.id_xds_document_submission,
                              pk_utils.create_oid(i_prof,
                                                  'ALERT_OID_HIE_XDS_SUBMISSION_SET',
                                                  xds.id_xds_document_submission), -- submission_set_unique_id
                              get_doc_oid(i_prof, de.id_doc_external), -- doc_oid
                              xds.flg_submission_type, -- submission_status,
                              pk_date_utils.dt_chr(i_lang, xds.dt_submission_time, i_prof), -- subm_dt_char,
                              pk_date_utils.dt_chr_hour(i_lang, xds.dt_submission_time, i_prof), -- subm_dt_char_hour,
                              (SELECT id_epis_report
                                 FROM epis_report er
                                WHERE er.id_doc_external = de.id_doc_external
                                  AND er.flg_type = pk_print_tool.c_flg_type_current), -- id_epis_report,
                              de.num_doc,
                              pk_translation.get_translation(i_lang, de.id_specialty), -- specialty,
                              pk_translation.get_translation(i_lang, de.id_doc_original), -- original,
                              pk_translation.get_translation(i_lang, de.id_language), -- desc_language,
                              de.notes,
                              (SELECT COUNT(1)
                                 FROM doc_comments dc
                                WHERE dc.id_doc_external = de.id_doc_external
                                  AND dc.flg_cancel = 'N'), -- note_count,
                              is_doc_type_publishable(i_lang, i_prof, de.id_doc_type), -- FLG_PUBLISHABLE,
                              is_doc_type_download(i_lang, i_prof, de.id_doc_type), -- flg_download,
                              de.id_doc_type, -- id_doc_type 
                              pk_date_utils.date_send_tsz(i_lang,
                                                          decode(de.flg_received, g_yes, de.dt_emited, de.dt_inserted),
                                                          i_prof.institution,
                                                          i_prof.software), -- created_date,
                              nvl(de.author, pk_prof_utils.get_name_signature(i_lang, i_prof, de.id_professional)), --created_by
                              decode(de.flg_received,
                                     g_yes,
                                     de.local_emited,
                                     pk_utils.get_institution_name(i_lang, de.id_institution)),
                              de.id_patient, --id_patient
                              de.id_external_request, --id_external_request
                              de.id_institution, --id_institution   
                              de.id_episode, --id_episode
                              nvl(de.dt_updated, de.dt_inserted), --lastupdateddatetstz
                              de.flg_saved_outside --saved_outside
                              )
          BULK COLLECT
          INTO document_tbl
          FROM doc_type dt
          JOIN doc_external de
            ON (dt.id_doc_type = de.id_doc_type)
          JOIN doc_ori_type dot
            ON (de.id_doc_ori_type = dot.id_doc_ori_type)
          LEFT JOIN xds_document_submission xds
            ON xds.id_doc_external = nvl(de.id_grupo, de.id_doc_external) -- o join com a doc_ext tem de ser via ID_GRUPO
         WHERE ((de.id_patient = l_patient) OR (de.id_episode = l_episode) OR (de.id_external_request = l_ext_req))
           AND de.id_institution IN (SELECT column_value
                                       FROM TABLE(l_inst))
           AND de.flg_status IN (g_doc_active, g_doc_inactive)
           AND (i_doc_ori_type IS NULL OR de.id_doc_ori_type = i_doc_ori_type) --Filter by document type
           AND nvl(xds.flg_status, g_doc_active) = g_doc_active
         ORDER BY de.flg_status ASC, de.dt_inserted DESC, pk_translation.get_translation(i_lang, dot.code_doc_ori_type);
    
        g_error := 'GET BODY DIAGRAMS';
        IF pk_doc.is_arch_including_body_diag(i_lang, i_prof)
           AND (i_doc_ori_type IS NULL OR i_doc_ori_type = 3)
        THEN
            IF pk_doc.get_body_diagrams_as_document(i_lang          => i_lang,
                                                    i_prof          => i_prof,
                                                    i_patient       => i_patient,
                                                    o_body_diagrams => body_diagram_tbl,
                                                    o_error         => o_error)
            THEN
                --do nothing
                g_error := 'GET BODY DIAGRAMS SUCCEEDED';
            END IF;
        END IF;
    
        l_document_tbl_count := document_tbl.count;
        IF l_document_tbl_count > 0
        THEN
            FOR i IN 1 .. document_tbl.count
            LOOP
                o_document_tbl.extend();
                o_document_tbl(i) := document_tbl(i);
            END LOOP;
        END IF;
    
        IF body_diagram_tbl.count > 0
        THEN
            FOR i IN 1 .. body_diagram_tbl.count
            LOOP
                o_document_tbl.extend();
                o_document_tbl(i + l_document_tbl_count) := body_diagram_tbl(i);
            END LOOP;
        END IF;
    
        RETURN o_document_tbl;
    
    END get_doc_list_by_type;

    FUNCTION get_doc_list_by_category_tbl
    (
        i_lang         IN NUMBER,
        i_prof         IN profissional,
        i_patient      IN patient.id_patient%TYPE,
        i_episode      IN episode.id_episode%TYPE,
        i_ext_req      IN p1_external_request.id_external_request%TYPE,
        i_btn          IN sys_button_prop.id_sys_button_prop%TYPE,
        i_doc_ori_type IN doc_ori_type.id_doc_ori_type%TYPE,
        i_id_doc_type  IN doc_type.id_doc_type%TYPE
    ) RETURN t_tbl_rec_document IS
    
        l_ret        BOOLEAN;
        o_error      t_error_out;
        my_exception EXCEPTION;
        l_inst       table_number;
        l_patient    patient.id_patient%TYPE;
        l_episode    episode.id_episode%TYPE;
        l_ext_req    p1_external_request.id_external_request%TYPE;
        l_my_pt      profile_template.id_profile_template%TYPE;
    
        document_tbl            t_tbl_rec_document := t_tbl_rec_document();
        o_document_tbl          t_tbl_rec_document := t_tbl_rec_document();
        body_diagram_tbl        t_tbl_rec_document := t_tbl_rec_document();
        l_include_body_diagrams sys_config.value%TYPE;
    
        l_document_tbl_count NUMBER := 0;
    
    BEGIN
    
        g_error := 'Get all related institutions';
        IF NOT pk_utils.get_institutions_sib(i_lang  => i_lang,
                                             i_prof  => i_prof,
                                             i_inst  => i_prof.institution,
                                             o_list  => l_inst,
                                             o_error => o_error)
        THEN
            RAISE my_exception;
        ELSE
            IF l_inst.count = 0
            THEN
                l_inst.extend;
                l_inst(1) := i_prof.institution;
            END IF;
        END IF;
    
        g_error := 'GET PROFILE';
        l_ret   := get_profile_template(i_lang, i_prof, l_my_pt, o_error);
    
        --Validate profile template from professional
        IF NOT l_ret
        THEN
            RAISE my_exception;
        END IF;
    
        -- Validate context (Patient, Episode and External Request)
        SELECT decode(pk_doc.get_config('DOC_PATIENT', i_prof, l_my_pt, i_btn), g_doc_config_y, i_patient, NULL),
               decode(pk_doc.get_config('DOC_EPISODE', i_prof, l_my_pt, i_btn), g_doc_config_y, i_episode, NULL),
               decode(pk_doc.get_config('DOC_REFERRAL', i_prof, l_my_pt, i_btn), g_doc_config_y, i_ext_req, NULL)
          INTO l_patient, l_episode, l_ext_req
          FROM dual;
    
        g_error := 'OPEN O_LIST';
        SELECT t_rec_document(dot.id_doc_ori_type, -- id_doc_ori_type,
                              pk_translation.get_translation(i_lang, dot.code_doc_ori_type), -- oritypedesc,
                              pk_translation.get_translation(i_lang, dt.code_doc_type), -- typedesc,
                              de.title,
                              de.id_doc_external, -- iddoc,
                              pk_doc.get_comments_line_with_count(i_lang,
                                                                  i_prof,
                                                                  de.id_doc_external,
                                                                  dot.flg_comment_type), -- numcomments,
                              get_count_image(i_lang, i_prof, de.id_doc_external), -- numimages,
                              pk_date_utils.dt_chr(i_lang, de.dt_emited, i_prof), -- dt_emited,
                              pk_date_utils.dt_chr(i_lang, de.dt_expire, i_prof), -- dt_expire,                          
                              pk_date_utils.date_send_tsz(i_lang,
                                                          decode(is_first_version(de.id_doc_external),
                                                                 g_yes,
                                                                 decode(de.flg_received,
                                                                        g_yes,
                                                                        de.dt_emited,
                                                                        de.dt_inserted),
                                                                 de.dt_updated),
                                                          i_prof.institution,
                                                          i_prof.software), -- lastupdateddate
                              nvl(decode(is_first_version(de.id_doc_external), g_yes, de.author, NULL), -- get de.author on the first document version                     
                                  pk_prof_utils.get_name_signature(i_lang,
                                                                   i_prof,
                                                                   nvl(de.id_professional_upd, de.id_professional))), -- lastupdatedby
                              nvl(decode(is_first_version(de.id_doc_external), g_yes, de.local_emited, NULL), -- get de.local_emited on the first document version                     
                                  pk_utils.get_institution_name(i_lang, nvl(de.update_institution, de.id_institution))), -- lastupdatedby_inst
                              pk_prof_utils.get_spec_signature(i_lang,
                                                               i_prof,
                                                               nvl(de.id_professional_upd, de.id_professional),
                                                               nvl(de.dt_updated, de.dt_inserted),
                                                               de.id_episode), -- todo_especialidade,
                              get_main_thumb_url(i_lang, i_prof, de.id_doc_external), -- url_thumb,
                              get_main_thumb_mime_type(i_lang, i_prof, de.id_doc_external), -- mime_type,
                              get_main_thumb_extension(i_lang, i_prof, de.id_doc_external), -- format_type,
                              de.flg_status,
                              dot.flg_comment_type,
                              de.id_doc_external,
                              nvl(de.id_grupo, de.id_doc_external), -- id_folder,
                              xds.id_xds_document_submission,
                              pk_utils.create_oid(i_prof,
                                                  'ALERT_OID_HIE_XDS_SUBMISSION_SET',
                                                  xds.id_xds_document_submission), -- submission_set_unique_id
                              get_doc_oid(i_prof, de.id_doc_external), -- doc_oid
                              xds.flg_submission_type, -- submission_status,
                              pk_date_utils.dt_chr(i_lang, xds.dt_submission_time, i_prof), -- subm_dt_char,
                              pk_date_utils.dt_chr_hour(i_lang, xds.dt_submission_time, i_prof), -- subm_dt_char_hour,
                              (SELECT id_epis_report
                                 FROM epis_report er
                                WHERE er.id_doc_external = de.id_doc_external
                                  AND er.flg_type = pk_print_tool.c_flg_type_current), -- id_epis_report,
                              de.num_doc,
                              pk_translation.get_translation(i_lang, de.id_specialty), -- specialty,
                              pk_translation.get_translation(i_lang, de.id_doc_original), -- original,
                              pk_translation.get_translation(i_lang, de.id_language), -- desc_language,
                              de.notes,
                              (SELECT COUNT(1)
                                 FROM doc_comments dc
                                WHERE dc.id_doc_external = de.id_doc_external
                                  AND dc.flg_cancel = 'N'), -- note_count,
                              is_doc_type_publishable(i_lang, i_prof, de.id_doc_type), -- FLG_PUBLISHABLE,
                              is_doc_type_download(i_lang, i_prof, de.id_doc_type), -- flg_download,
                              de.id_doc_type, -- id_doc_type 
                              pk_date_utils.date_send_tsz(i_lang,
                                                          decode(de.flg_received, g_yes, de.dt_emited, de.dt_inserted),
                                                          i_prof.institution,
                                                          i_prof.software), -- created_date,
                              nvl(de.author, pk_prof_utils.get_name_signature(i_lang, i_prof, de.id_professional)), --created_by
                              decode(de.flg_received,
                                     g_yes,
                                     de.local_emited,
                                     pk_utils.get_institution_name(i_lang, de.id_institution)),
                              de.id_patient, --id_patient
                              de.id_external_request, --id_external_request
                              de.id_institution, --id_institution   
                              de.id_episode, --id_episode
                              nvl(de.dt_updated, de.dt_inserted), --lastupdateddatetstz
                              de.flg_saved_outside --flg_saved_outside
                              )
          BULK COLLECT
          INTO document_tbl
          FROM doc_type dt
          JOIN doc_external de
            ON (dt.id_doc_type = de.id_doc_type)
          JOIN doc_ori_type dot
            ON (de.id_doc_ori_type = dot.id_doc_ori_type)
          LEFT JOIN xds_document_submission xds
            ON xds.id_doc_external = nvl(de.id_grupo, de.id_doc_external) -- o join com a doc_ext tem de ser via ID_GRUPO
         WHERE ((de.id_patient = l_patient) OR (de.id_episode = l_episode) OR (de.id_external_request = l_ext_req))
           AND de.id_institution IN (SELECT column_value
                                       FROM TABLE(l_inst))
           AND de.flg_status IN (g_doc_active, g_doc_inactive)
           AND (i_doc_ori_type IS NULL OR de.id_doc_ori_type = i_doc_ori_type) --Filter by document type
           AND (i_id_doc_type IS NULL OR dt.id_doc_type = i_id_doc_type)
           AND nvl(xds.flg_status, g_doc_active) = g_doc_active
         ORDER BY de.flg_status ASC, de.dt_inserted DESC, pk_translation.get_translation(i_lang, dot.code_doc_ori_type);
    
        g_error := 'GET BODY DIAGRAMS';
        IF pk_doc.is_arch_including_body_diag(i_lang, i_prof)
           AND (i_doc_ori_type IS NULL OR i_doc_ori_type = 3)
           AND (i_id_doc_type IS NULL OR i_id_doc_type = 2622)
        THEN
        
            IF pk_doc.get_body_diagrams_as_document(i_lang          => i_lang,
                                                    i_prof          => i_prof,
                                                    i_patient       => i_patient,
                                                    o_body_diagrams => body_diagram_tbl,
                                                    o_error         => o_error)
            THEN
                --do nothing
                g_error := 'GET BODY DIAGRAMS SUCCEEDED';
            END IF;
        END IF;
    
        l_document_tbl_count := document_tbl.count;
        IF l_document_tbl_count > 0
        THEN
            FOR i IN 1 .. document_tbl.count
            LOOP
                o_document_tbl.extend();
                o_document_tbl(i) := document_tbl(i);
            END LOOP;
        END IF;
    
        IF body_diagram_tbl.count > 0
        THEN
            FOR i IN 1 .. body_diagram_tbl.count
            LOOP
                o_document_tbl.extend();
                o_document_tbl(i + l_document_tbl_count) := body_diagram_tbl(i);
            END LOOP;
        END IF;
    
        RETURN o_document_tbl;
    
    END get_doc_list_by_category_tbl;

    /******************************************************************************
      OBJECTIVO:   Actualizar, no reset, os pacientes de um episódio
      PARAMETROS:  Entrada: I_LANG              - L?ngua registada como prefer?ncia do profissional
                            I_PROF              - Profissional que altera comentarios 
                            I_table_episode     - Id episodios
    
               Saida:   O_ERROR       - erro
    
     CRIA??O: Rita Lopes 2010/10/14
     NOTAS:
    *********************************************************************************/
    FUNCTION clear_documents_reset
    (
        i_lang             IN NUMBER,
        i_prof             IN profissional,
        i_clear_admin_docs IN VARCHAR2,
        i_table_episodes   IN table_number,
        i_table_patients   IN table_number,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        l_tbl_docexternal table_number;
        l_result          NUMBER;
        l_rowids          table_varchar;
    BEGIN
        g_error := 'EXECUTE IMMEDIATE';
        EXECUTE IMMEDIATE 'SELECT alert_reset.check_environment FROM dual'
            INTO l_result;
    
        IF l_result = 1
        THEN
        
            g_error := 'SELECT ID_DOC_EXTERNAL';
            SELECT id_doc_external
              BULK COLLECT
              INTO l_tbl_docexternal
              FROM (SELECT d.id_doc_external, d.id_doc_ori_type
                      FROM doc_external d
                     WHERE EXISTS (SELECT /*+dynamic_sampling (t1 10)*/
                             1
                              FROM TABLE(i_table_episodes) t1
                             WHERE t1.column_value = d.id_episode)
                    UNION ALL
                    SELECT d.id_doc_external, d.id_doc_ori_type
                      FROM doc_external d
                     WHERE d.id_episode IS NULL
                       AND EXISTS (SELECT /*+dynamic_sampling (t 10)*/
                             1
                              FROM TABLE(i_table_patients) t
                             WHERE t.column_value = d.id_patient))
             WHERE (i_clear_admin_docs = pk_alert_constant.g_no AND id_doc_ori_type != 9)
                OR i_clear_admin_docs = pk_alert_constant.g_yes;
        
            IF l_tbl_docexternal.count > 0
            THEN
                -- update id_patient    
                g_error := 'UPDATE DOC_EXTERNAL';
                FOR i IN 1 .. l_tbl_docexternal.count
                LOOP
                    l_rowids := table_varchar();
                
                    g_error := 'Call ts_doc_external.upd / ID_DOC_EXTERNAL_IN=' || l_tbl_docexternal(i);
                    ts_doc_external.upd(id_doc_external_in => l_tbl_docexternal(i),
                                        id_patient_in      => -1,
                                        id_institution_in  => -1,
                                        flg_status_in      => 'I',
                                        rows_out           => l_rowids);
                
                    g_error := 'Call t_data_gov_mnt.process_update';
                    t_data_gov_mnt.process_update(i_lang       => i_lang,
                                                  i_prof       => i_prof,
                                                  i_table_name => 'DOC_EXTERNAL',
                                                  i_rowids     => l_rowids,
                                                  o_error      => o_error);
                
                END LOOP;
            END IF;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'CLEAR_DOCUMENTS_RESET',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
    END clear_documents_reset;

    --
    FUNCTION get_doc_types
    (
        i_lang         IN NUMBER,
        i_prof         IN profissional,
        i_patient      IN patient.id_patient%TYPE,
        i_episode      IN episode.id_episode%TYPE,
        i_ext_req      IN p1_external_request.id_external_request%TYPE,
        i_btn          IN sys_button_prop.id_sys_button_prop%TYPE,
        i_doc_ori_type IN doc_ori_type.id_doc_ori_type%TYPE,
        o_list         OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_ret        BOOLEAN;
        my_exception EXCEPTION;
        l_my_pt      profile_template.id_profile_template%TYPE;
    
    BEGIN
    
        g_error := 'GET PROFILE';
        l_ret   := get_profile_template(i_lang, i_prof, l_my_pt, o_error);
    
        --Validate profile template from professional
        IF NOT l_ret
        THEN
            RAISE my_exception;
        END IF;
    
        g_error := 'OPEN O_LIST';
        OPEN o_list FOR
            SELECT id_doc_type, desc_doc_type, flg_publishable, rank, flg_comment_type
              FROM (SELECT dtc.id_doc_type,
                           pk_translation.get_translation(i_lang, dt.code_doc_type) desc_doc_type,
                           dtc.flg_publishable,
                           dt.rank,
                           dot.flg_comment_type,
                           row_number() over(PARTITION BY dtc.id_doc_type ORDER BY dtc.id_institution DESC, dtc.id_software DESC, dtc.id_profile_template DESC) rn
                      FROM doc_types_config dtc
                     INNER JOIN doc_type dt
                        ON dt.id_doc_type = dtc.id_doc_type
                     INNER JOIN doc_ori_type dot
                        ON dt.id_doc_ori_type = dot.id_doc_ori_type
                     WHERE dtc.id_doc_ori_type_parent = i_doc_ori_type
                       AND dt.flg_available = pk_alert_constant.g_available
                       AND dtc.id_institution IN (i_prof.institution, 0)
                       AND dtc.id_software IN (i_prof.software, 0)
                       AND dtc.id_profile_template IN (l_my_pt, 0)
                       AND pk_translation.get_translation(i_lang, dt.code_doc_type) IS NOT NULL)
             WHERE rn = 1
               AND desc_doc_type IS NOT NULL
             ORDER BY rank, desc_doc_type;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_list);
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     g_package_owner,
                                                     g_package_name,
                                                     'GET_DOC_TYPES',
                                                     o_error);
    END get_doc_types;

    FUNCTION get_doc_types
    (
        i_lang         IN NUMBER,
        i_prof         IN profissional,
        i_patient      IN patient.id_patient%TYPE,
        i_episode      IN episode.id_episode%TYPE,
        i_ext_req      IN p1_external_request.id_external_request%TYPE,
        i_btn          IN sys_button_prop.id_sys_button_prop%TYPE,
        i_doc_ori_type IN doc_ori_type.id_doc_ori_type%TYPE
    ) RETURN t_tbl_core_domain IS
    
        l_ret        BOOLEAN;
        my_exception EXCEPTION;
        l_my_pt      profile_template.id_profile_template%TYPE;
    
        l_return t_tbl_core_domain;
        l_error  t_error_out;
    
    BEGIN
    
        g_error := 'GET PROFILE';
        l_ret   := get_profile_template(i_lang, i_prof, l_my_pt, l_error);
    
        --Validate profile template from professional
        IF NOT l_ret
        THEN
            RAISE my_exception;
        END IF;
    
        g_error := 'OPEN L_RETURN';
        SELECT *
          BULK COLLECT
          INTO l_return
          FROM (SELECT t_row_core_domain(internal_name => NULL,
                                         desc_domain   => desc_doc_type,
                                         domain_value  => id_doc_type,
                                         order_rank    => NULL,
                                         img_name      => NULL)
                  FROM (SELECT id_doc_type, desc_doc_type --, flg_publishable, rank, flg_comment_type
                          FROM (SELECT dtc.id_doc_type,
                                       pk_translation.get_translation(i_lang, dt.code_doc_type) desc_doc_type,
                                       dtc.flg_publishable,
                                       dt.rank,
                                       dot.flg_comment_type,
                                       row_number() over(PARTITION BY dtc.id_doc_type ORDER BY dtc.id_institution DESC, dtc.id_software DESC, dtc.id_profile_template DESC) rn
                                  FROM doc_types_config dtc
                                 INNER JOIN doc_type dt
                                    ON dt.id_doc_type = dtc.id_doc_type
                                 INNER JOIN doc_ori_type dot
                                    ON dt.id_doc_ori_type = dot.id_doc_ori_type
                                 WHERE dtc.id_doc_ori_type_parent = i_doc_ori_type
                                   AND dt.flg_available = pk_alert_constant.g_available
                                   AND dtc.id_institution IN (i_prof.institution, 0)
                                   AND dtc.id_software IN (i_prof.software, 0)
                                   AND dtc.id_profile_template IN (l_my_pt, 0)
                                   AND pk_translation.get_translation(i_lang, dt.code_doc_type) IS NOT NULL)
                         WHERE rn = 1
                           AND desc_doc_type IS NOT NULL
                         ORDER BY rank, desc_doc_type));
    
        RETURN l_return;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_DOC_TYPES',
                                              o_error    => l_error);
            pk_alert_exceptions.reset_error_state;
            RETURN t_tbl_core_domain();
    END get_doc_types;

    FUNCTION get_doc_publishing_data
    (
        i_lang            IN NUMBER,
        i_prof            IN profissional,
        i_id_doc_external IN doc_external.id_doc_external%TYPE,
        o_list            OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'OPEN O_LIST';
        OPEN o_list FOR
            SELECT xdsccs.id_xds_doc_sub_conf_code_set,
                   xdsccs.desc_conf_code_set,
                   xdscc.conf_code,
                   xdscc.desc_conf_code,
                   xdscc.coding_schema
              FROM xds_document_submission xds, xds_doc_sub_conf_code_set xdsccs, xds_document_sub_conf_code xdscc
             WHERE xds.id_doc_external = (SELECT nvl(id_grupo, id_doc_external)
                                            FROM doc_external
                                           WHERE id_doc_external = i_id_doc_external)
               AND xds.flg_status = 'A' -- only active row (the last submission)
               AND xds.flg_submission_type IN
                   (pk_hie_xds.g_flg_submission_status_n, pk_hie_xds.g_flg_submission_status_u) -- only New or Updated Submissions
               AND xds.flg_submission_status IN (pk_hie_xds.g_flg_submission_status_s) -- and sent with success to INTER-ALERT
               AND xds.id_xds_document_submission = xdsccs.id_xds_document_submission
               AND xds.id_xds_document_submission = xdscc.id_xds_document_submission;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_list);
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     g_package_owner,
                                                     g_package_name,
                                                     'GET_DOC_PUBLISHING_DATA',
                                                     o_error);
    END get_doc_publishing_data;

    --
    FUNCTION is_doc_type_publishable
    (
        i_lang     IN NUMBER,
        i_prof     IN profissional,
        i_doc_type IN doc_ori_type.id_doc_ori_type%TYPE
    ) RETURN VARCHAR2 IS
    
        l_ret        BOOLEAN;
        l_error      t_error_out;
        my_exception EXCEPTION;
        l_number     table_number;
        l_my_pt      profile_template.id_profile_template%TYPE;
    
    BEGIN
    
        g_error := 'GET PROFILE';
        l_ret   := get_profile_template(i_lang, i_prof, l_my_pt, l_error);
    
        --Validate profile template from professional
        IF NOT l_ret
        THEN
            RAISE my_exception;
        END IF;
    
        g_error := 'OPEN O_LIST';
        SELECT 1
          BULK COLLECT
          INTO l_number
          FROM doc_types_config dtc
         INNER JOIN doc_type dt
            ON dt.id_doc_type = dtc.id_doc_type
         WHERE dtc.id_doc_type = i_doc_type
           AND dt.flg_available = 'Y'
           AND dtc.id_institution IN (i_prof.institution, 0)
           AND dtc.id_software IN (i_prof.software, 0)
           AND dtc.id_profile_template IN (l_my_pt, 0)
           AND dtc.flg_publishable = 'Y';
    
        IF SQL%FOUND
        THEN
            RETURN 'Y';
        ELSE
            RETURN 'N';
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_DOC_TYPES',
                                              l_error);
            RETURN 'N';
    END is_doc_type_publishable;
    --

    --
    FUNCTION get_categories
    (
        i_lang  IN NUMBER,
        i_prof  IN profissional,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_ret        BOOLEAN;
        my_exception EXCEPTION;
        l_my_pt      profile_template.id_profile_template%TYPE;
    
    BEGIN
    
        g_error := 'GET PROFILE';
        l_ret   := get_profile_template(i_lang, i_prof, l_my_pt, o_error);
    
        --Validate profile template from professional
        IF NOT l_ret
        THEN
            RAISE my_exception;
        END IF;
    
        g_error := 'OPEN O_LIST';
        OPEN o_list FOR
            SELECT t.id_doc_ori_type, pk_translation.get_translation(i_lang, dot.code_doc_ori_type) desc_ori_type
              FROM (SELECT c.id_doc_ori_type_parent id_doc_ori_type
                      FROM doc_types_config c
                     WHERE c.id_institution IN (i_prof.institution, 0)
                       AND c.id_software IN (i_prof.software, 0)
                       AND c.id_profile_template IN (l_my_pt, 0)
                       AND c.id_doc_ori_type_parent IS NOT NULL
                    UNION
                    SELECT c.id_doc_ori_type id_doc_ori_type
                      FROM doc_types_config c
                     WHERE c.id_institution IN (i_prof.institution, 0)
                       AND c.id_software IN (i_prof.software, 0)
                       AND c.id_profile_template IN (l_my_pt, 0)
                       AND c.id_doc_ori_type IS NOT NULL) t,
                   doc_ori_type dot
             WHERE t.id_doc_ori_type = dot.id_doc_ori_type
               AND dot.flg_available = 'Y'
             ORDER BY rank, desc_ori_type;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_list);
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     g_package_owner,
                                                     g_package_name,
                                                     'GET_CATEGORIES',
                                                     o_error);
        
    END get_categories;

    FUNCTION get_categories
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) RETURN t_tbl_core_domain IS
    
        l_ret           t_tbl_core_domain;
        l_check_profile BOOLEAN;
        l_my_pt         profile_template.id_profile_template%TYPE;
        l_error         t_error_out;
        my_exception    EXCEPTION;
    
    BEGIN
        g_error         := 'GET PROFILE';
        l_check_profile := get_profile_template(i_lang, i_prof, l_my_pt, l_error);
    
        --Validate profile template from professional
        IF NOT l_check_profile
        THEN
            RAISE my_exception;
        END IF;
    
        g_error := 'OPEN L_RET';
        SELECT *
          BULK COLLECT
          INTO l_ret
          FROM (SELECT t_row_core_domain(internal_name => NULL,
                                         desc_domain   => desc_ori_type,
                                         domain_value  => id_doc_ori_type,
                                         order_rank    => NULL,
                                         img_name      => NULL)
                  FROM (SELECT t.id_doc_ori_type,
                               pk_translation.get_translation(i_lang, dot.code_doc_ori_type) desc_ori_type
                          FROM (SELECT c.id_doc_ori_type_parent id_doc_ori_type
                                  FROM doc_types_config c
                                 WHERE c.id_institution IN (i_prof.institution, 0)
                                   AND c.id_software IN (i_prof.software, 0)
                                   AND c.id_profile_template IN (l_my_pt, 0)
                                   AND c.id_doc_ori_type_parent IS NOT NULL
                                UNION
                                SELECT c.id_doc_ori_type id_doc_ori_type
                                  FROM doc_types_config c
                                 WHERE c.id_institution IN (i_prof.institution, 0)
                                   AND c.id_software IN (i_prof.software, 0)
                                   AND c.id_profile_template IN (l_my_pt, 0)
                                   AND c.id_doc_ori_type IS NOT NULL) t,
                               doc_ori_type dot
                         WHERE t.id_doc_ori_type = dot.id_doc_ori_type
                           AND dot.flg_available = 'Y'
                         ORDER BY rank, desc_ori_type)
                 WHERE desc_ori_type IS NOT NULL);
    
        RETURN l_ret;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_CATEGORIES',
                                              o_error    => l_error);
            pk_alert_exceptions.reset_error_state;
            RETURN t_tbl_core_domain();
    END get_categories;

    --
    FUNCTION get_categories_tbl
    (
        i_lang  IN NUMBER,
        i_prof  IN profissional,
        o_error OUT t_error_out
    )
    
     RETURN table_number IS
    
        l_ret        table_number := table_number();
        l_ret_aux    BOOLEAN;
        my_exception EXCEPTION;
        l_my_pt      profile_template.id_profile_template%TYPE;
    
    BEGIN
    
        g_error   := 'GET PROFILE';
        l_ret_aux := get_profile_template(i_lang, i_prof, l_my_pt, o_error);
    
        --Validate profile template from professional
        IF NOT l_ret_aux
        THEN
            RAISE my_exception;
        END IF;
    
        g_error := 'OPEN CURSOR';
    
        SELECT tt.id_doc_ori_type
          BULK COLLECT
          INTO l_ret
          FROM (SELECT t.id_doc_ori_type,
                       t.flg_view,
                       t.rank,
                       rank() over(PARTITION BY t.id_doc_ori_type ORDER BY t.id_profile_template DESC, t.id_institution DESC, t.id_software DESC) AS rank1
                  FROM (SELECT c.id_doc_ori_type_parent id_doc_ori_type,
                               c.flg_view,
                               c.id_profile_template,
                               c.id_institution,
                               c.id_software,
                               c.rank
                          FROM doc_types_config c
                         WHERE c.id_institution IN (i_prof.institution, 0)
                           AND c.id_software IN (i_prof.software, 0)
                           AND c.id_profile_template IN (l_my_pt, 0)
                           AND c.id_doc_ori_type_parent IS NOT NULL
                        UNION
                        SELECT c.id_doc_ori_type id_doc_ori_type,
                               c.flg_view,
                               c.id_profile_template,
                               c.id_institution,
                               c.id_software,
                               c.rank
                          FROM doc_types_config c
                         WHERE c.id_institution IN (i_prof.institution, 0)
                           AND c.id_software IN (i_prof.software, 0)
                           AND c.id_profile_template IN (l_my_pt, 0)
                           AND c.id_doc_ori_type IS NOT NULL) t) tt,
               doc_ori_type dot
         WHERE tt.id_doc_ori_type = dot.id_doc_ori_type
           AND dot.flg_available = g_yes
           AND tt.flg_view = g_yes
           AND tt.rank1 = 1
         ORDER BY tt.rank;
    
        RETURN l_ret;
    
    EXCEPTION
        WHEN OTHERS THEN
            --pk_types.open_my_cursor(o_list);
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_CATEGORIES_TBL',
                                              o_error);
            RETURN l_ret;
        
    END get_categories_tbl;

    --
    FUNCTION get_doc_types_tbl
    (
        i_lang IN NUMBER,
        i_prof IN profissional,
        --i_doc_ori_type IN doc_ori_type.id_doc_ori_type%TYPE,
        o_error OUT t_error_out
    ) RETURN table_number IS
    
        l_ret        table_number := table_number();
        l_ret_aux    BOOLEAN;
        my_exception EXCEPTION;
        l_my_pt      profile_template.id_profile_template%TYPE;
    
    BEGIN
    
        g_error   := 'GET PROFILE';
        l_ret_aux := get_profile_template(i_lang, i_prof, l_my_pt, o_error);
    
        --Validate profile template from professional
        IF NOT l_ret_aux
        THEN
            RAISE my_exception;
        END IF;
    
        g_error := 'OPEN CURSOR';
        SELECT DISTINCT dtc.id_doc_type
          BULK COLLECT
          INTO l_ret
          FROM doc_types_config dtc
         INNER JOIN doc_type dt
            ON dt.id_doc_type = dtc.id_doc_type
         WHERE dtc.id_doc_type IS NOT NULL
           AND dt.flg_available = 'Y'
           AND dtc.id_institution IN (i_prof.institution, 0)
           AND dtc.id_software IN (i_prof.software, 0)
           AND dtc.id_profile_template IN (l_my_pt, 0);
    
        RETURN l_ret;
    
    EXCEPTION
        WHEN OTHERS THEN
        
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_DOC_TYPES_TBL',
                                              o_error);
            RETURN l_ret;
    END get_doc_types_tbl;

    /**
        * Check if documents with this doc type is downloadable
        *
        * @param   i_lang            language associated to the professional executing the request
        * @param   i_prof            professional, institution and software ids
        * @param   i_doc_type        document type
        * @param   o_error          an error message, set when return=false
        *
        * @RETURN  TRUE if sucess, FALSE otherwise
        * @author  Carlos Guilherme
        * @version 2.6.1
        * @since   12-04-2011
    */
    FUNCTION is_doc_type_download
    (
        i_lang     IN NUMBER,
        i_prof     IN profissional,
        i_doc_type IN doc_type.id_doc_type%TYPE
    ) RETURN VARCHAR2 IS
        l_ret        BOOLEAN;
        l_error      t_error_out;
        my_exception EXCEPTION;
        l_number     table_number;
        l_my_pt      profile_template.id_profile_template%TYPE;
    BEGIN
        g_error := 'GET PROFILE';
        l_ret   := get_profile_template(i_lang, i_prof, l_my_pt, l_error);
    
        --Validate profile template from professional
        IF NOT l_ret
        THEN
            RAISE my_exception;
        END IF;
    
        g_error := 'OPEN O_LIST';
        SELECT 1
          BULK COLLECT
          INTO l_number
          FROM doc_types_config dtc
         INNER JOIN doc_type dt
            ON dt.id_doc_type = dtc.id_doc_type
         WHERE dtc.id_doc_type = i_doc_type
           AND dt.flg_available = 'Y'
           AND dtc.id_institution IN (i_prof.institution, 0)
           AND dtc.id_software IN (i_prof.software, 0)
           AND dtc.id_profile_template IN (l_my_pt, 0)
           AND dtc.flg_download = 'Y';
    
        IF SQL%FOUND
        THEN
            RETURN 'Y';
        ELSE
            RETURN 'N';
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'IS_DOC_TYPE_DOWNLOAD',
                                              l_error);
            RETURN 'N';
    END is_doc_type_download;

    /**
    * Get a patient's document number.
    *
    * @param i_patient      patient identifier
    * @param i_doc_type     document type identifier
    *
    * @return               document number
    *
    * @author               Pedro Carneiro
    * @version               2.5.2.1
    * @since                2012/02/03
    */
    FUNCTION get_pat_doc_num
    (
        i_patient  IN patient.id_patient%TYPE,
        i_doc_type IN doc_type.id_doc_type%TYPE
    ) RETURN doc_external.num_doc%TYPE IS
        l_ret doc_external.num_doc%TYPE;
    
        CURSOR c_pat_doc_num IS
            SELECT de.num_doc
              FROM doc_external de
             WHERE de.id_doc_type = i_doc_type
               AND de.id_patient = i_patient
               AND de.flg_status = g_doc_active
             ORDER BY nvl(de.dt_updated, de.dt_inserted) DESC;
    BEGIN
        IF i_patient IS NULL
           OR i_doc_type IS NULL
        THEN
            l_ret := NULL;
        ELSE
            OPEN c_pat_doc_num;
            FETCH c_pat_doc_num
                INTO l_ret;
            CLOSE c_pat_doc_num;
        END IF;
    
        RETURN l_ret;
    END get_pat_doc_num;

    /*
    * returns list of all doc_ori_types visible to professional i_prof.
    * For each type there's also a counter that tells how many documents belonging to patient i_id_patient exist.
    *
    * @param i_lang            language associated to the professional executing the request
    * @param i_prof            professional, institution and software ids
    * @param i_id_patient      patient id
    * @param i_id_episode      episode id. If supplied then the doc count is narrowed to id_patient AND id_episode. If not, only by id_patient
    * @param i_id_sys_btn_prop screen where this function is called influences which doc ori types are visible
    * @param o_result          output cursor
    * @param o_error           error info
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    *
    * @author  Telmo
    * @version 2.6.1.6
    * @since   19-12-2011
    */
    FUNCTION get_tl_doc_ori_types
    (
        i_lang            IN NUMBER,
        i_prof            IN profissional,
        i_id_patient      IN doc_external.id_patient%TYPE,
        i_id_episode      IN doc_external.id_episode%TYPE,
        i_id_sys_btn_prop IN doc_types_config.id_sys_button_prop%TYPE,
        o_result          OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name        VARCHAR2(30) := 'GET_TL_DOC_ORI_TYPES';
        l_id_doc_ori_types table_number;
        l_inst             table_number;
        l_id_patient       doc_external.id_patient%TYPE;
        l_id_episode       doc_external.id_episode%TYPE;
        l_my_pt            profile_template.id_profile_template%TYPE;
    BEGIN
    
        g_error            := l_func_name || ' - GET ALLOWED ID_DOC_ORI_TYPES';
        l_id_doc_ori_types := get_categories_tbl(i_lang, i_prof, o_error);
    
        g_error := l_func_name || ' - GET ALL RELATED INSTITUTIONS';
        IF NOT pk_utils.get_institutions_sib(i_lang  => i_lang,
                                             i_prof  => i_prof,
                                             i_inst  => i_prof.institution,
                                             o_list  => l_inst,
                                             o_error => o_error)
        THEN
            RETURN FALSE;
        ELSE
            IF l_inst.count = 0
            THEN
                l_inst.extend;
                l_inst(1) := i_prof.institution;
            END IF;
        END IF;
    
        -- get prof profile 
        g_error := l_func_name || ' - GET PROFILE TEMPLATE';
        IF NOT get_profile_template(i_lang, i_prof, l_my_pt, o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        -- Validate context (Patient, Episode and External Request)
        g_error := l_func_name || ' - GET ID_PATIENT AND ID_EPISODE';
        SELECT decode(pk_doc.get_config('DOC_PATIENT', i_prof, l_my_pt, NULL), g_doc_config_y, i_id_patient, NULL),
               decode(pk_doc.get_config('DOC_EPISODE', i_prof, l_my_pt, NULL), g_doc_config_y, i_id_episode, NULL)
          INTO l_id_patient, l_id_episode
          FROM dual;
    
        g_error := l_func_name || ' - OPEN output cursor';
        OPEN o_result FOR
            SELECT dot.id_doc_ori_type id,
                   pk_translation.get_translation(i_lang, dot.code_doc_ori_type) label,
                   dot.tl_color colour,
                   pk_alert_constant.g_yes flg_show,
                   (SELECT COUNT(1)
                      FROM doc_external de
                      LEFT JOIN xds_document_submission xds
                        ON xds.id_doc_external = nvl(de.id_grupo, de.id_doc_external)
                     WHERE (de.id_patient = l_id_patient OR de.id_episode = l_id_episode)
                       AND de.id_doc_ori_type = dot.id_doc_ori_type
                       AND de.flg_status = g_doc_active
                       AND de.id_institution IN (SELECT column_value
                                                   FROM TABLE(l_inst))
                       AND nvl(xds.flg_status, g_doc_active) = g_doc_active) doc_count
              FROM doc_ori_type dot
             WHERE dot.flg_available = g_doc_ori_type_available_y
               AND dot.id_doc_ori_type IN (SELECT column_value
                                             FROM TABLE(l_id_doc_ori_types))
             ORDER BY dot.rank, label;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            RETURN FALSE;
    END get_tl_doc_ori_types;

    /*
    * returns scale info to build the screen background grid, the lower scale buttons(decade, year, month, etc.).
    * Also returns other info like lowest date patient doc and system date.
    * This is a wrapper for pk_timeline.get_tasks_time_scale.
    *
    * @param i_lang            language associated to the professional executing the request
    * @param i_prof            professional, institution and software ids
    * @param i_id_patient      patient id
    * @param i_id_episode      episode id. can be null. If not null, only documents related to this episode are considered
    * @param i_ids_doc_ori_types list of doc_ori_types that are currently selected 
    * @param o_scale           data to build the background, its scale, grid lines, etc.
    * @param o_patient_info    other useful data
    * @param o_error           error info
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    *
    * @author  Telmo
    * @version 2.6.1.6
    * @since   20-12-2011
    */
    FUNCTION get_tl_scale
    (
        i_lang              IN NUMBER,
        i_prof              IN profissional,
        i_id_patient        IN doc_external.id_patient%TYPE,
        i_id_episode        IN doc_external.id_episode%TYPE,
        i_ids_doc_ori_types IN table_number,
        o_scale             OUT pk_types.cursor_type,
        o_patient_info      OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name    VARCHAR2(30) := 'GET_TIME_SCALE';
        l_episode_list table_number;
        l_patient_info pk_types.cursor_type;
        dt_min_value   VARCHAR2(14);
        dt_max_value   VARCHAR2(14);
        dt_server      VARCHAR2(14);
    BEGIN
        IF i_id_episode IS NOT NULL
        THEN
            l_episode_list := table_number(i_id_episode);
        END IF;
    
        IF NOT pk_timeline.get_tasks_time_scale(i_lang             => i_lang,
                                                i_prof             => i_prof,
                                                i_id_tl_timeline   => c_tl_docs,
                                                i_id_patient       => i_id_patient,
                                                i_visit_list       => NULL,
                                                i_episode_list     => l_episode_list,
                                                i_patient_list     => NULL,
                                                i_tl_task_list     => NULL,
                                                i_ori_type_list    => i_ids_doc_ori_types,
                                                c_get_scale        => o_scale,
                                                c_get_patient_info => l_patient_info,
                                                o_error            => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        FETCH l_patient_info
            INTO dt_min_value, dt_max_value, dt_server;
        CLOSE l_patient_info;
    
        OPEN l_patient_info FOR
            SELECT dt_min_value dt_min_value,
                   to_char(SYSDATE, pk_alert_constant.g_date_hour_send_format) dt_max_value,
                   dt_server dt_server
              FROM dual;
    
        o_patient_info := l_patient_info;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            RETURN FALSE;
    END get_tl_scale;

    /* this carries all data needed to draw the grid lines, columns and its headers. 
    * This is a wrapper for pk_timeline_core.get_timeline_data.
    *
    * @param i_lang            language associated to the professional executing the request
    * @param i_prof            professional, institution and software ids
    * @param i_id_tl_scale     smallest time block. Can be decade, year, etc.
    * @param i_block_req_number how many blocks of tl_scale are needed
    * @param i_request_date    
    * @param i_direction       default B (both)
    * @param o_result          output
    * @param o_error           error info
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    *
    * @author  Telmo
    * @version 2.6.1.6
    * @since   21-12-2011
    */
    FUNCTION get_tl_grid
    (
        i_lang             IN NUMBER,
        i_prof             IN profissional,
        i_id_tl_scale      IN tl_scale.id_tl_scale%TYPE,
        i_block_req_number IN NUMBER,
        i_request_date     IN VARCHAR2,
        i_direction        IN VARCHAR2 DEFAULT 'B',
        o_x_data           OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(30) := 'GET_TIMELINE_GRID';
    BEGIN
    
        g_error := l_func_name || ' - CALL pk_timeline_core.get_timeline_data';
        IF NOT pk_timeline_core.get_timeline_data(i_lang             => i_lang,
                                                  i_prof             => i_prof,
                                                  id_tl_timeline     => c_tl_docs,
                                                  id_tl_scale        => i_id_tl_scale,
                                                  i_block_req_number => i_block_req_number,
                                                  i_request_date     => i_request_date,
                                                  i_direction        => nvl(i_direction, 'B'),
                                                  i_patient          => NULL,
                                                  o_x_data           => o_x_data,
                                                  o_error            => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            RETURN FALSE;
    END get_tl_grid;

    /* grid data
    *
    */
    FUNCTION get_tl_data
    (
        i_lang              IN NUMBER,
        i_prof              IN profissional,
        i_id_patient        IN doc_external.id_patient%TYPE,
        i_id_episode        IN doc_external.id_episode%TYPE,
        i_ids_doc_ori_types IN table_number,
        i_id_tl_scale       IN tl_scale.id_tl_scale%TYPE,
        o_result            OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name                  VARCHAR2(30) := 'GET_TL_DATA';
        tlinit_exception             EXCEPTION;
        l_inst                       table_number;
        l_my_pt                      profile_template.id_profile_template%TYPE;
        l_oid_hie_xds_submission_set sys_config.value%TYPE := pk_sysconfig.get_config('ALERT_OID_HIE_XDS_SUBMISSION_SET',
                                                                                      i_prof);
        l_doc_external_oid           sys_config.value%TYPE := pk_sysconfig.get_config('ALERT_OID_HIE_DOC_EXTERNAL',
                                                                                      i_prof);
        l_format_mask                VARCHAR2(100);
        l_id_patient                 doc_external.id_patient%TYPE;
        l_id_episode                 doc_external.id_episode%TYPE;
    
        FUNCTION inner_truncate_dates(id_tl_scale tl_scale.id_tl_scale%TYPE) RETURN VARCHAR2 IS
        BEGIN
            -- init constants
            pk_alert_constant.get_timescale_id;
            -- decide date mask
            CASE id_tl_scale
                WHEN pk_alert_constant.g_decade THEN
                    RETURN pk_timeline.g_format_mask_year;
                WHEN pk_alert_constant.g_year THEN
                    RETURN pk_timeline.g_format_mask_short_month;
                WHEN pk_alert_constant.g_month THEN
                    RETURN pk_timeline.g_format_mask_short_day;
                WHEN pk_alert_constant.g_week THEN
                    RETURN pk_timeline.g_format_mask_short_day;
                WHEN pk_alert_constant.g_day THEN
                    RETURN pk_timeline.g_format_mask_short_hour;
                WHEN pk_alert_constant.g_shift THEN
                    RETURN pk_timeline.g_format_mask_short_hour;
            END CASE;
        END inner_truncate_dates;
    
    BEGIN
    
        -- Initialize timeline
        IF NOT pk_timeline_core.initialize(i_lang, i_prof, o_error)
        THEN
            g_error := pk_message.get_message(i_lang, 'TL_INITIALIZE');
            RAISE tlinit_exception;
        END IF;
    
        g_error       := l_func_name || ' - GET DATE FORMAT';
        l_format_mask := inner_truncate_dates(i_id_tl_scale);
    
        g_error := l_func_name || ' - Get all related institutions';
        IF NOT pk_utils.get_institutions_sib(i_lang  => i_lang,
                                             i_prof  => i_prof,
                                             i_inst  => i_prof.institution,
                                             o_list  => l_inst,
                                             o_error => o_error)
        THEN
            RETURN FALSE;
        ELSE
            IF l_inst.count = 0
            THEN
                l_inst.extend;
                l_inst(1) := i_prof.institution;
            END IF;
        END IF;
    
        g_error := l_func_name || ' - GET PROFILE TEMPLATE';
        IF NOT get_profile_template(i_lang, i_prof, l_my_pt, o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        -- Validate context (Patient, Episode and External Request)
        SELECT decode(pk_doc.get_config('DOC_PATIENT', i_prof, l_my_pt, NULL), g_doc_config_y, i_id_patient, NULL),
               decode(pk_doc.get_config('DOC_EPISODE', i_prof, l_my_pt, NULL), g_doc_config_y, i_id_episode, NULL)
          INTO l_id_patient, l_id_episode
          FROM dual;
    
        g_error := l_func_name || ' - OPEN CURSOR';
        OPEN o_result FOR
            SELECT dot.id_doc_ori_type,
                   pk_translation.get_translation(i_lang, dot.code_doc_ori_type) oritypedesc,
                   pk_translation.get_translation(i_lang, dt.code_doc_type) typedesc,
                   de.title,
                   to_char(de.id_doc_external) iddoc,
                   pk_doc.get_comments_line_with_count(i_lang, i_prof, de.id_doc_external, dot.flg_comment_type) numcomments,
                   get_count_image(i_lang, i_prof, de.id_doc_external) numimages,
                   pk_date_utils.date_send_tsz(i_lang, de.dt_inserted, i_prof.institution, i_prof.software) date_begin,
                   pk_date_utils.trunc_insttimezone_str(i_prof, de.dt_inserted, l_format_mask) trunc_date_begin, -- esta e' a data a usar para posicionar o doc na grelha
                   to_char(de.dt_inserted, l_format_mask) || to_char(de.id_doc_ori_type) date_parent,
                   pk_date_utils.dt_chr(i_lang, de.dt_emited, i_prof) dt_emited,
                   pk_date_utils.dt_chr(i_lang, de.dt_expire, i_prof) dt_expire,
                   NULL date_end,
                   NULL trunc_date_end,
                   pk_date_utils.date_send_tsz(i_lang,
                                               nvl(de.dt_updated, de.dt_inserted),
                                               i_prof.institution,
                                               i_prof.software) lastupdateddate,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, nvl(de.id_professional_upd, de.id_professional)) lastupdatedby,
                   pk_prof_utils.get_spec_signature(i_lang,
                                                    i_prof,
                                                    nvl(de.id_professional_upd, de.id_professional),
                                                    nvl(de.dt_updated, de.dt_inserted),
                                                    de.id_episode) todo_especialidade,
                   get_main_thumb_url(i_lang, i_prof, de.id_doc_external) url_thumb,
                   get_main_thumb_mime_type(i_lang, i_prof, de.id_doc_external) mime_type,
                   get_main_thumb_extension(i_lang, i_prof, de.id_doc_external) format_type,
                   de.flg_status,
                   dot.flg_comment_type,
                   nvl(de.id_grupo, de.id_doc_external) id_folder,
                   xds.id_xds_document_submission,
                   decode(xds.id_xds_document_submission,
                          NULL,
                          NULL,
                          l_oid_hie_xds_submission_set || '.' || xds.id_xds_document_submission) submission_set_unique_id,
                   l_doc_external_oid || '.' || nvl(de.id_grupo, de.id_doc_external) doc_oid,
                   xds.flg_submission_type submission_status,
                   pk_date_utils.dt_chr(i_lang, xds.dt_submission_time, i_prof) subm_dt_char,
                   pk_date_utils.dt_chr_hour(i_lang, xds.dt_submission_time, i_prof) subm_dt_char_hour,
                   (SELECT id_epis_report
                      FROM epis_report er
                     WHERE er.id_doc_external = de.id_doc_external) id_epis_report,
                   de.num_doc,
                   pk_translation.get_translation(i_lang, de.id_specialty) specialty,
                   pk_translation.get_translation(i_lang, de.id_doc_original) original,
                   pk_translation.get_translation(i_lang, de.id_language) desc_language,
                   de.notes,
                   (SELECT COUNT(1)
                      FROM doc_comments dc
                     WHERE dc.id_doc_external = de.id_doc_external
                       AND dc.flg_cancel = 'N') note_count,
                   is_doc_type_publishable(i_lang, i_prof, de.id_doc_type) flg_publishable,
                   is_doc_type_download(i_lang, i_prof, de.id_doc_type) flg_download,
                   dt.id_doc_type
              FROM doc_type dt
              JOIN doc_external de
                ON dt.id_doc_type = de.id_doc_type
              JOIN doc_ori_type dot
                ON de.id_doc_ori_type = dot.id_doc_ori_type
              LEFT JOIN xds_document_submission xds
                ON xds.id_doc_external = nvl(de.id_grupo, de.id_doc_external) -- o join com a doc_ext tem de ser via ID_GRUPO
             WHERE (de.id_patient = l_id_patient OR de.id_episode = l_id_episode)
               AND de.id_institution IN (SELECT column_value
                                           FROM TABLE(l_inst))
               AND (i_ids_doc_ori_types IS NULL OR
                   de.id_doc_ori_type IN (SELECT column_value
                                             FROM TABLE(i_ids_doc_ori_types)))
               AND de.flg_status = pk_doc.g_doc_active
               AND nvl(xds.flg_status, g_doc_active) = g_doc_active
            -- aqui nao precisa de validar o acesso deste prof aos doc_ori_types porque ja foi feito no get_tl_doc_ori_types
            -- os ids que saem dessa funcao entram nesta
             ORDER BY date_parent, de.dt_inserted DESC, oritypedesc;
    
        RETURN TRUE;
    EXCEPTION
        WHEN tlinit_exception THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_TL_DATA',
                                              'U',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_result);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_result);
            RETURN FALSE;
    END get_tl_data;

    /**
    * Get patient's body diagrams as documents
    *
    * @param   i_lang           language associated to the professional executing the request
    * @param   i_prof           professional, institution and software ids
    * @param   i_patient        patient id
    * @parama  i_first_run
    * @param   o_body_diagrams  output body diagrams list
    * @param   o_error          an error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Daniel Silva
    * @version 2.6.2
    * @since   2012-04-05
    */
    FUNCTION get_body_diagrams_as_document
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_patient       IN patient.id_patient%TYPE,
        o_body_diagrams OUT t_tbl_rec_document,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        o_body_diagrams := get_body_diagrams_as_document(i_lang => i_lang, i_prof => i_prof, i_patient => i_patient);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
        
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_BODY_DIAGRAMS_AS_DOCUMENT',
                                              o_error);
        
            o_body_diagrams := t_tbl_rec_document();
            RETURN FALSE;
        
    END get_body_diagrams_as_document;

    /**
    * Get patient's body diagrams as documents
    *
    * @param   i_lang           language associated to the professional executing the request
    * @param   i_prof           professional, institution and software ids
    * @param   i_patient        patient id
    * @parama  i_first_run
    * @param   o_body_diagrams  output body diagrams list
    * @param   o_error          an error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Daniel Silva
    * @version 2.6.2
    * @since   2012-04-05
    */
    FUNCTION get_body_diagrams_as_document
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE
    ) RETURN t_tbl_rec_document IS
    
        o_error t_error_out;
    
        o_body_diagrams t_tbl_rec_document := t_tbl_rec_document();
    
        l_body_diagrams pk_types.cursor_type;
    
        l_id_epis_diagram table_number := table_number();
        l_diagram_order   table_number := table_number();
        l_diagram_desc    table_varchar := table_varchar();
        l_id_episode      table_number := table_number();
        l_last_upd_prof   table_number := table_number();
        l_specialty       table_number := table_number();
        l_last_upd_date   table_varchar := table_varchar();
        l_num_images      table_number := table_number();
    
        l_flg_status      epis_diagram.flg_status%TYPE;
        l_last_update_tag VARCHAR2(200);
        l_date_time       VARCHAR2(200);
    
        l_body_diagram_mime_type sys_config.value%TYPE;
    
        l_id_doc_type     NUMBER;
        l_doc_type_desc   VARCHAR2(4000);
        l_id_doc_ori_type NUMBER;
        l_ori_type_desc   VARCHAR2(4000);
    
    BEGIN
    
        l_body_diagram_mime_type := pk_sysconfig.get_config('BODY_DIAGRAMS_MIME_TYPE', i_prof => i_prof);
    
        IF pk_diagram_new.get_all_pat_diag_doc(i_lang    => i_lang,
                                               i_prof    => i_prof,
                                               i_patient => i_patient,
                                               o_info    => l_body_diagrams,
                                               o_error   => o_error)
        
        THEN
        
            SELECT d.id_doc_type,
                   pk_translation.get_translation(i_lang, d.code_doc_type),
                   d.id_doc_ori_type,
                   pk_translation.get_translation(i_lang, dot.code_doc_ori_type)
              INTO l_id_doc_type, l_doc_type_desc, l_id_doc_ori_type, l_ori_type_desc
              FROM doc_type d
              JOIN doc_ori_type dot
                ON d.id_doc_ori_type = dot.id_doc_ori_type
             WHERE d.id_doc_type = 2622; -- body diagrams doc_type
        
            --open l_body_diagrams;
            --into l_diagram_number, l_last_update_tag, l_date_time, l_id_epis_diagram, l_id_episode, l_num_images, l_last_upd_date, last_upd_prof, l_flg_status, l_specialty;
            FETCH l_body_diagrams BULK COLLECT
                INTO l_id_epis_diagram,
                     l_diagram_order,
                     l_diagram_desc,
                     l_id_episode,
                     l_last_upd_prof,
                     l_specialty,
                     l_last_upd_date,
                     l_num_images;
        
            SELECT t_rec_document(id_doc_ori_type => l_id_doc_ori_type,
                                  oritypedesc => l_ori_type_desc,
                                  typedesc => l_doc_type_desc,
                                  title => dd.val,
                                  iddoc => ied.val,
                                  numcomments => 0,
                                  numimages => nim.val,
                                  dt_emited => lud.val,
                                  dt_expire => NULL,
                                  lastupdateddate => lud.val,
                                  lastupdatedby => pk_prof_utils.get_name_signature(i_lang, i_prof, nvl(lup.val, lup.val)),
                                  pk_utils.get_institution_name(i_lang, i_prof.institution), -- lastupdateby_facility
                                  todo_especialidade => to_char(spe.val),
                                  url_thumb => ' ', --NULL (request new icon for body diagrams) 'http://pfhdev262.mni.local/DbImages?diagramLayoutImage=37',
                                  mime_type => l_body_diagram_mime_type,
                                  format_type => l_body_diagram_mime_type,
                                  flg_status => 'A', -- l_flg_status 
                                  flg_comment_type => NULL,
                                  id_doc_external => ied.val,
                                  id_folder => NULL,
                                  id_xds_document_submission => NULL,
                                  submission_set_unique_id => NULL,
                                  doc_oid => ied.val, --not to be shared
                                  submission_status => NULL,
                                  subm_dt_char => NULL,
                                  subm_dt_char_hour => NULL,
                                  id_epis_report => NULL,
                                  num_doc => NULL,
                                  specialty => NULL,
                                  original => NULL,
                                  desc_language => NULL,
                                  notes => NULL,
                                  note_count => NULL,
                                  flg_publishable => 'N',
                                  flg_download => 'N',
                                  id_doc_type => l_id_doc_type,
                                  created_date => lud.val,
                                  created_by => pk_prof_utils.get_name_signature(i_lang, i_prof, lup.val),
                                  created_by_inst => pk_utils.get_institution_name(i_lang, i_prof.institution),
                                  id_patient => i_patient,
                                  id_external_request => NULL,
                                  id_institution => i_prof.institution,
                                  id_episode => iep.val,
                                  lastupdateddatetstz => pk_date_utils.get_timestamp_insttimezone(i_lang,
                                                                                                  i_prof,
                                                                                                  lud.val,
                                                                                                  pk_alert_constant.g_dt_yyyymmddhh24miss),
                                  flg_saved_outside => 'N')
              BULK COLLECT
              INTO o_body_diagrams
              FROM (SELECT rownum rn, column_value val
                      FROM TABLE(l_id_epis_diagram)) ied
              JOIN (SELECT rownum rn, column_value val
                      FROM TABLE(l_diagram_order)) do
                ON do.rn = ied.rn
              JOIN (SELECT rownum rn, column_value val
                      FROM TABLE(l_diagram_desc)) dd
                ON dd.rn = ied.rn
              JOIN (SELECT rownum rn, column_value val
                      FROM TABLE(l_id_episode)) iep
                ON iep.rn = ied.rn
              JOIN (SELECT rownum rn, column_value val
                      FROM TABLE(l_last_upd_prof)) lup
                ON lup.rn = ied.rn
              JOIN (SELECT rownum rn, column_value val
                      FROM TABLE(l_specialty)) spe
                ON spe.rn = ied.rn
              JOIN (SELECT rownum rn, column_value val
                      FROM TABLE(l_last_upd_date)) lud
                ON lud.rn = ied.rn
              JOIN (SELECT rownum rn, column_value val
                      FROM TABLE(l_num_images)) nim
                ON nim.rn = ied.rn;
            CLOSE l_body_diagrams;
        
        END IF;
    
        RETURN o_body_diagrams;
    
    END;

    -- mantained for backward compatibility with UX
    FUNCTION get_document_count_by_category
    (
        i_lang    IN NUMBER,
        i_prof    IN profissional,
        i_pat     IN patient.id_patient%TYPE,
        i_episode IN episode.id_episode%TYPE,
        i_ext_req IN p1_external_request.id_external_request%TYPE,
        i_btn     IN sys_button_prop.id_sys_button_prop%TYPE,
        o_list    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_doc_cur         pk_types.cursor_type;
        l_rank            NUMBER;
        l_id_doc_ori_type NUMBER;
        desc_ori_type     VARCHAR2(200);
        num_docs          NUMBER;
        doc_oids          table_varchar;
        l_body_diagrams   pk_types.cursor_type;
    
        l_body_diagrams_count NUMBER := 0;
    
        l_diagram_number  VARCHAR2(200);
        l_last_update_tag VARCHAR2(200);
        l_date_time       VARCHAR2(200);
        l_id_epis_diagram NUMBER;
        l_id_episode      NUMBER;
        l_num_images      NUMBER;
        l_last_upd_date   epis_diagram.adw_last_update%TYPE;
        last_upd_prof     VARCHAR2(4000);
        l_flg_status      epis_diagram.flg_status%TYPE;
        l_specialty       VARCHAR2(4000);
    
        l_doc_count_by_cat_tbl t_tbl_rec_doc_count_by_cat := t_tbl_rec_doc_count_by_cat();
    
        id_docs        table_number_id;
        id_dates       table_timestamp_tstz;
        titles         table_varchar;
        doc_flg_status table_varchar := table_varchar(g_doc_active, g_doc_inactive);
    
        my_exception EXCEPTION;
    BEGIN
    
        IF NOT pk_doc.get_documents_list_count(i_lang,
                                               i_prof,
                                               i_pat,
                                               i_episode,
                                               i_ext_req,
                                               i_btn,
                                               doc_flg_status,
                                               o_list,
                                               o_error)
        THEN
            RAISE my_exception;
        
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_list);
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_DOCUMENT_COUNT_BY_CATEGORY',
                                              o_error);
            RETURN FALSE;
    END get_document_count_by_category;

    /**
    * Get attached documents for a specific external request (URLs to P1_ATTACHED_DOCUMENT servlet).
    *
    * @param i_external_request      external request
    *
    * @return               doc_image urls
    *
    * @author               Daniel Silva
    * @version              2.6.1
    * @since                2013/05/28
    * reason                ALERT-258767
    */
    FUNCTION get_ext_req_doc_urls
    (
        i_lang             IN NUMBER,
        i_external_request IN doc_external.id_external_request%TYPE,
        o_ext_req_doc_urls OUT pk_types.cursor_type,
        o_error            OUT t_error_out
        
    ) RETURN BOOLEAN IS
    
        l_external_request_data pk_types.cursor_type;
        l_seq_number            p1_match.sequential_number%TYPE;
        l_institution           p1_match.id_institution%TYPE;
        l_urlbase               VARCHAR2(2000);
        l_error                 t_error_out;
        my_exception            EXCEPTION;
    
    BEGIN
    
        pk_alertlog.log_debug('About to get sys_config: URL_P1_ATTACHED_DOCUMENT');
        l_urlbase := pk_sysconfig.get_config('URL_P1_ATTACHED_DOCUMENT', NULL);
        pk_alertlog.log_debug('URL_P1_ATTACHED_DOCUMENT Sys_config: ' || l_urlbase);
    
        IF NOT pk_p1_core.get_req_data(i_external_request, l_external_request_data, l_error)
        THEN
            g_error := 'Error getting external request data (sequencial number) for id_external_request=' ||
                       i_external_request;
            RAISE my_exception;
        ELSE
            IF l_external_request_data IS NULL
            THEN
                pk_alertlog.log_warn('External request data (sequencial number) NOT found for id_external_request=' ||
                                     i_external_request);
                l_seq_number := 'null';
            ELSE
                FETCH l_external_request_data
                    INTO l_seq_number, l_institution;
                CLOSE l_external_request_data;
            END IF;
        
            OPEN o_ext_req_doc_urls FOR
                SELECT de.title || ' (' || di.file_name || ')' title,
                       REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(l_urlbase, '@1', l_seq_number),
                                                       '@2',
                                                       de.id_external_request),
                                               '@3',
                                               di.id_doc_image),
                                       '@4',
                                       de.id_doc_external),
                               '@5',
                               get_hash(l_seq_number || '||' || de.id_external_request || '||' || de.id_doc_external || '||' ||
                                        di.id_doc_image)) url,
                       pk_date_utils.dt_chr_date_hour(i_lang, nvl(de.dt_updated, de.dt_inserted), NULL) last_update,
                       pk_prof_utils.get_name_signature(i_lang, NULL, nvl(de.id_professional_upd, de.id_professional)) last_updated_by,
                       pk_prof_utils.get_prof_speciality(i_lang,
                                                         profissional(de.id_professional, de.id_institution, NULL)) specialty,
                       nvl(de.dt_updated, de.dt_inserted) last_update_tstz
                  FROM doc_image di
                  JOIN doc_external de
                    ON di.id_doc_external = de.id_doc_external
                 WHERE de.id_external_request = i_external_request
                 ORDER BY last_update_tstz DESC;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_EXT_REQ_DOC_URLS',
                                              l_error);
            RETURN FALSE;
    END get_ext_req_doc_urls;

    /**
    * Get hash value for a given string. (Used as a token to validate P1 servlet requests for attached documents.)
    *
    * @param i_src      input string
    *
    * @return               hash value
    *
    * @author               Daniel Silva
    * @version              2.6.1
    * @since                2013/05/28
    * reason                ALERT-258767
    */
    FUNCTION get_hash(i_src IN VARCHAR2) RETURN VARCHAR2 IS
        l_hash_value  VARCHAR2(4000);
        l_current_day VARCHAR2(8);
    BEGIN
        SELECT to_char(SYSDATE, 'yyyymmdd')
          INTO l_current_day
          FROM dual;
    
        --select ora_hash(i_src) into l_hash_value from dual;
        SELECT sys.dbms_crypto.hash(utl_raw.cast_to_raw(i_src || '||' || l_current_day), 3)
          INTO l_hash_value
          FROM dual;
        RETURN l_hash_value;
    END get_hash;

    /**
    * Return a subset of images from a document list (lazy loading)
    *
    * @param i_lang              language id
    * @param i_prof              professional, software and institution ids
    * @param i_id_doc_list       list of document ids
    * @param i_start_point       subset starting point
    * @param i_quantity          number of results to return
    * @param o_doc_img_detail    image details
    * @param o_error             an error message
    *
    * @return true (sucess), false (error)
    * @created 2013.09.05
    * @author daniel.silva
    */
    FUNCTION get_doc_images_subset
    (
        i_lang              IN NUMBER,
        i_prof              IN profissional,
        i_id_doc_list       IN table_number,
        i_start_point       IN NUMBER,
        i_quantity          IN NUMBER,
        o_doc_images_subset OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        RETURN pk_doc.get_doc_images_internal(i_lang,
                                              i_prof,
                                              i_id_doc_list,
                                              i_start_point,
                                              i_quantity,
                                              o_doc_images_subset,
                                              o_error);
    
    END get_doc_images_subset;

    PROCEDURE get_archive_list_filter
    (
        i_filter_name   IN VARCHAR2,
        i_custom_filter IN NUMBER,
        i_context_ids   IN table_number,
        i_context_keys  IN table_varchar DEFAULT NULL,
        i_context_vals  IN table_varchar,
        i_name          IN VARCHAR2,
        o_vc2           OUT VARCHAR2,
        o_num           OUT NUMBER,
        o_id            OUT NUMBER,
        o_tstz          OUT TIMESTAMP WITH LOCAL TIME ZONE
    ) IS
        g_lang             CONSTANT NUMBER(24) := 1;
        g_prof_id          CONSTANT NUMBER(24) := 2;
        g_prof_institution CONSTANT NUMBER(24) := 3;
        g_prof_software    CONSTANT NUMBER(24) := 4;
        g_episode          CONSTANT NUMBER(24) := 5;
        g_patient          CONSTANT NUMBER(24) := 6;
        l_prof             CONSTANT profissional := profissional(i_context_ids(g_prof_id),
                                                                 i_context_ids(g_prof_institution),
                                                                 i_context_ids(g_prof_software));
        l_lang             CONSTANT language.id_language%TYPE := i_context_ids(g_lang);
        l_patient          CONSTANT patient.id_patient%TYPE := i_context_ids(g_patient);
        l_episode          CONSTANT episode.id_episode%TYPE := i_context_ids(g_episode);
    
        l_my_pt         profile_template.id_profile_template%TYPE;
        e_profile_templ EXCEPTION;
        l_error         t_error_out;
    
        l_lov_filter NUMBER;
        l_ftr_status VARCHAR2(1 CHAR);
    
    BEGIN
        IF i_context_vals.count > 4
        THEN
            l_lov_filter := i_context_vals(5);
            CASE l_lov_filter
                WHEN 5 THEN
                    l_ftr_status := 'A';
                WHEN 6 THEN
                    l_ftr_status := 'I';
                ELSE
                    l_ftr_status := NULL;
            END CASE;
        END IF;
    
        pk_context_api.set_parameter('i_lang', l_lang);
        pk_context_api.set_parameter('i_prof_id', i_context_ids(g_prof_id));
        pk_context_api.set_parameter('i_prof_institution', i_context_ids(g_prof_institution));
        pk_context_api.set_parameter('i_prof_software', i_context_ids(g_prof_software));
        pk_context_api.set_parameter('i_patient', l_patient);
        pk_context_api.set_parameter('i_episode', l_episode);
    
        CASE i_custom_filter
            WHEN 19 THEN
                pk_context_api.set_parameter('i_doc_ori_type', 9);
            WHEN 20 THEN
                pk_context_api.set_parameter('i_doc_ori_type', 47);
            WHEN 21 THEN
                pk_context_api.set_parameter('i_doc_ori_type', 60);
            WHEN 22 THEN
                pk_context_api.set_parameter('i_doc_ori_type', 30);
            WHEN 23 THEN
                pk_context_api.set_parameter('i_doc_ori_type', 3);
            ELSE
                pk_context_api.set_parameter('i_doc_ori_type', NULL);
        END CASE;
    
        CASE i_name
        
            WHEN 'i_lang' THEN
                o_id := l_lang;
            WHEN 'i_prof_id' THEN
                o_id := l_prof.id;
            WHEN 'i_prof_institution' THEN
                o_id := l_prof.institution;
            WHEN 'i_prof_software' THEN
                o_id := l_prof.software;
            WHEN 'i_episode' THEN
                o_id := l_episode;
            WHEN 'i_patient' THEN
                o_id := l_patient;
            WHEN 'g_doc_active' THEN
                o_vc2 := g_doc_active;
            WHEN 'g_doc_inactive' THEN
                o_vc2 := g_doc_inactive;
            WHEN 'i_doc_ori_type' THEN
                o_id := to_number(i_context_vals(3));
            WHEN 'l_doc_external_oid' THEN
                o_id := pk_sysconfig.get_config('ALERT_OID_HIE_DOC_EXTERNAL', l_prof);
            WHEN 'l_episode' THEN
                g_error := 'CALL GET_PROFILE_TEMPLATE';
                IF NOT get_profile_template(l_lang, l_prof, l_my_pt, l_error)
                THEN
                    RAISE e_profile_templ;
                END IF;
                o_id := CASE pk_doc.get_config('DOC_EPISODE', l_prof, l_my_pt, i_context_vals(2))
                            WHEN g_doc_config_y THEN
                             l_episode
                            ELSE
                             NULL
                        END;
            WHEN 'l_ext_req' THEN
                IF NOT get_profile_template(l_lang, l_prof, l_my_pt, l_error)
                THEN
                    RAISE e_profile_templ;
                END IF;
                o_vc2 := CASE pk_doc.get_config('DOC_REFERRAL', l_prof, l_my_pt, i_context_vals(2))
                             WHEN g_doc_config_y THEN
                              i_context_vals(3)
                             ELSE
                              NULL
                         END;
            WHEN 'l_oid_hie_xds_submission_set' THEN
                o_id := pk_sysconfig.get_config('ALERT_OID_HIE_XDS_SUBMISSION_SET', l_prof);
            WHEN 'l_patient' THEN
                IF NOT get_profile_template(l_lang, l_prof, l_my_pt, l_error)
                THEN
                    RAISE e_profile_templ;
                END IF;
                o_id := CASE pk_doc.get_config('DOC_PATIENT', l_prof, l_my_pt, i_context_vals(2))
                            WHEN g_doc_config_y THEN
                             l_patient
                            ELSE
                             NULL
                        END;
            WHEN 'l_search_text' THEN
                o_vc2 := i_context_vals(4);
            WHEN 'l_filter_status' THEN
                o_vc2 := l_ftr_status;
            
        END CASE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(l_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_ARCHIVE_LIST_FILTER',
                                              l_error);
    END get_archive_list_filter;

    FUNCTION get_institutions_sib
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional,
        i_inst IN institution.id_institution%TYPE
    ) RETURN table_number IS
    
        l_inst_list table_number;
        l_error     t_error_out;
    
    BEGIN
    
        l_inst_list := table_number();
        l_inst_list.extend;
        l_inst_list(1) := i_inst;
    
        RETURN l_inst_list;
    
    END get_institutions_sib;

    /**
    * Returns the document archive cover cell for the viewer. 
    *
    * @param i_lang              language id
    * @param i_prof              professional, software and institution ids
    * @param i_episode           id episode
    * @param o_viewer_info       data for viewer
    * @param o_error             an error message
    *
    * @return true (sucess), false (error)
    * @created 2013.09.19
    * @author daniel.silva
    */
    FUNCTION get_viewer_doc_archive_cover
    (
        i_lang        IN NUMBER,
        i_prof        IN profissional,
        i_patient     IN patient.id_patient%TYPE,
        i_episode     IN episode.id_episode%TYPE,
        o_viewer_info OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        counter            NUMBER := 0;
        title              VARCHAR2(400);
        last_doc_title     VARCHAR2(400);
        last_doc_date      VARCHAR2(50);
        last_doc_date_desc VARCHAR2(200);
        doc_tbl            t_tbl_rec_document;
    
        l_inst       table_number;
        my_exception EXCEPTION;
    
    BEGIN
    
        SELECT pk_message.get_message(i_lang, i_prof, 'SYS_BUTTON.CODE_BUTTON.126') title,
               COUNT(1) + pk_doc.get_body_diagrams_count(i_lang, i_prof, i_patient) counter
          INTO title, counter
          FROM doc_external de
         WHERE ((de.id_patient = i_patient) OR (de.id_episode = i_episode) OR (de.id_external_request = NULL))
           AND de.id_institution IN (SELECT column_value
                                       FROM TABLE(l_inst))
           AND de.flg_status IN (g_doc_active, g_doc_inactive);
    
        IF NOT pk_utils.get_institutions_sib(i_lang  => i_lang,
                                             i_prof  => i_prof,
                                             i_inst  => i_prof.institution,
                                             o_list  => l_inst,
                                             o_error => o_error)
        THEN
            RAISE my_exception;
        ELSE
            IF l_inst.count = 0
            THEN
                l_inst.extend;
                l_inst(1) := i_prof.institution;
            END IF;
        END IF;
    
        doc_tbl := pk_doc.get_doc_list_by_type(i_lang         => i_lang,
                                               i_prof         => i_prof,
                                               i_patient      => i_patient,
                                               i_episode      => i_episode,
                                               i_ext_req      => NULL,
                                               i_btn          => NULL,
                                               i_doc_ori_type => NULL);
    
        IF doc_tbl.count > 0
        THEN
            last_doc_title     := doc_tbl(1).title;
            last_doc_date      := doc_tbl(1).lastupdateddate;
            last_doc_date_desc := nvl(pk_date_utils.dt_chr_date_hour_tsz(i_lang => i_lang,
                                                                         i_date => last_doc_date,
                                                                         i_inst => i_prof.institution,
                                                                         i_soft => i_prof.software),
                                      ' ');
        END IF;
    
        OPEN o_viewer_info FOR
            SELECT title              AS title,
                   counter            AS counter,
                   last_doc_title     AS last_doc_title,
                   last_doc_date      AS last_doc_date,
                   last_doc_date_desc AS datedescription
              FROM dual;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_VIEWER_DOC_ARCHIVE_COVER',
                                              o_error);
            RETURN FALSE;
    END get_viewer_doc_archive_cover;

    /**
    * Returns TRUE if documents archive must show body diagrams. 
    *
    * @param i_lang              language id
    * @param i_prof              professional, software and institution ids
    *
    * @return true (sucess), false (error)
    * @created 2013.09.19
    * @author daniel.silva
    */
    FUNCTION is_arch_including_body_diag
    (
        i_lang IN NUMBER,
        i_prof IN profissional
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        IF pk_sysconfig.get_config('DOC_ARCH_INCLUDES_BODY_DIAGRAMS', i_prof) = g_yes
        THEN
            RETURN TRUE;
        END IF;
    
        RETURN FALSE;
    
    END is_arch_including_body_diag;

    /**
    * Returns the number of body diagrams for the patient (Returns 0 (zero) if doc archive is not configured to include body diagrams.
    *
    * @param i_lang              language id
    * @param i_prof              professional, software and institution ids
    * @param i_patient           patient id
    *
    * @return true (sucess), false (error)
    * @created 2013.09.19
    * @author daniel.silva
    */
    FUNCTION get_body_diagrams_count
    (
        i_lang    IN NUMBER,
        i_prof    IN profissional,
        i_patient IN NUMBER
    ) RETURN NUMBER IS
    
        l_body_diagrams_counter NUMBER := 0;
    
    BEGIN
    
        IF pk_sysconfig.get_config('DOC_ARCH_INCLUDES_BODY_DIAGRAMS', i_prof) = g_yes
        THEN
            l_body_diagrams_counter := pk_diagram_new.get_pat_num_diagrams(i_patient => i_patient);
        END IF;
    
        RETURN l_body_diagrams_counter;
    
    END get_body_diagrams_count;

    /**
    * Returns the menu structure to present the document archive in the viewer.
    *
    * @param i_lang              language id
    * @param i_prof              professional, software and institution ids
    * @param i_patient           patient id
    *
    * @return true (sucess), false (error)
    * @created 2013.09.19
    * @author daniel.silva
    */
    FUNCTION get_viewer_doc_archive
    (
        i_lang            IN NUMBER,
        i_prof            IN profissional,
        i_patient         IN patient.id_patient%TYPE,
        i_episode         IN episode.id_episode%TYPE,
        i_id_doc_ori_type IN doc_ori_type.id_doc_ori_type%TYPE,
        io_current_level  IN OUT NUMBER,
        o_viewer_info     OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    )
    
     RETURN BOOLEAN IS
    
        c pk_types.cursor_type;
    
        ord_type        NUMBER;
        id_doc_ori_type NUMBER;
        desc_ori_type   VARCHAR2(400);
        num_docs        NUMBER;
        doc_oids        table_varchar;
        id_docs         table_number_id;
        id_dates        table_timestamp_tstz;
        titles          table_varchar;
    
        last_doc_id    NUMBER;
        last_doc_title VARCHAR2(400);
        last_doc_date  TIMESTAMP;
    
        o_date             table_timestamp := table_timestamp();
        o_counter          table_number := table_number();
        o_description      table_varchar := table_varchar();
        o_title            table_varchar := table_varchar();
        o_date_description table_varchar := table_varchar();
        o_id_doc_ori_type  table_number := table_number();
        i                  NUMBER := 1;
        document_tbl       t_tbl_rec_document;
    
        doc_flg_status table_varchar := table_varchar(g_doc_active);
    BEGIN
    
        IF io_current_level = 1
           OR io_current_level = 2
        THEN
            -- Get cover or categories
            IF pk_doc.get_documents_list_count(i_lang       => i_lang,
                                               i_prof       => i_prof,
                                               i_pat        => i_patient,
                                               i_episode    => i_episode,
                                               i_ext_req    => NULL,
                                               i_btn        => NULL,
                                               i_flg_status => doc_flg_status,
                                               o_list       => c,
                                               o_error      => o_error)
            THEN
            
                LOOP
                    FETCH c
                        INTO ord_type, id_doc_ori_type, desc_ori_type, num_docs, doc_oids, id_docs, id_dates, titles;
                    EXIT WHEN c%NOTFOUND;
                
                    IF id_docs.count > 0
                       AND (id_docs.count = id_dates.count AND id_dates.count = titles.count)
                    THEN
                        BEGIN
                            SELECT tdc.val, tdt.val, ttt.val
                              INTO last_doc_id, last_doc_date, last_doc_title
                              FROM (SELECT rownum rn, column_value val
                                      FROM TABLE(id_docs)) tdc
                              JOIN (SELECT rownum rn, column_value val
                                      FROM TABLE(id_dates)) tdt
                                ON tdt.rn = tdc.rn
                              JOIN (SELECT rownum rn, column_value val
                                      FROM TABLE(titles)) ttt
                                ON ttt.rn = tdc.rn
                             WHERE tdt.val = (SELECT MAX(column_value)
                                                FROM TABLE(id_dates))
                               AND rownum = 1;
                        EXCEPTION
                            WHEN OTHERS THEN
                                last_doc_id    := NULL;
                                last_doc_date  := NULL;
                                last_doc_title := NULL;
                        END;
                    
                    ELSE
                        last_doc_id    := NULL;
                        last_doc_date  := NULL;
                        last_doc_title := NULL;
                    END IF;
                
                    o_id_doc_ori_type.extend;
                    o_id_doc_ori_type(i) := id_doc_ori_type;
                    o_date.extend;
                    o_date(i) := last_doc_date;
                    o_counter.extend;
                    o_counter(i) := num_docs;
                    o_description.extend;
                    o_description(i) := last_doc_title;
                    o_title.extend;
                    o_title(i) := desc_ori_type;
                    o_date_description.extend;
                    o_date_description(i) := nvl(pk_date_utils.dt_chr_date_hour_tsz(i_lang => i_lang,
                                                                                    i_date => last_doc_date,
                                                                                    i_inst => i_prof.institution,
                                                                                    i_soft => i_prof.software),
                                                 ' ');
                
                    i := i + 1;
                END LOOP;
            
                OPEN o_viewer_info FOR
                    SELECT tbl_ori_type.val AS id_doc_ori_type,
                           (CASE
                                WHEN io_current_level = 1 THEN
                                 pk_message.get_message(i_lang, 'SYS_BUTTON.CODE_BUTTON.126')
                                ELSE
                                 tbl_title.val
                            END) AS title,
                           tbl_date.val AS doc_date,
                           tbl_date_desc.val AS doc_date_desc,
                           tbl_desc.val AS description,
                           tbl_counter.val AS counter,
                           (CASE
                                WHEN tbl_counter.val > 0 THEN
                                 'Y'
                                ELSE
                                 'N'
                            END) AS flg_clickable
                      FROM (SELECT rownum rn, column_value val
                              FROM TABLE(o_title)) tbl_title
                      JOIN (SELECT rownum rn, column_value val
                              FROM TABLE(o_date)) tbl_date
                        ON tbl_title.rn = tbl_date.rn
                      JOIN (SELECT rownum rn, column_value val
                              FROM TABLE(o_date_description)) tbl_date_desc
                        ON tbl_title.rn = tbl_date_desc.rn
                      JOIN (SELECT rownum rn, column_value val
                              FROM TABLE(o_description)) tbl_desc
                        ON tbl_title.rn = tbl_desc.rn
                      JOIN (SELECT rownum rn, column_value val
                              FROM TABLE(o_counter)) tbl_counter
                        ON tbl_title.rn = tbl_counter.rn
                       AND ((io_current_level = 1 AND tbl_counter.val > 0) OR
                           (io_current_level = 2 AND tbl_counter.val > -1))
                      JOIN (SELECT rownum rn, column_value val
                              FROM TABLE(o_id_doc_ori_type)) tbl_ori_type
                        ON tbl_title.rn = tbl_ori_type.rn
                     WHERE 1 = (CASE
                               WHEN io_current_level = 1
                                    AND tbl_ori_type.val IS NULL THEN
                                1 --  level 1 :: Document archive cover we only want the total from "All Documents"                                                                             
                               WHEN io_current_level > 1
                                    AND tbl_ori_type.val IS NOT NULL THEN
                                1 -- level NOT 1 :: Categories menu
                               ELSE
                                0
                           END);
            END IF;
        
        ELSE
            -- Show the documents for the category
        
            document_tbl := pk_doc.get_doc_list_by_type(i_lang         => i_lang,
                                                        i_prof         => i_prof,
                                                        i_patient      => i_patient,
                                                        i_episode      => i_episode,
                                                        i_ext_req      => NULL,
                                                        i_btn          => NULL,
                                                        i_doc_ori_type => i_id_doc_ori_type);
            OPEN o_viewer_info FOR
                SELECT doc.id_doc_ori_type AS id_doc_ori_type,
                       doc.title AS title,
                       doc.lastupdateddate AS doc_date,
                       pk_date_utils.dt_chr_date_hour_str(i_lang     => i_lang,
                                                          i_date     => doc.lastupdateddate,
                                                          i_prof     => i_prof,
                                                          i_timezone => NULL) AS doc_date_desc,
                       typedesc AS description,
                       numimages AS counter,
                       (CASE
                        --WHEN doc.flg_status IN (g_doc_active) AND numimages > 0 THEN  -- User can only click if the doc is active and has images
                            WHEN numimages > 0 THEN -- User can only click if the doc has images
                             'T'
                            ELSE
                             'N'
                        END) AS flg_clickable,
                       doc.id_doc_type AS id_doc_type,
                       doc.iddoc AS id_doc,
                       doc.mime_type
                  FROM TABLE(CAST(document_tbl AS t_tbl_rec_document)) doc
                 WHERE doc.flg_status IN (g_doc_active); -- only active docs are available in the viewer
        
        END IF;
    
        RETURN TRUE;
    
    END get_viewer_doc_archive;

    FUNCTION get_viewer_doc_archive_cat
    (
        i_lang            IN NUMBER,
        i_prof            IN profissional,
        i_patient         IN patient.id_patient%TYPE,
        i_episode         IN episode.id_episode%TYPE,
        i_id_doc_ori_type IN doc_ori_type.id_doc_ori_type%TYPE,
        i_id_doc_type     IN doc_type.id_doc_type%TYPE,
        io_current_level  IN OUT NUMBER,
        o_viewer_info     OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    )
    
     RETURN BOOLEAN IS
    
        c pk_types.cursor_type;
    
        ord_type        NUMBER;
        id_doc_ori_type NUMBER;
        desc_ori_type   VARCHAR2(400);
        num_docs        NUMBER;
        doc_oids        table_varchar;
        id_docs         table_number_id;
        id_dates        table_timestamp_tstz;
        titles          table_varchar;
    
        last_doc_id    NUMBER;
        last_doc_title VARCHAR2(400);
        last_doc_date  TIMESTAMP;
    
        o_date             table_timestamp := table_timestamp();
        o_counter          table_number := table_number();
        o_description      table_varchar := table_varchar();
        o_title            table_varchar := table_varchar();
        o_date_description table_varchar := table_varchar();
        o_id_doc_ori_type  table_number := table_number();
        i                  NUMBER := 1;
        document_tbl       t_tbl_rec_document;
    
        doc_flg_status table_varchar := table_varchar(g_doc_active);
    BEGIN
    
        -- Show the documents for the category
    
        document_tbl := pk_doc.get_doc_list_by_category_tbl(i_lang         => i_lang,
                                                            i_prof         => i_prof,
                                                            i_patient      => i_patient,
                                                            i_episode      => i_episode,
                                                            i_ext_req      => NULL,
                                                            i_btn          => NULL,
                                                            i_doc_ori_type => i_id_doc_ori_type,
                                                            i_id_doc_type  => i_id_doc_type);
        OPEN o_viewer_info FOR
            SELECT doc.id_doc_ori_type AS id_doc_ori_type,
                   doc.title AS title,
                   doc.lastupdateddate AS doc_date,
                   pk_date_utils.dt_chr_date_hour_str(i_lang     => i_lang,
                                                      i_date     => doc.lastupdateddate,
                                                      i_prof     => i_prof,
                                                      i_timezone => NULL) AS doc_date_desc,
                   typedesc AS description,
                   numimages AS counter,
                   (CASE
                        WHEN numimages > 0 THEN -- User can only click if the doc has images
                         'T'
                        ELSE
                         'N'
                    END) AS flg_clickable,
                   doc.id_doc_type AS id_doc_type,
                   doc.iddoc AS id_doc,
                   doc.mime_type
              FROM TABLE(CAST(document_tbl AS t_tbl_rec_document)) doc
             WHERE doc.flg_status IN (g_doc_active); -- only active docs are available in the viewer
    
        RETURN TRUE;
    
    END get_viewer_doc_archive_cat;

    /********************************************************************************************
    * This procedure updates viewer_ea archives
    * 
    * @author  Mário Mineiro
    * @since   2014-03-06
    *
    ********************************************************************************************/

    PROCEDURE upd_viewer_ehr_ea
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) IS
    
        l_patients table_number;
        l_error    t_error_out;
    
    BEGIN
    
        SELECT id_patient
          BULK COLLECT
          INTO l_patients
          FROM viewer_ehr_ea vee
         WHERE (vee.id_patient IN (SELECT id_patient
                                     FROM doc_external) OR
               vee.id_patient IN (SELECT id_patient
                                     FROM epis_diagram));
    
        IF NOT upd_viewer_ehr_ea_pat(i_lang              => i_lang,
                                     i_prof              => i_prof,
                                     i_table_id_patients => l_patients,
                                     o_error             => l_error)
        THEN
            RAISE g_exception;
        END IF;
    
    END upd_viewer_ehr_ea;

    /**********************************************************************************************
    *  This fuction will update the table viewer_ehr_ea for the specified patients.
    *
    * @param I_LANG                   The id language
    * @param I_TABLE_ID_PATIENTS      Table of id patients to be clean.
    * @param O_ERROR                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *
    * @author                         Mário Mineiro
    * @version                        2.6.3.x
    * @since                          06-03-2014
    ********************************************************************************************/

    FUNCTION upd_viewer_ehr_ea_pat
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_table_id_patients IN table_number,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_num_occur     NUMBER;
        l_desc_first    VARCHAR2(200 CHAR);
        l_code_first    VARCHAR2(200 CHAR);
        l_dt_first      VARCHAR2(200 CHAR);
        l_dummy         VARCHAR2(200 CHAR);
        o_viewer_info   pk_types.cursor_type;
        l_current_level NUMBER;
    
    BEGIN
    
        g_error := 'START UPD_VIEWER_EHR_EA_PAT';
        FOR i IN 1 .. i_table_id_patients.count
        LOOP
        
            l_current_level := 1;
            g_error         := 'CALL GET_COUNT_AND_FIRST ' || i_table_id_patients(i);
            IF NOT pk_doc.get_viewer_doc_archive(i_lang            => i_lang,
                                                 i_prof            => i_prof,
                                                 i_patient         => i_table_id_patients(i),
                                                 i_episode         => NULL,
                                                 i_id_doc_ori_type => NULL,
                                                 io_current_level  => l_current_level,
                                                 o_viewer_info     => o_viewer_info,
                                                 o_error           => o_error)
            
            THEN
                RAISE g_exception;
            END IF;
        
            g_error := 'FETCH l_cursor';
            FETCH o_viewer_info
                INTO l_dummy, l_dummy, l_dt_first, l_dummy, l_desc_first, l_num_occur, l_dummy;
            g_found := o_viewer_info%FOUND;
            CLOSE o_viewer_info;
        
            UPDATE viewer_ehr_ea
               SET num_archive = nvl(l_num_occur, 0), desc_archive = l_desc_first, dt_archive = l_dt_first
             WHERE id_patient = i_table_id_patients(i) log errors INTO err$_viewer_ehr_ea(to_char(SYSDATE)) reject
             LIMIT unlimited;
        
        END LOOP;
    
        g_error := 'Update viewer';
        IF NOT
            pk_data_gov_admin.update_viewer_epis_archive(i_table_id_patients => i_table_id_patients, o_error => o_error)
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
                                              g_package_owner,
                                              g_package_name,
                                              'UPD_VIEWER_EHR_EA_PAT',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END upd_viewer_ehr_ea_pat;

    FUNCTION get_cda_reconciliation_info
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_patient        IN patient.id_patient%TYPE,
        i_codes             IN table_varchar,
        i_doc_oid           IN VARCHAR2,
        i_doc_source        IN VARCHAR2,
        o_msg_array         OUT pk_types.cursor_type,
        o_patient_info      OUT VARCHAR2,
        o_doc_sections      OUT pk_types.cursor_type,
        o_id_reconciliation OUT NUMBER,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        g_error        VARCHAR2(200 CHAR) := 'START GETTING CDA RECONCILIATION INFORMATION';
        txt_auxiliar   VARCHAR2(1000 CHAR);
        patient_name   VARCHAR2(1000 CHAR);
        patient_gender VARCHAR2(200 CHAR);
        patient_birth  VARCHAR2(200 CHAR);
    BEGIN
        g_error := 'getting sys messages';
        IF NOT pk_message.get_message_array(i_lang => i_lang, i_code_msg_arr => i_codes, o_desc_msg_arr => o_msg_array)
        THEN
            RAISE g_exception;
        END IF;
    
        -- Reconciliation info TODO
        IF NOT pk_clinical_data_rec.start_clinical_data_rec(i_lang            => i_lang,
                                                            i_id_professional => i_prof.id,
                                                            i_id_institution  => i_prof.institution,
                                                            i_id_software     => i_prof.software,
                                                            i_doc_oid         => i_doc_oid,
                                                            i_doc_source      => i_doc_source,
                                                            o_newid           => o_id_reconciliation,
                                                            o_error           => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        g_error := 'getting patient information';
        IF NOT pk_patient.get_pat_info(i_lang        => i_lang,
                                       i_id_pat      => i_id_patient,
                                       i_prof        => i_prof,
                                       o_name        => patient_name,
                                       o_nick_name   => txt_auxiliar,
                                       o_gender      => patient_gender,
                                       o_dt_birth    => patient_birth,
                                       o_age         => txt_auxiliar,
                                       o_dt_deceased => txt_auxiliar,
                                       o_error       => o_error)
        
        THEN
            RAISE g_exception;
        END IF;
    
        g_error := 'generatting patient information';
        SELECT decode(patient_gender,
                      'M',
                      pk_message.get_message(i_lang, 'CDA_RECONCILIATION_A038'),
                      'F',
                      pk_message.get_message(i_lang, 'CDA_RECONCILIATION_A037'),
                      pk_message.get_message(i_lang, 'CDA_RECONCILIATION_A039'))
          INTO patient_gender
          FROM dual;
    
        IF (length(patient_name) > 0)
        THEN
            o_patient_info := patient_name;
        END IF;
    
        IF (length(patient_birth) > 0)
        THEN
            o_patient_info := o_patient_info || '; ' || pk_message.get_message(i_lang, 'CDA_RECONCILIATION_A034') || ': ' ||
                              patient_birth;
        END IF;
    
        IF (length(patient_gender) > 0)
        THEN
            o_patient_info := o_patient_info || '; ' || pk_message.get_message(i_lang, 'CDA_RECONCILIATION_A035') || ': ' ||
                              patient_gender;
        END IF;
    
        g_error := 'get cda sections';
        get_doc_section_import(i_lang => i_lang, i_prof => i_prof, o_doc_section => o_doc_sections, o_error => o_error);
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_msg_array);
            pk_types.open_my_cursor(o_doc_sections);
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_CDA_RECONCILIATION_INFO',
                                              o_error);
        
            RETURN FALSE;
    END get_cda_reconciliation_info;

    PROCEDURE get_doc_section_import
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        o_doc_section OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) IS
        g_error VARCHAR2(200);
    
        l_records          table_number;
        l_profile_template NUMBER;
        l_category         NUMBER;
    BEGIN
        g_error            := 'Getting profile template';
        l_profile_template := pk_prof_utils.get_prof_profile_template(i_prof => i_prof);
    
        g_error    := 'Getting professional category';
        l_category := pk_prof_utils.get_id_category(i_lang => i_lang, i_prof => i_prof);
    
        l_records := pk_core_config.get_config_records(i_area             => 'DOC_SECTION_IMPORT',
                                                       i_prof             => i_prof,
                                                       i_market           => 0,
                                                       i_category         => l_category,
                                                       i_profile_template => l_profile_template,
                                                       i_prof_dcs         => table_number(0),
                                                       i_episode_dcs      => 0);
    
        g_error := 'START GETTING DOCUMENT SECTIONS';
        BEGIN
            OPEN o_doc_section FOR
                SELECT dsi.id_doc_section_import,
                       dsi.flg_match_available,
                       pk_translation.get_translation(i_lang, dsi.code_section) code_translation,
                       dsi.class_name,
                       dsi.section_type_id
                  FROM doc_section_import dsi
                 WHERE dsi.flg_available = 'Y'
                   AND dsi.id_record IN (SELECT /*+opt_estimate(table t rows=1)*/
                                          column_value id
                                           FROM TABLE(l_records) t);
        EXCEPTION
            WHEN OTHERS THEN
                pk_types.open_my_cursor(o_doc_section);
        END;
    
    END get_doc_section_import;

    /**********************************************************************************************
    *  This fuction will update the table viewer_ehr_ea for the specified patients.
    *
    * @param I_LANG                   The id language
    * @param I_PROF                   Professional (id, institution, software)
    * @param O_DOC_ARCHIVE_AREAS      Areas available for professionals
    * @param O_DOC_ARCHIVE_AREA_OP    Operations available in each area by professional
    * @param O_ERROR                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *
    * @author                         Jorge Costa
    * @version                        2.6.4.2
    * @since                          10-09-2014
    ********************************************************************************************/
    FUNCTION get_doc_archive_area
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        o_doc_archive_areas   OUT pk_types.cursor_type,
        o_doc_archive_area_op OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
        g_error            VARCHAR2(200 CHAR) := 'START GETTING CDA RECONCILIATION INFORMATION';
        l_records          table_number;
        l_profile_template NUMBER;
        l_category         NUMBER;
    
    BEGIN
        g_error            := 'Getting profile template';
        l_profile_template := pk_prof_utils.get_prof_profile_template(i_prof => i_prof);
    
        g_error    := 'Getting professional category';
        l_category := pk_prof_utils.get_id_category(i_lang => i_lang, i_prof => i_prof);
    
        l_records := pk_core_config.get_config_records(i_area             => 'DOC_ARCHIVE_AREA',
                                                       i_prof             => i_prof,
                                                       i_market           => 0,
                                                       i_category         => l_category,
                                                       i_profile_template => l_profile_template,
                                                       i_prof_dcs         => table_number(0),
                                                       i_episode_dcs      => 0);
    
        OPEN o_doc_archive_areas FOR
            SELECT da.id_doc_archive_area,
                   da.code_area,
                   da.code_title_area,
                   pk_translation.get_translation(i_lang, da.code_title_area) desc_area,
                   da.ux_class_name,
                   da.rank
              FROM doc_archive_area da
             WHERE da.id_record IN (SELECT /*+opt_estimate(table t rows=1)*/
                                     column_value id
                                      FROM TABLE(l_records) t)
               AND da.flg_available = g_yes
             ORDER BY da.rank;
    
        l_records := pk_core_config.get_config_records(i_area             => 'DOC_ARCHIVE_AREA_OP',
                                                       i_prof             => i_prof,
                                                       i_market           => 0,
                                                       i_category         => l_category,
                                                       i_profile_template => l_profile_template,
                                                       i_prof_dcs         => table_number(0),
                                                       i_episode_dcs      => 0);
    
        OPEN o_doc_archive_area_op FOR
            SELECT da.id_doc_archive_area,
                   da.code_area,
                   dao.id_doc_operation_conf,
                   dao.id_action,
                   a.from_state,
                   a.to_state
              FROM doc_archive_area da
             INNER JOIN doc_archive_area_op dao
                ON da.id_doc_archive_area = dao.id_doc_archive_area
               AND dao.id_record IN (SELECT /*+opt_estimate(table t rows=1)*/
                                      column_value id
                                       FROM TABLE(l_records) t)
               AND dao.flg_available = g_yes
              LEFT OUTER JOIN action a
                ON dao.id_action = a.id_action;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_doc_archive_areas);
            pk_types.open_my_cursor(o_doc_archive_area_op);
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_DOC_ARCHIE_AREA',
                                              o_error);
        
            RETURN FALSE;
    END get_doc_archive_area;

    FUNCTION insert_area
    (
        i_code_area     IN VARCHAR2,
        i_ux_class_name IN VARCHAR2,
        i_flg_available IN VARCHAR2,
        i_rank          IN NUMBER
    ) RETURN NUMBER IS
        l_next_id NUMBER(24);
    BEGIN
        SELECT MAX(id_doc_archive_area)
          INTO l_next_id
          FROM doc_archive_area;
    
        l_next_id := l_next_id + 1;
    
        INSERT INTO doc_archive_area
            (id_doc_archive_area, code_area, ux_class_name, flg_available, rank, id_record)
        VALUES
            (l_next_id, i_code_area, i_ux_class_name, i_flg_available, i_rank, l_next_id);
    
        RETURN l_next_id;
    END insert_area;

    FUNCTION insert_operation_conf
    (
        i_operation_name IN VARCHAR2,
        i_target_name    IN VARCHAR2,
        i_source_name    IN VARCHAR2,
        i_flg_available  IN VARCHAR2
    ) RETURN NUMBER IS
        l_next_id NUMBER(24);
    BEGIN
    
        SELECT MAX(id_doc_operation_config)
          INTO l_next_id
          FROM doc_operation_conf;
    
        l_next_id := l_next_id + 1;
    
        INSERT INTO doc_operation_conf
            (operation_name, target_name, source_name, id_doc_operation_config, flg_available)
        VALUES
            (i_operation_name, i_target_name, i_source_name, l_next_id, i_flg_available);
    
        RETURN l_next_id;
    END insert_operation_conf;

    FUNCTION insert_area_operation
    (
        i_id_doc_archive_area   IN NUMBER,
        i_id_doc_operation_conf IN NUMBER,
        i_id_action             IN NUMBER,
        i_flg_available         IN NUMBER
    ) RETURN NUMBER IS
        l_next_id NUMBER(24);
    BEGIN
    
        SELECT MAX(id_record)
          INTO l_next_id
          FROM doc_archive_area_op;
        l_next_id := l_next_id + 1;
    
        INSERT INTO doc_archive_area_op
            (id_doc_archive_area, id_doc_operation_conf, id_action, id_record, flg_available)
        VALUES
            (i_id_doc_archive_area, i_id_doc_operation_conf, i_id_action, l_next_id, i_flg_available);
    
        RETURN l_next_id;
    END insert_area_operation;

    /**********************************************************************************************
    *  This fuction will search document given a text search input.
    *
    * @param i_search_text                   word to search
    *
    * @return                         table_number record number
    *
    * @author                         Luis Costa
    * @version                        2.6.5.0
    * @since                          15-07-2015
    ********************************************************************************************/
    FUNCTION filter_documents_by_text(i_search_text IN VARCHAR2) RETURN table_number IS
    
        l_doc_ids table_number;
    BEGIN
    
        SELECT t.iddoc
          BULK COLLECT
          INTO l_doc_ids
          FROM v_all_documents_archive t
         WHERE pk_utils.remove_upper_accentuation(nvl(t.title, ' ')) LIKE
               '%' || REPLACE(pk_utils.remove_upper_accentuation(i_search_text), ' ', '%') || '%';
    
        RETURN l_doc_ids;
    END filter_documents_by_text;

    /**********************************************************************************************
    *  This fuction will update the episode of a given document
    *
    * @param i_lang                   The id language
    * @param i_prof                   Professional (id, institution, software)
    * @param i_doc                    Document to update
    * @param i_episode                Episode to set
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *
    * @author                         Andre Silva
    * @version                        2.7.4.4
    * @since                          03-10-2018
    ********************************************************************************************/
    FUNCTION set_epis_in_doc
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_doc_external IN doc_external.id_doc_external%TYPE,
        i_id_episode      IN episode.id_episode%TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        UPDATE doc_external
           SET id_episode = i_id_episode
         WHERE id_doc_external = i_id_doc_external;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_EPIS_IN_DOC',
                                              o_error);
        
            RETURN FALSE;
    END set_epis_in_doc;

    /**
    * GET doc type rank
    *
    * @param i_lang           Language identifier
    * @param i_prof           Logged professional structure
    * @param i_doc_ori_type     Doc ori type id
    *
    * @return                 rank number
    *
    * @raises                 PL/SQL generic error "OTHERS"
    *
    * @author               Lillian Lu
    * @version              2.7.4.0
    * @since                2018-09-10
    */
    FUNCTION get_doc_rank
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_doc_ori_type IN doc_external.id_doc_external%TYPE
    ) RETURN NUMBER IS
    
        l_rank doc_types_config.rank%TYPE;
    
        l_my_pt profile_template.id_profile_template%TYPE;
    
        my_exception EXCEPTION;
        l_error      t_error_out;
    
    BEGIN
    
        --Validate profile template from professional
        g_error := 'GET PK_DOC.GET_PROFILE_TEMPLATE';
        IF NOT pk_doc.get_profile_template(i_lang, i_prof, l_my_pt, l_error)
        THEN
            RAISE my_exception;
        END IF;
    
        g_error := 'GET RANK';
        SELECT t.rank
          INTO l_rank
          FROM (SELECT d.id_doc_ori_type,
                       d.flg_view,
                       d.rank,
                       rank() over(PARTITION BY d.id_doc_ori_type ORDER BY d.id_profile_template DESC, d.id_institution DESC, d.id_software DESC) rn
                  FROM (SELECT dtc.id_doc_ori_type_parent id_doc_ori_type,
                               dtc.flg_view,
                               dtc.id_profile_template,
                               dtc.id_institution,
                               dtc.id_software,
                               dtc.rank
                          FROM doc_types_config dtc
                         WHERE dtc.id_institution IN (i_prof.institution, 0)
                           AND dtc.id_software IN (i_prof.software, 0)
                           AND dtc.id_profile_template IN (l_my_pt, 0)
                           AND dtc.id_doc_ori_type_parent IS NOT NULL
                        UNION
                        SELECT dtc.id_doc_ori_type id_doc_ori_type,
                               dtc.flg_view,
                               dtc.id_profile_template,
                               dtc.id_institution,
                               dtc.id_software,
                               dtc.rank
                          FROM doc_types_config dtc
                         WHERE dtc.id_institution IN (i_prof.institution, 0)
                           AND dtc.id_software IN (i_prof.software, 0)
                           AND dtc.id_profile_template IN (l_my_pt, 0)
                           AND dtc.id_doc_ori_type IS NOT NULL) d) t,
               doc_ori_type dot
         WHERE dot.id_doc_ori_type = i_doc_ori_type
           AND dot.flg_available = g_yes
           AND dot.id_doc_ori_type = t.id_doc_ori_type
           AND t.flg_view = g_yes
           AND t.rn = 1
         ORDER BY t.rank;
    
        RETURN l_rank;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN 0;
    END get_doc_rank;

    FUNCTION get_default_doc_types
    (
        i_lang         IN NUMBER,
        i_prof         IN profissional,
        i_area         IN VARCHAR2,
        o_doc_ori_type OUT NUMBER,
        o_doc_type     OUT NUMBER,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_doc_type     NUMBER := NULL;
        l_doc_ori_type NUMBER := NULL;
    
    BEGIN
    
        IF i_area = g_area_lab_test
        THEN
            l_doc_type     := NULL;
            l_doc_ori_type := g_doc_ori_type_lab_test;
        END IF;
    
        o_doc_type     := l_doc_type;
        o_doc_ori_type := l_doc_ori_type;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_DEFAULT_DOC_TYPES',
                                              o_error);
            RETURN FALSE;
    END get_default_doc_types;

    /**
    * Returns TRUE if the documents are associated to lab_tests
    *
    * @param i_lang              language id
    * @param i_prof              professional, software and institution ids
    * @param i_doc_external      id of external document  
    *
    * @return true (sucess), false (error)
    */
    FUNCTION is_lab_test_result
    (
        i_lang         IN NUMBER,
        i_prof         IN profissional,
        i_doc_external IN doc_external.id_doc_external%TYPE
    ) RETURN BOOLEAN IS
    
        l_count NUMBER := 0;
    
    BEGIN
    
        SELECT COUNT(1)
          INTO l_count
          FROM analysis_media_archive ama
         WHERE ama.id_doc_external = i_doc_external
           AND ama.flg_status = pk_alert_constant.g_active
           AND ama.flg_type = pk_lab_tests_constant.g_media_archive_analysis_res;
    
        IF l_count > 0
        THEN
            RETURN TRUE;
        ELSE
            RETURN FALSE;
        END IF;
    
    END is_lab_test_result;

    FUNCTION ins_detail_in_type
    (
        i_descr IN VARCHAR2,
        i_val   IN VARCHAR2,
        i_type  IN VARCHAR2
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_detail.extend;
        g_detail(g_detail.last()) := t_rec_screen_detail(i_descr, i_val, i_type, NULL);
        RETURN TRUE;
    END ins_detail_in_type;

    FUNCTION get_document_detail
    (
        i_lang       IN NUMBER,
        i_prof       IN profissional,
        i_doc        IN NUMBER,
        o_doc_detail OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
        CURSOR c_comments IS
            SELECT dc.desc_comment, dc.dt_comment, dc.id_professional
              FROM doc_comments dc
              JOIN doc_external de
                ON de.id_doc_external = dc.id_doc_external
             WHERE de.id_doc_external = i_doc
               AND dc.flg_cancel = pk_alert_constant.g_no
             ORDER BY dc.dt_comment DESC;
    
        l_title_label           sys_message.desc_message%TYPE;
        l_doc_label             sys_message.desc_message%TYPE;
        l_category_label        sys_message.desc_message%TYPE;
        l_type_doc_label        sys_message.desc_message%TYPE;
        l_num_doc_label         sys_message.desc_message%TYPE;
        l_dt_doc_label          sys_message.desc_message%TYPE;
        l_record_date_label     sys_message.desc_message%TYPE;
        l_dt_exp_label          sys_message.desc_message%TYPE;
        l_desc_speciality_label sys_message.desc_message%TYPE;
        l_author_label          sys_message.desc_message%TYPE;
        l_performed_by_label    sys_message.desc_message%TYPE;
        l_type_original_label   sys_message.desc_message%TYPE;
        l_number_images_label   sys_message.desc_message%TYPE;
        l_original_stays_label  sys_message.desc_message%TYPE;
        l_desc_language_label   sys_message.desc_message%TYPE;
        l_notes_label           sys_message.desc_message%TYPE;
        l_signature_label       sys_message.desc_message%TYPE;
    
        l_title           doc_external.title%TYPE;
        l_doc             VARCHAR2(4000);
        l_category        VARCHAR2(4000);
        l_type_doc        VARCHAR2(4000);
        l_num_doc         doc_external.num_doc%TYPE;
        l_dt_doc          VARCHAR2(12 CHAR);
        l_record_date     VARCHAR2(400);
        l_dt_exp          VARCHAR2(12 CHAR);
        l_desc_speciality VARCHAR2(4000);
        l_author          VARCHAR2(4000);
        l_performed_by    VARCHAR2(4000);
        l_type_original   VARCHAR2(4000);
        l_number_images   NUMBER;
        l_original_stays  VARCHAR2(4000);
        l_desc_language   VARCHAR2(4000);
        l_signature       VARCHAR2(4000);
        l_id_performed_by doc_external.update_user%TYPE;
        l_exception       EXCEPTION;
    
        l_tbl_doc_activity t_doc_activity_list;
        l_documented_by    sys_message.desc_message%TYPE;
    
    BEGIN
    
        -- Obter detalhes
        g_error := 'OPEN O_DOC_DETAIL';
    
        SELECT NULL doc,
               de.num_doc,
               de.title,
               pk_date_utils.dt_chr(i_lang, de.dt_emited, i_prof) dt_doc,
               pk_date_utils.dt_chr(i_lang, de.dt_expire, i_prof) dt_exp,
               
               decode(de.desc_doc_destination,
                      NULL,
                      pk_translation.get_translation(i_lang,
                                                     'DOC_DESTINATION.CODE_DOC_DESTINATION.' || de.id_doc_destination),
                      de.desc_doc_destination) orig_dest,
               decode(de.desc_doc_ori_type,
                      NULL,
                      pk_translation.get_translation(i_lang, 'DOC_ORI_TYPE.CODE_DOC_ORI_TYPE.' || de.id_doc_ori_type),
                      de.desc_doc_ori_type) orig_type,
               pk_doc.get_count_image(i_lang, i_prof, de.id_doc_external) num_img,
               decode(de.desc_doc_original,
                      NULL,
                      pk_translation.get_translation(i_lang, 'DOC_ORIGINAL.CODE_DOC_ORIGINAL.' || de.id_doc_original),
                      de.desc_doc_original) desc_doc_original,
               de.author,
               pk_translation.get_translation(i_lang, 'SPECIALITY.CODE_SPECIALITY.' || de.id_specialty) desc_specialty,
               coalesce(de.desc_language, pk_translation.get_translation(i_lang, il.code_iso_lang)) desc_language,
               de.update_time performed_date,
               coalesce(de.desc_perf_by, pk_prof_utils.get_name_signature(i_lang, i_prof, de.id_prof_perf_by)) performed_by,
               de.id_prof_perf_by id_performed_by
          INTO l_doc,
               l_num_doc,
               l_title,
               l_dt_doc,
               l_dt_exp,
               l_original_stays,
               l_category,
               l_number_images,
               l_type_original,
               l_author,
               l_desc_speciality,
               l_desc_language,
               l_record_date,
               l_performed_by,
               l_id_performed_by
          FROM doc_external de
          LEFT JOIN xds_document_submission xds
            ON (nvl(de.id_grupo, de.id_doc_external) = xds.id_doc_external)
          LEFT JOIN iso_lang il
            ON il.id_iso_lang = de.id_language
         WHERE de.id_doc_external = i_doc
           AND nvl(xds.flg_status, g_doc_active) = g_doc_active;
    
        IF l_title IS NOT NULL
        THEN
            IF NOT ins_detail_in_type(l_title, NULL, pk_alert_constant.g_flg_screen_l1)
            THEN
                RAISE l_exception;
            END IF;
        
            IF NOT ins_detail_in_type(NULL, NULL, pk_alert_constant.g_flg_screen_wl)
            THEN
                RAISE l_exception;
            END IF;
            l_doc_label := pk_message.get_message(i_lang => i_lang, i_code_mess => 'ARCHIVE_DETAIL_FIELDS_T001');
        
            IF NOT ins_detail_in_type(l_doc_label, l_title, pk_alert_constant.g_flg_screen_l2b)
            THEN
                RAISE l_exception;
            END IF;
        
        END IF;
    
        IF l_category IS NOT NULL
        THEN
            l_category_label := pk_message.get_message(i_lang => i_lang, i_code_mess => 'ARCHIVE_DETAIL_FIELDS_T002');
        
            IF NOT ins_detail_in_type(l_category_label, l_category, pk_alert_constant.g_flg_screen_l2b)
            THEN
                RAISE l_exception;
            END IF;
        END IF;
    
        IF l_doc IS NOT NULL
        THEN
            l_type_doc_label := pk_message.get_message(i_lang => i_lang, i_code_mess => 'ARCHIVE_DETAIL_FIELDS_T003');
        
            IF NOT ins_detail_in_type(l_type_doc_label, l_doc, pk_alert_constant.g_flg_screen_l2b)
            THEN
                RAISE l_exception;
            END IF;
        END IF;
    
        IF l_num_doc IS NOT NULL
        THEN
            l_num_doc_label := pk_message.get_message(i_lang => i_lang, i_code_mess => 'ARCHIVE_DETAIL_FIELDS_T004');
        
            IF NOT ins_detail_in_type(l_num_doc_label, l_num_doc, pk_alert_constant.g_flg_screen_l2b)
            THEN
                RAISE l_exception;
            END IF;
        END IF;
    
        IF l_dt_doc IS NOT NULL
        THEN
            l_dt_doc_label := pk_message.get_message(i_lang => i_lang, i_code_mess => 'ARCHIVE_DETAIL_FIELDS_T005');
        
            IF NOT ins_detail_in_type(l_dt_doc_label, l_dt_doc, pk_alert_constant.g_flg_screen_l2b)
            THEN
                RAISE l_exception;
            END IF;
        END IF;
    
        IF l_dt_exp IS NOT NULL
        THEN
            l_dt_exp_label := pk_message.get_message(i_lang => i_lang, i_code_mess => 'ARCHIVE_DETAIL_FIELDS_T014');
        
            IF NOT ins_detail_in_type(l_dt_exp_label, l_dt_exp, pk_alert_constant.g_flg_screen_l2b)
            THEN
                RAISE l_exception;
            END IF;
        END IF;
    
        IF l_desc_speciality IS NOT NULL
        THEN
            l_desc_speciality_label := pk_message.get_message(i_lang      => i_lang,
                                                              i_code_mess => 'ARCHIVE_DETAIL_FIELDS_T015');
        
            IF NOT ins_detail_in_type(l_desc_speciality_label, l_desc_speciality, pk_alert_constant.g_flg_screen_l2b)
            THEN
                RAISE l_exception;
            END IF;
        END IF;
    
        IF l_author IS NOT NULL
        THEN
            l_author_label := pk_message.get_message(i_lang => i_lang, i_code_mess => 'ARCHIVE_DETAIL_FIELDS_T006');
        
            IF NOT ins_detail_in_type(l_author_label, l_author, pk_alert_constant.g_flg_screen_l2b)
            THEN
                RAISE l_exception;
            END IF;
        END IF;
    
        IF l_performed_by IS NOT NULL
        THEN
            l_performed_by_label := pk_message.get_message(i_lang      => i_lang,
                                                           i_code_mess => 'ARCHIVE_DETAIL_FIELDS_T016');
        
            IF NOT ins_detail_in_type(l_performed_by_label, l_performed_by, pk_alert_constant.g_flg_screen_l2b)
            THEN
                RAISE l_exception;
            END IF;
        END IF;
    
        IF l_type_original IS NOT NULL
        THEN
            l_type_original_label := pk_message.get_message(i_lang => i_lang, i_code_mess => 'DOC_T027') || ':';
        
            IF NOT ins_detail_in_type(l_type_original_label, l_type_original, pk_alert_constant.g_flg_screen_l2b)
            THEN
                RAISE l_exception;
            END IF;
        END IF;
    
        IF l_number_images IS NOT NULL
        THEN
            l_number_images_label := pk_message.get_message(i_lang      => i_lang,
                                                            i_code_mess => 'ARCHIVE_DETAIL_FIELDS_T008');
        
            IF NOT ins_detail_in_type(l_number_images_label, l_number_images, pk_alert_constant.g_flg_screen_l2b)
            THEN
                RAISE l_exception;
            END IF;
        END IF;
    
        IF l_original_stays IS NOT NULL
        THEN
            l_original_stays_label := pk_message.get_message(i_lang      => i_lang,
                                                             i_code_mess => 'ARCHIVE_DETAIL_FIELDS_T009');
        
            IF NOT ins_detail_in_type(l_original_stays_label, l_original_stays, pk_alert_constant.g_flg_screen_l2b)
            THEN
                RAISE l_exception;
            END IF;
        END IF;
    
        IF l_desc_language IS NOT NULL
        THEN
            l_desc_language_label := pk_message.get_message(i_lang      => i_lang,
                                                            i_code_mess => 'ARCHIVE_DETAIL_FIELDS_T017');
        
            IF NOT ins_detail_in_type(l_desc_language_label, l_desc_language, pk_alert_constant.g_flg_screen_l2b)
            THEN
                RAISE l_exception;
            END IF;
        END IF;
    
        --comments
        g_error := 'get comments';
    
        l_signature_label := pk_message.get_message(i_lang => i_lang, i_code_mess => 'ARCHIVE_DETAIL_FIELDS_T011');
    
        FOR r IN c_comments
        LOOP
            IF NOT ins_detail_in_type('', '', pk_alert_constant.g_flg_screen_wl)
            THEN
                RAISE l_exception;
            END IF;
        
            IF l_notes_label IS NULL
            THEN
                l_notes_label := pk_message.get_message(i_lang => i_lang, i_code_mess => 'ARCHIVE_DETAIL_FIELDS_T010');
            
                IF NOT ins_detail_in_type(l_notes_label, '', pk_alert_constant.g_flg_screen_l2b)
                THEN
                    RAISE l_exception;
                END IF;
            END IF;
        
            IF NOT ins_detail_in_type('', r.desc_comment, pk_alert_constant.g_flg_screen_l2b)
            THEN
                RAISE l_exception;
            END IF;
        
            l_signature := pk_prof_utils.get_detail_signature(i_lang                => i_lang,
                                                              i_prof                => i_prof,
                                                              i_id_episode          => NULL,
                                                              i_date_last_change    => r.dt_comment,
                                                              i_id_prof_last_change => r.id_professional);
            IF NOT ins_detail_in_type(l_signature_label, l_signature, pk_alert_constant.g_flg_screen_lp)
            THEN
                RAISE l_exception;
            END IF;
        END LOOP;
    
        IF NOT pk_doc_activity.get_doc_activity(i_lang         => i_lang,
                                                i_prof         => i_prof,
                                                i_id_doc       => i_doc,
                                                o_doc_activity => l_tbl_doc_activity,
                                                o_error        => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        l_documented_by := pk_message.get_message(i_lang => i_lang, i_code_mess => 'ARCHIVE_DETAIL_FIELDS_T019');
        IF l_tbl_doc_activity.exists(1)
        THEN
            FOR r IN l_tbl_doc_activity.first() .. l_tbl_doc_activity.last()
            LOOP
                IF l_title IS NULL
                THEN
                    l_title := pk_message.get_message(i_lang => i_lang, i_code_mess => 'ARCHIVE_HISTORY_TITLE_M001');
                
                    IF NOT ins_detail_in_type(l_title, '', pk_alert_constant.g_flg_screen_l1)
                    THEN
                        RAISE l_exception;
                    END IF;
                END IF;
            
                IF NOT ins_detail_in_type('', '', pk_alert_constant.g_flg_screen_wl)
                THEN
                    RAISE l_exception;
                END IF;
            
                IF NOT ins_detail_in_type(l_tbl_doc_activity(r).operation_desc, '', pk_alert_constant.g_flg_screen_l2b)
                THEN
                    RAISE l_exception;
                END IF;
            
                l_signature := pk_prof_utils.get_detail_signature(i_lang                => i_lang,
                                                                  i_prof                => i_prof,
                                                                  i_id_episode          => NULL,
                                                                  i_date_last_change    => l_tbl_doc_activity(r).dt_operation_tstz,
                                                                  i_id_prof_last_change => l_tbl_doc_activity(r).id_professional);
            
                IF NOT ins_detail_in_type('',
                                          l_documented_by || pk_alert_constant.g_two_points || l_signature,
                                          pk_alert_constant.g_flg_screen_lp)
                THEN
                    RAISE l_exception;
                END IF;
            
            END LOOP;
        END IF;
    
        OPEN o_doc_detail FOR
            SELECT descr, val, tipo AS TYPE
              FROM TABLE(g_detail);
    
        RETURN TRUE;
    
        OPEN o_doc_detail FOR
            SELECT descr, val, tipo AS TYPE
              FROM TABLE(g_detail);
    
        -- log document activity
        g_error := 'Error registering document activity';
        IF NOT pk_doc_activity.log_document_activity(i_lang            => i_lang,
                                                     i_prof            => i_prof,
                                                     i_doc_id          => i_doc,
                                                     i_operation       => 'VIEW',
                                                     i_source          => 'EHR',
                                                     i_target          => 'EHR',
                                                     i_operation_param => NULL,
                                                     o_error           => o_error)
        THEN
            RAISE l_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_DOCUMENT_DETAIL',
                                              o_error);
            RETURN FALSE;
    END get_document_detail;

    FUNCTION get_document_detail_hist
    (
        i_lang       IN NUMBER,
        i_prof       IN profissional,
        i_doc        IN NUMBER,
        o_doc_detail OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_tbl_doc_activity t_doc_activity_list;
        l_title            sys_message.desc_message%TYPE;
        l_documented_by    sys_message.desc_message%TYPE;
        l_signature        VARCHAR2(4000);
        l_exception        EXCEPTION;
    BEGIN
    
        IF NOT pk_doc_activity.get_doc_activity(i_lang         => i_lang,
                                                i_prof         => i_prof,
                                                i_id_doc       => i_doc,
                                                o_doc_activity => l_tbl_doc_activity,
                                                o_error        => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        l_documented_by := pk_message.get_message(i_lang => i_lang, i_code_mess => 'ARCHIVE_DETAIL_FIELDS_T019');
    
        FOR r IN l_tbl_doc_activity.first() .. l_tbl_doc_activity.last()
        LOOP
            IF l_title IS NULL
            THEN
                l_title := pk_message.get_message(i_lang => i_lang, i_code_mess => 'ARCHIVE_HISTORY_TITLE_M001');
            
                IF NOT ins_detail_in_type(l_title, '', pk_alert_constant.g_flg_screen_l1)
                THEN
                    RAISE l_exception;
                END IF;
            END IF;
        
            IF NOT ins_detail_in_type('', '', pk_alert_constant.g_flg_screen_wl)
            THEN
                RAISE l_exception;
            END IF;
        
            IF NOT ins_detail_in_type(l_tbl_doc_activity(r).operation_desc, '', pk_alert_constant.g_flg_screen_l2)
            THEN
                RAISE l_exception;
            END IF;
        
            l_signature := pk_prof_utils.get_detail_signature(i_lang                => i_lang,
                                                              i_prof                => i_prof,
                                                              i_id_episode          => NULL,
                                                              i_date_last_change    => l_tbl_doc_activity(r).dt_operation_tstz,
                                                              i_id_prof_last_change => l_tbl_doc_activity(r).id_professional);
        
            IF NOT ins_detail_in_type('',
                                      l_documented_by || pk_alert_constant.g_two_points || l_signature,
                                      pk_alert_constant.g_flg_screen_lp)
            THEN
                RAISE l_exception;
            END IF;
        
        END LOOP;
    
        OPEN o_doc_detail FOR
            SELECT descr, val, tipo AS TYPE
              FROM TABLE(g_detail);
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_doc_detail);
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     g_package_owner,
                                                     g_package_name,
                                                     'GET_DOCUMENT_DETAIL_HIST',
                                                     o_error);
            RETURN FALSE;
    END get_document_detail_hist;

    FUNCTION get_doc_archive_values
    (
        i_lang           IN NUMBER,
        i_prof           IN profissional,
        i_episode        IN NUMBER,
        i_patient        IN NUMBER,
        i_action         IN NUMBER, -- edit, new, submit
        i_root_name      IN VARCHAR2, -- root of dynamic screen
        i_curr_component IN NUMBER,
        i_idx            IN NUMBER,
        i_tbl_id_pk      IN table_number, -- id necessary for identifying pk for editing
        i_tbl_mkt_rel    IN table_number, -- components needed for default/edit
        i_value          IN table_table_varchar,
        o_error          OUT t_error_out
    ) RETURN t_tbl_ds_get_value IS
        tbl_result t_tbl_ds_get_value := t_tbl_ds_get_value();
    
        l_curr_comp_int_name ds_component.internal_name%TYPE;
        l_ds_internal_name   ds_component.internal_name%TYPE;
        l_id_ds_component    ds_component.id_ds_component%TYPE;
    
        l_id_external_doc external_doc.id_external_doc%TYPE;
    
        l_curr_val           VARCHAR2(4000) := NULL;
        l_flg_original_other VARCHAR2(1) := pk_alert_constant.g_no;
    
        --Variables for edition
        l_title                     VARCHAR2(200 CHAR);
        l_id_category               NUMBER(24);
        l_category_desc             translation.desc_lang_1%TYPE;
        l_document_number           doc_external.num_doc%TYPE;
        l_dt_document               VARCHAR2(50char);
        l_dt_expire                 VARCHAR2(50char);
        l_id_specialty              doc_external.id_specialty%TYPE;
        l_specialty_desc            VARCHAR2(200 CHAR);
        l_author                    VARCHAR2(1000 CHAR);
        l_performed_by              VARCHAR2(1000 CHAR);
        l_id_original_type          NUMBER(24);
        l_original_type_desc        VARCHAR2(200 CHAR);
        l_original_type_desc_other  VARCHAR2(200 CHAR);
        l_id_original_with          NUMBER(24);
        l_flg_original_stays_other  VARCHAR2(1) := pk_alert_constant.g_no;
        l_original_with_desc        VARCHAR2(200 CHAR);
        l_original_stays_desc_other VARCHAR2(200 CHAR);
        l_id_language               NUMBER(24);
        l_language_desc             VARCHAR2(200 CHAR);
        l_notes                     doc_comments.desc_comment%TYPE;
        l_flg_sent_by               doc_external.flg_sent_by%TYPE;
        l_sent_by_desc              VARCHAR2(200 CHAR);
        l_flg_other_language        VARCHAR2(1) := pk_alert_constant.g_no;
        l_desc_language_other       doc_external.desc_language%TYPE;
    
        my_exception EXCEPTION;
    
    BEGIN
    
        IF (i_action IS NULL OR i_action IN (-1))
        THEN
            IF NOT pk_doc.create_initdoc(i_lang            => i_lang,
                                         i_prof            => i_prof,
                                         i_patient         => i_patient,
                                         i_episode         => i_episode,
                                         i_ext_req         => NULL,
                                         i_btn             => NULL,
                                         i_id_grupo        => NULL,
                                         i_internal_commit => TRUE,
                                         o_id_doc          => l_id_external_doc,
                                         o_error           => o_error)
            THEN
                RAISE my_exception;
            END IF;
        
            --NEW FORM
            SELECT t_rec_ds_get_value(id_ds_cmpt_mkt_rel => t.id_ds_cmpt_mkt_rel,
                                       id_ds_component    => t.id_ds_component_child,
                                       internal_name      => t.internal_name_child,
                                       VALUE              => CASE
                                                                 WHEN t.internal_name_child = 'DS_PROFESSIONAL' THEN
                                                                  i_prof.id
                                                                 WHEN t.internal_name_child = 'DS_ID_DOC_EXTERNAL' THEN
                                                                  l_id_external_doc
                                                                 WHEN t.internal_name_child = 'DS_CATEGORY'
                                                                      AND i_root_name = 'DS_DOC_LAB_TEST_RESULT' THEN
                                                                  g_doc_ori_type_lab_test
                                                             END,
                                       value_clob         => NULL,
                                       min_value          => NULL,
                                       max_value          => NULL,
                                       desc_value         => CASE
                                                                 WHEN t.internal_name_child = 'DS_PROFESSIONAL' THEN
                                                                  pk_prof_utils.get_name_signature(i_lang, i_prof, i_prof.id)
                                                                 WHEN t.internal_name_child = 'DS_CATEGORY'
                                                                      AND i_root_name = 'DS_DOC_LAB_TEST_RESULT' THEN
                                                                  (SELECT pk_translation.get_translation(i_lang, dot.code_doc_ori_type)
                                                                     FROM doc_ori_type dot
                                                                    WHERE dot.id_doc_ori_type = g_doc_ori_type_lab_test)
                                                             END,
                                       desc_clob          => NULL,
                                       id_unit_measure    => t.id_unit_measure,
                                       desc_unit_measure  => NULL,
                                       flg_validation     => pk_alert_constant.g_yes,
                                       err_msg            => NULL,
                                       flg_event_type     => CASE
                                                                 WHEN t.internal_name_child = 'DS_PROFESSIONAL' THEN
                                                                  'R'
                                                             END,
                                       flg_multi_status   => NULL,
                                       idx                => i_idx)
              BULK COLLECT
              INTO tbl_result
              FROM (SELECT dc.id_ds_cmpt_mkt_rel,
                           dc.id_ds_component_child,
                           dc.internal_name_child,
                           dc.flg_event_type,
                           dc.rn,
                           dc.flg_component_type_child,
                           dc.id_unit_measure
                      FROM TABLE(pk_dyn_form.get_dyn_cfg(i_lang           => i_lang,
                                                         i_prof           => i_prof,
                                                         i_patient        => NULL,
                                                         i_component_name => i_root_name,
                                                         i_action         => NULL)) dc) t
              JOIN ds_component d
                ON d.id_ds_component = t.id_ds_component_child
             WHERE d.internal_name IN ('DS_PROFESSIONAL', 'DS_ID_DOC_EXTERNAL', 'DS_CATEGORY');
        
        ELSIF i_action = pk_dyn_form_constant.get_submit_action
        THEN
            --Action of submiting a value on any given element of the form
            IF i_curr_component IS NOT NULL
            THEN
                --Check which element has been changed
                SELECT d.internal_name_child
                  INTO l_curr_comp_int_name
                  FROM ds_cmpt_mkt_rel d
                 WHERE d.id_ds_cmpt_mkt_rel = i_curr_component;
            
                IF l_curr_comp_int_name = 'DS_ORIGINAL_TYPE'
                THEN
                    FOR i IN i_tbl_mkt_rel.first .. i_tbl_mkt_rel.last
                    LOOP
                        l_ds_internal_name := pk_orders_utils.get_ds_internal_name(i_tbl_mkt_rel(i));
                        l_id_ds_component  := pk_orders_utils.get_id_ds_component(i_tbl_mkt_rel(i));
                    
                        IF l_ds_internal_name = l_curr_comp_int_name
                        THEN
                        
                            l_flg_original_other := get_types_config_other(NULL,
                                                                           NULL,
                                                                           i_value(i) (1),
                                                                           NULL,
                                                                           i_prof,
                                                                           pk_prof_utils.get_prof_profile_template(i_prof),
                                                                           NULL);
                        
                            EXIT;
                        END IF;
                    END LOOP;
                
                    FOR i IN i_tbl_mkt_rel.first .. i_tbl_mkt_rel.last
                    LOOP
                        l_ds_internal_name := pk_orders_utils.get_ds_internal_name(i_tbl_mkt_rel(i));
                        l_id_ds_component  := pk_orders_utils.get_id_ds_component(i_tbl_mkt_rel(i));
                    
                        IF l_ds_internal_name = 'DS_ORIGINAL_OTHER'
                        THEN
                        
                            tbl_result.extend();
                            tbl_result(tbl_result.count) := t_rec_ds_get_value(id_ds_cmpt_mkt_rel => i_tbl_mkt_rel(i),
                                                                               id_ds_component    => l_id_ds_component,
                                                                               internal_name      => l_ds_internal_name,
                                                                               VALUE              => i_value(i) (1),
                                                                               value_clob         => NULL,
                                                                               min_value          => NULL,
                                                                               max_value          => NULL,
                                                                               desc_value         => i_value(i) (1),
                                                                               desc_clob          => NULL,
                                                                               id_unit_measure    => NULL,
                                                                               desc_unit_measure  => NULL,
                                                                               flg_validation     => pk_alert_constant.g_yes,
                                                                               err_msg            => NULL,
                                                                               flg_event_type     => CASE
                                                                                                      l_flg_original_other
                                                                                                         WHEN
                                                                                                          pk_alert_constant.g_yes THEN
                                                                                                          'M'
                                                                                                         ELSE
                                                                                                          'I'
                                                                                                     END,
                                                                               flg_multi_status   => NULL,
                                                                               idx                => i_idx);
                        
                        END IF;
                    END LOOP;
                ELSIF l_curr_comp_int_name = 'DS_ORIGINAL_STAYS_WITH'
                THEN
                    FOR i IN i_tbl_mkt_rel.first .. i_tbl_mkt_rel.last
                    LOOP
                        l_ds_internal_name := pk_orders_utils.get_ds_internal_name(i_tbl_mkt_rel(i));
                        l_id_ds_component  := pk_orders_utils.get_id_ds_component(i_tbl_mkt_rel(i));
                    
                        IF l_ds_internal_name = l_curr_comp_int_name
                        THEN
                        
                            l_flg_original_other := get_types_config_other(NULL,
                                                                           NULL,
                                                                           NULL,
                                                                           i_value(i) (1),
                                                                           i_prof,
                                                                           pk_prof_utils.get_prof_profile_template(i_prof),
                                                                           NULL);
                        
                            EXIT;
                        END IF;
                    END LOOP;
                
                    FOR i IN i_tbl_mkt_rel.first .. i_tbl_mkt_rel.last
                    LOOP
                        l_ds_internal_name := pk_orders_utils.get_ds_internal_name(i_tbl_mkt_rel(i));
                        l_id_ds_component  := pk_orders_utils.get_id_ds_component(i_tbl_mkt_rel(i));
                    
                        IF l_ds_internal_name = 'DS_ORIGINAL_STAYS_WITH_OTHER'
                        THEN
                        
                            tbl_result.extend();
                            tbl_result(tbl_result.count) := t_rec_ds_get_value(id_ds_cmpt_mkt_rel => i_tbl_mkt_rel(i),
                                                                               id_ds_component    => l_id_ds_component,
                                                                               internal_name      => l_ds_internal_name,
                                                                               VALUE              => i_value(i) (1),
                                                                               value_clob         => NULL,
                                                                               min_value          => NULL,
                                                                               max_value          => NULL,
                                                                               desc_value         => i_value(i) (1),
                                                                               desc_clob          => NULL,
                                                                               id_unit_measure    => NULL,
                                                                               desc_unit_measure  => NULL,
                                                                               flg_validation     => pk_alert_constant.g_yes,
                                                                               err_msg            => NULL,
                                                                               flg_event_type     => CASE
                                                                                                      l_flg_original_other
                                                                                                         WHEN
                                                                                                          pk_alert_constant.g_yes THEN
                                                                                                          'M'
                                                                                                         ELSE
                                                                                                          'I'
                                                                                                     END,
                                                                               flg_multi_status   => NULL,
                                                                               idx                => i_idx);
                        
                        END IF;
                    END LOOP;
                ELSIF l_curr_comp_int_name = 'DS_LANGUAGE'
                THEN
                    FOR i IN i_tbl_mkt_rel.first .. i_tbl_mkt_rel.last
                    LOOP
                        l_ds_internal_name := pk_orders_utils.get_ds_internal_name(i_tbl_mkt_rel(i));
                        l_id_ds_component  := pk_orders_utils.get_id_ds_component(i_tbl_mkt_rel(i));
                    
                        IF l_ds_internal_name = l_curr_comp_int_name
                        THEN
                            IF i_value(i) (1) = '-1'
                            THEN
                                l_flg_other_language := pk_alert_constant.g_yes;
                            END IF;
                        END IF;
                    END LOOP;
                
                    FOR i IN i_tbl_mkt_rel.first .. i_tbl_mkt_rel.last
                    LOOP
                        l_ds_internal_name := pk_orders_utils.get_ds_internal_name(i_tbl_mkt_rel(i));
                        l_id_ds_component  := pk_orders_utils.get_id_ds_component(i_tbl_mkt_rel(i));
                    
                        IF l_ds_internal_name = 'DS_LANGUAGE_OTHER'
                        THEN
                        
                            tbl_result.extend();
                            tbl_result(tbl_result.count) := t_rec_ds_get_value(id_ds_cmpt_mkt_rel => i_tbl_mkt_rel(i),
                                                                               id_ds_component    => l_id_ds_component,
                                                                               internal_name      => l_ds_internal_name,
                                                                               VALUE              => i_value(i) (1),
                                                                               value_clob         => NULL,
                                                                               min_value          => NULL,
                                                                               max_value          => NULL,
                                                                               desc_value         => i_value(i) (1),
                                                                               desc_clob          => NULL,
                                                                               id_unit_measure    => NULL,
                                                                               desc_unit_measure  => NULL,
                                                                               flg_validation     => pk_alert_constant.g_yes,
                                                                               err_msg            => NULL,
                                                                               flg_event_type     => CASE
                                                                                                      l_flg_other_language
                                                                                                         WHEN
                                                                                                          pk_alert_constant.g_yes THEN
                                                                                                          'M'
                                                                                                         ELSE
                                                                                                          'I'
                                                                                                     END,
                                                                               flg_multi_status   => NULL,
                                                                               idx                => i_idx);
                        
                        END IF;
                    END LOOP;
                END IF;
            END IF;
        ELSE
            --EDIÇÃO        
            SELECT t.title,
                   t.id_doc_ori_type,
                   t.orig_type,
                   t.num_doc,
                   t.dt_doc_ymd,
                   t.dt_exp_ymd,
                   t.id_specialty,
                   t.desc_specialty,
                   t.author,
                   t.desc_perf_by,
                   t.id_doc_original,
                   decode(t.flg_other_original,
                          pk_alert_constant.g_no,
                          t.desc_doc_original,
                          pk_message.get_message(i_lang, 'COMMON_M042')),
                   t.flg_other_original,
                   decode(t.flg_other_original, pk_alert_constant.g_yes, t.desc_doc_original, NULL),
                   t.id_doc_destination,
                   decode(t.flg_other_destination,
                          pk_alert_constant.g_no,
                          t.orig_dest,
                          pk_message.get_message(i_lang, 'COMMON_M042')),
                   t.flg_other_destination,
                   decode(t.flg_other_destination, pk_alert_constant.g_yes, t.orig_dest, NULL),
                   t.id_language,
                   t.desc_language,
                   t.notes,
                   t.flg_sent_by,
                   t.desc_sent_by,
                   t.desc_language_other
              INTO l_title,
                   l_id_category,
                   l_category_desc,
                   l_document_number,
                   l_dt_document,
                   l_dt_expire,
                   l_id_specialty,
                   l_specialty_desc,
                   l_author,
                   l_performed_by,
                   l_id_original_type,
                   l_original_type_desc,
                   l_flg_original_other,
                   l_original_type_desc_other,
                   l_id_original_with,
                   l_original_with_desc,
                   l_flg_original_stays_other,
                   l_original_stays_desc_other,
                   l_id_language,
                   l_language_desc,
                   l_notes,
                   l_flg_sent_by,
                   l_sent_by_desc,
                   l_desc_language_other
              FROM (WITH doc_info AS (SELECT ode.id_doc_external old_id,
                                             nde.id_doc_external new_id,
                                             nvl(dc.num_docs, 0) num_notes
                                        FROM doc_external ode,
                                             doc_external nde,
                                             (SELECT COUNT(doc.id_doc_external) num_docs, doc.id_doc_external
                                                FROM doc_comments doc
                                               GROUP BY doc.id_doc_external) dc
                                       WHERE ode.id_doc_external = i_tbl_id_pk(i_idx)
                                         AND dc.id_doc_external(+) = nde.id_doc_external
                                         AND ((ode.id_grupo IS NOT NULL AND ode.id_grupo = nde.id_grupo AND
                                             nde.flg_status IN (g_doc_active, g_doc_inactive, g_doc_pendente)) OR
                                             (ode.id_doc_external = nde.id_doc_external AND
                                             ode.flg_status IN (g_doc_active, g_doc_inactive, g_doc_pendente))))
                       SELECT de.num_doc,
                              de.title,
                              de.desc_perf_by,
                              pk_date_utils.date_send(i_lang, de.dt_emited, i_prof) dt_doc_ymd,
                              pk_date_utils.date_send(i_lang, de.dt_expire, i_prof) dt_exp_ymd,
                              de.id_doc_destination,
                              decode(de.desc_doc_destination,
                                     NULL,
                                     pk_translation.get_translation(i_lang, dd.code_doc_destination),
                                     de.desc_doc_destination) orig_dest,
                              de.id_doc_ori_type,
                              decode(de.desc_doc_ori_type,
                                     NULL,
                                     pk_translation.get_translation(i_lang, dot.code_doc_ori_type),
                                     de.desc_doc_ori_type) orig_type,
                              de.flg_sent_by,
                              pk_sysdomain.get_domain('DOC_EXTERNAL.FLG_SENT_BY', de.flg_sent_by, i_lang) desc_sent_by,
                              de.id_doc_original,
                              decode(de.desc_doc_original,
                                     NULL,
                                     pk_translation.get_translation(i_lang, do.code_doc_original),
                                     de.desc_doc_original) desc_doc_original,
                              de.author,
                              de.id_specialty,
                              pk_translation.get_translation(i_lang, s.code_speciality) desc_specialty,
                              de.id_language,
                              pk_translation.get_translation(i_lang, l.code_iso_lang) desc_language,
                              dcm.desc_comment notes,
                              --'Other' control
                              decode(de.id_doc_original,
                                     NULL,
                                     pk_alert_constant.g_no,
                                     get_types_config_other(NULL,
                                                            NULL,
                                                            de.id_doc_original,
                                                            NULL,
                                                            i_prof,
                                                            pk_prof_utils.get_prof_profile_template(i_prof),
                                                            NULL)) flg_other_original,
                              decode(dd.id_doc_destination,
                                     NULL,
                                     pk_alert_constant.g_no,
                                     get_types_config_other(NULL,
                                                            NULL,
                                                            NULL,
                                                            dd.id_doc_destination,
                                                            i_prof,
                                                            pk_prof_utils.get_prof_profile_template(i_prof),
                                                            NULL)) flg_other_destination,
                              de.desc_language desc_language_other
                         FROM doc_destination         dd,
                              doc_ori_type            dot,
                              doc_external            de,
                              doc_original            do,
                              speciality              s,
                              iso_lang                l,
                              xds_document_submission xds,
                              doc_info,
                              doc_comments            dcm
                        WHERE de.id_doc_external IN (doc_info.new_id)
                          AND dd.id_doc_destination(+) = de.id_doc_destination
                          AND dot.id_doc_ori_type = de.id_doc_ori_type
                          AND do.id_doc_original(+) = de.id_doc_original
                          AND de.id_doc_external = dcm.id_doc_external(+)
                             --
                          AND s.id_speciality(+) = de.id_specialty
                          AND de.id_language = l.id_iso_lang(+)
                          AND nvl(de.id_grupo, de.id_doc_external) = xds.id_doc_external(+)
                          AND nvl(xds.flg_status, g_doc_active) = pk_alert_constant.g_active) t
                        WHERE rownum = 1;
        
        
            FOR i IN i_tbl_mkt_rel.first .. i_tbl_mkt_rel.last
            LOOP
                l_ds_internal_name := pk_orders_utils.get_ds_internal_name(i_tbl_mkt_rel(i));
                l_id_ds_component  := pk_orders_utils.get_id_ds_component(i_tbl_mkt_rel(i));
            
                IF l_ds_internal_name IN ('DS_DOCUMENT_NAME',
                                          'DS_CATEGORY',
                                          'DS_DOCUMENT_NUMBER',
                                          'DS_DT_DOCUMENT',
                                          'DS_DT_DOCUMENT_EXPIRE',
                                          'DS_SPECIALTY',
                                          'DS_PROFESSIONAL',
                                          'DS_PERFORMED_BY',
                                          'DS_ORIGINAL_TYPE',
                                          'DS_ORIGINAL_OTHER',
                                          'DS_ORIGINAL_STAYS_WITH',
                                          'DS_ORIGINAL_STAYS_WITH_OTHER',
                                          'DS_LANGUAGE',
                                          'DS_NOTES',
                                          'DS_SENT_BY',
                                          'DS_LANGUAGE_OTHER',
                                          'DS_ID_DOC_EXTERNAL')
                THEN
                    tbl_result.extend();
                    tbl_result(tbl_result.count) := t_rec_ds_get_value(id_ds_cmpt_mkt_rel => i_tbl_mkt_rel(i),
                                                                       id_ds_component    => l_id_ds_component,
                                                                       internal_name      => l_ds_internal_name,
                                                                       VALUE              => CASE l_ds_internal_name
                                                                                                 WHEN 'DS_DOCUMENT_NAME' THEN
                                                                                                  l_title
                                                                                                 WHEN 'DS_CATEGORY' THEN
                                                                                                  to_char(l_id_category)
                                                                                                 WHEN 'DS_DOCUMENT_NUMBER' THEN
                                                                                                  l_document_number
                                                                                                 WHEN 'DS_DT_DOCUMENT' THEN
                                                                                                  l_dt_document
                                                                                                 WHEN 'DS_DT_DOCUMENT_EXPIRE' THEN
                                                                                                  l_dt_expire
                                                                                                 WHEN 'DS_SPECIALTY' THEN
                                                                                                  to_char(l_id_specialty)
                                                                                                 WHEN 'DS_PROFESSIONAL' THEN
                                                                                                  l_author
                                                                                                 WHEN 'DS_PERFORMED_BY' THEN
                                                                                                  l_performed_by
                                                                                                 WHEN 'DS_ORIGINAL_TYPE' THEN
                                                                                                  to_char(l_id_original_type)
                                                                                                 WHEN 'DS_ORIGINAL_OTHER' THEN
                                                                                                  to_char(l_original_type_desc_other)
                                                                                                 WHEN 'DS_ORIGINAL_STAYS_WITH' THEN
                                                                                                  to_char(l_id_original_with)
                                                                                                 WHEN 'DS_ORIGINAL_STAYS_WITH_OTHER' THEN
                                                                                                  l_original_stays_desc_other
                                                                                                 WHEN 'DS_LANGUAGE' THEN
                                                                                                  to_char(l_id_language)
                                                                                                 WHEN 'DS_NOTES' THEN
                                                                                                  l_notes
                                                                                                 WHEN 'DS_SENT_BY' THEN
                                                                                                  l_flg_sent_by
                                                                                                 WHEN 'DS_LANGUAGE_OTHER' THEN
                                                                                                  l_desc_language_other
                                                                                                 WHEN 'DS_ID_DOC_EXTERNAL' THEN
                                                                                                  to_char(i_tbl_id_pk(1))
                                                                                             END,
                                                                       value_clob         => NULL,
                                                                       min_value          => NULL,
                                                                       max_value          => NULL,
                                                                       desc_value         => CASE l_ds_internal_name
                                                                                                 WHEN 'DS_DOCUMENT_NAME' THEN
                                                                                                  l_title
                                                                                                 WHEN 'DS_CATEGORY' THEN
                                                                                                  l_category_desc
                                                                                                 WHEN 'DS_DOCUMENT_NUMBER' THEN
                                                                                                  l_document_number
                                                                                                 WHEN 'DS_SPECIALTY' THEN
                                                                                                  l_specialty_desc
                                                                                                 WHEN 'DS_PROFESSIONAL' THEN
                                                                                                  l_author
                                                                                                 WHEN 'DS_PERFORMED_BY' THEN
                                                                                                  l_performed_by
                                                                                                 WHEN 'DS_ORIGINAL_TYPE' THEN
                                                                                                  l_original_type_desc
                                                                                                 WHEN 'DS_ORIGINAL_OTHER' THEN
                                                                                                  l_original_type_desc_other
                                                                                                 WHEN 'DS_ORIGINAL_STAYS_WITH' THEN
                                                                                                  l_original_with_desc
                                                                                                 WHEN 'DS_ORIGINAL_STAYS_WITH_OTHER' THEN
                                                                                                  l_original_stays_desc_other
                                                                                                 WHEN 'DS_LANGUAGE' THEN
                                                                                                  l_language_desc
                                                                                                 WHEN 'DS_NOTES' THEN
                                                                                                  l_notes
                                                                                                 WHEN 'DS_SENT_BY' THEN
                                                                                                  l_sent_by_desc
                                                                                                 WHEN 'DS_LANGUAGE_OTHER' THEN
                                                                                                  l_desc_language_other
                                                                                             END,
                                                                       desc_clob          => NULL,
                                                                       id_unit_measure    => NULL,
                                                                       desc_unit_measure  => NULL,
                                                                       flg_validation     => pk_alert_constant.g_yes,
                                                                       err_msg            => NULL,
                                                                       flg_event_type     => CASE l_ds_internal_name
                                                                                                 WHEN 'DS_DOCUMENT_NAME' THEN
                                                                                                  'M'
                                                                                                 WHEN 'DS_CATEGORY' THEN
                                                                                                  'M'
                                                                                                 WHEN 'DS_PROFESSIONAL' THEN
                                                                                                  'R'
                                                                                                 WHEN 'DS_ORIGINAL_OTHER' THEN
                                                                                                  CASE
                                                                                                      WHEN l_flg_original_other = pk_alert_constant.g_yes THEN
                                                                                                       'M'
                                                                                                      ELSE
                                                                                                       'I'
                                                                                                  END
                                                                                                 WHEN 'DS_LANGUAGE_OTHER' THEN
                                                                                                  CASE
                                                                                                      WHEN l_desc_language_other IS NOT NULL THEN
                                                                                                       'M'
                                                                                                      ELSE
                                                                                                       'I'
                                                                                                  END
                                                                                                 WHEN 'DS_ORIGINAL_STAYS_WITH_OTHER' THEN
                                                                                                  CASE
                                                                                                      WHEN l_flg_original_stays_other = pk_alert_constant.g_yes THEN
                                                                                                       'M'
                                                                                                      ELSE
                                                                                                       'I'
                                                                                                  END
                                                                                                 WHEN 'DS_SENT_BY' THEN
                                                                                                  CASE
                                                                                                      WHEN l_flg_sent_by IS NOT NULL THEN
                                                                                                       'R'
                                                                                                      ELSE
                                                                                                       'I'
                                                                                                  END
                                                                                                 ELSE
                                                                                                  'A'
                                                                                             END,
                                                                       flg_multi_status   => NULL,
                                                                       idx                => i_idx);
                END IF;
            END LOOP;
        END IF;
    
        RETURN tbl_result;
    
    END get_doc_archive_values;

BEGIN

    pk_alertlog.who_am_i(owner => g_package_owner, name => g_package_name);

    pk_alertlog.log_init(owner => g_package_owner, object_name => g_package_name);

    g_yes := 'Y';
    g_no  := 'N';

    g_flg_img_thumbnail_n := 'N';

    g_flg_type_d := 'D';
    g_flg_type_i := 'I';

    g_flg_cancel_y := 'Y';
    g_flg_cancel_n := 'N';

    g_doc_type_available_y        := 'Y';
    g_doc_ori_type_available_y    := 'Y';
    g_doc_original_available_y    := 'Y';
    g_doc_destination_available_y := 'Y';

    -- g_flg_type_image := 'I';
    -- g_flg_type_doc   := 'D';

    g_epis_flg_status_canc := 'C';

    g_flg_comm_type_i := 'I';
    g_flg_comm_type_n := 'N';

    g_doc_ori_type_identific_y := 'Y';

END pk_doc;
/
