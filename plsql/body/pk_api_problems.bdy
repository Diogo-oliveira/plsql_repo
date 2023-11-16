/*-- Last Change Revision: $Rev: 1850754 $*/
/*-- Last Change by: $Author: ana.matos $*/
/*-- Date of last change: $Date: 2018-07-05 15:20:59 +0100 (qui, 05 jul 2018) $*/

CREATE OR REPLACE PACKAGE BODY pk_api_problems IS

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
    * @param i_unk_resolution         Is resolution date u
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
    ) RETURN BOOLEAN IS
        e_call_exception EXCEPTION;
        --created problems
        l_problem_ids table_number;
    
    BEGIN
        g_error := 'create_pat_problem_array';
        IF NOT create_pat_problem_array(i_lang                   => i_lang,
                                        i_epis                   => i_epis,
                                        i_pat                    => i_pat,
                                        i_prof                   => i_prof,
                                        i_desc_problem           => table_varchar(i_desc_problem),
                                        i_flg_status             => table_varchar(i_flg_status),
                                        i_notes                  => table_varchar(i_notes),
                                        i_prof_cat_type          => i_prof_cat_type,
                                        i_diagnosis              => table_number(i_diagnosis),
                                        i_flg_nature             => table_varchar(i_flg_nature),
                                        i_precaution_measure     => table_table_number(i_precaution_measure),
                                        i_header_warning         => table_varchar(i_header_warning),
                                        i_dt_diagnosed           => table_varchar(i_dt_diagnosed),
                                        i_dt_diagnosed_precision => table_varchar(i_dt_diagnosed_precision),
                                        i_dt_resolved            => table_varchar(i_dt_resolved),
                                        i_dt_resolved_precision  => table_varchar(i_dt_resolved_precision),
                                        o_id_problem             => l_problem_ids,
                                        o_error                  => o_error)
        THEN
            RAISE e_call_exception;
        END IF;
    
        --only one record is created
        o_id_problem := l_problem_ids(1);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'CREATE_PAT_PROBLEM',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END;

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
    ) RETURN BOOLEAN IS
        e_call_exception EXCEPTION;
        l_ids table_number;
    BEGIN
        g_error := 'create_pat_problem_array';
        IF NOT create_pat_problem_array(i_lang               => i_lang,
                                        i_epis               => i_epis,
                                        i_pat                => i_pat,
                                        i_prof               => i_prof,
                                        i_desc_problem       => table_varchar(i_desc_problem),
                                        i_flg_status         => table_varchar(i_flg_status),
                                        i_notes              => table_varchar(i_notes),
                                        i_prof_cat_type      => i_prof_cat_type,
                                        i_diagnosis          => table_number(i_diagnosis),
                                        i_flg_nature         => table_varchar(i_flg_nature),
                                        i_precaution_measure => table_table_number(table_number(i_precaution_measure)),
                                        i_header_warning     => table_varchar(i_header_warning),
                                        o_id_problem         => l_ids,
                                        o_error              => o_error)
        THEN
            RAISE e_call_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'CREATE_PAT_PROBLEM',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END;

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
    * @author                         Pedro Teixeira
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
    ) RETURN BOOLEAN IS
        e_call_exception EXCEPTION;
    
        l_msg       VARCHAR2(4000 CHAR);
        l_msg_title VARCHAR2(4000 CHAR);
        l_flg_show  VARCHAR2(4000 CHAR);
        l_button    VARCHAR2(4000 CHAR);
        l_type      table_varchar;
    
    BEGIN
    
        g_error := 'call pk_problems.create_pat_problem_array';
        IF NOT pk_problems.create_pat_problem_array(i_lang                   => i_lang,
                                                    i_epis                   => i_epis,
                                                    i_pat                    => i_pat,
                                                    i_prof                   => i_prof,
                                                    i_desc_problem           => i_desc_problem,
                                                    i_flg_status             => i_flg_status,
                                                    i_notes                  => i_notes,
                                                    i_prof_cat_type          => i_prof_cat_type,
                                                    i_diagnosis              => i_diagnosis,
                                                    i_flg_nature             => i_flg_nature,
                                                    i_precaution_measure     => i_precaution_measure,
                                                    i_header_warning         => i_header_warning,
                                                    i_dt_diagnosed           => i_dt_diagnosed,
                                                    i_dt_diagnosed_precision => i_dt_diagnosed_precision,
                                                    i_dt_resolved            => i_dt_resolved,
                                                    i_dt_resolved_precision  => i_dt_resolved_precision,
                                                    i_location               => NULL,
                                                    o_msg                    => l_msg,
                                                    o_msg_title              => l_msg_title,
                                                    o_flg_show               => l_flg_show,
                                                    o_button                 => l_button,
                                                    o_type                   => l_type,
                                                    o_ids                    => o_id_problem,
                                                    o_error                  => o_error)
        THEN
            RAISE e_call_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'CREATE_PAT_PROBLEM_ARRAY',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END;

    /**********************************************************************************************
    * updates problem record
    *
    * @return                         true if sucess, false otherwise
    *                        
    * @author                         Pedro Teixeira
    * @since                          23-07-2010
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
    ) RETURN BOOLEAN IS
        e_call_exception EXCEPTION;
    
        -- cursor vars
        l_pat_problem pat_problem.id_pat_problem%TYPE;
        l_calc_type   VARCHAR2(1 CHAR);
    
        CURSOR c_pp IS
            SELECT id_pat_problem
              FROM pat_problem
             WHERE id_pat_problem = i_id_pat_problem;
    
    BEGIN
        -- determin the problem type
        IF i_type IS NULL
        THEN
            g_error := 'GET L_ID_DIAGNOSIS';
            OPEN c_pp;
            FETCH c_pp
                INTO l_pat_problem;
            CLOSE c_pp;
        
            IF l_pat_problem IS NULL -- means that the ID is from pat_history_diagnosis table
            THEN
                l_calc_type := 'D'; -- diagnosis
            ELSE
                l_calc_type := 'P'; -- problem
            END IF;
        ELSE
            l_calc_type := i_type;
        END IF;
    
        g_error := 'call set_pat_problem_array';
        IF NOT set_pat_problem_array(i_lang,
                                     i_epis                  => i_epis,
                                     i_pat                   => i_pat,
                                     i_prof                  => i_prof,
                                     i_id_pat_problem        => table_number(i_id_pat_problem),
                                     i_flg_status            => table_varchar(i_flg_status),
                                     i_notes                 => table_varchar(i_notes),
                                     i_type                  => table_varchar(l_calc_type),
                                     i_prof_cat_type         => i_prof_cat_type,
                                     i_flg_nature            => table_varchar(i_flg_nature),
                                     i_precaution_measure    => table_table_number(table_number(i_precaution_measure)),
                                     i_header_warning        => table_varchar(i_header_warning),
                                     i_dt_resolved           => table_varchar(i_dt_resolved),
                                     i_dt_resolved_precision => table_varchar(i_dt_resolved_precision),
                                     o_error                 => o_error)
        
        THEN
            RAISE e_call_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'SET_PAT_PROBLEM',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END;

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
    ) RETURN BOOLEAN IS
        l_type table_varchar := table_varchar();
        l_ids  table_number := table_number();
        e_call_exception EXCEPTION;
    
    BEGIN
    
        g_error := 'call pk_problems.set_pat_problem_array';
        IF NOT pk_problems.set_pat_problem_array(i_lang                  => i_lang,
                                                 i_epis                  => i_epis,
                                                 i_pat                   => i_pat,
                                                 i_prof                  => i_prof,
                                                 i_id_pat_problem        => i_id_pat_problem,
                                                 i_flg_status            => i_flg_status,
                                                 i_notes                 => i_notes,
                                                 i_type                  => i_type,
                                                 i_prof_cat_type         => i_prof_cat_type,
                                                 i_flg_nature            => i_flg_nature,
                                                 i_precaution_measure    => i_precaution_measure,
                                                 i_header_warning        => i_header_warning,
                                                 i_dt_resolved           => i_dt_resolved,
                                                 i_dt_resolved_precision => i_dt_resolved_precision,
                                                 o_type                  => l_type,
                                                 o_ids                   => l_ids,
                                                 o_error                 => o_error)
        THEN
            RAISE e_call_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'SET_PAT_PROBLEM_ARRAY',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END;

BEGIN
    pk_alertlog.log_init(pk_alertlog.who_am_i);
    g_owner   := 'ALERT';
    g_package := 'PK_API_PROBLEMS';

END pk_api_problems;
/
