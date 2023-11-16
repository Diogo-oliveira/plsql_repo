-- CHANGED BY:Sofia Mendes
-- CHANGE DATE: 31/07/2009
-- CHANGE REASON: [ALERT-38676]
create TYPE t_rec_sch_alloc AS OBJECT(
        id_schedule number(24),
        id_bed NUMBER(24),
        id_patient  NUMBER(24),
	dt_begin TIMESTAMP WITH LOCAL TIME ZONE,
	dt_end   TIMESTAMP WITH LOCAL TIME ZONE);
-- CHANGE END: Sofia Mendes