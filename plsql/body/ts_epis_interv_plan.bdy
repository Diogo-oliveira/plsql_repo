/*-- Last Change Revision: $Rev: 2028107 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:44:12 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY ts_epis_interv_plan IS


	/* CAN'T TOUCH THIS */
    g_error   VARCHAR2(1000 CHAR);
    g_owner   VARCHAR2(30 CHAR);
    g_package VARCHAR2(30 CHAR);

   e_null_column_value EXCEPTION;
   PRAGMA EXCEPTION_INIT (e_null_column_value, -1400);
   --
   e_existing_fky_reference EXCEPTION;
   PRAGMA EXCEPTION_INIT (e_existing_fky_reference, -2266);
   --
   e_check_constraint_failure EXCEPTION;
   PRAGMA EXCEPTION_INIT (e_check_constraint_failure, -2290);
   --
   e_no_parent_key EXCEPTION;
   PRAGMA EXCEPTION_INIT (e_no_parent_key, -2291);
   --
   e_child_record_found EXCEPTION;
   PRAGMA EXCEPTION_INIT (e_child_record_found, -2292);
   --
   e_forall_error EXCEPTION;
   PRAGMA EXCEPTION_INIT (e_forall_error, -24381);
   --
   -- Defined for backward compatibilty.
   e_integ_constraint_failure EXCEPTION;
   PRAGMA EXCEPTION_INIT (e_integ_constraint_failure, -2291);

    -- Private utilities
   PROCEDURE get_constraint_info (
      owner_out OUT ALL_CONSTRAINTS.OWNER%TYPE
     ,name_out OUT ALL_CONSTRAINTS.CONSTRAINT_NAME%TYPE)
   IS
      l_errm VARCHAR2(2000) := DBMS_UTILITY.FORMAT_ERROR_STACK;
      dotloc PLS_INTEGER;
      leftloc PLS_INTEGER;
   BEGIN
      dotloc  := INSTR (l_errm,'.');
      leftloc := INSTR (l_errm,'(');
      owner_out := SUBSTR (l_errm, leftloc+1, dotloc-leftloc-1);
      name_out  := SUBSTR (l_errm, dotloc+1, INSTR (l_errm,')')-dotloc-1);
   END get_constraint_info;
   -- Public programs

   PROCEDURE ins (
      id_epis_interv_plan_in IN EPIS_INTERV_PLAN.ID_EPIS_INTERV_PLAN%TYPE
      ,
      id_interv_plan_in IN EPIS_INTERV_PLAN.ID_INTERV_PLAN%TYPE DEFAULT NULL,
      id_episode_in IN EPIS_INTERV_PLAN.ID_EPISODE%TYPE DEFAULT NULL,
      id_professional_in IN EPIS_INTERV_PLAN.ID_PROFESSIONAL%TYPE DEFAULT NULL,
      flg_status_in IN EPIS_INTERV_PLAN.FLG_STATUS%TYPE DEFAULT NULL,
      notes_in IN EPIS_INTERV_PLAN.NOTES%TYPE DEFAULT NULL,
      dt_creation_in IN EPIS_INTERV_PLAN.DT_CREATION%TYPE DEFAULT NULL,
      dt_begin_in IN EPIS_INTERV_PLAN.DT_BEGIN%TYPE DEFAULT NULL,
      dt_end_in IN EPIS_INTERV_PLAN.DT_END%TYPE DEFAULT NULL,
      id_cancel_info_det_in IN EPIS_INTERV_PLAN.ID_CANCEL_INFO_DET%TYPE DEFAULT NULL,
      flg_available_in IN EPIS_INTERV_PLAN.FLG_AVAILABLE%TYPE DEFAULT 'Y',
      desc_other_interv_plan_in IN EPIS_INTERV_PLAN.DESC_OTHER_INTERV_PLAN%TYPE DEFAULT NULL,
      create_user_in IN EPIS_INTERV_PLAN.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN EPIS_INTERV_PLAN.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN EPIS_INTERV_PLAN.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN EPIS_INTERV_PLAN.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN EPIS_INTERV_PLAN.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN EPIS_INTERV_PLAN.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      id_task_goal_det_in IN EPIS_INTERV_PLAN.ID_TASK_GOAL_DET%TYPE DEFAULT NULL
     ,handle_error_in IN BOOLEAN := TRUE
      , rows_out OUT TABLE_VARCHAR
      )
   IS
   BEGIN

     INSERT INTO EPIS_INTERV_PLAN (
         ID_EPIS_INTERV_PLAN,
         ID_INTERV_PLAN,
         ID_EPISODE,
         ID_PROFESSIONAL,
         FLG_STATUS,
         NOTES,
         DT_CREATION,
         DT_BEGIN,
         DT_END,
         ID_CANCEL_INFO_DET,
         FLG_AVAILABLE,
         DESC_OTHER_INTERV_PLAN,
         CREATE_USER,
         CREATE_TIME,
         CREATE_INSTITUTION,
         UPDATE_USER,
         UPDATE_TIME,
         UPDATE_INSTITUTION,
         ID_TASK_GOAL_DET
         )
      VALUES (
         id_epis_interv_plan_in,
         id_interv_plan_in,
         id_episode_in,
         id_professional_in,
         flg_status_in,
         notes_in,
         dt_creation_in,
         dt_begin_in,
         dt_end_in,
         id_cancel_info_det_in,
         flg_available_in,
         desc_other_interv_plan_in,
         create_user_in,
         create_time_in,
         create_institution_in,
         update_user_in,
         update_time_in,
         update_institution_in,
         id_task_goal_det_in
         ) RETURNING ROWID BULK COLLECT INTO rows_out;
   EXCEPTION
      WHEN DUP_VAL_ON_INDEX
      THEN
        IF NOT handle_error_in THEN RAISE;
        ELSE
        DECLARE
           l_owner ALL_CONSTRAINTS.OWNER%TYPE;
           l_name ALL_CONSTRAINTS.CONSTRAINT_NAME%TYPE;
           l_err_instance_id PLS_INTEGER;
        BEGIN
           get_constraint_info (l_owner, l_name);
           IF FALSE THEN NULL; -- Placeholder in case no unique indexes
           ELSE
              pk_alert_exceptions.raise_error (
                    error_name_in => 'DUPLICATE-VALUE'
                    ,name1_in => 'OWNER'
                    ,value1_in => l_owner
                    ,name2_in => 'CONSTRAINT_NAME'
                    ,value2_in => l_name
                    ,name3_in => 'TABLE_NAME'
                    ,value3_in => 'EPIS_INTERV_PLAN');
           END IF;
        END;
        END IF;
      WHEN e_check_constraint_failure
      THEN
        IF NOT handle_error_in THEN RAISE;
        ELSE
        DECLARE
           l_owner ALL_CONSTRAINTS.OWNER%TYPE;
           l_name ALL_CONSTRAINTS.CONSTRAINT_NAME%TYPE;
        BEGIN
           get_constraint_info (l_owner, l_name);
           pk_alert_exceptions.raise_error (
              error_name_in => 'CHECK-CONSTRAINT-FAILURE'
             ,name1_in => 'OWNER'
             ,value1_in => l_owner
             ,name2_in => 'CONSTRAINT_NAME'
             ,value2_in => l_name
             ,name3_in => 'TABLE_NAME'
             ,value3_in => 'EPIS_INTERV_PLAN');
        END;
        END IF;
      WHEN e_integ_constraint_failure OR e_no_parent_key OR e_child_record_found
      THEN
        IF NOT handle_error_in THEN RAISE;
        ELSE
        DECLARE
           l_owner ALL_CONSTRAINTS.OWNER%TYPE;
           l_name ALL_CONSTRAINTS.CONSTRAINT_NAME%TYPE;
           l_id PLS_INTEGER;
           l_err_name VARCHAR2(32767) DEFAULT 'NO-PARENT-KEY-FOUND';
        BEGIN
           get_constraint_info (l_owner, l_name);
           IF SQLCODE = -2292 -- Child record found
           THEN
              l_err_name := 'CHILD-RECORD-FOUND' ;
           END IF;
           pk_alert_exceptions.register_error (
              error_name_in => l_err_name
             ,err_instance_id_out => l_id
             ,name1_in => 'OWNER', value1_in => l_owner
             ,name2_in => 'CONSTRAINT_NAME', value2_in => l_name
             ,name3_in => 'TABLE_NAME', value3_in => 'EPIS_INTERV_PLAN');
           IF l_name = 'EIP_P_FK'
           THEN
              -- Add a context value for each column
              pk_alert_exceptions.add_context (
                 err_instance_id_in => l_id
               , name_in => 'ID_PROFESSIONAL'
               , value_in => id_professional_in);
           END IF;
           IF l_name = 'EIP_TSKGD_FK'
           THEN
              -- Add a context value for each column
              pk_alert_exceptions.add_context (
                 err_instance_id_in => l_id
               , name_in => 'ID_TASK_GOAL_DET'
               , value_in => id_task_goal_det_in);
           END IF;
           pk_alert_exceptions.raise_error_instance (err_instance_id_in => l_id);
        END;
        END IF;
      WHEN e_null_column_value
      THEN
        IF NOT handle_error_in THEN RAISE;
        ELSE
        DECLARE
           v_errm VARCHAR2(2000) := DBMS_UTILITY.FORMAT_ERROR_STACK;
           dot1loc INTEGER;
           dot2loc INTEGER;
           parenloc INTEGER;
           c_owner ALL_CONSTRAINTS.OWNER%TYPE;
           c_tabname ALL_TABLES.TABLE_NAME%TYPE;
           c_colname ALL_TAB_COLUMNS.COLUMN_NAME%TYPE;
        BEGIN
           dot1loc := INSTR (v_errm, '.', 1, 1);
           dot2loc := INSTR (v_errm, '.', 1, 2);
           parenloc := INSTR (v_errm, '(');
           c_owner :=SUBSTR (v_errm, parenloc+1, dot1loc-parenloc-1);
           c_tabname := SUBSTR (v_errm, dot1loc+1, dot2loc-dot1loc-1);
           c_colname := SUBSTR (v_errm, dot2loc+1, INSTR (v_errm,')')-dot2loc-1);

           pk_alert_exceptions.raise_error (
                error_name_in => 'COLUMN-CANNOT-BE-NULL'
               ,name1_in => 'OWNER'
               ,value1_in => c_owner
               ,name2_in => 'TABLE_NAME'
               ,value2_in => c_tabname
               ,name3_in => 'COLUMN_NAME'
               ,value3_in => c_colname);
        END;
        END IF;
   END ins;

   PROCEDURE ins (
      id_epis_interv_plan_in IN EPIS_INTERV_PLAN.ID_EPIS_INTERV_PLAN%TYPE
      ,
      id_interv_plan_in IN EPIS_INTERV_PLAN.ID_INTERV_PLAN%TYPE DEFAULT NULL,
      id_episode_in IN EPIS_INTERV_PLAN.ID_EPISODE%TYPE DEFAULT NULL,
      id_professional_in IN EPIS_INTERV_PLAN.ID_PROFESSIONAL%TYPE DEFAULT NULL,
      flg_status_in IN EPIS_INTERV_PLAN.FLG_STATUS%TYPE DEFAULT NULL,
      notes_in IN EPIS_INTERV_PLAN.NOTES%TYPE DEFAULT NULL,
      dt_creation_in IN EPIS_INTERV_PLAN.DT_CREATION%TYPE DEFAULT NULL,
      dt_begin_in IN EPIS_INTERV_PLAN.DT_BEGIN%TYPE DEFAULT NULL,
      dt_end_in IN EPIS_INTERV_PLAN.DT_END%TYPE DEFAULT NULL,
      id_cancel_info_det_in IN EPIS_INTERV_PLAN.ID_CANCEL_INFO_DET%TYPE DEFAULT NULL,
      flg_available_in IN EPIS_INTERV_PLAN.FLG_AVAILABLE%TYPE DEFAULT 'Y',
      desc_other_interv_plan_in IN EPIS_INTERV_PLAN.DESC_OTHER_INTERV_PLAN%TYPE DEFAULT NULL,
      create_user_in IN EPIS_INTERV_PLAN.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN EPIS_INTERV_PLAN.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN EPIS_INTERV_PLAN.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN EPIS_INTERV_PLAN.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN EPIS_INTERV_PLAN.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN EPIS_INTERV_PLAN.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      id_task_goal_det_in IN EPIS_INTERV_PLAN.ID_TASK_GOAL_DET%TYPE DEFAULT NULL
     ,handle_error_in IN BOOLEAN := TRUE
      )
   IS
   rows_out TABLE_VARCHAR;
   BEGIN

     ins (
      id_epis_interv_plan_in => id_epis_interv_plan_in
      ,
      id_interv_plan_in => id_interv_plan_in,
      id_episode_in => id_episode_in,
      id_professional_in => id_professional_in,
      flg_status_in => flg_status_in,
      notes_in => notes_in,
      dt_creation_in => dt_creation_in,
      dt_begin_in => dt_begin_in,
      dt_end_in => dt_end_in,
      id_cancel_info_det_in => id_cancel_info_det_in,
      flg_available_in => flg_available_in,
      desc_other_interv_plan_in => desc_other_interv_plan_in,
      create_user_in => create_user_in,
      create_time_in => create_time_in,
      create_institution_in => create_institution_in,
      update_user_in => update_user_in,
      update_time_in => update_time_in,
      update_institution_in => update_institution_in,
      id_task_goal_det_in => id_task_goal_det_in
     ,handle_error_in => handle_error_in
      ,rows_out => rows_out
      );
   END ins;


   PROCEDURE ins (
      rec_in IN EPIS_INTERV_PLAN%ROWTYPE
     ,gen_pky_in IN BOOLEAN DEFAULT FALSE
     ,sequence_in IN VARCHAR2 := NULL
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
   )
   IS
      l_rec EPIS_INTERV_PLAN%ROWTYPE := rec_in;
   BEGIN
      IF gen_pky_in THEN
         l_rec.ID_EPIS_INTERV_PLAN := next_key (sequence_in);
      END IF;
      ins (
         id_epis_interv_plan_in => l_rec.ID_EPIS_INTERV_PLAN
         ,
         id_interv_plan_in => l_rec.ID_INTERV_PLAN,
         id_episode_in => l_rec.ID_EPISODE,
         id_professional_in => l_rec.ID_PROFESSIONAL,
         flg_status_in => l_rec.FLG_STATUS,
         notes_in => l_rec.NOTES,
         dt_creation_in => l_rec.DT_CREATION,
         dt_begin_in => l_rec.DT_BEGIN,
         dt_end_in => l_rec.DT_END,
         id_cancel_info_det_in => l_rec.ID_CANCEL_INFO_DET,
         flg_available_in => l_rec.FLG_AVAILABLE,
         desc_other_interv_plan_in => l_rec.DESC_OTHER_INTERV_PLAN,
         create_user_in => l_rec.CREATE_USER,
         create_time_in => l_rec.CREATE_TIME,
         create_institution_in => l_rec.CREATE_INSTITUTION,
         update_user_in => l_rec.UPDATE_USER,
         update_time_in => l_rec.UPDATE_TIME,
         update_institution_in => l_rec.UPDATE_INSTITUTION,
         id_task_goal_det_in => l_rec.ID_TASK_GOAL_DET
         ,handle_error_in => handle_error_in
         , rows_out => rows_out
         );
   END ins;

   PROCEDURE ins (
      rec_in IN EPIS_INTERV_PLAN%ROWTYPE
     ,gen_pky_in IN BOOLEAN DEFAULT FALSE
     ,sequence_in IN VARCHAR2 := NULL
     ,handle_error_in IN BOOLEAN := TRUE
   )
   IS
      rows_out TABLE_VARCHAR;
   BEGIN

  ins (
      rec_in => rec_in
     ,gen_pky_in => gen_pky_in
     ,sequence_in => sequence_in
     ,handle_error_in => handle_error_in
     , rows_out => rows_out
   );

   END ins;

   FUNCTION next_key (sequence_in IN VARCHAR2 := NULL) RETURN EPIS_INTERV_PLAN.ID_EPIS_INTERV_PLAN%TYPE

   IS
     retval EPIS_INTERV_PLAN.ID_EPIS_INTERV_PLAN%TYPE;

   BEGIN
      IF sequence_in IS NULL
      THEN
         SELECT seq_EPIS_INTERV_PLAN.NEXTVAL INTO retval FROM dual;
      ELSE
         EXECUTE IMMEDIATE
            'SELECT ' || sequence_in || '.NEXTVAL FROM dual'
            INTO retval;
      END IF;
      RETURN retval;
   EXCEPTION
      WHEN OTHERS THEN
        pk_alert_exceptions.raise_error (
           error_name_in => 'SEQUENCE-GENERATION-FAILURE'
           ,name1_in => 'SEQUENCE'
           ,value1_in => NVL (sequence_in, 'seq_EPIS_INTERV_PLAN')
           );
   END next_key;

   PROCEDURE ins (
      id_interv_plan_in IN EPIS_INTERV_PLAN.ID_INTERV_PLAN%TYPE DEFAULT NULL,
      id_episode_in IN EPIS_INTERV_PLAN.ID_EPISODE%TYPE DEFAULT NULL,
      id_professional_in IN EPIS_INTERV_PLAN.ID_PROFESSIONAL%TYPE DEFAULT NULL,
      flg_status_in IN EPIS_INTERV_PLAN.FLG_STATUS%TYPE DEFAULT NULL,
      notes_in IN EPIS_INTERV_PLAN.NOTES%TYPE DEFAULT NULL,
      dt_creation_in IN EPIS_INTERV_PLAN.DT_CREATION%TYPE DEFAULT NULL,
      dt_begin_in IN EPIS_INTERV_PLAN.DT_BEGIN%TYPE DEFAULT NULL,
      dt_end_in IN EPIS_INTERV_PLAN.DT_END%TYPE DEFAULT NULL,
      id_cancel_info_det_in IN EPIS_INTERV_PLAN.ID_CANCEL_INFO_DET%TYPE DEFAULT NULL,
      flg_available_in IN EPIS_INTERV_PLAN.FLG_AVAILABLE%TYPE DEFAULT 'Y',
      desc_other_interv_plan_in IN EPIS_INTERV_PLAN.DESC_OTHER_INTERV_PLAN%TYPE DEFAULT NULL,
      create_user_in IN EPIS_INTERV_PLAN.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN EPIS_INTERV_PLAN.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN EPIS_INTERV_PLAN.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN EPIS_INTERV_PLAN.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN EPIS_INTERV_PLAN.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN EPIS_INTERV_PLAN.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      id_task_goal_det_in IN EPIS_INTERV_PLAN.ID_TASK_GOAL_DET%TYPE DEFAULT NULL,
      id_epis_interv_plan_out IN OUT EPIS_INTERV_PLAN.ID_EPIS_INTERV_PLAN%TYPE
      ,handle_error_in IN BOOLEAN := TRUE
      , rows_out OUT TABLE_VARCHAR
   )
   IS
        l_pky EPIS_INTERV_PLAN.ID_EPIS_INTERV_PLAN%TYPE := next_key;
   BEGIN
      ins (
         id_epis_interv_plan_in => l_pky,
         id_interv_plan_in => id_interv_plan_in,
         id_episode_in => id_episode_in,
         id_professional_in => id_professional_in,
         flg_status_in => flg_status_in,
         notes_in => notes_in,
         dt_creation_in => dt_creation_in,
         dt_begin_in => dt_begin_in,
         dt_end_in => dt_end_in,
         id_cancel_info_det_in => id_cancel_info_det_in,
         flg_available_in => flg_available_in,
         desc_other_interv_plan_in => desc_other_interv_plan_in,
         create_user_in => create_user_in,
         create_time_in => create_time_in,
         create_institution_in => create_institution_in,
         update_user_in => update_user_in,
         update_time_in => update_time_in,
         update_institution_in => update_institution_in,
         id_task_goal_det_in => id_task_goal_det_in
         ,handle_error_in => handle_error_in
         , rows_out => rows_out
         );
      id_epis_interv_plan_out := l_pky;
   END ins;

   PROCEDURE ins (
      id_interv_plan_in IN EPIS_INTERV_PLAN.ID_INTERV_PLAN%TYPE DEFAULT NULL,
      id_episode_in IN EPIS_INTERV_PLAN.ID_EPISODE%TYPE DEFAULT NULL,
      id_professional_in IN EPIS_INTERV_PLAN.ID_PROFESSIONAL%TYPE DEFAULT NULL,
      flg_status_in IN EPIS_INTERV_PLAN.FLG_STATUS%TYPE DEFAULT NULL,
      notes_in IN EPIS_INTERV_PLAN.NOTES%TYPE DEFAULT NULL,
      dt_creation_in IN EPIS_INTERV_PLAN.DT_CREATION%TYPE DEFAULT NULL,
      dt_begin_in IN EPIS_INTERV_PLAN.DT_BEGIN%TYPE DEFAULT NULL,
      dt_end_in IN EPIS_INTERV_PLAN.DT_END%TYPE DEFAULT NULL,
      id_cancel_info_det_in IN EPIS_INTERV_PLAN.ID_CANCEL_INFO_DET%TYPE DEFAULT NULL,
      flg_available_in IN EPIS_INTERV_PLAN.FLG_AVAILABLE%TYPE DEFAULT 'Y',
      desc_other_interv_plan_in IN EPIS_INTERV_PLAN.DESC_OTHER_INTERV_PLAN%TYPE DEFAULT NULL,
      create_user_in IN EPIS_INTERV_PLAN.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN EPIS_INTERV_PLAN.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN EPIS_INTERV_PLAN.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN EPIS_INTERV_PLAN.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN EPIS_INTERV_PLAN.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN EPIS_INTERV_PLAN.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      id_task_goal_det_in IN EPIS_INTERV_PLAN.ID_TASK_GOAL_DET%TYPE DEFAULT NULL,
      id_epis_interv_plan_out IN OUT EPIS_INTERV_PLAN.ID_EPIS_INTERV_PLAN%TYPE
      ,handle_error_in IN BOOLEAN := TRUE
   )
   IS
        rows_out TABLE_VARCHAR;
   BEGIN
      ins (
      id_interv_plan_in => id_interv_plan_in,
      id_episode_in => id_episode_in,
      id_professional_in => id_professional_in,
      flg_status_in => flg_status_in,
      notes_in => notes_in,
      dt_creation_in => dt_creation_in,
      dt_begin_in => dt_begin_in,
      dt_end_in => dt_end_in,
      id_cancel_info_det_in => id_cancel_info_det_in,
      flg_available_in => flg_available_in,
      desc_other_interv_plan_in => desc_other_interv_plan_in,
      create_user_in => create_user_in,
      create_time_in => create_time_in,
      create_institution_in => create_institution_in,
      update_user_in => update_user_in,
      update_time_in => update_time_in,
      update_institution_in => update_institution_in,
      id_task_goal_det_in => id_task_goal_det_in,
      id_epis_interv_plan_out => id_epis_interv_plan_out
      ,handle_error_in => handle_error_in
      , rows_out => rows_out
   );
   END ins;

   FUNCTION ins (
      id_interv_plan_in IN EPIS_INTERV_PLAN.ID_INTERV_PLAN%TYPE DEFAULT NULL,
      id_episode_in IN EPIS_INTERV_PLAN.ID_EPISODE%TYPE DEFAULT NULL,
      id_professional_in IN EPIS_INTERV_PLAN.ID_PROFESSIONAL%TYPE DEFAULT NULL,
      flg_status_in IN EPIS_INTERV_PLAN.FLG_STATUS%TYPE DEFAULT NULL,
      notes_in IN EPIS_INTERV_PLAN.NOTES%TYPE DEFAULT NULL,
      dt_creation_in IN EPIS_INTERV_PLAN.DT_CREATION%TYPE DEFAULT NULL,
      dt_begin_in IN EPIS_INTERV_PLAN.DT_BEGIN%TYPE DEFAULT NULL,
      dt_end_in IN EPIS_INTERV_PLAN.DT_END%TYPE DEFAULT NULL,
      id_cancel_info_det_in IN EPIS_INTERV_PLAN.ID_CANCEL_INFO_DET%TYPE DEFAULT NULL,
      flg_available_in IN EPIS_INTERV_PLAN.FLG_AVAILABLE%TYPE DEFAULT 'Y',
      desc_other_interv_plan_in IN EPIS_INTERV_PLAN.DESC_OTHER_INTERV_PLAN%TYPE DEFAULT NULL,
      create_user_in IN EPIS_INTERV_PLAN.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN EPIS_INTERV_PLAN.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN EPIS_INTERV_PLAN.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN EPIS_INTERV_PLAN.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN EPIS_INTERV_PLAN.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN EPIS_INTERV_PLAN.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      id_task_goal_det_in IN EPIS_INTERV_PLAN.ID_TASK_GOAL_DET%TYPE DEFAULT NULL
      ,handle_error_in IN BOOLEAN := TRUE
      , rows_out OUT TABLE_VARCHAR
   )
      RETURN
         EPIS_INTERV_PLAN.ID_EPIS_INTERV_PLAN%TYPE
   IS
        l_pky EPIS_INTERV_PLAN.ID_EPIS_INTERV_PLAN%TYPE := next_key;
   BEGIN
      ins (
         id_epis_interv_plan_in => l_pky,
         id_interv_plan_in => id_interv_plan_in,
         id_episode_in => id_episode_in,
         id_professional_in => id_professional_in,
         flg_status_in => flg_status_in,
         notes_in => notes_in,
         dt_creation_in => dt_creation_in,
         dt_begin_in => dt_begin_in,
         dt_end_in => dt_end_in,
         id_cancel_info_det_in => id_cancel_info_det_in,
         flg_available_in => flg_available_in,
         desc_other_interv_plan_in => desc_other_interv_plan_in,
         create_user_in => create_user_in,
         create_time_in => create_time_in,
         create_institution_in => create_institution_in,
         update_user_in => update_user_in,
         update_time_in => update_time_in,
         update_institution_in => update_institution_in,
         id_task_goal_det_in => id_task_goal_det_in
         ,handle_error_in => handle_error_in
         , rows_out => rows_out
         );
      RETURN l_pky;
   END ins;

   FUNCTION ins (
      id_interv_plan_in IN EPIS_INTERV_PLAN.ID_INTERV_PLAN%TYPE DEFAULT NULL,
      id_episode_in IN EPIS_INTERV_PLAN.ID_EPISODE%TYPE DEFAULT NULL,
      id_professional_in IN EPIS_INTERV_PLAN.ID_PROFESSIONAL%TYPE DEFAULT NULL,
      flg_status_in IN EPIS_INTERV_PLAN.FLG_STATUS%TYPE DEFAULT NULL,
      notes_in IN EPIS_INTERV_PLAN.NOTES%TYPE DEFAULT NULL,
      dt_creation_in IN EPIS_INTERV_PLAN.DT_CREATION%TYPE DEFAULT NULL,
      dt_begin_in IN EPIS_INTERV_PLAN.DT_BEGIN%TYPE DEFAULT NULL,
      dt_end_in IN EPIS_INTERV_PLAN.DT_END%TYPE DEFAULT NULL,
      id_cancel_info_det_in IN EPIS_INTERV_PLAN.ID_CANCEL_INFO_DET%TYPE DEFAULT NULL,
      flg_available_in IN EPIS_INTERV_PLAN.FLG_AVAILABLE%TYPE DEFAULT 'Y',
      desc_other_interv_plan_in IN EPIS_INTERV_PLAN.DESC_OTHER_INTERV_PLAN%TYPE DEFAULT NULL,
      create_user_in IN EPIS_INTERV_PLAN.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN EPIS_INTERV_PLAN.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN EPIS_INTERV_PLAN.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN EPIS_INTERV_PLAN.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN EPIS_INTERV_PLAN.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN EPIS_INTERV_PLAN.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      id_task_goal_det_in IN EPIS_INTERV_PLAN.ID_TASK_GOAL_DET%TYPE DEFAULT NULL
      ,handle_error_in IN BOOLEAN := TRUE
   )
      RETURN
         EPIS_INTERV_PLAN.ID_EPIS_INTERV_PLAN%TYPE
   IS
        l_pky EPIS_INTERV_PLAN.ID_EPIS_INTERV_PLAN%TYPE := next_key;
    rows_out TABLE_VARCHAR;
   BEGIN
      ins (
         id_epis_interv_plan_in => l_pky,
         id_interv_plan_in => id_interv_plan_in,
         id_episode_in => id_episode_in,
         id_professional_in => id_professional_in,
         flg_status_in => flg_status_in,
         notes_in => notes_in,
         dt_creation_in => dt_creation_in,
         dt_begin_in => dt_begin_in,
         dt_end_in => dt_end_in,
         id_cancel_info_det_in => id_cancel_info_det_in,
         flg_available_in => flg_available_in,
         desc_other_interv_plan_in => desc_other_interv_plan_in,
         create_user_in => create_user_in,
         create_time_in => create_time_in,
         create_institution_in => create_institution_in,
         update_user_in => update_user_in,
         update_time_in => update_time_in,
         update_institution_in => update_institution_in,
         id_task_goal_det_in => id_task_goal_det_in
         ,handle_error_in => handle_error_in
         , rows_out => rows_out
         );
      RETURN l_pky;
   END ins;

      PROCEDURE ins (
      id_interv_plan_in IN EPIS_INTERV_PLAN.ID_INTERV_PLAN%TYPE DEFAULT NULL,
      id_episode_in IN EPIS_INTERV_PLAN.ID_EPISODE%TYPE DEFAULT NULL,
      id_professional_in IN EPIS_INTERV_PLAN.ID_PROFESSIONAL%TYPE DEFAULT NULL,
      flg_status_in IN EPIS_INTERV_PLAN.FLG_STATUS%TYPE DEFAULT NULL,
      notes_in IN EPIS_INTERV_PLAN.NOTES%TYPE DEFAULT NULL,
      dt_creation_in IN EPIS_INTERV_PLAN.DT_CREATION%TYPE DEFAULT NULL,
      dt_begin_in IN EPIS_INTERV_PLAN.DT_BEGIN%TYPE DEFAULT NULL,
      dt_end_in IN EPIS_INTERV_PLAN.DT_END%TYPE DEFAULT NULL,
      id_cancel_info_det_in IN EPIS_INTERV_PLAN.ID_CANCEL_INFO_DET%TYPE DEFAULT NULL,
      flg_available_in IN EPIS_INTERV_PLAN.FLG_AVAILABLE%TYPE DEFAULT 'Y',
      desc_other_interv_plan_in IN EPIS_INTERV_PLAN.DESC_OTHER_INTERV_PLAN%TYPE DEFAULT NULL,
      create_user_in IN EPIS_INTERV_PLAN.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN EPIS_INTERV_PLAN.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN EPIS_INTERV_PLAN.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN EPIS_INTERV_PLAN.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN EPIS_INTERV_PLAN.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN EPIS_INTERV_PLAN.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      id_task_goal_det_in IN EPIS_INTERV_PLAN.ID_TASK_GOAL_DET%TYPE DEFAULT NULL
      ,handle_error_in IN BOOLEAN := TRUE
      , rows_out OUT TABLE_VARCHAR
   )
   IS
        l_pky EPIS_INTERV_PLAN.ID_EPIS_INTERV_PLAN%TYPE := next_key;
   BEGIN
      ins (
         id_epis_interv_plan_in => l_pky,
         id_interv_plan_in => id_interv_plan_in,
         id_episode_in => id_episode_in,
         id_professional_in => id_professional_in,
         flg_status_in => flg_status_in,
         notes_in => notes_in,
         dt_creation_in => dt_creation_in,
         dt_begin_in => dt_begin_in,
         dt_end_in => dt_end_in,
         id_cancel_info_det_in => id_cancel_info_det_in,
         flg_available_in => flg_available_in,
         desc_other_interv_plan_in => desc_other_interv_plan_in,
         create_user_in => create_user_in,
         create_time_in => create_time_in,
         create_institution_in => create_institution_in,
         update_user_in => update_user_in,
         update_time_in => update_time_in,
         update_institution_in => update_institution_in,
         id_task_goal_det_in => id_task_goal_det_in
         ,handle_error_in => handle_error_in
         , rows_out => rows_out
         );
   END ins;


     PROCEDURE ins (
      id_interv_plan_in IN EPIS_INTERV_PLAN.ID_INTERV_PLAN%TYPE DEFAULT NULL,
      id_episode_in IN EPIS_INTERV_PLAN.ID_EPISODE%TYPE DEFAULT NULL,
      id_professional_in IN EPIS_INTERV_PLAN.ID_PROFESSIONAL%TYPE DEFAULT NULL,
      flg_status_in IN EPIS_INTERV_PLAN.FLG_STATUS%TYPE DEFAULT NULL,
      notes_in IN EPIS_INTERV_PLAN.NOTES%TYPE DEFAULT NULL,
      dt_creation_in IN EPIS_INTERV_PLAN.DT_CREATION%TYPE DEFAULT NULL,
      dt_begin_in IN EPIS_INTERV_PLAN.DT_BEGIN%TYPE DEFAULT NULL,
      dt_end_in IN EPIS_INTERV_PLAN.DT_END%TYPE DEFAULT NULL,
      id_cancel_info_det_in IN EPIS_INTERV_PLAN.ID_CANCEL_INFO_DET%TYPE DEFAULT NULL,
      flg_available_in IN EPIS_INTERV_PLAN.FLG_AVAILABLE%TYPE DEFAULT 'Y',
      desc_other_interv_plan_in IN EPIS_INTERV_PLAN.DESC_OTHER_INTERV_PLAN%TYPE DEFAULT NULL,
      create_user_in IN EPIS_INTERV_PLAN.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN EPIS_INTERV_PLAN.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN EPIS_INTERV_PLAN.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN EPIS_INTERV_PLAN.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN EPIS_INTERV_PLAN.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN EPIS_INTERV_PLAN.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      id_task_goal_det_in IN EPIS_INTERV_PLAN.ID_TASK_GOAL_DET%TYPE DEFAULT NULL
      ,handle_error_in IN BOOLEAN := TRUE
   )
   IS
        l_pky EPIS_INTERV_PLAN.ID_EPIS_INTERV_PLAN%TYPE := next_key;
      rows_out TABLE_VARCHAR;
   BEGIN
      ins (
         id_epis_interv_plan_in => l_pky,
         id_interv_plan_in => id_interv_plan_in,
         id_episode_in => id_episode_in,
         id_professional_in => id_professional_in,
         flg_status_in => flg_status_in,
         notes_in => notes_in,
         dt_creation_in => dt_creation_in,
         dt_begin_in => dt_begin_in,
         dt_end_in => dt_end_in,
         id_cancel_info_det_in => id_cancel_info_det_in,
         flg_available_in => flg_available_in,
         desc_other_interv_plan_in => desc_other_interv_plan_in,
         create_user_in => create_user_in,
         create_time_in => create_time_in,
         create_institution_in => create_institution_in,
         update_user_in => update_user_in,
         update_time_in => update_time_in,
         update_institution_in => update_institution_in,
         id_task_goal_det_in => id_task_goal_det_in
         ,handle_error_in => handle_error_in
         , rows_out => rows_out
         );
   END ins;

    PROCEDURE ins (
      rows_in IN EPIS_INTERV_PLAN_tc
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
   )
   IS
   BEGIN
      IF rows_in.COUNT = 0
      THEN
         NULL;
      ELSE
         FORALL indx IN rows_in.FIRST .. rows_in.LAST
            SAVE EXCEPTIONS
            INSERT INTO EPIS_INTERV_PLAN VALUES rows_in (indx) RETURNING ROWID BULK COLLECT INTO rows_out;
      END IF;
   EXCEPTION
     WHEN e_forall_error
     THEN
        -- In Oracle9i and above, SAVE EXCEPTIONS will direct control
        -- here if any error occurs. We can then save all the error
        -- information out to the error instance.
       IF NOT handle_error_in THEN RAISE;
       ELSE
          <<bulk_handler>>
          DECLARE
             l_err_instance_id NUMBER;
          BEGIN
             -- For each error, write to the log.
             FOR indx IN 1 .. SQL%BULK_EXCEPTIONS.COUNT
             LOOP
                pk_alert_exceptions.register_error (
                    error_name_in => 'FORALL-INSERT-FAILURE'
                   ,err_instance_id_out => l_err_instance_id
                );

                pk_alert_exceptions.add_context (
                   err_instance_id_in => l_err_instance_id
                  ,NAME_IN => 'BINDING_ROW_' || indx
                  ,value_in => SQL%BULK_EXCEPTIONS (indx).ERROR_INDEX
                  ,validate_in => FALSE
                );
                pk_alert_exceptions.add_context (
                   err_instance_id_in => l_err_instance_id
                  ,NAME_IN => 'ERROR_AT_ROW_' || indx
                  ,value_in => SQL%BULK_EXCEPTIONS (indx).ERROR_CODE
                  ,validate_in => FALSE
                );

                pk_alert_exceptions.add_context (
                   err_instance_id_in => l_err_instance_id
                  ,NAME_IN => 'ID_EPIS_INTERV_PLAN _' || indx
                  ,value_in => rows_in(indx).ID_EPIS_INTERV_PLAN
                  ,validate_in => FALSE
                );

                pk_alert_exceptions.add_context (
                   err_instance_id_in => l_err_instance_id
                  ,NAME_IN => 'ID_INTERV_PLAN _' || indx
                  ,value_in => rows_in(indx).ID_INTERV_PLAN
                  ,validate_in => FALSE
                );

                pk_alert_exceptions.add_context (
                   err_instance_id_in => l_err_instance_id
                  ,NAME_IN => 'ID_EPISODE _' || indx
                  ,value_in => rows_in(indx).ID_EPISODE
                  ,validate_in => FALSE
                );

                pk_alert_exceptions.add_context (
                   err_instance_id_in => l_err_instance_id
                  ,NAME_IN => 'ID_PROFESSIONAL _' || indx
                  ,value_in => rows_in(indx).ID_PROFESSIONAL
                  ,validate_in => FALSE
                );

                pk_alert_exceptions.add_context (
                   err_instance_id_in => l_err_instance_id
                  ,NAME_IN => 'FLG_STATUS _' || indx
                  ,value_in => rows_in(indx).FLG_STATUS
                  ,validate_in => FALSE
                );

                pk_alert_exceptions.add_context (
                   err_instance_id_in => l_err_instance_id
                  ,NAME_IN => 'NOTES _' || indx
                  ,value_in => rows_in(indx).NOTES
                  ,validate_in => FALSE
                );

                pk_alert_exceptions.add_context (
                   err_instance_id_in => l_err_instance_id
                  ,NAME_IN => 'DT_CREATION _' || indx
                  ,value_in => rows_in(indx).DT_CREATION
                  ,validate_in => FALSE
                );

                pk_alert_exceptions.add_context (
                   err_instance_id_in => l_err_instance_id
                  ,NAME_IN => 'DT_BEGIN _' || indx
                  ,value_in => rows_in(indx).DT_BEGIN
                  ,validate_in => FALSE
                );

                pk_alert_exceptions.add_context (
                   err_instance_id_in => l_err_instance_id
                  ,NAME_IN => 'DT_END _' || indx
                  ,value_in => rows_in(indx).DT_END
                  ,validate_in => FALSE
                );

                pk_alert_exceptions.add_context (
                   err_instance_id_in => l_err_instance_id
                  ,NAME_IN => 'ID_CANCEL_INFO_DET _' || indx
                  ,value_in => rows_in(indx).ID_CANCEL_INFO_DET
                  ,validate_in => FALSE
                );

                pk_alert_exceptions.add_context (
                   err_instance_id_in => l_err_instance_id
                  ,NAME_IN => 'FLG_AVAILABLE _' || indx
                  ,value_in => rows_in(indx).FLG_AVAILABLE
                  ,validate_in => FALSE
                );

                pk_alert_exceptions.add_context (
                   err_instance_id_in => l_err_instance_id
                  ,NAME_IN => 'DESC_OTHER_INTERV_PLAN _' || indx
                  ,value_in => rows_in(indx).DESC_OTHER_INTERV_PLAN
                  ,validate_in => FALSE
                );

                pk_alert_exceptions.add_context (
                   err_instance_id_in => l_err_instance_id
                  ,NAME_IN => 'CREATE_USER _' || indx
                  ,value_in => rows_in(indx).CREATE_USER
                  ,validate_in => FALSE
                );

                pk_alert_exceptions.add_context (
                   err_instance_id_in => l_err_instance_id
                  ,NAME_IN => 'CREATE_TIME _' || indx
                  ,value_in => rows_in(indx).CREATE_TIME
                  ,validate_in => FALSE
                );

                pk_alert_exceptions.add_context (
                   err_instance_id_in => l_err_instance_id
                  ,NAME_IN => 'CREATE_INSTITUTION _' || indx
                  ,value_in => rows_in(indx).CREATE_INSTITUTION
                  ,validate_in => FALSE
                );

                pk_alert_exceptions.add_context (
                   err_instance_id_in => l_err_instance_id
                  ,NAME_IN => 'UPDATE_USER _' || indx
                  ,value_in => rows_in(indx).UPDATE_USER
                  ,validate_in => FALSE
                );

                pk_alert_exceptions.add_context (
                   err_instance_id_in => l_err_instance_id
                  ,NAME_IN => 'UPDATE_TIME _' || indx
                  ,value_in => rows_in(indx).UPDATE_TIME
                  ,validate_in => FALSE
                );

                pk_alert_exceptions.add_context (
                   err_instance_id_in => l_err_instance_id
                  ,NAME_IN => 'UPDATE_INSTITUTION _' || indx
                  ,value_in => rows_in(indx).UPDATE_INSTITUTION
                  ,validate_in => FALSE
                );

                pk_alert_exceptions.add_context (
                   err_instance_id_in => l_err_instance_id
                  ,NAME_IN => 'ID_TASK_GOAL_DET _' || indx
                  ,value_in => rows_in(indx).ID_TASK_GOAL_DET
                  ,validate_in => FALSE
                );

                pk_alert_exceptions.raise_error_instance( err_instance_id_in => l_err_instance_id );
             END LOOP;
          END bulk_handler;
        END IF;
     WHEN OTHERS
     THEN
       IF NOT handle_error_in THEN RAISE;
       ELSE
       pk_alert_exceptions.raise_error(
          error_name_in => 'FORALL-INSERT-FAILURE'
          ,name1_in => 'TABLE_NAME'
          ,value1_in => 'EPIS_INTERV_PLAN'
          ,name2_in => 'ROW_COUNT'
          ,value2_in => rows_in.COUNT
           );
       END IF;
   END ins;

    PROCEDURE ins (
      rows_in IN EPIS_INTERV_PLAN_tc
     ,handle_error_in IN BOOLEAN := TRUE
   )
   IS
      rows_out TABLE_VARCHAR;
   BEGIN
      ins (
      rows_in => rows_in
     ,handle_error_in => handle_error_in
     , rows_out => rows_out
   );
   END ins;


