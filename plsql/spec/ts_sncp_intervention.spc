/*-- Last Change Revision: $Rev: 1658071 $*/
/*-- Last Change by: $Author: ariel.machado $*/
/*-- Date of last change: $Date: 2014-11-10 09:49:40 +0000 (seg, 10 nov 2014) $*/
CREATE OR REPLACE PACKAGE TS_SNCP_INTERVENTION
/*
| Generated by or retrieved from QCGU - DO NOT MODIFY!
| QCGU - "Get it right, do it fast" - www.ToadWorld.com
| QCGU Universal ID: {1BD37A66-EA60-4927-9A64-F6DD89237236}
| Created On: Outubro 3, 2013 16:38:23
| Created By: ALERT
*/
IS

  -- Collection of %ROWTYPE records based on "SNCP_INTERVENTION"
     TYPE SNCP_INTERVENTION_tc IS TABLE OF SNCP_INTERVENTION%ROWTYPE INDEX BY BINARY_INTEGER;
     TYPE sncp_intervention_ntt IS TABLE OF SNCP_INTERVENTION%ROWTYPE;
     TYPE sncp_intervention_vat IS VARRAY(100) OF SNCP_INTERVENTION%ROWTYPE;

  -- Same type structure, with a static name.
     TYPE aat IS TABLE OF SNCP_INTERVENTION%ROWTYPE INDEX BY BINARY_INTEGER;
     TYPE ntt IS TABLE OF SNCP_INTERVENTION%ROWTYPE;
     TYPE vat IS VARRAY(100) OF SNCP_INTERVENTION%ROWTYPE;

   -- Column Collection based on column "ID_SNCP_INTERVENTION"
   TYPE ID_SNCP_INTERVENTION_cc IS TABLE OF SNCP_INTERVENTION.ID_SNCP_INTERVENTION%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "ID_NIC_INTERVENTION"
   TYPE ID_NIC_INTERVENTION_cc IS TABLE OF SNCP_INTERVENTION.ID_NIC_INTERVENTION%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "CREATE_USER"
   TYPE CREATE_USER_cc IS TABLE OF SNCP_INTERVENTION.CREATE_USER%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "CREATE_TIME"
   TYPE CREATE_TIME_cc IS TABLE OF SNCP_INTERVENTION.CREATE_TIME%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "CREATE_INSTITUTION"
   TYPE CREATE_INSTITUTION_cc IS TABLE OF SNCP_INTERVENTION.CREATE_INSTITUTION%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "UPDATE_USER"
   TYPE UPDATE_USER_cc IS TABLE OF SNCP_INTERVENTION.UPDATE_USER%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "UPDATE_TIME"
   TYPE UPDATE_TIME_cc IS TABLE OF SNCP_INTERVENTION.UPDATE_TIME%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "UPDATE_INSTITUTION"
   TYPE UPDATE_INSTITUTION_cc IS TABLE OF SNCP_INTERVENTION.UPDATE_INSTITUTION%TYPE INDEX BY BINARY_INTEGER;

   -- Insert one row, providing primary key if present
   PROCEDURE ins (
      id_sncp_intervention_in IN SNCP_INTERVENTION.ID_SNCP_INTERVENTION%TYPE
      ,
      id_nic_intervention_in IN SNCP_INTERVENTION.ID_NIC_INTERVENTION%TYPE DEFAULT NULL,
      create_user_in IN SNCP_INTERVENTION.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN SNCP_INTERVENTION.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN SNCP_INTERVENTION.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN SNCP_INTERVENTION.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN SNCP_INTERVENTION.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN SNCP_INTERVENTION.UPDATE_INSTITUTION%TYPE DEFAULT NULL
      -- Pass false if you want errors to propagate out unhandled
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      );

   PROCEDURE ins (
      id_sncp_intervention_in IN SNCP_INTERVENTION.ID_SNCP_INTERVENTION%TYPE
      ,
      id_nic_intervention_in IN SNCP_INTERVENTION.ID_NIC_INTERVENTION%TYPE DEFAULT NULL,
      create_user_in IN SNCP_INTERVENTION.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN SNCP_INTERVENTION.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN SNCP_INTERVENTION.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN SNCP_INTERVENTION.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN SNCP_INTERVENTION.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN SNCP_INTERVENTION.UPDATE_INSTITUTION%TYPE DEFAULT NULL
      -- Pass false if you want errors to propagate out unhandled
     ,handle_error_in IN BOOLEAN := TRUE
      );


   -- Insert a row based on a record.
   -- Specify whether or not a primary key value should be generated.
   PROCEDURE ins (
      rec_in IN SNCP_INTERVENTION%ROWTYPE
     ,gen_pky_in IN BOOLEAN DEFAULT FALSE
     ,sequence_in IN VARCHAR2 := NULL
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
   );

   PROCEDURE ins (
      rec_in IN SNCP_INTERVENTION%ROWTYPE
     ,gen_pky_in IN BOOLEAN DEFAULT FALSE
     ,sequence_in IN VARCHAR2 := NULL
     ,handle_error_in IN BOOLEAN := TRUE
   );

   -- Insert a collection of rows using FORALL; all primary key values
   -- must have already been generated, or are handled in triggers.
   PROCEDURE ins (
      rows_in IN SNCP_INTERVENTION_tc
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
   );

   PROCEDURE ins (
      rows_in IN SNCP_INTERVENTION_tc
     ,handle_error_in IN BOOLEAN := TRUE
   );

   -- Return next primary key value using the named sequence.
     FUNCTION next_key (sequence_in IN VARCHAR2 := NULL) RETURN SNCP_INTERVENTION.ID_SNCP_INTERVENTION%TYPE;

   -- Insert one row, generating hidden primary key using a sequence
   PROCEDURE ins (
      id_nic_intervention_in IN SNCP_INTERVENTION.ID_NIC_INTERVENTION%TYPE DEFAULT NULL,
      create_user_in IN SNCP_INTERVENTION.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN SNCP_INTERVENTION.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN SNCP_INTERVENTION.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN SNCP_INTERVENTION.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN SNCP_INTERVENTION.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN SNCP_INTERVENTION.UPDATE_INSTITUTION%TYPE DEFAULT NULL
      -- Pass false if you want errors to propagate out unhandled
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      );

   PROCEDURE ins (
      id_nic_intervention_in IN SNCP_INTERVENTION.ID_NIC_INTERVENTION%TYPE DEFAULT NULL,
      create_user_in IN SNCP_INTERVENTION.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN SNCP_INTERVENTION.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN SNCP_INTERVENTION.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN SNCP_INTERVENTION.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN SNCP_INTERVENTION.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN SNCP_INTERVENTION.UPDATE_INSTITUTION%TYPE DEFAULT NULL
      -- Pass false if you want errors to propagate out unhandled
     ,handle_error_in IN BOOLEAN := TRUE
      );

   -- Insert one row, returning primary key generated by sequence
   PROCEDURE ins (
      id_nic_intervention_in IN SNCP_INTERVENTION.ID_NIC_INTERVENTION%TYPE DEFAULT NULL,
      create_user_in IN SNCP_INTERVENTION.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN SNCP_INTERVENTION.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN SNCP_INTERVENTION.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN SNCP_INTERVENTION.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN SNCP_INTERVENTION.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN SNCP_INTERVENTION.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      id_sncp_intervention_out IN OUT SNCP_INTERVENTION.ID_SNCP_INTERVENTION%TYPE
      -- Pass false if you want errors to propagate out unhandled
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      );

   PROCEDURE ins (
      id_nic_intervention_in IN SNCP_INTERVENTION.ID_NIC_INTERVENTION%TYPE DEFAULT NULL,
      create_user_in IN SNCP_INTERVENTION.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN SNCP_INTERVENTION.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN SNCP_INTERVENTION.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN SNCP_INTERVENTION.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN SNCP_INTERVENTION.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN SNCP_INTERVENTION.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      id_sncp_intervention_out IN OUT SNCP_INTERVENTION.ID_SNCP_INTERVENTION%TYPE
      -- Pass false if you want errors to propagate out unhandled
     ,handle_error_in IN BOOLEAN := TRUE
      );

   -- Insert one row with function, return generated primary key
   FUNCTION ins (
      id_nic_intervention_in IN SNCP_INTERVENTION.ID_NIC_INTERVENTION%TYPE DEFAULT NULL,
      create_user_in IN SNCP_INTERVENTION.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN SNCP_INTERVENTION.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN SNCP_INTERVENTION.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN SNCP_INTERVENTION.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN SNCP_INTERVENTION.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN SNCP_INTERVENTION.UPDATE_INSTITUTION%TYPE DEFAULT NULL
      -- Pass false if you want errors to propagate out unhandled
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      )
      RETURN
         SNCP_INTERVENTION.ID_SNCP_INTERVENTION%TYPE
      ;

   FUNCTION ins (
      id_nic_intervention_in IN SNCP_INTERVENTION.ID_NIC_INTERVENTION%TYPE DEFAULT NULL,
      create_user_in IN SNCP_INTERVENTION.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN SNCP_INTERVENTION.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN SNCP_INTERVENTION.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN SNCP_INTERVENTION.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN SNCP_INTERVENTION.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN SNCP_INTERVENTION.UPDATE_INSTITUTION%TYPE DEFAULT NULL
      -- Pass false if you want errors to propagate out unhandled
     ,handle_error_in IN BOOLEAN := TRUE
      )
      RETURN
         SNCP_INTERVENTION.ID_SNCP_INTERVENTION%TYPE
      ;

   -- Update any/all columns by primary key. If you pass NULL, then
   -- the current column value is set to itself. If you need a more
   -- selected UPDATE then use one of the onecol procedures below.

  PROCEDURE upd (
      id_sncp_intervention_in IN SNCP_INTERVENTION.ID_SNCP_INTERVENTION%TYPE,
      id_nic_intervention_in IN SNCP_INTERVENTION.ID_NIC_INTERVENTION%TYPE DEFAULT NULL,
      ID_NIC_INTERVENTION_nin IN BOOLEAN := TRUE,
      create_user_in IN SNCP_INTERVENTION.CREATE_USER%TYPE DEFAULT NULL,
      CREATE_USER_nin IN BOOLEAN := TRUE,
      create_time_in IN SNCP_INTERVENTION.CREATE_TIME%TYPE DEFAULT NULL,
      CREATE_TIME_nin IN BOOLEAN := TRUE,
      create_institution_in IN SNCP_INTERVENTION.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      CREATE_INSTITUTION_nin IN BOOLEAN := TRUE,
      update_user_in IN SNCP_INTERVENTION.UPDATE_USER%TYPE DEFAULT NULL,
      UPDATE_USER_nin IN BOOLEAN := TRUE,
      update_time_in IN SNCP_INTERVENTION.UPDATE_TIME%TYPE DEFAULT NULL,
      UPDATE_TIME_nin IN BOOLEAN := TRUE,
      update_institution_in IN SNCP_INTERVENTION.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      UPDATE_INSTITUTION_nin IN BOOLEAN := TRUE,
     handle_error_in IN BOOLEAN := TRUE
     , rows_out IN OUT TABLE_VARCHAR
      );


       PROCEDURE upd (
      id_sncp_intervention_in IN SNCP_INTERVENTION.ID_SNCP_INTERVENTION%TYPE,
      id_nic_intervention_in IN SNCP_INTERVENTION.ID_NIC_INTERVENTION%TYPE DEFAULT NULL,
      ID_NIC_INTERVENTION_nin IN BOOLEAN := TRUE,
      create_user_in IN SNCP_INTERVENTION.CREATE_USER%TYPE DEFAULT NULL,
      CREATE_USER_nin IN BOOLEAN := TRUE,
      create_time_in IN SNCP_INTERVENTION.CREATE_TIME%TYPE DEFAULT NULL,
      CREATE_TIME_nin IN BOOLEAN := TRUE,
      create_institution_in IN SNCP_INTERVENTION.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      CREATE_INSTITUTION_nin IN BOOLEAN := TRUE,
      update_user_in IN SNCP_INTERVENTION.UPDATE_USER%TYPE DEFAULT NULL,
      UPDATE_USER_nin IN BOOLEAN := TRUE,
      update_time_in IN SNCP_INTERVENTION.UPDATE_TIME%TYPE DEFAULT NULL,
      UPDATE_TIME_nin IN BOOLEAN := TRUE,
      update_institution_in IN SNCP_INTERVENTION.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      UPDATE_INSTITUTION_nin IN BOOLEAN := TRUE,
     handle_error_in IN BOOLEAN := TRUE
      );



      PROCEDURE upd (
      id_nic_intervention_in IN SNCP_INTERVENTION.ID_NIC_INTERVENTION%TYPE DEFAULT NULL,
      ID_NIC_INTERVENTION_nin IN BOOLEAN := TRUE,
      create_user_in IN SNCP_INTERVENTION.CREATE_USER%TYPE DEFAULT NULL,
      CREATE_USER_nin IN BOOLEAN := TRUE,
      create_time_in IN SNCP_INTERVENTION.CREATE_TIME%TYPE DEFAULT NULL,
      CREATE_TIME_nin IN BOOLEAN := TRUE,
      create_institution_in IN SNCP_INTERVENTION.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      CREATE_INSTITUTION_nin IN BOOLEAN := TRUE,
      update_user_in IN SNCP_INTERVENTION.UPDATE_USER%TYPE DEFAULT NULL,
      UPDATE_USER_nin IN BOOLEAN := TRUE,
      update_time_in IN SNCP_INTERVENTION.UPDATE_TIME%TYPE DEFAULT NULL,
      UPDATE_TIME_nin IN BOOLEAN := TRUE,
      update_institution_in IN SNCP_INTERVENTION.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      UPDATE_INSTITUTION_nin IN BOOLEAN := TRUE,
    where_in varchar2,
     handle_error_in IN BOOLEAN := TRUE
     , rows_out IN OUT TABLE_VARCHAR
      );


      PROCEDURE upd (
      id_nic_intervention_in IN SNCP_INTERVENTION.ID_NIC_INTERVENTION%TYPE DEFAULT NULL,
      ID_NIC_INTERVENTION_nin IN BOOLEAN := TRUE,
      create_user_in IN SNCP_INTERVENTION.CREATE_USER%TYPE DEFAULT NULL,
      CREATE_USER_nin IN BOOLEAN := TRUE,
      create_time_in IN SNCP_INTERVENTION.CREATE_TIME%TYPE DEFAULT NULL,
      CREATE_TIME_nin IN BOOLEAN := TRUE,
      create_institution_in IN SNCP_INTERVENTION.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      CREATE_INSTITUTION_nin IN BOOLEAN := TRUE,
      update_user_in IN SNCP_INTERVENTION.UPDATE_USER%TYPE DEFAULT NULL,
      UPDATE_USER_nin IN BOOLEAN := TRUE,
      update_time_in IN SNCP_INTERVENTION.UPDATE_TIME%TYPE DEFAULT NULL,
      UPDATE_TIME_nin IN BOOLEAN := TRUE,
      update_institution_in IN SNCP_INTERVENTION.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      UPDATE_INSTITUTION_nin IN BOOLEAN := TRUE,
    where_in varchar2,
     handle_error_in IN BOOLEAN := TRUE
      );



   PROCEDURE upd_ins (
      id_sncp_intervention_in IN SNCP_INTERVENTION.ID_SNCP_INTERVENTION%TYPE,
      id_nic_intervention_in IN SNCP_INTERVENTION.ID_NIC_INTERVENTION%TYPE DEFAULT NULL,
      create_user_in IN SNCP_INTERVENTION.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN SNCP_INTERVENTION.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN SNCP_INTERVENTION.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN SNCP_INTERVENTION.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN SNCP_INTERVENTION.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN SNCP_INTERVENTION.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
     handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      );

      PROCEDURE upd_ins (
      id_sncp_intervention_in IN SNCP_INTERVENTION.ID_SNCP_INTERVENTION%TYPE,
      id_nic_intervention_in IN SNCP_INTERVENTION.ID_NIC_INTERVENTION%TYPE DEFAULT NULL,
      create_user_in IN SNCP_INTERVENTION.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN SNCP_INTERVENTION.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN SNCP_INTERVENTION.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN SNCP_INTERVENTION.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN SNCP_INTERVENTION.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN SNCP_INTERVENTION.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
     handle_error_in IN BOOLEAN := TRUE
      );

   PROCEDURE upd (
      rec_in IN SNCP_INTERVENTION%ROWTYPE,
     handle_error_in IN BOOLEAN := TRUE
     , rows_out IN OUT TABLE_VARCHAR
      );

      PROCEDURE upd (
      rec_in IN SNCP_INTERVENTION%ROWTYPE,
     handle_error_in IN BOOLEAN := TRUE
      );

      PROCEDURE upd (
      col_in IN SNCP_INTERVENTION_tc,
      ignore_if_null_in IN BOOLEAN := TRUE
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out IN OUT TABLE_VARCHAR
      );

      PROCEDURE upd (
      col_in IN SNCP_INTERVENTION_tc,
      ignore_if_null_in IN BOOLEAN := TRUE
     ,handle_error_in IN BOOLEAN := TRUE
      );





   -- Use Native Dynamic SQL increment a single NUMBER column
   -- for all rows specified by the dynamic WHERE clause
   PROCEDURE increment_onecol (
      colname_in IN ALL_TAB_COLUMNS.COLUMN_NAME%TYPE,
      where_in IN VARCHAR2 := NULL
      , increment_value_in IN NUMBER DEFAULT 1
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
   );

   PROCEDURE increment_onecol (
      colname_in IN ALL_TAB_COLUMNS.COLUMN_NAME%TYPE,
      where_in IN VARCHAR2 := NULL
      , increment_value_in IN NUMBER DEFAULT 1
     ,handle_error_in IN BOOLEAN := TRUE
   );









    -- Delete one row by primary key
   PROCEDURE del (
      id_sncp_intervention_in IN SNCP_INTERVENTION.ID_SNCP_INTERVENTION%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
      );

