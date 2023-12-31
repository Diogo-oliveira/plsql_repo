/*-- Last Change Revision: $Rev: 1658071 $*/
/*-- Last Change by: $Author: ariel.machado $*/
/*-- Date of last change: $Date: 2014-11-10 09:49:40 +0000 (seg, 10 nov 2014) $*/
CREATE OR REPLACE PACKAGE TS_NAN_DIAGNOSIS
/*
| Generated by or retrieved from QCGU - DO NOT MODIFY!
| QCGU - "Get it right, do it fast" - www.ToadWorld.com
| QCGU Universal ID: {1BD37A66-EA60-4927-9A64-F6DD89237236}
| Created On: Outubro 3, 2013 16:31:39
| Created By: ALERT
*/
IS

  -- Collection of %ROWTYPE records based on "NAN_DIAGNOSIS"
     TYPE NAN_DIAGNOSIS_tc IS TABLE OF NAN_DIAGNOSIS%ROWTYPE INDEX BY BINARY_INTEGER;
     TYPE nan_diagnosis_ntt IS TABLE OF NAN_DIAGNOSIS%ROWTYPE;
     TYPE nan_diagnosis_vat IS VARRAY(100) OF NAN_DIAGNOSIS%ROWTYPE;

  -- Same type structure, with a static name.
     TYPE aat IS TABLE OF NAN_DIAGNOSIS%ROWTYPE INDEX BY BINARY_INTEGER;
     TYPE ntt IS TABLE OF NAN_DIAGNOSIS%ROWTYPE;
     TYPE vat IS VARRAY(100) OF NAN_DIAGNOSIS%ROWTYPE;

   -- Column Collection based on column "ID_NAN_DIAGNOSIS"
   TYPE ID_NAN_DIAGNOSIS_cc IS TABLE OF NAN_DIAGNOSIS.ID_NAN_DIAGNOSIS%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "ID_TERMINOLOGY_VERSION"
   TYPE ID_TERMINOLOGY_VERSION_cc IS TABLE OF NAN_DIAGNOSIS.ID_TERMINOLOGY_VERSION%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "DIAGNOSIS_CODE"
   TYPE DIAGNOSIS_CODE_cc IS TABLE OF NAN_DIAGNOSIS.DIAGNOSIS_CODE%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "YEAR_APPROVED"
   TYPE YEAR_APPROVED_cc IS TABLE OF NAN_DIAGNOSIS.YEAR_APPROVED%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "YEAR_REVISED"
   TYPE YEAR_REVISED_cc IS TABLE OF NAN_DIAGNOSIS.YEAR_REVISED%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "LOE"
   TYPE LOE_cc IS TABLE OF NAN_DIAGNOSIS.LOE%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "REFERENCES"
   TYPE REFERENCES_cc IS TABLE OF NAN_DIAGNOSIS.REFERENCES%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "ID_INST_OWNER"
   TYPE ID_INST_OWNER_cc IS TABLE OF NAN_DIAGNOSIS.ID_INST_OWNER%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "ID_CONCEPT_VERSION"
   TYPE ID_CONCEPT_VERSION_cc IS TABLE OF NAN_DIAGNOSIS.ID_CONCEPT_VERSION%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "ID_CONCEPT_TERM"
   TYPE ID_CONCEPT_TERM_cc IS TABLE OF NAN_DIAGNOSIS.ID_CONCEPT_TERM%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "ID_NAN_CLASS"
   TYPE ID_NAN_CLASS_cc IS TABLE OF NAN_DIAGNOSIS.ID_NAN_CLASS%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "CREATE_USER"
   TYPE CREATE_USER_cc IS TABLE OF NAN_DIAGNOSIS.CREATE_USER%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "CREATE_TIME"
   TYPE CREATE_TIME_cc IS TABLE OF NAN_DIAGNOSIS.CREATE_TIME%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "CREATE_INSTITUTION"
   TYPE CREATE_INSTITUTION_cc IS TABLE OF NAN_DIAGNOSIS.CREATE_INSTITUTION%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "UPDATE_USER"
   TYPE UPDATE_USER_cc IS TABLE OF NAN_DIAGNOSIS.UPDATE_USER%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "UPDATE_TIME"
   TYPE UPDATE_TIME_cc IS TABLE OF NAN_DIAGNOSIS.UPDATE_TIME%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "UPDATE_INSTITUTION"
   TYPE UPDATE_INSTITUTION_cc IS TABLE OF NAN_DIAGNOSIS.UPDATE_INSTITUTION%TYPE INDEX BY BINARY_INTEGER;

   TYPE varchar2_t IS TABLE OF VARCHAR2(32767) INDEX BY PLS_INTEGER;
   /*
   START Special logic for handling LOB columns....
   */
   PROCEDURE n_ins_clobs_in_chunks (
      id_nan_diagnosis_in IN NAN_DIAGNOSIS.ID_NAN_DIAGNOSIS%TYPE,
      id_terminology_version_in IN NAN_DIAGNOSIS.ID_TERMINOLOGY_VERSION%TYPE DEFAULT NULL,
      diagnosis_code_in IN NAN_DIAGNOSIS.DIAGNOSIS_CODE%TYPE DEFAULT NULL,
      year_approved_in IN NAN_DIAGNOSIS.YEAR_APPROVED%TYPE DEFAULT NULL,
      year_revised_in IN NAN_DIAGNOSIS.YEAR_REVISED%TYPE DEFAULT NULL,
      loe_in IN NAN_DIAGNOSIS.LOE%TYPE DEFAULT NULL,
      id_inst_owner_in IN NAN_DIAGNOSIS.ID_INST_OWNER%TYPE DEFAULT NULL,
      id_concept_version_in IN NAN_DIAGNOSIS.ID_CONCEPT_VERSION%TYPE DEFAULT NULL,
      id_concept_term_in IN NAN_DIAGNOSIS.ID_CONCEPT_TERM%TYPE DEFAULT NULL,
      id_nan_class_in IN NAN_DIAGNOSIS.ID_NAN_CLASS%TYPE DEFAULT NULL,
      create_user_in IN NAN_DIAGNOSIS.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN NAN_DIAGNOSIS.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN NAN_DIAGNOSIS.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN NAN_DIAGNOSIS.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN NAN_DIAGNOSIS.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN NAN_DIAGNOSIS.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      handle_error_in IN BOOLEAN := TRUE,
      clob_columns_in IN varchar2_t,
      clob_pieces_in IN  varchar2_t
   );

   PROCEDURE n_upd_clobs_in_chunks (
      id_nan_diagnosis_in IN NAN_DIAGNOSIS.ID_NAN_DIAGNOSIS%TYPE,
      id_terminology_version_in IN NAN_DIAGNOSIS.ID_TERMINOLOGY_VERSION%TYPE DEFAULT NULL,
      diagnosis_code_in IN NAN_DIAGNOSIS.DIAGNOSIS_CODE%TYPE DEFAULT NULL,
      year_approved_in IN NAN_DIAGNOSIS.YEAR_APPROVED%TYPE DEFAULT NULL,
      year_revised_in IN NAN_DIAGNOSIS.YEAR_REVISED%TYPE DEFAULT NULL,
      loe_in IN NAN_DIAGNOSIS.LOE%TYPE DEFAULT NULL,
      id_inst_owner_in IN NAN_DIAGNOSIS.ID_INST_OWNER%TYPE DEFAULT NULL,
      id_concept_version_in IN NAN_DIAGNOSIS.ID_CONCEPT_VERSION%TYPE DEFAULT NULL,
      id_concept_term_in IN NAN_DIAGNOSIS.ID_CONCEPT_TERM%TYPE DEFAULT NULL,
      id_nan_class_in IN NAN_DIAGNOSIS.ID_NAN_CLASS%TYPE DEFAULT NULL,
      create_user_in IN NAN_DIAGNOSIS.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN NAN_DIAGNOSIS.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN NAN_DIAGNOSIS.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN NAN_DIAGNOSIS.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN NAN_DIAGNOSIS.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN NAN_DIAGNOSIS.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      ignore_if_null_in IN BOOLEAN := TRUE,
      handle_error_in IN BOOLEAN := TRUE,
      clob_columns_in IN varchar2_t,
      clob_pieces_in IN  varchar2_t
      );

   PROCEDURE n_upd_ins_clobs_in_chunks (
      id_nan_diagnosis_in IN NAN_DIAGNOSIS.ID_NAN_DIAGNOSIS%TYPE,
      id_terminology_version_in IN NAN_DIAGNOSIS.ID_TERMINOLOGY_VERSION%TYPE DEFAULT NULL,
      diagnosis_code_in IN NAN_DIAGNOSIS.DIAGNOSIS_CODE%TYPE DEFAULT NULL,
      year_approved_in IN NAN_DIAGNOSIS.YEAR_APPROVED%TYPE DEFAULT NULL,
      year_revised_in IN NAN_DIAGNOSIS.YEAR_REVISED%TYPE DEFAULT NULL,
      loe_in IN NAN_DIAGNOSIS.LOE%TYPE DEFAULT NULL,
      id_inst_owner_in IN NAN_DIAGNOSIS.ID_INST_OWNER%TYPE DEFAULT NULL,
      id_concept_version_in IN NAN_DIAGNOSIS.ID_CONCEPT_VERSION%TYPE DEFAULT NULL,
      id_concept_term_in IN NAN_DIAGNOSIS.ID_CONCEPT_TERM%TYPE DEFAULT NULL,
      id_nan_class_in IN NAN_DIAGNOSIS.ID_NAN_CLASS%TYPE DEFAULT NULL,
      create_user_in IN NAN_DIAGNOSIS.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN NAN_DIAGNOSIS.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN NAN_DIAGNOSIS.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN NAN_DIAGNOSIS.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN NAN_DIAGNOSIS.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN NAN_DIAGNOSIS.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      ignore_if_null_in IN BOOLEAN DEFAULT TRUE,
      handle_error_in IN BOOLEAN DEFAULT TRUE,
      clob_columns_in IN varchar2_t,
      clob_pieces_in IN  varchar2_t
      );

   /*
   END Special logic for handling LOB columns.
   */
   -- Insert one row, providing primary key if present
   PROCEDURE ins (
      id_nan_diagnosis_in IN NAN_DIAGNOSIS.ID_NAN_DIAGNOSIS%TYPE
      ,
      id_terminology_version_in IN NAN_DIAGNOSIS.ID_TERMINOLOGY_VERSION%TYPE DEFAULT NULL,
      diagnosis_code_in IN NAN_DIAGNOSIS.DIAGNOSIS_CODE%TYPE DEFAULT NULL,
      year_approved_in IN NAN_DIAGNOSIS.YEAR_APPROVED%TYPE DEFAULT NULL,
      year_revised_in IN NAN_DIAGNOSIS.YEAR_REVISED%TYPE DEFAULT NULL,
      loe_in IN NAN_DIAGNOSIS.LOE%TYPE DEFAULT NULL,
      references_in IN NAN_DIAGNOSIS.REFERENCES%TYPE DEFAULT NULL,
      id_inst_owner_in IN NAN_DIAGNOSIS.ID_INST_OWNER%TYPE DEFAULT NULL,
      id_concept_version_in IN NAN_DIAGNOSIS.ID_CONCEPT_VERSION%TYPE DEFAULT NULL,
      id_concept_term_in IN NAN_DIAGNOSIS.ID_CONCEPT_TERM%TYPE DEFAULT NULL,
      id_nan_class_in IN NAN_DIAGNOSIS.ID_NAN_CLASS%TYPE DEFAULT NULL,
      create_user_in IN NAN_DIAGNOSIS.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN NAN_DIAGNOSIS.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN NAN_DIAGNOSIS.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN NAN_DIAGNOSIS.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN NAN_DIAGNOSIS.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN NAN_DIAGNOSIS.UPDATE_INSTITUTION%TYPE DEFAULT NULL
      -- Pass false if you want errors to propagate out unhandled
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      );

   PROCEDURE ins (
      id_nan_diagnosis_in IN NAN_DIAGNOSIS.ID_NAN_DIAGNOSIS%TYPE
      ,
      id_terminology_version_in IN NAN_DIAGNOSIS.ID_TERMINOLOGY_VERSION%TYPE DEFAULT NULL,
      diagnosis_code_in IN NAN_DIAGNOSIS.DIAGNOSIS_CODE%TYPE DEFAULT NULL,
      year_approved_in IN NAN_DIAGNOSIS.YEAR_APPROVED%TYPE DEFAULT NULL,
      year_revised_in IN NAN_DIAGNOSIS.YEAR_REVISED%TYPE DEFAULT NULL,
      loe_in IN NAN_DIAGNOSIS.LOE%TYPE DEFAULT NULL,
      references_in IN NAN_DIAGNOSIS.REFERENCES%TYPE DEFAULT NULL,
      id_inst_owner_in IN NAN_DIAGNOSIS.ID_INST_OWNER%TYPE DEFAULT NULL,
      id_concept_version_in IN NAN_DIAGNOSIS.ID_CONCEPT_VERSION%TYPE DEFAULT NULL,
      id_concept_term_in IN NAN_DIAGNOSIS.ID_CONCEPT_TERM%TYPE DEFAULT NULL,
      id_nan_class_in IN NAN_DIAGNOSIS.ID_NAN_CLASS%TYPE DEFAULT NULL,
      create_user_in IN NAN_DIAGNOSIS.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN NAN_DIAGNOSIS.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN NAN_DIAGNOSIS.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN NAN_DIAGNOSIS.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN NAN_DIAGNOSIS.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN NAN_DIAGNOSIS.UPDATE_INSTITUTION%TYPE DEFAULT NULL
      -- Pass false if you want errors to propagate out unhandled
     ,handle_error_in IN BOOLEAN := TRUE
      );


   -- Insert a row based on a record.
   -- Specify whether or not a primary key value should be generated.
   PROCEDURE ins (
      rec_in IN NAN_DIAGNOSIS%ROWTYPE
     ,gen_pky_in IN BOOLEAN DEFAULT FALSE
     ,sequence_in IN VARCHAR2 := NULL
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
   );

   PROCEDURE ins (
      rec_in IN NAN_DIAGNOSIS%ROWTYPE
     ,gen_pky_in IN BOOLEAN DEFAULT FALSE
     ,sequence_in IN VARCHAR2 := NULL
     ,handle_error_in IN BOOLEAN := TRUE
   );

   -- Insert a collection of rows using FORALL; all primary key values
   -- must have already been generated, or are handled in triggers.
   PROCEDURE ins (
      rows_in IN NAN_DIAGNOSIS_tc
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
   );

   PROCEDURE ins (
      rows_in IN NAN_DIAGNOSIS_tc
     ,handle_error_in IN BOOLEAN := TRUE
   );

   -- Return next primary key value using the named sequence.
     FUNCTION next_key (sequence_in IN VARCHAR2 := NULL) RETURN NAN_DIAGNOSIS.ID_NAN_DIAGNOSIS%TYPE;

   -- Insert one row, generating hidden primary key using a sequence
   PROCEDURE ins (
      id_terminology_version_in IN NAN_DIAGNOSIS.ID_TERMINOLOGY_VERSION%TYPE DEFAULT NULL,
      diagnosis_code_in IN NAN_DIAGNOSIS.DIAGNOSIS_CODE%TYPE DEFAULT NULL,
      year_approved_in IN NAN_DIAGNOSIS.YEAR_APPROVED%TYPE DEFAULT NULL,
      year_revised_in IN NAN_DIAGNOSIS.YEAR_REVISED%TYPE DEFAULT NULL,
      loe_in IN NAN_DIAGNOSIS.LOE%TYPE DEFAULT NULL,
      references_in IN NAN_DIAGNOSIS.REFERENCES%TYPE DEFAULT NULL,
      id_inst_owner_in IN NAN_DIAGNOSIS.ID_INST_OWNER%TYPE DEFAULT NULL,
      id_concept_version_in IN NAN_DIAGNOSIS.ID_CONCEPT_VERSION%TYPE DEFAULT NULL,
      id_concept_term_in IN NAN_DIAGNOSIS.ID_CONCEPT_TERM%TYPE DEFAULT NULL,
      id_nan_class_in IN NAN_DIAGNOSIS.ID_NAN_CLASS%TYPE DEFAULT NULL,
      create_user_in IN NAN_DIAGNOSIS.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN NAN_DIAGNOSIS.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN NAN_DIAGNOSIS.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN NAN_DIAGNOSIS.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN NAN_DIAGNOSIS.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN NAN_DIAGNOSIS.UPDATE_INSTITUTION%TYPE DEFAULT NULL
      -- Pass false if you want errors to propagate out unhandled
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      );

   PROCEDURE ins (
      id_terminology_version_in IN NAN_DIAGNOSIS.ID_TERMINOLOGY_VERSION%TYPE DEFAULT NULL,
      diagnosis_code_in IN NAN_DIAGNOSIS.DIAGNOSIS_CODE%TYPE DEFAULT NULL,
      year_approved_in IN NAN_DIAGNOSIS.YEAR_APPROVED%TYPE DEFAULT NULL,
      year_revised_in IN NAN_DIAGNOSIS.YEAR_REVISED%TYPE DEFAULT NULL,
      loe_in IN NAN_DIAGNOSIS.LOE%TYPE DEFAULT NULL,
      references_in IN NAN_DIAGNOSIS.REFERENCES%TYPE DEFAULT NULL,
      id_inst_owner_in IN NAN_DIAGNOSIS.ID_INST_OWNER%TYPE DEFAULT NULL,
      id_concept_version_in IN NAN_DIAGNOSIS.ID_CONCEPT_VERSION%TYPE DEFAULT NULL,
      id_concept_term_in IN NAN_DIAGNOSIS.ID_CONCEPT_TERM%TYPE DEFAULT NULL,
      id_nan_class_in IN NAN_DIAGNOSIS.ID_NAN_CLASS%TYPE DEFAULT NULL,
      create_user_in IN NAN_DIAGNOSIS.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN NAN_DIAGNOSIS.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN NAN_DIAGNOSIS.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN NAN_DIAGNOSIS.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN NAN_DIAGNOSIS.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN NAN_DIAGNOSIS.UPDATE_INSTITUTION%TYPE DEFAULT NULL
      -- Pass false if you want errors to propagate out unhandled
     ,handle_error_in IN BOOLEAN := TRUE
      );

   -- Insert one row, returning primary key generated by sequence
   PROCEDURE ins (
      id_terminology_version_in IN NAN_DIAGNOSIS.ID_TERMINOLOGY_VERSION%TYPE DEFAULT NULL,
      diagnosis_code_in IN NAN_DIAGNOSIS.DIAGNOSIS_CODE%TYPE DEFAULT NULL,
      year_approved_in IN NAN_DIAGNOSIS.YEAR_APPROVED%TYPE DEFAULT NULL,
      year_revised_in IN NAN_DIAGNOSIS.YEAR_REVISED%TYPE DEFAULT NULL,
      loe_in IN NAN_DIAGNOSIS.LOE%TYPE DEFAULT NULL,
      references_in IN NAN_DIAGNOSIS.REFERENCES%TYPE DEFAULT NULL,
      id_inst_owner_in IN NAN_DIAGNOSIS.ID_INST_OWNER%TYPE DEFAULT NULL,
      id_concept_version_in IN NAN_DIAGNOSIS.ID_CONCEPT_VERSION%TYPE DEFAULT NULL,
      id_concept_term_in IN NAN_DIAGNOSIS.ID_CONCEPT_TERM%TYPE DEFAULT NULL,
      id_nan_class_in IN NAN_DIAGNOSIS.ID_NAN_CLASS%TYPE DEFAULT NULL,
      create_user_in IN NAN_DIAGNOSIS.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN NAN_DIAGNOSIS.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN NAN_DIAGNOSIS.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN NAN_DIAGNOSIS.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN NAN_DIAGNOSIS.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN NAN_DIAGNOSIS.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      id_nan_diagnosis_out IN OUT NAN_DIAGNOSIS.ID_NAN_DIAGNOSIS%TYPE
      -- Pass false if you want errors to propagate out unhandled
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      );

   PROCEDURE ins (
      id_terminology_version_in IN NAN_DIAGNOSIS.ID_TERMINOLOGY_VERSION%TYPE DEFAULT NULL,
      diagnosis_code_in IN NAN_DIAGNOSIS.DIAGNOSIS_CODE%TYPE DEFAULT NULL,
      year_approved_in IN NAN_DIAGNOSIS.YEAR_APPROVED%TYPE DEFAULT NULL,
      year_revised_in IN NAN_DIAGNOSIS.YEAR_REVISED%TYPE DEFAULT NULL,
      loe_in IN NAN_DIAGNOSIS.LOE%TYPE DEFAULT NULL,
      references_in IN NAN_DIAGNOSIS.REFERENCES%TYPE DEFAULT NULL,
      id_inst_owner_in IN NAN_DIAGNOSIS.ID_INST_OWNER%TYPE DEFAULT NULL,
      id_concept_version_in IN NAN_DIAGNOSIS.ID_CONCEPT_VERSION%TYPE DEFAULT NULL,
      id_concept_term_in IN NAN_DIAGNOSIS.ID_CONCEPT_TERM%TYPE DEFAULT NULL,
      id_nan_class_in IN NAN_DIAGNOSIS.ID_NAN_CLASS%TYPE DEFAULT NULL,
      create_user_in IN NAN_DIAGNOSIS.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN NAN_DIAGNOSIS.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN NAN_DIAGNOSIS.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN NAN_DIAGNOSIS.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN NAN_DIAGNOSIS.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN NAN_DIAGNOSIS.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      id_nan_diagnosis_out IN OUT NAN_DIAGNOSIS.ID_NAN_DIAGNOSIS%TYPE
      -- Pass false if you want errors to propagate out unhandled
     ,handle_error_in IN BOOLEAN := TRUE
      );

   -- Insert one row with function, return generated primary key
   FUNCTION ins (
      id_terminology_version_in IN NAN_DIAGNOSIS.ID_TERMINOLOGY_VERSION%TYPE DEFAULT NULL,
      diagnosis_code_in IN NAN_DIAGNOSIS.DIAGNOSIS_CODE%TYPE DEFAULT NULL,
      year_approved_in IN NAN_DIAGNOSIS.YEAR_APPROVED%TYPE DEFAULT NULL,
      year_revised_in IN NAN_DIAGNOSIS.YEAR_REVISED%TYPE DEFAULT NULL,
      loe_in IN NAN_DIAGNOSIS.LOE%TYPE DEFAULT NULL,
      references_in IN NAN_DIAGNOSIS.REFERENCES%TYPE DEFAULT NULL,
      id_inst_owner_in IN NAN_DIAGNOSIS.ID_INST_OWNER%TYPE DEFAULT NULL,
      id_concept_version_in IN NAN_DIAGNOSIS.ID_CONCEPT_VERSION%TYPE DEFAULT NULL,
      id_concept_term_in IN NAN_DIAGNOSIS.ID_CONCEPT_TERM%TYPE DEFAULT NULL,
      id_nan_class_in IN NAN_DIAGNOSIS.ID_NAN_CLASS%TYPE DEFAULT NULL,
      create_user_in IN NAN_DIAGNOSIS.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN NAN_DIAGNOSIS.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN NAN_DIAGNOSIS.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN NAN_DIAGNOSIS.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN NAN_DIAGNOSIS.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN NAN_DIAGNOSIS.UPDATE_INSTITUTION%TYPE DEFAULT NULL
      -- Pass false if you want errors to propagate out unhandled
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      )
      RETURN
         NAN_DIAGNOSIS.ID_NAN_DIAGNOSIS%TYPE
      ;

   FUNCTION ins (
      id_terminology_version_in IN NAN_DIAGNOSIS.ID_TERMINOLOGY_VERSION%TYPE DEFAULT NULL,
      diagnosis_code_in IN NAN_DIAGNOSIS.DIAGNOSIS_CODE%TYPE DEFAULT NULL,
      year_approved_in IN NAN_DIAGNOSIS.YEAR_APPROVED%TYPE DEFAULT NULL,
      year_revised_in IN NAN_DIAGNOSIS.YEAR_REVISED%TYPE DEFAULT NULL,
      loe_in IN NAN_DIAGNOSIS.LOE%TYPE DEFAULT NULL,
      references_in IN NAN_DIAGNOSIS.REFERENCES%TYPE DEFAULT NULL,
      id_inst_owner_in IN NAN_DIAGNOSIS.ID_INST_OWNER%TYPE DEFAULT NULL,
      id_concept_version_in IN NAN_DIAGNOSIS.ID_CONCEPT_VERSION%TYPE DEFAULT NULL,
      id_concept_term_in IN NAN_DIAGNOSIS.ID_CONCEPT_TERM%TYPE DEFAULT NULL,
      id_nan_class_in IN NAN_DIAGNOSIS.ID_NAN_CLASS%TYPE DEFAULT NULL,
      create_user_in IN NAN_DIAGNOSIS.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN NAN_DIAGNOSIS.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN NAN_DIAGNOSIS.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN NAN_DIAGNOSIS.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN NAN_DIAGNOSIS.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN NAN_DIAGNOSIS.UPDATE_INSTITUTION%TYPE DEFAULT NULL
      -- Pass false if you want errors to propagate out unhandled
     ,handle_error_in IN BOOLEAN := TRUE
      )
      RETURN
         NAN_DIAGNOSIS.ID_NAN_DIAGNOSIS%TYPE
      ;

   -- Update any/all columns by primary key. If you pass NULL, then
   -- the current column value is set to itself. If you need a more
   -- selected UPDATE then use one of the onecol procedures below.

  PROCEDURE upd (
      id_nan_diagnosis_in IN NAN_DIAGNOSIS.ID_NAN_DIAGNOSIS%TYPE,
      id_terminology_version_in IN NAN_DIAGNOSIS.ID_TERMINOLOGY_VERSION%TYPE DEFAULT NULL,
      ID_TERMINOLOGY_VERSION_nin IN BOOLEAN := TRUE,
      diagnosis_code_in IN NAN_DIAGNOSIS.DIAGNOSIS_CODE%TYPE DEFAULT NULL,
      DIAGNOSIS_CODE_nin IN BOOLEAN := TRUE,
      year_approved_in IN NAN_DIAGNOSIS.YEAR_APPROVED%TYPE DEFAULT NULL,
      YEAR_APPROVED_nin IN BOOLEAN := TRUE,
      year_revised_in IN NAN_DIAGNOSIS.YEAR_REVISED%TYPE DEFAULT NULL,
      YEAR_REVISED_nin IN BOOLEAN := TRUE,
      loe_in IN NAN_DIAGNOSIS.LOE%TYPE DEFAULT NULL,
      LOE_nin IN BOOLEAN := TRUE,
      references_in IN NAN_DIAGNOSIS.REFERENCES%TYPE DEFAULT NULL,
      REFERENCES_nin IN BOOLEAN := TRUE,
      id_inst_owner_in IN NAN_DIAGNOSIS.ID_INST_OWNER%TYPE DEFAULT NULL,
      ID_INST_OWNER_nin IN BOOLEAN := TRUE,
      id_concept_version_in IN NAN_DIAGNOSIS.ID_CONCEPT_VERSION%TYPE DEFAULT NULL,
      ID_CONCEPT_VERSION_nin IN BOOLEAN := TRUE,
      id_concept_term_in IN NAN_DIAGNOSIS.ID_CONCEPT_TERM%TYPE DEFAULT NULL,
      ID_CONCEPT_TERM_nin IN BOOLEAN := TRUE,
      id_nan_class_in IN NAN_DIAGNOSIS.ID_NAN_CLASS%TYPE DEFAULT NULL,
      ID_NAN_CLASS_nin IN BOOLEAN := TRUE,
      create_user_in IN NAN_DIAGNOSIS.CREATE_USER%TYPE DEFAULT NULL,
      CREATE_USER_nin IN BOOLEAN := TRUE,
      create_time_in IN NAN_DIAGNOSIS.CREATE_TIME%TYPE DEFAULT NULL,
      CREATE_TIME_nin IN BOOLEAN := TRUE,
      create_institution_in IN NAN_DIAGNOSIS.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      CREATE_INSTITUTION_nin IN BOOLEAN := TRUE,
      update_user_in IN NAN_DIAGNOSIS.UPDATE_USER%TYPE DEFAULT NULL,
      UPDATE_USER_nin IN BOOLEAN := TRUE,
      update_time_in IN NAN_DIAGNOSIS.UPDATE_TIME%TYPE DEFAULT NULL,
      UPDATE_TIME_nin IN BOOLEAN := TRUE,
      update_institution_in IN NAN_DIAGNOSIS.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      UPDATE_INSTITUTION_nin IN BOOLEAN := TRUE,
     handle_error_in IN BOOLEAN := TRUE
     , rows_out IN OUT TABLE_VARCHAR
      );


       PROCEDURE upd (
      id_nan_diagnosis_in IN NAN_DIAGNOSIS.ID_NAN_DIAGNOSIS%TYPE,
      id_terminology_version_in IN NAN_DIAGNOSIS.ID_TERMINOLOGY_VERSION%TYPE DEFAULT NULL,
      ID_TERMINOLOGY_VERSION_nin IN BOOLEAN := TRUE,
      diagnosis_code_in IN NAN_DIAGNOSIS.DIAGNOSIS_CODE%TYPE DEFAULT NULL,
      DIAGNOSIS_CODE_nin IN BOOLEAN := TRUE,
      year_approved_in IN NAN_DIAGNOSIS.YEAR_APPROVED%TYPE DEFAULT NULL,
      YEAR_APPROVED_nin IN BOOLEAN := TRUE,
      year_revised_in IN NAN_DIAGNOSIS.YEAR_REVISED%TYPE DEFAULT NULL,
      YEAR_REVISED_nin IN BOOLEAN := TRUE,
      loe_in IN NAN_DIAGNOSIS.LOE%TYPE DEFAULT NULL,
      LOE_nin IN BOOLEAN := TRUE,
      references_in IN NAN_DIAGNOSIS.REFERENCES%TYPE DEFAULT NULL,
      REFERENCES_nin IN BOOLEAN := TRUE,
      id_inst_owner_in IN NAN_DIAGNOSIS.ID_INST_OWNER%TYPE DEFAULT NULL,
      ID_INST_OWNER_nin IN BOOLEAN := TRUE,
      id_concept_version_in IN NAN_DIAGNOSIS.ID_CONCEPT_VERSION%TYPE DEFAULT NULL,
      ID_CONCEPT_VERSION_nin IN BOOLEAN := TRUE,
      id_concept_term_in IN NAN_DIAGNOSIS.ID_CONCEPT_TERM%TYPE DEFAULT NULL,
      ID_CONCEPT_TERM_nin IN BOOLEAN := TRUE,
      id_nan_class_in IN NAN_DIAGNOSIS.ID_NAN_CLASS%TYPE DEFAULT NULL,
      ID_NAN_CLASS_nin IN BOOLEAN := TRUE,
      create_user_in IN NAN_DIAGNOSIS.CREATE_USER%TYPE DEFAULT NULL,
      CREATE_USER_nin IN BOOLEAN := TRUE,
      create_time_in IN NAN_DIAGNOSIS.CREATE_TIME%TYPE DEFAULT NULL,
      CREATE_TIME_nin IN BOOLEAN := TRUE,
      create_institution_in IN NAN_DIAGNOSIS.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      CREATE_INSTITUTION_nin IN BOOLEAN := TRUE,
      update_user_in IN NAN_DIAGNOSIS.UPDATE_USER%TYPE DEFAULT NULL,
      UPDATE_USER_nin IN BOOLEAN := TRUE,
      update_time_in IN NAN_DIAGNOSIS.UPDATE_TIME%TYPE DEFAULT NULL,
      UPDATE_TIME_nin IN BOOLEAN := TRUE,
      update_institution_in IN NAN_DIAGNOSIS.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      UPDATE_INSTITUTION_nin IN BOOLEAN := TRUE,
     handle_error_in IN BOOLEAN := TRUE
      );



      PROCEDURE upd (
      id_terminology_version_in IN NAN_DIAGNOSIS.ID_TERMINOLOGY_VERSION%TYPE DEFAULT NULL,
      ID_TERMINOLOGY_VERSION_nin IN BOOLEAN := TRUE,
      diagnosis_code_in IN NAN_DIAGNOSIS.DIAGNOSIS_CODE%TYPE DEFAULT NULL,
      DIAGNOSIS_CODE_nin IN BOOLEAN := TRUE,
      year_approved_in IN NAN_DIAGNOSIS.YEAR_APPROVED%TYPE DEFAULT NULL,
      YEAR_APPROVED_nin IN BOOLEAN := TRUE,
      year_revised_in IN NAN_DIAGNOSIS.YEAR_REVISED%TYPE DEFAULT NULL,
      YEAR_REVISED_nin IN BOOLEAN := TRUE,
      loe_in IN NAN_DIAGNOSIS.LOE%TYPE DEFAULT NULL,
      LOE_nin IN BOOLEAN := TRUE,
      references_in IN NAN_DIAGNOSIS.REFERENCES%TYPE DEFAULT NULL,
      REFERENCES_nin IN BOOLEAN := TRUE,
      id_inst_owner_in IN NAN_DIAGNOSIS.ID_INST_OWNER%TYPE DEFAULT NULL,
      ID_INST_OWNER_nin IN BOOLEAN := TRUE,
      id_concept_version_in IN NAN_DIAGNOSIS.ID_CONCEPT_VERSION%TYPE DEFAULT NULL,
      ID_CONCEPT_VERSION_nin IN BOOLEAN := TRUE,
      id_concept_term_in IN NAN_DIAGNOSIS.ID_CONCEPT_TERM%TYPE DEFAULT NULL,
      ID_CONCEPT_TERM_nin IN BOOLEAN := TRUE,
      id_nan_class_in IN NAN_DIAGNOSIS.ID_NAN_CLASS%TYPE DEFAULT NULL,
      ID_NAN_CLASS_nin IN BOOLEAN := TRUE,
      create_user_in IN NAN_DIAGNOSIS.CREATE_USER%TYPE DEFAULT NULL,
      CREATE_USER_nin IN BOOLEAN := TRUE,
      create_time_in IN NAN_DIAGNOSIS.CREATE_TIME%TYPE DEFAULT NULL,
      CREATE_TIME_nin IN BOOLEAN := TRUE,
      create_institution_in IN NAN_DIAGNOSIS.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      CREATE_INSTITUTION_nin IN BOOLEAN := TRUE,
      update_user_in IN NAN_DIAGNOSIS.UPDATE_USER%TYPE DEFAULT NULL,
      UPDATE_USER_nin IN BOOLEAN := TRUE,
      update_time_in IN NAN_DIAGNOSIS.UPDATE_TIME%TYPE DEFAULT NULL,
      UPDATE_TIME_nin IN BOOLEAN := TRUE,
      update_institution_in IN NAN_DIAGNOSIS.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      UPDATE_INSTITUTION_nin IN BOOLEAN := TRUE,
    where_in varchar2,
     handle_error_in IN BOOLEAN := TRUE
     , rows_out IN OUT TABLE_VARCHAR
      );


      PROCEDURE upd (
      id_terminology_version_in IN NAN_DIAGNOSIS.ID_TERMINOLOGY_VERSION%TYPE DEFAULT NULL,
      ID_TERMINOLOGY_VERSION_nin IN BOOLEAN := TRUE,
      diagnosis_code_in IN NAN_DIAGNOSIS.DIAGNOSIS_CODE%TYPE DEFAULT NULL,
      DIAGNOSIS_CODE_nin IN BOOLEAN := TRUE,
      year_approved_in IN NAN_DIAGNOSIS.YEAR_APPROVED%TYPE DEFAULT NULL,
      YEAR_APPROVED_nin IN BOOLEAN := TRUE,
      year_revised_in IN NAN_DIAGNOSIS.YEAR_REVISED%TYPE DEFAULT NULL,
      YEAR_REVISED_nin IN BOOLEAN := TRUE,
      loe_in IN NAN_DIAGNOSIS.LOE%TYPE DEFAULT NULL,
      LOE_nin IN BOOLEAN := TRUE,
      references_in IN NAN_DIAGNOSIS.REFERENCES%TYPE DEFAULT NULL,
      REFERENCES_nin IN BOOLEAN := TRUE,
      id_inst_owner_in IN NAN_DIAGNOSIS.ID_INST_OWNER%TYPE DEFAULT NULL,
      ID_INST_OWNER_nin IN BOOLEAN := TRUE,
      id_concept_version_in IN NAN_DIAGNOSIS.ID_CONCEPT_VERSION%TYPE DEFAULT NULL,
      ID_CONCEPT_VERSION_nin IN BOOLEAN := TRUE,
      id_concept_term_in IN NAN_DIAGNOSIS.ID_CONCEPT_TERM%TYPE DEFAULT NULL,
      ID_CONCEPT_TERM_nin IN BOOLEAN := TRUE,
      id_nan_class_in IN NAN_DIAGNOSIS.ID_NAN_CLASS%TYPE DEFAULT NULL,
      ID_NAN_CLASS_nin IN BOOLEAN := TRUE,
      create_user_in IN NAN_DIAGNOSIS.CREATE_USER%TYPE DEFAULT NULL,
      CREATE_USER_nin IN BOOLEAN := TRUE,
      create_time_in IN NAN_DIAGNOSIS.CREATE_TIME%TYPE DEFAULT NULL,
      CREATE_TIME_nin IN BOOLEAN := TRUE,
      create_institution_in IN NAN_DIAGNOSIS.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      CREATE_INSTITUTION_nin IN BOOLEAN := TRUE,
      update_user_in IN NAN_DIAGNOSIS.UPDATE_USER%TYPE DEFAULT NULL,
      UPDATE_USER_nin IN BOOLEAN := TRUE,
      update_time_in IN NAN_DIAGNOSIS.UPDATE_TIME%TYPE DEFAULT NULL,
      UPDATE_TIME_nin IN BOOLEAN := TRUE,
      update_institution_in IN NAN_DIAGNOSIS.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      UPDATE_INSTITUTION_nin IN BOOLEAN := TRUE,
    where_in varchar2,
     handle_error_in IN BOOLEAN := TRUE
      );



   PROCEDURE upd_ins (
      id_nan_diagnosis_in IN NAN_DIAGNOSIS.ID_NAN_DIAGNOSIS%TYPE,
      id_terminology_version_in IN NAN_DIAGNOSIS.ID_TERMINOLOGY_VERSION%TYPE DEFAULT NULL,
      diagnosis_code_in IN NAN_DIAGNOSIS.DIAGNOSIS_CODE%TYPE DEFAULT NULL,
      year_approved_in IN NAN_DIAGNOSIS.YEAR_APPROVED%TYPE DEFAULT NULL,
      year_revised_in IN NAN_DIAGNOSIS.YEAR_REVISED%TYPE DEFAULT NULL,
      loe_in IN NAN_DIAGNOSIS.LOE%TYPE DEFAULT NULL,
      references_in IN NAN_DIAGNOSIS.REFERENCES%TYPE DEFAULT NULL,
      id_inst_owner_in IN NAN_DIAGNOSIS.ID_INST_OWNER%TYPE DEFAULT NULL,
      id_concept_version_in IN NAN_DIAGNOSIS.ID_CONCEPT_VERSION%TYPE DEFAULT NULL,
      id_concept_term_in IN NAN_DIAGNOSIS.ID_CONCEPT_TERM%TYPE DEFAULT NULL,
      id_nan_class_in IN NAN_DIAGNOSIS.ID_NAN_CLASS%TYPE DEFAULT NULL,
      create_user_in IN NAN_DIAGNOSIS.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN NAN_DIAGNOSIS.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN NAN_DIAGNOSIS.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN NAN_DIAGNOSIS.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN NAN_DIAGNOSIS.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN NAN_DIAGNOSIS.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
     handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      );

      PROCEDURE upd_ins (
      id_nan_diagnosis_in IN NAN_DIAGNOSIS.ID_NAN_DIAGNOSIS%TYPE,
      id_terminology_version_in IN NAN_DIAGNOSIS.ID_TERMINOLOGY_VERSION%TYPE DEFAULT NULL,
      diagnosis_code_in IN NAN_DIAGNOSIS.DIAGNOSIS_CODE%TYPE DEFAULT NULL,
      year_approved_in IN NAN_DIAGNOSIS.YEAR_APPROVED%TYPE DEFAULT NULL,
      year_revised_in IN NAN_DIAGNOSIS.YEAR_REVISED%TYPE DEFAULT NULL,
      loe_in IN NAN_DIAGNOSIS.LOE%TYPE DEFAULT NULL,
      references_in IN NAN_DIAGNOSIS.REFERENCES%TYPE DEFAULT NULL,
      id_inst_owner_in IN NAN_DIAGNOSIS.ID_INST_OWNER%TYPE DEFAULT NULL,
      id_concept_version_in IN NAN_DIAGNOSIS.ID_CONCEPT_VERSION%TYPE DEFAULT NULL,
      id_concept_term_in IN NAN_DIAGNOSIS.ID_CONCEPT_TERM%TYPE DEFAULT NULL,
      id_nan_class_in IN NAN_DIAGNOSIS.ID_NAN_CLASS%TYPE DEFAULT NULL,
      create_user_in IN NAN_DIAGNOSIS.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN NAN_DIAGNOSIS.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN NAN_DIAGNOSIS.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN NAN_DIAGNOSIS.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN NAN_DIAGNOSIS.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN NAN_DIAGNOSIS.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
     handle_error_in IN BOOLEAN := TRUE
      );

   PROCEDURE upd (
      rec_in IN NAN_DIAGNOSIS%ROWTYPE,
     handle_error_in IN BOOLEAN := TRUE
     , rows_out IN OUT TABLE_VARCHAR
      );

      PROCEDURE upd (
      rec_in IN NAN_DIAGNOSIS%ROWTYPE,
     handle_error_in IN BOOLEAN := TRUE
      );

      PROCEDURE upd (
      col_in IN NAN_DIAGNOSIS_tc,
      ignore_if_null_in IN BOOLEAN := TRUE
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out IN OUT TABLE_VARCHAR
      );

      PROCEDURE upd (
      col_in IN NAN_DIAGNOSIS_tc,
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
      id_nan_diagnosis_in IN NAN_DIAGNOSIS.ID_NAN_DIAGNOSIS%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
      );

