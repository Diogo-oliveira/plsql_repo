/*-- Last Change Revision: $Rev: 1766233 $*/
/*-- Last Change by: $Author: carlos.ferreira $*/
/*-- Date of last change: $Date: 2017-01-16 11:21:23 +0000 (seg, 16 jan 2017) $*/
CREATE OR REPLACE PACKAGE BODY ts_sys_list
/*
| Generated by or retrieved - DO NOT MODIFY!
| Created On: 2016-12-07 14:46:01
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

FUNCTION next_key(sequence_in IN VARCHAR2 := NULL) RETURN sys_list.ID_SYS_LIST%TYPE
IS
retval sys_list.ID_SYS_LIST%TYPE;
BEGIN
IF sequence_in IS NULL
THEN
retval := seq_sys_list.NEXTVAL;
ELSE
EXECUTE IMMEDIATE 'SELECT ' || sequence_in || '.NEXTVAL FROM dual'
INTO retval;
END IF;
RETURN retval;
END next_key;

-- Insert one row, generating hidden primary key using a sequence
PROCEDURE ins
(
CODE_SYS_LIST_in IN SYS_LIST.CODE_SYS_LIST%TYPE DEFAULT NULL,
IMG_NAME_in IN SYS_LIST.IMG_NAME%TYPE DEFAULT NULL,
CREATE_USER_in IN SYS_LIST.CREATE_USER%TYPE DEFAULT NULL,
CREATE_TIME_in IN SYS_LIST.CREATE_TIME%TYPE DEFAULT NULL,
CREATE_INSTITUTION_in IN SYS_LIST.CREATE_INSTITUTION%TYPE DEFAULT NULL,
UPDATE_USER_in IN SYS_LIST.UPDATE_USER%TYPE DEFAULT NULL,
UPDATE_TIME_in IN SYS_LIST.UPDATE_TIME%TYPE DEFAULT NULL,
UPDATE_INSTITUTION_in IN SYS_LIST.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
INTERNAL_NAME_in IN SYS_LIST.INTERNAL_NAME%TYPE DEFAULT NULL,
-- Pass false if you want errors to propagate out unhandled
handle_error_in IN BOOLEAN := TRUE,
rows_out        OUT table_varchar
)
IS
l_pky sys_list.ID_SYS_LIST%TYPE := next_key;
BEGIN
ins(
ID_SYS_LIST_IN => l_pky,
CODE_SYS_LIST_IN => CODE_SYS_LIST_IN,
IMG_NAME_IN => IMG_NAME_IN,
CREATE_USER_IN => CREATE_USER_IN,
CREATE_TIME_IN => CREATE_TIME_IN,
CREATE_INSTITUTION_IN => CREATE_INSTITUTION_IN,
UPDATE_USER_IN => UPDATE_USER_IN,
UPDATE_TIME_IN => UPDATE_TIME_IN,
UPDATE_INSTITUTION_IN => UPDATE_INSTITUTION_IN,
INTERNAL_NAME_IN => INTERNAL_NAME_IN,
handle_error_in       => handle_error_in,
rows_out              => rows_out);
END ins;

-- Insert one row, generating hidden primary key using a sequence
PROCEDURE ins
(
CODE_SYS_LIST_in IN SYS_LIST.CODE_SYS_LIST%TYPE DEFAULT NULL,
IMG_NAME_in IN SYS_LIST.IMG_NAME%TYPE DEFAULT NULL,
CREATE_USER_in IN SYS_LIST.CREATE_USER%TYPE DEFAULT NULL,
CREATE_TIME_in IN SYS_LIST.CREATE_TIME%TYPE DEFAULT NULL,
CREATE_INSTITUTION_in IN SYS_LIST.CREATE_INSTITUTION%TYPE DEFAULT NULL,
UPDATE_USER_in IN SYS_LIST.UPDATE_USER%TYPE DEFAULT NULL,
UPDATE_TIME_in IN SYS_LIST.UPDATE_TIME%TYPE DEFAULT NULL,
UPDATE_INSTITUTION_in IN SYS_LIST.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
INTERNAL_NAME_in IN SYS_LIST.INTERNAL_NAME%TYPE DEFAULT NULL,
-- Pass false if you want errors to propagate out unhandled
handle_error_in IN BOOLEAN := TRUE
)
IS
rows_out table_varchar;
BEGIN
ins(
CODE_SYS_LIST_IN => CODE_SYS_LIST_IN,
IMG_NAME_IN => IMG_NAME_IN,
CREATE_USER_IN => CREATE_USER_IN,
CREATE_TIME_IN => CREATE_TIME_IN,
CREATE_INSTITUTION_IN => CREATE_INSTITUTION_IN,
UPDATE_USER_IN => UPDATE_USER_IN,
UPDATE_TIME_IN => UPDATE_TIME_IN,
UPDATE_INSTITUTION_IN => UPDATE_INSTITUTION_IN,
INTERNAL_NAME_IN => INTERNAL_NAME_IN,
handle_error_in       => handle_error_in,
rows_out              => rows_out);
END ins;

-- Insert one row, returning primary key generated by sequence
PROCEDURE ins
(
CODE_SYS_LIST_in IN SYS_LIST.CODE_SYS_LIST%TYPE DEFAULT NULL,
IMG_NAME_in IN SYS_LIST.IMG_NAME%TYPE DEFAULT NULL,
CREATE_USER_in IN SYS_LIST.CREATE_USER%TYPE DEFAULT NULL,
CREATE_TIME_in IN SYS_LIST.CREATE_TIME%TYPE DEFAULT NULL,
CREATE_INSTITUTION_in IN SYS_LIST.CREATE_INSTITUTION%TYPE DEFAULT NULL,
UPDATE_USER_in IN SYS_LIST.UPDATE_USER%TYPE DEFAULT NULL,
UPDATE_TIME_in IN SYS_LIST.UPDATE_TIME%TYPE DEFAULT NULL,
UPDATE_INSTITUTION_in IN SYS_LIST.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
INTERNAL_NAME_in IN SYS_LIST.INTERNAL_NAME%TYPE DEFAULT NULL,
ID_SYS_LIST_OUT IN OUT sys_list.ID_SYS_LIST%TYPE,
-- Pass false if you want errors to propagate out unhandled
handle_error_in IN BOOLEAN := TRUE,
rows_out        OUT table_varchar
)
IS
l_pky sys_list.ID_SYS_LIST%TYPE := next_key;
BEGIN
ins(
ID_SYS_LIST_IN => l_pky,
CODE_SYS_LIST_IN => CODE_SYS_LIST_IN,
IMG_NAME_IN => IMG_NAME_IN,
CREATE_USER_IN => CREATE_USER_IN,
CREATE_TIME_IN => CREATE_TIME_IN,
CREATE_INSTITUTION_IN => CREATE_INSTITUTION_IN,
UPDATE_USER_IN => UPDATE_USER_IN,
UPDATE_TIME_IN => UPDATE_TIME_IN,
UPDATE_INSTITUTION_IN => UPDATE_INSTITUTION_IN,
INTERNAL_NAME_IN => INTERNAL_NAME_IN,
handle_error_in       => handle_error_in,
rows_out              => rows_out);
ID_SYS_LIST_OUT := l_pky;
END ins;

-- Insert one row, returning primary key generated by sequence
PROCEDURE ins
(
CODE_SYS_LIST_in IN SYS_LIST.CODE_SYS_LIST%TYPE DEFAULT NULL,
IMG_NAME_in IN SYS_LIST.IMG_NAME%TYPE DEFAULT NULL,
CREATE_USER_in IN SYS_LIST.CREATE_USER%TYPE DEFAULT NULL,
CREATE_TIME_in IN SYS_LIST.CREATE_TIME%TYPE DEFAULT NULL,
CREATE_INSTITUTION_in IN SYS_LIST.CREATE_INSTITUTION%TYPE DEFAULT NULL,
UPDATE_USER_in IN SYS_LIST.UPDATE_USER%TYPE DEFAULT NULL,
UPDATE_TIME_in IN SYS_LIST.UPDATE_TIME%TYPE DEFAULT NULL,
UPDATE_INSTITUTION_in IN SYS_LIST.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
INTERNAL_NAME_in IN SYS_LIST.INTERNAL_NAME%TYPE DEFAULT NULL,
ID_SYS_LIST_OUT IN OUT sys_list.ID_SYS_LIST%TYPE,
-- Pass false if you want errors to propagate out unhandled
handle_error_in IN BOOLEAN := TRUE
)
IS
rows_out table_varchar;
BEGIN
ins(
CODE_SYS_LIST_IN => CODE_SYS_LIST_IN,
IMG_NAME_IN => IMG_NAME_IN,
CREATE_USER_IN => CREATE_USER_IN,
CREATE_TIME_IN => CREATE_TIME_IN,
CREATE_INSTITUTION_IN => CREATE_INSTITUTION_IN,
UPDATE_USER_IN => UPDATE_USER_IN,
UPDATE_TIME_IN => UPDATE_TIME_IN,
UPDATE_INSTITUTION_IN => UPDATE_INSTITUTION_IN,
INTERNAL_NAME_IN => INTERNAL_NAME_IN,
ID_SYS_LIST_OUT => ID_SYS_LIST_OUT,
handle_error_in       => handle_error_in,
rows_out              => rows_out);
END ins;

-- Insert one row with function, return generated primary key
FUNCTION ins
(
CODE_SYS_LIST_in IN SYS_LIST.CODE_SYS_LIST%TYPE DEFAULT NULL,
IMG_NAME_in IN SYS_LIST.IMG_NAME%TYPE DEFAULT NULL,
CREATE_USER_in IN SYS_LIST.CREATE_USER%TYPE DEFAULT NULL,
CREATE_TIME_in IN SYS_LIST.CREATE_TIME%TYPE DEFAULT NULL,
CREATE_INSTITUTION_in IN SYS_LIST.CREATE_INSTITUTION%TYPE DEFAULT NULL,
UPDATE_USER_in IN SYS_LIST.UPDATE_USER%TYPE DEFAULT NULL,
UPDATE_TIME_in IN SYS_LIST.UPDATE_TIME%TYPE DEFAULT NULL,
UPDATE_INSTITUTION_in IN SYS_LIST.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
INTERNAL_NAME_in IN SYS_LIST.INTERNAL_NAME%TYPE DEFAULT NULL,
-- Pass false if you want errors to propagate out unhandled
handle_error_in IN BOOLEAN := TRUE,
rows_out        OUT table_varchar
) RETURN sys_list.ID_SYS_LIST%TYPE
IS
l_pky sys_list.ID_SYS_LIST%TYPE := next_key;
BEGIN
ins(
ID_SYS_LIST_IN => l_pky,
CODE_SYS_LIST_IN => CODE_SYS_LIST_IN,
IMG_NAME_IN => IMG_NAME_IN,
CREATE_USER_IN => CREATE_USER_IN,
CREATE_TIME_IN => CREATE_TIME_IN,
CREATE_INSTITUTION_IN => CREATE_INSTITUTION_IN,
UPDATE_USER_IN => UPDATE_USER_IN,
UPDATE_TIME_IN => UPDATE_TIME_IN,
UPDATE_INSTITUTION_IN => UPDATE_INSTITUTION_IN,
INTERNAL_NAME_IN => INTERNAL_NAME_IN,
handle_error_in       => handle_error_in,
rows_out              => rows_out);
RETURN l_pky;
END ins;

-- Insert one row with function, return generated primary key
FUNCTION ins
(
CODE_SYS_LIST_in IN SYS_LIST.CODE_SYS_LIST%TYPE DEFAULT NULL,
IMG_NAME_in IN SYS_LIST.IMG_NAME%TYPE DEFAULT NULL,
CREATE_USER_in IN SYS_LIST.CREATE_USER%TYPE DEFAULT NULL,
CREATE_TIME_in IN SYS_LIST.CREATE_TIME%TYPE DEFAULT NULL,
CREATE_INSTITUTION_in IN SYS_LIST.CREATE_INSTITUTION%TYPE DEFAULT NULL,
UPDATE_USER_in IN SYS_LIST.UPDATE_USER%TYPE DEFAULT NULL,
UPDATE_TIME_in IN SYS_LIST.UPDATE_TIME%TYPE DEFAULT NULL,
UPDATE_INSTITUTION_in IN SYS_LIST.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
INTERNAL_NAME_in IN SYS_LIST.INTERNAL_NAME%TYPE DEFAULT NULL,
-- Pass false if you want errors to propagate out unhandled
handle_error_in IN BOOLEAN := TRUE
) RETURN sys_list.ID_SYS_LIST%TYPE
IS
l_pky    sys_list.ID_SYS_LIST%TYPE := next_key;
rows_out table_varchar;
BEGIN
ins(
ID_SYS_LIST_IN => l_pky,
CODE_SYS_LIST_IN => CODE_SYS_LIST_IN,
IMG_NAME_IN => IMG_NAME_IN,
CREATE_USER_IN => CREATE_USER_IN,
CREATE_TIME_IN => CREATE_TIME_IN,
CREATE_INSTITUTION_IN => CREATE_INSTITUTION_IN,
UPDATE_USER_IN => UPDATE_USER_IN,
UPDATE_TIME_IN => UPDATE_TIME_IN,
UPDATE_INSTITUTION_IN => UPDATE_INSTITUTION_IN,
INTERNAL_NAME_IN => INTERNAL_NAME_IN,
handle_error_in       => handle_error_in,
rows_out              => rows_out);
RETURN l_pky;
END ins;

PROCEDURE ins
(
ID_SYS_LIST_in IN sys_list.ID_SYS_LIST%TYPE,
CODE_SYS_LIST_in IN SYS_LIST.CODE_SYS_LIST%TYPE DEFAULT NULL,
IMG_NAME_in IN SYS_LIST.IMG_NAME%TYPE DEFAULT NULL,
CREATE_USER_in IN SYS_LIST.CREATE_USER%TYPE DEFAULT NULL,
CREATE_TIME_in IN SYS_LIST.CREATE_TIME%TYPE DEFAULT NULL,
CREATE_INSTITUTION_in IN SYS_LIST.CREATE_INSTITUTION%TYPE DEFAULT NULL,
UPDATE_USER_in IN SYS_LIST.UPDATE_USER%TYPE DEFAULT NULL,
UPDATE_TIME_in IN SYS_LIST.UPDATE_TIME%TYPE DEFAULT NULL,
UPDATE_INSTITUTION_in IN SYS_LIST.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
INTERNAL_NAME_in IN SYS_LIST.INTERNAL_NAME%TYPE DEFAULT NULL,
handle_error_in IN BOOLEAN := TRUE,
rows_out OUT table_varchar
) IS
BEGIN
INSERT INTO sys_list
(
ID_SYS_LIST,
CODE_SYS_LIST,
IMG_NAME,
CREATE_USER,
CREATE_TIME,
CREATE_INSTITUTION,
UPDATE_USER,
UPDATE_TIME,
UPDATE_INSTITUTION,
INTERNAL_NAME
)
 VALUES
(
ID_SYS_LIST_IN,
CODE_SYS_LIST_IN,
IMG_NAME_IN,
CREATE_USER_IN,
CREATE_TIME_IN,
CREATE_INSTITUTION_IN,
UPDATE_USER_IN,
UPDATE_TIME_IN,
UPDATE_INSTITUTION_IN,
INTERNAL_NAME_IN
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
ID_SYS_LIST_in IN sys_list.ID_SYS_LIST%TYPE,
CODE_SYS_LIST_in IN SYS_LIST.CODE_SYS_LIST%TYPE DEFAULT NULL,
IMG_NAME_in IN SYS_LIST.IMG_NAME%TYPE DEFAULT NULL,
CREATE_USER_in IN SYS_LIST.CREATE_USER%TYPE DEFAULT NULL,
CREATE_TIME_in IN SYS_LIST.CREATE_TIME%TYPE DEFAULT NULL,
CREATE_INSTITUTION_in IN SYS_LIST.CREATE_INSTITUTION%TYPE DEFAULT NULL,
UPDATE_USER_in IN SYS_LIST.UPDATE_USER%TYPE DEFAULT NULL,
UPDATE_TIME_in IN SYS_LIST.UPDATE_TIME%TYPE DEFAULT NULL,
UPDATE_INSTITUTION_in IN SYS_LIST.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
INTERNAL_NAME_in IN SYS_LIST.INTERNAL_NAME%TYPE DEFAULT NULL,
handle_error_in IN BOOLEAN := TRUE
) IS
rows_out table_varchar;
BEGIN
ins(
ID_SYS_LIST_IN => ID_SYS_LIST_IN,
CODE_SYS_LIST_IN => CODE_SYS_LIST_IN,
IMG_NAME_IN => IMG_NAME_IN,
CREATE_USER_IN => CREATE_USER_IN,
CREATE_TIME_IN => CREATE_TIME_IN,
CREATE_INSTITUTION_IN => CREATE_INSTITUTION_IN,
UPDATE_USER_IN => UPDATE_USER_IN,
UPDATE_TIME_IN => UPDATE_TIME_IN,
UPDATE_INSTITUTION_IN => UPDATE_INSTITUTION_IN,
INTERNAL_NAME_IN => INTERNAL_NAME_IN,
handle_error_in => handle_error_in,
rows_out => rows_out);
END ins;

PROCEDURE ins
(
rec_in          IN sys_list%ROWTYPE,
gen_pky_in      IN BOOLEAN DEFAULT FALSE,
sequence_in     IN VARCHAR2 := NULL,
handle_error_in IN BOOLEAN := TRUE,
rows_out        OUT table_varchar
) IS
l_rec sys_list%ROWTYPE := rec_in;
BEGIN
IF gen_pky_in
THEN
l_rec.ID_SYS_LIST := next_key(sequence_in);
END IF;

ins(
ID_SYS_LIST_IN => l_rec.ID_SYS_LIST,
CODE_SYS_LIST_IN => l_rec.CODE_SYS_LIST,
IMG_NAME_IN => l_rec.IMG_NAME,
CREATE_USER_IN => l_rec.CREATE_USER,
CREATE_TIME_IN => l_rec.CREATE_TIME,
CREATE_INSTITUTION_IN => l_rec.CREATE_INSTITUTION,
UPDATE_USER_IN => l_rec.UPDATE_USER,
UPDATE_TIME_IN => l_rec.UPDATE_TIME,
UPDATE_INSTITUTION_IN => l_rec.UPDATE_INSTITUTION,
INTERNAL_NAME_IN => l_rec.INTERNAL_NAME,
handle_error_in       => handle_error_in,
rows_out              => rows_out);
END ins;

PROCEDURE ins
(
rec_in          IN sys_list%ROWTYPE,
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
rows_in         IN sys_list_tc,
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
INSERT INTO sys_list
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
rows_in         IN sys_list_tc,
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
ID_SYS_LIST_in IN sys_list.ID_SYS_LIST%TYPE,
CODE_SYS_LIST_in IN SYS_LIST.CODE_SYS_LIST%TYPE DEFAULT NULL,
CODE_SYS_LIST_nin IN BOOLEAN := TRUE,
IMG_NAME_in IN SYS_LIST.IMG_NAME%TYPE DEFAULT NULL,
IMG_NAME_nin IN BOOLEAN := TRUE,
CREATE_USER_in IN SYS_LIST.CREATE_USER%TYPE DEFAULT NULL,
CREATE_USER_nin IN BOOLEAN := TRUE,
CREATE_TIME_in IN SYS_LIST.CREATE_TIME%TYPE DEFAULT NULL,
CREATE_TIME_nin IN BOOLEAN := TRUE,
CREATE_INSTITUTION_in IN SYS_LIST.CREATE_INSTITUTION%TYPE DEFAULT NULL,
CREATE_INSTITUTION_nin IN BOOLEAN := TRUE,
UPDATE_USER_in IN SYS_LIST.UPDATE_USER%TYPE DEFAULT NULL,
UPDATE_USER_nin IN BOOLEAN := TRUE,
UPDATE_TIME_in IN SYS_LIST.UPDATE_TIME%TYPE DEFAULT NULL,
UPDATE_TIME_nin IN BOOLEAN := TRUE,
UPDATE_INSTITUTION_in IN SYS_LIST.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
UPDATE_INSTITUTION_nin IN BOOLEAN := TRUE,
INTERNAL_NAME_in IN SYS_LIST.INTERNAL_NAME%TYPE DEFAULT NULL,
INTERNAL_NAME_nin IN BOOLEAN := TRUE,
handle_error_in        IN BOOLEAN := TRUE,
rows_out               IN OUT table_varchar
)
is
l_rows_out             table_varchar;
l_CODE_SYS_LIST_n number(1);
l_IMG_NAME_n number(1);
l_CREATE_USER_n number(1);
l_CREATE_TIME_n number(1);
l_CREATE_INSTITUTION_n number(1);
l_UPDATE_USER_n number(1);
l_UPDATE_TIME_n number(1);
l_UPDATE_INSTITUTION_n number(1);
l_INTERNAL_NAME_n number(1);
begin

UPDATE sys_list
SET
CODE_SYS_LIST = decode(l_CODE_SYS_LIST_n, 0, CODE_SYS_LIST_in, nvl(CODE_SYS_LIST_in, CODE_SYS_LIST)),
IMG_NAME = decode(l_IMG_NAME_n, 0, IMG_NAME_in, nvl(IMG_NAME_in, IMG_NAME)),
CREATE_USER = decode(l_CREATE_USER_n, 0, CREATE_USER_in, nvl(CREATE_USER_in, CREATE_USER)),
CREATE_TIME = decode(l_CREATE_TIME_n, 0, CREATE_TIME_in, nvl(CREATE_TIME_in, CREATE_TIME)),
CREATE_INSTITUTION = decode(l_CREATE_INSTITUTION_n, 0, CREATE_INSTITUTION_in, nvl(CREATE_INSTITUTION_in, CREATE_INSTITUTION)),
UPDATE_USER = decode(l_UPDATE_USER_n, 0, UPDATE_USER_in, nvl(UPDATE_USER_in, UPDATE_USER)),
UPDATE_TIME = decode(l_UPDATE_TIME_n, 0, UPDATE_TIME_in, nvl(UPDATE_TIME_in, UPDATE_TIME)),
UPDATE_INSTITUTION = decode(l_UPDATE_INSTITUTION_n, 0, UPDATE_INSTITUTION_in, nvl(UPDATE_INSTITUTION_in, UPDATE_INSTITUTION)),
INTERNAL_NAME = decode(l_INTERNAL_NAME_n, 0, INTERNAL_NAME_in, nvl(INTERNAL_NAME_in, INTERNAL_NAME))
 WHERE
ID_SYS_LIST = ID_SYS_LIST_IN
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
ID_SYS_LIST_in IN sys_list.ID_SYS_LIST%TYPE,
CODE_SYS_LIST_in IN SYS_LIST.CODE_SYS_LIST%TYPE DEFAULT NULL,
CODE_SYS_LIST_nin IN BOOLEAN := TRUE,
IMG_NAME_in IN SYS_LIST.IMG_NAME%TYPE DEFAULT NULL,
IMG_NAME_nin IN BOOLEAN := TRUE,
CREATE_USER_in IN SYS_LIST.CREATE_USER%TYPE DEFAULT NULL,
CREATE_USER_nin IN BOOLEAN := TRUE,
CREATE_TIME_in IN SYS_LIST.CREATE_TIME%TYPE DEFAULT NULL,
CREATE_TIME_nin IN BOOLEAN := TRUE,
CREATE_INSTITUTION_in IN SYS_LIST.CREATE_INSTITUTION%TYPE DEFAULT NULL,
CREATE_INSTITUTION_nin IN BOOLEAN := TRUE,
UPDATE_USER_in IN SYS_LIST.UPDATE_USER%TYPE DEFAULT NULL,
UPDATE_USER_nin IN BOOLEAN := TRUE,
UPDATE_TIME_in IN SYS_LIST.UPDATE_TIME%TYPE DEFAULT NULL,
UPDATE_TIME_nin IN BOOLEAN := TRUE,
UPDATE_INSTITUTION_in IN SYS_LIST.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
UPDATE_INSTITUTION_nin IN BOOLEAN := TRUE,
INTERNAL_NAME_in IN SYS_LIST.INTERNAL_NAME%TYPE DEFAULT NULL,
INTERNAL_NAME_nin IN BOOLEAN := TRUE,
handle_error_in        IN BOOLEAN := TRUE
)
is
rows_out table_varchar;
begin
upd(
ID_SYS_LIST_IN => ID_SYS_LIST_IN,
CODE_SYS_LIST_IN => CODE_SYS_LIST_IN,
CODE_SYS_LIST_NIN => CODE_SYS_LIST_NIN,
IMG_NAME_IN => IMG_NAME_IN,
IMG_NAME_NIN => IMG_NAME_NIN,
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
INTERNAL_NAME_IN => INTERNAL_NAME_IN,
INTERNAL_NAME_NIN => INTERNAL_NAME_NIN,
handle_error_in        => handle_error_in,
rows_out               => rows_out);
end upd;

--Update any/all columns by dynamic WHERE
-- If you pass NULL, then the current column value is set to itself
PROCEDURE upd
(
CODE_SYS_LIST_in IN SYS_LIST.CODE_SYS_LIST%TYPE DEFAULT NULL,
CODE_SYS_LIST_nin IN BOOLEAN := TRUE,
IMG_NAME_in IN SYS_LIST.IMG_NAME%TYPE DEFAULT NULL,
IMG_NAME_nin IN BOOLEAN := TRUE,
CREATE_USER_in IN SYS_LIST.CREATE_USER%TYPE DEFAULT NULL,
CREATE_USER_nin IN BOOLEAN := TRUE,
CREATE_TIME_in IN SYS_LIST.CREATE_TIME%TYPE DEFAULT NULL,
CREATE_TIME_nin IN BOOLEAN := TRUE,
CREATE_INSTITUTION_in IN SYS_LIST.CREATE_INSTITUTION%TYPE DEFAULT NULL,
CREATE_INSTITUTION_nin IN BOOLEAN := TRUE,
UPDATE_USER_in IN SYS_LIST.UPDATE_USER%TYPE DEFAULT NULL,
UPDATE_USER_nin IN BOOLEAN := TRUE,
UPDATE_TIME_in IN SYS_LIST.UPDATE_TIME%TYPE DEFAULT NULL,
UPDATE_TIME_nin IN BOOLEAN := TRUE,
UPDATE_INSTITUTION_in IN SYS_LIST.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
UPDATE_INSTITUTION_nin IN BOOLEAN := TRUE,
INTERNAL_NAME_in IN SYS_LIST.INTERNAL_NAME%TYPE DEFAULT NULL,
INTERNAL_NAME_nin IN BOOLEAN := TRUE,
where_in               IN VARCHAR2,
handle_error_in        IN BOOLEAN := TRUE,
rows_out               IN OUT table_varchar
)
is
l_sql                  VARCHAR2(32767);
l_rows_out             table_varchar;
l_CODE_SYS_LIST_n number(1);
l_IMG_NAME_n number(1);
l_CREATE_USER_n number(1);
l_CREATE_TIME_n number(1);
l_CREATE_INSTITUTION_n number(1);
l_UPDATE_USER_n number(1);
l_UPDATE_TIME_n number(1);
l_UPDATE_INSTITUTION_n number(1);
l_INTERNAL_NAME_n number(1);
begin
l_CODE_SYS_LIST_n := sys.diutil.bool_to_int(CODE_SYS_LIST_nin);
l_IMG_NAME_n := sys.diutil.bool_to_int(IMG_NAME_nin);
l_CREATE_USER_n := sys.diutil.bool_to_int(CREATE_USER_nin);
l_CREATE_TIME_n := sys.diutil.bool_to_int(CREATE_TIME_nin);
l_CREATE_INSTITUTION_n := sys.diutil.bool_to_int(CREATE_INSTITUTION_nin);
l_UPDATE_USER_n := sys.diutil.bool_to_int(UPDATE_USER_nin);
l_UPDATE_TIME_n := sys.diutil.bool_to_int(UPDATE_TIME_nin);
l_UPDATE_INSTITUTION_n := sys.diutil.bool_to_int(UPDATE_INSTITUTION_nin);
l_INTERNAL_NAME_n := sys.diutil.bool_to_int(INTERNAL_NAME_nin);
l_sql := 'UPDATE sys_list SET' ||
' CODE_SYS_LIST = decode (' || l_CODE_SYS_LIST_n || ',0,:CODE_SYS_LIST_in, NVL (:CODE_SYS_LIST_in, CODE_SYS_LIST)) ' ||',' ||
' IMG_NAME = decode (' || l_IMG_NAME_n || ',0,:IMG_NAME_in, NVL (:IMG_NAME_in, IMG_NAME)) ' ||',' ||
' CREATE_USER = decode (' || l_CREATE_USER_n || ',0,:CREATE_USER_in, NVL (:CREATE_USER_in, CREATE_USER)) ' ||',' ||
' CREATE_TIME = decode (' || l_CREATE_TIME_n || ',0,:CREATE_TIME_in, NVL (:CREATE_TIME_in, CREATE_TIME)) ' ||',' ||
' CREATE_INSTITUTION = decode (' || l_CREATE_INSTITUTION_n || ',0,:CREATE_INSTITUTION_in, NVL (:CREATE_INSTITUTION_in, CREATE_INSTITUTION)) ' ||',' ||
' UPDATE_USER = decode (' || l_UPDATE_USER_n || ',0,:UPDATE_USER_in, NVL (:UPDATE_USER_in, UPDATE_USER)) ' ||',' ||
' UPDATE_TIME = decode (' || l_UPDATE_TIME_n || ',0,:UPDATE_TIME_in, NVL (:UPDATE_TIME_in, UPDATE_TIME)) ' ||',' ||
' UPDATE_INSTITUTION = decode (' || l_UPDATE_INSTITUTION_n || ',0,:UPDATE_INSTITUTION_in, NVL (:UPDATE_INSTITUTION_in, UPDATE_INSTITUTION)) ' ||',' ||
' INTERNAL_NAME = decode (' || l_INTERNAL_NAME_n || ',0,:INTERNAL_NAME_in, NVL (:INTERNAL_NAME_in, INTERNAL_NAME)) ' ||
' where ' || nvl(where_in, '(1=1)') || ' RETURNING ROWID BULK COLLECT INTO :l_rows_out';
EXECUTE IMMEDIATE 'BEGIN ' || l_sql || '; END;'
USING IN
CODE_SYS_LIST_IN,
IMG_NAME_IN,
CREATE_USER_IN,
CREATE_TIME_IN,
CREATE_INSTITUTION_IN,
UPDATE_USER_IN,
UPDATE_TIME_IN,
UPDATE_INSTITUTION_IN,
INTERNAL_NAME_IN,
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
CODE_SYS_LIST_in IN SYS_LIST.CODE_SYS_LIST%TYPE DEFAULT NULL,
CODE_SYS_LIST_nin IN BOOLEAN := TRUE,
IMG_NAME_in IN SYS_LIST.IMG_NAME%TYPE DEFAULT NULL,
IMG_NAME_nin IN BOOLEAN := TRUE,
CREATE_USER_in IN SYS_LIST.CREATE_USER%TYPE DEFAULT NULL,
CREATE_USER_nin IN BOOLEAN := TRUE,
CREATE_TIME_in IN SYS_LIST.CREATE_TIME%TYPE DEFAULT NULL,
CREATE_TIME_nin IN BOOLEAN := TRUE,
CREATE_INSTITUTION_in IN SYS_LIST.CREATE_INSTITUTION%TYPE DEFAULT NULL,
CREATE_INSTITUTION_nin IN BOOLEAN := TRUE,
UPDATE_USER_in IN SYS_LIST.UPDATE_USER%TYPE DEFAULT NULL,
UPDATE_USER_nin IN BOOLEAN := TRUE,
UPDATE_TIME_in IN SYS_LIST.UPDATE_TIME%TYPE DEFAULT NULL,
UPDATE_TIME_nin IN BOOLEAN := TRUE,
UPDATE_INSTITUTION_in IN SYS_LIST.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
UPDATE_INSTITUTION_nin IN BOOLEAN := TRUE,
INTERNAL_NAME_in IN SYS_LIST.INTERNAL_NAME%TYPE DEFAULT NULL,
INTERNAL_NAME_nin IN BOOLEAN := TRUE,
where_in               IN VARCHAR2,
handle_error_in        IN BOOLEAN := TRUE
)
is
rows_out table_varchar;
begin
upd(
CODE_SYS_LIST_IN => CODE_SYS_LIST_IN,
CODE_SYS_LIST_NIN => CODE_SYS_LIST_NIN,
IMG_NAME_IN => IMG_NAME_IN,
IMG_NAME_NIN => IMG_NAME_NIN,
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
INTERNAL_NAME_IN => INTERNAL_NAME_IN,
INTERNAL_NAME_NIN => INTERNAL_NAME_NIN,
where_in               => where_in,
handle_error_in        => handle_error_in,
rows_out               => rows_out);
end upd;

--Update/insert columns (with rows_out)
PROCEDURE upd_ins
(
ID_SYS_LIST_in IN sys_list.ID_SYS_LIST%TYPE,
CODE_SYS_LIST_in IN SYS_LIST.CODE_SYS_LIST%TYPE DEFAULT NULL,
IMG_NAME_in IN SYS_LIST.IMG_NAME%TYPE DEFAULT NULL,
CREATE_USER_in IN SYS_LIST.CREATE_USER%TYPE DEFAULT NULL,
CREATE_TIME_in IN SYS_LIST.CREATE_TIME%TYPE DEFAULT NULL,
CREATE_INSTITUTION_in IN SYS_LIST.CREATE_INSTITUTION%TYPE DEFAULT NULL,
UPDATE_USER_in IN SYS_LIST.UPDATE_USER%TYPE DEFAULT NULL,
UPDATE_TIME_in IN SYS_LIST.UPDATE_TIME%TYPE DEFAULT NULL,
UPDATE_INSTITUTION_in IN SYS_LIST.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
INTERNAL_NAME_in IN SYS_LIST.INTERNAL_NAME%TYPE DEFAULT NULL,
handle_error_in        IN BOOLEAN := TRUE,
rows_out               IN OUT table_varchar
)
is
begin
upd(
ID_SYS_LIST_IN => ID_SYS_LIST_IN,
CODE_SYS_LIST_IN => CODE_SYS_LIST_IN,
IMG_NAME_IN => IMG_NAME_IN,
CREATE_USER_IN => CREATE_USER_IN,
CREATE_TIME_IN => CREATE_TIME_IN,
CREATE_INSTITUTION_IN => CREATE_INSTITUTION_IN,
UPDATE_USER_IN => UPDATE_USER_IN,
UPDATE_TIME_IN => UPDATE_TIME_IN,
UPDATE_INSTITUTION_IN => UPDATE_INSTITUTION_IN,
INTERNAL_NAME_IN => INTERNAL_NAME_IN,
handle_error_in        => handle_error_in,
rows_out               => rows_out);
IF SQL%ROWCOUNT = 0
THEN
ins(
ID_SYS_LIST_IN => ID_SYS_LIST_IN,
CODE_SYS_LIST_IN => CODE_SYS_LIST_IN,
IMG_NAME_IN => IMG_NAME_IN,
CREATE_USER_IN => CREATE_USER_IN,
CREATE_TIME_IN => CREATE_TIME_IN,
CREATE_INSTITUTION_IN => CREATE_INSTITUTION_IN,
UPDATE_USER_IN => UPDATE_USER_IN,
UPDATE_TIME_IN => UPDATE_TIME_IN,
UPDATE_INSTITUTION_IN => UPDATE_INSTITUTION_IN,
INTERNAL_NAME_IN => INTERNAL_NAME_IN,
handle_error_in        => handle_error_in,
rows_out               => rows_out);
END IF;
end upd_ins;

--Update/insert columns (without rows_out)
PROCEDURE upd_ins
(
ID_SYS_LIST_in IN sys_list.ID_SYS_LIST%TYPE,
CODE_SYS_LIST_in IN SYS_LIST.CODE_SYS_LIST%TYPE DEFAULT NULL,
IMG_NAME_in IN SYS_LIST.IMG_NAME%TYPE DEFAULT NULL,
CREATE_USER_in IN SYS_LIST.CREATE_USER%TYPE DEFAULT NULL,
CREATE_TIME_in IN SYS_LIST.CREATE_TIME%TYPE DEFAULT NULL,
CREATE_INSTITUTION_in IN SYS_LIST.CREATE_INSTITUTION%TYPE DEFAULT NULL,
UPDATE_USER_in IN SYS_LIST.UPDATE_USER%TYPE DEFAULT NULL,
UPDATE_TIME_in IN SYS_LIST.UPDATE_TIME%TYPE DEFAULT NULL,
UPDATE_INSTITUTION_in IN SYS_LIST.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
INTERNAL_NAME_in IN SYS_LIST.INTERNAL_NAME%TYPE DEFAULT NULL,
handle_error_in        IN BOOLEAN := TRUE
)
is
rows_out table_varchar;
begin
upd_ins(
ID_SYS_LIST_IN,
CODE_SYS_LIST_IN,
IMG_NAME_IN,
CREATE_USER_IN,
CREATE_TIME_IN,
CREATE_INSTITUTION_IN,
UPDATE_USER_IN,
UPDATE_TIME_IN,
UPDATE_INSTITUTION_IN,
INTERNAL_NAME_IN,
handle_error_in,
rows_out);
end upd_ins;

--Update by record (with rows_out)
PROCEDURE upd
(
rec_in          IN sys_list%ROWTYPE,
handle_error_in IN BOOLEAN := TRUE,
rows_out        IN OUT table_varchar
)
is
begin
upd(
ID_SYS_LIST_IN => rec_in.ID_SYS_LIST,
CODE_SYS_LIST_IN => rec_in.CODE_SYS_LIST,
IMG_NAME_IN => rec_in.IMG_NAME,
CREATE_USER_IN => rec_in.CREATE_USER,
CREATE_TIME_IN => rec_in.CREATE_TIME,
CREATE_INSTITUTION_IN => rec_in.CREATE_INSTITUTION,
UPDATE_USER_IN => rec_in.UPDATE_USER,
UPDATE_TIME_IN => rec_in.UPDATE_TIME,
UPDATE_INSTITUTION_IN => rec_in.UPDATE_INSTITUTION,
INTERNAL_NAME_IN => rec_in.INTERNAL_NAME,
handle_error_in        => handle_error_in,
rows_out               => rows_out);
end upd;

--Update by record (without rows_out)
PROCEDURE upd
(
rec_in          IN sys_list%ROWTYPE,
handle_error_in IN BOOLEAN := TRUE
)
is
rows_out table_varchar;
begin
upd(
ID_SYS_LIST_IN => rec_in.ID_SYS_LIST,
CODE_SYS_LIST_IN => rec_in.CODE_SYS_LIST,
IMG_NAME_IN => rec_in.IMG_NAME,
CREATE_USER_IN => rec_in.CREATE_USER,
CREATE_TIME_IN => rec_in.CREATE_TIME,
CREATE_INSTITUTION_IN => rec_in.CREATE_INSTITUTION,
UPDATE_USER_IN => rec_in.UPDATE_USER,
UPDATE_TIME_IN => rec_in.UPDATE_TIME,
UPDATE_INSTITUTION_IN => rec_in.UPDATE_INSTITUTION,
INTERNAL_NAME_IN => rec_in.INTERNAL_NAME,
handle_error_in        => handle_error_in,
rows_out               => rows_out);
end upd;

--Update with collection (with rows_out)
PROCEDURE upd
(
col_in            IN sys_list_tc,
ignore_if_null_in IN BOOLEAN := TRUE,
handle_error_in   IN BOOLEAN := TRUE,
rows_out          IN OUT table_varchar
)
is
l_ID_SYS_LIST ID_SYS_LIST_CC;
l_CODE_SYS_LIST CODE_SYS_LIST_CC;
l_IMG_NAME IMG_NAME_CC;
l_CREATE_USER CREATE_USER_CC;
l_CREATE_TIME CREATE_TIME_CC;
l_CREATE_INSTITUTION CREATE_INSTITUTION_CC;
l_UPDATE_USER UPDATE_USER_CC;
l_UPDATE_TIME UPDATE_TIME_CC;
l_UPDATE_INSTITUTION UPDATE_INSTITUTION_CC;
l_INTERNAL_NAME INTERNAL_NAME_CC;
begin
FOR i IN col_in.FIRST .. col_in.LAST
LOOP
l_ID_SYS_LIST(i) := col_in(i).ID_SYS_LIST;
l_CODE_SYS_LIST(i) := col_in(i).CODE_SYS_LIST;
l_IMG_NAME(i) := col_in(i).IMG_NAME;
l_CREATE_USER(i) := col_in(i).CREATE_USER;
l_CREATE_TIME(i) := col_in(i).CREATE_TIME;
l_CREATE_INSTITUTION(i) := col_in(i).CREATE_INSTITUTION;
l_UPDATE_USER(i) := col_in(i).UPDATE_USER;
l_UPDATE_TIME(i) := col_in(i).UPDATE_TIME;
l_UPDATE_INSTITUTION(i) := col_in(i).UPDATE_INSTITUTION;
l_INTERNAL_NAME(i) := col_in(i).INTERNAL_NAME;
END LOOP;
IF nvl(ignore_if_null_in, FALSE)
THEN
-- Set any columns to their current values
-- if incoming value is NULL.
-- Put WHEN clause on column-level triggers!
FORALL i IN col_in.FIRST .. col_in.LAST
UPDATE sys_list
SET 
CODE_SYS_LIST = nvl(l_CODE_SYS_LIST(i), CODE_SYS_LIST),
IMG_NAME = nvl(l_IMG_NAME(i), IMG_NAME),
CREATE_USER = nvl(l_CREATE_USER(i), CREATE_USER),
CREATE_TIME = nvl(l_CREATE_TIME(i), CREATE_TIME),
CREATE_INSTITUTION = nvl(l_CREATE_INSTITUTION(i), CREATE_INSTITUTION),
UPDATE_USER = nvl(l_UPDATE_USER(i), UPDATE_USER),
UPDATE_TIME = nvl(l_UPDATE_TIME(i), UPDATE_TIME),
UPDATE_INSTITUTION = nvl(l_UPDATE_INSTITUTION(i), UPDATE_INSTITUTION),
INTERNAL_NAME = nvl(l_INTERNAL_NAME(i), INTERNAL_NAME)
 WHERE 
ID_SYS_LIST = l_ID_SYS_LIST(i)
 returning rowid bulk collect into rows_out;
ELSE
FORALL i IN col_in.FIRST .. col_in.LAST
UPDATE sys_list
SET 
CODE_SYS_LIST = l_CODE_SYS_LIST(i),
IMG_NAME = l_IMG_NAME(i),
CREATE_USER = l_CREATE_USER(i),
CREATE_TIME = l_CREATE_TIME(i),
CREATE_INSTITUTION = l_CREATE_INSTITUTION(i),
UPDATE_USER = l_UPDATE_USER(i),
UPDATE_TIME = l_UPDATE_TIME(i),
UPDATE_INSTITUTION = l_UPDATE_INSTITUTION(i),
INTERNAL_NAME = l_INTERNAL_NAME(i)
 WHERE 
ID_SYS_LIST = l_ID_SYS_LIST(i)
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
col_in            IN sys_list_tc,
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
RETURN 'BEGIN UPDATE sys_list
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
EXECUTE IMMEDIATE 'BEGIN UPDATE sys_list
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
EXECUTE IMMEDIATE 'UPDATE sys_list
SET ' || colname_in || '=' || colname_in || '+' || nvl(increment_value_in,1) ||
' WHERE ' || nvl(where_in, '1=1');
end increment_onecol;

-- Delete one row by primary key
PROCEDURE del
(
ID_SYS_LIST_in IN sys_list.ID_SYS_LIST%TYPE,
handle_error_in IN BOOLEAN := TRUE,
rows_out        OUT table_varchar
)
is
begin
DELETE FROM sys_list
 WHERE
ID_SYS_LIST = ID_SYS_LIST_IN
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
ID_SYS_LIST_in IN sys_list.ID_SYS_LIST%TYPE,
handle_error_in        IN BOOLEAN := TRUE
)
is
rows_out table_varchar;
begin
del(
ID_SYS_LIST_IN => ID_SYS_LIST_IN,
handle_error_in        => handle_error_in,
rows_out               => rows_out);
end del;

-- Deletions using dynamic SQL
FUNCTION dyndelstr
(
where_in IN VARCHAR2
)
 RETURN VARCHAR2 is 
begin
IF where_in IS NULL
THEN
RETURN 'DELETE FROM sys_list';
ELSE
RETURN 'DELETE FROM sys_list WHERE ' || where_in;
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
PROCEDURE initrec(sys_list_inout IN OUT sys_list%ROWTYPE)
is
begin
sys_list_inout.ID_SYS_LIST := NULL;
sys_list_inout.CODE_SYS_LIST := NULL;
sys_list_inout.IMG_NAME := NULL;
sys_list_inout.CREATE_USER := NULL;
sys_list_inout.CREATE_TIME := NULL;
sys_list_inout.CREATE_INSTITUTION := NULL;
sys_list_inout.UPDATE_USER := NULL;
sys_list_inout.UPDATE_TIME := NULL;
sys_list_inout.UPDATE_INSTITUTION := NULL;
sys_list_inout.INTERNAL_NAME := NULL;
end initrec;

-- Initialize a record with default values for columns in the table (fnc)
FUNCTION initrec RETURN sys_list%ROWTYPE
is
l_sys_list sys_list%ROWTYPE;
begin
return l_sys_list;
end initrec;

--get data from rowid
FUNCTION get_data_rowid(rows_in IN table_varchar) RETURN sys_list_tc
is
data sys_list_tc;
begin
select * bulk collect into data from sys_list
 WHERE rowid in (select /*+opt_estimate(table,t,scale_rows=0.0000001))*/ * from table(rows_in) t);
return data;
end get_data_rowid;

--get data from rowid (pragma autonomous transacion)
FUNCTION get_data_rowid_pat(rows_in IN table_varchar) RETURN sys_list_tc
is
data sys_list_tc;
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
END ts_sys_list;
/
