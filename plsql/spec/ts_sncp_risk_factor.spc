/*-- Last Change Revision: $Rev: 1658071 $*/
/*-- Last Change by: $Author: ariel.machado $*/
/*-- Date of last change: $Date: 2014-11-10 09:49:40 +0000 (seg, 10 nov 2014) $*/
CREATE OR REPLACE PACKAGE TS_SNCP_RISK_FACTOR
/*
| Generated by or retrieved from QCGU - DO NOT MODIFY!
| QCGU - "Get it right, do it fast" - www.ToadWorld.com
| QCGU Universal ID: {1BD37A66-EA60-4927-9A64-F6DD89237236}
| Created On: Outubro 3, 2013 16:39:6
| Created By: ALERT
*/
IS

  -- Collection of %ROWTYPE records based on "SNCP_RISK_FACTOR"
     TYPE SNCP_RISK_FACTOR_tc IS TABLE OF SNCP_RISK_FACTOR%ROWTYPE INDEX BY BINARY_INTEGER;
     TYPE sncp_risk_factor_ntt IS TABLE OF SNCP_RISK_FACTOR%ROWTYPE;
     TYPE sncp_risk_factor_vat IS VARRAY(100) OF SNCP_RISK_FACTOR%ROWTYPE;

  -- Same type structure, with a static name.
     TYPE aat IS TABLE OF SNCP_RISK_FACTOR%ROWTYPE INDEX BY BINARY_INTEGER;
     TYPE ntt IS TABLE OF SNCP_RISK_FACTOR%ROWTYPE;
     TYPE vat IS VARRAY(100) OF SNCP_RISK_FACTOR%ROWTYPE;

   -- Column Collection based on column "ID_SNCP_RISK_FACTOR"
   TYPE ID_SNCP_RISK_FACTOR_cc IS TABLE OF SNCP_RISK_FACTOR.ID_SNCP_RISK_FACTOR%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "ID_SNCP_DIAGNOSIS"
   TYPE ID_SNCP_DIAGNOSIS_cc IS TABLE OF SNCP_RISK_FACTOR.ID_SNCP_DIAGNOSIS%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "ID_NAN_RISK_FACTOR"
   TYPE ID_NAN_RISK_FACTOR_cc IS TABLE OF SNCP_RISK_FACTOR.ID_NAN_RISK_FACTOR%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "CREATE_USER"
   TYPE CREATE_USER_cc IS TABLE OF SNCP_RISK_FACTOR.CREATE_USER%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "CREATE_TIME"
   TYPE CREATE_TIME_cc IS TABLE OF SNCP_RISK_FACTOR.CREATE_TIME%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "CREATE_INSTITUTION"
   TYPE CREATE_INSTITUTION_cc IS TABLE OF SNCP_RISK_FACTOR.CREATE_INSTITUTION%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "UPDATE_USER"
   TYPE UPDATE_USER_cc IS TABLE OF SNCP_RISK_FACTOR.UPDATE_USER%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "UPDATE_TIME"
   TYPE UPDATE_TIME_cc IS TABLE OF SNCP_RISK_FACTOR.UPDATE_TIME%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "UPDATE_INSTITUTION"
   TYPE UPDATE_INSTITUTION_cc IS TABLE OF SNCP_RISK_FACTOR.UPDATE_INSTITUTION%TYPE INDEX BY BINARY_INTEGER;

   -- Insert one row, providing primary key if present
   PROCEDURE ins (
      id_sncp_risk_factor_in IN SNCP_RISK_FACTOR.ID_SNCP_RISK_FACTOR%TYPE
      ,
      id_sncp_diagnosis_in IN SNCP_RISK_FACTOR.ID_SNCP_DIAGNOSIS%TYPE DEFAULT NULL,
      id_nan_risk_factor_in IN SNCP_RISK_FACTOR.ID_NAN_RISK_FACTOR%TYPE DEFAULT NULL,
      create_user_in IN SNCP_RISK_FACTOR.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN SNCP_RISK_FACTOR.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN SNCP_RISK_FACTOR.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN SNCP_RISK_FACTOR.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN SNCP_RISK_FACTOR.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN SNCP_RISK_FACTOR.UPDATE_INSTITUTION%TYPE DEFAULT NULL
      -- Pass false if you want errors to propagate out unhandled
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      );

   PROCEDURE ins (
      id_sncp_risk_factor_in IN SNCP_RISK_FACTOR.ID_SNCP_RISK_FACTOR%TYPE
      ,
      id_sncp_diagnosis_in IN SNCP_RISK_FACTOR.ID_SNCP_DIAGNOSIS%TYPE DEFAULT NULL,
      id_nan_risk_factor_in IN SNCP_RISK_FACTOR.ID_NAN_RISK_FACTOR%TYPE DEFAULT NULL,
      create_user_in IN SNCP_RISK_FACTOR.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN SNCP_RISK_FACTOR.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN SNCP_RISK_FACTOR.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN SNCP_RISK_FACTOR.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN SNCP_RISK_FACTOR.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN SNCP_RISK_FACTOR.UPDATE_INSTITUTION%TYPE DEFAULT NULL
      -- Pass false if you want errors to propagate out unhandled
     ,handle_error_in IN BOOLEAN := TRUE
      );


   -- Insert a row based on a record.
   -- Specify whether or not a primary key value should be generated.
   PROCEDURE ins (
      rec_in IN SNCP_RISK_FACTOR%ROWTYPE
     ,gen_pky_in IN BOOLEAN DEFAULT FALSE
     ,sequence_in IN VARCHAR2 := NULL
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
   );

   PROCEDURE ins (
      rec_in IN SNCP_RISK_FACTOR%ROWTYPE
     ,gen_pky_in IN BOOLEAN DEFAULT FALSE
     ,sequence_in IN VARCHAR2 := NULL
     ,handle_error_in IN BOOLEAN := TRUE
   );

   -- Insert a collection of rows using FORALL; all primary key values
   -- must have already been generated, or are handled in triggers.
   PROCEDURE ins (
      rows_in IN SNCP_RISK_FACTOR_tc
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
   );

   PROCEDURE ins (
      rows_in IN SNCP_RISK_FACTOR_tc
     ,handle_error_in IN BOOLEAN := TRUE
   );

   -- Return next primary key value using the named sequence.
     FUNCTION next_key (sequence_in IN VARCHAR2 := NULL) RETURN SNCP_RISK_FACTOR.ID_SNCP_RISK_FACTOR%TYPE;

   -- Insert one row, generating hidden primary key using a sequence
   PROCEDURE ins (
      id_sncp_diagnosis_in IN SNCP_RISK_FACTOR.ID_SNCP_DIAGNOSIS%TYPE DEFAULT NULL,
      id_nan_risk_factor_in IN SNCP_RISK_FACTOR.ID_NAN_RISK_FACTOR%TYPE DEFAULT NULL,
      create_user_in IN SNCP_RISK_FACTOR.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN SNCP_RISK_FACTOR.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN SNCP_RISK_FACTOR.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN SNCP_RISK_FACTOR.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN SNCP_RISK_FACTOR.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN SNCP_RISK_FACTOR.UPDATE_INSTITUTION%TYPE DEFAULT NULL
      -- Pass false if you want errors to propagate out unhandled
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      );

   PROCEDURE ins (
      id_sncp_diagnosis_in IN SNCP_RISK_FACTOR.ID_SNCP_DIAGNOSIS%TYPE DEFAULT NULL,
      id_nan_risk_factor_in IN SNCP_RISK_FACTOR.ID_NAN_RISK_FACTOR%TYPE DEFAULT NULL,
      create_user_in IN SNCP_RISK_FACTOR.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN SNCP_RISK_FACTOR.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN SNCP_RISK_FACTOR.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN SNCP_RISK_FACTOR.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN SNCP_RISK_FACTOR.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN SNCP_RISK_FACTOR.UPDATE_INSTITUTION%TYPE DEFAULT NULL
      -- Pass false if you want errors to propagate out unhandled
     ,handle_error_in IN BOOLEAN := TRUE
      );

   -- Insert one row, returning primary key generated by sequence
   PROCEDURE ins (
      id_sncp_diagnosis_in IN SNCP_RISK_FACTOR.ID_SNCP_DIAGNOSIS%TYPE DEFAULT NULL,
      id_nan_risk_factor_in IN SNCP_RISK_FACTOR.ID_NAN_RISK_FACTOR%TYPE DEFAULT NULL,
      create_user_in IN SNCP_RISK_FACTOR.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN SNCP_RISK_FACTOR.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN SNCP_RISK_FACTOR.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN SNCP_RISK_FACTOR.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN SNCP_RISK_FACTOR.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN SNCP_RISK_FACTOR.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      id_sncp_risk_factor_out IN OUT SNCP_RISK_FACTOR.ID_SNCP_RISK_FACTOR%TYPE
      -- Pass false if you want errors to propagate out unhandled
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      );

   PROCEDURE ins (
      id_sncp_diagnosis_in IN SNCP_RISK_FACTOR.ID_SNCP_DIAGNOSIS%TYPE DEFAULT NULL,
      id_nan_risk_factor_in IN SNCP_RISK_FACTOR.ID_NAN_RISK_FACTOR%TYPE DEFAULT NULL,
      create_user_in IN SNCP_RISK_FACTOR.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN SNCP_RISK_FACTOR.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN SNCP_RISK_FACTOR.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN SNCP_RISK_FACTOR.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN SNCP_RISK_FACTOR.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN SNCP_RISK_FACTOR.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      id_sncp_risk_factor_out IN OUT SNCP_RISK_FACTOR.ID_SNCP_RISK_FACTOR%TYPE
      -- Pass false if you want errors to propagate out unhandled
     ,handle_error_in IN BOOLEAN := TRUE
      );

   -- Insert one row with function, return generated primary key
   FUNCTION ins (
      id_sncp_diagnosis_in IN SNCP_RISK_FACTOR.ID_SNCP_DIAGNOSIS%TYPE DEFAULT NULL,
      id_nan_risk_factor_in IN SNCP_RISK_FACTOR.ID_NAN_RISK_FACTOR%TYPE DEFAULT NULL,
      create_user_in IN SNCP_RISK_FACTOR.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN SNCP_RISK_FACTOR.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN SNCP_RISK_FACTOR.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN SNCP_RISK_FACTOR.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN SNCP_RISK_FACTOR.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN SNCP_RISK_FACTOR.UPDATE_INSTITUTION%TYPE DEFAULT NULL
      -- Pass false if you want errors to propagate out unhandled
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      )
      RETURN
         SNCP_RISK_FACTOR.ID_SNCP_RISK_FACTOR%TYPE
      ;

   FUNCTION ins (
      id_sncp_diagnosis_in IN SNCP_RISK_FACTOR.ID_SNCP_DIAGNOSIS%TYPE DEFAULT NULL,
      id_nan_risk_factor_in IN SNCP_RISK_FACTOR.ID_NAN_RISK_FACTOR%TYPE DEFAULT NULL,
      create_user_in IN SNCP_RISK_FACTOR.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN SNCP_RISK_FACTOR.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN SNCP_RISK_FACTOR.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN SNCP_RISK_FACTOR.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN SNCP_RISK_FACTOR.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN SNCP_RISK_FACTOR.UPDATE_INSTITUTION%TYPE DEFAULT NULL
      -- Pass false if you want errors to propagate out unhandled
     ,handle_error_in IN BOOLEAN := TRUE
      )
      RETURN
         SNCP_RISK_FACTOR.ID_SNCP_RISK_FACTOR%TYPE
      ;

   -- Update any/all columns by primary key. If you pass NULL, then
   -- the current column value is set to itself. If you need a more
   -- selected UPDATE then use one of the onecol procedures below.

  PROCEDURE upd (
      id_sncp_risk_factor_in IN SNCP_RISK_FACTOR.ID_SNCP_RISK_FACTOR%TYPE,
      id_sncp_diagnosis_in IN SNCP_RISK_FACTOR.ID_SNCP_DIAGNOSIS%TYPE DEFAULT NULL,
      ID_SNCP_DIAGNOSIS_nin IN BOOLEAN := TRUE,
      id_nan_risk_factor_in IN SNCP_RISK_FACTOR.ID_NAN_RISK_FACTOR%TYPE DEFAULT NULL,
      ID_NAN_RISK_FACTOR_nin IN BOOLEAN := TRUE,
      create_user_in IN SNCP_RISK_FACTOR.CREATE_USER%TYPE DEFAULT NULL,
      CREATE_USER_nin IN BOOLEAN := TRUE,
      create_time_in IN SNCP_RISK_FACTOR.CREATE_TIME%TYPE DEFAULT NULL,
      CREATE_TIME_nin IN BOOLEAN := TRUE,
      create_institution_in IN SNCP_RISK_FACTOR.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      CREATE_INSTITUTION_nin IN BOOLEAN := TRUE,
      update_user_in IN SNCP_RISK_FACTOR.UPDATE_USER%TYPE DEFAULT NULL,
      UPDATE_USER_nin IN BOOLEAN := TRUE,
      update_time_in IN SNCP_RISK_FACTOR.UPDATE_TIME%TYPE DEFAULT NULL,
      UPDATE_TIME_nin IN BOOLEAN := TRUE,
      update_institution_in IN SNCP_RISK_FACTOR.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      UPDATE_INSTITUTION_nin IN BOOLEAN := TRUE,
     handle_error_in IN BOOLEAN := TRUE
     , rows_out IN OUT TABLE_VARCHAR
      );


       PROCEDURE upd (
      id_sncp_risk_factor_in IN SNCP_RISK_FACTOR.ID_SNCP_RISK_FACTOR%TYPE,
      id_sncp_diagnosis_in IN SNCP_RISK_FACTOR.ID_SNCP_DIAGNOSIS%TYPE DEFAULT NULL,
      ID_SNCP_DIAGNOSIS_nin IN BOOLEAN := TRUE,
      id_nan_risk_factor_in IN SNCP_RISK_FACTOR.ID_NAN_RISK_FACTOR%TYPE DEFAULT NULL,
      ID_NAN_RISK_FACTOR_nin IN BOOLEAN := TRUE,
      create_user_in IN SNCP_RISK_FACTOR.CREATE_USER%TYPE DEFAULT NULL,
      CREATE_USER_nin IN BOOLEAN := TRUE,
      create_time_in IN SNCP_RISK_FACTOR.CREATE_TIME%TYPE DEFAULT NULL,
      CREATE_TIME_nin IN BOOLEAN := TRUE,
      create_institution_in IN SNCP_RISK_FACTOR.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      CREATE_INSTITUTION_nin IN BOOLEAN := TRUE,
      update_user_in IN SNCP_RISK_FACTOR.UPDATE_USER%TYPE DEFAULT NULL,
      UPDATE_USER_nin IN BOOLEAN := TRUE,
      update_time_in IN SNCP_RISK_FACTOR.UPDATE_TIME%TYPE DEFAULT NULL,
      UPDATE_TIME_nin IN BOOLEAN := TRUE,
      update_institution_in IN SNCP_RISK_FACTOR.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      UPDATE_INSTITUTION_nin IN BOOLEAN := TRUE,
     handle_error_in IN BOOLEAN := TRUE
      );



      PROCEDURE upd (
      id_sncp_diagnosis_in IN SNCP_RISK_FACTOR.ID_SNCP_DIAGNOSIS%TYPE DEFAULT NULL,
      ID_SNCP_DIAGNOSIS_nin IN BOOLEAN := TRUE,
      id_nan_risk_factor_in IN SNCP_RISK_FACTOR.ID_NAN_RISK_FACTOR%TYPE DEFAULT NULL,
      ID_NAN_RISK_FACTOR_nin IN BOOLEAN := TRUE,
      create_user_in IN SNCP_RISK_FACTOR.CREATE_USER%TYPE DEFAULT NULL,
      CREATE_USER_nin IN BOOLEAN := TRUE,
      create_time_in IN SNCP_RISK_FACTOR.CREATE_TIME%TYPE DEFAULT NULL,
      CREATE_TIME_nin IN BOOLEAN := TRUE,
      create_institution_in IN SNCP_RISK_FACTOR.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      CREATE_INSTITUTION_nin IN BOOLEAN := TRUE,
      update_user_in IN SNCP_RISK_FACTOR.UPDATE_USER%TYPE DEFAULT NULL,
      UPDATE_USER_nin IN BOOLEAN := TRUE,
      update_time_in IN SNCP_RISK_FACTOR.UPDATE_TIME%TYPE DEFAULT NULL,
      UPDATE_TIME_nin IN BOOLEAN := TRUE,
      update_institution_in IN SNCP_RISK_FACTOR.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      UPDATE_INSTITUTION_nin IN BOOLEAN := TRUE,
    where_in varchar2,
     handle_error_in IN BOOLEAN := TRUE
     , rows_out IN OUT TABLE_VARCHAR
      );


      PROCEDURE upd (
      id_sncp_diagnosis_in IN SNCP_RISK_FACTOR.ID_SNCP_DIAGNOSIS%TYPE DEFAULT NULL,
      ID_SNCP_DIAGNOSIS_nin IN BOOLEAN := TRUE,
      id_nan_risk_factor_in IN SNCP_RISK_FACTOR.ID_NAN_RISK_FACTOR%TYPE DEFAULT NULL,
      ID_NAN_RISK_FACTOR_nin IN BOOLEAN := TRUE,
      create_user_in IN SNCP_RISK_FACTOR.CREATE_USER%TYPE DEFAULT NULL,
      CREATE_USER_nin IN BOOLEAN := TRUE,
      create_time_in IN SNCP_RISK_FACTOR.CREATE_TIME%TYPE DEFAULT NULL,
      CREATE_TIME_nin IN BOOLEAN := TRUE,
      create_institution_in IN SNCP_RISK_FACTOR.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      CREATE_INSTITUTION_nin IN BOOLEAN := TRUE,
      update_user_in IN SNCP_RISK_FACTOR.UPDATE_USER%TYPE DEFAULT NULL,
      UPDATE_USER_nin IN BOOLEAN := TRUE,
      update_time_in IN SNCP_RISK_FACTOR.UPDATE_TIME%TYPE DEFAULT NULL,
      UPDATE_TIME_nin IN BOOLEAN := TRUE,
      update_institution_in IN SNCP_RISK_FACTOR.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      UPDATE_INSTITUTION_nin IN BOOLEAN := TRUE,
    where_in varchar2,
     handle_error_in IN BOOLEAN := TRUE
      );



   PROCEDURE upd_ins (
      id_sncp_risk_factor_in IN SNCP_RISK_FACTOR.ID_SNCP_RISK_FACTOR%TYPE,
      id_sncp_diagnosis_in IN SNCP_RISK_FACTOR.ID_SNCP_DIAGNOSIS%TYPE DEFAULT NULL,
      id_nan_risk_factor_in IN SNCP_RISK_FACTOR.ID_NAN_RISK_FACTOR%TYPE DEFAULT NULL,
      create_user_in IN SNCP_RISK_FACTOR.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN SNCP_RISK_FACTOR.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN SNCP_RISK_FACTOR.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN SNCP_RISK_FACTOR.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN SNCP_RISK_FACTOR.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN SNCP_RISK_FACTOR.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
     handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      );

      PROCEDURE upd_ins (
      id_sncp_risk_factor_in IN SNCP_RISK_FACTOR.ID_SNCP_RISK_FACTOR%TYPE,
      id_sncp_diagnosis_in IN SNCP_RISK_FACTOR.ID_SNCP_DIAGNOSIS%TYPE DEFAULT NULL,
      id_nan_risk_factor_in IN SNCP_RISK_FACTOR.ID_NAN_RISK_FACTOR%TYPE DEFAULT NULL,
      create_user_in IN SNCP_RISK_FACTOR.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN SNCP_RISK_FACTOR.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN SNCP_RISK_FACTOR.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN SNCP_RISK_FACTOR.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN SNCP_RISK_FACTOR.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN SNCP_RISK_FACTOR.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
     handle_error_in IN BOOLEAN := TRUE
      );

   PROCEDURE upd (
      rec_in IN SNCP_RISK_FACTOR%ROWTYPE,
     handle_error_in IN BOOLEAN := TRUE
     , rows_out IN OUT TABLE_VARCHAR
      );

      PROCEDURE upd (
      rec_in IN SNCP_RISK_FACTOR%ROWTYPE,
     handle_error_in IN BOOLEAN := TRUE
      );

      PROCEDURE upd (
      col_in IN SNCP_RISK_FACTOR_tc,
      ignore_if_null_in IN BOOLEAN := TRUE
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out IN OUT TABLE_VARCHAR
      );

      PROCEDURE upd (
      col_in IN SNCP_RISK_FACTOR_tc,
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
      id_sncp_risk_factor_in IN SNCP_RISK_FACTOR.ID_SNCP_RISK_FACTOR%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
      );

