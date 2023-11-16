/*-- Last Change Revision: $Rev: 2044948 $*/
/*-- Last Change by: $Author: elisabete.bugalho $*/
/*-- Date of last change: $Date: 2022-09-07 15:57:20 +0100 (qua, 07 set 2022) $*/

CREATE OR REPLACE PACKAGE pk_ea_vital_signs IS

    -- Author  : THIAGO.BRITO
    -- Created : 17-09-2008 17:04:59
    -- Purpose : The purpose of this new package is to keep the EasyAccess table VITAL_SIGNS_EA updated

    -- Public function and procedure declarations

    /**********************************************************************************************
    * This procedure has the business logic for the management of the VITAL_SIGNS_EA table.
    *
    * @param         i_lang                   language id
    * @param         i_prof                   profissional type
    * @param         i_event_type             type of the event (insert | update | delete)
    * @param         i_rowids                 list of the affected rowids 
    * @param         i_source_table_name      source table name
    * @param         i_list_columns           list of the affected columns
    * @param         i_dg_table_name          easy access table name
    *
    * @author        Thiago Brito
    * @since         2008-09-17
    **********************************************************************************************/
    PROCEDURE set_vital_signs_ea
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_event_type        IN VARCHAR2,
        i_rowids            IN table_varchar,
        i_source_table_name IN VARCHAR2,
        i_list_columns      IN table_varchar,
        i_dg_table_name     IN VARCHAR2
    );

    --

    /**********************************************************************************************
    * This procedure correct all duplicated collumns in table VITAL_SIGNS_EA
    *
    * @author        Luís Maia
    * @version       2.5.1
    * @since         16-Nov-2011
    **********************************************************************************************/
    PROCEDURE set_pat_rebuild_ea_tbls;

    --

    /**********************************************************************************************
    * Populates Vital Signs by Patient Easy Access table
    *
    * @param        i_tmp_patient_id         Temporary patient id
    * @param        i_real_patient_id        Real patient id
    *
    * @return       TRUE if sucess, FALSE otherwise
    *
    * @author       Luís Maia
    * @version      2.5.1
    * @since        16-Nov-2011
    **********************************************************************************************/
    PROCEDURE merge_vs_patient
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional,
        
        i_tmp_patient_id  IN vital_sign_read.id_patient%TYPE,
        i_real_patient_id IN vital_sign_read.id_patient%TYPE,
        o_rows_out        OUT table_varchar
    );

    --

    /**********************************************************************************************
    * Populates Vital Signs by Patient Easy Access table
    *
    * @param        i_tmp_episode_id         Temporary episode id
    * @param        i_tmp_patient_id         Temporary patient id
    * @param        i_real_episode_id        Real episode id
    * @param        i_real_patient_id        Real patient id
    *
    * @return       TRUE if sucess, FALSE otherwise
    *
    * @author       Luís Maia
    * @version      2.5.1
    * @since        16-Nov-2011
    **********************************************************************************************/
    PROCEDURE merge_vs_episode
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_tmp_episode_id  IN vital_sign_read.id_episode%TYPE,
        i_tmp_patient_id  IN vital_sign_read.id_patient%TYPE,
        i_real_episode_id IN vital_sign_read.id_episode%TYPE,
        i_real_patient_id IN vital_sign_read.id_patient%TYPE,
        o_rows_vsr_out    OUT table_varchar
    );

/* This procedure correct all duplicated collumns in table VITAL_SIGNS_EA for a specific patient-*/

    PROCEDURE set_pat_rebuild_ea_tbls_patient(i_patient IN vital_sign_read.id_patient%TYPE);
END pk_ea_vital_signs;
/
