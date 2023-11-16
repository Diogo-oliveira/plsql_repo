-- CHANGED BY:  Elisabete Bugalho
-- CHANGE DATE: 22/04/2015 16:24
-- CHANGE REASON:     ALERT-310274 03 - Packages, Types & Views Versioning

CREATE OR REPLACE TYPE t_rec_desc_info_ranked force AS OBJECT
(
    id        NUMBER,
    desc_info CLOB,
    num_rank  NUMBER,
    tstz_rank TIMESTAMP(6) WITH LOCAL TIME ZONE,
    signature VARCHAR2(4000),
    CONSTRUCTOR FUNCTION t_rec_desc_info_ranked RETURN SELF AS RESULT
);