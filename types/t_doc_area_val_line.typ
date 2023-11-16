-- CHANGED BY: Gisela Couto 
-- CHANGE DATE: 18-02-2014
-- CHANGE REASON: ALERT-274443 - Current pregnancy record end by the system incoherent viewer info

CREATE OR REPLACE TYPE t_doc_area_val_line IS OBJECT
(
    id_epis_documentation     NUMBER(24),
    PARENT                    VARCHAR2(50),
    id_documentation          NUMBER(24),
    id_doc_component          NUMBER(24),
    id_doc_element_crit       NUMBER(24),
    dt_reg                    VARCHAR2(50 CHAR),
    desc_doc_component        VARCHAR2(4000),
    desc_element              VARCHAR2(4000),
    VALUE                     VARCHAR2(4000),
    id_doc_area               NUMBER(24),
    rank_component            NUMBER,
    rank_element              NUMBER,
    desc_qualification        VARCHAR2(4000),
    flg_current_episode       VARCHAR2(2),
    id_epis_documentation_det NUMBER(24)
);
/

-- CHANGE END: Gisela Couto
