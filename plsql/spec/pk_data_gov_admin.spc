/*-- Last Change Revision: $Rev: 2028589 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:46:42 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_data_gov_admin IS

    g_ret BOOLEAN;

    FUNCTION get_yes RETURN VARCHAR2;
    FUNCTION get_no RETURN VARCHAR2;

    FUNCTION get_inst RETURN NUMBER;

    PROCEDURE set_inst(i_inst IN NUMBER);

    FUNCTION get_prof(i_inst IN NUMBER DEFAULT NULL) RETURN profissional;

    FUNCTION get_commit_limit RETURN NUMBER;

    PROCEDURE set_commit_limit(i_commit_step IN NUMBER);

    PROCEDURE create_missing_epis_info;

    PROCEDURE clean_err00_tables;

    /**
    * This package contains methods that allow for the verification and recreation of the data in data governance tables.
    * This methods must all be declared in the package spec and respect the same signature and name pattern so they can be
      called from the admin_all_datagov_tables method.
    * The pattern for this methods' name is admin_##_* where ## stands for any number with two algarisms and * stands for any string.
      ## will set the order in which the method must run.
    * The signature must be like this:
        i_patient                IN NUMBER DEFAULT NULL,
        i_episode                IN NUMBER DEFAULT NULL,
        i_schedule               IN NUMBER DEFAULT NULL,
        i_external_request       IN NUMBER DEFAULT NULL,
        i_institution            IN NUMBER DEFAULT NULL,
        i_start_dt               IN TIMESTAMP WITH TIME ZONE DEFAULT NULL,
        i_end_dt                 IN TIMESTAMP WITH TIME ZONE DEFAULT NULL,
        i_validate_table         IN BOOLEAN DEFAULT TRUE,
        i_output_invalid_records IN BOOLEAN DEFAULT FALSE,
        i_recreate_table         IN BOOLEAN DEFAULT FALSE,
           i_commit_step            IN NUMBER DEFAULT 1000
    **/

    /**
    * Actualize Easy Access table TASK_TIMELINE_EA with all EPISODE related tasks
    *
    * @param i_patient                Patient identifier
    * @param i_episode                Episode identifier
    * @value i_schedule               Shcedule identifier
    * @param i_external_request       P1 (referral) identifier
    * @param i_institution            Institution identifier
    * @param i_start_dt               Start date to be consider to the validation/reconstruction of data
    * @param i_end_dt                 End date to be consider to the validation/reconstruction of data
    * @param i_validate_table         Indicates necessary to validate data existent in easy access table
    * @param i_output_invalid_records Show final (resumed) information about updated statistics
    * @param i_recreate_table         Indicates necessary to rebuild data existent in easy access table
    * @param i_commit_step            Number of registries between commit's
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  Luís Maia
    * @version  2.5.0.7.6
    * @since    2009/12/23
    */
    FUNCTION admin_epi_task_tl_tables
    (
        i_patient                IN NUMBER DEFAULT NULL,
        i_episode                IN NUMBER DEFAULT NULL,
        i_schedule               IN NUMBER DEFAULT NULL,
        i_external_request       IN NUMBER DEFAULT NULL,
        i_institution            IN NUMBER DEFAULT NULL,
        i_start_dt               IN TIMESTAMP WITH TIME ZONE DEFAULT NULL,
        i_end_dt                 IN TIMESTAMP WITH TIME ZONE DEFAULT NULL,
        i_validate_table         IN BOOLEAN DEFAULT TRUE,
        i_output_invalid_records IN BOOLEAN DEFAULT FALSE,
        i_recreate_table         IN BOOLEAN DEFAULT FALSE,
        i_commit_step            IN NUMBER DEFAULT pk_data_gov_admin.get_commit_limit
    ) RETURN BOOLEAN;

    /**
    * Data migration for updating patient column in episode table
    *
    * @author  Rui Spratley
    * @version 2.4.3d
    * @since   20/10/2008
    */
    PROCEDURE admin_00_update_pat_in_episode;

    /**
    * Actualiza as novas colunas da EPISODE, criadas devido ?desnormalização da BO
    *
    * @author   Rui Batista
    * @version 2.4.3d
    * @since    2008/10/16
    */
    PROCEDURE admin_01_episode;

    /**
    * Data migration for updating episode column in tables with patient
    *
    * @author  Rui Spratley
    * @version 2.4.3d
    * @since   20/10/2008
    */
    PROCEDURE admin_02_update_episode;

    /**
    * Data migration for updating patient column in tables with episode
    *
    * @author  Rui Spratley
    * @version 2.4.3d
    * @since   20/10/2008
    */
    PROCEDURE admin_03_update_patient;

    /**
    * Actualiza a Easy Access VIEWER_EHR_EA
    *
    * @param i_inst                Institution id
    *
    * @author   João Ribeiro
    * @version  2.4.3d
    * @since    2009/02/06
    */
    PROCEDURE admin_98_viewer_ehr_ea(i_inst IN NUMBER DEFAULT 0);

    /**
    * Popular a tabela de Awareness
    *
    * @author   Teresa Coutinho
    * @version  2.4.3d
    * @since    2008/10/17
    */
    FUNCTION get_decode_val(i_val_field IN NUMBER) RETURN VARCHAR2;

    PROCEDURE admin_99_awareness;

    /**
    * Migração de dados para a tabela icnp_epis_diagnosis
    * id_visit, id_epis_type, flg_executions e id_patient
    *
    * @author  Joana Barroso
    * @version 2.4.3d
    * @since   14/10/2008
    */
    PROCEDURE admin_50_icnp_epis_diagnosis;

    /**
    * Migração de dados VISIT.ID_VISIT e PATIENT.ID_PATIENT para a tabela NURSE_TEA_REQ
    *
    * @author  Luís Maia
    * @version 2.4.3d
    * @since   15/10/2008
    */
    PROCEDURE admin_50_nurse_tea_req;

    /**
    * Migration script for EXAMS_EA
    *
    * @author  João Ribeiro
    * @version 2.4.3d
    * @since   16/10/2008
    */
    PROCEDURE admin_50_exams_ea;

    /**
    * Migration script for LAB_TESTS_EA
    *
    * @author  João Ribeiro
    * @version 2.4.3d
    * @since   16/10/2008
    */
    PROCEDURE admin_50_lab_tests_ea;

    /**
    * Migration script for INTERV_ICNP_EA
    *
    * @author  João Ribeiro
    * @version 2.4.3d
    * @since   17/10/2008
    */
    PROCEDURE admin_50_interv_icnp_ea;

    /**
    * Migration script for PROCEDURES_EA
    *
    * @author  João Ribeiro
    * @version 2.4.3d
    * @since   17/10/2008
    */
    PROCEDURE admin_50_procedures_ea;

    /**
    * Migracao de dados para a tabela referral_ea
    *
    * @author  Ana Monteiro
    * @version 2.4.3d
    * @since   15/10/2008
    */
    PROCEDURE admin_50_referral_ea;

    /**
    * Data migration for monitorizations_ea table
    *
    * @author  Rui Spratley
    * @version 2.4.3d
    * @since   20/10/2008
    */
    PROCEDURE admin_50_monitorizations_ea;

    /**
    * Data migration for vital signs easy access tables
    *
    * @author  Paulo Fonseca
    * @version 2.5.1
    * @since   10/12/2010
    */
    PROCEDURE admin_50_vs_ea_tbls;

    /**
    * This function is supposed to be used in order to update the
    * OPINION table regarding the migration issue from 2.4.3/4 Version.
    *
    * @author  Thiago Brito
    * @version 2.4.3d
    * @since   2008-Oct-21
    */
    PROCEDURE admin_50_update_opinion;

    /**
    * This function is supposed to be used in order to update the
    * CONSULT_REQ table regarding the migration issue from 2.4.3/4 Version.
    *
    * @author  Thiago Brito
    * @version 2.4.3d
    * @since   2008-Oct-21
    */
    PROCEDURE admin_50_update_consult_req;

    /**
    * This function is supposed to be used in order to update the
    * NURSE_TEA_REQ table regarding the migration issue from 2.4.3/4 Version.
    *
    * @author  Thiago Brito
    * @version  2.4.3d
    * @since   2008-Oct-21
    */
    PROCEDURE admin_50_update_nurse_tea_req;

    /**
    * Actualiza a Easy Access Tracking_Board_EA
    *
    * @author   Ariel Machado
    * @version  2.4.3d
    * @since    2008/10/20
    */
    PROCEDURE admin_50_tracking_board_ea;

    /**
    * Actualize Easy Access table TASK_TIMELINE_EA with past history encoded records
    *
    * @param i_patient                Patient identifier
    * @param i_episode                Episode identifier
    * @value i_schedule               Shcedule identifier
    * @param i_external_request       P1 (referral) identifier
    * @param i_institution            Institution identifier
    * @param i_start_dt               Start date to be consider to the validation/reconstruction of data
    * @param i_end_dt                 End date to be consider to the validation/reconstruction of data
    * @param i_validate_table         Indicates necessary to validate data existent in easy access table
    * @param i_output_invalid_records Show final (resumed) information about updated statistics
    * @param i_recreate_table         Indicates necessary to rebuild data existent in easy access table
    * @param i_commit_step            Number of registries between commit's
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    *
    * @author   Sofia Mendes
    * @version  2.6.1.2
    * @since    22-Sep-2011
    */
    FUNCTION admin_task_tl_past_hist_ea
    (
        i_patient                IN NUMBER DEFAULT NULL,
        i_episode                IN NUMBER DEFAULT NULL,
        i_schedule               IN NUMBER DEFAULT NULL,
        i_external_request       IN NUMBER DEFAULT NULL,
        i_institution            IN NUMBER DEFAULT NULL,
        i_start_dt               IN TIMESTAMP WITH TIME ZONE DEFAULT NULL,
        i_end_dt                 IN TIMESTAMP WITH TIME ZONE DEFAULT NULL,
        i_validate_table         IN BOOLEAN DEFAULT TRUE,
        i_output_invalid_records IN BOOLEAN DEFAULT FALSE,
        i_recreate_table         IN BOOLEAN DEFAULT FALSE,
        i_commit_step            IN NUMBER DEFAULT pk_data_gov_admin.get_commit_limit
    ) RETURN BOOLEAN;

    /**
    * Migration script for TASK_TIMELINE_EA (with analysis tasks)
    *
    * @author   Luís Maia
    * @version  2.5.0.2
    * @since    2009/04/11
    */
    PROCEDURE admin_task_tl_analysis_ea(i_episode IN NUMBER DEFAULT NULL);

    /**
    * Migration script for TASK_TIMELINE_EA (with exams tasks)
    *
    * @author   Luís Maia
    * @version  2.5.0.2
    * @since    2009/04/20
    */
    PROCEDURE admin_task_tl_exams_ea(i_episode IN NUMBER DEFAULT NULL);

    /**
    * Actualize Easy Access table TASK_TIMELINE_EA with problems encoded records
    *
    * @param i_patient                Patient identifier
    * @param i_episode                Episode identifier
    * @value i_schedule               Shcedule identifier
    * @param i_external_request       P1 (referral) identifier
    * @param i_institution            Institution identifier
    * @param i_start_dt               Start date to be consider to the validation/reconstruction of data
    * @param i_end_dt                 End date to be consider to the validation/reconstruction of data
    * @param i_validate_table         Indicates necessary to validate data existent in easy access table
    * @param i_output_invalid_records Show final (resumed) information about updated statistics
    * @param i_recreate_table         Indicates necessary to rebuild data existent in easy access table
    * @param i_commit_step            Number of registries between commit's
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    *
    * @author   Sofia Mendes
    * @version  2.6.1.2
    * @since    22-Sep-2011
    */
    FUNCTION admin_task_tl_problems_ea
    (
        i_patient                IN NUMBER DEFAULT NULL,
        i_episode                IN NUMBER DEFAULT NULL,
        i_schedule               IN NUMBER DEFAULT NULL,
        i_external_request       IN NUMBER DEFAULT NULL,
        i_institution            IN NUMBER DEFAULT NULL,
        i_start_dt               IN TIMESTAMP WITH TIME ZONE DEFAULT NULL,
        i_end_dt                 IN TIMESTAMP WITH TIME ZONE DEFAULT NULL,
        i_validate_table         IN BOOLEAN DEFAULT TRUE,
        i_output_invalid_records IN BOOLEAN DEFAULT FALSE,
        i_recreate_table         IN BOOLEAN DEFAULT FALSE,
        i_commit_step            IN NUMBER DEFAULT pk_data_gov_admin.get_commit_limit
    ) RETURN BOOLEAN;
    /**
    * Actualize Easy Access table TASK_TIMELINE_EA with problems encoded records
    *
    * @param i_patient                Patient identifier
    * @param i_episode                Episode identifier
    * @value i_schedule               Shcedule identifier
    * @param i_external_request       P1 (referral) identifier
    * @param i_institution            Institution identifier
    * @param i_start_dt               Start date to be consider to the validation/reconstruction of data
    * @param i_end_dt                 End date to be consider to the validation/reconstruction of data
    * @param i_validate_table         Indicates necessary to validate data existent in easy access table
    * @param i_output_invalid_records Show final (resumed) information about updated statistics
    * @param i_recreate_table         Indicates necessary to rebuild data existent in easy access table
    * @param i_commit_step            Number of registries between commit's
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    *
    * @author   Sofia Mendes
    * @version  2.6.1.2
    * @since    22-Sep-2011
    */
    FUNCTION admin_task_tl_allergy_ea
    (
        i_patient                IN NUMBER DEFAULT NULL,
        i_episode                IN NUMBER DEFAULT NULL,
        i_schedule               IN NUMBER DEFAULT NULL,
        i_external_request       IN NUMBER DEFAULT NULL,
        i_institution            IN NUMBER DEFAULT NULL,
        i_start_dt               IN TIMESTAMP WITH TIME ZONE DEFAULT NULL,
        i_end_dt                 IN TIMESTAMP WITH TIME ZONE DEFAULT NULL,
        i_validate_table         IN BOOLEAN DEFAULT TRUE,
        i_output_invalid_records IN BOOLEAN DEFAULT FALSE,
        i_recreate_table         IN BOOLEAN DEFAULT FALSE,
        i_commit_step            IN NUMBER DEFAULT pk_data_gov_admin.get_commit_limit
    ) RETURN BOOLEAN;
    /**
    * Actualize Easy Access table TASK_TIMELINE_EA with problems encoded records
    *
    * @param i_patient                Patient identifier
    * @param i_episode                Episode identifier
    * @value i_schedule               Shcedule identifier
    * @param i_external_request       P1 (referral) identifier
    * @param i_institution            Institution identifier
    * @param i_start_dt               Start date to be consider to the validation/reconstruction of data
    * @param i_end_dt                 End date to be consider to the validation/reconstruction of data
    * @param i_validate_table         Indicates necessary to validate data existent in easy access table
    * @param i_output_invalid_records Show final (resumed) information about updated statistics
    * @param i_recreate_table         Indicates necessary to rebuild data existent in easy access table
    * @param i_commit_step            Number of registries between commit's
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    *
    * @author   Sofia Mendes
    * @version  2.6.1.2
    * @since    22-Sep-2011
    */
    FUNCTION admin_task_tl_al_unaware_ea
    (
        i_patient                IN NUMBER DEFAULT NULL,
        i_episode                IN NUMBER DEFAULT NULL,
        i_schedule               IN NUMBER DEFAULT NULL,
        i_external_request       IN NUMBER DEFAULT NULL,
        i_institution            IN NUMBER DEFAULT NULL,
        i_start_dt               IN TIMESTAMP WITH TIME ZONE DEFAULT NULL,
        i_end_dt                 IN TIMESTAMP WITH TIME ZONE DEFAULT NULL,
        i_validate_table         IN BOOLEAN DEFAULT TRUE,
        i_output_invalid_records IN BOOLEAN DEFAULT FALSE,
        i_recreate_table         IN BOOLEAN DEFAULT FALSE,
        i_commit_step            IN NUMBER DEFAULT pk_data_gov_admin.get_commit_limit
    ) RETURN BOOLEAN;
    /**
    * Actualize Easy Access table TASK_TIMELINE_EA with problems encoded records
    *
    * @param i_patient                Patient identifier
    * @param i_episode                Episode identifier
    * @value i_schedule               Shcedule identifier
    * @param i_external_request       P1 (referral) identifier
    * @param i_institution            Institution identifier
    * @param i_start_dt               Start date to be consider to the validation/reconstruction of data
    * @param i_end_dt                 End date to be consider to the validation/reconstruction of data
    * @param i_validate_table         Indicates necessary to validate data existent in easy access table
    * @param i_output_invalid_records Show final (resumed) information about updated statistics
    * @param i_recreate_table         Indicates necessary to rebuild data existent in easy access table
    * @param i_commit_step            Number of registries between commit's
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    *
    * @author   Sofia Mendes
    * @version  2.6.1.2
    * @since    22-Sep-2011
    */
    FUNCTION admin_task_tl_prob_unaware_ea
    (
        i_patient                IN NUMBER DEFAULT NULL,
        i_episode                IN NUMBER DEFAULT NULL,
        i_schedule               IN NUMBER DEFAULT NULL,
        i_external_request       IN NUMBER DEFAULT NULL,
        i_institution            IN NUMBER DEFAULT NULL,
        i_start_dt               IN TIMESTAMP WITH TIME ZONE DEFAULT NULL,
        i_end_dt                 IN TIMESTAMP WITH TIME ZONE DEFAULT NULL,
        i_validate_table         IN BOOLEAN DEFAULT TRUE,
        i_output_invalid_records IN BOOLEAN DEFAULT FALSE,
        i_recreate_table         IN BOOLEAN DEFAULT FALSE,
        i_commit_step            IN NUMBER DEFAULT pk_data_gov_admin.get_commit_limit
    ) RETURN BOOLEAN;
    /**
    * Actualize Easy Access table TASK_TIMELINE_EA with problems encoded records
    *
    * @param i_patient                Patient identifier
    * @param i_episode                Episode identifier
    * @value i_schedule               Shcedule identifier
    * @param i_external_request       P1 (referral) identifier
    * @param i_institution            Institution identifier
    * @param i_start_dt               Start date to be consider to the validation/reconstruction of data
    * @param i_end_dt                 End date to be consider to the validation/reconstruction of data
    * @param i_validate_table         Indicates necessary to validate data existent in easy access table
    * @param i_output_invalid_records Show final (resumed) information about updated statistics
    * @param i_recreate_table         Indicates necessary to rebuild data existent in easy access table
    * @param i_commit_step            Number of registries between commit's
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    *
    * @author   Sofia Mendes
    * @version  2.6.1.2
    * @since    22-Sep-2011
    */
    FUNCTION admin_task_tl_prob_diag_ea
    (
        i_patient                IN NUMBER DEFAULT NULL,
        i_episode                IN NUMBER DEFAULT NULL,
        i_schedule               IN NUMBER DEFAULT NULL,
        i_external_request       IN NUMBER DEFAULT NULL,
        i_institution            IN NUMBER DEFAULT NULL,
        i_start_dt               IN TIMESTAMP WITH TIME ZONE DEFAULT NULL,
        i_end_dt                 IN TIMESTAMP WITH TIME ZONE DEFAULT NULL,
        i_validate_table         IN BOOLEAN DEFAULT TRUE,
        i_output_invalid_records IN BOOLEAN DEFAULT FALSE,
        i_recreate_table         IN BOOLEAN DEFAULT FALSE,
        i_commit_step            IN NUMBER DEFAULT pk_data_gov_admin.get_commit_limit
    ) RETURN BOOLEAN;

    /**
    * Actualize Easy Access table TASK_TIMELINE_EA with past history free text records
    *
    * @param i_patient                Patient identifier
    * @param i_episode                Episode identifier
    * @value i_schedule               Shcedule identifier
    * @param i_external_request       P1 (referral) identifier
    * @param i_institution            Institution identifier
    * @param i_start_dt               Start date to be consider to the validation/reconstruction of data
    * @param i_end_dt                 End date to be consider to the validation/reconstruction of data
    * @param i_validate_table         Indicates necessary to validate data existent in easy access table
    * @param i_output_invalid_records Show final (resumed) information about updated statistics
    * @param i_recreate_table         Indicates necessary to rebuild data existent in easy access table
    * @param i_commit_step            Number of registries between commit's
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    *
    * @author   Sofia Mendes
    * @version  2.6.1.2
    * @since    22-Sep-2011
    */
    FUNCTION admin_task_tl_ph_ftxt_ea
    (
        i_patient                IN NUMBER DEFAULT NULL,
        i_episode                IN NUMBER DEFAULT NULL,
        i_schedule               IN NUMBER DEFAULT NULL,
        i_external_request       IN NUMBER DEFAULT NULL,
        i_institution            IN NUMBER DEFAULT NULL,
        i_start_dt               IN TIMESTAMP WITH TIME ZONE DEFAULT NULL,
        i_end_dt                 IN TIMESTAMP WITH TIME ZONE DEFAULT NULL,
        i_validate_table         IN BOOLEAN DEFAULT TRUE,
        i_output_invalid_records IN BOOLEAN DEFAULT FALSE,
        i_recreate_table         IN BOOLEAN DEFAULT FALSE,
        i_commit_step            IN NUMBER DEFAULT pk_data_gov_admin.get_commit_limit
    ) RETURN BOOLEAN;

    FUNCTION admin_task_tl_consults
    (
        i_patient                IN NUMBER := NULL,
        i_episode                IN NUMBER := NULL,
        i_schedule               IN NUMBER := NULL,
        i_external_request       IN NUMBER := NULL,
        i_institution            IN NUMBER := NULL,
        i_start_dt               IN TIMESTAMP WITH LOCAL TIME ZONE := NULL,
        i_end_dt                 IN TIMESTAMP WITH LOCAL TIME ZONE := NULL,
        i_validate_table         IN BOOLEAN := TRUE,
        i_output_invalid_records IN BOOLEAN := FALSE,
        i_recreate_table         IN BOOLEAN := FALSE,
        i_commit_step            IN NUMBER := pk_data_gov_admin.get_commit_limit
    ) RETURN BOOLEAN;

    FUNCTION admin_task_tl_disch_instruc
    (
        i_patient                IN NUMBER := NULL,
        i_episode                IN NUMBER := NULL,
        i_schedule               IN NUMBER := NULL,
        i_external_request       IN NUMBER := NULL,
        i_institution            IN NUMBER := NULL,
        i_start_dt               IN TIMESTAMP WITH LOCAL TIME ZONE := NULL,
        i_end_dt                 IN TIMESTAMP WITH LOCAL TIME ZONE := NULL,
        i_validate_table         IN BOOLEAN := TRUE,
        i_output_invalid_records IN BOOLEAN := FALSE,
        i_recreate_table         IN BOOLEAN := FALSE,
        i_commit_step            IN NUMBER := pk_data_gov_admin.get_commit_limit
    ) RETURN BOOLEAN;

    FUNCTION admin_task_tl_inp_surg
    (
        i_patient                IN NUMBER := NULL,
        i_episode                IN NUMBER := NULL,
        i_schedule               IN NUMBER := NULL,
        i_external_request       IN NUMBER := NULL,
        i_institution            IN NUMBER := NULL,
        i_start_dt               IN TIMESTAMP WITH LOCAL TIME ZONE := NULL,
        i_end_dt                 IN TIMESTAMP WITH LOCAL TIME ZONE := NULL,
        i_validate_table         IN BOOLEAN := TRUE,
        i_output_invalid_records IN BOOLEAN := FALSE,
        i_recreate_table         IN BOOLEAN := FALSE,
        i_commit_step            IN NUMBER := pk_data_gov_admin.get_commit_limit
    ) RETURN BOOLEAN;

    FUNCTION admin_task_tl_surgery
    (
        i_patient                IN NUMBER := NULL,
        i_episode                IN NUMBER := NULL,
        i_schedule               IN NUMBER := NULL,
        i_external_request       IN NUMBER := NULL,
        i_institution            IN NUMBER := NULL,
        i_start_dt               IN TIMESTAMP WITH LOCAL TIME ZONE := NULL,
        i_end_dt                 IN TIMESTAMP WITH LOCAL TIME ZONE := NULL,
        i_validate_table         IN BOOLEAN := TRUE,
        i_output_invalid_records IN BOOLEAN := FALSE,
        i_recreate_table         IN BOOLEAN := FALSE,
        i_commit_step            IN NUMBER := pk_data_gov_admin.get_commit_limit
    ) RETURN BOOLEAN;

    /**
    * Actualize Easy Access table TASK_TIMELINE_EA with all tasks
    *
    * @param i_patient                Patient identifier
    * @param i_episode                Episode identifier
    * @value i_schedule               Shcedule identifier
    * @param i_external_request       P1 (referral) identifier
    * @param i_institution            Institution identifier
    * @param i_start_dt               Start date to be consider to the validation/reconstruction of data
    * @param i_end_dt                 End date to be consider to the validation/reconstruction of data
    * @param i_validate_table         Indicates necessary to validate data existent in easy access table
    * @param i_output_invalid_records Show final (resumed) information about updated statistics
    * @param i_recreate_table         Indicates necessary to rebuild data existent in easy access table
    * @param i_commit_step            Number of registries between commit's
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author   Luís Maia
    * @version  2.5.0.2
    * @since    2009/04/19
    */
    FUNCTION admin_all_task_tl_tables
    (
        i_patient                IN NUMBER DEFAULT NULL,
        i_episode                IN NUMBER DEFAULT NULL,
        i_schedule               IN NUMBER DEFAULT NULL,
        i_external_request       IN NUMBER DEFAULT NULL,
        i_institution            IN NUMBER DEFAULT NULL,
        i_start_dt               IN TIMESTAMP WITH TIME ZONE DEFAULT NULL,
        i_end_dt                 IN TIMESTAMP WITH TIME ZONE DEFAULT NULL,
        i_validate_table         IN BOOLEAN DEFAULT TRUE,
        i_output_invalid_records IN BOOLEAN DEFAULT FALSE,
        i_recreate_table         IN BOOLEAN DEFAULT FALSE,
        i_commit_step            IN NUMBER DEFAULT pk_data_gov_admin.get_commit_limit
    ) RETURN BOOLEAN;

    /**
    * Actualize Easy Access table TASK_TIMELINE_EA with all tasks
    *
    * @author   Luís Maia
    * @version  2.5.0.2
    * @since    2009/04/19
    */
    PROCEDURE admin_71_all_task_tl_tables;

    /**
    * Update Easy Access table GRIDS_EA with all valid episodes
    *
    * @author   Fábio Oliveira
    * @version  2.5.0.6
    * @since    2009/09/04
    */
    PROCEDURE admin_50_grids_ea;

    /**
    * Actualize Easy Access table BMNG_BED_EA and BMNG_DAPERTMENT_EA with all tasks
    *
    * @param i_patient                Patient identifier
    * @param i_episode                Episode identifier
    * @value i_schedule               Shcedule identifier
    * @param i_external_request       P1 (referral) identifier
    * @param i_institution            Institution identifier
    * @param i_start_dt               Start date to be consider to the validation/reconstruction of data
    * @param i_end_dt                 End date to be consider to the validation/reconstruction of data
    * @param i_validate_table         Indicates necessary to validate data existent in easy access table
    * @param i_output_invalid_records Show final (resumed) information about updated statistics
    * @param i_recreate_table         Indicates necessary to rebuild data existent in easy access table
    * @param i_commit_step            Number of registries between commit's
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author   Luís Maia
    * @version  2.6.1.0.1
    * @since    2011/05/09
    */
    FUNCTION admin_all_bmng_tables
    (
        i_patient                IN NUMBER DEFAULT NULL,
        i_episode                IN NUMBER DEFAULT NULL,
        i_schedule               IN NUMBER DEFAULT NULL,
        i_external_request       IN NUMBER DEFAULT NULL,
        i_institution            IN NUMBER DEFAULT NULL,
        i_start_dt               IN TIMESTAMP WITH TIME ZONE DEFAULT NULL,
        i_end_dt                 IN TIMESTAMP WITH TIME ZONE DEFAULT NULL,
        i_validate_table         IN BOOLEAN DEFAULT TRUE,
        i_output_invalid_records IN BOOLEAN DEFAULT FALSE,
        i_recreate_table         IN BOOLEAN DEFAULT FALSE,
        i_commit_step            IN NUMBER DEFAULT pk_data_gov_admin.get_commit_limit
    ) RETURN BOOLEAN;

    /**
    * ADMIN_ALL_BMNG_TABLES           Actualize all Easy Access tables associated with functionality Bed Management
    *
    * @author   Luís Maia
    * @version  2.5.0.5
    * @since    2009/07/28
    */
    PROCEDURE admin_70_all_bmng_tables;

    /**
    * Data migration main script
    *
    * @param   i_mode       execution mode    
    * @param   i_inst       instituition identifier
    *
    * @author  Rui Spratley
    * @version 2.6.2
    * @since   27/02/2012
    */
    PROCEDURE admin_all_datagov_tables
    (
        i_mode IN NUMBER DEFAULT 0,
        i_inst IN NUMBER DEFAULT 0
    );

    /**
    * Data migration main script (compatibility version)
    *
    * @param   i_mode       execution mode
    *
    * @author  Rui Spratley
    * @version 2.4.3d
    * @since   31/10/2008
    */
    PROCEDURE admin_all_datagov_tables(i_mode IN NUMBER DEFAULT 0);

    /**
    * Actualize Easy Access table TASK_TIMELINE_EA with medication tasks
    *
    * @param i_patient                Patient identifier
    * @param i_episode                Episode identifier
    * @value i_schedule               Shcedule identifier
    * @param i_external_request       P1 (referral) identifier
    * @param i_institution            Institution identifier
    * @param i_start_dt               Start date to be consider to the validation/reconstruction of data
    * @param i_end_dt                 End date to be consider to the validation/reconstruction of data
    * @param i_validate_table         Indicates necessary to validate data existent in easy access table
    * @param i_output_invalid_records Show final (resumed) information about updated statistics
    * @param i_recreate_table         Indicates necessary to rebuild data existent in easy access table
    * @param i_commit_step            Number of registries between commit's
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author   Pedro Teixeira
    * @version  2.6.1.2
    * @since    2011/08/26
    */
    FUNCTION admin_task_tl_medication_ea
    (
        i_patient                IN NUMBER DEFAULT NULL,
        i_episode                IN NUMBER DEFAULT NULL,
        i_schedule               IN NUMBER DEFAULT NULL,
        i_external_request       IN NUMBER DEFAULT NULL,
        i_institution            IN NUMBER DEFAULT NULL,
        i_start_dt               IN TIMESTAMP WITH TIME ZONE DEFAULT NULL,
        i_end_dt                 IN TIMESTAMP WITH TIME ZONE DEFAULT NULL,
        i_validate_table         IN BOOLEAN DEFAULT TRUE,
        i_output_invalid_records IN BOOLEAN DEFAULT FALSE,
        i_recreate_table         IN BOOLEAN DEFAULT FALSE,
        i_commit_step            IN NUMBER DEFAULT pk_data_gov_admin.get_commit_limit
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Actualize Easy Access table TASK_TIMELINE_EA with medication recon tasks
    *
    * @param i_patient                Patient identifier
    * @param i_episode                Episode identifier
    * @value i_schedule               Shcedule identifier
    * @param i_external_request       P1 (referral) identifier
    * @param i_institution            Institution identifier
    * @param i_start_dt               Start date to be consider to the validation/reconstruction of data
    * @param i_end_dt                 End date to be consider to the validation/reconstruction of data
    * @param i_validate_table         Indicates necessary to validate data existent in easy access table
    * @param i_output_invalid_records Show final (resumed) information about updated statistics
    * @param i_recreate_table         Indicates necessary to rebuild data existent in easy access table
    * @param i_commit_step            Number of registries between commit's
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    *
    * @author   Pedro Teixeira
    * @since    09/06/2017
    ********************************************************************************************/
    FUNCTION admin_task_tl_med_recon_ea
    (
        i_patient                IN NUMBER DEFAULT NULL,
        i_episode                IN NUMBER DEFAULT NULL,
        i_schedule               IN NUMBER DEFAULT NULL,
        i_external_request       IN NUMBER DEFAULT NULL,
        i_institution            IN NUMBER DEFAULT NULL,
        i_start_dt               IN TIMESTAMP WITH TIME ZONE DEFAULT NULL,
        i_end_dt                 IN TIMESTAMP WITH TIME ZONE DEFAULT NULL,
        i_validate_table         IN BOOLEAN DEFAULT TRUE,
        i_output_invalid_records IN BOOLEAN DEFAULT FALSE,
        i_recreate_table         IN BOOLEAN DEFAULT FALSE,
        i_commit_step            IN NUMBER DEFAULT pk_data_gov_admin.get_commit_limit
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Update intake and output tasks in TASK_TIMELINE_EA.
    *
    * @param i_patient                Patient identifier
    * @param i_episode                Episode identifier
    * @value i_schedule               Shcedule identifier
    * @param i_external_request       P1 (referral) identifier
    * @param i_institution            Institution identifier
    * @param i_start_dt               Start date to be consider to the validation/reconstruction of data
    * @param i_end_dt                 End date to be consider to the validation/reconstruction of data
    * @param i_validate_table         Indicates necessary to validate data existent in easy access table
    * @param i_output_invalid_records Show final (resumed) information about updated statistics
    * @param i_recreate_table         Indicates necessary to rebuild data existent in easy access table
    * @param i_commit_step            Number of registries between commit's
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author   Nuno Neves
    * @version  2.6.2
    * @since    2012/059/14
    ********************************************************************************************/
    FUNCTION admin_task_tl_nurse_tea
    (
        i_patient                IN NUMBER := NULL,
        i_episode                IN NUMBER := NULL,
        i_schedule               IN NUMBER := NULL,
        i_external_request       IN NUMBER := NULL,
        i_institution            IN NUMBER := NULL,
        i_start_dt               IN TIMESTAMP WITH LOCAL TIME ZONE := NULL,
        i_end_dt                 IN TIMESTAMP WITH LOCAL TIME ZONE := NULL,
        i_validate_table         IN BOOLEAN := TRUE,
        i_output_invalid_records IN BOOLEAN := FALSE,
        i_recreate_table         IN BOOLEAN := FALSE,
        i_commit_step            IN NUMBER := pk_data_gov_admin.get_commit_limit
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Actualize Easy Access table TASK_TIMELINE_EA with procedure tasks
    *
    * @param i_patient                Patient identifier
    * @param i_episode                Episode identifier
    * @value i_schedule               Shcedule identifier
    * @param i_external_request       P1 (referral) identifier
    * @param i_institution            Institution identifier
    * @param i_start_dt               Start date to be consider to the validation/reconstruction of data
    * @param i_end_dt                 End date to be consider to the validation/reconstruction of data
    * @param i_validate_table         Indicates necessary to validate data existent in easy access table
    * @param i_output_invalid_records Show final (resumed) information about updated statistics
    * @param i_recreate_table         Indicates necessary to rebuild data existent in easy access table
    * @param i_commit_step            Number of registries between commit's
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    *
    * @author   Nuno Neves
    * @version  2.6.3
    * @since    2012/11/19
    ********************************************************************************************/
    FUNCTION admin_task_tl_interv_p_plan
    (
        i_patient                IN NUMBER DEFAULT NULL,
        i_episode                IN NUMBER DEFAULT NULL,
        i_schedule               IN NUMBER DEFAULT NULL,
        i_external_request       IN NUMBER DEFAULT NULL,
        i_institution            IN NUMBER DEFAULT NULL,
        i_start_dt               IN TIMESTAMP WITH TIME ZONE DEFAULT NULL,
        i_end_dt                 IN TIMESTAMP WITH TIME ZONE DEFAULT NULL,
        i_validate_table         IN BOOLEAN DEFAULT TRUE,
        i_output_invalid_records IN BOOLEAN DEFAULT FALSE,
        i_recreate_table         IN BOOLEAN DEFAULT FALSE,
        i_commit_step            IN NUMBER DEFAULT pk_data_gov_admin.get_commit_limit
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Update tasks in TASK_TIMELINE_EA.
    *
    * @param i_patient                Patient identifier
    * @param i_episode                Episode identifier
    * @value i_schedule               Shcedule identifier
    * @param i_external_request       P1 (referral) identifier
    * @param i_institution            Institution identifier
    * @param i_start_dt               Start date to be consider to the validation/reconstruction of data
    * @param i_end_dt                 End date to be consider to the validation/reconstruction of data
    * @param i_validate_table         Indicates necessary to validate data existent in easy access table
    * @param i_output_invalid_records Show final (resumed) information about updated statistics
    * @param i_recreate_table         Indicates necessary to rebuild data existent in easy access table
    * @param i_commit_step            Number of registries between commit's
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author   Paulo teixeira
    * @version  2.6.3
    * @since    2013/05/13
    ********************************************************************************************/
    FUNCTION admin_task_tl_mtos_ea
    (
        i_patient                IN NUMBER := NULL,
        i_episode                IN NUMBER := NULL,
        i_schedule               IN NUMBER := NULL,
        i_external_request       IN NUMBER := NULL,
        i_institution            IN NUMBER := NULL,
        i_start_dt               IN TIMESTAMP WITH LOCAL TIME ZONE := NULL,
        i_end_dt                 IN TIMESTAMP WITH LOCAL TIME ZONE := NULL,
        i_validate_table         IN BOOLEAN := TRUE,
        i_output_invalid_records IN BOOLEAN := FALSE,
        i_recreate_table         IN BOOLEAN := FALSE,
        i_commit_step            IN NUMBER := pk_data_gov_admin.get_commit_limit
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Update triage records in TASK_TIMELINE_EA.
    *
    * @param i_patient                Patient identifier
    * @param i_episode                Episode identifier
    * @value i_schedule               Shcedule identifier
    * @param i_external_request       P1 (referral) identifier
    * @param i_institution            Institution identifier
    * @param i_start_dt               Start date to be consider to the validation/reconstruction of data
    * @param i_end_dt                 End date to be consider to the validation/reconstruction of data
    * @param i_validate_table         Indicates necessary to validate data existent in easy access table
    * @param i_output_invalid_records Show final (resumed) information about updated statistics
    * @param i_recreate_table         Indicates necessary to rebuild data existent in easy access table
    * @param i_commit_step            Number of registries between commit's
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author   Sofia Mendes
    * @version  2.6.3
    * @since    30-Apr-2013
    ********************************************************************************************/
    FUNCTION admin_task_tl_triage
    (
        i_patient                IN NUMBER := NULL,
        i_episode                IN NUMBER := NULL,
        i_schedule               IN NUMBER := NULL,
        i_external_request       IN NUMBER := NULL,
        i_institution            IN NUMBER := NULL,
        i_start_dt               IN TIMESTAMP WITH LOCAL TIME ZONE := NULL,
        i_end_dt                 IN TIMESTAMP WITH LOCAL TIME ZONE := NULL,
        i_validate_table         IN BOOLEAN := TRUE,
        i_output_invalid_records IN BOOLEAN := FALSE,
        i_recreate_table         IN BOOLEAN := FALSE,
        i_commit_step            IN NUMBER := pk_data_gov_admin.get_commit_limit
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Update CITS records in TASK_TIMELINE_EA.
    *
    * @param i_patient                Patient identifier
    * @param i_episode                Episode identifier
    * @value i_schedule               Shcedule identifier
    * @param i_external_request       P1 (referral) identifier
    * @param i_institution            Institution identifier
    * @param i_start_dt               Start date to be consider to the validation/reconstruction of data
    * @param i_end_dt                 End date to be consider to the validation/reconstruction of data
    * @param i_validate_table         Indicates necessary to validate data existent in easy access table
    * @param i_output_invalid_records Show final (resumed) information about updated statistics
    * @param i_recreate_table         Indicates necessary to rebuild data existent in easy access table
    * @param i_commit_step            Number of registries between commit's
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author   Sofia Mendes
    * @version  2.6.3
    * @since    11-Jul-2013
    ********************************************************************************************/
    FUNCTION admin_task_tl_cit
    (
        i_patient                IN NUMBER := NULL,
        i_episode                IN NUMBER := NULL,
        i_schedule               IN NUMBER := NULL,
        i_external_request       IN NUMBER := NULL,
        i_institution            IN NUMBER := NULL,
        i_start_dt               IN TIMESTAMP WITH LOCAL TIME ZONE := NULL,
        i_end_dt                 IN TIMESTAMP WITH LOCAL TIME ZONE := NULL,
        i_validate_table         IN BOOLEAN := TRUE,
        i_output_invalid_records IN BOOLEAN := FALSE,
        i_recreate_table         IN BOOLEAN := FALSE,
        i_commit_step            IN NUMBER := pk_data_gov_admin.get_commit_limit
    ) RETURN BOOLEAN;

    /********************************************************************************************    
    * Update Easy Access table TASK_TIMELINE_EA with communication orders info
      *
      * @param i_patient                Patient identifier
      * @param i_episode                Episode identifier
      * @value i_schedule               Shcedule identifier
      * @param i_external_request       P1 (referral) identifier
      * @param i_institution            Institution identifier
      * @param i_start_dt               Start date to be consider to the validation/reconstruction of data
      * @param i_end_dt                 End date to be consider to the validation/reconstruction of data
      * @param i_validate_table         Indicates necessary to validate data existent in easy access table
      * @param i_output_invalid_records Show final (resumed) information about updated statistics
      * @param i_recreate_table         Indicates necessary to rebuild data existent in easy access table
      * @param i_commit_step            Number of registries between commit's
      *
      * @return  TRUE if sucess, FALSE otherwise
      *
      * @author   Ana Monteiro
      * @version  2.6.3
      * @since    2014/03/06
      ********************************************************************************************/
    FUNCTION admin_task_tl_comm_orders
    (
        i_patient                IN NUMBER := NULL,
        i_episode                IN NUMBER := NULL,
        i_schedule               IN NUMBER := NULL,
        i_external_request       IN NUMBER := NULL,
        i_institution            IN NUMBER := NULL,
        i_start_dt               IN TIMESTAMP WITH LOCAL TIME ZONE := NULL,
        i_end_dt                 IN TIMESTAMP WITH LOCAL TIME ZONE := NULL,
        i_validate_table         IN BOOLEAN := TRUE,
        i_output_invalid_records IN BOOLEAN := FALSE,
        i_recreate_table         IN BOOLEAN := FALSE,
        i_commit_step            IN NUMBER := pk_data_gov_admin.get_commit_limit
    ) RETURN BOOLEAN;

    FUNCTION admin_task_tl_plan_ea
    (
        i_patient                IN NUMBER DEFAULT NULL,
        i_episode                IN NUMBER DEFAULT NULL,
        i_schedule               IN NUMBER DEFAULT NULL,
        i_external_request       IN NUMBER DEFAULT NULL,
        i_institution            IN NUMBER DEFAULT NULL,
        i_start_dt               IN TIMESTAMP WITH TIME ZONE DEFAULT NULL,
        i_end_dt                 IN TIMESTAMP WITH TIME ZONE DEFAULT NULL,
        i_validate_table         IN BOOLEAN DEFAULT TRUE,
        i_output_invalid_records IN BOOLEAN DEFAULT FALSE,
        i_recreate_table         IN BOOLEAN DEFAULT FALSE,
        i_commit_step            IN NUMBER DEFAULT pk_data_gov_admin.get_commit_limit
    ) RETURN BOOLEAN;

    FUNCTION update_viewer_epis_archive
    (
        i_table_id_patients IN table_number,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Updates Easy Access table TASK_TIMELINE_EA with Plan's tasks
    *
    * @param i_patient                Patient identifier
    * @param i_episode                Episode identifier
    * @value i_schedule               Schedule identifier
    * @param i_external_request       P1 (referral) identifier
    * @param i_institution            Institution identifier
    * @param i_start_dt               Start date to be consider to the validation/reconstruction of data
    * @param i_end_dt                 End date to be consider to the validation/reconstruction of data
    * @param i_validate_table         Indicates necessary to validate data existent in easy access table
    * @param i_output_invalid_records Show final (resumed) information about updated statistics
    * @param i_recreate_table         Indicates necessary to rebuild data existent in easy access table
    * @param i_commit_step            Number of registries between commit's
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *
    * @author                         António Neto
    * @version                        2.6.2
    * @since                          21-Mar-2012
    ********************************************************************************************/
    FUNCTION admin_task_tl_epis_reason_ea
    (
        i_patient                IN NUMBER DEFAULT NULL,
        i_episode                IN NUMBER DEFAULT NULL,
        i_schedule               IN NUMBER DEFAULT NULL,
        i_external_request       IN NUMBER DEFAULT NULL,
        i_institution            IN NUMBER DEFAULT NULL,
        i_start_dt               IN TIMESTAMP WITH TIME ZONE DEFAULT NULL,
        i_end_dt                 IN TIMESTAMP WITH TIME ZONE DEFAULT NULL,
        i_validate_table         IN BOOLEAN DEFAULT TRUE,
        i_output_invalid_records IN BOOLEAN DEFAULT FALSE,
        i_recreate_table         IN BOOLEAN DEFAULT FALSE,
        i_commit_step            IN NUMBER DEFAULT pk_data_gov_admin.get_commit_limit
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Actualize Easy Access table TASK_TIMELINE_EA with monitorizations tasks
    *
    * @param i_patient                Patient identifier
    * @param i_episode                Episode identifier
    * @value i_schedule               Shcedule identifier
    * @param i_external_request       P1 (referral) identifier
    * @param i_institution            Institution identifier
    * @param i_start_dt               Start date to be consider to the validation/reconstruction of data
    * @param i_end_dt                 End date to be consider to the validation/reconstruction of data
    * @param i_validate_table         Indicates necessary to validate data existent in easy access table
    * @param i_output_invalid_records Show final (resumed) information about updated statistics
    * @param i_recreate_table         Indicates necessary to rebuild data existent in easy access table
    * @param i_commit_step            Number of registries between commit's
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    *
    * @author   Luís Maia
    * @version  2.5.0.2
    * @since    2009/04/21
    ********************************************************************************************/
    FUNCTION admin_task_tl_monit_ea
    (
        i_patient                IN NUMBER DEFAULT NULL,
        i_episode                IN NUMBER DEFAULT NULL,
        i_schedule               IN NUMBER DEFAULT NULL,
        i_external_request       IN NUMBER DEFAULT NULL,
        i_institution            IN NUMBER DEFAULT NULL,
        i_start_dt               IN TIMESTAMP WITH TIME ZONE DEFAULT NULL,
        i_end_dt                 IN TIMESTAMP WITH TIME ZONE DEFAULT NULL,
        i_validate_table         IN BOOLEAN DEFAULT TRUE,
        i_output_invalid_records IN BOOLEAN DEFAULT FALSE,
        i_recreate_table         IN BOOLEAN DEFAULT FALSE,
        i_commit_step            IN NUMBER DEFAULT pk_data_gov_admin.get_commit_limit
    ) RETURN BOOLEAN;
    --
    FUNCTION admin_task_tl_er_law_ea
    (
        i_patient                IN NUMBER DEFAULT NULL,
        i_episode                IN NUMBER DEFAULT NULL,
        i_schedule               IN NUMBER DEFAULT NULL,
        i_external_request       IN NUMBER DEFAULT NULL,
        i_institution            IN NUMBER DEFAULT NULL,
        i_start_dt               IN TIMESTAMP WITH TIME ZONE DEFAULT NULL,
        i_end_dt                 IN TIMESTAMP WITH TIME ZONE DEFAULT NULL,
        i_validate_table         IN BOOLEAN DEFAULT TRUE,
        i_output_invalid_records IN BOOLEAN DEFAULT FALSE,
        i_recreate_table         IN BOOLEAN DEFAULT FALSE,
        i_commit_step            IN NUMBER DEFAULT pk_data_gov_admin.get_commit_limit
    ) RETURN BOOLEAN;
    --
    FUNCTION admin_task_tl_body_diagram_ea
    (
        i_patient                IN NUMBER DEFAULT NULL,
        i_episode                IN NUMBER DEFAULT NULL,
        i_schedule               IN NUMBER DEFAULT NULL,
        i_external_request       IN NUMBER DEFAULT NULL,
        i_institution            IN NUMBER DEFAULT NULL,
        i_start_dt               IN TIMESTAMP WITH TIME ZONE DEFAULT NULL,
        i_end_dt                 IN TIMESTAMP WITH TIME ZONE DEFAULT NULL,
        i_validate_table         IN BOOLEAN DEFAULT TRUE,
        i_output_invalid_records IN BOOLEAN DEFAULT FALSE,
        i_recreate_table         IN BOOLEAN DEFAULT FALSE,
        i_commit_step            IN NUMBER DEFAULT pk_data_gov_admin.get_commit_limit
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Update referrals task in TASK_TIMELINE_EA.
    *
    * @param i_patient                Patient identifier
    * @param i_episode                Episode identifier
    * @value i_schedule               Shcedule identifier
    * @param i_external_request       P1 (referral) identifier
    * @param i_institution            Institution identifier
    * @param i_start_dt               Start date to be consider to the validation/reconstruction of data
    * @param i_end_dt                 End date to be consider to the validation/reconstruction of data
    * @param i_validate_table         Indicates necessary to validate data existent in easy access table
    * @param i_output_invalid_records Show final (resumed) information about updated statistics
    * @param i_recreate_table         Indicates necessary to rebuild data existent in easy access table
    * @param i_commit_step            Number of registries between commit's
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author   Elisabete Bugalho
    * @version  2.7.1.
    * @since    2017/06/26
    ********************************************************************************************/
    FUNCTION admin_task_tl_ref_ea
    (
        i_patient                IN NUMBER := NULL,
        i_episode                IN NUMBER := NULL,
        i_schedule               IN NUMBER := NULL,
        i_external_request       IN NUMBER := NULL,
        i_institution            IN NUMBER := NULL,
        i_start_dt               IN TIMESTAMP WITH LOCAL TIME ZONE := NULL,
        i_end_dt                 IN TIMESTAMP WITH LOCAL TIME ZONE := NULL,
        i_validate_table         IN BOOLEAN := TRUE,
        i_output_invalid_records IN BOOLEAN := FALSE,
        i_recreate_table         IN BOOLEAN := FALSE,
        i_commit_step            IN NUMBER := pk_data_gov_admin.get_commit_limit
    ) RETURN BOOLEAN;
    --
    PROCEDURE grid_task_positioning;
    PROCEDURE grid_task_monitorizations;
    PROCEDURE grid_task_movements;
    PROCEDURE grid_task_hidrics;
    PROCEDURE grid_task_discharge_pend;

    FUNCTION tf_list_episode
    (
        i_id_patient     IN episode.id_patient%TYPE DEFAULT NULL,
        i_id_episode     IN episode.id_episode%TYPE DEFAULT NULL,
        i_id_institution IN episode.id_institution%TYPE DEFAULT NULL
    ) RETURN table_t_episode;

    FUNCTION admin_task_tl_iah_special_ea
    (
        i_patient                IN NUMBER := NULL,
        i_episode                IN NUMBER := NULL,
        i_schedule               IN NUMBER := NULL,
        i_external_request       IN NUMBER := NULL,
        i_institution            IN NUMBER := NULL,
        i_start_dt               IN TIMESTAMP WITH LOCAL TIME ZONE := NULL,
        i_end_dt                 IN TIMESTAMP WITH LOCAL TIME ZONE := NULL,
        i_validate_table         IN BOOLEAN := TRUE,
        i_output_invalid_records IN BOOLEAN := FALSE,
        i_recreate_table         IN BOOLEAN := FALSE,
        i_commit_step            IN NUMBER := pk_data_gov_admin.get_commit_limit
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Update IAH task in TASK_TIMELINE_EA.
    *
    * @param i_patient                Patient identifier
    * @param i_episode                Episode identifier
    * @value i_schedule               Shcedule identifier
    * @param i_id_aih                 P1 (referral) identifier
    * @param i_institution            Institution identifier
    * @param i_start_dt               Start date to be consider to the validation/reconstruction of data
    * @param i_end_dt                 End date to be consider to the validation/reconstruction of data
    * @param i_validate_table         Indicates necessary to validate data existent in easy access table
    * @param i_output_invalid_records Show final (resumed) information about updated statistics
    * @param i_recreate_table         Indicates necessary to rebuild data existent in easy access table
    * @param i_commit_step            Number of registries between commit's
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author   Pedro Henriques
    * @version  2.7.1.4
    * @since    2017/08/30
    ********************************************************************************************/
    FUNCTION admin_task_tl_iah_ea
    (
        i_patient                IN NUMBER := NULL,
        i_episode                IN NUMBER := NULL,
        i_schedule               IN NUMBER := NULL,
        i_external_request       IN NUMBER := NULL,
        i_institution            IN NUMBER := NULL,
        i_start_dt               IN TIMESTAMP WITH LOCAL TIME ZONE := NULL,
        i_end_dt                 IN TIMESTAMP WITH LOCAL TIME ZONE := NULL,
        i_validate_table         IN BOOLEAN := TRUE,
        i_output_invalid_records IN BOOLEAN := FALSE,
        i_recreate_table         IN BOOLEAN := FALSE,
        i_commit_step            IN NUMBER := pk_data_gov_admin.get_commit_limit
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Actualize Easy Access table TASK_TIMELINE_EA with episode problems encoded records
    *
    * @param i_patient                Patient identifier
    * @param i_episode                Episode identifier
    * @value i_schedule               Shcedule identifier
    * @param i_external_request       P1 (referral) identifier
    * @param i_institution            Institution identifier
    * @param i_start_dt               Start date to be consider to the validation/reconstruction of data
    * @param i_end_dt                 End date to be consider to the validation/reconstruction of data
    * @param i_validate_table         Indicates necessary to validate data existent in easy access table
    * @param i_output_invalid_records Show final (resumed) information about updated statistics
    * @param i_recreate_table         Indicates necessary to rebuild data existent in easy access table
    * @param i_commit_step            Number of registries between commit's
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    *
    * @author   Elisabete Bugalho
    * @version  2.7.2.2
    * @since    13/12/2017
    ********************************************************************************************/
    FUNCTION admin_task_tl_prob_epis_ea
    (
        i_patient                IN NUMBER DEFAULT NULL,
        i_episode                IN NUMBER DEFAULT NULL,
        i_schedule               IN NUMBER DEFAULT NULL,
        i_external_request       IN NUMBER DEFAULT NULL,
        i_institution            IN NUMBER DEFAULT NULL,
        i_start_dt               IN TIMESTAMP WITH TIME ZONE DEFAULT NULL,
        i_end_dt                 IN TIMESTAMP WITH TIME ZONE DEFAULT NULL,
        i_validate_table         IN BOOLEAN DEFAULT TRUE,
        i_output_invalid_records IN BOOLEAN DEFAULT FALSE,
        i_recreate_table         IN BOOLEAN DEFAULT FALSE,
        i_commit_step            IN NUMBER DEFAULT pk_data_gov_admin.get_commit_limit
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Actualize Easy Access table TASK_TIMELINE_EA with episode problems GROUP encoded records
    *
    * @param i_patient                Patient identifier
    * @param i_episode                Episode identifier
    * @value i_schedule               Shcedule identifier
    * @param i_external_request       P1 (referral) identifier
    * @param i_institution            Institution identifier
    * @param i_start_dt               Start date to be consider to the validation/reconstruction of data
    * @param i_end_dt                 End date to be consider to the validation/reconstruction of data
    * @param i_validate_table         Indicates necessary to validate data existent in easy access table
    * @param i_output_invalid_records Show final (resumed) information about updated statistics
    * @param i_recreate_table         Indicates necessary to rebuild data existent in easy access table
    * @param i_commit_step            Number of registries between commit's
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    *
    * @author   Elisabete Bugalho
    * @version  2.7.2.2
    * @since    13/12/2017
    ********************************************************************************************/
    FUNCTION admin_task_tl_prob_group_ea
    (
        i_patient                IN NUMBER DEFAULT NULL,
        i_episode                IN NUMBER DEFAULT NULL,
        i_schedule               IN NUMBER DEFAULT NULL,
        i_external_request       IN NUMBER DEFAULT NULL,
        i_institution            IN NUMBER DEFAULT NULL,
        i_start_dt               IN TIMESTAMP WITH TIME ZONE DEFAULT NULL,
        i_end_dt                 IN TIMESTAMP WITH TIME ZONE DEFAULT NULL,
        i_validate_table         IN BOOLEAN DEFAULT TRUE,
        i_output_invalid_records IN BOOLEAN DEFAULT FALSE,
        i_recreate_table         IN BOOLEAN DEFAULT FALSE,
        i_commit_step            IN NUMBER DEFAULT pk_data_gov_admin.get_commit_limit
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Actualize Easy Access table TASK_TIMELINE_EA with episode problems GROUP encoded records
    *
    * @param i_patient                Patient identifier
    * @param i_episode                Episode identifier
    * @value i_schedule               Shcedule identifier
    * @param i_external_request       P1 (referral) identifier
    * @param i_institution            Institution identifier
    * @param i_start_dt               Start date to be consider to the validation/reconstruction of data
    * @param i_end_dt                 End date to be consider to the validation/reconstruction of data
    * @param i_validate_table         Indicates necessary to validate data existent in easy access table
    * @param i_output_invalid_records Show final (resumed) information about updated statistics
    * @param i_recreate_table         Indicates necessary to rebuild data existent in easy access table
    * @param i_commit_step            Number of registries between commit's
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    *
    * @author   Elisabete Bugalho
    * @version  2.7.2.2
    * @since    19/12/2017
    ********************************************************************************************/
    FUNCTION admin_task_tl_prob_grp_ass_ea
    (
        i_patient                IN NUMBER DEFAULT NULL,
        i_episode                IN NUMBER DEFAULT NULL,
        i_schedule               IN NUMBER DEFAULT NULL,
        i_external_request       IN NUMBER DEFAULT NULL,
        i_institution            IN NUMBER DEFAULT NULL,
        i_start_dt               IN TIMESTAMP WITH TIME ZONE DEFAULT NULL,
        i_end_dt                 IN TIMESTAMP WITH TIME ZONE DEFAULT NULL,
        i_validate_table         IN BOOLEAN DEFAULT TRUE,
        i_output_invalid_records IN BOOLEAN DEFAULT FALSE,
        i_recreate_table         IN BOOLEAN DEFAULT FALSE,
        i_commit_step            IN NUMBER DEFAULT pk_data_gov_admin.get_commit_limit
    ) RETURN BOOLEAN;

    FUNCTION admin_task_tl_supply_ea
    (
        i_patient                IN NUMBER := NULL,
        i_episode                IN NUMBER := NULL,
        i_schedule               IN NUMBER := NULL,
        i_external_request       IN NUMBER := NULL,
        i_institution            IN NUMBER := NULL,
        i_start_dt               IN TIMESTAMP WITH LOCAL TIME ZONE := NULL,
        i_end_dt                 IN TIMESTAMP WITH LOCAL TIME ZONE := NULL,
        i_validate_table         IN BOOLEAN := TRUE,
        i_output_invalid_records IN BOOLEAN := FALSE,
        i_recreate_table         IN BOOLEAN := FALSE,
        i_commit_step            IN NUMBER := pk_data_gov_admin.get_commit_limit
    ) RETURN BOOLEAN;

    FUNCTION admin_task_tl_nurse_diag_ea
    (
        i_patient                IN NUMBER DEFAULT NULL,
        i_episode                IN NUMBER DEFAULT NULL,
        i_schedule               IN NUMBER DEFAULT NULL,
        i_external_request       IN NUMBER DEFAULT NULL,
        i_institution            IN NUMBER DEFAULT NULL,
        i_start_dt               IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        i_end_dt                 IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        i_validate_table         IN BOOLEAN DEFAULT TRUE,
        i_output_invalid_records IN BOOLEAN DEFAULT FALSE,
        i_recreate_table         IN BOOLEAN DEFAULT FALSE,
        i_commit_step            IN NUMBER DEFAULT pk_data_gov_admin.get_commit_limit
    ) RETURN BOOLEAN;

    FUNCTION admin_task_tl_nurse_interv_ea
    (
        i_patient                IN NUMBER DEFAULT NULL,
        i_episode                IN NUMBER DEFAULT NULL,
        i_schedule               IN NUMBER DEFAULT NULL,
        i_external_request       IN NUMBER DEFAULT NULL,
        i_institution            IN NUMBER DEFAULT NULL,
        i_start_dt               IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        i_end_dt                 IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        i_validate_table         IN BOOLEAN DEFAULT TRUE,
        i_output_invalid_records IN BOOLEAN DEFAULT FALSE,
        i_recreate_table         IN BOOLEAN DEFAULT FALSE,
        i_commit_step            IN NUMBER DEFAULT pk_data_gov_admin.get_commit_limit
    ) RETURN BOOLEAN;

    FUNCTION admin_task_tl_rehab_presc
    (
        i_patient                IN NUMBER DEFAULT NULL,
        i_episode                IN NUMBER DEFAULT NULL,
        i_schedule               IN NUMBER DEFAULT NULL,
        i_external_request       IN NUMBER DEFAULT NULL,
        i_institution            IN NUMBER DEFAULT NULL,
        i_start_dt               IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        i_end_dt                 IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        i_validate_table         IN BOOLEAN DEFAULT TRUE,
        i_output_invalid_records IN BOOLEAN DEFAULT FALSE,
        i_recreate_table         IN BOOLEAN DEFAULT FALSE,
        i_commit_step            IN NUMBER DEFAULT pk_data_gov_admin.get_commit_limit
    ) RETURN BOOLEAN;

    FUNCTION admin_task_tl_rehab_diag
    (
        i_patient                IN NUMBER DEFAULT NULL,
        i_episode                IN NUMBER DEFAULT NULL,
        i_schedule               IN NUMBER DEFAULT NULL,
        i_external_request       IN NUMBER DEFAULT NULL,
        i_institution            IN NUMBER DEFAULT NULL,
        i_start_dt               IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        i_end_dt                 IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        i_validate_table         IN BOOLEAN DEFAULT TRUE,
        i_output_invalid_records IN BOOLEAN DEFAULT FALSE,
        i_recreate_table         IN BOOLEAN DEFAULT FALSE,
        i_commit_step            IN NUMBER DEFAULT pk_data_gov_admin.get_commit_limit
    ) RETURN BOOLEAN;
    -------------------------------------------------------------------
    g_error    VARCHAR2(4000);
    g_log_lang language.id_language%TYPE := 2;

    g_sysdate_tstz TIMESTAMP WITH LOCAL TIME ZONE := current_timestamp;
    g_validation_type_2 CONSTANT PLS_INTEGER := 2; --Colocar no package specs como "Registo presente na tabela de Easy Access/Awareness mas com dados errados ou em falta"
    g_validation_type_1 CONSTANT PLS_INTEGER := 1; --"Registo em falta na tabela de Easy Access/Awareness"
    --Default value for episode, when we only have patient information
    g_default_episode CONSTANT PLS_INTEGER := -1;
    --Default value for patient, when we have invalid records
    g_default_patient CONSTANT PLS_INTEGER := -1;

    --TASK TIMELINE GLOBAL VARIABLES
    g_task_tl_table_name CONSTANT VARCHAR2(30 CHAR) := 'TASK_TIMELINE_EA';
    g_task_tl_column_pk1 CONSTANT VARCHAR2(30 CHAR) := 'ID_TASK_REFID';
    g_task_tl_column_pk2 CONSTANT VARCHAR2(30 CHAR) := 'ID_TL_TASK';
    g_task_tl_column_pk3 CONSTANT VARCHAR2(30 CHAR) := 'TABLE_NAME';

    --BED MANAGEMENT GLOBAL VARIABLES
    g_bmng_table_name     CONSTANT VARCHAR2(30 CHAR) := 'BMNG_BED_EA';
    g_bmng_column_pk1     CONSTANT VARCHAR2(30 CHAR) := 'ID_BMNG_ACTION';
    g_bmng_dep_table_name CONSTANT VARCHAR2(30 CHAR) := 'BMNG_DEPARTMENT_EA';
    g_bmng_dep_column_pk1 CONSTANT VARCHAR2(30 CHAR) := 'ID_DEPARTMENT';

    /* Package name */
    g_package_owner VARCHAR2(50 CHAR);
    g_package_name  VARCHAR2(50 CHAR);

    /* CONSTANTS */
    k_process_stats  CONSTANT VARCHAR2(30 CHAR) := 'PROCESS_STATISTICS';
    k_viewer_ea_proc CONSTANT VARCHAR2(30 CHAR) := 'ADMIN_98_VIEWER_EHR_EA';

END pk_data_gov_admin;
/
