
-- CHANGED BY:  Elisabete Bugalho
-- CHANGE DATE: 22/04/2015 16:24
-- CHANGE REASON:     ALERT-310274 03 - Packages, Types & Views Versioning

BEGIN

    pk_versioning.run(i_sql => q'[CREATE OR REPLACE TYPE t_rec_co_sign force AS OBJECT
                        (
                            id_co_sign            NUMBER(24),
                            id_co_sign_hist       NUMBER(24),
                            id_episode            NUMBER(24),
                            id_task               NUMBER(24),
                            id_task_group         NUMBER(24),
                            id_task_type          NUMBER(24),
                            desc_task_type        VARCHAR2(1000 CHAR),
                            icon_task_type        VARCHAR2(200 CHAR),
                            id_action             NUMBER(24),
                            desc_action           VARCHAR2(1000 CHAR),
                            id_task_type_action   NUMBER(24),
                            desc_order            VARCHAR2(4000 CHAR),
                            desc_instructions     VARCHAR2(1000 CHAR),
                            desc_task_action      VARCHAR2(1000 CHAR),
                            id_order_type         NUMBER(12),
                            desc_order_type       VARCHAR2(4000 CHAR),
                            id_prof_created       NUMBER(24),
                            id_prof_ordered_by    NUMBER(24),
                            desc_prof_ordered_by  VARCHAR2(1000 CHAR),
                            id_prof_co_signed     NUMBER(24),
                            dt_created            TIMESTAMP(6) WITH LOCAL TIME ZONE,
                            dt_ordered_by         TIMESTAMP(6) WITH LOCAL TIME ZONE,
                            dt_co_signed          TIMESTAMP(6) WITH LOCAL TIME ZONE,
                            flg_status            VARCHAR2(2 CHAR),
                            icon_status           VARCHAR2(200 CHAR),
                            desc_status           VARCHAR2(800),
                            code_co_sign_notes    VARCHAR2(200 CHAR),
                            co_sign_notes         CLOB,
                            flg_has_notes         VARCHAR2(1 CHAR),
                            flg_needs_cosign      VARCHAR2(1 CHAR),
                            flg_has_cosign       VARCHAR2(1 CHAR),

    CONSTRUCTOR FUNCTION t_rec_co_sign RETURN SELF AS RESULT  )
 ]');
 
    pk_versioning.run(i_sql => q'[CREATE OR REPLACE TYPE BODY t_rec_co_sign IS
    CONSTRUCTOR FUNCTION t_rec_co_sign RETURN SELF AS RESULT IS
    BEGIN

        self.id_co_sign_hist     := NULL;
        self.id_co_sign          := NULL;
        self.id_episode          := NULL;
        self.id_task             := NULL;
        self.id_task_group       := NULL;
        self.id_task_type        := NULL;
        self.desc_task_type      := NULL;
        self.icon_task_type      := NULL;
        self.id_action           := NULL;
        self.desc_action         := NULL;
        self.id_task_type_action := NULL;
        self.desc_order          := NULL;
        self.desc_instructions   := NULL;
        self.desc_task_action    := NULL;
        self.id_order_type       := NULL;
        self.desc_order_type     := NULL;
        self.id_prof_created     := NULL;
        self.id_prof_ordered_by  := NULL;
        self.desc_prof_ordered_by :=NULL;
        self.id_prof_co_signed   := NULL;
        self.dt_created          := NULL;
        self.dt_ordered_by       := NULL;
        self.dt_co_signed        := NULL;
        self.flg_status          := NULL;
        self.icon_status         := NULL;
        self.desc_status         := NULL;
        self.code_co_sign_notes  := NULL;
        self.co_sign_notes       := empty_clob();
        self.flg_has_notes       := NULL;
        self.flg_needs_cosign    := NULL;
        self.flg_has_cosign      := NULL;

        RETURN;
    END;
 END;
 ]');

END;
/
-- CHANGE END: Gisela Couto


