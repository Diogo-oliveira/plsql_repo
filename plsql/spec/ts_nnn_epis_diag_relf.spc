/*-- Last Change Revision: $Rev: 1658071 $*/
/*-- Last Change by: $Author: ariel.machado $*/
/*-- Date of last change: $Date: 2014-11-10 09:49:40 +0000 (seg, 10 nov 2014) $*/
CREATE OR REPLACE PACKAGE TS_NNN_EPIS_DIAG_RELF
/*
| Generated by or retrieved from QCGU - DO NOT MODIFY!
| QCGU - "Get it right, do it fast" - www.ToadWorld.com
| QCGU Universal ID: {1BD37A66-EA60-4927-9A64-F6DD89237236}
| Created On: January 8, 2014 10:33:48
| Created By: ALERT
*/
IS

  -- Collection of %ROWTYPE records based on "NNN_EPIS_DIAG_RELF"
     TYPE NNN_EPIS_DIAG_RELF_tc IS TABLE OF NNN_EPIS_DIAG_RELF%ROWTYPE INDEX BY BINARY_INTEGER;
     TYPE nnn_epis_diag_relf_ntt IS TABLE OF NNN_EPIS_DIAG_RELF%ROWTYPE;
     TYPE nnn_epis_diag_relf_vat IS VARRAY(100) OF NNN_EPIS_DIAG_RELF%ROWTYPE;

  -- Same type structure, with a static name.
     TYPE aat IS TABLE OF NNN_EPIS_DIAG_RELF%ROWTYPE INDEX BY BINARY_INTEGER;
     TYPE ntt IS TABLE OF NNN_EPIS_DIAG_RELF%ROWTYPE;
     TYPE vat IS VARRAY(100) OF NNN_EPIS_DIAG_RELF%ROWTYPE;

   -- Column Collection based on column "ID_NNN_EPIS_DIAG_RELF"
   TYPE ID_NNN_EPIS_DIAG_RELF_cc IS TABLE OF NNN_EPIS_DIAG_RELF.ID_NNN_EPIS_DIAG_RELF%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "ID_NNN_EPIS_DIAG_EVAL"
   TYPE ID_NNN_EPIS_DIAG_EVAL_cc IS TABLE OF NNN_EPIS_DIAG_RELF.ID_NNN_EPIS_DIAG_EVAL%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "ID_NAN_RELATED_FACTOR"
   TYPE ID_NAN_RELATED_FACTOR_cc IS TABLE OF NNN_EPIS_DIAG_RELF.ID_NAN_RELATED_FACTOR%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "CREATE_USER"
   TYPE CREATE_USER_cc IS TABLE OF NNN_EPIS_DIAG_RELF.CREATE_USER%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "CREATE_TIME"
   TYPE CREATE_TIME_cc IS TABLE OF NNN_EPIS_DIAG_RELF.CREATE_TIME%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "CREATE_INSTITUTION"
   TYPE CREATE_INSTITUTION_cc IS TABLE OF NNN_EPIS_DIAG_RELF.CREATE_INSTITUTION%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "UPDATE_USER"
   TYPE UPDATE_USER_cc IS TABLE OF NNN_EPIS_DIAG_RELF.UPDATE_USER%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "UPDATE_TIME"
   TYPE UPDATE_TIME_cc IS TABLE OF NNN_EPIS_DIAG_RELF.UPDATE_TIME%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "UPDATE_INSTITUTION"
   TYPE UPDATE_INSTITUTION_cc IS TABLE OF NNN_EPIS_DIAG_RELF.UPDATE_INSTITUTION%TYPE INDEX BY BINARY_INTEGER;

   -- Insert one row, providing primary key if present
   PROCEDURE ins (
      id_nnn_epis_diag_relf_in IN NNN_EPIS_DIAG_RELF.ID_NNN_EPIS_DIAG_RELF%TYPE
      ,
      id_nnn_epis_diag_eval_in IN NNN_EPIS_DIAG_RELF.ID_NNN_EPIS_DIAG_EVAL%TYPE DEFAULT NULL,
      id_nan_related_factor_in IN NNN_EPIS_DIAG_RELF.ID_NAN_RELATED_FACTOR%TYPE DEFAULT NULL,
      create_user_in IN NNN_EPIS_DIAG_RELF.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN NNN_EPIS_DIAG_RELF.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN NNN_EPIS_DIAG_RELF.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN NNN_EPIS_DIAG_RELF.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN NNN_EPIS_DIAG_RELF.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN NNN_EPIS_DIAG_RELF.UPDATE_INSTITUTION%TYPE DEFAULT NULL
      -- Pass false if you want errors to propagate out unhandled
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      );

   PROCEDURE ins (
      id_nnn_epis_diag_relf_in IN NNN_EPIS_DIAG_RELF.ID_NNN_EPIS_DIAG_RELF%TYPE
      ,
      id_nnn_epis_diag_eval_in IN NNN_EPIS_DIAG_RELF.ID_NNN_EPIS_DIAG_EVAL%TYPE DEFAULT NULL,
      id_nan_related_factor_in IN NNN_EPIS_DIAG_RELF.ID_NAN_RELATED_FACTOR%TYPE DEFAULT NULL,
      create_user_in IN NNN_EPIS_DIAG_RELF.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN NNN_EPIS_DIAG_RELF.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN NNN_EPIS_DIAG_RELF.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN NNN_EPIS_DIAG_RELF.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN NNN_EPIS_DIAG_RELF.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN NNN_EPIS_DIAG_RELF.UPDATE_INSTITUTION%TYPE DEFAULT NULL
      -- Pass false if you want errors to propagate out unhandled
     ,handle_error_in IN BOOLEAN := TRUE
      );


   -- Insert a row based on a record.
   -- Specify whether or not a primary key value should be generated.
   PROCEDURE ins (
      rec_in IN NNN_EPIS_DIAG_RELF%ROWTYPE
     ,gen_pky_in IN BOOLEAN DEFAULT FALSE
     ,sequence_in IN VARCHAR2 := NULL
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
   );

   PROCEDURE ins (
      rec_in IN NNN_EPIS_DIAG_RELF%ROWTYPE
     ,gen_pky_in IN BOOLEAN DEFAULT FALSE
     ,sequence_in IN VARCHAR2 := NULL
     ,handle_error_in IN BOOLEAN := TRUE
   );

   -- Insert a collection of rows using FORALL; all primary key values
   -- must have already been generated, or are handled in triggers.
   PROCEDURE ins (
      rows_in IN NNN_EPIS_DIAG_RELF_tc
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
   );

   PROCEDURE ins (
      rows_in IN NNN_EPIS_DIAG_RELF_tc
     ,handle_error_in IN BOOLEAN := TRUE
   );

   -- Return next primary key value using the named sequence.
     FUNCTION next_key (sequence_in IN VARCHAR2 := NULL) RETURN NNN_EPIS_DIAG_RELF.ID_NNN_EPIS_DIAG_RELF%TYPE;

   -- Insert one row, generating hidden primary key using a sequence
   PROCEDURE ins (
      id_nnn_epis_diag_eval_in IN NNN_EPIS_DIAG_RELF.ID_NNN_EPIS_DIAG_EVAL%TYPE DEFAULT NULL,
      id_nan_related_factor_in IN NNN_EPIS_DIAG_RELF.ID_NAN_RELATED_FACTOR%TYPE DEFAULT NULL,
      create_user_in IN NNN_EPIS_DIAG_RELF.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN NNN_EPIS_DIAG_RELF.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN NNN_EPIS_DIAG_RELF.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN NNN_EPIS_DIAG_RELF.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN NNN_EPIS_DIAG_RELF.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN NNN_EPIS_DIAG_RELF.UPDATE_INSTITUTION%TYPE DEFAULT NULL
      -- Pass false if you want errors to propagate out unhandled
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      );

   PROCEDURE ins (
      id_nnn_epis_diag_eval_in IN NNN_EPIS_DIAG_RELF.ID_NNN_EPIS_DIAG_EVAL%TYPE DEFAULT NULL,
      id_nan_related_factor_in IN NNN_EPIS_DIAG_RELF.ID_NAN_RELATED_FACTOR%TYPE DEFAULT NULL,
      create_user_in IN NNN_EPIS_DIAG_RELF.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN NNN_EPIS_DIAG_RELF.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN NNN_EPIS_DIAG_RELF.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN NNN_EPIS_DIAG_RELF.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN NNN_EPIS_DIAG_RELF.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN NNN_EPIS_DIAG_RELF.UPDATE_INSTITUTION%TYPE DEFAULT NULL
      -- Pass false if you want errors to propagate out unhandled
     ,handle_error_in IN BOOLEAN := TRUE
      );

   -- Insert one row, returning primary key generated by sequence
   PROCEDURE ins (
      id_nnn_epis_diag_eval_in IN NNN_EPIS_DIAG_RELF.ID_NNN_EPIS_DIAG_EVAL%TYPE DEFAULT NULL,
      id_nan_related_factor_in IN NNN_EPIS_DIAG_RELF.ID_NAN_RELATED_FACTOR%TYPE DEFAULT NULL,
      create_user_in IN NNN_EPIS_DIAG_RELF.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN NNN_EPIS_DIAG_RELF.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN NNN_EPIS_DIAG_RELF.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN NNN_EPIS_DIAG_RELF.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN NNN_EPIS_DIAG_RELF.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN NNN_EPIS_DIAG_RELF.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      id_nnn_epis_diag_relf_out IN OUT NNN_EPIS_DIAG_RELF.ID_NNN_EPIS_DIAG_RELF%TYPE
      -- Pass false if you want errors to propagate out unhandled
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      );

   PROCEDURE ins (
      id_nnn_epis_diag_eval_in IN NNN_EPIS_DIAG_RELF.ID_NNN_EPIS_DIAG_EVAL%TYPE DEFAULT NULL,
      id_nan_related_factor_in IN NNN_EPIS_DIAG_RELF.ID_NAN_RELATED_FACTOR%TYPE DEFAULT NULL,
      create_user_in IN NNN_EPIS_DIAG_RELF.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN NNN_EPIS_DIAG_RELF.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN NNN_EPIS_DIAG_RELF.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN NNN_EPIS_DIAG_RELF.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN NNN_EPIS_DIAG_RELF.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN NNN_EPIS_DIAG_RELF.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      id_nnn_epis_diag_relf_out IN OUT NNN_EPIS_DIAG_RELF.ID_NNN_EPIS_DIAG_RELF%TYPE
      -- Pass false if you want errors to propagate out unhandled
     ,handle_error_in IN BOOLEAN := TRUE
      );

   -- Insert one row with function, return generated primary key
   FUNCTION ins (
      id_nnn_epis_diag_eval_in IN NNN_EPIS_DIAG_RELF.ID_NNN_EPIS_DIAG_EVAL%TYPE DEFAULT NULL,
      id_nan_related_factor_in IN NNN_EPIS_DIAG_RELF.ID_NAN_RELATED_FACTOR%TYPE DEFAULT NULL,
      create_user_in IN NNN_EPIS_DIAG_RELF.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN NNN_EPIS_DIAG_RELF.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN NNN_EPIS_DIAG_RELF.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN NNN_EPIS_DIAG_RELF.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN NNN_EPIS_DIAG_RELF.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN NNN_EPIS_DIAG_RELF.UPDATE_INSTITUTION%TYPE DEFAULT NULL
      -- Pass false if you want errors to propagate out unhandled
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      )
      RETURN
         NNN_EPIS_DIAG_RELF.ID_NNN_EPIS_DIAG_RELF%TYPE
      ;

   FUNCTION ins (
      id_nnn_epis_diag_eval_in IN NNN_EPIS_DIAG_RELF.ID_NNN_EPIS_DIAG_EVAL%TYPE DEFAULT NULL,
      id_nan_related_factor_in IN NNN_EPIS_DIAG_RELF.ID_NAN_RELATED_FACTOR%TYPE DEFAULT NULL,
      create_user_in IN NNN_EPIS_DIAG_RELF.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN NNN_EPIS_DIAG_RELF.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN NNN_EPIS_DIAG_RELF.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN NNN_EPIS_DIAG_RELF.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN NNN_EPIS_DIAG_RELF.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN NNN_EPIS_DIAG_RELF.UPDATE_INSTITUTION%TYPE DEFAULT NULL
      -- Pass false if you want errors to propagate out unhandled
     ,handle_error_in IN BOOLEAN := TRUE
      )
      RETURN
         NNN_EPIS_DIAG_RELF.ID_NNN_EPIS_DIAG_RELF%TYPE
      ;

   -- Update any/all columns by primary key. If you pass NULL, then
   -- the current column value is set to itself. If you need a more
   -- selected UPDATE then use one of the onecol procedures below.

  PROCEDURE upd (
      id_nnn_epis_diag_relf_in IN NNN_EPIS_DIAG_RELF.ID_NNN_EPIS_DIAG_RELF%TYPE,
      id_nnn_epis_diag_eval_in IN NNN_EPIS_DIAG_RELF.ID_NNN_EPIS_DIAG_EVAL%TYPE DEFAULT NULL,
      ID_NNN_EPIS_DIAG_EVAL_nin IN BOOLEAN := TRUE,
      id_nan_related_factor_in IN NNN_EPIS_DIAG_RELF.ID_NAN_RELATED_FACTOR%TYPE DEFAULT NULL,
      ID_NAN_RELATED_FACTOR_nin IN BOOLEAN := TRUE,
      create_user_in IN NNN_EPIS_DIAG_RELF.CREATE_USER%TYPE DEFAULT NULL,
      CREATE_USER_nin IN BOOLEAN := TRUE,
      create_time_in IN NNN_EPIS_DIAG_RELF.CREATE_TIME%TYPE DEFAULT NULL,
      CREATE_TIME_nin IN BOOLEAN := TRUE,
      create_institution_in IN NNN_EPIS_DIAG_RELF.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      CREATE_INSTITUTION_nin IN BOOLEAN := TRUE,
      update_user_in IN NNN_EPIS_DIAG_RELF.UPDATE_USER%TYPE DEFAULT NULL,
      UPDATE_USER_nin IN BOOLEAN := TRUE,
      update_time_in IN NNN_EPIS_DIAG_RELF.UPDATE_TIME%TYPE DEFAULT NULL,
      UPDATE_TIME_nin IN BOOLEAN := TRUE,
      update_institution_in IN NNN_EPIS_DIAG_RELF.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      UPDATE_INSTITUTION_nin IN BOOLEAN := TRUE,
     handle_error_in IN BOOLEAN := TRUE
     , rows_out IN OUT TABLE_VARCHAR
      );


       PROCEDURE upd (
      id_nnn_epis_diag_relf_in IN NNN_EPIS_DIAG_RELF.ID_NNN_EPIS_DIAG_RELF%TYPE,
      id_nnn_epis_diag_eval_in IN NNN_EPIS_DIAG_RELF.ID_NNN_EPIS_DIAG_EVAL%TYPE DEFAULT NULL,
      ID_NNN_EPIS_DIAG_EVAL_nin IN BOOLEAN := TRUE,
      id_nan_related_factor_in IN NNN_EPIS_DIAG_RELF.ID_NAN_RELATED_FACTOR%TYPE DEFAULT NULL,
      ID_NAN_RELATED_FACTOR_nin IN BOOLEAN := TRUE,
      create_user_in IN NNN_EPIS_DIAG_RELF.CREATE_USER%TYPE DEFAULT NULL,
      CREATE_USER_nin IN BOOLEAN := TRUE,
      create_time_in IN NNN_EPIS_DIAG_RELF.CREATE_TIME%TYPE DEFAULT NULL,
      CREATE_TIME_nin IN BOOLEAN := TRUE,
      create_institution_in IN NNN_EPIS_DIAG_RELF.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      CREATE_INSTITUTION_nin IN BOOLEAN := TRUE,
      update_user_in IN NNN_EPIS_DIAG_RELF.UPDATE_USER%TYPE DEFAULT NULL,
      UPDATE_USER_nin IN BOOLEAN := TRUE,
      update_time_in IN NNN_EPIS_DIAG_RELF.UPDATE_TIME%TYPE DEFAULT NULL,
      UPDATE_TIME_nin IN BOOLEAN := TRUE,
      update_institution_in IN NNN_EPIS_DIAG_RELF.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      UPDATE_INSTITUTION_nin IN BOOLEAN := TRUE,
     handle_error_in IN BOOLEAN := TRUE
      );



      PROCEDURE upd (
      id_nnn_epis_diag_eval_in IN NNN_EPIS_DIAG_RELF.ID_NNN_EPIS_DIAG_EVAL%TYPE DEFAULT NULL,
      ID_NNN_EPIS_DIAG_EVAL_nin IN BOOLEAN := TRUE,
      id_nan_related_factor_in IN NNN_EPIS_DIAG_RELF.ID_NAN_RELATED_FACTOR%TYPE DEFAULT NULL,
      ID_NAN_RELATED_FACTOR_nin IN BOOLEAN := TRUE,
      create_user_in IN NNN_EPIS_DIAG_RELF.CREATE_USER%TYPE DEFAULT NULL,
      CREATE_USER_nin IN BOOLEAN := TRUE,
      create_time_in IN NNN_EPIS_DIAG_RELF.CREATE_TIME%TYPE DEFAULT NULL,
      CREATE_TIME_nin IN BOOLEAN := TRUE,
      create_institution_in IN NNN_EPIS_DIAG_RELF.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      CREATE_INSTITUTION_nin IN BOOLEAN := TRUE,
      update_user_in IN NNN_EPIS_DIAG_RELF.UPDATE_USER%TYPE DEFAULT NULL,
      UPDATE_USER_nin IN BOOLEAN := TRUE,
      update_time_in IN NNN_EPIS_DIAG_RELF.UPDATE_TIME%TYPE DEFAULT NULL,
      UPDATE_TIME_nin IN BOOLEAN := TRUE,
      update_institution_in IN NNN_EPIS_DIAG_RELF.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      UPDATE_INSTITUTION_nin IN BOOLEAN := TRUE,
    where_in varchar2,
     handle_error_in IN BOOLEAN := TRUE
     , rows_out IN OUT TABLE_VARCHAR
      );


      PROCEDURE upd (
      id_nnn_epis_diag_eval_in IN NNN_EPIS_DIAG_RELF.ID_NNN_EPIS_DIAG_EVAL%TYPE DEFAULT NULL,
      ID_NNN_EPIS_DIAG_EVAL_nin IN BOOLEAN := TRUE,
      id_nan_related_factor_in IN NNN_EPIS_DIAG_RELF.ID_NAN_RELATED_FACTOR%TYPE DEFAULT NULL,
      ID_NAN_RELATED_FACTOR_nin IN BOOLEAN := TRUE,
      create_user_in IN NNN_EPIS_DIAG_RELF.CREATE_USER%TYPE DEFAULT NULL,
      CREATE_USER_nin IN BOOLEAN := TRUE,
      create_time_in IN NNN_EPIS_DIAG_RELF.CREATE_TIME%TYPE DEFAULT NULL,
      CREATE_TIME_nin IN BOOLEAN := TRUE,
      create_institution_in IN NNN_EPIS_DIAG_RELF.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      CREATE_INSTITUTION_nin IN BOOLEAN := TRUE,
      update_user_in IN NNN_EPIS_DIAG_RELF.UPDATE_USER%TYPE DEFAULT NULL,
      UPDATE_USER_nin IN BOOLEAN := TRUE,
      update_time_in IN NNN_EPIS_DIAG_RELF.UPDATE_TIME%TYPE DEFAULT NULL,
      UPDATE_TIME_nin IN BOOLEAN := TRUE,
      update_institution_in IN NNN_EPIS_DIAG_RELF.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      UPDATE_INSTITUTION_nin IN BOOLEAN := TRUE,
    where_in varchar2,
     handle_error_in IN BOOLEAN := TRUE
      );



   PROCEDURE upd_ins (
      id_nnn_epis_diag_relf_in IN NNN_EPIS_DIAG_RELF.ID_NNN_EPIS_DIAG_RELF%TYPE,
      id_nnn_epis_diag_eval_in IN NNN_EPIS_DIAG_RELF.ID_NNN_EPIS_DIAG_EVAL%TYPE DEFAULT NULL,
      id_nan_related_factor_in IN NNN_EPIS_DIAG_RELF.ID_NAN_RELATED_FACTOR%TYPE DEFAULT NULL,
      create_user_in IN NNN_EPIS_DIAG_RELF.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN NNN_EPIS_DIAG_RELF.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN NNN_EPIS_DIAG_RELF.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN NNN_EPIS_DIAG_RELF.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN NNN_EPIS_DIAG_RELF.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN NNN_EPIS_DIAG_RELF.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
     handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      );

      PROCEDURE upd_ins (
      id_nnn_epis_diag_relf_in IN NNN_EPIS_DIAG_RELF.ID_NNN_EPIS_DIAG_RELF%TYPE,
      id_nnn_epis_diag_eval_in IN NNN_EPIS_DIAG_RELF.ID_NNN_EPIS_DIAG_EVAL%TYPE DEFAULT NULL,
      id_nan_related_factor_in IN NNN_EPIS_DIAG_RELF.ID_NAN_RELATED_FACTOR%TYPE DEFAULT NULL,
      create_user_in IN NNN_EPIS_DIAG_RELF.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN NNN_EPIS_DIAG_RELF.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN NNN_EPIS_DIAG_RELF.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN NNN_EPIS_DIAG_RELF.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN NNN_EPIS_DIAG_RELF.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN NNN_EPIS_DIAG_RELF.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
     handle_error_in IN BOOLEAN := TRUE
      );

   PROCEDURE upd (
      rec_in IN NNN_EPIS_DIAG_RELF%ROWTYPE,
     handle_error_in IN BOOLEAN := TRUE
     , rows_out IN OUT TABLE_VARCHAR
      );

      PROCEDURE upd (
      rec_in IN NNN_EPIS_DIAG_RELF%ROWTYPE,
     handle_error_in IN BOOLEAN := TRUE
      );

      PROCEDURE upd (
      col_in IN NNN_EPIS_DIAG_RELF_tc,
      ignore_if_null_in IN BOOLEAN := TRUE
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out IN OUT TABLE_VARCHAR
      );

      PROCEDURE upd (
      col_in IN NNN_EPIS_DIAG_RELF_tc,
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
      id_nnn_epis_diag_relf_in IN NNN_EPIS_DIAG_RELF.ID_NNN_EPIS_DIAG_RELF%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
      );

