/*-- Last Change Revision: $Rev: 2028684 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:47:19 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_exams IS

    /*
    * Fills exams grid task table
    *
    * @param      i_lang           Language
    * @param      i_prof           Profissional
    * @param      i_patient        Patient id
    * @param      i_episode        Episode id
    * @param      i_exam_req       Order exam id
    * @param      i_exam_req_det   Order exam detail id
    * @param      o_error          Error
    *
    * @return     boolean
    * @author     Ana Matos
    * @version    2.5
    * @since      2009/02/19
    */

    FUNCTION set_exam_grid_task
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_patient      IN patient.id_patient%TYPE,
        i_episode      IN episode.id_episode%TYPE,
        i_exam_req     IN exam_req.id_exam_req%TYPE,
        i_exam_req_det IN exam_req_det.id_exam_req_det%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Fills grid task other exams table
    *
    * @param      i_lang           Language
    * @param      i_prof           Profissional
    * @param      i_patient        Patient id
    * @param      i_episode        Episode id
    * @param      i_exam_req       Order exam id
    * @param      i_exam_req_det   Order exam detail id
    * @param      o_error          Error
    *
    * @return     boolean
    * @author     Ana Matos
    * @version    2.5
    * @since      2009/02/19
    */

    FUNCTION set_exam_grid_task
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_patient      IN patient.id_patient%TYPE,
        i_episode      IN episode.id_episode%TYPE,
        i_exam_req     IN exam_req.id_exam_req%TYPE,
        i_exam_req_det IN exam_req_det.id_exam_req_det%TYPE,
        i_flg_type     IN exam.flg_type%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Fills grid task other exams table
    *
    * @param      i_lang          Language
    * @param      i_prof          Profissional
    * @param      i_patient       Patient id
    * @param      i_episode       Episode id
    * @param      i_exam_req      Order exam id
    * @param      i_flg_contact   Contact status
    * @param      o_error         Error
    *
    * @return     boolean
    * @author     Ana Matos
    * @version    2.5
    * @since      2009/02/19
    */

    FUNCTION set_technician_grid_status
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_patient        IN exam_req.id_patient%TYPE,
        i_episode        IN exam_req.id_episode%TYPE,
        i_exam_req       IN exam_req.id_exam_req%TYPE,
        i_flg_contact    IN exam_req.flg_contact%TYPE,
        i_transaction_id IN VARCHAR2 DEFAULT NULL,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    PROCEDURE set_exam_episode_status
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_event_type        IN VARCHAR2,
        i_rowids            IN table_varchar,
        i_source_table_name IN VARCHAR2,
        i_list_columns      IN table_varchar,
        i_dg_table_name     IN VARCHAR
    );

    /*
    * Returns a list of requests' origins to filter the technician grid
    *
    * @param     i_lang    Language id
    * @param     i_prof    Professional
    * @param     o_list    Cursor
    * @param     o_error   Error message
    
    * @return    true or false on success or error
    *
    * @author    Ana Matos
    * @version   2.5
    * @since     2009/02/18
    */

    FUNCTION get_technician_grid_view
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Returns a list of statuses to be shown in the technician grid
    *
    * @param     i_lang       Language id
    * @param     i_prof       Professional
    * @param     i_exam_req   Exam's order id
    * @param     o_list       Cursor
    * @param     o_error      Error message
    
    * @return    true or false on success or error
    *
    * @author    Ana Matos
    * @version   2.5
    * @since     2009/03/20
    */

    FUNCTION get_technician_grid_list
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_exam_req IN exam_req.id_exam_req%TYPE,
        o_list     OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Returns the technician grid
    *
    * @param     i_lang     Language id
    * @param     i_prof     Professional
    * @param     i_filter   Flag that indicates the selected filter
    * @param     o_list     Cursor
    * @param     o_error    Error message
    
    * @return    true or false on success or error
    *
    * @author    Ana Matos
    * @version   2.5
    * @since     2009/02/18
    */

    FUNCTION get_technician_grid
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_filter IN VARCHAR2,
        o_list   OUT pk_types.cursor_type,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Checks if the technician has started the contact with the patient
    *
    * @param     i_lang        Language id
    * @param     i_prof        Professional
    * @param     i_exam_req    Exam order ir
    * @param     o_flg_show    Y/N
    * @param     o_msg_title   Message title
    * @param     o_msg         Message
    * @param     o_error       Error message
    
    * @return    true or false on success or error
    *
    * @author    Ana Matos
    * @version   2.5
    * @since     2009/03/27
    */

    FUNCTION check_technician_contact
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_exam_req  IN exam_req.id_exam_req%TYPE,
        o_flg_show  OUT VARCHAR2,
        o_msg_title OUT VARCHAR2,
        o_msg       OUT VARCHAR2,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Returns the exams that can be scheduled or rescheduled for a patient
    *
    * @param     i_lang      Language id
    * @param     i_prof      Professional
    * @param     i_patient   Patient id
    * @param     o_list      Cursor
    * @param     o_error     Error message
    
    * @return    true or false on success or error
    *
    * @author    Ana Matos
    * @version   2.7.4.6
    * @since     2018/11/16
    */

    FUNCTION get_exam_to_schedule_list
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        o_list    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Returns a list of exams for a given patient and episode
    *
    * @param     i_lang    Language id
    * @param     i_prof    Professional
    * @param     o_list    Cursor
    * @param     o_error   Error message
    
    * @return    true or false on success or error
    *
    * @author    Ana Matos
    * @version   2.5
    * @since     2009/03/06
    */

    FUNCTION get_exam_list
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        i_episode IN exam_req.id_episode%TYPE,
        o_list    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_exam_list_edit
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_exam_req_det IN table_number,
        o_list         OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Returns the information nedded to show in the HPI summary
    *
    * @param     i_lang              Language id
    * @param     i_prof              Professional
    * @param     i_patient           Patient id
    * @param     i_episode           Episode id
    * @param     i_epis_type         Episode type id
    * @param     o_title_anamnesis   Anamnesis title message
    * @param     o_anamnesis         Anamnesis
    * @param     o_title_diagnosis   Diagnosis title message
    * @param     o_diagnosis         Diagnosis
    * @param     o_error             Error message
    
    * @return    true or false on success or error
    *
    * @author    Ana Matos
    * @version   2.5
    * @since     2009/03/06
    */

    FUNCTION get_hpi_summary
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_patient         IN patient.id_patient%TYPE,
        i_episode         IN episode.id_episode%TYPE,
        i_epis_type       IN epis_type.id_epis_type%TYPE,
        o_title_anamnesis OUT VARCHAR2,
        o_anamnesis       OUT VARCHAR2,
        o_title_diagnosis OUT VARCHAR2,
        o_diagnosis       OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    PROCEDURE init_params_grid
    (
        i_filter_name   IN VARCHAR2,
        i_custom_filter IN NUMBER,
        i_context_ids   IN table_number,
        i_context_keys  IN table_varchar DEFAULT NULL,
        i_context_vals  IN table_varchar,
        i_name          IN VARCHAR2,
        o_vc2           OUT VARCHAR2,
        o_num           OUT NUMBER,
        o_id            OUT NUMBER,
        o_tstz          OUT TIMESTAMP WITH LOCAL TIME ZONE
    );

    g_package_owner VARCHAR2(50);
    g_package_name  VARCHAR2(50);

    g_user_exception  EXCEPTION;
    g_other_exception EXCEPTION;
    g_error VARCHAR2(4000);

    g_sysdate_tstz TIMESTAMP WITH LOCAL TIME ZONE;
    g_sysdate_char VARCHAR2(50);
    g_found        BOOLEAN;

    g_technician CONSTANT VARCHAR(1) := 'T';

    g_exam_req_all CONSTANT VARCHAR(1) := '0';
    g_exam_req_ext CONSTANT VARCHAR(2) := '-1';

    g_ft_status CONSTANT VARCHAR2(1) := 'A';

END pk_exams;
/