PROCEDURE upd (
      id_epis_interv_plan_in IN EPIS_INTERV_PLAN.ID_EPIS_INTERV_PLAN%TYPE,
      id_interv_plan_in IN EPIS_INTERV_PLAN.ID_INTERV_PLAN%TYPE DEFAULT NULL,
      ID_INTERV_PLAN_nin IN BOOLEAN := TRUE,
      id_episode_in IN EPIS_INTERV_PLAN.ID_EPISODE%TYPE DEFAULT NULL,
      ID_EPISODE_nin IN BOOLEAN := TRUE,
      id_professional_in IN EPIS_INTERV_PLAN.ID_PROFESSIONAL%TYPE DEFAULT NULL,
      ID_PROFESSIONAL_nin IN BOOLEAN := TRUE,
      flg_status_in IN EPIS_INTERV_PLAN.FLG_STATUS%TYPE DEFAULT NULL,
      FLG_STATUS_nin IN BOOLEAN := TRUE,
      notes_in IN EPIS_INTERV_PLAN.NOTES%TYPE DEFAULT NULL,
      NOTES_nin IN BOOLEAN := TRUE,
      dt_creation_in IN EPIS_INTERV_PLAN.DT_CREATION%TYPE DEFAULT NULL,
      DT_CREATION_nin IN BOOLEAN := TRUE,
      dt_begin_in IN EPIS_INTERV_PLAN.DT_BEGIN%TYPE DEFAULT NULL,
      DT_BEGIN_nin IN BOOLEAN := TRUE,
      dt_end_in IN EPIS_INTERV_PLAN.DT_END%TYPE DEFAULT NULL,
      DT_END_nin IN BOOLEAN := TRUE,
      id_cancel_info_det_in IN EPIS_INTERV_PLAN.ID_CANCEL_INFO_DET%TYPE DEFAULT NULL,
      ID_CANCEL_INFO_DET_nin IN BOOLEAN := TRUE,
      flg_available_in IN EPIS_INTERV_PLAN.FLG_AVAILABLE%TYPE DEFAULT NULL,
      FLG_AVAILABLE_nin IN BOOLEAN := TRUE,
      desc_other_interv_plan_in IN EPIS_INTERV_PLAN.DESC_OTHER_INTERV_PLAN%TYPE DEFAULT NULL,
      DESC_OTHER_INTERV_PLAN_nin IN BOOLEAN := TRUE,
      create_user_in IN EPIS_INTERV_PLAN.CREATE_USER%TYPE DEFAULT NULL,
      CREATE_USER_nin IN BOOLEAN := TRUE,
      create_time_in IN EPIS_INTERV_PLAN.CREATE_TIME%TYPE DEFAULT NULL,
      CREATE_TIME_nin IN BOOLEAN := TRUE,
      create_institution_in IN EPIS_INTERV_PLAN.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      CREATE_INSTITUTION_nin IN BOOLEAN := TRUE,
      update_user_in IN EPIS_INTERV_PLAN.UPDATE_USER%TYPE DEFAULT NULL,
      UPDATE_USER_nin IN BOOLEAN := TRUE,
      update_time_in IN EPIS_INTERV_PLAN.UPDATE_TIME%TYPE DEFAULT NULL,
      UPDATE_TIME_nin IN BOOLEAN := TRUE,
      update_institution_in IN EPIS_INTERV_PLAN.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      UPDATE_INSTITUTION_nin IN BOOLEAN := TRUE,
      id_task_goal_det_in IN EPIS_INTERV_PLAN.ID_TASK_GOAL_DET%TYPE DEFAULT NULL,
      ID_TASK_GOAL_DET_nin IN BOOLEAN := TRUE,
     handle_error_in IN BOOLEAN := TRUE
     , rows_out IN OUT TABLE_VARCHAR
      )
   IS
   l_rows_out TABLE_VARCHAR;
   l_ID_INTERV_PLAN_n NUMBER(1);
   l_ID_EPISODE_n NUMBER(1);
   l_ID_PROFESSIONAL_n NUMBER(1);
   l_FLG_STATUS_n NUMBER(1);
   l_NOTES_n NUMBER(1);
   l_DT_CREATION_n NUMBER(1);
   l_DT_BEGIN_n NUMBER(1);
   l_DT_END_n NUMBER(1);
   l_ID_CANCEL_INFO_DET_n NUMBER(1);
   l_FLG_AVAILABLE_n NUMBER(1);
   l_DESC_OTHER_INTERV_PLAN_n NUMBER(1);
   l_CREATE_USER_n NUMBER(1);
   l_CREATE_TIME_n NUMBER(1);
   l_CREATE_INSTITUTION_n NUMBER(1);
   l_UPDATE_USER_n NUMBER(1);
   l_UPDATE_TIME_n NUMBER(1);
   l_UPDATE_INSTITUTION_n NUMBER(1);
   l_ID_TASK_GOAL_DET_n NUMBER(1);
   BEGIN

   l_ID_INTERV_PLAN_n := sys.diutil.bool_to_int(ID_INTERV_PLAN_nin);
   l_ID_EPISODE_n := sys.diutil.bool_to_int(ID_EPISODE_nin);
   l_ID_PROFESSIONAL_n := sys.diutil.bool_to_int(ID_PROFESSIONAL_nin);
   l_FLG_STATUS_n := sys.diutil.bool_to_int(FLG_STATUS_nin);
   l_NOTES_n := sys.diutil.bool_to_int(NOTES_nin);
   l_DT_CREATION_n := sys.diutil.bool_to_int(DT_CREATION_nin);
   l_DT_BEGIN_n := sys.diutil.bool_to_int(DT_BEGIN_nin);
   l_DT_END_n := sys.diutil.bool_to_int(DT_END_nin);
   l_ID_CANCEL_INFO_DET_n := sys.diutil.bool_to_int(ID_CANCEL_INFO_DET_nin);
   l_FLG_AVAILABLE_n := sys.diutil.bool_to_int(FLG_AVAILABLE_nin);
   l_DESC_OTHER_INTERV_PLAN_n := sys.diutil.bool_to_int(DESC_OTHER_INTERV_PLAN_nin);
   l_CREATE_USER_n := sys.diutil.bool_to_int(CREATE_USER_nin);
   l_CREATE_TIME_n := sys.diutil.bool_to_int(CREATE_TIME_nin);
   l_CREATE_INSTITUTION_n := sys.diutil.bool_to_int(CREATE_INSTITUTION_nin);
   l_UPDATE_USER_n := sys.diutil.bool_to_int(UPDATE_USER_nin);
   l_UPDATE_TIME_n := sys.diutil.bool_to_int(UPDATE_TIME_nin);
   l_UPDATE_INSTITUTION_n := sys.diutil.bool_to_int(UPDATE_INSTITUTION_nin);
   l_ID_TASK_GOAL_DET_n := sys.diutil.bool_to_int(ID_TASK_GOAL_DET_nin);


         UPDATE EPIS_INTERV_PLAN SET
     ID_INTERV_PLAN = decode (l_ID_INTERV_PLAN_n,0,id_interv_plan_in, NVL (id_interv_plan_in, ID_INTERV_PLAN)),
     ID_EPISODE = decode (l_ID_EPISODE_n,0,id_episode_in, NVL (id_episode_in, ID_EPISODE)),
     ID_PROFESSIONAL = decode (l_ID_PROFESSIONAL_n,0,id_professional_in, NVL (id_professional_in, ID_PROFESSIONAL)),
     FLG_STATUS = decode (l_FLG_STATUS_n,0,flg_status_in, NVL (flg_status_in, FLG_STATUS)),
     NOTES = decode (l_NOTES_n,0,notes_in, NVL (notes_in, NOTES)),
     DT_CREATION = decode (l_DT_CREATION_n,0,dt_creation_in, NVL (dt_creation_in, DT_CREATION)),
     DT_BEGIN = decode (l_DT_BEGIN_n,0,dt_begin_in, NVL (dt_begin_in, DT_BEGIN)),
     DT_END = decode (l_DT_END_n,0,dt_end_in, NVL (dt_end_in, DT_END)),
     ID_CANCEL_INFO_DET = decode (l_ID_CANCEL_INFO_DET_n,0,id_cancel_info_det_in, NVL (id_cancel_info_det_in, ID_CANCEL_INFO_DET)),
     FLG_AVAILABLE = decode (l_FLG_AVAILABLE_n,0,flg_available_in, NVL (flg_available_in, FLG_AVAILABLE)),
     DESC_OTHER_INTERV_PLAN = decode (l_DESC_OTHER_INTERV_PLAN_n,0,desc_other_interv_plan_in, NVL (desc_other_interv_plan_in, DESC_OTHER_INTERV_PLAN)),
     CREATE_USER = decode (l_CREATE_USER_n,0,create_user_in, NVL (create_user_in, CREATE_USER)),
     CREATE_TIME = decode (l_CREATE_TIME_n,0,create_time_in, NVL (create_time_in, CREATE_TIME)),
     CREATE_INSTITUTION = decode (l_CREATE_INSTITUTION_n,0,create_institution_in, NVL (create_institution_in, CREATE_INSTITUTION)),
     UPDATE_USER = decode (l_UPDATE_USER_n,0,update_user_in, NVL (update_user_in, UPDATE_USER)),
     UPDATE_TIME = decode (l_UPDATE_TIME_n,0,update_time_in, NVL (update_time_in, UPDATE_TIME)),
     UPDATE_INSTITUTION = decode (l_UPDATE_INSTITUTION_n,0,update_institution_in, NVL (update_institution_in, UPDATE_INSTITUTION)),
     ID_TASK_GOAL_DET = decode (l_ID_TASK_GOAL_DET_n,0,id_task_goal_det_in, NVL (id_task_goal_det_in, ID_TASK_GOAL_DET))
          WHERE
             ID_EPIS_INTERV_PLAN = id_epis_interv_plan_in
         RETURNING ROWID BULK COLLECT INTO l_rows_out;


