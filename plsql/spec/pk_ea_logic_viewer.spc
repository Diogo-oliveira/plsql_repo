/*-- Last Change Revision: $Rev: 2028655 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:47:08 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_ea_logic_viewer IS
    -- This package provides Easy Access logic procedures to maintain the Viewer's EA table.
    -- @author Sérgio Santos
    -- @version 2.4.3-Denormalized

    /**
    * Inserts, Updates or Inserts a Patient (PK) in the Viewer EA table.
    *
    * @param i_lang               Language.
    * @param i_prof               Logged professional.
    * @param i_event_type         Type of event (UPDATE, INSERT, DELETE)
    * @param i_rowids             List of ROWIDs belonging to the changed records.
    * @param i_list_columns       List of columns that were changed
    * @param i_source_table_name  Name of the table that was changed.
    * @param i_dg_table_name      Name of the Data Governance table.
    *
    * @author Sérgio Santos
    * @version 2.4.3-Denormalized
    * @since 2008/09/25
    */
    PROCEDURE set_patient
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
    * Updates the NUM_PROBLEM, DESC_PROBLEM, DT_PROBLEM and DT_PROBLEM_FMT columns on the VIEWER_EHR_EA easy access table.
    *
    * @param i_lang               Language.
    * @param i_prof               Logged professional.
    * @param i_event_type         Type of event (UPDATE, INSERT, DELETE)
    * @param i_rowids             List of ROWIDs belonging to the changed records.
    * @param i_list_columns       List of columns that were changed
    * @param i_source_table_name  Name of the table that was changed.
    * @param i_dg_table_name      Name of the Data Governance table.
    *
    * @author Sérgio Santos
    * @version 2.4.3-Denormalized
    * @since 2008/11/21
    */
    PROCEDURE set_pat_problem
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_event_type        IN VARCHAR2,
        i_rowids            IN table_varchar,
        i_source_table_name IN VARCHAR2,
        i_list_columns      IN table_varchar,
        i_dg_table_name     IN VARCHAR2
    );

    /**
    * Updates the NUM_INTERV, DESC_INTERV, CODE_INTERV and DT_INTERV columns on the VIEWER_EHR_EA easy access table.
    *
    * @param i_lang               Language.
    * @param i_prof               Logged professional.
    * @param i_event_type         Type of event (UPDATE, INSERT, DELETE)
    * @param i_rowids             List of ROWIDs belonging to the changed records.
    * @param i_list_columns       List of columns that were changed
    * @param i_source_table_name  Name of the table that was changed.
    * @param i_dg_table_name      Name of the Data Governance table.
    *
    * @author Sérgio Santos
    * @version 2.4.3-Denormalized
    * @since 2008/12/10
    */
    PROCEDURE set_pat_interv
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_event_type        IN VARCHAR2,
        i_rowids            IN table_varchar,
        i_source_table_name IN VARCHAR2,
        i_list_columns      IN table_varchar,
        i_dg_table_name     IN VARCHAR2
    );

    /**
    * Updates the NUM_LAB, DESC_LAB, CODE_LAB and DT_LAB columns on the VIEWER_EHR_EA easy access table.
    *
    * @param i_lang               Language.
    * @param i_prof               Logged professional.
    * @param i_event_type         Type of event (UPDATE, INSERT, DELETE)
    * @param i_rowids             List of ROWIDs belonging to the changed records.
    * @param i_list_columns       List of columns that were changed
    * @param i_source_table_name  Name of the table that was changed.
    * @param i_dg_table_name      Name of the Data Governance table.
    *
    * @author Sérgio Santos
    * @version 2.4.3-Denormalized
    * @since 2008/12/11
    */
    PROCEDURE set_pat_lab
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_event_type        IN VARCHAR2,
        i_rowids            IN table_varchar,
        i_source_table_name IN VARCHAR2,
        i_list_columns      IN table_varchar,
        i_dg_table_name     IN VARCHAR2
    );

    /**
    * Updates the NUM_EPISODE, DESC_EPISODE, CODE_EPISODE and DT_EPISODE columns on the VIEWER_EHR_EA easy access table.
    *
    * @param i_lang               Language.
    * @param i_prof               Logged professional.
    * @param i_event_type         Type of event (UPDATE, INSERT, DELETE)
    * @param i_rowids             List of ROWIDs belonging to the changed records.
    * @param i_list_columns       List of columns that were changed
    * @param i_source_table_name  Name of the table that was changed.
    * @param i_dg_table_name      Name of the Data Governance table.
    *
    * @author Sérgio Santos
    * @version 2.4.3-Denormalized
    * @since 2008/12/11
    */
    PROCEDURE set_pat_episode
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_event_type        IN VARCHAR2,
        i_rowids            IN table_varchar,
        i_source_table_name IN VARCHAR2,
        i_list_columns      IN table_varchar,
        i_dg_table_name     IN VARCHAR2
    );

    /**
    * Updates the NUM_ARCHIVE, DESC_ARCHIVE, CODE_ARCHIVE and DT_ARCHIVE columns on the VIEWER_EHR_EA easy access table.
    *
    * @param i_lang               Language.
    * @param i_prof               Logged professional.
    * @param i_event_type         Type of event (UPDATE, INSERT, DELETE)
    * @param i_rowids             List of ROWIDs belonging to the changed records.
    * @param i_list_columns       List of columns that were changed
    * @param i_source_table_name  Name of the table that was changed.
    * @param i_dg_table_name      Name of the Data Governance table.
    *
    * @author Mário Mineiro
    * @version 2.6.4
    * @since 10-03-2014
    */
    PROCEDURE set_pat_archive
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_event_type        IN VARCHAR2,
        i_rowids            IN table_varchar,
        i_source_table_name IN VARCHAR2,
        i_list_columns      IN table_varchar,
        i_dg_table_name     IN VARCHAR2
    );

    /**
    * Updates the NUM_DIAG_ICNP, DESC_DIAG_ICNP, CODE_DIAG_ICNP and DT_DIAG_ICNP columns on the VIEWER_EHR_EA easy access table.
    *
    * @param i_lang               Language.
    * @param i_prof               Logged professional.
    * @param i_event_type         Type of event (UPDATE, INSERT, DELETE)
    * @param i_rowids             List of ROWIDs belonging to the changed records.
    * @param i_list_columns       List of columns that were changed
    * @param i_source_table_name  Name of the table that was changed.
    * @param i_dg_table_name      Name of the Data Governance table.
    *
    * @author Sérgio Santos
    * @version 2.4.3-Denormalized
    * @since 2008/12/12
    */
    PROCEDURE set_pat_diag_icnp
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_event_type        IN VARCHAR2,
        i_rowids            IN table_varchar,
        i_source_table_name IN VARCHAR2,
        i_list_columns      IN table_varchar,
        i_dg_table_name     IN VARCHAR2
    );

    /**
    * Updates the NUM_EXAM, DESC_EXAM, CODE_EXAM and DT_EXAM columns on the VIEWER_EHR_EA easy access table.
    *
    * @param i_lang               Language.
    * @param i_prof               Logged professional.
    * @param i_event_type         Type of event (UPDATE, INSERT, DELETE)
    * @param i_rowids             List of ROWIDs belonging to the changed records.
    * @param i_list_columns       List of columns that were changed
    * @param i_source_table_name  Name of the table that was changed.
    * @param i_dg_table_name      Name of the Data Governance table.
    *
    * @author Sérgio Santos
    * @version 2.4.3-Denormalized
    * @since 2008/12/12
    */
    PROCEDURE set_pat_exam
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_event_type        IN VARCHAR2,
        i_rowids            IN table_varchar,
        i_source_table_name IN VARCHAR2,
        i_list_columns      IN table_varchar,
        i_dg_table_name     IN VARCHAR2
    );

    /**
    * Updates the NUM_ALLERGY, DESC_ALLERGY, CODE_ALLERGY and DT_ALLERGY columns on the VIEWER_EHR_EA easy access table.
    *
    * @param i_lang               Language.
    * @param i_prof               Logged professional.
    * @param i_event_type         Type of event (UPDATE, INSERT, DELETE)
    * @param i_rowids             List of ROWIDs belonging to the changed records.
    * @param i_list_columns       List of columns that were changed
    * @param i_source_table_name  Name of the table that was changed.
    * @param i_dg_table_name      Name of the Data Governance table.
    *
    * @author Sérgio Santos
    * @version 2.4.3-Denormalized
    * @since 2009/13/01
    */
    PROCEDURE set_pat_allergy
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_event_type        IN VARCHAR2,
        i_rowids            IN table_varchar,
        i_source_table_name IN VARCHAR2,
        i_list_columns      IN table_varchar,
        i_dg_table_name     IN VARCHAR2
    );

    /**
    * Updates the NUM_MED, DESC_MED, CODE_MED and DT_MED columns on the VIEWER_EHR_EA easy access table.
    *
    * @param i_lang               Language.
    * @param i_prof               Logged professional.
    * @param i_event_type         Type of event (UPDATE, INSERT, DELETE)
    * @param i_rowids             List of ROWIDs belonging to the changed records.
    * @param i_list_columns       List of columns that were changed
    * @param i_source_table_name  Name of the table that was changed.
    * @param i_dg_table_name      Name of the Data Governance table.
    *
    * @author Sérgio Santos
    * @version 2.4.3-Denormalized
    * @since 2009/02/09
    */
    PROCEDURE set_pat_medication
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_event_type        IN VARCHAR2,
        i_rowids            IN table_varchar,
        i_source_table_name IN VARCHAR2,
        i_list_columns      IN table_varchar,
        i_dg_table_name     IN VARCHAR2
    );

    /**
    * Gets the number of allergies of a given patient
    *
    * @param i_lang               Language.
    * @param i_patient            The patient ID.
    *
    * @returns The number of allergies of the given patient
    *
    * @author Sérgio Santos
    * @version 2.4.3-Denormalized
    * @since 2008/09/29 
    */
    FUNCTION get_pat_num_allergies
    (
        i_lang    IN language.id_language%TYPE,
        i_patient IN patient.id_patient%TYPE
    ) RETURN NUMBER;

    /**
    * Gets the number of pending or inactive episodes of a given patient
    *
    * @param i_lang               Language.
    * @param i_patient            The patient ID.
    *
    * @returns The number of pending or inactive episodes of the given patient
    *
    * @author Sérgio Santos
    * @version 2.4.3-Denormalized
    * @since 2008/09/29 
    */
    FUNCTION get_pat_num_episodes
    (
        i_lang    IN language.id_language%TYPE,
        i_patient IN patient.id_patient%TYPE
    ) RETURN NUMBER;

    /**
    * Updates the NUM_VS, DESC_VS, DT_VS and DT_VS_FMT columns on the VIEWER_EHR_EA easy access table.
    *
    * @param i_lang               Language.
    * @param i_prof               Logged professional.
    * @param i_event_type         Type of event (UPDATE, INSERT, DELETE)
    * @param i_rowids             List of ROWIDs belonging to the changed records.
    * @param i_list_columns       List of columns that were changed
    * @param i_source_table_name  Name of the table that was changed.
    * @param i_dg_table_name      Name of the Data Governance table.
    *
    * @author Sérgio Santos
    * @version 2.4.3-Denormalized
    * @since 2008/11/21
    */
    PROCEDURE set_pat_vs
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_event_type        IN VARCHAR2,
        i_rowids            IN table_varchar,
        i_source_table_name IN VARCHAR2,
        i_list_columns      IN table_varchar,
        i_dg_table_name     IN VARCHAR2
    );

    /**
    * Updates the NUM_NOTE, DESC_NOTE, DT_NOTE and DT_NOTE_FMT columns on the VIEWER_EHR_EA easy access table.
    *
    * @param i_lang               Language.
    * @param i_prof               Logged professional.
    * @param i_event_type         Type of event (UPDATE, INSERT, DELETE)
    * @param i_rowids             List of ROWIDs belonging to the changed records.
    * @param i_list_columns       List of columns that were changed
    * @param i_source_table_name  Name of the table that was changed.
    * @param i_dg_table_name      Name of the Data Governance table.
    *
    * @author Sérgio Santos
    * @version 2.4.3-Denormalized
    * @since 2008/11/21
    */
    PROCEDURE set_pat_note
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_event_type        IN VARCHAR2,
        i_rowids            IN table_varchar,
        i_source_table_name IN VARCHAR2,
        i_list_columns      IN table_varchar,
        i_dg_table_name     IN VARCHAR2
    );

    PROCEDURE set_pat_bp
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_event_type        IN VARCHAR2,
        i_rowids            IN table_varchar,
        i_source_table_name IN VARCHAR2,
        i_list_columns      IN table_varchar,
        i_dg_table_name     IN VARCHAR2
    );

    ---------------------------------------- GLOBAL VALUES ----------------------------------------------

    /* Current timestamp */
    g_sysdate_tstz TIMESTAMP WITH TIME ZONE;

    /* Package name */
    g_package_name  VARCHAR2(32);
    g_package_owner VARCHAR2(32);

    /* Error tracking */
    g_error VARCHAR2(4000);
END pk_ea_logic_viewer;
/