-- Delete one row by primary key
   PROCEDURE del (
      id_nan_diagnosis_in IN NAN_DIAGNOSIS.ID_NAN_DIAGNOSIS%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      );


   -- Delete all rows for primary key column ID_NAN_DIAGNOSIS
   PROCEDURE del_ID_NAN_DIAGNOSIS (
      id_nan_diagnosis_in IN NAN_DIAGNOSIS.ID_NAN_DIAGNOSIS%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
     );

     -- Delete all rows for primary key column ID_NAN_DIAGNOSIS
   PROCEDURE del_ID_NAN_DIAGNOSIS (
      id_nan_diagnosis_in IN NAN_DIAGNOSIS.ID_NAN_DIAGNOSIS%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
     );

   -- Delete for unique value of NAN_DIAGNOSIS_UK
   PROCEDURE del_NAN_DIAGNOSIS_UK (
      id_terminology_version_in IN NAN_DIAGNOSIS.ID_TERMINOLOGY_VERSION%TYPE,
      diagnosis_code_in IN NAN_DIAGNOSIS.DIAGNOSIS_CODE%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
      );

   -- Delete for unique value of NAN_DIAGNOSIS_UK
   PROCEDURE del_NAN_DIAGNOSIS_UK (
      id_terminology_version_in IN NAN_DIAGNOSIS.ID_TERMINOLOGY_VERSION%TYPE,
      diagnosis_code_in IN NAN_DIAGNOSIS.DIAGNOSIS_CODE%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      );

   -- Delete all rows for this NANDX_CNCPTTR_FK foreign key value
   PROCEDURE del_NANDX_CNCPTTR_FK (
      id_concept_term_in IN NAN_DIAGNOSIS.ID_CONCEPT_TERM%TYPE,
      id_inst_owner_in IN NAN_DIAGNOSIS.ID_INST_OWNER%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
      );

      -- Delete all rows for this NANDX_CNCPTTR_FK foreign key value
   PROCEDURE del_NANDX_CNCPTTR_FK (
      id_concept_term_in IN NAN_DIAGNOSIS.ID_CONCEPT_TERM%TYPE,
      id_inst_owner_in IN NAN_DIAGNOSIS.ID_INST_OWNER%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      );

   -- Delete all rows for this NANDX_CNCPTV_FK foreign key value
   PROCEDURE del_NANDX_CNCPTV_FK (
      id_concept_version_in IN NAN_DIAGNOSIS.ID_CONCEPT_VERSION%TYPE,
      id_inst_owner_in IN NAN_DIAGNOSIS.ID_INST_OWNER%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
      );

      -- Delete all rows for this NANDX_CNCPTV_FK foreign key value
   PROCEDURE del_NANDX_CNCPTV_FK (
      id_concept_version_in IN NAN_DIAGNOSIS.ID_CONCEPT_VERSION%TYPE,
      id_inst_owner_in IN NAN_DIAGNOSIS.ID_INST_OWNER%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      );

   -- Delete all rows for this NANDX_NANC_FK foreign key value
   PROCEDURE del_NANDX_NANC_FK (
      id_nan_class_in IN NAN_DIAGNOSIS.ID_NAN_CLASS%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
      );

      -- Delete all rows for this NANDX_NANC_FK foreign key value
   PROCEDURE del_NANDX_NANC_FK (
      id_nan_class_in IN NAN_DIAGNOSIS.ID_NAN_CLASS%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      );

   -- Delete all rows for this NANDX_NAN_FK foreign key value
   PROCEDURE del_NANDX_NAN_FK (
      diagnosis_code_in IN NAN_DIAGNOSIS.DIAGNOSIS_CODE%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
      );

      -- Delete all rows for this NANDX_NAN_FK foreign key value
   PROCEDURE del_NANDX_NAN_FK (
      diagnosis_code_in IN NAN_DIAGNOSIS.DIAGNOSIS_CODE%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      );

   -- Delete all rows for this NANDX_TERMV_FK foreign key value
   PROCEDURE del_NANDX_TERMV_FK (
      id_terminology_version_in IN NAN_DIAGNOSIS.ID_TERMINOLOGY_VERSION%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
      );

      -- Delete all rows for this NANDX_TERMV_FK foreign key value
   PROCEDURE del_NANDX_TERMV_FK (
      id_terminology_version_in IN NAN_DIAGNOSIS.ID_TERMINOLOGY_VERSION%TYPE
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
      nan_diagnosis_inout IN OUT NAN_DIAGNOSIS%ROWTYPE
   );

   FUNCTION initrec RETURN NAN_DIAGNOSIS%ROWTYPE;



   FUNCTION get_data_rowid(
        rows_in IN TABLE_VARCHAR
        ) RETURN NAN_DIAGNOSIS_tc;


   FUNCTION get_data_rowid_pat(
        rows_in IN TABLE_VARCHAR
        ) RETURN NAN_DIAGNOSIS_tc;

END TS_NAN_DIAGNOSIS;
/