-- Delete one row by primary key
   PROCEDURE del (
      id_sncp_intervention_in IN SNCP_INTERVENTION.ID_SNCP_INTERVENTION%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      );


   -- Delete all rows for primary key column ID_SNCP_INTERVENTION
   PROCEDURE del_ID_SNCP_INTERVENTION (
      id_sncp_intervention_in IN SNCP_INTERVENTION.ID_SNCP_INTERVENTION%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
     );

     -- Delete all rows for primary key column ID_SNCP_INTERVENTION
   PROCEDURE del_ID_SNCP_INTERVENTION (
      id_sncp_intervention_in IN SNCP_INTERVENTION.ID_SNCP_INTERVENTION%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
     );

   -- Delete all rows for this SNCPINT_NICI_FK foreign key value
   PROCEDURE del_SNCPINT_NICI_FK (
      id_nic_intervention_in IN SNCP_INTERVENTION.ID_NIC_INTERVENTION%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
      );

      -- Delete all rows for this SNCPINT_NICI_FK foreign key value
   PROCEDURE del_SNCPINT_NICI_FK (
      id_nic_intervention_in IN SNCP_INTERVENTION.ID_NIC_INTERVENTION%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      );

    -- Delete all rows specified by dynamic WHERE clause
   PROCEDURE del_by (
      where_clause_in IN VARCHAR2
     ,handle_error_in IN BOOLEAN := TRUE
      );

      -- Delete all rows specified by dynamic WHERE clause
   PROCEDURE del_by (
      where_clause_in IN VARCHAR2
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      );

    -- Delete all rows where the specified VARCHAR2 column has
   -- a value that matches the specfified value.
   PROCEDURE del_by_col (
      colname_in IN VARCHAR2,
      colvalue_in IN VARCHAR2
     ,handle_error_in IN BOOLEAN := TRUE
      );


      -- Delete all rows where the specified VARCHAR2 column has
   -- a value that matches the specfified value.
   PROCEDURE del_by_col (
      colname_in IN VARCHAR2,
      colvalue_in IN VARCHAR2
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      );

    -- Delete all rows where the specified DATE column has
   -- a value that matches the specfified value.
   PROCEDURE del_by_col (
      colname_in IN VARCHAR2,
      colvalue_in IN DATE
     ,handle_error_in IN BOOLEAN := TRUE
      );

      -- Delete all rows where the specified DATE column has
   -- a value that matches the specfified value.
   PROCEDURE del_by_col (
      colname_in IN VARCHAR2,
      colvalue_in IN DATE
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      );


      -- Delete all rows where the specified TIMESTAMP column has
   -- a value that matches the specfified value.
   PROCEDURE del_by_col (
      colname_in IN VARCHAR2,
      colvalue_in IN TIMESTAMP WITH LOCAL TIME ZONE
     ,handle_error_in IN BOOLEAN := TRUE
      );

      -- Delete all rows where the specified TIMESTAMP column has
   -- a value that matches the specfified value.
   PROCEDURE del_by_col (
      colname_in IN VARCHAR2,
      colvalue_in IN TIMESTAMP WITH LOCAL TIME ZONE
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      );

    -- Delete all rows where the specified NUMBER column has
   -- a value that matches the specfified value.
   PROCEDURE del_by_col (
      colname_in IN VARCHAR2,
      colvalue_in IN NUMBER
     ,handle_error_in IN BOOLEAN := TRUE
      );

      -- Delete all rows where the specified NUMBER column has
   -- a value that matches the specfified value.
   PROCEDURE del_by_col (
      colname_in IN VARCHAR2,
      colvalue_in IN NUMBER
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      );

   -- Initialize a record with default values for columns in the table.
   PROCEDURE initrec (
      sncp_intervention_inout IN OUT SNCP_INTERVENTION%ROWTYPE
   );

   FUNCTION initrec RETURN SNCP_INTERVENTION%ROWTYPE;



   FUNCTION get_data_rowid(
        rows_in IN TABLE_VARCHAR
        ) RETURN SNCP_INTERVENTION_tc;


   FUNCTION get_data_rowid_pat(
        rows_in IN TABLE_VARCHAR
        ) RETURN SNCP_INTERVENTION_tc;

END TS_SNCP_INTERVENTION;
/