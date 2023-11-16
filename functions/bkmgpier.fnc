create or replace function bkmgpier(Nr in number default null)
  return varchar2
is
begin
 if (Nr is null) then
   return(null);
 elsif (Nr = 0) then
   return (0);
 elsif (Nr < 1024) then
   return (to_char(trunc(Nr))||'b');
 elsif (Nr < 1024*1024) then
   return (to_char(trunc(Nr/1024))||'K');
 elsif (Nr < 1024*1024*1024) then
   return (to_char(trunc(Nr/1024/1024))||'M');
 --elsif (Nr < 1024*1024*1024*1024) then
 else
   return (to_char(trunc(Nr/1024/1024/1024))||'G');
 end if;
end;
/
