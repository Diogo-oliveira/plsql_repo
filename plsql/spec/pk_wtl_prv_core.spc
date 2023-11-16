/*-- Last Change Revision: $Rev: 2015419 $*/
/*-- Last Change by: $Author: ana.matos $*/
/*-- Date of last change: $Date: 2022-05-30 09:31:54 +0100 (seg, 30 mai 2022) $*/

CREATE OR REPLACE PACKAGE pk_wtl_prv_core IS

    -- Waiting List status
    g_wtlist_status_active    CONSTANT waiting_list.flg_status%TYPE := 'A';
    g_wtlist_status_partial   CONSTANT waiting_list.flg_status%TYPE := 'P';
    g_wtlist_status_inactive  CONSTANT waiting_list.flg_status%TYPE := 'I';
    g_wtlist_status_schedule  CONSTANT waiting_list.flg_status%TYPE := 'S';
    g_wtlist_status_cancelled CONSTANT waiting_list.flg_status%TYPE := 'C';

    -- Waiting List type
    g_wtlist_type_surgery CONSTANT waiting_list.flg_type%TYPE := 'S';
    g_wtlist_type_bed     CONSTANT waiting_list.flg_type%TYPE := 'B';
    g_wtlist_type_both    CONSTANT waiting_list.flg_type%TYPE := 'A';

    -- Episode type
    g_id_epis_type_surgery   CONSTANT epis_type.id_epis_type%TYPE := 4;
    g_id_epis_type_inpatient CONSTANT epis_type.id_epis_type%TYPE := 5;

    -- Waiting List/Episode Satus
    g_wtl_epis_st_schedule        CONSTANT wtl_epis.flg_status%TYPE := 'S';
    g_wtl_epis_st_not_schedule    CONSTANT wtl_epis.flg_status%TYPE := 'N';
    g_wtl_epis_st_cancel_schedule CONSTANT wtl_epis.flg_status%TYPE := 'C';
    g_wtl_epis_st_no_show         CONSTANT wtl_epis.flg_status%TYPE := 'P'; --patient did not show option

    -- waiting list/dep_clin_serv
    g_wtl_dcs_type_specialty CONSTANT wtl_dep_clin_serv.flg_type%TYPE := 'S';
    g_wtl_dcs_type_ext_disc  CONSTANT wtl_dep_clin_serv.flg_type%TYPE := 'E';

    -- sr_epis_interv
    g_sr_epis_interv_status_c CONSTANT sr_epis_interv.flg_status%TYPE := 'C';

    --wtl_documentation.flg_type
    g_wtl_doc_type_b CONSTANT wtl_documentation.flg_type%TYPE := 'B';

    --wtl_documentation.flg_status
    g_wtl_doc_status_a CONSTANT wtl_documentation.flg_status%TYPE := 'A';
    g_wtl_doc_status_i CONSTANT wtl_documentation.flg_status%TYPE := 'I';
    g_wtl_doc_status_p CONSTANT wtl_documentation.flg_status%TYPE := 'P';
    g_wtl_doc_status_s CONSTANT wtl_documentation.flg_status%TYPE := 'S';

    --sys_domain values: Waiting list status
    g_waiting_pos_decision_w CONSTANT VARCHAR2(30) := 'W';
    g_incomplete_i           CONSTANT VARCHAR2(30) := 'I';
    g_wl_canceled_c          CONSTANT VARCHAR2(30) := 'C';

    /* Indexes for call arguments (i_args) */
    -- SURGERY INDEXES
    idx_flg_status             CONSTANT NUMBER(2) := 1; --csv
    idx_dpb                    CONSTANT NUMBER(2) := 2;
    idx_dpa                    CONSTANT NUMBER(2) := 3;
    idx_ids_dcs                CONSTANT NUMBER(2) := 4; --csv
    idx_ids_surgeons           CONSTANT NUMBER(2) := 5; --csv
    idx_ids_procedures         CONSTANT NUMBER(2) := 6; --csv
    idx_id_sched_cancel_reason CONSTANT NUMBER(2) := 7;
    idx_bsn                    CONSTANT NUMBER(2) := 8;
    idx_ssn                    CONSTANT NUMBER(2) := 9;
    idx_recnum                 CONSTANT NUMBER(2) := 10;
    idx_birthdate              CONSTANT NUMBER(2) := 11;
    idx_gender                 CONSTANT NUMBER(2) := 12;
    idx_surnameprefix          CONSTANT NUMBER(2) := 13;
    idx_surnamemaiden          CONSTANT NUMBER(2) := 14;
    idx_names                  CONSTANT NUMBER(2) := 15;
    idx_initials               CONSTANT NUMBER(2) := 16;
    idx_referral               CONSTANT NUMBER(2) := 17;
    idx_nhn                    CONSTANT NUMBER(2) := 18;
    idx_pat_id                 CONSTANT NUMBER(2) := 19;
    idx_dest_inst              CONSTANT NUMBER(2) := 20; --csv --destiny institution

    g_wtl waiting_list%ROWTYPE;

    /* Indexes for inpatient call arguments (i_args_inp) */
    -- ADMISSION INDEXES
    idx_inp_surg_status   CONSTANT NUMBER(2) := 1; --csv
    idx_inp_dpb           CONSTANT NUMBER(2) := 2;
    idx_inp_dpa           CONSTANT NUMBER(2) := 3;
    idx_inp_ids_dcs       CONSTANT NUMBER(2) := 4; --csv
    idx_inp_ids_ward      CONSTANT NUMBER(2) := 5; --csv
    idx_inp_id_adm_phys   CONSTANT NUMBER(2) := 6; --csv
    idx_inp_id_ind_adm    CONSTANT NUMBER(2) := 7; --csv
    idx_inp_cancel_reason CONSTANT NUMBER(2) := 8; --csv
    idx_inp_adm_duration  CONSTANT NUMBER(2) := 9;
    idx_inp_bsn           CONSTANT NUMBER(2) := 10;
    idx_inp_ssn           CONSTANT NUMBER(2) := 11;
    idx_inp_recnum        CONSTANT NUMBER(2) := 12;
    idx_inp_birthdate     CONSTANT NUMBER(2) := 13;
    idx_inp_gender        CONSTANT NUMBER(2) := 14;
    idx_inp_surnameprefix CONSTANT NUMBER(2) := 15;
    idx_inp_surnamemaiden CONSTANT NUMBER(2) := 16;
    idx_inp_names         CONSTANT NUMBER(2) := 17;
    idx_inp_initials      CONSTANT NUMBER(2) := 18;
    idx_inp_wtl_ids       CONSTANT NUMBER(2) := 19; --csv
    idx_inp_flg_search    CONSTANT NUMBER(2) := 20;
    idx_inp_referral      CONSTANT NUMBER(2) := 21;
    idx_inp_nhn           CONSTANT NUMBER(2) := 22;
    idx_inp_pat_id        CONSTANT NUMBER(2) := 23;
    idx_inp_dest_inst     CONSTANT NUMBER(2) := 24; --csv --destiny institution

    -----------------
    --- NEW SCHEDULER 
    -----------------
    -- associative array type to hold the search values sent to the WL search and detail functions.
    --The index is the value of the above criteria indexes. 
    --Telmo - 17-12-2009
    TYPE t_hashtable IS TABLE OF VARCHAR2(32767) INDEX BY PLS_INTEGER;

    --waiting list output columns 
    ix_out_relative_urgency CONSTANT NUMBER(2) := 1;
    ix_out_id_patient       CONSTANT NUMBER(2) := 2;
    ix_out_pat_name         CONSTANT NUMBER(2) := 3;
    ix_out_id_dcs           CONSTANT NUMBER(2) := 4; -- dcs do episodio de cirurgia
    ix_out_dcs_name         CONSTANT NUMBER(2) := 5;
    ix_out_id_prof          CONSTANT NUMBER(2) := 6;
    ix_out_prof_name        CONSTANT NUMBER(2) := 7;
    ix_out_id_procedure     CONSTANT NUMBER(2) := 8;
    ix_out_proc_name        CONSTANT NUMBER(2) := 9; --SURGERY_REQUEST_T001
    ix_out_id_ward          CONSTANT NUMBER(2) := 10;
    ix_out_ward_name        CONSTANT NUMBER(2) := 11;
    ix_out_id_ind_adm       CONSTANT NUMBER(2) := 12;
    ix_out_id_ind_adm_name  CONSTANT NUMBER(2) := 13; --ADM_REQUEST_T001
    ix_out_dt_surgery       CONSTANT NUMBER(2) := 14; --SURG_ADM_REQUEST_T007
    ix_out_adm_location     CONSTANT NUMBER(2) := 15; --ADM_REQUEST_T008

    ix_out_adm_service      CONSTANT NUMBER(2) := 16; --ADM_REQUEST_T009
    ix_out_diagnosis        CONSTANT NUMBER(2) := 17; --ADM_REQUEST_T028
    ix_out_adm_speciality   CONSTANT NUMBER(2) := 18; --ADM_REQUEST_T029
    ix_out_adm_physic       CONSTANT NUMBER(2) := 19; --ADM_REQUEST_T030
    ix_out_adm_type         CONSTANT NUMBER(2) := 20; --ADM_REQUEST_T031
    ix_out_adm_exp_duration CONSTANT NUMBER(2) := 21; --ADM_REQUEST_T032
    ix_out_preparation      CONSTANT NUMBER(2) := 22; --ADM_REQUEST_T033
    ix_out_room_type        CONSTANT NUMBER(2) := 23; --ADM_REQUEST_T034

    ix_out_mix_nurs CONSTANT NUMBER(2) := 24; --ADM_REQUEST_T035
    ix_out_bed_type CONSTANT NUMBER(2) := 25; --ADM_REQUEST_T036

    ix_out_pref_room            CONSTANT NUMBER(2) := 26; --ADM_REQUEST_T037
    ix_out_nurs_int_need        CONSTANT NUMBER(2) := 27; --ADM_REQUEST_T038
    ix_out_sugg_int_date        CONSTANT NUMBER(2) := 28; --ADM_REQUEST_T039
    ix_out_notes                CONSTANT NUMBER(2) := 29; --ADM_REQUEST_T040
    ix_out_nurs_int_loc         CONSTANT NUMBER(2) := 30; --ADM_REQUEST_T052
    ix_out_sch_per_start        CONSTANT NUMBER(2) := 31; --SURG_ADM_REQUEST_T002
    ix_out_urg_level            CONSTANT NUMBER(2) := 32; --SURG_ADM_REQUEST_T003
    ix_out_sch_per_end          CONSTANT NUMBER(2) := 33; --SURG_ADM_REQUEST_T004
    ix_out_min_time_infor       CONSTANT NUMBER(2) := 34; --SURG_ADM_REQUEST_T005
    ix_out_sugg_surg_date       CONSTANT NUMBER(2) := 35; --SURG_ADM_REQUEST_T006
    ix_out_adm_date             CONSTANT NUMBER(2) := 36; --SURG_ADM_REQUEST_T008
    ix_out_unav_start           CONSTANT NUMBER(2) := 37; --SURG_ADM_REQUEST_T010
    ix_out_unav_end             CONSTANT NUMBER(2) := 38; --SURG_ADM_REQUEST_T011
    ix_out_duration             CONSTANT NUMBER(2) := 39; --SURG_ADM_REQUEST_T013
    ix_out_sug_adm_date         CONSTANT NUMBER(2) := 40; --SURG_ADM_REQUEST_T014
    ix_out_rec_num              CONSTANT NUMBER(2) := 41; --SURG_ADM_REQUEST_T037
    ix_out_surg_spec            CONSTANT NUMBER(2) := 42; --SURGERY_REQUEST_T010
    ix_out_pref_surgeon         CONSTANT NUMBER(2) := 43; --SURGERY_REQUEST_T011
    ix_out_surg_exp_duration    CONSTANT NUMBER(2) := 44; --SURGERY_REQUEST_T012
    ix_out_icu                  CONSTANT NUMBER(2) := 45; --SURGERY_REQUEST_T013
    ix_out_ext_disc             CONSTANT NUMBER(2) := 46; --SURGERY_REQUEST_T014
    ix_out_dang_contam          CONSTANT NUMBER(2) := 47; --SURGERY_REQUEST_T015
    ix_out_pref_time            CONSTANT NUMBER(2) := 48; --SURGERY_REQUEST_T016
    ix_out_pref_time_reason     CONSTANT NUMBER(2) := 49; --SURGERY_REQUEST_T017
    ix_out_pos_decision         CONSTANT NUMBER(2) := 50; --SURGERY_REQUEST_T018
    ix_out_surg_notes           CONSTANT NUMBER(2) := 51; --SURGERY_REQUEST_T019
    ix_out_surg_needed          CONSTANT NUMBER(2) := 52; --SURGERY_REQUEST_T034
    ix_out_surg_location        CONSTANT NUMBER(2) := 53; -- nao tem sys_message
    ix_out_surg_room            CONSTANT NUMBER(2) := 54; -- nao tem sys_message
    ix_out_pat_gender           CONSTANT NUMBER(2) := 55; -- nao tem sys_message
    ix_out_pat_age              CONSTANT NUMBER(2) := 56; -- nao tem sys_message
    ix_out_dt_dpa               CONSTANT NUMBER(2) := 57; -- nao tem sys_message
    ix_out_clin_serv            CONSTANT NUMBER(2) := 58; -- nao tem sys_message
    ix_out_adm_needed           CONSTANT NUMBER(2) := 59; -- nao tem sys_message
    ix_out_flg_type             CONSTANT NUMBER(2) := 60; -- nao tem sys_message
    ix_out_flg_status           CONSTANT NUMBER(2) := 61; -- nao tem sys_message
    ix_out_dt_dpb               CONSTANT NUMBER(2) := 62; -- nao tem sys_message
    ix_out_dt_cancel_date       CONSTANT NUMBER(2) := 63; -- nao tem sys_message
    ix_out_cancel_reason        CONSTANT NUMBER(2) := 64; -- nao tem sys_message
    ix_out_id_dcs_inp           CONSTANT NUMBER(2) := 65; -- dcs do episodio de internamento
    ix_out_barthel_num          CONSTANT NUMBER(2) := 70; --SURG_ADM_REQUEST_T080
    ix_out_pos_validation       CONSTANT NUMBER(2) := 71; -- SR_POS_M002
    ix_out_pos_validation_notes CONSTANT NUMBER(2) := 72; -- SR_POS_M004
    ix_out_surg_proc_id_content CONSTANT NUMBER(2) := 73; -- nao tem sys_message
    ix_out_ward_list            CONSTANT NUMBER(2) := 74; --ADM_REQUEST_T065
    ix_out_ward_list_flg_esc    CONSTANT NUMBER(2) := 75; -- nao tem sys_message
    ix_out_id_adm_service       CONSTANT NUMBER(2) := 76; -- nao tem sys_message
    ix_out_id_adm_type          CONSTANT NUMBER(2) := 77; -- nao tem sys_message
    ix_out_id_room_type         CONSTANT NUMBER(2) := 78; -- nao tem sys_message
    ix_out_id_bed_type          CONSTANT NUMBER(2) := 79; -- nao tem sys_message
    ix_out_id_pref_room         CONSTANT NUMBER(2) := 80; -- nao tem sys_message
    ix_out_ids_pref_surgeons    CONSTANT NUMBER(2) := 81; -- nao tem sys_message
    ix_out_id_adm_phys          CONSTANT NUMBER(2) := 82; -- nao tem sys_message
    ix_out_id_location          CONSTANT NUMBER(2) := 83; -- nao tem sys_message
    ix_out_id_regim             CONSTANT NUMBER(2) := 84;
    ix_out_id_benef             CONSTANT NUMBER(2) := 85;
    ix_out_id_precau            CONSTANT NUMBER(2) := 86;
    ix_out_id_contact           CONSTANT NUMBER(2) := 87;
    ix_out_clinical_q           CONSTANT NUMBER(2) := 88;
    ix_out_proc_surgeon         CONSTANT NUMBER(2) := 89;
    ix_out_proc_diagnosis       CONSTANT NUMBER(2) := 90;

    --hash table containing column names for output indexes. check init values in the initialization area.
    ix_out_names t_hashtable;

    ----------------------
    --- NEW SCHEDULER END
    ----------------------

    /* Maximum decimal precision for advanced search */
    g_max_decimal_prec CONSTANT NUMBER := 9;

    /* market ids */
    g_market_id_nl CONSTANT NUMBER := 5;
    g_market_id_pt CONSTANT NUMBER := 1;

    /* Popup messages */
    g_msg_pop_title CONSTANT VARCHAR2(30) := 'INP_WL_MNGM_T013';

    g_exception EXCEPTION;

    FUNCTION get_wtlist_status
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_wtlist    IN waiting_list.id_waiting_list%TYPE,
        i_adm_needed   IN schedule_sr.adm_needed%TYPE DEFAULT NULL,
        i_chck_pos_req IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        o_status       OUT waiting_list.flg_status%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_ready_to_wtlist
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_wtlist        IN waiting_list.id_waiting_list%TYPE,
        i_flg_type         IN waiting_list.flg_type%TYPE,
        i_pos_confirmation IN VARCHAR2 DEFAULT 'Y',
        i_adm_needed       IN schedule_sr.adm_needed%TYPE DEFAULT NULL,
        i_chck_pos_req     IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        o_flg_valid        OUT VARCHAR2,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION check_adm_req_mandatory
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_id_wtlist IN waiting_list.id_waiting_list%TYPE,
        o_flg_valid OUT VARCHAR2,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION check_surg_req_mandatory
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_wtlist        IN waiting_list.id_waiting_list%TYPE,
        i_pos_confirmation IN VARCHAR2 DEFAULT 'Y',
        o_flg_valid        OUT VARCHAR2,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION check_surg_adm_req_mandatory
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_id_wtlist IN waiting_list.id_waiting_list%TYPE,
        o_flg_valid OUT VARCHAR2,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_list_number_csv(i_list VARCHAR2) RETURN table_number;

    FUNCTION get_list_string_csv(i_list VARCHAR2) RETURN table_varchar;

    /***************************************************************************************************************
    *
    * Checks if there are any differences between the two records provided. 
    * Same logic as PK_ADMISSION_REQUEST.CHECK_CHANGES by Fábio Oliveira.
    * Note: to be moved to PK_WTL_PRV_CORE
    *
    * @param      i_lang              language ID
    * @param      i_prof              ALERT profissional 
    * @param      i_wtl               ID of the current record in Waiting_list
    * @param      i_wtl_old           ID of the record to possibly be replaced in Waiting_list
    * @param      o_result            TRUE or FALSE - if the record should be moved to HIST or not.
    * @param      o_error                         
    *
    *
    * @RETURN  TRUE or FALSE, 
    * @author  Ricardo Nuno Almeida
    * @version 1.0
    * @since   29-04-2009
    *
    ****************************************************************************************************/
    FUNCTION check_changes
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_wtl     IN waiting_list%ROWTYPE,
        i_wtl_old IN waiting_list%ROWTYPE,
        o_result  OUT BOOLEAN,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Stores the common waiting list data of admission and surgery request.
    *
    * @param i_lang                       Language ID
    * @param i_prof                       Professional info
    * @param i_id_patient                 Patient ID
    * @param i_id_waiting_list            Waiting list ID
    * @param i_id_wtl_urg_level           Urgency level ID 
    * @param i_dt_sched_period_start      Scheduling period start date
    * @param i_dt_sched_period_end        Scheduling period end date
    * @param i_min_inform_time            Minimum time to inform
    * @param i_dt_surgery                 Suggested surgery date
    * @param i_dt_admission               Suggested admission date
    * @param i_unav_period_start          Unavailability period start date(s)
    * @param i_unav_period_end            Unavailability period end date(s)
    * @param o_error                      Error message
    *                        
    * @return            TRUE if successful, FALSE otherwise
    *
    * @author            José Brito
    * @version           1.0  
    * @since             2009/04/21
    **********************************************************************************************/
    FUNCTION set_waiting_list_info
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_patient      IN patient.id_patient%TYPE,
        i_id_waiting_list IN waiting_list.id_waiting_list%TYPE,
        -- Common data: Scheduling period
        i_id_wtl_urg_level      IN wtl_urg_level.id_wtl_urg_level%TYPE,
        i_dt_sched_period_start IN VARCHAR2,
        i_dt_sched_period_end   IN VARCHAR2,
        i_min_inform_time       IN waiting_list.min_inform_time%TYPE,
        i_dt_surgery            IN VARCHAR2,
        i_dt_admission          IN VARCHAR2,
        -- Common data: Unavailability period
        i_unav_period_start IN table_varchar,
        i_unav_period_end   IN table_varchar,
        --
        o_msg_error   OUT VARCHAR2,
        o_title_error OUT VARCHAR2,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Creates a record in WTL_EPIS for the given episode ID.
    *
    * @param i_lang                       Language ID
    * @param i_prof                       Professional info
    * @param i_id_episode                 Episode ID
    * @param i_id_waiting_list            Waiting list ID
    * @param i_id_schedule                Schedule ID
    * @param o_error                      Error message
    *                        
    * @return            TRUE if successful, FALSE otherwise
    *
    * @author            José Brito
    * @version           1.0  
    * @since             2009/05/04
    **********************************************************************************************/
    FUNCTION set_wtl_epis
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_episode      IN episode.id_episode%TYPE,
        i_id_waiting_list IN waiting_list.id_waiting_list%TYPE,
        i_id_schedule     IN schedule.id_schedule%TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Returns all or active unavailability periods the given waiting list.
    *
    * @param i_lang                       Language ID
    * @param i_prof                       Professional info
    * @param i_id_waiting_list            Waiting list ID
    * @param i_all                        (Y) All periods (N) Only active periods
    * @param o_unavailabilities           List of unavailability periods
    * @param o_error                      Error message
    *                        
    * @return            TRUE if successful, FALSE otherwise
    *
    * @author            José Brito
    * @version           1.0  
    * @since             2009/05/04
    **********************************************************************************************/
    FUNCTION get_unavailability
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_waiting_list  IN waiting_list.id_waiting_list%TYPE,
        i_all              IN VARCHAR2 DEFAULT 'Y',
        o_unavailabilities OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Returns all active sorting criteria for the pair institution/software.
    *
    * @param i_lang                       Language ID
    * @param i_prof                       Professional info
    * @param o_sort_keys                  List containing all sort keys configured for an institution (or the default values)
    * @param o_error                      Error message
    *                        
    * @return            TRUE if successful, FALSE otherwise
    *
    * @author            RicardoNunoAlmeida
    * @version           2.6  
    * @since             2009/12/21
    **********************************************************************************************/
    FUNCTION get_sort_keys
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_inst      IN institution.id_institution%TYPE,
        o_sort_keys OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Returns all active sorting criteria for the pair institution/software.
    *
    * @param i_lang                       Language ID
    * @param i_prof                       Professional info    
    *                        
    * @return            table_number - list of ID_WTL_SORT_KEYs available
    *
    * @author            RicardoNunoAlmeida
    * @version           2.6.0  
    * @since             2010/02/22
    **********************************************************************************************/
    FUNCTION get_sort_keys_core
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_inst     IN institution.id_institution%TYPE,
        i_children IN VARCHAR2 DEFAULT 'N',
        i_wtlsk    IN wtl_sort_key.id_wtl_sort_key%TYPE DEFAULT NULL
    ) RETURN t_table_wtl_skis;

    /**********************************************************************************************
    * Returns all active sorting criteria for the pair institution/software.
    *
    * @param i_lang                       Language ID
    * @param i_prof                       Professional info
    * @param o_sort_keys                  List containing all sort keys configured for an institution (or the default values)
    * @param o_error                      Error message
    *                        
    * @return            TRUE if successful, FALSE otherwise
    *
    * @author            RicardoNunoAlmeida
    * @version           2.6  
    * @since             2009/12/21
    **********************************************************************************************/
    FUNCTION get_surg_adm_req_mandatory
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_wtl        IN waiting_list%ROWTYPE,
        i_adm_needed IN schedule_sr.adm_needed%TYPE DEFAULT NULL,
        i_screen     IN VARCHAR2 DEFAULT 'I',
        o_required   OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Returns the order for the values of the specified criteria
    *
    * @param i_lang                       Language ID
    * @param i_prof                       Professional info    
    * @param i_inst                       institution to consider
    * @param i_wtlsk                      ID of the parent sort key. 
    * @param o_list                       table_varchar - list of ID_WTL_SORT_KEY values available and their ranking
    *                        
    * @return            true or false  for success
    *
    * @author            RicardoNunoAlmeida
    * @version           2.6.0  
    * @since             2010/02/22
    **********************************************************************************************/
    FUNCTION get_sort_keys_children
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_inst  IN institution.id_institution%TYPE,
        i_wtlsk IN wtl_sort_key.id_wtl_sort_key%TYPE,
        o_list  OUT t_table_wtl_skis,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_sort_keys_children
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_inst  IN institution.id_institution%TYPE,
        i_wtlsk IN wtl_sort_key.id_wtl_sort_key%TYPE
    ) RETURN t_table_wtl_skis;

    /***************************************************************************************************************
    *
    * Checks if there are active requests in the waiting list, for the provided institution.
    *
    *
    * @param      i_lang              language ID
    * @param      i_prof              ALERT profissional 
    * @param      o_result            TRUE or FALSE - if the records exist or not.
    * @param      o_error                         
    *
    *
    * @RETURN  TRUE or FALSE, 
    * @author  RicardoNunoAlmeida
    * @version 2.6.0
    * @since   01-03-2010
    *
    ****************************************************************************************************/
    FUNCTION check_wtl_active_recs
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_inst      IN institution.id_institution%TYPE,
        o_flg_exist OUT VARCHAR2,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    /******************************************************************************
    *  verify if all the mandatory fields to waiting list are filled except the POS 
    * 
    *  @param  i_lang              Language ID
    *  @param  i_prof              Professional ID/Institution ID/Software ID
    *  @param  i_id_wtlist         Waiting list ID
    *  @param  o_flg_valid         check is valid Y/N
    *  @param  o_error             Error data  
    *
    *  @return                     boolean
    *
    *  @author                     Sofia Mendes
    *  @version                    2.6.0.1
    *  @since                      2010/04/21
    *
    ******************************************************************************/
    FUNCTION get_ready_to_wl_exc_pos
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_wtlist    IN waiting_list.id_waiting_list%TYPE,
        i_chck_pos     IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        i_chck_pos_req IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        o_flg_valid    OUT VARCHAR2,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Sends the registry in wtl_epis associated to anepisode note to the history table
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)
    * @param   i_id_episode                Episode identifier. CAn be null if i_id_waiting_list is not null
    * @param   i_id_waiting_list           Waiting list identifier. CAn be null if i_id_episode is not null
    * @param   i_dt_wtl_epis_hist          Date in which the registry was sent to the history
    *
    * @param   o_error        Error information
    *
    * @return  Boolean
    *
    * @author  Sofia Mendes
    * @version 2.6.1.1
    * @since   27-Jun-2011
    */
    FUNCTION set_wtl_epis_hist
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_episode       IN episode.id_episode%TYPE DEFAULT NULL,
        i_id_waiting_list  IN waiting_list.id_waiting_list%TYPE DEFAULT NULL,
        i_id_schedule      IN wtl_epis.id_schedule%TYPE DEFAULT NULL,
        i_dt_wtl_epis_hist IN wtl_epis_hist.dt_wtl_epis_hist%TYPE DEFAULT current_timestamp,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_intern_name_dyn_screen
    (
        i_internal_name IN VARCHAR2,
        i_screen        IN VARCHAR2
    ) RETURN VARCHAR2;

    FUNCTION get_type_dyn_screen
    (
        i_internal_name IN VARCHAR2,
        i_screen        IN VARCHAR2
    ) RETURN VARCHAR2;

END pk_wtl_prv_core;
/
