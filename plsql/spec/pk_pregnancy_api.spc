/*-- Last Change Revision: $Rev: 2028864 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:48:25 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_pregnancy_api IS

    -- Author  : JOSE.SILVA
    -- Created : 15-11-2011 10:22:25 

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
    * Gets the formatted pregnancy code
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
    * @param i_dt_intervention        Pregnancy start date
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
    *
    * @RETURN  first episode date
    *
    * @author  José Silva
    * @version 2.5.1.9
    * @since   18-11-2011
    **********************************************************************************************/
    FUNCTION get_pregn_dt_first_epis
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_pat_pregnancy IN pat_pregnancy.id_pat_pregnancy%TYPE
    ) RETURN DATE;

    /********************************************************************************************
    * Get the date of the last episode that occured during the pregnancy
    * 
    * @param   i_lang                language associated to the professional executing the request
    * @param   i_prof                professional id, software and institution
    * @param   i_pat_pregnancy       pregnancy ID
    *
    * @RETURN  last episode date
    *
    * @author  José Silva
    * @version 2.5.1.9
    * @since   18-11-2011
    **********************************************************************************************/
    FUNCTION get_pregn_dt_last_epis
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_pat_pregnancy IN pat_pregnancy.id_pat_pregnancy%TYPE
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

    /**
    * Get the pregnancy gestation risk
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)
    * @param   i_patient                   Patient ID
    *
    * @return  gestation risk code
    *
    * @author  JOSE.SILVA
    * @version 2.5.1.9
    * @since   22-11-2011
    */
    FUNCTION get_pregn_gest_risk
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE
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
    * Get the SISPRENATAL code that represents the child birth type 
    * 
    * @param   i_lang                language associated to the professional executing the request
    * @param   i_prof                professional id, software and institution
    * @param   i_pat_pregnancy       pregnancy ID
    *
    * @RETURN  birth type code
    *
    * @author  José Silva
    * @version 2.5.1.9
    * @since   22-11-2011
    **********************************************************************************************/
    FUNCTION get_pregn_birthtype_code
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_pat_pregnancy IN pat_pregnancy.id_pat_pregnancy%TYPE
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * Get the SISPRENATAL code that represents a given vaccine 
    * 
    * @param   i_lang                language associated to the professional executing the request
    * @param   i_prof                professional id, software and institution
    * @param   i_patient             patient ID
    * @param   i_def_vacc_alert      mapping value (Alert)
    * @param   i_def_vacc_ext        mapping value (External system)
    * @param   i_ret_type            type of code: V - ID, D - Dose
    *
    * @RETURN  vaccine code
    *
    * @author  José Silva
    * @version 2.5.1.9
    * @since   22-11-2011
    **********************************************************************************************/
    FUNCTION get_pregn_vacc_doses
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_patient        IN patient.id_patient%TYPE,
        i_def_vacc_alert IN VARCHAR2,
        i_def_vacc_ext   IN VARCHAR2,
        i_ret_type       IN VARCHAR2
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * Get all the lab test content IDs that are available in SISPRENATAL 
    * 
    * @param   i_lang                language associated to the professional executing the request
    * @param   i_prof                professional id, software and institution
    * @param   i_def_lab             mapping value
    * @param   o_id_contents         content IDs
    * @param   o_code_sisprenatal    code to be exported when there are available results
    * @param   o_error               Error message, if an error occurred.
    *
    * @return True if successful, false otherwise.
    *
    * @author  José Silva
    * @version 2.5.1.9
    * @since   23-11-2011
    **********************************************************************************************/
    FUNCTION get_pregn_lab_ids
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_def_lab          IN VARCHAR2,
        o_id_contents      OUT table_varchar,
        o_code_sisprenatal OUT VARCHAR2,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get the SISPRENATAL code that represents a given lab test
    * 
    * @param   i_lang                language associated to the professional executing the request
    * @param   i_prof                professional id, software and institution
    * @param   i_patient             patient ID
    * @param   i_dt_min_lab_result   pregnancy start date
    * @param   i_id_contents         content IDs
    * @param   i_code_sisprenatal    SISPRENATAL code to be exported
    *
    * @RETURN  lab test code (1 or 0)
    *
    * @author  José Silva
    * @version 2.5.1.9
    * @since   23-11-2011
    **********************************************************************************************/
    FUNCTION get_pregn_lab_code
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_patient           IN patient.id_patient%TYPE,
        i_dt_min_lab_result IN pat_pregnancy.dt_init_pregnancy%TYPE,
        i_id_contents       IN table_varchar,
        i_code_sisprenatal  IN VARCHAR2
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

    /**
    * This function ables the user to add a new born record according to CCH specifications.
    *
    * @param IN  i_lang               Language ID
    * @param IN  i_prof               Professional structure
    * @param IN  i_epis               ID EPISODE
    * @param IN  i_epis_documentation ID_EPIS_DOCUMENTATION (When null => New record)
    * @param IN  i_newborn_name       Newborn name
    * @param IN  i_dt_birth           ARRAY of newborn birth dates
    * @param IN  i_newborn_gender     ARRAY of newborn genders (M-Male/F-Female/I-Undefined)
    * @param IN  i_newborn_weight     ARRAY of newborn weights
    * @param IN  i_newborn_weight_um  ARRAY of newborn weight unit measures (Kg by default)
    * @param IN  i_newborn_state      ARRAY of newborn state (A-Alive/D-Dead)
    * @param IN  i_delivery_type      Type of delivery ('CS' - Cesarian, etc.) (Values mapped in documentation_ext)
    * @param IN  i_notes              ARRAY of newborn notes
    * @param IN  i_pat_pregnancy      ID_PAT_PREGNANCY
    * @param OUT o_epis_documentation ARRAY of ID_EPIS_DDOCUMENTATION
    * @param OUT o_child_number       Number of the child of the current pregnancy
    * @param OUT o_error              Error structure
    * 
    * @version  2.7.1.5
    * @since    2017/10/18
    * @author   Diogo Oliveira
    */

    FUNCTION set_newborn_record
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_epis               IN episode.id_episode%TYPE,
        i_epis_documentation IN table_number,
        i_flg_action         IN VARCHAR2,
        i_newborn_name       IN table_varchar,
        i_dt_birth           IN table_varchar,
        i_newborn_gender     IN table_varchar,
        i_newborn_weight     IN table_number,
        i_newborn_weight_um  IN table_number,
        i_newborn_state      IN table_varchar,
        i_delivery_type      IN VARCHAR2,
        i_notes              IN table_varchar,
        i_pat_pregnancy      IN pat_pregnancy.id_pat_pregnancy%TYPE,
        o_epis_documentation OUT table_number,
        o_child_number       OUT table_number,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Cancels newborn records
    * 
    * @param   i_lang                language associated to the professional
    * @param   i_prof                professional id, software and institution
    * @param   i_epis_documentation  Array of the ID_epis_documentation to be cancelled.
    * @param   i_pat_pregnancy       ID_PAT_PREGNANCY          
    * @param   i_id_cancel_reason    Array of cancel reasons
    * @param   i_cancel_notes        Array of cancel notes
    *
    * @RETURN  o_error  
    * NOTE: The record will only be inactivated if there is still no episode created for the newborn         
    **********************************************************************************************/

    FUNCTION cancel_newborn_record
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_epis_documentation IN table_number,
        i_pat_pregnancy      IN pat_pregnancy.id_pat_pregnancy%TYPE,
        i_id_cancel_reason   IN table_number,
        i_cancel_notes       IN table_varchar,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Sets pregnancy records
    * 
    * @param   i_lang                  language associated to the professional
    * @param   i_prof                  professional id, software and institution
    * @param   i_episode               Episode ID of the mother
    * @param   i_pat_pregnancy         ID_PAT_PREGNANCY (This parameter is null when documenting a new record)
    * @param   i_dt_last_menstruation  Date of last menstruation (Optional) 
    * @param   i_num_weeks             Number of weeks of gestation
    * @param   i_num_days              Number of days of gestation (The total time of gestation considers the n.weekes + n.days) 
    * @param   i_n_children            Number of fetus (Mandatory)
    * @param   i_dt_expected_birth     Date expected for delivery (Optional - Automatically calculated when previous parameters are documented)                                      
    *
    * @RETURN  o_id_pat_pregnancy
    * @RETURN  o_error            
    **********************************************************************************************/

    FUNCTION set_pregnancy_record
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_episode              IN episode.id_episode%TYPE,
        i_pat_pregnancy        IN pat_pregnancy.id_pat_pregnancy%TYPE,
        i_dt_last_menstruation IN VARCHAR2,
        i_num_weeks            IN NUMBER,
        i_num_days             IN NUMBER,
        i_n_children           IN NUMBER,
        i_dt_expected_birth    IN VARCHAR2,
        o_id_pat_pregnancy     OUT pat_pregnancy.id_pat_pregnancy%TYPE,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Cancels pregnancy records
    * 
    * @param   i_lang                language associated to the professional
    * @param   i_prof                professional id, software and institution
    * @param   i_patient             ID_PATIENT
    * @param   i_pat_pregnancy       ID_PAT_PREGNANCY 
    *         
    * @RETURN  o_error         
    **********************************************************************************************/

    FUNCTION cancel_pregnancy_record
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_patient       IN patient.id_patient%TYPE,
        i_pat_pregnancy IN pat_pregnancy.id_pat_pregnancy%TYPE,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Sets the delivery assessment (Characterization of the delivery)
    * 
    * @param   i_lang                  language associated to the professional
    * @param   i_prof                  professional id, software and institution
    * @param   i_episode               Episode ID of the mother
    * @param   i_epis_documentation    ID_EPIS_DOCUMENTATION (For new records this value is sent as null)                                      
    * @param   i_pat_pregnancy         ID_PAT_PREGNANCY
    * @param   i_type_delivery         Array of type of delivery for each fetus (type_fetus_1,type_fetus2,...)
    *
    * @RETURN  o_epis_documentation
    * @RETURN  o_error          
    **********************************************************************************************/

    FUNCTION set_delivery_assessment
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_episode            IN episode.id_episode%TYPE,
        i_epis_documentation IN epis_documentation.id_epis_documentation%TYPE,
        i_pat_pregnancy      IN pat_pregnancy.id_pat_pregnancy%TYPE,
        i_type_delivery      IN table_varchar,
        o_epis_documentation OUT epis_documentation.id_epis_documentation%TYPE,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Creates an episode for the newborn if i_child_episode is null and associates the newborn to the mother
    * 
    * @param   i_lang                  language associated to the professional
    * @param   i_prof                  professional id, software and institution
    * @param   i_patient               ID_PATIENT of the mother
    * @param   i_pat_pregnancy         ID_PAT_PREGNANCY
    * @param   i_epis_documentation    ID_EPIS_DOCUMENTATION of the newborn record
    * @param   i_child_number          Child number
    * @param   i_new_patient           ID of the new patient (Id created via ADT)
    * @param   i_child_episode         ID episode of the child (IF null a new episode is created)      
    *
    * @RETURN  o_episode
    * @RETURN  o_patient
    * @RETURN  o_error              
    **********************************************************************************************/

    FUNCTION create_child_episode
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_patient            IN patient.id_patient%TYPE,
        i_pat_pregnancy      IN pat_pregnancy.id_pat_pregnancy%TYPE,
        i_epis_documentation IN epis_documentation.id_epis_documentation%TYPE,
        i_child_number       IN epis_doc_delivery.child_number%TYPE,
        i_new_patient        IN patient.id_patient%TYPE,
        i_child_episode      IN episode.id_episode%TYPE DEFAULT NULL,
        o_episode            OUT episode.id_episode%TYPE,
        o_patient            OUT patient.id_patient%TYPE,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    -- sisprenatal global variables
    g_def_sisprenatal_alert VARCHAR2(4000);
    g_a_values              pk_map.typ_map_value;
    g_b_values              pk_map.typ_map_value;

    g_flg_dt_first_epis CONSTANT VARCHAR2(1 CHAR) := 'F';
    g_flg_dt_last_epis  CONSTANT VARCHAR2(1 CHAR) := 'L';

    --global variables for pregnancy delivery
    g_doc_area_partogram     CONSTANT doc_area.id_doc_area%TYPE := 1048;
    g_doc_template_partogram CONSTANT doc_template.id_doc_template%TYPE := 506535;

    --delivery assessment
    g_doc_area_delivery_assessment CONSTANT doc_area.id_doc_area%TYPE := 1047;

    g_unit_measure_g CONSTANT unit_measure.id_unit_measure%TYPE := 15;
    g_id_doc_crit_kg CONSTANT doc_element_crit.id_doc_element_crit%TYPE := 5121352;

END pk_pregnancy_api;
/
