
--index with deterministic function!!! 
-- function for index use (index = ALERT.DR_IDR_EPI_PAT_TYP_DT_NT_IDX)
create or replace 
function pharmacy_idx_func_dr_has_notes
(
	i_notes in drug_req.notes_req%type
)
return number deterministic
is
	l_ret number(1) := 0;
begin
	if (i_notes is not null) then
		l_ret := 1;
	end if;

	return l_ret;
end pharmacy_idx_func_dr_has_notes;
/
