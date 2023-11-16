/*-- Last Change Revision: $Rev: 2055616 $*/
/*-- Last Change by: $Author: pedro.henriques $*/
/*-- Date of last change: $Date: 2023-02-22 15:27:24 +0000 (qua, 22 fev 2023) $*/

CREATE OR REPLACE PACKAGE BODY pk_blood_products_utils IS

    FUNCTION get_bp_status_to_update
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_blood_product_req IN blood_product_det.id_blood_product_req%TYPE,
        o_status            OUT blood_product_req.flg_status%TYPE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_count                NUMBER := 0;
        l_id_blood_product_det blood_product_det.id_blood_product_det%TYPE;
    
    BEGIN
    
        --Checks the number of tasks that are not yet cancelled/discontinued/finalized/returned
        SELECT COUNT(*)
          INTO l_count
          FROM blood_product_det bpd
         WHERE bpd.id_blood_product_req = i_blood_product_req
           AND bpd.flg_status NOT IN (pk_blood_products_constant.g_status_det_h,
                                      pk_blood_products_constant.g_status_det_c,
                                      pk_blood_products_constant.g_status_det_d,
                                      pk_blood_products_constant.g_status_det_f,
                                      pk_blood_products_constant.g_status_det_br,
                                      pk_blood_products_constant.g_status_det_wr,
                                      pk_blood_products_constant.g_status_det_cr);
    
        --If there are tasks with the mentioned statuses, REQ status should not be updated
        --RETURN FALSE => Req should not be updated
        --RETURN TRUE => Req should be updated
        IF l_count > 0
        THEN
            RETURN FALSE;
        ELSE
            SELECT COUNT(*)
              INTO l_count
              FROM blood_product_det bpd
             WHERE bpd.id_blood_product_req = i_blood_product_req;
        
            IF l_count = 1
            THEN
            
                SELECT bpd.id_blood_product_det
                  INTO l_id_blood_product_det
                  FROM blood_product_det bpd
                 WHERE bpd.id_blood_product_req = i_blood_product_req;
            
                SELECT decode(bpd.flg_status,
                              pk_blood_products_constant.g_status_det_br,
                              pk_blood_products_constant.g_status_det_f,
                              pk_blood_products_constant.g_status_det_cr,
                              get_returned_bag_status(i_lang, i_prof, l_id_blood_product_det),
                              --pk_blood_products_constant.g_status_req_d,
                              bpd.flg_status)
                  INTO o_status
                  FROM blood_product_det bpd
                 WHERE bpd.id_blood_product_req = i_blood_product_req;
            ELSE
                --verificar precedência
                SELECT decode(t.flg_status,
                              pk_blood_products_constant.g_status_det_br,
                              pk_blood_products_constant.g_status_det_f,
                              pk_blood_products_constant.g_status_det_cr,
                              get_returned_bag_status(i_lang, i_prof, t.id_blood_product_det),
                              -- pk_blood_products_constant.g_status_req_d,
                              t.flg_status)
                  INTO o_status
                  FROM (SELECT DISTINCT bpd.flg_status,
                                        CASE bpd.flg_status
                                            WHEN pk_blood_products_constant.g_status_det_wr THEN
                                             10
                                            WHEN pk_blood_products_constant.g_status_det_h THEN
                                             20
                                            WHEN pk_blood_products_constant.g_status_det_br THEN
                                             30
                                            WHEN pk_blood_products_constant.g_status_det_cr THEN
                                             40
                                            WHEN pk_blood_products_constant.g_status_det_f THEN
                                             50
                                            WHEN pk_blood_products_constant.g_status_det_d THEN
                                             60
                                            WHEN pk_blood_products_constant.g_status_det_c THEN
                                             70
                                            ELSE
                                             100
                                        END rank,
                                        bpd.id_blood_product_det
                          FROM blood_product_det bpd
                         WHERE bpd.id_blood_product_req = i_blood_product_req
                         ORDER BY rank ASC) t
                 WHERE rownum = 1;
            END IF;
        
            RETURN TRUE;
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_BP_STATUS_TO_UPDATE',
                                              o_error);
            RETURN FALSE;
    END get_bp_status_to_update;

    FUNCTION get_bp_questionnaire_rank
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_hemo_type  IN hemo_type.id_hemo_type%TYPE,
        i_questionnaire IN questionnaire.id_questionnaire%TYPE,
        i_flg_time      IN interv_questionnaire.flg_time%TYPE
    ) RETURN NUMBER IS
    
        l_rank NUMBER;
    
    BEGIN
    
        g_error := 'SELECT BP_QUESTIONNAIRE';
        SELECT MAX(bq.rank)
          INTO l_rank
          FROM bp_questionnaire bq
         WHERE bq.id_hemo_type = i_id_hemo_type
           AND bq.id_questionnaire = i_questionnaire
           AND bq.flg_time = i_flg_time
           AND bq.id_institution = i_prof.institution
           AND bq.flg_available = pk_alert_constant.g_available;
    
        RETURN l_rank;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_bp_questionnaire_rank;

    FUNCTION get_questionnaire_id_content
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_questionnaire IN questionnaire.id_questionnaire%TYPE,
        i_response      IN response.id_response%TYPE
    ) RETURN VARCHAR2 IS
    
        l_content VARCHAR2(200 CHAR);
    
    BEGIN
    
        IF i_response IS NOT NULL
        THEN
            g_error := 'SELECT QUESTIONNAIRE_RESPONSE';
            SELECT id_content
              INTO l_content
              FROM questionnaire_response qr
             WHERE qr.id_questionnaire = i_questionnaire
               AND qr.id_response = i_response
               AND qr.flg_available = pk_alert_constant.g_yes;
        ELSE
            g_error := 'SELECT QUESTIONNAIRE';
            SELECT id_content
              INTO l_content
              FROM questionnaire q
             WHERE q.id_questionnaire = i_questionnaire
               AND q.flg_available = pk_alert_constant.g_yes;
        END IF;
    
        RETURN l_content;
    
    EXCEPTION
        WHEN no_data_found THEN
            RETURN NULL;
    END get_questionnaire_id_content;

    PROCEDURE get_bp_init_parameters
    (
        i_filter_name   IN VARCHAR2,
        i_custom_filter IN NUMBER,
        i_context_ids   IN table_number,
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
    
        l_prof    CONSTANT profissional := profissional(i_context_ids(g_prof_id),
                                                        i_context_ids(g_prof_institution),
                                                        i_context_ids(g_prof_software));
        l_lang    CONSTANT language.id_language%TYPE := i_context_ids(g_lang);
        l_patient CONSTANT patient.id_patient%TYPE := i_context_ids(g_patient);
        l_episode CONSTANT episode.id_episode%TYPE := i_context_ids(g_episode);
    
        l_prof_profile_templ profile_template.id_profile_template%TYPE;
        l_prof_cat           category.id_category%TYPE;
    
        l_error  t_error_out;
        l_test   VARCHAR2(0010 CHAR);
        l_bp_req blood_product_req.id_blood_product_req%TYPE;
        l_market market.id_market%TYPE;
    
        l_limit sys_config.id_sys_config%TYPE := pk_sysconfig.get_config(i_prof    => l_prof,
                                                                         i_code_cf => 'BLOOD_TRANSFUSION_TIME_LIMIT');
    
    BEGIN
    
        pk_context_api.set_parameter('i_lang', l_lang);
        pk_context_api.set_parameter('i_prof_id', l_prof.id);
        pk_context_api.set_parameter('i_prof_institution', l_prof.institution);
        pk_context_api.set_parameter('i_prof_software', l_prof.software);
    
        pk_context_api.set_parameter('i_patient', l_patient);
        pk_context_api.set_parameter('i_episode', l_episode);
        pk_context_api.set_parameter('l_limit', l_limit);
    
        l_prof_profile_templ := pk_prof_utils.get_prof_profile_template(i_prof => l_prof);
        l_prof_cat           := pk_prof_utils.get_id_category(i_lang => l_lang, i_prof => l_prof);
        l_market             := pk_utils.get_institution_market(i_lang           => l_lang,
                                                                i_id_institution => l_prof.institution);
    
        pk_context_api.set_parameter('l_prof_cat', l_prof_cat);
    
        IF i_context_vals IS NOT NULL
           AND i_context_vals.count > 0
        THEN
            l_bp_req := to_number(i_context_vals(1));
            pk_context_api.set_parameter('i_bp_req', 'Y');
        
            IF i_context_vals.count > 1
            THEN
                IF i_context_vals(2) = 'BEGIN_TRANSP'
                THEN
                    IF l_market = pk_alert_constant.g_id_market_sa
                    THEN
                        IF i_context_vals.exists(3)
                        THEN
                            IF i_context_vals(3) IN ('RW', 'WT', 'OT', 'CT')
                            THEN
                                IF l_prof_cat = 2
                                THEN
                                    pk_context_api.set_parameter('i_scenario', 1);
                                ELSIF l_prof_profile_templ = 47
                                THEN
                                    pk_context_api.set_parameter('i_scenario', 2);
                                ELSIF l_prof_profile_templ = 22
                                THEN
                                    pk_context_api.set_parameter('i_scenario', 3);
                                ELSE
                                    pk_context_api.set_parameter('i_scenario', 2);
                                END IF;
                            ELSE
                                IF l_prof_cat = 2
                                THEN
                                    pk_context_api.set_parameter('i_scenario', 4);
                                ELSE
                                    pk_context_api.set_parameter('i_scenario', 3);
                                END IF;
                            END IF;
                        ELSE
                            IF l_prof_cat = 2
                            THEN
                                pk_context_api.set_parameter('i_scenario', 4);
                            ELSE
                                pk_context_api.set_parameter('i_scenario', 3);
                            END IF;
                        END IF;
                    ELSE
                        pk_context_api.set_parameter('i_scenario', 5);
                        pk_context_api.set_parameter('i_tecnician', pk_alert_constant.g_yes);
                    END IF;
                ELSE
                    IF l_market = pk_alert_constant.g_id_market_sa
                    THEN
                        IF i_context_vals.exists(3)
                        THEN
                            IF i_context_vals(3) IN ('RW', 'WT', 'OT', 'CT')
                            THEN
                                IF l_prof_cat = 2
                                THEN
                                    pk_context_api.set_parameter('i_scenario', 4);
                                ELSE
                                    pk_context_api.set_parameter('i_scenario', 3);
                                END IF;
                            ELSE
                                IF l_prof_cat = 2
                                   AND i_context_vals(3) IN ('RT', 'OR')
                                THEN
                                    pk_context_api.set_parameter('i_scenario', 4);
                                ELSIF l_prof_cat = 2
                                THEN
                                    pk_context_api.set_parameter('i_scenario', 1);
                                ELSIF l_prof_profile_templ = 47
                                THEN
                                    pk_context_api.set_parameter('i_scenario', 2);
                                ELSIF l_prof_profile_templ = 22
                                THEN
                                    pk_context_api.set_parameter('i_scenario', 3);
                                ELSIF i_context_vals(3) = 'RT'
                                THEN
                                    pk_context_api.set_parameter('i_scenario', 2);
                                ELSE
                                    pk_context_api.set_parameter('i_scenario', 3);
                                END IF;
                            END IF;
                        ELSE
                            IF l_prof_cat = 2
                            THEN
                                pk_context_api.set_parameter('i_scenario', 1);
                            ELSIF l_prof_profile_templ = 47
                            THEN
                                pk_context_api.set_parameter('i_scenario', 2);
                            ELSIF l_prof_profile_templ = 22
                            THEN
                                pk_context_api.set_parameter('i_scenario', 3);
                            ELSE
                                pk_context_api.set_parameter('i_scenario', 2);
                            END IF;
                        END IF;
                    ELSE
                        pk_context_api.set_parameter('i_scenario', 5);
                        pk_context_api.set_parameter('i_tecnician', pk_alert_constant.g_no);
                    END IF;
                
                END IF;
            END IF;
        ELSE
            pk_context_api.set_parameter('i_bp_req', 'N');
            pk_context_api.set_parameter('i_tecnician', pk_alert_constant.g_no);
            IF l_prof_cat = 2
            THEN
                pk_context_api.set_parameter('i_scenario', 4);
            ELSE
                pk_context_api.set_parameter('i_scenario', 5);
            END IF;
        END IF;
    
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
            WHEN 'i_blood_product_req' THEN
                o_vc2 := l_bp_req;
            WHEN 'l_visit' THEN
                o_id := pk_visit.get_visit(l_episode, l_error);
            WHEN 'g_bp_button_ok' THEN
                o_vc2 := pk_procedures_constant.g_interv_button_ok;
            WHEN 'g_bp_button_cancel' THEN
                o_vc2 := pk_procedures_constant.g_interv_button_cancel;
            WHEN 'g_bp_button_action' THEN
                o_vc2 := pk_procedures_constant.g_interv_button_action;
            WHEN 'g_bp_button_edit' THEN
                o_vc2 := pk_procedures_constant.g_interv_button_edit;
            WHEN 'g_bp_button_confirm' THEN
                o_vc2 := pk_procedures_constant.g_interv_button_confirmation;
        END CASE;
    END get_bp_init_parameters;

    FUNCTION get_bp_permission
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_button              IN VARCHAR2,
        i_episode             IN episode.id_episode%TYPE,
        i_blood_product_det   IN blood_product_det.id_blood_product_det%TYPE,
        i_flg_current_episode IN VARCHAR2
    ) RETURN VARCHAR2 IS
    
    BEGIN
    
        RETURN pk_alert_constant.g_yes;
    
    END get_bp_permission;

    FUNCTION get_bp_diagnosis
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_diagnosis_list IN interv_presc_det_hist.id_diagnosis_list%TYPE
    ) RETURN VARCHAR2 IS
    
        CURSOR c_diagnosis_list IS
            SELECT pk_diagnosis.get_mcdt_description(i_lang, i_prof, t.id_diagnosis_list) desc_diagnosis
              FROM (SELECT column_value id_diagnosis_list
                      FROM TABLE(CAST(pk_utils.str_split(i_diagnosis_list, ';') AS table_varchar2))) t;
    
        l_diagnosis_list c_diagnosis_list%ROWTYPE;
    
        l_diagnosis_desc VARCHAR2(4000);
    
    BEGIN
    
        FOR l_diagnosis_list IN c_diagnosis_list
        LOOP
            IF l_diagnosis_desc IS NULL
            THEN
                l_diagnosis_desc := l_diagnosis_list.desc_diagnosis;
            ELSE
                l_diagnosis_desc := l_diagnosis_desc || ', ' || l_diagnosis_list.desc_diagnosis;
            END IF;
        END LOOP;
    
        RETURN l_diagnosis_desc;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_bp_diagnosis;

    FUNCTION get_bp_icon
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_blood_product_det IN blood_product_det.id_blood_product_det%TYPE
    ) RETURN VARCHAR2 IS
    
        l_icon_name VARCHAR2(200 CHAR);
    
    BEGIN
    
        IF i_blood_product_det IS NULL
        THEN
            l_icon_name := NULL;
        ELSE
            g_error := 'GET ORDER_RECURRENCE';
            SELECT decode(bpd.id_order_recurrence, NULL, pk_alert_constant.g_no, pk_alert_constant.g_yes)
              INTO l_icon_name
              FROM blood_product_det bpd
             WHERE bpd.id_blood_product_det = i_blood_product_det;
        END IF;
    
        RETURN l_icon_name;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_bp_icon;

    FUNCTION get_status_string
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_episode   IN episode.id_episode%TYPE,
        i_bp_det    IN blood_product_det.id_blood_product_det%TYPE,
        i_force_anc IN VARCHAR2 DEFAULT pk_alert_constant.g_no
    ) RETURN VARCHAR2 IS
    
        l_status_string        VARCHAR2(200 CHAR);
        l_status_flg           VARCHAR2(200 CHAR);
        l_status_flg_aux       VARCHAR2(200 CHAR);
        l_status_icon          VARCHAR2(200 CHAR);
        l_status_msg           VARCHAR2(200 CHAR);
        l_status_str           VARCHAR2(200 CHAR);
        l_flg_time             blood_product_req.flg_time%TYPE;
        l_dt_begin             blood_product_req.dt_begin_tstz%TYPE;
        l_flg_status           blood_product_det.flg_status%TYPE;
        l_dt_blood_product     blood_product_det.dt_blood_product_det%TYPE;
        l_id_blood_product_req blood_product_req.id_blood_product_req%TYPE;
    
        l_limit sys_config.id_sys_config%TYPE := pk_sysconfig.get_config(i_prof    => i_prof,
                                                                         i_code_cf => 'BLOOD_TRANSFUSION_TIME_LIMIT');
    BEGIN
    
        SELECT bpd.flg_status,
               bpd.dt_blood_product_det,
               bpr.flg_time,
               coalesce(bpe2.dt_execution, bpe.dt_execution, bpd.dt_begin_tstz),
               bpr.id_blood_product_req
          INTO l_flg_status, l_dt_blood_product, l_flg_time, l_dt_begin, l_id_blood_product_req
          FROM blood_product_det bpd
          JOIN blood_product_req bpr
            ON bpd.id_blood_product_req = bpr.id_blood_product_req
          LEFT JOIN (SELECT *
                       FROM (SELECT bpe0.*,
                                    row_number() over(PARTITION BY bpe0.id_blood_product_det ORDER BY bpe0.dt_execution DESC) rn
                               FROM blood_product_execution bpe0
                              WHERE bpe0.id_blood_product_det = i_bp_det
                                AND bpe0.action = pk_blood_products_constant.g_bp_action_lab_collected
                              ORDER BY bpe0.dt_execution DESC)
                      WHERE rn = 1) bpe2
            ON bpe2.id_blood_product_det = bpd.id_blood_product_det
          LEFT JOIN blood_product_execution bpe
            ON bpe.id_blood_product_det = bpd.id_blood_product_det
           AND bpe.action = pk_blood_products_constant.g_bp_action_lab_service
         WHERE bpd.id_blood_product_det = i_bp_det;
    
        l_status_flg_aux := get_bp_unsafe_status(i_lang              => i_lang,
                                                 i_prof              => i_prof,
                                                 i_blood_product_req => l_id_blood_product_req,
                                                 i_blood_product_det => i_bp_det,
                                                 i_limit             => l_limit);
    
        pk_ea_logic_blood_products.get_bp_status(i_lang                => i_lang,
                                                 i_prof                => i_prof,
                                                 i_episode             => i_episode,
                                                 i_flg_time            => l_flg_time,
                                                 i_flg_status_det      => coalesce(l_status_flg_aux, l_flg_status),
                                                 i_dt_blood_product    => l_dt_blood_product,
                                                 i_dt_begin_req        => l_dt_begin,
                                                 i_order_recurr_option => NULL,
                                                 i_force_anc           => i_force_anc,
                                                 o_status_str          => l_status_str,
                                                 o_status_msg          => l_status_msg,
                                                 o_status_icon         => l_status_icon,
                                                 o_status_flg          => l_status_flg);
    
        l_status_string := pk_utils.get_status_string(i_lang        => i_lang,
                                                      i_prof        => i_prof,
                                                      i_status_str  => l_status_str,
                                                      i_status_msg  => l_status_msg,
                                                      i_status_icon => l_status_icon,
                                                      i_status_flg  => l_status_flg) || CASE
                               WHEN l_status_flg_aux IS NOT NULL THEN
                               --Add label of no longer safe.
                                pk_message.get_message(i_lang, 'BLOOD_PRODUCTS_T134')
                           END;
    
        RETURN l_status_string;
    
    END get_status_string;

    FUNCTION get_bp_number_bags
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_quantity        IN blood_product_det.qty_exec%TYPE,
        i_id_unit_measure IN blood_product_det.id_unit_mea_qty_exec%TYPE
    ) RETURN NUMBER IS
    
        l_volume_default sys_config.value%TYPE := pk_sysconfig.get_config('BLOOD_PRODUCT_UNIT_VOL', i_prof);
        l_qty_exec       blood_product_det.qty_exec%TYPE;
    
    BEGIN
    
        IF i_id_unit_measure = pk_blood_products_constant.g_bp_unit_ml
        THEN
            l_qty_exec := i_quantity / l_volume_default;
        ELSE
            l_qty_exec := i_quantity;
        END IF;
    
        RETURN l_qty_exec;
    
    END get_bp_number_bags;

    FUNCTION get_bp_quantity_desc
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_quantity        IN blood_product_det.qty_exec%TYPE,
        i_id_unit_measure IN blood_product_det.id_unit_mea_qty_exec%TYPE
    ) RETURN VARCHAR2 IS
    
        l_bag_volume_default sys_config.value%TYPE := pk_sysconfig.get_config('BLOOD_PRODUCT_UNIT_VOL', i_prof);
    
        l_volume_desc translation.desc_lang_1%TYPE := NULL;
        l_um_desc     translation.desc_lang_1%TYPE;
        l_um_desc_aux translation.desc_lang_1%TYPE;
    
    BEGIN
    
        IF i_id_unit_measure = pk_blood_products_constant.g_bp_unit_bag
        THEN
        
            SELECT pk_translation.get_translation(i_lang, um.code_unit_measure)
              INTO l_um_desc
              FROM unit_measure um
             WHERE um.id_unit_measure = i_id_unit_measure;
        
            SELECT pk_translation.get_translation(i_lang, um.code_unit_measure)
              INTO l_um_desc_aux
              FROM unit_measure um
             WHERE um.id_unit_measure = pk_blood_products_constant.g_bp_unit_ml;
        
            l_volume_desc := i_quantity || ' ' || l_um_desc || ' (' || i_quantity * l_bag_volume_default || ' ' ||
                             l_um_desc_aux || ')';
        
        ELSE
        
            SELECT pk_translation.get_translation(i_lang, um.code_unit_measure)
              INTO l_um_desc
              FROM unit_measure um
             WHERE um.id_unit_measure = i_id_unit_measure;
        
            l_volume_desc := i_quantity || ' ' || l_um_desc;
        
        END IF;
    
        RETURN l_volume_desc;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_bp_quantity_desc;

    FUNCTION get_bp_response
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_patient       IN patient.id_patient%TYPE,
        i_questionnaire IN questionnaire_response.id_questionnaire%TYPE,
        i_hemo_type     IN hemo_type.id_hemo_type%TYPE,
        i_flg_time      IN VARCHAR2
    ) RETURN table_varchar IS
    
        CURSOR c_patient IS
            SELECT gender, trunc(months_between(SYSDATE, dt_birth) / 12) age
              FROM patient
             WHERE id_patient = i_patient;
    
        l_patient c_patient%ROWTYPE;
    
        l_response table_varchar;
    
    BEGIN
    
        g_error := 'OPEN C_PATIENT';
        OPEN c_patient;
        FETCH c_patient
            INTO l_patient;
        CLOSE c_patient;
    
        g_error := 'SELECT QUESTIONNAIRE_RESPONSE';
        SELECT qr.id_response || '|' ||
               pk_mcdt.get_response_alias(i_lang, i_prof, 'RESPONSE.CODE_RESPONSE.' || qr.id_response) || '|' ||
               r.flg_free_text
          BULK COLLECT
          INTO l_response
          FROM questionnaire_response qr, response r
         WHERE qr.id_questionnaire = i_questionnaire
           AND qr.flg_available = pk_alert_constant.g_available
           AND qr.id_response = r.id_response
           AND r.flg_available = pk_alert_constant.g_available
           AND EXISTS (SELECT 1
                  FROM bp_questionnaire iq
                 WHERE iq.id_hemo_type = i_hemo_type
                   AND iq.flg_time = i_flg_time
                   AND iq.id_questionnaire = qr.id_questionnaire
                   AND iq.id_response = qr.id_response
                   AND iq.id_institution = i_prof.institution
                   AND iq.flg_available = pk_alert_constant.g_available)
           AND (((l_patient.gender IS NOT NULL AND
               coalesce(r.gender, 'I', 'U', 'N') IN ('I', 'U', 'N', l_patient.gender)) OR
               l_patient.gender IS NULL OR l_patient.gender IN ('I', 'U', 'N')) AND
               (nvl(l_patient.age, 0) BETWEEN nvl(r.age_min, 0) AND nvl(r.age_max, nvl(l_patient.age, 0)) OR
               nvl(l_patient.age, 0) = 0))
         ORDER BY qr.rank;
    
        RETURN l_response;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_bp_response;

    FUNCTION get_bp_response
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_notes IN interv_question_response.notes%TYPE
    ) RETURN bp_question_response.notes%TYPE IS
    
        l_ret bp_question_response.notes%TYPE;
    
    BEGIN
        -- Heuristic to minimize attempts to parse an invalid date
        IF dbms_lob.getlength(i_notes) = length('YYYYMMDDHHMMSS')
           AND pk_utils.is_number(char_in => i_notes) = pk_alert_constant.g_yes -- This is the size of a stored serialized date, not a mask (HH vs HH24).-- This is the size of a stored serialized date, not a mask (HH vs HH24).
        THEN
            -- We try to parse the note as a serialized date
            l_ret := pk_date_utils.dt_chr_str(i_lang     => i_lang,
                                              i_date     => i_notes,
                                              i_inst     => i_prof.institution,
                                              i_soft     => i_prof.software,
                                              i_timezone => NULL);
        ELSE
            l_ret := i_notes;
        END IF;
    
        RETURN l_ret;
    
    EXCEPTION
        WHEN OTHERS THEN
            -- Ignore parse errors and return original content
            RETURN i_notes;
    END get_bp_response;

    FUNCTION get_bp_episode_response
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_episode       IN episode.id_episode%TYPE,
        i_questionnaire IN bp_question_response.id_questionnaire%TYPE
    ) RETURN VARCHAR2 IS
    
        l_response VARCHAR2(1000 CHAR);
    
    BEGIN
    
        SELECT substr(concatenate(t.id_response || '|'), 1, length(concatenate(t.id_response || '|')) - 1)
          INTO l_response
          FROM (SELECT iqr.id_response,
                       dense_rank() over(PARTITION BY iqr.id_questionnaire ORDER BY iqr.dt_last_update_tstz DESC) rn
                  FROM bp_question_response iqr
                 WHERE iqr.id_episode = i_episode
                   AND iqr.id_questionnaire = i_questionnaire) t
         WHERE t.rn = 1;
    
        RETURN l_response;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_bp_episode_response;

    FUNCTION get_bp_pat_blood_group
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE
    ) RETURN VARCHAR IS
    
        l_pat_blood_group VARCHAR2(200);
    
    BEGIN
    
        SELECT *
          INTO l_pat_blood_group
          FROM (SELECT decode(p.flg_status,
                              pk_alert_constant.g_cancelled,
                              pk_sysdomain.get_domain('PAT_BLOOD_GROUP.FLG_BLOOD_GROUP', p.flg_blood_group, i_lang) ||
                              pk_message.get_message(i_lang, 'COMMON_M028'),
                              pk_sysdomain.get_domain('PAT_BLOOD_GROUP.FLG_BLOOD_GROUP', p.flg_blood_group, i_lang)) || ' ' ||
                       pk_sysdomain.get_domain('PAT_BLOOD_GROUP.FLG_BLOOD_RHESUS', p.flg_blood_rhesus, i_lang) blood_info
                  FROM pat_blood_group p, pat_blood_group p1
                 WHERE p.id_patient = i_id_patient
                   AND p1.id_patient = p.id_patient
                   AND (p1.dt_pat_blood_group_tstz = (SELECT MIN(dt_pat_blood_group_tstz)
                                                        FROM pat_blood_group
                                                       WHERE dt_pat_blood_group_tstz > p.dt_pat_blood_group_tstz
                                                         AND id_patient = p.id_patient) OR
                       (p1.dt_pat_blood_group_tstz = p.dt_pat_blood_group_tstz AND
                       p.flg_status = pk_alert_constant.g_active))
                 ORDER BY pk_sysdomain.get_rank(i_lang, 'PAT_BLOOD_GROUP.FLG_STATUS', p.flg_status),
                          p.dt_pat_blood_group_tstz DESC)
         WHERE rownum = 1;
    
        RETURN l_pat_blood_group;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_bp_pat_blood_group;

    FUNCTION get_bp_adverse_reaction_req
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_bp_req IN blood_product_req.id_blood_product_req%TYPE
    ) RETURN VARCHAR2 IS
    
        l_ret   VARCHAR2(1 CHAR);
        l_count NUMBER(24);
    
    BEGIN
    
        SELECT COUNT(*)
          INTO l_count
          FROM blood_product_det bpd
         WHERE bpd.id_blood_product_req = i_bp_req
           AND bpd.adverse_reaction = pk_alert_constant.g_yes;
    
        IF l_count > 0
        THEN
            l_ret := pk_alert_constant.g_yes;
        ELSE
            l_ret := pk_alert_constant.g_no;
        END IF;
    
        RETURN l_ret;
    
    END get_bp_adverse_reaction_req;

    FUNCTION get_bp_desc_hemo_type
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_blood_product_det IN blood_product_det.id_blood_product_det%TYPE,
        i_lab_hemo_type     IN VARCHAR2 DEFAULT pk_alert_constant.g_no
    ) RETURN VARCHAR2 IS
    
        l_hemo_type_desc VARCHAR2(200 CHAR);
    
    BEGIN
    
        SELECT CASE
                    WHEN i_lab_hemo_type = pk_alert_constant.g_yes THEN
                     nvl(bpd.desc_hemo_type_lab,
                         (SELECT pk_translation.get_translation(i_lang, ht.code_hemo_type)
                            FROM dual))
                    ELSE
                     (SELECT pk_translation.get_translation(i_lang, ht.code_hemo_type)
                        FROM dual)
                END desc_hemo_type
          INTO l_hemo_type_desc
          FROM blood_product_det bpd
          JOIN hemo_type ht
            ON ht.id_hemo_type = bpd.id_hemo_type
         WHERE bpd.id_blood_product_det = i_blood_product_det;
    
        RETURN l_hemo_type_desc;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_bp_desc_hemo_type;

    FUNCTION get_bp_compatibility
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_blood_product_det IN blood_product_det.id_blood_product_det%TYPE
    ) RETURN VARCHAR2 AS
        l_ret VARCHAR2(100 CHAR);
    BEGIN
    
        SELECT t.flg_compatibility
          INTO l_ret
          FROM (SELECT *
                  FROM blood_product_execution bpe
                 WHERE bpe.id_blood_product_det = i_blood_product_det
                   AND bpe.action = pk_blood_products_constant.g_bp_action_compability
                 ORDER BY bpe.exec_number DESC) t
         WHERE rownum = 1;
    
        RETURN l_ret;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_bp_compatibility;

    FUNCTION get_bp_compatibility_desc
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_blood_product_det IN blood_product_det.id_blood_product_det%TYPE,
        i_color             IN VARCHAR2 DEFAULT 'N'
    ) RETURN VARCHAR2 AS
        l_comp VARCHAR2(2 CHAR);
        l_ret  VARCHAR2(100 CHAR);
    BEGIN
    
        SELECT t.flg_compatibility
          INTO l_comp
          FROM (SELECT *
                  FROM blood_product_execution bpe
                 WHERE bpe.id_blood_product_det = i_blood_product_det
                   AND bpe.action = pk_blood_products_constant.g_bp_action_compability
                 ORDER BY bpe.exec_number DESC) t
         WHERE rownum = 1;
    
        IF i_color = pk_alert_constant.g_yes
           AND l_comp = 'I'
        THEN
            l_ret := '<font color="#C86464">' ||
                     pk_sysdomain.get_domain(i_lang, i_prof, 'BLOOD_PRODUCT_EXECUTION.FLG_COMPATIBILITY', l_comp, NULL) ||
                     '</font>';
        ELSE
            l_ret := pk_sysdomain.get_domain(i_lang, i_prof, 'BLOOD_PRODUCT_EXECUTION.FLG_COMPATIBILITY', l_comp, NULL);
        END IF;
    
        RETURN l_ret;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_bp_compatibility_desc;

    FUNCTION get_bp_compatibility_notes
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_blood_product_det IN blood_product_det.id_blood_product_det%TYPE
    ) RETURN VARCHAR2 AS
        l_ret VARCHAR2(100 CHAR);
    BEGIN
    
        SELECT t.notes_compatibility
          INTO l_ret
          FROM (SELECT *
                  FROM blood_product_execution bpe
                 WHERE bpe.id_blood_product_det = i_blood_product_det
                   AND bpe.action = pk_blood_products_constant.g_bp_action_compability
                 ORDER BY bpe.exec_number DESC) t
         WHERE rownum = 1;
    
        RETURN l_ret;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_bp_compatibility_notes;

    FUNCTION get_bp_compatibility_reg_tstz
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_blood_product_det IN blood_product_det.id_blood_product_det%TYPE
    ) RETURN TIMESTAMP
        WITH LOCAL TIME ZONE AS
        l_ret TIMESTAMP WITH LOCAL TIME ZONE;
    BEGIN
    
        SELECT t.dt_bp_execution_tstz
          INTO l_ret
          FROM (SELECT *
                  FROM blood_product_execution bpe
                 WHERE bpe.id_blood_product_det = i_blood_product_det
                   AND bpe.action = pk_blood_products_constant.g_bp_action_compability
                 ORDER BY bpe.exec_number DESC) t
         WHERE rownum = 1;
    
        RETURN l_ret;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_bp_compatibility_reg_tstz;

    FUNCTION get_bp_unsafe_status
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_blood_product_req IN blood_product_det.id_blood_product_req%TYPE,
        i_blood_product_det IN blood_product_det.id_blood_product_det%TYPE DEFAULT NULL,
        i_limit             IN sys_config.id_sys_config%TYPE
    ) RETURN sys_domain.val%TYPE IS
    
        l_dt_begin        blood_product_execution.dt_bp_execution_tstz%TYPE;
        l_elapsed_minutes NUMBER;
    
        l_sys_config_popup_limit sys_config.id_sys_config%TYPE := pk_sysconfig.get_config(i_prof    => i_prof,
                                                                                          i_code_cf => 'BLOOD_TIME_LIMIT_POPUP_SHOW');
        l_flg_status             blood_product_det.flg_status%TYPE;
    
        l_ret sys_domain.val%TYPE;
    BEGIN
        IF l_sys_config_popup_limit = pk_alert_constant.g_yes
        THEN
            IF i_blood_product_det IS NOT NULL
            THEN
                BEGIN
                    SELECT bpe.dt_bp_execution_tstz, bpd.flg_status
                      INTO l_dt_begin, l_flg_status
                      FROM blood_product_execution bpe
                      JOIN blood_product_det bpd
                        ON bpd.id_blood_product_det = bpe.id_blood_product_det
                     WHERE bpd.id_blood_product_req = i_blood_product_req
                       AND bpd.id_blood_product_det = i_blood_product_det
                       AND bpd.flg_status IN (pk_blood_products_constant.g_status_det_r_sc,
                                              pk_blood_products_constant.g_status_det_r_cc,
                                              pk_blood_products_constant.g_status_det_r_w,
                                              pk_blood_products_constant.g_status_det_wt,
                                              pk_blood_products_constant.g_status_det_ot,
                                              pk_blood_products_constant.g_status_det_ct,
                                              pk_blood_products_constant.g_status_det_rt,
                                              pk_blood_products_constant.g_status_det_o,
                                              pk_blood_products_constant.g_status_det_h,
                                              pk_blood_products_constant.g_status_det_df)
                       AND bpe.action = pk_blood_products_constant.g_bp_action_begin_transp;
                EXCEPTION
                    WHEN OTHERS THEN
                        l_dt_begin := NULL;
                END;
            ELSE
                BEGIN
                    SELECT bpe.dt_bp_execution_tstz, bpd.flg_status
                      INTO l_dt_begin, l_flg_status
                      FROM blood_product_execution bpe
                      JOIN blood_product_det bpd
                        ON bpd.id_blood_product_det = bpe.id_blood_product_det
                     WHERE bpd.id_blood_product_req = i_blood_product_req
                       AND bpd.id_blood_product_det = i_blood_product_det
                       AND bpd.flg_status IN (pk_blood_products_constant.g_status_det_r_sc,
                                              pk_blood_products_constant.g_status_det_r_cc,
                                              pk_blood_products_constant.g_status_det_r_w,
                                              pk_blood_products_constant.g_status_det_wt,
                                              pk_blood_products_constant.g_status_det_ot,
                                              pk_blood_products_constant.g_status_det_ct,
                                              pk_blood_products_constant.g_status_det_rt,
                                              pk_blood_products_constant.g_status_det_o,
                                              pk_blood_products_constant.g_status_det_h,
                                              pk_blood_products_constant.g_status_det_df)
                       AND bpe.action = pk_blood_products_constant.g_bp_action_begin_transp;
                EXCEPTION
                    WHEN OTHERS THEN
                        l_dt_begin := NULL;
                END;
                BEGIN
                    SELECT MIN(bpe.dt_bp_execution_tstz)
                      INTO l_dt_begin
                      FROM blood_product_execution bpe
                      JOIN blood_product_det bpd
                        ON bpd.id_blood_product_det = bpe.id_blood_product_det
                     WHERE bpd.id_blood_product_req = i_blood_product_req
                       AND bpd.flg_status IN (pk_blood_products_constant.g_status_det_r_sc,
                                              pk_blood_products_constant.g_status_det_r_cc,
                                              pk_blood_products_constant.g_status_det_r_w,
                                              pk_blood_products_constant.g_status_det_wt,
                                              pk_blood_products_constant.g_status_det_ot,
                                              pk_blood_products_constant.g_status_det_ct,
                                              pk_blood_products_constant.g_status_det_rt,
                                              pk_blood_products_constant.g_status_det_o,
                                              pk_blood_products_constant.g_status_det_h,
                                              pk_blood_products_constant.g_status_det_df)
                       AND bpe.action = pk_blood_products_constant.g_bp_action_begin_transp;
                
                    l_flg_status := pk_blood_products_constant.g_status_det_o;
                EXCEPTION
                    WHEN OTHERS THEN
                        l_dt_begin := NULL;
                END;
            
            END IF;
        
            IF l_dt_begin IS NOT NULL
            THEN
                l_elapsed_minutes := pk_date_utils.get_elapsed_minutes_abs_tsz(l_dt_begin);
                IF l_elapsed_minutes >= to_number(i_limit)
                THEN
                    l_ret := pk_blood_products_constant.g_status_det_x || l_flg_status;
                END IF;
            END IF;
        END IF;
        RETURN l_ret;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_bp_unsafe_status;

    FUNCTION get_bp_status_over_limit
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        i_limit   IN sys_config.id_sys_config%TYPE
    ) RETURN VARCHAR2 IS
    
        l_dt_begin             blood_product_execution.dt_bp_execution_tstz%TYPE;
        l_id_blood_product_det blood_product_det.id_blood_product_det%TYPE;
        l_elapsed_minutes      NUMBER;
    
        l_ret VARCHAR2(4000);
    BEGIN
        BEGIN
            SELECT MIN(bpe.dt_bp_execution_tstz)
              INTO l_dt_begin
              FROM blood_product_det bpd
              JOIN blood_product_req bpr
                ON bpr.id_blood_product_req = bpd.id_blood_product_req
              JOIN blood_product_execution bpe
                ON bpe.id_blood_product_det = bpd.id_blood_product_det
             WHERE bpr.id_episode = i_episode
               AND bpd.flg_status IN (pk_blood_products_constant.g_status_det_r_sc,
                                      pk_blood_products_constant.g_status_det_r_cc,
                                      pk_blood_products_constant.g_status_det_r_w,
                                      pk_blood_products_constant.g_status_det_wt,
                                      pk_blood_products_constant.g_status_det_ot,
                                      pk_blood_products_constant.g_status_det_ct,
                                      pk_blood_products_constant.g_status_det_rt,
                                      pk_blood_products_constant.g_status_det_o,
                                      pk_blood_products_constant.g_status_det_h,
                                      pk_blood_products_constant.g_status_det_df)
               AND bpe.action = pk_blood_products_constant.g_bp_action_begin_transp
             GROUP BY bpr.id_episode;
        EXCEPTION
            WHEN OTHERS THEN
                l_dt_begin := NULL;
        END;
    
        IF l_dt_begin IS NOT NULL
        THEN
            l_elapsed_minutes := pk_date_utils.get_elapsed_minutes_abs_tsz(l_dt_begin);
            IF l_elapsed_minutes >= to_number(i_limit)
            THEN
                BEGIN
                    SELECT bpd.id_blood_product_det
                      INTO l_id_blood_product_det
                      FROM blood_product_det bpd
                      JOIN blood_product_req bpr
                        ON bpr.id_blood_product_req = bpd.id_blood_product_req
                      JOIN blood_product_execution bpe
                        ON bpe.id_blood_product_det = bpd.id_blood_product_det
                     WHERE bpr.id_episode = i_episode
                       AND bpd.flg_status IN (pk_blood_products_constant.g_status_det_r_sc,
                                              pk_blood_products_constant.g_status_det_r_cc,
                                              pk_blood_products_constant.g_status_det_r_w,
                                              pk_blood_products_constant.g_status_det_ot,
                                              pk_blood_products_constant.g_status_det_ct,
                                              pk_blood_products_constant.g_status_det_rt,
                                              pk_blood_products_constant.g_status_det_o,
                                              pk_blood_products_constant.g_status_det_h,
                                              pk_blood_products_constant.g_status_det_df)
                       AND bpe.action = pk_blood_products_constant.g_bp_action_begin_transp
                       AND bpe.dt_bp_execution_tstz = l_dt_begin;
                EXCEPTION
                    WHEN OTHERS THEN
                        RETURN NULL;
                END;
            
                l_ret := get_status_string(i_lang    => i_lang,
                                           i_prof    => i_prof,
                                           i_episode => i_episode,
                                           i_bp_det  => l_id_blood_product_det);
            END IF;
        END IF;
    
        RETURN l_ret;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_bp_status_over_limit;

    FUNCTION get_status_string_req
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_bp_req          IN blood_product_req.id_blood_product_req%TYPE,
        i_limit           IN sys_config.id_sys_config%TYPE,
        i_status_str_req  IN VARCHAR2,
        i_status_msg_req  IN VARCHAR2,
        i_status_icon_req IN VARCHAR2,
        i_status_flg_req  IN VARCHAR2
        
    ) RETURN VARCHAR2 IS
    
        l_unsafe_status  sys_domain.val%TYPE := NULL;
        l_list           table_varchar2;
        l_status_str_req VARCHAR2(4000) := NULL;
    
        l_ret VARCHAR2(4000);
    BEGIN
    
        l_unsafe_status := pk_blood_products_utils.get_bp_unsafe_status(i_lang, i_prof, i_bp_req, NULL, i_limit);
    
        --Allow for the Requisition status icon to display more than one color 
        IF l_unsafe_status IS NOT NULL
        THEN
            l_list := pk_utils.str_split(i_status_str_req, '|');
        
            FOR i IN l_list.first .. l_list.last
            LOOP
                IF i = 11 --Position regarding the default_color
                THEN
                    l_status_str_req := l_status_str_req || pk_alert_constant.g_yes || '|';
                ELSE
                    l_status_str_req := l_status_str_req || l_list(i) || '|';
                END IF;
            END LOOP;
        END IF;
    
        l_ret := pk_utils.get_status_string(i_lang,
                                            i_prof,
                                            coalesce(l_status_str_req, i_status_str_req),
                                            i_status_msg_req,
                                            i_status_icon_req,
                                            coalesce(l_unsafe_status, i_status_flg_req)) || CASE
                     WHEN l_unsafe_status IS NOT NULL THEN
                      pk_message.get_message(i_lang, 'BLOOD_PRODUCTS_T134')
                 END;
    
        RETURN l_ret;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_status_string_req;

    FUNCTION get_analysis_result_blood
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_patient      IN patient.id_patient%TYPE,
        i_analysis     IN table_number,
        i_sample_type  IN table_number,
        i_flg_html_det IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        o_result_data  OUT table_varchar,
        o_result_date  OUT table_varchar,
        o_result_reg   OUT table_varchar,
        o_match        OUT NUMBER,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_tbl_lab_result t_tbl_lab_tests_results;
        l_exception EXCEPTION;
    
        l_msg_reg sys_message.desc_message%TYPE := pk_message.get_message(i_lang, i_prof, 'COMMON_M107');
    
    BEGIN
    
        IF NOT pk_lab_tests_core.get_lab_test_resultsview(i_lang             => i_lang,
                                                          i_prof             => i_prof,
                                                          i_patient          => i_patient,
                                                          i_analysis_req_det => NULL,
                                                          i_flg_type         => 'R',
                                                          i_dt_min           => NULL,
                                                          i_dt_max           => NULL,
                                                          i_flg_report       => NULL,
                                                          o_list             => l_tbl_lab_result,
                                                          o_error            => o_error)
        THEN
            RAISE l_exception;
        END IF;
    
        SELECT z.result_analysis, z.dt_result, z.result_reg
          BULK COLLECT
          INTO o_result_data, o_result_date, o_result_reg
          FROM (SELECT regexp_replace(t1.result, '[[:space:]]*', '') result_analysis,
                       t1.dt_result,
                       decode(i_flg_html_det, pk_alert_constant.g_no, '<i>', NULL) || l_msg_reg || ' ' || t1.prof_result ||
                       decode(t1.prof_spec_result, NULL, '; ', ' (' || t1.prof_spec_result || '); ') ||
                       t1.dt_result_date || decode(i_flg_html_det, pk_alert_constant.g_no, '</i>', NULL) result_reg
                  FROM TABLE(l_tbl_lab_result) t1
                 INNER JOIN TABLE(i_analysis) t2
                    ON t2.column_value = t1.id_analysis
                 INNER JOIN TABLE(i_sample_type) t3
                    ON t3.column_value = t1.id_sample_type
                 WHERE t1.result IS NOT NULL
                 ORDER BY t1.dt_result DESC) z
         WHERE rownum <= 2;
    
        IF o_result_data.count = 0
        THEN
            o_match := pk_blood_products_constant.g_an_blood_no_result;
        ELSIF o_result_data.count = 1
        THEN
            o_match := pk_blood_products_constant.g_an_blood_no_confirmed;
        ELSE
            IF o_result_data(1) = o_result_data(2)
            THEN
                o_match := pk_blood_products_constant.g_an_blood_confirmed;
            ELSE
                o_match := pk_blood_products_constant.g_an_blood_no_coincident;
            END IF;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_analysis_result_blood;

    FUNCTION get_returned_bag_status
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_blood_product_det IN blood_product_det.id_blood_product_det%TYPE
    ) RETURN VARCHAR2 IS
        l_action blood_product_execution.action%TYPE;
    BEGIN
    
        SELECT bpe.action
          INTO l_action
          FROM blood_product_execution bpe
         WHERE bpe.id_blood_product_det = i_blood_product_det
           AND bpe.action = pk_blood_products_constant.g_bp_action_conclude;
    
        RETURN pk_blood_products_constant.g_status_det_f;
    
    EXCEPTION
        WHEN no_data_found THEN
            RETURN pk_blood_products_constant.g_status_req_d;
    END;

    FUNCTION get_full_items_by_screen
    (
        i_lang        IN NUMBER,
        i_prof        IN profissional,
        i_patient     IN NUMBER,
        i_episode     IN NUMBER,
        i_screen_name IN VARCHAR2,
        i_action      IN NUMBER,
        o_components  OUT t_clin_quest_table,
        o_ds_target   OUT t_clin_quest_target_table,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_return BOOLEAN;
    
        l_tbl_id_bp       table_number;
        l_tbl_id_bp_final table_number;
        l_patient         patient%ROWTYPE;
        l_count           NUMBER;
    BEGIN
    
        l_tbl_id_bp := pk_utils.str_split_n(i_list => i_screen_name, i_delim => '|');
    
        IF i_action = 70
        THEN
            FOR i IN l_tbl_id_bp.first .. l_tbl_id_bp.last
            LOOP
                SELECT ipd.id_hemo_type
                  INTO l_tbl_id_bp(i)
                  FROM blood_product_det ipd
                 WHERE ipd.id_blood_product_det = l_tbl_id_bp(i);
            END LOOP;
        ELSE
            SELECT DISTINCT eq.id_hemo_type
              BULK COLLECT
              INTO l_tbl_id_bp_final
              FROM bp_questionnaire eq
             WHERE eq.id_hemo_type IN (SELECT column_value
                                         FROM TABLE(l_tbl_id_bp))
               AND eq.flg_time = pk_exam_constant.g_exam_cq_on_order
               AND eq.id_institution = i_prof.institution
               AND eq.flg_available = pk_exam_constant.g_available;
            IF l_tbl_id_bp_final.count = 0
            THEN
                o_components := t_clin_quest_table();
                o_ds_target  := t_clin_quest_target_table();
                RETURN TRUE;
            END IF;
        END IF;
    
        SELECT t_clin_quest_row(id_ds_cmpt_mkt_rel        => z.id_ds_cmpt_mkt_rel,
                                id_ds_component_parent    => z.id_ds_component_parent,
                                code_alt_desc             => z.code_alt_desc,
                                desc_component            => z.desc_component,
                                internal_name             => z.internal_name,
                                flg_data_type             => z.flg_data_type,
                                internal_sample_text_type => z.internal_sample_text_type,
                                id_ds_component_child     => z.id_ds_component_child,
                                rank                      => z.rank,
                                max_len                   => z.max_len,
                                min_len                   => z.min_len,
                                min_value                 => z.min_value,
                                max_value                 => z.max_value,
                                position                  => z.position,
                                flg_multichoice           => z.flg_multichoice,
                                comp_size                 => z.comp_size,
                                flg_wrap_text             => z.flg_wrap_text,
                                multichoice_code          => z.multichoice_code,
                                service_params            => z.service_params,
                                flg_event_type            => z.flg_event_type,
                                flg_exp_type              => z.flg_exp_type,
                                input_expression          => z.input_expression,
                                input_mask                => z.input_mask,
                                comp_offset               => z.comp_offset,
                                flg_hidden                => z.flg_hidden,
                                placeholder               => z.placeholder,
                                validation_message        => z.validation_message,
                                flg_clearable             => z.flg_clearable,
                                crate_identifier          => z.crate_identifier,
                                rn                        => z.rn,
                                flg_repeatable            => z.flg_repeatable,
                                flg_data_type2            => z.flg_data_type2,
                                text_line_nr              => NULL)
          BULK COLLECT
          INTO o_components
          FROM (SELECT 0 id_ds_cmpt_mkt_rel,
                       NULL id_ds_component_parent,
                       NULL code_alt_desc,
                       pk_message.get_message(i_lang, 'PROCEDURES_T163') desc_component,
                       i_screen_name internal_name,
                       NULL flg_data_type,
                       NULL internal_sample_text_type,
                       --to_number(i_screen_name) id_ds_component_child,
                       0    id_ds_component_child,
                       1    rank,
                       NULL max_len,
                       NULL min_len,
                       NULL min_value,
                       NULL max_value,
                       1    position,
                       NULL flg_multichoice,
                       NULL comp_size,
                       NULL flg_wrap_text,
                       NULL multichoice_code,
                       NULL service_params,
                       NULL flg_event_type,
                       NULL flg_exp_type,
                       NULL input_expression,
                       NULL input_mask,
                       NULL comp_offset,
                       NULL flg_hidden,
                       NULL placeholder,
                       NULL validation_message,
                       NULL flg_clearable,
                       NULL crate_identifier,
                       1    rn,
                       NULL flg_repeatable,
                       NULL flg_data_type2
                  FROM dual
                UNION ALL
                SELECT to_number(t.column_value) id_ds_cmpt_mkt_rel,
                       0 id_ds_component_parent,
                       NULL code_alt_desc,
                       pk_translation.get_translation(i_lang, 'HEMO_TYPE.CODE_HEMO_TYPE.' || to_number(t.column_value)) desc_component,
                       pk_translation.get_translation(i_lang, 'HEMO_TYPE.CODE_HEMO_TYPE.' || to_number(t.column_value)) internal_name,
                       NULL flg_data_type,
                       NULL internal_sample_text_type,
                       to_number(t.column_value) id_ds_component_child,
                       rownum rank,
                       NULL max_len,
                       NULL min_len,
                       NULL min_value,
                       NULL max_value,
                       rownum position,
                       NULL flg_multichoice,
                       NULL comp_size,
                       NULL flg_wrap_text,
                       NULL multichoice_code,
                       NULL service_params,
                       NULL flg_event_type,
                       NULL flg_exp_type,
                       NULL input_expression,
                       NULL input_mask,
                       NULL comp_offset,
                       NULL flg_hidden,
                       NULL placeholder,
                       NULL validation_message,
                       NULL flg_clearable,
                       NULL crate_identifier,
                       rownum rn,
                       NULL flg_repeatable,
                       NULL flg_data_type2
                  FROM TABLE(l_tbl_id_bp_final) t
                UNION ALL
                SELECT (q.id_questionnaire * 10 + q.id_hemo_type) id_ds_cmpt_mkt_rel,
                       q.id_hemo_type id_ds_component_parent,
                       NULL code_alt_desc,
                       pk_mcdt.get_questionnaire_alias(i_lang,
                                                       i_prof,
                                                       'QUESTIONNAIRE.CODE_QUESTIONNAIRE.' || q.id_questionnaire) desc_component,
                       to_char('BP' || '|' || q.id_hemo_type || '_' || q.id_questionnaire) internal_name,
                       decode(q.flg_type, 'D', 'DT', 'ME', 'MS', 'MI', 'MM', 'N', 'K', NULL) flg_data_type,
                       NULL internal_sample_text_type,
                       q.id_questionnaire id_ds_component_child,
                       q.id_questionnaire rank,
                       NULL max_len,
                       NULL min_len,
                       NULL min_value,
                       NULL max_value,
                       rownum + 1000 position,
                       decode(q.flg_type, 'ME', 'SRV', 'MI', 'SRV', NULL) flg_multichoice,
                       NULL comp_size,
                       NULL flg_wrap_text,
                       decode(q.flg_type, 'ME', 'GET_MULTICHOICE_CQ', 'MI', 'GET_MULTICHOICE_CQ', NULL) multichoice_code,
                       (q.id_questionnaire * 10 + q.id_hemo_type) service_params,
                       decode(q.id_questionnaire_parent, NULL, decode(q.flg_mandatory, 'Y', 'M', NULL), 'I') flg_event_type,
                       NULL flg_exp_type,
                       NULL input_expression,
                       NULL input_mask,
                       NULL comp_offset,
                       pk_alert_constant.g_no flg_hidden,
                       NULL placeholder,
                       NULL validation_message,
                       pk_alert_constant.g_yes flg_clearable,
                       NULL crate_identifier,
                       rownum + 100 rn,
                       NULL flg_repeatable,
                       NULL flg_data_type2
                  FROM (SELECT DISTINCT iq.id_hemo_type,
                                        iq.id_questionnaire,
                                        qr.id_questionnaire_parent,
                                        qr.id_response_parent,
                                        iq.flg_type,
                                        iq.flg_mandatory,
                                        iq.flg_copy,
                                        --iq.flg_validation,
                                        iq.id_unit_measure
                          FROM bp_questionnaire iq,
                               questionnaire_response qr,
                               (SELECT column_value AS id_hemo_type
                                  FROM TABLE(l_tbl_id_bp_final)) p
                         WHERE iq.id_hemo_type = p.id_hemo_type
                           AND iq.flg_time = 'O'
                           AND iq.id_institution = i_prof.institution
                           AND iq.flg_available = pk_procedures_constant.g_available
                           AND iq.id_questionnaire = qr.id_questionnaire
                           AND iq.id_response = qr.id_response
                           AND qr.flg_available = pk_procedures_constant.g_available
                           AND EXISTS
                         (SELECT 1
                                  FROM questionnaire q
                                 WHERE q.id_questionnaire = iq.id_questionnaire
                                   AND q.flg_available = pk_procedures_constant.g_available
                                   AND (((l_patient.gender IS NOT NULL AND
                                       coalesce(q.gender, 'I', 'U', 'N', 'C', 'A', 'B') IN
                                       ('I', 'U', 'N', 'C', 'A', 'B', l_patient.gender)) OR l_patient.gender IS NULL OR
                                       l_patient.gender IN ('I', 'U', 'N', 'C', 'A', 'B')) AND
                                       (nvl(l_patient.age, 0) BETWEEN nvl(q.age_min, 0) AND
                                       nvl(q.age_max, nvl(l_patient.age, 0)) OR nvl(l_patient.age, 0) = 0)))) q
                 ORDER BY rank) z;
    
        SELECT t_clin_quest_target_row(id_cmpt_mkt_origin    => z.id_cmpt_mkt_origin,
                                       id_cmpt_origin        => z.id_cmpt_origin,
                                       id_ds_event           => z.id_ds_event,
                                       flg_type              => z.flg_type,
                                       VALUE                 => z.value,
                                       id_cmpt_mkt_dest      => z.id_cmpt_mkt_dest,
                                       id_cmpt_dest          => z.id_cmpt_dest,
                                       field_mask            => z.field_mask,
                                       flg_event_target_type => z.flg_event_target_type,
                                       validation_message    => z.validation_message,
                                       rn                    => z.rn)
          BULK COLLECT
          INTO o_ds_target
          FROM (
                
                SELECT (q.id_questionnaire * 10 + q.id_hemo_type) id_cmpt_mkt_origin,
                        q.id_questionnaire id_cmpt_origin,
                        q.id_questionnaire id_ds_event,
                        'E' flg_type,
                        '@1 == ' || get_response_parent(i_lang, i_prof, q.id_hemo_type, q.id_questionnaire) VALUE,
                        qd.id_questionnaire * 10 + q.id_hemo_type id_cmpt_mkt_dest,
                        NULL id_cmpt_dest,
                        NULL field_mask,
                        'A' flg_event_target_type,
                        NULL validation_message,
                        1 rn
                  FROM (SELECT DISTINCT iq.id_hemo_type,
                                         iq.id_questionnaire,
                                         qr.id_questionnaire_parent,
                                         qr.id_response_parent,
                                         iq.flg_type,
                                         iq.flg_mandatory,
                                         iq.flg_copy,
                                         iq.flg_validation,
                                         iq.id_unit_measure,
                                         iq.rank
                           FROM bp_questionnaire iq, questionnaire_response qr
                          WHERE iq.id_hemo_type IN (SELECT *
                                                      FROM TABLE(l_tbl_id_bp))
                            AND iq.flg_time = 'O'
                            AND iq.id_institution = i_prof.institution
                            AND iq.flg_available = pk_procedures_constant.g_available
                            AND iq.id_questionnaire = qr.id_questionnaire
                            AND iq.id_response = qr.id_response
                            AND qr.flg_available = pk_procedures_constant.g_available
                            AND EXISTS
                          (SELECT 1
                                   FROM questionnaire q
                                  WHERE q.id_questionnaire = iq.id_questionnaire
                                    AND q.flg_available = pk_procedures_constant.g_available
                                    AND (((l_patient.gender IS NOT NULL AND coalesce(q.gender, 'I', 'U', 'N', 'C', 'A', 'B') IN
                                        ('I', 'U', 'N', 'C', 'A', 'B', l_patient.gender)) OR l_patient.gender IS NULL OR
                                        l_patient.gender IN ('I', 'U', 'N', 'C', 'A', 'B')) AND
                                        (nvl(l_patient.age, 0) BETWEEN nvl(q.age_min, 0) AND
                                        nvl(q.age_max, nvl(l_patient.age, 0)) OR nvl(l_patient.age, 0) = 0)))) q,
                        (SELECT DISTINCT qr.id_questionnaire, qr.id_questionnaire_parent, eq.id_hemo_type
                           FROM bp_questionnaire eq
                          INNER JOIN questionnaire_response qr
                             ON eq.id_questionnaire = qr.id_questionnaire
                          WHERE eq.id_hemo_type IN (SELECT *
                                                      FROM TABLE(l_tbl_id_bp))
                            AND eq.id_institution = i_prof.institution) qd
                 WHERE q.id_response_parent IS NULL
                   AND qd.id_questionnaire_parent = q.id_questionnaire
                   AND qd.id_hemo_type = q.id_hemo_type
                   AND q.flg_type IN ('ME', 'MI')
                UNION ALL
                SELECT (q.id_questionnaire * 10 + q.id_hemo_type) id_cmpt_mkt_origin,
                        q.id_questionnaire id_cmpt_origin,
                        q.id_questionnaire id_ds_event,
                        'E' flg_type,
                        '@1 != ' || get_response_parent(i_lang, i_prof, q.id_hemo_type, q.id_questionnaire) VALUE,
                        qd.id_questionnaire * 10 + q.id_hemo_type id_cmpt_mkt_dest,
                        NULL id_cmpt_dest,
                        NULL field_mask,
                        'I' flg_event_target_type,
                        NULL validation_message,
                        1 rn
                  FROM (SELECT DISTINCT iq.id_hemo_type,
                                         iq.id_questionnaire,
                                         qr.id_questionnaire_parent,
                                         qr.id_response_parent,
                                         iq.flg_type,
                                         iq.flg_mandatory,
                                         iq.flg_copy,
                                         iq.flg_validation,
                                         iq.id_unit_measure,
                                         iq.rank
                           FROM bp_questionnaire iq, questionnaire_response qr
                          WHERE iq.id_hemo_type IN (SELECT *
                                                      FROM TABLE(l_tbl_id_bp))
                            AND iq.flg_time = 'O'
                            AND iq.id_institution = i_prof.institution
                            AND iq.flg_available = pk_procedures_constant.g_available
                            AND iq.id_questionnaire = qr.id_questionnaire
                            AND iq.id_response = qr.id_response
                            AND qr.flg_available = pk_procedures_constant.g_available
                            AND EXISTS
                          (SELECT 1
                                   FROM questionnaire q
                                  WHERE q.id_questionnaire = iq.id_questionnaire
                                    AND q.flg_available = pk_procedures_constant.g_available
                                    AND (((l_patient.gender IS NOT NULL AND coalesce(q.gender, 'I', 'U', 'N', 'C', 'A', 'B') IN
                                        ('I', 'U', 'N', 'C', 'A', 'B', l_patient.gender)) OR l_patient.gender IS NULL OR
                                        l_patient.gender IN ('I', 'U', 'N', 'C', 'A', 'B')) AND
                                        (nvl(l_patient.age, 0) BETWEEN nvl(q.age_min, 0) AND
                                        nvl(q.age_max, nvl(l_patient.age, 0)) OR nvl(l_patient.age, 0) = 0)))) q,
                        (SELECT DISTINCT qr.id_questionnaire, qr.id_questionnaire_parent, eq.id_hemo_type
                           FROM bp_questionnaire eq
                          INNER JOIN questionnaire_response qr
                             ON eq.id_questionnaire = qr.id_questionnaire
                          WHERE eq.id_hemo_type IN (SELECT *
                                                      FROM TABLE(l_tbl_id_bp))
                            AND eq.id_institution = i_prof.institution) qd
                 WHERE q.id_response_parent IS NULL
                   AND qd.id_questionnaire_parent = q.id_questionnaire
                   AND qd.id_hemo_type = q.id_hemo_type
                   AND q.flg_type IN ('ME', 'MI')) z;
        --pk_types.open_cursor_if_closed(o_ds_target);
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_FULL_ITEMS_BY_SCREEN',
                                              o_error);
            RETURN FALSE;
    END get_full_items_by_screen;

    FUNCTION get_response_parent
    (
        i_lang          language.id_language%TYPE,
        i_prof          profissional,
        i_hemo_type     hemo_type.id_hemo_type %TYPE,
        i_questionnaire questionnaire.id_questionnaire%TYPE
    ) RETURN NUMBER AS
        l_ret NUMBER(24);
    BEGIN
    
        SELECT DISTINCT qr.id_response_parent
          INTO l_ret
          FROM bp_questionnaire iq
         INNER JOIN questionnaire_response qr
            ON iq.id_questionnaire = qr.id_questionnaire
         WHERE iq.id_hemo_type = i_hemo_type
           AND qr.id_questionnaire_parent = i_questionnaire
           AND iq.id_institution = i_prof.institution;
    
        RETURN l_ret;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
        
    END get_response_parent;

BEGIN

    pk_alertlog.who_am_i(g_package_owner, g_package_name);
    pk_alertlog.log_init(g_package_name);

END pk_blood_products_utils;
/
