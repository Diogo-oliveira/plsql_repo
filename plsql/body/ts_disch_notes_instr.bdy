/*-- Last Change Revision: $Rev: 1877368 $*/
/*-- Last Change by: $Author: adriano.ferreira $*/
/*-- Date of last change: $Date: 2018-11-12 15:39:19 +0000 (seg, 12 nov 2018) $*/
CREATE OR REPLACE PACKAGE BODY ts_disch_notes_instr
/*
| Generated by or retrieved - DO NOT MODIFY!
| Created On: 2017-06-26 15:10:57
| Created By: ALERT
*/
IS

e_null_column_value EXCEPTION;
PRAGMA EXCEPTION_INIT(e_null_column_value, -1400);

e_existing_fky_reference EXCEPTION;
PRAGMA EXCEPTION_INIT(e_existing_fky_reference, -2266);

e_check_constraint_failure EXCEPTION;
PRAGMA EXCEPTION_INIT(e_check_constraint_failure, -2290);

e_no_parent_key EXCEPTION;
PRAGMA EXCEPTION_INIT(e_no_parent_key, -2291);

e_child_record_found EXCEPTION;
PRAGMA EXCEPTION_INIT(e_child_record_found, -2292);

e_forall_error EXCEPTION;
PRAGMA EXCEPTION_INIT(e_forall_error, -24381);

-- Defined for backward compatibilty.
e_integ_constraint_failure EXCEPTION;
PRAGMA EXCEPTION_INIT(e_integ_constraint_failure, -2291);

PROCEDURE ins
(
ID_DISCHARGE_NOTES_in IN disch_notes_instr.ID_DISCHARGE_NOTES%TYPE,
ID_DISCH_INSTRUCTIONS_in IN disch_notes_instr.ID_DISCH_INSTRUCTIONS%TYPE,
CREATE_USER_in IN DISCH_NOTES_INSTR.CREATE_USER%TYPE DEFAULT NULL,
CREATE_TIME_in IN DISCH_NOTES_INSTR.CREATE_TIME%TYPE DEFAULT NULL,
CREATE_INSTITUTION_in IN DISCH_NOTES_INSTR.CREATE_INSTITUTION%TYPE DEFAULT NULL,
UPDATE_USER_in IN DISCH_NOTES_INSTR.UPDATE_USER%TYPE DEFAULT NULL,
UPDATE_TIME_in IN DISCH_NOTES_INSTR.UPDATE_TIME%TYPE DEFAULT NULL,
UPDATE_INSTITUTION_in IN DISCH_NOTES_INSTR.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
handle_error_in IN BOOLEAN := TRUE,
rows_out OUT table_varchar
) IS
BEGIN
INSERT INTO disch_notes_instr
(
ID_DISCHARGE_NOTES,
ID_DISCH_INSTRUCTIONS,
CREATE_USER,
CREATE_TIME,
CREATE_INSTITUTION,
UPDATE_USER,
UPDATE_TIME,
UPDATE_INSTITUTION
)
 VALUES
(
ID_DISCHARGE_NOTES_IN,
ID_DISCH_INSTRUCTIONS_IN,
CREATE_USER_IN,
CREATE_TIME_IN,
CREATE_INSTITUTION_IN,
UPDATE_USER_IN,
UPDATE_TIME_IN,
UPDATE_INSTITUTION_IN
)
RETURNING ROWID BULK COLLECT INTO rows_out;

EXCEPTION
WHEN e_null_column_value
OR e_existing_fky_reference
OR e_check_constraint_failure
OR e_no_parent_key
OR e_child_record_found
OR e_forall_error
OR e_integ_constraint_failure THEN
IF NOT handle_error_in
THEN
RAISE;
ELSE
pk_alertlog.log_info('DML error ignored: ' || SQLCODE || ': ' || SQLERRM);
END IF;

end ins;

PROCEDURE ins
(
ID_DISCHARGE_NOTES_in IN disch_notes_instr.ID_DISCHARGE_NOTES%TYPE,
ID_DISCH_INSTRUCTIONS_in IN disch_notes_instr.ID_DISCH_INSTRUCTIONS%TYPE,
CREATE_USER_in IN DISCH_NOTES_INSTR.CREATE_USER%TYPE DEFAULT NULL,
CREATE_TIME_in IN DISCH_NOTES_INSTR.CREATE_TIME%TYPE DEFAULT NULL,
CREATE_INSTITUTION_in IN DISCH_NOTES_INSTR.CREATE_INSTITUTION%TYPE DEFAULT NULL,
UPDATE_USER_in IN DISCH_NOTES_INSTR.UPDATE_USER%TYPE DEFAULT NULL,
UPDATE_TIME_in IN DISCH_NOTES_INSTR.UPDATE_TIME%TYPE DEFAULT NULL,
UPDATE_INSTITUTION_in IN DISCH_NOTES_INSTR.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
handle_error_in IN BOOLEAN := TRUE
) IS
rows_out table_varchar;
BEGIN
ins(
ID_DISCHARGE_NOTES_IN => ID_DISCHARGE_NOTES_IN,
ID_DISCH_INSTRUCTIONS_IN => ID_DISCH_INSTRUCTIONS_IN,
CREATE_USER_IN => CREATE_USER_IN,
CREATE_TIME_IN => CREATE_TIME_IN,
CREATE_INSTITUTION_IN => CREATE_INSTITUTION_IN,
UPDATE_USER_IN => UPDATE_USER_IN,
UPDATE_TIME_IN => UPDATE_TIME_IN,
UPDATE_INSTITUTION_IN => UPDATE_INSTITUTION_IN,
handle_error_in => handle_error_in,
rows_out => rows_out);
END ins;

