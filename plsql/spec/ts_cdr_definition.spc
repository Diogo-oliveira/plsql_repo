/*-- Last Change Revision: $Rev: 1113912 $*/
/*-- Last Change by: $Author: pedro.carneiro $*/
/*-- Date of last change: $Date: 2011-10-07 16:06:04 +0100 (sex, 07 out 2011) $*/
CREATE OR REPLACE PACKAGE TS_CDR_DEFINITION
/*
| Generated by or retrieved from QCGU - DO NOT MODIFY!
| QCGU - "Get it right, do it fast" - www.ToadWorld.com
| QCGU Universal ID: {1BD37A66-EA60-4927-9A64-F6DD89237236}
| Created On: Outubro 7, 2011 15:53:45
| Created By: ALERT
*/
IS

  -- Collection of %ROWTYPE records based on "CDR_DEFINITION"
     TYPE CDR_DEFINITION_tc IS TABLE OF CDR_DEFINITION%ROWTYPE INDEX BY BINARY_INTEGER;
     TYPE cdr_definition_ntt IS TABLE OF CDR_DEFINITION%ROWTYPE;
     TYPE cdr_definition_vat IS VARRAY(100) OF CDR_DEFINITION%ROWTYPE;

  -- Same type structure, with a static name.
     TYPE aat IS TABLE OF CDR_DEFINITION%ROWTYPE INDEX BY BINARY_INTEGER;
     TYPE ntt IS TABLE OF CDR_DEFINITION%ROWTYPE;
     TYPE vat IS VARRAY(100) OF CDR_DEFINITION%ROWTYPE;

   -- Column Collection based on column "ID_CDR_DEFINITION"
   TYPE ID_CDR_DEFINITION_cc IS TABLE OF CDR_DEFINITION.ID_CDR_DEFINITION%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "CODE_NAME"
   TYPE CODE_NAME_cc IS TABLE OF CDR_DEFINITION.CODE_NAME%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "CODE_DESCRIPTION"
   TYPE CODE_DESCRIPTION_cc IS TABLE OF CDR_DEFINITION.CODE_DESCRIPTION%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "FLG_STATUS"
   TYPE FLG_STATUS_cc IS TABLE OF CDR_DEFINITION.FLG_STATUS%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "FLG_ORIGIN"
   TYPE FLG_ORIGIN_cc IS TABLE OF CDR_DEFINITION.FLG_ORIGIN%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "ID_CDR_TYPE"
   TYPE ID_CDR_TYPE_cc IS TABLE OF CDR_DEFINITION.ID_CDR_TYPE%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "ID_INSTITUTION"
   TYPE ID_INSTITUTION_cc IS TABLE OF CDR_DEFINITION.ID_INSTITUTION%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "ID_PROF_CREATE"
   TYPE ID_PROF_CREATE_cc IS TABLE OF CDR_DEFINITION.ID_PROF_CREATE%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "ID_CANCEL_INFO_DET"
   TYPE ID_CANCEL_INFO_DET_cc IS TABLE OF CDR_DEFINITION.ID_CANCEL_INFO_DET%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "CREATE_USER"
   TYPE CREATE_USER_cc IS TABLE OF CDR_DEFINITION.CREATE_USER%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "CREATE_TIME"
   TYPE CREATE_TIME_cc IS TABLE OF CDR_DEFINITION.CREATE_TIME%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "CREATE_INSTITUTION"
   TYPE CREATE_INSTITUTION_cc IS TABLE OF CDR_DEFINITION.CREATE_INSTITUTION%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "UPDATE_USER"
   TYPE UPDATE_USER_cc IS TABLE OF CDR_DEFINITION.UPDATE_USER%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "UPDATE_TIME"
   TYPE UPDATE_TIME_cc IS TABLE OF CDR_DEFINITION.UPDATE_TIME%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "UPDATE_INSTITUTION"
   TYPE UPDATE_INSTITUTION_cc IS TABLE OF CDR_DEFINITION.UPDATE_INSTITUTION%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "ID_CONTENT"
   TYPE ID_CONTENT_cc IS TABLE OF CDR_DEFINITION.ID_CONTENT%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "FLG_AVAILABLE"
   TYPE FLG_AVAILABLE_cc IS TABLE OF CDR_DEFINITION.FLG_AVAILABLE%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "FLG_GENERIC"
   TYPE FLG_GENERIC_cc IS TABLE OF CDR_DEFINITION.FLG_GENERIC%TYPE INDEX BY BINARY_INTEGER;

   -- Insert one row, providing primary key if present
   PROCEDURE ins (
      id_cdr_definition_in IN CDR_DEFINITION.ID_CDR_DEFINITION%TYPE
      ,
      code_name_in IN CDR_DEFINITION.CODE_NAME%TYPE DEFAULT NULL,
      code_description_in IN CDR_DEFINITION.CODE_DESCRIPTION%TYPE DEFAULT NULL,
      flg_status_in IN CDR_DEFINITION.FLG_STATUS%TYPE DEFAULT 'A',
      flg_origin_in IN CDR_DEFINITION.FLG_ORIGIN%TYPE DEFAULT 'L',
      id_cdr_type_in IN CDR_DEFINITION.ID_CDR_TYPE%TYPE DEFAULT NULL,
      id_institution_in IN CDR_DEFINITION.ID_INSTITUTION%TYPE DEFAULT NULL,
      id_prof_create_in IN CDR_DEFINITION.ID_PROF_CREATE%TYPE DEFAULT NULL,
      id_cancel_info_det_in IN CDR_DEFINITION.ID_CANCEL_INFO_DET%TYPE DEFAULT NULL,
      create_user_in IN CDR_DEFINITION.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN CDR_DEFINITION.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN CDR_DEFINITION.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN CDR_DEFINITION.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN CDR_DEFINITION.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN CDR_DEFINITION.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      id_content_in IN CDR_DEFINITION.ID_CONTENT%TYPE DEFAULT NULL,
      flg_available_in IN CDR_DEFINITION.FLG_AVAILABLE%TYPE DEFAULT 'Y',
      flg_generic_in IN CDR_DEFINITION.FLG_GENERIC%TYPE DEFAULT 'Y'
      -- Pass false if you want errors to propagate out unhandled
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      );

   PROCEDURE ins (
      id_cdr_definition_in IN CDR_DEFINITION.ID_CDR_DEFINITION%TYPE
      ,
      code_name_in IN CDR_DEFINITION.CODE_NAME%TYPE DEFAULT NULL,
      code_description_in IN CDR_DEFINITION.CODE_DESCRIPTION%TYPE DEFAULT NULL,
      flg_status_in IN CDR_DEFINITION.FLG_STATUS%TYPE DEFAULT 'A',
      flg_origin_in IN CDR_DEFINITION.FLG_ORIGIN%TYPE DEFAULT 'L',
      id_cdr_type_in IN CDR_DEFINITION.ID_CDR_TYPE%TYPE DEFAULT NULL,
      id_institution_in IN CDR_DEFINITION.ID_INSTITUTION%TYPE DEFAULT NULL,
      id_prof_create_in IN CDR_DEFINITION.ID_PROF_CREATE%TYPE DEFAULT NULL,
      id_cancel_info_det_in IN CDR_DEFINITION.ID_CANCEL_INFO_DET%TYPE DEFAULT NULL,
      create_user_in IN CDR_DEFINITION.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN CDR_DEFINITION.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN CDR_DEFINITION.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN CDR_DEFINITION.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN CDR_DEFINITION.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN CDR_DEFINITION.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      id_content_in IN CDR_DEFINITION.ID_CONTENT%TYPE DEFAULT NULL,
      flg_available_in IN CDR_DEFINITION.FLG_AVAILABLE%TYPE DEFAULT 'Y',
      flg_generic_in IN CDR_DEFINITION.FLG_GENERIC%TYPE DEFAULT 'Y'
      -- Pass false if you want errors to propagate out unhandled
     ,handle_error_in IN BOOLEAN := TRUE
      );


   -- Insert a row based on a record.
   -- Specify whether or not a primary key value should be generated.
   PROCEDURE ins (
      rec_in IN CDR_DEFINITION%ROWTYPE
     ,gen_pky_in IN BOOLEAN DEFAULT FALSE
     ,sequence_in IN VARCHAR2 := NULL
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
   );

   PROCEDURE ins (
      rec_in IN CDR_DEFINITION%ROWTYPE
     ,gen_pky_in IN BOOLEAN DEFAULT FALSE
     ,sequence_in IN VARCHAR2 := NULL
     ,handle_error_in IN BOOLEAN := TRUE
   );

   -- Insert a collection of rows using FORALL; all primary key values
   -- must have already been generated, or are handled in triggers.
   PROCEDURE ins (
      rows_in IN CDR_DEFINITION_tc
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
   );

   PROCEDURE ins (
      rows_in IN CDR_DEFINITION_tc
     ,handle_error_in IN BOOLEAN := TRUE
   );

   -- Return next primary key value using the named sequence.
     FUNCTION next_key (sequence_in IN VARCHAR2 := NULL) RETURN CDR_DEFINITION.ID_CDR_DEFINITION%TYPE;

   -- Insert one row, generating hidden primary key using a sequence
   PROCEDURE ins (
      code_name_in IN CDR_DEFINITION.CODE_NAME%TYPE DEFAULT NULL,
      code_description_in IN CDR_DEFINITION.CODE_DESCRIPTION%TYPE DEFAULT NULL,
      flg_status_in IN CDR_DEFINITION.FLG_STATUS%TYPE DEFAULT 'A',
      flg_origin_in IN CDR_DEFINITION.FLG_ORIGIN%TYPE DEFAULT 'L',
      id_cdr_type_in IN CDR_DEFINITION.ID_CDR_TYPE%TYPE DEFAULT NULL,
      id_institution_in IN CDR_DEFINITION.ID_INSTITUTION%TYPE DEFAULT NULL,
      id_prof_create_in IN CDR_DEFINITION.ID_PROF_CREATE%TYPE DEFAULT NULL,
      id_cancel_info_det_in IN CDR_DEFINITION.ID_CANCEL_INFO_DET%TYPE DEFAULT NULL,
      create_user_in IN CDR_DEFINITION.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN CDR_DEFINITION.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN CDR_DEFINITION.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN CDR_DEFINITION.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN CDR_DEFINITION.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN CDR_DEFINITION.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      id_content_in IN CDR_DEFINITION.ID_CONTENT%TYPE DEFAULT NULL,
      flg_available_in IN CDR_DEFINITION.FLG_AVAILABLE%TYPE DEFAULT 'Y',
      flg_generic_in IN CDR_DEFINITION.FLG_GENERIC%TYPE DEFAULT 'Y'
      -- Pass false if you want errors to propagate out unhandled
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      );

   PROCEDURE ins (
      code_name_in IN CDR_DEFINITION.CODE_NAME%TYPE DEFAULT NULL,
      code_description_in IN CDR_DEFINITION.CODE_DESCRIPTION%TYPE DEFAULT NULL,
      flg_status_in IN CDR_DEFINITION.FLG_STATUS%TYPE DEFAULT 'A',
      flg_origin_in IN CDR_DEFINITION.FLG_ORIGIN%TYPE DEFAULT 'L',
      id_cdr_type_in IN CDR_DEFINITION.ID_CDR_TYPE%TYPE DEFAULT NULL,
      id_institution_in IN CDR_DEFINITION.ID_INSTITUTION%TYPE DEFAULT NULL,
      id_prof_create_in IN CDR_DEFINITION.ID_PROF_CREATE%TYPE DEFAULT NULL,
      id_cancel_info_det_in IN CDR_DEFINITION.ID_CANCEL_INFO_DET%TYPE DEFAULT NULL,
      create_user_in IN CDR_DEFINITION.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN CDR_DEFINITION.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN CDR_DEFINITION.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN CDR_DEFINITION.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN CDR_DEFINITION.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN CDR_DEFINITION.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      id_content_in IN CDR_DEFINITION.ID_CONTENT%TYPE DEFAULT NULL,
      flg_available_in IN CDR_DEFINITION.FLG_AVAILABLE%TYPE DEFAULT 'Y',
      flg_generic_in IN CDR_DEFINITION.FLG_GENERIC%TYPE DEFAULT 'Y'
      -- Pass false if you want errors to propagate out unhandled
     ,handle_error_in IN BOOLEAN := TRUE
      );

   -- Insert one row, returning primary key generated by sequence
   PROCEDURE ins (
      code_name_in IN CDR_DEFINITION.CODE_NAME%TYPE DEFAULT NULL,
      code_description_in IN CDR_DEFINITION.CODE_DESCRIPTION%TYPE DEFAULT NULL,
      flg_status_in IN CDR_DEFINITION.FLG_STATUS%TYPE DEFAULT 'A',
      flg_origin_in IN CDR_DEFINITION.FLG_ORIGIN%TYPE DEFAULT 'L',
      id_cdr_type_in IN CDR_DEFINITION.ID_CDR_TYPE%TYPE DEFAULT NULL,
      id_institution_in IN CDR_DEFINITION.ID_INSTITUTION%TYPE DEFAULT NULL,
      id_prof_create_in IN CDR_DEFINITION.ID_PROF_CREATE%TYPE DEFAULT NULL,
      id_cancel_info_det_in IN CDR_DEFINITION.ID_CANCEL_INFO_DET%TYPE DEFAULT NULL,
      create_user_in IN CDR_DEFINITION.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN CDR_DEFINITION.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN CDR_DEFINITION.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN CDR_DEFINITION.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN CDR_DEFINITION.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN CDR_DEFINITION.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      id_content_in IN CDR_DEFINITION.ID_CONTENT%TYPE DEFAULT NULL,
      flg_available_in IN CDR_DEFINITION.FLG_AVAILABLE%TYPE DEFAULT 'Y',
      flg_generic_in IN CDR_DEFINITION.FLG_GENERIC%TYPE DEFAULT 'Y',
      id_cdr_definition_out IN OUT CDR_DEFINITION.ID_CDR_DEFINITION%TYPE
      -- Pass false if you want errors to propagate out unhandled
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      );

   PROCEDURE ins (
      code_name_in IN CDR_DEFINITION.CODE_NAME%TYPE DEFAULT NULL,
      code_description_in IN CDR_DEFINITION.CODE_DESCRIPTION%TYPE DEFAULT NULL,
      flg_status_in IN CDR_DEFINITION.FLG_STATUS%TYPE DEFAULT 'A',
      flg_origin_in IN CDR_DEFINITION.FLG_ORIGIN%TYPE DEFAULT 'L',
      id_cdr_type_in IN CDR_DEFINITION.ID_CDR_TYPE%TYPE DEFAULT NULL,
      id_institution_in IN CDR_DEFINITION.ID_INSTITUTION%TYPE DEFAULT NULL,
      id_prof_create_in IN CDR_DEFINITION.ID_PROF_CREATE%TYPE DEFAULT NULL,
      id_cancel_info_det_in IN CDR_DEFINITION.ID_CANCEL_INFO_DET%TYPE DEFAULT NULL,
      create_user_in IN CDR_DEFINITION.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN CDR_DEFINITION.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN CDR_DEFINITION.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN CDR_DEFINITION.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN CDR_DEFINITION.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN CDR_DEFINITION.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      id_content_in IN CDR_DEFINITION.ID_CONTENT%TYPE DEFAULT NULL,
      flg_available_in IN CDR_DEFINITION.FLG_AVAILABLE%TYPE DEFAULT 'Y',
      flg_generic_in IN CDR_DEFINITION.FLG_GENERIC%TYPE DEFAULT 'Y',
      id_cdr_definition_out IN OUT CDR_DEFINITION.ID_CDR_DEFINITION%TYPE
      -- Pass false if you want errors to propagate out unhandled
     ,handle_error_in IN BOOLEAN := TRUE
      );

   -- Insert one row with function, return generated primary key
   FUNCTION ins (
      code_name_in IN CDR_DEFINITION.CODE_NAME%TYPE DEFAULT NULL,
      code_description_in IN CDR_DEFINITION.CODE_DESCRIPTION%TYPE DEFAULT NULL,
      flg_status_in IN CDR_DEFINITION.FLG_STATUS%TYPE DEFAULT 'A',
      flg_origin_in IN CDR_DEFINITION.FLG_ORIGIN%TYPE DEFAULT 'L',
      id_cdr_type_in IN CDR_DEFINITION.ID_CDR_TYPE%TYPE DEFAULT NULL,
      id_institution_in IN CDR_DEFINITION.ID_INSTITUTION%TYPE DEFAULT NULL,
      id_prof_create_in IN CDR_DEFINITION.ID_PROF_CREATE%TYPE DEFAULT NULL,
      id_cancel_info_det_in IN CDR_DEFINITION.ID_CANCEL_INFO_DET%TYPE DEFAULT NULL,
      create_user_in IN CDR_DEFINITION.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN CDR_DEFINITION.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN CDR_DEFINITION.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN CDR_DEFINITION.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN CDR_DEFINITION.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN CDR_DEFINITION.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      id_content_in IN CDR_DEFINITION.ID_CONTENT%TYPE DEFAULT NULL,
      flg_available_in IN CDR_DEFINITION.FLG_AVAILABLE%TYPE DEFAULT 'Y',
      flg_generic_in IN CDR_DEFINITION.FLG_GENERIC%TYPE DEFAULT 'Y'
      -- Pass false if you want errors to propagate out unhandled
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      )
      RETURN
         CDR_DEFINITION.ID_CDR_DEFINITION%TYPE
      ;

   FUNCTION ins (
      code_name_in IN CDR_DEFINITION.CODE_NAME%TYPE DEFAULT NULL,
      code_description_in IN CDR_DEFINITION.CODE_DESCRIPTION%TYPE DEFAULT NULL,
      flg_status_in IN CDR_DEFINITION.FLG_STATUS%TYPE DEFAULT 'A',
      flg_origin_in IN CDR_DEFINITION.FLG_ORIGIN%TYPE DEFAULT 'L',
      id_cdr_type_in IN CDR_DEFINITION.ID_CDR_TYPE%TYPE DEFAULT NULL,
      id_institution_in IN CDR_DEFINITION.ID_INSTITUTION%TYPE DEFAULT NULL,
      id_prof_create_in IN CDR_DEFINITION.ID_PROF_CREATE%TYPE DEFAULT NULL,
      id_cancel_info_det_in IN CDR_DEFINITION.ID_CANCEL_INFO_DET%TYPE DEFAULT NULL,
      create_user_in IN CDR_DEFINITION.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN CDR_DEFINITION.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN CDR_DEFINITION.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN CDR_DEFINITION.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN CDR_DEFINITION.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN CDR_DEFINITION.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      id_content_in IN CDR_DEFINITION.ID_CONTENT%TYPE DEFAULT NULL,
      flg_available_in IN CDR_DEFINITION.FLG_AVAILABLE%TYPE DEFAULT 'Y',
      flg_generic_in IN CDR_DEFINITION.FLG_GENERIC%TYPE DEFAULT 'Y'
      -- Pass false if you want errors to propagate out unhandled
     ,handle_error_in IN BOOLEAN := TRUE
      )
      RETURN
         CDR_DEFINITION.ID_CDR_DEFINITION%TYPE
      ;

   -- Update any/all columns by primary key. If you pass NULL, then
   -- the current column value is set to itself. If you need a more
   -- selected UPDATE then use one of the onecol procedures below.

  PROCEDURE upd (
      id_cdr_definition_in IN CDR_DEFINITION.ID_CDR_DEFINITION%TYPE,
      code_name_in IN CDR_DEFINITION.CODE_NAME%TYPE DEFAULT NULL,
      CODE_NAME_nin IN BOOLEAN := TRUE,
      code_description_in IN CDR_DEFINITION.CODE_DESCRIPTION%TYPE DEFAULT NULL,
      CODE_DESCRIPTION_nin IN BOOLEAN := TRUE,
      flg_status_in IN CDR_DEFINITION.FLG_STATUS%TYPE DEFAULT NULL,
      FLG_STATUS_nin IN BOOLEAN := TRUE,
      flg_origin_in IN CDR_DEFINITION.FLG_ORIGIN%TYPE DEFAULT NULL,
      FLG_ORIGIN_nin IN BOOLEAN := TRUE,
      id_cdr_type_in IN CDR_DEFINITION.ID_CDR_TYPE%TYPE DEFAULT NULL,
      ID_CDR_TYPE_nin IN BOOLEAN := TRUE,
      id_institution_in IN CDR_DEFINITION.ID_INSTITUTION%TYPE DEFAULT NULL,
      ID_INSTITUTION_nin IN BOOLEAN := TRUE,
      id_prof_create_in IN CDR_DEFINITION.ID_PROF_CREATE%TYPE DEFAULT NULL,
      ID_PROF_CREATE_nin IN BOOLEAN := TRUE,
      id_cancel_info_det_in IN CDR_DEFINITION.ID_CANCEL_INFO_DET%TYPE DEFAULT NULL,
      ID_CANCEL_INFO_DET_nin IN BOOLEAN := TRUE,
      create_user_in IN CDR_DEFINITION.CREATE_USER%TYPE DEFAULT NULL,
      CREATE_USER_nin IN BOOLEAN := TRUE,
      create_time_in IN CDR_DEFINITION.CREATE_TIME%TYPE DEFAULT NULL,
      CREATE_TIME_nin IN BOOLEAN := TRUE,
      create_institution_in IN CDR_DEFINITION.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      CREATE_INSTITUTION_nin IN BOOLEAN := TRUE,
      update_user_in IN CDR_DEFINITION.UPDATE_USER%TYPE DEFAULT NULL,
      UPDATE_USER_nin IN BOOLEAN := TRUE,
      update_time_in IN CDR_DEFINITION.UPDATE_TIME%TYPE DEFAULT NULL,
      UPDATE_TIME_nin IN BOOLEAN := TRUE,
      update_institution_in IN CDR_DEFINITION.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      UPDATE_INSTITUTION_nin IN BOOLEAN := TRUE,
      id_content_in IN CDR_DEFINITION.ID_CONTENT%TYPE DEFAULT NULL,
      ID_CONTENT_nin IN BOOLEAN := TRUE,
      flg_available_in IN CDR_DEFINITION.FLG_AVAILABLE%TYPE DEFAULT NULL,
      FLG_AVAILABLE_nin IN BOOLEAN := TRUE,
      flg_generic_in IN CDR_DEFINITION.FLG_GENERIC%TYPE DEFAULT NULL,
      FLG_GENERIC_nin IN BOOLEAN := TRUE,
     handle_error_in IN BOOLEAN := TRUE
     , rows_out IN OUT TABLE_VARCHAR
      );


       PROCEDURE upd (
      id_cdr_definition_in IN CDR_DEFINITION.ID_CDR_DEFINITION%TYPE,
      code_name_in IN CDR_DEFINITION.CODE_NAME%TYPE DEFAULT NULL,
      CODE_NAME_nin IN BOOLEAN := TRUE,
      code_description_in IN CDR_DEFINITION.CODE_DESCRIPTION%TYPE DEFAULT NULL,
      CODE_DESCRIPTION_nin IN BOOLEAN := TRUE,
      flg_status_in IN CDR_DEFINITION.FLG_STATUS%TYPE DEFAULT NULL,
      FLG_STATUS_nin IN BOOLEAN := TRUE,
      flg_origin_in IN CDR_DEFINITION.FLG_ORIGIN%TYPE DEFAULT NULL,
      FLG_ORIGIN_nin IN BOOLEAN := TRUE,
      id_cdr_type_in IN CDR_DEFINITION.ID_CDR_TYPE%TYPE DEFAULT NULL,
      ID_CDR_TYPE_nin IN BOOLEAN := TRUE,
      id_institution_in IN CDR_DEFINITION.ID_INSTITUTION%TYPE DEFAULT NULL,
      ID_INSTITUTION_nin IN BOOLEAN := TRUE,
      id_prof_create_in IN CDR_DEFINITION.ID_PROF_CREATE%TYPE DEFAULT NULL,
      ID_PROF_CREATE_nin IN BOOLEAN := TRUE,
      id_cancel_info_det_in IN CDR_DEFINITION.ID_CANCEL_INFO_DET%TYPE DEFAULT NULL,
      ID_CANCEL_INFO_DET_nin IN BOOLEAN := TRUE,
      create_user_in IN CDR_DEFINITION.CREATE_USER%TYPE DEFAULT NULL,
      CREATE_USER_nin IN BOOLEAN := TRUE,
      create_time_in IN CDR_DEFINITION.CREATE_TIME%TYPE DEFAULT NULL,
      CREATE_TIME_nin IN BOOLEAN := TRUE,
      create_institution_in IN CDR_DEFINITION.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      CREATE_INSTITUTION_nin IN BOOLEAN := TRUE,
      update_user_in IN CDR_DEFINITION.UPDATE_USER%TYPE DEFAULT NULL,
      UPDATE_USER_nin IN BOOLEAN := TRUE,
      update_time_in IN CDR_DEFINITION.UPDATE_TIME%TYPE DEFAULT NULL,
      UPDATE_TIME_nin IN BOOLEAN := TRUE,
      update_institution_in IN CDR_DEFINITION.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      UPDATE_INSTITUTION_nin IN BOOLEAN := TRUE,
      id_content_in IN CDR_DEFINITION.ID_CONTENT%TYPE DEFAULT NULL,
      ID_CONTENT_nin IN BOOLEAN := TRUE,
      flg_available_in IN CDR_DEFINITION.FLG_AVAILABLE%TYPE DEFAULT NULL,
      FLG_AVAILABLE_nin IN BOOLEAN := TRUE,
      flg_generic_in IN CDR_DEFINITION.FLG_GENERIC%TYPE DEFAULT NULL,
      FLG_GENERIC_nin IN BOOLEAN := TRUE,
     handle_error_in IN BOOLEAN := TRUE
      );



      PROCEDURE upd (
      code_name_in IN CDR_DEFINITION.CODE_NAME%TYPE DEFAULT NULL,
      CODE_NAME_nin IN BOOLEAN := TRUE,
      code_description_in IN CDR_DEFINITION.CODE_DESCRIPTION%TYPE DEFAULT NULL,
      CODE_DESCRIPTION_nin IN BOOLEAN := TRUE,
      flg_status_in IN CDR_DEFINITION.FLG_STATUS%TYPE DEFAULT NULL,
      FLG_STATUS_nin IN BOOLEAN := TRUE,
      flg_origin_in IN CDR_DEFINITION.FLG_ORIGIN%TYPE DEFAULT NULL,
      FLG_ORIGIN_nin IN BOOLEAN := TRUE,
      id_cdr_type_in IN CDR_DEFINITION.ID_CDR_TYPE%TYPE DEFAULT NULL,
      ID_CDR_TYPE_nin IN BOOLEAN := TRUE,
      id_institution_in IN CDR_DEFINITION.ID_INSTITUTION%TYPE DEFAULT NULL,
      ID_INSTITUTION_nin IN BOOLEAN := TRUE,
      id_prof_create_in IN CDR_DEFINITION.ID_PROF_CREATE%TYPE DEFAULT NULL,
      ID_PROF_CREATE_nin IN BOOLEAN := TRUE,
      id_cancel_info_det_in IN CDR_DEFINITION.ID_CANCEL_INFO_DET%TYPE DEFAULT NULL,
      ID_CANCEL_INFO_DET_nin IN BOOLEAN := TRUE,
      create_user_in IN CDR_DEFINITION.CREATE_USER%TYPE DEFAULT NULL,
      CREATE_USER_nin IN BOOLEAN := TRUE,
      create_time_in IN CDR_DEFINITION.CREATE_TIME%TYPE DEFAULT NULL,
      CREATE_TIME_nin IN BOOLEAN := TRUE,
      create_institution_in IN CDR_DEFINITION.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      CREATE_INSTITUTION_nin IN BOOLEAN := TRUE,
      update_user_in IN CDR_DEFINITION.UPDATE_USER%TYPE DEFAULT NULL,
      UPDATE_USER_nin IN BOOLEAN := TRUE,
      update_time_in IN CDR_DEFINITION.UPDATE_TIME%TYPE DEFAULT NULL,
      UPDATE_TIME_nin IN BOOLEAN := TRUE,
      update_institution_in IN CDR_DEFINITION.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      UPDATE_INSTITUTION_nin IN BOOLEAN := TRUE,
      id_content_in IN CDR_DEFINITION.ID_CONTENT%TYPE DEFAULT NULL,
      ID_CONTENT_nin IN BOOLEAN := TRUE,
      flg_available_in IN CDR_DEFINITION.FLG_AVAILABLE%TYPE DEFAULT NULL,
      FLG_AVAILABLE_nin IN BOOLEAN := TRUE,
      flg_generic_in IN CDR_DEFINITION.FLG_GENERIC%TYPE DEFAULT NULL,
      FLG_GENERIC_nin IN BOOLEAN := TRUE,
    where_in varchar2,
     handle_error_in IN BOOLEAN := TRUE
     , rows_out IN OUT TABLE_VARCHAR
      );


      PROCEDURE upd (
      code_name_in IN CDR_DEFINITION.CODE_NAME%TYPE DEFAULT NULL,
      CODE_NAME_nin IN BOOLEAN := TRUE,
      code_description_in IN CDR_DEFINITION.CODE_DESCRIPTION%TYPE DEFAULT NULL,
      CODE_DESCRIPTION_nin IN BOOLEAN := TRUE,
      flg_status_in IN CDR_DEFINITION.FLG_STATUS%TYPE DEFAULT NULL,
      FLG_STATUS_nin IN BOOLEAN := TRUE,
      flg_origin_in IN CDR_DEFINITION.FLG_ORIGIN%TYPE DEFAULT NULL,
      FLG_ORIGIN_nin IN BOOLEAN := TRUE,
      id_cdr_type_in IN CDR_DEFINITION.ID_CDR_TYPE%TYPE DEFAULT NULL,
      ID_CDR_TYPE_nin IN BOOLEAN := TRUE,
      id_institution_in IN CDR_DEFINITION.ID_INSTITUTION%TYPE DEFAULT NULL,
      ID_INSTITUTION_nin IN BOOLEAN := TRUE,
      id_prof_create_in IN CDR_DEFINITION.ID_PROF_CREATE%TYPE DEFAULT NULL,
      ID_PROF_CREATE_nin IN BOOLEAN := TRUE,
      id_cancel_info_det_in IN CDR_DEFINITION.ID_CANCEL_INFO_DET%TYPE DEFAULT NULL,
      ID_CANCEL_INFO_DET_nin IN BOOLEAN := TRUE,
      create_user_in IN CDR_DEFINITION.CREATE_USER%TYPE DEFAULT NULL,
      CREATE_USER_nin IN BOOLEAN := TRUE,
      create_time_in IN CDR_DEFINITION.CREATE_TIME%TYPE DEFAULT NULL,
      CREATE_TIME_nin IN BOOLEAN := TRUE,
      create_institution_in IN CDR_DEFINITION.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      CREATE_INSTITUTION_nin IN BOOLEAN := TRUE,
      update_user_in IN CDR_DEFINITION.UPDATE_USER%TYPE DEFAULT NULL,
      UPDATE_USER_nin IN BOOLEAN := TRUE,
      update_time_in IN CDR_DEFINITION.UPDATE_TIME%TYPE DEFAULT NULL,
      UPDATE_TIME_nin IN BOOLEAN := TRUE,
      update_institution_in IN CDR_DEFINITION.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      UPDATE_INSTITUTION_nin IN BOOLEAN := TRUE,
      id_content_in IN CDR_DEFINITION.ID_CONTENT%TYPE DEFAULT NULL,
      ID_CONTENT_nin IN BOOLEAN := TRUE,
      flg_available_in IN CDR_DEFINITION.FLG_AVAILABLE%TYPE DEFAULT NULL,
      FLG_AVAILABLE_nin IN BOOLEAN := TRUE,
      flg_generic_in IN CDR_DEFINITION.FLG_GENERIC%TYPE DEFAULT NULL,
      FLG_GENERIC_nin IN BOOLEAN := TRUE,
    where_in varchar2,
     handle_error_in IN BOOLEAN := TRUE
      );



   PROCEDURE upd_ins (
      id_cdr_definition_in IN CDR_DEFINITION.ID_CDR_DEFINITION%TYPE,
      code_name_in IN CDR_DEFINITION.CODE_NAME%TYPE DEFAULT NULL,
      code_description_in IN CDR_DEFINITION.CODE_DESCRIPTION%TYPE DEFAULT NULL,
      flg_status_in IN CDR_DEFINITION.FLG_STATUS%TYPE DEFAULT NULL,
      flg_origin_in IN CDR_DEFINITION.FLG_ORIGIN%TYPE DEFAULT NULL,
      id_cdr_type_in IN CDR_DEFINITION.ID_CDR_TYPE%TYPE DEFAULT NULL,
      id_institution_in IN CDR_DEFINITION.ID_INSTITUTION%TYPE DEFAULT NULL,
      id_prof_create_in IN CDR_DEFINITION.ID_PROF_CREATE%TYPE DEFAULT NULL,
      id_cancel_info_det_in IN CDR_DEFINITION.ID_CANCEL_INFO_DET%TYPE DEFAULT NULL,
      create_user_in IN CDR_DEFINITION.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN CDR_DEFINITION.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN CDR_DEFINITION.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN CDR_DEFINITION.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN CDR_DEFINITION.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN CDR_DEFINITION.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      id_content_in IN CDR_DEFINITION.ID_CONTENT%TYPE DEFAULT NULL,
      flg_available_in IN CDR_DEFINITION.FLG_AVAILABLE%TYPE DEFAULT NULL,
      flg_generic_in IN CDR_DEFINITION.FLG_GENERIC%TYPE DEFAULT NULL,
     handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      );

      PROCEDURE upd_ins (
      id_cdr_definition_in IN CDR_DEFINITION.ID_CDR_DEFINITION%TYPE,
      code_name_in IN CDR_DEFINITION.CODE_NAME%TYPE DEFAULT NULL,
      code_description_in IN CDR_DEFINITION.CODE_DESCRIPTION%TYPE DEFAULT NULL,
      flg_status_in IN CDR_DEFINITION.FLG_STATUS%TYPE DEFAULT NULL,
      flg_origin_in IN CDR_DEFINITION.FLG_ORIGIN%TYPE DEFAULT NULL,
      id_cdr_type_in IN CDR_DEFINITION.ID_CDR_TYPE%TYPE DEFAULT NULL,
      id_institution_in IN CDR_DEFINITION.ID_INSTITUTION%TYPE DEFAULT NULL,
      id_prof_create_in IN CDR_DEFINITION.ID_PROF_CREATE%TYPE DEFAULT NULL,
      id_cancel_info_det_in IN CDR_DEFINITION.ID_CANCEL_INFO_DET%TYPE DEFAULT NULL,
      create_user_in IN CDR_DEFINITION.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN CDR_DEFINITION.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN CDR_DEFINITION.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN CDR_DEFINITION.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN CDR_DEFINITION.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN CDR_DEFINITION.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      id_content_in IN CDR_DEFINITION.ID_CONTENT%TYPE DEFAULT NULL,
      flg_available_in IN CDR_DEFINITION.FLG_AVAILABLE%TYPE DEFAULT NULL,
      flg_generic_in IN CDR_DEFINITION.FLG_GENERIC%TYPE DEFAULT NULL,
     handle_error_in IN BOOLEAN := TRUE
      );

   PROCEDURE upd (
      rec_in IN CDR_DEFINITION%ROWTYPE,
     handle_error_in IN BOOLEAN := TRUE
     , rows_out IN OUT TABLE_VARCHAR
      );

      PROCEDURE upd (
      rec_in IN CDR_DEFINITION%ROWTYPE,
     handle_error_in IN BOOLEAN := TRUE
      );

      PROCEDURE upd (
      col_in IN CDR_DEFINITION_tc,
      ignore_if_null_in IN BOOLEAN := TRUE
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out IN OUT TABLE_VARCHAR
      );

      PROCEDURE upd (
      col_in IN CDR_DEFINITION_tc,
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
      id_cdr_definition_in IN CDR_DEFINITION.ID_CDR_DEFINITION%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
      );

