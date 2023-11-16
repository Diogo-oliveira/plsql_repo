/*-- Last Change Revision: $Rev: 2027489 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:42:23 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_pregnancy_api IS

    /* CAN'T TOUCH THIS */
    g_error   VARCHAR2(1000 CHAR);
    g_owner   VARCHAR2(30 CHAR);
    g_package VARCHAR2(30 CHAR);
    g_exception EXCEPTION;

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
    ) RETURN pat_pregnancy_code.code_number%TYPE IS
    BEGIN
        RETURN pk_pregnancy_core.get_pregnancy_next_code(i_lang            => i_lang,
                                                         i_prof            => i_prof,
                                                         i_code_state      => i_code_state,
                                                         i_code_year       => i_code_year,
                                                         i_starting_number => i_starting_number,
                                                         i_ending_number   => i_ending_number);
    END get_pregnancy_next_code;

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
    ) RETURN VARCHAR2 IS
    BEGIN
        RETURN pk_pregnancy_core.get_desc_pregnancy_code(i_lang        => i_lang,
                                                         i_prof        => i_prof,
                                                         i_code_state  => i_code_state,
                                                         i_code_year   => i_code_year,
                                                         i_code_number => i_code_number);
    END get_desc_pregnancy_code;

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
    ) RETURN NUMBER IS
    BEGIN
        RETURN pk_pregnancy_core.get_fetus_number(i_lang          => i_lang,
                                                  i_prof          => i_prof,
                                                  i_pat_pregnancy => i_pat_pregnancy);
    END get_fetus_number;

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
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        RETURN pk_pregnancy_core.set_pat_pregn_delivery(i_lang                => i_lang,
                                                        i_prof                => i_prof,
                                                        i_pat_pregnancy       => i_pat_pregnancy,
                                                        i_doc_area            => i_doc_area,
                                                        i_fetus_number        => i_fetus_number,
                                                        i_flg_type            => i_flg_type,
                                                        i_flg_child_gender    => i_flg_child_gender,
                                                        i_flg_childbirth_type => i_flg_childbirth_type,
                                                        i_flg_child_status    => i_flg_child_status,
                                                        i_child_weight        => i_child_weight,
                                                        i_weight_um           => i_weight_um,
                                                        i_dt_intervention     => i_dt_intervention,
                                                        i_desc_intervention   => i_desc_intervention,
                                                        i_flg_desc_interv     => i_flg_desc_interv,
                                                        i_id_inst_interv      => i_id_inst_interv,
                                                        i_notes_complications => i_notes_complications,
                                                        i_epis_documentation  => i_epis_documentation,
                                                        o_msg_error           => o_msg_error,
                                                        o_error               => o_error);
    END set_pat_pregn_delivery;

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
    ) RETURN BOOLEAN IS
    
    BEGIN
        RETURN pk_pregnancy_core.set_pat_pregnancy_hist(i_lang          => i_lang,
                                                        i_pat_pregnancy => i_pat_pregnancy,
                                                        o_error         => o_error);
    END set_pat_pregnancy_hist;

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
    ) RETURN NUMBER IS
    
    BEGIN
        RETURN pk_pregnancy_core.get_pregnancy_weeks(i_prof    => i_prof,
                                                     i_dt_preg => i_dt_preg,
                                                     i_dt_reg  => i_dt_reg,
                                                     i_weeks   => i_weeks);
    END get_pregnancy_weeks;

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
    ) RETURN NUMBER IS
    
    BEGIN
        RETURN pk_pregnancy_core.get_pregnancy_days(i_prof    => i_prof,
                                                    i_dt_preg => i_dt_preg,
                                                    i_dt_reg  => i_dt_reg,
                                                    i_weeks   => i_weeks);
    END get_pregnancy_days;

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
    ) RETURN DATE IS
    
    BEGIN
        RETURN pk_pregnancy_core.get_dt_pregnancy_start(i_prof            => i_prof,
                                                        i_num_weeks       => i_num_weeks,
                                                        i_num_weeks_exam  => i_num_weeks_exam,
                                                        i_num_weeks_us    => i_num_weeks_us,
                                                        i_dt_intervention => i_dt_intervention,
                                                        i_flg_precision   => i_flg_precision);
    END get_dt_pregnancy_start;

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
    ) RETURN DATE IS
    
    BEGIN
        RETURN pk_pregnancy_core.get_dt_pregnancy_end(i_lang      => i_lang,
                                                      i_prof      => i_prof,
                                                      i_num_weeks => i_num_weeks,
                                                      i_num_days  => i_num_days,
                                                      i_dt_init   => i_dt_init);
    END get_dt_pregnancy_end;

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
    ) RETURN pat_pregn_fetus.id_pat_pregn_fetus%TYPE IS
    
    BEGIN
        RETURN pk_pregnancy_core.get_pregn_fetus_id(i_lang          => i_lang,
                                                    i_prof          => i_prof,
                                                    i_pat_pregnancy => i_pat_pregnancy,
                                                    i_fetus_number  => i_fetus_number);
    END get_pregn_fetus_id;

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
    ) RETURN NUMBER IS
    
    BEGIN
        RETURN pk_pregnancy_core.get_ultrasound_trimester(i_lang                => i_lang,
                                                          i_prof                => i_prof,
                                                          i_flg_weeks_criteria  => i_flg_weeks_criteria,
                                                          i_dt_init_preg_lmp    => i_dt_init_preg_lmp,
                                                          i_dt_exam_result_tstz => i_dt_exam_result_tstz,
                                                          i_weeks_pregnancy     => i_weeks_pregnancy);
    END get_ultrasound_trimester;

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
    ) RETURN VARCHAR2 IS
    
    BEGIN
    
        RETURN pk_pregnancy_core.get_serialized_code(i_lang          => i_lang,
                                                     i_prof          => i_prof,
                                                     i_pat_pregnancy => i_pat_pregnancy);
    END get_serialized_code;

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
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        RETURN pk_pregnancy_core.get_pat_sisprenatal(i_lang          => i_lang,
                                                     i_prof          => i_prof,
                                                     i_scope         => i_scope,
                                                     i_institution   => i_institution,
                                                     o_patient       => o_patient,
                                                     o_pat_pregnancy => o_pat_pregnancy,
                                                     o_error         => o_error);
    END get_pat_sisprenatal;

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
    ) RETURN pat_pregnancy.dt_last_menstruation%TYPE IS
    
    BEGIN
        RETURN pk_pregnancy_core.get_dt_lmp_pregn(i_lang          => i_lang,
                                                  i_prof          => i_prof,
                                                  i_pat_pregnancy => i_pat_pregnancy);
    END get_dt_lmp_pregn;

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
    ) RETURN DATE IS
    
    BEGIN
        RETURN pk_pregnancy_core.get_pregn_dt_epis(i_lang          => i_lang,
                                                   i_prof          => i_prof,
                                                   i_pat_pregnancy => i_pat_pregnancy,
                                                   i_flg_type_date => g_flg_dt_first_epis);
    END get_pregn_dt_first_epis;

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
    ) RETURN DATE IS
    
    BEGIN
        RETURN pk_pregnancy_core.get_pregn_dt_epis(i_lang          => i_lang,
                                                   i_prof          => i_prof,
                                                   i_pat_pregnancy => i_pat_pregnancy,
                                                   i_flg_type_date => g_flg_dt_last_epis);
    END get_pregn_dt_last_epis;

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
    ) RETURN VARCHAR2 IS
    
    BEGIN
        RETURN pk_pregnancy_core.get_pregn_episode_type(i_lang             => i_lang,
                                                        i_prof             => i_prof,
                                                        i_pregn_dt_interv  => i_pregn_dt_interv,
                                                        i_pregn_flg_status => i_pregn_flg_status,
                                                        i_epis_dt_begin    => i_epis_dt_begin,
                                                        i_epis_dt_end      => i_epis_dt_end);
    END get_pregn_episode_type;

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
    ) RETURN VARCHAR2 IS
        l_func_name CONSTANT VARCHAR2(30) := 'GET_PREGN_GEST_RISK';
        l_error     t_error_out;
        l_error_chr VARCHAR2(4000);
    
        l_area_gest_risk CONSTANT doc_area.id_doc_area%TYPE := 1057;
        l_def_risk       CONSTANT VARCHAR2(20 CHAR) := 'GEST_TOTAL_RISK';
        l_def_template   CONSTANT VARCHAR2(20 CHAR) := 'GEST_RISK_TEMPLATE';
        l_def_arisco     CONSTANT VARCHAR2(20 CHAR) := 'CN_ARISCO';
    
        l_total_risk   NUMBER;
        l_a_values     pk_map.typ_map_value;
        l_b_values     pk_map.typ_map_value;
        l_risk_value   NUMBER := -999;
        l_tab_doc_elem table_number;
        l_doc_elem_val doc_element.id_doc_element%TYPE;
        l_ret          VARCHAR2(10 CHAR) := '00';
        l_ret_map      BOOLEAN;
    
    BEGIN
        l_total_risk := pk_risk_factor.get_pat_total_score(i_lang     => i_lang,
                                                           i_prof     => i_prof,
                                                           i_patient  => i_patient,
                                                           i_doc_area => l_area_gest_risk);
    
        -- if the patient has a registered risk factor then this will be exported                                                
        IF l_total_risk IS NOT NULL
        THEN
            g_error   := 'GET MAP VALUES (1)';
            l_ret_map := pk_map.get_map_a_and_b_values(i_a_system       => pk_api_sisprenatal_out.g_system_alert,
                                                       i_a_definition   => l_def_risk,
                                                       i_b_system       => pk_api_sisprenatal_out.g_system_sisprenatal,
                                                       i_b_definition   => l_def_arisco,
                                                       i_id_institution => 0,
                                                       i_id_software    => 0,
                                                       o_a_value        => l_a_values,
                                                       o_b_value        => l_b_values,
                                                       o_error          => l_error_chr);
        
            g_error := 'FETCH SISPRENATAL VALUE';
            FOR i IN 1 .. l_a_values.count
            LOOP
                IF l_total_risk < to_number(l_a_values(i))
                   AND to_number(l_a_values(i)) > l_risk_value
                THEN
                    l_risk_value := to_number(l_a_values(i));
                    l_ret        := l_b_values(i);
                END IF;
            
            END LOOP;
        ELSE
            g_error   := 'GET MAP VALUES (2)';
            l_ret_map := pk_map.get_map_a_and_b_values(i_a_system       => pk_api_sisprenatal_out.g_system_alert,
                                                       i_a_definition   => l_def_template,
                                                       i_b_system       => pk_api_sisprenatal_out.g_system_sisprenatal,
                                                       i_b_definition   => l_def_arisco,
                                                       i_id_institution => 0,
                                                       i_id_software    => 0,
                                                       o_a_value        => l_a_values,
                                                       o_b_value        => l_b_values,
                                                       o_error          => l_error_chr);
        
            g_error        := 'INIT TABLE';
            l_tab_doc_elem := table_number();
            FOR i IN 1 .. l_a_values.count
            LOOP
                l_tab_doc_elem.extend;
                l_tab_doc_elem(i) := l_a_values(i);
            END LOOP;
        
            g_error := 'GET REGISTERED ELEMENTS';
            IF NOT pk_touch_option.get_pat_last_record(i_lang         => i_lang,
                                                       i_prof         => i_prof,
                                                       i_patient      => i_patient,
                                                       i_doc_elements => l_tab_doc_elem,
                                                       o_doc_element  => l_doc_elem_val,
                                                       o_error        => l_error)
            THEN
                RAISE g_exception;
            END IF;
        
            g_error := 'CHECK GEST RISK TEMPLATE';
            -- the patient has a registered template with the gestational risk
            IF l_doc_elem_val IS NOT NULL
            THEN
                FOR i IN 1 .. l_a_values.count
                LOOP
                    IF l_a_values(i) = l_doc_elem_val
                    THEN
                        l_ret := l_b_values(i);
                        EXIT;
                    END IF;
                END LOOP;
            END IF;
        
        END IF;
    
        RETURN l_ret;
    END get_pregn_gest_risk;

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
    ) RETURN VARCHAR2 IS
    
    BEGIN
    
        RETURN pk_pregnancy_core.get_pregn_location_code(i_lang             => i_lang,
                                                         i_prof             => i_prof,
                                                         i_pregn_flg_interv => i_pregn_flg_interv);
    END get_pregn_location_code;

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
    ) RETURN VARCHAR2 IS
        l_func_name CONSTANT VARCHAR2(30) := 'GET_PREGN_BIRTHTYPE_CODE';
        l_error_chr VARCHAR2(4000);
    
        l_def_birth_type CONSTANT VARCHAR2(20 CHAR) := 'CHILDBIRTH_TYPE';
        l_def_cn_tparto  CONSTANT VARCHAR2(20 CHAR) := 'CN_TPARTO';
        l_child_birthtype pat_pregn_fetus.flg_childbirth_type%TYPE;
        l_ret_birthtype   VARCHAR2(2 CHAR);
        l_ret_map         BOOLEAN;
    
    BEGIN
    
        g_error           := 'GET BIRTH TYPE';
        l_child_birthtype := pk_pregnancy_core.get_pregn_birth_type(i_lang          => i_lang,
                                                                    i_prof          => i_prof,
                                                                    i_pat_pregnancy => i_pat_pregnancy);
    
        IF l_child_birthtype IS NOT NULL
        THEN
            g_error   := 'GET BIRTH TYPE CODE';
            l_ret_map := pk_map.get_map_unique_a_b(i_a_system       => pk_api_sisprenatal_out.g_system_alert,
                                                   i_b_system       => pk_api_sisprenatal_out.g_system_sisprenatal,
                                                   i_a_value        => l_child_birthtype,
                                                   i_a_definition   => l_def_birth_type,
                                                   i_b_definition   => l_def_cn_tparto,
                                                   i_id_institution => 0,
                                                   i_id_software    => 0,
                                                   o_b_value        => l_ret_birthtype,
                                                   o_error          => l_error_chr);
        END IF;
    
        IF l_ret_birthtype IS NULL
        THEN
            l_ret_birthtype := '00';
        END IF;
    
        RETURN l_ret_birthtype;
    END get_pregn_birthtype_code;

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
    ) RETURN VARCHAR2 IS
        l_func_name CONSTANT VARCHAR2(30) := 'GET_PREGN_VACC_DOSES';
        l_error     t_error_out;
        l_error_chr VARCHAR2(4000);
    
        TYPE l_hash_adm IS TABLE OF NUMBER INDEX BY PLS_INTEGER;
        l_adm_values l_hash_adm;
    
        l_adm_title   VARCHAR2(4000);
        l_adm_det     pk_vacc.p_adm_det_cur;
        l_adm_det_lst pk_vacc.table_adm_det;
        l_adm_count   NUMBER;
    
        l_ret     VARCHAR2(1 CHAR);
        l_ret_map BOOLEAN;
    
    BEGIN
    
        g_error := 'GET MAP VALUES';
        -- mapping values are fetched only in the first call
        IF g_def_sisprenatal_alert IS NULL
           OR g_def_sisprenatal_alert <> i_def_vacc_alert
        THEN
            l_ret_map := pk_map.get_map_a_and_b_values(i_a_system       => pk_api_sisprenatal_out.g_system_alert,
                                                       i_a_definition   => i_def_vacc_alert,
                                                       i_b_system       => pk_api_sisprenatal_out.g_system_sisprenatal,
                                                       i_b_definition   => i_def_vacc_ext,
                                                       i_id_institution => 0,
                                                       i_id_software    => 0,
                                                       o_a_value        => g_a_values,
                                                       o_b_value        => g_b_values,
                                                       o_error          => l_error_chr);
        
            g_def_sisprenatal_alert := i_def_vacc_alert;
        
        END IF;
    
        IF g_a_values.count > 0
        THEN
            FOR i IN 1 .. g_a_values.count
            LOOP
                IF i_ret_type = pk_api_sisprenatal_out.g_vacc_id_code
                THEN
                    l_ret := g_b_values(i);
                ELSIF i_ret_type = pk_api_sisprenatal_out.g_vacc_dose_code
                THEN
                    g_error := 'GET VACC DOSES';
                    IF NOT pk_vacc.get_vacc_adm_det(i_lang      => i_lang,
                                                    i_patient   => i_patient,
                                                    i_prof      => i_prof,
                                                    i_test_id   => to_number(g_a_values(i)),
                                                    i_to_add    => FALSE,
                                                    o_adm_title => l_adm_title,
                                                    o_adm_det   => l_adm_det,
                                                    o_error     => l_error)
                    THEN
                        g_error := SQLERRM;
                        RAISE g_exception;
                    END IF;
                
                    g_error := 'FETCH VACC DOSES';
                    FETCH l_adm_det BULK COLLECT
                        INTO l_adm_det_lst;
                
                    FOR i IN 1 .. l_adm_det_lst.count
                    LOOP
                        l_adm_values(l_adm_det_lst(i).id_test) := 1;
                    END LOOP;
                
                    l_adm_count := l_adm_values.count;
                
                    g_error := 'GET DOSE CODE';
                    IF l_adm_count <= 3
                    THEN
                        l_ret := to_char(l_adm_count);
                    ELSE
                        l_ret := '4';
                    END IF;
                
                    -- loop ends because the patient already has doses for this vaccine
                    IF l_adm_count > 0
                    THEN
                        EXIT;
                    END IF;
                
                END IF;
            END LOOP;
        END IF;
    
        RETURN l_ret;
    END get_pregn_vacc_doses;

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
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30) := 'GET_PREGN_LAB_IDS';
        l_error_chr VARCHAR2(4000);
    
        l_a_values pk_map.typ_map_value;
        l_b_values pk_map.typ_map_value;
    
        l_id_contents table_varchar;
    BEGIN
    
        g_error := 'GET MAP VALUES';
        IF NOT pk_map.get_map_a_and_b_values(i_a_system       => pk_api_sisprenatal_out.g_system_alert,
                                             i_a_definition   => i_def_lab,
                                             i_b_system       => pk_api_sisprenatal_out.g_system_sisprenatal,
                                             i_b_definition   => i_def_lab,
                                             i_id_institution => 0,
                                             i_id_software    => 0,
                                             o_a_value        => l_a_values,
                                             o_b_value        => l_b_values,
                                             o_error          => l_error_chr)
        THEN
            RAISE g_exception;
        END IF;
    
        g_error       := 'RETURN VALUES';
        l_id_contents := table_varchar();
        FOR i IN 1 .. l_a_values.count
        LOOP
            l_id_contents.extend;
            l_id_contents(i) := l_a_values(i);
        END LOOP;
    
        o_id_contents      := l_id_contents;
        o_code_sisprenatal := l_b_values(1);
    
        RETURN TRUE;
    END get_pregn_lab_ids;

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
    ) RETURN VARCHAR2 IS
        l_func_name CONSTANT VARCHAR2(30) := 'GET_PREGN_LAB_CODE';
        l_error t_error_out;
    
        l_dt_min_lab_result TIMESTAMP WITH LOCAL TIME ZONE;
        l_format_date     CONSTANT VARCHAR2(50) := 'DD-MM-YYYY';
        l_format_date_tzr CONSTANT VARCHAR2(50) := 'DD-MM-YYYY TZR';
        l_timezone      VARCHAR2(200);
        l_count_results NUMBER;
    BEGIN
    
        l_timezone          := ' ' || pk_date_utils.get_timezone(i_lang, i_prof);
        l_dt_min_lab_result := to_timestamp_tz(to_char(trunc(i_dt_min_lab_result), l_format_date) || l_timezone,
                                               l_format_date_tzr);
    
        g_error         := 'RETURN VALUES';
        l_count_results := pk_lab_tests_external_api_db.get_count_lab_test_results(i_lang              => i_lang,
                                                                                   i_prof              => i_prof,
                                                                                   i_patient           => i_patient,
                                                                                   i_id_content        => i_id_contents,
                                                                                   i_dt_min_lab_result => l_dt_min_lab_result);
    
        IF l_count_results > 0
        THEN
            RETURN i_code_sisprenatal;
        ELSE
            RETURN '0';
        END IF;
    END get_pregn_lab_code;

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
    ) RETURN VARCHAR2 IS
    
    BEGIN
        RETURN pk_pregnancy_core.get_pregn_inter_type(i_lang             => i_lang,
                                                      i_prof             => i_prof,
                                                      i_pat_pregnancy    => i_pat_pregnancy,
                                                      i_pregn_flg_status => i_pregn_flg_status);
    END get_pregn_inter_type;

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
    ) RETURN VARCHAR2 IS
    
    BEGIN
    
        RETURN pk_pregnancy_core.get_pregn_early_puerperal(i_lang            => i_lang,
                                                           i_prof            => i_prof,
                                                           i_dt_init_pregn   => i_dt_init_pregn,
                                                           i_dt_intervention => i_dt_intervention);
    END get_pregn_early_puerperal;

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
    ) RETURN episode.id_episode%TYPE IS
    
    BEGIN
        RETURN pk_pregnancy_core.get_pregn_first_epis(i_lang          => i_lang,
                                                      i_prof          => i_prof,
                                                      i_patient       => i_patient,
                                                      i_dt_init_pregn => i_dt_init_pregn);
    END get_pregn_first_epis;

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
    ) RETURN BOOLEAN IS
    
        l_prof_category          VARCHAR2(1);
        l_flg_msg                VARCHAR2(1);
        l_show_warning           VARCHAR2(1);
        l_epis_documentation     epis_documentation.id_epis_documentation%TYPE;
        l_tbl_epis_documentation table_number := table_number();
        l_tbl_child_number       table_number := table_number();
    
        l_newborn_name VARCHAR2(4000) := NULL;
    
        l_child_number INTEGER := 0;
        l_child_index  table_number := table_number();
    
        l_id_doc_element_alive doc_element.id_doc_element%TYPE;
        l_id_doc_element_dead  doc_element.id_doc_element%TYPE;
        l_id_doc_crit_alive    doc_element_crit.id_doc_element_crit%TYPE;
        l_id_doc_crit_dead     doc_element_crit.id_doc_element_crit%TYPE;
    
        l_id_doc_element_male      doc_element.id_doc_element%TYPE;
        l_id_doc_element_female    doc_element.id_doc_element%TYPE;
        l_id_doc_element_undefined doc_element.id_doc_element%TYPE;
        l_id_doc_crit_male         doc_element_crit.id_doc_element_crit%TYPE;
        l_id_doc_crit_female       doc_element_crit.id_doc_element_crit%TYPE;
        l_id_doc_crit_undefined    doc_element_crit.id_doc_element_crit%TYPE;
    
        l_id_doc_newborn_weight documentation.id_documentation%TYPE;
        l_id_doc_element_kg     doc_element.id_doc_element%TYPE;
    
        l_id_doc_dt_birth         documentation.id_documentation%TYPE;
        l_id_doc_element_dt_birth doc_element.id_doc_element%TYPE;
        l_id_doc_crit_dt_birth    doc_element_crit.id_doc_element_crit%TYPE;
    
        l_id_doc_newborn_state  documentation.id_documentation%TYPE;
        l_id_doc_newborn_gender documentation.id_documentation%TYPE;
    
        l_id_doc_element_birth_type doc_element.id_doc_element%TYPE;
        l_id_doc_birth_type         documentation.id_documentation%TYPE;
        l_id_doc_crit_birth_type    doc_element_crit.id_doc_element_crit%TYPE;
    
        l_id_doc_newborn_name         documentation.id_documentation%TYPE;
        l_id_doc_element_newborn_name doc_element.id_doc_element%TYPE;
        l_id_doc_crit_newborn_name    doc_element_crit.id_doc_element_crit%TYPE;
    
        l_id_patient  patient.id_patient%TYPE;
        l_preg_status pat_pregnancy.flg_status%TYPE;
    
        l_id_documentation      table_number := table_number();
        l_id_doc_element        table_number := table_number();
        l_id_doc_element_crit   table_number := table_number();
        l_value                 table_varchar := table_varchar();
        l_id_doc_element_qualif table_table_number := table_table_number();
        l_flg_type              VARCHAR2(1 CHAR);
        l_title                 sys_message.desc_message%TYPE;
        l_msg                   sys_message.desc_message%TYPE;
    BEGIN
    
        l_prof_category := pk_prof_utils.get_category(i_lang, i_prof);
    
        SELECT e.id_patient
          INTO l_id_patient
          FROM episode e
         WHERE e.id_episode = i_epis;
    
        SELECT COUNT(*)
          INTO l_child_number
          FROM epis_documentation ed
          JOIN epis_doc_delivery edd
            ON edd.id_epis_documentation = ed.id_epis_documentation
         WHERE ed.id_doc_area = g_doc_area_partogram
           AND ed.flg_status = pk_alert_constant.g_active
           AND ed.id_episode = i_epis
           AND edd.id_pat_pregnancy = i_pat_pregnancy;
    
        SELECT /*+ opt_estimate(table t rows=24)*/
         de.id_doc_element, pk_utils.str_token(de.value, 1, '|') VALUE, d.id_documentation
          INTO l_id_doc_element_alive, l_id_doc_crit_alive, l_id_doc_newborn_state
          FROM documentation_ext de
         INNER JOIN TABLE(table_varchar('CHILD_STATUS_ALIVE')) t
            ON de.internal_name = t.column_value
         INNER JOIN doc_element del
            ON de.id_doc_element = del.id_doc_element
         INNER JOIN documentation d
            ON del.id_documentation = d.id_documentation
         INNER JOIN doc_template_area_doc dtad
            ON d.id_documentation = dtad.id_documentation
         WHERE dtad.id_doc_area = g_doc_area_partogram
           AND dtad.id_doc_template = g_doc_template_partogram
           AND (pk_utils.str_token(de.value, 2, '|') IS NULL OR pk_utils.str_token(de.value, 2, '|') <= 1);
    
        SELECT /*+ opt_estimate(table t rows=24)*/
         de.id_doc_element, pk_utils.str_token(de.value, 1, '|') VALUE
          INTO l_id_doc_element_dead, l_id_doc_crit_dead
          FROM documentation_ext de
         INNER JOIN TABLE(table_varchar('CHILD_STATUS_DEAD')) t
            ON de.internal_name = t.column_value
         INNER JOIN doc_element del
            ON de.id_doc_element = del.id_doc_element
         INNER JOIN documentation d
            ON del.id_documentation = d.id_documentation
         INNER JOIN doc_template_area_doc dtad
            ON d.id_documentation = dtad.id_documentation
         WHERE dtad.id_doc_area = g_doc_area_partogram
           AND dtad.id_doc_template = g_doc_template_partogram
           AND (pk_utils.str_token(de.value, 2, '|') IS NULL OR pk_utils.str_token(de.value, 2, '|') <= 1);
    
        SELECT /*+ opt_estimate(table t rows=24)*/
         de.id_doc_element, pk_utils.str_token(de.value, 1, '|') VALUE, d.id_documentation
          INTO l_id_doc_element_male, l_id_doc_crit_male, l_id_doc_newborn_gender
          FROM documentation_ext de
         INNER JOIN TABLE(table_varchar('GENDER_MALE')) t
            ON de.internal_name = t.column_value
         INNER JOIN doc_element del
            ON de.id_doc_element = del.id_doc_element
         INNER JOIN documentation d
            ON del.id_documentation = d.id_documentation
         INNER JOIN doc_template_area_doc dtad
            ON d.id_documentation = dtad.id_documentation
         WHERE dtad.id_doc_area = g_doc_area_partogram
           AND dtad.id_doc_template = g_doc_template_partogram
           AND (pk_utils.str_token(de.value, 2, '|') IS NULL OR pk_utils.str_token(de.value, 2, '|') <= 1);
    
        SELECT /*+ opt_estimate(table t rows=24)*/
         de.id_doc_element, pk_utils.str_token(de.value, 1, '|') VALUE
          INTO l_id_doc_element_female, l_id_doc_crit_female
          FROM documentation_ext de
         INNER JOIN TABLE(table_varchar('GENDER_FEMALE')) t
            ON de.internal_name = t.column_value
         INNER JOIN doc_element del
            ON de.id_doc_element = del.id_doc_element
         INNER JOIN documentation d
            ON del.id_documentation = d.id_documentation
         INNER JOIN doc_template_area_doc dtad
            ON d.id_documentation = dtad.id_documentation
         WHERE dtad.id_doc_area = g_doc_area_partogram
           AND dtad.id_doc_template = g_doc_template_partogram
           AND (pk_utils.str_token(de.value, 2, '|') IS NULL OR pk_utils.str_token(de.value, 2, '|') <= 1);
    
        SELECT /*+ opt_estimate(table t rows=24)*/
         de.id_doc_element, pk_utils.str_token(de.value, 1, '|') VALUE
          INTO l_id_doc_element_undefined, l_id_doc_crit_undefined
          FROM documentation_ext de
         INNER JOIN TABLE(table_varchar('GENDER_I')) t
            ON de.internal_name = t.column_value
         INNER JOIN doc_element del
            ON de.id_doc_element = del.id_doc_element
         INNER JOIN documentation d
            ON del.id_documentation = d.id_documentation
         INNER JOIN doc_template_area_doc dtad
            ON d.id_documentation = dtad.id_documentation
         WHERE dtad.id_doc_area = g_doc_area_partogram
           AND dtad.id_doc_template = g_doc_template_partogram
           AND (pk_utils.str_token(de.value, 2, '|') IS NULL OR pk_utils.str_token(de.value, 2, '|') <= 1);
    
        SELECT /*+ opt_estimate(table t rows=24)*/
         de.id_doc_element, d.id_documentation
          INTO l_id_doc_element_kg, l_id_doc_newborn_weight
          FROM documentation_ext de
         INNER JOIN TABLE(table_varchar('FETUS_WEIGHT')) t
            ON de.internal_name = t.column_value
         INNER JOIN doc_element del
            ON de.id_doc_element = del.id_doc_element
         INNER JOIN documentation d
            ON del.id_documentation = d.id_documentation
         INNER JOIN doc_template_area_doc dtad
            ON d.id_documentation = dtad.id_documentation
         WHERE dtad.id_doc_area = g_doc_area_partogram
           AND dtad.id_doc_template = g_doc_template_partogram
           AND (pk_utils.str_token(de.value, 2, '|') IS NULL OR pk_utils.str_token(de.value, 2, '|') <= 1);
    
        SELECT /*+ opt_estimate(table t rows=24)*/
         de.id_doc_element, d.id_documentation, de.value
          INTO l_id_doc_element_dt_birth, l_id_doc_dt_birth, l_id_doc_crit_dt_birth
          FROM documentation_ext de
         INNER JOIN doc_element del
            ON de.id_doc_element = del.id_doc_element
         INNER JOIN documentation d
            ON del.id_documentation = d.id_documentation
         INNER JOIN doc_template_area_doc dtad
            ON d.id_documentation = dtad.id_documentation
         WHERE dtad.id_doc_area = g_doc_area_partogram
           AND dtad.id_doc_template = g_doc_template_partogram
           AND de.internal_name LIKE 'DATE_CHILD_BIRTH'
           AND (pk_utils.str_token(de.value, 2, '|') IS NULL OR pk_utils.str_token(de.value, 2, '|') <= 1);
    
        SELECT /*+ opt_estimate(table t rows=24)*/
         de.id_doc_element, d.id_documentation, de.value
          INTO l_id_doc_element_newborn_name, l_id_doc_newborn_name, l_id_doc_crit_newborn_name
          FROM documentation_ext de
         INNER JOIN doc_element del
            ON de.id_doc_element = del.id_doc_element
         INNER JOIN documentation d
            ON del.id_documentation = d.id_documentation
         INNER JOIN doc_template_area_doc dtad
            ON d.id_documentation = dtad.id_documentation
         WHERE dtad.id_doc_area = g_doc_area_partogram
           AND dtad.id_doc_template = g_doc_template_partogram
           AND de.internal_name LIKE 'Nome do recém-nascido'
           AND (pk_utils.str_token(de.value, 2, '|') IS NULL OR pk_utils.str_token(de.value, 2, '|') <= 1);
    
        BEGIN
            SELECT /*+ opt_estimate(table t rows=24)*/
             de.id_doc_element, d.id_documentation, de.value
              INTO l_id_doc_element_birth_type, l_id_doc_birth_type, l_id_doc_crit_birth_type
              FROM documentation_ext de
             INNER JOIN doc_element del
                ON de.id_doc_element = del.id_doc_element
             INNER JOIN documentation d
                ON del.id_documentation = d.id_documentation
             INNER JOIN doc_template_area_doc dtad
                ON d.id_documentation = dtad.id_documentation
             WHERE dtad.id_doc_area = g_doc_area_partogram
               AND dtad.id_doc_template = g_doc_template_partogram
               AND de.internal_name LIKE 'NB_DELIVERY_TYPE%'
               AND (pk_utils.str_token(de.value, 2, '|') IS NULL OR pk_utils.str_token(de.value, 2, '|') <= 1)
               AND de.flg_value = i_delivery_type;
        EXCEPTION
            WHEN no_data_found THEN
                l_id_doc_element_birth_type := NULL;
                l_id_doc_birth_type         := NULL;
                l_id_doc_crit_birth_type    := NULL;
        END;
    
        IF i_flg_action = 'E'
        THEN
        
            FOR i IN i_epis_documentation.first .. i_epis_documentation.last
            LOOP
                l_child_index.extend;
            
                /*                SELECT rn
                 INTO l_child_index(i)
                 FROM (SELECT ed.id_epis_documentation, ed.id_episode, ed.flg_status, rownum AS rn
                         FROM epis_documentation ed
                        WHERE ed.id_doc_area = g_doc_area_partogram
                          AND id_episode = i_epis
                          AND ed.flg_status = pk_alert_constant.g_active
                        ORDER BY 1 DESC)
                WHERE id_epis_documentation = i_epis_documentation(i);*/
            
                SELECT edd.child_number
                  INTO l_child_index(i)
                  FROM epis_documentation ed
                  JOIN epis_doc_delivery edd
                    ON edd.id_epis_documentation = ed.id_epis_documentation
                 WHERE ed.id_doc_area = g_doc_area_partogram
                   AND id_episode = i_epis
                   AND ed.flg_status = pk_alert_constant.g_active
                   AND ed.id_epis_documentation = i_epis_documentation(i);
            
            END LOOP;
        
        END IF;
    
        FOR i IN i_epis_documentation.first .. i_epis_documentation.last
        LOOP
        
            l_newborn_name := i_newborn_name(i);
        
            IF i_newborn_name(i) IS NOT NULL
            THEN
            
                l_id_documentation.extend;
                l_id_documentation(l_id_documentation.count) := l_id_doc_newborn_name;
            
                l_id_doc_element.extend();
                l_id_doc_element(l_id_doc_element.count) := l_id_doc_element_newborn_name;
            
                l_id_doc_element_crit.extend();
                l_id_doc_element_crit(l_id_doc_element_crit.count) := l_id_doc_crit_newborn_name;
            
                l_value.extend();
                l_value(l_value.count) := l_newborn_name;
            
                l_id_doc_element_qualif.extend();
                l_id_doc_element_qualif(l_id_doc_element_qualif.count) := table_number(NULL);
            END IF;
        
            IF i_dt_birth(i) IS NOT NULL
            THEN
                l_id_documentation.extend;
                l_id_documentation(l_id_documentation.count) := l_id_doc_dt_birth;
            
                l_id_doc_element.extend();
                l_id_doc_element(l_id_doc_element.count) := l_id_doc_element_dt_birth;
            
                l_id_doc_element_crit.extend();
                l_id_doc_element_crit(l_id_doc_element_crit.count) := l_id_doc_crit_dt_birth;
            
                l_value.extend();
                l_value(l_value.count) := i_dt_birth(i) || '|YYYYMMDDHH24MISS';
            
                l_id_doc_element_qualif.extend();
                l_id_doc_element_qualif(l_id_doc_element_qualif.count) := table_number(NULL);
            END IF;
        
            IF i_newborn_state(i) IS NOT NULL
            THEN
                l_id_documentation.extend;
                l_id_documentation(l_id_documentation.count) := l_id_doc_newborn_state;
            
                l_id_doc_element.extend();
                l_id_doc_element(l_id_doc_element.count) := CASE
                                                                WHEN i_newborn_state(i) = pk_delivery.g_child_status_alive THEN
                                                                 l_id_doc_element_alive
                                                                WHEN i_newborn_state(i) = pk_delivery.g_child_status_dead THEN
                                                                 l_id_doc_element_dead
                                                            END;
            
                l_id_doc_element_crit.extend();
                l_id_doc_element_crit(l_id_doc_element_crit.count) := CASE
                                                                          WHEN i_newborn_state(i) = pk_delivery.g_child_status_alive THEN
                                                                           l_id_doc_crit_alive
                                                                          WHEN i_newborn_state(i) = pk_delivery.g_child_status_dead THEN
                                                                           l_id_doc_crit_dead
                                                                      END;
            
                l_value.extend();
                l_value(l_value.count) := NULL;
            
                l_id_doc_element_qualif.extend();
                l_id_doc_element_qualif(l_id_doc_element_qualif.count) := table_number(NULL);
            END IF;
        
            IF i_newborn_gender(i) IS NOT NULL
            THEN
                l_id_documentation.extend;
                l_id_documentation(l_id_documentation.count) := l_id_doc_newborn_gender;
            
                l_id_doc_element.extend();
                l_id_doc_element(l_id_doc_element.count) := CASE
                                                                WHEN i_newborn_gender(i) = pk_patient.g_pat_gender_male THEN
                                                                 l_id_doc_element_male
                                                                WHEN i_newborn_gender(i) = pk_patient.g_pat_gender_female THEN
                                                                 l_id_doc_element_female
                                                                ELSE
                                                                 l_id_doc_element_undefined
                                                            END;
            
                l_id_doc_element_crit.extend();
                l_id_doc_element_crit(l_id_doc_element_crit.count) := CASE
                                                                          WHEN i_newborn_gender(i) = pk_patient.g_pat_gender_male THEN
                                                                           l_id_doc_crit_male
                                                                          WHEN i_newborn_gender(i) = pk_patient.g_pat_gender_female THEN
                                                                           l_id_doc_crit_female
                                                                          ELSE
                                                                           l_id_doc_crit_undefined
                                                                      END;
            
                l_value.extend();
                l_value(l_value.count) := NULL;
            
                l_id_doc_element_qualif.extend();
                l_id_doc_element_qualif(l_id_doc_element_qualif.count) := table_number(NULL);
            END IF;
        
            IF i_newborn_weight(i) IS NOT NULL
            THEN
                l_id_documentation.extend;
                l_id_documentation(l_id_documentation.count) := l_id_doc_newborn_weight;
            
                l_id_doc_element.extend();
                l_id_doc_element(l_id_doc_element.count) := CASE
                                                                WHEN i_newborn_weight(i) IS NOT NULL THEN
                                                                 l_id_doc_element_kg
                                                                ELSE
                                                                 NULL
                                                            END;
            
                l_id_doc_element_crit.extend();
                l_id_doc_element_crit(l_id_doc_element_crit.count) := CASE
                                                                          WHEN i_newborn_weight(i) IS NOT NULL THEN
                                                                           g_id_doc_crit_kg
                                                                          ELSE
                                                                           NULL
                                                                      END;
            
                l_value.extend();
                l_value(l_value.count) := CASE
                                              WHEN i_newborn_weight(i) IS NOT NULL THEN
                                               i_newborn_weight(i) || '|' || CASE
                                                   WHEN i_newborn_weight_um(i) IS NOT NULL THEN
                                                    i_newborn_weight_um(i)
                                                   ELSE
                                                    g_unit_measure_g
                                               END
                                              ELSE
                                               NULL
                                          END;
            
                l_id_doc_element_qualif.extend();
                l_id_doc_element_qualif(l_id_doc_element_qualif.count) := table_number(NULL);
            END IF;
        
            IF i_delivery_type IS NOT NULL
            THEN
                l_id_documentation.extend;
                l_id_documentation(l_id_documentation.count) := l_id_doc_birth_type;
            
                l_id_doc_element.extend();
                l_id_doc_element(l_id_doc_element.count) := l_id_doc_element_birth_type;
            
                l_id_doc_element_crit.extend();
                l_id_doc_element_crit(l_id_doc_element_crit.count) := l_id_doc_crit_birth_type;
            
                l_value.extend();
                l_value(l_value.count) := NULL;
            
                l_id_doc_element_qualif.extend();
                l_id_doc_element_qualif(l_id_doc_element_qualif.count) := table_number(NULL);
            END IF;
        
            IF NOT pk_delivery.set_epis_doc_delivery_internal(i_lang                  => i_lang,
                                                         i_prof                  => i_prof,
                                                         i_prof_cat_type         => l_prof_category,
                                                         i_epis                  => i_epis,
                                                         i_doc_area              => g_doc_area_partogram,
                                                         i_doc_template          => g_doc_template_partogram,
                                                         i_epis_documentation    => i_epis_documentation(i),
                                                         i_flg_type              => i_flg_action,
                                                         i_id_documentation      => l_id_documentation,
                                                         i_id_doc_element        => l_id_doc_element,
                                                         i_id_doc_element_crit   => l_id_doc_element_crit,
                                                         i_value                 => l_value,
                                                         i_notes                 => i_notes(i),
                                                         i_id_doc_element_qualif => l_id_doc_element_qualif,
                                                         i_epis_context          => NULL,
                                                         i_pat_pregnancy         => i_pat_pregnancy,
                                                         i_doc_element_ext       => table_number(NULL),
                                                         i_values_ext            => table_number(NULL),
                                                         i_child_number          => CASE
                                                                                        WHEN i_flg_action = 'N' THEN
                                                                                         i + l_child_number
                                                                                        ELSE
                                                                                         l_child_index(i)
                                                                                    END,
                                                         i_validate              => 'N',
                                                         o_flg_msg               => l_flg_msg,
                                                         o_show_warning          => l_show_warning,
                                                         o_flg_type              => l_flg_type,
                                                         o_title                 => l_title,
                                                         o_msg                   => l_msg,
                                                         o_epis_documentation    => l_epis_documentation,
                                                         o_error                 => o_error)
            THEN
                RETURN FALSE;
            END IF;
        
            l_tbl_child_number.extend();
            l_tbl_child_number(i) := CASE
                                         WHEN i_flg_action = 'N' THEN
                                          i + l_child_number
                                         ELSE
                                          l_child_index(i)
                                     END;
        
            l_tbl_epis_documentation.extend;
            l_tbl_epis_documentation(i) := l_epis_documentation;
        
            l_id_documentation      := table_number();
            l_id_doc_element        := table_number();
            l_id_doc_element_crit   := table_number();
            l_value                 := table_varchar();
            l_id_doc_element_qualif := table_table_number();
        
        END LOOP;
    
        SELECT pp.flg_status
          INTO l_preg_status
          FROM pat_pregnancy pp
         WHERE pp.id_pat_pregnancy = i_pat_pregnancy;
    
        IF l_preg_status = pk_pregnancy_core.g_pat_pregn_active
        THEN
        
            ts_pat_pregnancy.upd(id_pat_pregnancy_in        => i_pat_pregnancy,
                                 id_patient_in              => l_id_patient,
                                 flg_status_in              => pk_pregnancy_core.g_pat_pregn_past,
                                 dt_intervention_in         => pk_date_utils.get_string_tstz(i_lang,
                                                                                             i_prof,
                                                                                             i_dt_birth(1),
                                                                                             pk_date_utils.get_timezone(i_lang,
                                                                                                                        i_prof)),
                                 flg_dt_interv_precision_in => pk_pregnancy_core.g_dt_flg_precision_h);
        END IF;
    
        o_epis_documentation := l_tbl_epis_documentation;
        o_child_number       := l_tbl_child_number;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN FALSE;
        
    END set_newborn_record;

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
    ) RETURN BOOLEAN IS
    
        rows_out table_varchar;
        l_count  INTEGER := 0;
    
        l_id_epis_child epis_doc_delivery.id_child_episode%TYPE;
    
    BEGIN
    
        FOR i IN i_epis_documentation.first .. i_epis_documentation.last
        LOOP
        
            SELECT ed.id_child_episode
              INTO l_id_epis_child
              FROM epis_doc_delivery ed
             WHERE ed.id_epis_documentation = i_epis_documentation(i);
        
            IF l_id_epis_child IS NULL
            THEN
            
                --INACTIVATE EPIS_DOCUMENTATION
                ts_epis_documentation.upd(id_epis_documentation_in => i_epis_documentation(i),
                                          flg_status_in            => pk_alert_constant.g_cancelled,
                                          id_prof_cancel_in        => i_prof.id,
                                          notes_cancel_in          => i_cancel_notes(i),
                                          dt_cancel_tstz_in        => pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                                                                                    i_prof      => i_prof,
                                                                                                    i_timestamp => pk_date_utils.get_timestamp_str(i_lang      => i_lang,
                                                                                                                                                   i_prof      => i_prof,
                                                                                                                                                   i_timestamp => current_date,
                                                                                                                                                   i_timezone  => NULL),
                                                                                                    i_timezone  => NULL),
                                          id_cancel_reason_in      => i_id_cancel_reason(i),
                                          rows_out                 => rows_out);
                --CHECK NUMBER OF ACTIVE RECORDS
                SELECT COUNT(*)
                  INTO l_count
                  FROM epis_documentation d
                 WHERE d.id_episode = (SELECT DISTINCT id_episode
                                         FROM epis_documentation
                                        WHERE id_epis_documentation = i_epis_documentation(i))
                   AND d.id_doc_area = g_doc_area_partogram
                   AND d.flg_status = pk_alert_constant.g_active;
            
                -- NO ACTIVE RECORDS => UPDATE  pat_pregnancy AND pat_pregn_fetus
                IF l_count = 0
                THEN
                
                    ts_pat_pregnancy.upd(id_pat_pregnancy_in         => i_pat_pregnancy,
                                         flg_status_in               => pk_alert_constant.g_active,
                                         dt_intervention_in          => NULL,
                                         dt_intervention_nin         => FALSE,
                                         flg_dt_interv_precision_in  => NULL,
                                         flg_dt_interv_precision_nin => FALSE);
                
                    UPDATE pat_pregn_fetus f
                       SET f.flg_gender = NULL, f.flg_status = NULL, f.weight = NULL, f.id_unit_measure = NULL
                     WHERE f.id_pat_pregnancy = i_pat_pregnancy;
                END IF;
            
            END IF;
        
        END LOOP;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'pk_pregnancy_api',
                                              'cancel_newborn_record',
                                              o_error);
            RETURN FALSE;
    END cancel_newborn_record;

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
    ) RETURN BOOLEAN IS
    
        l_id_patient patient.id_patient%TYPE;
    
        l_flg_childbirth_type table_varchar := table_varchar();
        l_flg_child_status    table_varchar := table_varchar();
        l_flg_child_gender    table_varchar := table_varchar();
        l_flg_child_weight    table_number := table_number();
        l_um_weight           table_number := table_number();
        l_present_health      table_varchar := table_varchar();
        l_flg_present_health  table_varchar := table_varchar();
    
        l_id_pat_pregnancy pat_pregnancy.id_pat_pregnancy%TYPE;
    
        l_dt_expected_birth     VARCHAR2(50) := NULL;
        l_dt_init_chr_out       VARCHAR2(50) := NULL;
        l_dt_expected_birth_cht VARCHAR2(50) := NULL;
    BEGIN
    
        SELECT e.id_patient
          INTO l_id_patient
          FROM episode e
         WHERE e.id_episode = i_episode;
    
        FOR i IN 1 .. i_n_children
        LOOP
            l_flg_childbirth_type.extend();
            l_flg_child_status.extend();
            l_flg_child_gender.extend();
            l_flg_child_weight.extend();
            l_um_weight.extend();
            l_present_health.extend();
            l_flg_present_health.extend();
        
            l_flg_childbirth_type(i) := NULL;
            l_flg_child_status(i) := NULL;
            l_flg_child_gender(i) := NULL;
            l_flg_child_weight(i) := NULL;
            l_um_weight(i) := NULL;
            l_present_health(i) := NULL;
            l_flg_present_health(i) := NULL;
        
        END LOOP;
    
        IF i_dt_expected_birth IS NULL
           AND (i_num_weeks IS NOT NULL AND i_num_days IS NOT NULL)
        THEN
            IF NOT pk_pregnancy.get_dt_pregnancy_end(i_lang        => i_lang,
                                                     i_prof        => i_prof,
                                                     i_num_weeks   => i_num_weeks,
                                                     i_num_days    => i_num_days,
                                                     i_dt_init     => NULL,
                                                     o_dt_end      => l_dt_expected_birth,
                                                     o_dt_init_chr => l_dt_init_chr_out,
                                                     o_dt_end_chr  => l_dt_expected_birth_cht,
                                                     o_error       => o_error)
            THEN
                RETURN FALSE;
            END IF;
        END IF;
    
        IF NOT pk_pregnancy.set_pat_pregnancy(i_lang                 => i_lang,
                                         i_patient              => l_id_patient,
                                         i_pat_pregnancy        => i_pat_pregnancy,
                                         i_dt_last_menstruation => i_dt_last_menstruation,
                                         i_dt_intervention      => NULL,
                                         i_flg_type             => CASE
                                                                       WHEN i_pat_pregnancy IS NULL THEN
                                                                        'C'
                                                                       ELSE
                                                                        'U'
                                                                   END,
                                         i_num_weeks            => i_num_weeks,
                                         i_num_days             => i_num_days,
                                         i_n_children           => i_n_children,
                                         i_flg_childbirth_type  => l_flg_childbirth_type,
                                         i_flg_child_status     => l_flg_child_status,
                                         i_flg_child_gender     => l_flg_child_gender,
                                         i_flg_child_weight     => l_flg_child_weight,
                                         i_um_weight            => l_um_weight,
                                         i_present_health       => l_present_health,
                                         i_flg_present_health   => l_flg_present_health,
                                         i_flg_complication     => NULL,
                                         i_notes_complication   => NULL,
                                         i_flg_desc_interv      => NULL,
                                         i_desc_intervention    => NULL,
                                         i_id_inst_interv       => NULL,
                                         i_notes                => NULL,
                                         i_flg_abortion_type    => NULL,
                                         i_prof                 => i_prof,
                                         i_id_episode           => i_episode,
                                         i_flg_menses           => NULL,
                                         i_cycle_duration       => NULL,
                                         i_flg_use_constracep   => NULL,
                                         i_dt_contrac_meth_end  => NULL,
                                         i_flg_contra_precision => NULL,
                                         i_dt_pdel_lmp          => CASE
                                                                       WHEN i_dt_expected_birth IS NULL THEN
                                                                        l_dt_expected_birth
                                                                       ELSE
                                                                        i_dt_expected_birth
                                                                   END,
                                         i_num_weeks_exam       => NULL,
                                         i_num_days_exam        => NULL,
                                         i_num_weeks_us         => NULL,
                                         i_num_days_us          => NULL,
                                         i_dt_pdel_correct      => NULL,
                                         i_dt_us_performed      => NULL,
                                         i_flg_del_onset        => NULL,
                                         i_del_duration         => NULL,
                                         i_flg_interv_precision => NULL,
                                         i_id_alert_diagnosis   => NULL,
                                         i_code_state           => NULL,
                                         i_code_year            => NULL,
                                         i_code_number          => NULL,
                                         i_flg_contrac_type     => NULL,
                                         i_notes_contrac        => NULL,
                                         i_cdr_call             => NULL,
                                         i_flg_extraction       => NULL,
                                         i_flg_preg_out_type    => NULL,
                                         i_num_births           => NULL,
                                         i_num_abortions        => NULL,
                                         i_num_gestations       => NULL,
                                         i_flg_gest_weeks       => NULL,
                                         i_flg_gest_weeks_exam  => NULL,
                                         i_flg_gest_weeks_us    => NULL,
                                         o_error                => o_error)
        THEN
            RETURN FALSE;
        ELSE
        
            SELECT *
              INTO l_id_pat_pregnancy
              FROM (SELECT p.id_pat_pregnancy
                    
                      FROM pat_pregnancy p
                     WHERE p.id_episode = i_episode
                     ORDER BY 1 DESC)
            
             WHERE rownum = 1;
        
            o_id_pat_pregnancy := l_id_pat_pregnancy;
        
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              'pk_pregnancy_api.set_pregnancy_record',
                                              'ALERT',
                                              'pk_pregnancy_api',
                                              'set_pregnancy_record',
                                              o_error);
            RETURN FALSE;
        
    END set_pregnancy_record;

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
    ) RETURN BOOLEAN IS
    
        l_msg       VARCHAR2(1000);
        l_msg_title VARCHAR2(1000);
        l_flg_show  VARCHAR2(1000);
        l_button    VARCHAR2(1000);
    
        l_patient patient.id_patient%TYPE := NULL;
    
    BEGIN
    
        SELECT pp.id_patient
          INTO l_patient
          FROM pat_pregnancy pp
         WHERE pp.id_pat_pregnancy = i_pat_pregnancy;
    
        IF NOT pk_woman_health.cancel_pat_pregnancy(i_lang          => i_lang,
                                                    i_patient       => nvl(i_patient, l_patient),
                                                    i_pat_pregnancy => i_pat_pregnancy,
                                                    i_prof          => i_prof,
                                                    i_flg_confirm   => 'Y',
                                                    o_msg           => l_msg,
                                                    o_msg_title     => l_msg_title,
                                                    o_flg_show      => l_flg_show,
                                                    o_button        => l_button,
                                                    o_error         => o_error)
        THEN
            RETURN FALSE;
        ELSE
            RETURN TRUE;
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              'pk_pregnancy_api.set_pregnancy_record',
                                              'ALERT',
                                              'pk_pregnancy_api',
                                              'set_pregnancy_record',
                                              o_error);
            RETURN FALSE;
        
    END cancel_pregnancy_record;

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
    ) RETURN BOOLEAN IS
    
        l_prof_category VARCHAR2(1);
        l_num_children  INTEGER := 0;
    
        l_tbl_documentation    table_number := table_number();
        l_tbl_doc_element      table_number := table_number();
        l_tbl_doc_element_crit table_number := table_number();
        l_tbl_value            table_varchar := table_varchar();
        l_epis_documentation   epis_documentation.id_epis_documentation%TYPE;
        l_flg_msg              VARCHAR2(1);
        l_show_warning         VARCHAR2(1);
        l_flg_type             VARCHAR2(1);
        l_id_department        NUMBER;
        l_id_clinical_service  NUMBER;
        l_id_doc_fetus_number  NUMBER;
        l_title                sys_message.desc_message%TYPE;
        l_msg                  sys_message.desc_message%TYPE;
    BEGIN
    
        l_prof_category := pk_prof_utils.get_category(i_lang, i_prof);
    
        SELECT p.n_children
          INTO l_num_children
          FROM pat_pregnancy p
         WHERE p.id_pat_pregnancy = i_pat_pregnancy;
    
        SELECT de.id_doc_element
          INTO l_id_doc_fetus_number
          FROM documentation_ext de
         WHERE de.internal_name = 'FETUS_NUMBER'
           AND rownum = 1;
    
        FOR i IN 1 .. l_num_children
        LOOP
            l_tbl_documentation.extend;
            l_tbl_doc_element.extend();
            l_tbl_doc_element_crit.extend();
            l_tbl_value.extend();
        
            SELECT t.id_documentation, t.id_doc_element, t.value
              INTO l_tbl_documentation(i), l_tbl_doc_element(i), l_tbl_doc_element_crit(i)
              FROM (SELECT /*+ opt_estimate(table t rows=24)*/
                     de.id_documentation_ext,
                     de.id_doc_element,
                     pk_utils.str_token(de.value, 1, '|') VALUE,
                     de.internal_name,
                     de.flg_value,
                     pk_utils.str_token(de.value, 2, '|') fetus_number,
                     d.id_documentation
                      FROM documentation_ext de
                     INNER JOIN doc_element del
                        ON de.id_doc_element = del.id_doc_element
                     INNER JOIN documentation d
                        ON del.id_documentation = d.id_documentation
                     INNER JOIN doc_template_area_doc dtad
                        ON d.id_documentation = dtad.id_documentation
                     WHERE dtad.id_doc_area = g_doc_area_delivery_assessment
                       AND dtad.id_doc_template = g_doc_template_partogram
                       AND de.internal_name LIKE 'BIRTH_TYPE%') t
             WHERE t.flg_value = i_type_delivery(i)
               AND t.fetus_number = i;
        
        END LOOP;
    
        IF NOT pk_delivery.set_epis_doc_delivery(i_lang                  => i_lang,
                                            i_prof                  => i_prof,
                                            i_prof_cat_type         => l_prof_category,
                                            i_epis                  => i_episode,
                                            i_doc_area              => g_doc_area_delivery_assessment,
                                            i_doc_template          => g_doc_template_partogram,
                                            i_epis_documentation    => i_epis_documentation,
                                            i_flg_type              => CASE
                                                                           WHEN i_epis_documentation IS NULL THEN
                                                                            'N'
                                                                           ELSE
                                                                            'E'
                                                                       END,
                                            i_id_documentation      => l_tbl_documentation, ----
                                            i_id_doc_element        => l_tbl_doc_element, --table_number(312803 /*117904*/),
                                            i_id_doc_element_crit   => l_tbl_doc_element_crit, --table_number(669567 /*251593*/),
                                            i_value                 => l_tbl_value,
                                            i_notes                 => NULL,
                                            i_id_doc_element_qualif => table_table_number(table_number(NULL),
                                                                                          table_number(NULL),
                                                                                          table_number(NULL),
                                                                                          table_number(NULL),
                                                                                          table_number(NULL)),
                                            i_epis_context          => NULL,
                                            i_pat_pregnancy         => i_pat_pregnancy,
                                            i_doc_element_ext       => table_number(l_id_doc_fetus_number), ------------
                                            i_values_ext            => table_number(l_num_children),
                                            i_child_number          => NULL,
                                            i_validate              => NULL,
                                            o_flg_msg               => l_flg_msg,
                                            o_show_warning          => l_show_warning,
                                            o_flg_type              => l_flg_type,
                                            o_title                 => l_title,
                                            o_msg                   => l_msg,
                                            o_epis_documentation    => o_epis_documentation,
                                            o_id_department         => l_id_department,
                                            o_id_clinical_service   => l_id_clinical_service,
                                            o_error                 => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
    
    END set_delivery_assessment;

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
    ) RETURN BOOLEAN IS
    
        l_id_episode        episode.id_episode%TYPE;
        l_id_patient        patient.id_patient%TYPE;
        l_id_schedule       schedule.id_schedule%TYPE;
        l_fetus_number      epis_doc_delivery.fetus_number%TYPE;
        l_fetus_gender      pat_pregn_fetus.flg_gender%TYPE;
        l_fetus_name        patient.name%TYPE;
        l_fetus_alias       patient.alias%TYPE;
        l_fetus_first_name  patient.first_name%TYPE;
        l_fetus_middle_name patient.middle_name%TYPE;
        l_fetus_last_name   patient.last_name%TYPE;
        l_name_number       VARCHAR2(10);
        l_name_mother       patient.name%TYPE;
        l_alias_mother      patient.alias%TYPE;
        l_vip_mother        patient.vip_status%TYPE;
        l_dt_birth_tstz     TIMESTAMP WITH LOCAL TIME ZONE;
    
        l_domain_child_name CONSTANT sys_domain.code_domain%TYPE := 'CHILD_PATIENT_NAME';
        l_val_child_more    CONSTANT sys_domain.val%TYPE := 'M';
        l_val_child_single  CONSTANT sys_domain.val%TYPE := 'S';
        l_val sys_domain.val%TYPE;
    
        l_software_oris CONSTANT software.id_software%TYPE := pk_sysconfig.get_config('SOFTWARE_ID_ORIS', i_prof);
    
        l_id_fam_relationship_m CONSTANT family_relationship.id_family_relationship%TYPE := 3;
        l_id_fam_relationship_f CONSTANT family_relationship.id_family_relationship%TYPE := 4;
        l_id_fam_rel_mother     CONSTANT family_relationship.id_family_relationship%TYPE := 2;
    
        l_id_fam_relationship family_relationship.id_family_relationship%TYPE;
    
        l_exception      EXCEPTION;
        l_temp_exception EXCEPTION;
        l_error  t_error_out;
        l_rowids table_varchar;
    
        l_ret         NUMBER;
        l_ora_sqlcode VARCHAR2(200);
        l_ora_sqlerrm VARCHAR2(4000);
        l_err_desc    VARCHAR2(4000);
        l_err_action  VARCHAR2(4000);
    
        l_child_number episode.id_episode%TYPE;
    
        l_num_records INTEGER := 0;
    
    BEGIN
    
        l_id_patient := i_new_patient;
    
        BEGIN
            SELECT COUNT(*)
              INTO l_num_records
              FROM pat_family_member p
             WHERE p.id_patient = i_new_patient --filho
               AND p.id_pat_related = i_patient; --mãe
        EXCEPTION
            WHEN OTHERS THEN
                l_num_records := 0;
        END;
    
        IF i_child_number IS NOT NULL
        THEN
            l_child_number := i_child_number;
        ELSE
            BEGIN
                SELECT DISTINCT v.child_number
                  INTO l_child_number
                  FROM v_new_born_info v
                 WHERE v.id_epis_documentation = i_epis_documentation
                   AND rownum = 1;
            EXCEPTION
                WHEN OTHERS THEN
                    l_child_number := NULL;
            END;
        
        END IF;
    
        g_error := 'GET FETUS NUMBER';
        IF NOT pk_delivery.get_fetus_number(i_lang, i_prof, i_pat_pregnancy, l_fetus_number, l_error)
        THEN
            RAISE l_exception;
        END IF;
    
        g_error := 'GET BIRTH DATE';
        IF NOT pk_delivery.get_dt_birth(i_lang,
                                        i_prof,
                                        i_pat_pregnancy,
                                        pk_delivery.g_type_dt_birth_e,
                                        l_child_number,
                                        l_dt_birth_tstz,
                                        l_error)
        THEN
            RAISE l_exception;
        END IF;
    
        g_error := 'GET CHILD GENDER';
        SELECT ppf.flg_gender
          INTO l_fetus_gender
          FROM pat_pregn_fetus ppf
         WHERE ppf.id_pat_pregnancy = i_pat_pregnancy
           AND ppf.fetus_number = l_child_number
           AND ppf.flg_status = pk_delivery.g_pregn_fetus_a;
    
        g_error := 'GET MOTHER NAME';
        SELECT name, alias, vip_status
          INTO l_name_mother, l_alias_mother, l_vip_mother
          FROM patient
         WHERE id_patient = i_patient;
    
        l_name_number := to_char(l_child_number) || ' ';
    
        g_error := 'GET DOMAIN VAL';
        IF l_child_number > 3
        THEN
            l_val := l_val_child_more;
        ELSIF l_fetus_number > 1
        THEN
            l_val := l_child_number;
        ELSE
            l_val         := l_val_child_single;
            l_name_number := NULL;
        END IF;
    
        IF i_child_episode IS NULL
        THEN
        
            IF i_prof.software = l_software_oris
            THEN
                g_error := 'CREATE EPISODE TEMP 1';
                l_ret   := pk_sr_visit.create_all_surgery(i_lang           => i_lang,
                                                          i_id_prof        => i_prof.id,
                                                          i_id_institution => i_prof.institution,
                                                          i_id_software    => i_prof.software,
                                                          i_patient        => l_id_patient,
                                                          o_schedule       => l_id_schedule,
                                                          o_ora_sqlcode    => l_ora_sqlcode,
                                                          o_ora_sqlerrm    => l_ora_sqlerrm,
                                                          o_err_desc       => l_err_desc,
                                                          o_err_action     => l_err_action);
            
            ELSE
                g_error := 'CREATE EPISODE TEMP 2';
                l_ret   := pk_visit.create_episode_temp(i_lang           => i_lang,
                                                        i_id_prof        => i_prof.id,
                                                        i_id_institution => i_prof.institution,
                                                        i_id_software    => i_prof.software,
                                                        i_id_patient     => l_id_patient,
                                                        o_ora_sqlcode    => l_ora_sqlcode,
                                                        o_ora_sqlerrm    => l_ora_sqlerrm,
                                                        o_err_desc       => l_err_desc,
                                                        o_err_action     => l_err_action);
            END IF;
        
            IF l_ret = -1
            THEN
                RAISE l_temp_exception;
            END IF;
        
        END IF;
    
        IF i_child_episode IS NULL
        THEN
            l_id_episode := l_ret;
        ELSE
            l_id_episode := i_child_episode;
        END IF;
    
        g_error := 'UPDATE EPIS DOC DELIVERY';
        UPDATE epis_doc_delivery ed
           SET ed.id_child_episode = l_id_episode
         WHERE ed.id_pat_pregnancy = i_pat_pregnancy
           AND ed.id_epis_documentation = i_epis_documentation;
    
        g_error      := 'GET FETUS NAME';
        l_fetus_name := l_name_number || pk_sysdomain.get_domain(l_domain_child_name, l_val, i_lang) || ' ' ||
                        l_name_mother;
    
        g_error := 'GET FETUS ALIAS';
        IF l_alias_mother IS NOT NULL
        THEN
            l_fetus_alias := l_name_number || pk_sysdomain.get_domain(l_domain_child_name, l_val, i_lang) || ' ' ||
                             l_alias_mother;
        END IF;
    
        /* IF i_child_episode IS NULL
        THEN
        
            SELECT DISTINCT v.newborn_name
              INTO l_fetus_first_name
              FROM v_new_born_info v
             WHERE v.id_epis_documentation = i_epis_documentation
               AND rownum = 1;
            l_fetus_name := l_fetus_first_name;
            g_error      := 'UPDATE PATIENT';
        
            ts_patient.upd(id_patient_in  => l_id_patient,
                           name_in        => l_fetus_name,
                           first_name_in  => l_fetus_first_name,
                           middle_name_in => l_fetus_middle_name,
                           last_name_in   => l_fetus_last_name,
                           gender_in      => l_fetus_gender,
                           dt_birth_in    => trunc(CAST(l_dt_birth_tstz AS DATE)),
                           rows_out       => l_rowids);
        
            t_data_gov_mnt.process_update(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'PATIENT',
                                          i_rowids     => l_rowids,
                                          o_error      => l_error);
        
            g_error := 'UPDATE FETUS VIP STATUS';
            UPDATE patient p
               SET p.alias              = l_fetus_alias,
                   p.vip_status         = l_vip_mother,
                   p.dt_birth_tstz      = l_dt_birth_tstz,
                   p.flg_type_dt_birth  = pk_patient.g_flg_type_birth_f,
                   p.flg_level_dt_birth = pk_patient.g_flg_level_dt_birth_h
             WHERE p.id_patient = l_id_patient;
        ELSE
        
            SELECT p.first_name
              INTO l_fetus_name
              FROM patient p
             WHERE p.id_patient = i_new_patient;
        
        END IF;*/
    
        SELECT p.first_name
          INTO l_fetus_name
          FROM patient p
         WHERE p.id_patient = i_new_patient;
    
        g_error := 'GET FAMILY RELATIONSHIP';
        --      IF l_fetus_gender = g_pat_gender_f
        --      THEN
        --          l_id_fam_relationship := l_id_fam_relationship_f;
        --      ELSE
        l_id_fam_relationship := l_id_fam_relationship_m;
        --       END IF;
    
        IF l_num_records = 0
        THEN
            g_error := 'UPDATE PAT FAMILY 1';
            IF NOT
                pk_social.create_pat_family_internal(i_lang                   => i_lang,
                                                     i_id_pat                 => i_patient,
                                                     i_id_new_pat             => l_id_patient,
                                                     i_prof                   => i_prof,
                                                     i_name                   => l_fetus_name,
                                                     i_gender                 => l_fetus_gender,
                                                     i_dt_birth               => NULL,
                                                     i_id_family_relationship => l_id_fam_relationship,
                                                     i_marital_status         => NULL,
                                                     i_scholarship            => NULL,
                                                     i_pension                => NULL,
                                                     i_currency_pension       => NULL,
                                                     i_net_wage               => NULL,
                                                     i_currency_net_wage      => NULL,
                                                     i_unemployment_subsidy   => NULL,
                                                     i_currency_unemp_sub     => NULL,
                                                     i_job                    => NULL,
                                                     i_occupation_desc        => NULL,
                                                     i_prof_cat_type          => pk_prof_utils.get_category(i_lang, i_prof),
                                                     i_epis                   => -1,
                                                     o_error                  => l_error)
            THEN
                RAISE l_exception;
            END IF;
        
            g_error := 'UPDATE PAT FAMILY 1';
            IF NOT
                pk_social.create_pat_family_internal(i_lang                   => i_lang,
                                                     i_id_pat                 => l_id_patient,
                                                     i_id_new_pat             => i_patient,
                                                     i_prof                   => i_prof,
                                                     i_name                   => l_fetus_name,
                                                     i_gender                 => l_fetus_gender,
                                                     i_dt_birth               => NULL,
                                                     i_id_family_relationship => l_id_fam_rel_mother,
                                                     i_marital_status         => NULL,
                                                     i_scholarship            => NULL,
                                                     i_pension                => NULL,
                                                     i_currency_pension       => NULL,
                                                     i_net_wage               => NULL,
                                                     i_currency_net_wage      => NULL,
                                                     i_unemployment_subsidy   => NULL,
                                                     i_currency_unemp_sub     => NULL,
                                                     i_job                    => NULL,
                                                     i_occupation_desc        => NULL,
                                                     i_prof_cat_type          => pk_prof_utils.get_category(i_lang, i_prof),
                                                     i_epis                   => -1,
                                                     o_error                  => l_error)
            THEN
                RAISE l_exception;
            END IF;
        END IF;
    
        o_episode := l_id_episode;
        o_patient := l_id_patient;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN FALSE;
        
    END create_child_episode;

BEGIN

    /* CAN'T TOUCH THIS */
    /* Who am I */
    alertlog.pk_alertlog.who_am_i(owner => g_owner, name => g_package);
    /* Log init */
    alertlog.pk_alertlog.log_init(object_name => g_package);
END pk_pregnancy_api;
/