PROCEDURE ins
(
rec_in          IN disch_notes_instr%ROWTYPE,
gen_pky_in      IN BOOLEAN DEFAULT FALSE,
sequence_in     IN VARCHAR2 := NULL,
handle_error_in IN BOOLEAN := TRUE,
rows_out        OUT table_varchar
) IS
l_rec disch_notes_instr%ROWTYPE := rec_in;
BEGIN

ins(
ID_DISCHARGE_NOTES_IN => l_rec.ID_DISCHARGE_NOTES,
ID_DISCH_INSTRUCTIONS_IN => l_rec.ID_DISCH_INSTRUCTIONS,
CREATE_USER_IN => l_rec.CREATE_USER,
CREATE_TIME_IN => l_rec.CREATE_TIME,
CREATE_INSTITUTION_IN => l_rec.CREATE_INSTITUTION,
UPDATE_USER_IN => l_rec.UPDATE_USER,
UPDATE_TIME_IN => l_rec.UPDATE_TIME,
UPDATE_INSTITUTION_IN => l_rec.UPDATE_INSTITUTION,
handle_error_in       => handle_error_in,
rows_out              => rows_out);
END ins;

PROCEDURE ins
(
rec_in          IN disch_notes_instr%ROWTYPE,
gen_pky_in      IN BOOLEAN DEFAULT FALSE,
sequence_in     IN VARCHAR2 := NULL,
handle_error_in IN BOOLEAN := TRUE
) IS
rows_out table_varchar;
BEGIN
ins(rec_in          => rec_in,
gen_pky_in      => gen_pky_in,
sequence_in     => sequence_in,
handle_error_in => handle_error_in,
rows_out        => rows_out);
END ins;

-- Insert a collection of rows using FORALL; all primary key values
-- must have already been generated, or are handled in triggers
PROCEDURE ins
(
rows_in         IN disch_notes_instr_tc,
handle_error_in IN BOOLEAN := TRUE,
rows_out        OUT table_varchar
)
IS
BEGIN
IF rows_in.COUNT = 0
THEN
NULL;
ELSE
FORALL indx IN rows_in.FIRST .. rows_in.LAST SAVE EXCEPTIONS
INSERT INTO disch_notes_instr
VALUES rows_in
(indx)
RETURNING ROWID BULK COLLECT INTO rows_out;
END IF;

EXCEPTION
WHEN e_forall_error THEN
IF NOT handle_error_in
THEN
RAISE;
ELSE
FOR indx IN 1 .. SQL%BULK_EXCEPTIONS.COUNT
LOOP
pk_alertlog.log_info('DML error ignored: ' || SQLCODE || ': ' || SQLERRM);
END LOOP;
END IF;
WHEN OTHERS THEN
IF NOT handle_error_in
THEN
RAISE;
ELSE
pk_alertlog.log_info('DML error ignored: ' || SQLCODE || ': ' || SQLERRM);
END IF;

END ins;

-- Insert a collection of rows using FORALL; all primary key values
-- must have already been generated, or are handled in triggers
PROCEDURE ins
(
rows_in         IN disch_notes_instr_tc,
handle_error_in IN BOOLEAN := TRUE
)
IS
rows_out table_varchar;
BEGIN
ins(rows_in => rows_in, handle_error_in => handle_error_in, rows_out => rows_out);
END ins;

-- Update any/all columns by primary key. If you pass NULL, then
-- the current column value is set to itself. If you need a more
-- selected UPDATE then use one of the onecol procedures below.
PROCEDURE upd
(
ID_DISCHARGE_NOTES_in IN disch_notes_instr.ID_DISCHARGE_NOTES%TYPE,
ID_DISCH_INSTRUCTIONS_in IN disch_notes_instr.ID_DISCH_INSTRUCTIONS%TYPE,
CREATE_USER_in IN DISCH_NOTES_INSTR.CREATE_USER%TYPE DEFAULT NULL,
CREATE_USER_nin IN BOOLEAN := TRUE,
CREATE_TIME_in IN DISCH_NOTES_INSTR.CREATE_TIME%TYPE DEFAULT NULL,
CREATE_TIME_nin IN BOOLEAN := TRUE,
CREATE_INSTITUTION_in IN DISCH_NOTES_INSTR.CREATE_INSTITUTION%TYPE DEFAULT NULL,
CREATE_INSTITUTION_nin IN BOOLEAN := TRUE,
UPDATE_USER_in IN DISCH_NOTES_INSTR.UPDATE_USER%TYPE DEFAULT NULL,
UPDATE_USER_nin IN BOOLEAN := TRUE,
UPDATE_TIME_in IN DISCH_NOTES_INSTR.UPDATE_TIME%TYPE DEFAULT NULL,
UPDATE_TIME_nin IN BOOLEAN := TRUE,
UPDATE_INSTITUTION_in IN DISCH_NOTES_INSTR.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
UPDATE_INSTITUTION_nin IN BOOLEAN := TRUE,
handle_error_in        IN BOOLEAN := TRUE,
rows_out               IN OUT table_varchar
)
is
l_rows_out             table_varchar;
l_CREATE_USER_n number(1) := sys.diutil.bool_to_int(CREATE_USER_nin);
l_CREATE_TIME_n number(1) := sys.diutil.bool_to_int(CREATE_TIME_nin);
l_CREATE_INSTITUTION_n number(1) := sys.diutil.bool_to_int(CREATE_INSTITUTION_nin);
l_UPDATE_USER_n number(1) := sys.diutil.bool_to_int(UPDATE_USER_nin);
l_UPDATE_TIME_n number(1) := sys.diutil.bool_to_int(UPDATE_TIME_nin);
l_UPDATE_INSTITUTION_n number(1) := sys.diutil.bool_to_int(UPDATE_INSTITUTION_nin);
begin

