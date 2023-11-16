/*-- Last Change Revision: $Rev: 1303515 $*/
/*-- Last Change by: $Author: sofia.mendes $*/
/*-- Date of last change: $Date: 2012-05-17 15:29:11 +0100 (qui, 17 mai 2012) $*/
CREATE OR REPLACE PACKAGE TS_TREATMENT_MANAGEMENT
/*
| Generated by or retrieved from QCGU - DO NOT MODIFY!
| QCGU - "Get it right, do it fast" - www.ToadWorld.com
| QCGU Universal ID: {1BD37A66-EA60-4927-9A64-F6DD89237236}
| Created On: Maio 17, 2012 12:20:13
| Created By: ALERT
*/
IS

  -- Collection of %ROWTYPE records based on "TREATMENT_MANAGEMENT"
     TYPE TREATMENT_MANAGEMENT_tc IS TABLE OF TREATMENT_MANAGEMENT%ROWTYPE INDEX BY BINARY_INTEGER;
     TYPE treatment_management_ntt IS TABLE OF TREATMENT_MANAGEMENT%ROWTYPE;
     TYPE treatment_management_vat IS VARRAY(100) OF TREATMENT_MANAGEMENT%ROWTYPE;

  -- Same type structure, with a static name.
     TYPE aat IS TABLE OF TREATMENT_MANAGEMENT%ROWTYPE INDEX BY BINARY_INTEGER;
     TYPE ntt IS TABLE OF TREATMENT_MANAGEMENT%ROWTYPE;
     TYPE vat IS VARRAY(100) OF TREATMENT_MANAGEMENT%ROWTYPE;

   -- Column Collection based on column "ID_TREATMENT_MANAGEMENT"
   TYPE ID_TREATMENT_MANAGEMENT_cc IS TABLE OF TREATMENT_MANAGEMENT.ID_TREATMENT_MANAGEMENT%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "ID_TREATMENT"
   TYPE ID_TREATMENT_cc IS TABLE OF TREATMENT_MANAGEMENT.ID_TREATMENT%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "DESC_TREATMENT_MANAGEMENT"
   TYPE DESC_TREATMENT_MANAGEMENT_cc IS TABLE OF TREATMENT_MANAGEMENT.DESC_TREATMENT_MANAGEMENT%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "ID_PROFESSIONAL"
   TYPE ID_PROFESSIONAL_cc IS TABLE OF TREATMENT_MANAGEMENT.ID_PROFESSIONAL%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "FLG_TYPE"
   TYPE FLG_TYPE_cc IS TABLE OF TREATMENT_MANAGEMENT.FLG_TYPE%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "DT_CREATION_TSTZ"
   TYPE DT_CREATION_TSTZ_cc IS TABLE OF TREATMENT_MANAGEMENT.DT_CREATION_TSTZ%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "CREATE_USER"
   TYPE CREATE_USER_cc IS TABLE OF TREATMENT_MANAGEMENT.CREATE_USER%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "CREATE_TIME"
   TYPE CREATE_TIME_cc IS TABLE OF TREATMENT_MANAGEMENT.CREATE_TIME%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "CREATE_INSTITUTION"
   TYPE CREATE_INSTITUTION_cc IS TABLE OF TREATMENT_MANAGEMENT.CREATE_INSTITUTION%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "UPDATE_USER"
   TYPE UPDATE_USER_cc IS TABLE OF TREATMENT_MANAGEMENT.UPDATE_USER%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "UPDATE_TIME"
   TYPE UPDATE_TIME_cc IS TABLE OF TREATMENT_MANAGEMENT.UPDATE_TIME%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "UPDATE_INSTITUTION"
   TYPE UPDATE_INSTITUTION_cc IS TABLE OF TREATMENT_MANAGEMENT.UPDATE_INSTITUTION%TYPE INDEX BY BINARY_INTEGER;

   -- Insert one row, providing primary key if present
   PROCEDURE ins (
      id_treatment_management_in IN TREATMENT_MANAGEMENT.ID_TREATMENT_MANAGEMENT%TYPE
      ,
      id_treatment_in IN TREATMENT_MANAGEMENT.ID_TREATMENT%TYPE DEFAULT NULL,
      desc_treatment_management_in IN TREATMENT_MANAGEMENT.DESC_TREATMENT_MANAGEMENT%TYPE DEFAULT NULL,
      id_professional_in IN TREATMENT_MANAGEMENT.ID_PROFESSIONAL%TYPE DEFAULT NULL,
      flg_type_in IN TREATMENT_MANAGEMENT.FLG_TYPE%TYPE DEFAULT NULL,
      dt_creation_tstz_in IN TREATMENT_MANAGEMENT.DT_CREATION_TSTZ%TYPE DEFAULT NULL,
      create_user_in IN TREATMENT_MANAGEMENT.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN TREATMENT_MANAGEMENT.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN TREATMENT_MANAGEMENT.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN TREATMENT_MANAGEMENT.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN TREATMENT_MANAGEMENT.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN TREATMENT_MANAGEMENT.UPDATE_INSTITUTION%TYPE DEFAULT NULL
      -- Pass false if you want errors to propagate out unhandled
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      );

   PROCEDURE ins (
      id_treatment_management_in IN TREATMENT_MANAGEMENT.ID_TREATMENT_MANAGEMENT%TYPE
      ,
      id_treatment_in IN TREATMENT_MANAGEMENT.ID_TREATMENT%TYPE DEFAULT NULL,
      desc_treatment_management_in IN TREATMENT_MANAGEMENT.DESC_TREATMENT_MANAGEMENT%TYPE DEFAULT NULL,
      id_professional_in IN TREATMENT_MANAGEMENT.ID_PROFESSIONAL%TYPE DEFAULT NULL,
      flg_type_in IN TREATMENT_MANAGEMENT.FLG_TYPE%TYPE DEFAULT NULL,
      dt_creation_tstz_in IN TREATMENT_MANAGEMENT.DT_CREATION_TSTZ%TYPE DEFAULT NULL,
      create_user_in IN TREATMENT_MANAGEMENT.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN TREATMENT_MANAGEMENT.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN TREATMENT_MANAGEMENT.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN TREATMENT_MANAGEMENT.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN TREATMENT_MANAGEMENT.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN TREATMENT_MANAGEMENT.UPDATE_INSTITUTION%TYPE DEFAULT NULL
      -- Pass false if you want errors to propagate out unhandled
     ,handle_error_in IN BOOLEAN := TRUE
      );


   -- Insert a row based on a record.
   -- Specify whether or not a primary key value should be generated.
   PROCEDURE ins (
      rec_in IN TREATMENT_MANAGEMENT%ROWTYPE
     ,gen_pky_in IN BOOLEAN DEFAULT FALSE
     ,sequence_in IN VARCHAR2 := NULL
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
   );

   PROCEDURE ins (
      rec_in IN TREATMENT_MANAGEMENT%ROWTYPE
     ,gen_pky_in IN BOOLEAN DEFAULT FALSE
     ,sequence_in IN VARCHAR2 := NULL
     ,handle_error_in IN BOOLEAN := TRUE
   );

   -- Insert a collection of rows using FORALL; all primary key values
   -- must have already been generated, or are handled in triggers.
   PROCEDURE ins (
      rows_in IN TREATMENT_MANAGEMENT_tc
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
   );

   PROCEDURE ins (
      rows_in IN TREATMENT_MANAGEMENT_tc
     ,handle_error_in IN BOOLEAN := TRUE
   );

   -- Return next primary key value using the named sequence.
     FUNCTION next_key (sequence_in IN VARCHAR2 := NULL) RETURN TREATMENT_MANAGEMENT.ID_TREATMENT_MANAGEMENT%TYPE;

   -- Insert one row, generating hidden primary key using a sequence
   PROCEDURE ins (
      id_treatment_in IN TREATMENT_MANAGEMENT.ID_TREATMENT%TYPE DEFAULT NULL,
      desc_treatment_management_in IN TREATMENT_MANAGEMENT.DESC_TREATMENT_MANAGEMENT%TYPE DEFAULT NULL,
      id_professional_in IN TREATMENT_MANAGEMENT.ID_PROFESSIONAL%TYPE DEFAULT NULL,
      flg_type_in IN TREATMENT_MANAGEMENT.FLG_TYPE%TYPE DEFAULT NULL,
      dt_creation_tstz_in IN TREATMENT_MANAGEMENT.DT_CREATION_TSTZ%TYPE DEFAULT NULL,
      create_user_in IN TREATMENT_MANAGEMENT.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN TREATMENT_MANAGEMENT.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN TREATMENT_MANAGEMENT.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN TREATMENT_MANAGEMENT.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN TREATMENT_MANAGEMENT.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN TREATMENT_MANAGEMENT.UPDATE_INSTITUTION%TYPE DEFAULT NULL
      -- Pass false if you want errors to propagate out unhandled
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      );

   PROCEDURE ins (
      id_treatment_in IN TREATMENT_MANAGEMENT.ID_TREATMENT%TYPE DEFAULT NULL,
      desc_treatment_management_in IN TREATMENT_MANAGEMENT.DESC_TREATMENT_MANAGEMENT%TYPE DEFAULT NULL,
      id_professional_in IN TREATMENT_MANAGEMENT.ID_PROFESSIONAL%TYPE DEFAULT NULL,
      flg_type_in IN TREATMENT_MANAGEMENT.FLG_TYPE%TYPE DEFAULT NULL,
      dt_creation_tstz_in IN TREATMENT_MANAGEMENT.DT_CREATION_TSTZ%TYPE DEFAULT NULL,
      create_user_in IN TREATMENT_MANAGEMENT.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN TREATMENT_MANAGEMENT.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN TREATMENT_MANAGEMENT.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN TREATMENT_MANAGEMENT.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN TREATMENT_MANAGEMENT.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN TREATMENT_MANAGEMENT.UPDATE_INSTITUTION%TYPE DEFAULT NULL
      -- Pass false if you want errors to propagate out unhandled
     ,handle_error_in IN BOOLEAN := TRUE
      );

   -- Insert one row, returning primary key generated by sequence
   PROCEDURE ins (
      id_treatment_in IN TREATMENT_MANAGEMENT.ID_TREATMENT%TYPE DEFAULT NULL,
      desc_treatment_management_in IN TREATMENT_MANAGEMENT.DESC_TREATMENT_MANAGEMENT%TYPE DEFAULT NULL,
      id_professional_in IN TREATMENT_MANAGEMENT.ID_PROFESSIONAL%TYPE DEFAULT NULL,
      flg_type_in IN TREATMENT_MANAGEMENT.FLG_TYPE%TYPE DEFAULT NULL,
      dt_creation_tstz_in IN TREATMENT_MANAGEMENT.DT_CREATION_TSTZ%TYPE DEFAULT NULL,
      create_user_in IN TREATMENT_MANAGEMENT.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN TREATMENT_MANAGEMENT.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN TREATMENT_MANAGEMENT.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN TREATMENT_MANAGEMENT.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN TREATMENT_MANAGEMENT.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN TREATMENT_MANAGEMENT.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      id_treatment_management_out IN OUT TREATMENT_MANAGEMENT.ID_TREATMENT_MANAGEMENT%TYPE
      -- Pass false if you want errors to propagate out unhandled
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      );

   PROCEDURE ins (
      id_treatment_in IN TREATMENT_MANAGEMENT.ID_TREATMENT%TYPE DEFAULT NULL,
      desc_treatment_management_in IN TREATMENT_MANAGEMENT.DESC_TREATMENT_MANAGEMENT%TYPE DEFAULT NULL,
      id_professional_in IN TREATMENT_MANAGEMENT.ID_PROFESSIONAL%TYPE DEFAULT NULL,
      flg_type_in IN TREATMENT_MANAGEMENT.FLG_TYPE%TYPE DEFAULT NULL,
      dt_creation_tstz_in IN TREATMENT_MANAGEMENT.DT_CREATION_TSTZ%TYPE DEFAULT NULL,
      create_user_in IN TREATMENT_MANAGEMENT.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN TREATMENT_MANAGEMENT.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN TREATMENT_MANAGEMENT.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN TREATMENT_MANAGEMENT.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN TREATMENT_MANAGEMENT.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN TREATMENT_MANAGEMENT.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      id_treatment_management_out IN OUT TREATMENT_MANAGEMENT.ID_TREATMENT_MANAGEMENT%TYPE
      -- Pass false if you want errors to propagate out unhandled
     ,handle_error_in IN BOOLEAN := TRUE
      );

   -- Insert one row with function, return generated primary key
   FUNCTION ins (
      id_treatment_in IN TREATMENT_MANAGEMENT.ID_TREATMENT%TYPE DEFAULT NULL,
      desc_treatment_management_in IN TREATMENT_MANAGEMENT.DESC_TREATMENT_MANAGEMENT%TYPE DEFAULT NULL,
      id_professional_in IN TREATMENT_MANAGEMENT.ID_PROFESSIONAL%TYPE DEFAULT NULL,
      flg_type_in IN TREATMENT_MANAGEMENT.FLG_TYPE%TYPE DEFAULT NULL,
      dt_creation_tstz_in IN TREATMENT_MANAGEMENT.DT_CREATION_TSTZ%TYPE DEFAULT NULL,
      create_user_in IN TREATMENT_MANAGEMENT.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN TREATMENT_MANAGEMENT.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN TREATMENT_MANAGEMENT.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN TREATMENT_MANAGEMENT.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN TREATMENT_MANAGEMENT.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN TREATMENT_MANAGEMENT.UPDATE_INSTITUTION%TYPE DEFAULT NULL
      -- Pass false if you want errors to propagate out unhandled
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      )
      RETURN
         TREATMENT_MANAGEMENT.ID_TREATMENT_MANAGEMENT%TYPE
      ;

   FUNCTION ins (
      id_treatment_in IN TREATMENT_MANAGEMENT.ID_TREATMENT%TYPE DEFAULT NULL,
      desc_treatment_management_in IN TREATMENT_MANAGEMENT.DESC_TREATMENT_MANAGEMENT%TYPE DEFAULT NULL,
      id_professional_in IN TREATMENT_MANAGEMENT.ID_PROFESSIONAL%TYPE DEFAULT NULL,
      flg_type_in IN TREATMENT_MANAGEMENT.FLG_TYPE%TYPE DEFAULT NULL,
      dt_creation_tstz_in IN TREATMENT_MANAGEMENT.DT_CREATION_TSTZ%TYPE DEFAULT NULL,
      create_user_in IN TREATMENT_MANAGEMENT.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN TREATMENT_MANAGEMENT.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN TREATMENT_MANAGEMENT.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN TREATMENT_MANAGEMENT.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN TREATMENT_MANAGEMENT.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN TREATMENT_MANAGEMENT.UPDATE_INSTITUTION%TYPE DEFAULT NULL
      -- Pass false if you want errors to propagate out unhandled
     ,handle_error_in IN BOOLEAN := TRUE
      )
      RETURN
         TREATMENT_MANAGEMENT.ID_TREATMENT_MANAGEMENT%TYPE
      ;

   -- Update any/all columns by primary key. If you pass NULL, then
   -- the current column value is set to itself. If you need a more
   -- selected UPDATE then use one of the onecol procedures below.

  PROCEDURE upd (
      id_treatment_management_in IN TREATMENT_MANAGEMENT.ID_TREATMENT_MANAGEMENT%TYPE,
      id_treatment_in IN TREATMENT_MANAGEMENT.ID_TREATMENT%TYPE DEFAULT NULL,
      ID_TREATMENT_nin IN BOOLEAN := TRUE,
      desc_treatment_management_in IN TREATMENT_MANAGEMENT.DESC_TREATMENT_MANAGEMENT%TYPE DEFAULT NULL,
      DESC_TREATMENT_MANAGEMENT_nin IN BOOLEAN := TRUE,
      id_professional_in IN TREATMENT_MANAGEMENT.ID_PROFESSIONAL%TYPE DEFAULT NULL,
      ID_PROFESSIONAL_nin IN BOOLEAN := TRUE,
      flg_type_in IN TREATMENT_MANAGEMENT.FLG_TYPE%TYPE DEFAULT NULL,
      FLG_TYPE_nin IN BOOLEAN := TRUE,
      dt_creation_tstz_in IN TREATMENT_MANAGEMENT.DT_CREATION_TSTZ%TYPE DEFAULT NULL,
      DT_CREATION_TSTZ_nin IN BOOLEAN := TRUE,
      create_user_in IN TREATMENT_MANAGEMENT.CREATE_USER%TYPE DEFAULT NULL,
      CREATE_USER_nin IN BOOLEAN := TRUE,
      create_time_in IN TREATMENT_MANAGEMENT.CREATE_TIME%TYPE DEFAULT NULL,
      CREATE_TIME_nin IN BOOLEAN := TRUE,
      create_institution_in IN TREATMENT_MANAGEMENT.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      CREATE_INSTITUTION_nin IN BOOLEAN := TRUE,
      update_user_in IN TREATMENT_MANAGEMENT.UPDATE_USER%TYPE DEFAULT NULL,
      UPDATE_USER_nin IN BOOLEAN := TRUE,
      update_time_in IN TREATMENT_MANAGEMENT.UPDATE_TIME%TYPE DEFAULT NULL,
      UPDATE_TIME_nin IN BOOLEAN := TRUE,
      update_institution_in IN TREATMENT_MANAGEMENT.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      UPDATE_INSTITUTION_nin IN BOOLEAN := TRUE,
     handle_error_in IN BOOLEAN := TRUE
     , rows_out IN OUT TABLE_VARCHAR
      );


       PROCEDURE upd (
      id_treatment_management_in IN TREATMENT_MANAGEMENT.ID_TREATMENT_MANAGEMENT%TYPE,
      id_treatment_in IN TREATMENT_MANAGEMENT.ID_TREATMENT%TYPE DEFAULT NULL,
      ID_TREATMENT_nin IN BOOLEAN := TRUE,
      desc_treatment_management_in IN TREATMENT_MANAGEMENT.DESC_TREATMENT_MANAGEMENT%TYPE DEFAULT NULL,
      DESC_TREATMENT_MANAGEMENT_nin IN BOOLEAN := TRUE,
      id_professional_in IN TREATMENT_MANAGEMENT.ID_PROFESSIONAL%TYPE DEFAULT NULL,
      ID_PROFESSIONAL_nin IN BOOLEAN := TRUE,
      flg_type_in IN TREATMENT_MANAGEMENT.FLG_TYPE%TYPE DEFAULT NULL,
      FLG_TYPE_nin IN BOOLEAN := TRUE,
      dt_creation_tstz_in IN TREATMENT_MANAGEMENT.DT_CREATION_TSTZ%TYPE DEFAULT NULL,
      DT_CREATION_TSTZ_nin IN BOOLEAN := TRUE,
      create_user_in IN TREATMENT_MANAGEMENT.CREATE_USER%TYPE DEFAULT NULL,
      CREATE_USER_nin IN BOOLEAN := TRUE,
      create_time_in IN TREATMENT_MANAGEMENT.CREATE_TIME%TYPE DEFAULT NULL,
      CREATE_TIME_nin IN BOOLEAN := TRUE,
      create_institution_in IN TREATMENT_MANAGEMENT.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      CREATE_INSTITUTION_nin IN BOOLEAN := TRUE,
      update_user_in IN TREATMENT_MANAGEMENT.UPDATE_USER%TYPE DEFAULT NULL,
      UPDATE_USER_nin IN BOOLEAN := TRUE,
      update_time_in IN TREATMENT_MANAGEMENT.UPDATE_TIME%TYPE DEFAULT NULL,
      UPDATE_TIME_nin IN BOOLEAN := TRUE,
      update_institution_in IN TREATMENT_MANAGEMENT.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      UPDATE_INSTITUTION_nin IN BOOLEAN := TRUE,
     handle_error_in IN BOOLEAN := TRUE
      );



      PROCEDURE upd (
      id_treatment_in IN TREATMENT_MANAGEMENT.ID_TREATMENT%TYPE DEFAULT NULL,
      ID_TREATMENT_nin IN BOOLEAN := TRUE,
      desc_treatment_management_in IN TREATMENT_MANAGEMENT.DESC_TREATMENT_MANAGEMENT%TYPE DEFAULT NULL,
      DESC_TREATMENT_MANAGEMENT_nin IN BOOLEAN := TRUE,
      id_professional_in IN TREATMENT_MANAGEMENT.ID_PROFESSIONAL%TYPE DEFAULT NULL,
      ID_PROFESSIONAL_nin IN BOOLEAN := TRUE,
      flg_type_in IN TREATMENT_MANAGEMENT.FLG_TYPE%TYPE DEFAULT NULL,
      FLG_TYPE_nin IN BOOLEAN := TRUE,
      dt_creation_tstz_in IN TREATMENT_MANAGEMENT.DT_CREATION_TSTZ%TYPE DEFAULT NULL,
      DT_CREATION_TSTZ_nin IN BOOLEAN := TRUE,
      create_user_in IN TREATMENT_MANAGEMENT.CREATE_USER%TYPE DEFAULT NULL,
      CREATE_USER_nin IN BOOLEAN := TRUE,
      create_time_in IN TREATMENT_MANAGEMENT.CREATE_TIME%TYPE DEFAULT NULL,
      CREATE_TIME_nin IN BOOLEAN := TRUE,
      create_institution_in IN TREATMENT_MANAGEMENT.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      CREATE_INSTITUTION_nin IN BOOLEAN := TRUE,
      update_user_in IN TREATMENT_MANAGEMENT.UPDATE_USER%TYPE DEFAULT NULL,
      UPDATE_USER_nin IN BOOLEAN := TRUE,
      update_time_in IN TREATMENT_MANAGEMENT.UPDATE_TIME%TYPE DEFAULT NULL,
      UPDATE_TIME_nin IN BOOLEAN := TRUE,
      update_institution_in IN TREATMENT_MANAGEMENT.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      UPDATE_INSTITUTION_nin IN BOOLEAN := TRUE,
    where_in varchar2,
     handle_error_in IN BOOLEAN := TRUE
     , rows_out IN OUT TABLE_VARCHAR
      );


      PROCEDURE upd (
      id_treatment_in IN TREATMENT_MANAGEMENT.ID_TREATMENT%TYPE DEFAULT NULL,
      ID_TREATMENT_nin IN BOOLEAN := TRUE,
      desc_treatment_management_in IN TREATMENT_MANAGEMENT.DESC_TREATMENT_MANAGEMENT%TYPE DEFAULT NULL,
      DESC_TREATMENT_MANAGEMENT_nin IN BOOLEAN := TRUE,
      id_professional_in IN TREATMENT_MANAGEMENT.ID_PROFESSIONAL%TYPE DEFAULT NULL,
      ID_PROFESSIONAL_nin IN BOOLEAN := TRUE,
      flg_type_in IN TREATMENT_MANAGEMENT.FLG_TYPE%TYPE DEFAULT NULL,
      FLG_TYPE_nin IN BOOLEAN := TRUE,
      dt_creation_tstz_in IN TREATMENT_MANAGEMENT.DT_CREATION_TSTZ%TYPE DEFAULT NULL,
      DT_CREATION_TSTZ_nin IN BOOLEAN := TRUE,
      create_user_in IN TREATMENT_MANAGEMENT.CREATE_USER%TYPE DEFAULT NULL,
      CREATE_USER_nin IN BOOLEAN := TRUE,
      create_time_in IN TREATMENT_MANAGEMENT.CREATE_TIME%TYPE DEFAULT NULL,
      CREATE_TIME_nin IN BOOLEAN := TRUE,
      create_institution_in IN TREATMENT_MANAGEMENT.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      CREATE_INSTITUTION_nin IN BOOLEAN := TRUE,
      update_user_in IN TREATMENT_MANAGEMENT.UPDATE_USER%TYPE DEFAULT NULL,
      UPDATE_USER_nin IN BOOLEAN := TRUE,
      update_time_in IN TREATMENT_MANAGEMENT.UPDATE_TIME%TYPE DEFAULT NULL,
      UPDATE_TIME_nin IN BOOLEAN := TRUE,
      update_institution_in IN TREATMENT_MANAGEMENT.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      UPDATE_INSTITUTION_nin IN BOOLEAN := TRUE,
    where_in varchar2,
     handle_error_in IN BOOLEAN := TRUE
      );



   PROCEDURE upd_ins (
      id_treatment_management_in IN TREATMENT_MANAGEMENT.ID_TREATMENT_MANAGEMENT%TYPE,
      id_treatment_in IN TREATMENT_MANAGEMENT.ID_TREATMENT%TYPE DEFAULT NULL,
      desc_treatment_management_in IN TREATMENT_MANAGEMENT.DESC_TREATMENT_MANAGEMENT%TYPE DEFAULT NULL,
      id_professional_in IN TREATMENT_MANAGEMENT.ID_PROFESSIONAL%TYPE DEFAULT NULL,
      flg_type_in IN TREATMENT_MANAGEMENT.FLG_TYPE%TYPE DEFAULT NULL,
      dt_creation_tstz_in IN TREATMENT_MANAGEMENT.DT_CREATION_TSTZ%TYPE DEFAULT NULL,
      create_user_in IN TREATMENT_MANAGEMENT.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN TREATMENT_MANAGEMENT.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN TREATMENT_MANAGEMENT.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN TREATMENT_MANAGEMENT.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN TREATMENT_MANAGEMENT.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN TREATMENT_MANAGEMENT.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
     handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      );

      PROCEDURE upd_ins (
      id_treatment_management_in IN TREATMENT_MANAGEMENT.ID_TREATMENT_MANAGEMENT%TYPE,
      id_treatment_in IN TREATMENT_MANAGEMENT.ID_TREATMENT%TYPE DEFAULT NULL,
      desc_treatment_management_in IN TREATMENT_MANAGEMENT.DESC_TREATMENT_MANAGEMENT%TYPE DEFAULT NULL,
      id_professional_in IN TREATMENT_MANAGEMENT.ID_PROFESSIONAL%TYPE DEFAULT NULL,
      flg_type_in IN TREATMENT_MANAGEMENT.FLG_TYPE%TYPE DEFAULT NULL,
      dt_creation_tstz_in IN TREATMENT_MANAGEMENT.DT_CREATION_TSTZ%TYPE DEFAULT NULL,
      create_user_in IN TREATMENT_MANAGEMENT.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN TREATMENT_MANAGEMENT.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN TREATMENT_MANAGEMENT.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN TREATMENT_MANAGEMENT.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN TREATMENT_MANAGEMENT.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN TREATMENT_MANAGEMENT.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
     handle_error_in IN BOOLEAN := TRUE
      );

   PROCEDURE upd (
      rec_in IN TREATMENT_MANAGEMENT%ROWTYPE,
     handle_error_in IN BOOLEAN := TRUE
     , rows_out IN OUT TABLE_VARCHAR
      );

      PROCEDURE upd (
      rec_in IN TREATMENT_MANAGEMENT%ROWTYPE,
     handle_error_in IN BOOLEAN := TRUE
      );

      PROCEDURE upd (
      col_in IN TREATMENT_MANAGEMENT_tc,
      ignore_if_null_in IN BOOLEAN := TRUE
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out IN OUT TABLE_VARCHAR
      );

      PROCEDURE upd (
      col_in IN TREATMENT_MANAGEMENT_tc,
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
      id_treatment_management_in IN TREATMENT_MANAGEMENT.ID_TREATMENT_MANAGEMENT%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
      );

