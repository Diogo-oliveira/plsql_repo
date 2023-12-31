/*-- Last Change Revision: $Rev: 1271739 $*/
/*-- Last Change by: $Author: gustavo.serrano $*/
/*-- Date of last change: $Date: 2012-04-04 11:44:22 +0100 (qua, 04 abr 2012) $*/
CREATE OR REPLACE PACKAGE TS_DOC_MACRO_PROF_HIST
/*
| Generated by or retrieved from QCGU - DO NOT MODIFY!
| QCGU - "Get it right, do it fast" - www.ToadWorld.com
| QCGU Universal ID: {1BD37A66-EA60-4927-9A64-F6DD89237236}
| Created On: Mar�o 30, 2012 17:1:15
| Created By: ALERT
*/
IS

  -- Collection of %ROWTYPE records based on "DOC_MACRO_PROF_HIST"
     TYPE DOC_MACRO_PROF_HIST_tc IS TABLE OF DOC_MACRO_PROF_HIST%ROWTYPE INDEX BY BINARY_INTEGER;
     TYPE doc_macro_prof_hist_ntt IS TABLE OF DOC_MACRO_PROF_HIST%ROWTYPE;
     TYPE doc_macro_prof_hist_vat IS VARRAY(100) OF DOC_MACRO_PROF_HIST%ROWTYPE;

  -- Same type structure, with a static name.
     TYPE aat IS TABLE OF DOC_MACRO_PROF_HIST%ROWTYPE INDEX BY BINARY_INTEGER;
     TYPE ntt IS TABLE OF DOC_MACRO_PROF_HIST%ROWTYPE;
     TYPE vat IS VARRAY(100) OF DOC_MACRO_PROF_HIST%ROWTYPE;

   -- Column Collection based on column "DT_DOC_MACRO_HIST"
   TYPE DT_DOC_MACRO_HIST_cc IS TABLE OF DOC_MACRO_PROF_HIST.DT_DOC_MACRO_HIST%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "ID_DOC_MACRO_PROF"
   TYPE ID_DOC_MACRO_PROF_cc IS TABLE OF DOC_MACRO_PROF_HIST.ID_DOC_MACRO_PROF%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "ID_DOC_MACRO"
   TYPE ID_DOC_MACRO_cc IS TABLE OF DOC_MACRO_PROF_HIST.ID_DOC_MACRO%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "ID_PROFESSIONAL"
   TYPE ID_PROFESSIONAL_cc IS TABLE OF DOC_MACRO_PROF_HIST.ID_PROFESSIONAL%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "FLG_STATUS"
   TYPE FLG_STATUS_cc IS TABLE OF DOC_MACRO_PROF_HIST.FLG_STATUS%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "DT_CREATION"
   TYPE DT_CREATION_cc IS TABLE OF DOC_MACRO_PROF_HIST.DT_CREATION%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "CREATE_USER"
   TYPE CREATE_USER_cc IS TABLE OF DOC_MACRO_PROF_HIST.CREATE_USER%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "CREATE_TIME"
   TYPE CREATE_TIME_cc IS TABLE OF DOC_MACRO_PROF_HIST.CREATE_TIME%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "CREATE_INSTITUTION"
   TYPE CREATE_INSTITUTION_cc IS TABLE OF DOC_MACRO_PROF_HIST.CREATE_INSTITUTION%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "UPDATE_USER"
   TYPE UPDATE_USER_cc IS TABLE OF DOC_MACRO_PROF_HIST.UPDATE_USER%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "UPDATE_TIME"
   TYPE UPDATE_TIME_cc IS TABLE OF DOC_MACRO_PROF_HIST.UPDATE_TIME%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "UPDATE_INSTITUTION"
   TYPE UPDATE_INSTITUTION_cc IS TABLE OF DOC_MACRO_PROF_HIST.UPDATE_INSTITUTION%TYPE INDEX BY BINARY_INTEGER;

   -- Insert one row, providing primary key if present
   PROCEDURE ins (
      id_doc_macro_prof_in IN DOC_MACRO_PROF_HIST.ID_DOC_MACRO_PROF%TYPE,
      dt_doc_macro_hist_in IN DOC_MACRO_PROF_HIST.DT_DOC_MACRO_HIST%TYPE
      ,
      id_doc_macro_in IN DOC_MACRO_PROF_HIST.ID_DOC_MACRO%TYPE DEFAULT NULL,
      id_professional_in IN DOC_MACRO_PROF_HIST.ID_PROFESSIONAL%TYPE DEFAULT NULL,
      flg_status_in IN DOC_MACRO_PROF_HIST.FLG_STATUS%TYPE DEFAULT NULL,
      dt_creation_in IN DOC_MACRO_PROF_HIST.DT_CREATION%TYPE DEFAULT NULL,
      create_user_in IN DOC_MACRO_PROF_HIST.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN DOC_MACRO_PROF_HIST.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN DOC_MACRO_PROF_HIST.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN DOC_MACRO_PROF_HIST.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN DOC_MACRO_PROF_HIST.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN DOC_MACRO_PROF_HIST.UPDATE_INSTITUTION%TYPE DEFAULT NULL
      -- Pass false if you want errors to propagate out unhandled
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      );

   PROCEDURE ins (
      id_doc_macro_prof_in IN DOC_MACRO_PROF_HIST.ID_DOC_MACRO_PROF%TYPE,
      dt_doc_macro_hist_in IN DOC_MACRO_PROF_HIST.DT_DOC_MACRO_HIST%TYPE
      ,
      id_doc_macro_in IN DOC_MACRO_PROF_HIST.ID_DOC_MACRO%TYPE DEFAULT NULL,
      id_professional_in IN DOC_MACRO_PROF_HIST.ID_PROFESSIONAL%TYPE DEFAULT NULL,
      flg_status_in IN DOC_MACRO_PROF_HIST.FLG_STATUS%TYPE DEFAULT NULL,
      dt_creation_in IN DOC_MACRO_PROF_HIST.DT_CREATION%TYPE DEFAULT NULL,
      create_user_in IN DOC_MACRO_PROF_HIST.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN DOC_MACRO_PROF_HIST.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN DOC_MACRO_PROF_HIST.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN DOC_MACRO_PROF_HIST.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN DOC_MACRO_PROF_HIST.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN DOC_MACRO_PROF_HIST.UPDATE_INSTITUTION%TYPE DEFAULT NULL
      -- Pass false if you want errors to propagate out unhandled
     ,handle_error_in IN BOOLEAN := TRUE
      );


   -- Insert a row based on a record.
   PROCEDURE ins (
      rec_in IN DOC_MACRO_PROF_HIST%ROWTYPE
     ,sequence_in IN VARCHAR2 := NULL
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
   );

   PROCEDURE ins (
      rec_in IN DOC_MACRO_PROF_HIST%ROWTYPE
     ,sequence_in IN VARCHAR2 := NULL
     ,handle_error_in IN BOOLEAN := TRUE
   );

   -- Insert a collection of rows using FORALL; all primary key values
   -- must have already been generated, or are handled in triggers.
   PROCEDURE ins (
      rows_in IN DOC_MACRO_PROF_HIST_tc
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
   );

   PROCEDURE ins (
      rows_in IN DOC_MACRO_PROF_HIST_tc
     ,handle_error_in IN BOOLEAN := TRUE
   );

   -- Update any/all columns by primary key. If you pass NULL, then
   -- the current column value is set to itself. If you need a more
   -- selected UPDATE then use one of the onecol procedures below.

  PROCEDURE upd (
      id_doc_macro_prof_in IN DOC_MACRO_PROF_HIST.ID_DOC_MACRO_PROF%TYPE,
      dt_doc_macro_hist_in IN DOC_MACRO_PROF_HIST.DT_DOC_MACRO_HIST%TYPE,
      id_doc_macro_in IN DOC_MACRO_PROF_HIST.ID_DOC_MACRO%TYPE DEFAULT NULL,
      ID_DOC_MACRO_nin IN BOOLEAN := TRUE,
      id_professional_in IN DOC_MACRO_PROF_HIST.ID_PROFESSIONAL%TYPE DEFAULT NULL,
      ID_PROFESSIONAL_nin IN BOOLEAN := TRUE,
      flg_status_in IN DOC_MACRO_PROF_HIST.FLG_STATUS%TYPE DEFAULT NULL,
      FLG_STATUS_nin IN BOOLEAN := TRUE,
      dt_creation_in IN DOC_MACRO_PROF_HIST.DT_CREATION%TYPE DEFAULT NULL,
      DT_CREATION_nin IN BOOLEAN := TRUE,
      create_user_in IN DOC_MACRO_PROF_HIST.CREATE_USER%TYPE DEFAULT NULL,
      CREATE_USER_nin IN BOOLEAN := TRUE,
      create_time_in IN DOC_MACRO_PROF_HIST.CREATE_TIME%TYPE DEFAULT NULL,
      CREATE_TIME_nin IN BOOLEAN := TRUE,
      create_institution_in IN DOC_MACRO_PROF_HIST.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      CREATE_INSTITUTION_nin IN BOOLEAN := TRUE,
      update_user_in IN DOC_MACRO_PROF_HIST.UPDATE_USER%TYPE DEFAULT NULL,
      UPDATE_USER_nin IN BOOLEAN := TRUE,
      update_time_in IN DOC_MACRO_PROF_HIST.UPDATE_TIME%TYPE DEFAULT NULL,
      UPDATE_TIME_nin IN BOOLEAN := TRUE,
      update_institution_in IN DOC_MACRO_PROF_HIST.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      UPDATE_INSTITUTION_nin IN BOOLEAN := TRUE,
     handle_error_in IN BOOLEAN := TRUE
     , rows_out IN OUT TABLE_VARCHAR
      );


       PROCEDURE upd (
      id_doc_macro_prof_in IN DOC_MACRO_PROF_HIST.ID_DOC_MACRO_PROF%TYPE,
      dt_doc_macro_hist_in IN DOC_MACRO_PROF_HIST.DT_DOC_MACRO_HIST%TYPE,
      id_doc_macro_in IN DOC_MACRO_PROF_HIST.ID_DOC_MACRO%TYPE DEFAULT NULL,
      ID_DOC_MACRO_nin IN BOOLEAN := TRUE,
      id_professional_in IN DOC_MACRO_PROF_HIST.ID_PROFESSIONAL%TYPE DEFAULT NULL,
      ID_PROFESSIONAL_nin IN BOOLEAN := TRUE,
      flg_status_in IN DOC_MACRO_PROF_HIST.FLG_STATUS%TYPE DEFAULT NULL,
      FLG_STATUS_nin IN BOOLEAN := TRUE,
      dt_creation_in IN DOC_MACRO_PROF_HIST.DT_CREATION%TYPE DEFAULT NULL,
      DT_CREATION_nin IN BOOLEAN := TRUE,
      create_user_in IN DOC_MACRO_PROF_HIST.CREATE_USER%TYPE DEFAULT NULL,
      CREATE_USER_nin IN BOOLEAN := TRUE,
      create_time_in IN DOC_MACRO_PROF_HIST.CREATE_TIME%TYPE DEFAULT NULL,
      CREATE_TIME_nin IN BOOLEAN := TRUE,
      create_institution_in IN DOC_MACRO_PROF_HIST.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      CREATE_INSTITUTION_nin IN BOOLEAN := TRUE,
      update_user_in IN DOC_MACRO_PROF_HIST.UPDATE_USER%TYPE DEFAULT NULL,
      UPDATE_USER_nin IN BOOLEAN := TRUE,
      update_time_in IN DOC_MACRO_PROF_HIST.UPDATE_TIME%TYPE DEFAULT NULL,
      UPDATE_TIME_nin IN BOOLEAN := TRUE,
      update_institution_in IN DOC_MACRO_PROF_HIST.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      UPDATE_INSTITUTION_nin IN BOOLEAN := TRUE,
     handle_error_in IN BOOLEAN := TRUE
      );



      PROCEDURE upd (
      id_doc_macro_in IN DOC_MACRO_PROF_HIST.ID_DOC_MACRO%TYPE DEFAULT NULL,
      ID_DOC_MACRO_nin IN BOOLEAN := TRUE,
      id_professional_in IN DOC_MACRO_PROF_HIST.ID_PROFESSIONAL%TYPE DEFAULT NULL,
      ID_PROFESSIONAL_nin IN BOOLEAN := TRUE,
      flg_status_in IN DOC_MACRO_PROF_HIST.FLG_STATUS%TYPE DEFAULT NULL,
      FLG_STATUS_nin IN BOOLEAN := TRUE,
      dt_creation_in IN DOC_MACRO_PROF_HIST.DT_CREATION%TYPE DEFAULT NULL,
      DT_CREATION_nin IN BOOLEAN := TRUE,
      create_user_in IN DOC_MACRO_PROF_HIST.CREATE_USER%TYPE DEFAULT NULL,
      CREATE_USER_nin IN BOOLEAN := TRUE,
      create_time_in IN DOC_MACRO_PROF_HIST.CREATE_TIME%TYPE DEFAULT NULL,
      CREATE_TIME_nin IN BOOLEAN := TRUE,
      create_institution_in IN DOC_MACRO_PROF_HIST.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      CREATE_INSTITUTION_nin IN BOOLEAN := TRUE,
      update_user_in IN DOC_MACRO_PROF_HIST.UPDATE_USER%TYPE DEFAULT NULL,
      UPDATE_USER_nin IN BOOLEAN := TRUE,
      update_time_in IN DOC_MACRO_PROF_HIST.UPDATE_TIME%TYPE DEFAULT NULL,
      UPDATE_TIME_nin IN BOOLEAN := TRUE,
      update_institution_in IN DOC_MACRO_PROF_HIST.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      UPDATE_INSTITUTION_nin IN BOOLEAN := TRUE,
    where_in varchar2,
     handle_error_in IN BOOLEAN := TRUE
     , rows_out IN OUT TABLE_VARCHAR
      );


      PROCEDURE upd (
      id_doc_macro_in IN DOC_MACRO_PROF_HIST.ID_DOC_MACRO%TYPE DEFAULT NULL,
      ID_DOC_MACRO_nin IN BOOLEAN := TRUE,
      id_professional_in IN DOC_MACRO_PROF_HIST.ID_PROFESSIONAL%TYPE DEFAULT NULL,
      ID_PROFESSIONAL_nin IN BOOLEAN := TRUE,
      flg_status_in IN DOC_MACRO_PROF_HIST.FLG_STATUS%TYPE DEFAULT NULL,
      FLG_STATUS_nin IN BOOLEAN := TRUE,
      dt_creation_in IN DOC_MACRO_PROF_HIST.DT_CREATION%TYPE DEFAULT NULL,
      DT_CREATION_nin IN BOOLEAN := TRUE,
      create_user_in IN DOC_MACRO_PROF_HIST.CREATE_USER%TYPE DEFAULT NULL,
      CREATE_USER_nin IN BOOLEAN := TRUE,
      create_time_in IN DOC_MACRO_PROF_HIST.CREATE_TIME%TYPE DEFAULT NULL,
      CREATE_TIME_nin IN BOOLEAN := TRUE,
      create_institution_in IN DOC_MACRO_PROF_HIST.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      CREATE_INSTITUTION_nin IN BOOLEAN := TRUE,
      update_user_in IN DOC_MACRO_PROF_HIST.UPDATE_USER%TYPE DEFAULT NULL,
      UPDATE_USER_nin IN BOOLEAN := TRUE,
      update_time_in IN DOC_MACRO_PROF_HIST.UPDATE_TIME%TYPE DEFAULT NULL,
      UPDATE_TIME_nin IN BOOLEAN := TRUE,
      update_institution_in IN DOC_MACRO_PROF_HIST.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      UPDATE_INSTITUTION_nin IN BOOLEAN := TRUE,
    where_in varchar2,
     handle_error_in IN BOOLEAN := TRUE
      );



   PROCEDURE upd_ins (
      id_doc_macro_prof_in IN DOC_MACRO_PROF_HIST.ID_DOC_MACRO_PROF%TYPE,
      dt_doc_macro_hist_in IN DOC_MACRO_PROF_HIST.DT_DOC_MACRO_HIST%TYPE,
      id_doc_macro_in IN DOC_MACRO_PROF_HIST.ID_DOC_MACRO%TYPE DEFAULT NULL,
      id_professional_in IN DOC_MACRO_PROF_HIST.ID_PROFESSIONAL%TYPE DEFAULT NULL,
      flg_status_in IN DOC_MACRO_PROF_HIST.FLG_STATUS%TYPE DEFAULT NULL,
      dt_creation_in IN DOC_MACRO_PROF_HIST.DT_CREATION%TYPE DEFAULT NULL,
      create_user_in IN DOC_MACRO_PROF_HIST.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN DOC_MACRO_PROF_HIST.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN DOC_MACRO_PROF_HIST.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN DOC_MACRO_PROF_HIST.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN DOC_MACRO_PROF_HIST.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN DOC_MACRO_PROF_HIST.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
     handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      );

      PROCEDURE upd_ins (
      id_doc_macro_prof_in IN DOC_MACRO_PROF_HIST.ID_DOC_MACRO_PROF%TYPE,
      dt_doc_macro_hist_in IN DOC_MACRO_PROF_HIST.DT_DOC_MACRO_HIST%TYPE,
      id_doc_macro_in IN DOC_MACRO_PROF_HIST.ID_DOC_MACRO%TYPE DEFAULT NULL,
      id_professional_in IN DOC_MACRO_PROF_HIST.ID_PROFESSIONAL%TYPE DEFAULT NULL,
      flg_status_in IN DOC_MACRO_PROF_HIST.FLG_STATUS%TYPE DEFAULT NULL,
      dt_creation_in IN DOC_MACRO_PROF_HIST.DT_CREATION%TYPE DEFAULT NULL,
      create_user_in IN DOC_MACRO_PROF_HIST.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN DOC_MACRO_PROF_HIST.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN DOC_MACRO_PROF_HIST.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN DOC_MACRO_PROF_HIST.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN DOC_MACRO_PROF_HIST.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN DOC_MACRO_PROF_HIST.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
     handle_error_in IN BOOLEAN := TRUE
      );

   PROCEDURE upd (
      rec_in IN DOC_MACRO_PROF_HIST%ROWTYPE,
     handle_error_in IN BOOLEAN := TRUE
     , rows_out IN OUT TABLE_VARCHAR
      );

      PROCEDURE upd (
      rec_in IN DOC_MACRO_PROF_HIST%ROWTYPE,
     handle_error_in IN BOOLEAN := TRUE
      );

      PROCEDURE upd (
      col_in IN DOC_MACRO_PROF_HIST_tc,
      ignore_if_null_in IN BOOLEAN := TRUE
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out IN OUT TABLE_VARCHAR
      );

      PROCEDURE upd (
      col_in IN DOC_MACRO_PROF_HIST_tc,
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
      id_doc_macro_prof_in IN DOC_MACRO_PROF_HIST.ID_DOC_MACRO_PROF%TYPE,
      dt_doc_macro_hist_in IN DOC_MACRO_PROF_HIST.DT_DOC_MACRO_HIST%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
      );