if(rows_out is null)
then
rows_out := table_varchar();
end if;

rows_out :=  rows_out MULTISET UNION DISTINCT l_rows_out;

   EXCEPTION
      WHEN DUP_VAL_ON_INDEX
      THEN
        IF NOT handle_error_in THEN RAISE;
        ELSE
        DECLARE
           l_owner ALL_CONSTRAINTS.OWNER%TYPE;
           l_name ALL_CONSTRAINTS.CONSTRAINT_NAME%TYPE;
           l_err_instance_id PLS_INTEGER;
        BEGIN
           get_constraint_info (l_owner, l_name);
           IF FALSE THEN NULL; -- Placeholder in case no unique indexes
           ELSE
              pk_alert_exceptions.raise_error (
                    error_name_in => 'DUPLICATE-VALUE'
                    ,name1_in => 'OWNER'
                    ,value1_in => l_owner
                    ,name2_in => 'CONSTRAINT_NAME'
                    ,value2_in => l_name
                    ,name3_in => 'TABLE_NAME'
                    ,value3_in => 'EPIS_INTERV_PLAN');
           END IF;
        END;
        END IF;
      WHEN e_check_constraint_failure
      THEN
        IF NOT handle_error_in THEN RAISE;
        ELSE
        DECLARE
           l_owner ALL_CONSTRAINTS.OWNER%TYPE;
           l_name ALL_CONSTRAINTS.CONSTRAINT_NAME%TYPE;
        BEGIN
           get_constraint_info (l_owner, l_name);
           pk_alert_exceptions.raise_error (
              error_name_in => 'CHECK-CONSTRAINT-FAILURE'
             ,name1_in => 'OWNER'
             ,value1_in => l_owner
             ,name2_in => 'CONSTRAINT_NAME'
             ,value2_in => l_name
             ,name3_in => 'TABLE_NAME'
             ,value3_in => 'EPIS_INTERV_PLAN');
        END;
        END IF;
      WHEN e_integ_constraint_failure OR e_no_parent_key OR e_child_record_found
      THEN
        IF NOT handle_error_in THEN RAISE;
        ELSE
        DECLARE
           l_owner ALL_CONSTRAINTS.OWNER%TYPE;
           l_name ALL_CONSTRAINTS.CONSTRAINT_NAME%TYPE;
           l_id PLS_INTEGER;
           l_err_name VARCHAR2(32767) DEFAULT 'NO-PARENT-KEY-FOUND';
        BEGIN
           get_constraint_info (l_owner, l_name);
           IF SQLCODE = -2292 -- Child record found
           THEN
              l_err_name := 'CHILD-RECORD-FOUND' ;
           END IF;
           pk_alert_exceptions.register_error (
              error_name_in => l_err_name
             ,err_instance_id_out => l_id
             ,name1_in => 'OWNER', value1_in => l_owner
             ,name2_in => 'CONSTRAINT_NAME', value2_in => l_name
             ,name3_in => 'TABLE_NAME', value3_in => 'EPIS_INTERV_PLAN');
           IF l_name = 'EIP_P_FK'
           THEN
              -- Add a context value for each column
              pk_alert_exceptions.add_context (
                 err_instance_id_in => l_id
               , name_in => 'ID_PROFESSIONAL'
               , value_in => id_professional_in);
           END IF;
           IF l_name = 'EIP_TSKGD_FK'
           THEN
              -- Add a context value for each column
              pk_alert_exceptions.add_context (
                 err_instance_id_in => l_id
               , name_in => 'ID_TASK_GOAL_DET'
               , value_in => id_task_goal_det_in);
           END IF;
           pk_alert_exceptions.raise_error_instance (err_instance_id_in => l_id);
        END;
        END IF;
      WHEN e_null_column_value
      THEN
        IF NOT handle_error_in THEN RAISE;
        ELSE
        DECLARE
           v_errm VARCHAR2(2000) := DBMS_UTILITY.FORMAT_ERROR_STACK;
           dot1loc INTEGER;
           dot2loc INTEGER;
           parenloc INTEGER;
           c_owner ALL_CONSTRAINTS.OWNER%TYPE;
           c_tabname ALL_TABLES.TABLE_NAME%TYPE;
           c_colname ALL_TAB_COLUMNS.COLUMN_NAME%TYPE;
        BEGIN
           dot1loc := INSTR (v_errm, '.', 1, 1);
           dot2loc := INSTR (v_errm, '.', 1, 2);
           parenloc := INSTR (v_errm, '(');
           c_owner :=SUBSTR (v_errm, parenloc+1, dot1loc-parenloc-1);
           c_tabname := SUBSTR (v_errm, dot1loc+1, dot2loc-dot1loc-1);
           c_colname := SUBSTR (v_errm, dot2loc+1, INSTR (v_errm,')')-dot2loc-1);

           pk_alert_exceptions.raise_error (
                error_name_in => 'COLUMN-CANNOT-BE-NULL'
               ,name1_in => 'OWNER'
               ,value1_in => c_owner
               ,name2_in => 'TABLE_NAME'
               ,value2_in => c_tabname
               ,name3_in => 'COLUMN_NAME'
               ,value3_in => c_colname);
        END;
        END IF;
   END upd;


   PROCEDURE upd (
      id_epis_interv_plan_in IN EPIS_INTERV_PLAN.ID_EPIS_INTERV_PLAN%TYPE,
      id_interv_plan_in IN EPIS_INTERV_PLAN.ID_INTERV_PLAN%TYPE DEFAULT NULL,
      ID_INTERV_PLAN_nin IN BOOLEAN := TRUE,
      id_episode_in IN EPIS_INTERV_PLAN.ID_EPISODE%TYPE DEFAULT NULL,
      ID_EPISODE_nin IN BOOLEAN := TRUE,
      id_professional_in IN EPIS_INTERV_PLAN.ID_PROFESSIONAL%TYPE DEFAULT NULL,
      ID_PROFESSIONAL_nin IN BOOLEAN := TRUE,
      flg_status_in IN EPIS_INTERV_PLAN.FLG_STATUS%TYPE DEFAULT NULL,
      FLG_STATUS_nin IN BOOLEAN := TRUE,
      notes_in IN EPIS_INTERV_PLAN.NOTES%TYPE DEFAULT NULL,
      NOTES_nin IN BOOLEAN := TRUE,
      dt_creation_in IN EPIS_INTERV_PLAN.DT_CREATION%TYPE DEFAULT NULL,
      DT_CREATION_nin IN BOOLEAN := TRUE,
      dt_begin_in IN EPIS_INTERV_PLAN.DT_BEGIN%TYPE DEFAULT NULL,
      DT_BEGIN_nin IN BOOLEAN := TRUE,
      dt_end_in IN EPIS_INTERV_PLAN.DT_END%TYPE DEFAULT NULL,
      DT_END_nin IN BOOLEAN := TRUE,
      id_cancel_info_det_in IN EPIS_INTERV_PLAN.ID_CANCEL_INFO_DET%TYPE DEFAULT NULL,
      ID_CANCEL_INFO_DET_nin IN BOOLEAN := TRUE,
      flg_available_in IN EPIS_INTERV_PLAN.FLG_AVAILABLE%TYPE DEFAULT NULL,
      FLG_AVAILABLE_nin IN BOOLEAN := TRUE,
      desc_other_interv_plan_in IN EPIS_INTERV_PLAN.DESC_OTHER_INTERV_PLAN%TYPE DEFAULT NULL,
      DESC_OTHER_INTERV_PLAN_nin IN BOOLEAN := TRUE,
      create_user_in IN EPIS_INTERV_PLAN.CREATE_USER%TYPE DEFAULT NULL,
      CREATE_USER_nin IN BOOLEAN := TRUE,
      create_time_in IN EPIS_INTERV_PLAN.CREATE_TIME%TYPE DEFAULT NULL,
      CREATE_TIME_nin IN BOOLEAN := TRUE,
      create_institution_in IN EPIS_INTERV_PLAN.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      CREATE_INSTITUTION_nin IN BOOLEAN := TRUE,
      update_user_in IN EPIS_INTERV_PLAN.UPDATE_USER%TYPE DEFAULT NULL,
      UPDATE_USER_nin IN BOOLEAN := TRUE,
      update_time_in IN EPIS_INTERV_PLAN.UPDATE_TIME%TYPE DEFAULT NULL,
      UPDATE_TIME_nin IN BOOLEAN := TRUE,
      update_institution_in IN EPIS_INTERV_PLAN.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      UPDATE_INSTITUTION_nin IN BOOLEAN := TRUE,
      id_task_goal_det_in IN EPIS_INTERV_PLAN.ID_TASK_GOAL_DET%TYPE DEFAULT NULL,
      ID_TASK_GOAL_DET_nin IN BOOLEAN := TRUE,
     handle_error_in IN BOOLEAN := TRUE
      )
   IS
   rows_out TABLE_VARCHAR;
   BEGIN
     upd (
      id_epis_interv_plan_in => id_epis_interv_plan_in,
      id_interv_plan_in => id_interv_plan_in,
      ID_INTERV_PLAN_nin => ID_INTERV_PLAN_nin,
      id_episode_in => id_episode_in,
      ID_EPISODE_nin => ID_EPISODE_nin,
      id_professional_in => id_professional_in,
      ID_PROFESSIONAL_nin => ID_PROFESSIONAL_nin,
      flg_status_in => flg_status_in,
      FLG_STATUS_nin => FLG_STATUS_nin,
      notes_in => notes_in,
      NOTES_nin => NOTES_nin,
      dt_creation_in => dt_creation_in,
      DT_CREATION_nin => DT_CREATION_nin,
      dt_begin_in => dt_begin_in,
      DT_BEGIN_nin => DT_BEGIN_nin,
      dt_end_in => dt_end_in,
      DT_END_nin => DT_END_nin,
      id_cancel_info_det_in => id_cancel_info_det_in,
      ID_CANCEL_INFO_DET_nin => ID_CANCEL_INFO_DET_nin,
      flg_available_in => flg_available_in,
      FLG_AVAILABLE_nin => FLG_AVAILABLE_nin,
      desc_other_interv_plan_in => desc_other_interv_plan_in,
      DESC_OTHER_INTERV_PLAN_nin => DESC_OTHER_INTERV_PLAN_nin,
      create_user_in => create_user_in,
      CREATE_USER_nin => CREATE_USER_nin,
      create_time_in => create_time_in,
      CREATE_TIME_nin => CREATE_TIME_nin,
      create_institution_in => create_institution_in,
      CREATE_INSTITUTION_nin => CREATE_INSTITUTION_nin,
      update_user_in => update_user_in,
      UPDATE_USER_nin => UPDATE_USER_nin,
      update_time_in => update_time_in,
      UPDATE_TIME_nin => UPDATE_TIME_nin,
      update_institution_in => update_institution_in,
      UPDATE_INSTITUTION_nin => UPDATE_INSTITUTION_nin,
      id_task_goal_det_in => id_task_goal_det_in,
      ID_TASK_GOAL_DET_nin => ID_TASK_GOAL_DET_nin,
     handle_error_in => handle_error_in
     , rows_out => rows_out
      );
   END upd;