-- Delete one row by primary key
   PROCEDURE del (
      id_nnn_epis_diag_relf_in IN NNN_EPIS_DIAG_RELF.ID_NNN_EPIS_DIAG_RELF%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      );


   -- Delete all rows for primary key column ID_NNN_EPIS_DIAG_RELF
   PROCEDURE del_ID_NNN_EPIS_DIAG_RELF (
      id_nnn_epis_diag_relf_in IN NNN_EPIS_DIAG_RELF.ID_NNN_EPIS_DIAG_RELF%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
     );

     -- Delete all rows for primary key column ID_NNN_EPIS_DIAG_RELF
   PROCEDURE del_ID_NNN_EPIS_DIAG_RELF (
      id_nnn_epis_diag_relf_in IN NNN_EPIS_DIAG_RELF.ID_NNN_EPIS_DIAG_RELF%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
     );

   -- Delete for unique value of NNN_EPIS_DIAG_RELF_UK
   PROCEDURE del_NNN_EPIS_DIAG_RELF_UK (
      id_nnn_epis_diag_eval_in IN NNN_EPIS_DIAG_RELF.ID_NNN_EPIS_DIAG_EVAL%TYPE,
      id_nan_related_factor_in IN NNN_EPIS_DIAG_RELF.ID_NAN_RELATED_FACTOR%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
      );

   -- Delete for unique value of NNN_EPIS_DIAG_RELF_UK
   PROCEDURE del_NNN_EPIS_DIAG_RELF_UK (
      id_nnn_epis_diag_eval_in IN NNN_EPIS_DIAG_RELF.ID_NNN_EPIS_DIAG_EVAL%TYPE,
      id_nan_related_factor_in IN NNN_EPIS_DIAG_RELF.ID_NAN_RELATED_FACTOR%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      );

   -- Delete all rows for this NNNEDERLF_NANRLF_FK foreign key value
   PROCEDURE del_NNNEDERLF_NANRLF_FK (
      id_nan_related_factor_in IN NNN_EPIS_DIAG_RELF.ID_NAN_RELATED_FACTOR%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
      );

      -- Delete all rows for this NNNEDERLF_NANRLF_FK foreign key value
   PROCEDURE del_NNNEDERLF_NANRLF_FK (
      id_nan_related_factor_in IN NNN_EPIS_DIAG_RELF.ID_NAN_RELATED_FACTOR%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      );

   -- Delete all rows for this NNNEDERLF_NNNEDE_FK foreign key value
   PROCEDURE del_NNNEDERLF_NNNEDE_FK (
      id_nnn_epis_diag_eval_in IN NNN_EPIS_DIAG_RELF.ID_NNN_EPIS_DIAG_EVAL%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
      );

      -- Delete all rows for this NNNEDERLF_NNNEDE_FK foreign key value
   PROCEDURE del_NNNEDERLF_NNNEDE_FK (
      id_nnn_epis_diag_eval_in IN NNN_EPIS_DIAG_RELF.ID_NNN_EPIS_DIAG_EVAL%TYPE
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
      nnn_epis_diag_relf_inout IN OUT NNN_EPIS_DIAG_RELF%ROWTYPE
   );

   FUNCTION initrec RETURN NNN_EPIS_DIAG_RELF%ROWTYPE;



   FUNCTION get_data_rowid(
        rows_in IN TABLE_VARCHAR
        ) RETURN NNN_EPIS_DIAG_RELF_tc;


   FUNCTION get_data_rowid_pat(
        rows_in IN TABLE_VARCHAR
        ) RETURN NNN_EPIS_DIAG_RELF_tc;

END TS_NNN_EPIS_DIAG_RELF;
/
