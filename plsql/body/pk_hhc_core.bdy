/*-- Last Change Revision: $Rev: 2048171 $*/
/*-- Last Change by: $Author: elisabete.bugalho $*/
/*-- Date of last change: $Date: 2022-10-21 12:19:13 +0100 (sex, 21 out 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_hhc_core IS

    -- Private type declarations
    g_req_hist t_coll_hhc_req_hist := t_coll_hhc_req_hist();
    -- Private constant declarations

    -- Private variable declarations
    g_error   VARCHAR2(1000 CHAR);
    g_owner   VARCHAR2(30 CHAR);
    g_package VARCHAR2(30 CHAR);
    k_yes CONSTANT VARCHAR2(0010 CHAR) := 'Y';
    k_no  CONSTANT VARCHAR2(0010 CHAR) := 'N';

    k_hhc_requested              CONSTANT VARCHAR2(0010 CHAR) := pk_hhc_constant.k_hhc_req_status_requested;
    k_hhc_part_approved          CONSTANT VARCHAR2(0010 CHAR) := pk_hhc_constant.k_hhc_req_status_part_approved;
    k_hhc_in_evaluation          CONSTANT VARCHAR2(0010 CHAR) := pk_hhc_constant.k_hhc_req_status_in_eval;
    k_hhc_in_part_acc_wcm        CONSTANT VARCHAR2(0010 CHAR) := pk_hhc_constant.k_hhc_req_stauts_part_acc_wcm;
    k_hhc_closed                 CONSTANT VARCHAR2(0010 CHAR) := pk_hhc_constant.k_hhc_req_status_closed;
    k_hhc_canceled               CONSTANT VARCHAR2(0010 CHAR) := pk_hhc_constant.k_hhc_req_status_canceled;
    k_hhc_rejected               CONSTANT VARCHAR2(0010 CHAR) := pk_hhc_constant.k_hhc_req_status_rejected;
    k_hhc_discontinued           CONSTANT VARCHAR2(0010 CHAR) := pk_hhc_constant.k_hhc_req_status_discontinued;
    k_hhc_approved               CONSTANT VARCHAR2(0010 CHAR) := pk_hhc_constant.k_hhc_req_status_approved;
    k_hhc_req_status_in_progress CONSTANT VARCHAR2(0010 CHAR) := pk_hhc_constant.k_hhc_req_status_in_progress;
    k_hhc_undo                   CONSTANT VARCHAR2(0010 CHAR) := pk_hhc_constant.k_hhc_req_status_undo;

    k_action_add  CONSTANT NUMBER := pk_hhc_constant.k_action_add;
    k_action_edit CONSTANT NUMBER := pk_hhc_constant.k_action_edit;
    --k_action_cancel CONSTANT NUMBER := pk_hhc_constant.k_action_cancel;

    k_hhc_epis_type CONSTANT NUMBER := pk_hhc_constant.k_hhc_epis_type;

    k_ds_referral_type             CONSTANT NUMBER := pk_hhc_constant.k_ds_referral_type;
    k_ds_referral_origin           CONSTANT NUMBER := pk_hhc_constant.k_ds_referral_origin;
    k_ds_medical_history           CONSTANT NUMBER := pk_hhc_constant.k_ds_medical_history;
    k_ds_problems                  CONSTANT NUMBER := pk_hhc_constant.k_ds_problems;
    k_ds_vaccines                  CONSTANT NUMBER := pk_hhc_constant.k_ds_vaccines;
    k_ds_care_plan                 CONSTANT NUMBER := pk_hhc_constant.k_ds_care_plan;
    k_ds_supplies                  CONSTANT NUMBER := pk_hhc_constant.k_ds_supplies;
    k_ds_iv_referral_required      CONSTANT NUMBER := pk_hhc_constant.k_ds_iv_referral_required;
    k_ds_iv_pharm_assessed         CONSTANT NUMBER := pk_hhc_constant.k_ds_iv_pharm_assessed;
    k_ds_iv_inf_control_done       CONSTANT NUMBER := pk_hhc_constant.k_ds_iv_inf_control_done;
    k_ds_investigation_lab         CONSTANT NUMBER := pk_hhc_constant.k_ds_investigation_lab;
    k_ds_investigation_exam        CONSTANT NUMBER := pk_hhc_constant.k_ds_investigation_exam;
    k_ds_care_giver_name           CONSTANT NUMBER := pk_hhc_constant.k_ds_care_giver_name;
    k_ds_care_giver_contact_num    CONSTANT NUMBER := pk_hhc_constant.k_ds_care_giver_contact_num;
    k_ds_prof_in_charge_name       CONSTANT NUMBER := pk_hhc_constant.k_ds_prof_in_charge_name;
    k_ds_prof_internal_name        CONSTANT VARCHAR2(200 CHAR) := 'DS_HHC_PROF_IN_CHARGE_NAME';
    k_ds_prof_in_charge_mobile_num CONSTANT NUMBER := pk_hhc_constant.k_ds_prof_in_charge_mobile_num;
    k_ds_care_plan_specify         CONSTANT NUMBER := pk_hhc_constant.k_ds_care_plan_specify;

    k_ds_family_relationship CONSTANT NUMBER := pk_hhc_constant.k_ds_family_relationship;
    k_ds_family_rel_specify  CONSTANT NUMBER := pk_hhc_constant.k_ds_family_rel_specify;
    k_ds_firstname           CONSTANT NUMBER := pk_hhc_constant.k_ds_firstname;
    k_ds_lastname            CONSTANT NUMBER := pk_hhc_constant.k_ds_lastname;
    k_ds_othernames1         CONSTANT NUMBER := pk_hhc_constant.k_ds_othernames1;
    k_ds_othernames3         CONSTANT NUMBER := pk_hhc_constant.k_ds_othernames3;
    k_ds_phone_mobile        CONSTANT NUMBER := pk_hhc_constant.k_ds_phone_mobile;
    k_ds_id_care_giver       CONSTANT NUMBER := pk_hhc_constant.k_ds_id_care_giver;

    k_ds_autotranslate_2 CONSTANT NUMBER := 1362;
    k_ds_autotranslate_3 CONSTANT NUMBER := 1363;

    --k_ds_flg_component_type_root CONSTANT VARCHAR2(0010 CHAR) := 'R';
    k_ds_flg_component_type_node CONSTANT VARCHAR2(0010 CHAR) := 'N';
    k_ds_flg_component_type_leaf CONSTANT VARCHAR2(0010 CHAR) := 'L';

    k_idx_family_relationship CONSTANT NUMBER := 1;
    k_idx_firstname           CONSTANT NUMBER := 2;
    k_idx_lastname            CONSTANT NUMBER := 3;
    k_idx_othernames1         CONSTANT NUMBER := 4;
    k_idx_othernames3         CONSTANT NUMBER := 5;
    k_idx_phone_mobile        CONSTANT NUMBER := 6;
    k_idx_family_rel_spec     CONSTANT NUMBER := 7;
    k_idx_id_care_giver       CONSTANT NUMBER := 8;

    k_first_val CONSTANT NUMBER := 1;

    k_ds_adt_name_fam_rel      CONSTANT VARCHAR2(200 CHAR) := pk_hhc_constant.k_ds_adt_name_fam_rel;
    k_ds_adt_name_1st_name     CONSTANT VARCHAR2(200 CHAR) := pk_hhc_constant.k_ds_adt_name_1st_name;
    k_ds_adt_name_last_anme    CONSTANT VARCHAR2(200 CHAR) := pk_hhc_constant.k_ds_adt_name_last_anme;
    k_ds_adt_name_oname1       CONSTANT VARCHAR2(200 CHAR) := pk_hhc_constant.k_ds_adt_name_oname1;
    k_ds_adt_name_oname3       CONSTANT VARCHAR2(200 CHAR) := pk_hhc_constant.k_ds_adt_name_oname3;
    k_ds_adt_name_phone_no     CONSTANT VARCHAR2(200 CHAR) := pk_hhc_constant.k_ds_adt_name_phone_no;
    k_ds_adt_name_fam_rel_spec CONSTANT VARCHAR2(200 CHAR) := pk_hhc_constant.k_ds_adt_name_fam_rel_spec;
    k_ds_adt_id_care_giver     CONSTANT VARCHAR2(200 CHAR) := pk_hhc_constant.k_ds_adt_id_care_giver;

    -- doc areas for hhc
    --k_doc_area_interview   CONSTANT NUMBER := 36126;
    --k_doc_area_observation CONSTANT NUMBER := 36127;

    tbl_adt_comp table_varchar := table_varchar(k_ds_adt_name_fam_rel,
                                                k_ds_adt_name_1st_name,
                                                k_ds_adt_name_last_anme,
                                                k_ds_adt_name_oname1,
                                                k_ds_adt_name_oname3,
                                                k_ds_adt_name_phone_no,
                                                k_ds_adt_name_fam_rel_spec,
                                                k_ds_adt_id_care_giver);

    tbl_adt_value table_varchar := table_varchar();

    -- hhc_det_type id's of special components
    g_comp_special table_number;
    --ID's HHC det type
    g_id_hhc_det_type_orig hhc_det_type.id_hhc_det_type%TYPE := 3;

    k_hhc_det_type_orig_name hhc_det_type.type_name%TYPE := 'HHC_REFERRAL_ORIGIN';

    FUNCTION iif
    (
        i_bool  IN BOOLEAN,
        i_true  IN VARCHAR2,
        i_false IN VARCHAR2
    ) RETURN VARCHAR2 IS
    BEGIN
        IF i_bool
        THEN
            RETURN i_true;
        ELSE
            RETURN i_false;
        END IF;
    END iif;

    PROCEDURE reset_tbl_adt IS
    BEGIN
    
        tbl_adt_value := table_varchar();
        tbl_adt_value.extend(tbl_adt_comp.count);
    
    END reset_tbl_adt;

    --****************************************************
    PROCEDURE push_comp_value
    (
        i_comp  IN VARCHAR2,
        i_value IN table_varchar
    ) IS
        l_value VARCHAR2(4000);
    BEGIN
    
        IF i_value.exists(1)
        THEN
        
            l_value := i_value(k_first_val);
        
            <<lup_thru_comp>>
            FOR i IN 1 .. tbl_adt_comp.count
            LOOP
                IF i_comp = tbl_adt_comp(i)
                THEN
                    tbl_adt_value(i) := l_value;
                    EXIT lup_thru_comp;
                END IF;
            END LOOP lup_thru_comp;
        
        END IF;
    
    END push_comp_value;

    FUNCTION get_ds_id_component(i_ds_cmpt_mkt_rel IN NUMBER) RETURN NUMBER IS
        l_return NUMBER;
        tbl_id   table_number;
    BEGIN
    
        SELECT id_ds_component_child
          BULK COLLECT
          INTO tbl_id
          FROM v_ds_cmpt_mkt_rel dmr
         WHERE dmr.id_ds_cmpt_mkt_rel = i_ds_cmpt_mkt_rel;
    
        IF tbl_id.count > 0
        THEN
            l_return := tbl_id(1);
        END IF;
    
        RETURN l_return;
    
    END get_ds_id_component;

    FUNCTION get_default_values
    (
        i_id_mkt_rel IN NUMBER,
        i_value      IN VARCHAR2,
        i_desc_value IN VARCHAR2 DEFAULT NULL
    ) RETURN t_rec_ds_get_value IS
        l_ret t_rec_ds_get_value;
    BEGIN
    
        SELECT t_rec_ds_get_value(id_ds_cmpt_mkt_rel => i_id_mkt_rel,
                                  id_ds_component    => dc.id_ds_component_child,
                                  internal_name      => dc.internal_name_child,
                                  VALUE              => i_value,
                                  min_value          => NULL,
                                  max_value          => NULL,
                                  desc_value         => i_desc_value,
                                  desc_clob          => NULL,
                                  value_clob         => NULL,
                                  id_unit_measure    => NULL,
                                  desc_unit_measure  => NULL,
                                  flg_validation     => NULL,
                                  err_msg            => NULL,
                                  flg_event_type     => NULL,
                                  flg_multi_status   => NULL,
                                  idx                => 1)
          INTO l_ret
          FROM v_ds_cmpt_mkt_rel dc
         WHERE dc.id_ds_cmpt_mkt_rel = i_id_mkt_rel;
    
        RETURN l_ret;
    
    END get_default_values;

    -- *******************************
    FUNCTION get_family_rel_spec
    (
        i_patient    IN NUMBER,
        i_id_mkt_rel IN NUMBER
    ) RETURN t_rec_ds_get_value IS
        l_ret t_rec_ds_get_value;
        --l_value NUMBER;
        l_desc VARCHAR2(4000);
    BEGIN
    
        --l_value := pk_adt.get_id_pat_relative(i_id_patient => i_patient);
        l_desc := pk_adt.get_fam_relationship_spec(i_patient);
    
        l_ret := get_default_values(i_id_mkt_rel => i_id_mkt_rel, i_value => l_desc, i_desc_value => l_desc);
    
        RETURN l_ret;
    
    END get_family_rel_spec;
    --**************************************
    FUNCTION get_hhc_process(i_id_epis_hhc_req IN NUMBER) RETURN NUMBER IS
        tbl_id   table_number;
        l_return NUMBER;
    BEGIN
    
        SELECT ehr.id_epis_hhc
          BULK COLLECT
          INTO tbl_id
          FROM v_epis_hhc_req ehr
         WHERE ehr.id_epis_hhc_req = i_id_epis_hhc_req;
    
        IF tbl_id.count > 0
        THEN
            l_return := tbl_id(1);
        END IF;
    
        RETURN l_return;
    
    END get_hhc_process;

    --**************************************************
    FUNCTION get_episode_mrp
    (
        i_lang    IN NUMBER,
        i_prof    IN profissional,
        i_episode IN NUMBER
    ) RETURN NUMBER IS
        tbl_id          table_varchar;
        l_return        NUMBER;
        l_hand_off_type VARCHAR2(0100 CHAR);
    BEGIN
    
        pk_hand_off_core.get_hand_off_type(i_lang, i_prof, l_hand_off_type);
    
        IF l_hand_off_type = pk_hand_off.g_handoff_multiple
        THEN
        
            SELECT xsql.id_professional
              BULK COLLECT
              INTO tbl_id
              FROM (SELECT DISTINCT empr.id_professional
                      FROM epis_prof_resp epr
                      JOIN epis_multi_prof_resp empr
                        ON empr.id_epis_prof_resp = epr.id_epis_prof_resp
                     WHERE epr.id_episode = i_episode
                       AND epr.flg_type = pk_hand_off.g_prof_cat_doc
                       AND empr.flg_main_responsible = k_yes
                       AND epr.flg_status = pk_hand_off.g_hand_off_f) xsql;
        
        ELSE
        
            SELECT xsql.id_professional
              BULK COLLECT
              INTO tbl_id
              FROM (SELECT DISTINCT xsub.id_professional
                      FROM (SELECT nvl(epr.id_prof_to, epr.id_prof_comp) id_professional
                              FROM epis_prof_resp epr
                             WHERE epr.id_episode = i_episode
                               AND epr.flg_type = pk_hand_off.g_prof_cat_doc
                               AND epr.flg_status = pk_hand_off.g_hand_off_f) xsub) xsql;
        
        END IF;
    
        IF tbl_id.count > 0
        THEN
            l_return := tbl_id(1);
        END IF;
    
        RETURN l_return;
    
    END get_episode_mrp;

    -- *************************************
    FUNCTION get_prof_mphone(i_prof IN NUMBER) RETURN NUMBER IS
        tbl_mphone table_varchar;
        l_return   VARCHAR(1000 CHAR);
    BEGIN
    
        SELECT cell_phone
          BULK COLLECT
          INTO tbl_mphone
          FROM professional p
         WHERE p.id_professional = i_prof;
    
        IF tbl_mphone.count > 0
        THEN
            l_return := tbl_mphone(1);
        END IF;
    
        RETURN l_return;
    
    END get_prof_mphone;

    -- *********************************
    FUNCTION get_prof_in_charge_mphone
    (
        i_lang       IN NUMBER,
        i_prof       IN profissional,
        i_id_episode IN NUMBER,
        i_id_mkt_rel IN NUMBER
    ) RETURN t_rec_ds_get_value IS
        l_id_prof_mrp NUMBER;
        l_mphone      VARCHAR2(4000);
        l_ret         t_rec_ds_get_value;
    BEGIN
    
        --**************************************************
        l_id_prof_mrp := get_episode_mrp(i_lang => i_lang, i_prof => i_prof, i_episode => i_id_episode);
        l_mphone      := get_prof_mphone(i_prof => l_id_prof_mrp);
    
        l_ret := get_default_values(i_id_mkt_rel => i_id_mkt_rel, i_value => l_mphone, i_desc_value => l_mphone);
    
        RETURN l_ret;
    
    END get_prof_in_charge_mphone;

    -- *****************************
    PROCEDURE cancel_hhc_process(i_id_epis_hhc_req IN NUMBER) IS
        l_id_episode NUMBER;
    BEGIN
    
        l_id_episode := get_hhc_process(i_id_epis_hhc_req => i_id_epis_hhc_req);
    
        UPDATE episode
           SET flg_status = pk_alert_constant.g_epis_status_cancel
         WHERE id_episode = l_id_episode;
    
    END cancel_hhc_process;

    --*****************************************************
    FUNCTION get_item_values
    (
        i_component_child     IN NUMBER,
        i_id_epis_hhc_req_det IN NUMBER
    ) RETURN VARCHAR2 IS
        l_return VARCHAR2(4000);
    BEGIN
    
        CASE
            WHEN i_component_child IN (k_ds_referral_type,
                                       k_ds_referral_type,
                                       k_ds_referral_origin,
                                       k_ds_care_plan,
                                       k_ds_iv_referral_required,
                                       k_ds_iv_pharm_assessed,
                                       k_ds_iv_inf_control_done,
                                       k_ds_prof_in_charge_name) THEN
                l_return := get_value(i_id_epis_hhc_req_det);
            WHEN i_component_child IN (k_ds_medical_history,
                                       k_ds_problems,
                                       k_ds_vaccines,
                                       k_ds_supplies,
                                       k_ds_investigation_lab,
                                       k_ds_investigation_exam,
                                       k_ds_care_giver_name,
                                       k_ds_care_giver_contact_num,
                                       k_ds_prof_in_charge_mobile_num,
                                       k_ds_care_plan_specify) THEN
                l_return := NULL;
            ELSE
                l_return := NULL;
        END CASE;
    
        RETURN l_return;
    
    END get_item_values;

    -- Function and procedure implementations
    FUNCTION get_id_prof_status
    (
        i_epis_hhc_req IN NUMBER,
        i_flg_status   IN VARCHAR2,
        i_order        IN VARCHAR2 DEFAULT 'DESC'
    ) RETURN NUMBER IS
        l_return NUMBER;
        tbl_id   table_number;
    BEGIN
    
        SELECT xx.id_professional
          BULK COLLECT
          INTO tbl_id
          FROM (SELECT rownum rn, vs.id_professional
                  FROM v_epis_hhc_req_status vs
                 WHERE vs.id_epis_hhc_req = i_epis_hhc_req
                   AND vs.flg_status = i_flg_status
                --ORDER BY vs.dt_status DESC
                 ORDER BY CASE
                              WHEN i_order = 'ASC' THEN
                               vs.dt_status
                          END ASC,
                          CASE
                              WHEN i_order = 'DESC' THEN
                               vs.dt_status
                          END DESC) xx;
    
        IF tbl_id.count > 0
        THEN
            l_return := tbl_id(1);
        END IF;
    
        RETURN l_return;
    
    END get_id_prof_status;

    -- ********************************
    FUNCTION get_dt_status
    (
        i_epis_hhc_req IN NUMBER,
        i_flg_status   IN VARCHAR2
    ) RETURN v_epis_hhc_req_status.dt_status%TYPE IS
    
        tbl_id table_timestamp;
    
        l_return v_epis_hhc_req_status.dt_status%TYPE;
    
    BEGIN
    
        SELECT t.dt_status
          BULK COLLECT
          INTO tbl_id
          FROM (SELECT rownum rn, vs.dt_status
                  FROM v_epis_hhc_req_status vs
                 WHERE vs.id_epis_hhc_req = i_epis_hhc_req
                   AND vs.flg_status = i_flg_status
                 ORDER BY vs.dt_status DESC) t;
    
        IF tbl_id.count > 0
        THEN
            l_return := tbl_id(1);
        END IF;
    
        RETURN l_return;
    
    END get_dt_status;

    FUNCTION check_if_prof_can_cancel
    (
        i_flg_status IN VARCHAR2,
        i_flg_mrp    IN VARCHAR2 DEFAULT NULL
    ) RETURN VARCHAR2 IS
    
        l_return             VARCHAR2(0100 CHAR);
        l_has_mrp_permission VARCHAR2(1000 CHAR);
        l_flg_status         VARCHAR2(1000 CHAR);
    BEGIN
    
        IF i_flg_mrp IS NULL
        THEN
            l_has_mrp_permission := k_no;
        ELSE
            l_has_mrp_permission := i_flg_mrp;
        END IF;
    
        l_flg_status := i_flg_status;
    
        l_return := k_no;
        IF l_has_mrp_permission = k_yes
        THEN
            IF l_flg_status IN (k_hhc_requested)
            THEN
                l_return := k_yes;
            END IF;
        END IF;
    
        RETURN l_return;
    
    END check_if_prof_can_cancel;

    FUNCTION check_if_prof_can_edit
    (
        i_flg_status IN VARCHAR2,
        i_flg_mrp    IN VARCHAR2 DEFAULT NULL
    ) RETURN VARCHAR2 IS
    
        l_return             VARCHAR2(0100 CHAR);
        l_has_mrp_permission VARCHAR2(1000 CHAR);
        l_flg_status         VARCHAR2(1000 CHAR);
    BEGIN
    
        IF i_flg_mrp IS NULL
        THEN
            l_has_mrp_permission := k_no;
        ELSE
            l_has_mrp_permission := i_flg_mrp;
        END IF;
    
        l_flg_status := i_flg_status;
    
        l_return := k_no;
        IF l_has_mrp_permission = k_yes
        THEN
            IF l_flg_status IN (k_hhc_requested)
            THEN
                l_return := k_yes;
            END IF;
        END IF;
    
        RETURN l_return;
    
    END check_if_prof_can_edit;

    FUNCTION get_flg_status(i_id_epis_hhc_req IN epis_hhc_req.id_epis_hhc_req%TYPE) RETURN VARCHAR2 IS
        l_ret VARCHAR2(0010 CHAR);
    BEGIN
        SELECT flg_status
          INTO l_ret
          FROM v_epis_hhc_req v
         WHERE v.id_epis_hhc_req = i_id_epis_hhc_req;
    
        RETURN l_ret;
    
    EXCEPTION
        WHEN no_data_found THEN
            RETURN NULL;
        
    END get_flg_status;

    FUNCTION has_case_manager(i_id_epis_hhc_req IN epis_hhc_req.id_epis_hhc_req%TYPE) RETURN NUMBER IS
        l_ret NUMBER;
    BEGIN
    
        SELECT COUNT(*)
          INTO l_ret
          FROM v_epis_hhc_req ehr
         WHERE ehr.id_epis_hhc_req = i_id_epis_hhc_req
           AND ehr.id_prof_manager IS NOT NULL;
    
        RETURN l_ret;
    
    END has_case_manager;

    FUNCTION check_if_prof_can_discon
    (
        i_flg_status IN VARCHAR2,
        i_flg_mrp    IN VARCHAR2 DEFAULT NULL
    ) RETURN VARCHAR2 IS
    
        l_return             VARCHAR2(0100 CHAR);
        l_has_mrp_permission VARCHAR2(1000 CHAR);
        l_flg_status         VARCHAR2(1000 CHAR);
    BEGIN
    
        IF i_flg_mrp IS NULL
        THEN
            l_has_mrp_permission := k_no;
        ELSE
            l_has_mrp_permission := i_flg_mrp;
        END IF;
    
        l_flg_status := i_flg_status;
    
        l_return := k_no;
        IF l_has_mrp_permission = k_yes
        THEN
            IF l_flg_status IN (k_hhc_part_approved, k_hhc_in_evaluation, k_hhc_in_part_acc_wcm)
            THEN
                l_return := k_yes;
            END IF;
        END IF;
    
        RETURN l_return;
    
    END check_if_prof_can_discon;

    FUNCTION check_action_available
    (
        --    i_lang               IN NUMBER,
        --    i_prof               IN profissional,
        i_hhc_request        IN NUMBER,
        i_action_name        IN VARCHAR2,
        i_has_mrp_permission IN VARCHAR2
    ) RETURN VARCHAR2 IS
        l_flg_status VARCHAR2(0010 CHAR);
        l_return     VARCHAR2(0010 CHAR);
    BEGIN
    
        l_flg_status := get_flg_status(i_hhc_request);
    
        CASE i_action_name
            WHEN 'HHC_REQ_EDIT' THEN
                l_return := pk_hhc_core.check_if_prof_can_edit(i_flg_status => l_flg_status,
                                                               i_flg_mrp    => i_has_mrp_permission);
            WHEN 'HHC_REQ_CANCEL' THEN
                l_return := pk_hhc_core.check_if_prof_can_cancel(i_flg_status => l_flg_status,
                                                                 i_flg_mrp    => i_has_mrp_permission);
            WHEN 'HHC_REQ_DISCONTINUE' THEN
                l_return := pk_hhc_core.check_if_prof_can_discon(i_flg_status => l_flg_status,
                                                                 i_flg_mrp    => i_has_mrp_permission);
            ELSE
                l_return := k_no;
        END CASE;
    
        RETURN l_return;
    
    END check_action_available;

    FUNCTION check_action_avail_all_grid
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_action_name VARCHAR2,
        i_hhc_request IN NUMBER
    ) RETURN VARCHAR2 IS
        l_return         VARCHAR2(0010 CHAR);
        l_flg_status     VARCHAR2(0010 CHAR);
        l_is_coordinator VARCHAR2(0010 CHAR);
        --l_is_case_manager   VARCHAR2(0010 CHAR);
        l_has_case_manager  NUMBER;
        check_funcs_array   table_varchar := table_varchar('HHC_COORDINATOR', 'HHC_CASE_MANAGER');
        l_func_availability table_varchar := table_varchar();
    BEGIN
    
        l_flg_status       := get_flg_status(i_hhc_request);
        l_has_case_manager := has_case_manager(i_hhc_request);
    
        FOR i IN 1 .. check_funcs_array.count
        LOOP
            l_func_availability.extend;
            l_func_availability(i) := pk_prof_utils.check_has_functionality(i_lang        => i_lang,
                                                                            i_prof        => i_prof,
                                                                            i_intern_name => check_funcs_array(i));
        
        END LOOP;
    
        l_is_coordinator := l_func_availability(1);
        --l_is_case_manager := l_func_availability(2);
    
        IF l_is_coordinator = k_no
        THEN
            l_return := pk_alert_constant.g_inactive;
        ELSE
        
            CASE i_action_name
                WHEN 'HHC_REQ_ASSIG_CM' THEN
                    IF l_flg_status NOT IN
                       (k_hhc_requested, k_hhc_rejected, k_hhc_closed, k_hhc_discontinued, k_hhc_canceled)
                    THEN
                        l_return := pk_alert_constant.g_active;
                    
                    ELSE
                        l_return := pk_alert_constant.g_inactive;
                    END IF;
                
                WHEN 'HHC_REQ_REMOVE_CM' THEN
                    IF l_has_case_manager > 0
                       AND l_flg_status = k_hhc_part_approved
                    THEN
                        l_return := pk_alert_constant.g_active;
                    ELSE
                        l_return := pk_alert_constant.g_inactive;
                    END IF;
                
                ELSE
                    l_return := pk_alert_constant.g_inactive;
            END CASE;
        END IF;
        RETURN l_return;
    END check_action_avail_all_grid;

    FUNCTION has_team
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_hhc_req IN epis_hhc_req.id_epis_hhc_req%TYPE
    ) RETURN VARCHAR2 IS
        l_ret   VARCHAR2(1 CHAR) := pk_alert_constant.g_no;
        l_team  NUMBER;
        l_error t_error_out;
    BEGIN
    
        IF NOT pk_prof_teams.get_id_prof_team(i_lang         => i_lang,
                                              i_prof         => i_prof,
                                              i_id_hhc_req   => i_id_hhc_req,
                                              o_id_prof_team => l_team,
                                              o_error        => l_error)
        THEN
            l_team := NULL;
        END IF;
    
        IF l_team IS NOT NULL
        THEN
            l_ret := pk_alert_constant.g_yes;
        END IF;
    
        RETURN l_ret;
    
    END has_team;

    FUNCTION check_action_avail_referral
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_action_name     VARCHAR2,
        i_id_epis_hhc_req IN NUMBER
    ) RETURN VARCHAR2 IS
        l_return         VARCHAR2(0010 CHAR);
        l_flg_status     VARCHAR2(0010 CHAR);
        l_is_coordinator VARCHAR2(0010 CHAR);
        --l_is_case_manager     VARCHAR2(0010 CHAR);
        l_is_the_case_manager BOOLEAN;
        --l_has_case_manager    NUMBER;
        check_funcs_array   table_varchar := table_varchar('HHC_COORDINATOR', 'HHC_CASE_MANAGER');
        l_func_availability table_varchar := table_varchar();
        l_has_team          VARCHAR2(1 CHAR);
    BEGIN
    
        l_flg_status := get_flg_status(i_id_epis_hhc_req);
        --l_has_case_manager := has_case_manager(i_id_epis_hhc_req);
    
        FOR i IN 1 .. check_funcs_array.count
        LOOP
            l_func_availability.extend;
            l_func_availability(i) := pk_prof_utils.check_has_functionality(i_lang        => i_lang,
                                                                            i_prof        => i_prof,
                                                                            i_intern_name => check_funcs_array(i));
        
        END LOOP;
        l_has_team       := has_team(i_lang => i_lang, i_prof => i_prof, i_id_hhc_req => i_id_epis_hhc_req);
        l_is_coordinator := l_func_availability(1);
        --l_is_case_manager     := l_func_availability(2);
        l_is_the_case_manager := i_prof.id = get_id_case_manager_by_id_req(i_id_epis_hhc_req);
    
        CASE i_action_name
            WHEN 'HHC_REQUEST_PART_ACCEPT' THEN
                IF l_is_coordinator = k_yes
                   AND l_flg_status = k_hhc_requested
                THEN
                    l_return := pk_alert_constant.g_active;
                
                ELSE
                    l_return := pk_alert_constant.g_inactive;
                END IF;
            WHEN 'HHC_REQUEST_APPROVE' THEN
                IF l_flg_status IN (pk_hhc_constant.k_hhc_req_status_in_eval)
                   AND l_has_team = k_yes
                   AND l_is_the_case_manager
                THEN
                    l_return := pk_alert_constant.g_active;
                ELSE
                    l_return := pk_alert_constant.g_inactive;
                END IF;
            
            WHEN 'HHC_REQUEST_REJECT' THEN
                IF (l_is_coordinator = k_yes AND l_flg_status = k_hhc_requested)
                   OR (l_is_the_case_manager AND l_flg_status IN (k_hhc_requested, k_hhc_in_evaluation))
                THEN
                    l_return := pk_alert_constant.g_active;
                
                ELSE
                    l_return := pk_alert_constant.g_inactive;
                END IF;
            
            WHEN 'HHC_REQUEST_UNDO' THEN
                IF (l_is_coordinator = k_yes AND
                   l_flg_status IN (pk_hhc_constant.k_hhc_req_status_part_approved,
                                     pk_hhc_constant.k_hhc_req_status_rejected,
                                     pk_hhc_constant.k_hhc_req_stauts_part_acc_wcm))
                   OR (l_is_the_case_manager AND
                   l_flg_status IN
                   (pk_hhc_constant.k_hhc_req_status_approved, pk_hhc_constant.k_hhc_req_status_rejected))
                
                THEN
                    l_return := pk_alert_constant.g_active;
                
                ELSE
                    l_return := pk_alert_constant.g_inactive;
                END IF;
            WHEN 'HHC_REQUEST_EDIT' THEN
                IF l_flg_status IN (pk_hhc_constant.k_hhc_req_status_part_approved,
                                    pk_hhc_constant.k_hhc_req_status_rejected,
                                    pk_hhc_constant.k_hhc_req_stauts_part_acc_wcm)
                THEN
                    l_return := pk_alert_constant.g_active;
                
                ELSE
                    l_return := pk_alert_constant.g_inactive;
                END IF;
            ELSE
                l_return := pk_alert_constant.g_inactive;
        END CASE;
    
        RETURN l_return;
    END check_action_avail_referral;

    FUNCTION check_action_avail_hsa
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_action_name     VARCHAR2,
        i_id_epis_hhc_req IN NUMBER
    ) RETURN VARCHAR2 IS
        l_return         VARCHAR2(0010 CHAR);
        l_flg_status     VARCHAR2(0010 CHAR);
        l_is_coordinator VARCHAR2(0010 CHAR);
        --l_is_case_manager     VARCHAR2(0010 CHAR);
        --l_is_the_case_manager BOOLEAN;
        --l_has_case_manager    NUMBER;
        check_funcs_array   table_varchar := table_varchar('HHC_COORDINATOR');
        l_func_availability table_varchar := table_varchar();
    BEGIN
    
        l_flg_status := get_flg_status(i_id_epis_hhc_req);
        --l_has_case_manager := has_case_manager(i_id_epis_hhc_req);
    
        FOR i IN 1 .. check_funcs_array.count
        LOOP
            l_func_availability.extend;
            l_func_availability(i) := pk_prof_utils.check_has_functionality(i_lang        => i_lang,
                                                                            i_prof        => i_prof,
                                                                            i_intern_name => check_funcs_array(i));
        
        END LOOP;
    
        l_is_coordinator := l_func_availability(1);
    
        IF l_is_coordinator = k_no
        THEN
            l_return := pk_alert_constant.g_inactive;
        ELSE
        
            CASE i_action_name
                WHEN 'HHC_HSA_EDIT' THEN
                    IF l_flg_status IN (k_hhc_part_approved, k_hhc_in_part_acc_wcm, k_hhc_in_evaluation)
                    THEN
                        l_return := pk_alert_constant.g_active;
                    
                    ELSE
                        l_return := pk_alert_constant.g_inactive;
                    END IF;
                ELSE
                    l_return := pk_alert_constant.g_inactive;
            END CASE;
        END IF;
    
        RETURN l_return;
    END check_action_avail_hsa;

    FUNCTION check_active_action
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_action_name IN VARCHAR2,
        i_hhc_request IN NUMBER,
        i_subject     IN VARCHAR2
    ) RETURN VARCHAR2 IS
        l_return             VARCHAR2(0010 CHAR);
        l_has_mrp_permission VARCHAR2(0010 CHAR);
    BEGIN
    
        CASE i_subject
            WHEN 'HHC_REQUEST' THEN
                l_has_mrp_permission := get_prof_flg_mrp(i_lang => i_lang, i_prof => i_prof);
            
                l_return := pk_hhc_core.check_action_available(i_action_name        => i_action_name,
                                                               i_hhc_request        => i_hhc_request,
                                                               i_has_mrp_permission => l_has_mrp_permission);
            WHEN 'HHC_REQUEST_GRID_ALL' THEN
                l_return := pk_hhc_core.check_action_avail_all_grid(i_lang        => i_lang,
                                                                    i_prof        => i_prof,
                                                                    i_action_name => i_action_name,
                                                                    i_hhc_request => i_hhc_request);
            
            WHEN 'HHC_REQUEST_REFERRAL' THEN
                l_return := pk_hhc_core.check_action_avail_referral(i_lang            => i_lang,
                                                                    i_prof            => i_prof,
                                                                    i_action_name     => i_action_name,
                                                                    i_id_epis_hhc_req => i_hhc_request);
            
            WHEN 'HHC_PLAN' THEN
                l_return := pk_hhc_core.check_action_avail_plan(i_lang            => i_lang,
                                                                i_prof            => i_prof,
                                                                i_id_epis_hhc_req => i_hhc_request);
            
            WHEN 'HHC_HOME_SAFETY_ASSESS' THEN
                l_return := pk_hhc_core.check_action_avail_hsa(i_lang            => i_lang,
                                                               i_prof            => i_prof,
                                                               i_action_name     => i_action_name,
                                                               i_id_epis_hhc_req => i_hhc_request);
            
            ELSE
                l_return := NULL;
        END CASE;
    
        RETURN l_return;
    
    END check_active_action;

    -- ****************************************************
    FUNCTION save_adt_info
    (
        i_prof       IN profissional,
        i_id_patient IN NUMBER
    ) RETURN BOOLEAN IS
        l_bool BOOLEAN;
    BEGIN
    
        l_bool := pk_adt.save_caregiver_info(i_lang          => NULL,
                                             i_prof          => i_prof,
                                             i_id_patient    => i_id_patient,
                                             i_id_fam_rel    => tbl_adt_value(k_idx_family_relationship),
                                             i_fam_rel_spec  => tbl_adt_value(k_idx_family_rel_spec),
                                             i_firstname     => tbl_adt_value(k_idx_firstname),
                                             i_lastname      => tbl_adt_value(k_idx_lastname),
                                             i_othernames1   => tbl_adt_value(k_idx_othernames1),
                                             i_othernames3   => tbl_adt_value(k_idx_othernames3),
                                             i_phone_no      => tbl_adt_value(k_idx_phone_mobile),
                                             i_id_care_giver => tbl_adt_value(k_idx_id_care_giver));
    
        RETURN l_bool;
    
    END save_adt_info;

    FUNCTION get_actions
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_epis_hhc_req IN NUMBER,
        i_subject      IN VARCHAR2,
        o_actions      OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_func_name CONSTANT VARCHAR2(24 CHAR) := 'get_actions';
        l_params  VARCHAR2(1000 CHAR);
        l_actions t_coll_action;
    
    BEGIN
        -- init
        g_error := 'Init ' || l_func_name || ' / ' || l_params;
        -- l_has_mrp_permission := get_prof_flg_mrp(i_lang => i_lang, i_prof => i_prof);
        -- func
        -- all actions are listed in table action under subject HHC_REQUEST
        -- Each action is checked with function check_action_active
        g_error   := 'Call pk_action.tf_get_actions_permissions / ' || l_params;
        l_actions := pk_action.tf_get_actions(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_subject    => i_subject,
                                              i_from_state => NULL);
    
        g_error := 'OPEN o_list FOR / ' || l_params;
        OPEN o_actions FOR
            SELECT /*+opt_estimate (table t rows=1)*/
             t.id_action,
             t.id_parent,
             t.level_nr AS "LEVEL",
             t.from_state,
             t.to_state,
             t.desc_action,
             t.icon,
             t.flg_default,
             pk_hhc_core.check_active_action(i_lang        => i_lang,
                                             i_prof        => i_prof,
                                             i_action_name => t.action,
                                             i_hhc_request => i_epis_hhc_req,
                                             i_subject     => i_subject) flg_active,
             t.action
              FROM TABLE(CAST(l_actions AS t_coll_action)) t
             ORDER BY t.desc_action;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_actions);
            RETURN FALSE;
    END get_actions;

    -- *****************************************
    FUNCTION get_id_prof_request(i_epis_hhc_req IN NUMBER) RETURN NUMBER IS
        l_prof_id NUMBER;
    BEGIN
    
        l_prof_id := get_id_prof_status(i_epis_hhc_req => i_epis_hhc_req,
                                        i_flg_status   => pk_hhc_constant.k_hhc_req_status_requested,
                                        i_order        => 'ASC');
        RETURN l_prof_id;
    
    END get_id_prof_request;

    -- *****************************************
    FUNCTION get_id_prof_coordinator(i_epis_hhc_req IN NUMBER) RETURN NUMBER IS
        l_prof_id             NUMBER;
        l_coord_parc_accepted NUMBER;
        l_coord_rejected      NUMBER;
    BEGIN
    
        l_coord_parc_accepted := get_id_prof_status(i_epis_hhc_req => i_epis_hhc_req,
                                                    i_flg_status   => pk_hhc_constant.k_hhc_req_status_part_approved);
        l_coord_rejected      := get_id_prof_status(i_epis_hhc_req => i_epis_hhc_req,
                                                    i_flg_status   => pk_hhc_constant.k_hhc_req_status_rejected);
    
        IF l_coord_parc_accepted IS NOT NULL
        THEN
            l_prof_id := l_coord_parc_accepted;
        ELSIF l_coord_rejected IS NOT NULL
        THEN
            l_prof_id := l_coord_rejected;
        ELSE
            l_prof_id := NULL;
        END IF;
    
        RETURN l_prof_id;
    
    END get_id_prof_coordinator;

    -- *****************************************
    FUNCTION get_dt_request(i_epis_hhc_req IN NUMBER) RETURN v_epis_hhc_req_status.dt_status%TYPE IS
        l_return v_epis_hhc_req_status.dt_status%TYPE;
    BEGIN
    
        l_return := get_dt_status(i_epis_hhc_req => i_epis_hhc_req,
                                  i_flg_status   => pk_hhc_constant.k_hhc_req_status_requested);
        RETURN l_return;
    
    END get_dt_request;

    -- *****************************************
    FUNCTION get_dt_closed(i_epis_hhc_req IN NUMBER) RETURN v_epis_hhc_req_status.dt_status%TYPE IS
        l_return v_epis_hhc_req_status.dt_status%TYPE;
    BEGIN
    
        l_return := get_dt_status(i_epis_hhc_req => i_epis_hhc_req,
                                  i_flg_status   => pk_hhc_constant.k_hhc_req_status_closed);
        RETURN l_return;
    
    END get_dt_closed;

    -- *****************************************
    FUNCTION get_id_case_manager(i_epis_hhc IN epis_hhc_req.id_epis_hhc%TYPE) RETURN NUMBER IS
        l_return   NUMBER;
        tbl_return table_number;
    BEGIN
    
        SELECT hr.id_prof_manager
          BULK COLLECT
          INTO tbl_return
          FROM v_hhc_request hr
         WHERE hr.id_epis_hhc = i_epis_hhc
           AND hr.id_prof_manager IS NOT NULL;
    
        IF tbl_return.count > 0
        THEN
            l_return := tbl_return(1);
        END IF;
    
        RETURN l_return;
    
    END get_id_case_manager;
    -- *****************************************

    -- *****************************************
    FUNCTION get_id_case_manager_by_id_req(i_epis_hhc_req IN epis_hhc_req.id_epis_hhc_req%TYPE) RETURN NUMBER IS
        l_return   NUMBER;
        tbl_return table_number;
    BEGIN
    
        SELECT hr.id_prof_manager
          BULK COLLECT
          INTO tbl_return
          FROM v_hhc_request hr
         WHERE hr.id_epis_hhc_req = i_epis_hhc_req
           AND hr.id_prof_manager IS NOT NULL;
    
        IF tbl_return.count > 0
        THEN
            l_return := tbl_return(1);
        END IF;
    
        RETURN l_return;
    
    END get_id_case_manager_by_id_req;
    -- *****************************************
    FUNCTION get_prof_case_manager_list
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_epis_hhc         IN epis_hhc_req.id_epis_hhc%TYPE,
        o_id_prof_cmanager OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name        VARCHAR2(64) := 'GET_PROF_CASE_MANAGER_LIST';
        l_get_prof         table_number;
        l_intern_name_func sys_functionality.intern_name_func%TYPE := 'HHC_CASE_MANAGER';
        l_get_case_manager epis_hhc_req.id_prof_manager%TYPE;
    
    BEGIN
    
        l_get_prof := pk_prof_utils.get_prof_by_functionality(i_lang             => i_lang,
                                                              i_prof             => i_prof,
                                                              i_intern_name_func => l_intern_name_func);
    
        l_get_case_manager := pk_hhc_core.get_id_case_manager(i_epis_hhc => i_epis_hhc);
    
        OPEN o_id_prof_cmanager FOR
            SELECT gp.column_value prof_id,
                   pk_prof_utils.get_name(i_lang => i_lang, i_prof_id => gp.column_value) prof_name,
                   CASE l_get_case_manager
                       WHEN gp.column_value THEN
                        'Y'
                       ELSE
                        'N'
                   END flg_default
              FROM TABLE(l_get_prof) gp
             ORDER BY prof_name ASC;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_id_prof_cmanager);
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => 'ALERT',
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            RETURN FALSE;
        
    END get_prof_case_manager_list;

    FUNCTION get_types(i_internal_name_childs IN table_varchar) RETURN table_number IS
        l_ret table_number;
    BEGIN
    
        SELECT hdt.id_hhc_det_type
          BULK COLLECT
          INTO l_ret
          FROM hhc_det_type hdt
          JOIN (SELECT /*+ opt_estimate(table dc rows=1)  */
                 rownum rn, column_value internal_name
                  FROM TABLE(i_internal_name_childs) dcinc) inc
            ON inc.internal_name = hdt.internal_name
         ORDER BY inc.rn;
    
        RETURN l_ret;
    
    END get_types;

    FUNCTION get_internal_name_childs(i_tbl_mkt_rel IN table_number) RETURN table_varchar IS
        l_ret table_varchar;
    BEGIN
        SELECT dcm.internal_name_child
          BULK COLLECT
          INTO l_ret
          FROM v_ds_cmpt_mkt_rel dcm
          JOIN (SELECT /*+ opt_estimate(table dc rows=1)  */
                 rownum rn, column_value id
                  FROM TABLE(i_tbl_mkt_rel) dc) tmr
            ON tmr.id = dcm.id_ds_cmpt_mkt_rel
         WHERE dcm.id_ds_cmpt_mkt_rel NOT IN (3630, 3632)
        -- dont include toggle for translation
         ORDER BY tmr.rn;
    
        RETURN l_ret;
    
    END get_internal_name_childs;

    FUNCTION get_ds_components(i_tbl_mkt_rel IN table_number) RETURN table_number IS
        l_ret table_number;
    BEGIN
        SELECT dcm.id_ds_component_child
          BULK COLLECT
          INTO l_ret
          FROM v_ds_cmpt_mkt_rel dcm
          JOIN (SELECT /*+ opt_estimate(table dc rows=1)  */
                 rownum rn, column_value id
                  FROM TABLE(i_tbl_mkt_rel) dc) tmr
            ON tmr.id = dcm.id_ds_cmpt_mkt_rel
         ORDER BY tmr.rn;
    
        RETURN l_ret;
    
    END get_ds_components;

    PROCEDURE map_arrays
    (
        i_array IN table_varchar,
        o_array OUT table_varchar
    ) IS
        l_ret table_varchar := table_varchar();
    BEGIN
    
        <<lup_thru_i_array>>
        FOR i IN 1 .. i_array.count
        LOOP
            l_ret.extend(1);
            l_ret(i) := i_array(i);
        END LOOP lup_thru_i_array;
    
        o_array := l_ret;
    
    END map_arrays;

    FUNCTION tf_map_values_hhc
    (
        i_tbl_mkt_rel IN table_number,
        i_value       IN table_table_varchar
    ) RETURN t_hhc_req IS
    
        l_tbl_internal_name_childs table_varchar;
        l_plan_care                table_varchar := table_varchar();
        l_problems                 table_varchar := table_varchar();
        l_invest_lab               table_varchar := table_varchar();
        l_invest_exam              table_varchar := table_varchar();
        l_value_row                table_varchar;
    
        l_hhc_req t_hhc_req;
    
    BEGIN
    
        l_tbl_internal_name_childs := get_internal_name_childs(i_tbl_mkt_rel);
    
        <<lup_thru_tbl_int_name_childs>>
        FOR i IN 1 .. l_tbl_internal_name_childs.count
        LOOP
            l_value_row := i_value(i);
            CASE l_tbl_internal_name_childs(i)
                WHEN 'DS_HHC_REFERRAL_TYPE' THEN
                    l_hhc_req.l_referral_type := l_value_row(i);
                WHEN 'DS_HHC_REFERRAL_ORIGIN' THEN
                    l_hhc_req.l_referral_origin := l_value_row(i);
                WHEN 'DS_HHC_MEDICAL_HISTORY' THEN
                    l_hhc_req.l_medical_history := l_value_row(i);
                WHEN 'DS_HHC_PROBLEMS' THEN
                    map_arrays(l_value_row, l_problems);
                WHEN 'DS_HHC_VACCINES' THEN
                    l_hhc_req.l_vaccines := l_value_row(i);
                WHEN 'DS_HHC_CARE_PLAN' THEN
                    map_arrays(l_value_row, l_plan_care);
                WHEN 'DS_HHC_SUPPLIES' THEN
                    l_hhc_req.l_supply := l_value_row(i);
                WHEN 'DS_HHC_IV_REFERRAL_REQUIRED' THEN
                    l_hhc_req.l_referral_required := l_value_row(i);
                WHEN 'DS_HHC_IV_PHARM_ASSESSED' THEN
                    l_hhc_req.l_referral_pharm := l_value_row(i);
                WHEN 'DS_HHC_IV_INF_CONTROL_DONE' THEN
                    l_hhc_req.l_inf_control := l_value_row(i);
                WHEN 'DS_HHC_INVESTIGATION_LAB' THEN
                    map_arrays(l_value_row, l_invest_lab);
                WHEN 'DS_HHC_INVESTIGATION_EXAM' THEN
                    map_arrays(l_value_row, l_invest_exam);
                WHEN 'DS_HHC_CARE_GIVER_NAME' THEN
                    l_hhc_req.l_care_giver_name := l_value_row(i);
                WHEN 'DS_HHC_CARE_GIVER_CONTACT_NUM' THEN
                    l_hhc_req.l_care_giver_number := l_value_row(i);
                WHEN 'DS_HHC_PROF_IN_CHARGE_NAME' THEN
                    l_hhc_req.l_consult_name := l_value_row(i);
                WHEN 'DS_HHC_PROF_IN_CHARGE_MOBILE_NUM' THEN
                    l_hhc_req.l_consult_number := l_value_row(i);
                WHEN 'DS_FAMILY_RELATIONSHIP' THEN
                    l_hhc_req.l_family_relationship := l_value_row(i);
                WHEN 'DS_FIRSTNAME' THEN
                    l_hhc_req.l_firstname := l_value_row(i);
                WHEN 'DS_OTHERNAMES1' THEN
                    l_hhc_req.l_othernames1 := l_value_row(i);
                WHEN 'DS_LASTNAME' THEN
                    l_hhc_req.l_lastname := l_value_row(i);
                WHEN 'DS_OTHERNAMES3' THEN
                    l_hhc_req.l_othernames3 := l_value_row(i);
                WHEN 'DS_PHONE_MOBILE' THEN
                    l_hhc_req.l_phone_mobile := l_value_row(i);
                ELSE
                
                    l_hhc_req := NULL;
                
            END CASE;
        
        END LOOP lup_thru_tbl_int_name_childs;
    
        -- define arrays
        l_hhc_req.l_plan_care          := l_plan_care;
        l_hhc_req.l_problems           := l_problems;
        l_hhc_req.l_investigation_exam := l_invest_exam;
        l_hhc_req.l_investigation_lab  := l_invest_lab;
    
        RETURN l_hhc_req;
    
    END tf_map_values_hhc;

    PROCEDURE ins_req_internal
    (
        i_id_epis_hhc_req  IN epis_hhc_req.id_epis_hhc_req%TYPE,
        i_prof             IN profissional,
        i_id_patient       IN NUMBER,
        i_id_episode       IN episode.id_episode%TYPE,
        i_flg_status       IN VARCHAR2,
        i_id_cancel_reason IN NUMBER,
        i_cancel_notes     IN CLOB,
        i_hhc_process      IN NUMBER
    ) IS
    BEGIN
    
        INSERT INTO v_epis_hhc_req
            (id_epis_hhc_req,
             id_patient,
             id_episode,
             id_prof_manager,
             dt_prof_manager,
             flg_status,
             id_cancel_reason,
             cancel_notes,
             id_epis_hhc)
        VALUES
            (i_id_epis_hhc_req,
             i_id_patient,
             i_id_episode,
             i_prof.id,
             NULL,
             i_flg_status,
             i_id_cancel_reason,
             i_cancel_notes,
             i_hhc_process);
    
    END ins_req_internal;

    FUNCTION upd_req_status_flg_status
    (
        i_id_epis_hhc_req IN epis_hhc_req.id_epis_hhc_req%TYPE,
        i_flg_status      IN VARCHAR2 DEFAULT NULL,
        i_dt_status       IN TIMESTAMP WITH LOCAL TIME ZONE
    ) RETURN BOOLEAN IS
    
    BEGIN
        UPDATE v_epis_hhc_req_status v
           SET v.flg_status = i_flg_status
         WHERE v.id_epis_hhc_req = i_id_epis_hhc_req
           AND v.flg_status = i_flg_status
           AND v.dt_status = i_dt_status;
    
        RETURN TRUE;
    
    END upd_req_status_flg_status;

    FUNCTION upd_req_status_general
    (
        i_id_epis_hhc_req IN epis_hhc_req_status.id_epis_hhc_req %TYPE,
        i_id_professional IN professional.id_professional%TYPE DEFAULT NULL,
        i_flg_status      IN VARCHAR2,
        i_dt_status       IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_id_reason       IN NUMBER DEFAULT NULL,
        i_reason_notes    IN CLOB DEFAULT NULL,
        i_what_2_upd      IN VARCHAR2
    ) RETURN BOOLEAN IS
    
        l_ret BOOLEAN;
    
    BEGIN
    
        CASE i_what_2_upd
        /*acrescentar mais estados à medida do necessário*/
            WHEN 'FLG_STATUS' THEN
                l_ret := upd_req_status_flg_status(i_id_epis_hhc_req => i_id_epis_hhc_req,
                                                   i_flg_status      => i_flg_status,
                                                   i_dt_status       => i_dt_status);
            
            WHEN 'FLG_UNDONE' THEN
                l_ret := upd_flg_undone(i_id_epis_hhc_req => i_id_epis_hhc_req,
                                        i_flg_status      => i_flg_status,
                                        i_dt_status       => i_dt_status);
            
            ELSE
                l_ret := TRUE;
        END CASE;
    
        RETURN l_ret;
    
    END upd_req_status_general;

    FUNCTION ins_req_status
    (
        i_id_epis_hhc_req  IN epis_hhc_req.id_epis_hhc_req%TYPE,
        i_id_professional  IN professional.id_professional%TYPE,
        i_flg_status       IN VARCHAR2,
        i_id_cancel_reason IN epis_hhc_req.id_cancel_reason%TYPE,
        i_cancel_notes     IN epis_hhc_req.cancel_notes%TYPE
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        INSERT INTO v_epis_hhc_req_status
            (id_epis_hhc_req, id_professional, flg_status, dt_status, id_reason, reason_notes)
        VALUES
            (i_id_epis_hhc_req, i_id_professional, i_flg_status, current_timestamp, i_id_cancel_reason, i_cancel_notes);
    
        RETURN TRUE;
    
    END ins_req_status;

    FUNCTION upd_req_internal
    (
        i_id_epis_hhc_req  IN epis_hhc_req.id_epis_hhc_req%TYPE,
        i_prof             IN profissional,
        i_flg_status       IN VARCHAR2,
        i_id_cancel_reason IN NUMBER,
        i_cancel_notes     IN CLOB
    ) RETURN BOOLEAN IS
        l_ret BOOLEAN;
    BEGIN
    
        IF i_flg_status IS NOT NULL
        THEN
            -- update status
            UPDATE v_epis_hhc_req ehr
               SET ehr.flg_status       = i_flg_status,
                   ehr.id_prof_manager  = i_prof.id,
                   ehr.id_cancel_reason = i_id_cancel_reason,
                   ehr.cancel_notes     = i_cancel_notes
             WHERE ehr.id_epis_hhc_req = i_id_epis_hhc_req;
        
            l_ret := ins_req_status(i_id_epis_hhc_req, i_prof.id, i_flg_status, i_id_cancel_reason, i_cancel_notes);
        ELSE
            -- upd case manager
            UPDATE v_epis_hhc_req ehr
               SET ehr.id_prof_manager  = i_prof.id,
                   ehr.id_cancel_reason = i_id_cancel_reason,
                   ehr.cancel_notes     = i_cancel_notes
             WHERE ehr.id_epis_hhc_req = i_id_epis_hhc_req;
        END IF;
    
        RETURN l_ret;
    
    END upd_req_internal;

    PROCEDURE del_req_det(i_id_epis_hhc_req IN epis_hhc_req.id_epis_hhc_req%TYPE) IS
    
    BEGIN
        DELETE epis_hhc_req_det ehrd
         WHERE ehrd.id_epis_hhc_req = i_id_epis_hhc_req;
    END del_req_det;

    PROCEDURE ins_req_det_internal
    (
        i_id_epis_hhc_req     IN epis_hhc_req.id_epis_hhc_req%TYPE,
        i_id_epis_hhc_req_det IN epis_hhc_req_det.id_epis_hhc_req_det%TYPE,
        i_hhc_value           IN VARCHAR2,
        i_hhc_text            IN CLOB,
        i_id_type             IN hhc_det_type.id_hhc_det_type%TYPE,
        i_id_prof_creation    IN professional.id_professional%TYPE
    ) IS
    
    BEGIN
    
        INSERT INTO v_epis_hhc_req_det
            (id_epis_hhc_req_det, id_epis_hhc_req, id_hhc_det_type, hhc_value, hhc_text, id_prof_creation)
        VALUES
            (i_id_epis_hhc_req_det, i_id_epis_hhc_req, i_id_type, i_hhc_value, i_hhc_text, i_id_prof_creation);
    
    END ins_req_det_internal;

    PROCEDURE ins_req_det_hist
    (
        i_prof                IN profissional,
        i_id_epis_hhc_req     IN epis_hhc_req.id_epis_hhc_req%TYPE,
        i_id_epis_hhc_req_det IN epis_hhc_req_det.id_epis_hhc_req_det%TYPE,
        i_hhc_value           IN VARCHAR2,
        i_hhc_text            IN CLOB,
        i_id_type             IN hhc_det_type.id_hhc_det_type%TYPE,
        i_aggregator          IN NUMBER
    ) IS
    BEGIN
    
        INSERT INTO v_epis_hhc_req_det_h
            (id_epis_hhc_req_det,
             id_prof_creation,
             dt_creation,
             id_epis_hhc_req,
             id_hhc_det_type,
             hhc_value,
             hhc_text,
             id_group)
        VALUES
            (i_id_epis_hhc_req_det,
             i_prof.id,
             current_timestamp,
             i_id_epis_hhc_req,
             i_id_type,
             i_hhc_value,
             i_hhc_text,
             i_aggregator);
    
    END ins_req_det_hist;

    FUNCTION ins_req_det
    (
        i_prof                 IN profissional,
        i_id_epis_hhc_req      IN epis_hhc_req.id_epis_hhc_req%TYPE,
        i_internal_name_childs IN VARCHAR2,
        i_value                IN table_varchar,
        i_value_clob           IN CLOB,
        i_id_type              IN hhc_det_type.id_hhc_det_type%TYPE,
        i_seq_hhc_req_det_grp  IN NUMBER
    ) RETURN BOOLEAN IS
        l_flg_type            VARCHAR2(100);
        l_id_epis_hhc_req_det NUMBER;
        --l_value               VARCHAR2(4000);
        --l_value_lob           CLOB;
    
    BEGIN
    
        SELECT hdt.flg_type
          INTO l_flg_type
          FROM v_hhc_det_type hdt
         WHERE hdt.id_hhc_det_type = i_id_type;
    
        <<lup_thru_values>>
        FOR i IN 1 .. i_value.count
        LOOP
            l_id_epis_hhc_req_det := seq_epis_hhc_req_det.nextval;
            CASE l_flg_type
                WHEN pk_hhc_constant.k_hhc_type_text THEN
                
                    ins_req_det_internal(i_id_epis_hhc_req,
                                         l_id_epis_hhc_req_det,
                                         i_value(i),
                                         i_value_clob,
                                         i_id_type,
                                         i_prof.id);
                
                ELSE
                    ins_req_det_internal(i_id_epis_hhc_req,
                                         l_id_epis_hhc_req_det,
                                         i_value(i),
                                         NULL,
                                         i_id_type,
                                         i_prof.id);
            END CASE;
        
            ins_req_det_hist(i_prof,
                             i_id_epis_hhc_req,
                             l_id_epis_hhc_req_det,
                             i_value(i),
                             i_value_clob,
                             i_id_type,
                             i_seq_hhc_req_det_grp);
        
        END LOOP lup_thru_values;
    
        RETURN TRUE;
    
    END ins_req_det;

    FUNCTION set_epis_hhc_req_det
    (
        i_prof                 IN profissional,
        i_id_patient           IN patient.id_patient%TYPE,
        i_internal_name_childs IN table_varchar,
        i_value                IN table_table_varchar,
        i_value_clob           IN table_clob,
        i_id_types             IN table_number,
        i_flg_status           IN VARCHAR2, -- send 'C' if it's a creation , 'E' if it's an edit
        i_id_epis_hhc_req      IN epis_hhc_req.id_epis_hhc_req%TYPE
    ) RETURN BOOLEAN IS
    
        l_ret                  BOOLEAN;
        l_seq_hhc_req_det_grp  NUMBER;
        l_internal_name_childs VARCHAR2(4000);
        l_value                table_varchar := table_varchar();
        l_value_clob           CLOB;
        l_id_types             NUMBER;
    
    BEGIN
    
        /*VALIDATE ARGUMENTS*/
        reset_tbl_adt();
    
        IF i_flg_status = pk_hhc_constant.k_hhc_row_dml_edit
        THEN
            del_req_det(i_id_epis_hhc_req);
        END IF;
        l_seq_hhc_req_det_grp := seq_hhc_req_det_grp.nextval;
    
        <<lup_thru_values>>
    
        FOR i IN 1 .. i_internal_name_childs.count
        LOOP
        
            l_internal_name_childs := i_internal_name_childs(i);
            l_value                := i_value(i);
            l_value_clob           := i_value_clob(i);
            l_id_types             := i_id_types(i);
        
            IF i_flg_status = pk_hhc_constant.k_hhc_row_dml_create
            THEN
                push_comp_value(l_internal_name_childs, l_value);
            END IF;
        
            l_ret := ins_req_det(i_prof,
                                 i_id_epis_hhc_req,
                                 l_internal_name_childs,
                                 l_value,
                                 l_value_clob,
                                 l_id_types,
                                 l_seq_hhc_req_det_grp);
        
        END LOOP lup_thru_values;
    
        IF i_flg_status = pk_hhc_constant.k_hhc_row_dml_create
        THEN
            IF l_ret
            THEN
                l_ret := save_adt_info(i_prof => i_prof, i_id_patient => i_id_patient);
            END IF;
        END IF;
    
        RETURN l_ret;
    
    END set_epis_hhc_req_det;

    PROCEDURE ins_req_hist
    (
        i_id_epis_hhc_req     IN epis_hhc_req.id_epis_hhc_req%TYPE,
        i_prof                IN profissional,
        i_id_patient          IN NUMBER,
        i_id_episode          IN episode.id_episode%TYPE,
        i_flg_status          IN VARCHAR2,
        i_id_cancel_reason    IN NUMBER,
        i_cancel_notes        IN CLOB,
        i_hhc_process         IN NUMBER,
        i_id_prof_manager     IN epis_hhc_req.id_prof_manager%TYPE,
        i_dt_prof_manager     IN epis_hhc_req.dt_prof_manager%TYPE,
        i_id_prof_coordinator IN epis_hhc_req.id_prof_coordinator%TYPE
    ) IS
    BEGIN
    
        INSERT INTO v_epis_hhc_req_h
            (id_epis_hhc_req,
             id_prof_creation,
             dt_creation,
             id_patient,
             id_episode,
             id_prof_manager,
             dt_prof_manager,
             flg_status,
             id_cancel_reason,
             cancel_notes,
             id_epis_hhc,
             id_prof_coordinator)
        VALUES
            (i_id_epis_hhc_req,
             i_prof.id,
             current_timestamp,
             i_id_patient,
             i_id_episode,
             i_id_prof_manager,
             i_dt_prof_manager,
             i_flg_status,
             i_id_cancel_reason,
             i_cancel_notes,
             i_hhc_process,
             i_id_prof_coordinator);
    
    END ins_req_hist;

    FUNCTION ins_req
    (
        i_id_epis_hhc_req  IN epis_hhc_req.id_epis_hhc_req%TYPE,
        i_prof             IN profissional,
        i_id_patient       IN NUMBER,
        i_id_episode       IN episode.id_episode%TYPE,
        i_flg_status       IN VARCHAR2,
        i_id_cancel_reason IN NUMBER,
        i_cancel_notes     IN CLOB,
        i_hhc_process      IN NUMBER
    ) RETURN BOOLEAN IS
    BEGIN
    
        ins_req_internal(i_id_epis_hhc_req,
                         NULL,
                         i_id_patient,
                         i_id_episode,
                         i_flg_status,
                         i_id_cancel_reason,
                         i_cancel_notes,
                         i_hhc_process);
    
        ins_req_hist(i_id_epis_hhc_req,
                     i_prof,
                     i_id_patient,
                     i_id_episode,
                     i_flg_status,
                     i_id_cancel_reason,
                     i_cancel_notes,
                     i_hhc_process,
                     NULL,
                     NULL,
                     NULL);
    
        RETURN TRUE;
    
    END ins_req;

    FUNCTION set_req_status
    (
        i_id_epis_hhc_req IN epis_hhc_req.id_epis_hhc_req%TYPE,
        i_prof            IN profissional,
        i_flg_status      IN VARCHAR2
    ) RETURN BOOLEAN IS
        l_curr_flg_status VARCHAR2(1);
        l_ret             BOOLEAN;
    BEGIN
    
        -- see if it's necessary the update
        SELECT e.flg_status
          INTO l_curr_flg_status
          FROM v_epis_hhc_req e
         WHERE e.id_epis_hhc_req = i_id_epis_hhc_req;
    
        l_ret := l_curr_flg_status = i_flg_status;
    
        IF NOT l_ret
        THEN
            l_ret := pk_hhc_core.upd_epis_req(i_prof                => i_prof,
                                              i_id_epis_hhc_req     => i_id_epis_hhc_req,
                                              i_flg_status          => i_flg_status,
                                              i_id_prof_manager     => NULL,
                                              i_dt_prof_manager     => NULL,
                                              i_id_prof_coordinator => NULL,
                                              i_id_cancel_reason    => NULL,
                                              i_cancel_notes        => NULL);
        END IF;
    
        RETURN l_ret;
    
    END set_req_status;

    FUNCTION set_prof_manager
    (
        i_id_epis_hhc_req IN epis_hhc_req.id_epis_hhc_req%TYPE,
        i_prof            IN profissional
        --, i_id_episode      IN episode.id_episode%TYPE
    ) RETURN BOOLEAN IS
        l_curr_prof_manager NUMBER;
        l_ret               BOOLEAN;
    BEGIN
    
        -- see if it's necessary the update
        SELECT e.id_prof_manager
          INTO l_curr_prof_manager
          FROM v_epis_hhc_req e
         WHERE e.id_epis_hhc_req = i_id_epis_hhc_req;
    
        l_ret := l_curr_prof_manager = i_prof.id;
        IF NOT l_ret
        THEN
            l_ret := pk_hhc_core.upd_epis_req(i_prof                => i_prof,
                                              i_id_epis_hhc_req     => i_id_epis_hhc_req,
                                              i_flg_status          => NULL,
                                              i_id_prof_manager     => i_prof.id,
                                              i_dt_prof_manager     => current_timestamp,
                                              i_id_prof_coordinator => NULL,
                                              i_id_cancel_reason    => NULL,
                                              i_cancel_notes        => NULL);
        END IF;
    
        RETURN l_ret;
    
    END set_prof_manager;

    FUNCTION validate_args
    (
        i_internal_name_childs IN table_varchar,
        i_value                IN table_table_varchar,
        i_id_types             IN table_number
    ) RETURN BOOLEAN IS
        l_ret                   BOOLEAN;
        l_count_int_name_childs NUMBER := i_internal_name_childs.count;
        l_count_value           NUMBER := i_value.count;
        l_count_types           NUMBER := i_id_types.count;
    BEGIN
    
        CASE
            WHEN l_count_int_name_childs != l_count_value THEN
                l_ret := FALSE;
            WHEN l_count_int_name_childs != l_count_types THEN
                l_ret := FALSE;
            WHEN l_count_value != l_count_types THEN
                l_ret := FALSE;
            ELSE
                l_ret := TRUE;
        END CASE;
    
        RETURN l_ret;
    
    END validate_args;

    FUNCTION set_epis_hhc_req
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_id_episode           IN episode.id_episode%TYPE,
        i_id_patient           IN patient.id_patient%TYPE,
        i_id_epis_hhc_req      IN NUMBER,
        i_internal_name_childs IN table_varchar,
        i_value                IN table_table_varchar,
        i_value_clob           IN table_clob,
        i_id_types             IN table_number,
        o_id_epis_hhc_req      OUT NUMBER
    ) RETURN BOOLEAN IS
    
        l_ret             BOOLEAN := FALSE;
        l_id_epis_hhc_req NUMBER := i_id_epis_hhc_req;
        l_flg_status      VARCHAR2(1);
        l_hhc_process     NUMBER;
        l_alert_error     t_error_out;
    BEGIN
        IF l_id_epis_hhc_req IS NULL
        THEN
            -- it's a creation
        
            l_id_epis_hhc_req := seq_epis_hhc_req.nextval;
            l_flg_status      := pk_hhc_constant.k_hhc_req_status_requested;
        
            l_hhc_process := create_hhc_process(i_prof => i_prof,
                                                --i_hhc_req    => l_id_epis_hhc_req,
                                                i_id_patient => i_id_patient);
        
            l_ret := ins_req(l_id_epis_hhc_req,
                             i_prof,
                             i_id_patient,
                             i_id_episode,
                             l_flg_status,
                             NULL,
                             NULL,
                             l_hhc_process);
        
            l_ret := ins_req_status(l_id_epis_hhc_req, i_prof.id, l_flg_status, NULL, NULL);
        
            l_ret := set_epis_hhc_req_det( --i_lang,
                                          i_prof,
                                          --i_id_episode,
                                          i_id_patient,
                                          i_internal_name_childs,
                                          i_value,
                                          i_value_clob,
                                          i_id_types,
                                          pk_hhc_constant.k_hhc_row_dml_create,
                                          l_id_epis_hhc_req);
        
        ELSE
            l_flg_status := pk_hhc_constant.k_hhc_req_status_requested;
        
            -- care giver
            l_ret := set_prof_manager(l_id_epis_hhc_req, i_prof); --, i_id_episode);
        
            -- status
            l_ret := set_req_status(l_id_epis_hhc_req, i_prof, l_flg_status);
        
            l_ret := set_epis_hhc_req_det(i_prof,
                                          i_id_patient,
                                          i_internal_name_childs,
                                          i_value,
                                          i_value_clob,
                                          i_id_types,
                                          pk_hhc_constant.k_hhc_row_dml_edit,
                                          l_id_epis_hhc_req);
        
        END IF;
    
        o_id_epis_hhc_req := l_id_epis_hhc_req;
    
        l_ret := set_new_hhc_referral_alert(i_lang         => i_lang,
                                            i_prof         => i_prof,
                                            i_epis_hhc_req => l_id_epis_hhc_req,
                                            i_episode      => i_id_episode,
                                            o_error        => l_alert_error);
    
        RETURN l_ret;
    
    END set_epis_hhc_req;

    FUNCTION save_hhc_request
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_episode    IN episode.id_episode%TYPE,
        i_id_patient    IN patient.id_patient%TYPE,
        id_epis_hhc_req IN epis_hhc_req.id_epis_hhc_req%TYPE,
        i_tbl_mkt_rel   IN table_number,
        i_value         IN table_table_varchar,
        i_value_clob    IN table_clob,
        o_result        OUT NUMBER,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_ret BOOLEAN := FALSE;
        --l_bool_alert BOOLEAN;
        --l_val        BOOLEAN;
        --l_error VARCHAR2(1000 CHAR);
    
        l_internal_names table_varchar;
        l_id_types       table_number;
    
        --l_alert_error t_error_out;
    
        --l_id_epis_hhc_req NUMBER;
    
        e_wrong_args_exception EXCEPTION;
    
        l_func_name VARCHAR2(1000) := 'save_hhc_request';
        --l_count     NUMBER;
    
    BEGIN
    
        --l_count := i_value_clob.count;
        pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
    
        -- mapping values
        --l_error          := 'get_internal_name_childs';
        l_internal_names := get_internal_name_childs(i_tbl_mkt_rel);
    
        --l_error    := 'get_types';
        l_id_types := get_types(l_internal_names);
    
        --l_error := 'set_epis_hhc_req';
        l_ret := set_epis_hhc_req(i_lang,
                                  i_prof,
                                  i_id_episode,
                                  i_id_patient,
                                  id_epis_hhc_req,
                                  l_internal_names,
                                  i_value,
                                  i_value_clob,
                                  l_id_types,
                                  o_result);
    
        RETURN l_ret;
    
    EXCEPTION
        WHEN e_wrong_args_exception THEN
            g_error := 'Wrong args';
            pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'SAVE_HHC_REQUEST',
                                              o_error);
            RETURN FALSE;
    END save_hhc_request;
    --
    --função para devolver o texto a colocar como assinatura da alteração
    FUNCTION get_prof_signature
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_prof_sign IN epis_hhc_req_det_h.id_prof_creation%TYPE,
        i_date         IN epis_hhc_req_det_h.dt_creation%TYPE
    ) RETURN VARCHAR2 IS
        l_signature VARCHAR2(200);
    BEGIN
    
        l_signature := pk_prof_utils.get_detail_signature(i_lang                => i_lang,
                                                          i_prof                => i_prof,
                                                          i_id_episode          => NULL,
                                                          i_date_last_change    => NULL,
                                                          i_id_prof_last_change => i_id_prof_sign) ||
                       pk_date_utils.date_char_tsz(i_lang, i_date, i_prof.institution, i_prof.software);
    
        RETURN l_signature;
    
    END get_prof_signature;
    --
    --obtem a descrição do componente através do id
    FUNCTION get_cmpt_desc_by_id
    (
        i_lang                IN language.id_language%TYPE,
        i_id_component_parent IN ds_component.id_ds_component%TYPE
    ) RETURN VARCHAR IS
        l_text   sys_message.desc_message%TYPE;
        tbl_text table_varchar;
    BEGIN
    
        SELECT dc.code_ds_component
          BULK COLLECT
          INTO tbl_text
          FROM v_ds_component dc
         WHERE dc.id_ds_component = i_id_component_parent;
    
        IF tbl_text.count > 0
        THEN
            l_text := tbl_text(1);
        END IF;
    
        l_text := pk_message.get_message(i_lang, l_text);
    
        RETURN l_text;
    
    END get_cmpt_desc_by_id;
    --
    --get the desc of cancel reason
    FUNCTION get_desc_cancel_reason
    (
        i_id_epis_hhc_req    IN epis_hhc_req.id_epis_hhc_req%TYPE,
        o_desc_cancel_reason OUT VARCHAR2,
        o_cancel_notes       OUT CLOB
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        SELECT pk_translation.get_translation(8, cr.code_cancel_reason), rs.cancel_notes
          INTO o_desc_cancel_reason, o_cancel_notes
          FROM epis_hhc_req rs
          LEFT JOIN cancel_reason cr
            ON rs.id_cancel_reason = cr.id_cancel_reason
         WHERE rs.id_epis_hhc_req = i_id_epis_hhc_req;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN no_data_found THEN
            o_desc_cancel_reason := NULL;
            o_cancel_notes       := NULL;
            RETURN FALSE;
    END get_desc_cancel_reason;
    --get details from creation hhc request
    FUNCTION get_hhc_req_det_create
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_root_name     IN ds_component.internal_name%TYPE,
        i_id_request    IN epis_hhc_req.id_epis_hhc_req%TYPE,
        i_id_group      IN epis_hhc_req_det_h.id_group%TYPE,
        i_flg_report    IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        o_detail_create OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
        CURSOR c_components
        (
            i_lang       IN language.id_language%TYPE,
            i_prof       IN profissional,
            i_id_request IN epis_hhc_req.id_epis_hhc_req%TYPE,
            i_components IN t_dyn_tree_table
        ) IS
            SELECT pk_message.get_message(i_lang => i_lang, i_code_mess => code_ds_component) descr,
                   rank,
                   id_ds_component_parent,
                   flg_type,
                   flg_data_type,
                   internal_name,
                   position
              FROM (SELECT DISTINCT dc.code_ds_component,
                                    xsql.rank,
                                    xsql.id_ds_component_parent,
                                    hdt.flg_type,
                                    dc.flg_data_type,
                                    hdt.internal_name,
                                    xsql.position
                      FROM (SELECT /*+ opt_estimate(table t rows=1) */
                             t.*
                              FROM TABLE(i_components) t) xsql
                      JOIN v_ds_component dc
                        ON dc.id_ds_component = xsql.id_ds_component_child
                      JOIN v_hhc_det_type hdt
                        ON hdt.internal_name = xsql.internal_name_child
                      JOIN v_epis_hhc_req_det_h ehrdh
                        ON ehrdh.id_hhc_det_type = hdt.id_hhc_det_type
                      JOIN v_epis_hhc_req ehr
                        ON ehr.id_epis_hhc_req = ehrdh.id_epis_hhc_req
                     WHERE ehrdh.id_epis_hhc_req = i_id_request
                       AND ehrdh.id_group = i_id_group
                       AND xsql.flg_component_type_child = 'L'
                       AND (dbms_lob.compare(ehrdh.hhc_text, empty_clob()) != 0 OR ehrdh.hhc_value IS NOT NULL)
                       AND hdt.internal_name != pk_hhc_constant.k_ds_adt_id_care_giver)
             ORDER BY rank, position, id_ds_component_parent;
    
        CURSOR c_data
        (
            i_lang          IN language.id_language%TYPE,
            i_prof          IN profissional,
            i_id_request    IN epis_hhc_req.id_epis_hhc_req%TYPE,
            i_components    IN t_dyn_tree_table,
            i_internal_name IN hhc_det_type.internal_name%TYPE,
            i_id_group      IN epis_hhc_req_det_h.id_group%TYPE
        ) IS
            SELECT pk_hhc_core.get_detail_description(i_lang, i_prof, hdt.flg_type, hdt.type_name, ehrd.hhc_value) val_text,
                   ehrd.hhc_text val_clob,
                   hdt.flg_type
              FROM v_hhc_det_type hdt
              JOIN v_epis_hhc_req_det_h ehrd
                ON ehrd.id_hhc_det_type = hdt.id_hhc_det_type
             WHERE ehrd.id_epis_hhc_req = i_id_request
               AND ehrd.id_group = i_id_group
               AND hdt.internal_name = i_internal_name;
    
        l_signature                  VARCHAR2(200 CHAR);
        l_update_user                epis_hhc_req.update_user%TYPE;
        l_update_time                epis_hhc_req.update_time%TYPE;
        l_components                 t_dyn_tree_table;
        l_req_det                    t_coll_hhc_req_hist := t_coll_hhc_req_hist();
        index_t                      NUMBER := 1;
        l_old_id_ds_component_parent ds_component.id_ds_component%TYPE := 0;
        l_func_name CONSTANT VARCHAR2(15 CHAR) := 'get_hhc_req_det';
        l_desc               sys_message.desc_message%TYPE;
        l_val                CLOB;
        l_type               VARCHAR2(3 CHAR);
        l_flg_status         epis_hhc_req.flg_status%TYPE;
        l_desc_cancel_reason translation.desc_lang_8%TYPE;
        l_cancel_notes       CLOB;
        l_internal_error EXCEPTION;
    BEGIN
        --get components of dynamic screen
        g_error      := 'GET COMPONENTS FOR ' || i_root_name;
        l_components := pk_dyn_form.get_dyn_cfg(i_lang           => i_lang,
                                                i_prof           => i_prof,
                                                i_patient        => NULL,
                                                i_component_name => i_root_name,
                                                i_action         => NULL);
    
        g_error := 'GET SIGNATURE';
        SELECT id_prof_creation, dt_creation
          INTO l_update_user, l_update_time
          FROM (SELECT rh.id_prof_creation, rh.dt_creation, row_number() over(ORDER BY rh.dt_creation) rn
                  FROM v_epis_hhc_req_h rh
                 WHERE rh.id_epis_hhc_req = i_id_request)
         WHERE rn = 1;
    
        g_error      := 'GET HHC REQUEST STATUS';
        l_flg_status := get_epis_hhc_status(i_lang => i_lang, i_prof => i_prof, i_id_epis_hhc_req => i_id_request);
    
        g_error := 'GET DESC CANCEL REASON';
        IF l_flg_status IN (k_hhc_canceled, k_hhc_discontinued)
        THEN
            IF NOT get_desc_cancel_reason(i_id_epis_hhc_req    => i_id_request,
                                          o_desc_cancel_reason => l_desc_cancel_reason,
                                          o_cancel_notes       => l_cancel_notes)
            THEN
                RAISE l_internal_error;
            END IF;
        END IF;
    
        IF i_flg_report = pk_alert_constant.g_yes
           AND l_flg_status != k_hhc_canceled
        THEN
            l_flg_status := pk_alert_constant.g_flg_status_report_a;
        END IF;
    
        l_signature := get_prof_signature(i_lang, i_prof, l_update_user, l_update_time);
    
        IF i_flg_report = pk_alert_constant.g_yes
        THEN
            l_desc := pk_message.get_message(i_lang, 'REF_MARK_REQ_T023');
            l_req_det.extend;
            l_req_det(l_req_det.last()) := t_rec_hhc_req_hist(l_desc,
                                                              ' ',
                                                              pk_alert_constant.g_flg_screen_l0,
                                                              pk_alert_constant.g_flg_status_report_h,
                                                              i_id_request);
        END IF;
    
        index_t := index_t + 1;
    
        IF NOT get_req_status_formatted(i_lang            => i_lang,
                                        i_prof            => i_prof,
                                        i_id_epis_hhc_req => i_id_request,
                                        io_req_det        => l_req_det,
                                        i_flg_detail      => pk_hhc_constant.k_detail_status_referral_hist,
                                        o_error           => o_error)
        THEN
            RAISE l_internal_error;
        END IF;
    
        --l_desc := ' ';
        l_val  := ' ';
        l_type := pk_alert_constant.g_flg_screen_l1;
        l_desc := pk_sysdomain.get_domain(i_code_dom => pk_hhc_constant.k_hhc_flg_status_domain,
                                          i_val      => k_hhc_requested,
                                          i_lang     => i_lang);
    
        l_req_det.extend;
        l_req_det(l_req_det.last()) := t_rec_hhc_req_hist(l_desc, l_val, l_type, l_flg_status, i_id_request);
    
        g_error := 'GET DETAILS OFF HHC REQUEST';
    
        FOR r IN c_components(i_lang, i_prof, i_id_request, l_components)
        LOOP
        
            IF l_old_id_ds_component_parent != r.id_ds_component_parent
            THEN
                --insert blanck line
                IF index_t != 1
                THEN
                    l_desc := ' ';
                    l_val  := ' ';
                    l_type := pk_alert_constant.g_flg_screen_wl;
                
                    l_req_det.extend;
                    l_req_det(l_req_det.last()) := t_rec_hhc_req_hist(l_desc,
                                                                      l_val,
                                                                      l_type,
                                                                      pk_alert_constant.g_flg_status_report_h,
                                                                      i_id_request);
                    index_t := index_t + 1;
                END IF;
            
                --get header of component
                l_desc := get_cmpt_desc_by_id(i_lang, r.id_ds_component_parent);
                l_val  := '';
                l_type := pk_alert_constant.g_flg_screen_l1;
            
                l_req_det.extend;
                l_req_det(l_req_det.last()) := t_rec_hhc_req_hist(l_desc,
                                                                  l_val,
                                                                  l_type,
                                                                  pk_alert_constant.g_flg_status_report_h,
                                                                  i_id_request);
                index_t := index_t + 1;
            END IF;
            l_val  := NULL;
            l_desc := NULL;
            FOR s IN c_data(i_lang, i_prof, i_id_request, l_components, r.internal_name, i_id_group)
            LOOP
                IF r.flg_type = pk_hhc_constant.k_hhc_flg_type_text
                   AND r.flg_data_type IN (pk_hhc_constant.k_hhc_flg_data_type_lo)
                   AND s.val_clob IS NOT NULL
                THEN
                    l_val := s.val_clob;
                    l_req_det.extend;
                    l_req_det(l_req_det.last()) := t_rec_hhc_req_hist(r.descr || pk_alert_constant.g_two_points,
                                                                      l_val,
                                                                      pk_alert_constant.g_flg_screen_l2b,
                                                                      l_flg_status,
                                                                      i_id_request);
                ELSIF r.flg_type = pk_hhc_constant.k_hhc_flg_type_text
                      AND r.flg_data_type = pk_hhc_constant.k_hhc_flg_data_type_ft
                THEN
                
                    l_val := s.val_text;
                    l_req_det.extend;
                    l_req_det(l_req_det.last()) := t_rec_hhc_req_hist(r.descr || pk_alert_constant.g_two_points,
                                                                      l_val,
                                                                      pk_alert_constant.g_flg_screen_l2b,
                                                                      l_flg_status,
                                                                      i_id_request);
                ELSIF r.flg_type IN (pk_hhc_constant.k_hhc_flg_type_text,
                                     pk_hhc_constant.k_hhc_flg_type_d,
                                     pk_hhc_constant.k_hhc_flg_type_k,
                                     pk_hhc_constant.k_flg_type_r)
                      AND r.flg_data_type NOT IN
                      (pk_hhc_constant.k_hhc_flg_data_type_mw, pk_hhc_constant.k_hhc_flg_data_type_cb)
                THEN
                
                    l_val := s.val_text;
                    l_req_det.extend;
                    l_req_det(l_req_det.last()) := t_rec_hhc_req_hist(r.descr || pk_alert_constant.g_two_points,
                                                                      l_val,
                                                                      pk_alert_constant.g_flg_screen_l2b,
                                                                      l_flg_status,
                                                                      i_id_request);
                
                ELSIF r.flg_type IN (pk_hhc_constant.k_hhc_flg_type_k, pk_hhc_constant.k_hhc_flg_type_d)
                      AND r.flg_data_type IN (pk_hhc_constant.k_hhc_flg_data_type_ms,
                                              pk_hhc_constant.k_hhc_flg_data_type_mw,
                                              pk_hhc_constant.k_hhc_flg_data_type_cb)
                THEN
                    IF l_desc IS NULL
                    THEN
                        l_desc := r.descr || pk_alert_constant.g_two_points;
                        l_req_det.extend;
                        l_req_det(l_req_det.last()) := t_rec_hhc_req_hist(l_desc,
                                                                          '',
                                                                          pk_alert_constant.g_flg_screen_l2b,
                                                                          l_flg_status,
                                                                          i_id_request);
                    
                    END IF;
                
                    l_req_det.extend;
                    l_req_det(l_req_det.last()) := t_rec_hhc_req_hist('',
                                                                      s.val_text,
                                                                      pk_alert_constant.g_flg_screen_l3,
                                                                      l_flg_status,
                                                                      i_id_request);
                END IF;
            END LOOP;
        
            index_t                      := index_t + 1;
            l_old_id_ds_component_parent := r.id_ds_component_parent;
        END LOOP;
    
        --signature
        l_req_det.extend;
        l_req_det(l_req_det.last()) := t_rec_hhc_req_hist(pk_message.get_message(i_lang, 'COMMON_M107'),
                                                          l_signature,
                                                          pk_alert_constant.g_flg_screen_lp,
                                                          pk_alert_constant.g_flg_status_report_h,
                                                          i_id_request);
    
        OPEN o_detail_create FOR
            SELECT *
              FROM TABLE(l_req_det);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => o_error);
        
    END get_hhc_req_det_create;

    --add values to type
    FUNCTION set_val_rec_hhc_req_type
    (
        i_lang        IN language.id_language%TYPE,
        i_flg_report  IN VARCHAR2,
        i_id_request  IN epis_hhc_req.id_epis_hhc_req%TYPE,
        i_text_header IN VARCHAR2,
        i_descr_new   IN VARCHAR2,
        i_descr_old   IN VARCHAR2,
        i_value_new   IN VARCHAR2,
        i_value_old   IN VARCHAR2,
        i_desc_sign   IN VARCHAR2,
        i_val_sign    IN VARCHAR2
    ) RETURN BOOLEAN IS
        l_descr sys_message.desc_message%TYPE;
    BEGIN
    
        IF i_flg_report = pk_alert_constant.g_yes
        THEN
            l_descr := pk_message.get_message(i_lang, 'REF_MARK_REQ_T023');
            g_req_hist.extend;
            g_req_hist(g_req_hist.last()) := t_rec_hhc_req_hist(l_descr,
                                                                ' ',
                                                                pk_alert_constant.g_flg_screen_l0,
                                                                pk_alert_constant.g_flg_status_report_h,
                                                                i_id_request);
        END IF;
        IF i_text_header IS NOT NULL
        THEN
            --get header of component
            g_req_hist.extend;
            g_req_hist(g_req_hist.last()) := t_rec_hhc_req_hist(i_text_header,
                                                                '',
                                                                pk_alert_constant.g_flg_screen_l1,
                                                                pk_alert_constant.g_flg_status_report_h,
                                                                i_id_request);
        
        END IF;
        IF i_descr_new IS NOT NULL
           AND i_value_new IS NOT NULL
        THEN
            g_req_hist.extend;
            g_req_hist(g_req_hist.last()) := t_rec_hhc_req_hist(i_descr_new,
                                                                i_value_new,
                                                                pk_alert_constant.g_flg_screen_l2n,
                                                                pk_alert_constant.g_flg_status_report_h,
                                                                i_id_request);
        ELSIF i_descr_new IS NOT NULL
              AND i_value_new IS NULL
        THEN
            g_req_hist.extend;
            g_req_hist(g_req_hist.last()) := t_rec_hhc_req_hist(i_descr_new,
                                                                ' ',
                                                                pk_alert_constant.g_flg_screen_l2n,
                                                                pk_alert_constant.g_flg_status_report_h,
                                                                i_id_request);
        
        ELSIF i_descr_new IS NULL
              AND i_value_new IS NOT NULL
        THEN
            g_req_hist.extend;
            g_req_hist(g_req_hist.last()) := t_rec_hhc_req_hist('',
                                                                i_value_new,
                                                                pk_alert_constant.g_flg_screen_l3,
                                                                pk_alert_constant.g_flg_status_report_h,
                                                                i_id_request);
        END IF;
    
        IF i_descr_old IS NOT NULL
           AND i_value_old IS NOT NULL
        THEN
        
            g_req_hist.extend;
            g_req_hist(g_req_hist.last()) := t_rec_hhc_req_hist(i_descr_old,
                                                                i_value_old,
                                                                pk_alert_constant.g_flg_screen_l2b,
                                                                pk_alert_constant.g_flg_status_report_h,
                                                                i_id_request);
        
        ELSIF i_descr_old IS NOT NULL
              AND i_value_old IS NULL
        THEN
            g_req_hist.extend;
            g_req_hist(g_req_hist.last()) := t_rec_hhc_req_hist(i_descr_old,
                                                                '',
                                                                pk_alert_constant.g_flg_screen_l2b,
                                                                pk_alert_constant.g_flg_status_report_h,
                                                                i_id_request);
        ELSIF i_descr_old IS NULL
              AND i_value_old IS NOT NULL
        THEN
            g_req_hist.extend;
            g_req_hist(g_req_hist.last()) := t_rec_hhc_req_hist('',
                                                                i_value_old,
                                                                pk_alert_constant.g_flg_screen_l3,
                                                                pk_alert_constant.g_flg_status_report_h,
                                                                i_id_request);
        END IF;
    
        IF i_val_sign IS NOT NULL
        THEN
        
            g_req_hist.extend;
            g_req_hist(g_req_hist.last()) := t_rec_hhc_req_hist(i_desc_sign,
                                                                i_val_sign,
                                                                pk_alert_constant.g_flg_screen_lp,
                                                                pk_alert_constant.g_flg_status_report_h,
                                                                i_id_request);
        
            g_req_hist.extend;
            g_req_hist(g_req_hist.last()) := t_rec_hhc_req_hist(' ',
                                                                ' ',
                                                                pk_alert_constant.g_flg_screen_wl,
                                                                pk_alert_constant.g_flg_status_report_h,
                                                                i_id_request);
        
        END IF;
        RETURN TRUE;
    
    END set_val_rec_hhc_req_type;

    --
    --get details from hhc request
    FUNCTION get_hhc_req_det
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_root_name  IN ds_component.internal_name%TYPE,
        i_id_request IN epis_hhc_req.id_epis_hhc_req%TYPE,
        i_flg_report IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        o_detail     OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
        CURSOR c_components
        (
            i_lang       IN language.id_language%TYPE,
            i_prof       IN profissional,
            i_id_request IN epis_hhc_req.id_epis_hhc_req%TYPE,
            i_components IN t_dyn_tree_table
        ) IS
            SELECT pk_message.get_message(i_lang => i_lang, i_code_mess => code_ds_component) descr,
                   rank,
                   id_ds_component_parent,
                   flg_type,
                   flg_data_type,
                   internal_name,
                   position
              FROM (SELECT DISTINCT dc.code_ds_component,
                                    xsql.rank,
                                    xsql.id_ds_component_parent,
                                    hdt.flg_type,
                                    dc.flg_data_type,
                                    hdt.internal_name,
                                    xsql.position
                      FROM (SELECT /*+ opt_estimate(table t rows=1) */
                             t.*
                              FROM TABLE(i_components) t) xsql
                      JOIN v_ds_component dc
                        ON dc.id_ds_component = xsql.id_ds_component_child
                      JOIN v_hhc_det_type hdt
                        ON hdt.internal_name = xsql.internal_name_child
                      JOIN v_epis_hhc_req_det ehrd
                        ON ehrd.id_hhc_det_type = hdt.id_hhc_det_type
                      JOIN v_epis_hhc_req ehr
                        ON ehr.id_epis_hhc_req = ehrd.id_epis_hhc_req
                     WHERE ehrd.id_epis_hhc_req = i_id_request
                       AND xsql.flg_component_type_child = 'L'
                       AND (dbms_lob.compare(ehrd.hhc_text, empty_clob()) != 0 OR ehrd.hhc_value IS NOT NULL)
                       AND hdt.internal_name != pk_hhc_constant.k_ds_adt_id_care_giver)
             ORDER BY rank, position, id_ds_component_parent;
    
        CURSOR c_data
        (
            i_lang          IN language.id_language%TYPE,
            i_prof          IN profissional,
            i_id_request    IN epis_hhc_req.id_epis_hhc_req%TYPE,
            i_internal_name IN hhc_det_type.internal_name%TYPE
        ) IS
            SELECT pk_hhc_core.get_detail_description(i_lang, i_prof, hdt.flg_type, hdt.type_name, ehrd.hhc_value) val_text,
                   ehrd.hhc_text val_clob,
                   hdt.flg_type
              FROM v_epis_hhc_req_det ehrd
              JOIN v_hhc_det_type hdt
                ON ehrd.id_hhc_det_type = hdt.id_hhc_det_type
             WHERE ehrd.id_epis_hhc_req = i_id_request
               AND hdt.internal_name = i_internal_name;
    
        l_signature        VARCHAR2(200 CHAR);
        l_update_user      epis_hhc_req.update_user%TYPE;
        l_update_time      epis_hhc_req.update_time%TYPE;
        l_signature_status VARCHAR2(200 CHAR);
        --l_update_user_status         epis_hhc_req.update_user%TYPE;
        --l_update_time_status         epis_hhc_req.update_time%TYPE;
        l_components                 t_dyn_tree_table;
        l_req_det                    t_coll_hhc_req_hist := t_coll_hhc_req_hist();
        index_t                      NUMBER := 1;
        l_old_id_ds_component_parent ds_component.id_ds_component%TYPE := 0;
        l_func_name CONSTANT VARCHAR2(15 CHAR) := 'get_hhc_req_det';
        l_desc       sys_message.desc_message%TYPE;
        l_val        CLOB;
        l_type       hhc_det_type.flg_type%TYPE;
        l_flg_status epis_hhc_req.flg_status%TYPE;
        l_internal_error EXCEPTION;
        l_flg_status_rep epis_hhc_req.flg_status%TYPE;
        --l_status_detail  t_hhc_status_det_coll;
    
        l_desc_cancel_reason translation.desc_lang_8%TYPE;
        l_cancel_notes       CLOB;
    
    BEGIN
        --get components of dynamic screen
        g_error      := 'GET COMPONENTS FOR ' || i_root_name;
        l_components := pk_dyn_form.get_dyn_cfg(i_lang           => i_lang,
                                                i_prof           => i_prof,
                                                i_patient        => NULL,
                                                i_component_name => i_root_name,
                                                i_action         => NULL);
    
        g_error := 'GET SIGNATURE';
        SELECT prof_update, dt_update
          INTO l_update_user, l_update_time
          FROM (SELECT rh.id_prof_creation prof_update,
                       rh.dt_creation dt_update,
                       row_number() over(PARTITION BY rh.id_epis_hhc_req ORDER BY rh.dt_creation DESC) rn
                  FROM v_epis_hhc_req_det_h rh
                 WHERE rh.id_epis_hhc_req = i_id_request)
         WHERE rn = 1;
    
        l_signature := get_prof_signature(i_lang, i_prof, l_update_user, l_update_time);
    
        g_error := 'GET HHC REQUEST STATUS';
    
        SELECT x.flg_status flg_status,
               
               get_prof_signature(i_lang, i_prof, x.id_professional, x.dt_status)
        
          INTO l_flg_status, l_signature_status --l_update_user_status, l_update_time_status
          FROM (SELECT v.flg_status, v.id_professional, v.dt_status, row_number() over(ORDER BY v.dt_status DESC) rn
                  FROM v_epis_hhc_req_status v
                 WHERE v.id_epis_hhc_req = i_id_request
                   AND nvl(v.flg_undone, 'N') NOT IN (k_hhc_undo)) x
         WHERE x.rn = 1;
    
        --  l_flg_status := get_epis_hhc_status(i_lang => i_lang, i_prof => i_prof, i_id_epis_hhc_req => i_id_request);
    
        g_error := 'GET DESC CANCEL REASON';
        IF l_flg_status IN (k_hhc_canceled, k_hhc_discontinued)
        THEN
            IF NOT get_desc_cancel_reason(i_id_epis_hhc_req    => i_id_request,
                                          o_desc_cancel_reason => l_desc_cancel_reason,
                                          o_cancel_notes       => l_cancel_notes)
            THEN
                RAISE l_internal_error;
            END IF;
        END IF;
    
        g_error := 'GET DETAILS OFF HHC REQUEST';
    
        IF i_flg_report IN (pk_hhc_constant.k_detail_status_referral,
                            pk_hhc_constant.k_detail_status_referral_hist,
                            pk_hhc_constant.k_detail_status_referral_det)
        THEN
            IF NOT get_req_status_formatted(i_lang            => i_lang,
                                            i_prof            => i_prof,
                                            i_id_epis_hhc_req => i_id_request,
                                            io_req_det        => l_req_det,
                                            i_flg_detail      => i_flg_report,
                                            o_error           => o_error)
            THEN
                RAISE l_internal_error;
            END IF;
        
            IF NOT
                (i_flg_report = pk_hhc_constant.k_detail_status_referral_det AND l_flg_status NOT IN (k_hhc_requested))
            THEN
            
                --l_desc := ' ';
                l_val  := ' ';
                l_type := pk_alert_constant.g_flg_screen_l1;
                l_desc := pk_sysdomain.get_domain(i_code_dom => pk_hhc_constant.k_hhc_flg_status_domain,
                                                  i_val      => k_hhc_requested,
                                                  i_lang     => i_lang);
            
                l_req_det.extend;
                l_req_det(l_req_det.last()) := t_rec_hhc_req_hist(l_desc, l_val, l_type, l_flg_status_rep, i_id_request);
                index_t := index_t + 1;
            END IF;
        
        ELSE
            IF i_flg_report = pk_alert_constant.g_yes
            THEN
                IF l_flg_status != k_hhc_canceled
                THEN
                    l_flg_status_rep := pk_alert_constant.g_flg_status_report_a;
                ELSE
                    l_flg_status_rep := l_flg_status;
                END IF;
            
                l_desc := pk_message.get_message(i_lang, 'REF_MARK_REQ_T023');
                l_req_det.extend;
                l_req_det(l_req_det.last()) := t_rec_hhc_req_hist(l_desc,
                                                                  ' ',
                                                                  pk_alert_constant.g_flg_screen_l0,
                                                                  l_flg_status_rep,
                                                                  i_id_request);
            END IF;
            IF l_flg_status = k_hhc_requested
            THEN
                --l_desc := ' ';
                l_val  := ' ';
                l_type := pk_alert_constant.g_flg_screen_l1;
                l_desc := pk_sysdomain.get_domain(i_code_dom => pk_hhc_constant.k_hhc_flg_status_domain,
                                                  i_val      => l_flg_status,
                                                  i_lang     => i_lang);
            
                l_req_det.extend;
                l_req_det(l_req_det.last()) := t_rec_hhc_req_hist(l_desc, l_val, l_type, l_flg_status_rep, i_id_request);
            
            ELSE
                IF NOT get_req_status_formatted(i_lang            => i_lang,
                                                i_prof            => i_prof,
                                                i_id_epis_hhc_req => i_id_request,
                                                io_req_det        => l_req_det,
                                                i_flg_detail      => pk_hhc_constant.k_detail_status_referral_det,
                                                o_error           => o_error)
                THEN
                    RAISE l_internal_error;
                END IF;
            END IF;
            index_t := index_t + 1;
        END IF;
    
        FOR r IN c_components(i_lang, i_prof, i_id_request, l_components)
        LOOP
        
            IF l_old_id_ds_component_parent != r.id_ds_component_parent
            THEN
                --insert blanck line
                IF index_t != 1
                   AND l_flg_status = k_hhc_requested
                THEN
                    l_desc := ' ';
                    l_val  := ' ';
                    l_type := pk_alert_constant.g_flg_screen_wl;
                
                    l_req_det.extend;
                    l_req_det(l_req_det.last()) := t_rec_hhc_req_hist(l_desc,
                                                                      l_val,
                                                                      l_type,
                                                                      l_flg_status_rep,
                                                                      i_id_request);
                    index_t := index_t + 1;
                END IF;
            
                --get header of component
                l_desc := get_cmpt_desc_by_id(i_lang, r.id_ds_component_parent);
                l_val  := '';
                l_type := pk_alert_constant.g_flg_screen_l1;
            
                l_req_det.extend;
                l_req_det(l_req_det.last()) := t_rec_hhc_req_hist(l_desc, l_val, l_type, l_flg_status_rep, i_id_request);
                index_t := index_t + 1;
            END IF;
            l_val  := NULL;
            l_desc := NULL;
        
            FOR s IN c_data(i_lang, i_prof, i_id_request, r.internal_name)
            LOOP
            
                IF r.flg_type = pk_hhc_constant.k_hhc_flg_type_text
                   AND r.flg_data_type IN (pk_hhc_constant.k_hhc_flg_data_type_lo)
                   AND s.val_clob IS NOT NULL
                THEN
                    l_val := s.val_clob;
                    l_req_det.extend;
                    l_req_det(l_req_det.last()) := t_rec_hhc_req_hist(r.descr || pk_alert_constant.g_two_points,
                                                                      l_val,
                                                                      pk_alert_constant.g_flg_screen_l2b,
                                                                      l_flg_status_rep,
                                                                      i_id_request);
                ELSIF r.flg_type = pk_hhc_constant.k_hhc_flg_type_text
                      AND r.flg_data_type = pk_hhc_constant.k_hhc_flg_data_type_ft
                THEN
                
                    l_val := s.val_text;
                    l_req_det.extend;
                    l_req_det(l_req_det.last()) := t_rec_hhc_req_hist(r.descr || pk_alert_constant.g_two_points,
                                                                      l_val,
                                                                      pk_alert_constant.g_flg_screen_l2b,
                                                                      l_flg_status_rep,
                                                                      i_id_request);
                ELSIF r.flg_type IN (pk_hhc_constant.k_hhc_flg_type_text,
                                     pk_hhc_constant.k_hhc_flg_type_d,
                                     pk_hhc_constant.k_hhc_flg_type_k,
                                     pk_hhc_constant.k_flg_type_r)
                      AND r.flg_data_type NOT IN
                      (pk_hhc_constant.k_hhc_flg_data_type_mw, pk_hhc_constant.k_hhc_flg_data_type_cb)
                THEN
                
                    l_val := s.val_text;
                    l_req_det.extend;
                    l_req_det(l_req_det.last()) := t_rec_hhc_req_hist(r.descr || pk_alert_constant.g_two_points,
                                                                      l_val,
                                                                      pk_alert_constant.g_flg_screen_l2b,
                                                                      l_flg_status_rep,
                                                                      i_id_request);
                
                ELSIF r.flg_type IN (pk_hhc_constant.k_hhc_flg_type_k, pk_hhc_constant.k_hhc_flg_type_d)
                      AND r.flg_data_type IN (pk_hhc_constant.k_hhc_flg_data_type_ms,
                                              pk_hhc_constant.k_hhc_flg_data_type_mw,
                                              pk_hhc_constant.k_hhc_flg_data_type_cb)
                THEN
                    IF l_desc IS NULL
                    THEN
                        l_desc := r.descr || pk_alert_constant.g_two_points;
                        l_req_det.extend;
                        l_req_det(l_req_det.last()) := t_rec_hhc_req_hist(l_desc,
                                                                          '',
                                                                          pk_alert_constant.g_flg_screen_l2b,
                                                                          l_flg_status_rep,
                                                                          i_id_request);
                    
                    END IF;
                
                    l_req_det.extend;
                    l_req_det(l_req_det.last()) := t_rec_hhc_req_hist('',
                                                                      s.val_text,
                                                                      pk_alert_constant.g_flg_screen_l3,
                                                                      l_flg_status_rep,
                                                                      i_id_request);
                END IF;
            END LOOP;
        
            index_t := index_t + 1;
        
            l_old_id_ds_component_parent := r.id_ds_component_parent;
        END LOOP;
    
        --signature
        l_req_det.extend;
        l_req_det(l_req_det.last()) := t_rec_hhc_req_hist(pk_message.get_message(i_lang, 'COMMON_M156') ||
                                                          pk_alert_constant.g_two_points,
                                                          l_signature,
                                                          pk_alert_constant.g_flg_screen_lp,
                                                          l_flg_status_rep,
                                                          i_id_request);
        OPEN o_detail FOR
            SELECT descr,
                   val,
                   tipo                   AS flg_type,
                   flg_status,
                   i_id_request           AS id_request,
                   pk_alert_constant.g_no flg_html,
                   NULL                   val_clob,
                   pk_alert_constant.g_no flg_clob
              FROM TABLE(l_req_det);
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_detail);
            RETURN FALSE;
        
    END get_hhc_req_det;

    FUNCTION update_request_status
    (
        i_lang             IN NUMBER,
        i_prof             IN profissional,
        i_epis_hhc_req     IN NUMBER,
        i_flg_status       IN VARCHAR2,
        i_id_cancel_reason IN NUMBER,
        i_notes            IN CLOB,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        l_bool       BOOLEAN;
        l_id_episode NUMBER;
        l_error      VARCHAR2(1000 CHAR);
    BEGIN
    
        l_error := 'SELECT EISODE FROM HHC_REQUEST';
        SELECT id_episode
          INTO l_id_episode
          FROM epis_hhc_req x
         WHERE x.id_epis_hhc_req = i_epis_hhc_req;
    
        l_error := 'SAVE CANCELLATION';
        l_bool  := pk_hhc_core.upd_epis_req(i_prof                => i_prof,
                                            i_id_epis_hhc_req     => i_epis_hhc_req,
                                            i_flg_status          => i_flg_status,
                                            i_id_prof_manager     => NULL,
                                            i_dt_prof_manager     => NULL,
                                            i_id_prof_coordinator => NULL,
                                            i_id_cancel_reason    => i_id_cancel_reason,
                                            i_cancel_notes        => i_notes);
        l_bool  := ins_req_status(i_epis_hhc_req, i_prof.id, i_flg_status, i_id_cancel_reason, i_notes);
    
        IF i_flg_status IN (k_hhc_canceled, k_hhc_discontinued)
        THEN
            l_bool := pk_alerts.delete_sys_alert_event(i_lang         => i_lang,
                                                       i_prof         => i_prof,
                                                       i_id_sys_alert => pk_hhc_constant.k_hhc_new_referral_alert,
                                                       i_id_record    => l_id_episode,
                                                       o_error        => o_error);
        
        END IF;
    
        RETURN l_bool;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              l_error,
                                              g_owner,
                                              g_package,
                                              'update_request_status',
                                              o_error);
            RETURN FALSE;
    END update_request_status;

    FUNCTION get_type(i_id_epis_hhc_req_det IN epis_hhc_req_det.id_epis_hhc_req_det%TYPE) RETURN VARCHAR2 IS
        l_type VARCHAR2(1000);
    BEGIN
    
        SELECT t.internal_name
          INTO l_type
          FROM epis_hhc_req_det h
          JOIN hhc_det_type t
            ON t.id_hhc_det_type = h.id_hhc_det_type
         WHERE h.id_epis_hhc_req_det = i_id_epis_hhc_req_det;
    
        RETURN l_type;
    END get_type;

    FUNCTION get_value(i_id_epis_hhc_req_det IN epis_hhc_req_det.id_epis_hhc_req_det%TYPE) RETURN VARCHAR2 IS
        l_ret   VARCHAR2(4000);
        tbl_ret table_varchar;
    BEGIN
        SELECT ehrd.hhc_value
          BULK COLLECT
          INTO tbl_ret
          FROM epis_hhc_req_det ehrd
         WHERE ehrd.id_epis_hhc_req_det = i_id_epis_hhc_req_det;
    
        IF tbl_ret.count > 0
        THEN
            l_ret := tbl_ret(1);
        END IF;
    
        RETURN l_ret;
    
    END get_value;

    FUNCTION get_text(i_id_epis_hhc_req_det IN epis_hhc_req_det.id_epis_hhc_req_det%TYPE) RETURN CLOB IS
        l_ret CLOB;
    BEGIN
        SELECT ehrd.hhc_text
          INTO l_ret
          FROM epis_hhc_req_det ehrd
         WHERE ehrd.id_epis_hhc_req_det = i_id_epis_hhc_req_det;
    
        RETURN l_ret;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_text;

    FUNCTION get_desc_value
    (
        i_lang      IN NUMBER,
        i_prof      IN profissional,
        i_component IN VARCHAR2,
        i_value     IN VARCHAR2,
        i_type_name IN VARCHAR2
    ) RETURN VARCHAR2 IS
        l_return VARCHAR2(4000);
    BEGIN
    
        CASE
            WHEN i_component = k_ds_prof_in_charge_name THEN
                l_return := pk_prof_utils.get_name(i_lang => i_lang, i_prof_id => i_value);
            WHEN i_component IN (k_ds_problems, k_ds_investigation_lab, k_ds_investigation_exam) THEN
                l_return := get_hhc_translation(i_lang, i_prof, i_value, i_type_name);
            WHEN i_component = k_ds_family_relationship THEN
                l_return := pk_adt.get_fam_rel_domain_desc(i_lang, i_value);
            ELSE
                l_return := i_value;
        END CASE;
    
        RETURN l_return;
    
    END get_desc_value;

    FUNCTION get_edit_values
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_episode      IN episode.id_episode%TYPE,
        i_id_patient      IN patient.id_patient%TYPE,
        i_id_epis_hhc_req IN epis_hhc_req.id_epis_hhc_req%TYPE,
        i_root_name       IN VARCHAR2
    ) RETURN t_tbl_ds_get_value IS
        --l_ret     BOOLEAN;
        --l_type    VARCHAR2(1000);
        --l_req_det table_varchar;
        --l_temp_id NUMBER;
    
        tbl_result       t_tbl_ds_get_value := t_tbl_ds_get_value();
        tbl_tree_configs t_dyn_tree_table;
    
        disable_toggle_1 BOOLEAN := FALSE;
        disable_toggle_2 BOOLEAN := FALSE;
    
    BEGIN
    
        tbl_tree_configs := pk_dyn_form.get_dyn_cfg(i_lang           => i_lang,
                                                    i_prof           => i_prof,
                                                    i_patient        => NULL,
                                                    i_component_name => i_root_name,
                                                    i_action         => NULL);
    
        SELECT t_rec_ds_get_value(id_ds_cmpt_mkt_rel => mkt.id_ds_cmpt_mkt_rel,
                                  id_ds_component    => mkt.id_ds_component_child,
                                  internal_name      => mkt.internal_name_child,
                                  VALUE              => ehrd.hhc_value,
                                  min_value          => NULL,
                                  max_value          => NULL,
                                  desc_value         => pk_hhc_core.get_desc_value(i_lang      => i_lang,
                                                                                   i_prof      => i_prof,
                                                                                   i_component => mkt.id_ds_component_child,
                                                                                   i_value     => ehrd.hhc_value,
                                                                                   i_type_name => hdt.type_name),
                                  desc_clob          => ehrd.hhc_text,
                                  value_clob         => ehrd.hhc_value,
                                  id_unit_measure    => NULL,
                                  desc_unit_measure  => NULL,
                                  flg_validation     => 'Y',
                                  err_msg            => NULL,
                                  flg_event_type     => 'NA',
                                  flg_multi_status   => NULL,
                                  idx                => 1)
          BULK COLLECT
          INTO tbl_result
          FROM v_epis_hhc_req_det ehrd
         RIGHT JOIN v_hhc_det_type hdt
            ON ehrd.id_hhc_det_type = hdt.id_hhc_det_type
           AND ehrd.id_epis_hhc_req = i_id_epis_hhc_req
         RIGHT JOIN (SELECT /*+opt_estimate (table t rows=1)*/
                      t.internal_name_child, t.rank, t.id_ds_cmpt_mkt_rel, t.id_ds_component_child
                       FROM TABLE(tbl_tree_configs) t) mkt
            ON mkt.internal_name_child = hdt.internal_name
         ORDER BY mkt.rank;
    
        <<lup_thru_components>>
        FOR i IN 1 .. tbl_result.count
        LOOP
        
            IF tbl_result(i).id_ds_component IN (k_ds_firstname, k_ds_othernames1)
                AND tbl_result(i).value IS NOT NULL
            THEN
                disable_toggle_1 := TRUE;
            END IF;
            IF tbl_result(i).id_ds_component IN (k_ds_lastname, k_ds_othernames3)
                AND tbl_result(i).value IS NOT NULL
            THEN
                disable_toggle_2 := TRUE;
            END IF;
        
        END LOOP;
    
        <<lup_thru_components>>
        FOR i IN 1 .. tbl_result.count
        LOOP
        
            IF tbl_result(i).id_ds_component = k_ds_autotranslate_2
            THEN
                tbl_result(i).value := iif(disable_toggle_1, 'N', 'Y');
            END IF;
            IF tbl_result(i).id_ds_component = k_ds_autotranslate_3
            THEN
                tbl_result(i).value := iif(disable_toggle_2, 'N', 'Y');
            END IF;
        
        END LOOP;
    
        RETURN tbl_result;
    
    END get_edit_values;

    FUNCTION check_patient_in_hhc
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE,
        i_status     IN table_varchar
    ) RETURN BOOLEAN IS
        l_num NUMBER;
    BEGIN
        SELECT COUNT(1)
          INTO l_num
          FROM v_epis_hhc_req vr
         WHERE vr.id_patient = i_id_patient
           AND vr.flg_status IN (SELECT /*+opt_estimate (table t rows=1)*/
                                  column_value
                                   FROM TABLE(i_status) t);
        RETURN(l_num > 0);
    
    END check_patient_in_hhc;

    -- *******************************
    FUNCTION get_id_care_giver
    (
        i_patient    IN NUMBER,
        i_id_mkt_rel IN NUMBER
    ) RETURN t_rec_ds_get_value IS
        l_id_patient NUMBER;
        l_ret        t_rec_ds_get_value;
    BEGIN
    
        l_id_patient := pk_adt.get_id_pat_relative(i_id_patient => i_patient);
    
        l_ret := get_default_values(i_id_mkt_rel => i_id_mkt_rel, i_value => l_id_patient, i_desc_value => l_id_patient);
    
        RETURN l_ret;
    
    END get_id_care_giver;

    -- *******************************
    FUNCTION get_first_name
    (
        i_patient    IN NUMBER,
        i_id_mkt_rel IN NUMBER
    ) RETURN t_rec_ds_get_value IS
        l_ret        t_rec_ds_get_value;
        l_id_patient NUMBER;
        l_value      VARCHAR2(4000);
    BEGIN
    
        l_id_patient := pk_adt.get_id_pat_relative(i_id_patient => i_patient);
        l_value      := pk_adt.get_1st_cgiver_1st_name(i_id_patient => l_id_patient);
    
        l_ret := get_default_values(i_id_mkt_rel => i_id_mkt_rel, i_value => l_value, i_desc_value => l_value);
    
        RETURN l_ret;
    
    END get_first_name;

    -- *******************************
    FUNCTION get_othernames1
    (
        i_patient    IN NUMBER,
        i_id_mkt_rel IN NUMBER
    ) RETURN t_rec_ds_get_value IS
        l_ret        t_rec_ds_get_value;
        l_id_patient NUMBER;
        l_value      VARCHAR2(4000);
    BEGIN
    
        l_id_patient := pk_adt.get_id_pat_relative(i_id_patient => i_patient);
        l_value      := pk_adt.get_1st_cgiver_otname1(i_id_patient => l_id_patient);
    
        l_ret := get_default_values(i_id_mkt_rel => i_id_mkt_rel, i_value => l_value, i_desc_value => l_value);
    
        RETURN l_ret;
    
    END get_othernames1;

    -- *******************************
    FUNCTION get_lastname
    (
        i_patient    IN NUMBER,
        i_id_mkt_rel IN NUMBER
    ) RETURN t_rec_ds_get_value IS
        l_ret        t_rec_ds_get_value;
        l_id_patient NUMBER;
        l_value      VARCHAR2(4000);
    BEGIN
    
        l_id_patient := pk_adt.get_id_pat_relative(i_id_patient => i_patient);
        l_value      := pk_adt.get_1st_fam_name(i_id_patient => l_id_patient);
    
        l_ret := get_default_values(i_id_mkt_rel => i_id_mkt_rel, i_value => l_value, i_desc_value => l_value);
    
        RETURN l_ret;
    
    END get_lastname;

    --*******************************************
    FUNCTION get_othernames3
    (
        i_patient    IN NUMBER,
        i_id_mkt_rel IN NUMBER
    ) RETURN t_rec_ds_get_value IS
        l_ret        t_rec_ds_get_value;
        l_id_patient NUMBER;
        l_value      VARCHAR2(4000);
    BEGIN
    
        l_id_patient := pk_adt.get_id_pat_relative(i_id_patient => i_patient);
        l_value      := pk_adt.get_1st_fam_otname3(i_id_patient => l_id_patient);
    
        l_ret := get_default_values(i_id_mkt_rel => i_id_mkt_rel, i_value => l_value, i_desc_value => l_value);
    
        RETURN l_ret;
    
    END get_othernames3;

    --- CMF
    --**************************************
    FUNCTION get_iv_pharm_assessed(i_id_mkt_rel IN NUMBER) RETURN t_rec_ds_get_value IS
        l_ret   t_rec_ds_get_value;
        l_value VARCHAR2(4000);
    BEGIN
    
        l_value := k_yes;
    
        l_ret := get_default_values(i_id_mkt_rel => i_id_mkt_rel, i_value => l_value, i_desc_value => l_value);
    
        RETURN l_ret;
    
    END get_iv_pharm_assessed;

    FUNCTION get_iv_inf_control_done(i_id_mkt_rel IN NUMBER) RETURN t_rec_ds_get_value IS
        l_ret   t_rec_ds_get_value;
        l_value VARCHAR2(4000);
    BEGIN
    
        l_value := k_yes;
    
        l_ret := get_default_values(i_id_mkt_rel => i_id_mkt_rel, i_value => l_value, i_desc_value => l_value);
    
        RETURN l_ret;
    
    END get_iv_inf_control_done;
    -- end cmf

    --**************************************
    FUNCTION get_phone_mobile
    (
        i_patient    IN NUMBER,
        i_id_mkt_rel IN NUMBER
    ) RETURN t_rec_ds_get_value IS
        l_ret        t_rec_ds_get_value;
        l_id_patient NUMBER;
        l_value      VARCHAR2(4000);
    BEGIN
    
        l_id_patient := pk_adt.get_id_pat_relative(i_id_patient => i_patient);
        l_value      := pk_adt.get_1st_mphone_no(i_id_patient => l_id_patient);
    
        l_ret := get_default_values(i_id_mkt_rel => i_id_mkt_rel, i_value => l_value, i_desc_value => l_value);
    
        RETURN l_ret;
    
    END get_phone_mobile;

    -- *******************************
    FUNCTION get_family_rel
    (
        i_lang       IN NUMBER,
        i_patient    IN NUMBER,
        i_id_mkt_rel IN NUMBER
    ) RETURN t_rec_ds_get_value IS
        l_ret t_rec_ds_get_value;
        --l_id_patient NUMBER;
        l_value NUMBER;
        --tbl_desc     table_varchar;
        l_desc VARCHAR2(4000);
    BEGIN
    
        l_value := pk_adt.get_fam_relationship(i_id_patient => i_patient);
        l_desc  := pk_adt.get_fam_rel_domain_desc(i_lang, l_value);
    
        l_ret := get_default_values(i_id_mkt_rel => i_id_mkt_rel, i_value => l_value, i_desc_value => l_desc);
    
        RETURN l_ret;
    
    END get_family_rel;

    FUNCTION get_referral_type
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_patient    IN patient.id_patient%TYPE,
        i_id_mkt_rel IN NUMBER,
        i_root_name  IN VARCHAR2
    ) RETURN t_rec_ds_get_value IS
    
        l_ret      t_rec_ds_get_value;
        l_status   table_varchar := table_varchar(pk_hhc_constant.k_hhc_req_status_rejected,
                                                  pk_hhc_constant.k_hhc_req_status_closed,
                                                  pk_hhc_constant.k_hhc_req_status_discontinued);
        l_bool     BOOLEAN;
        l_def_type VARCHAR2(1 CHAR);
    BEGIN
    
        l_bool := check_patient_in_hhc(i_lang, i_prof, i_patient, l_status);
    
        IF l_bool
        THEN
            l_def_type := 'R';
        ELSE
            l_def_type := 'F';
        END IF;
        SELECT t_rec_ds_get_value(id_ds_cmpt_mkt_rel => i_id_mkt_rel,
                                  id_ds_component    => dc.id_ds_component_child,
                                  internal_name      => dc.internal_name_child,
                                  VALUE              => l_def_type,
                                  min_value          => NULL,
                                  max_value          => NULL,
                                  desc_value         => l_def_type,
                                  desc_clob          => NULL,
                                  value_clob         => NULL,
                                  id_unit_measure    => NULL,
                                  desc_unit_measure  => NULL,
                                  flg_validation     => NULL,
                                  err_msg            => NULL,
                                  flg_event_type     => NULL,
                                  flg_multi_status   => NULL,
                                  idx                => 1)
          INTO l_ret
          FROM v_ds_cmpt_mkt_rel dc
         WHERE dc.id_ds_cmpt_mkt_rel = i_id_mkt_rel;
    
        RETURN l_ret;
    
    END get_referral_type;

    FUNCTION get_referral_origin
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_mkt_rel IN NUMBER,
        i_root_name  IN VARCHAR2
    ) RETURN t_rec_ds_get_value IS
        l_value VARCHAR2(100 CHAR);
        l_ret   t_rec_ds_get_value;
        k_inpatient  CONSTANT NUMBER := 11;
        k_outpatient CONSTANT NUMBER := 1;
    BEGIN
    
        CASE i_prof.software
            WHEN k_inpatient THEN
                l_value := 'W';
            WHEN k_outpatient THEN
                l_value := 'O';
            ELSE
                l_value := '';
        END CASE;
    
        l_ret := get_default_values(i_id_mkt_rel => i_id_mkt_rel, i_value => l_value, i_desc_value => l_value);
    
        RETURN l_ret;
    
    END get_referral_origin;

    FUNCTION get_iv_referral_req
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_mkt_rel IN NUMBER,
        i_root_name  IN VARCHAR2
    ) RETURN t_rec_ds_get_value IS
        l_value VARCHAR2(0010 CHAR);
        l_ret   t_rec_ds_get_value;
    BEGIN
    
        l_value := 'N';
    
        l_ret := get_default_values(i_id_mkt_rel => i_id_mkt_rel, i_value => l_value, i_desc_value => l_value);
    
        RETURN l_ret;
    
    END get_iv_referral_req;

    FUNCTION get_vaccines
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_mkt_rel IN NUMBER,
        i_root_name  IN VARCHAR2
    ) RETURN t_rec_ds_get_value IS
    
        l_ret t_rec_ds_get_value;
    BEGIN
    
        SELECT t_rec_ds_get_value(id_ds_cmpt_mkt_rel => i_id_mkt_rel,
                                  id_ds_component    => dc.id_ds_component_child,
                                  internal_name      => dc.internal_name_child,
                                  VALUE              => '',
                                  min_value          => NULL,
                                  max_value          => NULL,
                                  desc_value         => NULL,
                                  desc_clob          => NULL,
                                  value_clob         => pk_message.get_message(i_lang, 'VACC_M014'),
                                  id_unit_measure    => NULL,
                                  desc_unit_measure  => NULL,
                                  flg_validation     => NULL,
                                  err_msg            => NULL,
                                  flg_event_type     => NULL,
                                  flg_multi_status   => NULL,
                                  idx                => 1)
          INTO l_ret
          FROM v_ds_cmpt_mkt_rel dc
         WHERE dc.id_ds_cmpt_mkt_rel = i_id_mkt_rel;
    
        RETURN l_ret;
    
    END get_vaccines;

    FUNCTION get_prof_in_charge
    (
        i_lang       IN NUMBER,
        i_prof       IN profissional,
        i_id_episode IN NUMBER,
        i_id_mkt_rel IN NUMBER
    ) RETURN t_rec_ds_get_value IS
        l_id_prof_mrp NUMBER;
        l_name        VARCHAR2(4000);
        l_ret         t_rec_ds_get_value;
    BEGIN
    
        l_id_prof_mrp := get_episode_mrp(i_lang => i_lang, i_prof => i_prof, i_episode => i_id_episode);
        l_name        := pk_prof_utils.get_name_signature(i_lang, i_prof, l_id_prof_mrp);
    
        SELECT t_rec_ds_get_value(id_ds_cmpt_mkt_rel => i_id_mkt_rel,
                                  id_ds_component    => dc.id_ds_component_child,
                                  internal_name      => dc.internal_name_child,
                                  VALUE              => l_id_prof_mrp,
                                  min_value          => NULL,
                                  max_value          => NULL,
                                  desc_value         => l_name,
                                  desc_clob          => NULL,
                                  value_clob         => NULL,
                                  id_unit_measure    => NULL,
                                  desc_unit_measure  => NULL,
                                  flg_validation     => NULL,
                                  err_msg            => NULL,
                                  flg_event_type     => NULL,
                                  flg_multi_status   => NULL,
                                  idx                => 1)
          INTO l_ret
          FROM v_ds_cmpt_mkt_rel dc
         WHERE dc.id_ds_cmpt_mkt_rel = i_id_mkt_rel;
    
        RETURN l_ret;
    
    END get_prof_in_charge;

    FUNCTION get_consult_in_charge
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_episode       IN episode.id_episode%TYPE,
        i_patient       IN patient.id_patient%TYPE,
        i_internal_name IN VARCHAR2
    ) RETURN t_tbl_core_domain IS
        l_ret t_tbl_core_domain;
        --l_bool        BOOLEAN;
        --l_pat_problem pk_types.cursor_type;
        --        l_            table_number;
    BEGIN
    
        SELECT *
          BULK COLLECT
          INTO l_ret
          FROM (SELECT t_row_core_domain(internal_name => i_internal_name,
                                         desc_domain   => name_prof,
                                         domain_value  => id_professional,
                                         order_rank    => NULL,
                                         img_name      => NULL)
                  FROM (SELECT id_professional,
                               pk_prof_utils.get_name(i_lang => i_lang, i_prof_id => id_professional) name_prof
                          FROM (SELECT xsql.id_professional,
                                       pk_hhc_core.get_prof_flg_mrp(i_lang,
                                                                    profissional(xsql.id_professional,
                                                                                 xsql.id_institution,
                                                                                 i_prof.software)) is_mrp
                                  FROM (SELECT pi.id_professional,
                                               pi.id_institution,
                                               row_number() over(PARTITION BY pi.id_professional ORDER BY pi.dt_begin_tstz DESC) rn
                                          FROM prof_institution pi
                                         WHERE pi.id_institution = i_prof.institution
                                           AND pi.flg_state = pk_alert_constant.g_active) xsql
                                 WHERE rn = 1) x
                         WHERE x.is_mrp = k_yes)
                 ORDER BY name_prof);
    
        RETURN l_ret;
    
    END get_consult_in_charge;

    --*********************************************
    FUNCTION map_rec_2_col
    (
        i_referral_type         IN t_rec_ds_get_value,
        i_referral_origin       IN t_rec_ds_get_value,
        i_iv_referral_req       IN t_rec_ds_get_value,
        i_vaccines              IN t_rec_ds_get_value,
        i_prof_in_charge        IN t_rec_ds_get_value,
        i_firstname             IN t_rec_ds_get_value,
        i_othernames1           IN t_rec_ds_get_value,
        i_lastname              IN t_rec_ds_get_value,
        i_othernames3           IN t_rec_ds_get_value,
        i_phone_mobile          IN t_rec_ds_get_value,
        i_ds_family_rel         IN t_rec_ds_get_value,
        i_ds_family_rel_spec    IN t_rec_ds_get_value,
        i_id_care_giver         IN t_rec_ds_get_value,
        i_prof_in_charge_mphone IN t_rec_ds_get_value,
        i_autotranslate_2       IN t_rec_ds_get_value,
        i_autotranslate_3       IN t_rec_ds_get_value
    ) RETURN t_tbl_ds_get_value IS
        l_ret t_tbl_ds_get_value := t_tbl_ds_get_value();
    BEGIN
    
        l_ret := t_tbl_ds_get_value(i_referral_type,
                                    i_referral_origin,
                                    i_iv_referral_req,
                                    i_vaccines,
                                    i_prof_in_charge,
                                    i_ds_family_rel,
                                    i_ds_family_rel_spec,
                                    i_firstname,
                                    i_othernames1,
                                    i_lastname,
                                    i_othernames3,
                                    i_prof_in_charge_mphone,
                                    i_id_care_giver,
                                    i_phone_mobile,
                                    i_autotranslate_2,
                                    i_autotranslate_3);
    
        RETURN l_ret;
    
    END map_rec_2_col;

    --****************************************************
    FUNCTION get_new_autotranslate(i_id_mkt_rel IN NUMBER) RETURN t_rec_ds_get_value IS
        l_ret t_rec_ds_get_value;
    BEGIN
    
        SELECT t_rec_ds_get_value(id_ds_cmpt_mkt_rel => i_id_mkt_rel,
                                  id_ds_component    => dc.id_ds_component_child,
                                  internal_name      => dc.internal_name_child,
                                  VALUE              => 'Y',
                                  min_value          => NULL,
                                  max_value          => NULL,
                                  desc_value         => 'Y',
                                  desc_clob          => NULL,
                                  value_clob         => NULL,
                                  id_unit_measure    => NULL,
                                  desc_unit_measure  => NULL,
                                  flg_validation     => NULL,
                                  err_msg            => NULL,
                                  flg_event_type     => NULL,
                                  flg_multi_status   => NULL,
                                  idx                => 1)
          INTO l_ret
          FROM v_ds_cmpt_mkt_rel dc
         WHERE dc.id_ds_cmpt_mkt_rel = i_id_mkt_rel;
    
        RETURN l_ret;
    
    END get_new_autotranslate;

    -- ***************************************
    FUNCTION get_new_values
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_episode     IN NUMBER,
        i_patient     IN patient.id_patient%TYPE,
        i_tbl_mkt_rel IN table_number
    ) RETURN t_tbl_ds_get_value IS
    
        tbl_result t_tbl_ds_get_value := t_tbl_ds_get_value();
    
        ds_components table_number;
    
        t_referral_type         t_rec_ds_get_value;
        t_referral_origin       t_rec_ds_get_value;
        t_iv_referral_req       t_rec_ds_get_value;
        t_vaccines              t_rec_ds_get_value;
        t_prof_in_charge        t_rec_ds_get_value;
        t_firstname             t_rec_ds_get_value;
        t_othernames1           t_rec_ds_get_value;
        t_autotranslate_2       t_rec_ds_get_value;
        t_lastname              t_rec_ds_get_value;
        t_othernames3           t_rec_ds_get_value;
        t_autotranslate_3       t_rec_ds_get_value;
        t_phone_mobile          t_rec_ds_get_value;
        t_ds_family_rel         t_rec_ds_get_value;
        t_prof_in_charge_mphone t_rec_ds_get_value;
        t_ds_family_rel_spec    t_rec_ds_get_value;
        t_id_care_giver         t_rec_ds_get_value;
    BEGIN
    
        ds_components := get_ds_components(i_tbl_mkt_rel);
    
        <<lup_thru_ds_components>>
        FOR i IN 1 .. ds_components.count
        LOOP
            CASE ds_components(i)
                WHEN k_ds_referral_type THEN
                    t_referral_type := get_referral_type(i_lang, i_prof, i_patient, i_tbl_mkt_rel(i), '');
                WHEN k_ds_referral_origin THEN
                    t_referral_origin := get_referral_origin(i_lang, i_prof, i_tbl_mkt_rel(i), '');
                WHEN k_ds_iv_referral_required THEN
                    t_iv_referral_req := get_iv_referral_req(i_lang, i_prof, i_tbl_mkt_rel(i), '');
                WHEN k_ds_vaccines THEN
                    t_vaccines := get_vaccines(i_lang, i_prof, i_tbl_mkt_rel(i), '');
                WHEN k_ds_prof_in_charge_name THEN
                    t_prof_in_charge := get_prof_in_charge(i_lang, i_prof, i_episode, i_tbl_mkt_rel(i));
                    --
                WHEN k_ds_prof_in_charge_mobile_num THEN
                    t_prof_in_charge_mphone := get_prof_in_charge_mphone(i_lang       => i_lang,
                                                                         i_prof       => i_prof,
                                                                         i_id_episode => i_episode,
                                                                         i_id_mkt_rel => i_tbl_mkt_rel(i));
                    --
                WHEN k_ds_family_relationship THEN
                    t_ds_family_rel := get_family_rel(i_lang, i_patient, i_tbl_mkt_rel(i));
                WHEN k_ds_family_rel_specify THEN
                    t_ds_family_rel_spec := get_family_rel_spec(i_patient, i_tbl_mkt_rel(i));
                WHEN k_ds_firstname THEN
                    t_firstname := get_first_name(i_patient, i_tbl_mkt_rel(i));
                WHEN k_ds_othernames1 THEN
                    t_othernames1 := get_othernames1(i_patient, i_tbl_mkt_rel(i));
                WHEN k_ds_lastname THEN
                    t_lastname := get_lastname(i_patient, i_tbl_mkt_rel(i));
                WHEN k_ds_othernames3 THEN
                    t_othernames3 := get_othernames3(i_patient, i_tbl_mkt_rel(i));
                WHEN k_ds_phone_mobile THEN
                    t_phone_mobile := get_phone_mobile(i_patient, i_tbl_mkt_rel(i));
                WHEN k_ds_id_care_giver THEN
                    t_id_care_giver := get_id_care_giver(i_patient, i_tbl_mkt_rel(i));
                WHEN k_ds_autotranslate_2 THEN
                    t_autotranslate_2 := get_new_autotranslate(i_tbl_mkt_rel(i));
                WHEN k_ds_autotranslate_3 THEN
                    t_autotranslate_3 := get_new_autotranslate(i_tbl_mkt_rel(i));
                ELSE
                    NULL;
            END CASE;
        
        END LOOP lup_thru_ds_components;
    
        tbl_result := map_rec_2_col(i_referral_type         => t_referral_type,
                                    i_referral_origin       => t_referral_origin,
                                    i_iv_referral_req       => t_iv_referral_req,
                                    i_vaccines              => t_vaccines,
                                    i_prof_in_charge        => t_prof_in_charge,
                                    i_firstname             => t_firstname,
                                    i_othernames1           => t_othernames1,
                                    i_lastname              => t_lastname,
                                    i_othernames3           => t_othernames3,
                                    i_phone_mobile          => t_phone_mobile,
                                    i_ds_family_rel         => t_ds_family_rel,
                                    i_ds_family_rel_spec    => t_ds_family_rel_spec,
                                    i_id_care_giver         => t_id_care_giver,
                                    i_prof_in_charge_mphone => t_prof_in_charge_mphone,
                                    i_autotranslate_2       => t_autotranslate_2,
                                    i_autotranslate_3       => t_autotranslate_3);
    
        RETURN tbl_result;
    
    END get_new_values;

    FUNCTION get_default_values_hhc
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_episode        IN episode.id_episode%TYPE,
        i_patient        IN patient.id_patient%TYPE,
        i_action         IN NUMBER, -- edit, new, submit
        i_root_name      IN VARCHAR2, -- root of dynamic screen
        i_curr_component IN NUMBER,
        i_tbl_id_pk      IN table_number, -- id necessary for identifying pk for editing
        i_tbl_mkt_rel    IN table_number, -- components needed for default/edit
        i_value          IN table_table_varchar,
        i_value_clob     IN table_clob,
        o_error          OUT t_error_out
    ) RETURN t_tbl_ds_get_value IS
        l_error VARCHAR2(1000 CHAR);
    
        tbl_result t_tbl_ds_get_value := t_tbl_ds_get_value();
    
    BEGIN
    
        CASE i_action
            WHEN k_action_edit THEN
                l_error    := 'get_edit_values';
                tbl_result := get_edit_values(i_lang,
                                              i_prof,
                                              i_episode,
                                              i_patient,
                                              i_tbl_id_pk(1),
                                              i_root_name
                                              --,o_error
                                              );
            WHEN k_action_add THEN
                l_error    := 'get_add_values';
                tbl_result := get_new_values(i_lang        => i_lang,
                                             i_prof        => i_prof,
                                             i_episode     => i_episode,
                                             i_patient     => i_patient,
                                             i_tbl_mkt_rel => i_tbl_mkt_rel);
            WHEN pk_dyn_form_constant.get_submit_action() THEN
                l_error    := 'get_submit_values';
                tbl_result := get_submit_values(i_lang           => i_lang,
                                                i_prof           => i_prof,
                                                i_episode        => i_episode,
                                                i_patient        => i_patient,
                                                i_root_name      => i_root_name,
                                                i_curr_component => i_curr_component,
                                                i_tbl_mkt_rel    => i_tbl_mkt_rel,
                                                i_value          => i_value,
                                                i_value_clob     => i_value_clob,
                                                o_error          => o_error);
            ELSE
                NULL;
        END CASE;
    
        RETURN tbl_result;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              l_error,
                                              g_owner,
                                              g_package,
                                              'GET_DEFAULT_VALUES_HHC',
                                              o_error);
            RETURN NULL;
    END get_default_values_hhc;

    --função para obter os tipos que possam uma opção de resposta
    --devolve os tipos em comum entre dois registos de histórico
    FUNCTION tf_get_tbl_component_com
    (
        --i_lang            IN language.id_language%TYPE,
        --i_prof            IN profissional,
        i_id_epis_hhc_req IN epis_hhc_req_det_h.id_epis_hhc_req%TYPE,
        i_id_group_old    epis_hhc_req_det_h.id_group%TYPE,
        i_id_group_new    epis_hhc_req_det_h.id_group%TYPE,
        i_comp_special    IN table_number
    ) RETURN table_number IS
        l_rec_hist_component_com table_number;
    BEGIN
    
        SELECT t.id_hhc_det_type
          BULK COLLECT
          INTO l_rec_hist_component_com
          FROM (
                
                SELECT x.id_hhc_det_type id_hhc_det_type
                  FROM epis_hhc_req_det_h x
                  JOIN hhc_det_type xx
                    ON xx.id_hhc_det_type = x.id_hhc_det_type
                 WHERE x.id_epis_hhc_req = i_id_epis_hhc_req
                   AND x.id_group = i_id_group_old
                   AND x.id_hhc_det_type NOT IN (SELECT /*+ opt_estimate(table t rows=1) */
                                                  t.*
                                                   FROM TABLE(i_comp_special) t)
                INTERSECT
                SELECT x.id_hhc_det_type id_hhc_det_type
                  FROM epis_hhc_req_det_h x
                  JOIN hhc_det_type xx
                    ON xx.id_hhc_det_type = x.id_hhc_det_type
                 WHERE x.id_epis_hhc_req = i_id_epis_hhc_req
                   AND x.id_group = i_id_group_new
                   AND x.id_hhc_det_type NOT IN (SELECT /*+ opt_estimate(table t rows=1) */
                                                  t.*
                                                   FROM TABLE(i_comp_special) t)
                
                ) t;
        RETURN l_rec_hist_component_com;
    END tf_get_tbl_component_com;

    --
    --função para obter os tipos que possam ter mais do que uma opção de resposta
    --devolve os tipos em comum entre dois registos de histórico
    FUNCTION tf_get_tbl_component_com_spec
    (
        --i_lang            IN language.id_language%TYPE,
        --i_prof            IN profissional,
        i_id_epis_hhc_req IN epis_hhc_req_det_h.id_epis_hhc_req%TYPE,
        i_id_group_old    IN epis_hhc_req_det_h.id_group%TYPE,
        i_id_group_new    IN epis_hhc_req_det_h.id_group%TYPE,
        i_comp_special    IN table_number
    ) RETURN table_number IS
    
        l_rec_hist_component_com_spec table_number;
    
    BEGIN
    
        SELECT t.id_hhc_det_type
          BULK COLLECT
          INTO l_rec_hist_component_com_spec
          FROM (SELECT x.id_hhc_det_type id_hhc_det_type
                  FROM epis_hhc_req_det_h x
                  JOIN hhc_det_type xx
                    ON xx.id_hhc_det_type = x.id_hhc_det_type
                 WHERE x.id_epis_hhc_req = i_id_epis_hhc_req
                   AND x.id_group = i_id_group_old
                   AND x.id_hhc_det_type IN (SELECT /*+ opt_estimate(table t rows=1) */
                                              t.*
                                               FROM TABLE(i_comp_special) t)
                INTERSECT
                SELECT x.id_hhc_det_type id_hhc_det_type
                  FROM epis_hhc_req_det_h x
                  JOIN hhc_det_type xx
                    ON xx.id_hhc_det_type = x.id_hhc_det_type
                 WHERE x.id_epis_hhc_req = i_id_epis_hhc_req
                   AND x.id_group = i_id_group_new
                   AND x.id_hhc_det_type IN (SELECT /*+ opt_estimate(table t rows=1) */
                                              t.*
                                               FROM TABLE(i_comp_special) t)) t;
    
        RETURN l_rec_hist_component_com_spec;
    
    END tf_get_tbl_component_com_spec;

    --função para obter os tipos que possam ter uma opção de resposta
    --é utilizada para devolver s tipos adicionados, ou os tipos eliminados
    FUNCTION tf_get_tbl_component_add_del
    (
        --i_lang            IN language.id_language%TYPE,
        --i_prof            IN profissional,
        i_id_epis_hhc_req IN epis_hhc_req_det_h.id_epis_hhc_req%TYPE,
        i_id_group_new    IN epis_hhc_req_det_h.id_group%TYPE,
        i_id_group_old    IN epis_hhc_req_det_h.id_group%TYPE,
        i_comp_special    IN table_number
    ) RETURN table_number IS
    
        l_rec_hist_component table_number;
    
    BEGIN
    
        SELECT t.id_hhc_det_type
          BULK COLLECT
          INTO l_rec_hist_component
          FROM (SELECT x.id_hhc_det_type id_hhc_det_type
                  FROM epis_hhc_req_det_h x
                  JOIN hhc_det_type xx
                    ON xx.id_hhc_det_type = x.id_hhc_det_type
                 WHERE x.id_epis_hhc_req = i_id_epis_hhc_req
                   AND x.id_group = i_id_group_new
                   AND x.id_hhc_det_type NOT IN (SELECT /*+ opt_estimate(table t rows=1) */
                                                  t.*
                                                   FROM TABLE(i_comp_special) t)
                MINUS
                SELECT x.id_hhc_det_type id_hhc_det_type
                  FROM epis_hhc_req_det_h x
                  JOIN hhc_det_type xx
                    ON xx.id_hhc_det_type = x.id_hhc_det_type
                 WHERE x.id_epis_hhc_req = i_id_epis_hhc_req
                   AND x.id_group = i_id_group_old
                   AND x.id_hhc_det_type NOT IN (SELECT /*+ opt_estimate(table t rows=1) */
                                                  t.*
                                                   FROM TABLE(i_comp_special) t)) t;
    
        RETURN l_rec_hist_component;
    
    END tf_get_tbl_component_add_del;
    --
    --função para obter os tipos que possam ter mais do que uma opção de resposta
    --é utilizada para devolver s tipos adicionados, ou os tipos eliminados
    FUNCTION tf_tbl_comp_add_del_spec
    (
        --i_lang            IN language.id_language%TYPE,
        --i_prof            IN profissional,
        i_id_epis_hhc_req IN epis_hhc_req_det_h.id_epis_hhc_req%TYPE,
        i_id_group_new    IN epis_hhc_req_det_h.id_group%TYPE,
        i_id_group_old    IN epis_hhc_req_det_h.id_group%TYPE,
        i_comp_special    IN table_number
    ) RETURN table_number IS
    
        l_rec_hist_component table_number;
    
    BEGIN
    
        SELECT id_hhc_det_type
          BULK COLLECT
          INTO l_rec_hist_component
          FROM (SELECT t.id_hhc_det_type
                  FROM (SELECT x.hhc_value, x.id_hhc_det_type id_hhc_det_type
                          FROM v_epis_hhc_req_det_h x
                          JOIN v_hhc_det_type xx
                            ON xx.id_hhc_det_type = x.id_hhc_det_type
                         WHERE x.id_epis_hhc_req = i_id_epis_hhc_req
                           AND x.id_group = i_id_group_new
                           AND x.id_hhc_det_type IN (SELECT /*+ opt_estimate(table t rows=1) */
                                                      t.*
                                                       FROM TABLE(i_comp_special) t)
                        MINUS
                        SELECT x.hhc_value, x.id_hhc_det_type id_hhc_det_type
                          FROM epis_hhc_req_det_h x
                          JOIN hhc_det_type xx
                            ON xx.id_hhc_det_type = x.id_hhc_det_type
                         WHERE x.id_epis_hhc_req = i_id_epis_hhc_req
                           AND x.id_group = i_id_group_old
                           AND x.id_hhc_det_type IN (SELECT /*+ opt_estimate(table t rows=1) */
                                                      t.*
                                                       FROM TABLE(i_comp_special) t)) t);
        RETURN l_rec_hist_component;
    
    END tf_tbl_comp_add_del_spec;

    --Função para obter os valores de uma secção que possa ter mais do que um valor na resposta
    FUNCTION get_spec_types
    (
        i_id_epis_hhc_req IN epis_hhc_req_det_h.id_epis_hhc_req%TYPE,
        i_id_group_old    IN epis_hhc_req_det_h.id_group%TYPE,
        i_id_group_new    IN epis_hhc_req_det_h.id_group%TYPE,
        i_id_hhc_det_type IN epis_hhc_req_det_h.id_hhc_det_type%TYPE
    ) RETURN NUMBER IS
    
        l_exist_add NUMBER;
        l_exist_rem NUMBER;
    
    BEGIN
        --verifica se foram adicionado valores
        SELECT COUNT(*)
          INTO l_exist_add
          FROM (SELECT x.hhc_value
                  FROM v_epis_hhc_req_det_h x
                  JOIN v_hhc_det_type xx
                    ON xx.id_hhc_det_type = x.id_hhc_det_type
                 WHERE x.id_epis_hhc_req = i_id_epis_hhc_req
                   AND x.id_group = i_id_group_new
                   AND x.id_hhc_det_type = i_id_hhc_det_type
                   AND nvl(x.hhc_value, 'xYzZ') NOT IN
                       (SELECT x.hhc_value
                          FROM v_epis_hhc_req_det_h x
                          JOIN v_hhc_det_type xx
                            ON xx.id_hhc_det_type = x.id_hhc_det_type
                         WHERE x.id_epis_hhc_req = i_id_epis_hhc_req
                           AND x.id_group = i_id_group_old
                           AND x.id_hhc_det_type = i_id_hhc_det_type));
    
        -- verifica se foram removidos valores
        SELECT COUNT(1)
          INTO l_exist_rem
          FROM (SELECT x.hhc_value
                  FROM v_epis_hhc_req_det_h x
                  JOIN v_hhc_det_type xx
                    ON xx.id_hhc_det_type = x.id_hhc_det_type
                 WHERE x.id_epis_hhc_req = i_id_epis_hhc_req
                   AND x.id_group = i_id_group_old
                   AND x.id_hhc_det_type = i_id_hhc_det_type
                   AND nvl(x.hhc_value, 'xYzZ') NOT IN
                       (SELECT x.hhc_value
                          FROM v_epis_hhc_req_det_h x
                          JOIN v_hhc_det_type xx
                            ON xx.id_hhc_det_type = x.id_hhc_det_type
                         WHERE x.id_epis_hhc_req = i_id_epis_hhc_req
                           AND x.id_group = i_id_group_new
                           AND x.id_hhc_det_type = i_id_hhc_det_type));
    
        RETURN l_exist_rem + l_exist_add;
    
    END get_spec_types;
    --
    --get id_group from request
    FUNCTION get_req_hist_id_group(i_id_epis_req IN epis_hhc_req_det_h.id_epis_hhc_req%TYPE)
        RETURN epis_hhc_req_det_h.id_group%TYPE IS
        l_id_group epis_hhc_req_det_h.id_group%TYPE;
    BEGIN
    
        SELECT id_group
          INTO l_id_group
          FROM (SELECT x.id_group, row_number() over(PARTITION BY x.id_epis_hhc_req ORDER BY x.dt_creation) rn
                  FROM v_epis_hhc_req_det_h x
                 WHERE x.id_epis_hhc_req = i_id_epis_req)
         WHERE rn = 1;
        RETURN l_id_group;
    
    END get_req_hist_id_group;

    FUNCTION get_id_epis_hhc_by_hhc_req(i_id_hhc_req IN epis_hhc_req.id_epis_hhc_req%TYPE)
        RETURN epis_hhc_req.id_epis_hhc%TYPE IS
        l_id_epis_hhc epis_hhc_req.id_epis_hhc%TYPE;
    BEGIN
    
        SELECT id_epis_hhc
          INTO l_id_epis_hhc
          FROM v_epis_hhc_req
         WHERE id_epis_hhc_req = i_id_hhc_req;
    
        RETURN l_id_epis_hhc;
    
    EXCEPTION
        WHEN no_data_found THEN
            RETURN NULL;
        
    END get_id_epis_hhc_by_hhc_req;
    --obtem o histórico de alterações
    FUNCTION get_hhc_req_det_hist
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_tbl_id_req IN table_number,
        i_flg_report IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        o_detail     OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
        CURSOR c_values_new
        (
            i_id_req          IN v_epis_hhc_req_det_h.id_epis_hhc_req%TYPE,
            i_id_group        IN epis_hhc_req_det_h.id_group%TYPE,
            i_id_hhc_det_type IN epis_hhc_req_det_h.id_hhc_det_type%TYPE,
            i_components      IN t_dyn_tree_table
        ) IS
            SELECT pk_hhc_core.get_detail_description(i_lang, i_prof, dt.flg_type, dt.type_name, dh.hhc_value) hhc_value,
                   dh.dt_creation,
                   dh.id_prof_creation,
                   pk_message.get_message(i_lang, dsc.code_component_h_edit) text_edit,
                   pk_message.get_message(i_lang, dsc.code_component_h_new) text_new,
                   pk_message.get_message(i_lang, dsc.code_component_h_del) text_del,
                   dsc.code_component_h_edit ds_code_edit,
                   dsc.code_ds_component ds_code,
                   dcr.id_ds_component_parent id_component_parent
              FROM v_epis_hhc_req_det_h dh
              JOIN v_hhc_det_type dt
                ON dt.id_hhc_det_type = dh.id_hhc_det_type
              JOIN v_ds_component dsc
                ON dsc.internal_name = dt.internal_name
              JOIN v_ds_cmpt_mkt_rel dcr
                ON dcr.internal_name_child = dsc.internal_name
              JOIN (SELECT /*+ opt_estimate(table t rows=1) */
                     t.*
                      FROM TABLE(i_components) t) xsql
                ON dcr.id_ds_cmpt_mkt_rel = xsql.id_ds_cmpt_mkt_rel
             WHERE dh.id_epis_hhc_req = i_id_req
               AND dh.id_group = i_id_group
               AND dh.id_hhc_det_type = i_id_hhc_det_type
               AND dt.internal_name != pk_hhc_constant.k_ds_adt_id_care_giver
             ORDER BY id_component_parent, dt_creation DESC;
    
        CURSOR c_values_old
        (
            i_id_req          IN v_epis_hhc_req_det_h.id_epis_hhc_req%TYPE,
            i_id_group        IN epis_hhc_req_det_h.id_group%TYPE,
            i_id_hhc_det_type IN epis_hhc_req_det_h.id_hhc_det_type%TYPE,
            i_components      IN t_dyn_tree_table
        ) IS
            SELECT pk_hhc_core.get_detail_description(i_lang, i_prof, dt.flg_type, dt.type_name, dh.hhc_value) hhc_value,
                   dh.dt_creation,
                   dh.id_prof_creation,
                   dsc.code_component_h_edit ds_code_edit,
                   dsc.code_ds_component ds_code,
                   dcr.id_ds_component_parent id_component_parent
              FROM v_epis_hhc_req_det_h dh
              JOIN v_hhc_det_type dt
                ON dt.id_hhc_det_type = dh.id_hhc_det_type
              JOIN v_ds_component dsc
                ON dsc.internal_name = dt.internal_name
              JOIN v_ds_cmpt_mkt_rel dcr
                ON dcr.internal_name_child = dsc.internal_name
              JOIN (SELECT /*+ opt_estimate(table t rows=1) */
                     t.*
                      FROM TABLE(i_components) t) xsql
                ON dcr.id_ds_cmpt_mkt_rel = xsql.id_ds_cmpt_mkt_rel
             WHERE dh.id_epis_hhc_req = i_id_req
               AND dh.id_group = i_id_group
               AND dh.id_hhc_det_type = i_id_hhc_det_type
               AND dt.internal_name != pk_hhc_constant.k_ds_adt_id_care_giver
             ORDER BY id_component_parent, dt_creation DESC;
    
        CURSOR c_data_old
        (
            i_lang            IN language.id_language%TYPE,
            i_id_epis_hhc_req IN epis_hhc_req_det_h.id_epis_hhc_req%TYPE,
            i_rec_hist        IN table_number,
            i_id_group        IN epis_hhc_req_det_h.id_group%TYPE,
            i_components      IN t_dyn_tree_table
        ) IS
            SELECT h.id_hhc_det_type id_hhc_det_type,
                   h.id_epis_hhc_req_det id_epis_hhc_req_det,
                   dt.flg_type flg_type,
                   pk_hhc_core.get_detail_description(i_lang, i_prof, dt.flg_type, dt.type_name, h.hhc_value) hhc_value,
                   h.hhc_text hhc_text,
                   pk_message.get_message(i_lang, dc.code_component_h_edit) text_edit,
                   pk_message.get_message(i_lang, dc.code_component_h_new) text_new,
                   pk_message.get_message(i_lang, dc.code_component_h_del) text_del,
                   h.dt_creation,
                   pk_message.get_message(i_lang, dc.code_ds_component) text,
                   h.id_prof_creation,
                   dcr.id_ds_component_parent id_component_parent
              FROM v_epis_hhc_req_det_h h
              JOIN v_hhc_det_type dt
                ON h.id_hhc_det_type = dt.id_hhc_det_type
              JOIN v_ds_component dc
                ON dc.internal_name = dt.internal_name
              JOIN v_ds_cmpt_mkt_rel dcr
                ON dcr.internal_name_child = dc.internal_name
              JOIN (SELECT /*+ opt_estimate(table xpto rows=1) */
                     t.*
                      FROM TABLE(i_components) t) xsql
                ON dcr.id_ds_cmpt_mkt_rel = xsql.id_ds_cmpt_mkt_rel
             WHERE h.id_epis_hhc_req = i_id_epis_hhc_req
               AND h.id_hhc_det_type IN (SELECT /*+ opt_estimate(table t rows=1) */
                                          column_value
                                           FROM TABLE(i_rec_hist) t)
               AND id_group = i_id_group
               AND dt.internal_name != pk_hhc_constant.k_ds_adt_id_care_giver
             ORDER BY id_component_parent, dt_creation DESC;
    
        CURSOR c_data_new
        (
            i_lang            IN language.id_language%TYPE,
            i_id_epis_hhc_req IN epis_hhc_req_det_h.id_epis_hhc_req%TYPE,
            i_rec_hist        IN epis_hhc_req_det_h.id_hhc_det_type%TYPE,
            i_id_group        IN epis_hhc_req_det_h.id_group%TYPE,
            i_components      IN t_dyn_tree_table
        ) IS
            SELECT h.id_hhc_det_type id_hhc_det_type,
                   h.id_epis_hhc_req_det id_epis_hhc_req_det,
                   dt.flg_type flg_type,
                   pk_hhc_core.get_detail_description(i_lang, i_prof, dt.flg_type, dt.type_name, h.hhc_value) hhc_value,
                   h.hhc_text hhc_text,
                   pk_message.get_message(i_lang, dc.code_component_h_edit) text_,
                   h.dt_creation,
                   h.id_prof_creation
              FROM v_epis_hhc_req_det_h h
              JOIN v_hhc_det_type dt
                ON h.id_hhc_det_type = dt.id_hhc_det_type
              JOIN v_ds_component dc
                ON dc.internal_name = dt.internal_name
              JOIN v_ds_cmpt_mkt_rel dcr
                ON dcr.internal_name_child = dc.internal_name
              JOIN (SELECT /*+ opt_estimate(table t rows=1) */
                     t.id_ds_cmpt_mkt_rel
                      FROM TABLE(i_components) t) xsql
                ON dcr.id_ds_cmpt_mkt_rel = xsql.id_ds_cmpt_mkt_rel
             WHERE h.id_epis_hhc_req = i_id_epis_hhc_req
               AND h.id_hhc_det_type = i_rec_hist
               AND h.id_group = i_id_group
             ORDER BY dt_creation DESC;
    
        l_tbl_grp table_number;
        --l_req_hist  t_coll_hhc_req_hist := t_coll_hhc_req_hist();
        l_req_det   t_coll_hhc_req_hist := t_coll_hhc_req_hist();
        l_req_det_c t_coll_hhc_req_hist := t_coll_hhc_req_hist();
    
        l_rec_hist_com table_number;
        l_detail       pk_types.cursor_type;
        l_detail_c     pk_types.cursor_type;
        l_descr        VARCHAR2(4000);
        l_type         VARCHAR2(3);
    
        --indices para os ciclos
        index_a NUMBER;
        index_b NUMBER;
        --index_t NUMBER := 1;
    
        l_data_new  epis_hhc_req_det_h.dt_creation%TYPE;
        l_val       CLOB;
        l_val_sign  VARCHAR2(500);
        l_value_new VARCHAR2(4000);
        l_value_old VARCHAR2(4000);
    
        l_descr_new   VARCHAR2(4000);
        l_descr_old   VARCHAR2(4000);
        l_total_grp   NUMBER;
        l_desc_sign   sys_message.desc_message%TYPE;
        l_text_header sys_message.desc_message%TYPE;
    
        l_id_prof_creation epis_hhc_req_det_h.id_prof_creation%TYPE;
        l_func_name CONSTANT VARCHAR2(25 CHAR) := 'get_hhc_req_det_hist';
        l_flag_status_detail VARCHAR2(0010 CHAR);
    
        l_id_group   epis_hhc_req_det_h.id_group%TYPE;
        l_components t_dyn_tree_table;
        l_internal_error EXCEPTION;
        l_id_request    epis_hhc_req.id_epis_hhc_req%TYPE;
        l_tbl_value_old t_coll_hhc_req_hist := t_coll_hhc_req_hist();
        l_tbl_value_new t_coll_hhc_req_hist := t_coll_hhc_req_hist();
    BEGIN
    
        l_components := pk_dyn_form.get_dyn_cfg(i_lang           => i_lang,
                                                i_prof           => i_prof,
                                                i_patient        => NULL,
                                                i_component_name => 'DS_HHC_REQUEST',
                                                i_action         => NULL);
    
        g_error := 'GET THE HHC_DET_TYPE IDS FOR SPECIAL CASES';
        SELECT DISTINCT id_hhc_det_type
          BULK COLLECT
          INTO g_comp_special
          FROM (SELECT hdt.id_hhc_det_type, dcmr.rank
                  FROM v_hhc_det_type hdt
                  JOIN v_ds_cmpt_mkt_rel dcmr
                    ON dcmr.internal_name_child = hdt.internal_name
                  JOIN v_ds_component dc
                    ON dcmr.id_ds_component_child = dc.id_ds_component
                 WHERE dc.flg_data_type IN (pk_hhc_constant.k_hhc_flg_data_type_ms,
                                            pk_hhc_constant.k_hhc_flg_data_type_cb,
                                            pk_hhc_constant.k_hhc_flg_data_type_mw)
                   AND dc.internal_name NOT IN (k_ds_adt_name_fam_rel)
                 ORDER BY dcmr.rank);
    
        --TEXT FOR SIGNATURE
        l_desc_sign := pk_message.get_message(i_lang => i_lang, i_code_mess => 'COMMON_M107');
    
        FOR req IN i_tbl_id_req.first() .. i_tbl_id_req.last()
        LOOP
            l_id_request := i_tbl_id_req(req);
        
            SELECT DISTINCT id_group
              BULK COLLECT
              INTO l_tbl_grp
              FROM epis_hhc_req_det_h
             WHERE id_epis_hhc_req = i_tbl_id_req(req)
             ORDER BY id_group DESC;
        
            l_total_grp := l_tbl_grp.count() - 1;
        
            IF l_total_grp > 0
            THEN
                FOR s IN 1 .. l_total_grp
                LOOP
                
                    index_a        := s;
                    index_b        := s + 1;
                    l_rec_hist_com := tf_get_tbl_component_com(i_tbl_id_req(req),
                                                               l_tbl_grp(index_a),
                                                               l_tbl_grp(index_b),
                                                               g_comp_special);
                
                    FOR r IN c_data_old(i_lang, i_tbl_id_req(req), l_rec_hist_com, l_tbl_grp(index_b), l_components)
                    LOOP
                    
                        FOR s IN c_data_new(i_lang,
                                            i_tbl_id_req(req),
                                            r.id_hhc_det_type,
                                            l_tbl_grp(index_a),
                                            l_components)
                        LOOP
                            --text fields
                            --updated record
                            IF r.id_hhc_det_type = s.id_hhc_det_type
                               AND r.hhc_value != s.hhc_value
                               AND r.hhc_value IS NOT NULL
                               AND s.hhc_value IS NOT NULL
                            THEN
                            
                                IF l_text_header IS NULL
                                   OR l_text_header != get_cmpt_desc_by_id(i_lang, r.id_component_parent)
                                THEN
                                    l_text_header := get_cmpt_desc_by_id(i_lang, r.id_component_parent);
                                ELSE
                                    l_text_header := NULL;
                                END IF;
                            
                                l_value_new := s.hhc_value;
                                l_value_old := r.hhc_value;
                                l_descr_new := r.text_edit || pk_alert_constant.g_two_points;
                                l_descr_old := r.text || pk_alert_constant.g_two_points;
                                l_val_sign  := get_prof_signature(i_lang         => i_lang,
                                                                  i_prof         => i_prof,
                                                                  i_id_prof_sign => s.id_prof_creation,
                                                                  i_date         => s.dt_creation);
                                IF NOT set_val_rec_hhc_req_type(i_lang        => i_lang,
                                                                i_flg_report  => i_flg_report,
                                                                i_id_request  => l_id_request,
                                                                i_text_header => l_text_header,
                                                                i_descr_new   => l_descr_new,
                                                                i_descr_old   => l_descr_old,
                                                                i_value_new   => l_value_new,
                                                                i_value_old   => l_value_old,
                                                                i_desc_sign   => l_desc_sign,
                                                                i_val_sign    => l_val_sign)
                                THEN
                                    RAISE l_internal_error;
                                END IF;
                                l_text_header := get_cmpt_desc_by_id(i_lang, r.id_component_parent);
                                l_data_new    := s.dt_creation;
                            
                                --new records
                            ELSIF r.id_hhc_det_type = s.id_hhc_det_type
                                  AND (r.hhc_value != s.hhc_value OR r.hhc_value IS NULL)
                                  AND r.hhc_value IS NULL
                                  AND s.hhc_value IS NOT NULL
                            THEN
                            
                                IF l_text_header IS NULL
                                   OR l_text_header != get_cmpt_desc_by_id(i_lang, r.id_component_parent)
                                THEN
                                    l_text_header := get_cmpt_desc_by_id(i_lang, r.id_component_parent);
                                ELSE
                                    l_text_header := NULL;
                                END IF;
                                l_value_new := s.hhc_value;
                                l_descr_new := r.text_new || pk_alert_constant.g_two_points;
                            
                                l_val_sign := get_prof_signature(i_lang         => i_lang,
                                                                 i_prof         => i_prof,
                                                                 i_id_prof_sign => s.id_prof_creation,
                                                                 i_date         => s.dt_creation);
                            
                                IF NOT set_val_rec_hhc_req_type(i_lang        => i_lang,
                                                                i_flg_report  => i_flg_report,
                                                                i_id_request  => l_id_request,
                                                                i_text_header => l_text_header,
                                                                i_descr_new   => l_descr_new,
                                                                i_descr_old   => NULL,
                                                                i_value_new   => l_value_new,
                                                                i_value_old   => NULL,
                                                                i_desc_sign   => l_desc_sign,
                                                                i_val_sign    => l_val_sign)
                                THEN
                                    RAISE l_internal_error;
                                END IF;
                                l_text_header := get_cmpt_desc_by_id(i_lang, r.id_component_parent);
                            
                                --deleted records
                            ELSIF r.id_hhc_det_type = s.id_hhc_det_type
                                  AND (r.hhc_value != s.hhc_value OR s.hhc_value IS NULL)
                                  AND r.hhc_value IS NOT NULL
                                  AND s.hhc_value IS NULL
                            THEN
                            
                                IF l_text_header IS NULL
                                   OR l_text_header != get_cmpt_desc_by_id(i_lang, r.id_component_parent)
                                THEN
                                    l_text_header := get_cmpt_desc_by_id(i_lang, r.id_component_parent);
                                ELSE
                                    l_text_header := NULL;
                                END IF;
                                l_value_new := r.hhc_value;
                                l_val_sign  := get_prof_signature(i_lang         => i_lang,
                                                                  i_prof         => i_prof,
                                                                  i_id_prof_sign => s.id_prof_creation,
                                                                  i_date         => s.dt_creation);
                            
                                IF NOT set_val_rec_hhc_req_type(i_lang        => i_lang,
                                                                i_flg_report  => i_flg_report,
                                                                i_id_request  => l_id_request,
                                                                i_text_header => l_text_header,
                                                                i_descr_new   => l_descr_new,
                                                                i_descr_old   => NULL,
                                                                i_value_new   => l_value_new,
                                                                i_value_old   => NULL,
                                                                i_desc_sign   => l_desc_sign,
                                                                i_val_sign    => l_val_sign)
                                THEN
                                    RAISE l_internal_error;
                                END IF;
                                l_text_header := get_cmpt_desc_by_id(i_lang, r.id_component_parent);
                            
                                --clob fields
                                --updated records
                            ELSIF r.id_hhc_det_type = s.id_hhc_det_type
                                  AND dbms_lob.compare(r.hhc_text, s.hhc_text) != 0
                                  AND ((r.hhc_text != empty_clob() AND s.hhc_text != empty_clob()))
                            
                            THEN
                                IF l_text_header IS NULL
                                   OR l_text_header != get_cmpt_desc_by_id(i_lang, r.id_component_parent)
                                THEN
                                    l_text_header := get_cmpt_desc_by_id(i_lang, r.id_component_parent);
                                ELSE
                                    l_text_header := NULL;
                                END IF;
                                l_text_header := get_cmpt_desc_by_id(i_lang, r.id_component_parent);
                                l_descr_new   := r.text_edit || pk_alert_constant.g_two_points;
                                l_descr_old   := r.text || pk_alert_constant.g_two_points;
                                l_value_new   := s.hhc_text;
                                l_value_old   := r.hhc_text;
                                l_val_sign    := get_prof_signature(i_lang         => i_lang,
                                                                    i_prof         => i_prof,
                                                                    i_id_prof_sign => s.id_prof_creation,
                                                                    i_date         => s.dt_creation);
                            
                                IF NOT set_val_rec_hhc_req_type(i_lang        => i_lang,
                                                                i_flg_report  => i_flg_report,
                                                                i_id_request  => l_id_request,
                                                                i_text_header => l_text_header,
                                                                i_descr_new   => l_descr_new,
                                                                i_descr_old   => l_descr_old,
                                                                i_value_new   => l_value_new,
                                                                i_value_old   => l_value_old,
                                                                i_desc_sign   => l_desc_sign,
                                                                i_val_sign    => l_val_sign)
                                THEN
                                    RAISE l_internal_error;
                                END IF;
                                l_text_header := get_cmpt_desc_by_id(i_lang, r.id_component_parent);
                            
                                --new records
                            ELSIF r.id_hhc_det_type = s.id_hhc_det_type
                                  AND dbms_lob.compare(r.hhc_text, nvl(s.hhc_text, 'XyZYZxX')) != 0
                                  AND ((r.hhc_text = empty_clob() AND s.hhc_text != empty_clob()))
                            THEN
                            
                                IF l_text_header IS NULL
                                   OR l_text_header != get_cmpt_desc_by_id(i_lang, r.id_component_parent)
                                THEN
                                    l_text_header := get_cmpt_desc_by_id(i_lang, r.id_component_parent);
                                ELSE
                                    l_text_header := NULL;
                                END IF;
                                l_value_new := s.hhc_text;
                                l_descr_new := r.text_new || pk_alert_constant.g_two_points;
                            
                                l_val_sign := get_prof_signature(i_lang         => i_lang,
                                                                 i_prof         => i_prof,
                                                                 i_id_prof_sign => s.id_prof_creation,
                                                                 i_date         => s.dt_creation);
                            
                                IF NOT set_val_rec_hhc_req_type(i_lang        => i_lang,
                                                                i_flg_report  => i_flg_report,
                                                                i_id_request  => l_id_request,
                                                                i_text_header => l_text_header,
                                                                i_descr_new   => l_descr_new,
                                                                i_descr_old   => NULL,
                                                                i_value_new   => l_value_new,
                                                                i_value_old   => NULL,
                                                                i_desc_sign   => l_desc_sign,
                                                                i_val_sign    => l_val_sign)
                                THEN
                                    RAISE l_internal_error;
                                END IF;
                                l_text_header := get_cmpt_desc_by_id(i_lang, r.id_component_parent);
                            
                                --deleted records
                            ELSIF r.id_hhc_det_type = s.id_hhc_det_type
                                  AND dbms_lob.compare(nvl(r.hhc_text, 'XyZYZxX'), s.hhc_text) != 0
                                  AND ((r.hhc_text != empty_clob() AND s.hhc_text = empty_clob()))
                            THEN
                            
                                IF l_text_header IS NULL
                                   OR l_text_header != get_cmpt_desc_by_id(i_lang, r.id_component_parent)
                                THEN
                                    l_text_header := get_cmpt_desc_by_id(i_lang, r.id_component_parent);
                                ELSE
                                    l_text_header := NULL;
                                END IF;
                                l_value_new := s.hhc_text;
                                l_descr_new := r.text_del || pk_alert_constant.g_two_points;
                            
                                l_val_sign := get_prof_signature(i_lang         => i_lang,
                                                                 i_prof         => i_prof,
                                                                 i_id_prof_sign => s.id_prof_creation,
                                                                 i_date         => s.dt_creation);
                            
                                IF NOT set_val_rec_hhc_req_type(i_lang        => i_lang,
                                                                i_flg_report  => i_flg_report,
                                                                i_id_request  => l_id_request,
                                                                i_text_header => l_text_header,
                                                                i_descr_new   => l_descr_new,
                                                                i_descr_old   => NULL,
                                                                i_value_new   => l_value_new,
                                                                i_value_old   => NULL,
                                                                i_desc_sign   => l_desc_sign,
                                                                i_val_sign    => l_val_sign)
                                THEN
                                    RAISE l_internal_error;
                                END IF;
                                l_text_header := get_cmpt_desc_by_id(i_lang, r.id_component_parent);
                            END IF;
                        END LOOP;
                    END LOOP;
                
                    --trata os registos especiais
                    --casos em que um campo pode ter mais do que um valor
                    FOR r IN 1 .. g_comp_special.count()
                    LOOP
                        l_text_header   := NULL;
                        l_value_new     := NULL;
                        l_value_old     := NULL;
                        l_val_sign      := NULL;
                        l_descr_new     := NULL;
                        l_tbl_value_new := t_coll_hhc_req_hist();
                        l_tbl_value_old := t_coll_hhc_req_hist();
                    
                        IF get_spec_types(i_tbl_id_req(req), l_tbl_grp(index_b), l_tbl_grp(index_a), g_comp_special(r)) > 0
                        THEN
                            FOR t IN c_values_old(i_tbl_id_req(req),
                                                  l_tbl_grp(index_b),
                                                  g_comp_special(r),
                                                  l_components)
                            LOOP
                            
                                l_tbl_value_old.extend;
                                l_tbl_value_old(l_tbl_value_old.last()) := t_rec_hhc_req_hist(descr      => '',
                                                                                              val        => t.hhc_value,
                                                                                              tipo       => '',
                                                                                              flg_status => '',
                                                                                              id_request => '');
                            
                            END LOOP;
                        
                            FOR t IN c_values_new(i_tbl_id_req(req),
                                                  l_tbl_grp(index_a),
                                                  g_comp_special(r),
                                                  l_components)
                            LOOP
                            
                                l_text_header := get_cmpt_desc_by_id(i_lang, t.id_component_parent);
                                IF l_data_new IS NULL
                                   OR l_id_prof_creation IS NULL
                                THEN
                                    l_data_new         := t.dt_creation;
                                    l_id_prof_creation := t.id_prof_creation;
                                END IF;
                                l_tbl_value_new.extend;
                                l_tbl_value_new(l_tbl_value_new.last()) := t_rec_hhc_req_hist(descr      => '',
                                                                                              val        => t.hhc_value,
                                                                                              tipo       => '',
                                                                                              flg_status => '',
                                                                                              id_request => '');
                            
                                --new record
                                IF l_tbl_value_old IS empty
                                   AND l_tbl_value_new IS NOT empty
                                   AND l_descr_new IS NULL
                                THEN
                                    l_descr_new := t.text_new;
                                    --delete record
                                ELSIF l_tbl_value_old IS NOT empty
                                      AND l_tbl_value_new IS empty
                                      AND l_descr_new IS NULL
                                THEN
                                    l_descr_new := t.text_del;
                                    --edit record
                                ELSIF l_tbl_value_old IS NOT empty
                                      AND l_tbl_value_new IS NOT empty
                                      AND l_descr_new IS NULL
                                THEN
                                    l_descr_new := t.text_edit;
                                END IF;
                            
                                l_descr_old := pk_message.get_message(i_lang, t.ds_code);
                            
                                IF (l_tbl_value_new IS NOT empty OR l_tbl_value_old IS NOT empty)
                                   AND l_val_sign IS NULL
                                THEN
                                    l_val_sign := get_prof_signature(i_lang         => i_lang,
                                                                     i_prof         => i_prof,
                                                                     i_id_prof_sign => t.id_prof_creation,
                                                                     i_date         => t.dt_creation);
                                
                                END IF;
                            END LOOP;
                            --new
                            IF l_tbl_value_new IS NOT empty
                            THEN
                            
                                IF NOT set_val_rec_hhc_req_type(i_lang        => i_lang,
                                                                i_flg_report  => i_flg_report,
                                                                i_id_request  => l_id_request,
                                                                i_text_header => l_text_header,
                                                                i_descr_new   => l_descr_new,
                                                                i_descr_old   => '',
                                                                i_value_new   => '',
                                                                i_value_old   => '',
                                                                i_desc_sign   => '',
                                                                i_val_sign    => '')
                                THEN
                                    RAISE l_internal_error;
                                END IF;
                            
                                FOR t IN l_tbl_value_new.first() .. l_tbl_value_new.last()
                                LOOP
                                
                                    IF NOT set_val_rec_hhc_req_type(i_lang        => i_lang,
                                                                    i_flg_report  => i_flg_report,
                                                                    i_id_request  => l_id_request,
                                                                    i_text_header => '',
                                                                    i_descr_new   => '',
                                                                    i_descr_old   => '',
                                                                    i_value_new   => l_tbl_value_new(t).val,
                                                                    i_value_old   => '',
                                                                    i_desc_sign   => '',
                                                                    i_val_sign    => '')
                                    THEN
                                        RAISE l_internal_error;
                                    END IF;
                                END LOOP;
                            END IF;
                            IF l_tbl_value_old IS NOT empty
                            THEN
                            
                                IF NOT set_val_rec_hhc_req_type(i_lang        => i_lang,
                                                                i_flg_report  => i_flg_report,
                                                                i_id_request  => l_id_request,
                                                                i_text_header => '',
                                                                i_descr_new   => '',
                                                                i_descr_old   => l_descr_old,
                                                                i_value_new   => '',
                                                                i_value_old   => '',
                                                                i_desc_sign   => '',
                                                                i_val_sign    => '')
                                THEN
                                    RAISE l_internal_error;
                                END IF;
                            
                                FOR t IN l_tbl_value_old.first() .. l_tbl_value_old.last()
                                LOOP
                                    IF NOT set_val_rec_hhc_req_type(i_lang        => i_lang,
                                                                    i_flg_report  => i_flg_report,
                                                                    i_id_request  => l_id_request,
                                                                    i_text_header => l_text_header,
                                                                    i_descr_new   => '',
                                                                    i_descr_old   => '',
                                                                    i_value_new   => '',
                                                                    i_value_old   => l_tbl_value_old(t).val,
                                                                    i_desc_sign   => '',
                                                                    i_val_sign    => '')
                                    THEN
                                        RAISE l_internal_error;
                                    END IF;
                                END LOOP;
                            
                                --assinatura
                                IF NOT set_val_rec_hhc_req_type(i_lang        => i_lang,
                                                                i_flg_report  => i_flg_report,
                                                                i_id_request  => l_id_request,
                                                                i_text_header => '',
                                                                i_descr_new   => '',
                                                                i_descr_old   => '',
                                                                i_value_new   => '',
                                                                i_value_old   => '',
                                                                i_desc_sign   => l_desc_sign,
                                                                i_val_sign    => l_val_sign)
                                THEN
                                    RAISE l_internal_error;
                                END IF;
                            END IF;
                        END IF;
                    END LOOP;
                
                --  index_a := index_a + 1;
                --  index_b := index_b + 1;
                END LOOP;
            END IF;
            IF i_flg_report = pk_alert_constant.g_yes
            THEN
                --get the request detail -- the current
                IF get_hhc_req_det(i_lang       => i_lang,
                                   i_prof       => i_prof,
                                   i_root_name  => 'DS_HHC_REQUEST',
                                   i_id_request => i_tbl_id_req(req),
                                   i_flg_report => i_flg_report,
                                   o_detail     => l_detail,
                                   o_error      => o_error)
                THEN
                
                    LOOP
                        FETCH l_detail
                            INTO l_descr, l_val, l_type, l_flag_status_detail, l_id_request;
                        EXIT WHEN l_detail%NOTFOUND;
                        l_req_det.extend;
                        l_req_det(l_req_det.last()) := t_rec_hhc_req_hist(l_descr,
                                                                          l_val,
                                                                          l_type,
                                                                          l_flag_status_detail,
                                                                          l_id_request);
                    
                    END LOOP;
                    CLOSE l_detail;
                END IF;
            END IF;
        
            l_id_group := get_req_hist_id_group(i_tbl_id_req(req));
            --get the request detail -- the first note
            IF get_hhc_req_det_create(i_lang          => i_lang,
                                      i_prof          => i_prof,
                                      i_root_name     => 'DS_HHC_REQUEST',
                                      i_id_request    => i_tbl_id_req(req),
                                      i_id_group      => l_id_group,
                                      i_flg_report    => i_flg_report,
                                      o_detail_create => l_detail_c,
                                      o_error         => o_error)
            THEN
                LOOP
                    FETCH l_detail_c
                        INTO l_descr, l_val, l_type, l_flag_status_detail, l_id_request;
                    EXIT WHEN l_detail_c%NOTFOUND;
                    l_req_det_c.extend;
                    l_req_det_c(l_req_det_c.last()) := t_rec_hhc_req_hist(l_descr,
                                                                          l_val,
                                                                          l_type,
                                                                          l_flag_status_detail,
                                                                          l_id_request);
                
                END LOOP;
                CLOSE l_detail_c;
            END IF;
        
        END LOOP;
    
        IF i_flg_report = pk_alert_constant.g_no
        THEN
            OPEN o_detail FOR
                SELECT descr,
                       val,
                       tipo                   AS flg_type,
                       flg_status,
                       id_request,
                       pk_alert_constant.g_no flg_html,
                       NULL                   val_clob,
                       pk_alert_constant.g_no flg_clob
                  FROM (SELECT *
                          FROM TABLE(g_req_hist)
                        UNION ALL
                        SELECT *
                          FROM TABLE(l_req_det_c));
        
        ELSE
        
            OPEN o_detail FOR
                SELECT descr,
                       val,
                       tipo                   AS flg_type,
                       flg_status,
                       id_request,
                       pk_alert_constant.g_no flg_html,
                       NULL                   val_clob,
                       pk_alert_constant.g_no flg_clob
                  FROM (SELECT *
                          FROM TABLE(l_req_det)
                        UNION ALL
                        SELECT *
                          FROM TABLE(g_req_hist)
                        UNION ALL
                        SELECT *
                          FROM TABLE(l_req_det_c));
        END IF;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_detail);
            RETURN FALSE;
    END get_hhc_req_det_hist;
    --
    --
    FUNCTION get_prof_flg_mrp
    (
        i_lang IN NUMBER,
        i_prof IN profissional
    ) RETURN VARCHAR2 IS
        l_return              VARCHAR2(0010 CHAR);
        l_id_profile_template NUMBER;
    BEGIN
    
        l_id_profile_template := pk_prof_utils.get_prof_profile_template(i_prof => i_prof);
    
        l_return := pk_prof_utils.get_flg_mrp(i_lang             => i_lang,
                                              i_prof             => i_prof,
                                              i_profile_template => l_id_profile_template);
    
        RETURN l_return;
    
    END get_prof_flg_mrp;
    -- *****************************************
    FUNCTION get_type_origin_value
    (
        i_lang         IN NUMBER,
        i_epis_hhc_req IN epis_hhc_req.id_epis_hhc_req%TYPE,
        i_type_name    IN VARCHAR2
    ) RETURN VARCHAR2 IS
        l_return VARCHAR2(4000);
    BEGIN
    
        SELECT pk_sysdomain.get_domain(i_code_dom => hdt.type_name, i_val => ehrd.hhc_value, i_lang => i_lang)
          INTO l_return
          FROM v_epis_hhc_req_det ehrd
          JOIN v_hhc_det_type hdt
            ON hdt.id_hhc_det_type = ehrd.id_hhc_det_type
         WHERE ehrd.id_epis_hhc_req = i_epis_hhc_req
           AND hdt.type_name = i_type_name;
        RETURN l_return;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
        
    END get_type_origin_value;

    -- *****************************************
    FUNCTION get_origin_text(i_id_epis_hhc_req IN epis_hhc_req.id_epis_hhc_req%TYPE) RETURN epis_hhc_req_det.hhc_value%TYPE IS
        l_return epis_hhc_req_det.hhc_value%TYPE;
    BEGIN
    
        SELECT ehrd.hhc_value
          INTO l_return
          FROM v_epis_hhc_req_det ehrd
         WHERE ehrd.id_hhc_det_type = g_id_hhc_det_type_orig
           AND ehrd.id_epis_hhc_req = i_id_epis_hhc_req;
        RETURN l_return;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
        
    END get_origin_text;

    FUNCTION get_count_hhc_req_by_patient(i_patient IN NUMBER) RETURN NUMBER IS
        l_count NUMBER;
        k_hhc_requested              CONSTANT VARCHAR2(0010 CHAR) := pk_hhc_constant.k_hhc_req_status_requested;
        k_hhc_part_approved          CONSTANT VARCHAR2(0010 CHAR) := pk_hhc_constant.k_hhc_req_status_part_approved;
        k_hhc_req_status_in_eval     CONSTANT VARCHAR2(0010 CHAR) := pk_hhc_constant.k_hhc_req_status_in_eval;
        k_hhc_req_status_approved    CONSTANT VARCHAR2(0010 CHAR) := pk_hhc_constant.k_hhc_req_status_approved;
        k_hhc_req_status_in_progress CONSTANT VARCHAR2(0010 CHAR) := pk_hhc_constant.k_hhc_req_status_part_approved;
    
    BEGIN
        SELECT COUNT(*)
          INTO l_count
          FROM v_epis_hhc_req req
          JOIN episode e
            ON e.id_episode = req.id_episode
          JOIN visit v
            ON v.id_visit = e.id_visit
         WHERE v.id_patient = i_patient
           AND req.flg_status IN (k_hhc_requested,
                                  k_hhc_part_approved,
                                  k_hhc_req_status_in_eval,
                                  k_hhc_req_status_approved,
                                  k_hhc_req_status_in_progress);
        RETURN l_count;
    
    END get_count_hhc_req_by_patient;

    FUNCTION get_hhc_translation
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_value     IN epis_hhc_req_det.hhc_value%TYPE,
        i_type_name hhc_det_type.type_name%TYPE
    ) RETURN VARCHAR IS
        l_result VARCHAR2(400);
    BEGIN
        IF i_type_name = pk_hhc_constant.g_type_name_lab
        THEN
        
            SELECT (pk_lab_tests_utils.get_alias_translation(i_lang                      => i_lang,
                                                             i_prof                      => i_prof,
                                                             i_flg_type                  => pk_lab_tests_constant.g_analysis_alias,
                                                             i_analysis_code_translation => a.code_analysis,
                                                             i_sample_code_translation   => st.code_sample_type,
                                                             i_dep_clin_serv             => NULL)) || ' ' ||
                   pk_date_utils.dt_chr_date_hour(i_lang => i_lang, i_date => ard.dt_target_tstz, i_prof => i_prof)
              INTO l_result
              FROM analysis_req_det ard
              JOIN analysis a
                ON a.id_analysis = ard.id_analysis
              JOIN sample_type st
                ON st.id_sample_type = ard.id_sample_type
             WHERE ard.id_analysis_req_det = i_value;
        
        ELSIF i_type_name = pk_hhc_constant.g_type_name_exam
        THEN
            SELECT pk_exam_utils.get_alias_translation(i_lang => i_lang, i_code_exam => e.code_exam)
              INTO l_result
              FROM exam_req_det erd
              JOIN exam e
                ON erd.id_exam = e.id_exam
             WHERE erd.id_exam_req_det = i_value;
        
        ELSIF i_type_name = pk_hhc_constant.g_type_name_problem
        THEN
            SELECT DISTINCT pk_diagnosis.std_diag_desc(i_lang                => i_lang,
                                                       i_prof                => i_prof,
                                                       i_id_alert_diagnosis  => ad.id_alert_diagnosis,
                                                       i_id_diagnosis        => d.id_diagnosis,
                                                       i_code                => d.code_icd,
                                                       i_flg_other           => d.flg_other,
                                                       i_flg_std_diag        => ad.flg_icd9,
                                                       i_show_aditional_info => k_no) problem
            
              INTO l_result
              FROM alert_diagnosis ad
              JOIN epis_hhc_req_det h
                ON to_char(ad.id_alert_diagnosis) = h.hhc_value
              JOIN diagnosis d
                ON ad.id_diagnosis = d.id_diagnosis
             WHERE ad.id_alert_diagnosis = i_value;
        END IF;
    
        RETURN l_result;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_hhc_translation;

    FUNCTION get_detail_description
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_flg_type  IN hhc_det_type.flg_type%TYPE,
        i_type_name IN hhc_det_type.type_name%TYPE,
        i_value     IN epis_hhc_req_det.hhc_value%TYPE
    ) RETURN VARCHAR2 IS
    
        l_result VARCHAR2(4000);
    
    BEGIN
    
        IF i_flg_type = pk_hhc_constant.g_flg_type_d
        THEN
            l_result := pk_sysdomain.get_domain(i_code_dom => i_type_name, i_val => i_value, i_lang => i_lang);
        ELSIF i_flg_type = pk_hhc_constant.g_flg_type_k
              AND
              i_type_name IN
              (pk_hhc_constant.g_type_name_problem, pk_hhc_constant.g_type_name_lab, pk_hhc_constant.g_type_name_exam)
        THEN
            l_result := get_hhc_translation(i_lang, i_prof, i_value, i_type_name);
        
        ELSIF i_flg_type = pk_hhc_constant.g_flg_type_k
              AND i_type_name = pk_hhc_constant.g_type_name_prof_in_ch
        THEN
            l_result := pk_prof_utils.get_name(i_lang, i_value);
        ELSIF i_flg_type = pk_hhc_constant.k_flg_type_r
              AND i_type_name = k_ds_adt_name_fam_rel
        THEN
            l_result := pk_adt.get_fam_rel_domain_desc(i_lang, i_value);
        ELSE
            l_result := i_value;
        END IF;
    
        RETURN l_result;
    
    END get_detail_description;

    FUNCTION ins_shadow_visit
    (
        i_prof       IN profissional,
        i_id_patient IN NUMBER
    ) RETURN NUMBER IS
        l_return NUMBER;
        xrow     visit%ROWTYPE;
    BEGIN
    
        xrow.id_visit       := seq_visit.nextval;
        xrow.flg_status     := 'A';
        xrow.id_patient     := i_id_patient;
        xrow.id_institution := i_prof.institution;
        xrow.dt_begin_tstz  := current_timestamp;
        xrow.dt_creation    := xrow.dt_begin_tstz;
    
        l_return := xrow.id_visit;
    
        INSERT INTO visit
            (id_visit, flg_status, id_patient, id_institution, dt_begin_tstz, dt_creation)
        VALUES
            (xrow.id_visit,
             xrow.flg_status,
             xrow.id_patient,
             xrow.id_institution,
             xrow.dt_begin_tstz,
             xrow.dt_creation);
    
        RETURN l_return;
    
    END ins_shadow_visit;

    FUNCTION ins_shadow_episode
    (
        i_prof         IN profissional,
        i_shadow_visit IN NUMBER,
        i_id_patient   IN NUMBER
    ) RETURN NUMBER IS
        l_return NUMBER;
        xrow     episode%ROWTYPE;
        k_epis_active CONSTANT VARCHAR2(0010 CHAR) := 'A';
        k_nothing     CONSTANT NUMBER := -1;
    BEGIN
    
        xrow.id_episode              := seq_episode.nextval;
        xrow.id_visit                := i_shadow_visit;
        xrow.id_clinical_service     := k_nothing;
        xrow.flg_status              := k_epis_active;
        xrow.id_epis_type            := k_hhc_epis_type;
        xrow.id_patient              := i_id_patient;
        xrow.id_dept                 := k_nothing;
        xrow.id_department           := k_nothing;
        xrow.id_cs_requested         := k_nothing;
        xrow.id_institution          := i_prof.institution;
        xrow.id_department_requested := k_nothing;
        xrow.id_dept_requested       := k_nothing;
    
        l_return := xrow.id_episode;
    
        INSERT INTO episode
            (id_episode,
             id_visit,
             id_clinical_service,
             flg_status,
             id_epis_type,
             id_patient,
             id_dept,
             id_department,
             id_cs_requested,
             id_institution,
             id_department_requested,
             id_dept_requested)
        VALUES
            (xrow.id_episode,
             xrow.id_visit,
             xrow.id_clinical_service,
             xrow.flg_status,
             xrow.id_epis_type,
             xrow.id_patient,
             xrow.id_dept,
             xrow.id_department,
             xrow.id_cs_requested,
             xrow.id_institution,
             xrow.id_department_requested,
             xrow.id_dept_requested);
    
        -- bare minimum
        INSERT INTO epis_info
            (id_episode, id_schedule)
        VALUES
            (xrow.id_episode, k_nothing);
    
        RETURN l_return;
    
    END ins_shadow_episode;

    FUNCTION create_hhc_process(i_prof IN profissional,
                                --i_hhc_req    IN NUMBER,
                                i_id_patient IN NUMBER) RETURN NUMBER IS
        l_id_visit   NUMBER;
        l_id_episode NUMBER;
    BEGIN
    
        l_id_visit := ins_shadow_visit(i_prof, i_id_patient);
    
        l_id_episode := ins_shadow_episode(i_prof => i_prof, i_shadow_visit => l_id_visit, i_id_patient => i_id_patient);
        --upd_hhc_request(i_hhc_req, l_id_episode);
    
        RETURN l_id_episode;
    
    END create_hhc_process;

    FUNCTION get_id_epis_hhc_req_by_pat(i_id_patient IN episode.id_patient%TYPE) RETURN epis_hhc_req.id_epis_hhc_req%TYPE IS
        l_id_epis_hhc_req epis_hhc_req.id_epis_hhc_req%TYPE;
    BEGIN
    
        SELECT v.id_epis_hhc_req
          INTO l_id_epis_hhc_req
          FROM v_epis_hhc_req v
         WHERE v.id_patient = i_id_patient
           AND v.flg_status NOT IN (k_hhc_closed, k_hhc_canceled, k_hhc_rejected, k_hhc_discontinued);
    
        RETURN l_id_epis_hhc_req;
    
    EXCEPTION
        WHEN no_data_found THEN
            RETURN NULL;
        
    END get_id_epis_hhc_req_by_pat;

    FUNCTION get_flg_hhc_discharge
    (
        --i_lang               IN language.id_language%TYPE,
        --i_prof               IN profissional,
        i_id_disch_reas_dest IN disch_reas_dest.id_disch_reas_dest%TYPE
        --o_error              OUT t_error_out
    ) RETURN discharge_reason.flg_hhc_disch%TYPE IS
        l_flg_hhc_disch discharge_reason.flg_hhc_disch%TYPE;
        tbl_return      table_varchar;
    BEGIN
        SELECT dr.flg_hhc_disch
          BULK COLLECT
          INTO tbl_return
          FROM discharge_reason dr
          JOIN disch_reas_dest drd
            ON dr.id_discharge_reason = drd.id_discharge_reason
         WHERE drd.id_disch_reas_dest = i_id_disch_reas_dest;
    
        IF tbl_return.count > 0
        THEN
            l_flg_hhc_disch := tbl_return(1);
        ELSE
            l_flg_hhc_disch := k_no;
        END IF;
    
        RETURN l_flg_hhc_disch;
    
    END get_flg_hhc_discharge;

    FUNCTION get_id_episode_by_hhc_req(i_id_epis_hhc_req IN epis_hhc_req.id_epis_hhc_req%TYPE) RETURN NUMBER IS
        l_id_episode NUMBER(24);
    BEGIN
    
        SELECT id_episode
          INTO l_id_episode
          FROM v_epis_hhc_req r
         WHERE r.id_epis_hhc_req = i_id_epis_hhc_req;
    
        RETURN l_id_episode;
    
    END get_id_episode_by_hhc_req;

    FUNCTION get_discharge_validation
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_patient         IN patient.id_patient%TYPE,
        i_id_episode         IN episode.id_episode%TYPE,
        i_id_disch_reas_dest IN disch_reas_dest.id_disch_reas_dest%TYPE,
        i_id_disch_status    IN discharge_status.id_discharge_status%TYPE,
        o_desc_msg           OUT sys_message.code_message%TYPE,
        o_popup_type         OUT VARCHAR2,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_hhc_req_status       epis_hhc_req.flg_status%TYPE;
        l_disch_hhc            discharge_reason.flg_hhc_disch%TYPE;
        l_id_epis_hhc_req      epis_hhc_req.id_epis_hhc_req%TYPE;
        l_id_episode_requested epis_hhc_req.id_episode%TYPE;
        l_config_value         sys_config.desc_sys_config%TYPE;
        k_config CONSTANT sys_config.id_sys_config%TYPE := 'HHC_ALLOW_DISCHARGE';
        --l_i_id_patient episode.id_patient%TYPE;
    BEGIN
    
        --verify if disch_reas_dest is  hhc
        l_disch_hhc := get_flg_hhc_discharge(i_id_disch_reas_dest);
    
        --get the id of epis_hhc_req
        l_id_epis_hhc_req := get_id_epis_hhc_req_by_pat(i_id_patient => i_id_patient);
        IF l_id_epis_hhc_req IS NOT NULL
        THEN
            l_id_episode_requested := get_id_episode_by_hhc_req(l_id_epis_hhc_req);
        END IF;
        --get status of hhc request
        l_hhc_req_status := get_epis_hhc_status(i_lang            => i_lang,
                                                i_prof            => i_prof,
                                                i_id_epis_hhc_req => l_id_epis_hhc_req);
    
        IF l_hhc_req_status = k_hhc_canceled
        THEN
            l_hhc_req_status := NULL;
        END IF;
    
        l_config_value := pk_sysconfig.get_config(k_config, i_prof);
    
        IF l_disch_hhc = pk_alert_constant.g_yes
        THEN
            IF i_id_disch_status IN (pk_hhc_constant.k_disch_final, pk_hhc_constant.k_disch_pending)
               AND l_hhc_req_status IS NULL
            THEN
                o_desc_msg   := pk_message.get_message(i_lang      => i_lang,
                                                       i_code_mess => pk_hhc_constant.k_disch_hhc_performed);
                o_popup_type := pk_hhc_constant.k_disch_hhc_performed;
            
            ELSIF i_id_disch_status = pk_hhc_constant.k_disch_pending
                  AND l_hhc_req_status IN (pk_hhc_constant.k_hhc_req_status_requested,
                                           pk_hhc_constant.k_hhc_req_status_in_eval,
                                           pk_hhc_constant.k_hhc_req_status_approved,
                                           pk_hhc_constant.k_hhc_req_status_in_progress,
                                           pk_hhc_constant.k_hhc_req_status_part_approved,
                                           pk_hhc_constant.k_hhc_req_stauts_part_acc_wcm)
            
            THEN
                --can save the dischage
                o_desc_msg   := NULL;
                o_popup_type := NULL;
                RETURN TRUE;
            
            ELSIF i_id_disch_status = pk_hhc_constant.k_disch_final
                  AND l_hhc_req_status IN (pk_hhc_constant.k_hhc_req_status_requested,
                                           pk_hhc_constant.k_hhc_req_status_part_approved,
                                           pk_hhc_constant.k_hhc_req_status_in_eval,
                                           pk_hhc_constant.k_hhc_req_stauts_part_acc_wcm)
                  AND l_config_value = pk_alert_constant.g_no
            THEN
                --show warning
                o_desc_msg   := pk_message.get_message(i_lang      => i_lang,
                                                       i_code_mess => pk_hhc_constant.k_disch_hhc_approval);
                o_popup_type := pk_hhc_constant.k_disch_hhc_approval;
            END IF;
        ELSE
            -- IF i_id_disch_status IN (pk_hhc_constant.k_disch_final, pk_hhc_constant.k_disch_pending)
            --    i_id_disch_status IS NULL
            IF l_hhc_req_status IN (pk_hhc_constant.k_hhc_req_status_requested,
                                    pk_hhc_constant.k_hhc_req_status_in_eval,
                                    pk_hhc_constant.k_hhc_req_status_approved,
                                    pk_hhc_constant.k_hhc_req_status_in_progress,
                                    pk_hhc_constant.k_hhc_req_status_part_approved,
                                    pk_hhc_constant.k_hhc_req_stauts_part_acc_wcm)
               AND i_prof.software = pk_alert_constant.g_soft_inpatient
               AND l_id_episode_requested = i_id_episode
            
            THEN
                --show warning
                o_desc_msg   := pk_message.get_message(i_lang      => i_lang,
                                                       i_code_mess => pk_hhc_constant.k_disch_hhc_ongoing);
                o_popup_type := pk_hhc_constant.k_disch_hhc_ongoing;
            END IF;
        END IF;
        RETURN TRUE;
    
    END get_discharge_validation;

    FUNCTION set_new_hhc_referral_alert
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_epis_hhc_req IN NUMBER,
        i_episode      IN episode.id_episode%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_ret BOOLEAN;
    BEGIN
    
        l_ret := set_hhc_alert_general(i_lang         => i_lang,
                                       i_prof         => i_prof,
                                       i_epis_hhc_req => i_epis_hhc_req,
                                       i_episode      => i_episode,
                                       i_id_sys_alert => pk_hhc_constant.k_hhc_new_referral_alert,
                                       i_alert_msg    => pk_hhc_constant.k_hhc_new_referral_msg,
                                       o_error        => o_error);
    
        RETURN l_ret;
    
    END set_new_hhc_referral_alert;

    FUNCTION set_hhc_approved_alert
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_epis_hhc_req IN NUMBER,
        i_episode      IN episode.id_episode%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_ret BOOLEAN;
    BEGIN
        l_ret := set_hhc_alert_general(i_lang         => i_lang,
                                       i_prof         => i_prof,
                                       i_epis_hhc_req => i_epis_hhc_req,
                                       i_episode      => i_episode,
                                       i_id_sys_alert => pk_hhc_constant.k_hhc_approved_alert,
                                       i_alert_msg    => pk_hhc_constant.k_hhc_approved_msg,
                                       o_error        => o_error);
    
        RETURN l_ret;
    END set_hhc_approved_alert;

    FUNCTION set_hhc_reject_alert
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_epis_hhc_req    IN NUMBER,
        i_episode         IN episode.id_episode%TYPE,
        i_id_professional IN NUMBER DEFAULT NULL,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_ret BOOLEAN;
    BEGIN
        l_ret := set_hhc_alert_general(i_lang            => i_lang,
                                       i_prof            => i_prof,
                                       i_episode         => i_episode,
                                       i_epis_hhc_req    => i_epis_hhc_req,
                                       i_id_sys_alert    => pk_hhc_constant.k_hhc_reject_alert,
                                       i_alert_msg       => pk_hhc_constant.k_hhc_reject_msg,
                                       i_id_professional => i_id_professional,
                                       o_error           => o_error);
    
        RETURN l_ret;
    END set_hhc_reject_alert;

    FUNCTION set_hhc_end_follow_up_alert
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_epis_hhc_req    IN NUMBER,
        i_episode         IN episode.id_episode%TYPE,
        i_id_professional IN NUMBER DEFAULT NULL,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_ret BOOLEAN;
    BEGIN
        l_ret := set_hhc_alert_general(i_lang            => i_lang,
                                       i_prof            => i_prof,
                                       i_epis_hhc_req    => i_epis_hhc_req,
                                       i_episode         => i_episode,
                                       i_id_sys_alert    => pk_hhc_constant.k_hhc_end_follow_up_alert,
                                       i_alert_msg       => pk_hhc_constant.k_hhc_end_follow_up_msg,
                                       i_id_professional => i_id_professional,
                                       o_error           => o_error);
    
        RETURN l_ret;
    END set_hhc_end_follow_up_alert;

    FUNCTION set_hhc_case_manager_alert
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_epis_hhc_req    IN NUMBER,
        i_episode         IN episode.id_episode%TYPE,
        i_id_professional IN NUMBER DEFAULT NULL,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_ret BOOLEAN;
    BEGIN
        l_ret := set_hhc_alert_general(i_lang            => i_lang,
                                       i_prof            => i_prof,
                                       i_epis_hhc_req    => i_epis_hhc_req,
                                       i_episode         => i_episode,
                                       i_id_sys_alert    => pk_hhc_constant.k_hhc_manager_assign_alert,
                                       i_alert_msg       => pk_hhc_constant.k_hhc_manager_assign_msg,
                                       i_id_professional => i_id_professional,
                                       o_error           => o_error);
    
        RETURN l_ret;
    END set_hhc_case_manager_alert;

    FUNCTION set_hhc_alert_general
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_epis_hhc_req    IN NUMBER,
        i_episode         IN episode.id_episode%TYPE,
        i_id_sys_alert    IN sys_alert.id_sys_alert%TYPE,
        i_alert_msg       IN VARCHAR2,
        i_id_professional IN NUMBER DEFAULT NULL,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_alert sys_alert_event%ROWTYPE;
        l_internal_error EXCEPTION;
    BEGIN
    
        g_error := 'OPEN CURSOR C_ALERT';
        pk_alertlog.log_debug(g_error);
    
        l_alert.id_sys_alert   := i_id_sys_alert;
        l_alert.id_software    := i_prof.software;
        l_alert.id_institution := i_prof.institution;
        l_alert.id_episode     := i_episode;
        l_alert.id_record      := i_epis_hhc_req;
        l_alert.dt_record      := current_timestamp;
    
        l_alert.id_professional := i_id_professional;
        l_alert.id_room         := NULL;
        l_alert.replace1        := i_alert_msg;
        l_alert.replace2        := NULL;
    
        g_error := 'CALL TO PK_ALERTS.INSERT_SYS_ALERT_EVENT';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_alerts.insert_sys_alert_event(i_lang,
                                                i_prof,
                                                l_alert.id_sys_alert,
                                                l_alert.id_episode,
                                                l_alert.id_record,
                                                l_alert.dt_record,
                                                l_alert.id_professional,
                                                l_alert.id_room,
                                                l_alert.id_clinical_service,
                                                NULL,
                                                l_alert.replace1,
                                                o_error)
        THEN
            RAISE l_internal_error;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_internal_error THEN
            pk_alert_exceptions.process_error(i_lang,
                                              o_error.ora_sqlcode,
                                              o_error.ora_sqlerrm,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'SET_NEW_HHC_REFERRAL_ALERT',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'SET_NEW_HHC_REFERRAL_ALERT',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
        
    END set_hhc_alert_general;

    --função para obter o id request de um paciente 
    --ordena pela data do request
    --não considera os cancelados
    FUNCTION get_id_req_by_pat
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE
    ) RETURN epis_hhc_req.id_epis_hhc_req%TYPE IS
        l_id_epis_hhc_req epis_hhc_req.id_epis_hhc_req%TYPE;
        tbl_id            table_number;
    BEGIN
        SELECT id_epis_hhc_req
          BULK COLLECT
          INTO tbl_id
          FROM (SELECT t.id_epis_hhc_req, row_number() over(ORDER BY t.dt_request DESC) rn
                  FROM (SELECT ehr.id_epis_hhc_req,
                               pk_date_utils.dt_chr_tsz(i_lang,
                                                        pk_hhc_core.get_dt_request(ehr.id_epis_hhc_req),
                                                        profissional(i_prof.id, i_prof.institution, i_prof.software)) dt_request
                          FROM alert.v_epis_hhc_req ehr
                        
                         WHERE ehr.id_patient = i_id_patient
                           AND ehr.flg_status != pk_alert_constant.g_cancelled) t)
         WHERE rn = 1;
    
        IF tbl_id.count > 0
        THEN
            l_id_epis_hhc_req := tbl_id(1);
        END IF;
    
        RETURN l_id_epis_hhc_req;
    
    END get_id_req_by_pat;

    FUNCTION get_last_id_hhc_request
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE,
        o_error      OUT t_error_out
    ) RETURN epis_hhc_req.id_epis_hhc_req%TYPE IS
        --l_flg_status epis_hhc_req.flg_status%TYPE;
        l_id_request epis_hhc_req.id_epis_hhc_req%TYPE;
        l_exception EXCEPTION;
        --l_func_name VARCHAR2(0024 CHAR) := 'get_last_id_hhc_request';
    BEGIN
    
        --obtem o request pelo paciente
        l_id_request := get_id_req_by_pat(i_lang => i_lang, i_prof => i_prof, i_id_patient => i_id_patient);
        --
        RETURN l_id_request;
    
    END get_last_id_hhc_request;
    --obtem todos os requests de um paciente
    FUNCTION get_all_hhc_req_from_pat
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE,
        o_error      OUT t_error_out
    ) RETURN table_number IS
        l_tbl_id_request table_number;
    BEGIN
    
        SELECT id_epis_hhc_req
          BULK COLLECT
          INTO l_tbl_id_request
          FROM (SELECT ehr.id_epis_hhc_req,
                       pk_date_utils.dt_chr_tsz(i_lang,
                                                pk_hhc_core.get_dt_request(ehr.id_epis_hhc_req),
                                                profissional(i_prof.id, i_prof.institution, i_prof.software)) dt_request
                
                  FROM v_epis_hhc_req ehr
                 WHERE ehr.id_patient = i_id_patient)
         ORDER BY dt_request DESC;
    
        RETURN l_tbl_id_request;
    
    END get_all_hhc_req_from_pat;

    FUNCTION check_functionality
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_functionality IN sys_functionality.id_functionality%TYPE
        
    ) RETURN BOOLEAN IS
        l_ret    BOOLEAN;
        l_exists NUMBER;
    BEGIN
    
        SELECT COUNT(*)
          INTO l_exists
          FROM prof_func p
         WHERE p.id_professional = i_prof.id
           AND p.id_functionality = i_id_functionality;
    
        l_ret := l_exists > 0;
    
        RETURN l_ret;
    
    END check_functionality;

    FUNCTION is_coordinator
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) RETURN VARCHAR2 IS
        l_ret VARCHAR2(1 CHAR);
    BEGIN
    
        IF check_functionality(i_lang             => i_lang,
                               i_prof             => i_prof,
                               i_id_functionality => pk_hhc_constant.k_hhc_func_coordinator)
        THEN
            l_ret := 'Y';
        ELSE
            l_ret := 'N';
        END IF;
    
        RETURN l_ret;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
        
    END is_coordinator;

    FUNCTION is_case_manager
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) RETURN VARCHAR2 IS
    
        l_ret VARCHAR2(1 CHAR);
    
    BEGIN
    
        IF check_functionality(i_lang             => i_lang,
                               i_prof             => i_prof,
                               i_id_functionality => pk_hhc_constant.k_hhc_func_case_manager)
        THEN
            l_ret := 'Y';
        ELSE
            l_ret := 'N';
        END IF;
    
        RETURN l_ret;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
        
    END is_case_manager;

    /**
    * get_epis_hhc_status
    *
    * @param     i_lang               id language
    * @param     i_prof               profissional identifier
    * @param     i_id_epis_hhc_req    Id of hhc request
    * @return    l_flg_status         request status
    * @version 2.8.1
    * @since  2019/12/20
    */
    FUNCTION get_epis_hhc_status
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_epis_hhc_req IN epis_hhc_req.id_epis_hhc_req%TYPE
    ) RETURN epis_hhc_req.flg_status%TYPE IS
        l_flg_status epis_hhc_req.flg_status%TYPE;
        tbl_var      table_varchar;
    BEGIN
        SELECT ve.flg_status
          BULK COLLECT
          INTO tbl_var
          FROM v_epis_hhc_req ve
         WHERE ve.id_epis_hhc_req = i_id_epis_hhc_req;
    
        IF tbl_var.count > 0
        THEN
            l_flg_status := tbl_var(1);
        END IF;
    
        RETURN l_flg_status;
    
    END get_epis_hhc_status;

    FUNCTION upd_epis_req
    (
        i_prof                IN profissional,
        i_id_epis_hhc_req     IN epis_hhc_req.id_epis_hhc_req%TYPE,
        i_flg_status          IN epis_hhc_req.flg_status%TYPE,
        i_id_prof_manager     IN epis_hhc_req.id_prof_manager%TYPE,
        i_dt_prof_manager     IN epis_hhc_req.dt_prof_manager%TYPE,
        i_prof_null           IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        i_id_prof_coordinator IN epis_hhc_req.id_prof_coordinator%TYPE,
        i_id_cancel_reason    IN epis_hhc_req.id_cancel_reason%TYPE,
        i_cancel_notes        IN epis_hhc_req.cancel_notes%TYPE
        
    ) RETURN BOOLEAN IS
        xrow v_epis_hhc_req%ROWTYPE;
        --****************************************
        FUNCTION process_id_manager
        (
            i_prof_null       IN VARCHAR2,
            i_id_prof_manager IN epis_hhc_req.id_prof_manager%TYPE,
            i_existing_value  IN epis_hhc_req.id_prof_manager%TYPE
        ) RETURN NUMBER IS
            l_return NUMBER;
        BEGIN
        
            IF i_prof_null = k_no
            THEN
                l_return := coalesce(i_id_prof_manager, i_existing_value);
            END IF;
        
            RETURN l_return;
        END process_id_manager;
    
        --***************************************
        FUNCTION process_dt_prof_manager
        (
            i_prof_null       IN VARCHAR2,
            i_dt_prof_manager IN epis_hhc_req.dt_prof_manager%TYPE,
            i_existing_value  IN epis_hhc_req.dt_prof_manager%TYPE
        ) RETURN epis_hhc_req.dt_prof_manager%TYPE IS
            l_return epis_hhc_req.dt_prof_manager%TYPE;
        BEGIN
        
            IF i_prof_null = k_no
            THEN
                l_return := coalesce(i_dt_prof_manager, i_existing_value);
            END IF;
        
            RETURN l_return;
        
        END process_dt_prof_manager;
    
        -- ******************************************************
        FUNCTION get_epis_hhc_req_row(i_id_epis_hhc_req IN NUMBER) RETURN v_epis_hhc_req%ROWTYPE IS
            l_row v_epis_hhc_req%ROWTYPE;
        BEGIN
        
            SELECT *
              INTO l_row
              FROM v_epis_hhc_req ehr
             WHERE ehr.id_epis_hhc_req = i_id_epis_hhc_req;
        
            RETURN l_row;
        
        END get_epis_hhc_req_row;
    
        --*****************************************************
        PROCEDURE set_values IS
        BEGIN
        
            xrow.flg_status          := coalesce(i_flg_status, xrow.flg_status);
            xrow.id_prof_coordinator := coalesce(i_id_prof_coordinator, xrow.id_prof_coordinator);
            xrow.id_cancel_reason    := coalesce(i_id_cancel_reason, NULL);
            xrow.cancel_notes        := coalesce(i_cancel_notes, NULL);
        
            xrow.id_prof_manager := process_id_manager(i_prof_null, i_id_prof_manager, xrow.id_prof_manager);
            xrow.dt_prof_manager := process_dt_prof_manager(i_prof_null, i_dt_prof_manager, xrow.dt_prof_manager);
        
        END set_values;
    
        --*****************************************************
        PROCEDURE upd_epis_hhc_req
        (
            i_id_epis_hhc_req IN NUMBER,
            i_row             IN v_epis_hhc_req%ROWTYPE
        ) IS
        BEGIN
        
            UPDATE v_epis_hhc_req v
               SET v.flg_status          = i_row.flg_status,
                   v.id_prof_manager     = i_row.id_prof_manager,
                   v.dt_prof_manager     = i_row.dt_prof_manager,
                   v.id_prof_coordinator = i_row.id_prof_coordinator,
                   v.id_cancel_reason    = i_row.id_cancel_reason,
                   v.cancel_notes        = i_row.cancel_notes
             WHERE v.id_epis_hhc_req = i_id_epis_hhc_req;
        
        END upd_epis_hhc_req;
    
    BEGIN
    
        xrow := get_epis_hhc_req_row(i_id_epis_hhc_req);
    
        set_values();
    
        upd_epis_hhc_req(i_id_epis_hhc_req => i_id_epis_hhc_req, i_row => xrow);
    
        ins_req_hist(xrow.id_epis_hhc_req,
                     i_prof,
                     xrow.id_patient,
                     xrow.id_episode,
                     xrow.flg_status,
                     xrow.id_cancel_reason,
                     xrow.cancel_notes,
                     xrow.id_epis_hhc,
                     xrow.id_prof_manager,
                     xrow.dt_prof_manager,
                     xrow.id_prof_coordinator);
    
        RETURN TRUE;
    END upd_epis_req;

    FUNCTION set_assign_case_man
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_epis_hhc_req IN epis_hhc_req.id_epis_hhc_req%TYPE,
        i_id_prof_manager IN epis_hhc_req.id_prof_manager%TYPE,
        i_id_reason       IN epis_hhc_req_status.id_cancel_reason%TYPE,
        i_reason          IN CLOB,
        o_error           OUT t_error_out
        
    ) RETURN BOOLEAN IS
        l_status          epis_hhc_req.flg_status%TYPE;
        l_dt_case_manager epis_hhc_req.dt_prof_manager%TYPE := current_timestamp;
        l_ret             BOOLEAN;
        l_id_episode      epis_hhc_req.id_episode%TYPE;
        l_alert_error     t_error_out;
    BEGIN
    
        l_status := get_epis_hhc_status(i_lang => i_lang, i_prof => i_prof, i_id_epis_hhc_req => i_id_epis_hhc_req);
        --l_id_episode := get_id_episode_by_hhc_req(i_id_epis_hhc_req);
        l_id_episode := get_id_epis_hhc_by_hhc_req(i_id_hhc_req => i_id_epis_hhc_req);
    
        --if the stauts not in "in evaluation" ou "partialy approv without cm" - update status
        IF l_status IN (k_hhc_in_part_acc_wcm, k_hhc_requested)
        THEN
            l_status := k_hhc_part_approved;
            l_ret    := ins_req_status(i_id_epis_hhc_req, i_prof.id, l_status, i_id_reason, i_reason);
        
        ELSE
            l_status := NULL;
        END IF;
    
        l_ret := pk_hhc_core.upd_epis_req(i_prof                => i_prof,
                                          i_id_epis_hhc_req     => i_id_epis_hhc_req,
                                          i_flg_status          => l_status,
                                          i_id_prof_manager     => i_id_prof_manager,
                                          i_dt_prof_manager     => l_dt_case_manager,
                                          i_prof_null           => k_no,
                                          i_id_prof_coordinator => i_prof.id,
                                          i_id_cancel_reason    => i_id_reason,
                                          i_cancel_notes        => i_reason);
    
        l_ret := pk_hhc_core.set_hhc_case_manager_alert(i_lang            => i_lang,
                                                        i_prof            => i_prof,
                                                        i_episode         => l_id_episode,
                                                        i_epis_hhc_req    => i_id_epis_hhc_req,
                                                        i_id_professional => i_id_prof_manager,
                                                        o_error           => l_alert_error);
        RETURN l_ret;
    
    END set_assign_case_man;

    FUNCTION remove_case_man
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_epis_hhc_req IN epis_hhc_req.id_epis_hhc_req%TYPE,
        i_prev_status     IN VARCHAR2 DEFAULT pk_hhc_constant.k_hhc_req_stauts_part_acc_wcm,
        o_error           OUT t_error_out
        
    ) RETURN BOOLEAN IS
        l_ret BOOLEAN;
    BEGIN
    
        l_ret := pk_hhc_core.upd_epis_req(i_prof                => i_prof,
                                          i_id_epis_hhc_req     => i_id_epis_hhc_req,
                                          i_flg_status          => i_prev_status,
                                          i_id_prof_manager     => NULL,
                                          i_dt_prof_manager     => NULL,
                                          i_prof_null           => k_yes,
                                          i_id_prof_coordinator => i_prof.id,
                                          i_id_cancel_reason    => NULL,
                                          i_cancel_notes        => NULL);
        l_ret := ins_req_status(i_id_epis_hhc_req, i_prof.id, i_prev_status, NULL, NULL);
        RETURN l_ret;
    
    END remove_case_man;

    FUNCTION get_ref_message_access
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_epis_hhc       IN epis_hhc_req.id_epis_hhc%TYPE,
        i_id_hhc_request IN epis_hhc_req.id_epis_hhc_req%TYPE,
        o_msg            OUT sys_message.desc_message%TYPE,
        o_flg_msg        OUT VARCHAR2,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_id_case_manager epis_hhc_req.id_prof_manager%TYPE;
        l_hhc_req_status  epis_hhc_req.flg_status%TYPE;
    BEGIN
    
        l_id_case_manager := pk_hhc_core.get_id_case_manager(i_epis_hhc => i_epis_hhc);
    
        l_hhc_req_status := pk_hhc_core.get_epis_hhc_status(i_lang            => i_lang,
                                                            i_prof            => i_prof,
                                                            i_id_epis_hhc_req => i_id_hhc_request);
        IF l_id_case_manager = i_prof.id
           AND l_hhc_req_status = pk_hhc_constant.k_hhc_req_status_part_approved
        THEN
            o_msg     := pk_message.get_message(i_lang => i_lang, i_code_mess => 'HHC_START_EVALUATION');
            o_flg_msg := pk_alert_constant.g_yes;
        ELSE
            o_msg     := NULL;
            o_flg_msg := pk_alert_constant.g_no;
        END IF;
    
        RETURN TRUE;
    
    END get_ref_message_access;

    FUNCTION set_ref_status_ie
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_hhc_request IN epis_hhc_req.id_epis_hhc_req%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_exception EXCEPTION;
        l_bool BOOLEAN := FALSE;
    BEGIN
        l_bool := pk_hhc_core.upd_epis_req(i_prof                => i_prof,
                                           i_id_epis_hhc_req     => i_id_hhc_request,
                                           i_flg_status          => pk_hhc_constant.k_hhc_req_status_in_eval,
                                           i_id_prof_manager     => NULL,
                                           i_dt_prof_manager     => NULL,
                                           i_prof_null           => k_no,
                                           i_id_prof_coordinator => NULL,
                                           i_id_cancel_reason    => NULL,
                                           i_cancel_notes        => NULL);
        IF l_bool
        THEN
            g_error := 'INSERT IN EPIS_HHC_REQ_STATUS';
            l_bool  := ins_req_status(i_id_epis_hhc_req  => i_id_hhc_request,
                                      i_id_professional  => i_prof.id,
                                      i_flg_status       => pk_hhc_constant.k_hhc_req_status_in_eval,
                                      i_id_cancel_reason => NULL,
                                      i_cancel_notes     => NULL);
            IF NOT l_bool
            THEN
                RAISE l_exception;
            END IF;
        ELSE
            RAISE l_exception;
        
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN l_exception THEN
            RETURN FALSE;
    END set_ref_status_ie;

    FUNCTION set_part_accept_no_case_manag
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_epis_hhc_req IN epis_hhc_req.id_epis_hhc_req%TYPE,
        i_id_reason       IN epis_hhc_req_status.id_cancel_reason%TYPE,
        i_reason          IN CLOB,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_ret        BOOLEAN;
        l_new_status epis_hhc_req.flg_status%TYPE;
    
    BEGIN
        l_new_status := pk_hhc_constant.k_hhc_req_stauts_part_acc_wcm;
    
        l_ret := pk_hhc_core.upd_epis_req(i_prof                => i_prof,
                                          i_id_epis_hhc_req     => i_id_epis_hhc_req,
                                          i_flg_status          => l_new_status,
                                          i_id_prof_manager     => NULL,
                                          i_dt_prof_manager     => NULL,
                                          i_prof_null           => k_no,
                                          i_id_prof_coordinator => i_prof.id,
                                          i_id_cancel_reason    => i_id_reason,
                                          i_cancel_notes        => i_reason);
    
        l_ret := ins_req_status(i_id_epis_hhc_req, i_prof.id, l_new_status, i_id_reason, i_reason);
    
        RETURN l_ret;
    END set_part_accept_no_case_manag;

    FUNCTION set_status_partially_accept
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_epis_hhc_req IN epis_hhc_req.id_epis_hhc_req%TYPE,
        i_id_prof_manager IN epis_hhc_req.id_prof_manager%TYPE,
        i_id_reason       IN epis_hhc_req_status.id_cancel_reason%TYPE,
        i_reason          IN CLOB,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_ret BOOLEAN;
    
    BEGIN
        IF i_id_prof_manager IS NOT NULL
        THEN
            /*this sets the case manager but also the new state of the request (in this case it's partially accepted)*/
            l_ret := pk_hhc_core.set_assign_case_man(i_lang            => i_lang,
                                                     i_prof            => i_prof,
                                                     i_id_epis_hhc_req => i_id_epis_hhc_req,
                                                     i_id_prof_manager => i_id_prof_manager,
                                                     i_id_reason       => i_id_reason,
                                                     i_reason          => i_reason,
                                                     o_error           => o_error);
        
        ELSE
            l_ret := set_part_accept_no_case_manag(i_lang            => i_lang,
                                                   i_prof            => i_prof,
                                                   i_id_epis_hhc_req => i_id_epis_hhc_req,
                                                   i_id_reason       => i_id_reason,
                                                   i_reason          => i_reason,
                                                   o_error           => o_error);
        END IF;
    
        RETURN l_ret;
    
    END set_status_partially_accept;

    FUNCTION get_coordinator
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_epis_hhc_req IN epis_hhc_req.id_epis_hhc_req%TYPE
    ) RETURN NUMBER IS
        l_coordinator NUMBER;
    BEGIN
    
        SELECT v.id_professional
          INTO l_coordinator
          FROM v_epis_hhc_req_status v
         WHERE v.id_epis_hhc_req = i_id_epis_hhc_req
           AND v.flg_status = k_hhc_requested
           AND v.flg_undone IS NULL;
    
        RETURN l_coordinator;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN l_coordinator;
    END get_coordinator;

    FUNCTION set_status_reject
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_epis_hhc_req IN epis_hhc_req.id_epis_hhc_req%TYPE,
        i_id_reason       IN epis_hhc_req_status.id_cancel_reason%TYPE,
        i_reason          IN CLOB,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_ret         BOOLEAN;
        l_status      VARCHAR2(1 CHAR);
        l_coordinator NUMBER;
    BEGIN
        l_status := pk_hhc_constant.k_hhc_req_status_rejected;
    
        l_coordinator := get_coordinator(i_lang, i_prof, i_id_epis_hhc_req);
    
        l_ret := pk_hhc_core.upd_epis_req(i_prof                => i_prof,
                                          i_id_epis_hhc_req     => i_id_epis_hhc_req,
                                          i_flg_status          => l_status,
                                          i_id_prof_manager     => NULL,
                                          i_dt_prof_manager     => NULL,
                                          i_prof_null           => k_no,
                                          i_id_prof_coordinator => l_coordinator,
                                          i_id_cancel_reason    => i_id_reason,
                                          i_cancel_notes        => i_reason);
    
        l_ret := ins_req_status(i_id_epis_hhc_req, i_prof.id, l_status, i_id_reason, i_reason);
    
        l_ret := set_hhc_reject_alert(i_lang            => i_lang,
                                      i_prof            => i_prof,
                                      i_epis_hhc_req    => i_id_epis_hhc_req,
                                      i_episode         => get_id_episode_by_hhc_req(i_id_epis_hhc_req),
                                      i_id_professional => l_coordinator,
                                      o_error           => o_error);
    
        RETURN l_ret;
    
    END set_status_reject;

    FUNCTION get_epis_hhc_req_prev_info
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_epis_hhc_req IN epis_hhc_req.id_epis_hhc_req%TYPE,
        i_row             IN NUMBER
    ) RETURN t_epis_hhc_req_status IS
        l_ret t_epis_hhc_req_status;
    BEGIN
        SELECT t_epis_hhc_req_status(id_epis_hhc_req => i_id_epis_hhc_req,
                                     id_professional => t.id_professional,
                                     flg_status      => t.flg_status,
                                     dt_status       => t.dt_status,
                                     id_reason       => t.id_reason,
                                     reason_notes    => t.reason_notes)
          INTO l_ret
          FROM (SELECT row_number() over(ORDER BY e.dt_status DESC) row_x,
                       e.id_professional id_professional,
                       e.flg_status flg_status,
                       e.dt_status dt_status,
                       e.id_cancel_reason id_reason,
                       e.cancel_notes reason_notes
                  FROM epis_hhc_req_status e
                 WHERE e.id_epis_hhc_req = i_id_epis_hhc_req
                   AND e.flg_undone IS NULL) t
         WHERE t.row_x = i_row;
    
        RETURN l_ret;
    
    END get_epis_hhc_req_prev_info;

    FUNCTION upd_flg_undone
    (
        i_id_epis_hhc_req IN epis_hhc_req.id_epis_hhc_req%TYPE,
        i_flg_status      IN VARCHAR2 DEFAULT NULL,
        i_dt_status       IN TIMESTAMP WITH LOCAL TIME ZONE
    ) RETURN BOOLEAN IS
    
    BEGIN
        UPDATE v_epis_hhc_req_status v
           SET v.flg_undone = k_hhc_undo
         WHERE v.id_epis_hhc_req = i_id_epis_hhc_req
           AND v.dt_status = i_dt_status
           AND v.flg_status = i_flg_status;
        RETURN TRUE;
    END upd_flg_undone;

    FUNCTION get_id_patient_by_hhc_req(i_id_epis_hhc_req IN epis_hhc_req.id_epis_hhc_req%TYPE) RETURN NUMBER IS
        l_id_patient NUMBER(24);
    BEGIN
    
        SELECT id_patient
          INTO l_id_patient
          FROM v_epis_hhc_req r
         WHERE r.id_epis_hhc_req = i_id_epis_hhc_req;
    
        RETURN l_id_patient;
    
    END get_id_patient_by_hhc_req;
    FUNCTION set_status_undo
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_epis_hhc_req IN epis_hhc_req.id_epis_hhc_req%TYPE,
        i_id_reason       IN epis_hhc_req_status.id_cancel_reason%TYPE,
        i_reason          IN CLOB,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_ret                       BOOLEAN;
        l_new_status                VARCHAR2(1 CHAR);
        l_status_undo               VARCHAR2(1 CHAR) := pk_hhc_constant.k_hhc_req_status_undo;
        l_epis_hhc_req_status_prev  t_epis_hhc_req_status;
        l_epis_hhc_req_status_atual t_epis_hhc_req_status;
        l_id_episode                epis_hhc_req.id_episode%TYPE;
        l_id_patient                epis_hhc_req.id_patient%TYPE;
        l_hhc_proc                  epis_hhc_req.id_epis_hhc%TYPE;
        l_id_prof_coor              epis_hhc_req.id_prof_coordinator%TYPE;
    BEGIN
        l_id_patient   := get_id_patient_by_hhc_req(i_id_epis_hhc_req);
        l_id_episode   := get_id_episode_by_hhc_req(i_id_epis_hhc_req);
        l_hhc_proc     := get_hhc_process(i_id_epis_hhc_req);
        l_id_prof_coor := get_id_prof_coordinator(i_id_epis_hhc_req);
    
        --insert undo action in epis_hhc_req_h
        ins_req_hist(i_id_epis_hhc_req,
                     i_prof,
                     l_id_patient,
                     l_id_episode,
                     l_status_undo,
                     i_id_reason,
                     i_reason,
                     l_hhc_proc,
                     NULL,
                     NULL,
                     l_id_prof_coor);
        -- ir buscar atual (req_status)
        l_epis_hhc_req_status_atual := get_epis_hhc_req_prev_info(i_lang            => i_lang,
                                                                  i_prof            => i_prof,
                                                                  i_id_epis_hhc_req => i_id_epis_hhc_req,
                                                                  i_row             => 1);
    
        -- atualizar flg_undone no registo atual (req_status)
        l_ret := upd_req_status_general(i_id_epis_hhc_req => i_id_epis_hhc_req,
                                        i_id_professional => l_epis_hhc_req_status_atual.id_professional,
                                        i_flg_status      => l_epis_hhc_req_status_atual.flg_status,
                                        i_dt_status       => l_epis_hhc_req_status_atual.dt_status,
                                        i_id_reason       => l_epis_hhc_req_status_atual.id_reason,
                                        i_reason_notes    => l_epis_hhc_req_status_atual.reason_notes,
                                        i_what_2_upd      => 'FLG_UNDONE');
    
        /*ir buscar info ao estado anterior ao atual*/
        l_epis_hhc_req_status_prev := get_epis_hhc_req_prev_info(i_lang            => i_lang,
                                                                 i_prof            => i_prof,
                                                                 i_id_epis_hhc_req => i_id_epis_hhc_req,
                                                                 i_row             => 1);
    
        l_new_status := l_epis_hhc_req_status_prev.flg_status;
    
        /* partially accepted with/without cm -> remove case manager update status to Requested*/
        IF l_epis_hhc_req_status_atual.flg_status IN (k_hhc_part_approved, k_hhc_in_part_acc_wcm)
        THEN
            l_new_status := k_hhc_requested;
            l_ret        := remove_case_man(i_lang            => i_lang,
                                            i_prof            => i_prof,
                                            i_id_epis_hhc_req => i_id_epis_hhc_req,
                                            i_prev_status     => l_new_status,
                                            o_error           => o_error);
        
        ELSE
        
            /* approved and rejected -> update to the previous status*/
            l_ret := pk_hhc_core.upd_epis_req(i_prof                => i_prof,
                                              i_id_epis_hhc_req     => i_id_epis_hhc_req,
                                              i_flg_status          => l_new_status,
                                              i_id_prof_manager     => NULL,
                                              i_dt_prof_manager     => NULL,
                                              i_prof_null           => k_no,
                                              i_id_prof_coordinator => i_prof.id,
                                              i_id_cancel_reason    => i_id_reason,
                                              i_cancel_notes        => i_reason);
        
            l_ret := ins_req_status(i_id_epis_hhc_req,
                                    i_prof.id,
                                    l_epis_hhc_req_status_prev.flg_status,
                                    l_epis_hhc_req_status_prev.id_reason,
                                    l_epis_hhc_req_status_prev.reason_notes);
        END IF;
        RETURN l_ret;
    
    END set_status_undo;

    FUNCTION get_type_text
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        flg_component_type IN ds_component.flg_component_type%TYPE
    ) RETURN VARCHAR2 IS
        l_ret VARCHAR2(3 CHAR);
    BEGIN
    
        CASE flg_component_type
            WHEN k_ds_flg_component_type_node THEN
                l_ret := pk_alert_constant.g_flg_screen_l2b;
            WHEN k_ds_flg_component_type_leaf THEN
                l_ret := pk_alert_constant.g_flg_screen_l3;
            ELSE
                l_ret := NULL;
        END CASE;
    
        RETURN l_ret;
    END get_type_text;

    FUNCTION get_reason
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_epis_hhc_req IN epis_hhc_req.id_epis_hhc_req%TYPE,
        i_flg_status      IN epis_hhc_req_status.flg_status%TYPE,
        i_dt_creation     IN epis_hhc_req_h.dt_creation%TYPE
    ) RETURN CLOB IS
    
        l_ret CLOB;
    BEGIN
    
        SELECT pk_translation.get_translation(i_lang      => i_lang,
                                              i_code_mess => 'CANCEL_REASON.CODE_CANCEL_REASON.' || x.id_reason)
          INTO l_ret
          FROM (SELECT v.cancel_notes, v.id_cancel_reason id_reason
                  FROM v_epis_hhc_req_h v
                 WHERE v.id_epis_hhc_req = i_id_epis_hhc_req
                   AND v.flg_status = i_flg_status
                   AND v.dt_creation = i_dt_creation) x
         WHERE rownum = 1;
    
        RETURN l_ret;
    
    END get_reason;

    FUNCTION get_reason_notes
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_epis_hhc_req IN epis_hhc_req.id_epis_hhc_req%TYPE,
        i_flg_status      IN epis_hhc_req_status.flg_status%TYPE,
        i_dt_creation     IN epis_hhc_req_h.dt_creation%TYPE
    ) RETURN CLOB IS
    
        l_ret CLOB;
    BEGIN
    
        SELECT x.reason_notes
          INTO l_ret
          FROM (SELECT v.cancel_notes reason_notes, v.id_cancel_reason id_reason
                  FROM v_epis_hhc_req_h v
                 WHERE v.id_epis_hhc_req = i_id_epis_hhc_req
                   AND v.flg_status = i_flg_status
                   AND v.dt_creation = i_dt_creation) x
         WHERE rownum = 1;
    
        RETURN l_ret;
    
    END get_reason_notes;

    FUNCTION check_hhc_undo(i_id_epis_hhc_req IN epis_hhc_req.id_epis_hhc_req%TYPE) RETURN VARCHAR2 IS
        l_return VARCHAR2(0010 CHAR) := k_no;
        l_count  NUMBER;
    BEGIN
    
        SELECT COUNT(*)
          INTO l_count
          FROM epis_hhc_req_status
         WHERE id_epis_hhc_req = i_id_epis_hhc_req
           AND flg_undone = k_hhc_undo;
    
        IF l_count > 0
        THEN
            l_return := k_yes;
        END IF;
    
        RETURN l_return;
    END check_hhc_undo;

    FUNCTION get_case_manager_by_status
    (
        i_epis_hhc_req IN epis_hhc_req.id_epis_hhc_req%TYPE,
        i_flg_status   IN epis_hhc_req_h.flg_status%TYPE,
        i_dt_creation  IN epis_hhc_req_h.dt_creation%TYPE
    ) RETURN NUMBER IS
        l_return   NUMBER;
        tbl_return table_number;
    BEGIN
    
        SELECT hrh.id_prof_manager
          BULK COLLECT
          INTO tbl_return
          FROM v_epis_hhc_req_h hrh
         WHERE hrh.id_epis_hhc_req = i_epis_hhc_req
           AND hrh.dt_creation = i_dt_creation
           AND hrh.flg_status = i_flg_status
           AND hrh.id_prof_manager IS NOT NULL;
    
        IF tbl_return.count > 0
        THEN
            l_return := tbl_return(1);
        END IF;
    
        RETURN l_return;
    
    END get_case_manager_by_status;

    FUNCTION get_req_status_formatted
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_epis_hhc_req IN epis_hhc_req.id_epis_hhc_req%TYPE,
        i_flg_detail      IN VARCHAR2,
        io_req_det        IN OUT t_coll_hhc_req_hist,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
        --l_func_name CONSTANT VARCHAR2(24 CHAR) := 'get_req_status_formatted';
    
        l_status table_varchar;
    
        l_desc sys_message.desc_message%TYPE;
        l_val  CLOB;
        l_type VARCHAR2(3 CHAR);
        --l_flg_status    epis_hhc_req.flg_status%TYPE;
        l_signature     VARCHAR2(200 CHAR);
        l_update_user   table_number;
        l_update_time   table_timestamp;
        l_undo          VARCHAR2(1);
        l_status_not_in VARCHAR2(1);
        l_status_old    VARCHAR2(2) := '-1';
    BEGIN
        l_undo := check_hhc_undo(i_id_epis_hhc_req);
        IF l_undo = k_no
        THEN
            l_status_not_in := k_hhc_requested;
        ELSIF l_undo = k_yes
        THEN
            l_status_not_in := k_hhc_undo;
        END IF;
    
        IF i_flg_detail = pk_hhc_constant.k_detail_status_referral_hist
        THEN
            SELECT x.flg_status flg_status, x.id_prof_creation id_professional, x.dt_creation dt_status
              BULK COLLECT
              INTO l_status, l_update_user, l_update_time
              FROM (SELECT h.flg_status, h.id_prof_creation, h.dt_creation
                      FROM v_epis_hhc_req_h h
                      LEFT JOIN v_epis_hhc_req_status v
                        ON (h.id_epis_hhc_req = v.id_epis_hhc_req AND
                           to_char(v.dt_status, 'dd-mm-yy hh24:mm:ss') = to_char(h.dt_creation, 'dd-mm-yy hh24:mm:ss'))
                     WHERE h.id_epis_hhc_req = i_id_epis_hhc_req
                     ORDER BY h.dt_creation DESC, h.flg_status ASC) x
             WHERE (i_flg_detail = pk_hhc_constant.k_detail_status_referral_hist);
        
        ELSIF i_flg_detail IN (pk_hhc_constant.k_detail_status_referral_det, pk_hhc_constant.k_detail_status_referral)
        THEN
            SELECT x.flg_status flg_status, x.id_prof_creation id_professional, x.dt_status dt_status
              BULK COLLECT
              INTO l_status, l_update_user, l_update_time
              FROM (SELECT h.flg_status, h.id_prof_creation, h.dt_creation dt_status
                      FROM v_epis_hhc_req_h h
                      LEFT JOIN v_epis_hhc_req_status v
                        ON (h.id_epis_hhc_req = v.id_epis_hhc_req AND
                           to_char(h.dt_creation, 'dd-mm-yy hh24:mm:ss') = to_char(v.dt_status, 'dd-mm-yy hh24:mm:ss'))
                     WHERE h.id_epis_hhc_req = i_id_epis_hhc_req
                          
                       AND (h.flg_status NOT IN (l_status_not_in) AND nvl(v.flg_undone, 'N') NOT IN (k_hhc_undo))
                     ORDER BY h.dt_creation DESC, h.flg_status ASC) x
             WHERE ((i_flg_detail = pk_hhc_constant.k_detail_status_referral_det AND rownum = 1) OR
                   i_flg_detail IN
                   (pk_hhc_constant.k_detail_status_referral, pk_hhc_constant.k_detail_status_referral_hist));
        
        END IF;
    
        -- começa o tratamento
        FOR i IN 1 .. l_status.count
        
        LOOP
            IF (l_status_old != l_status(i) AND
               i_flg_detail IN
               (pk_hhc_constant.k_detail_status_referral, pk_hhc_constant.k_detail_status_referral_det))
               OR (i_flg_detail = pk_hhc_constant.k_detail_status_referral_hist)
            THEN
                EXIT WHEN((i = l_status.count AND l_status(i) = k_hhc_requested) OR
                          (i != l_status.count AND l_status(i) = k_hhc_requested AND
                          i_flg_detail = pk_hhc_constant.k_detail_status_referral));
                -- começa por escrever o estado
                --l_desc := ' ';
                l_val  := ' ';
                l_type := pk_alert_constant.g_flg_screen_l1;
                l_desc := pk_sysdomain.get_domain(i_code_dom => pk_hhc_constant.k_hhc_flg_status_domain,
                                                  i_val      => l_status(i),
                                                  i_lang     => i_lang);
            
                io_req_det.extend;
                io_req_det(io_req_det.last()) := t_rec_hhc_req_hist(l_desc,
                                                                    l_val,
                                                                    l_type,
                                                                    l_status(i),
                                                                    i_id_epis_hhc_req);
            
                -- white line
                l_desc := ' ';
                l_val  := ' ';
                l_type := pk_alert_constant.g_flg_screen_wl;
            
                io_req_det.extend;
                io_req_det(io_req_det.last()) := t_rec_hhc_req_hist(l_desc,
                                                                    l_val,
                                                                    l_type,
                                                                    l_status(i),
                                                                    i_id_epis_hhc_req);
                -- tratamento das secções dependendo do estado
                IF l_status(i) IN (k_hhc_rejected, k_hhc_part_approved, k_hhc_in_part_acc_wcm)
                THEN
                
                    CASE l_status(i)
                        WHEN k_hhc_rejected THEN
                            -- primeira secção com descrição geral
                            l_desc := pk_message.get_message(i_lang => i_lang, i_code_mess => 'HHC_REF_REJECTION');
                        WHEN k_hhc_part_approved THEN
                            l_desc := pk_message.get_message(i_lang => i_lang, i_code_mess => 'HHC_REF_PART_ACCEPT');
                        WHEN k_hhc_in_part_acc_wcm THEN
                            l_desc := pk_message.get_message(i_lang => i_lang, i_code_mess => 'HHC_REF_PART_ACCEPT');
                    END CASE;
                
                    l_val  := ' ';
                    l_type := pk_alert_constant.g_flg_screen_l2b;
                
                    io_req_det.extend;
                    io_req_det(io_req_det.last) := t_rec_hhc_req_hist(descr      => l_desc,
                                                                      val        => l_val,
                                                                      tipo       => l_type,
                                                                      flg_status => l_status(i),
                                                                      id_request => i_id_epis_hhc_req);
                
                    l_val := get_reason(i_lang            => i_lang,
                                        i_prof            => i_prof,
                                        i_id_epis_hhc_req => i_id_epis_hhc_req,
                                        i_flg_status      => l_status(i),
                                        i_dt_creation     => l_update_time(i));
                    --HHC reason
                    IF l_val IS NOT NULL
                    THEN
                    
                        l_desc := pk_message.get_message(i_lang => i_lang, i_code_mess => 'HHC_REASON') ||
                                  pk_alert_constant.g_two_points;
                    
                        l_type := pk_alert_constant.g_flg_screen_l3;
                    
                        io_req_det.extend;
                        io_req_det(io_req_det.last) := t_rec_hhc_req_hist(descr      => l_desc,
                                                                          val        => l_val,
                                                                          tipo       => l_type,
                                                                          flg_status => l_status(i),
                                                                          id_request => i_id_epis_hhc_req);
                    END IF;
                    --HHC reason notes
                    l_val := get_reason_notes(i_lang            => i_lang,
                                              i_prof            => i_prof,
                                              i_id_epis_hhc_req => i_id_epis_hhc_req,
                                              i_flg_status      => l_status(i),
                                              i_dt_creation     => l_update_time(i));
                    IF l_val IS NOT NULL
                    THEN
                        l_desc := pk_message.get_message(i_lang => i_lang, i_code_mess => 'HHC_REASON_NOTES') ||
                                  pk_alert_constant.g_two_points;
                    
                        l_type := pk_alert_constant.g_flg_screen_l3;
                    
                        io_req_det.extend;
                        io_req_det(io_req_det.last) := t_rec_hhc_req_hist(descr      => l_desc,
                                                                          val        => l_val,
                                                                          tipo       => l_type,
                                                                          flg_status => l_status(i),
                                                                          id_request => i_id_epis_hhc_req);
                    END IF;
                ELSIF l_status(i) IN (k_hhc_canceled, k_hhc_undo, k_hhc_approved, k_hhc_discontinued)
                
                THEN
                    -- reason
                    l_val := get_reason(i_lang            => i_lang,
                                        i_prof            => i_prof,
                                        i_id_epis_hhc_req => i_id_epis_hhc_req,
                                        i_flg_status      => l_status(i),
                                        i_dt_creation     => l_update_time(i));
                    IF l_val IS NOT NULL
                    THEN
                    
                        l_desc := pk_message.get_message(i_lang => i_lang, i_code_mess => 'HHC_REASON') ||
                                  pk_alert_constant.g_two_points;
                    
                        l_type := pk_alert_constant.g_flg_screen_l2b;
                    
                        io_req_det.extend;
                        io_req_det(io_req_det.last) := t_rec_hhc_req_hist(descr      => l_desc,
                                                                          val        => l_val,
                                                                          tipo       => l_type,
                                                                          flg_status => l_status(i),
                                                                          id_request => i_id_epis_hhc_req);
                    END IF;
                
                    l_val := get_reason_notes(i_lang            => i_lang,
                                              i_prof            => i_prof,
                                              i_id_epis_hhc_req => i_id_epis_hhc_req,
                                              i_flg_status      => l_status(i),
                                              i_dt_creation     => l_update_time(i));
                    IF l_val IS NOT NULL
                    THEN
                        l_desc := pk_message.get_message(i_lang => i_lang, i_code_mess => 'HHC_REASON_NOTES') ||
                                  pk_alert_constant.g_two_points;
                    
                        l_type := pk_alert_constant.g_flg_screen_l2b;
                    
                        io_req_det.extend;
                        io_req_det(io_req_det.last) := t_rec_hhc_req_hist(descr      => l_desc,
                                                                          val        => l_val,
                                                                          tipo       => l_type,
                                                                          flg_status => l_status(i),
                                                                          id_request => i_id_epis_hhc_req);
                    
                    END IF;
                
                END IF;
            
                -- parte do assigned case manager
                IF i_flg_detail IN (pk_hhc_constant.k_detail_status_referral,
                                    pk_hhc_constant.k_detail_status_referral_det,
                                    pk_hhc_constant.k_detail_status_referral_hist)
                THEN
                    IF l_status(i) = pk_hhc_constant.k_hhc_req_status_part_approved
                    THEN
                        l_desc := pk_message.get_message(i_lang => i_lang, i_code_mess => 'HHC_REF_ASSIGN_CM') ||
                                  pk_alert_constant.g_two_points;
                        l_val  := pk_prof_utils.get_name(i_lang    => i_lang,
                                                         i_prof_id => get_case_manager_by_status(i_id_epis_hhc_req,
                                                                                                 l_status(i),
                                                                                                 l_update_time(i)));
                    
                        l_type := pk_alert_constant.g_flg_screen_l3;
                    
                        io_req_det.extend;
                        io_req_det(io_req_det.last) := t_rec_hhc_req_hist(descr      => l_desc,
                                                                          val        => l_val,
                                                                          tipo       => l_type,
                                                                          flg_status => l_status(i),
                                                                          id_request => i_id_epis_hhc_req);
                    END IF;
                END IF;
            
                l_signature := get_prof_signature(i_lang, i_prof, l_update_user(i), l_update_time(i));
                io_req_det.extend;
                io_req_det(io_req_det.last()) := t_rec_hhc_req_hist(pk_message.get_message(i_lang, 'COMMON_M156') ||
                                                                    pk_alert_constant.g_two_points,
                                                                    l_signature,
                                                                    pk_alert_constant.g_flg_screen_lp,
                                                                    l_status(i),
                                                                    i_id_epis_hhc_req);
            
                -- white line
                l_desc := ' ';
                l_val  := ' ';
                l_type := pk_alert_constant.g_flg_screen_wl;
            
                io_req_det.extend;
                io_req_det(io_req_det.last()) := t_rec_hhc_req_hist(l_desc,
                                                                    l_val,
                                                                    l_type,
                                                                    l_status(i),
                                                                    i_id_epis_hhc_req);
            
                -- separador
                IF i_flg_detail = pk_hhc_constant.k_detail_status_referral
                THEN
                    l_desc := ' ';
                    l_val  := ' ';
                    l_type := 'S';
                END IF;
            
                io_req_det.extend;
                io_req_det(io_req_det.last()) := t_rec_hhc_req_hist(l_desc,
                                                                    l_val,
                                                                    l_type,
                                                                    l_status(i),
                                                                    i_id_epis_hhc_req);
                IF i_flg_detail NOT IN (pk_hhc_constant.k_detail_status_referral_hist)
                THEN
                    -- white line
                    l_desc := ' ';
                    l_val  := ' ';
                    l_type := pk_alert_constant.g_flg_screen_wl;
                
                    io_req_det.extend;
                    io_req_det(io_req_det.last()) := t_rec_hhc_req_hist(l_desc,
                                                                        l_val,
                                                                        l_type,
                                                                        l_status(i),
                                                                        i_id_epis_hhc_req);
                END IF;
            END IF;
            l_status_old := l_status(i);
        END LOOP;
    
        RETURN TRUE;
    
    END get_req_status_formatted;

    /*table function genérica para ir buscar todos os requests que estao com determinada flg_status*/
    FUNCTION get_all_epis_hhc_req_by_status
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_flg_status        IN table_varchar,
        i_id_prof_requested IN epis_hhc_req.id_prof_manager%TYPE
    ) RETURN t_coll_epis_hhc_req IS
        t_coll t_coll_epis_hhc_req;
    BEGIN
    
        SELECT t_epis_hhc_req(id_epis_hhc_req     => er.id_epis_hhc_req,
                              id_episode          => er.id_episode,
                              flg_status          => er.flg_status,
                              id_cancel_reason    => er.id_cancel_reason,
                              cancel_notes        => er.cancel_notes,
                              id_prof_manager     => er.id_prof_manager,
                              dt_prof_manager     => er.dt_prof_manager,
                              id_patient          => er.id_patient,
                              id_epis_hhc         => er.id_epis_hhc,
                              id_prof_coordinator => er.id_prof_coordinator)
          BULK COLLECT
          INTO t_coll
          FROM v_epis_hhc_req er
         WHERE er.flg_status IN (SELECT /*+opt_estimate (table t rows=1)*/
                                  column_value
                                   FROM TABLE(i_flg_status) t);
    
        RETURN t_coll;
    
    END get_all_epis_hhc_req_by_status;

    /*
    *  Private function that trims a t_wl_search_row_coll collection at both ends.
    *  used by search_wl_* functions.
    */
    PROCEDURE trim_coll_bfs
    (
        i_coll          IN OUT NOCOPY t_coll_wl_hhc_req,
        i_page          IN NUMBER DEFAULT 1,
        i_rows_per_page IN NUMBER DEFAULT 20
    ) IS
        l_func_name VARCHAR2(30) := 'TRIM_COLL_BFS';
        l_start     NUMBER := ((i_page - 1) * i_rows_per_page) + 1;
    BEGIN
    
        -- trim inferior
        g_error := l_func_name || ' - LOWER TRIM';
        i_coll.delete(1, l_start - 1);
        -- trim superior
        g_error := l_func_name || ' - UPPER TRIM';
        IF nvl(i_rows_per_page, 20) <= i_coll.count
        THEN
            i_coll.trim(i_coll.count - i_rows_per_page);
        END IF;
    
        --RETURN TRUE;
    END trim_coll_bfs;

    -- ************************** cmf
    FUNCTION get_team_id_professional
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_tbl_inst   IN table_number,
        i_id_hhc_req IN epis_hhc_req.id_epis_hhc_req%TYPE
    ) RETURN table_number IS
        l_ret   table_number;
        l_team  NUMBER;
        l_error t_error_out;
    BEGIN
        IF NOT pk_prof_teams.get_id_prof_team(i_lang         => i_lang,
                                              i_prof         => i_prof,
                                              i_id_hhc_req   => i_id_hhc_req,
                                              i_tbl_inst     => i_tbl_inst,
                                              o_id_prof_team => l_team,
                                              o_error        => l_error)
        THEN
            l_team := NULL;
        END IF;
    
        IF l_team IS NOT NULL
        THEN
            SELECT x.id_professional
              BULK COLLECT
              INTO l_ret
              FROM TABLE(pk_prof_teams.tf_get_team_det(i_lang      => i_lang,
                                                       i_prof      => i_prof,
                                                       i_tbl_inst  => i_tbl_inst,
                                                       i_prof_team => l_team)) x;
        END IF;
    
        RETURN l_ret;
    
    END get_team_id_professional;

    FUNCTION get_team_id_professional
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_hhc_req IN epis_hhc_req.id_epis_hhc_req%TYPE
    ) RETURN table_number IS
        l_ret   table_number;
        l_team  NUMBER;
        l_error t_error_out;
    BEGIN
    
        IF NOT pk_prof_teams.get_id_prof_team(i_lang         => i_lang,
                                              i_prof         => i_prof,
                                              i_id_hhc_req   => i_id_hhc_req,
                                              o_id_prof_team => l_team,
                                              o_error        => l_error)
        THEN
            l_team := NULL;
        END IF;
    
        IF l_team IS NOT NULL
        THEN
            SELECT x.id_professional
              BULK COLLECT
              INTO l_ret
              FROM TABLE(pk_prof_teams.tf_get_team_det(i_lang => i_lang, i_prof => i_prof, i_prof_team => l_team)) x;
        END IF;
    
        RETURN l_ret;
    
    END get_team_id_professional;

    FUNCTION is_part_of_team
    (
        i_lang            IN language.id_language%TYPE,
        i_id_professional IN NUMBER,
        i_team            IN table_number
    ) RETURN VARCHAR2 IS
        l_bool BOOLEAN;
        l_ret  VARCHAR2(1 CHAR) := k_no;
    BEGIN
        IF i_team IS NOT NULL
        THEN
            FOR i IN 1 .. i_team.count
            LOOP
                l_bool := i_team(i) = i_id_professional;
                EXIT WHEN l_bool;
            END LOOP;
        
            IF l_bool
            THEN
                l_ret := k_yes;
            END IF;
        END IF;
        RETURN l_ret;
    
    END is_part_of_team;

    FUNCTION get_id_appointment(i_id_sch_event IN NUMBER) RETURN VARCHAR2 IS
        l_return   VARCHAR2(0200 CHAR);
        tbl_return table_varchar;
    BEGIN
    
        SELECT id_appointment
          BULK COLLECT
          INTO tbl_return
          FROM appointment x
         WHERE x.id_sch_event = i_id_sch_event
           AND flg_available = k_yes;
    
        IF tbl_return.count > 0
        THEN
            l_return := tbl_return(1);
        END IF;
    
        RETURN l_return;
    
    END get_id_appointment;

    /*função para a WL (ADT) que devolve (com as devidas tranformações) todos os requests que foram aprovados*/
    FUNCTION get_appr_epis_hhc_req_base_tf
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_tbl_inst          IN table_number,
        i_id_patient        IN patient.id_patient%TYPE,
        i_id_prof_requested IN epis_hhc_req.id_prof_manager%TYPE,
        i_age_min           IN NUMBER,
        i_age_max           IN NUMBER,
        i_gender            IN VARCHAR2,
        i_page              IN NUMBER DEFAULT 1,
        i_rows_per_page     IN NUMBER DEFAULT 20
    ) RETURN t_coll_wl_hhc_req IS
    
        l_status table_varchar := table_varchar(pk_hhc_constant.k_hhc_req_status_approved,
                                                pk_hhc_constant.k_hhc_req_status_in_progress);
    
        o_data           t_coll_wl_hhc_req;
        l_id_appointment VARCHAR2(0200 CHAR);
    BEGIN
    
        pk_alertlog.log_debug('i_id_patient:' || i_id_patient || ' i_id_prof_requested:' || i_id_prof_requested ||
                              ' i_age_min:' || i_age_min || ' i_age_max:' || i_age_max || ' i_gender:' || i_gender ||
                              ' i_page:' || i_page || 'i_rows_per_page:' || i_rows_per_page || ' I_PROF:' ||
                              pk_utils.to_string(i_input => i_prof));
    
        l_id_appointment := get_id_appointment(pk_hhc_constant.k_hhc_sch_event);
    
        SELECT t_wl_hhc_req(id_patient       => e.id_patient,
                            id_dep_clin_serv => d.id_dep_clin_serv,
                            id_service       => NULL,
                            id_speciality    => NULL,
                            id_requisition   => x.id_epis_hhc_req,
                            flg_type         => pk_hhc_constant.k_wl_hhc_flg_type,
                            dt_creation      => get_dt_status(i_epis_hhc_req => x.id_epis_hhc_req,
                                                              i_flg_status   => l_status(1)),
                            id_user_creation => pk_hhc_core.get_id_prof_request(i_epis_hhc_req => x.id_epis_hhc_req),
                            id_institution   => i_prof.institution,
                            id_language      => i_lang,
                            patient_name     => pk_patient.get_pat_name(i_lang    => i_lang,
                                                                        i_prof    => i_prof,
                                                                        i_patient => e.id_patient,
                                                                        i_episode => e.id_episode),
                            patient_origin   => get_type_origin_value(i_lang         => i_lang,
                                                                      i_epis_hhc_req => x.id_epis_hhc_req,
                                                                      i_type_name    => k_hhc_det_type_orig_name),
                            dt_status        => get_dt_status(i_epis_hhc_req => x.id_epis_hhc_req,
                                                              i_flg_status   => l_status(1)),
                            
                            id_content    => l_id_appointment,
                            professionals => pk_hhc_core.get_team_id_professional(i_lang       => i_lang,
                                                                                  i_prof       => i_prof,
                                                                                  i_tbl_inst   => i_tbl_inst,
                                                                                  i_id_hhc_req => x.id_epis_hhc_req))
          BULK COLLECT
          INTO o_data
          FROM episode e
          JOIN TABLE(pk_hhc_core.get_all_epis_hhc_req_by_status(i_lang => i_lang, i_prof => i_prof, i_flg_status => l_status, i_id_prof_requested => i_id_prof_requested)) x
            ON x.id_epis_hhc = e.id_episode --x.id_episode
          LEFT JOIN dep_clin_serv d
            ON d.id_department = e.id_department
           AND d.id_clinical_service = e.id_clinical_service
          JOIN patient p
            ON e.id_patient = p.id_patient
          JOIN visit v
            ON v.id_visit = e.id_visit
         WHERE e.id_institution IN (SELECT /*+ opt_estimate(table t rows=1) */
                                     column_value
                                      FROM TABLE(i_tbl_inst) t)
           AND (i_age_min IS NULL OR
               ((pk_patient.get_pat_age(i_lang        => i_lang,
                                         i_dt_birth    => p.dt_birth,
                                         i_dt_deceased => p.dt_deceased,
                                         i_age         => p.age,
                                         i_age_format  => 'YEARS',
                                         i_patient     => p.id_patient) >= i_age_min)))
           AND (i_age_max IS NULL OR
               ((pk_patient.get_pat_age(i_lang        => i_lang,
                                         i_dt_birth    => p.dt_birth,
                                         i_dt_deceased => p.dt_deceased,
                                         i_age         => p.age,
                                         i_age_format  => 'YEARS',
                                         i_patient     => p.id_patient) <= i_age_max)))
           AND (i_gender IS NULL OR pk_patient.get_pat_gender(e.id_patient) = i_gender)
           AND (e.id_patient = i_id_patient OR i_id_patient IS NULL)
           AND (i_id_prof_requested IS NULL OR
               (is_part_of_team(i_lang,
                                 i_id_prof_requested,
                                 get_team_id_professional(i_lang       => i_lang,
                                                          i_prof       => i_prof,
                                                          i_tbl_inst   => i_tbl_inst,
                                                          i_id_hhc_req => x.id_epis_hhc_req)) = k_yes))
           AND check_team_has_schedules(i_lang            => i_lang,
                                        i_prof            => i_prof,
                                        i_tbl_inst        => i_tbl_inst,
                                        i_id_epis_hhc_req => x.id_epis_hhc_req) = k_no;
    
        RETURN o_data;
    
    END get_appr_epis_hhc_req_base_tf;

    FUNCTION get_approved_epis_hhc_req_tf
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_tbl_inst          IN table_number,
        i_id_patient        IN patient.id_patient%TYPE,
        i_id_prof_requested IN epis_hhc_req.id_prof_manager%TYPE,
        i_age_min           IN NUMBER,
        i_age_max           IN NUMBER,
        i_gender            IN VARCHAR2,
        i_page              IN NUMBER DEFAULT 1,
        i_rows_per_page     IN NUMBER DEFAULT 20,
        o_row_count         OUT NUMBER
    ) RETURN t_coll_wl_hhc_req IS
        o_data t_coll_wl_hhc_req := t_coll_wl_hhc_req();
    BEGIN
    
        o_data := pk_hhc_core.get_appr_epis_hhc_req_base_tf(i_lang              => i_lang,
                                                            i_prof              => i_prof,
                                                            i_tbl_inst          => i_tbl_inst,
                                                            i_id_patient        => i_id_patient,
                                                            i_id_prof_requested => i_id_prof_requested,
                                                            i_age_min           => i_age_min,
                                                            i_age_max           => i_age_max,
                                                            i_gender            => i_gender,
                                                            i_page              => i_page,
                                                            i_rows_per_page     => i_rows_per_page);
    
        o_row_count := o_data.count;
    
        trim_coll_bfs(o_data, i_page, i_rows_per_page);
    
        RETURN o_data;
    
    END get_approved_epis_hhc_req_tf;

    FUNCTION get_approved_epis_hhc_req
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_tbl_inst          IN table_number,
        i_id_patient        IN patient.id_patient%TYPE,
        i_id_prof_requested IN epis_hhc_req.id_prof_manager%TYPE,
        i_age_min           IN NUMBER,
        i_age_max           IN NUMBER,
        i_gender            IN VARCHAR2,
        i_page              IN NUMBER DEFAULT 1,
        i_rows_per_page     IN NUMBER DEFAULT 20,
        o_data              OUT t_wl_search_row_coll,
        o_row_count         OUT NUMBER,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        l_coll_wl_hhc_req t_coll_wl_hhc_req;
        l_func_name CONSTANT VARCHAR2(25 CHAR) := 'get_approved_epis_hhc_req';
    
        -- l_test  table_table_number;
        --l_test2 table_number;
    BEGIN
    
        l_coll_wl_hhc_req := get_approved_epis_hhc_req_tf(i_lang              => i_lang,
                                                          i_prof              => i_prof,
                                                          i_tbl_inst          => i_tbl_inst,
                                                          i_id_patient        => i_id_patient,
                                                          i_id_prof_requested => i_id_prof_requested,
                                                          i_age_min           => i_age_min,
                                                          i_age_max           => i_age_max,
                                                          i_gender            => i_gender,
                                                          i_page              => i_page,
                                                          i_rows_per_page     => i_rows_per_page,
                                                          o_row_count         => o_row_count);
    
        SELECT t_wl_search_row(idrequisition            => x.id_requisition,
                               flgtype                  => x.flg_type,
                               qtl_flg_type             => NULL,
                               flg_status               => NULL,
                               idpatient                => x.id_patient,
                               relative_urgency         => NULL,
                               dtcreation               => x.dt_creation,
                               idusercreation           => x.id_user_creation,
                               idinstitution            => x.id_institution,
                               idservice                => x.id_service,
                               idresource               => NULL,
                               resourcetype             => NULL,
                               dtbeginmin               => NULL,
                               dtbeginmax               => NULL,
                               flgcontacttype           => NULL,
                               priority                 => NULL,
                               urgencylevel             => NULL,
                               idlanguage               => x.id_language,
                               idmotive                 => NULL,
                               motivetype               => NULL,
                               motivedescription        => NULL,
                               sessionnumber            => NULL,
                               frequencyunit            => NULL,
                               frequency                => NULL,
                               iddepclinserv            => table_number(x.id_dep_clin_serv),
                               idspeciality             => table_number(x.id_speciality),
                               expectedduration         => NULL,
                               hasrequisitiontoschedule => NULL,
                               sk_relative_urgency      => NULL,
                               sk_absolute_urgency      => NULL,
                               sk_waiting_time          => NULL,
                               sk_urgency_level         => NULL,
                               sk_barthel               => NULL,
                               sk_gender                => NULL,
                               idcontent                => x.id_content,
                               dtsugested               => NULL,
                               admissionneeded          => NULL,
                               ids_pref_surgeons        => NULL,
                               icuneeded                => NULL,
                               pos                      => NULL,
                               idroomtype               => NULL,
                               idbedtype                => NULL,
                               idpreferedroom           => NULL,
                               nurseintakeneed          => NULL,
                               mixednursing             => NULL,
                               admindic                 => NULL,
                               unavailabilitydatebegin  => NULL,
                               unavailabilitydateend    => NULL,
                               dangerofcontamination    => NULL,
                               idadmward                => NULL,
                               idadmclinserv            => NULL,
                               procdiagnosis            => NULL,
                               procsurgeon              => NULL,
                               patient_origin           => x.patient_origin,
                               dt_hhc_approval          => x.dt_status,
                               professionals            => x.professionals)
          BULK COLLECT
          INTO o_data
          FROM TABLE(l_coll_wl_hhc_req) x;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            RETURN FALSE;
        
    END get_approved_epis_hhc_req;

    FUNCTION get_approved_epis_hhc_req_curs
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_patient        IN patient.id_patient%TYPE,
        i_id_prof_requested IN epis_hhc_req.id_prof_manager%TYPE,
        i_age_min           IN NUMBER,
        i_age_max           IN NUMBER,
        i_gender            IN VARCHAR2,
        i_page              IN NUMBER DEFAULT 1,
        i_rows_per_page     IN NUMBER DEFAULT 20,
        o_data              OUT pk_types.cursor_type,
        o_row_count         OUT NUMBER,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        l_coll_wl_hhc_req t_coll_wl_hhc_req;
        l_func_name CONSTANT VARCHAR2(25 CHAR) := 'get_approved_epis_hhc_req';
    
        --l_test  table_table_number;
        --l_test2 table_number;
    BEGIN
    
        l_coll_wl_hhc_req := get_approved_epis_hhc_req_tf(i_lang              => i_lang,
                                                          i_prof              => i_prof,
                                                          i_tbl_inst          => table_number(i_prof.institution),
                                                          i_id_patient        => i_id_patient,
                                                          i_id_prof_requested => i_id_prof_requested,
                                                          i_age_min           => i_age_min,
                                                          i_age_max           => i_age_max,
                                                          i_gender            => i_gender,
                                                          i_page              => i_page,
                                                          i_rows_per_page     => i_rows_per_page,
                                                          o_row_count         => o_row_count);
    
        OPEN o_data FOR
            SELECT *
              FROM TABLE(l_coll_wl_hhc_req) x;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            RETURN FALSE;
        
    END get_approved_epis_hhc_req_curs;

    FUNCTION set_status_approve
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_epis_hhc_req IN epis_hhc_req.id_epis_hhc_req%TYPE,
        i_id_reason       IN epis_hhc_req_status.id_cancel_reason%TYPE,
        i_reason          IN CLOB,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_ret        BOOLEAN;
        l_new_status VARCHAR2(1 CHAR);
    BEGIN
    
        l_new_status := pk_hhc_constant.k_hhc_req_status_approved;
    
        /*passar para novo estado*/
        l_ret := pk_hhc_core.upd_epis_req(i_prof                => i_prof,
                                          i_id_epis_hhc_req     => i_id_epis_hhc_req,
                                          i_flg_status          => l_new_status,
                                          i_id_prof_manager     => NULL,
                                          i_dt_prof_manager     => NULL,
                                          i_prof_null           => k_no,
                                          i_id_prof_coordinator => i_prof.id,
                                          i_id_cancel_reason    => i_id_reason,
                                          i_cancel_notes        => i_reason);
    
        l_ret := ins_req_status(i_id_epis_hhc_req, i_prof.id, l_new_status, i_id_reason, i_reason);
    
        l_ret := set_hhc_approved_alert(i_lang         => i_lang,
                                        i_prof         => i_prof,
                                        i_epis_hhc_req => i_id_epis_hhc_req,
                                        i_episode      => get_id_episode_by_hhc_req(i_id_epis_hhc_req),
                                        o_error        => o_error);
    
        RETURN l_ret;
    
    END set_status_approve;

    FUNCTION get_prof_team_det
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_prof_team   IN prof_team.id_prof_team%TYPE,
        o_team_detail OUT pk_types.cursor_type,
        
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
        l_rec_team_prof_det t_coll_team_prof_det := t_coll_team_prof_det();
        l_rec_screen_detail t_coll_screen_detail := t_coll_screen_detail();
        l_val               VARCHAR2(400 CHAR);
        l_team              sys_message.desc_message%TYPE;
        l_team_members      sys_message.desc_message%TYPE;
        l_func_name CONSTANT VARCHAR2(18 CHAR) := 'get_prof_team_det';
        l_id_prof_register NUMBER;
        l_dt_register      TIMESTAMP WITH LOCAL TIME ZONE;
        l_signature        VARCHAR2(4000);
    
        --********************************************************************
        PROCEDURE set_signature
        (
            i_user IN VARCHAR2,
            i_date IN TIMESTAMP WITH LOCAL TIME ZONE
        ) IS
            l_prefix VARCHAR2(1000 CHAR);
        BEGIN
            -- DETAIL_COMMON_M001 'COMMON_M156'
            l_prefix := 'DETAIL_COMMON_M001';
        
            l_prefix := pk_message.get_message(i_lang => i_lang, i_code_mess => l_prefix);
        
            IF l_signature IS NULL
            THEN
                l_signature := l_prefix || ':' || pk_hhc_core.get_prof_signature(i_lang, i_prof, i_user, i_date);
            END IF;
        
        END set_signature;
    
        PROCEDURE get_creator_info(i_prof_team IN NUMBER) IS
        BEGIN
        
            IF i_prof_team IS NOT NULL
            THEN
                SELECT id_prof_register, dt_register
                  INTO l_id_prof_register, l_dt_register
                  FROM prof_team x
                 WHERE x.id_prof_team = i_prof_team;
            END IF;
        
        END get_creator_info;
    
    BEGIN
    
        g_error             := 'GET TF OF TEAM MEMBERS';
        l_rec_team_prof_det := pk_prof_teams.tf_get_team_det(i_lang      => i_lang,
                                                             i_prof      => i_prof,
                                                             i_prof_team => i_prof_team);
    
        l_team := pk_message.get_message(i_lang => i_lang, i_code_mess => 'PROF_TEAMS_M007');
    
        l_rec_screen_detail.extend;
        l_rec_screen_detail(l_rec_screen_detail.last()) := t_rec_screen_detail(l_team,
                                                                               '',
                                                                               pk_alert_constant.g_flg_screen_l1,
                                                                               '');
    
        l_team_members := pk_message.get_message(i_lang => i_lang, i_code_mess => 'PROF_TEAMS_M040');
        l_rec_screen_detail.extend;
        l_rec_screen_detail(l_rec_screen_detail.last()) := t_rec_screen_detail(l_team_members,
                                                                               '',
                                                                               pk_alert_constant.g_flg_screen_l2b,
                                                                               '');
    
        g_error := 'PUT TEAM MEMBERS IN TYPE';
    
        FOR r IN l_rec_team_prof_det.first() .. l_rec_team_prof_det.last()
        LOOP
            l_val := '-' || l_rec_team_prof_det(r).cat || pk_alert_constant.g_two_points || l_rec_team_prof_det(r).prof_name;
            l_rec_screen_detail.extend;
            l_rec_screen_detail(l_rec_screen_detail.last()) := t_rec_screen_detail('',
                                                                                   l_val,
                                                                                   pk_alert_constant.g_flg_screen_l2b,
                                                                                   '');
        END LOOP;
    
        get_creator_info(i_prof_team);
        set_signature(l_id_prof_register, l_dt_register);
        l_rec_screen_detail.extend;
        l_rec_screen_detail(l_rec_screen_detail.last()) := t_rec_screen_detail('', l_signature, 'LP', '');
    
        g_error := 'PUT TEAM MEMBERS CURSOR';
        OPEN o_team_detail FOR
            SELECT descr,
                   val,
                   tipo                   AS flg_type,
                   pk_alert_constant.g_no flg_html,
                   NULL                   val_clob,
                   pk_alert_constant.g_no flg_clob
              FROM TABLE(l_rec_screen_detail);
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
        
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => o_error);
        
            pk_types.open_my_cursor(o_team_detail);
            RETURN FALSE;
    END get_prof_team_det;

    FUNCTION get_hhc_id_department
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        o_id_department OUT department.id_department%TYPE,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(21 CHAR) := 'get_hhc_id_department';
        l_id_department table_number;
    BEGIN
        SELECT d.id_department
          BULK COLLECT
          INTO l_id_department
          FROM department d
         WHERE d.flg_type = pk_hhc_constant.k_dept_flg_type_h
           AND d.id_institution = i_prof.institution;
    
        IF l_id_department.count > 0
        THEN
            o_id_department := l_id_department(1);
        END IF;
        RETURN TRUE;
    
    EXCEPTION
        WHEN no_data_found THEN
        
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => o_error);
        
            o_id_department := NULL;
            RETURN FALSE;
    END get_hhc_id_department;

    FUNCTION get_epis_hhc_flg_status
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_epis_hhc_req IN epis_hhc_req.id_epis_hhc_req%TYPE,
        o_flg_status      OUT epis_hhc_req.flg_status%TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        o_flg_status := pk_hhc_core.get_epis_hhc_status(i_lang            => i_lang,
                                                        i_prof            => i_prof,
                                                        i_id_epis_hhc_req => i_id_epis_hhc_req);
        RETURN TRUE;
    
    END get_epis_hhc_flg_status;

    FUNCTION get_id_req_by_epis_hhc
    (
        i_lang       IN language.id_language%TYPE,
        i_id_episode IN episode.id_episode%TYPE
    ) RETURN epis_hhc_req.id_epis_hhc_req%TYPE IS
        l_id_epis_hhc_req epis_hhc_req.id_epis_hhc_req%TYPE;
        l_epis_type       episode.id_epis_type%TYPE;
        l_error           t_error_out;
        l_exception EXCEPTION;
        l_tbl_request table_number;
    BEGIN
    
        IF NOT pk_episode.get_epis_type(i_lang      => i_lang,
                                        i_id_epis   => i_id_episode,
                                        o_epis_type => l_epis_type,
                                        o_error     => l_error)
        THEN
            RAISE l_exception;
        END IF;
    
        IF l_epis_type = pk_hhc_constant.k_hhc_epis_type
        THEN
            SELECT ehr.id_epis_hhc_req
              BULK COLLECT
              INTO l_tbl_request
              FROM v_epis_hhc_req ehr
             WHERE ehr.id_epis_hhc = i_id_episode
               AND ehr.flg_status != pk_alert_constant.g_cancelled;
        ELSIF l_epis_type = pk_alert_constant.g_epis_type_home_health_care
        THEN
            SELECT ehr.id_epis_hhc_req
              BULK COLLECT
              INTO l_tbl_request
              FROM v_epis_hhc_req ehr
              JOIN episode e
                ON e.id_prev_episode = ehr.id_epis_hhc
             WHERE e.id_episode = i_id_episode
               AND ehr.flg_status != pk_alert_constant.g_cancelled;
        
        ELSE
            SELECT id_epis_hhc_req
              BULK COLLECT
              INTO l_tbl_request
              FROM (SELECT ehr.id_epis_hhc_req,
                           ehs.dt_status,
                           row_number() over(PARTITION BY ehs.id_epis_hhc_req ORDER BY ehs.dt_status DESC) rn
                      FROM alert.epis_hhc_req ehr
                      JOIN alert.epis_hhc_req_status ehs
                        ON ehr.id_epis_hhc_req = ehs.id_epis_hhc_req
                     WHERE ehs.flg_status = pk_hhc_constant.k_hhc_req_status_requested
                       AND ehr.flg_status <> pk_alert_constant.g_cancelled
                       AND ehr.id_episode = i_id_episode)
             WHERE rn = 1
             ORDER BY dt_status DESC;
        END IF;
    
        IF l_tbl_request.count > 0
        THEN
            l_id_epis_hhc_req := l_tbl_request(1);
        END IF;
    
        RETURN l_id_epis_hhc_req;
    EXCEPTION
        WHEN l_exception THEN
        
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_ID_REQ_BY_EPIS_HHC',
                                              o_error    => l_error);
            RETURN NULL;
        
    END get_id_req_by_epis_hhc;

    FUNCTION check_action_avail_plan
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_epis_hhc_req IN epis_hhc_req.id_epis_hhc_req%TYPE
    ) RETURN VARCHAR2 IS
        l_id_case_manager epis_hhc_req.id_prof_manager%TYPE;
        l_flg_status      epis_hhc_req.flg_status%TYPE;
        l_result          VARCHAR2(1 CHAR);
        l_id_hhc_request  epis_hhc_req.id_epis_hhc_req%TYPE;
        l_id_epis_hhc     NUMBER;
    BEGIN
    
        --l_id_hhc_request := get_id_req_by_epis_hhc(i_lang => i_lang, i_id_episode => i_id_epis_hhc);
        l_id_hhc_request := i_id_epis_hhc_req;
        l_id_epis_hhc    := get_id_epis_hhc_by_hhc_req(i_id_hhc_req => i_id_epis_hhc_req);
    
        l_flg_status := pk_hhc_core.get_epis_hhc_status(i_lang            => i_lang,
                                                        i_prof            => i_prof,
                                                        i_id_epis_hhc_req => l_id_hhc_request);
    
        l_id_case_manager := get_id_case_manager(i_epis_hhc => l_id_epis_hhc);
    
        IF i_prof.id = l_id_case_manager
           AND l_flg_status IN (k_hhc_part_approved, k_hhc_in_evaluation, k_hhc_approved, k_hhc_req_status_in_progress)
        THEN
            l_result := pk_alert_constant.g_yes;
        ELSE
            l_result := pk_alert_constant.g_no;
        END IF;
    
        RETURN l_result;
    
    END check_action_avail_plan;

    FUNCTION check_edit_avail
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_hhc_req IN epis_hhc_req.id_epis_hhc_req%TYPE
    ) RETURN VARCHAR2 IS
        l_flg_status        epis_hhc_req.flg_status%TYPE;
        l_result            VARCHAR2(1 CHAR);
        l_func_availability VARCHAR2(1 CHAR);
    BEGIN
    
        l_flg_status := pk_hhc_core.get_epis_hhc_status(i_lang            => i_lang,
                                                        i_prof            => i_prof,
                                                        i_id_epis_hhc_req => i_id_hhc_req);
    
        l_func_availability := pk_prof_utils.check_has_functionality(i_lang        => i_lang,
                                                                     i_prof        => i_prof,
                                                                     i_intern_name => 'HHC_COORDINATOR');
        IF l_func_availability = pk_alert_constant.g_yes
           AND l_flg_status IN (k_hhc_part_approved,
                                k_hhc_in_evaluation,
                                k_hhc_approved,
                                k_hhc_in_part_acc_wcm,
                                k_hhc_req_status_in_progress)
           AND i_prof.software = pk_alert_constant.g_soft_home_care
        THEN
            l_result := pk_alert_constant.g_yes;
        ELSE
            l_result := pk_alert_constant.g_no;
        END IF;
    
        RETURN l_result;
    
    END check_edit_avail;

    --função para devolver o motivo de cancelamento ou de aprovação de um request e as notas
    FUNCTION get_hhc_req_reason_notes
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_tbl_id_hhc_rec IN table_number,
        i_flg_report     IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        o_status         OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        CURSOR c_data(i_id_hhc_req IN epis_hhc_req.id_epis_hhc_req%TYPE) IS
        
            SELECT pk_sysdomain.get_domain('EPIS_HHC_REQ.FLG_STATUS', flg_status, i_lang) status,
                   pk_translation.get_translation(i_lang, code_cancel_reason) reason,
                   reason_notes notes,
                   flg_status,
                   pk_hhc_core.get_prof_signature(i_lang, i_prof, id_professional, dt_status) signature
              FROM (SELECT cr.code_cancel_reason,
                           ehrs.reason_notes,
                           ehrs.dt_status,
                           ehrs.flg_status,
                           ehrs.id_professional,
                           row_number() over(ORDER BY ehrs.dt_status DESC) rn
                      FROM v_epis_hhc_req_status ehrs
                      JOIN cancel_reason cr
                        ON ehrs.id_reason = cr.id_cancel_reason
                      JOIN v_epis_hhc_req ehr
                        ON ehr.id_epis_hhc_req = ehrs.id_epis_hhc_req
                     WHERE ehrs.id_epis_hhc_req = i_id_hhc_req
                       AND ehr.flg_status = pk_hhc_constant.k_hhc_req_status_rejected
                       AND ehrs.flg_status = pk_hhc_constant.k_hhc_req_status_rejected
                    UNION ALL
                    SELECT cr.code_cancel_reason,
                           ehrs.reason_notes,
                           ehrs.dt_status,
                           ehrs.flg_status,
                           ehrs.id_professional,
                           row_number() over(ORDER BY ehrs.dt_status DESC) rn
                      FROM v_epis_hhc_req_status ehrs
                      JOIN cancel_reason cr
                        ON ehrs.id_reason = cr.id_cancel_reason
                      JOIN v_epis_hhc_req ehr
                        ON ehr.id_epis_hhc_req = ehrs.id_epis_hhc_req
                     WHERE ehrs.id_epis_hhc_req = i_id_hhc_req
                       AND ehrs.flg_status = pk_hhc_constant.k_hhc_req_status_approved
                       AND ehr.flg_status IN (pk_hhc_constant.k_hhc_req_status_approved,
                                              pk_hhc_constant.k_hhc_req_status_in_eval,
                                              pk_hhc_constant.k_hhc_req_status_in_progress,
                                              pk_hhc_constant.k_hhc_req_status_closed))
             WHERE rn = 1;
    
        l_tbl_status t_coll_hhc_req_hist := t_coll_hhc_req_hist();
    
        l_status_lbl sys_message.desc_message%TYPE;
        l_reason_lbl sys_message.desc_message%TYPE;
        l_notes_lbl  sys_message.desc_message%TYPE;
        l_descr      sys_message.desc_message%TYPE;
    
        l_flg_status VARCHAR2(1 CHAR);
    BEGIN
    
        --get messages
        l_status_lbl := pk_message.get_message(i_lang => i_lang, i_code_mess => 'HHC_SATUS_REQUEST');
        l_reason_lbl := pk_message.get_message(i_lang => i_lang, i_code_mess => 'HHC_REASON');
        l_notes_lbl  := pk_message.get_message(i_lang => i_lang, i_code_mess => 'HHC_NOTES');
    
        l_descr := pk_message.get_message(i_lang, 'REP_COMMON_010');
    
        <<lup_main>>
        FOR t IN i_tbl_id_hhc_rec.first() .. i_tbl_id_hhc_rec.last()
        LOOP
            IF i_flg_report = pk_alert_constant.g_yes
            THEN
            
                l_tbl_status.extend;
                l_tbl_status(l_tbl_status.last()) := t_rec_hhc_req_hist(l_descr,
                                                                        '',
                                                                        pk_alert_constant.g_flg_screen_l0,
                                                                        l_flg_status,
                                                                        i_tbl_id_hhc_rec(t));
            END IF;
        
            <<lup_detail>>
            FOR r IN c_data(i_tbl_id_hhc_rec(t))
            LOOP
                l_flg_status := r.flg_status;
                l_tbl_status.extend;
                l_tbl_status(l_tbl_status.last()) := t_rec_hhc_req_hist(l_status_lbl,
                                                                        '',
                                                                        pk_alert_constant.g_flg_screen_l1,
                                                                        l_flg_status,
                                                                        i_tbl_id_hhc_rec(t));
                l_tbl_status.extend;
                l_tbl_status(l_tbl_status.last()) := t_rec_hhc_req_hist('',
                                                                        r.status,
                                                                        pk_alert_constant.g_flg_screen_l2b,
                                                                        l_flg_status,
                                                                        i_tbl_id_hhc_rec(t));
                l_tbl_status.extend;
                l_tbl_status(l_tbl_status.last()) := t_rec_hhc_req_hist(l_reason_lbl,
                                                                        '',
                                                                        pk_alert_constant.g_flg_screen_l1,
                                                                        l_flg_status,
                                                                        i_tbl_id_hhc_rec(t));
                l_tbl_status.extend;
                l_tbl_status(l_tbl_status.last()) := t_rec_hhc_req_hist('',
                                                                        r.reason,
                                                                        pk_alert_constant.g_flg_screen_l2b,
                                                                        l_flg_status,
                                                                        i_tbl_id_hhc_rec(t));
                l_tbl_status.extend;
                l_tbl_status(l_tbl_status.last()) := t_rec_hhc_req_hist(l_notes_lbl,
                                                                        '',
                                                                        pk_alert_constant.g_flg_screen_l1,
                                                                        l_flg_status,
                                                                        i_tbl_id_hhc_rec(t));
            
                l_tbl_status.extend;
                l_tbl_status(l_tbl_status.last()) := t_rec_hhc_req_hist('',
                                                                        r.notes,
                                                                        pk_alert_constant.g_flg_screen_l2b,
                                                                        l_flg_status,
                                                                        i_tbl_id_hhc_rec(t));
            
                l_tbl_status.extend;
                l_tbl_status(l_tbl_status.last()) := t_rec_hhc_req_hist(pk_message.get_message(i_lang, 'COMMON_M156') ||
                                                                        pk_alert_constant.g_two_points,
                                                                        r.signature,
                                                                        pk_alert_constant.g_flg_screen_lp,
                                                                        l_flg_status,
                                                                        i_tbl_id_hhc_rec(t));
            
            END LOOP lup_detail;
        
        END LOOP lup_main;
    
        OPEN o_status FOR
            SELECT descr, val, tipo AS flg_type, l_flg_status AS flg_status, id_request
              FROM TABLE(l_tbl_status);
    
        RETURN TRUE;
    
    END get_hhc_req_reason_notes;

    -- this FUNCTION is used IN plan screen
    FUNCTION get_prof_can_edit
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_hhc_req   IN epis_hhc_req.id_epis_hhc_req%TYPE,
        o_flg_can_edit OUT VARCHAR2,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        --l_id_epis_hhc epis_hhc_req.id_epis_hhc%TYPE;
    BEGIN
        --l_id_epis_hhc := get_id_epis_hhc_by_hhc_req(i_id_hhc_req => i_id_hhc_req);
        IF i_id_hhc_req IS NOT NULL
        THEN
            o_flg_can_edit := check_action_avail_plan(i_lang            => i_lang,
                                                      i_prof            => i_prof,
                                                      i_id_epis_hhc_req => i_id_hhc_req);
        ELSE
            o_flg_can_edit := pk_alert_constant.g_yes;
        END IF;
    
        RETURN TRUE;
    END get_prof_can_edit;

    -- *****************************************
    --verifica se o profissional é o case manager do request
    FUNCTION check_prof_is_cm
    (
        i_prof            IN profissional,
        i_id_epis_hhc_req IN epis_hhc_req.id_epis_hhc_req%TYPE
    ) RETURN VARCHAR2 IS
        l_return VARCHAR2(1 CHAR) := pk_alert_constant.g_no;
        l_count  NUMBER;
        -- tbl_return table_number;
    BEGIN
    
        SELECT COUNT(*)
          INTO l_count
          FROM v_hhc_request hr
         WHERE hr.id_epis_hhc_req = i_id_epis_hhc_req
           AND hr.id_prof_manager = i_prof.id;
    
        IF l_count > 0
        THEN
            l_return := pk_alert_constant.g_yes;
        END IF;
    
        RETURN l_return;
    
    END check_prof_is_cm;

    --função para alterar o estado do request para "IN EVALUATION" quando existem alterações
    --nos ecrãs(supplies, plan, health education)
    --efetuadas pelo case manager e o estado do request é "PARTIALLY ACCEPTED"

    FUNCTION set_req_status_ie
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_episode      IN episode.id_episode%TYPE,
        i_id_epis_hhc_req IN epis_hhc_req.id_epis_hhc_req%TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
        --l_epis_type       episode.id_epis_type%TYPE;
        l_id_epis_hhc_req epis_hhc_req.id_epis_hhc_req%TYPE;
        l_flg_status      epis_hhc_req.flg_status%TYPE;
        l_exception EXCEPTION;
        --l_flg_can_edit VARCHAR2(1 CHAR);
        l_prof_is_cm VARCHAR2(1 CHAR);
        --l_bool         BOOLEAN := FALSE;
    
    BEGIN
        g_error := 'GET ID OF REQUEST - L_ID_EPIS_HHC_REQ';
        IF i_id_epis_hhc_req IS NULL
        THEN
            l_id_epis_hhc_req := get_id_req_by_epis_hhc(i_lang => i_lang, i_id_episode => i_id_episode);
        ELSE
            l_id_epis_hhc_req := i_id_epis_hhc_req;
        END IF;
        g_error      := 'VERIFY IF PROFESSIONAL IS CASE MANAGER - L_PROF_IS_CM';
        l_prof_is_cm := check_prof_is_cm(i_prof => i_prof, i_id_epis_hhc_req => l_id_epis_hhc_req);
    
        g_error      := 'GET STATUS OF REQUEST - L_FLG_STATUS';
        l_flg_status := pk_hhc_core.get_epis_hhc_status(i_lang            => i_lang,
                                                        i_prof            => i_prof,
                                                        i_id_epis_hhc_req => l_id_epis_hhc_req);
    
        IF l_prof_is_cm = pk_alert_constant.g_yes
           AND l_flg_status = k_hhc_part_approved
        THEN
            g_error := 'CHANGE STATUS';
            IF NOT set_ref_status_ie(i_lang           => i_lang,
                                     i_prof           => i_prof,
                                     i_id_hhc_request => l_id_epis_hhc_req,
                                     o_error          => o_error)
            THEN
                RAISE l_exception;
            END IF;
        
        END IF;
        RETURN TRUE;
    EXCEPTION
        WHEN l_exception THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_ID_REQ_BY_EPIS_HHC',
                                              o_error    => o_error);
            RETURN FALSE;
    END set_req_status_ie;

    FUNCTION get_id_hhc_req_by_epis(i_id_episode IN episode.id_episode%TYPE) RETURN epis_hhc_req.id_epis_hhc_req%TYPE IS
        --l_id_epis_hhc_req epis_hhc_req.id_epis_hhc_req%TYPE;
        tbl_id   table_number;
        l_return NUMBER;
    BEGIN
        -- obter o id_da requisição pelo processo ou um episódio de homecare
        SELECT id_epis_hhc_req
          BULK COLLECT
          INTO tbl_id
          FROM v_epis_hhc_req v
         WHERE v.id_epis_hhc IN (SELECT id_prev_episode
                                   FROM episode e
                                  WHERE id_episode = i_id_episode
                                    AND e.id_epis_type = pk_alert_constant.g_epis_type_home_health_care
                                 UNION ALL
                                 SELECT i_id_episode
                                   FROM dual);
    
        IF tbl_id.count > 0
        THEN
            l_return := tbl_id(1);
        END IF;
    
        RETURN l_return;
    
    END get_id_hhc_req_by_epis;

    FUNCTION get_hhc_dt_base
    (
        i_id_episode IN episode.id_episode%TYPE,
        i_tbl_status IN table_varchar,
        i_status     IN VARCHAR2
    ) RETURN TIMESTAMP
        WITH LOCAL TIME ZONE IS
        l_date            epis_hhc_req_status.dt_status%TYPE;
        l_id_epis_hhc_req epis_hhc_req.id_epis_hhc_req%TYPE;
        tbl_date          table_timestamp_tstz;
    BEGIN
    
        l_id_epis_hhc_req := get_id_hhc_req_by_epis(i_id_episode);
    
        SELECT vs.dt_status
          BULK COLLECT
          INTO tbl_date
          FROM v_epis_hhc_req_status vs
          JOIN v_epis_hhc_req r
            ON vs.id_epis_hhc_req = r.id_epis_hhc_req
         WHERE vs.id_epis_hhc_req = l_id_epis_hhc_req
           AND r.flg_status IN (SELECT column_value
                                  FROM TABLE(i_tbl_status))
           AND vs.flg_status = i_status
         ORDER BY vs.dt_status DESC;
    
        IF tbl_date.count > 0
        THEN
            l_date := tbl_date(1);
        END IF;
    
        RETURN l_date;
    
    END get_hhc_dt_base;

    FUNCTION get_hhc_dt_admission
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE
    ) RETURN TIMESTAMP
        WITH LOCAL TIME ZONE IS
        l_admission_date epis_hhc_req_status.dt_status%TYPE;
        tbl_status       table_varchar := table_varchar(pk_hhc_constant.k_hhc_req_status_approved,
                                                        pk_hhc_constant.k_hhc_req_status_in_progress,
                                                        pk_hhc_constant.k_hhc_req_status_closed);
    BEGIN
    
        l_admission_date := get_hhc_dt_base(i_id_episode => i_id_episode,
                                            i_tbl_status => tbl_status,
                                            i_status     => pk_hhc_constant.k_hhc_req_status_approved);
    
        RETURN l_admission_date;
    
    END get_hhc_dt_admission;

    FUNCTION get_hhc_dt_discharge
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE
    ) RETURN TIMESTAMP
        WITH LOCAL TIME ZONE IS
        l_discharge_date epis_hhc_req_status.dt_status%TYPE;
        tbl_status       table_varchar := table_varchar(pk_hhc_constant.k_hhc_req_status_closed);
    BEGIN
    
        l_discharge_date := get_hhc_dt_base(i_id_episode => i_id_episode,
                                            i_tbl_status => tbl_status,
                                            i_status     => pk_hhc_constant.k_hhc_req_status_closed);
    
        RETURN l_discharge_date;
    
    END get_hhc_dt_discharge;

    FUNCTION get_hhc_icon
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        i_id_patient IN patient.id_patient%TYPE
    ) RETURN VARCHAR2 IS
        l_icon VARCHAR2(50 CHAR);
        k_icon CONSTANT VARCHAR2(50 CHAR) := 'HomeHealthCareIcon';
        l_bool   BOOLEAN;
        l_status table_varchar := table_varchar(pk_hhc_constant.k_hhc_req_status_in_progress,
                                                pk_hhc_constant.k_hhc_req_status_approved,
                                                pk_hhc_constant.k_hhc_req_status_part_approved);
    BEGIN
    
        l_bool := check_patient_in_hhc(i_lang, i_prof, i_id_patient, l_status);
    
        IF l_bool
        THEN
            l_icon := k_icon;
        END IF;
    
        RETURN l_icon;
    
    END get_hhc_icon;

    FUNCTION get_hhc_professional
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_schedule IN schedule.id_schedule%TYPE
    ) RETURN VARCHAR2 IS
    
        l_professional VARCHAR2(4000);
        l_sep          VARCHAR2(0010 CHAR) := ',' || chr(32);
    
    BEGIN
    
        IF i_id_schedule IS NOT NULL
        THEN
            l_professional := pk_events.get_multi_name_signature(i_lang     => i_lang,
                                                                 i_prof     => i_prof,
                                                                 i_schedule => i_id_schedule,
                                                                 i_sep      => l_sep);
        END IF;
    
        RETURN l_professional;
    
    END get_hhc_professional;

    FUNCTION get_hhc_message
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        i_id_patient IN patient.id_patient%TYPE
    ) RETURN VARCHAR2 IS
        l_msg VARCHAR2(1000 CHAR);
        k_msg CONSTANT VARCHAR2(50 CHAR) := 'HEADER_M034';
        l_bool   BOOLEAN;
        l_status table_varchar := table_varchar(pk_hhc_constant.k_hhc_req_status_in_progress,
                                                pk_hhc_constant.k_hhc_req_status_approved,
                                                pk_hhc_constant.k_hhc_req_status_part_approved);
    BEGIN
    
        l_bool := check_patient_in_hhc(i_lang, i_prof, i_id_patient, l_status);
    
        IF l_bool
        THEN
            l_msg := pk_message.get_message(i_lang, i_prof, k_msg);
        END IF;
    
        RETURN l_msg;
    
    END get_hhc_message;

    FUNCTION get_home_care_shortcut
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        i_id_patient IN patient.id_patient%TYPE
    ) RETURN VARCHAR IS
        l_ret      table_number;
        k_shortcut VARCHAR2(050) := 'HOMECARE';
        l_screens  table_varchar := table_varchar(k_shortcut);
        l_error    t_error_out;
    
        l_bool   BOOLEAN;
        l_return VARCHAR2(4000);
        l_status table_varchar := table_varchar(pk_hhc_constant.k_hhc_req_status_in_progress,
                                                pk_hhc_constant.k_hhc_req_status_approved,
                                                pk_hhc_constant.k_hhc_req_status_part_approved);
    BEGIN
    
        l_bool := check_patient_in_hhc(i_lang, i_prof, i_id_patient, l_status);
        IF l_bool
        THEN
        
            l_bool := pk_access.preload_shortcuts(i_lang    => i_lang,
                                                  i_prof    => i_prof,
                                                  i_screens => l_screens,
                                                  o_error   => l_error);
        
            IF l_bool
            THEN
                l_return := pk_access.get_shortcut(k_shortcut);
            END IF;
        END IF;
    
        RETURN l_return;
    
    END get_home_care_shortcut;

    FUNCTION get_active_info
    (
        i_patient IN NUMBER,
        i_field   IN VARCHAR2
    ) RETURN NUMBER IS
        tbl_num  table_number;
        l_return NUMBER;
    BEGIN
    
        SELECT CASE i_field
                   WHEN 'ID_EPISODE' THEN
                    e.id_episode
                   WHEN 'ID_EPIS_HHC_REQ' THEN
                    hr.id_epis_hhc_req
                   ELSE
                    NULL
               END CASE
          BULK COLLECT
          INTO tbl_num
          FROM episode e
          JOIN visit v
            ON v.id_visit = e.id_visit
          JOIN epis_hhc_req hr
            ON hr.id_epis_hhc = e.id_episode
         WHERE e.id_epis_type = pk_hhc_constant.k_hhc_epis_type
           AND v.id_patient = i_patient
           AND hr.flg_status NOT IN (pk_hhc_constant.k_hhc_req_status_canceled,
                                     pk_hhc_constant.k_hhc_req_status_discontinued,
                                     pk_hhc_constant.k_hhc_req_status_closed,
                                     pk_hhc_constant.k_hhc_req_status_rejected);
    
        IF tbl_num.count > 0
        THEN
            l_return := tbl_num(1);
        END IF;
    
        RETURN l_return;
    
    END get_active_info;

    FUNCTION get_active_hhc_episode(i_patient IN NUMBER) RETURN NUMBER IS
        --tbl_num  table_number;
        l_return NUMBER;
    BEGIN
    
        l_return := get_active_info(i_patient => i_patient, i_field => 'ID_EPISODE');
    
        RETURN l_return;
    
    END get_active_hhc_episode;

    FUNCTION get_active_hhc_request(i_patient IN NUMBER) RETURN NUMBER IS
        --tbl_num  table_number;
        l_return NUMBER;
    BEGIN
    
        l_return := get_active_info(i_patient => i_patient, i_field => 'ID_EPIS_HHC_REQ');
    
        RETURN l_return;
    
    END get_active_hhc_request;

    FUNCTION set_status_base
    (
        i_lang                IN NUMBER,
        i_prof                IN profissional,
        i_id_epis_hhc_req     IN epis_hhc_req.id_epis_hhc_req%TYPE,
        i_flg_status          IN epis_hhc_req.flg_status%TYPE,
        i_id_prof_manager     IN epis_hhc_req.id_prof_manager%TYPE,
        i_dt_prof_manager     IN epis_hhc_req.dt_prof_manager%TYPE,
        i_prof_null           IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        i_id_prof_coordinator IN epis_hhc_req.id_prof_coordinator%TYPE,
        i_id_cancel_reason    IN epis_hhc_req.id_cancel_reason%TYPE,
        i_cancel_notes        IN epis_hhc_req.cancel_notes%TYPE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
        l_ret        BOOLEAN;
        l_new_status VARCHAR2(1 CHAR) := i_flg_status;
    BEGIN
    
        l_ret := pk_hhc_core.upd_epis_req(i_prof                => i_prof,
                                          i_id_epis_hhc_req     => i_id_epis_hhc_req,
                                          i_flg_status          => l_new_status,
                                          i_id_prof_manager     => i_id_prof_manager,
                                          i_dt_prof_manager     => i_dt_prof_manager,
                                          i_prof_null           => i_prof_null,
                                          i_id_prof_coordinator => i_id_prof_coordinator,
                                          i_id_cancel_reason    => i_id_cancel_reason,
                                          i_cancel_notes        => i_cancel_notes);
    
        l_ret := ins_req_status(i_id_epis_hhc_req, i_prof.id, l_new_status, i_id_cancel_reason, i_cancel_notes);
    
        RETURN l_ret;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'SET_STATUS_BASE',
                                              o_error);
            RETURN FALSE;
    END set_status_base;

    FUNCTION check_if_already_approved(i_id_epis_hhc_req IN epis_hhc_req.id_epis_hhc_req%TYPE) RETURN VARCHAR2 IS
        l_return VARCHAR2(0010 CHAR) := k_no;
        l_count  NUMBER;
    BEGIN
    
        SELECT COUNT(*)
          INTO l_count
          FROM epis_hhc_req
         WHERE id_epis_hhc_req = i_id_epis_hhc_req
           AND flg_status = pk_hhc_constant.k_hhc_req_status_in_progress;
    
        IF l_count > 0
        THEN
            l_return := k_yes;
        END IF;
    
        RETURN l_return;
    
    END check_if_already_approved;

    -- ***********************************
    FUNCTION set_status_in_progress
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_epis_hhc_req IN epis_hhc_req.id_epis_hhc_req%TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_ret        BOOLEAN := TRUE;
        l_new_status VARCHAR2(1 CHAR);
    BEGIN
    
        l_new_status := check_if_already_approved(i_id_epis_hhc_req => i_id_epis_hhc_req);
    
        IF l_new_status = k_no
        THEN
        
            l_new_status := pk_hhc_constant.k_hhc_req_status_in_progress;
        
            l_ret := set_status_base(i_lang                => i_lang,
                                     i_prof                => i_prof,
                                     i_id_epis_hhc_req     => i_id_epis_hhc_req,
                                     i_flg_status          => l_new_status,
                                     i_id_prof_manager     => NULL,
                                     i_dt_prof_manager     => NULL,
                                     i_prof_null           => k_no,
                                     i_id_prof_coordinator => i_prof.id,
                                     i_id_cancel_reason    => NULL,
                                     i_cancel_notes        => NULL,
                                     o_error               => o_error);
        
        END IF;
    
        RETURN l_ret;
    
    END set_status_in_progress;

    --**************************************************************
    FUNCTION check_all_schedule_pending(i_hhc_episode IN NUMBER) RETURN VARCHAR2 IS
        l_count       NUMBER;
        l_count_flg   NUMBER;
        l_return      VARCHAR2(0010 CHAR) := k_no;
        tbl_count     table_number;
        tbl_count_flg table_number;
    BEGIN
    
        SELECT SUM(rn), SUM(xcount)
          BULK COLLECT
          INTO tbl_count, tbl_count_flg
          FROM (SELECT 1 rn, decode(s.flg_status, pk_schedule.g_sched_status_pend_approval, 1, 0) xcount
                  FROM schedule s
                  JOIN epis_info ei
                    ON ei.id_schedule = s.id_schedule
                  JOIN episode e
                    ON e.id_episode = ei.id_episode
                  JOIN episode ee
                    ON ee.id_episode = e.id_prev_episode
                 WHERE ee.id_epis_type = pk_hhc_constant.k_hhc_epis_type
                   AND s.flg_status = pk_schedule.g_sched_status_cancelled
                   AND ee.id_episode = i_hhc_episode) xsql;
    
        IF tbl_count.count > 0
        THEN
        
            l_count     := tbl_count(1);
            l_count_flg := tbl_count_flg(1);
        
            IF l_count = l_count_flg
            THEN
                l_return := k_yes;
            END IF;
        
        END IF;
    
        RETURN l_return;
    
    END check_all_schedule_pending;

    FUNCTION get_team_profile_template
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_hhc_req IN epis_hhc_req.id_epis_hhc_req%TYPE
    ) RETURN table_number IS
        l_ret   table_number;
        l_team  NUMBER;
        l_error t_error_out;
    BEGIN
    
        IF NOT pk_prof_teams.get_id_prof_team(i_lang         => i_lang,
                                              i_prof         => i_prof,
                                              i_id_hhc_req   => i_id_hhc_req,
                                              o_id_prof_team => l_team,
                                              o_error        => l_error)
        THEN
            l_team := NULL;
        END IF;
    
        IF l_team IS NOT NULL
        THEN
            SELECT DISTINCT x.id_profile_template
              BULK COLLECT
              INTO l_ret
              FROM TABLE(pk_prof_teams.tf_get_team_det(i_lang => i_lang, i_prof => i_prof, i_prof_team => l_team)) x;
        END IF;
    
        RETURN l_ret;
    
    END get_team_profile_template;

    FUNCTION get_visit_status_icon
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_episode   IN episode.id_episode%TYPE,
        i_id_discharge IN discharge.id_discharge%TYPE
    ) RETURN VARCHAR2 IS
        l_icon VARCHAR2(50 CHAR);
        k_icon_check   CONSTANT VARCHAR2(50 CHAR) := 'CheckIcon';
        k_icon_pending CONSTANT VARCHAR2(50 CHAR) := 'PendingIcon';
        --l_bool BOOLEAN;
    
    BEGIN
    
        IF i_id_discharge IS NULL
        THEN
            l_icon := k_icon_pending;
        ELSE
            l_icon := k_icon_check;
        END IF;
    
        RETURN l_icon;
    
    END get_visit_status_icon;

    FUNCTION get_epis_discharge_list
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_epis_hhc_req IN epis_hhc_req.id_epis_hhc_req%TYPE,
        o_list            OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(24 CHAR) := 'GET_EPIS_DISCHARGE_LIST';
        --l_profile   table_number;
        l_epis_hhc  epis_hhc_req.id_epis_hhc%TYPE;
        l_has_notes sys_message.desc_message%TYPE := pk_message.get_message(i_lang, i_prof, 'COMMON_T055');
        k_icon_check CONSTANT VARCHAR2(50 CHAR) := 'CheckIcon';
        --k_icon_pending CONSTANT VARCHAR2(50 CHAR) := 'PendingIcon';
    BEGIN
    
        l_epis_hhc := get_id_epis_hhc_by_hhc_req(i_id_epis_hhc_req);
    
        OPEN o_list FOR
            SELECT id_episode,
                   id_discharge,
                   prof_category,
                   id_prof_med,
                   dt_discharge_str,
                   dt_discharge,
                   notes_med,
                   prof_name,
                   status_icon,
                   has_notes_str
              FROM (SELECT id_episode,
                           id_discharge,
                           pk_message.get_message(i_lang, pt.code_profile_template) prof_category,
                           id_prof_med,
                           dt_med_tstz,
                           pk_date_utils.date_send_tsz(i_lang, dt_med_tstz, i_prof) dt_discharge_str,
                           pk_date_utils.date_char_tsz(i_lang, dt_med_tstz, i_prof.institution, i_prof.software) dt_discharge,
                           notes_med,
                           pk_prof_utils.get_name_signature(i_lang, i_prof, id_prof_med) prof_name,
                           pk_hhc_core.get_visit_status_icon(i_lang, i_prof, id_episode, id_discharge) status_icon,
                           decode(notes_med, NULL, NULL, l_has_notes) has_notes_str
                      FROM (SELECT pl.profile_template,
                                   epis.id_episode,
                                   id_discharge,
                                   id_prof_med,
                                   dt_med_tstz,
                                   notes_med,
                                   id_profile_template,
                                   dt_target_tstz,
                                   row_number() over(PARTITION BY pl.profile_template ORDER BY dt_med_tstz DESC NULLS LAST, dt_target_tstz DESC) rn
                              FROM (SELECT /*+ opt_estimate(table p rows=1)  */
                                     column_value profile_template
                                      FROM TABLE(pk_hhc_core.get_team_profile_template(i_lang       => i_lang,
                                                                                       i_prof       => i_prof,
                                                                                       i_id_hhc_req => i_id_epis_hhc_req)) p
                                    UNION (SELECT ppt.id_profile_template
                                            FROM episode e
                                            JOIN epis_info ei
                                              ON e.id_episode = ei.id_episode
                                            JOIN schedule s
                                              ON ei.id_schedule = s.id_schedule
                                            JOIN sch_resource sr
                                              ON sr.id_schedule = s.id_schedule
                                            JOIN prof_profile_template ppt
                                              ON sr.id_institution = ppt.id_institution
                                             AND sr.id_professional = ppt.id_professional
                                             AND ppt.id_profile_template IN
                                                 (pk_hhc_constant.k_prof_templ_die,
                                                  pk_hhc_constant.k_prof_templ_nurse,
                                                  pk_hhc_constant.k_prof_templ_ot,
                                                  pk_hhc_constant.k_prof_templ_psy,
                                                  pk_hhc_constant.k_prof_templ_pt,
                                                  pk_hhc_constant.k_prof_templ_phy,
                                                  pk_hhc_constant.k_prof_templ_rt,
                                                  pk_hhc_constant.k_prof_templ_sw_h,
                                                  pk_hhc_constant.k_prof_templ_st)
                                           WHERE e.id_prev_episode = l_epis_hhc
                                             AND e.id_epis_type = pk_alert_constant.g_epis_type_home_health_care)) pl
                              LEFT JOIN (SELECT e.id_episode,
                                               d.id_discharge,
                                               d.id_prof_med,
                                               d.dt_med_tstz,
                                               d.notes_med,
                                               coalesce(ppt1.id_profile_template, ppt.id_profile_template) id_profile_template,
                                               so.dt_target_tstz
                                          FROM episode e
                                          JOIN epis_info ei
                                            ON e.id_episode = ei.id_episode
                                          JOIN schedule s
                                            ON ei.id_schedule = s.id_schedule
                                          JOIN schedule_outp so
                                            ON ei.id_schedule_outp = so.id_schedule_outp
                                          LEFT JOIN (SELECT d.id_episode,
                                                           d.id_discharge,
                                                           d.id_prof_med,
                                                           d.dt_med_tstz,
                                                           d.notes_med
                                                      FROM discharge d
                                                      JOIN discharge_detail dd
                                                        ON dd.id_discharge = d.id_discharge
                                                       AND dd.flg_type_closure = 'F'
                                                     WHERE d.flg_status = pk_discharge.g_disch_flg_status_active) d
                                            ON d.id_episode = e.id_episode
                                          JOIN sch_resource sr
                                            ON sr.id_schedule = s.id_schedule
                                          JOIN prof_profile_template ppt
                                            ON sr.id_institution = ppt.id_institution
                                           AND sr.id_professional = ppt.id_professional
                                           AND ppt.id_profile_template IN
                                               (pk_hhc_constant.k_prof_templ_die,
                                                pk_hhc_constant.k_prof_templ_nurse,
                                                pk_hhc_constant.k_prof_templ_ot,
                                                pk_hhc_constant.k_prof_templ_psy,
                                                pk_hhc_constant.k_prof_templ_pt,
                                                pk_hhc_constant.k_prof_templ_phy,
                                                pk_hhc_constant.k_prof_templ_rt,
                                                pk_hhc_constant.k_prof_templ_sw_h,
                                                pk_hhc_constant.k_prof_templ_st)
                                          LEFT JOIN prof_profile_template ppt1
                                            ON ppt1.id_institution = e.id_institution
                                           AND ppt1.id_professional = d.id_prof_med
                                           AND ppt1.id_profile_template IN
                                               (pk_hhc_constant.k_prof_templ_die,
                                                pk_hhc_constant.k_prof_templ_nurse,
                                                pk_hhc_constant.k_prof_templ_ot,
                                                pk_hhc_constant.k_prof_templ_psy,
                                                pk_hhc_constant.k_prof_templ_pt,
                                                pk_hhc_constant.k_prof_templ_phy,
                                                pk_hhc_constant.k_prof_templ_rt,
                                                pk_hhc_constant.k_prof_templ_sw_h,
                                                pk_hhc_constant.k_prof_templ_st)
                                         WHERE e.id_prev_episode = l_epis_hhc
                                           AND e.id_epis_type = pk_alert_constant.g_epis_type_home_health_care) epis
                                ON pl.profile_template = epis.id_profile_template) epis
                      JOIN profile_template pt
                        ON epis.profile_template = pt.id_profile_template
                     WHERE rn = 1)
             ORDER BY CASE
                          WHEN status_icon = k_icon_check THEN
                           2 -- check in 2nd position
                          ELSE
                           1 -- all other states before check
                      END,
                      dt_med_tstz DESC,
                      prof_category;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_list);
            RETURN FALSE;
    END get_epis_discharge_list;

    FUNCTION get_prof_team_det_hist
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_prof_team   IN prof_team.id_prof_team%TYPE,
        o_team_detail OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        k_max_number CONSTANT NUMBER := 999999999999;
        l_max_group    NUMBER;
        l_team         VARCHAR2(4000);
        l_team_members VARCHAR2(4000);
        l_line         VARCHAR2(4000);
        l_signature    VARCHAR2(4000);
    
        l_func_name     CONSTANT VARCHAR2(0100 CHAR) := 'get_prof_team_det_hist';
        k_flg_screen_l1 CONSTANT VARCHAR2(0100 CHAR) := pk_alert_constant.g_flg_screen_l1;
        k_flg_screen_l2 CONSTANT VARCHAR2(0100 CHAR) := pk_alert_constant.g_flg_screen_l2;
        k_flg_screen_wl CONSTANT VARCHAR2(0100 CHAR) := pk_alert_constant.g_flg_screen_wl;
    
        k_2_points CONSTANT VARCHAR2(0100 CHAR) := pk_alert_constant.g_two_points;
    
        --l_profile_row profile_template%ROWTYPE;
        --l_profile VARCHAR2(1000 CHAR);
    
        l_rec_screen_detail t_coll_screen_detail := t_coll_screen_detail();
    
        CURSOR hist_c(i_group IN NUMBER) IS
            SELECT xfinal.group_rn,
                   xfinal.id_prof_team_hist,
                   xfinal.id_prof_team,
                   xfinal.id_professional,
                   xfinal.id_prof_register,
                   xfinal.prof_name,
                   xfinal.signature,
                   xfinal.dt_register,
                   pk_hhc_core.get_profile_template(i_lang, xfinal.id_professional) category
              FROM (SELECT xsql.id_prof_team_hist,
                           xsql.id_prof_team,
                           xsql.id_professional,
                           xsql.id_prof_register,
                           xsql.dt_register,
                           dense_rank() over(PARTITION BY id_prof_team ORDER BY xsql.id_prof_team_hist DESC) group_rn,
                           pk_prof_utils.get_name(i_lang, xsql.id_professional) prof_name,
                           pk_hhc_core.get_prof_signature(i_lang         => i_lang,
                                                          i_prof         => i_prof,
                                                          i_id_prof_sign => xsql.id_prof_register,
                                                          i_date         => xsql.dt_register) signature
                      FROM (SELECT k_max_number id_prof_team_hist,
                                   x.id_prof_team,
                                   x.id_professional,
                                   pt.id_prof_register,
                                   pt.dt_register
                              FROM prof_team_det x
                              JOIN prof_team pt
                                ON pt.id_prof_team = x.id_prof_team
                             WHERE x.id_prof_team = i_prof_team
                            UNION ALL
                            SELECT ptdh.id_prof_team_hist,
                                   ptdh.id_prof_team,
                                   ptdh.id_professional,
                                   pth.id_prof_register,
                                   pth.dt_register
                              FROM prof_team_det_hist ptdh
                              JOIN prof_team_hist pth
                                ON pth.id_prof_team_hist = ptdh.id_prof_team_hist
                             WHERE ptdh.id_prof_team = i_prof_team) xsql) xfinal
             WHERE (xfinal.group_rn = i_group)
                OR (i_group IS NULL)
             ORDER BY xfinal.dt_register DESC, category;
    
        TYPE tbl_row_type IS TABLE OF hist_c%ROWTYPE;
        tbl_hist tbl_row_type;
    
        --********************************************************************
        PROCEDURE push_row
        (
            i_var1 IN VARCHAR2,
            i_var2 IN VARCHAR2,
            i_var3 IN VARCHAR2,
            i_var4 IN VARCHAR2
        ) IS
            l_idx NUMBER;
        BEGIN
        
            l_rec_screen_detail.extend;
            l_idx := l_rec_screen_detail.count;
        
            l_rec_screen_detail(l_idx) := t_rec_screen_detail(i_var1, i_var2, i_var3, i_var4);
        
        END push_row;
    
        --********************************************************************
        PROCEDURE set_signature
        (
            i_created IN BOOLEAN,
            i_user    IN VARCHAR2,
            i_date    IN TIMESTAMP WITH LOCAL TIME ZONE
        ) IS
            l_prefix VARCHAR2(1000 CHAR);
        BEGIN
            -- DETAIL_COMMON_M001 'COMMON_M156'
            IF i_created
            THEN
                l_prefix := 'DETAIL_COMMON_M001';
            ELSE
                l_prefix := 'COMMON_M156';
            END IF;
        
            l_prefix := pk_message.get_message(i_lang => i_lang, i_code_mess => l_prefix);
        
            IF l_signature IS NULL
            THEN
                l_signature := l_prefix || k_2_points || pk_hhc_core.get_prof_signature(i_lang, i_prof, i_user, i_date);
            END IF;
        
        END set_signature;
    
    BEGIN
    
        l_team         := pk_message.get_message(i_lang => i_lang, i_code_mess => 'PROF_TEAMS_M007');
        l_team_members := pk_message.get_message(i_lang => i_lang, i_code_mess => 'PROF_TEAMS_M040');
    
        OPEN hist_c(NULL);
        FETCH hist_c BULK COLLECT
            INTO tbl_hist;
        CLOSE hist_c;
    
        l_max_group := tbl_hist(tbl_hist.count).group_rn;
    
        <<lup_thru_group_rn>>
        FOR i IN 1 .. l_max_group
        LOOP
        
            l_signature := NULL;
        
            OPEN hist_c(i);
            FETCH hist_c BULK COLLECT
                INTO tbl_hist;
            CLOSE hist_c;
        
            push_row(l_team, '', k_flg_screen_l1, '');
            push_row(l_team_members, '', k_flg_screen_l2, '');
        
            <<lup_thru_rows>>
            FOR j IN 1 .. tbl_hist.count
            LOOP
            
                l_line := tbl_hist(j).category || k_2_points || tbl_hist(j).prof_name;
                push_row('', l_line, k_flg_screen_l2, '');
            
                set_signature((l_max_group = i), tbl_hist(j).id_prof_register, tbl_hist(j).dt_register);
            
            END LOOP lup_thru_rows;
            push_row('', l_signature, 'LP', '');
            push_row('', '', k_flg_screen_wl, '');
        
        END LOOP lup_thru_group_rn;
    
        g_error := 'PUT TEAM MEMBERS CURSOR';
        OPEN o_team_detail FOR
            SELECT descr, val, tipo AS TYPE
              FROM TABLE(l_rec_screen_detail);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
        
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => o_error);
        
            pk_types.open_my_cursor(o_team_detail);
            RETURN FALSE;
        
    END get_prof_team_det_hist;

    FUNCTION check_hhc_epis_discharge
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_epis_hhc_req IN epis_hhc_req.id_epis_hhc_req%TYPE
    ) RETURN VARCHAR2 IS
        l_func_name CONSTANT VARCHAR2(24 CHAR) := 'check_hhc_epis_discharge';
        l_epis_hhc epis_hhc_req.id_epis_hhc%TYPE;
        l_count    NUMBER;
        l_error    t_error_out;
    BEGIN
    
        l_epis_hhc := get_id_epis_hhc_by_hhc_req(i_id_epis_hhc_req);
    
        SELECT COUNT(1)
          INTO l_count
          FROM (SELECT pl.profile_template,
                       epis.id_episode,
                       id_discharge,
                       dt_med_tstz,
                       id_profile_template,
                       row_number() over(PARTITION BY pl.profile_template ORDER BY dt_med_tstz DESC NULLS LAST, dt_target_tstz DESC) rn
                  FROM (SELECT /*+ opt_estimate(table p rows=1)  */
                         column_value profile_template
                          FROM TABLE(pk_hhc_core.get_team_profile_template(i_lang       => i_lang,
                                                                           i_prof       => i_prof,
                                                                           i_id_hhc_req => i_id_epis_hhc_req)) p) pl
                  JOIN (SELECT e.id_episode,
                              d.id_discharge,
                              d.id_prof_med,
                              d.dt_med_tstz,
                              d.notes_med,
                              coalesce(ppt1.id_profile_template, ppt.id_profile_template) id_profile_template,
                              so.dt_target_tstz
                         FROM episode e
                         JOIN epis_info ei
                           ON e.id_episode = ei.id_episode
                         JOIN schedule s
                           ON ei.id_schedule = s.id_schedule
                         JOIN schedule_outp so
                           ON ei.id_schedule_outp = so.id_schedule_outp
                         LEFT JOIN (SELECT d.id_episode, d.id_discharge, d.id_prof_med, d.dt_med_tstz, d.notes_med
                                     FROM discharge d
                                     JOIN discharge_detail dd
                                       ON dd.id_discharge = d.id_discharge
                                      AND dd.flg_type_closure = 'F'
                                    WHERE d.flg_status = pk_discharge.g_disch_flg_status_active) d
                           ON d.id_episode = e.id_episode
                         JOIN sch_resource sr
                           ON sr.id_schedule = s.id_schedule
                         JOIN prof_profile_template ppt
                           ON sr.id_institution = ppt.id_institution
                          AND sr.id_professional = ppt.id_professional
                         LEFT JOIN prof_profile_template ppt1
                           ON ppt1.id_institution = e.id_institution
                          AND ppt1.id_professional = d.id_prof_med
                        WHERE e.id_prev_episode = l_epis_hhc
                          AND e.id_epis_type = pk_alert_constant.g_epis_type_home_health_care) epis
                    ON pl.profile_template = epis.id_profile_template) epis
          JOIN profile_template pt
            ON epis.profile_template = pt.id_profile_template
         WHERE rn = 1
           AND id_discharge IS NULL;
    
        IF l_count > 0
        THEN
            RETURN pk_alert_constant.g_no;
        ELSE
            RETURN pk_alert_constant.g_yes;
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => l_error);
            RETURN pk_alert_constant.g_no;
    END check_hhc_epis_discharge;

    FUNCTION check_epis_discharge
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_epis_hhc_req IN epis_hhc_req.id_epis_hhc_req%TYPE,
        o_flg_show        OUT VARCHAR2,
        o_list            OUT table_varchar,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(24 CHAR) := 'CHECK_EPIS_DISCHARGE';
        --l_profile  table_number;
        l_epis_hhc epis_hhc_req.id_epis_hhc%TYPE;
        l_ret      VARCHAR2(1 CHAR);
    BEGIN
    
        l_epis_hhc := get_id_epis_hhc_by_hhc_req(i_id_epis_hhc_req);
    
        l_ret := pk_hhc_core.check_hhc_epis_discharge(i_lang, i_prof, i_id_epis_hhc_req);
    
        IF l_ret = pk_alert_constant.g_no
        THEN
            o_flg_show := pk_alert_constant.g_yes;
        ELSE
            o_flg_show := pk_alert_constant.g_no;
        END IF;
    
        SELECT pk_message.get_message(i_lang, pt.code_profile_template) prof_category
          BULK COLLECT
          INTO o_list
          FROM (SELECT pl.profile_template,
                       epis.id_episode,
                       id_discharge,
                       dt_med_tstz,
                       id_profile_template,
                       row_number() over(PARTITION BY pl.profile_template ORDER BY dt_med_tstz DESC NULLS LAST) rn
                  FROM (SELECT /*+ opt_estimate(table p rows=1)  */
                         column_value profile_template
                          FROM TABLE(pk_hhc_core.get_team_profile_template(i_lang       => i_lang,
                                                                           i_prof       => i_prof,
                                                                           i_id_hhc_req => i_id_epis_hhc_req)) p) pl
                  JOIN (SELECT e.id_episode,
                              d.id_discharge,
                              d.id_prof_med,
                              d.dt_med_tstz,
                              d.notes_med,
                              coalesce(ppt1.id_profile_template, ppt.id_profile_template) id_profile_template,
                              so.dt_target_tstz
                         FROM episode e
                         JOIN epis_info ei
                           ON e.id_episode = ei.id_episode
                         JOIN schedule s
                           ON ei.id_schedule = s.id_schedule
                         JOIN schedule_outp so
                           ON ei.id_schedule_outp = so.id_schedule_outp
                         LEFT JOIN (SELECT d.id_episode, d.id_discharge, d.id_prof_med, d.dt_med_tstz, d.notes_med
                                     FROM discharge d
                                     JOIN discharge_detail dd
                                       ON dd.id_discharge = d.id_discharge
                                      AND dd.flg_type_closure = 'F'
                                    WHERE d.flg_status = pk_discharge.g_disch_flg_status_active) d
                           ON d.id_episode = e.id_episode
                         JOIN sch_resource sr
                           ON sr.id_schedule = s.id_schedule
                         JOIN prof_profile_template ppt
                           ON sr.id_institution = ppt.id_institution
                          AND sr.id_professional = ppt.id_professional
                         LEFT JOIN prof_profile_template ppt1
                           ON ppt1.id_institution = e.id_institution
                          AND ppt1.id_professional = d.id_prof_med
                        WHERE e.id_prev_episode = l_epis_hhc
                          AND e.id_epis_type = pk_alert_constant.g_epis_type_home_health_care) epis
                    ON pl.profile_template = epis.id_profile_template) epis
          JOIN profile_template pt
            ON epis.profile_template = pt.id_profile_template
         WHERE rn = 1
           AND id_discharge IS NULL
         ORDER BY 1;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            RETURN FALSE;
    END check_epis_discharge;

    FUNCTION tf_hhc_next_schedules
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_epis_hhc_req IN epis_hhc_req.id_epis_hhc_req%TYPE,
        i_dt_schedule     IN schedule.dt_begin_tstz%TYPE
    ) RETURN table_number IS
        l_func_name CONSTANT VARCHAR2(24 CHAR) := 'tf_hhc_next_schedules';
        --l_profile   table_number;
        l_epis_hhc  epis_hhc_req.id_epis_hhc%TYPE;
        l_schedules table_number;
        l_error     t_error_out;
        k_no_show CONSTANT VARCHAR2(0010 CHAR) := 'B';
    BEGIN
    
        l_epis_hhc := get_id_epis_hhc_by_hhc_req(i_id_epis_hhc_req);
    
        SELECT s.id_schedule
          BULK COLLECT
          INTO l_schedules
          FROM episode e
          JOIN epis_info ei
            ON e.id_episode = ei.id_episode
          JOIN schedule s
            ON ei.id_schedule = s.id_schedule
          JOIN schedule_outp so
            ON ei.id_schedule_outp = so.id_schedule_outp
         WHERE e.id_prev_episode = l_epis_hhc
           AND e.id_epis_type = pk_alert_constant.g_epis_type_home_health_care
           AND e.flg_ehr = pk_alert_constant.g_epis_ehr_schedule
           AND so.flg_state != k_no_show
           AND s.dt_begin_tstz > i_dt_schedule
           AND e.flg_status != pk_alert_constant.g_epis_status_cancel;
    
        RETURN l_schedules;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => l_error);
    END tf_hhc_next_schedules;

    FUNCTION check_has_next_schedules
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_epis_hhc_req IN epis_hhc_req.id_epis_hhc_req%TYPE,
        o_flg_show        OUT VARCHAR2,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(24 CHAR) := 'CHECK_HAS_NEXT_SCHEDULES';
        l_schedules table_number;
    BEGIN
        o_flg_show  := pk_alert_constant.g_no;
        l_schedules := tf_hhc_next_schedules(i_lang, i_prof, i_id_epis_hhc_req, current_timestamp);
    
        IF l_schedules.count > 0
        THEN
            o_flg_show := pk_alert_constant.g_yes;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            RETURN FALSE;
    END check_has_next_schedules;

    FUNCTION get_summary_page_sections_hhc
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_summary_page IN summary_page.id_summary_page%TYPE,
        i_pat             IN patient.id_patient%TYPE,
        i_episode         IN episode.id_episode%TYPE,
        o_sections        OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_active_epis_hhc_req NUMBER;
        l_flg_status          VARCHAR2(0010 CHAR);
        --c_sections            pk_types.cursor_type;
        l_tbl_section    t_coll_sections;
        l_rec_section    t_rec_sections;
        l_count_epis_doc NUMBER;
    
        l_age              patient.age%TYPE;
        l_gender           patient.gender%TYPE;
        l_profile_template profile_template.id_profile_template%TYPE;
        l_market           market.id_market%TYPE;
        l_is_coordinator   VARCHAR2(2);
    
        l_func_name CONSTANT VARCHAR2(29 CHAR) := 'get_summary_page_sections_hhc';
        l_exception EXCEPTION;
    
    BEGIN
    
        g_error := 'AGE AND GENDER CHECK';
        SELECT p.gender, nvl(p.age, trunc(months_between(SYSDATE, p.dt_birth) / 12, 0)) age_in_years
          INTO l_gender, l_age
          FROM patient p
         WHERE p.id_patient = i_pat;
    
        l_profile_template := pk_prof_utils.get_prof_profile_template(i_prof);
        l_market           := pk_core.get_inst_mkt(i_id_institution => i_prof.institution);
        l_is_coordinator   := pk_prof_utils.check_has_functionality(i_lang        => i_lang,
                                                                    i_prof        => i_prof,
                                                                    i_intern_name => 'HHC_COORDINATOR');
    
        -- get the current active request
        l_active_epis_hhc_req := get_active_hhc_request(i_patient => i_pat);
    
        -- get the status of the current patient hhc_request
        l_flg_status := get_flg_status(i_id_epis_hhc_req => l_active_epis_hhc_req);
    
        l_tbl_section := pk_summary_page.tf_sections(i_lang             => i_lang,
                                                     i_prof             => i_prof,
                                                     i_market           => l_market,
                                                     i_gender           => l_gender,
                                                     i_age              => l_age,
                                                     i_profile_template => l_profile_template,
                                                     i_id_summary_page  => i_id_summary_page,
                                                     i_doc_areas_ex     => NULL,
                                                     i_doc_areas_in     => NULL);
    
        IF l_tbl_section IS NOT NULL
           AND l_tbl_section.count > 0
        THEN
            g_error := 'RUN THROUGH ALL SECTIONS';
            pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
            FOR i IN l_tbl_section.first .. l_tbl_section.last
            LOOP
            
                l_rec_section := l_tbl_section(i);
            
                --only a coordinator can write
                IF l_is_coordinator = k_yes
                THEN
                    -- in case the request is not in the desired states nothing can be done
                    IF l_flg_status NOT IN (k_hhc_part_approved, k_hhc_in_part_acc_wcm, k_hhc_in_evaluation)
                    THEN
                        l_rec_section.flg_write := pk_alert_constant.g_no;
                    ELSE
                        -- see if there already records
                        SELECT COUNT(*)
                          INTO l_count_epis_doc
                          FROM epis_documentation e
                         WHERE e.id_doc_area = l_rec_section.doc_area
                           AND e.id_episode = i_episode
                           AND e.flg_status = pk_alert_constant.g_active;
                    
                        IF l_count_epis_doc > 0
                        THEN
                            l_rec_section.flg_create := pk_alert_constant.g_no;
                        ELSE
                            l_rec_section.flg_create := pk_alert_constant.g_yes;
                        END IF;
                    END IF;
                ELSE
                    l_rec_section.flg_write := pk_alert_constant.g_no;
                END IF;
                l_tbl_section(i) := l_rec_section;
            END LOOP;
        END IF;
    
        OPEN o_sections FOR
            SELECT *
              FROM TABLE(l_tbl_section);
    
        RETURN TRUE;
    
    END get_summary_page_sections_hhc;

    FUNCTION set_status_close
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_epis_hhc_req IN epis_hhc_req.id_epis_hhc_req%TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_ret        BOOLEAN := TRUE;
        l_new_status VARCHAR2(1 CHAR);
    BEGIN
    
        l_new_status := pk_hhc_constant.k_hhc_req_status_closed;
    
        l_ret := set_status_base(i_lang                => i_lang,
                                 i_prof                => i_prof,
                                 i_id_epis_hhc_req     => i_id_epis_hhc_req,
                                 i_flg_status          => l_new_status,
                                 i_id_prof_manager     => NULL,
                                 i_dt_prof_manager     => NULL,
                                 i_prof_null           => k_no,
                                 i_id_prof_coordinator => i_prof.id,
                                 i_id_cancel_reason    => NULL,
                                 i_cancel_notes        => NULL,
                                 o_error               => o_error);
    
        RETURN l_ret;
    
    END set_status_close;

    FUNCTION get_visit_information
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_epis_hhc_req IN epis_hhc_req.id_epis_hhc_req%TYPE,
        o_first_dt        OUT schedule_outp.dt_target_tstz%TYPE,
        o_last_dt         OUT schedule_outp.dt_target_tstz%TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(24 CHAR) := 'GET_EPIS_DISCHARGE_LIST';
        --l_profile   table_number;
        l_epis_hhc epis_hhc_req.id_epis_hhc%TYPE;
        --l_has_notes sys_message.desc_message%TYPE := pk_message.get_message(i_lang, i_prof, 'COMMON_T055');
    
    BEGIN
    
        l_epis_hhc := get_id_epis_hhc_by_hhc_req(i_id_epis_hhc_req);
    
        SELECT first_dt, last_dt
          INTO o_first_dt, o_last_dt
          FROM (SELECT first_value(so.dt_target_tstz) over(ORDER BY so.dt_target_tstz) first_dt,
                       last_value(so.dt_target_tstz) over(ORDER BY so.dt_target_tstz DESC) last_dt,
                       row_number() over(ORDER BY so.dt_target_tstz DESC) rn
                  FROM episode e
                  JOIN epis_info ei
                    ON e.id_episode = ei.id_episode
                  JOIN schedule s
                    ON ei.id_schedule = s.id_schedule
                  JOIN schedule_outp so
                    ON ei.id_schedule_outp = so.id_schedule_outp
                 WHERE e.id_prev_episode = l_epis_hhc
                   AND e.id_epis_type = pk_alert_constant.g_epis_type_home_health_care
                   AND e.flg_ehr = pk_alert_constant.g_epis_ehr_normal
                   AND e.flg_status <> pk_alert_constant.g_epis_status_cancel) epis
         WHERE rn = 1;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN no_data_found THEN
            RETURN TRUE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            RETURN FALSE;
    END get_visit_information;

    FUNCTION check_team_has_schedules
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_tbl_inst        IN table_number,
        i_id_epis_hhc_req IN epis_hhc_req.id_epis_hhc_req%TYPE
    ) RETURN VARCHAR2 IS
    
        l_professional table_number;
        l_list_sched   table_number;
        l_epis_hhc     epis_hhc_req.id_epis_hhc%TYPE;
    
        l_ret VARCHAR2(1 CHAR) := pk_alert_constant.g_no;
    
    BEGIN
    
        l_epis_hhc := get_id_epis_hhc_by_hhc_req(i_id_epis_hhc_req);
    
        l_professional := get_team_id_professional(i_lang       => i_lang,
                                                   i_prof       => i_prof,
                                                   i_tbl_inst   => i_tbl_inst,
                                                   i_id_hhc_req => i_id_epis_hhc_req);
        SELECT id_professional
          BULK COLLECT
          INTO l_list_sched
          FROM (SELECT sr.id_professional,
                       row_number() over(PARTITION BY sr.id_professional ORDER BY sr.id_professional) rn
                  FROM episode e
                  JOIN epis_info ei
                    ON e.id_episode = ei.id_episode
                  JOIN schedule s
                    ON ei.id_schedule = s.id_schedule
                  JOIN sch_resource sr
                    ON sr.id_schedule = s.id_schedule
                 WHERE e.id_prev_episode = l_epis_hhc
                   AND e.id_epis_type = pk_alert_constant.g_epis_type_home_health_care
                   AND s.flg_status NOT IN (pk_schedule.g_flg_status_sched_c, pk_schedule.g_sched_status_pend_approval)
                   AND sr.id_professional IN (SELECT /*+ opt_estimate(table p rows=1)  */
                                               column_value profile_template
                                                FROM TABLE(l_professional) p)) epis
         WHERE rn = 1;
    
        IF l_list_sched.count = l_professional.count
        THEN
            l_ret := pk_alert_constant.g_yes;
        END IF;
    
        RETURN l_ret;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN l_ret;
    END check_team_has_schedules;

    FUNCTION get_list_prof_cat
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_schedule IN sch_resource.id_schedule%TYPE,
        i_flg_action  IN VARCHAR2
    ) RETURN VARCHAR2 IS
        l_result          VARCHAR2(4000);
        l_visit_perfor_by sys_message.code_message%TYPE := 'COMMON_T057';
    BEGIN
    
        SELECT CASE
                   WHEN i_flg_action = pk_alert_constant.g_flg_action_d THEN
                    listagg(prof_name || ' (' || cat || ')' || chr(13)) within GROUP(ORDER BY cat)
                   ELSE
                    pk_message.get_message(i_lang, l_visit_perfor_by) || listagg(cat, ', ') within GROUP(ORDER BY cat)
               END
          INTO l_result
          FROM (SELECT DISTINCT ppt.id_professional,
                                pk_prof_utils.get_name(i_lang, ppt.id_professional) prof_name,
                                pt.id_profile_template,
                                pk_message.get_message(i_lang, pt.code_profile_template) cat
                  FROM sch_resource sr
                  JOIN prof_profile_template ppt
                    ON sr.id_professional = ppt.id_professional
                  JOIN profile_template pt
                    ON ppt.id_profile_template = pt.id_profile_template
                 WHERE sr.id_schedule = i_id_schedule
                   AND ppt.id_profile_template IN (pk_hhc_constant.k_prof_templ_die,
                                                   pk_hhc_constant.k_prof_templ_nurse,
                                                   pk_hhc_constant.k_prof_templ_ot,
                                                   pk_hhc_constant.k_prof_templ_psy,
                                                   pk_hhc_constant.k_prof_templ_pt,
                                                   pk_hhc_constant.k_prof_templ_phy,
                                                   pk_hhc_constant.k_prof_templ_rt,
                                                   pk_hhc_constant.k_prof_templ_sw_h,
                                                   pk_hhc_constant.k_prof_templ_st)
                   AND ppt.id_institution = i_prof.institution);
        RETURN l_result;
    END get_list_prof_cat;

    -- this FUNCTION is used IN plan screen
    FUNCTION get_prof_can_cancel
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_hhc_req     IN epis_hhc_req.id_epis_hhc_req%TYPE,
        o_flg_can_cancel OUT VARCHAR2,
        o_error          OUT t_error_out
        
    ) RETURN BOOLEAN IS
        l_id_epis_hhc     epis_hhc_req.id_epis_hhc%TYPE;
        l_id_case_manager epis_hhc_req.id_prof_manager%TYPE;
        l_flg_status      epis_hhc_req.flg_status%TYPE;
        l_func_name       VARCHAR2(20) := 'get_prof_can_cancel';
    BEGIN
        l_id_epis_hhc := get_id_epis_hhc_by_hhc_req(i_id_hhc_req => i_id_hhc_req);
    
        l_flg_status := pk_hhc_core.get_epis_hhc_status(i_lang            => i_lang,
                                                        i_prof            => i_prof,
                                                        i_id_epis_hhc_req => i_id_hhc_req);
    
        l_id_case_manager := get_id_case_manager(i_epis_hhc => l_id_epis_hhc);
    
        IF i_prof.id = l_id_case_manager
           AND l_flg_status IN (k_hhc_part_approved, k_hhc_in_evaluation)
        THEN
            o_flg_can_cancel := pk_alert_constant.g_yes;
        ELSE
            o_flg_can_cancel := pk_alert_constant.g_no;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            RETURN FALSE;
    END get_prof_can_cancel;

    FUNCTION check_approved_request(i_patient IN NUMBER) RETURN VARCHAR2 IS
        tbl_num  table_number;
        l_return VARCHAR2(2 CHAR) := pk_alert_constant.g_no;
    BEGIN
    
        SELECT hr.id_epis_hhc_req
          BULK COLLECT
          INTO tbl_num
          FROM episode e
          JOIN epis_hhc_req hr
            ON hr.id_epis_hhc = e.id_episode
         WHERE e.id_epis_type = pk_hhc_constant.k_hhc_epis_type
           AND e.id_patient = i_patient
           AND hr.flg_status IN
               (pk_hhc_constant.k_hhc_req_status_approved, pk_hhc_constant.k_hhc_req_status_in_progress);
    
        IF tbl_num.count > 0
        THEN
            l_return := pk_alert_constant.g_yes;
        END IF;
    
        RETURN l_return;
    
    END check_approved_request;

    FUNCTION get_profile_template
    (
        i_lang    IN language.id_language%TYPE,
        i_id_prof IN NUMBER
    ) RETURN VARCHAR2 IS
        tbl_profile table_varchar;
        l_profile   VARCHAR2(1000 CHAR);
    BEGIN
    
        SELECT pk_message.get_message(i_lang, pt.code_profile_template) cat
          BULK COLLECT
          INTO tbl_profile
          FROM prof_profile_template ppt
          JOIN profile_template pt
            ON ppt.id_profile_template = pt.id_profile_template
         WHERE ppt.id_professional = i_id_prof
           AND ppt.id_profile_template IN (pk_hhc_constant.k_prof_templ_die,
                                           pk_hhc_constant.k_prof_templ_nurse,
                                           pk_hhc_constant.k_prof_templ_ot,
                                           pk_hhc_constant.k_prof_templ_psy,
                                           pk_hhc_constant.k_prof_templ_pt,
                                           pk_hhc_constant.k_prof_templ_phy,
                                           pk_hhc_constant.k_prof_templ_rt,
                                           pk_hhc_constant.k_prof_templ_sw_h,
                                           pk_hhc_constant.k_prof_templ_st);
    
        IF tbl_profile.count > 0
        THEN
            l_profile := tbl_profile(1);
        END IF;
    
        RETURN l_profile;
    
    END get_profile_template;

    FUNCTION get_prof_list
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_schedule IN schedule.id_schedule%TYPE,
        i_prof_cat IN category.flg_type%TYPE
    ) RETURN NUMBER IS
        l_professional table_number;
        l_prof_id      NUMBER;
    BEGIN
    
        IF i_schedule IS NOT NULL
        THEN
        
            SELECT sr.id_professional
              BULK COLLECT
              INTO l_professional
              FROM sch_resource sr
              JOIN professional p
                ON sr.id_professional = p.id_professional
              JOIN prof_profile_template ppt
                ON p.id_professional = ppt.id_professional
              JOIN profile_template pt
                ON ppt.id_profile_template = pt.id_profile_template
             WHERE sr.id_schedule = i_schedule
               AND ppt.id_institution = i_prof.institution
               AND pt.flg_type = i_prof_cat
               AND ppt.id_profile_template IN (pk_hhc_constant.k_prof_templ_die,
                                               pk_hhc_constant.k_prof_templ_nurse,
                                               pk_hhc_constant.k_prof_templ_ot,
                                               pk_hhc_constant.k_prof_templ_psy,
                                               pk_hhc_constant.k_prof_templ_pt,
                                               pk_hhc_constant.k_prof_templ_pt_c,
                                               pk_hhc_constant.k_prof_templ_phy,
                                               pk_hhc_constant.k_prof_templ_rt,
                                               pk_hhc_constant.k_prof_templ_sw_h,
                                               pk_hhc_constant.k_prof_templ_st);
        
        END IF;
        IF l_professional.count > 0
        THEN
            l_prof_id := l_professional(1);
        END IF;
        RETURN l_prof_id;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_prof_list;

    --***************************************
    FUNCTION get_comp_name_from_mkt(i_ds_cmp_mkt_rel IN NUMBER) RETURN VARCHAR2 IS
        tbl_name table_varchar;
        l_name   VARCHAR2(4000);
    BEGIN
    
        SELECT cmr.internal_name_child
          BULK COLLECT
          INTO tbl_name
          FROM v_ds_cmpt_mkt_rel cmr
         WHERE cmr.id_ds_cmpt_mkt_rel = i_ds_cmp_mkt_rel;
    
        IF tbl_name.count > 0
        THEN
            l_name := tbl_name(1);
        END IF;
    
        RETURN l_name;
    
    END get_comp_name_from_mkt;

    --***************************************
    FUNCTION get_submit_values
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_episode        IN episode.id_episode%TYPE,
        i_patient        IN patient.id_patient%TYPE,
        i_root_name      IN VARCHAR2,
        i_curr_component IN NUMBER,
        i_tbl_mkt_rel    IN table_number,
        i_value          IN table_table_varchar,
        i_value_clob     IN table_clob,
        o_error          IN t_error_out
    ) RETURN t_tbl_ds_get_value IS
        tbl_cmpt_trl table_number := table_number(2615, 3353, 3352, 3354);
        tbl_return   t_tbl_ds_get_value := t_tbl_ds_get_value();
        l_comp_name  VARCHAR2(4000);
    BEGIN
    
        l_comp_name := get_comp_name_from_mkt(i_curr_component);
    
        CASE
            WHEN i_curr_component MEMBER OF tbl_cmpt_trl THEN
                tbl_return := submit_for_translations(i_lang           => i_lang,
                                                      i_prof           => i_prof,
                                                      i_episode        => i_episode,
                                                      i_patient        => i_patient,
                                                      i_root_name      => i_root_name,
                                                      i_curr_component => i_curr_component,
                                                      i_tbl_mkt_rel    => i_tbl_mkt_rel,
                                                      i_value          => i_value,
                                                      i_value_clob     => i_value_clob,
                                                      o_error          => o_error);
                --WHEN i_curr_component = k_ds_prof_in_charge_name THEN
            WHEN l_comp_name = k_ds_prof_internal_name THEN
                tbl_return := submit_prof_in_charge(i_lang           => i_lang,
                                                    i_prof           => i_prof,
                                                    i_episode        => i_episode,
                                                    i_patient        => i_patient,
                                                    i_root_name      => i_root_name,
                                                    i_curr_component => i_curr_component,
                                                    i_tbl_mkt_rel    => i_tbl_mkt_rel,
                                                    i_value          => i_value,
                                                    i_value_clob     => i_value_clob,
                                                    o_error          => o_error);
            ELSE
            
                tbl_return := tbl_return;
        END CASE;
    
        RETURN tbl_return;
    
    END get_submit_values;

    --*****************************************
    FUNCTION submit_prof_in_charge
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_episode        IN episode.id_episode%TYPE,
        i_patient        IN patient.id_patient%TYPE,
        i_root_name      IN VARCHAR2,
        i_curr_component IN NUMBER,
        i_tbl_mkt_rel    IN table_number,
        i_value          IN table_table_varchar,
        i_value_clob     IN table_clob,
        o_error          IN t_error_out
    ) RETURN t_tbl_ds_get_value IS
        l_bool     BOOLEAN;
        l_prof_id  NUMBER;
        l_curr_idx NUMBER;
        l_phone    VARCHAR2(1000 CHAR);
        tbl_return t_tbl_ds_get_value := t_tbl_ds_get_value();
        tbl_result t_tbl_ds_get_value := t_tbl_ds_get_value();
        --*****************************
        PROCEDURE init_rec(i IN NUMBER) IS
        BEGIN
            tbl_result(i) := t_rec_ds_get_value(id_ds_cmpt_mkt_rel => NULL,
                                                id_ds_component    => NULL,
                                                internal_name      => NULL,
                                                VALUE              => NULL,
                                                value_clob         => NULL,
                                                min_value          => NULL,
                                                max_value          => NULL,
                                                desc_value         => NULL,
                                                desc_clob          => NULL,
                                                id_unit_measure    => NULL,
                                                desc_unit_measure  => NULL,
                                                flg_validation     => NULL,
                                                err_msg            => NULL,
                                                flg_event_type     => NULL,
                                                flg_multi_status   => NULL,
                                                idx                => 1);
        
        END init_rec;
    
        --********************
        FUNCTION process_cell_phone
        (
            i_ds_comp IN NUMBER,
            i_value   IN VARCHAR2
        ) RETURN t_tbl_ds_get_value IS
            l_id NUMBER;
        BEGIN
        
            tbl_result.extend();
            l_id := tbl_result.count;
            init_rec(l_id);
            tbl_result(l_id).id_ds_cmpt_mkt_rel := i_ds_comp;
        
            SELECT id_ds_component_child, internal_name_child
              INTO tbl_result(l_id).id_ds_component,tbl_result(l_id).internal_name
              FROM ds_cmpt_mkt_rel
             WHERE id_ds_cmpt_mkt_rel = i_ds_comp;
        
            tbl_result(l_id).value := i_value;
            tbl_result(l_id).value_clob := NULL;
            tbl_result(l_id).desc_value := i_value;
            tbl_result(l_id).desc_clob := NULL;
            tbl_result(l_id).id_unit_measure := NULL;
            tbl_result(l_id).desc_unit_measure := NULL;
            tbl_result(l_id).flg_validation := 'Y';
            tbl_result(l_id).err_msg := NULL;
            tbl_result(l_id).flg_event_type := 'M';
        
            RETURN tbl_result;
        
        END process_cell_phone;
    
        --*************************************
        FUNCTION is_cell_phone_component(i_ds_cmpt_mkt_rel IN NUMBER) RETURN BOOLEAN IS
            k_id_ds_comp_cell_phone CONSTANT NUMBER := 1313;
            l_curr_id NUMBER := -9999;
            tbl_id    table_number;
        BEGIN
        
            SELECT id_ds_component_child
              BULK COLLECT
              INTO tbl_id
              FROM ds_cmpt_mkt_rel
             WHERE id_ds_cmpt_mkt_rel = i_ds_cmpt_mkt_rel;
        
            IF tbl_id.count > 0
            THEN
                l_curr_id := tbl_id(1);
            END IF;
        
            RETURN(l_curr_id = k_id_ds_comp_cell_phone);
        
        END is_cell_phone_component;
    
    BEGIN
    
        -- Get id of professional and coresponding cell phone
        l_curr_idx := get_idx(i_tbl_mkt_rel, i_curr_component);
        l_prof_id  := i_value(l_curr_idx) (1);
        l_phone    := get_prof_mphone(l_prof_id);
    
        -- get id_cmpt_mkt rel of cell_phone component
        <<lup_thru_components>>
        FOR i IN 1 .. i_tbl_mkt_rel.count
        LOOP
            -- validated earlier
            l_bool := is_cell_phone_component(i_tbl_mkt_rel(i));
            --l_bool := TRUE;
            IF l_bool
            THEN
                -- Assigned value to cell_phone field
                tbl_return := process_cell_phone(i_tbl_mkt_rel(i), l_phone);
                EXIT lup_thru_components;
            END IF;
        END LOOP lup_thru_components;
    
        RETURN tbl_return;
    
    END submit_prof_in_charge;

    FUNCTION submit_for_translations
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_episode        IN episode.id_episode%TYPE,
        i_patient        IN patient.id_patient%TYPE,
        i_root_name      IN VARCHAR2,
        i_curr_component IN NUMBER,
        i_tbl_mkt_rel    IN table_number,
        i_value          IN table_table_varchar,
        i_value_clob     IN table_clob,
        o_error          IN t_error_out
    ) RETURN t_tbl_ds_get_value IS
        l_curr_idx NUMBER;
        l_dest_id  NUMBER;
        --ii              PLS_INTEGER;
        l_id            NUMBER;
        l_idx           NUMBER;
        b_name_1_toggle BOOLEAN;
        b_name_2_toggle BOOLEAN;
        l_bool1         BOOLEAN;
        l_bool2         BOOLEAN;
        l_bool          BOOLEAN;
        l_process       BOOLEAN := FALSE;
        l_text          VARCHAR2(4000);
        l_new_text      VARCHAR2(4000);
    
        tbl_result t_tbl_ds_get_value := t_tbl_ds_get_value();
    
        tbl_cmpt_id_eng  table_number := table_number(2615, 3353);
        tbl_cmpt_id_arab table_number := table_number(3352, 3354);
    
        tbl_cmpt_grp1 table_number := table_number(2615, 3352, 3630);
        tbl_cmpt_grp2 table_number := table_number(3353, 3354, 3632);
    
        tbl_cmpt_toggle_id table_number := table_number(3630, 3632);
    
        --**************************************
        PROCEDURE process_toggles IS
            l_chk_idx NUMBER;
        BEGIN
        
            l_chk_idx       := get_idx(i_tbl_mkt_rel, tbl_cmpt_toggle_id(1));
            b_name_1_toggle := i_value(l_chk_idx) (1) = k_yes;
        
            l_chk_idx       := get_idx(i_tbl_mkt_rel, tbl_cmpt_toggle_id(2));
            b_name_2_toggle := i_value(l_chk_idx) (1) = k_yes;
        
        END process_toggles;
    
        --*****************************
        PROCEDURE init_rec(i IN NUMBER) IS
        BEGIN
            tbl_result(i) := t_rec_ds_get_value(id_ds_cmpt_mkt_rel => NULL,
                                                id_ds_component    => NULL,
                                                internal_name      => NULL,
                                                VALUE              => NULL,
                                                value_clob         => NULL,
                                                min_value          => NULL,
                                                max_value          => NULL,
                                                desc_value         => NULL,
                                                desc_clob          => NULL,
                                                id_unit_measure    => NULL,
                                                desc_unit_measure  => NULL,
                                                flg_validation     => NULL,
                                                err_msg            => NULL,
                                                flg_event_type     => NULL,
                                                flg_multi_status   => NULL,
                                                idx                => 1);
        
        END init_rec;
    
    BEGIN
    
        l_curr_idx := get_idx(i_tbl_mkt_rel, i_curr_component);
    
        l_bool1 := i_curr_component MEMBER OF tbl_cmpt_grp1;
        l_bool2 := i_curr_component MEMBER OF tbl_cmpt_grp2;
    
        -- curr_toggle
        process_toggles();
    
        -- if part of group 1 and toggle 1 = Yes
        l_bool := (b_name_1_toggle AND l_bool1);
        IF l_bool
        THEN
        
            -- if curr component is english
            l_bool1 := i_curr_component MEMBER OF tbl_cmpt_id_eng;
            l_text  := i_value(l_curr_idx) (1);
            IF l_bool1
            THEN
                l_new_text := pk_adt.get_trl_oci_arab(l_text);
                l_idx      := get_idx(tbl_cmpt_id_eng, i_curr_component);
                l_dest_id  := tbl_cmpt_id_arab(l_idx);
            
            ELSE
                l_new_text := pk_adt.get_trl_arab_oci(l_text);
                l_idx      := get_idx(tbl_cmpt_id_arab, i_curr_component);
                l_dest_id  := tbl_cmpt_id_eng(l_idx);
            
            END IF;
        
            l_process := TRUE;
        
        END IF;
    
        -- if part of group 2 and toggle 2 = Yes
        l_bool := (b_name_2_toggle AND l_bool2);
        IF l_bool
        THEN
        
            -- if curr component is english
            l_bool1 := i_curr_component MEMBER OF tbl_cmpt_id_eng;
            l_text  := i_value(l_curr_idx) (1);
            IF l_bool1
            THEN
                l_new_text := pk_adt.get_trl_oci_arab(l_text);
                l_idx      := get_idx(tbl_cmpt_id_eng, i_curr_component);
                l_dest_id  := tbl_cmpt_id_arab(l_idx);
            
            ELSE
                l_new_text := pk_adt.get_trl_arab_oci(l_text);
                l_idx      := get_idx(tbl_cmpt_id_arab, i_curr_component);
                l_dest_id  := tbl_cmpt_id_eng(l_idx);
            
            END IF;
        
            l_process := TRUE;
        
        END IF;
    
        -- if translated, process
        IF l_process
        THEN
        
            -- detect field that will contain translated text
            tbl_result.extend();
            l_id := tbl_result.count;
            init_rec(l_id);
            tbl_result(l_id).id_ds_cmpt_mkt_rel := l_dest_id;
        
            SELECT id_ds_component_child, internal_name_child
              INTO tbl_result(l_id).id_ds_component,tbl_result(l_id).internal_name
              FROM ds_cmpt_mkt_rel
             WHERE id_ds_cmpt_mkt_rel = l_dest_id;
        
            tbl_result(l_id).value := l_new_text;
            tbl_result(l_id).value_clob := NULL;
            tbl_result(l_id).desc_value := l_new_text;
            tbl_result(l_id).desc_clob := NULL;
            tbl_result(l_id).id_unit_measure := NULL;
            tbl_result(l_id).desc_unit_measure := NULL;
            tbl_result(l_id).flg_validation := 'Y';
            tbl_result(l_id).err_msg := NULL;
            tbl_result(l_id).flg_event_type := 'M';
        
        END IF;
    
        RETURN tbl_result;
    
    END submit_for_translations;

    -- get index of value inside array
    FUNCTION get_idx
    (
        i_array IN table_number,
        i_value IN NUMBER
    ) RETURN NUMBER IS
        l_return NUMBER := 0;
    BEGIN
    
        FOR i IN 1 .. i_array.count
        LOOP
        
            IF i_array(i) = i_value
            THEN
                l_return := i;
                EXIT;
            END IF;
        
        END LOOP;
    
        RETURN l_return;
    
    END get_idx;

BEGIN
    /* CAN'T TOUCH THIS */
    /* Who am I */
    pk_alertlog.who_am_i(owner => g_owner, name => g_package);
    /* Log init */
    pk_alertlog.log_init(object_name => g_package);

END pk_hhc_core;
/
