/*-- Last Change Revision: $Rev: 1242645 $*/
/*-- Last Change by: $Author: pedro.carneiro $*/
/*-- Date of last change: $Date: 2012-02-29 10:47:31 +0000 (qua, 29 fev 2012) $*/


CREATE OR REPLACE PACKAGE TS_CDR_PARAMETER
/*
| Generated by or retrieved from QCGU - DO NOT MODIFY!
| QCGU - "Get it right, do it fast" - www.ToadWorld.com
| QCGU Universal ID: {1BD37A66-EA60-4927-9A64-F6DD89237236}
| Created On: Fevereiro 28, 2012 17:45:34
| Created By: ALERT
*/
IS

  -- Collection of %ROWTYPE records based on "CDR_PARAMETER"
     TYPE CDR_PARAMETER_tc IS TABLE OF CDR_PARAMETER%ROWTYPE INDEX BY BINARY_INTEGER;
     TYPE cdr_parameter_ntt IS TABLE OF CDR_PARAMETER%ROWTYPE;
     TYPE cdr_parameter_vat IS VARRAY(100) OF CDR_PARAMETER%ROWTYPE;

  -- Same type structure, with a static name.
     TYPE aat IS TABLE OF CDR_PARAMETER%ROWTYPE INDEX BY BINARY_INTEGER;
     TYPE ntt IS TABLE OF CDR_PARAMETER%ROWTYPE;
     TYPE vat IS VARRAY(100) OF CDR_PARAMETER%ROWTYPE;

   -- Column Collection based on column "ID_CDR_PARAMETER"
   TYPE ID_CDR_PARAMETER_cc IS TABLE OF CDR_PARAMETER.ID_CDR_PARAMETER%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "ID_CDR_DEF_COND"
   TYPE ID_CDR_DEF_COND_cc IS TABLE OF CDR_PARAMETER.ID_CDR_DEF_COND%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "ID_CDR_CONCEPT"
   TYPE ID_CDR_CONCEPT_cc IS TABLE OF CDR_PARAMETER.ID_CDR_CONCEPT%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "RANK"
   TYPE RANK_cc IS TABLE OF CDR_PARAMETER.RANK%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "CREATE_USER"
   TYPE CREATE_USER_cc IS TABLE OF CDR_PARAMETER.CREATE_USER%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "CREATE_TIME"
   TYPE CREATE_TIME_cc IS TABLE OF CDR_PARAMETER.CREATE_TIME%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "CREATE_INSTITUTION"
   TYPE CREATE_INSTITUTION_cc IS TABLE OF CDR_PARAMETER.CREATE_INSTITUTION%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "UPDATE_USER"
   TYPE UPDATE_USER_cc IS TABLE OF CDR_PARAMETER.UPDATE_USER%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "UPDATE_TIME"
   TYPE UPDATE_TIME_cc IS TABLE OF CDR_PARAMETER.UPDATE_TIME%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "UPDATE_INSTITUTION"
   TYPE UPDATE_INSTITUTION_cc IS TABLE OF CDR_PARAMETER.UPDATE_INSTITUTION%TYPE INDEX BY BINARY_INTEGER;

   -- Insert one row, providing primary key if present
   PROCEDURE ins (
      id_cdr_parameter_in IN CDR_PARAMETER.ID_CDR_PARAMETER%TYPE
      ,
      id_cdr_def_cond_in IN CDR_PARAMETER.ID_CDR_DEF_COND%TYPE DEFAULT NULL,
      id_cdr_concept_in IN CDR_PARAMETER.ID_CDR_CONCEPT%TYPE DEFAULT NULL,
      rank_in IN CDR_PARAMETER.RANK%TYPE DEFAULT NULL,
      create_user_in IN CDR_PARAMETER.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN CDR_PARAMETER.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN CDR_PARAMETER.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN CDR_PARAMETER.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN CDR_PARAMETER.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN CDR_PARAMETER.UPDATE_INSTITUTION%TYPE DEFAULT NULL
      -- Pass false if you want errors to propagate out unhandled
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      );

   PROCEDURE ins (
      id_cdr_parameter_in IN CDR_PARAMETER.ID_CDR_PARAMETER%TYPE
      ,
      id_cdr_def_cond_in IN CDR_PARAMETER.ID_CDR_DEF_COND%TYPE DEFAULT NULL,
      id_cdr_concept_in IN CDR_PARAMETER.ID_CDR_CONCEPT%TYPE DEFAULT NULL,
      rank_in IN CDR_PARAMETER.RANK%TYPE DEFAULT NULL,
      create_user_in IN CDR_PARAMETER.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN CDR_PARAMETER.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN CDR_PARAMETER.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN CDR_PARAMETER.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN CDR_PARAMETER.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN CDR_PARAMETER.UPDATE_INSTITUTION%TYPE DEFAULT NULL
      -- Pass false if you want errors to propagate out unhandled
     ,handle_error_in IN BOOLEAN := TRUE
      );


   -- Insert a row based on a record.
   -- Specify whether or not a primary key value should be generated.
   PROCEDURE ins (
      rec_in IN CDR_PARAMETER%ROWTYPE
     ,gen_pky_in IN BOOLEAN DEFAULT FALSE
     ,sequence_in IN VARCHAR2 := NULL
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
   );

   PROCEDURE ins (
      rec_in IN CDR_PARAMETER%ROWTYPE
     ,gen_pky_in IN BOOLEAN DEFAULT FALSE
     ,sequence_in IN VARCHAR2 := NULL
     ,handle_error_in IN BOOLEAN := TRUE
   );

   -- Insert a collection of rows using FORALL; all primary key values
   -- must have already been generated, or are handled in triggers.
   PROCEDURE ins (
      rows_in IN CDR_PARAMETER_tc
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
   );

   PROCEDURE ins (
      rows_in IN CDR_PARAMETER_tc
     ,handle_error_in IN BOOLEAN := TRUE
   );

   -- Return next primary key value using the named sequence.
     FUNCTION next_key (sequence_in IN VARCHAR2 := NULL) RETURN CDR_PARAMETER.ID_CDR_PARAMETER%TYPE;

   -- Insert one row, generating hidden primary key using a sequence
   PROCEDURE ins (
      id_cdr_def_cond_in IN CDR_PARAMETER.ID_CDR_DEF_COND%TYPE DEFAULT NULL,
      id_cdr_concept_in IN CDR_PARAMETER.ID_CDR_CONCEPT%TYPE DEFAULT NULL,
      rank_in IN CDR_PARAMETER.RANK%TYPE DEFAULT NULL,
      create_user_in IN CDR_PARAMETER.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN CDR_PARAMETER.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN CDR_PARAMETER.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN CDR_PARAMETER.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN CDR_PARAMETER.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN CDR_PARAMETER.UPDATE_INSTITUTION%TYPE DEFAULT NULL
      -- Pass false if you want errors to propagate out unhandled
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      );

   PROCEDURE ins (
      id_cdr_def_cond_in IN CDR_PARAMETER.ID_CDR_DEF_COND%TYPE DEFAULT NULL,
      id_cdr_concept_in IN CDR_PARAMETER.ID_CDR_CONCEPT%TYPE DEFAULT NULL,
      rank_in IN CDR_PARAMETER.RANK%TYPE DEFAULT NULL,
      create_user_in IN CDR_PARAMETER.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN CDR_PARAMETER.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN CDR_PARAMETER.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN CDR_PARAMETER.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN CDR_PARAMETER.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN CDR_PARAMETER.UPDATE_INSTITUTION%TYPE DEFAULT NULL
      -- Pass false if you want errors to propagate out unhandled
     ,handle_error_in IN BOOLEAN := TRUE
      );

   -- Insert one row, returning primary key generated by sequence
   PROCEDURE ins (
      id_cdr_def_cond_in IN CDR_PARAMETER.ID_CDR_DEF_COND%TYPE DEFAULT NULL,
      id_cdr_concept_in IN CDR_PARAMETER.ID_CDR_CONCEPT%TYPE DEFAULT NULL,
      rank_in IN CDR_PARAMETER.RANK%TYPE DEFAULT NULL,
      create_user_in IN CDR_PARAMETER.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN CDR_PARAMETER.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN CDR_PARAMETER.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN CDR_PARAMETER.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN CDR_PARAMETER.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN CDR_PARAMETER.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      id_cdr_parameter_out IN OUT CDR_PARAMETER.ID_CDR_PARAMETER%TYPE
      -- Pass false if you want errors to propagate out unhandled
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      );

   PROCEDURE ins (
      id_cdr_def_cond_in IN CDR_PARAMETER.ID_CDR_DEF_COND%TYPE DEFAULT NULL,
      id_cdr_concept_in IN CDR_PARAMETER.ID_CDR_CONCEPT%TYPE DEFAULT NULL,
      rank_in IN CDR_PARAMETER.RANK%TYPE DEFAULT NULL,
      create_user_in IN CDR_PARAMETER.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN CDR_PARAMETER.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN CDR_PARAMETER.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN CDR_PARAMETER.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN CDR_PARAMETER.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN CDR_PARAMETER.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      id_cdr_parameter_out IN OUT CDR_PARAMETER.ID_CDR_PARAMETER%TYPE
      -- Pass false if you want errors to propagate out unhandled
     ,handle_error_in IN BOOLEAN := TRUE
      );

   -- Insert one row with function, return generated primary key
   FUNCTION ins (
      id_cdr_def_cond_in IN CDR_PARAMETER.ID_CDR_DEF_COND%TYPE DEFAULT NULL,
      id_cdr_concept_in IN CDR_PARAMETER.ID_CDR_CONCEPT%TYPE DEFAULT NULL,
      rank_in IN CDR_PARAMETER.RANK%TYPE DEFAULT NULL,
      create_user_in IN CDR_PARAMETER.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN CDR_PARAMETER.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN CDR_PARAMETER.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN CDR_PARAMETER.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN CDR_PARAMETER.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN CDR_PARAMETER.UPDATE_INSTITUTION%TYPE DEFAULT NULL
      -- Pass false if you want errors to propagate out unhandled
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      )
      RETURN
         CDR_PARAMETER.ID_CDR_PARAMETER%TYPE
      ;

   FUNCTION ins (
      id_cdr_def_cond_in IN CDR_PARAMETER.ID_CDR_DEF_COND%TYPE DEFAULT NULL,
      id_cdr_concept_in IN CDR_PARAMETER.ID_CDR_CONCEPT%TYPE DEFAULT NULL,
      rank_in IN CDR_PARAMETER.RANK%TYPE DEFAULT NULL,
      create_user_in IN CDR_PARAMETER.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN CDR_PARAMETER.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN CDR_PARAMETER.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN CDR_PARAMETER.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN CDR_PARAMETER.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN CDR_PARAMETER.UPDATE_INSTITUTION%TYPE DEFAULT NULL
      -- Pass false if you want errors to propagate out unhandled
     ,handle_error_in IN BOOLEAN := TRUE
      )
      RETURN
         CDR_PARAMETER.ID_CDR_PARAMETER%TYPE
      ;

   -- Update any/all columns by primary key. If you pass NULL, then
   -- the current column value is set to itself. If you need a more
   -- selected UPDATE then use one of the onecol procedures below.

  PROCEDURE upd (
      id_cdr_parameter_in IN CDR_PARAMETER.ID_CDR_PARAMETER%TYPE,
      id_cdr_def_cond_in IN CDR_PARAMETER.ID_CDR_DEF_COND%TYPE DEFAULT NULL,
      ID_CDR_DEF_COND_nin IN BOOLEAN := TRUE,
      id_cdr_concept_in IN CDR_PARAMETER.ID_CDR_CONCEPT%TYPE DEFAULT NULL,
      ID_CDR_CONCEPT_nin IN BOOLEAN := TRUE,
      rank_in IN CDR_PARAMETER.RANK%TYPE DEFAULT NULL,
      RANK_nin IN BOOLEAN := TRUE,
      create_user_in IN CDR_PARAMETER.CREATE_USER%TYPE DEFAULT NULL,
      CREATE_USER_nin IN BOOLEAN := TRUE,
      create_time_in IN CDR_PARAMETER.CREATE_TIME%TYPE DEFAULT NULL,
      CREATE_TIME_nin IN BOOLEAN := TRUE,
      create_institution_in IN CDR_PARAMETER.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      CREATE_INSTITUTION_nin IN BOOLEAN := TRUE,
      update_user_in IN CDR_PARAMETER.UPDATE_USER%TYPE DEFAULT NULL,
      UPDATE_USER_nin IN BOOLEAN := TRUE,
      update_time_in IN CDR_PARAMETER.UPDATE_TIME%TYPE DEFAULT NULL,
      UPDATE_TIME_nin IN BOOLEAN := TRUE,
      update_institution_in IN CDR_PARAMETER.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      UPDATE_INSTITUTION_nin IN BOOLEAN := TRUE,
     handle_error_in IN BOOLEAN := TRUE
     , rows_out IN OUT TABLE_VARCHAR
      );


       PROCEDURE upd (
      id_cdr_parameter_in IN CDR_PARAMETER.ID_CDR_PARAMETER%TYPE,
      id_cdr_def_cond_in IN CDR_PARAMETER.ID_CDR_DEF_COND%TYPE DEFAULT NULL,
      ID_CDR_DEF_COND_nin IN BOOLEAN := TRUE,
      id_cdr_concept_in IN CDR_PARAMETER.ID_CDR_CONCEPT%TYPE DEFAULT NULL,
      ID_CDR_CONCEPT_nin IN BOOLEAN := TRUE,
      rank_in IN CDR_PARAMETER.RANK%TYPE DEFAULT NULL,
      RANK_nin IN BOOLEAN := TRUE,
      create_user_in IN CDR_PARAMETER.CREATE_USER%TYPE DEFAULT NULL,
      CREATE_USER_nin IN BOOLEAN := TRUE,
      create_time_in IN CDR_PARAMETER.CREATE_TIME%TYPE DEFAULT NULL,
      CREATE_TIME_nin IN BOOLEAN := TRUE,
      create_institution_in IN CDR_PARAMETER.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      CREATE_INSTITUTION_nin IN BOOLEAN := TRUE,
      update_user_in IN CDR_PARAMETER.UPDATE_USER%TYPE DEFAULT NULL,
      UPDATE_USER_nin IN BOOLEAN := TRUE,
      update_time_in IN CDR_PARAMETER.UPDATE_TIME%TYPE DEFAULT NULL,
      UPDATE_TIME_nin IN BOOLEAN := TRUE,
      update_institution_in IN CDR_PARAMETER.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      UPDATE_INSTITUTION_nin IN BOOLEAN := TRUE,
     handle_error_in IN BOOLEAN := TRUE
      );



      PROCEDURE upd (
      id_cdr_def_cond_in IN CDR_PARAMETER.ID_CDR_DEF_COND%TYPE DEFAULT NULL,
      ID_CDR_DEF_COND_nin IN BOOLEAN := TRUE,
      id_cdr_concept_in IN CDR_PARAMETER.ID_CDR_CONCEPT%TYPE DEFAULT NULL,
      ID_CDR_CONCEPT_nin IN BOOLEAN := TRUE,
      rank_in IN CDR_PARAMETER.RANK%TYPE DEFAULT NULL,
      RANK_nin IN BOOLEAN := TRUE,
      create_user_in IN CDR_PARAMETER.CREATE_USER%TYPE DEFAULT NULL,
      CREATE_USER_nin IN BOOLEAN := TRUE,
      create_time_in IN CDR_PARAMETER.CREATE_TIME%TYPE DEFAULT NULL,
      CREATE_TIME_nin IN BOOLEAN := TRUE,
      create_institution_in IN CDR_PARAMETER.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      CREATE_INSTITUTION_nin IN BOOLEAN := TRUE,
      update_user_in IN CDR_PARAMETER.UPDATE_USER%TYPE DEFAULT NULL,
      UPDATE_USER_nin IN BOOLEAN := TRUE,
      update_time_in IN CDR_PARAMETER.UPDATE_TIME%TYPE DEFAULT NULL,
      UPDATE_TIME_nin IN BOOLEAN := TRUE,
      update_institution_in IN CDR_PARAMETER.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      UPDATE_INSTITUTION_nin IN BOOLEAN := TRUE,
    where_in varchar2,
     handle_error_in IN BOOLEAN := TRUE
     , rows_out IN OUT TABLE_VARCHAR
      );


      PROCEDURE upd (
      id_cdr_def_cond_in IN CDR_PARAMETER.ID_CDR_DEF_COND%TYPE DEFAULT NULL,
      ID_CDR_DEF_COND_nin IN BOOLEAN := TRUE,
      id_cdr_concept_in IN CDR_PARAMETER.ID_CDR_CONCEPT%TYPE DEFAULT NULL,
      ID_CDR_CONCEPT_nin IN BOOLEAN := TRUE,
      rank_in IN CDR_PARAMETER.RANK%TYPE DEFAULT NULL,
      RANK_nin IN BOOLEAN := TRUE,
      create_user_in IN CDR_PARAMETER.CREATE_USER%TYPE DEFAULT NULL,
      CREATE_USER_nin IN BOOLEAN := TRUE,
      create_time_in IN CDR_PARAMETER.CREATE_TIME%TYPE DEFAULT NULL,
      CREATE_TIME_nin IN BOOLEAN := TRUE,
      create_institution_in IN CDR_PARAMETER.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      CREATE_INSTITUTION_nin IN BOOLEAN := TRUE,
      update_user_in IN CDR_PARAMETER.UPDATE_USER%TYPE DEFAULT NULL,
      UPDATE_USER_nin IN BOOLEAN := TRUE,
      update_time_in IN CDR_PARAMETER.UPDATE_TIME%TYPE DEFAULT NULL,
      UPDATE_TIME_nin IN BOOLEAN := TRUE,
      update_institution_in IN CDR_PARAMETER.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      UPDATE_INSTITUTION_nin IN BOOLEAN := TRUE,
    where_in varchar2,
     handle_error_in IN BOOLEAN := TRUE
      );



   PROCEDURE upd_ins (
      id_cdr_parameter_in IN CDR_PARAMETER.ID_CDR_PARAMETER%TYPE,
      id_cdr_def_cond_in IN CDR_PARAMETER.ID_CDR_DEF_COND%TYPE DEFAULT NULL,
      id_cdr_concept_in IN CDR_PARAMETER.ID_CDR_CONCEPT%TYPE DEFAULT NULL,
      rank_in IN CDR_PARAMETER.RANK%TYPE DEFAULT NULL,
      create_user_in IN CDR_PARAMETER.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN CDR_PARAMETER.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN CDR_PARAMETER.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN CDR_PARAMETER.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN CDR_PARAMETER.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN CDR_PARAMETER.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
     handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      );

      PROCEDURE upd_ins (
      id_cdr_parameter_in IN CDR_PARAMETER.ID_CDR_PARAMETER%TYPE,
      id_cdr_def_cond_in IN CDR_PARAMETER.ID_CDR_DEF_COND%TYPE DEFAULT NULL,
      id_cdr_concept_in IN CDR_PARAMETER.ID_CDR_CONCEPT%TYPE DEFAULT NULL,
      rank_in IN CDR_PARAMETER.RANK%TYPE DEFAULT NULL,
      create_user_in IN CDR_PARAMETER.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN CDR_PARAMETER.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN CDR_PARAMETER.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN CDR_PARAMETER.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN CDR_PARAMETER.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN CDR_PARAMETER.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
     handle_error_in IN BOOLEAN := TRUE
      );

   PROCEDURE upd (
      rec_in IN CDR_PARAMETER%ROWTYPE,
     handle_error_in IN BOOLEAN := TRUE
     , rows_out IN OUT TABLE_VARCHAR
      );

      PROCEDURE upd (
      rec_in IN CDR_PARAMETER%ROWTYPE,
     handle_error_in IN BOOLEAN := TRUE
      );

      PROCEDURE upd (
      col_in IN CDR_PARAMETER_tc,
      ignore_if_null_in IN BOOLEAN := TRUE
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out IN OUT TABLE_VARCHAR
      );

      PROCEDURE upd (
      col_in IN CDR_PARAMETER_tc,
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
      id_cdr_parameter_in IN CDR_PARAMETER.ID_CDR_PARAMETER%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
      );

