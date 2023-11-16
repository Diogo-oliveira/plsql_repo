/*-- Last Change Revision: $Rev: 2028865 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:48:25 +0100 (ter, 02 ago 2022) $*/
CREATE OR REPLACE PACKAGE pk_pregnancy_core IS

    --BEGIN AUX XML EXAM FUNCTION
    --Auxiliar functions that extracts exam sequence values
    --This functions simplied the readability of the code
    FUNCTION get_exam_diags
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE,
        i_id_episode IN episode.id_episode%TYPE,
        i_diags      IN xmltype
    ) RETURN pk_edis_types.rec_in_epis_diagnosis;
    FUNCTION get_exam_id_clin_quest(i_clin_quest xmltype) RETURN table_number;
    FUNCTION get_exam_clin_resp(i_clin_quest xmltype) RETURN table_varchar;
    FUNCTION get_exam_clin_notes(i_clin_quest xmltype) RETURN table_varchar;
    --END AUX XML EXAM FUNCTION   

    /********************************************************************************************
    * Returns the pregnancy start date
    *
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_num_weeks              number of weeks (by LMP)
    * @param i_num_weeks_exam         number of weeks (by examination)
    * @param i_num_weeks_us           number of weeks (by US)
    * @param i_dt_intervention        Intervention date (if the pregnancy is closed)
    *                        
    * @return                         pregnancy start date
    * 
    * @author                         José Silva
    * @version                        2.5.1.5
    * @since                          2011/03/31
    **********************************************************************************************/
    FUNCTION get_dt_pregnancy_start
    (
        i_prof            IN profissional,
        i_num_weeks       IN pat_pregnancy.num_gest_weeks%TYPE,
        i_num_weeks_exam  IN pat_pregnancy.num_gest_weeks_exam%TYPE,
        i_num_weeks_us    IN pat_pregnancy.num_gest_weeks_us%TYPE,
        i_dt_intervention IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_flg_precision   IN pat_pregnancy.flg_dt_interv_precision%TYPE
    ) RETURN DATE;

    /********************************************************************************************
    * Returns the pregnancy probable end date
    *
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_num_weeks              number of weeks
    * @param i_dt_init                Pregnancy start date
    *                        
    * @return                         pregnancy end date
    * 
    * @author                         José Silva
    * @version                        2.5.1.5
    * @since                          2011/04/04
    **********************************************************************************************/
    FUNCTION get_dt_pregnancy_end
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_num_weeks IN pat_pregnancy.num_gest_weeks%TYPE,
        i_num_days  IN NUMBER,
        i_dt_init   IN pat_pregnancy.dt_init_pregnancy%TYPE
    ) RETURN DATE;

    /********************************************************************************************
    * Returns all the information related with the ultrasound by pregnancy weeks and days.
    *
    * @param i_lagn                   Language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_num_weeks_us           Gestational weeks by US
    * @param i_num_weeks_performed    Gestational weeks at which the US was made
    * @param i_dt_us_performed        Date when the US was performed
    * @param o_num_weeks_us           Gestational weeks by US
    * @param o_num_weeks_performed    Gestational weeks at which the US was made
    * @param o_dt_us_performed        Date when the US was performed
    * @param o_error                  Error message
    *                        
    * @return                         true or false on success or error
    * 
    * @author                         José Silva
    * @version                        2.5.1.5
    * @since                          2011/04/06
    * @Updated By                     Gisela Couto
    * @Since                          2014/04/09
    **********************************************************************************************/
    FUNCTION get_us_dt_info
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_num_weeks_preg_init IN NUMBER,
        i_num_days_preg_init  IN NUMBER,
        i_dt_us_performed     IN pat_pregnancy.dt_us_performed%TYPE,
        o_num_weeks_performed OUT NUMBER,
        o_num_days_performed  OUT NUMBER,
        o_dt_us_performed     OUT pat_pregnancy.dt_us_performed%TYPE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Returns the pregnancy close date (formatted)
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_dt_intervention        Pregnancy start date
    * @param i_flg_precision          Date precision: (H)our, (D)ay, (M)onth or (Y)ear
    *                        
    * @return                         pregnancy end date (formatted)
    * 
    * @author                         José Silva
    * @version                        2.5.1.5
    * @since                          2011/04/05
    **********************************************************************************************/
    FUNCTION get_dt_intervention
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_dt_intervention IN pat_pregnancy.dt_intervention%TYPE,
        i_flg_precision   IN pat_pregnancy.flg_dt_interv_precision%TYPE
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * Returns the pregnancy close date (formatted)
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_dt_contrac_end         Last use of contraceptives
    * @param i_flg_precision          Date precision: (H)our, (D)ay, (M)onth or (Y)ear
    *                        
    * @return                         formatted date
    * 
    * @author                         José Silva
    * @version                        2.5.1.5
    * @since                          2011/04/29
    **********************************************************************************************/
    FUNCTION get_dt_contrac_end
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_dt_contrac_end IN pat_pregnancy.dt_contrac_meth_end%TYPE,
        i_flg_precision  IN pat_pregnancy.flg_dt_contrac_precision%TYPE
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * Returns the number of pregnany weeks (formatted text)
    *
    * @param i_lang                   language ID
    * @param i_dt_preg                start date
    * @param i_dt_reg                 current or end date
    *                        
    * @return                         number of weeks
    * 
    * @author                         José Silva
    * @version                        1.0
    * @since                          2008/09/03
    **********************************************************************************************/
    FUNCTION get_pregn_formatted_weeks
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_weeks      IN pat_pregnancy.num_gest_weeks%TYPE,
        i_dt_preg    IN DATE,
        i_dt_reg     IN pat_pregnancy.dt_intervention%TYPE,
        i_flg_status IN pat_pregnancy.flg_status%TYPE DEFAULT NULL
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * Returns the number of pregnany weeks
    *
    * @param i_dt_preg                start date
    * @param i_dt_reg                 current or end date
    *                        
    * @return                         number of weeks
    * 
    * @author                         José Silva
    * @version                        1.0
    * @since                          2008/05/24
    **********************************************************************************************/
    FUNCTION get_pregnancy_weeks
    (
        i_prof    IN profissional,
        i_dt_preg IN DATE,
        i_dt_reg  IN pat_pregnancy.dt_intervention%TYPE,
        i_weeks   IN pat_pregnancy.num_gest_weeks%TYPE
    ) RETURN NUMBER;

    /********************************************************************************************
    * Returns the number of extra pregnancy days
    *
    * @param i_dt_preg                start date
    * @param i_dt_reg                 current or end date
    * @param i_weeks                  number of weeks
    *                        
    * @return                         number of days
    * 
    * @author                         José Silva
    * @version                        1.0
    * @since                          2011/05/01
    **********************************************************************************************/
    FUNCTION get_pregnancy_days
    (
        i_prof    IN profissional,
        i_dt_preg IN DATE,
        i_dt_reg  IN pat_pregnancy.dt_intervention%TYPE,
        i_weeks   IN pat_pregnancy.num_gest_weeks%TYPE
    ) RETURN NUMBER;

    /********************************************************************************************
    * Gets all gestation weeks (with the included days)
    *
    * @param i_lang                   The language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_num_weeks              Number of gestation weeks (by LMP)
    * @param i_day_weeks              Number of extra gestation days (by LMP)
    * @param i_num_weeks_exam         Number of gestation weeks (by examination)
    * @param i_day_weeks_exam         Number of extra gestation days (by examination)
    * @param i_num_weeks_us           Number of gestation weeks (by ultrasound)        
    * @param i_day_weeks_us           Number of extra gestation days (by ultrasound)
    * @param o_num_weeks              Complete gestation weeks (by LMP)
    * @param o_num_weeks_exam         Complete gestation weeks (by examination)
    * @param o_num_weeks_us           Complete gestation weeks (by US)
    * @param o_error                  Error message
    *                        
    * @return                         true or false on success or error
    * 
    * @author                         José Silva
    * @version                        2.5.1.5
    * @since                          2011/03/30
    **********************************************************************************************/
    FUNCTION get_gestation_weeks
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_num_weeks      IN pat_pregnancy.num_gest_weeks%TYPE,
        i_num_days       IN NUMBER,
        i_num_weeks_exam IN pat_pregnancy.num_gest_weeks_exam%TYPE,
        i_num_days_exam  IN NUMBER,
        i_num_weeks_us   IN pat_pregnancy.num_gest_weeks_us%TYPE,
        i_num_days_us    IN NUMBER,
        o_num_weeks      OUT pat_pregnancy.num_gest_weeks%TYPE,
        o_num_weeks_exam OUT pat_pregnancy.num_gest_weeks_exam%TYPE,
        o_num_weeks_us   OUT pat_pregnancy.num_gest_weeks_us%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Returns the formatted text to place in the summary page
    *
    * @param i_doc_area               doc area ID of the section where the text is being formatted    
    * @param i_title                  title string
    * @param i_desc                   body string
    * @param i_sep                    string which separates different lines
    *                        
    * @return                         formatted text
    * 
    * @author                         José Silva
    * @version                        1.0
    * @since                          2011/04/11
    **********************************************************************************************/
    FUNCTION get_formatted_text_break
    (
        i_doc_area    IN doc_area.id_doc_area%TYPE,
        i_title       IN VARCHAR2,
        i_desc        IN VARCHAR2,
        i_sep         IN VARCHAR2,
        i_first_title IN VARCHAR2,
        i_flg_break   IN VARCHAR2
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * Returns the formatted text to place in the summary page
    *
    * @param i_doc_area               doc area ID of the section where the text is being formatted    
    * @param i_title                  title string
    * @param i_desc                   body string
    * @param i_sep                    string which separates different lines
    *                        
    * @return                         formatted text
    * 
    * @author                         José Silva
    * @version                        1.0
    * @since                          2008/05/24
    **********************************************************************************************/
    FUNCTION get_formatted_text
    (
        i_doc_area    IN doc_area.id_doc_area%TYPE,
        i_title       IN VARCHAR2,
        i_desc        IN VARCHAR2,
        i_sep         IN VARCHAR2,
        i_first_title IN VARCHAR2
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * Returns the description of the place in which the labor/abortion occured
    * 
    * @param i_lang                   language ID 
    * @param i_id_institution         institution ID
    * @param i_flg_desc_interv        option selected: D - home; O - free text
    * @param desc_intervention        location description
    * @param i_flg_show_other         show text "Other Hospital" (Y) or not (N)
    *                        
    * @return                         formatted text
    * 
    * @author                         José Silva
    * @version                        1.0
    * @since                          2008/09/05
    **********************************************************************************************/
    FUNCTION get_desc_intervention
    (
        i_lang              IN language.id_language%TYPE,
        i_id_institution    IN pat_pregnancy.id_inst_intervention%TYPE,
        i_flg_desc_interv   IN pat_pregnancy.flg_desc_intervention%TYPE,
        i_desc_intervention IN pat_pregnancy.desc_intervention%TYPE,
        i_flg_show_other    IN VARCHAR2 DEFAULT 'Y'
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * Returns the type of abortion
    *
    * @param i_flg_status             pregnancy status
    *                        
    * @return                         type of abortion
    * 
    * @author                         José Silva
    * @version                        1.0
    * @since                          2008/05/26
    **********************************************************************************************/
    FUNCTION get_abortion_type(i_flg_status IN pat_pregnancy.flg_status%TYPE) RETURN VARCHAR2;

    /********************************************************************************************
    * Returns the type of abortion (description)
    *
    * @param i_flg_status             pregnancy status
    * @param i_pat_pregnancy          pregnancy's ID
    * @param i_type_desc              description type: S - summary page; D - detail screen
    *                        
    * @return                         type of abortion
    * 
    * @author                         José Silva
    * @version                        1.0
    * @since                          2010/04/27
    **********************************************************************************************/
    FUNCTION get_pregn_outcome_desc
    (
        i_lang               IN language.id_language%TYPE,
        i_flg_status         IN pat_pregnancy.flg_status%TYPE,
        i_pat_pregnancy      IN pat_pregnancy.id_pat_pregnancy%TYPE,
        i_pat_pregnancy_hist IN pat_pregnancy_hist.id_pat_pregnancy_hist%TYPE,
        i_type_desc          IN VARCHAR2
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * Returns the viewer category
    *
    * @param i_pat_pregnancy          pregnancy ID
    *                        
    * @return                         viewer category
    * 
    * @author                         José Silva
    * @version                        1.0
    * @since                          2008/05/26
    **********************************************************************************************/
    FUNCTION get_viewer_category(i_pat_pregnancy IN pat_pregnancy.id_pat_pregnancy%TYPE) RETURN NUMBER;

    /********************************************************************************************
    * Gets all complications of a specific pregnancy
    *
    * @param i_lang                   The language ID   
    * @param i_prof                   Object (professional ID, institution ID, software ID)   
    *                        
    * @return                         weight unit measure (description)
    * 
    * @author                         José Silva
    * @version                        1.0
    * @since                          2008/11/26
    **********************************************************************************************/
    FUNCTION get_preg_complications
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_flg_complication    IN pat_pregnancy.flg_complication%TYPE,
        i_notes_complications IN pat_pregnancy.notes_complications%TYPE,
        i_pat_pregnancy       IN pat_pregnancy.id_pat_pregnancy%TYPE,
        i_pat_pregnancy_hist  IN pat_pregnancy_hist.id_pat_pregnancy_hist%TYPE
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * Gets all contraception type of a specific pregnancy
    *
    * @param i_lang                   The language ID   
    * @param i_prof                   Object (professional ID, institution ID, software ID)   
    *                        
    * @return                        contraception type (description)
    * 
    * @author                         Jorge Silva
    * @version                        1.0
    * @since                          2013/11/20
    **********************************************************************************************/
    FUNCTION get_contraception_type
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_pat_pregnancy      IN pat_pregnancy.id_pat_pregnancy%TYPE,
        i_pat_pregnancy_hist IN pat_pregnancy_hist.id_pat_pregnancy_hist%TYPE,
        i_other_string       IN VARCHAR2 DEFAULT 'Y'
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * Gets all contraception type id of a specific pregnancy
    *
    * @param i_lang                   The language ID   
    * @param i_prof                   Object (professional ID, institution ID, software ID)   
    * @param i_pat_pregnancy          Pat pregnancy ID
    *
    * @return                        contraception type (description)
    * 
    * @author                         Jorge Silva
    * @version                        1.0
    * @since                          2013/11/20
    **********************************************************************************************/
    FUNCTION get_contraception_type_id
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_pat_pregnancy IN pat_pregnancy.id_pat_pregnancy%TYPE
    ) RETURN table_varchar;

    /********************************************************************************************
    * Gets all complications in serialized format to be passed to the edition screen
    *
    * @param i_lang                   The language ID   
    * @param i_prof                   Object (professional ID, institution ID, software ID)   
    *                        
    * @return                         weight unit measure (description)
    * 
    * @author                         José Silva
    * @version                        1.0
    * @since                          2011/04/29
    **********************************************************************************************/
    FUNCTION get_serialized_compl
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_flg_complication IN pat_pregnancy.flg_complication%TYPE,
        i_pat_pregnancy    IN pat_pregnancy.id_pat_pregnancy%TYPE
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * Gets the obstetric indexes to place in the summary page
    *
    * @param i_lang                   The language ID   
    * @param i_prof                   Object (professional ID, institution ID, software ID)   
    * @param i_patient                Patient ID
    * @param i_type                   Formatting type: T - initial type, C - complete obstetric index          
    *                        
    * @return                         Pregnancy formatted obstetric indexes
    * 
    * @author                         José Silva
    * @version                        2.5.1.5
    * @since                          2011/03/28
    **********************************************************************************************/
    FUNCTION get_obstetric_index
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        i_type    IN VARCHAR2
    ) RETURN VARCHAR2;

    /************************************************************************************************************ 
    * This function creates new pregnacies or updates existing ones for the specified patient
    *
    * @param      i_pat_pregnancy               pregnancy's ID
    * @param      o_error                       error message
    *
    * @return     Saves the pregnancy history to be available after all changes
    * @author     José Silva
    * @version    0.1
    * @since      2008/05/25
    ***********************************************************************************************************/
    FUNCTION set_pat_pregnancy_hist
    (
        i_lang          IN language.id_language%TYPE,
        i_pat_pregnancy IN pat_pregnancy.id_pat_pregnancy%TYPE,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /************************************************************************************************************ 
    * This function creates a new pregnacy code
    *
    * @param i_lang                   The language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_pat_pregnancy          pregnancy ID
    * @param i_code_state             State code
    * @param i_code_year              Year code
    * @param i_code_number            Numeric code
    * @param i_flg_type               Type of pregnancy code: S - SIS prenatal (brazilian market)
    * @param o_error                  error message
    *
    *                        
    * @return     true or false on success or error
    *
    * @author     José Silva
    * @version    2.5.1.5
    * @since      2011/04/12
    ***********************************************************************************************************/
    FUNCTION set_pat_pregnancy_code
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_pat_pregnancy IN pat_pregnancy.id_pat_pregnancy%TYPE,
        i_code_state    IN pat_pregnancy_code.code_state%TYPE,
        i_code_year     IN pat_pregnancy_code.code_year%TYPE,
        i_code_number   IN pat_pregnancy_code.code_number%TYPE,
        i_flg_type      IN pat_pregnancy_code.flg_type%TYPE,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /************************************************************************************************************ 
    * Sets the pregnancy info (saved from labor and delivery assessments)
    *
    * @param      i_lang                        default language
    * @param      i_prof                        Object (professional ID, institution ID, software ID)   
    * @param      i_pat_pregnancy               pregnancy's ID
    * @param      i_doc_area                    doc area ID from the labor/delivery assessment
    * @param      i_fetus_number                Single fetus idetifier number
    * @param      i_flg_type                    record type: E - creation/edition; C - cancel; H - creation/edition with history saving
    * @param      i_flg_childbirth_type         list of child birth types (one per children)
    * @param      i_flg_child_status            list of child status (one per children)   
    * @param      i_flg_child_gender            list of child gender (one per children)
    * @param      i_child_weight                list of child weight (one per children) 
    * @param      i_weight_um                   weight unit measure
    * @param      i_dt_intervention             labor date
    * @param      i_desc_intervention           labor site: description
    * @param      l_flg_desc_interv             labor site: D - home; O - other hospital
    * @param      i_id_inst_interv              labor site: institution ID
    * @param      i_notes_complications         labor complications
    * @param      i_epis_documentation          Epis documentation 
    * @param      o_error                       error message
    *
    * @return     true or false on success or error
    * @author     José Silva
    * @version    0.1
    * @since      2008/09/08
    ***********************************************************************************************************/
    FUNCTION set_pat_pregn_delivery
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_pat_pregnancy       IN pat_pregnancy.id_pat_pregnancy%TYPE,
        i_doc_area            IN doc_area.id_doc_area%TYPE,
        i_fetus_number        IN NUMBER,
        i_flg_type            IN VARCHAR2,
        i_flg_child_gender    IN table_varchar,
        i_flg_childbirth_type IN table_varchar,
        i_flg_child_status    IN table_varchar,
        i_child_weight        IN table_number,
        i_weight_um           IN table_varchar,
        i_dt_intervention     IN pat_pregnancy.dt_intervention%TYPE,
        i_desc_intervention   IN pat_pregnancy.desc_intervention%TYPE,
        i_flg_desc_interv     IN pat_pregnancy.flg_desc_intervention%TYPE,
        i_id_inst_interv      IN pat_pregnancy.id_inst_intervention%TYPE,
        i_notes_complications IN pat_pregnancy.notes_complications%TYPE,
        i_epis_documentation  IN epis_documentation.id_epis_documentation%TYPE DEFAULT NULL,
        o_msg_error           OUT VARCHAR2,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    /************************************************************************************************************ 
    * Gets the 'N.A.' label when applicable
    *
    * @param      i_lang                        default language
    * @param      i_rh_father                   Father blood rhesus
    * @param      i_rh_mother                   Mother blood rhesus
    *
    * @return     'N.A.' label
    * @author     José Silva
    * @version    1.0
    * @since      2009/11/20
    ***********************************************************************************************************/
    FUNCTION get_antigl_need_na
    (
        i_lang      IN language.id_language%TYPE,
        i_rh_father IN pat_pregnancy.blood_rhesus_father%TYPE,
        i_rh_mother IN pat_blood_group.flg_blood_rhesus%TYPE
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * Gets the weight unit measure in the pregnancies summary
    *
    * @param i_lang                   The language ID   
    * @param i_prof                   Object (professional ID, institution ID, software ID) 
    * @param i_unit_measure           Unit ID associated with a specific measure
    *                        
    * @return                         weight unit measure (description)
    * 
    * @author                         José Silva
    * @version                        1.0
    * @since                          2008/11/26
    **********************************************************************************************/
    FUNCTION get_preg_summ_unit_measure
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_unit_measure IN unit_measure.id_unit_measure%TYPE
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * Gets the weight unit measure in the pregnancies summary
    *
    * @param i_lang                   The language ID   
    * @param i_prof                   Object (professional ID, institution ID, software ID)   
    *                        
    * @return                         weight unit measure (id)
    * 
    * @author                         José Silva
    * @version                        1.0
    * @since                          2010/02/15
    **********************************************************************************************/
    FUNCTION get_preg_summ_unit_measure_id
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) RETURN unit_measure.id_unit_measure%TYPE;

    /********************************************************************************************
    * Gets the weight unit measure list to be used in the weight keypad
    *
    * @param i_lang                   The language ID   
    * @param i_prof                   Object (professional ID, institution ID, software ID)   
    * @param o_unit_measures          Unit measure list
    * @param o_error                  error message
    *
    * @return     true or false on success or error
    * 
    * @author                         José Silva
    * @version                        1.0
    * @since                          2011/04/14
    **********************************************************************************************/
    FUNCTION get_preg_summ_unit_measure
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        o_unit_measures OUT pk_types.cursor_type,
        o_input_format  OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /************************************************************************************************************ 
    * Sets all the pregnancy numbers of a patient
    *
    * @param      i_lang               language ID
    * @param      i_prof               Object (professional ID, institution ID, software ID)
    * @param      i_patient            patient ID
    * @param      o_error              error message
    *
    * @return                          true or false on success or error
    *
    * @author     José Silva
    * @version    0.1
    * @since      2011/04/05
    ***********************************************************************************************************/
    FUNCTION set_n_pregnancy
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN pat_pregnancy.id_pat_pregnancy%TYPE,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Returns the pregnancy outcome based on the different fetus status
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_pat_pregnancy          Pregnancy ID
    * @param i_flg_child_status       Child status: Live birth or Still birth
    *                        
    * @return                         pregnancy outcome
    * 
    * @author                         José Silva
    * @version                        2.5.1.5
    * @since                          2011/04/08
    **********************************************************************************************/
    FUNCTION get_pregnancy_outcome
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_pat_pregnancy      IN pat_pregnancy.id_pat_pregnancy%TYPE,
        i_pat_pregnancy_hist IN pat_pregnancy_hist.id_pat_pregnancy_hist%TYPE,
        i_flg_child_status   IN table_varchar
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * Gets the first title that appears in a pregnancy record in the summary page
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_pat_pregnancy          Pregnancy ID
    * @param i_flg_type               Pregnancy type: (R)eported or (C)urrent pregnancy
    *                        
    * @return                         pregnancy outcome
    * 
    * @author                         José Silva
    * @version                        2.5.1.5
    * @since                          2011/04/08
    **********************************************************************************************/
    FUNCTION get_summ_page_first_title
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_pat_pregnancy      IN pat_pregnancy.id_pat_pregnancy%TYPE,
        i_pat_pregnancy_hist IN pat_pregnancy_hist.id_pat_pregnancy_hist%TYPE,
        i_flg_type           IN pat_pregnancy.flg_type%TYPE
    ) RETURN VARCHAR2;

    --

    FUNCTION check_break_summ_pg_exam
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_flg_type       IN pat_pregnancy.flg_type%TYPE,
        i_num_weeks_exam IN pat_pregnancy.num_gest_weeks_exam%TYPE
    ) RETURN VARCHAR2;

    --

    FUNCTION check_break_summ_pg_us
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_flg_type        IN pat_pregnancy.flg_type%TYPE,
        i_num_weeks_us    IN pat_pregnancy.num_gest_weeks_us%TYPE,
        i_dt_pdel_correct IN pat_pregnancy.dt_pdel_correct%TYPE,
        i_dt_us_performed IN pat_pregnancy.dt_us_performed%TYPE,
        i_n_children      IN pat_pregnancy.n_children%TYPE
    ) RETURN VARCHAR2;

    --

    FUNCTION check_break_summ_pg_compl
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_flg_type           IN pat_pregnancy.flg_type%TYPE,
        i_pat_pregnancy      IN pat_pregnancy.id_pat_pregnancy%TYPE,
        i_pat_pregn_hist     IN pat_pregnancy_hist.id_pat_pregnancy_hist%TYPE,
        i_flg_complication   IN pat_pregnancy.flg_complication%TYPE,
        i_notes_complication IN pat_pregnancy.notes_complications%TYPE
    ) RETURN VARCHAR2;

    --

    FUNCTION check_break_summ_pg_notes
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_flg_type IN pat_pregnancy.flg_type%TYPE,
        i_notes    IN pat_pregnancy.notes%TYPE
    ) RETURN VARCHAR2;

    --

    FUNCTION check_break_summ_pg_out
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_flg_type          IN pat_pregnancy.flg_type%TYPE,
        i_pat_pregnancy     IN pat_pregnancy.id_pat_pregnancy%TYPE,
        i_flg_status        IN pat_pregnancy.flg_status%TYPE,
        i_dt_intervention   IN pat_pregnancy.dt_intervention%TYPE,
        i_inst_intervention IN pat_pregnancy.id_inst_intervention%TYPE,
        i_flg_intervention  IN pat_pregnancy.flg_desc_intervention%TYPE,
        i_desc_intervention IN pat_pregnancy.desc_intervention%TYPE
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * Checks if a specific pregnancy has complications
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_pat_pregnancy          Pregnancy ID
    *                        
    * @return                         pregnancy outcome
    * 
    * @author                         José Silva
    * @version                        2.5.1.5
    * @since                          2011/04/11
    **********************************************************************************************/
    FUNCTION check_pregn_complications
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_pat_pregnancy      IN pat_pregnancy.id_pat_pregnancy%TYPE,
        i_flg_complication   IN pat_pregnancy.flg_complication%TYPE,
        i_notes_complication IN pat_pregnancy.notes_complications%TYPE,
        i_flg_type           IN pat_pregnancy.flg_type%TYPE DEFAULT NULL
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * Checks if a specific pregnancy code already exists
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_pat_pregnancy          pregnancy ID (when this function is called within a pregnancy edition)
    * @param i_code_state             State code
    * @param i_code_year              Year code
    * @param i_code_number            Numeric code
    * @param i_flg_type               Type of pregnancy code: S - SIS prenatal (brazilian market)
    *                        
    * @return                         code already exists: (Y)es or (N)o
    * 
    * @author                         José Silva
    * @version                        2.5.1.5
    * @since                          2011/04/12
    **********************************************************************************************/
    FUNCTION check_pregnancy_code
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_pat_pregnancy IN pat_pregnancy.id_pat_pregnancy%TYPE,
        i_code_state    IN pat_pregnancy_code.code_state%TYPE,
        i_code_year     IN pat_pregnancy_code.code_year%TYPE,
        i_code_number   IN pat_pregnancy_code.code_number%TYPE,
        i_flg_type      IN pat_pregnancy_code.flg_type%TYPE
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * Gets the formatted pregnancy code
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_code_state             State code
    * @param i_code_year              Year code
    * @param i_code_number            Numeric code
    * @param i_flg_type               Type of pregnancy code: S - SIS prenatal (brazilian market)
    *                        
    * @return                         code already exists: (Y)es or (N)o
    * 
    * @author                         José Silva
    * @version                        2.5.1.5
    * @since                          2011/04/12
    **********************************************************************************************/
    FUNCTION get_pat_pregnancy_code
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_pat_pregnancy      IN pat_pregnancy.id_pat_pregnancy%TYPE,
        i_pat_pregnancy_hist IN pat_pregnancy_hist.id_pat_pregnancy%TYPE
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * Gets the formatted pregnancy code
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_code_state             State code
    * @param i_code_year              Year code
    * @param i_code_number            Numeric code
    * @param i_flg_type               Type of pregnancy code: S - SIS prenatal (brazilian market)
    *                        
    * @return                         code already exists: (Y)es or (N)o
    * 
    * @author                         José Silva
    * @version                        2.5.1.5
    * @since                          2011/04/12
    **********************************************************************************************/
    FUNCTION get_desc_pregnancy_code
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_code_state  IN pat_pregnancy_code.code_state%TYPE,
        i_code_year   IN pat_pregnancy_code.code_year%TYPE,
        i_code_number IN pat_pregnancy_code.code_number%TYPE
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * Gets the serialized pregnancy code to be used in the keypad
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_code_state             State code
    * @param i_code_year              Year code
    * @param i_code_number            Numeric code
    *                        
    * @return                         code already exists: (Y)es or (N)o
    * 
    * @author                         José Silva
    * @version                        2.5.1.5
    * @since                          2011/04/14
    **********************************************************************************************/
    FUNCTION get_serialized_code
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_code_state  IN pat_pregnancy_code.code_state%TYPE,
        i_code_year   IN pat_pregnancy_code.code_year%TYPE,
        i_code_number IN pat_pregnancy_code.code_number%TYPE
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * Gets the serialized pregnancy code
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_pat_pregnancy          Pregnancy ID
    *                        
    * @return                         serialized code
    * 
    * @author                         José Silva
    * @version                        2.5.1.9
    * @since                          24-11-2011
    **********************************************************************************************/
    FUNCTION get_serialized_code
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_pat_pregnancy IN pat_pregnancy.id_pat_pregnancy%TYPE
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * Gets the next available pregnancy code
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_code_state             State code
    * @param i_code_year              Year code
    * @param i_starting_number        Serie starting number
    * @param i_ending_number          Serie ending number
    *                        
    * @return                         Next available pregnancy code
    * 
    * @author                         José Silva
    * @version                        2.5.1.5
    * @since                          2011/04/13
    **********************************************************************************************/
    FUNCTION get_pregnancy_next_code
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_code_state      IN pat_pregnancy_code.code_state%TYPE,
        i_code_year       IN pat_pregnancy_code.code_year%TYPE,
        i_starting_number IN NUMBER,
        i_ending_number   IN NUMBER
    ) RETURN pat_pregnancy_code.code_number%TYPE;

    /********************************************************************************************
    * Gets the pregnancy trimester (based on the ultrasound criteria)
    * 
    * @param   i_lang                language associated to the professional executing the request
    * @param   i_prof                professional id, software and institution
    * @param   i_flg_weeks_criteria  Weeks criteria (C - chronologic, U - ultrasound)
    * @param   i_dt_init_preg_lmp    Pregnancy initial date (chronologic criteria)
    * @param   i_dt_exam_result_tstz Exam result date
    * @param   i_weeks_pregnancy     Gestation weeks (ultrasound criteria)
    *
    * @RETURN  Pregnancy trimester
    *
    * @author  José Silva
    * @version 1.0
    * @since   14-04-2011
    **********************************************************************************************/
    FUNCTION get_ultrasound_trimester
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_flg_weeks_criteria  IN exam_result_pregnancy.flg_weeks_criteria%TYPE,
        i_dt_init_preg_lmp    IN pat_pregnancy.dt_init_preg_lmp%TYPE,
        i_dt_exam_result_tstz IN exam_result.dt_exam_result_tstz%TYPE,
        i_weeks_pregnancy     IN exam_result_pregnancy.weeks_pregnancy%TYPE
    ) RETURN NUMBER;

    /********************************************************************************************
    * Gets the number of fetus of a specific pregnancy
    * 
    * @param   i_lang                language associated to the professional executing the request
    * @param   i_prof                professional id, software and institution
    * @param   i_pat_pregnancy       pregnancy ID
    *
    * @RETURN  Number of fetus
    *
    * @author  José Silva
    * @version 2.5.1.5
    * @since   30-05-2011
    **********************************************************************************************/
    FUNCTION get_fetus_number
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_pat_pregnancy IN pat_pregnancy.id_pat_pregnancy%TYPE
    ) RETURN NUMBER;

    /********************************************************************************************
    * Gets a specific fetus record ID
    * 
    * @param   i_lang                language associated to the professional executing the request
    * @param   i_prof                professional id, software and institution
    * @param   i_pat_pregnancy       pregnancy ID
    * @param   i_fetus_number        fetus number
    *
    * @RETURN  Number of fetus
    *
    * @author  José Silva
    * @version 2.5.1.5
    * @since   30-05-2011
    **********************************************************************************************/
    FUNCTION get_pregn_fetus_id
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_pat_pregnancy IN pat_pregnancy.id_pat_pregnancy%TYPE,
        i_fetus_number  IN pat_pregn_fetus.fetus_number%TYPE
    ) RETURN pat_pregn_fetus.id_pat_pregn_fetus%TYPE;

    /********************************************************************************************
    * Get all the pregnants that will be exported to the SISPRENATAL archive
    * 
    * @param   i_lang                language associated to the professional executing the request
    * @param   i_prof                professional id, software and institution
    * @param   i_scope               scope of the extraction: (I)nside or (O)utside pregnancies (based on the SISPRENATAL code)
    * @param   o_patient             patient IDs
    * @param   o_pat_pregnancy       pregnancy IDs
    *
    * @return                        true or false on success or error
    *
    * @author  José Silva
    * @version 2.5.1.9
    * @since   17-11-2011
    **********************************************************************************************/
    FUNCTION get_pat_sisprenatal
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_scope         IN VARCHAR2,
        i_institution   IN institution.id_institution%TYPE,
        o_patient       OUT table_number,
        o_pat_pregnancy OUT table_number,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get the last menstruation date of a given pregnancy
    * 
    * @param   i_lang                language associated to the professional executing the request
    * @param   i_prof                professional id, software and institution
    * @param   i_pat_pregnancy       pregnancy ID
    *
    * @RETURN  Last menstuation date
    *
    * @author  José Silva
    * @version 2.5.1.9
    * @since   18-11-2011
    **********************************************************************************************/
    FUNCTION get_dt_lmp_pregn
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_pat_pregnancy IN pat_pregnancy.id_pat_pregnancy%TYPE
    ) RETURN pat_pregnancy.dt_last_menstruation%TYPE;

    /********************************************************************************************
    * Get the date of the first episode that occured during the pregnancy
    * 
    * @param   i_lang                language associated to the professional executing the request
    * @param   i_prof                professional id, software and institution
    * @param   i_pat_pregnancy       pregnancy ID
    * @param   i_flg_type_date       return date: (F)irst or (L)ast episode
    *
    * @RETURN  First or last episode date
    *
    * @author  José Silva
    * @version 2.5.1.9
    * @since   18-11-2011
    **********************************************************************************************/
    FUNCTION get_pregn_dt_epis
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_pat_pregnancy IN pat_pregnancy.id_pat_pregnancy%TYPE,
        i_flg_type_date IN VARCHAR2
    ) RETURN DATE;

    /********************************************************************************************
    * Get the SISPRENATAL code that represents the pregnancy episode type 
    * 
    * @param   i_lang                language associated to the professional executing the request
    * @param   i_prof                professional id, software and institution
    * @param   i_pregn_dt_interv     pregnancy labour/abortion date
    * @param   i_pregn_flg_status    pregnancy status
    * @param   i_epis_dt_begin       episode begin date
    * @param   i_epis_dt_end         episode end date
    *
    * @RETURN  Episode code
    *
    * @author  José Silva
    * @version 2.5.1.9
    * @since   21-11-2011
    **********************************************************************************************/
    FUNCTION get_pregn_episode_type
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_pregn_dt_interv  IN pat_pregnancy.dt_intervention%TYPE,
        i_pregn_flg_status IN pat_pregnancy.flg_status%TYPE,
        i_epis_dt_begin    IN episode.dt_begin_tstz%TYPE,
        i_epis_dt_end      IN episode.dt_end_tstz%TYPE
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * Get the SISPRENATAL code that represents the labour/abortion location 
    * 
    * @param   i_lang                language associated to the professional executing the request
    * @param   i_prof                professional id, software and institution
    * @param   i_pregn_flg_interv    labour/abortion location
    *
    * @RETURN  Location code
    *
    * @author  José Silva
    * @version 2.5.1.9
    * @since   22-11-2011
    **********************************************************************************************/
    FUNCTION get_pregn_location_code
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_pregn_flg_interv IN pat_pregnancy.flg_desc_intervention%TYPE
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * Get the pregnancy birth type
    * 
    * @param   i_lang                language associated to the professional executing the request
    * @param   i_prof                professional id, software and institution
    * @param   i_pat_pregnancy       pregnancy ID
    *
    * @RETURN  pregnancy birth type
    *
    * @author  José Silva
    * @version 2.5.1.9
    * @since   22-11-2011
    **********************************************************************************************/
    FUNCTION get_pregn_birth_type
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_pat_pregnancy IN pat_pregnancy.id_pat_pregnancy%TYPE
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * Get the SISPRENATAL code that represents the pregnancy interruption type 
    * 
    * @param   i_lang                language associated to the professional executing the request
    * @param   i_prof                professional id, software and institution
    * @param   i_pat_pregnancy       pregnancy ID
    * @param   i_pregn_flg_status    pregnancy status
    *
    * @RETURN  Type of abortion
    *
    * @author  José Silva
    * @version 2.5.1.9
    * @since   25-11-2011
    **********************************************************************************************/
    FUNCTION get_pregn_inter_type
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_pat_pregnancy    IN pat_pregnancy.id_pat_pregnancy%TYPE,
        i_pregn_flg_status IN pat_pregnancy.flg_status%TYPE
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * Checks if a specific pregnancy has an early puerperal period
    * 
    * @param   i_lang                language associated to the professional executing the request
    * @param   i_prof                professional id, software and institution
    * @param   i_dt_init_pregn       pregnancy begin date
    * @param   i_dt_intervention     pregnancy end date
    *
    * @RETURN  Early puerperal code
    *
    * @author  José Silva
    * @version 2.5.1.10
    * @since   13-12-2011
    **********************************************************************************************/
    FUNCTION get_pregn_early_puerperal
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_dt_init_pregn   IN pat_pregnancy.dt_init_pregnancy%TYPE,
        i_dt_intervention IN pat_pregnancy.dt_intervention%TYPE
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * Get the first episode ID after the pregnancy begin date
    * 
    * @param   i_lang                language associated to the professional executing the request
    * @param   i_prof                professional id, software and institution
    * @param   i_dt_init_pregn       pregnancy begin date
    *
    * @RETURN  Episode ID
    *
    * @author  José Silva
    * @version 2.5.1.11
    * @since   29-12-2011
    **********************************************************************************************/
    FUNCTION get_pregn_first_epis
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_patient       IN patient.id_patient%TYPE,
        i_dt_init_pregn IN pat_pregnancy.dt_init_pregnancy%TYPE
    ) RETURN episode.id_episode%TYPE;

    FUNCTION get_flg_pregn_out_type
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_episode   IN episode.id_episode%TYPE,
        o_flg_pregn OUT pat_pregnancy.flg_preg_out_type%TYPE,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Returns the last recorded values of pregnancies numbers (number of abortion, birth and getation)
    *
    * @param i_lang                   language identifier
    * @param i_prof                   logged professional structure
    * @param i_id_patient             Patient identifier
    *
    * @param o_pregn_summ             Array with last registered numbers for pregnancies summary
    * @param o_error                  error information
    *
    * @return                         false if errors occur, true otherwise
    *
    * @author                         Anna Kurowska
    * @version                        2.7.1
    * @since                          07-Aug-2017
    */
    FUNCTION get_last_preg_numbers
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE,
        o_pregn_summ OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_preg_weeks_unk
    (
        i_prof                IN profissional,
        i_dt_preg             IN DATE,
        i_dt_reg              IN pat_pregnancy.dt_intervention%TYPE,
        i_weeks               IN pat_pregnancy.num_gest_weeks%TYPE,
        i_flg_gest_weeks      IN pat_pregnancy.flg_gest_weeks%TYPE,
        i_flg_gest_weeks_exam IN pat_pregnancy.flg_gest_weeks_exam%TYPE,
        i_flg_gest_weeks_us   IN pat_pregnancy.flg_gest_weeks_us%TYPE
    ) RETURN NUMBER;

    g_touch_option    CONSTANT VARCHAR2(1) := 'D';
    g_free_text       CONSTANT VARCHAR2(1) := 'N';
    g_flg_available_y CONSTANT VARCHAR2(1) := 'Y';

    g_doc_area_past_hist    CONSTANT doc_area.id_doc_area%TYPE := 1049;
    g_doc_area_curr_pregn   CONSTANT doc_area.id_doc_area%TYPE := 1099;
    g_doc_area_obs_hist     CONSTANT doc_area.id_doc_area%TYPE := 2000;
    g_doc_area_obs_adv      CONSTANT doc_area.id_doc_area%TYPE := 2001;
    g_doc_area_obs_idx      CONSTANT doc_area.id_doc_area%TYPE := 6750;
    g_doc_area_obs_idx_tmpl CONSTANT doc_area.id_doc_area%TYPE := 36111;
    g_doc_area_preg_data    CONSTANT doc_area.id_doc_area%TYPE := 1097;

    g_doc_area_labor CONSTANT doc_area.id_doc_area%TYPE := 1047;
    g_doc_area_born  CONSTANT doc_area.id_doc_area%TYPE := 1048;

    g_pat_pregn_active CONSTANT pat_pregnancy.flg_status%TYPE := 'A';
    g_pat_pregn_past   CONSTANT pat_pregnancy.flg_status%TYPE := 'P';
    g_pat_pregn_cancel CONSTANT pat_pregnancy.flg_status%TYPE := 'C';
    g_pat_pregn_no     CONSTANT pat_pregnancy.flg_status%TYPE := 'N';

    g_pregn_fetus_dead   CONSTANT pat_pregn_fetus.flg_status%TYPE := 'D';
    g_pregn_fetus_alive  CONSTANT pat_pregn_fetus.flg_status%TYPE := 'A';
    g_pregn_fetus_cancel CONSTANT pat_pregn_fetus.flg_status%TYPE := 'C';
    g_pregn_fetus_unk    CONSTANT pat_pregn_fetus.flg_status%TYPE := 'U';
    g_pregn_fetus_an     CONSTANT pat_pregn_fetus.flg_status%TYPE := 'AN';
    g_pregn_fetus_si     CONSTANT pat_pregn_fetus.flg_status%TYPE := 'SI';

    g_pat_pregn_type_c  CONSTANT VARCHAR2(1) := 'C';
    g_pat_pregn_type_r  CONSTANT VARCHAR2(1) := 'R';
    g_pat_pregn_type_cr CONSTANT VARCHAR2(2) := 'CR';
    g_pat_pregn_type_ab CONSTANT pat_pregnancy.flg_preg_out_type%TYPE := 'AB';
    g_pat_pregn_type_b  CONSTANT pat_pregnancy.flg_preg_out_type%TYPE := 'B';

    g_pbg_active CONSTANT pat_blood_group.flg_status%TYPE := 'A';

    g_pat_pregn_extract_y CONSTANT pat_pregnancy.flg_extraction%TYPE := 'Y';

    g_pregn_viewer_cat_1  CONSTANT NUMBER := 1;
    g_pregn_viewer_cat_2  CONSTANT NUMBER := 2;
    g_pregn_viewer_cat_3  CONSTANT NUMBER := 3;
    g_domain_pregn_viewer CONSTANT sys_domain.code_domain%TYPE := 'PREGNANCY_VIEWER_CATEGORY';

    g_lower_limit CONSTANT VARCHAR2(1) := 'L';
    g_upper_limit CONSTANT VARCHAR2(1) := 'U';
    g_max_pregn   CONSTANT NUMBER := 999;

    g_flg_weight_l   CONSTANT VARCHAR2(1) := 'L';
    g_flg_weight_u   CONSTANT VARCHAR2(1) := 'U';
    g_flg_dead_fetus CONSTANT VARCHAR2(1) := 'D';
    g_flg_abortion   CONSTANT VARCHAR2(1) := 'A';
    g_flg_pre_labor  CONSTANT VARCHAR2(1) := 'P';
    g_flg_cesarean   CONSTANT VARCHAR2(1) := 'C';

    g_current_episode_yes CONSTANT VARCHAR2(1) := 'Y';
    g_current_episode_no  CONSTANT VARCHAR2(1) := 'N';
    g_flg_det_no          CONSTANT VARCHAR(1) := 'N';

    g_code_domain CONSTANT sys_domain.code_domain%TYPE := 'PAT_PREGNANCY.DESC_INTERVENTION';
    g_data_i      CONSTANT VARCHAR2(1) := 'I';
    g_flg_type_r  CONSTANT VARCHAR2(1) := 'R';

    g_flg_assist_p CONSTANT pat_pregn_inst_assist.flg_type%TYPE := 'P';
    g_flg_assist_l CONSTANT pat_pregn_inst_assist.flg_type%TYPE := 'L';

    g_flg_no_prob CONSTANT pat_pregnancy.flg_complication%TYPE := 'S';

    g_other_hospital CONSTANT pat_pregnancy.flg_type%TYPE := 'O';

    g_flg_dt_val_s CONSTANT VARCHAR2(1) := 'S';
    g_flg_dt_val_v CONSTANT VARCHAR2(1) := 'V';

    g_blood_rhesus_p CONSTANT pat_blood_group.flg_blood_rhesus%TYPE := 'P';
    g_blood_rhesus_n CONSTANT pat_blood_group.flg_blood_rhesus%TYPE := 'N';

    g_type_summ CONSTANT VARCHAR2(10) := 'S';
    g_type_det  CONSTANT VARCHAR2(10) := 'D';

    g_obs_idx_gp   CONSTANT VARCHAR2(10 CHAR) := 'GP';
    g_obs_idx_tpal CONSTANT VARCHAR2(10 CHAR) := 'TPAL';

    g_type_obs_idx_t CONSTANT VARCHAR2(1 CHAR) := 'T';
    g_type_obs_idx_c CONSTANT VARCHAR2(1 CHAR) := 'C';

    g_dt_flg_precision_h CONSTANT pat_pregnancy.flg_dt_interv_precision%TYPE := 'H';
    g_dt_flg_precision_d CONSTANT pat_pregnancy.flg_dt_interv_precision%TYPE := 'D';
    g_dt_flg_precision_m CONSTANT pat_pregnancy.flg_dt_interv_precision%TYPE := 'M';
    g_dt_flg_precision_y CONSTANT pat_pregnancy.flg_dt_interv_precision%TYPE := 'Y';

    g_pregn_code_s CONSTANT pat_pregnancy_code.flg_type%TYPE := 'S';

    g_ultrasound_criteria CONSTANT exam_result_pregnancy.flg_weeks_criteria%TYPE := 'U';
    g_pregnant_criteria   CONSTANT exam_result_pregnancy.flg_weeks_criteria%TYPE := 'C';

    g_flg_view_preg_summ CONSTANT vs_soft_inst.flg_view%TYPE := 'PS';

    g_unit_meas_type_preg     CONSTANT unit_measure_type.id_unit_measure_type%TYPE := 2;
    g_unit_meas_sub_type_preg CONSTANT unit_measure_subtype.id_unit_measure_subtype%TYPE := 10;

    g_adverse_weight_um_id CONSTANT unit_measure.id_unit_measure%TYPE := 15;

    g_desc_intervention_inst   CONSTANT pat_pregnancy.flg_desc_intervention%TYPE := 'I';
    g_desc_intervention_home   CONSTANT pat_pregnancy.flg_desc_intervention%TYPE := 'D';
    g_desc_intervention_other  CONSTANT pat_pregnancy.flg_desc_intervention%TYPE := 'O';
    g_desc_contract_type_other CONSTANT NUMBER(1) := -1;

    g_pat_pregn_auto_close CONSTANT pat_pregnancy.flg_status%TYPE := 'AC';
    g_pat_pregn_birth      CONSTANT pat_pregnancy.flg_status%TYPE := 'B';

    g_multichoice_type_contrac CONSTANT VARCHAR2(4000) := 'PAT_PREG_CONT_TYPE.ID_CONTRAC_TYPE';

    g_gest_weeks_unknown CONSTANT pat_pregnancy.flg_gest_weeks%TYPE := 'U';

END pk_pregnancy_core;
/
