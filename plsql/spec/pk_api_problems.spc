/*-- Last Change Revision: $Rev: 1850754 $*/
/*-- Last Change by: $Author: ana.matos $*/
/*-- Date of last change: $Date: 2018-07-05 15:20:59 +0100 (qui, 05 jul 2018) $*/

CREATE OR REPLACE PACKAGE pk_api_problems IS

    /**********************************************************************************************
    * creates problem records and associates them to patient
    * 
    * @param i_lang                   Language id
    * @param i_epis                   Episode id
    * @param i_pat                    Patient id
    * @param i_prof                   professional, software and institution id's             
    * @param i_desc_problem           Problem description 
    * @param i_flg_status             Problem status
    * @param i_notes                  Problem notes - optional
    * @param i_year_begin             Problem start date (Year) - optional
    * @param i_month_begin            Problem start date (Month) - optional
    * @param i_day_begin              Problem start date (Day) - optional
    * @param i_prof_cat_type          category of professional
    * @param i_diagnosis              Diagnoses id - optional
    * @param i_flg_nature             Problem nature (A-acute, C-chronic, S-Self-limiting) - optional
    * @param i_year_resolution        Problem resolution date (Year) - optional
    * @param i_month_resolution       Problem resolution date (Month) - optional
    * @param i_day_resolution         Problem resolution date (Day) - optional
    * @param i_precaution_measure     List of precaution measures - optional
    * @param i_header_warning         Header warning - optional
    * @param o_msg                     
    * @param o_msg_title              
    * @param o_flg_show               
    * @param o_button                 
    * @param o_error                  error message
    *
    * @return                         true if sucess, false otherwise
    *                        
    **********************************************************************************************/
    FUNCTION create_pat_problem
    (
        i_lang                   IN language.id_language%TYPE,
        i_epis                   IN episode.id_episode%TYPE,
        i_pat                    IN pat_problem.id_patient%TYPE,
        i_prof                   IN profissional,
        i_desc_problem           IN pat_history_diagnosis.desc_pat_history_diagnosis%TYPE,
        i_flg_status             IN pat_history_diagnosis.flg_status%TYPE,
        i_notes                  IN pat_history_diagnosis.notes%TYPE,
        i_prof_cat_type          IN category.flg_type%TYPE,
        i_diagnosis              IN alert_diagnosis.id_alert_diagnosis%TYPE,
        i_flg_nature             IN pat_history_diagnosis.flg_nature%TYPE,
        i_precaution_measure     IN table_number,
        i_header_warning         IN pat_history_diagnosis.flg_warning%TYPE DEFAULT 'N',
        i_dt_diagnosed           IN VARCHAR2,
        i_dt_diagnosed_precision IN pat_history_diagnosis.dt_diagnosed_precision%TYPE,
        i_dt_resolved            IN VARCHAR2,
        i_dt_resolved_precision  IN pat_history_diagnosis.dt_resolved_precision%TYPE,
        o_id_problem             OUT pat_history_diagnosis.id_pat_history_diagnosis%TYPE,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN;

    -- Author  : Pedro Teixeira
    -- Created : 23-07-2010
    -- Purpose : API for Problem managment

    /**********************************************************************************************
    * creates problem record
    *
    * @return                         true if sucess, false otherwise
    *                        
    * @author                         Pedro Teixeira
    * @since                          23-07-2010
    **********************************************************************************************/
    FUNCTION create_pat_problem
    (
        i_lang               IN language.id_language%TYPE,
        i_epis               IN episode.id_episode%TYPE,
        i_pat                IN pat_problem.id_patient%TYPE,
        i_prof               IN profissional,
        i_desc_problem       IN pat_history_diagnosis.desc_pat_history_diagnosis%TYPE,
        i_flg_status         IN pat_history_diagnosis.flg_status%TYPE,
        i_notes              IN pat_history_diagnosis.notes%TYPE,
        i_dt_symptoms        IN VARCHAR2,
        i_prof_cat_type      IN category.flg_type%TYPE,
        i_diagnosis          IN alert_diagnosis.id_alert_diagnosis%TYPE,
        i_flg_nature         IN pat_history_diagnosis.flg_nature%TYPE,
        i_dt_resolution      IN VARCHAR2,
        i_precaution_measure IN pat_hist_diag_precaution.id_precaution%TYPE,
        i_header_warning     IN pat_history_diagnosis.flg_warning%TYPE,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * creates problem records and associates them to patient
    * (overload created for legacy support)
    * 
    * @param i_lang                   id language
    * @param i_epis                   episode id
    * @param i_pat                    patient id
    * @param i_prof                   professional, software and institution id's             
    * @param i_desc_problem           problem description 
    * @param i_flg_status             flag status
    * @param i_notes                  list of notes to apply in all problems
    * @param i_dt_symptoms            start date of the problem   
    * @param i_epis_anamnesis         complaint id  
    * @param i_prof_cat_type          category of professional
    * @param i_diagnosis              list of diagnoses id's
    * @param i_flg_nature             list of problem natures (A-acute, C-chronic, S-Self-limiting)
    * @param i_dt_resolution          list of resolution dates
    * @param i_precaution_measure     list of precaution measures
    * @param i_header_warning         list of header warning
    * @param o_msg                     
    * @param o_msg_title              
    * @param o_flg_show               
    * @param o_button                 
    * @param o_error                  error message
    *
    * @return                         true if sucess, false otherwise
    *                        
    * @author                         Carlos Loureiro
    * @version                        1.0 
    * @since                          23-07-2010
    **********************************************************************************************/
    FUNCTION create_pat_problem_array
    (
        i_lang                   IN language.id_language%TYPE,
        i_epis                   IN episode.id_episode%TYPE,
        i_pat                    IN pat_problem.id_patient%TYPE,
        i_prof                   IN profissional,
        i_desc_problem           IN table_varchar,
        i_flg_status             IN table_varchar,
        i_notes                  IN table_varchar,
        i_prof_cat_type          IN category.flg_type%TYPE,
        i_diagnosis              IN table_number,
        i_flg_nature             IN table_varchar,
        i_precaution_measure     IN table_table_number,
        i_header_warning         IN table_varchar,
        i_dt_diagnosed           IN table_varchar DEFAULT NULL,
        i_dt_diagnosed_precision IN table_varchar DEFAULT NULL,
        i_dt_resolved            IN table_varchar DEFAULT NULL,
        i_dt_resolved_precision  IN table_varchar DEFAULT NULL,
        o_id_problem             OUT table_number,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * updates problem record
    *
    * @return                         true if sucess, false otherwise
    *                        
    * @author                         Pedro Teixeira
    * @since                          05-11-2010
    **********************************************************************************************/
    FUNCTION set_pat_problem
    (
        i_lang                  IN language.id_language%TYPE,
        i_epis                  IN episode.id_episode%TYPE,
        i_pat                   IN pat_problem.id_patient%TYPE,
        i_prof                  IN profissional,
        i_id_pat_problem        IN pat_problem.id_pat_problem%TYPE,
        i_flg_status            IN pat_history_diagnosis.flg_status%TYPE,
        i_notes                 IN pat_history_diagnosis.notes%TYPE,
        i_type                  IN VARCHAR2,
        i_prof_cat_type         IN category.flg_type%TYPE,
        i_flg_nature            IN pat_history_diagnosis.flg_nature%TYPE,
        i_precaution_measure    IN pat_hist_diag_precaution.id_precaution%TYPE,
        i_header_warning        IN pat_history_diagnosis.flg_warning%TYPE,
        i_dt_resolved           IN pat_history_diagnosis.dt_resolved%TYPE,
        i_dt_resolved_precision IN pat_history_diagnosis.dt_resolved_precision%TYPE,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN;

    /************************************************************************************************************************
    * Based on pk_problems.set_pat_problem_array_internal
    * Alterar / cancelar problema do doente. 
    * Usada no ecrã de mudanças de estado dos "Problemas" do doente, pq  permite a mudança de estado de vários problemas em simultâneo.
    * It does not perform a commit. 
    * Should not be called from flash, it's for database internal use.
    * 
    * @param i_lang The language id
    * @param i_epis The episode id
    * @param i_pat The patient id
    * @param i_prof The professional, institution and software ids    
    * @param i_id_pat_problem An array with pat problem ids
    * @param i_flg_status An array the the flg status values
    * @param i_notes An array with notes
    * @param i_type An array with pat problem types
    * @param i_id_prof_cat_type the professional category type
    * @param i_flg_nature An array with patient problem natures
    * @param o_error An error message to explain what went wrong if the execution fails.
    *
    * @return True if succeded, false otherwise.
    *
    * @author Pedro Teixeira, copied from pk_problems.set_pat_problem_array_internal
    * @version 1
    * @since 05-11-2010
    */
    FUNCTION set_pat_problem_array
    (
        i_lang                  IN language.id_language%TYPE,
        i_epis                  IN episode.id_episode%TYPE,
        i_pat                   IN pat_problem.id_patient%TYPE,
        i_prof                  IN profissional,
        i_id_pat_problem        IN table_number,
        i_flg_status            IN table_varchar,
        i_notes                 IN table_varchar,
        i_type                  IN table_varchar,
        i_prof_cat_type         IN category.flg_type%TYPE,
        i_flg_nature            IN table_varchar,
        i_precaution_measure    IN table_table_number,
        i_header_warning        IN table_varchar,
        i_dt_resolved           IN table_varchar,
        i_dt_resolved_precision IN table_varchar,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN;

    /**######################################################
      GLOBALS
    ######################################################**/
    g_owner   VARCHAR2(50);
    g_package VARCHAR2(50);
    g_error   VARCHAR2(4000);

END pk_api_problems;
/