-- Delete one row by primary key
   PROCEDURE del (
      id_sncp_risk_factor_in IN SNCP_RISK_FACTOR.ID_SNCP_RISK_FACTOR%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      );


   -- Delete all rows for primary key column ID_SNCP_RISK_FACTOR
   PROCEDURE del_ID_SNCP_RISK_FACTOR (
      id_sncp_risk_factor_in IN SNCP_RISK_FACTOR.ID_SNCP_RISK_FACTOR%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
     );

     -- Delete all rows for primary key column ID_SNCP_RISK_FACTOR
   PROCEDURE del_ID_SNCP_RISK_FACTOR (
      id_sncp_risk_factor_in IN SNCP_RISK_FACTOR.ID_SNCP_RISK_FACTOR%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
     );

   -- Delete all rows for this SNCPRKF_NANRKF_FK foreign key value
   PROCEDURE del_SNCPRKF_NANRKF_FK (
      id_nan_risk_factor_in IN SNCP_RISK_FACTOR.ID_NAN_RISK_FACTOR%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
      );

      -- Delete all rows for this SNCPRKF_NANRKF_FK foreign key value
   PROCEDURE del_SNCPRKF_NANRKF_FK (
      id_nan_risk_factor_in IN SNCP_RISK_FACTOR.ID_NAN_RISK_FACTOR%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      );

   -- Delete all rows for this SNCPRKF_SNCPD_FK foreign key value
   PROCEDURE del_SNCPRKF_SNCPD_FK (
      id_sncp_diagnosis_in IN SNCP_RISK_FACTOR.ID_SNCP_DIAGNOSIS%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
      );

      -- Delete all rows for this SNCPRKF_SNCPD_FK foreign key value
   PROCEDURE del_SNCPRKF_SNCPD_FK (
      id_sncp_diagnosis_in IN SNCP_RISK_FACTOR.ID_SNCP_DIAGNOSIS%TYPE
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
      sncp_risk_factor_inout IN OUT SNCP_RISK_FACTOR%ROWTYPE
   );

   FUNCTION initrec RETURN SNCP_RISK_FACTOR%ROWTYPE;



   FUNCTION get_data_rowid(
        rows_in IN TABLE_VARCHAR
        ) RETURN SNCP_RISK_FACTOR_tc;


   FUNCTION get_data_rowid_pat(
        rows_in IN TABLE_VARCHAR
        ) RETURN SNCP_RISK_FACTOR_tc;

END TS_SNCP_RISK_FACTOR;
/
