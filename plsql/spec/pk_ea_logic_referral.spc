/*-- Last Change Revision: $Rev: 2028649 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:47:06 +0100 (ter, 02 ago 2022) $*/
CREATE OR REPLACE PACKAGE pk_ea_logic_referral IS

    -- Author  : Joao Sa
    -- Created : 26-09-2008
    -- Purpose : Easy access logic for REFERRAL

    /**
    * Updates for p1_external_request
    * Esta funcao trata as seguintes colunas de REFERRAL_EA:
    *
    * ID_EXTERNAL_REQUEST
    * ID_PATIENT
    * NUM_REQ
    * FLG_TYPE
    * FLG_STATUS
    * ID_PROF_STATUS
    * DT_STATUS
    * FLG_PRIORITY
    * FLG_HOME
    * ID_SPECIALITY
    * DECISION_URG_LEVEL
    * ID_INST_ORIG
    * ID_INST_DEST
    * ID_DEP_CLIN_SERV
    * ID_PROF_REQUESTED
    * DT_REQUESTED
    * ID_SCHEDULE
    * ID_PROF_SCHEDULE (Estado S - Profissional do agendamento)
    * DT_SCHEDULE
    *
    * @param i_lang               Language.
    * @param i_prof               Logged professional.
    * @param i_event_type         Type of event (UPDATE, INSERT, etc)
    * @param i_rowids             List of ROWIDs belonging to the changed records.
    * @param i_list_columns       List of columns that were changed
    * @param i_source_table_name  Name of the table that was changed.
    * @param i_dg_table_name      Name of the Data Governance table.
    *
    * @author Joao Sa
    * @version 2.4.3-Denormalized
    * @since 2008/09/26
    */
    PROCEDURE set_external_request
    (
        i_lang              IN LANGUAGE.id_language%TYPE,
        i_prof              IN profissional,
        i_event_type        IN VARCHAR2,
        i_rowids            IN table_varchar,
        i_source_table_name IN VARCHAR2,
        i_list_columns      IN table_varchar,
        i_dg_table_name     IN VARCHAR
    );

    /**
    * Updates for p1_tracking
    * Esta funcao trata as seguintes colunas de REFERRAL_EA:
    *
    * ID_PROF_REDIRECTED
    * DT_NEW
    * DT_ISSUED
    * ID_PROF_TRIAGE
    * DT_TRIAGE
    * DT_FORWARDED
    * ID_PROF_SCHEDULE (Estado A)
    * DT_EFECTIV
    * DT_ACKNOWLEDGE
    *
    * @param i_lang               Language.
    * @param i_prof               Logged professional.
    * @param i_event_type         Type of event (UPDATE, INSERT, etc)
    * @param i_rowids             List of ROWIDs belonging to the changed records.
    * @param i_list_columns       List of columns that were changed
    * @param i_source_table_name  Name of the table that was changed.
    * @param i_dg_table_name      Name of the Data Governance table.
    *
    * @author Joao Sa
    * @version 2.4.3-Denormalized
    * @since 2008/09/26
    */
    PROCEDURE set_tracking
    (
        i_lang              IN LANGUAGE.id_language%TYPE,
        i_prof              IN profissional,
        i_event_type        IN VARCHAR2,
        i_rowids            IN table_varchar,
        i_source_table_name IN VARCHAR2,
        i_list_columns      IN table_varchar,
        i_dg_table_name     IN VARCHAR
    );

    /**
    * Updates for p1_match
    * Esta funcao trata as seguintes colunas de REFERRAL_EA:
    *
    * ID_MATCH
    *
    * @param i_lang               Language.
    * @param i_prof               Logged professional.
    * @param i_event_type         Type of event (UPDATE, INSERT, etc)
    * @param i_rowids             List of ROWIDs belonging to the changed records.
    * @param i_list_columns       List of columns that were changed
    * @param i_source_table_name  Name of the table that was changed.
    * @param i_dg_table_name      Name of the Data Governance table.
    *
    * @author Joao Sa
    * @version 2.4.3-Denormalized
    * @since 2008/09/26
    */
    PROCEDURE set_match
    (
        i_lang              IN LANGUAGE.id_language%TYPE,
        i_prof              IN profissional,
        i_event_type        IN VARCHAR2,
        i_rowids            IN table_varchar,
        i_source_table_name IN VARCHAR2,
        i_list_columns      IN table_varchar,
        i_dg_table_name     IN VARCHAR
    );

    /**
    * Updates for ref_orig_data
    * Esta funcao trata as seguintes colunas de REFERRAL_EA:
    *
    * ID_MATCH
    *
    * @param i_lang               Language.
    * @param i_prof               Logged professional.
    * @param i_event_type         Type of event (UPDATE, INSERT, etc)
    * @param i_rowids             List of ROWIDs belonging to the changed records.
    * @param i_list_columns       List of columns that were changed
    * @param i_source_table_name  Name of the table that was changed.
    * @param i_dg_table_name      Name of the Data Governance table.
    *
    * @author Joana Barroso
    * @version 2.5.0.7
    * @since 2010/01/19
    */

    PROCEDURE set_ref_orig_data
    (
        i_lang              IN LANGUAGE.id_language%TYPE,
        i_prof              IN profissional,
        i_event_type        IN VARCHAR2,
        i_rowids            IN table_varchar,
        i_source_table_name IN VARCHAR2,
        i_list_columns      IN table_varchar,
        i_dg_table_name     IN VARCHAR
    );

    /**
    * Updates for DOC_EXTERNAL
    * Esta funcao trata as seguintes colunas de REFERRAL_EA:
    *
    * NR_CLINICAL_DOC
    *
    * @param i_lang               Language.
    * @param i_prof               Logged professional.
    * @param i_event_type         Type of event (UPDATE, INSERT, etc)
    * @param i_rowids             List of ROWIDs belonging to the changed records.
    * @param i_list_columns       List of columns that were changed
    * @param i_source_table_name  Name of the table that was changed.
    * @param i_dg_table_name      Name of the Data Governance table.
    *
    * @author Joana Barroso
    * @version 2.6.1.20
    * @since 2013/07/10
    */

    PROCEDURE set_doc_external
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_event_type        IN VARCHAR2,
        i_rowids            IN table_varchar,
        i_source_table_name IN VARCHAR2,
        i_list_columns      IN table_varchar,
        i_dg_table_name     IN VARCHAR
    );

    /**
    * Updates for REF_COMMENTS
    * Esta funcao trata as seguintes colunas de REFERRAL_EA:
    *
    * nr_clin_comments
    * nr_adm_comments
    *
    * @param i_lang               Language.
    * @param i_prof               Logged professional.
    * @param i_event_type         Type of event (UPDATE, INSERT, etc)
    * @param i_rowids             List of ROWIDs belonging to the changed records.
    * @param i_list_columns       List of columns that were changed
    * @param i_source_table_name  Name of the table that was changed.
    * @param i_dg_table_name      Name of the Data Governance table.
    *
    * @author Joana Barroso
    * @version 2.6.1.21
    * @since 2013/07/10
    */

    PROCEDURE set_ref_comments
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_event_type        IN VARCHAR2,
        i_rowids            IN table_varchar,
        i_source_table_name IN VARCHAR2,
        i_list_columns      IN table_varchar,
        i_dg_table_name     IN VARCHAR
    );

    /**
    * Updates for REF_COMMENTS_READ
    * This function updates the following columns of REFERRAL_EA table:
    *
    * flg_clin_comm_read
    * flg_adm_comm_read
    *
    * @param i_lang               Language.
    * @param i_prof               Logged professional.
    * @param i_event_type         Type of event (UPDATE, INSERT, etc)
    * @param i_rowids             List of ROWIDs belonging to the changed records.
    * @param i_list_columns       List of columns that were changed
    * @param i_source_table_name  Name of the table that was changed.
    * @param i_dg_table_name      Name of the Data Governance table.
    *
    * @author  Ana Monteiro
    * @version 1.0
    * @since   24-01-2014
    */
    PROCEDURE set_ref_comments_read
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_event_type        IN VARCHAR2,
        i_rowids            IN table_varchar,
        i_source_table_name IN VARCHAR2,
        i_list_columns      IN table_varchar,
        i_dg_table_name     IN VARCHAR
    );

    /**
    * Updates for flg_status of p1_external_request
    * Esta funcao trata as seguintes colunas de REFERRAL_EA:
    *
    * STS_PROF_RESP
    * STS_ORIG_PHY
    * STS_ORIG_REG
    * STS_DEST_REG
    * STS_DEST_PHY_TE
    * STS_DEST_PHY_T
    * STS_DEST_PHY_MC
    * STS_ORIG_DC
    * STS_ORIG_DEFAULT
    * STS_DEST_DEFAULT
    *
    * @param i_lang               Language.
    * @param i_prof               Logged professional.
    * @param i_event_type         Type of event (UPDATE, INSERT, etc)
    * @param i_rowids             List of ROWIDs belonging to the changed records.
    * @param i_list_columns       List of columns that were changed
    * @param i_source_table_name  Name of the table that was changed.
    * @param i_dg_table_name      Name of the Data Governance table.
    *
    * @author  Ana Monteiro
    * @version 1.0
    * @since   09-04-2013
    */
    PROCEDURE set_exr_flg_status
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_event_type        IN VARCHAR2,
        i_rowids            IN table_varchar,
        i_source_table_name IN VARCHAR2,
        i_list_columns      IN table_varchar,
        i_dg_table_name     IN VARCHAR
    );

    /*******************************************************************************************************************************************
    * Name:                           set_tl_referral
    * Description:                    Function that updates patient Referrals information in the Easy Access table (task_timeline_ea)
    *
    * @param I_LANG                   Language ID
    * @param I_PROF                   Professional information Vector: (professional ID, institution ID, software ID)
    * @param I_EVENT_TYPE             Type of event (UPDATE, INSERT, etc)
    * @param I_ROWIDS                 List of ROWIDs belonging to the changed records.
    * @param I_LIST_COLUMNS           List of columns that were changed
    * @param I_SOURCE_TABLE_NAME      Name of the table that was changed.
    * @param I_DG_TABLE_NAME          Name of the Data Governance table.
    *
    * @value I_LANG                   {*} '1' PT {*} '2' EN {*} '3' ES {*} '4' NL {*} '5' IT {*} '6' FR {*} '11' PT-BR
    * @value I_EVENT_TYPE             {*} t_data_gov_mnt.g_event_insert {*} t_data_gov_mnt.g_event_update {*} t_data_gov_mnt.g_event_delete
    *
    * @return                         Return FALSE if an error occours, otherwise return TRUE
    * @raises                         PL/SQL generic erro "OTHERS"
    *
    * @author                         Elisabete Bugalho
    * @version                        2.7.1.1
    * @since                          14/06/2017
    *******************************************************************************************************************************************/
    PROCEDURE set_tl_referral
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_event_type        IN VARCHAR2,
        i_rowids            IN table_varchar,
        i_source_table_name IN VARCHAR2,
        i_list_columns      IN table_varchar,
        i_dg_table_name     IN VARCHAR
    );

    ---------------------------------------- GLOBAL VALUES ----------------------------------------------
    /* Package name */
    g_package_name VARCHAR2(30);

    /* Error tracking */
    g_error VARCHAR2(4000);
    /* Invalid event type */
    g_excp_invalid_event_type EXCEPTION;

END pk_ea_logic_referral;
/