UPDATE disch_notes_instr
SET
CREATE_USER = decode(l_CREATE_USER_n, 0, CREATE_USER_in, nvl(CREATE_USER_in, CREATE_USER)),
CREATE_TIME = decode(l_CREATE_TIME_n, 0, CREATE_TIME_in, nvl(CREATE_TIME_in, CREATE_TIME)),
CREATE_INSTITUTION = decode(l_CREATE_INSTITUTION_n, 0, CREATE_INSTITUTION_in, nvl(CREATE_INSTITUTION_in, CREATE_INSTITUTION)),
UPDATE_USER = decode(l_UPDATE_USER_n, 0, UPDATE_USER_in, nvl(UPDATE_USER_in, UPDATE_USER)),
UPDATE_TIME = decode(l_UPDATE_TIME_n, 0, UPDATE_TIME_in, nvl(UPDATE_TIME_in, UPDATE_TIME)),
UPDATE_INSTITUTION = decode(l_UPDATE_INSTITUTION_n, 0, UPDATE_INSTITUTION_in, nvl(UPDATE_INSTITUTION_in, UPDATE_INSTITUTION))
 WHERE
ID_DISCHARGE_NOTES = ID_DISCHARGE_NOTES_IN
 AND ID_DISCH_INSTRUCTIONS = ID_DISCH_INSTRUCTIONS_IN
RETURNING ROWID BULK COLLECT INTO l_rows_out;
IF (rows_out IS NULL)
THEN
rows_out := table_varchar();
END IF;
rows_out := rows_out MULTISET UNION DISTINCT l_rows_out;

EXCEPTION
WHEN e_null_column_value
OR e_existing_fky_reference
OR e_check_constraint_failure
OR e_no_parent_key
OR e_child_record_found
OR e_forall_error
OR e_integ_constraint_failure THEN
IF NOT handle_error_in
THEN
RAISE;
ELSE
pk_alertlog.log_info('DML error ignored: ' || SQLCODE || ': ' || SQLERRM);
END IF;

end upd;

-- Update any/all columns by primary key. If you pass NULL, then
-- the current column value is set to itself. If you need a more
-- selected UPDATE then use one of the onecol procedures below.
PROCEDURE upd
(
ID_DISCHARGE_NOTES_in IN disch_notes_instr.ID_DISCHARGE_NOTES%TYPE,
ID_DISCH_INSTRUCTIONS_in IN disch_notes_instr.ID_DISCH_INSTRUCTIONS%TYPE,
CREATE_USER_in IN DISCH_NOTES_INSTR.CREATE_USER%TYPE DEFAULT NULL,
CREATE_USER_nin IN BOOLEAN := TRUE,
CREATE_TIME_in IN DISCH_NOTES_INSTR.CREATE_TIME%TYPE DEFAULT NULL,
CREATE_TIME_nin IN BOOLEAN := TRUE,
CREATE_INSTITUTION_in IN DISCH_NOTES_INSTR.CREATE_INSTITUTION%TYPE DEFAULT NULL,
CREATE_INSTITUTION_nin IN BOOLEAN := TRUE,
UPDATE_USER_in IN DISCH_NOTES_INSTR.UPDATE_USER%TYPE DEFAULT NULL,
UPDATE_USER_nin IN BOOLEAN := TRUE,
UPDATE_TIME_in IN DISCH_NOTES_INSTR.UPDATE_TIME%TYPE DEFAULT NULL,
UPDATE_TIME_nin IN BOOLEAN := TRUE,
UPDATE_INSTITUTION_in IN DISCH_NOTES_INSTR.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
UPDATE_INSTITUTION_nin IN BOOLEAN := TRUE,
handle_error_in        IN BOOLEAN := TRUE
)
is
rows_out table_varchar;
begin
upd(
ID_DISCHARGE_NOTES_IN => ID_DISCHARGE_NOTES_IN,
ID_DISCH_INSTRUCTIONS_IN => ID_DISCH_INSTRUCTIONS_IN,
CREATE_USER_IN => CREATE_USER_IN,
CREATE_USER_NIN => CREATE_USER_NIN,
CREATE_TIME_IN => CREATE_TIME_IN,
CREATE_TIME_NIN => CREATE_TIME_NIN,
CREATE_INSTITUTION_IN => CREATE_INSTITUTION_IN,
CREATE_INSTITUTION_NIN => CREATE_INSTITUTION_NIN,
UPDATE_USER_IN => UPDATE_USER_IN,
UPDATE_USER_NIN => UPDATE_USER_NIN,
UPDATE_TIME_IN => UPDATE_TIME_IN,
UPDATE_TIME_NIN => UPDATE_TIME_NIN,
UPDATE_INSTITUTION_IN => UPDATE_INSTITUTION_IN,
UPDATE_INSTITUTION_NIN => UPDATE_INSTITUTION_NIN,
handle_error_in        => handle_error_in,
rows_out               => rows_out);
end upd;