PROCEDURE upd (
      id_interv_plan_in IN EPIS_INTERV_PLAN.ID_INTERV_PLAN%TYPE DEFAULT NULL,
      ID_INTERV_PLAN_nin IN BOOLEAN := TRUE,
      id_episode_in IN EPIS_INTERV_PLAN.ID_EPISODE%TYPE DEFAULT NULL,
      ID_EPISODE_nin IN BOOLEAN := TRUE,
      id_professional_in IN EPIS_INTERV_PLAN.ID_PROFESSIONAL%TYPE DEFAULT NULL,
      ID_PROFESSIONAL_nin IN BOOLEAN := TRUE,
      flg_status_in IN EPIS_INTERV_PLAN.FLG_STATUS%TYPE DEFAULT NULL,
      FLG_STATUS_nin IN BOOLEAN := TRUE,
      notes_in IN EPIS_INTERV_PLAN.NOTES%TYPE DEFAULT NULL,
      NOTES_nin IN BOOLEAN := TRUE,
      dt_creation_in IN EPIS_INTERV_PLAN.DT_CREATION%TYPE DEFAULT NULL,
      DT_CREATION_nin IN BOOLEAN := TRUE,
      dt_begin_in IN EPIS_INTERV_PLAN.DT_BEGIN%TYPE DEFAULT NULL,
      DT_BEGIN_nin IN BOOLEAN := TRUE,
      dt_end_in IN EPIS_INTERV_PLAN.DT_END%TYPE DEFAULT NULL,
      DT_END_nin IN BOOLEAN := TRUE,
      id_cancel_info_det_in IN EPIS_INTERV_PLAN.ID_CANCEL_INFO_DET%TYPE DEFAULT NULL,
      ID_CANCEL_INFO_DET_nin IN BOOLEAN := TRUE,
      flg_available_in IN EPIS_INTERV_PLAN.FLG_AVAILABLE%TYPE DEFAULT NULL,
      FLG_AVAILABLE_nin IN BOOLEAN := TRUE,
      desc_other_interv_plan_in IN EPIS_INTERV_PLAN.DESC_OTHER_INTERV_PLAN%TYPE DEFAULT NULL,
      DESC_OTHER_INTERV_PLAN_nin IN BOOLEAN := TRUE,
      create_user_in IN EPIS_INTERV_PLAN.CREATE_USER%TYPE DEFAULT NULL,
      CREATE_USER_nin IN BOOLEAN := TRUE,
      create_time_in IN EPIS_INTERV_PLAN.CREATE_TIME%TYPE DEFAULT NULL,
      CREATE_TIME_nin IN BOOLEAN := TRUE,
      create_institution_in IN EPIS_INTERV_PLAN.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      CREATE_INSTITUTION_nin IN BOOLEAN := TRUE,
      update_user_in IN EPIS_INTERV_PLAN.UPDATE_USER%TYPE DEFAULT NULL,
      UPDATE_USER_nin IN BOOLEAN := TRUE,
      update_time_in IN EPIS_INTERV_PLAN.UPDATE_TIME%TYPE DEFAULT NULL,
      UPDATE_TIME_nin IN BOOLEAN := TRUE,
      update_institution_in IN EPIS_INTERV_PLAN.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      UPDATE_INSTITUTION_nin IN BOOLEAN := TRUE,
      id_task_goal_det_in IN EPIS_INTERV_PLAN.ID_TASK_GOAL_DET%TYPE DEFAULT NULL,
      ID_TASK_GOAL_DET_nin IN BOOLEAN := TRUE,
    where_in varchar2 DEFAULT NULL,
     handle_error_in IN BOOLEAN := TRUE
     , rows_out IN OUT TABLE_VARCHAR
      )
   IS
   l_sql VARCHAR2(32767);
   l_rows_out TABLE_VARCHAR;
   l_ID_INTERV_PLAN_n NUMBER(1);
   l_ID_EPISODE_n NUMBER(1);
   l_ID_PROFESSIONAL_n NUMBER(1);
   l_FLG_STATUS_n NUMBER(1);
   l_NOTES_n NUMBER(1);
   l_DT_CREATION_n NUMBER(1);
   l_DT_BEGIN_n NUMBER(1);
   l_DT_END_n NUMBER(1);
   l_ID_CANCEL_INFO_DET_n NUMBER(1);
   l_FLG_AVAILABLE_n NUMBER(1);
   l_DESC_OTHER_INTERV_PLAN_n NUMBER(1);
   l_CREATE_USER_n NUMBER(1);
   l_CREATE_TIME_n NUMBER(1);
   l_CREATE_INSTITUTION_n NUMBER(1);
   l_UPDATE_USER_n NUMBER(1);
   l_UPDATE_TIME_n NUMBER(1);
   l_UPDATE_INSTITUTION_n NUMBER(1);
   l_ID_TASK_GOAL_DET_n NUMBER(1);
      id_epis_interv_plan_in EPIS_INTERV_PLAN.ID_EPIS_INTERV_PLAN%TYPE;
   BEGIN



      l_ID_INTERV_PLAN_n := sys.diutil.bool_to_int(ID_INTERV_PLAN_nin);
      l_ID_EPISODE_n := sys.diutil.bool_to_int(ID_EPISODE_nin);
      l_ID_PROFESSIONAL_n := sys.diutil.bool_to_int(ID_PROFESSIONAL_nin);
      l_FLG_STATUS_n := sys.diutil.bool_to_int(FLG_STATUS_nin);
      l_NOTES_n := sys.diutil.bool_to_int(NOTES_nin);
      l_DT_CREATION_n := sys.diutil.bool_to_int(DT_CREATION_nin);
      l_DT_BEGIN_n := sys.diutil.bool_to_int(DT_BEGIN_nin);
      l_DT_END_n := sys.diutil.bool_to_int(DT_END_nin);
      l_ID_CANCEL_INFO_DET_n := sys.diutil.bool_to_int(ID_CANCEL_INFO_DET_nin);
      l_FLG_AVAILABLE_n := sys.diutil.bool_to_int(FLG_AVAILABLE_nin);
      l_DESC_OTHER_INTERV_PLAN_n := sys.diutil.bool_to_int(DESC_OTHER_INTERV_PLAN_nin);
      l_CREATE_USER_n := sys.diutil.bool_to_int(CREATE_USER_nin);
      l_CREATE_TIME_n := sys.diutil.bool_to_int(CREATE_TIME_nin);
      l_CREATE_INSTITUTION_n := sys.diutil.bool_to_int(CREATE_INSTITUTION_nin);
      l_UPDATE_USER_n := sys.diutil.bool_to_int(UPDATE_USER_nin);
      l_UPDATE_TIME_n := sys.diutil.bool_to_int(UPDATE_TIME_nin);
      l_UPDATE_INSTITUTION_n := sys.diutil.bool_to_int(UPDATE_INSTITUTION_nin);
      l_ID_TASK_GOAL_DET_n := sys.diutil.bool_to_int(ID_TASK_GOAL_DET_nin);



l_sql := 'UPDATE EPIS_INTERV_PLAN SET '
     || ' ID_INTERV_PLAN = decode (' || l_ID_INTERV_PLAN_n || ',0,:id_interv_plan_in, NVL (:id_interv_plan_in, ID_INTERV_PLAN)) '|| ','
     || ' ID_EPISODE = decode (' || l_ID_EPISODE_n || ',0,:id_episode_in, NVL (:id_episode_in, ID_EPISODE)) '|| ','
     || ' ID_PROFESSIONAL = decode (' || l_ID_PROFESSIONAL_n || ',0,:id_professional_in, NVL (:id_professional_in, ID_PROFESSIONAL)) '|| ','
     || ' FLG_STATUS = decode (' || l_FLG_STATUS_n || ',0,:flg_status_in, NVL (:flg_status_in, FLG_STATUS)) '|| ','
     || ' NOTES = decode (' || l_NOTES_n || ',0,:notes_in, NVL (:notes_in, NOTES)) '|| ','
     || ' DT_CREATION = decode (' || l_DT_CREATION_n || ',0,:dt_creation_in, NVL (:dt_creation_in, DT_CREATION)) '|| ','
     || ' DT_BEGIN = decode (' || l_DT_BEGIN_n || ',0,:dt_begin_in, NVL (:dt_begin_in, DT_BEGIN)) '|| ','
     || ' DT_END = decode (' || l_DT_END_n || ',0,:dt_end_in, NVL (:dt_end_in, DT_END)) '|| ','
     || ' ID_CANCEL_INFO_DET = decode (' || l_ID_CANCEL_INFO_DET_n || ',0,:id_cancel_info_det_in, NVL (:id_cancel_info_det_in, ID_CANCEL_INFO_DET)) '|| ','
     || ' FLG_AVAILABLE = decode (' || l_FLG_AVAILABLE_n || ',0,:flg_available_in, NVL (:flg_available_in, FLG_AVAILABLE)) '|| ','
     || ' DESC_OTHER_INTERV_PLAN = decode (' || l_DESC_OTHER_INTERV_PLAN_n || ',0,:desc_other_interv_plan_in, NVL (:desc_other_interv_plan_in, DESC_OTHER_INTERV_PLAN)) '|| ','
     || ' CREATE_USER = decode (' || l_CREATE_USER_n || ',0,:create_user_in, NVL (:create_user_in, CREATE_USER)) '|| ','
     || ' CREATE_TIME = decode (' || l_CREATE_TIME_n || ',0,:create_time_in, NVL (:create_time_in, CREATE_TIME)) '|| ','
     || ' CREATE_INSTITUTION = decode (' || l_CREATE_INSTITUTION_n || ',0,:create_institution_in, NVL (:create_institution_in, CREATE_INSTITUTION)) '|| ','
     || ' UPDATE_USER = decode (' || l_UPDATE_USER_n || ',0,:update_user_in, NVL (:update_user_in, UPDATE_USER)) '|| ','
     || ' UPDATE_TIME = decode (' || l_UPDATE_TIME_n || ',0,:update_time_in, NVL (:update_time_in, UPDATE_TIME)) '|| ','
     || ' UPDATE_INSTITUTION = decode (' || l_UPDATE_INSTITUTION_n || ',0,:update_institution_in, NVL (:update_institution_in, UPDATE_INSTITUTION)) '|| ','
     || ' ID_TASK_GOAL_DET = decode (' || l_ID_TASK_GOAL_DET_n || ',0,:id_task_goal_det_in, NVL (:id_task_goal_det_in, ID_TASK_GOAL_DET)) '
      || ' where ' || nvl(where_in,'(1=1)')
      || ' RETURNING ROWID BULK COLLECT INTO :l_rows_out';




execute immediate 'BEGIN ' || l_sql || '; END;' using in
     id_interv_plan_in,
     id_episode_in,
     id_professional_in,
     flg_status_in,
     notes_in,
     dt_creation_in,
     dt_begin_in,
     dt_end_in,
     id_cancel_info_det_in,
     flg_available_in,
     desc_other_interv_plan_in,
     create_user_in,
     create_time_in,
     create_institution_in,
     update_user_in,
     update_time_in,
     update_institution_in,
     id_task_goal_det_in,
    OUT l_rows_out;

if(rows_out is null)
then
rows_out := table_varchar();
end if;