-- Delete one row by primary key
   PROCEDURE del (
      id_treatment_management_in IN TREATMENT_MANAGEMENT.ID_TREATMENT_MANAGEMENT%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      );


   -- Delete all rows for primary key column ID_TREATMENT_MANAGEMENT
   PROCEDURE del_ID_TREATMENT_MANAGEMENT (
      id_treatment_management_in IN TREATMENT_MANAGEMENT.ID_TREATMENT_MANAGEMENT%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
     );

     -- Delete all rows for primary key column ID_TREATMENT_MANAGEMENT
   PROCEDURE del_ID_TREATMENT_MANAGEMENT (
      id_treatment_management_in IN TREATMENT_MANAGEMENT.ID_TREATMENT_MANAGEMENT%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
     );

   -- Delete all rows for this TMAN_PROF_FK foreign key value
   PROCEDURE del_TMAN_PROF_FK (
      id_professional_in IN TREATMENT_MANAGEMENT.ID_PROFESSIONAL%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
      );

      -- Delete all rows for this TMAN_PROF_FK foreign key value
   PROCEDURE del_TMAN_PROF_FK (
      id_professional_in IN TREATMENT_MANAGEMENT.ID_PROFESSIONAL%TYPE
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
      treatment_management_inout IN OUT TREATMENT_MANAGEMENT%ROWTYPE
   );

   FUNCTION initrec RETURN TREATMENT_MANAGEMENT%ROWTYPE;



   FUNCTION get_data_rowid(
        rows_in IN TABLE_VARCHAR
        ) RETURN TREATMENT_MANAGEMENT_tc;


   FUNCTION get_data_rowid_pat(
        rows_in IN TABLE_VARCHAR
        ) RETURN TREATMENT_MANAGEMENT_tc;

END TS_TREATMENT_MANAGEMENT;
/