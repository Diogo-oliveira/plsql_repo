/*-- Last Change Revision: $Rev: 2028834 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:48:13 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_p1_exam AS

    /********************************************************************************************
    * Returns a list with the most frequent exams for a given professional
    *
    * @param i_lang          Language ID
    * @param i_prof          Professional info: id, institution and software
    * @param i_patient       Patient ID
    * @param i_exam_type     Exam type {*} 'I' Image {*} 'E' Other Exams
    * @param i_codification  Exam codification id
    * @param o_list          Exam list
    * @param o_error         Error message
    *
    * @return                TRUE if sucess, FALSE otherwise
    *
    * @author                Ana Monteiro
    * @version               1.0
    * @since                 2009-09-08
    ********************************************************************************************/
    FUNCTION get_exam_selection_list
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_patient      IN patient.id_patient%TYPE,
        i_exam_type    IN exam.flg_type%TYPE,
        i_codification IN codification.id_codification%TYPE,
        o_list         OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Returns a list with the exams' categories
    *
    * @param i_lang          Language ID
    * @param i_prof          Professional info: id, institution and software
    * @param i_patient       Patient ID
    * @param i_exam_type     Exam type {*} 'I' Image {*} 'E' Other Exams
    * @param i_codification  Exam codification id
    * @param o_list          Exam list
    * @param o_error         Error message
    *
    * @return                TRUE if sucess, FALSE otherwise
    *
    * @author                Ana Monteiro
    * @version               1.0
    * @since                 2009-09-08
    ********************************************************************************************/
    FUNCTION get_exam_category_search
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_patient      IN patient.id_patient%TYPE,
        i_exam_type    IN exam.flg_type%TYPE,
        i_codification IN codification.id_codification%TYPE,
        o_list         OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Returns a list with the exams' within a given category
    *
    * @param i_lang          Language ID
    * @param i_prof          Professional info: id, institution and software
    * @param i_patient       Patient ID
    * @param i_exam_cat      Exam category ID
    * @param i_exam_type     Exam type {*} 'I' Image {*} 'E' Other Exams        
    * @param i_codification  Exam codification id
    * @param o_list          Exam list
    * @param o_error         Error message
    *
    * @return                TRUE if sucess, FALSE otherwise
    *
    * @author                Ana Monteiro
    * @version               1.0
    * @since                 2009-09-08
    ********************************************************************************************/
    FUNCTION get_exam_in_category
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_patient      IN patient.id_patient%TYPE,
        i_exam_cat     IN exam_cat.id_exam_cat%TYPE,
        i_exam_type    IN exam.flg_type%TYPE,
        i_codification IN codification.id_codification%TYPE,
        o_list         OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Returns a list with the results of the user search
    *
    * @param i_lang          Language ID
    * @param i_prof          Professional info: id, institution and software
    * @param i_patient       Patient ID
    * @param i_exam_type     Exam type {*} 'I' Image {*} 'E' Other Exams
    * @param i_value         Search string        
    * @param i_codification  Exam codification id
    * @param o_flg_show      If exist message to show {*} 'Y' Yes {*} 'N' No
    * @param o_msg           Message indicating that exceeded the limit of records
    * @param o_msg_title     Title of the message to the user, if o_flg_show is 'Y'
    * @param o_list          Exam list
    * @param o_error         Error message
    *
    * @return                TRUE if sucess, FALSE otherwise
    *
    * @author                Ana Monteiro
    * @version               1.0
    * @since                 2009-09-08
    ********************************************************************************************/

    FUNCTION get_exam_search
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_patient      IN patient.id_patient%TYPE,
        i_exam_type    IN exam.flg_type%TYPE,
        i_value        IN VARCHAR2,
        i_codification IN codification.id_codification%TYPE,
        o_flg_show     OUT VARCHAR2,
        o_msg          OUT VARCHAR2,
        o_msg_title    OUT VARCHAR2,
        o_list         OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get institutions for the selected exam
    *
    * @param   I_LANG      language associated to the professional executing the request
    * @param   I_PROF      professional, institution and software ids
    * @value   i_exam_     type Exam type {*} 'I' Image {*} 'E' Other Exams
    * @param   I_EXAM      selected exam
    * @param   O_INST_DEST destination institution
    * @param   O_REF_AREA  flag to reference area
    * @param   O_ERROR     an error message, set when return=false
    *
    * @value   O_REF_AREA  {*} 'Y' in reference area {*} 'N' out of reference area
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author              Joana Barroso
    * @version             2.4.3
    * @since               19/03/2008
    *
    * @modify              Joana Barroso 21/04/2008 New param i_exam_type
    * @modify              Joana Barroso 22/04/2008 Elimination of 
    *                            (eis.flg_type = g_exam_exec OR eis.flg_type = g_exam_freq)   
    * @modify              Joana Barroso 08/05/2008 JOIN
    * @modify              Ana Monteiro 12/12/2008 ALERT-11933
    ********************************************************************************************/
    FUNCTION get_exam_institutions
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_exam_type    IN exam.flg_type%TYPE,
        i_exam         IN exam.id_exam%TYPE,
        o_institutions OUT pk_types.cursor_type,
        o_ref_area     OUT VARCHAR2,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get default institutions for the selected exam
    *
    * @param   I_LANG          language associated to the professional executing the request
    * @param   I_PROF          professional, institution and software ids
    * @value   i_exam_type     Exam type {*} 'I' Image {*} 'E' Other Exams
    * @param   I_EXAM          selected exam
    * @param   O_INST_DEST     default destination institution
    * @param   O_REF_AREA      flag to reference area
    * @param   O_ERROR an      error message, set when return=false
    *
    * @value   O_REF_AREA      {*} 'Y' in reference area {*} 'N' out of reference area
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author                  Joana Barroso
    * @version                 2.4.3
    * @since                   19/03/2008
    * @modify                  Joana Barroso 21/04/2008 New param i_exam_type
    * @modify                  Joana Barroso 22/04/2008 Elimination of 
    *                                (dcs.flg_type = g_exam_exec OR dcs.flg_type = g_exam_freq)
    * @modify                  Joana Barroso 08/05/2008 JOIN
    * @modify                  Ana Monteiro 12/12/2008 ALERT-11933
    ********************************************************************************************/
    FUNCTION get_exam_default_insts
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_exam_type    IN exam.flg_type%TYPE,
        i_exam         IN table_number,
        o_institutions OUT pk_types.cursor_type,
        o_ref_area     OUT VARCHAR2,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * get common institution based on all required exams
    *
    * @param    i_lang            preferred language id
    * @param    i_prof            object (id of professional, id of institution, id of software)
    * @param    i_exams           array of requested exams
    * ######    i_flg_type        (is not required here because the id_exam itself is enough to 
    * ######                      identify image exams from other exams)
    * @param    o_inst            cursor with institution information
    * @param    o_error           error message structure
    *
    * @return   boolean           false in case of error, otherwise true
    *
    * @author   Carlos Loureiro
    * @version  1.0
    * @since    2009/08/28
    ********************************************************************************************/
    FUNCTION get_exam_inst
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_exams IN table_number,
        o_inst  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_exam_inst
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_exams IN varchar2
    ) RETURN t_tbl_core_domain;

    --
    --       
    g_package_name  VARCHAR2(50);
    g_package_owner VARCHAR2(50);

    g_sysdate DATE;
    g_error   VARCHAR2(2000);
    g_exception EXCEPTION;
    g_retval BOOLEAN;

    g_selected          CONSTANT VARCHAR2(1) := 'S';
    g_doc_area_exam     CONSTANT doc_area.id_doc_area%TYPE := 1083;
    g_ref_external_inst CONSTANT sys_config.id_sys_config%TYPE := 'REF_EXTERNAL_INST';
END;
/
