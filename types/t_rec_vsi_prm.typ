-- CHANGED BY: Paulo Teixeira
-- CHANGE DATE: 02/05/2016 09:24
-- CHANGE REASON: [ALERT-320563] 
CREATE OR REPLACE TYPE t_rec_vsi_prm force AS OBJECT
(
    id_vs_soft_inst   NUMBER(24),
    id_vital_sign     NUMBER(24),
    desc_vital_sign   VARCHAR2(1000 CHAR),
    desc_market       VARCHAR2(200 CHAR),
    id_market         NUMBER(24),
    desc_software     VARCHAR2(200 CHAR),
    id_software       NUMBER(24),
    version           VARCHAR2(200 CHAR),
    desc_flg_view     VARCHAR2(200 CHAR),
    flg_view          VARCHAR2(200 CHAR),
    desc_unit_measure VARCHAR2(200 CHAR),
    id_unit_measure   NUMBER(24),
    color_grafh       VARCHAR2(200 CHAR),
    color_text        VARCHAR2(200 CHAR),
    box_type          VARCHAR2(1 CHAR),
    desc_box_type     VARCHAR2(200 CHAR),
    rank              NUMBER(24),
    CONSTRUCTOR FUNCTION t_rec_vsi_prm RETURN SELF AS RESULT
);
-- CHANGE END: Paulo Teixeira