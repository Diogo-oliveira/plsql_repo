-- CHANGED BY: António Neto
-- CHANGE DATE: 02/10/2011 10:19
-- CHANGE REASON: [ALERT_202696] Dev. DB - All buttons - Summary - Information regarding Critical care notes is not available

CREATE OR REPLACE TYPE t_rec_crit_doc_area_val AS OBJECT (
        id_epis_documentation      number(24),
				id_doc_component      number(24),
        desc_doc_component    VARCHAR2(4000 CHAR),
        desc_element          VARCHAR2(4000 CHAR)
);
/
-- CHANGE END: António Neto
