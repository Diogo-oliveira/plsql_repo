CREATE OR REPLACE TYPE STATUS_DEF
AS OBJECT (  id_pharmacy_status	number(24),
code_status	varchar2(200),
flg_status	varchar2(1),
icon_status	varchar2(200),
rank_status	number(6),
type_status	varchar2(5),
color_status	varchar2(1),
icon_color	varchar2(10),
background_color	varchar2(10),
prof_cat_type	varchar2(1))