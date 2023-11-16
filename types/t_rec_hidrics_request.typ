-- CHANGED BY: Sofia Mendes
-- CHANGE DATE: 02/10/2013
-- CHANGE REASON: [ALERT-266187] Intake and output improvements
BEGIN
    EXECUTE IMMEDIATE 'CREATE OR REPLACE TYPE t_rec_hidrics_request AS OBJECT
(
    id_epis_hidrics         NUMBER(24),
    flg_status_eh           VARCHAR2(1 CHAR),
    id_hidrics_type         NUMBER(24),
    acronym                 VARCHAR2(10 CHAR),
    id_epis_hidrics_balance NUMBER(24),
    flg_status_ehb          VARCHAR2(1 CHAR),
    dt_initial_tstz         TIMESTAMP(6)
        WITH LOCAL TIME ZONE,
    dt_end_tstz             TIMESTAMP(6)
        WITH LOCAL TIME ZONE,
    dt_next_balance         TIMESTAMP(6)
        WITH LOCAL TIME ZONE,
    interval_minutes        NUMBER(12),
    flg_restricted          VARCHAR2(1 CHAR),
    max_intake              NUMBER(24),
    min_output              NUMBER(24),
    total_admin             NUMBER(24),
    total_elim              NUMBER(24),
    dt_open_tstz            TIMESTAMP(6)
        WITH LOCAL TIME ZONE,
    dt_close_balance_tstz   TIMESTAMP(6)
        WITH LOCAL TIME ZONE,
    id_epis_type            NUMBER(24),
    flg_ti_type             VARCHAR2(2 CHAR),
    code_hidrics_type       VARCHAR2(200 CHAR),
    id_hidrics_interval     NUMBER(24),
    code_hidrics_interval   VARCHAR2(200 CHAR),
    flg_type                VARCHAR2(1 CHAR),
    notes                   VARCHAR2(2000 CHAR),
    notes_cancel            VARCHAR2(2000 CHAR),
    notes_inter             VARCHAR2(2000 CHAR),
    dt_begin_tstz           TIMESTAMP(6)
        WITH LOCAL TIME ZONE,
    id_professional_eh      NUMBER(24),
    id_professional_pr      NUMBER(24),
    flg_check_extra_take    VARCHAR2(1 CHAR),
    id_episode NUMBER(24)
)';
EXCEPTION
    WHEN OTHERS THEN
        dbms_output.put_line('operacao ja executada anteriormente');
END;

-- CHANGED BY: Vanessa Barsottelli
-- CHANGE DATE: 18/04/2016 11:20
-- CHANGE REASON: [ALERT-320093] - PIN Intake and Output improvements
BEGIN
    pk_versioning.run(i_sql => q'[CREATE OR REPLACE TYPE t_rec_hidrics_request force AS OBJECT
                                (
                                    id_epis_hidrics         NUMBER(24),
                                    flg_status_eh           VARCHAR2(1 CHAR),
                                    id_hidrics_type         NUMBER(24),
                                    acronym                 VARCHAR2(10 CHAR),
                                    id_epis_hidrics_balance NUMBER(24),
                                    flg_status_ehb          VARCHAR2(1 CHAR),
                                    dt_initial_tstz         TIMESTAMP(6)
                                        WITH LOCAL TIME ZONE,
                                    dt_end_tstz             TIMESTAMP(6)
                                        WITH LOCAL TIME ZONE,
                                    dt_next_balance         TIMESTAMP(6)
                                        WITH LOCAL TIME ZONE,
                                    interval_minutes        NUMBER(12),
                                    flg_restricted          VARCHAR2(1 CHAR),
                                    max_intake              NUMBER(26,2),
                                    min_output              NUMBER(26,2),
                                    total_admin             NUMBER(26,2),
                                    total_elim              NUMBER(26,2),
                                    dt_open_tstz            TIMESTAMP(6)
                                        WITH LOCAL TIME ZONE,
                                    dt_close_balance_tstz   TIMESTAMP(6)
                                        WITH LOCAL TIME ZONE,
                                    id_epis_type            NUMBER(24),
                                    flg_ti_type             VARCHAR2(2 CHAR),
                                    code_hidrics_type       VARCHAR2(200 CHAR),
                                    id_hidrics_interval     NUMBER(24),
                                    code_hidrics_interval   VARCHAR2(200 CHAR),
                                    flg_type                VARCHAR2(1 CHAR),
                                    notes                   VARCHAR2(2000 CHAR),
                                    notes_cancel            VARCHAR2(2000 CHAR),
                                    notes_inter             VARCHAR2(2000 CHAR),
                                    dt_begin_tstz           TIMESTAMP(6)
                                        WITH LOCAL TIME ZONE,
                                    id_professional_eh      NUMBER(24),
                                    id_professional_pr      NUMBER(24),
                                    flg_check_extra_take    VARCHAR2(1 CHAR),
                                    id_episode NUMBER(24),

                                    CONSTRUCTOR FUNCTION t_rec_hidrics_request RETURN SELF AS RESULT  )
                                ]');