rows_out :=  rows_out MULTISET UNION DISTINCT l_rows_out;

   EXCEPTION
      WHEN DUP_VAL_ON_INDEX
      THEN
        IF NOT handle_error_in THEN RAISE;
        ELSE
        DECLARE
           l_owner ALL_CONSTRAINTS.OWNER%TYPE;
           l_name ALL_CONSTRAINTS.CONSTRAINT_NAME%TYPE;
           l_err_instance_id PLS_INTEGER;
        BEGIN
           get_constraint_info (l_owner, l_name);
           IF FALSE THEN NULL; -- Placeholder in case no unique indexes
           ELSE
              pk_alert_exceptions.raise_error (
                    error_name_in => 'DUPLICATE-VALUE'
                    ,name1_in => 'OWNER'
                    ,value1_in => l_owner
                    ,name2_in => 'CONSTRAINT_NAME'
                    ,value2_in => l_name
                    ,name3_in => 'TABLE_NAME'
                    ,value3_in => 'EPIS_INTERV_PLAN');
           END IF;
        END;
        END IF;
      WHEN e_check_constraint_failure
      THEN
        IF NOT handle_error_in THEN RAISE;
        ELSE
        DECLARE
           l_owner ALL_CONSTRAINTS.OWNER%TYPE;
           l_name ALL_CONSTRAINTS.CONSTRAINT_NAME%TYPE;
        BEGIN
           get_constraint_info (l_owner, l_name);
           pk_alert_exceptions.raise_error (
              error_name_in => 'CHECK-CONSTRAINT-FAILURE'
             ,name1_in => 'OWNER'
             ,value1_in => l_owner
             ,name2_in => 'CONSTRAINT_NAME'
             ,value2_in => l_name
             ,name3_in => 'TABLE_NAME'
             ,value3_in => 'EPIS_INTERV_PLAN');
        END;
        END IF;
      WHEN e_integ_constraint_failure OR e_no_parent_key OR e_child_record_found
      THEN
        IF NOT handle_error_in THEN RAISE;
        ELSE
        DECLARE
           l_owner ALL_CONSTRAINTS.OWNER%TYPE;
           l_name ALL_CONSTRAINTS.CONSTRAINT_NAME%TYPE;
           l_id PLS_INTEGER;
           l_err_name VARCHAR2(32767) DEFAULT 'NO-PARENT-KEY-FOUND';
        BEGIN
           get_constraint_info (l_owner, l_name);
           IF SQLCODE = -2292 -- Child record found
           THEN
              l_err_name := 'CHILD-RECORD-FOUND' ;
           END IF;
           pk_alert_exceptions.register_error (
              error_name_in => l_err_name
             ,err_instance_id_out => l_id
             ,name1_in => 'OWNER', value1_in => l_owner
             ,name2_in => 'CONSTRAINT_NAME', value2_in => l_name
             ,name3_in => 'TABLE_NAME', value3_in => 'EPIS_INTERV_PLAN');
           IF l_name = 'EIP_P_FK'
           THEN
              -- Add a context value for each column
              pk_alert_exceptions.add_context (
                 err_instance_id_in => l_id
               , name_in => 'ID_PROFESSIONAL'
               , value_in => id_professional_in);
           END IF;
           IF l_name = 'EIP_TSKGD_FK'
           THEN
              -- Add a context value for each column
              pk_alert_exceptions.add_context (
                 err_instance_id_in => l_id
               , name_in => 'ID_TASK_GOAL_DET'
               , value_in => id_task_goal_det_in);
           END IF;
           pk_alert_exceptions.raise_error_instance (err_instance_id_in => l_id);
        END;
        END IF;
      WHEN e_null_column_value
      THEN
        IF NOT handle_error_in THEN RAISE;
        ELSE
        DECLARE
           v_errm VARCHAR2(2000) := DBMS_UTILITY.FORMAT_ERROR_STACK;
           dot1loc INTEGER;
           dot2loc INTEGER;
           parenloc INTEGER;
           c_owner ALL_CONSTRAINTS.OWNER%TYPE;
           c_tabname ALL_TABLES.TABLE_NAME%TYPE;
           c_colname ALL_TAB_COLUMNS.COLUMN_NAME%TYPE;
        BEGIN
           dot1loc := INSTR (v_errm, '.', 1, 1);
           dot2loc := INSTR (v_errm, '.', 1, 2);
           parenloc := INSTR (v_errm, '(');
           c_owner :=SUBSTR (v_errm, parenloc+1, dot1loc-parenloc-1);
           c_tabname := SUBSTR (v_errm, dot1loc+1, dot2loc-dot1loc-1);
           c_colname := SUBSTR (v_errm, dot2loc+1, INSTR (v_errm,')')-dot2loc-1);

           pk_alert_exceptions.raise_error (
                error_name_in => 'COLUMN-CANNOT-BE-NULL'
               ,name1_in => 'OWNER'
               ,value1_in => c_owner
               ,name2_in => 'TABLE_NAME'
               ,value2_in => c_tabname
               ,name3_in => 'COLUMN_NAME'
               ,value3_in => c_colname);
        END;
        END IF;
   END upd;





