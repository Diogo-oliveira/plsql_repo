/*-- Last Change Revision: $Rev: 2028746 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:47:40 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_inp_global_search AS

    -- Author  : VANESSA.BARSOTTELLI
    -- Created : 11/27/2013 8:51:53 AM
    -- Purpose : Package that should contain all functions/procedures for Global Search    

    /************************************************************************************************************
    * Get epis positioning info: episode, patient, professional and date record
    * Used for global search.
    *
    * @param i_owner         table owner
    * @param i_table         table name
    * @param i_rowtype       table rowtype
    *
    * @return                Info of episode, patient, professional and date record
    *
    * @author                Vanessa Barsottelli
    * @version               2.6.3
    * @since                 2013/11/22
    ***********************************************************************************************************/
    FUNCTION get_epis_pos_info
    (
        i_owner   IN VARCHAR2,
        i_table   IN VARCHAR2,
        i_rowtype IN epis_positioning%ROWTYPE
    ) RETURN t_trl_trs_result;

    /************************************************************************************************************
    * Get epis positioning description 
    * Used for global search.
    *
    * @param i_owner         table owner
    * @param i_table         table name
    * @param i_lang          language identifier
    * @param i_prof          professional identifier
    * @param i_rowtype       table rowtype
    * @param o_code_list     code list
    * @param o_desc_list     description list
    *
    * @return                List of code and description
    *
    * @author                Vanessa Barsottelli
    * @version               2.6.3
    * @since                 2013/11/22
    ***********************************************************************************************************/
    PROCEDURE get_epis_pos_code
    (
        i_owner     IN VARCHAR2,
        i_table     IN VARCHAR2,
        i_lang      IN NUMBER,
        i_prof      IN profissional,
        i_rowtype   IN epis_positioning%ROWTYPE,
        o_code_list OUT table_varchar,
        o_desc_list OUT table_varchar
    );

    /************************************************************************************************************
    * Get epis positioning plan info: episode, patient, professional and date record
    * Used for global search.
    *
    * @param i_owner         table owner
    * @param i_table         table name
    * @param i_rowtype       table rowtype
    *
    * @return                Info of episode, patient, professional and date record
    *
    * @author                Vanessa Barsottelli
    * @version               2.6.3
    * @since                 2013/11/27
    ***********************************************************************************************************/
    FUNCTION get_epis_pos_plan_info
    (
        i_owner   IN VARCHAR2,
        i_table   IN VARCHAR2,
        i_rowtype IN epis_positioning_plan%ROWTYPE
    ) RETURN t_trl_trs_result;

    /************************************************************************************************************
    * Get epis positioning det info: episode, patient, professional and date record
    * Used for global search.
    *
    * @param i_owner         table owner
    * @param i_table         table name
    * @param i_rowtype       table rowtype
    *
    * @return                Info of episode, patient, professional and date record
    *
    * @author                Vanessa Barsottelli
    * @version               2.6.3
    * @since                 2013/11/22
    ***********************************************************************************************************/
    FUNCTION get_epis_pos_det_info
    (
        i_owner   IN VARCHAR2,
        i_table   IN VARCHAR2,
        i_rowtype IN epis_positioning_det%ROWTYPE
    ) RETURN t_trl_trs_result;

    /************************************************************************************************************
    * Get epis positioning det description 
    * Used for global search.
    *
    * @param i_owner         table owner
    * @param i_table         table name
    * @param i_lang          language identifier
    * @param i_prof          professional identifier
    * @param i_rowtype       table rowtype
    * @param o_code_list     code list
    * @param o_desc_list     description list
    *
    * @return                List of code and description
    *
    * @author                Vanessa Barsottelli
    * @version               2.6.3
    * @since                 2013/11/22
    ***********************************************************************************************************/
    PROCEDURE get_epis_pos_det_code
    (
        i_owner     IN VARCHAR2,
        i_table     IN VARCHAR2,
        i_lang      IN NUMBER,
        i_prof      IN profissional,
        i_rowtype   IN epis_positioning_det%ROWTYPE,
        o_code_list OUT table_varchar,
        o_desc_list OUT table_varchar
    );

    /************************************************************************************************************
    * Get vital sign read info: episode, patient, professional and date record
    * Used for global search.
    *
    * @param i_owner         table owner
    * @param i_table         table name
    * @param i_rowtype       table rowtype
    *
    * @return                Info of episode, patient, professional and date record
    *
    * @author                Vanessa Barsottelli
    * @version               2.6.3
    * @since                 2013/11/26
    ***********************************************************************************************************/
    FUNCTION get_vs_read_info
    (
        i_owner   IN VARCHAR2,
        i_table   IN VARCHAR2,
        i_rowtype IN vital_sign_read%ROWTYPE
    ) RETURN t_trl_trs_result;

    /************************************************************************************************************
    * Get vital sign read description
    * Used for global search.
    *
    * @param i_owner         table owner
    * @param i_table         table name
    * @param i_lang          language identifier
    * @param i_prof          professional identifier
    * @param i_rowtype       table rowtype
    * @param o_code_list     code list
    * @param o_desc_list     description list
    *
    * @return                List of code and description
    *
    * @author                Vanessa Barsottelli
    * @version               2.6.3
    * @since                 2013/11/26
    ***********************************************************************************************************/
    PROCEDURE get_vs_read_codes
    (
        i_owner     IN VARCHAR2,
        i_table     IN VARCHAR2,
        i_lang      IN NUMBER,
        i_prof      IN profissional,
        i_rowtype   IN vital_sign_read%ROWTYPE,
        o_code_list OUT table_varchar,
        o_desc_list OUT table_varchar
    );

    /************************************************************************************************************
    * Get vital sign notes info: episode, patient, professional and date record
    * Used for global search.
    *
    * @param i_owner         table owner
    * @param i_table         table name
    * @param i_rowtype       table rowtype
    *
    * @return                Info of episode, patient, professional and date record
    *
    * @author                Vanessa Barsottelli
    * @version               2.6.3
    * @since                 2013/11/26
    ***********************************************************************************************************/
    FUNCTION get_vs_notes_info
    (
        i_owner   IN VARCHAR2,
        i_table   IN VARCHAR2,
        i_rowtype IN vital_sign_notes%ROWTYPE
    ) RETURN t_trl_trs_result;

    /************************************************************************************************************
    * Get monitorization info: episode, patient, professional and date record
    * Used for global search.
    *
    * @param i_owner         table owner
    * @param i_table         table name
    * @param i_rowtype       table rowtype
    *
    * @return                Info of episode, patient, professional and date record
    *
    * @author                Vanessa Barsottelli
    * @version               2.6.3
    * @since                 2013/11/27
    ***********************************************************************************************************/
    FUNCTION get_monitorization_info
    (
        i_owner   IN VARCHAR2,
        i_table   IN VARCHAR2,
        i_rowtype IN monitorization%ROWTYPE
    ) RETURN t_trl_trs_result;

    /************************************************************************************************************
    * Get monitorization vital signs info: episode, patient, professional and date record
    * Used for global search.
    *
    * @param i_owner         table owner
    * @param i_table         table name
    * @param i_rowtype       table rowtype
    *
    * @return                Info of episode, patient, professional and date record
    *
    * @author                Vanessa Barsottelli
    * @version               2.6.3
    * @since                 2013/11/27
    ***********************************************************************************************************/
    FUNCTION get_monitorization_vs_info
    (
        i_owner   IN VARCHAR2,
        i_table   IN VARCHAR2,
        i_rowtype IN monitorization_vs%ROWTYPE
    ) RETURN t_trl_trs_result;

    /************************************************************************************************************
    * Get monitorization vital sign read description
    * Used for global search.
    *
    * @param i_owner         table owner
    * @param i_table         table name
    * @param i_lang          language identifier
    * @param i_prof          professional identifier
    * @param i_rowtype       table rowtype
    * @param o_code_list     code list
    * @param o_desc_list     description list
    *
    * @return                List of code and description
    *
    * @author                Vanessa Barsottelli
    * @version               2.6.3
    * @since                 2013/11/27
    ***********************************************************************************************************/
    PROCEDURE get_monitorization_vs_codes
    (
        i_owner     IN VARCHAR2,
        i_table     IN VARCHAR2,
        i_lang      IN NUMBER,
        i_prof      IN profissional,
        i_rowtype   IN monitorization_vs%ROWTYPE,
        o_code_list OUT table_varchar,
        o_desc_list OUT table_varchar
    );

    /************************************************************************************************************
    * Get epis hidrics info: episode, patient, professional and date record
    * Used for global search.
    *
    * @param i_owner         table owner
    * @param i_table         table name
    * @param i_rowtype       table rowtype
    *
    * @return                Info of episode, patient, professional and date record
    *
    * @author                Vanessa Barsottelli
    * @version               2.6.3
    * @since                 2013/11/29
    ***********************************************************************************************************/
    FUNCTION get_epis_hidrics_info
    (
        i_owner   IN VARCHAR2,
        i_table   IN VARCHAR2,
        i_rowtype IN epis_hidrics%ROWTYPE
    ) RETURN t_trl_trs_result;

    /************************************************************************************************************
    * Get epis hidrics description
    * Used for global search.
    *
    * @param i_owner         table owner
    * @param i_table         table name
    * @param i_lang          language identifier
    * @param i_prof          professional identifier
    * @param i_rowtype       table rowtype
    * @param o_code_list     code list
    * @param o_desc_list     description list
    *
    * @return                List of code and description
    *
    * @author                Vanessa Barsottelli
    * @version               2.6.3
    * @since                 2013/11/29
    ***********************************************************************************************************/
    PROCEDURE get_epis_hidrics_codes
    (
        i_owner     IN VARCHAR2,
        i_table     IN VARCHAR2,
        i_lang      IN NUMBER,
        i_prof      IN profissional,
        i_rowtype   IN epis_hidrics%ROWTYPE,
        o_code_list OUT table_varchar,
        o_desc_list OUT table_varchar
    );

    /************************************************************************************************************
    * Get epis hidrics details info: episode, patient, professional and date record
    * Used for global search.
    *
    * @param i_owner         table owner
    * @param i_table         table name
    * @param i_rowtype       table rowtype
    *
    * @return                Info of episode, patient, professional and date record
    *
    * @author                Vanessa Barsottelli
    * @version               2.6.3
    * @since                 2013/11/29
    ***********************************************************************************************************/
    FUNCTION get_epis_hidrics_det_info
    (
        i_owner   IN VARCHAR2,
        i_table   IN VARCHAR2,
        i_rowtype IN epis_hidrics_det%ROWTYPE
    ) RETURN t_trl_trs_result;

    /************************************************************************************************************
    * Get epis hidrics detail description
    * Used for global search.
    *
    * @param i_owner         table owner
    * @param i_table         table name
    * @param i_lang          language identifier
    * @param i_prof          professional identifier
    * @param i_rowtype       table rowtype
    * @param o_code_list     code list
    * @param o_desc_list     description list
    *
    * @return                List of code and description
    *
    * @author                Vanessa Barsottelli
    * @version               2.6.3
    * @since                 2013/11/29
    ***********************************************************************************************************/
    PROCEDURE get_epis_hidrics_det_codes
    (
        i_owner     IN VARCHAR2,
        i_table     IN VARCHAR2,
        i_lang      IN NUMBER,
        i_prof      IN profissional,
        i_rowtype   IN epis_hidrics_det%ROWTYPE,
        o_code_list OUT table_varchar,
        o_desc_list OUT table_varchar
    );

    /************************************************************************************************************
    * Get epis hidrics line info: episode, patient, professional and date record
    * Used for global search.
    *
    * @param i_owner         table owner
    * @param i_table         table name
    * @param i_rowtype       table rowtype
    *
    * @return                Info of episode, patient, professional and date record
    *
    * @author                Vanessa Barsottelli
    * @version               2.6.3
    * @since                 2013/12/02
    ***********************************************************************************************************/
    FUNCTION get_epis_hidrics_line_info
    (
        i_owner   IN VARCHAR2,
        i_table   IN VARCHAR2,
        i_rowtype IN epis_hidrics_line%ROWTYPE
    ) RETURN t_trl_trs_result;

    /************************************************************************************************************
    * Get epis hidrics line description
    * Used for global search.
    *
    * @param i_owner         table owner
    * @param i_table         table name
    * @param i_lang          language identifier
    * @param i_prof          professional identifier
    * @param i_rowtype       table rowtype
    * @param o_code_list     code list
    * @param o_desc_list     description list
    *
    * @return                List of code and description
    *
    * @author                Vanessa Barsottelli
    * @version               2.6.3
    * @since                 2013/12/02
    ***********************************************************************************************************/
    PROCEDURE get_epis_hidrics_line_codes
    (
        i_owner     IN VARCHAR2,
        i_table     IN VARCHAR2,
        i_lang      IN NUMBER,
        i_prof      IN profissional,
        i_rowtype   IN epis_hidrics_line%ROWTYPE,
        o_code_list OUT table_varchar,
        o_desc_list OUT table_varchar
    );

    /************************************************************************************************************
    * Get the corresponding progress note task type by a given progress note area
    * Used for global search.
    *
    * @param i_pn_area       Progress note area ID
    *
    * @return                Task type ID
    *
    * @author                Vanessa Barsottelli
    * @version               2.6.3
    * @since                 2014/01/06
    ***********************************************************************************************************/
    FUNCTION get_pn_task_type(i_pn_area IN pn_area.id_pn_area%TYPE) RETURN NUMBER;

    /************************************************************************************************************
    * Get epis progress notes info: episode, patient, professional, date record and task type
    * Used for global search.
    *
    * @param i_owner         table owner
    * @param i_table         table name
    * @param i_rowtype       table rowtype
    *
    * @return                Info of episode, patient, professional and date record
    *
    * @author                Vanessa Barsottelli
    * @version               2.6.3
    * @since                 2013/12/03
    ***********************************************************************************************************/
    FUNCTION get_epis_pn_info
    (
        i_owner   IN VARCHAR2,
        i_table   IN VARCHAR2,
        i_rowtype IN epis_pn%ROWTYPE
    ) RETURN t_trl_trs_result;

    /************************************************************************************************************
    * Get epis progress notes description
    * Used for global search.
    *
    * @param i_owner         table owner
    * @param i_table         table name
    * @param i_lang          language identifier
    * @param i_prof          professional identifier
    * @param i_rowtype       table rowtype
    * @param o_code_list     code list
    * @param o_desc_list     description list
    *
    * @return                List of code and description
    *
    * @author                Vanessa Barsottelli
    * @version               2.6.3
    * @since                 2013/12/03
    ***********************************************************************************************************/
    PROCEDURE get_epis_pn_codes
    (
        i_owner     IN VARCHAR2,
        i_table     IN VARCHAR2,
        i_lang      IN NUMBER,
        i_prof      IN profissional,
        i_rowtype   IN epis_pn%ROWTYPE,
        o_code_list OUT table_varchar,
        o_desc_list OUT table_varchar
    );

    /************************************************************************************************************
    * Get epis progress notes det info: episode, patient, professional, date record and task type
    * Used for global search.
    *
    * @param i_owner         table owner
    * @param i_table         table name
    * @param i_rowtype       table rowtype
    *
    * @return                Info of episode, patient, professional and date record
    *
    * @author                Vanessa Barsottelli
    * @version               2.6.3
    * @since                 2013/12/04
    ***********************************************************************************************************/
    FUNCTION get_epis_pn_det_info
    (
        i_owner   IN VARCHAR2,
        i_table   IN VARCHAR2,
        i_rowtype IN epis_pn_det%ROWTYPE
    ) RETURN t_trl_trs_result;

    /************************************************************************************************************
    * Get epis progress notes det description
    * Used for global search.
    *
    * @param i_owner         table owner
    * @param i_table         table name
    * @param i_lang          language identifier
    * @param i_prof          professional identifier
    * @param i_rowtype       table rowtype
    * @param o_code_list     code list
    * @param o_desc_list     description list
    *
    * @return                List of code and description
    *
    * @author                Vanessa Barsottelli
    * @version               2.6.3
    * @since                 2013/12/04
    ***********************************************************************************************************/
    PROCEDURE get_epis_pn_det_codes
    (
        i_owner     IN VARCHAR2,
        i_table     IN VARCHAR2,
        i_lang      IN NUMBER,
        i_prof      IN profissional,
        i_rowtype   IN epis_pn_det%ROWTYPE,
        o_code_list OUT table_varchar,
        o_desc_list OUT table_varchar
    );

    /************************************************************************************************************
    * Get epis progress notes det task info: episode, patient, professional, date record and task type
    * Used for global search.
    *
    * @param i_owner         table owner
    * @param i_table         table name
    * @param i_rowtype       table rowtype
    *
    * @return                Info of episode, patient, professional and date record
    *
    * @author                Vanessa Barsottelli
    * @version               2.6.3
    * @since                 2013/12/05
    ***********************************************************************************************************/
    FUNCTION get_epis_pn_det_task_info
    (
        i_owner   IN VARCHAR2,
        i_table   IN VARCHAR2,
        i_rowtype IN epis_pn_det_task%ROWTYPE
    ) RETURN t_trl_trs_result;

    /************************************************************************************************************
    * Get epis progress notes det task description
    * Used for global search.
    *
    * @param i_owner         table owner
    * @param i_table         table name
    * @param i_lang          language identifier
    * @param i_prof          professional identifier
    * @param i_rowtype       table rowtype
    * @param o_code_list     code list
    * @param o_desc_list     description list
    *
    * @return                List of code and description
    *
    * @author                Vanessa Barsottelli
    * @version               2.6.3
    * @since                 2013/12/05
    ***********************************************************************************************************/
    PROCEDURE get_epis_pn_det_task_codes
    (
        i_owner     IN VARCHAR2,
        i_table     IN VARCHAR2,
        i_lang      IN NUMBER,
        i_prof      IN profissional,
        i_rowtype   IN epis_pn_det_task%ROWTYPE,
        o_code_list OUT table_varchar,
        o_desc_list OUT table_varchar
    );

    /************************************************************************************************************
    * Get epis progress notes addendum info: episode, patient, professional, date record and task type
    * Used for global search.
    *
    * @param i_owner         table owner
    * @param i_table         table name
    * @param i_rowtype       table rowtype
    *
    * @return                Info of episode, patient, professional and date record
    *
    * @author                Vanessa Barsottelli
    * @version               2.6.3
    * @since                 2013/12/04
    ***********************************************************************************************************/
    FUNCTION get_epis_pn_addendum_info
    (
        i_owner   IN VARCHAR2,
        i_table   IN VARCHAR2,
        i_rowtype IN epis_pn_addendum%ROWTYPE
    ) RETURN t_trl_trs_result;

    /************************************************************************************************************
    * Get epis progress notes addendum description
    * Used for global search.
    *
    * @param i_owner         table owner
    * @param i_table         table name
    * @param i_lang          language identifier
    * @param i_prof          professional identifier
    * @param i_rowtype       table rowtype
    * @param o_code_list     code list
    * @param o_desc_list     description list
    *
    * @return                List of code and description
    *
    * @author                Vanessa Barsottelli
    * @version               2.6.3
    * @since                 2013/12/04
    ***********************************************************************************************************/
    PROCEDURE get_epis_pn_addendum_codes
    (
        i_owner     IN VARCHAR2,
        i_table     IN VARCHAR2,
        i_lang      IN NUMBER,
        i_prof      IN profissional,
        i_rowtype   IN epis_pn_addendum%ROWTYPE,
        o_code_list OUT table_varchar,
        o_desc_list OUT table_varchar
    );

    /************************************************************************************************************
    * Get epis progress notes signoff info: episode, patient, professional, date record and task type
    * Used for global search.
    *
    * @param i_owner         table owner
    * @param i_table         table name
    * @param i_rowtype       table rowtype
    *
    * @return                Info of episode, patient, professional and date record
    *
    * @author                Vanessa Barsottelli
    * @version               2.6.3
    * @since                 2013/12/05
    ***********************************************************************************************************/
    FUNCTION get_epis_pn_signoff_info
    (
        i_owner   IN VARCHAR2,
        i_table   IN VARCHAR2,
        i_rowtype IN epis_pn_signoff%ROWTYPE
    ) RETURN t_trl_trs_result;

    /************************************************************************************************************
    * Get epis progress notes signoff description
    * Used for global search.
    *
    * @param i_owner         table owner
    * @param i_table         table name
    * @param i_lang          language identifier
    * @param i_prof          professional identifier
    * @param i_rowtype       table rowtype
    * @param o_code_list     code list
    * @param o_desc_list     description list
    *
    * @return                List of code and description
    *
    * @author                Vanessa Barsottelli
    * @version               2.6.3
    * @since                 2013/12/05
    ***********************************************************************************************************/
    PROCEDURE get_epis_pn_signoff_codes
    (
        i_owner     IN VARCHAR2,
        i_table     IN VARCHAR2,
        i_lang      IN NUMBER,
        i_prof      IN profissional,
        i_rowtype   IN epis_pn_signoff%ROWTYPE,
        o_code_list OUT table_varchar,
        o_desc_list OUT table_varchar
    );

    --
    g_vital_sign_active    CONSTANT VARCHAR2(1 CHAR) := 'A';
    g_vital_sign_cancelled CONSTANT VARCHAR2(1 CHAR) := 'C';

    g_monitor_cancelled   CONSTANT VARCHAR2(1 CHAR) := 'C';
    g_monitor_co_sign_yes CONSTANT VARCHAR2(1 CHAR) := 'Y';

    g_hidrics_cancelled   CONSTANT VARCHAR2(1 CHAR) := 'C';
    g_hidrics_interrupted CONSTANT VARCHAR2(1 CHAR) := 'I';

    g_pn_cancelled  CONSTANT VARCHAR2(1 CHAR) := 'C';
    g_pn_signed_off CONSTANT VARCHAR2(1 CHAR) := 'S';
    g_pn_migrated   CONSTANT VARCHAR2(1 CHAR) := 'M';
    g_pn_temporary  CONSTANT VARCHAR2(1 CHAR) := 'T';

    g_addendum_draft      CONSTANT VARCHAR2(1 CHAR) := 'D';
    g_addendum_finalized  CONSTANT VARCHAR2(1 CHAR) := 'F';
    g_addendum_cancelled  CONSTANT VARCHAR2(1 CHAR) := 'C';
    g_addendum_signed_off CONSTANT VARCHAR2(1 CHAR) := 'S';

END pk_inp_global_search;
/