-- CHANGED BY:  Nuno Alves
-- CHANGE DATE: 28/04/2015 15:15
-- CHANGE REASON: ALERT-310274 03 - Packages, Types & Views Versioning
BEGIN
    pk_versioning.run(i_sql => q'[CREATE OR REPLACE TYPE t_rec_co_sign force AS OBJECT
                        (
                            id_co_sign            NUMBER(24),
                            id_co_sign_hist       NUMBER(24),
                            id_episode            NUMBER(24),
                            id_task               NUMBER(24),
                            id_task_group         NUMBER(24),
                            id_task_type          NUMBER(24),
                            desc_task_type        VARCHAR2(1000 CHAR),
                            icon_task_type        VARCHAR2(200 CHAR),
                            id_action             NUMBER(24),
                            desc_action           VARCHAR2(1000 CHAR),
                            id_task_type_action   NUMBER(24),
                            desc_order            VARCHAR2(4000 CHAR),
                            desc_instructions     VARCHAR2(1000 CHAR),
                            desc_task_action      VARCHAR2(1000 CHAR),
                            id_order_type         NUMBER(12),
                            desc_order_type       VARCHAR2(4000 CHAR),
                            id_prof_created       NUMBER(24),
                            id_prof_ordered_by    NUMBER(24),
                            desc_prof_ordered_by  VARCHAR2(1000 CHAR),
                            id_prof_co_signed     NUMBER(24),
                            dt_req                TIMESTAMP(6) WITH LOCAL TIME ZONE,
                            dt_created            TIMESTAMP(6) WITH LOCAL TIME ZONE,
                            dt_ordered_by         TIMESTAMP(6) WITH LOCAL TIME ZONE,
                            dt_co_signed          TIMESTAMP(6) WITH LOCAL TIME ZONE,
                            flg_status            VARCHAR2(2 CHAR),
                            icon_status           VARCHAR2(200 CHAR),
                            desc_status           VARCHAR2(800),
                            code_co_sign_notes    VARCHAR2(200 CHAR),
                            co_sign_notes         CLOB,
                            flg_has_notes         VARCHAR2(1 CHAR),
                            flg_needs_cosign      VARCHAR2(1 CHAR),
                            flg_has_cosign       VARCHAR2(1 CHAR),

    CONSTRUCTOR FUNCTION t_rec_co_sign RETURN SELF AS RESULT  )
 ]');
 
    pk_versioning.run(i_sql => q'[CREATE OR REPLACE TYPE BODY t_rec_co_sign IS
    CONSTRUCTOR FUNCTION t_rec_co_sign RETURN SELF AS RESULT IS
    BEGIN

        self.id_co_sign_hist     := NULL;
        self.id_co_sign          := NULL;
        self.id_episode          := NULL;
        self.id_task             := NULL;
        self.id_task_group       := NULL;
        self.id_task_type        := NULL;
        self.desc_task_type      := NULL;
        self.icon_task_type      := NULL;
        self.id_action           := NULL;
        self.desc_action         := NULL;
        self.id_task_type_action := NULL;
        self.desc_order          := NULL;
        self.desc_instructions   := NULL;
        self.desc_task_action    := NULL;
        self.id_order_type       := NULL;
        self.desc_order_type     := NULL;
        self.id_prof_created     := NULL;
        self.id_prof_ordered_by  := NULL;
        self.desc_prof_ordered_by :=NULL;
        self.id_prof_co_signed   := NULL;
        self.dt_req              := NULL;
        self.dt_created          := NULL;
        self.dt_ordered_by       := NULL;
        self.dt_co_signed        := NULL;
        self.flg_status          := NULL;
        self.icon_status         := NULL;
        self.desc_status         := NULL;
        self.code_co_sign_notes  := NULL;
        self.co_sign_notes       := empty_clob();
        self.flg_has_notes       := NULL;
        self.flg_needs_cosign    := NULL;
        self.flg_has_cosign      := NULL;

        RETURN;
    END;
 END;
 ]');
END;
/
-- CHANGE END: Nuno Alves

