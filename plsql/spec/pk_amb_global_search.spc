/*-- Last Change Revision: $Rev: 1850754 $*/
/*-- Last Change by: $Author: ana.matos $*/
/*-- Date of last change: $Date: 2018-07-05 15:20:59 +0100 (qui, 05 jul 2018) $*/

CREATE OR REPLACE PACKAGE pk_amb_global_search AS

    -- Author  : JOEL.LOPES
    -- Created : 11/29/2013 10:50:50 AM
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
    * @author                Joel Lopes
    * @version               2.6.3
    * @since                 2013/11/29
    ***********************************************************************************************************/
    FUNCTION get_tbl_col_info_rec_cons_req
    (
        i_owner   IN VARCHAR2,
        i_table   IN VARCHAR2,
        i_rowtype IN consult_req%ROWTYPE
    ) RETURN t_trl_trs_result;

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
    * @author                Joel Lopes
    * @version               2.6.3
    * @since                 2013/11/29
    ***********************************************************************************************************/

    FUNCTION get_tbl_col_inf_cons_req_prof
    (
        i_owner   IN VARCHAR2,
        i_table   IN VARCHAR2,
        i_rowtype IN consult_req_prof%ROWTYPE
    ) RETURN t_trl_trs_result;

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
    * @author                Joel Lopes
    * @version               2.6.3
    * @since                 2013/12/03
    ***********************************************************************************************************/

    FUNCTION get_tbl_col_info_rec_diet_req
    (
        i_owner   IN VARCHAR2,
        i_table   IN VARCHAR2,
        i_rowtype IN epis_diet_req%ROWTYPE
    ) RETURN t_trl_trs_result;

    /************************************************************************************************************
    * Get diet type description 
    * Used for global search.
    *
    * @param i_owner         table owner
    * @param i_table         table name
    * @param i_lang          language identifier
    * @param i_rowtype       table rowtype
    * @param o_code_list     code list
    * @param o_desc_list     description list
    *
    * @return                List of code and description
    *
    * @author                Joel Lopes
    * @version               2.6.3
    * @since                 2013/12/03
    ***********************************************************************************************************/
    PROCEDURE get_tbl_col_codes_diet_req
    (
        i_owner     IN VARCHAR2,
        i_table     IN VARCHAR2,
        i_lang      IN NUMBER,
        i_prof      IN profissional,
        i_rowtype   IN epis_diet_req%ROWTYPE,
        o_code_list OUT table_varchar,
        o_desc_list OUT table_varchar
    );

    /************************************************************************************************************
    * Get epis positioning info: episode, patient, professional and date record
    * Used for global search.
    *
    * @param i_owner         table owner
    * @param i_table         table name
    * @param i_rowtype       table rowtype
    *
    * @return                Info of diet, patient, professional and date record
    *
    * @author                Joel Lopes
    * @version               2.6.3
    * @since                 2013/12/04
    ***********************************************************************************************************/

    FUNCTION get_tbl_col_info_diet_det
    (
        i_owner   IN VARCHAR2,
        i_table   IN VARCHAR2,
        i_rowtype IN epis_diet_det%ROWTYPE
    ) RETURN t_trl_trs_result;

    /************************************************************************************************************
    * Get diet type description 
    * Used for global search.
    *
    * @param i_owner         table owner
    * @param i_table         table name
    * @param i_lang          language identifier
    * @param i_rowtype       table rowtype
    * @param o_code_list     code list
    * @param o_desc_list     description list
    *
    * @return                List of code and description
    *
    * @author                Joel Lopes
    * @version               2.6.3
    * @since                 2013/12/04
    ***********************************************************************************************************/
    PROCEDURE get_tbl_col_codes_diet_det
    (
        i_owner     IN VARCHAR2,
        i_table     IN VARCHAR2,
        i_lang      IN NUMBER,
        i_prof      IN profissional,
        i_rowtype   IN epis_diet_det%ROWTYPE,
        o_code_list OUT table_varchar,
        o_desc_list OUT table_varchar
    );

    /**
    * Get task description.
    * Used for the global search.
    *
    * @param i_owner         Table owner
    * @param i_table         table
    * @param i_rowtype       rowtype    
    *
    * @return               episode and patient
    *
    * @author                         Joel Lopes
    * @version                        2.6.3.8.5.1
    * @since                          27/11/2013
    */

    FUNCTION get_tbl_col_info_rec_problems
    (
        i_owner   IN VARCHAR2,
        i_table   IN VARCHAR2,
        i_rowtype IN pat_history_diagnosis%ROWTYPE
    ) RETURN t_trl_trs_result;

    PROCEDURE get_tbl_col_info_codes_prob
    (
        i_owner     IN VARCHAR2,
        i_table     IN VARCHAR2,
        i_lang      IN NUMBER,
        i_prof      IN profissional,
        i_rowtype   IN pat_history_diagnosis%ROWTYPE,
        o_code_list OUT table_varchar,
        o_desc_list OUT table_varchar
    );

END pk_amb_global_search;
/