END;
-- END CHANGED
/
--CHANGE END: Sofia Mendes

-- CHANGED BY: Pedro Henriques
-- CHANGE DATE: 11/08/2016 08:12
-- CHANGE REASON: [ALERT-323541]

BEGIN
    pk_versioning.run(i_sql => q'[CREATE OR REPLACE TYPE t_rec_hidrics_request force AS OBJECT
                                (
                                    id_epis_hidrics         NUMBER(24),
                                    flg_status_eh           VARCHAR2(2 CHAR),
                                    id_hidrics_type         NUMBER(24),
                                    acronym                 VARCHAR2(10 CHAR),
                                    id_epis_hidrics_balance NUMBER(24),
                                    flg_status_ehb          VARCHAR2(2 CHAR),
                                    dt_initial_tstz         TIMESTAMP(6)
                                        WITH LOCAL TIME ZONE,
                                    dt_end_tstz             TIMESTAMP(6)
                                        WITH LOCAL TIME ZONE,
                                    dt_next_balance         TIMESTAMP(6)
                                        WITH LOCAL TIME ZONE,
                                    interval_minutes        NUMBER(12),
                                    flg_restricted          VARCHAR2(1 CHAR),
                                    max_intake              NUMBER(26,2),
                                    min_output              NUMBER(26,2),
                                    total_admin             NUMBER(26,2),
                                    total_elim              NUMBER(26,2),
                                    dt_open_tstz            TIMESTAMP(6)
                                        WITH LOCAL TIME ZONE,
                                    dt_close_balance_tstz   TIMESTAMP(6)
                                        WITH LOCAL TIME ZONE,
                                    id_epis_type            NUMBER(24),
                                    flg_ti_type             VARCHAR2(2 CHAR),
                                    code_hidrics_type       VARCHAR2(200 CHAR),
                                    id_hidrics_interval     NUMBER(24),
                                    code_hidrics_interval   VARCHAR2(200 CHAR),
                                    flg_type                VARCHAR2(1 CHAR),
                                    notes                   VARCHAR2(2000 CHAR),
                                    notes_cancel            VARCHAR2(2000 CHAR),
                                    notes_inter             VARCHAR2(2000 CHAR),
                                    dt_begin_tstz           TIMESTAMP(6)
                                        WITH LOCAL TIME ZONE,
                                    id_professional_eh      NUMBER(24),
                                    id_professional_pr      NUMBER(24),
                                    flg_check_extra_take    VARCHAR2(1 CHAR),
                                    id_episode NUMBER(24),

                                    CONSTRUCTOR FUNCTION t_rec_hidrics_request RETURN SELF AS RESULT  )
                                ]');

END;

--CHANGE END: Pedro Henriques
/