-- CHANGED BY:  Nuno Alves
-- CHANGE DATE: 15/10/2015 16:00
-- CHANGE REASON: ALERT-311010 - [EXAMS] Discharge button - Co-sign - Co-sign requests originated from recurrent imaging/other exams are not sorted properly when accessing the co-sign area
BEGIN
    pk_versioning.run(i_sql => q'[CREATE OR REPLACE TYPE t_rec_co_sign force AS OBJECT
                        (
                            id_co_sign            NUMBER(24),
                            id_co_sign_hist       NUMBER(24),
                            id_episode            NUMBER(24),
                            id_task               NUMBER(24),
                            id_task_group         NUMBER(24),
                            id_task_type          NUMBER(24),
                            desc_task_type        VARCHAR2(1000 CHAR),
                            icon_task_type        VARCHAR2(200 CHAR),
                            id_action             NUMBER(24),
                            desc_action           VARCHAR2(1000 CHAR),
                            id_task_type_action   NUMBER(24),
                            desc_order            VARCHAR2(4000 CHAR),
                            desc_instructions     VARCHAR2(1000 CHAR),
                            desc_task_action      VARCHAR2(1000 CHAR),
                            id_order_type         NUMBER(12),
                            desc_order_type       VARCHAR2(4000 CHAR),
                            id_prof_created       NUMBER(24),
                            id_prof_ordered_by    NUMBER(24),
                            desc_prof_ordered_by  VARCHAR2(1000 CHAR),
                            id_prof_co_signed     NUMBER(24),
                            dt_req                TIMESTAMP(6) WITH LOCAL TIME ZONE,
                            dt_created            TIMESTAMP(6) WITH LOCAL TIME ZONE,
                            dt_ordered_by         TIMESTAMP(6) WITH LOCAL TIME ZONE,
                            dt_co_signed          TIMESTAMP(6) WITH LOCAL TIME ZONE,
                            dt_exec_date_sort     TIMESTAMP(6) WITH LOCAL TIME ZONE,
                            flg_status            VARCHAR2(2 CHAR),
                            icon_status           VARCHAR2(200 CHAR),
                            desc_status           VARCHAR2(800),
                            code_co_sign_notes    VARCHAR2(200 CHAR),
                            co_sign_notes         CLOB,
                            flg_has_notes         VARCHAR2(1 CHAR),
                            flg_needs_cosign      VARCHAR2(1 CHAR),
                            flg_has_cosign       VARCHAR2(1 CHAR),

    CONSTRUCTOR FUNCTION t_rec_co_sign RETURN SELF AS RESULT  )
 ]');
 
    pk_versioning.run(i_sql => q'[CREATE OR REPLACE TYPE BODY t_rec_co_sign IS
    CONSTRUCTOR FUNCTION t_rec_co_sign RETURN SELF AS RESULT IS
    BEGIN

        self.id_co_sign_hist     := NULL;
        self.id_co_sign          := NULL;
        self.id_episode          := NULL;
        self.id_task             := NULL;
        self.id_task_group       := NULL;
        self.id_task_type        := NULL;
        self.desc_task_type      := NULL;
        self.icon_task_type      := NULL;
        self.id_action           := NULL;
        self.desc_action         := NULL;
        self.id_task_type_action := NULL;
        self.desc_order          := NULL;
        self.desc_instructions   := NULL;
        self.desc_task_action    := NULL;
        self.id_order_type       := NULL;
        self.desc_order_type     := NULL;
        self.id_prof_created     := NULL;
        self.id_prof_ordered_by  := NULL;
        self.desc_prof_ordered_by :=NULL;
        self.id_prof_co_signed   := NULL;
        self.dt_req              := NULL;
        self.dt_created          := NULL;
        self.dt_ordered_by       := NULL;
        self.dt_co_signed        := NULL;
        self.dt_exec_date_sort   := NULL;
        self.flg_status          := NULL;
        self.icon_status         := NULL;
        self.desc_status         := NULL;
        self.code_co_sign_notes  := NULL;
        self.co_sign_notes       := empty_clob();
        self.flg_has_notes       := NULL;
        self.flg_needs_cosign    := NULL;
        self.flg_has_cosign      := NULL;

        RETURN;
    END;
 END;
 ]');
END;
/
-- CHANGE END: Nuno Alves

-- CHANGED BY:  Elisabete Bugalho
-- CHANGE DATE: 29/01/2016 14:40
-- CHANGE REASON: ALERT-312482 Electronically co-sign is not being shown on detail

