-- CHANGED BY:Sofia Mendes
-- CHANGE DATE: 18/07/2009
-- CHANGE REASON: [ALERT-36170] - Bed scheduling
create TYPE t_rec_sch_inp_lv AS OBJECT(
        type VARCHAR2(24),
        id_bed NUMBER(24),
        id_patient  NUMBER(24),
        dt_begin TIMESTAMP WITH LOCAL TIME ZONE,
        dt_end   TIMESTAMP WITH LOCAL TIME ZONE,
	      begin_hour VARCHAR2(12),
	      end_hour   VARCHAR2(12),
	      icon       VARCHAR2(200),
	      position      number(12),
	      elem_id    number(24),
	      flg_color_session VARCHAr2(1));
-- CHANGE END: Sofia Mendes