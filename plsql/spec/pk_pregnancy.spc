/*-- Last Change Revision: $Rev: 2028863 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:48:24 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_pregnancy IS

    -- Joana Barroso 2008-11-19 type para get_sum_page_doc_area_preg_int
    TYPE p_doc_area_val_doc_rec IS RECORD(
        id_epis_documentation     epis_documentation.id_epis_documentation%TYPE,
        PARENT                    VARCHAR2(50),
        id_documentation          documentation.id_documentation%TYPE,
        id_doc_component          documentation.id_doc_component%TYPE,
        id_doc_element_crit       doc_element_crit.id_doc_element_crit%TYPE,
        dt_reg                    VARCHAR2(50),
        desc_doc_component        VARCHAR2(4000),
        desc_element              VARCHAR2(4000),
        VALUE                     epis_documentation_det.value%TYPE,
        id_doc_area               doc_area.id_doc_area%TYPE,
        rank_component            NUMBER,
        rank_element              NUMBER,
        desc_qualification        VARCHAR2(4000),
        flg_current_episode       VARCHAR2(2),
        id_epis_documentation_det epis_documentation_det.id_epis_documentation_det%TYPE);

    TYPE p_doc_area_val_doc_cur IS REF CURSOR RETURN p_doc_area_val_doc_rec;

    TYPE t_rec_doc_area_pregnancy IS RECORD(
        id_epis_documentation pat_pregnancy.id_pat_pregnancy%TYPE,
        id_doc_template       doc_template.id_doc_template%TYPE,
        dt_creation           VARCHAR2(50 CHAR),
        dt_register           VARCHAR2(50 CHAR),
        id_professional       pat_pregnancy.id_professional%TYPE,
        nick_name             professional.name%TYPE,
        desc_speciality       VARCHAR2(200 CHAR),
        id_doc_area           doc_area.id_doc_area%TYPE,
        flg_status            pat_pregnancy.flg_status%TYPE,
        desc_status           VARCHAR2(800 CHAR),
        flg_current_episode   VARCHAR2(2 CHAR),
        notes                 VARCHAR2(4000),
        dt_last_update        VARCHAR2(200 CHAR),
        flg_detail            VARCHAR2(1 CHAR));

    TYPE t_cur_doc_area_pregnancy IS REF CURSOR RETURN t_rec_doc_area_pregnancy;
    TYPE t_coll_doc_area_pregnancy IS TABLE OF t_rec_doc_area_pregnancy;

    -- Rui Duarte
    TYPE p_doc_area_val_doc_rec_ph IS RECORD(
        id_epis_documentation     epis_documentation.id_epis_documentation%TYPE,
        PARENT                    VARCHAR2(50),
        id_documentation          documentation.id_documentation%TYPE,
        id_doc_component          documentation.id_doc_component%TYPE,
        id_doc_element_crit       doc_element_crit.id_doc_element_crit%TYPE,
        flg_status                pat_pregnancy.flg_status%TYPE,
        dt_register               VARCHAR2(50 CHAR),
        dt_register_chr           VARCHAR2(50 CHAR),
        desc_doc_component        VARCHAR2(4000),
        desc_element              VARCHAR2(4000),
        VALUE                     epis_documentation_det.value%TYPE,
        id_doc_area               doc_area.id_doc_area%TYPE,
        rank_component            NUMBER,
        rank_element              NUMBER,
        desc_qualification        VARCHAR2(4000),
        flg_current_episode       VARCHAR2(2),
        id_epis_documentation_det epis_documentation_det.id_epis_documentation_det%TYPE,
        id_episode                pat_pregnancy.id_episode%TYPE,
        id_professional           pat_pregnancy.id_professional%TYPE,
        flg_canceled              VARCHAR2(2),
        flg_outdated              VARCHAR2(2));

    TYPE p_doc_area_val_doc_cur_ph IS REF CURSOR RETURN p_doc_area_val_doc_rec_ph;

    TYPE t_rec_doc_area_pregnancy_ph IS RECORD(
        id_epis_documentation pat_pregnancy.id_pat_pregnancy%TYPE,
        id_doc_template       doc_template.id_doc_template%TYPE,
        dt_register           VARCHAR2(50 CHAR),
        dt_register_chr       VARCHAR2(50 CHAR),
        id_professional       pat_pregnancy.id_professional%TYPE,
        nick_name             professional.name%TYPE,
        desc_speciality       VARCHAR2(200 CHAR),
        id_doc_area           doc_area.id_doc_area%TYPE,
        flg_status            pat_pregnancy.flg_status%TYPE,
        desc_status           VARCHAR2(800 CHAR),
        flg_current_episode   VARCHAR2(2 CHAR),
        notes                 VARCHAR2(4000),
        dt_last_update        VARCHAR2(200 CHAR),
        flg_detail            VARCHAR2(1 CHAR),
        id_episode            pat_pregnancy.id_episode%TYPE,
        n_pregnancy           pat_pregnancy.n_pregnancy%TYPE,
        id_visit              episode.id_visit%TYPE);

    TYPE t_cur_doc_area_pregnancy_ph IS REF CURSOR RETURN t_rec_doc_area_pregnancy_ph;
    TYPE t_coll_doc_area_pregnancy_ph IS TABLE OF t_rec_doc_area_pregnancy_ph;

    /********************************************************************************************
    * Returns the pregnancy probable end date
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_num_weeks              number of weeks
    * @param i_dt_init                Pregnancy start date
    * @param o_dt_end                 Pregnancy end date (serialized)
    * @param o_dt_end_chr             Pregnancy end date (formatted)
    * @param o_error                  Error message
    *                        
    * @return                         true or false on success or error                      
    * 
    * @author                         José Silva
    * @version                        2.5.1.5
    * @since                          2011/04/04
    **********************************************************************************************/
    FUNCTION get_dt_pregnancy_end
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_num_weeks   IN pat_pregnancy.num_gest_weeks%TYPE,
        i_num_days    IN NUMBER,
        i_dt_init     IN VARCHAR2,
        o_dt_end      OUT VARCHAR2,
        o_dt_init_chr OUT VARCHAR2,
        o_dt_end_chr  OUT VARCHAR2,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Returns all the information related with the ultrasound by pregnancy weeks and days.
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_dt_us_performed        Date when the US was performed
    * @param o_num_weeks_performed    Gestational weeks at which the US was made
    * @param o_dt_us_performed        Date when the US was performed
    * @param o_error                  Error message
    *                        
    * @return                         true or false on success or error
    * 
    * @author                         Gisela Couto
    * @version                        2.6.3.15
    * @since                          2014/04/08
    **********************************************************************************************/
    FUNCTION get_us_dt_info
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_num_weeks_preg_init IN NUMBER,
        i_num_days_preg_init  IN NUMBER,
        i_dt_us_performed     IN VARCHAR2,
        o_num_weeks_performed OUT NUMBER,
        o_num_days_performed  OUT NUMBER,
        o_dt_us_performed     OUT VARCHAR2,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    /*******************************************************************0*************************
    * Gets the formatted number of weeks and days of the current pregnancy (used in the report header)
    *
    * @param i_lang                   The language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_pat                    Patient ID
    *
    * @return                         Pregnancy weeks and days
    *
    * @author                         José Silva
    * @version                        2.6.1.1
    * @since                          2011/06/09
    **********************************************************************************************/
    FUNCTION get_pregnancy_weeks
    (
        i_lang IN NUMBER,
        i_prof IN profissional,
        i_pat  IN patient.id_patient%TYPE
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * Gets the formatted number of days of the current pregnancy
    *
    * @param i_lang                   The language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_pat                    Patient ID
    *
    * @return                         Pregnancy  days
    *
    * @author                         Gisela Couto
    * @version                        2.6.4.1.1
    * @since                          2014/08/27
    **********************************************************************************************/
    FUNCTION get_pregnancy_num_days
    (
        i_lang IN NUMBER,
        i_prof IN profissional,
        i_pat  IN patient.id_patient%TYPE
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * Gets the formatted number of weeks and days of the current pregnancy (CDS API)
    *
    * @param i_lang                   The language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_pat                    Patient ID
    *
    * @return                         Pregnancy weeks and days
    *
    * @author                         José Silva
    * @version                        2.6.1.2
    * @since                          2011/09/08
    **********************************************************************************************/
    FUNCTION get_pregnancy_num_weeks
    (
        i_lang IN NUMBER,
        i_prof IN profissional,
        i_pat  IN patient.id_patient%TYPE
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * Gets the weeks and days based in the input weeks or dates
    *
    * @param i_lagn                   Language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_weeks                  Input weeks
    * @param i_days                   Input days
    * @param i_dt_preg                Pregnancy start date (only if i_weeks and i_days is null)
    * @param i_dt_reg                 Pregnancy end date (if any)
    * @param o_weeks                  Output weeks
    * @param o_days                   Output days
    * @param o_weeks_chr              Formatted weeks and days
    * @param o_error                  Error message
    *                        
    * @return                         true or false on success or error
    * 
    * @author                         José Silva
    * @version                        2.5.1.5
    * @since                          2011/04/07
    **********************************************************************************************/
    FUNCTION get_preg_weeks_and_days
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_weeks     IN pat_pregnancy.num_gest_weeks%TYPE,
        i_days      IN NUMBER,
        i_dt_preg   IN VARCHAR2,
        i_dt_reg    IN VARCHAR2,
        o_weeks     OUT NUMBER,
        o_days      OUT NUMBER,
        o_weeks_chr OUT VARCHAR2,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Returns all information to fill the pregnancies summary page
    *
    * @param i_lang                   The language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_episode                episode ID
    * @param i_pat                    patient ID    
    * @param i_doc_area               the doc area ID
    * @param o_doc_area_register      Cursor with the doc area info register
    * @param o_doc_area_val           Cursor containing the completed info for episode
    * @param o_error                  Error message
    *                        
    * @return                         true or false on success or error
    * 
    * @author                         José Silva
    * @version                        1.0
    * @since                          2008/05/23
    * @dependencies                   PK_P1_DATA_EXPORT.get_past_hist_all        REFERRAL
    **********************************************************************************************/
    FUNCTION get_summ_page_doc_area_pregn
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_episode           IN episode.id_episode%TYPE,
        i_pat               IN patient.id_patient%TYPE,
        i_doc_area          IN doc_area.id_doc_area%TYPE,
        o_doc_area_register OUT pk_types.cursor_type,
        o_doc_area_val      OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_sum_page_doc_area_preg_int
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_pat               IN patient.id_patient%TYPE,
        i_doc_area          IN doc_area.id_doc_area%TYPE,
        o_doc_area_register OUT t_doc_area_register,
        o_doc_area_val      OUT t_doc_area_val,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Returns all information to fill the pregnancies summary page (REPORTS version)
    *
    * @param i_lang                   The language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_episode                episode ID
    * @param i_pat                    patient ID    
    * @param i_doc_area               the doc area ID
    * @param o_doc_area_register      Cursor with the doc area info register
    * @param o_doc_area_val           Cursor containing the completed info for episode
    * @param o_error                  Error message
    *                        
    * @return                         true or false on success or error
    * 
    * @author                         José Silva
    * @version                        1.0
    * @since                          2008/05/23
    **********************************************************************************************/

    FUNCTION get_summ_pg_doc_ar_preg_rep
    (
        i_lang              IN language.id_language%TYPE,
        i_prof_id           IN professional.id_professional%TYPE,
        i_prof_inst         IN institution.id_institution%TYPE,
        i_prof_sw           IN software.id_software%TYPE,
        i_episode           IN episode.id_episode%TYPE,
        i_pat               IN patient.id_patient%TYPE,
        i_doc_area          IN doc_area.id_doc_area%TYPE,
        o_doc_area_register OUT pk_types.cursor_type,
        o_doc_area_val      OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Gets all domains used in the pregnancy creation/edition screen
    *
    * @param   I_LANG language associated to the professional executing the request
    * @param   I_PROF  professional, institution and software ids
    * @param   I_DOMAIN domain code
    * @param   O_DOMAINS the cursOr with the domains info  
    * @param   O_ERROR an error message, set when return=false 
    *
    * @RETURN  TRUE if sucess, FALSE otherwise 
    *
    * @author  José Silva
    * @version 1.0 
    * @since   28-08-2008
    *********************************************************************************************/
    FUNCTION get_pregnancy_domain
    (
        i_lang    IN sys_domain.id_language%TYPE,
        i_prof    IN profissional,
        i_domain  IN sys_domain.code_domain%TYPE,
        o_domains OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /************************************************************************************************************ 
    * This function creates new pregnacies or updates existing ones for the specified patient
    *
    * @param      i_lang                        default language
    * @param      i_patient                     patient´s ID
    * @param      i_pat_pregnancy               pregnancy's ID
    * @param      i_dt_last_menstruation        last menstruation date
    * @param      i_dt_intervention             childbirth/abortion dat
    * @param      i_flg_type                    Register type: C - regular pregnancy, R - reported pregnancy
    * @param      i_n_pregnancy                 pregnancy number
    * @param      i_n_children                  number of born childs
    * @param      i_flg_childbirth_type         list of child birth types (one per children)
    * @param      i_flg_child_status            list of child status (one per children)   
    * @param      i_flg_child_gender            list of child gender (one per children)
    * @param      i_flg_child_weight            list of child weight (one per children)
    * @param      i_flg_complication            Complication type during pregnancy
    * @param      i_notes_complication          Complication notes (free text)
    * @param      i_flg_desc_interv             Type of register related to the intervention place: D - home; I - institution; O - free text
    * @param      i_desc_intervention           Description related to the place where the delivery/abortion occured
    * @param      i_id_inst_interv              Institution ID in which the labor/abortion took place
    * @param      i_notes                       Pregnancy notes
    * @param      i_flg_abortion_type           flag that indicates the abortion type
    * @param      i_prof                        Professional info
    * @param      i_id_episode                  Episode ID
    * @param      i_cdr_call                    Rule engine call identifier
    * @param      o_error                       error message
    *
    * @return     Saves the information for a specified pregnancy
    * @author     José Silva
    * @version    0.1
    * @since      2008/05/24
    ***********************************************************************************************************/
    FUNCTION set_pat_pregnancy
    (
        i_lang                 IN language.id_language%TYPE,
        i_patient              IN patient.id_patient%TYPE,
        i_pat_pregnancy        IN pat_pregnancy.id_pat_pregnancy%TYPE,
        i_dt_last_menstruation IN VARCHAR2,
        i_dt_intervention      IN VARCHAR2,
        i_flg_type             IN VARCHAR2,
        i_num_weeks            IN pat_pregnancy.num_gest_weeks%TYPE,
        i_num_days             IN NUMBER,
        i_n_children           IN pat_pregnancy.n_children%TYPE,
        i_flg_childbirth_type  IN table_varchar,
        i_flg_child_status     IN table_varchar,
        i_flg_child_gender     IN table_varchar,
        i_flg_child_weight     IN table_number,
        i_um_weight            IN table_number,
        --
        i_present_health     IN table_varchar,
        i_flg_present_health IN table_varchar,
        --
        i_flg_complication   IN pat_pregnancy.flg_complication%TYPE,
        i_notes_complication IN pat_pregnancy.notes_complications%TYPE,
        i_flg_desc_interv    IN pat_pregnancy.flg_desc_intervention%TYPE,
        i_desc_intervention  IN pat_pregnancy.desc_intervention%TYPE,
        i_id_inst_interv     IN pat_pregnancy.id_inst_intervention%TYPE,
        i_notes              IN pat_pregnancy.notes%TYPE,
        i_flg_abortion_type  IN pat_pregnancy.flg_status%TYPE,
        i_prof               IN profissional,
        i_id_episode         IN episode.id_episode%TYPE,
        --
        i_flg_menses           IN pat_pregnancy.flg_menses%TYPE,
        i_cycle_duration       IN pat_pregnancy.cycle_duration%TYPE,
        i_flg_use_constracep   IN pat_pregnancy.flg_use_constraceptives%TYPE,
        i_dt_contrac_meth_end  IN VARCHAR2,
        i_flg_contra_precision IN VARCHAR2,
        i_dt_pdel_lmp          IN VARCHAR2,
        i_num_weeks_exam       IN pat_pregnancy.num_gest_weeks_exam%TYPE,
        i_num_days_exam        IN NUMBER,
        i_num_weeks_us         IN pat_pregnancy.num_gest_weeks_us%TYPE,
        i_num_days_us          IN NUMBER,
        i_dt_pdel_correct      IN VARCHAR2,
        i_dt_us_performed      IN VARCHAR2,
        i_flg_del_onset        IN pat_pregnancy.flg_del_onset%TYPE,
        i_del_duration         IN pat_pregnancy.del_duration%TYPE,
        i_flg_interv_precision IN pat_pregnancy.flg_dt_interv_precision%TYPE,
        i_id_alert_diagnosis   IN table_number,
        -- SISPRENATAL
        i_code_state  IN pat_pregnancy_code.code_state%TYPE,
        i_code_year   IN pat_pregnancy_code.code_year%TYPE,
        i_code_number IN pat_pregnancy_code.code_number%TYPE,
        --Contraceptive Type
        i_flg_contrac_type IN table_number,
        i_notes_contrac    IN VARCHAR2,
        --
        i_cdr_call            IN cdr_event.id_cdr_call%TYPE DEFAULT NULL, --ALERT-175003
        i_flg_extraction      IN pat_pregnancy.flg_extraction%TYPE DEFAULT NULL,
        i_flg_preg_out_type   IN pat_pregnancy.flg_preg_out_type%TYPE DEFAULT NULL,
        i_num_births          IN pat_pregnancy.num_births%TYPE DEFAULT NULL,
        i_num_abortions       IN pat_pregnancy.num_abortions%TYPE DEFAULT NULL,
        i_num_gestations      IN pat_pregnancy.num_gestations%TYPE DEFAULT NULL,
        i_flg_gest_weeks      IN pat_pregnancy.flg_gest_weeks%TYPE DEFAULT NULL,
        i_flg_gest_weeks_exam IN pat_pregnancy.flg_gest_weeks_exam%TYPE DEFAULT NULL,
        i_flg_gest_weeks_us   IN pat_pregnancy.flg_gest_weeks_us%TYPE DEFAULT NULL,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    /************************************************************************************************************ 
    * Gets the information to be placed on the detail screen
    *
    * @param      i_lang                        default language
    * @param      i_patient                     patient´s ID
    * @param      i_pat_pregnancy               pregnancy's ID
    * @param      o_doc_area_register           Cursor with the pregnancy info register
    * @param      o_doc_area_val                Cursor containing the completed info for the current pregnancy
    * @param      o_error                       error message
    *
    * @return     true or false on success or error
    * @author     José Silva
    * @version    0.1
    * @since      2008/05/26
    ***********************************************************************************************************/
    FUNCTION get_pat_pregnancy_det
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_patient           IN patient.id_patient%TYPE,
        i_pat_pregnancy     IN pat_pregnancy.id_pat_pregnancy%TYPE,
        o_epis_doc_register OUT pk_types.cursor_type,
        o_epis_document_val OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /************************************************************************************************************ 
    * Saves the blood group information
    *
    * @param      i_lang                        default language
    * @param      i_patient                     patient´s ID
    * @param      i_episode                     episode ID
    * @param      i_pat_pregnancy               pregnancy's ID
    * @param      i_blood_type_mother           mother's blood group
    * @param      i_blood_type_father           father's blood group
    * @param      i_flg_antigl_aft_chb          AntiD (after all births)
    * @param      i_flg_antigl_aft_abb          AntiD (after all abortions)
    * @param      i_flg_antigl_need             AntiD need
    * @param      
    * @param      o_error                       error message
    *
    * @return     true or false on success or error
    * @author     José Silva
    * @version    0.1
    * @since      2008/05/26
    ***********************************************************************************************************/
    FUNCTION set_pat_pregnancy_rh
    (
        i_lang               IN language.id_language%TYPE,
        i_patient            IN patient.id_patient%TYPE,
        i_episode            IN episode.id_episode%TYPE,
        i_pat_pregnancy      IN pat_pregnancy.id_pat_pregnancy%TYPE,
        i_blood_type_mother  IN VARCHAR2,
        i_blood_type_father  IN VARCHAR2,
        i_flg_antigl_aft_chb IN pat_pregnancy.flg_antigl_aft_chb%TYPE,
        i_flg_antigl_aft_abb IN pat_pregnancy.flg_antigl_aft_abb%TYPE,
        i_flg_antigl_need    IN pat_pregnancy.flg_antigl_need%TYPE,
        i_titration_value    IN pat_pregnancy.titration_value%TYPE,
        i_flg_antibody       IN pat_pregnancy.flg_antibody%TYPE,
        i_prof               IN profissional,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    /************************************************************************************************************ 
    * Gets the pregnancy RH summary page
    *
    * @param      i_lang                        default language
    * @param      i_patient                     patient´s ID
    * @param      i_pat_pregnancy               pregnancy's ID
    * @param      o_pat_preg_rh                 pregnancy RH info
    * @param      o_error                       error message
    *
    * @return     true or false on success or error
    * @author     José Silva
    * @version    0.1
    * @since      2008/05/26
    ***********************************************************************************************************/
    FUNCTION get_pregn_rh_summ_page
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_patient       IN patient.id_patient%TYPE,
        i_pat_pregnancy IN pat_pregnancy.id_pat_pregnancy%TYPE,
        o_pat_preg_rh   OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /************************************************************************************************************ 
    * Gets the pregnancy RH detail
    *
    * @param      i_lang                        default language
    * @param      i_prof                        Object (professional ID, institution ID, software ID)   
    * @param      i_patient                     patient´s ID
    * @param      i_pat_pregnancy               pregnancy's ID
    * @param      o_pat_preg_rh_reg             Cursor with the pregnancy RH info register
    * @param      o_pat_preg_rh_val             Cursor containing the completed RH info for the current pregnancy
    * @param      o_error                       error message
    *
    * @return     true or false on success or error
    * @author     José Silva
    * @version    0.1
    * @since      2008/05/26
    ***********************************************************************************************************/
    FUNCTION get_pregn_rh_det
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_patient         IN patient.id_patient%TYPE,
        i_pat_pregnancy   IN pat_pregnancy.id_pat_pregnancy%TYPE,
        o_pat_preg_rh_reg OUT pk_types.cursor_type,
        o_pat_preg_rh_val OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /************************************************************************************************************ 
    * Sets the pregnancy fetus info
    *
    * @param      i_lang                        default language
    * @param      i_prof                        Object (professional ID, institution ID, software ID)   
    * @param      i_pat_pregnancy               pregnancy's ID
    * @param      i_n_children                  Total number of fetus
    * @param      i_fetus_number                Single fetus idetifier number
    * @param      i_flg_childbirth_type         list of child birth types (one per children)
    * @param      i_flg_child_status            list of child status (one per children)   
    * @param      i_flg_child_gender            list of child gender (one per children)
    * @param      i_flg_child_weight            list of child weight (one per children)   
    * @param      i_weight_um                   weight unit measure
    * @param      o_error                       error message
    *
    * @return     true or false on success or error
    * @author     José Silva
    * @version    0.1
    * @since      2008/06/01
    ***********************************************************************************************************/
    FUNCTION set_pat_pregn_fetus
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_pat_pregnancy       IN pat_pregnancy.id_pat_pregnancy%TYPE,
        i_n_children          IN pat_pregnancy.n_children%TYPE,
        i_fetus_number        IN NUMBER,
        i_flg_type            IN VARCHAR2,
        i_flg_child_gender    IN table_varchar,
        i_flg_childbirth_type IN table_varchar,
        i_flg_child_status    IN table_varchar,
        i_flg_child_weight    IN table_number,
        i_weight_um           IN table_varchar,
        i_present_health      IN table_varchar,
        i_flg_present_health  IN table_varchar,
        o_id_pat_pregn_fetus  OUT pat_pregn_fetus.id_pat_pregn_fetus%TYPE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    /************************************************************************************************************ 
    * Gets all keypad labels and the pregnancy number to be used in the creation screen
    *
    * @param      i_lang                        default language
    * @param      i_prof                        Object (professional ID, institution ID, software ID)   
    * @param      i_patient                     patient´s ID
    * @param      o_weeks_measure               Keypad label (weeks)
    * @param      o_weight_measure               Keypad label (weight)    
    * @param      o_num_pregnancy               Pregnancy number
    * @param      o_error                       error message
    *
    * @return     true or false on success or error
    * @author     José Silva
    * @version    0.1
    * @since      2008/06/03
    ***********************************************************************************************************/
    FUNCTION get_pregn_create_info
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_patient         IN patient.id_patient%TYPE,
        i_flg_type        IN pat_pregnancy.flg_type%TYPE,
        o_weeks_measure   OUT VARCHAR2,
        o_weight_measure  OUT pk_types.cursor_type,
        o_input_format    OUT pk_types.cursor_type,
        o_num_pregnancy   OUT NUMBER,
        o_weeks_min_fetus OUT NUMBER,
        o_pregn_summ      OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Gets the institution domain for the pregnancy templates
    *
    * @param   I_LANG language associated to the professional executing the request
    * @param   I_PROF  professional, institution and software ids 
    * @param   I_FLG_TYPE institution type: H - hospital, C - primary care, A - both, R - both (reported pregnancy)
    * @param   I_FLG_CONTEXT Context where the method is called: (P) Pregnancy screens
    * @param   O_DOMAINS the cursOr with the domains info  
    * @param   O_ERROR an error message, set when return=false 
    *
    * @RETURN  TRUE if sucess, FALSE otherwise 
    *
    * @author  José Silva
    * @version 1.0 
    * @since   27-06-2008
    */
    FUNCTION get_inst_domain_template
    (
        i_lang        IN sys_domain.id_language%TYPE,
        i_prof        IN profissional,
        i_flg_type    IN VARCHAR2,
        i_flg_context IN VARCHAR2 DEFAULT NULL,
        o_inst        OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Returns the number of new born childs with unusual weigh
    *
    * @param i_prof                   Object (professional ID, institution ID, software ID)       
    * @param i_patient                patient ID
    * @param i_flg_type               weight limit: U - upper limit, L - lower limit
    *                        
    * @return                         number of new born childs
    * 
    * @author                         José Silva
    * @version                        1.0
    * @since                          2008/07/03
    **********************************************************************************************/
    FUNCTION get_count_fetus_weight
    (
        i_prof     IN profissional,
        i_patient  IN patient.id_patient%TYPE,
        i_flg_type IN VARCHAR2
    ) RETURN NUMBER;

    /********************************************************************************************
    * Returns the number of dead fetus
    *
    * @param i_prof                   Object (professional ID, institution ID, software ID)   
    * @param i_patient                patient ID
    *                        
    * @return                         number of dead fetus
    * 
    * @author                         José Silva
    * @version                        1.0
    * @since                          2008/07/03
    **********************************************************************************************/
    FUNCTION get_count_dead_fetus
    (
        i_prof          IN profissional,
        i_patient       IN patient.id_patient%TYPE,
        i_pat_pregnancy IN pat_pregnancy.id_pat_pregnancy%TYPE DEFAULT NULL
    ) RETURN NUMBER;

    /********************************************************************************************
    * Returns the number of early deliveries
    *
    * @param i_prof                   Object (professional ID, institution ID, software ID)   
    * @param i_patient                patient ID
    *                        
    * @return                         number of early deliveries
    * 
    * @author                         José Silva
    * @version                        1.0
    * @since                          2008/07/03
    **********************************************************************************************/
    FUNCTION get_count_early_deliv
    (
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE
    ) RETURN NUMBER;

    /********************************************************************************************
    * Returns the number of cesarean sections
    *
    * @param i_prof                   Object (professional ID, institution ID, software ID)   
    * @param i_patient                patient ID
    *                        
    * @return                         number of cesarean sections
    * 
    * @author                         José Silva
    * @version                        1.0
    * @since                          2008/07/03
    **********************************************************************************************/
    FUNCTION get_count_cesarean
    (
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE
    ) RETURN NUMBER;

    /********************************************************************************************
    * Returns the first component to place in the adverse obstetric section and makes all calculations included in this section
    *
    * @param i_prof                   Object (professional ID, institution ID, software ID)   
    * @param i_patient                patient ID
    *                        
    * @return                         component text
    * 
    * @author                         José Silva
    * @version                        1.0
    * @since                          2008/07/05
    **********************************************************************************************/
    FUNCTION get_adv_obs_component
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * Migration of all pregnancies from the temporary episode to the definitive
    *
    * @param i_lang                   The language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_patient                Definitive patient ID
    * @param i_patient_temp           Temporary patient ID
    * @param o_error                  Error message
    *                        
    * @return                         true or false on success or error
    * 
    * @author                         José Silva
    * @version                        1.0   
    * @since                          01/09/2008
    **********************************************************************************************/
    FUNCTION set_match_pat_pregnancy
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_patient      IN episode.id_episode%TYPE,
        i_patient_temp IN episode.id_episode%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Returns the pregnancy outcome based on the different fetus status
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_flg_child_status       Child status: Live birth or Still birth
    * @param o_pregn_outcome          Pregnancy outcome
    * @param o_error                  Error message
    *                        
    * @return                         true or false on success or error
    * 
    * @author                         José Silva
    * @version                        2.5.1.5
    * @since                          2011/04/08
    **********************************************************************************************/
    FUNCTION get_pregnancy_outcome
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_flg_child_status IN table_varchar,
        o_pregn_outcome    OUT VARCHAR2,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Gets the formatted pregnancy code
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_code_state             State code
    * @param i_code_year              Year code
    * @param i_code_number            Numeric code
    * @param o_code_formatted         Formatted pregnancy code
    * @param o_error                  Error message
    *                        
    * @return                         true or false on success or error
    * 
    * @author                         José Silva
    * @version                        2.5.1.5
    * @since                          2011/04/13
    **********************************************************************************************/
    FUNCTION get_desc_pregnancy_code
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_code_state      IN pat_pregnancy_code.code_state%TYPE,
        i_code_year       IN pat_pregnancy_code.code_year%TYPE,
        i_code_number     IN pat_pregnancy_code.code_number%TYPE,
        o_code_formatted  OUT VARCHAR2,
        o_code_serialized OUT VARCHAR2,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Returns all information to fill the pregnancies summary page in past history area
    *
    * @param i_lang                   The language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_episode                episode ID
    * @param i_pat                    patient ID 
    * @param i_start_date             Start date 
    * @param i_end_date               End date    
    * @param i_doc_area               the doc area ID
    * @param o_doc_area_register      Cursor with the doc area info register
    * @param o_doc_area_val           Cursor containing the completed info for episode
    * @param o_error                  Error message
    *                        
    * @return                         true or false on success or error
    * 
    * @author                         Filipe Silva
    * @version                        2.6.0.5
    * @since                          2011/02/07
    **********************************************************************************************/
    FUNCTION get_sum_page_doc_ar_past_preg
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_episode           IN episode.id_episode%TYPE,
        i_pat               IN patient.id_patient%TYPE,
        i_doc_area          IN doc_area.id_doc_area%TYPE,
        i_start_date        IN pat_pregnancy.dt_pat_pregnancy_tstz%TYPE DEFAULT NULL,
        i_end_date          IN pat_pregnancy.dt_pat_pregnancy_tstz%TYPE DEFAULT NULL,
        o_doc_area_register OUT t_cur_doc_area_pregnancy_ph,
        o_doc_area_val      OUT p_doc_area_val_doc_cur_ph,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Check if patient has a active pregnancy
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_patient                Patient id
    *                        
    * @return                         'Y' - if it has a active pregnancy; 'N' - otherwise
    * 
    * @author                         Alexandre Santos
    * @version                        2.6
    * @since                          2013/01/15
    **********************************************************************************************/
    FUNCTION check_pat_is_preg
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * Check if the patient had a partum less than a month
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_patient                Patient id
    *                        
    * @return                         'Y' - if it had a partum less than one month; 'N' - otherwise
    * 
    * @author                         Alexandre Santos
    * @version                        2.6
    * @since                          2013/01/15
    **********************************************************************************************/
    FUNCTION check_pat_1month_pos_partum
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * Get pregnancy number
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_id_pat_pregancy        Pat pregancy id
    *                        
    * @return                         Pregnancy number
    * 
    * @author                         Sofia Mendes
    * @version                        2.6.3
    * @since                          2013/09/25
    **********************************************************************************************/
    FUNCTION get_n_pregnancy
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_pat_pregancy IN pat_pregnancy.id_pat_pregnancy%TYPE,
        o_n_pregnancy     OUT pat_pregnancy.n_pregnancy%TYPE
    ) RETURN BOOLEAN;
    --------------------------------------------------------------------------------
    PROCEDURE job_close_pregnancy;
    /********************************************************************************************
    * Returns the pregnancy number of weeks, number of days
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_id_pat_pregancy        Pat pregancy id
    * @param i_dt_intervention        init pregnancy date
    * @param o_weeks                  number of weeks
    * @param o_days                   number of days
    * @param o_error                  Error message
    *                        
    * @return                         true or false on success or error                      
    * 
    * @author                         Paulo Teixeira
    * @version                        2.6.3.10
    * @since                          2013/01/21
    **********************************************************************************************/
    FUNCTION get_preg_weeks_days
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_pat_pregnancy   IN pat_pregnancy.id_pat_pregnancy%TYPE,
        i_dt_intervention IN VARCHAR2,
        o_weeks           OUT NUMBER,
        o_days            OUT NUMBER,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get the last menstruation date from the current patient pregnancy  
    *
    * @param i_patient                Patient ID
    * @param i_lang                   Language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    *                        
    * @return                         Last menstruation date
    * 
    * @author                         Gisela Couto
    * @version                        2.6.4.1.1
    * @since                          2014/08/27
    **********************************************************************************************/
    FUNCTION get_last_menstruation_date
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE
    ) RETURN DATE;

    /********************************************************************************************
    * Get the last menstruation date from the current patient pregnancy  
    *
    * @param i_patient                Patient ID
    * @param i_lang                   Language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param o_date_out               Date returned
    * @param o_error                  Error message
    *                        
    * @return                         Last menstruation date
    * 
    * @author                         Gisela Couto
    * @version                        2.6.3.10.1
    * @since                          2014/02/04
    **********************************************************************************************/
    FUNCTION get_last_menstruation_date
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        o_date    OUT VARCHAR2,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Gets obstetric history according to the filter type passed. 
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_patient                Patient ID
    * @param i_flg_filter             Varchar 'ALL','LAST','MINE','LASTMINE'
    *                        
    * @return                         Title and pregnacy tstz
    * 
    * @author                         Gisela Couto
    * @version                        2.6.3.10.1
    * @since                          2014/02/05
    **********************************************************************************************/

    FUNCTION get_obstetric_history
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_patient           IN patient.id_patient%TYPE,
        i_flg_filter        IN VARCHAR2,
        o_obstetric_history OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Gets obstetric adverse history according to the filter type passed. 
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_patient                Patient ID
    * @param i_flg_filter             Varchar 'ALL','LAST','MINE','LASTMINE'
    *                        
    * @return                         Title and pregnacy tstz
    * 
    * @author                         Gisela Couto
    * @version                        2.6.3.10.1
    * @since                          2014/02/05
    **********************************************************************************************/

    FUNCTION get_obstetric_adverse_history
    (
        i_lang                      IN language.id_language%TYPE,
        i_prof                      IN profissional,
        i_patient                   IN patient.id_patient%TYPE,
        i_flg_filter                IN VARCHAR2,
        o_obstetric_adverse_history OUT pk_types.cursor_type,
        o_error                     OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Gets obstetric index resume. (TPAL)
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_patient                Patient ID
    * @param i_filter                 Varchar 'ALL','LAST','MINE','LASTMINE'
    *                        
    * @return                         Title, value and context
    * 
    * @author                         Gisela Couto
    * @version                        2.6.3.10.1
    * @since                          2014/02/07
    **********************************************************************************************/

    FUNCTION get_obstetric_resume
    (
        i_lang       IN language.id_language%TYPE,
        i_patient    IN patient.id_patient%TYPE,
        i_prof       IN profissional,
        i_flg_filter IN VARCHAR2,
        o_result     OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Gets obstetric index details. (TPAL)
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_patient                Patient ID
    * @param i_context                Context - 'TERMO', 'PRETERMO', ''ABORTOSGRAVIDEZES', 'FILHOSVIVOS'    
    * @param i_filter                 Varchar 'ALL','LAST','MINE','LASTMINE'
    *                   
    * @return                         
    * 
    * @author                         Gisela Couto
    * @version                        2.6.3.10.1
    * @since                          2014/02/07
    **********************************************************************************************/

    FUNCTION get_tpal_index_item_details
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        i_context IN VARCHAR2,
        i_filter  IN VARCHAR2,
        o_details OUT t_item_index_details,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * ets obstetric item index details.
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_patient                Patient ID
    * @param i_context                Context - 'TERMO', 'PRETERMO', ''ABORTOSGRAVIDEZES', 'FILHOSVIVOS'    
    * @param i_filter                 Varchar 'ALL','LAST','MINE','LASTMINE'
    *                   
    * @return                         
    * 
    * @author                         Gisela Couto
    * @version                        2.6.3.10.1
    * @since                          2014/02/07
    **********************************************************************************************/
    FUNCTION get_obstetric_item_details
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        i_context IN VARCHAR2,
        i_filter  IN VARCHAR2,
        o_details OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_limited_pregnancy_popup
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_patient     IN patient.id_patient%TYPE,
        o_type_popup  OUT VARCHAR2,
        o_title_popup OUT VARCHAR2,
        o_msg_popup   OUT VARCHAR2,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_patient_age_pregnancy
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_patient     IN patient.id_patient%TYPE,
        i_dt_birth    IN VARCHAR2 DEFAULT NULL,
        o_title_popup OUT VARCHAR2,
        o_msg_popup   OUT VARCHAR2,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Returns the number of lived fetus
    *
    * @param i_prof                   Object (professional ID, institution ID, software ID)       
    * @param i_patient                patient ID
    *                        
    * @return                         number of lived fetus
    * 
    * @author                         Vanessa Barsottelli
    * @version                        1.0
    * @since                          01/02/2017
    **********************************************************************************************/
    FUNCTION get_count_lived_fetus
    (
        i_prof          IN profissional,
        i_patient       IN patient.id_patient%TYPE,
        i_pat_pregnancy IN pat_pregnancy.id_pat_pregnancy%TYPE DEFAULT NULL
    ) RETURN NUMBER;

    /********************************************************************************************
    * Returns the last pregnancy fetus status condition do NOM024
    *
    * @param i_prof                   Object (professional ID, institution ID, software ID)       
    * @param i_patient                patient ID    
    * @param i_pat_pregnancy          pat_pregnancy ID
    *                        
    * @return                         fetus status
    * 
    * @author                         Vanessa Barsottelli
    * @version                        1.0
    * @since                          01/02/2017
    **********************************************************************************************/
    FUNCTION get_past_pregn_fetus_status
    (
        i_prof          IN profissional,
        i_patient       IN patient.id_patient%TYPE,
        i_pat_pregnancy IN pat_pregnancy.id_pat_pregnancy%TYPE
    ) RETURN VARCHAR2;

    FUNCTION get_fetus_present_health
    (
        i_prof          IN profissional,
        i_patient       IN patient.id_patient%TYPE,
        i_pat_pregnancy IN pat_pregnancy.id_pat_pregnancy%TYPE
    ) RETURN VARCHAR2;

    FUNCTION get_past_pregn_dt_interv
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_patient       IN patient.id_patient%TYPE,
        i_pat_pregnancy IN pat_pregnancy.id_pat_pregnancy%TYPE
    ) RETURN VARCHAR2;

    FUNCTION get_summary_page_sections
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_summary_page IN summary_page.id_summary_page%TYPE,
        i_pat             IN patient.id_patient%TYPE,
        o_sections        OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_flg_pregn_out_type
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_episode   IN episode.id_episode%TYPE,
        o_flg_pregn OUT pat_pregnancy.flg_preg_out_type%TYPE,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_pregnancy_popup_limits
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_patient     IN patient.id_patient%TYPE,
        i_value       IN NUMBER DEFAULT NULL,
        o_type_popup  OUT VARCHAR2,
        o_title_popup OUT VARCHAR2,
        o_msg_popup   OUT VARCHAR2,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Gets the obstetric indexes to place in the summary page
    *
    * @param i_lang                   The language ID   
    * @param i_prof                   Object (professional ID, institution ID, software ID)   
    * @param i_patient                Patient ID
    *                        
    * @return                         Pregnancy formatted obstetric indexes
    * 
    * @author                         Elisabete Bugalho
    * @version                        2.7.4.1
    * @since                          18/09/2018
    **********************************************************************************************/
    FUNCTION get_obstetric_index
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE
    ) RETURN VARCHAR2;

    /**************************************************************************
    * get import data from current pregnancy
    *                                                                         
    * @param i_lang                   Language ID                             
    * @param i_prof                   Profissional ID  
    * @param i_episode                Episode ID
    * @param i_pat                    Patient ID
    *
    * @return varchar2                Current pregnacy description for summary page
    *                                                                         
    * @author                         Ana Moita                   
    * @version                        2.8                            
    * @since                          18/08/2021                            
    **************************************************************************/
    FUNCTION get_sp_current_pregnacy
    
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN NUMBER,
        i_pat     IN patient.id_patient%TYPE
    ) RETURN CLOB;
    --------------------------------------------------------------------------------
    g_error VARCHAR2(4000);
    g_found BOOLEAN;
    g_yes CONSTANT VARCHAR2(1) := 'Y';
    g_no  CONSTANT VARCHAR2(1) := 'N';

    g_count_weight_l   NUMBER;
    g_count_weight_u   NUMBER;
    g_count_dead_fetus NUMBER;
    g_count_abortion   NUMBER;
    g_count_pre_labor  NUMBER;
    g_count_cesarean   NUMBER;
    g_flg_count        VARCHAR2(1);
    g_flg_mon_inst CONSTANT pat_health_program.flg_monitor_loc%TYPE := 'H';

    g_code_msg_weeks CONSTANT sys_message.code_message%TYPE := 'WOMAN_HEALTH_T159';

    g_ended_child_births_context CONSTANT VARCHAR2(32) := 'TERMO';
    g_n_ended_child_births_cont  CONSTANT VARCHAR2(32) := 'PRETERMO';
    g_alive_children_context     CONSTANT VARCHAR2(32) := 'FILHOSVIVOS';
    g_abortions_pregnancies      CONSTANT VARCHAR2(32) := 'ABORTOSGRAVIDEZES';

    g_obstetric_resume_all       CONSTANT VARCHAR2(10) := 'ALL';
    g_obstetric_resume_last      CONSTANT VARCHAR2(10) := 'LAST';
    g_obstetric_resume_mine      CONSTANT VARCHAR2(10) := 'MINE';
    g_obstetric_resume_last_mine CONSTANT VARCHAR2(10) := 'LASTMINE';

    g_preg_induced_abortions     CONSTANT VARCHAR(10) := '|AA|AI|AP|';
    g_preg_spontaneous_abortions CONSTANT VARCHAR(10) := '|AE|AS|E|';
    g_preg_molar                 CONSTANT VARCHAR(1) := 'M';
    g_preg_etopic                CONSTANT VARCHAR(2) := 'GE';
    g_gestation_weeks            CONSTANT sys_config.id_sys_config%TYPE := 'PREGNANCY_GESTATION_WEEKS';

END pk_pregnancy;
/