BEGIN
    pk_versioning.run(i_sql => q'[CREATE OR REPLACE TYPE t_rec_co_sign force AS OBJECT
                        (
                            id_co_sign            NUMBER(24),
                            id_co_sign_hist       NUMBER(24),
                            id_episode            NUMBER(24),
                            id_task               NUMBER(24),
                            id_task_group         NUMBER(24),
                            id_task_type          NUMBER(24),
                            desc_task_type        VARCHAR2(1000 CHAR),
                            icon_task_type        VARCHAR2(200 CHAR),
                            id_action             NUMBER(24),
                            desc_action           VARCHAR2(1000 CHAR),
                            id_task_type_action   NUMBER(24),
                            desc_order            VARCHAR2(4000 CHAR),
                            desc_instructions     VARCHAR2(1000 CHAR),
                            desc_task_action      VARCHAR2(1000 CHAR),
                            id_order_type         NUMBER(12),
                            desc_order_type       VARCHAR2(4000 CHAR),
                            id_prof_created       NUMBER(24),
                            id_prof_ordered_by    NUMBER(24),
                            desc_prof_ordered_by  VARCHAR2(1000 CHAR),
                            id_prof_co_signed     NUMBER(24),
                            dt_req                TIMESTAMP(6) WITH LOCAL TIME ZONE,
                            dt_created            TIMESTAMP(6) WITH LOCAL TIME ZONE,
                            dt_ordered_by         TIMESTAMP(6) WITH LOCAL TIME ZONE,
                            dt_co_signed          TIMESTAMP(6) WITH LOCAL TIME ZONE,
                            dt_exec_date_sort     TIMESTAMP(6) WITH LOCAL TIME ZONE,
                            flg_status            VARCHAR2(2 CHAR),
                            icon_status           VARCHAR2(200 CHAR),
                            desc_status           VARCHAR2(800),
                            code_co_sign_notes    VARCHAR2(200 CHAR),
                            co_sign_notes         CLOB,
                            flg_has_notes         VARCHAR2(1 CHAR),
                            flg_needs_cosign      VARCHAR2(1 CHAR),
                            flg_has_cosign       VARCHAR2(1 CHAR),
                            flg_made_auth        VARCHAR2(1 CHAR),

    CONSTRUCTOR FUNCTION t_rec_co_sign RETURN SELF AS RESULT  )
 ]');
 
    pk_versioning.run(i_sql => q'[CREATE OR REPLACE TYPE BODY t_rec_co_sign IS
    CONSTRUCTOR FUNCTION t_rec_co_sign RETURN SELF AS RESULT IS
    BEGIN

        self.id_co_sign_hist     := NULL;
        self.id_co_sign          := NULL;
        self.id_episode          := NULL;
        self.id_task             := NULL;
        self.id_task_group       := NULL;
        self.id_task_type        := NULL;
        self.desc_task_type      := NULL;
        self.icon_task_type      := NULL;
        self.id_action           := NULL;
        self.desc_action         := NULL;
        self.id_task_type_action := NULL;
        self.desc_order          := NULL;
        self.desc_instructions   := NULL;
        self.desc_task_action    := NULL;
        self.id_order_type       := NULL;
        self.desc_order_type     := NULL;
        self.id_prof_created     := NULL;
        self.id_prof_ordered_by  := NULL;
        self.desc_prof_ordered_by :=NULL;
        self.id_prof_co_signed   := NULL;
        self.dt_req              := NULL;
        self.dt_created          := NULL;
        self.dt_ordered_by       := NULL;
        self.dt_co_signed        := NULL;
        self.dt_exec_date_sort   := NULL;
        self.flg_status          := NULL;
        self.icon_status         := NULL;
        self.desc_status         := NULL;
        self.code_co_sign_notes  := NULL;
        self.co_sign_notes       := empty_clob();
        self.flg_has_notes       := NULL;
        self.flg_needs_cosign    := NULL;
        self.flg_has_cosign      := NULL;
        self.flg_made_auth       := NULL;
        RETURN;
    END;
 END;
 ]');
