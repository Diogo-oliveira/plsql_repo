CREATE OR REPLACE VIEW V_AUDITRECORD AS
SELECT SRA."ID_SYS_REQUEST",SRA."ID_SYS_SESSION",SRA."METHOD",SRA."REQ_VALUES",SRA."DT_REQUEST",SRA."DT_REQ_DAY",SRA."POSITION", saf.AUDIT_FUNC_DESC, Pk_Systracking.get_parameter_from_context(SRA.METHOD,SRA.REQ_VALUES,'PATIENT') PATIENT, 
Pk_Systracking.get_parameter_from_context(SRA.METHOD,SRA.REQ_VALUES,'EPISODE') EPISODE,
Pk_Systracking.get_parameter_from_context(SRA.METHOD,SRA.REQ_VALUES,'PROFESSIONAL') PROFESSIONAL, 
Pk_Systracking.get_parameter(Pk_Systracking.get_parameter_from_context(SRA.METHOD,SRA.REQ_VALUES,'PROFESSIONAL'),1) ID_PROFESSIONAL, 
Pk_Systracking.get_parameter(Pk_Systracking.get_parameter_from_context(SRA.METHOD,SRA.REQ_VALUES,'PROFESSIONAL'),2) ID_INSTITUTION, 
Pk_Systracking.get_parameter(Pk_Systracking.get_parameter_from_context(SRA.METHOD,SRA.REQ_VALUES,'PROFESSIONAL'),3) ID_SOFTWARE
FROM SYS_REQUEST_ATOMIC sra, SYS_AUDIT_FUNC saf WHERE sra.METHOD=saf.AUDIT_FUNC