-- Delete one row by primary key
   PROCEDURE del (
      id_cdr_definition_in IN CDR_DEFINITION.ID_CDR_DEFINITION%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      );


   -- Delete all rows for primary key column ID_CDR_DEFINITION
   PROCEDURE del_ID_CDR_DEFINITION (
      id_cdr_definition_in IN CDR_DEFINITION.ID_CDR_DEFINITION%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
     );

     -- Delete all rows for primary key column ID_CDR_DEFINITION
   PROCEDURE del_ID_CDR_DEFINITION (
      id_cdr_definition_in IN CDR_DEFINITION.ID_CDR_DEFINITION%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
     );

   -- Delete all rows for this CDRD_CDRT_FK foreign key value
   PROCEDURE del_CDRD_CDRT_FK (
      id_cdr_type_in IN CDR_DEFINITION.ID_CDR_TYPE%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
      );

      -- Delete all rows for this CDRD_CDRT_FK foreign key value
   PROCEDURE del_CDRD_CDRT_FK (
      id_cdr_type_in IN CDR_DEFINITION.ID_CDR_TYPE%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      );

   -- Delete all rows for this CDRD_CID_FK foreign key value
   PROCEDURE del_CDRD_CID_FK (
      id_cancel_info_det_in IN CDR_DEFINITION.ID_CANCEL_INFO_DET%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
      );

      -- Delete all rows for this CDRD_CID_FK foreign key value
   PROCEDURE del_CDRD_CID_FK (
      id_cancel_info_det_in IN CDR_DEFINITION.ID_CANCEL_INFO_DET%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      );

   -- Delete all rows for this CDRD_INST_FK foreign key value
   PROCEDURE del_CDRD_INST_FK (
      id_institution_in IN CDR_DEFINITION.ID_INSTITUTION%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
      );

      -- Delete all rows for this CDRD_INST_FK foreign key value
   PROCEDURE del_CDRD_INST_FK (
      id_institution_in IN CDR_DEFINITION.ID_INSTITUTION%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      );

   -- Delete all rows for this CDRD_PROF_FK foreign key value
   PROCEDURE del_CDRD_PROF_FK (
      id_prof_create_in IN CDR_DEFINITION.ID_PROF_CREATE%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
      );

      -- Delete all rows for this CDRD_PROF_FK foreign key value
   PROCEDURE del_CDRD_PROF_FK (
      id_prof_create_in IN CDR_DEFINITION.ID_PROF_CREATE%TYPE
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
      cdr_definition_inout IN OUT CDR_DEFINITION%ROWTYPE
   );

   FUNCTION initrec RETURN CDR_DEFINITION%ROWTYPE;



   FUNCTION get_data_rowid(
        rows_in IN TABLE_VARCHAR
        ) RETURN CDR_DEFINITION_tc;


   FUNCTION get_data_rowid_pat(
        rows_in IN TABLE_VARCHAR
        ) RETURN CDR_DEFINITION_tc;

END TS_CDR_DEFINITION;
/