PROCEDURE upd (
      id_interv_plan_in IN EPIS_INTERV_PLAN.ID_INTERV_PLAN%TYPE DEFAULT NULL,
      ID_INTERV_PLAN_nin IN BOOLEAN := TRUE,
      id_episode_in IN EPIS_INTERV_PLAN.ID_EPISODE%TYPE DEFAULT NULL,
      ID_EPISODE_nin IN BOOLEAN := TRUE,
      id_professional_in IN EPIS_INTERV_PLAN.ID_PROFESSIONAL%TYPE DEFAULT NULL,
      ID_PROFESSIONAL_nin IN BOOLEAN := TRUE,
      flg_status_in IN EPIS_INTERV_PLAN.FLG_STATUS%TYPE DEFAULT NULL,
      FLG_STATUS_nin IN BOOLEAN := TRUE,
      notes_in IN EPIS_INTERV_PLAN.NOTES%TYPE DEFAULT NULL,
      NOTES_nin IN BOOLEAN := TRUE,
      dt_creation_in IN EPIS_INTERV_PLAN.DT_CREATION%TYPE DEFAULT NULL,
      DT_CREATION_nin IN BOOLEAN := TRUE,
      dt_begin_in IN EPIS_INTERV_PLAN.DT_BEGIN%TYPE DEFAULT NULL,
      DT_BEGIN_nin IN BOOLEAN := TRUE,
      dt_end_in IN EPIS_INTERV_PLAN.DT_END%TYPE DEFAULT NULL,
      DT_END_nin IN BOOLEAN := TRUE,
      id_cancel_info_det_in IN EPIS_INTERV_PLAN.ID_CANCEL_INFO_DET%TYPE DEFAULT NULL,
      ID_CANCEL_INFO_DET_nin IN BOOLEAN := TRUE,
      flg_available_in IN EPIS_INTERV_PLAN.FLG_AVAILABLE%TYPE DEFAULT NULL,
      FLG_AVAILABLE_nin IN BOOLEAN := TRUE,
      desc_other_interv_plan_in IN EPIS_INTERV_PLAN.DESC_OTHER_INTERV_PLAN%TYPE DEFAULT NULL,
      DESC_OTHER_INTERV_PLAN_nin IN BOOLEAN := TRUE,
      create_user_in IN EPIS_INTERV_PLAN.CREATE_USER%TYPE DEFAULT NULL,
      CREATE_USER_nin IN BOOLEAN := TRUE,
      create_time_in IN EPIS_INTERV_PLAN.CREATE_TIME%TYPE DEFAULT NULL,
      CREATE_TIME_nin IN BOOLEAN := TRUE,
      create_institution_in IN EPIS_INTERV_PLAN.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      CREATE_INSTITUTION_nin IN BOOLEAN := TRUE,
      update_user_in IN EPIS_INTERV_PLAN.UPDATE_USER%TYPE DEFAULT NULL,
      UPDATE_USER_nin IN BOOLEAN := TRUE,
      update_time_in IN EPIS_INTERV_PLAN.UPDATE_TIME%TYPE DEFAULT NULL,
      UPDATE_TIME_nin IN BOOLEAN := TRUE,
      update_institution_in IN EPIS_INTERV_PLAN.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      UPDATE_INSTITUTION_nin IN BOOLEAN := TRUE,
      id_task_goal_det_in IN EPIS_INTERV_PLAN.ID_TASK_GOAL_DET%TYPE DEFAULT NULL,
      ID_TASK_GOAL_DET_nin IN BOOLEAN := TRUE,
    where_in varchar2 DEFAULT NULL,
     handle_error_in IN BOOLEAN := TRUE
      )
   IS
   rows_out TABLE_VARCHAR;
   BEGIN
      upd (
      id_interv_plan_in => id_interv_plan_in,
      ID_INTERV_PLAN_nin => ID_INTERV_PLAN_nin,
      id_episode_in => id_episode_in,
      ID_EPISODE_nin => ID_EPISODE_nin,
      id_professional_in => id_professional_in,
      ID_PROFESSIONAL_nin => ID_PROFESSIONAL_nin,
      flg_status_in => flg_status_in,
      FLG_STATUS_nin => FLG_STATUS_nin,
      notes_in => notes_in,
      NOTES_nin => NOTES_nin,
      dt_creation_in => dt_creation_in,
      DT_CREATION_nin => DT_CREATION_nin,
      dt_begin_in => dt_begin_in,
      DT_BEGIN_nin => DT_BEGIN_nin,
      dt_end_in => dt_end_in,
      DT_END_nin => DT_END_nin,
      id_cancel_info_det_in => id_cancel_info_det_in,
      ID_CANCEL_INFO_DET_nin => ID_CANCEL_INFO_DET_nin,
      flg_available_in => flg_available_in,
      FLG_AVAILABLE_nin => FLG_AVAILABLE_nin,
      desc_other_interv_plan_in => desc_other_interv_plan_in,
      DESC_OTHER_INTERV_PLAN_nin => DESC_OTHER_INTERV_PLAN_nin,
      create_user_in => create_user_in,
      CREATE_USER_nin => CREATE_USER_nin,
      create_time_in => create_time_in,
      CREATE_TIME_nin => CREATE_TIME_nin,
      create_institution_in => create_institution_in,
      CREATE_INSTITUTION_nin => CREATE_INSTITUTION_nin,
      update_user_in => update_user_in,
      UPDATE_USER_nin => UPDATE_USER_nin,
      update_time_in => update_time_in,
      UPDATE_TIME_nin => UPDATE_TIME_nin,
      update_institution_in => update_institution_in,
      UPDATE_INSTITUTION_nin => UPDATE_INSTITUTION_nin,
      id_task_goal_det_in => id_task_goal_det_in,
      ID_TASK_GOAL_DET_nin => ID_TASK_GOAL_DET_nin,
    where_in => where_in,
     handle_error_in => handle_error_in
     , rows_out => rows_out
      );
   END upd;

   PROCEDURE upd (
      rec_in IN EPIS_INTERV_PLAN%ROWTYPE,
     handle_error_in IN BOOLEAN := TRUE
     , rows_out IN OUT TABLE_VARCHAR
      )
   IS
   BEGIN
      upd (
         id_epis_interv_plan_in => rec_in.ID_EPIS_INTERV_PLAN,
         id_interv_plan_in => rec_in.ID_INTERV_PLAN,
         id_episode_in => rec_in.ID_EPISODE,
         id_professional_in => rec_in.ID_PROFESSIONAL,
         flg_status_in => rec_in.FLG_STATUS,
         notes_in => rec_in.NOTES,
         dt_creation_in => rec_in.DT_CREATION,
         dt_begin_in => rec_in.DT_BEGIN,
         dt_end_in => rec_in.DT_END,
         id_cancel_info_det_in => rec_in.ID_CANCEL_INFO_DET,
         flg_available_in => rec_in.FLG_AVAILABLE,
         desc_other_interv_plan_in => rec_in.DESC_OTHER_INTERV_PLAN,
         create_user_in => rec_in.CREATE_USER,
         create_time_in => rec_in.CREATE_TIME,
         create_institution_in => rec_in.CREATE_INSTITUTION,
         update_user_in => rec_in.UPDATE_USER,
         update_time_in => rec_in.UPDATE_TIME,
         update_institution_in => rec_in.UPDATE_INSTITUTION,
         id_task_goal_det_in => rec_in.ID_TASK_GOAL_DET

        ,handle_error_in => handle_error_in
        , rows_out => rows_out
       );
   END upd;

   PROCEDURE upd (
      rec_in IN EPIS_INTERV_PLAN%ROWTYPE,
     handle_error_in IN BOOLEAN := TRUE
      )
   IS
        rows_out TABLE_VARCHAR;
   BEGIN
      upd (
         id_epis_interv_plan_in => rec_in.ID_EPIS_INTERV_PLAN,
         id_interv_plan_in => rec_in.ID_INTERV_PLAN,
         id_episode_in => rec_in.ID_EPISODE,
         id_professional_in => rec_in.ID_PROFESSIONAL,
         flg_status_in => rec_in.FLG_STATUS,
         notes_in => rec_in.NOTES,
         dt_creation_in => rec_in.DT_CREATION,
         dt_begin_in => rec_in.DT_BEGIN,
         dt_end_in => rec_in.DT_END,
         id_cancel_info_det_in => rec_in.ID_CANCEL_INFO_DET,
         flg_available_in => rec_in.FLG_AVAILABLE,
         desc_other_interv_plan_in => rec_in.DESC_OTHER_INTERV_PLAN,
         create_user_in => rec_in.CREATE_USER,
         create_time_in => rec_in.CREATE_TIME,
         create_institution_in => rec_in.CREATE_INSTITUTION,
         update_user_in => rec_in.UPDATE_USER,
         update_time_in => rec_in.UPDATE_TIME,
         update_institution_in => rec_in.UPDATE_INSTITUTION,
         id_task_goal_det_in => rec_in.ID_TASK_GOAL_DET

        ,handle_error_in => handle_error_in
        , rows_out => rows_out
       );
   END upd;

   PROCEDURE upd_ins (
      id_epis_interv_plan_in IN EPIS_INTERV_PLAN.ID_EPIS_INTERV_PLAN%TYPE,
      id_interv_plan_in IN EPIS_INTERV_PLAN.ID_INTERV_PLAN%TYPE DEFAULT NULL,
      id_episode_in IN EPIS_INTERV_PLAN.ID_EPISODE%TYPE DEFAULT NULL,
      id_professional_in IN EPIS_INTERV_PLAN.ID_PROFESSIONAL%TYPE DEFAULT NULL,
      flg_status_in IN EPIS_INTERV_PLAN.FLG_STATUS%TYPE DEFAULT NULL,
      notes_in IN EPIS_INTERV_PLAN.NOTES%TYPE DEFAULT NULL,
      dt_creation_in IN EPIS_INTERV_PLAN.DT_CREATION%TYPE DEFAULT NULL,
      dt_begin_in IN EPIS_INTERV_PLAN.DT_BEGIN%TYPE DEFAULT NULL,
      dt_end_in IN EPIS_INTERV_PLAN.DT_END%TYPE DEFAULT NULL,
      id_cancel_info_det_in IN EPIS_INTERV_PLAN.ID_CANCEL_INFO_DET%TYPE DEFAULT NULL,
      flg_available_in IN EPIS_INTERV_PLAN.FLG_AVAILABLE%TYPE DEFAULT NULL,
      desc_other_interv_plan_in IN EPIS_INTERV_PLAN.DESC_OTHER_INTERV_PLAN%TYPE DEFAULT NULL,
      create_user_in IN EPIS_INTERV_PLAN.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN EPIS_INTERV_PLAN.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN EPIS_INTERV_PLAN.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN EPIS_INTERV_PLAN.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN EPIS_INTERV_PLAN.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN EPIS_INTERV_PLAN.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      id_task_goal_det_in IN EPIS_INTERV_PLAN.ID_TASK_GOAL_DET%TYPE DEFAULT NULL,
     handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      )
   IS
   BEGIN
      upd (
         id_epis_interv_plan_in => id_epis_interv_plan_in,
         id_interv_plan_in => id_interv_plan_in,
         id_episode_in => id_episode_in,
         id_professional_in => id_professional_in,
         flg_status_in => flg_status_in,
         notes_in => notes_in,
         dt_creation_in => dt_creation_in,
         dt_begin_in => dt_begin_in,
         dt_end_in => dt_end_in,
         id_cancel_info_det_in => id_cancel_info_det_in,
         flg_available_in => flg_available_in,
         desc_other_interv_plan_in => desc_other_interv_plan_in,
         create_user_in => create_user_in,
         create_time_in => create_time_in,
         create_institution_in => create_institution_in,
         update_user_in => update_user_in,
         update_time_in => update_time_in,
         update_institution_in => update_institution_in,
         id_task_goal_det_in => id_task_goal_det_in
         ,handle_error_in => handle_error_in
         , rows_out => rows_out
       );
      IF SQL%ROWCOUNT = 0
      THEN
         ins (
            id_epis_interv_plan_in => id_epis_interv_plan_in,
            id_interv_plan_in => id_interv_plan_in,
            id_episode_in => id_episode_in,
            id_professional_in => id_professional_in,
            flg_status_in => flg_status_in,
            notes_in => notes_in,
            dt_creation_in => dt_creation_in,
            dt_begin_in => dt_begin_in,
            dt_end_in => dt_end_in,
            id_cancel_info_det_in => id_cancel_info_det_in,
            flg_available_in => flg_available_in,
            desc_other_interv_plan_in => desc_other_interv_plan_in,
            create_user_in => create_user_in,
            create_time_in => create_time_in,
            create_institution_in => create_institution_in,
            update_user_in => update_user_in,
            update_time_in => update_time_in,
            update_institution_in => update_institution_in,
            id_task_goal_det_in => id_task_goal_det_in
            ,handle_error_in => handle_error_in
            , rows_out => rows_out
         );
      END IF;
   END upd_ins;

   PROCEDURE upd_ins (
      id_epis_interv_plan_in IN EPIS_INTERV_PLAN.ID_EPIS_INTERV_PLAN%TYPE,
      id_interv_plan_in IN EPIS_INTERV_PLAN.ID_INTERV_PLAN%TYPE DEFAULT NULL,
      id_episode_in IN EPIS_INTERV_PLAN.ID_EPISODE%TYPE DEFAULT NULL,
      id_professional_in IN EPIS_INTERV_PLAN.ID_PROFESSIONAL%TYPE DEFAULT NULL,
      flg_status_in IN EPIS_INTERV_PLAN.FLG_STATUS%TYPE DEFAULT NULL,
      notes_in IN EPIS_INTERV_PLAN.NOTES%TYPE DEFAULT NULL,
      dt_creation_in IN EPIS_INTERV_PLAN.DT_CREATION%TYPE DEFAULT NULL,
      dt_begin_in IN EPIS_INTERV_PLAN.DT_BEGIN%TYPE DEFAULT NULL,
      dt_end_in IN EPIS_INTERV_PLAN.DT_END%TYPE DEFAULT NULL,
      id_cancel_info_det_in IN EPIS_INTERV_PLAN.ID_CANCEL_INFO_DET%TYPE DEFAULT NULL,
      flg_available_in IN EPIS_INTERV_PLAN.FLG_AVAILABLE%TYPE DEFAULT NULL,
      desc_other_interv_plan_in IN EPIS_INTERV_PLAN.DESC_OTHER_INTERV_PLAN%TYPE DEFAULT NULL,
      create_user_in IN EPIS_INTERV_PLAN.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN EPIS_INTERV_PLAN.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN EPIS_INTERV_PLAN.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN EPIS_INTERV_PLAN.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN EPIS_INTERV_PLAN.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN EPIS_INTERV_PLAN.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      id_task_goal_det_in IN EPIS_INTERV_PLAN.ID_TASK_GOAL_DET%TYPE DEFAULT NULL,
     handle_error_in IN BOOLEAN := TRUE
      )
   IS
        rows_out TABLE_VARCHAR;
   BEGIN
      upd_ins (
      id_epis_interv_plan_in,
      id_interv_plan_in,
      id_episode_in,
      id_professional_in,
      flg_status_in,
      notes_in,
      dt_creation_in,
      dt_begin_in,
      dt_end_in,
      id_cancel_info_det_in,
      flg_available_in,
      desc_other_interv_plan_in,
      create_user_in,
      create_time_in,
      create_institution_in,
      update_user_in,
      update_time_in,
      update_institution_in,
      id_task_goal_det_in,
     handle_error_in
     ,rows_out
      );
   END upd_ins;


   PROCEDURE upd (
      col_in IN EPIS_INTERV_PLAN_tc,
      ignore_if_null_in IN BOOLEAN := TRUE
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out IN OUT TABLE_VARCHAR
      )
   IS
      l_ID_EPIS_INTERV_PLAN ID_EPIS_INTERV_PLAN_cc;
      l_ID_INTERV_PLAN ID_INTERV_PLAN_cc;
      l_ID_EPISODE ID_EPISODE_cc;
      l_ID_PROFESSIONAL ID_PROFESSIONAL_cc;
      l_FLG_STATUS FLG_STATUS_cc;
      l_NOTES NOTES_cc;
      l_DT_CREATION DT_CREATION_cc;
      l_DT_BEGIN DT_BEGIN_cc;
      l_DT_END DT_END_cc;
      l_ID_CANCEL_INFO_DET ID_CANCEL_INFO_DET_cc;
      l_FLG_AVAILABLE FLG_AVAILABLE_cc;
      l_DESC_OTHER_INTERV_PLAN DESC_OTHER_INTERV_PLAN_cc;
      l_CREATE_USER CREATE_USER_cc;
      l_CREATE_TIME CREATE_TIME_cc;
      l_CREATE_INSTITUTION CREATE_INSTITUTION_cc;
      l_UPDATE_USER UPDATE_USER_cc;
      l_UPDATE_TIME UPDATE_TIME_cc;
      l_UPDATE_INSTITUTION UPDATE_INSTITUTION_cc;
      l_ID_TASK_GOAL_DET ID_TASK_GOAL_DET_cc;
   BEGIN
      FOR i IN col_in.FIRST .. col_in.LAST loop
         l_ID_EPIS_INTERV_PLAN(i) := col_in(i).ID_EPIS_INTERV_PLAN;
         l_ID_INTERV_PLAN(i) := col_in(i).ID_INTERV_PLAN;
         l_ID_EPISODE(i) := col_in(i).ID_EPISODE;
         l_ID_PROFESSIONAL(i) := col_in(i).ID_PROFESSIONAL;
         l_FLG_STATUS(i) := col_in(i).FLG_STATUS;
         l_NOTES(i) := col_in(i).NOTES;
         l_DT_CREATION(i) := col_in(i).DT_CREATION;
         l_DT_BEGIN(i) := col_in(i).DT_BEGIN;
         l_DT_END(i) := col_in(i).DT_END;
         l_ID_CANCEL_INFO_DET(i) := col_in(i).ID_CANCEL_INFO_DET;
         l_FLG_AVAILABLE(i) := col_in(i).FLG_AVAILABLE;
         l_DESC_OTHER_INTERV_PLAN(i) := col_in(i).DESC_OTHER_INTERV_PLAN;
         l_CREATE_USER(i) := col_in(i).CREATE_USER;
         l_CREATE_TIME(i) := col_in(i).CREATE_TIME;
         l_CREATE_INSTITUTION(i) := col_in(i).CREATE_INSTITUTION;
         l_UPDATE_USER(i) := col_in(i).UPDATE_USER;
         l_UPDATE_TIME(i) := col_in(i).UPDATE_TIME;
         l_UPDATE_INSTITUTION(i) := col_in(i).UPDATE_INSTITUTION;
         l_ID_TASK_GOAL_DET(i) := col_in(i).ID_TASK_GOAL_DET;
      END LOOP;
      IF NVL (ignore_if_null_in, FALSE)
      THEN
         -- Set any columns to their current values
         -- if incoming value is NULL.
         -- Put WHEN clause on column-level triggers!
         FORALL i IN col_in.FIRST .. col_in.LAST
            UPDATE EPIS_INTERV_PLAN SET
               ID_INTERV_PLAN = NVL (l_ID_INTERV_PLAN(i), ID_INTERV_PLAN),
               ID_EPISODE = NVL (l_ID_EPISODE(i), ID_EPISODE),
               ID_PROFESSIONAL = NVL (l_ID_PROFESSIONAL(i), ID_PROFESSIONAL),
               FLG_STATUS = NVL (l_FLG_STATUS(i), FLG_STATUS),
               NOTES = NVL (l_NOTES(i), NOTES),
               DT_CREATION = NVL (l_DT_CREATION(i), DT_CREATION),
               DT_BEGIN = NVL (l_DT_BEGIN(i), DT_BEGIN),
               DT_END = NVL (l_DT_END(i), DT_END),
               ID_CANCEL_INFO_DET = NVL (l_ID_CANCEL_INFO_DET(i), ID_CANCEL_INFO_DET),
               FLG_AVAILABLE = NVL (l_FLG_AVAILABLE(i), FLG_AVAILABLE),
               DESC_OTHER_INTERV_PLAN = NVL (l_DESC_OTHER_INTERV_PLAN(i), DESC_OTHER_INTERV_PLAN),
               CREATE_USER = NVL (l_CREATE_USER(i), CREATE_USER),
               CREATE_TIME = NVL (l_CREATE_TIME(i), CREATE_TIME),
               CREATE_INSTITUTION = NVL (l_CREATE_INSTITUTION(i), CREATE_INSTITUTION),
               UPDATE_USER = NVL (l_UPDATE_USER(i), UPDATE_USER),
               UPDATE_TIME = NVL (l_UPDATE_TIME(i), UPDATE_TIME),
               UPDATE_INSTITUTION = NVL (l_UPDATE_INSTITUTION(i), UPDATE_INSTITUTION),
               ID_TASK_GOAL_DET = NVL (l_ID_TASK_GOAL_DET(i), ID_TASK_GOAL_DET)
             WHERE
                ID_EPIS_INTERV_PLAN = l_ID_EPIS_INTERV_PLAN(i)
         ;
      ELSE
         FORALL i IN col_in.FIRST .. col_in.LAST
            UPDATE EPIS_INTERV_PLAN SET
               ID_INTERV_PLAN = l_ID_INTERV_PLAN(i),
               ID_EPISODE = l_ID_EPISODE(i),
               ID_PROFESSIONAL = l_ID_PROFESSIONAL(i),
               FLG_STATUS = l_FLG_STATUS(i),
               NOTES = l_NOTES(i),
               DT_CREATION = l_DT_CREATION(i),
               DT_BEGIN = l_DT_BEGIN(i),
               DT_END = l_DT_END(i),
               ID_CANCEL_INFO_DET = l_ID_CANCEL_INFO_DET(i),
               FLG_AVAILABLE = l_FLG_AVAILABLE(i),
               DESC_OTHER_INTERV_PLAN = l_DESC_OTHER_INTERV_PLAN(i),
               CREATE_USER = l_CREATE_USER(i),
               CREATE_TIME = l_CREATE_TIME(i),
               CREATE_INSTITUTION = l_CREATE_INSTITUTION(i),
               UPDATE_USER = l_UPDATE_USER(i),
               UPDATE_TIME = l_UPDATE_TIME(i),
               UPDATE_INSTITUTION = l_UPDATE_INSTITUTION(i),
               ID_TASK_GOAL_DET = l_ID_TASK_GOAL_DET(i)
             WHERE
                ID_EPIS_INTERV_PLAN = l_ID_EPIS_INTERV_PLAN(i)
         ;
      END IF;
   END upd;


   PROCEDURE upd (
      col_in IN EPIS_INTERV_PLAN_tc,
      ignore_if_null_in IN BOOLEAN := TRUE
     ,handle_error_in IN BOOLEAN := TRUE
      )
   IS
     rows_out TABLE_VARCHAR;
   BEGIN
      upd (
      col_in ,
      ignore_if_null_in
     ,handle_error_in
     , rows_out
      );
   END upd;

   FUNCTION dynupdstr (
      colname_in IN ALL_TAB_COLUMNS.COLUMN_NAME%TYPE,
      where_in IN VARCHAR2 := NULL)

   RETURN VARCHAR2
   IS
   BEGIN
      RETURN
         'BEGIN UPDATE EPIS_INTERV_PLAN
             SET ' || colname_in || ' = :value
           WHERE ' || NVL (where_in, '1=1') || ' RETURNING ROWID BULK COLLECT INTO :rows_out; END;' ;
   END dynupdstr;

   FUNCTION dynupdstr_no_rows_out (
      colname_in IN ALL_TAB_COLUMNS.COLUMN_NAME%TYPE,
      where_in IN VARCHAR2 := NULL)

   RETURN VARCHAR2
   IS
   BEGIN
      RETURN
         'UPDATE EPIS_INTERV_PLAN
             SET ' || colname_in || ' = :value
           WHERE ' || NVL (where_in, '1=1');
   END dynupdstr_no_rows_out;























  PROCEDURE increment_onecol (
      colname_in IN ALL_TAB_COLUMNS.COLUMN_NAME%TYPE,
      where_in IN VARCHAR2 := NULL
      , increment_value_in IN NUMBER DEFAULT 1
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
   )
   IS
   BEGIN
      EXECUTE IMMEDIATE 'BEGIN UPDATE EPIS_INTERV_PLAN set ' || colname_in || '=' || colname_in || ' + ' || nvl(increment_value_in,1) || ' WHERE ' || NVL (where_in, '1=1') || ' RETURNING ROWID BULK COLLECT INTO :rows_out; END;'
      USING OUT rows_out;
   EXCEPTION
      WHEN DUP_VAL_ON_INDEX
      THEN
        IF NOT handle_error_in THEN RAISE;
        ELSE
        DECLARE
           l_owner ALL_CONSTRAINTS.OWNER%TYPE;
           l_name ALL_CONSTRAINTS.CONSTRAINT_NAME%TYPE;
           l_err_instance_id PLS_INTEGER;
        BEGIN
           get_constraint_info (l_owner, l_name);
           pk_alert_exceptions.raise_error (
              error_name_in => 'DUPLICATE-VALUE'
             ,name1_in => 'OWNER'
             ,value1_in => l_owner
             ,name2_in => 'CONSTRAINT_NAME'
             ,value2_in => l_name
             ,name3_in => 'TABLE_NAME'
             ,value3_in => 'EPIS_INTERV_PLAN');
        END;
        END IF;
      WHEN e_check_constraint_failure
      THEN
        IF NOT handle_error_in THEN RAISE;
        ELSE
        DECLARE
           l_owner ALL_CONSTRAINTS.OWNER%TYPE;
           l_name ALL_CONSTRAINTS.CONSTRAINT_NAME%TYPE;
        BEGIN
           get_constraint_info (l_owner, l_name);
           pk_alert_exceptions.raise_error (
              error_name_in => 'CHECK-CONSTRAINT-FAILURE'
             ,name1_in => 'OWNER'
             ,value1_in => l_owner
             ,name2_in => 'CONSTRAINT_NAME'
             ,value2_in => l_name
             ,name3_in => 'TABLE_NAME'
             ,value3_in => 'EPIS_INTERV_PLAN');
        END;
        END IF;
      WHEN e_integ_constraint_failure OR e_no_parent_key OR e_child_record_found
      THEN
        IF NOT handle_error_in THEN RAISE;
        ELSE
        DECLARE
           l_owner ALL_CONSTRAINTS.OWNER%TYPE;
           l_name ALL_CONSTRAINTS.CONSTRAINT_NAME%TYPE;
           l_id PLS_INTEGER;
           l_err_name VARCHAR2(32767) DEFAULT 'NO-PARENT-KEY-FOUND';
        BEGIN
           get_constraint_info (l_owner, l_name);
           IF SQLCODE = -2292 -- Child record found
           THEN
              l_err_name := 'CHILD-RECORD-FOUND' ;
           END IF;
           pk_alert_exceptions.register_error (
              error_name_in => l_err_name
             ,err_instance_id_out => l_id
             ,name1_in => 'OWNER', value1_in => l_owner
             ,name2_in => 'CONSTRAINT_NAME', value2_in => l_name
             ,name3_in => 'TABLE_NAME', value3_in => 'EPIS_INTERV_PLAN');
           pk_alert_exceptions.raise_error_instance (err_instance_id_in => l_id);
        END;
        END IF;
      WHEN e_null_column_value
      THEN
        IF NOT handle_error_in THEN RAISE;
        ELSE
        DECLARE
           v_errm VARCHAR2(2000) := DBMS_UTILITY.FORMAT_ERROR_STACK;
           dot1loc INTEGER;
           dot2loc INTEGER;
           parenloc INTEGER;
           c_owner ALL_CONSTRAINTS.OWNER%TYPE;
           c_tabname ALL_TABLES.TABLE_NAME%TYPE;
           c_colname ALL_TAB_COLUMNS.COLUMN_NAME%TYPE;
        BEGIN
           dot1loc := INSTR (v_errm, '.', 1, 1);
           dot2loc := INSTR (v_errm, '.', 1, 2);
           parenloc := INSTR (v_errm, '(');
           c_owner :=SUBSTR (v_errm, parenloc+1, dot1loc-parenloc-1);
           c_tabname := SUBSTR (v_errm, dot1loc+1, dot2loc-dot1loc-1);
           c_colname := SUBSTR (v_errm, dot2loc+1, INSTR (v_errm,')')-dot2loc-1);

           pk_alert_exceptions.raise_error (
                error_name_in => 'COLUMN-CANNOT-BE-NULL'
               ,name1_in => 'OWNER'
               ,value1_in => c_owner
               ,name2_in => 'TABLE_NAME'
               ,value2_in => c_tabname
               ,name3_in => 'COLUMN_NAME'
               ,value3_in => c_colname);
        END;
        END IF;
   END increment_onecol;

   PROCEDURE increment_onecol (
      colname_in IN ALL_TAB_COLUMNS.COLUMN_NAME%TYPE,
      where_in IN VARCHAR2 := NULL
     , increment_value_in IN NUMBER DEFAULT 1
     ,handle_error_in IN BOOLEAN := TRUE
   )
   IS
   rows_out table_varchar;
   BEGIN
      EXECUTE IMMEDIATE 'UPDATE EPIS_INTERV_PLAN set ' || colname_in || '=' || colname_in || ' + ' || nvl(increment_value_in,1) || ' WHERE ' || NVL (where_in, '1=1');
   EXCEPTION
      WHEN DUP_VAL_ON_INDEX
      THEN
        IF NOT handle_error_in THEN RAISE;
        ELSE
        DECLARE
           l_owner ALL_CONSTRAINTS.OWNER%TYPE;
           l_name ALL_CONSTRAINTS.CONSTRAINT_NAME%TYPE;
           l_err_instance_id PLS_INTEGER;
        BEGIN
           get_constraint_info (l_owner, l_name);
           pk_alert_exceptions.raise_error (
              error_name_in => 'DUPLICATE-VALUE'
             ,name1_in => 'OWNER'
             ,value1_in => l_owner
             ,name2_in => 'CONSTRAINT_NAME'
             ,value2_in => l_name
             ,name3_in => 'TABLE_NAME'
             ,value3_in => 'EPIS_INTERV_PLAN');
        END;
        END IF;
      WHEN e_check_constraint_failure
      THEN
        IF NOT handle_error_in THEN RAISE;
        ELSE
        DECLARE
           l_owner ALL_CONSTRAINTS.OWNER%TYPE;
           l_name ALL_CONSTRAINTS.CONSTRAINT_NAME%TYPE;
        BEGIN
           get_constraint_info (l_owner, l_name);
           pk_alert_exceptions.raise_error (
              error_name_in => 'CHECK-CONSTRAINT-FAILURE'
             ,name1_in => 'OWNER'
             ,value1_in => l_owner
             ,name2_in => 'CONSTRAINT_NAME'
             ,value2_in => l_name
             ,name3_in => 'TABLE_NAME'
             ,value3_in => 'EPIS_INTERV_PLAN');
        END;
        END IF;
      WHEN e_integ_constraint_failure OR e_no_parent_key OR e_child_record_found
      THEN
        IF NOT handle_error_in THEN RAISE;
        ELSE
        DECLARE
           l_owner ALL_CONSTRAINTS.OWNER%TYPE;
           l_name ALL_CONSTRAINTS.CONSTRAINT_NAME%TYPE;
           l_id PLS_INTEGER;
           l_err_name VARCHAR2(32767) DEFAULT 'NO-PARENT-KEY-FOUND';
        BEGIN
           get_constraint_info (l_owner, l_name);
           IF SQLCODE = -2292 -- Child record found
           THEN
              l_err_name := 'CHILD-RECORD-FOUND' ;
           END IF;
           pk_alert_exceptions.register_error (
              error_name_in => l_err_name
             ,err_instance_id_out => l_id
             ,name1_in => 'OWNER', value1_in => l_owner
             ,name2_in => 'CONSTRAINT_NAME', value2_in => l_name
             ,name3_in => 'TABLE_NAME', value3_in => 'EPIS_INTERV_PLAN');
           pk_alert_exceptions.raise_error_instance (err_instance_id_in => l_id);
        END;
        END IF;
      WHEN e_null_column_value
      THEN
        IF NOT handle_error_in THEN RAISE;
        ELSE
        DECLARE
           v_errm VARCHAR2(2000) := DBMS_UTILITY.FORMAT_ERROR_STACK;
           dot1loc INTEGER;
           dot2loc INTEGER;
           parenloc INTEGER;
           c_owner ALL_CONSTRAINTS.OWNER%TYPE;
           c_tabname ALL_TABLES.TABLE_NAME%TYPE;
           c_colname ALL_TAB_COLUMNS.COLUMN_NAME%TYPE;
        BEGIN
           dot1loc := INSTR (v_errm, '.', 1, 1);
           dot2loc := INSTR (v_errm, '.', 1, 2);
           parenloc := INSTR (v_errm, '(');
           c_owner :=SUBSTR (v_errm, parenloc+1, dot1loc-parenloc-1);
           c_tabname := SUBSTR (v_errm, dot1loc+1, dot2loc-dot1loc-1);
           c_colname := SUBSTR (v_errm, dot2loc+1, INSTR (v_errm,')')-dot2loc-1);

           pk_alert_exceptions.raise_error (
                error_name_in => 'COLUMN-CANNOT-BE-NULL'
               ,name1_in => 'OWNER'
               ,value1_in => c_owner
               ,name2_in => 'TABLE_NAME'
               ,value2_in => c_tabname
               ,name3_in => 'COLUMN_NAME'
               ,value3_in => c_colname);
        END;
        END IF;
   END increment_onecol;


   -- Delete functionality


   PROCEDURE del (
      id_epis_interv_plan_in IN EPIS_INTERV_PLAN.ID_EPIS_INTERV_PLAN%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      )
   IS
   BEGIN
      DELETE FROM EPIS_INTERV_PLAN
       WHERE
          ID_EPIS_INTERV_PLAN = id_epis_interv_plan_in
       RETURNING ROWID BULK COLLECT INTO rows_out
         ;
   EXCEPTION
      WHEN e_check_constraint_failure
      THEN
        IF NOT handle_error_in THEN RAISE;
        ELSE
        DECLARE
           l_owner ALL_CONSTRAINTS.OWNER%TYPE;
           l_name ALL_CONSTRAINTS.CONSTRAINT_NAME%TYPE;
        BEGIN
           get_constraint_info (l_owner, l_name);
           pk_alert_exceptions.raise_error (
              error_name_in => 'CHECK-CONSTRAINT-FAILURE'
             ,name1_in => 'OWNER'
             ,value1_in => l_owner
             ,name2_in => 'CONSTRAINT_NAME'
             ,value2_in => l_name
             ,name3_in => 'TABLE_NAME'
             ,value3_in => 'EPIS_INTERV_PLAN');
        END;
        END IF;
      WHEN e_integ_constraint_failure OR e_no_parent_key OR e_child_record_found
      THEN
        IF NOT handle_error_in THEN RAISE;
        ELSE
        DECLARE
           l_owner ALL_CONSTRAINTS.OWNER%TYPE;
           l_name ALL_CONSTRAINTS.CONSTRAINT_NAME%TYPE;
           l_id PLS_INTEGER;
           l_err_name VARCHAR2(32767) DEFAULT 'NO-PARENT-KEY-FOUND';
        BEGIN
           get_constraint_info (l_owner, l_name);
           IF SQLCODE = -2292 -- Child record found
           THEN
              l_err_name := 'CHILD-RECORD-FOUND' ;
           END IF;
           pk_alert_exceptions.register_error (
              error_name_in => l_err_name
             ,err_instance_id_out => l_id
             ,name1_in => 'OWNER', value1_in => l_owner
             ,name2_in => 'CONSTRAINT_NAME', value2_in => l_name
             ,name3_in => 'TABLE_NAME', value3_in => 'EPIS_INTERV_PLAN');
           pk_alert_exceptions.raise_error_instance (err_instance_id_in => l_id);
        END;
        END IF;
   END del;




   PROCEDURE del (
      id_epis_interv_plan_in IN EPIS_INTERV_PLAN.ID_EPIS_INTERV_PLAN%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
      )
   IS