--Update any/all columns by dynamic WHERE
-- If you pass NULL, then the current column value is set to itself
PROCEDURE upd
(
CREATE_USER_in IN DISCH_NOTES_INSTR.CREATE_USER%TYPE DEFAULT NULL,
CREATE_USER_nin IN BOOLEAN := TRUE,
CREATE_TIME_in IN DISCH_NOTES_INSTR.CREATE_TIME%TYPE DEFAULT NULL,
CREATE_TIME_nin IN BOOLEAN := TRUE,
CREATE_INSTITUTION_in IN DISCH_NOTES_INSTR.CREATE_INSTITUTION%TYPE DEFAULT NULL,
CREATE_INSTITUTION_nin IN BOOLEAN := TRUE,
UPDATE_USER_in IN DISCH_NOTES_INSTR.UPDATE_USER%TYPE DEFAULT NULL,
UPDATE_USER_nin IN BOOLEAN := TRUE,
UPDATE_TIME_in IN DISCH_NOTES_INSTR.UPDATE_TIME%TYPE DEFAULT NULL,
UPDATE_TIME_nin IN BOOLEAN := TRUE,
UPDATE_INSTITUTION_in IN DISCH_NOTES_INSTR.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
UPDATE_INSTITUTION_nin IN BOOLEAN := TRUE,
where_in               IN VARCHAR2,
handle_error_in        IN BOOLEAN := TRUE,
rows_out               IN OUT table_varchar
)
is
l_sql                  VARCHAR2(32767);
l_rows_out             table_varchar;
l_CREATE_USER_n number(1) := sys.diutil.bool_to_int(CREATE_USER_nin);
l_CREATE_TIME_n number(1) := sys.diutil.bool_to_int(CREATE_TIME_nin);
l_CREATE_INSTITUTION_n number(1) := sys.diutil.bool_to_int(CREATE_INSTITUTION_nin);
l_UPDATE_USER_n number(1) := sys.diutil.bool_to_int(UPDATE_USER_nin);
l_UPDATE_TIME_n number(1) := sys.diutil.bool_to_int(UPDATE_TIME_nin);
l_UPDATE_INSTITUTION_n number(1) := sys.diutil.bool_to_int(UPDATE_INSTITUTION_nin);
begin
l_CREATE_USER_n := sys.diutil.bool_to_int(CREATE_USER_nin);
l_CREATE_TIME_n := sys.diutil.bool_to_int(CREATE_TIME_nin);
l_CREATE_INSTITUTION_n := sys.diutil.bool_to_int(CREATE_INSTITUTION_nin);
l_UPDATE_USER_n := sys.diutil.bool_to_int(UPDATE_USER_nin);
l_UPDATE_TIME_n := sys.diutil.bool_to_int(UPDATE_TIME_nin);
l_UPDATE_INSTITUTION_n := sys.diutil.bool_to_int(UPDATE_INSTITUTION_nin);
l_sql := 'UPDATE disch_notes_instr SET' ||
' CREATE_USER = decode (' || l_CREATE_USER_n || ',0,:CREATE_USER_in, NVL (:CREATE_USER_in, CREATE_USER)) ' ||',' ||
' CREATE_TIME = decode (' || l_CREATE_TIME_n || ',0,:CREATE_TIME_in, NVL (:CREATE_TIME_in, CREATE_TIME)) ' ||',' ||
' CREATE_INSTITUTION = decode (' || l_CREATE_INSTITUTION_n || ',0,:CREATE_INSTITUTION_in, NVL (:CREATE_INSTITUTION_in, CREATE_INSTITUTION)) ' ||',' ||
' UPDATE_USER = decode (' || l_UPDATE_USER_n || ',0,:UPDATE_USER_in, NVL (:UPDATE_USER_in, UPDATE_USER)) ' ||',' ||
' UPDATE_TIME = decode (' || l_UPDATE_TIME_n || ',0,:UPDATE_TIME_in, NVL (:UPDATE_TIME_in, UPDATE_TIME)) ' ||',' ||
' UPDATE_INSTITUTION = decode (' || l_UPDATE_INSTITUTION_n || ',0,:UPDATE_INSTITUTION_in, NVL (:UPDATE_INSTITUTION_in, UPDATE_INSTITUTION)) ' ||
' where ' || nvl(where_in, '(1=1)') || ' RETURNING ROWID BULK COLLECT INTO :l_rows_out';
EXECUTE IMMEDIATE 'BEGIN ' || l_sql || '; END;'
USING IN
CREATE_USER_IN,
CREATE_TIME_IN,
CREATE_INSTITUTION_IN,
UPDATE_USER_IN,
UPDATE_TIME_IN,
UPDATE_INSTITUTION_IN,
OUT l_rows_out;
IF (rows_out IS NULL)
THEN
rows_out := table_varchar();
END IF;
rows_out := rows_out MULTISET UNION DISTINCT l_rows_out;

EXCEPTION
WHEN e_null_column_value
OR e_existing_fky_reference
OR e_check_constraint_failure
OR e_no_parent_key
OR e_child_record_found
OR e_forall_error
OR e_integ_constraint_failure THEN
IF NOT handle_error_in
THEN
RAISE;
ELSE
pk_alertlog.log_info('DML error ignored: ' || SQLCODE || ': ' || SQLERRM);
END IF;

end upd;

--Update any/all columns by dynamic WHERE
-- If you pass NULL, then the current column value is set to itself
PROCEDURE upd
(
CREATE_USER_in IN DISCH_NOTES_INSTR.CREATE_USER%TYPE DEFAULT NULL,
CREATE_USER_nin IN BOOLEAN := TRUE,
CREATE_TIME_in IN DISCH_NOTES_INSTR.CREATE_TIME%TYPE DEFAULT NULL,
CREATE_TIME_nin IN BOOLEAN := TRUE,
CREATE_INSTITUTION_in IN DISCH_NOTES_INSTR.CREATE_INSTITUTION%TYPE DEFAULT NULL,
CREATE_INSTITUTION_nin IN BOOLEAN := TRUE,
UPDATE_USER_in IN DISCH_NOTES_INSTR.UPDATE_USER%TYPE DEFAULT NULL,
UPDATE_USER_nin IN BOOLEAN := TRUE,
UPDATE_TIME_in IN DISCH_NOTES_INSTR.UPDATE_TIME%TYPE DEFAULT NULL,
UPDATE_TIME_nin IN BOOLEAN := TRUE,
UPDATE_INSTITUTION_in IN DISCH_NOTES_INSTR.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
UPDATE_INSTITUTION_nin IN BOOLEAN := TRUE,
where_in               IN VARCHAR2,
handle_error_in        IN BOOLEAN := TRUE
)
is
rows_out table_varchar;
begin
upd(
CREATE_USER_IN => CREATE_USER_IN,
CREATE_USER_NIN => CREATE_USER_NIN,
CREATE_TIME_IN => CREATE_TIME_IN,
CREATE_TIME_NIN => CREATE_TIME_NIN,
CREATE_INSTITUTION_IN => CREATE_INSTITUTION_IN,
CREATE_INSTITUTION_NIN => CREATE_INSTITUTION_NIN,
UPDATE_USER_IN => UPDATE_USER_IN,
UPDATE_USER_NIN => UPDATE_USER_NIN,
UPDATE_TIME_IN => UPDATE_TIME_IN,
UPDATE_TIME_NIN => UPDATE_TIME_NIN,
UPDATE_INSTITUTION_IN => UPDATE_INSTITUTION_IN,
UPDATE_INSTITUTION_NIN => UPDATE_INSTITUTION_NIN,
where_in               => where_in,
handle_error_in        => handle_error_in,
rows_out               => rows_out);
end upd;