-- Delete one row by primary key
   PROCEDURE del (
      id_cdr_parameter_in IN CDR_PARAMETER.ID_CDR_PARAMETER%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      );


   -- Delete all rows for primary key column ID_CDR_PARAMETER
   PROCEDURE del_ID_CDR_PARAMETER (
      id_cdr_parameter_in IN CDR_PARAMETER.ID_CDR_PARAMETER%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
     );

     -- Delete all rows for primary key column ID_CDR_PARAMETER
   PROCEDURE del_ID_CDR_PARAMETER (
      id_cdr_parameter_in IN CDR_PARAMETER.ID_CDR_PARAMETER%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
     );

   -- Delete all rows for this CDRP_CDRCP_FK foreign key value
   PROCEDURE del_CDRP_CDRCP_FK (
      id_cdr_concept_in IN CDR_PARAMETER.ID_CDR_CONCEPT%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
      );

      -- Delete all rows for this CDRP_CDRCP_FK foreign key value
   PROCEDURE del_CDRP_CDRCP_FK (
      id_cdr_concept_in IN CDR_PARAMETER.ID_CDR_CONCEPT%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      );

   -- Delete all rows for this CDRP_CDRDC_FK foreign key value
   PROCEDURE del_CDRP_CDRDC_FK (
      id_cdr_def_cond_in IN CDR_PARAMETER.ID_CDR_DEF_COND%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
      );

      -- Delete all rows for this CDRP_CDRDC_FK foreign key value
   PROCEDURE del_CDRP_CDRDC_FK (
      id_cdr_def_cond_in IN CDR_PARAMETER.ID_CDR_DEF_COND%TYPE
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
      cdr_parameter_inout IN OUT CDR_PARAMETER%ROWTYPE
   );

   FUNCTION initrec RETURN CDR_PARAMETER%ROWTYPE;



   FUNCTION get_data_rowid(
        rows_in IN TABLE_VARCHAR
        ) RETURN CDR_PARAMETER_tc;


   FUNCTION get_data_rowid_pat(
        rows_in IN TABLE_VARCHAR
        ) RETURN CDR_PARAMETER_tc;

END TS_CDR_PARAMETER;
/
