/*-- Last Change Revision: $Rev: 2028613 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:46:54 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_dmgr_hist IS

    /********************************************************************************************
    * This function inserts a new row in the PAT_DMGR_HIST table
    *
    * @param i_patient_code   Patient ID number
    * @param i_lang   ID of the language used by the professional
    * @param i_prof   professional ID + institution ID + software version
    * @param o_error   error description
    *
    *
    * @return                TRUE on success; FALSE otherwise
    *
    *
    * @author                Rui Abreu
    * @since                 2007/03/22
       ********************************************************************************************/

    FUNCTION create_dmgr_hist
    (
        i_data  IN pat_dmgr_hist%ROWTYPE,
        i_lang  IN LANGUAGE.id_language%TYPE,
        i_prof  IN profissional,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * This function computes the history of all the changes ever done to a patients demographic data
    *
    * @param i_patient_code   Patient ID number
    * @param i_lang   ID of the language used by the professional
    * @param i_prof   professional ID + institution ID + software version
    * @param o_new_info   All the new information added
    * @param o_old_info   All the outdated information
    * @param o_doc_info   The name of the doctor who performed the modification
    * @param o_date_info   modification date and hour
    * @param o_error   error description
    *
    *
    * @return                TRUE on success; FALSE otherwise
    *
    *
    * @author                Rui Abreu
    * @since                 2007/03/22
       ********************************************************************************************/

    FUNCTION get_dmgr_hist
    (
        i_patient_code IN NUMBER,
        i_lang         IN LANGUAGE.id_language%TYPE,
        i_prof         IN profissional,
        o_new_info     OUT table_varchar,
        o_old_info     OUT table_varchar,
        o_doc_info     OUT table_varchar,
        o_date_info    OUT table_varchar,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

END pk_dmgr_hist;
/