--Update/insert columns (with rows_out)
PROCEDURE upd_ins
(
ID_DISCHARGE_NOTES_in IN disch_notes_instr.ID_DISCHARGE_NOTES%TYPE,
ID_DISCH_INSTRUCTIONS_in IN disch_notes_instr.ID_DISCH_INSTRUCTIONS%TYPE,
CREATE_USER_in IN DISCH_NOTES_INSTR.CREATE_USER%TYPE DEFAULT NULL,
CREATE_TIME_in IN DISCH_NOTES_INSTR.CREATE_TIME%TYPE DEFAULT NULL,
CREATE_INSTITUTION_in IN DISCH_NOTES_INSTR.CREATE_INSTITUTION%TYPE DEFAULT NULL,
UPDATE_USER_in IN DISCH_NOTES_INSTR.UPDATE_USER%TYPE DEFAULT NULL,
UPDATE_TIME_in IN DISCH_NOTES_INSTR.UPDATE_TIME%TYPE DEFAULT NULL,
UPDATE_INSTITUTION_in IN DISCH_NOTES_INSTR.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
handle_error_in        IN BOOLEAN := TRUE,
rows_out               IN OUT table_varchar
)
is
begin
upd(
ID_DISCHARGE_NOTES_IN => ID_DISCHARGE_NOTES_IN,
ID_DISCH_INSTRUCTIONS_IN => ID_DISCH_INSTRUCTIONS_IN,
CREATE_USER_IN => CREATE_USER_IN,
CREATE_TIME_IN => CREATE_TIME_IN,
CREATE_INSTITUTION_IN => CREATE_INSTITUTION_IN,
UPDATE_USER_IN => UPDATE_USER_IN,
UPDATE_TIME_IN => UPDATE_TIME_IN,
UPDATE_INSTITUTION_IN => UPDATE_INSTITUTION_IN,
handle_error_in        => handle_error_in,
rows_out               => rows_out);
IF SQL%ROWCOUNT = 0
THEN
ins(
ID_DISCHARGE_NOTES_IN => ID_DISCHARGE_NOTES_IN,
ID_DISCH_INSTRUCTIONS_IN => ID_DISCH_INSTRUCTIONS_IN,
CREATE_USER_IN => CREATE_USER_IN,
CREATE_TIME_IN => CREATE_TIME_IN,
CREATE_INSTITUTION_IN => CREATE_INSTITUTION_IN,
UPDATE_USER_IN => UPDATE_USER_IN,
UPDATE_TIME_IN => UPDATE_TIME_IN,
UPDATE_INSTITUTION_IN => UPDATE_INSTITUTION_IN,
handle_error_in        => handle_error_in,
rows_out               => rows_out);
END IF;
end upd_ins;

--Update/insert columns (without rows_out)
PROCEDURE upd_ins
(
ID_DISCHARGE_NOTES_in IN disch_notes_instr.ID_DISCHARGE_NOTES%TYPE,
ID_DISCH_INSTRUCTIONS_in IN disch_notes_instr.ID_DISCH_INSTRUCTIONS%TYPE,
CREATE_USER_in IN DISCH_NOTES_INSTR.CREATE_USER%TYPE DEFAULT NULL,
CREATE_TIME_in IN DISCH_NOTES_INSTR.CREATE_TIME%TYPE DEFAULT NULL,
CREATE_INSTITUTION_in IN DISCH_NOTES_INSTR.CREATE_INSTITUTION%TYPE DEFAULT NULL,
UPDATE_USER_in IN DISCH_NOTES_INSTR.UPDATE_USER%TYPE DEFAULT NULL,
UPDATE_TIME_in IN DISCH_NOTES_INSTR.UPDATE_TIME%TYPE DEFAULT NULL,
UPDATE_INSTITUTION_in IN DISCH_NOTES_INSTR.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
handle_error_in        IN BOOLEAN := TRUE
)
is
rows_out table_varchar;
begin
upd_ins(
ID_DISCHARGE_NOTES_IN,
ID_DISCH_INSTRUCTIONS_IN,
CREATE_USER_IN,
CREATE_TIME_IN,
CREATE_INSTITUTION_IN,
UPDATE_USER_IN,
UPDATE_TIME_IN,
UPDATE_INSTITUTION_IN,
handle_error_in,
rows_out);
end upd_ins;

