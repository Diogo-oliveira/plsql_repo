CREATE OR REPLACE TYPE "T_ERROR_PARAMETER" AS OBJECT
(
NAME                    VARCHAR2(0100),
VALUE                    VARCHAR2(4000),

constructor function T_ERROR_PARAMETER return self as result,
member procedure set_prm( i_name in varchar2, i_value in varchar2 ),
member function get_name  return varchar2,
member function get_value return varchar2

) instantiable not final;
/


create or replace type body T_ERROR_PARAMETER as

constructor function T_ERROR_PARAMETER return self as result is
begin
self.name := 'VAR';	
self.value:= 'NULL';
return;
end T_ERROR_PARAMETER;

member procedure set_prm( i_name in varchar2, i_value in varchar2 ) is
begin
self.name := i_name;	
self.value:= i_value;
end;

member function get_name return varchar2 is
begin
return name;
end get_name;

member function get_value return varchar2 is
begin
return value;
end get_value;

end;
