/*-- Last Change Revision: $Rev: 2053893 $*/
/*-- Last Change by: $Author: ana.matos $*/
/*-- Date of last change: $Date: 2022-12-30 14:20:45 +0000 (sex, 30 dez 2022) $*/

CREATE OR REPLACE PACKAGE pk_backoffice_exam IS

    -- Author  : TERCIO.SOARES
    -- Created : 15-04-2008 15:34:37
    -- Purpose : Exams Configuration

    /********************************************************************************************
       * Get Exams List
    *
    * @param i_lang            Prefered language ID
    * @param i_search          Search
    * @param i_flg_image       Exams Type
    * @param o_exams_list      Exams list
    * @param o_error           Error
    *
    * @value i_flg_image       {*} 'Y' Image Exam  {*} 'N' Other Exams
    *
    * @return                  true or false on success or error
    *
    * @author                  JTS
    * @version                 0.1
    * @since                   2008/04/15
    ********************************************************************************************/
    FUNCTION get_exams_list
    (
        i_lang      IN language.id_language%TYPE,
        i_search    IN VARCHAR2,
        i_flg_image IN VARCHAR2,
        o_exam_list OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get Exams POSSIBLE LIST
    *
    * @param i_lang            Prefered language ID
    * @param o_list            Plus button options
    * @param o_error           Error
    *
    *
    * @return                  true or false on success or error
    *
    * @author                  JTS
    * @version                 0.1
    * @since                   2008/04/24
    ********************************************************************************************/
    FUNCTION get_exam_poss_list
    (
        i_lang  IN language.id_language%TYPE,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get Exam Information
    *
    * @param i_lang                Prefered language ID
    * @param i_prof                Object (professional ID, institution ID, software ID)
    * @param i_id_exam             Exam ID
    * @param o_exam                Exam
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      JTS
    * @version                     0.1
    * @since                       2008/04/15
    ********************************************************************************************/
    FUNCTION get_exam
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_id_exam IN exam.id_exam%TYPE,
        o_exam    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get other exams type list
    *
    * @param i_lang                Prefered language ID
    * @param o_type                Other exam type list
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      JTS
    * @version                     0.1
    * @since                       2008/04/16
    ********************************************************************************************/
    FUNCTION get_other_exam_type_list
    (
        i_lang  IN language.id_language%TYPE,
        o_type  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get Time Unit Measure Information List
    *
    * @param i_lang                Prefered language ID
    * @param o_unit                Unit measures
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      JTS
    * @version                     0.1
    * @since                       2008/04/16
    ********************************************************************************************/
    FUNCTION get_unit_measure_time
    (
        i_lang  IN language.id_language%TYPE,
        o_unit  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Interval in minutes for a unit_measure
    *
    * @param i_lang                Prefered language ID
    * @param i_prof                Object
    * @param i_freq                Unit number
    * @param i_freq_unit           Unit measure
    * @param o_interval            Interval in minutes
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      JTS
    * @version                     0.1
    * @since                       2008/04/16
    ********************************************************************************************/
    FUNCTION get_interval
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_freq      IN NUMBER,
        i_unit_freq IN NUMBER,
        o_interval  OUT NUMBER,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Insert New Exam OR Update Exam Information
    *
    * @param i_lang                Prefered language ID
    * @param i_prof                Object
    * @param i_id_exam             Exam ID
    * @param i_desc                Exam Name
    * @param i_flg_available       Y - available ; N - not available
    * @param i_flg_type            Exam Type
    * @param i_id_exam_cat         Exam category
    * @param i_gender              Gender
    * @param i_age_min             Minimum age
    * @param i_age_max             Maximum age
    * @param i_mdm_coding          MDM code
    * @param i_cpt_code            CPT code
    * @param i_flg_pat_resp        Term of responsability
    * @param i_flg_pat_prep        Preparation indications
    * @param o_id_exam             Exam ID
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      JTS
    * @version                     0.1
    * @since                       2008/04/16
    ********************************************************************************************/
    FUNCTION set_exam
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_exam       IN exam.id_exam%TYPE,
        i_desc          IN VARCHAR2,
        i_flg_available IN exam.flg_available%TYPE,
        i_flg_type      IN exam.flg_type%TYPE,
        i_id_exam_cat   IN exam.id_exam_cat%TYPE,
        i_gender        IN analysis.gender%TYPE,
        i_age_min       IN analysis.age_min%TYPE,
        i_age_max       IN analysis.age_max%TYPE,
        i_mdm_coding    IN VARCHAR2,
        i_cpt_code      IN VARCHAR2,
        i_flg_pat_resp  IN VARCHAR2,
        i_flg_pat_prep  IN VARCHAR2,
        o_id_exam       OUT exam.id_exam%TYPE,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Update Exam state
    *
    * @param i_lang                Prefered language ID
    * @param i_prof                Professional
    * @param i_id_exam             Exam ID's
    * @param i_flg_available       Y - available ; N - not available
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      JTS
    * @version                     0.1
    * @since                       2008/04/16
    ********************************************************************************************/
    FUNCTION set_exam_state
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_exam       IN table_number,
        i_flg_available IN table_varchar,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /** @headcom
    * Public Function. Get Institution Dep. Clinical Service Exams List
    * 
    * @param      I_LANG                     Identificação do Idioma
    * @param      I_ID_DEP_CLIN_SERV         Identificação do Dept/Serviço clínico
    * @param      I_ID_SOFTWARE              Identificação do Software
    * @param      I_FLG_IMAGE                Y - image exams; N - other exams
    * @param      O_EXAM_DCS_LIST            Cursor com a Informação da Listagem dos exames mais freq.
    * @param      O_ERROR                    Erro
    *
    * @return     boolean
    * @author     JTS
    * @version    0.1
    * @since      2008/04/15
    */
    FUNCTION get_exam_dcs_list
    (
        i_lang             IN language.id_language%TYPE,
        i_id_dept          IN dept.id_dept%TYPE,
        i_id_dep_clin_serv IN exam_dep_clin_serv.id_dep_clin_serv%TYPE,
        i_id_software      IN exam_dep_clin_serv.id_software%TYPE,
        i_id_institution   IN exam_dep_clin_serv.id_institution%TYPE,
        i_flg_image        IN VARCHAR2,
        o_exam_dcs_list    OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Exam/Dep_clin_serv association
    *
    * @param i_lang                  Prefered language ID
    * @param i_prof                  Object (professional ID, institution ID, software ID)
    * @param i_id_institution        Institution ID
    * @param i_id_software           Software ID
    * @param i_dep_clin_serv         Array of Department/Clinical Service ID's
    * @param i_exam                  Exam ID's
    * @param i_select                Array (Y - insert; N - delete)
    * @param i_commit_at_end         Commit (Y - Yes; N - No)
    * @param o_id_exam_dep_clin_serv Associations ID's
    * @param o_error                 Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      JTS
    * @version                     0.1
    * @since                       2008/04/17
    ********************************************************************************************/
    FUNCTION set_exam_dcs
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_id_institution        IN institution.id_institution%TYPE,
        i_id_software           IN software.id_software%TYPE,
        i_dep_clin_serv         IN table_number,
        i_exam                  IN table_table_number,
        i_select                IN table_table_varchar,
        i_commit_at_end         IN VARCHAR2,
        o_id_exam_dep_clin_serv OUT table_number,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get Exams by Institution and Software
    *
    * @param i_lang                Prefered language ID
    * @param i_id_institution      Institution ID
    * @param i_id_software         Software ID
    * @param i_flg_imagem          I - Image exams ; O - Other exams
    * @param i_search              Search
    * @param o_inst_soft_exam_list Exams list
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      JTS
    * @version                     0.1
    * @since                       2008/04/29
    ********************************************************************************************/
    FUNCTION get_inst_soft_exam_list
    (
        i_lang                IN language.id_language%TYPE,
        i_id_institution      IN analysis_instit_soft.id_institution%TYPE,
        i_id_software         IN analysis_instit_soft.id_software%TYPE,
        i_flg_image           IN VARCHAR2,
        i_search              IN VARCHAR2,
        o_inst_soft_exam_list OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    g_error VARCHAR2(2000);

    g_flg_available VARCHAR2(1);
    g_no            VARCHAR2(1);
    g_yes           VARCHAR2(1);

    g_exam_flg_available VARCHAR2(200);
    g_exam_flg_type      VARCHAR2(200);
    g_exam_flg_pat_prep  VARCHAR2(200);
    g_exam_flg_pat_resp  VARCHAR2(200);

    g_patient_gender VARCHAR2(200);

    g_min_unit_measure   NUMBER(24);
    g_hours_unit_measure NUMBER(24);
    g_day_unit_measure   NUMBER(24);
    g_week_unit_measure  NUMBER(24);

    g_hour_min NUMBER(24);
    g_day_min  NUMBER(24);
    g_week_min NUMBER(24);

END pk_backoffice_exam;
/