--Update by record (with rows_out)
PROCEDURE upd
(
rec_in          IN disch_notes_instr%ROWTYPE,
handle_error_in IN BOOLEAN := TRUE,
rows_out        IN OUT table_varchar
)
is
begin
upd(
ID_DISCHARGE_NOTES_IN => rec_in.ID_DISCHARGE_NOTES,
ID_DISCH_INSTRUCTIONS_IN => rec_in.ID_DISCH_INSTRUCTIONS,
CREATE_USER_IN => rec_in.CREATE_USER,
CREATE_TIME_IN => rec_in.CREATE_TIME,
CREATE_INSTITUTION_IN => rec_in.CREATE_INSTITUTION,
UPDATE_USER_IN => rec_in.UPDATE_USER,
UPDATE_TIME_IN => rec_in.UPDATE_TIME,
UPDATE_INSTITUTION_IN => rec_in.UPDATE_INSTITUTION,
handle_error_in        => handle_error_in,
rows_out               => rows_out);
end upd;

--Update by record (without rows_out)
PROCEDURE upd
(
rec_in          IN disch_notes_instr%ROWTYPE,
handle_error_in IN BOOLEAN := TRUE
)
is
rows_out table_varchar;
begin
upd(
ID_DISCHARGE_NOTES_IN => rec_in.ID_DISCHARGE_NOTES,
ID_DISCH_INSTRUCTIONS_IN => rec_in.ID_DISCH_INSTRUCTIONS,
CREATE_USER_IN => rec_in.CREATE_USER,
CREATE_TIME_IN => rec_in.CREATE_TIME,
CREATE_INSTITUTION_IN => rec_in.CREATE_INSTITUTION,
UPDATE_USER_IN => rec_in.UPDATE_USER,
UPDATE_TIME_IN => rec_in.UPDATE_TIME,
UPDATE_INSTITUTION_IN => rec_in.UPDATE_INSTITUTION,
handle_error_in        => handle_error_in,
rows_out               => rows_out);
end upd;

--Update with collection (with rows_out)
PROCEDURE upd
(
col_in            IN disch_notes_instr_tc,
ignore_if_null_in IN BOOLEAN := TRUE,
handle_error_in   IN BOOLEAN := TRUE,
rows_out          IN OUT table_varchar
)
is
l_ID_DISCHARGE_NOTES ID_DISCHARGE_NOTES_CC;
l_ID_DISCH_INSTRUCTIONS ID_DISCH_INSTRUCTIONS_CC;
l_CREATE_USER CREATE_USER_CC;
l_CREATE_TIME CREATE_TIME_CC;
l_CREATE_INSTITUTION CREATE_INSTITUTION_CC;
l_UPDATE_USER UPDATE_USER_CC;
l_UPDATE_TIME UPDATE_TIME_CC;
l_UPDATE_INSTITUTION UPDATE_INSTITUTION_CC;
begin
FOR i IN col_in.FIRST .. col_in.LAST
LOOP
l_ID_DISCHARGE_NOTES(i) := col_in(i).ID_DISCHARGE_NOTES;
l_ID_DISCH_INSTRUCTIONS(i) := col_in(i).ID_DISCH_INSTRUCTIONS;
l_CREATE_USER(i) := col_in(i).CREATE_USER;
l_CREATE_TIME(i) := col_in(i).CREATE_TIME;
l_CREATE_INSTITUTION(i) := col_in(i).CREATE_INSTITUTION;
l_UPDATE_USER(i) := col_in(i).UPDATE_USER;
l_UPDATE_TIME(i) := col_in(i).UPDATE_TIME;
l_UPDATE_INSTITUTION(i) := col_in(i).UPDATE_INSTITUTION;
END LOOP;
IF nvl(ignore_if_null_in, FALSE)
THEN
-- Set any columns to their current values
-- if incoming value is NULL.
-- Put WHEN clause on column-level triggers!
FORALL i IN col_in.FIRST .. col_in.LAST
UPDATE disch_notes_instr
SET 
CREATE_USER = nvl(l_CREATE_USER(i), CREATE_USER),
CREATE_TIME = nvl(l_CREATE_TIME(i), CREATE_TIME),
CREATE_INSTITUTION = nvl(l_CREATE_INSTITUTION(i), CREATE_INSTITUTION),
UPDATE_USER = nvl(l_UPDATE_USER(i), UPDATE_USER),
UPDATE_TIME = nvl(l_UPDATE_TIME(i), UPDATE_TIME),
UPDATE_INSTITUTION = nvl(l_UPDATE_INSTITUTION(i), UPDATE_INSTITUTION)
 WHERE 
ID_DISCHARGE_NOTES = l_ID_DISCHARGE_NOTES(i)
 AND ID_DISCH_INSTRUCTIONS = l_ID_DISCH_INSTRUCTIONS(i)
 returning rowid bulk collect into rows_out;
ELSE
FORALL i IN col_in.FIRST .. col_in.LAST
UPDATE disch_notes_instr
SET 
CREATE_USER = l_CREATE_USER(i),
CREATE_TIME = l_CREATE_TIME(i),
CREATE_INSTITUTION = l_CREATE_INSTITUTION(i),
UPDATE_USER = l_UPDATE_USER(i),
UPDATE_TIME = l_UPDATE_TIME(i),
UPDATE_INSTITUTION = l_UPDATE_INSTITUTION(i)
 WHERE 
ID_DISCHARGE_NOTES = l_ID_DISCHARGE_NOTES(i)
 AND ID_DISCH_INSTRUCTIONS = l_ID_DISCH_INSTRUCTIONS(i)
 returning rowid bulk collect into rows_out;
END IF;

EXCEPTION
WHEN e_forall_error THEN
IF NOT handle_error_in
THEN
RAISE;
ELSE
FOR indx IN 1 .. SQL%BULK_EXCEPTIONS.COUNT
LOOP
pk_alertlog.log_info('DML error ignored: ' || SQLCODE || ': ' || SQLERRM);
END LOOP;
END IF;
WHEN OTHERS THEN
IF NOT handle_error_in
THEN
RAISE;
ELSE
pk_alertlog.log_info('DML error ignored: ' || SQLCODE || ': ' || SQLERRM);
END IF;