rows_out TABLE_VARCHAR;
   BEGIN

del (
      id_epis_interv_plan_in => id_epis_interv_plan_in
     ,handle_error_in => handle_error_in
, rows_out => rows_out
      );

   END del;








   -- Delete all rows for primary key column ID_EPIS_INTERV_PLAN
   PROCEDURE del_ID_EPIS_INTERV_PLAN (
      id_epis_interv_plan_in IN EPIS_INTERV_PLAN.ID_EPIS_INTERV_PLAN%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
     )
   IS
   BEGIN
      DELETE FROM EPIS_INTERV_PLAN
       WHERE ID_EPIS_INTERV_PLAN = id_epis_interv_plan_in
      RETURNING ROWID BULK COLLECT INTO rows_out;
   EXCEPTION
      WHEN e_check_constraint_failure
      THEN
        IF NOT handle_error_in THEN RAISE;
        ELSE
        DECLARE
           l_owner ALL_CONSTRAINTS.OWNER%TYPE;
           l_name ALL_CONSTRAINTS.CONSTRAINT_NAME%TYPE;
        BEGIN
           get_constraint_info (l_owner, l_name);
           pk_alert_exceptions.raise_error (
              error_name_in => 'CHECK-CONSTRAINT-FAILURE'
             ,name1_in => 'OWNER'
             ,value1_in => l_owner
             ,name2_in => 'CONSTRAINT_NAME'
             ,value2_in => l_name
             ,name3_in => 'TABLE_NAME'
             ,value3_in => 'EPIS_INTERV_PLAN');
        END;
        END IF;
      WHEN e_integ_constraint_failure OR e_no_parent_key OR e_child_record_found
      THEN
        IF NOT handle_error_in THEN RAISE;
        ELSE
        DECLARE
           l_owner ALL_CONSTRAINTS.OWNER%TYPE;
           l_name ALL_CONSTRAINTS.CONSTRAINT_NAME%TYPE;
           l_id PLS_INTEGER;
           l_err_name VARCHAR2(32767) DEFAULT 'NO-PARENT-KEY-FOUND';
        BEGIN
           get_constraint_info (l_owner, l_name);
           IF SQLCODE = -2292 -- Child record found
           THEN
              l_err_name := 'CHILD-RECORD-FOUND' ;
           END IF;
           pk_alert_exceptions.register_error (
              error_name_in => l_err_name
             ,err_instance_id_out => l_id
             ,name1_in => 'OWNER', value1_in => l_owner
             ,name2_in => 'CONSTRAINT_NAME', value2_in => l_name
             ,name3_in => 'TABLE_NAME', value3_in => 'EPIS_INTERV_PLAN');
           pk_alert_exceptions.raise_error_instance (err_instance_id_in => l_id);
        END;
        END IF;
   END del_ID_EPIS_INTERV_PLAN;






   -- Delete all rows for primary key column ID_EPIS_INTERV_PLAN
   PROCEDURE del_ID_EPIS_INTERV_PLAN (
      id_epis_interv_plan_in IN EPIS_INTERV_PLAN.ID_EPIS_INTERV_PLAN%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
     )
   IS
   rows_out TABLE_VARCHAR;
   BEGIN
del_ID_EPIS_INTERV_PLAN (
      id_epis_interv_plan_in => id_epis_interv_plan_in
     ,handle_error_in => handle_error_in
, rows_out => rows_out
     );
   END del_ID_EPIS_INTERV_PLAN;















   PROCEDURE del_EIP_P_FK (
      id_professional_in IN EPIS_INTERV_PLAN.ID_PROFESSIONAL%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      )
   IS
   BEGIN
      DELETE FROM EPIS_INTERV_PLAN
       WHERE
          ID_PROFESSIONAL = del_EIP_P_FK.id_professional_in
       RETURNING ROWID BULK COLLECT INTO rows_out;
   EXCEPTION
      WHEN e_check_constraint_failure
      THEN
        IF NOT handle_error_in THEN RAISE;
        ELSE
        DECLARE
           l_owner ALL_CONSTRAINTS.OWNER%TYPE;
           l_name ALL_CONSTRAINTS.CONSTRAINT_NAME%TYPE;
        BEGIN
           get_constraint_info (l_owner, l_name);
           pk_alert_exceptions.raise_error (
              error_name_in => 'CHECK-CONSTRAINT-FAILURE'
             ,name1_in => 'OWNER'
             ,value1_in => l_owner
             ,name2_in => 'CONSTRAINT_NAME'
             ,value2_in => l_name
             ,name3_in => 'TABLE_NAME'
             ,value3_in => 'EPIS_INTERV_PLAN');
        END;
        END IF;
      WHEN e_integ_constraint_failure OR e_no_parent_key OR e_child_record_found
      THEN
        IF NOT handle_error_in THEN RAISE;
        ELSE
        DECLARE
           l_owner ALL_CONSTRAINTS.OWNER%TYPE;
           l_name ALL_CONSTRAINTS.CONSTRAINT_NAME%TYPE;
           l_id PLS_INTEGER;
           l_err_name VARCHAR2(32767) DEFAULT 'NO-PARENT-KEY-FOUND';
        BEGIN
           get_constraint_info (l_owner, l_name);
           IF SQLCODE = -2292 -- Child record found
           THEN
              l_err_name := 'CHILD-RECORD-FOUND' ;
           END IF;
           pk_alert_exceptions.register_error (
              error_name_in => l_err_name
             ,err_instance_id_out => l_id
             ,name1_in => 'OWNER', value1_in => l_owner
             ,name2_in => 'CONSTRAINT_NAME', value2_in => l_name
             ,name3_in => 'TABLE_NAME', value3_in => 'EPIS_INTERV_PLAN');
           pk_alert_exceptions.raise_error_instance (err_instance_id_in => l_id);
        END;
        END IF;
   END del_EIP_P_FK;



PROCEDURE del_EIP_P_FK (
      id_professional_in IN EPIS_INTERV_PLAN.ID_PROFESSIONAL%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
      )
   IS
   rows_out TABLE_VARCHAR;
   BEGIN
del_EIP_P_FK (
      id_professional_in => id_professional_in
     ,handle_error_in => handle_error_in
     , rows_out => rows_out
      );
   END del_EIP_P_FK;





   PROCEDURE del_EIP_TSKGD_FK (
      id_task_goal_det_in IN EPIS_INTERV_PLAN.ID_TASK_GOAL_DET%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      )
   IS
   BEGIN
      DELETE FROM EPIS_INTERV_PLAN
       WHERE
          ID_TASK_GOAL_DET = del_EIP_TSKGD_FK.id_task_goal_det_in
       RETURNING ROWID BULK COLLECT INTO rows_out;
   EXCEPTION
      WHEN e_check_constraint_failure
      THEN
        IF NOT handle_error_in THEN RAISE;
        ELSE
        DECLARE
           l_owner ALL_CONSTRAINTS.OWNER%TYPE;
           l_name ALL_CONSTRAINTS.CONSTRAINT_NAME%TYPE;
        BEGIN
           get_constraint_info (l_owner, l_name);
           pk_alert_exceptions.raise_error (
              error_name_in => 'CHECK-CONSTRAINT-FAILURE'
             ,name1_in => 'OWNER'
             ,value1_in => l_owner
             ,name2_in => 'CONSTRAINT_NAME'
             ,value2_in => l_name
             ,name3_in => 'TABLE_NAME'
             ,value3_in => 'EPIS_INTERV_PLAN');
        END;
        END IF;
      WHEN e_integ_constraint_failure OR e_no_parent_key OR e_child_record_found
      THEN
        IF NOT handle_error_in THEN RAISE;
        ELSE
        DECLARE
           l_owner ALL_CONSTRAINTS.OWNER%TYPE;
           l_name ALL_CONSTRAINTS.CONSTRAINT_NAME%TYPE;
           l_id PLS_INTEGER;
           l_err_name VARCHAR2(32767) DEFAULT 'NO-PARENT-KEY-FOUND';
        BEGIN
           get_constraint_info (l_owner, l_name);
           IF SQLCODE = -2292 -- Child record found
           THEN
              l_err_name := 'CHILD-RECORD-FOUND' ;
           END IF;
           pk_alert_exceptions.register_error (
              error_name_in => l_err_name
             ,err_instance_id_out => l_id
             ,name1_in => 'OWNER', value1_in => l_owner
             ,name2_in => 'CONSTRAINT_NAME', value2_in => l_name
             ,name3_in => 'TABLE_NAME', value3_in => 'EPIS_INTERV_PLAN');
           pk_alert_exceptions.raise_error_instance (err_instance_id_in => l_id);
        END;
        END IF;
   END del_EIP_TSKGD_FK;



PROCEDURE del_EIP_TSKGD_FK (
      id_task_goal_det_in IN EPIS_INTERV_PLAN.ID_TASK_GOAL_DET%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
      )
   IS
   rows_out TABLE_VARCHAR;
   BEGIN