END;
/

-- CHANGE END: Elisabete Bugalho

-- cmf
-- cmf
BEGIN
    pk_versioning.run(i_sql => q'[CREATE OR REPLACE TYPE t_rec_co_sign force AS OBJECT
                        (
                            id_co_sign            NUMBER(24),
                            id_co_sign_hist       NUMBER(24),
                            id_episode            NUMBER(24),
                            id_task               NUMBER(24),
                            id_task_group         NUMBER(24),
                            id_task_type          NUMBER(24),
                            desc_task_type        VARCHAR2(1000 CHAR),
                            icon_task_type        VARCHAR2(200 CHAR),
                            id_action             NUMBER(24),
                            desc_action           VARCHAR2(1000 CHAR),
                            id_task_type_action   NUMBER(24),
                            desc_order            VARCHAR2(4000 CHAR),
                            desc_instructions     clob,
                            desc_task_action      VARCHAR2(1000 CHAR),
                            id_order_type         NUMBER(12),
                            desc_order_type       VARCHAR2(4000 CHAR),
                            id_prof_created       NUMBER(24),
                            id_prof_ordered_by    NUMBER(24),
                            desc_prof_ordered_by  VARCHAR2(1000 CHAR),
                            id_prof_co_signed     NUMBER(24),
                            dt_req                TIMESTAMP(6) WITH LOCAL TIME ZONE,
                            dt_created            TIMESTAMP(6) WITH LOCAL TIME ZONE,
                            dt_ordered_by         TIMESTAMP(6) WITH LOCAL TIME ZONE,
                            dt_co_signed          TIMESTAMP(6) WITH LOCAL TIME ZONE,
                            dt_exec_date_sort     TIMESTAMP(6) WITH LOCAL TIME ZONE,
                            flg_status            VARCHAR2(2 CHAR),
                            icon_status           VARCHAR2(200 CHAR),
                            desc_status           VARCHAR2(800),
                            code_co_sign_notes    VARCHAR2(200 CHAR),
                            co_sign_notes         CLOB,
                            flg_has_notes         VARCHAR2(1 CHAR),
                            flg_needs_cosign      VARCHAR2(1 CHAR),
                            flg_has_cosign       VARCHAR2(1 CHAR),
                            flg_made_auth        VARCHAR2(1 CHAR),

    CONSTRUCTOR FUNCTION t_rec_co_sign RETURN SELF AS RESULT  )
 ]');
 
    pk_versioning.run(i_sql => q'[CREATE OR REPLACE TYPE BODY t_rec_co_sign IS
    CONSTRUCTOR FUNCTION t_rec_co_sign RETURN SELF AS RESULT IS
    BEGIN

        self.id_co_sign_hist     := NULL;
        self.id_co_sign          := NULL;
        self.id_episode          := NULL;
        self.id_task             := NULL;
        self.id_task_group       := NULL;
        self.id_task_type        := NULL;
        self.desc_task_type      := NULL;
        self.icon_task_type      := NULL;
        self.id_action           := NULL;
        self.desc_action         := NULL;
        self.id_task_type_action := NULL;
        self.desc_order          := NULL;
        self.desc_instructions   := NULL;
        self.desc_task_action    := NULL;
        self.id_order_type       := NULL;
        self.desc_order_type     := NULL;
        self.id_prof_created     := NULL;
        self.id_prof_ordered_by  := NULL;
        self.desc_prof_ordered_by :=NULL;
        self.id_prof_co_signed   := NULL;
        self.dt_req              := NULL;
        self.dt_created          := NULL;
        self.dt_ordered_by       := NULL;
        self.dt_co_signed        := NULL;
        self.dt_exec_date_sort   := NULL;
        self.flg_status          := NULL;
        self.icon_status         := NULL;
        self.desc_status         := NULL;
        self.code_co_sign_notes  := NULL;
        self.co_sign_notes       := empty_clob();
        self.flg_has_notes       := NULL;
        self.flg_needs_cosign    := NULL;
        self.flg_has_cosign      := NULL;
        self.flg_made_auth       := NULL;
        RETURN;
    END;
 END;
 ]');
END;
/
