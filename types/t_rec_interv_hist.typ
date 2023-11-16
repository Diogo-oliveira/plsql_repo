-- CHANGED BY: Nuno Neves
-- CHANGE DATE: 23/12/2011
-- CHANGE REASON: [ALERT-211466]
	CREATE OR REPLACE TYPE t_rec_interv_hist AS OBJECT
(      
    value_h                    VARCHAR2(1000 CHAR),
    descr_h                     VARCHAR2(1000 CHAR),
    id_icnp_epis_interv      NUMBER(24),
    id_icnp_interv_plan      NUMBER(24),
    id_vital_sign            NUMBER(24)
);
-- CHANGE END: Nuno Neves