end upd;

--Update with collection (without rows_out)
PROCEDURE upd
(
col_in            IN disch_notes_instr_tc,
ignore_if_null_in IN BOOLEAN := TRUE,
handle_error_in   IN BOOLEAN := TRUE
)
is
rows_out table_varchar;
begin
upd(col_in, ignore_if_null_in, handle_error_in, rows_out);
end upd;

--Dynamic update string
FUNCTION dynupdstr
(
colname_in IN all_tab_columns.column_name%TYPE,
where_in   IN VARCHAR2 := NULL
)
RETURN VARCHAR2 IS
BEGIN
RETURN 'BEGIN UPDATE disch_notes_instr
SET ' || colname_in || ' = :value
 WHERE ' || nvl(where_in, '1=1') || ' RETURNING ROWID BULK COLLECT INTO :rows_out; END;';
END dynupdstr;

-- Use Native Dynamic SQL increment a single NUMBER column
-- for all rows specified by the dynamic WHERE clause (with rows_out)
PROCEDURE increment_onecol
(
colname_in         IN all_tab_columns.column_name%TYPE,
where_in           IN VARCHAR2,
increment_value_in IN NUMBER DEFAULT 1,
handle_error_in    IN BOOLEAN := TRUE,
rows_out           OUT table_varchar
)
is
begin
EXECUTE IMMEDIATE 'BEGIN UPDATE disch_notes_instr
SET ' || colname_in || '=' || colname_in || '+' || nvl(increment_value_in,1) ||
' WHERE ' || nvl(where_in, '1=1') || ' RETURNING ROWID BULK COLLECT INTO :rows_out; END;'
USING OUT rows_out;
end increment_onecol;

-- Use Native Dynamic SQL increment a single NUMBER column
-- for all rows specified by the dynamic WHERE clause (without rows_out)
PROCEDURE increment_onecol
(
colname_in         IN all_tab_columns.column_name%TYPE,
where_in           IN VARCHAR2,
increment_value_in IN NUMBER DEFAULT 1,
handle_error_in    IN BOOLEAN := TRUE
)
is
rows_out table_varchar;
begin
EXECUTE IMMEDIATE 'UPDATE disch_notes_instr
SET ' || colname_in || '=' || colname_in || '+' || nvl(increment_value_in,1) ||
' WHERE ' || nvl(where_in, '1=1');
end increment_onecol;

-- Delete one row by primary key
PROCEDURE del
(
ID_DISCHARGE_NOTES_in IN disch_notes_instr.ID_DISCHARGE_NOTES%TYPE,
ID_DISCH_INSTRUCTIONS_in IN disch_notes_instr.ID_DISCH_INSTRUCTIONS%TYPE,
handle_error_in IN BOOLEAN := TRUE,
rows_out        OUT table_varchar
)
is
begin
DELETE FROM disch_notes_instr
 WHERE
ID_DISCHARGE_NOTES = ID_DISCHARGE_NOTES_IN AND 
ID_DISCH_INSTRUCTIONS = ID_DISCH_INSTRUCTIONS_IN
 RETURNING ROWID BULK COLLECT INTO rows_out;

EXCEPTION
WHEN e_null_column_value
OR e_existing_fky_reference
OR e_check_constraint_failure
OR e_no_parent_key
OR e_child_record_found
OR e_forall_error
OR e_integ_constraint_failure THEN
IF NOT handle_error_in
THEN
RAISE;
ELSE
pk_alertlog.log_info('DML error ignored: ' || SQLCODE || ': ' || SQLERRM);
END IF;

end del;

-- Delete one row by primary key
PROCEDURE del
(
ID_DISCHARGE_NOTES_in IN disch_notes_instr.ID_DISCHARGE_NOTES%TYPE,
ID_DISCH_INSTRUCTIONS_in IN disch_notes_instr.ID_DISCH_INSTRUCTIONS%TYPE,
handle_error_in        IN BOOLEAN := TRUE
)
is
rows_out table_varchar;
begin
del(
ID_DISCHARGE_NOTES_IN => ID_DISCHARGE_NOTES_IN,
ID_DISCH_INSTRUCTIONS_IN => ID_DISCH_INSTRUCTIONS_IN,
handle_error_in        => handle_error_in,
rows_out               => rows_out);
end del;

-- Delete all rows for this DNI_DI_FK foreign key value
PROCEDURE del_DNI_DI_FK
(
ID_DISCH_INSTRUCTIONS_in IN DISCH_NOTES_INSTR.ID_DISCH_INSTRUCTIONS%TYPE,
handle_error_in IN BOOLEAN := TRUE,
rows_out        OUT table_varchar
)
is
begin
DELETE FROM disch_notes_instr
 WHERE
ID_DISCH_INSTRUCTIONS = ID_DISCH_INSTRUCTIONS_in
 RETURNING ROWID BULK COLLECT INTO rows_out;

EXCEPTION
WHEN e_null_column_value
OR e_existing_fky_reference
OR e_check_constraint_failure
OR e_no_parent_key
OR e_child_record_found
OR e_forall_error
OR e_integ_constraint_failure THEN
IF NOT handle_error_in
THEN
RAISE;
ELSE
pk_alertlog.log_info('DML error ignored: ' || SQLCODE || ': ' || SQLERRM);
END IF;

end del_DNI_DI_FK;

-- Delete all rows for this DNI_DN_FK foreign key value
PROCEDURE del_DNI_DN_FK
(
ID_DISCHARGE_NOTES_in IN DISCH_NOTES_INSTR.ID_DISCHARGE_NOTES%TYPE,
handle_error_in IN BOOLEAN := TRUE,
rows_out        OUT table_varchar
)
is
begin
DELETE FROM disch_notes_instr
 WHERE