-- Delete one row by primary key
   PROCEDURE del (
      id_doc_macro_prof_in IN DOC_MACRO_PROF_HIST.ID_DOC_MACRO_PROF%TYPE,
      dt_doc_macro_hist_in IN DOC_MACRO_PROF_HIST.DT_DOC_MACRO_HIST%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      );


   -- Delete all rows for primary key column ID_DOC_MACRO_PROF
   PROCEDURE del_ID_DOC_MACRO_PROF (
      id_doc_macro_prof_in IN DOC_MACRO_PROF_HIST.ID_DOC_MACRO_PROF%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
     );

     -- Delete all rows for primary key column ID_DOC_MACRO_PROF
   PROCEDURE del_ID_DOC_MACRO_PROF (
      id_doc_macro_prof_in IN DOC_MACRO_PROF_HIST.ID_DOC_MACRO_PROF%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
     );


   -- Delete all rows for primary key column DT_DOC_MACRO_HIST
   PROCEDURE del_DT_DOC_MACRO_HIST (
      dt_doc_macro_hist_in IN DOC_MACRO_PROF_HIST.DT_DOC_MACRO_HIST%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
     );

     -- Delete all rows for primary key column DT_DOC_MACRO_HIST
   PROCEDURE del_DT_DOC_MACRO_HIST (
      dt_doc_macro_hist_in IN DOC_MACRO_PROF_HIST.DT_DOC_MACRO_HIST%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
     );

   -- Delete all rows for this DCMPH_DCMP_FK foreign key value
   PROCEDURE del_DCMPH_DCMP_FK (
      id_doc_macro_prof_in IN DOC_MACRO_PROF_HIST.ID_DOC_MACRO_PROF%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
      );

      -- Delete all rows for this DCMPH_DCMP_FK foreign key value
   PROCEDURE del_DCMPH_DCMP_FK (
      id_doc_macro_prof_in IN DOC_MACRO_PROF_HIST.ID_DOC_MACRO_PROF%TYPE
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
      doc_macro_prof_hist_inout IN OUT DOC_MACRO_PROF_HIST%ROWTYPE
   );

   FUNCTION initrec RETURN DOC_MACRO_PROF_HIST%ROWTYPE;



   FUNCTION get_data_rowid(
        rows_in IN TABLE_VARCHAR
        ) RETURN DOC_MACRO_PROF_HIST_tc;


   FUNCTION get_data_rowid_pat(
        rows_in IN TABLE_VARCHAR
        ) RETURN DOC_MACRO_PROF_HIST_tc;

END TS_DOC_MACRO_PROF_HIST;
/
