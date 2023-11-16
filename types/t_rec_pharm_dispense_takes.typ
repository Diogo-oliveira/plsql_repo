
create or replace type T_REC_PHARM_DISPENSE_TAKES as object
(
	drug		varchar2(255),
	version		varchar2(10),
	qt_presc	number(24,4),
	unit_presc	number(24),
	takes		number(24),
	qt_disp		number(24,4),
	unit_disp	number(24)
);
/