ID_DISCHARGE_NOTES = ID_DISCHARGE_NOTES_in
 RETURNING ROWID BULK COLLECT INTO rows_out;

EXCEPTION
WHEN e_null_column_value
OR e_existing_fky_reference
OR e_check_constraint_failure
OR e_no_parent_key
OR e_child_record_found
OR e_forall_error
OR e_integ_constraint_failure THEN
IF NOT handle_error_in
THEN
RAISE;
ELSE
pk_alertlog.log_info('DML error ignored: ' || SQLCODE || ': ' || SQLERRM);
END IF;

end del_DNI_DN_FK;

-- Delete all rows for this DNI_DI_FK foreign key value
PROCEDURE del_DNI_DI_FK
(
ID_DISCH_INSTRUCTIONS_in IN DISCH_NOTES_INSTR.ID_DISCH_INSTRUCTIONS%TYPE,
handle_error_in IN BOOLEAN := TRUE
)
is
rows_out table_varchar;
begin
 del_DNI_DI_FK(
ID_DISCH_INSTRUCTIONS_IN => ID_DISCH_INSTRUCTIONS_IN,
handle_error_in        => handle_error_in,
rows_out               => rows_out);
end del_DNI_DI_FK;

-- Delete all rows for this DNI_DN_FK foreign key value
PROCEDURE del_DNI_DN_FK
(
ID_DISCHARGE_NOTES_in IN DISCH_NOTES_INSTR.ID_DISCHARGE_NOTES%TYPE,
handle_error_in IN BOOLEAN := TRUE
)
is
rows_out table_varchar;
begin
 del_DNI_DN_FK(
ID_DISCHARGE_NOTES_IN => ID_DISCHARGE_NOTES_IN,
handle_error_in        => handle_error_in,
rows_out               => rows_out);
end del_DNI_DN_FK;

-- Deletions using dynamic SQL
FUNCTION dyndelstr
(
where_in IN VARCHAR2
)
 RETURN VARCHAR2 is 
begin
IF where_in IS NULL
THEN
RETURN 'DELETE FROM disch_notes_instr';
ELSE
RETURN 'DELETE FROM disch_notes_instr WHERE ' || where_in;
END IF;
end dyndelstr;
-- Delete all rows specified by dynamic WHERE clause
PROCEDURE del_by
(
where_clause_in IN VARCHAR2,
handle_error_in IN BOOLEAN := TRUE,
rows_out        OUT table_varchar
)
is
begin
EXECUTE IMMEDIATE 'BEGIN ' || dyndelstr (where_clause_in) || ' RETURNING ROWID BULK COLLECT INTO :rows_out; END;' using OUT rows_out;

EXCEPTION
WHEN e_null_column_value
OR e_existing_fky_reference
OR e_check_constraint_failure
OR e_no_parent_key
OR e_child_record_found
OR e_forall_error
OR e_integ_constraint_failure THEN
IF NOT handle_error_in
THEN
RAISE;
ELSE
pk_alertlog.log_info('DML error ignored: ' || SQLCODE || ': ' || SQLERRM);
END IF;

end del_by;

-- Delete all rows specified by dynamic WHERE clause
PROCEDURE del_by
(
where_clause_in IN VARCHAR2,
handle_error_in IN BOOLEAN := TRUE
)
is
begin
EXECUTE IMMEDIATE dyndelstr (where_clause_in);

EXCEPTION
WHEN e_null_column_value
OR e_existing_fky_reference
OR e_check_constraint_failure
OR e_no_parent_key
OR e_child_record_found
OR e_forall_error
OR e_integ_constraint_failure THEN
IF NOT handle_error_in
THEN
RAISE;
ELSE
pk_alertlog.log_info('DML error ignored: ' || SQLCODE || ': ' || SQLERRM);
END IF;

end del_by;

-- Initialize a record with default values for columns in the table (prc)
PROCEDURE initrec(disch_notes_instr_inout IN OUT disch_notes_instr%ROWTYPE)
is
begin
disch_notes_instr_inout.ID_DISCHARGE_NOTES := NULL;
disch_notes_instr_inout.ID_DISCH_INSTRUCTIONS := NULL;
disch_notes_instr_inout.CREATE_USER := NULL;
disch_notes_instr_inout.CREATE_TIME := NULL;
disch_notes_instr_inout.CREATE_INSTITUTION := NULL;
disch_notes_instr_inout.UPDATE_USER := NULL;
disch_notes_instr_inout.UPDATE_TIME := NULL;
disch_notes_instr_inout.UPDATE_INSTITUTION := NULL;
end initrec;

-- Initialize a record with default values for columns in the table (fnc)
FUNCTION initrec RETURN disch_notes_instr%ROWTYPE
is
l_disch_notes_instr disch_notes_instr%ROWTYPE;
begin
return l_disch_notes_instr;
end initrec;

--get data from rowid
FUNCTION get_data_rowid(rows_in IN table_varchar) RETURN disch_notes_instr_tc
is
data disch_notes_instr_tc;
begin
select * bulk collect into data from disch_notes_instr
 WHERE rowid in (select /*+opt_estimate(table,t,scale_rows=0.0000001))*/ * from table(rows_in) t);
return data;
end get_data_rowid;

--get data from rowid (pragma autonomous transacion)
FUNCTION get_data_rowid_pat(rows_in IN table_varchar) RETURN disch_notes_instr_tc
is
data disch_notes_instr_tc;
PRAGMA AUTONOMOUS_TRANSACTION;
begin
data := get_data_rowid(rows_in);
commit;
return data;

EXCEPTION
WHEN others
THEN
pk_alert_exceptions.raise_error(error_name_in => 'get_data_rowid_pat');
ROLLBACK;

end get_data_rowid_pat;

BEGIN
NULL;
END ts_disch_notes_instr;