del_EIP_TSKGD_FK (
      id_task_goal_det_in => id_task_goal_det_in
     ,handle_error_in => handle_error_in
     , rows_out => rows_out
      );
   END del_EIP_TSKGD_FK;












   -- Deletions using dynamic SQL
   FUNCTION dyndelstr (where_in IN VARCHAR2) RETURN VARCHAR2
   IS
   BEGIN
      IF where_in IS NULL
      THEN
         RETURN 'DELETE FROM EPIS_INTERV_PLAN';
      ELSE
         RETURN
            'DELETE FROM EPIS_INTERV_PLAN WHERE ' || where_in;
      END IF;
   END dyndelstr;

   FUNCTION dyncoldelstr (
      colname_in IN ALL_TAB_COLUMNS.COLUMN_NAME%TYPE)
      RETURN VARCHAR2
   IS
   BEGIN
      RETURN dyndelstr ( colname_in || ' = :value' );
   END;

   PROCEDURE del_by (
      where_clause_in IN VARCHAR2
     ,handle_error_in IN BOOLEAN := TRUE
      )
   IS
   BEGIN
      EXECUTE IMMEDIATE dyndelstr (where_clause_in);
   EXCEPTION
      WHEN e_check_constraint_failure
      THEN
        IF NOT handle_error_in THEN RAISE;
        ELSE
        DECLARE
           l_owner ALL_CONSTRAINTS.OWNER%TYPE;
           l_name ALL_CONSTRAINTS.CONSTRAINT_NAME%TYPE;
        BEGIN
           get_constraint_info (l_owner, l_name);
           pk_alert_exceptions.raise_error (
              error_name_in => 'CHECK-CONSTRAINT-FAILURE'
             ,name1_in => 'OWNER'
             ,value1_in => l_owner
             ,name2_in => 'CONSTRAINT_NAME'
             ,value2_in => l_name
             ,name3_in => 'TABLE_NAME'
             ,value3_in => 'EPIS_INTERV_PLAN');
        END;
        END IF;
      WHEN e_integ_constraint_failure OR e_no_parent_key OR e_child_record_found
      THEN
        IF NOT handle_error_in THEN RAISE;
        ELSE
        DECLARE
           l_owner ALL_CONSTRAINTS.OWNER%TYPE;
           l_name ALL_CONSTRAINTS.CONSTRAINT_NAME%TYPE;
           l_id PLS_INTEGER;
           l_err_name VARCHAR2(32767) DEFAULT 'NO-PARENT-KEY-FOUND';
        BEGIN
           get_constraint_info (l_owner, l_name);
           IF SQLCODE = -2292 -- Child record found
           THEN
              l_err_name := 'CHILD-RECORD-FOUND' ;
           END IF;
           pk_alert_exceptions.register_error (
              error_name_in => l_err_name
             ,err_instance_id_out => l_id
             ,name1_in => 'OWNER', value1_in => l_owner
             ,name2_in => 'CONSTRAINT_NAME', value2_in => l_name
             ,name3_in => 'TABLE_NAME', value3_in => 'EPIS_INTERV_PLAN');
           pk_alert_exceptions.raise_error_instance (err_instance_id_in => l_id);
        END;
        END IF;
   END del_by;





   PROCEDURE del_by (
      where_clause_in IN VARCHAR2
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      )
   IS
   BEGIN
      EXECUTE IMMEDIATE 'BEGIN ' || dyndelstr (where_clause_in) || ' RETURNING ROWID BULK COLLECT INTO :rows_out; END;' using OUT rows_out;
   EXCEPTION
      WHEN e_check_constraint_failure
      THEN
        IF NOT handle_error_in THEN RAISE;
        ELSE
        DECLARE
           l_owner ALL_CONSTRAINTS.OWNER%TYPE;
           l_name ALL_CONSTRAINTS.CONSTRAINT_NAME%TYPE;
        BEGIN
           get_constraint_info (l_owner, l_name);
           pk_alert_exceptions.raise_error (
              error_name_in => 'CHECK-CONSTRAINT-FAILURE'
             ,name1_in => 'OWNER'
             ,value1_in => l_owner
             ,name2_in => 'CONSTRAINT_NAME'
             ,value2_in => l_name
             ,name3_in => 'TABLE_NAME'
             ,value3_in => 'EPIS_INTERV_PLAN');
        END;
        END IF;
      WHEN e_integ_constraint_failure OR e_no_parent_key OR e_child_record_found
      THEN
        IF NOT handle_error_in THEN RAISE;
        ELSE
        DECLARE
           l_owner ALL_CONSTRAINTS.OWNER%TYPE;
           l_name ALL_CONSTRAINTS.CONSTRAINT_NAME%TYPE;
           l_id PLS_INTEGER;
           l_err_name VARCHAR2(32767) DEFAULT 'NO-PARENT-KEY-FOUND';
        BEGIN
           get_constraint_info (l_owner, l_name);
           IF SQLCODE = -2292 -- Child record found
           THEN
              l_err_name := 'CHILD-RECORD-FOUND' ;
           END IF;
           pk_alert_exceptions.register_error (
              error_name_in => l_err_name
             ,err_instance_id_out => l_id
             ,name1_in => 'OWNER', value1_in => l_owner
             ,name2_in => 'CONSTRAINT_NAME', value2_in => l_name
             ,name3_in => 'TABLE_NAME', value3_in => 'EPIS_INTERV_PLAN');
           pk_alert_exceptions.raise_error_instance (err_instance_id_in => l_id);
        END;
        END IF;
   END del_by;





   PROCEDURE del_by_col (
      colname_in IN VARCHAR2,
      colvalue_in IN VARCHAR2
     ,handle_error_in IN BOOLEAN := TRUE
   )
   IS
   BEGIN
      EXECUTE IMMEDIATE dyncoldelstr (colname_in)
         USING colvalue_in;
   EXCEPTION
      WHEN e_check_constraint_failure
      THEN
        IF NOT handle_error_in THEN RAISE;
        ELSE
        DECLARE
           l_owner ALL_CONSTRAINTS.OWNER%TYPE;
           l_name ALL_CONSTRAINTS.CONSTRAINT_NAME%TYPE;
        BEGIN
           get_constraint_info (l_owner, l_name);
           pk_alert_exceptions.raise_error (
              error_name_in => 'CHECK-CONSTRAINT-FAILURE'
             ,name1_in => 'OWNER'
             ,value1_in => l_owner
             ,name2_in => 'CONSTRAINT_NAME'
             ,value2_in => l_name
             ,name3_in => 'TABLE_NAME'
             ,value3_in => 'EPIS_INTERV_PLAN');
        END;
        END IF;
      WHEN e_integ_constraint_failure OR e_no_parent_key OR e_child_record_found
      THEN
        IF NOT handle_error_in THEN RAISE;
        ELSE
        DECLARE
           l_owner ALL_CONSTRAINTS.OWNER%TYPE;
           l_name ALL_CONSTRAINTS.CONSTRAINT_NAME%TYPE;
           l_id PLS_INTEGER;
           l_err_name VARCHAR2(32767) DEFAULT 'NO-PARENT-KEY-FOUND';
        BEGIN
           get_constraint_info (l_owner, l_name);
           IF SQLCODE = -2292 -- Child record found
           THEN
              l_err_name := 'CHILD-RECORD-FOUND' ;
           END IF;
           pk_alert_exceptions.register_error (
              error_name_in => l_err_name
             ,err_instance_id_out => l_id
             ,name1_in => 'OWNER', value1_in => l_owner
             ,name2_in => 'CONSTRAINT_NAME', value2_in => l_name
             ,name3_in => 'TABLE_NAME', value3_in => 'EPIS_INTERV_PLAN');
           pk_alert_exceptions.raise_error_instance (err_instance_id_in => l_id);
        END;
        END IF;
   END del_by_col;






   PROCEDURE del_by_col (
      colname_in IN VARCHAR2,
      colvalue_in IN VARCHAR2
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
   )
   IS
   BEGIN
      EXECUTE IMMEDIATE 'BEGIN ' || dyncoldelstr (colname_in) || ' RETURNING ROWID BULK COLLECT INTO :rows_out; END;'
         USING IN colvalue_in, OUT rows_out;
   EXCEPTION
      WHEN e_check_constraint_failure
      THEN
        IF NOT handle_error_in THEN RAISE;
        ELSE
        DECLARE
           l_owner ALL_CONSTRAINTS.OWNER%TYPE;
           l_name ALL_CONSTRAINTS.CONSTRAINT_NAME%TYPE;
        BEGIN
           get_constraint_info (l_owner, l_name);
           pk_alert_exceptions.raise_error (
              error_name_in => 'CHECK-CONSTRAINT-FAILURE'
             ,name1_in => 'OWNER'
             ,value1_in => l_owner
             ,name2_in => 'CONSTRAINT_NAME'
             ,value2_in => l_name
             ,name3_in => 'TABLE_NAME'
             ,value3_in => 'EPIS_INTERV_PLAN');
        END;
        END IF;
      WHEN e_integ_constraint_failure OR e_no_parent_key OR e_child_record_found
      THEN
        IF NOT handle_error_in THEN RAISE;
        ELSE
        DECLARE
           l_owner ALL_CONSTRAINTS.OWNER%TYPE;
           l_name ALL_CONSTRAINTS.CONSTRAINT_NAME%TYPE;
           l_id PLS_INTEGER;
           l_err_name VARCHAR2(32767) DEFAULT 'NO-PARENT-KEY-FOUND';
        BEGIN
           get_constraint_info (l_owner, l_name);
           IF SQLCODE = -2292 -- Child record found
           THEN
              l_err_name := 'CHILD-RECORD-FOUND' ;
           END IF;
           pk_alert_exceptions.register_error (
              error_name_in => l_err_name
             ,err_instance_id_out => l_id
             ,name1_in => 'OWNER', value1_in => l_owner
             ,name2_in => 'CONSTRAINT_NAME', value2_in => l_name
             ,name3_in => 'TABLE_NAME', value3_in => 'EPIS_INTERV_PLAN');
           pk_alert_exceptions.raise_error_instance (err_instance_id_in => l_id);
        END;
        END IF;
   END del_by_col;







   PROCEDURE del_by_col (
      colname_in IN VARCHAR2,
      colvalue_in IN DATE
     ,handle_error_in IN BOOLEAN := TRUE
      )
   IS
   BEGIN
      EXECUTE IMMEDIATE dyncoldelstr (colname_in)
         USING colvalue_in;
   EXCEPTION
      WHEN e_check_constraint_failure
      THEN
        IF NOT handle_error_in THEN RAISE;
        ELSE
        DECLARE
           l_owner ALL_CONSTRAINTS.OWNER%TYPE;
           l_name ALL_CONSTRAINTS.CONSTRAINT_NAME%TYPE;
        BEGIN
           get_constraint_info (l_owner, l_name);
           pk_alert_exceptions.raise_error (
              error_name_in => 'CHECK-CONSTRAINT-FAILURE'
             ,name1_in => 'OWNER'
             ,value1_in => l_owner
             ,name2_in => 'CONSTRAINT_NAME'
             ,value2_in => l_name
             ,name3_in => 'TABLE_NAME'
             ,value3_in => 'EPIS_INTERV_PLAN');
        END;
        END IF;
      WHEN e_integ_constraint_failure OR e_no_parent_key OR e_child_record_found
      THEN
        IF NOT handle_error_in THEN RAISE;
        ELSE
        DECLARE
           l_owner ALL_CONSTRAINTS.OWNER%TYPE;
           l_name ALL_CONSTRAINTS.CONSTRAINT_NAME%TYPE;
           l_id PLS_INTEGER;
           l_err_name VARCHAR2(32767) DEFAULT 'NO-PARENT-KEY-FOUND';
        BEGIN
           get_constraint_info (l_owner, l_name);
           IF SQLCODE = -2292 -- Child record found
           THEN
              l_err_name := 'CHILD-RECORD-FOUND' ;
           END IF;
           pk_alert_exceptions.register_error (
              error_name_in => l_err_name
             ,err_instance_id_out => l_id
             ,name1_in => 'OWNER', value1_in => l_owner
             ,name2_in => 'CONSTRAINT_NAME', value2_in => l_name
             ,name3_in => 'TABLE_NAME', value3_in => 'EPIS_INTERV_PLAN');
           pk_alert_exceptions.raise_error_instance (err_instance_id_in => l_id);
        END;
        END IF;
   END del_by_col;







   PROCEDURE del_by_col (
      colname_in IN VARCHAR2,
      colvalue_in IN DATE
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      )
   IS
   BEGIN
      EXECUTE IMMEDIATE 'BEGIN ' || dyncoldelstr (colname_in) || ' RETURNING ROWID BULK COLLECT INTO :rows_out; END;'
         USING IN colvalue_in, OUT rows_out;
   EXCEPTION
      WHEN e_check_constraint_failure
      THEN
        IF NOT handle_error_in THEN RAISE;
        ELSE
        DECLARE
           l_owner ALL_CONSTRAINTS.OWNER%TYPE;
           l_name ALL_CONSTRAINTS.CONSTRAINT_NAME%TYPE;
        BEGIN
           get_constraint_info (l_owner, l_name);
           pk_alert_exceptions.raise_error (
              error_name_in => 'CHECK-CONSTRAINT-FAILURE'
             ,name1_in => 'OWNER'
             ,value1_in => l_owner
             ,name2_in => 'CONSTRAINT_NAME'
             ,value2_in => l_name
             ,name3_in => 'TABLE_NAME'
             ,value3_in => 'EPIS_INTERV_PLAN');
        END;
        END IF;
      WHEN e_integ_constraint_failure OR e_no_parent_key OR e_child_record_found
      THEN
        IF NOT handle_error_in THEN RAISE;
        ELSE
        DECLARE
           l_owner ALL_CONSTRAINTS.OWNER%TYPE;
           l_name ALL_CONSTRAINTS.CONSTRAINT_NAME%TYPE;
           l_id PLS_INTEGER;
           l_err_name VARCHAR2(32767) DEFAULT 'NO-PARENT-KEY-FOUND';
        BEGIN
           get_constraint_info (l_owner, l_name);
           IF SQLCODE = -2292 -- Child record found
           THEN
              l_err_name := 'CHILD-RECORD-FOUND' ;
           END IF;
           pk_alert_exceptions.register_error (
              error_name_in => l_err_name
             ,err_instance_id_out => l_id
             ,name1_in => 'OWNER', value1_in => l_owner
             ,name2_in => 'CONSTRAINT_NAME', value2_in => l_name
             ,name3_in => 'TABLE_NAME', value3_in => 'EPIS_INTERV_PLAN');
           pk_alert_exceptions.raise_error_instance (err_instance_id_in => l_id);
        END;
        END IF;
   END del_by_col;







   PROCEDURE del_by_col (
      colname_in IN VARCHAR2,
      colvalue_in IN TIMESTAMP WITH LOCAL TIME ZONE
     ,handle_error_in IN BOOLEAN := TRUE
      )
   IS
   BEGIN
      EXECUTE IMMEDIATE dyncoldelstr (colname_in)
         USING colvalue_in;
   EXCEPTION
      WHEN e_check_constraint_failure
      THEN
        IF NOT handle_error_in THEN RAISE;
        ELSE
        DECLARE
           l_owner ALL_CONSTRAINTS.OWNER%TYPE;
           l_name ALL_CONSTRAINTS.CONSTRAINT_NAME%TYPE;
        BEGIN
           get_constraint_info (l_owner, l_name);
           pk_alert_exceptions.raise_error (
              error_name_in => 'CHECK-CONSTRAINT-FAILURE'
             ,name1_in => 'OWNER'
             ,value1_in => l_owner
             ,name2_in => 'CONSTRAINT_NAME'
             ,value2_in => l_name
             ,name3_in => 'TABLE_NAME'
             ,value3_in => 'EPIS_INTERV_PLAN');
        END;
        END IF;
      WHEN e_integ_constraint_failure OR e_no_parent_key OR e_child_record_found
      THEN
        IF NOT handle_error_in THEN RAISE;
        ELSE
        DECLARE
           l_owner ALL_CONSTRAINTS.OWNER%TYPE;
           l_name ALL_CONSTRAINTS.CONSTRAINT_NAME%TYPE;
           l_id PLS_INTEGER;
           l_err_name VARCHAR2(32767) DEFAULT 'NO-PARENT-KEY-FOUND';
        BEGIN
           get_constraint_info (l_owner, l_name);
           IF SQLCODE = -2292 -- Child record found
           THEN
              l_err_name := 'CHILD-RECORD-FOUND' ;
           END IF;
           pk_alert_exceptions.register_error (
              error_name_in => l_err_name
             ,err_instance_id_out => l_id
             ,name1_in => 'OWNER', value1_in => l_owner
             ,name2_in => 'CONSTRAINT_NAME', value2_in => l_name
             ,name3_in => 'TABLE_NAME', value3_in => 'EPIS_INTERV_PLAN');
           pk_alert_exceptions.raise_error_instance (err_instance_id_in => l_id);
        END;
        END IF;
   END del_by_col;







   PROCEDURE del_by_col (
      colname_in IN VARCHAR2,
      colvalue_in IN TIMESTAMP WITH LOCAL TIME ZONE
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      )
   IS
   BEGIN
      EXECUTE IMMEDIATE 'BEGIN ' || dyncoldelstr (colname_in) || ' RETURNING ROWID BULK COLLECT INTO :rows_out; END;'
         USING IN colvalue_in, OUT rows_out;
   EXCEPTION
      WHEN e_check_constraint_failure
      THEN
        IF NOT handle_error_in THEN RAISE;
        ELSE
        DECLARE
           l_owner ALL_CONSTRAINTS.OWNER%TYPE;
           l_name ALL_CONSTRAINTS.CONSTRAINT_NAME%TYPE;
        BEGIN
           get_constraint_info (l_owner, l_name);
           pk_alert_exceptions.raise_error (
              error_name_in => 'CHECK-CONSTRAINT-FAILURE'
             ,name1_in => 'OWNER'
             ,value1_in => l_owner
             ,name2_in => 'CONSTRAINT_NAME'
             ,value2_in => l_name
             ,name3_in => 'TABLE_NAME'
             ,value3_in => 'EPIS_INTERV_PLAN');
        END;
        END IF;
      WHEN e_integ_constraint_failure OR e_no_parent_key OR e_child_record_found
      THEN
        IF NOT handle_error_in THEN RAISE;
        ELSE
        DECLARE
           l_owner ALL_CONSTRAINTS.OWNER%TYPE;
           l_name ALL_CONSTRAINTS.CONSTRAINT_NAME%TYPE;
           l_id PLS_INTEGER;
           l_err_name VARCHAR2(32767) DEFAULT 'NO-PARENT-KEY-FOUND';
        BEGIN
           get_constraint_info (l_owner, l_name);
           IF SQLCODE = -2292 -- Child record found
           THEN
              l_err_name := 'CHILD-RECORD-FOUND' ;
           END IF;
           pk_alert_exceptions.register_error (
              error_name_in => l_err_name
             ,err_instance_id_out => l_id
             ,name1_in => 'OWNER', value1_in => l_owner
             ,name2_in => 'CONSTRAINT_NAME', value2_in => l_name
             ,name3_in => 'TABLE_NAME', value3_in => 'EPIS_INTERV_PLAN');
           pk_alert_exceptions.raise_error_instance (err_instance_id_in => l_id);
        END;
        END IF;
   END del_by_col;







   PROCEDURE del_by_col (
      colname_in IN VARCHAR2,
      colvalue_in IN NUMBER
     ,handle_error_in IN BOOLEAN := TRUE
   )
   IS
   BEGIN
      EXECUTE IMMEDIATE dyncoldelstr (colname_in)
         USING colvalue_in;
   EXCEPTION
      WHEN e_check_constraint_failure
      THEN
        IF NOT handle_error_in THEN RAISE;
        ELSE
        DECLARE
           l_owner ALL_CONSTRAINTS.OWNER%TYPE;
           l_name ALL_CONSTRAINTS.CONSTRAINT_NAME%TYPE;
        BEGIN
           get_constraint_info (l_owner, l_name);
           pk_alert_exceptions.raise_error (
              error_name_in => 'CHECK-CONSTRAINT-FAILURE'
             ,name1_in => 'OWNER'
             ,value1_in => l_owner
             ,name2_in => 'CONSTRAINT_NAME'
             ,value2_in => l_name
             ,name3_in => 'TABLE_NAME'
             ,value3_in => 'EPIS_INTERV_PLAN');
        END;
        END IF;
      WHEN e_integ_constraint_failure OR e_no_parent_key OR e_child_record_found
      THEN
        IF NOT handle_error_in THEN RAISE;
        ELSE
        DECLARE
           l_owner ALL_CONSTRAINTS.OWNER%TYPE;
           l_name ALL_CONSTRAINTS.CONSTRAINT_NAME%TYPE;
           l_id PLS_INTEGER;
           l_err_name VARCHAR2(32767) DEFAULT 'NO-PARENT-KEY-FOUND';
        BEGIN
           get_constraint_info (l_owner, l_name);
           IF SQLCODE = -2292 -- Child record found
           THEN
              l_err_name := 'CHILD-RECORD-FOUND' ;
           END IF;
           pk_alert_exceptions.register_error (
              error_name_in => l_err_name
             ,err_instance_id_out => l_id
             ,name1_in => 'OWNER', value1_in => l_owner
             ,name2_in => 'CONSTRAINT_NAME', value2_in => l_name
             ,name3_in => 'TABLE_NAME', value3_in => 'EPIS_INTERV_PLAN');
           pk_alert_exceptions.raise_error_instance (err_instance_id_in => l_id);
        END;
        END IF;
   END del_by_col;






   PROCEDURE del_by_col (
      colname_in IN VARCHAR2,
      colvalue_in IN NUMBER
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
   )
   IS
   BEGIN
     EXECUTE IMMEDIATE 'BEGIN ' || dyncoldelstr (colname_in) || ' RETURNING ROWID BULK COLLECT INTO :rows_out; END;'
         USING IN colvalue_in, OUT rows_out;
   EXCEPTION
      WHEN e_check_constraint_failure
      THEN
        IF NOT handle_error_in THEN RAISE;
        ELSE
        DECLARE
           l_owner ALL_CONSTRAINTS.OWNER%TYPE;
           l_name ALL_CONSTRAINTS.CONSTRAINT_NAME%TYPE;
        BEGIN
           get_constraint_info (l_owner, l_name);
           pk_alert_exceptions.raise_error (
              error_name_in => 'CHECK-CONSTRAINT-FAILURE'
             ,name1_in => 'OWNER'
             ,value1_in => l_owner
             ,name2_in => 'CONSTRAINT_NAME'
             ,value2_in => l_name
             ,name3_in => 'TABLE_NAME'
             ,value3_in => 'EPIS_INTERV_PLAN');
        END;
        END IF;
      WHEN e_integ_constraint_failure OR e_no_parent_key OR e_child_record_found
      THEN
        IF NOT handle_error_in THEN RAISE;
        ELSE
        DECLARE
           l_owner ALL_CONSTRAINTS.OWNER%TYPE;
           l_name ALL_CONSTRAINTS.CONSTRAINT_NAME%TYPE;
           l_id PLS_INTEGER;
           l_err_name VARCHAR2(32767) DEFAULT 'NO-PARENT-KEY-FOUND';
        BEGIN
           get_constraint_info (l_owner, l_name);
           IF SQLCODE = -2292 -- Child record found
           THEN
              l_err_name := 'CHILD-RECORD-FOUND' ;
           END IF;
           pk_alert_exceptions.register_error (
              error_name_in => l_err_name
             ,err_instance_id_out => l_id
             ,name1_in => 'OWNER', value1_in => l_owner
             ,name2_in => 'CONSTRAINT_NAME', value2_in => l_name
             ,name3_in => 'TABLE_NAME', value3_in => 'EPIS_INTERV_PLAN');
           pk_alert_exceptions.raise_error_instance (err_instance_id_in => l_id);
        END;
        END IF;
   END del_by_col;







   -- Initialize a record with default values for columns in the table.
   PROCEDURE initrec (
      epis_interv_plan_inout IN OUT EPIS_INTERV_PLAN%ROWTYPE
   )
   IS
   BEGIN
      epis_interv_plan_inout.ID_EPIS_INTERV_PLAN := NULL;
      epis_interv_plan_inout.ID_INTERV_PLAN := NULL;
      epis_interv_plan_inout.ID_EPISODE := NULL;
      epis_interv_plan_inout.ID_PROFESSIONAL := NULL;
      epis_interv_plan_inout.FLG_STATUS := NULL;
      epis_interv_plan_inout.NOTES := NULL;
      epis_interv_plan_inout.DT_CREATION := NULL;
      epis_interv_plan_inout.DT_BEGIN := NULL;
      epis_interv_plan_inout.DT_END := NULL;
      epis_interv_plan_inout.ID_CANCEL_INFO_DET := NULL;
      epis_interv_plan_inout.FLG_AVAILABLE := 'Y';
      epis_interv_plan_inout.DESC_OTHER_INTERV_PLAN := NULL;
      epis_interv_plan_inout.CREATE_USER := NULL;
      epis_interv_plan_inout.CREATE_TIME := NULL;
      epis_interv_plan_inout.CREATE_INSTITUTION := NULL;
      epis_interv_plan_inout.UPDATE_USER := NULL;
      epis_interv_plan_inout.UPDATE_TIME := NULL;
      epis_interv_plan_inout.UPDATE_INSTITUTION := NULL;
      epis_interv_plan_inout.ID_TASK_GOAL_DET := NULL;
   END initrec;

   FUNCTION initrec RETURN EPIS_INTERV_PLAN%ROWTYPE
   IS
      l_epis_interv_plan EPIS_INTERV_PLAN%ROWTYPE;
   BEGIN
      l_epis_interv_plan.FLG_AVAILABLE := 'Y';
      RETURN l_epis_interv_plan;
   END initrec;


   FUNCTION get_data_rowid(
        rows_in IN TABLE_VARCHAR
        ) RETURN EPIS_INTERV_PLAN_tc
   IS
        data EPIS_INTERV_PLAN_tc;
   BEGIN
        select * bulk collect into data from EPIS_INTERV_PLAN where rowid in (select * from table(rows_in));
        return data;
        EXCEPTION
      WHEN OTHERS THEN
        pk_alert_exceptions.raise_error (
           error_name_in => 'get_data_rowid'
           );
   END get_data_rowid;


   FUNCTION get_data_rowid_pat(
        rows_in IN TABLE_VARCHAR
        ) RETURN EPIS_INTERV_PLAN_tc
   is
        PRAGMA AUTONOMOUS_TRANSACTION;
        data EPIS_INTERV_PLAN_tc;
   BEGIN
        data := get_data_rowid(rows_in);
        commit;
        return data;
        EXCEPTION
      WHEN OTHERS THEN
        pk_alert_exceptions.raise_error (
           error_name_in => 'get_data_rowid'
           );
        rollback;
    END get_data_rowid_pat;

BEGIN
    -- Initialization
 
    /* CAN'T TOUCH THIS */
    /* Who am I */
    alertlog.pk_alertlog.who_am_i(owner => g_owner, name => g_package);
    /* Log init */
    alertlog.pk_alertlog.log_init(object_name => g_package);
END ts_epis_interv_plan;
/
