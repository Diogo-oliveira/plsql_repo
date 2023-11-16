/*-- Last Change Revision: $Rev: 2027409 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:42:08 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_organ_donor AS

    --
    -- PRIVATE TYPES AND SUBTYPES
    -- 

    SUBTYPE obj_name IS VARCHAR2(32 CHAR);
    SUBTYPE debug_msg IS VARCHAR2(200 CHAR);

    -- Organ/tissue rowtype structure
    TYPE organ_tissue_tc IS TABLE OF organ_tissue%ROWTYPE INDEX BY BINARY_INTEGER;

    --
    -- PRIVATE CONSTANTS
    -- 

    -- Package info
    c_package_owner CONSTANT obj_name := 'ALERT';
    c_package_name  CONSTANT obj_name := pk_alertlog.who_am_i();

    -- Death registry dynamic screen component names
    c_ds_contagious_diseases     CONSTANT ds_component.internal_name%TYPE := 'CONTAGIOUS_DISEASES';
    c_ds_able_don_organs         CONSTANT ds_component.internal_name%TYPE := 'DONATE_ORGANS';
    c_ds_reason_not_able_don_org CONSTANT ds_component.internal_name%TYPE := 'REASON_ORGAN';
    c_ds_able_don_tissues        CONSTANT ds_component.internal_name%TYPE := 'DONATE_TISSUE';
    c_ds_reason_not_able_don_tis CONSTANT ds_component.internal_name%TYPE := 'REASON_TISSUE';
    c_ds_will_consulted          CONSTANT ds_component.internal_name%TYPE := 'DONOR_REGISTRY';
    c_ds_will_result             CONSTANT ds_component.internal_name%TYPE := 'RESULT';
    c_ds_reason_will_not_cons    CONSTANT ds_component.internal_name%TYPE := 'REASON_DONAR';
    c_ds_other_declaration       CONSTANT ds_component.internal_name%TYPE := 'OTHER_DECLARATION';
    c_ds_other_declaration_notes CONSTANT ds_component.internal_name%TYPE := 'NOTES';
    c_ds_don_authorized          CONSTANT ds_component.internal_name%TYPE := 'DONATION_AUTHORIZED';
    c_ds_responsible_name        CONSTANT ds_component.internal_name%TYPE := 'NAME_AUTHORIZED';
    c_ds_family_relationship     CONSTANT ds_component.internal_name%TYPE := 'RELATION_DECEASED';
    c_ds_reason_not_authorized   CONSTANT ds_component.internal_name%TYPE := 'REASON_AUTHORIZED';
    c_ds_donation_approved       CONSTANT ds_component.internal_name%TYPE := 'DONATION_APPROVED';
    c_ds_object_research         CONSTANT ds_component.internal_name%TYPE := 'OBJECTION';
    c_ds_reason_not_approved     CONSTANT ds_component.internal_name%TYPE := 'REASON_CONCLUSIONS';
    c_ds_tissue_donor            CONSTANT ds_component.internal_name%TYPE := 'TISSUE_DONOR';
    c_ds_organ_donor             CONSTANT ds_component.internal_name%TYPE := 'ORGAN_DONOR';
    c_ds_family_letter           CONSTANT ds_component.internal_name%TYPE := 'FAMILY_LETTER';
    c_ds_family_name             CONSTANT ds_component.internal_name%TYPE := 'NAME_DECISION';
    c_ds_family_address          CONSTANT ds_component.internal_name%TYPE := 'ADDRESS';
    c_ds_justice_consent         CONSTANT ds_component.internal_name%TYPE := 'JUSTICE_OFFICER';
    c_ds_donor_center            CONSTANT ds_component.internal_name%TYPE := 'DONOR_PRESENTED';
    c_ds_reason_donor_center     CONSTANT ds_component.internal_name%TYPE := 'REASON_DONOR';

    --
    -- PRIVATE FUNCTIONS
    --

    /**********************************************************************************************
    * Returns a organ donor row/registry
    *
    * @param        i_organ_donor            Organ donor id, if null returns a row for a patient id
    *                                        (defaults to null)
    * @param        i_patient                Patient id, if null returns a row for a organ donor id
    *                                        (defaults to null)
    * @param        i_status                 Registry status, if null returns with any status
    *                                        (defaults to null)
    *
    * @return       Organ donor row/registry
    *                        
    * @author       Paulo Fonseca
    * @version      2.6.0.3
    * @since        21-Jun-2010
    **********************************************************************************************/
    FUNCTION get_organ_donor_row
    (
        i_organ_donor IN organ_donor.id_organ_donor%TYPE DEFAULT NULL,
        i_patient     IN patient.id_patient%TYPE DEFAULT NULL,
        i_status      IN death_registry.flg_status%TYPE DEFAULT NULL
    ) RETURN organ_donor%ROWTYPE IS
        c_function_name CONSTANT obj_name := 'GET_ORGAN_DONOR_ROW';
        l_dbg_msg debug_msg;
    
        l_od_row organ_donor%ROWTYPE;
    
    BEGIN
        IF i_organ_donor IS NOT NULL
        THEN
            l_dbg_msg := 'get organ donor registry data';
            pk_alertlog.log_info(text => l_dbg_msg, object_name => c_package_name, sub_object_name => c_function_name);
            SELECT od.*
              INTO l_od_row
              FROM organ_donor od
             WHERE od.id_organ_donor = i_organ_donor;
        
        ELSE
            l_dbg_msg := 'get patient organ donor data';
            pk_alertlog.log_info(text => l_dbg_msg, object_name => c_package_name, sub_object_name => c_function_name);
            SELECT odo.*
              INTO l_od_row
              FROM (SELECT od.*
                      FROM organ_donor od
                     WHERE od.id_patient = i_patient
                       AND (i_status IS NULL OR od.flg_status = i_status)
                     ORDER BY od.dt_organ_donor DESC) odo
             WHERE rownum = 1;
        END IF;
    
        RETURN l_od_row;
    
    EXCEPTION
        WHEN no_data_found THEN
            l_dbg_msg := 'patient does not have a organ donor registry';
            pk_alertlog.log_info(text => l_dbg_msg, object_name => c_package_name, sub_object_name => c_function_name);
            l_od_row.id_organ_donor := NULL;
            RETURN l_od_row;
        
    END get_organ_donor_row;

    /**********************************************************************************************
    * Get donor contagious diseases history next id
    *
    * @return       Donor contagious diseases next id
    *                        
    * @author       Paulo Fonseca
    * @version      2.6.0.3
    * @since        18-Jun-2010
    **********************************************************************************************/
    FUNCTION get_don_cont_disease_nextval RETURN donor_contag_disease.id_donor_contag_disease%TYPE IS
        c_function_name CONSTANT obj_name := 'GET_DON_CONT_DISEASE_NEXTVAL';
        l_dbg_msg debug_msg;
    
        l_donor_contag_disease donor_contag_disease.id_donor_contag_disease%TYPE;
    
    BEGIN
        l_dbg_msg := 'get donor contagious diseases next id';
        pk_alertlog.log_info(text => l_dbg_msg, object_name => c_package_name, sub_object_name => c_function_name);
        SELECT seq_donor_contag_disease.nextval
          INTO l_donor_contag_disease
          FROM dual;
    
        RETURN l_donor_contag_disease;
    
    END get_don_cont_disease_nextval;

    /**********************************************************************************************
    * Get donor contagious diseases history next id
    *
    * @return       Donor contagious diseases history next id
    *                        
    * @author       Filipe Machado
    * @version      2.6.0.3
    * @since        18-Jun-2010
    **********************************************************************************************/
    FUNCTION get_don_cont_dis_hist_nextval RETURN donor_cont_disease_hist.id_donor_cont_disease_hist%TYPE IS
        c_function_name CONSTANT obj_name := 'GET_DON_CONT_DIS_HIST_NEXTVAL';
        l_dbg_msg debug_msg;
    
        l_donor_cont_disease_hist donor_cont_disease_hist.id_donor_cont_disease_hist%TYPE;
    
    BEGIN
        l_dbg_msg := 'get donor contagious diseases history next id';
        pk_alertlog.log_info(text => l_dbg_msg, object_name => c_package_name, sub_object_name => c_function_name);
        SELECT seq_donor_cont_disease_hist.nextval
          INTO l_donor_cont_disease_hist
          FROM dual;
    
        RETURN l_donor_cont_disease_hist;
    
    END get_don_cont_dis_hist_nextval;

    /**********************************************************************************************
    * Get organ/tissue donation next id
    *
    * @return       Organ/tissue donation next id
    *                        
    * @author       Paulo Fonseca
    * @version      2.6.0.3
    * @since        21-Jun-2010
    **********************************************************************************************/
    FUNCTION get_org_tis_don_nextval RETURN death_cause.id_death_cause%TYPE IS
        c_function_name CONSTANT obj_name := 'GET_ORG_TIS_DON_NEXTVAL';
        l_dbg_msg debug_msg;
    
        l_organ_tissue_donation organ_tissue_donation.id_organ_tissue_donation%TYPE;
    
    BEGIN
        l_dbg_msg := 'get organ/tissue donation next id';
        pk_alertlog.log_info(text => l_dbg_msg, object_name => c_package_name, sub_object_name => c_function_name);
        SELECT seq_organ_tissue_donation.nextval
          INTO l_organ_tissue_donation
          FROM dual;
    
        RETURN l_organ_tissue_donation;
    
    END get_org_tis_don_nextval;

    /**********************************************************************************************
    * Get organ/tissue donation history next id
    *
    * @return       Organ/tissue donation history next id
    *                        
    * @author       Filipe Machado
    * @version      2.6.0.3
    * @since        21-Jun-2010
    **********************************************************************************************/
    FUNCTION get_org_tis_don_hist_nextval RETURN organ_tissue_donat_hist.id_organ_tissue_donat_hist%TYPE IS
        c_function_name CONSTANT obj_name := 'GET_ORG_TIS_DON_HIST_NEXTVAL';
        l_dbg_msg debug_msg;
    
        l_organ_tissue_donat_hist organ_tissue_donat_hist.id_organ_tissue_donat_hist%TYPE;
    
    BEGIN
        l_dbg_msg := 'get organ/tissue donation history next id';
        pk_alertlog.log_info(text => l_dbg_msg, object_name => c_package_name, sub_object_name => c_function_name);
        SELECT seq_organ_tissue_donat_hist.nextval
          INTO l_organ_tissue_donat_hist
          FROM dual;
    
        RETURN l_organ_tissue_donat_hist;
    
    END get_org_tis_don_hist_nextval;

    /**********************************************************************************************
    * Set donor contagious diseases history
    *
    * @param        i_lang                   Language id
    * @param        i_organ_donor            Organ donor id
    * @param        i_organ_donor_hist       Organ donor history id
    * @param        o_pat_history_diagnosis  Patient history diagnosis ids
    * @param        o_error                  Error information
    *
    * @return       TRUE if sucess, FALSE otherwise
    *                        
    * @author       Filipe Machado
    * @version      2.6.0.3
    * @since        21-Jun-2010
    **********************************************************************************************/
    FUNCTION set_donor_cont_disease_detail
    (
        i_lang                  IN language.id_language%TYPE,
        i_organ_donor           IN organ_donor.id_organ_donor%TYPE,
        i_organ_donor_hist      IN organ_donor_hist.id_organ_donor_hist%TYPE,
        o_pat_history_diagnosis OUT table_number,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
        c_function_name CONSTANT obj_name := 'SET_DONOR_CONT_DISEASE_DETAIL';
        l_dbg_msg debug_msg;
    
        l_dcd_tbl  ts_donor_contag_disease.donor_contag_disease_tc;
        l_dcdh_tbl ts_donor_cont_disease_hist.donor_cont_disease_hist_tc;
        l_nrows    PLS_INTEGER;
    
    BEGIN
        l_dbg_msg := 'get donor contagious diseases registries';
        pk_alertlog.log_info(text => l_dbg_msg, object_name => c_package_name, sub_object_name => c_function_name);
        SELECT dcd.* BULK COLLECT
          INTO l_dcd_tbl
          FROM donor_contag_disease dcd
         WHERE dcd.id_organ_donor = i_organ_donor;
    
        l_nrows := l_dcd_tbl.count();
        IF l_nrows = 0
        THEN
            l_dbg_msg := 'Donor does not have contagious diseases registries';
            pk_alertlog.log_info(text => l_dbg_msg, object_name => c_package_name, sub_object_name => c_function_name);
            o_pat_history_diagnosis := NULL;
            RETURN TRUE;
        END IF;
    
        o_pat_history_diagnosis := table_number();
        o_pat_history_diagnosis.extend(l_nrows);
    
        l_dbg_msg := 'fill donor contagious diseases history data';
        pk_alertlog.log_info(text => l_dbg_msg, object_name => c_package_name, sub_object_name => c_function_name);
        FOR idx IN 1 .. l_nrows
        LOOP
            l_dcdh_tbl(idx).id_organ_donor_hist := i_organ_donor_hist;
            l_dcdh_tbl(idx).id_donor_contag_disease := l_dcd_tbl(idx).id_donor_contag_disease;
            l_dcdh_tbl(idx).id_organ_donor := l_dcd_tbl(idx).id_organ_donor;
            l_dcdh_tbl(idx).id_pat_history_diagnosis := l_dcd_tbl(idx).id_pat_history_diagnosis;
            l_dcdh_tbl(idx).id_donor_cont_disease_hist := get_don_cont_dis_hist_nextval();
        
            o_pat_history_diagnosis(idx) := l_dcdh_tbl(idx).id_pat_history_diagnosis;
        
        END LOOP;
    
        l_dbg_msg := 'insert values into donor contagious diseases history';
        pk_alertlog.log_info(text => l_dbg_msg, object_name => c_package_name, sub_object_name => c_function_name);
        ts_donor_cont_disease_hist.ins(rows_in => l_dcdh_tbl);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => l_dbg_msg,
                                              i_owner    => c_package_owner,
                                              i_package  => c_package_name,
                                              i_function => c_function_name,
                                              o_error    => o_error);
        
            pk_utils.undo_changes;
            o_pat_history_diagnosis := NULL;
            RETURN FALSE;
        
    END set_donor_cont_disease_detail;

    /**********************************************************************************************
    * Set organ/tissue donation history
    *
    * @param        i_lang                   Language id
    * @param        i_organ_donor            Organ donor id
    * @param        i_organ_donor_hist       Organ donor history id
    * @param        o_organ_tissue           Organ/tissue ids
    * @param        o_error                  Error information
    *
    * @return       TRUE if sucess, FALSE otherwise
    *                        
    * @author       Filipe Machado
    * @version      2.6.0.3
    * @since        18-Jun-2010
    **********************************************************************************************/
    FUNCTION set_organ_tissue_donat_detail
    (
        i_lang             IN language.id_language%TYPE,
        i_organ_donor      IN organ_donor.id_organ_donor%TYPE,
        i_organ_donor_hist IN organ_donor_hist.id_organ_donor_hist%TYPE,
        o_organ_tissue     OUT table_number,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        c_function_name CONSTANT obj_name := 'SET_ORGAN_TISSUE_DONAT_DETAIL';
        l_dbg_msg debug_msg;
    
        l_otd_tbl  ts_organ_tissue_donation.organ_tissue_donation_tc;
        l_otdh_tbl ts_organ_tissue_donat_hist.organ_tissue_donat_hist_tc;
        l_nrows    PLS_INTEGER;
    
    BEGIN
        l_dbg_msg := 'get organ/tissue donation registries';
        pk_alertlog.log_info(text => l_dbg_msg, object_name => c_package_name, sub_object_name => c_function_name);
        SELECT otd.* BULK COLLECT
          INTO l_otd_tbl
          FROM organ_tissue_donation otd
         WHERE otd.id_organ_donor = i_organ_donor;
    
        l_nrows := l_otd_tbl.count();
        IF l_nrows = 0
        THEN
            l_dbg_msg := 'Donor does not have organ/tissue donation registries';
            pk_alertlog.log_info(text => l_dbg_msg, object_name => c_package_name, sub_object_name => c_function_name);
            o_organ_tissue := NULL;
            RETURN TRUE;
        END IF;
    
        o_organ_tissue := table_number();
        o_organ_tissue.extend(l_nrows);
    
        l_dbg_msg := 'fill organ/tissue donation history data';
        pk_alertlog.log_info(text => l_dbg_msg, object_name => c_package_name, sub_object_name => c_function_name);
        FOR idx IN 1 .. l_nrows
        LOOP
            l_otdh_tbl(idx).id_organ_donor_hist := i_organ_donor_hist;
            l_otdh_tbl(idx).id_organ_tissue_donation := l_otd_tbl(idx).id_organ_tissue_donation;
            l_otdh_tbl(idx).id_organ_donor := l_otd_tbl(idx).id_organ_donor;
            l_otdh_tbl(idx).id_organ_tissue := l_otd_tbl(idx).id_organ_tissue;
            l_otdh_tbl(idx).id_organ_tissue_donat_hist := get_org_tis_don_hist_nextval();
        
            o_organ_tissue(idx) := l_otdh_tbl(idx).id_organ_tissue;
        
        END LOOP;
    
        l_dbg_msg := 'insert values into organ/tissue donation history';
        pk_alertlog.log_info(text => l_dbg_msg, object_name => c_package_name, sub_object_name => c_function_name);
        ts_organ_tissue_donat_hist.ins(rows_in => l_otdh_tbl);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => l_dbg_msg,
                                              i_owner    => c_package_owner,
                                              i_package  => c_package_name,
                                              i_function => c_function_name,
                                              o_error    => o_error);
        
            pk_utils.undo_changes;
            o_organ_tissue := NULL;
            RETURN FALSE;
        
    END set_organ_tissue_donat_detail;

    /**********************************************************************************************
    * Set organ donor history
    *
    * @param        i_lang                   Language id
    * @param        i_organ_donor            Organ donor id
    * @param        o_organ_donor_hist       Organ donor history id
    * @param        o_error                  Error information
    *
    * @return       TRUE if sucess, FALSE otherwise
    *                        
    * @author       Filipe Machado
    * @version      2.6.0.3
    * @since        18-Jun-2010
    **********************************************************************************************/
    FUNCTION set_organ_donor_detail
    (
        i_lang             IN language.id_language%TYPE,
        i_organ_donor      IN organ_donor.id_organ_donor%TYPE,
        o_organ_donor_hist OUT organ_donor_hist.id_organ_donor_hist%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        c_function_name CONSTANT obj_name := 'SET_ORGAN_DONOR_DETAIL';
        l_dbg_msg debug_msg;
    
        l_od_row                organ_donor%ROWTYPE;
        l_odh_row               organ_donor_hist%ROWTYPE;
        l_pat_history_diagnosis table_number;
        l_organ_tissue          table_number;
    
    BEGIN
        l_dbg_msg := 'get organ donor data';
        pk_alertlog.log_info(text => l_dbg_msg, object_name => c_package_name, sub_object_name => c_function_name);
        l_od_row := get_organ_donor_row(i_organ_donor => i_organ_donor);
    
        l_dbg_msg := 'fill organ donor history data';
        pk_alertlog.log_info(text => l_dbg_msg, object_name => c_package_name, sub_object_name => c_function_name);
        l_odh_row.id_organ_donor          := l_od_row.id_organ_donor;
        l_odh_row.id_patient              := l_od_row.id_patient;
        l_odh_row.id_episode              := l_od_row.id_episode;
        l_odh_row.id_sl_able_don_organs   := l_od_row.id_sl_able_don_organs;
        l_odh_row.reason_not_able_don_org := l_od_row.reason_not_able_don_org;
        l_odh_row.id_sl_able_don_tissues  := l_od_row.id_sl_able_don_tissues;
        l_odh_row.reason_not_able_don_tis := l_od_row.reason_not_able_don_tis;
        l_odh_row.id_sl_will_consulted    := l_od_row.id_sl_will_consulted;
        l_odh_row.id_sl_will_result       := l_od_row.id_sl_will_result;
        l_odh_row.reason_will_not_cons    := l_od_row.reason_will_not_cons;
        l_odh_row.id_sl_other_declaration := l_od_row.id_sl_other_declaration;
        l_odh_row.other_declaration_notes := l_od_row.other_declaration_notes;
        l_odh_row.id_sl_don_authorized    := l_od_row.id_sl_don_authorized;
        l_odh_row.responsible_name        := l_od_row.responsible_name;
        l_odh_row.id_family_relationship  := l_od_row.id_family_relationship;
        l_odh_row.reason_not_authorized   := l_od_row.reason_not_authorized;
        l_odh_row.id_sl_donation_approved := l_od_row.id_sl_donation_approved;
        l_odh_row.id_sl_object_research   := l_od_row.id_sl_object_research;
        l_odh_row.reason_not_approved     := l_od_row.reason_not_approved;
        l_odh_row.id_sl_family_letter     := l_od_row.id_sl_family_letter;
        l_odh_row.family_name             := l_od_row.family_name;
        l_odh_row.family_address          := l_od_row.family_address;
        l_odh_row.id_sl_justice_consent   := l_od_row.id_sl_justice_consent;
        l_odh_row.id_sl_donor_center      := l_od_row.id_sl_donor_center;
        l_odh_row.reason_donor_center     := l_od_row.reason_donor_center;
        l_odh_row.id_prof_organ_donor     := l_od_row.id_prof_organ_donor;
        l_odh_row.dt_organ_donor          := l_od_row.dt_organ_donor;
        l_odh_row.id_cancel_reason        := l_od_row.id_cancel_reason;
        l_odh_row.notes_cancel            := l_od_row.notes_cancel;
        l_odh_row.flg_status              := l_od_row.flg_status;
        l_odh_row.id_organ_donor_hist     := ts_organ_donor_hist.next_key();
    
        l_dbg_msg := 'insert values into organ donor history';
        pk_alertlog.log_info(text => l_dbg_msg, object_name => c_package_name, sub_object_name => c_function_name);
        ts_organ_donor_hist.ins(rec_in => l_odh_row);
    
        l_dbg_msg := 'insert into donor contagious diseases history';
        pk_alertlog.log_info(text => l_dbg_msg, object_name => c_package_name, sub_object_name => c_function_name);
        IF NOT set_donor_cont_disease_detail(i_lang                  => i_lang,
                                             i_organ_donor           => i_organ_donor,
                                             i_organ_donor_hist      => l_odh_row.id_organ_donor_hist,
                                             o_pat_history_diagnosis => l_pat_history_diagnosis,
                                             o_error                 => o_error)
        THEN
            pk_utils.undo_changes;
            o_organ_donor_hist := NULL;
            RETURN FALSE;
        END IF;
    
        l_dbg_msg := 'insert into organ/tissue donation history';
        pk_alertlog.log_info(text => l_dbg_msg, object_name => c_package_name, sub_object_name => c_function_name);
        IF NOT set_organ_tissue_donat_detail(i_lang             => i_lang,
                                             i_organ_donor      => i_organ_donor,
                                             i_organ_donor_hist => l_odh_row.id_organ_donor_hist,
                                             o_organ_tissue     => l_organ_tissue,
                                             o_error            => o_error)
        THEN
            pk_utils.undo_changes;
            o_organ_donor_hist := NULL;
            RETURN FALSE;
        END IF;
    
        o_organ_donor_hist := l_odh_row.id_organ_donor_hist;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => l_dbg_msg,
                                              i_owner    => c_package_owner,
                                              i_package  => c_package_name,
                                              i_function => c_function_name,
                                              o_error    => o_error);
        
            pk_utils.undo_changes;
            o_organ_donor_hist := NULL;
            RETURN FALSE;
        
    END set_organ_donor_detail;

    /**********************************************************************************************
    * Get professional data for organ donor history registries
    *
    * @param        i_lang                   Language id
    * @param        i_prof                   Professional, software and institution ids
    * @param        i_patient                Patient id
    * @param        o_prof_data              Cursor with the professional data history
    * @param        o_error                  Error information
    *
    * @return       TRUE if sucess, FALSE otherwise
    *                        
    * @author       Paulo Fonseca
    * @version      2.6.0.3
    * @since        22-Jun-2010
    **********************************************************************************************/
    FUNCTION get_od_hist_prof_data
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_patient   IN patient.id_patient%TYPE,
        o_prof_data OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
        c_function_name CONSTANT obj_name := 'GET_OD_HIST_PROF_DATA';
        l_dbg_msg debug_msg;
    
        l_created   sys_message.desc_message%TYPE;
        l_edited    sys_message.desc_message%TYPE;
        l_cancelled sys_message.desc_message%TYPE;
    
    BEGIN
        l_dbg_msg := 'get detail status messages';
        pk_alertlog.log_info(text => l_dbg_msg, object_name => c_package_name, sub_object_name => c_function_name);
        l_created   := pk_message.get_message(i_lang => i_lang, i_code_mess => 'DETAIL_COMMON_M001');
        l_edited    := pk_message.get_message(i_lang => i_lang, i_code_mess => 'DETAIL_COMMON_M002');
        l_cancelled := pk_message.get_message(i_lang => i_lang, i_code_mess => 'DETAIL_COMMON_M003');
    
        l_dbg_msg := 'get info about the professional that made each registry';
        pk_alertlog.log_info(text => l_dbg_msg, object_name => c_package_name, sub_object_name => c_function_name);
        OPEN o_prof_data FOR
            SELECT pk_date_utils.date_char_tsz(i_lang, odh.dt_organ_donor, i_prof.institution, i_prof.software) AS registry_date,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, odh.id_prof_organ_donor) AS prof_name,
                   pk_prof_utils.get_spec_signature(i_lang,
                                                    i_prof,
                                                    odh.id_prof_organ_donor,
                                                    odh.dt_organ_donor,
                                                    odh.id_episode) AS prof_speciality,
                   odh.flg_status,
                   decode(odh.flg_status,
                          pk_alert_constant.g_active,
                          decode(odh.dt_organ_donor,
                                 (SELECT MIN(m.dt_organ_donor)
                                    FROM organ_donor_hist m
                                   WHERE m.id_organ_donor = odh.id_organ_donor
                                     AND m.flg_status = odh.flg_status),
                                 l_created,
                                 l_edited),
                          l_cancelled) AS desc_status,
                   odh.id_organ_donor_hist AS id_hist,
                   pk_cancel_reason.get_cancel_reason_desc(i_lang, i_prof, odh.id_cancel_reason) AS cancel_reason_desc,
                   odh.notes_cancel
              FROM organ_donor_hist odh
             WHERE odh.id_patient = i_patient
             ORDER BY odh.dt_organ_donor DESC;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => l_dbg_msg,
                                              i_owner    => c_package_owner,
                                              i_package  => c_package_name,
                                              i_function => c_function_name,
                                              o_error    => o_error);
        
            pk_types.open_my_cursor(i_cursor => o_prof_data);
            RETURN FALSE;
        
    END get_od_hist_prof_data;

    /**********************************************************************************************
    * Get a Patient history diagnosis id for a diagnosis registered for a patient, if he has one.
    *
    * @param        i_patient                Patient id
    * @param        i_diagnosis              Diagnosis id
    * @param        i_alert_diagnosis        Alert diagnosis id
    *
    * @return       Patient history diagnosis id
    *                        
    * @author       Paulo Fonseca
    * @version      2.6.0.3
    * @since        24-Jun-2010
    **********************************************************************************************/
    FUNCTION get_pat_history_diagnosis
    (
        i_patient         IN pat_history_diagnosis.id_patient%TYPE,
        i_diagnosis       IN pat_history_diagnosis.id_diagnosis%TYPE,
        i_alert_diagnosis IN pat_history_diagnosis.id_alert_diagnosis%TYPE
    ) RETURN pat_history_diagnosis.id_pat_history_diagnosis%TYPE IS
        c_function_name CONSTANT obj_name := 'GET_PAT_HISTORY_DIAGNOSIS';
        l_dbg_msg debug_msg;
    
        l_pat_history_diagnosis pat_history_diagnosis.id_pat_history_diagnosis%TYPE;
    
    BEGIN
        l_dbg_msg := 'get pat history diagnosis id';
        pk_alertlog.log_info(text => l_dbg_msg, object_name => c_package_name, sub_object_name => c_function_name);
        SELECT id_pat_history_diagnosis
          INTO l_pat_history_diagnosis
          FROM (SELECT phd.id_pat_history_diagnosis
                  FROM pat_history_diagnosis phd
                 WHERE phd.flg_status = pk_alert_constant.g_active
                   AND phd.id_patient = i_patient
                   AND instr(phd.flg_type, pk_summary_page.g_alert_diag_type_med) > 0
                   AND phd.id_diagnosis = i_diagnosis
                   AND (i_alert_diagnosis IS NULL OR phd.id_alert_diagnosis = i_alert_diagnosis)
                 ORDER BY phd.dt_pat_history_diagnosis_tstz DESC)
         WHERE rownum = 1;
    
        RETURN l_pat_history_diagnosis;
    
    EXCEPTION
        WHEN no_data_found THEN
            l_dbg_msg := 'diagnosis not found for this patient';
            pk_alertlog.log_info(text => l_dbg_msg, object_name => c_package_name, sub_object_name => c_function_name);
            RETURN NULL;
        
    END get_pat_history_diagnosis;

    /**********************************************************************************************
    * Set organ donor contagious diseases
    *
    * @param        i_lang                   Language id
    * @param        i_prof                   Professional, software and institution ids
    * @param        i_patient                Patient id
    * @param        i_episode                Episode id
    * @param        i_organ_donor            Organ donor id
    * @param        i_data_val               Structure with all data values
    * @param        o_pat_history_diagnosis  Patient history diagnosis ids
    * @param        o_error                  Error information
    *
    * @return       TRUE if sucess, FALSE otherwise
    *                        
    * @author       Paulo Fonseca
    * @version      2.6.0.3
    * @since        24-Jun-2010
    **********************************************************************************************/
    FUNCTION set_donor_contag_disease
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_patient               IN patient.id_patient%TYPE,
        i_episode               IN episode.id_episode%TYPE,
        i_organ_donor           IN organ_donor.id_organ_donor%TYPE,
        i_data_val              IN table_table_varchar,
        o_pat_history_diagnosis OUT table_number,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
        c_function_name CONSTANT obj_name := 'SET_DONOR_CONTAG_DISEASE';
        l_dbg_msg debug_msg;
    
        l_diagnosis             diagnosis.id_diagnosis%TYPE;
        l_alert_diagnosis       alert_diagnosis.id_alert_diagnosis%TYPE;
        l_pat_history_diagnosis pat_history_diagnosis.id_pat_history_diagnosis%TYPE;
    
        l_dcd_tbl ts_donor_contag_disease.donor_contag_disease_tc;
        idx_cd    PLS_INTEGER := 0;
    
        -- dummy variables
        l_msg       VARCHAR2(200 CHAR);
        l_msg_title VARCHAR2(200 CHAR);
        l_flg_show  VARCHAR2(200 CHAR);
        l_button    VARCHAR2(200 CHAR);
        l_type      table_varchar;
        l_ids       table_number;
    BEGIN
        l_dbg_msg := 'remove old donor_contagious diseases';
        pk_alertlog.log_info(text => l_dbg_msg, object_name => c_package_name, sub_object_name => c_function_name);
        ts_donor_contag_disease.del_by(where_clause_in => ' id_organ_donor = ' || i_organ_donor);
    
        l_dbg_msg := 'fill donor contagious diseases data structure';
        pk_alertlog.log_info(text => l_dbg_msg, object_name => c_package_name, sub_object_name => c_function_name);
        FOR idx IN 1 .. i_data_val.count()
        LOOP
            IF i_data_val(idx) (pk_dynamic_screen.c_name_idx) = c_ds_contagious_diseases
            THEN
                l_diagnosis       := i_data_val(idx) (pk_dynamic_screen.c_val_idx);
                l_alert_diagnosis := i_data_val(idx) (pk_dynamic_screen.c_alt_val_idx);
            
                l_dbg_msg := 'get contagious disease problem id';
                pk_alertlog.log_info(text            => l_dbg_msg,
                                     object_name     => c_package_name,
                                     sub_object_name => c_function_name);
                l_pat_history_diagnosis := get_pat_history_diagnosis(i_patient         => i_patient,
                                                                     i_diagnosis       => l_diagnosis,
                                                                     i_alert_diagnosis => l_alert_diagnosis);
            
                IF l_pat_history_diagnosis IS NULL
                THEN
                    l_dbg_msg := 'create contagious disease';
                    pk_alertlog.log_info(text            => l_dbg_msg,
                                         object_name     => c_package_name,
                                         sub_object_name => c_function_name);
                    IF NOT pk_problems.create_pat_problem_array(i_lang                   => i_lang,
                                                                i_epis                   => i_episode,
                                                                i_pat                    => i_patient,
                                                                i_prof                   => i_prof,
                                                                i_desc_problem           => table_varchar(NULL),
                                                                i_flg_status             => table_varchar(pk_alert_constant.g_active),
                                                                i_notes                  => table_varchar(NULL),
                                                                i_prof_cat_type          => NULL,
                                                                i_diagnosis              => table_number(l_diagnosis),
                                                                i_flg_nature             => table_varchar(NULL),
                                                                i_alert_diag             => table_number(l_alert_diagnosis),
                                                                i_precaution_measure     => table_table_number(NULL),
                                                                i_header_warning         => table_varchar(pk_alert_constant.g_yes),
                                                                i_cdr_call               => NULL,
                                                                i_dt_diagnosed           => table_varchar(NULL),
                                                                i_dt_diagnosed_precision => table_varchar(NULL),
                                                                i_dt_resolved            => table_varchar(NULL),
                                                                i_dt_resolved_precision  => table_varchar(NULL),
                                                                o_msg                    => l_msg,
                                                                o_msg_title              => l_msg_title,
                                                                o_flg_show               => l_flg_show,
                                                                o_button                 => l_button,
                                                                o_type                   => l_type,
                                                                o_ids                    => l_ids,
                                                                o_error                  => o_error)
                    THEN
                        pk_utils.undo_changes;
                        o_pat_history_diagnosis := NULL;
                        RETURN FALSE;
                    END IF;
                
                    l_dbg_msg := 'get new contagious disease problem id';
                    pk_alertlog.log_info(text            => l_dbg_msg,
                                         object_name     => c_package_name,
                                         sub_object_name => c_function_name);
                    l_pat_history_diagnosis := get_pat_history_diagnosis(i_patient         => i_patient,
                                                                         i_diagnosis       => l_diagnosis,
                                                                         i_alert_diagnosis => l_alert_diagnosis);
                END IF;
            
                idx_cd := l_dcd_tbl.count() + 1;
                l_dcd_tbl(idx_cd).id_organ_donor := i_organ_donor;
                l_dcd_tbl(idx_cd).id_pat_history_diagnosis := l_pat_history_diagnosis;
                l_dcd_tbl(idx_cd).id_donor_contag_disease := get_don_cont_disease_nextval();
            
            END IF;
        END LOOP;
    
        l_dbg_msg := 'insert into donor contagious diseases';
        pk_alertlog.log_info(text => l_dbg_msg, object_name => c_package_name, sub_object_name => c_function_name);
        ts_donor_contag_disease.ins(rows_in => l_dcd_tbl);
    
        l_dbg_msg := 'fill output collection with patient history diagnosis ids';
        pk_alertlog.log_info(text => l_dbg_msg, object_name => c_package_name, sub_object_name => c_function_name);
        IF idx_cd < 1
        THEN
            o_pat_history_diagnosis := NULL;
        
        ELSE
            o_pat_history_diagnosis := table_number();
            o_pat_history_diagnosis.extend(idx_cd);
            FOR idx IN 1 .. idx_cd
            LOOP
                o_pat_history_diagnosis(idx) := l_dcd_tbl(idx).id_pat_history_diagnosis;
            END LOOP;
        
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => l_dbg_msg,
                                              i_owner    => c_package_owner,
                                              i_package  => c_package_name,
                                              i_function => c_function_name,
                                              o_error    => o_error);
        
            pk_utils.undo_changes;
            o_pat_history_diagnosis := NULL;
            RETURN FALSE;
        
    END set_donor_contag_disease;

    /**********************************************************************************************
    * Set donor organ/tissues for donation
    *
    * @param        i_lang                   Language id
    * @param        i_organ_donor            Organ donor id
    * @param        i_data_val               Structure with all data values
    * @param        o_organ_tissue           Organ/tissues ids
    * @param        o_error                  Error information
    *
    * @return       TRUE if sucess, FALSE otherwise
    *                        
    * @author       Paulo Fonseca
    * @version      2.6.0.3
    * @since        24-Jun-2010
    **********************************************************************************************/
    FUNCTION set_organ_tissue_don
    (
        i_lang         IN language.id_language%TYPE,
        i_organ_donor  IN organ_donor.id_organ_donor%TYPE,
        i_data_val     IN table_table_varchar,
        o_organ_tissue OUT table_number,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        c_function_name CONSTANT obj_name := 'SET_ORGAN_TISSUE_DON';
        l_dbg_msg debug_msg;
    
        l_otd_tbl ts_organ_tissue_donation.organ_tissue_donation_tc;
        idx_ot    PLS_INTEGER := 0;
    
    BEGIN
        l_dbg_msg := 'remove old organ/tissues donations';
        pk_alertlog.log_info(text => l_dbg_msg, object_name => c_package_name, sub_object_name => c_function_name);
        ts_organ_tissue_donation.del_by(where_clause_in => ' id_organ_donor = ' || i_organ_donor);
    
        o_organ_tissue := table_number();
        l_dbg_msg      := 'fill organ/tissue donation data structure';
        pk_alertlog.log_info(text => l_dbg_msg, object_name => c_package_name, sub_object_name => c_function_name);
        FOR idx IN 1 .. i_data_val.count()
        LOOP
            IF i_data_val(idx) (pk_dynamic_screen.c_name_idx) IN (c_ds_tissue_donor, c_ds_organ_donor)
            THEN
                idx_ot := l_otd_tbl.count() + 1;
                l_otd_tbl(idx_ot).id_organ_donor := i_organ_donor;
                l_otd_tbl(idx_ot).id_organ_tissue := i_data_val(idx) (pk_dynamic_screen.c_val_idx);
                l_otd_tbl(idx_ot).id_organ_tissue_donation := get_org_tis_don_nextval();
            
            END IF;
        END LOOP;
    
        l_dbg_msg := 'insert into donor contagious diseases';
        pk_alertlog.log_info(text => l_dbg_msg, object_name => c_package_name, sub_object_name => c_function_name);
        ts_organ_tissue_donation.ins(rows_in => l_otd_tbl);
    
        l_dbg_msg := 'fill output collection with organ/tissues ids';
        pk_alertlog.log_info(text => l_dbg_msg, object_name => c_package_name, sub_object_name => c_function_name);
        IF idx_ot < 1
        THEN
            o_organ_tissue := NULL;
        
        ELSE
            o_organ_tissue := table_number();
            o_organ_tissue.extend(idx_ot);
            FOR idx IN 1 .. idx_ot
            LOOP
                o_organ_tissue(idx) := l_otd_tbl(idx).id_organ_tissue;
            END LOOP;
        
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => l_dbg_msg,
                                              i_owner    => c_package_owner,
                                              i_package  => c_package_name,
                                              i_function => c_function_name,
                                              o_error    => o_error);
        
            pk_utils.undo_changes;
            o_organ_tissue := NULL;
            RETURN FALSE;
        
    END set_organ_tissue_don;

    /**********************************************************************************************
    * Get donor contagious diseases
    *
    * @param        i_lang                   Language id
    * @param        i_prof                   Professional, software and institution ids
    * @param        i_organ_donor            Organ donor id
    * @param        o_data_val               Structure with data values
    * @param        o_error                  Error information
    *
    * @return       TRUE if sucess, FALSE otherwise
    *                        
    * @author       Paulo Fonseca
    * @version      2.6.0.3
    * @since        24-Jun-2010
    **********************************************************************************************/
    FUNCTION get_donor_contag_disease
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_organ_donor IN organ_donor.id_organ_donor%TYPE,
        o_data_val    IN OUT NOCOPY table_table_varchar,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        c_function_name CONSTANT obj_name := 'GET_DONOR_CONTAG_DISEASE';
        l_dbg_msg debug_msg;
    
        l_dcd_tbl ts_donor_contag_disease.donor_contag_disease_tc;
    
    BEGIN
        l_dbg_msg := 'get donor contagious diseases';
        pk_alertlog.log_info(text => l_dbg_msg, object_name => c_package_name, sub_object_name => c_function_name);
        SELECT dcd.* BULK COLLECT
          INTO l_dcd_tbl
          FROM donor_contag_disease dcd
         WHERE dcd.id_organ_donor = i_organ_donor;
    
        l_dbg_msg := 'fill structure with donor contagious diseases';
        pk_alertlog.log_info(text => l_dbg_msg, object_name => c_package_name, sub_object_name => c_function_name);
        FOR idx IN 1 .. l_dcd_tbl.count()
        LOOP
            o_data_val := pk_dynamic_screen.add_value_pat_hist_diagn(i_lang     => i_lang,
                                                                     i_prof     => i_prof,
                                                                     i_data_val => o_data_val,
                                                                     i_name     => c_ds_contagious_diseases,
                                                                     i_value    => l_dcd_tbl(idx).id_pat_history_diagnosis);
        END LOOP;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => l_dbg_msg,
                                              i_owner    => c_package_owner,
                                              i_package  => c_package_name,
                                              i_function => c_function_name,
                                              o_error    => o_error);
        
            o_data_val := NULL;
            RETURN FALSE;
        
    END get_donor_contag_disease;

    /**********************************************************************************************
    * Get donor contagious diseases history
    *
    * @param        i_lang                   Language id
    * @param        i_prof                   Professional, software and institution ids
    * @param        i_organ_donor_hist       Organ donor history id
    * @param        o_data_val               Structure with data values
    * @param        o_error                  Error information
    *
    * @return       TRUE if sucess, FALSE otherwise
    *                        
    * @author       Paulo Fonseca
    * @version      2.6.0.3
    * @since        24-Jun-2010
    **********************************************************************************************/
    FUNCTION get_don_cont_disease_detail
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_organ_donor_hist IN organ_donor_hist.id_organ_donor_hist%TYPE,
        o_data_val         IN OUT NOCOPY table_table_varchar,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        c_function_name CONSTANT obj_name := 'GET_DON_CONT_DISEASE_DETAIL';
        l_dbg_msg debug_msg;
    
        l_dcdh_tbl ts_donor_cont_disease_hist.donor_cont_disease_hist_tc;
    
    BEGIN
        l_dbg_msg := 'get donor contagious diseases';
        pk_alertlog.log_info(text => l_dbg_msg, object_name => c_package_name, sub_object_name => c_function_name);
        SELECT dcdh.* BULK COLLECT
          INTO l_dcdh_tbl
          FROM donor_cont_disease_hist dcdh
         WHERE dcdh.id_organ_donor_hist = i_organ_donor_hist;
    
        l_dbg_msg := 'fill structure with donor contagious diseases';
        pk_alertlog.log_info(text => l_dbg_msg, object_name => c_package_name, sub_object_name => c_function_name);
        FOR idx IN 1 .. l_dcdh_tbl.count()
        LOOP
            o_data_val := pk_dynamic_screen.add_value_pat_hist_diagn(i_lang     => i_lang,
                                                                     i_prof     => i_prof,
                                                                     i_data_val => o_data_val,
                                                                     i_name     => c_ds_contagious_diseases,
                                                                     i_value    => l_dcdh_tbl(idx)
                                                                                   .id_pat_history_diagnosis,
                                                                     i_hist     => i_organ_donor_hist);
        END LOOP;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => l_dbg_msg,
                                              i_owner    => c_package_owner,
                                              i_package  => c_package_name,
                                              i_function => c_function_name,
                                              o_error    => o_error);
        
            o_data_val := NULL;
            RETURN FALSE;
        
    END get_don_cont_disease_detail;

    /**********************************************************************************************
    * Get donor organ/tissues donations
    *
    * @param        i_lang                   Language id
    * @param        i_organ_donor            Organ donor id
    * @param        o_data_val               Structure with data values
    * @param        o_error                  Error information
    *
    * @return       TRUE if sucess, FALSE otherwise
    *                        
    * @author       Paulo Fonseca
    * @version      2.6.0.3
    * @since        24-Jun-2010
    **********************************************************************************************/
    FUNCTION get_organ_tissue_don
    (
        i_lang        IN language.id_language%TYPE,
        i_organ_donor IN organ_donor.id_organ_donor%TYPE,
        o_data_val    IN OUT NOCOPY table_table_varchar,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        c_function_name CONSTANT obj_name := 'GET_ORGAN_TISSUE_DON';
        l_dbg_msg debug_msg;
    
        l_ot_tbl organ_tissue_tc;
        l_name   ds_component.internal_name%TYPE;
    
    BEGIN
        l_dbg_msg := 'fill structure with organ/tissues donation';
        pk_alertlog.log_info(text => l_dbg_msg, object_name => c_package_name, sub_object_name => c_function_name);
        SELECT ot.* BULK COLLECT
          INTO l_ot_tbl
          FROM organ_tissue ot
         INNER JOIN organ_tissue_donation otd
            ON ot.id_organ_tissue = otd.id_organ_tissue
         WHERE otd.id_organ_donor = i_organ_donor
         ORDER BY ot.flg_type DESC;
    
        FOR idx IN 1 .. l_ot_tbl.count()
        LOOP
            CASE l_ot_tbl(idx).flg_type
                WHEN 'T' THEN
                    l_name := c_ds_tissue_donor;
                WHEN 'O' THEN
                    l_name := c_ds_organ_donor;
                ELSE
                    l_dbg_msg := 'unsupported organ/tissue type';
                    pk_alertlog.log_info(text            => l_dbg_msg,
                                         object_name     => c_package_name,
                                         sub_object_name => c_function_name);
                    o_data_val := NULL;
                    RETURN FALSE;
            END CASE;
            o_data_val := pk_dynamic_screen.add_value_org_tis(i_lang     => i_lang,
                                                              i_data_val => o_data_val,
                                                              i_name     => l_name,
                                                              i_value    => l_ot_tbl(idx).id_organ_tissue);
        
        END LOOP;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => l_dbg_msg,
                                              i_owner    => c_package_owner,
                                              i_package  => c_package_name,
                                              i_function => c_function_name,
                                              o_error    => o_error);
        
            o_data_val := NULL;
            RETURN FALSE;
        
    END get_organ_tissue_don;

    /**********************************************************************************************
    * Get donor organ/tissues donations history
    *
    * @param        i_lang                   Language id
    * @param        i_organ_donor_hist       Organ donor history id
    * @param        o_data_val               Structure with data values
    * @param        o_error                  Error information
    *
    * @return       TRUE if sucess, FALSE otherwise
    *                        
    * @author       Paulo Fonseca
    * @version      2.6.0.3
    * @since        24-Jun-2010
    **********************************************************************************************/
    FUNCTION get_organ_tissue_don_detail
    (
        i_lang             IN language.id_language%TYPE,
        i_organ_donor_hist IN organ_donor_hist.id_organ_donor_hist%TYPE,
        o_data_val         IN OUT NOCOPY table_table_varchar,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        c_function_name CONSTANT obj_name := 'GET_ORGAN_TISSUE_DON_DETAIL';
        l_dbg_msg debug_msg;
    
        l_ot_tbl organ_tissue_tc;
        l_name   ds_component.internal_name%TYPE;
    
    BEGIN
        l_dbg_msg := 'fill structure with organ/tissues donation history';
        pk_alertlog.log_info(text => l_dbg_msg, object_name => c_package_name, sub_object_name => c_function_name);
        SELECT ot.* BULK COLLECT
          INTO l_ot_tbl
          FROM organ_tissue ot
         INNER JOIN organ_tissue_donat_hist otdh
            ON ot.id_organ_tissue = otdh.id_organ_tissue
         WHERE otdh.id_organ_donor_hist = i_organ_donor_hist
         ORDER BY ot.flg_type DESC;
    
        FOR idx IN 1 .. l_ot_tbl.count()
        LOOP
            CASE l_ot_tbl(idx).flg_type
                WHEN 'T' THEN
                    l_name := c_ds_tissue_donor;
                WHEN 'O' THEN
                    l_name := c_ds_organ_donor;
                ELSE
                    l_dbg_msg := 'unsupported organ/tissue type';
                    pk_alertlog.log_info(text            => l_dbg_msg,
                                         object_name     => c_package_name,
                                         sub_object_name => c_function_name);
                    o_data_val := NULL;
                    RETURN FALSE;
            END CASE;
            o_data_val := pk_dynamic_screen.add_value_org_tis(i_lang     => i_lang,
                                                              i_data_val => o_data_val,
                                                              i_name     => l_name,
                                                              i_value    => l_ot_tbl(idx).id_organ_tissue,
                                                              i_hist     => i_organ_donor_hist);
        
        END LOOP;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => l_dbg_msg,
                                              i_owner    => c_package_owner,
                                              i_package  => c_package_name,
                                              i_function => c_function_name,
                                              o_error    => o_error);
        
            o_data_val := NULL;
            RETURN FALSE;
        
    END get_organ_tissue_don_detail;

    --
    -- PUBLIC FUNCTIONS
    -- 

    /**********************************************************************************************
    * Set organ donor data
    *
    * @param        i_lang                   Language id
    * @param        i_prof                   Professional, software and institution ids
    * @param        i_date                   Date of changes
    * @param        i_patient                Patient id
    * @param        i_episode                Episode id
    * @param        i_data_val               Structure with all data values
    * @param        o_organ_donor            Organ donor id
    * @param        o_error                  Error information
    *
    * @return       TRUE if sucess, FALSE otherwise
    *                        
    * @author       Paulo Fonseca
    * @version      2.6.0.3
    * @since        24-Jun-2010
    **********************************************************************************************/
    FUNCTION set_organ_donor
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_date        IN organ_donor.dt_organ_donor%TYPE,
        i_patient     IN patient.id_patient%TYPE,
        i_episode     IN episode.id_episode%TYPE,
        i_data_val    IN table_table_varchar,
        o_organ_donor OUT organ_donor.id_organ_donor%TYPE,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        c_function_name CONSTANT obj_name := 'SET_ORGAN_DONOR';
        l_dbg_msg debug_msg;
    
        l_od_tbl ts_organ_donor.organ_donor_tc;
    
        l_organ_donor_hist organ_donor_hist.id_organ_donor_hist%TYPE;
    
        l_organ_tissue          table_number;
        l_pat_history_diagnosis table_number;
    
    BEGIN
        l_dbg_msg := 'get the active organ donor registry for the patient, if he has one';
        pk_alertlog.log_info(text => l_dbg_msg, object_name => c_package_name, sub_object_name => c_function_name);
        l_od_tbl(1) := get_organ_donor_row(i_patient => i_patient, i_status => pk_alert_constant.g_active);
    
        l_dbg_msg := 'fill professional and date information';
        pk_alertlog.log_info(text => l_dbg_msg, object_name => c_package_name, sub_object_name => c_function_name);
        l_od_tbl(1).id_prof_organ_donor := i_prof.id;
        l_od_tbl(1).dt_organ_donor := i_date;
    
        l_dbg_msg := 'get death registry data from data structure';
        pk_alertlog.log_info(text => l_dbg_msg, object_name => c_package_name, sub_object_name => c_function_name);
        l_od_tbl(1).id_sl_able_don_organs := pk_dynamic_screen.get_value_number(i_component_name => c_ds_able_don_organs,
                                                                                i_data_val       => i_data_val,
                                                                                i_orig_val       => l_od_tbl(1)
                                                                                                    .id_sl_able_don_organs);
        l_od_tbl(1).reason_not_able_don_org := pk_dynamic_screen.get_value_str(i_component_name => c_ds_reason_not_able_don_org,
                                                                               i_data_val       => i_data_val,
                                                                               i_orig_val       => l_od_tbl(1)
                                                                                                   .reason_not_able_don_org);
        l_od_tbl(1).id_sl_able_don_tissues := pk_dynamic_screen.get_value_number(i_component_name => c_ds_able_don_tissues,
                                                                                 i_data_val       => i_data_val,
                                                                                 i_orig_val       => l_od_tbl(1)
                                                                                                     .id_sl_able_don_tissues);
        l_od_tbl(1).reason_not_able_don_tis := pk_dynamic_screen.get_value_str(i_component_name => c_ds_reason_not_able_don_tis,
                                                                               i_data_val       => i_data_val,
                                                                               i_orig_val       => l_od_tbl(1)
                                                                                                   .reason_not_able_don_tis);
        l_od_tbl(1).id_sl_will_consulted := pk_dynamic_screen.get_value_number(i_component_name => c_ds_will_consulted,
                                                                               i_data_val       => i_data_val,
                                                                               i_orig_val       => l_od_tbl(1)
                                                                                                   .id_sl_will_consulted);
        l_od_tbl(1).id_sl_will_result := pk_dynamic_screen.get_value_number(i_component_name => c_ds_will_result,
                                                                            i_data_val       => i_data_val,
                                                                            i_orig_val       => l_od_tbl(1)
                                                                                                .id_sl_will_result);
        l_od_tbl(1).reason_will_not_cons := pk_dynamic_screen.get_value_str(i_component_name => c_ds_reason_will_not_cons,
                                                                            i_data_val       => i_data_val,
                                                                            i_orig_val       => l_od_tbl(1)
                                                                                                .reason_will_not_cons);
        l_od_tbl(1).id_sl_other_declaration := pk_dynamic_screen.get_value_number(i_component_name => c_ds_other_declaration,
                                                                                  i_data_val       => i_data_val,
                                                                                  i_orig_val       => l_od_tbl(1)
                                                                                                      .id_sl_other_declaration);
        l_od_tbl(1).other_declaration_notes := pk_dynamic_screen.get_value_str(i_component_name => c_ds_other_declaration_notes,
                                                                               i_data_val       => i_data_val,
                                                                               i_orig_val       => l_od_tbl(1)
                                                                                                   .other_declaration_notes);
        l_od_tbl(1).id_sl_don_authorized := pk_dynamic_screen.get_value_number(i_component_name => c_ds_don_authorized,
                                                                               i_data_val       => i_data_val,
                                                                               i_orig_val       => l_od_tbl(1)
                                                                                                   .id_sl_don_authorized);
        l_od_tbl(1).responsible_name := pk_dynamic_screen.get_value_str(i_component_name => c_ds_responsible_name,
                                                                        i_data_val       => i_data_val,
                                                                        i_orig_val       => l_od_tbl(1).responsible_name);
        l_od_tbl(1).id_family_relationship := pk_dynamic_screen.get_value_number(i_component_name => c_ds_family_relationship,
                                                                                 i_data_val       => i_data_val,
                                                                                 i_orig_val       => l_od_tbl(1)
                                                                                                     .id_family_relationship);
        l_od_tbl(1).reason_not_authorized := pk_dynamic_screen.get_value_str(i_component_name => c_ds_reason_not_authorized,
                                                                             i_data_val       => i_data_val,
                                                                             i_orig_val       => l_od_tbl(1)
                                                                                                 .reason_not_authorized);
        l_od_tbl(1).id_sl_donation_approved := pk_dynamic_screen.get_value_number(i_component_name => c_ds_donation_approved,
                                                                                  i_data_val       => i_data_val,
                                                                                  i_orig_val       => l_od_tbl(1)
                                                                                                      .id_sl_donation_approved);
        l_od_tbl(1).id_sl_object_research := pk_dynamic_screen.get_value_number(i_component_name => c_ds_object_research,
                                                                                i_data_val       => i_data_val,
                                                                                i_orig_val       => l_od_tbl(1)
                                                                                                    .id_sl_object_research);
        l_od_tbl(1).reason_not_approved := pk_dynamic_screen.get_value_str(i_component_name => c_ds_reason_not_approved,
                                                                           i_data_val       => i_data_val,
                                                                           i_orig_val       => l_od_tbl(1)
                                                                                               .reason_not_approved);
        l_od_tbl(1).id_sl_family_letter := pk_dynamic_screen.get_value_number(i_component_name => c_ds_family_letter,
                                                                              i_data_val       => i_data_val,
                                                                              i_orig_val       => l_od_tbl(1)
                                                                                                  .id_sl_family_letter);
        l_od_tbl(1).family_name := pk_dynamic_screen.get_value_str(i_component_name => c_ds_family_name,
                                                                   i_data_val       => i_data_val,
                                                                   i_orig_val       => l_od_tbl(1).family_name);
        l_od_tbl(1).family_address := pk_dynamic_screen.get_value_str(i_component_name => c_ds_family_address,
                                                                      i_data_val       => i_data_val,
                                                                      i_orig_val       => l_od_tbl(1).family_address);
        l_od_tbl(1).id_sl_justice_consent := pk_dynamic_screen.get_value_number(i_component_name => c_ds_justice_consent,
                                                                                i_data_val       => i_data_val,
                                                                                i_orig_val       => l_od_tbl(1)
                                                                                                    .id_sl_justice_consent);
        l_od_tbl(1).id_sl_donor_center := pk_dynamic_screen.get_value_number(i_component_name => c_ds_donor_center,
                                                                             i_data_val       => i_data_val,
                                                                             i_orig_val       => l_od_tbl(1)
                                                                                                 .id_sl_donor_center);
        l_od_tbl(1).reason_donor_center := pk_dynamic_screen.get_value_str(i_component_name => c_ds_reason_donor_center,
                                                                           i_data_val       => i_data_val,
                                                                           i_orig_val       => l_od_tbl(1)
                                                                                               .reason_donor_center);
    
        l_dbg_msg := 'if didn''t find any active organ donor registry insert a new registry else update';
        pk_alertlog.log_info(text => l_dbg_msg, object_name => c_package_name, sub_object_name => c_function_name);
        IF l_od_tbl(1).id_organ_donor IS NULL
        THEN
            l_dbg_msg := 'fill patient, episode and status information';
            pk_alertlog.log_info(text => l_dbg_msg, object_name => c_package_name, sub_object_name => c_function_name);
            l_od_tbl(1).id_patient := i_patient;
            l_od_tbl(1).id_episode := i_episode;
            l_od_tbl(1).flg_status := pk_alert_constant.g_active;
        
            l_dbg_msg := 'get organ donor next key';
            pk_alertlog.log_info(text => l_dbg_msg, object_name => c_package_name, sub_object_name => c_function_name);
            l_od_tbl(1).id_organ_donor := ts_organ_donor.next_key;
        
            l_dbg_msg := 'insert values into organ donor';
            pk_alertlog.log_info(text => l_dbg_msg, object_name => c_package_name, sub_object_name => c_function_name);
            ts_organ_donor.ins(rows_in => l_od_tbl);
        
        ELSE
            l_dbg_msg := 'update death registry values';
            pk_alertlog.log_info(text => l_dbg_msg, object_name => c_package_name, sub_object_name => c_function_name);
            ts_organ_donor.upd(col_in => l_od_tbl, ignore_if_null_in => FALSE);
        
        END IF;
    
        l_dbg_msg := 'set organ donor contagious diseases';
        pk_alertlog.log_info(text => l_dbg_msg, object_name => c_package_name, sub_object_name => c_function_name);
        IF NOT set_donor_contag_disease(i_lang                  => i_lang,
                                        i_prof                  => i_prof,
                                        i_patient               => i_patient,
                                        i_episode               => i_episode,
                                        i_organ_donor           => l_od_tbl(1).id_organ_donor,
                                        i_data_val              => i_data_val,
                                        o_pat_history_diagnosis => l_pat_history_diagnosis,
                                        o_error                 => o_error)
        THEN
            pk_utils.undo_changes;
            o_organ_donor := NULL;
            RETURN FALSE;
        END IF;
    
        l_dbg_msg := 'set donor organ/tissues donations';
        pk_alertlog.log_info(text => l_dbg_msg, object_name => c_package_name, sub_object_name => c_function_name);
        IF NOT set_organ_tissue_don(i_lang         => i_lang,
                                    i_organ_donor  => l_od_tbl(1).id_organ_donor,
                                    i_data_val     => i_data_val,
                                    o_organ_tissue => l_organ_tissue,
                                    o_error        => o_error)
        THEN
            pk_utils.undo_changes;
            o_organ_donor := NULL;
            RETURN FALSE;
        END IF;
    
        l_dbg_msg := 'insert into organ donor history';
        pk_alertlog.log_info(text => l_dbg_msg, object_name => c_package_name, sub_object_name => c_function_name);
        IF NOT set_organ_donor_detail(i_lang             => i_lang,
                                      i_organ_donor      => l_od_tbl(1).id_organ_donor,
                                      o_organ_donor_hist => l_organ_donor_hist,
                                      o_error            => o_error)
        THEN
            pk_utils.undo_changes;
            o_organ_donor := NULL;
            RETURN FALSE;
        END IF;
    
        l_dbg_msg := 'set first obs';
        pk_alertlog.log_info(text => l_dbg_msg, object_name => c_package_name, sub_object_name => c_function_name);
        IF NOT pk_visit.set_first_obs(i_lang                => i_lang,
                                      i_id_episode          => i_episode,
                                      i_pat                 => i_patient,
                                      i_prof                => i_prof,
                                      i_prof_cat_type       => NULL,
                                      i_dt_last_interaction => i_date,
                                      i_dt_first_obs        => i_date,
                                      o_error               => o_error)
        THEN
            pk_utils.undo_changes;
            o_organ_donor := NULL;
            RETURN FALSE;
        END IF;
    
        o_organ_donor := l_od_tbl(1).id_organ_donor;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => l_dbg_msg,
                                              i_owner    => c_package_owner,
                                              i_package  => c_package_name,
                                              i_function => c_function_name,
                                              o_error    => o_error);
        
            pk_utils.undo_changes;
            o_organ_donor := NULL;
            RETURN FALSE;
        
    END set_organ_donor;

    /**********************************************************************************************
    * Get organ donor data
    *
    * @param        i_lang                   Language id
    * @param        i_prof                   Professional, software and institution ids
    * @param        i_patient                Patient id
    * @param        i_status                 Registry status, if null returns with any status
    *                                        (defaults to null)
    * @param        o_data_val               Structure with all data values
    * @param        o_prof_data              Cursor with the professional data
    * @param        o_error                  Error information
    *
    * @return       TRUE if sucess, FALSE otherwise
    *                        
    * @author       Paulo Fonseca
    * @version      2.6.0.3
    * @since        25-Jun-2010
    **********************************************************************************************/
    FUNCTION get_organ_donor_data
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_patient   IN patient.id_patient%TYPE,
        i_status    IN death_registry.flg_status%TYPE DEFAULT NULL,
        o_data_val  OUT table_table_varchar,
        o_prof_data OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
        c_function_name CONSTANT obj_name := 'GET_ORGAN_DONOR_DATA';
        l_dbg_msg debug_msg;
    
        l_od_row organ_donor%ROWTYPE;
    
    BEGIN
        l_dbg_msg := 'get patient organ donor data';
        pk_alertlog.log_info(text => l_dbg_msg, object_name => c_package_name, sub_object_name => c_function_name);
        l_od_row := get_organ_donor_row(i_patient => i_patient, i_status => i_status);
        IF l_od_row.id_organ_donor IS NULL
        THEN
            o_data_val := NULL;
            pk_types.open_my_cursor(i_cursor => o_prof_data);
            RETURN TRUE;
        END IF;
    
        pk_dynamic_screen.set_data_key(l_od_row.id_organ_donor);
    
        l_dbg_msg := 'build structure with death data';
        pk_alertlog.log_info(text => l_dbg_msg, object_name => c_package_name, sub_object_name => c_function_name);
    
        IF NOT get_donor_contag_disease(i_lang        => i_lang,
                                        i_prof        => i_prof,
                                        i_organ_donor => l_od_row.id_organ_donor,
                                        o_data_val    => o_data_val,
                                        o_error       => o_error)
        THEN
            o_data_val := NULL;
            pk_types.open_my_cursor(i_cursor => o_prof_data);
            RETURN FALSE;
        END IF;
    
        o_data_val := pk_dynamic_screen.add_value_sl(i_lang     => i_lang,
                                                     i_prof     => i_prof,
                                                     i_data_val => o_data_val,
                                                     i_name     => c_ds_able_don_organs,
                                                     i_value    => l_od_row.id_sl_able_don_organs);
        o_data_val := pk_dynamic_screen.add_value_text(i_data_val => o_data_val,
                                                       i_name     => c_ds_reason_not_able_don_org,
                                                       i_value    => l_od_row.reason_not_able_don_org);
        o_data_val := pk_dynamic_screen.add_value_sl(i_lang     => i_lang,
                                                     i_prof     => i_prof,
                                                     i_data_val => o_data_val,
                                                     i_name     => c_ds_able_don_tissues,
                                                     i_value    => l_od_row.id_sl_able_don_tissues);
        o_data_val := pk_dynamic_screen.add_value_text(i_data_val => o_data_val,
                                                       i_name     => c_ds_reason_not_able_don_tis,
                                                       i_value    => l_od_row.reason_not_able_don_tis);
        o_data_val := pk_dynamic_screen.add_value_sl(i_lang     => i_lang,
                                                     i_prof     => i_prof,
                                                     i_data_val => o_data_val,
                                                     i_name     => c_ds_will_consulted,
                                                     i_value    => l_od_row.id_sl_will_consulted);
        o_data_val := pk_dynamic_screen.add_value_sl(i_lang     => i_lang,
                                                     i_prof     => i_prof,
                                                     i_data_val => o_data_val,
                                                     i_name     => c_ds_will_result,
                                                     i_value    => l_od_row.id_sl_will_result);
        o_data_val := pk_dynamic_screen.add_value_text(i_data_val => o_data_val,
                                                       i_name     => c_ds_reason_will_not_cons,
                                                       i_value    => l_od_row.reason_will_not_cons);
        o_data_val := pk_dynamic_screen.add_value_sl(i_lang     => i_lang,
                                                     i_prof     => i_prof,
                                                     i_data_val => o_data_val,
                                                     i_name     => c_ds_other_declaration,
                                                     i_value    => l_od_row.id_sl_other_declaration);
        o_data_val := pk_dynamic_screen.add_value_text(i_data_val => o_data_val,
                                                       i_name     => c_ds_other_declaration_notes,
                                                       i_value    => l_od_row.other_declaration_notes);
        o_data_val := pk_dynamic_screen.add_value_sl(i_lang     => i_lang,
                                                     i_prof     => i_prof,
                                                     i_data_val => o_data_val,
                                                     i_name     => c_ds_don_authorized,
                                                     i_value    => l_od_row.id_sl_don_authorized);
        o_data_val := pk_dynamic_screen.add_value_text(i_data_val => o_data_val,
                                                       i_name     => c_ds_responsible_name,
                                                       i_value    => l_od_row.responsible_name);
        o_data_val := pk_dynamic_screen.add_value_fr(i_lang     => i_lang,
                                                     i_data_val => o_data_val,
                                                     i_name     => c_ds_family_relationship,
                                                     i_value    => l_od_row.id_family_relationship);
        o_data_val := pk_dynamic_screen.add_value_text(i_data_val => o_data_val,
                                                       i_name     => c_ds_reason_not_authorized,
                                                       i_value    => l_od_row.reason_not_authorized);
        o_data_val := pk_dynamic_screen.add_value_sl(i_lang     => i_lang,
                                                     i_prof     => i_prof,
                                                     i_data_val => o_data_val,
                                                     i_name     => c_ds_donation_approved,
                                                     i_value    => l_od_row.id_sl_donation_approved);
        o_data_val := pk_dynamic_screen.add_value_sl(i_lang     => i_lang,
                                                     i_prof     => i_prof,
                                                     i_data_val => o_data_val,
                                                     i_name     => c_ds_object_research,
                                                     i_value    => l_od_row.id_sl_object_research);
        o_data_val := pk_dynamic_screen.add_value_text(i_data_val => o_data_val,
                                                       i_name     => c_ds_reason_not_approved,
                                                       i_value    => l_od_row.reason_not_approved);
    
        IF NOT get_organ_tissue_don(i_lang        => i_lang,
                                    i_organ_donor => l_od_row.id_organ_donor,
                                    o_data_val    => o_data_val,
                                    o_error       => o_error)
        THEN
            o_data_val := NULL;
            pk_types.open_my_cursor(i_cursor => o_prof_data);
            RETURN FALSE;
        END IF;
    
        o_data_val := pk_dynamic_screen.add_value_sl(i_lang     => i_lang,
                                                     i_prof     => i_prof,
                                                     i_data_val => o_data_val,
                                                     i_name     => c_ds_family_letter,
                                                     i_value    => l_od_row.id_sl_family_letter);
        o_data_val := pk_dynamic_screen.add_value_text(i_data_val => o_data_val,
                                                       i_name     => c_ds_family_name,
                                                       i_value    => l_od_row.family_name);
        o_data_val := pk_dynamic_screen.add_value_text(i_data_val => o_data_val,
                                                       i_name     => c_ds_family_address,
                                                       i_value    => l_od_row.family_address);
        o_data_val := pk_dynamic_screen.add_value_sl(i_lang     => i_lang,
                                                     i_prof     => i_prof,
                                                     i_data_val => o_data_val,
                                                     i_name     => c_ds_justice_consent,
                                                     i_value    => l_od_row.id_sl_justice_consent);
        o_data_val := pk_dynamic_screen.add_value_sl(i_lang     => i_lang,
                                                     i_prof     => i_prof,
                                                     i_data_val => o_data_val,
                                                     i_name     => c_ds_donor_center,
                                                     i_value    => l_od_row.id_sl_donor_center);
        o_data_val := pk_dynamic_screen.add_value_text(i_data_val => o_data_val,
                                                       i_name     => c_ds_reason_donor_center,
                                                       i_value    => l_od_row.reason_donor_center);
    
        l_dbg_msg := 'get info about the professional that made the registry';
        pk_alertlog.log_info(text => l_dbg_msg, object_name => c_package_name, sub_object_name => c_function_name);
        IF NOT pk_dynamic_screen.get_organ_donor_prof_data(i_lang      => i_lang,
                                                        i_prof          => i_prof,
                                                           i_tbl_id    => table_number(l_od_row.id_organ_donor),
                                                        o_prof_data     => o_prof_data,
                                                        o_error         => o_error)
        THEN
            o_data_val := NULL;
            pk_types.open_my_cursor(i_cursor => o_prof_data);
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => l_dbg_msg,
                                              i_owner    => c_package_owner,
                                              i_package  => c_package_name,
                                              i_function => c_function_name,
                                              o_error    => o_error);
        
            o_data_val := NULL;
            pk_types.open_my_cursor(i_cursor => o_prof_data);
            RETURN FALSE;
        
    END get_organ_donor_data;

    /**********************************************************************************************
    * Get organ donor data history
    *
    * @param        i_lang                   Language id
    * @param        i_prof                   Professional, software and institution ids
    * @param        i_patient                Patient id
    * @param        o_data_val               Structure with all data values history
    * @param        o_prof_data              Cursor with the professional data history
    * @param        o_error                  Error information
    *
    * @return       TRUE if sucess, FALSE otherwise
    *                        
    * @author       Paulo Fonseca
    * @version      2.6.0.3
    * @since        25-Jun-2010
    **********************************************************************************************/
    FUNCTION get_organ_donor_detail
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_patient   IN patient.id_patient%TYPE,
        o_data_val  OUT table_table_varchar,
        o_prof_data OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
        c_function_name CONSTANT obj_name := 'GET_ORGAN_DONOR_DETAIL';
        l_dbg_msg debug_msg;
    
        l_odh_tbl ts_organ_donor_hist.organ_donor_hist_tc;
    
    BEGIN
        l_dbg_msg := 'get organ donor history';
        pk_alertlog.log_info(text => l_dbg_msg, object_name => c_package_name, sub_object_name => c_function_name);
        SELECT odh.* BULK COLLECT
          INTO l_odh_tbl
          FROM organ_donor_hist odh
         WHERE odh.id_patient = i_patient
         ORDER BY odh.dt_organ_donor DESC;
    
        l_dbg_msg := 'build structure with organ donor data';
        pk_alertlog.log_info(text => l_dbg_msg, object_name => c_package_name, sub_object_name => c_function_name);
    
        FOR idx IN 1 .. l_odh_tbl.count()
        LOOP
        
            IF NOT get_don_cont_disease_detail(i_lang             => i_lang,
                                               i_prof             => i_prof,
                                               i_organ_donor_hist => l_odh_tbl(idx).id_organ_donor_hist,
                                               o_data_val         => o_data_val,
                                               o_error            => o_error)
            THEN
                o_data_val := NULL;
                pk_types.open_my_cursor(i_cursor => o_prof_data);
                RETURN FALSE;
            END IF;
        
            o_data_val := pk_dynamic_screen.add_value_sl(i_lang     => i_lang,
                                                         i_prof     => i_prof,
                                                         i_data_val => o_data_val,
                                                         i_name     => c_ds_able_don_organs,
                                                         i_value    => l_odh_tbl(idx).id_sl_able_don_organs,
                                                         i_hist     => l_odh_tbl(idx).id_organ_donor_hist);
            o_data_val := pk_dynamic_screen.add_value_text(i_data_val => o_data_val,
                                                           i_name     => c_ds_reason_not_able_don_org,
                                                           i_value    => l_odh_tbl(idx).reason_not_able_don_org,
                                                           i_hist     => l_odh_tbl(idx).id_organ_donor_hist);
            o_data_val := pk_dynamic_screen.add_value_sl(i_lang     => i_lang,
                                                         i_prof     => i_prof,
                                                         i_data_val => o_data_val,
                                                         i_name     => c_ds_able_don_tissues,
                                                         i_value    => l_odh_tbl(idx).id_sl_able_don_tissues,
                                                         i_hist     => l_odh_tbl(idx).id_organ_donor_hist);
            o_data_val := pk_dynamic_screen.add_value_text(i_data_val => o_data_val,
                                                           i_name     => c_ds_reason_not_able_don_tis,
                                                           i_value    => l_odh_tbl(idx).reason_not_able_don_tis,
                                                           i_hist     => l_odh_tbl(idx).id_organ_donor_hist);
            o_data_val := pk_dynamic_screen.add_value_sl(i_lang     => i_lang,
                                                         i_prof     => i_prof,
                                                         i_data_val => o_data_val,
                                                         i_name     => c_ds_will_consulted,
                                                         i_value    => l_odh_tbl(idx).id_sl_will_consulted,
                                                         i_hist     => l_odh_tbl(idx).id_organ_donor_hist);
            o_data_val := pk_dynamic_screen.add_value_sl(i_lang     => i_lang,
                                                         i_prof     => i_prof,
                                                         i_data_val => o_data_val,
                                                         i_name     => c_ds_will_result,
                                                         i_value    => l_odh_tbl(idx).id_sl_will_result,
                                                         i_hist     => l_odh_tbl(idx).id_organ_donor_hist);
            o_data_val := pk_dynamic_screen.add_value_text(i_data_val => o_data_val,
                                                           i_name     => c_ds_reason_will_not_cons,
                                                           i_value    => l_odh_tbl(idx).reason_will_not_cons,
                                                           i_hist     => l_odh_tbl(idx).id_organ_donor_hist);
            o_data_val := pk_dynamic_screen.add_value_sl(i_lang     => i_lang,
                                                         i_prof     => i_prof,
                                                         i_data_val => o_data_val,
                                                         i_name     => c_ds_other_declaration,
                                                         i_value    => l_odh_tbl(idx).id_sl_other_declaration,
                                                         i_hist     => l_odh_tbl(idx).id_organ_donor_hist);
            o_data_val := pk_dynamic_screen.add_value_text(i_data_val => o_data_val,
                                                           i_name     => c_ds_other_declaration_notes,
                                                           i_value    => l_odh_tbl(idx).other_declaration_notes,
                                                           i_hist     => l_odh_tbl(idx).id_organ_donor_hist);
            o_data_val := pk_dynamic_screen.add_value_sl(i_lang     => i_lang,
                                                         i_prof     => i_prof,
                                                         i_data_val => o_data_val,
                                                         i_name     => c_ds_don_authorized,
                                                         i_value    => l_odh_tbl(idx).id_sl_don_authorized,
                                                         i_hist     => l_odh_tbl(idx).id_organ_donor_hist);
            o_data_val := pk_dynamic_screen.add_value_text(i_data_val => o_data_val,
                                                           i_name     => c_ds_responsible_name,
                                                           i_value    => l_odh_tbl(idx).responsible_name,
                                                           i_hist     => l_odh_tbl(idx).id_organ_donor_hist);
            o_data_val := pk_dynamic_screen.add_value_fr(i_lang     => i_lang,
                                                         i_data_val => o_data_val,
                                                         i_name     => c_ds_family_relationship,
                                                         i_value    => l_odh_tbl(idx).id_family_relationship,
                                                         i_hist     => l_odh_tbl(idx).id_organ_donor_hist);
            o_data_val := pk_dynamic_screen.add_value_text(i_data_val => o_data_val,
                                                           i_name     => c_ds_reason_not_authorized,
                                                           i_value    => l_odh_tbl(idx).reason_not_authorized,
                                                           i_hist     => l_odh_tbl(idx).id_organ_donor_hist);
            o_data_val := pk_dynamic_screen.add_value_sl(i_lang     => i_lang,
                                                         i_prof     => i_prof,
                                                         i_data_val => o_data_val,
                                                         i_name     => c_ds_donation_approved,
                                                         i_value    => l_odh_tbl(idx).id_sl_donation_approved,
                                                         i_hist     => l_odh_tbl(idx).id_organ_donor_hist);
            o_data_val := pk_dynamic_screen.add_value_sl(i_lang     => i_lang,
                                                         i_prof     => i_prof,
                                                         i_data_val => o_data_val,
                                                         i_name     => c_ds_object_research,
                                                         i_value    => l_odh_tbl(idx).id_sl_object_research,
                                                         i_hist     => l_odh_tbl(idx).id_organ_donor_hist);
            o_data_val := pk_dynamic_screen.add_value_text(i_data_val => o_data_val,
                                                           i_name     => c_ds_reason_not_approved,
                                                           i_value    => l_odh_tbl(idx).reason_not_approved,
                                                           i_hist     => l_odh_tbl(idx).id_organ_donor_hist);
        
            IF NOT get_organ_tissue_don_detail(i_lang             => i_lang,
                                               i_organ_donor_hist => l_odh_tbl(idx).id_organ_donor_hist,
                                               o_data_val         => o_data_val,
                                               o_error            => o_error)
            THEN
                o_data_val := NULL;
                pk_types.open_my_cursor(i_cursor => o_prof_data);
                RETURN FALSE;
            END IF;
        
            o_data_val := pk_dynamic_screen.add_value_sl(i_lang     => i_lang,
                                                         i_prof     => i_prof,
                                                         i_data_val => o_data_val,
                                                         i_name     => c_ds_family_letter,
                                                         i_value    => l_odh_tbl(idx).id_sl_family_letter,
                                                         i_hist     => l_odh_tbl(idx).id_organ_donor_hist);
            o_data_val := pk_dynamic_screen.add_value_text(i_data_val => o_data_val,
                                                           i_name     => c_ds_family_name,
                                                           i_value    => l_odh_tbl(idx).family_name,
                                                           i_hist     => l_odh_tbl(idx).id_organ_donor_hist);
            o_data_val := pk_dynamic_screen.add_value_text(i_data_val => o_data_val,
                                                           i_name     => c_ds_family_address,
                                                           i_value    => l_odh_tbl(idx).family_address,
                                                           i_hist     => l_odh_tbl(idx).id_organ_donor_hist);
            o_data_val := pk_dynamic_screen.add_value_sl(i_lang     => i_lang,
                                                         i_prof     => i_prof,
                                                         i_data_val => o_data_val,
                                                         i_name     => c_ds_justice_consent,
                                                         i_value    => l_odh_tbl(idx).id_sl_justice_consent,
                                                         i_hist     => l_odh_tbl(idx).id_organ_donor_hist);
            o_data_val := pk_dynamic_screen.add_value_sl(i_lang     => i_lang,
                                                         i_prof     => i_prof,
                                                         i_data_val => o_data_val,
                                                         i_name     => c_ds_donor_center,
                                                         i_value    => l_odh_tbl(idx).id_sl_donor_center,
                                                         i_hist     => l_odh_tbl(idx).id_organ_donor_hist);
            o_data_val := pk_dynamic_screen.add_value_text(i_data_val => o_data_val,
                                                           i_name     => c_ds_reason_donor_center,
                                                           i_value    => l_odh_tbl(idx).reason_donor_center,
                                                           i_hist     => l_odh_tbl(idx).id_organ_donor_hist);
        
        END LOOP;
    
        l_dbg_msg := 'get info about the professional that made the registries';
        pk_alertlog.log_info(text => l_dbg_msg, object_name => c_package_name, sub_object_name => c_function_name);
        IF NOT get_od_hist_prof_data(i_lang      => i_lang,
                                     i_prof      => i_prof,
                                     i_patient   => i_patient,
                                     o_prof_data => o_prof_data,
                                     o_error     => o_error)
        THEN
            o_data_val := NULL;
            pk_types.open_my_cursor(i_cursor => o_prof_data);
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => l_dbg_msg,
                                              i_owner    => c_package_owner,
                                              i_package  => c_package_name,
                                              i_function => c_function_name,
                                              o_error    => o_error);
        
            o_data_val := NULL;
            pk_types.open_my_cursor(i_cursor => o_prof_data);
            RETURN FALSE;
        
    END get_organ_donor_detail;

    /**********************************************************************************************
    * Cancel organ donor
    *
    * @param        i_lang                   Language id
    * @param        i_prof                   Professional, software and institution ids
    * @param        i_date                   Cancel date
    * @param        i_patient                Patient id
    * @param        i_episode                Episode id
    * @param        i_cancel_reason          Cancel reason id
    * @param        i_notes_cancel           Cancel notes
    * @param        o_error                  Error information
    *
    * @return       TRUE if sucess, FALSE otherwise
    *                        
    * @author       Filipe Machado
    * @version      2.6.0.3
    * @since        18-Jun-2010
    **********************************************************************************************/
    FUNCTION cancel_organ_donor
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_date          IN death_registry.dt_death_registry%TYPE,
        i_patient       IN patient.id_patient%TYPE,
        i_episode       IN episode.id_episode%TYPE,
        i_cancel_reason IN cancel_reason.id_cancel_reason%TYPE,
        i_notes_cancel  IN death_registry.notes_cancel%TYPE,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        c_function_name CONSTANT obj_name := 'CANCEL_ORGAN_DONOR';
        l_dbg_msg debug_msg;
    
        l_od_tbl           ts_organ_donor.organ_donor_tc;
        l_organ_donor_hist organ_donor_hist.id_organ_donor_hist%TYPE;
    
    BEGIN
        l_dbg_msg := 'get organ donor data, if exists';
        pk_alertlog.log_info(text => l_dbg_msg, object_name => c_package_name, sub_object_name => c_function_name);
        l_od_tbl(1) := get_organ_donor_row(i_patient => i_patient, i_status => pk_alert_constant.g_active);
        IF l_od_tbl(1).id_organ_donor IS NULL
        THEN
            RETURN TRUE;
        END IF;
    
        l_dbg_msg := 'set organ donor cancel information';
        pk_alertlog.log_info(text => l_dbg_msg, object_name => c_package_name, sub_object_name => c_function_name);
        l_od_tbl(1).flg_status := pk_alert_constant.g_cancelled;
        l_od_tbl(1).id_prof_organ_donor := i_prof.id;
        l_od_tbl(1).dt_organ_donor := i_date;
        l_od_tbl(1).id_cancel_reason := i_cancel_reason;
        l_od_tbl(1).notes_cancel := i_notes_cancel;
        ts_organ_donor.upd(col_in => l_od_tbl, ignore_if_null_in => FALSE);
    
        l_dbg_msg := 'insert into organ donor history';
        pk_alertlog.log_info(text => l_dbg_msg, object_name => c_package_name, sub_object_name => c_function_name);
        IF NOT set_organ_donor_detail(i_lang             => i_lang,
                                      i_organ_donor      => l_od_tbl(1).id_organ_donor,
                                      o_organ_donor_hist => l_organ_donor_hist,
                                      o_error            => o_error)
        THEN
            pk_utils.undo_changes;
            RETURN FALSE;
        END IF;
    
        l_dbg_msg := 'set first obs';
        pk_alertlog.log_info(text => l_dbg_msg, object_name => c_package_name, sub_object_name => c_function_name);
        IF NOT pk_visit.set_first_obs(i_lang                => i_lang,
                                      i_id_episode          => i_episode,
                                      i_pat                 => i_patient,
                                      i_prof                => i_prof,
                                      i_prof_cat_type       => NULL,
                                      i_dt_last_interaction => i_date,
                                      i_dt_first_obs        => i_date,
                                      o_error               => o_error)
        THEN
            pk_utils.undo_changes;
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => l_dbg_msg,
                                              i_owner    => c_package_owner,
                                              i_package  => c_package_name,
                                              i_function => c_function_name,
                                              o_error    => o_error);
        
            pk_utils.undo_changes;
            RETURN FALSE;
        
    END cancel_organ_donor;

    /**********************************************************************************************
    * Returns the contagious diseases list
    *
    * @param        i_lang                   Language id
    * @param        i_prof                   Professional, software and institution ids
    * @param        o_diagnosis              Cursor with diagnosis list for contagious diseases 
    * @param        o_error                  Error information
    *
    * @return       TRUE if sucess, FALSE otherwise
    *                        
    * @author       Filipe Machado
    * @version      2.6.0.3
    * @since        08-Jun-2010
    **********************************************************************************************/
    FUNCTION get_contagious_diseases
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        o_diagnosis OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
        c_function_name CONSTANT obj_name := 'GET_CONTAGIOUS_DISEASES';
        l_dbg_msg debug_msg;
    
    BEGIN
        l_dbg_msg := 'get contagious diseases list';
        pk_alertlog.log_info(text => l_dbg_msg, object_name => c_package_name, sub_object_name => c_function_name);
        OPEN o_diagnosis FOR
            SELECT cad.id_diagnosis, cad.id_alert_diagnosis, cad.label
              FROM (SELECT cd.id_diagnosis,
                           cd.id_alert_diagnosis,
                           pk_diagnosis.std_diag_desc(i_lang               => i_lang,
                                                      i_prof               => i_prof,
                                                      i_id_alert_diagnosis => cd.id_alert_diagnosis,
                                                      i_code_diagnosis     => cd.code_problems,
                                                      i_diagnosis_language => cd.id_language,
                                                      i_code               => cd.code_icd,
                                                      i_flg_other          => cd.flg_other,
                                                      i_flg_std_diag       => cd.flg_icd9) AS label
                      FROM (SELECT d.id_diagnosis,
                                   d.id_alert_diagnosis,
                                   d.code_problems,
                                   d.id_language,
                                   d.code_icd,
                                   d.flg_other,
                                   d.flg_icd9
                              FROM diagnosis_content d
                             WHERE d.code_problems IS NOT NULL
                               AND d.id_institution = i_prof.institution
                               AND d.id_software = i_prof.software
                               AND d.flg_type_dep_clin = pk_diagnosis.g_diag_pesq
                               AND d.flg_type IN
                                   (SELECT /*+opt_estimate(table,tdgc,scale_rows=1))*/
                                     column_value flg_terminology
                                      FROM TABLE(pk_diagnosis_core.get_diag_terminologies(i_lang      => i_lang,
                                                                                          i_prof      => i_prof,
                                                                                          i_task_type => pk_alert_constant.g_task_problems)) tdgc)
                               AND EXISTS
                             (SELECT 1
                                      FROM diag_diag_condition ddc
                                     WHERE d.id_diagnosis = ddc.id_diagnosis
                                       AND ddc.id_software IN (i_prof.software, pk_alert_constant.g_soft_all)
                                       AND ddc.id_institution IN (i_prof.institution, pk_alert_constant.g_inst_all))) cd) cad
             WHERE cad.label IS NOT NULL
             ORDER BY cad.label ASC;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => l_dbg_msg,
                                              i_owner    => c_package_owner,
                                              i_package  => c_package_name,
                                              i_function => c_function_name,
                                              o_error    => o_error);
        
            pk_types.open_my_cursor(i_cursor => o_diagnosis);
            RETURN FALSE;
        
    END get_contagious_diseases;

    /**********************************************************************************************
    * Returns the patient contagious diseases list
    *
    * @param        i_lang                   Language id
    * @param        i_prof                   Professional, software and institution ids
    * @param        i_patient                Patient id
    * @param        o_diagnosis              Cursor with the patient diagnosis list for
    *                                        contagious diseases
    * @param        o_error                  Error information
    *
    * @return       TRUE if sucess, FALSE otherwise
    *                        
    * @author       Filipe Machado
    * @version      2.6.0.3
    * @since        09-Jun-2010
    **********************************************************************************************/
    FUNCTION get_pat_contagious_diseases
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_patient   IN patient.id_patient%TYPE,
        o_diagnosis OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
        c_function_name CONSTANT obj_name := 'GET_PAT_CONTAGIOUS_DISEASES';
        l_dbg_msg debug_msg;
    
    BEGIN
        l_dbg_msg := 'get patient contagious diseases';
        pk_alertlog.log_info(text => l_dbg_msg, object_name => c_package_name, sub_object_name => c_function_name);
        OPEN o_diagnosis FOR
            SELECT phd.id_diagnosis,
                   phd.id_alert_diagnosis,
                   phd.id_pat_history_diagnosis,
                   decode(phd.id_alert_diagnosis,
                          NULL,
                          phd.desc_pat_history_diagnosis,
                          decode(phd.desc_pat_history_diagnosis, NULL, NULL, phd.desc_pat_history_diagnosis || ' - ') ||
                          pk_diagnosis.std_diag_desc(i_lang         => i_lang,
                                                     i_prof         => i_prof,
                                                     i_id_diagnosis => d.id_diagnosis,
                                                     i_code         => d.code_icd,
                                                     i_flg_other    => d.flg_other,
                                                     i_flg_std_diag => ad.flg_icd9)) AS label
              FROM pat_history_diagnosis phd
             INNER JOIN diagnosis d
                ON phd.id_diagnosis = d.id_diagnosis
              LEFT OUTER JOIN alert_diagnosis ad
                ON phd.id_alert_diagnosis = ad.id_alert_diagnosis
               AND ad.flg_type = pk_summary_page.g_alert_diag_type_med
             WHERE phd.flg_status = pk_alert_constant.g_active
               AND phd.id_patient = i_patient
               AND instr(phd.flg_type, pk_summary_page.g_alert_diag_type_med) > 0
               AND EXISTS (SELECT 1
                      FROM diag_diag_condition ddc
                     WHERE phd.id_diagnosis = ddc.id_diagnosis
                       AND ddc.id_software IN (i_prof.software, pk_alert_constant.g_soft_all)
                       AND ddc.id_institution IN (i_prof.institution, pk_alert_constant.g_inst_all))
             ORDER BY label;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => l_dbg_msg,
                                              i_owner    => c_package_owner,
                                              i_package  => c_package_name,
                                              i_function => c_function_name,
                                              o_error    => o_error);
        
            pk_types.open_my_cursor(i_cursor => o_diagnosis);
            RETURN FALSE;
        
    END get_pat_contagious_diseases;

    /**********************************************************************************************
    * Changes the patient id in a organ donor registry (This function should only be called
    * by pk_api_edis.set_episode_new_patient or pk_match.set_match_all_pat_internal)
    *
    * @param        i_lang                   Language id
    * @param        i_new_patient            New patient id
    * @param        i_old_patient            Old patient id, if null searches for episode id
    *                                        (defaults to null)
    * @param        i_episode                Episode id, if null searches for old patient id
    *                                        (defaults to null)
    * @param        o_error                  Error information
    *
    * @return       TRUE if sucess, FALSE otherwise
    *                        
    * @author       Paulo Fonseca
    * @version      2.6.0.3
    * @since        16-Jul-2010
    **********************************************************************************************/
    FUNCTION change_donor_patient_id
    (
        i_lang        IN language.id_language%TYPE,
        i_new_patient IN organ_donor.id_patient%TYPE,
        i_old_patient IN organ_donor.id_patient%TYPE DEFAULT NULL,
        i_episode     IN organ_donor.id_episode%TYPE DEFAULT NULL,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        c_function_name CONSTANT obj_name := 'CHANGE_DONOR_PATIENT_ID';
        l_dbg_msg debug_msg;
    
        l_where VARCHAR2(200 CHAR);
    
    BEGIN
        IF i_old_patient IS NOT NULL
        THEN
            l_where := ' id_patient = ' || i_old_patient;
        
        ELSIF i_episode IS NOT NULL
        THEN
            l_where := ' id_episode = ' || i_episode;
        
        ELSE
            l_dbg_msg := 'Temporary patient id or episode id must be filled';
            pk_alertlog.log_info(text => l_dbg_msg, object_name => c_package_name, sub_object_name => c_function_name);
            RETURN FALSE;
        
        END IF;
    
        l_dbg_msg := 'update patient id for all registries';
        pk_alertlog.log_info(text => l_dbg_msg, object_name => c_package_name, sub_object_name => c_function_name);
        ts_organ_donor.upd(id_patient_in => i_new_patient, id_patient_nin => FALSE, where_in => l_where);
    
        l_dbg_msg := 'update patient id for all history registries';
        pk_alertlog.log_info(text => l_dbg_msg, object_name => c_package_name, sub_object_name => c_function_name);
        ts_organ_donor_hist.upd(id_patient_in => i_new_patient, id_patient_nin => FALSE, where_in => l_where);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => l_dbg_msg,
                                              i_owner    => c_package_owner,
                                              i_package  => c_package_name,
                                              i_function => c_function_name,
                                              o_error    => o_error);
        
            pk_utils.undo_changes;
            RETURN FALSE;
        
    END change_donor_patient_id;

    /**********************************************************************************************
    * Changes the episode id in a organ donor registry (This function should only be called
    * by pk_match.set_match_core)
    *
    * @param        i_lang                   Language id
    * @param        i_new_episode            New episode id
    * @param        i_old_episode            Old episode id
    * @param        o_error                  Error information
    *
    * @return       TRUE if sucess, FALSE otherwise
    *                        
    * @author       Paulo Fonseca
    * @version      2.6.0.3
    * @since        16-Jul-2010
    **********************************************************************************************/
    FUNCTION change_donor_episode_id
    (
        i_lang        IN language.id_language%TYPE,
        i_new_episode IN organ_donor.id_episode%TYPE,
        i_old_episode IN organ_donor.id_episode%TYPE,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        c_function_name CONSTANT obj_name := 'CHANGE_DONOR_EPISODE_ID';
        l_dbg_msg debug_msg;
    
        l_where VARCHAR2(200 CHAR);
    
    BEGIN
        l_where := ' id_episode = ' || i_old_episode;
    
        l_dbg_msg := 'update episode id for all registries';
        pk_alertlog.log_info(text => l_dbg_msg, object_name => c_package_name, sub_object_name => c_function_name);
        ts_organ_donor.upd(id_episode_in => i_new_episode, id_episode_nin => FALSE, where_in => l_where);
    
        l_dbg_msg := 'update episode id for all history registries';
        pk_alertlog.log_info(text => l_dbg_msg, object_name => c_package_name, sub_object_name => c_function_name);
        ts_organ_donor_hist.upd(id_episode_in => i_new_episode, id_episode_nin => FALSE, where_in => l_where);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => l_dbg_msg,
                                              i_owner    => c_package_owner,
                                              i_package  => c_package_name,
                                              i_function => c_function_name,
                                              o_error    => o_error);
        
            pk_utils.undo_changes;
            RETURN FALSE;
        
    END change_donor_episode_id;

--
-- INITIALIZATION SECTION
-- 

BEGIN
    -- Initializes log context
    pk_alertlog.log_init(object_name => c_package_name);
END pk_organ_donor;
/
